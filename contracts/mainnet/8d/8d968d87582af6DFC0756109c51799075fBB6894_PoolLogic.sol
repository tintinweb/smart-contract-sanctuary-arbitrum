// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IAssetGuard.sol";

interface IAaveLendingPoolAssetGuard {
  function flashloanProcessing(
    address pool,
    uint256 portion,
    address[] memory repayAssets,
    uint256[] memory repayAmounts,
    uint256[] memory premiums,
    uint256[] memory interestRateModes
  ) external view returns (IAssetGuard.MultiTransaction[] memory transactions);

  function aaveLendingPool() external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../IHasSupportedAsset.sol";

interface IAssetGuard {
  struct MultiTransaction {
    address to;
    bytes txData;
  }

  function withdrawProcessing(
    address pool,
    address asset,
    uint256 withdrawPortion,
    address to
  ) external returns (address, uint256, MultiTransaction[] memory transactions);

  function getBalance(address pool, address asset) external view returns (uint256 balance);

  function getDecimals(address asset) external view returns (uint256 decimals);

  function removeAssetCheck(address poolLogic, address asset) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IERC721VerifyingGuard {
  function verifyERC721(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata
  ) external returns (bool verified);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGuard {
  event ExchangeFrom(address fundAddress, address sourceAsset, uint256 sourceAmount, address dstAsset, uint256 time);
  event ExchangeTo(address fundAddress, address sourceAsset, address dstAsset, uint256 dstAmount, uint256 time);

  function txGuard(
    address poolManagerLogic,
    address to,
    bytes calldata data
  ) external returns (uint16 txType, bool isPublic); // TODO: eventually update `txType` to be of enum type as per ITransactionTypes
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISlippageCheckingGuard {
  function isSlippageCheckingGuard() external view returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IGuard.sol";

interface ITxTrackingGuard is IGuard {
  function isTxTrackingGuard() external view returns (bool);

  function afterTxGuard(address poolManagerLogic, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <=0.8.10;

// With aditional optional views

interface IERC20Extended {
  // ERC20 Optional Views
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  // Views
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function scaledBalanceOf(address user) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  // Mutative functions
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGovernance {
  function contractGuards(address target) external view returns (address guard);

  function assetGuards(uint16 assetType) external view returns (address guard);

  function nameToDestination(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <=0.8.10;

interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetType(address asset) external view returns (uint16);

  function getMaximumSupportedAssetCount() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasDaoInfo {
  function getDaoFee() external view returns (uint256, uint256);

  function daoAddress() external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasFeeInfo {
  // Manager fee
  function getMaximumFee() external view returns (uint256, uint256, uint256, uint256);

  function maximumPerformanceFeeNumeratorChange() external view returns (uint256);

  function performanceFeeNumeratorChangeDelay() external view returns (uint256);

  function getExitFee() external view returns (uint256, uint256);

  function getExitCooldown() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasGuardInfo {
  // Get guard
  function getContractGuard(address extContract) external view returns (address);

  // Get asset guard
  function getAssetGuard(address extContract) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasOwnable {
  function owner() external view returns (address);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasPausable {
  function isPaused() external view returns (bool);

  function pausedPools(address pool) external view returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

pragma experimental ABIEncoderV2;

interface IHasSupportedAsset {
  struct Asset {
    address asset;
    bool isDeposit;
  }

  function getSupportedAssets() external view returns (Asset[] memory);

  function isSupportedAsset(address asset) external view returns (bool);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManaged {
  function manager() external view returns (address);

  function trader() external view returns (address);

  function managerName() external view returns (string memory);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolFactory {
  function governanceAddress() external view returns (address);

  function isPool(address pool) external view returns (bool);

  function customCooldownWhitelist(address from) external view returns (bool);

  function receiverWhitelist(address to) external view returns (bool);

  function emitPoolEvent() external;

  function emitPoolManagerEvent() external;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPoolManagerLogic {
  function poolLogic() external view returns (address);

  function isDepositAsset(address asset) external view returns (bool);

  function validateAsset(address asset) external view returns (bool);

  function assetValue(address asset) external view returns (uint256);

  function assetValue(address asset, uint256 amount) external view returns (uint256);

  function assetBalance(address asset) external view returns (uint256 balance);

  function factory() external view returns (address);

  function setPoolLogic(address fundAddress) external returns (bool);

  function totalFundValue() external view returns (uint256);

  function totalFundValueMutable() external returns (uint256);

  function isMemberAllowed(address member) external view returns (bool);

  function getFee() external view returns (uint256, uint256, uint256, uint256);

  function minDepositUSD() external view returns (uint256);
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
//
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20Extended.sol";
import "./interfaces/IHasDaoInfo.sol";
import "./interfaces/IHasFeeInfo.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IHasAssetInfo.sol";
import "./interfaces/IHasPausable.sol";
import "./interfaces/IPoolManagerLogic.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/IHasOwnable.sol";
import "./interfaces/IHasDaoInfo.sol";
import "./interfaces/IManaged.sol";
import "./interfaces/guards/IGuard.sol";
import "./interfaces/guards/ITxTrackingGuard.sol";
import "./interfaces/guards/IAssetGuard.sol";
import "./interfaces/guards/IAaveLendingPoolAssetGuard.sol";
import "./interfaces/guards/IERC721VerifyingGuard.sol";
import "./interfaces/guards/ISlippageCheckingGuard.sol";
import "./interfaces/IGovernance.sol";
import "./utils/AddressHelper.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @notice Logic implementation for pool
contract PoolLogic is ERC20Upgradeable, ReentrancyGuardUpgradeable, IERC721ReceiverUpgradeable {
  using SafeMathUpgradeable for uint256;
  using AddressHelper for address;

  struct FundSummary {
    string name;
    uint256 totalSupply;
    uint256 totalFundValue;
    address manager;
    string managerName;
    uint256 creationTime;
    bool privatePool;
    uint256 performanceFeeNumerator;
    uint256 managerFeeNumerator;
    uint256 managerFeeDenominator;
    uint256 exitFeeNumerator;
    uint256 exitFeeDenominator;
    uint256 entryFeeNumerator;
  }

  struct TxToExecute {
    address to;
    bytes data;
  }

  struct WithdrawnAsset {
    address asset;
    uint256 amount;
    bool externalWithdrawProcessed;
  }

  struct WithdrawProcessing {
    uint256 portionBalance;
    uint256 expectedWithdrawValue;
  }

  event Deposit(
    address fundAddress,
    address investor,
    address assetDeposited,
    uint256 amountDeposited,
    uint256 valueDeposited,
    uint256 fundTokensReceived,
    uint256 totalInvestorFundTokens,
    uint256 fundValue,
    uint256 totalSupply,
    uint256 time
  );

  event Withdrawal(
    address fundAddress,
    address investor,
    uint256 valueWithdrawn,
    uint256 fundTokensWithdrawn,
    uint256 totalInvestorFundTokens,
    uint256 fundValue,
    uint256 totalSupply,
    WithdrawnAsset[] withdrawnAssets,
    uint256 time
  );

  event TransactionExecuted(address pool, address manager, uint16 transactionType, uint256 time);

  event PoolPrivacyUpdated(bool isPoolPrivate);

  event ManagerFeeMinted(
    address pool,
    address manager,
    uint256 available,
    uint256 daoFee,
    uint256 managerFee,
    uint256 tokenPriceAtLastFeeMint
  );

  event PoolManagerLogicSet(address poolManagerLogic, address from);

  bool public privatePool;
  address public creator;

  uint256 public creationTime;

  address public factory;

  // Manager fees
  uint256 public tokenPriceAtLastFeeMint;

  mapping(address => uint256) public lastDeposit;

  address public poolManagerLogic;

  mapping(address => uint256) public lastWhitelistTransfer;

  uint256 public lastFeeMintTime;

  mapping(address => uint256) public lastExitCooldown;

  modifier onlyAllowed(address _recipient) {
    require(_recipient == manager() || !privatePool || isMemberAllowed(_recipient), "only members allowed");
    _;
  }

  modifier onlyManager() {
    require(msg.sender == manager(), "only manager");
    _;
  }

  modifier whenNotFactoryPaused() {
    require(!IHasPausable(factory).isPaused(), "contracts paused");
    _;
  }

  modifier whitelistedForCustomCooldown() {
    require(IPoolFactory(factory).customCooldownWhitelist(msg.sender), "only whitelisted sender");
    _;
  }

  modifier whenNotPaused() {
    require(!IHasPausable(factory).pausedPools(address(this)), "pool is paused");
    _;
  }

  /// @notice Initialize the pool
  /// @param _factory address of the factory
  /// @param _privatePool true if the pool is private, false otherwise
  /// @param _fundName name of the fund
  /// @param _fundSymbol symbol of the fund
  function initialize(
    address _factory,
    bool _privatePool,
    string memory _fundName,
    string memory _fundSymbol
  ) external initializer {
    require(_factory != address(0), "Invalid factory");
    __ERC20_init(_fundName, _fundSymbol);
    __ReentrancyGuard_init();

    factory = _factory;
    _setPoolPrivacy(_privatePool);
    creator = msg.sender;
    creationTime = block.timestamp;
    lastFeeMintTime = block.timestamp;

    tokenPriceAtLastFeeMint = 10 ** 18;
  }

  /// @notice Before token transfer hook
  /// @param from address of the token owner
  /// @param to address of the token receiver
  /// @param amount amount of tokens to transfer
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    // Minting
    if (from == address(0)) {
      return;
    }

    if (IPoolFactory(factory).receiverWhitelist(to) == true) {
      return;
    }

    require(getExitRemainingCooldown(from) == 0, "cooldown active");
  }

  /// @notice Set the pool privacy
  /// @param _privatePool true if the pool is private, false otherwise
  function setPoolPrivate(bool _privatePool) external onlyManager {
    require(privatePool != _privatePool, "flag must be different");

    _setPoolPrivacy(_privatePool);
    emitFactoryEvent();
  }

  /// @notice Set the pool privacy internal call
  /// @param _privacy true if the pool is private, false otherwise
  function _setPoolPrivacy(bool _privacy) internal {
    privatePool = _privacy;

    emit PoolPrivacyUpdated(_privacy);
  }

  /// @notice Deposit funds into the pool
  /// @param _asset Address of the token
  /// @param _amount Amount of tokens to deposit
  /// @return liquidityMinted Amount of liquidity minted
  function deposit(address _asset, uint256 _amount) external returns (uint256 liquidityMinted) {
    return _depositFor(msg.sender, _asset, _amount, IHasFeeInfo(factory).getExitCooldown());
  }

  function depositFor(address _recipient, address _asset, uint256 _amount) external returns (uint256 liquidityMinted) {
    return _depositFor(_recipient, _asset, _amount, IHasFeeInfo(factory).getExitCooldown());
  }

  function depositForWithCustomCooldown(
    address _recipient,
    address _asset,
    uint256 _amount,
    uint256 _cooldown
  ) external whitelistedForCustomCooldown returns (uint256 liquidityMinted) {
    require(_cooldown >= 5 minutes, "cooldown must exceed 5 mins");
    require(_cooldown <= IHasFeeInfo(factory).getExitCooldown(), "cant exceed default cooldown");

    return _depositFor(_recipient, _asset, _amount, _cooldown);
  }

  function _depositFor(
    address _recipient,
    address _asset,
    uint256 _amount,
    uint256 _cooldown
  ) private onlyAllowed(_recipient) whenNotFactoryPaused whenNotPaused returns (uint256 liquidityMinted) {
    require(IPoolManagerLogic(poolManagerLogic).isDepositAsset(_asset), "invalid deposit asset");

    uint256 fundValue = _mintManagerFee();

    uint256 totalSupplyBefore = totalSupply();

    _asset.tryAssemblyCall(
      abi.encodeWithSelector(IERC20Upgradeable.transferFrom.selector, msg.sender, address(this), _amount)
    );

    uint256 usdAmount = IPoolManagerLogic(poolManagerLogic).assetValue(_asset, _amount);

    // Scoping to avoid stack too deep errors.
    {
      (, , uint256 entryFeeNumerator, uint256 denominator) = IPoolManagerLogic(poolManagerLogic).getFee();

      if (totalSupplyBefore > 0) {
        // Accounting for entry fee while calculating liquidity to be minted.
        liquidityMinted = usdAmount.mul(totalSupplyBefore).mul(denominator.sub(entryFeeNumerator)).div(fundValue).div(
          denominator
        );
      } else {
        // This is equivalent to doing liquidityMinted = liquidityMinted * (1 - entryFeeNumerator/denominator).
        liquidityMinted = usdAmount.mul(denominator.sub(entryFeeNumerator)).div(denominator);
      }
    }

    // Note: We are making it impossible for someone to mint liquidity < 100_000.
    // This is so that we can mitigate the inflation attack.
    require(liquidityMinted >= 100_000, "invalid liquidityMinted");

    lastExitCooldown[_recipient] = calculateCooldown(
      balanceOf(_recipient),
      liquidityMinted,
      _cooldown,
      lastExitCooldown[_recipient],
      lastDeposit[_recipient],
      block.timestamp
    );
    lastDeposit[_recipient] = block.timestamp;

    _mint(_recipient, liquidityMinted);

    uint256 balance = balanceOf(_recipient);
    uint256 fundValueAfter = fundValue.add(usdAmount);
    uint256 totalSupplyAfter = totalSupplyBefore.add(liquidityMinted);

    require(
      balance.mul(_tokenPrice(fundValueAfter, totalSupplyAfter)).div(10 ** 18) >=
        IPoolManagerLogic(poolManagerLogic).minDepositUSD(),
      "must meet minimum deposit"
    );

    emit Deposit(
      address(this),
      _recipient,
      _asset,
      _amount,
      usdAmount,
      liquidityMinted,
      balance,
      fundValueAfter,
      totalSupplyAfter,
      block.timestamp
    );
    emitFactoryEvent();
  }

  /// @notice Not recommended to use. Use `withdrawSafe` instead
  /// @dev Kept for backward compatibility
  function withdraw(uint256 _fundTokenAmount) external {
    _withdrawTo(msg.sender, _fundTokenAmount, 10_000);
  }

  /// @notice Not recommended to use. Use `withdrawToSafe` instead
  /// @dev Kept for backward compatibility
  function withdrawTo(address _recipient, uint256 _fundTokenAmount) external {
    _withdrawTo(_recipient, _fundTokenAmount, 10_000);
  }

  /// @notice Most recent function to be used for withdrawing assets from the vault
  /// @dev This is for vaults that can have slippage on withdrawal, eg. portfolio has Aave positions with debt
  function withdrawSafe(uint256 _fundTokenAmount, uint256 _slippageTolerance) external {
    _withdrawTo(msg.sender, _fundTokenAmount, _slippageTolerance);
  }

  /// @notice Most recent function to be used for withdrawing assets from the vault to a specific address
  /// @dev This is for vaults that can have slippage on withdrawal, eg. portfolio has Aave positions with debt
  function withdrawToSafe(address _recipient, uint256 _fundTokenAmount, uint256 _slippageTolerance) external {
    _withdrawTo(_recipient, _fundTokenAmount, _slippageTolerance);
  }

  /// @notice Withdraw assets based on the fund token amount
  /// @param _recipient The address to withdraw to
  /// @param _fundTokenAmount Amount of fund tokens to withdraw
  /// @param _slippageTolerance Slippage tolerance, 10_000 = 100%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
  function _withdrawTo(
    address _recipient,
    uint256 _fundTokenAmount,
    uint256 _slippageTolerance
  ) internal nonReentrant whenNotFactoryPaused whenNotPaused {
    require(lastDeposit[msg.sender] < block.timestamp, "can withdraw shortly");
    require(balanceOf(msg.sender) >= _fundTokenAmount, "insufficient balance");
    require(_slippageTolerance <= 10_000, "invalid tolerance");

    // Scoping to avoid "stack-too-deep" errors.
    {
      // Calculating how much pool token supply will be left after withdrawal and
      // whether or not this satisfies the min supply (100_000) check.
      // If the user is redeeming all the shares then this check passes.
      // Otherwise, they might have to reduce the amount to be withdrawn.
      uint256 supplyAfter = totalSupply().sub(_fundTokenAmount);
      require(supplyAfter >= 100_000 || supplyAfter == 0, "below supply threshold");
    }

    // calculate the exit fee
    uint256 fundValue = _mintManagerFee();

    // calculate the proportion
    uint256 portion = _fundTokenAmount.mul(10 ** 18).div(totalSupply());

    // first return funded tokens
    _burn(msg.sender, _fundTokenAmount);

    // TODO: Combining into one line to fix stack too deep,
    //       need to refactor some variables into struct in order to have more variables
    IHasSupportedAsset.Asset[] memory _supportedAssets = IHasSupportedAsset(poolManagerLogic).getSupportedAssets();
    WithdrawnAsset[] memory withdrawnAssets = new WithdrawnAsset[](_supportedAssets.length);
    uint16 index = 0;

    for (uint256 i = 0; i < _supportedAssets.length; i++) {
      (address asset, uint256 portionOfAssetBalance, bool externalWithdrawProcessed) = _withdrawProcessing(
        _supportedAssets[i].asset,
        _recipient,
        portion,
        _slippageTolerance
      );

      if (portionOfAssetBalance > 0) {
        require(asset != address(0), "requires asset to withdraw");
        // Ignoring return value for transfer as want to transfer no matter what happened
        asset.tryAssemblyCall(
          abi.encodeWithSelector(IERC20Upgradeable.transfer.selector, _recipient, portionOfAssetBalance)
        );
      }

      if (externalWithdrawProcessed || portionOfAssetBalance > 0) {
        withdrawnAssets[index] = WithdrawnAsset({
          asset: asset,
          amount: portionOfAssetBalance,
          externalWithdrawProcessed: externalWithdrawProcessed
        });
        index++;
      }
    }

    // Reduce length for withdrawnAssets to remove the empty items
    uint256 reduceLength = _supportedAssets.length.sub(index);
    assembly {
      mstore(withdrawnAssets, sub(mload(withdrawnAssets), reduceLength))
    }

    uint256 valueWithdrawn = portion.mul(fundValue).div(10 ** 18);

    emit Withdrawal(
      address(this),
      msg.sender,
      valueWithdrawn,
      _fundTokenAmount,
      balanceOf(msg.sender),
      fundValue.sub(valueWithdrawn),
      totalSupply(),
      withdrawnAssets,
      block.timestamp
    );
    emitFactoryEvent();
  }

  /// @notice Perform any additional processing on withdrawal of asset
  /// @dev Checks for staked tokens and withdraws them to the investor account
  /// @param asset Asset for withdrawal processing
  /// @param to Investor account to send withdrawed tokens to
  /// @param portion Portion of investor withdrawal of the total dHedge pool
  /// @param slippageTolerance Slippage tolerance for withdrawal
  /// @return withdrawAsset Asset to be withdrawed
  /// @return withdrawBalance Asset balance amount to be withdrawed
  /// @return externalWithdrawProcessed A boolean for success or fail transaction
  function _withdrawProcessing(
    address asset,
    address to,
    uint256 portion,
    uint256 slippageTolerance
  )
    internal
    returns (
      address, // withdrawAsset
      uint256, // withdrawBalance
      bool externalWithdrawProcessed
    )
  {
    // Withdraw any external tokens (eg. staked tokens in other contracts)
    address guard = IHasGuardInfo(factory).getAssetGuard(asset);
    require(guard != address(0), "invalid guard");

    WithdrawProcessing memory params;
    params.portionBalance = IAssetGuard(guard).getBalance(address(this), asset).mul(portion).div(10 ** 18);
    // Value of the portion of the asset to be withdrawn
    params.expectedWithdrawValue = IPoolManagerLogic(poolManagerLogic).assetValue(asset, params.portionBalance);

    (address withdrawAsset, uint256 withdrawBalance, IAssetGuard.MultiTransaction[] memory transactions) = IAssetGuard(
      guard
    ).withdrawProcessing(address(this), asset, portion, to);

    uint256 txCount = transactions.length;
    if (txCount > 0) {
      uint256 assetBalanceBefore;
      if (withdrawAsset != address(0)) {
        assetBalanceBefore = IERC20Upgradeable(withdrawAsset).balanceOf(address(this));
      }
      // In case of withdraw from aave position with debt, this loop is where flash loan starts and finishes its execution
      for (uint256 i = 0; i < txCount; i++) {
        externalWithdrawProcessed = transactions[i].to.tryAssemblyCall(transactions[i].txData);
      }
      // In case of withdraw from aave position with debt, remaining weth is withdrawAsset and it gets added here
      if (withdrawAsset != address(0)) {
        // get any balance increase after withdraw processing and add it to the withdraw balance
        uint256 assetBalanceAfter = IERC20Upgradeable(withdrawAsset).balanceOf(address(this));
        withdrawBalance = withdrawBalance.add(assetBalanceAfter.sub(assetBalanceBefore));
      }
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool hasFunction, bytes memory answer) = guard.call(abi.encodeWithSignature("isSlippageCheckingGuard()"));
    // check slippage after asset's withdraw processing if required in its guard (eg. Aave)
    if (hasFunction && abi.decode(answer, (bool)) && withdrawAsset != address(0)) {
      // Ensure that actual value of tokens transferred is not less than the expected value, corrected by allowed tolerance
      require(
        IPoolManagerLogic(poolManagerLogic).assetValue(withdrawAsset, withdrawBalance) >=
          params.expectedWithdrawValue.mul(10_000 - slippageTolerance).div(10_000),
        "high withdraw slippage"
      );
    }

    return (withdrawAsset, withdrawBalance, externalWithdrawProcessed);
  }

  /// @notice Private function to let pool talk to other protocol
  /// @dev execute transaction for the pool
  /// @param to The destination address for pool to talk to
  /// @param data The data that going to send in the transaction
  /// @return success A boolean for success or fail transaction
  function _execTransaction(
    address to,
    bytes memory data
  ) private nonReentrant whenNotFactoryPaused returns (bool success) {
    require(to != address(0), "non-zero address is required");

    address contractGuard = IHasGuardInfo(factory).getContractGuard(to);
    address assetGuard;
    address guard;
    uint16 txType;
    bool isPublic;

    if (contractGuard != address(0)) {
      guard = contractGuard;
      (txType, isPublic) = IGuard(contractGuard).txGuard(poolManagerLogic, to, data);
    }

    // invalid contract guard call, try asset guard
    if (txType == 0) {
      // no contract guard configured, get asset guard
      assetGuard = IHasGuardInfo(factory).getAssetGuard(to);

      if (assetGuard == address(0)) {
        // If there is no contractGuard and no assetGuard then use the ERC20Guard for the transaction,
        // which will only allow a valid approve transaction
        address governanceAddress = IPoolFactory(factory).governanceAddress();
        assetGuard = IGovernance(governanceAddress).assetGuards(0); // get ERC20Guard (assetType 0)
      } else {
        // if asset is configured, ensure that it's enabled in the pool
        require(IHasSupportedAsset(poolManagerLogic).isSupportedAsset(to), "asset not enabled in pool");
      }
      guard = assetGuard;
      (txType, isPublic) = IGuard(assetGuard).txGuard(poolManagerLogic, to, data);
    }

    require(txType > 0, "invalid transaction");
    // solhint-disable-next-line reason-string
    require(isPublic || msg.sender == manager() || msg.sender == trader(), "only manager or trader or public function");

    success = to.tryAssemblyCall(data);

    // call afterTxGuard to track transactions
    // to make it compatible with previous version, we use low-level call before calling afterTxGuard() function
    // the low level call will return `false` if its execution reverts
    // solhint-disable-next-line avoid-low-level-calls
    (bool hasFunction, bytes memory returnData) = guard.call(abi.encodeWithSignature("isTxTrackingGuard()"));
    if (hasFunction && abi.decode(returnData, (bool))) {
      ITxTrackingGuard(guard).afterTxGuard(poolManagerLogic, to, data);
    }

    emit TransactionExecuted(address(this), manager(), txType, block.timestamp);
    emitFactoryEvent();
  }

  /// @notice Exposed function to let pool talk to other protocol
  /// @dev Execute single transaction for the pool
  /// @param to The destination address for pool to talk to
  /// @param data The data that going to send in the transaction
  /// @return success A boolean for success or fail transaction
  function execTransaction(address to, bytes calldata data) external returns (bool success) {
    return _execTransaction(to, data);
  }

  /// @notice Exposed function to let pool talk to other protocol
  /// @dev Execute multiple transactions for the pool
  /// @param txs Array of structs, each consisting of address and data
  /// @return success A boolean indicating if all transactions succeeded
  function execTransactions(TxToExecute[] calldata txs) external returns (bool success) {
    require(txs.length > 0, "no transactions to execute");

    for (uint256 i = 0; i < txs.length; i++) {
      bool result = _execTransaction(txs[i].to, txs[i].data);
      require(result, "transaction failure");
    }

    return true;
  }

  /// @notice Get fund summary of the pool
  /// @return Fund summary of the pool
  function getFundSummary() external view returns (FundSummary memory) {
    (
      uint256 performanceFeeNumerator,
      uint256 managerFeeNumerator,
      uint256 entryFeeNumerator,
      uint256 managerFeeDenominator
    ) = IPoolManagerLogic(poolManagerLogic).getFee();
    (uint256 exitFeeNumerator, uint256 exitFeeDenominator) = IHasFeeInfo(factory).getExitFee();

    return
      FundSummary(
        name(),
        totalSupply(),
        IPoolManagerLogic(poolManagerLogic).totalFundValue(),
        manager(),
        managerName(),
        creationTime,
        privatePool,
        performanceFeeNumerator,
        managerFeeNumerator,
        managerFeeDenominator,
        exitFeeNumerator,
        exitFeeDenominator,
        entryFeeNumerator
      );
  }

  /// @notice Get price of the asset adjusted for any unminted manager fees
  /// @param price A price of the asset
  function tokenPrice() external view returns (uint256 price) {
    uint256 fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    uint256 managerFee = calculateAvailableManagerFee(fundValue);
    uint256 tokenSupply = totalSupply().add(managerFee);

    price = _tokenPrice(fundValue, tokenSupply);
  }

  function tokenPriceWithoutManagerFee() external view returns (uint256 price) {
    uint256 fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    uint256 tokenSupply = totalSupply();
    price = _tokenPrice(fundValue, tokenSupply);
  }

  /// @notice Get price of the asset internal call
  /// @param _fundValue The total fund value of the pool
  /// @param _tokenSupply The total token supply of the pool
  /// @return price A price of the asset
  function _tokenPrice(uint256 _fundValue, uint256 _tokenSupply) internal pure returns (uint256 price) {
    if (_tokenSupply == 0 || _fundValue == 0) return 0;
    price = _fundValue.mul(10 ** 18).div(_tokenSupply);
  }

  /// @notice Get available manager fee of the pool
  /// @dev Keep this for backward compatibility (currently used by frontend and backend)
  /// @return fee available manager fee of the pool
  function availableManagerFee() external view returns (uint256 fee) {
    uint256 fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValue();
    fee = calculateAvailableManagerFee(fundValue);
  }

  /// @notice Get available manager fee of the pool
  /// @dev Can be used on the frontend by passing in fund value
  /// @param fundValue The total fund value of the pool
  /// @return fee available manager fee of the pool
  function calculateAvailableManagerFee(uint256 fundValue) public view returns (uint256 fee) {
    uint256 tokenSupply = totalSupply();

    (uint256 performanceFeeNumerator, uint256 managerFeeNumerator, , uint256 managerFeeDenominator) = IPoolManagerLogic(
      poolManagerLogic
    ).getFee();

    fee = _availableManagerFee(
      fundValue,
      tokenSupply,
      performanceFeeNumerator,
      managerFeeNumerator,
      managerFeeDenominator
    );
  }

  /// @notice Get available manager fee of the pool internal call
  /// @param _fundValue The total fund value of the pool
  /// @param _tokenSupply The total token supply of the pool
  /// @param _performanceFeeNumerator The manager fee numerator
  /// @param _managerFeeNumerator The streaming fee numerator
  /// @param _feeDenominator The fee denominator
  /// @return available manager fee of the pool
  function _availableManagerFee(
    uint256 _fundValue,
    uint256 _tokenSupply,
    uint256 _performanceFeeNumerator,
    uint256 _managerFeeNumerator,
    uint256 _feeDenominator
  ) internal view returns (uint256 available) {
    if (_tokenSupply == 0 || _fundValue == 0) return 0;

    uint256 currentTokenPrice = _fundValue.mul(10 ** 18).div(_tokenSupply);

    if (currentTokenPrice > tokenPriceAtLastFeeMint) {
      available = currentTokenPrice
        .sub(tokenPriceAtLastFeeMint)
        .mul(_tokenSupply)
        .mul(_performanceFeeNumerator)
        .div(_feeDenominator)
        .div(currentTokenPrice);
    }

    // this timestamp for old pools would be zero at the first time
    if (lastFeeMintTime != 0) {
      uint256 timeChange = block.timestamp.sub(lastFeeMintTime);
      uint256 streamingFee = _tokenSupply.mul(timeChange).mul(_managerFeeNumerator).div(_feeDenominator).div(365 days);
      available = available.add(streamingFee);
    }
  }

  /// @notice Mint the manager fee of the pool
  function mintManagerFee() external whenNotFactoryPaused whenNotPaused {
    _mintManagerFee();
  }

  /// @notice Get mint manager fee of the pool internal call
  /// @return fundValue The total fund value of the pool
  function _mintManagerFee() internal returns (uint256 fundValue) {
    fundValue = IPoolManagerLogic(poolManagerLogic).totalFundValueMutable();
    uint256 tokenSupply = totalSupply();

    (uint256 performanceFeeNumerator, uint256 managerFeeNumerator, , uint256 managerFeeDenominator) = IPoolManagerLogic(
      poolManagerLogic
    ).getFee();

    uint256 available = _availableManagerFee(
      fundValue,
      tokenSupply,
      performanceFeeNumerator,
      managerFeeNumerator,
      managerFeeDenominator
    );

    address daoAddress = IHasDaoInfo(factory).daoAddress();
    uint256 daoFeeNumerator;
    uint256 daoFeeDenominator;

    (daoFeeNumerator, daoFeeDenominator) = IHasDaoInfo(factory).getDaoFee();

    uint256 daoFee = available.mul(daoFeeNumerator).div(daoFeeDenominator);
    uint256 managerFee = available.sub(daoFee);

    if (daoFee > 0) _mint(daoAddress, daoFee);

    if (managerFee > 0) _mint(manager(), managerFee);

    uint256 currentTokenPrice = _tokenPrice(fundValue, tokenSupply);
    if (tokenPriceAtLastFeeMint < currentTokenPrice) {
      tokenPriceAtLastFeeMint = currentTokenPrice;
    }

    lastFeeMintTime = block.timestamp;

    emit ManagerFeeMinted(address(this), manager(), available, daoFee, managerFee, tokenPriceAtLastFeeMint);
    emitFactoryEvent();
  }

  /// @notice Calculate lockup cooldown applied to the investor after pool deposit
  /// @param currentBalance Investor's current pool tokens balance
  /// @param liquidityMinted Liquidity to be minted to investor after pool deposit
  /// @param newCooldown New cooldown lockup time
  /// @param lastCooldown Last cooldown lockup time applied to investor
  /// @param lastDepositTime Timestamp when last pool deposit happened
  /// @param blockTimestamp Timestamp of a block
  /// @return cooldown New lockup cooldown to be applied to investor address
  function calculateCooldown(
    uint256 currentBalance,
    uint256 liquidityMinted,
    uint256 newCooldown,
    uint256 lastCooldown,
    uint256 lastDepositTime,
    uint256 blockTimestamp
  ) public pure returns (uint256 cooldown) {
    // Get timestamp when current cooldown ends
    uint256 cooldownEndsAt = lastDepositTime.add(lastCooldown);
    // Current exit remaining cooldown
    uint256 remainingCooldown = cooldownEndsAt < blockTimestamp ? 0 : cooldownEndsAt.sub(blockTimestamp);
    // If it's first deposit with zero liquidity, no cooldown should be applied
    if (currentBalance == 0 && liquidityMinted == 0) {
      cooldown = 0;
      // If it's first deposit, new cooldown should be applied
    } else if (currentBalance == 0) {
      cooldown = newCooldown;
      // If zero liquidity or new cooldown reduces remaining cooldown, apply remaining
    } else if (liquidityMinted == 0 || newCooldown < remainingCooldown) {
      cooldown = remainingCooldown;
      // For the rest cases calculate cooldown based on current balance and liquidity minted
    } else {
      // If the user already owns liquidity, the additional lockup should be in proportion to their existing liquidity.
      // Calculated as newCooldown * liquidityMinted / currentBalance
      uint256 additionalCooldown = newCooldown.mul(liquidityMinted).div(currentBalance);
      // Aggregate additional and remaining cooldowns
      uint256 aggregatedCooldown = additionalCooldown.add(remainingCooldown);
      // Resulting value is capped at new cooldown time (shouldn't be bigger) and falls back to one second in case of zero
      cooldown = aggregatedCooldown > newCooldown
        ? newCooldown
        : aggregatedCooldown != 0
          ? aggregatedCooldown
          : 1;
    }
  }

  /// @notice Get exit remaining time of the pool
  /// @return remaining The remaining exit time of the pool
  function getExitRemainingCooldown(address sender) public view returns (uint256 remaining) {
    uint256 cooldownFinished = lastDeposit[sender].add(lastExitCooldown[sender]);

    if (cooldownFinished < block.timestamp) return 0;

    remaining = cooldownFinished.sub(block.timestamp);
  }

  /// @notice Set address for pool manager logic
  function setPoolManagerLogic(address _poolManagerLogic) external returns (bool) {
    require(_poolManagerLogic != address(0), "Invalid poolManagerLogic address");
    require(
      msg.sender == address(factory) || msg.sender == IHasOwnable(factory).owner(),
      "only owner or factory allowed"
    );

    poolManagerLogic = _poolManagerLogic;
    emit PoolManagerLogicSet(_poolManagerLogic, msg.sender);
    return true;
  }

  /// @notice Get address of the manager
  /// @return _manager The address of the manager
  function manager() internal view returns (address _manager) {
    _manager = IManaged(poolManagerLogic).manager();
  }

  /// @notice Get address of the trader
  /// @return _trader The address of the trader
  function trader() internal view returns (address _trader) {
    _trader = IManaged(poolManagerLogic).trader();
  }

  /// @notice Get name of the manager
  /// @return _managerName The name of the manager
  function managerName() public view returns (string memory _managerName) {
    _managerName = IManaged(poolManagerLogic).managerName();
  }

  /// @notice Return boolean if the address is a member of the list
  /// @param member The address of the member
  /// @return True if the address is a member of the list, false otherwise
  function isMemberAllowed(address member) public view returns (bool) {
    return IPoolManagerLogic(poolManagerLogic).isMemberAllowed(member);
  }

  /// @notice execute function of aave flash loan
  /// @dev This function is called after your contract has received the flash loaned amount
  /// @param assets the loaned assets
  /// @param amounts the loaned amounts per each asset
  /// @param premiums the additional owed amount per each asset
  /// @param originator the origin caller address of the flash loan
  /// @param params Variadic packed params to pass to the receiver as extra information
  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address originator,
    bytes memory params
  ) external returns (bool success) {
    require(originator == address(this), "only pool flash loan origin");

    address aaveLendingPoolAssetGuard = IHasGuardInfo(factory).getAssetGuard(msg.sender);
    require(
      aaveLendingPoolAssetGuard != address(0) &&
        msg.sender == IAaveLendingPoolAssetGuard(aaveLendingPoolAssetGuard).aaveLendingPool(),
      "invalid lending pool"
    );

    (uint256[] memory interestRateModes, uint256 portion) = abi.decode(params, (uint256[], uint256));

    address weth = IHasGuardInfo(factory).getAddress("weth");
    uint256 wethBalanceBefore = IERC20Upgradeable(weth).balanceOf(address(this));

    IAssetGuard.MultiTransaction[] memory transactions = IAaveLendingPoolAssetGuard(aaveLendingPoolAssetGuard)
      .flashloanProcessing(address(this), portion, assets, amounts, premiums, interestRateModes);

    for (uint256 i = 0; i < transactions.length; i++) {
      success = transactions[i].to.tryAssemblyCall(transactions[i].txData);
    }

    // Liquidation of collateral not enough to pay off debt, flashloan repayment stealing pool's weth
    require(
      wethBalanceBefore == 0 || wethBalanceBefore <= IERC20Upgradeable(weth).balanceOf(address(this)),
      "too high slippage"
    );
  }

  /// @notice Emits an event through the factory, so we can just listen to the factory offchain
  function emitFactoryEvent() internal {
    IPoolFactory(factory).emitPoolEvent();
  }

  /// @notice Support safeTransfers from ERC721 asset contracts
  /// @dev Currently used for Synthetix V3
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4 magicSelector) {
    address contractGuard = IHasGuardInfo(factory).getContractGuard(operator);

    // Only guarded contract can initiate ERC721 transfers
    require(contractGuard != address(0), "only guarded address allowed");

    require(
      IERC721VerifyingGuard(contractGuard).verifyERC721(operator, from, tokenId, data),
      "ERC721 token not verified"
    );

    magicSelector = IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  uint256[47] private __gap;
}

//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

// import "./BytesLib.sol";

pragma solidity 0.7.6;

/**
 * @title A library for Address utils.
 */
library AddressHelper {
  /**
   * @notice try a contract call via assembly
   * @param to the contract address
   * @param data the call data
   * @return success if the contract call is successful or not
   */
  function tryAssemblyCall(address to, bytes memory data) internal returns (bool success) {
    assembly {
      success := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
      switch iszero(success)
      case 1 {
        let size := returndatasize()
        returndatacopy(0x00, 0x00, size)
        revert(0x00, size)
      }
    }
  }

  /**
   * @notice try a contract delegatecall via assembly
   * @param to the contract address
   * @param data the call data
   * @return success if the contract call is successful or not
   */
  function tryAssemblyDelegateCall(address to, bytes memory data) internal returns (bool success) {
    assembly {
      success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
      switch iszero(success)
      case 1 {
        let size := returndatasize()
        returndatacopy(0x00, 0x00, size)
        revert(0x00, size)
      }
    }
  }

  // /**
  //  * @notice try a contract call
  //  * @param to the contract address
  //  * @param data the call data
  //  * @return success if the contract call is successful or not
  //  */
  // function tryCall(address to, bytes memory data) internal returns (bool) {
  //   (bool success, bytes memory res) = to.call(data);

  //   // Get the revert message of the call and revert with it if the call failed
  //   require(success, _getRevertMsg(res));

  //   return success;
  // }

  // /**
  //  * @dev Get the revert message from a call
  //  * @notice This is needed in order to get the human-readable revert message from a call
  //  * @param response Response of the call
  //  * @return Revert message string
  //  */
  // function _getRevertMsg(bytes memory response) internal pure returns (string memory) {
  //     // If the response length is less than 68, then the transaction failed silently (without a revert message)
  //     if (response.length < 68) return "Transaction reverted silently";
  //     bytes memory revertData = response.slice(4, response.length - 4); // Remove the selector which is the first 4 bytes
  //     return abi.decode(revertData, (string)); // All that remains is the revert string
  // }
}