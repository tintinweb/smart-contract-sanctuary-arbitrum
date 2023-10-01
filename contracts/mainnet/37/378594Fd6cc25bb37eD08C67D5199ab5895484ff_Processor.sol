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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../stores/DataStore.sol';
import '../stores/FundingStore.sol';
import '../stores/MarketStore.sol';
import '../stores/PositionStore.sol';

import '../utils/Roles.sol';

/**
 * @title  Funding
 * @notice Funding rates are calculated hourly for each market and collateral
 *         asset based on the real-time open interest imbalance
 */
contract Funding is Roles {
    // Events
    event FundingUpdated(address indexed asset, string market, int256 fundingTracker, int256 fundingIncrement);

    // Constants
    uint256 public constant UNIT = 10 ** 18;

    // Contracts
    DataStore public DS;
    FundingStore public fundingStore;
    MarketStore public marketStore;
    PositionStore public positionStore;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        fundingStore = FundingStore(DS.getAddress('FundingStore'));
        marketStore = MarketStore(DS.getAddress('MarketStore'));
        positionStore = PositionStore(DS.getAddress('PositionStore'));
    }

    /// @notice Updates funding tracker of `market` and `asset`
    /// @dev Only callable by other protocol contracts
    function updateFundingTracker(address asset, string calldata market) external onlyContract {
        uint256 lastUpdated = fundingStore.getLastUpdated(asset, market);
        uint256 _now = block.timestamp;

        // condition is true only on the very first execution
        if (lastUpdated == 0) {
            fundingStore.setLastUpdated(asset, market, _now);
            return;
        }

        // returns if block.timestamp - lastUpdated is less than funding interval
        if (lastUpdated + fundingStore.fundingInterval() > _now) return;

        // positive funding increment indicates that shorts pay longs, negative that longs pay shorts
        int256 fundingIncrement = getAccruedFunding(asset, market, 0); // in UNIT * bps

        // return if funding increment is zero
        if (fundingIncrement == 0) return;

        fundingStore.updateFundingTracker(asset, market, fundingIncrement);
        fundingStore.setLastUpdated(asset, market, _now);

        emit FundingUpdated(asset, market, fundingStore.getFundingTracker(asset, market), fundingIncrement);
    }

    /// @notice Returns accrued funding of `market` and `asset`
    function getAccruedFunding(address asset, string memory market, uint256 intervals) public view returns (int256) {
        if (intervals == 0) {
            intervals = (block.timestamp - fundingStore.getLastUpdated(asset, market)) / fundingStore.fundingInterval();
        }

        if (intervals == 0) return 0;

        uint256 OILong = positionStore.getOILong(asset, market);
        uint256 OIShort = positionStore.getOIShort(asset, market);

        if (OIShort == 0 && OILong == 0) return 0;

        uint256 OIDiff = OIShort > OILong ? OIShort - OILong : OILong - OIShort;

        MarketStore.Market memory marketInfo = marketStore.get(market);
        uint256 yearlyFundingFactor = marketInfo.fundingFactor;

        uint256 accruedFunding = (UNIT * yearlyFundingFactor * OIDiff * intervals) / (24 * 365 * (OILong + OIShort)); // in UNIT * bps

        if (OILong > OIShort) {
            // Longs pay shorts. Increase funding tracker.
            return int256(accruedFunding);
        } else {
            // Shorts pay longs. Decrease funding tracker.
            return -1 * int256(accruedFunding);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/OrderStore.sol';
import '../stores/MarketStore.sol';
import '../stores/RiskStore.sol';

import '../utils/Chainlink.sol';
import '../utils/Roles.sol';

/**
 * @title  Orders
 * @notice Implementation of order related logic, i.e. submitting orders / cancelling them
 */
contract Orders is Roles {

    // Libraries
    using Address for address payable;

    // Constants
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;

    // Events

    // Order of function / event params: id, user, asset, market
    event OrderCreated(
        uint256 indexed orderId,
        address indexed user,
        address indexed asset,
        string market,
        uint256 margin,
        uint256 size,
        uint256 price,
        uint256 fee,
        bool isLong,
        uint8 orderType,
        bool isReduceOnly,
        uint256 expiry,
        uint256 cancelOrderId
    );

    event OrderCancelled(uint256 indexed orderId, address indexed user, string reason);

    // Contracts
    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    MarketStore public marketStore;
    OrderStore public orderStore;
    RiskStore public riskStore;

    Chainlink public chainlink;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @dev Reverts if new orders are paused
    modifier ifNotPaused() {
        require(!orderStore.areNewOrdersPaused(), '!paused');
        _;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        marketStore = MarketStore(DS.getAddress('MarketStore'));
        orderStore = OrderStore(DS.getAddress('OrderStore'));
        riskStore = RiskStore(DS.getAddress('RiskStore'));
        chainlink = Chainlink(DS.getAddress('Chainlink'));
    }

    /// @notice Submits a new order
    /// @param params Order to submit
    /// @param tpPrice 18 decimal take profit price
    /// @param slPrice 18 decimal stop loss price
    function submitOrder(
        OrderStore.Order memory params,
        uint256 tpPrice,
        uint256 slPrice
    ) external payable ifNotPaused {
        // order cant be reduce-only if take profit or stop loss order is submitted alongside main order
        if (tpPrice > 0 || slPrice > 0) {
            params.isReduceOnly = false;
        }

        // Submit order
        uint256 valueConsumed;
        (, valueConsumed) = _submitOrder(params);

        // tp/sl price checks
        if (tpPrice > 0 || slPrice > 0) {
            if (params.price > 0) {
                if (tpPrice > 0) {
                    require(
                        (params.isLong && tpPrice > params.price) || (!params.isLong && tpPrice < params.price),
                        '!tp-invalid'
                    );
                }
                if (slPrice > 0) {
                    require(
                        (params.isLong && slPrice < params.price) || (!params.isLong && slPrice > params.price),
                        '!sl-invalid'
                    );
                }
            }

            if (tpPrice > 0 && slPrice > 0) {
                require((params.isLong && tpPrice > slPrice) || (!params.isLong && tpPrice < slPrice), '!tpsl-invalid');
            }

            // tp and sl order ids
            uint256 tpOrderId;
            uint256 slOrderId;

            // long -> short, short -> long for take profit / stop loss order
            params.isLong = !params.isLong;

            // reset order expiry for TP/SL orders
            if (params.expiry > 0) params.expiry = 0;

            // submit take profit order
            if (tpPrice > 0) {
                params.price = tpPrice;
                params.orderType = 1;
                params.isReduceOnly = true;

                // Order is reduce-only so valueConsumed is always zero
                (tpOrderId, ) = _submitOrder(params);
            }

            // submit stop loss order
            if (slPrice > 0) {
                params.price = slPrice;
                params.orderType = 2;
                params.isReduceOnly = true;

                // Order is reduce-only so valueConsumed is always zero
                (slOrderId, ) = _submitOrder(params);
            }

            // Update orders to cancel each other
            if (tpOrderId > 0 && slOrderId > 0) {
                orderStore.updateCancelOrderId(tpOrderId, slOrderId);
                orderStore.updateCancelOrderId(slOrderId, tpOrderId);
            }
        }

        // Refund msg.value excess, if any
        if (params.asset == address(0)) {
            uint256 diff = msg.value - valueConsumed;
            if (diff > 0) {
                payable(msg.sender).sendValue(diff);
            }
        }
    }

    /// @notice Submits a new order
    /// @dev Internal function invoked by {submitOrder}
    function _submitOrder(OrderStore.Order memory params) internal returns (uint256, uint256) {
        // Set user and timestamp
        params.user = msg.sender;
        params.timestamp = block.timestamp;

        // Validations
        require(params.orderType == 0 || params.orderType == 1 || params.orderType == 2, '!order-type');

        // execution price of trigger order cant be zero
        if (params.orderType != 0) {
            require(params.price > 0, '!price');
        }

        // check if base asset is supported and order size is above min size
        AssetStore.Asset memory asset = assetStore.get(params.asset);
        require(asset.minSize > 0, '!asset-exists');
        require(params.size >= asset.minSize, '!min-size');

        // check if market exists
        MarketStore.Market memory market = marketStore.get(params.market);
        require(market.maxLeverage > 0, '!market-exists');

        // Order expiry validations
        if (params.expiry > 0) {
            // expiry value cant be in the past
            require(params.expiry >= block.timestamp, '!expiry-value');

            // params.expiry cant be after default expiry of market and trigger orders
            uint256 ttl = params.expiry - block.timestamp;
            if (params.orderType == 0) require(ttl <= orderStore.maxMarketOrderTTL(), '!max-expiry');
            else require(ttl <= orderStore.maxTriggerOrderTTL(), '!max-expiry');
        }

        // cant cancel an order of another user
        if (params.cancelOrderId > 0) {
            require(orderStore.isUserOrder(params.cancelOrderId, params.user), '!user-oco');
        }

        params.fee = (params.size * market.fee) / BPS_DIVIDER;
        uint256 valueConsumed;

        if (params.isReduceOnly) {
            params.margin = 0;
            // Existing position is checked on execution so TP/SL can be submitted as reduce-only alongside a non-executed order
            // In this case, valueConsumed is zero as margin is zero and fee is taken from the order's margin when position is executed
        } else {
            require(!market.isReduceOnly, '!market-reduce-only');
            require(params.margin > 0, '!margin');

            uint256 leverage = (UNIT * params.size) / params.margin;
            require(leverage >= UNIT, '!min-leverage');
            require(leverage <= market.maxLeverage * UNIT, '!max-leverage');

            // Check against max OI if it's not reduce-only. this is not completely fail safe as user can place many
            // consecutive market orders of smaller size and get past the max OI limit here, because OI is not updated until
            // keeper picks up the order. That is why maxOI is checked on processing as well, which is fail safe.
            // This check is more of preemptive for user to not submit an order
            riskStore.checkMaxOI(params.asset, params.market, params.size);

            // Transfer fee and margin to store
            valueConsumed = params.margin + params.fee;

            if (params.asset == address(0)) {
                fundStore.transferIn{value: valueConsumed}(params.asset, params.user, valueConsumed);
            } else {
                fundStore.transferIn(params.asset, params.user, valueConsumed);
            }
        }

        // Add order to store and emit event
        params.orderId = orderStore.add(params);

        emit OrderCreated(
            params.orderId,
            params.user,
            params.asset,
            params.market,
            params.margin,
            params.size,
            params.price,
            params.fee,
            params.isLong,
            params.orderType,
            params.isReduceOnly,
            params.expiry,
            params.cancelOrderId
        );

        return (params.orderId, valueConsumed);
    }

    /// @notice Cancels order
    /// @param orderId Order to cancel
    function cancelOrder(uint256 orderId) external ifNotPaused {
        OrderStore.Order memory order = orderStore.get(orderId);
        require(order.size > 0, '!order');
        require(order.user == msg.sender, '!user');
        _cancelOrder(orderId, 'by-user');
    }

    /// @notice Cancel several orders
    /// @param orderIds Array of orderIds to cancel
    function cancelOrders(uint256[] calldata orderIds) external ifNotPaused {
        for (uint256 i = 0; i < orderIds.length; i++) {
            OrderStore.Order memory order = orderStore.get(orderIds[i]);
            if (order.size > 0 && order.user == msg.sender) {
                _cancelOrder(orderIds[i], 'by-user');
            }
        }
    }

    /// @notice Cancels order
    /// @dev Only callable by other protocol contracts
    /// @param orderId Order to cancel
    /// @param reason Cancellation reason
    function cancelOrder(uint256 orderId, string calldata reason) external onlyContract {
        _cancelOrder(orderId, reason);
    }

    /// @notice Cancel several orders
    /// @dev Only callable by other protocol contracts
    /// @param orderIds Order ids to cancel
    /// @param reasons Cancellation reasons
    function cancelOrders(uint256[] calldata orderIds, string[] calldata reasons) external onlyContract {
        for (uint256 i = 0; i < orderIds.length; i++) {
            _cancelOrder(orderIds[i], reasons[i]);
        }
    }

    /// @notice Cancels order
    /// @dev Internal function without access restriction
    /// @param orderId Order to cancel
    /// @param reason Cancellation reason
    function _cancelOrder(uint256 orderId, string memory reason) internal {
        OrderStore.Order memory order = orderStore.get(orderId);
        if (order.size == 0) return;

        orderStore.remove(orderId);

        if (!order.isReduceOnly) {
            fundStore.transferOut(order.asset, order.user, order.margin + order.fee);
        }

        emit OrderCancelled(orderId, order.user, reason);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/PoolStore.sol';

import '../utils/Roles.sol';

/**
 * @title  Pool
 * @notice Users can deposit supported assets to back trader profits and receive
 *         a share of trader losses. Each asset pool is siloed, e.g. the ETH
 *         pool is independent from the USDC pool.
 */
contract Pool is Roles {
    // Constants
    uint256 public constant BPS_DIVIDER = 10000;

    // Events
    event PoolDeposit(
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 clpAmount,
        uint256 poolBalance
    );

    event PoolWithdrawal(
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 feeAmount,
        uint256 clpAmount,
        uint256 poolBalance
    );

    event PoolPayIn(
        address indexed user,
        address indexed asset,
        string market,
        uint256 amount,
        uint256 bufferToPoolAmount,
        uint256 poolBalance,
        uint256 bufferBalance
    );

    event PoolPayOut(
        address indexed user,
        address indexed asset,
        string market,
        uint256 amount,
        uint256 poolBalance,
        uint256 bufferBalance
    );

    // Contracts
    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    PoolStore public poolStore;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        poolStore = PoolStore(DS.getAddress('PoolStore'));
    }

    /// @notice Credit trader loss to buffer and pay pool from buffer amount based on time and payout rate
    /// @param user User which incurred trading loss
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    /// @param amount Amount of trader loss
    function creditTraderLoss(address user, address asset, string memory market, uint256 amount) external onlyContract {
        // credit trader loss to buffer
        poolStore.incrementBufferBalance(asset, amount);

        // local variables
        uint256 lastPaid = poolStore.getLastPaid(asset);
        uint256 _now = block.timestamp;
        uint256 amountToSendPool;

        if (lastPaid == 0) {
            // during the very first execution, set lastPaid and return
            poolStore.setLastPaid(asset, _now);
        } else {
            // get buffer balance and buffer payout period to calculate amountToSendPool
            uint256 bufferBalance = poolStore.getBufferBalance(asset);
            uint256 bufferPayoutPeriod = poolStore.bufferPayoutPeriod();

            // Stream buffer balance progressively into the pool
            amountToSendPool = (bufferBalance * (block.timestamp - lastPaid)) / bufferPayoutPeriod;
            if (amountToSendPool > bufferBalance) amountToSendPool = bufferBalance;

            // update storage
            poolStore.incrementBalance(asset, amountToSendPool);
            poolStore.decrementBufferBalance(asset, amountToSendPool);
            poolStore.setLastPaid(asset, _now);
        }

        // emit event
        emit PoolPayIn(
            user,
            asset,
            market,
            amount,
            amountToSendPool,
            poolStore.getBalance(asset),
            poolStore.getBufferBalance(asset)
        );
    }

    /// @notice Pay out trader profit, from buffer first then pool if buffer is depleted
    /// @param user Address to send funds to
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    /// @param amount Amount of trader profit
    function debitTraderProfit(
        address user,
        address asset,
        string calldata market,
        uint256 amount
    ) external onlyContract {
        // return if profit = 0
        if (amount == 0) return;

        uint256 bufferBalance = poolStore.getBufferBalance(asset);

        // decrement buffer balance first
        poolStore.decrementBufferBalance(asset, amount);

        // if amount is greater than available in the buffer, pay remaining from the pool
        if (amount > bufferBalance) {
            uint256 diffToPayFromPool = amount - bufferBalance;
            uint256 poolBalance = poolStore.getBalance(asset);
            require(diffToPayFromPool < poolBalance, '!pool-balance');
            poolStore.decrementBalance(asset, diffToPayFromPool);
        }

        // transfer profit out
        fundStore.transferOut(asset, user, amount);

        // emit event
        emit PoolPayOut(user, asset, market, amount, poolStore.getBalance(asset), poolStore.getBufferBalance(asset));
    }

    /// @notice Deposit 'amount' of 'asset' into the pool
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param amount Amount to be deposited
    function deposit(address asset, uint256 amount) public payable {
        require(amount > 0, '!amount');
        require(assetStore.isSupported(asset), '!asset');

        uint256 balance = poolStore.getBalance(asset);
        address user = msg.sender;

        // if asset is ETH (address(0)), set amount to msg.value
        if (asset == address(0)) {
            amount = msg.value;
            fundStore.transferIn{value: amount}(asset, user, amount);
        } else {
            fundStore.transferIn(asset, user, amount);
        }

        // pool share is equal to pool balance of user divided by the total balance
        uint256 clpSupply = poolStore.getClpSupply(asset);
        uint256 clpAmount = balance == 0 || clpSupply == 0 ? amount : (amount * clpSupply) / balance;

        // increment balances
        poolStore.incrementUserClpBalance(asset, user, clpAmount);
        poolStore.incrementBalance(asset, amount);

        // emit event
        emit PoolDeposit(user, asset, amount, clpAmount, poolStore.getBalance(asset));
    }

    /// @notice Withdraw 'amount' of 'asset'
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param amount Amount to be withdrawn
    function withdraw(address asset, uint256 amount) public {
        require(amount > BPS_DIVIDER, '!amount');
        require(assetStore.isSupported(asset), '!asset');

        address user = msg.sender;

        // check pool balance and clp supply
        uint256 balance = poolStore.getBalance(asset);
        uint256 clpSupply = poolStore.getClpSupply(asset);
        require(balance > 0 && clpSupply > 0, '!empty');

        // check user balance
        uint256 userBalance = poolStore.getUserBalance(asset, user);
        if (amount > userBalance) amount = userBalance;

        // calculate pool withdrawal fee
        uint256 feeAmount = (amount * poolStore.getWithdrawalFee(asset)) / BPS_DIVIDER;
        uint256 amountMinusFee = amount - feeAmount;

        // CLP amount
        uint256 clpAmount = (amount * clpSupply) / balance;

        // decrement balances
        poolStore.decrementUserClpBalance(asset, user, clpAmount);
        poolStore.decrementBalance(asset, amountMinusFee);

        // transfer funds out
        fundStore.transferOut(asset, user, amountMinusFee);

        // emit event
        emit PoolWithdrawal(user, asset, amount, feeAmount, clpAmount, poolStore.getBalance(asset));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/FundingStore.sol';
import '../stores/MarketStore.sol';
import '../stores/OrderStore.sol';
import '../stores/PoolStore.sol';
import '../stores/PositionStore.sol';
import '../stores/RiskStore.sol';
import '../stores/StakingStore.sol';

import './Funding.sol';
import './Pool.sol';

import '../utils/Chainlink.sol';
import '../utils/Roles.sol';

/**
 * @title  Positions
 * @notice Implementation of position related logic, i.e. increase positions,
 *         decrease positions, close positions, add/remove margin
 */
contract Positions is Roles {

    // Constants
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant BPS_DIVIDER = 10000;

    // Events
    event PositionIncreased(
        uint256 indexed orderId,
        address indexed user,
        address indexed asset,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 price,
        uint256 positionMargin,
        uint256 positionSize,
        uint256 positionPrice,
        int256 fundingTracker,
        uint256 fee
    );

    event PositionDecreased(
        uint256 indexed orderId,
        address indexed user,
        address indexed asset,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 price,
        uint256 positionMargin,
        uint256 positionSize,
        uint256 positionPrice,
        int256 fundingTracker,
        uint256 fee,
        int256 pnl,
        int256 pnlUsd,
        int256 fundingFee
    );

    event MarginIncreased(
        address indexed user,
        address indexed asset,
        string market,
        uint256 marginDiff,
        uint256 positionMargin
    );

    event MarginDecreased(
        address indexed user,
        address indexed asset,
        string market,
        uint256 marginDiff,
        uint256 positionMargin
    );

    event FeePaid(
        uint256 indexed orderId,
        address indexed user,
        address indexed asset,
        string market,
        uint256 fee,
        uint256 poolFee,
        uint256 stakingFee,
        uint256 treasuryFee,
        uint256 keeperFee,
        bool isLiquidation
    );

    // Contracts
    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    FundingStore public fundingStore;
    MarketStore public marketStore;
    OrderStore public orderStore;
    PoolStore public poolStore;
    PositionStore public positionStore;
    RiskStore public riskStore;
    StakingStore public stakingStore;

    Funding public funding;
    Pool public pool;

    Chainlink public chainlink;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @dev Reverts if new orders are paused
    modifier ifNotPaused() {
        require(!orderStore.areNewOrdersPaused(), '!paused');
        _;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        fundingStore = FundingStore(DS.getAddress('FundingStore'));
        marketStore = MarketStore(DS.getAddress('MarketStore'));
        orderStore = OrderStore(DS.getAddress('OrderStore'));
        poolStore = PoolStore(DS.getAddress('PoolStore'));
        positionStore = PositionStore(DS.getAddress('PositionStore'));
        riskStore = RiskStore(DS.getAddress('RiskStore'));
        stakingStore = StakingStore(DS.getAddress('StakingStore'));
        funding = Funding(DS.getAddress('Funding'));
        pool = Pool(DS.getAddress('Pool'));
        chainlink = Chainlink(DS.getAddress('Chainlink'));
    }

    /// @notice Opens a new position or increases existing one
    /// @dev Only callable by other protocol contracts
    function increasePosition(uint256 orderId, uint256 price, address keeper) public onlyContract {
        OrderStore.Order memory order = orderStore.get(orderId);

        // Check if maximum open interest is reached
        riskStore.checkMaxOI(order.asset, order.market, order.size);
        positionStore.incrementOI(order.asset, order.market, order.size, order.isLong);
        funding.updateFundingTracker(order.asset, order.market);

        PositionStore.Position memory position = positionStore.getPosition(order.user, order.asset, order.market);
        uint256 averagePrice = (position.size * position.price + order.size * price) / (position.size + order.size);

        // Populate position fields if new position
        if (position.size == 0) {
            position.user = order.user;
            position.asset = order.asset;
            position.market = order.market;
            position.timestamp = block.timestamp;
            position.isLong = order.isLong;
            position.fundingTracker = fundingStore.getFundingTracker(order.asset, order.market);
        }

        // Add or update position
        position.size += order.size;
        position.margin += order.margin;
        position.price = averagePrice;

        positionStore.addOrUpdate(position);

        // Remove order
        orderStore.remove(orderId);

        // Credit fee to keeper, pool, stakers, treasury
        creditFee(orderId, order.user, order.asset, order.market, order.fee, false, keeper);

        emit PositionIncreased(
            orderId,
            order.user,
            order.asset,
            order.market,
            order.isLong,
            order.size,
            order.margin,
            price,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            order.fee
        );
    }

    /// @notice Decreases or closes an existing position
    /// @dev Only callable by other protocol contracts
    function decreasePosition(uint256 orderId, uint256 price, address keeper) external onlyContract {
        OrderStore.Order memory order = orderStore.get(orderId);
        PositionStore.Position memory position = positionStore.getPosition(order.user, order.asset, order.market);

        // If position size is less than order size, not all will be executed
        uint256 executedOrderSize = position.size > order.size ? order.size : position.size;
        uint256 remainingOrderSize = order.size - executedOrderSize;

        uint256 remainingOrderMargin;
        uint256 amountToReturnToUser;

        if (!order.isReduceOnly) {
            // User submitted order.margin when sending the order. Refund the portion of order.margin
            // that executes against the position
            uint256 executedOrderMargin = (order.margin * executedOrderSize) / order.size;
            amountToReturnToUser += executedOrderMargin;
            remainingOrderMargin = order.margin - executedOrderMargin;
        }

        // Calculate fee based on executed order size
        uint256 fee = (order.fee * executedOrderSize) / order.size;

        creditFee(orderId, order.user, order.asset, order.market, fee, false, keeper);

        // If an order is reduce-only, fee is taken from the position's margin.
        uint256 feeToPay = order.isReduceOnly ? fee : 0;

        // Funding update
        positionStore.decrementOI(order.asset, order.market, order.size, position.isLong);
        funding.updateFundingTracker(order.asset, order.market);

        // Get PNL of position
        (int256 pnl, int256 fundingFee) = getPnL(
            order.asset,
            order.market,
            position.isLong,
            price,
            position.price,
            executedOrderSize,
            position.fundingTracker
        );

        uint256 executedPositionMargin = (position.margin * executedOrderSize) / position.size;

        // If PNL is less than position margin, close position, else update position
        if (pnl <= -1 * int256(position.margin)) {
            pnl = -1 * int256(position.margin);
            executedPositionMargin = position.margin;
            executedOrderSize = position.size;
            position.size = 0;
        } else {
            position.margin -= executedPositionMargin;
            position.size -= executedOrderSize;
            position.fundingTracker = fundingStore.getFundingTracker(order.asset, order.market);
        }

        // Check for maximum pool drawdown
        riskStore.checkPoolDrawdown(order.asset, pnl);

        // Credit trader loss or debit trader profit based on pnl
        if (pnl < 0) {
            uint256 absPnl = uint256(-1 * pnl);
            pool.creditTraderLoss(order.user, order.asset, order.market, absPnl);

            uint256 totalPnl = absPnl + feeToPay;

            // If an order is reduce-only, fee is taken from the position's margin as the order's margin is zero.
            if (totalPnl < executedPositionMargin) {
                amountToReturnToUser += executedPositionMargin - totalPnl;
            }
        } else {
            pool.debitTraderProfit(order.user, order.asset, order.market, uint256(pnl));

            // If an order is reduce-only, fee is taken from the position's margin as the order's margin is zero.
            amountToReturnToUser += executedPositionMargin - feeToPay;
        }

        if (position.size == 0) {
            // Remove position if size == 0
            positionStore.remove(order.user, order.asset, order.market);
        } else {
            positionStore.addOrUpdate(position);
        }

        // Remove order and transfer funds out
        orderStore.remove(orderId);
        fundStore.transferOut(order.asset, order.user, amountToReturnToUser);

        emit PositionDecreased(
            orderId,
            order.user,
            order.asset,
            order.market,
            order.isLong,
            executedOrderSize,
            executedPositionMargin,
            price,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            feeToPay,
            pnl,
            _getUsdAmount(order.asset, pnl),
            fundingFee
        );

        // Open position in opposite direction if size remains
        if (!order.isReduceOnly && remainingOrderSize > 0) {
            OrderStore.Order memory nextOrder = OrderStore.Order({
                orderId: 0,
                user: order.user,
                market: order.market,
                asset: order.asset,
                margin: remainingOrderMargin,
                size: remainingOrderSize,
                price: 0,
                isLong: order.isLong,
                fee: (order.fee * remainingOrderSize) / order.size,
                orderType: 0,
                isReduceOnly: false,
                timestamp: block.timestamp,
                expiry: 0,
                cancelOrderId: 0
            });

            uint256 nextOrderId = orderStore.add(nextOrder);

            increasePosition(nextOrderId, price, keeper);
        }
    }

    /// @notice Close position without taking profits to retrieve margin in black swan scenarios
    /// @dev Only works for chainlink supported markets
    function closePositionWithoutProfit(address _asset, string calldata _market) external {
        address user = msg.sender;

        // check if positions exists
        PositionStore.Position memory position = positionStore.getPosition(user, _asset, _market);
        require(position.size > 0, '!position');

        // update funding tracker
        positionStore.decrementOI(_asset, _market, position.size, position.isLong);
        funding.updateFundingTracker(_asset, _market);

        // This is not available for markets without Chainlink
        MarketStore.Market memory market = marketStore.get(_market);
        uint256 price = chainlink.getPrice(market.chainlinkFeed);
        require(price > 0, '!price');

        (int256 pnl, ) = getPnL(
            _asset,
            _market,
            position.isLong,
            price,
            position.price,
            position.size,
            position.fundingTracker
        );

        // Only profitable positions can be closed this way
        require(pnl >= 0, '!pnl-positive');

        // Remove position and transfer margin out
        positionStore.remove(user, _asset, _market);
        fundStore.transferOut(_asset, user, position.margin);

        emit PositionDecreased(
            0,
            user,
            _asset,
            _market,
            !position.isLong,
            position.size,
            position.margin,
            price,
            position.margin,
            position.size,
            position.price,
            position.fundingTracker,
            0,
            0,
            0,
            0
        );
    }

    /// @notice Add margin to a position to decrease its leverage and push away its liquidation price
    function addMargin(address asset, string calldata market, uint256 margin) external payable ifNotPaused {
        address user = msg.sender;

        PositionStore.Position memory position = positionStore.getPosition(user, asset, market);
        require(position.size > 0, '!position');

        // Transfer additional margin in
        if (asset == address(0)) {
            margin = msg.value;
            fundStore.transferIn{value: margin}(asset, user, margin);
        } else {
            fundStore.transferIn(asset, user, margin);
        }

        require(margin > 0, '!margin');

        // update position margin
        position.margin += margin;

        // Check if leverage is above minimum leverage
        uint256 leverage = (UNIT * position.size) / position.margin;
        require(leverage >= UNIT, '!min-leverage');

        // update position
        positionStore.addOrUpdate(position);

        emit MarginIncreased(user, asset, market, margin, position.margin);
    }

    /// @notice Remove margin from a position to increase its leverage
    /// @dev Margin removal is only available on markets supported by Chainlink
    function removeMargin(address asset, string calldata market, uint256 margin) external ifNotPaused {
        address user = msg.sender;

        MarketStore.Market memory marketInfo = marketStore.get(market);

        PositionStore.Position memory position = positionStore.getPosition(user, asset, market);
        require(position.size > 0, '!position');
        require(position.margin > margin, '!margin');

        uint256 remainingMargin = position.margin - margin;

        // Leverage
        uint256 leverageAfterRemoval = (UNIT * position.size) / remainingMargin;
        require(leverageAfterRemoval <= marketInfo.maxLeverage * UNIT, '!max-leverage');

        // This is not available for markets without Chainlink
        uint256 price = chainlink.getPrice(marketInfo.chainlinkFeed);
        require(price > 0, '!price');

        (int256 upl, ) = getPnL(
            asset,
            market,
            position.isLong,
            price,
            position.price,
            position.size,
            position.fundingTracker
        );

        if (upl < 0) {
            uint256 absUpl = uint256(-1 * upl);
            require(
                absUpl < (remainingMargin * (BPS_DIVIDER - positionStore.removeMarginBuffer())) / BPS_DIVIDER,
                '!upl'
            );
        }

        // Update position and transfer margin out
        position.margin = remainingMargin;
        positionStore.addOrUpdate(position);

        fundStore.transferOut(asset, user, margin);

        emit MarginDecreased(user, asset, market, margin, position.margin);
    }

    /// @notice Credit fee to Keeper, Pool, Stakers, and Treasury
    /// @dev Only callable by other protocol contracts
    function creditFee(
        uint256 orderId,
        address user,
        address asset,
        string memory market,
        uint256 fee,
        bool isLiquidation,
        address keeper
    ) public onlyContract {
        if (fee == 0) return;

        // multiply fee by UNIT (10^18) to increase position
        fee = fee * UNIT;

        uint256 keeperFee;
        if (keeper != address(0)) {
            keeperFee = (fee * positionStore.keeperFeeShare()) / BPS_DIVIDER;
        }

        // Calculate fees
        uint256 netFee = fee - keeperFee;
        uint256 feeToStaking = (netFee * stakingStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToPool = (netFee * poolStore.feeShare()) / BPS_DIVIDER;
        uint256 feeToTreasury = netFee - feeToStaking - feeToPool;

        // Increment balances, transfer fees out
        // Divide fee by UNIT to get original fee value back
        poolStore.incrementBalance(asset, feeToPool / UNIT);
        stakingStore.incrementPendingReward(asset, feeToStaking / UNIT);
        fundStore.transferOut(asset, DS.getAddress('treasury'), feeToTreasury / UNIT);
        fundStore.transferOut(asset, keeper, keeperFee / UNIT);

        emit FeePaid(
            orderId,
            user,
            asset,
            market,
            fee / UNIT, // paid by user
            feeToPool / UNIT,
            feeToStaking / UNIT,
            feeToTreasury / UNIT,
            keeperFee / UNIT,
            isLiquidation
        );
    }

    /// @notice Get pnl of a position
    /// @param asset Base asset of position
    /// @param market Market position was submitted on
    /// @param isLong Wether position is long or short
    /// @param price Current price of market
    /// @param positionPrice Average execution price of position
    /// @param size Positions size (margin * leverage) in wei
    /// @param fundingTracker Market funding rate tracker
    /// @return pnl Profit and loss of position
    /// @return fundingFee Funding fee of position
    function getPnL(
        address asset,
        string memory market,
        bool isLong,
        uint256 price,
        uint256 positionPrice,
        uint256 size,
        int256 fundingTracker
    ) public view returns (int256 pnl, int256 fundingFee) {
        if (price == 0 || positionPrice == 0 || size == 0) return (0, 0);

        if (isLong) {
            pnl = (int256(size) * (int256(price) - int256(positionPrice))) / int256(positionPrice);
        } else {
            pnl = (int256(size) * (int256(positionPrice) - int256(price))) / int256(positionPrice);
        }

        int256 currentFundingTracker = fundingStore.getFundingTracker(asset, market);
        fundingFee = (int256(size) * (currentFundingTracker - fundingTracker)) / (int256(BPS_DIVIDER) * int256(UNIT)); // funding tracker is in UNIT * bps

        if (isLong) {
            pnl -= fundingFee; // positive = longs pay, negative = longs receive
        } else {
            pnl += fundingFee; // positive = shorts receive, negative = shorts pay
        }

        return (pnl, fundingFee);
    }

    /// @dev Returns USD value of `amount` of `asset`
    /// @dev Used for PositionDecreased event
    function _getUsdAmount(address asset, int256 amount) internal view returns (int256) {
        AssetStore.Asset memory assetInfo = assetStore.get(asset);
        uint256 chainlinkPrice = chainlink.getPrice(assetInfo.chainlinkFeed);
        uint256 decimals = 18;
        if (asset != address(0)) {
            decimals = IERC20Metadata(asset).decimals();
        }
        // amount is in the asset's decimals, convert to 18. Price is 18 decimals
        return (amount * int256(chainlinkPrice)) / int256(10 ** decimals);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@pythnetwork/pyth-sdk-solidity/IPyth.sol';
import '@pythnetwork/pyth-sdk-solidity/PythStructs.sol';

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/MarketStore.sol';
import '../stores/OrderStore.sol';
import '../stores/PoolStore.sol';
import '../stores/PositionStore.sol';
import '../stores/RiskStore.sol';

import './Funding.sol';
import './Orders.sol';
import './Pool.sol';
import './Positions.sol';

import '../utils/Chainlink.sol';
import '../utils/Roles.sol';

/**
 * @title  Processor
 * @notice Implementation of order execution and position liquidation.
 *         Orders are settled on-demand by the Pyth network. Keepers, which
 *         anyone can run, execute orders as they are submitted to CAP's
 *         contracts using Pyth prices. Orders can also be self executed after
 *         a cooldown period
 */
contract Processor is Roles, ReentrancyGuard {
    // Libraries
    using Address for address payable;

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;

    // Events
    event LiquidationError(address user, address asset, string market, uint256 price, string reason);
    event PositionLiquidated(
        address indexed user,
        address indexed asset,
        string market,
        bool isLong,
        uint256 size,
        uint256 margin,
        uint256 marginUsd,
        uint256 price,
        uint256 fee
    );
    event OrderSkipped(uint256 indexed orderId, string market, uint256 price, uint256 publishTime, string reason);
    event UserSkipped(
        address indexed user,
        address indexed asset,
        string market,
        uint256 price,
        uint256 publishTime,
        string reason
    );

    // Contracts
    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    MarketStore public marketStore;
    OrderStore public orderStore;
    PoolStore public poolStore;
    PositionStore public positionStore;
    RiskStore public riskStore;

    Funding public funding;
    Orders public orders;
    Pool public pool;
    Positions public positions;

    Chainlink public chainlink;
    IPyth public pyth;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @dev Reverts if order processing is paused
    modifier ifNotPaused() {
        require(!orderStore.isProcessingPaused(), '!paused');
        _;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        marketStore = MarketStore(DS.getAddress('MarketStore'));
        orderStore = OrderStore(DS.getAddress('OrderStore'));
        poolStore = PoolStore(DS.getAddress('PoolStore'));
        positionStore = PositionStore(DS.getAddress('PositionStore'));
        riskStore = RiskStore(DS.getAddress('RiskStore'));
        funding = Funding(DS.getAddress('Funding'));
        pool = Pool(DS.getAddress('Pool'));
        orders = Orders(DS.getAddress('Orders'));
        positions = Positions(DS.getAddress('Positions'));
        chainlink = Chainlink(DS.getAddress('Chainlink'));
        pyth = IPyth(DS.getAddress('Pyth'));
    }

    // ORDER EXECUTION

    /// @notice Self execution of order using Chainlink (after a cooldown period)
    /// @dev Anyone can call this in case order isn't executed from keeper via {executeOrders}
    /// @param orderId order id to execute
    function selfExecuteOrder(uint256 orderId) external nonReentrant ifNotPaused {
        (bool status, string memory reason) = _executeOrder(orderId, 0, true, address(0));
        require(status, reason);
    }

    /// @notice Order execution by keeper (anyone) with Pyth priceUpdateData
    /// @param orderIds order id's to execute
    /// @param priceUpdateData Pyth priceUpdateData, see docs.pyth.network
    function executeOrders(
        uint256[] calldata orderIds,
        bytes[] calldata priceUpdateData
    ) external payable nonReentrant ifNotPaused {
        // updates price for all submitted price feeds
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        require(msg.value >= fee, '!fee');
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        // Get the price for each order
        for (uint256 i = 0; i < orderIds.length; i++) {
            OrderStore.Order memory order = orderStore.get(orderIds[i]);
            MarketStore.Market memory market = marketStore.get(order.market);

            if (block.timestamp - order.timestamp < market.minOrderAge) {
                // Order too early (front run prevention)
                emit OrderSkipped(orderIds[i], order.market, 0, 0, '!early');
                continue;
            }

            (uint256 price, uint256 publishTime) = _getPythPrice(market.pythFeed);

            if (block.timestamp - publishTime > market.pythMaxAge) {
                // Price too old
                emit OrderSkipped(orderIds[i], order.market, price, publishTime, '!stale');
                continue;
            }

            (bool status, string memory reason) = _executeOrder(orderIds[i], price, false, msg.sender);
            if (!status) orders.cancelOrder(orderIds[i], reason);
        }

        // Refund msg.value excess, if any
        if (msg.value > fee) {
            uint256 diff = msg.value - fee;
            payable(msg.sender).sendValue(diff);
        }
    }

    /// @dev Executes submitted order
    /// @param orderId Order to execute
    /// @param price Pyth price (0 if self-executed since Chainlink price will be used)
    /// @param withChainlink Wether to use Chainlink or not (i.e. if self executed or not)
    /// @param keeper Address of keeper which executes the order (address(0) if self execution)
    function _executeOrder(
        uint256 orderId,
        uint256 price,
        bool withChainlink,
        address keeper
    ) internal returns (bool, string memory) {
        OrderStore.Order memory order = orderStore.get(orderId);

        // Validations

        if (order.size == 0) {
            return (false, '!order');
        }

        if (order.expiry > 0 && order.expiry <= block.timestamp) {
            return (false, '!expired');
        }

        // cancel if order is too old
        // By default, market orders expire after 30 minutes and trigger orders after 180 days
        uint256 ttl = block.timestamp - order.timestamp;
        if ((order.orderType == 0 && ttl > orderStore.maxMarketOrderTTL()) || ttl > orderStore.maxTriggerOrderTTL()) {
            return (false, '!too-old');
        }

        MarketStore.Market memory market = marketStore.get(order.market);

        uint256 chainlinkPrice = chainlink.getPrice(market.chainlinkFeed);

        if (withChainlink) {
            if (chainlinkPrice == 0) {
                return (false, '!no-chainlink-price');
            }
            if (!market.allowChainlinkExecution) {
                return (false, '!chainlink-not-allowed');
            }
            if (order.timestamp > block.timestamp - orderStore.chainlinkCooldown()) {
                return (false, '!chainlink-cooldown');
            }
            price = chainlinkPrice;
        }

        if (price == 0) {
            return (false, '!no-price');
        }

        // Bound provided price with chainlink
        if (!_boundPriceWithChainlink(market.maxDeviation, chainlinkPrice, price)) {
            return (true, '!chainlink-deviation'); // returns true so as not to trigger order cancellation
        }

        // Is trigger order executable at provided price?
        if (order.orderType != 0) {
            if (
                (order.orderType == 1 && order.isLong && price > order.price) ||
                (order.orderType == 1 && !order.isLong && price < order.price) || // limit buy // limit sell
                (order.orderType == 2 && order.isLong && price < order.price) || // stop buy
                (order.orderType == 2 && !order.isLong && price > order.price) // stop sell
            ) {
                return (true, '!no-execution'); // don't cancel order
            }
        } else if (order.price > 0) {
            // protected market order (market order with a price). It will execute only if the execution price
            // is better than the submitted price. Otherwise, it will be cancelled
            if ((order.isLong && price > order.price) || (!order.isLong && price < order.price)) {
                return (false, '!protected');
            }
        }

        // One-cancels-the-Other (OCO)
        // `cancelOrderId` is an existing order which should be cancelled when the current order executes
        if (order.cancelOrderId > 0) {
            try orders.cancelOrder(order.cancelOrderId, '!oco') {} catch Error(string memory reason) {
                return (false, reason);
            }
        }

        // Check if there is a position
        PositionStore.Position memory position = positionStore.getPosition(order.user, order.asset, order.market);

        bool doAdd = !order.isReduceOnly && (position.size == 0 || order.isLong == position.isLong);
        bool doReduce = position.size > 0 && order.isLong != position.isLong;

        if (doAdd) {
            try positions.increasePosition(orderId, price, keeper) {} catch Error(string memory reason) {
                return (false, reason);
            }
        } else if (doReduce) {
            try positions.decreasePosition(orderId, price, keeper) {} catch Error(string memory reason) {
                return (false, reason);
            }
        } else {
            return (false, '!reduce');
        }

        return (true, '');
    }

    // POSITION LIQUIDATION

    /// @notice Self liquidation of order using Chainlink price
    /// @param user User address to liquidate
    /// @param asset Base asset of position
    /// @param market Market this position was submitted on
    function selfLiquidatePosition(
        address user,
        address asset,
        string memory market
    ) external nonReentrant ifNotPaused {
        (bool status, string memory reason) = _liquidatePosition(user, asset, market, 0, true, address(0));
        require(status, reason);
    }

    /// @notice Position liquidation by keeper (anyone) with Pyth priceUpdateData
    /// @param users User addresses to liquidate
    /// @param assets Base asset array
    /// @param markets Market array
    /// @param priceUpdateData Pyth priceUpdateData, see docs.pyth.network
    function liquidatePositions(
        address[] calldata users,
        address[] calldata assets,
        string[] calldata markets,
        bytes[] calldata priceUpdateData
    ) external payable nonReentrant ifNotPaused {
        // updates price for all submitted price feeds
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        require(msg.value >= fee, '!fee');

        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        for (uint256 i = 0; i < users.length; i++) {
            MarketStore.Market memory market = marketStore.get(markets[i]);

            (uint256 price, uint256 publishTime) = _getPythPrice(market.pythFeed);

            if (block.timestamp - publishTime > market.pythMaxAge) {
                // Price too old
                emit UserSkipped(users[i], assets[i], markets[i], price, publishTime, '!stale');
                continue;
            }

            (bool status, string memory reason) = _liquidatePosition(
                users[i],
                assets[i],
                markets[i],
                price,
                false,
                msg.sender
            );
            if (!status) {
                emit LiquidationError(users[i], assets[i], markets[i], price, reason);
            }
        }

        // Refund msg.value excess, if any
        if (msg.value > fee) {
            uint256 diff = msg.value - fee;
            payable(msg.sender).sendValue(diff);
        }
    }

    /// @dev Liquidates position
    /// @param user User address to liquidate
    /// @param asset Base asset of position
    /// @param market Market this position was submitted on
    /// @param price Pyth price (0 if self liquidation since Chainlink price will be used)
    /// @param withChainlink Wether to use Chainlink or not (i.e. if self liquidation or not)
    /// @param keeper Address of keeper which liquidates position (address(0) if self liquidation)
    function _liquidatePosition(
        address user,
        address asset,
        string memory market,
        uint256 price,
        bool withChainlink,
        address keeper
    ) internal returns (bool, string memory) {
        PositionStore.Position memory position = positionStore.getPosition(user, asset, market);
        if (position.size == 0) {
            return (false, '!position');
        }

        MarketStore.Market memory marketInfo = marketStore.get(market);

        uint256 chainlinkPrice = chainlink.getPrice(marketInfo.chainlinkFeed);

        if (withChainlink) {
            if (chainlinkPrice == 0) {
                return (false, '!no-chainlink-price');
            }
            price = chainlinkPrice;
        }

        if (price == 0) {
            return (false, '!no-price');
        }

        // Bound provided price with chainlink
        if (!_boundPriceWithChainlink(marketInfo.maxDeviation, chainlinkPrice, price)) {
            return (false, '!chainlink-deviation');
        }

        // Get PNL of position
        (int256 pnl, ) = positions.getPnL(
            asset,
            market,
            position.isLong,
            price,
            position.price,
            position.size,
            position.fundingTracker
        );

        // Treshold after which position will be liquidated
        uint256 threshold = (position.margin * marketInfo.liqThreshold) / BPS_DIVIDER;

        // Liquidate position if PNL is less than required threshold
        if (pnl <= -1 * int256(threshold)) {
            uint256 fee = (position.size * marketInfo.fee) / BPS_DIVIDER;

            // Credit trader loss and fee
            pool.creditTraderLoss(user, asset, market, position.margin - fee);
            positions.creditFee(0, user, asset, market, fee, true, keeper);

            // Update funding
            positionStore.decrementOI(asset, market, position.size, position.isLong);
            funding.updateFundingTracker(asset, market);

            // Remove position
            positionStore.remove(user, asset, market);

            emit PositionLiquidated(
                user,
                asset,
                market,
                position.isLong,
                position.size,
                position.margin,
                _getUsdAmount(asset, position.margin),
                price,
                fee
            );
        }

        return (true, '');
    }

    // -- Utils -- //

    /// @dev Returns pyth price converted to 18 decimals
    function _getPythPrice(bytes32 priceFeedId) internal view returns (uint256, uint256) {
        // It will revert if the price is older than maxAge
        PythStructs.Price memory retrievedPrice = pyth.getPriceUnsafe(priceFeedId);
        uint256 baseConversion = 10 ** uint256(int256(18) + retrievedPrice.expo);

        // Convert price to 18 decimals
        uint256 price = uint256(retrievedPrice.price * int256(baseConversion));
        uint256 publishTime = retrievedPrice.publishTime;

        return (price, publishTime);
    }

    /// @dev Returns USD value of `amount` of `asset`
    /// @dev Used for PositionLiquidated event
    function _getUsdAmount(address asset, uint256 amount) internal view returns (uint256) {
        AssetStore.Asset memory assetInfo = assetStore.get(asset);
        uint256 chainlinkPrice = chainlink.getPrice(assetInfo.chainlinkFeed);
        uint256 decimals = 18;
        if (asset != address(0)) {
            decimals = IERC20Metadata(asset).decimals();
        }
        // amount is in the asset's decimals, convert to 18. Price is 18 decimals
        return (amount * chainlinkPrice) / 10 ** decimals;
    }

    /// @dev Submitted Pyth price is bound by the Chainlink price
    function _boundPriceWithChainlink(
        uint256 maxDeviation,
        uint256 chainlinkPrice,
        uint256 price
    ) internal pure returns (bool) {
        if (chainlinkPrice == 0 || maxDeviation == 0) return true;
        if (
            price >= (chainlinkPrice * (BPS_DIVIDER - maxDeviation)) / BPS_DIVIDER &&
            price <= (chainlinkPrice * (BPS_DIVIDER + maxDeviation)) / BPS_DIVIDER
        ) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../stores/AssetStore.sol';
import '../stores/DataStore.sol';
import '../stores/FundStore.sol';
import '../stores/StakingStore.sol';

import '../utils/Roles.sol';

/**
 * @title  Staking
 * @notice Stake CAP to receive rewards
 */
contract Staking is Roles {
    // Constants
    uint256 public constant UNIT = 10 ** 18;

    // Events
    event CAPStaked(address indexed user, uint256 amount);
    event CAPUnstaked(address indexed user, uint256 amount);
    event CollectedReward(address indexed user, address indexed asset, uint256 amount);

    // Contracts
    DataStore public DS;

    AssetStore public assetStore;
    FundStore public fundStore;
    StakingStore public stakingStore;

    address public cap;

    /// @dev Initializes DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @notice Initializes protocol contracts
    /// @dev Only callable by governance
    function link() external onlyGov {
        assetStore = AssetStore(DS.getAddress('AssetStore'));
        fundStore = FundStore(payable(DS.getAddress('FundStore')));
        stakingStore = StakingStore(DS.getAddress('StakingStore'));
        cap = DS.getAddress('CAP');
    }

    /// @notice Stake `amount` of CAP to receive rewards
    function stake(uint256 amount) external {
        require(amount > 0, '!amount');

        updateRewards(msg.sender);

        stakingStore.incrementSupply(amount);
        stakingStore.incrementBalance(msg.sender, amount);

        fundStore.transferIn(cap, msg.sender, amount);

        emit CAPStaked(msg.sender, amount);
    }

    /// @notice Unstake `amount` of CAP
    function unstake(uint256 amount) external {
        require(amount > 0, '!amount');

        // Set to max if above max
        if (amount >= stakingStore.getBalance(msg.sender)) {
            amount = stakingStore.getBalance(msg.sender);
        }

        updateRewards(msg.sender);

        stakingStore.decrementSupply(amount);
        stakingStore.decrementBalance(msg.sender, amount);

        fundStore.transferOut(cap, msg.sender, amount);

        emit CAPUnstaked(msg.sender, amount);
    }

    /// @notice Collect multiple rewards
    function collectMultiple(address[] calldata assets) external {
        for (uint256 i = 0; i < assets.length; i++) {
            collectReward(assets[i]);
        }
    }

    /// @notice Collect reward of `asset`
    function collectReward(address asset) public {
        updateRewards(msg.sender);

        uint256 rewardToSend = stakingStore.getClaimableReward(asset, msg.sender);
        stakingStore.setClaimableReward(asset, msg.sender, 0);

        if (rewardToSend > 0) {
            fundStore.transferOut(asset, msg.sender, rewardToSend);

            emit CollectedReward(msg.sender, asset, rewardToSend);
        }
    }

    /// @notice Update rewards of `account`
    function updateRewards(address account) public {
        if (account == address(0)) return;
        for (uint256 i = 0; i < assetStore.getAssetCount(); i++) {
            address asset = assetStore.getAssetByIndex(i);
            stakingStore.incrementRewardPerToken(asset);
            stakingStore.updateClaimableReward(asset, account);
        }
    }

    /// @notice Get claimable reward of `account` and `asset`
    function getClaimableReward(address asset, address account) public view returns (uint256) {
        uint256 currentClaimableReward = stakingStore.getClaimableReward(asset, account);

        uint256 capSupply = stakingStore.getTotalSupply();
        if (capSupply == 0) return currentClaimableReward;

        uint256 _rewardPerTokenStored = stakingStore.getRewardPerTokenSum(asset) +
            (stakingStore.getPendingReward(asset) * UNIT) /
            capSupply;
        if (_rewardPerTokenStored == 0) return currentClaimableReward; // no rewards yet

        uint256 capBalance = stakingStore.getBalance(account);

        return
            currentClaimableReward +
            (capBalance * (_rewardPerTokenStored - stakingStore.getPreviousReward(asset, account))) /
            UNIT;
    }

    /// @notice Get claimable reward of `account` and `assets`
    function getClaimableRewards(address[] calldata assets, address account) external view returns (uint256[] memory) {
        uint256 length = assets.length;
        uint256[] memory _rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _rewards[i] = getClaimableReward(assets[i], account);
        }

        return _rewards;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @title MockToken
/// @notice Mock ERC20 token contract used for tests
contract MockToken is ERC20 {
    uint8 _decimals;

    constructor(string memory name, string memory symbol, uint8 __decimals) ERC20(name, symbol) {
        _decimals = __decimals;
    }

    /// @dev returns decimals of token, e.g. 6 for USDC
    function decimals() public view virtual override returns (uint8) {
        if (_decimals > 0) return _decimals;
        return 18;
    }

    /// @dev mint tokens to msg.sender
    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../utils/Roles.sol';

/// @title AssetStore
/// @notice Persistent storage of supported assets
contract AssetStore is Roles {
    // Asset info struct
    struct Asset {
        uint256 minSize;
        address chainlinkFeed;
    }

    // Asset list
    address[] public assetList;
    mapping(address => Asset) private assets;

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Set or update an asset
    /// @dev Only callable by governance
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param assetInfo Struct containing minSize and chainlinkFeed
    function set(address asset, Asset memory assetInfo) external onlyGov {
        assets[asset] = assetInfo;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i] == asset) return;
        }
        assetList.push(asset);
    }

    /// @notice Returns asset struct of `asset`
    /// @param asset Asset address, e.g. address(0) for ETH
    function get(address asset) external view returns (Asset memory) {
        return assets[asset];
    }

    /// @notice Get a list of all supported assets
    function getAssetList() external view returns (address[] memory) {
        return assetList;
    }

    /// @notice Get number of supported assets
    function getAssetCount() external view returns (uint256) {
        return assetList.length;
    }

    /// @notice Returns asset address at `index`
    /// @param index index of asset
    function getAssetByIndex(uint256 index) external view returns (address) {
        return assetList[index];
    }

    /// @notice Returns true if `asset` is supported
    /// @param asset Asset address, e.g. address(0) for ETH
    function isSupported(address asset) external view returns (bool) {
        return assets[asset].minSize > 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../utils/Governable.sol';

/// @title DataStore
/// @notice General purpose storage contract
/// @dev Access is restricted to governance
contract DataStore is Governable {
    // Key-value stores
    mapping(bytes32 => uint256) public uintValues;
    mapping(bytes32 => int256) public intValues;
    mapping(bytes32 => address) public addressValues;
    mapping(bytes32 => bytes32) public dataValues;
    mapping(bytes32 => bool) public boolValues;
    mapping(bytes32 => string) public stringValues;

    constructor() Governable() {}

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setUint(string calldata key, uint256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || uintValues[hash] == 0) {
            uintValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getUint(string calldata key) external view returns (uint256) {
        return uintValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setInt(string calldata key, int256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || intValues[hash] == 0) {
            intValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getInt(string calldata key) external view returns (int256) {
        return intValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value address to store
    /// @param overwrite Overwrites existing value if set to true
    function setAddress(string calldata key, address value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || addressValues[hash] == address(0)) {
            addressValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getAddress(string calldata key) external view returns (address) {
        return addressValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value byte value to store
    function setData(string calldata key, bytes32 value) external onlyGov returns (bool) {
        dataValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getData(string calldata key) external view returns (bytes32) {
        return dataValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store (true / false)
    function setBool(string calldata key, bool value) external onlyGov returns (bool) {
        boolValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getBool(string calldata key) external view returns (bool) {
        return boolValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value string to store
    function setString(string calldata key, string calldata value) external onlyGov returns (bool) {
        stringValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getString(string calldata key) external view returns (string memory) {
        return stringValues[getHash(key)];
    }

    /// @param key string to hash
    function getHash(string memory key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../utils/Roles.sol';

/// @title FundingStore
/// @notice Storage of funding trackers for all supported markets
contract FundingStore is Roles {
    // interval used to calculate accrued funding
    uint256 public fundingInterval = 1 hours;

    // asset => market => funding tracker (long) (short is opposite)
    mapping(address => mapping(string => int256)) private fundingTrackers;

    // asset => market => last time fundingTracker was updated. In seconds.
    mapping(address => mapping(string => uint256)) private lastUpdated;

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice updates `fundingInterval`
    /// @dev Only callable by governance
    /// @param interval new funding interval, in seconds
    function setFundingInterval(uint256 interval) external onlyGov {
        require(interval > 0, '!interval');
        fundingInterval = interval;
    }

    /// @notice Updates `lastUpdated` mapping
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Funding.updateFundingTracker
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    /// @param timestamp Timestamp in seconds
    function setLastUpdated(address asset, string calldata market, uint256 timestamp) external onlyContract {
        lastUpdated[asset][market] = timestamp;
    }

    /// @notice updates `fundingTracker` mapping
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Funding.updateFundingTracker
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    /// @param fundingIncrement Accrued funding of given asset and market
    function updateFundingTracker(
        address asset,
        string calldata market,
        int256 fundingIncrement
    ) external onlyContract {
        fundingTrackers[asset][market] += fundingIncrement;
    }

    /// @notice Returns last update timestamp of `asset` and `market`
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    function getLastUpdated(address asset, string calldata market) external view returns (uint256) {
        return lastUpdated[asset][market];
    }

    /// @notice Returns funding tracker of `asset` and `market`
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param market Market, e.g. "ETH-USD"
    function getFundingTracker(address asset, string calldata market) external view returns (int256) {
        return fundingTrackers[asset][market];
    }

    /// @notice Returns funding trackers of `assets` and `markets`
    /// @param assets Array of asset addresses
    /// @param markets Array of market strings
    function getFundingTrackers(
        address[] calldata assets,
        string[] calldata markets
    ) external view returns (int256[] memory fts) {
        uint256 length = assets.length;
        fts = new int256[](length);
        for (uint256 i = 0; i < length; i++) {
            fts[i] = fundingTrackers[assets[i]][markets[i]];
        }
        return fts;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../utils/Roles.sol';

/// @title FundStore
/// @notice Storage of protocol funds
contract FundStore is Roles, ReentrancyGuard {
    // Libraries
    using SafeERC20 for IERC20;
    using Address for address payable;

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Transfers `amount` of `asset` in
    /// @dev Only callable by other protocol contracts
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param from Address where asset is transferred from
    function transferIn(address asset, address from, uint256 amount) external payable onlyContract {
        if (amount == 0 || asset == address(0)) return;
        IERC20(asset).safeTransferFrom(from, address(this), amount);
    }

    /// @notice Transfers `amount` of `asset` out
    /// @dev Only callable by other protocol contracts
    /// @param asset Asset address, e.g. address(0) for ETH
    /// @param to Address where asset is transferred to
    function transferOut(address asset, address to, uint256 amount) external nonReentrant onlyContract {
        if (amount == 0 || to == address(0)) return;
        if (asset == address(0)) {
            payable(to).sendValue(amount);
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../utils/Roles.sol';

/// @title MarketStore
/// @notice Persistent storage of supported markets
contract MarketStore is Roles {
    // Market struct
    struct Market {
        string name; // Market's full name, e.g. Bitcoin / U.S. Dollar
        string category; // crypto, fx, commodities, or indices
        address chainlinkFeed; // Price feed contract address
        uint256 maxLeverage; // No decimals
        uint256 maxDeviation; // In bps, max price difference from oracle to chainlink price
        uint256 fee; // In bps. 10 = 0.1%
        uint256 liqThreshold; // In bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minOrderAge; // Min order age before is can be executed. In seconds
        uint256 pythMaxAge; // Max Pyth submitted price age, in seconds
        bytes32 pythFeed; // Pyth price feed id
        bool allowChainlinkExecution; // Allow anyone to execute orders with chainlink
        bool isReduceOnly; // accepts only reduce only orders
    }

    // Constants to limit gov power
    uint256 public constant MAX_FEE = 1000; // 10%
    uint256 public constant MAX_DEVIATION = 1000; // 10%
    uint256 public constant MAX_LIQTHRESHOLD = 10000; // 100%
    uint256 public constant MAX_MIN_ORDER_AGE = 30;
    uint256 public constant MIN_PYTH_MAX_AGE = 3;

    // list of supported markets
    string[] public marketList; // "ETH-USD", "BTC-USD", etc
    mapping(string => Market) private markets;

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Set or update a market
    /// @dev Only callable by governance
    /// @param market String identifier, e.g. "ETH-USD"
    /// @param marketInfo Market struct containing required market data
    function set(string calldata market, Market memory marketInfo) external onlyGov {
        require(marketInfo.fee <= MAX_FEE, '!max-fee');
        require(marketInfo.maxLeverage >= 1, '!max-leverage');
        require(marketInfo.maxDeviation <= MAX_DEVIATION, '!max-deviation');
        require(marketInfo.liqThreshold <= MAX_LIQTHRESHOLD, '!max-liqthreshold');
        require(marketInfo.minOrderAge <= MAX_MIN_ORDER_AGE, '!max-minorderage');
        require(marketInfo.pythMaxAge >= MIN_PYTH_MAX_AGE, '!min-pythmaxage');

        markets[market] = marketInfo;
        for (uint256 i = 0; i < marketList.length; i++) {
            // check if market already exists, if yes return
            if (keccak256(abi.encodePacked(marketList[i])) == keccak256(abi.encodePacked(market))) return;
        }
        marketList.push(market);
    }

    /// @notice Returns market struct of `market`
    /// @param market String identifier, e.g. "ETH-USD"
    function get(string calldata market) external view returns (Market memory) {
        return markets[market];
    }

    /// @notice Returns market struct array of specified markets
    /// @param _markets Array of market strings, e.g. ["ETH-USD", "BTC-USD"]
    function getMany(string[] calldata _markets) external view returns (Market[] memory) {
        uint256 length = _markets.length;
        Market[] memory _marketInfos = new Market[](length);
        for (uint256 i = 0; i < length; i++) {
            _marketInfos[i] = markets[_markets[i]];
        }
        return _marketInfos;
    }

    /// @notice Returns market identifier at `index`
    /// @param index index of marketList
    function getMarketByIndex(uint256 index) external view returns (string memory) {
        return marketList[index];
    }

    /// @notice Get a list of all supported markets
    function getMarketList() external view returns (string[] memory) {
        return marketList;
    }

    /// @notice Get number of supported markets
    function getMarketCount() external view returns (uint256) {
        return marketList.length;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '../utils/Roles.sol';

/// @title OrderStore
/// @notice Persistent storage for Orders.sol
contract OrderStore is Roles {
    // Libraries
    using EnumerableSet for EnumerableSet.UintSet;

    // Order struct
    struct Order {
        uint256 orderId; // incremental order id
        address user; // user that usubmitted the order
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this order was submitted on
        uint256 margin; // Collateral tied to this order. In wei
        uint256 size; // Order size (margin * leverage). In wei
        uint256 price; // The order's price if its a trigger or protected order
        uint256 fee; // Fee amount paid. In wei
        bool isLong; // Wether the order is a buy or sell order
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        bool isReduceOnly; // Wether the order is reduce-only
        uint256 timestamp; // block.timestamp at which the order was submitted
        uint256 expiry; // block.timestamp at which the order expires
        uint256 cancelOrderId; // orderId to cancel when this order executes
    }

    uint256 public oid; // incremental order id
    mapping(uint256 => Order) private orders; // order id => Order
    mapping(address => EnumerableSet.UintSet) private userOrderIds; // user => [order ids..]
    EnumerableSet.UintSet private marketOrderIds; // [order ids..]
    EnumerableSet.UintSet private triggerOrderIds; // [order ids..]

    uint256 public maxMarketOrderTTL = 5 minutes;
    uint256 public maxTriggerOrderTTL = 180 days;
    uint256 public chainlinkCooldown = 5 minutes;

    bool public areNewOrdersPaused;
    bool public isProcessingPaused;

    constructor(RoleStore rs) Roles(rs) {}

    // Setters

    /// @notice Disable submitting new orders
    /// @dev Only callable by governance
    function setAreNewOrdersPaused(bool b) external onlyGov {
        areNewOrdersPaused = b;
    }

    /// @notice Disable processing new orders
    /// @dev Only callable by governance
    function setIsProcessingPaused(bool b) external onlyGov {
        isProcessingPaused = b;
    }

    /// @notice Set duration until market orders expire
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setMaxMarketOrderTTL(uint256 amount) external onlyGov {
        require(amount > 0, '!amount');
        require(amount < maxTriggerOrderTTL, 'amount > maxTriggerOrderTTL');
        maxMarketOrderTTL = amount;
    }

    /// @notice Set duration until trigger orders expire
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setMaxTriggerOrderTTL(uint256 amount) external onlyGov {
        require(amount > 0, '!amount');
        require(amount > maxMarketOrderTTL, 'amount < maxMarketOrderTTL');
        maxTriggerOrderTTL = amount;
    }

    /// @notice Set duration after orders can be executed with chainlink
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setChainlinkCooldown(uint256 amount) external onlyGov {
        require(amount > 0, '!amount');
        chainlinkCooldown = amount;
    }

    /// @notice Adds order to storage
    /// @dev Only callable by other protocol contracts
    function add(Order memory order) external onlyContract returns (uint256) {
        uint256 nextOrderId = ++oid;
        order.orderId = nextOrderId;
        orders[nextOrderId] = order;
        userOrderIds[order.user].add(nextOrderId);
        if (order.orderType == 0) {
            marketOrderIds.add(order.orderId);
        } else {
            triggerOrderIds.add(order.orderId);
        }
        return nextOrderId;
    }

    /// @notice Removes order from store
    /// @dev Only callable by other protocol contracts
    /// @param orderId Order to remove
    function remove(uint256 orderId) external onlyContract {
        Order memory order = orders[orderId];
        if (order.size == 0) return;
        userOrderIds[order.user].remove(orderId);
        marketOrderIds.remove(orderId);
        triggerOrderIds.remove(orderId);
        delete orders[orderId];
    }

    /// @notice Updates `cancelOrderId` of `orderId`, e.g. TP order cancels a SL order and vice versa
    /// @dev Only callable by other protocol contracts
    /// @param orderId Order which cancels `cancelOrderId` on execution
    /// @param cancelOrderId Order to cancel when `orderId` executes
    function updateCancelOrderId(uint256 orderId, uint256 cancelOrderId) external onlyContract {
        Order storage order = orders[orderId];
        order.cancelOrderId = cancelOrderId;
    }

    /// @notice Returns a single order
    /// @param orderId Order to get
    function get(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /// @notice Returns many orders
    /// @param orderIds Orders to get, e.g. [1, 2, 5]
    function getMany(uint256[] calldata orderIds) external view returns (Order[] memory) {
        uint256 length = orderIds.length;
        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[orderIds[i]];
        }

        return _orders;
    }

    /// @notice Returns market orders
    /// @param length Amount of market orders to return
    function getMarketOrders(uint256 length) external view returns (Order[] memory) {
        uint256 _length = marketOrderIds.length();
        if (length > _length) length = _length;

        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[marketOrderIds.at(i)];
        }

        return _orders;
    }

    /// @notice Returns trigger orders
    /// @param length Amount of trigger orders to return
    /// @param offset Offset to start
    function getTriggerOrders(uint256 length, uint256 offset) external view returns (Order[] memory) {
        uint256 _length = triggerOrderIds.length();
        if (length > _length) length = _length;

        Order[] memory _orders = new Order[](length);

        for (uint256 i = offset; i < length + offset; i++) {
            _orders[i] = orders[triggerOrderIds.at(i)];
        }

        return _orders;
    }

    /// @notice Returns orders of `user`
    function getUserOrders(address user) external view returns (Order[] memory) {
        uint256 length = userOrderIds[user].length();
        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[userOrderIds[user].at(i)];
        }

        return _orders;
    }

    /// @notice Returns amount of market orders
    function getMarketOrderCount() external view returns (uint256) {
        return marketOrderIds.length();
    }

    /// @notice Returns amount of trigger orders
    function getTriggerOrderCount() external view returns (uint256) {
        return triggerOrderIds.length();
    }

    /// @notice Returns order amount of `user`
    function getUserOrderCount(address user) external view returns (uint256) {
        return userOrderIds[user].length();
    }

    /// @notice Returns true if order is from `user`
    /// @param orderId order to check
    /// @param user user to check
    function isUserOrder(uint256 orderId, address user) external view returns (bool) {
        return userOrderIds[user].contains(orderId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../utils/Roles.sol';

/// @title PoolStore
/// @notice Persistent storage for Pool.sol
contract PoolStore is Roles {
    // Libraries
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_POOL_WITHDRAWAL_FEE = 500; // in bps = 5%

    // State variables
    uint256 public feeShare = 500;
    uint256 public bufferPayoutPeriod = 7 days;

    mapping(address => uint256) private clpSupply; // asset => clp supply
    mapping(address => uint256) private balances; // asset => balance
    mapping(address => mapping(address => uint256)) private userClpBalances; // asset => account => clp amount

    mapping(address => uint256) private bufferBalances; // asset => balance
    mapping(address => uint256) private lastPaid; // asset => timestamp

    mapping(address => uint256) private withdrawalFees; // asset => bps

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Set pool fee
    /// @dev Only callable by governance
    /// @param bps fee share in bps
    function setFeeShare(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        feeShare = bps;
    }

    /// @notice Set buffer payout period
    /// @dev Only callable by governance
    /// @param period Buffer payout period in seconds, default is 7 days (604800 seconds)
    function setBufferPayoutPeriod(uint256 period) external onlyGov {
        require(period > 0, '!period');
        bufferPayoutPeriod = period;
    }

    /// @notice Set pool withdrawal fee
    /// @dev Only callable by governance
    /// @param asset Pool asset, e.g. address(0) for ETH
    /// @param bps Withdrawal fee in bps
    function setWithdrawalFee(address asset, uint256 bps) external onlyGov {
        require(bps <= MAX_POOL_WITHDRAWAL_FEE, '!pool-withdrawal-fee');
        withdrawalFees[asset] = bps;
    }

    /// @notice Increments pool balance
    /// @dev Only callable by other protocol contracts
    function incrementBalance(address asset, uint256 amount) external onlyContract {
        balances[asset] += amount;
    }

    /// @notice Decrements pool balance
    /// @dev Only callable by other protocol contracts
    function decrementBalance(address asset, uint256 amount) external onlyContract {
        balances[asset] = balances[asset] <= amount ? 0 : balances[asset] - amount;
    }

    /// @notice Increments buffer balance
    /// @dev Only callable by other protocol contracts
    function incrementBufferBalance(address asset, uint256 amount) external onlyContract {
        bufferBalances[asset] += amount;
    }

    /// @notice Decrements buffer balance
    /// @dev Only callable by other protocol contracts
    function decrementBufferBalance(address asset, uint256 amount) external onlyContract {
        bufferBalances[asset] = bufferBalances[asset] <= amount ? 0 : bufferBalances[asset] - amount;
    }

    /// @notice Updates `lastPaid`
    /// @dev Only callable by other protocol contracts
    function setLastPaid(address asset, uint256 timestamp) external onlyContract {
        lastPaid[asset] = timestamp;
    }

    /// @notice Increments `clpSupply` and `userClpBalances`
    /// @dev Only callable by other protocol contracts
    function incrementUserClpBalance(address asset, address user, uint256 amount) external onlyContract {
        clpSupply[asset] += amount;

        unchecked {
            // Overflow not possible: balance + amount is at most clpSupply + amount, which is checked above.
            userClpBalances[asset][user] += amount;
        }
    }

    /// @notice Decrements `clpSupply` and `userClpBalances`
    /// @dev Only callable by other protocol contracts
    function decrementUserClpBalance(address asset, address user, uint256 amount) external onlyContract {
        clpSupply[asset] = clpSupply[asset] <= amount ? 0 : clpSupply[asset] - amount;

        userClpBalances[asset][user] = userClpBalances[asset][user] <= amount
            ? 0
            : userClpBalances[asset][user] - amount;
    }

    /// @notice Returns withdrawal fee of `asset` from pool
    function getWithdrawalFee(address asset) external view returns (uint256) {
        return withdrawalFees[asset];
    }

    /// @notice Returns the sum of buffer and pool balance of `asset`
    function getAvailable(address asset) external view returns (uint256) {
        return balances[asset] + bufferBalances[asset];
    }

    /// @notice Returns amount of `asset` in pool
    function getBalance(address asset) external view returns (uint256) {
        return balances[asset];
    }

    /// @notice Returns amount of `asset` in buffer
    function getBufferBalance(address asset) external view returns (uint256) {
        return bufferBalances[asset];
    }

    /// @notice Returns pool balances of `_assets`
    function getBalances(address[] calldata _assets) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = balances[_assets[i]];
        }

        return _balances;
    }

    /// @notice Returns buffer balances of `_assets`
    function getBufferBalances(address[] calldata _assets) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = bufferBalances[_assets[i]];
        }

        return _balances;
    }

    /// @notice Returns last time pool was paid
    function getLastPaid(address asset) external view returns (uint256) {
        return lastPaid[asset];
    }

    /// @notice Returns `_assets` balance of `account`
    function getUserBalances(address[] calldata _assets, address account) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = getUserBalance(_assets[i], account);
        }

        return _balances;
    }

    /// @notice Returns `asset` balance of `account`
    function getUserBalance(address asset, address account) public view returns (uint256) {
        if (clpSupply[asset] == 0) return 0;
        return (userClpBalances[asset][account] * balances[asset]) / clpSupply[asset];
    }

    /// @notice Returns total amount of CLP for `asset`
    function getClpSupply(address asset) public view returns (uint256) {
        return clpSupply[asset];
    }

    /// @notice Returns amount of CLP of `account` for `asset`
    function getUserClpBalance(address asset, address account) public view returns (uint256) {
        return userClpBalances[asset][account];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '../utils/Roles.sol';

/// @title PositionStore
/// @notice Persistent storage for Positions.sol
contract PositionStore is Roles {
    // Libraries
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Position struct
    struct Position {
        address user; // User that submitted the position
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this position was submitted on
        bool isLong; // Wether the position is long or short
        uint256 size; // The position's size (margin * leverage)
        uint256 margin; // Collateral tied to this position. In wei
        int256 fundingTracker; // Market funding rate tracker
        uint256 price; // The position's average execution price
        uint256 timestamp; // Time at which the position was created
    }

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_KEEPER_FEE_SHARE = 2000; // 20%

    // State variables
    uint256 public removeMarginBuffer = 1000;
    uint256 public keeperFeeShare = 500;

    // Mappings
    mapping(address => mapping(string => uint256)) private OI; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OILong; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OIShort; // open interest. market => asset => amount]

    mapping(bytes32 => Position) private positions; // key = asset,user,market
    EnumerableSet.Bytes32Set private positionKeys; // [position keys..]
    mapping(address => EnumerableSet.Bytes32Set) private positionKeysForUser; // user => [position keys..]

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Updates `removeMarginBuffer`
    /// @dev Only callable by governance
    /// @param bps new `removeMarginBuffer` in bps
    function setRemoveMarginBuffer(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        removeMarginBuffer = bps;
    }

    /// @notice Sets keeper fee share
    /// @dev Only callable by governance
    /// @param bps new `keeperFeeShare` in bps
    function setKeeperFeeShare(uint256 bps) external onlyGov {
        require(bps <= MAX_KEEPER_FEE_SHARE, '!keeper-fee-share');
        keeperFeeShare = bps;
    }

    /// @notice Adds new position or updates exisiting one
    /// @dev Only callable by other protocol contracts
    /// @param position Position to add/update
    function addOrUpdate(Position memory position) external onlyContract {
        bytes32 key = _getPositionKey(position.user, position.asset, position.market);
        positions[key] = position;
        positionKeysForUser[position.user].add(key);
        positionKeys.add(key);
    }

    /// @notice Removes position
    /// @dev Only callable by other protocol contracts
    function remove(address user, address asset, string calldata market) external onlyContract {
        bytes32 key = _getPositionKey(user, asset, market);
        positionKeysForUser[user].remove(key);
        positionKeys.remove(key);
        delete positions[key];
    }

    /// @notice Increments open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.increasePosition
    function incrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] += amount;
        if (isLong) {
            OILong[asset][market] += amount;
        } else {
            OIShort[asset][market] += amount;
        }
    }

    /// @notice Decrements open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked whenever a position is closed or decreased
    function decrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] = OI[asset][market] <= amount ? 0 : OI[asset][market] - amount;
        if (isLong) {
            OILong[asset][market] = OILong[asset][market] <= amount ? 0 : OILong[asset][market] - amount;
        } else {
            OIShort[asset][market] = OIShort[asset][market] <= amount ? 0 : OIShort[asset][market] - amount;
        }
    }

    /// @notice Returns open interest of `asset` and `market`
    function getOI(address asset, string calldata market) external view returns (uint256) {
        return OI[asset][market];
    }

    /// @notice Returns open interest of long positions
    function getOILong(address asset, string calldata market) external view returns (uint256) {
        return OILong[asset][market];
    }

    /// @notice Returns open interest of short positions
    function getOIShort(address asset, string calldata market) external view returns (uint256) {
        return OIShort[asset][market];
    }

    /// @notice Returns position of `user`
    /// @param asset Base asset of position
    /// @param market Market this position was submitted on
    function getPosition(address user, address asset, string memory market) public view returns (Position memory) {
        bytes32 key = _getPositionKey(user, asset, market);
        return positions[key];
    }

    /// @notice Returns positions of `users`
    /// @param assets Base assets of positions
    /// @param markets Markets of positions
    function getPositions(
        address[] calldata users,
        address[] calldata assets,
        string[] calldata markets
    ) external view returns (Position[] memory) {
        uint256 length = users.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = getPosition(users[i], assets[i], markets[i]);
        }

        return _positions;
    }

    /// @notice Returns positions
    /// @param keys Position keys
    function getPositions(bytes32[] calldata keys) external view returns (Position[] memory) {
        uint256 length = keys.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[keys[i]];
        }

        return _positions;
    }

    /// @notice Returns number of positions
    function getPositionCount() external view returns (uint256) {
        return positionKeys.length();
    }

    /// @notice Returns `length` amount of positions starting from `offset`
    function getPositions(uint256 length, uint256 offset) external view returns (Position[] memory) {
        uint256 _length = positionKeys.length();
        if (length > _length) length = _length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = offset; i < length + offset; i++) {
            _positions[i] = positions[positionKeys.at(i)];
        }

        return _positions;
    }

    /// @notice Returns all positions of `user`
    function getUserPositions(address user) external view returns (Position[] memory) {
        uint256 length = positionKeysForUser[user].length();
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[positionKeysForUser[user].at(i)];
        }

        return _positions;
    }

    /// @dev Returns position key by hashing (user, asset, market)
    function _getPositionKey(address user, address asset, string memory market) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, asset, market));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './DataStore.sol';
import './PoolStore.sol';
import './PositionStore.sol';

import '../utils/Roles.sol';

/// @title RiskStore
/// @notice Implementation of risk mitigation measures such as maximum open interest and maximum pool drawdown
contract RiskStore is Roles {
    // Constants
    uint256 public constant BPS_DIVIDER = 10000;

    mapping(string => mapping(address => uint256)) private maxOI; // market => asset => amount

    // Pool Risk Measures
    uint256 public poolHourlyDecay = 416; // bps = 4.16% hourly, disappears after 24 hours
    mapping(address => int256) private poolProfitTracker; // asset => amount (amortized)
    mapping(address => uint256) private poolProfitLimit; // asset => bps
    mapping(address => uint256) private poolLastChecked; // asset => timestamp

    // Contracts
    DataStore public DS;

    /// @dev Initialize DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @notice Set maximum open interest
    /// @notice Once current open interest exceeds this value, orders are no longer accepted
    /// @dev Only callable by governance
    /// @param market Market to set, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    /// @param amount Max open interest to set
    function setMaxOI(string calldata market, address asset, uint256 amount) external onlyGov {
        require(amount > 0, '!amount');
        maxOI[market][asset] = amount;
    }

    /// @notice Set hourly pool decay
    /// @dev Only callable by governance
    /// @param bps Hourly pool decay in bps
    function setPoolHourlyDecay(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        poolHourlyDecay = bps;
    }

    /// @notice Set pool profit limit of `asset`
    /// @dev Only callable by governance
    /// @param asset Address of asset, e.g. address(0) for ETH
    /// @param bps Pool profit limit in bps
    function setPoolProfitLimit(address asset, uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        poolProfitLimit[asset] = bps;
    }

    /// @notice Measures the net loss of a pool over time
    /// @notice Reverts if time-weighted drawdown is higher than the allowed profit limit
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.decreasePosition
    function checkPoolDrawdown(address asset, int256 pnl) external onlyContract {
        // Get available amount of `asset` in the pool (pool balance + buffer balance)
        uint256 poolAvailable = PoolStore(DS.getAddress('PoolStore')).getAvailable(asset);

        // Get profit tracker, pnl > 0 means trader win
        int256 profitTracker = getPoolProfitTracker(asset) + pnl;
        // get profit limit of pool
        uint256 profitLimit = poolProfitLimit[asset];

        // update storage vars
        poolProfitTracker[asset] = profitTracker;
        poolLastChecked[asset] = block.timestamp;

        // return if profit limit or profit tracker is zero / less than zero
        if (profitLimit == 0 || profitTracker <= 0) return;

        // revert if profitTracker > profitLimit * available funds
        require(uint256(profitTracker) < (profitLimit * poolAvailable) / BPS_DIVIDER, '!pool-risk');
    }

    /// @notice Checks if maximum open interest is reached
    /// @param market Market to check, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    function checkMaxOI(address asset, string calldata market, uint256 size) external view {
        uint256 openInterest = PositionStore(DS.getAddress('PositionStore')).getOI(asset, market);
        uint256 _maxOI = maxOI[market][asset];
        if (_maxOI > 0 && openInterest + size > _maxOI) revert('!max-oi');
    }

    /// @notice Get maximum open interest of `market`
    /// @param market Market to check, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    function getMaxOI(string calldata market, address asset) external view returns (uint256) {
        return maxOI[market][asset];
    }

    /// @notice Returns pool profit tracker of `asset`
    /// @dev Amortized every hour by 4.16% unless otherwise set
    function getPoolProfitTracker(address asset) public view returns (int256) {
        int256 profitTracker = poolProfitTracker[asset];
        uint256 lastCheckedHourId = poolLastChecked[asset] / (1 hours);
        uint256 currentHourId = block.timestamp / (1 hours);

        if (currentHourId > lastCheckedHourId) {
            // hours passed since last check
            uint256 hoursPassed = currentHourId - lastCheckedHourId;
            if (hoursPassed >= BPS_DIVIDER / poolHourlyDecay) {
                profitTracker = 0;
            } else {
                // reduce profit tracker by `poolHourlyDecay` for every hour that passed since last check
                for (uint256 i = 0; i < hoursPassed; i++) {
                    profitTracker *= (int256(BPS_DIVIDER) - int256(poolHourlyDecay)) / int256(BPS_DIVIDER);
                }
            }
        }

        return profitTracker;
    }

    /// @notice Returns pool profit limit of `asset`
    function getPoolProfitLimit(address asset) external view returns (uint256) {
        return poolProfitLimit[asset];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../utils/Governable.sol';

/**
 * @title  RoleStore
 * @notice Role-based access control mechanism. Governance can grant and
 *         revoke roles dynamically via {grantRole} and {revokeRole}
 */
contract RoleStore is Governable {
    // Libraries
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Set of roles
    EnumerableSet.Bytes32Set internal roles;

    // Role -> address
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;

    constructor() Governable() {}

    /// @notice Grants `role` to `account`
    /// @dev Only callable by governance
    function grantRole(address account, bytes32 role) external onlyGov {
        // add role if not already present
        if (!roles.contains(role)) roles.add(role);

        require(roleMembers[role].add(account));
    }

    /// @notice Revokes `role` from `account`
    /// @dev Only callable by governance
    function revokeRole(address account, bytes32 role) external onlyGov {
        require(roleMembers[role].remove(account));

        // Remove role if it has no longer any members
        if (roleMembers[role].length() == 0) {
            roles.remove(role);
        }
    }

    /// @notice Returns `true` if `account` has been granted `role`
    function hasRole(address account, bytes32 role) external view returns (bool) {
        return roleMembers[role].contains(account);
    }

    /// @notice Returns number of roles
    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '../utils/Roles.sol';

/// @title StakingStore
/// @notice Persistent storage for Staking.sol
contract StakingStore is Roles {
    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant UNIT = 10 ** 18;

    // Fee share for CAP stakers
    uint256 public feeShare = 500;

    // Total amount of CAP (ticker: CAP) staked
    uint256 totalSupply;

    // Account to cap staked
    mapping(address => uint256) private balances;

    // Rewards
    mapping(address => uint256) private rewardPerTokenSum;
    mapping(address => uint256) private pendingReward;
    mapping(address => mapping(address => uint256)) private previousReward;
    mapping(address => mapping(address => uint256)) private claimableReward;

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Set fee share for CAP stakers
    /// @dev Only callable by governance
    /// @param bps fee share in bps
    function setFeeShare(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        feeShare = bps;
    }

    /// @notice Increments total staked supply by `amount`
    /// @dev Only callable by other protocol contracts
    function incrementSupply(uint256 amount) external onlyContract {
        totalSupply += amount;
    }

    /// @notice Decrements total staked supply by `amount`
    /// @dev Only callable by other protocol contracts
    function decrementSupply(uint256 amount) external onlyContract {
        totalSupply = totalSupply <= amount ? 0 : totalSupply - amount;
    }

    /// @notice Increments staked balance of `user` by `amount`
    /// @dev Only callable by other protocol contracts
    function incrementBalance(address user, uint256 amount) external onlyContract {
        balances[user] += amount;
    }

    /// @notice Decrements staked balance of `user` by `amount`
    /// @dev Only callable by other protocol contracts
    function decrementBalance(address user, uint256 amount) external onlyContract {
        balances[user] = balances[user] <= amount ? 0 : balances[user] - amount;
    }

    /// @notice Increments pending reward of `asset` by `amount`
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.creditFee
    function incrementPendingReward(address asset, uint256 amount) external onlyContract {
        pendingReward[asset] += amount;
    }

    /// @notice Increments `asset` reward per token
    /// @dev Only callable by other protocol contracts
    function incrementRewardPerToken(address asset) external onlyContract {
        if (totalSupply == 0) return;
        uint256 amount = (pendingReward[asset] * UNIT) / totalSupply;
        rewardPerTokenSum[asset] += amount;
        // due to rounding errors a fraction of fees stays in the contract
        // pendingReward is set to the amount which is left over, and will be distributed later
        pendingReward[asset] -= (amount * totalSupply) / UNIT;
    }

    /// @notice Updates claimable reward of `asset` by `user`
    /// @dev Only callable by other protocol contracts
    function updateClaimableReward(address asset, address user) external onlyContract {
        if (rewardPerTokenSum[asset] == 0) return;
        uint256 amount = (balances[user] * (rewardPerTokenSum[asset] - previousReward[asset][user])) / UNIT;
        claimableReward[asset][user] += amount;
        previousReward[asset][user] = rewardPerTokenSum[asset];
    }

    /// @notice Sets claimable reward of `asset` by `user`
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Staking.collectReward, sets reward to zero when an user claims his reward
    function setClaimableReward(address asset, address user, uint256 amount) external onlyContract {
        claimableReward[asset][user] = amount;
    }

    /// @notice Returns total amount of staked CAP
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /// @notice Returns staked balance of `account`
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @notice Returns pending reward of `asset`
    function getPendingReward(address asset) external view returns (uint256) {
        return pendingReward[asset];
    }

    /// @notice Returns previous reward of `asset`
    function getPreviousReward(address asset, address user) external view returns (uint256) {
        return previousReward[asset][user];
    }

    /// @notice Returns rewardPerTokenSum of `asset`
    function getRewardPerTokenSum(address asset) external view returns (uint256) {
        return rewardPerTokenSum[asset];
    }

    /// @notice Returns claimable reward of `asset` by `user`
    function getClaimableReward(address asset, address user) external view returns (uint256) {
        return claimableReward[asset][user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

/// @title Chainlink
/// @notice Consumes price data
contract Chainlink {
    // -- Constants -- //
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant GRACE_PERIOD_TIME = 3600;
    uint256 public constant RATE_STALE_PERIOD = 86400;

    // -- Variables -- //
    AggregatorV3Interface internal sequencerUptimeFeed;

    // -- Errors -- //
    error SequencerDown();
    error GracePeriodNotOver();
    error StaleRate();

    /**
     * For a list of available sequencer proxy addresses, see:
     * https://docs.chain.link/docs/l2-sequencer-flag/#available-networks
     */

    // -- Constructor -- //
    constructor() {
        // Arbitrum L2 sequencer feed
        sequencerUptimeFeed = AggregatorV3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    }

    // Returns the latest price
    function getPrice(address feed) public view returns (uint256) {
        if (feed == address(0)) return 0;

        // prettier-ignore
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;

        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);

        // prettier-ignore
        (
            /*uint80 roundID*/, 
            int price, 
            /*uint startedAt*/,
            uint256 updatedAt, 
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        if (updatedAt < block.timestamp - RATE_STALE_PERIOD) {
            revert StaleRate();
        }

        uint8 decimals = priceFeed.decimals();

        // Return 18 decimals standard
        return (uint256(price) * UNIT) / 10 ** decimals;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title Governable
/// @notice Basic access control mechanism, gov has access to certain functions
contract Governable {
    address public gov;

    event SetGov(address prevGov, address nextGov);

    /// @dev Initializes the contract setting the deployer address as governance
    constructor() {
        _setGov(msg.sender);
    }

    /// @dev Reverts if called by any account other than gov
    modifier onlyGov() {
        require(msg.sender == gov, '!gov');
        _;
    }

    /// @notice Sets a new governance address
    /// @dev Only callable by governance
    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    /// @notice Sets a new governance address
    /// @dev Internal function without access restriction
    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;
        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './Governable.sol';
import '../stores/RoleStore.sol';

/// @title Roles
/// @notice Role-based access control mechanism via onlyContract modifier
contract Roles is Governable {
    bytes32 public constant CONTRACT = keccak256('CONTRACT');

    RoleStore public roleStore;

    /// @dev Initializes roleStore address
    constructor(RoleStore rs) Governable() {
        roleStore = rs;
    }

    /// @dev Reverts if caller address has not the contract role
    modifier onlyContract() {
        require(roleStore.hasRole(msg.sender, CONTRACT), '!contract-role');
        _;
    }
}