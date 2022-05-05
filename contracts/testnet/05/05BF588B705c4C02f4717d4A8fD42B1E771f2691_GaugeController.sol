/**
 *Submitted for verification at Arbiscan on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

interface IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }
    
    /**
     * @notice Voting escrow contract
     */
    function voting_escrow() external view returns (address);

    /**
     * @notice Number of gauge types
     */
    function n_gauge_types() external view returns (int128);

    /**
     * @notice Number of gauges
     */
    function n_gauges() external view returns(int128);

    /**
     * @notice Gauge type id => name
     */
    function gauge_type_names(int128 _gauge_type_id) external view returns (string memory);

    /**
     * @notice Gauge number => Pool id
     */
    function gauges(int128 _gauge_number) external view returns (uint256);

    /**
     * @notice user => pool id => VotedSlope
     */
    function vote_user_slopes(address _user, uint256 _pool_id) external view returns (VotedSlope memory);

    /**
     * @notice Total vote power used by user
     */
    function vote_user_power(address _user) external view returns (uint256);

    /**
     * Last user vote's timestamp for each pool id
     */
    function last_user_vote(address _user, uint256 _pool_id) external view returns (uint256);

    /**
     * @notice pool id => time => Point
     */
    function points_weight(uint256 _pool_id, uint256 _timestamp) external view returns (Point memory);

    /**
     * @notice pool id => time => slope
     */
    function changes_weight(uint256 _pool_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice pool id => last scheduled time (next week)
     */
    function time_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice type_id => time => Point
     */
    function points_sum(int128 _type_id, uint256 _timestamp) external view returns (Point memory);

    /**
     * @notice type_id => time => slope
     */
    function changes_sum(int128 _type_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice type_id => last scheduled time (next week)
     */
    function time_sum(int128 _type_id) external view returns (uint256);

    /**
     * @notice time => total weight
     */
    function points_total(uint256 _timestamp) external view returns(uint256);

    /**
     * @notice last scheduled time
     */
    function time_total() external view returns (uint256);

    /**
     * @notice type_id => time => type weight
     */
    function points_type_weight(int128 _type_id, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice type_id => last scheduled time (next week)
     */
    function time_type_weight(int128 _type_id) external view returns(uint256);

    /**
     * @notice Add gauge type with name `_name` and weight `_weight`
     * @param _name Name of gauge type
     * @param _weight Weight of gauge type
     */
    function add_type(string memory _name, uint256 _weight) external;

    /**
     * @notice Add gauge type with name `_name` and weight `0`
     * @param _name Name of gauge type
     */
    function add_type(string memory _name) external;

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `_weight`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     * @param _weight Gauge weight
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type, uint256 _weight) external;

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `0`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type) external;

    /**
     * @notice Get gauge type for address
     * @param _pool_id Gauge address
     * @return Gauge type id
     */
    function gauge_types(uint256 _pool_id) external view returns (int128);

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param _pool_id Gauge address
     */
    function checkpoint(uint256 _pool_id) external;

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id, uint256 _time) external view returns (uint256);

    /**
     * @notice Get Gauge relative weight (not more than 1.0) at `_time = block.timestamp` normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id, uint256 _time) external returns (uint256);

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records at `_time = block.timestamp`
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id) external returns (uint256);

    /**
     * @notice Change gauge type `_type_id` weight to `_weight`
     * @param _type_id Gauge type id
     * @param _weight New Gauge weight
     */
    function change_type_weight(int128 _type_id, uint256 _weight) external;

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param _pool_id `GaugeController` contract address
     * @param _weight New Gauge weight
     */
    function change_gauge_weight(uint256 _pool_id, uint256 _weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param _pool_id Gauge which `msg.sender` votes for
     * @param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function vote_for_gauge_weights(uint256 _pool_id, uint256 _user_weight) external;

    /**
     * @notice Get current gauge weight
     * @param _pool_id Gauge address
     * @return Gauge weight
     */
    function get_gauge_weight(uint256 _pool_id) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param _type_id Type id
     * @return Type weight
     */
    function get_type_weight(int128 _type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function get_total_weight() external view returns (uint256);

    /**
     * @notice Get sum of gauge weights per type
     * @param _type_id Type id
     * @return Sum of gauge weights
     */
    function get_weights_sum_per_type(int128 _type_id) external view returns (uint256);

    event AddType(
        string name,
        int128 type_id
    );

    event NewTypeWeight(
        int128 type_id,
        uint256 time,
        uint256 weight,
        uint256 total_weight
    );

    event NewGaugeWeight(
        uint256 pool_id,
        uint256 time,
        uint256 weight,
        uint256 total_weight
    );

    event VoteForGauge(
        uint256 time,
        address user,
        uint256 pool_id,
        uint256 weight
    );

    event NewGauge(
        uint256 addr,
        int128 gauge_type,
        uint256 weight
    );

    event KilledGauge(
        uint256 addr
    );

    error InvalidGaugeType();
    error DuplicatedGauge();
    error LockExpiresBeforeNextEpoch();
    error NoVotingPowerLeft();
    error VoteTooSoon();
    error GaugeNotFound();
    error UsedTooMuchPower();
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IWhitelist {
    function check(address _addr) external view returns (bool);

    function addToWhitelist(address _addr) external;

    function removeFromWhitelist(address _addr) external;

    error AlreadyWhitelisted();
    error NotWhitelisted();
}

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function whitelist() external view returns (address);
    function token() external view returns (address);
    function supply() external view returns (uint256);
    function epoch() external view returns (uint256);

    function point_history(uint256 _epoch) external view returns (Point memory);
    function locked(address _user) external view returns (LockedBalance memory);
    function user_point_history(address _user, uint256 _epoch) external returns (Point memory);
    function user_point_epoch(address _user) external view returns (uint256);
    function slope_changes(uint256 _timestamp) external view returns (int128);

    function get_last_user_slope(address _user) external view returns (int128);
    function user_point_history__ts(address _user, uint256 _epoch) external view returns (uint256);
    function locked__end(address _user) external view returns (uint256);

    function balanceOf(address _addr, uint256 _time) external view returns (uint256);
    function balanceOf(address _addr) external view returns (uint256);
    function balanceOfAt(address _addr, uint256 _block) external view returns(uint256);
    function totalSupply(uint256 _timestamp) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function checkpoint() external;
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function deposit_for(address _addr, uint256 _value) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;

    event Deposit(
        address indexed _provider,
        uint256 _value,
        uint256 indexed _locktime,
        DepositType _type,
        uint256 _timestamp
    );

    event Withdraw(
        address indexed _provider,
        uint256 _value,
        uint256 _timestamp
    );

    event Supply(
        uint256 _prevSupply,
        uint256 _supply
    );

    error InvalidDepositAmount();
    error LockNotFound();
    error LockStillActive();
    error LockAlreadyExpired();
    error LockAlreadyExists();
    error UnlockTimeInPast();
    error UnlockTimeAboveMax();
    error BlockInFuture();
    error TransferFailed(address _from, address _to, uint256 _amount);
    error InvalidWhitelist();
    error Unauthorized();
}

contract GaugeController is IGaugeController, Ownable {
    // Internal use only
    // Used to fix `Stack Too Deep` error: https://soliditydeveloper.com/stacktoodeep
    struct _VoteForGaugeVariables {
        uint256 slope;
        uint256 lock_end;
        uint256 next_time;
        int128 gauge_type;
        uint256 old_dt;
    }

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 constant WEEK = 7 * 86400;
    // Cannot change weight votes more often than once in 10 days
    uint256 constant WEIGHT_VOTE_DELAY = 10 * 86400;
    uint256 constant MULTIPLIER = 10 ** 18;

    // Voting escrow contract address
    address public voting_escrow;

    // GAUGE PARAMETERS
    // All numbers are "fixed point" on the basis of 1e18 

    // Number of gauge types
    int128 public n_gauge_types;
    // Number of gauges
    int128 public n_gauges;
    // Gauge type id => name
    mapping(int128 => string) public gauge_type_names;
    // Gauge id => Pool id
    mapping(int128 => uint256) public gauges;
    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gauge has not been set
    // Pool id => Gauge type id
    mapping(uint256 => int128) internal _gauge_types;

    // user => pool id => VotedSlope
    mapping(address => mapping(uint256 => VotedSlope)) internal _vote_user_slopes;
    // Total vote power used by user
    mapping(address => uint256) public vote_user_power;
    // Last user vote's timestamp for each pool id
    mapping(address => mapping(uint256 => uint256)) public last_user_vote;

    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    // pool id => time => Point
    mapping(uint256 => mapping(uint256 => Point)) internal _points_weight;
    // pool id => time => slope
    mapping(uint256 => mapping(uint256 => uint256)) public changes_weight;
    // pool id => last scheduled time (next week)
    mapping(uint256 => uint256) public time_weight;

    // type_id => time => Point
    mapping(int128 => mapping(uint256 => Point)) internal _points_sum;
    // type_id => time => slope
    mapping(int128 => mapping(uint256 => uint256)) public changes_sum;
    // type_id => last scheduled time (next week)
    mapping(int128 => uint256) public time_sum;

    // time => total weight
    mapping(uint256 => uint256) public points_total;
    // last scheduled time
    uint256 public time_total;

    // type_id => time => type weight
    mapping(int128 => mapping(uint256 => uint256 )) public points_type_weight;
    // type_id => last scheduled time (next week)
    mapping(int128 => uint256 ) public time_type_weight;

    /**
     * @param _voting_escrow Voting escrow contract address
     * @param _governor Owner of the gauge controller contract
     */
    constructor(address _voting_escrow, address _governor) {
        voting_escrow = _voting_escrow;

        _transferOwnership(_governor);

        time_total = (block.timestamp / WEEK) * WEEK;
    }

    /**
     * @notice Add gauge type with name `_name` and weight `_weight`
     * @param _name Name of gauge type
     * @param _weight Weight of gauge type
     */
    function add_type(string memory _name, uint256 _weight) public onlyOwner {
        int128 type_id = n_gauge_types;
        gauge_type_names[type_id] = _name;
        n_gauge_types = type_id + 1;
        if (_weight != 0) {
            _change_type_weight(type_id, _weight);
            emit AddType(_name, type_id);
        }
    }

    /**
     * @notice Add gauge type with name `_name` and weight `0`
     * @param _name Name of gauge type
     */
    function add_type(string memory _name) external {
        add_type(_name, 0);
    }

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `_weight`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     * @param _weight Gauge weight
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type, uint256 _weight) public onlyOwner {
        if (_gauge_type < 0 || _gauge_type >= n_gauge_types) {
            revert InvalidGaugeType();
        }

        if (_gauge_types[_pool_id] != 0) {
            revert DuplicatedGauge();
        }

        int128 n = n_gauges;
        n_gauges = n + 1;
        gauges[n] = _pool_id;

        _gauge_types[_pool_id] = _gauge_type + 1;
        uint256 next_time = ((block.timestamp + WEEK) / WEEK) * WEEK;

        if (_weight > 0) {
            uint256 _type_weight = _get_type_weight(_gauge_type);
            uint256 _old_sum = _get_sum(_gauge_type);
            uint256 _old_total = _get_total();

            _points_sum[_gauge_type][next_time].bias = _weight + _old_sum;
            time_sum[_gauge_type] = next_time;
            points_total[next_time] = _old_total + _type_weight * _weight;
            time_total = next_time;

            _points_weight[_pool_id][next_time].bias = _weight;
        }

        if (time_sum[_gauge_type] == 0) {
            time_sum[_gauge_type] = next_time;
        }
        time_weight[_pool_id] = next_time;

        emit NewGauge(_pool_id, _gauge_type, _weight);
    }

    /**
     * @notice Add gauge `_pool_id` of type `_gauge_type` with weight `0`
     * @param _pool_id Gauge address
     * @param _gauge_type Gauge type
     */
    function add_gauge(uint256 _pool_id, int128 _gauge_type) external {
        add_gauge(_pool_id, _gauge_type, 0); 
    }

    /**
     * @notice Get gauge type for address
     * @param _pool_id Gauge address
     * @return Gauge type id
     */
    function gauge_types(uint256 _pool_id) external view returns (int128) {
        int128 gauge_type = _gauge_types[_pool_id];

        if (gauge_type < 0) {
            revert InvalidGaugeType();
        }

        return gauge_type - 1;
    }

    /**
     * @notice Checkpoint to fill data common for all gauges
     */
    function checkpoint() external {
        _get_total();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
     * @param _pool_id Gauge address
     */
    function checkpoint(uint256 _pool_id) external {
        _get_weight(_pool_id);
        _get_total();
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id, uint256 _time) public view returns (uint256) {
        return _gauge_relative_weight(_pool_id, _time);
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) at `_time = block.timestamp` normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight(uint256 _pool_id) external view returns (uint256) {
        return gauge_relative_weight(_pool_id, block.timestamp);
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id, uint256 _time) public returns (uint256) {
        _get_weight(_pool_id);
        _get_total(); // Also calculates get_sum
        return _gauge_relative_weight(_pool_id, _time);
    }

    /**
     * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
               values for type and gauge records at `_time = block.timestamp`
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param _pool_id Gauge address
     * @return Value of relative weight normalized to 1e18
     */
    function gauge_relative_weight_write(uint256 _pool_id) external returns (uint256) {
        return gauge_relative_weight_write(_pool_id, block.timestamp);
    }

    /**
     * @notice Change gauge type `_type_id` weight to `_weight`
     * @param _type_id Gauge type id
     * @param _weight New Gauge weight
     */
    function change_type_weight(int128 _type_id, uint256 _weight) external onlyOwner {
        _change_type_weight(_type_id, _weight);
    }

    /**
     * @notice Change weight of gauge `addr` to `weight`
     * @param _pool_id `GaugeController` contract address
     * @param _weight New Gauge weight
     */
    function change_gauge_weight(uint256 _pool_id, uint256 _weight) external onlyOwner {
        _change_gauge_weight(_pool_id, _weight);
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param _pool_id Gauge which `msg.sender` votes for
     * @param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function vote_for_gauge_weights(uint256 _pool_id, uint256 _user_weight) external {
        // Using a struct here to prevent `Stack too deep` error
        // https://soliditydeveloper.com/stacktoodeep
        _VoteForGaugeVariables memory vote_for_gauge_vars = _VoteForGaugeVariables({
            slope: SafeCast.toUint256(int256(IVotingEscrow(voting_escrow).get_last_user_slope(msg.sender))),
            lock_end: IVotingEscrow(voting_escrow).locked__end(msg.sender),
            next_time: ((block.timestamp + WEEK) / WEEK) * WEEK,
            gauge_type: _gauge_types[_pool_id] - 1,
            old_dt: 0
        });

        if (vote_for_gauge_vars.lock_end <= vote_for_gauge_vars.next_time) {
            revert LockExpiresBeforeNextEpoch();
        }

        if (_user_weight > 10000) {
            revert NoVotingPowerLeft();
        }

        if (block.timestamp < last_user_vote[msg.sender][_pool_id] + WEIGHT_VOTE_DELAY) {
            revert VoteTooSoon();
        }

        if (vote_for_gauge_vars.gauge_type < 0) {
            revert GaugeNotFound();
        }

        // Prepare slopes and biases in memory
        VotedSlope memory old_slope = _vote_user_slopes[msg.sender][_pool_id];
        if (old_slope.end > vote_for_gauge_vars.next_time) {
            vote_for_gauge_vars.old_dt = old_slope.end - vote_for_gauge_vars.next_time;
        }
        uint256 old_bias = old_slope.slope * vote_for_gauge_vars.old_dt;
        VotedSlope memory new_slope = VotedSlope({
            slope: (vote_for_gauge_vars.slope * _user_weight) / 10000,
            end: vote_for_gauge_vars.lock_end,
            power: _user_weight
        });
        uint256 new_bias = new_slope.slope * (vote_for_gauge_vars.lock_end - vote_for_gauge_vars.next_time);

        // Check and update powers (weights) used
        uint256 power_used = vote_user_power[msg.sender];
        power_used = power_used + new_slope.power - old_slope.power;
        vote_user_power[msg.sender] = power_used;

        if (power_used > 10000) {
            revert UsedTooMuchPower();
        }

        // Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for next_time
        uint256 old_weight_bias = _get_weight(_pool_id);
        uint256 old_weight_slope = _points_weight[_pool_id][vote_for_gauge_vars.next_time].slope;
        uint256 old_sum_bias = _get_sum(vote_for_gauge_vars.gauge_type);
        uint256 old_sum_slope = _points_sum[vote_for_gauge_vars.gauge_type][vote_for_gauge_vars.next_time].slope;

        _points_weight[_pool_id][vote_for_gauge_vars.next_time].bias = Math.max(old_weight_bias + new_bias, old_bias) - old_bias;
        _points_sum[vote_for_gauge_vars.gauge_type][vote_for_gauge_vars.next_time].bias = Math.max(old_sum_bias + new_bias, old_bias) - old_bias;
        if (old_slope.end > vote_for_gauge_vars.next_time) {
            _points_weight[_pool_id][vote_for_gauge_vars.next_time].slope = Math.max(old_weight_slope + new_slope.slope, old_slope.slope) - old_slope.slope;
            _points_sum[vote_for_gauge_vars.gauge_type][vote_for_gauge_vars.next_time].slope = Math.max(old_sum_slope + new_slope.slope, old_slope.slope) - old_slope.slope;
        } else {
            _points_weight[_pool_id][vote_for_gauge_vars.next_time].slope += new_slope.slope;
            _points_sum[vote_for_gauge_vars.gauge_type][vote_for_gauge_vars.next_time].slope += new_slope.slope;
        }
        if (old_slope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            changes_weight[_pool_id][old_slope.end] -= old_slope.slope;
            changes_sum[vote_for_gauge_vars.gauge_type][old_slope.end] -= old_slope.slope;
        }
        // Add slope changes for new slopes
        changes_weight[_pool_id][new_slope.end] += new_slope.slope;
        changes_sum[vote_for_gauge_vars.gauge_type][new_slope.end] += new_slope.slope;

        _get_total();

        _vote_user_slopes[msg.sender][_pool_id] = new_slope;

        // Record last action time
        last_user_vote[msg.sender][_pool_id] = block.timestamp;

        emit VoteForGauge(block.timestamp, msg.sender, _pool_id, _user_weight);
    }

    /**
     * @notice Get current gauge weight
     * @param _pool_id Gauge address
     * @return Gauge weight
     */
    function get_gauge_weight(uint256 _pool_id) external view returns (uint256) {
        return _points_weight[_pool_id][time_weight[_pool_id]].bias;
    }

    /**
     * @notice Get current type weight
     * @param _type_id Type id
     * @return Type weight
     */
    function get_type_weight(int128 _type_id) external view returns (uint256) {
        return points_type_weight[_type_id][time_type_weight[_type_id]];
    }

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function get_total_weight() external view returns (uint256) {
        return points_total[time_total];
    }

    /**
     * @notice Get sum of gauge weights per type
     * @param _type_id Type id
     * @return Sum of gauge weights
     */
    function get_weights_sum_per_type(int128 _type_id) external view returns (uint256) {
        return _points_sum[_type_id][time_sum[_type_id]].bias;
    }

    function vote_user_slopes(address _user, uint256 _pool_id) external view returns (VotedSlope memory) {
        return _vote_user_slopes[_user][_pool_id];
    }

    function points_weight(uint256 _pool_id, uint256 _timestamp) external view returns (Point memory) {
        return _points_weight[_pool_id][_timestamp];
    }

    function points_sum(int128 _type_id, uint256 _timestamp) external view returns (Point memory) {
        return _points_sum[_type_id][_timestamp];
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins
               and return the type weight for the future week
     * @param _gauge_type Gauge type id
     * @return Type weight
     */
    function _get_type_weight(int128 _gauge_type) internal returns (uint256) {
        uint256 t = time_type_weight[_gauge_type];
        if (t > 0) {
            uint256 w = points_type_weight[_gauge_type][t];
            for (uint256 i; i < 500; ++i) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                points_type_weight[_gauge_type][t] = w;
                if (t > block.timestamp) {
                    time_type_weight[_gauge_type] = t;
                }
            }
            return w;
        }

        return 0;
    }

    /**
     * @notice Fill sum of gauge weights for the same type week-over-week for
               missed checkins and return the sum for the future week
     * @param _gauge_type Gauge type id
     * @return Sum of weights
     */
    function _get_sum(int128 _gauge_type) internal returns (uint256) {
        uint256 t = time_sum[_gauge_type];
        if (t > 0) {
            Point memory pt = _points_sum[_gauge_type][t];
            for (uint256 i; i < 500; ++i) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                uint256 d_bias = pt.slope * WEEK;
                if (pt.bias > d_bias) {
                    pt.bias -= d_bias;
                    uint256 d_slope = changes_sum[_gauge_type][t];
                    pt.slope -= d_slope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                _points_sum[_gauge_type][t] = pt;
                if (t > block.timestamp) {
                    time_sum[_gauge_type] = t;
                }
            }
            return pt.bias;
        }

        return 0;
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins
               and return the total for the future week
     * @return Total weight
     */
    function _get_total() internal returns (uint256) {
        uint256 t = time_total;
        int128 _n_gauge_types = n_gauge_types;
        if (t > block.timestamp) {
            // If we have already checkpointed - still need to change the value
            t -= WEEK;
        }
        uint256 pt = points_total[t];

        for (int128 gauge_type = 0; gauge_type < 100; ++gauge_type) {
            if (gauge_type == _n_gauge_types) {
                break;
            }
            _get_sum(gauge_type);
            _get_type_weight(gauge_type);
        }

        for (uint256 i; i < 500; ++i) {
            if (t > block.timestamp) {
                break;
            }
            t += WEEK;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gauge_type; gauge_type < 100; ++gauge_type) {
                if (gauge_type == _n_gauge_types) {
                    break;
                }
                uint256 type_sum = _points_sum[gauge_type][t].bias;
                uint256 type_weight = points_type_weight[gauge_type][t];
                pt += type_sum * type_weight;
            }
            points_total[t] = pt;

            if (t > block.timestamp) {
                time_total = t;
            }
        }

        return pt;
    }

    /**
     * @notice Fill historic gauge weights week-over-week for missed checkins
               and return the total for the future week
     * @param _pool_id Address of the gauge
     * @return Gauge weight
     */
    function _get_weight(uint256 _pool_id) internal returns (uint256) {
        uint256 t = time_weight[_pool_id];
        if (t > 0) {
            Point memory pt = _points_weight[_pool_id][t];
            for (uint256 i; i < 500; ++i) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                uint256 d_bias = pt.slope * WEEK;
                if (pt.bias > d_bias) {
                    pt.bias -= d_bias;
                    uint256 d_slope = changes_weight[_pool_id][t];
                    pt.slope -= d_slope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                _points_weight[_pool_id][t] = pt;
                if (t > block.timestamp) {
                    time_weight[_pool_id] = t;
                }
            }
            return pt.bias;
        }

        return 0;
    }

    /**
     * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
               (e.g. 1.0 == 1e18). Inflation which will be received by it is
               inflation_rate * relative_weight / 1e18
     * @param _pool_id Gauge address
     * @param _time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gauge_relative_weight(uint256 _pool_id, uint256 _time) internal view returns (uint256) {
        uint256 t = (_time / WEEK) * WEEK;
        uint256 _total_weight = points_total[t];

        if (_total_weight > 0) {
            int128 gauge_type = _gauge_types[_pool_id] - 1;
            uint256 _type_weight = points_type_weight[gauge_type][t];
            uint256 _gauge_weight = _points_weight[_pool_id][t].bias;
            return MULTIPLIER * _type_weight * _gauge_weight / _total_weight;
        }

        return 0;
    }

    /**
     * @notice Change type weight
     * @param _type_id Type id
     * @param _weight New type weight
     */
    function _change_type_weight(int128 _type_id, uint256 _weight) internal {
        uint256 old_weight = _get_type_weight(_type_id);
        uint256 old_sum = _get_sum(_type_id);
        uint256 _total_weight = _get_total();
        uint256 next_time = ((block.timestamp + WEEK) / WEEK) * WEEK;

        _total_weight = _total_weight + old_sum * _weight - old_sum * old_weight;
        points_total[next_time] = _total_weight;
        points_type_weight[_type_id][next_time] = _weight;
        time_total = next_time;
        time_type_weight[_type_id] = next_time;

        emit NewTypeWeight(_type_id, next_time, _weight, _total_weight);
    }

    /**
     * @notice Change gauge weight
     * @dev Only needed when testing in reality
     */
    function _change_gauge_weight(uint256 _pool_id, uint256 _weight) internal {
        int128 gauge_type = _gauge_types[_pool_id] - 1;
        uint256 old_gauge_weight = _get_weight(_pool_id);
        uint256 type_weight = _get_type_weight(gauge_type);
        uint256 old_sum = _get_sum(gauge_type);
        uint256 _total_weight = _get_total();
        uint256 next_time = ((block.timestamp + WEEK) / WEEK) * WEEK;

        _points_weight[_pool_id][next_time].bias = _weight;
        time_weight[_pool_id] = next_time;

        uint256 new_sum = old_sum + _weight - old_gauge_weight;
        _points_sum[gauge_type][next_time].bias = new_sum;
        time_sum[gauge_type] = next_time;

        _total_weight = _total_weight + new_sum * type_weight - old_sum * type_weight;
        points_total[next_time] = _total_weight;
        time_total = next_time;

        emit NewGaugeWeight(_pool_id, block.timestamp, _weight, _total_weight);
    }
}