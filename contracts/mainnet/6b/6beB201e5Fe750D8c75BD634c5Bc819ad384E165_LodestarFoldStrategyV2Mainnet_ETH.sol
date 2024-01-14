// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./inheritance/Governable.sol";

import "./interface/IController.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";

import "./RewardForwarder.sol";


contract Controller is Governable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // ========================= Fields =========================

    // external parties
    address public targetToken;
    address public protocolFeeReceiver;
    address public profitSharingReceiver;
    address public rewardForwarder;
    address public universalLiquidator;
    address public dolomiteYieldFarmingRouter;

    uint256 public nextImplementationDelay;

    /// 15% of fees captured go to iFARM stakers
    uint256 public profitSharingNumerator = 700;
    uint256 public nextProfitSharingNumerator = 0;
    uint256 public nextProfitSharingNumeratorTimestamp = 0;

    /// 5% of fees captured go to strategists
    uint256 public strategistFeeNumerator = 0;
    uint256 public nextStrategistFeeNumerator = 0;
    uint256 public nextStrategistFeeNumeratorTimestamp = 0;

    /// 5% of fees captured go to the devs of the platform
    uint256 public platformFeeNumerator = 300;
    uint256 public nextPlatformFeeNumerator = 0;
    uint256 public nextPlatformFeeNumeratorTimestamp = 0;

    /// used for queuing a new delay
    uint256 public tempNextImplementationDelay = 0;
    uint256 public tempNextImplementationDelayTimestamp = 0;

    uint256 public constant MAX_TOTAL_FEE = 3000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    /// @notice This mapping allows certain contracts to stake on a user's behalf
    mapping (address => bool) public addressWhitelist;
    mapping (bytes32 => bool) public codeWhitelist;

    // All eligible hardWorkers that we have
    mapping (address => bool) public hardWorkers;

    // ========================= Events =========================

    event QueueProfitSharingChange(uint profitSharingNumerator, uint validAtTimestamp);
    event ConfirmProfitSharingChange(uint profitSharingNumerator);

    event QueueStrategistFeeChange(uint strategistFeeNumerator, uint validAtTimestamp);
    event ConfirmStrategistFeeChange(uint strategistFeeNumerator);

    event QueuePlatformFeeChange(uint platformFeeNumerator, uint validAtTimestamp);
    event ConfirmPlatformFeeChange(uint platformFeeNumerator);

    event QueueNextImplementationDelay(uint implementationDelay, uint validAtTimestamp);
    event ConfirmNextImplementationDelay(uint implementationDelay);

    event AddedAddressToWhitelist(address indexed _address);
    event RemovedAddressFromWhitelist(address indexed _address);

    event AddedCodeToWhitelist(address indexed _address);
    event RemovedCodeFromWhitelist(address indexed _address);

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ========================= Modifiers =========================

    modifier onlyHardWorkerOrGovernance() {
        require(hardWorkers[msg.sender] || (msg.sender == governance()),
            "only hard worker can call this");
        _;
    }

    constructor(
        address _storage,
        address _targetToken,
        address _protocolFeeReceiver,
        address _profitSharingReceiver,
        address _rewardForwarder,
        address _universalLiquidator,
        uint _nextImplementationDelay
    )
    Governable(_storage)
    public {
        require(_targetToken != address(0), "_targetToken should not be empty");
        require(_protocolFeeReceiver != address(0), "_protocolFeeReceiver should not be empty");
        require(_profitSharingReceiver != address(0), "_profitSharingReceiver should not be empty");
        require(_rewardForwarder != address(0), "_rewardForwarder should not be empty");
        require(_nextImplementationDelay > 0, "_nextImplementationDelay should be gt 0");

        targetToken = _targetToken;
        protocolFeeReceiver = _protocolFeeReceiver;
        profitSharingReceiver = _profitSharingReceiver;
        rewardForwarder = _rewardForwarder;
        universalLiquidator = _universalLiquidator;
        nextImplementationDelay = _nextImplementationDelay;
    }

        // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    function greyList(address _addr) public view returns (bool) {
        return !addressWhitelist[_addr] && !codeWhitelist[getContractHash(_addr)];
    }

    // Only smart contracts will be affected by the whitelist.
    function addToWhitelist(address _target) public onlyGovernance {
        addressWhitelist[_target] = true;
        emit AddedAddressToWhitelist(_target);
    }

    function addMultipleToWhitelist(address[] memory _targets) public onlyGovernance {
        for (uint256 i = 0; i < _targets.length; i++) {
        addressWhitelist[_targets[i]] = true;
        }
    }

    function removeFromWhitelist(address _target) public onlyGovernance {
        addressWhitelist[_target] = false;
        emit RemovedAddressFromWhitelist(_target);
    }

    function removeMultipleFromWhitelist(address[] memory _targets) public onlyGovernance {
        for (uint256 i = 0; i < _targets.length; i++) {
        addressWhitelist[_targets[i]] = false;
        }
    }

    function getContractHash(address a) public view returns (bytes32 hash) {
        assembly {
        hash := extcodehash(a)
        }
    }

    function addCodeToWhitelist(address _target) public onlyGovernance {
        codeWhitelist[getContractHash(_target)] = true;
        emit AddedCodeToWhitelist(_target);
    }

    function removeCodeFromWhitelist(address _target) public onlyGovernance {
        codeWhitelist[getContractHash(_target)] = false;
        emit RemovedCodeFromWhitelist(_target);
    }

    function setRewardForwarder(address _rewardForwarder) public onlyGovernance {
        require(_rewardForwarder != address(0), "new reward forwarder should not be empty");
        rewardForwarder = _rewardForwarder;
    }

    function setTargetToken(address _targetToken) public onlyGovernance {
        require(_targetToken != address(0), "new target token should not be empty");
        targetToken = _targetToken;
    }

    function setProfitSharingReceiver(address _profitSharingReceiver) public onlyGovernance {
        require(_profitSharingReceiver != address(0), "new profit sharing receiver should not be empty");
        profitSharingReceiver = _profitSharingReceiver;
    }

    function setProtocolFeeReceiver(address _protocolFeeReceiver) public onlyGovernance {
        require(_protocolFeeReceiver != address(0), "new protocol fee receiver should not be empty");
        protocolFeeReceiver = _protocolFeeReceiver;
    }

    function setUniversalLiquidator(address _universalLiquidator) public onlyGovernance {
        require(_universalLiquidator != address(0), "new universal liquidator should not be empty");
        universalLiquidator = _universalLiquidator;
    }

    function setDolomiteYieldFarmingRouter(address _dolomiteYieldFarmingRouter) public onlyGovernance {
        require(_dolomiteYieldFarmingRouter != address(0), "new reward forwarder should not be empty");
        dolomiteYieldFarmingRouter = _dolomiteYieldFarmingRouter;
    }

    function getPricePerFullShare(address _vault) public view returns (uint256) {
        return IVault(_vault).getPricePerFullShare();
    }

    function doHardWork(address _vault) external onlyHardWorkerOrGovernance {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        emit SharePriceChangeLog(
            _vault,
            IVault(_vault).strategy(),
            oldSharePrice,
            IVault(_vault).getPricePerFullShare(),
            block.timestamp
        );
    }

    function addHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) public onlyGovernance {
        require(_worker != address(0), "_worker must be defined");
        hardWorkers[_worker] = false;
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(address _strategy, address _token, uint256 _amount) external onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvageable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvageToken(governance(), _token, _amount);
    }

    function feeDenominator() public pure returns (uint) {
        // keep the interface for this function as a `view` for now, in case it changes in the future
        return FEE_DENOMINATOR;
    }

    function setProfitSharingNumerator(uint _profitSharingNumerator) public onlyGovernance {
        require(
            _profitSharingNumerator + strategistFeeNumerator + platformFeeNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        nextProfitSharingNumerator = _profitSharingNumerator;
        nextProfitSharingNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueProfitSharingChange(nextProfitSharingNumerator, nextProfitSharingNumeratorTimestamp);
    }

    function confirmSetProfitSharingNumerator() public onlyGovernance {
        require(
            nextProfitSharingNumerator != 0
            && nextProfitSharingNumeratorTimestamp != 0
            && block.timestamp >= nextProfitSharingNumeratorTimestamp,
            "invalid timestamp or no new profit sharing numerator confirmed"
        );
        require(
            nextProfitSharingNumerator + strategistFeeNumerator + platformFeeNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        profitSharingNumerator = nextProfitSharingNumerator;
        nextProfitSharingNumerator = 0;
        nextProfitSharingNumeratorTimestamp = 0;
        emit ConfirmProfitSharingChange(profitSharingNumerator);
    }

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) public onlyGovernance {
        require(
            _strategistFeeNumerator + platformFeeNumerator + profitSharingNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        nextStrategistFeeNumerator = _strategistFeeNumerator;
        nextStrategistFeeNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueStrategistFeeChange(nextStrategistFeeNumerator, nextStrategistFeeNumeratorTimestamp);
    }

    function confirmSetStrategistFeeNumerator() public onlyGovernance {
        require(
            nextStrategistFeeNumerator != 0
            && nextStrategistFeeNumeratorTimestamp != 0
            && block.timestamp >= nextStrategistFeeNumeratorTimestamp,
            "invalid timestamp or no new strategist fee numerator confirmed"
        );
        require(
            nextStrategistFeeNumerator + platformFeeNumerator + profitSharingNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        strategistFeeNumerator = nextStrategistFeeNumerator;
        nextStrategistFeeNumerator = 0;
        nextStrategistFeeNumeratorTimestamp = 0;
        emit ConfirmStrategistFeeChange(strategistFeeNumerator);
    }

    function setPlatformFeeNumerator(uint _platformFeeNumerator) public onlyGovernance {
        require(
            _platformFeeNumerator + strategistFeeNumerator + profitSharingNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        nextPlatformFeeNumerator = _platformFeeNumerator;
        nextPlatformFeeNumeratorTimestamp = block.timestamp + nextImplementationDelay;
        emit QueuePlatformFeeChange(nextPlatformFeeNumerator, nextPlatformFeeNumeratorTimestamp);
    }

    function confirmSetPlatformFeeNumerator() public onlyGovernance {
        require(
            nextPlatformFeeNumerator != 0
            && nextPlatformFeeNumeratorTimestamp != 0
            && block.timestamp >= nextPlatformFeeNumeratorTimestamp,
            "invalid timestamp or no new platform fee numerator confirmed"
        );
        require(
            nextPlatformFeeNumerator + strategistFeeNumerator + profitSharingNumerator <= MAX_TOTAL_FEE,
            "total fee too high"
        );

        platformFeeNumerator = nextPlatformFeeNumerator;
        nextPlatformFeeNumerator = 0;
        nextPlatformFeeNumeratorTimestamp = 0;
        emit ConfirmPlatformFeeChange(platformFeeNumerator);
    }

    function setNextImplementationDelay(uint256 _nextImplementationDelay) public onlyGovernance {
        require(
            _nextImplementationDelay > 0,
            "invalid _nextImplementationDelay"
        );

        tempNextImplementationDelay = _nextImplementationDelay;
        tempNextImplementationDelayTimestamp = block.timestamp + nextImplementationDelay;
        emit QueueNextImplementationDelay(tempNextImplementationDelay, tempNextImplementationDelayTimestamp);
    }

    function confirmNextImplementationDelay() public onlyGovernance {
        require(
            tempNextImplementationDelayTimestamp != 0 && block.timestamp >= tempNextImplementationDelayTimestamp,
            "invalid timestamp or no new implementation delay confirmed"
        );
        nextImplementationDelay = tempNextImplementationDelay;
        tempNextImplementationDelay = 0;
        tempNextImplementationDelayTimestamp = 0;
        emit ConfirmNextImplementationDelay(nextImplementationDelay);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IPoolFactory {
  function deploy(address _storage, address _vault) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IStrategyFactory {
  function deploy(address _storage, address _vault, address _providedStrategyAddress) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVaultFactory {
  function deploy(address _storage, address _underlying) external returns (address);
  function info(address vault) external view returns(address Underlying, address NewVault);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IStrategyFactory.sol";
import "./interface/IVaultFactory.sol";
import "./interface/IPoolFactory.sol";

import "../interface/IVault.sol";
import "../inheritance/Governable.sol";

contract MegaFactory is Ownable {

  enum VaultType {
    None,
    Regular
  }

  enum StrategyType {
    None,
    Upgradable
  }

  address public potPoolFactory;
  mapping(uint256 => address) public vaultFactories;
  mapping(uint256 => address) public strategyFactories;

  struct CompletedDeployment {
    VaultType vaultType;
    address Underlying;
    address NewVault;
    address NewStrategy;
    address NewPool;
  }

  event DeploymentCompleted(string id);

  mapping (string => CompletedDeployment) public completedDeployments;
  mapping (address => bool) public authorizedDeployers;

  address public multisig;
  address public actualStorage;

  /* methods to make compatible with Storage */
  function governance() external view returns (address) {
    return address(this); // fake governance
  }

  function isGovernance(address addr) external view returns (bool) {
    return addr == address(this); // fake governance
  }

  function isController(address addr) external view returns (bool) {
    return addr == address(this); // fake controller
  }

  modifier onlyAuthorizedDeployer(string memory id) {
    require(completedDeployments[id].vaultType == VaultType.None, "cannot reuse id");
    require(authorizedDeployers[msg.sender], "unauthorized deployer");
    _;
    emit DeploymentCompleted(id);
  }

  constructor(address _storage, address _multisig) public {
    multisig = _multisig;
    actualStorage = _storage;
    setAuthorization(owner(), true);
    setAuthorization(multisig, true);
  }

  function setAuthorization(address userAddress, bool isDeployer) public onlyOwner {
    authorizedDeployers[userAddress] = isDeployer;
  }

  function setVaultFactory(uint256 vaultType, address factoryAddress) external onlyOwner {
    vaultFactories[vaultType] = factoryAddress;
  }

  function setStrategyFactory(uint256 strategyType, address factoryAddress) external onlyOwner {
    strategyFactories[strategyType] = factoryAddress;
  }

  function setPotPoolFactory(address factoryAddress) external onlyOwner {
    potPoolFactory = factoryAddress;
  }

  function createRegularVault(string calldata id, address underlying) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     actualStorage,
     underlying
    );

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      address(0),
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }

  function createRegularVaultUsingUpgradableStrategy(string calldata id, address underlying, address strategyImplementation) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     address(this), // using this as initial storage, then switching to actualStorage
     underlying
    );

    address strategy = IStrategyFactory(strategyFactories[uint256(StrategyType.Upgradable)]).deploy(actualStorage, vault, strategyImplementation);
    IVault(vault).setStrategy(strategy);
    Governable(vault).setStorage(actualStorage);

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      strategy,
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../inheritance/Governable.sol";
import "../../inheritance/OwnableWhitelist.sol";
import "../interface/IPoolFactory.sol";
import "../../PotPool.sol";

contract PotPoolFactory is OwnableWhitelist, IPoolFactory {
  address public iFARM = 0x9dCA587dc65AC0a043828B0acd946d71eb8D46c1;
  uint256 public poolDefaultDuration = 604800; // 7 days

  function setPoolDefaultDuration(uint256 _value) external onlyOwner {
    poolDefaultDuration = _value;
  }

  function deploy(address actualStorage, address vault) override external onlyWhitelisted returns (address) {
    address actualGovernance = Governable(vault).governance();

    string memory tokenSymbol = ERC20(vault).symbol();
    address[] memory rewardDistribution = new address[](1);
    rewardDistribution[0] = actualGovernance;
    address[] memory rewardTokens = new address[](1);
    rewardTokens[0] = iFARM;
    PotPool pool = new PotPool(
      rewardTokens,
      vault,
      poolDefaultDuration,
      rewardDistribution,
      actualStorage,
      string(abi.encodePacked("p", tokenSymbol)),
      string(abi.encodePacked("p", tokenSymbol)),
      ERC20(vault).decimals()
    );

    Ownable(pool).transferOwnership(actualGovernance);

    return address(pool);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../interface/IStrategyFactory.sol";
import "../../upgradability/StrategyProxy.sol";
import "../../inheritance/OwnableWhitelist.sol";

interface IInitializableStrategy {
  function initializeStrategy(address _storage, address _vault) external;
}

contract UpgradableStrategyFactory is OwnableWhitelist, IStrategyFactory {
  function deploy(address actualStorage, address vault, address upgradableStrategyImplementation) override external onlyWhitelisted returns (address) {
    StrategyProxy proxy = new StrategyProxy(upgradableStrategyImplementation);
    IInitializableStrategy strategy = IInitializableStrategy(address(proxy));
    strategy.initializeStrategy(actualStorage, vault);
    return address(proxy);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../VaultProxy.sol";
import "../../interface/IVault.sol";
import "../interface/IVaultFactory.sol";
import "../../inheritance/OwnableWhitelist.sol";

contract RegularVaultFactory is OwnableWhitelist, IVaultFactory {
  address public vaultImplementation = 0x54Cbc624F1648AC4820b960EFde9574B25386cFD;
  address public lastDeployedAddress = address(0);

  function deploy(address _storage, address underlying) override external onlyWhitelisted returns (address) {
    lastDeployedAddress = address(new VaultProxy(vaultImplementation));
    IVault(lastDeployedAddress).initializeVault(
      _storage,
      underlying,
      10000,
      10000
    );

    return lastDeployedAddress;
  }

  function changeDefaultImplementation(address newImplementation) external onlyOwner {
    require(newImplementation != address(0), "Must be set");
    vaultImplementation = newImplementation;
  }

  function info(address vault) override external view returns(address Underlying, address NewVault) {
    Underlying = IVault(vault).underlying();
    NewVault = vault;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../inheritance/Controllable.sol";
import "../interface/IGlobalIncentivesHelper.sol";

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract GlobalIncentivesExecutor is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  mapping (address => bool) public notifier;
  mapping (address => bool) public changer;

  address[] public tokens;
  uint256[] public totals;
  address public globalIncentivesHelper;
  uint256 public mostRecentWeeksEmissionTimestamp;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender] || msg.sender == governance(), "Only notifier");
    _;
  }

  constructor(address _storage, address _globalIncentivesHelper) public Controllable(_storage) {
    globalIncentivesHelper = _globalIncentivesHelper;
  }

  function updateData(
    address[] calldata _tokens,
    uint256[] calldata _totals,
    uint256 baseTimestamp
  ) external onlyChanger {
    tokens = _tokens;
    totals = _totals;
    if (baseTimestamp > 0) {
      // 0 means "do not reset"
      mostRecentWeeksEmissionTimestamp = baseTimestamp;
    } else {
      require(mostRecentWeeksEmissionTimestamp > 0, "you have to configure mostRecentWeeksEmissionTimestamp");
    }
  }

  function execute() external onlyNotifier {
    require(mostRecentWeeksEmissionTimestamp > 0, "mostRecentWeeksEmissionTimestamp was never configured");
    require(mostRecentWeeksEmissionTimestamp.add(1 weeks) <= block.timestamp, "too early");
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 globalIncentivesHelperBalance = IERC20Upgradeable(tokens[i]).balanceOf(globalIncentivesHelper);
      require(globalIncentivesHelperBalance >= totals[i], "not enough balance");
    }
    mostRecentWeeksEmissionTimestamp = mostRecentWeeksEmissionTimestamp.add(1 weeks);
    IGlobalIncentivesHelper(globalIncentivesHelper).notifyPools(tokens, totals, mostRecentWeeksEmissionTimestamp);
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./NotifyHelperStateful.sol";
import "./NotifyHelperGeneric.sol";
import "../inheritance/Controllable.sol";

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract GlobalIncentivesHelper is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public helperControlStorage;
  address public notifyHelperGeneric;
  address public escrow;
  address public reserve;
  address public farm;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  mapping (address => address) public tokenToHelper;
  mapping (address => bool) public changer;
  mapping (address => bool) public notifier;

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender] || msg.sender == governance(), "Only notifier");
    _;
  }

  constructor(
    address _storage,
    address _farm,
    address _farmHelper,
    address _notifyHelperGeneric,
    address _escrow,
    address _reserve
    ) public Controllable(_storage) {
    tokenToHelper[_farm] = _farmHelper;
    farm = _farm;
    notifyHelperGeneric = _notifyHelperGeneric;
    helperControlStorage = address(new Storage());
    escrow = _escrow;
    reserve = _reserve;
  }

  function notifyPools(address[] calldata tokens, uint256[] calldata totals, uint256 timestamp) external onlyNotifier {
    for (uint256 i = 0; i < tokens.length; i++) {
      // IERC20Upgradeable(tokens[i]).safeTransferFrom(msg.sender, address(this), totals[i]);
      IERC20Upgradeable(tokens[i]).approve(tokenToHelper[tokens[i]], totals[i]);
      NotifyHelperStateful(tokenToHelper[tokens[i]]).notifyPools(totals[i], timestamp);
    }
  }

  // uses generic helper
  function newToken(address token) external onlyChanger {
    newTokenWithHelper(token, notifyHelperGeneric);
  }

  // uses a specific notify helper
  function newTokenWithHelper(address token, address notifyHelper) public onlyChanger {
    require(tokenToHelper[token] == address(0), "Token already initialized");
    tokenToHelper[token] = address(new NotifyHelperStateful(
      helperControlStorage,
      notifyHelper, // the universal helper should be sufficient in all cases
      token,
      address(0), // no iFARM/ampliFARM notify helper is needed
      escrow,
      reserve
    ));
    if (notifyHelper == notifyHelperGeneric) {
      NotifyHelperGeneric(notifyHelper).setWhitelist(tokenToHelper[token], true);
    }
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setNotifier(governance(), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(address(this), true);
    NotifyHelperStateful(tokenToHelper[token]).setChanger(governance(), true);
  }

  function resetToken(address token) public onlyChanger {
    tokenToHelper[token] = address(0);
  }

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(
    address[] calldata tokens,
    address[] calldata poolAddress,
    uint256[] calldata poolPercentage,
    NotificationType[] calldata notificationType,
    bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(tokens[i], poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(
    address token,
    address poolAddress,
    uint256 poolPercentage,
    NotificationType notificationType,
    bool vests
  ) public onlyChanger {
    if (token == farm) {
      require(notificationType != NotificationType.TOKEN, "With FARM, use FARM, AMPLIFARM, or TRANSFER");
    }
    if (notificationType == NotificationType.TOKEN) {
      // we use type translation so that we can use the same contract
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(NotificationType.FARM)), vests);
    } else {
      NotifyHelperStateful(tokenToHelper[token]).setPool(poolAddress, poolPercentage,
        NotifyHelperStateful.NotificationType(uint256(notificationType)), vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address token, address _escrow) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVestingEscrow(_escrow);
  }

  /// Configuration method for vesting for governance
  function setVesting(address token, uint256 _numerator, uint256 _denominator) external onlyGovernance {
    NotifyHelperStateful(tokenToHelper[token]).setVesting(_numerator, _denominator);
  }

  function notificationExists(address token, address poolAddress) public view returns(bool) {
    return NotifyHelperStateful(tokenToHelper[token]).notificationExists(poolAddress);
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../inheritance/Controllable.sol";
import "../PotPool.sol";

contract NotifyHelperGeneric is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event WhitelistSet(address who, bool value);

  mapping (address => bool) public alreadyNotified;
  mapping (address => bool) public whitelist;

  modifier onlyWhitelisted {
    require(whitelist[msg.sender] || msg.sender == governance(), "Only whitelisted");
    _;
  }

  constructor(address _storage)
  Controllable(_storage) public {
    setWhitelist(governance(), true);
  }

  function setWhitelist(address who, bool value) public onlyWhitelisted {
    whitelist[who] = value;
    emit WhitelistSet(who, value);
  }

  /**
  * Notifies all the pools, safe guarding the notification amount.
  */
  function notifyPools(uint256[] memory amounts,
    address[] memory pools,
    uint256 sum, address _token
  ) public onlyWhitelisted {
    require(amounts.length == pools.length, "Amounts and pools lengths mismatch");
    for (uint i = 0; i < pools.length; i++) {
      alreadyNotified[pools[i]] = false;
    }

    uint256 check = 0;
    for (uint i = 0; i < pools.length; i++) {
      require(amounts[i] > 0, "Notify zero");
      require(!alreadyNotified[pools[i]], "Duplicate pool");
      IERC20Upgradeable token = IERC20Upgradeable(_token);
      token.safeTransferFrom(msg.sender, pools[i], amounts[i]);
      PotPool(pools[i]).notifyTargetRewardAmount(_token, amounts[i]);
      check = check.add(amounts[i]);
      alreadyNotified[pools[i]] = true;
    }
    require(sum == check, "Wrong check sum");
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../inheritance/Controllable.sol";
import "../PotPool.sol";

interface INotifyHelperGeneric {
  function feeRewardForwarder() external view returns (address);

  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum, address token
  ) external;
}

interface INotifyHelperAmpliFARM {
  function notifyPools(uint256[] calldata amounts,
    address[] calldata pools,
    uint256 sum
  ) external;
}

contract NotifyHelperStateful is Controllable {

  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ChangerSet(address indexed account, bool value);
  event NotifierSet(address indexed account, bool value);
  event Vesting(address pool, uint256 amount);
  event PoolChanged(address indexed pool, uint256 percentage, uint256 notificationType, bool vests);

  enum NotificationType {
    VOID, AMPLIFARM, FARM, TRANSFER, PROFIT_SHARE, TOKEN
  }

  struct Notification {
    address poolAddress;
    NotificationType notificationType;
    uint256 percentage;
    bool vests;
  }

  struct WorkingNotification {
    address[] pools;
    uint256[] amounts;
    uint256 checksum;
    uint256 counter;
  }

  uint256 public VESTING_DENOMINATOR = 3;
  uint256 public VESTING_NUMERATOR = 2;

  mapping (address => bool) changer;
  mapping (address => bool) notifier;

  address public notifyHelperRegular;
  address public notifyHelperAmpliFARM;
  address public rewardToken;

  Notification[] public notifications;
  mapping (address => uint256) public poolToIndex;
  mapping (uint256 => uint256) public numbers; // NotificationType to the number of pools

  address public reserve;
  address public vestingEscrow;
  uint256 public totalPercentage; // maintain state to not have to calculate during emissions

  modifier onlyChanger {
    require(changer[msg.sender] || msg.sender == governance(), "Only changer");
    _;
  }

  modifier onlyNotifier {
    require(notifier[msg.sender], "Only notifier");
    _;
  }

  constructor(address _storage,
    address _notifyHelperRegular,
    address _rewardToken,
    address _notifyHelperAmpliFARM,
    address _escrow,
    address _reserve)
  Controllable(_storage) public {
    // used for getting a reference to FeeRewardForwarder
    notifyHelperRegular = _notifyHelperRegular;
    rewardToken = _rewardToken;
    notifyHelperAmpliFARM = _notifyHelperAmpliFARM;
    vestingEscrow = _escrow;
    reserve = _reserve;
    require(_reserve != address(0), "invalid reserve");
    require(_escrow != address(0), "invalid escrow");
  }

  /// Whitelisted entities can notify pools based on the state, both for FARM and iFARM
  /// The only whitelisted entity here would be the minter helper
  function notifyPools(uint256 total, uint256 timestamp) public onlyNotifier {
    // transfer the tokens from the msg.sender to here
    IERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, address(this), total);

    // prepare the notification data
    WorkingNotification memory ampliFARM = WorkingNotification(
      new address[](numbers[uint256(NotificationType.AMPLIFARM)]),
      new uint256[](numbers[uint256(NotificationType.AMPLIFARM)]),
      0,
      0
    );
    WorkingNotification memory regular = WorkingNotification(
      new address[](numbers[uint256(NotificationType.FARM)]),
      new uint256[](numbers[uint256(NotificationType.FARM)]),
      0,
      0
    );
    uint256 vestingAmount = 0;
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      if (notification.notificationType == NotificationType.TRANSFER) {
        // simple transfer
        IERC20Upgradeable(rewardToken).safeTransfer(
          notification.poolAddress,
          total.mul(notification.percentage).div(totalPercentage)
        );
      } else {
        // FARM or ampliFARM notification
        WorkingNotification memory toUse = notification.notificationType == NotificationType.FARM ? regular : ampliFARM;
        toUse.amounts[toUse.counter] = total.mul(notification.percentage).div(totalPercentage);
        if (notification.vests) {
          uint256 toVest = toUse.amounts[toUse.counter].mul(VESTING_NUMERATOR).div(VESTING_DENOMINATOR);
          toUse.amounts[toUse.counter] = toUse.amounts[toUse.counter].sub(toVest);
          vestingAmount = vestingAmount.add(toVest);
          emit Vesting(notification.poolAddress, toVest);
        }
        toUse.pools[toUse.counter] = notification.poolAddress;
        toUse.checksum = toUse.checksum.add(toUse.amounts[toUse.counter]);
        toUse.counter = toUse.counter.add(1);
      }
    }

    // handle vesting
    if (vestingAmount > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(vestingEscrow, vestingAmount);
    }

    // ampliFARM notifications
    if (ampliFARM.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperAmpliFARM, ampliFARM.checksum);
      INotifyHelperAmpliFARM(notifyHelperAmpliFARM).notifyPools(ampliFARM.amounts, ampliFARM.pools, ampliFARM.checksum);
    }

    // regular notifications
    if (regular.checksum > 0) {
      IERC20Upgradeable(rewardToken).approve(notifyHelperRegular, regular.checksum);
      INotifyHelperGeneric(notifyHelperRegular).notifyPools(
        regular.amounts, regular.pools, regular.checksum, rewardToken
      );
    }

    // send rest to the reserve
    uint256 remainingBalance = IERC20Upgradeable(rewardToken).balanceOf(address(this));
    if (remainingBalance > 0) {
      IERC20Upgradeable(rewardToken).safeTransfer(reserve, remainingBalance);
    }
  }

  /// Returning the governance
  function transferGovernance(address target, address newStorage) external onlyGovernance {
    Governable(target).setStorage(newStorage);
  }

  /// The governance configures whitelists
  function setChanger(address who, bool value) external onlyGovernance {
    changer[who] = value;
    emit ChangerSet(who, value);
  }

  /// The governance configures whitelists
  function setNotifier(address who, bool value) external onlyGovernance {
    notifier[who] = value;
    emit NotifierSet(who, value);
  }

  /// Whitelisted entity makes changes to the notifications
  function setPoolBatch(address[] calldata poolAddress, uint256[] calldata poolPercentage, NotificationType[] calldata notificationType, bool[] calldata vests) external onlyChanger {
    for (uint256 i = 0; i < poolAddress.length; i++) {
      setPool(poolAddress[i], poolPercentage[i], notificationType[i], vests[i]);
    }
  }

  /// Pool management, adds, updates or removes a transfer/notification
  function setPool(address poolAddress, uint256 poolPercentage, NotificationType notificationType, bool vests) public onlyChanger {
    require(notificationType != NotificationType.VOID, "Use valid indication");
    require(notificationType != NotificationType.TOKEN, "We do not use TOKEN here");
    if (notificationExists(poolAddress) && poolPercentage == 0) {
      // remove
      removeNotification(poolAddress);
    } else if (notificationExists(poolAddress)) {
      // update
      updateNotification(poolAddress, notificationType, poolPercentage, vests);
    } else if (poolPercentage > 0) {
      // add because it does not exist
      addNotification(poolAddress, poolPercentage, notificationType, vests);
    }
    emit PoolChanged(poolAddress, poolPercentage, uint256(notificationType), vests);
  }

  /// Configuration method for vesting for governance
  function setVestingEscrow(address _escrow) external onlyGovernance {
    vestingEscrow = _escrow;
  }

  /// Configuration method for vesting for governance
  function setVesting(uint256 _numerator, uint256 _denominator) external onlyGovernance {
    VESTING_DENOMINATOR = _numerator;
    VESTING_NUMERATOR = _denominator;
  }

  function notificationExists(address poolAddress) public view returns(bool) {
    if (notifications.length == 0) return false;
    if (poolToIndex[poolAddress] != 0) return true;
    return (notifications[0].poolAddress == poolAddress);
  }

  function removeNotification(address poolAddress) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    uint256 index = poolToIndex[poolAddress];
    Notification storage notification = notifications[index];

    totalPercentage = totalPercentage.sub(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].sub(1);

    // move the last element here and pop from the array
    notifications[index] = notifications[notifications.length.sub(1)];
    poolToIndex[notifications[index].poolAddress] = index;
    poolToIndex[poolAddress] = 0;
    notifications.pop();
  }

  function updateNotification(address poolAddress, NotificationType notificationType, uint256 percentage, bool vesting) internal {
    require(notificationExists(poolAddress), "notification does not exist");
    require(percentage > 0, "notification is 0");
    uint256 index = poolToIndex[poolAddress];
    totalPercentage = totalPercentage.sub(notifications[index].percentage).add(percentage);
    notifications[index].percentage = percentage;
    notifications[index].vests = vesting;
    if (notifications[index].notificationType != notificationType) {
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].sub(1);
      notifications[index].notificationType = notificationType;
      numbers[uint256(notifications[index].notificationType)] = numbers[uint256(notifications[index].notificationType)].add(1);
    }
  }

  function addNotification(address poolAddress, uint256 percentage, NotificationType notificationType, bool vesting) internal {
    require(!notificationExists(poolAddress), "notification exists");
    require(percentage > 0, "notification is 0");
    require(PotPool(poolAddress).getRewardTokenIndex(rewardToken) != uint256(-1), "Token not configured on pot pool");
    Notification memory notification = Notification(poolAddress, notificationType, percentage, vesting);
    notifications.push(notification);
    totalPercentage = totalPercentage.add(notification.percentage);
    numbers[uint256(notification.notificationType)] = numbers[uint256(notification.notificationType)].add(1);
    poolToIndex[notification.poolAddress] = notifications.length.sub(1);
    require(notificationExists(poolAddress), "notification was not added");
  }

  /// emergency draining of tokens and ETH as there should be none staying here
  function emergencyDrain(address token, uint256 amount) public onlyGovernance {
    if (token == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
    }
  }

  function getConfig(uint256 totalAmount) external view returns(address[] memory, uint256[] memory, uint256[] memory) {
    address[] memory pools = new address[](notifications.length);
    uint256[] memory percentages = new uint256[](notifications.length);
    uint256[] memory amounts = new uint256[](notifications.length);
    for (uint256 i = 0; i < notifications.length; i++) {
      Notification storage notification = notifications[i];
      pools[i] = notification.poolAddress;
      percentages[i] = notification.percentage.mul(1000000).div(totalPercentage);
      amounts[i] = notification.percentage.mul(totalAmount).div(totalPercentage);
    }
    return (pools, percentages, amounts);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./NotifyHelperStateful.sol";

contract ViewerNotifyHelperStateful {

  /// configuration check method
  function getConfig(address helper, uint256 totalAmount)
  external view returns(address[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
    (
    address[] memory pools,
    uint256[] memory percentages,
    uint256[] memory amounts
    ) = NotifyHelperStateful(helper).getConfig(totalAmount);

    uint256[] memory types = new uint256[](pools.length);
    for (uint256 i = 0; i < pools.length; i++) {
      (, NotifyHelperStateful.NotificationType notificationType, , ) = NotifyHelperStateful(helper).notifications(i);
      types[i] = uint256(notificationType);
    }

    return (pools, percentages, amounts, types);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./Governable.sol";

contract Controllable is Governable {

  constructor(address _storage) public Governable(_storage) {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../upgradability/ReentrancyGuardUpgradeable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is ReentrancyGuardUpgradeable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
    ReentrancyGuardUpgradeable.initialize();
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableWhitelist is Ownable {
  mapping (address => bool) public whitelist;

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender] || msg.sender == owner(), "not allowed");
    _;
  }

  function setWhitelist(address target, bool isWhitelisted) public onlyOwner {
    whitelist[target] = isWhitelisted;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	enum InterestRateMode {
		NONE,
		STABLE,
		VARIABLE
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
	event RewardsAccrued(address indexed user, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

	event ClaimerSet(address indexed user, address indexed claimer);

	/*
	 * @dev Returns the configuration of the distribution for a certain asset
	 * @param asset The address of the reference asset of the distribution
	 * @return The asset index, the emission per second and the last updated timestamp
	 **/
	function getAssetData(address asset) external view returns (uint256, uint256, uint256);

	/**
	 * @dev Whitelists an address to claim the rewards on behalf of another address
	 * @param user The address of the user
	 * @param claimer The address of the claimer
	 */
	function setClaimer(address user, address claimer) external;

	/**
	 * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
	 * @param user The address of the user
	 * @return The claimer address
	 */
	function getClaimer(address user) external view returns (address);

	/**
	 * @dev Configure assets for a certain rewards emission
	 * @param assets The assets to incentivize
	 * @param emissionsPerSecond The emission for each asset
	 */
	function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
	 * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
	 * @param amount Amount of rewards to claim
	 * @param user Address to check and claim rewards
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewardsOnBehalf(
		address[] calldata assets,
		uint256 amount,
		address user,
		address to
	) external returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @return the unclaimed user rewards
	 */
	function getUserUnclaimedRewards(address user) external view returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @param asset The asset to incentivize
	 * @return the user index for the asset
	 */
	function getUserAssetData(address user, address asset) external view returns (uint256);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function REWARD_TOKEN() external view returns (address);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function PRECISION() external view returns (uint8);

	/**
	 * @dev Gets the distribution end timestamp of the emissions
	 */
	function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IScaledBalanceToken.sol";
import "./IInitializableAToken.sol";
import "./IAaveIncentivesController.sol";

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
	/**
	 * @dev Emitted after the mint action
	 * @param from The address performing the mint
	 * @param value The amount being
	 * @param index The new liquidity index of the reserve
	 **/
	event Mint(address indexed from, uint256 value, uint256 index);

	/**
	 * @dev Mints `amount` aTokens to `user`
	 * @param user The address receiving the minted tokens
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 * @return `true` if the the previous balance of the user was 0
	 */
	function mint(address user, uint256 amount, uint256 index) external returns (bool);

	/**
	 * @dev Emitted after aTokens are burned
	 * @param from The owner of the aTokens, getting them burned
	 * @param target The address that will receive the underlying
	 * @param value The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

	/**
	 * @dev Emitted during the transfer action
	 * @param from The user whose tokens are being transferred
	 * @param to The recipient
	 * @param value The amount being transferred
	 * @param index The new liquidity index of the reserve
	 **/
	event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

	/**
	 * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
	 * @param user The owner of the aTokens, getting them burned
	 * @param receiverOfUnderlying The address that will receive the underlying
	 * @param amount The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

	/**
	 * @dev Mints aTokens to the reserve treasury
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 */
	function mintToTreasury(uint256 amount, uint256 index) external;

	/**
	 * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
	 * @param from The address getting liquidated, current owner of the aTokens
	 * @param to The recipient
	 * @param value The amount of tokens getting transferred
	 **/
	function transferOnLiquidation(address from, address to, uint256 value) external;

	/**
	 * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
	 * assets in borrow(), withdraw() and flashLoan()
	 * @param user The recipient of the underlying
	 * @param amount The amount getting transferred
	 * @return The amount transferred
	 **/
	function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

	/**
	 * @dev Invoked to execute actions on the aToken side after a repayment.
	 * @param user The user executing the repayment
	 * @param amount The amount getting repaid
	 **/
	function handleRepayment(address user, uint256 amount) external;

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);

	/**
	 * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 **/
	function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./ILendingPool.sol";
import "./IAaveIncentivesController.sol";

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
	/**
	 * @dev Emitted when an aToken is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param treasury The address of the treasury
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param aTokenDecimals the decimals of the underlying
	 * @param aTokenName the name of the aToken
	 * @param aTokenSymbol the symbol of the aToken
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address treasury,
		address incentivesController,
		uint8 aTokenDecimals,
		string aTokenName,
		string aTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the aToken
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param treasury The address of the Aave treasury, receiving the fees on this aToken
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
	 * @param aTokenName The name of the aToken
	 * @param aTokenSymbol The symbol of the aToken
	 */
	function initialize(
		ILendingPool pool,
		address treasury,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 aTokenDecimals,
		string calldata aTokenName,
		string calldata aTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./ILendingPool.sol";
import "./IAaveIncentivesController.sol";

/**
 * @title IInitializableDebtToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Aave
 **/
interface IInitializableDebtToken {
	/**
	 * @dev Emitted when a debt token is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param debtTokenDecimals the decimals of the debt token
	 * @param debtTokenName the name of the debt token
	 * @param debtTokenSymbol the symbol of the debt token
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address incentivesController,
		uint8 debtTokenDecimals,
		string debtTokenName,
		string debtTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the debt token.
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
	 * @param debtTokenName The name of the token
	 * @param debtTokenSymbol The symbol of the token
	 */
	function initialize(
		ILendingPool pool,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 debtTokenDecimals,
		string memory debtTokenName,
		string memory debtTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ILendingPoolAddressesProvider.sol";
import "./DataTypes.sol";

interface ILendingPool {
	/**
	 * @dev Emitted on deposit()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
	 * @param amount The amount deposited
	 * @param referral The referral code used
	 **/
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on withdraw()
	 * @param reserve The address of the underlyng asset being withdrawn
	 * @param user The address initiating the withdrawal, owner of aTokens
	 * @param to Address that will receive the underlying
	 * @param amount The amount to be withdrawn
	 **/
	event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

	/**
	 * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
	 * @param reserve The address of the underlying asset being borrowed
	 * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
	 * initiator of the transaction on flashLoan()
	 * @param onBehalfOf The address that will be getting the debt
	 * @param amount The amount borrowed out
	 * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
	 * @param borrowRate The numeric rate at which the user has borrowed
	 * @param referral The referral code used
	 **/
	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on repay()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The beneficiary of the repayment, getting his debt reduced
	 * @param repayer The address of the user initiating the repay(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

	/**
	 * @dev Emitted on swapBorrowRateMode()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user swapping his rate mode
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on rebalanceStableBorrowRate()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user for which the rebalance has been executed
	 **/
	event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The address of the flash loan receiver contract
	 * @param initiator The address initiating the flash loan
	 * @param asset The address of the asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param premium The fee flash borrowed
	 * @param referralCode The referral code used
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	/**
	 * @dev Emitted when the pause is triggered.
	 */
	event Paused();

	/**
	 * @dev Emitted when the pause is lifted.
	 */
	event Unpaused();

	/**
	 * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
	 * LendingPoolCollateral manager using a DELEGATECALL
	 * This allows to have the events in the generated ABI for LendingPool.
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	/**
	 * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
	 * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
	 * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
	 * gets added to the LendingPool ABI
	 * @param reserve The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(address asset, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 **/
	function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
	 * @param asset The address of the underlying asset borrowed
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 **/
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The address of the underlying asset deposited
	 * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
	 **/
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
	 * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
	 *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	/**
	 * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
	 * as long as the amount taken plus a fee is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * For further details please visit https://developers.aave.com
	 * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
	 * @param assets The addresses of the assets being flash-borrowed
	 * @param amounts The amounts amounts being flash-borrowed
	 * @param modes Types of the debt to open if the flash loan is not returned:
	 *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
	 *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
	 * @param params Variadic packed params to pass to the receiver as extra information
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function flashLoan(
		address receiverAddress,
		address[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	/**
	 * @dev Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateralETH the total collateral in ETH of the user
	 * @return totalDebtETH the total debt in ETH of the user
	 * @return availableBorrowsETH the borrowing power left of the user
	 * @return currentLiquidationThreshold the liquidation threshold of the user
	 * @return ltv the loan to value of the user
	 * @return healthFactor the current health factor of the user
	 **/
	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	/**
	 * @dev Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 **/
	function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @dev Returns the configuration of the user across all the reserves
	 * @param user The user address
	 * @return The configuration of the user
	 **/
	function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

	/**
	 * @dev Returns the normalized income normalized income of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve's normalized income
	 */
	function getReserveNormalizedIncome(address asset) external view returns (uint256);

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve normalized variable debt
	 */
	function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;

	function getLiquidationFeeTo() external view returns (address);

	function setLiquidationFeeTo(address liquidationFeeTo) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IScaledBalanceToken {
	/**
	 * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
	 * updated stored balance divided by the reserve's liquidity index at the moment of the update
	 * @param user The user whose balance is calculated
	 * @return The scaled balance of the user
	 **/
	function scaledBalanceOf(address user) external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the user and the scaled total supply.
	 * @param user The address of the user
	 * @return The scaled balance of the user
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

	/**
	 * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
	 * @return The scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./IScaledBalanceToken.sol";
import "./IInitializableDebtToken.sol";
import "./IAaveIncentivesController.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
	/**
	 * @dev Emitted after the mint action
	 * @param from The address performing the mint
	 * @param onBehalfOf The address of the user on which behalf minting has been performed
	 * @param value The amount to be minted
	 * @param index The last index of the reserve
	 **/
	event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

	/**
	 * @dev Mints debt token to the `onBehalfOf` address
	 * @param user The address receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The address receiving the debt tokens
	 * @param amount The amount of debt being minted
	 * @param index The variable debt index of the reserve
	 * @return `true` if the the previous balance of the user is 0
	 **/
	function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);

	/**
	 * @dev Emitted when variable debt is burnt
	 * @param user The user which debt has been burned
	 * @param amount The amount of debt being burned
	 * @param index The index of the user
	 **/
	event Burn(address indexed user, uint256 amount, uint256 index);

	/**
	 * @dev Burns user variable debt
	 * @param user The user which debt is burnt
	 * @param index The variable debt index of the reserve
	 **/
	function burn(address user, uint256 amount, uint256 index) external;

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function user_checkpoint(address) external;
    function claim_rewards() external;
    function bal_pseudo_minter() external view returns (address);
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;


/**
 * @dev Base minter interface, applicable to Mainnet minter or L2 pseudo minters.
 */
interface IBalancerMinter {
    event Minted(address indexed recipient, address gauge, uint256 minted);

    /**
     * @notice Returns the address of the Balancer Governance Token
     */
    function getBalancerToken() external view returns (address);

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external returns (uint256);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] calldata gauges) external returns (uint256);

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mintFor(address gauge, address user) external returns (uint256);

    /**
     * @notice Mint tokens for `user` across multiple gauges
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauges List of `LiquidityGauge` addresses
     * @param user Address to mint to
     */
    function mintManyFor(address[] calldata gauges, address user) external returns (uint256);

    /**
     * @notice The total number of tokens minted for `user` from `gauge`
     */
    function minted(address user, address gauge) external view returns (uint256);

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function getMinterApproval(address minter, address user) external view returns (bool);

    /**
     * @notice Set whether `minter` is approved to mint tokens on your behalf
     */
    function setMinterApproval(address minter, bool approval) external;

    /**
     * @notice Set whether `minter` is approved to mint tokens on behalf of `user`, who has signed a message authorizing
     * them.
     */
    function setMinterApprovalWithSignature(
        address minter,
        bool approval,
        address user,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // The below functions are near-duplicates of functions available above.
    // They are included for ABI compatibility with snake_casing as used in vyper contracts.
    // solhint-disable func-name-mixedcase

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function allowed_to_mint_for(address minter, address user) external view returns (bool);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @dev This function is not recommended as `mintMany()` is more flexible and gas efficient
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauges) external;

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mint_for(address gauge, address user) external;

    /**
     * @notice Toggle whether `minter` is approved to mint tokens for `user`
     */
    function toggle_approve_mint(address minter) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAsset {
}

interface IBVault {
    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, address[] calldata tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, address indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(address indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        address[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, address[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, address[] calldata tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, address[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external payable;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest calldata request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        address[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory assetDeltas);

    function getProtocolFeesCollector() external view returns(address);

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(address indexed recipient, address indexed token, uint256 amount, uint256 feeAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IPoolSwapStructs.sol";

interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Returns this Pool's ID, used when interacting with the Vault (to e.g. join the Pool or swap with it).
     */
    function getPoolId() external view returns (bytes32);

    /**
     * @dev Returns the current swap fee percentage as a 18 decimal fixed point number, so e.g. 1e17 corresponds to a
     * 10% swap fee.
     */
    function getSwapFeePercentage() external view returns (uint256);

    /**
     * @dev Returns the scaling factors of each of the Pool's tokens. This is an implementation detail that is typically
     * not relevant for outside parties, but which might be useful for some types of Pools.
     */
    function getScalingFactors() external view returns (uint256[] memory);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

interface ILinearPool is IBasePool {
    /**
     * @dev Returns the Pool's main token.
     */
    function getMainToken() external view returns (address);

    /**
     * @dev Returns the Pool's wrapped token.
     */
    function getWrappedToken() external view returns (address);

    /**
     * @dev Returns the index of the Pool's BPT in the Pool tokens array (as returned by IVault.getPoolTokens).
     */
    function getBptIndex() external view returns (uint256);

    /**
     * @dev Returns the index of the Pool's main token in the Pool tokens array (as returned by IVault.getPoolTokens).
     */
    function getMainIndex() external view returns (uint256);

    /**
     * @dev Returns the index of the Pool's wrapped token in the Pool tokens array (as returned by
     * IVault.getPoolTokens).
     */
    function getWrappedIndex() external view returns (uint256);

    /**
     * @dev Returns the Pool's targets for the main token balance. These values have had the main token's scaling
     * factor applied to them.
     */
    function getTargets() external view returns (uint256 lowerTarget, uint256 upperTarget);

    /**
     * @notice Set the lower and upper bounds of the zero-fee trading range for the main token balance.
     * @dev For a new target range to be valid:
     *      - the current balance must be between the current targets (meaning no fees are currently pending)
     *      - the current balance must be between the new targets (meaning setting them does not create pending fees)
     *
     * The first requirement could be relaxed, as the LPs actually benefit from the pending fees not being paid out,
     * but being stricter makes analysis easier at little expense.
     *
     * This is a permissioned function, reserved for the pool owner. It will revert when called within a Vault context
     * (i.e. in the middle of a join or an exit).
     *
     * Correct behavior depends on the token balances from the Vault, which may be out of sync with the state of
     * the pool during execution of a Vault hook.
     *
     * See https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345 for reference.
     */
    function setTargets(uint256 newLowerTarget, uint256 newUpperTarget) external;

    /**
     * @notice Set the swap fee percentage.
     * @dev This is a permissioned function, reserved for the pool owner. It will revert when called within a Vault
     * context (i.e. in the middle of a join or an exit).
     *
     * Correct behavior depends on the token balances from the Vault, which may be out of sync with the state of
     * the pool during execution of a Vault hook.
     *
     * See https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345 for reference.
     */
    function setSwapFeePercentage(uint256 swapFeePercentage) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../IBVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IBVault.SwapKind kind;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import '../uniswap/IUniswapV2Router01.sol';

interface ICamelotRouter is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;


}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IDividendsV2 {
    function harvestAllDividends() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTPool is IERC721 {
  function exists(uint256 tokenId) external view returns (bool);
  function hasDeposits() external view returns (bool);
  function getPoolInfo() external view returns (
    address lpToken, address grailToken, address sbtToken, uint256 lastRewardTime, uint256 accRewardsPerShare,
    uint256 lpSupply, uint256 lpSupplyWithMultiplier, uint256 allocPoint
  );
  function getStakingPosition(uint256 tokenId) external view returns (
    uint256 amount, uint256 amountWithMultiplier, uint256 startLockTime,
    uint256 lockDuration, uint256 lockMultiplier, uint256 rewardDebt,
    uint256 boostPoints, uint256 totalMultiplier
  );

  function boost(uint256 userAddress, uint256 amount) external;
  function unboost(uint256 userAddress, uint256 amount) external;

  function createPosition(uint256 amount, uint256 lockDuration) external;
  function addToPosition(uint256 tokenId, uint256 amountToAdd) external;
  function harvestPosition(uint256 tokenId) external;
  function withdrawFromPosition(uint256 tokenId, uint256 amountToWithdraw) external;
  function emergencyWithdraw(uint256 tokenId) external;

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface INitroPool {
  function withdraw(uint256 tokenId) external;
  function emergencyWithdraw(uint256 tokenId) external;
  function harvest() external;
  function nftPool() external view returns (address);
  function userInfo(address user) external view returns (uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXGrailTokenUsage.sol";

interface IXGrail is IERC20 {
  struct XGrailBalance {
    uint256 allocatedAmount; // Amount of xGRAIL allocated to a Usage
    uint256 redeemingAmount; // Total amount of xGRAIL currently being redeemed
  }
  struct RedeemInfo {
    uint256 grailAmount; // GRAIL amount to receive when vesting has ended
    uint256 xGrailAmount; // xGRAIL amount to redeem
    uint256 endTime;
    IXGrailTokenUsage dividendsAddress;
    uint256 dividendsAllocation; // Share of redeeming xGRAIL to allocate to the Dividends Usage contract
  }
  function getXGrailBalance(address user) external view returns (XGrailBalance calldata);
  function getGrailByVestingDuration(uint256 amount, uint256 duration) external view returns (uint256);
  function getUserRedeemsLength(address user) external view returns (uint256);
  function getUserRedeem(address user, uint256 index) external view returns (RedeemInfo calldata);
  function getUsageApproval(address user, address usageAddress) external view returns (uint256);
  function getUsageAllocation(address user, address usageAddress) external view returns (uint256);
  function dividendsAddress() external view returns (address);
  function usagesDeallocationFee(address allocation) external view returns (uint256);
  function grailToken() external view returns (address);
  function minRedeemDuration() external view returns (uint256);

  function approveUsage(address usage, uint256 amount) external;
  function convert(uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
  function redeem(uint256 amount, uint256 duration) external;
  function finalizeRedeem(uint256 redeemIndex) external;
  function updateRedeemDividendsAddress(uint256 redeemIndex) external;
  function cancelRedeem(uint256 redeemIndex) external;
  function allocate(address usage, uint256 amount, bytes calldata usageData) external;
  function deallocate(address usage, uint256 amount, bytes calldata usageData) external;

  function updateTransferWhitelist(address account, bool add) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IXGrailTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IYieldBooster {
  function deallocateAllFromPool(address userAddress, uint256 tokenId) external;
  function getMultiplier(address poolAddress, uint256 maxBoostMultiplier, uint256 amount, uint256 totalPoolSupply, uint256 allocatedAmount) external view returns (uint256);
  function getExpectedMultiplier(uint256 maxBoostMultiplier, uint256 lpAmount, uint256 totalLpSupply, uint256 userAllocation, uint256 poolTotalAllocation) external view returns (uint256);
  function getUserTotalAllocation(address user) external view returns (uint256);
  function getPoolTotalAllocation(address pool) external view returns (uint256);
  function getUserPositionAllocation(address user, address pool, uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
interface IComet {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    function supply(address asset, uint amount) external;
    function supplyTo(address dst, address asset, uint amount) external;
    function supplyFrom(address from, address dst, address asset, uint amount) external;

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function transferAsset(address dst, address asset, uint amount) external;
    function transferAssetFrom(address src, address dst, address asset, uint amount) external;

    function withdraw(address asset, uint amount) external;
    function withdrawTo(address to, address asset, uint amount) external;
    function withdrawFrom(address src, address to, address asset, uint amount) external;

    function approveThis(address manager, address asset, uint amount) external;
    function withdrawReserves(address to, uint amount) external;

    function absorb(address absorber, address[] calldata accounts) external;
    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) external;
    function quoteCollateral(address asset, uint baseAmount) external view returns (uint);

    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);
    function getCollateralReserves(address asset) external view returns (uint);
    function getReserves() external view returns (int);
    function getPrice(address priceFeed) external view returns (uint);

    function isBorrowCollateralized(address account) external view returns (bool);
    function isLiquidatable(address account) external view returns (bool);

    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function borrowBalanceOf(address account) external view returns (uint256);

    function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused) external;
    function isSupplyPaused() external view returns (bool);
    function isTransferPaused() external view returns (bool);
    function isWithdrawPaused() external view returns (bool);
    function isAbsorbPaused() external view returns (bool);
    function isBuyPaused() external view returns (bool);

    function accrueAccount(address account) external;
    function getSupplyRate(uint utilization) external view returns (uint64);
    function getBorrowRate(uint utilization) external view returns (uint64);
    function getUtilization() external view returns (uint);

    function governor() external view returns (address);
    function pauseGuardian() external view returns (address);
    function baseToken() external view returns (address);
    function baseTokenPriceFeed() external view returns (address);
    function extensionDelegate() external view returns (address);

    /// @dev uint64
    function supplyKink() external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint);
    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint);
    /// @dev uint64
    function borrowKink() external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint);
    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint);
    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint);

    /// @dev uint64
    function baseScale() external view returns (uint);
    /// @dev uint64
    function trackingIndexScale() external view returns (uint);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint);
    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint);
    /// @dev uint104
    function baseMinForRewards() external view returns (uint);
    /// @dev uint104
    function baseBorrowMin() external view returns (uint);
    /// @dev uint104
    function targetReserves() external view returns (uint);

    function numAssets() external view returns (uint8);
    function decimals() external view returns (uint8);

    function initializeStorage() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Compound's CometRewards Contract
 * @notice Hold and claim token rewards
 * @author Compound
 */
interface ICometRewards {
    struct RewardOwed {
        address token;
        uint owed;
    }
    function claim(address comet, address src, bool accrue) external;
    function getRewardOwed(address comet, address account) external returns (RewardOwed memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_2token {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount
  ) external payable;
  function remove_liquidity_imbalance(
    uint256[2] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[2] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external payable;
  function calc_token_amount(
    uint256[2] calldata amounts,
    bool deposit
  ) external view returns(uint);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_3token_meta {
  function add_liquidity(
    address pool,
    uint256[3] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    address pool,
    uint256[3] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    address pool,
    uint256 _amount,
    uint256[3] calldata amounts
  ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_3token {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[3] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[3] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[3] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
  function calc_token_amount(
    uint256[3] calldata amounts,
    bool deposit
  ) external view returns(uint);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_4token_meta {
  function add_liquidity(
    address pool,
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    address pool,
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    address pool,
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ICurveDeposit_4token {
  function get_virtual_price() external view returns (uint);
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
  function remove_liquidity_imbalance(
    uint256[4] calldata amounts,
    uint256 max_burn_amount
  ) external;
  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
  function calc_token_amount(
    uint256[4] calldata amounts,
    bool deposit
  ) external view returns(uint);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IClearing {
  function getSqrtTwapX96(address, uint32) external view returns(uint160);
  function getDepositAmount(address, address, uint256) external view returns(uint256, uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IHypervisor {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getTotalAmounts() external view returns(uint256, uint256);
  function withdraw(uint256 shares, address to, address from, uint256[4] calldata minAmounts) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IUniProxy {
  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  ) external;
  function getSqrtTwapX96(address, uint32) external view returns(uint160);
  function clearance() external view returns(address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


interface IController {

    // ========================= Events =========================

    event QueueProfitSharingChange(uint profitSharingNumerator, uint validAtTimestamp);
    event ConfirmProfitSharingChange(uint profitSharingNumerator);

    event QueueStrategistFeeChange(uint strategistFeeNumerator, uint validAtTimestamp);
    event ConfirmStrategistFeeChange(uint strategistFeeNumerator);

    event QueuePlatformFeeChange(uint platformFeeNumerator, uint validAtTimestamp);
    event ConfirmPlatformFeeChange(uint platformFeeNumerator);

    event QueueNextImplementationDelay(uint implementationDelay, uint validAtTimestamp);
    event ConfirmNextImplementationDelay(uint implementationDelay);

    event AddedStakingContract(address indexed stakingContract);
    event RemovedStakingContract(address indexed stakingContract);

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ==================== Functions ====================

    /**
     * An EOA can safely interact with the system no matter what. If you're using Metamask, you're using an EOA. Only
     * smart contracts may be affected by this grey list. This contract will not be able to ban any EOA from the system
     * even if an EOA is being added to the greyList, he/she will still be able to interact with the whole system as if
     * nothing happened. Only smart contracts will be affected by being added to the greyList. This grey list is only
     * used in VaultV3.sol, see the code there for reference
     */
    function greyList(address _target) external view returns (bool);

    function addressWhiteList(address _target) external view returns (bool);

    function codeWhiteList(address _target) external view returns (bool);

    function addToWhitelist(address _target) external;

    function addCodeToWhitelist(address _target) external;

    function store() external view returns (address);

    function governance() external view returns (address);

    function doHardWork(address _vault) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    /**
     * @return The targeted profit token to convert all-non-compounding rewards to. Defaults to WETH.
     */
    function targetToken() external view returns (address);

    function setTargetToken(address _targetToken) external;

    function profitSharingReceiver() external view returns (address);

    function setProfitSharingReceiver(address _profitSharingReceiver) external;

    function protocolFeeReceiver() external view returns (address);

    function setProtocolFeeReceiver(address _protocolFeeReceiver) external;

    function rewardForwarder() external view returns (address);

    function setRewardForwarder(address _rewardForwarder) external;

    function universalLiquidator() external view returns (address);

    function setUniversalLiquidator(address _universalLiquidator) external;

    function dolomiteYieldFarmingRouter() external view returns (address);

    function setDolomiteYieldFarmingRouter(address _value) external;

    function nextImplementationDelay() external view returns (uint256);

    function profitSharingNumerator() external view returns (uint256);

    function strategistFeeNumerator() external view returns (uint256);

    function platformFeeNumerator() external view returns (uint256);

    function feeDenominator() external view returns (uint256);

    function setProfitSharingNumerator(uint _profitSharingNumerator) external;

    function confirmSetProfitSharingNumerator() external;

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) external;

    function confirmSetStrategistFeeNumerator() external;

    function setPlatformFeeNumerator(uint _platformFeeNumerator) external;

    function confirmSetPlatformFeeNumerator() external;

    function setNextImplementationDelay(uint256 _nextImplementationDelay) external;

    function confirmNextImplementationDelay() external;

    function nextProfitSharingNumerator() external view returns (uint256);

    function nextProfitSharingNumeratorTimestamp() external view returns (uint256);

    function nextStrategistFeeNumerator() external view returns (uint256);

    function nextStrategistFeeNumeratorTimestamp() external view returns (uint256);

    function nextPlatformFeeNumerator() external view returns (uint256);

    function nextPlatformFeeNumeratorTimestamp() external view returns (uint256);

    function tempNextImplementationDelay() external view returns (uint256);

    function tempNextImplementationDelayTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


interface IERC4626 {

    // ========================= Events =========================

    /**
     * Caller has exchanged assets for shares, and transferred those shares to owner.
     *
     * MUST be emitted when tokens are deposited into the Vault via the mint and deposit methods.
     */
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    /**
     * Caller has exchanged shares, owned by owner, for assets, and transferred those assets to receiver.
     *
     * MUST be emitted when shares are withdrawn from the Vault in ERC4626.redeem or ERC4626.withdraw methods.
     */
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    // ========================= Functions =========================

    /**
     * @return assetTokenAddress The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @return  totalManagedAssets Total amount of the underlying asset that is “managed” by Vault. SHOULD include any compounding that
     *          occurs from yield. MUST be inclusive of any fees that are charged against assets in the Vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @return  assetsPerUnitShare The amount of underlying the Vault would exchange for 1 unit of shares, in an ideal scenario where all
     *          the conditions are met. MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT show any variations depending on the caller. MUST NOT reflect slippage or other on-chain
     *          conditions, when performing the actual exchange. MUST NOT revert unless due to integer overflow caused
     *          by an unreasonably large input. MUST round down towards 0. This calculation MAY NOT reflect the
     *          “per-user” price-per-share, and instead should reflect the “average-user’s” price-per-share, meaning
     *          what the average user should expect to see when exchanging to and from. This function should normally
     *          return more than `10 ** underlying().decimals`.
     */
    function assetsPerShare() external view returns (uint256 assetsPerUnitShare);

    /**
     * @return  assets Total amount of the underlying asset that is “managed” by Vault for the `depositor`. SHOULD include any
     *          compounding that occurs from yield. MUST be inclusive of any fees that are charged against assets in the
     *          Vault.
     */
    function assetsOf(address depositor) external view returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit
     * call. MUST return the maximum amount of assets deposit would allow to be deposited for receiver and not cause a
     * revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     * necessary). This assumes that the user has infinite assets, i.e. MUST NOT rely on balanceOf of asset. MUST factor
     * in both global and user-specific limits, like if deposits are entirely disabled (even temporarily) it MUST return
     * 0. MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     */
    function maxDeposit(address caller) external view returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current
     * on-chain conditions.
     *
     * MUST return as close to and no more than the exact amount of Vault shares that would be
     * minted in a deposit call in the same transaction. I.e. deposit should return the same or more shares as
     * previewDeposit if called in the same transaction. MUST NOT account for deposit limits like those returned from
     * maxDeposit and should always act as though the deposit would be accepted, regardless if the user has enough
     * tokens approved, etc.
     *
     * MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause deposit to revert.
     *
     * Note that any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * MUST emit the Deposit event.
     *
     * MUST support ERC-20 approve / transferFrom on asset as a deposit flow. MAY support an additional flow in which
     * the underlying tokens are owned by the Vault contract before the deposit execution, and are accounted for during
     * deposit.
     *
     * MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * Note that most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * Maximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
     *
     * MUST return the maximum amount of shares mint would allow to be deposited to receiver and not cause a revert,
     * which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if necessary).
     * This assumes that the user has infinite assets, i.e. MUST NOT rely on balanceOf of asset.
     *
     * MUST factor in both global and user-specific limits, like if mints are entirely disabled (even temporarily) it
     * MUST return 0.
     *
     * MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     */
    function maxMint(address caller) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current
     * on-chain conditions.
     *
     * MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call in
     * the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the same
     * transaction.
     *
     * MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint would
     * be accepted, regardless if the user has enough tokens approved, etc.
     *
     * MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause mint to revert.
     *
     * Note that any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * MUST emit the Deposit event.
     *
     * MUST support ERC-20 approve / transferFrom on asset as a mint flow. MAY support an additional flow in which the
     * underlying tokens are owned by the Vault contract before the mint execution, and are accounted for during mint.
     *
     * MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * Note that most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a
     * withdraw call.
     *
     * MUST return the maximum amount of assets that could be transferred from owner through withdraw and not cause a
     * revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     * necessary).
     *
     * MUST factor in both global and user-specific limits, like if withdrawals are entirely disabled (even temporarily)
     * it MUST return 0.
     */
    function maxWithdraw(address caller) external view returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given
     * current on-chain conditions.
     *
     * MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     * call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if called
     * in the same transaction.
     *
     * MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though the
     * withdrawal would be accepted, regardless if the user has enough shares, etc.
     *
     * MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause withdraw to revert.
     *
     * Note that any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage
     * in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * MUST emit the Withdraw event.
     *
     * MUST support a withdraw flow where the shares are burned from owner directly where owner is msg.sender or
     * msg.sender has ERC-20 approval over the shares of owner. MAY support an additional flow in which the shares are
     * transferred to the Vault contract before the withdraw execution, and are accounted for during withdraw.
     *
     * MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not
     * having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
     *
     * MUST return the maximum amount of shares that could be transferred from owner through redeem and not cause a
     * revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     * necessary).
     *
     * MUST factor in both global and user-specific limits, like if redemption is entirely disabled (even temporarily)
     * it MUST return 0.
     */
    function maxRedeem(address caller) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given
     * current on-chain conditions.
     *
     * MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call in
     * the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the same
     * transaction.
     *
     * MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     * redemption would be accepted, regardless if the user has enough shares, etc.
     *
     * MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause redeem to revert.
     *
     * Note that any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * MUST emit the Withdraw event.
     *
     * MUST support a redeem flow where the shares are burned from owner directly where owner is msg.sender or
     * msg.sender has ERC-20 approval over the shares of owner. MAY support an additional flow in which the shares are
     * transferred to the Vault contract before the redeem execution, and are accounted for during redeem.
     *
     * MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not
     * having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IGlobalIncentivesHelper {
  function notifyPools(address[] calldata tokens, uint256[] calldata totals, uint256 timestamp) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


interface IPotPool {

    function initializePotPool(
        address[] calldata _rewardTokens,
        address _lpToken,
        uint256 _duration,
        address[] calldata _rewardDistribution,
        address _storage
    ) external;

    function lpToken() external view returns (address);

    function duration() external view returns (uint256);

    function stakedBalanceOf(address _user) external view returns (uint);

    function smartContractStakers(address _user) external view returns (bool);

    function rewardTokens(uint _index) external view returns (address);

    function getRewardTokens() external view returns (address[] memory);

    function periodFinishForToken(address _rewardToken) external view returns (uint);

    function rewardRateForToken(address _rewardToken) external view returns (uint);

    function lastUpdateTimeForToken(address _rewardToken) external view returns (uint);

    function rewardPerTokenStoredForToken(address _rewardToken) external view returns (uint);

    function userRewardPerTokenPaidForToken(address _rewardToken, address _user) external view returns (uint);

    function rewardsForToken(address _rewardToken, address _user) external view returns (uint);

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    /**
     * A push mechanism for accounts that have not claimed their rewards for a long time. The implementation is
     * semantically analogous to getReward(), but uses a push pattern instead of pull pattern.
     */
    function pushAllRewards(address _recipient) external;

    function getAllRewards() external;

    function getReward(address _rewardToken) external;

    function addRewardToken(address _rewardToken) external;

    function removeRewardToken(address _rewardToken) external;

    /**
     * @return If the return value is MAX_UINT256, it means that the specified reward token is not in the list
     */
    function getRewardTokenIndex(address _rewardToken) external view returns (uint256);

    function notifyTargetRewardAmount(address _rewardToken, uint256 _reward) external;

    function rewardTokensLength() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


interface IProfitSharingReceiver {

    function governance() external view returns (address);

    function withdrawTokens(address[] calldata _tokens) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


/**
 * @dev A routing contract that is responsible for taking the harvested gains and routing them into FARM and additional
 *      buyback tokens for the corresponding strategy
 */
interface IRewardForwarder {

    function store() external view returns (address);

    function governance() external view returns (address);

    /**
     * @dev This function sends converted `_buybackTokens` to `msg.sender`. The returned amounts will match the
     *      `amounts` return value. The fee amounts are converted to the profit sharing token and sent to the proper
     *      addresses (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @param _buybackTokens    the output tokens that `_buyBackAmounts` should be swapped to (outputToken)
     * @param _buybackAmounts   the amounts of `_token` that will be bought into more `_buybackTokens` token
     * @return amounts The amounts that were purchased of _buybackTokens
     */
    function notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] calldata _buybackTokens,
        uint256[] calldata _buybackAmounts
    ) external returns (uint[] memory amounts);

    /**
     * @dev This function converts the fee amounts to the profit sharing token and sends them to the proper addresses
     *      (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     */
    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IStrategy {

    /// @notice declared as public so child contract can call it
    function isUnsalvageableToken(address token) external view returns (bool);

    function salvageToken(address recipient, address token, uint amount) external;

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 _amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);

    function strategist() external view returns (address);

    /**
     * @return  The value of any accumulated rewards that are under control by the strategy. Each index corresponds with
     *          the tokens in `rewardTokens`. This function is not a `view`, because some protocols, like Curve, need
     *          writeable functions to get the # of claimable reward tokens
     */
    function getRewardPoolValues() external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUniversalLiquidator {
    event Swap(
        address indexed sellToken,
        address indexed buyToken,
        address indexed receiver,
        address initiator,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    function swap(
        address _sellToken,
        address _buyToken,
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


interface IUpgradeSource {

  function shouldUpgrade() external view returns (bool, address);

  function finalizeUpgrade() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVault {

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) external;

    function balanceOf(address _holder) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function underlyingUnit() external view returns (uint);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function announceStrategyUpdate(address _strategy) external;

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external;

    function deposit(uint256 _amount) external;
    function deposit(uint256 _amount, address _receiver) external;

    function depositFor(uint256 _amount, address _holder) external;

    function withdrawAll() external;

    function withdraw(uint256 _numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address _holder) view external returns (uint256);

    /**
     * The total amount available to be deposited from this vault into the strategy, while adhering to the
     * `vaultFractionToInvestNumerator` and `vaultFractionToInvestDenominator` rules
     */
    function availableToInvestOut() external view returns (uint256);

    /**
     * This should be callable only by the controller (by the hard worker) or by governance
     */
    function doHardWork() external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint[] memory);

    function exitMarket(address cToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external virtual returns (uint);

    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external virtual;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external virtual returns (uint);

    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function borrowVerify(address cToken, address borrower, uint borrowAmount) external virtual;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external virtual returns (uint);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external virtual;

    function enableLooping(bool state) external virtual returns (bool);

    function isLoopingEnabled(address user) external view virtual returns (bool);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external virtual returns (uint);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external virtual returns (uint);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external virtual;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint transferTokens
    ) external virtual returns (uint);

    function transferVerify(address cToken, address src, address dst, uint transferTokens) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount
    ) external view virtual returns (uint, uint);

    function claimComp(address holder) external virtual;
    function borrowCaps(address cToken) external view virtual returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Official record of token balances for each account
    mapping(address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public constant protocolSeizeShareMantissa = 2.8e16; //2.8%

    /**
     * @notice Address that is allowed to pull from reserves for staking (rewardRouter)
     */
    address payable public reserveGuardian;
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows, uint borrowIndex);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint repayAmount,
        uint accountBorrows,
        uint totalBorrows,
        uint borrowIndex
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint repayAmount,
        address cTokenCollateral,
        uint seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when reserveGuardian is changed
     */
    event NewReserveGuardian(address oldReserveGuardian, address newReserveGuardian);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);

    function approve(address spender, uint amount) external virtual returns (bool);

    function allowance(address owner, address spender) external view virtual returns (uint);

    function balanceOf(address owner) external view virtual returns (uint);

    function balanceOfUnderlying(address owner) external virtual returns (uint);

    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view virtual returns (uint);

    function supplyRatePerBlock() external view virtual returns (uint);

    function totalBorrowsCurrent() external virtual returns (uint);

    function borrowBalanceCurrent(address account) external virtual returns (uint);

    function borrowBalanceStored(address account) external view virtual returns (uint);

    function exchangeRateCurrent() external virtual returns (uint);

    function exchangeRateStored() external view virtual returns (uint);

    function getCash() external view virtual returns (uint);

    function accrueInterest() external virtual returns (uint);

    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint);

    function _acceptAdmin() external virtual returns (uint);

    function _setComptroller(ComptrollerInterface newComptroller) external virtual returns (uint);

    function _setReserveGuardian(address payable newReserveGuardian) external virtual returns (uint);

    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);

    function _reduceReserves(uint reduceAmount) external virtual returns (uint);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) external virtual returns (uint);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {
    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function mint() external payable virtual;

    function redeem(uint redeemTokens) external virtual returns (uint);

    function redeemBehalf(uint redeemTokens, address redeemee) external virtual returns (uint);

    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);

    function borrow(uint borrowAmount) external virtual returns (uint);

    function borrowBehalf(uint borrowAmount, address borrowee) external virtual returns (uint);

    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrow() external payable virtual;

    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);

    function liquidateBorrow(
        address borrower,
        uint repayAmount,
        CTokenInterface cTokenCollateral
    ) external virtual returns (uint);

    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

abstract contract CEtherInterface {
    /*** User Interface ***/

    function mint() external payable virtual;

    function redeem(uint redeemTokens) external virtual returns (uint);

    function redeemBehalf(uint redeemTokens, address redeemee) external virtual returns (uint);

    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);

    function borrow(uint borrowAmount) external virtual returns (uint);

    function borrowBehalf(uint borrowAmount, address borrowee) external virtual returns (uint);

    function repayBorrow() external payable virtual;

    function repayBorrowBehalf(address borrower) external payable virtual;

    function liquidateBorrow(address borrower, CTokenInterface cTokenCollateral) external payable virtual;

    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /*** Admin Functions ***/

    function _addReserves() external payable virtual returns (uint);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external virtual;
}

abstract contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external virtual;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint error, uint info, uint detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

interface IStakingRewards {
    function stakeLODE(uint256 amount, uint256 lockTime) external;
    function unstakeLODE(uint256 amount) external;
    function emergencyStakerWithdrawal() external;
    function claimRewards() external;
    function userInfo(address) external view returns(uint96, int128);
    function LODE() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterMagpie {
    struct PoolInfo {
        address stakingToken; // Address of staking token contract to be staked.
        uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
        uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
        address rewarder;
        address helper;
        bool helperNeedsHarvest;
    }

    function poolLength() external view returns (uint256);

    function tokenToPoolInfo(
        address _stakingToken
    ) external view returns (PoolInfo memory);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _stakingTokenToken,
        address _rewarder,
        address _helper,
        bool _helperNeedsHarvest
    ) external;

    function createRewarder(
        address _stakingToken,
        address mainRewardToken
    ) external returns (address);

    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _helper,
        address _rewarder,
        bool _helperNeedsHarvest
    ) external;

    // View function to see pending GMPs on frontend.
    function getPoolInfo(
        address token
    )
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function rewarderBonusTokenInfo(
        address _stakingToken
    )
        external
        view
        returns (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        );

    function pendingTokens(
        address _stakingToken,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function depositFor(
        address _stakingToken,
        uint256 _amount,
        address sender
    ) external;

    function withdrawFor(
        address _stakingToken,
        uint256 _amount,
        address _sender
    ) external;

    function depositVlMGPFor(uint256 _amount, address sender) external;

    function withdrawVlMGPFor(uint256 _amount, address sender) external;

    function depositMWomSVFor(uint256 _amount, address sender) external;

    function withdrawMWomSVFor(uint256 _amount, address sender) external;

    function multiclaim(address[] calldata _stakingTokens) external;

    function multiclaimSpec(
        address[] calldata _stakingTokens,
        address[][] memory _rewardTokens
    ) external;

    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(
        address _stakingToken,
        address _user
    ) external view returns (uint256 depositAmount, uint256 availableAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IPool {
    function getTokens() external view returns (address[] memory);

    function addressOfAsset(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IWombatPoolHelper {
    function totalStaked() external view returns (uint256);

    function balance(address _address) external view returns (uint256);

    function depositToken() external view returns (address);
    
    function lpToken() external view returns (address);

    function rewarder() external view returns (address);

    function masterMagpie() external view returns (address);

    function stakingToken() external view returns (address);

    function wombatStaking() external view returns (address);

    function deposit(uint256 amount, uint256 minimumAmount) external;

    function withdraw(uint256 amount, uint256 minimumAmount) external;

    function depositNative(uint256 _minimumLiquidity) external payable;

    function depositLP(uint256 _lpAmount) external;

    function withdrawLP(uint256 _lpAmount, bool _harvest) external;

    function harvest() external;
}

// SPDX-License-Identifier: MIT

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IWombatStaking {
    struct Pool {
        uint256 pid; // pid on master wombat
        address depositToken; // token to be deposited on wombat
        address lpAddress; // token received after deposit on wombat
        address receiptToken; // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
    }

    function convertWOM(uint256 amount) external returns (uint256);

    function masterWombat() external view returns (address);

    function deposit(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _for,
        address _from
    ) external;

    function depositLP(
        address _lpToken,
        uint256 _lpAmount,
        address _for
    ) external;

    function withdraw(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _sender
    ) external;

    function getPoolLp(address _lpToken) external view returns (address);

    function pools(address _lpToken) external view returns (Pool memory);

    function harvest(address _lpToken) external;

    function burnReceiptToken(address _lpToken, uint256 _amount) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    )
        external
        returns (
            address[][] memory rewardTokens,
            uint256[][] memory feeAmounts
        );

    function voter() external view returns (address);

    function pendingBribeCallerFee(
        address[] calldata pendingPools
    )
        external
        view
        returns (
            IERC20[][] memory rewardTokens,
            uint256[][] memory callerFeeAmount
        );
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IGauge {
    function depositAll(uint tokenId) external;
    function deposit(uint amount, uint tokenId) external;
    function withdrawAll() external;
    function withdraw(uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function balanceOf(address account) external view returns (uint);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface ILizardPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function stable() external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ILizardRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IMiniChefV2 {

  function deposit(uint256 _pid, uint256 _amount, address _to) external;
  function withdraw(uint256 _pid, uint256 _amount, address _to) external;
  function harvest(uint256 _pid, address _to) external;
  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;
  function userInfo(uint256 _pid, address _user) external view returns (uint256 _balance, int256 _rewardDebt);
  function poolInfo(uint256 _pid) external view returns (
    uint128 _accSushiPerShare,
    uint64 _lastRewardTimestamp,
    uint64 _allocPoint
  );
  function lpToken(uint256 _pid) external view returns (address);
  function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILBRouter {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountNATIVEMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountNATIVE);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactNATIVE(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapNATIVEForExactTokens(
        uint256 amountOut,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {

    // ==================== Events ====================

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint amount0, uint amount1);

    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    // ==================== Functions ====================

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IUniswapV2Router02 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IUniswapV3Router {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Unlicense
// based on https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;


interface IWETH {

    function balanceOf(address target) external view returns (uint256);

    function deposit() external payable ;

    function withdraw(uint wad) external ;

    function totalSupply() external view returns (uint) ;

    function approve(address guy, uint wad) external returns (bool) ;

    function transfer(address dst, uint wad) external returns (bool) ;

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IVault.sol";
import "../upgradability/BaseUpgradeableStrategy.sol";

contract NoopStrategyUpgradeable is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  constructor() public BaseUpgradeableStrategy() {}

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault
  ) public initializer {

    require(_vault != address(0), "_vault cannot be empty");
    require(_underlying == IVault(_vault).underlying(), "underlying mismatch");

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      address(0),
      address(0),
      address(0)
    );
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function investedUnderlyingBalance() external view returns (uint256 balance) {
      balance = IERC20(underlying()).balanceOf(address(this));
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() external restricted {
    address _underlying = underlying();
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(address(vault()), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  /*
  * Cashes some amount out and withdraws to the vault
  */
  function withdrawToVault(uint256 amount) external restricted {
    address _underlying = underlying();
    require(IERC20(_underlying).balanceOf(address(this)) >= amount,
      "insufficient balance for the withdrawal");
    if (amount > 0) {
      IERC20(_underlying).safeTransfer(address(vault()), amount);
    }
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external restricted {
    // a no-op
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./inheritance/Controllable.sol";
import "./interface/IController.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {

    mapping (address => bool) public rewardDistribution;

    constructor(address[] memory _rewardDistributions) public {
        // multisig on Arbitrum
        rewardDistribution[0xf3D1A027E858976634F81B7c41B09A05A46EdA21] = true;
        // NotifyHelper
        rewardDistribution[0xC0cE53f755feAe93Fd219b2Cd0F58a4Fd0d535Dd] = true;

        for(uint256 i = 0; i < _rewardDistributions.length; i++) {
          rewardDistribution[_rewardDistributions[i]] = true;
        }
    }

    function notifyTargetRewardAmount(address rewardToken, uint256 reward) external virtual;
    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(rewardDistribution[_msgSender()], "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address[] calldata _newRewardDistribution, bool _flag)
        external
        onlyOwner
    {
        for(uint256 i = 0; i < _newRewardDistribution.length; i++){
          rewardDistribution[_newRewardDistribution[i]] = _flag;
        }
    }
}

contract PotPool is IRewardDistributionRecipient, Controllable, ERC20 {

    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public lpToken;
    uint256 public duration; // making it not a constant is less gas efficient, but portable

    mapping(address => uint256) public stakedBalanceOf;

    mapping (address => bool) smartContractStakers;
    address[] public rewardTokens;
    mapping(address => uint256) public periodFinishForToken;
    mapping(address => uint256) public rewardRateForToken;
    mapping(address => uint256) public lastUpdateTimeForToken;
    mapping(address => uint256) public rewardPerTokenStoredForToken;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
    mapping(address => mapping(address => uint256)) public rewardsForToken;

    event RewardAdded(address rewardToken, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address rewardToken, uint256 reward);
    event RewardDenied(address indexed user, address rewardToken, uint256 reward);
    event SmartContractRecorded(address indexed smartContractAddress, address indexed smartContractInitiator);

    modifier onlyGovernanceOrRewardDistribution() {
      require(msg.sender == governance() || rewardDistribution[msg.sender], "Not governance nor reward distribution");
      _;
    }

    modifier updateRewards(address account) {
      for(uint256 i = 0; i < rewardTokens.length; i++ ){
        address rt = rewardTokens[i];
        rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
        lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
        if (account != address(0)) {
            rewardsForToken[rt][account] = earned(rt, account);
            userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
        }
      }
      _;
    }

    modifier updateReward(address account, address rt){
      rewardPerTokenStoredForToken[rt] = rewardPerToken(rt);
      lastUpdateTimeForToken[rt] = lastTimeRewardApplicable(rt);
      if (account != address(0)) {
          rewardsForToken[rt][account] = earned(rt, account);
          userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
      }
      _;
    }

    /** View functions to respect old interface */
    function rewardToken() public view returns(address) {
      return rewardTokens[0];
    }

    function rewardPerToken() public view returns(uint256) {
      return rewardPerToken(rewardTokens[0]);
    }

    function periodFinish() public view returns(uint256) {
      return periodFinishForToken[rewardTokens[0]];
    }

    function rewardRate() public view returns(uint256) {
      return rewardRateForToken[rewardTokens[0]];
    }

    function lastUpdateTime() public view returns(uint256) {
      return lastUpdateTimeForToken[rewardTokens[0]];
    }

    function rewardPerTokenStored() public view returns(uint256) {
      return rewardPerTokenStoredForToken[rewardTokens[0]];
    }

    function userRewardPerTokenPaid(address user) public view returns(uint256) {
      return userRewardPerTokenPaidForToken[rewardTokens[0]][user];
    }

    function rewards(address user) public view returns(uint256) {
      return rewardsForToken[rewardTokens[0]][user];
    }

    // [Hardwork] setting the reward, lpToken, duration, and rewardDistribution for each pool
    constructor(
        address[] memory _rewardTokens,
        address _lpToken,
        uint256 _duration,
        address[] memory _rewardDistribution,
        address _storage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
      ) public
      ERC20(_name, _symbol)
      IRewardDistributionRecipient(_rewardDistribution)
      Controllable(_storage) // only used for referencing the grey list
    {
        require(_decimals == ERC20(_lpToken).decimals(), "decimals has to be aligned with the lpToken");
        require(_rewardTokens.length != 0, "should initialize with at least 1 rewardToken");
        rewardTokens = _rewardTokens;
        lpToken = _lpToken;
        duration = _duration;
    }

    //Overwrite ERC20's transfer function to block transfer of pTokens,
    //as transferring the token does not transfer the rewards or rights to unstake.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
      if (amount > 0) {
        revert("Staked assets cannot be transferred");
      }
    }

    function lastTimeRewardApplicable(uint256 i) public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[i]);
    }

    function lastTimeRewardApplicable(address rt) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishForToken[rt]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return lastTimeRewardApplicable(rewardTokens[0]);
    }

    function rewardPerToken(uint256 i) public view returns (uint256) {
        return rewardPerToken(rewardTokens[i]);
    }

    function rewardPerToken(address rt) public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredForToken[rt];
        }
        return
            rewardPerTokenStoredForToken[rt].add(
                lastTimeRewardApplicable(rt)
                    .sub(lastUpdateTimeForToken[rt])
                    .mul(rewardRateForToken[rt])
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(uint256 i, address account) public view returns (uint256) {
        return earned(rewardTokens[i], account);
    }

    function earned(address account) public view returns (uint256) {
        return earned(rewardTokens[0], account);
    }

    function earned(address rt, address account) public view returns (uint256) {
        return
            stakedBalanceOf[account]
                .mul(rewardPerToken(rt).sub(userRewardPerTokenPaidForToken[rt][account]))
                .div(1e18)
                .add(rewardsForToken[rt][account]);
    }

    function stake(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        recordSmartContract();
        super._mint(msg.sender, amount); // ERC20 is used as a staking receipt
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].add(amount);
        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateRewards(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super._burn(msg.sender, amount);
        stakedBalanceOf[msg.sender] = stakedBalanceOf[msg.sender].sub(amount);
        IERC20(lpToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(Math.min(stakedBalanceOf[msg.sender], balanceOf(msg.sender)));
        getAllRewards();
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    /// The implementation is semantically analogous to getReward(), but uses a push pattern
    /// instead of pull pattern.
    function pushAllRewards(address recipient) public updateRewards(recipient) onlyGovernance {
      bool rewardPayout = (!smartContractStakers[recipient] || !IController(controller()).greyList(recipient));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        uint256 reward = earned(rewardTokens[i], recipient);
        if (reward > 0) {
            rewardsForToken[rewardTokens[i]][recipient] = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, then
            // make sure that it is not on our greyList.
            if (rewardPayout) {
                IERC20(rewardTokens[i]).safeTransfer(recipient, reward);
                emit RewardPaid(recipient, rewardTokens[i], reward);
            } else {
                emit RewardDenied(recipient, rewardTokens[i], reward);
            }
        }
      }
    }

    function getAllRewards() public updateRewards(msg.sender) {
      recordSmartContract();
      bool rewardPayout = (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender));
      for(uint256 i = 0 ; i < rewardTokens.length; i++ ){
        _getRewardAction(rewardTokens[i], rewardPayout);
      }
    }

    function getReward(address rt) public updateReward(msg.sender, rt) {
      recordSmartContract();
      _getRewardAction(
        rt,
        // don't payout if it is a grey listed smart contract
        (!smartContractStakers[msg.sender] || !IController(controller()).greyList(msg.sender))
      );
    }

    function getReward() public {
      getReward(rewardTokens[0]);
    }

    function _getRewardAction(address rt, bool rewardPayout) internal {
      uint256 reward = earned(rt, msg.sender);
      if (reward > 0 && IERC20(rt).balanceOf(address(this)) >= reward ) {
          rewardsForToken[rt][msg.sender] = 0;
          // If it is a normal user and not smart contract,
          // then the requirement will pass
          // If it is a smart contract, then
          // make sure that it is not on our greyList.
          if (rewardPayout) {
              IERC20(rt).safeTransfer(msg.sender, reward);
              emit RewardPaid(msg.sender, rt, reward);
          } else {
              emit RewardDenied(msg.sender, rt, reward);
          }
      }
    }

    function addRewardToken(address rt) public onlyGovernanceOrRewardDistribution {
      require(getRewardTokenIndex(rt) == uint256(-1), "Reward token already exists");
      rewardTokens.push(rt);
    }

    function removeRewardToken(address rt) public onlyGovernanceOrRewardDistribution {
      uint256 i = getRewardTokenIndex(rt);
      require(i != uint256(-1), "Reward token does not exists");
      require(periodFinishForToken[rewardTokens[i]] < block.timestamp, "Can only remove when the reward period has passed");
      require(rewardTokens.length > 1, "Cannot remove the last reward token");
      uint256 lastIndex = rewardTokens.length - 1;

      // swap
      rewardTokens[i] = rewardTokens[lastIndex];

      // delete last element
      rewardTokens.pop();
    }

    // If the return value is MAX_UINT256, it means that
    // the specified reward token is not in the list
    function getRewardTokenIndex(address rt) public view returns(uint256) {
      for(uint i = 0 ; i < rewardTokens.length ; i++){
        if(rewardTokens[i] == rt)
          return i;
      }
      return uint256(-1);
    }

    function notifyTargetRewardAmount(address _rewardToken, uint256 reward)
        public override
        onlyRewardDistribution
        updateRewards(address(0))
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(reward < uint(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

        uint256 i = getRewardTokenIndex(_rewardToken);
        require(i != uint256(-1), "rewardTokenIndex not found");

        if (block.timestamp >= periodFinishForToken[_rewardToken]) {
            rewardRateForToken[_rewardToken] = reward.div(duration);
        } else {
            uint256 remaining = periodFinishForToken[_rewardToken].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRateForToken[_rewardToken]);
            rewardRateForToken[_rewardToken] = reward.add(leftover).div(duration);
        }
        lastUpdateTimeForToken[_rewardToken] = block.timestamp;
        periodFinishForToken[_rewardToken] = block.timestamp.add(duration);
        emit RewardAdded(_rewardToken, reward);
    }

    function notifyRewardAmount(uint256 reward)
        external override
        onlyRewardDistribution
        updateRewards(address(0))
    {
      notifyTargetRewardAmount(rewardTokens[0], reward);
    }

    function rewardTokensLength() public view returns(uint256){
      return rewardTokens.length;
    }

    // Harvest Smart Contract recording
    function recordSmartContract() internal {
      if( tx.origin != msg.sender ) {
        smartContractStakers[msg.sender] = true;
        emit SmartContractRecorded(msg.sender, tx.origin);
      }
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./inheritance/Governable.sol";
import "./interface/IProfitSharingReceiver.sol";


/**
 * A simple contract for receiving tokens for profit sharing. This contract is designed to pool rewards that will be
 * sent by governance to Ethereum mainnet for FARM buybacks
 */
contract ProfitSharingReceiver is Governable {
    using SafeERC20 for IERC20;

    event WithdrawToken(address indexed token, address indexed receiver, uint amount);

    constructor(
        address _store
    )
    public
    Governable(_store) {}

    function withdrawTokens(address[] calldata _tokens) external onlyGovernance {
        address _governance = governance();
        for (uint i = 0; i < _tokens.length; ++i) {
            uint amount = IERC20(_tokens[i]).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_tokens[i]).safeTransfer(_governance, amount);
                emit WithdrawToken(_tokens[i], _governance, amount);
            }
        }
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interface/IVault.sol";

contract Reader {

  function getAllInformation(address who, address[] memory vaults, address[] memory pools)
  public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    return (unstakedBalances(who, vaults), stakedBalances(who, pools), vaultSharePrices(vaults));
  }

  function unstakedBalances(address who, address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IERC20Upgradeable(vaults[i]).balanceOf(who);
    }
    return result;
  }

  function stakedBalances(address who, address[] memory pools) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](pools.length);
    for (uint256 i = 0; i < pools.length; i++) {
      result[i] = IERC20Upgradeable(pools[i]).balanceOf(who);
    }
    return result;
  }

  function underlyingBalances(address who, address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IERC20Upgradeable(IVault(vaults[i]).underlying()).balanceOf(who);
    }
    return result;
  }

  function vaultSharePrices(address[] memory vaults) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IVault(vaults[i]).getPricePerFullShare();
    }
    return result;
  }

  function underlyingBalanceWithInvestmentForHolder(address who, address[] memory vaults)
  public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      result[i] = IVault(vaults[i]).underlyingBalanceWithInvestmentForHolder(who);
    }
    return result;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./inheritance/Governable.sol";
import "./interface/IController.sol";
import "./interface/IRewardForwarder.sol";
import "./interface/IProfitSharingReceiver.sol";
import "./interface/IStrategy.sol";
import "./interface/IUniversalLiquidator.sol";
import "./inheritance/Controllable.sol";

/**
 * @dev This contract receives rewards from strategies and is responsible for routing the reward's liquidation into
 *      specific buyback tokens and profit tokens for the DAO.
 */
contract RewardForwarder is Controllable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant iFARM = address(0x9dCA587dc65AC0a043828B0acd946d71eb8D46c1);

    constructor(
        address _storage
    ) public Controllable(_storage) {}

    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external {
        _notifyFee(
            _token,
            _profitSharingFee,
            _strategistFee,
            _platformFee
        );
    }

    function _notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) internal {
        address _controller = controller();
        address liquidator = IController(_controller).universalLiquidator();

        uint totalTransferAmount = _profitSharingFee.add(_strategistFee).add(_platformFee);
        require(totalTransferAmount > 0, "totalTransferAmount should not be 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), totalTransferAmount);

        address _targetToken = IController(_controller).targetToken();

        if (_token != _targetToken) {
            IERC20(_token).safeApprove(liquidator, 0);
            IERC20(_token).safeApprove(liquidator, _platformFee);

            uint amountOutMin = 1;

            if (_platformFee > 0) {
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    _targetToken,
                    _platformFee,
                    amountOutMin,
                    IController(_controller).protocolFeeReceiver()
                );
            }
        } else {
            IERC20(_targetToken).safeTransfer(IController(_controller).protocolFeeReceiver(), _platformFee);
        }

        if (_token != iFARM) {
            IERC20(_token).safeApprove(liquidator, 0);
            IERC20(_token).safeApprove(liquidator, _profitSharingFee.add(_strategistFee));

            uint amountOutMin = 1;

            if (_profitSharingFee > 0) {
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    iFARM,
                    _profitSharingFee,
                    amountOutMin,
                    IController(_controller).profitSharingReceiver()
                );
            }
            if (_strategistFee > 0) {
                IUniversalLiquidator(liquidator).swap(
                    _token,
                    iFARM,
                    _strategistFee,
                    amountOutMin,
                    IStrategy(msg.sender).strategist()
                );
            }
        } else {
            if (_strategistFee > 0) {
                IERC20(iFARM).safeTransfer(IStrategy(msg.sender).strategist(), _strategistFee);
            }
            IERC20(iFARM).safeTransfer(IController(_controller).profitSharingReceiver(), _profitSharingFee);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../inheritance/ControllableInit.sol";
import "../interface/IController.sol";
import "../interface/IRewardForwarder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _strategist
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    _setStrategist(_strategist);
    _setSell(true);
    _setSellFloor(0);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  // ========================= Internal & Private Functions =========================

  // ==================== Functionality ====================

  /**
    * @dev Same as `_notifyProfitAndBuybackInRewardToken` but does not perform a compounding buyback. Just takes fees
    *      instead.
    */
  function _notifyProfitInRewardToken(
      address _rewardToken,
      uint256 _rewardBalance
  ) internal {
      if (_rewardBalance > 100) {
          uint _feeDenominator = feeDenominator();
          uint256 strategistFee = _rewardBalance.mul(strategistFeeNumerator()).div(_feeDenominator);
          uint256 platformFee = _rewardBalance.mul(platformFeeNumerator()).div(_feeDenominator);
          uint256 profitSharingFee = _rewardBalance.mul(profitSharingNumerator()).div(_feeDenominator);

          address strategyFeeRecipient = strategist();
          address platformFeeRecipient = IController(controller()).governance();

          emit ProfitLogInReward(
              _rewardToken,
              _rewardBalance,
              profitSharingFee,
              block.timestamp
          );
          emit PlatformFeeLogInReward(
              platformFeeRecipient,
              _rewardToken,
              _rewardBalance,
              platformFee,
              block.timestamp
          );
          emit StrategistFeeLogInReward(
              strategyFeeRecipient,
              _rewardToken,
              _rewardBalance,
              strategistFee,
              block.timestamp
          );

          address rewardForwarder = IController(controller()).rewardForwarder();
          IERC20(_rewardToken).safeApprove(rewardForwarder, 0);
          IERC20(_rewardToken).safeApprove(rewardForwarder, _rewardBalance);

          // Distribute/send the fees
          IRewardForwarder(rewardForwarder).notifyFee(
              _rewardToken,
              profitSharingFee,
              strategistFee,
              platformFee
          );
      } else {
          emit ProfitLogInReward(_rewardToken, 0, 0, block.timestamp);
          emit PlatformFeeLogInReward(IController(controller()).governance(), _rewardToken, 0, 0, block.timestamp);
          emit StrategistFeeLogInReward(strategist(), _rewardToken, 0, 0, block.timestamp);
      }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../interface/IController.sol";
import "../inheritance/ControllableInit.sol";

contract BaseUpgradeableStrategyStorage is ControllableInit {

  event ProfitsNotCollected(
      address indexed rewardToken,
      bool sell,
      bool floor
  );
  event ProfitLogInReward(
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event ProfitAndBuybackLog(
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event PlatformFeeLogInReward(
      address indexed treasury,
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event StrategistFeeLogInReward(
      address indexed strategist,
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_TOKENS_SLOT = 0x45418d9b5c2787ae64acbffccad43f2b487c1a16e24385aa9d2b059f9d1d163c;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  bytes32 internal constant _STRATEGIST_SLOT = 0x6a7b588c950d46e2de3db2f157e5e0e4f29054c8d60f17bf0c30352e223a458d;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_TOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardTokens")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

    assert(_STRATEGIST_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.strategist")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public virtual view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setRewardTokens(address[] memory _rewardTokens) internal {
    setAddressArray(_REWARD_TOKENS_SLOT, _rewardTokens);
  }

  function isRewardToken(address _token) public view returns (bool) {
    return _isAddressInList(_token, rewardTokens());
  }

  function rewardTokens() public view returns (address[] memory) {
    return getAddressArray(_REWARD_TOKENS_SLOT);
  }

  function _isAddressInList(address _searchValue, address[] memory _list) internal pure returns (bool) {
    for (uint i = 0; i < _list.length; i++) {
      if (_list[i] == _searchValue) {
        return true;
      }
    }
    return false;
  }

  function _setStrategist(address _strategist) internal {
    setAddress(_STRATEGIST_SLOT, _strategist);
  }

  function strategist() public view returns (address) {
    return getAddress(_STRATEGIST_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public virtual view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return IController(controller()).profitSharingNumerator();
  }

  function platformFeeNumerator() public view returns (uint256) {
    return IController(controller()).platformFeeNumerator();
  }

  function strategistFeeNumerator() public view returns (uint256) {
    return IController(controller()).strategistFeeNumerator();
  }

  function feeDenominator() public view returns (uint256) {
    return IController(controller()).feeDenominator();
  }

  function universalLiquidator() public view returns (address) {
    return IController(controller()).universalLiquidator();
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

    function nextImplementationDelay() public view returns (uint256) {
        return IController(controller()).nextImplementationDelay();
    }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

      function setUint256Array(bytes32 slot, uint256[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setUint256(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function setAddressArray(bytes32 slot, address[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setAddress(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }


    function getUint256Array(bytes32 slot) internal view returns (uint[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new uint[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getUint256(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddressArray(bytes32 slot) internal view returns (address[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new address[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getAddress(bytes32(uint(slot) + 1 + i));
        }
    }

    function setBytes32(bytes32 slot, bytes32 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
        sstore(slot, _value)
        }
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
        str := sload(slot)
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * Same old `ReentrancyGuard`, but can be used by upgradable contracts
 */
contract ReentrancyGuardUpgradeable is Initializable {

    bytes32 internal constant _NOT_ENTERED_SLOT = 0x62ae7bf2df4e95c187ea09c8c47c3fc3d9abc36298f5b5b6c5e2e7b4b291fe25;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_getNotEntered(_NOT_ENTERED_SLOT), "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(_NOT_ENTERED_SLOT, false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    constructor() public {
        assert(_NOT_ENTERED_SLOT == bytes32(uint256(keccak256("eip1967.reentrancyGuard.notEntered")) - 1));
    }

    function initialize() public initializer {
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    function _getNotEntered(bytes32 slot) private view returns (bool) {
        uint str;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
        return str == 1;
    }

    function _setNotEntered(bytes32 slot, bool _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../inheritance/IUpgradeSource.sol";
import "./BaseUpgradeabilityProxy.sol";

contract StrategyProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the strategy
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success,) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./interface/IUpgradeSource.sol";
import "./upgradability/BaseUpgradeabilityProxy.sol";

contract VaultProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the vault
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success,) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract VaultStorage is Initializable {

    bytes32 internal constant _STRATEGY_SLOT = 0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
    bytes32 internal constant _UNDERLYING_SLOT = 0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
    bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT = 0x39122c9adfb653455d0c05043bd52fcfbc2be864e832efd3abc72ce5a3d7ed5a;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT = 0x469a3bad2fab7b936c45eecd1f5da52af89cead3e2ed7f732b6f3fc92ed32308;
    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0xb1acf527cd7cd1668b30e5a9a1c0d845714604de29ce560150922c9d8c0937df;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x3bc747f4b148b37be485de3223c90b4468252967d2ea7f9fcbd8b6e653f434c9;
    bytes32 internal constant _NEXT_STRATEGY_SLOT = 0xcd7bd9250b0e02f3b13eccf8c73ef5543cb618e0004628f9ca53b65fbdbde2d0;
    bytes32 internal constant _NEXT_STRATEGY_TIMESTAMP_SLOT = 0x5d2b24811886ad126f78c499d71a932a5435795e4f2f6552f0900f12d663cdcf;
    bytes32 internal constant _ALLOW_SHARE_PRICE_DECREASE_SLOT = 0x22f7033891e85fc76735ebd320e0d3f546da431c4729c2f6d2613b11923aaaed;
    bytes32 internal constant _WITHDRAW_BEFORE_REINVESTING_SLOT = 0x4215fbb95dc0890d3e1660fb9089350f2d3f350c0a756934874cae6febf42a79;
    bytes32 internal constant _PAUSED_SLOT = 0xf1cf856d03630b74791fc293cfafd739932a5a075b02d357fb7a726a38777930;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor() public {
        assert(_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1));
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
        assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
        assert(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestNumerator")) - 1));
        assert(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.vaultFractionToInvestDenominator")) - 1));
        assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementation")) - 1));
        assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextImplementationTimestamp")) - 1));
        assert(_NEXT_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextStrategy")) - 1));
        assert(_NEXT_STRATEGY_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.nextStrategyTimestamp")) - 1));
        assert(_ALLOW_SHARE_PRICE_DECREASE_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allowSharePriceDecrease")) - 1));
        assert(_WITHDRAW_BEFORE_REINVESTING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.withdrawBeforeReinvesting")) - 1));
        assert(_PAUSED_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.paused")) - 1));
    }

    function initialize(
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator,
        uint256 _underlyingUnit
    ) public initializer {
        _setUnderlying(_underlying);
        _setVaultFractionToInvestNumerator(_toInvestNumerator);
        _setVaultFractionToInvestDenominator(_toInvestDenominator);
        _setUnderlyingUnit(_underlyingUnit);
        _setNextStrategyTimestamp(0);
        _setNextStrategy(address(0));
        _setAllowSharePriceDecrease(false);
        _setWithdrawBeforeReinvesting(false);
    }

    function _setStrategy(address _address) internal {
        setAddress(_STRATEGY_SLOT, _address);
    }

    function _strategy() internal view returns (address) {
        return getAddress(_STRATEGY_SLOT);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _underlying() internal view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        setUint256(_UNDERLYING_UNIT_SLOT, _value);
    }

    function _underlyingUnit() internal view returns (uint256) {
        return getUint256(_UNDERLYING_UNIT_SLOT);
    }

    function _setVaultFractionToInvestNumerator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT, _value);
    }

    function _vaultFractionToInvestNumerator() internal view returns (uint256) {
        return getUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT);
    }

    function _setVaultFractionToInvestDenominator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT, _value);
    }

    function _vaultFractionToInvestDenominator() internal view returns (uint256) {
        return getUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT);
    }

    function _setAllowSharePriceDecrease(bool _value) internal {
        setBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT, _value);
    }

    function _allowSharePriceDecrease() internal view returns (bool) {
        return getBoolean(_ALLOW_SHARE_PRICE_DECREASE_SLOT);
    }

    function _setWithdrawBeforeReinvesting(bool _value) internal {
        setBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT, _value);
    }

    function _withdrawBeforeReinvesting() internal view returns (bool) {
        return getBoolean(_WITHDRAW_BEFORE_REINVESTING_SLOT);
    }

    function _setNextImplementation(address _address) internal {
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
    }

    function _nextImplementation() internal view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function _nextImplementationTimestamp() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    function _setNextStrategy(address _value) internal {
        setAddress(_NEXT_STRATEGY_SLOT, _value);
    }

    function _nextStrategy() internal view returns (address) {
        return getAddress(_NEXT_STRATEGY_SLOT);
    }

    function _setNextStrategyTimestamp(uint256 _value) internal {
        setUint256(_NEXT_STRATEGY_TIMESTAMP_SLOT, _value);
    }

    function _nextStrategyTimestamp() internal view returns (uint256) {
        return getUint256(_NEXT_STRATEGY_TIMESTAMP_SLOT);
    }

    function _implementation() internal view returns (address) {
        return getAddress(_IMPLEMENTATION_SLOT);
    }

    function _paused() internal view returns (bool) {
        return getBoolean(_PAUSED_SLOT);
    }

    function _setPaused(bool _value) internal {
        setBoolean(_PAUSED_SLOT, _value);
    }

    function setBoolean(bytes32 slot, bool _value) internal {
        setUint256(slot, _value ? 1 : 0);
    }

    function getBoolean(bytes32 slot) internal view returns (bool) {
        return (getUint256(slot) == 1);
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./interface/IController.sol";
import "./interface/IUpgradeSource.sol";
import "./inheritance/ControllableInit.sol";
import "./VaultStorage.sol";


contract VaultV1 is ERC20Upgradeable, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  /**
   * Caller has exchanged assets for shares, and transferred those shares to owner.
   *
   * MUST be emitted when tokens are deposited into the Vault via the mint and deposit methods.
   */
  event Deposit(
      address indexed sender,
      address indexed receiver,
      uint256 assets,
      uint256 shares
  );

  /**
   * Caller has exchanged shares, owned by owner, for assets, and transferred those assets to receiver.
   *
   * MUST be emitted when shares are withdrawn from the Vault in ERC4626.redeem or ERC4626.withdraw methods.
   */
  event Withdraw(
      address indexed sender,
      address indexed receiver,
      address indexed owner,
      uint256 assets,
      uint256 shares
  );
  event Invest(uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);


  constructor() public {
  }

  // the function is name differently to not cause inheritance clash in truffle and allows tests
  function initializeVault(
    address _storage,
    address _underlying,
    uint256 _toInvestNumerator,
    uint256 _toInvestDenominator
  ) public initializer {
    require(_toInvestNumerator <= _toInvestDenominator, "cannot invest more than 100%");
    require(_toInvestDenominator != 0, "cannot divide by 0");

    __ERC20_init(
      string(abi.encodePacked("FARM_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("f", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initialize(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    VaultStorage.initialize(
      _underlying,
      _toInvestNumerator,
      _toInvestDenominator,
      underlyingUnit
    );
  }

  function strategy() public view returns(address) {
    return _strategy();
  }

  function underlying() public view returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  function vaultFractionToInvestNumerator() public view returns(uint256) {
    return _vaultFractionToInvestNumerator();
  }

  function vaultFractionToInvestDenominator() public view returns(uint256) {
    return _vaultFractionToInvestDenominator();
  }

  function nextImplementation() public view returns(address) {
    return _nextImplementation();
  }

  function nextImplementationTimestamp() public view returns(uint256) {
    return _nextImplementationTimestamp();
  }

  function nextImplementationDelay() public view returns (uint256) {
    return IController(controller()).nextImplementationDelay();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "Strategy must be defined");
    _;
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "This smart contract has been grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined onlyControllerOrGovernance external {
    // ensure that new funds are invested too
    invest();
    IStrategy(strategy()).doHardWork();
  }

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInVault() view public returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() view public returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function getPricePerFullShare() public view returns (uint256) {
    return totalSupply() == 0
        ? underlyingUnit()
        : underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /* get the user's share (in underlying)
  */
  function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function nextStrategy() public view returns (address) {
    return _nextStrategy();
  }

  function nextStrategyTimestamp() public view returns (uint256) {
    return _nextStrategyTimestamp();
  }

  function canUpdateStrategy(address _strategy) public view returns (bool) {
    bool isStrategyNotSetYet = strategy() == address(0);
    bool hasTimelockPassed = block.timestamp > nextStrategyTimestamp() && nextStrategyTimestamp() != 0;
    return isStrategyNotSetYet || (_strategy == nextStrategy() && hasTimelockPassed);
  }

  /**
  * Indicates that the strategy update will happen in the future
  */
  function announceStrategyUpdate(address _strategy) public onlyControllerOrGovernance {
    // records a new timestamp
    uint256 when = block.timestamp.add(nextImplementationDelay());
    _setNextStrategyTimestamp(when);
    _setNextStrategy(_strategy);
    emit StrategyAnnounced(_strategy, when);
  }

  /**
  * Finalizes (or cancels) the strategy update by resetting the data
  */
  function finalizeStrategyUpdate() public onlyControllerOrGovernance {
    _setNextStrategyTimestamp(0);
    _setNextStrategy(address(0));
  }

  function setStrategy(address _strategy) public onlyControllerOrGovernance {
    require(canUpdateStrategy(_strategy),
      "The strategy exists and switch timelock did not elapse yet");
    require(_strategy != address(0), "new _strategy cannot be empty");
    require(IStrategy(_strategy).underlying() == address(underlying()), "Vault underlying must match Strategy underlying");
    require(IStrategy(_strategy).vault() == address(this), "the strategy does not belong to this vault");

    emit StrategyChanged(_strategy, strategy());
    if (address(_strategy) != address(strategy())) {
      if (address(strategy()) != address(0)) { // if the original strategy (no underscore) is defined
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IStrategy(strategy()).withdrawAllToVault();
      }
      _setStrategy(_strategy);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
      IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }
    finalizeStrategyUpdate();
  }

  function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external onlyGovernance {
    require(denominator > 0, "denominator must be greater than 0");
    require(numerator <= denominator, "denominator must be greater than or equal to the numerator");
    _setVaultFractionToInvestNumerator(numerator);
    _setVaultFractionToInvestDenominator(denominator);
  }

  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
        .mul(vaultFractionToInvestNumerator())
        .div(vaultFractionToInvestDenominator());
    uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInVault()
        // TODO: we think that the "else" branch of the ternary operation is not
        // going to get hit
        ? remainingToInvest : underlyingBalanceInVault();
    }
  }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares.
  * Approval is assumed.
  */
  function deposit(uint256 amount) external nonReentrant defense {
    _deposit(amount, msg.sender, msg.sender);
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares
  * assigned to the holder.
  * This facilitates depositing for someone else (using DepositHelper)
  */
  function depositFor(uint256 amount, address holder) public nonReentrant defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdraw(uint256 shares) external nonReentrant defense {
    _withdraw(shares, msg.sender, msg.sender);
  }

  function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != address(0), "holder must be defined");

    if (address(strategy()) != address(0)) {
      require(IStrategy(strategy()).depositArbCheck(), "Too much arb");
    }

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(sender, beneficiary, amount, toMint);
  }

  function _withdraw(uint256 numberOfShares, address receiver, address owner) internal {
    require(totalSupply() > 0, "Vault has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    uint256 totalSupply = totalSupply();

    address sender = msg.sender;
      if (sender != owner) {
        uint256 currentAllowance = allowance(owner, sender);
        if (currentAllowance != uint(-1)) {
          require(currentAllowance >= numberOfShares, "ERC20: transfer amount exceeds allowance");
          _approve(owner, sender, currentAllowance - numberOfShares);
        }
      }
    _burn(owner, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20Upgradeable(underlying()).safeTransfer(receiver, underlyingAmountToWithdraw);

    // update the withdrawal amount for the holder
    emit Withdraw(sender, receiver, owner, underlyingAmountToWithdraw, numberOfShares);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function shouldUpgrade() external view override returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./interface/IERC4626.sol";
import "./VaultV1.sol";

contract VaultV2 is IERC4626, VaultV1 {

    /// By default, the constant `10` is a uint8. This implicitly converts it to `uint256`
    uint256 public constant TEN = 10;

    function asset() public view override returns (address) {
        return underlying();
    }

    function totalAssets() public view override returns (uint256) {
        return underlyingBalanceWithInvestment();
    }

    function assetsPerShare() public view override returns (uint256) {
        return convertToAssets(TEN ** decimals());
    }

    function assetsOf(address _depositor) public view override returns (uint256) {
        return totalAssets() * balanceOf(_depositor) / totalSupply();
    }

    function maxDeposit(address /*caller*/) public view override returns (uint256) {
        return uint(-1);
    }

    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        return convertToShares(_assets);
    }

    function deposit(uint256 _assets, address _receiver) public override nonReentrant defense returns (uint256) {
        uint shares = convertToShares(_assets);
        _deposit(_assets, msg.sender, _receiver);
        return shares;
    }

    function maxMint(address /*caller*/) public view override returns (uint256) {
        return uint(-1);
    }

    function previewMint(uint256 _shares) public view override returns (uint256) {
        return convertToAssets(_shares);
    }

    function mint(uint256 _shares, address _receiver) public override nonReentrant defense returns (uint256) {
        uint assets = convertToAssets(_shares);
        _deposit(assets, msg.sender, _receiver);
        return assets;
    }

    function maxWithdraw(address _caller) public view override returns (uint256) {
        return assetsOf(_caller);
    }

    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        return convertToShares(_assets);
    }

    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    )
    public override
    nonReentrant
    defense
    returns (uint256) {
        uint256 shares = convertToShares(_assets);
        _withdraw(shares, _receiver, _owner);
        return shares;
    }

    function maxRedeem(address _caller) public view override returns (uint256) {
        return balanceOf(_caller);
    }

    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        return convertToAssets(_shares);
    }

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    )
    public override
    nonReentrant
    defense
    returns (uint256) {
        uint256 assets = convertToAssets(_shares);
        _withdraw(_shares, _receiver, _owner);
        return assets;
    }

    // ========================= Conversion Functions =========================

    function convertToAssets(uint256 _shares) public view returns (uint256) {
        return totalAssets() == 0 || totalSupply() == 0
            ? _shares * (TEN ** ERC20Upgradeable(underlying()).decimals()) / (TEN ** decimals())
            : _shares * totalAssets() / totalSupply();
    }

    function convertToShares(uint256 _assets) public view returns (uint256) {
        return totalAssets() == 0 || totalSupply() == 0
            ? _assets * (TEN ** decimals()) / (TEN ** ERC20Upgradeable(underlying()).decimals())
            : _assets * totalSupply() / totalAssets();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/balancer/IBVault.sol";
import "../../base/interface/balancer/Gauge.sol";
import "../../base/interface/balancer/IBalancerMinter.sol";
import "./interface/IAuraBooster.sol";
import "./interface/IAuraBaseRewardPool.sol";

contract AuraStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
  address public constant bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant booster = address(0x98Ef32edd24e2c92525E59afc4475C1242a30184);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _AURA_POOLID_SLOT = 0xbc10a276e435b4e9a9e92986f93a224a34b50c1898d7551c38ef30a08efadec4;
  bytes32 internal constant _BALANCER_POOLID_SLOT = 0xbf3f653715dd45c84a3367d2975f271307cb967d6ce603dc4f0def2ad909ca64;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_AURA_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.auraPoolId")) - 1));
    assert(_BALANCER_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.balancerPoolId")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    bytes32 _balancerPoolID,
    uint256 _auraPoolID,
    address _depositToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    (address _lpt,) = IBVault(bVault).getPool(_balancerPoolID);
    require(_lpt == _underlying, "Underlying mismatch");
    (_lpt,,,,,) = IAuraBooster(booster).poolInfo(_auraPoolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");

    _setAuraPoolId(_auraPoolID);
    _setBalancerPoolId(_balancerPoolID);
    _setDepositToken(_depositToken);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = IAuraBaseRewardPool(rewardPool()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        IAuraBaseRewardPool(rewardPool()).withdrawAllAndUnwrap(false); //don't claim rewards
    }
  }

  function _partialWithdrawalRewardPool(uint256 amount) internal {
    IAuraBaseRewardPool(rewardPool()).withdrawAndUnwrap(amount, false);  //don't claim rewards at this point
  }

  function _exitRewardPool() internal {
      uint256 stakedBalance = _rewardPoolBalance();
      if (stakedBalance != 0) {
          IAuraBaseRewardPool(rewardPool()).withdrawAllAndUnwrap(true);
      }
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(booster, 0);
    IERC20(underlying_).safeApprove(booster, entireBalance);
    IAuraBooster(booster).depositAll(auraPoolId(), true); //deposit and stake
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function changeDepositToken(address _depositToken) public onlyGovernance {
    _setDepositToken(_depositToken);
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerDeposit(
    address tokenIn,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    (address[] memory poolTokens,,) = IBVault(bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    uint256[] memory amountsIn = new uint256[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
      amountsIn[i] = poolTokens[i] == tokenIn ? amountIn : 0;
    }

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    _approveIfNeed(tokenIn, bVault, amountIn);
    IBVault(bVault).joinPool(
      poolId,
      address(this),
      address(this),
      request
    );
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0) {
        continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, rewardBalance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, rewardBalance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _depositToken = depositToken();
    if (_depositToken != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _depositToken, remainingRewardBalance, 1, address(this));
    }

    uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
    if (tokenBalance > 0 && !(_depositToken == underlying())) {
      depositLP();
    }
  }

  function depositLP() internal {
    address _depositToken = depositToken();
    uint256 depositTokenBalance = IERC20(_depositToken).balanceOf(address(this));

    _balancerDeposit(
      _depositToken,
      balancerPoolId(),
      depositTokenBalance,
      1
    );
  }

  /** Withdraws all the asset to the vault
   */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    _exitRewardPool();
    _liquidateReward();
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /** Withdraws specific amount of asset to the vault
   */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IAuraBaseRewardPool(rewardPool()).getReward();
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  /** Aura deposit pool ID
   */
  function _setAuraPoolId(uint256 _value) internal {
    setUint256(_AURA_POOLID_SLOT, _value);
  }

  /** Balancer deposit pool ID
   */
  function _setBalancerPoolId(bytes32 _value) internal {
    setBytes32(_BALANCER_POOLID_SLOT, _value);
  }

  function auraPoolId() public view returns (uint256) {
    return getUint256(_AURA_POOLID_SLOT);
  }

  function balancerPoolId() public view returns (bytes32) {
    return getBytes32(_BALANCER_POOLID_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_auraBAL_wstETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xc7FA3A3527435720f0e2a4c1378335324dd4F9b3);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address wsteth = address(0x5979D7b546E38E414F7E9822514be443A4800529);
    address rewardPool = address(0x1597010ffE2e25a584D9705C1e48585BbfE56fC0);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xc7fa3a3527435720f0e2a4c1378335324dd4f9b3000200000000000000000459,  // Balancer Pool id
      9,      // Aura Pool id
      wsteth   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_bbaUSD_v2 is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xc6EeE8cb7643eC2F05F46d569e9eC8EF8b41b389);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address rewardPool = address(0x237c47c7A0c4236049B872A6972Cfc0729B0D362);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xc6eee8cb7643ec2f05f46d569e9ec8ef8b41b389000000000000000000000475,  // Balancer Pool id
      18,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_bbaUSD is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xEE02583596AEE94ccCB7e8ccd3921d955f17982A);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0x4fA10A40407BA386E3A863381200b4e6049950fa);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xee02583596aee94cccb7e8ccd3921d955f17982a00000000000000000000040a,  // Balancer Pool id
      2,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_bbwstETH_bbaUSD is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9fB7D6dCAC7b6aa20108BaD226c35B85A9e31B63);
    address bbwsteth = address(0x5A7f39435fD9c381e4932fa2047C9a5136A5E3E7);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0xCA995CAab490EFb2122a046866a1ab10a9A32939);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x9fb7d6dcac7b6aa20108bad226c35b85a9e31b63000200000000000000000412,  // Balancer Pool id
      8,      // Aura Pool id
      bbwsteth   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_DOLA_USDC is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8bc65Eed474D1A00555825c91FeAb6A8255C2107);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0xAc7025Dec5E216025C76414f6ac1976227c20Ff0);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x8bc65eed474d1a00555825c91feab6a8255c2107000000000000000000000453,  // Balancer Pool id
      12,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_MAGIC_USDC is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xb3028Ca124B80CFE6E9CA57B70eF2F0CCC41eBd4);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address rewardPool = address(0xa4a5be1f830a6e94B844E12f86D97ff54a01A573);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xb3028ca124b80cfe6e9ca57b70ef2f0ccc41ebd40002000000000000000000ba,  // Balancer Pool id
      6,      // Aura Pool id
      usdc   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_PAL_OHM is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8d333f82e0693f53fA48c40d5D4547142E907e1D);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address ohm = address(0xf0cb2dc0db5e6c66B9a70Ac27B06b878da017028);
    address rewardPool = address(0x9fC8196aAdCd24a5ea90e65d975Ef3332D7435db);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x8d333f82e0693f53fa48c40d5d4547142e907e1d000200000000000000000437,  // Balancer Pool id
      11,      // Aura Pool id
      ohm   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_RDNT_ETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x32dF62dc3aEd2cD6224193052Ce665DC18165841);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0xa17492d89cB2D0bE1dDbd0008F8585EDc5B0ACf3);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x32df62dc3aed2cd6224193052ce665dc181658410002000000000000000003bd,  // Balancer Pool id
      1,      // Aura Pool id
      weth   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_rETH_aWETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xCba9Ff45cfB9cE238AfDE32b0148Eb82CbE63562);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0x0DCb3664BaFe8f7Afb2174C1FF736fe9011De9ff);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xcba9ff45cfb9ce238afde32b0148eb82cbe635620000000000000000000003fd,  // Balancer Pool id
      4,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_tBTC_wBTC is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x542F16DA0efB162D20bF4358EfA095B70A100f9E);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0xFCC94454061b7fDF0B03b0D2107Ecd9c6c74ddfd);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x542f16da0efb162d20bf4358efa095b70a100f9e000000000000000000000436,  // Balancer Pool id
      5,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_tBTC_wETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xc9f52540976385A84BF416903e1Ca3983c539E34);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0x9626E4D2b444f386fD63181f65dfEB8D141E1824);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0xc9f52540976385a84bf416903e1ca3983c539e34000200000000000000000434,  // Balancer Pool id
      3,      // Aura Pool id
      weth   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_wstETH_aWETH_v2 is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x45C4D1376943Ab28802B995aCfFC04903Eb5223f);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address rewardPool = address(0x10dCf485EA947faf9A9B819A2d3207323d0c72Ca);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x45c4d1376943ab28802b995acffc04903eb5223f000000000000000000000470,  // Balancer Pool id
      17,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_wstETH_aWETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7f39435fD9c381e4932fa2047C9a5136A5E3E7);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address rewardPool = address(0x2a288e87A044eA6a73a19178EC11903c4DF68f17);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x5a7f39435fd9c381e4932fa2047c9a5136a5e3e7000000000000000000000400,  // Balancer Pool id
      7,      // Aura Pool id
      underlying   //depositToken
    );
    rewardTokens = [aura, bal, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AuraStrategy.sol";

contract AuraStrategyMainnet_wstETH_wETH is AuraStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f);
    address aura = address(0x1509706a6c66CA549ff0cB464de88231DDBe213B);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address rewardPool = address(0x49e998899FF11598182918098588E8b90d7f60D3);
    AuraStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      0x36bf227d6bac96e2ab1ebb5492ecec69c691943f000200000000000000000316,  // Balancer Pool id
      0,      // Aura Pool id
      weth   //depositToken
    );
    rewardTokens = [aura, bal];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IAuraBaseRewardPool {

    function balanceOf(address account) external view returns(uint256 amount);

    function pid() external view returns (uint256 _pid);

    function stakingToken() external view returns (address _stakingToken);

    function getReward() external;

    function stake(uint256 _amount) external;

    function stakeAll() external;

    function withdraw(uint256 amount, bool claim) external;

    function withdrawAll(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IAuraBooster {
    
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;

    function depositAll(uint256 _pid, bool _stake) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdrawAll(uint256 _pid) external;

    function poolInfo(uint256 _pid) external view returns (address lpToken, address, address, address, address, bool);

    function earmarkRewards(uint256 _pid) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/solidLizard/ILizardRouter.sol";
import "../../base/interface/balancer/IBVault.sol";
import "../../base/interface/balancer/Gauge.sol";
import "../../base/interface/balancer/IBalancerMinter.sol";

contract BalancerStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
  address public constant lizardRouter = address(0xF26515D5482e2C2FD237149bF6A653dA4794b3D0);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _BVAULT_SLOT = 0x85cbd475ba105ca98d9a2db62dcf7cf3c0074b36303ef64160d68a3e0fdd3c67;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _BOOSTED_POOL = 0xd816e748a078d825fa9cc9dc9335909f9baa20dc1b5619211972fc7e672bd2fb;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  mapping(address => mapping(address => bytes32)) public poolIds;
  mapping(address => mapping(address => address)) public router;
  address[] public rewardTokens;
  mapping(address => mapping(address => bool)) public deposit;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_BVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.bVault")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_BOOSTED_POOL == bytes32(uint256(keccak256("eip1967.strategyStorage.boostedPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _bVault,
    bytes32 _poolID,
    address _depositToken,
    bool _boosted
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    (address _lpt,) = IBVault(_bVault).getPool(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolID);
    _setBVault(_bVault);
    _setDepositToken(_depositToken);
    _setBoostedPool(_boosted);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = Gauge(rewardPool()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    address rewardPool_ = rewardPool();
    Gauge(rewardPool_).withdraw(
      Math.min(Gauge(rewardPool_).balanceOf(address(this)), amount)
    );
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    Gauge(rewardPool_).deposit(entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
  }

  function addRewardToken(address _token, address[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath);
  }

  function setBalancerSwapPoolId(address _sellToken, address _buyToken, bytes32 _poolId) public onlyGovernance {
    poolIds[_sellToken][_buyToken] = _poolId;
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _camelotSwap(
    address sellToken,
    address buyToken,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address[] memory path = new address[](2);
    path[0] = sellToken;
    path[1] = buyToken;
    IERC20(sellToken).safeApprove(camelotRouter, 0);
    IERC20(sellToken).safeApprove(camelotRouter, amountIn);
    ICamelotRouter(camelotRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn, minAmountOut, path, address(this), harvestMSIG, block.timestamp
    );
  }

  function _lizardSwap(
    address sellToken,
    address buyToken,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IERC20(sellToken).safeApprove(lizardRouter, 0);
    IERC20(sellToken).safeApprove(lizardRouter, amountIn);
    ILizardRouter(lizardRouter).swapExactTokensForTokensSimple(
      amountIn, minAmountOut, sellToken, buyToken, false, address(this), block.timestamp
    );
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address _bVault = bVault();
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, _bVault, amountIn);
    IBVault(_bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  function _balancerDeposit(
    address tokenIn,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    address _bVault = bVault();
    (address[] memory poolTokens,,) = IBVault(_bVault).getPoolTokens(poolId);
    uint256 _nTokens = poolTokens.length;

    IAsset[] memory assets = new IAsset[](_nTokens);
    for (uint256 i = 0; i < _nTokens; i++) {
      assets[i] = IAsset(poolTokens[i]);
    }

    IBVault.JoinKind joinKind = IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;

    uint256[] memory amountsIn = new uint256[](_nTokens);
    for (uint256 j = 0; j < amountsIn.length; j++) {
      amountsIn[j] = address(assets[j]) == tokenIn ? amountIn : 0;
    }

    bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

    IBVault.JoinPoolRequest memory request;
    request.assets = assets;
    request.maxAmountsIn = amountsIn;
    request.userData = userData;
    request.fromInternalBalance = false;

    _approveIfNeed(tokenIn, _bVault, amountIn);
    IBVault(_bVault).joinPool(
      poolId,
      address(this),
      address(this),
      request
    );
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0) {
        continue;
      }
      if (reward2WETH[token].length < 2) {
        continue;
      }
      for (uint256 j = 0; j < reward2WETH[token].length - 1; j++) {
        address sellToken = reward2WETH[token][j];
        address buyToken = reward2WETH[token][j+1];
        uint256 sellTokenBalance = IERC20(sellToken).balanceOf(address(this));
        if (poolIds[sellToken][buyToken] == bytes32(0)) {
          if (router[sellToken][buyToken] == lizardRouter) {
            _lizardSwap(sellToken, buyToken, sellTokenBalance, 1);
          } else if (router[sellToken][buyToken] == camelotRouter) {
            _camelotSwap(sellToken, buyToken, sellTokenBalance, 1);
          }
        } else {
          if (deposit[sellToken][buyToken]) {
            _balancerDeposit(
              sellToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          } else {
            _balancerSwap(
              sellToken,
              buyToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          }
        }
      }
    }

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (WETH2deposit.length > 1) { //else we assume WETH is the deposit token, no need to swap
      for(uint256 i = 0; i < WETH2deposit.length - 1; i++){
        address sellToken = WETH2deposit[i];
        address buyToken = WETH2deposit[i+1];
        uint256 sellTokenBalance = IERC20(sellToken).balanceOf(address(this));
        if (poolIds[sellToken][buyToken] == bytes32(0)) {
          if (router[sellToken][buyToken] == lizardRouter) {
            _lizardSwap(sellToken, buyToken, sellTokenBalance, 1);
          } else if (router[sellToken][buyToken] == camelotRouter) {
            _camelotSwap(sellToken, buyToken, sellTokenBalance, 1);
          }
        } else {
          if (deposit[sellToken][buyToken]) {
            _balancerDeposit(
              sellToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          } else {
            _balancerSwap(
              sellToken,
              buyToken,
              poolIds[sellToken][buyToken],
              sellTokenBalance,
              1
            );
          }
        }
      }
    }

    address _depositToken = depositToken();
    uint256 tokenBalance = IERC20(depositToken()).balanceOf(address(this));
    if (tokenBalance > 0 && !(_depositToken == underlying())) {
      depositLP();
    }
  }

  function depositLP() internal {
    address _depositToken = depositToken();
    bytes32 _poolId = poolId();
    uint256 depositTokenBalance = IERC20(_depositToken).balanceOf(address(this));

    if (boostedPool()) {
      _balancerSwap(
        _depositToken,
        underlying(),
        _poolId,
        depositTokenBalance,
        1
      );
    } else {
      _balancerDeposit(
        _depositToken,
        _poolId,
        depositTokenBalance,
        1
      );
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    address _rewardPool = rewardPool();
    IBalancerMinter(Gauge(_rewardPool).bal_pseudo_minter()).mint(_rewardPool);
    Gauge(_rewardPool).claim_rewards();
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(bytes32 _value) internal {
    setBytes32(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (bytes32) {
    return getBytes32(_POOLID_SLOT);
  }

  function _setBVault(address _address) internal {
    setAddress(_BVAULT_SLOT, _address);
  }

  function bVault() public view returns (address) {
    return getAddress(_BVAULT_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setBoostedPool(bool _boosted) internal {
    setBoolean(_BOOSTED_POOL, _boosted);
  }

  function boostedPool() public view returns (bool) {
    return getBoolean(_BOOSTED_POOL);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_bbaUSD is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xEE02583596AEE94ccCB7e8ccd3921d955f17982A);
    address bbausdc = address(0x7c82A23B4C48D796dee36A9cA215b641C6a8709d);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0xb0Bdd5000307144Ed7d30Cf4025Ec1FBA9D79D65);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xee02583596aee94cccb7e8ccd3921d955f17982a00000000000000000000040a,  // Pool id
      bbausdc,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, usdc, bbausdc];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[usdc][bbausdc] = 0x7c82a23b4c48d796dee36a9ca215b641c6a8709d000000000000000000000406;
    router[weth][usdc] = camelotRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_bbwstETH_bbaUSD is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9fB7D6dCAC7b6aa20108BaD226c35B85A9e31B63);
    address bbwsteth = address(0x5A7f39435fD9c381e4932fa2047C9a5136A5E3E7);
    address bbaweth = address(0xDa1CD1711743e57Dd57102E9e61b75f3587703da);
    address wsteth = address(0x5979D7b546E38E414F7E9822514be443A4800529);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address ldo = address(0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60);
    address gauge = address(0xc01F38a0557C53d3b0427F644998d1F76972ecA1);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x9fb7d6dcac7b6aa20108bad226c35b85a9e31b63000200000000000000000412,  // Pool id
      bbwsteth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wsteth, weth];
    WETH2deposit = [weth, bbaweth, bbwsteth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[wsteth][weth] = 0xfb5e6d0c1dfed2ba000fbc040ab8df3615ac329c000000000000000000000159;
    poolIds[weth][bbaweth] = 0xda1cd1711743e57dd57102e9e61b75f3587703da0000000000000000000003fc;
    poolIds[bbaweth][bbwsteth] = 0x5a7f39435fd9c381e4932fa2047c9a5136a5e3e7000000000000000000000400;
    router[ldo][wsteth] = camelotRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_RDNT_ETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x32dF62dc3aEd2cD6224193052Ce665DC18165841);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0xcf9f895296F5e1D66a7D4dcf1d92e1B435E9f999);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x32df62dc3aed2cd6224193052ce665dc181658410002000000000000000003bd,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_rETH_aWETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xCba9Ff45cfB9cE238AfDE32b0148Eb82CbE63562);
    address bbaweth = address(0xDa1CD1711743e57Dd57102E9e61b75f3587703da);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0x6c34d77a57226f9Df6eC476B20913350832eBfEC);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xcba9ff45cfb9ce238afde32b0148eb82cbe635620000000000000000000003fd,  // Pool id
      bbaweth,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, bbaweth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[weth][bbaweth] = 0xda1cd1711743e57dd57102e9e61b75f3587703da0000000000000000000003fc;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_tBTC_wBTC is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x542F16DA0efB162D20bF4358EfA095B70A100f9E);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address tbtc = address(0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40);
    address gauge = address(0xb438c6cc53315FfA3fcD1bc8b27d6c3155b0B56A);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x542f16da0efb162d20bf4358efa095b70a100f9e000000000000000000000436,  // Pool id
      tbtc,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    WETH2deposit = [weth, tbtc];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[weth][tbtc] = 0xc9f52540976385a84bf416903e1ca3983c539e34000200000000000000000434;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_tBTC_wETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xc9f52540976385A84BF416903e1Ca3983c539E34);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0x011417BBED6FC9cefF36C032D431b0eFcBA7f8B3);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0xc9f52540976385a84bf416903e1ca3983c539e34000200000000000000000434,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_wBTC_wETH_USDC is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x64541216bAFFFEec8ea535BB71Fbc927831d0595);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0x820A9F3897B2aBFeEcE95dF4aA71D8a4fb448C3B);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_wstETH_aWETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7f39435fD9c381e4932fa2047C9a5136A5E3E7);
    address bbaweth = address(0xDa1CD1711743e57Dd57102E9e61b75f3587703da);
    address wsteth = address(0x5979D7b546E38E414F7E9822514be443A4800529);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address ldo = address(0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60);
    address gauge = address(0xae9F2cE52FE89DD78e6F13d5d7b33125aE3dFF8C);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x5a7f39435fd9c381e4932fa2047c9a5136a5e3e7000000000000000000000400,  // Pool id
      bbaweth,   //depositToken
      true      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wsteth, weth];
    WETH2deposit = [weth, bbaweth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[wsteth][weth] = 0xfb5e6d0c1dfed2ba000fbc040ab8df3615ac329c000000000000000000000159;
    poolIds[weth][bbaweth] = 0xda1cd1711743e57dd57102e9e61b75f3587703da0000000000000000000003fc;
    router[ldo][wsteth] = camelotRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_wstETH_USDC is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x178E029173417b1F9C8bC16DCeC6f697bC323746);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address ldo = address(0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60);
    address wbtc = address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address wsteth = address(0x5979D7b546E38E414F7E9822514be443A4800529);
    address gauge = address(0x9232EE56ab3167e2d77E491fBa82baBf963cCaCE);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x178e029173417b1f9c8bc16dcec6f697bc323746000200000000000000000158,  // Pool id
      wsteth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal, ldo];
    reward2WETH[bal] = [bal, weth];
    reward2WETH[ldo] = [ldo, wbtc, weth];
    WETH2deposit = [weth, wsteth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
    poolIds[ldo][wbtc] = 0x9cc5d63aa18e6d33180453d5831acdd6b483e823000100000000000000000327;
    poolIds[weth][wsteth] = 0x36bf227d6bac96e2ab1ebb5492ecec69c691943f000200000000000000000316;
    router[wbtc][weth] = camelotRouter;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BalancerStrategy.sol";

contract BalancerStrategyMainnet_wstETH_wETH is BalancerStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x36bf227d6BaC96e2aB1EbB5492ECec69C691943f);
    address bal = address(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8);
    address gauge = address(0x8F0B53F3BA19Ee31C0A73a6F6D84106340fadf5f);
    BalancerStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      gauge,
      address(0xBA12222222228d8Ba445958a75a0704d566BF2C8), //balancer vault
      0x36bf227d6bac96e2ab1ebb5492ecec69c691943f000200000000000000000316,  // Pool id
      weth,   //depositToken
      false      //boosted
    );
    rewardTokens = [bal];
    reward2WETH[bal] = [bal, weth];
    poolIds[bal][weth] = 0xcc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/INFTPool.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";
import "../../base/interface/IUniversalLiquidator.sol";

contract CamelotNFTStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
  address public constant xGrail = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POS_ID_SLOT = 0x025da88341279feed86c02593d3d75bb35ff95cb72e32ffd093929b008413de5;
  bytes32 internal constant _XGRAIL_VAULT_SLOT = 0xd445aff5601e22e4f2e49f44eb54e33aa29670745d5241914b5369f65f9d43d0;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POS_ID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.posId")) - 1));
    assert(_XGRAIL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.xGrailVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _grail,
    address _nftPool,
    address _xGrailVault,
    address _potPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _nftPool,
      _grail,
      harvestMSIG
    );

    address _lpt;
    (_lpt,,,,,,,) = INFTPool(_nftPool).getPoolInfo();
    require(_lpt == underlying(), "NFTPool Info does not match underlying");
    setAddress(_XGRAIL_VAULT_SLOT, _xGrailVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
    if (posId() > 0) {
      (bal,,,,,,,) = INFTPool(rewardPool()).getStakingPosition(posId());
    } else {
      bal = 0;
    }
  }

  function exitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      INFTPool(rewardPool()).withdrawFromPosition(posId(), stakedBalance);
    }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
      INFTPool(rewardPool()).withdrawFromPosition(posId(), amount);
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      INFTPool(rewardPool()).emergencyWithdraw(posId());
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _rewardPool = rewardPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_rewardPool, 0);
    IERC20(_underlying).safeApprove(_rewardPool, entireBalance);
    if (rewardPoolBalance() > 0) {  //We already have a position. Withdraw from staking, add to position, stake again.
      INFTPool(_rewardPool).addToPosition(posId(), entireBalance);
    } else {                        //We do not yet have a position. Create a position and store the position ID. Then stake.
      INFTPool(_rewardPool).createPosition(entireBalance, 0);
      uint256 newPosId = INFTPool(_rewardPool).tokenOfOwnerByIndex(address(this), 0);
      _setPosId(newPosId);
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _claimRewards() internal {
    uint256 _posId = posId();
    if (_posId > 0){
      INFTPool(rewardPool()).harvestPosition(_posId);
    }
  }

  function _liquidateRewards(uint256 _xGrailAmount) internal {
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    uint256 notifyBalance;
    if (_xGrailAmount > rewardBalance.mul(9)) {
      notifyBalance = rewardBalance.mul(10);
    } else {
      notifyBalance = rewardBalance.add(_xGrailAmount);
    }
    _notifyProfitInRewardToken(_rewardToken, notifyBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance < 1e6) {
      _handleXGrail();
      return;
    }

    IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
    IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);

    address _underlying = underlying();

    address token0 = ICamelotPair(_underlying).token0();
    address token1 = ICamelotPair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    uint256 token0Amount;
    if (_rewardToken != token0) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token0, toToken0, 1, address(this));
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (_rewardToken != token1) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token1, toToken1, 1, address(this));
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    IERC20(token0).safeApprove(camelotRouter, 0);
    IERC20(token0).safeApprove(camelotRouter, token0Amount);

    IERC20(token1).safeApprove(camelotRouter, 0);
    IERC20(token1).safeApprove(camelotRouter, token1Amount);

    ICamelotRouter(camelotRouter).addLiquidity(
      token0,
      token1,
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );

    _handleXGrail();
  }

  function _handleXGrail() internal {
    uint256 balance = IERC20(xGrail).balanceOf(address(this));
    if (balance == 0) { return; }
    address _xGrailVault = xGrailVault();
    address _potPool = potPool();

    IERC20(xGrail).safeApprove(_xGrailVault, 0);
    IERC20(xGrail).safeApprove(_xGrailVault, balance);
    IVault(_xGrailVault).deposit(balance);

    uint256 vaultBalance = IERC20(_xGrailVault).balanceOf(address(this));
    IERC20(_xGrailVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_xGrailVault, vaultBalance);
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimRewards();
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    investAllUnderlying();
  }

  function _setPosId(uint256 _value) internal {
    setUint256(_POS_ID_SLOT, _value);
  }

  function posId() public view returns (uint256) {
    return getUint256(_POS_ID_SLOT);
  }

  function setXGrailVault(address _value) public onlyGovernance {
    require(xGrailVault() == address(0), "Hodl vault already set");
    setAddress(_XGRAIL_VAULT_SLOT, _value);
  }

  function xGrailVault() public view returns (address) {
    return getAddress(_XGRAIL_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the WETH unwrapping

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function onNFTHarvest(address /*operator*/, address /*to*/, uint256 /*tokenId*/, uint256 /*grailAmount*/, uint256 /*xGrailAmount*/) external pure returns (bool) {return true;}
  function onNFTAddToPosition(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
  function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNFTStrategy.sol";

contract CamelotNFTStrategyMainnet_ARB_ETH is CamelotNFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa6c5C7D189fA4eB5Af8ba34E63dCDD3a635D433f);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x9FFC53cE956Bf040c4465B73B3cfC04569EDaEf1);
    CamelotNFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNFTStrategy.sol";

contract CamelotNFTStrategyMainnet_ETH_USDC is CamelotNFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x84652bb2539513BAf36e225c930Fdd8eaa63CE27);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x6BC938abA940fB828D39Daa23A94dfc522120C11);
    CamelotNFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNFTStrategy.sol";

contract CamelotNFTStrategyMainnet_GRAIL_ARB is CamelotNFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xC9da32C3b444F15412F7FeAC6104d1E258D23B1b);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x2a9766A73999a7dE16A4b4E345c8a6fC4E4288Cc);
    CamelotNFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNFTStrategy.sol";

contract CamelotNFTStrategyMainnet_GRAIL_USDC is CamelotNFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x87425D8812f44726091831a9A109f4bDc3eA34b4);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x9CB2F70C8360461ab35e31A07ae9e94B26CA8A86);
    CamelotNFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/INFTPool.sol";
import "../../base/interface/camelot/INitroPool.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";
import "../../base/interface/IUniversalLiquidator.sol";

contract CamelotNitroIFarmStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
  address public constant xGrail = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
  address public constant iFarm = address(0x9dCA587dc65AC0a043828B0acd946d71eb8D46c1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POS_ID_SLOT = 0x025da88341279feed86c02593d3d75bb35ff95cb72e32ffd093929b008413de5;
  bytes32 internal constant _NFT_POOL_SLOT = 0x828d9a241b00468f203e6001f37c2f3f9b054802b5bfa652f8dee2a0f2d586d9;
  bytes32 internal constant _NITRO_POOL_SLOT = 0x1ee567d62ee6cf3d5c44deeb8b6f34774a4a2d99f55ae3d5f1ca16bee430b005;
  bytes32 internal constant _XGRAIL_VAULT_SLOT = 0xd445aff5601e22e4f2e49f44eb54e33aa29670745d5241914b5369f65f9d43d0;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POS_ID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.posId")) - 1));
    assert(_NFT_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nftPool")) - 1));
    assert(_NITRO_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nitroPool")) - 1));
    assert(_XGRAIL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.xGrailVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _grail,
    address _nftPool,
    address _nitroPool,
    address _xGrailVault,
    address _potPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _nitroPool,
      _grail,
      harvestMSIG
    );

    address _lpt;
    (_lpt,,,,,,,) = INFTPool(_nftPool).getPoolInfo();
    require(_lpt == underlying(), "NFTPool Info does not match underlying");
    address checkNftPool = INitroPool(_nitroPool).nftPool();
    require(checkNftPool == _nftPool, "NitroPool does not match NFTPool");
    _setNFTPool(_nftPool);
    _setNitroPool(_nitroPool);
    setAddress(_XGRAIL_VAULT_SLOT, _xGrailVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
    (bal,,,,) = INitroPool(nitroPool()).userInfo(address(this));
  }

  function exitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).withdraw(_posId);
      INFTPool(nftPool()).withdrawFromPosition(_posId, stakedBalance);
    }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
      uint256 _posId = posId();
      address _nitroPool = nitroPool();
      address _nftPool = nftPool();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).withdrawFromPosition(_posId, amount);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).emergencyWithdraw(_posId);
      INFTPool(nftPool()).emergencyWithdraw(_posId);
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _nftPool = nftPool();
    address _nitroPool = nitroPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_nftPool, 0);
    IERC20(_underlying).safeApprove(_nftPool, entireBalance);
    if (rewardPoolBalance() > 0) {  //We already have a position. Withdraw from staking, add to position, stake again.
      uint256 _posId = posId();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).addToPosition(_posId, entireBalance);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    } else {                        //We do not yet have a position. Create a position and store the position ID. Then stake.
      INFTPool(_nftPool).createPosition(entireBalance, 0);
      uint256 newPosId = INFTPool(_nftPool).tokenOfOwnerByIndex(address(this), 0);
      _setPosId(newPosId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, posId());
    }
  }

  function updateNitroPool(address newNitroPool) external onlyGovernance {
    address _nitroPool = nitroPool();
    uint256 _posId = posId();
    if (_posId > 0) {
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
    }
    _setNitroPool(newNitroPool);
    INFTPool(nftPool()).safeTransferFrom(address(this), nitroPool(), _posId);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _claimRewards() internal {
    uint256 _posId = posId();
    if (_posId > 0){
      address _nitroPool = nitroPool();
      address _nftPool = nftPool();
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).harvestPosition(_posId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    }
  }

  function _liquidateRewards(uint256 _xGrailAmount) internal {
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance.add(_xGrailAmount));
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
    IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);

    address _underlying = underlying();

    address token0 = ICamelotPair(_underlying).token0();
    address token1 = ICamelotPair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    uint256 token0Amount;
    if (_rewardToken != token0) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token0, toToken0, 1, address(this));
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (_rewardToken != token1) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token1, toToken1, 1, address(this));
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    IERC20(token0).safeApprove(camelotRouter, 0);
    IERC20(token0).safeApprove(camelotRouter, token0Amount);

    IERC20(token1).safeApprove(camelotRouter, 0);
    IERC20(token1).safeApprove(camelotRouter, token1Amount);

    ICamelotRouter(camelotRouter).addLiquidity(
      token0,
      token1,
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );

    _handleXGrail();
  }

  function _handleXGrail() internal {
    uint256 balance = IERC20(xGrail).balanceOf(address(this));
    if (balance == 0) { return; }
    address _xGrailVault = xGrailVault();
    address _potPool = potPool();

    IERC20(xGrail).safeApprove(_xGrailVault, 0);
    IERC20(xGrail).safeApprove(_xGrailVault, balance);
    IVault(_xGrailVault).deposit(balance);

    uint256 vaultBalance = IERC20(_xGrailVault).balanceOf(address(this));
    IERC20(_xGrailVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_xGrailVault, vaultBalance);

    uint256 iFarmBalance = IERC20(iFarm).balanceOf(address(this));
    IERC20(iFarm).safeTransfer(_potPool, iFarmBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(iFarm, iFarmBalance);
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimRewards();
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    investAllUnderlying();
  }

  function _setPosId(uint256 _value) internal {
    setUint256(_POS_ID_SLOT, _value);
  }

  function posId() public view returns (uint256) {
    return getUint256(_POS_ID_SLOT);
  }

  function _setNFTPool(address _address) internal {
    setAddress(_NFT_POOL_SLOT, _address);
  }

  function nftPool() public view returns (address) {
    return getAddress(_NFT_POOL_SLOT);
  }

  function _setNitroPool(address _address) internal {
    setAddress(_NITRO_POOL_SLOT, _address);
  }

  function nitroPool() public view returns (address) {
    return getAddress(_NITRO_POOL_SLOT);
  }

  function setXGrailVault(address _value) public onlyGovernance {
    require(xGrailVault() == address(0), "Hodl vault already set");
    setAddress(_XGRAIL_VAULT_SLOT, _value);
  }

  function xGrailVault() public view returns (address) {
    return getAddress(_XGRAIL_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the WETH unwrapping

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function onNFTHarvest(address /*operator*/, address /*to*/, uint256 /*tokenId*/, uint256 /*grailAmount*/, uint256 /*xGrailAmount*/) external pure returns (bool) {return true;}
  function onNFTAddToPosition(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
  function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroIFarmStrategy.sol";

contract CamelotNitroIFarmStrategyMainnet_iFARM_ETH is CamelotNitroIFarmStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xD2A7084369cC93672b2CA868757a9f327e3677a4);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x5DbFE78Bf6d6FDE1db1854c9A30DFb2d565e6152);
    address nitroPool = address(0x1330Ef50fb3aF24eB0c748BEbE38d059639d4158);
    CamelotNitroIFarmStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/INFTPool.sol";
import "../../base/interface/camelot/INitroPool.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";
import "../../base/interface/IUniversalLiquidator.sol";

contract CamelotNitroStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
  address public constant xGrail = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POS_ID_SLOT = 0x025da88341279feed86c02593d3d75bb35ff95cb72e32ffd093929b008413de5;
  bytes32 internal constant _NFT_POOL_SLOT = 0x828d9a241b00468f203e6001f37c2f3f9b054802b5bfa652f8dee2a0f2d586d9;
  bytes32 internal constant _NITRO_POOL_SLOT = 0x1ee567d62ee6cf3d5c44deeb8b6f34774a4a2d99f55ae3d5f1ca16bee430b005;
  bytes32 internal constant _XGRAIL_VAULT_SLOT = 0xd445aff5601e22e4f2e49f44eb54e33aa29670745d5241914b5369f65f9d43d0;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POS_ID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.posId")) - 1));
    assert(_NFT_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nftPool")) - 1));
    assert(_NITRO_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nitroPool")) - 1));
    assert(_XGRAIL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.xGrailVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _grail,
    address _nftPool,
    address _nitroPool,
    address _xGrailVault,
    address _potPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _nitroPool,
      _grail,
      harvestMSIG
    );

    address _lpt;
    (_lpt,,,,,,,) = INFTPool(_nftPool).getPoolInfo();
    require(_lpt == underlying(), "NFTPool Info does not match underlying");
    address checkNftPool = INitroPool(_nitroPool).nftPool();
    require(checkNftPool == _nftPool, "NitroPool does not match NFTPool");
    _setNFTPool(_nftPool);
    _setNitroPool(_nitroPool);
    setAddress(_XGRAIL_VAULT_SLOT, _xGrailVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
    (bal,,,,) = INitroPool(nitroPool()).userInfo(address(this));
  }

  function exitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).withdraw(_posId);
      INFTPool(nftPool()).withdrawFromPosition(_posId, stakedBalance);
    }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
      uint256 _posId = posId();
      address _nitroPool = nitroPool();
      address _nftPool = nftPool();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).withdrawFromPosition(_posId, amount);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).emergencyWithdraw(_posId);
      INFTPool(nftPool()).emergencyWithdraw(_posId);
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _nftPool = nftPool();
    address _nitroPool = nitroPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_nftPool, 0);
    IERC20(_underlying).safeApprove(_nftPool, entireBalance);
    if (rewardPoolBalance() > 0) {  //We already have a position. Withdraw from staking, add to position, stake again.
      uint256 _posId = posId();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).addToPosition(_posId, entireBalance);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    } else {                        //We do not yet have a position. Create a position and store the position ID. Then stake.
      INFTPool(_nftPool).createPosition(entireBalance, 0);
      uint256 newPosId = INFTPool(_nftPool).tokenOfOwnerByIndex(address(this), 0);
      _setPosId(newPosId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, posId());
    }
  }

  function updateNitroPool(address newNitroPool) external onlyGovernance {
    address _nitroPool = nitroPool();
    uint256 _posId = posId();
    if (_posId > 0) {
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
    }
    _setNitroPool(newNitroPool);
    INFTPool(nftPool()).safeTransferFrom(address(this), nitroPool(), _posId);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _claimRewards() internal {
    uint256 _posId = posId();
    if (_posId > 0){
      address _nitroPool = nitroPool();
      address _nftPool = nftPool();
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).harvestPosition(_posId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    }
  }

  function _liquidateRewards(uint256 _xGrailAmount) internal {
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    uint256 notifyBalance;
    if (_xGrailAmount > rewardBalance.mul(9)) {
      notifyBalance = rewardBalance.mul(10);
    } else {
      notifyBalance = rewardBalance.add(_xGrailAmount);
    }
    _notifyProfitInRewardToken(_rewardToken, notifyBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance < 1e6) {
      _handleXGrail();
      return;
    }

    IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
    IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);

    address _underlying = underlying();

    address token0 = ICamelotPair(_underlying).token0();
    address token1 = ICamelotPair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    uint256 token0Amount;
    if (_rewardToken != token0) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token0, toToken0, 1, address(this));
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (_rewardToken != token1) {
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, token1, toToken1, 1, address(this));
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    IERC20(token0).safeApprove(camelotRouter, 0);
    IERC20(token0).safeApprove(camelotRouter, token0Amount);

    IERC20(token1).safeApprove(camelotRouter, 0);
    IERC20(token1).safeApprove(camelotRouter, token1Amount);

    ICamelotRouter(camelotRouter).addLiquidity(
      token0,
      token1,
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );

    _handleXGrail();
  }

  function _handleXGrail() internal {
    uint256 balance = IERC20(xGrail).balanceOf(address(this));
    if (balance == 0) { return; }
    address _xGrailVault = xGrailVault();
    address _potPool = potPool();

    IERC20(xGrail).safeApprove(_xGrailVault, 0);
    IERC20(xGrail).safeApprove(_xGrailVault, balance);
    IVault(_xGrailVault).deposit(balance);

    uint256 vaultBalance = IERC20(_xGrailVault).balanceOf(address(this));
    IERC20(_xGrailVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_xGrailVault, vaultBalance);
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimRewards();
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    investAllUnderlying();
  }

  function _setPosId(uint256 _value) internal {
    setUint256(_POS_ID_SLOT, _value);
  }

  function posId() public view returns (uint256) {
    return getUint256(_POS_ID_SLOT);
  }

  function _setNFTPool(address _address) internal {
    setAddress(_NFT_POOL_SLOT, _address);
  }

  function nftPool() public view returns (address) {
    return getAddress(_NFT_POOL_SLOT);
  }

  function _setNitroPool(address _address) internal {
    setAddress(_NITRO_POOL_SLOT, _address);
  }

  function nitroPool() public view returns (address) {
    return getAddress(_NITRO_POOL_SLOT);
  }

  function setXGrailVault(address _value) public onlyGovernance {
    require(xGrailVault() == address(0), "Hodl vault already set");
    setAddress(_XGRAIL_VAULT_SLOT, _value);
  }

  function xGrailVault() public view returns (address) {
    return getAddress(_XGRAIL_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the WETH unwrapping

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function onNFTHarvest(address /*operator*/, address /*to*/, uint256 /*tokenId*/, uint256 /*grailAmount*/, uint256 /*xGrailAmount*/) external pure returns (bool) {return true;}
  function onNFTAddToPosition(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
  function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_EQB_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x69B545997BD6aBC81CaE39Fe9bdC94d2242a0f92);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address eqb = address(0xBfbCFe8873fE28Dfa25f1099282b088D52bbAD9C);
    address nftPool = address(0x76075F03e0Ae34bF0B63bcFb731F9DB5F826dcAe);
    address nitroPool = address(0xE13B64C33eCB0501C21e0423fcd2efAF5e0a2592);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, eqb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_GENE_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa0c79678bCFbEA0a358D5FeA563100893C37a848);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address gnome = address(0x7698Ac5D15bb3Ba7185adCBff32A80ebD9d0709B);
    address nftPool = address(0xc7044561328BE256a37b2Aaf44b42D0E4c86eFED);
    address nitroPool = address(0x1ceEA34c280346DC539281EAb8b61EBe6CF7e496);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail, gnome];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_GMX_USDC is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x913398d79438e8D709211cFC3DC8566F6C67e1A8);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x978E469E8242cd18af5926A1b60B8D93A550a391);
    address nitroPool = address(0xf54E40b1dB413476324636292cD6c547E4012204);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_GNOME_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x60F7116d7c451ac5a5159F60Fc5fC36336b742c4);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address gene = address(0x59A729658e9245B0cF1f8Cb9fb37945D2B06ea27);
    address nftPool = address(0x1e527Dc9B55DD46DE058239ff33907a5b6E396D1);
    address nitroPool = address(0x7F2a4E30bC0c9eB68CC3644516bA2c4b4b481F1c);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail, gene];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_JONES_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x460c2c075340EbC19Cf4af68E5d83C194E7D21D0);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0xE20cE7d800934eC568Fe94E135E84b1e919AbB2a);
    address nitroPool = address(0xda2257dd3501Cd96164eEf0C744E2ee30E646A40);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_LODE_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x49bB23DfAe944059C2403BCc255c5a9c0F851a8D);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address nftPool = address(0x48D45129b58f0d464Bdd5023E013FFFc40512c30);
    address nitroPool = address(0x9c33453927D6698A141BdE5DDbc2fBa88BaA2d51);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, lode];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_RELAY_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xBbcF0B7F070B170909C9ff430878e92ceAd990F3);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address relay = address(0x1426CF37CAA89628C4DA2864e40cF75E6d66Ac6b);
    address nftPool = address(0x30cbcBbd793501690d9Ca6f78fC798Ce987Af7d9);
    address nitroPool = address(0xe9b80ffd7Bd59189487Ab15866F88eBc8E7937A1);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, relay];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_SILO_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE01E0B5C707EdEE3FFC10b464115cC20073817A2);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address silo = address(0x0341C0C0ec423328621788d4854119B97f44E391);
    address nftPool = address(0x48776552223FFca23125e8E9509E949732FAee72);
    address nitroPool = address(0x4C5d499252c932822df31C921747F89F6a7f92ED);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, silo];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_SPOOL_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x835785C823e3c19c37cb6e2C616C278738947978);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address spool = address(0xECA14F81085e5B8d1c9D32Dcb596681574723561);
    address nftPool = address(0x7e25ae5cd6bC3C6c1Df41A0CfeE123ad6C27D714);
    address nitroPool = address(0x7eceE3f0dEF3337360aF0d42798C2E1DAC5cEb87);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, spool];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_THALES_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8971dFb268B961a9270632f28B24F2f637c94244);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address thales = address(0xE85B662Fe97e8562f4099d8A1d5A92D4B453bF30);
    address nftPool = address(0xB5108062de111F61E0dD585f4225ae18d1BB21D9);
    address nitroPool = address(0x41b52A004EeDacf5CAfb8cf76b8360b679372070);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, thales];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_UMAMI_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xa1e48225215d9e656F4f9d779fc32817C50de0E5);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x5CC05f1D98FA65E3de125DA9006579e991905ab2);
    address nitroPool = address(0x36Cf5b4aA422e3EA2581Cd7C0E21BdFff09F9c5B);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_UWU_USDC is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6B8b78554Db2f017CCA749dad38E445cd8A3b5B4);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address uwu = address(0x05d35769a222AfFd6185e20F3f3676Abde56C25F);
    address nftPool = address(0x4B51d227db5d0508320479532618383dA81A9539);
    address nitroPool = address(0x0fB1ADe48A1f567Ba31D3d3CAda701E0705D5077);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, usdc, uwu];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_VELA_ETH is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4c0A68dd92449Fc06c1A651E9eb1dFfB61D64e18);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address vela = address(0x088cd8f5eF3652623c22D48b1605DCfE860Cd704);
    address nftPool = address(0xF319A470e6d3b720824f520A8d72E8aD06B4317B);
    address nitroPool = address(0xCAd702CC3a173cbb5Dd900024e33FB7E0ab58c8E);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0)
    );
    rewardTokens = [grail, vela];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotNitroStrategy.sol";

