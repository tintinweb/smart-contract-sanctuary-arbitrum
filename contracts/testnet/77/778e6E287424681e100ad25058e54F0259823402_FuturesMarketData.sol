/**
 *Submitted for verification at Arbiscan on 2023-05-30
*/

/* Tribeone: FuturesMarketData.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/FuturesMarketData.sol
* Docs: https://docs.tribeone.io/contracts/FuturesMarketData
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

interface IFuturesMarketBaseTypes {
    /* ========== TYPES ========== */

    enum Status {
        Ok,
        InvalidPrice,
        PriceOutOfBounds,
        CanLiquidate,
        CannotLiquidate,
        MaxMarketSizeExceeded,
        MaxLeverageExceeded,
        InsufficientMargin,
        NotPermitted,
        NilOrder,
        NoPositionOpen,
        PriceTooVolatile
    }

    // If margin/size are positive, the position is long; if negative then it is short.
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    // next-price order storage
    struct NextPriceOrder {
        int128 sizeDelta; // difference in position to pass to modifyPosition
        uint128 targetRoundId; // price oracle roundId using which price this order needs to exucted
        uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
        uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
        bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
    }
}


interface IFuturesMarket {
    /* ========== FUNCTION INTERFACE ========== */

    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingSequence(uint index) external view returns (int128 netFunding);

    function positions(address account)
        external
        view
        returns (
            uint64 id,
            uint64 fundingIndex,
            uint128 margin,
            uint128 lastPrice,
            int128 size
        );

    function assetPrice() external view returns (uint price, bool invalid);

    function marketSizes() external view returns (uint long, uint short);

    function marketDebt() external view returns (uint debt, bool isInvalid);

    function currentFundingRate() external view returns (int fundingRate);

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

    function canLiquidate(address account) external view returns (bool);

    function orderFee(int sizeDelta) external view returns (uint fee, bool invalid);

    function postTradeDetails(int sizeDelta, address sender)
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            IFuturesMarketBaseTypes.Status status
        );

    /* ---------- Market Operations ---------- */

    function recomputeFunding() external returns (uint lastIndex);

    function transferMargin(int marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPosition(int sizeDelta) external;

    function modifyPositionWithTracking(int sizeDelta, bytes32 trackingCode) external;

    function submitNextPriceOrder(int sizeDelta) external;

    function submitNextPriceOrderWithTracking(int sizeDelta, bytes32 trackingCode) external;

    function cancelNextPriceOrder(address account) external;

    function executeNextPriceOrder(address account) external;

    function closePosition() external;

    function closePositionWithTracking(bytes32 trackingCode) external;

    function liquidatePosition(address account) external;
}


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


interface IFuturesMarketSettings {
    struct Parameters {
        uint takerFee;
        uint makerFee;
        uint takerFeeNextPrice;
        uint makerFeeNextPrice;
        uint nextPriceConfirmWindow;
        uint maxLeverage;
        uint maxMarketValueUSD;
        uint maxFundingRate;
        uint skewScaleUSD;
    }

    function takerFee(bytes32 _marketKey) external view returns (uint);

    function makerFee(bytes32 _marketKey) external view returns (uint);

    function takerFeeNextPrice(bytes32 _marketKey) external view returns (uint);

    function makerFeeNextPrice(bytes32 _marketKey) external view returns (uint);

    function nextPriceConfirmWindow(bytes32 _marketKey) external view returns (uint);

    function maxLeverage(bytes32 _marketKey) external view returns (uint);

    function maxMarketValueUSD(bytes32 _marketKey) external view returns (uint);

    function maxFundingRate(bytes32 _marketKey) external view returns (uint);

    function skewScaleUSD(bytes32 _marketKey) external view returns (uint);

    function parameters(bytes32 _marketKey)
        external
        view
        returns (
            uint _takerFee,
            uint _makerFee,
            uint _takerFeeNextPrice,
            uint _makerFeeNextPrice,
            uint _nextPriceConfirmWindow,
            uint _maxLeverage,
            uint _maxMarketValueUSD,
            uint _maxFundingRate,
            uint _skewScaleUSD
        );

