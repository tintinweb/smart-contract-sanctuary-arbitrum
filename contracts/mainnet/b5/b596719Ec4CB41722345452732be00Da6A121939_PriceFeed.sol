// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

interface IConfiguration {
  event DepositFeeUpdated(uint256 fee);
  event WithdrawFeeUpdated(uint256 fee);
  event ProtocolTreasuryUpdated(address indexed treasury);

  function depositFee() external view returns (uint256);

  function setDepositFee(uint256 fee) external;

  function withdrawFee() external view returns (uint256);

  function setWithdrawFee(uint256 fee) external;

  function protocolTreasury() external view returns (address);

  function setProtocolTreasury(address treasury) external;
}

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

/// @dev Common contract exceptions

/// @dev Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @dev Thrown on attempting to call a non-implemented function
error NotImplementedException();

/// @dev Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @dev Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

// NOTE: new values must always be added at the end of the enum

enum PriceFeedType {
  COMPOSITE_ORACLE
}

interface IPriceFeedType {
  /// @dev Returns the price feed type
  function priceFeedType() external view returns (PriceFeedType);

  /// @dev Returns whether sanity checks on price feed result should be skipped
  function skipPriceCheck() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

import {IVersion} from "./IVersion.sol";

interface IPriceOracleEvents {
  /// @dev Emits when a quote price feed is changed
  event ChangedQuotePriceFeed(address indexed quotePriceFeed, uint8 decimals);

  /// @dev Emits when a new price feed is added
  event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleExceptions {
  /// @dev Thrown if a price feed returns 0
  error ZeroPriceException();

  /// @dev Thrown if the last recorded result was not updated in the last round
  error ChainPriceStaleException();

  /// @dev Thrown on attempting to get a result for a token that does not have a price feed
  error PriceOracleNotExistsException();

  /// @dev Thrown on attempting to set a token price feed to an address that is not a
  ///      correct price feed
  error IncorrectPriceFeedException();
}

interface IPriceOracle is IPriceOracleEvents, IPriceOracleExceptions, IVersion {
  /// @dev Sets a quote price feed if it doesn't exist, or updates an existing one
  /// @param quotePriceFeed Address of a Fiat price feed adhering to Chainlink's interface
  function addQuotePriceFeed(address quotePriceFeed) external;

  /// @dev Sets a price feed if it doesn't exist, or updates an existing one
  /// @param token Address of the token to set the price feed for
  /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
  function addPriceFeed(address token, address priceFeed) external;

  /// @dev Returns token's price in USD (8 decimals)
  /// @param token The token to compute the price for
  function getPrice(address token) external view returns (uint256);

  /// @dev Converts a quantity of an asset to USD (decimals = 8).
  /// @param amount Amount to convert
  /// @param token Address of the token to be converted
  function convertToUSD(
    uint256 amount,
    address token
  ) external view returns (uint256);

  /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
  /// @param amount Amount to convert
  /// @param token Address of the token converted to
  function convertFromUSD(
    uint256 amount,
    address token
  ) external view returns (uint256);

  /// @dev Converts one asset into another
  /// @param amount Amount to convert
  /// @param tokenFrom Address of the token to convert from
  /// @param tokenTo Address of the token to convert to
  function convert(
    uint256 amount,
    address tokenFrom,
    address tokenTo
  ) external view returns (uint256);

  /// @dev Returns token's price in Derived Fiat (8 decimals)
  /// @param token The token to compute the price for
  function getPriceInDerivedFiat(address token) external view returns (uint256);

  /// @dev Converts a quantity of an asset to Derived Fiat (decimals = 8).
  /// @param amount Amount to convert
  /// @param token Address of the token to be converted
  function convertToDerivedFiat(
    uint256 amount,
    address token
  ) external view returns (uint256);

  /// @dev Converts a quantity of Derived Fiat (decimals = 8) to an equivalent amount of an asset
  /// @param amount Amount to convert
  /// @param token Address of the token converted to
  function convertFromDerivedFiat(
    uint256 amount,
    address token
  ) external view returns (uint256);

  /// @dev Converts one asset into another with Derived Fiat
  /// @param amount Amount to convert
  /// @param tokenFrom Address of the token to convert from
  /// @param tokenTo Address of the token to convert to
  function convertInDerivedFiat(
    uint256 amount,
    address tokenFrom,
    address tokenTo
  ) external view returns (uint256);

  /// @dev Returns the price feed address for the passed token
  /// @param token Token to get the price feed for
  function priceFeeds(address token) external view returns (address priceFeed);

