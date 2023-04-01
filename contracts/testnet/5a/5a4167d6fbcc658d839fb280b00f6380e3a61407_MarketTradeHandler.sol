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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract Owned {
  error Owned_NotOwner();
  error Owned_NotPendingOwner();

  address public owner;
  address public pendingOwner;

  event OwnershipTransferred(
    address indexed _previousOwner,
    address indexed _newOwner
  );

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Owned_NotOwner();
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    // Move _newOwner to pendingOwner
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    // Check
    if (msg.sender != pendingOwner) revert Owned_NotPendingOwner();

    // Log
    emit OwnershipTransferred(owner, pendingOwner);

    // Effect
    owner = pendingOwner;
    delete pendingOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// base
import { Owned } from "@hmx/base/Owned.sol";

//contracts
import { OracleMiddleware } from "@hmx/oracle/OracleMiddleware.sol";
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";
import { PerpStorage } from "@hmx/storages/PerpStorage.sol";
// Interfaces
import { ICalculator } from "@hmx/contracts/interfaces/ICalculator.sol";
import { IConfigStorage } from "@hmx/storages/interfaces/IConfigStorage.sol";

contract Calculator is Owned, ICalculator {
  uint32 internal constant BPS = 1e4;
  uint64 internal constant ETH_PRECISION = 1e18;
  uint64 internal constant RATE_PRECISION = 1e18;

  // EVENTS
  event LogSetOracle(address indexed oldOracle, address indexed newOracle);
  event LogSetVaultStorage(address indexed oldVaultStorage, address indexed vaultStorage);
  event LogSetConfigStorage(address indexed oldConfigStorage, address indexed configStorage);
  event LogSetPerpStorage(address indexed oldPerpStorage, address indexed perpStorage);

  // STATES
  // @todo - move oracle config to storage
  address public oracle;
  address public vaultStorage;
  address public configStorage;
  address public perpStorage;

  constructor(address _oracle, address _vaultStorage, address _perpStorage, address _configStorage) {
    // Sanity check
    if (
      _oracle == address(0) || _vaultStorage == address(0) || _perpStorage == address(0) || _configStorage == address(0)
    ) revert ICalculator_InvalidAddress();

    PerpStorage(_perpStorage).getGlobalState();
    VaultStorage(_vaultStorage).plpLiquidityDebtUSDE30();
    ConfigStorage(_configStorage).getLiquidityConfig();

    oracle = _oracle;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;
    perpStorage = _perpStorage;
  }

  /// @notice getAUME30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return PLP Value in E18 format
  function getAUME30(bool _isMaxPrice) external view returns (uint256) {
    // plpAUM = value of all asset + pnlShort + pnlLong + pendingBorrowingFee
    uint256 pendingBorrowingFeeE30 = _getPendingBorrowingFeeE30();
    int256 pnlE30 = _getGlobalPNLE30();
    uint256 aum = _getPLPValueE30(_isMaxPrice) + pendingBorrowingFeeE30;

    if (pnlE30 < 0) {
      aum += uint256(-pnlE30);
    } else {
      uint256 _pnl = uint256(pnlE30);
      if (aum < _pnl) return 0;
      unchecked {
        aum -= _pnl;
      }
    }

    return aum;
  }

  /// @notice getPendingBorrowingFeeE30 This function calculates the total pending borrowing fee from all asset classes.
  /// @return total pending borrowing fee in e30 format
  function getPendingBorrowingFeeE30() external view returns (uint256) {
    return _getPendingBorrowingFeeE30();
  }

  /// @notice _getPendingBorrowingFeeE30 This function calculates the total pending borrowing fee from all asset classes.
  /// @return total pending borrowing fee in e30 format
  function _getPendingBorrowingFeeE30() internal view returns (uint256) {
    // SLOAD
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    uint256 _len = ConfigStorage(configStorage).getAssetClassConfigsLength();

    // Get the PLP TVL.
    uint256 _plpTVL = _getPLPValueE30(false);
    uint256 _pendingBorrowingFee; // sum from each asset class
    for (uint256 i; i < _len; ) {
      PerpStorage.GlobalAssetClass memory _assetClassState = _perpStorage.getGlobalAssetClassByIndex(i);

      uint256 _borrowingFeeE30 = (_getNextBorrowingRate(uint8(i), _plpTVL) * _assetClassState.reserveValueE30) /
        RATE_PRECISION;

      // Formula:
      // pendingBorrowingFee = (sumBorrowingFeeE30 - sumSettledBorrowingFeeE30) + latestBorrowingFee
      _pendingBorrowingFee +=
        (_assetClassState.sumBorrowingFeeE30 - _assetClassState.sumSettledBorrowingFeeE30) +
        _borrowingFeeE30;

      unchecked {
        ++i;
      }
    }

    return _pendingBorrowingFee;
  }

  /// @notice GetPLPValue in E30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return PLP Value
  function getPLPValueE30(bool _isMaxPrice) external view returns (uint256) {
    return _getPLPValueE30(_isMaxPrice);
  }

  /// @notice GetPLPValue in E30
  /// @param _isMaxPrice Use Max or Min Price
  /// @return PLP Value
  function _getPLPValueE30(bool _isMaxPrice) internal view returns (uint256) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    bytes32[] memory _plpAssetIds = _configStorage.getPlpAssetIds();
    uint256 assetValue = 0;
    uint256 _len = _plpAssetIds.length;

    for (uint256 i = 0; i < _len; ) {
      uint256 value = _getPLPUnderlyingAssetValueE30(_plpAssetIds[i], _configStorage, _isMaxPrice);
      unchecked {
        assetValue += value;
        ++i;
      }
    }

    return assetValue;
  }

  /// @notice Get PLP underlying asset value in E30
  /// @param _underlyingAssetId the underlying asset id, the one we want to find the value
  /// @param _configStorage config storage
  /// @param _isMaxPrice Use Max or Min Price
  /// @return PLP Value
  function _getPLPUnderlyingAssetValueE30(
    bytes32 _underlyingAssetId,
    ConfigStorage _configStorage,
    bool _isMaxPrice
  ) internal view returns (uint256) {
    ConfigStorage.AssetConfig memory _assetConfig = _configStorage.getAssetConfig(_underlyingAssetId);

    (uint256 _priceE30, , ) = OracleMiddleware(oracle).unsafeGetLatestPrice(_underlyingAssetId, _isMaxPrice);
    uint256 value = (VaultStorage(vaultStorage).plpLiquidity(_assetConfig.tokenAddress) * _priceE30) /
      (10 ** _assetConfig.decimals);

    return value;
  }

  /// @notice getPLPPrice in e18 format
  /// @param _aum aum in PLP
  /// @param _plpSupply Total Supply of PLP token
  /// @return PLP Price in e18
  function getPLPPrice(uint256 _aum, uint256 _plpSupply) external pure returns (uint256) {
    if (_plpSupply == 0) return 0;
    return _aum / _plpSupply;
  }

  /// @notice get all PNL in e30 format
  /// @return pnl value
  function _getGlobalPNLE30() internal view returns (int256) {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    OracleMiddleware _oracle = OracleMiddleware(oracle);

    int256 totalPnlLong = 0;
    int256 totalPnlShort = 0;
    uint256 _len = _configStorage.getMarketConfigsLength();

    for (uint256 i = 0; i < _len; ) {
      ConfigStorage.MarketConfig memory _marketConfig = _configStorage.getMarketConfigByIndex(i);
      PerpStorage.GlobalMarket memory _globalMarket = _perpStorage.getGlobalMarketByIndex(i);

      int256 _pnlLongE30 = 0;
      int256 _pnlShortE30 = 0;
      (uint256 priceE30, , ) = _oracle.unsafeGetLatestPrice(_marketConfig.assetId, false);

      if (_globalMarket.longAvgPrice > 0 && _globalMarket.longPositionSize > 0) {
        if (priceE30 < _globalMarket.longAvgPrice) {
          uint256 _absPNL = ((_globalMarket.longAvgPrice - priceE30) * _globalMarket.longPositionSize) /
            _globalMarket.longAvgPrice;
          _pnlLongE30 = -int256(_absPNL);
        } else {
          uint256 _absPNL = ((priceE30 - _globalMarket.longAvgPrice) * _globalMarket.longPositionSize) /
            _globalMarket.longAvgPrice;
          _pnlLongE30 = int256(_absPNL);
        }
      }

      if (_globalMarket.shortAvgPrice > 0 && _globalMarket.shortPositionSize > 0) {
        if (_globalMarket.shortAvgPrice < priceE30) {
          uint256 _absPNL = ((priceE30 - _globalMarket.shortAvgPrice) * _globalMarket.shortPositionSize) /
            _globalMarket.shortAvgPrice;

          _pnlShortE30 = -int256(_absPNL);
        } else {
          uint256 _absPNL = ((_globalMarket.shortAvgPrice - priceE30) * _globalMarket.shortPositionSize) /
            _globalMarket.shortAvgPrice;
          _pnlShortE30 = int256(_absPNL);
        }
      }

      {
        unchecked {
          ++i;
          totalPnlLong += _pnlLongE30;
          totalPnlShort += _pnlShortE30;
        }
      }
    }

    return totalPnlLong + totalPnlShort;
  }

  /// @notice getMintAmount in e18 format
  /// @param _aumE30 aum in PLP E30
  /// @param _totalSupply PLP total supply
  /// @param _value value in USD e30
  /// @return mintAmount in e18 format
  function getMintAmount(uint256 _aumE30, uint256 _totalSupply, uint256 _value) public pure returns (uint256) {
    return _aumE30 == 0 ? _value / 1e12 : (_value * _totalSupply) / _aumE30;
  }

  function convertTokenDecimals(
    uint256 fromTokenDecimals,
    uint256 toTokenDecimals,
    uint256 amount
  ) public pure returns (uint256) {
    return (amount * 10 ** toTokenDecimals) / 10 ** fromTokenDecimals;
  }

  function getAddLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external view returns (uint32) {
    if (!_configStorage.getLiquidityConfig().dynamicFeeEnabled) {
      return _configStorage.getLiquidityConfig().depositFeeRateBPS;
    }

    return
      _getFeeBPS(
        _tokenValueE30,
        _getPLPUnderlyingAssetValueE30(_configStorage.tokenAssetIds(_token), _configStorage, false),
        _getPLPValueE30(false),
        _configStorage.getLiquidityConfig(),
        _configStorage.getAssetPlpTokenConfigByToken(_token),
        LiquidityDirection.ADD
      );
  }

  function getRemoveLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external view returns (uint32) {
    if (!_configStorage.getLiquidityConfig().dynamicFeeEnabled) {
      return _configStorage.getLiquidityConfig().withdrawFeeRateBPS;
    }

    return
      _getFeeBPS(
        _tokenValueE30,
        _getPLPUnderlyingAssetValueE30(_configStorage.tokenAssetIds(_token), _configStorage, true),
        _getPLPValueE30(true),
        _configStorage.getLiquidityConfig(),
        _configStorage.getAssetPlpTokenConfigByToken(_token),
        LiquidityDirection.REMOVE
      );
  }

  function _getFeeBPS(
    uint256 _value, //e30
    uint256 _liquidityUSD, //e30
    uint256 _totalLiquidityUSD, //e30
    ConfigStorage.LiquidityConfig memory _liquidityConfig,
    ConfigStorage.PLPTokenConfig memory _plpTokenConfig,
    LiquidityDirection direction
  ) internal pure returns (uint32) {
    uint32 _feeBPS = direction == LiquidityDirection.ADD
      ? _liquidityConfig.depositFeeRateBPS
      : _liquidityConfig.withdrawFeeRateBPS;
    uint32 _taxBPS = _liquidityConfig.taxFeeRateBPS;
    uint256 _totalTokenWeight = _liquidityConfig.plpTotalTokenWeight;

    uint256 startValue = _liquidityUSD;
    uint256 nextValue = startValue + _value;
    if (direction == LiquidityDirection.REMOVE) nextValue = _value > startValue ? 0 : startValue - _value;

    uint256 targetValue = _getTargetValue(_totalLiquidityUSD, _plpTokenConfig.targetWeight, _totalTokenWeight);

    if (targetValue == 0) return _feeBPS;

    uint256 startTargetDiff = startValue > targetValue ? startValue - targetValue : targetValue - startValue;
    uint256 nextTargetDiff = nextValue > targetValue ? nextValue - targetValue : targetValue - nextValue;

    // nextValue moves closer to the targetValue -> positive case;
    // Should apply rebate.
    if (nextTargetDiff < startTargetDiff) {
      uint32 rebateBPS = uint32((_taxBPS * startTargetDiff) / targetValue);
      return rebateBPS > _feeBPS ? 0 : _feeBPS - rebateBPS;
    }

    // _nextWeight represented 18 precision
    uint256 _nextWeight = (nextValue * ETH_PRECISION) / (_totalLiquidityUSD + _value);
    if (_nextWeight > _plpTokenConfig.targetWeight + _plpTokenConfig.maxWeightDiff) {
      revert ICalculator_PoolImbalance();
    }

    // If not then -> negative impact to the pool.
    // Should apply tax.
    uint256 midDiff = (startTargetDiff + nextTargetDiff) / 2;
    if (midDiff > targetValue) {
      midDiff = targetValue;
    }
    _taxBPS = uint32((_taxBPS * midDiff) / targetValue);

    return uint32(_feeBPS + _taxBPS);
  }

  /// @notice get settlement fee rate
  /// @param _token - token
  /// @param _liquidityUsdDelta - withdrawal amount
  /// @return _settlementFeeRate in e18 format
  function getSettlementFeeRate(
    address _token,
    uint256 _liquidityUsdDelta
  ) external view returns (uint256 _settlementFeeRate) {
    // usd debt
    uint256 _tokenLiquidityUsd = _getPLPUnderlyingAssetValueE30(
      ConfigStorage(configStorage).tokenAssetIds(_token),
      ConfigStorage(configStorage),
      false
    );
    if (_tokenLiquidityUsd == 0) return 0;

    // total usd debt

    uint256 _totalLiquidityUsd = _getPLPValueE30(false);
    ConfigStorage.LiquidityConfig memory _liquidityConfig = ConfigStorage(configStorage).getLiquidityConfig();

    // target value = total usd debt * target weight ratio (targe weigh / total weight);

    uint256 _targetUsd = (_totalLiquidityUsd *
      ConfigStorage(configStorage).getAssetPlpTokenConfigByToken(_token).targetWeight) /
      _liquidityConfig.plpTotalTokenWeight;

    if (_targetUsd == 0) return 0;

    // next value
    uint256 _nextUsd = _tokenLiquidityUsd - _liquidityUsdDelta;

    // current target diff
    uint256 _currentTargetDiff;
    uint256 _nextTargetDiff;
    unchecked {
      _currentTargetDiff = _tokenLiquidityUsd > _targetUsd
        ? _tokenLiquidityUsd - _targetUsd
        : _targetUsd - _tokenLiquidityUsd;
      // next target diff
      _nextTargetDiff = _nextUsd > _targetUsd ? _nextUsd - _targetUsd : _targetUsd - _nextUsd;
    }

    if (_nextTargetDiff < _currentTargetDiff) return 0;

    // settlement fee rate = (next target diff + current target diff / 2) * base tax fee / target usd
    return
      (((_nextTargetDiff + _currentTargetDiff) / 2) * _liquidityConfig.taxFeeRateBPS * ETH_PRECISION) /
      _targetUsd /
      BPS;
  }

  // return in e18
  function _getTargetValue(
    uint256 totalLiquidityUSD, //e30
    uint256 tokenWeight, //e18
    uint256 totalTokenWeight // 1e18
  ) public pure returns (uint256) {
    if (totalLiquidityUSD == 0) return 0;

    return (totalLiquidityUSD * tokenWeight) / totalTokenWeight;
  }

  ////////////////////////////////////////////////////////////////////////////////////
  //////////////////////  SETTERs  ///////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////

  /// @notice Set new Oracle contract address.
  /// @param _oracle New Oracle contract address.
  function setOracle(address _oracle) external onlyOwner {
    // @todo - Sanity check
    if (_oracle == address(0)) revert ICalculator_InvalidAddress();
    emit LogSetOracle(oracle, _oracle);
    oracle = _oracle;
  }

  /// @notice Set new VaultStorage contract address.
  /// @param _vaultStorage New VaultStorage contract address.
  function setVaultStorage(address _vaultStorage) external onlyOwner {
    // @todo - Sanity check
    if (_vaultStorage == address(0)) revert ICalculator_InvalidAddress();
    emit LogSetVaultStorage(vaultStorage, _vaultStorage);
    vaultStorage = _vaultStorage;
  }

  /// @notice Set new ConfigStorage contract address.
  /// @param _configStorage New ConfigStorage contract address.
  function setConfigStorage(address _configStorage) external onlyOwner {
    // @todo - Sanity check
    if (_configStorage == address(0)) revert ICalculator_InvalidAddress();
    emit LogSetConfigStorage(configStorage, _configStorage);
    configStorage = _configStorage;
  }

  /// @notice Set new PerpStorage contract address.
  /// @param _perpStorage New PerpStorage contract address.
  function setPerpStorage(address _perpStorage) external onlyOwner {
    // @todo - Sanity check
    if (_perpStorage == address(0)) revert ICalculator_InvalidAddress();
    emit LogSetPerpStorage(perpStorage, _perpStorage);
    perpStorage = _perpStorage;
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ////////////////////// CALCULATOR
  ////////////////////////////////////////////////////////////////////////////////////

  /// @notice Calculate for value on trader's account including Equity, IMR and MMR.
  /// @dev Equity = Sum(collateral tokens' Values) + Sum(unrealized PnL) - Unrealized Borrowing Fee - Unrealized Funding Fee
  /// @param _subAccount Trader account's address.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _equityValueE30 Total equity of trader's account.
  function getEquity(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) public view returns (int256 _equityValueE30) {
    // Calculate collateral tokens' value on trader's sub account
    uint256 _collateralValueE30 = getCollateralValue(_subAccount, _limitPriceE30, _limitAssetId);

    // Calculate unrealized PnL and unrealized fee
    (int256 _unrealizedPnlValueE30, int256 _unrealizedFeeValueE30) = getUnrealizedPnlAndFee(
      _subAccount,
      _limitPriceE30,
      _limitAssetId
    );

    // Calculate equity
    _equityValueE30 += int256(_collateralValueE30);
    _equityValueE30 += _unrealizedPnlValueE30;
    _equityValueE30 -= _unrealizedFeeValueE30;

    return _equityValueE30;
  }

  struct GetUnrealizedPnlAndFee {
    PerpStorage.Position position;
    uint256 absSize;
    bool isLong;
    uint256 priceE30;
    bool isProfit;
    uint256 delta;
  }

  // @todo integrate realizedPnl Value

  /// @notice Calculate unrealized PnL from trader's sub account.
  /// @dev This unrealized pnl deducted by collateral factor.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _unrealizedPnlE30 PnL value after deducted by collateral factor.
  function getUnrealizedPnlAndFee(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) public view returns (int256 _unrealizedPnlE30, int256 _unrealizedFeeE30) {
    // Get all trader's opening positions
    PerpStorage.Position[] memory _positions = PerpStorage(perpStorage).getPositionBySubAccount(_subAccount);

    ConfigStorage.MarketConfig memory _marketConfig;
    PerpStorage.GlobalMarket memory _globalMarket;
    uint256 pnlFactorBps = ConfigStorage(configStorage).pnlFactorBPS();
    uint256 liquidationFee = ConfigStorage(configStorage).getLiquidationConfig().liquidationFeeUSDE30;

    GetUnrealizedPnlAndFee memory _var;
    uint256 _len = _positions.length;

    // Loop through all trader's positions
    for (uint256 i; i < _len; ) {
      _var.position = _positions[i];
      _var.absSize = _abs(_var.position.positionSizeE30);
      _var.isLong = _var.position.positionSizeE30 > 0;

      // Get market config according to opening position
      _marketConfig = ConfigStorage(configStorage).getMarketConfigByIndex(_var.position.marketIndex);
      _globalMarket = PerpStorage(perpStorage).getGlobalMarketByIndex(_var.position.marketIndex);

      // Check to overwrite price
      if (_limitAssetId == _marketConfig.assetId && _limitPriceE30 != 0) {
        _var.priceE30 = _limitPriceE30;
      } else {
        // @todo - validate price age
        (_var.priceE30, , , ) = OracleMiddleware(oracle).getLatestAdaptivePriceWithMarketStatus(
          _marketConfig.assetId,
          !_var.isLong, // if current position is SHORT position, then we use max price
          (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
          -_var.position.positionSizeE30,
          _marketConfig.fundingRate.maxSkewScaleUSD
        );
      }

      {
        // Calculate pnl
        (_var.isProfit, _var.delta) = _getDelta(
          _var.absSize,
          _var.isLong,
          _var.priceE30,
          _var.position.avgEntryPriceE30,
          _var.position.lastIncreaseTimestamp
        );
        if (_var.isProfit) {
          _unrealizedPnlE30 += int256((pnlFactorBps * _var.delta) / BPS);
        } else {
          _unrealizedPnlE30 -= int256(_var.delta);
        }
      }

      {
        {
          // Calculate borrowing fee
          uint256 _plpTVL = _getPLPValueE30(false);
          PerpStorage.GlobalAssetClass memory _globalAssetClass = PerpStorage(perpStorage).getGlobalAssetClassByIndex(
            _marketConfig.assetClass
          );
          uint256 _nextBorrowingRate = _getNextBorrowingRate(_marketConfig.assetClass, _plpTVL);
          uint256 _borrowingRate = _globalAssetClass.sumBorrowingRate +
            _nextBorrowingRate -
            _var.position.entryBorrowingRate;
          // Calculate the borrowing fee based on reserved value, borrowing rate.
          _unrealizedFeeE30 += int256((_var.position.reserveValueE30 * _borrowingRate) / 1e18);
          // getBorrowingFee(_marketConfig.assetClass, _var.position.reserveValueE30, _var.position.entryBorrowingRate)
        }
        {
          // Calculate funding fee
          int256 nextFundingRate = _getNextFundingRate(_var.position.marketIndex);
          int256 fundingRate = _globalMarket.currentFundingRate + nextFundingRate;
          _unrealizedFeeE30 += _getFundingFee(_var.isLong, _var.absSize, fundingRate, _var.position.entryFundingRate);
        }
        // Calculate trading fee
        _unrealizedFeeE30 += int256((_var.absSize * _marketConfig.decreasePositionFeeRateBPS) / BPS);
      }

      unchecked {
        ++i;
      }
    }

    if (_len != 0) {
      // Calculate liquidation fee
      _unrealizedFeeE30 += int256(liquidationFee);
    }

    return (_unrealizedPnlE30, _unrealizedFeeE30);
  }

  /// @notice Calculate collateral tokens to value from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _collateralValueE30
  function getCollateralValue(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) public view returns (uint256 _collateralValueE30) {
    // Get list of current depositing tokens on trader's account
    address[] memory _traderTokens = VaultStorage(vaultStorage).getTraderTokens(_subAccount);

    // Loop through list of current depositing tokens
    for (uint256 i; i < _traderTokens.length; ) {
      address _token = _traderTokens[i];
      ConfigStorage.CollateralTokenConfig memory _collateralTokenConfig = ConfigStorage(configStorage)
        .getCollateralTokenConfigs(_token);

      // Get token decimals from ConfigStorage
      uint256 _decimals = ConfigStorage(configStorage).getAssetConfigByToken(_token).decimals;

      // Get collateralFactor from ConfigStorage
      uint32 collateralFactorBPS = _collateralTokenConfig.collateralFactorBPS;

      // Get current collateral token balance of trader's account
      uint256 _amount = VaultStorage(vaultStorage).traderBalances(_subAccount, _token);

      // Get price from oracle
      uint256 _priceE30;

      // Get token asset id from ConfigStorage
      bytes32 _tokenAssetId = ConfigStorage(configStorage).tokenAssetIds(_token);
      if (_tokenAssetId == _limitAssetId && _limitPriceE30 != 0) {
        _priceE30 = _limitPriceE30;
      } else {
        // @todo - validate price age
        (_priceE30, , ) = OracleMiddleware(oracle).getLatestPriceWithMarketStatus(
          _tokenAssetId,
          false // @note Collateral value always use Min price
        );
      }
      // Calculate accumulative value of collateral tokens
      // collateral value = (collateral amount * price) * collateralFactorBPS
      // collateralFactor 1e4 = 100%
      _collateralValueE30 += (_amount * _priceE30 * collateralFactorBPS) / ((10 ** _decimals) * BPS);

      unchecked {
        i++;
      }
    }

    return _collateralValueE30;
  }

  /// @notice Calculate Initial Margin Requirement from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @return _imrValueE30 Total imr of trader's account.
  function getIMR(address _subAccount) public view returns (uint256 _imrValueE30) {
    // Get all trader's opening positions
    PerpStorage.Position[] memory _traderPositions = PerpStorage(perpStorage).getPositionBySubAccount(_subAccount);

    // Loop through all trader's positions
    for (uint256 i; i < _traderPositions.length; ) {
      PerpStorage.Position memory _position = _traderPositions[i];

      uint256 _size;
      if (_position.positionSizeE30 < 0) {
        _size = uint(_position.positionSizeE30 * -1);
      } else {
        _size = uint(_position.positionSizeE30);
      }

      // Calculate IMR on position
      _imrValueE30 += calculatePositionIMR(_size, _position.marketIndex);

      unchecked {
        i++;
      }
    }

    return _imrValueE30;
  }

  /// @notice Calculate Maintenance Margin Value from trader's sub account.
  /// @param _subAccount Trader's address that combined between Primary account and Sub account.
  /// @return _mmrValueE30 Total mmr of trader's account
  function getMMR(address _subAccount) public view returns (uint256 _mmrValueE30) {
    // Get all trader's opening positions
    PerpStorage.Position[] memory _traderPositions = PerpStorage(perpStorage).getPositionBySubAccount(_subAccount);

    // Loop through all trader's positions
    for (uint256 i; i < _traderPositions.length; ) {
      PerpStorage.Position memory _position = _traderPositions[i];

      uint256 _size;
      if (_position.positionSizeE30 < 0) {
        _size = uint(_position.positionSizeE30 * -1);
      } else {
        _size = uint(_position.positionSizeE30);
      }

      // Calculate MMR on position
      _mmrValueE30 += calculatePositionMMR(_size, _position.marketIndex);

      unchecked {
        i++;
      }
    }

    return _mmrValueE30;
  }

  /// @notice Calculate for Initial Margin Requirement from position size.
  /// @param _positionSizeE30 Size of position.
  /// @param _marketIndex Market Index from opening position.
  /// @return _imrE30 The IMR amount required on position size, 30 decimals.
  function calculatePositionIMR(uint256 _positionSizeE30, uint256 _marketIndex) public view returns (uint256 _imrE30) {
    // Get market config according to position
    ConfigStorage.MarketConfig memory _marketConfig = ConfigStorage(configStorage).getMarketConfigByIndex(_marketIndex);

    _imrE30 = (_positionSizeE30 * _marketConfig.initialMarginFractionBPS) / BPS;
    return _imrE30;
  }

  /// @notice Calculate for Maintenance Margin Requirement from position size.
  /// @param _positionSizeE30 Size of position.
  /// @param _marketIndex Market Index from opening position.
  /// @return _mmrE30 The MMR amount required on position size, 30 decimals.
  function calculatePositionMMR(uint256 _positionSizeE30, uint256 _marketIndex) public view returns (uint256 _mmrE30) {
    // Get market config according to position
    ConfigStorage.MarketConfig memory _marketConfig = ConfigStorage(configStorage).getMarketConfigByIndex(_marketIndex);

    _mmrE30 = (_positionSizeE30 * _marketConfig.maintenanceMarginFractionBPS) / BPS;
    return _mmrE30;
  }

  /// @notice This function returns the amount of free collateral available to a given sub-account
  /// @param _subAccount The address of the sub-account
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  /// @return _freeCollateral The amount of free collateral available to the sub-account
  function getFreeCollateral(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) public view returns (uint256 _freeCollateral) {
    int256 equity = getEquity(_subAccount, _limitPriceE30, _limitAssetId);
    uint256 imr = getIMR(_subAccount);
    if (equity < int256(imr)) return 0;
    _freeCollateral = uint256(equity) - imr;
    return _freeCollateral;
  }

  /// @notice get next short average price with realized PNL
  /// @param _market - global market
  /// @param _currentPrice - min / max price depends on position direction
  /// @param _positionSizeDelta - position size after increase / decrease.
  ///                           if positive is LONG position, else is SHORT
  /// @param _realizedPositionPnl - position realized PnL if positive is profit, and negative is loss
  /// @return _nextAveragePrice next average price
  function calculateShortAveragePrice(
    PerpStorage.GlobalMarket memory _market,
    uint256 _currentPrice,
    int256 _positionSizeDelta,
    int256 _realizedPositionPnl
  ) external pure returns (uint256 _nextAveragePrice) {
    // global
    uint256 _globalPositionSize = _market.shortPositionSize;
    int256 _globalAveragePrice = int256(_market.shortAvgPrice);

    if (_globalAveragePrice == 0) return 0;

    // if positive means, has profit
    int256 _globalPnl = (int256(_globalPositionSize) * (_globalAveragePrice - int256(_currentPrice))) /
      _globalAveragePrice;
    int256 _newGlobalPnl = _globalPnl - _realizedPositionPnl;

    uint256 _newGlobalPositionSize;
    // position > 0 is means decrease short position
    // else is increase short position
    if (_positionSizeDelta > 0) {
      _newGlobalPositionSize = _globalPositionSize - uint256(_positionSizeDelta);
    } else {
      _newGlobalPositionSize = _globalPositionSize + uint256(-_positionSizeDelta);
    }

    // possible happen when trader close last short position of the market
    if (_newGlobalPositionSize == 0) return 0;

    bool _isGlobalProfit = _newGlobalPnl > 0;
    uint256 _absoluteGlobalPnl = uint256(_isGlobalProfit ? _newGlobalPnl : -_newGlobalPnl);

    // divisor = latest global position size - pnl
    uint256 divisor = _isGlobalProfit
      ? (_newGlobalPositionSize - _absoluteGlobalPnl)
      : (_newGlobalPositionSize + _absoluteGlobalPnl);

    if (divisor == 0) return 0;

    // next short average price = current price * latest global position size / latest global position size - pnl
    _nextAveragePrice = (_currentPrice * _newGlobalPositionSize) / divisor;

    return _nextAveragePrice;
  }

  /// @notice get next long average price with realized PNL
  /// @param _market - global market
  /// @param _currentPrice - min / max price depends on position direction
  /// @param _positionSizeDelta - position size after increase / decrease.
  ///                           if positive is LONG position, else is SHORT
  /// @param _realizedPositionPnl - position realized PnL if positive is profit, and negative is loss
  /// @return _nextAveragePrice next average price
  function calculateLongAveragePrice(
    PerpStorage.GlobalMarket memory _market,
    uint256 _currentPrice,
    int256 _positionSizeDelta,
    int256 _realizedPositionPnl
  ) external pure returns (uint256 _nextAveragePrice) {
    // global
    uint256 _globalPositionSize = _market.longPositionSize;
    int256 _globalAveragePrice = int256(_market.longAvgPrice);

    if (_globalAveragePrice == 0) return 0;

    // if positive means, has profit
    int256 _globalPnl = (int256(_globalPositionSize) * (int256(_currentPrice) - _globalAveragePrice)) /
      _globalAveragePrice;
    int256 _newGlobalPnl = _globalPnl - _realizedPositionPnl;

    uint256 _newGlobalPositionSize;
    // position > 0 is means increase short position
    // else is decrease short position
    if (_positionSizeDelta > 0) {
      _newGlobalPositionSize = _globalPositionSize + uint256(_positionSizeDelta);
    } else {
      _newGlobalPositionSize = _globalPositionSize - uint256(-_positionSizeDelta);
    }

    // possible happen when trader close last long position of the market
    if (_newGlobalPositionSize == 0) return 0;

    bool _isGlobalProfit = _newGlobalPnl > 0;
    uint256 _absoluteGlobalPnl = uint256(_isGlobalProfit ? _newGlobalPnl : -_newGlobalPnl);

    // divisor = latest global position size + pnl
    uint256 divisor = _isGlobalProfit
      ? (_newGlobalPositionSize + _absoluteGlobalPnl)
      : (_newGlobalPositionSize - _absoluteGlobalPnl);

    if (divisor == 0) return 0;

    // next long average price = current price * latest global position size / latest global position size + pnl
    _nextAveragePrice = (_currentPrice * _newGlobalPositionSize) / divisor;

    return _nextAveragePrice;
  }

  function getNextFundingRate(uint256 _marketIndex) external view returns (int256 fundingRate) {
    return _getNextFundingRate(_marketIndex);
  }

  /// @notice Calculate next funding rate using when increase/decrease position.
  /// @param _marketIndex Market Index.
  /// @return fundingRate next funding rate using for both LONG & SHORT positions.
  function _getNextFundingRate(uint256 _marketIndex) internal view returns (int256 fundingRate) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    GetFundingRateVar memory vars;
    ConfigStorage.MarketConfig memory marketConfig = _configStorage.getMarketConfigByIndex(_marketIndex);
    PerpStorage.GlobalMarket memory globalMarket = PerpStorage(perpStorage).getGlobalMarketByIndex(_marketIndex);
    if (marketConfig.fundingRate.maxFundingRate == 0 || marketConfig.fundingRate.maxSkewScaleUSD == 0) return 0;
    // Get funding interval
    vars.fundingInterval = _configStorage.getTradingConfig().fundingInterval;
    // If block.timestamp not pass the next funding time, return 0.
    if (globalMarket.lastFundingTime + vars.fundingInterval > block.timestamp) return 0;

    vars.marketSkewUSDE30 = int(globalMarket.longPositionSize) - int(globalMarket.shortPositionSize);

    // The result of this nextFundingRate Formula will be in the range of [-maxFundingRate, maxFundingRate]
    vars.ratio = _max(-1e18, -((vars.marketSkewUSDE30 * 1e18) / int(marketConfig.fundingRate.maxSkewScaleUSD)));
    vars.ratio = _min(vars.ratio, 1e18);
    vars.nextFundingRate = (vars.ratio * int(uint(marketConfig.fundingRate.maxFundingRate))) / 1e18;

    vars.elapsedIntervals = int((block.timestamp - globalMarket.lastFundingTime) / vars.fundingInterval);
    vars.nextFundingRate = vars.nextFundingRate * vars.elapsedIntervals;

    return vars.nextFundingRate;
  }

  /**
   * Funding Rate
   */
  /// @notice This function returns funding fee according to trader's position
  /// @param _marketIndex Index of market
  /// @param _isLong Is long or short exposure
  /// @param _size Position size
  /// @return fundingFee Funding fee of position
  function getFundingFee(
    uint256 _marketIndex,
    bool _isLong,
    int256 _size,
    int256 _entryFundingRate
  ) external view returns (int256 fundingFee) {
    if (_size == 0) return 0;
    uint256 absSize = _size > 0 ? uint(_size) : uint(-_size);

    PerpStorage.GlobalMarket memory _globalMarket = PerpStorage(perpStorage).getGlobalMarketByIndex(_marketIndex);

    return _getFundingFee(_isLong, absSize, _globalMarket.currentFundingRate, _entryFundingRate);
  }

  function _getFundingFee(
    bool _isLong,
    uint256 _size,
    int256 _sumFundingRate,
    int256 _entryFundingRate
  ) private pure returns (int256 fundingFee) {
    int256 _fundingRate = _sumFundingRate - _entryFundingRate;

    // IF _fundingRate < 0, LONG positions pay fees to SHORT and SHORT positions receive fees from LONG
    // IF _fundingRate > 0, LONG positions receive fees from SHORT and SHORT pay fees to LONG
    fundingFee = (int256(_size) * _fundingRate) / int64(RATE_PRECISION);

    // Position Exposure   | Funding Rate       | Fund Flow
    // (isLong)            | (fundingRate > 0)  | (traderMustPay)
    // ---------------------------------------------------------------------
    // true                | true               | false  (fee reserve -> trader)
    // true                | false              | true   (trader -> fee reserve)
    // false               | true               | true   (trader -> fee reserve)
    // false               | false              | false  (fee reserve -> trader)

    // If fundingFee is negative mean Trader receives Fee
    // If fundingFee is positive mean Trader pays Fee
    if (_isLong) {
      return -fundingFee;
    }
    return fundingFee;
  }

  /// @notice Calculates the borrowing fee for a given asset class based on the reserved value, entry borrowing rate, and current sum borrowing rate of the asset class.
  /// @param _assetClassIndex The index of the asset class for which to calculate the borrowing fee.
  /// @param _reservedValue The reserved value of the asset class.
  /// @param _entryBorrowingRate The entry borrowing rate of the asset class.
  /// @return borrowingFee The calculated borrowing fee for the asset class.
  function getBorrowingFee(
    uint8 _assetClassIndex,
    uint256 _reservedValue,
    uint256 _entryBorrowingRate
  ) external view returns (uint256 borrowingFee) {
    // Get the global asset class.
    PerpStorage.GlobalAssetClass memory _assetClassState = PerpStorage(perpStorage).getGlobalAssetClassByIndex(
      _assetClassIndex
    );
    // // Calculate borrowing fee.
    return _getBorrowingFee(_reservedValue, _assetClassState.sumBorrowingRate, _entryBorrowingRate);
  }

  function _getBorrowingFee(
    uint256 _reservedValue,
    uint256 _sumBorrowingRate,
    uint256 _entryBorrowingRate
  ) internal view returns (uint256 borrowingFee) {
    // Calculate borrowing rate.
    uint256 _borrowingRate = _sumBorrowingRate - _entryBorrowingRate;
    // Calculate the borrowing fee based on reserved value, borrowing rate.
    return (_reservedValue * _borrowingRate) / RATE_PRECISION;
  }

  function getNextBorrowingRate(
    uint8 _assetClassIndex,
    uint256 _plpTVL
  ) external view returns (uint256 _nextBorrowingRate) {
    return _getNextBorrowingRate(_assetClassIndex, _plpTVL);
  }

  /// @notice This function takes an asset class index as input and returns the next borrowing rate for that asset class.
  /// @param _assetClassIndex The index of the asset class.
  /// @param _plpTVL value in plp
  /// @return _nextBorrowingRate The next borrowing rate for the asset class.
  function _getNextBorrowingRate(
    uint8 _assetClassIndex,
    uint256 _plpTVL
  ) internal view returns (uint256 _nextBorrowingRate) {
    ConfigStorage _configStorage = ConfigStorage(configStorage);

    // Get the trading config, asset class config, and global asset class for the given asset class index.
    ConfigStorage.TradingConfig memory _tradingConfig = _configStorage.getTradingConfig();
    ConfigStorage.AssetClassConfig memory _assetClassConfig = _configStorage.getAssetClassConfigByIndex(
      _assetClassIndex
    );
    PerpStorage.GlobalAssetClass memory _assetClassState = PerpStorage(perpStorage).getGlobalAssetClassByIndex(
      _assetClassIndex
    );
    // If block.timestamp not pass the next funding time, return 0.
    if (_assetClassState.lastBorrowingTime + _tradingConfig.fundingInterval > block.timestamp) return 0;

    // If PLP TVL is 0, return 0.
    if (_plpTVL == 0) return 0;

    // Calculate the number of funding intervals that have passed since the last borrowing time.
    uint256 intervals = (block.timestamp - _assetClassState.lastBorrowingTime) / _tradingConfig.fundingInterval;

    // Calculate the next borrowing rate based on the asset class config, global asset class reserve value, and intervals.
    return (_assetClassConfig.baseBorrowingRate * _assetClassState.reserveValueE30 * intervals) / _plpTVL;
  }

  function getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) external view returns (bool, uint256) {
    return _getDelta(_size, _isLong, _markPrice, _averagePrice, _lastIncreaseTimestamp);
  }

  // @todo - pass current price here
  /// @notice Calculates the delta between average price and mark price, based on the size of position and whether the position is profitable.
  /// @param _size The size of the position.
  /// @param _isLong position direction
  /// @param _markPrice current market price
  /// @param _averagePrice The average price of the position.
  /// @return isProfit A boolean value indicating whether the position is profitable or not.
  /// @return delta The Profit between the average price and the fixed price, adjusted for the size of the order.
  function _getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) internal view returns (bool, uint256) {
    // Check for invalid input: averagePrice cannot be zero.
    if (_averagePrice == 0) return (false, 0);

    // Calculate the difference between the average price and the fixed price.
    uint256 priceDelta;
    unchecked {
      priceDelta = _averagePrice > _markPrice ? _averagePrice - _markPrice : _markPrice - _averagePrice;
    }

    // Calculate the delta, adjusted for the size of the order.
    uint256 delta = (_size * priceDelta) / _averagePrice;

    // Determine if the position is profitable or not based on the averagePrice and the mark price.
    bool isProfit;
    if (_isLong) {
      isProfit = _markPrice > _averagePrice;
    } else {
      isProfit = _markPrice < _averagePrice;
    }

    // In case of profit, we need to check the current timestamp against minProfitDuration
    // in order to prevent front-run attack, or price manipulation.
    // Check `isProfit` first, to save SLOAD in loss case.
    if (isProfit) {
      IConfigStorage.TradingConfig memory _tradingConfig = ConfigStorage(configStorage).getTradingConfig();
      if (block.timestamp < _lastIncreaseTimestamp + _tradingConfig.minProfitDuration) {
        return (isProfit, 0);
      }
    }

    // Return the values of isProfit and delta.
    return (isProfit, delta);
  }

  function _max(int256 a, int256 b) internal pure returns (int256) {
    return a > b ? a : b;
  }

  function _min(int256 a, int256 b) internal pure returns (int256) {
    return a < b ? a : b;
  }

  function _abs(int256 x) private pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";

