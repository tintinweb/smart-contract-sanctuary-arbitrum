// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSigner(address _signer) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused() external view returns (bool);

    function isInterestPaused() external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkLiquidator(address _liquidator) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IMarketPriceFeed {
    function priceForTrade(string memory _token, uint256 value, uint256 maxValue, bool _maximise) external view returns (uint256);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IMarketPriceFeed.sol";

contract FastPriceFeed {
    using SafeMath for uint256;
    using SafeMath for uint128;

    uint256 public constant MAX_REF_PRICE = type(uint160).max;//max chainLink price
    uint256 public constant MAX_CUMULATIVE_REF_DELTA = type(uint32).max;//max cumulative chainLink price delta
    uint256 public constant MAX_CUMULATIVE_FAST_DELTA = type(uint32).max;//max cumulative fast price delta
    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;//cumulative delta precision
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;//basis points divisor
    uint256 public constant MAX_PRICE_DURATION = 30 minutes;//max price validity period 
    uint256 public constant PRICE_PRECISION = 10 ** 10;//price precision

    // fit data in a uint256 slot to save gas costs
    struct PriceDataItem {
        uint160 refPrice; // ChainLink price
        uint32 refTime; // last ChainLink price updated at time
        uint32 cumulativeRefDelta; // cumulative ChainLink price delta
        uint32 cumulativeFastDelta; // cumulative fast price delta
    }

    mapping(string => PriceDataItem) public priceData;//chainLink price data
    mapping(string => uint256) public prices;//offChain price data
    mapping(string => uint32) lastUpdatedAts;//last offChain price update time
    uint256 public lastUpdatedBlock;//last offChain price update block
    mapping(string => uint256) public maxCumulativeDeltaDiffs;//max cumulative delta diff,delta = (cumulativeFastDelta - cumulativeRefDelta)

    // should be 10 ** 8
    uint256[] public tokenPrecisions;//offChain price decimals
    string[] public tokens;//index token

    bool public isInitialized;//is initialized,only can be initialized once
    address public marketPriceFeed;//marketPriceFeed address

    //max diff between chainLink price and offChain price,if diff > maxDeviationBasisPoints then use chainLink price or offChain price
    uint256 public maxDeviationBasisPoints;
    //max diff between chainLink price and offChain price,if diff > maxDeviationBasisPoints then use chainLink price 
    uint256 public indexMaxDeviationBasisPoints;
    uint256 public priceDuration;//offChain validity period tradePrice,if delay > priceDuration then use chainLink price with 0.2% spreadBasisPoints 
    uint256 public indexPriceDuration;//offChain validity period for indexPrice
    //max offChain price update delay,if delay > maxPriceUpdateDelay then use chainLink price with 5% spreadBasisPoints 
    uint256 public maxPriceUpdateDelay;
    uint256 public spreadBasisPointsIfInactive = 20;
    uint256 public spreadBasisPointsIfChainError = 500;
    uint256 public minBlockInterval; //min block interval between two offChain price update
    uint256 public maxTimeDeviation = 3600;//max time deviation between offChain price update time and block timestamp
    uint256 public priceDataInterval = 60;//cumulative delta interval
    bool public isSpreadEnabled = false;//is spread enabled
    address public manager;
    
    event PriceData(string token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event MaxCumulativeDeltaDiffExceeded(string token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event PriceUpdated(string _token, uint256 _price);
    event SetMarketPriceFeed(address _marketPriceFeed);
    event SetMaxTimeDeviation(uint256 _maxTimeDeviation);
    event SetPriceDuration(uint256 _priceDuration, uint256 _indexPriceDuration);
    event SetMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay);
    event SetMinBlockInterval(uint256 _minBlockInterval);
    event SetMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints);
    event SetSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive);
    event SetSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError);
    event SetPriceDataInterval(uint256 _priceDataInterval);
    event SetIsSpreadEnabled(bool _isSpreadEnabled);
    event SetTokens(string[] _tokens, uint256[] _tokenPrecisions);
    event SetLastUpdatedAt(string token, uint256 lastUpdatedAt);
    event SetMaxCumulativeDeltaDiff(string token, uint256 maxCumulativeDeltaDiff);

    modifier onlyRouter() {
        require(IManager(manager).checkRouter(msg.sender), "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "FastPriceFeed: Must be controller");
        _;
    }

    constructor(
        address _manager,
        uint256 _priceDuration,
        uint256 _indexPriceDuration,
        uint256 _maxPriceUpdateDelay,
        uint256 _minBlockInterval,
        uint256 _maxDeviationBasisPoints,
        uint256 _indexMaxDeviationBasisPoints
    ) {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        require(_indexPriceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _indexPriceDuration");
        require(_manager != address(0), "FastPriceFeed: invalid manager");
        manager = _manager;
        priceDuration = _priceDuration;
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        minBlockInterval = _minBlockInterval;
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        indexMaxDeviationBasisPoints = _indexMaxDeviationBasisPoints;
        indexPriceDuration = _indexPriceDuration;
    }

    function setMarketPriceFeed(address _marketPriceFeed) external onlyController {
        require(_marketPriceFeed != address(0), "FastPriceFeed: invalid _marketPriceFeed");
        marketPriceFeed = _marketPriceFeed;
        emit SetMarketPriceFeed(_marketPriceFeed);
    }

    function setMaxTimeDeviation(uint256 _maxTimeDeviation) external onlyController {
        maxTimeDeviation = _maxTimeDeviation;
        emit SetMaxTimeDeviation(_maxTimeDeviation);
    }

    function setPriceDuration(uint256 _priceDuration, uint256 _indexPriceDuration) external onlyController {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        require(_indexPriceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _indexPriceDuration");
        priceDuration = _priceDuration;
        indexPriceDuration = _indexPriceDuration;
        emit SetPriceDuration(_priceDuration, _indexPriceDuration);
    }

    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external onlyController {
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        emit SetMaxPriceUpdateDelay(_maxPriceUpdateDelay);
    }

    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external onlyController {
        spreadBasisPointsIfInactive = _spreadBasisPointsIfInactive;
        emit SetSpreadBasisPointsIfInactive(_spreadBasisPointsIfInactive);
    }

    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external onlyController {
        spreadBasisPointsIfChainError = _spreadBasisPointsIfChainError;
        emit SetSpreadBasisPointsIfChainError(_spreadBasisPointsIfChainError);
    }

    function setMinBlockInterval(uint256 _minBlockInterval) external onlyController {
        minBlockInterval = _minBlockInterval;
        emit SetMinBlockInterval(_minBlockInterval);
    }

    function setIsSpreadEnabled(bool _isSpreadEnabled) external onlyController {
        isSpreadEnabled = _isSpreadEnabled;
        emit SetIsSpreadEnabled(_isSpreadEnabled);
    }

    function setLastUpdatedAt(string memory _token, uint32 _lastUpdatedAt) external onlyController {
        lastUpdatedAts[_token] = _lastUpdatedAt;
        emit  SetLastUpdatedAt(_token, _lastUpdatedAt);
    }

    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints, uint256 _indexMaxDeviationBasisPoints) external onlyController {
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        indexMaxDeviationBasisPoints = _indexMaxDeviationBasisPoints;
        emit SetMaxDeviationBasisPoints(_maxDeviationBasisPoints);
    }

    function setMaxCumulativeDeltaDiffs(string[] memory _tokens, uint256[] memory _maxCumulativeDeltaDiffs) external onlyController {
        for (uint256 i = 0; i < _tokens.length; i++) {
            string memory token = _tokens[i];
            maxCumulativeDeltaDiffs[token] = _maxCumulativeDeltaDiffs[i];
            emit SetMaxCumulativeDeltaDiff(token, _maxCumulativeDeltaDiffs[i]);
        }
    }

    function setPriceDataInterval(uint256 _priceDataInterval) external onlyController {
        priceDataInterval = _priceDataInterval;
        emit SetPriceDataInterval(_priceDataInterval);
    }

    function setTokens(string[] memory _tokens, uint256[] memory _tokenPrecisions) external onlyController {
        require(_tokens.length == _tokenPrecisions.length, "FastPriceFeed: invalid lengths");
        tokens = _tokens;
        tokenPrecisions = _tokenPrecisions;
        emit SetTokens(_tokens, _tokenPrecisions);
    }

    function setPrices(string[] memory _tokens, uint128[] memory _prices, uint32[] memory _timestamps) external onlyRouter {
        for (uint256 i = 0; i < _tokens.length; i++) {
            bool shouldUpdate = _setLastUpdatedValues(_tokens[i], _timestamps[i]);
            if (shouldUpdate) {
                uint256 price = _prices[i];
                if (price != 0) {
                    price = price.mul(PRICE_PRECISION).div(10 ** tokenPrecisions[i]);
                    _setPrice(_tokens[i], price, marketPriceFeed);
                }
            }
        }

    }

    // under regular operation, the fastPrice (prices[token]) is returned and there is no spread returned from this function,
    // though VaultPriceFeed might apply its own spread
    //
    // if the fastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    // in case the fastPrice has not been updated for maxPriceUpdateDelay then the _refPrice with a larger spread is used (spread: spreadBasisPointsIfChainError)
    //
    // there will be a spread from the _refPrice to the fastPrice in the following cases:
    // - in case isSpreadEnabled is set to true
    // - in case the maxDeviationBasisPoints between _refPrice and fastPrice is exceeded
    // - in case watchers flag an issue
    // - in case the cumulativeFastDelta exceeds the cumulativeRefDelta by the maxCumulativeDeltaDiff
    function getPrice(string memory _token, uint256 _refPrice, bool _maximise) external view returns (uint256) {
        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(maxPriceUpdateDelay)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
            }
            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
        }
        
        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(priceDuration)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
            }
            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
        }

        uint256 fastPrice = prices[_token];

        if (fastPrice == 0) {return _refPrice;}
        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        bool hasSpread = !favorFastPrice(_token) || diffBasisPoints > maxDeviationBasisPoints;

        if (hasSpread) {
            // return the higher of the two prices
            if (_maximise) {
                return _refPrice > fastPrice ? _refPrice : fastPrice;
            }

            // return the lower of the two prices
            //min price
            return _refPrice < fastPrice ? _refPrice : fastPrice;
        }

        return fastPrice;
    }

    function favorFastPrice(string memory _token) public view returns (bool) {
        if (isSpreadEnabled) {
            return false;
        }

        (/* uint256 prevRefPrice */, /* uint256 refTime */, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);
        if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
            // force a spread if the cumulative delta for the fast price feed exceeds the cumulative delta
            // for the Chainlink price feed by the maxCumulativeDeltaDiff allowed
            return false;
        }

        return true;
    }

    function getIndexPrice(string memory _token, uint256 _refPrice, bool _maximise) external view returns (uint256) {
        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(indexPriceDuration)) {
            return _refPrice;
        }

        uint256 fastPrice = prices[_token];
        if (fastPrice == 0) return _refPrice;

        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        if (diffBasisPoints > indexMaxDeviationBasisPoints) {
            return _refPrice;
        }

        return fastPrice;
    }

    function getPriceData(string memory _token) public view returns (uint256, uint256, uint256, uint256) {
        PriceDataItem memory data = priceData[_token];
        return (uint256(data.refPrice), uint256(data.refTime), uint256(data.cumulativeRefDelta), uint256(data.cumulativeFastDelta));
    }

    function _setPrice(string memory _token, uint256 _price, address _marketPriceFeed) internal {
        if (_marketPriceFeed != address(0)) {
            uint256 refPrice = IMarketPriceFeed(_marketPriceFeed).getLatestPrimaryPrice(_token);
            uint256 fastPrice = prices[_token];
            (uint256 prevRefPrice, uint256 refTime, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);

            if (prevRefPrice > 0) {
                uint256 refDeltaAmount = refPrice > prevRefPrice ? refPrice.sub(prevRefPrice) : prevRefPrice.sub(refPrice);
                uint256 fastDeltaAmount = fastPrice > _price ? fastPrice.sub(_price) : _price.sub(fastPrice);

                // reset cumulative delta values if it is a new time window
                if (refTime.div(priceDataInterval) != block.timestamp.div(priceDataInterval)) {
                    cumulativeRefDelta = 0;
                    cumulativeFastDelta = 0;
                }
               
                cumulativeRefDelta = cumulativeRefDelta.add(refDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(prevRefPrice));
                cumulativeFastDelta = cumulativeFastDelta.add(fastDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(fastPrice));
            }
            
            if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
                emit MaxCumulativeDeltaDiffExceeded(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
            }

            _setPriceData(_token, refPrice, cumulativeRefDelta, cumulativeFastDelta);
            emit PriceData(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        }
        prices[_token] = _price;
        emit PriceUpdated(_token, _price);
    }

    function _setPriceData(string memory _token, uint256 _refPrice, uint256 _cumulativeRefDelta, uint256 _cumulativeFastDelta) internal {
        require(_refPrice < MAX_REF_PRICE, "FastPriceFeed: invalid refPrice");
        // skip validation of block.timestamp, it should only be out of range after the year 2100
        require(_cumulativeRefDelta < MAX_CUMULATIVE_REF_DELTA, "FastPriceFeed: invalid cumulativeRefDelta");
        require(_cumulativeFastDelta < MAX_CUMULATIVE_FAST_DELTA, "FastPriceFeed: invalid cumulativeFastDelta");

        priceData[_token] = PriceDataItem(
            uint160(_refPrice),
            uint32(block.timestamp),
            uint32(_cumulativeRefDelta),
            uint32(_cumulativeFastDelta)
        );
    }

    function _setLastUpdatedValues(string memory _token, uint32 _timestamp) internal returns (bool) {
        if (minBlockInterval > 0) {
            require(block.number.sub(lastUpdatedBlock) >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
        }

        uint256 _maxTimeDeviation = maxTimeDeviation;
        require(_timestamp > block.timestamp.sub(_maxTimeDeviation), "FastPriceFeed: _timestamp below allowed range");
        require(_timestamp < block.timestamp.add(_maxTimeDeviation), "FastPriceFeed: _timestamp exceeds allowed range");

        // do not update prices if _timestamp is before the current lastUpdatedAt value
        if (_timestamp < lastUpdatedAts[_token]) {
            return false;
        }

        lastUpdatedAts[_token] = _timestamp;
        lastUpdatedBlock = block.number;

        return true;
    }
}