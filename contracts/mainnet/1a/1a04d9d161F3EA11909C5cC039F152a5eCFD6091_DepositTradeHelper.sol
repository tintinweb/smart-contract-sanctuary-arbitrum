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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "./IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Stripped version of `@balancer-labs/v2-interfaces/contracts/vault/IVault.sol`
 * that only exposes the necessary vault methods for DepositTradeHelper.
 */
interface IVault {
  /**
   * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
   * the tokens' `balances` changed.
   *
   * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
   * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
   *
   * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
   * order as passed to `registerTokens`.
   *
   * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
   * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
   * instead.
   */
  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );

  // Swaps
  //
  // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
  // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
  // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
  //
  // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
  // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
  // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
  // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
  // individual swaps.
  //
  // There are two swap kinds:
  //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
  // `onSwap` hook) the amount of tokens out (to send to the recipient).
  //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
  // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
  //
  // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
  // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
  // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
  // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
  // the final intended token.
  //
  // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
  // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
  // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
  // much less gas than they would otherwise.
  //
  // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
  // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
  // updating the Pool's internal accounting).
  //
  // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
  // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
  // minimum amount of tokens to receive (by passing a negative value) is specified.
  //
  // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
  // this point in time (e.g. if the transaction failed to be included in a block promptly).
  //
  // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
  // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
  // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
  // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
  //
  // Finally, Internal Balance can be used when either sending or receiving tokens.

  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  /**
   * @dev Performs a swap with a single Pool.
   *
   * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
   * taken from the Pool, which must be greater than or equal to `limit`.
   *
   * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
   * sent to the Pool, which must be less than or equal to `limit`.
   *
   * Internal Balance usage and the recipient are determined by the `funds` struct.
   *
   * Emits a `Swap` event.
   */
  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
   * the `kind` value.
   *
   * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
   * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
   *
   * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
   * used to extend swap behavior.
   */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
   * `assets` array passed to that function, and ETH assets are converted to WETH.
   *
   * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
   * from the previous swap, depending on the swap kind.
   *
   * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
   * used to extend swap behavior.
   */
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
   * `recipient` account.
   *
   * If the caller is not `sender`, it must be an authorized relayer for them.
   *
   * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
   * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
   * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
   * `joinPool`.
   *
   * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
   * transferred. This matches the behavior of `exitPool`.
   *
   * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
   * revert.
   */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
   * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
   *
   * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
   * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
   * receives are the same that an equivalent `batchSwap` call would receive.
   *
   * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
   * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
   * approve them for the Vault, or even know a user's address.
   *
   * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
   * eth_call instead of eth_sendTransaction.
   */
  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds
  ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IAsset, ICollateral, IDepositTradeHelper, IERC20, ISwapRouter, IVault} from "./interfaces/IDepositTradeHelper.sol";
