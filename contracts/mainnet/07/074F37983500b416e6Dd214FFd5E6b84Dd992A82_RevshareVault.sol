// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * Constant values used elsewhere
 */
library LibConstants {

    //gas that was used just to load this contract, etc.
    uint constant PRE_OP_GAS = 40_000;
    
    //final computation needed to compute and transfer gas fees
    uint constant POST_OP_GAS = 80_000;
    

    uint16 constant HOUR = 3600;
    uint24 constant DAY = 86400;

    //storage and calldata requirements significantly higher when using more than 
    //6decs for USD price precision
    uint constant USD_PRECISION = 1e6;

    //1_000_000 as a 6-decimal number
    uint constant MM_VOLUME = 1e12;

    //when doing asset-related math, increase precision accordingly.
    uint constant PRICE_PRECISION = 1e30;

    //========================================================================
    // Assignable roles for role-managed contracts
    //========================================================================

    //allowed to add relays and other role managers
    string public constant ROLE_MGR = "ROLE_MANAGER";

    //allowed to submit execution requests
    string public constant RELAY = "RELAY";

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../libraries/LibStorage.sol";

/**
 * This contract aims to mitigate concerns over a single EOA upgrading or making
 * config changes to deployed contracts. It essentially requires that N-signatures 
 * approve any config change along with a timelock before the change can be applied.
 * 
 * The intent is for the community to have more awareness/insight into the changes being
 * made and why. The timelock period gives the community an opportunity to voice concerns
 * so that any pending change can be cancelled for reconsideration.
 *
 * The way this works is changes are associated with an underlying function selector. 
 * That selector will not be callable until at least the minimum signatures are provided
 * approving the change. Once approvals are provided, and enough time has ellapsed, 
 * the underlying change function is called and the approval is cleared for the next 
 * change.
 *
 * Pausing is also supported such that it can only be called by an approver. Pause function 
 * is an emergency and is immediately enforced without multiple signatures. Resume requires 
 * multiple parties to resume operations.
 */
abstract contract MultiSigConfigurable {
    
    using LibMultiSig for LibMultiSig.MultiSigStorage;

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    event RequiredSigChanged(uint newReq);
    event ChangeRequested(address indexed approver, bytes4 selector, bytes32 sigHash, uint nonce, uint timelockExpiration);
    event UpgradeRequested(address indexed approver, address logic, bytes32 sigHash, uint timelockExpiration);

    event LogicUpgraded(address indexed newLogic);

    event Paused(address indexed caller);
    event ResumeRequested(address indexed approvder, bytes32 sigHash);
    event ResumedOperations();

    /**
     * Modifier to check whether a specific function has been approved by required signers
     */
    modifier afterApproval(bytes4 selector) {
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        require(ms.approvedCalls[selector], "Not approved to call");
        _;
    }

    /**
     * Only an approver can call the function with this modifier
     */
    modifier onlyApprover() {
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        require(ms.approvedSigner[msg.sender], "Unauthorized");
        _;
    }

    /**
     * Function is only callable when contract is not paused
     */
    modifier notPaused() {
        require(!LibStorage.getMultiSigStorage().paused, "Not while paused");
        _;
    }
    
    /**
     * Validate and initialize the multi-sig stored configuration settings. This is 
     * only callable once after deployment.
     */
    function initializeMSConfigurable(LibMultiSig.MultiSigConfig memory config) public {
        LibStorage.getMultiSigStorage().initializeMultSig(config);
    }

    /**
     * Add a signer to the multi-sig
     */
    function addSigner(address signer) public onlyApprover {
        require(address(0) != signer, "Invalid signer");
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        ms.approvedSigner[signer] = true;
        emit SignerAdded(signer);
    }

    /** 
     * Remove a signer from the multi-sig
     */
    function removeSigner(address signer) public onlyApprover {
        require(address(0) != signer, "Invalid signer");
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        delete ms.approvedSigner[signer];
        emit SignerRemoved(signer);
    }

    /**
     * Make an adjustment to the minimum number of signers. This requires approval 
     * from signers as well as a timelock delay.
     */
    function setRequiredSigs(uint8 sigs) public afterApproval(this.setRequiredSigs.selector) {
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        ms.requiredSigs = sigs;
        emit RequiredSigChanged(sigs);
    }

    /****************************************************************************
     * Pause logic
     *****************************************************************************/
    /** 
     * Pause is immediately enforced by a single approver
     */
    function pause() public onlyApprover {
        LibMultiSig.MultiSigStorage storage ms = LibStorage.getMultiSigStorage();
        ms.paused = true;
        emit Paused(msg.sender);
    }

    /**
     * Determine if the contract is paused
     */
    function isPaused() public view returns (bool) {
        return LibStorage.getMultiSigStorage().paused;
    }

    /**
     * Request that the contract resume operations.
     */
    function requestResume() public onlyApprover {
        LibStorage.getMultiSigStorage().requestResume();
    }

    /**
     * Cancel a resume request
     */
    function cancelResume() public onlyApprover {
        LibStorage.getMultiSigStorage().cancelResume();
    }

    function resumeSigsNeeded() public view returns(uint8) {
        return LibStorage.getMultiSigStorage().resumeSigsNeeded();
    }

    function delegatedApproveResume(address signer, bytes calldata sig) public onlyApprover {
        LibStorage.getMultiSigStorage().delegatedApproveResume(signer, sig);
    }

    function approveResume() public onlyApprover {
        LibStorage.getMultiSigStorage().approveResume();
    }
    //END PAUSE LOGIC---------------------------------------------------------------
    



    /****************************************************************************
     * Upgrade logic
     *****************************************************************************/
    
    /**
     * Request that the multi-sig's underlying logic change. This registers a requirements
     * for signers to approve the upgrade.
     */
    function requestUpgrade(address logic) public onlyApprover {
        LibStorage.getMultiSigStorage().requestUpgrade(logic);
    }

    /**
     * Whether a pending upgrade has sufficieint signatures and enough time has ellapsed
     */
    function canUpgrade() public view returns (bool) {
        return LibStorage.getMultiSigStorage().canUpgrade();
    }

    /**
     * The number of signatures needed for an upgrade
     */
    function upgradeSignaturesNeeded() public view returns (uint) {
        return LibStorage.getMultiSigStorage().upgradeSigsNeeded();
    }

    /**
     * Manual call to approve a pending upgrade.
     */
    function approveUpgrade() public onlyApprover {
        LibStorage.getMultiSigStorage().approveUpgrade();
    }

    /**
     * A delegated approval for an upgrade. The signed hash is derived from events 
     * emitted when upgrade was requested.
     */
    function delegatedApproveUpgrade(address signer, bytes calldata sig) public onlyApprover {
        LibStorage.getMultiSigStorage().delegatedApproveUpgrade(signer, sig);
    }
    //END UPGRADE LOGIC---------------------------------------------------------------



    /****************************************************************************
     * Change logic
     *****************************************************************************/

    /**
     * Request a change be made to the contract settings. The details of what is changed 
     * are embedded in the calldata. This should be the function call that will be executed
     * on this contract once approval is settled.
     */
    function requestChange(bytes calldata data) public onlyApprover {
        LibStorage.getMultiSigStorage().requestChange(data);
    }

    /**
     * Cancel a pending change using the nonce that was provided in the event emitted
     * when the change was requested.
     */
    function cancelChange(uint nonce) public onlyApprover {
        LibStorage.getMultiSigStorage().cancelChange(nonce);
    }

    /**
     * Whether a change can be applied. The nonce is emitted as part of the request change event.
     */
    function canApplyChange(uint nonce) public view {
        return LibStorage.getMultiSigStorage().canApplyChange(nonce);
    }

    /**
     * Number of signatures needed to approve a specific change.
     */
    function changeSigsNeeded(uint nonce) public view returns (uint) {
        return LibStorage.getMultiSigStorage().changeSigsNeeded(nonce);
    }

    /**
     * Delegated approval for a specific change.
     */
    function delegatedApproveChange(uint nonce, address signer, bytes calldata sig) public onlyApprover {
        LibStorage.getMultiSigStorage().delegatedApproveChange(nonce, signer, sig);
    }

    /**
     * Direct approve for a specific change.
     */
    function approveChange(uint nonce) public onlyApprover {
        LibStorage.getMultiSigStorage().approveChange(nonce);
    }
    //END CHANGE LOGIC---------------------------------------------------------------

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../token/IDXBL.sol";
import "./LibMultiSig.sol";
import "../revshare/IRevshareVault.sol";
import "../common/LibConstants.sol";

/**
 * Primary library for Dexible contract ops and storage. All functions are protected by
 * modifiers in Dexible contract except for initialize.
 */
library LibDexible {

    event ChangedRevshareVault(address indexed old, address indexed newRevshare);
    event ChangedRevshareSplit(uint8 split);
    event ChangedBpsRates(uint32 stdRate, uint32 minRate);

    //used to change revshare vault address
    struct RevshareChange {
        address revshare;
        uint allowedAfterTime;
    }

    //used to change the revshare split percentage
    struct SplitChange {
        uint8 split;
        uint allowedAfterTime;
    }

    //used to changes the std and min bps fees
    struct BpsFeeChange {
        uint16 stdBps;
        uint16 minBps;
    }

    //primary initialization config settings
    struct DexibleConfig {
        
        //percent to split to revshare
        uint8 revshareSplitRatio;

        //std bps rate to apply to all trades
        uint16 stdBpsRate;

        //minimum bps rate regardless of tokens held
        uint16 minBpsRate;

        //the revshare vault contract
        address revshareManager;

        //treasury for Dexible team
        address treasury;

        //the DXBL token address
        address dxblToken;

        //address of account to assign roles
        address roleManager;

        //minimum flat fee to charge if bps fee is too low
        uint112 minFeeUSD;

        //config info for multisig settings
        LibMultiSig.MultiSigConfig multiSigConfig;
    }

    /**
     * This is the primary storage for Dexible operations.
     */
    struct DexibleStorage {
        //how much of fee goes to revshare vault
        uint8 revshareSplitRatio;
         
        //standard bps fee rate
        uint16 stdBpsRate;

        //minimum fee applied regardless of tokens held
        uint16 minBpsRate;

        //min fee to charge if bps too low
        uint112 minFeeUSD;
        
        //revshare vault address
        address revshareManager;

        //treasury address
        address treasury;

        //the DXBL token
        IDXBL dxblToken;
    }

    /**
     * Initialize storage settings. This can only be called once after deployment of proxy.
     */
    function initialize(DexibleStorage storage ds, DexibleConfig calldata config) public {
        require(ds.treasury == address(0), "Dexible was already initialized");

        require(config.revshareManager != address(0), "Invalid RevshareVault address");
        require(config.treasury != address(0), "Invalid treasury");
        require(config.dxblToken != address(0), "Invalid DXBL token address");
        require(config.revshareSplitRatio > 0, "Invalid revshare split ratio");
        require(config.stdBpsRate > 0, "Must provide a standard bps fee rate");
        require(config.minBpsRate > 0, "minBpsRate is required");
        require(config.minBpsRate < config.stdBpsRate, "Min bps rate must be less than std");

        ds.revshareSplitRatio = config.revshareSplitRatio;
        ds.revshareManager = config.revshareManager;
        ds.treasury = config.treasury;
        ds.dxblToken = IDXBL(config.dxblToken);
        ds.stdBpsRate = config.stdBpsRate;
        ds.minBpsRate = config.minBpsRate;
        ds.minFeeUSD = config.minFeeUSD; //can be 0
    }

    /**
     * Set the stored revshare vault.
     */
    function setRevshareVault(DexibleStorage storage ds, address t) public {
        require(t != address(0), "Invalid revshare vault");
        emit ChangedRevshareVault(ds.revshareManager, t);
        ds.revshareManager = t;
    }

    /**
     * Set the revshare split percentage
     */
    function setRevshareSplit(DexibleStorage storage ds, uint8 split) public {
        require(split > 0, "Invalid split");
        ds.revshareSplitRatio = split;
        emit ChangedRevshareSplit(split);
    }

    /**
     * Set new std/min bps rates
     */
    function setNewBps(DexibleStorage storage rs, BpsFeeChange calldata changes) public {
        require(changes.minBps > 0,"Invalid min bps fee");
        require(changes.stdBps > 0, "Invalid std bps fee");
        rs.minBpsRate = changes.minBps;
        rs.stdBpsRate = changes.stdBps;
        emit ChangedBpsRates(changes.stdBps, changes.minBps);
    }

    

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * This library is the logic and storage used for multi-sig ops
 */
library LibMultiSig {

    //initial multi-sig initialization settings
    struct MultiSigConfig {
        uint8 requiredSigs;
        uint32 timelockSeconds;
        address logic;
        address[] approvers;
    }

    //a pending change of some kind
    struct PendingChange {
        uint8 approvals;
        bytes32 sigHash;
        bytes4 selector;
        bytes fnData;
        uint allowedAfterTime;
    }

    //pending upgrade to contract logic
    struct PendingUpgrade {
        uint8 approvals;
        bytes32 sigHash;
        address newLogic;
        uint allowedAfterTime;
    }

    //pending resume request
    struct PendingResume {
        uint8 approvals;
        bytes32 sigHash;
        uint allowedAfterTime;
    }


    event ChangeRequested(address indexed approver, bytes4 selector, bytes32 sigHash, uint nonce, uint timelockExpiration);
    event UpgradeRequested(address indexed approver, address logic, bytes32 sigHash, uint timelockExpiration);
    event ResumeRequested(address indexed approvder, bytes32 sigHash);
    event LogicUpgraded(address indexed newLogic);
    event ResumedOperations();

    /**
     * The primary storage for MultiSig ops
     */
    struct MultiSigStorage {

        //whether the multi-sig is pausing all public operations
        bool paused;

        //number of sigs required to make changes
        uint8 requiredSigs;

        //the logic implementation for the proxy using this multi-sig
        address logic;

        //unique nonce for change sigs
        uint nonce;

        //how many seconds to wait before changes are allowed to be committed
        uint32 timelockSeconds;

        //pending logic upgrade.
        PendingUpgrade pendingUpgrade;

        //pending resume request waiting on sigs
        PendingResume pendingResume;

        //changes are pending function calls with timelock and sig requirement
        mapping(uint => PendingChange) pendingChanges;

        //whether a particular address signed off on a change hash yet
        mapping(bytes32 => address[]) signedChanges;

        //all approved change function call selectors are stored here. They are
        //check when the change function is called. It must be sig approved and
        //expire its timelock before it ends up here
        mapping(bytes4 => bool) approvedCalls;

        //all approved signers
        mapping(address => bool) approvedSigner;
    }

    /**
     * Intialize multi-sig settings
     */
    function initializeMultSig(MultiSigStorage storage ms, MultiSigConfig calldata config) public {
        require(ms.requiredSigs == 0, "Already initialized");
        require(config.requiredSigs > 1, "At least 2 signers required");
        require(config.approvers.length >= config.requiredSigs, "Need at least as many approvers as sigs required");
        require(config.timelockSeconds > 0, "Invalid timelock");
        require(config.logic != address(0), "Invalid logic address");
        ms.requiredSigs = config.requiredSigs;
        ms.logic = config.logic;
        ms.timelockSeconds = config.timelockSeconds;
        for(uint i=0;i<config.approvers.length;i=_incr(i)) {
            ms.approvedSigner[config.approvers[i]] = true;
        }
    }

    /****************************************************************************
     * Pause Logic
     *****************************************************************************/

     /**
      * Request that the contract resume normal operations.
      */
    function requestResume(MultiSigStorage storage ms) public {
        //make sure we're paused
        require(ms.paused, "Not currently paused");
        //create sighash from next nonce
        bytes32 sigHash = keccak256(abi.encode(ms.nonce, block.chainid));

        //mark sender as having signed the hash
        ms.signedChanges[sigHash].push(msg.sender);

        //immediate expiration so that it can be resumed right away once approved
        uint exp = block.timestamp;
        ms.pendingResume = PendingResume({
            approvals: 1,
            sigHash: sigHash,
            allowedAfterTime: exp
        });
        //increment for next op
        ++ms.nonce;
        emit ResumeRequested(msg.sender, sigHash);
    }

    /**
     * Cancel a request to resume operations
     */
    function cancelResume(MultiSigStorage storage ms) public {
        require(ms.pendingResume.allowedAfterTime > 0, "No pending resume");
        delete ms.pendingResume;
    }

    /**
     * Whether we can resume operations yet
     */
    function canResume(MultiSigStorage storage ms) public view returns (bool) {
        require(ms.pendingResume.allowedAfterTime > 0, "No pending resume");
        return ms.pendingResume.approvals + 1 >= ms.requiredSigs;
    }

    /**
     * Number of approvals needed to resume ops
     */
    function resumeSigsNeeded(MultiSigStorage storage ms) public view returns (uint8) {
        require(ms.pendingResume.allowedAfterTime > 0, "No pending resume");
        return ms.requiredSigs - ms.pendingResume.approvals;
    }

    /**
     * Delegated signature to resume operations
     */
    function delegatedApproveResume(MultiSigStorage storage ms, address signer, bytes calldata sig) public {
        //make sure signer is authorized
        require(ms.approvedSigner[signer], "Unauthorized signer");
        PendingResume storage pu = ms.pendingResume;
        require(pu.allowedAfterTime > 0, "No pending resume request");
        //and that their sig is valid
        address check = ECDSA.recover(_asMessage(pu.sigHash), sig);
        require(check == signer, "Invalid signature");
        //then actually resume
        _doApproveResume(ms, signer, pu);
    }

    /**
     * Approver approving resume ops
     */
    function approveResume(MultiSigStorage storage ms) public {
        PendingResume storage pu = ms.pendingResume;
        require(pu.allowedAfterTime > 0, "No pending resume request");
        _doApproveResume(ms, msg.sender, pu);
    }

    function _doApproveResume(MultiSigStorage storage ms, address signer, PendingResume storage pu) private {
        //make sure didn't sign already
        require(!_contains(ms.signedChanges[pu.sigHash],signer), "Signer already signed");
        //increment approvals
        ++pu.approvals;
        bytes32 sigHash = pu.sigHash;
        //see if we've hit threshold yt
        if(pu.approvals >= ms.requiredSigs) {
            //no longer paused
            ms.paused = false;
            //cleanup requests and signature history
            delete ms.signedChanges[sigHash];
            delete ms.pendingResume;
        } else {
            //if mark signer as approving resume
            ms.signedChanges[sigHash].push(signer);
        }
    }
    //--------------------------------------------------------------------------------


    /****************************************************************************
     * Upgrade logic
     *****************************************************************************/

     /**
      * Request that the underlying logic for this contract be upgraded
      */
    function requestUpgrade(MultiSigStorage storage ms, address logic) public {
        //ensure not setting incorrectly
        require(logic != address(0), "Invalid logic address");
        
        //hash of address and unique op nonce (and chain to prevent replays)
        bytes32 sigHash = keccak256(abi.encode(logic, ms.nonce, block.chainid));

        //mark sender as approving op
        ms.signedChanges[sigHash].push(msg.sender);

        //expiration is after timelock
        uint exp = block.timestamp + ms.timelockSeconds;
        ms.pendingUpgrade = PendingUpgrade({
            approvals: 1,
            sigHash: sigHash,
            newLogic: logic,
            allowedAfterTime: exp
        });

        //increment for next op
        ++ms.nonce;
        emit UpgradeRequested(msg.sender, logic, sigHash, exp);
    }

    /**
     * Cancel request to upgrade the contract logic
     */
    function cancelUpgrade(MultiSigStorage storage ms) public {
        delete ms.pendingUpgrade;
    }

    /**
     * Whether we can upgrade the logic yet
     */
    function canUpgrade(MultiSigStorage storage ms) public view returns (bool) {
        return ms.pendingUpgrade.allowedAfterTime > 0 &&
                ms.pendingUpgrade.allowedAfterTime < block.timestamp &&
                ms.pendingUpgrade.approvals + 1 >= ms.requiredSigs;
    }

    /**
     * Signatures needed to approve an upgrade
     */
    function upgradeSigsNeeded(MultiSigStorage storage ms) public view returns (uint8) {
        require(ms.pendingUpgrade.allowedAfterTime > 0, "No pending upgrade");
        return ms.requiredSigs - ms.pendingUpgrade.approvals;
    }

    /**
     * Delegate approval to upgrade the contract logic
     */
    function delegatedApproveUpgrade(MultiSigStorage storage ms, address signer, bytes calldata sig) public {
        //make sure signer is an approver
        require(ms.approvedSigner[signer], "Unauthorized signer");

        //make sure there is a valid upgrade pending
        PendingUpgrade storage pu = ms.pendingUpgrade;
        require(pu.allowedAfterTime > 0, "No pending change for that nonce");

        //make sure signature is valid
        address check = ECDSA.recover(_asMessage(pu.sigHash), sig);
        require(check == signer, "Invalid signature");

        //then approve the upgrade
        _doApproveUpgrade(ms, signer, pu);
    }

    /**
     * Approver calling to approve logic upgrade
     */
    function approveUpgrade(MultiSigStorage storage ms) public {
        //make sure upgrade is actually pending
        PendingUpgrade storage pu = ms.pendingUpgrade;
        require(pu.allowedAfterTime > 0, "No pending change for that nonce");
        _doApproveUpgrade(ms, msg.sender, pu);
    }

    /**
     * Perform logic upgrade.
     */
    function _doApproveUpgrade(MultiSigStorage storage ms, address signer, PendingUpgrade storage pu) private {
         //make sure we haven't already upgraded
        require(ms.logic != ms.pendingUpgrade.newLogic, "Already upgraded");
        
        //make sure signer hasn't signed already
        require(!_contains(ms.signedChanges[pu.sigHash],signer), "Signer already signed");
       
        //increment approval count
        ++pu.approvals;
        bytes32 sigHash = pu.sigHash;

        //if we've reached threshold and waited long enough
        if(pu.approvals >= ms.requiredSigs && pu.allowedAfterTime < block.timestamp) {
            //perform upgrade
            doUpgrade(ms, pu);
            //remove signatures for upgrade request
            delete ms.signedChanges[sigHash];
        } else {
            //mark signer as having approved
            ms.signedChanges[sigHash].push(signer);
        }
    }

    //perform upgrade
    function doUpgrade(MultiSigStorage storage ms, PendingUpgrade storage pu) private {
        //set new logic contract address
        ms.logic = pu.newLogic;
        //remove pending upgrade
        delete ms.pendingUpgrade;

        //tell world we've upgraded
        emit LogicUpgraded(ms.logic);
    }
    //--------------------------------------------------------------------------------





    /****************************************************************************
     * Config change
     *****************************************************************************/

     /**
      * Request that a setting be changed
      */
    function requestChange(MultiSigStorage storage ms, bytes calldata data) public {
        //make sure we have a valid selector to call
        require(data.length >= 4, "Invalid call data");

        //get the selector bytes
        bytes4 sel = bytes4(data[:4]);

        //hash call data with unique op nonce and chain
        bytes32 sigHash = keccak256(abi.encode(data, ms.nonce, block.chainid));

        //mark caller as already approved
        ms.signedChanges[sigHash].push(msg.sender);
        
        //expire after timelock
        uint exp = block.timestamp + ms.timelockSeconds;
        ms.pendingChanges[ms.nonce] = PendingChange({
            approvals: 1, //presumably the caller making the request is checked before lib used
            sigHash: sigHash,
            selector: sel,
            fnData: data,
            allowedAfterTime: exp
        });

        //emit the event of the requested change
        emit ChangeRequested(msg.sender, sel, sigHash, ms.nonce, exp);

        //make nonce unique for next run (after event emitted so everyone knows which nonce
        //the change applies to)
        ++ms.nonce;
    }

    /**
     * Cancel a specific change request
     */
    function cancelChange(MultiSigStorage storage ms, uint nonce) public {
        delete ms.pendingChanges[nonce];
    }

    /**
     * Whether we can apply a specific change
     */
    function canApplyChange(MultiSigStorage storage ms, uint nonce) public view   {
        PendingChange storage pc = ms.pendingChanges[nonce];
        //pending change is still pending
        require(pc.allowedAfterTime > 0, "No pending change for that nonce");
        //and we've waited long enough with one more sig to go
        require(pc.allowedAfterTime < block.timestamp && 
            pc.approvals + 1 >= ms.requiredSigs, "Not able to apply yet");
    }

    /**
     * The number of signatures required to apply a specific change
     */
    function changeSigsNeeded(MultiSigStorage storage ms, uint nonce) public view returns (uint) {
        //make sure valid change
        PendingChange storage pc = ms.pendingChanges[nonce];
        require(pc.allowedAfterTime > 0, "No pending change for nonce");
    
        return ms.requiredSigs - pc.approvals;
    }

    /**
     * Delegated approval for a specific change
     */
    function delegatedApproveChange(MultiSigStorage storage ms, uint nonce, address signer, bytes calldata sig) public {
        //make sure signer is authorized
        require(ms.approvedSigner[signer], "Unauthorized signer");

        //and change is still valid
        PendingChange storage pc = ms.pendingChanges[nonce];
        require(pc.allowedAfterTime > 0, "No pending change for that nonce");

        //and signer has valid signature
        address check = ECDSA.recover(_asMessage(pc.sigHash), sig);
        require(check == signer, "Invalid signature");

        //then do the change
        _doChangeApproval(ms, nonce, signer, pc);
    }

    /**
     * Approver calling to approve a specific change
     */
    function approveChange(MultiSigStorage storage ms, uint nonce) public {
        //Make sure caller is a signer
        require(ms.approvedSigner[msg.sender], "Unauthorized signer");

        //and that change is still valid
        PendingChange storage pc = ms.pendingChanges[nonce];
        require(pc.allowedAfterTime > 0, "No pending change for that nonce");

        //then apply change
        _doChangeApproval(ms, nonce, msg.sender, pc);
    }

    /**
     * Apply a pending change
     */
    function _doChangeApproval(MultiSigStorage storage ms, uint nonce, address caller, PendingChange storage pc) private {
        
        //make sure they haven't signed yet
        require(!_contains(ms.signedChanges[pc.sigHash], caller), "Already signed approval");
        
        //inrement total approvals
        ++pc.approvals;
        
        bytes4 sel = pc.selector;

        //see if we've met thresholds
        if(pc.approvals >= ms.requiredSigs && pc.allowedAfterTime < block.timestamp) {
            //mark the operation as being approved. This allows us to actually 
            //call the function that is marked with modifier checking for prior approval
            ms.approvedCalls[sel] = true;
            
            //invoke the actual function
            (bool success,bytes memory retData) = address(this).call(pc.fnData);
            if(success) {
                //only get rid of pending approval change if the call succeeded
                delete ms.pendingChanges[nonce];
                delete ms.signedChanges[pc.sigHash];
            } else {
                //otherwise, the approved call data will be retained and we can try again
                console.log("Change failed");
                console.logBytes(retData);
            }
            //no matter the outcome, always reset the approval 
            //so that no one can call the selector without approval going through
            delete ms.approvedCalls[sel];
        } else {
            //mark caller as having signed
            ms.signedChanges[pc.sigHash].push(caller);
        }
    }

    //utility function to see if an address is in an array of approvers
    function _contains(address[] storage ar, address tgt) private view returns (bool) {
        for(uint i=0;i<ar.length;i=_incr(i)) {
            if(ar[i] == tgt) {
                return true;
            }
        }
        return false;
    }

    //removes uint guard for incrementing counter
    function _incr(uint i) internal pure returns (uint) {
        unchecked { return i + 1; }
    }

    //convert sig hash to message signed by EOA/approver
    function _asMessage(bytes32 h) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", h));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/IDXBL.sol";
import "../common/LibConstants.sol";
import "./LibMultiSig.sol";

/**
 * Interface for Chainlink oracle feeds
 */
interface IPriceFeed {
    function latestRoundData() external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

/**
 * Library used for revshare vault storage and updates
 */
library LibRevshare {

    /****************************************************************************
     * Copy of events from IRevshareEvents
     *****************************************************************************/
    event ProposedDiscountChange(uint32 oldRate, uint32 newRate, uint allowedAfterTime);
    event DiscountChanged(uint32 newRate);

    event ProposedVolumeGoal(uint oldVolume, uint newVolume, uint allowedAfterTime);
    event AppliedVolumeGoal(uint newVolume);

    event ProposedMintRateChange(uint16 minThreshold, uint16 maxThreshold, uint percentage, uint allowedAfterTime);
    event MintRateChange(uint16 minThreshold, uint16 maxThreshold, uint percentage);
    
    event ProposedFeeToken(address indexed token, address indexed priceFeed, bool removal, uint allowedAfterTime);
    event FeeTokenAdded(address indexed token, address indexed priceFeed);
    event FeeTokenRemoved(address indexed token);


    /****************************************************************************
     * Initialization Config Settings
     *****************************************************************************/
    //mint rate bucket
    struct MintRateRangeConfig {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
    }

    //fee token and its associated chainlink feed
    struct FeeTokenConfig {
        address[] feeTokens;
        address[] priceFeeds;
    }

    //initialize config to intialize storage
    struct RevshareConfig {

        //the address of the wrapped native token
        address wrappedNativeToken;

        //starting volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //initial rate ranges to apply
        MintRateRangeConfig[] rateRanges;

        //set of fee token/price feed pairs to initialize with
        FeeTokenConfig feeTokenConfig;

        //multi-sig settings
        LibMultiSig.MultiSigConfig multiSigConfig;
    }

    /****************************************************************************
     * Stored Settings
     *****************************************************************************/
    //stored mint rate range
    struct MintRateRange {
        uint16 minMMVolume;
        uint16 maxMMVolume;
        uint rate;
        uint index;
    }

    //price feed for a fee token
    struct PriceFeed {
        IPriceFeed feed;
        uint8 decimals;
    }

    /**
     * Primary storage for revshare vault
     */
    struct RevshareStorage {

        //revshare pool creator
        address creator;

        //token address
        IDXBL dxbl;

        //dexible settlement
        address dexible;

        //wrapped native asset address for gas computation
        address wrappedNativeToken;

        //time before changes take effect
        uint32 timelockSeconds;

        //base volume needed to mint a single DXBL token. This increases
        //as we get closer to reaching the daily goal
        uint baseMintThreshold;

        //current daily volume adjusted each hour
        uint currentVolume;

        //to compute what hourly slots to deduct from 24hr window
        uint lastTradeTimestamp;

        //all known fee tokens. Some may be inactive
        IERC20[] feeTokens;

        //the current volume range we're operating in for mint rate
        MintRateRange currentMintRate;

        //The ranges of 24hr volume and their percentage-per-MM increase to 
        //mint a single token
        MintRateRange[] mintRateRanges;

        //hourly volume totals to adjust current volume every 24 hr slot
        uint[24] hourlyVolume;

        //fee token decimals
        mapping(address => uint8) tokenDecimals;

        //all allowed fee tokens mapped to their price feed address
        mapping(address => PriceFeed) allowedFeeTokens;
    }



    /****************************************************************************
     * Initialization functions
     *****************************************************************************/
    function initialize(RevshareStorage storage rs,
            RevshareConfig calldata config) public {

        require(rs.creator == address(0), "Already initialized");
        require(config.baseMintThreshold > 0, "Must provide a base mint threshold");
        require(config.wrappedNativeToken != address(0), "Invalid wrapped native token");

        rs.creator = msg.sender;
        rs.baseMintThreshold = config.baseMintThreshold;
        rs.wrappedNativeToken = config.wrappedNativeToken;
        
        _initializeMintRates(rs, config.rateRanges);
        _initializeFeeTokens(rs, config.feeTokenConfig);
    }


    /**
     * Initialize configured fee tokens
     */
    function _initializeFeeTokens(RevshareStorage storage rs, FeeTokenConfig calldata config) internal {
        require(config.feeTokens.length > 0 && config.feeTokens.length == config.priceFeeds.length, "Must provide equal-length arrays for fee tokens and price feeds");

        for(uint i=0;i<config.feeTokens.length;++i) {
            address token = config.feeTokens[i];
            address feed = config.priceFeeds[i];
            rs.feeTokens.push(IERC20(token));
            rs.tokenDecimals[token] = IERC20Metadata(token).decimals();
            rs.allowedFeeTokens[token] = PriceFeed({
                feed: IPriceFeed(feed),
                decimals: IPriceFeed(feed).decimals()
            });
        }
        require(rs.allowedFeeTokens[rs.wrappedNativeToken].decimals > 0, "Wrapped native asset must be a valid fee token");
    }


    /**
     * Initialize the mint rate buckets
     */
    function _initializeMintRates(RevshareStorage storage rs, MintRateRangeConfig[] calldata ranges) internal {
        require(rs.mintRateRanges.length == 0, "Already initialized rate ranges");
        for(uint i=0;i<ranges.length;++i) {
            MintRateRangeConfig calldata rc = ranges[i];
            require(rc.maxMMVolume > 0, "Max MM Volume must be > 0");
            require(rc.rate > 0, "Rate must be > 0");
            rs.mintRateRanges.push(MintRateRange({
                minMMVolume: rc.minMMVolume,
                maxMMVolume: rc.maxMMVolume,
                rate: rc.rate,
                index: i
            }));
        }
        rs.currentMintRate = rs.mintRateRanges[0];
    }

    /*************************************************************************
    * DISCOUNT CHANGES
    **************************************************************************/

    /**
     * This is really jsut a delegate to the DXBL token to set the discount rate for 
     * the token. Since the DXBL token has no timelock on its settings, it allows the
     * revshare vault to make the discount rate change only. This allows us to leverage 
     * the multi-sig timelock feature of the vault to control the discount rate of token.
     */
    function setDiscountRateBps(RevshareStorage storage rs, uint32 rate) public {
        //only minter (revshare) is allowed to set the discount rate on token contract
        rs.dxbl.setDiscountRate(rate);
        emit DiscountChanged(rate);
    }
    //END DISCOUNT CHANGES____________________________________________________________________________



    /*************************************************************************
    * FEE TOKEN CHANGES
    **************************************************************************/
    /** 
     * Adjusts fee tokens allowed by the protocol. Changes are a REPLACEMENT of fee 
     * token configuration
     */
    function setFeeTokens(RevshareStorage storage rs, FeeTokenConfig calldata details) public {
        require(details.feeTokens.length > 0 && details.feeTokens.length == details.priceFeeds.length, "Must provide equal-length arrays for fee tokens and price feeds");

        /**
         * NOTE: it's impractical right now to remove fee tokens. We may need to upgrade
         * contract logic to handle some type of deprecation period for expiring fee tokens
         * that will be removed in the future. This would allow withdraws on the token
         * but not new deposits, giving the community an opportunity to withdraw. But chances
         * are, if it's being deprecated, it's probably because there's no liquidity or a problem
         * with it.
         */
        IERC20[] memory existing = rs.feeTokens;
        for(uint i=0;i<existing.length;i = _incr(i)) {
            //if we've removed a fee token that was active
            if(!_contains(details.feeTokens, address(existing[i]))) {
                console.log("Fee token has balance", address(existing[i]));
                //we have to make sure the vault doesn't have a balance
                require(existing[i].balanceOf(address(this)) == 0, "Attempting to remove fee token that has non-zero balance");
            }
            
            delete rs.allowedFeeTokens[address(existing[i])];
            delete rs.tokenDecimals[address(existing[i])];
            emit FeeTokenRemoved(address(existing[i]));
        }

        delete rs.feeTokens;
        IERC20[] memory newTokens = new IERC20[](details.feeTokens.length);
        //current active token count in memory so that we're not updating storage in a loop
        for(uint i=0;i<details.feeTokens.length;++i) {
            address ft = details.feeTokens[i];
            address pf = details.priceFeeds[i];
            //store price feed info including cached decimal count
            rs.allowedFeeTokens[ft] = PriceFeed({
                feed: IPriceFeed(pf),
                decimals: IPriceFeed(pf).decimals()
            });
            //add fee token to array
            newTokens[i] = IERC20(ft);

            //cache decimals for tken
            rs.tokenDecimals[ft] = IERC20Metadata(ft).decimals();
            emit FeeTokenAdded(ft, pf);
        }
        rs.feeTokens = newTokens;
    }
    //END FEE TOKEN CHANGES____________________________________________________________________________



    /*************************************************************************
    * MINT RATE CHANGES
    **************************************************************************/

    /**
     * Set the mint rate buckets that control how much volume is required to mint a single
     * DXBL token. This is a REPLACEMENT to the existing rates. Make sure to account for 
     * all ranges.
     */
    function setMintRates(RevshareStorage storage rs, MintRateRangeConfig[] calldata changes) public {
        
        //replace existing ranges
        delete rs.mintRateRanges;

        //we're going to possible change the current mint rate depending on new buckets
        MintRateRange memory newCurrent = rs.currentMintRate;

        //the current 24hr volume, normalized in millions
        uint16 normalizedVolume = uint16(rs.currentVolume / LibConstants.MM_VOLUME);
        
        for(uint i=0;i<changes.length;++i) {
            MintRateRangeConfig calldata change = changes[i];
            MintRateRange memory newOne = MintRateRange({
                    minMMVolume: change.minMMVolume,
                    maxMMVolume: change.maxMMVolume,
                    rate: change.rate,
                    index: i
            });
            rs.mintRateRanges.push(newOne);
            //if the new change is in range of current volume level, it becomes the new rate
            if(change.minMMVolume <= normalizedVolume && normalizedVolume < change.maxMMVolume) {
                newCurrent = newOne;
            }
            emit MintRateChange(change.minMMVolume, change.maxMMVolume, change.rate);
        }
        rs.currentMintRate = newCurrent;
    }
    //END MINT RATE CHANGES____________________________________________________________________________

    function _incr(uint i) private pure returns (uint) {
        unchecked { return i + 1; }
    }

    function _contains(address[] memory ar, address tgt) private pure returns (bool) {
        for(uint i=0;i<ar.length;i=_incr(i)) {
            if(ar[i] == tgt) {
                return true;
            }
        }
        return false;
    }
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../common/LibConstants.sol";

/**
 * Library used for role storage and update ops
 */
library LibRoleManagement {

    //emitted when role is added
    event RoleSet(address indexed member, string role);

    //emitted when role revoked
    event RoleRevoked(address indexed member, string role);

    struct RoleStorage {
        address creator;
        uint updateId;
        mapping(string => mapping(address => bool)) roles;
    }

    function initializeRoles(RoleStorage storage rs, address roleMgr) public{
        require(rs.creator == address(0), "Already initialized");
        require(roleMgr != address(0), "Invalid owner address");
        rs.creator = msg.sender;
        setRole(rs, roleMgr, LibConstants.ROLE_MGR);
        setRole(rs, msg.sender, LibConstants.ROLE_MGR);
    }

    function setRole(RoleStorage storage rs, address member, string memory role) public   {
        rs.roles[role][member] = true;
        rs.updateId++;
        emit LibRoleManagement.RoleSet(member, role);
    }

    function setRoles(RoleStorage storage rs, address member, string[] calldata roles) public  {
        for(uint i=0;i<roles.length;++i) {
            string calldata role = roles[i];
            setRole(rs, member, role);
        }
        rs.updateId++;
    }

    function removeRole(RoleStorage storage rs, address member, string memory role) public  {
        delete rs.roles[role][member];
        rs.updateId++;
        emit LibRoleManagement.RoleRevoked(member, role);
    }

    function removeRoles(RoleStorage storage rs, address member, string[] calldata roles) public  {
        for(uint i=0;i<roles.length;++i) {
            string calldata role = roles[i];
            removeRole(rs, member, role);
        }
        ++rs.updateId;
    }

    function hasRole(RoleStorage storage rs, address member, string memory role) public view returns (bool) {
        return rs.roles[role][member];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./LibRevshare.sol";
import "../revshare/IRevshareVault.sol";
import "../common/LibConstants.sol";

import "hardhat/console.sol";

/**
 * Utilities library used by RevshareVault for computations and rate adjustments.
 */
library LibRSUtils {

    //utility to remove guard check on loop iterations
    function incr(uint i) internal pure returns (uint) {
        unchecked {
            return i + 1;
        }
    }

    /**
     * Computes total AUM in USD for all active fee tokens
     */
    function aumUSD(LibRevshare.RevshareStorage storage fs) public view returns(uint usd) {
        //for each fee token allowed in the vault
        //move to memory so we're not accessing storage in loop
        IERC20[] memory feeTokens = fs.feeTokens;
        for(uint i=0;i<feeTokens.length;i=incr(i)) {
            IERC20 ft = IERC20(feeTokens[i]);
            LibRevshare.PriceFeed storage pf = fs.allowedFeeTokens[address(ft)];
            
            //make sure fee token still active
            //get the price of the asset
            uint price = getPrice(pf);
            //use it to compute USD value
            (uint _usd,) = _toUSD(fs, ft, price, 0);
            usd += _usd;
        }

        return usd;
    }

    /**
     * Get a summary of assets in the vault
     */
    function assets(LibRevshare.RevshareStorage storage fs) public view returns (IRevshareVault.AssetInfo[] memory tokens) {
         /**
         * RISK: Must limit the fee token count to avoid miner not allowing call due to high
         * gas usage
         */

        //create in-memory structure only for active fee tokens
        tokens = new IRevshareVault.AssetInfo[](fs.feeTokens.length);

        //count offset of return tokens
        uint cnt = 0;
        
        //copy fee tokens in memory to we're not accessing storage in loop
        IERC20[] memory feeTokens = fs.feeTokens;
        for(uint i=0;i<feeTokens.length;i=incr(i)) {
            IERC20 ft = feeTokens[i];
            LibRevshare.PriceFeed storage pf = fs.allowedFeeTokens[address(ft)];

            //lookup USD price of asset in 30-dec units
            uint price = getPrice(pf);

            //convert to total usd-precision USD value
            (uint usd, uint bal) = _toUSD(fs, ft, price, 0);

            tokens[cnt] = IRevshareVault.AssetInfo({
                token: address(ft),
                balance: bal,
                usdValue: usd,
                usdPrice: (price*LibConstants.USD_PRECISION) / LibConstants.PRICE_PRECISION
            });
            ++cnt;
        }
    }

    /**
     * Get the current USD volume threshold to mint a single DXBL token
     */
    function mintRate(LibRevshare.RevshareStorage storage rs) public view returns (uint rate) {
        /**
        * formula for mint rate:
        * startingRate+(startingRate*(ratePerMM*MM_vol))
        */
        uint16 normalizedMMInVolume = uint16(rs.currentVolume / LibConstants.MM_VOLUME);

        //mint rate is a bucket with min/max volume thresholds and establishes how many 
        //percentage points per million to apply to the starting mint rate 
        uint percIncrease = rs.currentMintRate.rate * normalizedMMInVolume;

        //mint rate percentage is expressed in 18-dec units so have to divide that out before adding to base
        rate = rs.baseMintThreshold + ((rs.baseMintThreshold * percIncrease)/1e18);
    } 

    /**
     * Convert the given raw fee-token volume amount into USD units based on current price of fee token
     */
    function computeVolumeUSD(LibRevshare.RevshareStorage storage fs, address feeToken, uint amount) public view returns(uint volumeUSD) {
        LibRevshare.PriceFeed storage pf = fs.allowedFeeTokens[feeToken];

        //price is in USD with 30decimal precision
        uint ftp = getPrice(pf);

        (uint v,) = _toUSD(fs, IERC20(feeToken), ftp, amount);
        volumeUSD = v;
    }

    /**
     * Compute the Net Asset Value (NAV) for each DXBL token in circulation.
     */
    function computeNavUSD(LibRevshare.RevshareStorage storage rs) public view returns (uint nav) {
        //console.log("--------------- START COMPUTE NAV ---------------------");
        
        //get the total supply of dxbl tokens
        uint supply = rs.dxbl.totalSupply();

        //get the total USD under management by this vault
        uint aum = aumUSD(rs);

        //if either is 0, the nav is 0
        if(supply == 0 || aum == 0) {
            return 0;
        }
         
        //supply is 18decs while aum and nav are expressed in USD units
        nav = (aum*1e18) / supply;
      //  console.log("--------------- END COMPUTE NAV ---------------------");
    }

    /**
     * Adjust the vault's 24hr USD volume with the newly executed volume amount
     */
    function adjustVolume(LibRevshare.RevshareStorage storage rs, uint volumeUSD) public {
        //get the current hour
        uint lastTrade = rs.lastTradeTimestamp;

        //record when we last adjusted volume
        rs.lastTradeTimestamp = block.timestamp;
        uint newVolume = volumeUSD;
        if(lastTrade > 0 && lastTrade <= (block.timestamp - LibConstants.DAY)) {
            delete rs.hourlyVolume;
        } else {
            //otherwise, since we never rolled over 24hrs, just delete the volume
            //that accrued 24hrs ago
            uint hr = (block.timestamp % LibConstants.DAY) / LibConstants.HOUR;
            uint slot = 0;
            //remove guard for some efficiency gain
            unchecked{slot = (hr+1)%24; }

            //get the volume bin 24hrs ago by wrapping around to next hour in 24hr period
            uint yesterdayTotal = rs.hourlyVolume[slot];

            //if we get called multiple times in the block, the same hourly total
            //would be deducted multiple times. So we reset it here so that we're 
            //not deducting it multiple times in the hour. Only the first deduction
            //will be applied and 0'd out.
            rs.hourlyVolume[slot] = 0;

            //add new volume to current hour bin
            rs.hourlyVolume[hr] += volumeUSD;

            //manipulate volume in memory not storage
            newVolume = rs.currentVolume + volumeUSD;

            //Remove volume from 24hr's ago if there was anything
            if(yesterdayTotal > 0) {
                //note that because currentVolume includes yesterday's, then this subtraction 
                //is safe.
                newVolume -= yesterdayTotal;
            } 
        }
        rs.currentVolume = newVolume;
        _adjustMintRate(rs, uint16(newVolume / LibConstants.MM_VOLUME));
    }

    /**
     * Get the price of an asset by calling its chainlink price feed
     */
    function getPrice(LibRevshare.PriceFeed storage pf) public view returns (uint) {
        
        //get latest price
        (   ,
            int256 answer,
            ,
            uint256 updatedAt,
        ) = pf.feed.latestRoundData();

        //make sure price valid
        require(answer > 0, "No price data available");

        //10min buffer around 24hr window for chainlink feed to update prices
        uint stale = block.timestamp - LibConstants.DAY - 600;
        require(updatedAt > stale, "Stale price data");
        return (uint256(answer) * LibConstants.PRICE_PRECISION) / (10**pf.decimals);
    }

    /**
     * Convert an assets total balance to USD
     */
    function _toUSD(LibRevshare.RevshareStorage storage fs, IERC20 token, uint price, uint amt) internal view returns(uint usd, uint bal) {
        bal = amt;
        if(bal == 0) {
            bal = token.balanceOf(address(this));
        }
        
        //compute usd in raw form (fee-token units + price-precision units) but account for
        //USD precision
        usd = (bal * price)*LibConstants.USD_PRECISION;

        //then divide out the fee token and price-precision units
        usd /= (10**fs.tokenDecimals[address(token)]*LibConstants.PRICE_PRECISION);
        
    }

    /**
     * Make an adjustment to the mint rate if the 24hr volume falls into a new rate bucket
     */
    function _adjustMintRate(LibRevshare.RevshareStorage storage rs, uint16 normalizedMMInVolume) internal {
        
        LibRevshare.MintRateRange memory mr = rs.currentMintRate;
        //if the current rate bucket's max is less than current normalized volume
        if(mr.maxMMVolume <= normalizedMMInVolume) {
            //we must have increased volume so we have to adjust the rate up
            _adjustMintRateUp(rs, normalizedMMInVolume);
            //otherwise if the current rate's min is more than the current volume
        } else if(mr.minMMVolume >= normalizedMMInVolume) {
            //it means we're trading less volume than the current rate, so we need
            //to adjust it down
            _adjustMintRateDown(rs, normalizedMMInVolume);
        } //else rate stays the same
    }

    /**
     * Increase the minimum volume required to mint a single token
     */
    function _adjustMintRateUp(LibRevshare.RevshareStorage storage rs, uint16 mm) internal {
        LibRevshare.MintRateRange memory mr = rs.currentMintRate;
        while(!_rateInRange(mr,mm)) {
            //move to the next higher rate if one is configured, otherwise stay where we are
            LibRevshare.MintRateRange storage next = rs.mintRateRanges[mr.index + 1];
            if(next.rate == 0) {
                //reached highest rate, that will be the capped rate 
                break;
            }
            mr = next;
        }

        //don't waste gas storing if not changed
        if(rs.currentMintRate.rate != mr.rate) {
            rs.currentMintRate = mr;
        }
        
    }
    
    /**
     * Decrease minimum volume required to mint a DXBL token
     */
    function _adjustMintRateDown(LibRevshare.RevshareStorage storage rs, uint16 mm) internal {
        LibRevshare.MintRateRange memory mr = rs.currentMintRate;
        while(!_rateInRange(mr,mm)) {
            if(mr.index > 0) {
                //move to the next higher rate if one is configured, otherwise stay where we are
                LibRevshare.MintRateRange storage next = rs.mintRateRanges[mr.index - 1];
                mr = next;
            } else {
                //we go to the lowest rate then
                break;
            }
        }
        rs.currentMintRate = mr;
    }

    //test to see if volume is range for a rate bucket
    function _rateInRange(LibRevshare.MintRateRange memory range, uint16 mm) internal pure returns (bool) {
        return range.minMMVolume <= mm && mm < range.maxMMVolume;
    }
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./LibRoleManagement.sol";
import "./LibDexible.sol";
import "./LibRevshare.sol";
import "./LibMultiSig.sol";

library LibStorage {
    bytes32 constant ROLE_STORAGE_KEY = 0xeaae66d228e19ff3fd9a03e3c23ae62eb7fb45b5ce2ee3b6fbdc8dd6b661c819;

    bytes32 constant DEXIBLE_STORAGE_KEY = 0x949817a987a8e038ef345d3c9d4fd28e49d8e4e09456e57c05a8b2ce2e62866c;

    bytes32 constant REVSHARE_STORAGE_KEY = 0xbfa76ec2967ed7f8d3d40cd552f1451ab03573b596bfce931a6a016f7733078c;

    bytes32 constant MULTI_SIG_STORAGE = 0x95345cad9ec96dfc8c5b0a875a5c498451c293011b6404d5fac2627c08bc661c;

    function getRoleStorage() internal pure returns (LibRoleManagement.RoleStorage storage rs) {
        assembly { rs.slot := ROLE_STORAGE_KEY }
    }

    function getDexibleStorage() internal pure returns (LibDexible.DexibleStorage storage ds) {
        assembly { ds.slot := DEXIBLE_STORAGE_KEY }
    }

    function getRevshareStorage() internal pure returns (LibRevshare.RevshareStorage storage rs) {
        assembly { rs.slot := REVSHARE_STORAGE_KEY }
    }

    function getMultiSigStorage() internal pure returns (LibMultiSig.MultiSigStorage storage es) {
        assembly { es.slot := MULTI_SIG_STORAGE }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "../libraries/LibStorage.sol";
import "../libraries/LibRevshare.sol";
import "../common/LibConstants.sol";
import "../common/MultiSigConfigurable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * Configuration settings for RevshareVault. This applies multi-sig functionality by extending
 * base multi-sig contract.
 */
abstract contract ConfigurableRS is MultiSigConfigurable {

    using LibRevshare for LibRevshare.RevshareStorage;

    /**
     * Initialize revshare vault settings. This can only be called once after deployment of
     * proxy.
     */
    function initialize(LibRevshare.RevshareConfig calldata config) public {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();

        //init revshare settings
        rs.initialize(config);

        //init multi-sig settings
        super.initializeMSConfigurable(config.multiSigConfig);
    }

    /*************************************************************************
    * Set the DXBL token contract. One time only
    **************************************************************************/
    function setDXBL(address token) public onlyApprover {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        require(token != address(0), "Invalid DXBL token address");
        require(address(rs.dxbl) == address(0), "Already initialized DXBL address");
        rs.dxbl = IDXBL(token);
    }

    //read the current DXBL token setting
    function getDXBLToken() public view returns(address) {
        return address(LibStorage.getRevshareStorage().dxbl);
    }

    /*************************************************************************
    * Set the Dexible contract. One time only
    **************************************************************************/
    function setDexible(address dex) public onlyApprover {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        require(rs.dexible == address(0), "Already initialized Dexible address");
        require(dex != address(0), "Invalid dexible address");
        rs.dexible = dex;
    }

    //get the dexible contract address
    function getDexibleContract() public view returns (address) {
        return address(LibStorage.getRevshareStorage().dexible);
    }

    /*************************************************************************
    * DISCOUNT CHANGES
    **************************************************************************/

    /**
     * Set a new discount rate for DXBL tokens but only after multi-sig approval and timelock
     */
    function setDiscountRateBps(uint32 bps) public afterApproval(this.setDiscountRateBps.selector) {
        LibStorage.getRevshareStorage().setDiscountRateBps(bps);
    }
    //END DISCOUNT CHANGES____________________________________________________________________________

    /*************************************************************************
    * FEE TOKEN CHANGES
    **************************************************************************/

    /**
     * Set the fee tokens for the vault but only after approval and timelock. This REPLACES
     * all allowed fee tokens.
     */
    function setFeeTokens(LibRevshare.FeeTokenConfig calldata details) public afterApproval(this.setFeeTokens.selector) {
        LibStorage.getRevshareStorage().setFeeTokens(details);
    }
    //END FEE TOKEN CHANGES____________________________________________________________________________


    /*************************************************************************
    * MINT RATE CHANGES
    **************************************************************************/
    /**
     * Set the mint rate buckets that determine minimum volume for a single DXBL token
     */
    function setMintRates(LibRevshare.MintRateRangeConfig[] calldata ranges) public afterApproval(this.setMintRates.selector) {
        LibStorage.getRevshareStorage().setMintRates(ranges);
    }
    //END MINT RATE CHANGES____________________________________________________________________________

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IRevshareEvents {

    event ProposedDiscountChange(uint32 oldRate, uint32 newRate, uint allowedAfterTime);
    event DiscountChanged(uint32 newRate);

    event ProposedBpsChange(uint32 oldStdRate, uint32 newStdRate, uint32 oldMinRate, uint32 newMinRate, uint allowedAfterTime);
    event BpsChanged(uint32 stdRate, uint32 minRate);

    event ProposedVolumeGoal(uint oldVolume, uint newVolume, uint allowedAfterTime);
    event AppliedVolumeGoal(uint newVolume);

    event ProposedMintRateChange(uint16 minThreshold, uint16 maxThreshold, uint percentage, uint allowedAfterTime);
    event MintRateChange(uint16 minThreshold, uint16 maxThreshold, uint percentage);
    
    event ProposedFeeToken(address indexed token, address indexed priceFeed, bool removal, uint allowedAfterTime);
    event FeeTokenAdded(address indexed token, address indexed priceFeed);
    event FeeTokenRemoved(address indexed token);
    event  DXBLRedeemed(address holder, uint dxblAmount, address rewardToken, uint rewardAmount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IRevshareEvents.sol";

interface IRevshareVault is IRevshareEvents {

    struct AssetInfo {
        address token;
        uint balance;
        uint usdValue;
        uint usdPrice;
    }

    function isFeeTokenAllowed(address tokens) external view returns (bool);
    function currentMintRateUSD() external view returns (uint);
    function currentNavUSD() external view returns(uint);
    function discountBps() external view returns(uint32);
    function dailyVolumeUSD() external view returns(uint);
    function aumUSD() external view returns(uint);
    function feeTokenPriceUSD(address feeToken) external view returns (uint);
    function convertGasToFeeToken(address feeToken, uint gasCost) external view returns (uint);
    function assets() external view returns (AssetInfo[] memory);
    function rewardTrader(address trader, address feeToken, uint amount) external;
    function estimateRedemption(address feeToken, uint dxblAmount) external view returns(uint);
    function redeemDXBL(address feeToken, uint dxblAmount, uint minOutAmount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./IRevshareVault.sol";
import "../libraries/LibStorage.sol";
import "../common/LibConstants.sol";
import "../libraries/LibRSUtils.sol";
import "./ConfigurableRS.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * The revshare vault is responsible for tracking 24hr volume levels for Dexible, computing
 * current Net Asset Value (NAV) of each token in circulation, minting DXBL tokens according
 * to volume threshold buckets, and redeeming DXBL for a portion of the vault's holdings.
 *
 * The vault has minting authority to the DXBL token and is the only way to create and
 * burn DXBL tokens.
 */
contract RevshareVault is ConfigurableRS, IRevshareVault {

    using LibRSUtils for LibRevshare.RevshareStorage;
    using SafeERC20 for IERC20;

    //makes sure only the Dexible contract can call a function
    modifier onlyDexible() {
        require(msg.sender == LibStorage.getRevshareStorage().dexible, "Unauthorized");
        _;
    }

    /**
     * Check whether a fee tokens is allowed to pay for fees
     */
    function isFeeTokenAllowed(address token) external override view returns(bool) {
        return address(LibStorage.getRevshareStorage().allowedFeeTokens[token].feed) != address(0);
    }

    /**
     * Get the current minimum volume required to mint a DXBL token. This is returned
     * in USD precision units (see LibConstants for that value but is likely 6-decimals)
     */
    function currentMintRateUSD() external override view returns (uint rate) {
        return LibStorage.getRevshareStorage().mintRate();
    }

    /**
     * Get the current NAV for each DXBL token in circulation. This is returned in 
     * USD precision units (see LibConstants but is likely 6 decimals)
     */
    function currentNavUSD() external view override returns(uint) {
        return LibStorage.getRevshareStorage().computeNavUSD();
    }

    /**
     * Get the current discount applied per DXBL token owned. This is a bps 
     * setting so 5 means 5 bps or .05%
     */
    function discountBps() external view override returns(uint32) {
        return LibStorage.getRevshareStorage().dxbl.discountPerTokenBps();
    }

    /**
     * Compute the total USD value of assets held in the vault.
     */
    function aumUSD() external view returns(uint) {
        return LibStorage.getRevshareStorage().aumUSD();
    }

    /**
     * Get details of assets held by the vault.
     */
    function assets() external view override returns (AssetInfo[] memory) {
        return LibStorage.getRevshareStorage().assets();
    }

    /**
     * Compute the USD volume traded in the last 24hrs
     */
    function dailyVolumeUSD() external view override returns (uint) {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        return rs.currentVolume;
    }

    /**
     * Get the USD price for a fee token
     */
    function feeTokenPriceUSD(address feeToken) external view override returns(uint) {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        LibRevshare.PriceFeed storage pf = rs.allowedFeeTokens[feeToken];
        require(address(pf.feed) != address(0), "Unsupported fee token");
        return LibRSUtils.getPrice(pf);
    }

    /**
     * Convert gas units to fee token units using oracle prices for native asset
     */
    function convertGasToFeeToken(address feeToken, uint gasCost) external view override returns(uint) {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        if(feeToken == rs.wrappedNativeToken) {
            //already in native units
            return gasCost;
        }
        uint np = LibRSUtils.getPrice(rs.allowedFeeTokens[rs.wrappedNativeToken]);
        uint ftp = LibRSUtils.getPrice(rs.allowedFeeTokens[feeToken]);
        uint ftpNative = (np*LibConstants.PRICE_PRECISION)/ftp;
        uint ftpUnits = (ftpNative * gasCost) / LibConstants.PRICE_PRECISION;
        return (ftpUnits * (10**rs.tokenDecimals[feeToken])) / 1e18; //native is always 18decs
    }

    /**
     * Estimate how much of a fee token will be withdrawn given a balance of DXBL tokens.
     */
    function estimateRedemption(address rewardToken, uint dxblAmount) external override view returns(uint) {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        uint nav = rs.computeNavUSD();
         //convert nav to price-precision units
        nav = (nav * LibConstants.PRICE_PRECISION) / LibConstants.USD_PRECISION;
        
        //we need to know the value of each token in rewardToken units
        //start by getting the USD price of reward token
        uint ftUSD = this.feeTokenPriceUSD(rewardToken);

        uint8 ftDecs = rs.tokenDecimals[rewardToken];

        //Divide nav of each token by the price of each reward token expanding 
        //precision to include the fee-token decimals
        uint ftUnitPrice = (nav*(10**ftDecs))/ftUSD;

        //compute how much rewardToken to withdraw based on unit price of each DXBL
        //in fee-token units. Have to remove the dexible token precision (18)
        return (dxblAmount * ftUnitPrice)/1e18;
    }

    /**
     * Assume fee token has been vetted prior to making this call. Since only called by Dexible,
     * easy to verify that assumption.
     */
    function rewardTrader(address trader, address feeToken, uint amount) external override onlyDexible notPaused {
        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        uint volumeUSD = rs.computeVolumeUSD(feeToken, amount);

        //determine the mint rate
        uint rate = rs.mintRate();

        //make the volume adjustment to the pool
        rs.adjustVolume(volumeUSD);

        //get the number of DXBL per $1 of volume
        uint tokens = (volumeUSD*1e18) / rate;

        rs.dxbl.mint(trader, tokens);
    }
    
    /**
     * Redeem or burn DXBL for a specific reward token. The min amount reflects any slippage
     * that could occur if someone withdraws the same asset before a trader and the balance
     * cannot cover both withdraws.
     */
    function redeemDXBL(address rewardToken, uint dxblAmount, uint minOutAmount) external override notPaused {

        LibRevshare.RevshareStorage storage rs = LibStorage.getRevshareStorage();
        //get the trader's balance to make sure they actually have tokens to burn
        uint traderBal = rs.dxbl.balanceOf(msg.sender);
        require(traderBal >= dxblAmount, "Insufficient DXBL balance to redeem");
        
        //estimate how much we could withdraw if there is sufficient reward tokens available
        uint wdAmt = this.estimateRedemption(rewardToken, dxblAmount);

        /**
        * NOTE: is it likely that there will be dust remaining for the asset due to USD
        * rounding/precision.
        *
        * It will be redeemable once the balance acrues enough for the
        * next burn request
        */

        //how much does the vault own?
        uint vaultBal = IERC20(rewardToken).balanceOf(address(this));

        //do we have enough to cover the withdraw?
        if(wdAmt > vaultBal) {
            //vault doesn't have sufficient funds to cover. See if meets trader's 
            //min expectations
            if(vaultBal >= minOutAmount) {
                wdAmt = vaultBal;
            } else {
                revert("Insufficient asset balance to produce expected withdraw amount");
            }
        }
        //if all good, transfer withdraw amount to caller
        IERC20(rewardToken).safeTransfer(msg.sender, wdAmt);

        //burn the tokens
        rs.dxbl.burn(msg.sender, dxblAmount);
        emit DXBLRedeemed(msg.sender, dxblAmount, rewardToken, wdAmt);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDXBL is IERC20, IERC20Metadata {
    struct FeeRequest {
        bool referred;
        address trader;
        uint amt;
        uint dxblBalance;
        uint16 stdBpsRate;
        uint16 minBpsRate;
    }

    function minter() external view returns (address);
    function discountPerTokenBps() external view returns(uint32);

    function mint(address acct, uint amt) external;
    function burn(address holder, uint amt) external;
    function setDiscountRate(uint32 discount) external;
    function computeDiscountedFee(FeeRequest calldata request) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}