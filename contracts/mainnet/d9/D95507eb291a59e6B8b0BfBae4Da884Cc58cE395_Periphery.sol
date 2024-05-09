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
import "../interfaces/IERC20.sol";
import "../interfaces/IPriceHelper.sol";

contract Periphery {
    using SignedSafeMath for int256;
    using SignedSafeMath for int8;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    struct MarketConfig {
        MarketDataStructure.MarketConfig marketConfig;
        address pool;
        address marginAsset;
        uint8 marketType;
    }

    struct PoolConfig {
        uint256 minAddLiquidityAmount;
        uint256 minRemoveLiquidityAmount;
        uint256 reserveRate;
        uint256 removeLiquidityFeeRate;
        bool addPaused;
        bool removePaused;
        address baseAsset;
    }

    struct MarketInfo {
        uint256 longSize;
        uint256 shortSize;
        uint256 availableLiquidity;
        // interest info
        uint256 longBorrowRate;
        uint256 longBorrowIG;
        uint256 shortBorrowRate;
        uint256 shortBorrowIG;
        // funding info
        int256 fundingRate;
        int256 frX96;
        int256 fgX96;
        uint256 lastUpdateTs;
    }

    struct PoolInfo {
        int256 balance;
        uint256 sharePrice;
        int256 assetAmount;
        uint256 allMakerFreeze;
        uint256 totalSupply;
        int256 totalUnrealizedPNL;
        int256 makerFundingPayment;
        uint256 interestPayment;
        int256 rlzPNL;
    }

    // rate decimal 1e6

    int256 constant RATE_PRECISION = 1e6;
    // amount decimal 1e20
    uint256 constant AMOUNT_PRECISION = 1e20;
    uint256 constant PRICE_PRECISION = 1e10;

    address manager;
    address marketPriceFeed;
    address priceHelper;

    event UpdateMarketPriceFeed(address priceFeed);
    event UpdatePriceHelper(address priceHelper);

    constructor(address _manager, address _marketPriceFeed, address _priceHelper){
        require(_manager != address(0) && _marketPriceFeed != address(0) && _priceHelper != address(0), "PC0");
        manager = _manager;
        marketPriceFeed = _marketPriceFeed;
        priceHelper = _priceHelper;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "PO0");
        _;
    }

    function updateMarketPriceFeed(address _marketPriceFeed) external onlyController {
        require(_marketPriceFeed != address(0), "PU0");
        marketPriceFeed = _marketPriceFeed;
        emit UpdateMarketPriceFeed(_marketPriceFeed);
    }

    function updatePriceHelper(address _priceHelper) external onlyController {
        require(_priceHelper != address(0), "PUP0");
        priceHelper = _priceHelper;
        emit UpdatePriceHelper(_priceHelper);
    }

    function getMarketConfig(address _market) external view returns (MarketConfig memory config){
        config.marketConfig = IMarket(_market).getMarketConfig();
        config.pool = IMarket(_market).pool();
        config.marginAsset = IManager(manager).getMarketMarginAsset(_market);
        config.marketType = IMarket(_market).marketType();
    }

    function getPoolConfig(address _pool) external view returns (PoolConfig memory config){
        config.minAddLiquidityAmount = IPool(_pool).minAddLiquidityAmount();
        config.minRemoveLiquidityAmount = IPool(_pool).minRemoveLiquidityAmount();
        config.reserveRate = IPool(_pool).reserveRate();
        config.removeLiquidityFeeRate = IPool(_pool).removeLiquidityFeeRate();
        config.addPaused = IPool(_pool).addPaused();
        config.removePaused = IPool(_pool).removePaused();
        config.baseAsset = IPool(_pool).getBaseAsset();
    }

    ///below are view functions
    function getMarketInfo(address market) public view returns (MarketInfo memory info)  {
        address pool = IMarket(market).pool();
        (info.longSize, info.shortSize, info.availableLiquidity) = IPool(pool).getMarketAmount(market);
        (,,uint256 longFreeze,uint256 shortFreeze,,,,,,,) = IPool(pool).poolDataByMarkets(market);
        info.availableLiquidity = info.availableLiquidity.sub(longFreeze).sub(shortFreeze);

        (info.shortBorrowRate, info.shortBorrowIG) = IPool(pool).getCurrentBorrowIG(- 1);   // scaled by 1e27
        (info.longBorrowRate, info.longBorrowIG) = IPool(pool).getCurrentBorrowIG(1);     //  scaled by 1e27

        info.lastUpdateTs = IMarket(market).lastFrX96Ts();
        info.fgX96 = IMarket(market).fundingGrowthGlobalX96();
        (info.frX96, info.fundingRate) = IFundingLogic(IMarket(market).getLogicAddress()).getFunding(market);
    }

    function getPoolInfo(address _pool) external view returns (PoolInfo memory info){
        (info.sharePrice) = getSharePrice(_pool);
        info.balance = IPool(_pool).balance();
        (info.rlzPNL,,,, info.makerFundingPayment, info.interestPayment, info.allMakerFreeze) = getAllMarketData(_pool);
        info.assetAmount = IPool(_pool).balanceReal();
        info.totalSupply = IPool(_pool).totalSupply();
        (,, info.totalUnrealizedPNL) = IPool(_pool).globalHf();
    }

    /// @notice calculate and return the share price of a pool
    function getSharePrice(address _pool) public view returns (uint256 price){
        uint256 totalSupply = IPool(_pool).totalSupply();
        if (totalSupply == 0) {
            price = PRICE_PRECISION;
        } else {
            uint256 baseAssetDecimals = IERC20(IPool(_pool).getBaseAsset()).decimals();
            uint256 decimals = IERC20(_pool).decimals();
            (,uint256 poolTotalTmp,) = IPool(_pool).globalHf();
            price = poolTotalTmp
                .mul(10 ** decimals)
                .div(totalSupply)
                .mul(PRICE_PRECISION)
                .div(10 ** baseAssetDecimals);
        }
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

    struct TakerPositionInfo {
        MarketDataStructure.Position position;
        int256 fundingPayment;
        uint256 interestPayment;
        uint256 maxDecreaseMargin;
    }
    ///@notice get all positions of a taker, if _market is 0, get all positions of the taker
    ///@param _market the market address
    ///@param _taker the taker address
    function getAllPosition(address _market, address _taker) external view returns (TakerPositionInfo memory longInfo, TakerPositionInfo memory shortInfo){
        uint256 longPositionId = getPositionId(_market, _taker, 1);
        uint256 shortPositionId = getPositionId(_market, _taker, - 1);
        longInfo.position = IMarket(_market).getPosition(longPositionId);
        if (longInfo.position.amount > 0) {
            (, longInfo.fundingPayment) = getPositionFundingPayment(_market, longPositionId);
            (longInfo.interestPayment) = getPositionInterestPayment(_market, longPositionId);
            (longInfo.maxDecreaseMargin) = getMaxDecreaseMargin(_market, longPositionId);
        }

        if (longPositionId != shortPositionId) {
            shortInfo.position = IMarket(_market).getPosition(shortPositionId);
            if (shortInfo.position.amount > 0) {
                (, shortInfo.fundingPayment) = getPositionFundingPayment(_market, shortPositionId);
                (shortInfo.interestPayment) = getPositionInterestPayment(_market, shortPositionId);
                (shortInfo.maxDecreaseMargin) = getMaxDecreaseMargin(_market, shortPositionId);
            }
        }
    }

    function getPositionStatus(address _market, uint256 _id) external view returns (bool) {
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        if (position.amount > 0) {
            (address fundingLogic) = IMarket(_market).getLogicAddress();
            MarketDataStructure.MarketConfig memory marketConfig = IMarket(_market).getMarketConfig();
            uint256 indexPrice = IMarketPriceFeed(marketPriceFeed).priceForIndex(IMarket(_market).token(), position.direction == - 1);
            (int256 frX96,) = IFundingLogic(fundingLogic).getFunding(position.market);
            position.fundingPayment = position.fundingPayment.add(IFundingLogic(fundingLogic).getFundingPayment(_market, _id, frX96));
            return IMarketLogic(IMarket(_market).marketLogic()).isLiquidateOrProfitMaximum(position, marketConfig.mm, indexPrice, marketConfig.marketAssetPrecision);
        }
        return false;
    }

    /// @notice get ids of maker's liquidity position id
    /// @param _pool the pool where the order in
    /// @param _maker the address of taker
    function getMakerPositionId(address _pool, address _maker) external view returns (uint256 positionId){
        positionId = IPool(_pool).makerPositionIds(_maker);
    }

    /// @notice get position by pool and position id
    /// @param _pool the pool where the order in
    /// @param _positionId the id of the position to get
    /// @return order
    function getPoolPosition(address _pool, uint256 _positionId) external view returns (IPool.Position memory){
        return IPool(_pool).makerPositions(_positionId);
    }

    /// @notice check if the position can be liquidated
    /// @param _pool maker address
    /// @param _positionId position id
    /// @return status true if the position can be liquidated
    function makerPositionHf(address _pool, uint256 _positionId) external view returns (bool status){
        (uint256 sharePrice) = getSharePrice(_pool);
        IPool.Position memory position = IPool(_pool).makerPositions(_positionId);
        uint256 currentValue = position.liquidity.mul(sharePrice).mul(10 ** IERC20(IPool(_pool).getBaseAsset()).decimals()).div(PRICE_PRECISION).div(10 ** IERC20(_pool).decimals());
        int256 pnl = currentValue.toInt256().sub(position.entryValue.toInt256());
        status = position.initMargin.toInt256().add(pnl) <= currentValue.toInt256().mul(IPool(_pool).mm().toInt256()).div(RATE_PRECISION);
    }

    /// @notice check if the pool can be clear all
    /// @param _pool maker address
    /// @return status true if the pool can be clear all
    function poolHf(address _pool) external view returns (bool status){
        (status,,) = IPool(_pool).globalHf();
    }

    function getMakerPositionLiqPrice(address _pool, uint256 _positionId) external view returns (uint256 liqSharePrice){
        IPool.Position memory position = IPool(_pool).makerPositions(_positionId);
        if (position.liquidity != 0) {
            // 18 + 10 + 18 + 6 = 52
            liqSharePrice = position.entryValue.sub(position.initMargin)
                .mul(PRICE_PRECISION).mul(10 ** IERC20(_pool).decimals()).mul(RATE_PRECISION.toUint256())
                .div(position.liquidity).div(10 ** IERC20(IPool(_pool).getBaseAsset()).decimals()).div(RATE_PRECISION.toUint256().sub(IPool(_pool).mm()));
        }
    }

    struct ClearAllPriceVar {
        int256 balance;
        int256 assetAmount;
        uint256 totalSupply;
        uint256 mm;
        int256 maxUnrealizedPNL;
        int256 makerFundingPayment;
        uint256 interestPayment;
        uint256 longAmount;
        uint256 longOpenTotal;
        uint256 shortAmount;
        uint256 shortOpenTotal;
        int256 deltaSize;
        int256 poolTotalTmp;
        uint256 lpDecimals;
        uint256 assetDecimals;
        int256 tempPrice;
    }

    function getPoolClearAllPrice(address pool, address market) external view returns (uint256 sharePrice, uint256 indexPrice){
        ClearAllPriceVar memory vars;
        vars.balance = IPool(pool).balance();
        vars.assetAmount = IPool(pool).balanceReal();
        vars.totalSupply = IPool(pool).totalSupply();
        vars.mm = IPool(pool).mm();
        vars.lpDecimals = IERC20(pool).decimals();
        vars.assetDecimals = IERC20(IPool(pool).getBaseAsset()).decimals();
        (,,,,,
            vars.makerFundingPayment,
        ,
            vars.longAmount,
            vars.longOpenTotal,
            vars.shortAmount,
            vars.shortOpenTotal
        ) = IPool(pool).poolDataByMarkets(market);
        (,,,,, vars.interestPayment,) = getAllMarketData(pool);
        uint256 precision = 10 ** (20 - vars.assetDecimals);
        uint8 marketType = IMarket(market).marketType();
        vars.poolTotalTmp = vars.balance.add(vars.longOpenTotal.add(vars.shortOpenTotal).div(precision).toInt256()).add(vars.makerFundingPayment).add(vars.interestPayment.toInt256());
        vars.maxUnrealizedPNL = vars.poolTotalTmp.mul(vars.mm.toInt256()).div(RATE_PRECISION).sub(vars.assetAmount).mul(RATE_PRECISION).div(RATE_PRECISION.sub(vars.mm.toInt256()));
        vars.poolTotalTmp = vars.poolTotalTmp.add(vars.maxUnrealizedPNL);
        sharePrice = vars.poolTotalTmp < 0 ? 0 : vars.poolTotalTmp.toUint256().mul(PRICE_PRECISION).mul(10 ** vars.lpDecimals).div(vars.totalSupply).div(10 ** vars.assetDecimals);
        vars.deltaSize = vars.longAmount.toInt256().sub(vars.shortAmount.toInt256()).div(precision.toInt256());
        if (marketType == 1) {
            vars.tempPrice = vars.deltaSize.mul(PRICE_PRECISION.toInt256()).div(vars.longOpenTotal.toInt256().sub(vars.shortOpenTotal.toInt256()).div(precision.toInt256()).add(vars.maxUnrealizedPNL));
            indexPrice = vars.tempPrice < 0 ? 0 : vars.tempPrice.toUint256();
        } else {
            if (marketType == 2) {
                vars.maxUnrealizedPNL = vars.maxUnrealizedPNL.mul(RATE_PRECISION).div((IMarket(market).getMarketConfig().multiplier).toInt256());
            }
            vars.tempPrice = vars.longOpenTotal.toInt256().sub(vars.shortOpenTotal.toInt256()).div(precision.toInt256()).sub(vars.maxUnrealizedPNL).mul(PRICE_PRECISION.toInt256()).div(vars.deltaSize);
            indexPrice = vars.deltaSize == 0 ? 0 : vars.tempPrice < 0 ? 0 : vars.tempPrice.toUint256();
        }
    }

    struct GetAllMarketDataVars {
        uint256 i;
        address[] markets;
        address market;
        int256 _rlzPNL;
        uint256 _longMakerFreeze;
        uint256 _shortMakerFreeze;
        uint256 _takerTotalMargin;
        int256 _makerFundingPayment;
        uint256 _interestPayment;
        uint256 _longInterestPayment;
        uint256 _shortInterestPayment;
    }

    /// @notice calculate the sum data of all markets
    function getAllMarketData(address pool) public view returns (
        int256 rlzPNL,
        uint256 longMakerFreeze,
        uint256 shortMakerFreeze,
        uint256 takerTotalMargin,
        int256 makerFundingPayment,
        uint256 interestPayment,
        uint256 allMakerFreeze
    ){
        GetAllMarketDataVars memory vars;
        vars.markets = IPool(pool).getMarketList();
        vars.market = vars.markets[0];
        (
            rlzPNL,
        ,
            longMakerFreeze,
            shortMakerFreeze,
            takerTotalMargin,
            makerFundingPayment,
            interestPayment,,,,
        ) = IPool(pool).poolDataByMarkets(vars.market);
        
        vars._longInterestPayment = IPool(pool).getCurrentAmount(1, IPool(pool).interestData(1).totalBorrowShare);
        vars._longInterestPayment = vars._longInterestPayment <= longMakerFreeze ? 0 : vars._longInterestPayment.sub(longMakerFreeze);
        vars._shortInterestPayment = IPool(pool).getCurrentAmount(- 1, IPool(pool).interestData(- 1).totalBorrowShare);
        vars._shortInterestPayment = vars._shortInterestPayment <= shortMakerFreeze ? 0 : vars._shortInterestPayment.sub(shortMakerFreeze);
        interestPayment = interestPayment.add(vars._longInterestPayment).add(vars._shortInterestPayment);

        allMakerFreeze = longMakerFreeze.add(shortMakerFreeze);
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
        int256 balance = IPool(_pool).balance();
        (uint256 sharePrice) = getSharePrice(_pool);
        uint256 removeValue = _liquidity.mul(sharePrice).mul(10 ** IERC20(IPool(_pool).getBaseAsset()).decimals()).div(PRICE_PRECISION).div(10 ** IERC20(_pool).decimals());
        return removeValue.toInt256() <= balance;
    }

    /// @notice can add liquidity or not
    /// @param _pool the pool to add liquidity or not
    function canAddLiquidity(address _pool) external view returns (bool){
        (,,,uint256 takerTotalMargin,,, uint256 allMakerFreeze) = getAllMarketData(_pool);
        (,,int256 totalUnPNL) = IPool(_pool).globalHf();
        if (totalUnPNL <= int256(takerTotalMargin) && totalUnPNL.neg256() <= int256(allMakerFreeze)) {
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
        (frX96,) = IFundingLogic(calc).getFunding(market);
        fundingPayment = position.fundingPayment.add(IFundingLogic(calc).getFundingPayment(market, position.id, frX96));
    }

    function getPositionInterestPayment(address market, uint256 positionId) public view returns (uint256 positionInterestPayment){
        MarketDataStructure.Position memory position = IMarket(market).getPosition(positionId);
        address pool = IManager(manager).getMakerByMarket(market);
        uint256 amount = IPool(pool).getCurrentAmount(position.direction, position.debtShare);
        positionInterestPayment = amount < position.makerMargin ? 0 : amount - position.makerMargin;
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
        uint256 payInterest = IPool(IMarket(market).pool()).getCurrentAmount(position.direction, position.debtShare);
        payInterest = payInterest < position.makerMargin ? 0 : payInterest.sub(position.makerMargin);
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

    function executeOrder(uint256 _id) external returns (int256, uint256, bool);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action, uint256 clearPrice) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool isExecutedByIndexPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);
    
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

import "./IPriceHelper.sol";

interface IMarketPriceFeed {
    function priceForTrade(address pool, address market, string memory token, int8 takerDirection, uint256 deltaSize, uint256 deltaValue, bool isLiquidation) external returns (uint256 size, uint256 vol, uint256 tradePrice);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);

    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;

    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    function modifyMarketTickConfig(address pool, address market, string memory token, IPriceHelper.MarketTickConfig memory cfg) external;

    function getMarketPrice(address market, string memory _token, bool maximise) external view returns (uint256 marketPrice);
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
pragma abicoder v2;
import "../libraries/Tick.sol";

interface IPriceHelper {
    struct MarketTickConfig {
        bool isLinear;
        uint8 marketType;
        uint8 liquidationIndex;
        uint256 baseAssetDivisor;
        uint256 multiplier; // different precision from rate divisor
        uint256 maxLiquidity;
        Tick.Config[7] tickConfigs;
    }

    struct CalcTradeInfoParams {
        address pool;
        address market;
        uint256 indexPrice;
        bool isTakerLong;
        bool liquidation;
        uint256 deltaSize;
        uint256 deltaValue;
    }

    function calcTradeInfo(CalcTradeInfoParams memory params) external returns(uint256 deltaSize, uint256 volTotal, uint256 tradePrice);
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;
    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) external;
    function getMarketPrice(address market, uint256 indexPrice) external view returns (uint256 marketPrice);
    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    event TickConfigChanged(address market, MarketTickConfig cfg);
    event TickInfoChanged(address market, uint8 index, uint256 size, uint256 premiumX96);
    event Slot0StateChanged(address market, uint256 netSize, uint256 premiumX96, bool isLong, uint8 currentTick);
    event LiquidationBufferSizeChanged(address market, uint8 index, uint256 bufferSize);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

library Constant {
    uint256 constant Q96 = 1 << 96;
    uint256 constant RATE_DIVISOR = 1e8;
    uint256 constant PRICE_DIVISOR = 1e10;// 1e10
    uint256 constant SIZE_DIVISOR = 1e20;// 1e20 for AMOUNT_PRECISION
    uint256 constant TICK_LENGTH = 7;
    uint256 constant MULTIPLIER_DIVISOR = 1e6;

    int256 constant FundingRate1_10000X96 = int256(Q96) * 1 / 10000;
    int256 constant FundingRate4_10000X96 = int256(Q96) * 4 / 10000;
    int256 constant FundingRate5_10000X96 = int256(Q96) * 5 / 10000;
    int256 constant FundingRate6_10000X96 = int256(Q96) * 6 / 10000;
    int256 constant FundingRateMaxX96 = int256(Q96) * 375 / 100000;
    int256 constant FundingRate8Hours = 8 hours;
    int256 constant FundingRate24Hours = 24 hours;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "./Constant.sol";
import "./SafeMath.sol";

library Tick {
    using SafeMath for uint256;

    struct Info {
        uint256 size;
        uint256 premiumX96;
    }

    struct Config {
        uint32 sizeRate;
        uint32 premium;
    }

    function calcTickInfo(uint32 sizeRate, uint32 premium, bool isLinear, uint256 liquidity, uint256 indexPrice) internal pure returns (uint256 size, uint256 premiumX96){
        if(isLinear) {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(Constant.PRICE_DIVISOR).div(indexPrice);
        } else {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(indexPrice).div(Constant.PRICE_DIVISOR);
        }

        premiumX96 = uint256(premium).mul(Constant.Q96).div(Constant.RATE_DIVISOR);
    }
}