// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../interfaces/StorageInterfaceV5.sol";

contract MTTNftRewards {
    // Contracts (constant)
    StorageInterfaceV5 immutable storageT;

    // Params (constant)
    uint256 constant ROUND_LENGTH = 50;

    // Params (adjustable)
    uint256 public triggerTimeout = 30; // blocks
    uint256 public sameBlockLimit = 10; // bots

    uint256 public firstP = 40; // %
    uint256 public sameBlockP = 20; // %
    uint256 public poolP = 40; // %

    // Custom data types
    struct TriggeredLimit {
        address first;
        address[] sameBlock;
        uint256 block;
    }
    struct TriggeredLimitId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        StorageInterfaceV5.LimitOrder order;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    // State
    uint256 public currentOrder = 1; // current order in round
    uint256 public currentRound; // current round (1 round = 50 orders)

    mapping(uint256 => uint256) public roundTokens; // total token rewards for a round
    mapping(address => mapping(uint256 => uint256)) public roundOrdersToClaim; // orders to claim from a round (out of 50)

    mapping(address => uint256) public tokensToClaim; // rewards other than pool (first & same block)

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(StorageInterfaceV5.LimitOrder => TriggeredLimit))))
        public triggeredLimits; // limits being triggered

    mapping(address => mapping(uint256 => mapping(uint256 => OpenLimitOrderType)))
        public openLimitOrderTypes;

    // Statistics
    mapping(address => uint256) public tokensClaimed; // 1e18
    uint256 public tokensClaimedTotal; // 1e18

    // Events
    event NumberUpdated(string name, uint256 value);
    event PercentagesUpdated(uint256 firstP, uint256 sameBlockP, uint256 poolP);

    event TriggeredFirst(TriggeredLimitId id, address bot);
    event TriggeredSameBlock(TriggeredLimitId id, address bot);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(
        TriggeredLimitId id,
        address first,
        uint256 sameBlockCount,
        uint256 reward
    );

    event PoolTokensClaimed(
        address bot,
        uint256 fromRound,
        uint256 toRound,
        uint256 tokens
    );
    event TokensClaimed(address bot, uint256 tokens);

    constructor(StorageInterfaceV5 _storageT) {
        storageT = _storageT;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Manage params
    function updateTriggerTimeout(uint256 _triggerTimeout) external onlyGov {
        require(_triggerTimeout >= 5, "LESS_THAN_5");
        triggerTimeout = _triggerTimeout;
        emit NumberUpdated("triggerTimeout", _triggerTimeout);
    }

    function updateSameBlockLimit(uint256 _sameBlockLimit) external onlyGov {
        require(_sameBlockLimit >= 5, "LESS_THAN_5");
        sameBlockLimit = _sameBlockLimit;
        emit NumberUpdated("sameBlockLimit", _sameBlockLimit);
    }

    function updatePercentages(
        uint256 _firstP,
        uint256 _sameBlockP,
        uint256 _poolP
    ) external onlyGov {
        require(_firstP + _sameBlockP + _poolP == 100, "SUM_NOT_100");

        firstP = _firstP;
        sameBlockP = _sameBlockP;
        poolP = _poolP;

        emit PercentagesUpdated(_firstP, _sameBlockP, _poolP);
    }

    // Triggers
    function storeFirstToTrigger(TriggeredLimitId calldata _id, address _bot)
        external
        onlyTrading
    {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];

        t.first = _bot;
        delete t.sameBlock;
        t.block = block.number;

        emit TriggeredFirst(_id, _bot);
    }

    function storeTriggerSameBlock(TriggeredLimitId calldata _id, address _bot)
        external
        onlyTrading
    {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];

        require(t.block == block.number, "TOO_LATE");
        require(t.sameBlock.length < sameBlockLimit, "SAME_BLOCK_LIMIT");

        t.sameBlock.push(_bot);

        emit TriggeredSameBlock(_id, _bot);
    }

    function unregisterTrigger(TriggeredLimitId calldata _id)
        external
        onlyCallbacks
    {
        delete triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        emit TriggerUnregistered(_id);
    }

    // Distribute rewards
    function distributeNftReward(TriggeredLimitId calldata _id, uint256 _reward)
        external
        onlyCallbacks
    {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];

        require(t.block > 0, "NOT_TRIGGERED");

        tokensToClaim[t.first] += (_reward * firstP) / 100;

        if (t.sameBlock.length > 0) {
            uint256 sameBlockReward = (_reward * sameBlockP) /
                t.sameBlock.length /
                100;
            for (uint256 i = 0; i < t.sameBlock.length; i++) {
                tokensToClaim[t.sameBlock[i]] += sameBlockReward;
            }
        }

        roundTokens[currentRound] += (_reward * poolP) / 100;
        roundOrdersToClaim[t.first][currentRound]++;

        if (currentOrder == ROUND_LENGTH) {
            currentOrder = 1;
            currentRound++;
        } else {
            currentOrder++;
        }

        emit TriggerRewarded(_id, t.first, t.sameBlock.length, _reward);
    }

    // Claim rewards
    function claimPoolTokens(uint256 _fromRound, uint256 _toRound) external {
        require(_toRound >= _fromRound, "TO_BEFORE_FROM");
        require(_toRound < currentRound, "TOO_EARLY");

        uint256 tokens;

        for (uint256 i = _fromRound; i <= _toRound; i++) {
            tokens +=
                (roundOrdersToClaim[msg.sender][i] * roundTokens[i]) /
                ROUND_LENGTH;
            roundOrdersToClaim[msg.sender][i] = 0;
        }

        require(tokens > 0, "NOTHING_TO_CLAIM");
        //change to method bot get reward from MMT to usdc
        //storageT.handleTokens(msg.sender, tokens, true);
        storageT.transferDai(address(storageT), msg.sender, tokens);

        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;

        emit PoolTokensClaimed(msg.sender, _fromRound, _toRound, tokens);
    }

    function claimTokens() external {
        uint256 tokens = tokensToClaim[msg.sender];
        require(tokens > 0, "NOTHING_TO_CLAIM");

        tokensToClaim[msg.sender] = 0;
        //change to method bot get reward from MMT to usdc
        //storageT.handleTokens(msg.sender, tokens, true);
        storageT.transferDai(address(storageT), msg.sender, tokens);
        tokensClaimed[msg.sender] += tokens;
        tokensClaimedTotal += tokens;

        emit TokensClaimed(msg.sender, tokens);
    }

    // Manage open limit order types
    function setOpenLimitOrderType(
        address _trader,
        uint256 _pairIndex,
        uint256 _index,
        OpenLimitOrderType _type
    ) external onlyTrading {
        openLimitOrderTypes[_trader][_pairIndex][_index] = _type;
    }

    // Getters
    function triggered(TriggeredLimitId calldata _id)
        external
        view
        returns (bool)
    {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];
        return t.block > 0;
    }

    function timedOut(TriggeredLimitId calldata _id)
        external
        view
        returns (bool)
    {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];
        return t.block > 0 && block.number - t.block >= triggerTimeout;
    }

    function sameBlockTriggers(TriggeredLimitId calldata _id)
        external
        view
        returns (address[] memory)
    {
        return
            triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order]
                .sameBlock;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./NftRewardsInterfaceV6.sol";
