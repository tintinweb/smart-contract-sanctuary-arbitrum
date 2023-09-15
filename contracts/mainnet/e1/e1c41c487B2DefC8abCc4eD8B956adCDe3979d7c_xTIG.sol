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
pragma solidity ^0.8.0;

interface IExtraRewards {
    function claim() external;
    function pending(address _user, address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernanceStaking {
    function stake(uint256 _amount, uint256 _duration) external;
    function unstake(uint256 _amount) external;
    function claim() external;
    function distribute(address _token, uint256 _amount) external;
    function whitelistReward(address _rewardToken) external;
    function pending(address _user, address _token) external view returns (uint256);
    function userStaked(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IxTIG is IERC20 {
    function vestingPeriod() external view returns (uint256);
    function earlyUnlockPenalty() external view returns (uint256);
    function epochFeesGenerated(uint256 _epoch) external view returns (uint256);
    function epochAllocation(uint256 _epoch) external view returns (uint256);
    function epochAllocationClaimed(uint256 _epoch) external view returns (uint256);
    function feesGenerated(uint256 _epoch, address _trader) external view returns (uint256);
    function tigAssetValue(address _tigAsset) external view returns (uint256);
    function createVest(uint256 _from) external;
    function claimTig() external;
    function earlyClaimTig() external;
    function claimFees() external;
    function addFees(address _trader, address _tigAsset, uint256 _fees) external;
    function addTigRewards(uint256 _epoch, uint256 _amount) external;
    function setTigAssetValue(address _tigAsset, uint256 _value) external;
    function setCanAddFees(address _address, bool _allowed) external;
    function setExtraRewards(address _address) external;
    function setVestingPeriod(uint256 _time) external;
    function setEarlyUnlockPenalty(uint256 _percent) external;
    function whitelistReward(address _rewardToken) external;
    function contractPending(address _token) external view returns (uint256);
    function extraRewardsPending(address _token) external view returns (uint256);
    function pending(address _user, address _token) external view returns (uint256);
    function pendingTig(address _user) external view returns (uint256);
    function pendingEarlyTig(address _user) external view returns (uint256);
    function upcomingXTig(address _user) external view returns (uint256);
    function stakedTigBalance() external view returns (uint256);
    function userRewardBatches(address _user) external view returns (RewardBatch[] memory);
    function unclaimedAllocation(uint256 _epoch) external view returns (uint256);
    function currentEpoch() external view returns (uint256);

    struct RewardBatch {
        uint256 amount;
        uint256 unlockTime;
    }

    event TigRewardsAdded(address indexed sender, uint256 amount);
    event TigVested(address indexed account, uint256 amount);
    event TigClaimed(address indexed user, uint256 amount);
    event EarlyTigClaimed(address indexed user, uint256 amount, uint256 penalty);
    event TokenWhitelisted(address token);
    event TokenUnwhitelisted(address token);
    event RewardClaimed(address indexed user, uint256 reward);
    event VestingPeriodUpdated(uint256 time);
    event EarlyUnlockPenaltyUpdated(uint256 percent);
    event FeePermissionUpdated(address indexed protocol, bool permission);
    event TreasuryUpdated(address indexed treasury);
    event SetExtraRewards(address indexed extraRewards);
    event FeesAdded(address indexed _trader, address indexed _tigAsset, uint256 _amount, uint256 indexed _value);
    event TigAssetValueUpdated(address indexed _tigAsset, uint256 indexed _value);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./utils/IterableMappingBool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IxTIG.sol";
import "./interfaces/IGovernanceStaking.sol";
import "./interfaces/IExtraRewards.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract xTIG is IxTIG, ERC20, Ownable {

    using SafeERC20 for IERC20;
    using IterableMappingBool for IterableMappingBool.Map;

    // Constants
    uint256 public constant DIVISION_CONSTANT = 1e10;
    uint256 public constant EPOCH_PERIOD = 1 days;
    uint256 public constant MAX_VESTING_PERIOD = 30 days;
    uint256 public constant MAX_EARLY_UNLOCK_PENALTY = 75e8;

    // Contracts and addresses
    IERC20 public immutable tig;
    IGovernanceStaking public immutable staking;
    address public treasury;
    address public trading;
    IExtraRewards public extraRewards;

    // xTIG settings
    uint256 public vestingPeriod = 30 days;
    uint256 public earlyUnlockPenalty = 5e9;
    mapping(address => uint256) public tigAssetValue;
    IterableMappingBool.Map private rewardTokens;
    mapping(address => bool) public canAddFees;

    // Reward distribution logic
    mapping(uint256 => uint256) public epochFeesGenerated;
    mapping(uint256 => uint256) public epochAllocation;
    mapping(uint256 => uint256) public epochAllocationClaimed;
    mapping(address => uint256) public accRewardsPerToken;
    mapping(address => mapping(address => uint256)) public userPaid; // user => token => amount
    mapping(uint256 => mapping(address => uint256)) public feesGenerated; // 7d epoch => trader => fees
    mapping(address => RewardBatch[]) public userRewards;

    // Helpers for UI
    mapping(address => uint256) public lastClaimedEpoch; // Last xTIG claim / createVest
    mapping(address => bool) public hasEarnedBefore; // Has earned xTIG before

    /**
     * @dev Throws if called by any account that is not permissioned to store fees generated by trading.
     */
    modifier onlyPermissioned() {
        require(canAddFees[msg.sender], "!Permission");
        _;
    }

    /**
     * @notice Constructor to initialize the contract
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param _tig The TIG token address
     * @param _staking The staking contract address
     * @param _treasury The treasury address
     */
    constructor(string memory name_, string memory symbol_, IERC20 _tig, IGovernanceStaking _staking, address _treasury) ERC20(name_, symbol_) {
        require(
            address(_tig) != address(0) &&
            address(_staking) != address(0) &&
            _treasury != address(0),
            "Zero address"
        );
        tig = _tig;
        staking = _staking;
        treasury = _treasury;
        tig.approve(address(_staking), type(uint256).max);
    }

    /**
     * @notice Create vest xTIG from a specified block epoch to current epoch
     * @param _from Epoch to start vesting xTIG from
     */
    function createVest(uint256 _from) external {
        uint256 _to = block.timestamp / EPOCH_PERIOD;
        createVestTo(_from, _to);
    }

    /**
     * @notice Create vest xTIG from a specified block epoch to another specified epoch
     * @param _from Epoch to start vesting xTIG from
     * @param _to Epoch to end at
     */
    function createVestTo(uint256 _from, uint256 _to) public {
        uint256 _totalAmount;
        for (uint256 _epoch=_from; _epoch<_to; _epoch++) {
            if (epochFeesGenerated[_epoch] == 0) {
                continue;
            }
            uint256 _amount = epochAllocation[_epoch] * feesGenerated[_epoch][msg.sender] / epochFeesGenerated[_epoch];
            if (_amount == 0) {
                continue;
            }
            _totalAmount += _amount;
            delete feesGenerated[_epoch][msg.sender];
            epochAllocationClaimed[_epoch] += _amount;
        }
        require(_totalAmount != 0, "No fees generated by trader");
        lastClaimedEpoch[msg.sender] = _to;
        _claim(msg.sender);
        userRewards[msg.sender].push(RewardBatch(_totalAmount, block.timestamp + vestingPeriod));
        _mint(msg.sender, _totalAmount);
        _updateUserPaid(msg.sender);
        emit TigVested(msg.sender, _totalAmount);
        if (vestingPeriod == 0) {
            claimTig();
        }
    }

    function claimTig() public {
        uint256 _length = userRewards[msg.sender].length;
        claimTigRanged(0, _length);
    }
    /**
     * @dev Claims the TIG rewards for the caller.
     * @notice This function allows the caller to claim their accumulated TIG rewards that have passed the vesting period.
     * @param _from The index of the first reward to claim.
     * @param _to The last index of the range of reward to claim, exclusive. This is to prevent gas limit from being exceeded.
     */
    function claimTigRanged(uint256 _from, uint256 _to) public {
        _claim(msg.sender);
        RewardBatch[] storage rewardsStorage = userRewards[msg.sender];
        uint256 _length = rewardsStorage.length;
        require(_length >= _to, "_to exceeds len");

        uint256 _amount;
        while(_from < _to) {
            RewardBatch memory reward = rewardsStorage[_from];
            if (block.timestamp >= reward.unlockTime) {
                _amount += reward.amount;
                rewardsStorage[_from] = rewardsStorage[_length - 1];
                rewardsStorage.pop();
                _length--;
                _to--;
            } else {
                _from++;
            }
        }

        require(_amount != 0, "No TIG to claim");
        _burn(msg.sender, _amount);
        staking.unstake(_amount);
        _updateUserPaid(msg.sender);
        tig.safeTransfer(msg.sender, _amount);
        emit TigClaimed(msg.sender, _amount);
    }



    function earlyClaimTig() external {
        uint256 _length = userRewards[msg.sender].length;
        earlyClaimTigRanged(0, _length);
    }
    /**
     * @dev Claims the TIG rewards for the caller, with an early unlock penalty.
     * @notice Claim accumulated TIG rewards, with a penalty applied to TIG that have not passed the vesting period.
     * @param _from The index of the first reward to claim.
     * @param _to The last index of the range of reward to claim, exclusive. This is to prevent gas limit from being exceeded.
     */
    function earlyClaimTigRanged(uint256 _from, uint256 _to) public {
        RewardBatch[] storage rewardsStorage = userRewards[msg.sender];
        uint256 _length = rewardsStorage.length;
        require(_length != 0, "No TIG to claim");
        require(_length >= _to, "_to exceeds len");
        _claim(msg.sender);

        uint256 _unstakeAmount;
        uint256 _userAmount;
        while (_from < _to) {
            RewardBatch memory reward = rewardsStorage[_from];
            _unstakeAmount += reward.amount;
            if (block.timestamp >= reward.unlockTime) {
                _userAmount += reward.amount;
            } else {
                _userAmount += reward.amount*(DIVISION_CONSTANT-earlyUnlockPenalty)/DIVISION_CONSTANT;
            }

            rewardsStorage[_from] = rewardsStorage[_length - 1];
            rewardsStorage.pop();
            _length--;
            _to--;
        }

        _burn(msg.sender, _unstakeAmount);
        staking.unstake(_unstakeAmount);
        uint256 _amountForTreasury = _unstakeAmount-_userAmount;
        _updateUserPaid(msg.sender);
        tig.safeTransfer(treasury, _amountForTreasury);
        tig.safeTransfer(msg.sender, _userAmount);
        emit EarlyTigClaimed(msg.sender, _userAmount, _amountForTreasury);
    }

    /**
     * @dev Claims the fees generated by the caller.
     * @notice This function allows the caller to claim the TIG staking rewards earned by holding xTIG.
     */
    function claimFees() external {
        _claim(msg.sender);
    }

    /**
     * @dev Adds fees generated by a trader to the contract.
     * @param _trader The address of the trader.
     * @param _tigAsset The address of the asset in which fees were generated.
     * @param _fees The amount of fees generated by the trader in the specified asset.
     * @notice This function allows a permissioned address to add fees generated by a trader to the contract.
     */
    function addFees(address _trader, address _tigAsset, uint256 _fees) external onlyPermissioned {
        uint256 _value = _fees * tigAssetValue[_tigAsset] / 1e18;
        uint256 _epoch = block.timestamp / EPOCH_PERIOD;
        feesGenerated[_epoch][_trader] += _value;
        if (!hasEarnedBefore[_trader]) {
            hasEarnedBefore[_trader] = true;
            lastClaimedEpoch[_trader] = _epoch;
        }
        epochFeesGenerated[_epoch] += _value;
        emit FeesAdded(_trader, _tigAsset, _fees, _value);
    }

    /**
     * @dev Adds TIG rewards to the contract for a specific epoch.
     * @param _epoch The epoch for which to add the TIG rewards.
     * @param _amount The amount of TIG rewards to add for the specified epoch.
     * @notice This function allows the contract owner to add TIG rewards to the contract for a specific epoch.
     */
    function addTigRewards(uint256 _epoch, uint256 _amount) external onlyOwner {
        require(_epoch >= block.timestamp / EPOCH_PERIOD, "No past epochs");
        tig.safeTransferFrom(msg.sender, address(this), _amount);
        epochAllocation[_epoch] += _amount;
        _distribute();
        staking.stake(_amount, 0);
        emit TigRewardsAdded(msg.sender, _amount);
    }

    /**
     * @dev Sets the value of a tigAsset used in fee calculations.
     * @param _tigAsset The address of the tigAsset.
     * @param _value The value of the tigAsset.
     * @notice This function allows the contract owner to set the value of a tigAsset used in fee calculations.
     */
    function setTigAssetValue(address _tigAsset, uint256 _value) external onlyOwner {
        tigAssetValue[_tigAsset] = _value;
        emit TigAssetValueUpdated(_tigAsset, _value);
    }

    /**
     * @dev Sets the permission for an address to add fees generated by traders.
     * @param _address The address for which to set the fee permission.
     * @param _allowed True to allow the address to add fees, false to disallow.
     * @notice This function allows the contract owner to set the permission for an address to add fees generated by traders.
     */
    function setCanAddFees(address _address, bool _allowed) external onlyOwner {
        canAddFees[_address] = _allowed;
        emit FeePermissionUpdated(_address, _allowed);
    }

    /**
     * @dev Sets the treasury address for receiving assets.
     * @param _address The address of the treasury.
     * @notice This function allows the contract owner to set the treasury address for receiving assets.
     */
    function setTreasury(address _address) external onlyOwner {
        require(_address != address(0), "Zero address");
        treasury = _address;
        emit TreasuryUpdated(_address);
    }

    /**
     * @dev Sets the contract address for optional extra rewards.
     * @param _address The address of the contract implementing the IExtraRewards interface.
     * @notice This function allows the contract owner to set the contract address for extra rewards.
     */
    function setExtraRewards(address _address) external onlyOwner {
        _distribute();
        extraRewards = IExtraRewards(_address);
        emit SetExtraRewards(_address);
    }

    /**
     * @dev Sets the vesting period for xTIG tokens.
     * @param _time The new vesting period in seconds.
     * @notice This function allows the contract owner to set the vesting period for xTIG tokens.
     */
    function setVestingPeriod(uint256 _time) external onlyOwner {
        require(_time <= MAX_VESTING_PERIOD, "Period too long");
        vestingPeriod = _time;
        emit VestingPeriodUpdated(_time);
    }

    /**
     * @dev Sets the early unlock penalty for xTIG tokens.
     * @param _percent The new early unlock penalty as a percentage.
     * @notice This function allows the contract owner to set the early unlock penalty for xTIG tokens.
     */
    function setEarlyUnlockPenalty(uint256 _percent) external onlyOwner {
        require(_percent <= MAX_EARLY_UNLOCK_PENALTY, "Bad percent");
        earlyUnlockPenalty = _percent;
        emit EarlyUnlockPenaltyUpdated(_percent);
    }

    /**
     * @dev Whitelists a reward token for distribution.
     * @param _rewardToken The address of the reward token to whitelist.
     * @notice This function allows the contract owner to whitelist a reward token for distribution.
     */
    function whitelistReward(address _rewardToken) external onlyOwner {
        require(!rewardTokens.get(_rewardToken), "Already whitelisted");
        rewardTokens.set(_rewardToken);
        emit TokenWhitelisted(_rewardToken);
    }

    /**
     * @dev Removes a reward token from the whitelist.
     * @param _rewardToken The address of the reward token to remove from the whitelist.
     * @notice This function allows the contract owner to remove a reward token from the whitelist.
     */
    function unwhitelistReward(address _rewardToken) external onlyOwner {
        require(rewardTokens.get(_rewardToken), "Not whitelisted");
        rewardTokens.remove(_rewardToken);
        emit TokenUnwhitelisted(_rewardToken);
    }

    /**
     * @dev Returns the amount of TIG staking rewards this xTIG contract has earned.
     * @param _token The address of the reward token for which to calculate pending rewards.
     * @return The amount of reward tokens pending.
     * @notice This function allows the caller to check the amount of TIG staking rewards this xTIG contract has earned.
     */
    function contractPending(address _token) public view returns (uint256) {
        return staking.pending(address(this), _token);
    }

    /**
     * @dev Returns the amount of extra rewards this xTIG contract has earned.
     * @param _token The address of the reward token for which to calculate pending rewards.
     * @return The amount of reward tokens pending.
     * @notice This function allows the caller to check the amount of extra rewards this xTIG contract has earned.
     */
    function extraRewardsPending(address _token) public view returns (uint256) {
        if (address(extraRewards) == address(0)) return 0;
        return extraRewards.pending(address(this), _token);
    }

    /**
     * @dev Returns the amount of rewards pending for the caller.
     * @param _user The address of the user for which to calculate pending rewards.
     * @param _token The address of the token for which to calculate pending rewards.
     * @return The amount of rewards pending for the caller.
     * @notice This function allows the caller to check the amount of an user's pending rewards.
     */
    function pending(address _user, address _token) public view returns (uint256) {
        if (stakedTigBalance() == 0 || totalSupply() == 0) return 0;
        return balanceOf(_user) * (accRewardsPerToken[_token] + (contractPending(_token)*1e18/stakedTigBalance()) + (extraRewardsPending(_token)*1e18/totalSupply())) / 1e18 - userPaid[_user][_token];
    }

    /**
     * @dev Returns the amount of TIG pending for the caller as a result of xTIG vesting.
     * @param _user The address of the user for which to calculate pending TIG.
     * @return The amount of TIG pending for the caller as a result of xTIG vesting.
     * @notice This function allows the caller to check the amount of TIG pending for the caller as a result of xTIG vesting.
     */
    function pendingTig(address _user) external view returns (uint256) {
        RewardBatch[] memory rewards = userRewards[_user];
        uint256 _length = rewards.length;
        uint256 _amount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _amount = _amount + reward.amount;
            }
        }   
        return _amount;     
    }

    /**
     * @dev Returns the amount of TIG pending for the caller with an early unlock penalty.
     * @param _user The address of the user for which to calculate pending rewards.
     * @return The amount of TIG pending for the caller with an early unlock penalty.
     * @notice This function allows the caller to check the amount of TIG pending for the caller with an early unlock penalty.
     */
    function pendingEarlyTig(address _user) external view returns (uint256) {
        RewardBatch[] memory rewards = userRewards[_user];
        uint256 _length = rewards.length;
        uint256 _amount;
        for (uint256 i=0; i<_length; i++) {
            RewardBatch memory reward = rewards[i];
            if (block.timestamp >= reward.unlockTime) {
                _amount += reward.amount;
            } else {
                _amount += reward.amount*(DIVISION_CONSTANT-earlyUnlockPenalty)/DIVISION_CONSTANT;
            }
        }
        return _amount;  
    }

    /**
     * @dev Returns the amount of upcoming xTIG tokens that the caller will receive in the current epoch.
     * @param _user The address of the user for which to calculate upcoming xTIG tokens.
     * @return The amount of upcoming xTIG tokens that the caller will receive in the current epoch.
     * @notice This function allows the caller to check the amount of upcoming xTIG tokens they will receive in the current epoch.
     */
    function upcomingXTig(address _user) external view returns (uint256) {
        uint256 _epoch = block.timestamp / EPOCH_PERIOD;
        if (epochFeesGenerated[_epoch] == 0) return 0;
        return epochAllocation[_epoch] * feesGenerated[_epoch][_user] / epochFeesGenerated[_epoch];
    }

    /**
     * @dev Returns the amount of xTIG tokens claimable by the caller from a specified epoch to current epoch.
     * @param _user The address of the user for which to calculate claimable xTIG tokens.
     * @param _from The starting epoch for calculating claimable xTIG tokens.
     * @return The amount of xTIG tokens claimable by the caller from a specified epoch to current epoch.
     * @notice This function allows the caller to check the amount of xTIG tokens claimable from a specified epoch to current epoch.
     */
    function claimableXTig(address _user, uint256 _from) external view returns (uint256) {
        uint256 _to = block.timestamp / EPOCH_PERIOD;
        return claimableXTigTo(_user, _from, _to);
    }

    /**
     * @dev Returns the amount of xTIG tokens claimable by the caller in a specific epoch range.
     * @param _user The address of the user for which to calculate claimable xTIG tokens.
     * @param _from The starting epoch for calculating claimable xTIG tokens.
     * @return The amount of xTIG tokens claimable by the caller in the specified epoch range.
     * @notice This function allows the caller to check the amount of xTIG tokens claimable in a specific epoch range.
     */
    function claimableXTigTo(address _user, uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 _amount;
        for (uint256 _epoch=_from; _epoch<_to; _epoch++) {
            if (epochFeesGenerated[_epoch] == 0) {
                continue;
            }
            _amount += epochAllocation[_epoch] * feesGenerated[_epoch][_user] / epochFeesGenerated[_epoch];
        }
        return _amount;
    }

    /**
     * @dev Returns the total amount of TIG tokens staked by the contract.
     * @return The total amount of TIG tokens staked by the contract.
     * @notice This function allows anyone to check the total amount of TIG tokens staked by the contract.
     */
    function stakedTigBalance() public view returns (uint256) {
        return staking.userStaked(address(this));
    }

    /**
     * @dev Returns an array of vested xTIG batches for the given user.
     * @param _user The address of the user for which to retrieve vested xTIG batches.
     * @return An array of vested xTIG batches for the given user.
     * @notice This function allows the caller to retrieve an array of vested xTIG batches for the given user.
     */
    function userRewardBatches(address _user) external view returns (RewardBatch[] memory) {
        return userRewards[_user];
    }

    /**
     * @dev Returns the unclaimed allocation for a specific epoch.
     * @param _epoch The epoch for which to retrieve the unclaimed allocation.
     * @return The unclaimed allocation for the specified epoch.
     * @notice This function allows the caller to retrieve the unclaimed allocation for a specific epoch.
     */
    function unclaimedAllocation(uint256 _epoch) external view returns (uint256) {
        return epochAllocation[_epoch] - epochAllocationClaimed[_epoch];
    }

    /**
     * @dev Returns the current epoch.
     * @return The current epoch.
     * @notice This function allows anyone to check the current epoch.
     */
    function currentEpoch() external view returns (uint256) {
        return block.timestamp / EPOCH_PERIOD;
    }

    /**
     * @dev Internal function to claim rewards for the caller.
     * @param _user The address of the user for which to claim rewards.
     * @notice This function allows the contract to internally claim rewards for the caller.
     */
    function _claim(address _user) internal {
        _distribute();
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            uint256 _pending = pending(_user, _token);
            if (_pending != 0) {
                userPaid[_user][_token] += _pending;
                IERC20(_token).safeTransfer(_user, _pending);
                emit RewardClaimed(_user, _pending);
            }
        }
    }

    /**
     * @dev Internal function to distribute rewards among xTIG holders.
     * @notice This function allows the contract to internally distribute rewards among xTIG holders.
     */
    function _distribute() internal {
        uint256 _length = rewardTokens.size();
        uint256[] memory _balancesBefore = new uint256[](_length);
        for (uint256 i=0; i<_length; i++) {
            address _token = rewardTokens.getKeyAtIndex(i);
            _balancesBefore[i] = IERC20(_token).balanceOf(address(this));
        }
        if (address(extraRewards) != address(0)) {
            extraRewards.claim();
        }
        staking.claim();
        for (uint256 i=0; i<_length; i++) {
            address _token = rewardTokens.getKeyAtIndex(i);
            uint256 _amount = IERC20(_token).balanceOf(address(this)) - _balancesBefore[i];
            if (stakedTigBalance() == 0 || totalSupply() == 0) {
                IERC20(_token).safeTransfer(treasury, _amount);
                continue;
            }
            uint256 _amountPerStakedTig = _amount*1e18/stakedTigBalance();
            accRewardsPerToken[_token] += _amountPerStakedTig;
            IERC20(_token).safeTransfer(treasury, _amount-_amount*totalSupply()/stakedTigBalance());
        }
    }

    /**
     * @dev Internal function to update the paid rewards for a user.
     * @param _user The address of the user for which to update the paid rewards.
     * @notice This function allows the contract to internally update the paid rewards for a user.
     */
    function _updateUserPaid(address _user) internal {
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            userPaid[_user][_token] = balanceOf(_user) * accRewardsPerToken[_token] / 1e18;
        }
    }

    /**
     * @dev Override transfer to disallow transfers.
     */
    function _transfer(address, address, uint256) internal override {
        revert("xTIG: No transfer");
    }
}