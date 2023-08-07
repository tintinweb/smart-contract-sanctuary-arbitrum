// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IChainlinkFlags {
  function getFlag(address) external view returns (bool);
}

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

interface IPriceHelper {
    function getSlipPointPrice(string memory token, uint256 price, uint256 value, uint256 maxValue, bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface ISecondaryPriceFeed {
    function getPrice(string memory _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);

    function getIndexPrice(string memory _token, uint256 _refPrice, bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * copy from openzeppelin-contracts
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeCast.sol";
import "../interfaces/IChainlinkFlags.sol";
import "../interfaces/IManager.sol";
import "../interfaces/ISecondaryPriceFeed.sol";
import "../interfaces/IPriceHelper.sol";

contract MarketPriceFeed {
    using SafeMath for uint256;
    using SafeCast for uint256;

    //uint256 public constant PRICE_DECIMAL = 10;
    uint256 public constant PRICE_PRECISION = 10 ** 10;//price decimal 1e10
    uint256 public constant ONE_USD = PRICE_PRECISION;//1 USD
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;//basis points 1e4
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;//max spread basis points 0.5%
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;//max adjustment interval 2 hours，is not allowed to be changed in interval
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;//max adjustment basis points 0.2%

    // Identifier of the Sequencer offline flag on the Flags contract
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
    address public manager;
    address public chainlinkFlags;//chainlink flags address
    address public priceHelper;//priceHelper address

    bool public isSecondaryPriceEnabled = true; //is offChain price enabled
    uint256 public priceSampleSpace = 1;//price sample space
    uint256 public maxStrictPriceDeviation = 0;//strict stable token price deviation
    address public secondaryPriceFeed; // offChain price feed address

    //token => chainLink address
    mapping(string => address) public priceFeeds;//token => chainLink address
    mapping(string => uint256) public priceDecimals;//token => chainLink price decimal
    mapping(string => uint256) public spreadBasisPoints;//token => spread basis points
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping(string => bool) public strictStableTokens;//token => is strict stable token
    mapping(string => uint256) public  adjustmentBasisPoints;//token => adjustment basis points
    mapping(string => bool) public  isAdjustmentAdditive;//token => is adjustment additive
    mapping(string => uint256) public lastAdjustmentTimings;//token => last adjustment timing

    event SetChainlinkFlags(address indexed _chainlinkFlags);
    event SetPriceHelper(address indexed _priceHelper);
    event SetAdjustment(string indexed _token, bool indexed _isAdditive, uint256 indexed _adjustmentBps);
    event SetIsSecondaryPriceEnabled(bool indexed _isEnabled);
    event SetSecondaryPriceFeed(address indexed _secondaryPriceFeed);
    event SetSpreadBasisPoints(string indexed _token, uint256 indexed _spreadBasisPoints);
    event SetPriceSampleSpace(uint256 indexed _priceSampleSpace);
    event SetMaxStrictPriceDeviation(uint256 indexed _maxStrictPriceDeviation);
    event SetTokenConfig(string _token, address _priceFeed, uint256 _priceDecimals, bool _isStrictStable);

    constructor(address _manager) {
        require(_manager != address(0), "MarketPriceFeed: _manager is zero address");
        manager = _manager;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "MarketPriceFeed: Must be controller");
        _;
    }

    function setChainlinkFlags(address _chainlinkFlags) external onlyController {
        require(_chainlinkFlags != address(0), "MarketPriceFeed: _chainlinkFlags is zero address");
        chainlinkFlags = _chainlinkFlags;
        emit SetChainlinkFlags(_chainlinkFlags);
    }

    function setPriceHelper(address _priceHelper) external onlyController {
        priceHelper = _priceHelper;
        emit SetPriceHelper(_priceHelper);
    }

    function setAdjustment(string memory _token, bool _isAdditive, uint256 _adjustmentBps) external onlyController {
        require(
            lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            "MarketPriceFeed: adjustment frequency exceeded"
        );
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
        emit SetAdjustment(_token, _isAdditive, _adjustmentBps);
    }

    function setIsSecondaryPriceEnabled(bool _isEnabled) external onlyController {
        isSecondaryPriceEnabled = _isEnabled;
        emit SetIsSecondaryPriceEnabled(_isEnabled);
    }

    function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyController {
        require(_secondaryPriceFeed != address(0), "MarketPriceFeed: _secondaryPriceFeed is zero address");
        secondaryPriceFeed = _secondaryPriceFeed;
        emit SetSecondaryPriceFeed(_secondaryPriceFeed);
    }

    function setSpreadBasisPoints(string memory _token, uint256 _spreadBasisPoints) external onlyController {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "MarketPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
        emit SetSpreadBasisPoints(_token, _spreadBasisPoints);
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external onlyController {
        require(_priceSampleSpace > 0, "MarketPriceFeed: invalid _priceSampleSpace");
        priceSampleSpace = _priceSampleSpace;
        emit SetPriceSampleSpace(_priceSampleSpace);
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external onlyController {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
        emit SetMaxStrictPriceDeviation(_maxStrictPriceDeviation);
    }

    function setTokenConfig(
        string memory _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyController {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
        emit SetTokenConfig(_token, _priceFeed, _priceDecimals, _isStrictStable);
    }

    function getPrice(string memory _token, uint256 value, uint256 maxValue, bool _maximise) public view returns (uint256) {
        uint256 price = getPriceV1(_token, _maximise);
        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            }
        }
        
        if (priceHelper != address(0)) {
            price = IPriceHelper(priceHelper).getSlipPointPrice(_token, price, value, maxValue, _maximise);
        }

        return price;
    }

    function getPriceV1(string memory _token, bool _maximise) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);

        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }


        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }
        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
    }

    function getLatestPrimaryPrice(string memory _token) public view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "MarketPriceFeed: invalid price feed");

        AggregatorV2V3Interface priceFeed = AggregatorV2V3Interface(priceFeedAddress);

        int256 price = priceFeed.latestAnswer();
        require(price > 0, "MarketPriceFeed: invalid price");

        return uint256(price).mul(PRICE_PRECISION).div(10 ** priceFeed.decimals());
    }

    function getPrimaryPrice(string memory _token, bool _maximise) public view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "MarketPriceFeed: invalid price feed");

        AggregatorV2V3Interface priceFeed = AggregatorV2V3Interface(priceFeedAddress);
        uint256 price = 0;
        uint256 roundId = priceFeed.latestRound();
        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) {break;}
            uint256 p;

            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, "MarketPriceFeed: invalid price");
                p = uint256(_p);
            } else {
                (, int256 _p, , ,) = priceFeed.getRoundData((roundId - i).toUint80());
                require(_p > 0, "MarketPriceFeed: invalid price");
                p = uint256(_p);
            }

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "MarketPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(PRICE_PRECISION).div(10 ** _priceDecimals);
    }

    function getSecondaryPrice(string memory _token, uint256 _referencePrice, bool _maximise) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) {return _referencePrice;}
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }

    function getIndexPrice(string memory _token, bool _maximise) internal view returns (uint256) {
        return ISecondaryPriceFeed(secondaryPriceFeed).getIndexPrice(_token, getLatestPrimaryPrice(_token), _maximise);
    }

    function priceForTrade(string memory _token, uint256 value, uint256 maxValue, bool _maximise) external view returns (uint256){
        return getPrice(_token, value, maxValue, _maximise);
    }

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256){
        return getIndexPrice(_token, _maximise);
    }

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256){
        return getIndexPrice(_token, _maximise);
    }

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256){
        return getIndexPrice(_token, _maximise);
    }
}