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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "CasinoBase" Contract
 * @author Stefan Stoll, [email protected]
 * @dev This contract enables users to interact with Transpare's casino and sports betting services.
 *      It manages users' deposits, withdrawals, and betting actions.
 *      The contract implements various safety mechanisms, such as the safety stop feature, to enhance the security of funds and operations.
 *      Further, the contract is designed to be upgradeable, allowing the addition/removal of game contracts and adjustment of key parameters like house edge.
 *      Note: Think of it like a casino headquarters.
 */

pragma solidity ^0.8.0;

// Audited OpenZeppelin libraries for secure token transfers, reentrancy protection, and safety mechanism.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Liquidity pool functionality
import "./LiquidityProvider.sol";

// Sports integration
import "./Sports.sol";

// Casino Game contracts access management
import "./CasinoGameContracts.sol";

// Protective layer against potential exploits.
import "./Defense.sol";

contract CasinoBase is LiquidityProvider, Defense, CasinoGameContracts, Sports, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public usdtToken;

    // Public state variables
    uint16 public houseEdge; // House edge of the casino (% value)
    uint16 public maxBetPercentage; // Maximum bet amount (% of casino LP funds)
    address public transpareWallet; // Wallet managed by Transpare
    uint256 public casinoUSDTUserBalance; // Total amount of USDT in user balances

    // Stores all active games
    struct ActiveCasinoBet {
        address user;
        address casinoGameContract;
        uint256 betAmount;
        bytes betParameters;
        uint256 betPlacedAt;
    }

    // Mappings to manage user balances, liquidity provider balances, and active games
    mapping(address => uint256) public userBalance; // User addresses to their deposited balances
    mapping(uint256 => ActiveCasinoBet) public activeCasinoBets; // Nonces to active game data

    // Events to log important contract actions
    event CasinoBetPlaced(
        uint256 nonce, 
        address indexed indexedUser, address user, 
        address indexed indexedCasinoGameContract, address casinoGameContract, 
        uint256 indexed indexedBetAmount, uint256 betAmount,
        bytes betParameters
    );
    event CasinoBetResult(
        uint256 nonce, 
        address indexed indexedUser, address user, 
        address indexed indexedCasinoGameContract, address casinoGameContract, 
        uint256 betAmount, 
        uint256 indexed indexedMultiplier, uint256 multiplier
    );
    event Deposit(
        address indexed indexedUser, address user,
        uint256 indexed indexedDepositAmount, uint256 depositAmount
    );
    event Withdrawal(
        address indexed indexedUser, address user, 
        uint256 indexed indexedWithdrawAmount, uint256 withdrawAmount
    );
    event ManualGameSettlement(uint256 indexed nonce, address indexed user, uint256 indexed betAmount);
    event HouseEdgeUpdated(uint256 newHouseEdge);
    event MaxBetPercentageUpdated(uint256 newMaxBetPercentage);
    event TranspareWalletUpdated(address newTranspareWallet);

    /**
     * @notice Constructor to set up initial configurations.
     * @param _usdtToken Address of the USDT token contract.
     * @param _houseEdge Initial house edge value for the casino.
     * @param _transpareWallet Wallet address managed by Transpare.
     */
    constructor(
        IERC20 _usdtToken,
        uint16 _maxBetPercentage,
        uint16 _houseEdge,
        address _transpareWallet
    ) {
        require(address(_usdtToken) != address(0), "Invalid USDT token address");
        require(_maxBetPercentage >= 0 && _maxBetPercentage <= 1000, "Max bet not 0 <= x <= 1000");
        require(_houseEdge >= 0 && _houseEdge <= 1000, "House edge not 0 <= x <= 1000");
        require(_transpareWallet != address(0), "Invalid Transpare wallet");
        
        usdtToken = _usdtToken;
        maxBetPercentage = _maxBetPercentage;
        houseEdge = _houseEdge;
        transpareWallet = _transpareWallet;
    }

    /**
     * @notice Allows users to deposit USDT into the casino.
     * @param _depositAmount Amount of USDT to deposit (6 decimals).
     */
    function deposit(uint256 _depositAmount) external whenNotPaused nonReentrant whenNotRestricted {
        require(_depositAmount > 0, "Deposit should be > 0");

        usdtToken.safeTransferFrom(msg.sender, address(this), _depositAmount);
        userBalance[msg.sender] += _depositAmount;
        casinoUSDTUserBalance += _depositAmount;

        emit Deposit(msg.sender, msg.sender, _depositAmount, _depositAmount);
    }

    /**
     * @notice Allows users to withdraw USDT from the casino.
     * @dev Bad actors will be prevented from withdrawing by the team in the 
     * unlikely case there was an exploit in the code and they were to take advantage
     * @param _withdrawAmount Amount of USDT to withdraw (6 decimals).
     */
    function withdraw(uint256 _withdrawAmount) external whenNotPaused nonReentrant whenNotRestricted {
        require(userBalance[msg.sender] >= _withdrawAmount, "Insufficient balance");
        require(_withdrawAmount > 0, "Amount should be > than 0");

        if (isSlidingWindowActive[WindowType.Casino]) {
            // Check sliding window defensive mechanism
            uint256 _proposedBalance = usdtToken.balanceOf(address(this)) - _withdrawAmount;
            _checkSlidingWindow(WindowType.Casino, msg.sender, _proposedBalance);
        }

        // Note From the Author:
        // if (highRiskMode) acts as the contracts liquidity protector and
        // is only activated when the contract is at extremely high risk conditions (<0.1% of the time)
        // If this occurs, the team has to check and make sure the contract
        // isn't being exploited. highRiskMode should almost never be activated and if
        // it is, the team will disable it asap. When highRiskMode is activated,
        // withdrawals are capped at a safe amount. Check docs for more info.
        if (highRiskMode) {
            // check if withdrawal follows withdrawal limits during a high risk period
            // withdraw will revert if it doesn't
            _withdrawFromHighRiskPool(_withdrawAmount);
        }

        // Normal flow (unlimited withdrawal amounts)
        userBalance[msg.sender] -= _withdrawAmount;
        casinoUSDTUserBalance -= _withdrawAmount;
        usdtToken.safeTransfer(msg.sender, _withdrawAmount);

        emit Withdrawal(msg.sender, msg.sender, _withdrawAmount, _withdrawAmount);
    }

    function addLiquidity(uint256 _depositInUSDT) external whenNotPaused nonReentrant whenNotRestricted {
        require(highRiskMode == false, "High risk on, try again soon");
        require(userBalance[msg.sender] >= _depositInUSDT, "Insufficient user balance");
        require(_depositInUSDT > 0, "Amount should be greater than 0");
        
        userBalance[msg.sender] -= _depositInUSDT;
        casinoUSDTUserBalance -= _depositInUSDT;

        _addLiquidity(_depositInUSDT);
    }

    function removeLiquidity(uint256 _withdrawalInLP) external whenNotPaused nonReentrant whenNotRestricted {
        require(highRiskMode == false, "High risk on, try again soon");
        require(_withdrawalInLP > 0, "Amount should be greater than 0");
        
        uint256 _withdrawalInUSDT = _removeLiquidity(_withdrawalInLP);

        if (isSlidingWindowActive[WindowType.LiquidityPool]) {
            // Check sliding window defensive mechanism
            uint256 _proposedBalance = casinoUSDTLiquidityBalance - _withdrawalInUSDT;
            _checkSlidingWindow(WindowType.LiquidityPool, msg.sender, _proposedBalance);
            // Check again to see if it updated
            require(highRiskMode == false, "High risk on, try again soon");
        }
        
        userBalance[msg.sender] += _withdrawalInUSDT;
        casinoUSDTUserBalance += _withdrawalInUSDT;
    }

    /**
     * @notice Allows users to place a casino bet
     * @dev Only authenticated game contract can be called.
     * @param _casinoGameContract Address of the game contract.
     * @param _betAmount Amount of USDT to bet.
     * @param _betParameters Data required to place the bet.
     */
    function placeCasinoBet(
        address _casinoGameContract,
        uint256 _betAmount,
        bytes calldata _betParameters
    ) external whenNotPaused nonReentrant whenNotRestricted {
        require(_betParameters.length <= maxBytesLength, "Bet parameters too long");
        require(casinoGameContracts[_casinoGameContract], "Game contract not authenticated");
        require(userBalance[msg.sender] >= _betAmount, "Insufficient balance");
        require(_betAmount > 0, "Bet should be greater than 0");
        require(_betAmount <= (casinoUSDTLiquidityBalance * maxBetPercentage) / 1000, "Bet amount too high");

        userBalance[msg.sender] -= _betAmount;
        casinoUSDTUserBalance -= _betAmount;

        uint256 _nonce;

        try ICasinoGameContract(_casinoGameContract).play(_betParameters) returns (
            uint256 nonce
        ) {
            _nonce = nonce;

            activeCasinoBets[_nonce] = ActiveCasinoBet({
                user: msg.sender,
                casinoGameContract: _casinoGameContract,
                betAmount: _betAmount,
                betParameters: _betParameters,
                betPlacedAt: block.timestamp
            });
        } catch (bytes memory) {
            revert("Failed to place casino bet.");
        }

        emit CasinoBetPlaced(_nonce, msg.sender, msg.sender, _casinoGameContract, _casinoGameContract, _betAmount, _betAmount, _betParameters);
    }

    /**
     * @notice Handles the result of a game and adjusts user balances accordingly.
     * @dev This is where we apply our houseEdge to all winning bets (never to loosing bets)
     * @param _nonce Unique identifier for the game.
     * @param _multiplier Amount of USDT won by the user.
     */
    function notifyGameResult(
        uint256 _nonce,
        uint256 _multiplier
    ) external whenNotPaused onlyCasinoGameContract whenNotRestricted {
        address _user = activeCasinoBets[_nonce].user;
        require(_user != address(0), "Game not found");

        uint256 _betAmount = activeCasinoBets[_nonce].betAmount;
        if (_multiplier == 0) {
            casinoUSDTLiquidityBalance += (_betAmount * 985) / 1000; // 98.5% back to LP holders 
            userBalance[transpareWallet] += (_betAmount * 15) / 1000; // 1.5% back to Transpare (1% costs, 0.5% user loyalty)
            casinoUSDTUserBalance += (_betAmount * 15) / 1000;
        } else {
            uint256 _adjustedMultiplier = _multiplier * (1000 - houseEdge);
            uint256 _winAmount = (_betAmount * _adjustedMultiplier) / 1000;

            if (isSlidingWindowActive[WindowType.LiquidityPool]) {
                // Check sliding window defensive mechanism
                uint256 _proposedBalance = casinoUSDTLiquidityBalance - _winAmount;
                _checkSlidingWindow(WindowType.LiquidityPool, _user, _proposedBalance);
            }

            casinoUSDTLiquidityBalance -= _winAmount;
            userBalance[_user] += _winAmount;
            casinoUSDTUserBalance += _winAmount;
        }

        emit CasinoBetResult(_nonce, _user, _user, msg.sender, msg.sender, _betAmount, _multiplier, _multiplier);

        delete activeCasinoBets[_nonce];
    }

    /**
     * @notice Allows users to place a sports bet
     * @dev Processes sports bet using the SportsConnector contract.
     * @param _betAmount Amount of USDT to bet.
     * @param _betParameters Parameter required to place the bet.
     */
    function placeSportsBet(
        uint256 _betAmount,
        bytes calldata _betParameters
    ) external whenNotPaused nonReentrant whenNotRestricted {
        require(_betParameters.length <= maxBytesLength, "Bet parameters too long");
        require(userBalance[msg.sender] >= _betAmount, "Insufficient balance");
        require(_betAmount > 0, "Bet should be greater than 0");
        require(highRiskMode == false, "High risk on, try again soon");

        userBalance[msg.sender] -= _betAmount;
        casinoUSDTUserBalance -= _betAmount;

        _placeSportsBet(_betAmount, _betParameters);
    }

    /**
     * @notice Allows the owner to settle an active game manually and return a failed bet to the user.
     * @dev This function should only be called in case of a failure in the game settlement process.
     * @param _nonce Unique identifier for the game.
     */
    function manuallySettleGame(uint256 _nonce) external onlyOwner {
        address _user = activeCasinoBets[_nonce].user;
        uint256 _betAmount = activeCasinoBets[_nonce].betAmount;

        require(_user != address(0), "Game not found");

        // Credit the user's balance with the original bet amount
        userBalance[_user] += _betAmount;
        casinoUSDTUserBalance += _betAmount;

        // Remove the game from active games
        delete activeCasinoBets[_nonce];

        // Optionally, you could emit an event here to log the manual settlement
        emit ManualGameSettlement(_nonce, _user, _betAmount);
    }

    /**
     * @notice Updates the house edge.
     * @param _newHouseEdge New house edge to set.
     */
    function updateHouseEdge(uint16 _newHouseEdge) external onlyOwner {
        require(_newHouseEdge >= 0 && _newHouseEdge <= 1000, "House edge not 0 <= x <= 1000");

        houseEdge = _newHouseEdge;

        emit HouseEdgeUpdated(_newHouseEdge);
    }

    /**
     * @notice Updates the max bet percentage.
     * @param _newMaxBetPercentage New max bet percentage to set.
     */
    function updateMaxBet(uint16 _newMaxBetPercentage) external onlyOwner {
        require(_newMaxBetPercentage >= 0 && _newMaxBetPercentage <= 1000, "Max bet not 0 <= x <= 1000");

        maxBetPercentage = _newMaxBetPercentage;

        emit MaxBetPercentageUpdated(_newMaxBetPercentage);
    }

    /**
     * @notice Updates the Transpare team wallet
     * @param _newTranspareWallet New Transpare team wallet
     */
    function updateTranspareWallet(address _newTranspareWallet) external onlyOwner {
        require(_newTranspareWallet != address(0), "Not a real address");

        transpareWallet = _newTranspareWallet;

        emit TranspareWalletUpdated(_newTranspareWallet);
    }

    /**
     * @notice Corrects the casino balance if there is a mismatch with the actual USDT balance
     * @dev It checks if the sum of total user balances and casino balance matches the contract's USDT balance.
     *      If there is a mismatch, it recalculates the casino balance by subtracting the total user balances
     *      from the contract's USDT balance, thereby ensuring consistency with the actual balance on-chain.
     *      Note: This function should never have to be used
     */
    function correctCasinoUSDTLiquidityBalance() external onlyOwner {
        if (casinoUSDTUserBalance + casinoUSDTLiquidityBalance != usdtToken.balanceOf(address(this))) {
            casinoUSDTLiquidityBalance = usdtToken.balanceOf(address(this)) - casinoUSDTUserBalance;
        }
    }

    /**
     * @notice Restricts an address manually
     * @param _addressToRestrict The address to restrict
     */
    function restrictAddress(address _addressToRestrict) external onlyOwner {
        _restrictAddress(_addressToRestrict);
    }
    
    /**
     * @notice Enables high risk mode manually
     */
    function enableHighRiskMode() external onlyOwner {
        _enableHighRiskMode();
    }


    /**
     * @notice Enables the casino's protector tool based on the given window type.
     * @dev Enables the sliding window with the latest balance and current timestamp.
     *      This function helps reset the slidingWindow if there was a legitimate big win.
     *      Pro-actively prevents a safetyStop (pause) from occurring due to big fair wins
     * @param _windowType The type of window to enable (either LiquidityPool or Casino).
     */
    function enableSlidingWindow(WindowType _windowType, uint256 _windowSize, uint256 _windowShiftSize, uint8 _thresholdPercentage) external onlyOwner {
        uint256 _currentBalance = (_windowType == WindowType.LiquidityPool) ? casinoUSDTLiquidityBalance : usdtToken.balanceOf(address(this));
        _enableSlidingWindow(_windowType, _windowSize, _windowShiftSize, _currentBalance, _thresholdPercentage);
    }

    /**
     * @notice Disables the casino's protector tool based on the given window type.
     * @dev Disables the sliding window. This function helps turn off the slidingWindow.
     * @param _windowType The type of window to disable (either LiquidityPool or Casino).
     */
    function disableSlidingWindow(WindowType _windowType) external onlyOwner {
        _disableSlidingWindow(_windowType);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "CasinoGameContracts" Contract
 * @author Stefan Stoll, [email protected]
 * @dev This contract enables the management/authentication of different casino game contracts within a larger system.
 *      It provides functionalities to add or remove game contracts and ensures that only authenticated game contracts can interact with the system.
 *      Note: The array gameContractAddresses is used solely to return a list of all authenticated contracts. The mapping casinoGameContracts is what we use for logic everywhere.
 */

pragma solidity ^0.8.0;

// Provides ownership control (OpenZeppelin), enabling only the owner to perform certain operations.
import "./IOwnable.sol";

// Interface for interacting with external casino game contracts.
interface ICasinoGameContract {
    /**
     * @notice Facilitates placing a bet in casino games.
     * @dev Function is expected to handle the logic for casino game bet placement and return a unique identifier for the bet.
     * @param _betParameters Data needed to place a casino bet.
     * @return nonce Unique identifier for the game round/bet.
     */
    function play(bytes calldata _betParameters) external returns (uint256 nonce);
}

contract CasinoGameContracts is IOwnable {
    // Max allowed bytes length for bet parameters, used to control input size and prevent abuse.
    uint256 public maxBytesLength = 100;

    // Mapping of game contract addresses to their authentication status.
    // Used to quickly check if a game contract is authenticated.
    mapping(address => bool) public casinoGameContracts;

    // Array of game contract addresses used for user convenience
    // by allowing the listing of all authenticated game contracts.
    address[] private listOfAllCasinoGameContracts;

    /**
     * @dev Modifier ensuring calls only come from authenticated game contracts.
     *      Used for callbacks to provide game results from authenticated game contracts.
     */
    modifier onlyCasinoGameContract() {
        require(casinoGameContracts[msg.sender], "Caller not authenticated");
        _;
    }

    // Emitted when a game contract is authenticated.
    event CasinoGameContractAdded(address indexed casinoGameContract);
    // Emitted when an authenticated game contract is removed.
    event CasinoGameContractRemoved(address indexed casinoGameContract);

    /**
     * @notice Authenticates a new game contract.
     * @dev Adds the game contract to the mapping (system) and the list of addresses, and triggers an event.
     *      Requires that the contract address is valid and not already authenticated.
     * @param _casinoGameContract Address of the game contract to authenticate.
     */
    function addCasinoGameContract(address _casinoGameContract) external onlyOwner {
        require(_casinoGameContract != address(0), "Invalid game contract address");
        require(!casinoGameContracts[_casinoGameContract], "Game already authenticated");

        // Add to the mapping
        casinoGameContracts[_casinoGameContract] = true;

        // Add to the array
        listOfAllCasinoGameContracts.push(_casinoGameContract);

        emit CasinoGameContractAdded(_casinoGameContract);
    }

    /**
     * @notice Removes an authenticated game contract.
     * @dev Removes the game contract from the mapping (system) and the list of addresses, and triggers an event.
     *      Requires that the contract address is already authenticated.
     * @param _casinoGameContract Address of the game contract to remove.
     */
    function removeCasinoGameContract(address _casinoGameContract) external onlyOwner {
        require(casinoGameContracts[_casinoGameContract], "Game contract not found");

        // Remove from mapping
        delete casinoGameContracts[_casinoGameContract];
        
        // Remove from the array
        for (uint8 i = 0; i < listOfAllCasinoGameContracts.length; i++) {
            if (listOfAllCasinoGameContracts[i] == _casinoGameContract) {
                listOfAllCasinoGameContracts[i] = listOfAllCasinoGameContracts[listOfAllCasinoGameContracts.length - 1];
                listOfAllCasinoGameContracts.pop();
                break;
            }
        }

        emit CasinoGameContractRemoved(_casinoGameContract);
    }

    /**
     * @notice Provides a list of all authenticated contracts.
     * @dev This extra function just allows users to be able to see a full list
     *      of all of the current authenticated game contracts for transparency.
     */
    function getAllAuthenticatedCasinoGameContracts() external view returns (address[] memory) {
        return listOfAllCasinoGameContracts;
    }

    /**
     * @notice Updates the maximum allowed bytes length for bet parameters.
     * @dev Allows the owner to set a new maximum length for the bet parameters. This ensures control
     *      over the input size and helps prevent abuse by limiting the acceptable input length.
     * @param _maxBytesLength The new maximum length for bet parameters.
     */
    function setMaxBytesLength(uint256 _maxBytesLength) external onlyOwner {
        maxBytesLength = _maxBytesLength;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// Provides pausing functionality (OpenZeppelin), enabling certain roles to pause certain operations if required.
import "./IPausable.sol";

import "./SlidingWindow.sol";
import "./HighRiskWithdraw.sol";

contract Defense is SlidingWindow, HighRiskWithdraw, IPausable {
    mapping(address => bool) internal restrictedAddresses;
 
    // Modifier to check if the caller is not restricted
    modifier whenNotRestricted() {
        require(!restrictedAddresses[msg.sender], "Address is restricted");
        _;
    }

    // Event to log defense actions
    event SafetyStopTriggered(WindowType _windowType, uint256 _proposedcasinoUSDTLiquidityBalance);
    event AddressRestricted(address indexed target);
    event AddressUnrestricted(address indexed target);

    function _checkSlidingWindow(WindowType _windowType, address _user, uint256 _proposedBalance) internal {
        if (highRiskMode) {
            return;
        } else {
            // Update the sliding window
            _updateWindow(_windowType, _proposedBalance);
            // Get sliding window configurations (LP, Casino)
            WindowConfig storage _config = windowConfigs[_windowType];
            // Get balance that contract shouldn't go under using sliding window
            uint256 _allowedBalance = (_config.windowPeriodStartBalance * (100 - _config.thresholdPercentage)) / 100;
            if (_proposedBalance <= _allowedBalance) {
                // Logic that restricts a user if an attempted withdrawal caused the balance to 
                // Note: Address will be unrestricted immediately if no wrong doing, just a big withdrawal
                // Note: For withdrawals > 25% of the entire casino balance, if you give the team a heads up
                // Note: we can disable defense mechanisms for a smooth withdrawal process.
                if (_allowedBalance == 0 || (_proposedBalance * 100) / _allowedBalance < 95) {
                    _restrictAddress(_user);
                }
                _enableHighRiskMode();
                _disableSlidingWindow(_windowType);
                emit SafetyStopTriggered(_windowType, _proposedBalance);
            }
        }
    }

    // Function to restrict an address
    function _restrictAddress(address _address) internal {
        restrictedAddresses[_address] = true;
        emit AddressRestricted(_address);
    }

    // Function to unrestrict an address
    function unrestrictAddress(address _address) public onlyOwner {
        restrictedAddresses[_address] = false;
        emit AddressRestricted(_address);
    }

    // Function to check if an address is restricted
    function isAddressRestricted(address _address) public view returns (bool) {
        return restrictedAddresses[_address];
    }

    /**
     * @notice Pauses the contract, preventing deposits, withdrawals, and game actions.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resumes the contract operations after being paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "HighRiskWithdraw" Contract
 * @author Stefan Stoll, [email protected]
 * @dev This contract allows the contract + owner to enable and disable highRiskMode
 *      and configure the limits of the high-risk mode withdrawal pool.
 */

pragma solidity ^0.8.0;

// Provides ownership control (OpenZeppelin), enabling only the owner to perform certain operations.
import "./IOwnable.sol";

contract HighRiskWithdraw is IOwnable {
    // State variable indicating whether high-risk withdrawal mode is active.
    // High-risk mode allows restricted withdrawals according to specific conditions
    // defined by the contract's rules.
    bool public highRiskMode = false;

    // Epoch counter to help reset user balances and manage withdrawal periods
    uint256 private currentEpoch = 0; 

    // Constants for default configuration
    uint256 private constant DEFAULT_POOL_SIZE = 10000 * 1e6; // (10,000 USDT)
    uint256 private constant DEFAULT_PER_USER_WITHDRAWAL_LIMIT = 400 * 1e6; // (400 USDT)

    // Constants for minimum configuration
    uint256 private constant MINIMUM_POOL_SIZE = 1e6; // (1 USDT)
    uint256 private constant MINIMUM_WITHDRAWAL_LIMIT = 1e6; // (1 USDT)

    // Struct to hold high-risk withdraw pool details
    struct HighRiskPool {
        uint256 poolSize; // Total pool size available for withdraw (6 decimals)
        uint256 perUserWithdrawalLimit; // Withdrawal limit per user (6 decimals)
        uint256 totalAmountWithdrawn; // Total amount withdrawn from pool (6 decimals)
    }

    // State variable to hold the current highRiskPool
    HighRiskPool public highRiskPool;

    // Tracks the last withdrawal epoch for each user to manage perUserWithdrawalLimit
    mapping(address => uint256) private userLastWithdrawalEpoch;
    // Tracks the total high-risk withdrawals for each user during the currentEpoch (6 decimals)
    mapping(address => uint256) private userHighRiskWithdrawals;

    // Events to notify changes related to HighRiskPools
    event HighRiskModeEnabled(uint256 poolSize, uint256 perUserWithdrawalLimit, uint256 totalAmountWithdrawn);
    event HighRiskModeDisabled(uint256 poolSize, uint256 perUserWithdrawalLimit, uint256 totalAmountWithdrawn);
    event HighRiskPoolConfigured(uint256 poolSize, uint256 perUserWithdrawalLimit, uint256 totalAmountWithdrawn);

    /**
     * @notice Constructor to initialize default values
     */
    constructor() {
        // Initialization with default values
        highRiskPool = HighRiskPool(DEFAULT_POOL_SIZE, DEFAULT_PER_USER_WITHDRAWAL_LIMIT, 0);
    }

    /**
     * @notice Turn on highRiskMode and start withdrawal pool
     * @dev Can only be called internally and by owner.
     */
    function _enableHighRiskMode() internal {
        require(!highRiskMode, "High risk must not be active");

        currentEpoch++; // Increment epoch to help reset user balances

        // Resets the high risk pool to default values if there hasn't been a manual highRiskPool configuration
        if (highRiskPool.totalAmountWithdrawn > 0) {
            highRiskPool.poolSize = DEFAULT_POOL_SIZE;
            highRiskPool.perUserWithdrawalLimit = DEFAULT_PER_USER_WITHDRAWAL_LIMIT;
            highRiskPool.totalAmountWithdrawn = 0;
        }

        highRiskMode = true; // Turns on high risk conditions
        
        emit HighRiskModeEnabled(highRiskPool.poolSize, highRiskPool.perUserWithdrawalLimit, highRiskPool.totalAmountWithdrawn);
    }

    /**
     * @notice Turn off highRiskMode and stop withdrawal pool
     * @dev Can only be called internally and by owner.
     */
    function disableHighRiskMode() public onlyOwner {
        require(highRiskMode, "High risk must be active");
        
        highRiskMode = false; // Turns off high risk conditions

        emit HighRiskModeDisabled(highRiskPool.poolSize, highRiskPool.perUserWithdrawalLimit, highRiskPool.totalAmountWithdrawn);
    }

    /**
     * @notice Enforce withdrawal limits during highRiskMode
     * @dev The currentEpoch is used to differentiate between withdrawal periods,
     *      and user withdrawals are reset if the last withdrawal was from a previous epoch.
     *      The function ensures that neither the total high-risk pool limit nor the individual
     *      user's limit is exceeded.     
     * @param _amount The amount to withdraw from the highRiskPool (6 decimals)
     */
    function _withdrawFromHighRiskPool(uint256 _amount) internal {
        require(highRiskMode, "High risk must be active");
        // Check if total HighRiskPool is exceeded
        require(highRiskPool.poolSize >= highRiskPool.totalAmountWithdrawn + _amount, "Exceeds highRisk withdraw limit");

        // Resets user's withdrawal amounts if they are from a previous epoch
        if (userLastWithdrawalEpoch[msg.sender] < currentEpoch) {
            userHighRiskWithdrawals[msg.sender] = 0;
            userLastWithdrawalEpoch[msg.sender] = currentEpoch;
        }
        // Check if user withdrawal would exceed individual user limit
        require(userHighRiskWithdrawals[msg.sender] + _amount <= highRiskPool.perUserWithdrawalLimit, "Exceeds user pool withdraw limit");

        // Update total and individual user withdrawals
        highRiskPool.totalAmountWithdrawn += _amount;
        userHighRiskWithdrawals[msg.sender] += _amount;
    }

    /**
     * @notice Configure the highRiskPool setup
     * @dev Can only be called by the owner, and only if highRiskMode is not active
     * @param _poolSize Total pool size available for withdrawal (6 decimals)
     * @param _perUserWithdrawalLimit Withdrawal limit per user (6 decimals)
     */
    function configureHighRiskPool(uint256 _poolSize, uint256 _perUserWithdrawalLimit) public onlyOwner {
        require(!highRiskMode, "High risk mode is active");
        require(_poolSize > _perUserWithdrawalLimit, "perUserWithdrawLimit > poolSize");
        require(_poolSize > MINIMUM_POOL_SIZE && _perUserWithdrawalLimit > MINIMUM_WITHDRAWAL_LIMIT, "Inputs must be > $1 in USDT");

        // Update highRiskPool configuration
        highRiskPool.poolSize = _poolSize;
        highRiskPool.perUserWithdrawalLimit = _perUserWithdrawalLimit;
        highRiskPool.totalAmountWithdrawn = 0;

        emit HighRiskPoolConfigured(highRiskPool.poolSize, highRiskPool.perUserWithdrawalLimit, highRiskPool.totalAmountWithdrawn);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// The IOwnable contract is an abstraction layer that inherits from the Ownable contract provided by OpenZeppelin.
// It serves as a common base contract for other contracts within the project to utilize ownership functionalities.
// This contract deliberately contains no additional logic or state.
abstract contract IOwnable is Ownable {
    // Intentionally left blank. Just inheriting all features from OpenZeppelin's Ownable contract.
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

// The IPausable contract is an abstraction layer that inherits from the Pausable contract provided by OpenZeppelin.
// It serves as a common base contract for other contracts within the project to utilize pausing functionalities.
// This contract deliberately contains no additional logic or state, as it solely exists to extend the features of the Pausable contract.
abstract contract IPausable is Pausable {
    // Intentionally left blank. Just inheriting all features from OpenZeppelin's Pausable contract.
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "LiquidityProvider" Contract
 * @author Stefan Stoll, [email protected]
 * @dev CasinoLP (cLP) represents a share of the total liquidity in the pool.
 *      Users can deposit USDT to mint CasinoLP tokens and can burn CasinoLP tokens to withdraw USDT.
 *      This contract handles the conversion between CasinoLP and USDT, and manages the liquidity for the casino's operations.
 */

pragma solidity ^0.8.0;

// Audited OpenZeppelin libraries for token creation and secure token transfers.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityProvider is ERC20("CasinoLP", "cLP") {
    // Public state variables
    uint256 public casinoUSDTLiquidityBalance = 0; // Balance of USDT that backs CasinoLP tokens (6 decimal places).

    // Events to log liquidity changes
    event LiquidityAdded(
        address indexed indexedUser, address user,
        uint256 indexed indexedDepositInLP, uint256 depositInLP, 
        uint256 indexed indexedDepositInUSDT, uint256 depositInUSDT
    );
    event LiquidityRemoved(
        address indexed indexedUser, address user,
        uint256 indexed indexedWithdrawInLP, uint256 withdrawtInLP, 
        uint256 indexed indexedWithdrawInUSDT, uint256 withdrawInUSDT
    );

    /**
     * @notice Internal function to add liquidity to the contract.
     * @param _depositInUSDT Amount of USDT to add to liquidity pool (6 decimals).
     */
    function _addLiquidity(uint256 _depositInUSDT) internal {
        // If it's the first deposit, mint CasinoLP tokens at a 1:1 ratio with USDT.
        // This establishes the initial conversion rate for the liquidity pool.
        // Otherwise, calculate the equivalent amount of CasinoLP tokens based on the current liquidity pool's value.
        // The conversion rate is determined by the ratio of total CasinoLP tokens to the total USDT balance in the pool.
        uint256 _depositInLP = (totalSupply() == 0) 
        ? _depositInUSDT * 1e12 
        : _depositInUSDT * totalSupply() / casinoUSDTLiquidityBalance;

        // Increase the casino balance.
        casinoUSDTLiquidityBalance += _depositInUSDT;

        // Mint the CasinoLP tokens for the depositor.
        _mint(msg.sender, _depositInLP);

        emit LiquidityAdded(msg.sender, msg.sender, _depositInLP, _depositInLP, _depositInUSDT, _depositInUSDT);
    }

    /**
     * @notice Internal function to remove liquidity from the contract.
     * @param _withdrawalInLP Amount of CasinoLP tokens to withdraw from the liquidity pool (18 decimal places).
     * @return Amount of USDT withdrawn from the liquidity pool.
     */
    function _removeLiquidity(uint256 _withdrawalInLP) internal returns (uint256) {
        require(balanceOf(msg.sender) >= _withdrawalInLP, "Insufficient CasinoLP");
        require(totalSupply() > 0, "No CasinoLP minted yet");

        // Calculate the amount of USDT to withdraw, proportionate to the amount of CasinoLP tokens (6 decimal points).
        uint256 _withdrawalInUSDT = _withdrawalInLP * casinoUSDTLiquidityBalance / totalSupply();

        // Ensure that the withdrawal does not exceed the casino balance.
        require(_withdrawalInUSDT <= casinoUSDTLiquidityBalance, "Exceeds casino balance");

        // Update the casino balance.
        casinoUSDTLiquidityBalance -= _withdrawalInUSDT;

        // Burn the CasinoLP tokens.
        _burn(msg.sender, _withdrawalInLP);

        emit LiquidityRemoved(msg.sender, msg.sender, _withdrawalInLP, _withdrawalInLP, _withdrawalInUSDT, _withdrawalInUSDT);

        return _withdrawalInUSDT;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "SlidingWindow" Contract
 * @author Stefan Stoll, [email protected]
 * @dev Implements a SlidingWindow mechanism to provide a robust and agile liquidity management system.
 *
 *      The SlidingWindow concept is utilized to divide a continuous time frame into discrete windows of fixed duration.
 *      Each window captures balance fluxuation and allows for the continuous monitoring of liquidity changes.
 *
 *      This contract supports two types of Sliding Windows: LiquidityPool and Casino.
 *      - LiquidityPool: Manages the USDT allocated to CasinoLP holders.
 *      - Casino: Manages the total USDT the contract holds, including LiquidityPool and the sum of user balances.
 *
 *      The adjustable parameters for each type enable tailored monitoring and control according to specific requirements.
 *      By tracking liquidity continuously, the SlidingWindow serves as a safeguard, providing a shield against significant exploits.
 *      In the unlikely event of a failure or attack, this mechanism contributes to preserving system stability and protecting user assets.
 * 
 */

pragma solidity ^0.8.0;

// Provides ownership control (OpenZeppelin), enabling only the owner to perform certain operations.
import "./IOwnable.sol";

// Enum defining the two supported sliding window types:
// - LiquidityPool: Represents the USDT allocated to CasinoLP holders.
// - Casino: Represents the total USDT the contract holds (LiquidityPool + sum of user balances).
enum WindowType { LiquidityPool, Casino }

contract SlidingWindow is IOwnable {
    // Structure to define sliding window configuration
    struct WindowConfig {
        uint256 windowSize;                    // Fixed window duration in seconds.
        uint256 windowShiftSize;               // Fixed shift duration within the window in seconds.
        uint8 numberOfIntervals;               // Fixed number of intervals in the window.
        uint256 initialWindowStartTime;        // Fixed initial start time of the window.
        uint256 initialWindowEndTime;          // Fixed initial end time of the window.
        uint256 windowPeriodStartTime;         // Dynamic start time of the current window.
        uint256 windowPeriodEndTime;           // Dynamic end time of the current window.
        uint256 windowPeriodStartBalance;      // Dynamic start balance of the current window in USDT.
        uint8 thresholdPercentage;             // Fixed threshold percentage for monitoring abnormal drops (e.g., 20%).
        uint8 lastUpdatedIndex;                // Dynamic index of the last updated interval.
        uint256[] intervalStartBalanceHistory; // Dynamic history of start balances for each interval.
    }

    // Mappings to manage the active state and configurations for each sliding window type
    mapping(WindowType => bool) public isSlidingWindowActive;
    mapping(WindowType => WindowConfig) internal windowConfigs;

    // Events to notify changes related to SlidingWindows
    event SlidingWindowEnabled(WindowType windowType);
    event SlidingWindowDisabled(WindowType windowType);

    /**
     * @notice Updates a sliding window's state, handling shifts and balance updates.
     * @dev Called internally to handle shifts and updates within a sliding window.
     *      Manages the window period and balances, shifts the window if necessary, 
     *      and ensures alignment with the current time.
     * @param _windowType Type of the sliding window.
     * @param _proposedBalance Proposed balance for the update.
     */
    function _updateWindow(WindowType _windowType, uint256 _proposedBalance) internal {
        WindowConfig storage config = windowConfigs[_windowType];

        // Check if the current time exceeds the end of the initial window period plus one shift size (just for optimization)
        if (block.timestamp >= config.initialWindowEndTime + config.windowShiftSize) {
            // Determine the number of shifts needed to realign the window with the current time
            uint256 _shiftsNeeded = (block.timestamp - config.windowPeriodEndTime) / config.windowShiftSize;

            // If shifts are needed, update the window period start and end times
            if (_shiftsNeeded > 0) {
                // If a whole window of shifts was missed, restart the sliding window
                if (_shiftsNeeded >= config.numberOfIntervals) {
                    // We do not want to use the _proposedBalance, instead pull a trusted previous balance
                    uint256 _windowPeriodStartBalance = config.intervalStartBalanceHistory[0];
                    _disableSlidingWindow(_windowType);
                    uint8 _thresholdPercentage;
                    if (_windowType == WindowType.LiquidityPool) {
                        _thresholdPercentage = 20;
                    } else {
                        _thresholdPercentage = 40;
                    }
                    _enableSlidingWindow(_windowType, 8 * 60 * 60, 2 * 60 * 60, _windowPeriodStartBalance, _thresholdPercentage);
                } else {
                    // Shift the window period start time forward by the required number of shifts
                    config.windowPeriodStartTime += _shiftsNeeded * config.windowShiftSize;
                    // Recalculate the window period end time based on the new start time
                    config.windowPeriodEndTime = config.windowPeriodStartTime + config.windowSize;

                    uint256 _oldestIntervalIndex = (config.lastUpdatedIndex + _shiftsNeeded) % config.numberOfIntervals;
                    config.windowPeriodStartBalance = config.intervalStartBalanceHistory[_oldestIntervalIndex];

                    // Update missed interval start balances for all missed shifts
                    for (uint256 i = 1; i <= _shiftsNeeded; i++) {
                        config.intervalStartBalanceHistory[(_oldestIntervalIndex + i) % config.numberOfIntervals] = _proposedBalance;
                    }
                }
            }
        }

        // Calculate the current interval index based on the time elapsed since the initial window start
        uint256 _rawCurrentIntervalIndex = (block.timestamp - config.initialWindowStartTime) / config.windowShiftSize;
        // Normalize the raw interval index to fit within the number of intervals defined
        uint8 _currentIntervalIndex = uint8(_rawCurrentIntervalIndex % config.numberOfIntervals);

        // Check if we are in a new interval since the last update
        if (_rawCurrentIntervalIndex != config.lastUpdatedIndex) {
            // Store the given balance in the intervalStartBalanceHistory array
            config.intervalStartBalanceHistory[_currentIntervalIndex] = _proposedBalance;
            // Update the last interval index to the current one, indicating an update was made
            config.lastUpdatedIndex = _currentIntervalIndex;
        }
    }

    /**
     * @notice Configures and enables a sliding window.
     * @param _windowType Type of the sliding window (LiquidityPool or Casino).
     * @param _windowSize Size of the window in seconds.
     * @param _windowShiftSize Shift size within the window in seconds.
     * @param _currentBalance Initial balance for the window in USDT
     * @param _thresholdPercentage Threshold percentage for monitoring abnormal drops (e.g., 20%).
     */
    function _enableSlidingWindow(WindowType _windowType, uint256 _windowSize, uint256 _windowShiftSize, uint256 _currentBalance, uint8 _thresholdPercentage) internal {
        require(!isSlidingWindowActive[_windowType], "Sliding window is active");
        require(_windowSize % _windowShiftSize == 0, "Size % ShiftSize must be 0");
        require(_windowShiftSize > 0, "Shift size can't be 0");
        require(_windowSize > _windowShiftSize, "Window size not > shift size");
        require(_thresholdPercentage <= 100, "Threshold % must be < 100");

        WindowConfig storage config = windowConfigs[_windowType];

        // Set up # of intervals
        uint256 _numberOfIntervals = _windowSize / _windowShiftSize;
        config.numberOfIntervals = uint8(_numberOfIntervals);
        config.intervalStartBalanceHistory = new uint256[](_numberOfIntervals);
        for (uint8 i = 0; i < _numberOfIntervals; i++) {
            config.intervalStartBalanceHistory[i] = _currentBalance;
        }
        config.lastUpdatedIndex = 0;

        // Set the config with parameters given
        config.windowSize = _windowSize;
        config.windowShiftSize = _windowShiftSize;
        config.windowPeriodStartBalance = _currentBalance;
        config.thresholdPercentage = _thresholdPercentage;

        // Set the window start time and end time with timestamps
        config.initialWindowStartTime = block.timestamp;
        config.initialWindowEndTime = config.initialWindowStartTime + config.windowSize;
        config.windowPeriodStartTime = block.timestamp;
        config.windowPeriodEndTime = config.windowPeriodStartTime + config.windowSize;

        // Activate the SlidingWindow
        isSlidingWindowActive[_windowType] = true;

        emit SlidingWindowEnabled(_windowType);
    }

    /**
     * @notice Disables a sliding window.
     * @param _windowType Type of the sliding window (LiquidityPool or Casino).
     */
    function _disableSlidingWindow(WindowType _windowType) internal {
        require(isSlidingWindowActive[_windowType], "Sliding window is not active");
        
        // Restet the configuration associated with the sliding window type
        delete windowConfigs[_windowType];
        // Deactivate the SlidingWindow
        isSlidingWindowActive[_windowType] = false;

        emit SlidingWindowDisabled(_windowType);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

/**
 * @title Transpare "Sports" Contract
 * @author Stefan Stoll, [email protected]
 * @dev This contract facilitates sports betting by allowing users to place bets and forwarding them to the sports connector.
 */

pragma solidity ^0.8.0;

// Provides ownership control, enabling only the owner to perform certain operations.
import "./IOwnable.sol";

// Defines the interface for interacting with the sports connector contract.
interface ISportsConnector {
    /**
     * @notice Facilitates placing a sports bet.
     * @dev The function interfaces with the sports connector to place a sports bet.
     * @param _betParameters Parameters for the sports bet.
     */
    function relaySportsBet(bytes calldata _betParameters) external;
}

contract Sports is IOwnable {
    address public sportsConnectorContract; // Address of the contract that enables sports betting

    // Stores a sports bet
    struct ActiveSportsBet {
        uint256 betAmount;   // Bet amount in USDT.
        bytes betParameters; // Parameters of the bet (e.g., teams, odds).
        uint256 timestamp;   // Timestamp when the bet was placed.
        bool isPending;      // True if the bet is pending, false if settled.
    }

    // Mapping to associate user addresses with their sports bets.
    mapping(address => mapping(uint256 => ActiveSportsBet)) public sportsBetsByUser;
    // Mapping to keep track of the number of bets for each user.
    mapping(address => uint256) public userBetCount;
    
    // Event triggered when a new sports bet is placed.
    event SportsBetPlaced(
        address indexed indexedUser, address _user, 
        uint256 indexed indexedBetAmount, uint256 betAmount,
        bytes betParameters
    );
    // Event triggered when the sports connector contract address is updated.
    event SportsConnectorContractUpdated(address newSportsConnectorContract);

    /**
     * @notice Allows users to place a sports bet
     * @dev Internal function to place a sports bet using the SportsConnector contract.
     *      Only callable by the placeSportsBet() function throughout all smart contracts.
     * @param _betAmount Amount of USDT to bet.
     * @param _betParameters Parameters required to place the bet.
     */
    function _placeSportsBet(
        uint256 _betAmount,
        bytes calldata _betParameters
    ) internal {
        try
            ISportsConnector(sportsConnectorContract).relaySportsBet(_betParameters)
        {
            uint256 betID = userBetCount[msg.sender]++;
            ActiveSportsBet storage activeSportsBet = sportsBetsByUser[msg.sender][betID];
            activeSportsBet.betAmount = _betAmount;
            activeSportsBet.betParameters = _betParameters;
            activeSportsBet.timestamp = block.timestamp;
            activeSportsBet.isPending = true;
        } catch (bytes memory) {
            revert("Failed to place sports bet.");
        }
        
        emit SportsBetPlaced(msg.sender, msg.sender, _betAmount, _betAmount, _betParameters);
    }

    /**
     * @notice Updates the address of the SportsConnector contract.
     * @param _newSportsConnectorContract New address of the sports connector contract.
     */
    function updateSportsConnectorContract(address _newSportsConnectorContract) external onlyOwner {
        require(_newSportsConnectorContract != address(0), "Invalid address");
        
        sportsConnectorContract = _newSportsConnectorContract;

        emit SportsConnectorContractUpdated(_newSportsConnectorContract);
    }
}