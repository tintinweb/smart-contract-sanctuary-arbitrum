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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
pragma solidity 0.8.17;

interface ILendingPoolConfig {
  function interestRateAPR(uint256 _debt, uint256 _floating) external view returns (uint256);
  function interestRatePerSecond(uint256 _debt, uint256 _floating) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWAVAX {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/lending/ILendingPoolConfig.sol";
import "../interfaces/tokens/IWAVAX.sol";


contract LendingPool is ERC20, ReentrancyGuard, Pausable, Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Contract of pool's underlying asset
  IERC20 public immutable asset;
  // Pool config with interest rate model
  ILendingPoolConfig public immutable lendingPoolConfig;
  // Does pool accept native token?
  bool public immutable isNativeAsset;
  // Protocol treasury address
  address public treasury;
  // Asset decimals
  uint256 public immutable assetDecimals;
  // Amount borrowed from this pool
  uint256 public totalBorrows;
  // Total borrow shares in this pool
  uint256 public totalBorrowDebt;
  // The fee % applied to interest earned that goes to the protocol in 1e18
  uint256 public protocolFee;
  // Last updated timestamp of this pool
  uint256 public lastUpdatedAt;
  // Max capacity of vault in asset decimals / amt
  uint256 public maxCapacity;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== STRUCTS ========== */

  struct Borrower {
    // Boolean for whether borrower is approved to borrow from this pool
    bool approved;
    // Debt share of the borrower in this pool
    uint256 debt;
    // The last timestamp borrower borrowed from this pool
    uint256 lastUpdatedAt;
  }

  /* ========== MAPPINGS ========== */

  // Mapping of borrowers to borrowers struct
  mapping(address => Borrower) public borrowers;

  /* ========== EVENTS ========== */

  event Deposit(address indexed lender, uint256 depositShares, uint256 depositAmount);
  event Withdraw(address indexed withdrawer, uint256 withdrawShares, uint256 withdrawAmount);
  event Borrow(address indexed borrower, uint256 borrowDebt, uint256 borrowAmount);
  event Repay(address indexed borrower, uint256 repayDebt, uint256 repayAmount);
  event ProtocolFeeUpdated(address indexed caller, uint256 previousProtocolFee, uint256 newProtocolFee);
  event UpdateMaxCapacity(uint256 _maxCapacity);

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _name  Name for ibToken for this lending pool, e.g. Interest Bearing AVAX
    * @param _symbol  Symbol for ibToken for this lending pool, e.g. ibAVAX
    * @param _asset  Contract address for underlying ERC20 asset
    * @param _isNativeAsset  Boolean for whether this lending pool accepts the native asset (e.g. AVAX)
    * @param _protocolFee  Protocol fee in 1e18
    * @param _maxCapacity Max capacity of lending pool in asset decimals
    * @param _lendingPoolConfig  Contract for Lending Pool Configuration
    * @param _treasury  Contract address for protocol treasury
  */
  constructor(
    string memory _name,
    string memory _symbol,
    IERC20 _asset,
    bool _isNativeAsset,
    uint256 _protocolFee,
    uint256 _maxCapacity,
    ILendingPoolConfig _lendingPoolConfig,
    address _treasury
    ) ERC20(_name, _symbol) {
      require(address(_asset) != address(0), "invalid asset");
      require(address(_lendingPoolConfig) != address(0), "invalid lending pool config");
      require(_treasury != address(0), "invalid treasury");
      require(ERC20(address(_asset)).decimals() <= 18, "asset decimals must be <= 18");

      asset = _asset;
      isNativeAsset = _isNativeAsset;
      protocolFee = _protocolFee;
      lendingPoolConfig = _lendingPoolConfig;
      treasury = _treasury;
      maxCapacity = _maxCapacity;
      assetDecimals = ERC20(address(asset)).decimals();
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Returns the total value of the lending pool, i.e totalBorrows + interest + totalAvailableSupply
    * @return totalValue   Total value of lending pool in token decimals
  */
  function totalValue() public view returns (uint256) {
    uint256 interest = _pendingInterest(0);
    return totalBorrows + interest + totalAvailableSupply();
  }

  /**
    * Returns the available balance of asset in the pool
    * @return totalAvailableSupply   Balance of asset in the pool in token decimals
  */
  function totalAvailableSupply() public view returns (uint256) {
    return asset.balanceOf(address(this));
  }

  /**
    * Returns the the borrow utilization rate of the pool
    * @return utilizationRate   Ratio of borrows to total liquidity in 1e18
  */
  function utilizationRate() public view returns (uint256){
    uint256 totalValue_ = totalValue();

    return (totalValue_ == 0) ? 0 : totalBorrows * SAFE_MULTIPLIER / totalValue_;
  }

  /**
    * Returns the exchange rate for ibToken to asset
    * @return exchangeRate   Ratio of ibToken to underlying asset in token decimals
  */
  function exchangeRate() public view returns (uint256) {
    uint256 totalValue_ = totalValue();
    uint256 totalSupply_ = totalSupply();

    if (totalValue_ == 0 || totalSupply_ == 0) {
      return 1 * (10 ** assetDecimals);
    } else {
      return totalValue_ * SAFE_MULTIPLIER / totalSupply_;
    }
  }

  /**
    * Returns the current borrow APR
    * @return borrowAPR   Current borrow rate in 1e18
  */
  function borrowAPR() public view returns (uint256) {
    return lendingPoolConfig.interestRateAPR(totalBorrows, totalAvailableSupply());
  }

  /**
    * Returns the current lending APR; borrowAPR * utilization * (1 - protocolFee)
    * @return lendingAPR   Current lending rate in 1e18
  */
  function lendingAPR() public view returns (uint256) {
    uint256 borrowAPR_ = borrowAPR();
    uint256 utilizationRate_ = utilizationRate();

    if (borrowAPR_ == 0 || utilizationRate_ == 0) {
      return 0;
    } else {
      return borrowAPR_ * utilizationRate_
                         / SAFE_MULTIPLIER
                         * ((1 * SAFE_MULTIPLIER) - protocolFee)
                         / SAFE_MULTIPLIER;
    }
  }

  /**
    * Returns a borrower's maximum total repay amount taking into account ongoing interest
    * @param _address   Borrower's address
    * @return maxRepay   Borrower's total repay amount of assets in assets decimals
  */
  function maxRepay(address _address) public view returns (uint256) {
    if (totalBorrows == 0) {
      return 0;
    } else {
      uint256 interest = _pendingInterest(0);

      return borrowers[_address].debt * (totalBorrows + interest) / totalBorrowDebt;
    }
  }

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved addresses for borrowers
  */
  modifier onlyBorrower() {
    require(borrowers[msg.sender].approved, "Borrower not approved");
    _;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * Deposits asset into lending pool and mint ibToken to user
    * @param _assetAmount Amount of asset tokens to deposit in token decimals
    * @param _minSharesAmount Minimum amount of ibTokens tokens to receive on deposit
  */
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) external payable nonReentrant whenNotPaused {
    require(_assetAmount + totalValue() <= maxCapacity, "Exceeded max capacity");

    if (msg.value > 0) {
      require(isNativeAsset, "Only accepting native token");
      require(_assetAmount == msg.value, "Amount != msg.value");

      IWAVAX(address(asset)).deposit{ value: msg.value }();
    } else {
      require(!isNativeAsset, "Only accepting non-native token");
      require(_assetAmount > 0, "Deposited amount must be > 0");
      asset.safeTransferFrom(msg.sender, address(this), _assetAmount);
    }

    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(_assetAmount);

    uint256 sharesAmount = _mintShares(_assetAmount);

    require(sharesAmount >= _minSharesAmount, "Shares received less than minimum");

    emit Deposit(msg.sender, sharesAmount, _assetAmount);
  }

  /**
    * Withdraws asset from lending pool, burns ibToken from user
    * @param _ibTokenAmount Amount of ibTokens to burn in 1e18
    * @param _minWithdrawAmount Minimum amount of asset tokens to receive on withdrawal
  */
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external nonReentrant whenNotPaused {
    require(_ibTokenAmount > 0, "Amount must be > 0");
    require(_ibTokenAmount <= balanceOf(msg.sender), "Withdraw amount exceeds balance");

    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(0);

    uint256 withdrawAmount = _burnShares(_ibTokenAmount);

    require(withdrawAmount >= _minWithdrawAmount, "Assets received less than minimum");

    if (isNativeAsset) {
      IWAVAX(address(asset)).withdraw(withdrawAmount);
      (bool success, ) = msg.sender.call{value: withdrawAmount}("");
      require(success, "Transfer failed.");
    } else {
      asset.safeTransfer(msg.sender, withdrawAmount);
    }

    emit Withdraw(msg.sender, _ibTokenAmount, withdrawAmount);
  }

  /**
    * Borrow asset from lending pool, adding debt
    * @param _borrowAmount Amount of tokens to borrow in token decimals
  */
  function borrow(uint256 _borrowAmount) external nonReentrant whenNotPaused onlyBorrower {
    require(_borrowAmount > 0, "Amount must be > 0");
    require(_borrowAmount <= totalAvailableSupply(), "Not enough lending liquidity to borrow");

    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(0);

    // Calculate debt amount
    uint256 debt = totalBorrows == 0 ? _borrowAmount : _borrowAmount * totalBorrowDebt / totalBorrows;

    // Update pool state
    totalBorrows = totalBorrows + _borrowAmount;
    totalBorrowDebt = totalBorrowDebt + debt;

    // Update borrower state
    Borrower storage borrower_ = borrowers[msg.sender];
    borrower_.debt = borrower_.debt + debt;
    borrower_.lastUpdatedAt = block.timestamp;

    // Transfer borrowed token from pool to manager
    asset.safeTransfer(msg.sender, _borrowAmount);

    emit Borrow(msg.sender, debt, _borrowAmount);
  }

  /**
    * Repay asset to lending pool, reducing debt
    * @param _repayAmount Amount of debt to repay in token decimals
  */
  function repay(uint256 _repayAmount) external nonReentrant whenNotPaused {
    require(_repayAmount > 0, "Amount must be > 0");

    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(0);

    uint256 maxRepay_ = maxRepay(msg.sender);

    require(maxRepay_ > 0, "Repay amount must be > 0");

    if (_repayAmount > maxRepay_) {
      _repayAmount = maxRepay_;
    }

    // Transfer repay tokens to the pool
    asset.safeTransferFrom(msg.sender, address(this), _repayAmount);

    uint256 borrowerTotalRepayAmount = maxRepay_;

    // Calculate debt to reduce based on repay amount
    uint256 debt = _repayAmount * borrowers[msg.sender].debt / borrowerTotalRepayAmount;

    // Update pool state
    totalBorrows = totalBorrows - _repayAmount;
    totalBorrowDebt = totalBorrowDebt - debt;

    // Update borrower state
    Borrower storage borrower_ = borrowers[msg.sender];
    borrower_.debt = borrower_.debt - debt;
    borrower_.lastUpdatedAt = block.timestamp;

    emit Repay(msg.sender, debt, _repayAmount);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Calculate amount of ibTokens owed to depositor and mints them
    * @param _assetAmount  Amount of tokens to deposit in token decimals
    * @return shares  Amount of ibTokens minted in 1e18
  */
  function _mintShares(uint256 _assetAmount) internal returns (uint256) {
    // Calculate liquidity share amount
    uint256 shares = totalSupply() == 0 ?
      _assetAmount * _to18ConversionFactor() :
      _assetAmount * totalSupply() / (totalValue() - _assetAmount);

    // Mint ibToken to user equal to liquidity share amount
    _mint(msg.sender, shares);

    return shares;
  }

  /**
    * Calculate amount of asset owed to depositor based on ibTokens burned
    * @param _sharesAmount Amount of shares to burn in 1e18
    * @return withdrawAmount  Amount of assets withdrawn based on ibTokens burned in token decimals
  */
  function _burnShares(uint256 _sharesAmount) internal returns (uint256) {
    // Calculate amount of assets to withdraw based on shares to burn
    uint256 totalShares = totalSupply();
    uint256 withdrawAmount = totalShares == 0 ?
      0 :
      _sharesAmount * totalValue() / totalShares;

    // Burn user's ibTokens
    _burn(msg.sender, _sharesAmount);

    return withdrawAmount;
  }

  /**
    * Interest accrual function that calculates accumulated interest from lastUpdatedTimestamp and add to totalBorrows
    * @param _value Additonal amount of assets being deposited in token decimals
  */
  function _updatePoolWithInterestsAndTimestamp(uint256 _value) internal {
    uint256 interest = _pendingInterest(_value);
    uint256 toReserve = interest * protocolFee / SAFE_MULTIPLIER;
    asset.safeTransfer(treasury, toReserve);
    totalBorrows = totalBorrows + interest;
    lastUpdatedAt = block.timestamp;
  }

  /**
    * Returns the pending interest that will be accrued to the reserves in the next call
    * @param _value Newly deposited assets to be subtracted off total available liquidity in token decimals
    * @return interest  Amount of interest owned in token decimals
  */
  function _pendingInterest(uint256 _value) internal view returns (uint256) {
    if (totalBorrows == 0) return 0;

    uint256 totalAvailableSupply_ = totalAvailableSupply();
    uint256 timePassed = block.timestamp - lastUpdatedAt;
    uint256 floating = totalAvailableSupply_ == 0 ? 0 : totalAvailableSupply_ - _value;
    uint256 ratePerSec = lendingPoolConfig.interestRatePerSecond(totalBorrows, floating);

    // First division is due to ratePerSec being in 1e18
    // Second division is due to ratePerSec being in 1e18
    return ratePerSec * totalBorrows
      * timePassed
      / SAFE_MULTIPLIER;
  }

  /**
    * Conversion factor for tokens with less than 1e18 to return in 1e18
    * @return conversionFactor  Amount of decimals for conversion to 1e18
  */
  function _to18ConversionFactor() internal view returns (uint256) {
    unchecked {
      if (assetDecimals == 18) return 1;

      return 10**(18 - assetDecimals);
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Update protocol fee
    * @param _newProtocolFee  Fee percentage in 1e18
  */
  function updateProtocolFee(uint256 _newProtocolFee) external onlyOwner {
    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(0);

    emit ProtocolFeeUpdated(msg.sender, protocolFee, _newProtocolFee);

    protocolFee = _newProtocolFee;
  }

  /**
    * Approve address to borrow from this pool
    * @param _borrower  Borrower address
  */
  function approveBorrower(address _borrower) external onlyOwner {
    require(!borrowers[_borrower].approved, "Borrower already approved");

    borrowers[_borrower].approved = true;
  }

  /**
    * Revoke address to borrow from this pool
    * @param _borrower  Borrower address
  */
  function revokeBorrower(address _borrower) external onlyOwner {
    require(borrowers[_borrower].approved, "Borrower already revoked");

    borrowers[_borrower].approved = false;
  }

  /**
    * Emergency repay of assets to lending pool to clear bad debt
    * @param _repayAmount Amount of debt to repay in token decimals
  */
  function emergencyRepay(uint256 _repayAmount, address _defaulter) external nonReentrant whenPaused onlyOwner {
    require(_repayAmount > 0, "Amount must be > 0");

    uint256 maxRepay_ = maxRepay(_defaulter);

    require(maxRepay_ > 0, "Repay amount must be > 0");

    if (_repayAmount > maxRepay_) {
      _repayAmount = maxRepay_;
    }

    // Update pool with accrued interest and latest timestamp
    _updatePoolWithInterestsAndTimestamp(0);

    uint256 borrowerTotalRepayAmount = maxRepay_;

    // Calculate debt to reduce based on repay amount
    uint256 debt = _repayAmount * borrowers[_defaulter].debt / borrowerTotalRepayAmount;

    // Update pool state
    totalBorrows = totalBorrows - _repayAmount;
    totalBorrowDebt = totalBorrowDebt - debt;

    // Update borrower state
    borrowers[_defaulter].debt = borrowers[_defaulter].debt - debt;
    borrowers[_defaulter].lastUpdatedAt = block.timestamp;

    // Transfer repay tokens to the pool
    asset.safeTransferFrom(msg.sender, address(this), _repayAmount);

    emit Repay(msg.sender, debt, _repayAmount);
  }

  /**
    * Emergency pause of lending pool that pauses all deposits, borrows and normal withdrawals
  */
  function emergencyPause() external onlyOwner whenNotPaused {
    _pause();
  }

  /**
    * Emergency resume of lending pool that pauses all deposits, borrows and normal withdrawals
  */
  function emergencyResume() external onlyOwner whenPaused {
    _unpause();
  }

  /**
    * Update max capacity value
    * @param _maxCapacity Capacity value in token decimals (amount)
  */
  function updateMaxCapacity(uint256 _maxCapacity) external onlyOwner {
    maxCapacity = _maxCapacity;

    emit UpdateMaxCapacity(_maxCapacity);
  }

  /**
    * Update treasury address
    * @param _treasury Treasury address
  */
  function updateTreasury(address _treasury) external onlyOwner {
    require(_treasury != address(0), "Invalid address");
    treasury = _treasury;
  }

  /* ========== FALLBACK FUNCTIONS ========== */

  /**
    * Fallback function to receive native token sent to this contract,
    * needed for receiving native token to contract when unwrapped
  */
  receive() external payable {
    require(isNativeAsset, "Lending pool asset not native token");
  }
}