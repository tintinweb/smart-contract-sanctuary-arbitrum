// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";

abstract contract GNSNftRewardsV6 {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;

    // Params (constant)
    uint constant ROUND_LENGTH = 50;
    uint constant MIN_TRIGGER_TIMEOUT = 1;
    uint constant MIN_SAME_BLOCK_LIMIT = 5;

    // Params (adjustable)
    uint public triggerTimeout; // blocks
    uint public sameBlockLimit; // bots

    uint public firstP; // %
    uint public sameBlockP; // %
    uint public poolP; // %

    // Custom data types
    struct TriggeredLimit {
        address first;
        address[] sameBlock;
        uint block;
    }
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

    // State
    uint public currentOrder; // current order in round
    uint public currentRound; // current round (1 round = 50 orders)

    mapping(uint => uint) public roundTokens; // total token rewards for a round
    mapping(address => mapping(uint => uint)) public roundOrdersToClaim; // orders to claim from a round (out of 50)

    mapping(address => uint) public tokensToClaim; // rewards other than pool (first & same block)

    mapping(address => mapping(uint => mapping(uint => mapping(StorageInterfaceV5.LimitOrder => TriggeredLimit))))
        public triggeredLimits; // limits being triggered

    mapping(address => mapping(uint => mapping(uint => OpenLimitOrderType))) public openLimitOrderTypes;

    // Statistics
    mapping(address => uint) public tokensClaimed; // 1e18
    uint public tokensClaimedTotal; // 1e18

    // Events
    event NumberUpdated(string name, uint value);
    event PercentagesUpdated(uint firstP, uint sameBlockP, uint poolP);

    event TriggeredFirst(TriggeredLimitId id, address bot);
    event TriggeredSameBlock(TriggeredLimitId id, address bot);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(TriggeredLimitId id, address first, uint sameBlockCount, uint reward);

    event PoolTokensClaimed(address bot, uint fromRound, uint toRound, uint tokens);
    event TokensClaimed(address bot, uint tokens);

    function initialize(
        StorageInterfaceV5 _storageT,
        uint _triggerTimeout,
        uint _sameBlockLimit,
        uint _firstP,
        uint _sameBlockP,
        uint _poolP
    ) external virtual;

    // Manage params
    function updateTriggerTimeout(uint _triggerTimeout) external virtual;

    function updateSameBlockLimit(uint _sameBlockLimit) external virtual;

    function updatePercentages(uint _firstP, uint _sameBlockP, uint _poolP) external virtual;

    // Triggers
    function storeFirstToTrigger(TriggeredLimitId calldata _id, address _bot) external virtual;

    function storeTriggerSameBlock(TriggeredLimitId calldata _id, address _bot) external virtual;

    function unregisterTrigger(TriggeredLimitId calldata _id) external virtual;

    // Distribute rewards
    function distributeNftReward(TriggeredLimitId calldata _id, uint _reward) external virtual;

    // Claim rewards
    function claimPoolTokens(uint _fromRound, uint _toRound) external virtual;

    function claimTokens() external virtual;

    // Manage open limit order types
    function setOpenLimitOrderType(
        address _trader,
        uint _pairIndex,
        uint _index,
        OpenLimitOrderType _type
    ) external virtual;

    // Getters
    function triggered(TriggeredLimitId calldata _id) external view virtual returns (bool);

    function timedOut(TriggeredLimitId calldata _id) external view virtual returns (bool);

    function sameBlockTriggers(TriggeredLimitId calldata _id) external view virtual returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";

abstract contract GNSPairInfosV6_1 {
    // Addresses
    StorageInterfaceV5 public storageT;
    address public manager;

    // Constant parameters
    uint constant PRECISION = 1e10; // 10 decimals
    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)

    // Adjustable parameters
    uint public maxNegativePnlOnOpenP; // PRECISION (%)

    // Pair parameters
    struct PairParams {
        uint onePercentDepthAbove; // DAI
        uint onePercentDepthBelow; // DAI
        uint rolloverFeePerBlockP; // PRECISION (%)
        uint fundingFeePerBlockP; // PRECISION (%)
    }

    mapping(uint => PairParams) public pairParams;

    // Pair acc funding fees
    struct PairFundingFees {
        int accPerOiLong; // 1e18 (DAI)
        int accPerOiShort; // 1e18 (DAI)
        uint lastUpdateBlock;
    }

    mapping(uint => PairFundingFees) public pairFundingFees;

    // Pair acc rollover fees
    struct PairRolloverFees {
        uint accPerCollateral; // 1e18 (DAI)
        uint lastUpdateBlock;
    }

    mapping(uint => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // 1e18 (DAI)
        int funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    mapping(address => mapping(uint => mapping(uint => TradeInitialAccFees))) public tradeInitialAccFees;

    // Events
    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint value);

    event PairParamsUpdated(uint pairIndex, PairParams value);
    event OnePercentDepthUpdated(uint pairIndex, uint valueAbove, uint valueBelow);
    event RolloverFeePerBlockPUpdated(uint pairIndex, uint value);
    event FundingFeePerBlockPUpdated(uint pairIndex, uint value);

    event TradeInitialAccFeesStored(address trader, uint pairIndex, uint index, uint rollover, int funding);

    event AccFundingFeesStored(uint pairIndex, int valueLong, int valueShort);
    event AccRolloverFeesStored(uint pairIndex, uint value);

    event FeesCharged(
        uint pairIndex,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint rolloverFees, // 1e18 (DAI)
        int fundingFees // 1e18 (DAI)
    );

    function initialize(StorageInterfaceV5 _storageT, address _manager, uint _maxNegativePnlOnOpenP) external virtual;

    // Set manager address
    function setManager(address _manager) external virtual;

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint value) external virtual;

    // Set parameters for pair
    function setPairParams(uint pairIndex, PairParams memory value) public virtual;

    function setPairParamsArray(uint[] memory indices, PairParams[] memory values) external virtual;

    // Set one percent depth for pair
    function setOnePercentDepth(uint pairIndex, uint valueAbove, uint valueBelow) public virtual;

    function setOnePercentDepthArray(
        uint[] memory indices,
        uint[] memory valuesAbove,
        uint[] memory valuesBelow
    ) external virtual;

    // Set rollover fee for pair
    function setRolloverFeePerBlockP(uint pairIndex, uint value) public virtual;

    function setRolloverFeePerBlockPArray(uint[] memory indices, uint[] memory values) external virtual;

    // Set funding fee for pair
    function setFundingFeePerBlockP(uint pairIndex, uint value) public virtual;

    function setFundingFeePerBlockPArray(uint[] memory indices, uint[] memory values) external virtual;

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(address trader, uint pairIndex, uint index, bool long) external virtual;

    // Acc rollover fees (store right before fee % update)
    function getPendingAccRolloverFees(uint pairIndex) public view virtual returns (uint);

    // Acc funding fees (store right before trades opened / closed and fee % update)
    function getPendingAccFundingFees(uint pairIndex) public view virtual returns (int valueLong, int valueShort);

    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint tradeOpenInterest // 1e18 (DAI)
    )
        external
        view
        virtual
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradePriceImpactPure(
        uint openPrice, // PRECISION
        bool long,
        uint startOpenInterest, // 1e18 (DAI)
        uint tradeOpenInterest, // 1e18 (DAI)
        uint onePercentDepth
    )
        public
        pure
        virtual
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // 1e18 (DAI)
    ) public view virtual returns (uint); // 1e18 (DAI)

    function getTradeRolloverFeePure(
        uint accRolloverFeesPerCollateral,
        uint endAccRolloverFeesPerCollateral,
        uint collateral // 1e18 (DAI)
    ) public pure virtual returns (uint); // 1e18 (DAI)

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    )
        public
        view
        virtual
        returns (
            int // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    function getTradeFundingFeePure(
        int accFundingFeesPerOi,
        int endAccFundingFeesPerOi,
        uint collateral, // 1e18 (DAI)
        uint leverage
    )
        public
        pure
        virtual
        returns (
            int // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view virtual returns (uint); // PRECISION

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        uint rolloverFee, // 1e18 (DAI)
        int fundingFee // 1e18 (DAI)
    ) public pure virtual returns (uint); // PRECISION

    // Dai sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (DAI)
    ) external virtual returns (uint amount); // 1e18 (DAI)

    function getTradeValuePure(
        uint collateral, // 1e18 (DAI)
        int percentProfit, // PRECISION (%)
        uint rolloverFee, // 1e18 (DAI)
        int fundingFee, // 1e18 (DAI)
        uint closingFee // 1e18 (DAI)
    ) public pure virtual returns (uint); // 1e18 (DAI)

    // Useful getters
    function getPairInfos(
        uint[] memory indices
    ) external view virtual returns (PairParams[] memory, PairRolloverFees[] memory, PairFundingFees[] memory);

    function getOnePercentDepthAbove(uint pairIndex) external view virtual returns (uint);

    function getOnePercentDepthBelow(uint pairIndex) external view virtual returns (uint);

    function getRolloverFeePerBlockP(uint pairIndex) external view virtual returns (uint);

    function getFundingFeePerBlockP(uint pairIndex) external view virtual returns (uint);

    function getAccRolloverFees(uint pairIndex) external view virtual returns (uint);

    function getAccRolloverFeesUpdateBlock(uint pairIndex) external view virtual returns (uint);

    function getAccFundingFeesLong(uint pairIndex) external view virtual returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view virtual returns (int);

    function getAccFundingFeesUpdateBlock(uint pairIndex) external view virtual returns (uint);

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint pairIndex,
        uint index
    ) external view virtual returns (uint);

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint pairIndex,
        uint index
    ) external view virtual returns (int);

    function getTradeOpenedAfterUpdate(address trader, uint pairIndex, uint index) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";