import "./PairsStorageInterfaceV6.sol";

interface AggregatorInterfaceV6 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);

    function nftRewards() external view returns (NftRewardsInterfaceV6);

    function getPrice(
        uint256,
        OrderType,
        uint256
    ) external returns (uint256);

    function tokenPriceDai() external view returns (uint256);

    function linkFee(uint256, uint256) external view returns (uint256);

    function tokenDaiReservesLp() external view returns (uint256, uint256);

    function pendingSlOrders(uint256) external view returns (PendingSl memory);

    function storePendingSlOrder(uint256 orderId, PendingSl calldata p)
        external;

    function unregisterPendingSlOrder(uint256 orderId) external;

    function emptyNodeFulFill(
        uint256,
        uint256,
        OrderType
    ) external;

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import './StorageInterfaceV5.sol';

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface PairsStorageInterfaceV6 {
    //thangtest only testnet UNDEFINED
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE,
        UNDEFINED
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint256);

    function updateGroupCollateral(
        uint256,
        uint256,
        bool,
        bool
    ) external;

    function pairJob(uint256)
        external
        returns (
            string memory,
            string memory,
            bytes32,
            uint256
        );

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./UniswapRouterInterfaceV5.sol";
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./VaultInterfaceV5.sol";
import "./PairsStorageInterfaceV6.sol";
import "./AggregatorInterfaceV6.sol";

interface StorageInterfaceV5 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint256 leverageUnlocked;
        address referral;
        uint256 referralRewardsTotal; // 1e18
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

    function dai() external view returns (TokenInterfaceV5);

    function token() external view returns (TokenInterfaceV5);

    function linkErc677() external view returns (TokenInterfaceV5);

    function tokenDaiRouter() external view returns (UniswapRouterInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6);

    function vault() external view returns (VaultInterfaceV5);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(
        address,
        uint256,
        bool
    ) external;

    function transferDai(
        address,
        address,
        uint256
    ) external;

    function transferLinkToAggregator(
        address,
        uint256,
        uint256
    ) external;

    function unregisterTrade(
        address,
        uint256,
        uint256
    ) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external;

    function hasOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint256,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint256,
        uint256
    ) external view returns (Trade memory);

    function openTradesInfo(
        address,
        uint256,
        uint256
    ) external view returns (TradeInfo memory);

    function updateSl(
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function updateTp(
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function getOpenLimitOrder(
        address,
        uint256,
        uint256
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint256) external view returns (uint256);

    function positionSizeTokenDynamic(uint256, uint256)
        external
        view
        returns (uint256);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256)
        external
        view
        returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256)
        external
        view
        returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256)
        external
        view
        returns (uint256);

    function increaseNftRewards(uint256, uint256) external;

    function nftSuccessTimelock() external view returns (uint256);

    function currentPercentProfit(
        uint256,
        uint256,
        bool,
        uint256
    ) external view returns (int256);

    function reqID_pendingNftOrder(uint256)
        external
        view
        returns (PendingNftOrder memory);

    function setNftLastSuccess(uint256) external;

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint256) external view returns (uint256);

    function unregisterPendingNftOrder(uint256) external;

    function handleDevGovFees(
        uint256,
        uint256,
        bool,
        bool
    ) external returns (uint256);

    function distributeLpRewards(uint256) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint256) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint256) external;

    function getLeverageUnlocked(address) external view returns (uint256);

    function openLimitOrdersCount(address, uint256)
        external
        view
        returns (uint256);

    function maxOpenLimitOrdersPerPair() external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256)
        external
        view
        returns (uint256);

    function pendingMarketCloseCount(address, uint256)
        external
        view
        returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function tradesPerBlock(uint256) external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestDai(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address)
        external
        view
        returns (uint256[] memory);

    function traders(address) external view returns (Trader memory);

    function nfts(uint256) external view returns (NftInterfaceV5);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface TokenInterfaceV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface VaultInterfaceV5{
	function sendDaiToTrader(address, uint) external;
	function receiveDaiFromTrader(address, uint, uint) external;
	function currentBalanceDai() external view returns(uint);
	function distributeRewardDai(uint) external;
	function distributeReward(uint assets) external;
	function sendAssets(uint assets, address receiver) external;
	function receiveAssets(uint assets, address user) external;
}