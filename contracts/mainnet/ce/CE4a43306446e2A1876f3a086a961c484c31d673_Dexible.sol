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

import "./TokenTypes.sol";

/**
 * These types only relevant for relay-based submissions through protocol
 */
library ExecutionTypes {

    /**
     * Basic fee information which includes any payments to be made to affiliates.
     */
    struct FeeDetails {

        //the fee token to pay
        IERC20 feeToken;

        //affiliate address to pay affiliate fee
        address affiliate;

        //fee to pay affiliate
        uint affiliatePortion;
    }

    /**
     * Shared information in every execution request. This will evolve 
     * over time to support signatures and privacy proofs as the protocol
     * decentralizes
     */
    struct ExecutionRequest {
        //account requesting this execution
        address requester;

        //fees info
        FeeDetails fee;
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

import "./TokenTypes.sol";
import "./ExecutionTypes.sol";

/**
 * Swap data strutures to submit for execution
 */
library SwapTypes {

    /**
     * Individual router called to execute some action. Only approved 
     * router addresses will execute successfully
     */
    struct RouterRequest {
        //router contract that handles the specific route data
        address router;

        //any spend allowance approval required
        address spender;

        //the amount to send to the router
        TokenTypes.TokenAmount routeAmount;

        //the data to use for calling the router
        bytes routerData;
    }

    /**
     * Swap request that is restricted to only relay-based executions. This prevents
     * applying discounts through sybil attacks and affiliate addresses.
     */
    struct SwapRequest {

        //general execution request details
        ExecutionTypes.ExecutionRequest executionRequest;

        //input token and amount
        TokenTypes.TokenAmount tokenIn;

        //expected min output and amount
        TokenTypes.TokenAmount tokenOut;

        //array of routes to call to perform swaps
        RouterRequest[] routes;
    }

    /**
     * This is used when the caller is also the trader.
     */
    struct SelfSwap {
        //fee token paying in
        IERC20 feeToken;

        //input token and full amount
        TokenTypes.TokenAmount tokenIn;

        //output token and minimum amount out expected
        TokenTypes.TokenAmount tokenOut;

        //the routers to call
        RouterRequest[] routes;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenTypes {

    /**
     * Wrapper structure for token and an amount
     */
    struct TokenAmount {
        uint112 amount;
        IERC20 token;
    }
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./DexibleRoleManagement.sol";
import "../common/MultiSigConfigurable.sol";
import "./IDexible.sol";

/**
 * Base contract to add configuration options for Dexible contract. All config settings
 * require multi-sigs since we extend the MultiSigConfigurable contract. 
 */
abstract contract ConfigurableDexible is IDexible, MultiSigConfigurable, DexibleRoleManagement {

    using LibDexible for LibDexible.DexibleStorage;
    
    /**
     * Get the current BPS fee rates
     */
    function bpsRates() public view returns (LibDexible.BpsFeeChange memory) {
        return LibDexible.BpsFeeChange({
            stdBps: LibStorage.getDexibleStorage().stdBpsRate,
            minBps: LibStorage.getDexibleStorage().minBpsRate
        });
    }

    /**
     * Set a new bps rate after approval and timelock
     */
    function setNewBps(LibDexible.BpsFeeChange calldata changes) public afterApproval(this.setNewBps.selector) {
        LibStorage.getDexibleStorage().setNewBps(changes);
    }

    /**
     * Get the address for the RevshareVault
     */
    function revshareVault() public view returns (address) {
        return LibStorage.getDexibleStorage().revshareManager;
    }

    /**
     * Set the address of the revshare vault after approval and timelock
     */
    function setRevshareVault(address t) public afterApproval(this.setRevshareVault.selector) {
        LibStorage.getDexibleStorage().setRevshareVault(t);
    }

    /**
     * Get the amount of BPS fee going to the RevshareVault (expressed as whole percentage i.e. 50 = 50%)
     */
    function revshareSplit() public view returns (uint8) {
        return LibStorage.getDexibleStorage().revshareSplitRatio;
    }

    /**
     * Set the revshare split percentage after approval and timelock
     */
    function setRevshareSplit(uint8 split) public afterApproval(this.setRevshareSplit.selector) {
        LibStorage.getDexibleStorage().setRevshareSplit(split);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ConfigurableDexible.sol";
import "../libraries/LibStorage.sol";
import "./extensions/SwapExtension.sol";

/**
 * Dexible is the core contract used by the protocol to execution various actions. Swapping,
 * heding, staking, etc. are all handled through the Dexible contract. The contract is also
 * coupled to the RevshareVault in that only this contract can request that tokens be rewarded
 * to users.
 */
contract Dexible is ConfigurableDexible {

    //used for trycatch calls
    modifier onlySelf() {
        require(msg.sender == address(this), "Internal call only");
        _;
    }
    using SwapExtension for SwapTypes.SwapRequest;
    using LibDexible for LibDexible.DexibleStorage;
    using SafeERC20 for IERC20;


    /**
     * Initialize Dexible with config settings. This can only be called once after
     * deployment.
     */
    function initialize(LibDexible.DexibleConfig calldata config) public {
        //initialize dexible storage settings
        LibDexible.initialize(LibStorage.getDexibleStorage(), config);

        //initialize key roles
        LibRoleManagement.initializeRoles(LibStorage.getRoleStorage(), config.roleManager);

        //initialize multi-sig settings
        super.initializeMSConfigurable(config.multiSigConfig);
    }

    /**
     * Set the treasury to send share of revenue and gas fees after approval and timeout
     */
    function setTreasury(address t) external override afterApproval(this.setTreasury.selector) {
        LibDexible.DexibleStorage storage ds = LibStorage.getDexibleStorage();
        require(t != address(0), "Invalid treasury address");
        ds.treasury = t;
    }

    /**
     * Main swap function that is only callable by Dexible relays. This version of swap 
     * accounts for affiliate rewards and discounts.
     */
    function swap(SwapTypes.SwapRequest calldata request) external onlyRelay notPaused {
        //console.log("----------------------------- START SWAP ------------------------");
       
        //compute how much gas we have at the outset, plus some gas for loading contract, etc.
        uint startGas = gasleft() + LibConstants.PRE_OP_GAS;
        SwapExtension.SwapDetails memory details = SwapExtension.SwapDetails({
            feeIsInput: false,
            isSelfSwap: false,
            startGas: startGas,
            bpsAmount: 0,
            gasAmount: 0,
            nativeGasAmount: 0,
            toProtocol: 0,
            toRevshare: 0,
            outToTrader: 0,
            preDXBLBalance: 0,
            outAmount: 0,
            remainingInBalance: 0
        });

        bool success = false;
        //execute the swap but catch any problem
        try this._trySwap{
            gas: gasleft() - LibConstants.POST_OP_GAS
        }(request, details) returns (SwapExtension.SwapDetails memory sd) {
            details = sd;
            success = true;
        } catch {
            console.log("Swap failed");
            success = false;
        }

        request.postFill(details, success);
        //console.log("----------------------------- END SWAP ------------------------");
        
    }

    /**
     * This version of swap can be called by anyone. The caller becomes the trader
     * and they pay all gas fees themselves. This is needed to prevent sybil attacks
     * where traders can provide their own affiliate address and get discounts.
     */
    function selfSwap(SwapTypes.SelfSwap calldata request) external notPaused {
        //we create a swap request that has no affiliate attached and thus no
        //automatic discount.
        SwapTypes.SwapRequest memory swapReq = SwapTypes.SwapRequest({
            executionRequest: ExecutionTypes.ExecutionRequest({
                fee: ExecutionTypes.FeeDetails({
                    feeToken: request.feeToken,
                    affiliate: address(0),
                    affiliatePortion: 0
                }),
                requester: msg.sender
            }),
            tokenIn: request.tokenIn,
            tokenOut: request.tokenOut,
            routes: request.routes
        });
        SwapExtension.SwapDetails memory details = SwapExtension.SwapDetails({
            feeIsInput: false,
            isSelfSwap: true,
            startGas: 0,
            bpsAmount: 0,
            gasAmount: 0,
            nativeGasAmount: 0,
            toProtocol: 0,
            toRevshare: 0,
            outToTrader: 0,
            preDXBLBalance: 0,
            outAmount: 0,
            remainingInBalance: 0
        });
        details = swapReq.fill(details);
        swapReq.postFill(details, true);
    }

    function _trySwap(SwapTypes.SwapRequest memory request, SwapExtension.SwapDetails memory details) external onlySelf returns (SwapExtension.SwapDetails memory) {
        return request.fill(details);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../libraries/LibStorage.sol";
import "../libraries/LibRoleManagement.sol";
import "../common/LibConstants.sol";

import "hardhat/console.sol";

/**
 * Role management base contract that manages certain key roles for Dexible contract.
 */
abstract contract DexibleRoleManagement {

    //emitted when role is added
    event RoleSet(address indexed member, string role);

    //emitted when role revoked
    event RoleRevoked(address indexed member, string role);

    using LibRoleManagement for LibRoleManagement.RoleStorage;

    modifier onlyRelay() {
        require(LibStorage.getRoleStorage().hasRole(msg.sender, LibConstants.RELAY), "Unauthorized relay");
        _;
    }

    modifier onlyCreator() {
        require(LibStorage.getRoleStorage().creator == msg.sender, "Unauthorized");
        _;
    }

    modifier onlyRoleManager() {
        require(hasRole(msg.sender, LibConstants.ROLE_MGR), "Unauthorized");
        _;
    }

    function addRelay(address relay) public {
        setRole(relay, LibConstants.RELAY);
    }

    function addRelays(address[] calldata relays) public {
        for(uint i=0;i<relays.length;++i) {
            setRole(relays[i], LibConstants.RELAY);
        }
    }

    function removeRelay(address relay) public {
        removeRole(relay, LibConstants.RELAY);
    }

    function isRelay(address relay) public view returns(bool) {
        return hasRole(relay, LibConstants.RELAY);
    }

    function setRole(address member, string memory role) public onlyRoleManager {
         LibStorage.getRoleStorage().setRole(member, role);
    }

    function setRoles(address member, string[] calldata roles) public onlyRoleManager {
         LibStorage.getRoleStorage().setRoles(member, roles);
    }

    function removeRole(address member, string memory role) public onlyRoleManager {
         LibStorage.getRoleStorage().removeRole(member, role);
    }

    function removeRoles(address member, string[] calldata roles) public onlyRoleManager {
         LibStorage.getRoleStorage().removeRoles(member, roles);
    }

    function hasRole(address member, string memory role) public view returns (bool) {
        return  LibStorage.getRoleStorage().hasRole(member, role);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


import "../../libraries/LibStorage.sol";
import "../../common/SwapTypes.sol";
import "../../common/LibConstants.sol";
import "../../revshare/IRevshareVault.sol";
import "../../libraries/LibFees.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

/**
 * Dexible will eventually support multiple types of executions. The swap logic is handled 
 * by this extension library that handles checking for swap details and calling routers
 * with specified input.
 */
library SwapExtension {
    using SafeERC20 for IERC20;

    event SwapFailed(address indexed trader, 
                     IERC20 feeToken, 
                     uint gasFeePaid);
    event SwapSuccess(address indexed trader,
                        address indexed affiliate,
                        uint inputAmount,
                        uint outputAmount,
                        IERC20 feeToken,
                        uint gasFee,
                        uint affiliateFee,
                        uint dexibleFee);
    event AffiliatePaid(address indexed affiliate, IERC20 token, uint amount);
    event PaidGasFunds(address indexed relay, uint amount);
    event InsufficientGasFunds(address indexed relay, uint amount);

    /**
     * NOTE: These gas settings are used to estmate the total gas being used
     * to execute a transaction. Because solidity provides no way to determine
     * the actual gas used until the txn is mined, we have to add buffer gas 
     * amount to account for post-gas-fee computation logic.
     */

    

    //final computation needed to compute and transfer gas fees
    uint constant POST_OP_GAS = 80_000;

    struct SwapDetails {
        bool feeIsInput;
        bool isSelfSwap;
        uint startGas;
        uint toProtocol;
        uint toRevshare;
        uint outToTrader;
        uint outAmount;
        uint bpsAmount;
        uint gasAmount;
        uint nativeGasAmount;
        uint preDXBLBalance;
        uint remainingInBalance;
    }

    function fill(SwapTypes.SwapRequest calldata request, SwapDetails memory details) public returns (SwapDetails memory) {
        preCheck(request, details);
        details.outAmount = request.tokenOut.token.balanceOf(address(this));
        preFill(request);

        for(uint i=0;i<request.routes.length;++i) {
            SwapTypes.RouterRequest calldata rr = request.routes[i];
            IERC20(rr.routeAmount.token).safeApprove(rr.spender, rr.routeAmount.amount);
            (bool s, ) = rr.router.call(rr.routerData);

            if(!s) {
                revert("Failed to swap");
            }
        }
        uint out = request.tokenOut.token.balanceOf(address(this));
        if(details.outAmount < out) {
            details.outAmount = out - details.outAmount;
        } else {
            details.outAmount = 0;
        }
        
        console.log("Expected", request.tokenOut.amount, "Received", details.outAmount);
        //first, make sure enough output was generated
        require(details.outAmount >= request.tokenOut.amount, "Insufficient output generated");
        return details;
    }

    function postFill(SwapTypes.SwapRequest calldata request, SwapDetails memory details, bool success) public  {

        //get post-swap balance so we know how much refund if we didn't spend all
        uint cBal = request.tokenIn.token.balanceOf(address(this));

        //deliberately setting remaining balance to 0 if less amount than current balance.
        //this will force an underflow exception if we attempt to deduct more fees than
        //remaining balance
        details.remainingInBalance = cBal > details.remainingInBalance ? cBal - details.remainingInBalance : 0;

        console.log("Remaining input balance", details.remainingInBalance);

        if(success) {
            //if we succeeded, then do successful post-swap ops
            handleSwapSuccess(request, details); 
        }  else {
            //otherwise, handle as a failure
            handleSwapFailure(request, details);
        }
        //console.log("Total gas use for relay payment", totalGasUsed);
        //pay the relayer their gas fee if we have funds for it
        payRelayGas(details.nativeGasAmount);
    }

    /**
     * When a relay-based swap fails, we need to account for failure gas fees if the input
     * token is the fee token. That's what this function does
     */
    function handleSwapFailure(SwapTypes.SwapRequest calldata request, SwapDetails memory details) public {
        //compute fees for failed txn
        if(details.isSelfSwap) {
            revert("Swap failed");
        }
        
        //trader still owes the gas fees to the treasury/relay even though the swap failed. This is because
        //the trader may have set slippage too low, or other problems thus increasing the chance of failure.
        
        //compute gas fee in fee-token units
        unchecked { 
            //the total gas used thus far plus some post-op stuff that needs to get done
            uint totalGas = (details.startGas - gasleft()) + 40000;
            
            console.log("Estimated gas used for trader gas payment", totalGas);
            details.nativeGasAmount = (totalGas * tx.gasprice);
        }
        uint gasInFeeToken = LibFees.computeGasFee(request, details.nativeGasAmount);
        if(details.feeIsInput) {
            console.log("Transferring partial input token to devteam for failure gas fees");
            
            console.log("Failed gas fee", gasInFeeToken);

            //transfer input assets to treasury
            request.executionRequest.fee.feeToken.safeTransferFrom(request.executionRequest.requester, LibStorage.getDexibleStorage().treasury, gasInFeeToken);
            
            emit SwapFailed(request.executionRequest.requester, request.executionRequest.fee.feeToken, gasInFeeToken);
        } else {
            //otherwise, if not the input token, unfortunately, Dexible treasury eats the cost.
            console.log("Fee token is output; therefore cannot reimburse team for failure gas fees");
            emit SwapFailed(request.executionRequest.requester, request.executionRequest.fee.feeToken, 0);
        }
    }

    /**
     * This is called when a relay-based swap is successful. It basically rewards DXBL tokens
     * to trader and pays appropriate fees.
     */
    function handleSwapSuccess(SwapTypes.SwapRequest calldata request, 
                SwapDetails memory details) public {
        
        
        //reward trader with DXBL tokens
        collectDXBL(request, details.feeIsInput, details.outAmount);

        //pay fees
        payAndDistribute(request, details);
    }

    /**
     * Reward DXBL to the trader
     */
    function collectDXBL(SwapTypes.SwapRequest memory request, bool feeIsInput, uint outAmount) public {
        uint value = 0;
        if(feeIsInput) {
            //when input, the total input amount is used to determine reward rate
            value = request.tokenIn.amount;
        } else {
            //otherwise, it's the output generated from the swap
            value = outAmount;
        }
        //Dexible is the only one allowed to ask the vault to mint tokens on behalf of a trader
        //See RevshareVault for logic of minting rewards
        IRevshareVault(LibStorage.getDexibleStorage().revshareManager).rewardTrader(request.executionRequest.requester, address(request.executionRequest.fee.feeToken), value);
    }

    /**
     * Distribute payments to revshare pool, affiliates, treasury, and trader
     */
    function payAndDistribute(SwapTypes.SwapRequest memory request, 
                                SwapDetails memory details) public  {
        payRevshareAndAffiliate(request, details);
        payProtocolAndTrader(request, details);
    }

    /**
     * Payout bps portions to revshare pool and affiliate
     */
    function payRevshareAndAffiliate(SwapTypes.SwapRequest memory request, 
                                SwapDetails memory details) public {
        //assume trader gets all output
        details.outToTrader = details.outAmount;

        //the bps portion of fee. 
        details.bpsAmount = LibFees.computeBpsFee(request, details.feeIsInput, details.preDXBLBalance, details.outAmount);
    
        //console.log("Total bps fee", payments.bpsAmount);
        uint minFee = LibFees.computeMinFeeUnits(address(request.executionRequest.fee.feeToken));
        if(minFee > details.bpsAmount) {
            console.log("Trade too small. Charging minimum flat fee", minFee);
            details.bpsAmount = minFee;
        }

        //revshare pool gets portion of bps fee collected
        details.toRevshare = (details.bpsAmount * LibStorage.getDexibleStorage().revshareSplitRatio) / 100;

        console.log("To revshare", details.toRevshare);

        //protocol gets remaining bps but affiliate fees come out of its portion. This could revert if
        //Dexible miscalculated the affiliate reward portion. However, the call would revert here and
        //Dexible relay would pay the gas fee.
        details.toProtocol = (details.bpsAmount-details.toRevshare) - request.executionRequest.fee.affiliatePortion;

        console.log("Protocol pre-gas", details.toProtocol);

        //fees accounted for thus far
        uint total = details.toRevshare + details.toProtocol + request.executionRequest.fee.affiliatePortion;
            
        if(!details.feeIsInput) {
            //this is an interim calculation. Gas fees get deducted later as well. This will
            //also revert if insufficient output was generated to cover all fees
            console.log("Out amount", details.outAmount, "Total fees so far", total);
            require(details.outAmount > total, "Insufficient output to pay fees");
            details.outToTrader = details.outAmount - total;
        } else {
            //this will revert with error if total is more than we have available
            //forcing caller to pay gas for insufficient buffer in input amount vs. traded amount
            require(details.remainingInBalance > total, "Insufficient input funds to pay fees");
            details.remainingInBalance -= total;
        }

        //now distribute fees
        IERC20 feeToken = request.executionRequest.fee.feeToken;
        //pay revshare their portion
        feeToken.safeTransfer(LibStorage.getDexibleStorage().revshareManager, details.toRevshare);
        if(request.executionRequest.fee.affiliatePortion > 0) {
            //pay affiliate their portion
            feeToken.safeTransfer(request.executionRequest.fee.affiliate, request.executionRequest.fee.affiliatePortion);
            emit AffiliatePaid(request.executionRequest.fee.affiliate, feeToken, request.executionRequest.fee.affiliatePortion);
        }
    }

    /**
     * Final step to compute gas consumption for trader and pay the protocol and trader 
     * their shares.
     */
    function payProtocolAndTrader(SwapTypes.SwapRequest memory request,
                            SwapDetails memory details) public {
        
        if(!details.isSelfSwap) {
            //If this was a relay-based swap, we need to pay treasury an estimated gas fee
            

            //we leave unguarded for gas savings since we know start gas is always higher 
            //than used and will never rollover without costing an extremely large amount of $$
            unchecked { 
                console.log("Start gas", details.startGas, "Left", gasleft());

                //the total gas used thus far plus some post-op buffer for transfers and events
                uint totalGas = (details.startGas - gasleft()) + POST_OP_GAS;
                
                console.log("Estimated gas used for trader gas payment", totalGas);
                details.nativeGasAmount = (totalGas * tx.gasprice);
            }
            //use price oracle in vault to get native price in fee token
            details.gasAmount = LibFees.computeGasFee(request, details.nativeGasAmount);
            console.log("Gas paid by trader in fee token", details.gasAmount);

            //add gas payment to treasury portion
            details.toProtocol += details.gasAmount;
            console.log("Payment to protocol", details.toProtocol);

            if(!details.feeIsInput) {
                //if output was fee, deduct gas payment from proceeds
                require(details.outToTrader >= details.gasAmount, "Insufficient output to pay gas fees");
                details.outToTrader -= details.gasAmount;
            } else {
                //will revert if insufficient remaining balance to cover gas causing caller
                //to pay all gas and get nothing if they don't have sufficient buffer of input vs
                //router input amount
                require(details.remainingInBalance >= details.gasAmount, "Insufficient input to pay gas fees");
                details.remainingInBalance -= details.gasAmount;
            }
            //console.log("Proceeds to trader", payments.outToTrader);
        }

        //now distribute fees
        IERC20 feeToken = request.executionRequest.fee.feeToken;
        feeToken.safeTransfer(LibStorage.getDexibleStorage().treasury, details.toProtocol);

        //console.log("Sending total output to trader", payments.outToTrader);
        request.tokenOut.token.safeTransfer(request.executionRequest.requester, details.outToTrader);
        
        //refund any remaining over-estimate of input amount needed
        if(details.remainingInBalance > 0) {
            //console.log("Total refund to trader", payments.remainingInBalance);
            request.tokenIn.token.safeTransfer(request.executionRequest.requester, details.remainingInBalance);
        }   
        emit SwapSuccess(request.executionRequest.requester,
                    request.executionRequest.fee.affiliate,
                    request.tokenOut.amount,
                    details.outToTrader, 
                    request.executionRequest.fee.feeToken,
                    details.gasAmount,
                    request.executionRequest.fee.affiliatePortion,
                    details.bpsAmount); 
        //console.log("Finished swap");
    }

    function preCheck(SwapTypes.SwapRequest calldata request, SwapDetails memory details) public view {
        //make sure fee token is allowed
        address fToken = address(request.executionRequest.fee.feeToken);
        bool ok = IRevshareVault(LibStorage.getDexibleStorage()
                .revshareManager).isFeeTokenAllowed(fToken);
        require(
            ok, 
            "Fee token is not allowed"
        );

        //and that it's one of the tokens swapped
        require(fToken == address(request.tokenIn.token) ||
                fToken == address(request.tokenOut.token), 
                "Fee token must be input or output token");

         //get the current DXBL balance at the start to apply discounts
        details.preDXBLBalance = LibStorage.getDexibleStorage().dxblToken.balanceOf(request.executionRequest.requester);
        
        //flag whether the input token is the fee token
        details.feeIsInput = address(request.tokenIn.token) == address(request.executionRequest.fee.feeToken);
        if(details.feeIsInput) {
            //if it is make sure it doesn't match the first router input amount to account for fees.
            require(request.tokenIn.amount > request.routes[0].routeAmount.amount, "Input fee token amount does not account for fees");
        }

        //get the starting input balance for the input token so we know how much was spent for the swap
        details.remainingInBalance = request.tokenIn.token.balanceOf(address(this));
    }

    function preFill(SwapTypes.SwapRequest calldata request) public {
        //transfer input tokens to router so it can perform dex trades
        console.log("Transfering input for trading:", request.tokenIn.amount);
        //we transfer the entire input, not the router-only inputs. This is to 
        //save gas on individual transfers. Any unused portion of input is returned 
        //to the trader in the end.
        request.tokenIn.token.safeTransferFrom(request.executionRequest.requester, address(this), request.tokenIn.amount);
        console.log("Expected output", request.tokenOut.amount);
    }


    /**
     * Pay the relay with gas funds stored in this contract. The gas used provided 
     * does not include arbitrum multiplier but may include additional amount for post-op
     * gas estimates.
     */
    function payRelayGas(uint gasFee) public {
        
        console.log("Relay Gas Reimbursement", gasFee);
        //if there is ETH in the contract, reimburse the relay that called the fill function
        if(address(this).balance < gasFee) {
            console.log("Cannot reimburse relay since do not have enough funds");
            emit InsufficientGasFunds(msg.sender, gasFee);
        } else {
            console.log("Transfering gas fee to relay");
            payable(msg.sender).transfer(gasFee);
            emit PaidGasFunds(msg.sender, gasFee);
        }
    }

    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../common/SwapTypes.sol";

interface IDexible {

    event SwapFailed(address indexed trader, 
                     IERC20 feeToken, 
                     uint gasFeePaid);
    event SwapSuccess(address indexed trader,
                        address indexed affiliate,
                        uint inputAmount,
                        uint outputAmount,
                        IERC20 feeToken,
                        uint gasFee,
                        uint affiliateFee,
                        uint dexibleFee);
    event AffiliatePaid(address indexed affiliate, IERC20 token, uint amount);

    event PaidGasFunds(address indexed relay, uint amount);
    event InsufficientGasFunds(address indexed relay, uint amount);
    event ChangedRevshareVault(address indexed old, address indexed newRevshare);
    event ChangedRevshareSplit(uint8 split);
    event ChangedBpsRates(uint32 stdRate, uint32 minRate);

    function setTreasury(address t) external;
    function swap(SwapTypes.SwapRequest calldata request) external;
    function selfSwap(SwapTypes.SelfSwap calldata request) external;
    
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

import "./LibStorage.sol";
import "../common/SwapTypes.sol";
import "../token/IDXBL.sol";

library LibFees {

    /**
     * Compute gas fee in fee-token units. This uses the RevshareVault's access to oracles
     * to determing native gas price relative to fee token price.
     */
    function computeGasFee(SwapTypes.SwapRequest memory request, uint gasTotal) public view returns (uint gasFee) {
        LibDexible.DexibleStorage storage ds = LibStorage.getDexibleStorage();
        IRevshareVault vault = IRevshareVault(ds.revshareManager);
        return vault.convertGasToFeeToken(address(request.executionRequest.fee.feeToken), gasTotal);
    }

    /**
     * Compute the bps to charge for the swap. This leverages the DXBL token to compute discounts
     * based on trader balances and discount rates applied per DXBL token.
     */
    function computeBpsFee(SwapTypes.SwapRequest memory request, bool feeIsInput, uint preDXBL, uint outAmount) public view returns (uint) {
        //apply any discounts
        LibDexible.DexibleStorage storage ds = LibStorage.getDexibleStorage();
        
        return ds.dxblToken.computeDiscountedFee(
            IDXBL.FeeRequest({
                trader: request.executionRequest.requester,
                amt: feeIsInput ? request.tokenIn.amount : outAmount,
                referred: request.executionRequest.fee.affiliate != address(0),
                dxblBalance: preDXBL,
                stdBpsRate: ds.stdBpsRate,
                minBpsRate: ds.minBpsRate
            }));
    }

    function computeMinFeeUnits(address feeToken) public view returns (uint) {
        LibDexible.DexibleStorage storage rs = LibStorage.getDexibleStorage();
        if(rs.minFeeUSD == 0) {
            return 0;
        }

        IRevshareVault vault = IRevshareVault(rs.revshareManager);
        //fee token price is in 30-dec units.
        uint usdPrice = vault.feeTokenPriceUSD(feeToken);

        uint8 ftDecs = IERC20Metadata(feeToken).decimals();

        //fee USD configuration is expressed in 18-decimals. Have to convert to fee-token units and 
        //account for price units
        uint minFeeUSD = (rs.minFeeUSD * (ftDecs != 18 ? ((10**ftDecs) / 1e18) : 1)) * LibConstants.PRICE_PRECISION;

        //then simply divide to get fee token units that equate to min fee USD
        return  minFeeUSD / usdPrice;
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