contract CamelotNitroStrategyMainnet_WINR_USDC is CamelotNitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xAa6d06CeB39132b720b54259B70F41f9C975782A);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address winr = address(0xD77B108d4f6cefaa0Cae9506A934e825BEccA46E);
    address nftPool = address(0xEa33C17D890f33bc2570938E4C318faa2DBaba08);
    address nitroPool = address(0x335c8Fe952924794A7a0aB59971FAcC4835B4cE0);
    CamelotNitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //fxGRAIL
      address(0)
    );
    rewardTokens = [grail, winr];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/gamma/IHypervisor.sol";
import "../../base/interface/gamma/IUniProxy.sol";
import "../../base/interface/gamma/IClearing.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/INFTPool.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";

contract CamelotV3NFTStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant xGrail = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POS_ID_SLOT = 0x025da88341279feed86c02593d3d75bb35ff95cb72e32ffd093929b008413de5;
  bytes32 internal constant _XGRAIL_VAULT_SLOT = 0xd445aff5601e22e4f2e49f44eb54e33aa29670745d5241914b5369f65f9d43d0;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;
  bytes32 internal constant _UNIPROXY_SLOT = 0x09ff9720152edb4fad4ed05a0b77258f0fce17715f9397342eb08c8d7f965234;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POS_ID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.posId")) - 1));
    assert(_XGRAIL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.xGrailVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
    assert(_UNIPROXY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.uniProxy")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _grail,
    address _nftPool,
    address _xGrailVault,
    address _potPool,
    address _uniProxy
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _nftPool,
      _grail,
      harvestMSIG
    );

    (address _lpt,,,,,,,) = INFTPool(_nftPool).getPoolInfo();
    require(_lpt == underlying(), "NFTPool Info does not match underlying");
    setAddress(_XGRAIL_VAULT_SLOT, _xGrailVault);
    setAddress(_POTPOOL_SLOT, _potPool);
    setAddress(_UNIPROXY_SLOT, _uniProxy);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
    if (posId() > 0) {
      (bal,,,,,,,) = INFTPool(rewardPool()).getStakingPosition(posId());
    } else {
      bal = 0;
    }
  }

  function exitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      INFTPool(rewardPool()).withdrawFromPosition(posId(), stakedBalance);
    }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
      INFTPool(rewardPool()).withdrawFromPosition(posId(), amount);
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      INFTPool(rewardPool()).emergencyWithdraw(posId());
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _rewardPool = rewardPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_rewardPool, 0);
    IERC20(_underlying).safeApprove(_rewardPool, entireBalance);
    if (rewardPoolBalance() > 0) {  //We already have a position. Withdraw from staking, add to position, stake again.
      INFTPool(_rewardPool).addToPosition(posId(), entireBalance);
    } else {                        //We do not yet have a position. Create a position and store the position ID. Then stake.
      INFTPool(_rewardPool).createPosition(entireBalance, 0);
      uint256 newPosId = INFTPool(_rewardPool).tokenOfOwnerByIndex(address(this), 0);
      _setPosId(newPosId);
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _claimRewards() internal {
    uint256 _posId = posId();
    if (_posId > 0){
      INFTPool(rewardPool()).harvestPosition(_posId);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateRewards(uint256 _xGrailAmount) internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    uint256 notifyBalance;
    if (_xGrailAmount > rewardBalance.mul(9)) {
      notifyBalance = rewardBalance.mul(10);
    } else {
      notifyBalance = rewardBalance.add(_xGrailAmount);
    }
    _notifyProfitInRewardToken(_rewardToken, notifyBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance < 1e6) {
      _handleXGrail();
      return;
    }

    _depositToGamma();
    _handleXGrail();
  }

  function _handleXGrail() internal {
    uint256 balance = IERC20(xGrail).balanceOf(address(this));
    if (balance == 0) { return; }
    address _xGrailVault = xGrailVault();
    address _potPool = potPool();

    IERC20(xGrail).safeApprove(_xGrailVault, 0);
    IERC20(xGrail).safeApprove(_xGrailVault, balance);
    IVault(_xGrailVault).deposit(balance);

    uint256 vaultBalance = IERC20(_xGrailVault).balanceOf(address(this));
    IERC20(_xGrailVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_xGrailVault, vaultBalance);
  }

  function _depositToGamma() internal {
    address _underlying = underlying();
    address _clearing = IUniProxy(uniProxy()).clearance();
    address _token0 = IHypervisor(_underlying).token0();
    address _token1 = IHypervisor(_underlying).token1();
    (uint256 toToken0, uint256 toToken1) = _calculateToTokenAmounts();
    (uint256 amount0, uint256 amount1) = _swapToTokens(_token0, _token1, toToken0, toToken1);
    (uint256 min1, uint256 max1) = IClearing(_clearing).getDepositAmount(_underlying, _token0, amount0);
    if (amount1 < min1) {
      (,uint256 max0) = IClearing(_clearing).getDepositAmount(_underlying, _token1, amount1);
      if (amount0 > max0) {
        amount0 = max0;
      }
    } else if (amount1 > max1) {
      amount1 = max1;
    }
    uint256[4] memory minIn = [uint(0), uint(0), uint(0), uint(0)];

    IERC20(_token0).safeApprove(_underlying, 0);
    IERC20(_token0).safeApprove(_underlying, amount0);
    IERC20(_token1).safeApprove(_underlying, 0);
    IERC20(_token1).safeApprove(_underlying, amount1);
    IUniProxy(uniProxy()).deposit(amount0, amount1, address(this), _underlying, minIn);
  }

  function _calculateToTokenAmounts() internal view returns(uint256, uint256){
    address pool = underlying();
    (uint256 poolBalance0, uint256 poolBalance1) = IHypervisor(pool).getTotalAmounts();
    address clearing = IUniProxy(uniProxy()).clearance();
    uint256 sqrtPrice0In1 = uint256(IClearing(clearing).getSqrtTwapX96(pool, 1));
    uint256 price0In1 = sqrtPrice0In1.mul(sqrtPrice0In1).div(uint(2**(96 * 2)).div(1e18));
    uint256 totalPoolBalanceIn1 = poolBalance0.mul(price0In1).div(1e18).add(poolBalance1);
    uint256 poolWeight0 = poolBalance0.mul(price0In1).div(totalPoolBalanceIn1);

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    uint256 toToken0 = rewardBalance.mul(poolWeight0).div(1e18);
    uint256 toToken1 = rewardBalance.sub(toToken0);
    return (toToken0, toToken1);
  }

  function _swapToTokens(
    address tokenOut0,
    address tokenOut1,
    uint256 toToken0,
    uint256 toToken1
  ) internal returns(uint256, uint256){
    address tokenIn = rewardToken();
    address _universalLiquidator = universalLiquidator();
    uint256 token0Amount;
    if (tokenIn != tokenOut0){
      IERC20(tokenIn).safeApprove(_universalLiquidator, 0);
      IERC20(tokenIn).safeApprove(_universalLiquidator, toToken0);
      IUniversalLiquidator(_universalLiquidator).swap(tokenIn, tokenOut0, toToken0, 1, address(this));
      token0Amount = IERC20(tokenOut0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (tokenIn != tokenOut1){
      IERC20(tokenIn).safeApprove(_universalLiquidator, 0);
      IERC20(tokenIn).safeApprove(_universalLiquidator, toToken1);
      IUniversalLiquidator(_universalLiquidator).swap(tokenIn, tokenOut1, toToken1, 1, address(this));
      token1Amount = IERC20(tokenOut1).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token1Amount = toToken1;
    }
    return (token0Amount, token1Amount);
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimRewards();
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  function _setPosId(uint256 _value) internal {
    setUint256(_POS_ID_SLOT, _value);
  }

  function posId() public view returns (uint256) {
    return getUint256(_POS_ID_SLOT);
  }

  function setXGrailVault(address _value) public onlyGovernance {
    require(xGrailVault() == address(0), "Hodl vault already set");
    setAddress(_XGRAIL_VAULT_SLOT, _value);
  }

  function xGrailVault() public view returns (address) {
    return getAddress(_XGRAIL_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function _setUniProxy(address _value) public onlyGovernance {
    setAddress(_UNIPROXY_SLOT, _value);
  }

  function uniProxy() public view returns (address) {
    return getAddress(_UNIPROXY_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function onNFTHarvest(address /*operator*/, address /*to*/, uint256 /*tokenId*/, uint256 /*grailAmount*/, uint256 /*xGrailAmount*/) external pure returns (bool) {return true;}
  function onNFTAddToPosition(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
  function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NFTStrategy.sol";

contract CamelotV3NFTStrategyMainnet_ARB_USDC is CamelotV3NFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x29237292F15BC3615BFCc0D958C265Aa64527FB2);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x14AD01d5f496e9C40358629f6a95a7C3B5c4b767);
    CamelotV3NFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0),
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NFTStrategy.sol";

contract CamelotV3NFTStrategyMainnet_ETH_USDC is CamelotV3NFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0x3b6486154b9dAe942C393b1cB3d11E3395B02Df8);
    CamelotV3NFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0),
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NFTStrategy.sol";

contract CamelotV3NFTStrategyMainnet_ETH_USDT is CamelotV3NFTStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9330e26b5Fc0b7c417C6bD901528d5c65BE5cdf2);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address nftPool = address(0xF42884071fFe17Bdd7d1710C31191023419e0CA7);
    CamelotV3NFTStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f),
      address(0),
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail];
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/gamma/IHypervisor.sol";
import "../../base/interface/gamma/IUniProxy.sol";
import "../../base/interface/gamma/IClearing.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/INFTPool.sol";
import "../../base/interface/camelot/INitroPool.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";

contract CamelotV3NitroStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant xGrail = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POS_ID_SLOT = 0x025da88341279feed86c02593d3d75bb35ff95cb72e32ffd093929b008413de5;
  bytes32 internal constant _XGRAIL_VAULT_SLOT = 0xd445aff5601e22e4f2e49f44eb54e33aa29670745d5241914b5369f65f9d43d0;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;
  bytes32 internal constant _UNIPROXY_SLOT = 0x09ff9720152edb4fad4ed05a0b77258f0fce17715f9397342eb08c8d7f965234;
  bytes32 internal constant _NFT_POOL_SLOT = 0x828d9a241b00468f203e6001f37c2f3f9b054802b5bfa652f8dee2a0f2d586d9;
  bytes32 internal constant _NITRO_POOL_SLOT = 0x1ee567d62ee6cf3d5c44deeb8b6f34774a4a2d99f55ae3d5f1ca16bee430b005;


  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POS_ID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.posId")) - 1));
    assert(_XGRAIL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.xGrailVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
    assert(_UNIPROXY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.uniProxy")) - 1));
    assert(_NFT_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nftPool")) - 1));
    assert(_NITRO_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nitroPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _grail,
    address _nftPool,
    address _nitroPool,
    address _xGrailVault,
    address _potPool,
    address _uniProxy
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _nitroPool,
      _grail,
      harvestMSIG
    );

    address _lpt;
    (_lpt,,,,,,,) = INFTPool(_nftPool).getPoolInfo();
    require(_lpt == underlying(), "NFTPool Info does not match underlying");
    address checkNftPool = INitroPool(_nitroPool).nftPool();
    require(checkNftPool == _nftPool, "NitroPool does not match NFTPool");
    _setNFTPool(_nftPool);
    _setNitroPool(_nitroPool);
    setAddress(_XGRAIL_VAULT_SLOT, _xGrailVault);
    setAddress(_POTPOOL_SLOT, _potPool);
    setAddress(_UNIPROXY_SLOT, _uniProxy);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
    if (posId() > 0) {
      (bal,,,,) = INitroPool(nitroPool()).userInfo(address(this));
    } else {
      bal = 0;
    }
  }

  function exitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).withdraw(_posId);
      INFTPool(nftPool()).withdrawFromPosition(_posId, stakedBalance);
    }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
    uint256 _posId = posId();
    address _nitroPool = nitroPool();
    address _nftPool = nftPool();
    INitroPool(_nitroPool).withdraw(_posId);
    INFTPool(_nftPool).withdrawFromPosition(_posId, amount);
    INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
      uint256 _posId = posId();
      INitroPool(nitroPool()).emergencyWithdraw(_posId);
      INFTPool(nftPool()).emergencyWithdraw(_posId);
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    address _nftPool = nftPool();
    address _nitroPool = nitroPool();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(_nftPool, 0);
    IERC20(_underlying).safeApprove(_nftPool, entireBalance);
    if (rewardPoolBalance() > 0) {  //We already have a position. Withdraw from staking, add to position, stake again.
      uint256 _posId = posId();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).addToPosition(_posId, entireBalance);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    } else {                        //We do not yet have a position. Create a position and store the position ID. Then stake.
      INFTPool(_nftPool).createPosition(entireBalance, 0);
      uint256 newPosId = INFTPool(_nftPool).tokenOfOwnerByIndex(address(this), 0);
      _setPosId(newPosId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, posId());
    }
  }

  function updateNitroPool(address newNitroPool) external onlyGovernance {
    address _nitroPool = nitroPool();
    uint256 _posId = posId();
    if (_posId > 0) {
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
    }
    _setNitroPool(newNitroPool);
    INFTPool(nftPool()).safeTransferFrom(address(this), nitroPool(), _posId);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _claimRewards() internal {
    uint256 _posId = posId();
    if (_posId > 0){
      address _nitroPool = nitroPool();
      address _nftPool = nftPool();
      INitroPool(_nitroPool).harvest();
      INitroPool(_nitroPool).withdraw(_posId);
      INFTPool(_nftPool).harvestPosition(_posId);
      INFTPool(_nftPool).safeTransferFrom(address(this), _nitroPool, _posId);
    }
  }

  // We assume that all the tradings can be done on Uniswap
  function _liquidateRewards(uint256 _xGrailAmount) internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    uint256 notifyBalance;
    if (_xGrailAmount > rewardBalance.mul(9)) {
      notifyBalance = rewardBalance.mul(10);
    } else {
      notifyBalance = rewardBalance.add(_xGrailAmount);
    }
    _notifyProfitInRewardToken(_rewardToken, notifyBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance < 1e6) {
      _handleXGrail();
      return;
    }

    _depositToGamma();
    _handleXGrail();
  }

  function _handleXGrail() internal {
    uint256 balance = IERC20(xGrail).balanceOf(address(this));
    if (balance == 0) { return; }
    address _xGrailVault = xGrailVault();
    address _potPool = potPool();

    IERC20(xGrail).safeApprove(_xGrailVault, 0);
    IERC20(xGrail).safeApprove(_xGrailVault, balance);
    IVault(_xGrailVault).deposit(balance);

    uint256 vaultBalance = IERC20(_xGrailVault).balanceOf(address(this));
    IERC20(_xGrailVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_xGrailVault, vaultBalance);
  }

  function _depositToGamma() internal {
    address _underlying = underlying();
    address _clearing = IUniProxy(uniProxy()).clearance();
    address _token0 = IHypervisor(_underlying).token0();
    address _token1 = IHypervisor(_underlying).token1();
    (uint256 toToken0, uint256 toToken1) = _calculateToTokenAmounts();
    (uint256 amount0, uint256 amount1) = _swapToTokens(_token0, _token1, toToken0, toToken1);
    (uint256 min1, uint256 max1) = IClearing(_clearing).getDepositAmount(_underlying, _token0, amount0);
    if (amount1 < min1) {
      (,uint256 max0) = IClearing(_clearing).getDepositAmount(_underlying, _token1, amount1);
      if (amount0 > max0) {
        amount0 = max0;
      }
    } else if (amount1 > max1) {
      amount1 = max1;
    }
    uint256[4] memory minIn = [uint(0), uint(0), uint(0), uint(0)];

    IERC20(_token0).safeApprove(_underlying, 0);
    IERC20(_token0).safeApprove(_underlying, amount0);
    IERC20(_token1).safeApprove(_underlying, 0);
    IERC20(_token1).safeApprove(_underlying, amount1);
    IUniProxy(uniProxy()).deposit(amount0, amount1, address(this), _underlying, minIn);
  }

  function _calculateToTokenAmounts() internal view returns(uint256, uint256){
    address pool = underlying();
    (uint256 poolBalance0, uint256 poolBalance1) = IHypervisor(pool).getTotalAmounts();
    address clearing = IUniProxy(uniProxy()).clearance();
    uint256 sqrtPrice0In1 = uint256(IClearing(clearing).getSqrtTwapX96(pool, 1));
    uint256 price0In1 = sqrtPrice0In1.mul(sqrtPrice0In1).div(uint(2**(96 * 2)).div(1e18));
    uint256 totalPoolBalanceIn1 = poolBalance0.mul(price0In1).div(1e18).add(poolBalance1);
    uint256 poolWeight0 = poolBalance0.mul(price0In1).div(totalPoolBalanceIn1);

    uint256 rewardBalance = IERC20(rewardToken()).balanceOf(address(this));
    uint256 toToken0 = rewardBalance.mul(poolWeight0).div(1e18);
    uint256 toToken1 = rewardBalance.sub(toToken0);
    return (toToken0, toToken1);
  }

  function _swapToTokens(
    address tokenOut0,
    address tokenOut1,
    uint256 toToken0,
    uint256 toToken1
  ) internal returns(uint256, uint256){
    address tokenIn = rewardToken();
    address _universalLiquidator = universalLiquidator();
    uint256 token0Amount;
    if (tokenIn != tokenOut0){
      IERC20(tokenIn).safeApprove(_universalLiquidator, 0);
      IERC20(tokenIn).safeApprove(_universalLiquidator, toToken0);
      IUniversalLiquidator(_universalLiquidator).swap(tokenIn, tokenOut0, toToken0, 1, address(this));
      token0Amount = IERC20(tokenOut0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (tokenIn != tokenOut1){
      IERC20(tokenIn).safeApprove(_universalLiquidator, 0);
      IERC20(tokenIn).safeApprove(_universalLiquidator, toToken1);
      IUniversalLiquidator(_universalLiquidator).swap(tokenIn, tokenOut1, toToken1, 1, address(this));
      token1Amount = IERC20(tokenOut1).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is the reward token itself
      token1Amount = toToken1;
    }
    return (token0Amount, token1Amount);
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimRewards();
    uint256 xGrailReward = IERC20(xGrail).balanceOf(address(this));
    _liquidateRewards(xGrailReward);
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  function _setPosId(uint256 _value) internal {
    setUint256(_POS_ID_SLOT, _value);
  }

  function posId() public view returns (uint256) {
    return getUint256(_POS_ID_SLOT);
  }

  function setXGrailVault(address _value) public onlyGovernance {
    require(xGrailVault() == address(0), "Hodl vault already set");
    setAddress(_XGRAIL_VAULT_SLOT, _value);
  }

  function xGrailVault() public view returns (address) {
    return getAddress(_XGRAIL_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function _setUniProxy(address _value) public onlyGovernance {
    setAddress(_UNIPROXY_SLOT, _value);
  }

  function uniProxy() public view returns (address) {
    return getAddress(_UNIPROXY_SLOT);
  }

  function _setNFTPool(address _address) internal {
    setAddress(_NFT_POOL_SLOT, _address);
  }

  function nftPool() public view returns (address) {
    return getAddress(_NFT_POOL_SLOT);
  }

  function _setNitroPool(address _address) internal {
    setAddress(_NITRO_POOL_SLOT, _address);
  }

  function nitroPool() public view returns (address) {
    return getAddress(_NITRO_POOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function onNFTHarvest(address /*operator*/, address /*to*/, uint256 /*tokenId*/, uint256 /*grailAmount*/, uint256 /*xGrailAmount*/) external pure returns (bool) {return true;}
  function onNFTAddToPosition(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
  function onNFTWithdraw(address /*operator*/, uint256 /*tokenId*/, uint256 /*lpAmount*/) external pure returns (bool) {return true;}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_ARB_ETH is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x863cb3E55526Fa2F7e6b04ecf21Ea39143AC8056);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xbFf9F4591b423ce63e9Ef803533C70ae8a03bEed);
    address nitroPool = address(0xe105b532cb42bf065D152643B29feDA85625Dce9);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_ARB_USDC is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x29237292F15BC3615BFCc0D958C265Aa64527FB2);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0x14AD01d5f496e9C40358629f6a95a7C3B5c4b767);
    address nitroPool = address(0x6aCdfD8Bd4f5AC6F5E0cA54024663C251e9Cf0f4);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0x39bC1a41e9b77De48bb1D6cBDb5E36635c4c28b9), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_DAI_USDC is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x2766Ba1B6772d23E1F58260a1dF57bFFB4661953);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0x31089a2df37AC97A405377CBA2Bb4Fc993984B1d);
    address nitroPool = address(0x9320C0e76D56F9aA0dB60016A2430d38a0D42A26);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_ETH_USDC is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0x3b6486154b9dAe942C393b1cB3d11E3395B02Df8);
    address nitroPool = address(0x84EDB15BcBf6818879C6FDf26A69700D43100A74);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0x5f0AB004Ab2a3c35461e0E5Ce89839DA22B2E598), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_ETH_USDT is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9330e26b5Fc0b7c417C6bD901528d5c65BE5cdf2);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xF42884071fFe17Bdd7d1710C31191023419e0CA7);
    address nitroPool = address(0xe364CF2dd75192D2b04059D6c0aE559699b1E31A);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0x7e4d7C473d090ff0C70ee41A50116e0b7463EB46), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_GMX_ETH is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9bdb8335619bA4E20Bea1321f8E32f45fD6e6e22);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0x4242fbeEcF6b1Db01a50B8878f85c31E5e53a5c6);
    address nitroPool = address(0x2Ed02f03a7EC25Acd2BcE9C32d359A8fE02e798B);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_GRAIL_ETH is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x97D81162B96D57476CcF170595a39c1DC76676c9);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0x06Bd22D16B6fB79380fF3DD49F0801a62eDD943b);
    address nitroPool = address(0xd599c5B68D89213d2eEC9dDdfc92fFc9Ca1795ca);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_LINK_ETH is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xF3557102C0cCBE07EE237B6eE70984f313886432);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xf49926092302B0c18385a7069f98456dF0e5C8Fe);
    address nitroPool = address(0xE651C9562F471bE685c1faE9EFaa0b5932974172);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_LUSD_USDC is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x439e2D51BA26Fa062a1E4F0eDAA68F3B830Ca6da);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xaF3bFe781ffEe9f77867C556ab6A604E26FA678A);
    address nitroPool = address(0xDcF6fD8BB2Fbd5D9241a1eF961a36f55DB1BBE47);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_USDCe_USDT is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x61A7b3dae70D943C6f2eA9ba4FfD2fEcc6AF15E4);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xD07F046a75Eac939488e40f52196dF43eDe28e00);
    address nitroPool = address(0x3c81626E537E41f8b3C86F3da07F12A44DEe4a0e);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CamelotV3NitroStrategy.sol";

