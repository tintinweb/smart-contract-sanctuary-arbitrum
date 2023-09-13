// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ChainlinkFeedInterfaceV5 {
    function latestRoundData() external view returns (uint80, int, uint, uint, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSBorrowingFeesInterfaceV6_4 {
    // Structs
    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; // 1e10 (%)
        uint64 initialAccFeeShort; // 1e10 (%)
        uint64 prevGroupAccFeeLong; // 1e10 (%)
        uint64 prevGroupAccFeeShort; // 1e10 (%)
        uint64 pairAccFeeLong; // 1e10 (%)
        uint64 pairAccFeeShort; // 1e10 (%)
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint48 feeExponent;
        uint lastAccBlockWeightedMarketCap; // 1e40
    }
    struct PairOi {
        uint72 long; // 1e10 (DAI)
        uint72 short; // 1e10 (DAI)
        uint72 max; // 1e10 (DAI)
        uint40 _placeholder; // might be useful later
    }
    struct Group {
        uint112 oiLong; // 1e10
        uint112 oiShort; // 1e10
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint80 maxOi; // 1e10
        uint lastAccBlockWeightedMarketCap; // 1e40
    }
    struct InitialAccFees {
        uint64 accPairFee; // 1e10 (%)
        uint64 accGroupFee; // 1e10 (%)
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; // 1e10 (%)
        uint48 feeExponent;
        uint72 maxOi;
    }
    struct GroupParams {
        uint32 feePerBlock; // 1e10 (%)
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }
    struct BorrowingFeeInput {
        address trader;
        uint pairIndex;
        uint index;
        bool long;
        uint collateral; // 1e18 (DAI)
        uint leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice; // 1e10
        bool long;
        uint collateral; // 1e18 (DAI)
        uint leverage;
    }
    struct PendingAccFeesInput {
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint oiLong; // 1e18
        uint oiShort; // 1e18
        uint32 feePerBlock; // 1e10
        uint currentBlock;
        uint accLastUpdatedBlock;
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }

    // Events
    event PairParamsUpdated(
        uint indexed pairIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint48 feeExponent,
        uint72 maxOi
    );
    event PairGroupUpdated(uint indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint72 maxOi, uint48 feeExponent);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        bool open,
        bool long,
        uint positionSizeDai // 1e18
    );
    event PairAccFeesUpdated(uint indexed pairIndex, uint currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupAccFeesUpdated(uint16 indexed groupIndex, uint currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    // Functions
    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint); // PRECISION

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint); // 1e18 (DAI)

    function handleTradeAction(
        address trader,
        uint pairIndex,
        uint index,
        uint positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint pairIndex, bool long, uint positionSizeDai) external view returns (bool);

    function getPairMaxOi(uint pairIndex) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSPairInfosInterfaceV6 {
    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // 1e18 (DAI)
        int funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    function tradeInitialAccFees(address, uint, uint) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(address trader, uint pairIndex, uint index, bool long) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // 1e18 (DAI)
    ) external view returns (uint);

    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    )
        external
        view
        returns (
            int // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        uint rolloverFee, // 1e18 (DAI)
        int fundingFee // 1e18 (DAI)
    ) external pure returns (uint);

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (DAI)
    ) external returns (uint); // 1e18 (DAI)

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSReferralsInterfaceV6_2 {
    function registerPotentialReferrer(address trader, address referral) external;

    function distributePotentialReward(
        address trader,
        uint volumeDai,
        uint pairOpenFeeP,
        uint tokenPriceDai
    ) external returns (uint);

    function getPercentOfOpenFeeP(address trader) external view returns (uint);

    function getTraderReferrer(address trader) external view returns (address referrer);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns (uint);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint indexed uniqueId,
        uint indexed batchNumber,
        uint indexInBatch,
        uint arbBlockNum,
        uint ethBlockNum,
        uint timestamp,
        uint callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT

import {StorageInterfaceV5} from "./StorageInterfaceV5.sol";

pragma solidity 0.8.17;

interface IGNSOracleRewardsV6_4_1 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterfaceV5.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeTrigger(TriggeredLimitId calldata) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeOracleReward(TriggeredLimitId calldata, uint) external;

    function openLimitOrderTypes(address, uint, uint) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGToken {
    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(uint prevPositiveOpenPnl, uint newPositiveOpenPnl) external returns (uint);

    struct LockedDeposit {
        address owner;
        uint shares; // 1e18
        uint assetsDeposited; // 1e18
        uint assetsDiscount; // 1e18
        uint atTimestamp; // timestamp
        uint lockDuration; // timestamp
    }

    function getLockedDeposit(uint depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceDai() external view returns (uint);

    function tvl() external view returns (uint);

    function marketCap() external view returns (uint);

    function getPendingAccBlockWeightedMarketCap(uint currentBlock) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface PairsStorageInterfaceV6 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(uint) external returns (string memory, string memory, bytes32, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairSpreadP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupMaxCollateral(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosDai(uint) external view returns (uint);

    function pairsCount() external view returns (uint);
}

// SPDX-License-Identifier: MIT
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./IGToken.sol";
import "./PairsStorageInterfaceV6.sol";
import "./ChainlinkFeedInterfaceV5.sol";

pragma solidity 0.8.17;

interface PoolInterfaceV5 {
    function increaseAccTokensPerLp(uint) external;
}

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface StorageInterfaceV5 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeDai; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceDai; // PRECISION
        uint openInterestDai; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (TokenInterfaceV5);

    function token() external view returns (TokenInterfaceV5);

    function linkErc677() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_4);

    function vault() external view returns (IGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferDai(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(address, uint, uint) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;

    function openTrades(address, uint, uint) external view returns (Trade memory);

    function openTradesInfo(address, uint, uint) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(address, uint, uint) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(address, uint) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(uint) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(address, uint) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestDai(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface IStateCopyUtils {
    function getOpenLimitOrders() external view returns (StorageInterfaceV5.OpenLimitOrder[] memory);

    function nftRewards() external view returns (NftRewardsInterfaceV6_3_1);
}

interface NftRewardsInterfaceV6_3_1 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterfaceV5.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address, uint) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint, uint) external;

    function openLimitOrderTypes(address, uint, uint) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);

    function botInUse(bytes32) external view returns (bool);

    function getNftBotHashes(uint, address, uint, address, uint, uint) external pure returns (bytes32, bytes32);

    function setNftBotInUse(bytes32, bytes32) external;

    function nftBotInUse(bytes32, bytes32) external view returns (bool);

    function linkToTokenRewards(uint, uint) external view returns (uint);
}

interface AggregatorInterfaceV6_4 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);

    function getPrice(uint, OrderType, uint, uint) external returns (uint);

    function tokenPriceDai() external returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function linkPriceFeed() external view returns (ChainlinkFeedInterfaceV5);

    function nodes(uint index) external view returns (address);
}

