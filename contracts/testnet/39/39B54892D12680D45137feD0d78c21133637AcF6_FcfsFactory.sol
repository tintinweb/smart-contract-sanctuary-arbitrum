// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IRoles.sol";
import "../Constant.sol";

contract Accessable {

    IRoles private _roles;
    string private constant NO_RIGHTS = "No rights";

    constructor(IRoles roles) {
        _roles = roles;
    }

    function getRoles() public view returns (IRoles) {
        return _roles;
    }
   
    modifier onlyDeployer() {
        _require(_roles.isDeployer(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyConfigurator() {
        _require(_roles.isConfigurator(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyApprover() {
        _require(_roles.isApprover(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyDaoAdmin() {
        _require(_roles.isAdmin(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyDaoOrApprover() {
        _require(_roles.isAdmin(msg.sender) || _roles.isApprover(msg.sender), NO_RIGHTS);
        _;
    }

    function _require(bool condition, string memory err) pure internal {
        require(condition, err);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;


import "./TokenHelper.sol";
import "../interfaces/IParameterProvider.sol";
import "../interfaces/IAddressProvider.sol";
import "../interfaces/IReferralRewardVault.sol";
import "../Constant.sol";

contract FeesDistributable is TokenHelper {

    event FeeDistributed(address destination, address token, uint amount);

    function _distributeFees(IParameterProvider param, IAddressProvider add, address currency, uint feeAmt, uint raisedAmt) internal  {
       
        address[3] memory dest = add.getFeeAddresses();
        uint[] memory p = _getPercentages(param);

        // Check p0+p1+p2 is 100%. 
        // If not, the parameterProvider values are wrong & we will do manual distribution instead of reverting the finishUp call.
        if (p[0]+p[1]+p[2] != Constant.PCNT_100) {
            return;
        }

        // Distribute them
        // 1. Referral, 2. Treasury, 3. Sales
        uint fee;
        for (uint n=0; n<3; n++) {

            if (p[n] > 0 && dest[n] != Constant.ZERO_ADDRESS) {
                
                fee = (feeAmt*p[n])/Constant.PCNT_100;
                if (fee > 0) {
                    // Only erc20 token supported. Use WBNB for bnb currency.
                    _transferTokenOut(currency, fee, dest[n]);
        
                    if (n==0) {
                        // ReferralReward Vault
                        // Get the current referral split % and fix this value for this campaign
                        uint upSplitPcnt = param.getValue(ParamKey.ReferralUplineSplitPcnt);
                        IReferralRewardVault(dest[n]).declareReward(currency, raisedAmt, fee, upSplitPcnt);
                    }
                    emit FeeDistributed(dest[n], currency, fee);
                }
            }
        }
    }

    function _getPercentages(IParameterProvider provider) private view returns (uint[] memory) {

        ParamKey[] memory keys = new ParamKey[](3);
        keys[0] = ParamKey.RevShareReferralPcnt;
        keys[1] = ParamKey.RevShareTreasuryPcnt;
        keys[2] = ParamKey.RevShareDealsTeamPcnt;
        return provider.getValues(keys);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IParameterProvider.sol";
import "../interfaces/IAddressProvider.sol";


contract Providers {

    IParameterProvider internal _paramProvider;
    IAddressProvider internal _addressProvider;

    constructor(IParameterProvider param, IAddressProvider add) {
        _paramProvider = param;
        _addressProvider = add;
    }

    function getAddress(AddressKey key) internal view returns (address) {
        return _addressProvider.getAddress(key);
    }

    function getParam(ParamKey key) internal view returns (uint) {
        return _paramProvider.getValue(key);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../sale-common/interfaces/ISuperCerts.sol";
import "./TokenHelper.sol";

abstract contract SuperCertsClaimable is TokenHelper {

    struct Data {
        bool enabled;
        address certsAddress;
        uint groupId;
        string groupName;
        mapping(address=> bool) claimedMap;

        // Support Vesting of project fund in SuperCerts.
        bool vestFund;
        bool teamCertsClaimed;
        address teamAddress; // Used if team has vested their fund in SuperCert.
    }

    Data private _data;

    function claimCerts(address referer, bytes memory signature) virtual external;
    function claimTeamCerts() virtual external;
    
    function getCertsInfo() public view returns (address certsAddress, address teamAddress, bool enabled, bool vestFund, bool teamCertsClaimed) {
        certsAddress = _data.certsAddress;
        teamAddress = _data.teamAddress;
        enabled = _data.enabled;
        vestFund = _data.vestFund;
        teamCertsClaimed = _data.teamCertsClaimed;
    }

    function _setupCerts(address certsAddress, uint groupId, string memory groupName, bool vestFundInCerts, address teamAddress) internal {
        _data.enabled = true;
        _data.certsAddress = certsAddress;
        _data.teamAddress = teamAddress;
        _data.groupId = groupId;
        _data.groupName = groupName;
        _data.vestFund = vestFundInCerts;
    }

    function _completeCerts(uint totalEntitlement, address currency, uint amount) internal {
        if (_data.enabled) {
            if (totalEntitlement > 0) {
                ISuperCerts(_data.certsAddress).setUserSourceByCampaign(_data.groupId, _data.groupName, totalEntitlement, true);
            }
            if (_data.vestFund) {
                ISuperCerts(_data.certsAddress).setTeamSourceByCampaign(_data.teamAddress, currency, amount);
            }
        }
    }

    function _isCertsClaimable(address user) internal view returns (bool certsEnabled, bool claimed) {
        certsEnabled = _data.enabled;
        claimed = _data.claimedMap[user];
    }

    function _claimCerts(address user, uint entitlement) internal returns (bool success) {

        if (!_data.enabled || _data.claimedMap[user]) {
            return false;
        }
        _data.claimedMap[user] = true;
        ISuperCerts(_data.certsAddress).claimCertsFromCampaign(user, _data.groupId, _data.groupName, entitlement);
        return true;
    }

    function _claimTeamCerts() internal returns (bool) {
        if (!_data.enabled || _data.teamCertsClaimed) {
            return false;
        }
        _data.teamCertsClaimed = true;
        ISuperCerts(_data.certsAddress).claimTeamCertsFromCampaign();
        return true;
    }

    function _transferFundToCertsOrDao(address currency, uint amount, address dao) internal {
        if (amount > 0) {
            (address certsAddress, , bool enabled, bool vestFund,) = getCertsInfo();
            address to = (enabled && vestFund) ? certsAddress : dao;
            _transferTokenOut(currency, amount, to);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../Constant.sol";


contract TokenHelper {

    using SafeERC20 for IERC20;

    function _transferTokenIn(address token, uint amount) internal {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount); 
    }

    function _transferTokenOut(address token, uint amount, address to) internal  {
        IERC20(token).safeTransfer(to, amount); 
    }

    function _transferTokenFrom(address token, uint amount, address from, address to) internal {
        IERC20(token).safeTransferFrom(from, to, amount); 
    }

    function _burnTokenFrom(address token, address from, uint amount) internal {
        if (amount > 0) {
            ERC20Burnable(token).burnFrom(from, amount);
        }
    }

    function _burnToken(address token, uint amount) internal {
        if (amount > 0) {
            ERC20Burnable(token).burn(amount);
        }
    }

    function _getDpValue(address token) internal view returns (uint) {
        uint dp = IERC20Metadata(token).decimals();
        return 10 ** dp;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract Whitelistable {

    mapping(address=> bool) private _whitelistMap;
    uint private _total;

    function isWhiteListed(address user) public view returns (bool) {
        return _whitelistMap[user];
    }

    function getWhitelistCount() external view returns (uint) {
        return _total;
    }

    function _addRemoveWhitelist(address[] calldata users, bool add) internal {
        uint len = users.length;
        for (uint n=0; n<len; n++) {

            if (add != _whitelistMap[users[n]]) {
                _whitelistMap[users[n]] = add;
                if (add) {
                    _total++;
                } else {
                    _total--;
                }
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum AddressKey {

    // Dao MultiSig
    DaoMultiSig,
    OfficialSigner,

    // Token
    Launch,
    GovernanceLaunch, // Staked Launch

    // Fees Addresses
    ReferralRewardVault,
    TreasuryVault,
    SalesVault
}

interface IAddressProvider {
    function getAddress(AddressKey key) external view returns (address);
    function getOfficialAddresses() external view returns (address a, address b);
    function getTokenAddresses() external view returns (address a, address b);
    function getFeeAddresses() external view returns (address[3] memory values);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum DataSource {
    Campaign,
    SuperCerts,
    Governance,
    Referral,
    Proposal,
    MarketPlace,
    SuperFarm,
    EggPool,
    Swap
}

enum DataAction {
    Buy,
    Refund,
    ClaimCerts,
    ClaimTokens,
    ClaimTeamTokens,
    List,
    Unlist,
    AddLp,
    RemoveLp,
    Rebate,
    Revenue,
    Swap
}

interface IDataLog {
    
    function log(address fromContract, address fromUser, uint source, uint action, uint data1, uint data2) external;

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum ParamKey {

        // There will only be 1 parameterProvders in the native chain.
        // The rest of the eVM contracts will retrieve from this single parameterProvider.

        ProposalTimeToLive,
        ProposalMinPower,
        ProposalMaxQueue,
        ProposalVotingDuration,
        ProposalLaunchCollateral,
        ProposalTimeLock,
        ProposalCreatorExecutionDuration,
        ProposalQuorumPcnt, // Eg 30% of total power voted (Yes, No, Abstain) to pass.
        ProposalDummy1, // For future
        ProposalDummy2, // For future

        StakerMinLaunch,        // Eg: Min 1000 vLaunch
        StakerCapLaunch,        // Eg: Cap at 50,000 vLaunch
        StakerDiscountMinPnct,  // Eg: 1000 vLaunch gets 0.6% discount on Fee. For OTC and NFT only.
        StakerDiscountCapPnct,  // Eg: 50,000 vLaunch gets 30%% discount on Fee. For OTC and NFT only.
        StakerDummy1,           // For future
        StakerDummy2,           // For future

        RevShareReferralPcnt,   // Fee% for referrals
        RevShareTreasuryPcnt,   // Fee% for treasury
        RevShareDealsTeamPcnt,  // Business & Tech .
        RevShareDummy1, // For future
        RevShareDummy2, // For future

        ReferralUplineSplitPcnt,    // Eg 80% of rebate goes to upline, 20% to user
        ReferralDummy1, // For future
        ReferralDummy2, // For future

        SaleUserMaxFeePcnt,         // User's max fee% for any sale
        SaleUserCurrentFeePcnt,     // The current user's fee%
        SaleChargeFee18Dp,          // Each time a user buys, there's a fee like $1. Can be 0.
        SaleMaxPurchasePcntByFund,  // The max % of hardCap that SuperLauncher Fund can buy in a sale.
        SaleDummy1, // For future
        SaleDummy2, // For future

        lastIndex
    }

interface IParameterProvider {

    function setValue(ParamKey key, uint value) external;
    function setValues(ParamKey[] memory keys, uint[] memory values) external;
    function getValue(ParamKey key) external view returns (uint);
    function getValues(ParamKey[] memory keys) external view returns (uint[] memory);

    // Validation
    function validateChanges(ParamKey[] calldata keys, uint[] calldata values) external returns (bool success);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IReferralRewardVault {

    function registerCampaign(address campaign) external;
    function declareReward(address currency, uint totalSale, uint totalRebate, uint uplineSplitPcnt) external;
    function recordUserReward(address user, uint amount, address referer) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IRoles {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../base/Providers.sol";
import "../../base/Accessable.sol";
import "../../base/Whitelistable.sol";
import "../../base/SuperCertsClaimable.sol";
import "../../base/FeesDistributable.sol";
import "../interfaces/ICampaign.sol";
import "../interfaces/IManager.sol";
import "../../Constant.sol";

abstract contract Base is ICampaign, FeesDistributable, SuperCertsClaimable, Whitelistable, Accessable, Providers, ReentrancyGuard {

    using SafeERC20 for IERC20;

     enum State {
        Configured,
        Finalized,
        Finished,
        Failed,
        Cancelled
    }

    IManager internal _manager;
    uint internal _state; // Bitmask of bool //

    modifier onlyManager() {
        _require(msg.sender == address(_manager), "Not manager");
        _;
    }

    modifier canConfigure() {
        _require(_manager.getRoles().isConfigurator(msg.sender) && !getState(State.Finalized), "Cannot configure");
        _;
    }

    event Setup(address indexed executor);
    event Finalized(address indexed executor);
    event FinishUp(address indexed executor);

    constructor(IManager mgr) Accessable(mgr.getRoles())
        Providers(mgr.getParameterProvider(), mgr.getAddressProvider()) 
    {
        _manager = mgr;
    }

    // EXTERNAL & PUBLIC FUNCTIONS

    // Whitelist support
    function addRemoveWhitelist(address[] calldata users, bool add) external onlyConfigurator {
        _addRemoveWhitelist(users, add);
    }

    // SuperCerts support
    function setupCerts(address certsAddress, uint groupId, string memory groupName, bool vestFundInCerts, address teamAddress) external canConfigure {
        _requireNonZero(certsAddress);

        // If we turn on vesting for team's fund, then teamAddress has to be valid
        if (vestFundInCerts) {
            _requireNonZero(teamAddress);
        }
        _setupCerts(certsAddress, groupId, groupName, vestFundInCerts, teamAddress);
    }

    function getState(State s) public view returns (bool) {
        return (_state & (1 << uint8(s))) > 0;
    }

    function isConfigured() internal view returns (bool) {
        return (getState(State.Configured));
    }

    function isFinished() internal view returns (bool) {
        return (getState(State.Finished));
    }

    function isCancelled() internal view returns (bool) {
        return (getState(State.Cancelled));
    }

     // Implement ICampaign
    function cancelCampaign() external override onlyManager {
        _requireFinish(false);
        _setState(State.Cancelled, true);
    }

    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external override onlyManager {
        _transferTokenOut(tokenAddress, amount, to);
    }

    function finalize(bool requireSuperCert) external onlyApprover {
        _require(!getState(State.Finalized), "Already finalize");

        // Check that if SuperCert is needed, we have configured it.
        if (requireSuperCert) {
            (, , bool enabled, ,) = getCertsInfo();
            _require(enabled, "SuperCert not setup yet");
        }
        _setState(State.Finalized, true);
    }

    // INTERNAL FUNCTIONS

    function _setState(State state, bool on) internal {
        if (on) {
            _state |= (1 << uint8(state));
        } else {
            _state &= ~(1 << uint8(state));
        }
    }

    function _requireFinish(bool state) internal view {
        _require(state == getState(State.Finished), "Wrong finish state");
    }

    function _requireCancel(bool state) internal view {
        _require(state == getState(State.Cancelled), "Wrong cancelled state");
    }

    function _requireNonZero(uint a) internal pure {
        _require (a > 0, "Cannot be 0");
    }

    function _requireNonZero(uint a, uint b) internal pure {
        _require (a > 0 && b > 0, "Cannot be 0");
    }

    function _requireNonZero(address a) internal pure {
        _require (a != Constant.ZERO_ADDRESS, "Invalid address");
    }
     function _requireNonZero(address a, address b) internal pure {
        _require (a != Constant.ZERO_ADDRESS && b != Constant.ZERO_ADDRESS, "Invalid addresses");
    }

    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

        function _valueOf(uint fund, uint percent) internal pure returns (uint) {
        return (fund * percent) / Constant.PCNT_100;
    }

    function _valueMinusOff(uint fund, uint percentOff) internal pure returns (uint) {
        return ((Constant.PCNT_100 - percentOff) * fund) / Constant.PCNT_100;
    }

    function _interpolate(uint value, uint vMin, uint vMax, uint outMin, uint outMax) internal pure returns (uint) {
        if (value < vMin) {
            return 0;
        }
        if (value >= vMax) {
            return outMax;
        }
        uint rangeY = outMax - outMin;
        uint rangeX = vMax - vMin;
        return outMin + ((value - vMin) * rangeY ) / rangeX;
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IManager.sol";

abstract contract Factory {
    
    IManager internal _manager;
    uint internal _autoIndex;

    constructor(IManager manager) {
        _manager = manager;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface ICampaign {
    function cancelCampaign() external;
    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface ILpLocker {

    enum LpScheme {
        PercentRaise,
        FixedDollar
    }

    struct LpParam {
        LpScheme scheme;
        address router;
        uint value;
        uint rate;
        uint lockDuration;
        uint version;
        uint reservedUsdc; // Calculated USDC amount reserved for LP provision
        LpParamV3 v3;
    }

    struct LpParamV3 {
        uint24 poolFee;
        uint160 poolPrice;
        int24 minTick;
        int24 maxTick;
    }

    struct LpCreation {
        bool created;
        address lpToken;
        uint tokenId; // For v3
        uint unlockTime;
        address token;
        address currency;
        uint tokenQty;
        uint currencyQty;
        bool claimedUnusedTokens;
    }

    function createLp(LpParam memory params, address token, address currency, uint currencyDpValue) external; 
   
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";
import "../../interfaces/IParameterProvider.sol";
import "../../interfaces/IAddressProvider.sol";

interface IManager {
    function getRoles() external view returns (IRoles);
    function getParameterProvider() external view returns (IParameterProvider);
     function getAddressProvider() external view returns (IAddressProvider);
    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external;
    function isCampaignActive(address campaign) external view returns (bool);
}

interface ISaleManager is IManager {
    function addCampaign(address newContract) external;
    function isRouterApproved(address router) external view returns (bool);
}

interface ICertsManager is IManager {
    function addCerts(address certsContract) external;   
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface ISuperCerts {
    function setUserSourceByCampaign(uint groupId, string memory groupName, uint totalTokens,  bool finalizeGroup) external ;
    function setTeamSourceByCampaign(address teamAddress, address currency, uint amount) external;
    function claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount) external;
    function claimTeamCertsFromCampaign() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Types.sol";
import "../../base/Base.sol";
import "../../../interfaces/IReferralRewardVault.sol";

abstract contract SaleBase is Base {

    Types.Config internal _config;
    Types.GlobalParams internal _global;
    Types.Sales internal _sales;
    Types.Lp internal _lp;
    address private officialSigner;
    address private daoAddress; // To receive fund & referral reward if user does not have any upline

    event Buy(address indexed user, uint fund, uint totalPayable);
    event LpCreated(); 

    constructor(IManager mgr) Base(mgr) {
        (address dao, address signer) = _addressProvider.getOfficialAddresses();
        _requireNonZero(dao, signer);
        daoAddress = dao;
        officialSigner = signer;
    }

    //-----------------------------------------------------------//
    //   EXTERNAL FUNCTIONS WITH ROLE-ACCESS RIGHT REQUIREMENT   //
    //-----------------------------------------------------------//

    function finishUp() external nonReentrant onlyDeployer {
        _require(!isFinished() && !isCancelled(), "Finished or cancelled");
       
        // Softcap met ?
        if (!metSoftCap()) {
            // Failed. Can get a full refund
            _setState(State.Failed, true);
            return;
        } 
        _setState(State.Finished, true);

        emit FinishUp(msg.sender);
        uint raisedAmt = getRaisedAmount();
        if (raisedAmt == 0) {
            return;
        }

        // Calculate the amount to project
        uint projectAmt = _valueMinusOff(raisedAmt, _config.projectFeePcnt);
        // The total fee going to SL
        uint totalSLFee = _sales.totalProjectFeeCollected + _sales.totalUserFeeCollected + _sales.totalSaleChargeFeeCollected;
       
        // Distribute the fee to the various addresses
        _distributeFees(_paramProvider, _addressProvider, _config.currency, totalSLFee, raisedAmt);
       
       // LP Provision? Only IDO can have LP provision.   
        if (_lp.configured) {
           _lp.params.reservedUsdc = _getUsdcAmountForLp(projectAmt);
           projectAmt -= _lp.params.reservedUsdc; // This amount of USDC is reserved in the contract for subsequent LP provision    
       }

        // Transfer fund to either dao or SuperCerts to vest
        _transferFundToCertsOrDao(_config.currency, projectAmt, daoAddress);
    
        // In SuperCert, we set the total entitlement & vested fund
        uint totalEntitlement = getTokensQty(raisedAmt);
        _completeCerts(totalEntitlement, _config.currency, projectAmt);
    }

    function extendSale(uint endTime) external onlyDeployer {
        _require(!isFinished() && !isCancelled(), "Finished or cancelled");
        _require(endTime > _config.endTime, "Invalid endTime");
        _config.endTime = endTime;
    }

    function exportAll() external onlyConfigurator view returns (uint, address[] memory, uint[] memory) {
        uint len =  _sales.buyerList.length;
        address[] memory add = new address[](len);
        uint[] memory amounts = new uint[](len);

        address tmp;
        for (uint n = 0; n < len; n++) {
            tmp = _sales.buyerList[n];
            add[n] = tmp;
            amounts[n] = _sales.userPurchaseMap[tmp].totalFund;
        }
        return (len, add, amounts);
    }

    function export(uint from, uint to) external onlyConfigurator view returns (uint, address[] memory, uint[] memory) {
        uint len =  _sales.buyerList.length;
        require(len > 0  && from <= to, "Invalid range");
        require(to < len, "Out of range");

        uint count = to - from + 1;

        address[] memory add = new address[](count);
        uint[] memory amounts = new uint[](count);

        address tmp;
        for (uint n = 0; n < count; n++) {
            tmp = _sales.buyerList[n + from];
            add[n] = tmp;
            amounts[n] = _sales.userPurchaseMap[tmp].totalFund;
        }
        return (count, add, amounts);
    }

    //--------------------------------//
    //   EXTERNAL, PUBLIC  FUNCTIONS  //
    //--------------------------------//
    // Depending on user's stake, they will get a rebate% off (projectFee% + userFee%).
    // Eg: projectFee% = 5%. userFee% = 3%. Rebate% = 50%
    function getPayable(uint fund, uint stake) public view returns (uint totalPayable, uint saleChargeFee, uint rebatePcnt, uint projectFeePcnt, uint userFeePcnt) {
        projectFeePcnt = _config.projectFeePcnt;
        userFeePcnt = _config.userFeePcnt;
        saleChargeFee = _global.saleChargeFee;

        if (stake > 0) {
            rebatePcnt = _getStakerRebatePcnt(stake);
        }
        uint offPcnt = _valueOf(projectFeePcnt + userFeePcnt, rebatePcnt); // Eg 50% * (10% + 2%) = 6%
        totalPayable = saleChargeFee + ((Constant.PCNT_100 + userFeePcnt - offPcnt) * fund) / Constant.PCNT_100;
    }

    function isCertsClaimable(address user) public view returns (bool certsEnabled, bool claimable, bool claimed) {
        (certsEnabled, claimed) = _isCertsClaimable(user);
        if (isFinished() && !claimed && _sales.userPurchaseMap[user].totalFund > 0) {
            claimable = true;
        }
    }
    
    function returnFund() external nonReentrant {
        _requireFinish(false);
        _requireCancel(true);

        (bool refunded, uint paid) = getRefundInfo(msg.sender);
        _require(!refunded, "Already refunded");      
        _require(paid > 0, "Not bought");
        _sales.returnFundMap[msg.sender] = true; 

        _transferTokenOut(_config.currency, paid, msg.sender);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.Refund, paid, 0);
    }

    function getCapLeft() public view returns (uint) {
        return _config.hardCap - _sales.totalFundRaised;
    }

    function getRaisedAmount() public view returns(uint) {
        return _sales.totalFundRaised;
    }

    function getBuyersCount() external view returns (uint) {
        return _sales.buyerList.length;
    }

    function getConfig() external view returns(Types.Config memory config){
        return _config;
    }

    function getGlobalParams() external view returns(Types.GlobalParams memory params){
        return _global;
    }

    function getRefundInfo(address user) public view returns(bool refunded,  uint paid)
    {
        refunded = _sales.returnFundMap[user];  
        paid = _sales.userPurchaseMap[user].totalPaid;
    }

    //--------------------------------//
    //   IMPLEMENT VIRTUAL FUNCTIONS  //
    //--------------------------------//

    function claimCerts(address referer, bytes memory signature) external override nonReentrant {
        _requireFinish(true);
  
        uint bought = _sales.userPurchaseMap[msg.sender].totalFund;
        _require(bought > 0, "Not bought");
        uint totalEntitlement = getTokensQty(bought);

        _require(_claimCerts(msg.sender, totalEntitlement), "Already Claimed");

        // When a user claim their deed, we will also send this info to the referral reward system for rewarding 
        address[3] memory dest = _addressProvider.getFeeAddresses();

        // Check for valid referrer, If not valid, the SL will be the receiver
        bool hasUpline = (referer != Constant.ZERO_ADDRESS && verifyUpline(msg.sender, referer, signature));
        address upline = hasUpline ? referer : daoAddress;
         
        IReferralRewardVault(dest[0]).recordUserReward(msg.sender, bought, upline);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimCerts, totalEntitlement, 0);
    }

    function claimTeamCerts() external override nonReentrant {

        _requireFinish(true);
        (, address teamAddress, bool enabled, bool vestFund,)  = getCertsInfo();
        if (enabled && vestFund) {
            _require(_claimTeamCerts(), "Already Claimed");
            _manager.logData(teamAddress, DataSource.Campaign, DataAction.ClaimCerts, 0, 0);
        }
    }
    

    //------------------------------//
    //   DECLARE VIRTUAL FUNCTIONS  //
    //------------------------------//

    function metSoftCap() public virtual view returns (bool);
    function getTokensQty(uint fund) public virtual view returns (uint);
    function getStakerAllocation(uint stake) public virtual view returns (uint);

    //-----------------------//
    //   INTERNAL FUNCTIONS  //
    //-----------------------//

    function _setup(
        uint8 saleType,
        uint[2] calldata timings, 
        address[2] calldata addresses,
        uint hardCap,
        uint softCap, // can be  0
        uint projectFeePcnt, // can be 0
        bool useCustomUserFee,
        uint customUserFeePcnt) internal { 
            _require(saleType <= Constant.TYPE_NFT, "Wrong type");
            _requireNonZero(addresses[0], addresses[1]);
            _require(timings[0] > block.timestamp, "Invalid start time");
            _require(timings[1] > timings[0] || timings[1] == 0, "Invalid end time");
            _require(projectFeePcnt < Constant.PCNT_100, "Fee exceeded 100%");
            _requireNonZero(hardCap);

            _config.saleType = saleType;
            _config.projectFeePcnt = projectFeePcnt;

            if (useCustomUserFee) {
                _config.userFeePcnt = customUserFeePcnt;
            } else {
                _config.userFeePcnt = _paramProvider.getValue(ParamKey.SaleUserCurrentFeePcnt);
            }
            _require(_config.userFeePcnt < Constant.PCNT_100, "Fee exceeded 100%");
            
            _config.token = addresses[0];
            _config.tokenDpValue = _getDpValue(_config.token);
            _config.currency = addresses[1];
            _config.currencyDpValue = _getDpValue(_config.currency);
            _config.hardCap = hardCap;
            _config.softCap = softCap;       
            _config.startTime = timings[0];
            _config.endTime = timings[1];

             // Get global from parameterProvider
            uint[] memory data = _getGlobalParams();
            _global.minLaunch = data[0];
            _global.capLaunch = data[1];
            _global.stakerRebateMinPnct = data[2];
            _global.stakerRebateCapPnct = data[3];
            _global.maxPurchasePcntByFund = data[4];
            uint saleChargeFee18dp = data[5]; // This is in 18dp;
            if (saleChargeFee18dp > 0) {
                _global.saleChargeFee = (saleChargeFee18dp * _config.currencyDpValue) / Constant.E18;
            }

            _setState(State.Configured, true);
            emit Setup(msg.sender);
    }

    function _updatePurchase(address user, uint fund, uint totalPayable, uint stake) internal {

        // Check the fund and payable amount are correct
        (uint finalPayable, uint saleChargeFee, uint rebatePcnt, , ) = getPayable(fund, stake);
        _require(finalPayable == totalPayable, "Wrong amount");
       
        uint userFee = _valueOf(fund, _config.userFeePcnt);
        uint projectFee = _valueOf(fund, _config.projectFeePcnt);
        _updatePurchase(user, fund, totalPayable, saleChargeFee, userFee, projectFee, rebatePcnt);

        emit Buy(msg.sender, fund, totalPayable);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.Buy, fund, totalPayable);
    }
    function _updatePurchase(address user, uint fund, uint totalPayable, uint saleChargeFee, uint userFee, uint projectFee, uint rebatePcnt) private  {

        // Record new buying address if users first time buying.
        Types.Purchases storage purchases = _sales.userPurchaseMap[user];
        if (purchases.totalFund == 0) {
            _sales.buyerList.push(user);
        }

        // Update
        uint rebateAmt = _valueOf(userFee + projectFee, rebatePcnt);
        Types.PurchaseItem memory newBuy = Types.PurchaseItem(block.timestamp, fund, userFee, rebateAmt);
        purchases.items.push(newBuy);
        purchases.totalFund += fund;
        purchases.totalPaid += totalPayable;

        _sales.totalFundRaised += fund;
        _sales.totalProjectFeeCollected += _valueMinusOff(projectFee, rebatePcnt);
        _sales.totalUserFeeCollected += _valueMinusOff(userFee, rebatePcnt);
        _sales.totalSaleChargeFeeCollected += saleChargeFee;
    }

    function _getUsdcAmountForLp(uint raisedUsdcAfterFee) internal view returns (uint) {
        // Depending on the raised amount, fee and the scheme type, a specific amount of USDC is required to be 
        // used as LP provision
        if (_lp.params.scheme == ILpLocker.LpScheme.PercentRaise) {
            return _valueOf(raisedUsdcAfterFee, _lp.params.value);
        } else {
            return _lp.params.value;
        }
    }

    //----------------------//
    //   PRIVATE FUNCTIONS  //
    //----------------------//

    function _getGlobalParams() private view returns (uint[] memory) {
        ParamKey[] memory keys = new ParamKey[](6);
        keys[0] = ParamKey.StakerMinLaunch;
        keys[1] = ParamKey.StakerCapLaunch;
        keys[2] = ParamKey.StakerDiscountMinPnct;
        keys[3] = ParamKey.StakerDiscountCapPnct;
        keys[4] = ParamKey.SaleMaxPurchasePcntByFund;
        keys[5] = ParamKey.SaleChargeFee18Dp;
        return _paramProvider.getValues(keys);
    }

    function _getStakerRebatePcnt(uint stake) private view returns (uint) {
        return _interpolate(stake, _global.minLaunch, _global.capLaunch, _global.stakerRebateMinPnct, _global.stakerRebateCapPnct);
    }

    function verifyStake(address user, uint stake, bytes memory signature) internal view returns (uint) {
        bytes32 hash =  keccak256(abi.encodePacked(this, user, stake));
        return _verifyHash(hash, signature) ? stake : 0;
    }

    function verifyUpline(address user, address upline, bytes memory signature) internal view returns (bool) {
        bytes32 hash =  keccak256(abi.encodePacked(user, upline));
        return _verifyHash(hash, signature);
    }

    function _verifyHash(bytes32 hash, bytes memory signature) private view returns (bool) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(Constant.ETH_SIGN_PREFIX, hash));
        address signer = recover(prefixedHashMessage, signature);
        return (signer == officialSigner);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/ILpLocker.sol";

library Types {
    
    struct Config {
        uint8 saleType;
        address token;
        uint tokenDpValue;
        address currency;
        uint currencyDpValue;
        uint hardCap;
        uint softCap;
        uint startTime;
        uint endTime;
        uint projectFeePcnt;
        uint userFeePcnt;
    }
    // Note: unitPrice is not part of Config, so that the derived contract can support dynamic pricing if ever needed.


    // Get from parametersProvider and can't override in sale campaign.
    struct GlobalParams {
        uint minLaunch;             // Eg: Min 1000 vLaunch
        uint capLaunch;             // Eg: Cap at 50,000 vLaunch
        uint stakerRebateMinPnct;   // Eg: 1000 svLaunch gets 0.6% discount on total Fee.
        uint stakerRebateCapPnct;   // Eg: 50,000 svLaunch gets 30%% discount on total Fee.
        uint saleChargeFee;         // Eg: $1 sale charge fee per purchase
        uint maxPurchasePcntByFund; 
              
    }

    struct Sales {
        uint totalFundRaised;
        uint totalProjectFeeCollected;
        uint totalUserFeeCollected;
        uint totalSaleChargeFeeCollected;
        mapping(address=>Purchases)  userPurchaseMap;
        address[]  buyerList; // For exporting purpose
        mapping(address=>bool) returnFundMap; // Refund Support
    }

    struct Purchases {
        PurchaseItem[] items;     
        uint totalFund;   // In currency unit. Determine the tokens amount a user will get.
        uint totalPaid;   // In currency unit. Total paid, after user fee and deduction for rebate. Include mgmt fees.
    }

    struct PurchaseItem {
        uint time;
        uint fund;
        uint fee;
        uint rebate; // Rebate can be higher than fee, as it include rebate on project fee.
    }

    struct Lp {
        address lockerAddress;
        bool configured;
        bool lpCreated;
        ILpLocker.LpParam params;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./FcfsTypes.sol";
import "../base/SaleBase.sol";
import "../../interfaces/ILpLocker.sol";
import "../../interfaces/IManager.sol";


/*
This campaign supports 3 types of Sale. 
(1) IDO
(2) NFT
(3) OTC

A campaign can have a project fee% and/or a user's fee%.
Qualified svLaunch staker can buy in the staker round, before the public round opens.
Qualified svLaunch staker can also get a rebate of the above fee(s).

IDO:
- min, max allocation depends on the amount of user's stake Launch.

NFT, OTC:
- min, max is same as public allocation
*/

contract FcfsCampaign is SaleBase {

    constructor(IManager manager) SaleBase(manager) { }

    FcfsTypes.CustomData private _data; 

    //-----------------------------------------------------------//
    //   EXTERNAL FUNCTIONS WITH ROLE-ACCESS RIGHT REQUIREMENT   //
    //-----------------------------------------------------------//

    function setup(
        uint8 saleType,
        uint[2] calldata timings, // Open, End of sale. If end is 0, then it does not have an end. 
        uint preOpenDuration, // The duration before open that the staker can buy before the public
        address[2] calldata addresses, // token, currency
        uint hardCap,   // In currency. 
        uint softCap,   // In currency. Can be 0.
        uint unitPrice,
        uint[6] calldata minMaxAlloc,
        uint projectFeePcnt, // Fee charged to project. Can be different based on individual project.
        bool useCustomUserFee,
        uint customUserFeePcnt
    ) external canConfigure {
        _setup(saleType, timings, addresses, hardCap, softCap, projectFeePcnt, useCustomUserFee, customUserFeePcnt);
        _setupCustomData(preOpenDuration, unitPrice, minMaxAlloc);
    }

    function setupLpV2(address locker, address router, ILpLocker.LpScheme scheme, uint lpValue, uint rate) public canConfigure {
        _require(isConfigured(), "Setup first");
        _require(_config.saleType == Constant.TYPE_IDO, "Not Ido");
        _requireNonZero(lpValue, rate);

        // Check router is one of the approved router? 
        bool routerOk = ISaleManager(address(_manager)).isRouterApproved(router);
        _require(routerOk, "Router not whitelisted");

        _lp.lockerAddress = locker;
        _lp.configured = true;
        _lp.params.router = router;
        _lp.params.scheme = scheme;
        _lp.params.value = lpValue;
        _lp.params.rate = rate; // The USDC amount per token. In USDC dp.
        _lp.params.version = 2;
       
       
        // For this setup, check to make sure that if we just hit softcap, the USDC (after fee) is enough to provide LP.
        uint softCapAfterFee = _valueMinusOff(_config.softCap, _config.projectFeePcnt);

        uint usdcNeeded = _getUsdcAmountForLp(softCapAfterFee);
        _require(usdcNeeded <= softCapAfterFee, "Softcap too low for Lp");
    }

    function setupLpV3(address locker, address router, ILpLocker.LpScheme scheme, uint lpValue, uint rate, uint24 poolFee, uint160 poolPrice, int24 minTick, int24 maxTick) external canConfigure {
        setupLpV2(locker, router, scheme, lpValue, rate);

        _requireNonZero(poolPrice);
        _require(minTick > 0 && maxTick > 0, "Invalid ticks");

        _lp.params.version = 3;
        _lp.params.v3.poolFee = poolFee;
        _lp.params.v3.poolPrice= poolPrice;
        _lp.params.v3.minTick = minTick;
        _lp.params.v3.maxTick = maxTick;
    }

    function createLp() external nonReentrant onlyDeployer {
        if (_lp.configured && !_lp.lpCreated && _lp.params.reservedUsdc > 0) {

            _lp.lpCreated = true;
            // Send the USDC to LpLocker
            _transferTokenOut(_config.currency, _lp.params.reservedUsdc, _lp.lockerAddress);
            // Call Lp Locker to create Lp
            ILpLocker(_lp.lockerAddress).createLp(_lp.params, _config.token, _config.currency, _config.currencyDpValue);
            emit LpCreated();
        }
    }


    //--------------------------------//
    //   EXTERNAL, PUBLIC  FUNCTIONS  //
    //--------------------------------//

    // fund: amount used to buy the token. Exclude fee.
    // totalPayable: total cost of purchase including fee charged to user. This value is for counter-checking/verification purpose.
    function buy(uint fund, uint totalPayable) external nonReentrant {
        _buy(fund, totalPayable, 0, "");
    }

    function buyStaker(uint fund, uint totalPayable, uint stake, bytes memory signature) external nonReentrant {
        _buy(fund, totalPayable, stake, signature);
    }

    function getAllocationInfo(address user, uint stake) public view returns(uint8 userType, uint totalBought, uint min, uint max) {
        
        if (isWhiteListed(user)) {
            min = _data.alloc.fund.min;
            max = _data.alloc.fund.max;
            userType = Constant.WHITELISTED;
        } else if (stake >= _global.minLaunch) {
            min = _data.alloc.staker.min;
            max = getStakerAllocation(stake);
            userType = Constant.STAKER;
        } else {
            min = _data.alloc.publicUser.min;
            max = _data.alloc.publicUser.max;
            userType = Constant.PUBLIC;
        }
        Types.Purchases storage purchases = _sales.userPurchaseMap[user];
        totalBought = purchases.totalFund;
    }

    //--------------------------------//
    //   IMPLEMENT VIRTUAL FUNCTIONS  //
    //--------------------------------//

    function metSoftCap() public override view returns (bool) {
        return _sales.totalFundRaised >= _config.softCap;
    }

    function getTokensQty(uint fund) public override view returns (uint) {
        return (fund * _config.tokenDpValue) / _data.unitPrice;
    }

    function getStakerAllocation(uint stake) public virtual override view returns (uint) { 
        return _interpolate(stake, _global.minLaunch, _global.capLaunch, _data.alloc.staker.min, _data.alloc.staker.max);
    }

    //----------------------//
    //   PRIVATE FUNCTIONS  //
    //----------------------//

    function _setupCustomData(uint preOpenDuration, uint unitPrice, uint[6] calldata minMaxAlloc) private {
        _requireNonZero(unitPrice);
        _requireNonZero(minMaxAlloc[0], minMaxAlloc[1]);
        _requireNonZero(minMaxAlloc[2], minMaxAlloc[3]);
        _requireNonZero(minMaxAlloc[4], minMaxAlloc[5]);
        _require(minMaxAlloc[1] >= minMaxAlloc[0], "Invalid min, max");
        _require(minMaxAlloc[3] >= minMaxAlloc[2], "Invalid min, max");
        _require(minMaxAlloc[5] >= minMaxAlloc[4], "Invalid min, max");

        _data.unitPrice = unitPrice;
        _data.preOpenTime = _config.startTime - preOpenDuration;
        _require(block.timestamp < _data.preOpenTime, "Invalid preopen time");

        _data.alloc.publicUser.min = minMaxAlloc[0];
        _data.alloc.publicUser.max = minMaxAlloc[1];
        _data.alloc.staker.min = minMaxAlloc[2];
        _data.alloc.staker.max = minMaxAlloc[3];
        _data.alloc.fund.min = minMaxAlloc[4];
        _data.alloc.fund.max = minMaxAlloc[5];
    }

    function _buy(uint fund, uint totalPayable, uint stake, bytes memory signature) private {

        _require(fund > 0 && isConfigured(), "Cannot buy");

        // Make sure no over-sold
        uint left = getCapLeft();
        require(fund <= left, "Not enough left");

        if (stake > 0) {
            stake = verifyStake(msg.sender, stake, signature);
            require(stake > 0, "Wrong stake");
        }

        (uint8 userType, uint totalBought, uint min, uint max) = getAllocationInfo(msg.sender, stake);
        bool preOpenUser = userType != Constant.PUBLIC; // Stakers and whitelist can buy say 15 mins before live
        _require(_isLive(preOpenUser), "Not live");

        // Check limit
        _require(totalBought + fund <= max, "Exceeded max");
        // Last user can buy less than min
        if ( fund < min) {
           _require(fund == left, "Less than min");
        }

        _transferTokenIn(_config.currency, totalPayable);
        _updatePurchase(msg.sender, fund, totalPayable, stake);
    }
    
    function _isLive(bool isPreOpenUser) private view returns (bool) {
        bool opened = block.timestamp >= (isPreOpenUser ? _data.preOpenTime : _config.startTime);
        bool ended = _config.endTime == 0 ? false : block.timestamp >= _config.endTime;
        return (opened && !ended && !isFinished() && !isCancelled());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../base/Factory.sol";
import "./FcfsCampaign.sol";


contract FcfsFactory is Factory {
    
    constructor(ISaleManager manager) Factory(manager) { }

    function create() external {
        if (_manager.getRoles().isDeployer(msg.sender)) {
            bytes32 salt = keccak256(abi.encodePacked(_autoIndex++, msg.sender));
            address newAddress = address(new FcfsCampaign{salt: salt}(_manager));
            ISaleManager(address(_manager)).addCampaign(newAddress);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

library FcfsTypes {
    
    struct CustomData {
        uint unitPrice; // Price (in currency) per unit of token (eg 1e18) 
        uint preOpenTime; // Stakers and Whitelisted Fund can buy slightly earlier (from preOpenTime to startTime 
        Alloc alloc;
    }

    struct Alloc {
        MinMax publicUser;
        MinMax staker;
        MinMax fund;
    }

    struct MinMax {
        uint min;   // In currency unit
        uint max;   // In currency unit
    }
}