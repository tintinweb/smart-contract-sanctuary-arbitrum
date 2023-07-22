// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressRegistry.sol";

contract AddressRegistry is IAddressRegistry, Ownable {
    mapping(uint256 => address) libraryAndContractAddresses;

    constructor(address _weth9) {
        setAddress(AddressId.ADDRESS_ID_WETH9, _weth9);
    }

    function setAddress(uint256 id, address _addr) public onlyOwner {
        libraryAndContractAddresses[id] = _addr;
        emit SetAddress(_msgSender(), id, _addr);
    }

    function getAddress(uint256 id) external view override returns (address) {
        return libraryAndContractAddresses[id];
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "../libraries/helpers/AddressId.sol";

interface IAddressRegistry {
    event SetAddress(
        address indexed setter,
        uint256 indexed id,
        address newAddress
    );

    function getAddress(uint256 id) external view returns (address);
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExtraInterestBearingToken is IERC20 {
    /**
     * @dev Emitted after the mint action
     * @param to The address receive tokens
     * @param value The amount being
     **/
    event Mint(address indexed to, uint256 value);

    /**
     * @dev Mints `amount` eTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     */
    function mint(address user, uint256 amount) external;

    /**
     * @dev Emitted after eTokens are burned
     * @param from The owner of the eTokens, getting them burned
     * @param target The address that will receive the underlying tokens
     * @param eTokenAmount The amount being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    );

    /**
     * @dev Burns eTokens from `user` and sends the underlying tokens to `receiverOfUnderlying`
     * Can only be called by the lending pool;
     * The `underlyingTokenAmount` should be calculated based on the current exchange rate in lending pool
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param eTokenAmount The amount of eTokens being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    function burn(
        address receiverOfUnderlying,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    ) external;

    /**
     * @dev Emitted after the minted to treasury
     * @param treasury The treasury address
     * @param value The amount being minted
     **/
    event MintToTreasury(address indexed treasury, uint256 value);

    /**
     * @dev Mints eTokens to the treasury of the reserve
     * @param treasury The address of treasury
     * @param amount The amount of ftokens getting minted
     */
    function mintToTreasury(address treasury, uint256 amount) external;

    /**
     * @dev Transfers the underlying tokens to `target`. Called by the LendingPool to transfer
     * underlying tokens to target in functions like borrow(), withdraw()
     * @param target The recipient of the eTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(
        address target,
        uint256 amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    function utilizationRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function borrowingRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function exchangeRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function totalLiquidityOfReserve(
        uint256 reserveId
    ) external view returns (uint256 totalLiquidity);

    function totalBorrowsOfReserve(
        uint256 reserveId
    ) external view returns (uint256 totalBorrows);

    function getReserveIdOfDebt(uint256 debtId) external view returns (uint256);

    event InitReserve(
        address indexed reserve,
        address indexed eTokenAddress,
        address stakingAddress,
        uint256 id
    );
    /**
     * @dev Emitted on deposit()
     * @param reserveId The id of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the eTokens
     * @param reserveAmount The reserve amount deposited
     * @param eTokenAmount The eToken amount received
     * @param referral The referral code used
     **/
    event Deposited(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 reserveAmount,
        uint256 eTokenAmount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on redeem()
     * @param reserveId The id of the reserve
     * @param user The address initiating the withdrawal, owner of eTokens
     * @param to Address that will receive the underlying tokens
     * @param eTokenAmount The amount of eTokens to redeem
     * @param underlyingTokenAmount The amount of underlying tokens user received after redeem
     **/
    event Redeemed(
        uint256 indexed reserveId,
        address indexed user,
        address indexed to,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    );

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param reserveId The id of the reserve
     * @param contractAddress The address of the contract to initiate this borrow
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param amount The amount borrowed out
     **/
    event Borrow(
        uint256 indexed reserveId,
        address indexed contractAddress,
        address indexed onBehalfOf,
        uint256 amount
    );

    /**
     * @dev Emitted on repay()
     * @param reserveId The id of the reserve
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param contractAddress The address of the contract to initiate this repay
     * @param amount The amount repaid
     **/
    event Repay(
        uint256 indexed reserveId,
        address indexed onBehalfOf,
        address indexed contractAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event UnPaused();

    event EnableVaultToBorrow(
        uint256 indexed vaultId,
        address indexed vaultAddress
    );

    event DisableVaultToBorrow(
        uint256 indexed vaultId,
        address indexed vaultAddress
    );

    event SetCreditsOfVault(
        uint256 indexed vaultId,
        address indexed vaultAddress,
        uint256 indexed reserveId,
        uint256 credit
    );

    event SetInterestRateConfig(
        uint256 indexed reserveId,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    );

    event SetReserveCapacity(uint256 indexed reserveId, uint256 cap);

    event SetReserveFeeRate(uint256 indexed reserveId, uint256 feeRate);

    event ReserveActivated(uint256 indexed reserveId);
    event ReserveDeActivated(uint256 indexed reserveId);
    event ReserveFrozen(uint256 indexed reserveId);
    event ReserveUnFreeze(uint256 indexed reserveId);
    event ReserveBorrowEnabled(uint256 indexed reserveId);
    event ReserveBorrowDisabled(uint256 indexed reserveId);

    struct ReserveStatus {
        uint256 reserveId;
        address underlyingTokenAddress;
        address eTokenAddress;
        address stakingAddress;
        uint256 totalLiquidity;
        uint256 totalBorrows;
        uint256 exchangeRate;
        uint256 borrowingRate;
    }

    struct PositionStatus {
        uint256 reserveId;
        address user;
        uint256 eTokenStaked;
        uint256 eTokenUnStaked;
        uint256 liquidity;
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying eTokens.
     * - E.g. User deposits 100 USDC and gets in return for specific amount of eUSDC
     * the eUSDC amount depends on the exchange rate between USDC and eUSDC
     * @param reserveId The ID of the reserve
     * @param amount The amount of reserve to be deposited
     * @param onBehalfOf The address that will receive the eTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of eTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable returns (uint256);

    /**
     * @dev User redeems eTokens in exchange for the underlying asset
     * E.g. User has 100 eUSDC, and the current exchange rate of eUSDC and USDC is 1:1.1
     * he will receive 110 USDC after redeem 100eUSDC
     * @param reserveId The id of the reserve
     * @param eTokenAmount The amount of eTokens to redeem
     *   - If the amount is type(uint256).max, all of user's eTokens will be redeemed
     * @param to Address that will receive the underlying tokens, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @param receiveNativeETH If receive native ETH, set this param to true
     * @return The underlying token amount user finally receive
     **/
    function redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) external payable returns (uint256);

    function newDebtPosition(uint256 reserveId) external returns (uint256);

    function getCurrentDebt(
        uint256 debtId
    ) external view returns (uint256 currentDebt, uint256 latestBorrowingIndex);

    /**
     * @dev Allows farming users to borrow a specific `amount` of the reserve underlying asset.
     * The user's borrowed tokens is transferred to the vault position contract and is recorded in the user's vault position(VaultPositionManageContract).
     * When debt ratio of user's vault position reach the liquidate limit,
     * the position will be liquidated and repay his debt(borrowed value + accrued interest)
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     */
    function borrow(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external;

    /**
     * @notice Repays borrowed underlying tokens to the reserve pool
     * The user's debt is recorded in the vault position(VaultPositionManageContract).
     * After this function successfully executed, user's debt should be reduced in VaultPositionManageContract.
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     * @return The final amount repaid
     **/
    function repay(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external returns (uint256);

    function getUnderlyingTokenAddress(
        uint256 reserveId
    ) external view returns (address underlyingTokenAddress);

    function getETokenAddress(
        uint256 reserveId
    ) external view returns (address underlyingTokenAddress);

    function getStakingAddress(
        uint256 reserveId
    ) external view returns (address);
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards {
    event RewardsSet(
        address rewardsToken,
        uint256 start,
        uint256 end,
        uint256 total
    );

    event Staked(
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount
    );

    event Withdraw(address indexed user, address indexed to, uint256 amount);

    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 claimed
    );

    struct Reward {
        uint256 startTime;
        uint256 endTime;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function stakedToken() external view returns (IERC20);

    function lendingPool() external view returns (address);

    function totalStaked() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function rewardsTokenListLength() external view returns (uint256);

    function earned(
        address _account,
        address _rewardsToken
    ) external view returns (uint256);

    function stake(uint _amount, address onBehalfOf) external;

    function withdraw(uint _amount, address to) external;

    function withdrawByLendingPool(
        uint _amount,
        address user,
        address to
    ) external;

    function claim() external;
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IVaultFactory {
    event NewVault(
        address indexed token0,
        address indexed token1,
        bool stable,
        address vaultAddress,
        uint256 indexed vaultId
    );

    function vaults(uint256 vaultId) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IExtraInterestBearingToken.sol";
import "../interfaces/ILendingPool.sol";
import "../libraries/helpers/Errors.sol";

/**
 * @title ExtraInterestBearingToken(EToken)
 * @dev Implementation of the interest bearing token(eToken) for the extraFi Lending Pool
 * @author extraFi Team
 */
contract ExtraInterestBearingToken is
    IExtraInterestBearingToken,
    ReentrancyGuard,
    ERC20
{
    using SafeERC20 for IERC20;

    address public immutable lendingPool;
    address public immutable underlyingAsset;

    uint8 private _decimals;

    modifier onlyLendingPool() {
        require(
            msg.sender == lendingPool,
            Errors.LP_CALLER_MUST_BE_LENDING_POOL
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAsset_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;

        require(underlyingAsset_ != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        underlyingAsset = underlyingAsset_;
        lendingPool = msg.sender;
    }

    /**
     * @dev Mints `amount` eTokens to `user`, only the LendingPool Contract can call this function.
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     */
    function mint(
        address user,
        uint256 amount
    ) external override onlyLendingPool nonReentrant {
        _mint(user, amount);
        emit Mint(user, amount);
    }

    /**
     * @dev Burns eTokens from `user` and sends the underlying tokens to `receiverOfUnderlying`
     * Can only be called by the lending pool;
     * The `underlyingTokenAmount` should be calculated based on the current exchange rate in lending pool
     * @param receiverOfUnderlying The address that will receive the underlying tokens
     * @param eTokenAmount The amount of eTokens being burned
     * @param underlyingTokenAmount The amount of underlying tokens being transferred to user
     **/
    function burn(
        address receiverOfUnderlying,
        uint256 eTokenAmount,
        uint256 underlyingTokenAmount
    ) external override onlyLendingPool nonReentrant {
        _burn(msg.sender, eTokenAmount);

        IERC20(underlyingAsset).safeTransfer(
            receiverOfUnderlying,
            underlyingTokenAmount
        );

        emit Burn(
            msg.sender,
            receiverOfUnderlying,
            eTokenAmount,
            underlyingTokenAmount
        );
    }

    /**
     * @dev Mints eTokens to the reserve's fee receiver
     * @param treasury The address of treasury
     * @param amount The amount of tokens getting minted
     */
    function mintToTreasury(
        address treasury,
        uint256 amount
    ) external override onlyLendingPool nonReentrant {
        require(treasury != address(0), "zero address");
        _mint(treasury, amount);
        emit MintToTreasury(treasury, amount);
    }

    /**
     * @dev Transfers the underlying tokens to `target`. Called by the LendingPool to transfer
     * underlying tokens to target in functions like borrow(), withdraw()
     * @param target The recipient of the eTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(
        address target,
        uint256 amount
    ) external override onlyLendingPool nonReentrant returns (uint256) {
        IERC20(underlyingAsset).safeTransfer(target, amount);
        return amount;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/ILendingPool.sol";
import "../interfaces/IVaultFactory.sol";

import "../libraries/types/DataTypes.sol";
import "../libraries/logic/ReserveLogic.sol";
import "../libraries/logic/ReserveKey.sol";
import "../libraries/logic/ETokenDeployer.sol";
import "../libraries/logic/StakingRewardsDeployer.sol";

import "../AddressRegistry.sol";
import "../Payments.sol";

contract LendingPool is ILendingPool, Ownable, Payments, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for DataTypes.ReserveData;

    // Reserve map, each reserve represents a pool that users can deposit/withdraw/borrow/repay
    mapping(uint256 => DataTypes.ReserveData) public reserves;
    uint256 public nextReserveId = 1;

    // Credits is the borrowing power of vaults
    // Each vault should own a specific credits so as to borrow tokens from the pool
    // Only the contract that have enough credits can borrow from lending pool
    // Only owners can set this map to grant new credits to a contract
    // Credits, mapping(reserveId => mapping(contract_address => credits))
    mapping(uint256 => mapping(address => uint256)) public credits;

    // Whitelist of vault contracts
    // only vault contracts in the whitelist can borrow from the lending pool
    mapping(address => bool) public borrowingWhiteList;

    address public immutable addressRegistry;

    // Debt positions, mapping(debtId => DebtPosition)
    mapping(uint256 => DataTypes.DebtPositionData) public debtPositions;
    uint256 public nextDebtPositionId = 1;

    bool public paused = false;

    modifier notPaused() {
        require(!paused, Errors.LP_IS_PAUSED);
        _;
    }

    constructor(address _addressRegistry, address _WETH9) Payments(_WETH9) {
        require(_addressRegistry != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        require(_WETH9 != address(0), Errors.VL_ADDRESS_CANNOT_ZERO);
        addressRegistry = _addressRegistry;
    }

    /// @notice initialize a reserve pool for an asset
    function initReserve(address asset) external onlyOwner notPaused {
        uint256 id = nextReserveId;
        nextReserveId += 1;

        // new a eToken contract
        string memory name = string(
            abi.encodePacked(
                ERC20(asset).name(),
                "(ExtraFi Interest Bearing Token)"
            )
        );
        string memory symbol = string(
            abi.encodePacked("e", ERC20(asset).symbol())
        );
        uint8 decimals = ERC20(asset).decimals();

        address eTokenAddress = ETokenDeployer.deploy(
            name,
            symbol,
            decimals,
            asset,
            id
        );

        DataTypes.ReserveData storage reserveData = reserves[id];
        reserveData.setActive(true);
        reserveData.setBorrowingEnabled(true);

        initReserve(reserveData, asset, eTokenAddress, type(uint256).max, id);

        createStakingPoolForReserve(id);

        emit InitReserve(asset, eTokenAddress, reserveData.stakingAddress, id);
    }

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying eTokens.
     * - E.g. User deposits 100 USDC and gets in return for specific amount of eUSDC
     * the eUSDC amount depends on the exchange rate between USDC and eUSDC
     * @param reserveId The ID of the reserve
     * @param amount The amount of reserve to be deposited
     * @param onBehalfOf The address that will receive the eTokens, same as _msgSender() if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of eTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    )
        public
        payable
        override
        notPaused
        nonReentrant
        returns (uint256 eTokenAmount)
    {
        eTokenAmount = _deposit(reserveId, amount, onBehalfOf);

        // if there is unused ETH, refund it to _msgSender()
        if (msg.value > 0) {
            refundETH();
        }

        // emit event
        emit Deposited(
            reserveId,
            _msgSender(),
            onBehalfOf,
            amount,
            eTokenAmount,
            referralCode
        );
    }

    // deposit assets and stake eToken to the staking contract for rewards
    function depositAndStake(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable notPaused nonReentrant returns (uint256 eTokenAmount) {
        eTokenAmount = _deposit(reserveId, amount, address(this));

        address stakingPool = reserves[reserveId].stakingAddress;
        require(stakingPool != address(0), "Address=0");
        IERC20(getETokenAddress(reserveId)).approve(stakingPool, eTokenAmount);
        IStakingRewards(stakingPool).stake(eTokenAmount, onBehalfOf);

        // if there is unused ETH, refund it to _msgSender()
        if (msg.value > 0) {
            refundETH();
        }

        // emit event
        emit Deposited(
            reserveId,
            _msgSender(),
            onBehalfOf,
            amount,
            eTokenAmount,
            referralCode
        );
    }

    /**
     * @dev User redeems eTokens in exchange for the underlying asset
     * E.g. User has 100 fUSDC, and the current exchange rate of fUSDC and USDC is 1:1.1
     * he will receive 110 USDC after redeem 100fUSDC
     * @param reserveId The id of the reserve
     * @param eTokenAmount The amount of eTokens to redeem
     *   - If the amount is type(uint256).max, all of user's eTokens will be redeemed
     * @param to Address that will receive the underlying tokens, same as _msgSender() if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @param receiveNativeETH If receive native ETH, set this param to true
     * @return The underlying token amount user finally receive
     **/
    function redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    )
        public
        payable
        override
        notPaused
        nonReentrant
        avoidUsingNativeEther
        returns (uint256)
    {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);

        if (eTokenAmount == type(uint256).max) {
            eTokenAmount = IExtraInterestBearingToken(reserve.eTokenAddress)
                .balanceOf(_msgSender());
        }
        // transfer eTokens to this contract
        IERC20(reserve.eTokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            eTokenAmount
        );

        // calculate underlying tokens using eTokens
        uint256 underlyingTokenAmount = _redeem(
            reserveId,
            eTokenAmount,
            to,
            receiveNativeETH
        );

        emit Redeemed(
            reserveId,
            _msgSender(),
            to,
            eTokenAmount,
            underlyingTokenAmount
        );

        return (underlyingTokenAmount);
    }

    // unstake stakedEtoken and redeem etokens
    function unStakeAndWithdraw(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    )
        external
        payable
        notPaused
        nonReentrant
        avoidUsingNativeEther
        returns (uint256)
    {
        address stakingPool = reserves[reserveId].stakingAddress;
        require(stakingPool != address(0), "Address=0");

        IStakingRewards(stakingPool).withdrawByLendingPool(
            eTokenAmount,
            _msgSender(),
            address(this)
        );

        uint256 underlyingTokenAmount = _redeem(
            reserveId,
            eTokenAmount,
            to,
            receiveNativeETH
        );

        emit Redeemed(
            reserveId,
            _msgSender(),
            to,
            eTokenAmount,
            underlyingTokenAmount
        );

        return (underlyingTokenAmount);
    }

    function _deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) internal returns (uint256 eTokenAmount) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        // update states
        reserve.updateState(getTreasury());

        // validate
        reserve.checkCapacity(amount);

        uint256 exchangeRate = reserve.reserveToETokenExchangeRate();

        // Transfer the user's reserve token to eToken contract
        pay(
            reserve.underlyingTokenAddress,
            _msgSender(),
            reserve.eTokenAddress,
            amount
        );

        // Mint eTokens for the user
        eTokenAmount = amount.mul(exchangeRate).div(Precision.FACTOR1E18);

        IExtraInterestBearingToken(reserve.eTokenAddress).mint(
            onBehalfOf,
            eTokenAmount
        );

        // update the interest rate after the deposit
        reserve.updateInterestRates();
    }

    function _redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) internal returns (uint256) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        // update states
        reserve.updateState(getTreasury());

        // calculate underlying tokens using eTokens
        uint256 underlyingTokenAmount = reserve
            .eTokenToReserveExchangeRate()
            .mul(eTokenAmount)
            .div(Precision.FACTOR1E18);

        require(
            underlyingTokenAmount <= reserve.availableLiquidity(),
            Errors.VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH
        );

        if (reserve.underlyingTokenAddress == WETH9 && receiveNativeETH) {
            IExtraInterestBearingToken(reserve.eTokenAddress).burn(
                address(this),
                eTokenAmount,
                underlyingTokenAmount
            );
            unwrapWETH9(underlyingTokenAmount, to);
        } else {
            // burn eTokens and transfer the underlying tokens to receiver
            IExtraInterestBearingToken(reserve.eTokenAddress).burn(
                to,
                eTokenAmount,
                underlyingTokenAmount
            );
        }

        // update the interest rate after the redeem
        reserve.updateInterestRates();

        return (underlyingTokenAmount);
    }

    function newDebtPosition(
        uint256 reserveId
    ) external override notPaused nonReentrant returns (uint256 debtId) {
        DataTypes.ReserveData storage reserve = getReserve(reserveId);
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        require(reserve.getBorrowingEnabled(), Errors.VL_BORROWING_NOT_ENABLED);

        debtId = nextDebtPositionId;
        nextDebtPositionId = nextDebtPositionId + 1;
        DataTypes.DebtPositionData storage newPosition = debtPositions[debtId];
        newPosition.owner = _msgSender();

        reserve.updateState(getTreasury());
        reserve.updateInterestRates();

        newPosition.reserveId = reserveId;
        newPosition.borrowedIndex = reserve.borrowingIndex;
    }

    /**
     * @dev Allows farming users to borrow a specific `amount` of the reserve underlying asset.
     * The user's borrowed tokens is transferred to the vault contract and is recorded in the user's vault position.
     * When debt ratio of user's vault position reach the liquidate limit,
     * the position will be liquidated and repay his debt(borrowed value + accrued interest)
     * @param onBehalfOf The beneficiary of the borrowing, receiving the tokens in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     */
    function borrow(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external override notPaused nonReentrant {
        require(
            borrowingWhiteList[_msgSender()],
            Errors.VL_BORROWING_CALLER_NOT_IN_WHITELIST
        );

        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        require(
            _msgSender() == debtPosition.owner,
            Errors.VL_INVALID_DEBT_OWNER
        );

        DataTypes.ReserveData storage reserve = getReserve(
            debtPosition.reserveId
        );
        require(!reserve.getFrozen(), Errors.VL_RESERVE_FROZEN);
        require(reserve.getBorrowingEnabled(), Errors.VL_BORROWING_NOT_ENABLED);

        // update states
        reserve.updateState(getTreasury());
        updateDebtPosition(debtPosition, reserve.borrowingIndex);

        // only vault contract has credits to borrow tokens
        // when this function is called from the vault contracts,
        // the _msgSender() is the vault's address
        uint256 credit = credits[debtPosition.reserveId][_msgSender()];
        require(amount <= credit, Errors.VL_OUT_OF_CREDITS);
        credits[debtPosition.reserveId][_msgSender()] = credit.sub(amount);

        require(
            amount <= reserve.availableLiquidity(),
            Errors.LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW
        );
        reserve.totalBorrows += amount;
        debtPosition.borrowed += amount;
        // The receiver of the underlying tokens must be the farming contract (_msgSender())
        IExtraInterestBearingToken(reserve.eTokenAddress).transferUnderlyingTo(
            _msgSender(),
            amount
        );

        reserve.updateInterestRates();

        emit Borrow(debtPosition.reserveId, _msgSender(), onBehalfOf, amount);
    }

    /**
     * @notice Repays borrowed underlying tokens to the reserve pool
     * The user's debt is recorded in the vault position(Vault Contract).
     * After this function successfully executed, user's debt should be reduced in Vault Contract.
     * @param onBehalfOf The user who repay debts in his vaultPosition
     * @param debtId The debtPositionId
     * @param amount The amount to be borrowed
     * @return The final amount repaid
     **/
    function repay(
        address onBehalfOf,
        uint256 debtId,
        uint256 amount
    ) external override notPaused nonReentrant returns (uint256) {
        require(
            borrowingWhiteList[_msgSender()],
            Errors.VL_BORROWING_CALLER_NOT_IN_WHITELIST
        );

        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        require(
            _msgSender() == debtPosition.owner,
            Errors.VL_INVALID_DEBT_OWNER
        );

        DataTypes.ReserveData storage reserve = getReserve(
            debtPosition.reserveId
        );

        // update states
        reserve.updateState(getTreasury());
        updateDebtPosition(debtPosition, reserve.borrowingIndex);

        // only vaultPositionManager contract has credits to borrow tokens
        // when this function is called from the vaultPositionManager contracts,
        // the _msgSender() is the contract's address
        uint256 credit = credits[debtPosition.reserveId][_msgSender()];
        credits[debtPosition.reserveId][_msgSender()] = credit.add(amount);

        if (amount > debtPosition.borrowed) {
            amount = debtPosition.borrowed;
        }
        reserve.totalBorrows = reserve.totalBorrows.sub(amount);
        debtPosition.borrowed = debtPosition.borrowed.sub(amount);

        // Transfer the underlying tokens from the vaultPosition to the eToken contract
        IERC20(reserve.underlyingTokenAddress).safeTransferFrom(
            _msgSender(),
            reserve.eTokenAddress,
            amount
        );

        reserve.updateInterestRates();

        emit Repay(debtPosition.reserveId, onBehalfOf, _msgSender(), amount);
        return amount;
    }

    function initReserve(
        DataTypes.ReserveData storage reserveData,
        address underlyingTokenAddress,
        address eTokenAddress,
        uint256 reserveCapacity,
        uint256 id
    ) internal {
        reserveData.underlyingTokenAddress = underlyingTokenAddress;
        reserveData.eTokenAddress = eTokenAddress;
        reserveData.reserveCapacity = reserveCapacity;
        reserveData.id = id;

        reserveData.lastUpdateTimestamp = uint128(block.timestamp);
        reserveData.borrowingIndex = Precision.FACTOR1E18;

        reserveData.reserveFeeRate = 1500; // 15.00%

        // set initial borrowing rate
        // (0%, 0%) -> (80%, 20%) -> (90%, 50%) -> (100%, 150%)
        setBorrowingRateConfig(reserveData, 8000, 2000, 9000, 5000, 15000);
    }

    function createStakingPoolForReserve(uint256 reserveId) internal {
        address eTokenAddress = reserves[reserveId].eTokenAddress;
        require(eTokenAddress != address(0), "Address=0");

        reserves[reserveId].stakingAddress = StakingRewardsDeployer.deploy(
            eTokenAddress
        );

        Ownable(reserves[reserveId].stakingAddress).transferOwnership(owner());
    }

    function updateDebtPosition(
        DataTypes.DebtPositionData storage debtPosition,
        uint256 latestBorrowingIndex
    ) internal {
        debtPosition.borrowed = debtPosition
            .borrowed
            .mul(latestBorrowingIndex)
            .div(debtPosition.borrowedIndex);

        debtPosition.borrowedIndex = latestBorrowingIndex;
    }

    function setBorrowingRateConfig(
        DataTypes.ReserveData storage reserve,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    ) internal {
        // (0%, 0%) -> (utilizationA, borrowingRateA) -> (utilizationB, borrowingRateB) -> (100%, maxBorrowingRate)
        reserve.borrowingRateConfig.utilizationA = uint128(
            Precision.FACTOR1E18.mul(utilizationA).div(Constants.PERCENT_100)
        );

        reserve.borrowingRateConfig.borrowingRateA = uint128(
            Precision.FACTOR1E18.mul(borrowingRateA).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.utilizationB = uint128(
            Precision.FACTOR1E18.mul(utilizationB).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.borrowingRateB = uint128(
            Precision.FACTOR1E18.mul(borrowingRateB).div(Constants.PERCENT_100)
        );
        reserve.borrowingRateConfig.maxBorrowingRate = uint128(
            Precision.FACTOR1E18.mul(maxBorrowingRate).div(
                Constants.PERCENT_100
            )
        );
    }

    function getReserve(
        uint256 reserveId
    ) internal view returns (DataTypes.ReserveData storage reserve) {
        reserve = reserves[reserveId];
        require(reserve.getActive(), Errors.VL_NO_ACTIVE_RESERVE);
    }

    function getTreasury() internal view returns (address treasury) {
        treasury = AddressRegistry(addressRegistry).getAddress(
            AddressId.ADDRESS_ID_TREASURY
        );
        require(treasury != address(0), Errors.VL_TREASURY_ADDRESS_NOT_SET);
    }

    function getVault(
        uint256 vaultId
    ) internal view returns (address vaultAddress) {
        address vaultFactory = AddressRegistry(addressRegistry).getAddress(
            AddressId.ADDRESS_ID_VAULT_FACTORY
        );

        vaultAddress = IVaultFactory(vaultFactory).vaults(vaultId);
        require(vaultAddress != address(0), "Invalid VaultId");
    }

    function getReserveStatus(
        uint256[] calldata reserveIdArr
    ) external view returns (ReserveStatus[] memory statusArr) {
        statusArr = new ReserveStatus[](reserveIdArr.length);

        for (uint256 i = 0; i < reserveIdArr.length; i++) {
            statusArr[i].reserveId = reserveIdArr[i];
            statusArr[i].underlyingTokenAddress = reserves[reserveIdArr[i]]
                .underlyingTokenAddress;
            statusArr[i].eTokenAddress = reserves[reserveIdArr[i]]
                .eTokenAddress;
            statusArr[i].stakingAddress = reserves[reserveIdArr[i]]
                .stakingAddress;
            (statusArr[i].totalLiquidity, statusArr[i].totalBorrows) = reserves[
                reserveIdArr[i]
            ].totalLiquidityAndBorrows();
            statusArr[i].exchangeRate = reserves[reserveIdArr[i]]
                .eTokenToReserveExchangeRate();
            statusArr[i].borrowingRate = reserves[reserveIdArr[i]]
                .borrowingRate();
        }
    }

    function getPositionStatus(
        uint256[] calldata reserveIdArr,
        address user
    ) external view returns (PositionStatus[] memory statusArr) {
        statusArr = new PositionStatus[](reserveIdArr.length);

        for (uint256 i = 0; i < reserveIdArr.length; i++) {
            statusArr[i].reserveId = reserveIdArr[i];
            statusArr[i].user = user;
            statusArr[i].eTokenStaked = IStakingRewards(
                reserves[reserveIdArr[i]].stakingAddress
            ).balanceOf(user);
            statusArr[i].eTokenUnStaked = IERC20(
                reserves[reserveIdArr[i]].eTokenAddress
            ).balanceOf(user);
            statusArr[i].liquidity = statusArr[i]
                .eTokenStaked
                .add(statusArr[i].eTokenUnStaked)
                .mul(reserves[reserveIdArr[i]].eTokenToReserveExchangeRate())
                .div(Precision.FACTOR1E18);
        }
    }

    function getCurrentDebt(
        uint256 debtId
    )
        external
        view
        override
        returns (uint256 currentDebt, uint256 latestBorrowingIndex)
    {
        DataTypes.DebtPositionData storage debtPosition = debtPositions[debtId];
        DataTypes.ReserveData storage reserve = reserves[
            debtPosition.reserveId
        ];

        latestBorrowingIndex = reserve.latestBorrowingIndex();
        currentDebt = debtPosition.borrowed.mul(latestBorrowingIndex).div(
            debtPosition.borrowedIndex
        );
    }

    function getReserveIdOfDebt(
        uint256 debtId
    ) public view override returns (uint256) {
        return debtPositions[debtId].reserveId;
    }

    function getUnderlyingTokenAddress(
        uint256 reserveId
    ) public view override returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.underlyingTokenAddress;
    }

    function getETokenAddress(
        uint256 reserveId
    ) public view override returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.eTokenAddress;
    }

    function getStakingAddress(
        uint256 reserveId
    ) public view override returns (address) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.stakingAddress;
    }

    function exchangeRateOfReserve(
        uint256 reserveId
    ) public view override returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.eTokenToReserveExchangeRate();
    }

    function utilizationRateOfReserve(
        uint256 reserveId
    ) public view override returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return reserve.utilizationRate();
    }

    function borrowingRateOfReserve(
        uint256 reserveId
    ) public view override returns (uint256) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        return uint256(reserve.borrowingRate());
    }

    function totalLiquidityOfReserve(
        uint256 reserveId
    ) public view override returns (uint256 totalLiquidity) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        (totalLiquidity, ) = reserve.totalLiquidityAndBorrows();
    }

    function totalBorrowsOfReserve(
        uint256 reserveId
    ) public view override returns (uint256 totalBorrows) {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        (, totalBorrows) = reserve.totalLiquidityAndBorrows();
    }

    //----------------->>>>>  Set with Admin <<<<<-----------------
    function emergencyPauseAll() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unPauseAll() external onlyOwner {
        paused = false;
        emit UnPaused();
    }

    function enableVaultToBorrow(uint256 vaultId) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);

        borrowingWhiteList[vaultAddr] = true;
        emit EnableVaultToBorrow(vaultId, vaultAddr);
    }

    function disableVaultToBorrow(
        uint256 vaultId
    ) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);

        borrowingWhiteList[vaultAddr] = false;
        emit DisableVaultToBorrow(vaultId, vaultAddr);
    }

    function setCreditsOfVault(
        uint256 vaultId,
        uint256 reserveId,
        uint256 credit
    ) external onlyOwner notPaused {
        address vaultAddr = getVault(vaultId);
        credits[reserveId][vaultAddr] = credit;
        emit SetCreditsOfVault(vaultId, vaultAddr, reserveId, credit);
    }

    function activateReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setActive(true);

        emit ReserveActivated(reserveId);
    }

    function deActivateReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setActive(false);
        emit ReserveDeActivated(reserveId);
    }

    function freezeReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setFrozen(true);
        emit ReserveFrozen(reserveId);
    }

    function unFreezeReserve(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setFrozen(false);
        emit ReserveUnFreeze(reserveId);
    }

    function enableBorrowing(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setBorrowingEnabled(true);
        emit ReserveBorrowEnabled(reserveId);
    }

    function disableBorrowing(uint256 reserveId) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.setBorrowingEnabled(false);
        emit ReserveBorrowDisabled(reserveId);
    }

    function setReserveFeeRate(
        uint256 reserveId,
        uint16 _rate
    ) public onlyOwner notPaused {
        require(_rate <= Constants.PERCENT_100, "invalid percent");
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        reserve.reserveFeeRate = _rate;

        emit SetReserveFeeRate(reserveId, _rate);
    }

    function setBorrowingRateConfig(
        uint256 reserveId,
        uint16 utilizationA,
        uint16 borrowingRateA,
        uint16 utilizationB,
        uint16 borrowingRateB,
        uint16 maxBorrowingRate
    ) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];
        setBorrowingRateConfig(
            reserve,
            utilizationA,
            borrowingRateA,
            utilizationB,
            borrowingRateB,
            maxBorrowingRate
        );

        emit SetInterestRateConfig(
            reserveId,
            utilizationA,
            borrowingRateA,
            utilizationB,
            borrowingRateB,
            maxBorrowingRate
        );
    }

    function setReserveCapacity(
        uint256 reserveId,
        uint256 cap
    ) public onlyOwner notPaused {
        DataTypes.ReserveData storage reserve = reserves[reserveId];

        reserve.reserveCapacity = cap;
        emit SetReserveCapacity(reserveId, cap);
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IExtraInterestBearingToken.sol";
import "../interfaces/IStakingRewards.sol";

contract StakingRewards is Ownable, IStakingRewards {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public immutable override stakedToken;
    address public immutable override lendingPool;

    address[] public rewardTokens;

    mapping(address => bool) public inRewardsTokenList;

    uint256 public override totalStaked;

    mapping(address => Reward) public rewardData;
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public userRewardsClaimable;

    uint internal _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "reentrant call");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyLendingPool() {
        require(lendingPool == msg.sender);
        _;
    }

    modifier updateReward(address user) {
        for (uint i; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            rewardData[rewardToken].rewardPerTokenStored = rewardPerToken(
                rewardToken
            );
            rewardData[rewardToken].lastUpdateTime = Math.min(
                rewardData[rewardToken].endTime,
                block.timestamp
            );

            if (user != address(0)) {
                userRewardsClaimable[user][rewardToken] = earned(
                    user,
                    rewardToken,
                    rewardData[rewardToken].rewardPerTokenStored
                );
                userRewardPerTokenPaid[user][rewardToken] = rewardData[
                    rewardToken
                ].rewardPerTokenStored;
            }
        }
        _;
    }

    /// @notice This contract must be create in lendingPool's `initReserve()`
    constructor(address _stakingToken) {
        stakedToken = IERC20(_stakingToken);
        lendingPool = msg.sender;
    }

    function rewardPerToken(address rewardToken) public view returns (uint) {
        if (block.timestamp <= rewardData[rewardToken].startTime) {
            // new rewards not start
            return rewardData[rewardToken].rewardPerTokenStored;
        }

        uint256 dt = Math.min(
            rewardData[rewardToken].endTime,
            block.timestamp
        ) - (rewardData[rewardToken].lastUpdateTime);

        if (dt == 0 || totalStaked == 0) {
            return rewardData[rewardToken].rewardPerTokenStored;
        }

        return
            rewardData[rewardToken].rewardPerTokenStored +
            (rewardData[rewardToken].rewardRate * dt * 1e18) /
            totalStaked;
    }

    function earned(
        address user,
        address rewardToken
    ) public view override returns (uint) {
        uint256 curRewardPerToken = rewardPerToken(rewardToken);

        return earned(user, rewardToken, curRewardPerToken);
    }

    function earned(
        address user,
        address rewardToken,
        uint256 curRewardPerToken
    ) internal view returns (uint) {
        uint256 d = curRewardPerToken -
            userRewardPerTokenPaid[user][rewardToken];

        return
            (balanceOf[user] * d) /
            1e18 +
            userRewardsClaimable[user][rewardToken];
    }

    function setReward(
        address rewardToken,
        uint256 startTime,
        uint256 endTime,
        uint256 totalRewards
    ) public onlyOwner nonReentrant updateReward(address(0)) {
        require(startTime < endTime, "start must lt end");
        require(rewardData[rewardToken].endTime < block.timestamp, "not end");

        if (!inRewardsTokenList[rewardToken]) {
            rewardTokens.push(rewardToken);
            inRewardsTokenList[rewardToken] = true;
        }

        rewardData[rewardToken].startTime = startTime;
        rewardData[rewardToken].endTime = endTime;
        rewardData[rewardToken].lastUpdateTime = block.timestamp;
        rewardData[rewardToken].rewardRate =
            totalRewards /
            (endTime - startTime);

        if (block.timestamp > startTime && totalStaked > 0) {
            uint256 dt = block.timestamp - startTime;

            rewardData[rewardToken].rewardPerTokenStored +=
                (rewardData[rewardToken].rewardRate * dt * 1e18) /
                totalStaked;
        }

        if (block.timestamp > startTime && totalStaked == 0) {
            // If this happens, there is no staked tokens from startTime to now
            // The rewards in this period should be removed
            uint256 dt = block.timestamp - startTime;
            totalRewards -= rewardData[rewardToken].rewardRate * dt;
        }

        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalRewards
        );

        emit RewardsSet(rewardToken, startTime, endTime, totalRewards);
    }

    /**
     * @dev Stake `amount` of assets to this contract
     * @param amount The amount of assets to be staked
     * @param onBehalfOf The address that will receive the staked position, same as msg.sender if the user
     *   wants to receive them on his own wallet.
     **/
    function stake(
        uint amount,
        address onBehalfOf
    ) external override nonReentrant updateReward(onBehalfOf) {
        require(amount > 0, "amount = 0");

        stakedToken.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[onBehalfOf] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, onBehalfOf, amount);
    }

    /**
     * @dev Withdraw `amount` of staked assets
     * @param amount The amount of assets to withdraw
     * @param to The address that will receive the staked assets, same as msg.sender if the user
     *   wants to receive them on his own wallet.
     **/
    function withdraw(
        uint amount,
        address to
    ) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "amount = 0");

        balanceOf[msg.sender] -= amount;
        totalStaked -= amount;

        require(stakedToken.transfer(to, amount), "transfer failed");

        emit Withdraw(msg.sender, to, amount);
    }

    /**
     * @dev Withdraw `amount` of staked assets called by lendingPool
     * only lendingPool can call this function in `unstakeAndWithdraw()` of LendingPool
     * @param amount The amount of assets to withdraw
     * @param user The user of the staked position
     * @param to The address that will receive the staked assets, same as msg.sender if the user
     *   wants to receive them on his own wallet.
     **/
    function withdrawByLendingPool(
        uint amount,
        address user,
        address to
    ) external override onlyLendingPool nonReentrant updateReward(user) {
        require(amount > 0, "amount = 0");

        balanceOf[user] -= amount;
        totalStaked -= amount;

        require(stakedToken.transfer(to, amount), "transfer falied");

        emit Withdraw(user, to, amount);
    }

    function claim() external override nonReentrant updateReward(msg.sender) {
        for (uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 claimable = userRewardsClaimable[msg.sender][rewardToken];
            if (claimable > 0) {
                userRewardsClaimable[msg.sender][rewardToken] = 0;
                require(
                    IERC20(rewardToken).transfer(msg.sender, claimable),
                    "transfer failed"
                );
                emit RewardPaid(msg.sender, rewardToken, claimable);
            }
        }
    }

    function update() external updateReward(address(0)) onlyOwner {}

    function rewardsTokenListLength() external view override returns (uint256) {
        return rewardTokens.length;
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

library Constants {
    uint256 internal constant PERCENT_100 = 10000;

    uint256 internal constant PROTOCOL_FEE_TYPE_WITHDRAW = 1;
    uint256 internal constant PROTOCOL_FEE_TYPE_LIQUIDATE = 2;
    uint256 internal constant PROTOCOL_FEE_TYPE_COMPOUND = 3;
    uint256 internal constant PROTOCOL_FEE_TYPE_RANGESTOP = 4;
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

library AddressId {
    uint256 constant ADDRESS_ID_WETH9 = 1;
    uint256 constant ADDRESS_ID_UNI_V3_FACTORY = 2;
    uint256 constant ADDRESS_ID_UNI_V3_NONFUNGIBLE_POSITION_MANAGER = 3;
    uint256 constant ADDRESS_ID_UNI_V3_SWAP_ROUTER = 4;
    uint256 constant ADDRESS_ID_VELO_ROUTER = 5;
    uint256 constant ADDRESS_ID_VELO_FACTORY = 6;
    uint256 constant ADDRESS_ID_VAULT_POSITION_MANAGER = 7;
    uint256 constant ADDRESS_ID_SWAP_EXECUTOR_MANAGER = 8;
    uint256 constant ADDRESS_ID_LENDING_POOL = 9;
    uint256 constant ADDRESS_ID_VAULT_FACTORY = 10;
    uint256 constant ADDRESS_ID_TREASURY = 11;
    uint256 constant ADDRESS_ID_VE_TOKEN = 12;

    uint256 constant ADDRESS_ID_VELO_VAULT_DEPLOYER = 101;
    uint256 constant ADDRESS_ID_VELO_VAULT_INITIALIZER = 102;
    uint256 constant ADDRESS_ID_VELO_VAULT_POSITION_LOGIC = 103;
    uint256 constant ADDRESS_ID_VELO_VAULT_REWARDS_LOGIC = 104;
    uint256 constant ADDRESS_ID_VELO_VAULT_OWNER_ACTIONS = 105;
    uint256 constant ADDRESS_ID_VELO_SWAP_PATH_MANAGER = 106;
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - VT = Vault
 *  - LP = LendingPool
 *  - P = Pausable
 */
library Errors {
    //contract specific errors
    string internal constant VL_TRANSACTION_TOO_OLD = "0"; // 'Transaction too old'
    string internal constant VL_NO_ACTIVE_RESERVE = "1"; // 'Action requires an active reserve'
    string internal constant VL_RESERVE_FROZEN = "2"; // 'Action cannot be performed because the reserve is frozen'
    string internal constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "3"; // 'The current liquidity is not enough'
    string internal constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "4"; // 'User cannot withdraw more than the available balance'
    string internal constant VL_TRANSFER_NOT_ALLOWED = "5"; // 'Transfer cannot be allowed.'
    string internal constant VL_BORROWING_NOT_ENABLED = "6"; // 'Borrowing is not enabled'
    string internal constant VL_INVALID_DEBT_OWNER = "7"; // 'Invalid interest rate mode selected'
    string internal constant VL_BORROWING_CALLER_NOT_IN_WHITELIST = "8"; // 'The collateral balance is 0'
    string internal constant VL_DEPOSIT_TOO_MUCH = "9"; // 'Deposit too much'
    string internal constant VL_OUT_OF_CAPACITY = "10"; // 'There is not enough collateral to cover a new borrow'
    string internal constant VL_OUT_OF_CREDITS = "11"; // 'Out of credits, there is not enough credits to borrow'
    string internal constant VL_PERCENT_TOO_LARGE = "12"; // 'Percentage too large'
    string internal constant VL_ADDRESS_CANNOT_ZERO = "13"; // vault address cannot be zero
    string internal constant VL_VAULT_UN_ACTIVE = "14";
    string internal constant VL_VAULT_FROZEN = "15";
    string internal constant VL_VAULT_BORROWING_DISABLED = "16";
    string internal constant VL_NOT_WETH9 = "17";
    string internal constant VL_INSUFFICIENT_WETH9 = "18";
    string internal constant VL_INSUFFICIENT_TOKEN = "19";
    string internal constant VL_LIQUIDATOR_NOT_IN_WHITELIST = "20";
    string internal constant VL_COMPOUNDER_NOT_IN_WHITELIST = "21";
    string internal constant VL_VAULT_ALREADY_INITIALIZED = "22";
    string internal constant VL_TREASURY_ADDRESS_NOT_SET = "23";

    string internal constant VT_INVALID_RESERVE_ID = "40"; // invalid reserve id
    string internal constant VT_INVALID_POOL = "41"; // invalid uniswap v3 pool
    string internal constant VT_INVALID_VAULT_POSITION_MANAGER = "42"; // invalid vault position manager
    string internal constant VT_VAULT_POSITION_NOT_ACTIVE = "43"; // vault position is not active
    string internal constant VT_VAULT_POSITION_AUTO_COMPOUND_NOT_ENABLED = "44"; // 'auto compound not enabled'
    string internal constant VT_VAULT_POSITION_ID_INVALID = "45"; // 'VaultPositionId invalid'
    string internal constant VT_VAULT_PAUSED = "46"; // 'vault is paused'
    string internal constant VT_VAULT_FROZEN = "47"; // 'vault is frozen'
    string internal constant VT_VAULT_CALLBACK_INVALID_SENDER = "48"; // 'callback must be initiate by the vault self
    string internal constant VT_VAULT_DEBT_RATIO_TOO_LOW_TO_LIQUIDATE = "49"; // 'debt ratio haven't reach liquidate ratio'
    string internal constant VT_VAULT_POSITION_MANAGER_INVALID = "50"; // 'invalid vault manager'
    string internal constant VT_VAULT_POSITION_RANGE_STOP_DISABLED = "60"; // 'vault positions' range stop is disabled'
    string internal constant VT_VAULT_POSITION_RANGE_STOP_PRICE_INVALID = "61"; // 'invalid range stop price'
    string internal constant VT_VAULT_POSITION_OUT_OF_MAX_LEVERAGE = "62";
    string internal constant VT_VAULT_POSITION_SHARES_INVALID = "63";

    string internal constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "80"; // 'There is not enough liquidity available to borrow'
    string internal constant LP_CALLER_MUST_BE_LENDING_POOL = "81"; // 'Caller must be lending pool contract'
    string internal constant LP_BORROW_INDEX_OVERFLOW = "82"; // 'The borrow index overflow'
    string internal constant LP_IS_PAUSED = "83"; // lending pool is paused
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "../../lendingpool/ExtraInterestBearingToken.sol";

library ETokenDeployer {
    function deploy(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address underlyingAsset_,
        uint256 id
    ) external returns (address) {
        address eTokenAddress = address(
            new ExtraInterestBearingToken{
                salt: keccak256(
                    abi.encode(
                        underlyingAsset_,
                        id,
                        "ExtraInterestBearingToken"
                    )
                )
            }(name_, symbol_, decimals_, underlyingAsset_)
        );

        return eTokenAddress;
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../libraries/Precision.sol";

import "../types/DataTypes.sol";

library InterestRateUtils {
    using SafeMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Calculate the borrowing rate at specific utilization
     * @param config The interest rate config
     * @param utilizationRate The current utilization of the reserve
     * @return borrowingRate The borrowing interest rate of the reserve
     **/
    function calculateBorrowingRate(
        DataTypes.InterestRateConfig storage config,
        uint256 utilizationRate
    ) internal view returns (uint256 borrowingRate) {
        if (utilizationRate <= config.utilizationA) {
            if (config.utilizationA == 0) {
                return config.borrowingRateA;
            }
            borrowingRate = utilizationRate.mul(config.borrowingRateA).div(
                config.utilizationA
            );
        } else if (utilizationRate <= config.utilizationB) {
            if (config.utilizationB == config.utilizationA) {
                return config.borrowingRateB;
            }
            borrowingRate = uint256(config.borrowingRateB)
                .sub(config.borrowingRateA)
                .mul(utilizationRate.sub(config.utilizationA))
                .div(uint256(config.utilizationB).sub(config.utilizationA))
                .add(config.borrowingRateA);
        } else {
            if (config.utilizationB >= Precision.FACTOR1E18) {
                return config.maxBorrowingRate;
            }
            borrowingRate = uint256(config.maxBorrowingRate)
                .sub(config.borrowingRateB)
                .mul(utilizationRate.sub(config.utilizationB))
                .div(Precision.FACTOR1E18.sub(config.utilizationB))
                .add(config.borrowingRateB);
        }
        return borrowingRate;
    }

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta
     **/

    function calculateLinearInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(
            uint256(lastUpdateTimestamp)
        );

        return
            rate.mul(timeDifference).div(SECONDS_PER_YEAR).add(
                Precision.FACTOR1E18
            );
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
     *
     * @param rate The interest rate
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint128 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

        if (exp == 0) {
            return Precision.FACTOR1E18;
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate.div(SECONDS_PER_YEAR);

        uint256 basePowerTwo = ratePerSecond.mul(ratePerSecond).div(
            Precision.FACTOR1E18
        );

        uint256 basePowerThree = basePowerTwo.mul(ratePerSecond).div(
            Precision.FACTOR1E18
        );

        uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
        uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(
            basePowerThree
        ) / 6;

        return
            (Precision.FACTOR1E18)
                .add(ratePerSecond.mul(exp))
                .add(secondTerm)
                .add(thirdTerm);
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint128 lastUpdateTimestamp
    ) internal view returns (uint256) {
        return
            calculateCompoundedInterest(
                rate,
                lastUpdateTimestamp,
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

library ReserveKey {
    /// @dev Returns the key of the reserve in the lending pool
    function compute(
        address reserve,
        address eTokenAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(reserve, eTokenAddress));
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../libraries/Precision.sol";

import "../../interfaces/IExtraInterestBearingToken.sol";

import "./InterestRateUtils.sol";
import "../types/DataTypes.sol";
import "../helpers/Errors.sol";
import "../Constants.sol";

library ReserveLogic {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Get the total liquidity and borrowed out portion,
     * where the total liquidity is the sum of available liquidity and borrowed out portion.
     * @param reserve The Reserve Object
     */
    function totalLiquidityAndBorrows(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256 total, uint256 borrows) {
        borrows = borrowedLiquidity(reserve);
        total = availableLiquidity(reserve).add(borrows);
    }

    /**
     * @dev Get the available liquidity not borrowed out.
     * @param reserve The Reserve Object
     * @return liquidity
     */ function availableLiquidity(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256 liquidity) {
        liquidity = IERC20(reserve.underlyingTokenAddress).balanceOf(
            reserve.eTokenAddress
        );
    }

    /**
     * @dev Get the liquidity borrowed out.
     * @param reserve The Reserve Object
     * @return liquidity
     */
    function borrowedLiquidity(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256 liquidity) {
        liquidity = latestBorrowingIndex(reserve).mul(reserve.totalBorrows).div(
                reserve.borrowingIndex
            );
    }

    /**
     * @dev Get the utilization of the reserve.
     * @param reserve The Reserve Object
     * @return rate
     */
    function utilizationRate(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256 rate) {
        (uint256 total, uint256 borrows) = totalLiquidityAndBorrows(reserve);

        if (total > 0) {
            rate = borrows.mul(Precision.FACTOR1E18).div(total);
        }

        return rate;
    }

    /**
     * @dev Get the borrowing interest rate of the reserve.
     * @param reserve The Reserve Object
     * @return rate
     */ function borrowingRate(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256 rate) {
        rate = InterestRateUtils.calculateBorrowingRate(
            reserve.borrowingRateConfig,
            utilizationRate(reserve)
        );
    }

    /**
     * @dev Exchange Rate from reserve liquidity to eToken
     * @param reserve The Reserve Object
     * @return The Exchange Rate
     */
    function reserveToETokenExchangeRate(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256) {
        (uint256 totalLiquidity, ) = totalLiquidityAndBorrows(reserve);
        uint256 totalETokens = IERC20(reserve.eTokenAddress).totalSupply();

        if (totalETokens == 0 || totalLiquidity == 0) {
            return Precision.FACTOR1E18;
        }
        return totalETokens.mul(Precision.FACTOR1E18).div(totalLiquidity);
    }

    /**
     * @dev Exchange Rate from eToken to reserve liquidity
     * @param reserve The Reserve Object
     * @return The Exchange Rate
     */
    function eTokenToReserveExchangeRate(
        DataTypes.ReserveData storage reserve
    ) external view returns (uint256) {
        (uint256 totalLiquidity, ) = totalLiquidityAndBorrows(reserve);
        uint256 totalETokens = IERC20(reserve.eTokenAddress).totalSupply();

        if (totalETokens == 0 || totalLiquidity == 0) {
            return Precision.FACTOR1E18;
        }
        return totalLiquidity.mul(Precision.FACTOR1E18).div(totalETokens);
    }

    /**
     * @dev Returns the borrowing index for the reserve
     * @param reserve The reserve object
     * @return The borrowing index.
     **/
    function latestBorrowingIndex(
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256) {
        if (reserve.lastUpdateTimestamp == uint128(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.borrowingIndex;
        }

        return
            reserve
                .borrowingIndex
                .mul(
                    InterestRateUtils.calculateCompoundedInterest(
                        reserve.currentBorrowingRate,
                        reserve.lastUpdateTimestamp
                    )
                )
                .div(Precision.FACTOR1E18);
    }

    function checkCapacity(
        DataTypes.ReserveData storage reserve,
        uint256 depositAmount
    ) internal view {
        (uint256 totalLiquidity, ) = totalLiquidityAndBorrows(reserve);

        require(
            totalLiquidity.add(depositAmount) <= reserve.reserveCapacity,
            Errors.VL_OUT_OF_CAPACITY
        );
    }

    /**
     * @dev Updates the the variable borrow index.
     * @param reserve the reserve object
     **/
    function updateState(
        DataTypes.ReserveData storage reserve,
        address treasury
    ) internal {
        uint256 previousDebt = reserve.totalBorrows;
        _updateIndexes(reserve);

        _mintToTreasury(reserve, previousDebt, reserve.totalBorrows, treasury);
    }

    /**
     * @dev Updates the interest rate of the reserve pool.
     * @param reserve the reserve object
     **/
    function updateInterestRates(
        DataTypes.ReserveData storage reserve
    ) internal {
        reserve.currentBorrowingRate = InterestRateUtils.calculateBorrowingRate(
            reserve.borrowingRateConfig,
            utilizationRate(reserve)
        );
    }

    /**
     * @dev Updates the reserve indexes and the timestamp of the update
     * @param reserve The reserve object
     **/
    function _updateIndexes(DataTypes.ReserveData storage reserve) internal {
        uint256 newBorrowingIndex = reserve.borrowingIndex;
        uint256 newTotalBorrows = reserve.totalBorrows;

        if (reserve.totalBorrows > 0) {
            newBorrowingIndex = latestBorrowingIndex(reserve);
            newTotalBorrows = newBorrowingIndex.mul(reserve.totalBorrows).div(
                reserve.borrowingIndex
            );

            require(
                newBorrowingIndex <= type(uint128).max,
                Errors.LP_BORROW_INDEX_OVERFLOW
            );

            reserve.borrowingIndex = newBorrowingIndex;
            reserve.totalBorrows = newTotalBorrows;
            reserve.lastUpdateTimestamp = uint128(block.timestamp);
        }
    }

    /**
     * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
     * specific asset.
     * @param reserve The reserve reserve to be updated
     * @param previousDebt The previous debt
     * @param currentDebt The current debt
     **/
    function _mintToTreasury(
        DataTypes.ReserveData storage reserve,
        uint256 previousDebt,
        uint256 currentDebt,
        address treasury
    ) internal {
        uint256 feeRate = reserve.reserveFeeRate;

        if (feeRate == 0) {
            return;
        }

        //debt accrued is the current debt minus the debt at the last update
        uint256 totalDebtAccrued = currentDebt.sub(previousDebt);
        uint256 reserveValueAccrued = totalDebtAccrued.mul(feeRate).div(
            Constants.PERCENT_100
        );
        // reserve value to eTokens
        uint256 exchangeRate = reserveToETokenExchangeRate(reserve);
        uint256 feeInEToken = reserveValueAccrued.mul(exchangeRate).div(
            Precision.FACTOR1E18
        );

        if (feeInEToken != 0) {
            IExtraInterestBearingToken(reserve.eTokenAddress).mintToTreasury(
                treasury,
                feeInEToken
            );
        }
    }

    /**
     * @dev Sets the active state of the reserve
     * @param reserve The reserve
     * @param state The true or false state
     **/
    function setActive(
        DataTypes.ReserveData storage reserve,
        bool state
    ) internal {
        reserve.flags.isActive = state;
    }

    /**
     * @dev Gets the active state of the reserve
     * @param reserve The reserve
     * @return The true or false state
     **/
    function getActive(
        DataTypes.ReserveData storage reserve
    ) internal view returns (bool) {
        return reserve.flags.isActive;
    }

    /**
     * @dev Sets the frozen state of the reserve
     * @param reserve The reserve
     * @param state The true or false state
     **/
    function setFrozen(
        DataTypes.ReserveData storage reserve,
        bool state
    ) internal {
        reserve.flags.frozen = state;
    }

    /**
     * @dev Gets the frozen state of the reserve
     * @param reserve The reserve
     * @return The true or false state
     **/
    function getFrozen(
        DataTypes.ReserveData storage reserve
    ) internal view returns (bool) {
        return reserve.flags.frozen;
    }

    /**
     * @dev Sets the borrowing enable state of the reserve
     * @param reserve The reserve
     * @param state The true or false state
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveData storage reserve,
        bool state
    ) internal {
        reserve.flags.borrowingEnabled = state;
    }

    /**
     * @dev Gets the borrowing enable state of the reserve
     * @param reserve The reserve
     * @return The true or false state
     **/
    function getBorrowingEnabled(
        DataTypes.ReserveData storage reserve
    ) internal view returns (bool) {
        return reserve.flags.borrowingEnabled;
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "../../lendingpool/StakingRewards.sol";

library StakingRewardsDeployer {
    function deploy(address stakingToken) external returns (address) {
        address stakingAddress = address(new StakingRewards(stakingToken));

        return stakingAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

library Precision {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant FACTOR1E18 = 1e18;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    struct DebtPositionData {
        uint256 reserveId;
        address owner;
        uint256 borrowed;
        uint256 borrowedIndex;
    }

    struct VaultPositionData {
        // manager of the position, who can adjust the position
        address manager;
        // tokenId of the v3 NFT position
        uint256 v3TokenId;
        // The debt positionId for token0
        uint256 debtPositionId0;
        // The debt share for token0
        uint256 debtShare0;
        // The debt positionId for token1
        uint256 debtPositionId1;
        // The debt share for token1
        uint256 debtShare1;
        // Total shares of this position
        uint256 totalShares;
    }

    // Interest Rate Config
    // The utilization rate and borrowing rate are expressed in RAY
    // utilizationB must gt utilizationA
    struct InterestRateConfig {
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationA;
        // The borrowing rate at utilization_rate_a
        uint128 borrowingRateA;
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationB;
        // The borrowing rate at utilization_rate_b
        uint128 borrowingRateB;
        // the max borrowing rate while the utilization is 100%
        uint128 maxBorrowingRate;
    }

    struct ReserveData {
        // variable borrow index.
        uint256 borrowingIndex;
        // the current borrow rate.
        uint256 currentBorrowingRate;
        // the total borrows of the reserve at a variable rate. Expressed in the currency decimals
        uint256 totalBorrows;
        // underlying token address
        address underlyingTokenAddress;
        // eToken address
        address eTokenAddress;
        // staking address
        address stakingAddress;
        // the capacity of the reserve pool
        uint256 reserveCapacity;
        // borrowing rate config
        InterestRateConfig borrowingRateConfig;
        // the id of the reserve. Represents the position in the list of the reserves
        uint256 id;
        uint128 lastUpdateTimestamp;
        // reserve fee charged, percent of the borrowing interest that is put into the treasury.
        uint16 reserveFeeRate;
        Flags flags;
    }

    struct Flags {
        bool isActive; // set to 1 if the reserve is properly configured
        bool frozen; // set to 1 if reserve is frozen, only allows repays and withdraws, but not deposits or new borrowings
        bool borrowingEnabled; // set to 1 if borrowing is enabled, allow borrowing from this pool
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IWETH9.sol";
import "./libraries/TransferHelper.sol";

import "./libraries/helpers/Errors.sol";

abstract contract Payments {
    address public immutable WETH9;

    modifier avoidUsingNativeEther() {
        require(msg.value == 0, "avoid using native ether");
        _;
    }

    constructor(address _WETH9) {
        WETH9 = _WETH9;
    }

    receive() external payable {
        require(msg.sender == WETH9, Errors.VL_NOT_WETH9);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) internal {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, Errors.VL_INSUFFICIENT_WETH9);

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }

    function refundETH() internal {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WETH9 && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            require(
                IWETH9(WETH9).transfer(recipient, value),
                "transfer failed"
            );
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}