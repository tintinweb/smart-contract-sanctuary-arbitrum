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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {RemoteDefiiAgent} from "shift-core/contracts/RemoteDefiiAgent.sol";
import {RemoteDefiiPrincipal} from "shift-core/contracts/RemoteDefiiPrincipal.sol";
import {Supported2Tokens} from "shift-core/contracts/defii/supported-tokens/Supported2Tokens.sol";
import {LayerZeroRemoteCalls} from "shift-core/contracts/defii/remote-calls/LayerZeroRemoteCalls.sol";

import {VelodromeUsdcUsdce} from "../../logic/optimism/VelodromeUsdcUsdce.sol";
import "../../constants/optimism.sol" as AGENT;
import "../../constants/arbitrumOne.sol" as PRINCIPAL;

contract Agent is
    RemoteDefiiAgent,
    Supported2Tokens,
    LayerZeroRemoteCalls,
    VelodromeUsdcUsdce
{
    constructor()
        Supported2Tokens(AGENT.USDC, AGENT.USDCe)
        LayerZeroRemoteCalls(AGENT.LZ_ENDPOINT, PRINCIPAL.LZ_CHAIN_ID)
        RemoteDefiiAgent(
            AGENT.ONEINCH_ROUTER,
            PRINCIPAL.CHAIN_ID,
            ExecutionConstructorParams({
                incentiveVault: msg.sender,
                treasury: msg.sender,
                fixedFee: 50, // 0.5%
                performanceFee: 2000 // 20%
            })
        )
    {}
}