contract CamelotV3NitroStrategyMainnet_WTBC_ETH is CamelotV3NitroStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x56c87c3892d3917895bAe1A4cAcf6ea23a4DB84d);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address nftPool = address(0xA562803Aa6FC35C3f3AB2d42b4281fE462dfb620);
    address nitroPool = address(0x773B2db85b0cb5f647F8708d783d04f659Be28e9);
    CamelotV3NitroStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      nftPool,
      nitroPool,
      address(0xFA10759780304c2B8d34B051C039899dFBbcad7f), //xGrail vault
      address(0), //PotPool
      address(0x1F1Ca4e8236CD13032653391dB7e9544a6ad123E) //UniProxy
    );
    rewardTokens = [grail, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/IXGrail.sol";
import "../../base/interface/camelot/IXGrailTokenUsage.sol";
import "../../base/interface/camelot/IDividendsV2.sol";
import "../../base/interface/camelot/ICamelotPair.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/camelot/IYieldBooster.sol";
import "../../base/interface/IUniversalLiquidator.sol";

contract XGrailStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TargetAllocation {
        address allocationAddress; // Address to allocate too
        uint256 weight;            // Weight of allocation (in BPS)
        bytes data;                // Bytes to send in the usageData field
    }

    struct CurrentAllocation {
        address allocationAddress; // Address to allocate too
        uint256 amount;            // Amount of allocation in xGrail
        bytes data;                // Bytes to send in the usageData field
    }

    address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
    address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    bytes32 internal constant _YIELD_BOOSTER_SLOT = 0xbec2ddcc523ceccf38b524de8ba8b3f9263c108934a48e6c1382566b16a326d2;
    bytes32 internal constant _ALLOCATION_WHITELIST_SLOT = 0x0a5b0b20c401b06b37b537c3cab830e5993f53887001d5bcca3f1a84420b9ac4;

    CurrentAllocation[] public currentAllocations;
    TargetAllocation[] public allocationTargets;
    address[] public rewardTokens;
    mapping(address => bool) internal isLp;

    modifier onlyAllocationWhitelist() {
        require(_isAddressInList(msg.sender, allocationWhitelist()),
        "Caller has to be whitelisted");
        _;
    }

    constructor() public BaseUpgradeableStrategy() {
        assert(_YIELD_BOOSTER_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.yieldBooster")) - 1));
        assert(_ALLOCATION_WHITELIST_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allocationWhitelist")) - 1));
    }

    function initializeBaseStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _grail,
        address _yieldBooster
    ) public initializer {

        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            IXGrail(_underlying).dividendsAddress(),
            _grail,
            harvestMSIG
        );

        setAddress(_YIELD_BOOSTER_SLOT, _yieldBooster);
        address[] memory whitelist = new address[](3);
        whitelist[0] = governance();
        whitelist[1] = harvestMSIG;
        whitelist[2] = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, whitelist);
    }

    function yieldBooster() public view returns(address) {
        return getAddress(_YIELD_BOOSTER_SLOT);
    }

    function setYieldBooster(address _target) public onlyGovernance {
        setAddress(_YIELD_BOOSTER_SLOT, _target);
    }

    function allocationWhitelist() public view returns(address[] memory) {
        return getAddressArray(_ALLOCATION_WHITELIST_SLOT);
    }

    function setAllocationWhitelist(address[] memory _allocationWhitelist) public onlyGovernance {
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, _allocationWhitelist);
    }

    function depositArbCheck() external pure returns(bool) {
        return true;
    }

    function dividendsAddress() public view returns(address) {
        return IXGrail(underlying()).dividendsAddress();
    }

    function _liquidateRewards(uint256 _xGrailAmount) internal {
        address _rewardToken = rewardToken();
        address _universalLiquidator = universalLiquidator();
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (isLp[token]) {
                address token0 = ICamelotPair(token).token0();
                address token1 = ICamelotPair(token).token1();
                IERC20(token).safeApprove(camelotRouter, 0);
                IERC20(token).safeApprove(camelotRouter, balance);
                ICamelotRouter(camelotRouter).removeLiquidity(token0, token1, balance, 1, 1, address(this), block.timestamp);
                uint256 balance0 = IERC20(token0).balanceOf(address(this));
                if (token0 != _rewardToken){
                    IERC20(token0).safeApprove(_universalLiquidator, 0);
                    IERC20(token0).safeApprove(_universalLiquidator, balance0);
                    IUniversalLiquidator(_universalLiquidator).swap(token0, _rewardToken, balance0, 1, address(this));
                }
                uint256 balance1 = IERC20(token1).balanceOf(address(this));
                if (token1 != _rewardToken){
                    IERC20(token1).safeApprove(_universalLiquidator, 0);
                    IERC20(token1).safeApprove(_universalLiquidator, balance1);
                    IUniversalLiquidator(_universalLiquidator).swap(token1, _rewardToken, balance1, 1, address(this));
                }
            } else {
                if (token != _rewardToken){
                    IERC20(token).safeApprove(_universalLiquidator, 0);
                    IERC20(token).safeApprove(_universalLiquidator, balance);
                    IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
                }
            }
        }

        uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (rewardBalance < 1e12){
            return;
        }
        _notifyProfitInRewardToken(_rewardToken, rewardBalance.add(_xGrailAmount));
        uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
            return;
        }

        _depositGrail(remainingRewardBalance);
    }

    function _depositGrail(uint256 amount) internal {
        address _rewardToken = rewardToken();
        address _underlying = underlying();
        IERC20(_rewardToken).safeApprove(_underlying, 0);
        IERC20(_rewardToken).safeApprove(_underlying, amount);
        IXGrail(_underlying).convert(amount);
    }

    function getCurrentAllocation(address allocationAddress, bytes memory data) public view returns(uint256) {
        if (allocationAddress == dividendsAddress()) {
            return IXGrail(underlying()).getUsageAllocation(address(this), allocationAddress);
        } else if (allocationAddress == yieldBooster()) {
            (address poolAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
            return IYieldBooster(yieldBooster()).getUserPositionAllocation(address(this), poolAddress, tokenId);
        }
    }

    function xGrailBalanceAllocated() view public returns (IXGrail.XGrailBalance memory) {
        return IXGrail(underlying()).getXGrailBalance(address(this));
    }

    function investedUnderlyingBalance() view public returns (uint256) {
        return xGrailBalanceAllocated().allocatedAmount.add(IERC20(underlying()).balanceOf(address(this)));
    }

    function doHardWork() external onlyNotPausedInvesting restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _liquidateRewards(claimedXGrail);
        rebalanceAllocations();
    }

    function rebalanceAllocations() public onlyNotPausedInvesting restricted {
        uint256 maxLength = currentAllocations.length.add(allocationTargets.length);
        address[] memory increaseAddresses = new address[](maxLength);
        uint256[] memory increaseAmounts = new uint256[](maxLength);
        bytes[] memory increaseDatas = new bytes[](maxLength);
        address[] memory decreaseAddresses = new address[](maxLength);
        uint256[] memory decreaseAmounts = new uint256[](maxLength);
        bytes[] memory decreaseDatas = new bytes[](maxLength);
        uint256 nDecrease = 0;
        uint256 nIncrease = 0;

        for (uint256 i; i < currentAllocations.length; i++) {  //Check if we have current allocations that are not in the targets
            address allocationAddress = currentAllocations[i].allocationAddress;
            bytes memory data = currentAllocations[i].data;
            bool isTarget = false;
            for (uint256 j; j < allocationTargets.length; j++) {
                address targetAddress = allocationTargets[j].allocationAddress;
                bytes memory targetData = allocationTargets[j].data;
                if (targetAddress == allocationAddress && keccak256(targetData) == keccak256(data)) {
                    isTarget = true;
                    break;
                }
            }
            if (!isTarget) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAllocations[i].amount;
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            }
        }

        uint256 nAllocations = 0;
        for (uint256 i; i < allocationTargets.length; i++) {           //Split target allocations into increases and decreases
            address allocationAddress = allocationTargets[i].allocationAddress;
            bytes memory data = allocationTargets[i].data;
            uint256 currentAmount = getCurrentAllocation(allocationAddress, data);
            uint256 targetAmount = investedUnderlyingBalance().mul(allocationTargets[i].weight).div(10000);
            if (currentAmount > targetAmount) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAmount.sub(targetAmount);
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            } else if (targetAmount > currentAmount) {
                increaseAddresses[nIncrease] = allocationAddress;
                increaseAmounts[nIncrease] = targetAmount.sub(currentAmount);
                increaseDatas[nIncrease] = data;
                nIncrease += 1;
            } else {    //No change in amount, store to current positions
                CurrentAllocation memory newAllocation;
                newAllocation.allocationAddress = allocationAddress;
                newAllocation.amount = targetAmount;
                newAllocation.data = data;
                if (nAllocations >= currentAllocations.length) {
                    currentAllocations.push(newAllocation);
                } else {
                    currentAllocations[nAllocations] = newAllocation;
                }
                nAllocations += 1;
            }
        }

        for (uint256 i; i < nDecrease; i++) {        //First handle decreases to free up xGrail for increases
            uint256 currentAllocation = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
            if (currentAllocation > 0){
                IXGrail(underlying()).deallocate(decreaseAddresses[i], Math.min(decreaseAmounts[i], currentAllocation), decreaseDatas[i]);
                if (getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]) > 0){
                    CurrentAllocation memory newAllocation;
                    newAllocation.allocationAddress = decreaseAddresses[i];
                    newAllocation.amount = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
                    newAllocation.data = decreaseDatas[i];
                    if (nAllocations >= currentAllocations.length) {
                        currentAllocations.push(newAllocation);
                    } else {
                        currentAllocations[nAllocations] = newAllocation;
                    }
                    nAllocations += 1;
                }
            }
        }

        for (uint256 i; i < nIncrease; i++) {        //Now handle increases
            address _underlying = underlying();
            uint256 _amount = Math.min(increaseAmounts[i], IERC20(_underlying).balanceOf(address(this)));
            IXGrail(_underlying).approveUsage(increaseAddresses[i], _amount);
            IXGrail(_underlying).allocate(increaseAddresses[i], _amount, increaseDatas[i]);
            CurrentAllocation memory newAllocation;
            newAllocation.allocationAddress = increaseAddresses[i];
            newAllocation.amount = getCurrentAllocation(increaseAddresses[i], increaseDatas[i]);
            newAllocation.data = increaseDatas[i];
            if (nAllocations >= currentAllocations.length) {
                currentAllocations.push(newAllocation);
            } else {
                currentAllocations[nAllocations] = newAllocation;
            }
            nAllocations += 1;
        }

        if (currentAllocations.length > nAllocations) {
            for (uint256 i; i < (currentAllocations.length).sub(nAllocations); i++) {
                currentAllocations.pop();
            }
        }
    }

    function setAllocationTargets(
        address[] memory addresses,
        uint256[] memory weights,
        address[] memory poolAddresses,
        uint256[] memory tokenIds
    ) external onlyAllocationWhitelist {
        require(addresses.length == weights.length, "Array mismatch");
        require(addresses.length == poolAddresses.length, "Array mismatch");
        require(addresses.length == tokenIds.length, "Array mismatch");
        uint256 totalWeight = 0;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == dividendsAddress()) {
                require(weights[i] >= 5000, "Dividend weight");
            }
            TargetAllocation memory newAllocation;
            newAllocation.allocationAddress = addresses[i];
            newAllocation.weight = weights[i];
            if (addresses[i] == dividendsAddress()) {
                newAllocation.data = new bytes(0);
            } else {
                newAllocation.data = abi.encode(poolAddresses[i], tokenIds[i]);
            }
            if (i >= allocationTargets.length) {
                allocationTargets.push(newAllocation);
            } else {
                allocationTargets[i] = newAllocation;
            }
            totalWeight = totalWeight.add(weights[i]);
        }

        require(totalWeight == 10000, "Total weight");

        if (allocationTargets.length > addresses.length) {
            for (uint256 i; i < (allocationTargets.length).sub(addresses.length); i++) {
                allocationTargets.pop();
            }
        }
    }

    function _deallocateAll() internal {
        for (uint256 i; i < currentAllocations.length; i++) {
            if (getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data) > 0) {
                IXGrail(underlying()).deallocate(
                    currentAllocations[i].allocationAddress,
                    getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data),
                    currentAllocations[i].data
                );
            }
        }
        for (uint256 i; i < currentAllocations.length; i++) {
            currentAllocations.pop();
        }
    }

    function _deallocatePartial(uint256 amount) internal {
        uint256 balanceBefore = IERC20(underlying()).balanceOf(address(this));
        uint256 toDeallocate = amount;
        for (uint256 i; i < currentAllocations.length; i++) {
            IXGrail(underlying()).deallocate(
                currentAllocations[i].allocationAddress,
                Math.min(currentAllocations[i].amount, toDeallocate.mul(101).div(100)),
                currentAllocations[i].data
            );
            currentAllocations[i].amount = getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data);

            uint256 balanceNew = IERC20(underlying()).balanceOf(address(this));
            uint256 balanceChange = balanceNew.sub(balanceBefore);
            balanceBefore = balanceNew;
            if (balanceChange >= toDeallocate) {
                return;
            } else {
                toDeallocate = toDeallocate.sub(balanceChange);
            }
        }
    }

    function withdrawAllToVault() public restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _deallocateAll();
        _liquidateRewards(claimedXGrail);
        IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }

    function withdrawToVault(uint256 _amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        address _underlying = underlying();
        uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

        if(_amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = _amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(xGrailBalanceAllocated().allocatedAmount, needToWithdraw);
            _deallocatePartial(toWithdraw);
        }
        IERC20(_underlying).safeTransfer(vault(), _amount);
        rebalanceAllocations();
    }

    function emergencyExit() public onlyGovernance {
        _deallocateAll();
        _setPausedInvesting(true);
    }

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }


    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./XGrailStrategy.sol";