  /// @dev Returns the price feed for the passed token,
  ///      with additional parameters
  /// @param token Token to get the price feed for
  function priceFeedsWithFlags(
    address token
  ) external view returns (address priceFeed, bool skipCheck, uint256 decimals);
}

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

/// @title IVersion
/// @dev Declares a version function which returns the contract's version
interface IVersion {
  /// @dev Returns contract version
  function version() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceFeedChecker} from "./PriceFeedChecker.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IPriceFeedType} from "../interfaces/IPriceFeedType.sol";
import {IConfiguration} from "../interfaces/IConfiguration.sol";

// EXCEPTIONS
import {ZeroAddressException, AddressIsNotContractException, IncorrectTokenContractException} from "../interfaces/IErrors.sol";

// STRUCTS

struct PriceFeedConfig {
  address token;
  address priceFeed;
}

// CONSTANTS

uint256 constant SKIP_PRICE_CHECK_FLAG = 1 << 161;
uint256 constant DECIMALS_SHIFT = 162;

/// @title Price Oracle
/// @author Gearbox
/// @notice Works as router and provide cross rates converting via USD or BRL
/// @dev All function calls are currently implemented
/// @custom:security-contact [email protected]
contract PriceFeed is Ownable, PriceFeedChecker, IPriceOracle {
  using Address for address;

  /// @dev Map of token addresses to corresponding price feeds and their parameters,
  ///      encoded into a single uint256
  mapping(address => uint256) internal priceFeedsList;

  // Contract version
  uint256 public constant version = 1;

  address public immutable link;

  IConfiguration public immutable configuration;

  /// @dev Chainlink quote asset price feed
  AggregatorV3Interface public quotePriceFeed;

  /// @dev Chainlink quote asset price feed decimals
  uint8 public quotePriceFeedDecimals;

  constructor(
    address quotePriceFeed_,
    PriceFeedConfig[] memory defaults_,
    address link_,
    address configuration_
  ) {
    require(
      quotePriceFeed_ != address(0),
      "PriceFeed: quotePriceFeed_ cannot be address 0"
    );

    require(link_ != address(0), "PriceFeed: link_ cannot be address 0");

    require(
      configuration_ != address(0),
      "PriceFeed: configuration_ cannot be address 0"
    );

    // LINK token
    link = link_;

    // Protocol configurations
    configuration = IConfiguration(configuration_);

    _addQuotePriceFeed(quotePriceFeed_);

    uint256 len = defaults_.length;

    for (uint256 i = 0; i < len; ) {
      _addPriceFeed(defaults_[i].token, defaults_[i].priceFeed); // F:[PO-1]

      unchecked {
        ++i;
      }
    }
  }

  /// @inheritdoc IPriceOracle
  function addQuotePriceFeed(address quotePriceFeed_) external onlyOwner {
    _addQuotePriceFeed(quotePriceFeed_);
  }

  // slither-disable-start uninitialized-local,unused-return,calls-loop
  /// @dev IMPLEMENTATION: addQuotePriceFeed
  /// @param quotePriceFeed_ Address of a Fiat price feed adhering to Chainlink's interface
  function _addQuotePriceFeed(address quotePriceFeed_) internal {
    if (quotePriceFeed_ == address(0)) revert ZeroAddressException(); // F:[PO-2]

    if (!quotePriceFeed_.isContract())
      revert AddressIsNotContractException(quotePriceFeed_); // F:[PO-2]

    uint8 decimals = AggregatorV3Interface(quotePriceFeed_).decimals();

    if (decimals != 8) revert IncorrectPriceFeedException(); // F:[PO-2]

    try AggregatorV3Interface(quotePriceFeed_).latestRoundData() returns (
      uint80 roundID,
      int256 price,
      uint256,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
      // Checks result
      _checkAnswer(roundID, price, updatedAt, answeredInRound);
    } catch {
      revert IncorrectPriceFeedException(); // F:[PO-2]
    }

    quotePriceFeed = AggregatorV3Interface(quotePriceFeed_);
    quotePriceFeedDecimals = decimals;

    emit ChangedQuotePriceFeed(quotePriceFeed_, decimals); // F:[PO-3]
  }

  // slither-disable-end uninitialized-local,unused-return,calls-loop

  /// @inheritdoc IPriceOracle
  function addPriceFeed(address token, address priceFeed) external onlyOwner {
    _addPriceFeed(token, priceFeed);
  }

  // slither-disable-start uninitialized-local,unused-return,calls-loop,cyclomatic-complexity
  /// @dev IMPLEMENTATION: addPriceFeed
  /// @param token Address of the token to set the price feed for
  /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
  function _addPriceFeed(address token, address priceFeed) internal {
    if (token == address(0) || priceFeed == address(0))
      revert ZeroAddressException(); // F:[PO-2]

    if (!token.isContract()) revert AddressIsNotContractException(token); // F:[PO-2]

    if (!priceFeed.isContract())
      revert AddressIsNotContractException(priceFeed); // F:[PO-2]

    try AggregatorV3Interface(priceFeed).decimals() returns (uint8 _decimals) {
      if (_decimals != 8) revert IncorrectPriceFeedException(); // F:[PO-2]
    } catch {
      revert IncorrectPriceFeedException(); // F:[PO-2]
    }

    bool skipCheck;

    try IPriceFeedType(priceFeed).skipPriceCheck() returns (bool property) {
      skipCheck = property; // F:[PO-2]
    } catch {}

    uint8 decimals;
    try ERC20(token).decimals() returns (uint8 _decimals) {
      if (_decimals > 18) revert IncorrectTokenContractException(); // F:[PO-2]

      decimals = _decimals; // F:[PO-3]
    } catch {
      revert IncorrectTokenContractException(); // F:[PO-2]
    }

    try AggregatorV3Interface(priceFeed).latestRoundData() returns (
      uint80 roundID,
      int256 price,
      uint256,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
      // Checks result if skipCheck is not set
      if (!skipCheck) _checkAnswer(roundID, price, updatedAt, answeredInRound);
    } catch {
      revert IncorrectPriceFeedException(); // F:[PO-2]
    }

    _setPriceFeedWithFlags(token, priceFeed, skipCheck, decimals);

    emit NewPriceFeed(token, priceFeed); // F:[PO-3]
  }

  // slither-disable-end uninitialized-local,unused-return,calls-loop,cyclomatic-complexity

  /// @inheritdoc IPriceOracle
  function getPrice(
    address token
  ) public view override returns (uint256 price) {
    (price, ) = _getPrice(token);
  }

  /// @dev IMPLEMENTATION: getPrice
  function _getPrice(
    address token
  ) internal view returns (uint256 price, uint256 decimals) {
    address priceFeed;

    bool skipCheck;

    (priceFeed, skipCheck, decimals) = priceFeedsWithFlags(token); //

    // slither-disable-start unused-return
    (
      uint80 roundID,
      int256 _price,
      ,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = AggregatorV3Interface(priceFeed).latestRoundData(); // F:[PO-6]
    // slither-disable-end unused-return

    // Checks if SKIP_PRICE_CHECK_FLAG is not set
    if (!skipCheck) _checkAnswer(roundID, _price, updatedAt, answeredInRound); // F:[PO-5]

    price = (uint256(_price)); // F:[PO-6]
  }

  /// @inheritdoc IPriceOracle
  function convertToUSD(
    uint256 amount,
    address token
  ) public view override returns (uint256) {
    (uint256 price, uint256 decimals) = _getPrice(token);

    return (amount * price) / (10 ** decimals); // F:[PO-7]
  }

  /// @inheritdoc IPriceOracle
  function convertFromUSD(
    uint256 amount,
    address token
  ) public view override returns (uint256) {
    (uint256 price, uint256 decimals) = _getPrice(token);

    return (amount * (10 ** decimals)) / price; // F:[PO-7]
  }

  /// @inheritdoc IPriceOracle
  function convert(
    uint256 amount,
    address tokenFrom,
    address tokenTo
  ) public view override returns (uint256) {
    return convertFromUSD(convertToUSD(amount, tokenFrom), tokenTo); // F:[PO-8]
  }

  /// @inheritdoc IPriceOracle
  function getPriceInDerivedFiat(
    address token
  ) public view override returns (uint256 price) {
    (price, ) = _getPriceInDerivedFiat(token);
  }

  /// @dev IMPLEMENTATION: getPriceInDerivedFiat
  /// @dev Further audit this function later
  function _getPriceInDerivedFiat(
    address token
  ) internal view returns (uint256 price, uint256 decimals) {
    int256 decimals_ = int256(10 ** uint256(8));

    address priceFeed;

    bool skipCheck;

    (priceFeed, skipCheck, decimals) = priceFeedsWithFlags(token); //

    // slither-disable-start unused-return
    (
      uint80 baseRoundID,
      int256 basePrice,
      ,
      uint256 baseUpdatedAt,
      uint80 baseAnsweredInRound
    ) = AggregatorV3Interface(priceFeed).latestRoundData(); // F:[PO-6]

    // Checks if SKIP_PRICE_CHECK_FLAG is not set
    if (!skipCheck)
      _checkAnswer(baseRoundID, basePrice, baseUpdatedAt, baseAnsweredInRound); // F:[PO-5]

    uint8 baseDecimals = AggregatorV3Interface(priceFeed).decimals();

    basePrice = _scalePrice(basePrice, baseDecimals, 8); // F:[PO-6]

    (
      uint80 quoteRoundID,
      int256 quotePrice,
      ,
      uint256 quoteUpdatedAt,
      uint80 quoteAnsweredInRound
    ) = AggregatorV3Interface(address(quotePriceFeed)).latestRoundData(); // F:[PO-6]
    // slither-disable-end unused-return

    // Checks
    _checkAnswer(
      quoteRoundID,
      quotePrice,
      quoteUpdatedAt,
      quoteAnsweredInRound
    ); // F:[PO-5]

    uint8 quoteDecimals = quotePriceFeedDecimals;

    quotePrice = _scalePrice(quotePrice, quoteDecimals, 8);

    price = uint256((basePrice * decimals_) / quotePrice);
  }

  /// @dev Further audit this function later
  function _scalePrice(
    int256 _price,
    uint8 _priceDecimals,
    uint8 _decimals
  ) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * int256(10 ** uint256(_decimals - _priceDecimals));
    } else if (_priceDecimals > _decimals) {
      return _price / int256(10 ** uint256(_priceDecimals - _decimals));
    }
    return _price;
  }

