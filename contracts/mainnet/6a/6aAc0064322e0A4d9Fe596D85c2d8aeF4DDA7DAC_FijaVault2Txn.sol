// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC4626.sol)

// ####################################################
// ################## IMPORTANT #######################
// ####################################################
// NOTE fija Finance: ETH native compatibility -- Forked OZ contract and updated deposit method to become payable.

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
 * a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(
        IERC20 asset_
    ) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_)
            .staticcall(
                abi.encodeWithSelector(IERC20Metadata.decimals.selector)
            );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals()
        public
        view
        virtual
        override(IERC20Metadata, ERC20)
        returns (uint8)
    {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(
        uint256 assets
    ) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(
        uint256 shares
    ) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(
        address
    ) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(
        address owner
    ) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(
        address owner
    ) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(
        uint256 shares
    ) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(
        uint256 shares
    ) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(
        uint256 assets,
        address receiver
    ) public payable virtual override returns (uint256) {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public payable virtual override returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public payable virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");
        uint256 assets = previewRedeem(shares);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? _initialConvertToAssets(shares, rounding)
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);

        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// FijaVault errors
error VaultNoAssetMatching();
error VaultNotWhitelisted();
error VaultNoUpdateCandidate();
error VaultUpdateStrategyTimeError();
error VaultStrategyUndefined();
error VaultUnauthorizedAccess();
error VaultUnauthorizedCaller();
error VaultMaxRedeemExceeded();
error VaultMaxWithdrawalExceeded();

// FijaACL errors
error ACLOwnerZero();
error ACLGovZero();
error ACLResellZero();
error ACLNotOwner();
error ACLNotGov();
error ACLNotGovOwner();
error ACLNotReseller();
error ACLNotWhitelist();
error ACLTransferUserNotWhitelist();
error ACLDepositReceiverNotWhitelist();
error ACLRedeemWithdrawReceiverOwnerNotWhitelist();
error ACLWhitelistAddressZero();

// Strategy errors
error FijaUnauthorizedFlash();
error FijaInvalidAssetFlash();
error FijaStrategyUpdateInProgress();

// Transfer errors
error TransferDisbalance();
error NotEnoughETHSent();
error TransferFailed();

// emergency mode restriction
error FijaInEmergencyMode();

error FijaInsufficientAmountToWithdraw();
error FijaZeroInput();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IFijaACL.sol";
import "./errors.sol";

///
/// @title Access control contract
/// @author Fija
/// @notice Provides access rights management to child contracts
/// @dev some of the methods have default access modifiers and
/// some do not have restrictions. Please verify and override to have expected behaviour
/// *********** IMPORTANT **************
/// whitelist functions in the contract are not protected
/// it is responsibility of child contracts to define access rights
///
abstract contract FijaACL is IFijaACL {
    address private _owner;
    address private _governance;
    address private _reseller;
    mapping(address => bool) private _whitelist;

    constructor(address governance_, address reseller_) {
        _transferOwnership(msg.sender);
        _transferGovernance(governance_);
        _transferReseller(reseller_);
    }

    ///
    /// @dev Throws if called by any account that's not whitelisted.
    ///
    modifier onlyWhitelisted() {
        _checkWhitelist();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the owner.
    ///
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Governance.
    ///
    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Reseller.
    ///
    modifier onlyReseller() {
        _checkReseller();
        _;
    }

    ///
    /// @dev Throws if called by any account other than the Governance or Owner.
    ///
    modifier onlyOwnerOrGovernance() {
        _checkOwnerOrGovernance();
        _;
    }

    ///
    /// @dev Throws if receiver and owner are not in the whitelist
    ///
    modifier onlyReceiverOwnerWhitelisted(address receiver, address owner_) {
        _checkReceiverOwnerWhitelisted(receiver, owner_);
        _;
    }

    ///
    /// @dev Throws if receiver is not in the whitelist
    ///
    modifier onlyReceiverWhitelisted(address receiver) {
        _checkReceiverWhitelisted(receiver);
        _;
    }

    ///
    /// NOTE: emits IFijaACL.WhitelistedAddressAdded
    /// @inheritdoc IFijaACL
    ///
    function addAddressToWhitelist(
        address addr
    ) public virtual override returns (bool) {
        if (isWhitelisted(addr)) {
            return false;
        }
        _addAddressToWhitelist(addr);

        return true;
    }

    ///
    /// NOTE: emits IFijaACL.WhitelistedAddressRemoved
    /// @inheritdoc IFijaACL
    ///
    function removeAddressFromWhitelist(
        address addr
    ) public virtual override returns (bool) {
        if (!isWhitelisted(addr)) {
            return false;
        }
        _removeAddressFromWhitelist(addr);

        return true;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function governance() public view virtual override returns (address) {
        return _governance;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function reseller() public view virtual override returns (address) {
        return _reseller;
    }

    ///
    /// @inheritdoc IFijaACL
    ///
    function isWhitelisted(
        address addr
    ) public view virtual override returns (bool) {
        return _whitelist[addr];
    }

    ///
    /// NOTE: only owner access, emits IFijaACL.OwnershipTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferOwnership(
        address newOwner
    ) external virtual override onlyOwner {
        _transferOwnership(newOwner);
    }

    ///
    /// NOTE: only owner or governance access, emits IFijaACL.GovernanceTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferGovernance(
        address newGovernance
    ) external virtual override onlyOwnerOrGovernance {
        if (newGovernance == address(0)) {
            revert ACLGovZero();
        }
        _transferGovernance(newGovernance);
    }

    ///
    /// NOTE: only governance access, emits IFijaACL.ResellerTransferred
    /// @inheritdoc IFijaACL
    ///
    function transferReseller(
        address newReseller
    ) external virtual override onlyGovernance {
        if (newReseller == address(0)) {
            revert ACLResellZero();
        }
        _transferReseller(newReseller);
    }

    ///
    /// NOTE: only governance access, emits IFijaACL.GovernanceTransferred
    /// @inheritdoc IFijaACL
    ///
    function renounceGovernance() external virtual override onlyGovernance {
        _transferGovernance(address(0));
    }

    ///
    /// NOTE: only reseller access, emits IFijaACL.ResellerTransferred
    /// @inheritdoc IFijaACL
    ///
    function renounceReseller() external virtual override onlyReseller {
        _transferReseller(address(0));
    }

    ///
    /// NOTE: owner cannot be zero address
    /// @dev Helper method for transferOwnership.
    /// Changes ownership access to new owner address.
    /// @param newOwner address of new owner
    ///
    function _transferOwnership(address newOwner) internal virtual {
        if (newOwner == address(0)) {
            revert ACLOwnerZero();
        }
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///
    /// @dev Helper method for transferGovernance.
    /// Changes governance access to new governance address.
    /// @param newGovernance address of new governance
    ///
    function _transferGovernance(address newGovernance) internal virtual {
        address oldGovernance = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }

    ///
    /// @dev Helper method for transferReseller.
    /// Changes reseller access to new reseller address.
    /// @param newReseller address of new reseller
    ///
    function _transferReseller(address newReseller) internal virtual {
        address oldReseller = _reseller;
        _reseller = newReseller;
        emit ResellerTransferred(oldReseller, newReseller);
    }

    ///
    /// @dev Helper method for onlyOwner modifier
    ///
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert ACLNotOwner();
        }
    }

    ///
    /// @dev Helper method for onlyGovernance modifier
    ///
    function _checkGovernance() internal view virtual {
        if (governance() != msg.sender) {
            revert ACLNotGov();
        }
    }

    ///
    /// @dev Helper method for onlyOwnerOrGovernance modifier
    ///
    function _checkOwnerOrGovernance() internal view virtual {
        if (governance() != msg.sender && owner() != msg.sender) {
            revert ACLNotGovOwner();
        }
    }

    ///
    /// @dev Helper method for onlyReseller modifier
    ///
    function _checkReseller() internal view virtual {
        if (reseller() != msg.sender) {
            revert ACLNotReseller();
        }
    }

    ///
    /// @dev Helper method for onlyWhitelisted modifier
    ///
    function _checkWhitelist() internal view virtual {
        if (!isWhitelisted(msg.sender) && msg.sender != address(this)) {
            revert ACLNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for onlyReceiverOwnerWhitelisted modifier
    ///
    function _checkReceiverOwnerWhitelisted(
        address receiver,
        address owner_
    ) internal view virtual {
        if (!isWhitelisted(receiver) || !isWhitelisted(owner_)) {
            revert ACLRedeemWithdrawReceiverOwnerNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for onlyReceiverWhitelisted modifier
    ///
    function _checkReceiverWhitelisted(address receiver) internal view virtual {
        if (!isWhitelisted(receiver)) {
            revert ACLDepositReceiverNotWhitelist();
        }
    }

    ///
    /// @dev Helper method for adding address to contract whitelist.
    /// @param addr address to be added to the whitelist
    ///
    function _addAddressToWhitelist(address addr) internal {
        if (addr == address(0)) {
            revert ACLWhitelistAddressZero();
        }
        _whitelist[addr] = true;
        emit WhitelistedAddressAdded(addr);
    }

    ///
    /// @dev Helper method for removing address from contract whitelist.
    /// @param addr address to be removed from the whitelist
    ///
    function _removeAddressFromWhitelist(address addr) internal {
        _whitelist[addr] = false;
        emit WhitelistedAddressRemoved(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC4626.sol";
import "./FijaACL.sol";
import "../interfaces/IFijaERC4626Base.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

///
/// @title Fija ERC4626 Base contract
/// @author Fija
/// @notice Used as template for implementing ERC4626
/// @dev This is mainly used for adding access rights to specific methods.
/// NOTE: All mint related methods are disabled from ERC4626
///
abstract contract FijaERC4626Base is IFijaERC4626Base, FijaACL, ERC4626 {
    using Math for uint256;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ///
    /// @dev maximum amount to deposit/redeem/withdraw in assets in single call
    /// NOTE: if user wants to deposits/withdrawls/redeem with amounts above this limit
    /// transaction will be rejected
    ///
    uint256 internal immutable MAX_TICKET_SIZE;

    ///
    /// @dev maximum value of vault in assets
    /// NOTE: all deposits above this value will be rejected
    ///
    uint256 internal immutable MAX_VAULT_VALUE;

    constructor(
        IERC20 asset_,
        address governance_,
        address reseller_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        ERC4626(asset_)
        ERC20(tokenName_, tokenSymbol_)
        FijaACL(governance_, reseller_)
    {
        MAX_TICKET_SIZE = maxTicketSize_;
        MAX_VAULT_VALUE = maxVaultValue_;
    }

    ///
    /// @dev Throws if zero input amount (on deposit, withdraw, redeem)
    ///
    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert FijaZeroInput();
        }
        _;
    }

    ///
    /// @inheritdoc IERC4626
    ///
    function totalAssets()
        public
        view
        virtual
        override(IERC4626, ERC4626)
        returns (uint256)
    {
        if (asset() == ETH) {
            return address(this).balance;
        } else {
            return IERC20(asset()).balanceOf(address(this));
        }
    }

    ///
    /// @inheritdoc IFijaERC4626Base
    ///
    function convertToTokens(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    ///
    /// NOTE: caller and "to" must be whitelisted
    /// @inheritdoc IERC20
    ///
    function transfer(
        address to,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        if (!isWhitelisted(to)) {
            revert ACLTransferUserNotWhitelist();
        }
        super.transfer(to, amount);

        return true;
    }

    ///
    /// NOTE: caller and "to" must be whitelisted
    /// @inheritdoc IERC20
    ///
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        if (!isWhitelisted(from) || !isWhitelisted(to)) {
            revert ACLTransferUserNotWhitelist();
        }
        super.transferFrom(from, to, amount);

        return true;
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc IERC20
    ///
    function approve(
        address spender,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        return super.approve(spender, amount);
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc ERC20
    ///
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual override onlyWhitelisted returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc ERC20
    ///
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual override onlyWhitelisted returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function mint(
        uint256,
        address
    ) public virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function previewMint(
        uint256
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function maxMint(
        address
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// @dev calculates maximum amount user is allowed to deposit in assets,
    /// this depends of current value of vault and user deposit amount.
    /// It is controlled by MAX_TICKET_SIZE and MAX_VAULT_VALUE
    /// @return maximum amount user can deposit to the vault in assets
    ///
    function maxDeposit(
        address receiver
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return _maxDeposit(receiver, totalAssets());
    }

    ///
    /// @dev calculates maximum amount user is allowed to withdraw in assets,
    /// this on user withdrawal amount request.
    /// It is controlled by MAX_TICKET_SIZE
    /// @return maximum amount user can withdraw from the vault in assets
    ///
    function maxWithdraw(
        address owner
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        uint256 assets = _convertToAssets(balanceOf(owner), Math.Rounding.Down);

        return assets > MAX_TICKET_SIZE ? MAX_TICKET_SIZE : assets;
    }

    ///
    /// @dev calculates maximum amount user is allowed to redeem in tokens from the vault
    /// It is controlled by MAX_TICKET_SIZE
    /// @return maximum amount user can redeem from the vault in tokens
    ///
    function maxRedeem(
        address owner
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        uint256 tokens = balanceOf(owner);
        uint256 assets = _convertToAssets(tokens, Math.Rounding.Down);

        return
            assets > MAX_TICKET_SIZE
                ? convertToTokens(MAX_TICKET_SIZE)
                : tokens;
    }

    ///
    /// @dev calculates amount of tokens receiver will get based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive tokens.
    /// @return amount of tokens receiver will receive
    /// NOTE: this is protected generic template method for deposits and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.deposit from child contract to enforce access rights.
    /// Caller and receiver must be whitelisted
    /// Emits IERC4626.Deposit
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverWhitelisted(receiver)
        returns (uint256)
    {
        if (asset() == ETH) {
            if (assets != msg.value) {
                revert TransferDisbalance();
            }
            uint256 totalAssetBeforeDeposit = totalAssets() - msg.value;
            require(
                assets <= _maxDeposit(receiver, totalAssetBeforeDeposit),
                "ERC4626: deposit more than max"
            );

            uint256 supply = totalSupply();
            uint256 tokens = (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, Math.Rounding.Down)
                : assets.mulDiv(
                    supply,
                    totalAssetBeforeDeposit,
                    Math.Rounding.Down
                );

            _mint(receiver, tokens);

            emit Deposit(msg.sender, receiver, assets, tokens);

            return tokens;
        } else {
            return super.deposit(assets, receiver);
        }
    }

    ///
    /// @dev Burns exact number of tokens from owner and sends assets to receiver.
    /// @param tokens amount of tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of assets receiver will receive based on exact burnt tokens
    /// NOTE: this is protected generic template method for redeeming and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.redeem from child contract to enforce access rights.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(tokens)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        returns (uint256)
    {
        if (asset() == ETH) {
            uint256 assets = _redeemHelper(tokens, owner);

            if (msg.sender != owner) {
                _spendAllowance(owner, msg.sender, tokens);
            }
            _burn(owner, tokens);

            (bool success, ) = payable(receiver).call{value: assets}("");
            if (!success) {
                revert TransferFailed();
            }
            emit Withdraw(msg.sender, receiver, owner, assets, tokens);

            return assets;
        } else {
            uint256 assets = _redeemHelper(tokens, owner);
            _withdraw(_msgSender(), receiver, owner, assets, tokens);

            return assets;
        }
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of tokens burnt based on exact assets requested
    /// NOTE: this is protected generic template method for withdrawing and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.withdraw from child contract to enforce access rights.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        returns (uint256)
    {
        if (asset() == ETH) {
            uint256 tokens = _withdrawHelper(assets, owner);

            if (msg.sender != owner) {
                _spendAllowance(owner, msg.sender, tokens);
            }
            _burn(owner, tokens);
            (bool success, ) = payable(receiver).call{value: assets}("");
            if (!success) {
                revert TransferFailed();
            }
            emit Withdraw(msg.sender, receiver, owner, assets, tokens);

            return tokens;
        } else {
            uint256 tokens = _withdrawHelper(assets, owner);
            _withdraw(_msgSender(), receiver, owner, assets, tokens);

            return tokens;
        }
    }

    ///
    /// @dev helper method - calculates maximum amount user is allowed to deposit in assets,
    /// this depends of current value of vault and user deposit amount.
    /// It is controlled by MAX_TICKET_SIZE and MAX_VAULT_VALUE
    /// @param totalAsset total assets in deposit currency
    /// @return maximum amount user can deposit to the vault in assets
    ///
    function _maxDeposit(
        address,
        uint256 totalAsset
    ) internal view returns (uint256) {
        if (MAX_VAULT_VALUE >= totalAsset) {
            uint256 maxValueDiff = MAX_VAULT_VALUE - totalAsset;
            if (maxValueDiff <= MAX_TICKET_SIZE) {
                return maxValueDiff;
            } else {
                return MAX_TICKET_SIZE;
            }
        } else {
            return 0;
        }
    }

    function _withdrawHelper(
        uint256 assets,
        address owner
    ) internal view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 totalAssets_ = totalAssets();

        // max withdraw check
        uint256 assets_ = (supply == 0)
            ? _initialConvertToAssets(balanceOf(owner), Math.Rounding.Down)
            : balanceOf(owner).mulDiv(totalAssets_, supply, Math.Rounding.Down);

        uint256 maxWithdrawalAssets = assets_ > MAX_TICKET_SIZE
            ? MAX_TICKET_SIZE
            : assets_;

        require(
            assets <= maxWithdrawalAssets,
            "ERC4626: withdraw more than max"
        );

        // preview withdraw
        uint256 tokens = (assets == 0 || supply == 0)
            ? _initialConvertToShares(assets, Math.Rounding.Up)
            : assets.mulDiv(supply, totalAssets_, Math.Rounding.Up);

        return tokens;
    }

    function _redeemHelper(
        uint256 tokens,
        address owner
    ) internal view returns (uint256) {
        // max reedem check
        uint256 tokens_ = balanceOf(owner);
        uint256 totalAssets_ = totalAssets();

        uint256 supply = totalSupply();

        uint256 assets_ = (supply == 0)
            ? _initialConvertToAssets(tokens_, Math.Rounding.Down)
            : tokens_.mulDiv(totalAssets_, supply, Math.Rounding.Down);

        uint256 maxReedemTokens = assets_ > MAX_TICKET_SIZE
            ? convertToTokens(MAX_TICKET_SIZE)
            : tokens_;

        require(tokens <= maxReedemTokens, "ERC4626: redeem more than max");

        // preview redeem
        uint256 assets = (supply == 0)
            ? _initialConvertToAssets(tokens, Math.Rounding.Down)
            : tokens.mulDiv(totalAssets_, supply, Math.Rounding.Down);

        return assets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./FijaERC4626Base.sol";
import "../interfaces/IFijaStrategy.sol";
import "../interfaces/IFijaVault.sol";
import "./errors.sol";

///
/// @title FijaVault
/// @author Fija
/// @notice Enables users to deposit assets and receive vault tokens in return.
/// User can withdraw back assets by burning their vault tokens,
/// potentially increased for vault interest.
/// @dev In order for Vault to function properly, following needs to be completed:
/// - "Deployer" deployed Strategy which vault will use and it's address is known
/// - "Deployer" invoked Strategy.addAddressToWhitelist and added this Vault to Strategy's whitelist
///
contract FijaVault is IFijaVault, FijaERC4626Base {
    IFijaStrategy internal _strategy;
    StrategyCandidate internal _strategyCandidate;

    uint256 internal _approvalDelay;

    constructor(
        IFijaStrategy strategy_,
        IERC20 asset_,
        string memory tokenName_,
        string memory tokenSymbol_,
        address governance_,
        address reseller_,
        uint256 approvalDelay_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        FijaERC4626Base(
            asset_,
            governance_,
            reseller_,
            tokenName_,
            tokenSymbol_,
            maxTicketSize_,
            maxVaultValue_
        )
    {
        if (address(strategy_) == address(0)) {
            revert VaultStrategyUndefined();
        }
        if (strategy_.asset() != asset()) {
            revert VaultNoAssetMatching();
        }

        _strategy = strategy_;
        _approvalDelay = approvalDelay_;
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function strategy() public view virtual override returns (address) {
        return address(_strategy);
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function proposedStrategy()
        public
        view
        virtual
        override
        returns (StrategyCandidate memory)
    {
        return _strategyCandidate;
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function approvalDelay() public view virtual override returns (uint256) {
        return _approvalDelay;
    }

    ///
    /// NOTE: vault needs to be added to proposed strategy whitelist prior to calling this function
    /// Emits IFijaVault.NewStrategyCandidateEvent
    /// @inheritdoc IFijaVault
    ///
    function proposeStrategy(
        IFijaStrategy strategyCandidate
    ) public virtual override onlyGovernance {
        if (!strategyCandidate.isWhitelisted(address(this))) {
            revert VaultNotWhitelisted();
        }

        _strategyCandidate = StrategyCandidate({
            implementation: address(strategyCandidate),
            proposedTime: uint64(block.timestamp)
        });

        emit NewStrategyCandidateEvent(
            address(strategyCandidate),
            block.timestamp
        );
    }

    ///
    /// NOTE: this can only be called when proposedTime + approvalDelay has passed.
    /// For safety it sets StrategyCandidate.implementation to 0 address and proposedTime to over 130 years from now
    /// Emits IFijaVault.UpdateStrategyEvent
    /// @inheritdoc IFijaVault
    ///
    function updateStrategy() public payable virtual override onlyGovernance {
        if (_strategyCandidate.implementation == address(0)) {
            revert VaultNoUpdateCandidate();
        }
        if (
            _strategyCandidate.proposedTime + _approvalDelay >= block.timestamp
        ) {
            revert VaultUpdateStrategyTimeError();
        }

        emit UpdateStrategyEvent(
            _strategyCandidate.implementation,
            block.timestamp
        );

        // get assets back from strategy in batches
        uint256 remainingTokens = _strategy.balanceOf(address(this));
        while (remainingTokens > 0) {
            uint256 maxRedeem = _strategy.maxRedeem(address(this));
            uint256 redeemAmount = remainingTokens > maxRedeem
                ? maxRedeem
                : remainingTokens;
            _strategy.redeem(redeemAmount, address(this), address(this));
            remainingTokens -= redeemAmount;
        }

        // get all assets in the vault (assets received from strategy + outstanding assets if any)
        uint256 totalAssetsInVault = 0;
        if (asset() != ETH) {
            totalAssetsInVault = IERC20(asset()).balanceOf(address(this));
        } else {
            totalAssetsInVault = address(this).balance;
        }

        // assign new strategy
        _strategy = IFijaStrategy(_strategyCandidate.implementation);

        // vault is giving new Strategy approval for asset transfer
        if (asset() != ETH) {
            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategy),
                totalAssetsInVault
            );
        }

        // deposit assets received from old strategy to new strategy and receive strategy tokens from new strategy,
        // in batches
        while (totalAssetsInVault > 0) {
            uint256 maxDeposit = _strategy.maxDeposit(address(this));
            uint256 depositAmount = totalAssetsInVault > maxDeposit
                ? maxDeposit
                : totalAssetsInVault;

            uint256 ethValue = 0;
            if (asset() == ETH) {
                ethValue = depositAmount;
            }
            _strategy.deposit{value: ethValue}(depositAmount, address(this));
            totalAssetsInVault -= depositAmount;
        }

        // resets strategy candidate after strategy update has been completed
        _strategyCandidate.implementation = address(0);
        _strategyCandidate.proposedTime = type(uint64).max; //set proposed time to the far future
    }

    ///
    /// @dev gets amount of assets under vault management
    /// @return amount in assets
    ///
    function totalAssets()
        public
        view
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        if (asset() == ETH) {
            return
                _strategy.convertToAssets(_strategy.balanceOf(address(this))) +
                address(this).balance;
        } else {
            return
                _strategy.convertToAssets(_strategy.balanceOf(address(this))) +
                IERC20(asset()).balanceOf(address(this));
        }
    }

    ///
    /// @dev calculates amount of vault tokens receiver will get from the Vault based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive vault tokens.
    /// @return amount of vault tokens receiver will receive
    /// NOTE: Main entry method for receiving deposits, which will be then distrubuted through strategy contract.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller and receiver must be whitelisted
    /// Emits IERC4626.Deposit
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        uint256 tokens = super.deposit(assets, receiver);
        uint256 allAssets;
        if (asset() == ETH) {
            allAssets = address(this).balance;
            _strategy.deposit{value: allAssets}(allAssets, address(this));
        } else {
            allAssets = IERC20(asset()).balanceOf(address(this));
            // Vault is giving Strategy approval for asset transfer
            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategy),
                allAssets
            );
            _strategy.deposit(allAssets, address(this));
        }

        return tokens;
    }

    ///
    /// @dev Burns exact number of vault tokens from owner and sends assets to receiver.
    /// @param tokens amount of vault tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of assets receiver will receive based on exact burnt vault tokens
    /// NOTE: Unwinds investments from strategy and returns assets.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        uint256 assets = previewRedeem(tokens);

        uint256 currentBalance;
        if (asset() == ETH) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(asset()).balanceOf(address(this));
        }

        if (assets > currentBalance) {
            uint256 strategyTokens = _strategy.previewWithdraw(
                assets - currentBalance
            );
            _strategy.redeem(strategyTokens, address(this), address(this));
        }
        return super.redeem(tokens, receiver, owner);
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of vault tokens burnt based on exact assets requested
    /// NOTE: Unwinds investments from strategy and returns assets.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        uint256 currentBalance;
        if (asset() == ETH) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(asset()).balanceOf(address(this));
        }

        if (assets > currentBalance) {
            _strategy.withdraw(
                assets - currentBalance,
                address(this),
                address(this)
            );
        }
        return super.withdraw(assets, receiver, owner);
    }

    ///
    /// NOTE: only reseller access
    /// @inheritdoc IFijaACL
    ///
    function addAddressToWhitelist(
        address addr
    ) public virtual override onlyReseller returns (bool) {
        return super.addAddressToWhitelist(addr);
    }

    ///
    /// NOTE: only reseller access
    /// @inheritdoc IFijaACL
    ///
    function removeAddressFromWhitelist(
        address addr
    ) public virtual override onlyReseller returns (bool) {
        return super.removeAddressFromWhitelist(addr);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FijaVault.sol";
import "../interfaces/IFijaVault2Txn.sol";
import "../interfaces/IFijaStrategy2Txn.sol";
import "./types.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

///
/// @title FijaVault2Tx
/// @author Fija
/// @notice Enables users to deposit assets and receive vault tokens in return.
/// User can withdraw back assets by burning their vault tokens,
/// potentially increased for vault interest.
/// @dev In order for Vault to function properly, following needs to be completed:
/// - "Deployer" deployed Strategy which vault will use and it's address is known
/// - "Deployer" invoked Strategy.addAddressToWhitelist and added this Vault to Strategy's whitelist
/// NOTE: Vault supports 2 tx processes for deposits/withdraw/redeem
///
contract FijaVault2Txn is IFijaVault2Txn, FijaVault {
    using Math for uint256;

    ///
    /// @dev holder for input params of deposit/redeem/withdraw calls
    /// passed to strategy - strategy.deposit/withdraw/redeem will read
    /// this when called. This so we do not break IERC4626.
    ///
    TxParams internal _txParams;

    ///
    /// @dev flag indicating strategy is in update process
    ///
    bool internal _strategyUpdateInProgress;

    ///
    /// @dev fee for GMX keeper
    /// Taken into account with totalAssets,
    /// set here to not break IERC4626.
    ///
    uint256 internal _executionFee;

    constructor(
        IFijaStrategy strategy_,
        IERC20 asset_,
        string memory tokenName_,
        string memory tokenSymbol_,
        address governance_,
        address reseller_,
        uint256 approvalDelay_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        FijaVault(
            strategy_,
            asset_,
            tokenName_,
            tokenSymbol_,
            governance_,
            reseller_,
            approvalDelay_,
            maxTicketSize_,
            maxVaultValue_
        )
    {}

    ///
    /// @dev Throws if strategy is in update mode
    ///
    modifier isUpdateStrategyInProgress() {
        _strategyUpdateInProgressCheck();
        _;
    }

    ///
    /// @dev Throws if caller is not strategy or strategy candidate
    ///
    modifier onlyStrategy() {
        _onlyStrategy();
        _;
    }

    ///
    /// @dev gets amount of assets under vault management
    /// @return amount in assets
    ///
    function totalAssets()
        public
        view
        virtual
        override(FijaVault, IERC4626)
        returns (uint256)
    {
        if (asset() == ETH) {
            return super.totalAssets() - _executionFee;
        } else {
            return super.totalAssets();
        }
    }

    ///
    /// @dev calculates amount of vault tokens receiver will get from the Vault based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive vault tokens.
    /// @return amount of vault tokens receiver will receive
    /// NOTE: Main entry method for receiving deposits, which will be then distrubuted through strategy contract.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller and receiver must be whitelisted
    /// Additional parameters to strategy are passed by _txParams
    /// Emits IERC4626.Deposit
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override(FijaVault, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverWhitelisted(receiver)
        isUpdateStrategyInProgress
        returns (uint256)
    {
        uint256 tokens;

        if (asset() == ETH) {
            uint256 executionFee = msg.value - assets;

            _executionFee = executionFee;
            uint256 totalAssetBeforeDeposit = totalAssets() - assets;
            require(
                assets <= _maxDeposit(receiver, totalAssetBeforeDeposit),
                "ERC4626: deposit more than max"
            );

            uint256 supply = totalSupply();
            tokens = (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, Math.Rounding.Down)
                : assets.mulDiv(
                    supply,
                    totalAssetBeforeDeposit,
                    Math.Rounding.Down
                );

            uint256 balance = address(this).balance;

            // store vault.deposit params for afterDeposit callback called by strategy in 2 tx
            _txParams = TxParams(
                assets,
                tokens,
                receiver,
                address(0),
                TxType.DEPOSIT
            );

            _strategy.deposit{value: balance}(
                balance - executionFee,
                address(this)
            );

            _txParams = TxParams(0, 0, address(0), address(0), TxType.DEPOSIT);
            _executionFee = 0;
        } else {
            require(
                assets <= maxDeposit(receiver),
                "ERC4626: deposit more than max"
            );

            tokens = ERC4626.previewDeposit(assets);

            SafeERC20.safeTransferFrom(
                IERC20(asset()),
                msg.sender,
                address(this),
                assets
            );

            uint256 balance = IERC20(asset()).balanceOf(address(this));

            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategy),
                balance
            );
            // store vault.deposit params for afterDeposit callback called by strategy in 2 tx
            _txParams = TxParams(
                assets,
                tokens,
                receiver,
                address(0),
                TxType.DEPOSIT
            );

            _strategy.deposit{value: msg.value}(balance, address(this));

            _txParams = TxParams(0, 0, address(0), address(0), TxType.DEPOSIT);
        }
        return tokens;
    }

    ///
    /// @dev Burns exact number of vault tokens from owner and sends assets to receiver.
    /// This method is invoked by end user and is part of 1st tx in 2 tx redeem process.
    /// When afterRedeem callback is invoked by strategy in 2nd tx end user will receive assets.
    /// @param tokens amount of vault tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of assets receiver will receive based on exact burnt vault tokens
    /// NOTE: Unwinds investments from strategy.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Additional parameters to strategy are passed by _txParams
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(FijaVault, IERC4626)
        onlyWhitelisted
        nonZeroAmount(tokens)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        isUpdateStrategyInProgress
        returns (uint256)
    {
        uint256 assets;
        uint256 assetsToReturn;
        uint256 currentBalanceAvailable;

        if (asset() == ETH) {
            _executionFee = msg.value;

            // execution fee is reduced from current balance
            currentBalanceAvailable = address(this).balance - msg.value;
        } else {
            currentBalanceAvailable = IERC20(asset()).balanceOf(address(this));
        }
        assets = previewRedeem(tokens);

        if (tokens > maxRedeem(owner)) {
            revert VaultMaxRedeemExceeded();
        }

        if (assets <= currentBalanceAvailable) {
            assetsToReturn = FijaERC4626Base.redeem(tokens, receiver, owner);
        } else {
            SafeERC20.safeIncreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                type(uint256).max / 10
            );

            if (
                (!_strategyUpdateInProgress && msg.sender == owner) ||
                allowance(owner, msg.sender) >= tokens
            ) {
                _approve(
                    owner,
                    address(_strategy),
                    allowance(owner, address(_strategy)) +
                        type(uint256).max /
                        10
                );
            } else {
                revert VaultUnauthorizedCaller();
            }

            uint256 strategyTokens = _strategy.previewWithdraw(
                assets - currentBalanceAvailable
            );

            // store vault.deposit params for afterRedeem callback called by strategy in 2 tx
            _txParams = TxParams(0, tokens, receiver, owner, TxType.REDEEM);

            _strategy.redeem{value: msg.value}(
                strategyTokens,
                address(this),
                address(this)
            );

            _txParams = TxParams(0, 0, address(0), address(0), TxType.REDEEM);

            assetsToReturn = 0;
        }
        _executionFee = 0;

        return assetsToReturn;
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver.
    /// This method is invoked by end user and is part of 1st tx in 2 tx withdrawal process.
    /// When afterWithdraw callback is invoked by strategy in 2nd tx end user will receive assets.
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of vault tokens burnt based on exact assets requested
    /// NOTE: Unwinds investments from strategy.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Additional parameters to strategy are passed by _txParams
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        payable
        virtual
        override(FijaVault, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        isUpdateStrategyInProgress
        returns (uint256)
    {
        uint256 tokens;
        uint256 currentBalanceAvailableToUser;

        if (asset() == ETH) {
            _executionFee = msg.value;

            // execution fee is reduced from current balance
            currentBalanceAvailableToUser = address(this).balance - msg.value;
        } else {
            currentBalanceAvailableToUser = IERC20(asset()).balanceOf(
                address(this)
            );
        }
        if (assets > maxWithdraw(owner)) {
            revert VaultMaxRedeemExceeded();
        }

        if (assets <= currentBalanceAvailableToUser) {
            tokens = FijaERC4626Base.withdraw(assets, receiver, owner);
        } else {
            SafeERC20.safeIncreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                type(uint256).max / 10
            );

            if (
                msg.sender == owner ||
                allowance(owner, msg.sender) >= previewWithdraw(assets)
            ) {
                _approve(
                    owner,
                    address(_strategy),
                    allowance(owner, address(_strategy)) +
                        type(uint256).max /
                        10
                );
            } else {
                revert VaultUnauthorizedCaller();
            }

            // store vault withdraw params for afterWithdraw callback
            _txParams = TxParams(assets, 0, receiver, owner, TxType.WITHDRAW);

            _strategy.withdraw{value: msg.value}(
                assets - currentBalanceAvailableToUser,
                address(this),
                address(this)
            );

            _txParams = TxParams(0, 0, address(0), address(0), TxType.WITHDRAW);
            tokens = 0;
        }
        _executionFee = 0;

        return tokens;
    }

    ///
    /// NOTE: caller only strategy
    /// @inheritdoc IFijaVault2Txn
    ///
    function afterDeposit(
        uint256 assets,
        uint256 tokensToMint,
        address receiver,
        bool isSuccess
    ) external onlyStrategy {
        if (isSuccess) {
            if (!_strategyUpdateInProgress) {
                _mint(receiver, tokensToMint);
                emit Deposit(msg.sender, receiver, assets, tokensToMint);
            }
        } else {
            if (_strategyUpdateInProgress) {
                _strategyUpdateInProgress = false;
            }
            emit DepositFailed(receiver, assets, block.timestamp);
        }
    }

    ///
    /// NOTE: caller only strategy
    /// @inheritdoc IFijaVault2Txn
    ///
    function afterRedeem(
        uint256 tokens,
        address receiver,
        address owner,
        bool isSuccess
    ) external onlyStrategy {
        if (isSuccess) {
            if (!_strategyUpdateInProgress) {
                FijaERC4626Base.redeem(tokens, receiver, owner);
            }
        } else {
            if (_strategyUpdateInProgress) {
                _strategyUpdateInProgress = false;
            }

            emit RedeemFailed(receiver, owner, tokens, block.timestamp);
        }

        uint256 subtrahend = type(uint256).max / 10;
        if (
            _strategy.allowance(address(this), address(_strategy)) <= subtrahend
        ) {
            SafeERC20.safeApprove(IERC20(_strategy), address(_strategy), 0);
        } else {
            SafeERC20.safeDecreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                subtrahend
            );
        }

        if (!_strategyUpdateInProgress) {
            uint256 allowance = allowance(owner, address(_strategy));
            _approve(
                owner,
                address(_strategy),
                allowance <= subtrahend ? 0 : allowance - subtrahend
            );
        }
    }

    ///
    /// NOTE: caller only strategy
    /// @inheritdoc IFijaVault2Txn
    ///
    function afterWithdraw(
        uint256 assets,
        address receiver,
        address owner,
        bool isSuccess
    ) external onlyStrategy {
        if (isSuccess) {
            FijaERC4626Base.withdraw(assets, receiver, owner);
        } else {
            emit WithdrawFailed(receiver, owner, assets, block.timestamp);
        }

        uint256 subtrahend = type(uint256).max / 10;
        if (
            _strategy.allowance(address(this), address(_strategy)) <= subtrahend
        ) {
            SafeERC20.safeApprove(IERC20(_strategy), address(_strategy), 0);
        } else {
            SafeERC20.safeDecreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                subtrahend
            );
        }

        if (!_strategyUpdateInProgress) {
            uint256 allowance = allowance(owner, address(_strategy));
            _approve(
                owner,
                address(_strategy),
                allowance <= subtrahend ? 0 : allowance - subtrahend
            );
        }
    }

    ///
    /// @inheritdoc IFijaVault2Txn
    ///
    function txParams() external view returns (TxParams memory) {
        return _txParams;
    }

    ///
    /// NOTE: only be called when proposedTime + approvalDelay has passed,
    /// Update process is executed in multiple tx by first redeeming
    /// vault assets from current strategy and then depositing assets in new strategy
    /// @dev Updates strategy for vault
    /// Emits IFijaVault.UpdateStrategyEvent
    /// @inheritdoc IFijaVault
    ///
    function updateStrategy()
        public
        payable
        virtual
        override(FijaVault, IFijaVault)
        onlyGovernance
    {
        if (_strategyCandidate.implementation == address(0)) {
            revert VaultNoUpdateCandidate();
        }
        if (
            _strategyCandidate.proposedTime + _approvalDelay >= block.timestamp
        ) {
            revert VaultUpdateStrategyTimeError();
        }

        _strategyUpdateInProgress = true;

        _redeemFromCurrentStrategy();
    }

    ///
    /// @dev required gas to provide to GMX keeper to execute deposit/withdrawal requests
    /// @param txType enum to determine the type of transaction to calculate gas limit
    /// @return gas amount
    ///
    function getExecutionGasLimit(TxType txType) public view returns (uint256) {
        return
            IFijaStrategy2Txn(address(_strategy)).getExecutionGasLimit(txType);
    }

    ///
    /// @dev helper for withdrawing vault assets from current strategy as part of strategy update process
    ///
    function _redeemFromCurrentStrategy() private {
        uint256 remainingTokens = _strategy.balanceOf(address(this));
        // get assets back from strategy in batches
        if (remainingTokens > 0) {
            uint256 maxRedeem = _strategy.maxRedeem(address(this));
            uint256 redeemAmount = remainingTokens > maxRedeem
                ? maxRedeem
                : remainingTokens;

            SafeERC20.safeIncreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                type(uint256).max / 10
            );
            _strategy.redeem{value: msg.value}(
                redeemAmount,
                address(this),
                address(this)
            );

            return;
        }

        // give new strategy allowance for asset transfer
        if (asset() != ETH) {
            uint256 totalAssetsInVault = IERC20(asset()).balanceOf(
                address(this)
            );
            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategyCandidate.implementation),
                totalAssetsInVault
            );
        }

        // deposit assets received from old strategy to new strategy
        // and receive strategy tokens from new strategy, in batches

        _depositToNewStrategy();
    }

    ///
    /// @dev helper for depositing vault assets to new strategy as part of strategy update process
    ///
    function _depositToNewStrategy() private {
        address newStrategy = _strategyCandidate.implementation;
        uint256 totalAssetsInVault;

        if (asset() == ETH) {
            totalAssetsInVault = address(this).balance - msg.value;
        } else {
            totalAssetsInVault = IERC20(asset()).balanceOf(address(this));
        }

        if (totalAssetsInVault > 0) {
            uint256 maxDeposit = IFijaStrategy(newStrategy).maxDeposit(
                address(this)
            );
            uint256 depositAmount = totalAssetsInVault > maxDeposit
                ? maxDeposit
                : totalAssetsInVault;

            uint256 ethValue;
            if (asset() == ETH) {
                ethValue = depositAmount + msg.value;
            } else {
                ethValue = msg.value;
            }
            IFijaStrategy(newStrategy).deposit{value: ethValue}(
                depositAmount,
                address(this)
            );
            return;
        }
        uint256 subtrahend = type(uint256).max / 10;
        if (
            _strategy.allowance(address(this), address(_strategy)) <= subtrahend
        ) {
            SafeERC20.safeApprove(IERC20(_strategy), address(_strategy), 0);
        } else {
            SafeERC20.safeDecreaseAllowance(
                IERC20(_strategy),
                address(_strategy),
                subtrahend
            );
        }

        _strategyUpdateInProgress = false;

        _strategy = IFijaStrategy(newStrategy);
        // resets strategy candidate after strategy update has been completed
        _strategyCandidate.implementation = address(0);
        _strategyCandidate.proposedTime = type(uint64).max; //set proposed time to far future

        emit UpdateStrategyEvent(
            _strategyCandidate.implementation,
            block.timestamp
        );
    }

    ///
    /// @dev helper for modifier - checks if vault is updating strategy
    ///
    function _strategyUpdateInProgressCheck() internal view virtual {
        if (_strategyUpdateInProgress) {
            revert FijaStrategyUpdateInProgress();
        }
    }

    ///
    /// @dev helper for modifier - checks if vault is caller is strategy or strategy candidate
    ///
    function _onlyStrategy() internal view {
        bool isStrategySender = msg.sender == address(_strategy);
        bool isStrategyCandidateSender = msg.sender ==
            _strategyCandidate.implementation &&
            _strategyUpdateInProgress;

        if (!isStrategySender && !isStrategyCandidateSender) {
            revert VaultUnauthorizedAccess();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

enum TxType {
    DEPOSIT,
    WITHDRAW,
    REDEEM,
    HARVEST,
    REBALANCE,
    EMERGENCY_MODE_WITHDRAW,
    EMERGENCY_MODE_DEPOSIT
}

struct TxParams {
    uint256 assets;
    uint256 tokens;
    address receiver;
    address owner;
    TxType txType;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

// ####################################################
// ################## IMPORTANT #######################
// ####################################################
// NOTE fija Finance: ETH native compatibility -- Forked OZ contract and updated deposit method to become payable.

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(
        uint256 assets
    ) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(
        uint256 shares
    ) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(
        uint256 assets
    ) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external payable returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(
        uint256 assets
    ) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external payable returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(
        uint256 shares
    ) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external payable returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

///
/// @title Access control interface
/// @author Fija
/// @notice Defines methods and events for access control manipulation in contracts
///
interface IFijaACL {
    ///
    /// @dev emits when address is added to whitelist
    /// @param addr address added to the whitelist
    ///
    event WhitelistedAddressAdded(address addr);

    ///
    /// @dev emits when address is removed from whitelist
    /// @param addr address removed from the whitelist
    ///
    event WhitelistedAddressRemoved(address addr);

    ///
    /// @dev emits when owner is changed
    /// @param previousOwner address of previous owner
    /// @param newOwner address of new owner
    ///
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    ///
    /// @dev emits when governance is changed
    /// @param previousGovernance address of previous governance
    /// @param newGovernance address of new governance
    ///
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    ///
    /// @dev emits when reseller is changed
    /// @param previousReseller address of previous reseller
    /// @param newReseller address of new reseller
    ///
    event ResellerTransferred(
        address indexed previousReseller,
        address indexed newReseller
    );

    ///
    /// @dev adds address to whitelist
    /// @param addr address to be added to whitelist
    /// @return true if address was added, false if it already in whitelist
    ///
    function addAddressToWhitelist(address addr) external returns (bool);

    ///
    /// @dev removes address from whitelist
    /// @param addr address to be removed from whitelist
    /// @return true if address was removed, false if it not in the whitelist
    ///
    function removeAddressFromWhitelist(address addr) external returns (bool);

    ///
    /// @dev contract owner
    /// @return address of the current owner
    ///
    function owner() external view returns (address);

    ///
    /// @dev contract governance
    /// @return address of the current governance
    ///
    function governance() external view returns (address);

    ///
    /// @dev contract reseller
    /// @return address of the current reseller
    ///
    function reseller() external view returns (address);

    ///
    /// @dev checks if address is in whitelist
    /// @param addr address to check if it is in whitelist
    /// @return true if address is in contract whitelist, false if it is not.
    ///
    function isWhitelisted(address addr) external view returns (bool);

    ///
    /// @dev changes ownership to new owner address
    /// @param newOwner address of new owner
    ///
    function transferOwnership(address newOwner) external;

    ///
    /// @dev changes governance to new governance address.
    /// @param newGovernance address of new governance
    ///
    function transferGovernance(address newGovernance) external;

    ///
    /// @dev changes reseller to new reseller address.
    /// @param newReseller address of new reseller
    ///
    function transferReseller(address newReseller) external;

    ///
    /// @dev Leaves the contract without governance.
    /// It will not be possible to call `onlyGovernance` functions anymore.
    /// Renouncing governance will leave the contract without governance,
    /// thereby removing any functionality that is only available to the governance.
    ///
    function renounceGovernance() external;

    ///
    /// @dev Leaves the contract without reseller.
    /// It will not be possible to call `onlyReseller` functions anymore.
    /// Renouncing reseller will leave the contract without reseller,
    /// thereby removing any functionality that is only available to the reseller.
    ///
    function renounceReseller() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC4626.sol";
import "./IFijaACL.sol";

///
/// @title Base interface
/// @author Fija
/// @notice Interface base layer for vault and strategy interfaces
///
interface IFijaERC4626Base is IFijaACL, IERC4626 {
    ///
    /// @dev Returns the amount of tokens that the Vault would exchange for the amount of assets provided, in an ideal
    /// scenario where all the conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    /// @param assets amount to be converted to tokens amount
    ///
    function convertToTokens(
        uint256 assets
    ) external view returns (uint256 tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaERC4626Base.sol";

///
/// @title FijaStrategy interface
/// @author Fija
/// @notice Expanding base IFijaERC4626Base to support strategy specific methods
///
interface IFijaStrategy is IFijaERC4626Base {
    ///
    /// @dev check if there is a need to rebalance strategy funds
    /// @return bool indicating need for rebalance
    ///
    function needRebalance() external view returns (bool);

    ///
    /// @dev executes strategy rebalancing
    ///
    function rebalance() external payable;

    ///
    /// @dev check if there is a need to harvest strategy funds
    /// @return bool indicating need for harvesting
    ///
    function needHarvest() external view returns (bool);

    ///
    /// @dev executes strategy harvesting
    ///
    function harvest() external payable;

    ///
    /// @dev gets emergency mode status of strategy
    /// @return flag indicting emergency mode status
    ///
    function emergencyMode() external view returns (bool);

    ///
    /// @dev sets emergency mode on/off
    /// @param turnOn toggle flag
    ///
    function setEmergencyMode(bool turnOn) external payable;

    ///
    /// @dev check if there is a need for setting strategy in emergency mode
    /// @return bool indicating need for emergency mode
    ///
    function needEmergencyMode() external view returns (bool);

    ///
    /// @dev gets various strategy status parameters
    /// @return status parameters as string
    ///
    function status() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaStrategy.sol";
import "../base/types.sol";

///
/// @title FijaStrategy2Txn interface
/// @author Fija
/// @notice Expanding base IFijaStrategy to be able to estimate gas limit for GMX keeper execution fee
///
interface IFijaStrategy2Txn is IFijaStrategy {
    ///
    /// @dev required gas to provide to GMX keeper to execute deposit/withdrawal requests
    /// @param txType enum to determine the type of transaction to calculate gas limit
    /// @return gas amount
    ///
    function getExecutionGasLimit(
        TxType txType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaERC4626Base.sol";
import "./IFijaStrategy.sol";

///
/// @title Vault interface
/// @author Fija
/// @notice Defines interface methods and events used by the FijaVault
///
interface IFijaVault is IFijaERC4626Base {
    ///
    /// @param strategyCandidate address of strategy candidate
    /// @param timestamp proposed time in seconds from when strategy candidate could be
    /// eligble to be promoted to vault strategy. Also depens on IFijaVault.approvalDelay
    ///
    struct StrategyCandidate {
        address implementation;
        uint64 proposedTime;
    }

    ///
    /// @dev emits when new strategy is proposed
    /// @param strategyCandidate address representing StrategyCandidate
    /// @param timestamp time in seconds event is triggered
    ///
    event NewStrategyCandidateEvent(
        address strategyCandidate,
        uint256 timestamp
    );

    ///
    /// @dev emits when strategy canidate has become new vault strategy
    /// @param newStrategy address representing new strategy (IStrategy)
    /// @param timestamp time in seconds when event is triggered
    ///
    event UpdateStrategyEvent(address newStrategy, uint256 timestamp);

    ///
    /// @dev gets strategy in use
    /// @return strategy address
    ///
    function strategy() external view returns (address);

    ///
    /// @dev gets strategy candidate, which has potential to be elected as vault strategy
    /// @return StrategyCandidate object, see IFijaVault.StrategyCandidate
    ///
    function proposedStrategy()
        external
        view
        returns (StrategyCandidate memory);

    ///
    /// @dev gets time which need to pass in order for strategy candidate to
    /// become eligble to become new vault strategy.
    /// @return time in seconds
    ///
    function approvalDelay() external view returns (uint256);

    ///
    /// @dev sets new strategy candidate for the vault
    /// @param strategyCandidate object representing new strategy candidate for vault
    ///
    function proposeStrategy(IFijaStrategy strategyCandidate) external;

    ///
    /// @dev updates strategy in use, based on strategy proposal candidate
    ///
    function updateStrategy() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaVault.sol";
import "./IFijaStrategy.sol";

import "../base/types.sol";

///
/// @title FijaVault2Txn interface
/// @author Fija
/// @notice Defines interface methods and events used by FijaVault2Txn
/// @dev expands base IFijaVault with adding callback methods to support
/// 2 transaction deposit/withdraw/redeem
///
interface IFijaVault2Txn is IFijaVault {
    ///
    /// @dev emits when deposit fails
    /// @param receiver token receiver address
    /// @param assets amount of assets caller wants to deposit
    /// @param timestamp timestamp in seconds
    ///
    event DepositFailed(
        address indexed receiver,
        uint256 assets,
        uint256 timestamp
    );

    ///
    /// @dev emits when withdraw fails
    /// @param receiver asset receiver address
    /// @param owner token owner address
    /// @param assets amount of assets owner wants to withdraw
    /// @param timestamp timestamp in seconds
    ///
    event WithdrawFailed(
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 timestamp
    );

    ///
    /// @dev emits when redeem fails
    /// @param receiver asset receiver address
    /// @param owner token owner address
    /// @param tokens amount of tokens owner wants to burn
    /// @param timestamp timestamp in seconds
    ///
    event RedeemFailed(
        address indexed receiver,
        address indexed owner,
        uint256 tokens,
        uint256 timestamp
    );

    ///
    /// @dev callback invoked by strategy to indicate it's deposit process completed
    /// @param assets amount of assets caller wants to deposit
    /// @param tokensToMint amount of tokens vault needs to send to the caller
    /// @param receiver token receiver address
    /// @param isSuccess flag indicating strategy deposit was successful
    ///
    function afterDeposit(
        uint256 assets,
        uint256 tokensToMint,
        address receiver,
        bool isSuccess
    ) external;

    ///
    /// @dev callback invoked by strategy to indicate it's redeem process completed
    /// @param tokens amount of vault tokens caller wants to redeem
    /// @param receiver asset receiver address
    /// @param owner vault token owner address
    /// @param isSuccess flag indicating strategy redeem was successful
    ///
    function afterRedeem(
        uint256 tokens,
        address receiver,
        address owner,
        bool isSuccess
    ) external;

    ///
    /// @dev callback invoked by strategy to indicate it's withdrawal process completed
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver asset receiver address
    /// @param owner vault token owner address
    /// @param isSuccess flag indicating strategy withdrawal was successful
    ///
    function afterWithdraw(
        uint256 assets,
        address receiver,
        address owner,
        bool isSuccess
    ) external;

    ///
    /// @dev gets input params for vault.deposit/withdraw/redeem,
    /// used by strategy to invoke vault callbacks with original calldata
    /// @return TxParams
    ///
    function txParams() external view returns (TxParams memory);
}