contract XGrailStrategyMainnet_XGrail is XGrailStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address yieldBooster = address(0xD27c373950E7466C53e5Cd6eE3F70b240dC0B1B1);
    address ethUsdc = address(0x84652bb2539513BAf36e225c930Fdd8eaa63CE27);
    XGrailStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      yieldBooster
    );
    rewardTokens = [ethUsdc];
    isLp[ethUsdc] = true;
    TargetAllocation memory initialAllocation;
    initialAllocation.allocationAddress = dividendsAddress();
    initialAllocation.weight = 10000;
    initialAllocation.data = new bytes(0);
    allocationTargets.push(initialAllocation);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/IXGrail.sol";
import "../../base/interface/camelot/IDividendsV2.sol";
import "../../base/interface/camelot/IYieldBooster.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/gamma/IHypervisor.sol";

contract XGrailStrategyV2 is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TargetAllocation {
        address allocationAddress; // Address to allocate too
        uint256 weight;            // Weight of allocation (in BPS)
        bytes data;                // Bytes to send in the usageData field
    }

    struct CurrentAllocation {
        address allocationAddress; // Address to allocate too
        uint256 amount;            // Amount of allocation in xGrail
        bytes data;                // Bytes to send in the usageData field
    }

    address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
    address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    bytes32 internal constant _YIELD_BOOSTER_SLOT = 0xbec2ddcc523ceccf38b524de8ba8b3f9263c108934a48e6c1382566b16a326d2;
    bytes32 internal constant _ALLOCATION_WHITELIST_SLOT = 0x0a5b0b20c401b06b37b537c3cab830e5993f53887001d5bcca3f1a84420b9ac4;

    CurrentAllocation[] public currentAllocations;
    TargetAllocation[] public allocationTargets;
    address[] public rewardTokens;
    mapping(address => bool) internal isLp;

    modifier onlyAllocationWhitelist() {
        require(_isAddressInList(msg.sender, allocationWhitelist()),
        "Caller has to be whitelisted");
        _;
    }

    constructor() public BaseUpgradeableStrategy() {
        assert(_YIELD_BOOSTER_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.yieldBooster")) - 1));
        assert(_ALLOCATION_WHITELIST_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allocationWhitelist")) - 1));
    }

    function initializeBaseStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _grail,
        address _yieldBooster
    ) public initializer {

        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            IXGrail(_underlying).dividendsAddress(),
            _grail,
            harvestMSIG
        );

        setAddress(_YIELD_BOOSTER_SLOT, _yieldBooster);
        address[] memory whitelist = new address[](3);
        whitelist[0] = governance();
        whitelist[1] = harvestMSIG;
        whitelist[2] = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, whitelist);
    }

    function yieldBooster() public view returns(address) {
        return getAddress(_YIELD_BOOSTER_SLOT);
    }

    function setYieldBooster(address _target) public onlyGovernance {
        setAddress(_YIELD_BOOSTER_SLOT, _target);
    }

    function allocationWhitelist() public view returns(address[] memory) {
        return getAddressArray(_ALLOCATION_WHITELIST_SLOT);
    }

    function setAllocationWhitelist(address[] memory _allocationWhitelist) public onlyGovernance {
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, _allocationWhitelist);
    }

    function depositArbCheck() external pure returns(bool) {
        return true;
    }

    function dividendsAddress() public view returns(address) {
        return IXGrail(underlying()).dividendsAddress();
    }

    function _liquidateRewards(uint256 _xGrailAmount) internal {
        address _rewardToken = rewardToken();
        address _universalLiquidator = universalLiquidator();
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (isLp[token]) {
                address token0 = IHypervisor(token).token0();
                address token1 = IHypervisor(token).token1();
                uint256[4] memory minAmounts = [uint(0), uint(0), uint(0), uint(0)];
                IHypervisor(token).withdraw(balance, address(this), address(this), minAmounts);
                uint256 balance0 = IERC20(token0).balanceOf(address(this));
                if (token0 != _rewardToken){
                    IERC20(token0).safeApprove(_universalLiquidator, 0);
                    IERC20(token0).safeApprove(_universalLiquidator, balance0);
                    IUniversalLiquidator(_universalLiquidator).swap(token0, _rewardToken, balance0, 1, address(this));
                }
                uint256 balance1 = IERC20(token1).balanceOf(address(this));
                if (token1 != _rewardToken){
                    IERC20(token1).safeApprove(_universalLiquidator, 0);
                    IERC20(token1).safeApprove(_universalLiquidator, balance1);
                    IUniversalLiquidator(_universalLiquidator).swap(token1, _rewardToken, balance1, 1, address(this));
                }
            } else {
                if (token != _rewardToken){
                    IERC20(token).safeApprove(_universalLiquidator, 0);
                    IERC20(token).safeApprove(_universalLiquidator, balance);
                    IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
                }
            }
        }

        uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (rewardBalance < 1e12){
            return;
        }
        _notifyProfitInRewardToken(_rewardToken, rewardBalance.add(_xGrailAmount));
        uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
            return;
        }

        _depositGrail(remainingRewardBalance);
    }

    function _depositGrail(uint256 amount) internal {
        address _rewardToken = rewardToken();
        address _underlying = underlying();
        IERC20(_rewardToken).safeApprove(_underlying, 0);
        IERC20(_rewardToken).safeApprove(_underlying, amount);
        IXGrail(_underlying).convert(amount);
    }

    function getCurrentAllocation(address allocationAddress, bytes memory data) public view returns(uint256) {
        if (allocationAddress == dividendsAddress()) {
            return IXGrail(underlying()).getUsageAllocation(address(this), allocationAddress);
        } else if (allocationAddress == yieldBooster()) {
            (address poolAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
            return IYieldBooster(yieldBooster()).getUserPositionAllocation(address(this), poolAddress, tokenId);
        }
    }

    function xGrailBalanceAllocated() view public returns (IXGrail.XGrailBalance memory) {
        return IXGrail(underlying()).getXGrailBalance(address(this));
    }

    function investedUnderlyingBalance() view public returns (uint256) {
        return xGrailBalanceAllocated().allocatedAmount.add(IERC20(underlying()).balanceOf(address(this)));
    }

    function doHardWork() external onlyNotPausedInvesting restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _liquidateRewards(claimedXGrail);
        rebalanceAllocations();
    }

    function rebalanceAllocations() public onlyNotPausedInvesting restricted {
        uint256 maxLength = currentAllocations.length.add(allocationTargets.length);
        address[] memory increaseAddresses = new address[](maxLength);
        uint256[] memory increaseAmounts = new uint256[](maxLength);
        bytes[] memory increaseDatas = new bytes[](maxLength);
        address[] memory decreaseAddresses = new address[](maxLength);
        uint256[] memory decreaseAmounts = new uint256[](maxLength);
        bytes[] memory decreaseDatas = new bytes[](maxLength);
        uint256 nDecrease = 0;
        uint256 nIncrease = 0;

        for (uint256 i; i < currentAllocations.length; i++) {  //Check if we have current allocations that are not in the targets
            address allocationAddress = currentAllocations[i].allocationAddress;
            bytes memory data = currentAllocations[i].data;
            bool isTarget = false;
            for (uint256 j; j < allocationTargets.length; j++) {
                address targetAddress = allocationTargets[j].allocationAddress;
                bytes memory targetData = allocationTargets[j].data;
                if (targetAddress == allocationAddress && keccak256(targetData) == keccak256(data)) {
                    isTarget = true;
                    break;
                }
            }
            if (!isTarget) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAllocations[i].amount;
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            }
        }

        uint256 nAllocations = 0;
        for (uint256 i; i < allocationTargets.length; i++) {           //Split target allocations into increases and decreases
            address allocationAddress = allocationTargets[i].allocationAddress;
            bytes memory data = allocationTargets[i].data;
            uint256 currentAmount = getCurrentAllocation(allocationAddress, data);
            uint256 targetAmount = investedUnderlyingBalance().mul(allocationTargets[i].weight).div(10000);
            if (currentAmount > targetAmount) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAmount.sub(targetAmount);
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            } else if (targetAmount > currentAmount) {
                increaseAddresses[nIncrease] = allocationAddress;
                increaseAmounts[nIncrease] = targetAmount.sub(currentAmount);
                increaseDatas[nIncrease] = data;
                nIncrease += 1;
            } else {    //No change in amount, store to current positions
                CurrentAllocation memory newAllocation;
                newAllocation.allocationAddress = allocationAddress;
                newAllocation.amount = targetAmount;
                newAllocation.data = data;
                if (nAllocations >= currentAllocations.length) {
                    currentAllocations.push(newAllocation);
                } else {
                    currentAllocations[nAllocations] = newAllocation;
                }
                nAllocations += 1;
            }
        }

        for (uint256 i; i < nDecrease; i++) {        //First handle decreases to free up xGrail for increases
            uint256 currentAllocation = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
            if (currentAllocation > 0){
                IXGrail(underlying()).deallocate(decreaseAddresses[i], Math.min(decreaseAmounts[i], currentAllocation), decreaseDatas[i]);
                if (getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]) > 0){
                    CurrentAllocation memory newAllocation;
                    newAllocation.allocationAddress = decreaseAddresses[i];
                    newAllocation.amount = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
                    newAllocation.data = decreaseDatas[i];
                    if (nAllocations >= currentAllocations.length) {
                        currentAllocations.push(newAllocation);
                    } else {
                        currentAllocations[nAllocations] = newAllocation;
                    }
                    nAllocations += 1;
                }
            }
        }

        for (uint256 i; i < nIncrease; i++) {        //Now handle increases
            address _underlying = underlying();
            uint256 _amount = Math.min(increaseAmounts[i], IERC20(_underlying).balanceOf(address(this)));
            IXGrail(_underlying).approveUsage(increaseAddresses[i], _amount);
            IXGrail(_underlying).allocate(increaseAddresses[i], _amount, increaseDatas[i]);
            CurrentAllocation memory newAllocation;
            newAllocation.allocationAddress = increaseAddresses[i];
            newAllocation.amount = getCurrentAllocation(increaseAddresses[i], increaseDatas[i]);
            newAllocation.data = increaseDatas[i];
            if (nAllocations >= currentAllocations.length) {
                currentAllocations.push(newAllocation);
            } else {
                currentAllocations[nAllocations] = newAllocation;
            }
            nAllocations += 1;
        }

        if (currentAllocations.length > nAllocations) {
            for (uint256 i; i < (currentAllocations.length).sub(nAllocations); i++) {
                currentAllocations.pop();
            }
        }
    }

    function setAllocationTargets(
        address[] memory addresses,
        uint256[] memory weights,
        address[] memory poolAddresses,
        uint256[] memory tokenIds
    ) external onlyAllocationWhitelist {
        require(addresses.length == weights.length, "Array mismatch");
        require(addresses.length == poolAddresses.length, "Array mismatch");
        require(addresses.length == tokenIds.length, "Array mismatch");
        uint256 totalWeight = 0;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == dividendsAddress()) {
                require(weights[i] >= 5000, "Dividend weight");
            }
            TargetAllocation memory newAllocation;
            newAllocation.allocationAddress = addresses[i];
            newAllocation.weight = weights[i];
            if (addresses[i] == dividendsAddress()) {
                newAllocation.data = new bytes(0);
            } else {
                newAllocation.data = abi.encode(poolAddresses[i], tokenIds[i]);
            }
            if (i >= allocationTargets.length) {
                allocationTargets.push(newAllocation);
            } else {
                allocationTargets[i] = newAllocation;
            }
            totalWeight = totalWeight.add(weights[i]);
        }

        require(totalWeight == 10000, "Total weight");

        if (allocationTargets.length > addresses.length) {
            for (uint256 i; i < (allocationTargets.length).sub(addresses.length); i++) {
                allocationTargets.pop();
            }
        }
    }

    function _deallocateAll() internal {
        for (uint256 i; i < currentAllocations.length; i++) {
            if (getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data) > 0) {
                IXGrail(underlying()).deallocate(
                    currentAllocations[i].allocationAddress,
                    getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data),
                    currentAllocations[i].data
                );
            }
        }
        for (uint256 i; i < currentAllocations.length; i++) {
            currentAllocations.pop();
        }
    }

    function _deallocatePartial(uint256 amount) internal {
        uint256 balanceBefore = IERC20(underlying()).balanceOf(address(this));
        uint256 toDeallocate = amount;
        for (uint256 i; i < currentAllocations.length; i++) {
            IXGrail(underlying()).deallocate(
                currentAllocations[i].allocationAddress,
                Math.min(currentAllocations[i].amount, toDeallocate.mul(101).div(100)),
                currentAllocations[i].data
            );
            currentAllocations[i].amount = getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data);

            uint256 balanceNew = IERC20(underlying()).balanceOf(address(this));
            uint256 balanceChange = balanceNew.sub(balanceBefore);
            balanceBefore = balanceNew;
            if (balanceChange >= toDeallocate) {
                return;
            } else {
                toDeallocate = toDeallocate.sub(balanceChange);
            }
        }
    }

    function withdrawAllToVault() public restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _deallocateAll();
        _liquidateRewards(claimedXGrail);
        IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }

    function withdrawToVault(uint256 _amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        address _underlying = underlying();
        uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

        if(_amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = _amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(xGrailBalanceAllocated().allocatedAmount, needToWithdraw);
            _deallocatePartial(toWithdraw);
        }
        IERC20(_underlying).safeTransfer(vault(), _amount);
        rebalanceAllocations();
    }

    function emergencyExit() public onlyGovernance {
        _deallocateAll();
        _setPausedInvesting(true);
    }

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }


    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    function finalizeUpgrade() external onlyGovernance {
        address ethUsdc = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
        rewardTokens = [ethUsdc];
        isLp[ethUsdc] = true;
        _finalizeUpgrade();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./XGrailStrategyV2.sol";

contract XGrailStrategyV2Mainnet_XGrail is XGrailStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address yieldBooster = address(0xD27c373950E7466C53e5Cd6eE3F70b240dC0B1B1);
    address ethUsdc = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
    XGrailStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      yieldBooster
    );
    rewardTokens = [ethUsdc];
    isLp[ethUsdc] = true;
    TargetAllocation memory initialAllocation;
    initialAllocation.allocationAddress = dividendsAddress();
    initialAllocation.weight = 10000;
    initialAllocation.data = new bytes(0);
    allocationTargets.push(initialAllocation);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/compound/IComet.sol";