import {SafeOwnable} from "prepo-shared-contracts/contracts/SafeOwnable.sol";
import {ITokenSender, TokenSenderCaller} from "prepo-shared-contracts/contracts/TokenSenderCaller.sol";
import {TreasuryCaller} from "prepo-shared-contracts/contracts/TreasuryCaller.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract DepositTradeHelper is
  IDepositTradeHelper,
  ReentrancyGuard,
  SafeOwnable,
  TokenSenderCaller,
  TreasuryCaller
{
  ICollateral private immutable _collateral;
  IERC20 private immutable _baseToken;
  ISwapRouter private immutable _swapRouter;
  IVault private immutable _wstethVault;

  bytes32 private _wstethPoolId;
  uint256 private _tradeFeePercent;

  uint24 public constant override POOL_FEE_TIER = 10000;

  constructor(
    ICollateral collateral,
    ISwapRouter swapRouter,
    IVault wstethVault
  ) {
    _collateral = collateral;
    _baseToken = collateral.getBaseToken();
    _swapRouter = swapRouter;
    _wstethVault = wstethVault;
    collateral.getBaseToken().approve(address(collateral), type(uint256).max);
    collateral.getBaseToken().approve(address(wstethVault), type(uint256).max);
    collateral.approve(address(swapRouter), type(uint256).max);
  }

  /// @dev Assumes `_baseToken` is WstETH
  function wrapAndDeposit(
    address recipient,
    bytes calldata depositData,
    OffChainBalancerParams calldata balancerParams
  ) external payable override nonReentrant {
    _wrapAndDeposit(recipient, depositData, balancerParams);
  }

  function wrapAndDeposit(
    address recipient,
    OffChainBalancerParams calldata balancerParams
  ) external payable override nonReentrant {
    _wrapAndDeposit(recipient, balancerParams);
  }

  function tradeForPosition(
    address recipient,
    uint256 collateralAmount,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external override nonReentrant {
    _permitAndTransfer(
      msg.sender,
      address(_collateral),
      collateralAmount,
      collateralPermit
    );
    uint256 collateralAmountAfterFee = _sendCollateralFeeAndRebate(
      recipient,
      collateralAmount
    );
    _trade(
      recipient,
      address(_collateral),
      tradeParams.positionToken,
      collateralAmountAfterFee,
      tradeParams
    );
  }

  function tradeForCollateral(
    address recipient,
    uint256 positionAmount,
    Permit calldata positionPermit,
    OffChainTradeParams calldata tradeParams
  ) external override nonReentrant {
    _permitAndTransfer(
      msg.sender,
      tradeParams.positionToken,
      positionAmount,
      positionPermit
    );
    /**
     * Since any position token could be passed in, it is simpler to just
     * perform a one-time approval on the first trade of a Long or Short
     * token. This removes the need to "register" Long or Short tokens
     * every time we need the contract to support one.
     */
    if (
      IERC20(tradeParams.positionToken).allowance(
        address(this),
        address(_swapRouter)
      ) != type(uint256).max
    ) {
      IERC20(tradeParams.positionToken).approve(
        address(_swapRouter),
        type(uint256).max
      );
    }
    // trade recipient is this contract so fee can be captured
    uint256 collateralAmountBeforeFee = _trade(
      address(this),
      tradeParams.positionToken,
      address(_collateral),
      positionAmount,
      tradeParams
    );
    uint256 collateralAmountAfterFee = _sendCollateralFeeAndRebate(
      recipient,
      collateralAmountBeforeFee
    );
    _collateral.transfer(recipient, collateralAmountAfterFee);
  }

  function wrapAndDepositAndTrade(
    address recipient,
    bytes calldata depositData,
    OffChainBalancerParams calldata balancerParams,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external payable override nonReentrant {
    uint256 collateralAmountBeforeFee = _wrapAndDeposit(
      recipient,
      depositData,
      balancerParams
    );
    /**
     * funder = recipient in this case since minted collateral is attributed
     * to the recipient. Since this function will only be used for collateral
     * => position trading, can assume collateral will be the input token and
     * position token as the output.
     */
    _permitAndTransfer(
      recipient,
      address(_collateral),
      collateralAmountBeforeFee,
      collateralPermit
    );
    uint256 collateralAmountAfterFee = _sendCollateralFeeAndRebate(
      recipient,
      collateralAmountBeforeFee
    );
    _trade(
      recipient,
      address(_collateral),
      tradeParams.positionToken,
      collateralAmountAfterFee,
      tradeParams
    );
  }

  function wrapAndDepositAndTrade(
    address recipient,
    OffChainBalancerParams calldata balancerParams,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external payable override nonReentrant {
    uint256 collateralAmountBeforeFee = _wrapAndDeposit(
      recipient,
      balancerParams
    );
    /**
     * funder = recipient in this case since minted collateral is attributed
     * to the recipient. Since this function will only be used for collateral
     * => position trading, can assume collateral will be the input token and
     * position token as the output.
     */
    _permitAndTransfer(
      recipient,
      address(_collateral),
      collateralAmountBeforeFee,
      collateralPermit
    );
    uint256 collateralAmountAfterFee = _sendCollateralFeeAndRebate(
      recipient,
      collateralAmountBeforeFee
    );
    _trade(
      recipient,
      address(_collateral),
      tradeParams.positionToken,
      collateralAmountAfterFee,
      tradeParams
    );
  }

  function withdrawAndUnwrap(
    address recipient,
    uint256 amount,
    bytes calldata withdrawData,
    Permit calldata collateralPermit,
    OffChainBalancerParams calldata balancerParams
  ) external override nonReentrant {
    uint256 recipientETHBefore = recipient.balance;
    _permitAndTransfer(
      msg.sender,
      address(_collateral),
      amount,
      collateralPermit
    );
    uint256 wstethAmount = _collateral.withdraw(
      address(this),
      amount,
      withdrawData
    );
    IERC20 rewardToken = _tokenSender.getOutputToken();
    uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
    if (rewardTokenBalance > 0)
      rewardToken.transfer(recipient, rewardTokenBalance);
    IVault.SingleSwap memory wstethSwapParams = IVault.SingleSwap(
      _wstethPoolId,
      IVault.SwapKind.GIVEN_IN,
      IAsset(address(_baseToken)),
      // output token as zero address means ETH
      IAsset(address(0)),
      wstethAmount,
      ""
    );
    IVault.FundManagement memory wstethFundingParams = IVault.FundManagement(
      address(this),
      false,
      // Unwraps WETH into ETH directly to recipient
      payable(recipient),
      false
    );
    _wstethVault.swap(
      wstethSwapParams,
      wstethFundingParams,
      balancerParams.amountOutMinimum,
      balancerParams.deadline
    );
    require(
      recipient.balance - recipientETHBefore >=
        balancerParams.amountOutMinimum,
      "Insufficient ETH from swap"
    );
  }

  function withdrawAndUnwrap(
    address recipient,
    uint256 amount,
    Permit calldata collateralPermit,
    OffChainBalancerParams calldata balancerParams
  ) external override nonReentrant {
    uint256 recipientETHBefore = recipient.balance;
    _permitAndTransfer(
      msg.sender,
      address(_collateral),
      amount,
      collateralPermit
    );
    uint256 wstethAmount = _collateral.withdraw(address(this), amount);
    IERC20 rewardToken = _tokenSender.getOutputToken();
    uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
    if (rewardTokenBalance > 0)
      rewardToken.transfer(recipient, rewardTokenBalance);
    IVault.SingleSwap memory wstethSwapParams = IVault.SingleSwap(
      _wstethPoolId,
      IVault.SwapKind.GIVEN_IN,
      IAsset(address(_baseToken)),
      // output token as zero address means ETH
      IAsset(address(0)),
      wstethAmount,
      ""
    );
    IVault.FundManagement memory wstethFundingParams = IVault.FundManagement(
      address(this),
      false,
      // Unwraps WETH into ETH directly to recipient
      payable(recipient),
      false
    );
    _wstethVault.swap(
      wstethSwapParams,
      wstethFundingParams,
      balancerParams.amountOutMinimum,
      balancerParams.deadline
    );
    require(
      recipient.balance - recipientETHBefore >=
        balancerParams.amountOutMinimum,
      "Insufficient ETH from swap"
    );
  }

  function setWstethPoolId(bytes32 wstethPoolId) external override onlyOwner {
    _wstethPoolId = wstethPoolId;
    emit WstethPoolIdChange(wstethPoolId);
  }

  function setTradeFeePercent(uint256 tradeFeePercent)
    external
    override
    onlyOwner
  {
    _tradeFeePercent = tradeFeePercent;
    emit TradeFeePercentChange(tradeFeePercent);
  }

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    public
    override
    onlyOwner
  {
    /**
     * Zero address is used here to represent that this multiplier will be
     * applied to all accounts.
     */
    if (account != address(0)) revert InvalidAccount();
    super.setAmountMultiplier(account, amountMultiplier);
  }

  function setTokenSender(ITokenSender tokenSender) public override onlyOwner {
    super.setTokenSender(tokenSender);
  }

  function setTreasury(address treasury) public override onlyOwner {
    super.setTreasury(treasury);
  }

  function getCollateral() external view override returns (ICollateral) {
    return _collateral;
  }

  function getBaseToken() external view override returns (IERC20) {
    return _baseToken;
  }

  function getSwapRouter() external view override returns (ISwapRouter) {
    return _swapRouter;
  }

  function getWstethVault() external view override returns (IVault) {
    return _wstethVault;
  }

  function getWstethPoolId() external view override returns (bytes32) {
    return _wstethPoolId;
  }

  function getTradeFeePercent() external view override returns (uint256) {
    return _tradeFeePercent;
  }

  function _wrapAndDeposit(
    address recipient,
    bytes memory depositData,
    OffChainBalancerParams calldata balancerParams
  ) internal returns (uint256) {
    uint256 wstethBalanceBefore = _baseToken.balanceOf(address(this));
    IVault.SingleSwap memory wstethSwapParams = IVault.SingleSwap(
      _wstethPoolId,
      IVault.SwapKind.GIVEN_IN,
      // input token as zero address means ETH
      IAsset(address(0)),
      IAsset(address(_baseToken)),
      msg.value,
      // keep optional `userData` field empty
      ""
    );
    IVault.FundManagement memory wstethFundingParams = IVault.FundManagement(
      address(this),
      // false because we are not trading with internal pool balances
      false,
      /**
       * Although the contract is not receiving ETH in this swap, the
       * parameter is payable because Balancer allows recipients to receive
       * ETH.
       */
      payable(address(this)),
      false
    );
    uint256 wstethAmount = _wstethVault.swap{value: msg.value}(
      wstethSwapParams,
      wstethFundingParams,
      balancerParams.amountOutMinimum,
      balancerParams.deadline
    );
    require(
      _baseToken.balanceOf(address(this)) - wstethBalanceBefore >=
        balancerParams.amountOutMinimum,
      "Insufficient wstETH from swap"
    );
    return _collateral.deposit(recipient, wstethAmount, depositData);
  }

  function _wrapAndDeposit(
    address recipient,
    OffChainBalancerParams calldata balancerParams
  ) internal returns (uint256) {
    uint256 wstethBalanceBefore = _baseToken.balanceOf(address(this));
    IVault.SingleSwap memory wstethSwapParams = IVault.SingleSwap(
      _wstethPoolId,
      IVault.SwapKind.GIVEN_IN,
      // input token as zero address means ETH
      IAsset(address(0)),
      IAsset(address(_baseToken)),
      msg.value,
      // keep optional `userData` field empty
      ""
    );
    IVault.FundManagement memory wstethFundingParams = IVault.FundManagement(
      address(this),
      // false because we are not trading with internal pool balances
      false,
      /**
       * Although the contract is not receiving ETH in this swap, the
       * parameter is payable because Balancer allows recipients to receive
       * ETH.
       */
      payable(address(this)),
      false
    );
    uint256 wstethAmount = _wstethVault.swap{value: msg.value}(
      wstethSwapParams,
      wstethFundingParams,
      balancerParams.amountOutMinimum,
      balancerParams.deadline
    );
    require(
      _baseToken.balanceOf(address(this)) - wstethBalanceBefore >=
        balancerParams.amountOutMinimum,
      "Insufficient wstETH from swap"
    );
    return _collateral.deposit(recipient, wstethAmount);
  }

  function _permitAndTransfer(
    address funder,
    address token,
    uint256 amount,
    Permit calldata permit
  ) internal {
    /**
     * Because `IERC20Permit` and `IERC20` do not overlap, it is cleaner to
     * pass it in as an address and recast it separately when we need to
     * access its functions.
     */
    if (permit.deadline != 0) {
      IERC20Permit(token).permit(
        funder,
        address(this),
        type(uint256).max,
        permit.deadline,
        permit.v,
        permit.r,
        permit.s
      );
    }
    IERC20(token).transferFrom(funder, address(this), amount);
  }

  function _sendCollateralFeeAndRebate(
    address recipient,
    uint256 amountBeforeFee
  ) internal returns (uint256 amountAfterFee) {
    uint256 fee = (amountBeforeFee * _tradeFeePercent) / PERCENT_UNIT;
    amountAfterFee = amountBeforeFee - fee;
    if (fee == 0) return amountAfterFee;
    _collateral.transfer(_treasury, fee);
    if (address(_tokenSender) == address(0)) return amountAfterFee;
    uint256 scaledFee = (fee * _accountToAmountMultiplier[address(0)]) /
      PERCENT_UNIT;
    if (scaledFee == 0) return amountAfterFee;
    _tokenSender.send(recipient, scaledFee);
  }

  function _trade(
    address recipient,
    address inputToken,
    address outputToken,
    uint256 inputTokenAmount,
    OffChainTradeParams calldata tradeParams
  ) internal returns (uint256 outputTokenAmount) {
    ISwapRouter.ExactInputSingleParams memory exactInputSingleParams = ISwapRouter
      .ExactInputSingleParams(
        inputToken,
        /**
         * Don't use tradeParams.positionToken because calling function might
         * have position token as the input rather than the output.
         */
        outputToken,
        POOL_FEE_TIER,
        recipient,
        tradeParams.deadline,
        inputTokenAmount,
        tradeParams.amountOutMinimum,
        tradeParams.sqrtPriceLimitX96
      );
    outputTokenAmount = _swapRouter.exactInputSingle(exactInputSingleParams);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IHook} from "./IHook.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface ICollateral is IERC20Upgradeable, IERC20PermitUpgradeable {
  event Deposit(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event DepositFeePercentChange(uint256 percent);
  event DepositHookChange(address hook);
  event Withdraw(
    address indexed funder,
    address indexed recipient,
    uint256 amountAfterFee,
    uint256 fee
  );
  event WithdrawFeePercentChange(uint256 percent);
  event WithdrawHookChange(address hook);

  function deposit(
    address recipient,
    uint256 baseTokenAmount,
    bytes calldata data
  ) external returns (uint256 collateralMintAmount);

  function deposit(address recipient, uint256 baseTokenAmount)
    external
    returns (uint256 collateralMintAmount);

  function withdraw(
    address recipient,
    uint256 collateralAmount,
    bytes calldata data
  ) external returns (uint256 baseTokenAmountAfterFee);

  function withdraw(address recipient, uint256 collateralAmount)
    external
    returns (uint256 baseTokenAmountAfterFee);

  function setDepositFeePercent(uint256 depositFeePercent) external;

  function setWithdrawFeePercent(uint256 withdrawFeePercent) external;

  function setDepositHook(IHook hook) external;

  function setWithdrawHook(IHook hook) external;

  function getBaseToken() external view returns (IERC20);

  function getDepositFeePercent() external view returns (uint256);

  function getWithdrawFeePercent() external view returns (uint256);

  function getDepositHook() external view returns (IHook);

  function getWithdrawHook() external view returns (IHook);

  function getBaseTokenBalance() external view returns (uint256);

  function PERCENT_UNIT() external view returns (uint256);

  function FEE_LIMIT() external view returns (uint256);

  function SET_DEPOSIT_FEE_PERCENT_ROLE() external view returns (bytes32);

  function SET_WITHDRAW_FEE_PERCENT_ROLE() external view returns (bytes32);

  function SET_DEPOSIT_HOOK_ROLE() external view returns (bytes32);

  function SET_WITHDRAW_HOOK_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ICollateral, IERC20} from "./ICollateral.sol";
import {IAsset, IVault} from "../balancer/IVault.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IDepositTradeHelper {
  struct Permit {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct OffChainBalancerParams {
    uint256 amountOutMinimum;
    uint256 deadline;
  }

  struct OffChainTradeParams {
    address positionToken;
    uint256 deadline;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  event TradeFeePercentChange(uint256 percent);
  event WstethPoolIdChange(bytes32 wstethPoolId);

  function wrapAndDeposit(
    address recipient,
    bytes calldata depositData,
    OffChainBalancerParams calldata balancerParams
  ) external payable;

  function wrapAndDeposit(
    address recipient,
    OffChainBalancerParams calldata balancerParams
  ) external payable;

  function tradeForPosition(
    address recipient,
    uint256 collateralAmount,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external;

  function tradeForCollateral(
    address recipient,
    uint256 positionAmount,
    Permit calldata positionPermit,
    OffChainTradeParams calldata tradeParams
  ) external;

  function wrapAndDepositAndTrade(
    address recipient,
    bytes calldata depositData,
    OffChainBalancerParams calldata balancerParams,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external payable;

  function wrapAndDepositAndTrade(
    address recipient,
    OffChainBalancerParams calldata balancerParams,
    Permit calldata collateralPermit,
    OffChainTradeParams calldata tradeParams
  ) external payable;

  function withdrawAndUnwrap(
    address recipient,
    uint256 amount,
    bytes calldata withdrawData,
    Permit calldata collateralPermit,
    OffChainBalancerParams calldata balancerParams
  ) external;

  function withdrawAndUnwrap(
    address recipient,
    uint256 amount,
    Permit calldata collateralPermit,
    OffChainBalancerParams calldata balancerParams
  ) external;

  function setWstethPoolId(bytes32 wstethPoolId) external;

  function setTradeFeePercent(uint256 tradeFeePercent) external;

  function getBaseToken() external view returns (IERC20);

  function getCollateral() external view returns (ICollateral);

  function getSwapRouter() external view returns (ISwapRouter);

  function getWstethVault() external view returns (IVault);

  function getWstethPoolId() external view returns (bytes32);

  function getTradeFeePercent() external view returns (uint256);

  function POOL_FEE_TIER() external view returns (uint24);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IHook {
  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee,
    bytes calldata data
  ) external;

  function hook(
    address funder,
    address recipient,
    uint256 amountBeforeFee,
    uint256 amountAfterFee
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice An extension of OpenZeppelin's `Ownable.sol` contract that requires
 * an address to be nominated, and then accept that nomination, before
 * ownership is transferred.
 */
interface ISafeOwnable {
  /**
   * @dev Emitted via `transferOwnership()`.
   * @param previousNominee The previous nominee
   * @param newNominee The new nominee
   */
  event NomineeUpdate(
    address indexed previousNominee,
    address indexed newNominee
  );

  /**
   * @notice Nominates an address to be owner of the contract.
   * @dev Only callable by `owner()`.
   * @param nominee The address that will be nominated
   */
  function transferOwnership(address nominee) external;

  /**
   * @notice Renounces ownership of contract and leaves the contract
   * without any owner.
   * @dev Only callable by `owner()`.
   * Sets nominee back to zero address.
   * It will not be possible to call `onlyOwner` functions anymore.
   */
  function renounceOwnership() external;

  /**
   * @notice Accepts ownership nomination.
   * @dev Only callable by the current nominee. Sets nominee back to zero
   * address.
   */
  function acceptOwnership() external;

  /// @return The current nominee
  function getNominee() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IUintValue} from "./IUintValue.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenSender {
  event PriceLowerBoundChange(uint256 price);
  event PriceOracleChange(IUintValue oracle);

  function send(address recipient, uint256 inputAmount) external;

  function setPriceOracle(IUintValue priceOracle) external;

  function setPriceLowerBound(uint256 priceLowerBound) external;

  function getOutputToken() external view returns (IERC20);

  function getPriceOracle() external view returns (IUintValue);

  function getPriceLowerBound() external view returns (uint256);

  function SET_PRICE_ORACLE_ROLE() external view returns (bytes32);

  function SET_PRICE_LOWER_BOUND_ROLE() external view returns (bytes32);

  function SET_ALLOWED_MSG_SENDERS_ROLE() external view returns (bytes32);

  function SET_ACCOUNT_LIMIT_RESET_PERIOD_ROLE()
    external
    view
    returns (bytes32);

  function SET_ACCOUNT_LIMIT_PER_PERIOD_ROLE() external view returns (bytes32);

  function WITHDRAW_ERC20_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITokenSender} from "./ITokenSender.sol";

interface ITokenSenderCaller {
  event AmountMultiplierChange(address account, uint256 multiplier);
  event TokenSenderChange(address sender);

  error InvalidAccount();

  function setTokenSender(ITokenSender tokenSender) external;

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    external;

  function getTokenSender() external view returns (ITokenSender);

  function getAmountMultiplier(address account)
    external
    view
    returns (uint256);

  function PERCENT_UNIT() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface ITreasuryCaller {
  event TreasuryChange(address treasury);

  function setTreasury(address treasury) external;

  function getTreasury() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IUintValue {
  function get() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISafeOwnable} from "./interfaces/ISafeOwnable.sol";

contract SafeOwnable is ISafeOwnable, Ownable {
  address private _nominee;

  modifier onlyNominee() {
    require(_msgSender() == _nominee, "msg.sender != nominee");
    _;
  }

  function transferOwnership(address nominee)
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    _setNominee(nominee);
  }

  function acceptOwnership() public virtual override onlyNominee {
    _transferOwnership(_nominee);
    _setNominee(address(0));
  }

  function renounceOwnership()
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    super.renounceOwnership();
    _setNominee(address(0));
  }

  function getNominee() public view virtual override returns (address) {
    return _nominee;
  }

  function _setNominee(address nominee) internal virtual {
    address _oldNominee = _nominee;
    _nominee = nominee;
    emit NomineeUpdate(_oldNominee, nominee);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITokenSender, ITokenSenderCaller} from "./interfaces/ITokenSenderCaller.sol";

contract TokenSenderCaller is ITokenSenderCaller {
  mapping(address => uint256) internal _accountToAmountMultiplier;
  ITokenSender internal _tokenSender;

  uint256 public constant override PERCENT_UNIT = 1000000;

  function setAmountMultiplier(address account, uint256 amountMultiplier)
    public
    virtual
    override
  {
    _accountToAmountMultiplier[account] = amountMultiplier;
    emit AmountMultiplierChange(account, amountMultiplier);
  }

  function setTokenSender(ITokenSender tokenSender) public virtual override {
    _tokenSender = tokenSender;
    emit TokenSenderChange(address(tokenSender));
  }

  function getAmountMultiplier(address account)
    external
    view
    override
    returns (uint256)
  {
    return _accountToAmountMultiplier[account];
  }

  function getTokenSender() external view override returns (ITokenSender) {
    return _tokenSender;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {ITreasuryCaller} from "./interfaces/ITreasuryCaller.sol";

contract TreasuryCaller is ITreasuryCaller {
  address internal _treasury;

  function setTreasury(address treasury) public virtual override {
    _treasury = treasury;
    emit TreasuryChange(treasury);
  }

  function getTreasury() external view override returns (address) {
    return _treasury;
  }
}