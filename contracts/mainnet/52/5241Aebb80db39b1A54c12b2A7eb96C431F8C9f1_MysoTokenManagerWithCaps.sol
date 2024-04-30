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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error UnregisteredVault();
    error InvalidDelegatee();
    error InvalidSender();
    error InvalidFee();
    error InsufficientSendAmount();
    error NoOracle();
    error InvalidOracleAnswer();
    error InvalidOracleDecimals();
    error InvalidOracleVersion();
    error InvalidAddress();
    error InvalidArrayLength();
    error InvalidQuote();
    error OutdatedQuote();
    error InvalidOffChainSignature();
    error InvalidOffChainMerkleProof();
    error InvalidCollUnlock();
    error InvalidAmount();
    error UnknownOnChainQuote();
    error NeitherTokenIsGOHM();
    error NoLpTokens();
    error ZeroReserve();
    error IncorrectGaugeForLpToken();
    error InvalidGaugeIndex();
    error AlreadyStaked();
    error InvalidWithdrawAmount();
    error InvalidBorrower();
    error OutsideValidRepayWindow();
    error InvalidRepayAmount();
    error ReclaimAmountIsZero();
    error UnregisteredGateway();
    error NonWhitelistedOracle();
    error NonWhitelistedCompartment();
    error NonWhitelistedCallback();
    error NonWhitelistedToken();
    error LtvHigherThanMax();
    error InsufficientVaultFunds();
    error InvalidInterestRateFactor();
    error InconsistentUnlockTokenAddresses();
    error InvalidEarliestRepay();
    error InvalidNewMinNumOfSigners();
    error AlreadySigner();
    error InvalidArrayIndex();
    error InvalidSignerRemoveInfo();
    error InvalidSendAmount();
    error TooSmallLoanAmount();
    error DeadlinePassed();
    error WithdrawEntered();
    error DuplicateAddresses();
    error OnChainQuoteAlreadyAdded();
    error OffChainQuoteHasBeenInvalidated();
    error Uninitialized();
    error InvalidRepaymentScheduleLength();
    error FirstDueDateTooCloseOrPassed();
    error InvalidGracePeriod();
    error UnregisteredLoanProposal();
    error NotInSubscriptionPhase();
    error NotInUnsubscriptionPhase();
    error InsufficientBalance();
    error InsufficientFreeSubscriptionSpace();
    error BeforeEarliestUnsubscribe();
    error InconsistentLastLoanTermsUpdateTime();
    error InvalidActionForCurrentStatus();
    error FellShortOfTotalSubscriptionTarget();
    error InvalidRollBackRequest();
    error UnsubscriptionAmountTooLarge();
    error InvalidSubscriptionRange();
    error InvalidMaxTotalSubscriptions();
    error OutsideConversionTimeWindow();
    error OutsideRepaymentTimeWindow();
    error NoDefault();
    error LoanIsFullyRepaid();
    error RepaymentIdxTooLarge();
    error AlreadyClaimed();
    error AlreadyConverted();
    error InvalidDueDates();
    error LoanTokenDueIsZero();
    error WaitForLoanTermsCoolOffPeriod();
    error ZeroConversionAmount();
    error InvalidNewOwnerProposal();
    error CollateralMustBeCompartmentalized();
    error InvalidCompartmentForToken();
    error InvalidSignature();
    error InvalidUpdate();
    error CannotClaimOutdatedStatus();
    error DelegateReducedBalance();
    error FundingPoolAlreadyExists();
    error InvalidLender();
    error NonIncreasingTokenAddrs();
    error NonIncreasingNonFungibleTokenIds();
    error TransferToWrappedTokenFailed();
    error TransferFromWrappedTokenFailed();
    error StateAlreadySet();
    error ReclaimableCollateralAmountZero();
    error InvalidSwap();
    error InvalidUpfrontFee();
    error InvalidOracleTolerance();
    error ReserveRatiosSkewedFromOraclePrice();
    error SequencerDown();
    error GracePeriodNotOver();
    error LoanExpired();
    error NoDsEth();
    error TooShortTwapInterval();
    error TooLongTwapInterval();
    error TwapExceedsThreshold();
    error Reentrancy();
    error TokenNotStuck();
    error InconsistentExpTransferFee();
    error InconsistentExpVaultBalIncrease();
    error DepositLockActive();
    error DisallowedSubscriptionLockup();
    error IncorrectLoanAmount();
    error Disabled();
    error CannotRemintUnlessZeroSupply();
    error TokensStillMissingFromWrapper();
    error OnlyMintFromSingleTokenWrapper();
    error NonMintableTokenState();
    error NoTokensTransferred();
    error TokenAlreadyCountedInWrapper();
    error TokenNotOwnedByWrapper();
    error TokenDoesNotBelongInWrapper(address tokenAddr, uint256 tokenId);
    error InvalidMintAmount();
    error QuoteViolatesPolicy();
    error AlreadyPublished();
    error PolicyAlreadySet();
    error NoPolicyToDelete();
    error InvalidTenorBounds();
    error InvalidLtvBounds();
    error InvalidLoanPerCollBounds();
    error InvalidMinApr();
    error NoPolicy();
    error InvalidMinFee();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library Helpers {
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 vs) {
        require(sig.length == 64, "invalid signature length");
        // solhint-disable no-inline-assembly
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            vs := mload(add(sig, 64))
        }
        // implicitly return (r, vs)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";

