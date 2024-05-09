// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/ReentrancyGuard.sol";
import "../libraries/SafeCast.sol";
import "../libraries/SignedSafeMath.sol";
import "../libraries/TransferHelper.sol";
import "./MarketStorage.sol";
import "../interfaces/IMarketLogic.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IFundingLogic.sol";
import "../interfaces/IInviteManager.sol";

/// @notice A market represents a perpetual trading market, eg. BTC_USDT (USDT settled).
/// YFX.com provides a diverse perpetual contracts including two kinds of position model, which are one-way position and
/// the hedging positiion mode, as well as three kinds of perpetual contracts, which are the linear contracts, the inverse contracts and the quanto contracts.

contract Market is MarketStorage, ReentrancyGuard {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int8;
    using SafeCast for int256;
    using SafeCast for uint256;

    constructor(address _manager, address _marketLogic, address _fundingLogic){
        //require(_manager != address(0) && _marketLogic != address(0) && _fundingLogic != address(0), "Market: address is zero address");
        require(_manager != address(0) && _marketLogic != address(0), "MC0");
        manager = _manager;
        marketLogic = _marketLogic;
        fundingLogic = _fundingLogic;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "O0");
        _;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "MO1");
        _;
    }

    modifier onlyRouter() {
        require(IManager(manager).checkRouter(msg.sender), "MO2");
        _;
    }

    modifier onlyExecutor() {
        require(IManager(manager).checkExecutorRouter(msg.sender), "MOE1");
        _;
    }

    modifier whenNotCreateOrderPaused() {
        require(!marketConfig.createOrderPaused, "MW0");
        _;
    }

    modifier whenNotSetTPSLPricePaused() {
        require(!marketConfig.setTPSLPricePaused, "MW1");
        _;
    }

    modifier whenUpdateMarginPaused() {
        require(!marketConfig.updateMarginPaused, "MW2");
        _;
    }

    /// @notice initialize market, only manager can call
    /// @param _token actually the price key, eg. "BTC_USDT"
    /// @param _marginAsset  margin asset address
    /// @param _pool pool address
    /// @param _marketType market type: {0: linear, 1: inverse, 2: quanto}
    function initialize(string memory _token, address _marginAsset, address _pool, uint8 _marketType) external {
        require(msg.sender == manager && _marginAsset != address(0) && _pool != address(0), "MIO");
        token = _token;
        marginAsset = _marginAsset;
        pool = _pool;
        marketType = _marketType;
        emit Initialize(_token, _marginAsset, _pool, _marketType);
    }

    /// @notice set market params, only controller can call
    /// @param _marketLogic market logic address
    /// @param _fundingLogic funding logic address
    function modifyLogicAddresses(
        address _marketLogic,
        address _fundingLogic
    ) external onlyController {
        require(_marketLogic != address(0), "MM0");
        if (fundingLogic != address(0)) {
            require(_fundingLogic != address(0), "MM1");
        }
        marketLogic = _marketLogic;
        fundingLogic = _fundingLogic;
        emit LogicAddressesModified(marketLogic, fundingLogic);
    }

    /// @notice set general market configurations, only controller can call
    /// @param _config configuration parameters
    function setMarketConfig(MarketDataStructure.MarketConfig memory _config) external onlyManager {
        marketConfig = _config;
        emit SetMarketConfig(marketConfig);
    }

    /// @notice switch position mode, users can choose the one-way or hedging positon mode for a specific market
    /// @param _taker taker address
    /// @param _mode mode {0: one-way, 1: hedging}
    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external onlyRouter {
        positionModes[_taker] = _mode;
        emit SwitchPositionMode(_taker, _mode);
    }

    function createOrder(MarketDataStructure.CreateInternalParams memory params) public whenNotCreateOrderPaused returns (uint256) {
        require(IManager(manager).checkRouter(msg.sender) || (msg.sender == address(this)) || IManager(manager).checkExecutorRouter(msg.sender), "MO2");
        
        MarketDataStructure.Order memory order = IMarketLogic(marketLogic).createOrderInternal(params);
        order.id = ++orderID;

        orders[order.id] = order;
        takerOrderList[params._taker].push(order.id);

        if (!params.isLiquidate) takerOrderNum[params._taker][order.orderType] ++;
        _setTakerOrderTotalValue(order.taker, order.orderType, order.direction, order.freezeMargin.mul(order.takerLeverage).toInt256());


        if (!params.isLiquidate) IMarketLogic(marketLogic).checkOrder(order.id);
        return order.id;
    }

    struct ExecuteOrderInternalParams {
        bytes32 code;
        address inviter;
        uint256 discountRate;
        uint256 inviteRate;
        MarketDataStructure.Order order;
        MarketDataStructure.Position position;
        MarketDataStructure.Position oldPosition;
        MarketDataStructure.TradeResponse response;
        address inviteManager;
        int256 settleDustMargin;            // dust margin part to be settled
    }

    /// @notice execute an order
    /// @param _id order id
    /// @return resultCode execute result 0：open success；1:order open fail；2:trigger order open fail; 3:low-level call failed
    /// @return _positionId position id
    function executeOrder(uint256 _id) external nonReentrant onlyExecutor returns (uint256 resultCode, uint256 _positionId, bool isAllClosed) {
        ExecuteOrderInternalParams memory params;
        params.order = orders[_id];
        //freezeMargin > 0 ,order type is open and position direction is same as order direction;freezeMargin = 0,order type is close and position direction is neg of order direction

        int8 positionDirection;
        if (isOpenOrder(params.order.orderType)) {
            positionDirection = params.order.direction;
        } else {
            positionDirection = params.order.direction.neg256().toInt8();
        }
        MarketDataStructure.PositionKey key = getPositionKey(params.order.taker, positionDirection);
        _positionId = takerPositionList[params.order.taker][key];
        if (_positionId == 0) {
            _positionId = ++positionID;
            takerPositionList[params.order.taker][key] = _positionId;
        }

        //store position last funding rate
        orders[_id].frLastX96 = takerPositions[_positionId].frLastX96;
        //store position last funding amount
        orders[_id].fundingAmount = takerPositions[_positionId].amount.toInt256().mul(takerPositions[_positionId].direction);

        IPool(pool).updateBorrowIG();
        _settleFunding(takerPositions[_positionId]);

        params.oldPosition = takerPositions[_positionId];

        params.inviteManager = _inviteManager();
        (params.code, params.inviter, params.discountRate, params.inviteRate) = _getReferrerCodeByTaker(params.inviteManager, params.order.taker);

        uint256 indexPrice = IMarketLogic(marketLogic).getIndexOrMarketPrice(address(this), params.order.direction == 1, params.order.useIP);
        // trigger condition validation
        if (params.order.triggerPrice > 0) {
            if ((block.timestamp >= params.order.createTs.add(IManager(manager).triggerOrderDuration())) ||
                (params.order.triggerDirection == 1 ? indexPrice <= params.order.triggerPrice : indexPrice >= params.order.triggerPrice)) {
                // 2 is the error code for "trigger order open fail"
                return (2, _positionId, false);
            }
        }

        try IMarketLogic(marketLogic).trade(_id, _positionId, params.discountRate, params.inviteRate)
        returns (
            MarketDataStructure.Order memory _order,
            MarketDataStructure.Position memory _position,
            MarketDataStructure.TradeResponse memory _response
        ){
            params.order = _order;
            params.position = _position;
            params.response = _response;
        } catch Error(string memory reason) {
            emit ExecuteOrderError(_id, reason);
            orders[_id].status = MarketDataStructure.OrderStatus.OpenFail;
            // 1 is the error code for "order open fail"
            return (1, _positionId, false);
        } catch (bytes memory lowLevelData) {
            emit ExecuteOrderLowLeveError(_id, lowLevelData);
            // 3 is the error code for "low-level call failed"
            return (3, _positionId, false);
        }

        if (params.order.freezeMargin > 0) _transfer(IManager(manager).vault(), params.order.freezeMargin);
        takerOrderNum[params.order.taker][params.order.orderType]--;
        _setTakerOrderTotalValue(params.order.taker, params.order.orderType, params.order.direction, params.order.freezeMargin.mul(params.order.takerLeverage).toInt256().neg256());

        if (params.response.isIncreasePosition) {
            IPool.UpdateParams memory u;
            u.orderId = params.order.id;
            u.makerMargin = params.response.isDecreasePosition ? params.position.makerMargin : params.position.makerMargin.sub(params.oldPosition.makerMargin);
            u.takerMargin = params.response.isDecreasePosition ? params.position.takerMargin : params.position.takerMargin.sub(params.oldPosition.takerMargin);
            u.amount = params.response.isDecreasePosition ? params.position.amount : params.position.amount.sub(params.oldPosition.amount);
            u.total = params.response.isDecreasePosition ? params.position.value : params.position.value.sub(params.oldPosition.value);
            u.makerFee = params.response.isDecreasePosition ? 0 : params.order.feeToMaker;
            u.takerDirection = params.order.direction;
            u.marginToVault = params.order.freezeMargin;
            u.taker = params.order.taker;
            u.feeToInviter = params.response.isDecreasePosition ? 0 : params.order.feeToInviter;
            u.inviter = params.inviter;
            u.deltaDebtShare = params.response.isDecreasePosition ? params.position.debtShare : params.position.debtShare.sub(params.oldPosition.debtShare);
            u.feeToExchange = params.response.isDecreasePosition ? 0 : params.order.feeToExchange;
            IPool(pool).openUpdate(u);
        }
        
        if (params.response.isDecreasePosition) {
            IPool(pool).closeUpdate(
                IPool.UpdateParams(
                    params.order.id,
                    params.response.isIncreasePosition ? params.oldPosition.makerMargin : params.oldPosition.makerMargin.sub(params.position.makerMargin),
                    params.response.isIncreasePosition ? params.oldPosition.takerMargin : params.oldPosition.takerMargin.sub(params.position.takerMargin),
                    params.response.isIncreasePosition ? params.oldPosition.amount : params.oldPosition.amount.sub(params.position.amount),
                    params.response.isIncreasePosition ? params.oldPosition.value : params.oldPosition.value.sub(params.position.value),
                    params.order.rlzPnl.neg256(),
                    params.order.feeToMaker,
                    params.response.isIncreasePosition ? params.oldPosition.fundingPayment : params.oldPosition.fundingPayment.sub(params.position.fundingPayment),
                    params.oldPosition.direction,
                    params.response.isIncreasePosition ? 0 : params.order.freezeMargin,
                    params.response.isIncreasePosition ? params.oldPosition.debtShare : params.oldPosition.debtShare.sub(params.position.debtShare),
                    params.order.interestPayment,
                    params.oldPosition.isETH,
                    0,
                    params.response.toTaker,
                    params.order.taker,
                    params.order.feeToInviter,
                    params.inviter,
                    params.order.feeToExchange,
                    false
                )
            );
        }

        _updateUTP(params.inviteManager, params.order.taker, params.inviter, params.response.tradeValue);

        emit ExecuteInfo(params.order.id, params.order.orderType, params.order.direction, params.order.taker, params.response.tradeValue, params.order.feeToDiscount, params.order.tradePrice);

        if (params.response.isIncreasePosition && !params.response.isDecreasePosition) {
            require(params.position.amount > params.oldPosition.amount, "EO0");
        } else if (!params.response.isIncreasePosition && params.response.isDecreasePosition) {
            require(params.position.amount < params.oldPosition.amount, "EO1");
        } else {
            require(params.position.direction != params.oldPosition.direction, "EO2");
        }

        if (params.order.freezeMargin == 0) params.order.freezeMargin = params.oldPosition.takerMargin.sub(params.position.takerMargin);
        params.order.code = params.code;
        params.order.tradeIndexPrice = indexPrice;
        orders[_id] = params.order;
        takerPositions[_positionId] = params.position;

        // position mint
        isAllClosed = params.response.isDecreasePosition == params.response.isIncreasePosition;

        return (0, _positionId, isAllClosed);
    }

    struct LiquidateInternalParams {
        IMarketLogic.LiquidateInfoResponse response;
        uint256 toTaker;
        bytes32 code;
        address inviter;
        uint256 discountRate;
        uint256 inviteRate;
        address inviteManager;
    }

    ///@notice liquidate position
    ///@param _id position id
    ///@param action liquidate type
    ///@return liquidate order id
    function liquidate(uint256 _id, MarketDataStructure.OrderType action, uint256 clearPrice) public onlyExecutor returns (uint256) {
        LiquidateInternalParams memory params;
        MarketDataStructure.Position storage position = takerPositions[_id];
        require(position.amount > 0, "L0");

        //create liquidate order
        MarketDataStructure.Order storage order = orders[createOrder(MarketDataStructure.CreateInternalParams(position.taker, position.id, 0, 0, 0, position.amount, position.takerLeverage, position.direction.neg256().toInt8(), 0, 0, position.useIP, 1, true, position.isETH))];
        order.frLastX96 = position.frLastX96;
        order.fundingAmount = position.amount.toInt256().mul(position.direction);
        //update interest rate
        IPool(pool).updateBorrowIG();
        //settle funding rate
        _settleFunding(position);
        order.frX96 = fundingGrowthGlobalX96;
        order.fundingPayment = position.fundingPayment;

        params.inviteManager = _inviteManager();
        (params.code, params.inviter, params.discountRate, params.inviteRate) = _getReferrerCodeByTaker(params.inviteManager, order.taker);
        //get liquidate info by marketLogic
        params.response = IMarketLogic(marketLogic).getLiquidateInfo(IMarketLogic.LiquidityInfoParams(position, action, params.discountRate, params.inviteRate, clearPrice));

        //update order info
        order.code = params.code;
        order.takerFee = params.response.takerFee;
        order.feeToMaker = params.response.feeToMaker;
        order.feeToExchange = params.response.feeToExchange;
        order.feeToInviter = params.response.feeToInviter;
        order.feeToDiscount = params.response.feeToDiscount;
        order.orderType = action;
        order.interestPayment = params.response.payInterest;
        order.riskFunding = params.response.riskFunding;
        order.rlzPnl = params.response.pnl;
        order.status = MarketDataStructure.OrderStatus.Opened;
        order.tradeTs = block.timestamp;
        order.tradePrice = params.response.price;
        order.tradeIndexPrice = params.response.indexPrice;
        order.freezeMargin = position.takerMargin;

        //liquidate position，update close position info in pool
        IPool(pool).closeUpdate(
            IPool.UpdateParams(
                order.id,
                position.makerMargin,
                position.takerMargin,
                position.amount,
                position.value,
                params.response.pnl.neg256(),
                params.response.feeToMaker,
                position.fundingPayment,
                position.direction,
                0,
                position.debtShare,
                params.response.payInterest,
                position.isETH,
                order.riskFunding,
                params.response.toTaker,
                position.taker,
                order.feeToInviter,
                params.inviter,
                order.feeToExchange,
                action == MarketDataStructure.OrderType.ClearAll
            )
        );

        //emit invite info
        if (order.orderType != MarketDataStructure.OrderType.Liquidate) {
            _updateUTP(params.inviteManager, order.taker, params.inviter, params.response.tradeValue);
        }

        emit ExecuteInfo(order.id, order.orderType, order.direction, order.taker, params.response.tradeValue, order.feeToDiscount, order.tradePrice);

        //update position info
        position.amount = 0;
        position.makerMargin = 0;
        position.takerMargin = 0;
        position.value = 0;
        //position cumulative rlz pnl
        position.pnl = position.pnl.add(order.rlzPnl);
        position.fundingPayment = 0;
        position.lastUpdateTs = 0;
        //clear position debt share
        position.debtShare = 0;

        return order.id;
    }
    
    function _getReferrerCodeByTaker(address inviteManager, address taker)internal view returns(bytes32, address, uint256, uint256){
        return IInviteManager(inviteManager).getReferrerCodeByTaker(taker);
    }

    function _updateUTP(address inviteManager, address taker, address inviter, uint256 tradeValue) internal {
        IInviteManager(inviteManager).updateTradeValue(marketType, taker, inviter, tradeValue);
    }
    
    function _inviteManager() internal view returns(address){
        return IManager(manager).inviteManager();
    }

    ///@notice update market funding rate
    function updateFundingGrowthGlobal() external {
        _updateFundingGrowthGlobal();
    }

    ///@notice update market funding rate
    ///@param position taker position
    ///@return _fundingPayment
    function _settleFunding(MarketDataStructure.Position storage position) internal returns (int256 _fundingPayment){
        /// @notice once funding logic address set, address(0) is not allowed to use
        if (fundingLogic == address(0)) {
            return 0;
        }
        _updateFundingGrowthGlobal();
        _fundingPayment = IFundingLogic(fundingLogic).getFundingPayment(address(this), position.id, fundingGrowthGlobalX96);
        position.frLastX96 = fundingGrowthGlobalX96;
        if (_fundingPayment != 0) {
            position.fundingPayment = position.fundingPayment.add(_fundingPayment);
            IPool(pool).updateFundingPayment(address(this), _fundingPayment);
        }
    }

    ///@notice update market funding rate
    function _updateFundingGrowthGlobal() internal {
        //calc current funding rate by fundingLogic
        if (fundingLogic != address(0)) {
            int256 deltaFundingRate;
            (fundingGrowthGlobalX96, deltaFundingRate) = IFundingLogic(fundingLogic).getFunding(address(this));
            if (block.timestamp != lastFrX96Ts) {
                lastFrX96Ts = block.timestamp;
            }
            emit UpdateFundingRate(deltaFundingRate);
        }
    }

    ///@notice cancel order, only router can call
    ///@param _id order id
    function cancel(uint256 _id) external nonReentrant onlyRouter {
        MarketDataStructure. Order storage order = orders[_id];
        require(order.status == MarketDataStructure.OrderStatus.Open || order.status == MarketDataStructure.OrderStatus.OpenFail, "MC0");
        order.status = MarketDataStructure.OrderStatus.Canceled;
        //reduce taker order count
        takerOrderNum[order.taker][order.orderType]--;
        _setTakerOrderTotalValue(order.taker, order.orderType, order.direction, order.freezeMargin.mul(order.takerLeverage).toInt256().neg256());
        if (order.freezeMargin > 0) _transfer(msg.sender, order.freezeMargin);
    }

    function _setTakerOrderTotalValue(address _taker, MarketDataStructure.OrderType orderType, int8 _direction, int256 _value) internal {
        if (isOpenOrder(orderType)) {
            _value = _value.mul(AMOUNT_PRECISION).div(marketConfig.marketAssetPrecision.toInt256());
            //reduce taker order total value
            takerOrderTotalValues[_taker][_direction] = takerOrderTotalValues[_taker][_direction].add(_value);
        }
    }

    ///@notice set order stop profit and loss price, only router can call
    ///@param _id position id
    ///@param _profitPrice take profit price
    ///@param _stopLossPrice stop loss price
    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool isExecutedByIndexPrice) external onlyRouter whenNotSetTPSLPricePaused {
        MarketDataStructure.Position storage position = takerPositions[_id];
        position.takeProfitPrice = _profitPrice;
        position.stopLossPrice = _stopLossPrice;
        position.useIP = isExecutedByIndexPrice;
        position.lastTPSLTs = block.timestamp;
    }

    ///@notice increase or decrease taker margin, only router can call
    ///@param _id position id
    ///@param _updateMargin increase or decrease margin
    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external nonReentrant onlyRouter whenUpdateMarginPaused {
        MarketDataStructure.Position storage position = takerPositions[_id];
        int256 _deltaMargin = _updateMargin.toInt256();
        if (isIncrease) {
            position.takerMargin = position.takerMargin.add(_updateMargin);
        } else {
            position.takerMargin = position.takerMargin.sub(_updateMargin);
            _deltaMargin = _deltaMargin.neg256();
        }

        //update taker margin in pool
        IPool(pool).takerUpdateMargin(address(this), position.taker, _deltaMargin, position.isETH);
        emit UpdateMargin(_id, _deltaMargin);
    }

    function _transfer(address to, uint256 amount) internal {
        TransferHelper.safeTransfer(marginAsset, to, amount);
    }

    function isOpenOrder(MarketDataStructure.OrderType orderType) internal pure returns (bool) {
        return orderType == MarketDataStructure.OrderType.Open || orderType == MarketDataStructure.OrderType.TriggerOpen;
    }

    ///@notice get taker position id
    ///@param _taker taker address
    ///@param _direction position direction
    ///@return position id
    function getPositionId(address _taker, int8 _direction) public view returns (uint256) {
        return takerPositionList[_taker][getPositionKey(_taker, _direction)];
    }

    function getPositionKey(address _taker, int8 _direction) internal view returns (MarketDataStructure.PositionKey key) {
        //if position mode is oneway,position key is 2,else if direction is 1,position key is 1,else position key is 0
        key = positionModes[_taker] == MarketDataStructure.PositionMode.OneWay ? MarketDataStructure.PositionKey.OneWay :
            _direction == - 1 ? MarketDataStructure.PositionKey.Short : MarketDataStructure.PositionKey.Long;
    }

    function getPosition(uint256 _id) external view returns (MarketDataStructure.Position memory) {
        return takerPositions[_id];
    }

    function getOrderIds(address _taker) external view returns (uint256[] memory) {
        return takerOrderList[_taker];
    }

    function getOrder(uint256 _id) external view returns (MarketDataStructure.Order memory) {
        return orders[_id];
    }

    function getLogicAddress() external view returns (address){
        return fundingLogic;
    }

    function getMarketConfig() external view returns (MarketDataStructure.MarketConfig memory){
        return marketConfig;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

contract MarketStorage {
    // amount decimal 1e20
    int256 constant AMOUNT_PRECISION = 1e20;

    string public token;//indexToken，like `BTC_USD`,price key
    uint8 public marketType = 0;//contract type ,0:usd-m,1:coin-m,2:mix-m
    address public pool;//pool address
    address internal manager;//manager address
    address public marketLogic;//marketLogic address
    address internal fundingLogic;//fundingLogic address
    address internal marginAsset;//margin asset address
    MarketDataStructure.MarketConfig internal marketConfig;//marketConfig

    uint256 public positionID;//positionID
    uint256 public orderID;//orderID
    //uint256 public triggerOrderID = type(uint128).max;  //trigger Order ID
    //taker => key => positionID
    mapping(address => mapping(MarketDataStructure.PositionKey => uint256)) internal takerPositionList;//key: short;long;cross
    //taker => orderID[]
    mapping(address => uint256[]) internal takerOrderList;
    //orderId => order
    mapping(uint256 => MarketDataStructure.Order) internal orders;
    //positionId => position
    mapping(uint256 => MarketDataStructure.Position) internal takerPositions;
    //taker => marginMode
    mapping(address => MarketDataStructure.PositionMode) public positionModes;//0 cross marginMode；1 Isolated marginMode
    //taker => orderType => orderNum, orderNum < maxOrderLimit
    mapping(address => mapping(MarketDataStructure.OrderType => uint256)) public takerOrderNum;
    //taker => direction => orderTotalValue,orderTotalValue < maxOrderValueLimit
    mapping(address => mapping(int8 => int256)) public takerOrderTotalValues;
    //cumulative funding rate,it`s last funding rate, fundingGrowthGlobalX96 be equivalent to frX96
    int256 public fundingGrowthGlobalX96;
    //last update funding rate timestamp
    uint256 public lastFrX96Ts;//lastFrX96Ts
    //uint256 public lastExecutedOrderId;

    event Initialize(string indexToken, address _clearAnchor, address _pool, uint8 _marketType);
    event LogicAddressesModified(address _marketLogic, address _fundingLogic);
    event SetMarketConfig(MarketDataStructure.MarketConfig _marketConfig);
    event ExecuteOrderLowLeveError(uint256 _orderId, bytes _errCode);
    event ExecuteOrderError(uint256 _orderId, string _reason);
    event ExecuteInfo(
        uint256 id, 
        MarketDataStructure.OrderType orderType,
        int8 direction,
        address taker,
        uint256 tradeValue,
        uint256 feeToDiscunt,
        uint256 tradePrice
    );
    event UpdateMargin(uint256 id, int256 deltaMargin);
    event SwitchPositionMode(address taker, MarketDataStructure.PositionMode mode);
    event UpdateFundingRate(int256 fundingRate);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

//import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256 constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256 constant PRICE_PRECISION = 1e10;
    uint256 constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address vault;                                              // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 baseAssetDecimals;                                  // base token decimals
    address interestLogic;                                      // interest logic address
    address WETH;                                               // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity
    uint256 public mm;                                          // maintenance margin ratio
    bool public clearAll;
    uint256 public minLeverage;
    uint256 public maxLeverage;
    uint256 public penaltyRate;

    int256 public balance;                                      // balance that is available to use of this pool
    int256 public balanceReal;
    uint256 public reserveRate;                                 // reserve ratio
    uint256 sharePrice;                                         // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId;                                      // liquidity operations order id
    uint256 eventId;                                            // event count

    address[] marketList;                                       // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)
    mapping(uint256 => IPool.Position) public makerPositions;   // mapping of liquidity positions for addresses
    mapping(address => uint256) public makerPositionIds;        // mapping of liquidity positions for addresses

    //structs
    struct MarketConfig {
        uint256 marketType;
        uint256 fundUtRateLimit;                                // fund utilization ratio limit, 0: cant't open; example 200000  r = fundUtRateLimit/RATE_PRECISION=0.2
        uint256 openLimit;                                      // 0: 0 authorized credit limit; > 0 limit is min(openLimit, fundUtRateLimit * balance)
    }

    struct DataByMarket {
        int256 rlzPNL;                                          // realized profit and loss
        uint256 cumulativeFee;                                  // cumulative trade fee for pool
        uint256 longMakerFreeze;                                // user total long margin freeze, that is the pool short margin freeze
        uint256 shortMakerFreeze;                               // user total short margin freeze, that is pool long margin freeze
        uint256 takerTotalMargin;                               // all taker's margin
        int256 makerFundingPayment;                             // pending fundingPayment
        uint256 interestPayment;                                // interestPayment          
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    struct PoolParams {
        uint256 _minAmount;
        uint256 _minLiquidity;
        address _market;
        uint256 _openRate;
        uint256 _openLimit;
        uint256 _reserveRate;
        uint256 _ratio;
        bool _add;
        bool _remove;
        address _interestLogic;
        address _marketPriceFeed;
        uint256 _mm;
        uint256 _minLeverage;
        uint256 _maxLeverage;
        uint256 _penaltyRate;
    }

    struct GlobalHf {
        uint256 sharePrice;
        uint256[] indexPrices;
        uint256 allMakerFreeze;
        DataByMarket allMarketPos;
        uint256 poolInterest;
        int256 totalUnPNL;
        uint256 poolTotalTmp;
    }

    event RegisterMarket(address market);
    event AddLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 initMargin, uint256 liquidity, uint256 entryValue, uint256 sharePrice, uint256 totalValue);
    event RemoveLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker, uint256 sharePrice, uint256 rmFee, uint256 totalValue, uint256 actionType);
    event Liquidate(uint256 id, address maker,uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker,uint256 penalty, uint256 sharePrice, uint256 totalValue);
    event ActivatedClearAll(uint256 ts, uint256[] indexPrices);
    event AddMakerPositionMargin(uint256 id, uint256 positionId, uint256 addMargin);
    event ReStarted(address pool);
    event OpenUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
    event CloseUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 riskFunding,
        int256 rlzPnl,
        int256 fundingPayment,
        uint256 interestPayment,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
    * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IFundingLogic {
    function getFunding(address market) external view returns (int256 fundingGrowthGlobalX96, int256 deltaFundingRate);

    function getFundingPayment(address market, uint256 positionId, int256 fundingGrowthGlobalX96) external view returns (int256 fundingPayment);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IInviteManager {
    function setTraderReferralCode(address _account, bytes32 _code) external;

    function getReferrerCodeByTaker(address _taker) external view returns (bytes32, address, uint256, uint256);

    function updateTradeValue(uint8 _marketType, address _taker, address _inviter, uint256 _tradeValue) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSuperSigner(address _signer) external view returns (bool);

    function checkSigner(address signer, uint8 sType) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkExecutorRouter(address _executorRouter) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function checkMarketLogic(address _logic) external view returns (bool);

    function checkMarketPriceFeed(address _feed) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused(address market) external view returns (bool);

    function isInterestPaused(address pool) external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkExecutor(address _executor, uint8 eType) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);

    function modifySingleInterestStatus(address pool, bool _interestPaused) external;

    function modifySingleFundingStatus(address market, bool _fundingPaused) external;
    
    function router() external view returns (address);

    function executorRouter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarketLogic {
    struct LiquidityInfoParams {
        MarketDataStructure.Position position;
        MarketDataStructure.OrderType action;
        uint256 discountRate;
        uint256 inviteRate;
        uint256 clearPrice;
    }

    struct LiquidateInfoResponse {
        int256 pnl;
        uint256 takerFee;
        uint256 feeToMaker;
        uint256 feeToExchange;
        uint256 feeToInviter;
        uint256 feeToDiscount;
        uint256 riskFunding;
        uint256 payInterest;
        uint256 toTaker;
        uint256 tradeValue;
        uint256 price;
        uint256 indexPrice;
    }

    function trade(uint256 id, uint256 positionId, uint256, uint256) external returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response);

    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view returns (MarketDataStructure.Order memory order);

    function getLiquidateInfo(LiquidityInfoParams memory params) external returns (LiquidateInfoResponse memory response);

    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) external view returns (bool);

    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view returns (uint256 maxDecreaseMargin);

    function checkOrder(uint256 id) external view;

    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) external view;

    function getIndexOrMarketPrice(address _market, bool _maximise, bool isIndexPrice) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }
    
    struct UpdateParams {
        uint256 orderId;
        uint256 makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 takerMargin;
        uint256 amount;
        uint256 total;
        int256 makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 takerDirection;//old position direction
        uint256 marginToVault;// reduce position size ,order margin should be to record in vault
        uint256 deltaDebtShare;//reduce position debt share
        uint256 payInterest;//settled interest payment
        bool isOutETH;//margin is ETH
        uint256 toRiskFund;
        uint256 toTaker;//balance of reduce position to taker
        address taker;//taker address
        uint256 feeToInviter; //trade fee to inviter
        address inviter;//inviter address
        uint256 feeToExchange;//fee to exchange
        bool isClearAll;
    }

    struct Position{
        address maker;
        uint256 initMargin;
        uint256 liquidity;
        uint256 entryValue;
        uint256 lastAddTime;
        uint256 makerStopLossPrice;
        uint256 makerProfitPrice;
    }
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function makerPositions(uint256 positionId) external view returns (Position memory);

    function openUpdate(UpdateParams memory params) external;

    function closeUpdate(UpdateParams memory params) external;

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external;

    function addLiquidity(uint256 orderId, address sender, uint256 amount, uint256 leverage) external returns(uint256 liquidity);

    function removeLiquidity(uint256 orderId, address sender, uint256 liquidity, bool isETH, bool isSystem) external returns (uint256 settleLiquidity);

    function liquidate(uint256 positionId) external ;

    function registerMarket(address _market) external returns (bool);

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getBaseAsset() external view returns (address);

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function clearAll() external view returns (bool);

    function makerPositionIds(address maker) external view returns (uint256);
    
    function mm()external view returns (uint256);
    
    function globalHf()external view returns (bool status, uint256 poolTotalTmp, int256 totalUnPNL);

    function addMakerPositionMargin(uint256 positionId, uint256 addMargin) external;

    function setTPSLPrice(address maker, uint256 positionId, uint256 tp, uint256 sl) external;
    
    function balance() external view returns (int256);
    
    function balanceReal() external view returns (int256);
    
    function getMarketList() external view returns (address[] memory);

    function poolDataByMarkets(address market) external view returns (int256, uint256, uint256, uint256, uint256, int256, uint256, uint256, uint256, uint256, uint256);
    
    function interestData(int8 direction) external view returns (IPool.InterestData memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @notice data structure used by Pool

library MarketDataStructure {
    /// @notice enumerate of user trade order status
    enum OrderStatus {
        Open,
        Opened,
        OpenFail,
        Canceled
    }

    /// @notice enumerate of user trade order types
    enum OrderType{
        Open,
        Close,
        TriggerOpen,
        TriggerClose,
        Liquidate,
        TakeProfit,
        UserTakeProfit,
        UserStopLoss,
        ClearAll
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        Hedge,
        OneWay
    }

    enum PositionKey{
        Short,
        Long,
        OneWay
    }

    /// @notice Position data structure
    struct Position {
        uint256 id;                 // position id, generated by counter
        address taker;              // taker address
        address market;             // market address
        int8 direction;             // position direction
        uint16 takerLeverage;       // leverage used by trader
        uint256 amount;             // position amount
        uint256 value;              // position value
        uint256 takerMargin;        // margin of trader
        uint256 makerMargin;        // margin of maker(pool)
        uint256 multiplier;         // multiplier of quanto perpetual contracts
        int256 frLastX96;           // last settled funding global cumulative value
        uint256 stopLossPrice;      // stop loss price of this position set by trader
        uint256 takeProfitPrice;    // take profit price of this position set by trader
        bool useIP;                 // true if the tp/sl is executed by index price
        uint256 lastTPSLTs;         // last timestamp of trading setting the stop loss price or take profit price
        int256 fundingPayment;      // cumulative funding need to pay of this position
        uint256 debtShare;          // borrowed share of interest module
        int256 pnl;                 // cumulative realized pnl of this position
        bool isETH;                 // true if the margin is payed by ETH
        uint256 lastUpdateTs;       // last updated timestamp of this position
    }

    /// @notice data structure of trading orders
    struct Order {
        uint256 id;                             // order id, generated by counter
        address market;                         // market address
        address taker;                          // trader address
        int8 direction;                         // order direction
        uint16 takerLeverage;                   // order leverage
        int8 triggerDirection;                  // price condition if order is trigger order: {0: not available, 1: >=, -1: <= }
        uint256 triggerPrice;                   // trigger price, 0: not available
        bool useIP;                             // true if the order is executed by index price
        uint256 freezeMargin;                   // frozen margin of this order
        uint256 amount;                         // order amount
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 takerOpenPriceMin;              // minimum trading price for slippage control
        uint256 takerOpenPriceMax;              // maximum trading price for slippage control

        OrderType orderType;                    // order type
        uint256 riskFunding;                    // risk funding penalty if this is a liquidate order

        uint256 takerFee;                       // taker trade fee
        uint256 feeToInviter;                   // reward of trading fee to the inviter
        uint256 feeToExchange;                  // trading fee charged by protocol
        uint256 feeToMaker;                     // fee reward to the pool
        uint256 feeToDiscount;                  // fee discount
        uint256 executeFee;                     // execution fee
        bytes32 code;                           // invite code

        uint256 tradeTs;                        // trade timestamp
        uint256 tradePrice;                     // trade price
        uint256 tradeIndexPrice;                // index price when executing
        int256 rlzPnl;                          // realized pnl by this order

        int256 fundingPayment;                  // settled funding payment
        int256 frX96;                           // latest cumulative funding growth global
        int256 frLastX96;                       // last cumulative funding growth global
        int256 fundingAmount;                   // funding amount by this order, calculated by amount, frX96 and frLastX96

        uint256 interestPayment;                // settled interest amount
        
        uint256 createTs;                       // create timestamp
        OrderStatus status;                     // order status
        MarketDataStructure.PositionMode mode;  // margin mode, one-way or hedge
        bool isETH;                             // true if the margin is payed by ETH
    }

    /// @notice configuration of markets
    struct MarketConfig {
        uint256 mm;                             // maintenance margin ratio
        uint256 liquidateRate;                  // penalty ratio when position is liquidated, penalty = position.value * liquidateRate
        uint256 tradeFeeRate;                   // trading fee rate
        uint256 makerFeeRate;                   // ratio of trading fee that goes to the pool
        bool createOrderPaused;                 // true if order creation is paused
        bool setTPSLPricePaused;                // true if tpsl price setting is paused
        bool createTriggerOrderPaused;          // true if trigger order creation is paused
        bool updateMarginPaused;                // true if updating margin is paused
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 marketAssetPrecision;           // margin asset decimals
        uint256 DUST;                           // dust amount,scaled by AMOUNT_PRECISION (1e20)

        uint256 takerLeverageMin;               // minimum leverage that trader can use
        uint256 takerLeverageMax;               // maximum leverage that trader can use
        uint256 dMMultiplier;                   // used to calculate the initial margin when trading decrease position margin

        uint256 takerMarginMin;                 // minimum margin of a single trader order
        uint256 takerMarginMax;                 // maximum margin of a single trader order
        uint256 takerValueMin;                  // minimum value amount of a single trader order
        uint256 takerValueMax;                  // maximum value amount of a single trader order
        int256 takerValueLimit;                 // maximum position value of a single position
    }

    /// @notice internal parameter data structure when creating an order
    struct CreateInternalParams {
        address _taker;             // trader address
        uint256 id;                 // order id, generated by id counter
        uint256 minPrice;           // slippage: minimum trading price, validated in Router
        uint256 maxPrice;           // slippage: maximum trading price, validated in Router
        uint256 margin;             // order margin
        uint256 amount;             // close order amount, 0 if order is an open order
        uint16 leverage;            // order leverage, validated in MarketLogic
        int8 direction;             // order direction, validated in MarketLogic
        int8 triggerDirection;      // trigger condition, validated in MarketLogic
        uint256 triggerPrice;       // trigger price
        bool useIP;                 // true if the order is executed by index price
        uint8 reduceOnly;           // 0: false, 1: true
        bool isLiquidate;           // is liquidate order, liquidate orders are generated automatically
        bool isETH;                 // true if order margin payed in ETH
    }

    /// @notice returned data structure when an order is executed, used by MarketLogic.sol::trade
    struct TradeResponse {
        uint256 toTaker;            // refund to the taker
        uint256 tradeValue;         // value of the order
        uint256 leftInterestPayment;// interest payment on the remaining portion of the position
        bool isIncreasePosition;    // if the order causes position value increased
        bool isDecreasePosition;    // true if the order causes position value decreased
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * copy from openzeppelin-contracts
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeCast.sol";

library SignedSafeMath {
    using SafeCast for int256;

    int256 constant private _INT256_MIN = - 2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == - 1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }


    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > - 2 ** 255, "PerpMath: inversion overflow");
        return - a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC20.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        /*
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }
        */

        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}