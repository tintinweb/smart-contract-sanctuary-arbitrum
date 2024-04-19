// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice A simple library to work with arrays
 */
library ArrayHelper {
    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than or equal to the `element_`. The time complexity is O(log n)
     * @param array the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array` if no such element
     */
    function lowerBound(
        uint256[] storage array,
        uint256 element_
    ) internal view returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array[mid_] >= element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than the `element_`. The time complexity is O(log n)
     * @param array the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array` if no such element
     */
    function upperBound(
        uint256[] storage array,
        uint256 element_
    ) internal view returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array[mid_] > element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice The function that calculates the sum of all array elements from `beginIndex_` to
     * `endIndex_` inclusive using its prefix sum array
     * @param beginIndex_ the index of the first range element
     * @param endIndex_ the index of the last range element
     * @return the sum of all elements of the range
     */
    function getRangeSum(
        uint256[] storage prefixes,
        uint256 beginIndex_,
        uint256 endIndex_
    ) internal view returns (uint256) {
        require(beginIndex_ <= endIndex_, "ArrayHelper: wrong range");

        if (beginIndex_ == 0) {
            return prefixes[endIndex_];
        }

        return prefixes[endIndex_] - prefixes[beginIndex_ - 1];
    }

    /**
     * @notice The function to compute the prefix sum array
     * @param arr_ the initial array to be turned into the prefix sum array
     * @return prefixes_ the prefix sum array
     */
    function countPrefixes(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory prefixes_) {
        if (arr_.length == 0) {
            return prefixes_;
        }

        prefixes_ = new uint256[](arr_.length);
        prefixes_[0] = arr_[0];

        for (uint256 i = 1; i < prefixes_.length; i++) {
            prefixes_[i] = prefixes_[i - 1] + arr_[i];
        }
    }

    /**
     * @notice The function to reverse an array
     * @param arr_ the array to reverse
     * @return reversed_ the reversed array
     */
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(string[] memory arr_) internal pure returns (string[] memory reversed_) {
        reversed_ = new string[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    function reverse(bytes32[] memory arr_) internal pure returns (bytes32[] memory reversed_) {
        reversed_ = new bytes32[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to insert an array into the other array
     * @param to_ the array to insert into
     * @param index_ the insertion starting index
     * @param what_ the array to be inserted
     * @return the index to start the next insertion from
     */
    function insert(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    function insert(
        bytes32[] memory to_,
        uint256 index_,
        bytes32[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function that free memory that was allocated for array
     * @param array_ the array to crop
     * @param newLength_ the new length of the array
     * @return ref to cropped array
     */
    function crop(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure returns (uint256[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        address[] memory array_,
        uint256 newLength_
    ) internal pure returns (address[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(bool[] memory array_, uint256 newLength_) internal pure returns (bool[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        string[] memory array_,
        uint256 newLength_
    ) internal pure returns (string[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    function crop(
        bytes32[] memory array_,
        uint256 newLength_
    ) internal pure returns (bytes32[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice A simple library to work with sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     * @notice The function to insert an array of elements into the set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice ## Usage example:
 *
 * ```
 * using StringSet for StringSet.Set;
 *
 * StringSet.Set internal set;
 * ```
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice The function add value to set
     * @param set the set object
     * @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function remove value to set
     * @param set the set object
     * @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function returns true if value in the set
     * @param set the set object
     * @param value_ the value to search in set
     * @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     * @notice The function returns length of set
     * @param set the set object
     * @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice The function returns value from set by index
     * @param set the set object
     * @param index_ the index of slot in set
     * @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     * @notice The function that returns values the set stores, can be very expensive to call
     * @param set the set object
     * @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This library is used to convert numbers that use token's N decimals to M decimals.
 * Comes extremely handy with standardizing the business logic that is intended to work with many different ERC20 tokens
 * that have different precision (decimals). One can perform calculations with 18 decimals only and resort to convertion
 * only when the payouts (or interactions) with the actual tokes have to be made.
 *
 * The best usage scenario involves accepting and calculating values with 18 decimals throughout the project, despite the tokens decimals.
 *
 * Also it is recommended to call `round18()` function on the first execution line in order to get rid of the
 * trailing numbers if the destination decimals are less than 18
 *
 * ## Usage example:
 *
 * ```
 * contract Taker {
 *     ERC20 public USDC;
 *     uint256 public paid;
 *
 *     . . .
 *
 *     function pay(uint256 amount) external {
 *         uint256 decimals = USDC.decimals();
 *         amount = amount.round18(decimals);
 *
 *         paid += amount;
 *         USDC.transferFrom(msg.sender, address(this), amount.from18(decimals));
 *     }
 * }
 * ```
 */
library DecimalsConverter {
    /**
     * @notice The function to get the decimals of ERC20 token. Needed for bytecode optimization
     * @param token_ the ERC20 token
     * @return the decimals of provided token
     */
    function decimals(address token_) internal view returns (uint8) {
        return ERC20(token_).decimals();
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision
     * @param amount_ the number to convert
     * @param token_ the token, whose decimals will be precised to 18
     * @return the number brought to 18 decimals of precision
     */
    function to18(uint256 amount_, address token_) internal view returns (uint256) {
        return to18(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision
     * @param amount_ the number to convert
     * @param baseDecimals_ the current precision of the number
     * @return the number brought to 18 decimals of precision
     */
    function to18(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return convert(amount_, baseDecimals_, 18);
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision. Reverts if output is zero
     * @param amount_ the number to convert
     * @param token_ the token, whose decimals will be precised to 18
     * @return the number brought to 18 decimals of precision
     */
    function to18Safe(uint256 amount_, address token_) internal view returns (uint256) {
        return to18Safe(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision. Reverts if output is zero
     * @param amount_ the number to convert
     * @param baseDecimals_ the current precision of the number
     * @return the number brought to 18 decimals of precision
     */
    function to18Safe(uint256 amount_, uint256 baseDecimals_) internal pure returns (uint256) {
        return _convertSafe(amount_, baseDecimals_, _to18);
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision
     * @param amount_ the number to covert
     * @param token_ the token, whose decimals will be used as desired decimals of precision
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18(uint256 amount_, address token_) internal view returns (uint256) {
        return from18(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision
     * @param amount_ the number to covert
     * @param destDecimals_ the desired precision decimals
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return convert(amount_, 18, destDecimals_);
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision.
     * Reverts if output is zero
     * @param amount_ the number to covert
     * @param token_ the token, whose decimals will be used as desired decimals of precision
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18Safe(uint256 amount_, address token_) internal view returns (uint256) {
        return from18Safe(amount_, decimals(token_));
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision.
     * Reverts if output is zero
     * @param amount_ the number to covert
     * @param destDecimals_ the desired precision decimals
     * @return the number brought from 18 to desired decimals of precision
     */
    function from18Safe(uint256 amount_, uint256 destDecimals_) internal pure returns (uint256) {
        return _convertSafe(amount_, destDecimals_, _from18);
    }

    /**
     * @notice The function to substitute the trailing digits of a number with zeros
     * @param amount_ the number to round. Should be with 18 precision decimals
     * @param decimals_ the required number precision
     * @return the rounded number. Comes with 18 precision decimals
     */
    function round18(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return to18(from18(amount_, decimals_), decimals_);
    }

    /**
     * @notice The function to substitute the trailing digits of a number with zeros. Reverts if output is zero
     * @param amount_ the number to round. Should be with 18 precision decimals
     * @param decimals_ the required number precision
     * @return the rounded number. Comes with 18 precision decimals
     */
    function round18Safe(uint256 amount_, uint256 decimals_) internal pure returns (uint256) {
        return _convertSafe(amount_, decimals_, round18);
    }

    /**
     * @notice The function to do the token precision convertion
     * @param amount_ the amount to convert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @return the converted number
     */
    function convert(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) internal view returns (uint256) {
        return convert(amount_, uint256(decimals(baseToken_)), uint256(decimals(destToken_)));
    }

    /**
     * @notice The function to do the precision convertion
     * @param amount_ the amount to covert
     * @param baseDecimals_ current number precision
     * @param destDecimals_ desired number precision
     * @return the converted number
     */
    function convert(
        uint256 amount_,
        uint256 baseDecimals_,
        uint256 destDecimals_
    ) internal pure returns (uint256) {
        if (baseDecimals_ > destDecimals_) {
            amount_ = amount_ / 10 ** (baseDecimals_ - destDecimals_);
        } else if (baseDecimals_ < destDecimals_) {
            amount_ = amount_ * 10 ** (destDecimals_ - baseDecimals_);
        }

        return amount_;
    }

    /**
     * @notice The function to do the token precision convertion. Reverts if output is zero
     * @param amount_ the amount to convert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @return the converted number
     */
    function convertTokensSafe(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) internal view returns (uint256) {
        return _convertTokensSafe(amount_, baseToken_, destToken_, _convertTokens);
    }

    /**
     * @notice The function to bring the number to 18 decimals of precision
     * @param amount_ the number to convert
     * @param baseDecimals_ the current precision of the number
     * @return the number brought to 18 decimals of precision
     */
    function _to18(uint256 amount_, uint256 baseDecimals_) private pure returns (uint256) {
        return convert(amount_, baseDecimals_, 18);
    }

    /**
     * @notice The function to bring the number from 18 decimals to the desired decimals of precision
     * @param amount_ the number to covert
     * @param destDecimals_ the desired precision decimals
     * @return the number brought from 18 to desired decimals of precision
     */
    function _from18(uint256 amount_, uint256 destDecimals_) private pure returns (uint256) {
        return convert(amount_, 18, destDecimals_);
    }

    /**
     * @notice The function to do the token precision convertion
     * @param amount_ the amount to convert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @return the converted number
     */
    function _convertTokens(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) private view returns (uint256) {
        return convert(amount_, uint256(decimals(baseToken_)), uint256(decimals(destToken_)));
    }

    /**
     * @notice The function wrapper to do the safe precision convertion. Reverts if output is zero
     * @param amount_ the amount to covert
     * @param decimals_ the precision decimals
     * @param _convertFunc the internal function pointer to "from", "to", or "round" functions
     * @return conversionResult_ the convertion result
     */
    function _convertSafe(
        uint256 amount_,
        uint256 decimals_,
        function(uint256, uint256) internal pure returns (uint256) _convertFunc
    ) private pure returns (uint256 conversionResult_) {
        conversionResult_ = _convertFunc(amount_, decimals_);

        require(conversionResult_ > 0, "DecimalsConverter: conversion failed");
    }

    /**
     * @notice The function wrapper to do the safe precision convertion for ERC20 tokens. Reverts if output is zero
     * @param amount_ the amount to covert
     * @param baseToken_ current token
     * @param destToken_ desired token
     * @param _convertFunc the internal function pointer to "from", "to", or "round" functions
     * @return conversionResult_ the convertion result
     */
    function _convertTokensSafe(
        uint256 amount_,
        address baseToken_,
        address destToken_,
        function(uint256, address, address) internal view returns (uint256) _convertFunc
    ) private view returns (uint256 conversionResult_) {
        conversionResult_ = _convertFunc(amount_, baseToken_, destToken_);

        require(conversionResult_ > 0, "DecimalsConverter: conversion failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice This library simplifies non-obvious type castings
 */
library TypeCaster {
    /**
     * @notice The function that casts the list of `X`-type elements to the list of uint256
     * @param from_ the list of `X`-type elements
     * @return array_ the list of uint256
     */
    function asUint256Array(
        bytes32[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asUint256Array(
        address[] memory from_
    ) internal pure returns (uint256[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the list of `X`-type elements to the list of addresses
     * @param from_ the list of `X`-type elements
     * @return array_ the list of addresses
     */
    function asAddressArray(
        bytes32[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asAddressArray(
        uint256[] memory from_
    ) internal pure returns (address[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function that casts the list of `X`-type elements to the list of bytes32
     * @param from_ the list of `X`-type elements
     * @return array_ the list of bytes32
     */
    function asBytes32Array(
        uint256[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    function asBytes32Array(
        address[] memory from_
    ) internal pure returns (bytes32[] memory array_) {
        assembly {
            array_ := from_
        }
    }

    /**
     * @notice The function to transform an element into an array
     * @param from_ the element
     * @return array_ the element as an array
     */
    function asSingletonArray(uint256 from_) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = from_;
    }

    function asSingletonArray(address from_) internal pure returns (address[] memory array_) {
        array_ = new address[](1);
        array_[0] = from_;
    }

    function asSingletonArray(bool from_) internal pure returns (bool[] memory array_) {
        array_ = new bool[](1);
        array_[0] = from_;
    }

    function asSingletonArray(string memory from_) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = from_;
    }

    function asSingletonArray(bytes32 from_) internal pure returns (bytes32[] memory array_) {
        array_ = new bytes32[](1);
        array_[0] = from_;
    }

    /**
     * @notice The function to convert static array to dynamic
     * @param static_ the static array to convert
     * @return dynamic_ the converted dynamic array
     */
    function asDynamic(
        uint256[1] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        uint256[2] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        uint256[3] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        uint256[4] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        uint256[5] memory static_
    ) internal pure returns (uint256[] memory dynamic_) {
        dynamic_ = new uint256[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(
        address[1] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        address[2] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        address[3] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        address[4] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        address[5] memory static_
    ) internal pure returns (address[] memory dynamic_) {
        dynamic_ = new address[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(bool[1] memory static_) internal pure returns (bool[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(bool[2] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(bool[3] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(bool[4] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(bool[5] memory static_) internal pure returns (bool[] memory dynamic_) {
        dynamic_ = new bool[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(string[1] memory static_) internal pure returns (string[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(string[2] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(string[3] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(string[4] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(string[5] memory static_) internal pure returns (string[] memory dynamic_) {
        dynamic_ = new string[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function asDynamic(
        bytes32[1] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        return asSingletonArray(static_[0]);
    }

    function asDynamic(
        bytes32[2] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](2);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 2);
    }

    function asDynamic(
        bytes32[3] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](3);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 3);
    }

    function asDynamic(
        bytes32[4] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](4);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 4);
    }

    function asDynamic(
        bytes32[5] memory static_
    ) internal pure returns (bytes32[] memory dynamic_) {
        dynamic_ = new bytes32[](5);

        uint256 pointerS_;
        uint256 pointerD_;

        assembly {
            pointerS_ := static_
            pointerD_ := dynamic_
        }

        _copy(pointerS_, pointerD_, 5);
    }

    function _copy(uint256 locationS_, uint256 locationD_, uint256 length_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, length_) {
                i := add(i, 1)
            } {
                locationD_ := add(locationD_, 0x20)

                mstore(locationD_, mload(locationS_))

                locationS_ := add(locationS_, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IP2PSports
 * @dev Interface for a peer-to-peer sports betting platform.
 * This interface defines the basic events, enums, and structs required for creating, joining, resolving,
 * and canceling challenges, as well as managing and withdrawing bets and admin shares in a decentralized sports betting platform.
 */
interface IP2PSports {
    /**
     * @dev Emitted when a new challenge is created.
     * @param challengeId Unique identifier for the challenge.
     * @param token Address of the token used for betting.
     * @param by Address of the user who created the challenge.
     */
    event ChallengeCreated(uint256 challengeId, address token, address by);

    /**
     * @dev Emitted when a user joins an existing challenge.
     * @param challengeId Unique identifier for the challenge.
     * @param amount Amount of the token bet by the user.
     * @param by Address of the user who joined the challenge.
     */
    event ChallengeJoined(uint256 challengeId, uint256 amount, address by);

    /**
     * @dev Emitted when a challenge is resolved.
     * @param challengeId Unique identifier for the challenge.
     * @param finalOutcome Final outcome of the challenge (1 for win, 2 for loss, etc.).
     */
    event ChallengeResolved(uint256 challengeId, uint8 finalOutcome);

    /**
     * @dev Emitted when a challenge is canceled.
     * @param challengeId Unique identifier for the canceled challenge.
     */
    event ChallengeCanceled(uint256 challengeId);

    /**
     * @dev Emitted when a user cancels their participation in a challenge.
     * @param user Address of the user canceling their participation.
     * @param challengeId Unique identifier for the challenge.
     */
    event CancelParticipation(address user, uint256 challengeId);

    /**
     * @dev Emitted after the resolution of a challenge, detailing the redistribution of funds.
     * @param challengeId Unique identifier for the challenge.
     * @param winners Array of addresses of the winning users.
     * @param winnersProfit Array of profits earned by each winning user.
     * @param losers Array of addresses of the losing users.
     * @param losersLoss Array of amounts lost by each losing user.
     */
    event ChallengeFundsMoved(
        uint256 challengeId,
        address[] winners,
        uint256[] winnersProfit,
        address[] losers,
        uint256[] losersLoss
    );

    /**
     * @dev Emitted when a user withdraws their winnings or funds.
     * @param token Address of the token being withdrawn.
     * @param amount Amount of the token being withdrawn.
     * @param by Address of the user performing the withdrawal.
     */
    event UserWithdrawn(address token, uint256 amount, address by);

    /**
     * @dev Emitted when the admin receives a share from challenge participation fees.
     * @param challengeId Unique identifier for the challenge from which the fees were taken.
     * @param token Address of the token in which the fees were paid.
     * @param amount Amount of the fees received.
     */
    event AdminReceived(uint256 challengeId, address token, uint256 amount);

    /**
     * @dev Emitted when the admin withdraws their accumulated shares.
     * @param token Address of the token being withdrawn.
     * @param amount Amount of the token being withdrawn.
     */
    event AdminWithdrawn(address token, uint256 amount);

    /**
     * @dev Enum for tracking the status of a challenge.
     */
    enum ChallengeStatus {
        None,
        CanBeCreated,
        Betting,
        Awaiting,
        Canceled,
        ResolvedFor,
        ResolvedAgainst,
        ResolvedDraw
    }

    /**
     * @dev Enum for distinguishing between individual and group challenges.
     */
    enum ChallengeType {
        Individual,
        Group
    }

    /**
     * @dev Struct for storing details about a challenge.
     */
    struct Challenge {
        address token; // Token used for betting.
        address[] usersFor; // Users betting for the outcome.
        address[] usersAgainst; // Users betting against the outcome.
        uint256 amountFor; // Total amount bet for the outcome.
        uint256 amountAgainst; // Total amount bet against the outcome.
        ChallengeStatus status; // Current status of the challenge.
        ChallengeType challengeType; // Type of challenge (individual or group).
        uint256 startTime; // Start time of the challenge.
        uint256 endTime; // End time of the challenge.
        address creator; // Creator of the challenge.
    }

    /**
     * @dev Struct for storing a user's bet on a challenge.
     */
    struct UserBet {
        uint256 amount; // Amount of the bet.
        uint8 decision; // User's decision (for or against).
    }

    /**
     * @dev Struct for defining admin share rules based on bet thresholds.
     */
    struct AdminShareRule {
        uint256[] thresholds; // Bet amount thresholds for different share percentages.
        uint256[] percentages; // Admin share percentages for corresponding thresholds.
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@solarity/solidity-lib/libs/arrays/SetHelper.sol";
import "@solarity/solidity-lib/libs/arrays/ArrayHelper.sol";
import "@solarity/solidity-lib/libs/utils/TypeCaster.sol";
import "@solarity/solidity-lib/libs/decimals/DecimalsConverter.sol";

import "./interfaces/IP2PSports.sol";

import "@solarity/solidity-lib/utils/Globals.sol";

/// @title P2PSports: A Peer-to-Peer Sports Betting Smart Contract
/** @notice This contract allows users to create and join sports betting challenges, bet on outcomes,
 * and withdraw winnings in a decentralized manner. It supports betting with STMX token and other ERC20 tokens, along with ETH
 * and uses Chainlink for price feeds to calculate admin shares.
 * @dev The contract uses OpenZeppelin's Ownable and ReentrancyGuard for access control and reentrancy protection,
 * and utilizes libraries from solidity-lib for array and decimal manipulations.
 */
contract P2PSports is IP2PSports, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SetHelper for EnumerableSet.AddressSet;
    using DecimalsConverter for *;
    using ArrayHelper for uint256[];
    using TypeCaster for *;
    /// @notice Backend server address to resolve, cancel challenges or some additional control.
    address public backend;
    /// @notice Token address for the STMX token, used as one of the betting currencies

    // Configuration / Validation parameters for different betting logics
    uint256 public maxAdminSharePercentage;
    uint256 public maxChallengersEachSide;
    uint256 public maxChallengesToResolve;
    uint256 public maxWinnersGroupChallenge;
    uint256 public awaitingTimeForPublicCancel;
    uint256 public defaultOracleDecimals;
    uint256 public minUSDBetAmount;

    /// @notice ChallengeId of the last challenge created
    uint256 public latestChallengeId;

    /// @notice Flag to allow or restrict creations or joining challenges
    bool public bettingAllowed;

    // Internal storage for tokens, price feeds, challenges, and bets
    EnumerableSet.AddressSet internal _allTokens;
    EnumerableSet.AddressSet internal _oraclessTokens;
    EnumerableSet.AddressSet internal _allowedTokens;
    mapping(address => AggregatorV3Interface) internal _priceFeeds;
    mapping(uint256 => Challenge) internal _challenges;
    mapping(address => mapping(uint256 => UserBet)) internal _userChallengeBets;
    mapping(address => mapping(address => uint256)) internal _withdrawables;
    mapping(address => AdminShareRule) internal _adminShareRules;
    mapping(address => uint256) internal _oraclessTokensMinBetAmount;

    /// @dev Ensures the function is called only by the backend address
    modifier onlyBackend() {
        _onlyBackend();
        _;
    }

    /// @notice Initializes the contract with provided addresses and tokens
    /** @dev Sets initial configuration for the contract and allows specified tokens.
     * @param backend_ Address of the backend server for challenge resolution and control
     */
    constructor(address backend_) {
        require(backend_ != address(0), "backend should be non-zero address");

        // Contract setup and initial token allowance
        backend = backend_;
        maxAdminSharePercentage = 20 * PRECISION;
        maxChallengersEachSide = 50;
        maxChallengesToResolve = 10;
        maxWinnersGroupChallenge = 10;
        awaitingTimeForPublicCancel = 172800; //48 hours
        bettingAllowed = true;
        defaultOracleDecimals = 8;
        minUSDBetAmount = 10 * 10 ** 8;
    }

    /// @notice Creates a new challenge for betting
    /** @dev Emits a `ChallengeCreated` event and calls `joinChallenge` for the challenge creator.
     * @param token Address of the token used for betting (zero address for native currency)
     * @param amountFromWallet Amount to be bet from the creator's wallet
     * @param amountFromWithdrawables Amount to be bet from the creator's withdrawable balance
     * @param decision The side of the bet the creator is taking
     * @param challengeType The type of challenge (Individual or Group)
     * @param startTime Start time of the challenge
     * @param endTime End time of the challenge
     */
    function createChallenge(
        address token,
        uint256 amountFromWallet,
        uint256 amountFromWithdrawables,
        uint8 decision,
        ChallengeType challengeType,
        uint256 startTime,
        uint256 endTime
    ) external payable {
        uint256 challengeId = ++latestChallengeId;

        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Invalid times provided"
        );

        if (token == address(0)) {
            require(amountFromWallet == msg.value, "Amounts and values are different");
        } else {
            require(_allowedTokens.contains(token), "Token is not available for the challenge");
        }

        Challenge storage _challenge = _challenges[challengeId];

        _challenge.token = token;
        _challenge.status = ChallengeStatus.Betting;
        _challenge.challengeType = challengeType;
        _challenge.startTime = startTime;
        _challenge.endTime = endTime;
        _challenge.creator = msg.sender;

        emit ChallengeCreated(challengeId, token, msg.sender);

        joinChallenge(challengeId, amountFromWallet, amountFromWithdrawables, decision);
    }

    /// @notice Allows users to join an existing challenge with their bet
    /** @dev Emits a `ChallengeJoined` event if the join is successful.
     * @param challengeId ID of the challenge to join
     * @param amountFromWallet Amount to be bet from the user's wallet
     * @param amountFromWithdrawables Amount to be bet from the user's withdrawable balance
     * @param decision The side of the bet the user is taking
     */
    function joinChallenge(
        uint256 challengeId,
        uint256 amountFromWallet,
        uint256 amountFromWithdrawables,
        uint8 decision
    ) public payable {
        require(bettingAllowed, "Betting not allowed yet");

        Challenge memory challengeDetails = _challenges[challengeId];

        require(challengeExists(challengeId), "Challenge doesn't exist");

        if (challengeDetails.challengeType == ChallengeType.Group) {
            require(decision == 1, "Decision should be 1 for group challenge");
        } else {
            require(decision == 1 || decision == 2, "Decision should be 1 or 2");
        }
        require(
            _challengeStatus(challengeId) == ChallengeStatus.Betting,
            "Challenge not in progress"
        );
        require(
            _userChallengeBets[msg.sender][challengeId].decision == 0,
            "You can only challenge once"
        );

        if (_challenges[challengeId].token == address(0)) {
            require(amountFromWallet == msg.value, "Amounts and values are different");
        } else {
            require(msg.value == 0, "ETH value not needed");
        }

        _joinChallenge(challengeId, amountFromWallet, amountFromWithdrawables, decision);
    }

    /// @notice Checks if a challenge with the given ID exists
    /** @dev A challenge is considered to exist if its ID is greater than 0 and less than or equal to the latest challenge ID.
     * @param challengeId The ID of the challenge to check.
     * @return bool Returns true if the challenge exists, false otherwise.
     */
    function challengeExists(uint256 challengeId) public view returns (bool) {
        return challengeId > 0 && challengeId <= latestChallengeId;
    }

    /// @notice Withdraws available tokens for the sender
    /** @dev This function allows users to withdraw their available tokens from the contract. It uses the
     * nonReentrant modifier from OpenZeppelin to prevent reentrancy attacks. A `UserWithdrawn` event is
     * emitted upon a successful withdrawal.
     * @param token The address of the token to be withdrawn. Use the zero address for the native currency.
     *
     * Requirements:
     * - The sender must have a positive withdrawable balance for the specified token.
     * Emits a {UserWithdrawn} event indicating the token, amount, and the user who performed the withdrawal.
     */
    function withdraw(address token) external nonReentrant {
        uint256 amount = _withdrawables[msg.sender][token];
        require(amount > 0, "No withdrawables available");
        delete _withdrawables[msg.sender][token];
        _withdraw(token, msg.sender, amount);

        emit UserWithdrawn(token, amount, msg.sender);
    }

    /// @notice Resolves multiple challenges with their final outcomes
    /** @dev This function is called by the backend to resolve challenges that have reached their end time
     * and are in the awaiting status. It updates the status of each challenge based on its final outcome.
     * Only challenges of type `Individual` can be resolved using this function. A `ChallengeResolved` event is
     * emitted for each challenge that is resolved. This function uses the `onlyBackend` modifier to ensure
     * that only authorized backend addresses can call it, and `nonReentrant` to prevent reentrancy attacks.
     * @param challengeIds Array of IDs of the challenges to be resolved.
     * @param finalOutcomes Array of final outcomes for each challenge, where outcomes are defined as follows:
     * - 1: Side A wins,
     * - 2: Side B wins,
     * - 3: Draw.
     *
     * Requirements:
     * - The lengths of `challengeIds` and `finalOutcomes` must be the same and not exceed `maxChallengesToResolve`.
     * - Each challenge must exist, be in the `Awaiting` status, and be of type `Individual`.
     * - Each `finalOutcome` must be within the range [1,3].
     */
    function resolveChallenge(
        uint256[] memory challengeIds,
        uint8[] memory finalOutcomes
    ) external onlyBackend nonReentrant {
        require(
            challengeIds.length <= maxChallengesToResolve,
            "Length greater than max allowed limit"
        );
        require(
            challengeIds.length == finalOutcomes.length,
            "Number of challenge ids and final outcomes should be same"
        );
        for (uint256 i = 0; i < challengeIds.length; i++) {
            require(
                _challenges[challengeIds[i]].challengeType == ChallengeType.Individual,
                "Challenge type should be individual"
            );
            uint256 challengeId = challengeIds[i];
            uint8 finalOutcome = finalOutcomes[i];
            require(finalOutcome > 0 && finalOutcome < 4, "Final outcome can only be 1, 2, or 3");
            require(challengeExists(challengeId), "Challenge doesn't exist");
            require(
                _challengeStatus(challengeId) == ChallengeStatus.Awaiting,
                "Challenge not awaiting"
            );

            _challenges[challengeId].status = ChallengeStatus(finalOutcome + 4);

            emit ChallengeResolved(challengeId, finalOutcome);

            if (finalOutcome == 3) {
                _cancelBets(challengeId);
            } else {
                _calculateChallenge(challengeId, finalOutcome);
            }
        }
    }

    /// @notice Cancels a user's participation in a challenge
    /** @dev This function allows the backend to cancel a user's participation in a challenge, refunding their bet.
     * It can only be called by the backend and is protected against reentrancy attacks. The function checks if the
     * challenge exists and ensures that the challenge is either in the `Awaiting` or `Betting` status, implying that
     * it has not been resolved yet. Additionally, it verifies that the user has indeed placed a bet on the challenge.
     * After these checks, it calls an internal function `_cancelParticipation` to handle the logic for cancelling the
     * user's participation and processing the refund.
     * @param user The address of the user whose participation is to be cancelled.
     * @param challengeId The ID of the challenge from which the user's participation is to be cancelled.
     *
     * Requirements:
     * - The challenge must exist and be in a state where participation can be cancelled (`Awaiting` or `Betting`).
     * - The user must have participated in the challenge.
     * Uses the `onlyBackend` modifier to ensure only the backend can invoke this function, and `nonReentrant` for security.
     */
    function cancelParticipation(
        address user,
        uint256 challengeId
    ) external onlyBackend nonReentrant {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        ChallengeStatus status = _challengeStatus(challengeId);
        require(
            status == ChallengeStatus.Awaiting || status == ChallengeStatus.Betting,
            "Challenge participant can not be cancelled"
        );
        require(
            _userChallengeBets[user][challengeId].decision != 0,
            "User haven't participated yet"
        );

        _cancelParticipation(user, challengeId);
    }

    /// @notice Resolves a group challenge by determining winners and distributing profits
    /** @dev This function is used for resolving group challenges specifically, where multiple participants can win.
     * It can only be executed by the backend and is protected against reentrancy. The function ensures that the
     * challenge exists, is currently awaiting resolution, and is of the `Group` challenge type. It then validates
     * that the lengths of the winners and profits arrays match and do not exceed the maximum number of winners allowed.
     * Each winner's address must have participated in the challenge, and winners must be unique. The total of the profits
     * percentages must equal 100. Once validated, the challenge status is updated, and profits are calculated and
     * distributed to the winners based on the provided profits percentages.
     * @param challengeId The ID of the group challenge to resolve.
     * @param winners An array of addresses of the winners of the challenge.
     * @param profits An array of profit percentages corresponding to each winner, summing to 100.
     *
     * Requirements:
     * - The challenge must exist, be in the `Awaiting` status, and be of the `Group` type.
     * - The `winners` and `profits` arrays must have the same length and comply with the maximum winners limit.
     * - The sum of the `profits` percentages must equal 100.
     * Emits a {ChallengeResolved} event with the challenge ID and a hardcoded outcome of `5`, indicating group resolution.
     */
    function resolveGroupChallenge(
        uint256 challengeId,
        address[] calldata winners,
        uint256[] calldata profits
    ) external onlyBackend nonReentrant {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        require(
            _challengeStatus(challengeId) == ChallengeStatus.Awaiting,
            "Challenge not awaiting"
        );
        require(
            _challenges[challengeId].challengeType == ChallengeType.Group,
            "Challenge type should be Group"
        );
        require(
            winners.length == profits.length && winners.length <= maxWinnersGroupChallenge,
            "Winners and profits arrays should be of same length and should not exceed max winners"
        );

        uint256 totalProfit = 0;
        for (uint256 i = 0; i < winners.length; i++) {
            totalProfit += profits[i];
            require(
                _userChallengeBets[winners[i]][challengeId].decision != 0,
                "Invalid winner address"
            );
            // Ensure winners are unique within the array
            for (uint256 j = 0; j < i; j++) {
                require(winners[i] != winners[j], "Winners should be unique");
            }
        }

        require(totalProfit == (100 * DECIMAL), "Profits percentage total should be 100");

        _challenges[challengeId].status = ChallengeStatus.ResolvedFor;

        emit ChallengeResolved(challengeId, 5);

        _calculateGroupChallenge(challengeId, winners, profits);
    }

    /// @notice Cancels a challenge and refunds all participants
    /** @dev This function allows the backend to cancel a challenge if it's either awaiting resolution or still open for betting.
     * It ensures that the challenge exists and is in a cancelable state (either `Awaiting` or `Betting`). Upon cancellation,
     * the challenge's status is updated to `Canceled`, and all bets placed on the challenge are refunded to the participants.
     * This function is protected by the `onlyBackend` modifier to restrict access to the backend address, and `nonReentrant`
     * to prevent reentrancy attacks.
     * @param challengeId The ID of the challenge to be cancelled.
     *
     * Requirements:
     * - The challenge must exist and be in a state that allows cancellation (`Awaiting` or `Betting`).
     * Emits a {ChallengeCanceled} event upon successful cancellation, indicating which challenge was cancelled.
     */
    function cancelChallenge(uint256 challengeId) external onlyBackend nonReentrant {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        ChallengeStatus status = _challengeStatus(challengeId);
        require(
            status == ChallengeStatus.Awaiting || status == ChallengeStatus.Betting,
            "Challenge not awaiting or betting"
        );

        _challenges[challengeId].status = ChallengeStatus.Canceled;

        emit ChallengeCanceled(challengeId);

        _cancelBets(challengeId);
    }

    /// @notice Allows cancellation of challenges that have been awaiting resolution for too long
    /** @dev This function permits the cancellation of a challenge if it has been in the `Awaiting` status beyond
     * the specified waiting time. It's designed to ensure that challenges don't remain unresolved indefinitely,
     * allowing participants to recover their bets. The function checks that the challenge exists, is currently
     * awaiting resolution, and has surpassed the `awaitingTimeForPublicCancel` duration since its end time. Upon
     * fulfilling these conditions, the challenge's status is updated to `Canceled`, and bets are refunded.
     * Protected by `nonReentrant` to prevent reentrancy attacks.
     * @param challengeId The ID of the challenge to cancel due to prolonged awaiting status.
     *
     * Requirements:
     * - The challenge must exist and be in the `Awaiting` status.
     * - The current time must exceed the challenge's end time plus the allowed waiting period for cancellation.
     * Emits a {ChallengeCanceled} event upon successful cancellation.
     */
    function cancelLongAwaitingChallenge(uint256 challengeId) public nonReentrant {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        ChallengeStatus status = _challengeStatus(challengeId);
        Challenge memory challengeDetails = _challenges[challengeId];
        require(
            msg.sender == owner() || msg.sender == challengeDetails.creator,
            "Neither a owner, nor a challenge creator"
        );
        require(status == ChallengeStatus.Awaiting, "Challenge not awaiting");
        require(
            (challengeDetails.endTime + awaitingTimeForPublicCancel) < block.timestamp,
            "Challenge not long awaiting"
        );

        _challenges[challengeId].status = ChallengeStatus.Canceled;

        emit ChallengeCanceled(challengeId);

        _cancelBets(challengeId);
    }

    /// @notice Toggles the ability for users to place bets on challenges
    /** @dev This function allows the contract owner to enable or disable betting across the platform.
     * It's a straightforward toggle that sets the `bettingAllowed` state variable based on the input.
     * Access to this function is restricted to the contract owner through the `onlyOwner` modifier from
     * OpenZeppelin's Ownable contract, ensuring that only the owner can change the betting policy.
     * @param value_ A boolean indicating whether betting should be allowed (`true`) or not (`false`).
     */
    function allowBetting(bool value_) external onlyOwner {
        bettingAllowed = value_;
    }

    /// @notice Updates the minimum USD betting amount.
    /// @dev Can only be called by the contract owner.
    /// @param value_ The new minimum betting amount in USD.
    function changeMinUSDBettingAmount(uint256 value_) external onlyOwner {
        minUSDBetAmount = value_;
    }

    /// @notice Updates the address of the backend responsible for challenge resolutions and administrative actions
    /** @dev This function allows the contract owner to change the backend address to a new one.
     * Ensures the new backend address is not the zero address to prevent rendering the contract unusable.
     * The function is protected by the `onlyOwner` modifier, ensuring that only the contract owner has the authority
     * to update the backend address. This is crucial for maintaining the integrity and security of the contract's
     * administrative functions.
     * @param backend_ The new address to be set as the backend. It must be a non-zero address.
     *
     * Requirements:
     * - The new backend address cannot be the zero address, ensuring that the function call has meaningful intent.
     */
    function changeBackend(address backend_) external onlyOwner {
        require(backend_ != address(0), "backend should be non-zero");
        backend = backend_;
    }

    /// @notice Updates the start and end times for an existing challenge
    /** @dev This function is designed to adjust the timing of a challenge, allowing the backend to
     * modify the start and end times as necessary. It's particularly useful for correcting mistakes
     * or accommodating changes in event schedules. The function checks for the existence of the challenge
     * and validates that the new end time is indeed after the new start time to maintain logical consistency.
     * Access is restricted to the backend through the `onlyBackend` modifier to ensure that only authorized
     * personnel can make such adjustments.
     * @param challengeId The ID of the challenge whose timings are to be changed.
     * @param startTime The new start time for the challenge.
     * @param endTime The new end time for the challenge.
     *
     * Requirements:
     * - The challenge must exist to be eligible for time changes.
     * - The new end time must be greater than the new start time to ensure the challenge duration is positive.
     */
    function changeChallengeTime(
        uint256 challengeId,
        uint256 startTime,
        uint256 endTime
    ) external onlyBackend {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        require(endTime > startTime, "Challenge end time should be greater than start time");
        Challenge storage _challenge = _challenges[challengeId];
        _challenge.startTime = startTime;
        _challenge.endTime = endTime;
    }

    /// @notice Allows a batch of tokens to be used for betting, with optional price feeds for valuation
    /** @dev This function permits the contract owner to add tokens to the list of those allowed for betting.
     * It also associates Chainlink price feeds with tokens, enabling the conversion of bets to a common value basis for calculations.
     * Tokens without a specified price feed (address(0)) are considered to have fixed or known values and are added to a separate list.
     * The function ensures that each token in the input array has a corresponding price feed address (which can be the zero address).
     * The `onlyOwner` modifier restricts this function's execution to the contract's owner, safeguarding against unauthorized token addition.
     * @param tokens An array of token addresses to be allowed for betting.
     * @param priceFeeds An array of Chainlink price feed addresses corresponding to the tokens. Use address(0) for tokens without a need for price feeds.
     * @param minBetAmounts An array of amount corresponding to every token being allowed, the value for oracless tokens will be considers only in this method.
     * Requirements:
     * - The lengths of the `tokens` and `priceFeeds` arrays must match to ensure each token has a corresponding price feed address.
     */
    function allowTokens(
        address[] memory tokens,
        address[] memory priceFeeds,
        uint256[] memory minBetAmounts
    ) public onlyOwner {
        require(
            tokens.length == priceFeeds.length && tokens.length == minBetAmounts.length,
            "Lengths differ"
        );

        _allowedTokens.add(tokens);
        _allTokens.add(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (priceFeeds[i] == address(0)) {
                require(minBetAmounts[i] > 0, "Invalid minimum amount");
                _oraclessTokensMinBetAmount[tokens[i]] = minBetAmounts[i];
                _oraclessTokens.add(tokens[i]);
            } else {
                _priceFeeds[tokens[i]] = AggregatorV3Interface(priceFeeds[i]);
            }
        }
    }

    /// @notice Removes a batch of tokens from being allowed for betting and deletes associated price feeds
    /** @dev This function enables the contract owner to restrict certain tokens from being used in betting activities.
     * It involves removing tokens from the list of allowed tokens, potentially removing them from the list of tokens
     * without a Chainlink price feed (oracless tokens), and deleting their associated price feeds if any were set.
     * This is a crucial administrative function for managing the tokens that can be used on the platform, allowing
     * for adjustments based on compliance, liquidity, or other operational considerations.
     * Execution is restricted to the contract's owner through the `onlyOwner` modifier, ensuring that token restrictions
     * can only be imposed by authorized parties.
     * @param tokens An array of token addresses that are to be restricted from use in betting.
     */
    function restrictTokens(address[] calldata tokens) external onlyOwner {
        _allowedTokens.remove(tokens);
        _oraclessTokens.remove(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            delete _priceFeeds[tokens[i]];
            delete _oraclessTokensMinBetAmount[tokens[i]];
        }
    }

    /// @notice Sets the rules for administrative shares on betting winnings based on thresholds
    /** @dev Allows the contract owner to define how administrative shares (a portion of betting winnings) are calculated.
     * This can be configured differently for the STMX token versus other tokens, as indicated by the `isSTMX` flag.
     * Each entry in the `thresholds` and `percentages` arrays defines a tier: if the winnings fall into a certain threshold,
     * the corresponding percentage is applied as the administrative share. The function enforces ascending order for thresholds
     * and ensures that the share percentages do not exceed a maximum limit. This setup allows for flexible configuration
     * of administrative fees based on the amount won.
     * Access is restricted to the contract owner through the `onlyOwner` modifier, ensuring that only they can set these rules.
     * @param thresholds An array of threshold values, each representing the lower bound of a winnings bracket.
     * @param percentages An array of percentages corresponding to each threshold, defining the admin share for that bracket.
     * @param token A boolean flag indicating whether these rules apply to the STMX token (`true`) or other tokens (`false`).
     *
     * Requirements:
     * - The `thresholds` and `percentages` arrays must be of equal length and not empty, ensuring each threshold has a corresponding percentage.
     * - Thresholds must be in ascending order, and all percentages must not exceed the predefined maximum admin share percentage.
     */
    function setAdminShareRules(
        uint256[] calldata thresholds,
        uint256[] calldata percentages,
        address token
    ) external onlyOwner {
        require(
            thresholds.length > 0 && thresholds.length == percentages.length,
            "Lengths differ"
        );

        for (uint256 i = 0; i < thresholds.length - 1; i++) {
            require(thresholds[i] <= thresholds[i + 1], "Descending threshold");
            require(percentages[i] <= maxAdminSharePercentage, "Share is greater than 20%");
        }

        require(
            percentages[percentages.length - 1] <= maxAdminSharePercentage,
            "Share is greater than 20%"
        );

        _adminShareRules[token] = AdminShareRule({
            percentages: percentages,
            thresholds: thresholds
        });
    }

    /// @notice Retrieves the administrative share rules for either the STMX token or other tokens
    /** @dev This function provides external access to the administrative share rules that have been set up for either
     * the STMX token (if `isSTMX` is true) or for other tokens (if `isSTMX` is false). These rules define the thresholds
     * and corresponding percentages that determine how administrative shares are calculated from betting winnings.
     * The function returns two arrays: one for the thresholds and one for the percentages, which together outline the
     * structure of admin shares based on the amount of winnings.
     * @param token A boolean flag indicating whether to retrieve the rules for the STMX token (`true`) or other tokens (`false`).
     * @return thresholds An array of uint256 representing the winnings thresholds for admin shares calculation.
     * @return percentages An array of uint256 representing the admin share percentages for each corresponding threshold.
     */
    function getAdminShareRules(
        address token
    ) external view returns (uint256[] memory thresholds, uint256[] memory percentages) {
        AdminShareRule storage rule = _adminShareRules[token];
        return (rule.thresholds, rule.percentages);
    }

    /// @notice Retrieves the list of tokens currently allowed for betting
    /** @dev This function provides external visibility into which tokens are currently permitted for use in betting within the platform.
     * It leverages the EnumerableSet library from OpenZeppelin to handle the dynamic array of addresses representing the allowed tokens.
     * This is particularly useful for interfaces or external contracts that need to verify or display the tokens users can bet with.
     * @return An array of addresses, each representing a token that is allowed for betting.
     */
    function getAllowedTokens() external view returns (address[] memory) {
        return _allowedTokens.values();
    }

    /// @notice Fetches detailed information about a specific challenge by its ID
    /** @dev This function provides access to the details of a given challenge, including its current status, which is
     * dynamically determined based on the challenge's timing and resolution state. It's essential for external callers
     * to be able to retrieve comprehensive data on a challenge, such as its participants, status, and betting amounts,
     * to properly interact with or display information about the challenge. The function checks that the requested
     * challenge exists before attempting to access its details.
     * @param challengeId The unique identifier of the challenge for which details are requested.
     * @return challengeDetails A `Challenge` struct containing all relevant data about the challenge, including an updated status.
     *
     * Requirements:
     * - The challenge must exist, as indicated by its ID being within the range of created challenges.
     */
    function getChallengeDetails(
        uint256 challengeId
    ) external view returns (Challenge memory challengeDetails) {
        require(challengeExists(challengeId), "Challenge doesn't exist");
        challengeDetails = _challenges[challengeId];

        challengeDetails.status = _challengeStatus(challengeId);
    }

    /// @notice Retrieves the bet details placed by a specific user on a particular challenge
    /** @dev This function allows anyone to view the details of a bet made by a user on a specific challenge,
     * including the amount bet and the side the user has chosen. It's crucial for enabling users or interfaces
     * to confirm the details of participation in challenges and to understand the stakes involved. This function
     * directly accesses the mapping of user bets based on the user address and challenge ID, returning the
     * corresponding `UserBet` struct.
     * @param challengeId The ID of the challenge for which the bet details are being queried.
     * @param user The address of the user whose bet details are requested.
     * @return A `UserBet` struct containing the amount of the bet and the decision (side chosen) by the user for the specified challenge.
     */
    function getUserBet(uint256 challengeId, address user) external view returns (UserBet memory) {
        return _userChallengeBets[user][challengeId];
    }

    /// @notice Provides a list of tokens and corresponding amounts available for withdrawal by a specific user
    /** @dev This function compiles a comprehensive view of all tokens that a user has available to withdraw,
     * including winnings, refunds, or other credits due to the user. It iterates over the entire list of tokens
     * recognized by the contract (not just those currently allowed for betting) to ensure that users can access
     * any funds owed to them, regardless of whether a token's betting status has changed. This is essential for
     * maintaining transparency and access to funds for users within the platform.
     * @param user The address of the user for whom withdrawable balances are being queried.
     * @return tokens An array of token addresses, representing each token that the user has a balance of.
     * @return amounts An array of uint256 values, each corresponding to the balance of the token at the same index in the `tokens` array.
     */
    function getUserWithdrawables(
        address user
    ) external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256 allTokensLength = _allTokens.length();

        tokens = new address[](allTokensLength);
        amounts = new uint256[](allTokensLength);

        for (uint256 i = 0; i < allTokensLength; i++) {
            tokens[i] = _allTokens.at(i);
            amounts[i] = _withdrawables[user][tokens[i]];
        }
    }

    /**
     * @dev Allows a user to join a challenge, handling the financial transactions involved, including admin fees.
     * This internal function processes a user's bet on a challenge, taking into account amounts from the user's wallet and
     * withdrawable balance. It calculates and deducts an admin share based on the total bet amount and updates the challenge
     * and user's records accordingly.
     *
     * @param challengeId The unique identifier of the challenge the user wishes to join.
     * @param amountFromWallet The portion of the user's bet that will be taken from their wallet.
     * @param amountFromWithdrawables The portion of the user's bet that will be taken from their withdrawable balance.
     * @param decision Indicates whether the user is betting for (1) or against (2) in the challenge; for group challenges, this is ignored.
     *
     * The function enforces several checks and conditions:
     * - The total bet amount must exceed the admin share calculated for the transaction.
     * - The user must have sufficient withdrawable balance if opting to use it.
     * - Transfers the required amount from the user's wallet if applicable.
     * - Updates the admin's withdrawable balance with the admin share.
     * - Adds the user to the challenge participants and updates the challenge's total amount for or against based on the user's decision.
     * - Ensures the number of participants does not exceed the maximum allowed.
     * - Records the user's bet details.
     *
     * Emits a `ChallengeJoined` event upon successful joining of the challenge.
     * Emits an `AdminReceived` event to indicate the admin share received from the user's bet.
     *
     * Requirements:
     * - The sum of `amountFromWallet` and `amountFromWithdrawables` must be greater than the admin share.
     * - If using withdrawables, the user must have enough balance.
     * - The challenge token must be transferred successfully from the user's wallet if necessary.
     * - The challenge's participants count for either side must not exceed `maxChallengersEachSide`.
     *
     * Notes:
     * - This function uses the nonReentrant modifier to prevent reentry attacks.
     * - It supports participation in both individual and group challenges.
     * - Admin shares are calculated and deducted from the user's total bet amount to ensure fair administration fees.
     */
    function _joinChallenge(
        uint256 challengeId,
        uint256 amountFromWallet,
        uint256 amountFromWithdrawables,
        uint8 decision
    ) internal nonReentrant {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;
        uint256 amount = amountFromWallet + amountFromWithdrawables;
        uint256 adminShare = _calculateAdminShare(_challenge, amount);

        // Ensure that the total amount is greater than the admin share per challenge
        require(amount > adminShare, "amount <= admin share per challenge");
        uint256 valueAmount = (_getValue(challengeToken) * amount) /
            10 ** (challengeToken == address(0) ? 18 : challengeToken.decimals());

        if (_oraclessTokens.contains(challengeToken)) {
            require(valueAmount >= _oraclessTokensMinBetAmount[challengeToken], "Invalid amount");
        } else {
            require(valueAmount >= minUSDBetAmount, "Invalid amount");
        }

        // Deduct the amount from the withdrawables if bet amount is from withdrawables
        if (amountFromWithdrawables > 0) {
            require(
                _withdrawables[msg.sender][challengeToken] >= amountFromWithdrawables,
                "not enough withdrawables"
            );
            _withdrawables[msg.sender][challengeToken] -= amountFromWithdrawables;
        }

        // Transfer the amount from the user's wallet to the contract
        if (challengeToken != address(0)) {
            IERC20(challengeToken).safeTransferFrom(msg.sender, address(this), amountFromWallet);
        }

        // Add admin share to withdrawables
        _withdrawables[owner()][challengeToken] += adminShare;
        amount -= adminShare;

        uint256 participants;

        // Depending on the decision, update challenge state and user bet details
        if (decision == 1 || _challenge.challengeType == ChallengeType.Group) {
            _challenge.usersFor.push(msg.sender);
            participants = _challenge.usersFor.length;
            _challenge.amountFor += amount;
        } else {
            _challenge.usersAgainst.push(msg.sender);
            participants = _challenge.usersAgainst.length;
            _challenge.amountAgainst += amount;
        }

        // Ensure the number of participants does not exceed the maximum allowed per side
        require(participants <= maxChallengersEachSide, "Max challengers per side");

        // Record user's bet details for the challenge
        if (_challenge.challengeType == ChallengeType.Group) {
            _userChallengeBets[msg.sender][challengeId] = UserBet({amount: amount, decision: 1});
        } else {
            _userChallengeBets[msg.sender][challengeId] = UserBet({
                amount: amount,
                decision: decision
            });
        }

        // Emit events for challenge joined and admin received shares
        emit ChallengeJoined(challengeId, amount, msg.sender);
        emit AdminReceived(challengeId, challengeToken, adminShare);
    }

    /**
     * @dev Calculates the results of a challenge based on the final outcome and updates the participants' balances accordingly.
     * This internal function takes the final outcome of a challenge and determines the winners and losers, redistributing the
     * pooled amounts between participants based on their initial bets. It ensures that the winnings are proportionally distributed
     * to the winners from the total amount bet by the losers.
     *
     * @param challengeId The unique identifier of the challenge to calculate results for.
     * @param finalOutcome The final outcome of the challenge represented as a uint8 value. A value of `1` indicates
     * that the original "for" side wins, while `2` indicates that the "against" side wins.
     *
     * The function performs the following steps:
     * - Identifies the winning and losing sides based on `finalOutcome`.
     * - Calculates the total winning amount for each winning participant based on their bet proportion.
     * - Updates the `_withdrawables` mapping to reflect the winnings for each winning participant.
     * - Prepares data for the losing participants but does not adjust their balances as their amounts are considered lost.
     *
     * Emits a `ChallengeFundsMoved` event indicating the redistribution of funds following the challenge's conclusion.
     * This event provides detailed arrays of winning and losing users, alongside the amounts won or lost.
     *
     * Requirements:
     * - The challenge identified by `challengeId` must exist within the `_challenges` mapping.
     * - The `finalOutcome` must correctly reflect the challenge's outcome, with `1` for a win by the original "for" side
     *   and `2` for a win by the "against" side.
     *
     * Notes:
     * - This function is critical for ensuring fair payout to the winners based on the total amount bet by the losers.
     * - It assumes that the `finalOutcome` has been determined by an external process or oracle that is not part of this function.
     */
    function _calculateChallenge(uint256 challengeId, uint8 finalOutcome) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        // Determine the arrays of winning and losing users, and their respective amounts
        address[] storage usersWin = _challenge.usersFor;
        address[] storage usersLose = _challenge.usersAgainst;
        uint256 winAmount = _challenge.amountFor;
        uint256 loseAmount = _challenge.amountAgainst;

        if (finalOutcome == 2) {
            // If final outcome is lose, swap win and lose arrays
            (usersWin, usersLose) = (usersLose, usersWin);
            (winAmount, loseAmount) = (loseAmount, winAmount);
        }

        uint256 usersWinLength = usersWin.length;
        uint256 usersLoseLength = usersLose.length;

        uint256[] memory winAmounts = new uint256[](usersWinLength);

        // Distribute winnings to winning users
        for (uint256 i = 0; i < usersWinLength; i++) {
            address user = usersWin[i];
            UserBet storage bet = _userChallengeBets[user][challengeId];

            uint256 userWinAmount = bet.amount + ((loseAmount * bet.amount) / winAmount);

            winAmounts[i] = userWinAmount;
            _withdrawables[user][challengeToken] += userWinAmount;
        }

        uint256[] memory loseAmounts = new uint256[](usersLoseLength);

        // Record losing amounts
        for (uint256 i = 0; i < usersLoseLength; i++) {
            loseAmounts[i] = _userChallengeBets[usersLose[i]][challengeId].amount;
        }

        // Emit event for funds distribution
        emit ChallengeFundsMoved(challengeId, usersWin, winAmounts, usersLose, loseAmounts);
    }

    /**
     * @dev Cancels a user's participation in a given challenge, refunding their bet and updating the challenge's state.
     * This internal function handles the cancellation process for both individual and group challenges.
     * It adjusts the challenge's total bet amount and participant list based on the user's decision (for or against).
     * Additionally, it increments the user's withdrawable balance by the amount of their canceled bet.
     *
     * @param user The address of the user whose participation is being canceled.
     * @param challengeId The unique identifier of the challenge from which the user is withdrawing.
     *
     * The function performs the following operations:
     * - Identifies whether the user was betting for or against the challenge, or if it's a group challenge.
     * - Removes the user from the appropriate participant list (`usersFor` or `usersAgainst`) and adjusts the challenge's
     *   total amount for or against accordingly.
     * - Increases the user's withdrawable balance by the amount of their bet.
     * - Emits a `CancelParticipation` event signaling the user's cancellation from the challenge.
     * - Emits a `ChallengeFundsMoved` event to indicate the movement of funds due to the cancellation, for consistency and tracking.
     *
     * Notes:
     * - This function is designed to work with both individual and group challenges, modifying the challenge's state
     *   to reflect the user's cancellation and ensuring the integrity of the challenge's betting totals.
     * - It utilizes the `contains` function to find the user's position in the participant lists and handles their removal efficiently.
     * - The adjustment of the challenge's betting totals and participant lists is crucial for maintaining accurate and fair
     *   challenge outcomes and balances.
     */
    function _cancelParticipation(address user, uint256 challengeId) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        uint256 usersForLength = _challenge.usersFor.length;
        uint256 usersAgainstLength = _challenge.usersAgainst.length;

        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        uint256 amount = _userChallengeBets[user][challengeId].amount;

        if (
            (_challenge.challengeType == ChallengeType.Individual &&
                _userChallengeBets[user][challengeId].decision == 1) ||
            _challenge.challengeType == ChallengeType.Group
        ) {
            // If user is for the challenge or it's a group challenge, handle accordingly
            uint256 i = contains(_challenge.usersFor, user);
            _withdrawables[user][challengeToken] += amount;
            _challenge.amountFor -= amount;
            _challenge.usersFor[i] = _challenge.usersFor[usersForLength - 1];
            _challenge.usersFor.pop();
        } else {
            // If user is against the challenge, handle accordingly
            uint256 i = contains(_challenge.usersAgainst, user);
            _withdrawables[user][challengeToken] += amount;
            _challenge.amountAgainst -= amount;
            _challenge.usersAgainst[i] = _challenge.usersAgainst[usersAgainstLength - 1];
            _challenge.usersAgainst.pop();
        }

        // Prepare data for event emission
        users[0] = user;
        amounts[0] = amount;

        // Clear user's bet for the challenge
        delete _userChallengeBets[user][challengeId];

        // Emit events for cancellation of participation and fund movement
        emit CancelParticipation(user, challengeId);
        emit ChallengeFundsMoved(challengeId, users, amounts, new address[](0), new uint256[](0));
    }

    /**
     * @dev Calculates and allocates winnings and losses for a group challenge.
     * This internal function determines the amounts won by each winning user and the amounts lost by each losing user
     * within a challenge. It updates the `_withdrawables` mapping to reflect the winnings for each winning user based
     * on their share of the profits. Losing users' bet amounts are noted but not immediately acted upon in this function.
     *
     * @param challengeId The unique identifier of the challenge being calculated.
     * @param usersWin An array of addresses for users who won in the challenge.
     * @param profits An array of profit percentages corresponding to each winning user.
     *
     * Requirements:
     * - `usersWin` and `profits` arrays must be of the same length, with each entry in `profits` representing
     *   the percentage of the total winnings that the corresponding user in `usersWin` should receive.
     * - This function does not directly handle the transfer of funds but updates the `_withdrawables` mapping to
     *   reflect the amounts that winning users are able to withdraw.
     * - Losing users' details are aggregated but are used primarily for event emission.
     *
     * Emits a `ChallengeFundsMoved` event indicating the challenge ID, winning users and their win amounts,
     * and losing users with the amounts they bet and lost. This helps in tracking the outcome and settlements
     * of group challenges.
     *
     * Note:
     * - The actual transfer of funds from losing to winning users is not performed in this function. Instead, it calculates
     *   and updates balances that users can later withdraw.
     */
    function _calculateGroupChallenge(
        uint256 challengeId,
        address[] calldata usersWin,
        uint256[] calldata profits
    ) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        uint256[] memory winAmounts = new uint256[](usersWin.length);
        uint256[] memory loseAmounts = new uint256[](_challenge.usersFor.length - usersWin.length);
        address[] memory usersLose = new address[](_challenge.usersFor.length - usersWin.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _challenge.usersFor.length; i++) {
            uint256 index = contains(usersWin, _challenge.usersFor[i]);
            if (index == usersWin.length) {
                usersLose[j] = _challenge.usersFor[i];
                loseAmounts[j] = _userChallengeBets[_challenge.usersFor[i]][challengeId].amount;
                j++;
            } else {
                uint256 winAmount = (_challenge.amountFor * profits[index]) / (100 * DECIMAL);
                _withdrawables[usersWin[index]][challengeToken] += winAmount;
                winAmounts[index] = winAmount;
            }
        }

        // Emit event for fund movement in the group challenge
        emit ChallengeFundsMoved(challengeId, usersWin, winAmounts, usersLose, loseAmounts);
    }

    /**
     * @dev Searches for an element in an address array and returns its index if found.
     * This internal pure function iterates through an array of addresses to find a specified element.
     * It's designed to check the presence of an address in a given array and identify its position.
     *
     * @param array The array of addresses to search through.
     * @param element The address to search for within the array.
     * @return The index of the element within the array if found; otherwise, returns the length of the array.
     * This means that if the return value is equal to the array's length, the element is not present in the array.
     */
    function contains(address[] memory array, address element) internal pure returns (uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return i;
            }
        }
        return array.length;
    }

    /**
     * @dev Cancels all bets placed on a challenge, refunding the bet amounts to the bettors.
     * This internal function handles the process of cancelling bets for both "for" and "against" positions in a given challenge.
     * It aggregates users and their respective bet amounts from both positions, updates their withdrawable balances,
     * and emits an event indicating the movement of funds due to the challenge's cancellation.
     *
     * The function iterates through all bets placed "for" and "against" the challenge, compiles lists of users and their bet amounts,
     * and credits the bet amounts back to the users' withdrawable balances in the form of the challenge's token.
     *
     * @param challengeId The unique identifier of the challenge whose bets are to be cancelled.
     *
     * Emits a `ChallengeFundsMoved` event with details about the challengeId, users involved, their refunded amounts,
     * and empty arrays for new users and new amounts as no new bets are created during the cancellation process.
     *
     * Requirements:
     * - The function is internal and expected to be called in scenarios where a challenge needs to be cancelled, such as
     *   when a challenge is deemed invalid or when conditions for the challenge's execution are not met.
     * - It assumes that `_challenges` maps `challengeId` to a valid `Challenge` struct containing arrays of users who have bet "for" and "against".
     * - The function updates `_withdrawables`, a mapping of user addresses to another mapping of token addresses and their withdrawable amounts, ensuring users can withdraw their bet amounts after the bets are cancelled.
     */
    function _cancelBets(uint256 challengeId) internal {
        Challenge storage _challenge = _challenges[challengeId];
        address challengeToken = _challenge.token;

        uint256 usersForLength = _challenge.usersFor.length;
        uint256 usersAgainstLength = _challenge.usersAgainst.length;

        address[] memory users = new address[](usersForLength + usersAgainstLength);
        uint256[] memory amounts = new uint256[](usersForLength + usersAgainstLength);

        for (uint256 i = 0; i < usersForLength; i++) {
            address user = _challenge.usersFor[i];

            users[i] = user;
            amounts[i] = _userChallengeBets[user][challengeId].amount;

            _withdrawables[user][challengeToken] += amounts[i];
        }

        for (uint256 i = 0; i < usersAgainstLength; i++) {
            address user = _challenge.usersAgainst[i];
            uint256 index = i + usersForLength;

            users[index] = user;
            amounts[index] = _userChallengeBets[user][challengeId].amount;

            _withdrawables[user][challengeToken] += amounts[index];
        }

        emit ChallengeFundsMoved(challengeId, users, amounts, new address[](0), new uint256[](0));
    }

    /**
     * @dev Withdraws an amount of native cryptocurrency (e.g., ETH) or an ERC-20 token and sends it to a specified address.
     * This internal function handles the transfer of both native cryptocurrency and ERC-20 tokens based on the token address provided.
     * If the `token` parameter is the zero address, it treats the transfer as a native cryptocurrency transaction.
     * Otherwise, it performs a safe transfer of an ERC-20 token.
     *
     * @param token The address of the token to withdraw. If the address is `0x0`, the withdrawal is processed as a native cryptocurrency transaction.
     * @param to The recipient address to which the currency or tokens are sent.
     * @param amount The amount of currency or tokens to send. The function ensures that this amount is securely transferred to the `to` address.
     *
     * Requirements:
     * - For native cryptocurrency transfers:
     *   - The transaction must succeed. If it fails, the function reverts with "Failed to send ETH".
     * - For ERC-20 token transfers:
     *   - The function uses `safeTransfer` from the IERC20 interface to prevent issues related to double spending or errors in transfer.
     *   - The ERC-20 token contract must implement `safeTransfer` correctly according to the ERC-20 standard.
     */
    function _withdraw(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            // Native cryptocurrency transfer
            (bool ok, ) = to.call{value: amount}("");
            require(ok, "Failed to send ETH");
        } else {
            // ERC-20 token transfer
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @dev Calculates the administrator's share of a challenge based on the challenge's token and the amount.
     * This internal view function determines the admin's share by first converting the `amount` of the challenge's
     * token into a standardized value (using `_getValue` function to get the token's value in a common denomination).
     * It then uses this value to find the applicable admin share percentage from a predefined set of rules (`_adminShareRules`).
     *
     * @param _challenge The challenge struct from which the token is retrieved to calculate the value amount.
     * @param amount The amount involved in the challenge for which the admin's share is to be calculated.
     * @return The calculated admin share as a uint256, based on the challenge's conditions and predefined rules.
     *
     * Logic:
     * - Determines the value of the `amount` of tokens by fetching the token's current value and adjusting for decimal places.
     * - Uses the calculated value to find the corresponding admin share percentage from `_adminShareRules`.
     * - The share is computed based on thresholds which determine the percentage rate applicable to the value amount.
     * - If the value amount does not meet the minimum threshold, the function returns 0, indicating no admin share.
     * - If applicable, the admin share is calculated by multiplying the `amount` by the determined percentage
     *   and dividing by `PERCENTAGE_100` to ensure the result is in the correct scale.
     *
     * Requirements:
     * - The function dynamically adjusts for the token's decimals, using 18 decimals for the native currency (e.g., ETH) or
     *   querying the token contract for ERC-20 tokens.
     * - It handles special cases, such as when the token is the platform's specific token (e.g. STMX),
     *   by applying predefined rules for calculating the admin share.
     */
    function _calculateAdminShare(
        Challenge storage _challenge,
        uint256 amount
    ) internal view returns (uint256) {
        address token = _challenge.token;
        uint256 valueAmount = (_getValue(token) * amount) /
            10 ** (token == address(0) ? 18 : token.decimals());

        AdminShareRule storage rule = _adminShareRules[token];

        uint256 index = rule.thresholds.upperBound(valueAmount);

        if (index == 0) {
            return 0;
        }

        return (amount * rule.percentages[index - 1]) / PERCENTAGE_100;
    }

    /**
     * @dev Retrieves the current value of a given token, based on oracle data.
     * This internal view function queries the value of the specified token from a price feed oracle.
     * If the token is recognized by a preset list of oracles (_oraclessTokens), it returns a default value.
     * Otherwise, it fetches the latest round data from the token's associated price feed.
     * The function requires that the oracle's reported value be positive and updated within the last day,
     * indicating no oracle malfunction.
     * It adjusts the oracle's value based on a default decimal precision, to ensure consistency across different oracles.
     *
     * @param token The address of the token for which the value is being queried.
     * @return The current value of the token as a uint256, adjusted for default decimal precision.
     * The value is adjusted to match the `defaultOracleDecimals` precision if necessary.
     *
     * Requirements:
     * - The oracle's latest value for the token must be positive and updated within the last 24 hours.
     * - If the token is not recognized by the _oraclessTokens set, but has a price feed, the function normalizes the
     *   value to a standard decimal precision (defaultOracleDecimals) for consistency.
     * - Throws "Oracle malfunction" if the oracle's latest data does not meet the requirements.
     */
    function _getValue(address token) internal view returns (uint256) {
        int256 value;
        uint256 updatedAt;

        if (_oraclessTokens.contains(token)) {
            value = int256(10 ** defaultOracleDecimals);
        } else {
            (, value, , updatedAt, ) = _priceFeeds[token].latestRoundData();
            require(value > 0 && updatedAt >= block.timestamp - 1 days, "Oracle malfunction");
            uint256 oracleDecimals = _priceFeeds[token].decimals();
            if (oracleDecimals > defaultOracleDecimals) {
                value = value / int256(10 ** (oracleDecimals - defaultOracleDecimals));
            } else if (oracleDecimals < defaultOracleDecimals) {
                value = value * int256(10 ** (defaultOracleDecimals - oracleDecimals));
            }
        }

        return uint256(value);
    }

    /**
     * @dev Determines the current status of a specific challenge by its ID.
     * This internal view function assesses the challenge's status based on its current state and timing.
     * It checks if the challenge is in a final state (Canceled, ResolvedFor, ResolvedAgainst, or ResolvedDraw).
     * If not, it then checks whether the challenge's end time has passed to determine if it's in the Awaiting state.
     * Otherwise, it defaults to the Betting state, implying that the challenge is still active and accepting bets.
     *
     * @param challengeId The unique identifier for the challenge whose status is being queried.
     * @return ChallengeStatus The current status of the challenge. This can be one of the following:
     * - Canceled: The challenge has been canceled.
     * - ResolvedFor: The challenge has been resolved in favor of the proposer.
     * - ResolvedAgainst: The challenge has been resolved against the proposer.
     * - ResolvedDraw: The challenge has been resolved as a draw.
     * - Awaiting: The challenge is awaiting resolution, but betting is closed due to the end time having passed.
     * - Betting: The challenge is open for bets.
     */
    function _challengeStatus(uint256 challengeId) internal view returns (ChallengeStatus) {
        ChallengeStatus status = _challenges[challengeId].status;
        uint256 endTime = _challenges[challengeId].endTime;

        if (
            status == ChallengeStatus.Canceled ||
            status == ChallengeStatus.ResolvedFor ||
            status == ChallengeStatus.ResolvedAgainst ||
            status == ChallengeStatus.ResolvedDraw
        ) {
            return status;
        }

        if (block.timestamp > endTime) {
            return ChallengeStatus.Awaiting;
        }

        return ChallengeStatus.Betting;
    }

    /**
     * @dev Ensures that the function is only callable by the designated backend address.
     * This internal view function checks if the `msg.sender` is the same as the stored `backend` address.
     * It should be used as a modifier in functions that are meant to be accessible only by the backend.
     * Reverts with a "Not a backend" error message if the `msg.sender` is not the backend address.
     */
    function _onlyBackend() internal view {
        require(msg.sender == backend, "Not a backend");
    }
}