interface IMysoTokenManager {
    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams);

    function processP2PCreateVault(
        uint256 numRegisteredVaults,
        address vaultCreator,
        address newLenderVaultAddr
    ) external;

    function processP2PCreateWrappedTokenForERC721s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PCreateWrappedTokenForERC20s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolDeposit(
        address fundingPool,
        address depositor,
        uint256 depositAmount,
        uint256 depositLockupDuration,
        uint256 transferFee
    ) external;

    function processP2PoolSubscribe(
        address fundingPool,
        address subscriber,
        address loanProposal,
        uint256 subscriptionAmount,
        uint256 subscriptionLockupDuration,
        uint256 totalSubscriptions,
        DataTypesPeerToPool.LoanTerms calldata loanTerms
    ) external;

    function processP2PoolLoanFinalization(
        address loanProposal,
        address fundingPool,
        address arranger,
        address borrower,
        uint256 grossLoanAmount,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolCreateLoanProposal(
        address fundingPool,
        address proposalCreator,
        address collToken,
        uint256 arrangerFee,
        uint256 numLoanProposals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPeer {
    struct Loan {
        // address of borrower
        address borrower;
        // address of coll token
        address collToken;
        // address of loan token
        address loanToken;
        // timestamp after which any portion of loan unpaid defaults
        uint40 expiry;
        // timestamp before which borrower cannot repay
        uint40 earliestRepay;
        // initial collateral amount of loan
        uint128 initCollAmount;
        // loan amount given
        uint128 initLoanAmount;
        // full repay amount at start of loan
        uint128 initRepayAmount;
        // amount repaid (loan token) up until current time
        // note: partial repayments are allowed
        uint128 amountRepaidSoFar;
        // amount reclaimed (coll token) up until current time
        // note: partial repayments are allowed
        uint128 amountReclaimedSoFar;
        // flag tracking if collateral has been unlocked by vault
        bool collUnlocked;
        // address of the compartment housing the collateral
        address collTokenCompartmentAddr;
    }

    struct QuoteTuple {
        // loan amount per one unit of collateral if no oracle
        // LTV in terms of the constant BASE (10 ** 18) if using oracle
        uint256 loanPerCollUnitOrLtv;
        // interest rate percentage in BASE (can be negative but greater than -BASE)
        // i.e. -100% < interestRatePct since repay amount of 0 is not allowed
        // also interestRatePctInBase is not annualized
        int256 interestRatePctInBase;
        // fee percentage,in BASE, which will be paid in upfront in collateral
        uint256 upfrontFeePctInBase;
        // length of the loan in seconds
        uint256 tenor;
    }

    struct GeneralQuoteInfo {
        // address of collateral token
        address collToken;
        // address of loan token
        address loanToken;
        // address of oracle (optional)
        address oracleAddr;
        // min loan amount (in loan token) prevent griefing attacks or
        // amounts lender feels isn't worth unlocking on default
        uint256 minLoan;
        // max loan amount (in loan token) if lender wants a cap
        uint256 maxLoan;
        // timestamp after which quote automatically invalidates
        uint256 validUntil;
        // time, in seconds, that loan cannot be exercised
        uint256 earliestRepayTenor;
        // address of compartment implementation (optional)
        address borrowerCompartmentImplementation;
        // will invalidate quote after one use
        // if false, will be a standing quote
        bool isSingleUse;
        // whitelist address (optional)
        address whitelistAddr;
        // flag indicating whether whitelistAddr refers to a single whitelisted
        // borrower or to a whitelist authority that can whitelist multiple addresses
        bool isWhitelistAddrSingleBorrower;
    }

    struct OnChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // array of quote parameters
        QuoteTuple[] quoteTuples;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
    }

    struct OffChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // root of the merkle tree, where the merkle tree encodes all QuoteTuples the lender accepts
        bytes32 quoteTuplesRoot;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
        // for invalidating multiple parallel quotes in one click
        uint256 nonce;
        // array of compact signatures from vault signers
        bytes[] compactSigs;
    }

    struct LoanRepayInstructions {
        // loan id being repaid
        uint256 targetLoanId;
        // repay amount after transfer fees in loan token
        uint128 targetRepayAmount;
        // expected transfer fees in loan token (=0 for tokens without transfer fee)
        // note: amount that borrower sends is targetRepayAmount + expectedTransferFee
        uint128 expectedTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // e.g., for using collateral to payoff debt via DEX
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
    }

    struct BorrowTransferInstructions {
        // amount of collateral sent
        uint256 collSendAmount;
        // sum of (i) protocol fee and (ii) transfer fees (if any) associated with sending any collateral to vault
        uint256 expectedProtocolAndVaultTransferFee;
        // transfer fees associated with sending any collateral to compartment (if used)
        uint256 expectedCompartmentTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // slippage protection if oracle price is too loose
        uint256 minLoanAmount;
        // e.g., for one-click leverage
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
        // any data needed by myso token manager
        bytes mysoTokenManagerData;
    }

    struct TransferInstructions {
        // collateral token receiver
        address collReceiver;
        // effective upfront fee in collateral tokens (vault or compartment)
        uint256 upfrontFee;
    }

    struct WrappedERC721TokenInfo {
        // address of the ERC721_TOKEN
        address tokenAddr;
        // array of ERC721_TOKEN ids
        uint256[] tokenIds;
    }

    struct WrappedERC20TokenInfo {
        // token addresse
        address tokenAddr;
        // token amounts
        uint256 tokenAmount;
    }

    struct OnChainQuoteInfo {
        // hash of on chain quote
        bytes32 quoteHash;
        // valid until timestamp
        uint256 validUntil;
    }

    enum WhitelistState {
        // not whitelisted
        NOT_WHITELISTED,
        // can be used as loan or collateral token
        ERC20_TOKEN,
        // can be be used as oracle
        ORACLE,
        // can be used as compartment
        COMPARTMENT,
        // can be used as callback contract
        CALLBACK,
        // can be used as loan or collateral token, but if collateral then must
        // be used in conjunction with a compartment (e.g., for stETH with possible
        // negative rebase that could otherwise affect other borrowers in the vault)
        ERC20_TOKEN_REQUIRING_COMPARTMENT,
        // can be used in conjunction with an ERC721 wrapper
        ERC721_TOKEN,
        // can be used as ERC721 wrapper contract
        ERC721WRAPPER,
        // can be used as ERC20 wrapper contract
        ERC20WRAPPER,
        // can be used as MYSO token manager contract
        MYSO_TOKEN_MANAGER,
        // can be used as quote policy manager contract
        QUOTE_POLICY_MANAGER
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";

interface ILenderVaultImpl {
    event AddedSigners(address[] _signers);

    event MinNumberOfSignersSet(uint256 minNumSigners);

    event RemovedSigner(
        address signerRemoved,
        uint256 signerIdx,
        address signerMovedFromEnd
    );

    event CollateralUnlocked(
        address indexed vaultOwner,
        address indexed collToken,
        uint256[] loanIds,
        uint256 amountUnlocked
    );

    event QuoteProcessed(
        uint256 netPledgeAmount,
        DataTypesPeerToPeer.TransferInstructions transferInstructions
    );

    event Withdrew(address indexed tokenAddr, uint256 withdrawAmount);

    event CircuitBreakerUpdated(
        address indexed newCircuitBreaker,
        address indexed oldCircuitBreaker
    );

    event ReverseCircuitBreakerUpdated(
        address indexed newReverseCircuitBreaker,
        address indexed oldReverseCircuitBreaker
    );

    event OnChainQuotingDelegateUpdated(
        address indexed newOnChainQuotingDelegate,
        address indexed oldOnChainQuotingDelegate
    );

    /**
     * @notice function to initialize lender vault
     * @dev factory creates clone and then initializes the vault
     * @param vaultOwner address of vault owner
     * @param addressRegistry registry address
     */
    function initialize(address vaultOwner, address addressRegistry) external;

    /**
     * @notice function to unlock defaulted collateral
     * @dev only loans with same collateral token can be unlocked in one call
     * function will revert if mismatch in coll token to a loan.collToken.
     * @param collToken address of the collateral token
     * @param _loanIds array of indices of the loans to unlock
     */
    function unlockCollateral(
        address collToken,
        uint256[] calldata _loanIds
    ) external;

    /**
     * @notice function to update loan info on a reoay
     * @dev only borrower gateway can call this function
     * loanId is needed by vault to store updated loan info
     * @param repayAmount amount of loan repaid
     * @param loanId index of loan in loans array
     * @param collAmount amount of collateral to unlock
     * @param noCompartment boolean flag indicating whether loan has no compartment
     * @param collToken address of the collateral token
     */
    function updateLoanInfo(
        uint128 repayAmount,
        uint256 loanId,
        uint128 collAmount,
        bool noCompartment,
        address collToken
    ) external;

    /**
     * @notice function to processQuote on a borrow
     * @dev only borrower gateway can call this function
     * @param borrower address of the borrower
     * @param borrowInstructions struct containing all info for borrow (see DataTypesPeerToPeer.sol notes)
     * @param generalQuoteInfo struct containing quote info (see Datatypes.sol notes)
     * @param quoteTuple struct containing specific quote tuple info (see DataTypesPeerToPeer.sol notes)
     * @return loan loan information after processing the quote
     * @return loanId index of loans in the loans array
     * @return transferInstructions struct containing transfer instruction info (see DataTypesPeerToPeer.sol notes)
     */
    function processQuote(
        address borrower,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple
    )
        external
        returns (
            DataTypesPeerToPeer.Loan calldata loan,
            uint256 loanId,
            DataTypesPeerToPeer.TransferInstructions memory transferInstructions
        );

    /**
     * @notice function to withdraw a token from a vault
     * @dev only vault owner can withdraw
     * @param token address of the token to withdraw
     * @param amount amount of token to withdraw
     */
    function withdraw(address token, uint256 amount) external;

    /**
     * @notice function to transfer token from vault
     * @dev only borrow gateway can call this function
     * @param token address of the token to transfer
     * @param recipient address which receives the tokens
     * @param amount amount of token to transfer
     */
    function transferTo(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice function to transfer token from a compartment
     * @dev only borrow gateway can call this function, if callbackAddr, then
     * the collateral will be transferred to the callback address
     * @param repayAmount amount of loan token to be repaid
     * @param repayAmountLeft amount of loan token still outstanding
     * @param reclaimCollAmount amount of collateral to be reclaimed
     * @param borrowerAddr address of the borrower
     * @param collTokenAddr address of the coll token to transfer to compartment
     * @param callbackAddr address of callback
     * @param collTokenCompartmentAddr address of the coll token compartment
     */
    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr,
        address collTokenCompartmentAddr
    ) external;

    /**
     * @notice function to set minimum number of signers required for an offchain quote
     * @dev this function allows a multi-sig quorum to sign a quote offchain
     * @param _minNumOfSigners minimum number of signatures borrower needs to provide
     */
    function setMinNumOfSigners(uint256 _minNumOfSigners) external;

    /**
     * @notice function to add a signer
     * @dev this function only can be called by vault owner
     * @param _signers array of signers to add
     */
    function addSigners(address[] calldata _signers) external;

    /**
     * @notice function to remove a signer
     * @dev this function only can be called by vault owner
     * @param signer address of signer to be removed
     * @param signerIdx index of the signers array at which signer resides
     */
    function removeSigner(address signer, uint256 signerIdx) external;

    /**
     * @notice function to set a circuit breaker
     * @dev the circuit breaker (and vault owner) can pause all loan offers;
     * note: circuit breaker and reverse circuit breaker can be the same account
     * @param circuitBreaker address of the circuit breaker
     */
    function setCircuitBreaker(address circuitBreaker) external;

    /**
     * @notice function to set a reverse circuit breaker
     * @dev the reverse circuit breaker (and vault owner) can unpause all loan offers;
     * note: circuit breaker and reverse circuit breaker can be the same account
     * @param reverseCircuitBreaker address of the reverse circuit breaker
     */
    function setReverseCircuitBreaker(address reverseCircuitBreaker) external;

    /**
     * @notice function to set a delegate for on chain quoting
     * @dev the quote handler (and vault owner) can add, delete and update on chain quotes
     * @param onChainQuotingDelegate address of the delegate
     */
    function setOnChainQuotingDelegate(address onChainQuotingDelegate) external;

    /**
     * @notice function to pause all quotes from lendervault
     * @dev only vault owner and circuit breaker can pause quotes
     */
    function pauseQuotes() external;

    /**
     * @notice function to unpause all quotes from lendervault
     * @dev only vault owner and reverse circuit breaker can unpause quotes again
     */
    function unpauseQuotes() external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice function to retrieve loan from loans array in vault
     * @dev this function reverts on invalid index
     * @param index index of loan
     * @return loan loan stored at that index in vault
     */
    function loan(
        uint256 index
    ) external view returns (DataTypesPeerToPeer.Loan memory loan);

    /**
     * @notice function to return owner address
     * @return owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice function to return the total number of signers
     * @return number of signers
     */
    function totalNumSigners() external view returns (uint256);

    /**
     * @notice function to return unlocked token balances
     * @param tokens array of token addresses
     * @return balances the vault balances of the token addresses
     * @return _lockedAmounts the vault locked amounts of the token addresses
     */
    function getTokenBalancesAndLockedAmounts(
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory balances, uint256[] memory _lockedAmounts);

    /**
     * @notice function to return address of registry
     * @return registry address
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice function to return address of the circuit breaker
     * @return circuit breaker address
     */
    function circuitBreaker() external view returns (address);

    /**
     * @notice function to return address of the reverse circuit breaker
     * @return reverse circuit breaker address
     */
    function reverseCircuitBreaker() external view returns (address);

    /**
     * @notice function to return address of the delegate for on chain quoting
     * @return approved delegate address
     */
    function onChainQuotingDelegate() external view returns (address);

    /**
     * @notice function returns signer at given index
     * @param index of the signers array
     * @return signer address
     */
    function signers(uint256 index) external view returns (address);

    /**
     * @notice function returns minimum number of signers
     * @return minimum number of signers
     */
    function minNumOfSigners() external view returns (uint256);

    /**
     * @notice function returns if address is a signer
     * @return true, if a signer, else false
     */
    function isSigner(address signer) external view returns (bool);

    /**
     * @notice function returns if withdraw mutex is activated
     * @return true, if withdraw already called, else false
     */
    function withdrawEntered() external view returns (bool);

    /**
     * @notice function returns current locked amounts of given token
     * @param token address of the token
     * @return amount of token locked
     */
    function lockedAmounts(address token) external view returns (uint256);

    /**
     * @notice function returns total number of loans
     * @return total number of loans
     */
    function totalNumLoans() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPool {
    struct Repayment {
        // The loan token amount due for given period; initially, expressed in relative terms (100%=BASE), once
        // finalized in absolute terms (in loanToken)
        uint128 loanTokenDue;
        // The coll token amount that can be converted for given period; initially, expressed in relative terms w.r.t.
        // loanTokenDue (e.g., convert every 1 loanToken for 8 collToken), once finalized in absolute terms (in collToken)
        uint128 collTokenDueIfConverted;
        // Timestamp when repayment is due
        uint40 dueTimestamp;
    }

    struct LoanTerms {
        // Min subscription amount (in loan token) that the borrower deems acceptable
        uint128 minTotalSubscriptions;
        // Max subscription amount (in loan token) that the borrower deems acceptable
        uint128 maxTotalSubscriptions;
        // The number of collateral tokens the borrower pledges per loan token borrowed as collateral for default case
        uint128 collPerLoanToken;
        // Borrower who can finalize given loan proposal
        address borrower;
        // Array of scheduled repayments
        Repayment[] repaymentSchedule;
    }

    struct StaticLoanProposalData {
        // Factory address from which the loan proposal is created
        address factory;
        // Funding pool address that is associated with given loan proposal and from which loan liquidity can be
        // sourced
        address fundingPool;
        // Address of collateral token to be used for given loan proposal
        address collToken;
        // Address of arranger who can manage the loan proposal contract
        address arranger;
        // Address of whitelist authority who can manage the lender whitelist (optional)
        address whitelistAuthority;
        // Unsubscribe grace period (in seconds), i.e., after acceptance by borrower lenders can unsubscribe and
        // remove liquidity for this duration before being locked-in
        uint256 unsubscribeGracePeriod;
        // Conversion grace period (in seconds), i.e., lenders can exercise their conversion right between
        // [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
        uint256 conversionGracePeriod;
        // Repayment grace period (in seconds), i.e., borrowers can repay between
        // [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
        uint256 repaymentGracePeriod;
    }

    struct DynamicLoanProposalData {
        // Arranger fee charged on final loan amount, initially in relative terms (100%=BASE), and after finalization
        // in absolute terms (in loan token)
        uint256 arrangerFee;
        // The gross loan amount; initially this is zero and gets set once loan proposal gets accepted and finalized;
        // note that the borrower receives the gross loan amount minus any arranger and protocol fees
        uint256 grossLoanAmount;
        // Final collateral amount reserved for defaults; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForDefault;
        // Final collateral amount reserved for conversions; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForConversions;
        // Timestamp when the loan terms get accepted by borrower and after which they cannot be changed anymore
        uint256 loanTermsLockedTime;
        // Current repayment index, mapping to currently relevant repayment schedule element; note the
        // currentRepaymentIdx (initially 0) only ever gets incremented on repay
        uint256 currentRepaymentIdx;
        // Status of current loan proposal
        DataTypesPeerToPool.LoanStatus status;
        // Protocol fee, initially in relative terms (100%=BASE), and after finalization in absolute terms (in loan token);
        // note that the relative protocol fee is locked in at the time when the loan proposal is created
        uint256 protocolFee;
    }

    enum LoanStatus {
        WITHOUT_LOAN_TERMS,
        IN_NEGOTIATION,
        LOAN_TERMS_LOCKED,
        READY_TO_EXECUTE,
        ROLLBACK,
        LOAN_DEPLOYED,
        DEFAULTED
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IStMysoToken {
    function weight(address acc) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {Helpers} from "../Helpers.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";
import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";
import {IStMysoToken} from "./interfaces/IStMysoToken.sol";

contract MysoTokenManager is Ownable2Step, IMysoTokenManager {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    struct RewardInfo {
        uint128 collThreshold;
        // Multiplier in units of BASE
        uint128 mysoTokenMultiplier;
    }

    uint256 public totalMysoLoanAmount;
    uint256 public minMysoWeight;

    address public mysoIOOVault;
    address public mysoToken;
    address public stMysoToken;
    address public signingAuthority;
    mapping(address => RewardInfo) public rewardInfos;
    mapping(bytes32 => bool) public alreadyClaimed;
    event RewardInfoSet(
        address indexed collToken,
        uint128 collThreshold,
        uint128 mysoTokenMultiplier
    );
    event MysoTokenSet(address mysoToken);
    event StMysoTokenSet(address stMysoToken);
    event MinMysoWeightSet(uint256 minMysoWeight);
    event IOOVaultSet(address mysoIOOVault);
    event SignerSet(address signer);
    event TotalMysoLoanAmountSet(uint256 totalMysoLoanAmount);

    error NotAllowed();

    constructor(
        address _mysoIOOVault,
        address _mysoToken,
        address _stMysoToken,
        uint256 _minMysoWeight,
        address _signer
    ) {
        mysoIOOVault = _mysoIOOVault;
        mysoToken = _mysoToken;
        stMysoToken = _stMysoToken;
        minMysoWeight = _minMysoWeight;
        signingAuthority = _signer;
        _transferOwnership(msg.sender);
    }

    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams) {
        applicableProtocolFeeParams = currProtocolFeeParams;
        address _mysoToken = mysoToken;
        if (_mysoToken != address(0)) {
            bool isMysoIoo = loan.loanToken == _mysoToken &&
                lenderVault == mysoIOOVault;
            if (!_isAllowed(isMysoIoo, borrowInstructions, loan)) {
                revert NotAllowed();
            }
            if (isMysoIoo) {
                totalMysoLoanAmount += loan.initLoanAmount;
            }
            address _stMysoToken = stMysoToken;
            if (
                _stMysoToken != address(0) &&
                IStMysoToken(_stMysoToken).weight(loan.borrower) >=
                minMysoWeight
            ) {
                RewardInfo memory rewardInfo = rewardInfos[loan.collToken];
                // @dev: multiplier in BASE cancels out with MYT decimals
                uint256 rewardAmount = (loan.initCollAmount *
                    rewardInfo.mysoTokenMultiplier) /
                    (10 ** IERC20Metadata(loan.collToken).decimals());
                uint256 bal = IERC20(_mysoToken).balanceOf(address(this));
                rewardAmount = rewardAmount > bal ? bal : rewardAmount;
                if (
                    loan.initCollAmount >= rewardInfo.collThreshold &&
                    rewardAmount > 0
                ) {
                    SafeERC20.safeTransfer(
                        IERC20(_mysoToken),
                        ILenderVaultImpl(lenderVault).owner(),
                        rewardAmount
                    );
                }
            }
        }
    }

    // solhint-disable no-empty-blocks
    function processP2PCreateVault(
        uint256 /*numRegisteredVaults*/,
        address /*vaultCreator*/,
        address /*newLenderVaultAddr*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PCreateWrappedTokenForERC721s(
        address /*tokenCreator*/,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[]
            calldata /*tokensToBeWrapped*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PCreateWrappedTokenForERC20s(
        address /*tokenCreator*/,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[]
            calldata /*tokensToBeWrapped*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolDeposit(
        address /*fundingPool*/,
        address /*depositor*/,
        uint256 /*depositAmount*/,
        uint256 /*depositLockupDuration*/,
        uint256 /*transferFee*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolSubscribe(
        address /*fundingPool*/,
        address /*subscriber*/,
        address /*loanProposal*/,
        uint256 /*subscriptionAmount*/,
        uint256 /*subscriptionLockupDuration*/,
        uint256 /*totalSubscriptions*/,
        DataTypesPeerToPool.LoanTerms calldata /*loanTerms*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolLoanFinalization(
        address /*loanProposal*/,
        address /*fundingPool*/,
        address /*arranger*/,
        address /*borrower*/,
        uint256 /*grossLoanAmount*/,
        bytes calldata /*mysoTokenManagerData*/
    ) external {}

    // solhint-disable no-empty-blocks
    function processP2PoolCreateLoanProposal(
        address /*fundingPool*/,
        address /*proposalCreator*/,
        address /*collToken*/,
        uint256 /*arrangerFee*/,
        uint256 /*numLoanProposals*/
    ) external {}

    function withdraw(address token, address to, uint256 amount) external {
        _checkOwner();
        SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

    function setRewardInfo(
        address collToken,
        uint128 collThreshold,
        uint128 mysoTokenMultiplier
    ) external {
        _checkOwner();
        RewardInfo storage rewardInfo = rewardInfos[collToken];
        rewardInfo.collThreshold = collThreshold;
        rewardInfo.mysoTokenMultiplier = mysoTokenMultiplier;
        emit RewardInfoSet(collToken, collThreshold, mysoTokenMultiplier);
    }

    function setMinMysoWeight(uint256 _minMysoWeight) external {
        _checkOwner();
        minMysoWeight = _minMysoWeight;
        emit MinMysoWeightSet(_minMysoWeight);
    }

    function setMysoToken(address _mysoToken) external {
        _checkOwner();
        mysoToken = _mysoToken;
        emit MysoTokenSet(_mysoToken);
    }

    function setStMysoToken(address _stMysoToken) external {
        _checkOwner();
        stMysoToken = _stMysoToken;
        emit StMysoTokenSet(_stMysoToken);
    }

    function setIOOVault(address _mysoIOOVault) external {
        _checkOwner();
        mysoIOOVault = _mysoIOOVault;
        emit IOOVaultSet(_mysoIOOVault);
    }

    function setSigner(address _signer) external {
        _checkOwner();
        signingAuthority = _signer;
        emit SignerSet(_signer);
    }

    function setTotalMysoLoanAmount(uint256 _totalMysoLoanAmount) external {
        _checkOwner();
        totalMysoLoanAmount = _totalMysoLoanAmount;
        emit TotalMysoLoanAmountSet(_totalMysoLoanAmount);
    }

    function transferOwnership(address _newOwnerProposal) public override {
        _checkOwner();
        if (
            _newOwnerProposal == address(0) ||
            _newOwnerProposal == address(this) ||
            _newOwnerProposal == pendingOwner() ||
            _newOwnerProposal == owner()
        ) {
            revert Errors.InvalidNewOwnerProposal();
        }
        super._transferOwnership(_newOwnerProposal);
    }

    function _isAllowed(
        bool isMysoIoo,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan
    ) internal virtual returns (bool) {
        if (isMysoIoo) {
            address _signer = signingAuthority;
            if (_signer == address(0)) {
                return true;
            } else {
                (bytes memory compactSig, uint256 nonce) = abi.decode(
                    borrowInstructions.mysoTokenManagerData,
                    (bytes, uint256)
                );
                bytes32 payloadHash = keccak256(
                    abi.encode(loan.borrower, nonce)
                );
                if (alreadyClaimed[payloadHash]) {
                    return false;
                }
                (bytes32 r, bytes32 vs) = Helpers.splitSignature(compactSig);
                bytes32 messageHash = ECDSA.toEthSignedMessageHash(payloadHash);
                address recoveredSigner = messageHash.recover(r, vs);
                if (recoveredSigner == _signer) {
                    alreadyClaimed[payloadHash] = true;
                    return true;
                }
                return false;
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import {MysoTokenManager} from "./MysoTokenManager.sol";
import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";

contract MysoTokenManagerWithCaps is MysoTokenManager {
    struct CollatCapInfo {
        address token;
        uint128 maxPledge;
    }

    mapping(address => uint256) public collatCaps;
    mapping(address => uint256) public totalPledged;

    event CollatCapsSet(CollatCapInfo[] collatCaps);

    constructor(
        address _mysoIOOVault,
        address _mysoToken,
        address _stMysoToken,
        uint256 _minMysoWeight,
        address _signer,
        CollatCapInfo[] memory _collatCaps
    )
        MysoTokenManager(
            _mysoIOOVault,
            _mysoToken,
            _stMysoToken,
            _minMysoWeight,
            _signer
        )
    {
        for (uint256 i = 0; i < _collatCaps.length; i++) {
            collatCaps[_collatCaps[i].token] = _collatCaps[i].maxPledge;
        }
    }

    function setCollatCaps(CollatCapInfo[] calldata _collatCaps) external {
        _checkOwner();
        for (uint256 i = 0; i < _collatCaps.length; i++) {
            collatCaps[_collatCaps[i].token] = _collatCaps[i].maxPledge;
        }
        emit CollatCapsSet(_collatCaps);
    }

    function _isAllowed(
        bool isMysoIoo,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan
    ) internal override returns (bool isAllowed) {
        isAllowed = super._isAllowed(isMysoIoo, borrowInstructions, loan);
        if (!isAllowed) {
            return false;
        }
        if (isMysoIoo) {
            uint256 _newPledged = totalPledged[loan.collToken] +
                loan.initCollAmount;
            uint256 _collatCap = collatCaps[loan.collToken];
            // @dev: default 0 value means no cap
            if (_collatCap == 0) {
                return true;
            }
            isAllowed = _newPledged <= collatCaps[loan.collToken];
            if (isAllowed) {
                totalPledged[loan.collToken] = _newPledged;
            }
        } else {
            isAllowed = true;
        }
    }
}