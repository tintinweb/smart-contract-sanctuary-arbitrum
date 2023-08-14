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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/IterableMappingBool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAutoTigAsset is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}

contract TigrisLPStaking is Ownable {

    using SafeERC20 for IERC20;
    using IterableMappingBool for IterableMappingBool.Map;
    IterableMappingBool.Map private assets;
    uint256 public constant DIVISION_CONSTANT = 1e10;
    uint256 public constant MAX_WITHDRAWAL_PERIOD = 30 days;
    uint256 public constant MAX_DEPOSIT_FEE = 1e8; // 1%
    uint256 public constant MAX_EARLY_WITHDRAW_FEE = 25e8; // 25%
    uint256 public constant MIN_INITIAL_DEPOSIT = 1e15;

    address public treasury;
    uint256 public withdrawalPeriod = 7 days;
    uint256 public depositFee;
    uint256 public earlyWithdrawFee = 10e8; // 10%
    bool public earlyWithdrawalEnabled;

    // Assets always have 18 decimals
    mapping(address => uint256) public totalStaked; // [asset] => amount
    mapping(address => uint256) public totalPendingWithdrawal; // [asset] => amount
    mapping(address => mapping(address => bool)) public isUserAutocompounding; // [user][asset] => bool
    mapping(address => mapping(address => uint256)) public userStaked; // [user][asset] => amount
    mapping(address => mapping(address => uint256)) public userPendingWithdrawal; // [user][asset] => amount
    mapping(address => mapping(address => uint256)) public withdrawTimestamp; // [user][asset] => timestamp
    mapping(address => mapping(address => uint256)) public userPaid; // [user][asset] => amount
    mapping(address => uint256) public accRewardsPerToken; // [asset] => amount
    mapping(address => uint256) public compoundedAssetValue; // [asset] => amount
    mapping(address => IAutoTigAsset) public autoTigAsset; // [asset] => autoTigAsset
    mapping(address => uint256) public depositCap; // [asset] => amount

    // Events
    event Staked(address indexed asset, address indexed user, uint256 amount, uint256 fee);
    event WithdrawalInitiated(address indexed asset, address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawalConfirmed(address indexed asset, address indexed user, uint256 amount);
    event WithdrawalCancelled(address indexed asset, address indexed user, uint256 amount);
    event EarlyWithdrawal(address indexed asset, address indexed user, uint256 amount, uint256 fee);
    event LPRewardClaimed(address indexed asset, address indexed user, uint256 amount);
    event LPRewardDistributed(address indexed asset, uint256 amount);
    event AssetWhitelisted(address indexed asset, IAutoTigAsset indexed autoTigAsset);
    event AssetUnwhitelisted(address indexed asset);
    event WithdrawalPeriodUpdated(uint256 newPeriod);
    event TreasuryUpdated(address newTreasury);
    event DepositFeeUpdated(uint256 newFee);
    event EarlyWithdrawFeeUpdated(uint256 newFee);
    event EarlyWithdrawalEnabled(bool enabled);
    event UserAutocompoundingUpdated(address indexed user, address indexed asset, bool isAutocompounding);
    event DepositCapUpdated(address indexed asset, uint256 newCap);

    /**
     * @dev Initializes the TigrisLPStaking contract with the provided treasury address.
     * @param _treasury The address of the treasury where fees will be transferred.
     * @notice The treasury address cannot be the zero address.
     */
    constructor(address _treasury) {
        require(_treasury != address(0), "ZeroAddress");
        treasury = _treasury;
    }

    /**
     * @dev Stakes a specified amount of tigAsset tokens.
     * @param _tigAsset The address of the tigAsset token to stake.
     * @param _amount The amount of tigAsset tokens to stake.
     * @notice The `_amount` will be automatically adjusted to account for the deposit fee, if applicable.
     * @notice If the user has opted for autocompounding, minted AutoTigAsset tokens will be received instead of staking.
     * @notice Emits a `Staked` event on success.
     */
    function stake(address _tigAsset, uint256 _amount) public {
        require(_tigAsset != address(0), "ZeroAddress");
        require(_amount != 0, "ZeroAmount");
        require(assets.get(_tigAsset), "Asset not allowed");
        uint256 _fee;
        if (depositFee != 0) {
            _fee = _amount * depositFee / DIVISION_CONSTANT;
            _amount -= _fee;
        }
        require(totalDeposited(_tigAsset) + totalPendingWithdrawal[_tigAsset] + _amount <= depositCap[_tigAsset], "Deposit cap exceeded");
        _claim(msg.sender, _tigAsset);
        IERC20(_tigAsset).safeTransferFrom(msg.sender, address(this), _amount + _fee);
        IERC20(_tigAsset).safeTransfer(treasury, _fee);
        if (isUserAutocompounding[msg.sender][_tigAsset]) {
            uint256 _autocompoundingAmount = _amount * 1e18 / compoundedAssetValue[_tigAsset];
            autoTigAsset[_tigAsset].mint(msg.sender, _autocompoundingAmount);
        } else {
            totalStaked[_tigAsset] += _amount;
            userStaked[msg.sender][_tigAsset] += _amount;
            userPaid[msg.sender][_tigAsset] = userStaked[msg.sender][_tigAsset] * accRewardsPerToken[_tigAsset] / 1e18;
        }
        emit Staked(_tigAsset, msg.sender, _amount, _fee);
    }

    function initiateWithdrawalMax(address _tigAsset) external {
        initiateWithdrawal(_tigAsset, userDeposited(msg.sender, _tigAsset));
    }

    /**
     * @dev Initiates a withdrawal request for a specified amount of tigAsset tokens.
     * @param _tigAsset The address of the tigAsset token for which the withdrawal is requested.
     * @param _amount The amount of tigAsset tokens to withdraw.
     * @notice Users can initiate withdrawal requests, and the funds will be available for withdrawal after the withdrawal period has elapsed.
     * @notice If the user has opted for autocompounding, AutoTigAsset tokens will be burned instead of withdrawing LP tokens.
     * @notice Emits a `WithdrawalInitiated` event on success.
     */
    function initiateWithdrawal(address _tigAsset, uint256 _amount) public {
        require(_tigAsset != address(0), "ZeroAddress");
        require(_amount != 0, "Amount must be greater than 0");
        require(userDeposited(msg.sender, _tigAsset) >= _amount, "Not enough staked");
        _claim(msg.sender, _tigAsset);
        if (isUserAutocompounding[msg.sender][_tigAsset]) {
            uint256 _autocompoundingAmount = _amount * 1e18 / compoundedAssetValue[_tigAsset];
            autoTigAsset[_tigAsset].burn(msg.sender, _autocompoundingAmount);
        } else {
            totalStaked[_tigAsset] -= _amount;
            userStaked[msg.sender][_tigAsset] -= _amount;
            userPaid[msg.sender][_tigAsset] = userStaked[msg.sender][_tigAsset] * accRewardsPerToken[_tigAsset] / 1e18;
        }
        userPendingWithdrawal[msg.sender][_tigAsset] += _amount;
        totalPendingWithdrawal[_tigAsset] += _amount;
        withdrawTimestamp[msg.sender][_tigAsset] = block.timestamp + withdrawalPeriod;
        emit WithdrawalInitiated(_tigAsset, msg.sender, _amount, withdrawTimestamp[msg.sender][_tigAsset]);
        // No need to wait for a 2-step withdrawal if the withdrawal period is 0
        if (withdrawalPeriod == 0) {
            confirmWithdrawal(_tigAsset);
        }
    }

    /**
     * @dev Confirms a withdrawal request for a specified amount of tigAssets.
     * @param _tigAsset The address of the tigAsset for which the withdrawal is confirmed.
     * @notice Users can confirm their withdrawal request after the withdrawal period has elapsed.
     * @notice Emits a `WithdrawalConfirmed` event on success.
     */
    function confirmWithdrawal(address _tigAsset) public {
        require(_tigAsset != address(0), "ZeroAddress");
        uint256 _pendingWithdrawal = userPendingWithdrawal[msg.sender][_tigAsset];
        require(_pendingWithdrawal != 0, "Nothing to withdraw");
        require(block.timestamp >= withdrawTimestamp[msg.sender][_tigAsset], "Withdrawal not ready");
        delete userPendingWithdrawal[msg.sender][_tigAsset];
        totalPendingWithdrawal[_tigAsset] -= _pendingWithdrawal;
        IERC20(_tigAsset).safeTransfer(msg.sender, _pendingWithdrawal);
        emit WithdrawalConfirmed(_tigAsset, msg.sender, _pendingWithdrawal);
    }

    /**
     * @dev Cancels a withdrawal request for a specified amount of tigAssets.
     * @param _tigAsset The address of the tigAsset for which the withdrawal is cancelled.
     * @notice Users can cancel their withdrawal request before the withdrawal period has elapsed.
     * @notice If the user has opted for autocompounding, the cancelled tigAssets will be converted back to AutoTigAsset tokens.
     * @notice Emits a `WithdrawalCancelled` event on success.
     */
    function cancelWithdrawal(address _tigAsset) external {
        require(_tigAsset != address(0), "ZeroAddress");
        uint256 _pendingWithdrawal = userPendingWithdrawal[msg.sender][_tigAsset];
        require(_pendingWithdrawal != 0, "Nothing to cancel");
        _claim(msg.sender, _tigAsset);
        delete userPendingWithdrawal[msg.sender][_tigAsset];
        totalPendingWithdrawal[_tigAsset] -= _pendingWithdrawal;
        if (isUserAutocompounding[msg.sender][_tigAsset]) {
            uint256 _autocompoundingAmount = _pendingWithdrawal * 1e18 / compoundedAssetValue[_tigAsset];
            autoTigAsset[_tigAsset].mint(msg.sender, _autocompoundingAmount);
        } else {
            totalStaked[_tigAsset] += _pendingWithdrawal;
            userStaked[msg.sender][_tigAsset] += _pendingWithdrawal;
            userPaid[msg.sender][_tigAsset] = userStaked[msg.sender][_tigAsset] * accRewardsPerToken[_tigAsset] / 1e18;
        }
        emit WithdrawalCancelled(_tigAsset, msg.sender, _pendingWithdrawal);
    }

    function earlyWithdrawalMax(address _tigAsset) external {
        earlyWithdrawal(_tigAsset, userDeposited(msg.sender, _tigAsset));
    }

    /**
     * @dev Performs an early withdrawal of a specified amount of tigAssets.
     * @param _tigAsset The address of the tigAsset for which the early withdrawal is performed.
     * @param _amount The amount of tigAssets to withdraw.
     * @notice Early withdrawal incurs a penalty fee, which is defined by the `earlyWithdrawFee` variable.
     * @notice Users can perform early withdrawal if the `earlyWithdrawalEnabled` variable is set to true.
     * @notice Emits an `EarlyWithdrawal` event on success.
     */
    function earlyWithdrawal(address _tigAsset, uint256 _amount) public {
        require(earlyWithdrawalEnabled, "Early withdrawal disabled");
        require(_tigAsset != address(0), "ZeroAddress");
        require(_amount != 0, "Amount must be greater than 0");
        require(userDeposited(msg.sender, _tigAsset) >= _amount, "Not enough staked");
        require(userPendingWithdrawal[msg.sender][_tigAsset] == 0, "Withdrawal already initiated");
        _claim(msg.sender, _tigAsset);
        if (isUserAutocompounding[msg.sender][_tigAsset]) {
            uint256 _autocompoundingAmount = _amount * 1e18 / compoundedAssetValue[_tigAsset];
            autoTigAsset[_tigAsset].burn(msg.sender, _autocompoundingAmount);
        } else {
            totalStaked[_tigAsset] -= _amount;
            userStaked[msg.sender][_tigAsset] -= _amount;
            userPaid[msg.sender][_tigAsset] = userStaked[msg.sender][_tigAsset] * accRewardsPerToken[_tigAsset] / 1e18;
        }
        uint256 _fee = _amount * earlyWithdrawFee / DIVISION_CONSTANT;
        _amount = _amount - _fee;
        IERC20(_tigAsset).safeTransfer(treasury, _fee);
        IERC20(_tigAsset).safeTransfer(msg.sender, _amount);
        emit EarlyWithdrawal(_tigAsset, msg.sender, _amount, _fee);
    }

    /**
     * @dev Allows users to claim their accrued tigAsset rewards.
     * @param _tigAsset The address of the tigAsset token for which the rewards are claimed.
     * @notice The accrued rewards are calculated based on the user's share of staked tigAsset tokens and the distributed rewards.
     * @notice Emits a `LPRewardClaimed` event on success.
     */
    function claim(address _tigAsset) public {
        _claim(msg.sender, _tigAsset);
    }

    function _claim(address _user, address _tigAsset) internal {
        require(_tigAsset != address(0), "ZeroAddress");
        uint256 _pending = pending(_user, _tigAsset);
        if (_pending == 0) return;
        userPaid[_user][_tigAsset] += _pending;
        IERC20(_tigAsset).safeTransfer(_user, _pending);
        emit LPRewardClaimed(_tigAsset, _user, _pending);
    }

    /**
     * @dev Distributes rewards to stakers and autocompounders of a whitelisted tigAsset.
     * @param _tigAsset The address of the tigAsset for which the rewards are being distributed.
     * @param _amount The amount of tigAsset rewards to be distributed.
     * @notice Only the contract owner can distribute rewards to stakers and autocompounders.
     * @notice The rewards are distributed proportionally based on the total staked tigAssets and the total autocompounded tigAssets.
     * @notice The distributed rewards are added to the reward pool and affect the reward accrual rate.
     * @notice Emits an `LPRewardDistributed` event on success.
     */
    function distribute(
        address _tigAsset,
        uint256 _amount
    ) external {
        require(_tigAsset != address(0), "ZeroAddress");
        if (!assets.get(_tigAsset) || totalDeposited(_tigAsset) == 0 || _amount == 0) return;
        try IERC20(_tigAsset).transferFrom(msg.sender, address(this), _amount) {} catch {
            return;
        }
        uint256 _toDistributeToStakers = _amount * totalStaked[_tigAsset] / totalDeposited(_tigAsset);
        uint256 _toDistributeToAutocompounders = _amount - _toDistributeToStakers;
        if (_toDistributeToStakers != 0) {
            accRewardsPerToken[_tigAsset] += _toDistributeToStakers * 1e18 / totalStaked[_tigAsset];
        }
        if (_toDistributeToAutocompounders != 0) {
            compoundedAssetValue[_tigAsset] += _toDistributeToAutocompounders * 1e18 / totalAutocompounding(_tigAsset);
        }
        emit LPRewardDistributed(_tigAsset, _amount);
    }

    /**
     * @dev Sets the autocompounding option for a tigAsset.
     * @param _tigAsset The address of the tigAsset for which the autocompounding option is being set.
     * @param _isAutocompounding A boolean indicating whether autocompounding is enabled or disabled for the user.
     * @notice Users can enable or disable autocompounding for their staked tigAssets.
     * @notice If autocompounding is enabled, tigAssets will be converted to AutoTigAsset tokens.
     * @notice If autocompounding is disabled, AutoTigAsset tokens will be converted back to tigAssets.
     * @notice Emits a `UserAutocompoundingUpdated` event on success.
     */
    function setAutocompounding(address _tigAsset, bool _isAutocompounding) public {
        require(_tigAsset != address(0), "ZeroAddress");
        _claim(msg.sender, _tigAsset);
        isUserAutocompounding[msg.sender][_tigAsset] = _isAutocompounding;
        if (_isAutocompounding) {
            uint256 _toCompoundedAssets = userStaked[msg.sender][_tigAsset] * 1e18 / compoundedAssetValue[_tigAsset];
            totalStaked[_tigAsset] -= userStaked[msg.sender][_tigAsset];
            delete userStaked[msg.sender][_tigAsset];
            autoTigAsset[_tigAsset].mint(msg.sender, _toCompoundedAssets);
        } else {
            uint256 _autoTigAssetBalance = userAutocompounding(msg.sender, _tigAsset);
            uint256 _toStakedAssets = _autoTigAssetBalance * compoundedAssetValue[_tigAsset] / 1e18;
            autoTigAsset[_tigAsset].burn(msg.sender, _autoTigAssetBalance);
            userPaid[msg.sender][_tigAsset] += _toStakedAssets * accRewardsPerToken[_tigAsset] / 1e18;
            totalStaked[_tigAsset] += _toStakedAssets;
            userStaked[msg.sender][_tigAsset] += _toStakedAssets;
        }
        emit UserAutocompoundingUpdated(msg.sender, _tigAsset, _isAutocompounding);
    }

    /**
     * @dev Whitelists an tigAsset for staking.
     * @param _tigAsset The address of the tigAsset to be whitelisted.
     * @param _initialDeposit The initial amount of tigAsset to be deposited after whitelisting.
     * @notice Only the contract owner can whitelist tigAssets.
     * @notice Emits an `AssetWhitelisted` event on success.
     */
    function whitelistAsset(address _tigAsset, uint256 _initialDeposit) external onlyOwner {
        require(_tigAsset != address(0), "ZeroAddress");
        require(!assets.get(_tigAsset), "Already whitelisted");
        assets.set(_tigAsset);
        IAutoTigAsset _autoTigAsset = autoTigAsset[_tigAsset];
        if (address(_autoTigAsset) == address(0)) {
            require(_initialDeposit >= MIN_INITIAL_DEPOSIT, "Initial deposit too small");
            _autoTigAsset = new AutoTigAsset(_tigAsset);
            autoTigAsset[_tigAsset] = _autoTigAsset;
            compoundedAssetValue[_tigAsset] = 1e18;
            // Prevent small malicious first deposit
            setAutocompounding(_tigAsset, true);
            stake(_tigAsset, _initialDeposit);
        }
        emit AssetWhitelisted(_tigAsset, _autoTigAsset);
    }

    /**
     * @dev Removes an tigAsset from the whitelist.
     * @param _tigAsset The address of the tigAsset to be removed from the whitelist.
     * @notice Only the contract owner can remove tigAsset from the whitelist.
     * @notice Emits an `AssetUnwhitelisted` event on success.
     */
    function unwhitelistAsset(address _tigAsset) external onlyOwner {
        require(_tigAsset != address(0), "ZeroAddress");
        require(assets.get(_tigAsset), "Not whitelisted");
        assets.remove(_tigAsset);
        emit AssetUnwhitelisted(_tigAsset);
    }

    /**
     * @dev Updates the withdrawal period.
     * @param _withdrawalPeriod The new withdrawal period, specified in seconds.
     * @notice Only the contract owner can update the withdrawal period.
     * @notice The maximum allowed withdrawal period is `MAX_WITHDRAWAL_PERIOD`.
     * @notice Emits a `WithdrawalPeriodUpdated` event on success.
     */
    function setWithdrawalPeriod(uint256 _withdrawalPeriod) external onlyOwner {
        require(_withdrawalPeriod <= MAX_WITHDRAWAL_PERIOD, "Withdrawal period too long");
        withdrawalPeriod = _withdrawalPeriod;
        emit WithdrawalPeriodUpdated(_withdrawalPeriod);
    }

    /**
     * @dev Updates the treasury address to receive fees.
     * @param _treasury The address of the new treasury contract.
     * @notice Only the contract owner can update the treasury address.
     * @notice Emits a `TreasuryUpdated` event on success.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "ZeroAddress");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @dev Updates the deposit fee for tigAssets.
     * @param _depositFee The new deposit fee, expressed as a percentage with `DIVISION_CONSTANT` divisor.
     * @notice Only the contract owner can update the deposit fee.
     * @notice The maximum allowed deposit fee is `MAX_DEPOSIT_FEE`.
     * @notice Emits a `DepositFeeUpdated` event on success.
     */
    function setDepositFee(uint256 _depositFee) external onlyOwner {
        require(_depositFee <= MAX_DEPOSIT_FEE, "Fee too high");
        depositFee = _depositFee;
        emit DepositFeeUpdated(_depositFee);
    }

    /**
     * @dev Updates the early withdrawal fee for tigAssets.
     * @param _earlyWithdrawFee The new early withdrawal fee, expressed as a percentage with `DIVISION_CONSTANT` divisor.
     * @notice Only the contract owner can update the early withdrawal fee.
     * @notice The maximum allowed early withdrawal fee is `MAX_EARLY_WITHDRAW_FEE`.
     * @notice Emits an `EarlyWithdrawFeeUpdated` event on success.
     */
    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(_earlyWithdrawFee <= MAX_EARLY_WITHDRAW_FEE, "Fee too high");
        earlyWithdrawFee = _earlyWithdrawFee;
        emit EarlyWithdrawFeeUpdated(_earlyWithdrawFee);
    }

    /**
     * @dev Enables or disables early withdrawal for tigAssets.
     * @param _enabled A boolean indicating whether early withdrawal is enabled or disabled.
     * @notice Only the contract owner can enable or disable early withdrawal.
     * @notice Emits an `EarlyWithdrawalEnabled` event on success.
     */
    function setEarlyWithdrawalEnabled(bool _enabled) external onlyOwner {
        earlyWithdrawalEnabled = _enabled;
        emit EarlyWithdrawalEnabled(_enabled);
    }

    /**
     * @dev Updates the deposit cap for a tigAsset.
     * @param _tigAsset The address of the tigAsset for which the deposit cap is being updated.
     * @param _depositCap The new deposit cap for the tigAsset.
     * @notice Only the contract owner can update the deposit cap for tigAssets.
     * @notice Emits a `DepositCapUpdated` event on success.
     */
    function setDepositCap(address _tigAsset, uint256 _depositCap) external onlyOwner {
        require(_tigAsset != address(0), "ZeroAddress");
        depositCap[_tigAsset] = _depositCap;
        emit DepositCapUpdated(_tigAsset, _depositCap);
    }

    /**
     * @dev Returns the total amount of tigAssets deposited and autocompounded for a specific tigAsset.
     * @param _tigAsset The address of the tigAsset for which the total deposited amount is requested.
     * @return The total amount of tigAssets deposited and autocompounded for the given tigAsset.
     */
    function totalDeposited(address _tigAsset) public view returns (uint256) {
        return totalAutocompounding(_tigAsset) * compoundedAssetValue[_tigAsset] / 1e18 + totalStaked[_tigAsset];
    }

    /**
     * @dev Returns the pending rewards of a user for a specific tigAsset.
     * @param _user The address of the user for whom the pending rewards are requested.
     * @param _tigAsset The address of the tigAsset for which the pending rewards are requested.
     * @return The amount of pending rewards for the user in the given tigAsset.
     * @notice If the user has autocompounding enabled for the tigAsset, the function returns 0, as autocompounders do not earn rewards as pending rewards.
     */
    function pending(address _user, address _tigAsset) public view returns (uint256) {
        if (isUserAutocompounding[_user][_tigAsset]) {
            return 0;
        }
        return userStaked[_user][_tigAsset] * accRewardsPerToken[_tigAsset] / 1e18 - userPaid[_user][_tigAsset];
    }

    /**
     * @dev Returns the total amount of tigAssets deposited by a user for a specific tigAsset.
     * @param _user The address of the user for whom the deposited amount is requested.
     * @param _tigAsset The address of the tigAsset for which the deposited amount is requested.
     * @return The total amount of tigAssets deposited by the user in the given tigAsset.
     * @notice If the user has autocompounding enabled for the tigAsset, the function returns the equivalent amount of tigAssets based on the compoundedAssetValue.
     * @notice If the user does not have autocompounding enabled, the function returns the amount of tigAssets staked directly.
     */
    function userDeposited(address _user, address _tigAsset) public view returns (uint256) {
        if (isUserAutocompounding[_user][_tigAsset]) {
            return userAutocompounding(_user, _tigAsset) * compoundedAssetValue[_tigAsset] / 1e18;
        } else {
            return userStaked[_user][_tigAsset];
        }
    }

    /**
     * @dev Returns the total amount of AutoTigAsset tokens (autocompounded tigAssets) for a specific tigAsset.
     * @param _tigAsset The address of the tigAsset for which the total autocompounded amount is requested.
     * @return The total amount of AutoTigAsset tokens (autocompounded tigAssets) for the given tigAsset.
     */
    function totalAutocompounding(address _tigAsset) public view returns (uint256) {
        return IERC20(autoTigAsset[_tigAsset]).totalSupply();
    }

    /**
     * @dev Returns the amount of AutoTigAsset tokens (autocompounded tigAssets) held by a user for a specific tigAsset.
     * @param _user The address of the user for whom the amount of AutoTigAsset tokens is requested.
     * @param _tigAsset The address of the tigAsset for which the amount of AutoTigAsset tokens is requested.
     * @return The amount of AutoTigAsset tokens held by the user for the given tigAsset.
     */
    function userAutocompounding(address _user, address _tigAsset) public view returns (uint256) {
        return IERC20(autoTigAsset[_tigAsset]).balanceOf(_user);
    }

    /**
     * @dev Checks if a tigAsset is whitelisted.
     * @param _tigAsset The address of the tigAsset to be checked.
     * @return A boolean indicating whether the tigAsset is whitelisted.
     */
    function isAssetWhitelisted(address _tigAsset) external view returns (bool) {
        return assets.get(_tigAsset);
    }
}

