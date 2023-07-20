// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Deposit, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ICegaState } from "./interfaces/ICegaState.sol";
import { DCSVault } from "./DCSVault.sol";

library DCSCalculations {
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_TO_DAYS = 86400;
    uint256 public constant BPS_DECIMALS = 10 ** 4;
    uint256 public constant LARGE_CONSTANT = 10 ** 18;
    uint256 public constant ORACLE_STALE_DELAY = 1 days;

    function convertBaseAssetToAlternativeAsset(
        uint256 priceToConvert,
        uint256 strikePrice
    ) public pure returns (uint256) {
        return (priceToConvert * LARGE_CONSTANT) / (strikePrice * LARGE_CONSTANT);
    }

    function getSpotPriceAtExpiry(
        string memory oracleName,
        uint256 tradeEndDate,
        address cegaStateAddress
    ) public view returns (uint256) {
        ICegaState cegaState = ICegaState(cegaStateAddress);
        address oracle = cegaState.oracleAddresses(oracleName);
        require(oracle != address(0), "400:Unregistered");

        // TODO need to use historical data
        (, int256 answer, uint256 startedAt, , ) = IOracle(oracle).latestRoundData();
        require(tradeEndDate - ORACLE_STALE_DELAY <= startedAt, "400:T");
        return uint256(answer);
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param vaultFinalPayoff is the final payoff of the vault
     * @param feeBps is the fee in bps
     */
    function calculateFees(uint256 vaultFinalPayoff, uint256 feeBps) public pure returns (uint256) {
        uint256 totalFee = (vaultFinalPayoff * feeBps) / BPS_DECIMALS;
        return totalFee;
    }

    /**
     * @notice Calculates the coupon payment accumulated for a given number of daysPassed
     * @param underlyingAmount is the amount of assets
     * @param aprBps is the apr in bps
     * @param tradeDate is the date of the trade
     */
    function calculateCouponPayment(
        uint256 underlyingAmount,
        uint256 aprBps,
        uint256 tradeDate,
        uint256 tenorInDays
    ) public view returns (uint256) {
        uint256 currentTime = block.timestamp;

        // if (currentTime > tradeExpiry) {
        //     self.vaultStatus = VaultStatus.TradeExpired;
        //     return;
        // }

        uint256 daysPassed = (currentTime - tradeDate) / DCSCalculations.SECONDS_TO_DAYS;
        uint256 couponDays = Math.min(daysPassed, tenorInDays);

        return (underlyingAmount * couponDays * aprBps * LARGE_CONSTANT) / DAYS_IN_YEAR / BPS_DECIMALS / LARGE_CONSTANT;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ICegaState } from "./interfaces/ICegaState.sol";
import { Deposit, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { DCSVault } from "./DCSVault.sol";
import { DCSCalculations } from "./DCSCalculations.sol";

contract DCSProduct is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event DCSProductCreated(
        address indexed cegaState,
        address indexed baseAssetAddress,
        address indexed alternativeAssetAddress,
        string name,
        uint256 feeBps,
        uint256 maxDepositAmountLimit,
        uint256 minDepositAmount,
        uint256 minWithdrawalAmount,
        address dcsCalculationsAddress
    );

    event MinDepositAmountUpdated(uint256 minDepositAmount);
    event MinWithdrawalAmountUpdated(uint256 minWithdrawalAmount);
    event IsDepositQueueOpenUpdated(bool isDepositQueueOpen);
    event MaxDepositAmountLimitUpdated(uint256 maxDepositAmountLimit);

    event VaultCreated(address indexed vaultAddress, string _tokenSymbol, string _tokenName, uint256 _vaultStart);
    event VaultRemoved(address indexed vaultAddress);

    event DepositQueued(address indexed receiver, uint256 amount);
    event DepositProcessed(address indexed vaultAddress, address indexed receiver, uint256 amount);

    event VaultStatusUpdated(address indexed vaultAddress, VaultStatus vaultStatus);

    ICegaState public cegaState;

    address public immutable baseAssetAddress; // will usually be usdc
    address public immutable alternativeAssetAddress; // asset returned if final spot falls below strike
    string public name;
    string public oracleName;
    uint256 public feeBps; // basis points
    bool public isDepositQueueOpen;
    uint256 public maxDepositAmountLimit;
    uint256 public minDepositAmount;
    uint256 public minWithdrawalAmount;

    uint256 public sumVaultUnderlyingAmounts;
    uint256 public queuedDepositsTotalAmount;
    uint256 public queuedDepositsCount;

    address[] public vaultAddresses;

    Deposit[] public depositQueue;

    address public dcsCalculationsAddress;

    /**
     * @notice Creates a new DCSProduct
     * @param _cegaState is the address of the CegaState contract
     * @param _baseAssetAddress is the address of the base currency
     * @param _alternativeAssetAddress is the adress of the alternative currency
     * @param _name is the name of the product
     * @param _maxDepositAmountLimit is the deposit limit for the product
     * @param _minDepositAmount is the minimum units of underlying for a user to deposit
     * @param _minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    constructor(
        address _cegaState,
        address _baseAssetAddress,
        address _alternativeAssetAddress,
        string memory _name,
        uint256 _feeBps,
        uint256 _maxDepositAmountLimit,
        uint256 _minDepositAmount,
        uint256 _minWithdrawalAmount,
        address _dcsCalculationsAddress, // if we need to upgrade/swap out calculations logic. TODO need to figure out how this routing actually works..
        string memory _oracleName // we'll only have one oracle per product, which tracks the baseAsset
    ) {
        require(_feeBps < 1e4, "400:IB");
        require(_minDepositAmount > 0, "400:IU");
        require(_minWithdrawalAmount > 0, "400:IU");
        require(_baseAssetAddress != address(0), "400:AD");
        require(_alternativeAssetAddress != address(0), "400:AD");

        cegaState = ICegaState(_cegaState);
        baseAssetAddress = _baseAssetAddress;
        alternativeAssetAddress = _alternativeAssetAddress;
        name = _name;
        feeBps = _feeBps;
        maxDepositAmountLimit = _maxDepositAmountLimit;
        isDepositQueueOpen = false;

        minDepositAmount = _minDepositAmount;
        minWithdrawalAmount = _minWithdrawalAmount;

        dcsCalculationsAddress = _dcsCalculationsAddress;
        oracleName = _oracleName;
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     */
    modifier onlyDefaultAdmin() {
        require(cegaState.isDefaultAdmin(msg.sender), "403:DA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     */
    modifier onlyOperatorAdmin() {
        require(cegaState.isOperatorAdmin(msg.sender), "403:OA");
        _;
    }

    /**
     * @notice Asserts that the vault has been initialized & is a Cega Vault
     */
    modifier onlyValidVault(address vaultAddress) {
        DCSVault vault = DCSVault(vaultAddress);
        require(vault.vaultStart() != 0, "400:VA");
        _;
    }

    /**
     * @notice Returns array of vault addresses associated with the product
     */
    function getVaultAddresses() public view returns (address[] memory) {
        return vaultAddresses;
    }

    /**
     * @notice Returns sum of base assets in all vaults
     */
    function getSumVaultBaseAssets() public view returns (uint256) {
        uint256 sumVaultBaseAssets = 0;
        for (uint i = 0; i < vaultAddresses.length; i++) {
            DCSVault vault = DCSVault(vaultAddresses[i]);
            uint256 vaultBaseAssets = vault.totalBaseAssets();
            sumVaultBaseAssets += vaultBaseAssets;
        }
        return sumVaultBaseAssets;
    }

    /**
     * @notice Returns sum of alternative assets in all vaults
     */
    function getSumVaultAlternativeAssets() public view returns (uint256) {
        uint256 sumVaultAlternativeAssets = 0;
        for (uint i = 0; i < vaultAddresses.length; i++) {
            DCSVault vault = DCSVault(vaultAddresses[i]);
            uint256 vaultAlternativeAssets = vault.totalAlternativeAssets();
            sumVaultAlternativeAssets += vaultAlternativeAssets;
        }
        return sumVaultAlternativeAssets;
    }

    function getFeeBps() public view returns (uint256) {
        return feeBps;
    }

    /**
     * @notice Sets a new address for DCSCalculations for future upgradability. Can only be modified by defaultadmin
     */
    function setDCSCalculationsAddress(address _newDCSCalculationsAddress) public onlyDefaultAdmin {
        dcsCalculationsAddress = _newDCSCalculationsAddress;
    }

    /**
     * @notice Sets the management fee for the product
     * @param _feeBps is the management fee in bps (100% = 10000)
     */
    function setFeeBps(uint256 _feeBps) public onlyOperatorAdmin {
        require(_feeBps < 1e4, "400:IB");
        feeBps = _feeBps;
    }

    /**
     * @notice Sets the min deposit amount for the product
     * @param _minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function setMinDepositAmount(uint256 _minDepositAmount) public onlyOperatorAdmin {
        require(_minDepositAmount > 0, "400:IU");
        minDepositAmount = _minDepositAmount;
        emit MinDepositAmountUpdated(_minDepositAmount);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param _minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function setMinWithdrawalAmount(uint256 _minWithdrawalAmount) public onlyOperatorAdmin {
        require(_minWithdrawalAmount > 0, "400:IU");
        minWithdrawalAmount = _minWithdrawalAmount;
        emit MinWithdrawalAmountUpdated(_minWithdrawalAmount);
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param _isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function setIsDepositQueueOpen(bool _isDepositQueueOpen) public onlyOperatorAdmin {
        isDepositQueueOpen = _isDepositQueueOpen;
        emit IsDepositQueueOpenUpdated(_isDepositQueueOpen);
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) public onlyTraderAdmin {
        require(queuedDepositsTotalAmount + sumVaultUnderlyingAmounts <= _maxDepositAmountLimit, "400:TooSmall");
        maxDepositAmountLimit = _maxDepositAmountLimit;
        emit MaxDepositAmountLimitUpdated(_maxDepositAmountLimit);
    }

    /**
     * @notice Creates a new vault for the product & maps the new vault address to the vaultMetadata
     * @param _tokenName is the name of the token for the vault
     * @param _tokenSymbol is the symbol for the vault's token
     * @param _vaultStart is the timestamp of the vault's start
     */
    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart,
        address _cegaState
    ) public onlyTraderAdmin returns (address vaultAddress) {
        require(_vaultStart != 0, "400:VS");
        DCSVault vault = new DCSVault(
            _cegaState,
            baseAssetAddress,
            alternativeAssetAddress,
            _tokenName,
            _tokenSymbol,
            _vaultStart,
            oracleName
        );
        address newVaultAddress = address(vault);
        vaultAddresses.push(newVaultAddress);

        // TODO update event to include all params
        emit VaultCreated(newVaultAddress, _tokenSymbol, _tokenName, _vaultStart);
        return newVaultAddress;
    }

    /**
     * @notice defaultAdmin has the ability to remove a Vault
     * @param i is the index of the vault in the vaultAddresses array
     */
    function removeVault(uint256 i) public onlyDefaultAdmin {
        address vaultAddress = vaultAddresses[i];
        vaultAddresses[i] = vaultAddresses[vaultAddresses.length - 1];
        vaultAddresses.pop();

        emit VaultRemoved(vaultAddress);
    }

    /**
     * Transfers assets from the user to the product
     * @param amount is the amount of assets being deposited
     */
    function addToDepositQueue(uint256 amount) public nonReentrant {
        require(isDepositQueueOpen, "500:NotOpen");
        require(amount >= minDepositAmount, "400:DA");

        queuedDepositsCount += 1;
        queuedDepositsTotalAmount += amount;
        require((queuedDepositsTotalAmount + getSumVaultBaseAssets()) <= maxDepositAmountLimit, "500:TooBig");

        IERC20(baseAssetAddress).safeTransferFrom(msg.sender, address(this), amount);
        depositQueue.push(Deposit({ amount: amount, receiver: msg.sender }));
        emit DepositQueued(msg.sender, amount);
    }

    /**
     * Processes the product's deposit queue into a specific vault
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the number of elements in the deposit queue to be processed
     */

    function processDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public nonReentrant onlyTraderAdmin onlyValidVault(vaultAddress) {
        DCSVault vault = DCSVault(vaultAddress);
        // require(vault.vaultStatus == VaultStatus.DepositsOpen, "500:WS");
        // require(!(vault.totalBaseAssets == 0 && vault.totalSupply() > 0), "500:Z");

        uint256 processCount = Math.min(queuedDepositsCount, maxProcessCount);
        Deposit storage deposit;

        while (processCount > 0) {
            deposit = depositQueue[queuedDepositsCount - 1];

            queuedDepositsTotalAmount -= deposit.amount;
            vault.deposit(deposit.amount, deposit.receiver);
            IERC20(baseAssetAddress).approve(address(this), deposit.amount);
            IERC20(baseAssetAddress).safeTransferFrom(address(this), vaultAddress, deposit.amount);

            depositQueue.pop();
            queuedDepositsCount -= 1;
            processCount -= 1;

            emit DepositProcessed(vaultAddress, deposit.receiver, deposit.amount);
        }

        if (queuedDepositsCount == 0) {
            vault.setVaultStatus(VaultStatus.NotTraded);
            emit VaultStatusUpdated(vaultAddress, VaultStatus.NotTraded);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ICegaState } from "./interfaces/ICegaState.sol";
import { DCSProduct } from "./DCSProduct.sol";
import { VaultStatus, Withdrawal } from "./Structs.sol";
import { DCSCalculations } from "./DCSCalculations.sol";

contract DCSVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event WithdrawalQueued(address indexed vaultAddress, address indexed receiver, uint256 amountShares);

    address public cegaStateAddress;
    ICegaState public cegaState;
    DCSProduct public dcsProduct;

    // Vault Set Up information
    address public immutable baseAssetAddress; // will usually be usdc
    address public immutable alternativeAssetAddress; // asset returned if final spot falls below strike
    string public oracleName; // maybe dont need this but keeping for now

    // Trade information
    uint256 public vaultStart;
    uint256 public tradeStartDate;
    uint256 public tradeEndDate;
    uint256 public aprBps;
    uint256 public tenorInDays;
    uint256 public initialBaseSpotPrice;
    uint256 public strikeBasePrice; // strike price set at beginning of trade, in units of baseAsset
    address public auctionWinner;

    Withdrawal[] public withdrawalQueue;

    // Vault Status Information
    VaultStatus public vaultStatus;
    uint256 public finalBaseSpotPrice; // final spot price at trade end, in units of baseAsset
    bool public isPayoffInBaseAsset; // whether we payoff in base asset or alternative asset
    uint256 public notionalInBaseAsset;
    uint256 public vaultFinalPayoff; // this unit will be base asset if isPayoffWithBaseAsset == true
    uint256 public totalYield;

    // Deposits & withdraw information
    uint256 public queuedWithdrawalsSharesAmount;
    uint256 public queuedWithdrawalsCount;

    /**
     * @notice Creates a new DCSVault that is owned by a DCSProduct
     * @param _baseAssetAddress is the address of the underlying asset
     * @param _alternativeAssetAddress is the address of the alternative asset
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the name of the token symbol
     */
    constructor(
        address _cegaStateAddress,
        address _baseAssetAddress,
        address _alternativeAssetAddress,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart,
        string memory _oracleName
    ) ERC20(_tokenName, _tokenSymbol) {
        cegaStateAddress = _cegaStateAddress;
        cegaState = ICegaState(cegaStateAddress);
        baseAssetAddress = _baseAssetAddress;
        alternativeAssetAddress = _alternativeAssetAddress;
        isPayoffInBaseAsset = true;
        vaultStart = _vaultStart;
        oracleName = _oracleName;
        dcsProduct = DCSProduct(owner());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     */
    modifier onlyDefaultAdmin() {
        require(cegaState.isDefaultAdmin(msg.sender), "403:DA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     */
    modifier onlyOperatorAdmin() {
        require(cegaState.isOperatorAdmin(msg.sender), "403:OA");
        _;
    }

    /**
     * @notice Asserts that the vault has been initialized & is a Cega Vault
     */
    modifier onlyValidVault() {
        require(vaultStart != 0, "400:VA");
        _;
    }

    modifier onlyProductOrOperatorAdmin() {
        require(msg.sender == owner() || cegaState.isOperatorAdmin(msg.sender), "403:POA");
        _;
    }

    /**
     * @notice Returns base assets in vault
     */
    function totalBaseAssets() public view returns (uint256) {
        return IERC20(baseAssetAddress).balanceOf(address(this));
    }

    /**
     * @notice Returns alternative assets in vault
     */
    function totalAlternativeAssets() public view returns (uint256) {
        return IERC20(alternativeAssetAddress).balanceOf(address(this));
    }

    /**
     * @notice Converts units of shares to assets
     * @param shares is the number of vault tokens
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        if (isPayoffInBaseAsset) {
            return (shares * totalBaseAssets()) / _totalSupply;
        }
        return (shares * totalAlternativeAssets()) / _totalSupply;
    }

    /**
     * @notice Converts units assets to shares
     * @param assets is the amount of base assets
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _totalBaseAssets = totalBaseAssets();
        if (_totalBaseAssets == 0 || _totalSupply == 0) return assets;
        return (assets * _totalSupply) / _totalBaseAssets;
    }

    /**
     * Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     * @param receiver is the address of the original depositor
     */
    function deposit(uint256 assets, address receiver) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        _mint(receiver, shares);

        return shares;
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     */
    function redeem(uint256 shares) external onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        _burn(msg.sender, shares);

        return assets;
    }

    // TRADING METHODS
    // TODO - create NFT / token to send to a winning MM?

    /**
     * Trader admin has ability to set the vault to "DepositsOpen" state
     */
    function openVaultDeposits() public onlyTraderAdmin {
        require(vaultStatus == VaultStatus.DepositsClosed, "500:WS");
        vaultStatus = VaultStatus.DepositsOpen;
    }

    /**
     * @notice Trader admin sets the trade data after the auction. This Starts the trade
     */
    function startTrade(
        uint256 _tradeStartDate,
        uint256 _tradeEndDate,
        uint256 _aprBps,
        uint256 _tenorInDays,
        uint256 _strikeBasePrice,
        uint256 _initialSpotBasePrice,
        address _auctionWinner
    ) public onlyTraderAdmin onlyValidVault {
        require(vaultStatus == VaultStatus.NotTraded, "500:WS");
        require(_tradeStartDate >= vaultStart, "400:TD");
        require(_tradeEndDate > _tradeStartDate, "400:TE");

        // allow for a 1 day difference in input tenor and derived tenor
        uint256 derivedDays = (_tradeEndDate - _tradeStartDate) / 1 days;
        if (derivedDays < _tenorInDays) {
            require(_tenorInDays - derivedDays <= 1, "400:TN");
        } else {
            require(derivedDays - _tenorInDays <= 1, "400:TN");
        }

        tradeStartDate = _tradeStartDate;
        tradeEndDate = _tradeEndDate;
        aprBps = _aprBps;
        tenorInDays = _tenorInDays;
        strikeBasePrice = _strikeBasePrice;
        initialBaseSpotPrice = _initialSpotBasePrice;
        auctionWinner = _auctionWinner;
        notionalInBaseAsset = totalBaseAssets();
    }

    // SETTLEMENT METHODS
    /**
     * @notice Calculates the final payoff for a given vault
     */
    function calculateVaultFinalPayoff() public onlyValidVault returns (uint256) {
        require((vaultStatus == VaultStatus.TradeExpired || vaultStatus == VaultStatus.PayoffCalculated), "500:WS");
        finalBaseSpotPrice = DCSCalculations.getSpotPriceAtExpiry(oracleName, tradeEndDate, cegaStateAddress);
        // convert to alternative asset
        if (finalBaseSpotPrice < strikeBasePrice) {
            isPayoffInBaseAsset = false;
            uint256 notionalInAlternativeAsset = DCSCalculations.convertBaseAssetToAlternativeAsset(
                notionalInBaseAsset,
                strikeBasePrice
            );
            uint256 couponInAlternativeAsset = DCSCalculations.calculateCouponPayment(
                notionalInAlternativeAsset,
                aprBps,
                tradeStartDate,
                tenorInDays
            );
            totalYield = couponInAlternativeAsset;
            vaultFinalPayoff = notionalInAlternativeAsset + couponInAlternativeAsset;
        } else {
            uint256 couponInBaseAsset = DCSCalculations.calculateCouponPayment(
                notionalInBaseAsset,
                aprBps,
                tradeStartDate,
                tenorInDays
            );
            totalYield = couponInBaseAsset;
            vaultFinalPayoff = notionalInBaseAsset + couponInBaseAsset;
        }

        vaultStatus = VaultStatus.PayoffCalculated;
        return vaultFinalPayoff;
    }

    // MM does settlement with us in alternative asset
    // we burn their nft? check valid position?
    function settlementInAlternativeAsset(address counterparty) public nonReentrant {
        // Payoff in alternative asset
        if (!isPayoffInBaseAsset) {
            // require counter party to have enough funds
            require(IERC20(alternativeAssetAddress).balanceOf(counterparty) >= vaultFinalPayoff);
            // we send USDC notional
            IERC20(baseAssetAddress).safeTransfer(counterparty, notionalInBaseAsset);
            // take correct amount in alternative asset from them
            IERC20(alternativeAssetAddress).safeTransferFrom(msg.sender, address(this), vaultFinalPayoff);
        }
    }

    /**
     * @notice Transfers the correct amount of fees to the fee recipient
     */
    function collectFees() public nonReentrant onlyTraderAdmin onlyValidVault {
        require(vaultStatus == VaultStatus.PayoffCalculated, "500:WS");

        uint256 totalFees = DCSCalculations.calculateFees(vaultFinalPayoff, dcsProduct.getFeeBps());

        totalFees = Math.min(totalFees, vaultFinalPayoff);
        IERC20(baseAssetAddress).safeTransfer(cegaState.feeRecipient(), totalFees);

        vaultStatus = VaultStatus.FeesCollected;
    }

    /**
     * @notice Queues a withdrawal for the token holder of a specific vault token
     * @param amountShares is the number of vault tokens to be redeemed
     */
    function addToWithdrawalQueue(uint256 amountShares) public nonReentrant onlyValidVault {
        require(amountShares >= dcsProduct.minWithdrawalAmount(), "400:WA");

        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), amountShares);
        withdrawalQueue.push(Withdrawal({ amountShares: amountShares, receiver: msg.sender }));
        queuedWithdrawalsCount += 1;
        queuedWithdrawalsSharesAmount += amountShares;
        emit WithdrawalQueued(address(this), msg.sender, amountShares);
    }

    /**
     * @notice Processes all the queued withdrawals in the withdrawal queue
     * @param maxProcessCount is the maximum number of withdrawals to process in the queue
     */
    function processWithdrawalQueue(uint256 maxProcessCount) public nonReentrant onlyTraderAdmin onlyValidVault {
        // Needs zombie state so that we can restore the vault
        require(vaultStatus == VaultStatus.FeesCollected || vaultStatus == VaultStatus.Zombie, "500:WS");

        uint256 processCount = Math.min(queuedWithdrawalsCount, maxProcessCount);
        uint256 amountAssets;
        Withdrawal memory withdrawal;
        while (processCount > 0) {
            withdrawal = withdrawalQueue[queuedWithdrawalsCount - 1];

            // redeem does the conversion in base / altnerative assets
            amountAssets = this.redeem(withdrawal.amountShares);
            if (isPayoffInBaseAsset) {
                IERC20(baseAssetAddress).safeTransfer(withdrawal.receiver, amountAssets);
            } else {
                IERC20(alternativeAssetAddress).safeTransfer(withdrawal.receiver, amountAssets);
            }

            withdrawalQueue.pop();
            queuedWithdrawalsCount -= 1;
            processCount -= 1;
        }

        if (queuedWithdrawalsCount == 0) {
            if (totalBaseAssets() == 0 && totalAlternativeAssets() == 0 && totalSupply() > 0) {
                vaultStatus = VaultStatus.Zombie;
            } else {
                vaultStatus = VaultStatus.WithdrawalQueueProcessed;
            }
        }
    }

    /**
     * @notice Resets the vault to the default state after the trade is settled
     */
    function rolloverVault() public onlyTraderAdmin onlyValidVault {
        require(vaultStatus == VaultStatus.WithdrawalQueueProcessed, "500:WS");
        require(tradeEndDate != 0, "400:TE");
        if (isPayoffInBaseAsset) {
            vaultStart = tradeEndDate;
            tradeStartDate = 0;
            tradeEndDate = 0;
            aprBps = 0;
            vaultStatus = VaultStatus.DepositsClosed;
            totalYield = 0;
            vaultFinalPayoff = 0;
            initialBaseSpotPrice = 0;
            strikeBasePrice = 0;
            auctionWinner = address(0);
        } else {
            vaultStatus = VaultStatus.Zombie;
        }
    }

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     */
    function calculateCurrentYield() public onlyValidVault returns (uint256) {
        uint256 currentTime = block.timestamp;

        if (currentTime > tradeEndDate) {
            vaultStatus = VaultStatus.TradeExpired;
        }
        uint256 currentYield = DCSCalculations.calculateCouponPayment(
            notionalInBaseAsset,
            aprBps,
            tradeStartDate,
            tenorInDays
        );
        totalYield = currentYield;
    }

    /**
     * Operator admin has ability to override the vault's status
     * @param _vaultStatus is the new status for the vault
     */
    function setVaultStatus(VaultStatus _vaultStatus) public onlyProductOrOperatorAdmin onlyValidVault {
        vaultStatus = _vaultStatus;
    }

    /**
     * Default admin has an override to set the knock in status for a vault
     * @param newState is the new state for isKnockedIn
     */
    function setIsPayoffInBaseAsset(bool newState) public onlyDefaultAdmin onlyValidVault {
        isPayoffInBaseAsset = newState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICegaState {
    function marketMakerAllowList(address marketMaker) external view returns (bool);

    function products(string memory productName) external view returns (address);

    function oracleAddresses(string memory oracleName) external view returns (address);

    function oracleNames() external view returns (string[] memory);

    function productNames() external view returns (string[] memory);

    function feeRecipient() external view returns (address);

    function isDefaultAdmin(address sender) external view returns (bool);

    function isTraderAdmin(address sender) external view returns (bool);

    function isOperatorAdmin(address sender) external view returns (bool);

    function isServiceAdmin(address sender) external view returns (bool);

    function getOracleNames() external view returns (string[] memory);

    function addOracle(string memory oracleName, address oracleAddress) external;

    function removeOracle(string memory oracleName) external;

    function getProductNames() external view returns (string[] memory);

    function addProduct(string memory productName, address product) external;

    function removeProduct(string memory productName) external;

    function updateMarketMakerPermission(address marketMaker, bool allow) external;

    function setFeeRecipient(address _feeRecipient) external;

    function moveAssetsToProduct(string memory productName, address vaultAddress, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IAggregatorV3 } from "./IAggregatorV3.sol";
import { RoundData } from "../Structs.sol";

interface IOracle is IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function cegaState() external view returns (address);

    function oracleData() external view returns (RoundData[] memory);

    function nextRoundId() external view returns (uint80);

    function addNextRoundData(RoundData calldata _roundData) external;

    function updateRoundData(uint80 roundId, RoundData calldata _roundData) external;

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

struct LeverageMetadata {
    bool isAllowed;
    bool isDepositQueueOpen;
    uint256 maxDepositAmountLimit;
    uint256 sumVaultUnderlyingAmounts;
    uint256 queuedDepositsTotalAmount;
    address[] vaultAddresses;
}

struct FCNVaultAssetInfo {
    address vaultAddress;
    uint256 totalAssets;
    uint256 totalSupply;
    uint256 inputAssets;
    uint256 outputShares;
    uint256 inputShares;
    uint256 outputAssets;
}