    function minKeeperFee() external view returns (uint);

    function liquidationFeeRatio() external view returns (uint);

    function liquidationBufferRatio() external view returns (uint);

    function minInitialMargin() external view returns (uint);
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


pragma experimental ABIEncoderV2;

// Internal references


// https://docs.tribeone.io/contracts/source/contracts/FuturesMarketData
// A utility contract to allow the front end to query market data in a single call.
contract FuturesMarketData {
    /* ========== TYPES ========== */

    struct FuturesGlobals {
        uint minInitialMargin;
        uint liquidationFeeRatio;
        uint liquidationBufferRatio;
        uint minKeeperFee;
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
        FeeRates feeRates;
    }

    struct MarketLimits {
        uint maxLeverage;
        uint maxMarketValueUSD;
    }

    struct Sides {
        uint long;
        uint short;
    }

    struct MarketSizeDetails {
        uint marketSize;
        FuturesMarketData.Sides sides;
        uint marketDebt;
        int marketSkew;
    }

    struct PriceDetails {
        uint price;
        bool invalid;
    }

    struct FundingParameters {
        uint maxFundingRate;
        uint skewScaleUSD;
    }

    struct FeeRates {
        uint takerFee;
        uint makerFee;
        uint takerFeeNextPrice;
        uint makerFeeNextPrice;
    }

    struct FundingDetails {
        int currentFundingRate;
        int unrecordedFunding;
        uint fundingLastRecomputed;
    }

    struct MarketData {
        address market;
        bytes32 baseAsset;
        bytes32 marketKey;
        FuturesMarketData.FeeRates feeRates;
        FuturesMarketData.MarketLimits limits;
        FuturesMarketData.FundingParameters fundingParameters;
        FuturesMarketData.MarketSizeDetails marketSizeDetails;
        FuturesMarketData.PriceDetails priceDetails;
    }

    struct PositionData {
        IFuturesMarketBaseTypes.Position position;
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

    function _futuresMarketSettings() internal view returns (IFuturesMarketSettings) {
        return
            IFuturesMarketSettings(
                resolverProxy.requireAndGetAddress("FuturesMarketSettings", "Missing FuturesMarketSettings Address")
            );
    }

    function globals() external view returns (FuturesGlobals memory) {
        IFuturesMarketSettings settings = _futuresMarketSettings();
        return
            FuturesGlobals({
                minInitialMargin: settings.minInitialMargin(),
                liquidationFeeRatio: settings.liquidationFeeRatio(),
                liquidationBufferRatio: settings.liquidationBufferRatio(),
                minKeeperFee: settings.minKeeperFee()
            });
    }

    function parameters(bytes32 marketKey) external view returns (IFuturesMarketSettings.Parameters memory) {
        return _parameters(marketKey);
    }

    function _parameters(bytes32 marketKey) internal view returns (IFuturesMarketSettings.Parameters memory) {
        (
            uint takerFee,
            uint makerFee,
            uint takerFeeNextPrice,
            uint makerFeeNextPrice,
            uint nextPriceConfirmWindow,
            uint maxLeverage,
            uint maxMarketValueUSD,
            uint maxFundingRate,
            uint skewScaleUSD
        ) = _futuresMarketSettings().parameters(marketKey);
        return
            IFuturesMarketSettings.Parameters(
                takerFee,
                makerFee,
                takerFeeNextPrice,
                makerFeeNextPrice,
                nextPriceConfirmWindow,
                maxLeverage,
                maxMarketValueUSD,
                maxFundingRate,
                skewScaleUSD
            );
    }

    function _marketSummaries(address[] memory markets) internal view returns (MarketSummary[] memory) {
        uint numMarkets = markets.length;
        MarketSummary[] memory summaries = new MarketSummary[](numMarkets);
        for (uint i; i < numMarkets; i++) {
            IFuturesMarket market = IFuturesMarket(markets[i]);
            bytes32 marketKey = market.marketKey();
            bytes32 baseAsset = market.baseAsset();
            IFuturesMarketSettings.Parameters memory params = _parameters(marketKey);

            (uint price, ) = market.assetPrice();
            (uint debt, ) = market.marketDebt();

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
                FeeRates(params.takerFee, params.makerFee, params.takerFeeNextPrice, params.makerFeeNextPrice)
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

    function _fundingParameters(IFuturesMarketSettings.Parameters memory params)
        internal
        pure
        returns (FundingParameters memory)
    {
        return FundingParameters(params.maxFundingRate, params.skewScaleUSD);
    }

    function _marketSizes(IFuturesMarket market) internal view returns (Sides memory) {
        (uint long, uint short) = market.marketSizes();
        return Sides(long, short);
    }

    function _marketDetails(IFuturesMarket market) internal view returns (MarketData memory) {
        (uint price, bool invalid) = market.assetPrice();
        (uint marketDebt, ) = market.marketDebt();
        bytes32 baseAsset = market.baseAsset();
        bytes32 marketKey = market.marketKey();

        IFuturesMarketSettings.Parameters memory params = _parameters(marketKey);

        return
            MarketData(
                address(market),
                baseAsset,
                marketKey,
                FeeRates(params.takerFee, params.makerFee, params.takerFeeNextPrice, params.makerFeeNextPrice),
                MarketLimits(params.maxLeverage, params.maxMarketValueUSD),
                _fundingParameters(params),
                MarketSizeDetails(market.marketSize(), _marketSizes(market), marketDebt, market.marketSkew()),
                PriceDetails(price, invalid)
            );
    }

    function marketDetails(IFuturesMarket market) external view returns (MarketData memory) {
        return _marketDetails(market);
    }

    function marketDetailsForKey(bytes32 marketKey) external view returns (MarketData memory) {
        return _marketDetails(IFuturesMarket(_futuresMarketManager().marketForKey(marketKey)));
    }

    function _position(IFuturesMarket market, address account)
        internal
        view
        returns (IFuturesMarketBaseTypes.Position memory)
    {
        (
            uint64 positionId,
            uint64 positionEntryIndex,
            uint128 positionMargin,
            uint128 positionEntryPrice,
            int128 positionSize
        ) = market.positions(account);
        return
            IFuturesMarketBaseTypes.Position(
                positionId,
                positionEntryIndex,
                positionMargin,
                positionEntryPrice,
                positionSize
            );
    }

    function _notionalValue(IFuturesMarket market, address account) internal view returns (int) {
        (int value, ) = market.notionalValue(account);
        return value;
    }

    function _profitLoss(IFuturesMarket market, address account) internal view returns (int) {
        (int value, ) = market.profitLoss(account);
        return value;
    }

    function _accruedFunding(IFuturesMarket market, address account) internal view returns (int) {
        (int value, ) = market.accruedFunding(account);
        return value;
    }

    function _remainingMargin(IFuturesMarket market, address account) internal view returns (uint) {
        (uint value, ) = market.remainingMargin(account);
        return value;
    }

    function _accessibleMargin(IFuturesMarket market, address account) internal view returns (uint) {
        (uint value, ) = market.accessibleMargin(account);
        return value;
    }

    function _liquidationPrice(IFuturesMarket market, address account) internal view returns (uint) {
        (uint liquidationPrice, ) = market.liquidationPrice(account);
        return liquidationPrice;
    }

    function _positionDetails(IFuturesMarket market, address account) internal view returns (PositionData memory) {
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

    function positionDetails(IFuturesMarket market, address account) external view returns (PositionData memory) {
        return _positionDetails(market, account);
    }

    function positionDetailsForMarketKey(bytes32 marketKey, address account) external view returns (PositionData memory) {
        return _positionDetails(IFuturesMarket(_futuresMarketManager().marketForKey(marketKey)), account);
    }
}