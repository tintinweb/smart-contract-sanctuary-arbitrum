// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 5
 */
interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6
 */
interface IGNSPairsStorage {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint256 spreadP; // PRECISION
        uint256 groupIndex;
        uint256 feeIndex;
    }
    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 maxCollateralP; // % (of DAI vault current balance)
    }
    struct Fee {
        string name;
        uint256 openFeeP; // PRECISION (% of leveraged pos)
        uint256 closeFeeP; // PRECISION (% of leveraged pos)
        uint256 oracleFeeP; // PRECISION (% of leveraged pos)
        uint256 nftLimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint256 referralFeeP; // PRECISION (% of leveraged pos)
        uint256 minLevPosDai; // 1e18 (collateral x leverage, useful for min fee)
    }

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairNftLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosDai(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);

    event PairAdded(uint256 index, string from, string to);
    event PairUpdated(uint256 index);

    event GroupAdded(uint256 index, string name);
    event GroupUpdated(uint256 index);

    event FeeAdded(uint256 index, string name);
    event FeeUpdated(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IChainlinkFeed.sol";
import "./IGNSTradingCallbacks.sol";
import "./IGNSPairsStorage.sol";

/**
 * @custom:version 6.4
 */
interface IGNSPriceAggregator {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    struct Order {
        uint16 pairIndex;
        uint112 linkFeePerNode;
        OrderType orderType;
        bool active;
        bool isLookback;
    }

    struct LookbackOrderAnswer {
        uint64 open;
        uint64 high;
        uint64 low;
        uint64 ts;
    }

    function pairsStorage() external view returns (IGNSPairsStorage);

    function getPrice(uint256, OrderType, uint256, uint256) external returns (uint256);

    function tokenPriceDai() external returns (uint256);

    function linkFee(uint256, uint256) external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function linkPriceFeed() external view returns (IChainlinkFeed);

    function nodes(uint256 index) external view returns (address);

    event PairsStorageUpdated(address value);
    event LinkPriceFeedUpdated(address value);
    event MinAnswersUpdated(uint256 value);

    event NodeAdded(uint256 index, address value);
    event NodeReplaced(uint256 index, address oldNode, address newNode);
    event NodeRemoved(uint256 index, address oldNode);

    event JobIdUpdated(uint256 index, bytes32 jobId);

    event PriceRequested(
        uint256 indexed orderId,
        bytes32 indexed job,
        uint256 indexed pairIndex,
        OrderType orderType,
        uint256 nodesCount,
        uint256 linkFeePerNode,
        uint256 fromBlock,
        bool isLookback
    );

    event PriceReceived(
        bytes32 request,
        uint256 indexed orderId,
        address indexed node,
        uint16 indexed pairIndex,
        uint256 price,
        uint256 referencePrice,
        uint112 linkFee,
        bool isLookback,
        bool usedInMedian
    );

    event CallbackExecuted(IGNSTradingCallbacks.AggregatorAnswer a, OrderType orderType);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSTradingCallbacks {
    struct AggregatorAnswer {
        uint256 orderId;
        uint256 price;
        uint256 spreadP;
        uint256 open;
        uint256 high;
        uint256 low;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint256 posDai;
        uint256 levPosDai;
        uint256 tokenPriceDai;
        int256 profitP;
        uint256 price;
        uint256 liqPrice;
        uint256 daiSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
        bool exactExecution;
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }

    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    struct TradeData {
        uint40 maxSlippageP; // 1e10 (%)
        uint48 lastOiUpdateTs;
        uint168 _placeholder; // for potential future data
    }

    struct OpenTradePrepInput {
        uint256 executionPrice;
        uint256 wantedPrice;
        uint256 marketPrice;
        uint256 spreadP;
        bool buy;
        uint256 pairIndex;
        uint256 positionSize;
        uint256 leverage;
        uint256 maxSlippageP;
        uint256 tp;
        uint256 sl;
    }

    enum TradeType {
        MARKET,
        LIMIT
    }

    enum CancelReason {
        NONE,
        PAUSED,
        MARKET_CLOSED,
        SLIPPAGE,
        TP_REACHED,
        SL_REACHED,
        EXPOSURE_LIMITS,
        PRICE_IMPACT,
        MAX_LEVERAGE,
        NO_TRADE,
        WRONG_TRADE,
        NOT_HIT
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;

    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;

    function getTradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    event MarketExecuted(
        uint256 indexed orderId,
        IGNSTradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit, // before fees
        uint256 daiSentToTrader
    );

    event LimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        IGNSTradingStorage.Trade t,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit,
        uint256 daiSentToTrader,
        bool exactExecution
    );

    event MarketOpenCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        CancelReason cancelReason
    );
    event MarketCloseCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        CancelReason cancelReason
    );
    event NftOrderCanceled(
        uint256 indexed orderId,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        CancelReason cancelReason
    );

    event ClosingFeeSharesPUpdated(uint256 daiVaultFeeP, uint256 lpFeeP, uint256 sssFeeP);

    event Pause(bool paused);
    event Done(bool done);
    event GovFeesClaimed(uint256 valueDai);

    event GovFeeCharged(address indexed trader, uint256 valueDai, bool distributed);
    event ReferralFeeCharged(address indexed trader, uint256 valueDai);
    event TriggerFeeCharged(address indexed trader, uint256 valueDai);
    event SssFeeCharged(address indexed trader, uint256 valueDai);
    event DaiVaultFeeCharged(address indexed trader, uint256 valueDai);
    event BorrowingFeeCharged(address indexed trader, uint256 tradeValueDai, uint256 feeValueDai);
    event PairMaxLeverageUpdated(uint256 indexed pairIndex, uint256 maxLeverage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSPriceAggregator.sol"; // avoid chained conversions for pairsStorage

/**
 * @custom:version 5
 */
interface IGNSTradingStorage {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 initialPosToken; // 1e18
        uint256 positionSizeDai; // 1e18
        uint256 openPrice; // PRECISION
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION
        uint256 sl; // PRECISION
    }
    struct TradeInfo {
        uint256 tokenId;
        uint256 tokenPriceDai; // PRECISION
        uint256 openInterestDai; // 1e18
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize; // 1e18 (DAI or GFARM2)
        uint256 spreadReductionP;
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION (%)
        uint256 sl; // PRECISION (%)
        uint256 minPrice; // PRECISION
        uint256 maxPrice; // PRECISION
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; // PRECISION
        uint256 slippageP; // PRECISION (%)
        uint256 spreadReductionP;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint256 nftId;
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (address);

    function token() external view returns (address);

    function linkErc677() external view returns (address);

    function priceAggregator() external view returns (IGNSPriceAggregator);

    function vault() external view returns (address);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferDai(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function getOpenLimitOrders() external view returns (OpenLimitOrder[] memory);

    function spreadReductionsP(uint256) external view returns (uint256);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function increaseNftRewards(uint256, uint256) external;

    function nftSuccessTimelock() external view returns (uint256);

    function reqID_pendingNftOrder(uint256) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint256) external view returns (uint256);

    function unregisterPendingNftOrder(uint256) external;

    function handleDevGovFees(uint256, uint256, bool, bool) external returns (uint256);

    function distributeLpRewards(uint256) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestDai(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function nfts(uint256) external view returns (address);

    function fakeBlockNumber() external view returns (uint256); // Testing
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IGNSTradingStorage.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage a price impact decay algorithm .
 *
 * When a trade is placed, OI is added to the window corresponding to time of open.
 * When a trade is removed, OI is removed from the window corresponding to time of open.
 *
 * When calculating price impact, only the most recent X windows are taken into account.
 */
library PriceImpactUtils {
    uint256 private constant PRECISION = 1e10; // 10 decimals

    uint48 private constant MAX_WINDOWS_COUNT = 5;
    uint48 private constant MAX_WINDOWS_DURATION = 1 days;
    uint48 private constant MIN_WINDOWS_DURATION = 10 minutes;

    struct OiWindowsStorage {
        OiWindowsSettings settings;
        mapping(uint48 => mapping(uint256 => mapping(uint256 => PairOi))) windows; // duration => pairIndex => windowId => Oi
    }

    struct OiWindowsSettings {
        uint48 startTs;
        uint48 windowsDuration;
        uint48 windowsCount;
    }

    struct PairOi {
        uint128 long; // 1e18 (DAI)
        uint128 short; // 1e18 (DAI)
    }

    struct OiWindowUpdate {
        uint48 windowsDuration;
        uint256 pairIndex;
        uint256 windowId;
        bool long;
        uint128 openInterest; // 1e18 (DAI)
    }

    /**
     * @dev Triggered when OiWindowsSettings is initialized (once)
     */
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OiWindowsSettings.windowsCount is updated
     */
    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);

    /**
     * @dev Triggered when OiWindowsSettings.windowsDuration is updated
     */
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OI is added to a window.
     */
    event PriceImpactOpenInterestAdded(OiWindowUpdate oiWindowUpdate);

    /**
     * @dev Triggered when OI is (tentatively) removed from a window.
     */
    event PriceImpactOpenInterestRemoved(OiWindowUpdate oiWindowUpdate, bool notOutdated);

    /**
     * @dev Triggered when multiple pairs' OI are transferred to a new window.
     */
    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );

    /**
     * @dev Triggered when a pair's OI is transferred to a new window.
     */
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, PairOi totalPairOi);

    /**
     * @dev Returns storage pointer for struct in borrowing contract, at defined slot
     */
    function getStorage() private pure returns (OiWindowsStorage storage s) {
        uint256 storageSlot = StorageUtils.PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT;
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Validates new windowsDuration value
     */
    modifier validWindowsDuration(uint48 _windowsDuration) {
        require(
            _windowsDuration >= MIN_WINDOWS_DURATION && _windowsDuration <= MAX_WINDOWS_DURATION,
            "WRONG_WINDOWS_DURATION"
        );
        _;
    }

    /**
     * @dev Initializes OiWindowsSettings startTs and windowsDuration.
     * windowsCount is 0 for now for backwards-compatible behavior until oi windows have enough data.
     *
     * Should only be called once, in initializeV2() of borrowing contract.
     * Emits a {OiWindowsSettingsInitialized} event.
     */
    function initializeOiWindowsSettings(uint48 _windowsDuration) external validWindowsDuration(_windowsDuration) {
        getStorage().settings = OiWindowsSettings({
            startTs: uint48(block.timestamp),
            windowsDuration: _windowsDuration,
            windowsCount: 0 // maintains previous price impact OI behavior for now
        });

        emit OiWindowsSettingsInitialized(_windowsDuration);
    }

    /**
     * @dev Updates OiWindowSettings.windowsCount storage value
     *
     * Emits a {PriceImpactWindowsCountUpdated} event.
     */
    function setPriceImpactWindowsCount(uint48 _newWindowsCount) external {
        OiWindowsSettings storage settings = getStorage().settings;

        require(_newWindowsCount <= MAX_WINDOWS_COUNT, "ABOVE_MAX_WINDOWS_COUNT");
        require(_newWindowsCount == 0 || getCurrentWindowId(settings) >= _newWindowsCount - 1, "TOO_EARLY");

        settings.windowsCount = _newWindowsCount;

        emit PriceImpactWindowsCountUpdated(_newWindowsCount);
    }

    /**
     * @dev Updates OiWindowSettings.windowsDuration storage value,
     * and transfers the OI from all pairs past active windows (current window duration)
     * to the new current window (new window duration).
     *
     * Emits a {PriceImpactWindowsDurationUpdated} event.
     */
    function setPriceImpactWindowsDuration(
        uint48 _newWindowsDuration,
        uint256 _pairsCount
    ) external validWindowsDuration(_newWindowsDuration) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        if (settings.windowsCount > 0) {
            transferPriceImpactOiForPairs(
                _pairsCount,
                oiStorage.windows[settings.windowsDuration],
                oiStorage.windows[_newWindowsDuration],
                settings,
                _newWindowsDuration
            );
        }

        settings.windowsDuration = _newWindowsDuration;

        emit PriceImpactWindowsDurationUpdated(_newWindowsDuration);
    }

    /**
     * @dev Adds long / short `_openInterest` (1e18) to current window of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestAdded} event.
     */
    function addPriceImpactOpenInterest(uint128 _openInterest, uint256 _pairIndex, bool _long) external {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][currentWindowId];

        if (_long) {
            pairOi.long += _openInterest;
        } else {
            pairOi.short += _openInterest;
        }

        emit PriceImpactOpenInterestAdded(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, currentWindowId, _long, _openInterest)
        );
    }

    /**
     * @dev Removes `_openInterest` (1e18) from window at `_addTs` of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestRemoved} event when `_addTs` is greater than zero.
     */
    function removePriceImpactOpenInterest(
        uint128 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external {
        // If trade opened before update, OI wasn't stored in any window anyway
        if (_addTs == 0) {
            return;
        }

        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 addWindowId = getWindowId(_addTs, settings);

        bool notOutdated = isWindowPotentiallyActive(addWindowId, currentWindowId);

        // Only remove OI if window is not outdated already
        if (notOutdated) {
            PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][addWindowId];

            if (_long) {
                pairOi.long = _openInterest < pairOi.long ? pairOi.long - _openInterest : 0;
            } else {
                pairOi.short = _openInterest < pairOi.short ? pairOi.short - _openInterest : 0;
            }
        }

        emit PriceImpactOpenInterestRemoved(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, addWindowId, _long, _openInterest),
            notOutdated
        );
    }

    /**
     * @dev Transfers total long / short OI from last '_settings.windowsCount' windows of `_prevPairOiWindows`
     * to current window of `_newPairOiWindows` for `pairsCount` pairs.
     *
     * Emits a {PriceImpactOiTransferredPairs} event.
     */
    function transferPriceImpactOiForPairs(
        uint256 pairsCount,
        mapping(uint256 => mapping(uint256 => PairOi)) storage _prevPairOiWindows, // pairIndex => windowId => PairOi
        mapping(uint256 => mapping(uint256 => PairOi)) storage _newPairOiWindows, // pairIndex => windowId => PairOi
        OiWindowsSettings memory _settings,
        uint48 _newWindowsDuration
    ) private {
        uint256 prevCurrentWindowId = getCurrentWindowId(_settings);
        uint256 prevEarliestWindowId = getEarliestActiveWindowId(prevCurrentWindowId, _settings.windowsCount);

        uint256 newCurrentWindowId = getCurrentWindowId(
            OiWindowsSettings(_settings.startTs, _newWindowsDuration, _settings.windowsCount)
        );

        for (uint256 pairIndex; pairIndex < pairsCount; ) {
            transferPriceImpactOiForPair(
                pairIndex,
                prevCurrentWindowId,
                prevEarliestWindowId,
                _prevPairOiWindows[pairIndex],
                _newPairOiWindows[pairIndex][newCurrentWindowId]
            );

            unchecked {
                ++pairIndex;
            }
        }

        emit PriceImpactOiTransferredPairs(pairsCount, prevCurrentWindowId, prevEarliestWindowId, newCurrentWindowId);
    }

    /**
     * @dev Transfers total long / short OI from `prevEarliestWindowId` to `prevCurrentWindowId` windows of
     * `_prevPairOiWindows` to `_newPairOiWindow` window.
     *
     * Emits a {PriceImpactOiTransferredPair} event.
     */
    function transferPriceImpactOiForPair(
        uint256 pairIndex,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        mapping(uint256 => PairOi) storage _prevPairOiWindows,
        PairOi storage _newPairOiWindow
    ) private {
        PairOi memory totalPairOi;

        // Aggregate sum of total long / short OI for past windows
        for (uint256 id = prevEarliestWindowId; id <= prevCurrentWindowId; ) {
            PairOi memory pairOi = _prevPairOiWindows[id];

            totalPairOi.long += pairOi.long;
            totalPairOi.short += pairOi.short;

            // Clean up previous map once added to the sum
            delete _prevPairOiWindows[id];

            unchecked {
                ++id;
            }
        }

        bool longOiTransfer = totalPairOi.long > 0;
        bool shortOiTransfer = totalPairOi.short > 0;

        if (longOiTransfer) {
            _newPairOiWindow.long += totalPairOi.long;
        }

        if (shortOiTransfer) {
            _newPairOiWindow.short += totalPairOi.short;
        }

        // Only emit even if there was an actual OI transfer
        if (longOiTransfer || shortOiTransfer) {
            emit PriceImpactOiTransferredPair(pairIndex, totalPairOi);
        }
    }

    /**
     * @dev Returns window id at `_timestamp` given `_settings`.
     */
    function getWindowId(uint48 _timestamp, OiWindowsSettings memory _settings) internal pure returns (uint256) {
        return (_timestamp - _settings.startTs) / _settings.windowsDuration;
    }

    /**
     * @dev Returns window id at current timestamp given `_settings`.
     */
    function getCurrentWindowId(OiWindowsSettings memory _settings) internal view returns (uint256) {
        return getWindowId(uint48(block.timestamp), _settings);
    }

    /**
     * @dev Returns earliest active window id given `_currentWindowId` and `_windowsCount`.
     */
    function getEarliestActiveWindowId(uint256 _currentWindowId, uint48 _windowsCount) internal pure returns (uint256) {
        uint256 windowNegativeDelta = _windowsCount - 1; // -1 because we include current window
        return _currentWindowId > windowNegativeDelta ? _currentWindowId - windowNegativeDelta : 0;
    }

    /**
     * @dev Returns whether '_windowId' can be potentially active id given `_currentWindowId`
     */
    function isWindowPotentiallyActive(uint256 _windowId, uint256 _currentWindowId) internal pure returns (bool) {
        return _currentWindowId - _windowId < MAX_WINDOWS_COUNT;
    }

    /**
     * @dev Returns total long / short OI `activeOi`, from last active windows of `_pairOiWindows`
     * given `_settings` (backwards-compatible).
     */
    function getPriceImpactOi(
        uint256 _pairIndex,
        bool _long,
        IGNSTradingStorage _previousOiContract
    ) external view returns (uint256 activeOi) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        // Return raw OI if windowsCount is explicitly 0 (= previous behavior)
        if (settings.windowsCount == 0) {
            return _previousOiContract.openInterestDai(_pairIndex, _long ? 0 : 1);
        }

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 earliestWindowId = getEarliestActiveWindowId(currentWindowId, settings.windowsCount);

        for (uint256 i = earliestWindowId; i <= currentWindowId; ) {
            PairOi memory _pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][i];
            activeOi += _long ? _pairOi.long : _pairOi.short;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns trade price impact % and opening price after impact.
     */
    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        bool _long,
        uint256 _startOpenInterest, // 1e18 (DAI)
        uint256 _tradeOpenInterest, // 1e18 (DAI)
        uint256 _onePercentDepth
    )
        external
        pure
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        if (_onePercentDepth == 0) {
            return (0, _openPrice);
        }

        priceImpactP = ((_startOpenInterest + _tradeOpenInterest / 2) * PRECISION) / _onePercentDepth / 1e18;

        uint256 priceImpact = (priceImpactP * _openPrice) / PRECISION / 100;
        priceAfterImpact = _long ? _openPrice + priceImpact : _openPrice - priceImpact;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage storage slots used by our external libraries.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT = 7;
}