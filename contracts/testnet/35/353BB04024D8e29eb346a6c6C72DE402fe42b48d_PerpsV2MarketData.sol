/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

/* Tribeone: PerpsV2MarketData.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/PerpsV2MarketData.sol
* Docs: https://docs.tribeone.io/contracts/PerpsV2MarketData
*
* Contract Dependencies: (none)
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

interface IFuturesMarketManager {
    function markets(uint index, uint pageSize) external view returns (address[] memory);

    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory);

    function numMarkets() external view returns (uint);

    function numMarkets(bool proxiedMarkets) external view returns (uint);

    function allMarkets() external view returns (address[] memory);

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint debt, bool isInvalid);

    function isEndorsed(address account) external view returns (bool);

    function allEndorsedAddresses() external view returns (address[] memory);

    function addEndorsedAddresses(address[] calldata addresses) external;

    function removeEndorsedAddresses(address[] calldata addresses) external;
}


interface IPerpsV2MarketBaseTypes {
    /* ========== TYPES ========== */

    enum OrderType {Atomic, Delayed, Offchain}

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


pragma experimental ABIEncoderV2;


interface IPerpsV2MarketViews {
    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingRateLastRecomputed() external view returns (int128 fundingRate);

    function fundingSequence(uint index) external view returns (int128 netFunding);

    function positions(address account) external view returns (IPerpsV2MarketBaseTypes.Position memory);

    function delayedOrders(address account) external view returns (IPerpsV2MarketBaseTypes.DelayedOrder memory);

    function assetPrice() external view returns (uint price, bool invalid);

    function fillPrice(int sizeDelta) external view returns (uint price, bool invalid);

    function marketSizes() external view returns (uint long, uint short);

    function marketDebt() external view returns (uint debt, bool isInvalid);

    function currentFundingRate() external view returns (int fundingRate);

    function currentFundingVelocity() external view returns (int fundingVelocity);

    function unrecordedFunding() external view returns (int funding, bool invalid);

    function fundingSequenceLength() external view returns (uint length);

    /* ---------- Position Details ---------- */

    function notionalValue(address account) external view returns (int value, bool invalid);

    function profitLoss(address account) external view returns (int pnl, bool invalid);

    function accruedFunding(address account) external view returns (int funding, bool invalid);

    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid);

    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid);

    function liquidationPrice(address account) external view returns (uint price, bool invalid);

    function liquidationFee(address account) external view returns (uint);

    function isFlagged(address account) external view returns (bool);

    function canLiquidate(address account) external view returns (bool);

    function orderFee(int sizeDelta, IPerpsV2MarketBaseTypes.OrderType orderType)
        external
        view
        returns (uint fee, bool invalid);

    function postTradeDetails(
        int sizeDelta,
        uint tradePrice,
        IPerpsV2MarketBaseTypes.OrderType orderType,
        address sender
    )
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            IPerpsV2MarketBaseTypes.Status status
        );
}


interface IPerpsV2MarketSettings {
    struct Parameters {
        uint takerFee;
        uint makerFee;
        uint takerFeeDelayedOrder;
        uint makerFeeDelayedOrder;
        uint takerFeeOffchainDelayedOrder;
        uint makerFeeOffchainDelayedOrder;
        uint maxLeverage;
        uint maxMarketValue;
        uint maxFundingVelocity;
        uint skewScale;
        uint nextPriceConfirmWindow;
        uint delayedOrderConfirmWindow;
        uint minDelayTimeDelta;
        uint maxDelayTimeDelta;
        uint offchainDelayedOrderMinAge;
        uint offchainDelayedOrderMaxAge;
        bytes32 offchainMarketKey;
        uint offchainPriceDivergence;
        uint liquidationPremiumMultiplier;
        uint liquidationBufferRatio;
        uint maxLiquidationDelta;
        uint maxPD;
    }

    function takerFee(bytes32 _marketKey) external view returns (uint);

    function makerFee(bytes32 _marketKey) external view returns (uint);

    function takerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function makerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function makerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function nextPriceConfirmWindow(bytes32 _marketKey) external view returns (uint);

    function delayedOrderConfirmWindow(bytes32 _marketKey) external view returns (uint);

    function offchainDelayedOrderMinAge(bytes32 _marketKey) external view returns (uint);

    function offchainDelayedOrderMaxAge(bytes32 _marketKey) external view returns (uint);

    function maxLeverage(bytes32 _marketKey) external view returns (uint);

    function maxMarketValue(bytes32 _marketKey) external view returns (uint);

    function maxFundingVelocity(bytes32 _marketKey) external view returns (uint);

    function skewScale(bytes32 _marketKey) external view returns (uint);

    function minDelayTimeDelta(bytes32 _marketKey) external view returns (uint);

    function maxDelayTimeDelta(bytes32 _marketKey) external view returns (uint);

    function offchainMarketKey(bytes32 _marketKey) external view returns (bytes32);

