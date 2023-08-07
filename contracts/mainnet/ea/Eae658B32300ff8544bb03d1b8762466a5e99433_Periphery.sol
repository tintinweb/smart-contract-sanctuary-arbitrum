// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/SafeCast.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SignedSafeMath.sol";
import "../libraries/MarketDataStructure.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IFundingLogic.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IMarketLogic.sol";
import "../interfaces/IMarketPriceFeed.sol";
import "../interfaces/IMarketLogic.sol";
import "../core/PoolStorage.sol";

contract Periphery {
    using SignedSafeMath for int256;
    using SignedSafeMath for int8;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    struct MarketInfo {
        address market;
        address pool;
        address token;
        address marginAsset;
        uint8 marketType;
        MarketDataStructure.MarketConfig marketConfig;
    }

    struct PoolInfo {
        uint256 minAddLiquidityAmount;
        uint256 minRemoveLiquidityAmount;
        uint256 reserveRate;
        uint256 removeLiquidityFeeRate;
        uint256 balance;
        uint256 sharePrice;
        uint256 assetAmount;
        bool addPaused;
        bool removePaused;
        uint256 totalSupply;
    }

    // rate decimal 1e6

    int256 public constant RATE_PRECISION = 1e6;
    // amount decimal 1e20
    uint256 public constant AMOUNT_PRECISION = 1e20;

    address public manager;
    address public marketPriceFeed;

    event UpdateMarketPriceFeed(address priceFeed);

    constructor(address _manager, address _marketPriceFeed) {
        require(_manager != address(0), "Periphery: _manager is the zero address");
        require(_marketPriceFeed != address(0), "Periphery: _marketPriceFeed is the zero address");
        manager = _manager;
        marketPriceFeed = _marketPriceFeed;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "Periphery: Must be controller");
        _;
    }

    function updateMarketPriceFeed(address _marketPriceFeed) external onlyController {
        require(_marketPriceFeed != address(0), "Periphery: _marketPriceFeed is the zero address");
        marketPriceFeed = _marketPriceFeed;
        emit UpdateMarketPriceFeed(_marketPriceFeed);
    }

    ///below are view functions
    function getAllMarkets() public view returns (MarketInfo[] memory) {
        address[]  memory markets = IManager(manager).getAllMarkets();
        MarketInfo[] memory infos = new MarketInfo[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            MarketInfo memory info;
            info.market = markets[i];
            info.pool = IMarket(markets[i]).pool();
            info.marginAsset = IManager(manager).getMarketMarginAsset(markets[i]);
            info.marketType = IMarket(markets[i]).marketType();
            info.marketConfig = IMarket(markets[i]).getMarketConfig();
            infos[i] = info;
        }
        return infos;
    }

    function getAllPools() external view returns (address[] memory) {
        return IManager(manager).getAllPools();
    }

    function getPoolInfo(address _pool) external view returns (PoolInfo memory info){
        info.minAddLiquidityAmount = IPool(_pool).minAddLiquidityAmount();
        info.minRemoveLiquidityAmount = IPool(_pool).minRemoveLiquidityAmount();
        info.reserveRate = IPool(_pool).reserveRate();
        info.removeLiquidityFeeRate = IPool(_pool).removeLiquidityFeeRate();
        (info.sharePrice, info.balance) = IPool(_pool).getSharePrice();
        info.assetAmount = IPool(_pool).getAssetAmount();
        info.addPaused = IPool(_pool).addPaused();
        info.removePaused = IPool(_pool).removePaused();
        info.totalSupply = IPool(_pool).totalSupply();
    }

    function getOrderIds(address _market, address taker) external view returns (uint256[] memory) {
        return IMarket(_market).getOrderIds(taker);
    }

    function getOrder(address _market, uint256 id) public view returns (MarketDataStructure.Order memory) {
        return IMarket(_market).getOrder(id);
    }

    function getPositionId(address _market, address _taker, int8 _direction) public view returns (uint256) {
        uint256 id = IMarket(_market).getPositionId(_taker, _direction);
        return id;
    }

    function getPosition(address _market, uint256 _id) public view returns (MarketDataStructure.Position memory _position, int256 _fundingPayment, uint256 _interestPayment, uint256 _maxDecreaseMargin) {
        (_position) = IMarket(_market).getPosition(_id);
        (, _fundingPayment) = getPositionFundingPayment(_market, _position.id);
        (_interestPayment) = getPositionInterestPayment(_market, _position.id);
        (_maxDecreaseMargin) = getMaxDecreaseMargin(_market, _position.id);
    }

    ///@notice get all positions of a taker, if _market is 0, get all positions of the taker
    ///@param _market the market address
    ///@param _taker the taker address
    ///@return positions the positions of the taker
    function getAllPosition(address _market, address _taker) external view returns (MarketDataStructure.Position[] memory) {
        address[] memory markets;

        if (_market != address(0)) {
            markets = new address[](1);
            markets[0] = _market;
        } else {
            markets = IManager(manager).getAllMarkets();
        }

        MarketDataStructure.Position[] memory positions = new MarketDataStructure.Position[](markets.length * 2);
        uint256 index;
        for (uint256 i = 0; i < markets.length; i++) {
            uint256 longPositionId = getPositionId(markets[i], _taker, 1);
            MarketDataStructure.Position memory longPosition = IMarket(_market).getPosition(longPositionId);
            if (longPosition.amount > 0) {
                positions[index] = longPosition;
                index++;
            }

            uint256 shortPositionId = getPositionId(markets[i], _taker, - 1);
            if (longPositionId == shortPositionId) continue;
            MarketDataStructure.Position memory shortPosition = IMarket(_market).getPosition(shortPositionId);
            if (shortPosition.amount > 0) {
                positions[index] = shortPosition;
                index++;
            }
        }
        return positions;
    }

    function getPositionStatus(address _market, uint256 _id) external view returns (bool) {
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        if (position.amount > 0) {
            (address fundingLogic) = IMarket(_market).getLogicAddress();
            MarketDataStructure.MarketConfig memory marketConfig = IMarket(_market).getMarketConfig();
            uint256 indexPrice = IMarketPriceFeed(marketPriceFeed).priceForIndex(IMarket(_market).token(), position.direction == - 1);
            int256 frX96 = IFundingLogic(fundingLogic).getFunding(position.market);
            position.fundingPayment = position.fundingPayment.add(IFundingLogic(fundingLogic).getFundingPayment(_market, _id, frX96));
            return IMarketLogic(IMarket(_market).marketLogic()).isLiquidateOrProfitMaximum(position, marketConfig.mm, indexPrice, marketConfig.marketAssetPrecision);
        }
        return false;
    }

    /// @notice get ids of maker's liquidity order
    /// @param _pool the pool where the order in
    /// @param _maker the address of taker
    function getMakerOrderIds(address _pool, address _maker) external view returns (uint256[] memory _orderIds){
        (_orderIds) = IPool(_pool).getMakerOrderIds(_maker);
    }

    /// @notice get order by pool and order id
    /// @param _pool the pool where the order in
    /// @param _id the id of the order to get
    /// @return order
    function getPoolOrder(address _pool, uint256 _id) external view returns (PoolDataStructure.MakerOrder memory order){
        return IPool(_pool).getOrder(_id);
    }

    /// @notice get amount of lp by pool and taker
    /// @param _pool the pool where the liquidity in
    /// @param _maker the address of taker
    function getLpBalanceOf(address _pool, address _maker) external view returns (uint256 _liquidity, uint256 _totalSupply){
        (_liquidity, _totalSupply) = IPool(_pool).getLpBalanceOf(_maker);
    }

    /// @notice check can open or not
    /// @param _pool the pool to open
    /// @param _makerMargin margin amount
    /// @return result
    function canOpen(address _pool, address _market, uint256 _makerMargin) external view returns (bool){
        return IPool(_pool).canOpen(_market, _makerMargin);
    }

    /// @notice can remove liquidity or not
    /// @param _pool the pool to remove liquidity
    /// @param _liquidity the amount to remove liquidity
    function canRemoveLiquidity(address _pool, uint256 _liquidity) external view returns (bool){
        uint256 totalSupply = IPool(_pool).totalSupply();
        (,uint256 balance) = IPool(_pool).getSharePrice();
        if (totalSupply > 0) {
            (PoolStorage.DataByMarket memory allMarketPos, uint256 allMakerFreeze) = IPool(_pool).getAllMarketData();
            int256 totalUnPNL = IPool(_pool).makerProfitForLiquidity(false);
            if (totalUnPNL <= int256(allMarketPos.takerTotalMargin) && totalUnPNL * (- 1) <= int256(allMakerFreeze)) {
                uint256 amount = _liquidity.mul(allMakerFreeze.toInt256().add(balance.toInt256()).add(totalUnPNL).add(allMarketPos.makerFundingPayment).toUint256()).div(totalSupply);
                if (balance >= amount) {
                    return true;
                }
            }
        }
        return false;
    }


    /// @notice can add liquidity or not
    /// @param _pool the pool to add liquidity or not
    function canAddLiquidity(address _pool) external view returns (bool){
        (PoolStorage.DataByMarket memory allMarketPos, uint256 allMakerFreeze) = IPool(_pool).getAllMarketData();
        int256 totalUnPNL = IPool(_pool).makerProfitForLiquidity(true);
        if (totalUnPNL <= int256(allMarketPos.takerTotalMargin) && totalUnPNL.neg256() <= int256(allMakerFreeze)) {
            return true;
        }
        return false;
    }

    /// @notice get funding info
    /// @param id position id
    /// @param market the market address
    /// @return frX96 current funding rate
    /// @return fundingPayment funding payment
    function getPositionFundingPayment(address market, uint256 id) public view returns (int256 frX96, int256 fundingPayment){
        MarketDataStructure.Position memory position = IMarket(market).getPosition(id);
        (address calc) = IMarket(market).getLogicAddress();
        frX96 = IFundingLogic(calc).getFunding(market);
        fundingPayment = position.fundingPayment.add(IFundingLogic(calc).getFundingPayment(market, position.id, frX96));
    }

    function getPositionInterestPayment(address market, uint256 positionId) public view returns (uint256 positionInterestPayment){
        MarketDataStructure.Position memory position = IMarket(market).getPosition(positionId);
        address pool = IManager(manager).getMakerByMarket(market);
        uint256 amount = IPool(pool).getCurrentAmount(position.direction, position.debtShare);
        positionInterestPayment = amount < position.makerMargin ? 0 : amount - position.makerMargin;
    }

    function getFundingInfo(address market) external view returns (int256 frX96, int256 fgX96, uint256 lastUpdateTs){
        lastUpdateTs = IMarket(market).lastFrX96Ts();
        fgX96 = IMarket(market).fundingGrowthGlobalX96();
        (address calc) = IMarket(market).getLogicAddress();
        frX96 = IFundingLogic(calc).getFunding(market);
    }

    /// @notice get funding and interest info
    /// @param market the market address
    /// @return longBorrowRate one hour per ，scaled by 1e27
    /// @return longBorrowIG current ig
    /// @return shortBorrowRate one hour per ，scaled by 1e27
    /// @return shortBorrowIG current ig
    /// @return frX96 current fr
    /// @return fgX96 last fr
    /// @return lastUpdateTs last update time
    function getFundingAndInterestInfo(address market) public view returns (uint256 longBorrowRate, uint256 longBorrowIG, uint256 shortBorrowRate, uint256 shortBorrowIG, int256 frX96, int256 fgX96, uint256 lastUpdateTs){
        lastUpdateTs = IMarket(market).lastFrX96Ts();
        fgX96 = IMarket(market).fundingGrowthGlobalX96();
        (address calc) = IMarket(market).getLogicAddress();
        frX96 = IFundingLogic(calc).getFunding(market);

        address pool = IManager(manager).getMakerByMarket(market);
        (longBorrowRate, longBorrowIG) = IPool(pool).getCurrentBorrowIG(1);
        (shortBorrowRate, shortBorrowIG) = IPool(pool).getCurrentBorrowIG(- 1);
    }

    /// @notice get order id info
    /// @param market the market address
    /// @return orderID last order id
    /// @return lastExecutedOrderId last executed order id
    /// @return triggerOrderID last trigger order id
    function getMarketOrderIdInfo(address market) external view returns (uint256 orderID, uint256 lastExecutedOrderId, uint256 triggerOrderID){
        orderID = IMarket(market).orderID();
        lastExecutedOrderId = IMarket(market).lastExecutedOrderId();
        triggerOrderID = IMarket(market).triggerOrderID();
    }

    function getPositionMode(address _market, address _taker) external view returns (MarketDataStructure.PositionMode _mode){
        return IMarket(_market).positionModes(_taker);
    }

    function getMaxDecreaseMargin(address market, uint256 positionId) public view returns (uint256){
        return IMarketLogic(IMarket(market).marketLogic()).getMaxTakerDecreaseMargin(IMarket(market).getPosition(positionId));
    }

    function getOrderNumLimit(address _market, address _taker) external view returns (uint256 _currentOpenNum, uint256 _currentCloseNum, uint256 _currentTriggerOpenNum, uint256 _currentTriggerCloseNum, uint256 _limit){
        _currentOpenNum = IMarket(_market).takerOrderNum(_taker, MarketDataStructure.OrderType.Open);
        _currentCloseNum = IMarket(_market).takerOrderNum(_taker, MarketDataStructure.OrderType.Close);
        _currentTriggerOpenNum = IMarket(_market).takerOrderNum(_taker, MarketDataStructure.OrderType.TriggerOpen);
        _currentTriggerCloseNum = IMarket(_market).takerOrderNum(_taker, MarketDataStructure.OrderType.TriggerClose);
        _limit = IManager(manager).orderNumLimit();
    }

    /// @notice get position's liq price
    /// @param positionId position id
    ///@return liqPrice liquidation price,price is scaled by 1e8
    function getPositionLiqPrice(address market, uint256 positionId) external view returns (uint256 liqPrice){
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(market).getMarketConfig();
        uint8 marketType = IMarket(market).marketType();

        MarketDataStructure.Position memory position = IMarket(market).getPosition(positionId);
        if (position.amount == 0) return 0;
        //calc position current payInterest
        uint256 payInterest = IPool(IMarket(market).pool()).getCurrentAmount(position.direction, position.debtShare).sub(position.makerMargin);
        //calc position current fundingPayment
        (, position.fundingPayment) = getPositionFundingPayment(position.market, positionId);
        int256 numerator;
        int256 denominator;
        int256 value = position.value.mul(marketConfig.marketAssetPrecision).div(AMOUNT_PRECISION).toInt256();
        int256 amount = position.amount.mul(marketConfig.marketAssetPrecision).div(AMOUNT_PRECISION).toInt256();
        if (marketType == 0) {
            numerator = position.fundingPayment.add(payInterest.toInt256()).add(value.mul(position.direction)).sub(position.takerMargin.toInt256()).mul(RATE_PRECISION);
            denominator = RATE_PRECISION.mul(position.direction).sub(marketConfig.mm.toInt256()).mul(amount);
        } else if (marketType == 1) {
            numerator = marketConfig.mm.toInt256().add(position.direction.mul(RATE_PRECISION)).mul(amount);
            denominator = position.takerMargin.toInt256().sub(position.fundingPayment).sub(payInterest.toInt256()).add(value.mul(position.direction)).mul(RATE_PRECISION);
        } else {
            numerator = position.fundingPayment.add(payInterest.toInt256()).sub(position.takerMargin.toInt256()).mul(RATE_PRECISION).add(value.mul(position.multiplier.toInt256()).mul(position.direction)).mul(RATE_PRECISION);
            denominator = RATE_PRECISION.mul(position.direction).sub(marketConfig.mm.toInt256()).mul(amount).mul(position.multiplier.toInt256());
        }

        if (denominator == 0) return 0;

        liqPrice = numerator.mul(1e8).div(denominator).toUint256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256  constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256  constant PRICE_PRECISION = 1e10;
    uint256  constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address public vault;                                       // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 public baseAssetDecimals;                           // base token decimals
    address public interestLogic;                               // interest logic address
    address public WETH;                                        // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity

    uint256 public balance;                                     // balance that is available to use of this pool
    uint256 public reserveRate;                                 // reserve ratio
    uint256 public sharePrice;                                  // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId = 1;                                  // liquidity operations order id
    mapping(address => uint256) lastOperationTime;              // mapping of last operation timestamp for addresses

    address[] public marketList;                                // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(uint256 => PoolDataStructure.MakerOrder) makerOrders;           // liquidity orders
    mapping(address => uint256[]) public makerOrderIds;         // mapping of liquidity orders for addresses
    mapping(address => uint256) public freezeBalanceOf;         // frozen liquidity amount when removing
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)

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
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    event RegisterMarket(address market);
    event SetMinAddLiquidityAmount(uint256 minAmount);
    event SetMinRemoveLiquidity(uint256 minLp);
    event SetOpenRateAndLimit(address market, uint256 openRate, uint256 openLimit);
    event SetReserveRate(uint256 reserveRate);
    event SetRemoveLiquidityFeeRatio(uint256 feeRate);
    event SetPaused(bool addPaused, bool removePaused);
    event SetInterestLogic(address interestLogic);
    event SetMarketPriceFeed(address marketPriceFeed);
    event ExecuteAddLiquidityOrder(uint256 orderId, address maker, uint256 amount, uint256 share, uint256 sharePrice);
    event ExecuteRmLiquidityOrder(uint256 orderId, address maker, uint256 rmAmount, uint256 rmShare, uint256 sharePrice, uint256 rmFee);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IFundingLogic {
    function getFunding(address market) external view returns (int256 fundingGrowthGlobalX96);

    function getFundingPayment(address market, uint256 positionId, int256 fundingGrowthGlobalX96) external view returns (int256 fundingPayment);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSigner(address _signer) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused() external view returns (bool);

    function isInterestPaused() external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkLiquidator(address _liquidator) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarket {
    function setMarketConfig(MarketDataStructure.MarketConfig memory _config) external;

    function updateFundingGrowthGlobal() external;

    function getMarketConfig() external view returns (MarketDataStructure.MarketConfig memory);

    function marketType() external view returns (uint8);

    function positionModes(address) external view returns (MarketDataStructure.PositionMode);

    function fundingGrowthGlobalX96() external view returns (int256);

    function lastFrX96Ts() external view returns (uint256);

    function takerOrderTotalValues(address, int8) external view returns (int256);

    function pool() external view returns (address);

    function getPositionId(address _trader, int8 _direction) external view returns (uint256);

    function getPosition(uint256 _id) external view returns (MarketDataStructure.Position memory);

    function getOrderIds(address _trader) external view returns (uint256[] memory);

    function getOrder(uint256 _id) external view returns (MarketDataStructure.Order memory);

    function createOrder(MarketDataStructure.CreateInternalParams memory params) external returns (uint256 id);

    function cancel(uint256 _id) external;

    function executeOrder(uint256 _id) external returns (int256, uint256);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);

    function lastExecutedOrderId() external view returns (uint256);

    function triggerOrderID() external view returns (uint256);

    function marketLogic() external view returns (address);

    function token() external view returns (string memory);
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

    function trade(uint256 id, uint256 positionId, uint256, uint256) external view returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response, uint256 errCode);

    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view returns (MarketDataStructure.Order memory order);

    function getLiquidateInfo(LiquidityInfoParams memory params) external view returns (LiquidateInfoResponse memory response);

    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) external view returns (bool);

    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view returns (uint256 maxDecreaseMargin);

    function checkOrder(uint256 id) external view;

    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) external view;

    function checkoutConfig(address market, MarketDataStructure.MarketConfig memory _config) external view;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IMarketPriceFeed {
    function priceForTrade(string memory _token, uint256 value, uint256 maxValue, bool _maximise) external view returns (uint256);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/PoolDataStructure.sol";
import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }

    /// @notice the following tow structs are parameters used to update pool data when an order is executed.
    ///         We differ the affect of the executed order by result as open or close,
    ///         which represents increase or decrease the position.
    ///         Normally, there's one type of pool update operation during one order execution,
    ///         excepts in the one-way position model, when an order causing the position reversal, both opening and
    ///         closing process will be executed respectively.

    struct OpenUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;   // pool balance taken by this order
        uint256 _takerMargin;   // taker margin for this order
        uint256 _amount;        // order amount
        uint256 _total;         // order value
        uint256 makerFee;       // fees distributed to the pool, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        int8 _takerDirection;   // order direction
        uint256 marginToVault;  // margin should transferred to the vault
        address taker;          // taker address
        uint256 feeToInviter;   // fees distributed to the inviter, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        address inviter;        // inviter address
        uint256 deltaDebtShare; //add position debt share
        uint256 feeToExchange;  // fee distributed to the protocol, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
    }

    struct CloseUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 _takerMargin;
        uint256 _amount;
        uint256 _total;
        int256 _makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 _takerDirection;//old position direction
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

    function setMinAddLiquidityAmount(uint256 _minAmount) external returns (bool);

    function setMinRemoveLiquidity(uint256 _minLiquidity) external returns (bool);

    function setOpenRate(address _market, uint256 _openRate, uint256 _openLimit) external returns (bool);

    //function setRemoveLiquidityFeeRatio(uint256 _rate) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function getOrder(uint256 _no) external view returns (PoolDataStructure.MakerOrder memory);

    function openUpdate(OpenUpdateInternalParams memory params) external returns (bool);

    function closeUpdate(CloseUpdateInternalParams memory params) external returns (bool);

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external returns (bool);

    function addLiquidity(address sender, uint256 amount) external returns (uint256 _id);

    function executeAddLiquidityOrder(uint256 id) external returns (uint256 liquidity);

    function removeLiquidity(address sender, uint256 liquidity) external returns (uint256 _id, uint256 _liquidity);

    function executeRmLiquidityOrder(uint256 id, bool isETH) external returns (uint256 amount);

    function getLpBalanceOf(address _maker) external view returns (uint256 _balance, uint256 _totalSupply);

    function registerMarket(address _market) external returns (bool);

    function getSharePrice() external view returns (
        uint256 _price,
        uint256 _balance
    );

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getAllMarketData() external view returns (PoolStorage.DataByMarket memory allMarketPos, uint256 allMakerFreeze);

    function getAssetAmount() external view returns (uint256 amount);

    function getBaseAsset() external view returns (address);

    function getAutoId() external view returns (uint256);

//    function updateLiquidatorFee(address _liquidator) external;

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function makerProfitForLiquidity(bool isAdd) external view returns (int256 unPNL);
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
        UserStopLoss
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        OneWay,
        Hedge
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
        
        uint256 createTs;                         // create timestamp
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
library PoolDataStructure {
    enum PoolAction {
        Deposit,
        Withdraw
    }

    enum PoolActionStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    /// @notice data structure of adding or removing liquidity order
    struct MakerOrder {
        uint256 id;                     // liquidity order id, generated by counter
        address maker;                  // user address
        uint256 submitBlockTimestamp;   // timestamp when order submitted
        uint256 amount;                 // base asset amount
        uint256 liquidity;              // liquidity
        uint256 feeToPool;              // fee charged when remove liquidity
        uint256 sharePrice;             // pool share price when order is executed
        int256 poolTotal;               // pool total valuation when order is executed
        int256 profit;                  // pool profit when order is executed, pnl + funding earns + interest earns
        PoolAction action;              // order action type
        PoolActionStatus status;        // order status
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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

// SPDX-License-Identifier: GPL-2.0-or-later
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