interface ICalculator {
  /**
   * ERRORS
   */
  error ICalculator_InvalidAddress();
  error ICalculator_InvalidAveragePrice();
  error ICalculator_PoolImbalance();

  /**
   * STRUCTS
   */
  struct GetFundingRateVar {
    uint256 fundingInterval;
    int256 marketSkewUSDE30;
    int256 ratio;
    int256 nextFundingRate;
    int256 elapsedIntervals;
  }

  //@todo - will be use in _getFeeRate
  enum LiquidityDirection {
    ADD,
    REMOVE
  }

  enum PositionExposure {
    LONG,
    SHORT
  }

  function getAUME30(bool isMaxPrice) external returns (uint256);

  function getPLPValueE30(bool isMaxPrice) external view returns (uint256);

  function getFreeCollateral(
    address _subAccount,
    uint256 _price,
    bytes32 _assetId
  ) external view returns (uint256 _freeCollateral);

  function getPLPPrice(uint256 aum, uint256 supply) external returns (uint256);

  function getMintAmount(uint256 _aum, uint256 _totalSupply, uint256 _amount) external view returns (uint256);

  function convertTokenDecimals(
    uint256 _fromTokenDecimals,
    uint256 _toTokenDecimals,
    uint256 _amount
  ) external pure returns (uint256);

  function getAddLiquidityFeeBPS(
    address _token,
    uint256 _tokenValue,
    ConfigStorage _configStorage
  ) external returns (uint32);

  function getRemoveLiquidityFeeBPS(
    address _token,
    uint256 _tokenValueE30,
    ConfigStorage _configStorage
  ) external returns (uint32);

  function calculatePositionIMR(uint256 _positionSizeE30, uint256 _marketIndex) external view returns (uint256 _imrE30);

  function calculatePositionMMR(uint256 _positionSizeE30, uint256 _marketIndex) external view returns (uint256 _mmrE30);

  function getEquity(
    address _subAccount,
    uint256 _price,
    bytes32 _assetId
  ) external view returns (int256 _equityValueE30);

  function getUnrealizedPnlAndFee(
    address _subAccount,
    uint256 _limitPriceE30,
    bytes32 _limitAssetId
  ) external view returns (int256 _unrealizedPnlE30, int256 _unrealizedFeeE30);

  function getIMR(address _subAccount) external view returns (uint256 _imrValueE30);

  function getMMR(address _subAccount) external view returns (uint256 _mmrValueE30);

  function getSettlementFeeRate(address _token, uint256 _liquidityUsdDelta) external returns (uint256);

  function getCollateralValue(
    address _subAccount,
    uint256 _limitPrice,
    bytes32 _assetId
  ) external view returns (uint256 _collateralValueE30);

  function getNextFundingRate(uint256 _marketIndex) external view returns (int256);

  function getDelta(
    uint256 _size,
    bool _isLong,
    uint256 _markPrice,
    uint256 _averagePrice,
    uint256 _lastincreaseTimestamp
  ) external view returns (bool, uint256);

  function setOracle(address _oracle) external;

  function setVaultStorage(address _address) external;

  function setConfigStorage(address _address) external;

  function setPerpStorage(address _address) external;

  function oracle() external returns (address _address);

  function vaultStorage() external returns (address _address);

  function configStorage() external returns (address _address);

  function perpStorage() external returns (address _address);

  function getPendingBorrowingFeeE30() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// base
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Owned } from "@hmx/base/Owned.sol";
import { IPyth } from "pyth-sdk-solidity/IPyth.sol";

// contracts
import { TradeService } from "@hmx/services/TradeService.sol";
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { PerpStorage } from "@hmx/storages/PerpStorage.sol";

// interfaces
import { IMarketTradeHandler } from "@hmx/handlers/interfaces/IMarketTradeHandler.sol";