import "../../base/interface/compound/ICometRewards.sol";

contract CompoundStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _MARKET_SLOT = 0x7e894854bb2aa938fcac0eb9954ddb51bd061fc228fb4e5b8e859d96c06bfaa0;

  constructor() public BaseUpgradeableStrategy() {
    assert(_MARKET_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.market")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _market,
    address _rewardPool,
    address _rewardToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      harvestMSIG
    );

    address _lpt = IComet(_market).baseToken();
    require(_lpt == _underlying, "Underlying mismatch");

    _setMarket(_market);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = IComet(market()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    IComet(market()).withdraw(underlying(), Math.min(_rewardPoolBalance(), amount));
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address market_ = market();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(market_, 0);
    IERC20(underlying_).safeApprove(market_, entireBalance);
    IComet(market_).supply(underlying_, entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == market());
  }

  function _claimReward() internal {
    ICometRewards(rewardPool()).claim(market(), address(this), true);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _claimReward();
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    _claimReward();
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  function _setMarket(address _address) internal {
    setAddress(_MARKET_SLOT, _address);
  }

  function market() public view returns (address) {
    return getAddress(_MARKET_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./CompoundStrategy.sol";

contract CompoundStrategyMainnet_USDC is CompoundStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address market = address(0xA5EDBDD9646f8dFF606d7448e414884C7d905dCA);
    address rewards = address(0x88730d254A2f7e6AC8388c3198aFd694bA9f7fae);
    address comp = address(0x354A6dA3fcde098F8389cad84b0182725c6C91dE);
    CompoundStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      market,
      rewards,
      comp
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../interface/IBooster.sol";
import "../interface/IBaseRewardPool.sol";
import "../../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../../base/interface/curve/ICurveDeposit_2token.sol";
import "../../../base/interface/curve/ICurveDeposit_3token.sol";
import "../../../base/interface/curve/ICurveDeposit_3token_meta.sol";
import "../../../base/interface/curve/ICurveDeposit_4token.sol";
import "../../../base/interface/curve/ICurveDeposit_4token_meta.sol";
import "../../../base/interface/weth/IWETH.sol";

contract ConvexStrategy is BaseUpgradeableStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _DEPOSIT_ARRAY_POSITION_SLOT = 0xb7c50ef998211fff3420379d0bf5b8dfb0cee909d1b7d9e517f311c104675b09;
  bytes32 internal constant _CURVE_DEPOSIT_SLOT = 0xb306bb7adebd5a22f5e4cdf1efa00bc5f62d4f5554ef9d62c1b16327cd3ab5f9;
  bytes32 internal constant _NTOKENS_SLOT = 0xbb60b35bae256d3c1378ff05e8d7bee588cd800739c720a107471dfa218f74c1;
  bytes32 internal constant _METAPOOL_SLOT = 0x567ad8b67c826974a167f1a361acbef5639a3e7e02e99edbc648a84b0923d5b7;

  // this would be reset on each upgrade
  address[] public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  address[] public rewardTokens;
  mapping (address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_DEPOSIT_ARRAY_POSITION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositArrayPosition")) - 1));
    assert(_CURVE_DEPOSIT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.curveDeposit")) - 1));
    assert(_NTOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nTokens")) - 1));
    assert(_METAPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.metaPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolID,
    address _depositToken,
    uint256 _depositArrayPosition,
    address _curveDeposit,
    uint256 _nTokens,
    bool _metaPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    address _lpt;
    (_lpt,,,,) = IBooster(booster).poolInfo(_poolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    require(_depositArrayPosition < _nTokens, "Deposit array position out of bounds");
    require(1 < _nTokens && _nTokens < 5, "_nTokens should be 2, 3 or 4");
    _setDepositArrayPosition(_depositArrayPosition);
    _setPoolId(_poolID);
    _setDepositToken(_depositToken);
    _setCurveDeposit(_curveDeposit);
    _setNTokens(_nTokens);
    _setMetaPool(_metaPool);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function rewardPoolBalance() internal view returns (uint256 bal) {
      bal = IBaseRewardPool(rewardPool()).balanceOf(address(this));
  }

  function exitRewardPool() internal {
      uint256 stakedBalance = rewardPoolBalance();
      if (stakedBalance != 0) {
          IBaseRewardPool(rewardPool()).withdrawAll(true);
      }
  }

  function partialWithdrawalRewardPool(uint256 amount) internal {
    IBaseRewardPool(rewardPool()).withdraw(amount, false);  //don't claim rewards at this point
  }

  function emergencyExitRewardPool() internal {
    uint256 stakedBalance = rewardPoolBalance();
    if (stakedBalance != 0) {
        IBaseRewardPool(rewardPool()).withdrawAll(false); //don't claim rewards
    }
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function enterRewardPool() internal {
    address _underlying = underlying();
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeApprove(booster, 0);
    IERC20(_underlying).safeApprove(booster, entireBalance);
    IBooster(booster).depositAll(poolId()); //deposit and stake
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == depositToken(), "Path should end with depositToken");
    WETH2deposit = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
  }

  function addRewardToken(address _token, address[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH);
  }

  function changeDepositToken(address _depositToken, address[] memory _liquidationPath) public onlyGovernance {
    _setDepositToken(_depositToken);
    setDepositLiquidationPath(_liquidationPath);
  }

  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 3000;
    }
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  function uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  // We assume that all the tradings can be done on Sushiswap
  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapoolId exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _depositToken = depositToken();

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if(reward2WETH[token].length < 2 || rewardBalance < 1e15) {
        continue;
      }

      uniV3Swap(rewardBalance, 1, reward2WETH[token]);
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if(_depositToken != _rewardToken) {
      uniV3Swap(remainingRewardBalance, 1, WETH2deposit);
    }

    uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
    if (tokenBalance > 0) {
      depositCurve();
    }
  }

  function depositCurve() internal {
    address _depositToken = depositToken();
    address _curveDeposit = curveDeposit();
    uint256 _nTokens = nTokens();
    uint256 _depositArrayPosition = depositArrayPosition();
    bool _metaPool = metaPool();

    uint256 tokenBalance = IERC20(_depositToken).balanceOf(address(this));
    IERC20(_depositToken).safeApprove(_curveDeposit, 0);
    IERC20(_depositToken).safeApprove(_curveDeposit, tokenBalance);

    // we can accept 1 as minimum, this will be called only by trusted roles
    uint256 minimum = 1;
    if (_nTokens == 2) {
      uint256[2] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      ICurveDeposit_2token(_curveDeposit).add_liquidity(depositArray, minimum);
    } else if (_nTokens == 3) {
      uint256[3] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        ICurveDeposit_3token_meta(_curveDeposit).add_liquidity(underlying(), depositArray, minimum);
      } else {
        ICurveDeposit_3token(_curveDeposit).add_liquidity(depositArray, minimum);
      }
    } else if (_nTokens == 4) {
      uint256[4] memory depositArray;
      depositArray[_depositArrayPosition] = tokenBalance;
      if (_metaPool) {
        ICurveDeposit_4token_meta(_curveDeposit).add_liquidity(underlying(), depositArray, minimum);
      } else {
        ICurveDeposit_4token(_curveDeposit).add_liquidity(depositArray, minimum);
      }
    }
  }

  /*
  *   Stakes everything the strategy holds into the reward pool
  */
  function investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      enterRewardPool();
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    if (address(rewardPool()) != address(0)) {
      exitRewardPool();
    }
    _liquidateReward();
    IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    address _underlying = underlying();
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(rewardPoolBalance(), needToWithdraw);
      partialWithdrawalRewardPool(toWithdraw);
    }
    IERC20(_underlying).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    return rewardPoolBalance()
      .add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IBaseRewardPool(rewardPool()).getReward(address(this));
    _liquidateReward();
    investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function _setDepositArrayPosition(uint256 _value) internal {
    setUint256(_DEPOSIT_ARRAY_POSITION_SLOT, _value);
  }

  function depositArrayPosition() public view returns (uint256) {
    return getUint256(_DEPOSIT_ARRAY_POSITION_SLOT);
  }

  function _setCurveDeposit(address _address) internal {
    setAddress(_CURVE_DEPOSIT_SLOT, _address);
  }

  function curveDeposit() public view returns (address) {
    return getAddress(_CURVE_DEPOSIT_SLOT);
  }

  function _setNTokens(uint256 _value) internal {
    setUint256(_NTOKENS_SLOT, _value);
  }

  function nTokens() public view returns (uint256) {
    return getUint256(_NTOKENS_SLOT);
  }

  function _setMetaPool(bool _value) internal {
    setBoolean(_METAPOOL_SLOT, _value);
  }

  function metaPool() public view returns (bool) {
    return getBoolean(_METAPOOL_SLOT);
  }


  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the WETH unwrapping
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./base/ConvexStrategy.sol";

contract ConvexStrategyMainnet_FRAX_USDC is ConvexStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xC9B8a3FDECB9D5b218d02555a8Baf332E5B740d5); // Info -> LP Token address
    address rewardPool = address(0x93729702Bf9E1687Ae2124e191B8fFbcC0C8A0B0); // Info -> Rewards contract address
    address crv = address(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
    address cvx = address(0xb952A807345991BD529FDded05009F5e80Fe8F45);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    ConvexStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, // rewardPool
      10,  // Pool id: Info -> Rewards contract address -> read -> pid
      usdc, // depositToken
      1, //depositArrayPosition. Find deposit transaction -> input params
      underlying, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      2, //nTokens -> total number of deposit tokens
      false //metaPool -> if LP token address == pool address (at curve)
    );
    rewardTokens = [crv, cvx];
    reward2WETH[crv] = [crv, weth];
    reward2WETH[cvx] = [cvx, weth];
    WETH2deposit = [weth, usdc];
    storedPairFee[weth][usdc] = 500;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./base/ConvexStrategy.sol";

contract ConvexStrategyMainnet_USDC_USDT is ConvexStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x7f90122BF0700F9E7e1F688fe926940E8839F353); // Info -> LP Token address
    address rewardPool = address(0x971E732B5c91A59AEa8aa5B0c763E6d648362CF8); // Info -> Rewards contract address
    address crv = address(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
    address cvx = address(0xb952A807345991BD529FDded05009F5e80Fe8F45);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    ConvexStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, // rewardPool
      7,  // Pool id: Info -> Rewards contract address -> read -> pid
      usdc, // depositToken
      0, //depositArrayPosition. Find deposit transaction -> input params
      underlying, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      2, //nTokens -> total number of deposit tokens
      false //metaPool -> if LP token address == pool address (at curve)
    );
    rewardTokens = [crv, cvx];
    reward2WETH[crv] = [crv, weth];
    reward2WETH[cvx] = [cvx, weth];
    WETH2deposit = [weth, usdc];
    storedPairFee[weth][usdc] = 500;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./base/ConvexStrategy.sol";

contract ConvexStrategyMainnet_USDT_WBTC_WETH is ConvexStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2); // Info -> LP Token address
    address rewardPool = address(0xA9249f8667cb120F065D9dA1dCb37AD28E1E8FF0); // Info -> Rewards contract address
    address crv = address(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978);
    address cvx = address(0xb952A807345991BD529FDded05009F5e80Fe8F45);
    address curveDeposit = address(0x960ea3e3C7FB317332d990873d354E18d7645590); // only needed if deposits are not via underlying
    ConvexStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool, // rewardPool
      8,  // Pool id: Info -> Rewards contract address -> read -> pid
      weth, // depositToken
      2, //depositArrayPosition. Find deposit transaction -> input params
      curveDeposit, // deposit contract: usually underlying. Find deposit transaction -> interacted contract
      3, //nTokens -> total number of deposit tokens
      false //metaPool -> if LP token address == pool address (at curve)
    );
    rewardTokens = [crv, cvx];
    reward2WETH[crv] = [crv, weth];
    reward2WETH[cvx] = [cvx, weth];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IBaseRewardPool {
    function balanceOf(address account) external view returns(uint256 amount);
    function pid() external view returns (uint256 _pid);
    function stakingToken() external view returns (address _stakingToken);
    function getReward(address account) external;
    function stake(uint256 _amount) external;
    function stakeAll() external;
    function withdraw(uint256 amount, bool claim) external;
    function withdrawAll(bool claim) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
    function depositAll(uint256 _pid) external;
    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external;
    function poolInfo(uint256 _pid) external view returns (address lpToken, address, address, bool, address);
    function earmarkRewards(uint256 _pid) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/sushiswap/IMiniChefV2.sol";

contract JonesStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _poolID
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      harvestMSIG
    );

    address _lpt = IMiniChefV2(rewardPool()).lpToken(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolID);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance,) = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    if (amount > 0) {
      IMiniChefV2(rewardPool()).withdraw(poolId(), amount, address(this));
    }
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IMiniChefV2(rewardPool_).deposit(poolId(), entireBalance, address(this));
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (token != _rewardToken && balance != 0){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./JonesStrategy.sol";

contract JonesStrategyMainnet_wjAURA is JonesStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xcB9295ac65De60373A25C18d2044D517ed5da8A9);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address miniChef = address(0x0aEfaD19aA454bCc1B1Dd86e18A7d58D0a6FAC38);
    JonesStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      miniChef,
      arb,
      2        // Pool id
    );
    rewardTokens = [arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/lodestar/IStakingRewards.sol";

contract LodeStakingStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      _rewardToken,
      harvestMSIG
    );

    address _lpt = IStakingRewards(rewardPool()).LODE();
    require(_lpt == _underlying, "Underlying mismatch");
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance,) = IStakingRewards(rewardPool()).userInfo(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
      IStakingRewards(rewardPool()).emergencyStakerWithdrawal();
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    if (amount > 0) {
      IStakingRewards(rewardPool()).unstakeLODE(amount);
    }
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IStakingRewards(rewardPool_).stakeLODE(entireBalance, 10);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (token != _rewardToken && balance != 0){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (_rewardPoolBalance() > 0){
      IStakingRewards(rewardPool()).claimRewards();
    }
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    if (_rewardPoolBalance() > 0){
      IStakingRewards(rewardPool()).claimRewards();
    }
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./LodeStakingStrategy.sol";

contract LodeStakingStrategyMainnet_LODE is LodeStakingStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address rewardPool = address(0x8ab1774A6FC5eE51559964e13ECD54155340c116);
    LodeStakingStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool,
      weth
    );
    rewardTokens = [weth];
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/lodestar/CTokenInterfaces.sol";
import "../../base/interface/lodestar/ComptrollerInterface.sol";
import "../../base/interface/balancer/IBVault.sol";
import "../../base/interface/weth/IWETH.sol";

contract LodestarFoldStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _CTOKEN_SLOT = 0x316ad921d519813e6e41c0e056b79e4395192c2b101f8b61cf5b94999360d568;
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;

  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;

  bool internal makingFlashDeposit;
  bool internal makingFlashWithdrawal;

  constructor() public BaseUpgradeableStrategy() {
    assert(_CTOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.cToken")) - 1));
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _cToken,
    address _comptroller,
    address _rewardToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    uint256 _factorDenominator,
    bool _fold
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _comptroller,
      _rewardToken,
      harvestMSIG
    );

    if (_underlying != weth) {
      require(CErc20Interface(_cToken).underlying() == _underlying, "Underlying mismatch");
    }

    _setCToken(_cToken);

    require(_collateralFactorNumerator < _factorDenominator, "Numerator should be smaller than denominator");
    require(_borrowTargetFactorNumerator < _collateralFactorNumerator, "Target should be lower than limit");
    _setFactorDenominator(_factorDenominator);
    _setCollateralFactorNumerator(_collateralFactorNumerator);
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    setBoolean(_FOLD_SLOT, _fold);
    address[] memory markets = new address[](1);
    markets[0] = _cToken;
    ComptrollerInterface(_comptroller).enterMarkets(markets);
  }

  modifier updateSupplyInTheEnd() {
    _;
    address _cToken = cToken();
    // amount we supplied
    suppliedInUnderlying = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    borrowedInUnderlying = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == cToken());
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function _investAllUnderlying() internal onlyNotPausedInvesting updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (!fold()) {
      return;
    }
    _depositWithFlashloan();
  }

  /**
  * Exits Moonwell and transfers everything to the vault.
  */
  function withdrawAllToVault() public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    _withdrawMaximum(true);
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    _withdrawMaximum(false);
  }

  function _withdrawMaximum(bool claim) internal updateSupplyInTheEnd {
    if (claim) {
      _claimRewards();
      _liquidateRewards();
    }
    _redeemMaximum();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amountUnderlying <= balance) {
      IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
      return;
    }
    uint256 toRedeem = amountUnderlying.sub(balance);
    // get some of the underlying
    _redeemPartial(toRedeem);
    // transfer the amount requested (or the amount we have) back to vault()
    IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
    balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      _investAllUnderlying();
    }
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    _claimRewards();
    _liquidateRewards();
    _investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy vUnderlying balance becomes 0.
  */
  function _redeemMaximum() internal {
    _redeemMaximumWithFlashloan();
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function _redeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    _redeemWithFlashloan(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0
      );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimRewards() internal {
    ComptrollerInterface(rewardPool()).claimComp(address(this));
  }

  function _liquidateRewards() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    if (rewardBalance <= 1e13) {
      return;
    }
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance <= 1e13) {
      return;
    }
  
    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /**
  * Returns the current balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Radiant - debt
    return IERC20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  /**
  * Supplies to Moonwel
  */
  function _supply(uint256 amount) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    if (_underlying == weth) {
      IWETH(weth).withdraw(balance);
      CErc20Interface(_cToken).mint{value: balance}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, balance);
      CErc20Interface(_cToken).mint(balance);
    }
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    // Borrow, check the balance for this contract's address
    CErc20Interface(cToken()).borrow(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _redeem(uint256 amountUnderlying) internal {
    CErc20Interface(cToken()).redeemUnderlying(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _repay(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    if (_underlying == weth) {
      IWETH(weth).withdraw(amountUnderlying);
      CErc20Interface(_cToken).repayBorrow{value: amountUnderlying}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, amountUnderlying);
      CErc20Interface(_cToken).repayBorrow(amountUnderlying);
    }
  }

  function _redeemMaximumWithFlashloan() internal {
    address _cToken = cToken();
    // amount of liquidity in Radiant
    uint256 available = CTokenInterface(_cToken).getCash();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);

    _redeemWithFlashloan(Math.min(available, balance), 0);
    supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    if (supplied > 0) {
      _redeem(supplied);
    }
  }

  function _depositWithFlashloan() internal {
    address _cToken = cToken();
    uint _denom = factorDenominator();
    uint _borrowNum = borrowTargetFactorNumerator();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    if (borrowed > borrowTarget) {
      setBoolean(_FOLD_SLOT, false);
      _redeemPartial(0);
      return;
    }
    uint256 borrowDiff = borrowTarget.sub(borrowed);

    uint256 totalBorrows = CTokenInterface(_cToken).totalBorrowsCurrent();
    uint256 borrowCap = ComptrollerInterface(rewardPool()).borrowCaps(_cToken);

    if (totalBorrows.add(borrowDiff) > borrowCap) {
      return;
    }

    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = abi.encode(0);
    tokens[0] = underlying();
    amounts[0] = borrowDiff;
    makingFlashDeposit = true;
    IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
    makingFlashDeposit = false;
  }

  function _redeemWithFlashloan(uint256 amount, uint256 borrowTargetFactorNumerator) internal {
    address _cToken = cToken();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(borrowTargetFactorNumerator).div(factorDenominator().sub(borrowTargetFactorNumerator));
    }
    uint256 borrowDiff = borrowed.sub(newBorrowTarget);

    address[] memory tokens = new address[](1);
    uint256[] memory amounts = new uint256[](1);
    bytes memory userData = abi.encode(0);
    tokens[0] = underlying();
    amounts[0] = borrowDiff;
    makingFlashWithdrawal = true;
    IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
    makingFlashWithdrawal = false;
  }

  function receiveFlashLoan(IERC20[] memory /*tokens*/, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory /*userData*/) external {
    require(msg.sender == bVault);
    require(!makingFlashDeposit || !makingFlashWithdrawal, "Only one can be true");
    require(makingFlashDeposit || makingFlashWithdrawal, "One has to be true");
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    uint256 toRepay = amounts[0].add(feeAmounts[0]);
    if (makingFlashDeposit){
      _supply(balance);
      _borrow(toRepay);
    } else {
      address _cToken = cToken();
      uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      uint256 repaying = Math.min(balance, borrowed);
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, repaying);
      _repay(repaying);
      _redeem(toRepay);
    }
    balance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeTransfer(bVault, toRepay);
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function _setCollateralFactorNumerator(uint256 _numerator) internal {
    require(_numerator <= uint(820).mul(factorDenominator()).div(1000), "Collateral factor cannot be this high");
    require(_numerator > borrowTargetFactorNumerator(), "Collateral factor should be higher than borrow target");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
  }

  function _setFactorDenominator(uint256 _denominator) internal {
    setUint256(_FACTORDENOMINATOR_SLOT, _denominator);
  }

  function factorDenominator() public view returns (uint256) {
    return getUint256(_FACTORDENOMINATOR_SLOT);
  }

  function setBorrowTargetFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator < collateralFactorNumerator(), "Target should be lower than collateral limit");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _numerator);
  }

  function borrowTargetFactorNumerator() public view returns (uint256) {
    return getUint256(_BORROWTARGETFACTORNUMERATOR_SLOT);
  }

  function setFold (bool _fold) public onlyGovernance {
    setBoolean(_FOLD_SLOT, _fold);
  }

  function fold() public view returns (bool) {
    return getBoolean(_FOLD_SLOT);
  }

  function _setCToken (address _target) internal {
    setAddress(_CTOKEN_SLOT, _target);
  }

  function cToken() public view returns (address) {
    return getAddress(_CTOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance updateSupplyInTheEnd {
    _finalizeUpgrade();
  }

  receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_DAI is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address cToken = address(0x4987782da9a63bC3ABace48648B15546D821c720);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_ETH is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address cToken = address(0x2193c45244AF12C280941281c8aa67dD08be0a64);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      780,
      800,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_FRAX is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F);
    address cToken = address(0xD12d43Cdf498e377D3bfa2c6217f05B466E14228);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_USDC is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address cToken = address(0x4C9aAed3b8c443b4b634D1A189a5e25C604768dE);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      800,
      820,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_USDCe is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address cToken = address(0x1ca530f02DD0487cef4943c674342c5aEa08922F);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      800,
      820,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_USDT is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address cToken = address(0x9365181A7df82a1cC578eAE443EFd89f00dbb643);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      680,
      700,
      1000,
      true
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategy.sol";

contract LodestarFoldStrategyMainnet_WBTC is LodestarFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address cToken = address(0xC37896BF3EE5a2c62Cdbd674035069776f721668);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/lodestar/CTokenInterfaces.sol";
import "../../base/interface/lodestar/ComptrollerInterface.sol";
import "../../base/interface/balancer/IBVault.sol";
import "../../base/interface/weth/IWETH.sol";

contract LodestarFoldStrategyV2 is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _CTOKEN_SLOT = 0x316ad921d519813e6e41c0e056b79e4395192c2b101f8b61cf5b94999360d568;
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;

  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;

  bool internal makingFlashDeposit;
  bool internal makingFlashWithdrawal;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_CTOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.cToken")) - 1));
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _cToken,
    address _comptroller,
    address _rewardToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    uint256 _factorDenominator,
    bool _fold
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _comptroller,
      _rewardToken,
      harvestMSIG
    );

    if (_underlying != weth) {
      require(CErc20Interface(_cToken).underlying() == _underlying, "Underlying mismatch");
    }

    _setCToken(_cToken);

    require(_collateralFactorNumerator < _factorDenominator, "Numerator should be smaller than denominator");
    require(_borrowTargetFactorNumerator < _collateralFactorNumerator, "Target should be lower than limit");
    _setFactorDenominator(_factorDenominator);
    _setCollateralFactorNumerator(_collateralFactorNumerator);
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    setBoolean(_FOLD_SLOT, _fold);
    address[] memory markets = new address[](1);
    markets[0] = _cToken;
    ComptrollerInterface(_comptroller).enterMarkets(markets);
  }

  modifier updateSupplyInTheEnd() {
    _;
    address _cToken = cToken();
    // amount we supplied
    suppliedInUnderlying = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    borrowedInUnderlying = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == cToken());
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function _investAllUnderlying() internal onlyNotPausedInvesting updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (!fold()) {
      return;
    }
    _depositWithFlashloan();
  }

  /**
  * Exits Moonwell and transfers everything to the vault.
  */
  function withdrawAllToVault() public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    _withdrawMaximum(true);
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    _withdrawMaximum(false);
  }

  function _withdrawMaximum(bool claim) internal updateSupplyInTheEnd {
    if (claim) {
      _claimRewards();
      _liquidateRewards();
    }
    _redeemMaximum();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amountUnderlying <= balance) {
      IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
      return;
    }
    uint256 toRedeem = amountUnderlying.sub(balance);
    // get some of the underlying
    _redeemPartial(toRedeem);
    // transfer the amount requested (or the amount we have) back to vault()
    IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
    balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      _investAllUnderlying();
    }
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    _claimRewards();
    _liquidateRewards();
    _investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy vUnderlying balance becomes 0.
  */
  function _redeemMaximum() internal {
    _redeemMaximumWithFlashloan();
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function _redeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    _redeemWithFlashloan(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0
      );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimRewards() internal {
    ComptrollerInterface(rewardPool()).claimComp(address(this));
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateRewards() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
          IERC20(token).safeApprove(_universalLiquidator, 0);
          IERC20(token).safeApprove(_universalLiquidator, balance);
          IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance <= 1e13) {
      return;
    }
  
    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /**
  * Returns the current balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Radiant - debt
    return IERC20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  /**
  * Supplies to Moonwel
  */
  function _supply(uint256 amount) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    if (_underlying == weth) {
      IWETH(weth).withdraw(balance);
      CErc20Interface(_cToken).mint{value: balance}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, balance);
      CErc20Interface(_cToken).mint(balance);
    }
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    // Borrow, check the balance for this contract's address
    CErc20Interface(cToken()).borrow(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _redeem(uint256 amountUnderlying) internal {
    CErc20Interface(cToken()).redeemUnderlying(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _repay(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    if (_underlying == weth) {
      IWETH(weth).withdraw(amountUnderlying);
      CErc20Interface(_cToken).repayBorrow{value: amountUnderlying}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, amountUnderlying);
      CErc20Interface(_cToken).repayBorrow(amountUnderlying);
    }
  }

  function _redeemMaximumWithFlashloan() internal {
    address _cToken = cToken();
    // amount of liquidity in Radiant
    uint256 available = CTokenInterface(_cToken).getCash();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);

    _redeemWithFlashloan(Math.min(available, balance), 0);
    supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    if (supplied > 0) {
      _redeem(supplied);
    }
  }

  function _depositWithFlashloan() internal {
    address _cToken = cToken();
    uint _denom = factorDenominator();
    uint _borrowNum = borrowTargetFactorNumerator();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    uint256 borrowDiff;
    if (borrowed > borrowTarget) {
      _redeemPartial(0);
      borrowDiff = 0;
    } else {
      borrowDiff = borrowTarget.sub(borrowed);
      uint256 borrowCap = ComptrollerInterface(rewardPool()).borrowCaps(_cToken);
      uint256 totalBorrows = CTokenInterface(_cToken).totalBorrows();
      uint256 borrowAvail;
      if (totalBorrows < borrowCap) {
        borrowAvail = borrowCap.sub(totalBorrows).sub(1);
      } else {
        borrowAvail = 0;
      }
      if (borrowDiff > borrowAvail){
        borrowDiff = borrowAvail;
      }
    }

    address _underlying = underlying();
    uint256 balancerBalance = IERC20(_underlying).balanceOf(bVault);

    if (borrowDiff > balancerBalance) {
      _depositNoFlash(supplied, borrowed, _cToken, _denom, _borrowNum);
    } else {
      address[] memory tokens = new address[](1);
      uint256[] memory amounts = new uint256[](1);
      bytes memory userData = abi.encode(0);
      tokens[0] = underlying();
      amounts[0] = borrowDiff;
      makingFlashDeposit = true;
      IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
      makingFlashDeposit = false;
    }
  }

  function _redeemWithFlashloan(uint256 amount, uint256 borrowTargetFactorNumerator) internal {
    address _cToken = cToken();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(borrowTargetFactorNumerator).div(factorDenominator().sub(borrowTargetFactorNumerator));
    }
    uint256 borrowDiff = borrowed.sub(newBorrowTarget);
    address _underlying = underlying();
    uint256 balancerBalance = IERC20(_underlying).balanceOf(bVault);

    if (borrowDiff > balancerBalance) {
      _redeemNoFlash(amount, supplied, borrowed, _cToken, factorDenominator(), borrowTargetFactorNumerator);
    } else {
      address[] memory tokens = new address[](1);
      uint256[] memory amounts = new uint256[](1);
      bytes memory userData = abi.encode(0);
      tokens[0] = underlying();
      amounts[0] = borrowDiff;
      makingFlashWithdrawal = true;
      IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
      makingFlashWithdrawal = false;
      _redeem(amount);
    }
  }

  function receiveFlashLoan(IERC20[] memory /*tokens*/, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory /*userData*/) external {
    require(msg.sender == bVault);
    require(!makingFlashDeposit || !makingFlashWithdrawal, "Only one can be true");
    require(makingFlashDeposit || makingFlashWithdrawal, "One has to be true");
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    uint256 toRepay = amounts[0].add(feeAmounts[0]);
    if (makingFlashDeposit){
      _supply(balance);
      _borrow(toRepay);
    } else {
      address _cToken = cToken();
      uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      uint256 repaying = Math.min(balance, borrowed);
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, repaying);
      _repay(repaying);
      _redeem(toRepay);
    }
    balance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeTransfer(bVault, toRepay);
  }

  function _depositNoFlash(uint256 supplied, uint256 borrowed, address _cToken, uint256 _denom, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    {
      uint256 borrowCap = ComptrollerInterface(rewardPool()).borrowCaps(_cToken);
      uint256 totalBorrows = CTokenInterface(_cToken).totalBorrows();
      uint256 borrowAvail;
      if (totalBorrows < borrowCap) {
        borrowAvail = borrowCap.sub(totalBorrows).sub(1);
      } else {
        borrowAvail = 0;
      }
      if (borrowTarget.sub(borrowed) > borrowAvail) {
        borrowTarget = borrowed.add(borrowAvail);
      }
    }
    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget.sub(borrowed);
      uint256 maxBorrow = supplied.mul(collateralFactorNumerator()).div(_denom).sub(borrowed);
      _borrow(Math.min(wantBorrow, maxBorrow));
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      if (underlyingBalance > 0) {
        _supply(underlyingBalance);
      }
      //update parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
      balance = supplied.sub(borrowed);
    }
  }

  function _redeemNoFlash(uint256 amount, uint256 supplied, uint256 borrowed, address _cToken, uint256 _denom, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    }
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed.mul(_denom).div(collateralFactorNumerator());
      uint256 toRepay = borrowed.sub(newBorrowTarget);
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied.sub(requiredCollateral), amount.add(toRepay));
      _redeem(toRedeem);
      // now we can repay our borrowed amount
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      _repay(Math.min(toRepay, underlyingBalance));
      // update the parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    }
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance < amount) {
      uint256 toRedeem = amount.sub(underlyingBalance);
      uint256 balance = supplied.sub(borrowed);
      // redeem the most we can redeem
      _redeem(Math.min(toRedeem, balance));
    }
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function _setCollateralFactorNumerator(uint256 _numerator) internal {
    require(_numerator <= uint(820).mul(factorDenominator()).div(1000), "Collateral factor cannot be this high");
    require(_numerator > borrowTargetFactorNumerator(), "Collateral factor should be higher than borrow target");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
  }

  function _setFactorDenominator(uint256 _denominator) internal {
    setUint256(_FACTORDENOMINATOR_SLOT, _denominator);
  }

  function factorDenominator() public view returns (uint256) {
    return getUint256(_FACTORDENOMINATOR_SLOT);
  }

  function setBorrowTargetFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator < collateralFactorNumerator(), "Target should be lower than collateral limit");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _numerator);
  }

  function borrowTargetFactorNumerator() public view returns (uint256) {
    return getUint256(_BORROWTARGETFACTORNUMERATOR_SLOT);
  }

  function setFold (bool _fold) public onlyGovernance {
    setBoolean(_FOLD_SLOT, _fold);
  }

  function fold() public view returns (bool) {
    return getBoolean(_FOLD_SLOT);
  }

  function _setCToken (address _target) internal {
    setAddress(_CTOKEN_SLOT, _target);
  }

  function cToken() public view returns (address) {
    return getAddress(_CTOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance updateSupplyInTheEnd {
    _finalizeUpgrade();
  }

  receive() external payable {}
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/IVault.sol";
import "../../base/interface/IPotPool.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/lodestar/CTokenInterfaces.sol";
import "../../base/interface/lodestar/ComptrollerInterface.sol";
import "../../base/interface/balancer/IBVault.sol";
import "../../base/interface/weth/IWETH.sol";

contract LodestarFoldStrategyV2HODL is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
  address public constant bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _CTOKEN_SLOT = 0x316ad921d519813e6e41c0e056b79e4395192c2b101f8b61cf5b94999360d568;
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;
  bytes32 internal constant _LODE_VAULT_SLOT = 0xf7566b617fb729f096ab296b2ea55a2d2da7aa17043d001c3834a520a9963a7f;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;

  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;

  bool internal makingFlashDeposit;
  bool internal makingFlashWithdrawal;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_CTOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.cToken")) - 1));
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
    assert(_LODE_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.lodeVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _cToken,
    address _comptroller,
    address _rewardToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    uint256 _factorDenominator,
    bool _fold,
    address _lodeVault,
    address _potPool
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _comptroller,
      _rewardToken,
      harvestMSIG
    );
    _setCToken(_cToken);

    _setFactorDenominator(_factorDenominator);
    require(_collateralFactorNumerator <= factorDenominator(), "CF too high");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _collateralFactorNumerator);
    require(_borrowTargetFactorNumerator < _collateralFactorNumerator, "BF too high");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    
    setBoolean(_FOLD_SLOT, _fold);
    address[] memory markets = new address[](1);
    markets[0] = _cToken;
    ComptrollerInterface(_comptroller).enterMarkets(markets);

    setAddress(_LODE_VAULT_SLOT, _lodeVault);
    setAddress(_POTPOOL_SLOT, _potPool);
  }

  modifier updateSupplyInTheEnd() {
    _;
    address _cToken = cToken();
    // amount we supplied
    suppliedInUnderlying = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    borrowedInUnderlying = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == cToken());
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function _investAllUnderlying() internal onlyNotPausedInvesting updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (!fold()) {
      return;
    }
    _depositWithFlashloan();
  }

  /**
  * Exits Moonwell and transfers everything to the vault.
  */
  function withdrawAllToVault() public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    _withdrawMaximum(true);
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    _withdrawMaximum(false);
  }

  function _withdrawMaximum(bool claim) internal updateSupplyInTheEnd {
    if (claim) {
      _claimRewards();
      _liquidateRewards();
    }
    _redeemMaximum();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amountUnderlying <= balance) {
      IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
      return;
    }
    uint256 toRedeem = amountUnderlying.sub(balance);
    // get some of the underlying
    _redeemPartial(toRedeem);
    // transfer the amount requested (or the amount we have) back to vault()
    IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
    balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      _investAllUnderlying();
    }
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    _claimRewards();
    _liquidateRewards();
    _investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy vUnderlying balance becomes 0.
  */
  function _redeemMaximum() internal {
    _redeemMaximumWithFlashloan();
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function _redeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    _redeemWithFlashloan(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0
      );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Redeem amount");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "NS");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimRewards() internal {
    ComptrollerInterface(rewardPool()).claimComp(address(this));
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateRewards() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    uint256 hodledInRT;
    uint256 totalFee = strategistFeeNumerator().add(platformFeeNumerator()).add(profitSharingNumerator());
    uint256 _feeDenominator = feeDenominator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
        continue;
      }
      if (token == lode) {
        uint256 toHodl = balance.mul(_feeDenominator.sub(totalFee)).div(_feeDenominator);
        _hodlLode(toHodl);
        balance = IERC20(token).balanceOf(address(this));
        hodledInRT = balance.mul(_feeDenominator.sub(totalFee)).div(totalFee);
      }
      if (token != _rewardToken){
        uint256 rtBefore = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(token).safeApprove(_universalLiquidator, 0);
        IERC20(token).safeApprove(_universalLiquidator, balance);
        IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
        uint256 rtGained = IERC20(_rewardToken).balanceOf(address(this)).sub(rtBefore);
        if (token == lode) {
          hodledInRT = rtGained.mul(_feeDenominator.sub(totalFee)).div(totalFee);
        }
      }
    }
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this)).add(hodledInRT);
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance <= 1e10) {
      return;
    }
  
    address _underlying = underlying();
    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  function _hodlLode(uint256 toHodl) internal {
    address _lodeVault = lodeVault();
    address _potPool = potPool();

    IERC20(lode).safeApprove(_lodeVault, 0);
    IERC20(lode).safeApprove(_lodeVault, toHodl);
    IVault(_lodeVault).deposit(toHodl);

    uint256 vaultBalance = IERC20(_lodeVault).balanceOf(address(this));
    IERC20(_lodeVault).safeTransfer(_potPool, vaultBalance);
    IPotPool(_potPool).notifyTargetRewardAmount(_lodeVault, vaultBalance);
  }

  /**
  * Returns the current balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Radiant - debt
    return IERC20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  /**
  * Supplies to Moonwel
  */
  function _supply(uint256 amount) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    if (_underlying == weth) {
      IWETH(weth).withdraw(balance);
      CErc20Interface(_cToken).mint{value: balance}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, balance);
      CErc20Interface(_cToken).mint(balance);
    }
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    // Borrow, check the balance for this contract's address
    CErc20Interface(cToken()).borrow(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _redeem(uint256 amountUnderlying) internal {
    CErc20Interface(cToken()).redeemUnderlying(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _repay(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    address _cToken = cToken();
    if (_underlying == weth) {
      IWETH(weth).withdraw(amountUnderlying);
      CErc20Interface(_cToken).repayBorrow{value: amountUnderlying}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, amountUnderlying);
      CErc20Interface(_cToken).repayBorrow(amountUnderlying);
    }
  }

  function _redeemMaximumWithFlashloan() internal {
    address _cToken = cToken();
    // amount of liquidity in Radiant
    uint256 available = CTokenInterface(_cToken).getCash();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);

    _redeemWithFlashloan(Math.min(available, balance), 0);
    supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    if (supplied > 0) {
      _redeem(supplied);
    }
  }

  function _depositWithFlashloan() internal {
    address _cToken = cToken();
    uint _denom = factorDenominator();
    uint _borrowNum = borrowTargetFactorNumerator();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    uint256 borrowDiff;
    if (borrowed > borrowTarget) {
      _redeemPartial(0);
      borrowDiff = 0;
    } else {
      borrowDiff = borrowTarget.sub(borrowed);
    }

    uint256 totalBorrows = CTokenInterface(_cToken).totalBorrowsCurrent();
    uint256 borrowCap = ComptrollerInterface(rewardPool()).borrowCaps(_cToken);

    if (totalBorrows.add(borrowDiff) > borrowCap) {
      return;
    }

    address _underlying = underlying();
    uint256 balancerBalance = IERC20(_underlying).balanceOf(bVault);

    if (borrowDiff > balancerBalance) {
      _depositNoFlash(supplied, borrowed, _cToken, _denom, _borrowNum);
    } else {
      address[] memory tokens = new address[](1);
      uint256[] memory amounts = new uint256[](1);
      bytes memory userData = abi.encode(0);
      tokens[0] = underlying();
      amounts[0] = borrowDiff;
      makingFlashDeposit = true;
      IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
      makingFlashDeposit = false;
    }
  }

  function _redeemWithFlashloan(uint256 amount, uint256 borrowTargetFactorNumerator) internal {
    address _cToken = cToken();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(borrowTargetFactorNumerator).div(factorDenominator().sub(borrowTargetFactorNumerator));
    }
    uint256 borrowDiff = borrowed.sub(newBorrowTarget);
    address _underlying = underlying();
    uint256 balancerBalance = IERC20(_underlying).balanceOf(bVault);

    if (borrowDiff > balancerBalance) {
      _redeemNoFlash(amount, supplied, borrowed, _cToken, factorDenominator(), borrowTargetFactorNumerator);
    } else {
      address[] memory tokens = new address[](1);
      uint256[] memory amounts = new uint256[](1);
      bytes memory userData = abi.encode(0);
      tokens[0] = underlying();
      amounts[0] = borrowDiff;
      makingFlashWithdrawal = true;
      IBVault(bVault).flashLoan(address(this), tokens, amounts, userData);
      makingFlashWithdrawal = false;
      _redeem(amount);
    }
  }

  function receiveFlashLoan(IERC20[] memory /*tokens*/, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory /*userData*/) external {
    require(msg.sender == bVault);
    require(!makingFlashDeposit || !makingFlashWithdrawal, "Only one can be true");
    require(makingFlashDeposit || makingFlashWithdrawal, "One has to be true");
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    uint256 toRepay = amounts[0].add(feeAmounts[0]);
    if (makingFlashDeposit){
      _supply(balance);
      _borrow(toRepay);
    } else {
      address _cToken = cToken();
      uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      uint256 repaying = Math.min(balance, borrowed);
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, repaying);
      _repay(repaying);
      _redeem(toRepay);
    }
    balance = IERC20(_underlying).balanceOf(address(this));
    IERC20(_underlying).safeTransfer(bVault, toRepay);
  }

  function _depositNoFlash(uint256 supplied, uint256 borrowed, address _cToken, uint256 _denom, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget.sub(borrowed);
      uint256 maxBorrow = supplied.mul(collateralFactorNumerator()).div(_denom).sub(borrowed);
      _borrow(Math.min(wantBorrow, maxBorrow));
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      if (underlyingBalance > 0) {
        _supply(underlyingBalance);
      }
      //update parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
      balance = supplied.sub(borrowed);
    }
  }

  function _redeemNoFlash(uint256 amount, uint256 supplied, uint256 borrowed, address _cToken, uint256 _denom, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    }
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed.mul(_denom).div(collateralFactorNumerator());
      uint256 toRepay = borrowed.sub(newBorrowTarget);
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied.sub(requiredCollateral), amount.add(toRepay));
      _redeem(toRedeem);
      // now we can repay our borrowed amount
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      _repay(Math.min(toRepay, underlyingBalance));
      // update the parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    }
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance < amount) {
      uint256 toRedeem = amount.sub(underlyingBalance);
      uint256 balance = supplied.sub(borrowed);
      // redeem the most we can redeem
      _redeem(Math.min(toRedeem, balance));
    }
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function _setCollateralFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator <= factorDenominator(), "CF too high");
    require(_numerator > borrowTargetFactorNumerator(), "CF too low");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
  }

  function _setFactorDenominator(uint256 _denominator) internal {
    setUint256(_FACTORDENOMINATOR_SLOT, _denominator);
  }

  function factorDenominator() public view returns (uint256) {
    return getUint256(_FACTORDENOMINATOR_SLOT);
  }

  function setBorrowTargetFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator < collateralFactorNumerator(), "BF too high");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _numerator);
  }

  function borrowTargetFactorNumerator() public view returns (uint256) {
    return getUint256(_BORROWTARGETFACTORNUMERATOR_SLOT);
  }

  function setFold (bool _fold) public onlyGovernance {
    setBoolean(_FOLD_SLOT, _fold);
  }

  function fold() public view returns (bool) {
    return getBoolean(_FOLD_SLOT);
  }

  function _setCToken (address _target) internal {
    setAddress(_CTOKEN_SLOT, _target);
  }

  function cToken() public view returns (address) {
    return getAddress(_CTOKEN_SLOT);
  }

  function setLodeVault(address _value) public onlyGovernance {
    setAddress(_LODE_VAULT_SLOT, _value);
  }

  function lodeVault() public view returns (address) {
    return getAddress(_LODE_VAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance updateSupplyInTheEnd {
    _finalizeUpgrade();
  }

  receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2HODL.sol";

contract LodestarFoldStrategyV2HODLMainnet_USDC is LodestarFoldStrategyV2HODL {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address cToken = address(0x4C9aAed3b8c443b4b634D1A189a5e25C604768dE);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2HODL.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      weth,
      800,
      820,
      1000,
      true,
      address(0x710A1AB6Cb8412DE9613ad6c7195453Ce8b5ca71), // LODE vault
      address(0) //potPool (to be set after deployment)
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_ARB is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address cToken = address(0x8991d64fe388fA79A4f7Aa7826E8dA09F0c3C96a);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      680,
      700,
      1000,
      true
    );
    rewardTokens = [lode];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_DAI is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address cToken = address(0x4987782da9a63bC3ABace48648B15546D821c720);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_DPX is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55);
    address cToken = address(0x5d27cFf80dF09f28534bb37d386D43aA60f88e25);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      130,
      150,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_ETH is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address cToken = address(0x2193c45244AF12C280941281c8aa67dD08be0a64);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      780,
      800,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_FRAX is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F);
    address cToken = address(0xD12d43Cdf498e377D3bfa2c6217f05B466E14228);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_GMX is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
    address cToken = address(0x79B6c5e1A7C0aD507E1dB81eC7cF269062BAb4Eb);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      680,
      700,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_USDC is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address cToken = address(0x4C9aAed3b8c443b4b634D1A189a5e25C604768dE);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      800,
      820,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_USDCe is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address cToken = address(0x1ca530f02DD0487cef4943c674342c5aEa08922F);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      800,
      820,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_USDT is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address cToken = address(0x9365181A7df82a1cC578eAE443EFd89f00dbb643);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      680,
      700,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_WBTC is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address cToken = address(0xC37896BF3EE5a2c62Cdbd674035069776f721668);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LodestarFoldStrategyV2.sol";

