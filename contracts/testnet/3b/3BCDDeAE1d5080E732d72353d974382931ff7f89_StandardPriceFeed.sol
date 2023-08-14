/**
 *Submitted for verification at Arbiscan on 2023-08-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

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

library Errors {
    string constant ZERO_AMOUNT = "0 amount";
    string constant ZERO_ADDRESS = "0xaddr";
    string constant UNAUTHORIZED = "UNAUTHORIZED";

    string constant MARKET_NOT_LISTED = "TE:Market not listed";
    string constant INVALID_COLLATERAL_TOKEN = "TE:Invalid collateral token";
    string constant INVALID_POSITION_SIZE = "TE:Invalid size";
    string constant EXCEED_LIQUIDITY = "TE:Exceed liquidity";
    string constant POSITION_NOT_EXIST = "TE:Position not exists";
    string constant INVALID_COLLATERAL_DELTA = "TE:Invalid collateralDelta";
    string constant POSITION_NOT_LIQUIDATABLE = "TE:Position not liquidatable";
    string constant EXCEED_MAX_OI = "TE:Exceed max OI";

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
    error MarginRatioNotMet();
    error ZeroAddress();
    // Orderbook

    error OrderNotFound(uint256 orderId);
}

contract StandardPriceFeed {
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    bool public isSpreadEnabled;
    address public gov;
    uint256 public defaultSpread = 4; // 0.04%
    uint256 public maxPriceDiff = 1e16; // 1%
    uint256 public spreadBasisPointsIfInactive = 20; // 0.1%
    uint256 public spreadBasisPointsIfError = 100; // 1%
    // if the lastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    uint256 public maxPriceUpdateDelay = 1 hours;
    uint256 public priceDuration = 5 minutes;

    mapping(address => bool) public isWhitelistedToken;
    mapping(address => uint8) public decimals;
    mapping(address => uint256) public prices;
    mapping(address => address) public chainLinkFeeds;
    mapping(address => bool) public isKeeper;
    mapping(address => uint256) public lastUpdatedTimestamp;
    mapping(address => bool) public isSyntheticToken;

    event SetGov(address indexed account);
    event PriceSet(address indexed token, uint256 price, uint256 timestamp);
    event TokenAdded(address indexed token, uint8 decimal, address chainLinkFeed);
    event SyntheticTokenAddeded(address indexed token, uint8 decimal);
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

    function setIsSpreadEnabled(bool _flag) external onlyGov {
        isSpreadEnabled = _flag;
        emit SetSpreadEnabled(_flag);
    }

    function setConfigs(
        uint256 _defaultSpread,
        uint256 _maxPriceDiff,
        uint256 _spreadBasisPointsIfInactive,
        uint256 _spreadBasisPointsIfError,
        uint256 _maxPriceUpdateDelay,
        uint256 _priceDuration
    ) external onlyGov {
        require(_maxPriceDiff <= BASIS_POINTS_DIVISOR, "FastPriceFeed::setConfigs: maxPriceDiff");
        require(
            _spreadBasisPointsIfInactive <= MAX_SPREAD_BASIS_POINTS,
            "FastPriceFeed::setConfigs: spreadBasisPointsIfInactive"
        );

        require(
            _spreadBasisPointsIfError <= MAX_SPREAD_BASIS_POINTS,
            "FastPriceFeed::setConfigs: spreadBasisPointsIfError"
        );

        defaultSpread = _defaultSpread;
        maxPriceDiff = _maxPriceDiff;
        spreadBasisPointsIfInactive = _spreadBasisPointsIfInactive;
        spreadBasisPointsIfError = _spreadBasisPointsIfError;
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        priceDuration = _priceDuration;

        emit SetConfigs(
            _defaultSpread,
            _maxPriceDiff,
            _spreadBasisPointsIfInactive,
            _spreadBasisPointsIfError,
            _maxPriceUpdateDelay,
            _priceDuration
        );
    }

    function setDefaultSpread(uint256 _defaultSpread) external onlyGov {
        defaultSpread = _defaultSpread;

        emit SetDefaultSpread(_defaultSpread);
    }

    function setTokenConfig(address _token, address _chainLinkFeed) external onlyGov {
        require(_chainLinkFeed != address(0), "PriceFeed::invalidPriceFeed");
        uint8 decimal = AggregatorV3Interface(_chainLinkFeed).decimals();
        isWhitelistedToken[_token] = true;
        chainLinkFeeds[_token] = _chainLinkFeed;
        decimals[_token] = decimal;

        emit TokenAdded(_token, decimal, _chainLinkFeed);
    }

    function setSyntheticToken(string memory _nameOrSymbol, uint8 _decimals) external onlyGov {
        address token = generateAddress(_nameOrSymbol);
        isWhitelistedToken[token] = true;
        decimals[token] = _decimals;
        isSyntheticToken[token] = true;

        emit SyntheticTokenAddeded(token, _decimals);
    }

    function generateAddress(string memory input) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(input));
        address addr = address(uint160(uint256(hash)));
        return addr;
    }

    function _calcPriceWithSpread(
        uint256 _price,
        uint256 _spreadBps,
        bool _isMax
    ) internal view returns (uint256) {
        if (!isSpreadEnabled) {
            return _price;
        }

        uint256 numerator = _isMax
            ? BASIS_POINTS_DIVISOR + _spreadBps
            : BASIS_POINTS_DIVISOR - _spreadBps;

        return (_price * numerator) / BASIS_POINTS_DIVISOR;
    }

    // under regular operation, the lastPrice (prices[token]) is returned and there is no spread returned from this function,
    // though TradingEnginePriceFeed might apply its own spread
    //
    // if the lastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    // in case the lastPrice has not been updated for maxPriceUpdateDelay then the _refPrice with a larger spread is used (spread: spreadBasisPointsIfError)
    //
    // there will be a spread from the _refPrice to the lastPrice in the following cases:

    // - in case isSpreadEnabled is set to true
    // - in case the maxDeviationBasisPoints between _refPrice and lastPrice is exceeded
    // - in case watchers flag an issue
    // - in case the cumulativeFastDelta exceeds the cumulativeRefDelta by the maxCumulativeDeltaDiff
    function getPrice(address _token, bool _isMax) external view returns (uint256) {
        (uint256 lastPrice, uint256 lastPriceTimestamp) = _getLastPrice(_token);
        if (isSyntheticToken[_token]) {
            return _calcPriceWithSpread(lastPrice, defaultSpread, _isMax);
        }

        uint256 chainlinkPrice = getChainlinkPrice(_token);

        if (lastPrice == 0 && chainlinkPrice == 0) {
            revert Errors.PriceFeedInActive();
        }

        if (block.timestamp > lastPriceTimestamp + maxPriceUpdateDelay) {
            return _calcPriceWithSpread(chainlinkPrice, spreadBasisPointsIfError, _isMax);
        }

        if (block.timestamp > lastPriceTimestamp + priceDuration) {
            return _calcPriceWithSpread(chainlinkPrice, spreadBasisPointsIfInactive, _isMax);
        }

        if (lastPrice == 0) {
            return _calcPriceWithSpread(chainlinkPrice, defaultSpread, _isMax);
        }

        uint256 priceDiff = lastPrice > chainlinkPrice
            ? ((lastPrice - chainlinkPrice) * 1e18) / chainlinkPrice
            : ((chainlinkPrice - lastPrice) * 1e18) / chainlinkPrice;

        bool surpassed = priceDiff > maxPriceDiff;

        uint256 price = lastPrice;
        if (surpassed) {
            // return the higher of the two prices
            if (_isMax) {
                price = chainlinkPrice > lastPrice ? chainlinkPrice : lastPrice;
            } else {
                // return the lower of the two prices
                price = chainlinkPrice < lastPrice ? chainlinkPrice : lastPrice;
            }
        }

        return _calcPriceWithSpread(price, defaultSpread, _isMax);
    }

    function _scalePrice(
        uint256 _amount,
        uint256 _decimals,
        uint256 _targetDecimals
    ) internal pure returns (uint256) {
        return (_amount * (10 ** _targetDecimals)) / 10 ** _decimals;
    }

    function getChainlinkPrice(address _token) public view returns (uint256 scaledPrice) {
        address priceFeed = chainLinkFeeds[_token];
        // If a token doesn't have a chainlink feed, return 0
        if (priceFeed == address(0)) {
            return 0;
        }

        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeed).latestRoundData();

        require(answeredInRound >= roundID, "COA: Stale answer");
        require(timeStamp != 0, "COA: Round incomplete");

        scaledPrice = _scalePrice(
            uint256(price),
            decimals[_token],
            Constants.ORACLE_PRICE_DECIMALS
        );
    }

    function _getLastPrice(
        address _token
    ) internal view returns (uint256 price, uint256 updatedAt) {
        return (prices[_token], lastUpdatedTimestamp[_token]);
    }

    function setPrices(address[] calldata _tokens, uint256[] calldata _prices) public onlyKeeper {
        uint256 timestamp = block.timestamp;
        require(_tokens.length == _prices.length, "!length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(isWhitelistedToken[token], "FastPriceFeed::Unknown token");

            prices[token] = _scalePrice(
                _prices[i],
                decimals[token],
                Constants.ORACLE_PRICE_DECIMALS
            );
            lastUpdatedTimestamp[token] = timestamp;

            emit PriceSet(token, _prices[i], timestamp);
        }
    }

    // function setPricesAndExecuteOrders(
    //     address[] calldata _tokens,
    //     uint256[] calldata _prices,
    //     uint256[] calldata _orders
    // ) external onlyKeeper {
    //     setPrices(_tokens, _prices);

    //     if (_orders.length > 0) {
    //         orderbook.executeOrders(_orders, payable(msg.sender));
    //     }
    // }
}