  /// @inheritdoc IPriceOracle
  function convertToDerivedFiat(
    uint256 amount,
    address token
  ) public view override returns (uint256) {
    (uint256 price, uint256 decimals) = _getPriceInDerivedFiat(token);

    return (amount * price) / (10 ** decimals); // F:[PO-7]
  }

  /// @inheritdoc IPriceOracle
  function convertFromDerivedFiat(
    uint256 amount,
    address token
  ) public view override returns (uint256) {
    (uint256 price, uint256 decimals) = _getPriceInDerivedFiat(token);

    return (amount * (10 ** decimals)) / price; // F:[PO-7]
  }

  /// @inheritdoc IPriceOracle
  function convertInDerivedFiat(
    uint256 amount,
    address tokenFrom,
    address tokenTo
  ) public view override returns (uint256) {
    return
      convertFromDerivedFiat(convertToDerivedFiat(amount, tokenFrom), tokenTo); // F:[PO-8]
  }

  /// @inheritdoc IPriceOracle
  function priceFeeds(
    address token
  ) external view override returns (address priceFeed) {
    (priceFeed, , ) = priceFeedsWithFlags(token); // F:[PO-3]
  }

  /// @inheritdoc IPriceOracle
  function priceFeedsWithFlags(
    address token
  )
    public
    view
    override
    returns (address priceFeed, bool skipCheck, uint256 decimals)
  {
    uint256 pf = priceFeedsList[token]; // F:[PO-3]

    if (pf == 0) revert PriceOracleNotExistsException();

    priceFeed = address(uint160(pf)); // F:[PO-3]

    skipCheck = pf & SKIP_PRICE_CHECK_FLAG != 0; // F:[PO-3]

    decimals = pf >> DECIMALS_SHIFT;
  }