contract LodestarFoldStrategyV2Mainnet_wstETH is LodestarFoldStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5979D7b546E38E414F7E9822514be443A4800529);
    address cToken = address(0xfECe754D92bd956F681A941Cef4632AB65710495);
    address comptroller = address(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    address lode = address(0xF19547f9ED24aA66b03c3a552D181Ae334FBb8DB);
    address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    LodestarFoldStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      lode,
      730,
      750,
      1000,
      true
    );
    rewardTokens = [lode, arb];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/magpie/IWombatPoolHelper.sol";
import "../../base/interface/magpie/IMasterMagpie.sol";
import "../../base/interface/magpie/IAsset.sol";
import "../../base/interface/magpie/IPool.sol";

contract MagpieStrategy is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant weth =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant harvestMSIG =
        address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
    // address public constant wombatStaking =
    //     address(0x3CbFC97f87f534b42bb58276B7b5dCaD29E57EAc);

    // this would be reset on each upgrade
    address[] public rewardTokens;

    constructor() public BaseUpgradeableStrategy() {}

    function initializeBaseStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool
    ) public initializer {
        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            _rewardPool,
            weth,
            harvestMSIG
        );

        address _lpt = IWombatPoolHelper(rewardPool()).lpToken();
        require(_lpt == _underlying, "Underlying mismatch");
    }

    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    function _rewardPoolBalance() internal view returns (uint256 balance) {
        balance = IWombatPoolHelper(rewardPool()).balance(address(this));
    }

    function _emergencyExitRewardPool() internal {
        uint256 stakedBalance = _rewardPoolBalance();
        if (stakedBalance != 0) {
            _withdrawUnderlyingFromPool(stakedBalance);
        }
    }

    function _withdrawUnderlyingFromPool(uint256 amount) internal {      
        if (amount > 0) {
            IWombatPoolHelper(rewardPool()).withdrawLP(amount, false);
            // _getWomLP();
        }
    }

    function _enterRewardPool() internal {
        address underlying_ = underlying();
        address rewardPool_ = rewardPool();
        uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
        address staking = IWombatPoolHelper(rewardPool_).wombatStaking();
        IERC20(underlying_).safeApprove(staking, 0);
        IERC20(underlying_).safeApprove(staking, entireBalance);
        IWombatPoolHelper(rewardPool_).depositLP(entireBalance);
    }

    function _investAllUnderlying() internal onlyNotPausedInvesting {
        // this check is needed, because most of the SNX reward pools will revert if
        // you try to stake(0).
        if (IERC20(underlying()).balanceOf(address(this)) > 0) {
            _enterRewardPool();
        }
    }

    /*
     *   In case there are some issues discovered about the pool or underlying asset
     *   Governance can exit the pool properly
     *   The function is only used for emergency to exit the pool
     */
    function emergencyExit() public onlyGovernance {
        _emergencyExitRewardPool();
        _setPausedInvesting(true);
    }

    /*
     *   Resumes the ability to invest into the underlying reward pools
     */
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function addRewardToken(address _token) public onlyGovernance {
        rewardTokens.push(_token);
    }

    function _liquidateReward() internal {
        if (!sell()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), false);
            return;
        }

        address _universalLiquidator = universalLiquidator();
        address _rewardToken = rewardToken();

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 rewardBalance = IERC20(token).balanceOf(address(this));

            if (rewardBalance == 0) {
                continue;
            }

            if (token != _rewardToken) {
                IERC20(token).safeApprove(_universalLiquidator, 0);
                IERC20(token).safeApprove(_universalLiquidator, rewardBalance);
                IUniversalLiquidator(_universalLiquidator).swap(
                    token,
                    _rewardToken,
                    rewardBalance,
                    1,
                    address(this)
                );
            }
        }

        uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        _notifyProfitInRewardToken(_rewardToken, rewardBalance);
        uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(
            address(this)
        );

        if (remainingRewardBalance == 0) {
            return;
        }

        address depositToken = IWombatPoolHelper(rewardPool()).depositToken();

        if (depositToken != _rewardToken) {
            IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
            IERC20(_rewardToken).safeApprove(
                _universalLiquidator,
                remainingRewardBalance
            );
            IUniversalLiquidator(_universalLiquidator).swap(
                _rewardToken,
                depositToken,
                remainingRewardBalance,
                1,
                address(this)
            );
        }

        _getWomLP();
    }

    function _getWomLP() internal {
        address _underlying = underlying();
        address ulToken = IAsset(_underlying).underlyingToken();
        uint256 balance = IERC20(ulToken).balanceOf(address(this));
        if (balance == 0) {
            return;
        }
        address pool = IAsset(_underlying).pool();
        IERC20(ulToken).safeApprove(pool, 0);
        IERC20(ulToken).safeApprove(pool, balance);
        IPool(pool).deposit(
            ulToken,
            balance,
            1,
            address(this),
            block.timestamp,
            false
        );
    }

    function _claimRewards() internal {
        address[] memory _stakingTokens = new address[](1);
        _stakingTokens[0] = IWombatPoolHelper(rewardPool()).stakingToken();

        address masterMagpie_ = IWombatPoolHelper(rewardPool()).masterMagpie();
        IWombatPoolHelper(rewardPool()).harvest();
        IMasterMagpie(masterMagpie_).multiclaim(_stakingTokens);
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawAllToVault() public restricted {
        _withdrawUnderlyingFromPool(_rewardPoolBalance());
        _claimRewards();
        _liquidateReward();
        address underlying_ = underlying();

        IERC20(underlying_).safeTransfer(
            vault(),
            IERC20(underlying_).balanceOf(address(this))
        );
    }

    /*
     *   Withdraws all the asset to the vault
     */
    function withdrawToVault(uint256 _amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        address underlying_ = underlying();
        uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

        if (_amount > entireBalance) {
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = _amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
            _withdrawUnderlyingFromPool(toWithdraw);
        }

        IERC20(underlying_).safeTransfer(vault(), _amount);
    }

    /*
     *   Note that we currently do not have a mechanism here to include the
     *   amount of reward that is accrued.
     */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IERC20(underlying()).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return
            _rewardPoolBalance().add(
                IERC20(underlying()).balanceOf(address(this))
            );
    }

    /*
     *   Governance or Controller can claim coins that are somehow transferred into the contract
     *   Note that they cannot come in take away coins that are used and defined in the strategy itself
     */
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(
            !unsalvagableTokens(token),
            "token is defined as not salvagable"
        );
        IERC20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        _claimRewards();
        _liquidateReward();
        _investAllUnderlying();
    }

    /**
     * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
     * simplest possible way.
     */
    function setSell(bool s) public onlyGovernance {
        _setSell(s);
    }

    /**
     * Sets the minimum amount of CRV needed to trigger a sale.
     */
    function setSellFloor(uint256 floor) public onlyGovernance {
        _setSellFloor(floor);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_DAI is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0Fa7b744F18D8E8c3D61B64b110F25CC27E73055); // DAI LP address
    address rewardPool = address(0x224c51A5FDA5bfF752F06112a7e2961Dc9A26703); // DAI WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_ETH is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xe62880CC6872c9E9Fb1DDd73f400850fdaBE798D); // WETH LP address
    address rewardPool = address(0xE3e45d55c7291AEE758DFcad3A508BF1b43A8bA4); // WETH WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_USDC_E is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x2977b0B54a76c2b56D32cef19f8ea83Cc766cFD9); // USDC.e LP address
    address rewardPool = address(0x1aFE333bA31E6966E33782B0D19998E89117387F); // USDC.e WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_USDC is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE5232c2837204ee66952f365f104C09140FB2E43); // USDC LP address
    address rewardPool = address(0x58BB9749e35E15Ca016AD624EfB5297826310ea1); // USDC WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_USDT is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x85cEBD962861be410a777755dFa06914de6af003); // USDT address
    address rewardPool = address(0xBB2A70A9fF3f7b151E14bEF5052B49DB4FdFf806); // USDT WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./MagpieStrategy.sol";

