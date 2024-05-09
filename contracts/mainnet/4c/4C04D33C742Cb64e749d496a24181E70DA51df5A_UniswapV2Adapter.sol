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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IDexAdapter} from "../interfaces/IDexAdapter.sol";
/**
 * @title DexAdapter
 * @author Oddcod3 (@oddcod3)
 */

abstract contract DexAdapter is IDexAdapter {
    /// @dev Adapter description and version
    string public s_description;

    constructor(string memory description) {
        s_description = description;
    }

    /// @inheritdoc IDexAdapter
    function swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory extraArgs
    ) external returns (uint256 amountOut) {
        amountOut = _swap(tokenIn, tokenOut, to, amountIn, amountOutMin, extraArgs);
    }

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param to The recipient of the swap
     * @param amountIn The amount of input tokens to be swapped.
     * @param amountOutMin The minimum amount out of output tokens below which the swap reverts.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @return amountOut The amount of output token received.
     * @notice Must be overridden for each concrete adapter with the correct implementation for the target DEX.
     */
    function _swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory extraArgs
    ) internal virtual returns (uint256 amountOut);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @return maxOutput The maximum amount of output tokens that can be received.
     * @return extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @notice Must be overridden for each concrete adapter with the correct implementation for the target DEX.
     */
    function _getMaxOutput(address tokenIn, address tokenOut, uint256 amountIn)
        internal
        view
        virtual
        returns (uint256 maxOutput, bytes memory extraArgs);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     */
    function _getOutputFromArgs(address tokenIn, address tokenOut, uint256 amountIn, bytes memory extraArgs)
        internal
        view
        virtual
        returns (uint256 amountOut);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @return adapterArgs Array of adapter extraArgs given the tokenIn and tokenOut.
     */
    function _getAdapterArgs(address tokenIn, address tokenOut)
        internal
        view
        virtual
        returns (bytes[] memory adapterArgs);

    /// @inheritdoc IDexAdapter
    function getMaxOutput(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256 maxOutput, bytes memory extraArgs)
    {
        if (tokenIn == tokenOut || amountIn == 0) return (0, new bytes(0));
        (maxOutput, extraArgs) = _getMaxOutput(tokenIn, tokenOut, amountIn);
    }

    /// @inheritdoc IDexAdapter
    function getOutputFromArgs(address tokenIn, address tokenOut, uint256 amountIn, bytes memory extraArgs)
        external
        view
        returns (uint256 amountOut)
    {
        if (tokenIn == tokenOut || amountIn == 0) return 0;
        amountOut = _getOutputFromArgs(tokenIn, tokenOut, amountIn, extraArgs);
    }

    /// @inheritdoc IDexAdapter
    function getAdapterArgs(address tokenIn, address tokenOut) external view returns (bytes[] memory extraArgs) {
        if (tokenIn == tokenOut) return extraArgs;
        extraArgs = _getAdapterArgs(tokenIn, tokenOut);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";
import {DexAdapter} from "./DexAdapter.sol";

/**
 * @title UniswapV2Adapter
 * @author Oddcod3 (@oddcod3)
 */
contract UniswapV2Adapter is DexAdapter, Governable {
    using SafeERC20 for IERC20;

    error UniswapV2Adapter__OutOfBound();
    error UniswapV2Adapter__NotRegisteredFactory();
    error UniswapV2Adapter__FactoryAlreadyRegistered();
    error UniswapV2Adapter__InvalidPool();
    error UniswapV2Adapter__InsufficientOutput();

    struct UniswapV2FactoryData {
        bool isRegistered;
        uint48 feeNumerator;
        uint48 feeDenominator;
    }

    /// @dev Array of Uniswap V2 Factory interfaces that the contract interacts with.
    IUniswapV2Factory[] private s_factories;
    /// @dev A mapping from Uniswap V2 Factory addresses to their respective data structures.
    mapping(address => UniswapV2FactoryData) private s_factoryData;

    constructor(address governor, string memory description) DexAdapter(description) Governable(governor) {}

    /**
     * @dev Registers a new factory in the adapter with specific fee parameters. This function can only be called by the contract's governor.
     * @param factory The address of the UniswapV2 factory to be registered.
     * @param feeNumerator The numerator part of the fee fraction for this factory.
     * @param feeDenominator The denominator part of the fee fraction for this factory.
     * @notice This function will revert with 'UniswapV2Adapter__FactoryAlreadyRegistered' if the factory is already registered.
     *         It sets the factory as registered and stores its fee structure.
     */
    function addFactory(address factory, uint48 feeNumerator, uint48 feeDenominator) external onlyGovernor {
        UniswapV2FactoryData storage factoryData = s_factoryData[factory];
        if (factoryData.isRegistered) revert UniswapV2Adapter__FactoryAlreadyRegistered();
        factoryData.isRegistered = true;
        factoryData.feeNumerator = feeNumerator;
        factoryData.feeDenominator = feeDenominator;
        s_factories.push(IUniswapV2Factory(factory));
    }

    /**
     * @dev Removes a factory from the list. This function can only be called by the contract's governor.
     * @param factoryIndex The index of the factory in the s_factories array to be removed.
     * @notice If the factoryIndex is out of bounds of s_factories array, the function will revert with 'UniswapV2Adapter__OutOfBound'.
     *         This function deletes the factory's data and removes it from the s_factories array.
     * @notice Care must be taken to pass the correct factoryIndex, as an incorrect index can result in the removal of the wrong factory.
     */
    function removeFactory(uint256 factoryIndex) external onlyGovernor {
        uint256 factoriesLen = s_factories.length;
        if (factoriesLen == 0 || factoryIndex >= factoriesLen) revert UniswapV2Adapter__OutOfBound();
        delete s_factoryData[address(s_factories[factoryIndex])];
        if (factoryIndex < factoriesLen - 1) {
            s_factories[factoryIndex] = s_factories[factoriesLen - 1];
        }
        s_factories.pop();
    }

    /// @inheritdoc DexAdapter
    function _swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory extraArgs
    ) internal override returns (uint256 amountOut) {
        IUniswapV2Factory factory = IUniswapV2Factory(abi.decode(extraArgs, (address)));
        UniswapV2FactoryData memory factoryData = s_factoryData[address(factory)];
        if (!factoryData.isRegistered) revert UniswapV2Adapter__NotRegisteredFactory();
        address targetPool = factory.getPair(tokenIn, tokenOut);
        if (targetPool == address(0)) revert UniswapV2Adapter__InvalidPool();
        amountOut = _getAmountOut(
            targetPool, amountIn, factoryData.feeNumerator, factoryData.feeDenominator, tokenIn < tokenOut
        );
        if (amountOut < amountOutMin) revert UniswapV2Adapter__InsufficientOutput();
        (uint256 amount0Out, uint256 amount1Out) =
            tokenIn < tokenOut ? (uint256(0), amountOut) : (amountOut, uint256(0));
        IERC20(tokenIn).safeTransferFrom(msg.sender, targetPool, amountIn);
        IUniswapV2Pair(targetPool).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    /// @inheritdoc DexAdapter
    function _getMaxOutput(address tokenIn, address tokenOut, uint256 amountIn)
        internal
        view
        override
        returns (uint256 maxOutput, bytes memory extraArgs)
    {
        IUniswapV2Factory targetFactory;
        UniswapV2FactoryData memory factoryData;
        address targetPool;
        uint256 factoriesLen = s_factories.length;
        uint256 tempOutput;
        bool zeroToOne = tokenIn < tokenOut;
        for (uint256 i; i < factoriesLen;) {
            targetFactory = s_factories[i];
            targetPool = targetFactory.getPair(tokenIn, tokenOut);
            if (targetPool != address(0)) {
                factoryData = s_factoryData[address(targetFactory)];
                tempOutput =
                    _getAmountOut(targetPool, amountIn, factoryData.feeNumerator, factoryData.feeDenominator, zeroToOne);
                if (tempOutput > maxOutput) {
                    maxOutput = tempOutput;
                    extraArgs = abi.encode(address(targetFactory));
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc DexAdapter
    function _getOutputFromArgs(address tokenIn, address tokenOut, uint256 amountIn, bytes memory extraArgs)
        internal
        view
        override
        returns (uint256 amountOut)
    {
        IUniswapV2Factory factory = IUniswapV2Factory(abi.decode(extraArgs, (address)));
        UniswapV2FactoryData memory factoryData = s_factoryData[address(factory)];
        if (!factoryData.isRegistered) return 0;
        address pool = factory.getPair(tokenIn, tokenOut);
        if (pool == address(0)) return 0;
        return _getAmountOut(pool, amountIn, factoryData.feeNumerator, factoryData.feeDenominator, tokenIn < tokenOut);
    }

    /// @inheritdoc DexAdapter
    function _getAdapterArgs(address tokenIn, address tokenOut)
        internal
        view
        override
        returns (bytes[] memory extraArgs)
    {
        uint256 factoriesLen = s_factories.length;
        bytes[] memory tempArgs = new bytes[](factoriesLen);
        uint256 argsLen;
        IUniswapV2Factory factory;
        for (uint256 i; i < factoriesLen;) {
            factory = s_factories[i];
            if (factory.getPair(tokenIn, tokenOut) != address(0)) {
                tempArgs[argsLen] = abi.encode(address(factory));
                unchecked {
                    ++argsLen;
                }
            }
            unchecked {
                ++i;
            }
        }
        extraArgs = new bytes[](argsLen);
        for (uint256 j; j < argsLen;) {
            extraArgs[j] = tempArgs[j];
            unchecked {
                ++j;
            }
        }
    }

    /**
     * @dev Calculates the amount of output tokens that can be obtained from a given input amount for a swap operation in a Uniswap V2 pool, considering the pool's reserves and fee structure.
     * @param targetPool The address of the Uniswap V2 pool.
     * @param amountIn The amount of input tokens to be swapped.
     * @param feeNumerator The numerator part of the fee fraction for the swap.
     * @param feeDenominator The denominator part of the fee fraction for the swap.
     * @param zeroToOne A boolean flag indicating the direction of the swap (true for swapping token0 to token1, false for token1 to token0).
     * @return amountOut The amount of output tokens that can be received from the swap.
     * @notice This function computes the output amount by applying the Uniswap V2 formula, taking into account the current reserves of the pool and the specified fee structure.
     */
    function _getAmountOut(
        address targetPool,
        uint256 amountIn,
        uint48 feeNumerator,
        uint48 feeDenominator,
        bool zeroToOne
    ) private view returns (uint256 amountOut) {
        uint256 amountInWithFee;
        (uint256 reserveIn, uint256 reserveOut,) = IUniswapV2Pair(targetPool).getReserves();
        (reserveIn, reserveOut) = zeroToOne ? (reserveIn, reserveOut) : (reserveOut, reserveIn);
        if (reserveIn > 0 && reserveOut > 0) {
            amountInWithFee = amountIn * feeNumerator;
            amountOut = (amountInWithFee * reserveOut) / ((reserveIn * feeDenominator) + amountInWithFee);
        }
    }

    /**
     * @dev Retrieves details of a specific factory identified by its index in the 's_factory' array.
     * @param factoryIndex The index of the factory in the 's_factories' array.
     * @return factory The address of the factory at the specified index.
     * @return feeNumerator The numerator part of the fee fraction associated with this factory.
     * @return feeDenominator The denominator part of the fee fraction associated with this factory.
     * @notice The function will return the address of the factory and its fee structure.
     *         It is important to ensure that the factoryIndex is within the bounds of the array to avoid out-of-bounds errors.
     */
    function getFactoryAtIndex(uint256 factoryIndex)
        external
        view
        returns (address factory, uint48 feeNumerator, uint48 feeDenominator)
    {
        factory = address(s_factories[factoryIndex]);
        UniswapV2FactoryData memory factoryData = s_factoryData[address(factory)];
        feeNumerator = factoryData.feeNumerator;
        feeDenominator = factoryData.feeDenominator;
    }

    /// @return factoriesLength The number of factories currently registered
    function allFactoriesLength() external view returns (uint256) {
        return s_factories.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IDexAdapter
 * @author Oddcod3 (@oddcod3)
 */
interface IDexAdapter {
    /**
     * @dev Executes a token swap in the specified pool using this adapter.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param to The recipient of the swap.
     * @param amountIn The amount of input tokens to be swapped.
     * @param amountOutMin The minimum amount out of output tokens below which the swap reverts.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @return amountOut The amount of output token received.
     */
    function swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory extraArgs
    ) external returns (uint256 amountOut);

    /**
     * @dev Identifies the optimal target pool that maximizes the amount of output tokens received.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @return maxOutput The maximum amount of output tokens that can be received.
     * @return extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @notice This function scans available pools to find the one that provides the highest return for the given input token and amount.
     */
    function getMaxOutput(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256 maxOutput, bytes memory extraArgs);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @return amountOut The amount of output tokens received.
     */
    function getOutputFromArgs(address tokenIn, address tokenOut, uint256 amountIn, bytes memory extraArgs)
        external
        view
        returns (uint256 amountOut);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @return adapterArgs Array of adapter extraArgs given the tokenIn and tokenOut.
     *
     */
    function getAdapterArgs(address tokenIn, address tokenOut) external view returns (bytes[] memory adapterArgs);

    /**
     * @return description A string containing the description and version of the adapter.
     * @notice This function returns a textual description and version number of the adapter,
     */
    function s_description() external view returns (string memory description);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IGovernable} from "./interfaces/IGovernable.sol";

/**
 * @title Governable
 * @notice A 2-step governable contract with a delay between setting the pending governor and transferring governance.
 */
contract Governable is IGovernable {
    error Governable__ZeroAddress();
    error Governable__NotAuthorized();
    error Governable__TooEarly(uint64 timestampReady);

    address private s_governor;
    address private s_pendingGovernor;
    uint64 private s_govTransferReqTimestamp;
    uint32 public constant TRANSFER_GOVERNANCE_DELAY = 3 days;

    event GovernanceTrasferred(address indexed oldGovernor, address indexed newGovernor);
    event PendingGovernorChanged(address indexed pendingGovernor);

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    constructor(address governor) {
        s_governor = governor;
        emit GovernanceTrasferred(address(0), governor);
    }

    /// @inheritdoc IGovernable
    function setPendingGovernor(address pendingGovernor) external onlyGovernor {
        if (pendingGovernor == address(0)) revert Governable__ZeroAddress();
        s_pendingGovernor = pendingGovernor;
        s_govTransferReqTimestamp = uint64(block.timestamp);
        emit PendingGovernorChanged(pendingGovernor);
    }

    /// @inheritdoc IGovernable
    function transferGovernance() external {
        address newGovernor = s_pendingGovernor;
        address oldGovernor = s_governor;
        uint64 govTransferReqTimestamp = s_govTransferReqTimestamp;
        if (msg.sender != oldGovernor && msg.sender != newGovernor) revert Governable__NotAuthorized();
        if (newGovernor == address(0)) revert Governable__ZeroAddress();
        if (block.timestamp - govTransferReqTimestamp < TRANSFER_GOVERNANCE_DELAY) {
            revert Governable__TooEarly(govTransferReqTimestamp + TRANSFER_GOVERNANCE_DELAY);
        }
        s_pendingGovernor = address(0);
        s_governor = newGovernor;
        emit GovernanceTrasferred(oldGovernor, newGovernor);
    }

    function _revertIfNotGovernor() internal view {
        if (msg.sender != s_governor) revert Governable__NotAuthorized();
    }

    function _getGovernor() internal view returns (address) {
        return s_governor;
    }

    function _getPendingGovernor() internal view returns (address) {
        return s_pendingGovernor;
    }

    function _getGovTransferReqTimestamp() internal view returns (uint64) {
        return s_govTransferReqTimestamp;
    }

    function getGovernor() external view returns (address) {
        return _getGovernor();
    }

    function getPendingGovernor() external view returns (address) {
        return _getPendingGovernor();
    }

    function getGovTransferReqTimestamp() external view returns (uint64) {
        return _getGovTransferReqTimestamp();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernable {
    /**
     * @param pendingGovernor The new pending governor address.
     * @notice A call to transfer governance is required to promote the new pending governor to the governor role.
     */
    function setPendingGovernor(address pendingGovernor) external;

    /// @notice Promote the pending governor to the governor role.
    function transferGovernance() external;

    function getGovernor() external view returns (address);

    function getPendingGovernor() external view returns (address);

    function getGovTransferReqTimestamp() external view returns (uint64);
}