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

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Interfaces
import { IPLPv2 } from "./interfaces/IPLPv2.sol";

contract PLPv2 is ReentrancyGuard, Ownable, ERC20("PLPv2", "Perp88 LP v2") {
  mapping(address => bool) public minters;

  event SetMinter(address indexed minter, bool isMinter);

  /**
   * Modifiers
   */

  modifier onlyMinter() {
    if (!minters[msg.sender]) {
      revert IPLPv2.IPLPv2_onlyMinter();
    }
    _;
  }

  function setMinter(address minter, bool isMinter) external onlyOwner nonReentrant {
    minters[minter] = isMinter;
    emit SetMinter(minter, isMinter);
  }

  function mint(address to, uint256 amount) external onlyMinter nonReentrant {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter nonReentrant {
    _burn(from, amount);
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

interface IPLPv2 {
  /**
   * ERRORS
   */
  error IPLPv2_onlyMinter();

  function setMinter(address minter, bool isMinter) external;

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function approve(address _to, uint256 _amount) external;

  function balanceOf(address _account) external returns (uint256 _amount);

  function totalSupply() external returns (uint256 _total);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// base
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Owned } from "@hmx/base/Owned.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contracts
import { LiquidityService } from "@hmx/services/LiquidityService.sol";
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";
import { PerpStorage } from "@hmx/storages/PerpStorage.sol";
import { Calculator } from "@hmx/contracts/Calculator.sol";
import { OracleMiddleware } from "@hmx/oracle/OracleMiddleware.sol";

// interfaces
import { ILiquidityHandler } from "@hmx/handlers/interfaces/ILiquidityHandler.sol";
import { IWNative } from "../interfaces/IWNative.sol";
import { IPyth } from "pyth-sdk-solidity/IPyth.sol";

/// @title LiquidityHandler
contract LiquidityHandler is Owned, ReentrancyGuard, ILiquidityHandler {
  using SafeERC20 for IERC20;

  /**
   * Events
   */
  event LogSetLiquidityService(address oldValue, address newValue);
  event LogSetMinExecutionFee(uint256 oldValue, uint256 newValue);
  event LogSetPyth(address oldPyth, address newPyth);
  event LogSetOrderExecutor(address executor, bool isAllow);
  event LogCreateAddLiquidityOrder(
    address indexed account,
    uint256 indexed orderId,
    address indexed token,
    uint256 amountIn,
    uint256 minOut,
    uint256 executionFee
  );
  event LogCreateRemoveLiquidityOrder(
    address indexed account,
    uint256 indexed orderId,
    address indexed token,
    uint256 amountIn,
    uint256 minOut,
    uint256 executionFee,
    bool isNativeOut
  );
  event LogExecuteLiquidityOrder(
    address indexed account,
    uint256 indexed orderId,
    address indexed token,
    uint256 amount,
    uint256 minOut,
    bool isAdd,
    uint256 actualOut
  );
  event LogCancelLiquidityOrder(
    address indexed account,
    uint256 indexed orderId,
    address indexed token,
    uint256 amount,
    uint256 minOut,
    bool isAdd
  );

  event LogRefund(
    address indexed account,
    uint256 indexed orderId,
    address indexed token,
    uint256 amount,
    bool isNativeOut
  );
  /**
   * States
   */

  address liquidityService; //liquidityService
  address pyth; //pyth
  uint256 public executionOrderFee; // executionOrderFee in tokenAmount unit
  bool isExecuting; // order is executing (prevent direct call executeLiquidity()

  uint256 public nextExecutionOrderIndex;
  LiquidityOrder[] public liquidityOrders; // all liquidityOrder

  mapping(address => bool) public orderExecutors; //address -> flag to execute

  constructor(address _liquidityService, address _pyth, uint256 _executionOrderFee) {
    liquidityService = _liquidityService;
    pyth = _pyth;
    executionOrderFee = _executionOrderFee;
    // slither-disable-next-line unused-return
    LiquidityService(_liquidityService).perpStorage();
    // slither-disable-next-line unused-return
    IPyth(_pyth).getUpdateFee(new bytes[](0));
  }

  /**
   * MODIFIER
   */

  modifier onlyAcceptedToken(address _token) {
    ConfigStorage(LiquidityService(liquidityService).configStorage()).validateAcceptedLiquidityToken(_token);
    _;
  }

  modifier onlyOrderExecutor() {
    if (!orderExecutors[msg.sender]) revert ILiquidityHandler_NotWhitelisted();
    _;
  }

  receive() external payable {
    if (msg.sender != ConfigStorage(LiquidityService(liquidityService).configStorage()).weth())
      revert ILiquidityHandler_InvalidSender();
  }

  /**
   * Core Function
   */

  /// @notice Create a new AddLiquidity order
  /// @param _tokenIn address token in
  /// @param _amountIn amount token in (based on decimals)
  /// @param _minOut minPLP out
  /// @param _executionFee The execution fee of order
  /// @param _shouldWrap in case of sending native token
  function createAddLiquidityOrder(
    address _tokenIn,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _executionFee,
    bool _shouldWrap
  ) external payable nonReentrant onlyAcceptedToken(_tokenIn) returns (uint256 _orderId) {
    LiquidityService(liquidityService).validatePreAddRemoveLiquidity(_amountIn);

    //1. convert native to WNative (including executionFee)
    _transferInETH();

    if (_executionFee < executionOrderFee) revert ILiquidityHandler_InsufficientExecutionFee();

    if (_shouldWrap) {
      if (msg.value != _amountIn + executionOrderFee) {
        revert ILiquidityHandler_InCorrectValueTransfer();
      }
    } else {
      if (msg.value != executionOrderFee) revert ILiquidityHandler_InCorrectValueTransfer();
      IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
    }

    _orderId = liquidityOrders.length;
    liquidityOrders.push(
      LiquidityOrder({
        account: payable(msg.sender),
        orderId: _orderId,
        token: _tokenIn,
        amount: _amountIn,
        minOut: _minOut,
        isAdd: true,
        executionFee: _executionFee,
        isNativeOut: _shouldWrap
      })
    );

    emit LogCreateAddLiquidityOrder(msg.sender, _orderId, _tokenIn, _amountIn, _minOut, _executionFee);
    return _orderId;
  }

  /// @notice Create a new RemoveLiquidity order
  /// @param _tokenOut address token in
  /// @param _amountIn amount token in (based on decimals)
  /// @param _minOut minAmountOut
  /// @param _executionFee The execution fee of order
  /// @param _isNativeOut in case of user need native token
  function createRemoveLiquidityOrder(
    address _tokenOut,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _executionFee,
    bool _isNativeOut
  ) external payable nonReentrant onlyAcceptedToken(_tokenOut) returns (uint256 _orderId) {
    LiquidityService(liquidityService).validatePreAddRemoveLiquidity(_amountIn);

    //convert native to WNative (including executionFee)
    _transferInETH();

    if (_executionFee < executionOrderFee) revert ILiquidityHandler_InsufficientExecutionFee();

    if (msg.value != executionOrderFee) revert ILiquidityHandler_InCorrectValueTransfer();

    IERC20(ConfigStorage(LiquidityService(liquidityService).configStorage()).plp()).safeTransferFrom(
      msg.sender,
      address(this),
      _amountIn
    );

    _orderId = liquidityOrders.length;
    liquidityOrders.push(
      LiquidityOrder({
        account: payable(msg.sender),
        orderId: _orderId,
        token: _tokenOut,
        amount: _amountIn,
        minOut: _minOut,
        isAdd: false,
        executionFee: _executionFee,
        isNativeOut: _isNativeOut
      })
    );

    emit LogCreateRemoveLiquidityOrder(
      msg.sender,
      _orderId,
      _tokenOut,
      _amountIn,
      _minOut,
      _executionFee,
      _isNativeOut
    );

    return _orderId;
  }

  /// @notice Cancel order
  /// @param _orderId orderIndex of user order
  function cancelLiquidityOrder(uint256 _orderId) external nonReentrant {
    _cancelLiquidityOrder(msg.sender, _orderId);
  }

  /// @notice Cancel order
  /// @param _account the primary account
  /// @param _orderIndex Order Index which could be retrieved from lastOrderIndex(address) beware in case of index is 0`
  function _cancelLiquidityOrder(address _account, uint256 _orderIndex) internal {
    if (
      _orderIndex < nextExecutionOrderIndex || // orderIndex to execute must >= nextExecutionOrderIndex
      liquidityOrders.length <= _orderIndex // orders length must > orderIndex
    ) {
      revert ILiquidityHandler_NoOrder();
    }

    if (_account != liquidityOrders[_orderIndex].account) {
      revert ILiquidityHandler_NotOrderOwner();
    }

    LiquidityOrder memory order = liquidityOrders[_orderIndex];
    delete liquidityOrders[_orderIndex];
    _refund(order);

    emit LogCancelLiquidityOrder(
      payable(_account),
      order.orderId,
      order.token,
      order.amount,
      order.minOut,
      order.isAdd
    );
  }

  /// @notice refund order
  /// @dev this method has not be called directly
  /// @param _order order to execute
  // slither-disable-next-line
  function _refund(LiquidityOrder memory _order) internal {
    if (_order.amount == 0) {
      revert ILiquidityHandler_NoOrder();
    }

    if (_order.isAdd) {
      if (_order.isNativeOut) {
        _transferOutETH(_order.amount, _order.account);
      } else {
        IERC20(_order.token).safeTransfer(_order.account, _order.amount);
      }
      emit LogRefund(_order.account, _order.orderId, _order.token, _order.amount, _order.isNativeOut);
    } else {
      address _plp = ConfigStorage(LiquidityService(liquidityService).configStorage()).plp();
      IERC20(_plp).safeTransfer(_order.account, _order.amount);
      emit LogRefund(_order.account, _order.orderId, _plp, _order.amount, false);
    }
  }

  /// @notice orderExecutor pending order
  /// @param _feeReceiver ExecutionFee Receiver Address
  /// @param _priceData Price data from Pyth to be used for updating the market prices
  // slither-disable-next-line reentrancy-eth
  function executeOrder(
    uint256 _endIndex,
    address payable _feeReceiver,
    bytes[] memory _priceData
  ) external nonReentrant onlyOrderExecutor {
    uint256 _orderLength = liquidityOrders.length;
    uint256 _latestOrderIndex = _orderLength - 1;
    if (_orderLength == 0 || nextExecutionOrderIndex == _orderLength) {
      revert ILiquidityHandler_NoOrder();
    }

    if (_endIndex > _latestOrderIndex) {
      _endIndex = _latestOrderIndex;
    }

    uint256 _updateFee = IPyth(pyth).getUpdateFee(_priceData);
    IWNative(ConfigStorage(LiquidityService(liquidityService).configStorage()).weth()).withdraw(_updateFee);

    // slither-disable-next-line arbitrary-send-eth
    IPyth(pyth).updatePriceFeeds{ value: _updateFee }(_priceData);
    uint256 _totalFeeReceiver = 0;

    for (uint256 i = nextExecutionOrderIndex; i <= _endIndex; ) {
      LiquidityOrder memory _order = liquidityOrders[i];
      delete liquidityOrders[i];

      // refund in case of order updatePythFee > executionFee
      if (_updateFee > _order.executionFee) {
        _refund(_order);
      } else {
        isExecuting = true;

        try this.executeLiquidity(_order) returns (uint256 actualOut) {
          emit LogExecuteLiquidityOrder(
            _order.account,
            _order.orderId,
            _order.token,
            _order.amount,
            _order.minOut,
            _order.isAdd,
            actualOut
          );
        } catch Error(string memory) {
          //refund in case of revert as message
          _refund(_order);
        } catch (bytes memory) {
          //refund in case of revert as bytes
          _refund(_order);
        }
        isExecuting = false;
      }

      _totalFeeReceiver += _order.executionFee;

      unchecked {
        ++i;
      }
    }

    nextExecutionOrderIndex = _endIndex + 1;
    // Pay the executor
    _transferOutETH(_totalFeeReceiver - _updateFee, _feeReceiver);
  }

  /// @notice execute either addLiquidity or removeLiquidity
  /// @param _order order of executing
  // slither-disable-next-line
  function executeLiquidity(LiquidityOrder memory _order) external returns (uint256) {
    if (isExecuting) {
      if (_order.isAdd) {
        IERC20(_order.token).safeTransfer(LiquidityService(liquidityService).vaultStorage(), _order.amount);
        return
          LiquidityService(liquidityService).addLiquidity(_order.account, _order.token, _order.amount, _order.minOut);
      } else {
        uint256 amountOut = LiquidityService(liquidityService).removeLiquidity(
          _order.account,
          _order.token,
          _order.amount,
          _order.minOut
        );

        if (_order.isNativeOut) {
          _transferOutETH(amountOut, payable(_order.account));
        } else {
          IERC20(_order.token).safeTransfer(_order.account, amountOut);
        }
        return amountOut;
      }
    } else {
      revert ILiquidityHandler_NotExecutionState();
    }
  }

  /// @notice Transfer in ETH from user to be used as execution fee
  /// @dev The received ETH will be wrapped into WETH and store in this contract for later use.
  function _transferInETH() private {
    IWNative(ConfigStorage(LiquidityService(liquidityService).configStorage()).weth()).deposit{ value: msg.value }();
  }

  /// @notice Transfer out ETH to the receiver
  /// @dev The stored WETH will be unwrapped and transfer as native token
  /// @param _amountOut Amount of ETH to be transferred
  /// @param _receiver The receiver of ETH in its native form. The receiver must be able to accept native token.
  function _transferOutETH(uint256 _amountOut, address _receiver) private {
    IWNative(ConfigStorage(LiquidityService(liquidityService).configStorage()).weth()).withdraw(_amountOut);
    // slither-disable-next-line arbitrary-send-eth
    payable(_receiver).transfer(_amountOut);
  }

  /**
   * GETTER
   */

  /// @notice get liquidity order
  function getLiquidityOrders() external view returns (LiquidityOrder[] memory _liquidityOrder) {
    return liquidityOrders;
  }

  /**
   * SETTER
   */

  /// @notice setLiquidityService
  /// @param _newLiquidityService liquidityService address
  function setLiquidityService(address _newLiquidityService) external nonReentrant onlyOwner {
    if (_newLiquidityService == address(0)) revert ILiquidityHandler_InvalidAddress();
    emit LogSetLiquidityService(liquidityService, _newLiquidityService);
    liquidityService = _newLiquidityService;
    LiquidityService(_newLiquidityService).vaultStorage();
  }

  /// @notice setMinExecutionFee
  /// @param _newMinExecutionFee minExecutionFee in ethers
  function setMinExecutionFee(uint256 _newMinExecutionFee) external nonReentrant onlyOwner {
    emit LogSetMinExecutionFee(executionOrderFee, _newMinExecutionFee);
    executionOrderFee = _newMinExecutionFee;
  }

  /// @notice setMinExecutionFee
  /// @param _executor address who will be executor
  /// @param _isAllow flag to allow to execute
  function setOrderExecutor(address _executor, bool _isAllow) external nonReentrant onlyOwner {
    orderExecutors[_executor] = _isAllow;
    emit LogSetOrderExecutor(_executor, _isAllow);
  }

  /// @notice Set new Pyth contract address.
  /// @param _pyth New Pyth contract address.
  function setPyth(address _pyth) external nonReentrant onlyOwner {
    if (_pyth == address(0)) revert ILiquidityHandler_InvalidAddress();
    emit LogSetPyth(pyth, _pyth);
    pyth = _pyth;

    // Sanity check
    IPyth(_pyth).getUpdateFee(new bytes[](0));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILiquidityHandler {
  /**
   * Errors
   */
  error ILiquidityHandler_InvalidSender();
  error ILiquidityHandler_InsufficientExecutionFee();
  error ILiquidityHandler_InCorrectValueTransfer();
  error ILiquidityHandler_InsufficientRefund();
  error ILiquidityHandler_NotWhitelisted();
  error ILiquidityHandler_InvalidAddress();
  error ILiquidityHandler_NotExecutionState();
  error ILiquidityHandler_NoOrder();
  error ILiquidityHandler_NotOrderOwner();

  /**
   * Struct
   */
  struct LiquidityOrder {
    address payable account;
    uint256 orderId;
    address token;
    uint256 amount;
    uint256 minOut;
    bool isAdd;
    uint256 executionFee;
    bool isNativeOut; // token Out for remove liquidity(!unwrap) and refund addLiquidity (shoulWrap) flag
  }

  /**
   * Core functions
   */
  function createAddLiquidityOrder(
    address _tokenBuy,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _executionFee,
    bool _shouldUnwrap
  ) external payable returns (uint256);

  function createRemoveLiquidityOrder(
    address _tokenSell,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _executionFee,
    bool _shouldUnwrap
  ) external payable returns (uint256);

  function executeOrder(uint256 endIndex, address payable feeReceiver, bytes[] memory _priceData) external;

  function cancelLiquidityOrder(uint256 _orderIndex) external;

  function getLiquidityOrders() external view returns (LiquidityOrder[] memory);

  function nextExecutionOrderIndex() external view returns (uint256);

  function setOrderExecutor(address _executor, bool _isOk) external;

  function executeLiquidity(LiquidityOrder memory _order) external returns (uint256);

  function executionOrderFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IWNative {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function mint(address to, uint256 value) external;

  function balanceOf(address wallet) external returns (uint256);
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

// base
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contracts
import { ConfigStorage } from "@hmx/storages/ConfigStorage.sol";
import { VaultStorage } from "@hmx/storages/VaultStorage.sol";
import { PerpStorage } from "@hmx/storages/PerpStorage.sol";
import { Calculator } from "@hmx/contracts/Calculator.sol";
import { PLPv2 } from "@hmx/contracts/PLPv2.sol";
import { OracleMiddleware } from "@hmx/oracle/OracleMiddleware.sol";

// interfaces
import { ILiquidityService } from "./interfaces/ILiquidityService.sol";

contract LiquidityService is ReentrancyGuard, ILiquidityService {
  address public configStorage;
  address public vaultStorage;
  address public perpStorage;

  uint256 internal constant PRICE_PRECISION = 10 ** 30;
  uint32 internal constant BPS = 1e4;
  uint8 internal constant USD_DECIMALS = 30;

  event AddLiquidity(
    address account,
    address token,
    uint256 amount,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 mintAmount
  );
  event RemoveLiquidity(
    address account,
    address tokenOut,
    uint256 liquidity,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 amountOut
  );

  event CollectSwapFee(address user, address token, uint256 feeUsd, uint256 fee);
  event CollectAddLiquidityFee(address user, address token, uint256 feeUsd, uint256 fee);
  event CollectRemoveLiquidityFee(address user, address token, uint256 feeUsd, uint256 fee);

  constructor(address _perpStorage, address _vaultStorage, address _configStorage) {
    perpStorage = _perpStorage;
    vaultStorage = _vaultStorage;
    configStorage = _configStorage;

    // Sanity Check
    PerpStorage(_perpStorage).getGlobalState();
    ConfigStorage(_configStorage).calculator();
    VaultStorage(_vaultStorage).devFees(address(0));
  }

  /**
   * MODIFIER
   */

  modifier onlyWhitelistedExecutor() {
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    _;
  }

  modifier onlyAcceptedToken(address _token) {
    ConfigStorage(configStorage).validateAcceptedLiquidityToken(_token);
    _;
  }

  function addLiquidity(
    address _lpProvider,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external nonReentrant onlyWhitelistedExecutor onlyAcceptedToken(_token) returns (uint256) {
    // 1. _validate
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    validatePreAddRemoveLiquidity(_amount);

    if (VaultStorage(vaultStorage).pullToken(_token) != _amount) {
      revert LiquidityService_InvalidInputAmount();
    }

    Calculator _calculator = Calculator(ConfigStorage(configStorage).calculator());

    // 2. getMinPrice for using to join Pool
    (uint256 _price, ) = OracleMiddleware(_calculator.oracle()).getLatestPrice(
      ConfigStorage(configStorage).tokenAssetIds(_token),
      false
    );

    // 3. get aum and lpSupply before deduction fee
    uint256 _aumE30 = _calculator.getAUME30(true);
    uint256 _lpSupply = ERC20(ConfigStorage(configStorage).plp()).totalSupply();

    (uint256 _tokenValueUSDAfterFee, uint256 _mintAmount) = _joinPool(
      _token,
      _amount,
      _price,
      _lpProvider,
      _minAmount,
      _aumE30,
      _lpSupply
    );

    //7 Transfer Token from LiquidityHandler to VaultStorage and Mint PLP to user
    PLPv2(ConfigStorage(configStorage).plp()).mint(_lpProvider, _mintAmount);

    emit AddLiquidity(_lpProvider, _token, _amount, _aumE30, _lpSupply, _tokenValueUSDAfterFee, _mintAmount);
    return _mintAmount;
  }

  function removeLiquidity(
    address _lpProvider,
    address _tokenOut,
    uint256 _amount,
    uint256 _minAmount
  ) external nonReentrant onlyWhitelistedExecutor onlyAcceptedToken(_tokenOut) returns (uint256) {
    // 1. _validate
    ConfigStorage(configStorage).validateServiceExecutor(address(this), msg.sender);
    validatePreAddRemoveLiquidity(_amount);

    Calculator _calculator = Calculator(ConfigStorage(configStorage).calculator());
    uint256 _aumE30 = _calculator.getAUME30(false);
    uint256 _lpSupply = ERC20(ConfigStorage(configStorage).plp()).totalSupply();

    // lp value to remove
    uint256 _lpUsdValueE30 = _lpSupply != 0 ? (_amount * _aumE30) / _lpSupply : 0;
    uint256 _amountOut = _exitPool(_tokenOut, _lpUsdValueE30, _lpProvider, _minAmount);

    // handler receive PLP of user then burn it from handler
    PLPv2(ConfigStorage(configStorage).plp()).burn(msg.sender, _amount);

    VaultStorage(vaultStorage).pushToken(_tokenOut, msg.sender, _amountOut);

    _validatePLPHealthCheck(_tokenOut);

    emit RemoveLiquidity(_lpProvider, _tokenOut, _amount, _aumE30, _lpSupply, _lpUsdValueE30, _amountOut);

    return _amountOut;
  }

  function _joinPool(
    address _token,
    uint256 _amount,
    uint256 _price,
    address _lpProvider,
    uint256 _minAmount,
    uint256 _aumE30,
    uint256 _lpSupply
  ) internal returns (uint256 _tokenValueUSDAfterFee, uint256 mintAmount) {
    Calculator _calculator = Calculator(ConfigStorage(configStorage).calculator());

    uint32 _feeBps = _getAddLiquidityFeeBPS(_token, _amount, _price);
    uint256 amountAfterFee = _collectFee(_token, _lpProvider, _price, _amount, _feeBps, LiquidityAction.ADD_LIQUIDITY);

    // 4. Calculate mintAmount
    _tokenValueUSDAfterFee = _calculator.convertTokenDecimals(
      ConfigStorage(configStorage).getAssetTokenDecimal(_token),
      USD_DECIMALS,
      (amountAfterFee * _price) / PRICE_PRECISION
    );

    mintAmount = _calculator.getMintAmount(_aumE30, _lpSupply, _tokenValueUSDAfterFee);

    // 5. Check slippage: revert on error
    if (mintAmount < _minAmount) revert LiquidityService_InsufficientLiquidityMint();

    //6 accounting PLP (plpLiquidityUSD,total, plpLiquidity)
    VaultStorage(vaultStorage).addPLPLiquidity(_token, amountAfterFee);

    return (_tokenValueUSDAfterFee, mintAmount);
  }

  function _exitPool(
    address _tokenOut,
    uint256 _lpUsdValueE30,
    address _lpProvider,
    uint256 _minAmount
  ) internal returns (uint256) {
    Calculator _calculator = Calculator(ConfigStorage(configStorage).calculator());
    (uint256 _maxPrice, ) = OracleMiddleware(_calculator.oracle()).getLatestPrice(
      ConfigStorage(configStorage).tokenAssetIds(_tokenOut),
      false
    );

    uint256 _amountOut = _calculator.convertTokenDecimals(
      30,
      ConfigStorage(configStorage).getAssetTokenDecimal(_tokenOut),
      (_lpUsdValueE30 * PRICE_PRECISION) / _maxPrice
    );

    if (_amountOut == 0) revert LiquidityService_BadAmountOut();

    uint32 _feeBps = Calculator(ConfigStorage(configStorage).calculator()).getRemoveLiquidityFeeBPS(
      _tokenOut,
      _lpUsdValueE30,
      ConfigStorage(configStorage)
    );

    VaultStorage(vaultStorage).removePLPLiquidity(_tokenOut, _amountOut);

    _amountOut = _collectFee(_tokenOut, _lpProvider, _maxPrice, _amountOut, _feeBps, LiquidityAction.REMOVE_LIQUIDITY);

    if (_minAmount > _amountOut) {
      revert LiquidityService_Slippage();
    }

    return _amountOut;
  }

  function _getAddLiquidityFeeBPS(address _token, uint256 _amount, uint256 _price) internal view returns (uint32) {
    uint256 tokenUSDValueE30 = Calculator(ConfigStorage(configStorage).calculator()).convertTokenDecimals(
      ConfigStorage(configStorage).getAssetTokenDecimal(_token),
      USD_DECIMALS,
      (_amount * _price) / PRICE_PRECISION // tokenValueInDecimal = amount * priceE30 / 1e30
    );

    if (tokenUSDValueE30 == 0) {
      revert LiquidityService_InsufficientLiquidityMint();
    }

    uint32 _feeBps = Calculator(ConfigStorage(configStorage).calculator()).getAddLiquidityFeeBPS(
      _token,
      tokenUSDValueE30,
      ConfigStorage(configStorage)
    );

    return _feeBps;
  }

  // calculate fee and accounting fee
  function _collectFee(
    address _token,
    address _account,
    uint256 _tokenPriceUsd,
    uint256 _amount,
    uint32 _feeBPS,
    LiquidityAction _action
  ) internal returns (uint256 _amountAfterFee) {
    uint256 _fee = (_amount * _feeBPS) / BPS;

    VaultStorage(vaultStorage).addFee(_token, _fee);
    uint256 _decimals = ConfigStorage(configStorage).getAssetTokenDecimal(_token);

    if (_action == LiquidityAction.SWAP) {
      emit CollectSwapFee(_account, _token, (_fee * _tokenPriceUsd) / 10 ** _decimals, _fee);
    } else if (_action == LiquidityAction.ADD_LIQUIDITY) {
      emit CollectAddLiquidityFee(_account, _token, (_fee * _tokenPriceUsd) / 10 ** _decimals, _fee);
    } else if (_action == LiquidityAction.REMOVE_LIQUIDITY) {
      emit CollectRemoveLiquidityFee(_account, _token, (_fee * _tokenPriceUsd) / 10 ** _decimals, _fee);
    }
    return _amount - _fee;
  }

  function _validatePLPHealthCheck(address _token) internal view {
    // liquidityLeft < bufferLiquidity
    if (
      VaultStorage(vaultStorage).plpLiquidity(_token) <
      ConfigStorage(configStorage).getAssetPlpTokenConfigByToken(_token).bufferLiquidity
    ) {
      revert LiquidityService_InsufficientLiquidityBuffer();
    }

    ConfigStorage.LiquidityConfig memory _liquidityConfig = ConfigStorage(configStorage).getLiquidityConfig();
    PerpStorage.GlobalState memory _globalState = PerpStorage(perpStorage).getGlobalState();
    Calculator _calculator = Calculator(ConfigStorage(configStorage).calculator());

    // Validate Max PLP Utilization
    // =====================================
    // reserveValue / PLP TVL > maxPLPUtilization
    // Transform to save precision:
    // reserveValue > maxPLPUtilization * PLPTVL
    uint256 plpTVL = _calculator.getPLPValueE30(false);

    if (_globalState.reserveValueE30 * BPS > _liquidityConfig.maxPLPUtilizationBPS * plpTVL) {
      revert LiquidityService_MaxPLPUtilizationExceeded();
    }

    // Validate PLP Reserved
    if (_globalState.reserveValueE30 > plpTVL) {
      revert LiquidityService_InsufficientPLPReserved();
    }
  }

  /// @notice validatePreAddRemoveLiquidity used in Handler,Service
  /// @param _amount amountIn
  function validatePreAddRemoveLiquidity(uint256 _amount) public view {
    if (!ConfigStorage(configStorage).getLiquidityConfig().enabled) {
      revert LiquidityService_CircuitBreaker();
    }

    if (_amount == 0) {
      revert LiquidityService_BadAmount();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILiquidityService {
  /**
   * Errors
   */
  error LiquidityService_CircuitBreaker();
  error LiquidityService_InvalidToken();
  error LiquidityService_InvalidInputAmount();
  error LiquidityService_InsufficientLiquidityMint();
  error LiquidityService_BadAmount();
  error LiquidityService_BadAmountOut();
  error LiquidityService_Slippage();

  error LiquidityService_InsufficientLiquidityBuffer();
  error LiquidityService_MaxPLPUtilizationExceeded();
  error LiquidityService_InsufficientPLPReserved();

  /**
   * Enum
   */
  enum LiquidityAction {
    SWAP,
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
  }

  /**
   * Functions
   */
  function addLiquidity(
    address _lpProvider,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external returns (uint256);

  function removeLiquidity(
    address _lpProvider,
    address _tokenOut,
    uint256 _amount,
    uint256 _minAmount
  ) external returns (uint256);

  function configStorage() external returns (address);

  function vaultStorage() external returns (address);

  function perpStorage() external returns (address);
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