    function offchainPriceDivergence(bytes32 _marketKey) external view returns (uint);

    function liquidationPremiumMultiplier(bytes32 _marketKey) external view returns (uint);

    function maxPD(bytes32 _marketKey) external view returns (uint);

    function maxLiquidationDelta(bytes32 _marketKey) external view returns (uint);

    function liquidationBufferRatio(bytes32 _marketKey) external view returns (uint);

    function parameters(bytes32 _marketKey) external view returns (Parameters memory);

    function minKeeperFee() external view returns (uint);

    function maxKeeperFee() external view returns (uint);

    function liquidationFeeRatio() external view returns (uint);

    function minInitialMargin() external view returns (uint);

    function keeperLiquidationFee() external view returns (uint);
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketData
// A utility contract to allow the front end to query market data in a single call.
contract PerpsV2MarketData {
    /* ========== TYPES ========== */

    struct FuturesGlobals {
        uint minInitialMargin;
        uint liquidationFeeRatio;
        uint minKeeperFee;
        uint maxKeeperFee;
    }

    struct MarketSummary {
        address market;
        bytes32 asset;
        bytes32 key;
        uint maxLeverage;
        uint price;
        uint marketSize;
        int marketSkew;
        uint marketDebt;
        int currentFundingRate;
        int currentFundingVelocity;
        FeeRates feeRates;
    }

    struct MarketLimits {
        uint maxLeverage;
        uint maxMarketValue;
    }

    struct Sides {
        uint long;
        uint short;
    }

    struct MarketSizeDetails {
        uint marketSize;
        PerpsV2MarketData.Sides sides;
        uint marketDebt;
        int marketSkew;
    }

    struct PriceDetails {
        uint price;
        bool invalid;
    }

    struct FundingParameters {
        uint maxFundingVelocity;
        uint skewScale;
    }

    struct FeeRates {
        uint takerFee;
        uint makerFee;
        uint takerFeeDelayedOrder;
        uint makerFeeDelayedOrder;
        uint takerFeeOffchainDelayedOrder;
        uint makerFeeOffchainDelayedOrder;
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
        int notionalValue;
        int profitLoss;
        int accruedFunding;
        uint remainingMargin;
        uint accessibleMargin;
        uint liquidationPrice;
        bool canLiquidatePosition;
    }

    /* ========== STORAGE VARIABLES ========== */

    IAddressResolver public resolverProxy;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _resolverProxy) public {
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
        for (uint i; i < legacyMarkets.length; i++) {
            if (legacyMarkets[i] == market) {
                return true;
            }
        }
        return false;
    }

    function _marketSummaries(address[] memory markets) internal view returns (MarketSummary[] memory) {
        uint numMarkets = markets.length;
        MarketSummary[] memory summaries = new MarketSummary[](numMarkets);

        // get mapping of legacyMarkets
        address[] memory legacyMarkets = _futuresMarketManager().allMarkets(false);

        for (uint i; i < numMarkets; i++) {
            IPerpsV2MarketViews market = IPerpsV2MarketViews(markets[i]);
            bytes32 marketKey = market.marketKey();
            bytes32 baseAsset = market.baseAsset();
            IPerpsV2MarketSettings.Parameters memory params = _parameters(marketKey);

            (uint price, ) = market.assetPrice();
            (uint debt, ) = market.marketDebt();
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
                isLegacy ? 0 : market.currentFundingVelocity(),
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

    function _fundingParameters(IPerpsV2MarketSettings.Parameters memory params)
        internal
        pure
        returns (FundingParameters memory)
    {
        return FundingParameters(params.maxFundingVelocity, params.skewScale);
    }

    function _marketSizes(IPerpsV2MarketViews market) internal view returns (Sides memory) {
        (uint long, uint short) = market.marketSizes();
        return Sides(long, short);
    }

    function _marketDetails(IPerpsV2MarketViews market) internal view returns (MarketData memory) {
        (uint price, bool invalid) = market.assetPrice();
        (uint marketDebt, ) = market.marketDebt();
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

    function _position(IPerpsV2MarketViews market, address account)
        internal
        view
        returns (IPerpsV2MarketBaseTypes.Position memory)
    {
        return market.positions(account);
    }

    function _notionalValue(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.notionalValue(account);
        return value;
    }

    function _profitLoss(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.profitLoss(account);
        return value;
    }

    function _accruedFunding(IPerpsV2MarketViews market, address account) internal view returns (int) {
        (int value, ) = market.accruedFunding(account);
        return value;
    }

    function _remainingMargin(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint value, ) = market.remainingMargin(account);
        return value;
    }

    function _accessibleMargin(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint value, ) = market.accessibleMargin(account);
        return value;
    }

    function _liquidationPrice(IPerpsV2MarketViews market, address account) internal view returns (uint) {
        (uint liquidationPrice, ) = market.liquidationPrice(account);
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