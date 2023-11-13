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

import "../interfaces/IGNSTradingCallbacks.sol";

/**
 * @custom:version 6.4.2
 */
library TradeUtils {
    function _getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type
    )
        internal
        view
        returns (
            IGNSTradingCallbacks,
            IGNSTradingCallbacks.LastUpdated memory,
            IGNSTradingCallbacks.SimplifiedTradeId memory
        )
    {
        IGNSTradingCallbacks callbacks = IGNSTradingCallbacks(_callbacks);
        IGNSTradingCallbacks.LastUpdated memory l = callbacks.getTradeLastUpdated(trader, pairIndex, index, _type);

        return (callbacks, l, IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, _type));
    }

    function setTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        uint32 b = uint32(blockNumber);
        IGNSTradingCallbacks callbacks = IGNSTradingCallbacks(_callbacks);
        callbacks.setTradeLastUpdated(
            IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, _type),
            IGNSTradingCallbacks.LastUpdated(b, b, b, b)
        );
    }

    function setSlLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            IGNSTradingCallbacks callbacks,
            IGNSTradingCallbacks.LastUpdated memory l,
            IGNSTradingCallbacks.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.sl = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTpLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            IGNSTradingCallbacks callbacks,
            IGNSTradingCallbacks.LastUpdated memory l,
            IGNSTradingCallbacks.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.tp = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setLimitMaxSlippageP(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 maxSlippageP
    ) external {
        require(maxSlippageP <= type(uint40).max, "OVERFLOW");
        IGNSTradingCallbacks(_callbacks).setTradeData(
            IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, IGNSTradingCallbacks.TradeType.LIMIT),
            IGNSTradingCallbacks.TradeData(uint40(maxSlippageP), 0, 0)
        );
    }
}