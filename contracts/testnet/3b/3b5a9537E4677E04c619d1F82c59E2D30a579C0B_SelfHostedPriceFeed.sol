// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Constants {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;
    uint256 public constant DEFAULT_VLP_PRICE = 100000;
    uint256 public constant FUNDING_RATE_PRECISION = 1e6;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    uint256 public constant LIQUIDATION_FEE_DIVISOR = 1e18;
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;

    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%
    uint256 public constant PRICE_PRECISION = 1e12;
    uint256 public constant LP_DECIMALS = 18;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // init set to 1$
    uint256 public constant USD_VALUE_PRECISION = 1e18;

    uint256 public constant TOKEN_PRECISION = 1e18;
    uint256 public constant FEE_PRECISION = 1e6;

    uint8 public constant ORACLE_PRICE_DECIMALS = 18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library Errors {
    string constant ZERO_AMOUNT = "0 amount";
    string constant ZERO_ADDRESS = "0x address";
    string constant UNAUTHORIZED = "UNAUTHORIZED";

    string constant MARKET_NOT_LISTED = "TradingEngine:Market not listed";
    string constant INVALID_COLLATERAL_TOKEN = "TradingEngine:Invalid collateral token";
    string constant INVALID_POSITION_SIZE = "TradingEngine:Invalid size";
    string constant EXCEED_LIQUIDITY = "TradingEngine:Exceed liquidity";
    string constant POSITION_NOT_EXIST = "TradingEngine:Position not exists";
    string constant INVALID_COLLATERAL_DELTA = "TradingEngine:Invalid collateralDelta";
    string constant POSITION_NOT_LIQUIDATABLE = "TradingEngine:Position not liquidatable";
    string constant EXCEED_MAX_OI = "TradingEngine:Exceed max OI";

    string constant INVALID_COLLATERAL_AMOUNT = "Exchange:Invalid collateral amount";
    string constant TRIGGER_PRICE_NOT_PASS = "Exchange:Trigger price not pass";
    string constant TP_SL_NOT_PASS = "Exchange:TP/SL price not pass";
    string constant LOW_EXECUTION_FEE = "Exchange:Low execution fee";
    string constant ORDER_NOT_FOUND = "Exchange:Order not found";
    string constant NOT_ORDER_OWNER = "Exchange:Not order owner";
    string constant INVALID_TP_SL_PRICE = "Exchange:Invalid TP/SL price";

    error InvalidPositionSize();
    error InsufficientCollateral();
    error PriceFeedInActive();
    error PositionNotExist();
    error InvalidCollateralAmount();
    // Orderbook

    error OrderNotFound(uint256 orderId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Constants} from "../../common/Constants.sol";
import {Errors} from "../../common/Errors.sol";

contract SelfHostedPriceFeed {
    bool public isSpreadEnabled;
    address public gov;
    uint256 public defaultSpread = 4; // 0.04%
    uint256 public maxPriceDiff = 1e16; // 1%
    uint256 public spreadBasisPointsIfInactive = 20; // 0.1%
    uint256 public spreadBasisPointsIfError = 100; // 1%
    // if the lastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    uint256 public maxPriceUpdateDelay = 1 hours;
    uint256 public priceDuration = 5 minutes;

    mapping(address => uint256) public prices;
    mapping(address => bool) public isKeeper;

    struct PriceUpdate {
        uint128 price;
        uint128 lastUpdated;
    }
    mapping(address => PriceUpdate) public priceUpdates;
    mapping(address => bool) public isWhitelistedToken;

    event SetGov(address indexed account);
    event PriceSet(address indexed token, uint256 price, uint256 timestamp);
    event TokenAdded(address indexed token);
    event KeeperAdded(address indexed keeper);
    event SetSpreadEnabled(bool flag);
    event SetDefaultSpread(uint256 spread);
    event SetConfigs(
        uint256 defaultSpread,
        uint256 maxPriceDiff,
        uint256 spreadBasisPointsIfInactive,
        uint256 spreadBasisPointsIfError,
        uint256 maxPriceUpdateDelay,
        uint256 priceDuration
    );

    constructor() {
        gov = msg.sender;
        isKeeper[msg.sender] = true;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "TradingEnginePriceFeed::onlyGov");
        _;
    }

    modifier onlyKeeper() {
        require(isKeeper[msg.sender], "TradingEnginePriceFeed::onlyKeeper");
        _;
    }

    function addToken(address _token) external onlyGov {
        require(
            !isWhitelistedToken[_token],
            "TradingEnginePriceFeed::addToken: token already added"
        );
        isWhitelistedToken[_token] = true;
        emit TokenAdded(_token);
    }

    function setGov(address _account) external onlyGov {
        gov = _account;
        emit SetGov(_account);
    }

    function addKeeper(address _keeper) external onlyGov {
        isKeeper[_keeper] = true;
    }

    function setMaxPriceDiff(uint256 rate) external onlyGov {
        maxPriceDiff = rate;
    }

    function setDefaultSpread(uint256 _defaultSpread) external onlyGov {
        defaultSpread = _defaultSpread;

        emit SetDefaultSpread(_defaultSpread);
    }

    function getPrice(address _token) external view returns (uint256) {
        return prices[_token];
    }

    function setPrices(address[] calldata _tokens, uint256[] calldata _prices) public onlyKeeper {
        uint256 timestamp = block.timestamp;
        require(_tokens.length == _prices.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(isWhitelistedToken[token], "FastPriceFeed::Unknown token");
            priceUpdates[token] = PriceUpdate({
                price: uint128(_prices[i]),
                lastUpdated: uint128(timestamp)
            });

            emit PriceSet(token, _prices[i], timestamp);
        }
    }
}