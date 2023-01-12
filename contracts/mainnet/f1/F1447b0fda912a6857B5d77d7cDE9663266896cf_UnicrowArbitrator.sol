// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

import "../UnicrowTypes.sol";

interface IUnicrow {
  /**
   * @notice Deposit ETH or SafeERC20 to open a new escrow payment.
   * @notice We don't white- or black-list, but we strongly discourage users from using ERC777 tokens
   * @notice   and any ERC20 tokens which perform extra logic in their transfer functions. 
   * @notice If the balance claiming transaction fails due to the token's contract error or malicious behavior, 
   * @notice   it is not possible to try to claim the balance again.
   * @dev Escrow ID is generated automatically by the contract
   * @param input Escrow input (seller, marketplace, currency, and challenge period information)
   * @param arbitrator Arbitrator address (submit zero address to not set an arbitrator)
   * @param arbitratorFee Arbitrator Fee
   */
  function pay(
    EscrowInput memory input,
    address arbitrator,
    uint16 arbitratorFee
  ) external payable;

  /**
   * @notice Function called by UnicrowDispute to execute a challenge
   * @dev can be called by UnicrowDispute only
   * @param escrowId ID of the challenged escrow payment
   * @param split New split (bips)
   * @param consensus New consensus
   * @param challengeStart When the new challenge period starts
   * @param challengeEnd When the new challenge period ends
   */
  function challenge(
    uint256 escrowId,
    uint16[4] memory split,
    int16[2] memory consensus,
    uint64 challengeStart,
    uint64 challengeEnd
  ) external;

  /**
   * @notice Refund 100% of the buyer payment (all fees are waived).
   * @dev Can be called only by the Seller
   * @param escrowId ID of the escrow to be refunded
   */
  function refund(uint escrowId) external;

  /**
   * @notice Release the payment to the seller and to all other parties that charge a fee from it.
   * @dev Can be called by the Buyer only
   * @param escrowId ID of the escrow to be released
   */
  function release(uint escrowId) external;

  /**
   * @notice Settle a payment (i.e. split it with arbitrary shares between the buyer and the seller). Fees are reduced proportionally to the seller's share.
   * @dev Can be called only by UnicrowDispute
   * @param escrowId ID of the escrow to be settled
   * @param split New split in bips (total must equal 10000)
   * @param consensus New consensus
   */
  function settle(
    uint256 escrowId,
    uint16[4] memory split,
    int16[2] memory consensus
    ) external;

  /**
   * @notice Calculating the final splits (incl. fees) based on how the payment is concluded.
   * @dev The currentSplit is not expected to equal 100% in total. Buyer and seller splits should equal 100 based
   * on how the payment is settled, other splits represent fees which will get reduced and deducted accordingly
   * @param currentSplit Current splits in bips
   */
  function splitCalculation(
    uint16[5] calldata currentSplit
  ) external returns(uint16[5] memory);

  /**
   * @dev Get the escrow data (without arbitrator or settlement information)
   * @param escrowId ID of the escrow to retrieve information of
   */
  function getEscrow(
    uint256 escrowId
  ) external returns(Escrow memory);

  /**
   * @notice Set the escrow as claimed (i.e. that its balance has been sent to all the parties involved).
   * @dev Callable only by other Unicrow contracts
   * @param escrowId ID of the escrow to set as claimed
   */
  function setClaimed(uint escrowId) external;

  /**
   * @notice Update protocol fee (governance only, cannot be more than 1%)
   * @param fee New protocol fee (bips)
   */
  function updateEscrowFee(uint16 fee) external;