abstract contract GNSPairsStorageV6 {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;

    // Params (constant)
    uint constant MIN_LEVERAGE = 2;
    uint constant MAX_LEVERAGE = 1000;

    // Custom data types
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)
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
        bytes32 job;
        uint minLeverage;
        uint maxLeverage;
        uint maxCollateralP; // % (of DAI vault current balance)
    }
    struct Fee {
        string name;
        uint openFeeP; // PRECISION (% of leveraged pos)
        uint closeFeeP; // PRECISION (% of leveraged pos)
        uint oracleFeeP; // PRECISION (% of leveraged pos)
        uint nftLimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint referralFeeP; // PRECISION (% of leveraged pos)
        uint minLevPosDai; // 1e18 (collateral x leverage, useful for min fee)
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

    mapping(uint => uint[2]) public groupsCollaterals; // (long, short)

    // Events
    event PairAdded(uint index, string from, string to);
    event PairUpdated(uint index);

    event GroupAdded(uint index, string name);
    event GroupUpdated(uint index);

    event FeeAdded(uint index, string name);
    event FeeUpdated(uint index);

    function initialize(StorageInterfaceV5 _storageT, uint _currentOrderId) external virtual;

    // Manage pairs
    function addPair(Pair calldata _pair) public virtual;

    function addPairs(Pair[] calldata _pairs) external virtual;

    function updatePair(uint _pairIndex, Pair calldata _pair) external virtual;

    // Manage groups
    function addGroup(Group calldata _group) external virtual;

    function updateGroup(uint _id, Group calldata _group) external virtual;

    // Manage fees
    function addFee(Fee calldata _fee) external virtual;

    function updateFee(uint _id, Fee calldata _fee) external virtual;

    // Update collateral open exposure for a group (callbacks)
    function updateGroupCollateral(uint _pairIndex, uint _amount, bool _long, bool _increase) external virtual;

    // Fetch relevant info for order (aggregator)
    function pairJob(uint _pairIndex) external virtual returns (string memory, string memory, bytes32, uint);

    // Getters (pairs & groups)
    function pairFeed(uint _pairIndex) external view virtual returns (Feed memory);

    function pairSpreadP(uint _pairIndex) external view virtual returns (uint);

    function pairMinLeverage(uint _pairIndex) external view virtual returns (uint);

    function pairMaxLeverage(uint _pairIndex) external view virtual returns (uint);

    function groupMaxCollateral(uint _pairIndex) external view virtual returns (uint);

    function groupCollateral(uint _pairIndex, bool _long) external view virtual returns (uint);

    function guaranteedSlEnabled(uint _pairIndex) external view virtual returns (bool);

    // Getters (fees)
    function pairOpenFeeP(uint _pairIndex) external view virtual returns (uint);

    function pairCloseFeeP(uint _pairIndex) external view virtual returns (uint);

    function pairOracleFeeP(uint _pairIndex) external view virtual returns (uint);

    function pairNftLimitOrderFeeP(uint _pairIndex) external view virtual returns (uint);

    function pairReferralFeeP(uint _pairIndex) external view virtual returns (uint);

    function pairMinLevPosDai(uint _pairIndex) external view virtual returns (uint);

    // Getters (backend)
    function pairsBackend(uint _index) external view virtual returns (Pair memory, Group memory, Fee memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";

abstract contract GNSTradingCallbacksV6_3_2 {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;
    address public nftRewards;
    address public pairInfos;
    address public referrals;
    address public staking;

    // Params (constant)
    uint constant PRECISION = 1e10; // 10 decimals

    uint constant MAX_SL_P = 75; // -75% PNL
    uint constant MAX_GAIN_P = 900; // 900% PnL (10x)
    uint constant MAX_EXECUTE_TIMEOUT = 5; // 5 blocks

    // Params (adjustable)
    uint public daiVaultFeeP; // % of closing fee going to DAI vault (eg. 40)
    uint public lpFeeP; // % of closing fee going to GNS/DAI LPs (eg. 20)
    uint public sssFeeP; // % of closing fee going to GNS staking (eg. 40)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract
    uint public canExecuteTimeout; // How long an update to TP/SL/Limit has to wait before it is executable

    // Last Updated State
    mapping(address => mapping(uint => mapping(uint => mapping(TradeType => LastUpdated)))) public tradeLastUpdated; // Block numbers for last updated

    // v6.3.2 Storage/State
    address public borrowingFees;

    mapping(uint => uint) public pairMaxLeverage;

    // Custom data types
    struct AggregatorAnswer {
        uint orderId;
        uint price;
        uint spreadP;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint posDai;
        uint levPosDai;
        uint tokenPriceDai;
        int profitP;
        uint price;
        uint liqPrice;
        uint daiSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
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

    // Events
    event MarketExecuted(
        uint indexed orderId,
        StorageInterfaceV5.Trade t,
        bool open,
        uint price,
        uint priceImpactP,
        uint positionSizeDai,
        int percentProfit, // before fees
        uint daiSentToTrader
    );

    event LimitExecuted(
        uint indexed orderId,
        uint limitIndex,
        StorageInterfaceV5.Trade t,
        address indexed nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        uint price,
        uint priceImpactP,
        uint positionSizeDai,
        int percentProfit,
        uint daiSentToTrader
    );

    event MarketOpenCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        CancelReason cancelReason
    );
    event MarketCloseCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        CancelReason cancelReason
    );
    event NftOrderCanceled(
        uint indexed orderId,
        address indexed nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        CancelReason cancelReason
    );

    event SlUpdated(uint indexed orderId, address indexed trader, uint indexed pairIndex, uint index, uint newSl);
    event SlCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        CancelReason cancelReason
    );

    event ClosingFeeSharesPUpdated(uint daiVaultFeeP, uint lpFeeP, uint sssFeeP);
    event CanExecuteTimeoutUpdated(uint newValue);

    event Pause(bool paused);
    event Done(bool done);

    event DevGovFeeCharged(address indexed trader, uint valueDai);
    event ReferralFeeCharged(address indexed trader, uint valueDai);
    event NftBotFeeCharged(address indexed trader, uint valueDai);
    event SssFeeCharged(address indexed trader, uint valueDai);
    event DaiVaultFeeCharged(address indexed trader, uint valueDai);
    event BorrowingFeeCharged(address indexed trader, uint tradeValueDai, uint feeValueDai);
    event PairMaxLeverageUpdated(uint indexed pairIndex, uint maxLeverage);

    // Custom errors (save gas)
    error WrongParams();
    error Forbidden();

    // Public views
    function getAllPairsMaxLeverage() external virtual view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";

abstract contract GNSTradingStorageV5 {
    // Constants
    uint public constant PRECISION = 1e10;
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    TokenInterfaceV5 public dai;
    TokenInterfaceV5 public linkErc677;

    // Contracts (updatable)
    AggregatorInterfaceV6_2 public priceAggregator;
    PoolInterfaceV5 public pool;
    address public trading;
    address public callbacks;
    TokenInterfaceV5 public token;
    NftInterfaceV5[5] public nfts;
    IGToken public vault;

    // Trading variables
    uint public maxTradesPerPair;
    uint public maxPendingMarketOrders;
    uint public nftSuccessTimelock; // blocks
    uint[5] public spreadReductionsP; // %

    // Gov & dev addresses (updatable)
    address public gov;
    address public dev;

    // Gov & dev fees
    uint public devFeesToken; // 1e18
    uint public devFeesDai; // 1e18
    uint public govFeesToken; // 1e18
    uint public govFeesDai; // 1e18

    // Stats
    uint public tokensBurned; // 1e18
    uint public tokensMinted; // 1e18
    uint public nftRewards; // 1e18

    // Enums
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    // Structs
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

    // Supported tokens to open trades with
    address[] public supportedTokens;

    // Trades mappings
    mapping(address => mapping(uint => mapping(uint => Trade))) public openTrades;
    mapping(address => mapping(uint => mapping(uint => TradeInfo))) public openTradesInfo;
    mapping(address => mapping(uint => uint)) public openTradesCount;

    // Limit orders mappings
    mapping(address => mapping(uint => mapping(uint => uint))) public openLimitOrderIds;
    mapping(address => mapping(uint => uint)) public openLimitOrdersCount;
    OpenLimitOrder[] public openLimitOrders;

    // Pending orders mappings
    mapping(uint => PendingMarketOrder) public reqID_pendingMarketOrder;
    mapping(uint => PendingNftOrder) public reqID_pendingNftOrder;
    mapping(address => uint[]) public pendingOrderIds;
    mapping(address => mapping(uint => uint)) public pendingMarketOpenCount;
    mapping(address => mapping(uint => uint)) public pendingMarketCloseCount;

    // List of open trades & limit orders
    mapping(uint => address[]) public pairTraders;
    mapping(address => mapping(uint => uint)) public pairTradersId;

    // Current and max open interests for each pair
    mapping(uint => uint[3]) public openInterestDai; // 1e18 [long,short,max]

    // Restrictions & Timelocks
    mapping(uint => uint) public nftLastSuccess;

    // List of allowed contracts => can update storage + mint/burn tokens
    mapping(address => bool) public isTradingContract;

    // Events
    event SupportedTokenAdded(address a);
    event TradingContractAdded(address a);
    event TradingContractRemoved(address a);
    event AddressUpdated(string name, address a);
    event NftsUpdated(NftInterfaceV5[5] nfts);
    event NumberUpdated(string name, uint value);
    event NumberUpdatedPair(string name, uint pairIndex, uint value);
    event SpreadReductionsUpdated(uint[5]);

    function initialize(
        TokenInterfaceV5 _dai,
        TokenInterfaceV5 _linkErc677,
        TokenInterfaceV5 _token,
        NftInterfaceV5[5] memory _nfts,
        address _gov,
        address _dev,
        uint _nftSuccessTimelock
    ) external virtual;

    // Manage addresses
    function setGov(address _gov) external virtual;

    function setDev(address _dev) external virtual;

    function updateToken(TokenInterfaceV5 _newToken) external virtual;

    function updateNfts(NftInterfaceV5[5] memory _nfts) external virtual;

    // Trading + callbacks contracts
    function addTradingContract(address _trading) external virtual;

    function removeTradingContract(address _trading) external virtual;

    function addSupportedToken(address _token) external virtual;

    function setPriceAggregator(address _aggregator) external virtual;

    function setPool(address _pool) external virtual;

    function setVault(address _vault) external virtual;

    function setTrading(address _trading) external virtual;

    function setCallbacks(address _callbacks) external virtual;

    // Manage trading variables
    function setMaxTradesPerPair(uint _maxTradesPerPair) external virtual;

    function setMaxPendingMarketOrders(uint _maxPendingMarketOrders) external virtual;

    function setNftSuccessTimelock(uint _blocks) external virtual;

    function setSpreadReductionsP(uint[5] calldata _r) external virtual;

    function setMaxOpenInterestDai(uint _pairIndex, uint _newMaxOpenInterest) external virtual;

    // Manage stored trades
    function storeTrade(Trade memory _trade, TradeInfo memory _tradeInfo) external virtual;

    function unregisterTrade(address trader, uint pairIndex, uint index) external virtual;

    // Manage pending market orders
    function storePendingMarketOrder(PendingMarketOrder memory _order, uint _id, bool _open) external virtual;

    function unregisterPendingMarketOrder(uint _id, bool _open) external virtual;

    // Manage open limit orders
    function storeOpenLimitOrder(OpenLimitOrder memory o) external virtual;

    function updateOpenLimitOrder(OpenLimitOrder calldata _o) external virtual;

    function unregisterOpenLimitOrder(address _trader, uint _pairIndex, uint _index) external virtual;

    // Manage NFT orders
    function storePendingNftOrder(PendingNftOrder memory _nftOrder, uint _orderId) external virtual;

    function unregisterPendingNftOrder(uint _order) external virtual;

    // Manage open trade
    function updateSl(address _trader, uint _pairIndex, uint _index, uint _newSl) external virtual;

    function updateTp(address _trader, uint _pairIndex, uint _index, uint _newTp) external virtual;

    function updateTrade(Trade memory _t) external virtual;

    // Manage rewards
    function distributeLpRewards(uint _amount) external virtual;

    function increaseNftRewards(uint _nftId, uint _amount) external virtual;

    // Manage dev & gov fees
    function handleDevGovFees(
        uint _pairIndex,
        uint _leveragedPositionSize,
        bool _dai,
        bool _fullFee
    ) external virtual returns (uint fee);

    function claimFees() external virtual;

    // Manage tokens
    function handleTokens(address _a, uint _amount, bool _mint) external virtual;

    function transferDai(address _from, address _to, uint _amount) external virtual;

    function transferLinkToAggregator(address _from, uint _pairIndex, uint _leveragedPosDai) external virtual;

    // View utils functions
    function firstEmptyTradeIndex(address trader, uint pairIndex) public view virtual returns (uint index);

    function firstEmptyOpenLimitIndex(address trader, uint pairIndex) public view virtual returns (uint index);

    function hasOpenLimitOrder(address trader, uint pairIndex, uint index) public view virtual returns (bool);

    // Additional getters
    function pairTradersArray(uint _pairIndex) external view virtual returns (address[] memory);

    function getPendingOrderIds(address _trader) external view virtual returns (uint[] memory);

    function pendingOrderIdsCount(address _trader) external view virtual returns (uint);

    function getOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external view virtual returns (OpenLimitOrder memory);

    function getOpenLimitOrders() external view virtual returns (OpenLimitOrder[] memory);

    function getSupportedTokens() external view virtual returns (address[] memory);

    function getSpreadReductionsArray() external view virtual returns (uint[5] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStorageInterfaceV5.sol";
import "../interfaces/GNSReferralsInterfaceV6_2.sol";
import "../interfaces/IGNSOracleRewardsV6_4_1.sol";
import "../interfaces/GNSBorrowingFeesInterfaceV6_4.sol";
import "./GNSPairInfosV6_1.sol";
import "./GNSNftRewardsV6.sol";

abstract contract GNSTradingV6_4_1 {
    // Contracts (constant)
    StorageInterfaceV5 public storageT;
    IGNSOracleRewardsV6_4_1 public oracleRewards;
    GNSPairInfosV6_1 public pairInfos;
    GNSReferralsInterfaceV6_2 public referrals;
    GNSBorrowingFeesInterfaceV6_4 public borrowingFees;

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

    // Manage params
    
    // Manage state

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        IGNSOracleRewardsV6_4_1.OpenLimitOrderType orderType, // LEGACY => market
        uint slippageP, // 1e10 (%)
        address referrer
    ) external virtual;

    // Close trade (MARKET)
    function closeTradeMarket(uint pairIndex, uint index) external virtual;
    
    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex,
        uint index,
        uint price, // PRECISION
        uint tp,
        uint sl,
        uint maxSlippageP
    ) external virtual;

    function cancelOpenLimitOrder(uint pairIndex, uint index) external virtual;

    // Manage limit order (TP/SL)
    function updateTp(uint pairIndex, uint index, uint newTp) external virtual;

    function updateSl(uint pairIndex, uint index, uint newSl) external virtual;

    // Execute limit order
    function executeNftOrder(uint256 packed) external virtual;

    // Market timeout
    function openTradeMarketTimeout(uint _order) external virtual;

    function closeTradeMarketTimeout(uint _order) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./contracts/GNSPairInfosV6_1.sol";
import "./contracts/GNSTradingV6_4_1.sol";
import "./contracts/GNSTradingStorageV5.sol";
import "./contracts/GNSTradingCallbacksV6_3_2.sol";

contract GainsReader {
    struct PairOpenInterestDai {
        uint256 long;
        uint256 short;
        uint256 max;
    }

    struct PairInfo {
        uint256 onePercentDepthAbove; // DAI
        uint256 onePercentDepthBelow; // DAI
        uint256 rolloverFeePerBlockP; // PRECISION (%)
        uint256 fundingFeePerBlockP; // PRECISION (%)
        uint256 accPerCollateral; // 1e18 (DAI)
        uint256 lastRolloverUpdateBlock;
        int256 accPerOiLong; // 1e18 (DAI)
        int256 accPerOiShort; // 1e18 (DAI)
        uint256 lastFundingUpdateBlock;
    }

    struct GainsConfig {
        GNSPairsStorageV6.Fee[] fees;
        GNSPairsStorageV6.Group[] groups;
        GNSTradingV6_4_1 trading;
        address callbacks;
        uint256 maxTradesPerPair;
        address[] supportedTokens;
        address oracleRewards;
        uint256 maxPosDai;
        bool isPaused;
        uint256 maxNegativePnlOnOpenP;
        uint256 pairsCount;
    }

    struct PairLeverage {
        uint pairMinLeverage;
        uint pairMaxLeverage;
    }

    struct GainsPair {
        GNSPairsStorageV6.Pair pair;
        PairOpenInterestDai openInterestDai;
        PairInfo pairInfo;
        PairLeverage pairLeverage; 
    }

    struct PositionInfo {
        GNSTradingStorageV5.Trade trade;
        GNSTradingStorageV5.TradeInfo tradeInfo;
        int256 initialFundingFeePerOi;
        uint256 initialRolloverFeePerCollateral;
        uint256 pendingAccRolloverFee;
        int256 pendingAccFundingFeeValueLong;
        int256 pendingAccFundingFeeValueShort;
    }

    struct MarketOrder {
        uint256 id;
        GNSTradingStorageV5.PendingMarketOrder order;
    }

    GNSPairsStorageV6 public immutable pairStorage;
    GNSTradingStorageV5 public immutable tradingStorage;

    // 0xf67df2a4339ec1591615d94599081dd037960d4b
    // 0xcfa6ebd475d89db04cad5a756fff1cb2bc5be33c
    constructor(GNSPairsStorageV6 pairStorage_, GNSTradingStorageV5 tradingStorage_) {
        pairStorage = pairStorage_;
        tradingStorage = tradingStorage_;
    }

    function getPairsCount() external view returns (uint256) {
        return pairStorage.pairsCount();
    }

    function config() external view returns (GainsConfig memory) {
        GNSTradingV6_4_1 trading = GNSTradingV6_4_1(tradingStorage.trading());
        GNSPairInfosV6_1 pairInfo = trading.pairInfos();
        uint256 feesCount = pairStorage.feesCount();
        uint256 groupsCount = pairStorage.groupsCount();

        GainsConfig memory gainsInfo = GainsConfig(
            new GNSPairsStorageV6.Fee[](feesCount),
            new GNSPairsStorageV6.Group[](groupsCount),
            trading,
            tradingStorage.callbacks(),
            tradingStorage.maxTradesPerPair(),
            tradingStorage.getSupportedTokens(),
            address(trading.oracleRewards()),
            trading.maxPosDai(),
            trading.isPaused(),
            pairInfo.maxNegativePnlOnOpenP(),
            pairStorage.pairsCount()
        );

        for (uint256 i = 0; i < feesCount; i++) {
            GNSPairsStorageV6.Fee memory fee = gainsInfo.fees[i];
            (
                fee.name,
                fee.openFeeP,
                fee.closeFeeP,
                fee.oracleFeeP,
                fee.nftLimitOrderFeeP,
                fee.referralFeeP,
                fee.minLevPosDai
            ) = pairStorage.fees(i);
        }
        for (uint256 i = 0; i < groupsCount; i++) {
            GNSPairsStorageV6.Group memory group = gainsInfo.groups[i];
            (group.name, group.job, group.minLeverage, group.maxLeverage, group.maxCollateralP) = pairStorage.groups(i);
        }

        return gainsInfo;
    }

    function pair(uint256 pairIndex) external view returns (GainsPair memory gainsPair) {
        GNSTradingV6_4_1 trading = GNSTradingV6_4_1(tradingStorage.trading());
        GNSTradingCallbacksV6_3_2 tradingCallbacks = GNSTradingCallbacksV6_3_2(tradingStorage.callbacks());

        GNSPairInfosV6_1 pairInfo = trading.pairInfos();

        GNSPairsStorageV6.Pair memory p = gainsPair.pair;

        (p.from, p.to, p.feed, p.spreadP, p.groupIndex, p.feeIndex) = pairStorage.pairs(pairIndex);
        gainsPair.openInterestDai = PairOpenInterestDai(
            tradingStorage.openInterestDai(pairIndex, 0),
            tradingStorage.openInterestDai(pairIndex, 1),
            tradingStorage.openInterestDai(pairIndex, 2)
        );
        PairInfo memory pairInfoItem = gainsPair.pairInfo;
        (
            pairInfoItem.onePercentDepthAbove,
            pairInfoItem.onePercentDepthBelow,
            pairInfoItem.rolloverFeePerBlockP,
            pairInfoItem.fundingFeePerBlockP
        ) = pairInfo.pairParams(pairIndex);
        (pairInfoItem.accPerCollateral, pairInfoItem.lastRolloverUpdateBlock) = pairInfo.pairRolloverFees(pairIndex);
        (pairInfoItem.accPerOiLong, pairInfoItem.accPerOiShort, pairInfoItem.lastFundingUpdateBlock) = pairInfo
            .pairFundingFees(pairIndex);

        // copied from GNSTradingV6_3_2.sol
        uint callbacksMaxLev = tradingCallbacks.pairMaxLeverage(pairIndex);
        uint pairMaxLeverage = callbacksMaxLev > 0 ? callbacksMaxLev : pairStorage.pairMaxLeverage(pairIndex);  

        gainsPair.pairLeverage = PairLeverage(
            pairStorage.pairMinLeverage(pairIndex),
            pairMaxLeverage
        );

    }

    function getLimitOrders(address trader)
        external
        view
        returns (
            GNSTradingStorageV5.OpenLimitOrder[] memory openLimitOrders,
            IGNSOracleRewardsV6_4_1.OpenLimitOrderType[] memory openLimitOrderTypes
        )
    {
        GNSTradingV6_4_1 trading = GNSTradingV6_4_1(tradingStorage.trading());
        IGNSOracleRewardsV6_4_1 oracleRewards = trading.oracleRewards();
        uint256 maxTradesPerPair = tradingStorage.maxTradesPerPair();
        uint256 pairsCount = pairStorage.pairsCount();

        uint256[] memory limitOrderCounts = new uint256[](pairsCount);
        uint256 total;
        for (uint256 pairIndex = 0; pairIndex < pairsCount; pairIndex++) {
            limitOrderCounts[pairIndex] = tradingStorage.openLimitOrdersCount(trader, pairIndex);
            total += limitOrderCounts[pairIndex];
        }

        openLimitOrders = new GNSTradingStorageV5.OpenLimitOrder[](total);
        openLimitOrderTypes = new IGNSOracleRewardsV6_4_1.OpenLimitOrderType[](total);
        uint256 openLimitOrderIndex;
        if (total > 0) {
            for (uint256 pairIndex = 0; pairIndex < pairsCount; pairIndex++) {
                if (limitOrderCounts[pairIndex] > 0) {
                    // orders could be [order, empty, order] and limitOrderCounts will be 2
                    for (uint256 orderIndex = 0; orderIndex < maxTradesPerPair; orderIndex++) {
                        if (tradingStorage.hasOpenLimitOrder(trader, pairIndex, orderIndex)) {
                            openLimitOrders[openLimitOrderIndex] = tradingStorage.getOpenLimitOrder(
                                trader,
                                pairIndex,
                                orderIndex
                            );
                            openLimitOrderTypes[openLimitOrderIndex] = oracleRewards.openLimitOrderTypes(
                                trader,
                                pairIndex,
                                orderIndex
                            );
                            openLimitOrderIndex++;
                        }
                    }
                }
            }
        }
    }

    function getPositionsAndMarketOrders(address trader)
        external
        view
        returns (PositionInfo[] memory positionInfos, MarketOrder[] memory marketOrders)
    {
        GNSPairInfosV6_1 pairInfo;
        {
            GNSTradingV6_4_1 trading = GNSTradingV6_4_1(tradingStorage.trading());
            pairInfo = trading.pairInfos();
        }
        uint256 pairsCount = pairStorage.pairsCount();

        uint256[] memory openTradesCount = new uint256[](pairsCount);
        uint256 total;
        for (uint256 pairIndex = 0; pairIndex < pairsCount; pairIndex++) {
            openTradesCount[pairIndex] = tradingStorage.openTradesCount(trader, pairIndex);
            total += openTradesCount[pairIndex];
        }

        positionInfos = new PositionInfo[](total);
        uint256 positionInfoIndex;
        if (total > 0) {
            uint256 maxTradesPerPair = tradingStorage.maxTradesPerPair();
            for (uint256 pairIndex = 0; pairIndex < pairsCount; pairIndex++) {
                if (openTradesCount[pairIndex] > 0) {
                    positionInfoIndex = _getPositionInfo(
                        positionInfos,
                        positionInfoIndex,
                        pairInfo,
                        trader,
                        pairIndex,
                        maxTradesPerPair
                    );
                }
            }
        }

        uint256[] memory pendingOrderIds = tradingStorage.getPendingOrderIds(trader);
        marketOrders = new MarketOrder[](pendingOrderIds.length);
        for (uint256 i = 0; i < pendingOrderIds.length; i++) {
            marketOrders[i].id = pendingOrderIds[i];
            GNSTradingStorageV5.PendingMarketOrder memory order = marketOrders[i].order;
            (
                order.trade,
                order.block,
                order.wantedPrice,
                order.slippageP,
                order.spreadReductionP,
                order.tokenId
            ) = tradingStorage.reqID_pendingMarketOrder(pendingOrderIds[i]);
        }
    }

    function _getPositionInfo(
        PositionInfo[] memory positionInfos,
        uint256 positionInfoIndex,
        GNSPairInfosV6_1 pairInfo,
        address trader,
        uint256 pairIndex,
        uint256 maxTradesPerPair
    ) internal view returns (uint256 newPositionInfoIndex) {
        newPositionInfoIndex = positionInfoIndex;
        uint256 pendingAccRolloverFee = pairInfo.getPendingAccRolloverFees(pairIndex);
        (int256 pendingAccFundingFeeLong, int256 pendingAccFundingFeeShort) = pairInfo.getPendingAccFundingFees(
            pairIndex
        );
        // positions could be [position, empty, position] and openTradesCount will be 2
        for (uint256 orderIndex = 0; orderIndex < maxTradesPerPair; orderIndex++) {
            GNSTradingStorageV5.Trade memory trade = getOpenTrades(trader, pairIndex, orderIndex);
            if (trade.trader == trader && trade.pairIndex == pairIndex && trade.index == orderIndex) {
                GNSTradingStorageV5.TradeInfo memory tradeInfo;
                (
                    tradeInfo.tokenId,
                    tradeInfo.tokenPriceDai, // PRECISION
                    tradeInfo.openInterestDai, // 1e18
                    tradeInfo.tpLastUpdated,
                    tradeInfo.slLastUpdated,
                    tradeInfo.beingMarketClosed
                ) = tradingStorage.openTradesInfo(trader, pairIndex, orderIndex);
                positionInfos[newPositionInfoIndex] = PositionInfo(
                    trade,
                    tradeInfo,
                    pairInfo.getTradeInitialAccFundingFeesPerOi(trader, pairIndex, orderIndex),
                    pairInfo.getTradeInitialAccRolloverFeesPerCollateral(trader, pairIndex, orderIndex),
                    pendingAccRolloverFee,
                    pendingAccFundingFeeLong,
                    pendingAccFundingFeeShort
                );
                newPositionInfoIndex++;
            }
        }
    }

    function getOpenTrades(
        address trader,
        uint256 pairIndex,
        uint256 orderIndex
    ) internal view returns (GNSTradingStorageV5.Trade memory trade) {
        (bool success, bytes memory data) = address(tradingStorage).staticcall(
            abi.encodeWithSignature("openTrades(address,uint256,uint256)", trader, pairIndex, orderIndex)
        );
        require(success, "openTrades revert");
        require(data.length >= 32 * 10, "openTrades broken");
        assembly {
            mstore(add(trade, 0), mload(add(data, 32)))
            mstore(add(trade, 32), mload(add(data, 64)))
            mstore(add(trade, 64), mload(add(data, 96)))
            mstore(add(trade, 96), mload(add(data, 128)))
            mstore(add(trade, 128), mload(add(data, 160)))
            mstore(add(trade, 160), mload(add(data, 192)))
            mstore(add(trade, 192), mload(add(data, 224)))
            mstore(add(trade, 224), mload(add(data, 256)))
            mstore(add(trade, 256), mload(add(data, 288)))
            mstore(add(trade, 288), mload(add(data, 320)))
        }
    }
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

import {StorageInterfaceV5} from "./IStorageInterfaceV5.sol";

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
}

// SPDX-License-Identifier: MIT
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./IGToken.sol";
import "../contracts/GNSPairsStorageV6.sol";

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

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

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

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function pairsStorage() external view returns (GNSPairsStorageV6);

    function getPrice(uint, OrderType, uint) external returns (uint);

    function tokenPriceDai() external returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

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
pragma solidity 0.8.17;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
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