contract MagpieStrategyMainnet_WOM is MagpieStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x59d8DCA660b71Ba97a16f781A40809a0fC350769); // WOM LP address
    address rewardPool = address(0xB979524b2e5983cE9f27EABa8c176eB684f2789A); // WOM WombatPoolHelper
    address wom = address(0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96);
    address mgp = address(0xa61F74247455A40b01b0559ff6274441FAfa22A3);
    MagpieStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      rewardPool
    );
    rewardTokens = [wom, mgp];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IiPoison {
    function depositPoison(uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../base/interface/IVault.sol";
import "../../base/PotPool.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/masterchef/IMasterChef.sol";
import "./interface/IiPoison.sol";

contract PoisonStrategyHodl is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
  address public constant sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;
  bytes32 internal constant _HODLVAULT_SLOT = 0xc26d330f887c749cb38ae7c37873ff08ac4bba7aec9113c82d48a0cf6cc145f2;
  bytes32 internal constant _POTPOOL_SLOT = 0x7f4b50847e7d7a4da6a6ea36bfb188c77e9f093697337eb9a876744f926dd014;
  bytes32 internal constant _HODLTOKEN_SLOT = 0x3ed76c1ddd44f6251c0d268c9f5a0af4a2227e90ab146d70e6b186ad3fc7e183;


  // this would be reset on each upgrade
  mapping(address => address[]) public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  mapping (address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
    assert(_HODLVAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlVault")) - 1));
    assert(_POTPOOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.potPool")) - 1));
    assert(_HODLTOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolId,
    address _hodlToken,
    address _hodlVault,
    address _potPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    (address _lpt,,,) = IMasterChef(_rewardPool).poolInfo(_poolId);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolId);
    setAddress(_HODLVAULT_SLOT, _hodlVault);
    setAddress(_POTPOOL_SLOT, _potPool);
    setHodlToken(_hodlToken);
  }

  /*///////////////////////////////////////////////////////////////
                  STORAGE SETTER AND GETTER
  //////////////////////////////////////////////////////////////*/

  function setHodlVault(address _value) public onlyGovernance {
    require(hodlVault() == address(0), "Hodl vault already set");
    setAddress(_HODLVAULT_SLOT, _value);
  }

  function hodlVault() public view returns (address) {
    return getAddress(_HODLVAULT_SLOT);
  }

  function setPotPool(address _value) public onlyGovernance {
    require(potPool() == address(0), "PotPool already set");
    setAddress(_POTPOOL_SLOT, _value);
  }

  function potPool() public view returns (address) {
    return getAddress(_POTPOOL_SLOT);
  }

  function setHodlToken(address _value) internal {
    setAddress(_HODLTOKEN_SLOT, _value);
  }

  function hodlToken() public view returns (address) {
    return getAddress(_HODLTOKEN_SLOT);
  }

  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == poison, "Path should end with Poison token");
    require(_route[0] == weth, "Path should start with WETH");
    WETH2deposit[_route[_route.length-1]] = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    require(_route[0] == poison, "Path should start with Poison token");
    reward2WETH[_route[0]] = _route;
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  /*///////////////////////////////////////////////////////////////
                  PROXY - FINALIZE UPGRADE
  //////////////////////////////////////////////////////////////*/

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL HELPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance, ) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function _emergencyExitRewardPool() internal {
    IMasterChef(rewardPool()).emergencyWithdraw(poolId());
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    IMasterChef(rewardPool()).withdraw(poolId(), amount);
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IMasterChef(rewardPool_).deposit(poolId(), entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }
  
  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 3000;
    }
  }

  function uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  // We Hodl all the rewards
  function _hodlAndNotify() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    uint256 poisonBalance = IERC20(poison).balanceOf(address(this));
    if (poisonBalance == 0) {
      return;
    }

    uniV3Swap(poisonBalance, 1, reward2WETH[poison]);

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    uniV3Swap(remainingRewardBalance, 1, WETH2deposit[poison]);
    poisonBalance = IERC20(poison).balanceOf(address(this));
    if (poisonBalance > 0) {
      address _hodlToken = hodlToken();
      IERC20(poison).safeApprove(_hodlToken, 0);
      IERC20(poison).safeApprove(_hodlToken, poisonBalance);
      IiPoison(_hodlToken).depositPoison(poisonBalance);
    }

    address _hodlVault = hodlVault();
    address _hodlToken = hodlToken();
    address _potPool = potPool();
    uint256 hodlBalance = IERC20(_hodlToken).balanceOf(address(this));

    IERC20(_hodlToken).safeApprove(_hodlVault, 0);
    IERC20(_hodlToken).safeApprove(_hodlVault, hodlBalance);

    IVault(_hodlVault).deposit(hodlBalance);

    uint256 fRewardBalance = IERC20(_hodlVault).balanceOf(address(this));
    IERC20(_hodlVault).safeTransfer(_potPool, fRewardBalance);

    PotPool(_potPool).notifyTargetRewardAmount(_hodlVault, fRewardBalance);
  }

  /*///////////////////////////////////////////////////////////////
                  PUBLIC EMERGENCY FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  /*///////////////////////////////////////////////////////////////
                  ISTRATEGY FUNCTION IMPLEMENTATIONS
  //////////////////////////////////////////////////////////////*/

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _hodlAndNotify();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IMasterChef(rewardPool()).deposit(poolId(), 0);
    _hodlAndNotify();
    _investAllUnderlying();
  }
  
  function depositArbCheck() public pure returns(bool) {
    return true;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyHodl.sol";

contract PoisonStrategyHodlMainnet_pGOLD is PoisonStrategyHodl {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xF602A45812040D90B202355bdc05438918CD3FE3);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address iPoison = address(0xDA016d31f2B52C73D7c1956E955ae8A507b305bB);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyHodl.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      0,
      iPoison,
      address(0x9F65E93209EFAe76a716ffF7d40089d2aA1b9ad1),  //iPoison vault
      address(0)
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[poison] = [weth, usdc, poison];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyHodl.sol";

contract PoisonStrategyHodlMainnet_pSLVR is PoisonStrategyHodl {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x867B1Cd06039Eb70385788a048B57F6d4fDC5Dbb);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address iPoison = address(0xDA016d31f2B52C73D7c1956E955ae8A507b305bB);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyHodl.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      1,
      iPoison,
      address(0x9F65E93209EFAe76a716ffF7d40089d2aA1b9ad1),  //iPoison vault
      address(0)
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[poison] = [weth, usdc, poison];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/masterchef/IMasterChef.sol";
import "./interface/IiPoison.sol";

contract PoisonStrategyiPoison is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  mapping(address => address[]) public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  mapping (address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolId
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    (address _lpt,,,) = IMasterChef(_rewardPool).poolInfo(_poolId);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolId);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance, ) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function _emergencyExitRewardPool() internal {
    IMasterChef(rewardPool()).emergencyWithdraw(poolId());
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    IMasterChef(rewardPool()).withdraw(poolId(), amount);
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IMasterChef(rewardPool_).deposit(poolId(), entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == poison, "Path should end with Poison token");
    require(_route[0] == weth, "Path should start with WETH");
    WETH2deposit[_route[_route.length-1]] = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    require(_route[0] == poison, "Path should start with Poison token");
    reward2WETH[_route[0]] = _route;
  }
  
  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 3000;
    }
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  function uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    uint256 poisonBalance = IERC20(poison).balanceOf(address(this));

    if (poisonBalance == 0) {
      return;
    }

    uniV3Swap(poisonBalance, 1, reward2WETH[poison]);

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    uniV3Swap(remainingRewardBalance, 1, WETH2deposit[poison]);
    poisonBalance = IERC20(poison).balanceOf(address(this));
    if (poisonBalance > 0) {
      address _underlying = underlying();
      IERC20(poison).safeApprove(_underlying, 0);
      IERC20(poison).safeApprove(_underlying, poisonBalance);
      IiPoison(_underlying).depositPoison(poisonBalance);
    }
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IMasterChef(rewardPool()).deposit(poolId(), 0);
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyiPoison.sol";

