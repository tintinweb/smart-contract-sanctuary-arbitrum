// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/IPerpsV2MarketViews.sol";
import "./interfaces/IPerpsV2MarketBaseTypes.sol";
import "./interfaces/IPerpsV2MarketSettings.sol";
import "./interfaces/IAddressResolver.sol";

// A utility contract to allow the front end to query market data in a single call.
contract PerpsV2MarketData {
    /* ========== TYPES ========== */

    struct FuturesGlobals {
        uint256 minInitialMargin;
        uint256 liquidationFeeRatio;
        uint256 minKeeperFee;
        uint256 maxKeeperFee;
    }

    struct MarketSummary {
        address market;
        bytes32 asset;
        bytes32 key;
        uint256 maxLeverage;
        uint256 price;
        uint256 marketSize;
        int256 marketSkew;
        uint256 marketDebt;
        int256 currentFundingRate;
        int256 currentFundingVelocity;
        FeeRates feeRates;
    }

    struct MarketLimits {
        uint256 maxLeverage;
        uint256 maxMarketValue;
    }

    struct Sides {
        uint256 long;
        uint256 short;
    }

    struct MarketSizeDetails {
        uint256 marketSize;
        PerpsV2MarketData.Sides sides;
        uint256 marketDebt;
        int256 marketSkew;
    }

    struct PriceDetails {
        uint256 price;
        bool invalid;
    }

    struct FundingParameters {
        uint256 maxFundingVelocity;
        uint256 skewScale;
    }

    struct FeeRates {
        uint256 takerFee;
        uint256 makerFee;
        uint256 takerFeeDelayedOrder;
        uint256 makerFeeDelayedOrder;
        uint256 takerFeeOffchainDelayedOrder;
        uint256 makerFeeOffchainDelayedOrder;
    }

    struct MarketData {
        address market;
        bytes32 baseAsset;
        bytes32 marketKey;
        PerpsV2MarketData.FeeRates feeRates;
        PerpsV2MarketData.MarketLimits limits;
        PerpsV2MarketData.FundingParameters fundingParameters;
        PerpsV2MarketData.MarketSizeDetails marketSizeDetails;
        PerpsV2MarketData.PriceDetails priceDetails;
    }

    struct PositionData {
        IPerpsV2MarketBaseTypes.Position position;
        int256 notionalValue;
        int256 profitLoss;
        int256 accruedFunding;
        uint256 remainingMargin;
        uint256 accessibleMargin;
        uint256 liquidationPrice;
        bool canLiquidatePosition;
    }

    /* ========== STORAGE VARIABLES ========== */

    IAddressResolver public resolverProxy;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _resolverProxy) {
        resolverProxy = _resolverProxy;
    }

    /* ========== VIEWS ========== */

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return
            IFuturesMarketManager(
                resolverProxy.requireAndGetAddress("FuturesMarketManager", "Missing FuturesMarketManager Address")
            );
    }

    function _perpsV2MarketSettings() internal view returns (IPerpsV2MarketSettings) {
        return
            IPerpsV2MarketSettings(
                resolverProxy.requireAndGetAddress("PerpsV2MarketSettings", "Missing PerpsV2MarketSettings Address")
            );
    }

    function globals() external view returns (FuturesGlobals memory) {
        IPerpsV2MarketSettings settings = _perpsV2MarketSettings();
        return
            FuturesGlobals({
                minInitialMargin: settings.minInitialMargin(),
                liquidationFeeRatio: settings.liquidationFeeRatio(),
                minKeeperFee: settings.minKeeperFee(),
                maxKeeperFee: settings.maxKeeperFee()
            });
    }

    function parameters(bytes32 marketKey) external view returns (IPerpsV2MarketSettings.Parameters memory) {
        return _parameters(marketKey);
    }

    function _parameters(bytes32 marketKey) internal view returns (IPerpsV2MarketSettings.Parameters memory) {
        return _perpsV2MarketSettings().parameters(marketKey);
    }

    function _isLegacyMarket(address[] memory legacyMarkets, address market) internal view returns (bool) {
        for (uint256 i; i < legacyMarkets.length; i++) {
            if (legacyMarkets[i] == market) {
                return true;
            }
        }
        return false;
    }

    function _marketSummaries(address[] memory markets) internal view returns (MarketSummary[] memory) {
        uint256 numMarkets = markets.length;
        MarketSummary[] memory summaries = new MarketSummary[](numMarkets);

        // get mapping of legacyMarkets
        address[] memory legacyMarkets = _futuresMarketManager().allMarkets();

        for (uint256 i; i < numMarkets; i++) {
            IPerpsV2MarketViews market = IPerpsV2MarketViews(markets[i]);
            bytes32 marketKey = market.marketKey();
            bytes32 baseAsset = market.baseAsset();
            IPerpsV2MarketSettings.Parameters memory params = _parameters(marketKey);

            (uint256 price, ) = market.assetPrice();
            (uint256 debt, ) = market.marketDebt();
            bool isLegacy = _isLegacyMarket(legacyMarkets, markets[i]);

            summaries[i] = MarketSummary(
                address(market),
                baseAsset,
                marketKey,
                params.maxLeverage,
                price,
                market.marketSize(),
                market.marketSkew(),
                debt,
                market.currentFundingRate(),
                isLegacy ? int256(0) : market.currentFundingVelocity(),
                FeeRates(
                    params.takerFee,
                    params.makerFee,
                    params.takerFeeDelayedOrder,
                    params.makerFeeDelayedOrder,
                    params.takerFeeOffchainDelayedOrder,
                    params.makerFeeOffchainDelayedOrder
                )
            );
        }

        return summaries;
    }

    function marketSummaries(address[] calldata markets) external view returns (MarketSummary[] memory) {
        return _marketSummaries(markets);
    }

    function marketSummariesForKeys(bytes32[] calldata marketKeys) external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().marketsForKeys(marketKeys));
    }

    function allMarketSummaries() external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().allMarkets());
    }

    function allProxiedMarketSummaries() external view returns (MarketSummary[] memory) {
        return _marketSummaries(_futuresMarketManager().allMarkets(true));
    }

    function _fundingParameters(
        IPerpsV2MarketSettings.Parameters memory params
    ) internal pure returns (FundingParameters memory) {
        return FundingParameters(params.maxFundingVelocity, params.skewScale);
    }

    function _marketSizes(IPerpsV2MarketViews market) internal view returns (Sides memory) {
        (uint256 long, uint256 short) = market.marketSizes();
        return Sides(long, short);
    }

    function _marketDetails(IPerpsV2MarketViews market) internal view returns (MarketData memory) {
        (uint256 price, bool invalid) = market.assetPrice();
        (uint256 marketDebt, ) = market.marketDebt();
        bytes32 baseAsset = market.baseAsset();
        bytes32 marketKey = market.marketKey();

        IPerpsV2MarketSettings.Parameters memory params = _parameters(marketKey);

        return
            MarketData(
                address(market),
                baseAsset,
                marketKey,
                FeeRates(
                    params.takerFee,
                    params.makerFee,
                    params.takerFeeDelayedOrder,
                    params.makerFeeDelayedOrder,
                    params.takerFeeOffchainDelayedOrder,
                    params.makerFeeOffchainDelayedOrder
                ),
                MarketLimits(params.maxLeverage, params.maxMarketValue),
                _fundingParameters(params),
                MarketSizeDetails(market.marketSize(), _marketSizes(market), marketDebt, market.marketSkew()),
                PriceDetails(price, invalid)
            );
    }

    function marketDetails(IPerpsV2MarketViews market) external view returns (MarketData memory) {
        return _marketDetails(market);
    }

    function marketDetailsForKey(bytes32 marketKey) external view returns (MarketData memory) {
        return _marketDetails(IPerpsV2MarketViews(_futuresMarketManager().marketForKey(marketKey)));
    }

    function _position(
        IPerpsV2MarketViews market,
        address account
    ) internal view returns (IPerpsV2MarketBaseTypes.Position memory) {
        return market.positions(account);
    }

    function _notionalValue(IPerpsV2MarketViews market, address account) internal view returns (int256) {
        (int256 value, ) = market.notionalValue(account);
        return value;
    }

    function _profitLoss(IPerpsV2MarketViews market, address account) internal view returns (int256) {
        (int256 value, ) = market.profitLoss(account);
        return value;
    }

    function _accruedFunding(IPerpsV2MarketViews market, address account) internal view returns (int256) {
        (int256 value, ) = market.accruedFunding(account);
        return value;
    }

    function _remainingMargin(IPerpsV2MarketViews market, address account) internal view returns (uint256) {
        (uint256 value, ) = market.remainingMargin(account);
        return value;
    }

    function _accessibleMargin(IPerpsV2MarketViews market, address account) internal view returns (uint256) {
        (uint256 value, ) = market.accessibleMargin(account);
        return value;
    }

    function _liquidationPrice(IPerpsV2MarketViews market, address account) internal view returns (uint256) {
        (uint256 liquidationPrice, ) = market.liquidationPrice(account);
        return liquidationPrice;
    }

    function _positionDetails(IPerpsV2MarketViews market, address account) internal view returns (PositionData memory) {
        return
            PositionData(
                _position(market, account),
                _notionalValue(market, account),
                _profitLoss(market, account),
                _accruedFunding(market, account),
                _remainingMargin(market, account),
                _accessibleMargin(market, account),
                _liquidationPrice(market, account),
                market.canLiquidate(account)
            );
    }

    function positionDetails(IPerpsV2MarketViews market, address account) external view returns (PositionData memory) {
        return _positionDetails(market, account);
    }

    function positionDetailsForMarketKey(bytes32 marketKey, address account) external view returns (PositionData memory) {
        return _positionDetails(IPerpsV2MarketViews(_futuresMarketManager().marketForKey(marketKey)), account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAvailableBridge(bytes32 bridgeName) external view returns (address);

    function getBridgeList() external view returns (bytes32[] memory);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFuturesMarketManager {
    function markets(uint256 index, uint256 pageSize) external view returns (address[] memory);

    function numMarkets() external view returns (uint256);

    function allMarkets() external view returns (address[] memory);

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint256 debt, bool isInvalid);

    function isMarketImplementation(address _account) external view returns (bool);

    function sendIncreaseSynth(bytes32 bridgeKey, bytes32 synthKey, uint256 synthAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPerpsV2MarketBaseTypes {
    /* ========== TYPES ========== */

    enum OrderType {
        Atomic,
        Delayed,
        Offchain
    }

    enum Status {
        Ok,
        InvalidPrice,
        InvalidOrderType,
        PriceOutOfBounds,
        CanLiquidate,
        CannotLiquidate,
        MaxMarketSizeExceeded,
        MaxLeverageExceeded,
        InsufficientMargin,
        NotPermitted,
        NilOrder,
        NoPositionOpen,
        PriceTooVolatile,
        PriceImpactToleranceExceeded,
        PositionFlagged,
        PositionNotFlagged
    }

    // If margin/size are positive, the position is long; if negative then it is short.
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    // Delayed order storage
    struct DelayedOrder {
        bool isOffchain; // flag indicating the delayed order is offchain
        int128 sizeDelta; // difference in position to pass to modifyPosition
        uint128 desiredFillPrice; // desired fill price as usd used on fillPrice at execution
        uint128 targetRoundId; // price oracle roundId using which price this order needs to executed
        uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
        uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
        uint256 executableAtTime; // The timestamp at which this order is executable at
        uint256 intentionTime; // The block timestamp of submission
        bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPerpsV2MarketSettings {
    struct Parameters {
        uint256 takerFee;
        uint256 makerFee;
        uint256 takerFeeDelayedOrder;
        uint256 makerFeeDelayedOrder;
        uint256 takerFeeOffchainDelayedOrder;
        uint256 makerFeeOffchainDelayedOrder;
        uint256 maxLeverage;
        uint256 maxMarketValue;
        uint256 maxFundingVelocity;
        uint256 skewScale;
        uint256 nextPriceConfirmWindow;
        uint256 delayedOrderConfirmWindow;
        uint256 minDelayTimeDelta;
        uint256 maxDelayTimeDelta;
        uint256 offchainDelayedOrderMinAge;
        uint256 offchainDelayedOrderMaxAge;
        bytes32 offchainMarketKey;
        uint256 offchainPriceDivergence;
        uint256 liquidationPremiumMultiplier;
        uint256 liquidationBufferRatio;
        uint256 maxLiquidationDelta;
        uint256 maxPD;
    }

    function takerFee(bytes32 _marketKey) external view returns (uint256);

    function makerFee(bytes32 _marketKey) external view returns (uint256);

    function takerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint256);

    function makerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint256);

    function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint256);

    function makerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint256);

    function nextPriceConfirmWindow(bytes32 _marketKey) external view returns (uint256);

    function delayedOrderConfirmWindow(bytes32 _marketKey) external view returns (uint256);

    function offchainDelayedOrderMinAge(bytes32 _marketKey) external view returns (uint256);

    function offchainDelayedOrderMaxAge(bytes32 _marketKey) external view returns (uint256);

    function maxLeverage(bytes32 _marketKey) external view returns (uint256);

    function maxMarketValue(bytes32 _marketKey) external view returns (uint256);

    function maxFundingVelocity(bytes32 _marketKey) external view returns (uint256);

    function skewScale(bytes32 _marketKey) external view returns (uint256);

    function minDelayTimeDelta(bytes32 _marketKey) external view returns (uint256);

    function maxDelayTimeDelta(bytes32 _marketKey) external view returns (uint256);

    function offchainMarketKey(bytes32 _marketKey) external view returns (bytes32);

    function offchainPriceDivergence(bytes32 _marketKey) external view returns (uint256);

    function liquidationPremiumMultiplier(bytes32 _marketKey) external view returns (uint256);

    function maxPD(bytes32 _marketKey) external view returns (uint256);

    function maxLiquidationDelta(bytes32 _marketKey) external view returns (uint256);

    function liquidationBufferRatio(bytes32 _marketKey) external view returns (uint256);

    function parameters(bytes32 _marketKey) external view returns (Parameters memory);

    function minKeeperFee() external view returns (uint256);

    function maxKeeperFee() external view returns (uint256);

    function liquidationFeeRatio() external view returns (uint256);

    function minInitialMargin() external view returns (uint256);

    function keeperLiquidationFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPerpsV2MarketBaseTypes.sol";

interface IPerpsV2MarketViews {
    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingRateLastRecomputed() external view returns (int128 fundingRate);

    function fundingSequence(uint256 index) external view returns (int128 netFunding);

    function positions(address account) external view returns (IPerpsV2MarketBaseTypes.Position memory);

    function delayedOrders(address account) external view returns (IPerpsV2MarketBaseTypes.DelayedOrder memory);

    function assetPrice() external view returns (uint256 price, bool invalid);

    function fillPrice(int256 sizeDelta) external view returns (uint256 price, bool invalid);

    function marketSizes() external view returns (uint256 long, uint256 short);

    function marketDebt() external view returns (uint256 debt, bool isInvalid);

    function currentFundingRate() external view returns (int256 fundingRate);

    function currentFundingVelocity() external view returns (int256 fundingVelocity);

    function unrecordedFunding() external view returns (int256 funding, bool invalid);

    function fundingSequenceLength() external view returns (uint256 length);

    /* ---------- Position Details ---------- */

    function notionalValue(address account) external view returns (int256 value, bool invalid);

    function profitLoss(address account) external view returns (int256 pnl, bool invalid);

    function accruedFunding(address account) external view returns (int256 funding, bool invalid);

    function remainingMargin(address account) external view returns (uint256 marginRemaining, bool invalid);

    function accessibleMargin(address account) external view returns (uint256 marginAccessible, bool invalid);

    function liquidationPrice(address account) external view returns (uint256 price, bool invalid);

    function liquidationFee(address account) external view returns (uint256);

    function isFlagged(address account) external view returns (bool);

    function canLiquidate(address account) external view returns (bool);

    function orderFee(
        int256 sizeDelta,
        IPerpsV2MarketBaseTypes.OrderType orderType
    ) external view returns (uint256 fee, bool invalid);

    function postTradeDetails(
        int256 sizeDelta,
        uint256 tradePrice,
        IPerpsV2MarketBaseTypes.OrderType orderType,
        address sender
    )
        external
        view
        returns (
            uint256 margin,
            int256 size,
            uint256 price,
            uint256 liqPrice,
            uint256 fee,
            IPerpsV2MarketBaseTypes.Status status
        );
}