contract Principal is
    RemoteDefiiPrincipal,
    Supported2Tokens,
    LayerZeroRemoteCalls
{
    constructor()
        RemoteDefiiPrincipal(
            PRINCIPAL.ONEINCH_ROUTER,
            AGENT.CHAIN_ID,
            PRINCIPAL.USDC,
            "Velodrome Optimism USDC/USDC.e"
        )
        LayerZeroRemoteCalls(PRINCIPAL.LZ_ENDPOINT, AGENT.LZ_CHAIN_ID)
        Supported2Tokens(PRINCIPAL.USDC, PRINCIPAL.USDCe)
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

uint256 constant CHAIN_ID = 42161;

// tokens
address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
address constant USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

// layer zero
address constant LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
uint16 constant LZ_CHAIN_ID = 110;

// swaps
address constant ONEINCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

uint256 constant CHAIN_ID = 10;

// tokens
address constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
address constant USDCe = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

// layer zero
address constant LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
uint16 constant LZ_CHAIN_ID = 111;

// swaps
address constant ONEINCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "velodrome/contracts/interfaces/IRouter.sol";
import {IGauge} from "velodrome/contracts/interfaces/IGauge.sol";

import {Execution} from "shift-core/contracts/defii/Execution.sol";

import "../../constants/optimism.sol";

abstract contract VelodromeUsdcUsdce is Execution {
    // tokens
    IERC20 VELO = IERC20(0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db);
    IERC20 lpToken = IERC20(0x36E3c209B373b861c185ecdBb8b2EbDD98587BDb);

    // contracts
    IRouter router = IRouter(0xa062aE8A9c5e11aaA026fc2670B0D65cCc8B2858);
    IGauge gauge = IGauge(0x6dd083cEe9638E0827Dc86805C9891c493f34C56);

    constructor() {
        IERC20(USDC).approve(address(router), type(uint256).max);
        IERC20(USDCe).approve(address(router), type(uint256).max);
        lpToken.approve(address(router), type(uint256).max);
        lpToken.approve(address(gauge), type(uint256).max);
    }

    function _enterLogic() internal override {
        (, , uint256 lpAmount) = router.addLiquidity(
            USDC,
            USDCe,
            true,
            IERC20(USDC).balanceOf(address(this)),
            IERC20(USDCe).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
        gauge.deposit(lpAmount);
    }

    function _exitLogic(uint256 lpAmount) internal override {
        gauge.withdraw(lpAmount);
        router.removeLiquidity(
            USDC,
            USDCe,
            true,
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function totalLiquidity() public view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function _claimRewardsLogic() internal override {
        gauge.getReward(address(this));
        VELO.transfer(incentiveVault, VELO.balanceOf(address(this)));
    }

    function _withdrawLiquidityLogic(
        address to,
        uint256 liquidity
    ) internal override {
        gauge.withdraw(liquidity);
        lpToken.transfer(to, liquidity);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBridgeAdapter {
    /// @notice Struct with token info for bridge.
    /// @notice `address_` - token address.
    /// @notice `amount` - token amount.
    /// @notice `slippage` - slippage for bridge.
    /// @dev Slippage should be in bps (eg 100% = 1e4)
    struct Token {
        address address_;
        uint256 amount;
        uint256 slippage;
    }

    /// @notice Struct with message info for bridge.
    /// @notice `dstChainId` - evm chain id (check http://chainlist.org/ for reference)
    /// @notice `content` - any info about bridge (eg `abi.encode(chainId, msg.sender)`)
    /// @notice `bridgeParams` - bytes with bridge params, different for each bridge implementation
    struct Message {
        uint256 dstChainId;
        bytes content;
        bytes bridgeParams;
    }

    /// @notice Event emitted when bridge finished on destination chain
    /// @param traceId trace id from `sendTokenWithMessage`
    /// @param token bridged token address
    /// @param amount bridge token amount
    event BridgeFinished(
        bytes32 indexed traceId,
        address token,
        uint256 amount
    );

    /// @notice Reverts, if bridge finished with wrong caller
    error Unauthorized();

    /// @notice Reverts, if chain not supported with this bridge adapter
    /// @param chainId Provided chain id
    error UnsupportedChain(uint256 chainId);

    /// @notice Reverts, if token not supported with this bridge adapter
    /// @param token Provided token address
    error UnsupportedToken(address token);

    /// @notice Send custom token with message to antoher evm chain.
    /// @dev Caller contract should be deployed on same addres on destination chain.
    /// @dev Caller contract should send target token before call.
    /// @dev Caller contract should implement `ITokenWithMessageReceiver`.
    /// @param token Struct with token info.
    /// @param token Struct with token info1.
    /// @param message Struct with message info.
    /// @return traceId Random bytes32 for bridge tracing.
    function sendTokenWithMessage(
        Token calldata token,
        Message calldata message
    ) external payable returns (bytes32 traceId);

    /// @notice Estimate fee in native currency for `sendTokenWithMessage`.
    /// @dev You should provide equal params to `estimateFee` and `sendTokenWithMessage`
    /// @param token Struct with token info.
    /// @param message Struct with message info.
    /// @return fee Fee amount in native currency
    function estimateFee(
        Token calldata token,
        Message calldata message
    ) external view returns (uint256 fee);

    /// @notice Returns block containing bridge finishing transaction.
    /// @param traceId trace id from `sendTokenWithMessage`
    /// @return blockNumber block number in destination chain
    function bridgeFinishedBlock(
        bytes32 traceId
    ) external view returns (uint256 blockNumber);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenWithMessageReceiver {
    /// @notice Receive bridged token with message from `BridgeAdapter`
    /// @dev Implementation should take token from caller (eg `IERC20(token).transferFrom(msg.seder, ..., amount)`)
    /// @param token Bridged token address
    /// @param amount Bridged token amount
    /// @param message Bridged message
    function receiveTokenWithMessage(
        address token,
        uint256 amount,
        bytes calldata message
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SharedLiquidity} from "./SharedLiquidity.sol";

abstract contract Execution is SharedLiquidity {
    struct ExecutionConstructorParams {
        address incentiveVault;
        address treasury;
        uint256 fixedFee;
        uint256 performanceFee;
    }

    error EnterFailed();
    error ExitFailed();
    event Enter(uint256 liquidityDelta);

    address public immutable incentiveVault;
    address public immutable treasury;
    uint256 public immutable performanceFee;
    uint256 public immutable fixedFee;

    constructor(ExecutionConstructorParams memory params) {
        incentiveVault = params.incentiveVault;
        treasury = params.treasury;
        fixedFee = params.fixedFee;
        performanceFee = params.performanceFee;
    }

    function claimRewards() external {
        _claimRewardsLogic();
    }

    function _enter(uint256 minLiquidityDelta) internal returns (uint256) {
        uint256 liquidityBefore = totalLiquidity();
        _enterLogic();
        uint256 liquidityAfter = totalLiquidity();
        if (
            liquidityBefore >= liquidityAfter ||
            (liquidityAfter - liquidityBefore) < minLiquidityDelta
        ) {
            revert EnterFailed();
        }
        emit Enter(liquidityAfter - liquidityBefore);

        return _sharesFromLiquidityDelta(liquidityBefore, liquidityAfter);
    }

    function _exit(uint256 shares) internal {
        uint256 liquidity = _toLiquidity(shares);
        _withdrawShares(shares);
        _exitLogic(liquidity);
    }

    function _calculatePerformanceFeeAmount(
        uint256 shares
    ) internal view returns (uint256) {
        return (shares * performanceFee) / 1e4;
    }

    function _claimRewardsLogic() internal virtual;

    function _enterLogic() internal virtual;

    function _exitLogic(uint256 liquidity) internal virtual;

    function _withdrawLiquidityLogic(
        address to,
        uint256 liquidity
    ) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Execution} from "./Execution.sol";

abstract contract ExecutionSimulation is Execution {
    constructor(ExecutionConstructorParams memory params) Execution(params) {}

    function simulateExit(
        uint256 shares,
        address[] calldata tokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateExitAndRevert(shares, tokens) {} catch (
            bytes memory result
        ) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateExitAndRevert(
        uint256 shares,
        address[] calldata tokens
    ) external {
        int256[] memory balanceChanges = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(tokens[i]).balanceOf(address(this))
            );
        }

        _exitLogic(_toLiquidity(shares));

        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(tokens[i]).balanceOf(address(this))) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;

        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    function simulateClaimRewards(
        address[] calldata rewardTokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateClaimRewardsAndRevert(rewardTokens) {} catch (
            bytes memory result
        ) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateClaimRewardsAndRevert(
        address[] calldata rewardTokens
    ) external {
        int256[] memory balanceChanges = new int256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(rewardTokens[i]).balanceOf(incentiveVault)
            );
        }

        _claimRewardsLogic();

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(rewardTokens[i]).balanceOf(incentiveVault)) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;
        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FundsHolder {
    using SafeERC20 for IERC20;

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function transferTokenTo(
        address token,
        uint256 amount,
        address to
    ) external {
        require(msg.sender == owner);
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridgeAdapter} from "shift-adapters/contracts/bridge/IBridgeAdapter.sol";

import {IVault} from "../../interfaces/IVault.sol";
import {IDefii} from "../../interfaces/IDefii.sol";

contract LocalInstructions {
    using SafeERC20 for IERC20;

    error WrongInstructionType(
        IDefii.InstructionType provided,
        IDefii.InstructionType required
    );

    event Swap(
        address tokenIn,
        address tokenOut,
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut
    );

    address immutable swapRouter;

    constructor(address swapRouter_) {
        swapRouter = swapRouter_;
    }

    function _doSwap(
        IDefii.SwapInstruction memory swapInstruction
    ) internal returns (uint256 amountOut) {
        if (swapInstruction.tokenIn == swapInstruction.tokenOut) {
            return swapInstruction.amountIn;
        }
        amountOut = IERC20(swapInstruction.tokenOut).balanceOf(address(this));
        IERC20(swapInstruction.tokenIn).safeIncreaseAllowance(
            swapRouter,
            swapInstruction.amountIn
        );
        (bool success, ) = swapRouter.call(swapInstruction.routerCalldata);

        amountOut =
            IERC20(swapInstruction.tokenOut).balanceOf(address(this)) -
            amountOut;
        require(success && amountOut >= swapInstruction.minAmountOut);

        emit Swap(
            swapInstruction.tokenIn,
            swapInstruction.tokenOut,
            swapRouter,
            swapInstruction.amountIn,
            amountOut
        );
    }

    function _returnAllFunds(
        address vault,
        uint256 positionId,
        address token
    ) internal {
        _returnFunds(
            vault,
            positionId,
            token,
            IERC20(token).balanceOf(address(this))
        );
    }

    function _returnFunds(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            IERC20(token).safeIncreaseAllowance(vault, amount);
            IVault(vault).depositToPosition(positionId, token, amount);
        }
    }

    function _checkInstructionType(
        IDefii.Instruction memory instruction,
        IDefii.InstructionType requiredType
    ) internal pure {
        if (instruction.type_ != requiredType) {
            revert WrongInstructionType(instruction.type_, requiredType);
        }
    }

    function _decodeSwap(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.SwapInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.SWAP);
        return abi.decode(instruction.data, (IDefii.SwapInstruction));
    }

    function _decodeMinLiquidityDelta(
        IDefii.Instruction memory instruction
    ) internal pure returns (uint256) {
        _checkInstructionType(
            instruction,
            IDefii.InstructionType.MIN_LIQUIDITY_DELTA
        );
        return abi.decode(instruction.data, (uint256));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridgeAdapter} from "shift-adapters/contracts/bridge/IBridgeAdapter.sol";
import {ITokenWithMessageReceiver} from "shift-adapters/contracts/bridge/ITokenWithMessageReceiver.sol";

import {IDefii} from "../../interfaces/IDefii.sol";
import {LocalInstructions} from "./LocalInstructions.sol";
import {FundsHolder} from "./FundsHolder.sol";

contract RemoteInstructions is LocalInstructions, ITokenWithMessageReceiver {
    using SafeERC20 for IERC20;

    uint256 public immutable remoteChainId;
    FundsHolder public immutable fundsHolder;

    mapping(address vault => mapping(uint256 positionId => address fundsOwner))
        public fundsOwner;
    mapping(address vault => mapping(uint256 positionId => mapping(address token => uint256 balance)))
        private _funds;

    event Bridge(
        address token,
        address bridgeAdapter,
        uint256 amount,
        uint256 chainId,
        bytes32 traceId
    );

    constructor(
        address swapRouter_,
        uint256 remoteChainId_
    ) LocalInstructions(swapRouter_) {
        remoteChainId = remoteChainId_;
        fundsHolder = new FundsHolder();
    }

    function receiveTokenWithMessage(
        address token,
        uint256 amount,
        bytes calldata message
    ) external {
        //TODO: everyone can rewrite owner rigth now
        (address vault, uint256 positionId, address owner) = abi.decode(
            message,
            (address, uint256, address)
        );

        fundsOwner[vault][positionId] = owner;
        IERC20(token).safeTransferFrom(
            msg.sender,
            address(fundsHolder),
            amount
        );
        _funds[vault][positionId][token] += amount;
    }

    function withdrawFunds(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) external {
        address owner = fundsOwner[vault][positionId];
        require(msg.sender == owner);

        _funds[vault][positionId][token] -= amount;
        fundsHolder.transferTokenTo(token, amount, owner);
    }

    function _releaseToken(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            amount = _funds[vault][positionId][token];
        }

        if (amount > 0) {
            _funds[vault][positionId][token] -= amount;
            fundsHolder.transferTokenTo(token, amount, address(this));
        }
    }

    function _holdToken(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            amount = IERC20(token).balanceOf(address(this));
        }
        if (amount > 0) {
            IERC20(token).safeTransfer(address(fundsHolder), amount);
            _funds[vault][positionId][token] += amount;
        }
    }

    function _doBridge(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.BridgeInstruction memory bridgeInstruction
    ) internal {
        IERC20(bridgeInstruction.token).safeTransfer(
            bridgeInstruction.bridgeAdapter,
            bridgeInstruction.amount
        );

        bytes32 traceId = IBridgeAdapter(bridgeInstruction.bridgeAdapter)
            .sendTokenWithMessage{value: bridgeInstruction.value}(
            IBridgeAdapter.Token({
                address_: bridgeInstruction.token,
                amount: bridgeInstruction.amount,
                slippage: bridgeInstruction.slippage
            }),
            IBridgeAdapter.Message({
                dstChainId: remoteChainId,
                content: abi.encode(vault, positionId, owner),
                bridgeParams: bridgeInstruction.bridgeParams
            })
        );

        emit Bridge(
            bridgeInstruction.token,
            bridgeInstruction.bridgeAdapter,
            bridgeInstruction.amount,
            remoteChainId,
            traceId
        );
    }

    function _doSwapBridge(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.SwapBridgeInstruction memory swapBridgeInstruction
    ) internal {
        _doSwap(
            IDefii.SwapInstruction({
                tokenIn: swapBridgeInstruction.tokenIn,
                tokenOut: swapBridgeInstruction.tokenOut,
                amountIn: swapBridgeInstruction.amountIn,
                minAmountOut: swapBridgeInstruction.minAmountOut,
                routerCalldata: swapBridgeInstruction.routerCalldata
            })
        );
        _doBridge(
            vault,
            positionId,
            owner,
            IDefii.BridgeInstruction({
                token: swapBridgeInstruction.tokenOut,
                amount: IERC20(swapBridgeInstruction.tokenOut).balanceOf(
                    address(this)
                ),
                slippage: swapBridgeInstruction.slippage,
                bridgeAdapter: swapBridgeInstruction.bridgeAdapter,
                value: swapBridgeInstruction.value,
                bridgeParams: swapBridgeInstruction.bridgeParams
            })
        );
    }

    function _decodeBridge(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.BridgeInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.BRIDGE);
        return abi.decode(instruction.data, (IDefii.BridgeInstruction));
    }

    function _decodeSwapBridge(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.SwapBridgeInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.SWAP_BRIDGE);
        return abi.decode(instruction.data, (IDefii.SwapBridgeInstruction));
    }

    function _decodeRemoteCall(
        IDefii.Instruction calldata instruction
    ) internal pure returns (bytes calldata) {
        _checkInstructionType(instruction, IDefii.InstructionType.REMOTE_CALL);
        return instruction.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Notion {
    error NotANotion(address token);

    address immutable _notion;

    constructor(address notion_) {
        _notion = notion_;
    }

    function _checkNotion(address token) internal view {
        if (token != _notion) {
            revert NotANotion(token);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {RemoteCalls} from "./RemoteCalls.sol";

interface ILayerZeroEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);
}

interface ILayerZeroReceiver {
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

abstract contract LayerZeroRemoteCalls is ILayerZeroReceiver, RemoteCalls {
    ILayerZeroEndpoint immutable lzEndpoint;
    uint16 immutable lzRemoteChainId;

    constructor(address lzEndpoint_, uint16 lzRemoteChainId_) {
        lzEndpoint = ILayerZeroEndpoint(lzEndpoint_);
        lzRemoteChainId = lzRemoteChainId_;
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) external {
        require(_srcChainId == lzRemoteChainId);
        require(msg.sender == address(lzEndpoint));
        require(
            keccak256(_srcAddress) ==
                keccak256(abi.encodePacked(address(this), address(this)))
        );
        _finishRemoteCall(_payload);
    }

    function _remoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal override {
        (address lzPaymentAddress, bytes memory lzAdapterParams) = abi.decode(
            bridgeParams,
            (address, bytes)
        );

        ILayerZeroEndpoint(lzEndpoint).send{value: msg.value}(
            lzRemoteChainId,
            abi.encodePacked(address(this), address(this)),
            calldata_,
            payable(tx.origin),
            lzPaymentAddress,
            lzAdapterParams
        );
    }

    function quoteLayerZeroFee(
        bytes calldata calldata_,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        (nativeFee, zroFee) = lzEndpoint.estimateFees(
            lzRemoteChainId,
            address(this),
            calldata_,
            _payInZRO,
            _adapterParam
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract RemoteCalls {
    event RemoteCall(bytes calldata_);

    modifier remoteFn() {
        require(msg.sender == address(this));
        _;
    }

    function _startRemoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal {
        _remoteCall(calldata_, bridgeParams);
    }

    function _finishRemoteCall(bytes memory calldata_) internal {
        address(this).call(calldata_);
    }

    function _remoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract SharedLiquidity {
    function _sharesFromLiquidityDelta(
        uint256 liquidityBefore,
        uint256 liquidityAfter
    ) internal view returns (uint256) {
        uint256 totalShares_ = totalShares();
        uint256 liquidityDelta = liquidityAfter - liquidityBefore;
        if (totalShares_ == 0) {
            return liquidityDelta;
        } else {
            return (liquidityDelta * totalShares_) / liquidityBefore;
        }
    }

    function _toLiquidity(uint256 shares) internal view returns (uint256) {
        return (shares * totalLiquidity()) / totalShares();
    }

    function totalShares() public view virtual returns (uint256);

    function totalLiquidity() public view virtual returns (uint256);

    function _withdrawShares(uint256 shares) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SupportedTokens} from "./SupportedTokens.sol";

contract Supported2Tokens is SupportedTokens {
    address private immutable _supportedToken1;
    address private immutable _supportedToken2;

    constructor(address supportedToken1_, address supportedToken2_) {
        _supportedToken1 = supportedToken1_;
        _supportedToken2 = supportedToken2_;
    }

    function _isTokenSupported(
        address token
    ) internal view override returns (bool) {
        return token == _supportedToken1 || token == _supportedToken2;
    }

    function _supportedTokens()
        internal
        view
        override
        returns (address[] memory t)
    {
        t = new address[](2);
        t[0] = _supportedToken1;
        t[1] = _supportedToken2;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract SupportedTokens {
    error TokenNotSupported(address token);

    function _checkToken(address token) internal view {
        if (!_isTokenSupported(token)) {
            revert TokenNotSupported(token);
        }
    }

    function _isTokenSupported(address) internal view virtual returns (bool);

    function _supportedTokens()
        internal
        view
        virtual
        returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDefii is IERC20 {
    enum InstructionType {
        SWAP,
        BRIDGE,
        SWAP_BRIDGE, // SwapInstruction + BridgeInstruction
        REMOTE_CALL,
        MIN_LIQUIDITY_DELTA // Just uint256
    }

    struct Instruction {
        InstructionType type_;
        bytes data;
    }

    struct SwapInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
    }
    struct BridgeInstruction {
        address token;
        uint256 amount;
        uint256 slippage;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
    }
    struct SwapBridgeInstruction {
        // swap
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
        // bridge
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
        uint256 slippage; // bps
    }

    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    function withdrawLiquidity(
        address recipieint,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable;

    function notion() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IDefii} from "./IDefii.sol";
import {Status} from "../misc/StatusLogic.sol";

interface IVault is IERC721Enumerable {
    event BalanceChanged(
        uint256 indexed positionId,
        address indexed token,
        uint256 amount,
        bool increased
    );
    event DefiiStatusChanged(
        uint256 indexed positionId,
        address indexed defii,
        Status indexed newStatus
    );

    error CantChangeDefiiStatus(
        Status currentStatus,
        Status wantStatus,
        Status positionStatus
    );
    error UseWithdrawLiquidity(address token);
    error UnsupportedDefii(address defii);
    error PositionProcessing();

    function deposit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount
    ) external;

    function depositWithPermit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function depositToPosition(
        uint256 positionId,
        address token,
        uint256 amount
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        uint256 positionId
    ) external;

    function enterDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    function enterCallback(uint256 positionId, uint256 shares) external;

    function exitDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    function exitCallback(uint256 positionId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract OperatorMixin {
    event OperatorApprovalChanged(
        address indexed user,
        address indexed operator,
        bool approval
    );

    error InvalidSignature();
    error OperatorNotAuthorized(address user, address operator);

    string constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 constant OPERATOR_APPROVAL_SIGNATURE_HASH =
        keccak256(
            "OperatorSetApproval(address user,address operator,bool approval,uint256 nonce)"
        );
    bytes32 constant DOMAIN_SEPARATOR =
        keccak256(abi.encode(keccak256("EIP712Domain()")));

    mapping(address user => mapping(address operator => bool isApproved))
        public operatorApproval;
    mapping(address => uint256) public operatorNonces;

    modifier operatorCheckApproval(address user) {
        _operatorCheckApproval(user);
        _;
    }

    function operatorSetApproval(address operator, bool approval) external {
        _operatorSetApproval(msg.sender, operator, approval);
    }

    function operatorSetApprovalWithPermit(
        address user,
        address operator,
        bool approval,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        OPERATOR_APPROVAL_SIGNATURE_HASH,
                        user,
                        operator,
                        approval,
                        operatorNonces[user]++
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress != user) {
            revert InvalidSignature();
        }
        _operatorSetApproval(user, operator, approval);
    }

    function _operatorSetApproval(
        address user,
        address operator,
        bool approval
    ) internal {
        operatorApproval[user][operator] = approval;
        emit OperatorApprovalChanged(user, operator, approval);
    }

    function _operatorCheckApproval(address user) internal view {
        if (user != msg.sender && !operatorApproval[user][msg.sender]) {
            revert OperatorNotAuthorized(user, msg.sender);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVault} from "../interfaces/IVault.sol";

enum Status {
    NOT_PROCESSING,
    ENTERING,
    EXITING,
    PROCESSED
}

uint256 constant MASK_SIZE = 2;
uint256 constant ONES_MASK = (1 << MASK_SIZE) - 1;
uint256 constant MAX_DEFII_AMOUNT = 256 / MASK_SIZE - 1;

type Statuses is uint256;
using StatusLogic for Statuses global;

library StatusLogic {
    /*
    Library for gas efficient status updates.

    We have more than 2 statuses, so, we can't use simple bitmask. To solve
    this problem, we use MASK_SIZE bits for every status.
    */

    function getPositionStatus(
        Statuses statuses
    ) internal pure returns (Status) {
        return
            Status(Statuses.unwrap(statuses) >> (MASK_SIZE * MAX_DEFII_AMOUNT));
    }

    function getDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex
    ) internal pure returns (Status) {
        return
            Status(
                (Statuses.unwrap(statuses) >> (MASK_SIZE * defiiIndex)) &
                    ONES_MASK
            );
    }

    function allDefiisProcessed(
        Statuses statuses,
        uint256 numDefiis
    ) internal pure returns (bool) {
        // Status.PROCESSED = 3 = 0b11
        // So, if all defiis processed, we have
        // statuses = 0b0100......111111111

        // First we need remove 2 left bits (position status)
        uint256 withoutPosition = Statuses.unwrap(
            statuses.setPositionStatus(Status.NOT_PROCESSING)
        );

        return (withoutPosition + 1) == (2 ** (MASK_SIZE * numDefiis));
    }

    function updateDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus,
        uint256 numDefiis
    ) internal pure returns (Statuses) {
        Status positionStatus = statuses.getPositionStatus();

        if (positionStatus == Status.NOT_PROCESSING) {
            // If position not processing:
            // - we can start enter/exit
            // - we need to update position status too
            if (newStatus == Status.ENTERING || newStatus == Status.EXITING) {
                return
                    statuses
                        .setDefiiStatus(defiiIndex, newStatus)
                        .setPositionStatus(newStatus);
            }
        } else {
            Status currentStatus = statuses.getDefiiStatus(defiiIndex);
            // If position entering:
            // - we can start/finish enter
            // - we need to reset position status, if all defiis has processed

            // If position exiting:
            // - we can start/finish exit
            // - we need to reset position status, if all defiis has processed

            // prettier-ignore
            if ((
                positionStatus == Status.ENTERING &&
                currentStatus == Status.NOT_PROCESSING &&
                newStatus == Status.ENTERING
            ) || (
                positionStatus == Status.ENTERING &&
                currentStatus == Status.ENTERING &&
                newStatus == Status.PROCESSED
            ) || (
                positionStatus == Status.EXITING &&
                currentStatus == Status.NOT_PROCESSING &&
                newStatus == Status.EXITING
            ) || (
                positionStatus == Status.EXITING &&
                currentStatus == Status.EXITING &&
                newStatus == Status.PROCESSED
            )
            ) {
                statuses = statuses.setDefiiStatus(defiiIndex, newStatus);
                if (statuses.allDefiisProcessed(numDefiis)) {
                    return Statuses.wrap(0);
                } else {
                    return statuses;
                }
            }
        }

        revert IVault.CantChangeDefiiStatus(
            statuses.getDefiiStatus(defiiIndex),
            newStatus,
            positionStatus
        );
    }

    function setPositionStatus(
        Statuses statuses,
        Status newStatus
    ) internal pure returns (Statuses) {
        uint256 offset = MASK_SIZE * MAX_DEFII_AMOUNT;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }

    function setDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus
    ) internal pure returns (Statuses) {
        uint256 offset = MASK_SIZE * defiiIndex;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IDefii} from "./interfaces/IDefii.sol";
import {OperatorMixin} from "./misc/OperatorMixin.sol";
import {ExecutionSimulation} from "./defii/ExecutionSimulation.sol";
import {RemoteInstructions} from "./defii/instructions/RemoteInstructions.sol";
import {SharedLiquidity} from "./defii/SharedLiquidity.sol";
import {RemoteCalls} from "./defii/remote-calls/RemoteCalls.sol";
import {SupportedTokens} from "./defii/supported-tokens/SupportedTokens.sol";
import {Notion} from "./defii/Notion.sol";

import {RemoteDefiiPrincipal} from "./RemoteDefiiPrincipal.sol";

abstract contract RemoteDefiiAgent is
    RemoteInstructions,
    RemoteCalls,
    ExecutionSimulation,
    SupportedTokens,
    OperatorMixin
{
    using SafeERC20 for IERC20;

    event RemoteEnter(address indexed vault, uint256 indexed postionId);
    event RemoteExit(address indexed vault, uint256 indexed postionId);

    uint256 internal _totalShares;
    mapping(address vault => mapping(uint256 positionId => uint256))
        public userShares;

    constructor(
        address swapRouter_,
        uint256 remoteChainId_,
        ExecutionConstructorParams memory executionParams
    )
        RemoteInstructions(swapRouter_, remoteChainId_)
        ExecutionSimulation(executionParams)
    {
        fundsOwner[address(0)][0] = msg.sender;
    }

    function remoteEnter(
        address vault,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable operatorCheckApproval(fundsOwner[vault][positionId]) {
        // instructions
        // [SWAP, SWAP, ..., SWAP, MIN_LIQUIDITY_DELTA, REMOTE_CALL]

        address[] memory tokens = _supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _releaseToken(vault, positionId, tokens[i], 0);
        }

        uint256 nInstructions = instructions.length;
        for (uint256 i = 0; i < nInstructions - 2; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            _checkToken(instruction.tokenOut);
            _doSwap(instruction);
        }

        uint256 shares = _enter(
            _decodeMinLiquidityDelta(instructions[nInstructions - 2])
        );
        _totalShares += shares;

        _startRemoteCall(
            abi.encodeWithSelector(
                RemoteDefiiPrincipal.mintShares.selector,
                vault,
                positionId,
                shares
            ),
            _decodeRemoteCall(instructions[nInstructions - 1])
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            _holdToken(vault, positionId, tokens[i], 0);
        }
        emit RemoteEnter(vault, positionId);
    }

    function remoteExit(
        address vault,
        uint256 positionId,
        uint256 shares,
        IDefii.Instruction[] calldata instructions
    ) external payable {
        address owner = fundsOwner[vault][positionId];
        _operatorCheckApproval(owner);

        userShares[vault][positionId] -= shares;
        _exit(shares);

        for (uint256 i = 0; i < instructions.length; i++) {
            if (instructions[i].type_ == IDefii.InstructionType.BRIDGE) {
                IDefii.BridgeInstruction
                    memory bridgeInstruction = _decodeBridge(instructions[i]);
                _checkToken(bridgeInstruction.token);
                _doBridge(vault, positionId, owner, bridgeInstruction);
            } else if (
                instructions[i].type_ == IDefii.InstructionType.SWAP_BRIDGE
            ) {
                IDefii.SwapBridgeInstruction
                    memory swapBridgeInstruction = _decodeSwapBridge(
                        instructions[i]
                    );
                _checkToken(swapBridgeInstruction.tokenOut);
                _doSwapBridge(vault, positionId, owner, swapBridgeInstruction);
            }
        }

        address[] memory tokens = _supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _holdToken(vault, positionId, tokens[i], 0);
        }
        emit RemoteExit(vault, positionId);
    }

    function reinvest(IDefii.Instruction[] calldata instructions) external {
        // instructions
        // [SWAP, SWAP, ..., SWAP, MIN_LIQUIDITY_DELTA]

        uint256 nInstructions = instructions.length;
        for (uint256 i = 0; i < nInstructions - 1; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            IERC20(instruction.tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                instruction.amountIn
            );
            _checkToken(instruction.tokenOut);
            _doSwap(instruction);
        }

        uint256 shares = _enter(
            _decodeMinLiquidityDelta(instructions[nInstructions - 1])
        );
        uint256 feeAmount = _calculatePerformanceFeeAmount(shares);

        userShares[address(0)][0] += feeAmount;
        _totalShares += feeAmount;

        address[] memory tokens = _supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokens[i]).transfer(msg.sender, tokenBalance);
            }
        }
    }

    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }

    function increaseUserShares(
        address vault,
        uint256 positionId,
        uint256 shares
    ) external remoteFn {
        userShares[vault][positionId] += shares;
    }

    function withdrawLiquidity(address to, uint256 shares) external remoteFn {
        uint256 liquidity = _toLiquidity(shares);
        _totalShares -= shares;

        _withdrawLiquidityLogic(to, liquidity);
    }

    function _withdrawShares(uint256 shares) internal override {
        _totalShares -= shares;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IDefii} from "./interfaces/IDefii.sol";
import {IVault} from "./interfaces/IVault.sol";
import {OperatorMixin} from "./misc/OperatorMixin.sol";
import {RemoteInstructions} from "./defii/instructions/RemoteInstructions.sol";
import {RemoteCalls} from "./defii/remote-calls/RemoteCalls.sol";
import {SupportedTokens} from "./defii/supported-tokens/SupportedTokens.sol";
import {Notion} from "./defii/Notion.sol";

import {RemoteDefiiAgent} from "./RemoteDefiiAgent.sol";

abstract contract RemoteDefiiPrincipal is
    IDefii,
    RemoteInstructions,
    RemoteCalls,
    SupportedTokens,
    ERC20,
    Notion,
    OperatorMixin
{
    using SafeERC20 for IERC20;

    constructor(
        address swapRouter_,
        uint256 remoteChainId_,
        address notion_,
        string memory name
    )
        Notion(notion_)
        RemoteInstructions(swapRouter_, remoteChainId_)
        ERC20(name, "DLP")
    {}

    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable {
        IERC20(_notion).safeTransferFrom(msg.sender, address(this), amount);

        address owner = IVault(msg.sender).ownerOf(positionId);
        for (uint256 i = 0; i < instructions.length; i++) {
            if (instructions[i].type_ == InstructionType.BRIDGE) {
                BridgeInstruction memory instruction = _decodeBridge(
                    instructions[i]
                );
                _checkNotion(instruction.token);
                _doBridge(msg.sender, positionId, owner, instruction);
            } else if (instructions[i].type_ == InstructionType.SWAP_BRIDGE) {
                SwapBridgeInstruction memory instruction = _decodeSwapBridge(
                    instructions[i]
                );
                _checkToken(instruction.tokenOut);
                _doSwapBridge(msg.sender, positionId, owner, instruction);
            }
        }

        _returnAllFunds(msg.sender, positionId, _notion);
    }

    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable {
        _burn(msg.sender, shares);

        _startRemoteCall(
            abi.encodeWithSelector(
                RemoteDefiiAgent.increaseUserShares.selector,
                msg.sender,
                positionId,
                shares
            ),
            _decodeRemoteCall(instructions[0])
        );
    }

    function notion() external view returns (address) {
        return _notion;
    }

    function mintShares(
        address vault,
        uint256 positionId,
        uint256 shares
    ) external remoteFn {
        _mint(vault, shares);
        IVault(vault).enterCallback(positionId, shares);
    }

    function remoteExit(
        address vault,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable operatorCheckApproval(fundsOwner[vault][positionId]) {
        // instructions
        // [SWAP, SWAP, ..., SWAP]
        uint256 nInstructions = instructions.length;
        uint256 notionAmount = 0;
        for (uint256 i = 0; i < nInstructions; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            _checkToken(instruction.tokenIn);
            _checkNotion(instruction.tokenOut);
            _releaseToken(
                vault,
                positionId,
                instruction.tokenIn,
                instruction.amountIn
            );
            notionAmount += _doSwap(instruction);
        }
        _returnFunds(vault, positionId, _notion, notionAmount);
        IVault(vault).exitCallback(positionId);
    }

    function withdrawLiquidity(
        address recipieint,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable {
        _burn(msg.sender, shares);

        _startRemoteCall(
            abi.encodeWithSelector(
                RemoteDefiiAgent.withdrawLiquidity.selector,
                recipieint,
                shares
            ),
            _decodeRemoteCall(instructions[0])
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGauge {
    error NotAlive();
    error NotAuthorized();
    error NotVoter();
    error RewardRateTooHigh();
    error ZeroAmount();
    error ZeroRewardRate();

    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);
    event NotifyReward(address indexed from, uint256 amount);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(address indexed from, uint256 amount);

    /// @notice Address of the pool LP token which is deposited (staked) for rewards
    function stakingToken() external view returns (address);

    /// @notice Address of the token (VELO v2) rewarded to stakers
    function rewardToken() external view returns (address);

    /// @notice Address of the FeesVotingReward contract linked to the gauge
    function feesVotingReward() external view returns (address);

    /// @notice Address of Velodrome v2 Voter
    function voter() external view returns (address);

    /// @notice Returns if gauge is linked to a legitimate Velodrome pool
    function isPool() external view returns (bool);

    /// @notice Timestamp end of current rewards period
    function periodFinish() external view returns (uint256);

    /// @notice Current reward rate of rewardToken to distribute per second
    function rewardRate() external view returns (uint256);

    /// @notice Most recent timestamp contract has updated state
    function lastUpdateTime() external view returns (uint256);

    /// @notice Most recent stored value of rewardPerToken
    function rewardPerTokenStored() external view returns (uint256);

    /// @notice Amount of stakingToken deposited for rewards
    function totalSupply() external view returns (uint256);

    /// @notice Get the amount of stakingToken deposited by an account
    function balanceOf(address) external view returns (uint256);

    /// @notice Cached rewardPerTokenStored for an account based on their most recent action
    function userRewardPerTokenPaid(address) external view returns (uint256);

    /// @notice Cached amount of rewardToken earned for an account
    function rewards(address) external view returns (uint256);

    /// @notice View to see the rewardRate given the timestamp of the start of the epoch
    function rewardRateByEpoch(uint256) external view returns (uint256);

    /// @notice Cached amount of fees generated from the Pool linked to the Gauge of token0
    function fees0() external view returns (uint256);

    /// @notice Cached amount of fees generated from the Pool linked to the Gauge of token1
    function fees1() external view returns (uint256);

    /// @notice Get the current reward rate per unit of stakingToken deposited
    function rewardPerToken() external view returns (uint256 _rewardPerToken);

    /// @notice Returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable() external view returns (uint256 _time);

    /// @notice Returns accrued balance to date from last claim / first deposit.
    function earned(address _account) external view returns (uint256 _earned);

    /// @notice Total amount of rewardToken to distribute for the current rewards period
    function left() external view returns (uint256 _left);

    /// @notice Retrieve rewards for an address.
    /// @dev Throws if not called by same address or voter.
    /// @param _account .
    function getReward(address _account) external;

    /// @notice Deposit LP tokens into gauge for msg.sender
    /// @param _amount .
    function deposit(uint256 _amount) external;

    /// @notice Deposit LP tokens into gauge for any user
    /// @param _amount .
    /// @param _recipient Recipient to give balance to
    function deposit(uint256 _amount, address _recipient) external;

    /// @notice Withdraw LP tokens for user
    /// @param _amount .
    function withdraw(uint256 _amount) external;

    /// @dev Notifies gauge of gauge rewards. Assumes gauge reward tokens is 18 decimals.
    ///      If not 18 decimals, rewardRate may have rounding issues.
    function notifyRewardAmount(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWETH} from "./IWETH.sol";

interface IRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    error ConversionFromV2ToV1VeloProhibited();
    error ETHTransferFailed();
    error Expired();
    error InsufficientAmount();
    error InsufficientAmountA();
    error InsufficientAmountB();
    error InsufficientAmountADesired();
    error InsufficientAmountBDesired();
    error InsufficientAmountAOptimal();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error InvalidAmountInForETHDeposit();
    error InvalidTokenInForETHDeposit();
    error InvalidPath();
    error InvalidRouteA();
    error InvalidRouteB();
    error OnlyWETH();
    error PoolDoesNotExist();
    error PoolFactoryDoesNotExist();
    error SameAddresses();
    error ZeroAddress();

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of Velodrome v1 PairFactory.sol
    function v1Factory() external view returns (address);

    /// @notice Address of Velodrome v2 PoolFactory.sol
    function defaultFactory() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Interface of WETH contract used for WETH => ETH wrapping/unwrapping
    function weth() external view returns (IWETH);

    /// @dev Represents Ether. Used by zapper to determine whether to return assets as ETH/WETH.
    function ETHER() external view returns (address);

    /// @dev Struct containing information necessary to zap in and out of pools
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           Stable or volatile pool
    /// @param factory          factory of pool
    /// @param amountOutMinA    Minimum amount expected from swap leg of zap via routesA
    /// @param amountOutMinB    Minimum amount expected from swap leg of zap via routesB
    /// @param amountAMin       Minimum amount of tokenA expected from liquidity leg of zap
    /// @param amountBMin       Minimum amount of tokenB expected from liquidity leg of zap
    struct Zap {
        address tokenA;
        address tokenB;
        bool stable;
        address factory;
        uint256 amountOutMinA;
        uint256 amountOutMinB;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    /// @notice Sort two tokens by which address value is less than the other
    /// @param tokenA   Address of token to sort
    /// @param tokenB   Address of token to sort
    /// @return token0  Lower address value between tokenA and tokenB
    /// @return token1  Higher address value between tokenA and tokenB
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    /// @notice Calculate the address of a pool by its' factory.
    ///         Used by all Router functions containing a `Route[]` or `_factory` argument.
    ///         Reverts if _factory is not approved by the FactoryRegistry
    /// @dev Returns a randomly generated address for a nonexistent pool
    /// @param tokenA   Address of token to query
    /// @param tokenB   Address of token to query
    /// @param stable   True if pool is stable, false if volatile
    /// @param _factory Address of factory which created the pool
    function poolFor(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) external view returns (address pool);

    /// @notice Wraps around poolFor(tokenA,tokenB,stable,_factory) for backwards compatibility to Velodrome v1
    function pairFor(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) external view returns (address pool);

    /// @notice Fetch and sort the reserves for a pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param _factory     Address of PoolFactory for tokenA and tokenB
    /// @return reserveA    Amount of reserves of the sorted token A
    /// @return reserveB    Amount of reserves of the sorted token B
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) external view returns (uint256 reserveA, uint256 reserveB);

    /// @notice Perform chained getAmountOut calculations on any number of pools
    function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);

    // **** ADD LIQUIDITY ****

    /// @notice Quote the amount deposited into a Pool
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           True if pool is stable, false if volatile
    /// @param _factory         Address of PoolFactory for tokenA and tokenB
    /// @param amountADesired   Amount of tokenA desired to deposit
    /// @param amountBDesired   Amount of tokenB desired to deposit
    /// @return amountA         Amount of tokenA to actually deposit
    /// @return amountB         Amount of tokenB to actually deposit
    /// @return liquidity       Amount of liquidity token returned from deposit
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Quote the amount of liquidity removed from a Pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param _factory     Address of PoolFactory for tokenA and tokenB
    /// @param liquidity    Amount of liquidity to remove
    /// @return amountA     Amount of tokenA received
    /// @return amountB     Amount of tokenB received
    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);

    /// @notice Add liquidity of two tokens to a Pool
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           True if pool is stable, false if volatile
    /// @param amountADesired   Amount of tokenA desired to deposit
    /// @param amountBDesired   Amount of tokenB desired to deposit
    /// @param amountAMin       Minimum amount of tokenA to deposit
    /// @param amountBMin       Minimum amount of tokenB to deposit
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountA         Amount of tokenA to actually deposit
    /// @return amountB         Amount of tokenB to actually deposit
    /// @return liquidity       Amount of liquidity token returned from deposit
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Add liquidity of a token and WETH (transferred as ETH) to a Pool
    /// @param token                .
    /// @param stable               True if pool is stable, false if volatile
    /// @param amountTokenDesired   Amount of token desired to deposit
    /// @param amountTokenMin       Minimum amount of token to deposit
    /// @param amountETHMin         Minimum amount of ETH to deposit
    /// @param to                   Recipient of liquidity token
    /// @param deadline             Deadline to add liquidity
    /// @return amountToken         Amount of token to actually deposit
    /// @return amountETH           Amount of tokenETH to actually deposit
    /// @return liquidity           Amount of liquidity token returned from deposit
    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    // **** REMOVE LIQUIDITY ****

    /// @notice Remove liquidity of two tokens from a Pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param liquidity    Amount of liquidity to remove
    /// @param amountAMin   Minimum amount of tokenA to receive
    /// @param amountBMin   Minimum amount of tokenB to receive
    /// @param to           Recipient of tokens received
    /// @param deadline     Deadline to remove liquidity
    /// @return amountA     Amount of tokenA received
    /// @return amountB     Amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /// @notice Remove liquidity of a token and WETH (returned as ETH) from a Pool
    /// @param token            .
    /// @param stable           True if pool is stable, false if volatile
    /// @param liquidity        Amount of liquidity to remove
    /// @param amountTokenMin   Minimum amount of token to receive
    /// @param amountETHMin     Minimum amount of ETH to receive
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountToken     Amount of token received
    /// @return amountETH       Amount of ETH received
    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /// @notice Remove liquidity of a fee-on-transfer token and WETH (returned as ETH) from a Pool
    /// @param token            .
    /// @param stable           True if pool is stable, false if volatile
    /// @param liquidity        Amount of liquidity to remove
    /// @param amountTokenMin   Minimum amount of token to receive
    /// @param amountETHMin     Minimum amount of ETH to receive
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountETH       Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    // **** SWAP ****

    /// @notice Swap one token for another
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Swap ETH for a token
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactETHForTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    /// @notice Swap a token for WETH (returned as ETH)
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired ETH
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Swap one token for another without slippage protection
    /// @return amounts     Array of amounts to swap  per route
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function UNSAFE_swapExactTokensForTokens(
        uint256[] memory amounts,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    // **** SWAP (supporting fee-on-transfer tokens) ****

    /// @notice Swap one token for another supporting fee-on-transfer tokens
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external;

    /// @notice Swap ETH for a token supporting fee-on-transfer tokens
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable;

    /// @notice Swap a token for WETH (returned as ETH) supporting fee-on-transfer tokens
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired ETH
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external;

    /// @notice Zap a token A into a pool (B, C). (A can be equal to B or C).
    ///         Supports standard ERC20 tokens only (i.e. not fee-on-transfer tokens etc).
    ///         Slippage is required for the initial swap.
    ///         Additional slippage may be required when adding liquidity as the
    ///         price of the token may have changed.
    /// @param tokenIn      Token you are zapping in from (i.e. input token).
    /// @param amountInA    Amount of input token you wish to send down routesA
    /// @param amountInB    Amount of input token you wish to send down routesB
    /// @param zapInPool    Contains zap struct information. See Zap struct.
    /// @param routesA      Route used to convert input token to tokenA
    /// @param routesB      Route used to convert input token to tokenB
    /// @param to           Address you wish to mint liquidity to.
    /// @param stake        Auto-stake liquidity in corresponding gauge.
    /// @return liquidity   Amount of LP tokens created from zapping in.
    function zapIn(
        address tokenIn,
        uint256 amountInA,
        uint256 amountInB,
        Zap calldata zapInPool,
        Route[] calldata routesA,
        Route[] calldata routesB,
        address to,
        bool stake
    ) external payable returns (uint256 liquidity);

    /// @notice Zap out a pool (B, C) into A.
    ///         Supports standard ERC20 tokens only (i.e. not fee-on-transfer tokens etc).
    ///         Slippage is required for the removal of liquidity.
    ///         Additional slippage may be required on the swap as the
    ///         price of the token may have changed.
    /// @param tokenOut     Token you are zapping out to (i.e. output token).
    /// @param liquidity    Amount of liquidity you wish to remove.
    /// @param zapOutPool   Contains zap struct information. See Zap struct.
    /// @param routesA      Route used to convert tokenA into output token.
    /// @param routesB      Route used to convert tokenB into output token.
    function zapOut(
        address tokenOut,
        uint256 liquidity,
        Zap calldata zapOutPool,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external;

    /// @notice Used to generate params required for zapping in.
    ///         Zap in => remove liquidity then swap.
    ///         Apply slippage to expected swap values to account for changes in reserves in between.
    /// @dev Output token refers to the token you want to zap in from.
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           .
    /// @param _factory         .
    /// @param amountInA        Amount of input token you wish to send down routesA
    /// @param amountInB        Amount of input token you wish to send down routesB
    /// @param routesA          Route used to convert input token to tokenA
    /// @param routesB          Route used to convert input token to tokenB
    /// @return amountOutMinA   Minimum output expected from swapping input token to tokenA.
    /// @return amountOutMinB   Minimum output expected from swapping input token to tokenB.
    /// @return amountAMin      Minimum amount of tokenA expected from depositing liquidity.
    /// @return amountBMin      Minimum amount of tokenB expected from depositing liquidity.
    function generateZapInParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountInA,
        uint256 amountInB,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin);

    /// @notice Used to generate params required for zapping out.
    ///         Zap out => swap then add liquidity.
    ///         Apply slippage to expected liquidity values to account for changes in reserves in between.
    /// @dev Output token refers to the token you want to zap out of.
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           .
    /// @param _factory         .
    /// @param liquidity        Amount of liquidity being zapped out of into a given output token.
    /// @param routesA          Route used to convert tokenA into output token.
    /// @param routesB          Route used to convert tokenB into output token.
    /// @return amountOutMinA   Minimum output expected from swapping tokenA into output token.
    /// @return amountOutMinB   Minimum output expected from swapping tokenB into output token.
    /// @return amountAMin      Minimum amount of tokenA expected from withdrawing liquidity.
    /// @return amountBMin      Minimum amount of tokenB expected from withdrawing liquidity.
    function generateZapOutParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin);

    /// @notice Used by zapper to determine appropriate ratio of A to B to deposit liquidity. Assumes stable pool.
    /// @dev Returns stable liquidity ratio of B to (A + B).
    ///      E.g. if ratio is 0.4, it means there is more of A than there is of B.
    ///      Therefore you should deposit more of token A than B.
    /// @param tokenA   tokenA of stable pool you are zapping into.
    /// @param tokenB   tokenB of stable pool you are zapping into.
    /// @param factory  Factory that created stable pool.
    /// @return ratio   Ratio of token0 to token1 required to deposit into zap.
    function quoteStableLiquidityRatio(
        address tokenA,
        address tokenB,
        address factory
    ) external view returns (uint256 ratio);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}