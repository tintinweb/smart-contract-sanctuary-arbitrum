//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./interfaces/IPerpetualMarketCore.sol";
import "./lib/NettingLib.sol";
import "./lib/IndexPricer.sol";
import "./lib/SpreadLib.sol";
import "./lib/EntryPriceMath.sol";
import "./lib/PoolMath.sol";

/**
 * @title PerpetualMarketCore
 * @notice Perpetual Market Core Contract manages perpetual pool positions and calculates amount of collaterals.
 * Error Code
 * PMC0: No available liquidity
 * PMC1: No available liquidity
 * PMC2: caller must be PerpetualMarket contract
 * PMC3: underlying price must not be 0
 * PMC4: pool delta must be negative
 * PMC5: invalid params
 */
contract PerpetualMarketCore is IPerpetualMarketCore, Ownable, ERC20 {
    using NettingLib for NettingLib.Info;
    using SpreadLib for SpreadLib.Info;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    uint256 private constant MAX_PRODUCT_ID = 2;

    // λ for exponentially weighted moving average is 94%
    int256 private constant LAMBDA = 94 * 1e6;

    // funding period is 1 days
    int256 private constant FUNDING_PERIOD = 1 days;

    // max ratio of (IV/RV)^2 for squeeth pool
    int256 private squaredPerpFundingMultiplier;

    // max funding rate of future pool
    int256 private perpFutureMaxFundingRate;

    // min slippage tolerance of a hedge
    uint256 private minSlippageToleranceOfHedge;

    // max slippage tolerance of a hedge
    uint256 private maxSlippageToleranceOfHedge;

    // rate of return threshold of a hedge
    uint256 private hedgeRateOfReturnThreshold;

    // allowable percentage of movement in the underlying spot price
    int256 private poolMarginRiskParam;

    // trade fee
    int256 private tradeFeeRate;

    // protocol fee
    int256 private protocolFeeRate;

    struct Pool {
        uint128 amountLockedLiquidity;
        int128 positionPerpetuals;
        uint128 entryPrice;
        int256 amountFundingPaidPerPosition;
        uint128 lastFundingPaymentTime;
    }

    struct PoolSnapshot {
        int128 futureBaseFundingRate;
        int128 ethVariance;
        int128 ethPrice;
        uint128 lastSnapshotTime;
    }

    enum MarginChange {
        ShortToShort,
        ShortToLong,
        LongToLong,
        LongToShort
    }

    // Total amount of liquidity provided by LPs
    uint256 public amountLiquidity;

    // Pools information storage
    mapping(uint256 => Pool) public pools;

    // Infos for spread calculation
    mapping(uint256 => SpreadLib.Info) private spreadInfos;

    // Infos for LPToken's spread calculation
    SpreadLib.Info private lpTokenSpreadInfo;

    // Snapshot of pool state at last ETH variance calculation
    PoolSnapshot internal poolSnapshot;

    // Infos for collateral calculation
    NettingLib.Info private nettingInfo;

    // The address of Chainlink price feed
    AggregatorV3Interface private priceFeed;

    // The last spot price at heding
    int256 public lastHedgeSpotPrice;

    // The address of Perpetual Market Contract
    address private perpetualMarket;

    event FundingPayment(
        uint256 productId,
        int256 fundingRate,
        int256 amountFundingPaidPerPosition,
        int256 fundingPaidPerPosition,
        int256 poolReceived
    );
    event VarianceUpdated(int256 variance, int256 underlyingPrice, uint256 timestamp);

    event SetSquaredPerpFundingMultiplier(int256 squaredPerpFundingMultiplier);
    event SetPerpFutureMaxFundingRate(int256 perpFutureMaxFundingRate);
    event SetHedgeParams(
        uint256 minSlippageToleranceOfHedge,
        uint256 maxSlippageToleranceOfHedge,
        uint256 hedgeRateOfReturnThreshold
    );
    event SetPoolMarginRiskParam(int256 poolMarginRiskParam);
    event SetTradeFeeRate(int256 tradeFeeRate, int256 protocolFeeRate);

    modifier onlyPerpetualMarket() {
        require(msg.sender == perpetualMarket, "PMC2");
        _;
    }

    constructor(
        address _priceFeedAddress,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        // The decimals of LP token is 8
        _setupDecimals(8);

        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        // initialize spread infos
        spreadInfos[0].init();
        spreadInfos[1].init();

        // 550%
        squaredPerpFundingMultiplier = 550 * 1e6;
        // 0.22%
        perpFutureMaxFundingRate = 22 * 1e4;
        // min slippage tolerance of a hedge is 0.4%
        minSlippageToleranceOfHedge = 40;
        // max slippage tolerance of a hedge is 0.8%
        maxSlippageToleranceOfHedge = 80;
        // rate of return threshold of a hedge is 2.5 %
        hedgeRateOfReturnThreshold = 25 * 1e5;
        // Pool collateral risk param is 40%
        poolMarginRiskParam = 4000;
        // Trade fee is 0.05%
        tradeFeeRate = 5 * 1e4;
        // Protocol fee is 0.02%
        protocolFeeRate = 2 * 1e4;
    }

    function setPerpetualMarket(address _perpetualMarket) external onlyOwner {
        require(perpetualMarket == address(0) && _perpetualMarket != address(0));
        perpetualMarket = _perpetualMarket;
    }

    /**
     * @notice Initialize pool with initial liquidity and funding rate
     */
    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external override onlyPerpetualMarket returns (uint256 mintAmount) {
        require(totalSupply() == 0);
        mintAmount = _depositAmount;

        (int256 spotPrice, ) = getUnderlyingPrice();

        // initialize pool snapshot
        poolSnapshot.ethVariance = _initialFundingRate.toInt128();
        poolSnapshot.ethPrice = spotPrice.toInt128();
        poolSnapshot.lastSnapshotTime = block.timestamp.toUint128();

        // initialize last spot price at heding
        lastHedgeSpotPrice = spotPrice;

        amountLiquidity = amountLiquidity.add(_depositAmount);
        _mint(_depositor, mintAmount);
    }

    /**
     * @notice Provides liquidity
     */
    function deposit(address _depositor, uint256 _depositAmount)
        external
        override
        onlyPerpetualMarket
        returns (uint256 mintAmount)
    {
        require(totalSupply() > 0);

        uint256 lpTokenPrice = getLPTokenPrice(_depositAmount.toInt256());

        lpTokenPrice = lpTokenSpreadInfo.checkPrice(true, int256(lpTokenPrice)).toUint256();

        mintAmount = _depositAmount.mul(1e16).div(lpTokenPrice);

        amountLiquidity = amountLiquidity.add(_depositAmount);
        _mint(_depositor, mintAmount);
    }

    /**xx
     * @notice Withdraws liquidity
     */
    function withdraw(address _withdrawer, uint256 _withdrawnAmount)
        external
        override
        onlyPerpetualMarket
        returns (uint256 burnAmount)
    {
        require(getAvailableLiquidityAmount() >= _withdrawnAmount, "PMC0");

        uint256 lpTokenPrice = getLPTokenPrice(-_withdrawnAmount.toInt256());

        lpTokenPrice = lpTokenSpreadInfo.checkPrice(false, int256(lpTokenPrice)).toUint256();

        burnAmount = _withdrawnAmount.mul(1e16).div(lpTokenPrice);

        amountLiquidity = amountLiquidity.sub(_withdrawnAmount);
        _burn(_withdrawer, burnAmount);
    }

    function addLiquidity(uint256 _amount) external override onlyPerpetualMarket {
        amountLiquidity = amountLiquidity.add(_amount);
    }

    /**
     * @notice Adds or removes positions
     * @param _productId product id
     * @param _tradeAmount amount of position to trade. positive for pool short and negative for pool long.
     */
    function updatePoolPosition(uint256 _productId, int128 _tradeAmount)
        public
        override
        onlyPerpetualMarket
        returns (
            uint256 tradePrice,
            int256,
            uint256 protocolFee
        )
    {
        require(amountLiquidity > 0, "PMC1");

        (int256 spotPrice, ) = getUnderlyingPrice();

        // Updates pool position
        pools[_productId].positionPerpetuals -= _tradeAmount;

        // Calculate trade price
        (tradePrice, protocolFee) = calculateSafeTradePrice(_productId, spotPrice, _tradeAmount);

        {
            (int256 newEntryPrice, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(pools[_productId].entryPrice),
                pools[_productId].positionPerpetuals.add(_tradeAmount),
                int256(tradePrice),
                -_tradeAmount
            );

            pools[_productId].entryPrice = newEntryPrice.toUint256().toUint128();

            amountLiquidity = Math.addDelta(amountLiquidity, profitValue - protocolFee.toInt256());
        }

        return (tradePrice, pools[_productId].amountFundingPaidPerPosition, protocolFee);
    }

    /**
     * @notice Locks liquidity if more collateral required
     * and unlocks liquidity if there is unrequied collateral.
     */
    function rebalance() external override onlyPerpetualMarket {
        (int256 spotPrice, ) = getUnderlyingPrice();

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            int256 deltaMargin;
            int256 deltaLiquidity;

            {
                int256 hedgePositionValue;
                (deltaMargin, hedgePositionValue) = addMargin(i, spotPrice);

                (, deltaMargin, deltaLiquidity) = calculatePreTrade(
                    i,
                    deltaMargin,
                    hedgePositionValue,
                    MarginChange.LongToLong
                );
            }

            if (deltaLiquidity != 0) {
                amountLiquidity = Math.addDelta(amountLiquidity, deltaLiquidity);
            }
            if (deltaMargin != 0) {
                pools[i].amountLockedLiquidity = Math.addDelta(pools[i].amountLockedLiquidity, deltaMargin).toUint128();
            }
        }
    }

    /**
     * @notice Gets USDC and underlying amount to make the pool delta neutral
     */
    function getTokenAmountForHedging()
        external
        view
        override
        returns (NettingLib.CompleteParams memory completeParams)
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        (int256 futurePoolDelta, int256 sqeethPoolDelta) = getDeltas(
            spotPrice,
            pools[0].positionPerpetuals,
            pools[1].positionPerpetuals
        );

        int256[2] memory deltas;

        deltas[0] = futurePoolDelta;
        deltas[1] = sqeethPoolDelta;

        completeParams = NettingLib.getRequiredTokenAmountsForHedge(nettingInfo.amountsUnderlying, deltas, spotPrice);

        uint256 slippageTolerance = calculateSlippageToleranceForHedging(spotPrice);

        if (completeParams.isLong) {
            completeParams.amountUsdc = (completeParams.amountUsdc.mul(uint256(10000).add(slippageTolerance))).div(
                10000
            );
        } else {
            completeParams.amountUsdc = (completeParams.amountUsdc.mul(uint256(10000).sub(slippageTolerance))).div(
                10000
            );
        }
    }

    /**
     * @notice Update netting info to complete heging procedure
     */
    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams)
        external
        override
        onlyPerpetualMarket
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        lastHedgeSpotPrice = spotPrice;

        nettingInfo.complete(_completeParams);
    }

    /**
     * @notice Updates pool snapshot
     * Calculates ETH variance and base funding rate for future pool.
     */
    function updatePoolSnapshot() external override onlyPerpetualMarket {
        if (block.timestamp < poolSnapshot.lastSnapshotTime + 12 hours) {
            return;
        }

        updateVariance(block.timestamp);
        updateBaseFundingRate();
    }

    function executeFundingPayment() external override onlyPerpetualMarket {
        (int256 spotPrice, ) = getUnderlyingPrice();

        // Funding payment
        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            _executeFundingPayment(i, spotPrice);
        }
    }

    /**
     * @notice Calculates ETH variance under the Exponentially Weighted Moving Average Model.
     */
    function updateVariance(uint256 _timestamp) internal {
        (int256 spotPrice, ) = getUnderlyingPrice();

        // u_{t-1} = (S_t - S_{t-1}) / S_{t-1}
        int256 u = spotPrice.sub(poolSnapshot.ethPrice).mul(1e8).div(poolSnapshot.ethPrice);

        int256 uPower2 = u.mul(u).div(1e8);

        // normalization
        uPower2 = (uPower2.mul(FUNDING_PERIOD)).div((_timestamp - poolSnapshot.lastSnapshotTime).toInt256());

        // Updates snapshot
        // variance_{t} = λ * variance_{t-1} + (1 - λ) * u_{t-1}^2
        poolSnapshot.ethVariance = ((LAMBDA.mul(poolSnapshot.ethVariance).add((1e8 - LAMBDA).mul(uPower2))) / 1e8)
            .toInt128();
        poolSnapshot.ethPrice = spotPrice.toInt128();
        poolSnapshot.lastSnapshotTime = _timestamp.toUint128();

        emit VarianceUpdated(poolSnapshot.ethVariance, poolSnapshot.ethPrice, _timestamp);
    }

    function updateBaseFundingRate() internal {
        poolSnapshot.futureBaseFundingRate = 0;
    }

    /////////////////////////
    //  Admin Functions    //
    /////////////////////////

    function setSquaredPerpFundingMultiplier(int256 _squaredPerpFundingMultiplier) external onlyOwner {
        require(_squaredPerpFundingMultiplier >= 0 && _squaredPerpFundingMultiplier <= 2000 * 1e6);
        squaredPerpFundingMultiplier = _squaredPerpFundingMultiplier;
        emit SetSquaredPerpFundingMultiplier(_squaredPerpFundingMultiplier);
    }

    function setPerpFutureMaxFundingRate(int256 _perpFutureMaxFundingRate) external onlyOwner {
        require(_perpFutureMaxFundingRate >= 0 && _perpFutureMaxFundingRate <= 1 * 1e6);
        perpFutureMaxFundingRate = _perpFutureMaxFundingRate;
        emit SetPerpFutureMaxFundingRate(_perpFutureMaxFundingRate);
    }

    function setHedgeParams(
        uint256 _minSlippageToleranceOfHedge,
        uint256 _maxSlippageToleranceOfHedge,
        uint256 _hedgeRateOfReturnThreshold
    ) external onlyOwner {
        require(
            _minSlippageToleranceOfHedge >= 0 && _maxSlippageToleranceOfHedge >= 0 && _hedgeRateOfReturnThreshold >= 0
        );
        require(
            _minSlippageToleranceOfHedge < _maxSlippageToleranceOfHedge && _maxSlippageToleranceOfHedge <= 200,
            "PMC5"
        );

        minSlippageToleranceOfHedge = _minSlippageToleranceOfHedge;
        maxSlippageToleranceOfHedge = _maxSlippageToleranceOfHedge;
        hedgeRateOfReturnThreshold = _hedgeRateOfReturnThreshold;
        emit SetHedgeParams(_minSlippageToleranceOfHedge, _maxSlippageToleranceOfHedge, _hedgeRateOfReturnThreshold);
    }

    function setPoolMarginRiskParam(int256 _poolMarginRiskParam) external onlyOwner {
        require(_poolMarginRiskParam >= 0);
        poolMarginRiskParam = _poolMarginRiskParam;
        emit SetPoolMarginRiskParam(_poolMarginRiskParam);
    }

    function setTradeFeeRate(int256 _tradeFeeRate, int256 _protocolFeeRate) external onlyOwner {
        require(0 <= _protocolFeeRate && _tradeFeeRate <= 30 * 1e4 && _protocolFeeRate < _tradeFeeRate, "PMC5");
        tradeFeeRate = _tradeFeeRate;
        protocolFeeRate = _protocolFeeRate;
        emit SetTradeFeeRate(_tradeFeeRate, _protocolFeeRate);
    }

    /////////////////////////
    //  Getter Functions   //
    /////////////////////////

    /**
     * @notice Gets LP token price
     * LPTokenPrice = (L + ΣUnrealizedPnL_i - ΣAmountLockedLiquidity_i) / Supply
     * @return LPTokenPrice scaled by 1e16
     */
    function getLPTokenPrice(int256 _deltaLiquidityAmount) public view override returns (uint256) {
        (int256 spotPrice, ) = getUnderlyingPrice();

        int256 unrealizedPnL = (
            getUnrealizedPnL(0, spotPrice, _deltaLiquidityAmount).add(
                getUnrealizedPnL(1, spotPrice, _deltaLiquidityAmount)
            )
        );

        return
            (
                (
                    uint256(amountLiquidity.toInt256().add(unrealizedPnL)).sub(pools[0].amountLockedLiquidity).sub(
                        pools[1].amountLockedLiquidity
                    )
                ).mul(1e16)
            ).div(totalSupply());
    }

    /**
     * @notice Gets trade price
     * @param _productId product id
     * @param _tradeAmount amount of position to trade. positive for pool short and negative for pool long.
     */
    function getTradePrice(uint256 _productId, int128 _tradeAmount)
        external
        view
        override
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        )
    {
        (int256 spotPrice, ) = getUnderlyingPrice();

        return calculateTradePriceReadOnly(_productId, spotPrice, _tradeAmount, 0);
    }

    /**
     * @notice Gets utilization ratio
     * Utilization Ratio = (ΣAmountLockedLiquidity_i) / L
     * @return Utilization Ratio scaled by 1e8
     */
    function getUtilizationRatio() external view returns (uint256) {
        uint256 amountLocked;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            amountLocked = amountLocked.add(pools[i].amountLockedLiquidity);
        }

        return amountLocked.mul(1e8).div(amountLiquidity);
    }

    function getTradePriceInfo(int128[2] memory amountAssets) external view override returns (TradePriceInfo memory) {
        (int256 spotPrice, ) = getUnderlyingPrice();

        int256[2] memory tradePrices;
        int256[2] memory fundingRates;
        int256[2] memory amountFundingPaidPerPositionGlobals;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            int256 indexPrice;
            (tradePrices[i], indexPrice, fundingRates[i], , ) = calculateTradePriceReadOnly(
                i,
                spotPrice,
                -amountAssets[i],
                0
            );

            int256 fundingFeePerPosition = calculateFundingFeePerPosition(
                i,
                indexPrice,
                fundingRates[i],
                block.timestamp
            );

            amountFundingPaidPerPositionGlobals[i] = pools[i].amountFundingPaidPerPosition.add(fundingFeePerPosition);
        }

        return TradePriceInfo(uint128(spotPrice), tradePrices, fundingRates, amountFundingPaidPerPositionGlobals);
    }

    /////////////////////////
    //  Private Functions  //
    /////////////////////////

    /**
     * @notice Executes funding payment
     */
    function _executeFundingPayment(uint256 _productId, int256 _spotPrice) internal {
        if (pools[_productId].lastFundingPaymentTime == 0) {
            // Initialize timestamp
            pools[_productId].lastFundingPaymentTime = uint128(block.timestamp);
            return;
        }

        if (block.timestamp <= pools[_productId].lastFundingPaymentTime) {
            return;
        }

        (
            int256 currentFundingRate,
            int256 fundingFeePerPosition,
            int256 fundingReceived
        ) = calculateResultOfFundingPayment(_productId, _spotPrice, block.timestamp);

        pools[_productId].amountFundingPaidPerPosition = pools[_productId].amountFundingPaidPerPosition.add(
            fundingFeePerPosition
        );

        if (fundingReceived != 0) {
            amountLiquidity = Math.addDelta(amountLiquidity, fundingReceived);
        }

        // Update last timestamp of funding payment
        pools[_productId].lastFundingPaymentTime = uint128(block.timestamp);

        emit FundingPayment(
            _productId,
            currentFundingRate,
            pools[_productId].amountFundingPaidPerPosition,
            fundingFeePerPosition,
            fundingReceived
        );
    }

    /**
     * @notice Calculates funding rate, funding fee per position and funding fee that the pool will receive.
     * @param _productId product id
     * @param _spotPrice current spot price for index calculation
     * @param _currentTimestamp the timestamp to execute funding payment
     */
    function calculateResultOfFundingPayment(
        uint256 _productId,
        int256 _spotPrice,
        uint256 _currentTimestamp
    )
        internal
        view
        returns (
            int256 currentFundingRate,
            int256 fundingFeePerPosition,
            int256 fundingReceived
        )
    {
        int256 indexPrice = IndexPricer.calculateIndexPrice(_productId, _spotPrice);

        currentFundingRate = calculateFundingRate(
            _productId,
            getSignedMarginAmount(pools[_productId].positionPerpetuals, _productId),
            amountLiquidity.toInt256(),
            0,
            0
        );

        fundingFeePerPosition = calculateFundingFeePerPosition(
            _productId,
            indexPrice,
            currentFundingRate,
            _currentTimestamp
        );

        // Pool receives 'FundingPaidPerPosition * -(Pool Positions)' USDC as funding fee.
        fundingReceived = (fundingFeePerPosition.mul(-pools[_productId].positionPerpetuals)).div(1e16);
    }

    /**
     * @notice Calculates amount of funding fee which long position should pay per position.
     * FundingPaidPerPosition = IndexPrice * FundingRate * (T-t) / 1 days
     * @param _productId product id
     * @param _indexPrice index price of the perpetual
     * @param _currentFundingRate current funding rate used to calculate funding fee
     * @param _currentTimestamp the timestamp to execute funding payment
     */
    function calculateFundingFeePerPosition(
        uint256 _productId,
        int256 _indexPrice,
        int256 _currentFundingRate,
        uint256 _currentTimestamp
    ) internal view returns (int256 fundingFeePerPosition) {
        fundingFeePerPosition = _indexPrice.mul(_currentFundingRate).div(1e8);

        // Normalization by FUNDING_PERIOD
        fundingFeePerPosition = (
            fundingFeePerPosition.mul(int256(_currentTimestamp.sub(pools[_productId].lastFundingPaymentTime)))
        ).div(FUNDING_PERIOD);
    }

    /**
     * @notice Calculates signedDeltaMargin and changes of lockedLiquidity and totalLiquidity.
     * @return signedDeltaMargin is Δmargin: the change of the signed margin.
     * @return unlockLiquidityAmount is the change of the absolute amount of margin.
     * if return value is negative it represents unrequired.
     * @return deltaLiquidity Δliquidity: the change of the total liquidity amount.
     */
    function calculatePreTrade(
        uint256 _productId,
        int256 _deltaMargin,
        int256 _hedgePositionValue,
        MarginChange _marginChangeType
    )
        internal
        view
        returns (
            int256 signedDeltaMargin,
            int256 unlockLiquidityAmount,
            int256 deltaLiquidity
        )
    {
        if (_deltaMargin > 0) {
            // In case of lock additional margin
            require(getAvailableLiquidityAmount() >= uint256(_deltaMargin), "PMC1");
            unlockLiquidityAmount = _deltaMargin;
        } else if (_deltaMargin < 0) {
            // In case of unlock unrequired margin
            (deltaLiquidity, unlockLiquidityAmount) = calculateUnlockedLiquidity(
                pools[_productId].amountLockedLiquidity,
                _deltaMargin,
                _hedgePositionValue
            );
        }

        // Calculate signedDeltaMargin
        signedDeltaMargin = calculateSignedDeltaMargin(
            _marginChangeType,
            unlockLiquidityAmount,
            pools[_productId].amountLockedLiquidity
        );
    }

    /**
     * @notice Calculates trade price checked by spread manager
     * @return trade price and total protocol fee
     */
    function calculateSafeTradePrice(
        uint256 _productId,
        int256 _spotPrice,
        int256 _tradeAmount
    ) internal returns (uint256, uint256) {
        int256 deltaMargin;
        int256 signedDeltaMargin;
        int256 deltaLiquidity;
        {
            int256 hedgePositionValue;
            (deltaMargin, hedgePositionValue) = addMargin(_productId, _spotPrice);
            (signedDeltaMargin, deltaMargin, deltaLiquidity) = calculatePreTrade(
                _productId,
                deltaMargin,
                hedgePositionValue,
                getMarginChange(pools[_productId].positionPerpetuals, _tradeAmount)
            );
        }

        int256 signedMarginAmount = getSignedMarginAmount(
            // Calculate pool position before trade
            pools[_productId].positionPerpetuals.add(_tradeAmount),
            _productId
        );

        (int256 tradePrice, , , , int256 protocolFee) = calculateTradePrice(
            _productId,
            _spotPrice,
            _tradeAmount > 0,
            signedMarginAmount,
            amountLiquidity.toInt256(),
            signedDeltaMargin,
            deltaLiquidity
        );

        tradePrice = spreadInfos[_productId].checkPrice(_tradeAmount > 0, tradePrice);

        // Update pool liquidity and locked liquidity
        {
            if (deltaLiquidity != 0) {
                amountLiquidity = Math.addDelta(amountLiquidity, deltaLiquidity);
            }
            pools[_productId].amountLockedLiquidity = Math
                .addDelta(pools[_productId].amountLockedLiquidity, deltaMargin)
                .toUint128();
        }

        return (tradePrice.toUint256(), protocolFee.toUint256().mul(Math.abs(_tradeAmount)).div(1e8));
    }

    /**
     * @notice Calculates trade price as read-only trade.
     * @return tradePrice , indexPrice, fundingRate, tradeFee and protocolFee
     */
    function calculateTradePriceReadOnly(
        uint256 _productId,
        int256 _spotPrice,
        int256 _tradeAmount,
        int256 _deltaLiquidity
    )
        internal
        view
        returns (
            int256 tradePrice,
            int256 indexPrice,
            int256 fundingRate,
            int256 tradeFee,
            int256 protocolFee
        )
    {
        int256 signedDeltaMargin;

        if (_tradeAmount != 0) {
            (int256 deltaMargin, int256 hedgePositionValue, MarginChange marginChangeType) = getRequiredMargin(
                _productId,
                _spotPrice,
                _tradeAmount.toInt128()
            );

            int256 deltaLiquidityByTrade;

            (signedDeltaMargin, , deltaLiquidityByTrade) = calculatePreTrade(
                _productId,
                deltaMargin,
                hedgePositionValue,
                marginChangeType
            );

            _deltaLiquidity = _deltaLiquidity.add(deltaLiquidityByTrade);
        }
        {
            int256 signedMarginAmount = getSignedMarginAmount(pools[_productId].positionPerpetuals, _productId);

            (tradePrice, indexPrice, fundingRate, tradeFee, protocolFee) = calculateTradePrice(
                _productId,
                _spotPrice,
                _tradeAmount > 0,
                signedMarginAmount,
                amountLiquidity.toInt256(),
                signedDeltaMargin,
                _deltaLiquidity
            );
        }

        tradePrice = spreadInfos[_productId].getUpdatedPrice(_tradeAmount > 0, tradePrice, block.timestamp);

        return (tradePrice, indexPrice, fundingRate, tradeFee, protocolFee);
    }

    /**
     * @notice Adds margin to Netting contract
     */
    function addMargin(uint256 _productId, int256 _spot)
        internal
        returns (int256 deltaMargin, int256 hedgePositionValue)
    {
        (int256 delta0, int256 delta1) = getDeltas(_spot, pools[0].positionPerpetuals, pools[1].positionPerpetuals);
        int256 gamma = (IndexPricer.calculateGamma(1).mul(pools[1].positionPerpetuals)) / 1e8;

        (deltaMargin, hedgePositionValue) = nettingInfo.addMargin(
            _productId,
            NettingLib.AddMarginParams(delta0, delta1, gamma, _spot, poolMarginRiskParam)
        );
    }

    /**
     * @notice Calculated required or unrequired margin for read-only price calculation.
     * @return deltaMargin is the change of the absolute amount of margin.
     * @return hedgePositionValue is current value of locked margin.
     * if return value is negative it represents unrequired.
     */
    function getRequiredMargin(
        uint256 _productId,
        int256 _spot,
        int128 _tradeAmount
    )
        internal
        view
        returns (
            int256 deltaMargin,
            int256 hedgePositionValue,
            MarginChange marginChangeType
        )
    {
        int256 delta0;
        int256 delta1;
        int256 gamma;

        {
            int128 tradeAmount0 = pools[0].positionPerpetuals;
            int128 tradeAmount1 = pools[1].positionPerpetuals;

            if (_productId == 0) {
                tradeAmount0 -= _tradeAmount;
                marginChangeType = getMarginChange(tradeAmount0, _tradeAmount);
            }

            if (_productId == 1) {
                tradeAmount1 -= _tradeAmount;
                marginChangeType = getMarginChange(tradeAmount1, _tradeAmount);
            }

            (delta0, delta1) = getDeltas(_spot, tradeAmount0, tradeAmount1);
            gamma = (IndexPricer.calculateGamma(1).mul(tradeAmount1)) / 1e8;
        }

        int256 totalRequiredMargin = NettingLib.getRequiredMargin(
            _productId,
            NettingLib.AddMarginParams(delta0, delta1, gamma, _spot, poolMarginRiskParam)
        );

        hedgePositionValue = nettingInfo.getHedgePositionValue(_spot, _productId);

        deltaMargin = totalRequiredMargin - hedgePositionValue;
    }

    /**
     * @notice Gets signed amount of margin used for trade price calculation.
     * @param _position current pool position
     * @param _productId product id
     * @return signedMargin is calculated by following rule.
     * If poolPosition is 0 then SignedMargin is 0.
     * If poolPosition is long then SignedMargin is negative.
     * If poolPosition is short then SignedMargin is positive.
     */
    function getSignedMarginAmount(int256 _position, uint256 _productId) internal view returns (int256) {
        if (_position == 0) {
            return 0;
        } else if (_position > 0) {
            return -pools[_productId].amountLockedLiquidity.toInt256();
        } else {
            return pools[_productId].amountLockedLiquidity.toInt256();
        }
    }

    /**
     * @notice Get signed delta margin. Signed delta margin is the change of the signed margin.
     * It is used for trade price calculation.
     * For example, if pool position becomes to short 10 from long 10 and deltaMargin hasn't changed.
     * Then deltaMargin should be 0 but signedDeltaMargin should be +20.
     * @param _deltaMargin amount of change in margin resulting from the trade
     * @param _currentMarginAmount amount of locked margin before trade
     * @return signedDeltaMargin is calculated by follows.
     * Crossing case:
     *   If position moves long to short then
     *     Δm = currentMarginAmount * 2 + deltaMargin
     *   If position moves short to long then
     *     Δm = -(currentMarginAmount * 2 + deltaMargin)
     * Non Crossing Case:
     *   If position moves long to long then
     *     Δm = -deltaMargin
     *   If position moves short to short then
     *     Δm = deltaMargin
     */
    function calculateSignedDeltaMargin(
        MarginChange _marginChangeType,
        int256 _deltaMargin,
        int256 _currentMarginAmount
    ) internal pure returns (int256) {
        if (_marginChangeType == MarginChange.LongToShort) {
            return _currentMarginAmount.mul(2).add(_deltaMargin);
        } else if (_marginChangeType == MarginChange.ShortToLong) {
            return -(_currentMarginAmount.mul(2).add(_deltaMargin));
        } else if (_marginChangeType == MarginChange.LongToLong) {
            return -_deltaMargin;
        } else {
            // In case of ShortToShort
            return _deltaMargin;
        }
    }

    /**
     * @notice Gets the type of margin change.
     * @param _newPosition positions resulting from trades
     * @param _positionTrade delta positions to trade
     * @return marginChange the type of margin change
     */
    function getMarginChange(int256 _newPosition, int256 _positionTrade) internal pure returns (MarginChange) {
        int256 position = _newPosition.add(_positionTrade);

        if (position > 0 && _newPosition < 0) {
            return MarginChange.LongToShort;
        } else if (position < 0 && _newPosition > 0) {
            return MarginChange.ShortToLong;
        } else if (position >= 0 && _newPosition >= 0) {
            return MarginChange.LongToLong;
        } else {
            return MarginChange.ShortToShort;
        }
    }

    /**
     * @notice Calculates delta liquidity amount and unlock liquidity amount
     * unlockLiquidityAmount = Δm * amountLockedLiquidity / hedgePositionValue
     * deltaLiquidity = Δm - UnlockAmount
     */
    function calculateUnlockedLiquidity(
        uint256 _amountLockedLiquidity,
        int256 _deltaMargin,
        int256 _hedgePositionValue
    ) internal pure returns (int256 deltaLiquidity, int256 unlockLiquidityAmount) {
        unlockLiquidityAmount = _deltaMargin.mul(_amountLockedLiquidity.toInt256()).div(_hedgePositionValue);

        return ((-_deltaMargin + unlockLiquidityAmount), unlockLiquidityAmount);
    }

    /**
     * @notice Calculates perpetual's trade price
     * TradePrice = IndexPrice * (1 + FundingRate) + TradeFee
     * @return TradePrice scaled by 1e8
     */
    function calculateTradePrice(
        uint256 _productId,
        int256 _spotPrice,
        bool _isLong,
        int256 _margin,
        int256 _totalLiquidityAmount,
        int256 _deltaMargin,
        int256 _deltaLiquidity
    )
        internal
        view
        returns (
            int256,
            int256 indexPrice,
            int256,
            int256 tradeFee,
            int256 protocolFee
        )
    {
        int256 fundingRate = calculateFundingRate(
            _productId,
            _margin,
            _totalLiquidityAmount,
            _deltaMargin,
            _deltaLiquidity
        );

        indexPrice = IndexPricer.calculateIndexPrice(_productId, _spotPrice);

        int256 tradePrice = (indexPrice.mul(int256(1e16).add(fundingRate))).div(1e16);

        tradeFee = getTradeFee(_productId, _isLong, indexPrice);

        tradePrice = tradePrice.add(tradeFee);

        protocolFee = getProtocolFee(_productId, indexPrice);

        return (tradePrice, indexPrice, fundingRate, Math.abs(tradeFee).toInt256(), protocolFee);
    }

    /**
     * @notice Gets trade fee
     * TradeFee = IndxPrice * tradeFeeRate
     */
    function getTradeFee(
        uint256 _productId,
        bool _isLong,
        int256 _indexPrice
    ) internal view returns (int256) {
        require(_indexPrice > 0);

        if (_isLong) {
            return _indexPrice.mul(tradeFeeRate).mul(int256(_productId + 1)) / 1e8;
        } else {
            return -_indexPrice.mul(tradeFeeRate).mul(int256(_productId + 1)) / 1e8;
        }
    }

    /**
     * @notice Gets protocol fee
     * ProtocolFee = IndxPrice * protocolFeeRate
     */
    function getProtocolFee(uint256 _productId, int256 _indexPrice) internal view returns (int256) {
        require(_indexPrice > 0);

        return _indexPrice.mul(protocolFeeRate).mul(int256(_productId + 1)) / 1e8;
    }

    function getDeltas(
        int256 _spotPrice,
        int256 _tradeAmount0,
        int256 _tradeAmount1
    ) internal pure returns (int256, int256) {
        int256 futurePoolDelta = (IndexPricer.calculateDelta(0, _spotPrice).mul(_tradeAmount0)) / 1e8;
        int256 sqeethPoolDelta = (IndexPricer.calculateDelta(1, _spotPrice).mul(_tradeAmount1)) / 1e8;
        return (futurePoolDelta, sqeethPoolDelta);
    }

    /**
     * @notice Calculates Unrealized PnL
     * UnrealizedPnL = (TradePrice - EntryPrice) * Position_i + HedgePositionValue
     * TradePrice is calculated as fill price of closing all pool positions.
     * @return UnrealizedPnL scaled by 1e8
     */
    function getUnrealizedPnL(
        uint256 _productId,
        int256 _spotPrice,
        int256 _deltaLiquidityAmount
    ) internal view returns (int256) {
        int256 positionsValue;

        if (pools[_productId].positionPerpetuals != 0) {
            (int256 tradePrice, , , , ) = calculateTradePriceReadOnly(
                _productId,
                _spotPrice,
                pools[_productId].positionPerpetuals,
                _deltaLiquidityAmount
            );
            positionsValue =
                pools[_productId].positionPerpetuals.mul(tradePrice.sub(pools[_productId].entryPrice.toInt256())) /
                1e8;
        }

        {
            int256 hedgePositionValue = nettingInfo.getHedgePositionValue(_spotPrice, _productId);

            positionsValue = positionsValue.add(hedgePositionValue);
        }

        return positionsValue;
    }

    /**
     * @notice Calculates perpetual's funding rate
     * Squared:
     *   FundingRate = variance * (1 + squaredPerpFundingMultiplier * m / L)
     * Future:
     *   FundingRate = BASE_FUNDING_RATE + perpFutureMaxFundingRate * (m / L)
     * @param _productId product id
     * @param _margin amount of locked margin before trade
     * @param _totalLiquidityAmount amount of total liquidity before trade
     * @param _deltaMargin amount of change in margin resulting from the trade
     * @param _deltaLiquidity difference of liquidity
     * @return FundingRate scaled by 1e16 (1e16 = 100%)
     */
    function calculateFundingRate(
        uint256 _productId,
        int256 _margin,
        int256 _totalLiquidityAmount,
        int256 _deltaMargin,
        int256 _deltaLiquidity
    ) internal view returns (int256) {
        if (_productId == 0) {
            int256 fundingRate = perpFutureMaxFundingRate
                .mul(
                    PoolMath.calculateMarginDivLiquidity(_margin, _deltaMargin, _totalLiquidityAmount, _deltaLiquidity)
                )
                .div(1e8);
            return poolSnapshot.futureBaseFundingRate.add(fundingRate);
        } else if (_productId == 1) {
            if (_totalLiquidityAmount == 0) {
                return poolSnapshot.ethVariance.mul(1e8);
            } else {
                int256 addition = squaredPerpFundingMultiplier
                    .mul(
                        PoolMath.calculateMarginDivLiquidity(
                            _margin,
                            _deltaMargin,
                            _totalLiquidityAmount,
                            _deltaLiquidity
                        )
                    )
                    .div(1e8);
                return poolSnapshot.ethVariance.mul(int256(1e16).add(addition)).div(1e8);
            }
        }
        return 0;
    }

    /**
     * @notice Calculates the slippage tolerance of USDC amount for a hedge
     */
    function calculateSlippageToleranceForHedging(int256 _spotPrice) internal view returns (uint256 slippageTolerance) {
        uint256 rateOfReturn = Math.abs(_spotPrice.sub(lastHedgeSpotPrice).mul(1e8).div(lastHedgeSpotPrice));

        slippageTolerance = minSlippageToleranceOfHedge.add(
            (maxSlippageToleranceOfHedge - minSlippageToleranceOfHedge).mul(rateOfReturn).div(
                hedgeRateOfReturnThreshold
            )
        );

        if (slippageTolerance < minSlippageToleranceOfHedge) slippageTolerance = minSlippageToleranceOfHedge;
        if (slippageTolerance > maxSlippageToleranceOfHedge) slippageTolerance = maxSlippageToleranceOfHedge;
    }

    /**
     * @notice Gets available amount of liquidity
     * available amount = amountLiquidity - (ΣamountLocked_i)
     */
    function getAvailableLiquidityAmount() internal view returns (uint256) {
        uint256 amountLocked;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            amountLocked = amountLocked.add(pools[i].amountLockedLiquidity);
        }

        return amountLiquidity.sub(amountLocked);
    }

    /**
     * @notice get underlying price scaled by 1e8
     */
    function getUnderlyingPrice() internal view returns (int256, uint256) {
        (, int256 answer, , uint256 roundTimestamp, ) = priceFeed.latestRoundData();

        require(answer > 0, "PMC3");

        return (answer, roundTimestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

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

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

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
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

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

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/NettingLib.sol";

interface IPerpetualMarketCore {
    struct TradePriceInfo {
        uint128 spotPrice;
        int256[2] tradePrices;
        int256[2] fundingRates;
        int256[2] amountsFundingPaidPerPosition;
    }

    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external returns (uint256 mintAmount);

    function deposit(address _depositor, uint256 _depositAmount) external returns (uint256 mintAmount);

    function withdraw(address _withdrawer, uint256 _withdrawnAmount) external returns (uint256 burnAmount);

    function addLiquidity(uint256 _amount) external;

    function updatePoolPosition(uint256 _productId, int128 _tradeAmount)
        external
        returns (
            uint256 tradePrice,
            int256,
            uint256 protocolFee
        );

    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams) external;

    function updatePoolSnapshot() external;

    function executeFundingPayment() external;

    function getTradePriceInfo(int128[2] memory amountAssets) external view returns (TradePriceInfo memory);

    function getTradePrice(uint256 _productId, int128 _tradeAmount)
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        );

    function rebalance() external;

    function getTokenAmountForHedging() external view returns (NettingLib.CompleteParams memory completeParams);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title NettingLib
 * Error codes
 * N0: Unknown product id
 * N1: Total delta must be greater than 0
 * N2: No enough USDC
 */
library NettingLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    struct AddMarginParams {
        int256 delta0;
        int256 delta1;
        int256 gamma1;
        int256 spotPrice;
        int256 poolMarginRiskParam;
    }

    struct CompleteParams {
        uint256 amountUsdc;
        uint256 amountUnderlying;
        int256[2] amountsRequiredUnderlying;
        bool isLong;
    }

    struct Info {
        uint128 amountAaveCollateral;
        uint128[2] amountsUsdc;
        int128[2] amountsUnderlying;
    }

    /**
     * @notice Adds required margin for delta hedging
     */
    function addMargin(
        Info storage _info,
        uint256 _productId,
        AddMarginParams memory _params
    ) internal returns (int256 requiredMargin, int256 hedgePositionValue) {
        int256 totalRequiredMargin = getRequiredMargin(_productId, _params);

        hedgePositionValue = getHedgePositionValue(_info, _params.spotPrice, _productId);

        requiredMargin = totalRequiredMargin.sub(hedgePositionValue);

        if (_info.amountsUsdc[_productId].toInt256().add(requiredMargin) < 0) {
            requiredMargin = -_info.amountsUsdc[_productId].toInt256();
        }

        _info.amountsUsdc[_productId] = Math.addDelta(_info.amountsUsdc[_productId], requiredMargin).toUint128();
    }

    function getRequiredTokenAmountsForHedge(
        int128[2] memory _amountsUnderlying,
        int256[2] memory _deltas,
        int256 _spotPrice
    ) internal pure returns (CompleteParams memory completeParams) {
        completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] - _deltas[0];
        completeParams.amountsRequiredUnderlying[1] = -_amountsUnderlying[1] - _deltas[1];

        int256 totalUnderlyingPosition = getTotalUnderlyingPosition(_amountsUnderlying);

        // 1. Calculate required amount of underlying token
        int256 requiredUnderlyingAmount;
        {
            // required amount is -(net delta)
            requiredUnderlyingAmount = -_deltas[0].add(_deltas[1]).add(totalUnderlyingPosition);

            if (_deltas[0].add(_deltas[1]) > 0) {
                // if pool delta is positive
                requiredUnderlyingAmount = -totalUnderlyingPosition;

                completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] + _deltas[1];
            }

            completeParams.isLong = requiredUnderlyingAmount > 0;
        }

        // 2. Calculate USDC and ETH amounts.
        completeParams.amountUnderlying = Math.abs(requiredUnderlyingAmount);
        completeParams.amountUsdc = (Math.abs(requiredUnderlyingAmount).mul(uint256(_spotPrice))) / 1e8;

        return completeParams;
    }

    /**
     * @notice Completes delta hedging procedure
     * Calculate holding amount of Underlying and USDC after a hedge.
     */
    function complete(Info storage _info, CompleteParams memory _params) internal {
        uint256 totalUnderlying = Math.abs(_params.amountsRequiredUnderlying[0]).add(
            Math.abs(_params.amountsRequiredUnderlying[1])
        );

        require(totalUnderlying > 0, "N1");

        for (uint256 i = 0; i < 2; i++) {
            _info.amountsUnderlying[i] = _info
                .amountsUnderlying[i]
                .add(_params.amountsRequiredUnderlying[i])
                .toInt128();

            {
                uint256 deltaUsdcAmount = (_params.amountUsdc.mul(Math.abs(_params.amountsRequiredUnderlying[i]))).div(
                    totalUnderlying
                );

                if (_params.isLong) {
                    require(_info.amountsUsdc[i] >= deltaUsdcAmount, "N2");
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].sub(deltaUsdcAmount).toUint128();
                } else {
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].add(deltaUsdcAmount).toUint128();
                }
            }
        }
    }

    /**
     * @notice Gets required margin
     * @param _productId Id of product to get required margin
     * @param _params parameters to calculate required margin
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMargin(uint256 _productId, AddMarginParams memory _params) internal pure returns (int256) {
        int256 weightedDelta = calculateWeightedDelta(_productId, _params.delta0, _params.delta1);

        if (_productId == 0) {
            return getRequiredMarginOfFuture(_params, weightedDelta);
        } else if (_productId == 1) {
            return getRequiredMarginOfSqueeth(_params, weightedDelta);
        } else {
            revert("N0");
        }
    }

    /**
     * @notice Gets required margin for future
     * RequiredMargin_{future} = (1+α)*S*|WeightedDelta|
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfFuture(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 requiredMargin = (_params.spotPrice.mul(Math.abs(_weightedDelta).toInt256())) / 1e8;
        return ((1e4 + _params.poolMarginRiskParam).mul(requiredMargin)) / 1e4;
    }

    /**
     * @notice Gets required margin for squeeth
     * RequiredMargin_{squeeth}
     * = max((1-α) * S * |WeightDelta_{sqeeth}-α * S * gamma|, (1+α) * S * |WeightDelta_{sqeeth}+α * S * gamma|)
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfSqueeth(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 deltaFromGamma = (_params.poolMarginRiskParam.mul(_params.spotPrice).mul(_params.gamma1)) / 1e12;

        return
            Math.max(
                (
                    (1e4 - _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.sub(deltaFromGamma)).toInt256()
                    )
                ) / 1e12,
                (
                    (1e4 + _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.add(deltaFromGamma)).toInt256()
                    )
                ) / 1e12
            );
    }

    /**
     * @notice Gets notional value of hedge positions
     * HedgePositionValue_i = AmountsUsdc_i+AmountsUnderlying_i*S
     * @return HedgePositionValue scaled by 1e8
     */
    function getHedgePositionValue(
        Info memory _info,
        int256 _spot,
        uint256 _productId
    ) internal pure returns (int256) {
        int256 hedgeNotional = _spot.mul(_info.amountsUnderlying[_productId]) / 1e8;

        return _info.amountsUsdc[_productId].toInt256().add(hedgeNotional);
    }

    /**
     * @notice Gets total underlying position
     * TotalUnderlyingPosition = ΣAmountsUnderlying_i
     */
    function getTotalUnderlyingPosition(int128[2] memory _amountsUnderlying)
        internal
        pure
        returns (int256 underlyingPosition)
    {
        for (uint256 i = 0; i < 2; i++) {
            underlyingPosition = underlyingPosition.add(_amountsUnderlying[i]);
        }

        return underlyingPosition;
    }

    /**
     * @notice Calculates weighted delta
     * WeightedDelta = delta_i * (Σdelta_i) / (Σ|delta_i|)
     * @return weighted delta scaled by 1e8
     */
    function calculateWeightedDelta(
        uint256 _productId,
        int256 _delta0,
        int256 _delta1
    ) internal pure returns (int256) {
        int256 netDelta = _delta0.add(_delta1);
        int256 totalDelta = (Math.abs(_delta0).add(Math.abs(_delta1))).toInt256();

        require(totalDelta >= 0, "N1");

        if (totalDelta == 0) {
            return 0;
        }

        if (_productId == 0) {
            return (Math.abs(_delta0).toInt256().mul(netDelta)).div(totalDelta);
        } else if (_productId == 1) {
            return (Math.abs(_delta1).toInt256().mul(netDelta)).div(totalDelta);
        } else {
            revert("N0");
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title IndexPricer
 * @notice Library contract that has functions to calculate Index price and Greeks of perpetual
 */
library IndexPricer {
    using SignedSafeMath for int256;

    /// @dev Scaling factor for squared index price.
    int256 public constant SCALING_FACTOR = 1e4;

    /**
     * @notice Calculates index price of perpetuals
     * Future: ETH
     * Squeeth: ETH^2 / 10000
     * @return calculated index price scaled by 1e8
     */
    function calculateIndexPrice(uint256 _productId, int256 _spot) internal pure returns (int256) {
        if (_productId == 0) {
            return _spot;
        } else if (_productId == 1) {
            return (_spot.mul(_spot)) / (1e8 * SCALING_FACTOR);
        } else {
            revert("NP");
        }
    }

    /**
     * @notice Calculates delta of perpetuals
     * Future: 1
     * Squeeth: 2 * ETH / 10000
     * @return calculated delta scaled by 1e8
     */
    function calculateDelta(uint256 _productId, int256 _spot) internal pure returns (int256) {
        if (_productId == 0) {
            return 1e8;
        } else if (_productId == 1) {
            return _spot.mul(2) / SCALING_FACTOR;
        } else {
            revert("NP");
        }
    }

    /**
     * @notice Calculates gamma of perpetuals
     * Future: 0
     * Squeeth: 2 / 10000
     * @return calculated gamma scaled by 1e8
     */
    function calculateGamma(uint256 _productId) internal pure returns (int256) {
        if (_productId == 0) {
            return 0;
        } else if (_productId == 1) {
            return 2 * SCALING_FACTOR;
        } else {
            revert("NP");
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title SpreadLib
 * @notice Spread Library has functions to controls spread for short-term volatility risk management
 */
library SpreadLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeMath for uint256;
    using SignedSafeMath for int128;

    /// @dev 6 minutes
    uint256 private constant SAFETY_PERIOD = 6 minutes;
    /// @dev 8 bps
    uint256 private constant SPREAD_DECREASE_PER_PERIOD = 8;
    /// @dev 80 bps
    int256 private constant MAX_SPREAD_DECREASE = 80;

    struct Info {
        uint128 timeLastLongTransaction;
        int128 minLongTradePrice;
        uint128 timeLastShortTransaction;
        int128 maxShortTradePrice;
    }

    function init(Info storage _info) internal {
        _info.minLongTradePrice = type(int128).max;
        _info.maxShortTradePrice = 0;
    }

    /**
     * @notice Checks and updates price to guarantee that
     * max(bit) ≤ min(ask) from some point t to t-Safety Period.
     * @param _isLong trade is long or short
     * @param _price trade price
     * @return adjustedPrice adjusted price
     */
    function checkPrice(
        Info storage _info,
        bool _isLong,
        int256 _price
    ) internal returns (int256 adjustedPrice) {
        Info memory cache = Info(
            _info.timeLastLongTransaction,
            _info.minLongTradePrice,
            _info.timeLastShortTransaction,
            _info.maxShortTradePrice
        );

        adjustedPrice = getUpdatedPrice(cache, _isLong, _price, block.timestamp);

        _info.timeLastLongTransaction = cache.timeLastLongTransaction;
        _info.minLongTradePrice = cache.minLongTradePrice;
        _info.timeLastShortTransaction = cache.timeLastShortTransaction;
        _info.maxShortTradePrice = cache.maxShortTradePrice;
    }

    function getUpdatedPrice(
        Info memory _info,
        bool _isLong,
        int256 _price,
        uint256 _timestamp
    ) internal pure returns (int256 adjustedPrice) {
        adjustedPrice = _price;
        if (_isLong) {
            // if long
            if (_info.timeLastShortTransaction >= _timestamp - SAFETY_PERIOD) {
                // Within safety period
                if (adjustedPrice < _info.maxShortTradePrice) {
                    uint256 tt = (_timestamp - _info.timeLastShortTransaction) / 1 minutes;
                    int256 spreadClosing = int256(SPREAD_DECREASE_PER_PERIOD.mul(tt));
                    if (spreadClosing > MAX_SPREAD_DECREASE) {
                        spreadClosing = MAX_SPREAD_DECREASE;
                    }
                    if (adjustedPrice <= (_info.maxShortTradePrice.mul(1e4 - spreadClosing)) / 1e4) {
                        _info.maxShortTradePrice = ((_info.maxShortTradePrice.mul(1e4 - spreadClosing)) / 1e4)
                            .toInt128();
                    }
                    adjustedPrice = _info.maxShortTradePrice;
                }
            }

            // Update min ask
            if (_info.minLongTradePrice > adjustedPrice || _info.timeLastLongTransaction + SAFETY_PERIOD < _timestamp) {
                _info.minLongTradePrice = adjustedPrice.toInt128();
            }
            _info.timeLastLongTransaction = uint128(_timestamp);
        } else {
            // if short
            if (_info.timeLastLongTransaction >= _timestamp - SAFETY_PERIOD) {
                // Within safety period
                if (adjustedPrice > _info.minLongTradePrice) {
                    uint256 tt = (_timestamp - _info.timeLastLongTransaction) / 1 minutes;
                    int256 spreadClosing = int256(SPREAD_DECREASE_PER_PERIOD.mul(tt));
                    if (spreadClosing > MAX_SPREAD_DECREASE) {
                        spreadClosing = MAX_SPREAD_DECREASE;
                    }
                    if (adjustedPrice <= (_info.minLongTradePrice.mul(1e4 + spreadClosing)) / 1e4) {
                        _info.minLongTradePrice = ((_info.minLongTradePrice.mul(1e4 + spreadClosing)) / 1e4).toInt128();
                    }
                    adjustedPrice = _info.minLongTradePrice;
                }
            }

            // Update max bit
            if (
                _info.maxShortTradePrice < adjustedPrice || _info.timeLastShortTransaction + SAFETY_PERIOD < _timestamp
            ) {
                _info.maxShortTradePrice = adjustedPrice.toInt128();
            }
            _info.timeLastShortTransaction = uint128(_timestamp);
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title EntryPriceMath
 * @notice Library contract which has functions to calculate new entry price and profit
 * from previous entry price and trade price for implementing margin wallet.
 */
library EntryPriceMath {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @notice Calculates new entry price and return profit if position is closed
     *
     * Calculation Patterns
     *  |Position|PositionTrade|NewPosition|Pattern|
     *  |       +|            +|          +|      A|
     *  |       +|            -|          +|      B|
     *  |       +|            -|          -|      C|
     *  |       -|            -|          -|      A|
     *  |       -|            +|          -|      B|
     *  |       -|            +|          +|      C|
     *
     * Calculations
     *  Pattern A (open positions)
     *   NewEntryPrice = (EntryPrice * |Position| + TradePrce * |PositionTrade|) / (Position + PositionTrade)
     *
     *  Pattern B (close positions)
     *   NewEntryPrice = EntryPrice
     *   ProfitValue = -PositionTrade * (TradePrice - EntryPrice)
     *
     *  Pattern C (close all positions & open new)
     *   NewEntryPrice = TradePrice
     *   ProfitValue = Position * (TradePrice - EntryPrice)
     *
     * @param _entryPrice previous entry price
     * @param _position current position
     * @param _tradePrice trade price
     * @param _positionTrade position to trade
     * @return newEntryPrice new entry price
     * @return profitValue notional profit value when positions are closed
     */
    function updateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) internal pure returns (int256 newEntryPrice, int256 profitValue) {
        int256 newPosition = _position.add(_positionTrade);
        if (_position == 0 || (_position > 0 && _positionTrade > 0) || (_position < 0 && _positionTrade < 0)) {
            newEntryPrice = (
                _entryPrice.mul(int256(Math.abs(_position))).add(_tradePrice.mul(int256(Math.abs(_positionTrade))))
            ).div(int256(Math.abs(_position.add(_positionTrade))));
        } else if (
            (_position > 0 && _positionTrade < 0 && newPosition > 0) ||
            (_position < 0 && _positionTrade > 0 && newPosition < 0)
        ) {
            newEntryPrice = _entryPrice;
            profitValue = (-_positionTrade).mul(_tradePrice.sub(_entryPrice)) / 1e8;
        } else {
            if (newPosition != 0) {
                newEntryPrice = _tradePrice;
            }

            profitValue = _position.mul(_tradePrice.sub(_entryPrice)) / 1e8;
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "./Math.sol";

/**
 * @notice AMM related math library
 */
library PoolMath {
    using SignedSafeMath for int256;
    using SafeCast for int256;

    /**
     * @notice Calculate multiple integral of (m/L)^3.
     * The formula is `(_m^3 + (3/2)*_m^2 * _deltaMargin + _m * _deltaMargin^2 + _deltaMargin^3 / 4) * (_l + _deltaL / 2) / (_l^2 * (_l + _deltaL)^2)`.
     * @param _m required margin
     * @param _deltaMargin difference of required margin
     * @param _l total amount of liquidity
     * @param _deltaL difference of liquidity
     * @return returns result of above formula
     */
    function calculateMarginDivLiquidity(
        int256 _m,
        int256 _deltaMargin,
        int256 _l,
        int256 _deltaL
    ) internal pure returns (int256) {
        require(_l > 0, "l must be positive");

        int256 result = 0;

        result = (_m.mul(_m).mul(_m));

        result = result.add(_m.mul(_m).mul(_deltaMargin).mul(3).div(2));

        result = result.add(_m.mul(_deltaMargin).mul(_deltaMargin));

        result = result.add(_deltaMargin.mul(_deltaMargin).mul(_deltaMargin).div(4));

        result = result.mul(1e8).div(_l).div(_l);

        return result.mul(_l.add(_deltaL.div(2))).mul(1e8).div(_l.add(_deltaL)).div(_l.add(_deltaL));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Error codes
 * M0: y is too small
 * M1: y is too large
 * M2: possible overflow
 * M3: input should be positive number
 * M4: cannot handle exponents greater than 100
 */
library Math {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /// @dev Min exp
    int256 private constant MIN_EXP = -63 * 1e8;
    /// @dev Max exp
    uint256 private constant MAX_EXP = 100 * 1e8;
    /// @dev ln(2) scaled by 1e8
    uint256 private constant LN_2_E8 = 69314718;

    /**
     * @notice Return the addition of unsigned integer and sigined integer.
     * when y is negative reverting on negative result and when y is positive reverting on overflow.
     */
    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "M0");
        } else {
            require((z = x + uint256(y)) >= x, "M1");
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? b : a;
    }

    /**
     * @notice Returns scaled number.
     * Reverts if the scaler is greater than 50.
     */
    function scale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from > _to) {
            require(_from - _to < 70, "M2");
            // (_from - _to) is safe because _from > _to.
            // 10**(_from - _to) is safe because it's less than 10**70.
            return _a.div(10**(_from - _to));
        } else if (_from < _to) {
            require(_to - _from < 70, "M2");
            // (_to - _from) is safe because _to > _from.
            // 10**(_to - _from) is safe because it's less than 10**70.
            return _a.mul(10**(_to - _from));
        } else {
            return _a;
        }
    }
}