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

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { YieldSlice } from  "./YieldSlice.sol";
import { NPVToken } from "../tokens/NPVToken.sol";
import { ILiquidityPool } from "../interfaces/ILiquidityPool.sol";

/// @title Swap future yield for upfront tokens.
contract NPVSwap {
    using SafeERC20 for IERC20;

    NPVToken public immutable npvToken;
    YieldSlice public immutable slice;
    ILiquidityPool public immutable pool;

    event LockForNPV(uint256 indexed id,
                     address indexed owner,
                     address indexed recipient,
                     uint256 tokens,
                     uint256 yield);

    event SwapNPVForSlice(uint256 indexed id,
                          address indexed recipient,
                          uint256 npv);

    event LockForYield(uint256 indexed id,
                       address indexed owner,
                       uint256 tokens,
                       uint256 yield,
                       uint256 amountOut);

    event SwapForSlice(uint256 indexed id,
                       address indexed recipient,
                       uint256 yield,
                       uint256 npv);

    event RolloverForYield(uint256 indexed id,
                           address indexed recipient,
                           uint256 yield,
                           uint256 npv,
                           uint256 amountOut);

    event MintAndPayWithYield(uint256 indexed id, uint256 paid);

    modifier validAddress(address who) {
        require(who != address(0), "NS: zero address");
        require(who != address(this), "NS: this address");
        _;
    }

    modifier validRecipient(address recipient) {
        require(recipient != address(0), "NS: zero address");
        _;
    }

    /// @notice Create an NPVSwap.
    /// @param slice_ Yield slice contract that will use to slice and swap yield.
    /// @param pool_ Liquidity pool to trade NPV for real tokens.
    constructor(address slice_, address pool_)
        validAddress(slice_)
        validAddress(pool_) {

        address npvToken_ = address(YieldSlice(slice_).npvToken());
        require(npvToken_ == ILiquidityPool(pool_).token0() ||
                npvToken_ == ILiquidityPool(pool_).token1(), "NS: wrong token");

        npvToken = NPVToken(npvToken_);
        slice = YieldSlice(slice_);
        pool = ILiquidityPool(pool_);
    }


    // --------------------------------------------------------- //
    // ---- Low level: Transacting in NPV tokens and slices ---- //
    // --------------------------------------------------------- //

    /// @notice Compute the amount of NPV that will be generated.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    function previewLockForNPV(uint256 tokens, uint256 yield) public view returns (uint256) {
        (uint256 npv, uint256 fees) = slice.previewDebtSlice(tokens, yield);
        return npv - fees;
    }

    /// @notice Compute the result of a swap from yield to NPV tokens.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldIn The amount of yield tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapYieldForNPV(uint256 yieldIn, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        return pool.previewSwap(address(slice.yieldToken()),
                                uint128(yieldIn),
                                sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from yield to NPV tokens, with exact output.
    /// @dev Not a view, and should not be used, on-chain, due to underlying Uniswap v3 behavior.
    /// @param npvOut The amount of NPV tokens desired as output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapYieldForNPVOut(uint256 npvOut, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        return pool.previewSwapOut(address(slice.yieldToken()),
                                   uint128(npvOut),
                                   sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from NPV tokens to yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param npvIn The amount of NPV tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapNPVForYield(uint256 npvIn, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        return pool.previewSwap(address(npvToken),
                                uint128(npvIn),
                                sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from NPV tokens to yield, with exact output.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldOut The amount of yield tokens desired as output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapNPVForYieldOut(uint256 yieldOut, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        return pool.previewSwapOut(address(npvToken),
                                   uint128(yieldOut),
                                   sqrtPriceLimitX96);
    }

    /// @notice Lock yield generating tokens to generate NPV tokens.
    /// @param owner Owner of the resulting yield slice.
    /// @param recipient Recipient of the NPV tokens.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param memo Optional memo data to associate with the yield slice.
    function lockForNPV(address owner,
                        address recipient,
                        uint256 tokens,
                        uint256 yield,
                        bytes calldata memo)
        public
        validRecipient(owner)
        validRecipient(recipient)
        returns (uint256) {

        IERC20(slice.generatorToken()).safeTransferFrom(msg.sender, address(this), tokens);
        slice.generatorToken().safeApprove(address(slice), 0);
        slice.generatorToken().safeApprove(address(slice), tokens);

        uint256 id = slice.debtSlice(owner, recipient, tokens, yield, memo);

        emit LockForNPV(id, owner, recipient, tokens, yield);

        return id;
    }

    /// @notice Swap NPV tokens for a future yield in the form of a yield slice.
    /// @param recipient Recipient of the yield slice.
    /// @param npv Amount of NPV tokens to swap into the yield slice.
    /// @param memo Optional memo data to associate with the yield slice.
    function swapNPVForSlice(address recipient,
                             uint256 npv,
                             bytes calldata memo)
        external
        validRecipient(recipient)
        returns (uint256) {

        IERC20(slice.npvToken()).safeTransferFrom(msg.sender, address(this), npv);
        IERC20(slice.npvToken()).safeApprove(address(slice), 0); 
        IERC20(slice.npvToken()).safeApprove(address(slice), npv);

        uint256 id = slice.creditSlice(npv, recipient, memo);

        emit SwapNPVForSlice(id, recipient, npv);

        return id;
    }


    // --------------------------------------------------------------- //
    // ---- High level: Transacting in generator and yield tokens ---- //
    // --------------------------------------------------------------- //

    /// @notice Compute the result of a swap from locking future yield into upfront yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewLockForYield(uint256 tokens, uint256 yield, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        uint256 previewNPV = previewLockForNPV(tokens, yield);
        return pool.previewSwap(address(npvToken), uint128(previewNPV), sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap of yield for future yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldIn The amount of yield tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapForSlice(uint256 yieldIn, uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        (uint256 npv, uint256 priceX96) = pool.previewSwap(address(slice.yieldToken()),
                                                           uint128(yieldIn),
                                                           sqrtPriceLimitX96);
        uint256 fees = slice.creditFees(npv);
        return (npv - fees, priceX96);
    }

    /// @notice Lock yield generating tokens into a slice, and swap for yield tokens.
    /// @param owner Owner of the resulting debt yield slice.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param amountOutMin Minimum amount of yield to output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    /// @param memo Optional memo data to associate with the yield slice.
    function lockForYield(address owner,
                          uint256 tokens,
                          uint256 yield,
                          uint256 amountOutMin,
                          uint128 sqrtPriceLimitX96,
                          bytes calldata memo)
        external
        validRecipient(owner)
        returns (uint256, uint256) {

        uint256 npv = previewLockForNPV(tokens, yield);

        uint256 id = lockForNPV(owner, address(this), tokens, yield, memo);

        IERC20(npvToken).safeApprove(address(pool), 0);
        IERC20(npvToken).safeApprove(address(pool), npv);
        uint256 out = pool.swap(owner,
                                address(npvToken),
                                uint128(npv),
                                uint128(amountOutMin),
                                sqrtPriceLimitX96);

        emit LockForYield(id, owner, tokens, yield, out);

        return (id, out);
    }

    /// @notice Swap upfront yield for a future yield slice.
    /// @param recipient Recipient of the future yield.
    /// @param yield Amount of upfront yield to swap for future yield.
    /// @param npvMin Minumum amount of NPV of yield to receive.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    /// @param memo Optional memo data to associate with the yield slice.
    function swapForSlice(address recipient,
                          uint256 yield,
                          uint256 npvMin,
                          uint128 sqrtPriceLimitX96,
                          bytes calldata memo)
        validRecipient(recipient)
        external
        returns (uint256) {

        slice.yieldToken().safeTransferFrom(msg.sender, address(this), yield);
        slice.yieldToken().safeApprove(address(pool), 0);
        slice.yieldToken().safeApprove(address(pool), yield);

        uint256 out = pool.swap(address(this),
                                address(slice.yieldToken()),
                                uint128(yield),
                                uint128(npvMin),
                                sqrtPriceLimitX96);

        IERC20(slice.npvToken()).safeApprove(address(slice), 0);
        IERC20(slice.npvToken()).safeApprove(address(slice), out);
        uint256 id = slice.creditSlice(out, recipient, memo);

        emit SwapForSlice(id, recipient, yield, out);

        return id;
    }

    // -------------------------------------------------------------- //
    // ---- Rollover: Receive additional yield from a debt slice ---- //
    // -------------------------------------------------------------- //
    /// @notice Compute the result of a rollover locking more future yield into upfront yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param id The debt slice to rollover.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewRolloverForYield(uint256 id,
                                     uint256 yield,
                                     uint128 sqrtPriceLimitX96)
        external returns (uint256, uint256) {

        (, uint256 npv, ) = slice.previewRollover(id, yield);
        return pool.previewSwap(address(npvToken), uint128(npv), sqrtPriceLimitX96);
    }

    function rolloverForYield(uint256 id,
                              address recipient,
                              uint256 yield,
                              uint256 amountOutMin,
                              uint128 sqrtPriceLimitX96)
        external
        validRecipient(recipient)
        returns (uint256) {

        (, uint256 npv, ) = slice.previewRollover(id, yield);

        slice.rollover(id, address(this), yield);

        IERC20(npvToken).safeApprove(address(pool), 0);
        IERC20(npvToken).safeApprove(address(pool), npv);
        uint256 out = pool.swap(recipient,
                                address(npvToken),
                                uint128(npv),
                                uint128(amountOutMin),
                                sqrtPriceLimitX96);

        emit RolloverForYield(id, recipient, yield, npv, out);

        return out;
    }

    // ----------------------------------------------------------------- //
    // ---- Repay with yield: Mint NPV with yield, and pay off debt ---- //
    // ----------------------------------------------------------------- //

    /// @notice Mint NPV tokens from yield at 1:1 rate, and pay off debt for a slice.
    /// @param id The debt slice ID.
    /// @param amount The amount of yield tokens to exchange for NPV tokens.
    function mintAndPayWithYield(uint256 id, uint256 amount) external returns (uint256) {

        amount = _min(amount, slice.remaining(id));
        slice.yieldToken().safeTransferFrom(msg.sender, address(this), amount);
        slice.yieldToken().safeApprove(address(slice), 0);
        slice.yieldToken().safeApprove(address(slice), amount);
        slice.mintFromYield(address(this), amount);
        IERC20(slice.npvToken()).safeApprove(address(slice), 0);
        IERC20(slice.npvToken()).safeApprove(address(slice), amount);
        uint256 paid = slice.payDebt(id, amount);

        emit MintAndPayWithYield(id, paid);

        return paid;
    }

    function _min(uint256 x1, uint256 x2) private pure returns (uint256) {
        return x1 < x2 ? x1 : x2;
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IYieldSource } from "../interfaces/IYieldSource.sol";
import { IDiscounter } from "../interfaces/IDiscounter.sol";
import { YieldData } from "../data/YieldData.sol";
import { NPVToken } from "../tokens/NPVToken.sol";

/// @title Slice and transfer future yield based on net present value.
contract YieldSlice is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct DebtSlice {
        address owner;
        uint128 blockTimestamp;
        uint128 unlockedBlockTimestamp;
        uint256 shares;  // Share of the vault's locked generators
        uint256 tokens;  // Tokens locked for generation
        uint256 npvDebt;
        bytes memo;
    }

    struct CreditSlice {
        address owner;

        uint128 createdTimestamp;

        // The slice is entitled to `npvCredit` amount of yield, discounted
        // relative to `blockTimestamp`.
        uint128 blockTimestamp;
        uint256 npvCredit;

        // This slice's share of yield, as a fraction of total NPV tokens.
        uint256 npvTokens;

        // `pending` is accumulated but unclaimed yield for this slice,
        // in nominal terms.
        uint256 pending;

        // `claimed` is the amount of yield claimed by this slice, in
        // nominal terms
        uint256 claimed;

        bytes memo;
    }

    struct RolloverApproval {
        address who;
        uint256 amount;
    }

    uint256 public constant FEE_DENOM = 100_0;

    // Max fees limit what can be set by governance. Actual fee may be lower.

    // -- Debt fee ratio -- //
    // Debt fee ratio is relative to the discount rate of the transaction.
    // For example, a debt fee ratio of 100% means that the the protocol fee
    // is equal to the discount rate. A ratio of 50% means the protocol fee
    // is half the discount rate.
    uint256 public constant MAX_DEBT_FEE_RATIO = 100_0;


    // -- Credit fees -- //
    // Credit fee are are simple percent of the NPV tokens being purchased.
    uint256 public constant MAX_CREDIT_FEE = 20_0;


    // -- Roles --//
    /** @notice Gov role enables governance functions, including setting
        other roles, setting the dust limit, and setting fees. Gov can
        set a new gov.
     */
    address public gov;

    /** @notice Unlocker role enables unlocking a debt slice on behalf of
        its owner. This is for the benefit of the slice owner, to avoid
        excess socialization of refund from long unlock delays.
     */
    address public unlocker;

    /** @notice Treasury role receives fees.
     */
    address public treasury;

    // The unallocated credit slice tracks yield that has been sold using a
    // debt slice, but hasn't been purchased using a credit slice. When a
    // credit slice purchase takes place, the receiver of that purhcase gets
    // a proportional share of the claimable yield from this slice.
    uint256 public constant UNALLOC_ID = 1;

    uint256 public nextId = UNALLOC_ID + 1;
    uint256 public totalShares;
    uint256 public harvestedYield;
    uint256 public dustLimit;
    uint256 public cumulativePaidYield;

    // Track separately from NPV token total supply, because burns
    // happen on credit slice claims, even though debt slice unlocks
    // are what result in yield generation changes.
    uint256 public activeNPV;

    uint256 public debtFee;
    uint256 public creditFee;

    NPVToken public npvToken;
    IERC20 public immutable generatorToken;
    IERC20 public immutable yieldToken;

    IYieldSource public immutable yieldSource;
    IDiscounter public immutable discounter;
    YieldData public immutable debtData;
    YieldData public immutable creditData;

    mapping(uint256 => DebtSlice) public debtSlices;
    mapping(uint256 => CreditSlice) public creditSlices;
    mapping(uint256 => uint256) public pendingClaimable;
    mapping(uint256 => RolloverApproval) public approvedRollover;

    event SliceDebt(address indexed owner,
                    uint256 indexed id,
                    uint256 tokens,
                    uint256 yield,
                    uint256 npv,
                    uint256 fees);

    event SliceCredit(address indexed owner,
                      uint256 indexed id,
                      uint256 npv,
                      uint256 fees);

    event RolloverDebt(address indexed owner,
                       uint256 indexed id,
                       uint256 yield,
                       uint256 npv,
                       uint256 fees);

    event UnlockDebtSlice(address indexed owner,
                          uint256 indexed id);

    event PayDebt(uint256 indexed id, uint256 amount);

    event WithdrawNPV(address indexed recipient,
                     uint256 indexed id,
                     uint256 amount);

    event Claimed(uint256 indexed id, uint256 amount);

    event DustLimit(uint256 dustLimit);
    event DebtFee(uint256 debtFee);
    event CreditFee(uint256 creditFee);
    event Gov(address indexed gov);
    event Unlocker(address indexed unlocker);
    event Treasury(address indexed treasury);
    event Harvest(uint256 total, uint256 delta);
    event RecordDebtData(uint256 totalTokens, uint256 cumulativeYield);
    event RecordCreditData(uint256 totalTokens, uint256 cumulativeYield);
    event MintFromYield(address indexed recipient, uint256 amount);
    event TransferOwnership(uint256 indexed id, address indexed recipient);
    event ApproveRollover(uint256 indexed id, address indexed who, uint256 amountYield);

    modifier onlyGov() {
        require(msg.sender == gov, "YS: only gov");
        _;
    }

    modifier isSlice(uint256 id) {
        require(id < nextId, "YS: invalid id");
        _;
    }

    modifier isDebtSlice(uint256 id) {
        require(debtSlices[id].owner != address(0), "YS: no such debt slice");
        _;
    }

    modifier isCreditSlice(uint256 id) {
        require(creditSlices[id].owner != address(0), "YS: no such credit slice");
        _;
    }

    modifier debtSliceOwner(uint256 id) {
        require(debtSlices[id].owner == msg.sender, "YS: only owner");
        _;
    }

    modifier debtSliceOwnerOrUnlocker(uint256 id) {
        require(debtSlices[id].owner == msg.sender || unlocker == msg.sender, "YS: only owner or unlocker");
        _;
    }

    modifier creditSliceOwner(uint256 id) {
        require(creditSlices[id].owner == msg.sender, "YS: only owner");
        _;
    }

    modifier noDust(uint256 amount) {
        require(amount > dustLimit, "YS: dust");
        _;
    }

    modifier validAddress(address recipient) {
        require(recipient != address(0), "YS: zero address");
        require(recipient != address(this), "YS: this address");
        _;
    }

    /// @notice Create a YieldSlice.
    /// @param symbol Symbol for the NPV token.
    /// @param yieldSource_ An interface to interact with the underlying source of yield.
    /// @param debtData_ Tracker for yield per token per second on debt side.
    /// @param creditData_ Tracker for yield per token per second on credit side.
    /// @param discounter_ Discount function for the future yield.
    /// @param dustLimit_ Smallest amount of generating tokens that can be locked.
    constructor(string memory symbol,
                address yieldSource_,
                address debtData_,
                address creditData_,
                address discounter_,
                uint256 dustLimit_)

        validAddress(yieldSource_)
        validAddress(debtData_)
        validAddress(creditData_)
        validAddress(discounter_) {

        gov = msg.sender;
        unlocker = msg.sender;
        treasury = msg.sender;

        npvToken = new NPVToken(symbol, symbol);
        yieldSource = IYieldSource(yieldSource_);
        generatorToken = IYieldSource(yieldSource_).generatorToken();
        yieldToken = IYieldSource(yieldSource_).yieldToken();
        discounter = IDiscounter(discounter_);
        dustLimit = dustLimit_;
        debtData = YieldData(debtData_);
        creditData = YieldData(creditData_);

        creditSlices[UNALLOC_ID] = CreditSlice({
            owner: address(this),
            createdTimestamp: uint128(block.timestamp),
            blockTimestamp: uint128(block.timestamp),
            npvCredit: 0,
            npvTokens: 0,
            pending: 0,
            claimed: 0,
            memo: new bytes(0) });
    }

    function _min(uint256 x1, uint256 x2) private pure returns (uint256) {
        return x1 < x2 ? x1 : x2;
    }

    /// @notice Set the governance address.
    /// @param gov_ The new governance address.
    function setGov(address gov_) validAddress(gov_) external onlyGov {
        gov = gov_;

        emit Gov(gov);
    }

    /// @notice Set the unlocker address.
    /// @param unlocker_ The new unlocker address.
    function setUnlocker(address unlocker_) validAddress(unlocker_) external onlyGov {
        unlocker = unlocker_;

        emit Unlocker(unlocker);
    }

    /// @notice Set the treasury address.
    /// @param treasury_ The new treasury address.
    function setTreasury(address treasury_) validAddress(treasury_) external onlyGov {
        treasury = treasury_;

        emit Treasury(treasury);
    }

    /// @notice Set the dust limit.
    /// @param dustLimit_ The new dust limit.
    function setDustLimit(uint256 dustLimit_) external onlyGov {
        dustLimit = dustLimit_;

        emit DustLimit(dustLimit);
    }

    /// @notice Set the fee ratio on the debt side.
    /// @param debtFee_ The new debt fee ratio.
    function setDebtFee(uint256 debtFee_) external onlyGov {
        require(debtFee_ <= MAX_DEBT_FEE_RATIO, "YS: max debt fee");
        debtFee = debtFee_;

        emit DebtFee(debtFee);
    }

    /// @notice Set the fee ratio othe credit side.
    /// @param creditFee_ The new credit fee ratio.
    function setCreditFee(uint256 creditFee_) external onlyGov {
        require(creditFee_ <= MAX_CREDIT_FEE, "YS: max credit fee");
        creditFee = creditFee_;

        emit CreditFee(creditFee);
    }

    /// @notice Total number of yield generating tokens.
    /// @return Total number of yield generating tokens.
    function totalTokens() public view returns (uint256) {
        return yieldSource.amountGenerator();
    }

    /// @notice Amount of yield generated in the contract's lifetime.
    /// @return Cumulative yield on debt side.
    function cumulativeYield() public view returns (uint256) {
        return harvestedYield + yieldSource.amountPending();
    }

    /// @notice Amount of yield generated in the contract's lifetime, including direct payments.
    /// @return Cumulative yield on credit side.
    function cumulativeYieldCredit() public view returns (uint256) {
        return harvestedYield + cumulativePaidYield + yieldSource.amountPending();
    }

    /// @notice Harvest yield from the yield generating tokens.
    function harvest() external nonReentrant {
        _harvest();
    }

    function _harvest() private {
        uint256 pending = yieldSource.amountPending();
        if (pending == 0) return;
        yieldSource.harvest();
        harvestedYield += pending;

        emit Harvest(harvestedYield, pending);
    }

    /// @notice Recrod data for yield generation rates on both debt and credit side.
    function recordData() external nonReentrant {
        _recordData();
    }

    function _recordData() private {
        uint256 debtTT = totalTokens();
        uint256 debtCY = cumulativeYield();
        debtData.record(debtTT, debtCY);

        uint256 creditCY = cumulativeYieldCredit();
        creditData.record(activeNPV, creditCY);

        emit RecordDebtData(debtTT, debtCY);
        emit RecordCreditData(activeNPV, creditCY);
    }

    /// @notice Number of locked tokens associated with a debt slice.
    /// @param id ID of the debt slice.
    function tokens(uint256 id) public view isDebtSlice(id) returns (uint256) {
        if (totalShares == 0) return 0;
        return totalTokens() * debtSlices[id].shares / totalShares;
    }

    function _previewDebtSlice(uint256 tokens_, uint256 yield) internal view returns (uint256, uint256) {
        uint256 npv = discounter.discounted(tokens_, yield);
        uint256 fees = ((yield - npv) * debtFee) / FEE_DENOM;
        return (npv, fees);
    }

    /// @notice Compute the amount of NPV tokens from locking yield into a slice.
    /// @param tokens_ Amount of yield generating tokens to lock.
    /// @param yield Amount of future yield to lock.
    /// @return uint256 Amount of NPV tokens minted to recipient.
    /// @return uint256 Amount of NPV tokens going to fees.
    function previewDebtSlice(uint256 tokens_, uint256 yield) public view returns (uint256, uint256) {
        return _previewDebtSlice(tokens_, yield);
    }

    function _previewRollover(uint256 id, uint256 yield) internal view returns (uint256, uint256, uint256) {
        DebtSlice storage slice = debtSlices[id];
        ( , uint256 npvGen, ) = generatedDebt(id);

        // Block rollovers for paid slices, to avoid refund accounting. User
        // can unlock and lock into a new slice instead.
        if (npvGen >= slice.npvDebt) return (0, 0, 0);

        // Compute preview as if it were a brand new debt slice.
        (uint256 npv, uint256 fees) = _previewDebtSlice(slice.tokens, yield);

        // Compute NPV debt remaining, relative to the current timestamp
        uint256 remainingShifted = discounter.shiftForward(block.timestamp - uint256(slice.blockTimestamp),
                                                           slice.npvDebt - npvGen);

        // If remaining NPV debt burden exceeds what we can mint, then we can't rollover
        if (remainingShifted > npv) return (0, 0, 0);

        uint256 incrementalNPV = npv - remainingShifted;
        uint256 incrementalFees = fees * incrementalNPV / npv;

        return (remainingShifted,
                incrementalNPV,
                incrementalFees);
    }

    /// @notice Compute the result of a debt slice rollover.
    /// @param id Id of the debt slice to rollover.
    /// @param yield Amount of future yield to lock, as if we were locking it relative to today.
    /// @return uint256 Amount of NPV debt, relative to the current timestamp, before the rollover.
    /// @return uint256 Amount of incremental NPV tokens minted to recipient.
    /// @return uint256 Amount of incremental NPV tokens going to fees.
    function previewRollover(uint256 id, uint256 yield) public view returns (uint256, uint256, uint256) {
        return _previewRollover(id, yield);
    }

    function _modifyDebtPosition(uint256 id, uint256 deltaGenerator, uint256 deltaYield)
        internal
        isDebtSlice(id)
        returns (uint256, uint256) {

        DebtSlice storage slice = debtSlices[id];

        // Update generator shares and deposit the tokens
        uint256 newTotalShares;
        uint256 deltaShares;
        uint256 oldTotalTokens = totalTokens();
        if (totalShares == 0 || oldTotalTokens == 0) {
            newTotalShares = deltaGenerator;
            deltaShares = deltaGenerator;
        } else {
            newTotalShares = (oldTotalTokens + deltaGenerator) * totalShares / oldTotalTokens;
            deltaShares = newTotalShares - totalShares;
        }

        generatorToken.safeTransferFrom(msg.sender, address(this), deltaGenerator);
        generatorToken.safeApprove(address(yieldSource), 0);
        generatorToken.safeApprove(address(yieldSource), deltaGenerator);
        yieldSource.deposit(deltaGenerator, false);

        // Update NPV debt for the slice
        (uint256 npv, uint256 fees) = _previewDebtSlice(deltaGenerator, deltaYield);
        slice.npvDebt = npv;
        slice.blockTimestamp = uint128(block.timestamp);
        slice.shares += deltaShares;
        slice.tokens += deltaGenerator;

        totalShares = newTotalShares;

        return (npv, fees);
    }

    /// @notice Lock yield generating tokens into a slice, in exchange for NPV tokens.
    /// @param owner Owner of the resulting debt slice, entitled to transfer the slice and unlock underlying.
    /// @param recipient Recipient of the NPV tokens minted.
    /// @param amountGenerator Amount of yield generating tokens to lock.
    /// @param amountYield Amount of yield to lock.
    /// @param memo Optional memo data to associate with the yield slice.
    /// @return ID of the debt slice.
    function debtSlice(address owner,
                       address recipient,
                       uint256 amountGenerator,
                       uint256 amountYield,
                       bytes calldata memo)
        external
        nonReentrant
        noDust(amountGenerator)
        validAddress(recipient)
        returns (uint256) {

        uint256 id = nextId++;
        debtSlices[id] = DebtSlice({
            owner: owner,
            blockTimestamp: 0,
            unlockedBlockTimestamp: 0,
            shares: 0,
            tokens: 0,
            npvDebt: 0,
            memo: memo });

        (uint256 npv, uint256 fees) = _modifyDebtPosition(id, amountGenerator, amountYield);

        npvToken.mint(recipient, npv - fees);
        npvToken.mint(treasury, fees);
        activeNPV += npv;

        _modifyCreditPosition(UNALLOC_ID, int256(npv));
        _recordData();

        emit SliceDebt(owner, id, amountGenerator, amountYield, npv, fees);
        
        return id;
    }

    function _approveRollover(uint256 id, address who, uint256 amountYield) internal {
        approvedRollover[id] = RolloverApproval(who, amountYield);

        emit ApproveRollover(id, who, amountYield);
    }

    /// @notice Allow an address to rollover an owned debt slice.
    /// @param id The debt slice to approve for rollover.
    /// @param who The address to approve for rollover.
    /// @param amountYield The exact amount to approve for rollover.
    function approveRollover(uint256 id, address who, uint256 amountYield)
        external
        nonReentrant
        debtSliceOwner(id) {

        _approveRollover(id, who, amountYield);
    }

    /// @notice Rollover a debt slice by taking out a new loan, and mint new NPV tokens.
    /// @param id The debt slice to rollover.
    /// @param recipient The recipient of minted NPV tokens.
    /// @param amountYield The amount of yield to be commited into the slice.
    /// @return The amount of new NPV tokens minted.
    function rollover(uint256 id, address recipient, uint256 amountYield)
        external
        nonReentrant
        returns (uint256) {

        require(debtSlices[id].owner == msg.sender ||
                (approvedRollover[id].who == msg.sender &&
                 approvedRollover[id].amount == amountYield),
                "YS: only owner or approved");

        (uint256 remainingNPV,
         uint256 incrementalNPV,
         uint256 incrementalFees) = _previewRollover(id, amountYield);
        require(incrementalNPV > 0, "YS: cannot rollover");

        DebtSlice storage slice = debtSlices[id];

        slice.blockTimestamp = uint128(block.timestamp);
        slice.npvDebt = remainingNPV + incrementalNPV;
        
        npvToken.mint(recipient, incrementalNPV - incrementalFees);
        npvToken.mint(treasury, incrementalFees);
        activeNPV += incrementalNPV;

        _modifyCreditPosition(UNALLOC_ID, int256(incrementalNPV));
        _recordData();

        _approveRollover(id, address(0), 0);

        emit RolloverDebt(slice.owner,
                          id,
                          amountYield,
                          remainingNPV + incrementalNPV,
                          incrementalFees);

        return incrementalNPV;
    }

    /// @notice Mint NPV tokens from yield at 1:1 rate.
    /// @param recipient Recipient of the NPV tokens minted.
    /// @param amount The amount of yield tokens to exchange for NPV tokens.
    function mintFromYield(address recipient, uint256 amount)
        external
        validAddress(recipient) {

        IERC20(yieldToken).safeTransferFrom(msg.sender, address(this), amount);
        npvToken.mint(recipient, amount);
        activeNPV += amount;
        cumulativePaidYield += amount;
        _recordData();

        emit MintFromYield(recipient, amount);
    }

    /// @notice Pay off a debt slice using NPV tokens.
    /// @param id ID of the debt slice to pay.
    /// @param amount Amount of NPV tokens to pay off.
    /// @return Actual amouhnt of NPV tokens used to pay off.
    function payDebt(uint256 id, uint256 amount)
        external
        nonReentrant
        isDebtSlice(id) returns (uint256) {

        DebtSlice storage slice = debtSlices[id];
        require(slice.unlockedBlockTimestamp == 0, "YS: already unlocked");

        ( , uint256 npvGen, ) = generatedDebt(id);
        uint256 left = npvGen > slice.npvDebt ? 0 : slice.npvDebt - npvGen;
        uint256 actual = _min(left, amount);
        IERC20(npvToken).safeTransferFrom(msg.sender, address(this), actual);
        slice.npvDebt -= actual;
        npvToken.burn(address(this), actual);
        activeNPV -= actual;

        emit PayDebt(id, actual);

        return actual;
    }

    /// @notice Transfer ownership of a yield slice.
    /// @param id ID of the slice to transfer.
    /// @param recipient Recipient of the transfer
    function transferOwnership(uint256 id, address recipient)
        external
        nonReentrant
        validAddress(recipient)
        isSlice(id) {

        if (approvedRollover[id].amount != 0) {
            approvedRollover[id].who = address(0);
            approvedRollover[id].amount = 0;
        }

        if (debtSlices[id].owner != address(0)) {
            DebtSlice storage slice = debtSlices[id];
            require(recipient != slice.owner, "YS: transfer owner");
            require(slice.owner == msg.sender, "YS: only debt slice owner");
            slice.owner = recipient;
        } else {
            CreditSlice storage slice = creditSlices[id];
            require(recipient != slice.owner, "YS: transfer owner");
            require(slice.owner == msg.sender, "YS: only credit slice owner");
            _claim(id, 0);
            slice.owner = recipient;
        }

        emit TransferOwnership(id, recipient);
    }

    /// @notice Unlock the underlying tokens for a debt slice, if possible. Excess yield generated will be refunded.
    /// @dev Unlocker role may unlock a debt slice, to prevent excess refund loss for the owner.
    /// @param id ID of the debt slice.
    function unlockDebtSlice(uint256 id) external nonReentrant debtSliceOwnerOrUnlocker(id) {
        DebtSlice storage slice = debtSlices[id];
        require(slice.unlockedBlockTimestamp == 0, "YS: already unlocked");

        ( , uint256 npvGen, uint256 refund) = generatedDebt(id);

        require(npvGen >= slice.npvDebt, "YS: npv debt");

        if (refund > 0) {
            _harvest();
            uint256 balance = IERC20(yieldToken).balanceOf(address(this));
            IERC20(yieldToken).safeTransfer(slice.owner, _min(balance, refund));
        }

        uint256 amount = _min(yieldSource.amountGenerator(), tokens(id));
        yieldSource.withdraw(amount, false, slice.owner);
        activeNPV -= slice.npvDebt;
        totalShares -= slice.shares;

        slice.unlockedBlockTimestamp = uint128(block.timestamp);

        emit UnlockDebtSlice(slice.owner, id);
    }

    function _creditFees(uint256 npv) internal view returns (uint256) {
        return (npv * creditFee) / FEE_DENOM;
    }

    function creditFees(uint256 npv) external view returns (uint256) {
        return _creditFees(npv);
    }

    /// @notice Modify a credit slice's NPV values.
    /// @dev Here be dragons: Pay careful attention to which timestamp the NPV values reference.
    /// @param id The credit slice to modify.
    /// @param deltaNPV Change in NPV tokens, relative to the creation timestamp of the slice.
    function _modifyCreditPosition(uint256 id, int256 deltaNPV) internal isCreditSlice(id) {
        if (deltaNPV == 0) return;
        CreditSlice storage slice = creditSlices[id];

        // The new NPV credited will be the existing NPV's value shifted
        // forward to the current timestamp, subtracting the already generated
        // NPV to this point.
        ( , uint256 npvGen, uint256 claimable) = generatedCredit(id);

        uint256 shiftedNPV = discounter.shiftForward(block.timestamp - uint256(slice.blockTimestamp),
                                                     slice.npvCredit - npvGen);

        // Checkpoint what we can claim as pending, and set claimed to zero
        // as it is now relative to the new timestamp.
        slice.blockTimestamp = uint128(block.timestamp);
        slice.pending = claimable;
        slice.claimed = 0;

        uint256 secondsFromCreation = block.timestamp - uint256(slice.createdTimestamp);

        // Update npvCredit and npvTokens. Carefully track which timestamp they are
        // relative to. The npvCredit field is the slice's entitled NPV relative to
        // slice.blockTimestamp. The npvTokens field is the slice's locked NPV tokens,
        // and can be used to compute their entitled NPV relative to the creation
        // timestamp.
        if (deltaNPV >= 0) {
            slice.npvCredit = shiftedNPV + discounter.shiftForward(secondsFromCreation,
                                                                   uint256(deltaNPV));
            slice.npvTokens += uint256(deltaNPV);
        } else {
            slice.npvCredit = shiftedNPV - discounter.shiftForward(secondsFromCreation,
                                                                   uint256(-deltaNPV));
            slice.npvTokens -= uint256(-deltaNPV);
        }
    }

    /// @notice Exchange NPV tokens for future yield, in the form of a credit slice.
    /// @param npv Amount of NPV tokens to swap.
    /// @param recipient Recipient of the credit slice.
    /// @param memo Optional memo data to associate with the yield slice.
    /// @return ID of the credit slice.
    function creditSlice(uint256 npv, address recipient, bytes calldata memo)
        external
        nonReentrant
        validAddress(recipient)
        returns (uint256) {

        uint256 fees = _creditFees(npv);

        IERC20(npvToken).safeTransferFrom(msg.sender, address(this), npv);
        IERC20(npvToken).safeTransfer(treasury, fees);

        CreditSlice storage unalloc = creditSlices[UNALLOC_ID];

        // Compute the unallocated slice's generated NPV and claimable amounts,
        // relative to the original timestamp. Record this as pending yield, and
        // update the remaining NPV, if any.
        {
            (, uint256 npvGen, uint256 claimable) = generatedCredit(UNALLOC_ID);
            unalloc.npvCredit -= npvGen;
            unalloc.pending = claimable;
        }

        // Shift the unallocated slice's remaining NPV credit such that it becomes
        // relative to the current timestamp.
        unalloc.npvCredit = discounter.shiftForward(block.timestamp - uint256(unalloc.blockTimestamp),
                                                    unalloc.npvCredit);

        // Compute the proportional share of vested, pending yield that will go to
        // the new slice.
        uint256 pendingShare = unalloc.pending * (npv - fees) / unalloc.npvTokens;

        // Compute the proportional share of remaining NPV credit that will go to the
        // new slice.
        uint256 npvCredit = unalloc.npvCredit * (npv - fees) / unalloc.npvTokens;

        // Update the unallocated slice
        unalloc.blockTimestamp = uint128(block.timestamp);
        unalloc.pending -= pendingShare;
        unalloc.npvCredit -= npvCredit;
        unalloc.npvTokens -= npv;

        uint256 id = nextId++;
        CreditSlice memory slice = CreditSlice({
            owner: recipient,
            createdTimestamp: uint128(block.timestamp),
            blockTimestamp: uint128(block.timestamp),
            npvCredit: npvCredit,
            npvTokens: npv - fees,
            pending: pendingShare,
            claimed: 0,
            memo: memo });
        creditSlices[id] = slice;

        emit SliceCredit(recipient, id, npv, fees);

        return id;
    }

    function _claim(uint256 id, uint256 limit) internal returns (uint256) {
        CreditSlice storage slice = creditSlices[id];
        ( , uint256 npvGen, uint256 claimable) = generatedCredit(id);

        if (claimable == 0) return 0;

        _harvest();
        uint256 amount = _min(claimable, yieldToken.balanceOf(address(this)));
        if (limit > 0) {
            amount = _min(limit, amount);
        }
        yieldToken.safeTransfer(slice.owner, amount);
        slice.claimed += amount;

        if (npvGen == slice.npvCredit) {
            npvToken.burn(address(this), slice.npvTokens);
        }

        emit Claimed(id, amount);

        return amount;
    }

    /// @notice Claim yield from a credit slice.
    /// @param id ID of the credit slice.
    /// @param limit Max amount of yield to claim, where 0 is no limit.
    /// @return Amount of yield claimed.
    function claim(uint256 id, uint256 limit)
        external
        nonReentrant
        creditSliceOwner(id) returns (uint256) {

        return _claim(id, limit);
    }

    function withdrawableNPV(uint256 id)
        public
        view
        isCreditSlice(id)
        returns (uint256) {

        CreditSlice storage slice = creditSlices[id];

        // Compute the NPV credit available relative to slice's timestamp,
        // and shift that value backwards such that it is becomes relative
        // to the creation timestamp.
        ( , uint256 npvGen, ) = generatedCredit(id);
        return discounter.shiftBackward(block.timestamp - uint256(slice.createdTimestamp),
                                        slice.npvCredit - npvGen);
    }

    /// @notice Withdraw NPV tokens from a credit slice, if possible.
    /// @param id ID of the credit slice.
    /// @param recipient Recipient of the NPV tokens.
    /// @param amount Amount of NPV to withdraw.
    function withdrawNPV(uint256 id,
                         address recipient,
                         uint256 amount)
        external
        nonReentrant
        validAddress(recipient)
        creditSliceOwner(id) {

        uint256 available = withdrawableNPV(id);

        if (amount == 0) {
            amount = available;
        }

        require(amount <= available, "YS: insufficient NPV");

        npvToken.transfer(recipient, amount);
        _modifyCreditPosition(id, -int256(amount));
        _modifyCreditPosition(UNALLOC_ID, int256(amount));

        emit WithdrawNPV(recipient, id, amount);
    }

    /// @notice Amount of NPV debt remaining for debt slice.
    /// @param id ID of the debt slice.
    /// @return Amount of NPV debt remaining.
    function remaining(uint256 id) external view returns (uint256) {
        ( , uint256 npvGen, ) = generatedDebt(id);
        return debtSlices[id].npvDebt - npvGen;
    }

    /// @notice Yield generated by a debt slice.
    /// @param id ID of the debt slice.
    /// @return Total nominal yield generated.
    /// @return NPV of the yield generated, relative to slice creation.
    /// @return Amount of yield tokens to refund upon unlock.
    function generatedDebt(uint256 id) public view returns (uint256, uint256, uint256) {
        DebtSlice storage slice = debtSlices[id];
        uint256 nominal = 0;
        uint256 npv = 0;
        uint256 refund = 0;
        uint256 last = slice.unlockedBlockTimestamp == 0 ? block.timestamp : slice.unlockedBlockTimestamp;

        for (uint256 i = slice.blockTimestamp;
             i < last;
             i += discounter.discountPeriod()) {

            uint256 end = _min(last - 1, i + discounter.discountPeriod());
            uint256 yts = debtData.yieldPerTokenPerSecond(uint128(i),
                                                          uint128(end),
                                                          totalTokens(),
                                                          cumulativeYield());

            uint256 yield = (yts * (end - i) * slice.tokens) / debtData.PRECISION_FACTOR();
            uint256 pv = discounter.shiftBackward(end - slice.blockTimestamp, yield);

            if (npv == slice.npvDebt) {
                refund += yield;
            } else if (npv + pv > slice.npvDebt) {
                uint256 owed = discounter.shiftForward(end - slice.blockTimestamp,
                                                       slice.npvDebt - npv);
                uint256 leftover = yield - owed;
                nominal += owed;
                refund += leftover;
                npv = slice.npvDebt;
            } else {
                npv += pv;
                nominal += yield;
            }
        }

        return (nominal, npv, refund);
    }

    /// @notice Yield generated by a credit slice.
    /// @param id ID of the credit slice.
    /// @return Total nominal yield generated.
    /// @return NPV of the yield generated, relative to slice creation.
    /// @return Amount of yield tokens claimable for this slice.
    function generatedCredit(uint256 id) public view returns (uint256, uint256, uint256) {
        CreditSlice storage slice = creditSlices[id];
        uint256 nominal = 0;
        uint256 npv = 0;
        uint256 claimable = 0;

        for (uint256 i = slice.blockTimestamp;
             npv < slice.npvCredit && i < block.timestamp;
             i += discounter.discountPeriod()) {

            uint256 end = _min(block.timestamp - 1, i + discounter.discountPeriod());
            uint256 yts = creditData.yieldPerTokenPerSecond(uint128(i),
                                                            uint128(end),
                                                            activeNPV,
                                                            cumulativeYieldCredit());

            uint256 yield = (yts * (end - i) * slice.npvTokens) / creditData.PRECISION_FACTOR();
            uint256 pv = discounter.shiftBackward(end - slice.blockTimestamp, yield);

            if (npv + pv > slice.npvCredit) {
                pv = slice.npvCredit - npv;
                yield = discounter.shiftForward(end - slice.blockTimestamp, pv);
            }

            claimable += yield;
            nominal += yield;
            npv += pv;
        }

        return (slice.pending + nominal,
                npv,
                slice.pending + claimable - slice.claimed);
    }
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/** @notice YieldData keeps track of historical average yields on a periodic
    basis. It uses this data to return the overall average yield for a range
    of time in the `yieldPerTokenPerSlock` method. This method is O(N) on the
    number of epochs recorded. Therefore, to prevent excessive gas costs, the
    interval should be set such that N does not exceed around a thousand. An
    interval of 10 days will stay below this limit for a few decades. Keep in
    mind, though, that a larger interval reduces accuracy.

    Owner role can set the writer role up to one time.
*/
contract YieldData is Ownable {
    struct Epoch {
        uint256 tokens;
        uint256 yield;
        uint256 yieldPerToken;
        uint128 blockTimestamp;
        uint128 epochSeconds;
    }

    uint256 public constant PRECISION_FACTOR = 10**18;

    /** @notice Writer role is permitted to write new data points. This
        role can only be assigned once, and it is expected to be set to
        a YieldSlice contract, which writes data in a deterministic
        fashion.
     */
    address public writer;

    uint128 public immutable interval;

    Epoch[] public epochs;
    uint128 public epochIndex;

    event SetWriter(address indexed who);

    /// @notice Create a YieldData.
    /// @param interval_ Minimum size in seconds of each epoch.
    constructor(uint128 interval_) {
        interval = interval_;
        writer = address(0);
    }

    /// @notice Set the writer.
    /// @param writer_ The new writer.
    function setWriter(address writer_) external onlyOwner {
        require(writer_ != address(0), "YD: zero address");
        require(writer == address(0), "YD: only set once");
        writer = writer_;

        emit SetWriter(writer);
    }

    /// @notice Check if data is empty.
    /// @return True if the data is empty.
    function isEmpty() external view returns (bool) {
        return epochs.length == 0;
    }

    /// @notice Get the current epoch.
    /// @return The current epoch.
    function current() external view returns (Epoch memory) {
        return epochs[epochIndex];
    }

    function _record(uint256 tokens, uint256 yield) internal view returns
        (Epoch memory epochPush, Epoch memory epochSet) {

        if (epochs.length == 0) {
            epochPush = Epoch({
                blockTimestamp: uint128(block.timestamp),
                epochSeconds: 0,
                tokens: tokens,
                yield: yield,
                yieldPerToken: 0 });
        } else {
            Epoch memory c = epochs[epochIndex];

            uint128 epochSeconds = uint128(block.timestamp) - c.blockTimestamp - c.epochSeconds;
            uint256 delta = (yield - c.yield);

            c.yieldPerToken += c.tokens == 0 ? 0 : delta * PRECISION_FACTOR / c.tokens;
            c.epochSeconds += epochSeconds;

            if (c.epochSeconds >= interval) {
                epochPush = Epoch({
                    blockTimestamp: uint128(block.timestamp),
                    epochSeconds: 0,
                    tokens: tokens,
                    yield: yield,
                    yieldPerToken: 0 });
            } else {
                c.tokens = tokens;
            }

            c.yield = yield;
            epochSet = c;
        }
    }

    /// @notice Record new data.
    /// @param tokens Amount of generating tokens for this data point.
    /// @param yield Amount of yield generated for this data point. Cumulative and monotonically increasing.
    function record(uint256 tokens, uint256 yield) external {
        require(msg.sender == writer, "YD: only writer");

        (Epoch memory epochPush, Epoch memory epochSet) = _record(tokens, yield);

        if (epochSet.blockTimestamp != 0) {
            epochs[epochIndex] = epochSet;
        }
        if (epochPush.blockTimestamp != 0) {
            epochs.push(epochPush);
            epochIndex = uint128(epochs.length) - 1;
        }
    }

    function _find(uint128 blockTimestamp) internal view returns (uint256 result) {
        require(epochs.length > 0, "YD: no epochs");

        result = epochIndex;
        if (blockTimestamp >= epochs[epochIndex].blockTimestamp) return epochIndex;
        if (blockTimestamp <= epochs[0].blockTimestamp) return 0;

        uint256 i = epochs.length / 2;
        uint256 start = 0;
        uint256 end = epochs.length;
        while (true) {
            uint128 bn = epochs[i].blockTimestamp;
            if (blockTimestamp >= bn &&
                (i + 1 > epochIndex || blockTimestamp < epochs[i + 1].blockTimestamp)) {
                return i;
            }

            if (blockTimestamp > bn) {
                start = i + 1;
            } else {
                end = i;
            }
            i = (start + end) / 2;
        }
    }

    /// @notice Compute the yield per token per second for a time range. The first and final epoch in the time range are prorated, and therefore the resulting value is an approximation.
    /// @param start Timestamp indicating the start of the time range.
    /// @param end Timestmap indicating the end of the time range.
    /// @param tokens Optional, the amount of tokens locked. Can be 0.
    /// @param yield Optional, the amount of cumulative yield. Can be 0.
    /// @return Amount of yield per `PRECISION_FACTOR` amount of tokens per second.
    function yieldPerTokenPerSecond(uint128 start, uint128 end, uint256 tokens, uint256 yield) external view returns (uint256) {
        if (start == end) return 0;
        if (start == uint128(block.timestamp)) return 0;

        require(start < end, "YD: start must precede end");
        require(start < uint128(block.timestamp), "YD: start must be in the past");
        require(end <= uint128(block.timestamp), "YD: end must be in the past or current");

        uint256 index = _find(start);
        uint256 yieldPerToken;
        uint256 numSeconds;

        Epoch memory epochPush;
        Epoch memory epochSet;
        if (yield != 0) (epochPush, epochSet) = _record(tokens, yield);
        uint128 maxIndex = epochPush.blockTimestamp == 0 ? epochIndex : epochIndex + 1;

        while (true) {
            if (index > maxIndex) break;
            Epoch memory epoch;
            if (epochSet.blockTimestamp != 0 && index == epochIndex) {
                epoch = epochSet;
            } else {
                epoch = epochs[index];
            }

            ++index;

            uint256 epochSeconds = epoch.epochSeconds;
            if (epochSeconds == 0) break;

            if (start > epoch.blockTimestamp) {
                epochSeconds -= start - epoch.blockTimestamp;
            }
            if (end < epoch.blockTimestamp + epoch.epochSeconds) {
                epochSeconds -= epoch.blockTimestamp + epoch.epochSeconds - end;
            }

            uint256 incr = (epochSeconds * epoch.yieldPerToken) / epoch.epochSeconds;

            yieldPerToken += incr;
            numSeconds += epochSeconds;

            if (end < epoch.blockTimestamp + epoch.epochSeconds) break;
        }

        if (numSeconds == 0) return 0;

        return yieldPerToken / numSeconds;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDiscounter {
    function discountPeriod() external view returns (uint256);

    function setDaily(uint256 daily) external;
    function setMaxDays(uint256 maxDays) external;

    function discounted(uint256 generator, uint256 yield) external view returns (uint256);
    function shiftForward(uint256 numSeconds, uint256 npv) external view returns (uint256);
    function shiftBackward(uint256 numSeconds, uint256 npv) external view returns (uint256);
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

abstract contract ILiquidityPool {
    address public token0;
    address public token1;

    // Not marked `view` to allow calls to Uniswap Quoter, which is
    // gas inefficient. Do not call on-chain.
    function previewSwap(address tokenIn,
                         uint128 amountIn,
                         uint128 sqrtPriceLimitX96) virtual external returns (uint256, uint256);

    function previewSwapOut(address tokenIn,
                            uint128 amountOut,
                            uint128 sqrtPriceLimitX96) virtual external returns (uint256, uint256);

    function swap(address recipient,
                  address tokenIn,
                  uint128 amountIn,
                  uint128 amountOutMinimum,
                  uint128 sqrtPriceLimitX96)
        virtual external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IYieldSource {
    function yieldToken() external virtual view returns (IERC20);
    function generatorToken() external virtual view returns (IERC20);
    function setOwner(address) external virtual;
    function deposit(uint256 amount, bool claim) external virtual;
    function withdraw(uint256 amount, bool claim, address to) external virtual;
    function harvest() external virtual;
    function amountPending() external virtual view returns (uint256);
    function amountGenerator() external virtual view returns (uint256);
}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.13;

import { ERC20 } from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";

/** @notice NPV tokens are used to track the net present value of future yield.

    Owner role is allowed to mint and burn token, and set a new owner.
    Expected to be a YieldSlice.
 */
contract NPVToken is ERC20, Ownable {

    /// @notice Create an NPVToken.
    /// @param name Name of the token.
    /// @param symbol Symbol of the token.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable() {
    }

    /// @notice Mint new NPV tokens.
    /// @param recipient Recipient of the new tokens.
    /// @param amount Amount of tokens to mint.
    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    /// @notice Burn NPV tokens.
    /// @param recipient Recipient of the burn.
    /// @param amount Amout of tokens to burn.
    function burn(address recipient, uint256 amount) external onlyOwner {
        require(recipient == msg.sender, "NPVT: can only burn own");
        require(balanceOf(recipient) >= amount, "NPVT: insufficient balance");
        _burn(recipient, amount);
    }
}