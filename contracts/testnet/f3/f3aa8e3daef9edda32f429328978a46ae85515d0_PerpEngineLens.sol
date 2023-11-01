// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IPerpEngine} from "../interfaces/IPerpEngine.sol";
import {IOffchainBook} from "../interfaces/IOffchainBook.sol";

contract PerpEngineLens {
    IPerpEngine public perpEngine;

    constructor(address _perpEngine) {
        perpEngine = IPerpEngine(_perpEngine);
    }

    function getAllMarkets() external view returns (IOffchainBook.Market[] memory) {
        address[] memory _marketIds = perpEngine.getMarketIds();
        uint256 _length = _marketIds.length;
        IOffchainBook.Market[] memory _result = new IOffchainBook.Market[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _result[i] = IOffchainBook(_marketIds[i]).getMarket();
        }
        return _result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IOffchainBook} from "./IOffchainBook.sol";
import {IMarginBank} from "./IMarginBank.sol";
import {IPriceFeed} from "./IPriceFeed.sol";
import {IFundingRateManager} from "./IFundingRateManager.sol";
import {IFeeCalculator} from "./IFeeCalculator.sol";

interface IPerpEngine {
    /// @dev data of market.
    struct State {
        int256 availableSettle;
        int256 fundingIndex;
        int256 lastAccrualFundingTime;
    }

    /// @dev balance of user in market
    struct Balance {
        int256 amount;
        int256 quoteAmount;
        int256 fundingIndex;
    }

    struct MarketDelta {
        address market;
        address account;
        int256 amountDelta;
        int256 quoteDelta;
    }

    struct UpdateMarketTx {
        address market;
        int128 maxLeverage;
        int128 minSize;
        int128 tickSize;
        int128 stepSize;
        IOffchainBook.RiskStore riskStore;
        IOffchainBook.FeeStore feeStore;
    }

    // =============== FUNCTIONS ===============
    function addMarket(
        IOffchainBook _book,
        IOffchainBook.RiskStore memory _risk,
        IOffchainBook.FeeStore memory _fee,
        address _indexToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function updateMarket(bytes calldata _params) external;
    function applyDeltas(MarketDelta[] calldata _deltas) external;
    function settlePnl(address[] memory _markets, address _account) external returns (int256 _totalSettled);
    function socializeAccount(address _account, int256 _insurance) external returns (int256);
    function accrueFunding(address _market) external returns (int256);

    // =============== VIEWS ===============
    function getMarketIds() external view returns (address[] memory);
    function getConfig()
        external
        view
        returns (address _bank, address _priceFeed, address _fundingManager, address _feeCalculator);
    function getOffchainBook(address _market) external view returns (address);
    function getBalance(address _market, address _account) external view returns (Balance memory);
    function getBalanceAmount(address _market, address _account) external view returns (int256);
    function getUnRealizedPnl(address[] calldata _markets, address _account)
        external
        view
        returns (int256 _unRealizedPnl);
    function getUnRealizedPnl(address _account) external view returns (int256 _unRealizedPnl);

    // =============== ERRORS ===============
    error DuplicateMarket();
    error InvalidOffchainBook();
    error InvalidDecimals();

    // =============== EVENTS ===============
    event BankSet(address indexed _bank);
    event PriceFeedSet(address indexed _priceFeed);
    event FundingRateManagerSet(address indexed _fundingManager);
    event FeeCalculatorSet(address indexed _fundingManager);
    event MarketAdded(address indexed _indexToken, address indexed _book);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IEndpoint} from "./IEndpoint.sol";
import {IPerpEngine} from "./IPerpEngine.sol";

interface IOffchainBook {
    struct OrderDigest {
        bytes32 taker;
        bytes32 maker;
    }

    struct Market {
        address indexToken;
        uint8 indexDecimals;
        address quoteToken;
        uint8 quoteDecimals;
        /// @dev max leverage of market, default 20x.
        int128 maxLeverage;
        /// @dev min size of position, ex 0.01 btc-usdc perp.
        int128 minSize;
        /// @dev min price increment of order, ex 1 usdc.
        int128 tickSize;
        /// @dev min size increment of order, ex 0.001 btc-usdc perp.
        int128 stepSize;
        /// @dev total of marker fees and taker fees.
        int256 tradeFeeCollected;
        /// @dev total of execution fees of trader.
        int256 executionFeeCollected;
    }

    struct RiskStore {
        int64 longWeightInitial;
        int64 shortWeightInitial;
        int64 longWeightMaintenance;
        int64 shortWeightMaintenance;
    }

    struct FeeStore {
        int256 makerFees;
        int256 talkerFees;
    }

    // =============== FUNCTIONS ===============
    function initialize(
        address _owner,
        address _endpoint,
        IPerpEngine _engine,
        address _indexToken,
        address _quoteToken,
        int128 _maxLeverage,
        int128 _minSize,
        int128 _tickSize,
        int128 _stepSize
    ) external;
    function claimTradeFees() external returns (int256 _feeAmount);
    function claimExecutionFees() external returns (int256 _feeAmount);
    function modifyMarket(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize) external;
    function modifyRiskStore(RiskStore calldata _risk) external;
    function modifyFeeStore(FeeStore calldata _fee) external;
    function matchOrders(IEndpoint.MatchOrders calldata _params) external;

    // =============== VIEWS ===============
    function getRiskStore() external view returns (RiskStore memory);
    function getFeeStore() external view returns (FeeStore memory);
    function getMarket() external view returns (Market memory);
    function getIndexToken() external view returns (address);
    function getQuoteToken() external view returns (address);
    function getMaxLeverage() external view returns (int128);
    function getFees() external view returns (uint256, uint256);
    function getDigest(IEndpoint.Order memory _order) external returns (bytes32);

    // =============== ERRORS ===============
    error NotHealthy();
    error InvalidSignature();
    error InvalidOrderPrice();
    error InvalidOrderAmount();
    error OrderCannotBeMatched();
    error BadRiskStoreConfig();
    error BadFeeStoreConfig();
    error BadMarketConfig();
    error MaxLeverageTooHigh();

    // =============== EVENTS ===============
    event TradeFeeClaimed(int256 _feeAmount);
    event ExecutionFeeClaimed(int256 _feeAmount);
    event MarketModified(int128 _maxLeverage, int128 _minSize, int128 _tickSize, int128 _stepSize);
    event RiskStoreModified(RiskStore _risk);
    event FeeStoreModified(FeeStore _fee);
    event FillOrder(
        bytes32 indexed _digest,
        address indexed _account,
        int256 _price,
        int256 _amount,
        // whether this order is taking or making
        bool _isTaker,
        // amount paid in fees (in quote)
        int256 _feeAmount,
        // change in this account's base balance from this fill
        int256 _amountDelta,
        // change in this account's quote balance from this fill
        int256 _quoteAmountDelta
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IEndpoint.sol";

interface IMarginBank {
    function handleDepositTransfer(address _account, uint256 _amount) external;

    function withdrawCollateral(IEndpoint.WithdrawCollateral memory _txn) external;

    function liquidate(IEndpoint.Liquidate calldata _txn) external;

    function claimTradeFees() external;

    // EVENTS
    event Deposited(address indexed account, uint256 amount);
    event EndpointSet(address indexed endpoint);
    event Withdrawn(address indexed account, uint256 amount);

    // ERRORS
    error UnknownToken();
    error ZeroAddress();
    error InsufficientFunds();
    error NotUnderMaintenance();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAggregatorV3Interface} from "./IAggregatorV3Interface.sol";

interface IPriceFeed {
    enum PriceSource {
        Pyth,
        Chainlink
    }

    struct MarketConfig {
        /// @dev precision of base token
        uint256 baseUnits;
        /// @dev use chainlink or pyth oracle
        PriceSource priceSource;
        /// @dev chainlink price feed
        IAggregatorV3Interface chainlinkPriceFeed;
        /// @dev market id of pyth
        bytes32 pythId;
    }

    function configMarket(
        address _market,
        PriceSource _priceSource,
        IAggregatorV3Interface _chainlinkPriceFeed,
        bytes32 _pythId
    ) external;
    function setFundingRateManager(address _fundingRateManager) external;
    function updatePrice(bytes[] calldata _data) external payable;

    // =============== VIEW FUNCTIONS ===============
    function getIndexPrice(address _market) external view returns (uint256);
    function getMarkPrice(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error InvalidPythId();
    error UnknownMarket();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market);
    event FundingRateManagerSet(address indexed _fundingRateManager);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFundingRateManager {
    // =============== FUNCTIONS ===============
    function addMarket(address _market, uint256 _startTime) external;
    function update(address[] calldata _markets, int256[] calldata _values) external;

    // =============== VIEWS ===============
    function PRECISION() external view returns (uint256);
    function FUNDING_INTERVAL() external view returns (uint256);

    function lastFundingRate(address _market) external view returns (int256);
    function nextFundingTime(address _market) external view returns (uint256);

    // =============== ERRORS ===============
    error Outdated();
    error OutOfRange();

    error DuplicateMarket();
    error MarketNotExits();
    error InvalidUpdateData();

    // =============== EVENTS ===============
    event MarketAdded(address indexed _market, uint256 _startTime);
    event ValueUpdated(address indexed _market, int256 _value);
    event FundingRateUpdated(address indexed _market, int256 _value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IFeeCalculator {
    function getFeeRate(address _market, address _account, bool _isTaker) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IEndpoint {
    enum TransactionType {
        ExecuteSlowMode,
        UpdateFundingRate,
        WithdrawCollateral,
        MatchOrders,
        SettlePnl,
        ClaimExecutionFees,
        ClaimTradeFees,
        Liquidate
    }

    struct WithdrawCollateral {
        address account;
        uint64 nonce;
        address token;
        uint256 amount;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct Liquidate {
        bytes[] priceData;
        address account;
        uint64 nonce;
    }

    struct UpdateFundingRate {
        address[] markets;
        int256[] values;
    }

    struct Order {
        address account;
        int256 price;
        int256 amount;
        bool reduceOnly;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct SignedMatchOrders {
        address market;
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrders {
        address market;
        Order taker;
        Order maker;
    }

    struct SettlePnl {
        address[] markets;
        address account;
    }

    // =============== EVENTS ===============
    event MarginBankSet(address indexed _marginBank);
    event SequencerSet(address indexed _sequencer);
    event PerpEngineSet(address indexed _perpEngine);
    event BookSet(address indexed _market, address _book);
    event FundingRateManagerSet(address indexed _fundingRateManager);
    event PriceFeedSet(address indexed _fundingRateManager);
    event SubmitTransactions();

    // =============== ERRORS ===============
    error Unauthorized();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidNonce();
    error InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}