interface TradingCallbacksV6_4 {
    enum TradeType {
        MARKET,
        LIMIT
    }
    struct SimplifiedTradeId {
        address trader;
        uint pairIndex;
        uint index;
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
        uint216 _placeholder; // for potential future data
    }

    function tradeLastUpdated(address, uint, uint, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint blockNumber) internal pure returns (uint48) {
        require(blockNumber <= type(uint48).max, "OVERFLOW");
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library PackingUtils {
    function pack(uint256[] memory values, uint256[] memory bitLengths) external pure returns (uint256 packed) {
        require(values.length == bitLengths.length, "Mismatch in the lengths of values and bitLengths arrays");

        uint256 currentShift;

        for (uint256 i; i < values.length; i++) {
            require(currentShift + bitLengths[i] <= 256, "Packed value exceeds 256 bits");

            uint256 maxValue = (1 << bitLengths[i]) - 1;
            require(values[i] <= maxValue, "Value too large for specified bit length");

            uint256 maskedValue = values[i] & maxValue;
            packed |= maskedValue << currentShift;
            currentShift += bitLengths[i];
        }
    }

    function unpack(uint256 packed, uint256[] memory bitLengths) external pure returns (uint256[] memory values) {
        values = new uint256[](bitLengths.length);

        uint256 currentShift;
        for (uint256 i; i < bitLengths.length; i++) {
            require(currentShift + bitLengths[i] <= 256, "Unpacked value exceeds 256 bits");

            uint256 maxValue = (1 << bitLengths[i]) - 1;
            uint256 mask = maxValue << currentShift;
            values[i] = (packed & mask) >> currentShift;

            currentShift += bitLengths[i];
        }
    }

    function unpack256To64(uint256 packed) external pure returns (uint64 a, uint64 b, uint64 c, uint64 d) {
        a = uint64(packed);
        b = uint64(packed >> 64);
        c = uint64(packed >> 128);
        d = uint64(packed >> 192);
    }

    // Function-specific unpacking utils
    function unpackExecuteNftOrder(
        uint256 packed
    ) external pure returns (uint256 a, address b, uint256 c, uint256 d, uint256 e, uint256 f) {
        a = packed & 0xFF; // 8 bits
        b = address(uint160(packed >> 8)); // 160 bits
        c = (packed >> 168) & 0xFFFF; // 16 bits
        d = (packed >> 184) & 0xFFFF; // 16 bits
        e = (packed >> 200) & 0xFFFF; // 16 bits
        f = (packed >> 216) & 0xFFFF; // 16 bits
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/StorageInterfaceV5.sol";

library TradeUtils {
    function _getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType _type
    )
        internal
        view
        returns (
            TradingCallbacksV6_4,
            TradingCallbacksV6_4.LastUpdated memory,
            TradingCallbacksV6_4.SimplifiedTradeId memory
        )
    {
        TradingCallbacksV6_4 callbacks = TradingCallbacksV6_4(_callbacks);
        TradingCallbacksV6_4.LastUpdated memory l = callbacks.tradeLastUpdated(trader, pairIndex, index, _type);

        return (callbacks, l, TradingCallbacksV6_4.SimplifiedTradeId(trader, pairIndex, index, _type));
    }

    function setTradeLastUpdated(
        address _callbacks,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType _type,
        uint blockNumber
    ) external {
        uint32 b = uint32(blockNumber);
        TradingCallbacksV6_4 callbacks = TradingCallbacksV6_4(_callbacks);
        callbacks.setTradeLastUpdated(
            TradingCallbacksV6_4.SimplifiedTradeId(trader, pairIndex, index, _type),
            TradingCallbacksV6_4.LastUpdated(b, b, b, b)
        );
    }

    function setSlLastUpdated(
        address _callbacks,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType _type,
        uint blockNumber
    ) external {
        (
            TradingCallbacksV6_4 callbacks,
            TradingCallbacksV6_4.LastUpdated memory l,
            TradingCallbacksV6_4.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.sl = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTpLastUpdated(
        address _callbacks,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType _type,
        uint blockNumber
    ) external {
        (
            TradingCallbacksV6_4 callbacks,
            TradingCallbacksV6_4.LastUpdated memory l,
            TradingCallbacksV6_4.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.tp = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTradeData(
        address _callbacks,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType _type,
        uint maxSlippageP
    ) external {
        require(maxSlippageP <= type(uint40).max, "OVERFLOW");
        TradingCallbacksV6_4 callbacks = TradingCallbacksV6_4(_callbacks);
        callbacks.setTradeData(
            TradingCallbacksV6_4.SimplifiedTradeId(trader, pairIndex, index, _type),
            TradingCallbacksV6_4.TradeData(uint40(maxSlippageP), 0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Delegatable {
    mapping(address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(address trader, bytes calldata call_data) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(call_data);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }

    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/StorageInterfaceV5.sol";
import "../interfaces/GNSPairInfosInterfaceV6.sol";
import "../interfaces/GNSReferralsInterfaceV6_2.sol";
import "../interfaces/GNSBorrowingFeesInterfaceV6_4.sol";
import "../interfaces/IGNSOracleRewardsV6_4_1.sol";
import "../v6.2/Delegatable.sol";
import "../libraries/ChainUtils.sol";
import "../libraries/TradeUtils.sol";
import "../libraries/PackingUtils.sol";

contract GNSTradingV6_4_1 is Delegatable {
    using TradeUtils for address;
    using PackingUtils for uint256;

    // Contracts (constant)
    StorageInterfaceV5 public immutable storageT;
    IGNSOracleRewardsV6_4_1 public immutable oracleRewards;
    GNSPairInfosInterfaceV6 public immutable pairInfos;
    GNSReferralsInterfaceV6_2 public immutable referrals;
    GNSBorrowingFeesInterfaceV6_4 public immutable borrowingFees;

    // Params (constant)
    uint private constant PRECISION = 1e10;
    uint private constant MAX_SL_P = 75; // -75% PNL

    // Params (adjustable)
    uint public maxPosDai; // 1e18 (eg. 75000 * 1e18)
    uint public marketOrdersTimeout; // block (eg. 30)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    mapping(address => bool) public bypassTriggerLink; // Doesn't have to pay link in executeNftOrder()

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint value);
    event BypassTriggerLinkUpdated(address user, bool bypass);

    event MarketOrderInitiated(uint indexed orderId, address indexed trader, uint indexed pairIndex, bool open);

    event OpenLimitPlaced(address indexed trader, uint indexed pairIndex, uint index);
    event OpenLimitUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newPrice,
        uint newTp,
        uint newSl,
        uint maxSlippageP
    );
    event OpenLimitCanceled(address indexed trader, uint indexed pairIndex, uint index);

    event TpUpdated(address indexed trader, uint indexed pairIndex, uint index, uint newTp);
    event SlUpdated(address indexed trader, uint indexed pairIndex, uint index, uint newSl);

    event NftOrderInitiated(uint orderId, address indexed trader, uint indexed pairIndex, bool byPassesLinkCost);

    event ChainlinkCallbackTimeout(uint indexed orderId, StorageInterfaceV5.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint indexed pairIndex, uint index);

    constructor(
        StorageInterfaceV5 _storageT,
        IGNSOracleRewardsV6_4_1 _oracleRewards,
        GNSPairInfosInterfaceV6 _pairInfos,
        GNSReferralsInterfaceV6_2 _referrals,
        GNSBorrowingFeesInterfaceV6_4 _borrowingFees,
        uint _maxPosDai,
        uint _marketOrdersTimeout
    ) {
        require(
            address(_storageT) != address(0) &&
                address(_oracleRewards) != address(0) &&
                address(_pairInfos) != address(0) &&
                address(_referrals) != address(0) &&
                address(_borrowingFees) != address(0) &&
                _maxPosDai > 0 &&
                _marketOrdersTimeout > 0,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        oracleRewards = _oracleRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;
        borrowingFees = _borrowingFees;

        maxPosDai = _maxPosDai;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract() {
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone() {
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosDai(uint value) external onlyGov {
        require(value > 0, "VALUE_0");
        maxPosDai = value;
        emit NumberUpdated("maxPosDai", value);
    }

    function setMarketOrdersTimeout(uint value) external onlyGov {
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    function setBypassTriggerLink(address user, bool bypass) external onlyGov {
        bypassTriggerLink[user] = bypass;

        emit BypassTriggerLinkUpdated(user, bypass);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;
        emit Paused(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;
        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        IGNSOracleRewardsV6_4_1.OpenLimitOrderType orderType, // LEGACY => market
        uint slippageP, // 1e10 (%)
        address referrer
    ) external notContract notDone {
        require(!isPaused, "PAUSED");
        require(t.openPrice * slippageP < type(uint256).max, "OVERFLOW");
        require(t.openPrice > 0, "PRICE_ZERO");

        AggregatorInterfaceV6_4 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        address sender = _msgSender();

        require(
            storageT.openTradesCount(sender, t.pairIndex) +
                storageT.pendingMarketOpenCount(sender, t.pairIndex) +
                storageT.openLimitOrdersCount(sender, t.pairIndex) <
                storageT.maxTradesPerPair(),
            "MAX_TRADES_PER_PAIR"
        );

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");
        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");
        require(t.positionSizeDai * t.leverage >= pairsStored.pairMinLevPosDai(t.pairIndex), "BELOW_MIN_POS");

        require(
            t.leverage > 0 &&
                t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) &&
                t.leverage <= _pairMaxLeverage(pairsStored, t.pairIndex),
            "LEVERAGE_INCORRECT"
        );

        require(t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice), "WRONG_TP");
        require(t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice), "WRONG_SL");

        (uint priceImpactP, ) = pairInfos.getTradePriceImpact(0, t.pairIndex, t.buy, t.positionSizeDai * t.leverage);
        require(priceImpactP * t.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

        storageT.transferDai(sender, address(storageT), t.positionSizeDai);

        if (orderType != IGNSOracleRewardsV6_4_1.OpenLimitOrderType.LEGACY) {
            uint index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                StorageInterfaceV5.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeDai,
                    0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            oracleRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);

            address c = storageT.callbacks();
            c.setTradeLastUpdated(
                sender,
                t.pairIndex,
                index,
                TradingCallbacksV6_4.TradeType.LIMIT,
                ChainUtils.getBlockNumber()
            );
            c.setTradeData(sender, t.pairIndex, index, TradingCallbacksV6_4.TradeType.LIMIT, slippageP);

            emit OpenLimitPlaced(sender, t.pairIndex, index);
        } else {
            uint orderId = aggregator.getPrice(
                t.pairIndex,
                AggregatorInterfaceV6_4.OrderType.MARKET_OPEN,
                t.positionSizeDai * t.leverage,
                ChainUtils.getBlockNumber()
            );

            storageT.storePendingMarketOrder(
                StorageInterfaceV5.PendingMarketOrder(
                    StorageInterfaceV5.Trade(
                        sender,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeDai,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    0,
                    0
                ),
                orderId,
                true
            );

            emit MarketOrderInitiated(orderId, sender, t.pairIndex, true);
        }

        referrals.registerPotentialReferrer(sender, referrer);
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint pairIndex, uint index) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(sender, pairIndex, index);

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");
        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            AggregatorInterfaceV6_4.OrderType.MARKET_CLOSE,
            (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION,
            ChainUtils.getBlockNumber()
        );

        storageT.storePendingMarketOrder(
            StorageInterfaceV5.PendingMarketOrder(
                StorageInterfaceV5.Trade(sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0),
                0,
                0,
                0,
                0,
                0
            ),
            orderId,
            false
        );

        emit MarketOrderInitiated(orderId, sender, pairIndex, false);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex,
        uint index,
        uint price, // PRECISION
        uint tp,
        uint sl,
        uint maxSlippageP
    ) external notContract notDone {
        require(price > 0, "PRICE_ZERO");

        address sender = _msgSender();
        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        require(tp == 0 || (o.buy ? tp > price : tp < price), "WRONG_TP");
        require(sl == 0 || (o.buy ? sl < price : sl > price), "WRONG_SL");

        require(price * maxSlippageP < type(uint256).max, "OVERFLOW");

        _checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.OPEN);

        o.minPrice = price;
        o.maxPrice = price;
        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        address c = storageT.callbacks();
        c.setTradeLastUpdated(
            sender,
            pairIndex,
            index,
            TradingCallbacksV6_4.TradeType.LIMIT,
            ChainUtils.getBlockNumber()
        );
        c.setTradeData(sender, pairIndex, index, TradingCallbacksV6_4.TradeType.LIMIT, maxSlippageP);

        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl, maxSlippageP);
    }

    function cancelOpenLimitOrder(uint pairIndex, uint index) external notContract notDone {
        address sender = _msgSender();
        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        _checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.OPEN);

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferDai(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(uint pairIndex, uint index, uint newTp) external notContract notDone {
        address sender = _msgSender();

        _checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.TP);

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        require(t.leverage > 0, "NO_TRADE");

        storageT.updateTp(sender, pairIndex, index, newTp);
        storageT.callbacks().setTpLastUpdated(
            sender,
            pairIndex,
            index,
            TradingCallbacksV6_4.TradeType.MARKET,
            ChainUtils.getBlockNumber()
        );

        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function updateSl(uint pairIndex, uint index, uint newSl) external notContract notDone {
        address sender = _msgSender();

        _checkNoPendingTrigger(sender, pairIndex, index, StorageInterfaceV5.LimitOrder.SL);

        StorageInterfaceV5.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = (t.openPrice * MAX_SL_P) / 100 / t.leverage;

        require(
            newSl == 0 || (t.buy ? newSl >= t.openPrice - maxSlDist : newSl <= t.openPrice + maxSlDist),
            "SL_TOO_BIG"
        );

        storageT.updateSl(sender, pairIndex, index, newSl);
        storageT.callbacks().setSlLastUpdated(
            sender,
            pairIndex,
            index,
            TradingCallbacksV6_4.TradeType.MARKET,
            ChainUtils.getBlockNumber()
        );

        emit SlUpdated(sender, pairIndex, index, newSl);
    }

    // Execute limit order
    function executeNftOrder(uint256 packed) external notContract notDone {
        (uint _orderType, address trader, uint pairIndex, uint index, , ) = packed.unpackExecuteNftOrder();

        StorageInterfaceV5.LimitOrder orderType = StorageInterfaceV5.LimitOrder(_orderType);
        IGNSOracleRewardsV6_4_1.TriggeredLimitId memory triggeredLimitId = _checkNoPendingTrigger(
            trader,
            pairIndex,
            index,
            orderType
        );

        StorageInterfaceV5.Trade memory t;
        bool isOpenLimit = orderType == StorageInterfaceV5.LimitOrder.OPEN;

        if (isOpenLimit) {
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index), "NO_LIMIT");
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if (orderType == StorageInterfaceV5.LimitOrder.LIQ) {
                if (t.sl > 0) {
                    uint liqPrice = borrowingFees.getTradeLiquidationPrice(
                        GNSBorrowingFeesInterfaceV6_4.LiqPriceInput(
                            t.trader,
                            t.pairIndex,
                            t.index,
                            t.openPrice,
                            t.buy,
                            (t.initialPosToken *
                                storageT.openTradesInfo(t.trader, t.pairIndex, t.index).tokenPriceDai) / PRECISION,
                            t.leverage
                        )
                    );

                    require(t.buy ? liqPrice > t.sl : liqPrice < t.sl, "HAS_SL");
                }
            } else {
                require(orderType != StorageInterfaceV5.LimitOrder.SL || t.sl > 0, "NO_SL");
                require(orderType != StorageInterfaceV5.LimitOrder.TP || t.tp > 0, "NO_TP");
            }
        }

        address sender = _msgSender();
        bool byPassesLinkCost = bypassTriggerLink[sender];

        uint leveragedPosDai;

        if (isOpenLimit) {
            StorageInterfaceV5.OpenLimitOrder memory l = storageT.getOpenLimitOrder(trader, pairIndex, index);

            uint _leveragedPosDai = l.positionSize * l.leverage;
            (uint priceImpactP, ) = pairInfos.getTradePriceImpact(0, l.pairIndex, l.buy, _leveragedPosDai);

            require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

            if (!byPassesLinkCost) {
                leveragedPosDai = _leveragedPosDai;
            }
        } else if (!byPassesLinkCost) {
            leveragedPosDai =
                (t.initialPosToken * storageT.openTradesInfo(trader, pairIndex, index).tokenPriceDai * t.leverage) /
                PRECISION;
        }

        if (leveragedPosDai > 0) {
            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosDai);
        }

        uint orderId = _getPriceNftOrder(
            isOpenLimit,
            trader,
            pairIndex,
            index,
            isOpenLimit ? TradingCallbacksV6_4.TradeType.LIMIT : TradingCallbacksV6_4.TradeType.MARKET,
            orderType,
            leveragedPosDai
        );

        StorageInterfaceV5.PendingNftOrder memory pendingNftOrder;
        pendingNftOrder.nftHolder = sender;
        pendingNftOrder.nftId = 0;
        pendingNftOrder.trader = trader;
        pendingNftOrder.pairIndex = pairIndex;
        pendingNftOrder.index = index;
        pendingNftOrder.orderType = orderType;

        storageT.storePendingNftOrder(pendingNftOrder, orderId);
        oracleRewards.storeTrigger(triggeredLimitId);

        emit NftOrderInitiated(orderId, trader, pairIndex, byPassesLinkCost);
    }

    // Market timeout
    function openTradeMarketTimeout(uint _order) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");
        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferDai(address(storageT), sender, t.positionSizeDai);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function closeTradeMarketTimeout(uint _order) external notContract notDone {
        address sender = _msgSender();

        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        StorageInterfaceV5.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");
        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("closeTradeMarket(uint256,uint256)", t.pairIndex, t.index)
        );

        if (!success) {
            emit CouldNotCloseTrade(sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }

    // Helpers (private)
    function _checkNoPendingTrigger(
        address trader,
        uint pairIndex,
        uint index,
        StorageInterfaceV5.LimitOrder orderType
    ) private view returns (IGNSOracleRewardsV6_4_1.TriggeredLimitId memory triggeredLimitId) {
        triggeredLimitId = IGNSOracleRewardsV6_4_1.TriggeredLimitId(trader, pairIndex, index, orderType);
        require(
            !oracleRewards.triggered(triggeredLimitId) || oracleRewards.timedOut(triggeredLimitId),
            "PENDING_TRIGGER"
        );
    }

    function _pairMaxLeverage(PairsStorageInterfaceV6 pairsStored, uint pairIndex) private view returns (uint) {
        uint max = TradingCallbacksV6_4(storageT.callbacks()).pairMaxLeverage(pairIndex);
        return max > 0 ? max : pairsStored.pairMaxLeverage(pairIndex);
    }

    function _getPriceNftOrder(
        bool isOpenLimit,
        address trader,
        uint pairIndex,
        uint index,
        TradingCallbacksV6_4.TradeType tradeType,
        StorageInterfaceV5.LimitOrder orderType,
        uint leveragedPosDai
    ) private returns (uint orderId) {
        TradingCallbacksV6_4.LastUpdated memory lastUpdated = TradingCallbacksV6_4(storageT.callbacks())
            .tradeLastUpdated(trader, pairIndex, index, tradeType);

        AggregatorInterfaceV6_4 aggregator = storageT.priceAggregator();

        orderId = aggregator.getPrice(
            pairIndex,
            isOpenLimit ? AggregatorInterfaceV6_4.OrderType.LIMIT_OPEN : AggregatorInterfaceV6_4.OrderType.LIMIT_CLOSE,
            leveragedPosDai,
            isOpenLimit ? lastUpdated.limit : orderType == StorageInterfaceV5.LimitOrder.SL
                ? lastUpdated.sl
                : orderType == StorageInterfaceV5.LimitOrder.TP
                ? lastUpdated.tp
                : lastUpdated.created
        );
    }
}