contract MarketTradeHandler is Owned, ReentrancyGuard, IMarketTradeHandler {
  /**
   * EVENT
   */
  event LogSetTradeService(address oldMarketTradeService, address newMarketTradeService);
  event LogSetPyth(address oldPyth, address newPyth);
  event LogBuy(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _buySizeE30,
    uint256 _shortDecreasingSizeE30,
    uint256 _longIncreasingSizeE30
  );
  event LogSell(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _sellSizeE30,
    uint256 _longDecreasingSizeE30,
    uint256 _shortIncreasingSizeE30
  );

  /**
   * STATES
   */
  address public tradeService;
  address public pyth;

  constructor(address _tradeService, address _pyth) {
    if (_tradeService == address(0) || _pyth == address(0)) revert IMarketTradeHandler_InvalidAddress();

    tradeService = _tradeService;
    pyth = _pyth;

    // Sanity check
    TradeService(_tradeService).perpStorage();
    IPyth(_pyth).getUpdateFee(new bytes[](0));
  }

  /**
   * MODIFIER
   */

  /**
   * SETTER
   */

  /// @notice Set new trader service contract address.
  /// @param _newTradeService New trader service contract address.
  function setTradeService(address _newTradeService) external nonReentrant onlyOwner {
    if (_newTradeService == address(0)) revert IMarketTradeHandler_InvalidAddress();
    emit LogSetTradeService(address(tradeService), _newTradeService);
    tradeService = _newTradeService;

    // Sanity check
    TradeService(_newTradeService).perpStorage();
  }

  /// @notice Set new Pyth contract address.
  /// @param _newPyth New Pyth contract address.
  function setPyth(address _newPyth) external nonReentrant onlyOwner {
    if (_newPyth == address(0)) revert IMarketTradeHandler_InvalidAddress();
    emit LogSetPyth(pyth, _newPyth);
    pyth = _newPyth;

    // Sanity check
    IPyth(_newPyth).getUpdateFee(new bytes[](0));
  }

  /**
   * CALCULATION
   */

  /// @notice Perform buy, in which increasing position size towards long exposure.
  /// @dev Flipping from short exposure to long exposure is possible here.
  /// @param _account Trader's primary wallet account.
  /// @param _subAccountId Trader's sub account id.
  /// @param _marketIndex Market index.
  /// @param _buySizeE30 Buying size in e30 format.
  /// @param _tpToken Take profit token
  /// @param _priceData Pyth price feed data, can be derived from Pyth client SDK.
  function buy(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _buySizeE30,
    address _tpToken, // NOTE: current only support GLP as profit token
    bytes[] memory _priceData
  ) external payable nonReentrant {
    if (_buySizeE30 == 0) {
      revert IMarketTradeHandler_ZeroSizeInput();
    }

    // Feed Price
    // slither-disable-next-line arbitrary-send-eth
    IPyth(pyth).updatePriceFeeds{ value: IPyth(pyth).getUpdateFee(_priceData) }(_priceData);

    // 0. Get position
    PerpStorage.Position memory _position = _getPosition(_account, _subAccountId, _marketIndex);

    // 1. Find the `_shortDecreasingSizeE30` and `_longIncreasingSizeE30`
    uint256 _shortDecreasingSizeE30 = 0;
    uint256 _longIncreasingSizeE30 = 0;
    {
      if (_position.positionSizeE30 < 0) {
        // If short position exists, we need to close it first

        uint256 _longPositionSizeE30 = uint256(-_position.positionSizeE30);

        if (_buySizeE30 > _longPositionSizeE30) {
          // If buy size can cover the short position size,
          // long position size should be the remaining buy size
          unchecked {
            _shortDecreasingSizeE30 = _longPositionSizeE30;
            _longIncreasingSizeE30 = _buySizeE30 - _longPositionSizeE30;
          }
        } else {
          // If buy size cannot cover the short position size,
          // just simply decrease the position
          _shortDecreasingSizeE30 = _buySizeE30;
          // can be commented to save gas
          // _longIncreasingSizeE30 = 0;
        }
      } else {
        // If short position does not exists,
        // just simply increase the long position

        // can be commented to save gas
        // _shortDecreasingSizeE30 = 0;
        _longIncreasingSizeE30 = _buySizeE30;
      }
    }

    // 2. Decrease the short position first
    if (_shortDecreasingSizeE30 > 0) {
      TradeService(tradeService).decreasePosition(
        _account,
        _subAccountId,
        _marketIndex,
        _shortDecreasingSizeE30,
        _tpToken,
        0
      );
    }

    // 3. Then, increase the long position
    if (_longIncreasingSizeE30 > 0) {
      TradeService(tradeService).increasePosition(
        _account,
        _subAccountId,
        _marketIndex,
        int256(_longIncreasingSizeE30),
        0
      );
    }

    emit LogBuy(_account, _subAccountId, _marketIndex, _buySizeE30, _shortDecreasingSizeE30, _longIncreasingSizeE30);
  }

  /// @notice Perform sell, in which increasing position size towards short exposure.
  /// @dev Flipping from long exposure to short exposure is possible here.
  /// @param _account Trader's primary wallet account.
  /// @param _subAccountId Trader's sub account id.
  /// @param _marketIndex Market index.
  /// @param _sellSizeE30 Buying size in e30 format.
  /// @param _tpToken Take profit token
  /// @param _priceData Pyth price feed data, can be derived from Pyth client SDK.
  function sell(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _sellSizeE30,
    address _tpToken, // NOTE: current only support GLP as profit token
    bytes[] memory _priceData
  ) external payable nonReentrant {
    if (_sellSizeE30 == 0) {
      revert IMarketTradeHandler_ZeroSizeInput();
    }

    // Feed Price
    // slither-disable-next-line arbitrary-send-eth
    IPyth(pyth).updatePriceFeeds{ value: IPyth(pyth).getUpdateFee(_priceData) }(_priceData);

    // 0. Get position
    PerpStorage.Position memory _position = _getPosition(_account, _subAccountId, _marketIndex);

    // 1. Find the `_longDecreasingSizeE30` and `_shortIncreasingSizeE30`
    uint256 _longDecreasingSizeE30 = 0;
    uint256 _shortIncreasingSizeE30 = 0;
    {
      if (_position.positionSizeE30 > 0) {
        // If long position exists, we need to close it first

        uint256 _longPositionSizeE30 = uint256(_position.positionSizeE30);

        if (_sellSizeE30 > _longPositionSizeE30) {
          // If sell size can cover the long position size,
          // short position size should be the remaining sell size
          unchecked {
            _longDecreasingSizeE30 = _longPositionSizeE30;
            _shortIncreasingSizeE30 = _sellSizeE30 - _longPositionSizeE30;
          }
        } else {
          // If sell size cannot cover the short position size,
          // just simply decrease the position
          _longDecreasingSizeE30 = _sellSizeE30;
          // can be commented to save gas
          // _shortIncreasingSizeE30 = 0;
        }
      } else {
        // If long position does not exists,
        // just simply increase the short position

        // can be commented to save gas
        // _longDecreasingSizeE30 = 0;
        _shortIncreasingSizeE30 = _sellSizeE30;
      }
    }

    // 2. Decrease the long position first
    if (_longDecreasingSizeE30 > 0) {
      TradeService(tradeService).decreasePosition(
        _account,
        _subAccountId,
        _marketIndex,
        _longDecreasingSizeE30,
        _tpToken,
        0
      );
    }

    // 3. Then, increase the short position
    if (_shortIncreasingSizeE30 > 0) {
      TradeService(tradeService).increasePosition(
        _account,
        _subAccountId,
        _marketIndex,
        -int256(_shortIncreasingSizeE30),
        0
      );
    }

    emit LogSell(_account, _subAccountId, _marketIndex, _sellSizeE30, _longDecreasingSizeE30, _shortIncreasingSizeE30);
  }

  /// @notice Calculate subAccount address on trader.
  /// @dev This uses to create subAccount address combined between Primary account and SubAccount ID.
  /// @param _primary Trader's primary wallet account.
  /// @param _subAccountId Trader's sub account ID.
  /// @return _subAccount Trader's sub account address used for trading.
  function _getSubAccount(address _primary, uint8 _subAccountId) internal pure returns (address _subAccount) {
    if (_subAccountId > 255) revert();
    return address(uint160(_primary) ^ uint160(_subAccountId));
  }

  /// @notice Derive positionId from sub-account and market index
  /// @param _subAccount Trader's sub account (account + subAccountId).
  /// @param _marketIndex Market index.
  /// @return _positionId
  function _getPositionId(address _subAccount, uint256 _marketIndex) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_subAccount, _marketIndex));
  }

  /// @notice Get position struct from account, subAccountId and market index
  /// @param _account Trader's primary wallet account.
  /// @param _subAccountId Trader's sub account id.
  /// @param _marketIndex Market index.
  /// @return _position Position struct
  function _getPosition(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex
  ) internal view returns (PerpStorage.Position memory) {
    address _perpStorage = TradeService(tradeService).perpStorage();
    address _subAccount = _getSubAccount(_account, _subAccountId);
    bytes32 _positionId = _getPositionId(_subAccount, _marketIndex);

    return PerpStorage(_perpStorage).getPositionById(_positionId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IMarketTradeHandler {
  /**
   * Errors
   */
  error IMarketTradeHandler_InvalidAddress();
  error IMarketTradeHandler_PositionNotFullyClosed();
  error IMarketTradeHandler_ZeroSizeInput();

  function setTradeService(address _newTradeService) external;

  function setPyth(address _newPyth) external;

  function buy(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _buySizeE30,
    address _tpToken,
    bytes[] memory _priceData
  ) external payable;

  function sell(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _sellSizeE30,
    address _tpToken,
    bytes[] memory _priceData
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PerpStorage } from "@hmx/storages/PerpStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";

import { Calculator } from "@hmx/contracts/Calculator.sol";
import { Owned } from "@hmx/base/Owned.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { OracleMiddleware } from "@hmx/oracle/OracleMiddleware.sol";
import { ITradeHelper } from "@hmx/helpers/interfaces/ITradeHelper.sol";

contract TradeHelper is ITradeHelper, ReentrancyGuard, Owned {
  uint32 internal constant BPS = 1e4;
  uint64 internal constant RATE_PRECISION = 1e18;

  /**
   * Events
   */
  event LogSettleTradingFeeValue(address subAccount, uint256 feeUsd);
  event LogSettleTradingFeeAmount(address subAccount, address token, uint256 devFeeAmount, uint256 protocolFeeAmount);
  event LogSettleBorrowingFeeValue(address subAccount, uint256 feeUsd);
  event LogSettleBorrowingFeeAmount(address subAccount, address token, uint256 devFeeAmount, uint256 plpFeeAmount);
  event LogSettleFundingFeeValue(address subAccount, int256 feeUsd);
  event LogSettleFundingFeeAmountWhenTraderPays(address subAccount, address token, uint256 amount);
  event LogSettleFundingFeeAmountWhenTraderReceives(address subAccount, address token, uint256 amount);
  event LogSetConfigStorage(address indexed oldConfigStorage, address newConfigStorage);
  event LogSetVaultStorage(address indexed oldVaultStorage, address newVaultStorage);
  event LogSetPerpStorage(address indexed oldPerpStorage, address newPerpStorage);

  address public perpStorage;
  address public vaultStorage;
  address public configStorage;
  Calculator public calculator; // cache this from configStorage

  constructor(address _perpStorage, address _vaultStorage, address _configStorage) {
    // Sanity check
    ConfigStorage(_configStorage).calculator();
    VaultStorage(_vaultStorage).devFees(address(0));
    PerpStorage(_perpStorage).getGlobalState();

    perpStorage = _perpStorage;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;
    calculator = Calculator(ConfigStorage(_configStorage).calculator());
  }

  function reloadConfig() external {
    // TODO: access control, sanity check, natspec
    // TODO: discuss about this pattern

    calculator = Calculator(ConfigStorage(configStorage).calculator());
  }

  /// @notice This function updates the borrowing rate for the given asset class index.
  /// @param _assetClassIndex The index of the asset class.
  function updateBorrowingRate(uint8 _assetClassIndex) external {
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // Get the funding interval, asset class config, and global asset class for the given asset class index.
    PerpStorage.GlobalAssetClass memory _globalAssetClass = _perpStorage.getGlobalAssetClassByIndex(_assetClassIndex);
    uint256 _fundingInterval = ConfigStorage(configStorage).getTradingConfig().fundingInterval;
    uint256 _lastBorrowingTime = _globalAssetClass.lastBorrowingTime;

    // If last borrowing time is 0, set it to the nearest funding interval time and return.
    if (_lastBorrowingTime == 0) {
      _globalAssetClass.lastBorrowingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateGlobalAssetClass(_assetClassIndex, _globalAssetClass);
      return;
    }

    // If block.timestamp is not passed the next funding interval, skip updating
    if (_lastBorrowingTime + _fundingInterval <= block.timestamp) {
      uint256 _plpTVL = calculator.getPLPValueE30(false);

      // update borrowing rate
      uint256 borrowingRate = calculator.getNextBorrowingRate(_assetClassIndex, _plpTVL);
      _globalAssetClass.sumBorrowingRate += borrowingRate;
      _globalAssetClass.lastBorrowingTime = (block.timestamp / _fundingInterval) * _fundingInterval;

      uint256 borrowingFee = (_globalAssetClass.reserveValueE30 * borrowingRate) / RATE_PRECISION;

      _globalAssetClass.sumBorrowingFeeE30 += borrowingFee;
    }
    _perpStorage.updateGlobalAssetClass(_assetClassIndex, _globalAssetClass);
  }

  /// @notice This function updates the funding rate for the given market index.
  /// @param _marketIndex The index of the market.
  function updateFundingRate(uint256 _marketIndex) external {
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // Get the funding interval, asset class config, and global asset class for the given asset class index.
    PerpStorage.GlobalMarket memory _globalMarket = _perpStorage.getGlobalMarketByIndex(_marketIndex);

    uint256 _fundingInterval = ConfigStorage(configStorage).getTradingConfig().fundingInterval;
    uint256 _lastFundingTime = _globalMarket.lastFundingTime;

    // If last funding time is 0, set it to the nearest funding interval time and return.
    if (_lastFundingTime == 0) {
      _globalMarket.lastFundingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateGlobalMarket(_marketIndex, _globalMarket);
      return;
    }

    // If block.timestamp is not passed the next funding interval, skip updating
    if (_lastFundingTime + _fundingInterval <= block.timestamp) {
      // update funding rate
      int256 nextFundingRate = calculator.getNextFundingRate(_marketIndex);
      int256 lastFundingRate = _globalMarket.currentFundingRate;
      _globalMarket.currentFundingRate += nextFundingRate;
      _perpStorage.updateGlobalMarket(_marketIndex, _globalMarket);

      if (_globalMarket.longPositionSize > 0) {
        int256 fundingFeeLongE30 = calculator.getFundingFee(
          _marketIndex,
          true,
          int(_globalMarket.longPositionSize),
          lastFundingRate
        );
        _globalMarket.accumFundingLong += fundingFeeLongE30;
      }

      if (_globalMarket.shortPositionSize > 0) {
        int256 fundingFeeShortE30 = calculator.getFundingFee(
          _marketIndex,
          false,
          int(_globalMarket.shortPositionSize),
          lastFundingRate
        );
        _globalMarket.accumFundingShort += fundingFeeShortE30;
      }

      _globalMarket.lastFundingTime = (block.timestamp / _fundingInterval) * _fundingInterval;
      _perpStorage.updateGlobalMarket(_marketIndex, _globalMarket);
    }
  }

  struct SettleAllFeesVars {
    // Share vars
    VaultStorage vaultStorage;
    ConfigStorage configStorage;
    PerpStorage perpStorage;
    OracleMiddleware oracle;
    ConfigStorage.TradingConfig tradingConfig;
    uint256 plpLiquidityDebtUSDE30;
    uint256 marketIndex;
    address[] collateralTokens;
    uint256 collateralTokensLength;
    address subAccount;
    uint256 tokenPrice;
    // Trading fee vars
    uint256 tradingFeeToBePaid;
    // Borrowing fee vars
    uint256 borrowingFeeToBePaid;
    // Funding fee vars
    int256 fundingFeeToBePaid;
    uint256 absFundingFeeToBePaid;
    bool isLong;
    bool traderMustPay;
  }

  function settleAllFees(
    PerpStorage.Position memory _position,
    uint256 _absSizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex,
    uint256 _marketIndex
  ) external {
    SettleAllFeesVars memory _vars;

    // SLOAD
    _vars.marketIndex = _marketIndex;
    _vars.perpStorage = PerpStorage(perpStorage);
    _vars.vaultStorage = VaultStorage(vaultStorage);
    _vars.configStorage = ConfigStorage(configStorage);
    _vars.oracle = OracleMiddleware(_vars.configStorage.oracle());
    _vars.collateralTokens = _vars.configStorage.getCollateralTokens();
    _vars.collateralTokensLength = _vars.collateralTokens.length;
    _vars.tradingConfig = _vars.configStorage.getTradingConfig();
    _vars.subAccount = _getSubAccount(_position.primaryAccount, _position.subAccountId);

    // Calculate the trading fee
    {
      _vars.tradingFeeToBePaid = (_absSizeDelta * _positionFeeBPS) / BPS;
      emit LogSettleTradingFeeValue(_vars.subAccount, _vars.tradingFeeToBePaid);
    }

    // Calculate the borrowing fee
    {
      _vars.borrowingFeeToBePaid = calculator.getBorrowingFee(
        _assetClassIndex,
        _position.reserveValueE30,
        _position.entryBorrowingRate
      );

      emit LogSettleBorrowingFeeValue(_vars.subAccount, _vars.borrowingFeeToBePaid);
    }

    // Calculate the funding fee
    {
      _vars.isLong = _position.positionSizeE30 > 0;

      _vars.fundingFeeToBePaid = calculator.getFundingFee(
        _marketIndex,
        _vars.isLong,
        _position.positionSizeE30,
        _position.entryFundingRate
      );
      _vars.absFundingFeeToBePaid = _abs(_vars.fundingFeeToBePaid);

      // If fundingFee is negative mean Trader receives Fee
      // If fundingFee is positive mean Trader pays Fee
      _vars.traderMustPay = (_vars.fundingFeeToBePaid > 0);

      emit LogSettleFundingFeeValue(_vars.subAccount, _vars.fundingFeeToBePaid);
    }

    // Update global state
    {
      _accumSettledBorrowingFee(_assetClassIndex, _vars.borrowingFeeToBePaid);
    }

    // In case trader must receive funding fee, process it first and separately from other fees
    if (!_vars.traderMustPay) {
      // We are now trying our best to cover
      // - _vars.absFundingFeeToBePaid (when trader must receive)
      //
      // If one collateral cannot cover, try the next one and so on.
      // If all of the collaterals still cannot cover, revert.
      for (uint256 i; i < _vars.collateralTokensLength; ) {
        bytes32 _tokenAssetId = _vars.configStorage.tokenAssetIds(_vars.collateralTokens[i]);
        (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_tokenAssetId, false);

        _settleFundingFeeWhenTraderMustReceive(_vars, _vars.collateralTokens[i]);

        // stop iteration, if all fees are covered
        if (_vars.absFundingFeeToBePaid == 0) break;

        unchecked {
          ++i;
        }
      }

      if (_vars.absFundingFeeToBePaid > 0) {
        // This could occur when funding fee does not have enough liquidity to pay funding fee to trader
        // If fee cannot be covered, borrow from PLP and book as PLP Debts
        for (uint256 i; i < _vars.collateralTokensLength; ) {
          bytes32 _tokenAssetId = _vars.configStorage.tokenAssetIds(_vars.collateralTokens[i]);
          (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_tokenAssetId, false);

          _settleFundingFeeWhenBorrowingFromPLP(_vars, _vars.collateralTokens[i]);

          // stop iteration, if all fees are covered
          if (_vars.absFundingFeeToBePaid == 0) break;

          unchecked {
            ++i;
          }
        }
      }

      if (_vars.absFundingFeeToBePaid > 0) revert ITradeHelper_FundingFeeCannotBeCovered();
    }

    // We are now trying our best to cover
    // - _vars.tradingFeeToBePaid
    // - _vars.borrowingFeeToBePaid
    // - _vars.absFundingFeeToBePaid (when trader must pay)
    //
    // If one collateral cannot cover, try the next one and so on.
    // If all of the collaterals still cannot cover, revert.
    for (uint256 i; i < _vars.collateralTokensLength; ) {
      bytes32 _tokenAssetId = _vars.configStorage.tokenAssetIds(_vars.collateralTokens[i]);
      (_vars.tokenPrice, ) = _vars.oracle.getLatestPrice(_tokenAssetId, false);

      // Funding fee
      if (_vars.absFundingFeeToBePaid > 0) {
        // If there's borrowing debts from PLP, then trader must repays to PLP first
        _vars.plpLiquidityDebtUSDE30 = _vars.vaultStorage.plpLiquidityDebtUSDE30();
        if (_vars.plpLiquidityDebtUSDE30 > 0) {
          _repayBorrowDebtFromTraderToPlp(_vars, _vars.collateralTokens[i]);
        }

        // If no borrowing debts from PLP
        // or
        // If trader still must pays for funding fee reserve after repay borrowing debts
        if (_vars.absFundingFeeToBePaid > 0) {
          _settleFundingFeeWhenTraderMustPay(_vars, _vars.collateralTokens[i]);
        }

        // still cannot cover all, move to next iteration
        if (_vars.absFundingFeeToBePaid > 0) {
          unchecked {
            ++i;
          }
          continue;
        }
      }

      // Trading fee
      if (_vars.tradingFeeToBePaid > 0) {
        _settleTradingFee(_vars, _vars.collateralTokens[i]);

        // still cannot cover all, move to next iteration
        if (_vars.tradingFeeToBePaid > 0) {
          unchecked {
            ++i;
          }
          continue;
        }
      }

      // Borrowing fee
      if (_vars.borrowingFeeToBePaid > 0) {
        _settleBorrowingFee(_vars, _vars.collateralTokens[i]);

        // still cannot cover all, move to next iteration
        if (_vars.borrowingFeeToBePaid > 0) {
          unchecked {
            ++i;
          }
          continue;
        }
      }

      // _vars.borrowingFeeToBePaid  is the last fee to be covered
      // simply check _vars.borrowingFeeToBePaid  == 0
      // stop iteration, if all fees are covered
      if (_vars.borrowingFeeToBePaid == 0) break;

      unchecked {
        ++i;
      }
    }

    // If fee cannot be covered, revert.
    // This shouldn't be happen unless the platform is suffering from bad debt
    if (_vars.tradingFeeToBePaid > 0) revert ITradeHelper_TradingFeeCannotBeCovered();
    if (_vars.borrowingFeeToBePaid > 0) revert ITradeHelper_BorrowingFeeCannotBeCovered();
    if (_vars.absFundingFeeToBePaid > 0) revert ITradeHelper_FundingFeeCannotBeCovered();
  }

  function _settleFundingFeeWhenTraderMustPay(
    SettleAllFeesVars memory _vars,
    address _collateralToken
  ) internal returns (uint256) {
    // PerpStorage.GlobalMarket memory _globalMarket = _vars.perpStorage.getGlobalMarketByIndex(_vars.marketIndex);

    // When trader is the payer
    uint256 _traderBalance = _vars.vaultStorage.traderBalances(_vars.subAccount, _collateralToken);

    // We are going to deduct trader balance,
    // so we need to check whether trader has this collateral token or not.
    // If not skip to next token
    if (_traderBalance > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _traderBalance,
        _vars.absFundingFeeToBePaid,
        _collateralToken,
        _vars.tokenPrice
      );

      // book the balances
      _vars.vaultStorage.payFundingFeeFromTraderToFundingFeeReserve(_vars.subAccount, _collateralToken, _repayAmount);

      // Update accum funding fee on Global storage for surplus calculation
      _vars.isLong
        ? _updateAccumFundingLong(_vars.marketIndex, -int(_repayValue))
        : _updateAccumFundingShort(_vars.marketIndex, -int(_repayValue));

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.absFundingFeeToBePaid -= _repayValue;
    }
  }

  function _repayBorrowDebtFromTraderToPlp(SettleAllFeesVars memory _vars, address _collateralToken) internal {
    // When trader is the payer
    uint256 _traderBalance = _vars.vaultStorage.traderBalances(_vars.subAccount, _collateralToken);

    // We are going to deduct trader balance,
    // so we need to check whether trader has this collateral token or not.
    // If not skip to next token
    if (_traderBalance > 0) {
      // If absFundingFeeToBePaid is less than borrowing debts from PLP, Then Trader repay with all current collateral amounts to PLP
      // Else Trader repay with just enough current collateral amounts to PLP
      uint256 repayFundingFeeValue = _vars.absFundingFeeToBePaid < _vars.plpLiquidityDebtUSDE30
        ? _vars.absFundingFeeToBePaid
        : _vars.plpLiquidityDebtUSDE30;

      // Trader repay with just enough current collateral amounts to PLP
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _traderBalance,
        repayFundingFeeValue,
        _collateralToken,
        _vars.tokenPrice
      );
      _vars.vaultStorage.repayFundingFeeDebtFromTraderToPlp(
        _vars.subAccount,
        _collateralToken,
        _repayAmount,
        _repayValue
      );

      // Update accum funding fee on Global storage for surplus calculation
      _vars.isLong
        ? _updateAccumFundingLong(_vars.marketIndex, -int(_repayValue))
        : _updateAccumFundingShort(_vars.marketIndex, -int(_repayValue));

      _vars.absFundingFeeToBePaid -= _repayValue;
    }
  }

  function _settleFundingFeeWhenTraderMustReceive(
    SettleAllFeesVars memory _vars,
    address _collateralToken
  ) internal returns (uint256) {
    // When funding fee is the payer
    uint256 _fundingFeeBalance = _vars.vaultStorage.fundingFeeReserve(_collateralToken);

    // We are going to deduct funding fee balance,
    // so we need to check whether funding fee has this collateral token or not.
    // If not skip to next token
    if (_fundingFeeBalance > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _fundingFeeBalance,
        _vars.absFundingFeeToBePaid,
        _collateralToken,
        _vars.tokenPrice
      );

      // book the balances
      _vars.vaultStorage.payFundingFeeFromFundingFeeReserveToTrader(_vars.subAccount, _collateralToken, _repayAmount);

      // Update accum funding fee on Global storage for surplus calculation
      _vars.isLong
        ? _updateAccumFundingLong(_vars.marketIndex, int(_repayValue))
        : _updateAccumFundingShort(_vars.marketIndex, int(_repayValue));

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.absFundingFeeToBePaid -= _repayValue;
    }
  }

  function _settleFundingFeeWhenBorrowingFromPLP(SettleAllFeesVars memory _vars, address _collateralToken) internal {
    // When plp liquidity is the payer
    uint256 _plpBalance = _vars.vaultStorage.plpLiquidity(_collateralToken);

    // We are going to deduct plp liquidity balance,
    // so we need to check whether plp has this collateral token or not.
    // If not skip to next token
    if (_plpBalance > 0) {
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _plpBalance,
        _vars.absFundingFeeToBePaid,
        _collateralToken,
        _vars.tokenPrice
      );

      // book the balances
      _vars.vaultStorage.borrowFundingFeeFromPlpToTrader(_vars.subAccount, _collateralToken, _repayAmount, _repayValue);

      // Update accum funding fee on Global storage for surplus calculation
      _vars.isLong
        ? _updateAccumFundingLong(_vars.marketIndex, int(_repayValue))
        : _updateAccumFundingShort(_vars.marketIndex, int(_repayValue));

      // deduct _vars.absFundingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.absFundingFeeToBePaid -= _repayValue;

      emit LogSettleFundingFeeAmountWhenTraderReceives(_vars.subAccount, _collateralToken, _repayAmount);
    }
  }

  function _settleTradingFee(SettleAllFeesVars memory _vars, address _collateralToken) internal {
    // Get trader balance of each collateral
    uint256 _traderBalance = _vars.vaultStorage.traderBalances(_vars.subAccount, _collateralToken);

    // if trader has some of this collateral token, try cover the fee with it
    if (_traderBalance > 0) {
      // protocol fee portion + dev fee portion
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _traderBalance,
        _vars.tradingFeeToBePaid,
        _collateralToken,
        _vars.tokenPrice
      );

      // devFee = tradingFee * devFeeRate
      uint256 _devFeeAmount = (_repayAmount * _vars.tradingConfig.devFeeRateBPS) / BPS;
      // the rest after dev fee deduction belongs to protocol fee portion
      uint256 _protocolFeeAmount = _repayAmount - _devFeeAmount;

      // book those moving balances
      _vars.vaultStorage.payTradingFee(_vars.subAccount, _collateralToken, _devFeeAmount, _protocolFeeAmount);

      // deduct _vars.tradingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.tradingFeeToBePaid -= _repayValue;

      emit LogSettleTradingFeeAmount(_vars.subAccount, _collateralToken, _devFeeAmount, _protocolFeeAmount);
    }
    // else continue, as trader does not have any of this collateral token
  }

  function _settleBorrowingFee(SettleAllFeesVars memory _vars, address _collateralToken) internal {
    // Get trader balance of each collateral
    uint256 _traderBalance = _vars.vaultStorage.traderBalances(_vars.subAccount, _collateralToken);

    // if trader has some of this collateral token, try cover the fee with it
    if (_traderBalance > 0) {
      // plp fee portion + dev fee portion
      (uint256 _repayAmount, uint256 _repayValue) = _getRepayAmount(
        _vars.configStorage,
        _traderBalance,
        _vars.borrowingFeeToBePaid,
        _collateralToken,
        _vars.tokenPrice
      );

      // devFee = tradingFee * devFeeRate
      uint256 _devFeeAmount = (_repayAmount * _vars.tradingConfig.devFeeRateBPS) / BPS;
      // the rest after dev fee deduction belongs to plp liquidity
      uint256 _plpFeeAmount = _repayAmount - _devFeeAmount;

      // book those moving balances
      _vars.vaultStorage.payBorrowingFee(_vars.subAccount, _collateralToken, _devFeeAmount, _plpFeeAmount);

      // deduct _vars.tradingFeeToBePaid with _repayAmount, so that the next iteration could continue deducting the fee
      _vars.borrowingFeeToBePaid -= _repayValue;

      emit LogSettleBorrowingFeeAmount(_vars.subAccount, _collateralToken, _devFeeAmount, _plpFeeAmount);
    }
    // else continue, as trader does not have any of this collateral token
  }

  function _accumSettledBorrowingFee(uint256 _assetClassIndex, uint256 _borrowingFeeToBeSettled) internal {
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    PerpStorage.GlobalAssetClass memory _globalAssetClass = _perpStorage.getGlobalAssetClassByIndex(
      uint8(_assetClassIndex)
    );
    _globalAssetClass.sumSettledBorrowingFeeE30 += _borrowingFeeToBeSettled;
    _perpStorage.updateGlobalAssetClass(uint8(_assetClassIndex), _globalAssetClass);
  }

  function _getRepayAmount(
    ConfigStorage _configStorage,
    uint256 _traderBalance,
    uint256 _feeValueE30,
    address _token,
    uint256 _tokenPrice
  ) internal view returns (uint256 _repayAmount, uint256 _repayValueE30) {
    uint8 _tokenDecimal = _configStorage.getAssetTokenDecimal(_token);
    uint256 _feeAmount = (_feeValueE30 * (10 ** _tokenDecimal)) / _tokenPrice;

    if (_traderBalance > _feeAmount) {
      // _traderBalance can cover the rest of the fee
      return (_feeAmount, _feeValueE30);
    } else {
      // _traderBalance cannot cover the rest of the fee, just take the amount the trader have
      uint256 _traderBalanceValue = (_traderBalance * _tokenPrice) / (10 ** _tokenDecimal);
      return (_traderBalance, _traderBalanceValue);
    }
  }

  function _updateAccumFundingLong(uint256 _marketIndex, int256 fundingLong) internal {
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    PerpStorage.GlobalMarket memory _globalMarket = _perpStorage.getGlobalMarketByIndex(_marketIndex);

    _globalMarket.accumFundingLong += fundingLong;
    _perpStorage.updateGlobalMarket(_marketIndex, _globalMarket);
  }

  function _updateAccumFundingShort(uint256 _marketIndex, int256 fundingShort) internal {
    PerpStorage _perpStorage = PerpStorage(perpStorage);
    PerpStorage.GlobalMarket memory _globalMarket = _perpStorage.getGlobalMarketByIndex(_marketIndex);

    _globalMarket.accumFundingShort += fundingShort;
    _perpStorage.updateGlobalMarket(_marketIndex, _globalMarket);
  }

  function _abs(int256 x) private pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }

  function _getSubAccount(address _primary, uint8 _subAccountId) internal pure returns (address) {
    if (_subAccountId > 255) revert();
    return address(uint160(_primary) ^ uint160(_subAccountId));
  }

  /**
   * Setter
   */
  /// @notice Set new ConfigStorage contract address.
  /// @param _configStorage New ConfigStorage contract address.
  function setConfigStorage(address _configStorage) external nonReentrant onlyOwner {
    if (_configStorage == address(0)) revert ITradeHelper_InvalidAddress();
    emit LogSetConfigStorage(configStorage, _configStorage);
    configStorage = _configStorage;

    // Sanity check
    ConfigStorage(_configStorage).calculator();
  }

  /// @notice Set new VaultStorage contract address.
  /// @param _vaultStorage New VaultStorage contract address.
  function setVaultStorage(address _vaultStorage) external nonReentrant onlyOwner {
    if (_vaultStorage == address(0)) revert ITradeHelper_InvalidAddress();

    emit LogSetVaultStorage(vaultStorage, _vaultStorage);
    vaultStorage = _vaultStorage;

    // Sanity check
    VaultStorage(_vaultStorage).devFees(address(0));
  }

  /// @notice Set new PerpStorage contract address.
  /// @param _perpStorage New PerpStorage contract address.
  function setPerpStorage(address _perpStorage) external nonReentrant onlyOwner {
    if (_perpStorage == address(0)) revert ITradeHelper_InvalidAddress();

    emit LogSetPerpStorage(perpStorage, _perpStorage);
    perpStorage = _perpStorage;

    // Sanity check
    PerpStorage(_perpStorage).getGlobalState();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { PerpStorage } from "@hmx/storages/PerpStorage.sol";

interface ITradeHelper {
  error ITradeHelper_TradingFeeCannotBeCovered();
  error ITradeHelper_BorrowingFeeCannotBeCovered();
  error ITradeHelper_FundingFeeCannotBeCovered();
  error ITradeHelper_InvalidAddress();

  function reloadConfig() external;

  function updateBorrowingRate(uint8 _assetClassIndex) external;

  function updateFundingRate(uint256 _marketIndex) external;

  function settleAllFees(
    PerpStorage.Position memory position,
    uint256 _absSizeDelta,
    uint32 _positionFeeBPS,
    uint8 _assetClassIndex,
    uint256 _marketIndex
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

library IteratableAddressList {
  error IteratableAddressList_Existed();
  error IteratableAddressList_NotExisted();
  error IteratableAddressList_NotInitialized();
  error IteratableAddressList_WrongPrev();

  address internal constant START = address(1);
  address internal constant END = address(1);
  address internal constant EMPTY = address(0);

  struct List {
    uint256 size;
    mapping(address => address) next;
  }

  function init(List storage list) internal returns (List storage) {
    list.next[START] = END;
    return list;
  }

  function has(List storage list, address addr) internal view returns (bool) {
    return list.next[addr] != EMPTY;
  }

  function add(
    List storage list,
    address addr
  ) internal returns (List storage) {
    // Check
    if (has(list, addr)) revert IteratableAddressList_Existed();

    // Effect
    list.next[addr] = list.next[START];
    list.next[START] = addr;
    list.size++;

    return list;
  }

  function remove(
    List storage list,
    address addr,
    address prevAddr
  ) internal returns (List storage) {
    // Check
    if (!has(list, addr)) revert IteratableAddressList_NotExisted();
    if (list.next[prevAddr] != addr) revert IteratableAddressList_WrongPrev();

    // Effect
    list.next[prevAddr] = list.next[addr];
    list.next[addr] = EMPTY;
    list.size--;

    return list;
  }

  function getAll(List storage list) internal view returns (address[] memory) {
    address[] memory addrs = new address[](list.size);
    address curr = list.next[START];
    for (uint256 i = 0; curr != END; i++) {
      addrs[i] = curr;
      curr = list.next[curr];
    }
    return addrs;
  }

  function getPreviousOf(
    List storage list,
    address addr
  ) internal view returns (address) {
    address curr = list.next[START];
    if (curr == EMPTY) revert IteratableAddressList_NotInitialized();
    for (uint256 i = 0; curr != END; i++) {
      if (list.next[curr] == addr) return curr;
      curr = list.next[curr];
    }
    return END;
  }

  function getNextOf(
    List storage list,
    address curr
  ) internal view returns (address) {
    return list.next[curr];
  }

  function length(List storage list) internal view returns (uint256) {
    return list.size;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Owned } from "@hmx/base/Owned.sol";
import { IOracleAdapter } from "./interfaces/IOracleAdapter.sol";
import { IOracleMiddleware } from "./interfaces/IOracleMiddleware.sol";

contract OracleMiddleware is Owned, IOracleMiddleware {
  /**
   * Structs
   */
  struct AssetPriceConfig {
    /// @dev Acceptable price age in second.
    uint32 trustPriceAge;
    /// @dev The acceptable threshold confidence ratio. ex. _confidenceRatio = 0.01 ether means 1%
    uint32 confidenceThresholdE6;
  }

  /**
   * Events
   */
  event LogSetMarketStatus(bytes32 indexed _assetId, uint8 _status);
  event LogSetUpdater(address indexed _account, bool _isActive);
  event LogSetAssetPriceConfig(
    bytes32 indexed _assetId,
    uint32 _oldConfidenceThresholdE6,
    uint32 _newConfidenceThresholdE6,
    uint256 _oldTrustPriceAge,
    uint256 _newTrustPriceAge
  );
  event LogSetPythAdapter(address oldPythAdapter, address newPythAdapter);

  /**
   * States
   */
  IOracleAdapter public pythAdapter;

  // whitelist mapping of market status updater
  mapping(address => bool) public isUpdater;
  mapping(bytes32 => AssetPriceConfig) public assetPriceConfigs;

  // states
  // MarketStatus
  // Note from Pyth doc: Only prices with a value of status=trading should be used. If the status is not trading but is
  // Unknown, Halted or Auction the Pyth price can be an arbitrary value.
  // https://docs.pyth.network/design-overview/account-structure
  //
  // 0 = Undefined, default state since contract init
  // 1 = Inactive, equivalent to `unknown`, `halted`, `auction`, `ignored` from Pyth
  // 2 = Active, equivalent to `trading` from Pyth
  // assetId => marketStatus
  mapping(bytes32 => uint8) public marketStatus;

  constructor(IOracleAdapter _pythAdapter) {
    pythAdapter = _pythAdapter;
  }

  /**
   * Modifiers
   */

  modifier onlyUpdater() {
    if (!isUpdater[msg.sender]) {
      revert IOracleMiddleware_OnlyUpdater();
    }
    _;
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdate) {
    (_price, , _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate);
  }

  /// @notice Return the latest price and last update of the given asset id.
  /// @dev Same as getLatestPrice(), but unsafe function has no check price age
  /// @dev It is expected that the downstream contract should return the price in USD with 30 decimals.
  /// @dev The currency of the price that will be quoted with depends on asset id. For example, we can have two BTC price but quoted differently.
  ///      In that case, we can define two different asset ids as BTC/USD, BTC/EUR.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    (_price, _exponent, _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _exponent, _lastUpdate);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as getLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, , _lastUpdate) = _getLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest price of asset, last update of the given asset id, along with market status.
  /// @dev Same as unsafeGetLatestPrice(), but with market status. Revert if status is 0 (Undefined) which means we never utilize this assetId.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_price, , _lastUpdate) = _unsafeGetLatestPrice(_assetId, _isMax);

    return (_price, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the unsafe latest adaptive rice of asset, last update of the given asset id
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate) {
    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false
    );
    return (_adaptivePrice, _lastUpdate);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, _exponent, _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      true
    );
    return (_adaptivePrice, _exponent, _lastUpdate, _status);
  }

  /// @notice Return the latest adaptive rice of asset, last update of the given asset id, along with market status.
  /// @dev Adaptive price is the price that is applied with premium or discount based on the market skew.
  /// @param _assetId The asset id to get the price. This can be address or generic id.
  /// @param _isMax Whether to get the max price or min price.
  /// @param _marketSkew market skew quoted in asset (NOT USD)
  /// @param _sizeDelta The size delta of this operation. It will determine the new market skew to be used for calculation.
  /// @param _maxSkewScaleUSD The config of maxSkewScaleUSD
  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status) {
    _status = marketStatus[_assetId];
    if (_status == 0) revert IOracleMiddleware_MarketStatusUndefined();

    (_adaptivePrice, , _lastUpdate) = _getLatestAdaptivePrice(
      _assetId,
      _isMax,
      _marketSkew,
      _sizeDelta,
      _maxSkewScaleUSD,
      false
    );
    return (_adaptivePrice, _lastUpdate, _status);
  }

  function _getLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) private view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth
    (_price, _exponent, _lastUpdate) = pythAdapter.getLatestPrice(_assetId, _isMax, _assetConfig.confidenceThresholdE6);

    // check price age
    if (block.timestamp - _lastUpdate > _assetConfig.trustPriceAge) revert IOracleMiddleware_PythPriceStale();

    // 2. Return the price and last update
    return (_price, _exponent, _lastUpdate);
  }

  function _unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) private view returns (uint256 _price, int32 _exponent, uint256 _lastUpdate) {
    AssetPriceConfig memory _assetConfig = assetPriceConfigs[_assetId];

    // 1. get price from Pyth
    (_price, _exponent, _lastUpdate) = pythAdapter.getLatestPrice(_assetId, _isMax, _assetConfig.confidenceThresholdE6);

    // 2. Return the price and last update
    return (_price, _exponent, _lastUpdate);
  }

  function _getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD,
    bool isSafe
  ) private view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate) {
    // Get price from Pyth
    uint256 _price;
    (_price, _exponent, _lastUpdate) = isSafe
      ? _getLatestPrice(_assetId, _isMax)
      : _unsafeGetLatestPrice(_assetId, _isMax);

    // Apply premium/discount
    _adaptivePrice = _calculateAdaptivePrice(_marketSkew, _sizeDelta, _price, _maxSkewScaleUSD);

    // Return the price and last update
    return (_adaptivePrice, _exponent, _lastUpdate);
  }

  /// @notice Calcuatate adaptive base on Market skew by position size
  /// @param _marketSkew Long position size - Short position size
  /// @param _sizeDelta Position size delta
  /// @param _price Oracle price
  /// @param _maxSkewScaleUSD Config from Market config
  /// @return _adaptivePrice
  function _calculateAdaptivePrice(
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _price,
    uint256 _maxSkewScaleUSD
  ) internal pure returns (uint256 _adaptivePrice) {
    // couldn't calculate adaptive price because max skew scale config is used to calcualte premium with market skew
    // then just return oracle price
    if (_maxSkewScaleUSD == 0) return _price;

    // Given
    //    Max skew scale = 300,000,000 USD
    //    Current Price  =       1,500 USD
    //    Given:
    //      Long Position size   = 1,000,000 USD
    //      Short Position size  =   700,000 USD
    //      then Market skew     = Long - Short = 300,000 USD
    //
    //    If Trader manipulatate by Decrease Long position for 150,000 USD
    //    Then:
    //      Premium (before) = 300,000 / 300,000,000 = 0.001
    int256 _premium = (_marketSkew * 1e30) / int256(_maxSkewScaleUSD);

    //      Premium (after)  = (300,000 - 150,000) / 300,000,000 = 0.0005
    //      ** + When user increase Long position ot Decrease Short position
    //      ** - When user increase Short position ot Decrease Long position
    int256 _premiumAfter = ((_marketSkew + _sizeDelta) * 1e30) / int256(_maxSkewScaleUSD);

    //      Adaptive price = Price * (1 + Median of Before and After)
    //                     = 1,500 * (1 + (0.001 + 0.0005 / 2))
    //                     = 1,500 * (1 + 0.00125) = 1,501.875
    int256 _premiumMedian = (_premium + _premiumAfter) / 2;
    return (_price * uint256(1e30 + _premiumMedian)) / 1e30;
  }

  /// @notice Set asset price configs
  /// @param _assetId Asset's to set price config
  /// @param _confidenceThresholdE6 New price confidence threshold
  /// @param _trustPriceAge valid price age
  function setAssetPriceConfig(
    bytes32 _assetId,
    uint32 _confidenceThresholdE6,
    uint32 _trustPriceAge
  ) external onlyOwner {
    AssetPriceConfig memory _config = assetPriceConfigs[_assetId];

    emit LogSetAssetPriceConfig(
      _assetId,
      _config.confidenceThresholdE6,
      _confidenceThresholdE6,
      _config.trustPriceAge,
      _trustPriceAge
    );
    _config.confidenceThresholdE6 = _confidenceThresholdE6;
    _config.trustPriceAge = _trustPriceAge;

    assetPriceConfigs[_assetId] = _config;
  }

  /// @notice Set market status for the given asset.
  /// @param _assetId The asset address to set.
  /// @param _status Status enum, see `marketStatus` comment section.
  function setMarketStatus(bytes32 _assetId, uint8 _status) external onlyUpdater {
    if (_status > 2) revert IOracleMiddleware_InvalidMarketStatus();

    marketStatus[_assetId] = _status;
    emit LogSetMarketStatus(_assetId, _status);
  }

  /// @notice A function for setting updater who is able to setMarketStatus
  function setUpdater(address _account, bool _isActive) external onlyOwner {
    isUpdater[_account] = _isActive;
    emit LogSetUpdater(_account, _isActive);
  }

  /**
   * Setter
   */
  /// @notice Set new PythAdapter contract address.
  /// @param _newPythAdapter New PythAdapter contract address.
  function setPythAdapter(address _newPythAdapter) external onlyOwner {
    pythAdapter = IOracleAdapter(_newPythAdapter);

    emit LogSetPythAdapter(address(pythAdapter), _newPythAdapter);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOracleAdapter {
  function getLatestPrice(
    bytes32 _assetId,
    bool _isMax,
    uint32 _confidenceThreshold
  ) external view returns (uint256, int32, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOracleMiddleware {
  // errors
  error IOracleMiddleware_PythPriceStale();
  error IOracleMiddleware_MarketStatusUndefined();
  error IOracleMiddleware_OnlyUpdater();
  error IOracleMiddleware_InvalidMarketStatus();

  function isUpdater(address _updater) external returns (bool);

  function assetPriceConfigs(bytes32 _assetId) external returns (uint32, uint32);

  function marketStatus(bytes32 _assetId) external returns (uint8);

  function getLatestPrice(bytes32 _assetId, bool _isMax) external view returns (uint256 _price, uint256 _lastUpdated);

  function getLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function getLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function unsafeGetLatestAdaptivePrice(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate);

  function getLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, int32 _exponent, uint256 _lastUpdate, uint8 _status);

  function unsafeGetLatestAdaptivePriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax,
    int256 _marketSkew,
    int256 _sizeDelta,
    uint256 _maxSkewScaleUSD
  ) external view returns (uint256 _adaptivePrice, uint256 _lastUpdate, uint8 _status);

  // =========================================
  // | ---------- Setter ------------------- |
  // =========================================

  function unsafeGetLatestPrice(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, int32 _exponent, uint256 _lastUpdated);

  function unsafeGetLatestPriceWithMarketStatus(
    bytes32 _assetId,
    bool _isMax
  ) external view returns (uint256 _price, uint256 _lastUpdated, uint8 _status);

  function setMarketStatus(bytes32 _assetId, uint8 _status) external;

  function setUpdater(address _updater, bool _isActive) external;

  function setAssetPriceConfig(bytes32 _assetId, uint32 _confidenceThresholdE6, uint32 _trustPriceAge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contracts
import { PerpStorage } from "@hmx/storages/PerpStorage.sol";
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";
import { Calculator } from "@hmx/contracts/Calculator.sol";
import { OracleMiddleware } from "@hmx/oracle/OracleMiddleware.sol";
import { TradeHelper } from "@hmx/helpers/TradeHelper.sol";
import { Owned } from "@hmx/base/Owned.sol";

// interfaces
import { ITradeService } from "@hmx/services/interfaces/ITradeService.sol";
import { ITradeServiceHook } from "@hmx/services/interfaces/ITradeServiceHook.sol";

// @todo - refactor, deduplicate code
contract TradeService is ReentrancyGuard, ITradeService, Owned {
  uint32 internal constant BPS = 1e4;
  uint64 internal constant RATE_PRECISION = 1e18;

  /**
   * Structs
   */
  struct IncreasePositionVars {
    PerpStorage.Position position;
    address subAccount;
    bytes32 positionId;
    bool isLong;
    bool isNewPosition;
    bool currentPositionIsLong;
    uint256 adaptivePriceE30;
    uint256 priceE30;
    uint256 closePriceE30;
    int32 exponent;
  }
  struct DecreasePositionVars {
    PerpStorage.Position position;
    address subAccount;
    bytes32 positionId;
    uint256 absPositionSizeE30;
    uint256 closePrice;
    bool isLongPosition;
    uint256 positionSizeE30ToDecrease;
    address tpToken;
    uint256 limitPriceE30;
    uint256 oraclePrice;
    int256 realizedPnl;
    int256 unrealizedPnl;
    // for SLOAD
    Calculator calculator;
    PerpStorage perpStorage;
    ConfigStorage configStorage;
    OracleMiddleware oracle;
  }

  struct SettleLossVars {
    uint256 price;
    uint256 collateral;
    uint256 collateralUsd;
    uint256 collateralToRemove;
    uint256 decimals;
    bytes32 tokenAssetId;
  }

  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    _;
  }

  /**
   * Events
   */
  // @todo - modify event parameters
  event LogDecreasePosition(bytes32 indexed _positionId, uint256 _decreasedSize);
  event LogForceClosePosition(
    address indexed _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    address _tpToken,
    uint256 _closedPositionSize,
    bool isProfit,
    uint256 _delta
  );
  event LogDeleverage(
    address indexed _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    address _tpToken,
    uint256 _closedPositionSize
  );
  event LogSetConfigStorage(address indexed oldConfigStorage, address newConfigStorage);
  event LogSetVaultStorage(address indexed oldVaultStorage, address newVaultStorage);
  event LogSetPerpStorage(address indexed oldPerpStorage, address newPerpStorage);
  event LogSetCalculator(address indexed oldCalculator, address newCalculator);
  event LogSetTradeHelper(address indexed oldTradeHelper, address newTradeHelper);

  /**
   * States
   */
  address public perpStorage;
  address public vaultStorage;
  address public configStorage;
  address public tradeHelper;
  Calculator public calculator; // cache this from configStorage

  constructor(address _perpStorage, address _vaultStorage, address _configStorage, address _tradeHelper) {
    // Sanity check
    PerpStorage(_perpStorage).getGlobalState();
    VaultStorage(_vaultStorage).plpLiquidityDebtUSDE30();
    ConfigStorage(_configStorage).getLiquidityConfig();

    perpStorage = _perpStorage;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;
    tradeHelper = _tradeHelper;
    calculator = Calculator(ConfigStorage(_configStorage).calculator());
  }

  function reloadConfig() external {
    // TODO: access control, sanity check, natspec
    // TODO: discuss about this pattern

    calculator = Calculator(ConfigStorage(configStorage).calculator());
  }

  /// @notice This function increases a trader's position for a specific market by a given size delta.
  ///         The primary account and sub-account IDs are used to identify the trader's account.
  ///         The market index is used to identify the specific market.
  /// @param _primaryAccount The address of the primary account associated with the trader.
  /// @param _subAccountId The ID of the sub-account associated with the trader.
  /// @param _marketIndex The index of the market for which the position is being increased.
  /// @param _sizeDelta The change in size of the position. Positive values meaning LONG position, while negative values mean SHORT position.
  /// @param _limitPriceE30 limit price for execute order
  function increasePosition(
    address _primaryAccount,
    uint8 _subAccountId,
    uint256 _marketIndex,
    int256 _sizeDelta,
    uint256 _limitPriceE30
  ) external nonReentrant onlyWhitelistedExecutor {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    Calculator _calculator = calculator;
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // validate service should be called from handler ONLY
    _configStorage.validateServiceExecutor(address(this), msg.sender);

    IncreasePositionVars memory _vars;

    // get the sub-account from the primary account and sub-account ID
    _vars.subAccount = _getSubAccount(_primaryAccount, _subAccountId);

    // get the position for the given sub-account and market index
    _vars.positionId = _getPositionId(_vars.subAccount, _marketIndex);
    _vars.position = _perpStorage.getPositionById(_vars.positionId);

    // get the market configuration for the given market index
    ConfigStorage.MarketConfig memory _marketConfig = _configStorage.getMarketConfigByIndex(_marketIndex);

    // check size delta
    if (_sizeDelta == 0) revert ITradeService_BadSizeDelta();

    // check allow increase position
    if (!_marketConfig.allowIncreasePosition) revert ITradeService_NotAllowIncrease();

    // determine whether the new size delta is for a long position
    _vars.isLong = _sizeDelta > 0;

    _vars.isNewPosition = _vars.position.positionSizeE30 == 0;

    // Pre validation
    // Verify that the number of positions has exceeds
    {
      if (
        _vars.isNewPosition &&
        _configStorage.getTradingConfig().maxPosition < _perpStorage.getNumberOfSubAccountPosition(_vars.subAccount) + 1
      ) revert ITradeService_BadNumberOfPosition();
    }

    _vars.currentPositionIsLong = _vars.position.positionSizeE30 > 0;
    // Verify that the current position has the same exposure direction
    if (!_vars.isNewPosition && _vars.currentPositionIsLong != _vars.isLong) revert ITradeService_BadExposure();

    // Update borrowing rate
    TradeHelper(tradeHelper).updateBorrowingRate(_marketConfig.assetClass);

    // Update funding rate
    TradeHelper(tradeHelper).updateFundingRate(_marketIndex);

    // get the global market for the given market index
    PerpStorage.GlobalMarket memory _globalMarket = _perpStorage.getGlobalMarketByIndex(_marketIndex);
    {
      uint256 _lastPriceUpdated;
      uint8 _marketStatus;

      // Get Price market.
      (_vars.adaptivePriceE30, _vars.exponent, _lastPriceUpdated, _marketStatus) = OracleMiddleware(
        _configStorage.oracle()
      ).getLatestAdaptivePriceWithMarketStatus(
          _marketConfig.assetId,
          _vars.isLong, // if current position is SHORT position, then we use max price
          (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
          _sizeDelta,
          _marketConfig.fundingRate.maxSkewScaleUSD
        );

      if (_limitPriceE30 != 0) {
        _vars.adaptivePriceE30 = _limitPriceE30;
      }

      (_vars.closePriceE30, , , ) = OracleMiddleware(_configStorage.oracle()).getLatestAdaptivePriceWithMarketStatus(
        _marketConfig.assetId,
        _vars.isLong, // if current position is SHORT position, then we use max price
        (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
        -_vars.position.positionSizeE30,
        _marketConfig.fundingRate.maxSkewScaleUSD
      );

      // Market active represent the market is still listed on our protocol
      if (!_marketConfig.active) revert ITradeService_MarketIsDelisted();

      // if market status is not 2, means that the market is closed or market status has been defined yet
      if (_marketStatus != 2) revert ITradeService_MarketIsClosed();
    }

    // market validation
    // check sub account equity is under MMR
    _subAccountHealthCheck(_vars.subAccount, _limitPriceE30, _marketConfig.assetId);

    // get the absolute value of the new size delta
    uint256 _absSizeDelta = abs(_sizeDelta);

    // if the position size is zero, set the average price to the current price (new position)
    if (_vars.isNewPosition) {
      _vars.position.avgEntryPriceE30 = _vars.adaptivePriceE30;
      _vars.position.primaryAccount = _primaryAccount;
      _vars.position.subAccountId = _subAccountId;
      _vars.position.marketIndex = _marketIndex;
    }

    // Settle
    // - trading fees
    // - borrowing fees
    // - funding fees
    TradeHelper(tradeHelper).settleAllFees(
      _vars.position,
      _absSizeDelta,
      _marketConfig.increasePositionFeeRateBPS,
      _marketConfig.assetClass,
      _marketIndex
    );

    // update the position size by adding the new size delta
    _vars.position.positionSizeE30 += _sizeDelta;

    // if the position size is not zero and the new size delta is not zero, calculate the new average price (adjust position)
    if (!_vars.isNewPosition) {
      // console2.log("======== new close price ======= ");
      (uint256 _nextClosePriceE30, , , ) = OracleMiddleware(_configStorage.oracle())
        .getLatestAdaptivePriceWithMarketStatus(
          _marketConfig.assetId,
          _vars.isLong, // if current position is SHORT position, then we use max price
          // + new position size delta to update market skew temporary
          (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)) + _sizeDelta,
          // positionSizeE30 is new position size, when updated with sizeDelta above
          -_vars.position.positionSizeE30,
          _marketConfig.fundingRate.maxSkewScaleUSD
        );

      // console2.log("_nextClosePriceE30", _nextClosePriceE30);

      _vars.position.avgEntryPriceE30 = _getPositionNextAveragePrice(
        abs(_vars.position.positionSizeE30),
        _vars.isLong,
        _absSizeDelta,
        _nextClosePriceE30,
        _vars.closePriceE30,
        _vars.position.avgEntryPriceE30,
        _vars.position.lastIncreaseTimestamp
      );
    }

    {
      PerpStorage.GlobalAssetClass memory _globalAssetClass = _perpStorage.getGlobalAssetClassByIndex(
        _marketConfig.assetClass
      );

      _vars.position.entryBorrowingRate = _globalAssetClass.sumBorrowingRate;
      _vars.position.entryFundingRate = _globalMarket.currentFundingRate;
    }

    // if the position size is zero after the update, revert the transaction with an error
    if (_vars.position.positionSizeE30 == 0) revert ITradeService_BadPositionSize();

    {
      // calculate the initial margin required for the new position
      uint256 _imr = (_absSizeDelta * _marketConfig.initialMarginFractionBPS) / BPS;

      // get the amount of free collateral available for the sub-account
      uint256 subAccountFreeCollateral = _calculator.getFreeCollateral(
        _vars.subAccount,
        _limitPriceE30,
        _marketConfig.assetId
      );

      // if the free collateral is less than the initial margin required, revert the transaction with an error
      if (subAccountFreeCollateral < _imr) revert ITradeService_InsufficientFreeCollateral();

      // calculate the maximum amount of reserve required for the new position
      uint256 _maxReserve = (_imr * _marketConfig.maxProfitRateBPS) / BPS;
      // increase the reserved amount by the maximum reserve required for the new position
      _increaseReserved(_marketConfig.assetClass, _maxReserve);
      _vars.position.reserveValueE30 += _maxReserve;
    }

    {
      _vars.position.lastIncreaseTimestamp = block.timestamp;

      // update global market state
      if (_vars.isLong) {
        uint256 _nextAvgPrice = _globalMarket.longPositionSize == 0
          ? _vars.adaptivePriceE30
          : _calculator.calculateLongAveragePrice(_globalMarket, _vars.adaptivePriceE30, _sizeDelta, 0);

        _perpStorage.updateGlobalLongMarketById(
          _marketIndex,
          _globalMarket.longPositionSize + _absSizeDelta,
          _nextAvgPrice
        );
      } else {
        // to increase SHORT position sizeDelta should be negative
        uint256 _nextAvgPrice = _globalMarket.shortPositionSize == 0
          ? _vars.adaptivePriceE30
          : _calculator.calculateShortAveragePrice(_globalMarket, _vars.adaptivePriceE30, _sizeDelta, 0);

        _perpStorage.updateGlobalShortMarketById(
          _marketIndex,
          _globalMarket.shortPositionSize + _absSizeDelta,
          _nextAvgPrice
        );
      }
    }

    // save the updated position to the storage
    _perpStorage.savePosition(_vars.subAccount, _vars.positionId, _vars.position);

    // Call Trade Service Hook
    _increasePositionHooks(_primaryAccount, _subAccountId, _marketIndex, _absSizeDelta);
  }

  // @todo - rewrite description
  /// @notice decrease trader position
  /// @param _account - address
  /// @param _subAccountId - address
  /// @param _marketIndex - market index
  /// @param _positionSizeE30ToDecrease - position size to decrease
  /// @param _tpToken - take profit token
  /// @param _limitPriceE30  price from LimitTrade in e30 unit
  function decreasePosition(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _positionSizeE30ToDecrease,
    address _tpToken,
    uint256 _limitPriceE30
  ) external nonReentrant onlyWhitelistedExecutor {
    // init vars
    DecreasePositionVars memory _vars;
    // SLOAD
    _vars.configStorage = ConfigStorage(configStorage);
    _vars.perpStorage = PerpStorage(perpStorage);
    _vars.calculator = calculator;

    // validate service should be called from handler ONLY
    _vars.configStorage.validateServiceExecutor(address(this), msg.sender);

    // prepare
    ConfigStorage.MarketConfig memory _marketConfig = _vars.configStorage.getMarketConfigByIndex(_marketIndex);

    _vars.subAccount = _getSubAccount(_account, _subAccountId);
    _vars.positionId = _getPositionId(_vars.subAccount, _marketIndex);
    _vars.position = _vars.perpStorage.getPositionById(_vars.positionId);

    // Pre validation
    // if position size is 0 means this position is already closed
    if (_vars.position.positionSizeE30 == 0) revert ITradeService_PositionAlreadyClosed();

    _vars.isLongPosition = _vars.position.positionSizeE30 > 0;

    // convert position size to be uint256
    _vars.absPositionSizeE30 = uint256(
      _vars.isLongPosition ? _vars.position.positionSizeE30 : -_vars.position.positionSizeE30
    );
    _vars.positionSizeE30ToDecrease = _positionSizeE30ToDecrease;
    _vars.tpToken = _tpToken;
    _vars.limitPriceE30 = _limitPriceE30;
    _vars.oracle = OracleMiddleware(_vars.configStorage.oracle());

    // position size to decrease is greater then position size, should be revert
    if (_positionSizeE30ToDecrease > _vars.absPositionSizeE30) revert ITradeService_DecreaseTooHighPositionSize();

    PerpStorage.GlobalMarket memory _globalMarket = _vars.perpStorage.getGlobalMarketByIndex(_marketIndex);
    {
      uint256 _lastPriceUpdated;
      uint8 _marketStatus;

      (_vars.closePrice, , _lastPriceUpdated, _marketStatus) = _vars.oracle.getLatestAdaptivePriceWithMarketStatus(
        _marketConfig.assetId,
        !_vars.isLongPosition, // if current position is SHORT position, then we use max price
        (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
        -_vars.position.positionSizeE30,
        _marketConfig.fundingRate.maxSkewScaleUSD
      );

      if (_limitPriceE30 != 0) {
        _vars.closePrice = _limitPriceE30;
      }

      // Market active represent the market is still listed on our protocol
      if (!_marketConfig.active) revert ITradeService_MarketIsDelisted();

      // if market status is not 2, means that the market is closed or market status has been defined yet
      if (_marketStatus != 2) revert ITradeService_MarketIsClosed();

      // check sub account equity is under MMR
      _subAccountHealthCheck(_vars.subAccount, _limitPriceE30, _marketConfig.assetId);
    }

    // update position, market, and global market state
    _decreasePosition(_marketConfig, _marketIndex, _vars);

    // Call Trade Service Hook
    _decreasePositionHooks(_account, _subAccountId, _marketIndex, _positionSizeE30ToDecrease);
  }

  // @todo - access control
  /// @notice force close trader position with maximum profit could take
  /// @param _account position owner
  /// @param _subAccountId sub-account id
  /// @param _marketIndex position market index
  /// @param _tpToken take profit token
  function forceClosePosition(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    address _tpToken
  ) external nonReentrant onlyWhitelistedExecutor returns (bool _isMaxProfit, bool _isProfit, uint256 _delta) {
    // init vars
    DecreasePositionVars memory _vars;

    // SLOAD
    _vars.configStorage = ConfigStorage(configStorage);
    _vars.calculator = calculator;
    _vars.perpStorage = PerpStorage(perpStorage);

    ConfigStorage.MarketConfig memory _marketConfig = _vars.configStorage.getMarketConfigByIndex(_marketIndex);

    _vars.subAccount = _getSubAccount(_account, _subAccountId);
    _vars.positionId = _getPositionId(_vars.subAccount, _marketIndex);
    _vars.position = _vars.perpStorage.getPositionById(_vars.positionId);

    // Pre validation
    // if position size is 0 means this position is already closed
    if (_vars.position.positionSizeE30 == 0) revert ITradeService_PositionAlreadyClosed();

    _vars.isLongPosition = _vars.position.positionSizeE30 > 0;

    // convert position size to be uint256
    _vars.absPositionSizeE30 = uint256(
      _vars.isLongPosition ? _vars.position.positionSizeE30 : -_vars.position.positionSizeE30
    );
    _vars.positionSizeE30ToDecrease = _vars.absPositionSizeE30;
    _vars.tpToken = _tpToken;

    PerpStorage.GlobalMarket memory _globalMarket = _vars.perpStorage.getGlobalMarketByIndex(_marketIndex);

    {
      uint8 _marketStatus;

      (_vars.closePrice, , , _marketStatus) = OracleMiddleware(_vars.configStorage.oracle())
        .getLatestAdaptivePriceWithMarketStatus(
          _marketConfig.assetId,
          !_vars.isLongPosition, // if current position is SHORT position, then we use max price
          (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
          -_vars.position.positionSizeE30,
          _marketConfig.fundingRate.maxSkewScaleUSD
        );

      // if market status is not 2, means that the market is closed or market status has been defined yet
      if (_marketConfig.active && _marketStatus != 2) revert ITradeService_MarketIsClosed();
      // check sub account equity is under MMR
      /// @dev no need to derived price on this
      _subAccountHealthCheck(_vars.subAccount, 0, 0);
    }

    // update position, market, and global market state
    /// @dev no need to derived price on this
    (_isMaxProfit, _isProfit, _delta) = _decreasePosition(_marketConfig, _marketIndex, _vars);

    emit LogForceClosePosition(
      _account,
      _subAccountId,
      _marketIndex,
      _tpToken,
      _vars.absPositionSizeE30,
      _isProfit,
      _delta
    );
  }

  /// @notice Validates if a market is delisted.
  /// @param _marketIndex The index of the market to be checked.
  function validateMarketDelisted(uint256 _marketIndex) external view {
    // Check if the market is currently active in the config storage
    if (ConfigStorage(configStorage).getMarketConfigByIndex(_marketIndex).active) {
      // If it's active, revert with a custom error message defined in the ITradeService_MarketHealthy error definition
      revert ITradeService_MarketHealthy();
    }
  }

  /// @notice This function validates if deleverage is safe and healthy in Pool liquidity provider.
  function validateDeleverage() external view {
    // SLOAD
    Calculator _calculator = calculator;
    uint256 _aum = _calculator.getAUME30(false);
    uint256 _tvl = _calculator.getPLPValueE30(false);

    // check plp safety buffer
    if ((_tvl - _aum) * BPS <= (BPS - ConfigStorage(configStorage).getLiquidityConfig().plpSafetyBufferBPS) * _tvl)
      revert ITradeService_PlpHealthy();
  }

  /// @notice Validates if close position with max profit.
  /// @param _isMaxProfit close position with max profit.
  function validateMaxProfit(bool _isMaxProfit) external pure {
    if (!_isMaxProfit) revert ITradeService_ReservedValueStillEnough();
  }

  /// @notice decrease trader position
  /// @param _marketConfig - target market config
  /// @param _globalMarketIndex - global market index
  /// @param _vars - decrease criteria
  /// @return _isMaxProfit - positiion is close with max profit
  function _decreasePosition(
    ConfigStorage.MarketConfig memory _marketConfig,
    uint256 _globalMarketIndex,
    DecreasePositionVars memory _vars
  ) internal returns (bool _isMaxProfit, bool isProfit, uint256 delta) {
    // Update borrowing rate
    TradeHelper(tradeHelper).updateBorrowingRate(_marketConfig.assetClass);

    // Update funding rate
    TradeHelper(tradeHelper).updateFundingRate(_globalMarketIndex);

    // Settle
    // - trading fees
    // - borrowing fees
    // - funding fees
    TradeHelper(tradeHelper).settleAllFees(
      _vars.position,
      _vars.positionSizeE30ToDecrease,
      _marketConfig.increasePositionFeeRateBPS,
      _marketConfig.assetClass,
      _globalMarketIndex
    );

    uint256 _newAbsPositionSizeE30 = _vars.absPositionSizeE30 - _vars.positionSizeE30ToDecrease;

    // check position is too tiny
    // @todo - now validate this at 1 USD, design where to keep this config
    //       due to we has problem stack too deep in MarketConfig now
    if (_newAbsPositionSizeE30 > 0 && _newAbsPositionSizeE30 < 1e30) revert ITradeService_TooTinyPosition();

    /**
     * calculate realized profit & loss
     */
    {
      (isProfit, delta) = calculator.getDelta(
        _vars.absPositionSizeE30,
        _vars.isLongPosition,
        _vars.closePrice,
        _vars.position.avgEntryPriceE30,
        _vars.position.lastIncreaseTimestamp
      );

      // if trader has profit more than our reserved value then trader's profit maximum is reserved value
      if (isProfit && delta >= _vars.position.reserveValueE30) {
        delta = _vars.position.reserveValueE30;
        _isMaxProfit = true;
      }

      uint256 _toRealizedPnl = (delta * _vars.positionSizeE30ToDecrease) / _vars.absPositionSizeE30;
      if (isProfit) {
        _vars.realizedPnl = int256(_toRealizedPnl);
        _vars.unrealizedPnl = int256(delta - _toRealizedPnl);
      } else {
        _vars.realizedPnl = -int256(_toRealizedPnl);
        _vars.unrealizedPnl = -int256(delta - _toRealizedPnl);
      }
    }

    /**
     *  update perp storage
     */

    {
      PerpStorage.GlobalMarket memory _globalMarket = _vars.perpStorage.getGlobalMarketByIndex(_globalMarketIndex);

      if (_vars.isLongPosition) {
        uint256 _nextAvgPrice = _vars.calculator.calculateLongAveragePrice(
          _globalMarket,
          _vars.closePrice,
          -int256(_vars.positionSizeE30ToDecrease),
          _vars.realizedPnl
        );
        _vars.perpStorage.updateGlobalLongMarketById(
          _globalMarketIndex,
          _globalMarket.longPositionSize - _vars.positionSizeE30ToDecrease,
          _nextAvgPrice
        );
      } else {
        uint256 _nextAvgPrice = _vars.calculator.calculateShortAveragePrice(
          _globalMarket,
          _vars.closePrice,
          int256(_vars.positionSizeE30ToDecrease),
          _vars.realizedPnl
        );
        _vars.perpStorage.updateGlobalShortMarketById(
          _globalMarketIndex,
          _globalMarket.shortPositionSize - _vars.positionSizeE30ToDecrease,
          _nextAvgPrice
        );
      }

      PerpStorage.GlobalState memory _globalState = _vars.perpStorage.getGlobalState();
      PerpStorage.GlobalAssetClass memory _globalAssetClass = _vars.perpStorage.getGlobalAssetClassByIndex(
        _marketConfig.assetClass
      );

      // update global storage
      // to calculate new global reserve = current global reserve - reserve delta (position reserve * (position size delta / current position size))
      _globalState.reserveValueE30 -=
        (_vars.position.reserveValueE30 * _vars.positionSizeE30ToDecrease) /
        _vars.absPositionSizeE30;
      _globalAssetClass.reserveValueE30 -=
        (_vars.position.reserveValueE30 * _vars.positionSizeE30ToDecrease) /
        _vars.absPositionSizeE30;
      _vars.perpStorage.updateGlobalState(_globalState);
      _vars.perpStorage.updateGlobalAssetClass(_marketConfig.assetClass, _globalAssetClass);

      if (_newAbsPositionSizeE30 != 0) {
        // @todo - remove this, make this compat with testing that have to set max skew scale
        if (_marketConfig.fundingRate.maxSkewScaleUSD > 0) {
          // calculate new entry price here
          (_vars.oraclePrice, ) = _vars.oracle.getLatestPrice(
            _marketConfig.assetId,
            !_vars.isLongPosition // if current position is SHORT position, then we use max price
          );

          _vars.position.avgEntryPriceE30 = _getNewAvgPriceAfterDecrease(
            (int(_globalMarket.longPositionSize) - int(_globalMarket.shortPositionSize)),
            _vars.position.positionSizeE30,
            _vars.isLongPosition ? int(_vars.positionSizeE30ToDecrease) : -int(_vars.positionSizeE30ToDecrease),
            _vars.unrealizedPnl,
            _vars.oraclePrice,
            _marketConfig.fundingRate.maxSkewScaleUSD
          );
        }

        // update position info
        _vars.position.entryBorrowingRate = _globalAssetClass.sumBorrowingRate;
        _vars.position.entryFundingRate = _globalMarket.currentFundingRate;
        _vars.position.positionSizeE30 = _vars.isLongPosition
          ? int256(_newAbsPositionSizeE30)
          : -int256(_newAbsPositionSizeE30);
        _vars.position.reserveValueE30 =
          ((_newAbsPositionSizeE30 * _marketConfig.initialMarginFractionBPS * _marketConfig.maxProfitRateBPS) / BPS) /
          BPS;
        _vars.position.realizedPnl += _vars.realizedPnl;

        _vars.perpStorage.savePosition(_vars.subAccount, _vars.positionId, _vars.position);
      } else {
        _vars.perpStorage.removePositionFromSubAccount(_vars.subAccount, _vars.positionId);
      }
    }

    // =======================================
    // | ------ settle profit & loss ------- |
    // =======================================
    {
      if (_vars.realizedPnl != 0) {
        if (_vars.realizedPnl > 0) {
          // profit, trader should receive take profit token = Profit in USD
          _settleProfit(_vars.subAccount, _vars.tpToken, uint256(_vars.realizedPnl));
        } else {
          // loss
          _settleLoss(_vars.subAccount, uint256(-_vars.realizedPnl));
        }
      }
    }

    // =========================================
    // | --------- post validation ----------- |
    // =========================================

    // check sub account equity is under MMR
    _subAccountHealthCheck(_vars.subAccount, _vars.limitPriceE30, _marketConfig.assetId);

    emit LogDecreasePosition(_vars.positionId, _vars.positionSizeE30ToDecrease);
  }

  /// @notice settle profit
  /// @param _subAccount - Sub-account of trader
  /// @param _tpToken - token that trader want to take profit as collateral
  /// @param _realizedProfitE30 - trader profit in USD
  function _settleProfit(address _subAccount, address _tpToken, uint256 _realizedProfitE30) internal {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    VaultStorage _vaultStorage = VaultStorage(vaultStorage);

    bytes32 _tpAssetId = _configStorage.tokenAssetIds(_tpToken);
    (uint256 _tpTokenPrice, ) = OracleMiddleware(_configStorage.oracle()).getLatestPrice(_tpAssetId, false);

    uint256 _decimals = _configStorage.getAssetTokenDecimal(_tpToken);

    // calculate token trader should received
    uint256 _tpTokenOut = (_realizedProfitE30 * (10 ** _decimals)) / _tpTokenPrice;

    uint256 _settlementFeeRate = calculator.getSettlementFeeRate(_tpToken, _realizedProfitE30);

    uint256 _settlementFee = (_tpTokenOut * _settlementFeeRate) / 1e18;

    // TODO: no more fee to protocol fee, but discount deduction amount of PLP instead
    _vaultStorage.payTraderProfit(_subAccount, _tpToken, _tpTokenOut, _settlementFee);

    // @todo - emit LogSettleProfit(trader, collateralToken, addedAmount, settlementFee)
  }

  /// @notice settle loss
  /// @param _subAccount - Sub-account of trader
  /// @param _debtUsd - Loss in USD
  function _settleLoss(address _subAccount, uint256 _debtUsd) internal {
    // SLOAD
    ConfigStorage _configStorage = ConfigStorage(configStorage);
    VaultStorage _vaultStorage = VaultStorage(vaultStorage);
    OracleMiddleware _oracleMiddleware = OracleMiddleware(_configStorage.oracle());
    address[] memory _plpTokens = _configStorage.getPlpTokens();

    uint256 _len = _plpTokens.length;

    SettleLossVars memory _vars;

    // Loop through all the plp tokens for the sub-account
    for (uint256 _i; _i < _len; ) {
      address _token = _plpTokens[_i];

      _vars.decimals = _configStorage.getAssetTokenDecimal(_token);

      // Sub-account plp collateral
      _vars.collateral = _vaultStorage.traderBalances(_subAccount, _token);

      // continue settle when sub-account has collateral, else go to check next token
      if (_vars.collateral != 0) {
        _vars.tokenAssetId = _configStorage.tokenAssetIds(_token);

        // Retrieve the latest price and confident threshold of the plp underlying token
        (_vars.price, ) = _oracleMiddleware.getLatestPrice(_vars.tokenAssetId, false);

        _vars.collateralUsd = (_vars.collateral * _vars.price) / (10 ** _vars.decimals);

        if (_vars.collateralUsd >= _debtUsd) {
          // When this collateral token can cover all the debt, use this token to pay it all
          _vars.collateralToRemove = (_debtUsd * (10 ** _vars.decimals)) / _vars.price;

          _vaultStorage.payPlp(_subAccount, _token, _vars.collateralToRemove);
          // @todo - emit LogSettleLoss(trader, collateralToken, deductedAmount)
          // In this case, all debt are paid. We can break the loop right away.
          break;
        } else {
          // When this collateral token cannot cover all the debt, use this token to pay debt as much as possible
          _vars.collateralToRemove = (_vars.collateralUsd * (10 ** _vars.decimals)) / _vars.price;

          _vaultStorage.payPlp(_subAccount, _token, _vars.collateralToRemove);
          // @todo - emit LogSettleLoss(trader, collateralToken, deductedAmount)
          // update debtUsd
          unchecked {
            _debtUsd = _debtUsd - _vars.collateralUsd;
          }
        }
      }

      unchecked {
        ++_i;
      }
    }
  }

  /**
   * Internal functions
   */

  // @todo - add description
  function _getSubAccount(address _primary, uint8 _subAccountId) internal pure returns (address) {
    if (_subAccountId > 255) revert();
    return address(uint160(_primary) ^ uint160(_subAccountId));
  }

  // @todo - add description
  function _getPositionId(address _account, uint256 _marketIndex) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account, _marketIndex));
  }

  /// @notice Calculates the next average price of a position, given the current position details and the next price.
  /// @param _size The current size of the position.
  /// @param _isLong Whether the position is long or short.
  /// @param _sizeDelta The size difference between the current position and the next position.
  /// @param _markPrice current market price
  /// @param _closePrice the adaptive price of this market if this position is fully closed. This is used to correctly calculate position pnl.
  /// @param _averagePrice The current average price of the position.
  /// @return The next average price of the position.
  function _getPositionNextAveragePrice(
    uint256 _size,
    bool _isLong,
    uint256 _sizeDelta,
    uint256 _markPrice,
    uint256 _closePrice,
    uint256 _averagePrice,
    uint256 _lastIncreaseTimestamp
  ) internal view returns (uint256) {
    // Get the delta and isProfit value from the _getDelta function
    (bool isProfit, uint256 delta) = calculator.getDelta(
      _size,
      _isLong,
      _closePrice,
      _averagePrice,
      _lastIncreaseTimestamp
    );

    // Calculate the next size and divisor
    uint256 nextSize = _size + _sizeDelta;
    uint256 divisor;
    if (_isLong) {
      divisor = isProfit ? nextSize + delta : nextSize - delta;
    } else {
      divisor = isProfit ? nextSize - delta : nextSize + delta;
    }

    // Calculate the next average price of the position
    return (_markPrice * nextSize) / divisor;
  }

  /// @notice Calculates the next average price of a position, after decrease position
  /// @param _marketSkew market skew of market before decrease
  /// @param _positionSize position size. positive number for Long position and negative for Short
  /// @param _sizeToDecrease size to decrease. positive number for Long position and negative for Short
  /// @param _unrealizedPnl delta - realized pnl
  /// @param _priceE30 oracle price
  /// @param _maxSkewScale - max skew scale
  /// @return _newAveragePrice
  function _getNewAvgPriceAfterDecrease(
    int256 _marketSkew,
    int256 _positionSize,
    int256 _sizeToDecrease,
    int256 _unrealizedPnl,
    uint256 _priceE30,
    uint256 _maxSkewScale
  ) internal pure returns (uint256 _newAveragePrice) {
    // premium before       = market skew - size delta / max scale skew
    // premium after        = market skew - position size / max scale skew
    // premium              = (premium after + premium after) / 2
    // new close price      = 100 * (1 + premium)
    // remaining size       = position size - size delta
    // new avg price        = (new close price * remaining size) / (remaining size + unrealized pnl)

    // Example:
    // Given
    //    - max scale       = 1000000 USD
    //    - market skew     = 2000 USD
    //    - price           = 100 USD
    //    - position size   = 1000 USD
    //    - decrease size   = 300 USD
    //    - remaining size  = 500 USD
    //    - entry price     = 100.05 USD
    //    - close price     = 100.15 USD
    //    - pnl             = 1000 * (100.15 - 100.05) / 100.05 = 0.999500249875062468765617191404 USD
    //    - reliazed pnl    = 300 * (100.15 - 100.05) / 100.05 = 0.299850074962518740629685157421 USD
    //    - unrealized pnl  = 0.999500249875062468765617191404 - 0.299850074962518740629685157421
    //                      = 0.699650174912543728135932033983
    // Then
    //    - premium before      = 2000 - 300 = 1700 / 1000000 = 0.0017
    //    - premium after       = 2000 - 1000 = 1000 / 1000000 = 0.001
    //    - new premium         = 0.0017 + 0.001 = 0.0027 / 2 = 0.00135
    //    - price with premium  = 100 * (1 + 0.00135) = 100.135 USD
    //    - new avg price       = (100.135 * 700) / (700 + 0.699650174912543728135932033983)
    //                          = 100.035014977533699450823764353469 USD

    int256 _premiumBefore = ((_marketSkew - _sizeToDecrease) * 1e30) / int256(_maxSkewScale);
    int256 _premiumAfter = ((_marketSkew - _positionSize) * 1e30) / int256(_maxSkewScale);

    int256 _premium = (_premiumBefore + _premiumAfter) / 2;

    uint256 _priceWithPremium;
    if (_premium > 0) {
      _priceWithPremium = (_priceE30 * (1e30 + uint256(_premium))) / 1e30;
    } else {
      _priceWithPremium = (_priceE30 * (1e30 - uint256(-_premium))) / 1e30;
    }

    int256 _remainingSize = _positionSize - _sizeToDecrease;
    return uint256((int256(_priceWithPremium) * _remainingSize) / (_remainingSize + _unrealizedPnl));
  }

  /// @notice This function increases the reserve value
  /// @param _assetClassIndex The index of asset class.
  /// @param _reservedValue The amount by which to increase the reserve value.
  function _increaseReserved(uint8 _assetClassIndex, uint256 _reservedValue) internal {
    // SLOAD
    PerpStorage _perpStorage = PerpStorage(perpStorage);

    // Get the total TVL
    uint256 tvl = calculator.getPLPValueE30(true);

    // Retrieve the global state
    PerpStorage.GlobalState memory _globalState = _perpStorage.getGlobalState();

    // Retrieve the global asset class
    PerpStorage.GlobalAssetClass memory _globalAssetClass = _perpStorage.getGlobalAssetClassByIndex(_assetClassIndex);

    // get the liquidity configuration
    ConfigStorage.LiquidityConfig memory _liquidityConfig = ConfigStorage(configStorage).getLiquidityConfig();

    // Increase the reserve value by adding the reservedValue
    _globalState.reserveValueE30 += _reservedValue;
    _globalAssetClass.reserveValueE30 += _reservedValue;

    // Check if the new reserve value exceeds the % of AUM, and revert if it does
    if ((tvl * _liquidityConfig.maxPLPUtilizationBPS) < _globalState.reserveValueE30 * BPS) {
      revert ITradeService_InsufficientLiquidity();
    }

    // Update the new reserve value in the PerpStorage contract
    _perpStorage.updateGlobalState(_globalState);
    _perpStorage.updateGlobalAssetClass(_assetClassIndex, _globalAssetClass);
  }

  /// @notice health check for sub account that equity > margin maintenance required
  /// @param _subAccount target sub account for health check
  /// @param _limitPriceE30 Price to be overwritten to a specified asset
  /// @param _limitAssetId Asset to be overwritten by _limitPriceE30
  function _subAccountHealthCheck(address _subAccount, uint256 _limitPriceE30, bytes32 _limitAssetId) internal view {
    // check sub account is healthy
    int256 _subAccountEquity = calculator.getEquity(_subAccount, _limitPriceE30, _limitAssetId);

    // maintenance margin requirement (MMR) = position size * maintenance margin fraction
    // note: maintenanceMarginFractionBPS is 1e4
    uint256 _mmr = calculator.getMMR(_subAccount);

    // if sub account equity < MMR, then trader couldn't decrease position
    if (_subAccountEquity < 0 || uint256(_subAccountEquity) < _mmr) revert ITradeService_SubAccountEquityIsUnderMMR();
  }

  function _increasePositionHooks(
    address _primaryAccount,
    uint256 _subAccountId,
    uint256 _marketIndex,
    uint256 _sizeDelta
  ) internal {
    address[] memory _hooks = ConfigStorage(configStorage).getTradeServiceHooks();
    for (uint256 i; i < _hooks.length; ) {
      ITradeServiceHook(_hooks[i]).onIncreasePosition(_primaryAccount, _subAccountId, _marketIndex, _sizeDelta, "");
      unchecked {
        ++i;
      }
    }
  }

  function _decreasePositionHooks(
    address _primaryAccount,
    uint256 _subAccountId,
    uint256 _marketIndex,
    uint256 _sizeDelta
  ) internal {
    address[] memory _hooks = ConfigStorage(configStorage).getTradeServiceHooks();
    for (uint256 i; i < _hooks.length; ) {
      ITradeServiceHook(_hooks[i]).onDecreasePosition(_primaryAccount, _subAccountId, _marketIndex, _sizeDelta, "");
      unchecked {
        ++i;
      }
    }
  }

  /**
   * Maths
   */
  function abs(int256 x) private pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }

  /**
   * Setter
   */
  /// @notice Set new ConfigStorage contract address.
  /// @param _configStorage New ConfigStorage contract address.
  function setConfigStorage(address _configStorage) external nonReentrant onlyOwner {
    if (_configStorage == address(0)) revert ITradeService_InvalidAddress();
    emit LogSetConfigStorage(configStorage, _configStorage);
    configStorage = _configStorage;

    // Sanity check
    ConfigStorage(_configStorage).calculator();
  }

  /// @notice Set new VaultStorage contract address.
  /// @param _vaultStorage New VaultStorage contract address.
  function setVaultStorage(address _vaultStorage) external nonReentrant onlyOwner {
    if (_vaultStorage == address(0)) revert ITradeService_InvalidAddress();

    emit LogSetVaultStorage(vaultStorage, _vaultStorage);
    vaultStorage = _vaultStorage;

    // Sanity check
    VaultStorage(_vaultStorage).devFees(address(0));
  }

  /// @notice Set new PerpStorage contract address.
  /// @param _perpStorage New PerpStorage contract address.
  function setPerpStorage(address _perpStorage) external nonReentrant onlyOwner {
    if (_perpStorage == address(0)) revert ITradeService_InvalidAddress();

    emit LogSetPerpStorage(perpStorage, _perpStorage);
    perpStorage = _perpStorage;

    // Sanity check
    PerpStorage(_perpStorage).getGlobalState();
  }

  /// @notice Set new Calculator contract address.
  /// @param _calculator New Calculator contract address.
  function setCalculator(address _calculator) external nonReentrant onlyOwner {
    if (_calculator == address(0)) revert ITradeService_InvalidAddress();

    emit LogSetCalculator(address(calculator), _calculator);
    calculator = Calculator(_calculator);

    // Sanity check
    Calculator(_calculator).oracle();
  }

  /// @notice Set new TradeHelper contract address.
  /// @param _tradeHelper New TradeHelper contract address.
  function setTradeHelper(address _tradeHelper) external nonReentrant onlyOwner {
    if (_tradeHelper == address(0)) revert ITradeService_InvalidAddress();

    emit LogSetTradeHelper(tradeHelper, _tradeHelper);
    tradeHelper = _tradeHelper;

    // Sanity check
    TradeHelper(_tradeHelper).perpStorage();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ITradeService {
  /**
   * Errors
   */
  error ITradeService_MarketIsDelisted();
  error ITradeService_MarketIsClosed();
  error ITradeService_PositionAlreadyClosed();
  error ITradeService_DecreaseTooHighPositionSize();
  error ITradeService_SubAccountEquityIsUnderMMR();
  error ITradeService_TooTinyPosition();
  error ITradeService_BadSubAccountId();
  error ITradeService_BadSizeDelta();
  error ITradeService_NotAllowIncrease();
  error ITradeService_BadNumberOfPosition();
  error ITradeService_BadExposure();
  error ITradeService_InvalidAveragePrice();
  error ITradeService_BadPositionSize();
  error ITradeService_InsufficientLiquidity();
  error ITradeService_InsufficientFreeCollateral();
  error ITradeService_ReservedValueStillEnough();
  error ITradeService_PlpHealthy();
  error ITradeService_MarketHealthy();
  error ITradeService_InvalidAddress();

  /**
   * STRUCTS
   */

  function configStorage() external view returns (address);

  function perpStorage() external view returns (address);

  function vaultStorage() external view returns (address);

  function reloadConfig() external;

  function increasePosition(
    address _primaryAccount,
    uint8 _subAccountId,
    uint256 _marketIndex,
    int256 _sizeDelta,
    uint256 _limitPriceE30
  ) external;

  function decreasePosition(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    uint256 _positionSizeE30ToDecrease,
    address _tpToken,
    uint256 _limitPriceE30
  ) external;

  function forceClosePosition(
    address _account,
    uint8 _subAccountId,
    uint256 _marketIndex,
    address _tpToken
  ) external returns (bool _isMaxProfit, bool _isProfit, uint256 _delta);

  function validateMaxProfit(bool isMaxProfit) external view;

  function validateDeleverage() external view;

  function validateMarketDelisted(uint256 _marketIndex) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ITradeServiceHook {
  /**
   * Errors
   */

  /**
   * Core Functions
   */
  function onIncreasePosition(
    address primaryAccount,
    uint256 subAccountId,
    uint256 marketIndex,
    uint256 sizeDelta,
    bytes32 data
  ) external;

  function onDecreasePosition(
    address primaryAccount,
    uint256 subAccountId,
    uint256 marketIndex,
    uint256 sizeDelta,
    bytes32 data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

//base
import { Owned } from "@hmx/base/Owned.sol";
import { IteratableAddressList } from "@hmx/libraries/IteratableAddressList.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// interfaces
import { IConfigStorage } from "./interfaces/IConfigStorage.sol";

/// @title ConfigStorage
/// @notice storage contract to keep configs
contract ConfigStorage is IConfigStorage, Owned {
  using IteratableAddressList for IteratableAddressList.List;
  using SafeERC20 for ERC20;

  /**
   * Events
   */
  event LogSetServiceExecutor(address indexed contractAddress, address executorAddress, bool isServiceExecutor);
  event LogSetCalculator(address indexed oldCalculator, address newCalculator);
  event LogSetOracle(address indexed oldOracle, address newOracle);
  event LogSetPLP(address indexed oldPlp, address newPlp);
  event LogSetLiquidityConfig(LiquidityConfig indexed oldLiquidityConfig, LiquidityConfig newLiquidityConfig);
  event LogSetDynamicEnabled(bool enabled);
  event LogSetPnlFactor(uint32 oldPnlFactorBPS, uint32 newPnlFactorBPS);
  event LogSetSwapConfig(SwapConfig indexed oldConfig, SwapConfig newConfig);
  event LogSetTradingConfig(TradingConfig indexed oldConfig, TradingConfig newConfig);
  event LogSetLiquidationConfig(LiquidationConfig indexed oldConfig, LiquidationConfig newConfig);
  event LogSetMarketConfig(uint256 marketIndex, MarketConfig oldConfig, MarketConfig newConfig);
  event LogSetPlpTokenConfig(address token, PLPTokenConfig oldConfig, PLPTokenConfig newConfig);
  event LogSetCollateralTokenConfig(bytes32 assetId, CollateralTokenConfig oldConfig, CollateralTokenConfig newConfig);
  event LogSetAssetConfig(bytes32 assetId, AssetConfig oldConfig, AssetConfig newConfig);
  event LogSetWeth(address indexed oldWeth, address newWeth);
  event LogSetAssetClassConfigByIndex(uint256 index, AssetClassConfig oldConfig, AssetClassConfig newConfig);
  event LogAddAssetClassConfig(uint256 index, AssetClassConfig newConfig);
  event LogAddMarketConfig(uint256 index, MarketConfig newConfig);
  event LogRemoveUnderlying(address token);
  event LogDelistMarket(uint256 marketIndex);
  event LogSetLiquidityEnabled(bool _enabled);
  event LogAddOrUpdatePLPTokenConfigs(address _token, PLPTokenConfig _config, PLPTokenConfig _newConfig);

  /**
   * Constants
   */
  address public constant ITERABLE_ADDRESS_LIST_START = address(1);
  address public constant ITERABLE_ADDRESS_LIST_END = address(1);

  /**
   * States
   */
  LiquidityConfig public liquidityConfig;
  SwapConfig public swapConfig;
  TradingConfig public tradingConfig;
  LiquidationConfig public liquidationConfig;

  mapping(address => bool) public allowedLiquidators; // allowed contract to execute liquidation service
  mapping(address => mapping(address => bool)) public serviceExecutors; // service => handler => isOK, to allowed executor for service layer

  address public calculator;
  address public oracle;
  address public plp;
  address public treasury;
  uint32 public pnlFactorBPS; // factor that calculate unrealized PnL after collateral factor
  address public weth;

  // Token's address => Asset ID
  mapping(address => bytes32) public tokenAssetIds;
  // Asset ID => Configs
  mapping(bytes32 => AssetConfig) public assetConfigs;
  // PLP stuff
  bytes32[] public plpAssetIds;
  mapping(bytes32 => PLPTokenConfig) public assetPlpTokenConfigs;
  // Cross margin
  bytes32[] public collateralAssetIds;
  mapping(bytes32 => CollateralTokenConfig) public assetCollateralTokenConfigs;
  // Trade
  MarketConfig[] public marketConfigs;
  AssetClassConfig[] public assetClassConfigs;
  address[] public tradeServiceHooks;

  constructor() {}

  /**
   * Validation
   */

  /// @notice Validate only whitelisted executor contracts to be able to call Service contracts.
  /// @param _contractAddress Service contract address to be executed.
  /// @param _executorAddress Executor contract address to call service contract.
  function validateServiceExecutor(address _contractAddress, address _executorAddress) external view {
    if (!serviceExecutors[_contractAddress][_executorAddress]) revert IConfigStorage_NotWhiteListed();
  }

  function validateAcceptedLiquidityToken(address _token) external view {
    if (!assetPlpTokenConfigs[tokenAssetIds[_token]].accepted) revert IConfigStorage_NotAcceptedLiquidity();
  }

  /// @notice Validate only accepted token to be deposit/withdraw as collateral token.
  /// @param _token Token address to be deposit/withdraw.
  function validateAcceptedCollateral(address _token) external view {
    if (!assetCollateralTokenConfigs[tokenAssetIds[_token]].accepted) revert IConfigStorage_NotAcceptedCollateral();
  }

  /**
   * Getter
   */

  function getMarketConfigById(uint256 _marketIndex) external view returns (MarketConfig memory _marketConfig) {
    return marketConfigs[_marketIndex];
  }

  function getTradingConfig() external view returns (TradingConfig memory) {
    return tradingConfig;
  }

  function getMarketConfigByIndex(uint256 _index) external view returns (MarketConfig memory _marketConfig) {
    return marketConfigs[_index];
  }

  function getAssetClassConfigByIndex(
    uint256 _index
  ) external view returns (AssetClassConfig memory _assetClassConfig) {
    return assetClassConfigs[_index];
  }

  function getCollateralTokenConfigs(
    address _token
  ) external view returns (CollateralTokenConfig memory _collateralTokenConfig) {
    return assetCollateralTokenConfigs[tokenAssetIds[_token]];
  }

  function getAssetTokenDecimal(address _token) external view returns (uint8) {
    return assetConfigs[tokenAssetIds[_token]].decimals;
  }

  function getLiquidityConfig() external view returns (LiquidityConfig memory) {
    return liquidityConfig;
  }

  function getLiquidationConfig() external view returns (LiquidationConfig memory) {
    return liquidationConfig;
  }

  function getMarketConfigsLength() external view returns (uint256) {
    return marketConfigs.length;
  }

  function getAssetClassConfigsLength() external view returns (uint256) {
    return assetClassConfigs.length;
  }

  function getPlpTokens() external view returns (address[] memory) {
    address[] memory _result = new address[](plpAssetIds.length);

    for (uint256 _i = 0; _i < plpAssetIds.length; ) {
      _result[_i] = assetConfigs[plpAssetIds[_i]].tokenAddress;
      unchecked {
        ++_i;
      }
    }

    return _result;
  }

  function getAssetConfigByToken(address _token) external view returns (AssetConfig memory) {
    return assetConfigs[tokenAssetIds[_token]];
  }

  function getCollateralTokens() external view returns (address[] memory) {
    bytes32[] memory _collateralAssetIds = collateralAssetIds;
    mapping(bytes32 => AssetConfig) storage _assetConfigs = assetConfigs;

    uint256 _len = _collateralAssetIds.length;
    address[] memory tokenAddresses = new address[](_len);

    for (uint256 _i; _i < _len; ) {
      tokenAddresses[_i] = _assetConfigs[_collateralAssetIds[_i]].tokenAddress;

      unchecked {
        ++_i;
      }
    }
    return tokenAddresses;
  }

  function getAssetConfig(bytes32 _assetId) external view returns (AssetConfig memory) {
    return assetConfigs[_assetId];
  }

  function getAssetPlpTokenConfig(bytes32 _assetId) external view returns (PLPTokenConfig memory) {
    return assetPlpTokenConfigs[_assetId];
  }

  function getAssetPlpTokenConfigByToken(address _token) external view returns (PLPTokenConfig memory) {
    return assetPlpTokenConfigs[tokenAssetIds[_token]];
  }

  function getPlpAssetIds() external view returns (bytes32[] memory) {
    return plpAssetIds;
  }

  function getTradeServiceHooks() external view returns (address[] memory) {
    return tradeServiceHooks;
  }

  /**
   * Setter
   */

  function setPlpAssetId(bytes32[] memory _plpAssetIds) external onlyOwner {
    plpAssetIds = _plpAssetIds;
  }

  function setCalculator(address _calculator) external onlyOwner {
    emit LogSetCalculator(calculator, _calculator);
    // @todo - add sanity check
    calculator = _calculator;
  }

  function setOracle(address _oracle) external onlyOwner {
    emit LogSetOracle(oracle, _oracle);
    // @todo - sanity check
    oracle = _oracle;
  }

  function setPLP(address _plp) external onlyOwner {
    emit LogSetPLP(plp, _plp);
    // @todo - sanity check
    plp = _plp;
  }

  function setLiquidityConfig(LiquidityConfig memory _liquidityConfig) external onlyOwner {
    emit LogSetLiquidityConfig(liquidityConfig, _liquidityConfig);
    // @todo - sanity check
    liquidityConfig = _liquidityConfig;
  }

  function setLiquidityEnabled(bool _enabled) external {
    liquidityConfig.enabled = _enabled;
    emit LogSetLiquidityEnabled(_enabled);
  }

  function setDynamicEnabled(bool _enabled) external {
    liquidityConfig.dynamicFeeEnabled = _enabled;
    emit LogSetDynamicEnabled(_enabled);
  }

  // @todo - Add Description
  function setServiceExecutor(
    address _contractAddress,
    address _executorAddress,
    bool _isServiceExecutor
  ) external onlyOwner {
    serviceExecutors[_contractAddress][_executorAddress] = _isServiceExecutor;

    emit LogSetServiceExecutor(_contractAddress, _executorAddress, _isServiceExecutor);
  }

  function setPnlFactor(uint32 _pnlFactorBPS) external onlyOwner {
    emit LogSetPnlFactor(pnlFactorBPS, _pnlFactorBPS);
    pnlFactorBPS = _pnlFactorBPS;
  }

  function setSwapConfig(SwapConfig memory _newConfig) external onlyOwner {
    emit LogSetSwapConfig(swapConfig, _newConfig);
    swapConfig = _newConfig;
  }

  function setTradingConfig(TradingConfig memory _newConfig) external onlyOwner {
    emit LogSetTradingConfig(tradingConfig, _newConfig);
    tradingConfig = _newConfig;
  }

  function setLiquidationConfig(LiquidationConfig memory _newConfig) external onlyOwner {
    emit LogSetLiquidationConfig(liquidationConfig, _newConfig);
    liquidationConfig = _newConfig;
  }

  function setMarketConfig(
    uint256 _marketIndex,
    MarketConfig memory _newConfig
  ) external onlyOwner returns (MarketConfig memory _marketConfig) {
    emit LogSetMarketConfig(_marketIndex, marketConfigs[_marketIndex], _newConfig);
    marketConfigs[_marketIndex] = _newConfig;
    return marketConfigs[_marketIndex];
  }

  function setPlpTokenConfig(
    address _token,
    PLPTokenConfig memory _newConfig
  ) external onlyOwner returns (PLPTokenConfig memory _plpTokenConfig) {
    emit LogSetPlpTokenConfig(_token, assetPlpTokenConfigs[tokenAssetIds[_token]], _newConfig);
    assetPlpTokenConfigs[tokenAssetIds[_token]] = _newConfig;
    return _newConfig;
  }

  function setCollateralTokenConfig(
    bytes32 _assetId,
    CollateralTokenConfig memory _newConfig
  ) external onlyOwner returns (CollateralTokenConfig memory _collateralTokenConfig) {
    emit LogSetCollateralTokenConfig(_assetId, assetCollateralTokenConfigs[_assetId], _newConfig);
    assetCollateralTokenConfigs[_assetId] = _newConfig;
    collateralAssetIds.push(_assetId);
    return assetCollateralTokenConfigs[_assetId];
  }

  function setAssetConfig(
    bytes32 _assetId,
    AssetConfig memory _newConfig
  ) external onlyOwner returns (AssetConfig memory _assetConfig) {
    emit LogSetAssetConfig(_assetId, assetConfigs[_assetId], _newConfig);
    assetConfigs[_assetId] = _newConfig;
    address _token = _newConfig.tokenAddress;

    if (_token != address(0)) {
      tokenAssetIds[_token] = _assetId;

      // sanity check
      ERC20(_token).decimals();
    }

    return assetConfigs[_assetId];
  }

  function setWeth(address _weth) external onlyOwner {
    emit LogSetWeth(weth, _weth);
    weth = _weth;
  }

  /// @notice add or update AcceptedToken
  /// @dev This function only allows to add new token or update existing token,
  /// any attempt to remove token will be reverted.
  /// @param _tokens The token addresses to set.
  /// @param _configs The token configs to set.
  function addOrUpdateAcceptedToken(address[] calldata _tokens, PLPTokenConfig[] calldata _configs) external onlyOwner {
    if (_tokens.length != _configs.length) {
      revert IConfigStorage_BadLen();
    }

    uint256 _tokenLen = _tokens.length;
    for (uint256 _i; _i < _tokenLen; ) {
      bytes32 _assetId = tokenAssetIds[_tokens[_i]];

      uint256 _assetIdLen = plpAssetIds.length;

      bool _isSetPLPAssetId = true;

      for (uint256 _j; _j < _assetIdLen; ) {
        if (plpAssetIds[_j] == _assetId) {
          _isSetPLPAssetId = false;
        }
        unchecked {
          ++_j;
        }
      }

      // Adjust plpTotalToken Weight
      if (liquidityConfig.plpTotalTokenWeight == 0) {
        liquidityConfig.plpTotalTokenWeight = _configs[_i].targetWeight;
      } else {
        liquidityConfig.plpTotalTokenWeight =
          (liquidityConfig.plpTotalTokenWeight - assetPlpTokenConfigs[_assetId].targetWeight) +
          _configs[_i].targetWeight;
      }

      if (liquidityConfig.plpTotalTokenWeight > 1e18) {
        revert IConfigStorage_ExceedLimitSetting();
      }

      // put asset ID after add totalWeight
      if (_isSetPLPAssetId) {
        plpAssetIds.push(_assetId);
      }

      assetPlpTokenConfigs[_assetId] = _configs[_i];
      emit LogAddOrUpdatePLPTokenConfigs(_tokens[_i], assetPlpTokenConfigs[_assetId], _configs[_i]);

      // Update totalWeight accordingly

      unchecked {
        ++_i;
      }
    }
  }

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external onlyOwner returns (uint256 _index) {
    uint256 _newAssetClassIndex = assetClassConfigs.length;
    assetClassConfigs.push(_newConfig);
    emit LogAddAssetClassConfig(_newAssetClassIndex, _newConfig);
    return _newAssetClassIndex;
  }

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external onlyOwner {
    emit LogSetAssetClassConfigByIndex(_index, assetClassConfigs[_index], _newConfig);
    assetClassConfigs[_index] = _newConfig;
  }

  function addMarketConfig(MarketConfig calldata _newConfig) external onlyOwner returns (uint256 _index) {
    uint256 _newMarketIndex = marketConfigs.length;
    marketConfigs.push(_newConfig);
    emit LogAddMarketConfig(_newMarketIndex, _newConfig);
    return _newMarketIndex;
  }

  function delistMarket(uint256 _marketIndex) external onlyOwner {
    emit LogDelistMarket(_marketIndex);
    delete marketConfigs[_marketIndex].active;
  }

  /// @notice Remove underlying token.
  /// @param _token The token address to remove.
  function removeAcceptedToken(address _token) external onlyOwner {
    bytes32 _assetId = tokenAssetIds[_token];

    // Update totalTokenWeight
    liquidityConfig.plpTotalTokenWeight -= assetPlpTokenConfigs[_assetId].targetWeight;

    // delete from plpAssetIds
    uint256 _len = plpAssetIds.length;
    for (uint256 _i = 0; _i < _len; ) {
      if (_assetId == plpAssetIds[_i]) {
        delete plpAssetIds[_i];
        break;
      }

      unchecked {
        ++_i;
      }
    }
    // Delete plpTokenConfig
    delete assetPlpTokenConfigs[_assetId];

    emit LogRemoveUnderlying(_token);
  }

  function setTradeServiceHooks(address[] calldata _newHooks) external onlyOwner {
    tradeServiceHooks = _newHooks;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// interfaces
import { IPerpStorage } from "./interfaces/IPerpStorage.sol";

import { Owned } from "@hmx/base/Owned.sol";

/// @title PerpStorage
/// @notice storage contract to keep core feature state
contract PerpStorage is Owned, ReentrancyGuard, IPerpStorage {
  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    if (!serviceExecutors[msg.sender]) revert IPerpStorage_NotWhiteListed();
    _;
  }

  /**
   * Events
   */
  event SetServiceExecutor(address indexed executorAddress, bool isServiceExecutor);

  /**
   * States
   */
  GlobalState public globalState; // global state that accumulative value from all markets

  mapping(bytes32 => Position) public positions;
  mapping(address => bytes32[]) public subAccountPositionIds;
  mapping(address => uint256) public subAccountBorrowingFee;
  mapping(address => uint256) public badDebt;
  mapping(uint256 => GlobalMarket) public globalMarkets;
  mapping(uint256 => GlobalAssetClass) public globalAssetClass;
  mapping(address => bool) public serviceExecutors;

  /**
   * Getter
   */

  /// @notice Get all positions with a specific trader's sub-account
  /// @param _trader The address of the trader whose positions to retrieve
  /// @return traderPositions An array of Position objects representing the trader's positions
  function getPositionBySubAccount(address _trader) external view returns (Position[] memory traderPositions) {
    bytes32[] memory _positionIds = subAccountPositionIds[_trader];
    if (_positionIds.length > 0) {
      Position[] memory _traderPositions = new Position[](_positionIds.length);
      uint256 _len = _positionIds.length;
      for (uint256 i; i < _len; ) {
        _traderPositions[i] = (positions[_positionIds[i]]);

        unchecked {
          i++;
        }
      }

      return _traderPositions;
    }
  }

  function getPositionIds(address _subAccount) external view returns (bytes32[] memory _positionIds) {
    return subAccountPositionIds[_subAccount];
  }

  // @todo - add description
  function getPositionById(bytes32 _positionId) external view returns (Position memory) {
    return positions[_positionId];
  }

  function getNumberOfSubAccountPosition(address _subAccount) external view returns (uint256) {
    return subAccountPositionIds[_subAccount].length;
  }

  // todo: add description
  // todo: support to update borrowing rate
  // todo: support to update funding rate
  function getGlobalMarketByIndex(uint256 _marketIndex) external view returns (GlobalMarket memory) {
    return globalMarkets[_marketIndex];
  }

  function getGlobalAssetClassByIndex(uint256 _assetClassIndex) external view returns (GlobalAssetClass memory) {
    return globalAssetClass[_assetClassIndex];
  }

  function getGlobalState() external view returns (GlobalState memory) {
    return globalState;
  }

  /// @notice Gets the bad debt associated with the given sub-account.
  /// @param subAccount The address of the sub-account to get the bad debt for.
  /// @return _badDebt The bad debt associated with the given sub-account.
  function getBadDebt(address subAccount) external view returns (uint256 _badDebt) {
    return badDebt[subAccount];
  }

  /**
   * Setter
   */

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external onlyOwner nonReentrant {
    serviceExecutors[_executorAddress] = _isServiceExecutor;
    emit SetServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function savePosition(
    address _subAccount,
    bytes32 _positionId,
    Position calldata position
  ) external nonReentrant onlyWhitelistedExecutor {
    IPerpStorage.Position memory _position = positions[_positionId];
    // register new position for trader's sub-account
    if (_position.positionSizeE30 == 0) {
      subAccountPositionIds[_subAccount].push(_positionId);
    }
    positions[_positionId] = position;
  }

  /// @notice Resets the position associated with the given position ID.
  /// @param _subAccount The sub account of the position.
  /// @param _positionId The ID of the position to be reset.
  function removePositionFromSubAccount(address _subAccount, bytes32 _positionId) external onlyWhitelistedExecutor {
    bytes32[] storage _positionIds = subAccountPositionIds[_subAccount];
    uint256 _len = _positionIds.length;
    for (uint256 _i; _i < _len; ) {
      if (_positionIds[_i] == _positionId) {
        _positionIds[_i] = _positionIds[_len - 1];
        _positionIds.pop();
        delete positions[_positionId];

        break;
      }

      unchecked {
        ++_i;
      }
    }
  }

  // @todo - update funding rate
  function updateGlobalLongMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAvgPrice
  ) external onlyWhitelistedExecutor {
    globalMarkets[_marketIndex].longPositionSize = _newPositionSize;
    globalMarkets[_marketIndex].longAvgPrice = _newAvgPrice;
  }

  // @todo - update funding rate
  function updateGlobalShortMarketById(
    uint256 _marketIndex,
    uint256 _newPositionSize,
    uint256 _newAvgPrice
  ) external onlyWhitelistedExecutor {
    globalMarkets[_marketIndex].shortPositionSize = _newPositionSize;
    globalMarkets[_marketIndex].shortAvgPrice = _newAvgPrice;
  }

  function updateGlobalState(GlobalState memory _newGlobalState) external onlyWhitelistedExecutor {
    globalState = _newGlobalState;
  }

  function updateGlobalAssetClass(
    uint8 _assetClassIndex,
    GlobalAssetClass memory _newAssetClass
  ) external onlyWhitelistedExecutor {
    globalAssetClass[_assetClassIndex] = _newAssetClass;
  }

  function updateGlobalMarket(
    uint256 _marketIndex,
    GlobalMarket memory _globalMarket
  ) external onlyWhitelistedExecutor {
    globalMarkets[_marketIndex] = _globalMarket;
  }

  function increaseSubAccountBorrowingFee(address _subAccount, uint256 _borrowingFee) external onlyWhitelistedExecutor {
    subAccountBorrowingFee[_subAccount] += _borrowingFee;
  }

  function decreaseSubAccountBorrowingFee(address _subAccount, uint256 _borrowingFee) external onlyWhitelistedExecutor {
    // Maximum decrease the current amount
    if (subAccountBorrowingFee[_subAccount] < _borrowingFee) {
      subAccountBorrowingFee[_subAccount] = 0;
      return;
    }

    subAccountBorrowingFee[_subAccount] -= _borrowingFee;
  }

  /// @notice Adds bad debt to the specified sub-account.
  /// @param _subAccount The address of the sub-account to add bad debt to.
  /// @param _badDebt The amount of bad debt to add to the sub-account.
  function addBadDebt(address _subAccount, uint256 _badDebt) external onlyWhitelistedExecutor {
    // Add the bad debt to the sub-account
    badDebt[_subAccount] += _badDebt;
  }

  function increaseReserved(uint8 _assetClassIndex, uint256 _reserve) external onlyWhitelistedExecutor {
    globalState.reserveValueE30 += _reserve;
    globalAssetClass[_assetClassIndex].reserveValueE30 += _reserve;
  }

  function decreaseReserved(uint8 _assetClassIndex, uint256 _reserve) external onlyWhitelistedExecutor {
    globalState.reserveValueE30 -= _reserve;
    globalAssetClass[_assetClassIndex].reserveValueE30 -= _reserve;
  }

  function increasePositionSize(uint256 _marketIndex, bool _isLong, uint256 _size) external {
    if (_isLong) {
      globalMarkets[_marketIndex].longPositionSize += _size;
    } else {
      globalMarkets[_marketIndex].shortPositionSize += _size;
    }
  }

  function decreasePositionSize(uint256 _marketIndex, bool _isLong, uint256 _size) external {
    if (_isLong) {
      globalMarkets[_marketIndex].longPositionSize -= _size;
    } else {
      globalMarkets[_marketIndex].shortPositionSize -= _size;
    }
  }

  function updateGlobalMarketPrice(uint256 _marketIndex, bool _isLong, uint256 _price) external {
    if (_isLong) {
      globalMarkets[_marketIndex].longAvgPrice = _price;
    } else {
      globalMarkets[_marketIndex].shortAvgPrice = _price;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interfaces
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IVaultStorage } from "./interfaces/IVaultStorage.sol";

import { Owned } from "@hmx/base/Owned.sol";

/// @title VaultStorage
/// @notice storage contract to do accounting for token, and also hold physical tokens
contract VaultStorage is Owned, ReentrancyGuard, IVaultStorage {
  using SafeERC20 for IERC20;

  /**
   * Modifiers
   */
  modifier onlyWhitelistedExecutor() {
    if (!serviceExecutors[msg.sender]) revert IVaultStorage_NotWhiteListed();
    _;
  }
  /**
   * Events
   */
  event LogSetTraderBalance(address indexed trader, address token, uint balance);
  event SetServiceExecutor(address indexed executorAddress, bool isServiceExecutor);

  /**
   * States
   */

  mapping(address => uint256) public totalAmount; //token => tokenAmount
  mapping(address => uint256) public plpLiquidity; // token => PLPTokenAmount
  mapping(address => uint256) public protocolFees; // protocol fee in token unit

  uint256 public plpLiquidityDebtUSDE30; // USD dept accounting when fundingFee is not enough to repay to trader
  mapping(address => uint256) public fundingFeeReserve; // sum of realized funding fee amount

  mapping(address => uint256) public devFees;

  // trader address (with sub-account) => token => amount
  mapping(address => mapping(address => uint256)) public traderBalances;
  // mapping(address => address[]) public traderTokens;
  mapping(address => address[]) public traderTokens;
  mapping(address => bool) public serviceExecutors;

  /**
   * VALIDATION
   */

  function validateAddTraderToken(address _trader, address _token) public view {
    address[] storage traderToken = traderTokens[_trader];

    for (uint256 i; i < traderToken.length; ) {
      if (traderToken[i] == _token) revert IVaultStorage_TraderTokenAlreadyExists();
      unchecked {
        i++;
      }
    }
  }

  function validateRemoveTraderToken(address _trader, address _token) public view {
    if (traderBalances[_trader][_token] != 0) revert IVaultStorage_TraderBalanceRemaining();
  }

  /**
   * GETTER
   */

  function getTraderTokens(address _subAccount) external view returns (address[] memory) {
    return traderTokens[_subAccount];
  }

  function pullPLPLiquidity(address _token) external view returns (uint256) {
    return IERC20(_token).balanceOf(address(this)) - plpLiquidity[_token];
  }

  /**
   * ERC20 interaction functions
   */

  function pullToken(address _token) external returns (uint256) {
    uint256 prevBalance = totalAmount[_token];
    uint256 nextBalance = IERC20(_token).balanceOf(address(this));

    totalAmount[_token] = nextBalance;
    return nextBalance - prevBalance;
  }

  function pushToken(address _token, address _to, uint256 _amount) external nonReentrant onlyWhitelistedExecutor {
    IERC20(_token).safeTransfer(_to, _amount);
    totalAmount[_token] = IERC20(_token).balanceOf(address(this));
  }

  /**
   * SETTER
   */

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external nonReentrant onlyOwner {
    serviceExecutors[_executorAddress] = _isServiceExecutor;
    emit SetServiceExecutor(_executorAddress, _isServiceExecutor);
  }

  function addFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    protocolFees[_token] += _amount;
  }

  function addFundingFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    fundingFeeReserve[_token] += _amount;
  }

  function removeFundingFee(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    fundingFeeReserve[_token] -= _amount;
  }

  function addPlpLiquidityDebtUSDE30(uint256 _value) external onlyWhitelistedExecutor {
    plpLiquidityDebtUSDE30 += _value;
  }

  function removePlpLiquidityDebtUSDE30(uint256 _value) external onlyWhitelistedExecutor {
    plpLiquidityDebtUSDE30 -= _value;
  }

  function addPLPLiquidity(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    plpLiquidity[_token] += _amount;
  }

  function withdrawFee(address _token, uint256 _amount, address _receiver) external onlyWhitelistedExecutor {
    if (_receiver == address(0)) revert IVaultStorage_ZeroAddress();
    protocolFees[_token] -= _amount;
    IERC20(_token).safeTransfer(_receiver, _amount);
  }

  function removePLPLiquidity(address _token, uint256 _amount) external onlyWhitelistedExecutor {
    if (plpLiquidity[_token] < _amount) revert IVaultStorage_PLPBalanceRemaining();
    plpLiquidity[_token] -= _amount;
  }

  function _addTraderToken(address _trader, address _token) internal onlyWhitelistedExecutor {
    validateAddTraderToken(_trader, _token);
    traderTokens[_trader].push(_token);
  }

  function _removeTraderToken(address _trader, address _token) internal {
    validateRemoveTraderToken(_trader, _token);

    address[] storage traderToken = traderTokens[_trader];
    uint256 tokenLen = traderToken.length;
    uint256 lastTokenIndex = tokenLen - 1;

    // find and deregister the token
    for (uint256 i; i < tokenLen; ) {
      if (traderToken[i] == _token) {
        // delete the token by replacing it with the last one and then pop it from there
        if (i != lastTokenIndex) {
          traderToken[i] = traderToken[lastTokenIndex];
        }
        traderToken.pop();
        break;
      }

      unchecked {
        i++;
      }
    }
  }

  // @todo - natSpec
  function removeAllTraderTokens(address _trader) external onlyWhitelistedExecutor {
    delete traderTokens[_trader];
  }

  /// @notice increase sub-account collateral
  /// @param _subAccount - sub account
  /// @param _token - collateral token to increase
  /// @param _amount - amount to increase
  function increaseTraderBalance(address _subAccount, address _token, uint256 _amount) public onlyWhitelistedExecutor {
    _increaseTraderBalance(_subAccount, _token, _amount);
  }

  /// @notice decrease sub-account collateral
  /// @param _subAccount - sub account
  /// @param _token - collateral token to increase
  /// @param _amount - amount to increase
  function decreaseTraderBalance(address _subAccount, address _token, uint256 _amount) public onlyWhitelistedExecutor {
    _deductTraderBalance(_subAccount, _token, _amount);
  }

  /// @notice Pays the PLP for providing liquidity with the specified token and amount.
  /// @param _trader The address of the trader paying the PLP.
  /// @param _token The address of the token being used to pay the PLP.
  /// @param _amount The amount of the token being used to pay the PLP.
  function payPlp(address _trader, address _token, uint256 _amount) external onlyWhitelistedExecutor {
    // Increase the PLP's liquidity for the specified token
    plpLiquidity[_token] += _amount;

    // Decrease the trader's balance for the specified token
    _deductTraderBalance(_trader, _token, _amount);
  }

  function transfer(address _token, address _from, address _to, uint256 _amount) external onlyWhitelistedExecutor {
    _deductTraderBalance(_from, _token, _amount);
    _increaseTraderBalance(_to, _token, _amount);
  }

  function payTradingFee(
    address _trader,
    address _token,
    uint256 _devFeeAmount,
    uint256 _protocolFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _devFeeAmount + _protocolFeeAmount);

    // Increase the amount to devFees and protocolFees
    devFees[_token] += _devFeeAmount;
    protocolFees[_token] += _protocolFeeAmount;
  }

  function payBorrowingFee(
    address _trader,
    address _token,
    uint256 _devFeeAmount,
    uint256 _plpFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _devFeeAmount + _plpFeeAmount);

    // Increase the amount to devFees and plpLiquidity
    devFees[_token] += _devFeeAmount;
    plpLiquidity[_token] += _plpFeeAmount;
  }

  function payFundingFeeFromTraderToPlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    _deductTraderBalance(_trader, _token, _fundingFeeAmount);

    // Increase the amount to plpLiquidity
    plpLiquidity[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromPlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from plpLiquidity
    plpLiquidity[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    _increaseTraderBalance(_trader, _token, _fundingFeeAmount);
  }

  function payTraderProfit(
    address _trader,
    address _token,
    uint256 _totalProfitAmount,
    uint256 _settlementFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from plpLiquidity
    plpLiquidity[_token] -= _totalProfitAmount;

    protocolFees[_token] += _settlementFeeAmount;
    _increaseTraderBalance(_trader, _token, _totalProfitAmount - _settlementFeeAmount);
  }

  function _increaseTraderBalance(address _trader, address _token, uint256 _amount) internal {
    if (_amount == 0) return;

    if (traderBalances[_trader][_token] == 0) {
      _addTraderToken(_trader, _token);
    }
    traderBalances[_trader][_token] += _amount;
  }

  function _deductTraderBalance(address _trader, address _token, uint256 _amount) internal {
    if (_amount == 0) return;

    traderBalances[_trader][_token] -= _amount;
    if (traderBalances[_trader][_token] == 0) {
      _removeTraderToken(_trader, _token);
    }
  }

  function convertFundingFeeReserveWithPLP(
    address _convertToken,
    address _targetToken,
    uint256 _convertAmount,
    uint256 _targetAmount
  ) external onlyWhitelistedExecutor {
    // Deduct convert token amount from funding fee reserve
    fundingFeeReserve[_convertToken] -= _convertAmount;

    // Increase convert token amount to PLP
    plpLiquidity[_convertToken] += _convertAmount;

    // Deduct target token amount from PLP
    plpLiquidity[_targetToken] -= _targetAmount;

    // Deduct convert token amount from funding fee reserve
    fundingFeeReserve[_targetToken] += _targetAmount;
  }

  function withdrawSurplusFromFundingFeeReserveToPLP(
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from funding fee reserve
    fundingFeeReserve[_token] -= _fundingFeeAmount;

    // Increase the amount to PLP
    plpLiquidity[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromTraderToFundingFeeReserve(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from trader balance
    decreaseTraderBalance(_trader, _token, _fundingFeeAmount);

    // Increase the amount to fundingFee
    fundingFeeReserve[_token] += _fundingFeeAmount;
  }

  function payFundingFeeFromFundingFeeReserveToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount
  ) external onlyWhitelistedExecutor {
    // Deduct amount from fundingFee
    fundingFeeReserve[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    increaseTraderBalance(_trader, _token, _fundingFeeAmount);
  }

  function repayFundingFeeDebtFromTraderToPlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external {
    // Deduct amount from trader balance
    decreaseTraderBalance(_trader, _token, _fundingFeeAmount);

    // Add token amounts that PLP received
    plpLiquidity[_token] += _fundingFeeAmount;

    // Remove debt value on PLP as received
    plpLiquidityDebtUSDE30 -= _fundingFeeValue;
  }

  function borrowFundingFeeFromPlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external {
    // Deduct token amounts from PLP
    plpLiquidity[_token] -= _fundingFeeAmount;

    // Increase the amount to trader
    increaseTraderBalance(_trader, _token, _fundingFeeAmount);

    // Add debt value on PLP
    plpLiquidityDebtUSDE30 += _fundingFeeValue;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IConfigStorage {
  /**
   * Errors
   */
  error IConfigStorage_NotWhiteListed();
  error IConfigStorage_ExceedLimitSetting();
  error IConfigStorage_BadLen();
  error IConfigStorage_BadArgs();
  error IConfigStorage_NotAcceptedCollateral();
  error IConfigStorage_NotAcceptedLiquidity();

  /**
   * Structs
   */
  /// @notice Asset's config
  struct AssetConfig {
    address tokenAddress;
    bytes32 assetId;
    uint8 decimals;
    bool isStableCoin; // token is stablecoin
  }

  /// @notice perp liquidity provider token config
  struct PLPTokenConfig {
    uint256 targetWeight; // percentage of all accepted PLP tokens
    uint256 bufferLiquidity; // liquidity reserved for swapping, decimal is depends on token
    uint256 maxWeightDiff; // Maximum difference from the target weight in %
    bool accepted; // accepted to provide liquidity
  }

  /// @notice collateral token config
  struct CollateralTokenConfig {
    address settleStrategy; // determine token will be settled for NON PLP collateral, e.g. aUSDC redeemed as USDC
    uint32 collateralFactorBPS; // token reliability factor to calculate buying power, 1e4 = 100%
    bool accepted; // accepted to deposit as collateral
  }

  struct FundingRate {
    uint256 maxSkewScaleUSD; // maximum skew scale for using maxFundingRate
    uint256 maxFundingRate; // maximum funding rate
  }

  struct MarketConfig {
    bytes32 assetId; // pyth network asset id
    uint32 increasePositionFeeRateBPS; // fee rate to increase position
    uint32 decreasePositionFeeRateBPS; // fee rate to decrease position
    uint32 initialMarginFractionBPS; // IMF
    uint32 maintenanceMarginFractionBPS; // MMF
    uint32 maxProfitRateBPS; // maximum profit that trader could take per position
    uint32 minLeverageBPS; // minimum leverage that trader could open position
    uint8 assetClass; // Crypto = 1, Forex = 2, Stock = 3
    bool allowIncreasePosition; // allow trader to increase position
    bool active; // if active = false, means this market is delisted
    FundingRate fundingRate;
  }

  struct AssetClassConfig {
    uint256 baseBorrowingRate;
  }

  struct LiquidityConfig {
    uint256 plpTotalTokenWeight; // % of token Weight (must be 1e18)
    uint32 plpSafetyBufferBPS; // for PLP deleverage
    uint32 taxFeeRateBPS; // PLP deposit, withdraw, settle collect when pool weight is imbalances
    uint32 flashLoanFeeRateBPS;
    uint32 maxPLPUtilizationBPS; //% of max utilization
    uint32 depositFeeRateBPS; // PLP deposit fee rate
    uint32 withdrawFeeRateBPS; // PLP withdraw fee rate
    bool dynamicFeeEnabled; // if disabled, swap, add or remove liquidity will exclude tax fee
    bool enabled; // Circuit breaker on Liquidity
  }

  struct SwapConfig {
    uint32 stablecoinSwapFeeRateBPS;
    uint32 swapFeeRateBPS;
  }

  struct TradingConfig {
    uint256 fundingInterval; // funding interval unit in seconds
    uint256 minProfitDuration;
    uint32 devFeeRateBPS;
    uint8 maxPosition;
  }

  struct LiquidationConfig {
    uint256 liquidationFeeUSDE30; // liquidation fee in USD
  }

  /**
   * State Getter
   */

  function calculator() external view returns (address);

  function oracle() external view returns (address);

  function plp() external view returns (address);

  function treasury() external view returns (address);

  function pnlFactorBPS() external view returns (uint32);

  function weth() external view returns (address);

  function tokenAssetIds(address _token) external view returns (bytes32);

  /**
   * Validation
   */

  function validateServiceExecutor(address _contractAddress, address _executorAddress) external view;

  function validateAcceptedLiquidityToken(address _token) external view;

  function validateAcceptedCollateral(address _token) external view;

  /**
   * Getter
   */

  function getMarketConfigById(uint256 _marketIndex) external view returns (MarketConfig memory _marketConfig);

  function getTradingConfig() external view returns (TradingConfig memory);

  function getMarketConfigByIndex(uint256 _index) external view returns (MarketConfig memory _marketConfig);

  function getAssetClassConfigByIndex(uint256 _index) external view returns (AssetClassConfig memory _assetClassConfig);

  function getCollateralTokenConfigs(
    address _token
  ) external view returns (CollateralTokenConfig memory _collateralTokenConfig);

  function getAssetTokenDecimal(address _token) external view returns (uint8);

  function getLiquidityConfig() external view returns (LiquidityConfig memory);

  function getLiquidationConfig() external view returns (LiquidationConfig memory);

  function getMarketConfigsLength() external view returns (uint256);

  function getPlpTokens() external view returns (address[] memory);

  function getAssetConfigByToken(address _token) external view returns (AssetConfig memory);

  function getCollateralTokens() external view returns (address[] memory);

  function getAssetConfig(bytes32 _assetId) external view returns (AssetConfig memory);

  function getAssetPlpTokenConfig(bytes32 _assetId) external view returns (PLPTokenConfig memory);

  function getAssetPlpTokenConfigByToken(address _token) external view returns (PLPTokenConfig memory);

  function getPlpAssetIds() external view returns (bytes32[] memory);

  function getTradeServiceHooks() external view returns (address[] memory);

  /**
   * Setter
   */

  function setPlpAssetId(bytes32[] memory _plpAssetIds) external;

  function setLiquidityEnabled(bool _enabled) external;

  function setDynamicEnabled(bool _enabled) external;

  function setCalculator(address _calculator) external;

  function setOracle(address _oracle) external;

  function setPLP(address _plp) external;

  function setLiquidityConfig(LiquidityConfig memory _liquidityConfig) external;

  // @todo - Add Description
  function setServiceExecutor(address _contractAddress, address _executorAddress, bool _isServiceExecutor) external;

  function setPnlFactor(uint32 _pnlFactor) external;

  function setSwapConfig(SwapConfig memory _newConfig) external;

  function setTradingConfig(TradingConfig memory _newConfig) external;

  function setLiquidationConfig(LiquidationConfig memory _newConfig) external;

  function setMarketConfig(
    uint256 _marketIndex,
    MarketConfig memory _newConfig
  ) external returns (MarketConfig memory _marketConfig);

  function setPlpTokenConfig(
    address _token,
    PLPTokenConfig memory _newConfig
  ) external returns (PLPTokenConfig memory _plpTokenConfig);

  function setCollateralTokenConfig(
    bytes32 _assetId,
    CollateralTokenConfig memory _newConfig
  ) external returns (CollateralTokenConfig memory _collateralTokenConfig);

  function setAssetConfig(
    bytes32 assetId,
    AssetConfig memory _newConfig
  ) external returns (AssetConfig memory _assetConfig);

  function setWeth(address _weth) external;

  function addOrUpdateAcceptedToken(address[] calldata _tokens, PLPTokenConfig[] calldata _configs) external;

  function addAssetClassConfig(AssetClassConfig calldata _newConfig) external returns (uint256 _index);

  function setAssetClassConfigByIndex(uint256 _index, AssetClassConfig calldata _newConfig) external;

  function setTradeServiceHooks(address[] calldata _newHooks) external;

  function addMarketConfig(MarketConfig calldata _newConfig) external returns (uint256 _index);

  function delistMarket(uint256 _marketIndex) external;

  function removeAcceptedToken(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPerpStorage {
  /**
   * Errors
   */
  error IPerpStorage_NotWhiteListed();

  struct GlobalState {
    uint256 reserveValueE30; // accumulative of reserve value from all opening positions
  }

  struct GlobalAssetClass {
    uint256 reserveValueE30; // accumulative of reserve value from all opening positions
    uint256 sumBorrowingRate;
    uint256 lastBorrowingTime;
    uint256 sumBorrowingFeeE30;
    uint256 sumSettledBorrowingFeeE30;
  }

  // mapping _marketIndex => globalPosition;
  struct GlobalMarket {
    // LONG position
    uint256 longPositionSize;
    uint256 longAvgPrice;
    // SHORT position
    uint256 shortPositionSize;
    uint256 shortAvgPrice;
    // funding rate
    int256 currentFundingRate;
    uint256 lastFundingTime;
    int256 accumFundingLong; // accumulative of funding fee value on LONG positions using for calculating surplus
    int256 accumFundingShort; // accumulative of funding fee value on SHORT positions using for calculating surplus
  }

  // Trade position
  struct Position {
    address primaryAccount;
    uint256 marketIndex;
    uint256 avgEntryPriceE30;
    uint256 entryBorrowingRate;
    uint256 reserveValueE30; // Max Profit reserved in USD (9X of position collateral)
    uint256 lastIncreaseTimestamp; // To validate position lifetime
    int256 positionSizeE30; // LONG (+), SHORT(-) Position Size
    int256 realizedPnl;
    int256 entryFundingRate;
    uint8 subAccountId;
  }

  /**
   * Getter
   */

  function getPositionBySubAccount(address _trader) external view returns (Position[] memory traderPositions);

  function getPositionById(bytes32 _positionId) external view returns (Position memory);

  function getGlobalMarketByIndex(uint256 _marketIndex) external view returns (GlobalMarket memory);

  function getGlobalAssetClassByIndex(uint256 _assetClassIndex) external view returns (GlobalAssetClass memory);

  function getGlobalState() external view returns (GlobalState memory);

  function getNumberOfSubAccountPosition(address _subAccount) external view returns (uint256);

  function getBadDebt(address _subAccount) external view returns (uint256 badDebt);

  function updateGlobalLongMarketById(uint256 _marketIndex, uint256 _newPositionSize, uint256 _newAvgPrice) external;

  function updateGlobalShortMarketById(uint256 _marketIndex, uint256 _newPositionSize, uint256 _newAvgPrice) external;

  function updateGlobalState(GlobalState memory _newGlobalState) external;

  function savePosition(address _subAccount, bytes32 _positionId, Position calldata position) external;

  function removePositionFromSubAccount(address _subAccount, bytes32 _positionId) external;

  function updateGlobalAssetClass(uint8 _assetClassIndex, GlobalAssetClass memory _newAssetClass) external;

  function addBadDebt(address _subAccount, uint256 _badDebt) external;

  function updateGlobalMarket(uint256 _marketIndex, GlobalMarket memory _globalMarket) external;

  function getPositionIds(address _subAccount) external returns (bytes32[] memory _positionIds);

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external;

  function increaseReserved(uint8 _assetClassIndex, uint256 _reserve) external;

  function decreaseReserved(uint8 _assetClassIndex, uint256 _reserve) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVaultStorage {
  /**
   * Errors
   */
  error IVaultStorage_NotWhiteListed();
  error IVaultStorage_TraderTokenAlreadyExists();
  error IVaultStorage_TraderBalanceRemaining();
  error IVaultStorage_ZeroAddress();
  error IVaultStorage_PLPBalanceRemaining();

  /**
   * Functions
   */

  function totalAmount(address _token) external returns (uint256);

  function plpLiquidityDebtUSDE30() external view returns (uint256);

  function traderBalances(address _trader, address _token) external view returns (uint256 amount);

  function getTraderTokens(address _trader) external view returns (address[] memory);

  function protocolFees(address _token) external view returns (uint256);

  function fundingFeeReserve(address _token) external view returns (uint256);

  function devFees(address _token) external view returns (uint256);

  function plpLiquidity(address _token) external view returns (uint256);

  function pullToken(address _token) external returns (uint256);

  function addFee(address _token, uint256 _amount) external;

  function addPLPLiquidity(address _token, uint256 _amount) external;

  function withdrawFee(address _token, uint256 _amount, address _receiver) external;

  function removePLPLiquidity(address _token, uint256 _amount) external;

  function pushToken(address _token, address _to, uint256 _amount) external;

  function addFundingFee(address _token, uint256 _amount) external;

  function removeFundingFee(address _token, uint256 _amount) external;

  function addPlpLiquidityDebtUSDE30(uint256 _value) external;

  function removePlpLiquidityDebtUSDE30(uint256 _value) external;

  function pullPLPLiquidity(address _token) external view returns (uint256);

  function increaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function decreaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function payPlp(address _trader, address _token, uint256 _amount) external;

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external;

  function borrowFundingFeeFromPlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;

  function repayFundingFeeDebtFromTraderToPlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;
}