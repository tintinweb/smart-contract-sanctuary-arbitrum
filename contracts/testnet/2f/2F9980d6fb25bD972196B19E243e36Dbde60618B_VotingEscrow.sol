/**
 *Submitted for verification at Arbiscan on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

contract VotingEscrow is IVotingEscrow, Ownable {
    uint256 constant WEEK = 7 * 86400;
    uint256 constant MAXTIME = 4 * 365 * 86400;
    uint256 constant MULTIPLIER = 10 ** 18;

    string public name;
    string public symbol;
    address public whitelist;
    address public token;
    uint256 public supply;
    uint256 public epoch;

    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes;

    uint8 internal _decimals;
    mapping(address => LockedBalance) internal _locked;
    mapping(uint256 => Point) internal _point_history;
    mapping(address => mapping(uint256 => Point)) internal _user_point_history;

    constructor(
        string memory _name,
        string memory _symbol,
        address _governor,
        address _token,
        address _whitelist
    ) {
        name = _name;
        symbol = _symbol;
        token = _token;
        whitelist = _whitelist;

        _decimals = ERC20(_token).decimals();

        _transferOwnership(_governor);
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function get_last_user_slope(address _user) external view returns (int128) {
        uint256 user_epoch = user_point_epoch[_user];
        return _user_point_history[_user][user_epoch].slope;
    }

    function user_point_history(address _user, uint256 _epoch) external view returns (Point memory) {
        return _user_point_history[_user][_epoch];
    }

    function user_point_history__ts(address _user, uint256 _epoch) external view returns (uint256) {
        return _user_point_history[_user][_epoch].ts;
    }

    function locked(address _user) external view returns (LockedBalance memory) {
        return _locked[_user];
    }

    function locked__end(address _user) external view returns (uint256) {
        return _locked[_user].end;
    }

    function point_history(uint256 _epoch) external view returns (Point memory) {
        return _point_history[_epoch];
    }

    function checkpoint() external {
        _checkpoint(address(0), LockedBalance(0, 0), LockedBalance(0, 0));
    }

    function create_lock(uint256 _value, uint256 _unlock_time) external {
        _assert_not_contract(msg.sender);

        // Locktime is rounded down to weeks
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance memory lock = _locked[msg.sender];

        if (_value == 0) {
            revert InvalidDepositAmount();
        }

        if (lock.amount > 0) {
            revert LockAlreadyExists();
        }

        if (unlock_time <= block.timestamp) {
            revert UnlockTimeInPast();
        }

        if (unlock_time > block.timestamp + MAXTIME) {
            revert UnlockTimeAboveMax();
        }

        _deposit_for(msg.sender, _value, unlock_time, lock, DepositType.CREATE_LOCK_TYPE, msg.sender);
    }

    function deposit_for(address _addr, uint256 _value) external {
        LockedBalance memory lock = _locked[_addr];

        if (_value == 0) {
            revert InvalidDepositAmount();
        }

        if (lock.amount == 0) {
            revert LockNotFound();
        }

        if (lock.end <= block.timestamp) {
            revert LockAlreadyExpired();
        }

        _deposit_for(_addr, _value, 0, lock, DepositType.DEPOSIT_FOR_TYPE, msg.sender);
    }

    function increase_amount(uint256 _value) external {
        _assert_not_contract(msg.sender);

        LockedBalance memory lock = _locked[msg.sender];

        if (_value == 0) {
            revert InvalidDepositAmount();
        }

        if (lock.amount == 0) {
            revert LockNotFound();
        }

        if (lock.end <= block.timestamp) {
            revert LockAlreadyExpired();
        }

        _deposit_for(msg.sender, _value, 0, lock, DepositType.INCREASE_LOCK_AMOUNT, msg.sender);
    }

    function increase_unlock_time(uint256 _unlock_time) external {
        _assert_not_contract(msg.sender);

        // Locktime is rounded down to weeks
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance memory lock = _locked[msg.sender];

        if (lock.amount == 0) {
            revert LockNotFound();
        }

        if (lock.end <= block.timestamp) {
            revert LockAlreadyExpired();
        }

        if (unlock_time <= lock.end) {
            revert UnlockTimeInPast();
        }

        if (unlock_time > block.timestamp + MAXTIME) {
            revert UnlockTimeAboveMax();
        }

        _deposit_for(msg.sender, 0, unlock_time, lock, DepositType.INCREASE_UNLOCK_TIME, msg.sender);
    }

    function withdraw() external {
        LockedBalance memory lock = _locked[msg.sender];

        if (lock.end > block.timestamp) {
            revert LockStillActive();
        }

        uint256 value = _int128ToUint256(lock.amount);

        LockedBalance memory old_locked = lock;

        lock.end = 0;
        lock.amount = 0;
        _locked[msg.sender] = lock;

        uint256 supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, old_locked, lock);

        if (!ERC20(token).transfer(msg.sender, value)) {
            revert TransferFailed(address(this), msg.sender, value);
        }

        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function balanceOf(address _addr, uint256 _time) public view returns (uint256) {
        uint256 _epoch = user_point_epoch[_addr];

        if (_epoch == 0) {
            return 0;
        }

        Point memory last_point = _user_point_history[_addr][_epoch];

        last_point.bias -= last_point.slope * _uint256ToInt128(_time - last_point.ts);
        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        return _int128ToUint256(last_point.bias);
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return balanceOf(_addr, block.timestamp);
    }

    function balanceOfAt(address _addr, uint256 _block) external view returns(uint256) {
        return _balanceOfAt(_addr,_block);
    }

    function totalSupply(uint256 _timestamp) public view returns (uint256) {
        Point memory last_point = _point_history[epoch];

        return _supply_at(last_point, _timestamp);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply(block.timestamp);
    }

    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        if (_block > block.number) {
            revert BlockInFuture();
        }

        uint256 _epoch = epoch;
        uint256 target_epoch = _find_block_epoch(_block, _epoch);

        Point memory point = _point_history[target_epoch];
        uint256 dt = 0;
        if (target_epoch < _epoch) {
            Point memory point_next = _point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt = (_block - point.blk) * (point_next.ts - point.ts) / (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt = (_block - point.blk) * (block.timestamp - point.ts) / (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return _supply_at(point, point.ts + dt);
    }

    function _checkpoint(address _user, LockedBalance memory old_locked, LockedBalance memory new_locked) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 current_epoch = epoch;

        if (_user != address(0)) {
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / _uint256ToInt128(MAXTIME);
                u_old.bias = u_old.slope * _uint256ToInt128(old_locked.end - block.timestamp);
            }
            
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / _uint256ToInt128(MAXTIME);
                u_new.bias = u_new.slope * _uint256ToInt128(new_locked.end - block.timestamp);
            }

            old_dslope = slope_changes[old_locked.end];

            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }
        
        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });

        if (current_epoch > 0) {
            last_point = _point_history[current_epoch];
        }

        uint256 last_checkpoint = last_point.ts;

        Point memory initial_last_point = last_point;
        uint256 block_slope = 0;

        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }

        // We need to use block scoping here to prevent `Stack Too Deep` error
        // https://soliditydeveloper.com/stacktoodeep
        {
            uint256 t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint256 i; i < 255; ++i) {
                t_i += WEEK;
                int128 d_slope = 0;

                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }

                last_point.bias -= last_point.slope * _uint256ToInt128(t_i - last_checkpoint);
                last_point.slope += d_slope;

                if (last_point.bias < 0) {
                    last_point.bias = 0;
                }

                if (last_point.slope < 0) {
                    last_point.slope = 0;
                }

                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                current_epoch += 1;

                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    _point_history[current_epoch] = last_point;
                }
            }
        }

        epoch = current_epoch;

        if (_user != address(0)) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        _point_history[current_epoch] = last_point;

        if (_user != address(0)) {
            if (old_locked.end > block.timestamp) {
                old_dslope += u_old.slope;
                if(new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope;
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope;
                    slope_changes[new_locked.end] = new_dslope;
                }
            }

            uint256 user_epoch = user_point_epoch[_user] + 1;
            user_point_epoch[_user] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            _user_point_history[_user][user_epoch] = u_new;
        }
    }

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 _unlock_time,
        LockedBalance memory _locked_balance,
        DepositType _type,
        address _sender
    ) internal {
        LockedBalance memory lock = _locked_balance;
        uint256 supply_before = supply;
        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (lock.amount, lock.end);

        // Adding to existing lock, or if a lock is expired - creating a new one
        lock.amount += _uint256ToInt128(_value);

        if (_unlock_time != 0) {
            lock.end = _unlock_time;
        }

        _locked[_addr] = lock;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_addr, old_locked, lock);

        if (_value != 0) {
            if(!ERC20(token).transferFrom(_sender, address(this), _value)) {
                revert TransferFailed(_sender, address(this), _value);
            }
        }

        emit Deposit(_addr, _value, lock.end, _type, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function _balanceOfAt(address _addr, uint256 _block) internal view returns (uint256) {
        if (_block > block.number) {
            revert BlockInFuture();
        }

        // Binary search
        uint256 _min = 0;
        uint256 _max = user_point_epoch[_addr];
        // Will be always enough for 128-bit numbers
        for (uint256 i; i < 128; ++i) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (_user_point_history[_addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = _user_point_history[_addr][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = _point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (_epoch < max_epoch) {
            Point memory point_1 = _point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += d_t * (_block - point_0.blk) / d_block;
        }

        upoint.bias -= upoint.slope * _uint256ToInt128(block_time - upoint.ts);
        if (upoint.bias >= 0) {
            return _int128ToUint256(upoint.bias);
        } else {
            return 0;
        }
    }

    function _find_block_epoch(uint256 _block, uint256 _max_epoch) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = _max_epoch;
        // Will be always enough for 128-bit numbers
        for (uint256 i; i < 128; ++i) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (_point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function _supply_at(Point memory last_point, uint256 _time) internal view returns (uint256) {
        uint256 t_i = (last_point.ts / WEEK) * WEEK;
        for (uint256 i; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > _time) {
                t_i = _time;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * _uint256ToInt128(t_i - last_point.ts);
            if (t_i == _time) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        return _int128ToUint256(last_point.bias);
    }

    function _assert_not_contract(address _addr) internal view {
        // Caller is an EOA
        if (_addr == tx.origin) {
            return;
        }

        if (whitelist == address(0)) {
            revert InvalidWhitelist();
        }

        if (!IWhitelist(whitelist).check(_addr)) {
            revert Unauthorized();
        }
    }

    function _int128ToUint256(int128 _input) internal pure returns (uint256) {
        return SafeCast.toUint256(int256(_input));
    }

    function _uint256ToInt128(uint256 _input) internal pure returns (int128) {
        return SafeCast.toInt128(
            SafeCast.toInt256(_input)
        );
    }
}