contract PoisonStrategyiPoisonMainnet_iPoison is PoisonStrategyiPoison {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xDA016d31f2B52C73D7c1956E955ae8A507b305bB);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyiPoison.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      4
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[poison] = [weth, usdc, poison];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/masterchef/IMasterChef.sol";

contract PoisonStrategyLP is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
  address public constant sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  mapping(address => address[]) public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  mapping (address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolId
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    (address _lpt,,,) = IMasterChef(_rewardPool).poolInfo(_poolId);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolId);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance, ) = IMasterChef(rewardPool()).userInfo(poolId(), address(this));
  }

  function _emergencyExitRewardPool() internal {
    IMasterChef(rewardPool()).emergencyWithdraw(poolId());
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    IMasterChef(rewardPool()).withdraw(poolId(), amount);
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IMasterChef(rewardPool_).deposit(poolId(), entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    address _underlying = underlying();
    address token0 = IUniswapV2Pair(_underlying).token0();
    address token1 = IUniswapV2Pair(_underlying).token1();
    require(_route[_route.length-1] == token0 || _route[_route.length-1] == token1, "Path should end with a token in the LP");
    require(_route[0] == weth, "Path should start with WETH");
    WETH2deposit[_route[_route.length-1]] = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    require(_route[0] == poison, "Path should start with Poison token");
    reward2WETH[_route[0]] = _route;
  }

  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 3000;
    }
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  function uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    uint256 poisonBalance = IERC20(poison).balanceOf(address(this));

    if (poisonBalance == 0) {
      return;
    }

    uniV3Swap(poisonBalance, 1, reward2WETH[poison]);

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    IERC20(_rewardToken).safeApprove(sushiRouter, 0);
    IERC20(_rewardToken).safeApprove(sushiRouter, remainingRewardBalance);

    address _underlying = underlying();

    address token0 = IUniswapV2Pair(_underlying).token0();
    address token1 = IUniswapV2Pair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    uint256 token0Amount;
    if (WETH2deposit[token0].length > 1) {
      IUniswapV2Router02(sushiRouter).swapExactTokensForTokens(
        toToken0,
        1,
        WETH2deposit[token0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (WETH2deposit[token1].length > 1) {
      IUniswapV2Router02(sushiRouter).swapExactTokensForTokens(
        toToken1,
        1,
        WETH2deposit[token1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    IERC20(token0).safeApprove(sushiRouter, 0);
    IERC20(token0).safeApprove(sushiRouter, token0Amount);

    IERC20(token1).safeApprove(sushiRouter, 0);
    IERC20(token1).safeApprove(sushiRouter, token1Amount);

    IUniswapV2Router02(sushiRouter).addLiquidity(
      token0,
      token1,
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IMasterChef(rewardPool()).deposit(poolId(), 0);
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pAAPL_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x410B7C383a0dF3c56C63E44b2e4Cb752A1350b32);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pAapl = address(0xf8f636BB3Be1fEEB979E1ea281389b49CF3a6853);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      11
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pAapl] = [weth, usdc, pAapl];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pAMZN_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x9B915D6eA56a7aBf03A96615AC76dFF2fD9dd60c);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pAmzn = address(0xE656165d39419C03D588515c835d109E19221e1E);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      10
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pAmzn] = [weth, usdc, pAmzn];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pGOLD_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xB5d8DF1D117C4E92dD481FD3E4c1C5857767f9fe);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pGold = address(0xF602A45812040D90B202355bdc05438918CD3FE3);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      3
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pGold] = [weth, usdc, pGold];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pOIL_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xb63E561193FAbD5482761c7aCC0711D7B784f845);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pOil = address(0xb816688E4B70C9076BD87d45b5309F205ec2cf5f);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      5
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pOil] = [weth, usdc, pOil];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pSLVR_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5f586464c9DF5cA0C685798B4Fa092136f087BEc);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pSlvr = address(0x867B1Cd06039Eb70385788a048B57F6d4fDC5Dbb);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      6
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pSlvr] = [weth, usdc, pSlvr];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PoisonStrategyLP.sol";

contract PoisonStrategyLPMainnet_pTSLA_USDC is PoisonStrategyLP {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x00468cd187492080C66A96F28581881fC306f851);
    address poison = address(0x31C91D8Fb96BfF40955DD2dbc909B36E8b104Dde);
    address pTsla = address(0x8DCD3393a6e48E898A60e05baeC0d568df128F89);
    address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address masterChef = address(0x1b1Eb8CCC251deb3abD971B12bD8f34ac2A9a608);
    PoisonStrategyLP.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      8
    );
    reward2WETH[poison] = [poison, usdc, weth];
    storedPairFee[usdc][weth] = 500;
    storedPairFee[poison][usdc] = 3000;
    WETH2deposit[pTsla] = [weth, usdc, pTsla];
    WETH2deposit[usdc] = [weth, usdc];
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./RadiantInteractorInitializable.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/uniswap/IUniswapV3Router.sol";
import "../../base/interface/balancer/IBVault.sol";

import "hardhat/console.sol";

contract RadiantFoldStrategy is BaseUpgradeableStrategy, RadiantInteractorInitializable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant bVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  address public constant uniV3Router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;

  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;

  address[] public WETH2underlying;
  mapping(address => address[]) public reward2WETH;
  mapping(address => mapping(address => bytes32)) public poolIds;
  address[] public rewardTokens;
  mapping(address => mapping(address => uint24)) public storedPairFee;

  constructor() public BaseUpgradeableStrategy() {
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _atoken,
    address _lendingPool,
    address _incentivesController,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    uint256 _factorDenominator,
    bool _fold
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _incentivesController,
      weth,
      harvestMSIG
    );

    RadiantInteractorInitializable.initialize(_underlying, _atoken, _lendingPool);

    require(IVault(_vault).underlying() == _underlying, "vault does not support underlying");
    _setFactorDenominator(_factorDenominator);
    _setCollateralFactorNumerator(_collateralFactorNumerator);
    require(_borrowTargetFactorNumerator < collateralFactorNumerator(), "Target should be lower than collateral limit");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    setBoolean(_FOLD_SLOT, _fold);
  }

  modifier updateSupplyInTheEnd() {
    _;
    // amount we supplied
    suppliedInUnderlying = IAToken(aToken()).balanceOf(address(this));
    console.log("SUPPLIED:", suppliedInUnderlying);
    // amount we borrowed
    borrowedInUnderlying = getBorrowBalance();
    console.log("BORROWED:", borrowedInUnderlying);
    if(suppliedInUnderlying != 0){
      console.log("LTV:     ", borrowedInUnderlying.mul(100000).div(suppliedInUnderlying));
    }
  }

  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == aToken());
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function investAllUnderlying() public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    address _aToken = aToken();
    uint _denom = factorDenominator();
    uint _borrowNum = borrowTargetFactorNumerator();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (!fold()) {
      return;
    }
    // amount we supplied
    uint256 supplied = IAToken(_aToken).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = getBorrowBalance();
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget.sub(borrowed);
      uint256 maxBorrow = supplied.mul(collateralFactorNumerator()).div(_denom).sub(borrowed);
      _borrow(Math.min(wantBorrow, maxBorrow));
      underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      if (underlyingBalance > 0) {
        _supply(underlyingBalance);
      }
      //update parameters
      supplied = IAToken(_aToken).balanceOf(address(this));
      borrowed = getBorrowBalance();
      balance = supplied.sub(borrowed);
    }
  }

  /**
  * Exits Radiant and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    withdrawMaximum(true);
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    withdrawMaximum(false);
  }

  function withdrawMaximum(bool claim) internal updateSupplyInTheEnd {
    if (claim) {
      claimRewards();
      liquidateRewards();
    }
    redeemMaximum();
  }

  function withdrawToVault(uint256 amountUnderlying) external restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amountUnderlying <= balance) {
      IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
      return;
    }
    uint256 toRedeem = amountUnderlying.sub(balance);
    // get some of the underlying
    mustRedeemPartial(toRedeem);
    // transfer the amount requested (or the amount we have) back to vault()
    IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
    balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      investAllUnderlying();
    }
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    claimRewards();
    liquidateRewards();
    investAllUnderlying();
  }

  /**
  * Redeems maximum that can be redeemed from Venus.
  * Redeem the minimum of the underlying we own, and the underlying that the vToken can
  * immediately retrieve. Ensures that `redeemMaximum` doesn't fail silently.
  *
  * DOES NOT ensure that the strategy vUnderlying balance becomes 0.
  */
  function redeemMaximum() internal {
    redeemMaximumWithLoan(
      collateralFactorNumerator(),
      factorDenominator()
    );
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function mustRedeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    redeemPartialWithLoan(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0,
      collateralFactorNumerator(),
      factorDenominator()
      );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function uniV3PairFee(address sellToken, address buyToken) public view returns(uint24 fee) {
    if(storedPairFee[sellToken][buyToken] != 0) {
      return storedPairFee[sellToken][buyToken];
    } else if(storedPairFee[buyToken][sellToken] != 0) {
      return storedPairFee[buyToken][sellToken];
    } else {
      return 500;
    }
  }

  function setPairFee(address token0, address token1, uint24 fee) public onlyGovernance {
    storedPairFee[token0][token1] = fee;
  }

  function _uniV3Swap(
    uint256 amountIn,
    uint256 minAmountOut,
    address[] memory pathWithoutFee
  ) internal {
    address currentSellToken = pathWithoutFee[0];

    IERC20(currentSellToken).safeIncreaseAllowance(uniV3Router, amountIn);

    bytes memory pathWithFee = abi.encodePacked(currentSellToken);
    for(uint256 i=1; i < pathWithoutFee.length; i++) {
      address currentBuyToken = pathWithoutFee[i];
      pathWithFee = abi.encodePacked(
        pathWithFee,
        uniV3PairFee(currentSellToken, currentBuyToken),
        currentBuyToken);
      currentSellToken = currentBuyToken;
    }

    IUniswapV3Router.ExactInputParams memory param = IUniswapV3Router.ExactInputParams({
      path: pathWithFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    IUniswapV3Router(uniV3Router).exactInput(param);
  }

  function _approveIfNeed(address token, address spender, uint256 amount) internal {
    uint256 allowance = IERC20(token).allowance(address(this), spender);
    if (amount > allowance) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, amount);
    }
  }

  function _balancerSwap(
    address sellToken,
    address buyToken,
    bytes32 poolId,
    uint256 amountIn,
    uint256 minAmountOut
  ) internal {
    IBVault.SingleSwap memory singleSwap;
    IBVault.SwapKind swapKind = IBVault.SwapKind.GIVEN_IN;

    singleSwap.poolId = poolId;
    singleSwap.kind = swapKind;
    singleSwap.assetIn = IAsset(sellToken);
    singleSwap.assetOut = IAsset(buyToken);
    singleSwap.amount = amountIn;
    singleSwap.userData = abi.encode(0);

    IBVault.FundManagement memory funds;
    funds.sender = address(this);
    funds.fromInternalBalance = false;
    funds.recipient = payable(address(this));
    funds.toInternalBalance = false;

    _approveIfNeed(sellToken, bVault, amountIn);
    IBVault(bVault).swap(singleSwap, funds, minAmountOut, block.timestamp);
  }

  function claimRewards() internal {

  }

  function liquidateRewards() internal {
    address _rewardToken = rewardToken();
    address _underlying = underlying();
    uint256 rewardBalanceBefore = 0;

    if (_underlying == _rewardToken) {
      rewardBalanceBefore = IERC20(_rewardToken).balanceOf(address(this));
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if(reward2WETH[token].length < 2 || rewardBalance == 0) {
        continue;
      }

      if(poolIds[token][weth] != bytes32(0)){
        _balancerSwap(token, weth, poolIds[token][weth], rewardBalance, 1);
      } else {
        _uniV3Swap(rewardBalance, 1, reward2WETH[token]);
      }
    }

    uint256 rewardBalanceAfter = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalanceAfter.sub(rewardBalanceBefore));
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    // no liquidation needed when underlying is reward token
    if (_underlying != _rewardToken) {
      _uniV3Swap(remainingRewardBalance, 1, WETH2underlying);
    }
  }

  /**
  * Returns the current balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // underlying in this strategy + underlying redeemable from Radiant - debt
    return IERC20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function _setCollateralFactorNumerator(uint256 _numerator) internal {
    require(_numerator <= uint(800).mul(factorDenominator()).div(1000), "Collateral factor cannot be this high");
    require(_numerator > borrowTargetFactorNumerator(), "Collateral factor should be higher than borrow target");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
  }

  function _setFactorDenominator(uint256 _denominator) internal {
    setUint256(_FACTORDENOMINATOR_SLOT, _denominator);
  }

  function factorDenominator() public view returns (uint256) {
    return getUint256(_FACTORDENOMINATOR_SLOT);
  }

  function setBorrowTargetFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator < collateralFactorNumerator(), "Target should be lower than collateral limit");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _numerator);
  }

  function borrowTargetFactorNumerator() public view returns (uint256) {
    return getUint256(_BORROWTARGETFACTORNUMERATOR_SLOT);
  }

  function setFold (bool _fold) public onlyGovernance {
    setBoolean(_FOLD_SLOT, _fold);
  }

  function fold() public view returns (bool) {
    return getBoolean(_FOLD_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance updateSupplyInTheEnd {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./RadiantFoldStrategy.sol";

contract RadiantFoldStrategyMainnet_USDC is RadiantFoldStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address aToken = address(0x48a29E756CC1C097388f3B2f3b570ED270423b3d);
    address lendingPool = address(0xF4B1486DD74D07706052A33d31d7c0AAFD0659E1);
    address incentivesController = address(0xebC85d44cefb1293707b11f707bd3CEc34B4D5fA);
    address rdnt = address(0x3082CC23568eA640225c2467653dB90e9250AaA0);
    RadiantFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      lendingPool,
      incentivesController,
      750,
      800,
      1000,
      true
    );
    rewardTokens = [rdnt];
    reward2WETH[rdnt] = [rdnt, weth];
    WETH2underlying = [weth, underlying];
    poolIds[rdnt][weth] = bytes32(0x32df62dc3aed2cd6224193052ce665dc181658410002000000000000000003bd);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/upgradability/ReentrancyGuardUpgradeable.sol";
import "../../base/interface/aave/IAToken.sol";
import "../../base/interface/aave/IVariableDebtToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract RadiantInteractorInitializable is Initializable, ReentrancyGuardUpgradeable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 internal constant _INTERACTOR_UNDERLYING_SLOT = 0x3e9f9f7ea72bae20746fd93eefa9f38d4f124c4ea7b6f6d6641f8cca268c5697;
  bytes32 internal constant _ATOKEN_SLOT = 0x2f43c3ecf8ac46d09de41084e1373bbb359106625ff3f6be5c67006874596c56;
  bytes32 internal constant _LENDING_POOL_SLOT = 0x16629dc35139b48d2fb13a69b9726e401b86938e76df6b9c2ecb3b618e205532;

  constructor() public {
    assert(_INTERACTOR_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.interactorStorage.underlying")) - 1));
    assert(_ATOKEN_SLOT == bytes32(uint256(keccak256("eip1967.interactorStorage.atoken")) - 1));
    assert(_LENDING_POOL_SLOT == bytes32(uint256(keccak256("eip1967.interactorStorage.lendingPool")) - 1));
  }

  function initialize(
    address _underlying,
    address _atoken,
    address _lendingPool
  ) public initializer {
    ReentrancyGuardUpgradeable.initialize();

    _setLendingPool(_lendingPool);
    _setInteractorUnderlying(_underlying);
    _setAToken(_atoken);
  }

  function getBorrowBalance() public view returns(uint256) {
    address _underlying = intUnderlying();
    DataTypes.ReserveData memory reserveData = ILendingPool(lendingPool()).getReserveData(_underlying);
    address debtToken = reserveData.variableDebtTokenAddress;
    uint256 borrowed = IVariableDebtToken(debtToken).balanceOf(address(this));
    return borrowed;
  }

  /**
  * Supplies to Radiant
  */
  function _supply(uint256 amount) internal returns(uint256) {
    address _underlying = intUnderlying();
    address _lendingPool = lendingPool();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    IERC20(_underlying).safeApprove(_lendingPool, 0);
    IERC20(_underlying).safeApprove(_lendingPool, balance);
    ILendingPool(_lendingPool).deposit(_underlying, balance, address(this), 0);
    return balance;
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    // Borrow, check the balance for this contract's address
    ILendingPool(lendingPool()).borrow(intUnderlying(), amountUnderlying, 2, 0, address(this));
  }

  /**
  * Repays a loan
  */
  function _repay(uint256 amountUnderlying) internal {
    address _underlying = intUnderlying();
    address _lendingPool = lendingPool();
    IERC20(_underlying).safeApprove(_lendingPool, 0);
    IERC20(_underlying).safeApprove(_lendingPool, amountUnderlying);
    ILendingPool(_lendingPool).repay(_underlying, amountUnderlying, 2, address(this));
  }

  /**
  * Withdraw liquidity in underlying
  */
  function _withdrawUnderlying(uint256 amountUnderlying) internal {
    if (amountUnderlying > 0) {
      ILendingPool(lendingPool()).withdraw(intUnderlying(), amountUnderlying, address(this));
    }
  }

  function redeemMaximumWithLoan(uint256 collateralFactorNumerator, uint256 collateralFactorDenominator) internal {
    address _underlying = intUnderlying();
    address _aToken = aToken();
    // amount of liquidity in Radiant
    uint256 available = IERC20(_underlying).balanceOf(_aToken);
    // amount we supplied
    uint256 supplied = IAToken(_aToken).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = getBorrowBalance();
    uint256 balance = supplied.sub(borrowed);

    redeemPartialWithLoan(Math.min(available, balance), 0, collateralFactorNumerator, collateralFactorDenominator);
    supplied = IAToken(_aToken).balanceOf(address(this));
    if (supplied > 0) {
    available = IERC20(_underlying).balanceOf(_aToken);
      _withdrawUnderlying(Math.min(available, supplied));
    }
  }

  function redeemPartialWithLoan(
    uint256 amount,
    uint256 borrowTargetFactorNumerator,
    uint256 collateralFactorNumerator,
    uint256 factorDenominator) internal {

    address _underlying = intUnderlying();
    address _aToken = aToken();
    // amount we supplied
    uint256 supplied = IAToken(_aToken).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = getBorrowBalance();
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(borrowTargetFactorNumerator).div(factorDenominator.sub(borrowTargetFactorNumerator));
    }
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed.mul(factorDenominator).div(collateralFactorNumerator);
      uint256 toRepay = borrowed.sub(newBorrowTarget);
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied.sub(requiredCollateral), amount.add(toRepay));
      _withdrawUnderlying(toRedeem);
      // now we can repay our borrowed amount
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      _repay(Math.min(toRepay, underlyingBalance));
      // update the parameters
      borrowed = getBorrowBalance();
      supplied = IAToken(_aToken).balanceOf(address(this));
    }
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance < amount) {
      uint256 toRedeem = amount.sub(underlyingBalance);
      uint256 balance = supplied.sub(borrowed);
      // redeem the most we can redeem
      _withdrawUnderlying(Math.min(toRedeem, balance));
    }
  }

  function _setInteractorUnderlying(address _address) internal {
    _setAddress(_INTERACTOR_UNDERLYING_SLOT, _address);
  }

  function intUnderlying() internal virtual view returns (address) {
    return _getAddress(_INTERACTOR_UNDERLYING_SLOT);
  }

  function _setAToken(address _address) internal {
    _setAddress(_ATOKEN_SLOT, _address);
  }

  function aToken() public virtual view returns (address) {
    return _getAddress(_ATOKEN_SLOT);
  }

  function _setLendingPool(address _address) internal {
    _setAddress(_LENDING_POOL_SLOT, _address);
  }

  function lendingPool() public virtual view returns (address) {
    return _getAddress(_LENDING_POOL_SLOT);
  }

  function _setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function _getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/solidLizard/ILizardRouter.sol";
import "../../base/interface/solidLizard/IGauge.sol";
import "../../base/interface/solidLizard/ILizardPair.sol";

contract SolidLizardStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant lizardRouter = address(0xF26515D5482e2C2FD237149bF6A653dA4794b3D0);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // this would be reset on each upgrade
  address[] public rewardTokens;
  mapping(address => ILizardRouter.Route[]) public reward2WETH;
  mapping(address => ILizardRouter.Route[]) public lpLiquidationPath;

  
  constructor() public BaseUpgradeableStrategy() {}

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
      balance = IGauge(rewardPool()).balanceOf(address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    address rewardPool_ = rewardPool();
    IGauge(rewardPool_).withdraw(
      Math.min(IGauge(rewardPool_).balanceOf(address(this)), amount)
    );
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IGauge(rewardPool_).deposit(entireBalance, 0);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setRewardLiquidationPath(address _token, ILizardRouter.Route[] memory _route) public onlyGovernance {
    require(_route[_route.length-1].to == weth, "Path should end with WETH");
    require(_route[0].from == _token, "Path should start with rewardToken");

    delete reward2WETH[_token];
    for(uint256 i = 0; i < _route.length; i++) {
      reward2WETH[_token].push(_route[i]);
    }
  }

  function setLpLiquidationPath(address _token, ILizardRouter.Route[] memory _route) public onlyGovernance {
    require(_route[_route.length-1].to == _token, "Path should end with lp token");
    require(_route[0].from == weth, "Path should start with WETH");

    delete lpLiquidationPath[_token];
    for(uint256 i = 0; i < _route.length; i++) {
      lpLiquidationPath[_token].push(_route[i]);
    }
  }

  function addRewardToken(address _token, ILizardRouter.Route[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_token, _path2WETH);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (rewardBalance == 0) {
        continue;
      }
      if (reward2WETH[token].length == 0) {
        continue;
      }

      IERC20(token).safeApprove(lizardRouter, 0);
      IERC20(token).safeApprove(lizardRouter, rewardBalance);
  
      ILizardRouter(lizardRouter).swapExactTokensForTokens(
        rewardBalance,
        1,
        reward2WETH[token],
        address(this),
        block.timestamp
      );
    }

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _underlying = underlying();

    address token0 = ILizardPair(_underlying).token0();
    address token1 = ILizardPair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    IERC20(_rewardToken).safeApprove(lizardRouter, 0);
    IERC20(_rewardToken).safeApprove(lizardRouter, remainingRewardBalance);

    uint256 token0Amount;
    if (lpLiquidationPath[token0].length > 0) {
      ILizardRouter(lizardRouter).swapExactTokensForTokens(
        toToken0,
        1,
        lpLiquidationPath[token0],
        address(this),
        block.timestamp
      );
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is weth itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (lpLiquidationPath[token1].length > 0) {
      ILizardRouter(lizardRouter).swapExactTokensForTokens(
        toToken1,
        1,
        lpLiquidationPath[token1],
        address(this),
        block.timestamp
      );
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    // provide token1 and token2 to Lizard
    IERC20(token0).safeApprove(lizardRouter, 0);
    IERC20(token0).safeApprove(lizardRouter, token0Amount);

    IERC20(token1).safeApprove(lizardRouter, 0);
    IERC20(token1).safeApprove(lizardRouter, token1Amount);

    ILizardRouter(lizardRouter).addLiquidity(
      token0,
      token1,
      ILizardPair(_underlying).stable(), 
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IGauge(rewardPool()).getReward(address(this), rewardTokens);
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {} // this is needed for the receiving Matic
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_agEUR_USDC is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0x5cd95bc186E41419e6B48a0153833C8105781292);
        address gauge = address(0x12981565263628164cDFA32290EBCcdbd7e5cCa4);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        address agEUR = address(0xFA5Ed56A203466CbBC2430a43c66b9D8723528E7);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[usdc].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[agEUR].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[agEUR].push(
            ILizardRouter.Route({
                from: usdc,
                to: agEUR,
                stable: false
            })
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_ARB_USDC is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0x9cB911Cbb270cAE0d132689cE11c2c52aB2DedBC);
        address gauge = address(0xc43e8F9AE4c1Ef6b8b63CBFEfE8Fe90d375fe11C);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[usdc].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[arb].push(
            ILizardRouter.Route({
                from: weth,
                to: arb,
                stable: false
            })
        );
      
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_ARB_wETH is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0xCeD06c9330B02C378C31c7b12570B1C38AbfcEA6);
        address gauge = address(0xeCEe212b65a54cA7725aA19DCEed45effB3cf385);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address arb = address(0x912CE59144191C1204E64559FE8253a0e49E6548);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[arb].push(
            ILizardRouter.Route({
                from: weth,
                to: arb,
                stable: false
            })
        );
      
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_ETSGamma_USDPlus is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0x97e5f60fA17816011039B908C19Fa4B43DE73731);
        address gauge = address(0xF5E17c2a60D4eF718F6b233d284978BEEb060eD6);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address etsGamma = address(0x813fFCC4Af3e810E6b447235cC88A02f00454453);
        address usdPlus = address(0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65);
        address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[usdPlus].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[usdPlus].push(
            ILizardRouter.Route({
                from: usdc,
                to: usdPlus,
                stable: true
            })
        );
        lpLiquidationPath[etsGamma].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[etsGamma].push(
            ILizardRouter.Route({
                from: usdc,
                to: usdPlus,
                stable: true
            })
        );
        lpLiquidationPath[etsGamma].push(
            ILizardRouter.Route({
                from: usdPlus,
                to: etsGamma,
                stable: true
            })
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_LUSD_USDC is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0xB1E9b823295B3C69ac651C05D987B67189ff20AD);
        address gauge = address(0xa4f536393E277DC63ECfa869d901b4f81cc5462C);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        address lusd = address(0x93b346b6BC2548dA6A1E7d98E9a421B42541425b);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[usdc].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[lusd].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
        lpLiquidationPath[lusd].push(
            ILizardRouter.Route({
                from: usdc,
                to: lusd,
                stable: true
            })
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_SLIZ_wETH is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0x751F3B8ca139bC1F3482b193297485f14208826a);
        address gauge = address(0x549855586afc1283E90295088ba5Eb51E7236ae8);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[lizard].push(
            ILizardRouter.Route({
                from: weth,
                to: lizard,
                stable: false
            })
        );
      
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SolidLizardStrategy.sol";

contract SolidLizardStrategyMainnet_wETH_USDC is SolidLizardStrategy {

    constructor() public {}

    function initializeStrategy(
        address _storage,
        address _vault
    ) public initializer {
        address underlying = address(0xe20F93279fF3538b1ad70D11bA160755625e3400);
        address gauge = address(0x0322CEbACF1f235913bE3FCE407F9F81632ede8B);
        address lizard = address(0x463913D3a3D3D291667D53B8325c598Eb88D3B0e);
        address weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        address usdc = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

        SolidLizardStrategy.initializeBaseStrategy(
            _storage,
            underlying,
            _vault,
            gauge
        );

        rewardTokens.push(lizard);
       
        reward2WETH[lizard].push(
            ILizardRouter.Route({
                from: lizard,
                to: weth,
                stable: false
            })
        );
        lpLiquidationPath[usdc].push(
            ILizardRouter.Route({
                from: weth,
                to: usdc,
                stable: false
            })
        );
      
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/uniswap/IUniswapV2Router02.sol";
import "../../base/interface/uniswap/IUniswapV2Pair.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/ICamelotRouter.sol";
import "../../base/interface/solidLizard/ILizardRouter.sol";
import "../../base/interface/sushiswap/IMiniChefV2.sol";

contract SushiStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  address public constant sushiRouter = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _POOLID_SLOT = 0x3fd729bfa2e28b7806b03a6e014729f59477b530f995be4d51defc9dad94810b;

  // this would be reset on each upgrade
  mapping(address => address[]) public WETH2deposit;
  mapping(address => address[]) public reward2WETH;
  address[] public rewardTokens;

  constructor() public BaseUpgradeableStrategy() {
    assert(_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.poolId")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    uint256 _poolID
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardPool,
      weth,
      harvestMSIG
    );

    address _lpt = IMiniChefV2(rewardPool()).lpToken(_poolID);
    require(_lpt == _underlying, "Underlying mismatch");

    _setPoolId(_poolID);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    (balance,) = IMiniChefV2(rewardPool()).userInfo(poolId(), address(this));
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
        _withdrawUnderlyingFromPool(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    if (amount > 0) {
      IMiniChefV2(rewardPool()).withdraw(poolId(), amount, address(this));
    }
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IMiniChefV2(rewardPool_).deposit(poolId(), entireBalance, address(this));
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function setDepositLiquidationPath(address [] memory _route) public onlyGovernance {
    address _underlying = underlying();
    address token0 = IUniswapV2Pair(_underlying).token0();
    address token1 = IUniswapV2Pair(_underlying).token1();
    require(_route[0] == weth, "Path should start with WETH");
    require(_route[_route.length-1] == token0 || _route[_route.length-1] == token1, "Path should end with a token in the underlying LP");
    WETH2deposit[_route[_route.length-1]] = _route;
  }

  function setRewardLiquidationPath(address [] memory _route) public onlyGovernance {
    require(_route[_route.length-1] == weth, "Path should end with WETH");
    bool isReward = false;
    for(uint256 i = 0; i < rewardTokens.length; i++){
      if (_route[0] == rewardTokens[i]) {
        isReward = true;
      }
    }
    require(isReward, "Path should start with a rewardToken");
    reward2WETH[_route[0]] = _route;
  }

  function addRewardToken(address _token, address[] memory _path2WETH) public onlyGovernance {
    rewardTokens.push(_token);
    setRewardLiquidationPath(_path2WETH);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));

      if (rewardBalance == 0) {
        continue;
      }
      if (reward2WETH[token].length < 2) {
        continue;
      }
      IERC20(token).safeApprove(sushiRouter, 0);
      IERC20(token).safeApprove(sushiRouter, rewardBalance);
      IUniswapV2Router02(sushiRouter).swapExactTokensForTokens(
      rewardBalance, 1, reward2WETH[token], address(this), block.timestamp);
    }

    address _rewardToken = rewardToken();
    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _underlying = underlying();
    address token0 = IUniswapV2Pair(_underlying).token0();
    address token1 = IUniswapV2Pair(_underlying).token1();

    uint256 toToken0 = remainingRewardBalance.div(2);
    uint256 toToken1 = remainingRewardBalance.sub(toToken0);

    IERC20(_rewardToken).safeApprove(sushiRouter, 0);
    IERC20(_rewardToken).safeApprove(sushiRouter, remainingRewardBalance);

    uint256 token0Amount;
    if (WETH2deposit[token0].length > 0) {
      IUniswapV2Router02(sushiRouter).swapExactTokensForTokens(
      toToken0, 1, WETH2deposit[token0], address(this), block.timestamp);
      token0Amount = IERC20(token0).balanceOf(address(this));
    } else {
      // otherwise we assme token0 is weth itself
      token0Amount = toToken0;
    }

    uint256 token1Amount;
    if (WETH2deposit[token1].length > 0) {
      IUniswapV2Router02(sushiRouter).swapExactTokensForTokens(
      toToken1, 1, WETH2deposit[token1], address(this), block.timestamp);
      token1Amount = IERC20(token1).balanceOf(address(this));
    } else {
      token1Amount = toToken1;
    }

    // provide token1 and token2 to Lizard
    IERC20(token0).safeApprove(sushiRouter, 0);
    IERC20(token0).safeApprove(sushiRouter, token0Amount);

    IERC20(token1).safeApprove(sushiRouter, 0);
    IERC20(token1).safeApprove(sushiRouter, token1Amount);

    IUniswapV2Router02(sushiRouter).addLiquidity(
      token0,
      token1,
      token0Amount,
      token1Amount,
      1,
      1,
      address(this),
      block.timestamp
    );
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    IMiniChefV2(rewardPool()).harvest(poolId(), address(this));
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setPoolId(uint256 _value) internal {
    setUint256(_POOLID_SLOT, _value);
  }

  function poolId() public view returns (uint256) {
    return getUint256(_POOLID_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./SushiStrategy.sol";

contract SushiStrategyMainnet_DPX_ETH is SushiStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0C1Cf6883efA1B496B01f654E247B9b419873054);
    address dpx = address(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55);
    address sushi = address(0xd4d42F0b6DEF4CE0383636770eF773390d85c61A);
    address miniChef = address(0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3);
    SushiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      miniChef,
      17        // Pool id
    );
    rewardTokens = [dpx, sushi];
    reward2WETH[dpx] = [dpx, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[dpx] = [weth, dpx];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./SushiStrategy.sol";

contract SushiStrategyMainnet_MAGIC_ETH is SushiStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xB7E50106A5bd3Cf21AF210A755F9C8740890A8c9);
    address magic = address(0x539bdE0d7Dbd336b79148AA742883198BBF60342);
    address sushi = address(0xd4d42F0b6DEF4CE0383636770eF773390d85c61A);
    address miniChef = address(0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3);
    SushiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      miniChef,
      13        // Pool id
    );
    rewardTokens = [magic, sushi];
    reward2WETH[magic] = [magic, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[magic] = [weth, magic];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./SushiStrategy.sol";

contract SushiStrategyMainnet_RDPX_ETH is SushiStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x7418F5A2621E13c05d1EFBd71ec922070794b90a);
    address dpx = address(0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55);
    address rdpx = address(0x32Eb7902D4134bf98A28b963D26de779AF92A212);
    address sushi = address(0xd4d42F0b6DEF4CE0383636770eF773390d85c61A);
    address miniChef = address(0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3);
    SushiStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      miniChef,
      23        // Pool id
    );
    rewardTokens = [dpx, sushi];
    reward2WETH[dpx] = [dpx, weth];
    reward2WETH[sushi] = [sushi, weth];
    WETH2deposit[rdpx] = [weth, rdpx];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategyMainnet_DAI is NoopStrategyUpgradeable {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategyMainnet_USDC is NoopStrategyUpgradeable {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategyMainnet_USDT is NoopStrategyUpgradeable {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategyMainnet_WETH is NoopStrategyUpgradeable {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}