  /// @dev Encodes the price feed address with parameters into a uint256,
  ///      and saves it into a map
  /// @param token Address of the token to add the price feed for
  /// @param priceFeed Address of the price feed
  /// @param skipCheck Whether price feed result sanity checks should be skipped
  /// @param decimals Decimals for the price feed's result
  function _setPriceFeedWithFlags(
    address token,
    address priceFeed,
    bool skipCheck,
    uint8 decimals
  ) internal {
    uint256 value = uint160(priceFeed); // F:[PO-3]

    if (skipCheck) value |= SKIP_PRICE_CHECK_FLAG; // F:[PO-3]

    priceFeedsList[token] = value + (uint256(decimals) << DECIMALS_SHIFT); // F:[PO-3]
  }
}

// SPDX-License-Identifier: BUSL-1.1

// (c) Gearbox Holdings, 2022

// This code was largely inspired by Gearbox Protocol

pragma solidity 0.8.18;

import {IPriceOracleExceptions} from "../interfaces/IPriceOracle.sol";

/// @title Price Feed Checker
/// @author Gearbox
/// @notice Sanity checker for Chainlink price feed results
/// @dev All function calls are currently implemented
/// @custom:security-contact [email protected]
contract PriceFeedChecker is IPriceOracleExceptions {
  function _checkAnswer(
    uint80 roundID,
    int256 price,
    uint256 updatedAt,
    uint80 answeredInRound
  ) internal pure {
    if (price <= 0) revert ZeroPriceException(); // F:[PO-5]
    if (answeredInRound < roundID || updatedAt == 0)
      revert ChainPriceStaleException(); // F:[PO-5]
  }
}