  /**
   * @notice Update governance contract address (governable)
   * @param governance New governance address
   */
  function updateGovernance(address governance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../UnicrowTypes.sol";

interface IUnicrowArbitrator {
    /**
     * Assigns an arbitrator to an escrow.
     * @dev Called by Unicrow.pay()
     * @param escrowId Id of the escrow
     * @param arbitrator Arbitrator's address
     * @param arbitratorFee Arbitrator fee in bips (can be 0)
      */
    function setArbitrator(uint256 escrowId, address arbitrator, uint16 arbitratorFee) external;

    /**
     * One of the parties (buyer or seller) can call this to propose an arbitrator
     * for an escrow that has no arbitrator defined
     * @param escrowId Id of the escrow
     * @param arbitrator Arbitrator's address
     * @param arbitratorFee Arbitrator fee in bips (can be 0)
      */
    function proposeArbitrator(uint256 escrowId, address arbitrator, uint16 arbitratorFee) external;

    /**
     * Approve an arbitrator proposed by another party (i.e. by seller if buyer proposed, by buyer if seller proposed).
     * @dev To ensure the user approves an arbitrator they wanted, it requires the same parameters as proposal
     * @param escrowId Id of an escrow
     * @param validationAddress Arbitrator's address - will be compared with the existing proposal
     * @param validation Arbitrator's Fee - will be compared with the existing proposal
    */
    function approveArbitrator(uint256 escrowId, address validationAddress, uint16 validation) external;

    /**
     * Arbitrate an payment - to be called only by an escrow's arbitrator
     * @param escrowId Id of an escrow
     * @param newSplit How the payment should be split between buyer [0] and seller [1]. [100, 0] will refund the payment to the buyer, [0, 100] will release it to the seller, anything in between will
     */
    function arbitrate(uint256 escrowId, uint16[2] memory newSplit) external;

    /**
     * Get information about proposed or assigned arbitrator.
     * @dev buyerConsensus and sellerConsensus indicate if the arbitrator was only proposed by one of the parties or
     * @dev has been assigned by the mutual consensus
     * @return Arbitrator information.
     * @param escrowId ID of the escrow
     */
    function getArbitratorData(uint256 escrowId) external view returns(Arbitrator memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUnicrowClaim {
    /// @notice Claim multiple escrows.
    /// @dev To save everyone's gas costs, it claims balances and fees of all parties that are eligible for a share from the escrow
    /// @param escrows List of escrows to be claimed.
    function claimMultiple(uint[] memory escrows) external;

    /// @notice Claim a single escrow
    /// @dev To save everyone's gas costs, it claims balances and fees of all parties that are eligible for a share from the escrow
    /// @param escrowId escrow to be claimed
    function claim(uint escrowId) external returns(uint256[5] memory);

    // @notice Update rewards contract pointer (governable)
    // @param crowRewards_ New rewards address
    function updateCrowRewards(address crowRewards_) external;

    // @notice Update staking rewards contract pointer (governable)
    // @param stakingRewards_ New staking rewards address
    function updateStakingRewards(address crowRewards_) external;

    // @notice Update protocol fee collection address (governable)
    // @param protocolFeeAddress_ New protocol fee collection address
    function updateProtocolFeeAddress(address protocolFeeAddress_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "../UnicrowTypes.sol";

interface IUnicrowDispute {
  /**
   * Challenge a payment. If the challenge is successful (the criteria are met),
   * it sets whoever sent the challenge as a payee and sets a new challenge period
   * @param escrowId Id of the escrow that's being challenged
   */
  function challenge(uint256 escrowId) external;

  /**
   * Send an offer to settle the payment between the buyer and the seller
   * @param escrowId ID of the escrow for which the offer is sent
   * @param newSplit the new settlement proposal ([buyerSplit, sellerSplit] in bips, sum must equal 10000)
   */
  function offerSettlement(uint256 escrowId, uint16[2] memory newSplit) external;

  /**
   * Approve an offer to settle the payment between the buyer and the seller
   * @param escrowId ID of the escrow for which the offer is sent
   * @param validation the settlement proposal that must be equal to an offer sent by the other party
   */
  function approveSettlement(uint256 escrowId,uint16[2] memory validation) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUnicrow.sol";
import "./interfaces/IUnicrowClaim.sol";
import "./interfaces/IUnicrowArbitrator.sol";
import "./UnicrowDispute.sol";
import "./UnicrowTypes.sol";

/// @title The primary Unicrow contract
/// @notice Receives and distributes the payments, maintains and provides information about the escrow records, and allows basic operations
contract Unicrow is ReentrancyGuard, IUnicrow, Context {
    using Counters for Counters.Counter;

    /// Generates unique escrow ID in incremental order
    Counters.Counter public escrowIdCounter;

    /// @notice Arbitrator information and functionality for the escrows
    IUnicrowArbitrator public immutable unicrowArbitrator;

    /// @notice Withdraws payments from the escrows once the criteria are met
    IUnicrowClaim public immutable unicrowClaim;

    /// @notice Dispute resolution, incl. challenges and settlements
    UnicrowDispute public immutable unicrowDispute;

    /// @notice Escrow fee in bips (can never be higher than 100)
    uint16 public protocolFee;

    /// address of a governance contract (multisig initially, DAO governor eventually)
    address public governanceAddress;

    /// storage of the primary escrow data. The key is generated by the contract incrementally
    mapping(uint256 => Escrow) escrows;

    /**
     * @notice Emitted when the payment is deposited into the contract and an escrow record is created
     * @param escrowId Unique, contract-generated escrow record identifier
     * @param blockTime timestamp of the block in which the transaction was included
     * @param escrow Details of the escrow as stored in the contract
     * @param arbitrator Address of an arbitrator (zero is returned if no arbitrator was defined)
     * @param arbitratorFee Arbitrator's fee in bips
     * @param challengePeriod Initial challenge period in seconds
     */
    event Pay(uint256 indexed escrowId, uint256 blockTime, Escrow escrow, address arbitrator, uint256 arbitratorFee, uint256 challengePeriod);

    /**
     * @notice Emitted when the buyer releases the payment manually (regardless of the challenge period)
     * @param escrowId ID of the released escrow payment
     * @param blockTime Timestamp of the block in which the transaction was included
     * @param escrow Details of the released Escrow
     * @param amounts Amounts in token allocated to each party (incl. fees). See UnicrowTypes for mapping of each party (WHO_*)
     */
    event Release(uint256 indexed escrowId, uint256 blockTime, Escrow escrow, uint256[5] amounts);

    /**
     * @notice Emitted when seller fully refunds the payment. Detailed calculated values are not returned because the payment is refunded in full, all fees are waived
     * @param escrowId Id of the refunded payment
     * @param escrow Details of the refunded payment
     * @param blockTime Timestamp of the block in which the transaction was included
     */
    event Refund(uint256 indexed escrowId, Escrow escrow, uint256 blockTime);

    /// The contructor initiates immutable and governed references to other contracts
    constructor(
        address unicrowClaim_,
        address unicrowArbitrator_,
        address unicrowDispute_,
        address governanceAddress_,
        uint16 protocolFee_
    ) {
        unicrowArbitrator = IUnicrowArbitrator(unicrowArbitrator_);
        unicrowClaim = IUnicrowClaim(unicrowClaim_);
        unicrowDispute = UnicrowDispute(unicrowDispute_);
        governanceAddress = governanceAddress_;
        protocolFee = protocolFee_;
    }

    /// Check that the governance contract is calling this
    modifier onlyGovernance() {
        require(_msgSender() == governanceAddress);
        _;
    }

    /// Check that Unicrow's claimMultiple contract is calling this
    modifier onlyUnicrowClaim() {
        require(_msgSender() == address(unicrowClaim));
        _;
    }

    /// Check that arbitration or dispute contract is calling this
    modifier onlyUnicrowArbitratorOrDispute() {
        require(_msgSender() == address(unicrowArbitrator) || _msgSender() == address(unicrowDispute));
        _;
    }

    /// Check that dispute contract is calling this
    modifier onlyUnicrowDispute() {
        require(_msgSender() == address(unicrowDispute));
        _;
    }

    /// @inheritdoc IUnicrow
    function pay(
        EscrowInput calldata input,
        address arbitrator,
        uint16 arbitratorFee
    ) external override payable nonReentrant {
        // Get current escrow id from the incremental counter
        uint256 escrowId = escrowIdCounter.current();

        // The address that sent the payment is set as a buyer
        address buyer = _msgSender();

        // Amount of the payment in ERC20 tokens
        uint amount = input.amount;

        // Make sure there's something left for the seller :-)
        require(arbitratorFee + input.marketplaceFee + protocolFee < 10000, "1-026");

        // Payment can't use address(0)
        require(escrows[escrowId].buyer == address(0), "0-001");

        // Seller cannot be empty
        require(input.seller != address(0), "0-002");

        // Buyer cannot be seller
        require(buyer != input.seller, "0-003");

        // Payment amount must be greater than zero
        require(amount > 0, "0-011");

        // Buyer can't send ETH if currency is not ETH
        if(msg.value > 0) {
            require(input.currency == address(0), "0-010");
        }
        
        // Check if the payment was made in ETH 
        if (input.currency == address(0)) {
            // Amount in the payment metadata must match what was sent
            require(amount == msg.value);
        } else {
            uint balanceBefore = IERC20(input.currency).balanceOf(address(this));

            // If the payment was made in ERC20 and not ETH, execute the transfer
            SafeERC20.safeTransferFrom(
                IERC20(input.currency),
                buyer,
                address(this),
                amount
            );

            uint balanceAfter = IERC20(input.currency).balanceOf(address(this));

            // Make sure that the input amount is the amount received
            amount = balanceAfter - balanceBefore;
        }

        // If a marketplace fee was set, ensure a marketplace address was set
        if(input.marketplaceFee > 0) {
            require(input.marketplace != address(0), "0-009");
        }

        // Check if the arbitrator was defined
        if (arbitrator != address(0)) {

            // Arbitrator can't be seller or buyer
            require(arbitrator != buyer && arbitrator != input.seller, "1-027");

            // Set the arbitrator in the arbitrator contract
            unicrowArbitrator.setArbitrator(escrowId, arbitrator, arbitratorFee);
        }

        // Split array is how Unicrow maintains information about seller's and buyer's shares, and the fees
        uint16[4] memory split = [0, 10000, input.marketplaceFee, protocolFee];
        
        // Set initial consensus to buyer = 0, seller = 1
        int16[2] memory consensus = [int16(0), int16(1)];

        // Create an Escrow object that will be stored in the contract
        Escrow memory escrow = Escrow({
            buyer: buyer,
            seller: input.seller,
            currency: input.currency,
            marketplace: input.marketplace,
            marketplaceFee: input.marketplaceFee,
            claimed: 0,
            split: split,
            consensus: consensus,
            challengeExtension: uint64(input.challengeExtension > 0 ? input.challengeExtension : input.challengePeriod),
            challengePeriodStart: uint64(block.timestamp), //challenge start
            challengePeriodEnd: uint64(block.timestamp + input.challengePeriod), //chalenge end
            amount: amount
        });

        // Store the escrow information
        escrows[escrowId] = escrow;

        // Increase the escrow id counter
        escrowIdCounter.increment();

        emit Pay(escrowId, block.timestamp, escrow, arbitrator, arbitratorFee, input.challengePeriod);
    }

    /// @inheritdoc IUnicrow
    function refund(uint256 escrowId) external override nonReentrant {
        address sender = _msgSender();

        // Get escrow information from the contract's storage
        Escrow memory escrow = escrows[escrowId];

        // Only seller can refund
        require(sender == escrow.seller, "1-011");

        // Check that the escrow is not claimed yet
        require(escrow.claimed == 0, "0-005");

        // Set split to 100% to buyer and waive the fees
        escrow.split[WHO_BUYER] = 10000;
        escrow.split[WHO_SELLER] = 0;
        escrow.split[WHO_MARKETPLACE] = 0;
        escrow.split[WHO_PROTOCOL] = 0;
        
        // Keep record of number of challenges (for reputation purposes)
        escrow.consensus[WHO_BUYER] = abs8(escrow.consensus[WHO_BUYER]) + 1;

        // Set escrow consensus based on the number of previous challenges (1 = no challenge)
        escrow.consensus[WHO_SELLER] = abs8(escrow.consensus[WHO_SELLER]);

        // Update splits and consensus information in the storage
        escrows[escrowId].split = escrow.split;
        escrows[escrowId].consensus = escrow.consensus;

        // Update the escrow as claimed in the storage and in the emitted event
        escrows[escrowId].claimed = 1;
        escrow.claimed = 1;

        // Withdraw the amount to the buyer
        if (address(escrow.currency) == address(0)) {
            (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
            require(success, "1-012");
        } else {
            SafeERC20.safeTransfer(
                IERC20(escrow.currency),
                escrow.buyer,
                escrow.amount
            );
        }


        emit Refund(escrowId, escrow, block.timestamp);
    }

    /// @inheritdoc IUnicrow
    function release(uint256 escrowId) external override {
        address sender = _msgSender();
        Escrow memory escrow = escrows[escrowId];

        // Only buyer can release
        require(sender == escrow.buyer, "1-025");

        // Set buyer consensus to 1 or based on the number of previous challenges
        escrow.consensus[WHO_BUYER] = abs8(escrow.consensus[WHO_BUYER]) + 1;

        // Set seller's escrow consensus based on the number of previous challenges
        escrow.consensus[WHO_SELLER] = abs8(escrow.consensus[WHO_SELLER]);

        // Update consensus in the storage
        escrows[escrowId].consensus = escrow.consensus;

        // Claim the payment and fees and get the final amounts
        uint256[5] memory amounts = unicrowClaim.claim(escrowId);

        // Emit all the information including the amounts
        emit Release(escrowId, block.timestamp, escrow, amounts);
    }

    /// @inheritdoc IUnicrow
    function challenge(
        uint256 escrowId,
        uint16[4] calldata split,
        int16[2] calldata consensus,
        uint64 challengeStart,
        uint64 challengeEnd
    ) external override onlyUnicrowDispute {
        escrows[escrowId].split = split;
        escrows[escrowId].consensus = consensus;
        escrows[escrowId].challengePeriodStart = challengeStart;
        escrows[escrowId].challengePeriodEnd = challengeEnd;
    }

    /// @inheritdoc IUnicrow
    function updateEscrowFee(uint16 fee) external override onlyGovernance {
        require(fee <= 100, "0-008");
        protocolFee = fee;
    }

    /// @inheritdoc IUnicrow
    function updateGovernance(address governance) external override onlyGovernance {
        governanceAddress = governance;
    }

    /// @notice Return basic escrow information (excl. arbitration information, settlement offers, and token details)
    /// @param escrowId ID of the escrow to be returned
    function getEscrow(uint256 escrowId)
        external
        override
        view
        returns (Escrow memory)
    {
        return escrows[escrowId];
    }

    /// @notice Return all the escrow data (incl. arbitration information, settlement offers, and token details)
    /// @param escrowId ID of the escrow to be returned
    function getAllEscrowData(uint256 escrowId)
        external
        view
        returns (Data memory)
    {
        address currency = escrows[escrowId].currency;

        // Get information about the ERC20 token (or return ETH)
        Token memory token = Token({
            address_: currency,
            decimals: currency == address(0) ? 18 : ERC20(currency).decimals(),
            symbol: currency == address(0) ? "ETH" : ERC20(currency).symbol()
        });

        Arbitrator memory arbitrator = unicrowArbitrator.getArbitratorData(escrowId);
        Settlement memory settlement = unicrowDispute.getSettlementDetails(escrowId);

        return Data(
            escrows[escrowId],
            arbitrator,
            settlement,
            token
        );
    }

    /// @dev Transfer ether or token from this contract's treasury. Can be called only by Unicrow's Claim contract
    function sendEscrowShare(
        address to,
        uint256 amount,
        address currency
    ) public onlyUnicrowClaim {
         if(currency == address(0)) {
            to.call{value: amount, gas: 5000}("");
         } else {
           SafeERC20.safeTransfer(
                IERC20(currency),
                to,
                amount
            );
         }
     }

    /// @inheritdoc IUnicrow
    function settle(
        uint256 escrowId,
        uint16[4] calldata split,
        int16[2] calldata consensus
    ) external override onlyUnicrowArbitratorOrDispute {
        escrows[escrowId].split = split;
        escrows[escrowId].consensus = consensus;
    }

    /// @inheritdoc IUnicrow
    function splitCalculation(
        uint16[5] calldata currentSplit
    ) external pure override returns (uint16[5] memory) {
        uint16[5] memory split;

        uint16 calculatedArbitratorFee;

        // Discount the protocol fee based on seller's share
        if (currentSplit[WHO_PROTOCOL] > 0) {
            split[WHO_PROTOCOL] = uint16((
                uint256(currentSplit[WHO_PROTOCOL]) *
                    currentSplit[WHO_SELLER]) /
                    _100_PCT_IN_BIPS
            );
        }

        // Discount the marketplace fee based on the seller's share
        if (currentSplit[WHO_MARKETPLACE] > 0) {
            split[WHO_MARKETPLACE] = uint16(
                (uint256(currentSplit[WHO_MARKETPLACE]) *
                    currentSplit[WHO_SELLER]) /
                    _100_PCT_IN_BIPS
            );
        }

        // Calculate the arbitrator fee based on the seller's split
        if (currentSplit[WHO_ARBITRATOR] > 0) {
            calculatedArbitratorFee = uint16(
                (uint256(currentSplit[WHO_ARBITRATOR]) *
                    currentSplit[WHO_SELLER]) /
                    _100_PCT_IN_BIPS
            );
        }

        // Calculate seller's final share by substracting all the fees
        split[WHO_SELLER] = currentSplit[WHO_SELLER] - split[WHO_PROTOCOL] - split[WHO_MARKETPLACE] - calculatedArbitratorFee;
        split[WHO_BUYER] = currentSplit[WHO_BUYER];
        split[WHO_ARBITRATOR] = calculatedArbitratorFee;

        return split;
    }

    /// @inheritdoc IUnicrow
    function setClaimed(uint256 escrowId) external override onlyUnicrowClaim nonReentrant {
        escrows[escrowId].claimed = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Unicrow.sol";
import "./interfaces/IUnicrowArbitrator.sol";
import "./interfaces/IUnicrowClaim.sol";
import "./UnicrowTypes.sol";

/**
 * @title Unicrow Arbitrator
 * @notice Functionality for assigning an arbitrator to an escrow and for an arbitrator to decide a dispute
 */
contract UnicrowArbitrator is IUnicrowArbitrator, Context, ReentrancyGuard {
    using Address for address payable;

    /// Reference to the main Unicrow contract
    Unicrow public immutable unicrow;
    
    /// Reference to the contract that manages claims from the escrows
    IUnicrowClaim public immutable unicrowClaim;

    /// Stores information about arbitrators in relation to escrows
    mapping(uint256 => Arbitrator) public escrowArbitrator;

    /**
     * @dev Emitted when an arbitrator has been proposed by one of the parties or
     * @dev if the other party sends a different proposal or also if the original party changes their proposal
     * @param escrowId Id of the escrow to which the proposer belongs
     * @param arbitrator Arbitrator's address
     * @param arbitratorFee Proposed fee in bips
     * @param proposer Address of the party that sent the proposal
    */
    event ArbitratorProposed(uint256 indexed escrowId, address arbitrator, uint16 arbitratorFee, address proposer);

    /**
     * @dev Emitted when the arbitrator proposal was approved by the other party
     * @param escrowId Id of the escrow to which the proposer belongs
     * @param arbitrator Arbitrator's address
     * @param arbitratorFee Proposed fee in bips
    */
    event ArbitratorApproved(uint256 indexed escrowId, address arbitrator, uint256 arbitratorFee);

    /**
     * @dev Emitted when the arbitrator has resolved a dispute
     * @param escrowId Id of the arbitrated escrow
     * @param escrow The escrow data, incl. the final split between buyer and seller as decided by the arbitrator
     * @param blockTime Timestamp of the block in which the transaction was minuted
     * @param amounts All amounts (i.e. incl. marketplace fee, arbitrator fee, and protocol fee) in the token
     */
    event Arbitrated(uint256 indexed escrowId, Escrow escrow, uint256 blockTime, uint256[5] amounts);

    /**
     * The constructor provides immutable reference to the main escrow and claimMultiple contracts
     * @param unicrow_ Unicrow contract address
     * @param unicrowClaim_ UnicrowClaim contract address
     */
    constructor(
        address unicrow_,
        address unicrowClaim_
    ) {
        unicrow = Unicrow(payable(unicrow_));
        unicrowClaim = IUnicrowClaim(payable(unicrowClaim_));
    }

    /**
     * @dev Checks if the provided address is either a buyer or a seller in the provided escrow
     * @param escrowId Id of the escrow to check
     * @param caller Address to check against
     */
    modifier onlyEscrowMember(uint256 escrowId, address caller) {
        require(_isEscrowMember(escrowId, caller), "2-004");
        _;
    }

    /// @dev Checks if the caller is the Unicrow's main escrow contract
    modifier onlyUnicrow() {
        require(_msgSender() == address(unicrow));
        _;
    }

    /// @inheritdoc IUnicrowArbitrator
    function setArbitrator(
        uint256 escrowId,
        address arbitrator,
        uint16 arbitratorFee
    ) external override onlyUnicrow {
        // Store arbitrator address and fee
        escrowArbitrator[escrowId].arbitrator = arbitrator;
        escrowArbitrator[escrowId].arbitratorFee = arbitratorFee;

        // In this case, the arbitrator was set during the payment,
        // so it is considered to be based on the mutual consensus consensus
        escrowArbitrator[escrowId].buyerConsensus = true;
        escrowArbitrator[escrowId].sellerConsensus = true;
    }

    /// @inheritdoc IUnicrowArbitrator
    function proposeArbitrator(
        uint256 escrowId,
        address arbitrator,
        uint16 arbitratorFee
    ) external override onlyEscrowMember(escrowId, _msgSender()) {
        Arbitrator storage arbitratorData = escrowArbitrator[escrowId];
        Escrow memory escrow = unicrow.getEscrow(escrowId);

        // Arbitrator can't be address 0
        require(arbitrator != address(0), "2-009");

        // Check if arbitrator is not the buyer or seller
        require(arbitrator != escrow.buyer && arbitrator != escrow.seller, "2-010");

        // Check that arbitrator hasnt't been set already
        require(!arbitratorData.buyerConsensus || !arbitratorData.sellerConsensus,"2-006" );

        // Make sure there's something left for the seller :-)
        require(escrow.marketplaceFee + escrow.split[WHO_PROTOCOL] + arbitratorFee < 10000, "2-007");

        // Save the proposal parameters
        arbitratorData.arbitrator = arbitrator;
        arbitratorData.arbitratorFee = arbitratorFee;

        // That the arbitrator is only proposed and not assigne is indicated by a lack of consensus
        if (_isEscrowBuyer(escrow, _msgSender())) {
            arbitratorData.buyerConsensus = true;
            arbitratorData.sellerConsensus = false;
        } else if (_isEscrowSeller(escrow, _msgSender())) {
            arbitratorData.sellerConsensus = true;
            arbitratorData.buyerConsensus = false;
        }

        emit ArbitratorProposed(
            escrowId,
            arbitrator,
            arbitratorFee,
            _msgSender()
        );
    }

    /// @inheritdoc IUnicrowArbitrator
    function approveArbitrator(uint256 escrowId, address validationAddress, uint16 validation)
        external
        override
        onlyEscrowMember(escrowId, _msgSender())
    {
        Arbitrator memory arbitratorData = getArbitratorData(escrowId);
        Escrow memory escrow = unicrow.getEscrow(escrowId);

        // Check that the arbitrator has been proposed
        require(arbitratorData.arbitrator != address(0), "2-008");

        // Compare the approval to the original proposal
        require(validationAddress == arbitratorData.arbitrator, "2-008");
        require(validation == arbitratorData.arbitratorFee, "2-007");

        // Check that the buyer is approving seller's proposal (or vice versa) and if yes, confirm the consensus
        if (_isEscrowBuyer(escrow, _msgSender())) {
            require(
                arbitratorData.buyerConsensus == false,
                "2-003"
            );
            escrowArbitrator[escrowId].buyerConsensus = true;
        }
        if (_isEscrowSeller(escrow, _msgSender())) {
            require(
                arbitratorData.sellerConsensus == false,
                "2-003"
            );
            escrowArbitrator[escrowId].sellerConsensus = true;
        }

        emit ArbitratorApproved(escrowId, arbitratorData.arbitrator, arbitratorData.arbitratorFee);
    }

    /// @inheritdoc IUnicrowArbitrator
    function arbitrate(uint256 escrowId, uint16[2] calldata newSplit)
        external
        override
    {
        Arbitrator memory arbitratorData = getArbitratorData(escrowId);
        Escrow memory escrow = unicrow.getEscrow(escrowId);

        // Check that this is this escrow's arbitrator calling
        require(_msgSender() == arbitratorData.arbitrator, "2-005");
        
        // Check that the arbitrator was set by mutual consensus
        require(
            arbitratorData.buyerConsensus && arbitratorData.sellerConsensus,
            "2-001"
        );
        
        // Ensure the splits equal 100%
        require(newSplit[WHO_BUYER] + newSplit[WHO_SELLER] == 10000, "1-007");

        // Retain number of challenges in the final consensus record
        escrow.consensus[WHO_BUYER] = abs8(escrow.consensus[WHO_BUYER]) + 1;
        escrow.consensus[WHO_SELLER] = abs8(escrow.consensus[WHO_SELLER]);

        // Update gross (pre-fees) splits as defined in the arbitration
        escrow.split[WHO_BUYER] = newSplit[WHO_BUYER];
        escrow.split[WHO_SELLER] = newSplit[WHO_SELLER];

        // Execute settlement on the escrow
        unicrow.settle(
            escrowId,
            escrow.split,
            escrow.consensus
        );

        // Set the payment as arbitrated
        escrowArbitrator[escrowId].arbitrated = true;

        // Withdraw the amounts accordingly
        //   (this will take into account that arbitrator called this and will set arbitrator fee accordingly)
        uint256[5] memory amounts = unicrowClaim.claim(escrowId);

        emit Arbitrated(escrowId, escrow, block.timestamp, amounts);
    }

    /**
     * @dev Calculates final splits of all parties involved in the payment when the paymet is decided by an arbitrator.
     * @dev If seller's split is < 100% it will discount the marketplace and protocol fee, but (unlike when refunded by
     * @dev seller or settled mutually) will keep full Arbitrator fee and deduct it from both shares proportionally
     * @param currentSplit Current split in bips. See WHO_* contants for keys
     * @return Splits in bips using the same keys for the array
     */
    function arbitrationCalculation(
        uint16[5] calldata currentSplit
    ) public pure returns (uint16[5] memory) {
        uint16[5] memory split;

        uint16 calculatedSellerArbitratorFee;
        uint16 calculatedBuyerArbitratorFee;

        if(currentSplit[WHO_ARBITRATOR] > 0) {
            // Calculate buyer's portion of the arbitrator fee
            calculatedBuyerArbitratorFee = uint16(
                (uint256(currentSplit[WHO_ARBITRATOR])
                        * currentSplit[WHO_BUYER])
                        / _100_PCT_IN_BIPS
            );
            
             // Seller's portion of the arbitrator fee
            calculatedSellerArbitratorFee = uint16(
                (uint256(currentSplit[WHO_ARBITRATOR])
                    * currentSplit[WHO_SELLER])
                    / _100_PCT_IN_BIPS
            );
            
            // Store how much the arbitrator will get from each party
            split[WHO_ARBITRATOR] = calculatedBuyerArbitratorFee + calculatedSellerArbitratorFee;
        }

        // Protocol fee
        if (currentSplit[WHO_PROTOCOL] > 0) {
            split[WHO_PROTOCOL] = uint16(
                (uint256(currentSplit[WHO_PROTOCOL])
                    * currentSplit[WHO_SELLER])
                    / _100_PCT_IN_BIPS
            );
        }

        // Marketplace fee
        if (currentSplit[WHO_MARKETPLACE] > 0) {
            split[WHO_MARKETPLACE] = uint16(
                (uint256(currentSplit[WHO_MARKETPLACE])
                    * currentSplit[WHO_SELLER])
                    / _100_PCT_IN_BIPS
            );
        }

        // Substract buyer's portion of the arbitartor fee from their share (if any)
        if(currentSplit[WHO_BUYER] > 0) {
            split[WHO_BUYER] = uint16(
                uint256(currentSplit[WHO_BUYER])
                        - calculatedBuyerArbitratorFee
                );
        }

        // Marketplace, protocol, and seller's portion of the arbitartor fee are substracted from seller's share
        if(currentSplit[WHO_SELLER] > 0) {
            split[WHO_SELLER] = uint16(
                uint256(currentSplit[WHO_SELLER])
                    - split[WHO_PROTOCOL]
                    - split[WHO_MARKETPLACE]
                    - calculatedSellerArbitratorFee
                );
        }

        return split;
    }

    /// @inheritdoc IUnicrowArbitrator
    function getArbitratorData(uint256 escrowId)
        public
        override
        view
        returns (Arbitrator memory)
    {
        return escrowArbitrator[escrowId];
    }

    /**
     * @dev Checks whether an address is a buyer in the provided escrow
     * @param escrowId Id of the escrow to check against
     * @param member_ the address to check
     */
    function _isEscrowMember(uint256 escrowId, address member_)
        internal
        view
        returns (bool)
    {
        Escrow memory escrow = unicrow.getEscrow(escrowId);
        return escrow.buyer == member_ || escrow.seller == member_;
    }

    /**
     * @dev Checks whether an address is a buyer in the provided escrow
     * @param escrow Instance of escrow
     * @param _buyer the address to check
     */
    function _isEscrowBuyer(Escrow memory escrow, address _buyer)
        internal
        pure
        returns (bool)
    {
        return _buyer == escrow.buyer;
    }

    /**
     * @dev Checks whether an address is a seller in the provided escrow
     * @param escrow Instance of escrow
     * @param _seller the address to check
     */
    function _isEscrowSeller(Escrow memory escrow, address _seller)
        internal
        pure
        returns (bool)
    {
        return _seller == escrow.seller;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IUnicrowClaim.sol";
import "./interfaces/IUnicrowDispute.sol";
import "./interfaces/IUnicrowArbitrator.sol";
import "./Unicrow.sol";
import "./UnicrowTypes.sol";

contract UnicrowDispute is IUnicrowDispute, Context, ReentrancyGuard {
    using Address for address payable;

    /// Main Unicrow's escrow contract
    Unicrow public immutable unicrow;

    /// Reference to the contract that manages claims from the escrow
    IUnicrowClaim public immutable unicrowClaim;

    /// Reference to the Arbitration contract
    IUnicrowArbitrator public immutable unicrowArbitrator;

    /// Stores information about which address sent the latest offer to settle a particular escrow identified by its ID
    mapping(uint256 => address) public latestSettlementOfferBy;

    /// Stores information about the splits in the latest offer to settle an escrow identified by its ID
    mapping(uint256 => uint16[2]) public latestSettlementOffer;

    /**
     * @dev Emitted when a challenge is sent for an escrow
     * @param escrowId ID of the challenged escrow
     * @param blockTime Timestamp when the challenge was minted
     * @param escrow information about the challenged escrow
    */
    event Challenge(uint256 indexed escrowId, uint256 blockTime, Escrow escrow);

    /**
     * @dev Settlement offer (i.e. offer to split the escrow by defined shares) was sent by one of the parties
     * @param escrowId ID of the scrow for which a settlement was offered
     * @param blockTime Timestamp for when the offer was minted
     * @param latestSettlementOffer Splits [buyer's split, seller's split] as defined in the offer (in bips)
     * @param latestSettlementOfferBy address which sent the offer
     */
    event SettlementOffer(uint256 indexed escrowId, uint256 blockTime, uint16[2] latestSettlementOffer, address latestSettlementOfferBy);

    /**
     * @dev Settlement offer was approved and the escrow was settled and claimed
     * @param escrowId ID of the escrow
     * @param escrow Details of the escrow
     * @param latestSettlementOffer Splits (in bips) in the settlement offer that was approved
     * @param blockTime Timestamp of when the settlement was minted
     * @param amounts amounts (in token) sent to addresses that were eligible to any shares and fees from the escrow
     */
    event ApproveOffer(uint256 indexed escrowId, Escrow escrow, uint16[2] latestSettlementOffer,uint256 blockTime, uint256[5] amounts);

    /**
     * Constructor sets immutable references to the related Unicrow contracts
     */
    constructor(
        address unicrow_,
        address unicrowClaim_,
        address unicrowArbitrator_
    ) {
        unicrow = Unicrow(payable(unicrow_));
        unicrowClaim = IUnicrowClaim(payable(unicrowClaim_));
        unicrowArbitrator = IUnicrowArbitrator(unicrowArbitrator_);
    }

    /// @inheritdoc IUnicrowDispute
    function challenge(uint256 escrowId) external override nonReentrant {
        address sender = _msgSender();

        Escrow memory escrow = unicrow.getEscrow(escrowId);

        // Only the escrow's seller and buyer can challenge
        require(sender == escrow.seller || sender == escrow.buyer, "1-009");

        // The payment must be either in "Paid" or "Challenged" state
        require(
            escrow.consensus[WHO_SELLER] <= 0 ||
                escrow.consensus[WHO_BUYER] <= 0,
            "1-005"
        );

        // Check that the challenge period is running
        require(block.timestamp <= escrow.challengePeriodEnd, "1-016");
        require(block.timestamp > escrow.challengePeriodStart, "1-019");

        // Prevent reduntant challenge from seller's side
        require(
            sender != escrow.buyer ||
            escrow.consensus[WHO_BUYER] <= 0,
            "1-014"
        );

        // Prevent reduntant challenge from buyer's side
        require(
            sender != escrow.seller ||
            escrow.consensus[WHO_SELLER] <= 0,
            "1-015"
        );

        // Challenge does a few things:
        //   - sets split to 100/0% for the challenging party
        //   - sets the challenging party's consensus to positive and increases it by one
        //   - sets the challenged party consensus to negative
        // This way, if one of the parties has negative consensus, we know the payment is challenged
        //   and the absolute number keeps track of how many challenges have there been
        if (sender == escrow.buyer) {
            escrow.split[WHO_BUYER] = 10000;
            escrow.split[WHO_SELLER] = 0;
            escrow.consensus[WHO_BUYER] = abs8(escrow.consensus[WHO_BUYER]) + 1;
            escrow.consensus[WHO_SELLER] = -(abs8(escrow.consensus[WHO_SELLER]));
        } else if (sender == escrow.seller) {
            escrow.split[WHO_SELLER] = 10000;
            escrow.split[WHO_BUYER] = 0;
            escrow.consensus[WHO_BUYER] = -(abs8(escrow.consensus[WHO_BUYER]));
            escrow.consensus[WHO_SELLER] = abs8(escrow.consensus[WHO_SELLER]) + 1;
        }

        // The new challenge period starts at the end of the current period
        //   and is extended by the time set in the original payment
        uint64 periodStart = escrow.challengePeriodEnd;
        uint64 periodEnd = escrow.challengePeriodEnd + escrow.challengeExtension;

        // Execute the challenge in the main escrow contract
        unicrow.challenge(
            escrowId,
            escrow.split,
            escrow.consensus,
            periodStart,
            periodEnd
        );

        // Update the challenge periods for the returned event
        escrow.challengePeriodStart = periodStart;
        escrow.challengePeriodEnd = periodEnd;

        emit Challenge(escrowId, block.timestamp, escrow);
    }

    /// @inheritdoc IUnicrowDispute
    function offerSettlement(uint256 escrowId, uint16[2] calldata newSplit)
        external
        override
        nonReentrant
    {
        address sender = _msgSender();
        Escrow memory escrow = unicrow.getEscrow(escrowId);

        // Only buyer or seller can offer a settlement
        require(sender == escrow.buyer || sender == escrow.seller, "1-009");

        // Check that the payment has not been released, refunded, or settled already
        require(
            escrow.consensus[WHO_SELLER] <= 0 ||
                escrow.consensus[WHO_BUYER] <= 0,
            "1-005"
        );

        // Proposed splits should equal 100%
        require(newSplit[WHO_BUYER] + newSplit[WHO_SELLER] == 10000, "1-007");

        // Record the latest offer details
        latestSettlementOfferBy[escrowId] = sender;
        latestSettlementOffer[escrowId] = newSplit;

        emit SettlementOffer(escrowId, block.timestamp, newSplit, msg.sender);
    }

    /// @inheritdoc IUnicrowDispute
    function approveSettlement(
        uint256 escrowId,
        uint16[2] calldata validation
    ) external override {
        address sender = _msgSender();

        Escrow memory escrow = unicrow.getEscrow(escrowId);

        address latestSettlementOfferByAddress = latestSettlementOfferBy[escrowId];

        // Only buyer or seller can approve a settlement
        require(sender == escrow.buyer || sender == escrow.seller, "1-009");

        // Check that there's a prior settlement offer
        require(latestSettlementOfferByAddress != address(0), "1-017");

        // Only buyer can approve Seller's offer and vice versa
        require(sender != latestSettlementOfferByAddress, "1-020");

        uint16[2] memory latestOffer = latestSettlementOffer[escrowId];

        // Check that the splits sent for approval are the ones that were offered
        require(
            validation[WHO_BUYER] == latestOffer[WHO_BUYER] &&
            validation[WHO_SELLER] == latestOffer[WHO_SELLER],
            "1-018"
        );

        uint16[4] memory split = escrow.split;

        split[WHO_BUYER] = latestOffer[WHO_BUYER];
        split[WHO_SELLER] = latestOffer[WHO_SELLER];

        // Update buyer and seller consensus to positive numbers
        escrow.consensus[WHO_BUYER] = abs8(escrow.consensus[WHO_BUYER]) + 1;
        escrow.consensus[WHO_SELLER] = abs8(escrow.consensus[WHO_SELLER]);

        // Record the settlement in the main escrow contract
        unicrow.settle(
            escrowId,
            split,
            escrow.consensus
        );

        // Sent shares to all the parties and read the final amounts
        uint256[5] memory amounts = unicrowClaim.claim(escrowId);

        emit ApproveOffer(escrowId, escrow, latestOffer, block.timestamp, amounts);
    }

    /**
     * Get details about the latest settlement offer
     * @param escrowId Id of the escrow to get settlement offer details for
     * @return Returns zero values in the returned object's fields if there's been no offer
     */
    function getSettlementDetails(uint256 escrowId) external view returns (Settlement memory) {
       Settlement memory settlement = Settlement(latestSettlementOfferBy[escrowId], latestSettlementOffer[escrowId]);
       return settlement;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

uint16 constant _100_PCT_IN_BIPS = 10000;

// these constants are used as keys for consensus and split arrays
uint8 constant WHO_BUYER = 0;
uint8 constant WHO_SELLER = 1;
uint8 constant WHO_MARKETPLACE = 2;
uint8 constant WHO_PROTOCOL = 3;
uint8 constant WHO_ARBITRATOR = 4;

/// @dev This is how information about each escrow is stored int he main contract, mapped to escrowId
struct Escrow {
    /// @dev Who sent the payment
    address buyer;

    /// @dev By how much will the challenge period get extended after a challenge (in seconds)
    uint64 challengeExtension;

    /// @dev Whom is the payment for
    address seller;

    /// @dev When does/has the current challenge period start(ed) (seconds in Unix epoch)
    uint64 challengePeriodStart;

    /// @dev Address of a marketplace that has facilitated the trade (0x000...00 if none)
    address marketplace;

    /// @dev Fee for the marketplace (can be 0 even if a marketplace was set but doesn't charge fee)
    uint256 marketplaceFee;

    /// @dev When does the current challenge period end (seconds in Unix epoch)
    uint64 challengePeriodEnd;

    /// @dev Token used in the payment (0x00..00 for ETH)
    address currency;

    /// @dev True if the payment was already withdrawn from the escrow
    uint16 claimed;

    /**
     * @dev Indicates status of the payment from buyer's and seller's side.
     * Negative value means that party was challenged.
     * Examples for various states:
     *  0, 1: Paid - If the payment is claimed after challenge period ends, consensus remains like this
     *  1, 1: Released by buyer
     *  1,-1: 1x Challenged by buyer - If the payment is claimed after CP ends, consensus remains like this
     * -1, 2: 1x Challenged by buyer and 1x by Seller
     *  2,-2: 2x Challenged by buyer, 1x by seller
     *  3, 2: Released, Refunded, or Settled. Deduct 1 from each consensus number to calculate number of challenges
     */
    int16[2] consensus;

    /**
     * @dev Buyer's and Seller's share, and fees, in bips
     * Example of a new payment with 5% marketplace fee, 5% arbitrator fee: [0, 10000, 500, 500]
     * If the payment is refunded: [10000, 0, 0, 0]
     * If the payment is settled (e.g. 20% discount for the buyer): [8000, 2000, 500, 500]
     *
     * Note, that the sum of all splits can equal to more than 100% here.
     * The actual fees and shares are re-calculated when the payment is finally claimed
     */
    uint16[4] split;

    /// @dev amount in the token
    uint256 amount;
}

/// @dev Escrow parameters to be sent along with the deposit
struct EscrowInput {
    /// @dev who should receive the payment
    address seller;

    /// @dev address of a marketplace that has facilitated the payment
    address marketplace;

    /// @dev Fee for the marketplace (can be 0 even if a marketplace was set but doesn't charge fee)
    uint16 marketplaceFee;

    /// @dev Token used in the payment (0x00..00 for ETH)
    address currency;

    /// @dev Initial challenge period (in seconds)
    uint32 challengePeriod;

    /// @dev By how much will the challenge period get extended after a challenge (in seconds)
    uint32 challengeExtension;

    /// @dev Amount in token
    uint256 amount;
}

/// @dev Information about arbitrator proposed or assigned to an escrow.
/// @dev If both buyerConsensus and sellerConsensus are 1, the arbitrator is assigned, otherwise it's only been proposed by the party that has 1
struct Arbitrator {
    /// @dev Address of the arbitrator. 0x00..00 for no arbitrator
    address arbitrator;

    /// @dev Arbitrator's fee in bips. Can be 0
    uint16 arbitratorFee;

    /// @dev Seller's agreement on the arbitrator
    bool sellerConsensus;

    /// @dev Buyer's agreement on the arbitrator
    bool buyerConsensus;

    /// @dev Has the escrow been decided by the arbitrator
    bool arbitrated;
}

/// @dev Stores information about settlement, mapped to escrowId in UnicrowDispute contract
struct Settlement {
    /// @dev address of who sent the latest settlement offer. Returns 0x00..00 if no offer has been made
    address latestSettlementOfferBy;

    /// @dev how the payment was offered to be settled [buyer, seller] in bips
    uint16[2] latestSettlementOffer;
}

/// @dev Information about the token used in the payment is returned in this structure
struct Token {
    address address_;
    uint8 decimals;
    string symbol;
}

/// @dev Superstructure that includes all the information relevant to an escrow
struct Data {
    Escrow escrow;
    Arbitrator arbitrator;
    Settlement settlement;
    Token token;
}

function abs8(int16 x) pure returns (int16) {
    return x >= 0 ? x : -x;
}