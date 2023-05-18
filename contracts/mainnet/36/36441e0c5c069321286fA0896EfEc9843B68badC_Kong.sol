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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);
    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint _ownerFeeShare, address _feeTo);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface ICamelotRouter is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;


}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./Node.sol";
import "./Camelot/ICamelotRouter.sol";
import "./Camelot/ICamelotFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Kong is ERC20, Ownable {
    Node public node;
    ICamelotRouter public camelotRouter;
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // ETH/USD Arbitrum

    address public camelotPair;
    address public distributionPool;
    address public futureUsePool;
    address public marketing;
    address public team;

    enum Step {
        Pause,
        PresaleWhitelist,
        Presale,
        PublicSale
    }
    Step public sellingStep;

    // FEES AND TAXES
    uint256 public teamFee;
    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public rewardSwapFee;
    uint256 public pumpDumpTax;
    uint256 public sellTax;
    uint256 public transferTax;
    uint256 public swapTokensAmount;

    bool public swapping;
    bool public swapLiquify;

    uint256 constant maxSupply = 20e6 * 1e18;
    uint256 public nodesPrice = 60;
    uint16 public maxNodePresaleWhitelist = 64;
    uint16 public presalePriceWhitelist = 50;
    uint16 public maxNodePresale = 44;
    uint16 public presalePrice = 40;
    uint16[] periodsStaking = [0, 15, 30, 180];

    bytes32 merkleRoot;

    mapping(address => bool) public feeExempts;
    mapping(address => uint8) nodePerWalletPresaleWhitelist;
    mapping(address => uint8) nodePerWalletPresale;

    event StepChanged(uint8 step);
    event TeamChanged(address team);
    event SellTaxChanged(uint256 sellTax);
    event TeamFeeChanged(uint256 teamFee);
    event MarketingChanged(address marketing);
    event SwapLiquifyChanged(bool swapLiquify);
    event NodesPriceChanged(uint256 nodesPrice);
    event RewardsFeeChanged(uint256 rewardsFee);
    event PumpDumpTaxChanged(uint256 pumpDumpTax);
    event TransferTaxChanged(uint256 transferTax);
    event PresalePriceChanged(uint16 presalePrice);
    event RewardSwapFeeChanged(uint256 rewardSwapFee);
    event FutureUsePoolChanged(address futureUsePool);
    event MaxNodePresaleChanged(uint16 maxNodePresale);
    event NodeManagementChanged(address nodeManagement);
    event PeriodsStakingChanged(uint16[] periodsStaking);
    event FeeExemptsChanged(address owner, bool isExempt);
    event DistributionPoolChanged(address distributionPool);

    event SwapTokensAmountChanged(uint256 swapTokensAmount);
    event LiquidityPoolFeeChanged(uint256 liquidityPoolFee);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event PresalePriceWhitelistChanged(uint16 presalePriceWhitelist);
    event MaxNodePresaleWhitelistChanged(uint16 maxNodePresaleWhitelist);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event AllRewardsClaimed(
        address owner,
        uint256 rewards,
        uint256 meetingFees,
        uint256 kongFees
    );
    event NodeUnstaked(
        address owner,
        uint256 nodeId,
        uint256 rewards,
        uint256 meetingFees,
        uint256 kongFees
    );
    event RewardClaimed(
        address owner,
        uint256 nodeId,
        uint256 rewards,
        uint256 meetingFees,
        uint256 kongFees
    );

    error WrongStep();
    error WrongType();
    error AmountNull();
    error NodeStaked();
    error NotOwnerNode();
    error NotEnoughETH();
    error NotEnoughKong();
    error NotWhitelisted();
    error LengthMismatch();
    error AllSupplyNotMinted();
    error MaxNodePresaleReached();

    constructor(
        bytes32 _merkleRoot,
        uint256 _swapAmount,
        address _camRouter,
        address[] memory _addresses,
        uint256[] memory _balances,
        uint256[] memory _fees
    )
        ERC20("KONG", "BNA")
    {
        if (_addresses.length == 0) revert AmountNull();
        if (_addresses.length != _balances.length) revert LengthMismatch();
        if (_fees.length != 7) revert LengthMismatch();

        merkleRoot = _merkleRoot;

        distributionPool = _addresses[0];
        futureUsePool = _addresses[1];
        marketing = _addresses[2];
        team = _addresses[3];

        ICamelotRouter _camelotRouter = ICamelotRouter(_camRouter);
        camelotRouter = _camelotRouter;

        teamFee = _fees[0];
        rewardsFee = _fees[1];
        liquidityPoolFee = _fees[2];
        rewardSwapFee = _fees[3];
        pumpDumpTax = _fees[4];
        sellTax = _fees[5];
        transferTax = _fees[6];
        swapTokensAmount = _swapAmount * 1e18;

        feeExempts[address(this)] = true;
        feeExempts[address(camelotRouter)] = true;
        feeExempts[owner()] = true;

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], _balances[i] * 1e18);
        }
        if (totalSupply() != maxSupply) revert AllSupplyNotMinted();
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function setStep(uint8 _step) external onlyOwner {
        sellingStep = Step(_step);
        emit StepChanged(_step);
    }

    function setNodeManagement(address _nodeManagement) external onlyOwner {
        node = Node(_nodeManagement);
        emit NodeManagementChanged(_nodeManagement);
    }

    // FEES
    function setDistributionPool(
        address payable _distributionPool
    ) external onlyOwner {
        distributionPool = _distributionPool;
        emit DistributionPoolChanged(_distributionPool);
    }

    function setFutureUsePool(
        address payable _futureUsePool
    ) external onlyOwner {
        futureUsePool = _futureUsePool;
        emit FutureUsePoolChanged(_futureUsePool);
    }

    function setMarketing(address payable _marketing) external onlyOwner {
        marketing = _marketing;
        emit MarketingChanged(_marketing);
    }

    function setTeam(address payable _team) external onlyOwner {
        team = _team;
        emit TeamChanged(_team);
    }

    function setTeamFee(uint256 _teamFee) external onlyOwner {
        teamFee = _teamFee;
        emit TeamFeeChanged(_teamFee);
    }

    function setRewardsFee(uint256 _rewardsFee) external onlyOwner {
        rewardsFee = _rewardsFee;
        emit RewardsFeeChanged(_rewardsFee);
    }

    function setLiquidityPoolFee(uint256 _liquidityPoolFee) external onlyOwner {
        liquidityPoolFee = _liquidityPoolFee;
        emit LiquidityPoolFeeChanged(_liquidityPoolFee);
    }

    function setRewardSwapFee(uint256 _rewardSwapFee) external onlyOwner {
        rewardSwapFee = _rewardSwapFee;
        emit RewardSwapFeeChanged(_rewardSwapFee);
    }

    function setPumpDumpTax(uint256 _pumpDumpTax) external onlyOwner {
        pumpDumpTax = _pumpDumpTax;
        emit PumpDumpTaxChanged(_pumpDumpTax);
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
        emit SellTaxChanged(_sellTax);
    }

    function setTransferTax(uint256 _transferTax) external onlyOwner {
        transferTax = _transferTax;
        emit TransferTaxChanged(_transferTax);
    }

    function setSwapLiquify(bool _swapLiquify) external onlyOwner {
        swapLiquify = _swapLiquify;
        emit SwapLiquifyChanged(_swapLiquify);
    }

    function setSwapTokensAmount(uint256 _swapTokensAmount) external onlyOwner {
        swapTokensAmount = _swapTokensAmount * 1e18;
        emit SwapTokensAmountChanged(_swapTokensAmount);
    }

    function setFeeExempts(
        address _address,
        bool _isExempt
    ) external onlyOwner {
        feeExempts[_address] = _isExempt;
        emit FeeExemptsChanged(_address, _isExempt);
    }

    function setPresalePriceWhitelist(
        uint16 _presalePriceWhitelist
    ) external onlyOwner {
        presalePriceWhitelist = _presalePriceWhitelist;
        emit PresalePriceWhitelistChanged(_presalePriceWhitelist);
    }

    function setPresalePrice(uint16 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
        emit PresalePriceChanged(_presalePrice);
    }

    function setMaxNodePresaleWhitelist(
        uint16 _maxNodePresaleWhitelist
    ) external onlyOwner {
        maxNodePresaleWhitelist = _maxNodePresaleWhitelist;
        emit MaxNodePresaleWhitelistChanged(_maxNodePresaleWhitelist);
    }

    function setMaxNodePresale(uint16 _maxNodePresale) external onlyOwner {
        maxNodePresale = _maxNodePresale;
        emit MaxNodePresaleChanged(_maxNodePresale);
    }

    function setNodesPrice(uint256 _nodesPrice) external onlyOwner {
        nodesPrice = _nodesPrice;
        emit NodesPriceChanged(_nodesPrice);
    }

    function setPeriodsStaking(
        uint16[] calldata _periodsStaking
    ) external onlyOwner {
        if (_periodsStaking.length != 4) revert LengthMismatch();
        periodsStaking = _periodsStaking;
        emit PeriodsStakingChanged(_periodsStaking);
    }

    function buyNodes(uint256 _amount) external payable {
        if (sellingStep != Step.Presale && sellingStep != Step.PublicSale)
            revert WrongStep();
        if (_amount < 1) revert AmountNull();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && swapLiquify && !swapping && sender != owner()) {
            swapping = true;

            uint256 teamTokens = (contractTokenBalance * teamFee) / 100;
            uint256 rewardsPoolTokens = (contractTokenBalance * rewardsFee) /
                100;
            uint256 rewardsTokenstoSwap = (rewardsPoolTokens * rewardSwapFee) /
                100;
            uint256 swapTokens = (contractTokenBalance * liquidityPoolFee) /
                100;

            swapAndSendToFee(team, teamTokens);
            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(
                address(this),
                distributionPool,
                rewardsPoolTokens - rewardsTokenstoSwap
            );
            swapAndLiquify(swapTokens);
            swapTokensForEth(balanceOf(address(this)));

            swapping = false;
        }

        bool _stake;
        if (sellingStep == Step.Presale) {
            if (nodePerWalletPresale[sender] + _amount > maxNodePresale)
                revert MaxNodePresaleReached();
            if (
                msg.value <
                (_amount * presalePrice * 1e26) / uint256(getLatestPrice())
            ) revert NotEnoughETH();
            _stake = true;
            nodePerWalletPresale[sender] += uint8(_amount);
        } else {
            uint256 _nodesPrice = _amount * nodesPrice * 1e18;
            if (balanceOf(sender) < _nodesPrice) revert NotEnoughKong();
            super._transfer(sender, address(this), _nodesPrice);
        }
        for (uint256 i; i < _amount; ++i) {
            node.buyNode(sender, _stake);
        }
    }

    function buyNodesWhitelist(
        bytes32[] calldata _proof,
        uint256 _amount
    ) external payable {
        if (_amount < 1) revert AmountNull();
        if (sellingStep != Step.PresaleWhitelist) revert WrongStep();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();
        if (!_isWhiteListed(sender, _proof)) revert NotWhitelisted();
        if (
            nodePerWalletPresaleWhitelist[sender] + _amount >
            maxNodePresaleWhitelist
        ) revert MaxNodePresaleReached();
        if (
            msg.value <
            (_amount * presalePriceWhitelist * 1e26) / uint256(getLatestPrice())
        ) revert NotEnoughETH();
        nodePerWalletPresaleWhitelist[sender] += uint8(_amount);
        for (uint256 i; i < _amount; ++i) {
            node.buyNode(sender, true);
        }
    }

    function upgradeNode(uint256 _nodeId) external {
        if (sellingStep != Step.PublicSale) revert WrongStep();
        (
            uint8 nodeType,
            ,
            address nodeOwner,
            ,
            ,
            ,
            uint256 nodeStartStaking
        ) = node.nodesById(_nodeId);
        if (nodeType != 1 && nodeType != 2) revert WrongType();
        address sender = msg.sender;
        if (sender == address(0) || nodeOwner != sender) revert NotOwnerNode();
        if (nodeStartStaking > 0) revert NodeStaked();

        uint256 nodePrice = nodesPrice * 1e18;
        if (balanceOf(sender) < nodePrice) revert NotEnoughKong();

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && swapLiquify && !swapping && sender != owner()) {
            swapping = true;

            uint256 teamTokens = (contractTokenBalance * teamFee) / 100;
            uint256 rewardsPoolTokens = (contractTokenBalance * rewardsFee) /
                100;
            uint256 rewardsTokenstoSwap = (rewardsPoolTokens * rewardSwapFee) /
                100;
            uint256 swapTokens = (contractTokenBalance * liquidityPoolFee) /
                100;

            swapAndSendToFee(team, teamTokens);
            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(
                address(this),
                distributionPool,
                rewardsPoolTokens - rewardsTokenstoSwap
            );
            swapAndLiquify(swapTokens);
            swapTokensForEth(balanceOf(address(this)));

            swapping = false;
        }

        super._transfer(sender, address(this), nodePrice);
        node.upgradeNode(sender, _nodeId);
    }

    function stake(uint256 _nodeId, uint8 _periodStaking) external {
        if (sellingStep != Step.PublicSale) revert WrongStep();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();
        if (
            _periodStaking != periodsStaking[0] &&
            _periodStaking != periodsStaking[1] &&
            _periodStaking != periodsStaking[2] &&
            _periodStaking != periodsStaking[3]
        ) revert WrongType();
        node.stake(_nodeId, sender, _periodStaking);
    }

    function unstake(uint256 _nodeId) external {
        if (sellingStep != Step.PublicSale) revert WrongStep();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();
        uint256[3] memory rewards = node.unstake(_nodeId, sender);

        super._transfer(
            distributionPool,
            address(this),
            (rewards[1] + rewards[2]) * 1e18
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && !swapping && swapLiquify) {
            swapping = true;
            swapAndSendToFee(team, (rewards[1] + rewards[2]) * 1e18);
            swapping = false;
        }

        super._transfer(distributionPool, sender, rewards[0] * 1e18);
        emit NodeUnstaked(sender, _nodeId, rewards[0], rewards[1], rewards[2]);
    }

    function claimRewards(uint256 _nodeId) external {
        if (sellingStep != Step.PublicSale) revert WrongStep();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();
        uint256[3] memory rewards = node.claimRewards(sender, _nodeId);

        super._transfer(
            distributionPool,
            address(this),
            (rewards[1] + rewards[2]) * 1e18
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && !swapping && swapLiquify) {
            swapping = true;
            swapAndSendToFee(team, (rewards[1] + rewards[2]) * 1e18);
            swapping = false;
        }

        super._transfer(distributionPool, sender, rewards[0] * 1e18);
        emit RewardClaimed(sender, _nodeId, rewards[0], rewards[1], rewards[2]);
    }

    function claimAllRewards() external {
        if (sellingStep != Step.PublicSale) revert WrongStep();
        address sender = msg.sender;
        if (sender == address(0)) revert NotOwnerNode();
        uint256[3] memory rewards = node.claimAllRewards(sender);

        super._transfer(
            distributionPool,
            address(this),
            (rewards[1] + rewards[2]) * 1e18
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && !swapping && swapLiquify) {
            swapping = true;
            swapAndSendToFee(team, (rewards[1] + rewards[2]) * 1e18);
            swapping = false;
        }

        super._transfer(distributionPool, sender, rewards[0] * 1e18);
        emit AllRewardsClaimed(sender, rewards[0], rewards[1], rewards[2]);
    }

    function boostReward(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    // WHITELIST
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _isWhiteListed(
        address _account,
        bytes32[] calldata _proof
    ) private view returns (bool) {
        return _verify(_leafHash(_account), _proof);
    }

    function _leafHash(address _account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // CAMELOT
    function setRouterAddress(address _router) external onlyOwner {
        camelotRouter = ICamelotRouter(_router);
        address _camelotPair;
        try
            ICamelotFactory(camelotRouter.factory()).createPair(
                address(this),
                camelotRouter.WETH()
            )
        returns (address _pair) {
            _camelotPair = _pair;
        } catch {
            _camelotPair = ICamelotFactory(camelotRouter.factory()).getPair(
                address(this),
                camelotRouter.WETH()
            );
        }
        camelotPair = _camelotPair;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(camelotRouter), _tokenAmount);

        camelotRouter.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = camelotRouter.WETH();

        _approve(address(this), address(camelotRouter), _tokenAmount);

        camelotRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            address(0),
            block.timestamp
        );

        emit SwapTokensForETH(_tokenAmount, path);
    }

    function swapAndLiquify(uint256 _contractTokenBalance) private {
        uint256 half = _contractTokenBalance / 2;
        uint256 otherHalf = _contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;
        // add liquidity to Camelot
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendToFee(address _destination, uint256 _tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(_tokens);
        uint256 newBalance = address(this).balance - initialETHBalance;
        payable(_destination).transfer(newBalance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 newAmount = amount;

        // to avoid pump/dump
        (uint256[] memory balanceNodeTo, ) = node.getNodesDataOf(to);
        if (
            from == address(camelotPair) &&
            balanceOf(to) > 0 &&
            balanceNodeTo.length == 0 &&
            !feeExempts[to]
        ) {
            uint256 amountPumpDumpTax = (newAmount * pumpDumpTax) / 100;
            super._transfer(from, address(this), amountPumpDumpTax);
            newAmount -= amountPumpDumpTax;
        }

        if (to == address(camelotPair) && !feeExempts[from]) {
            uint256 amountSellTax = (newAmount * sellTax) / 100;
            super._transfer(from, address(this), amountSellTax);
            newAmount -= amountSellTax;
        }

        if (!feeExempts[to] && !feeExempts[from]) {
            uint256 amountTransferTax = (newAmount * transferTax) / 100;
            _burn(_msgSender(), amountTransferTax);
            newAmount -= amountTransferTax;
        }

        super._transfer(from, to, newAmount);
    }

    // receive ETH from camelotRouter when swaping
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Node is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public kong;

    struct NodeEntity {
        uint8 nodeType;
        uint16 periodStaking;
        address owner;
        uint256 id;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 startStaking;
    }

    struct User {
        uint256[] nodesIds;
        uint256[] nodesTypesAmount;
    }

    uint8 public malusPeriodStaking;
    uint8[] rewardPerDayPerType;
    uint8[] feesChancesMeeting;
    uint8[] feesAmountMeeting;
    uint8[] feesAmountKong;
    uint8[] boostAPR; // divide by 10
    uint256 public maxRewards;

    uint256 public stakingPeriod = 1 days;
    uint256 public totalNodesCreated;
    uint256[] totalNodesPerType = [0, 0, 0];

    mapping(address => User) nodesOf;
    mapping(uint256 => NodeEntity) public nodesById;

    event BoostAPRChanged(uint8[] boostAPR);
    event MaxRewardsChanged(uint256 maxRewards);
    event NodeCreated(address to, uint256 idNode);
    event StakingPeriodChanged(uint256 stakingPeriod);
    event FeesAmountKongChanged(uint8[] feesAmountKong);
    event MalusPeriodStakingChanged(uint8 malusPeriodStaking);
    event FeesAmountMeetingChanged(uint8[] feesAmountMeeting);
    event FeesChancesMeetingChanged(uint8[] feesChancesMeeting);
    event RewardPerDayPerTypeChanged(uint8[] rewardPerDayPerType);
    event NodeUpgraded(address to, uint256 idNode, uint8 nodeType);
    event NodeStaked(address from, uint256 idNode, uint16 periodStaking);

    error WrongWay();
    error NotStaked();
    error RewardZero();
    error NotOwnerNode();
    error AlreadyStaked();
    error NotEnoughTime();
    error LengthMismatch();
    error NodeDoesnotExist();
    error NotAllowedStakingPeriod();

    constructor(
        address _kong,
        uint8 _malusPeriodStaking,
        uint8[] memory _rewardPerDayPerType,
        uint8[] memory _feesChancesMeeting,
        uint8[] memory _feesAmountMeeting,
        uint8[] memory _feesAmountKong,
        uint8[] memory _boostAPR,
        uint256 _maxRewards
    ) {
        kong = IERC20(_kong);
        malusPeriodStaking = _malusPeriodStaking;
        rewardPerDayPerType = _rewardPerDayPerType;
        feesChancesMeeting = _feesChancesMeeting;
        feesAmountMeeting = _feesAmountMeeting;
        feesAmountKong = _feesAmountKong;
        boostAPR = _boostAPR;
        maxRewards = _maxRewards;
    }

    modifier onlyKong() {
        if (msg.sender != address(kong) && msg.sender != owner())
            revert WrongWay();
        _;
    }

    function _getRandom(
        uint256 _limit,
        uint256 _nonce
    ) private view returns (bool) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    totalNodesCreated,
                    _nonce
                )
            )
        ) % 100;
        return random < _limit;
    }

    function setToken(address _kong) external onlyOwner {
        kong = IERC20(_kong);
    }

    function setMalusPeriodStaking(
        uint8 _malusPeriodStaking
    ) external onlyOwner {
        malusPeriodStaking = _malusPeriodStaking;
        emit MalusPeriodStakingChanged(_malusPeriodStaking);
    }

    function setMaxRewards(uint256 _maxRewards) external onlyOwner {
        maxRewards = _maxRewards;
        emit MaxRewardsChanged(_maxRewards);
    }

    function setRewardPerDayPerType(
        uint8[] memory _rewardPerDayPerType
    ) external onlyOwner {
        if (_rewardPerDayPerType.length != 3) revert LengthMismatch();
        rewardPerDayPerType = _rewardPerDayPerType;
        emit RewardPerDayPerTypeChanged(_rewardPerDayPerType);
    }

    function setFeesChancesMeeting(
        uint8[] memory _feesChancesMeeting
    ) external onlyOwner {
        if (_feesChancesMeeting.length != 3) revert LengthMismatch();
        feesChancesMeeting = _feesChancesMeeting;
        emit FeesChancesMeetingChanged(_feesChancesMeeting);
    }

    function setFeesAmountMeeting(
        uint8[] memory _feesAmountMeeting
    ) external onlyOwner {
        if (_feesAmountMeeting.length != 3) revert LengthMismatch();
        feesAmountMeeting = _feesAmountMeeting;
        emit FeesAmountMeetingChanged(_feesAmountMeeting);
    }

    function setFeesAmountKong(
        uint8[] memory _feesAmountKong
    ) external onlyOwner {
        if (_feesAmountKong.length != 4) revert LengthMismatch();
        feesAmountKong = _feesAmountKong;
        emit FeesAmountKongChanged(_feesAmountKong);
    }

    function setBoostAPR(uint8[] memory _boostAPR) external onlyOwner {
        if (_boostAPR.length != 3) revert LengthMismatch();
        boostAPR = _boostAPR;
        emit BoostAPRChanged(_boostAPR);
    }

    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner {
        stakingPeriod = _stakingPeriod;
        emit StakingPeriodChanged(_stakingPeriod);
    }

    // BUY NODE & UPGRADE
    function buyNode(address _to, bool _stake) external onlyKong {
        User storage user = nodesOf[_to];
        uint8 period;
        uint256 start;

        if (_stake) {
            period = 5;
            start = block.timestamp;
        }

        uint256 idNode = totalNodesCreated;
        nodesById[idNode] = NodeEntity({
            nodeType: 1,
            periodStaking: period,
            owner: _to,
            id: idNode,
            creationTime: block.timestamp,
            lastClaimTime: 0,
            startStaking: start
        });
        if (user.nodesTypesAmount.length == 0) {
            user.nodesTypesAmount = [0, 0, 0];
        }
        user.nodesIds.push(idNode);
        user.nodesTypesAmount[0]++;
        totalNodesPerType[0]++;
        totalNodesCreated++;
        emit NodeCreated(_to, idNode);
    }

    function upgradeNode(address _to, uint256 _nodeId) external onlyKong {
        NodeEntity storage node = nodesById[_nodeId];
        uint8 actualNodeType = node.nodeType;
        User storage user = nodesOf[_to];

        node.nodeType++;
        node.creationTime = block.timestamp;
        user.nodesTypesAmount[actualNodeType - 1]--;
        totalNodesPerType[actualNodeType - 1]--;
        user.nodesTypesAmount[actualNodeType]++;
        totalNodesPerType[actualNodeType]++;
        emit NodeUpgraded(_to, _nodeId, actualNodeType + 1);
    }

    // STAKE & UNSTAKE
    function stake(
        uint256 _nodeId,
        address _from,
        uint16 _periodStaking
    ) external onlyKong {
        NodeEntity storage node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.startStaking > 0) revert AlreadyStaked();

        node.startStaking = block.timestamp;
        node.periodStaking = _periodStaking;
        emit NodeStaked(_from, _nodeId, _periodStaking);
    }

    function unstake(
        uint256 _nodeId,
        address _from
    ) external onlyKong returns (uint256[3] memory) {
        NodeEntity storage node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.startStaking == 0) revert NotStaked();

        uint256[3] memory rewards = getRewards(_nodeId, 0);
        if (rewards[0] == 0) revert RewardZero();
        node.lastClaimTime = block.timestamp;
        node.startStaking = 0;
        node.periodStaking = 0;
        return rewards;
    }

    // REWARDS
    function claimRewards(
        address _from,
        uint256 _nodeId
    ) external onlyKong returns (uint256[3] memory) {
        NodeEntity memory node = nodesById[_nodeId];
        if (node.owner != _from) revert NotOwnerNode();
        if (node.periodStaking > 0) revert NotAllowedStakingPeriod();
        if (node.startStaking == 0) revert NotStaked();
        uint256[3] memory rewards = getRewards(_nodeId, 0);
        if (rewards[0] == 0) revert RewardZero();
        nodesById[_nodeId].lastClaimTime = block.timestamp;
        return rewards;
    }

    function claimAllRewards(
        address _from
    ) external onlyKong returns (uint256[3] memory) {
        uint256[3] memory totalRewards;
        uint256[] memory nodesIds = nodesOf[_from].nodesIds;

        for (uint256 i; i < nodesIds.length; ++i) {
            // To solve potential revert NotEnoughTime, NotStaked and NotAllowedStakingPeriod
            NodeEntity memory node = nodesById[nodesIds[i]];
            if (node.owner != _from) revert NotOwnerNode();
            uint256 startTime;
            if (node.startStaking > node.lastClaimTime) {
                startTime = node.startStaking;
            } else {
                startTime = node.lastClaimTime;
            }
            uint256 stakedPeriod = (block.timestamp - startTime) /
                stakingPeriod;

            if (
                stakedPeriod > 0 &&
                node.startStaking > 0 &&
                node.periodStaking == 0
            ) {
                uint256[3] memory rewards = getRewards(nodesIds[i], i);
                if (rewards[0] > 0) {
                    totalRewards[0] += rewards[0];
                    totalRewards[1] += rewards[1];
                    totalRewards[2] += rewards[2];
                    nodesById[nodesIds[i]].lastClaimTime = block.timestamp;
                }
            }
        }

        if (totalRewards[0] == 0) revert RewardZero();
        return totalRewards;
    }

    function getRewardsWithoutRandomFees(
        uint256 _nodeId
    ) public view returns (uint256, uint256) {
        NodeEntity memory node = nodesById[_nodeId];
        if (node.owner == address(0)) revert NodeDoesnotExist();
        if (node.startStaking == 0) revert NotStaked();

        uint8 percentageKongFees;
        uint256 kongFees;
        uint256 stakedPeriod;
        uint256 rewards;
        uint256 startTime;

        if (node.startStaking > node.lastClaimTime) {
            startTime = node.startStaking;
        } else {
            startTime = node.lastClaimTime;
        }

        stakedPeriod = (block.timestamp - startTime) / stakingPeriod;
        if (stakedPeriod < 1) revert NotEnoughTime();

        uint period = node.periodStaking;
        if (period > 0 && stakedPeriod > period) {
            stakedPeriod = period;
        }

        rewards = stakedPeriod * rewardPerDayPerType[node.nodeType - 1];

        // BoostAPR and MalusVesting
        if (period > 0) {
            if (stakedPeriod >= period) {
                rewards = (rewards * boostAPR[node.nodeType - 1]) / 10;
            } else {
                rewards -= (rewards * malusPeriodStaking) / 100;
            }
        } else {
            if (rewards > maxRewards) rewards = maxRewards;
        }

        // KongFees
        if (stakedPeriod == 1) {
            percentageKongFees = feesAmountKong[0];
        } else if (stakedPeriod == 2) {
            percentageKongFees = feesAmountKong[1];
        } else if (stakedPeriod == 3) {
            percentageKongFees = feesAmountKong[2];
        } else {
            percentageKongFees = feesAmountKong[3];
        }
        kongFees = (rewards * percentageKongFees) / 100;

        return (rewards, kongFees);
    }

    function getRewards(
        uint256 _nodeId,
        uint256 _nonce
    ) private view returns (uint256[3] memory) {
        uint8 percentageMeetingFees;
        uint256 rewards;
        uint256 kongFees;
        uint256 meetingFees;

        NodeEntity memory node = nodesById[_nodeId];

        (rewards, kongFees) = getRewardsWithoutRandomFees(_nodeId);

        // MeetingFees
        bool isMet = _getRandom(feesChancesMeeting[node.nodeType - 1], _nonce);
        if (isMet) {
            percentageMeetingFees = feesAmountMeeting[node.nodeType - 1];
            meetingFees = (rewards * percentageMeetingFees) / 100;
        }

        rewards -= meetingFees + kongFees;

        return [rewards, meetingFees, kongFees];
    }

    // NODES INFORMATIONS
    function getNodesDataOf(
        address account
    ) external view returns (uint256[] memory, uint256[] memory) {
        return (nodesOf[account].nodesIds, nodesOf[account].nodesTypesAmount);
    }

    function getAllNodesOf(
        address account
    ) external view returns (NodeEntity[] memory) {
        uint256[] memory nodesIds = nodesOf[account].nodesIds;
        uint256 numberOfNodes = nodesOf[account].nodesIds.length;
        NodeEntity[] memory nodes = new NodeEntity[](numberOfNodes);
        for (uint256 i; i < numberOfNodes; ++i) {
            nodes[i] = nodesById[nodesIds[i]];
        }
        return nodes;
    }

    function getRewardPerDayPerType() external view returns (uint8[] memory) {
        return rewardPerDayPerType;
    }

    function getTotalNodesPerType() external view returns (uint256[] memory) {
        return totalNodesPerType;
    }
}