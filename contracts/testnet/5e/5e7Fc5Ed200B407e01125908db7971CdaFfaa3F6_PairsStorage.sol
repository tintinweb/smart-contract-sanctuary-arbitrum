// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./PairsStorageInterface.sol";
import "./StorageInterface.sol";
import "./CallbacksInterface.sol";

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) external returns (uint256);

    function getPrice(
        OrderType,
        bytes[] calldata,
        StorageInterface.Trade memory
    ) external returns (uint, uint256);

    function fulfill(uint256 orderId, uint256 price) external;

    function pairsStorage() external view returns (PairsStorageInterface);

    function tokenPriceUSDT() external returns (uint);

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) external returns (uint256);

    function linkFee(uint, uint) external view returns (uint);

    function orders(uint) external view returns (uint, OrderType, uint, bool);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    function getPairForIndex(
        uint256 _pairIndex
    ) external view returns (string memory, string memory);

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface CallbacksInterface {
    struct AggregatorAnswer {
        uint orderId;
        uint256 price;
        uint spreadP;
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeOpenOrderCallback(AggregatorAnswer memory) external;

    function executeCloseOrderCallback(AggregatorAnswer memory) external;

    function updateSlCallback(AggregatorAnswer memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface LimitOrdersInterface {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterface.LimitOrder order;
    }
    //MOMENTUM = STOP
    //REVERSAL = LIMIT
    //LEGACY = MARKET
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface NarwhalReferralInterface {
    struct ReferrerDetails {
        address[] userReferralList;
        uint volumeReferredUSDT; // 1e18
        uint pendingRewards; // 1e18
        uint totalRewards; // 1e18
        bool registered;
        uint256 referralLink;
        bool canChangeReferralLink;
        address userReferredFrom;
        bool isWhitelisted;
        uint256 discount;
        uint256 rebate;
        uint256 tier;
    }

    function getReferralDiscountAndRebate(
        address _user
    ) external view returns (uint256, uint256);

    function signUp(address trader, address referral) external;

    function incrementTier2Tier3(
        address _tier2,
        uint256 _rewardTier2,
        uint256 _rewardTier3,
        uint256 _tradeSize
    ) external;

    function getReferralDetails(
        address _user
    ) external view returns (ReferrerDetails memory);

    function getReferral(address _user) external view returns (address);

    function isTier3KOL(address _user) external view returns (bool);

    function tier3tier2RebateBonus() external view returns (uint256);

    function incrementRewards(address _user, uint256 _rewards,uint256 _tradeSize) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairInfoInterface {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (USDT)
    ) external returns (uint); // 1e18 (USDT)

    function getAccFundingFeesLong(uint pairIndex) external view returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairsStorageInterface {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

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

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUSDT(uint) external view returns (uint);

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint);

    function incr() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PoolInterface {
    function increaseAccTokens(uint) external;
}

// SPDX-License-Identifier: MITUSDT
pragma solidity 0.8.15;
import "./TokenInterface.sol";
import "./AggregatorInterfaceV6_2.sol";
import "./UniswapRouterInterfaceV5.sol";
import "./VaultInterface.sol";
import "./PoolInterface.sol";

interface StorageInterface {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal; // 1e18
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUSDT; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (USDT or GFARM2)
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

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256);
    
    function gov() external view returns (address);

    function dev() external view returns (address);

    function USDT() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function linkErc677() external view returns (TokenInterface);

    function tokenUSDTRouter() external view returns (UniswapRouterInterfaceV5);

    function tempTradeStatus(address _trader,uint256 _pairIndex,uint256 _index) external view returns (bool);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (VaultInterface);

    function pool() external view returns (PoolInterface);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUSDT(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function tradeTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function positionSizeTokenDynamic(uint, uint) external view returns (uint);

    function maxSlP() external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingLimitOrder(PendingLimitOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function currentPercentProfit(
        uint,
        uint,
        bool,
        uint
    ) external view returns (int);

    function reqID_pendingLimitOrder(
        uint
    ) external view returns (PendingLimitOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingLimitOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint) external;

    function getLeverageUnlocked(address) external view returns (uint);

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function maxOpenLimitOrdersPerPair() external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function maxTradesPerBlock() external view returns (uint);

    function tradesPerBlock(uint) external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function maxGainP() external view returns (uint);

    function defaultLeverageUnlocked() external view returns (uint);

    function openInterestUSDT(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function traders(address) external view returns (Trader memory);

    function keeperForOrder(uint256) external view returns (address);

    function accPerOiOpen(
        address,
        uint,
        uint
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface TokenInterface {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface UniswapRouterInterfaceV5 {
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
pragma solidity 0.8.15;

interface VaultInterface {
    function sendUSDTToTrader(address, uint) external;

    function receiveUSDTFromTrader(address, uint, uint, bool) external;

    function currentBalanceUSDT() external view returns (uint);

    function distributeRewardUSDT(uint, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract PairsStorage {
    // Contracts (constant)
    StorageInterface public storageT;

    // Params (constant)
    uint constant MIN_LEVERAGE = 1;
    uint constant MAX_LEVERAGE = 1000;
    // Custom data types
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    }

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint spreadP; // PRECISION
        uint groupIndex;
        uint feeIndex;
    }
    struct Group {
        string name;
        uint minLeverage;
        uint maxLeverage;
        uint maxCollateralP; // % (of USDT vault current balance)
    }
    struct Fee {
        string name;
        uint openFeeP; // PRECISION (% of leveraged pos)
        uint closeFeeP; // PRECISION (% of leveraged pos)
        uint oracleFeeP; // PRECISION (% of leveraged pos)
        uint LimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint referralFeeP; // PRECISION (% of leveraged pos)
        uint minLevPosUSDT; // usdtDecimals (collateral x leverage, useful for min fee)
    }

    // State
    uint public currentOrderId;
    uint public pairsCount;
    uint public groupsCount;
    uint public feesCount;

    mapping(uint => Pair) public pairs;
    mapping(uint => Group) public groups;
    mapping(uint => Fee) public fees;

    mapping(string => mapping(string => bool)) public isPairListed;
    mapping(address => bool) public allowedToInteract;

    mapping(uint => uint[2]) public groupsCollaterals; // (long, short)

    // Events
    event PairAdded(uint index, string from, string to);
    event PairUpdated(uint index);

    event GroupAdded(uint index, string name);
    event GroupUpdated(uint index);

    event FeeAdded(uint index, string name);
    event FeeUpdated(uint index);

    constructor(uint _currentOrderId,address _storage) {
        require(_currentOrderId > 0, "ORDER_ID_0");
        currentOrderId = _currentOrderId;
        storageT = StorageInterface(_storage);
    }

    // Modifiers
    modifier onlyGov() {
        require(
            msg.sender == storageT.gov(),
            "GOV_ONLY"
        );
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    modifier groupListed(uint _groupIndex) {
        require(groups[_groupIndex].minLeverage > 0, "GROUP_NOT_LISTED");
        _;
    }
    modifier feeListed(uint _feeIndex) {
        require(fees[_feeIndex].openFeeP > 0, "FEE_NOT_LISTED");
        _;
    }

    modifier feedOk(Feed calldata _feed) {
        require(_feed.maxDeviationP > 0);
        require(
            _feed.feedCalculation != FeedCalculation.COMBINE,
            "WRONG_FEED_CALCULATION"
        );
        _;
    }
    modifier groupOk(Group calldata _group) {
        require(
            _group.minLeverage >= MIN_LEVERAGE &&
                _group.maxLeverage <= MAX_LEVERAGE &&
                _group.minLeverage < _group.maxLeverage,
            "WRONG_LEVERAGES"
        );
        _;
    }
    modifier feeOk(Fee calldata _fee) {
        require(
            _fee.openFeeP > 0 &&
                _fee.closeFeeP > 0 &&
                _fee.oracleFeeP > 0 &&
                _fee.LimitOrderFeeP > 0 &&
                _fee.referralFeeP > 0 &&
                _fee.minLevPosUSDT > 0,
            "WRONG_FEES"
        );
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
    }

    function changeStorageInterface(address _storage) public onlyGov {
        require(_storage != address(0), "ZERO_ADDRESS");
        storageT = StorageInterface(_storage);
    }

    // Manage pairs
    function addPair(
        Pair calldata _pair
    )
        public
        onlyGov
        feedOk(_pair.feed)
        groupListed(_pair.groupIndex)
        feeListed(_pair.feeIndex)
    {
        require(!isPairListed[_pair.from][_pair.to], "PAIR_ALREADY_LISTED");

        pairs[pairsCount] = _pair;
        isPairListed[_pair.from][_pair.to] = true;

        emit PairAdded(pairsCount++, _pair.from, _pair.to);
    }

    function addPairs(Pair[] calldata _pairs) external {
        for (uint i = 0; i < _pairs.length; i++) {
            addPair(_pairs[i]);
        }
    }

    function updatePair(
        uint _pairIndex,
        Pair calldata _pair
    ) external onlyGov feedOk(_pair.feed) feeListed(_pair.feeIndex) {
        Pair storage p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");

        p.feed = _pair.feed;
        p.spreadP = _pair.spreadP;
        p.feeIndex = _pair.feeIndex;

        emit PairUpdated(_pairIndex);
    }

    // Manage groups
    function addGroup(Group calldata _group) external onlyGov groupOk(_group) {
        groups[groupsCount] = _group;
        emit GroupAdded(groupsCount++, _group.name);
    }

    function updateGroup(
        uint _id,
        Group calldata _group
    ) external onlyGov groupListed(_id) groupOk(_group) {
        groups[_id] = _group;
        emit GroupUpdated(_id);
    }

    // Manage fees
    function addFee(Fee calldata _fee) external onlyGov feeOk(_fee) {
        fees[feesCount] = _fee;
        emit FeeAdded(feesCount++, _fee.name);
    }

    function updateFee(
        uint _id,
        Fee calldata _fee
    ) external onlyGov feeListed(_id) feeOk(_fee) {
        fees[_id] = _fee;
        emit FeeUpdated(_id);
    }

    // Update collateral open exposure for a group (callbacks)
    function updateGroupCollateral(
        uint _pairIndex,
        uint _amount,
        bool _long,
        bool _increase
    ) external onlyCallbacks {

        uint[2] storage collateralOpen = groupsCollaterals[
            pairs[_pairIndex].groupIndex
        ];
        uint index = _long ? 0 : 1;

        if (_increase) {
            collateralOpen[index] += _amount;
        } else {
            collateralOpen[index] = collateralOpen[index] > _amount
                ? collateralOpen[index] - _amount
                : 0;
        }
    }

    // Fetch relevant info for order (aggregator)
    function pairJob(
        uint _pairIndex
    ) external returns (string memory, string memory, uint) {
        require(
            msg.sender == address(storageT.priceAggregator()),
            "AGGREGATOR_ONLY"
        );
        Pair memory p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");
        return (p.from, p.to, currentOrderId++);
    }

    // Getters (pairs & groups)
    function pairFeed(uint _pairIndex) external view returns (Feed memory) {
        return pairs[_pairIndex].feed;
    }

    function pairSpreadP(uint _pairIndex) external view returns (uint) {
        return pairs[_pairIndex].spreadP;
    }

    function pairMinLeverage(uint _pairIndex) external view returns (uint) {
        return groups[pairs[_pairIndex].groupIndex].minLeverage;
    }

    function pairMaxLeverage(uint _pairIndex) external view returns (uint) {
        return groups[pairs[_pairIndex].groupIndex].maxLeverage;
    }

    function groupMaxCollateral(uint _pairIndex) external view returns (uint) {
        return
            (groups[pairs[_pairIndex].groupIndex].maxCollateralP *
                storageT.vault().currentBalanceUSDT()) / 100;
    }

    function groupCollateral(
        uint _pairIndex,
        bool _long
    ) external view returns (uint) {
        return groupsCollaterals[pairs[_pairIndex].groupIndex][_long ? 0 : 1];
    }

    function guaranteedSlEnabled(uint _pairIndex) external view returns (bool) {
        return pairs[_pairIndex].groupIndex == 0; // crypto only
    }

    // Getters (fees)
    function pairOpenFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].openFeeP;
    }

    function pairCloseFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].closeFeeP;
    }

    function pairOracleFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].oracleFeeP;
    }

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].LimitOrderFeeP;
    }

    function pairReferralFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].referralFeeP;
    }

    function pairMinLevPosUSDT(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].minLevPosUSDT;
    }

    // Getters (backend)
    function pairsBackend(
        uint _index
    ) external view returns (Pair memory, Group memory, Fee memory) {
        Pair memory p = pairs[_index];
        return (p, groups[p.groupIndex], fees[p.feeIndex]);
    }
}