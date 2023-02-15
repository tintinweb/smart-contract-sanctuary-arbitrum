// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "../access/Governable.sol";

contract PikaPriceFeed is Governable {
    using SafeMath for uint256;

    address owner;
    uint256 public lastUpdatedTime;
    uint256 public priceDuration = 600; // 10 mins
    uint256 public updateInterval = 120; // 2 mins
    mapping (address => uint256) public priceMap;
    mapping (address => uint256) public maxPriceDiffs;
    mapping (address => uint256) public spreads;
    mapping (address => uint256) lastUpdatedTimes;
    mapping(address => bool) public keepers;
    mapping (address => bool) public voters;
    mapping (address => bool) public disableFastOracleVotes;
    uint256 public minVoteCount = 2;
    uint256 public disableFastOracleVote;
    bool public isChainlinkOnly = false;
    bool public isPikaOracleOnly = false;
    bool public isSpreadEnabled = false;
    uint256 public delta = 20; // 20bp
    uint256 public decay = 9000; // 0.9
    uint256 public defaultMaxPriceDiff = 2e16; // 2%
    uint256 public defaultSpread = 30; // 0.3%

    event PriceSet(address token, uint256 price, uint256 timestamp);
    event PriceDurationSet(uint256 priceDuration);
    event UpdateIntervalSet(uint256 updateInterval);
    event DefaultMaxPriceDiffSet(uint256 maxPriceDiff);
    event MaxPriceDiffSet(address token, uint256 maxPriceDiff);
    event KeeperSet(address keeper, bool isActive);
    event VoterSet(address voter, bool isActive);
    event DeltaAndDecaySet(uint256 delta, uint256 decay);
    event IsSpreadEnabledSet(bool isSpreadEnabled);
    event DefaultSpreadSet(uint256 defaultSpread);
    event SpreadSet(address token, uint256 spread);
    event IsChainlinkOnlySet(bool isChainlinkOnlySet);
    event IsPikaOracleOnlySet(bool isPikaOracleOnlySet);
    event SetOwner(address owner);
    event DisableFastOracle(address voter);
    event EnableFastOracle(address voter);
    event MinVoteCountSet(uint256 minVoteCount);

    uint256 public constant MAX_PRICE_DURATION = 30 minutes;
    uint256 public constant PRICE_BASE = 10000;

    constructor() {
        owner = msg.sender;
        keepers[msg.sender] = true;
    }

    function getPrice(address token, bool isMax) external view returns (uint256) {
        (uint256 price, bool isChainlink) = getPriceAndSource(token);
        if (isSpreadEnabled || isChainlink || disableFastOracleVote >= minVoteCount) {
            uint256 spread = spreads[token] == 0 ? defaultSpread : spreads[token];
            return isMax ? price * (PRICE_BASE + spread) / PRICE_BASE : price * (PRICE_BASE - spread) / PRICE_BASE;
        }
        return price;
    }

    function shouldHaveSpread(address token) external view returns (bool) {
        (,bool isChainlink) = getPriceAndSource(token);
        return isSpreadEnabled || isChainlink || disableFastOracleVote >= minVoteCount;
    }

    function shouldUpdatePrice() external view returns (bool) {
        return lastUpdatedTime + updateInterval < block.timestamp;
    }

    function shouldUpdatePriceForToken(address token) external view returns (bool) {
        return lastUpdatedTimes[token] + updateInterval < block.timestamp;
    }

    function shouldUpdatePriceForTokens(address[] calldata tokens) external view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (lastUpdatedTimes[tokens[i]] + updateInterval < block.timestamp) {
                return true;
            }
        }
        return false;
    }

    function getPrice(address token) public view returns (uint256) {
        (uint256 price,) = getPriceAndSource(token);
        return price;
    }

    function getPriceAndSource(address token) public view returns (uint256, bool) {
        (uint256 chainlinkPrice, uint256 chainlinkTimestamp) = getChainlinkPrice(token);
        if (isChainlinkOnly || (!isPikaOracleOnly && (block.timestamp > lastUpdatedTimes[token].add(priceDuration) && chainlinkTimestamp > lastUpdatedTimes[token]))) {
            return (chainlinkPrice, true);
        }
        uint256 pikaPrice = priceMap[token];
        uint256 priceDiff = pikaPrice > chainlinkPrice ? (pikaPrice.sub(chainlinkPrice)).mul(1e18).div(chainlinkPrice) :
            (chainlinkPrice.sub(pikaPrice)).mul(1e18).div(chainlinkPrice);
        uint256 maxPriceDiff = maxPriceDiffs[token] == 0 ? defaultMaxPriceDiff : maxPriceDiffs[token];
        if (priceDiff > maxPriceDiff) {
            return (chainlinkPrice, true);
        }
        return (pikaPrice, false);
    }

    function getChainlinkPrice(address token) public view returns (uint256 priceToReturn, uint256 chainlinkTimestamp) {
        require(token != address(0), '!feed-error');

        (,int256 price,,uint256 timeStamp,) = AggregatorV3Interface(token).latestRoundData();

        require(price > 0, '!price');
        require(timeStamp > 0, '!timeStamp');
        uint8 decimals = AggregatorV3Interface(token).decimals();
        chainlinkTimestamp = timeStamp;
        if (decimals != 8) {
            priceToReturn = uint256(price) * (10**8) / (10**uint256(decimals));
        } else {
            priceToReturn = uint256(price);
        }
    }

    function getPrices(address[] memory tokens) external view returns (uint256[] memory){
        uint256[] memory curPrices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            curPrices[i] = getPrice(tokens[i]);
        }
        return curPrices;
    }

    function getLastNPrices(address token, uint256 n) external view returns(uint256[] memory) {
        require(token != address(0), '!feed-error');

        uint256[] memory prices = new uint256[](n);
        uint8 decimals = AggregatorV3Interface(token).decimals();
        (uint80 roundId,,,,) = AggregatorV3Interface(token).latestRoundData();

        for (uint256 i = 0; i < n; i++) {
            (,int256 price,,,) = AggregatorV3Interface(token).getRoundData(roundId - uint80(i));
            require(price > 0, '!price');
            uint256 priceToReturn;
            if (decimals != 8) {
                priceToReturn = uint256(price) * (10**8) / (10**uint256(decimals));
            } else {
                priceToReturn = uint256(price);
            }
            prices[i] = priceToReturn;
        }
        return prices;
    }

    function setPrices(address[] memory tokens, uint256[] memory prices) external onlyKeeper {
        require(tokens.length == prices.length, "!length");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            priceMap[token] = prices[i];
            lastUpdatedTimes[token] = block.timestamp;
            emit PriceSet(token, prices[i], block.timestamp);
        }
        lastUpdatedTime = block.timestamp;
    }

    function disableFastOracle() external onlyVoter {
        require(!disableFastOracleVotes[msg.sender], "already voted");
        disableFastOracleVotes[msg.sender] = true;
        disableFastOracleVote = disableFastOracleVote + 1;

        emit DisableFastOracle(msg.sender);
    }

    function enableFastOracle() external onlyVoter {
        require(disableFastOracleVotes[msg.sender], "already enabled");
        disableFastOracleVotes[msg.sender] = false;
        disableFastOracleVote = disableFastOracleVote - 1;

        emit EnableFastOracle(msg.sender);
    }

    function setMinVoteCount(uint256 _minVoteCount) external onlyOwner {
        minVoteCount = _minVoteCount;

        emit MinVoteCountSet(_minVoteCount);
    }

    function setPriceDuration(uint256 _priceDuration) external onlyOwner {
        require(_priceDuration <= MAX_PRICE_DURATION, "!priceDuration");
        priceDuration = _priceDuration;
        emit PriceDurationSet(_priceDuration);
    }

    function setUpdatedInterval(uint256 _updateInterval) external onlyOwner {
        updateInterval = _updateInterval;
        emit UpdateIntervalSet(_updateInterval);
    }

    function setDefaultMaxPriceDiff(uint256 _defaultMaxPriceDiff) external onlyOwner {
        require(_defaultMaxPriceDiff < 3e16, "too big"); // must be smaller than 3%
        defaultMaxPriceDiff = _defaultMaxPriceDiff;
        emit DefaultMaxPriceDiffSet(_defaultMaxPriceDiff);
    }

    function setMaxPriceDiff(address _token, uint256 _maxPriceDiff) external onlyOwner {
        require(_maxPriceDiff < 3e16, "too big"); // must be smaller than 3%
        maxPriceDiffs[_token] = _maxPriceDiff;
        emit MaxPriceDiffSet(_token, _maxPriceDiff);
    }

    function setKeeper(address _keeper, bool _isActive) external onlyOwner {
        keepers[_keeper] = _isActive;
        emit KeeperSet(_keeper, _isActive);
    }

    function setVoter(address _voter, bool _isActive) external onlyOwner {
        voters[_voter] = _isActive;
        emit VoterSet(_voter, _isActive);
    }

    function setIsChainlinkOnly(bool _isChainlinkOnly) external onlyOwner {
        isChainlinkOnly = _isChainlinkOnly;
        emit IsChainlinkOnlySet(isChainlinkOnly);
    }

    function setIsPikaOracleOnly(bool _isPikaOracleOnly) external onlyOwner {
        isPikaOracleOnly = _isPikaOracleOnly;
        emit IsPikaOracleOnlySet(isPikaOracleOnly);
    }

    function setDeltaAndDecay(uint256 _delta, uint256 _decay) external onlyOwner {
        delta = _delta;
        decay = _decay;
        emit DeltaAndDecaySet(delta, decay);
    }

    function setIsSpreadEnabled(bool _isSpreadEnabled) external onlyOwner {
        isSpreadEnabled = _isSpreadEnabled;
        emit IsSpreadEnabledSet(_isSpreadEnabled);
    }

    function setDefaultSpread(uint256 _defaultSpread) external onlyOwner {
        defaultSpread = _defaultSpread;
        emit DefaultSpreadSet(_defaultSpread);
    }

    function setSpread(address _token, uint256 _spread) external onlyOwner {
        spreads[_token] = _spread;
        emit SpreadSet(_token, _spread);
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit SetOwner(_owner);
    }

    modifier onlyVoter() {
        require(voters[msg.sender], "!voter");
        _;
    }

    modifier onlyKeeper() {
        require(keepers[msg.sender], "!keepers");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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