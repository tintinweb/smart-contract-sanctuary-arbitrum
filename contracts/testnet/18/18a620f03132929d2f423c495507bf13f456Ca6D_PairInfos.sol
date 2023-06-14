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

contract PairInfos {
    // Addresses
    StorageInterface immutable storageT;
    address public manager;

    // Constant parameters
    uint constant PRECISION = 1e10; // 10 decimals
    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)
    uint256 public usdtDecimals;

    // Adjustable parameters
    uint public maxNegativePnlOnOpenP = 40 * PRECISION; // PRECISION (%)

    // Pair parameters
    struct PairParams {
        uint onePercentDepthAbove; // USDT
        uint onePercentDepthBelow; // USDT
        uint rolloverFeePerBlockP; // PRECISION (%)
        uint fundingFeePerBlockP; // PRECISION (%)
    }

    mapping(uint => PairParams) public pairParams;

    // Pair acc funding fees
    struct PairFundingFees {
        int accPerOiLong; // usdtDecimals (USDT)
        int accPerOiShort; // usdtDecimals (USDT)
        uint lastUpdateBlock;
    }

    mapping(uint => PairFundingFees) public pairFundingFees;

    // Pair acc rollover fees
    struct PairRolloverFees {
        uint accPerCollateral; // usdtDecimals (USDT)
        uint lastUpdateBlock;
    }

    mapping(uint => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // usdtDecimals (USDT)
        int funding; // usdtDecimals (USDT)
        bool openedAfterUpdate;
    }

    mapping(address => mapping(uint => mapping(uint => TradeInitialAccFees)))
        public tradeInitialAccFees;
    
    mapping(address => bool) public allowedToInteract;

    // Events
    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint value);

    event PairParamsUpdated(uint pairIndex, PairParams value);
    event OnePercentDepthUpdated(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    );
    event RolloverFeePerBlockPUpdated(uint pairIndex, uint value);
    event FundingFeePerBlockPUpdated(uint pairIndex, uint value);

    event TradeInitialAccFeesStored(
        address trader,
        uint pairIndex,
        uint index,
        uint rollover,
        int funding
    );

    event AccFundingFeesStored(uint pairIndex, int valueLong, int valueShort);
    event AccRolloverFeesStored(uint pairIndex, uint value);

    event FeesCharged(
        uint pairIndex,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint rolloverFees, // usdtDecimals (USDT)
        int fundingFees // usdtDecimals (USDT)
    );

    constructor(
        StorageInterface _storageT,
        uint256 _usdtDecimals) {
        storageT = _storageT;
        usdtDecimals = _usdtDecimals;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "MANAGER_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
    }


    // Set manager address
    function setManager(address _manager) external onlyGov {
        require(_manager != address(0), "ZERO_ADDRESS");
        manager = _manager;
        emit ManagerUpdated(_manager);
    }

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint value) external onlyManager {
        require(value != 0, "ZERO_VALUE");
        maxNegativePnlOnOpenP = value;
        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    // Set parameters for pair
    function setPairParams(
        uint pairIndex,
        PairParams memory value
    ) public onlyManager {
        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }

    function setPairParamsArray(
        uint[] memory indices,
        PairParams[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setPairParams(indices[i], values[i]);
        }
    }

    // Set one percent depth for pair
    function setOnePercentDepth(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    ) public onlyManager {
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;

        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }

    function setOnePercentDepthArray(
        uint[] memory indices,
        uint[] memory valuesAbove,
        uint[] memory valuesBelow
    ) external onlyManager {
        require(
            indices.length == valuesAbove.length &&
                indices.length == valuesBelow.length,
            "WRONG_LENGTH"
        );

        for (uint i = 0; i < indices.length; i++) {
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    // Set rollover fee for pair
    function setRolloverFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        require(value <= 25000000, "TOO_HIGH"); // ≈ 100% per day

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;

        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }

    function setRolloverFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    // Set funding fee for pair
    function setFundingFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        require(value <= 10000000, "TOO_HIGH"); // ≈ 40% per day

        storeAccFundingFees(pairIndex);

        pairParams[pairIndex].fundingFeePerBlockP = value;

        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    function setFundingFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external onlyCallbacks {
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long
            ? pairFundingFees[pairIndex].accPerOiLong
            : pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(
            trader,
            pairIndex,
            index,
            t.rollover,
            t.funding
        );
    }

    // Acc rollover fees (store right before fee % update)
    function storeAccRolloverFees(uint pairIndex) private {
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }

    function getPendingAccRolloverFees(
        uint pairIndex
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        PairRolloverFees storage r = pairRolloverFees[pairIndex];
        uint _usdtDecimals = usdtDecimals;
        return
            r.accPerCollateral +
            ((block.number - r.lastUpdateBlock) *
                pairParams[pairIndex].rolloverFeePerBlockP *
                _usdtDecimals) /
            PRECISION /
            100;
    }

    // Acc funding fees (store right before trades opened / closed and fee % update)
    function storeAccFundingFees(uint pairIndex) private {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex);
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }

    function getPendingAccFundingFees(
        uint pairIndex
    ) public view returns (int valueLong, int valueShort) {
        PairFundingFees storage f = pairFundingFees[pairIndex];
        int256 _usdtDecimals = int256(usdtDecimals);

        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        int openInterestUSDTLong = int(storageT.openInterestUSDT(pairIndex, 0));
        int openInterestUSDTShort = int(
            storageT.openInterestUSDT(pairIndex, 1)
        );

        int fundingFeesPaidByLongs = ((openInterestUSDTLong -
            openInterestUSDTShort) *
            int(block.number - f.lastUpdateBlock) *
            int(pairParams[pairIndex].fundingFeePerBlockP)) /
            int(PRECISION) /
            100;

        if (openInterestUSDTLong > 0) {
            valueLong += (fundingFeesPaidByLongs * _usdtDecimals) / openInterestUSDTLong;
        }

        if (openInterestUSDTShort > 0) {
            valueShort +=
                (fundingFeesPaidByLongs * _usdtDecimals * (-1)) /
                openInterestUSDTShort;
        }
    }

    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint tradeOpenInterest // usdtDecimals (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,
            long,
            storageT.openInterestUSDT(pairIndex, long ? 0 : 1),
            tradeOpenInterest,
            long
                ? pairParams[pairIndex].onePercentDepthAbove
                : pairParams[pairIndex].onePercentDepthBelow
        );
    }

    function getTradePriceImpactPure(
        uint openPrice, // PRECISION
        bool long,
        uint startOpenInterest, // usdtDecimals (USDT)
        uint tradeOpenInterest, // usdtDecimals (USDT)
        uint onePercentDepth
    )
        public
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        if (onePercentDepth == 0) {
            return (0, openPrice);
        }

        priceImpactP =
            ((startOpenInterest + tradeOpenInterest / 2) * PRECISION) /
            usdtDecimals /
            onePercentDepth;

        uint priceImpact = (priceImpactP * openPrice) / PRECISION / 100;

        priceAfterImpact = long
            ? openPrice + priceImpact
            : openPrice - priceImpact;
    }

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // usdtDecimals (USDT)
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        return
            getTradeRolloverFeePure(
                t.rollover,
                getPendingAccRolloverFees(pairIndex),
                collateral
            );
    }

    function getTradeRolloverFeePure(
        uint accRolloverFeesPerCollateral,
        uint endAccRolloverFeesPerCollateral,
        uint collateral // usdtDecimals (USDT)
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        return
            ((endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral) *
                collateral) / usdtDecimals;
    }

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    )
        public
        view
        returns (
            int // usdtDecimals (USDT) | Positive => Fee, Negative => Reward
        )
    {
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        (int pendingLong, int pendingShort) = getPendingAccFundingFees(
            pairIndex
        );

        return
            getTradeFundingFeePure(
                t.funding,
                long ? pendingLong : pendingShort,
                collateral,
                leverage
            );
    }

    function getTradeFundingFeePure(
        int accFundingFeesPerOi,
        int endAccFundingFeesPerOi,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    )
        public
        view
        returns (
            int // usdtDecimals (USDT) | Positive => Fee, Negative => Reward
        )
    {
        return
            ((endAccFundingFeesPerOi - accFundingFeesPerOi) *
                int(collateral) *
                int(leverage)) / int(usdtDecimals);
    }

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    ) external view returns (uint) {
        // PRECISION
        return
            getTradeLiquidationPricePure(
                openPrice,
                long,
                collateral,
                leverage,
                getTradeRolloverFee(trader, pairIndex, index, collateral),
                getTradeFundingFee(
                    trader,
                    pairIndex,
                    index,
                    long,
                    collateral,
                    leverage
                )
            );
    }

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        uint rolloverFee, // usdtDecimals (USDT)
        int fundingFee // usdtDecimals (USDT)
    ) public pure returns (uint) {
        // PRECISION
        int liqPriceDistance = (int(openPrice) *
            (int((collateral * LIQ_THRESHOLD_P) / 100) -
                int(rolloverFee) -
                fundingFee)) /
            int(collateral) /
            int(leverage);

        int liqPrice = long
            ? int(openPrice) - liqPriceDistance
            : int(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint(liqPrice) : 0;
    }

    // USDT sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // usdtDecimals (USDT)
    ) external onlyCallbacks returns (uint amount) {
        // usdtDecimals (USDT)
        storeAccFundingFees(pairIndex);

        uint r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int f = getTradeFundingFee(
            trader,
            pairIndex,
            index,
            long,
            collateral,
            leverage
        );
        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);
        emit FeesCharged(
            pairIndex,
            long,
            collateral,
            leverage,
            percentProfit,
            r,
            f
        );
    }

    function getTradeValuePure(
        uint collateral, // usdtDecimals (USDT)
        int percentProfit, // PRECISION (%)
        uint rolloverFee, // usdtDecimals (USDT)
        int fundingFee, // usdtDecimals (USDT)
        uint closingFee // usdtDecimals (USDT)
    ) public pure returns (uint) {
        // usdtDecimals (USDT)
        int value = int(collateral) +
            (int(collateral) * percentProfit) /
            int(PRECISION) /
            100 -
            int(rolloverFee) -
            fundingFee;

        if (value <= (int(collateral) * int(100 - LIQ_THRESHOLD_P)) / 100) {
            return 0;
        }
        
        
        value -= int(closingFee);

        return value > 0 ? uint(value) : 0;
    }

    // Useful getters
    function getPairInfos(
        uint[] memory indices
    )
        external
        view
        returns (
            PairParams[] memory,
            PairRolloverFees[] memory,
            PairFundingFees[] memory
        )
    {
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](
            indices.length
        );
        PairFundingFees[] memory fundingFees = new PairFundingFees[](
            indices.length
        );

        for (uint i = 0; i < indices.length; i++) {
            uint index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }

    function getOnePercentDepthAbove(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthAbove;
    }

    function getOnePercentDepthBelow(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthBelow;
    }

    function getRolloverFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }

    function getFundingFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].fundingFeePerBlockP;
    }

    function getAccRolloverFees(uint pairIndex) external view returns (uint) {
        return pairRolloverFees[pairIndex].accPerCollateral;
    }

    function getAccRolloverFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }

    function getAccFundingFeesLong(uint pairIndex) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiLong;
    }

    function getAccFundingFeesShort(
        uint pairIndex
    ) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiShort;
    }

    function getAccFundingFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (uint) {
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (int) {
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }

    function getTradeOpenedAfterUpdate(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (bool) {
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
    }
}