/**
 * @title AutoTigAsset
 * @dev A token contract representing AutoTigAsset tokens, which are minted and burned for users who enable autocompounding.
 */
contract AutoTigAsset is ERC20, IAutoTigAsset {

    address public immutable underlying;
    address public immutable factory;

    /**
     * @dev Creates AutoTigAsset tokens for a specific tigAsset.
     * @param _tigAsset The address of the tigAsset to be represented by the AutoTigAsset tokens.
     */
    constructor(
        address _tigAsset
    ) ERC20(
        string(abi.encodePacked("Autocompounding ", ERC20(_tigAsset).name())),
        string(abi.encodePacked("auto", ERC20(_tigAsset).symbol()))
    ) {
        require(_tigAsset != address(0), "ZeroAddress");
        underlying = _tigAsset;
        factory = msg.sender;
    }

    /**
     * @dev Modifier to restrict minting and burning to the contract factory (TigrisLPStaking).
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    /**
     * @dev Mints AutoTigAsset tokens to a specified address.
     * @param _to The address to which the AutoTigAsset tokens will be minted.
     * @param _amount The amount of AutoTigAsset tokens to mint.
     * @notice Only the contract factory (TigrisLPStaking) can mint AutoTigAsset tokens.
     */
    function mint(address _to, uint256 _amount) external onlyFactory {
        _mint(_to, _amount);
    }

    /**
     * @dev Burns AutoTigAsset tokens from a specified address.
     * @param _from The address from which the AutoTigAsset tokens will be burned.
     * @param _amount The amount of AutoTigAsset tokens to burn.
     * @notice Only the contract factory (TigrisLPStaking) can burn AutoTigAsset tokens.
     */
    function burn(address _from, uint256 _amount) external onlyFactory {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMappingBool {
    // Iterable mapping from address to bool;
    struct Map {
        address[] keys;
        mapping(address => bool) values;
        mapping(address => uint) indexOf;
    }

    function get(Map storage map, address key) internal view returns (bool) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key) internal {
        if (!map.values[key]) {
            map.values[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (map.values[key]) {
            delete map.values[key];

            uint index = map.indexOf[key];
            address lastKey = map.keys[map.keys.length - 1];

            map.indexOf[lastKey] = index;
            delete map.indexOf[key];

            map.keys[index] = lastKey;
            map.keys.pop();
        }
    }

}