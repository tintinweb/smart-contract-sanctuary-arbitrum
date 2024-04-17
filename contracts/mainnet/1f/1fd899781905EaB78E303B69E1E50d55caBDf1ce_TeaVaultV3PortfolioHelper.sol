// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity ^0.8.0;

interface ITeaVaultV3Pair {

    error PoolNotInitialized();
    error InvalidFeePercentage();
    error InvalidFeeCap();
    error InvalidShareAmount();
    error PositionLengthExceedsLimit();
    error InvalidPriceSlippage(uint256 amount0, uint256 amount1);
    error PositionDoesNotExist();
    error ZeroLiquidity();
    error CallerIsNotManager();
    error InvalidCallbackStatus();
    error InvalidCallbackCaller();
    error SwapInZeroLiquidityRegion();
    error TransactionExpired();
    error InvalidSwapToken();
    error InvalidSwapReceiver();
    error InsufficientSwapResult(uint256 minAmount, uint256 convertedAmount);
    error InvalidTokenOrder();

    event TeaVaultV3PairCreated(address indexed teaVaultAddress);
    event FeeConfigChanged(address indexed sender, uint256 timestamp, FeeConfig feeConfig);
    event ManagerChanged(address indexed sender, address indexed newManager);
    event ManagementFeeCollected(uint256 shares);
    event DepositShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event WithdrawShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeShares);
    event AddLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event RemoveLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Collect(address indexed pool, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1);
    event CollectSwapFees(address indexed pool, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event Swap(bool indexed zeroForOne, bool indexed exactInput, uint256 amountIn, uint256 amountOut);

    /// @notice Fee config structure
    /// @param vault Fee goes to this address
    /// @param entryFee Entry fee in 0.0001% (collected when depositing)
    /// @param exitFee Exit fee in 0.0001% (collected when withdrawing)
    /// @param performanceFee Platform performance fee in 0.0001% (collected for each cycle, from profits)
    /// @param managementFee Platform yearly management fee in 0.0001% (collected when depositing/withdrawing)
    struct FeeConfig {
        address vault;
        uint24 entryFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
    }

    /// @notice Uniswap V3 position structure
    /// @param tickLower Tick lower bound
    /// @param tickUpper Tick upper bound
    /// @param liquidity Liquidity size
    struct Position {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    function DECIMALS_MULTIPLIER() external view returns (uint256);

    /// @notice get asset token0 address
    /// @return token0 token0 address
    function assetToken0() external view returns (address token0);

    /// @notice get asset token1 address
    /// @return token1 token1 address
    function assetToken1() external view returns (address token1);

    /// @notice get vault balance of token0
    /// @return amount vault balance of token0
    function getToken0Balance() external view returns (uint256 amount);

    /// @notice get vault balance of token1
    /// @return amount vault balance of token1
    function getToken1Balance() external view returns (uint256 amount);

    /// @notice get pool token and price info
    /// @return token0 token0 address
    /// @return token1 token1 address
    /// @return decimals0 token0 decimals
    /// @return decimals1 token1 decimals
    /// @return feeTier current pool price in tick
    /// @return sqrtPriceX96 current pool price in sqrtPriceX96
    /// @return tick current pool price in tick
    function getPoolInfo() external view returns (
        address token0,
        address token1,
        uint8 decimals0,
        uint8 decimals1,
        uint24 feeTier,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Set fee structure and vault addresses
    /// @notice Only available to admins
    /// @param _feeConfig Fee structure settings
    function setFeeConfig(FeeConfig calldata _feeConfig) external;

    /// @notice Assign fund manager
    /// @notice Only the owner can do this
    /// @param _manager Fund manager address
    function assignManager(address _manager) external;

    /// @notice Collect management fee by share token inflation
    /// @notice Only fund manager can do this
    /// @return collectedShares Share amount collected by minting
    function collectManagementFee() external returns (uint256 collectedShares);

    /// @notice Mint shares and deposit token0 and token1
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    function deposit(
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external returns (uint256 depositedAmount0, uint256 depositedAmount1);

    /// @notice Burn shares and withdraw token0 and token1
    /// @param _shares Share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    function withdraw(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Add liquidity to a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be added to the position
    /// @param _amount0Min Minimum token0 amount to be added to the position
    /// @param _amount1Min Minimum token1 amount to be added to the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount added to the position
    /// @return amount1 Token1 amount added to the position
    function addLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Remove liquidity from a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be removed from the position
    /// @param _amount0Min Minimum token0 amount to be removed from the position
    /// @param _amount1Min Minimum token1 amount to be removed from the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount removed from the position
    /// @return amount1 Token1 amount removed from the position
    function removeLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collect swap fee of a position
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Token0 amount collected from the position
    /// @return amount1 Token1 amount collected from the position
    function collectPositionSwapFee(
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Collect swap fee of all positions
    /// @notice Only fund manager can do this
    /// @return amount0 Token0 amount collected from the positions
    /// @return amount1 Token1 amount collected from the positions
    function collectAllSwapFee() external returns (uint128 amount0, uint128 amount1);

    /// @notice Swap tokens on the pool with exact input amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountIn Amount of input token
    /// @param _amountOutMin Required minimum output token amount
    /// @param _minPriceInSqrtPriceX96 Minimum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountOut Output token amount
    function swapInputSingle(
        bool _zeroForOne,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint160 _minPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountOut);


    /// @notice Swap tokens on the pool with exact output amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountOut Output token amount
    /// @param _amountInMax Required maximum input token amount
    /// @param _maxPriceInSqrtPriceX96 Maximum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountIn Input token amount
    function swapOutputSingle(
        bool _zeroForOne,
        uint256 _amountOut,
        uint256 _amountInMax,
        uint160 _maxPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountIn);

    /// @notice Process batch operations in one transation
    /// @return results Results in bytes array
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Get position info by specifying tickLower and tickUpper of the position
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        int24 _tickLower,
        int24 _tickUpper
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get position info by specifying position index
    /// @param _index Position index
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        uint256 _index
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get all position info
    /// @return amount0 All positions token0 amount
    /// @return amount1 All positions token1 amount
    /// @return fee0 All positions pending fee token0 amount
    /// @return fee1 All positions pending fee token1 amount
    function allPositionInfo() external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get underlying assets hold by this vault
    /// @return amount0 Total token0 amount
    /// @return amount1 Total token1 amount
    function vaultAllUnderlyingAssets() external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get vault value in token0
    /// @return value0 Vault value in token0
    function estimatedValueInToken0() external view returns (uint256 value0);

    /// @notice Get vault value in token1
    /// @return value1 Vault value in token1
    function estimatedValueInToken1() external view returns (uint256 value1);

    /// @notice Calculate liquidity of a position from amount0 and amount1
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param amount0 amount of token0
    /// @param amount1 amount of token1
    /// @return liquidity calculated liquidity 
    function getLiquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128 liquidity);

    /// @notice Calculate amount of tokens required for liquidity of a position
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param liquidity amount of liquidity
    /// @return amount0 amount of token0 required
    /// @return amount1 amount of token1 required
    function getAmountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get all open positions
    /// @return results Array of all open positions
   function getAllPositions() external view returns (Position[] memory results);
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "../oracle/interface/IAssetOracle.sol";

pragma solidity ^0.8.0;

interface ITeaVaultV3Portfolio {

    error BaseAssetNotSet();
    error OracleNotEnabled();
    error AssetBalanceNotZero();
    error BaseAssetCannotBeAdded();
    error BaseAssetCannotBeRemoved();
    error AssetAlreadyAdded();
    error InvalidAssetType();
    error InvalidAddress();
    error InvalidFeeRate();
    error ExecuteSwapFailed(bytes reason);
    error InsufficientSwapResult(uint256 minAmount, uint256 convertedAmount);
    error InvalidSwapTokens();
    error SimulationError();
    error CallerIsNotManager();
    error CallerIsNotManagerNorOwner();
    error InvalidShareAmount();
    error InvalidArraySize();
    error InsufficientMinAmount();

    event TeaVaultV3PortCreated(address indexed teaVaultAddress, string indexed name, string indexed symbol);
    event AssetAdded(address indexed asset, uint256 timestamp);
    event AssetRemoved(address indexed asset, uint256 timestamp);
    event ManagerChanged(address indexed manager, uint256 timestamp);
    event FeeConfigChanged(FeeConfig feeConfig, uint256 timestamp);
    event Deposit(address indexed from, uint256 shares, uint256[] amounts, uint256 timestamp);
    event Withdraw(address indexed from, uint256 shares, uint256[] amounts, uint256 timestamp);
    event EntryFeeCollected(address indexed vault, uint256[] amounts, uint256 timestamp);
    event ExitFeeCollected(address indexed vault, uint256 shares, uint256 timestamp);
    event ManagementFeeCollected(address indexed vault, uint256 shares, uint256 timestamp);
    event PerformanceFeeCollected(address indexed vault, uint256 shares, uint256 timestamp);
    event Swap(address indexed manager, address indexed srcToken, address indexed dstToken, address router, uint256 amountIn, uint256 amountOut, uint256 timestamp);

    /// @notice Fee config structure
    /// @param vault Fee goes to this address
    /// @param entryFee Entry fee in bps (collected when depositing)
    /// @param exitFee Exit fee in bps (collected when withdrawing)
    /// @param managementFee Platform yearly management fee in bps (collected when depositing/withdrawing)
    /// @param performanceFee Platform performance fee in 0.0001% (collected for each cycle, from profits)
    /// @param decayFactor Performance fee reserve decay factor in UQ0.128
    struct FeeConfig {
        address vault;
        uint24 entryFee;
        uint24 exitFee;
        uint24 managementFee;
        uint24 performanceFee;
        uint256 decayFactor;
    }

    /// @notice Asset AssetType type
    /// @param Null Empty type
    /// @param Base Vault base asset
    /// @param Atomic Simple asset
    /// @param TeaVaultV3Pair TeaVaultV3Pair asset
    /// @param End End of ERC20 type, not a real type
    enum AssetType {
        Null,
        Base,
        Atomic,
        TeaVaultV3Pair,
        AToken,
        End
    }

    /// @notice Generic version of Uniswap V3 SwapRouter exactInput and exactOutput params
    /// @param path Swap path
    /// @param recipient Swap recipient
    /// @param deadline Transaction deadline
    /// @param amountInOrOut Amount input/output for exactInput/exactOutput swap
    /// @param amountOutOrInTolerance Amount output/input tolerance for exactInput/exactOutput swap
    struct SwapRouterGenericParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountInOrOut;
        uint256 amountOutOrInTolerance;
    }

    /// @notice Get number of assets
    /// @return numAssets number of assets
    function getNumberOfAssets() external view returns (uint256 numAssets);

    /// @notice Add non-base asset
    /// @notice Only the owner can do this
    /// @param _asset Asset address
    /// @param _assetType Asset AssetType
    function addAsset(ERC20Upgradeable _asset, AssetType _assetType) external;

    /// @notice Remove non-base asset
    /// @notice If asset is atomic asset, its balance must be zero.
    /// @notice If asset is composite asset (TeaVaultV3Pair or AToken), it will withdraw all remaining balances before removing.
    /// @notice Only the owner can do this
    /// @param _index Asset index
    /// @param _minTokenAmounts minium token amounts required to be converted when a composite asset is withdrawn
    /// @notice _minTokenAmounts[_index] is ignored
    function removeAsset(uint256 _index, uint256[] calldata _minTokenAmounts) external;

    /// @notice Swap all tokens of an asset via UniswapV3 and remove asset
    /// @notice Only owner can do this
    /// @param _index Asset index
    /// @param _dstToken Destination token
    /// @param _path Swap path
    /// @param _deadline Transaction deadline
    /// @param _amountOutTolerance Amount output tolerance for exactInput swap
    /// @return convertedAmount Swap output amount
    function swapAndRemoveAsset(
        uint256 _index,
        address _dstToken,
        bytes calldata _path,
        uint256 _deadline,
        uint256 _amountOutTolerance
    ) external returns (
        uint256 convertedAmount
    );

    /// @notice Get all assets
    /// @return assets All assets
    function getAssets() external view returns (ERC20Upgradeable[] memory assets);

    /// @notice Get balance of all assets
    /// @return balances Balance of all assets
    function getAssetsBalance() external view returns (uint256[] memory balances);

    /// @notice Calculate value composition in base asset
    /// @return values value of assets
    function calculateValueComposition() external view returns (uint256[] memory values);

    /// @notice Calculate total vault value in base asset
    /// @return totalValue estimated vault value in base asset
    function calculateTotalValue() external view returns (uint256 totalValue);

    /// @notice Assign weight manager
    /// @notice Only the owner can do this
    /// @param _manager Weight manager address
    function assignManager(address _manager) external;

    /// @notice Set fee structure and vault addresses
    /// @notice Only available to the owner
    /// @param _feeConfig Fee structure settings
    function setFeeConfig(FeeConfig calldata _feeConfig) external;

    /// @notice Preview how much asset tokens required to mint shares
    /// @param _shares Share amount to be minted
    /// @return amounts Required asset amounts
    function previewDeposit(uint256 _shares) external returns (uint256[] memory amounts);

    /// @notice Mint shares and deposit asset tokens
    /// @param _shares Share amount to be minted
    /// @return amounts Deposited asset amounts
    function deposit(uint256 _shares) external returns (uint256[] memory amounts);

    /// @notice Burn shares and withdraw asset tokens
    /// @param _shares Share amount to be burnt
    /// @return amounts Withdrawn asset amounts
    function withdraw(uint256 _shares) external returns (uint256[] memory amounts);

    /// @notice Collect performance fee
    /// @return collectedShares Collected performance fee in shares
    function collectPerformanceFee() external returns (uint256 collectedShares);

    /// @notice Collect management fee
    /// @return collectedShares Collected management fee in shares
    function collectManagementFee() external returns (uint256 collectedShares);

    /// @notice Supply to AAVE pool and get aToken
    /// @notice Only fund manager can do this
    /// @param _asset Asset to deposit
    /// @param _amount amount to be deposited
    function aaveSupply(address _asset, uint256 _amount) external;

    /// @notice Withdraw from AAVE pool and burn aToken
    /// @notice Only fund manager can do this
    /// @param _asset Asset to withdraw
    /// @param _amount amount to be withdrawn, use type(uint256).max to withdraw all
    /// @return withdrawAmount Withdrawn amount
    function aaveWithdraw(address _asset, uint256 _amount) external returns (uint256 withdrawAmount);

    /// @notice Deposit and get TeaVaultV3Pair share token
    /// @notice Only fund manager can do this
    /// @param _asset Asset to deposit
    /// @param _shares Composite asset share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    function v3PairDeposit(
        address _asset,
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external returns (
        uint256 depositedAmount0,
        uint256 depositedAmount1
    );

    /// @notice Withdraw and burn TeaVaultV3Pair share token
    /// @notice Only fund manager can do this
    /// @param _asset Asset to withdraw
    /// @param _shares Composite asset share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrawn token0 amount
    /// @return withdrawnAmount1 Withdrawn token1 amount
    function v3PairWithdraw(
        address _asset,
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external returns (
        uint256 withdrawnAmount0,
        uint256 withdrawnAmount1
    );

    /// @notice A helper function for manager to calculate Uniswap V3 swap path
    /// @param _isExactInput Swap mode is exactInput or not
    /// @param _tokens Swap path tokens
    /// @param _fees Swap path fees
    /// @return path Swap path
    function calculateSwapPath(
        bool _isExactInput,
        address[] calldata _tokens,
        uint24[] calldata _fees
    ) external pure returns (
        bytes memory path
    );

    /// @notice Swap assets via Uniswap V3 SwapRouter
    /// @notice Only fund manager can do this
    /// @param _isExactInput Swap mode is exactInput or not
    /// @param _srcToken Swap source token
    /// @param _dstToken Swap destination token
    /// @param _path Swap path
    /// @param _deadline Transaction deadline
    /// @param _amountInOrOut Amount input/output for exactInput/exactOutput swap
    /// @param _amountOutOrInTolerance Amount output/input tolerance for exactInput/exactOutput swap
    /// @return amountOutOrIn Swap output/input amount
    function uniswapV3SwapViaSwapRouter(
        bool _isExactInput,
        address _srcToken,
        address _dstToken,
        bytes calldata _path,
        uint256 _deadline,
        uint256 _amountInOrOut,
        uint256 _amountOutOrInTolerance
    ) external returns (
        uint256 amountOutOrIn
    );

    /// @notice Swap assets via swap router
    /// @notice Only fund manager can do this
    /// @param _srcToken Source token
    /// @param _dstToken Destination token
    /// @param _inputAmount Amount of source tokens to swap
    /// @param _swapRouter Swap router
    /// @param _data Calldata of swap router
    /// @return convertedAmount Swap output amount
    function executeSwap(
        address _srcToken,
        address _dstToken,
        uint256 _inputAmount,
        address _swapRouter,
        bytes calldata _data
    ) external returns (
        uint256 convertedAmount
    );
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity ^0.8.0;

import "../interface/ITeaVaultV3Pair.sol";
import "../interface/ITeaVaultV3Portfolio.sol";

interface ITeaVaultV3PortfolioHelper {

    enum VaultType {
        TeaVaultV3Pair,
        TeaVaultV3Portfolio
    }

    error InvalidAddress();
    error NestedMulticall();
    error OnlyInMulticall();
    error NotWETH9Vault();
    error InvalidSwapReceiver();
    error InvalidTokenAmounts();
    error InvalidTokenType();
    error MulticallFailed(uint256 index, bytes reason);
    error ExecuteSwapFailed(bytes reason);
    error InsufficientSwapResult(uint256 minAmount, uint256 convertedAmount);
    error InvalidVaultType();
    error InvalidMinOutputLength();
    error OutputTokenLessThanMinimum(uint256 index, uint256 amount, uint256 minimum);
    error InsufficientSharesMinted();
    error InsufficientValue(uint256 value, uint256 minValue);

    /// @notice Multicall for TeaVaultV3Portfolio
    /// @notice This function converts all msg.value into WETH9, and transfer required token amounts from the caller to the contract,
    /// @notice perform the transactions specified in _data, then refund all remaining ETH and tokens back to the caller.
    /// @notice Only ETH and tokens in _tokens will be refunded. Use refundTokens function to refund other tokens.
    /// @param _vaultType type of vault
    /// @param _vault address of TeaVaultV3Portfolio vault for this transaction
    /// @param _tokens Address of each token for use in this transaction
    /// @param _amounts Amounts of each token for use in this transaction
    /// @param _minOutputs Minimum amount of each token in the vault should be returned to the caller (used for slippage check on withdraw)
    /// @param _data array of function call data
    /// @return results function call results
    function multicall(
        VaultType _vaultType,
        address _vault,
        address[] calldata _tokens,        
        uint256[] calldata _amounts,
        uint256[] calldata _minOutputs,
        bytes[] calldata _data
    ) external payable returns (bytes[] memory results);

    /// @notice Deposit to TeaVaultV3Portfolio vault
    /// @notice Can only be called inside multicall
    /// @param _shares Share amount to be mint
    /// @return amounts Amounts of tokens deposited
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function deposit(
        uint256 _shares
    ) external payable returns (uint256[] memory amounts);

    /// @notice Deposit maximum possible shares to TeaVaultV3Portfolio vault
    /// @notice Can only be called inside multicall
    /// @param _minShares minimum shares to be minted
    /// @return shares Amount of shares minted
    /// @return amounts Amounts of tokens deposited
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function depositMax(uint256 _minShares) external payable returns (uint256 shares, uint256[] memory amounts);

    /// @notice Burn shares and withdraw token0 and token1 from a TeaVaultV3Portfolio vault
    /// @notice Can only be called inside multicall
    /// @param _shares Share amount to be burnt
    /// @return amounts Amounts of tokens withdrawn
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function withdraw(
        uint256 _shares
    ) external payable returns (uint256[] memory amounts);

    /// @notice Deposit to TeaVaultV3Pair vault
    /// @notice Can only be called inside multicall
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function depositV3Pair(
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable returns (uint256 depositedAmount0, uint256 depositedAmount1);

    /// @notice Deposit max possible shares to TeaVaultV3Pair vault
    /// @notice Can only be called inside multicall
    /// @param _minShares minimum shares to be minted
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return shares Amount of shares minted
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function depositV3PairMax(
        uint256 _minShares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable returns (uint256 shares, uint256 depositedAmount0, uint256 depositedAmount1);    

    /// @notice Burn shares and withdraw token0 and token1 from TeaVaultV3Pair vault
    /// @notice Can only be called inside multicall
    /// @param _shares Share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function withdrawV3Pair(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external payable returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Supply to AAVE pool and get aToken
    /// @param _asset Token to supply to AAVE pool
    /// @param _amount amount to be deposited
    function aaveSupply(address _asset, uint256 _amount) external payable;

    /// @notice Withdraw from AAVE pool and burn aToken
    /// @param _asset aToken to withdraw
    /// @param _amount amount to be withdrawn, use type(uint256).max to withdraw all
    /// @return withdrawAmount Withdrawn amount
    function aaveWithdraw(address _asset, uint256 _amount) external payable returns (uint256 withdrawAmount);

    /// @notice Withdraw all from AAVE pool and burn aToken
    /// @notice Should pair this with aaveSupply in a call chain to make sure all unused aTokens are converted
    /// @notice back to tokens so they can be refunded
    /// @param _asset aToken to withdraw
    /// @return withdrawAmount Withdrawn amount
    function aaveWithdrawMax(address _asset) external payable returns (uint256 withdrawAmount);

    /// @notice Deposit to a TeaVaultV3Pair
    /// @notice Can only be called inside multicall
    /// @param _v3pair The TeaVaultV3Pair vault to deposit to
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function v3PairDeposit(
        address _v3pair,
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable returns (uint256 depositedAmount0, uint256 depositedAmount1);

    /// @notice Withdraw from a TeaVaultV3Pair
    /// @notice Can only be called inside multicall
    /// @param _v3pair The TeaVaultV3Pair vault to deposit to
    /// @param _shares Share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function v3PairWithdraw(
        address _v3pair,
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external payable returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Withdraw all shares from a TeaVaultV3Pair
    /// @notice Can only be called inside multicall
    /// @notice Should pair this with v3PairDeposit in a call chain to make sure all unused shares are converted
    /// @notice back to tokens so they can be refunded
    /// @param _v3pair The TeaVaultV3Pair vault to deposit to
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function v3PairWithdrawMax(
        address _v3pair
    ) external payable returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Swap assets via swap router
    /// @notice Can only be called inside multicall
    /// @param _srcToken Source token
    /// @param _dstToken Destination token
    /// @param _amountInMax Max amount of source token to swap
    /// @param _amountOutMin Min amount of destination tokens to receive
    /// @param _swapRouter swap router
    /// @param _data Call data of swap router
    /// @return convertedAmount Swap output amount
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function swap(
        address _srcToken,
        address _dstToken,
        uint256 _amountInMax,
        uint256 _amountOutMin,
        address _swapRouter,
        bytes calldata _data
    ) external payable returns (uint256 convertedAmount);

    /// @notice Convert all WETH9 back to ETH
    /// @notice Can only be called inside multicall
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function convertWETH() external payable;

    /// @notice Verify if the total value is high enough, otherwise revert
    /// @notice This function checks if current value of vault shares plus all remaining tokens is higher than _minValue.
    /// @notice It uses the vault's asset oracle to estimate value.
    /// @notice This function is inteded for deposit only.
    /// @notice Can only be called inside multicall
    /// @param _minValue minimum value
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function checkV3PortfolioValue(uint256 _minValue) external payable;

    /// @notice Verify if the total value is high enough, otherwise revert
    /// @notice This function checks if current value of vault shares plus all remaining tokens is higher than _minValueInToken0 and _minValueInToken1.
    /// @notice It uses the vault's pool spot price to estimate value.
    /// @notice This function is inteded for deposit only.
    /// @notice Can only be called inside multicall
    /// @param _minValueInToken0 minimum value in token0
    /// @param _minValueInToken1 minimum value in token1
    /// @dev this function is set to payable because multicall is payable
    /// @dev otherwise calls to this function fails as solidity requires msg.value to be 0 for non-payable functions
    function checkV3PairValue(uint256 _minValueInToken0, uint256 _minValueInToken1) external payable;

    /// @notice Refund tokens
    /// @notice Can only be called inside multicall
    /// @notice Send all tokens specified in _tokens back to the send.
    /// @param _tokens Address of each token to refund
    function refundTokens(
        address[] calldata _tokens
    ) external payable;

    /// @notice Resuce stuck native tokens in the contract, send them to the caller
    /// @notice Only owner can call this function.
    /// @notice This is for emergency only. Users should not left tokens in the contract.
    /// @param _amount Amount to transfer
    function rescueEth(uint256 _amount) external;

    /// @notice Resuce stuck tokens in the contract, send them to the caller
    /// @notice Only owner can call this function.
    /// @notice This is for emergency only. Users should not left tokens in the contract.
    /// @param _token Address of the token
    /// @param _amount Amount to transfer
    function rescueFund(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH9 {

    function balanceOf(address) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);

}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity =0.8.21;

interface IAssetOracle {

    error BaseAssetCannotBeReenabled();
    error ConfigLengthMismatch();
    error BaseAssetMismatch();
    error AssetNotEnabled();
    error BatchLengthMismatched();
    error AssetNotInPool();
    error ZeroTwapIntervalNotAllowed();    

    /*
        sample: asset = USDT (decimals = 6), TWAP (USDT/USDC) = 1.001, oracle decimals = 4, amount = 123000000
        returns:
            getValue: 123 * getTwap = 1231230
            getTwap: 10010
    */

    /// @notice get oracle decimals
    function decimals() external view returns (uint8);

    /// @notice get oracle base asset
    function getBaseAsset() external view returns (address);

    /// @notice get whether asset oracle is enabled
    function isOracleEnabled(address _asset) external view returns (bool);

    /// @notice get asset value in TWAP with the given amount
    function getValue(address _asset, uint256 _amount) external view returns (uint256 value);

    /// @notice batch version of getValue
    function getBatchValue(address[] calldata _assets,uint256[] calldata _amounts) external view returns (uint256[] memory values);
    
    /// @notice get asset value in TWAP with the given amount and TWAP
    function getValueWithTwap(address _asset, uint256 _amount, uint256 _twap) external view returns (uint256 value);

    /// @notice batch version of getValueWithTwap
    function getBatchValueWithTwap(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _twaps
    ) external view returns (
        uint256[] memory values
    );

    /// @notice get unit TWAP of asset
    function getTwap(address _asset) external view returns (uint256 price);

    /// @notice batch version of getTwap
    function getBatchTwap(address[] calldata _assets) external view returns (uint256[] memory prices);
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity =0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Swapper is a helper contract for sending calls to arbitray swap router
/// @notice Since there's no need to approve tokens to Swapper, it's safe for Swapper
/// @notice to call arbitrary contracts.
contract Swapper is Ownable {

    using SafeERC20 for IERC20;

    error InvalidAddress();
    error NotAllowedCaller();

    mapping (address => bool) public allowedCallers;

    constructor() {
        allowedCallers[msg.sender] = true;
    }

    function setAllowedCaller(address _caller, bool _allow) external onlyOwner {
        allowedCallers[_caller] = _allow;
    }

    function swap(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _amountIn,
        address _swapRouter,
        bytes calldata _data
    ) external {
        // AUDIT: SRE-01M
        if (!Address.isContract(_swapRouter)) revert InvalidAddress();
        // AUDIT: SRE-02M
        if (!allowedCallers[msg.sender]) revert NotAllowedCaller();

        _srcToken.approve(_swapRouter, _amountIn);
        (bool success, bytes memory returndata) = _swapRouter.call(_data);
        uint256 length = returndata.length;
        if (!success) {
            // call failed, propagate revert data
            assembly ("memory-safe") {
                revert(add(returndata, 32), length)
            }
        }
        _srcToken.approve(_swapRouter, 0);

        // send tokens back to caller
        uint256 balance = _srcToken.balanceOf(address(this));
        if (balance > 0) {
            _srcToken.safeTransfer(msg.sender, balance);
        }

        balance = _dstToken.balanceOf(address(this));
        if (balance > 0) {
            _dstToken.safeTransfer(msg.sender, balance);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity =0.8.21;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "./interface/ITeaVaultV3PortfolioHelper.sol";
import "./interface/IWETH9.sol";
import "./interface/AAVE/IPool.sol";

import "./Swapper.sol";

interface ITeaVaultV3PortfolioAssetType {
    function assetType(address _asset) external returns (ITeaVaultV3Portfolio.AssetType);
    function assetOracle() external returns (IAssetOracle);
    function aaveATokenOracle() external returns (IAssetOracle);
    function teaVaultV3PairOracle() external returns (IAssetOracle);
}

//import "hardhat/console.sol";
contract TeaVaultV3PortfolioHelper is ITeaVaultV3PortfolioHelper, Ownable {

    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using FullMath for uint256;

    IWETH9 immutable public weth9;
    IPool immutable public aavePool;
    Swapper immutable public swapper;
    address private vault;

    constructor(address _weth9, address _aavePool) {
        weth9 = IWETH9(_weth9);
        aavePool = IPool(_aavePool);
        vault = address(0x1);

        if (_weth9 == address(0)) revert InvalidAddress();

        swapper = new Swapper();
    }

    receive() external payable onlyInMulticall {
        // allow receiving eth inside multicall
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function multicall(
        VaultType _vaultType,
        address _vault,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256[] calldata _minOutputs,
        bytes[] calldata _data
    ) external payable returns (bytes[] memory results) {
        // AUDIT: TVH-03M
        if (_vault == address(0) || _vault == address(0x1)) revert InvalidAddress();

        if (vault != address(0x1)) {
            revert NestedMulticall();
        }

        vault = _vault;

        // transfer tokens from user
        uint256 tokensLength = _tokens.length;
        bool hasWeth9;
        if (_amounts.length != tokensLength) revert InvalidTokenAmounts();
        // AUDIT: TVH-03C
        for (uint256 i; i < tokensLength; ) {
            if (_amounts[i] > 0) {
                IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
            }

            if (_tokens[i] == address(weth9)) {
                hasWeth9 = true;
            }

            unchecked { i = i + 1; }
        }

        // convert msg.value into weth9 if necessary
        if (msg.value > 0) {
            if (hasWeth9) {
                weth9.deposit{ value: msg.value }();
            }
            else {
                // vault does not support weth9, revert
                revert NotWETH9Vault();
            }
        }

        // execute commands
        results = new bytes[](_data.length);
        // AUDIT: TVH-03C
        for (uint256 i = 0; i < _data.length; ) {
            (bool success, bytes memory returndata) = address(this).delegatecall(_data[i]);
            if (success) {
                results[i] = returndata;
            }
            else {
                revert MulticallFailed(i, returndata);
            }

            unchecked { i = i + 1; }
        }

        uint256 balance;

        // refund all balances
        if (address(this).balance > 0) {
            Address.sendValue(payable(msg.sender), address(this).balance);
        }

        // refund all tokens
        // AUDIT: TVH-03C
        for (uint256 i; i < tokensLength; ) {
            balance = IERC20(_tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, balance);
            }

            unchecked { i = i + 1; }
        }

        // refund vault shares
        balance = IERC20(_vault).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_vault).safeTransfer(msg.sender, balance);
        }

        // refund all vault tokens
        if (_vaultType == VaultType.TeaVaultV3Pair) {
            if (_minOutputs.length != 2) revert InvalidMinOutputLength();

            IERC20 token0 = IERC20(ITeaVaultV3Pair(_vault).assetToken0());
            IERC20 token1 = IERC20(ITeaVaultV3Pair(_vault).assetToken1());

            balance = token0.balanceOf(address(this));
            if (balance < _minOutputs[0]) revert OutputTokenLessThanMinimum(0, balance, _minOutputs[0]);
            if (balance > 0) {
                token0.safeTransfer(msg.sender, balance);
            }

            balance = token1.balanceOf(address(this));
            if (balance < _minOutputs[1]) revert OutputTokenLessThanMinimum(1, balance, _minOutputs[1]);
            if (balance > 0) {
                token1.safeTransfer(msg.sender, balance);
            }
        }
        else if (_vaultType == VaultType.TeaVaultV3Portfolio) {
            ERC20Upgradeable[] memory vaultTokens = ITeaVaultV3Portfolio(vault).getAssets();
            tokensLength = vaultTokens.length;
            if (_minOutputs.length != tokensLength) revert InvalidMinOutputLength();

            // AUDIT: TVH-03C
            for (uint256 i; i < tokensLength; ) {
                balance = vaultTokens[i].balanceOf(address(this));
                if (balance < _minOutputs[i]) revert OutputTokenLessThanMinimum(i, balance, _minOutputs[i]);
                if (balance > 0) {
                    vaultTokens[i].safeTransfer(msg.sender, balance);
                }

                unchecked { i = i + 1; }
            }
        }
        // The compiler already ensures _vaultType to be in the enum type.
        // else {
        //     revert InvalidVaultType();
        // }

        vault = address(0x1);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function deposit(
        uint256 _shares
    ) external payable onlyInMulticall returns (uint256[] memory amounts) {
        ERC20Upgradeable[] memory tokens = ITeaVaultV3Portfolio(vault).getAssets();
        uint256 tokensLength = tokens.length;

        // AUDIT: TVH-03C
        for(uint256 i; i < tokensLength; ) {
            tokens[i].forceApprove(vault, type(uint256).max);
            unchecked { i = i + 1; }
        }
        amounts = ITeaVaultV3Portfolio(vault).deposit(_shares);

        // since vault is specified by the caller, it's safer to remove all allowances after depositing
        // AUDIT: TVH-03C
        for(uint256 i; i < tokensLength; ) {
            tokens[i].forceApprove(vault, 0);
            unchecked { i = i + 1; }
        }
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function depositMax(uint256 _minShares) external payable onlyInMulticall returns (uint256 shares, uint256[] memory amounts) {
        ERC20Upgradeable[] memory tokens = ITeaVaultV3Portfolio(vault).getAssets();
        uint256 tokensLength = tokens.length;

        // AUDIT: TVH-03C
        for(uint256 i; i < tokensLength; ) {
            tokens[i].forceApprove(vault, type(uint256).max);
            unchecked { i = i + 1; }
        }

        uint256 totalShares = IERC20(vault).totalSupply();
        if (totalShares == 0) {
            // vault is empty, calculate shares directly
            uint256 balance0 = tokens[0].balanceOf(address(this));
            shares = balance0 * (10 ** (ERC20Upgradeable(vault).decimals() - tokens[0].decimals()));
        }
        else {
            // estimate share amount
            uint256[] memory assetAmounts = ITeaVaultV3Portfolio(vault).getAssetsBalance();
            uint256 halfShares = type(uint256).max;
            // AUDIT: TVH-03C
            for (uint256 i; i < tokensLength; ) {
                if (assetAmounts[i] > 0) {
                    uint256 balance = tokens[i].balanceOf(address(this));
                    uint256 sharesForToken = balance.mulDiv(totalShares, assetAmounts[i]);
                    if (halfShares > sharesForToken) {
                        halfShares = sharesForToken;
                    }
                    assetAmounts[i] = balance;
                }
                unchecked { i = i + 1; }
            }

            // simulate depositing half of the shares
            halfShares /= 2;
            amounts = ITeaVaultV3Portfolio(vault).previewDeposit(halfShares);

            // estimate share amount again
            shares = type(uint256).max;
            // AUDIT: TVH-03C
            for (uint256 i; i < tokensLength; ) {
                if (amounts[i] > 0) {
                    uint256 sharesForToken = assetAmounts[i].mulDiv(halfShares, amounts[i]);
                    if (shares > sharesForToken) {
                        shares = sharesForToken;
                    }
                }
                unchecked { i = i + 1; }
            }
        }

        if (shares < _minShares) revert InsufficientSharesMinted();

        // deposit
        amounts = ITeaVaultV3Portfolio(vault).deposit(shares);

        // since vault is specified by the caller, it's safer to remove all allowances after depositing
        // AUDIT: TVH-03C
        for(uint256 i; i < tokensLength; ) {
            tokens[i].forceApprove(vault, 0);
            unchecked { i = i + 1; }
        }
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function withdraw(
        uint256 _shares
    ) external payable onlyInMulticall returns (uint256[] memory amounts) {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), _shares);
        amounts = ITeaVaultV3Portfolio(vault).withdraw(_shares);
    }


    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function depositV3Pair(
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable onlyInMulticall returns (uint256 depositedAmount0, uint256 depositedAmount1) {
        IERC20 token0 = IERC20(ITeaVaultV3Pair(vault).assetToken0());
        IERC20 token1 = IERC20(ITeaVaultV3Pair(vault).assetToken1());        
        token0.forceApprove(vault, type(uint256).max);
        token1.forceApprove(vault, type(uint256).max);
        (depositedAmount0, depositedAmount1) = ITeaVaultV3Pair(vault).deposit(_shares, _amount0Max, _amount1Max);

        // since vault is specified by the caller, it's safer to remove all allowances after depositing
        token0.forceApprove(vault, 0);
        token1.forceApprove(vault, 0);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function depositV3PairMax(
        uint256 _minShares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable onlyInMulticall returns (uint256 shares, uint256 depositedAmount0, uint256 depositedAmount1) {
        IERC20 token0 = IERC20(ITeaVaultV3Pair(vault).assetToken0());
        IERC20 token1 = IERC20(ITeaVaultV3Pair(vault).assetToken1());        
        token0.forceApprove(vault, type(uint256).max);
        token1.forceApprove(vault, type(uint256).max);

        uint256 totalShares = IERC20(vault).totalSupply();
        if (totalShares == 0) {
            // vault is empty, calculate shares directly
            uint256 balance0 = token0.balanceOf(address(this));
            shares = balance0 * ITeaVaultV3Pair(vault).DECIMALS_MULTIPLIER();
        }
        else {
            // estimate share amount
            (uint256 amount0, uint256 amount1) = ITeaVaultV3Pair(vault).vaultAllUnderlyingAssets();
            uint256 balance0 = token0.balanceOf(address(this));
            uint256 balance1 = token1.balanceOf(address(this));
            uint256 shares0 = amount0 == 0 ? 0 : balance0.mulDiv(totalShares, amount0);
            uint256 shares1 = amount1 == 0 ? 0 : balance1.mulDiv(totalShares, amount1);
            shares = shares0 > shares1 ? shares1 : shares0;
            // simulate depositing half of the shares
            (uint256 halfAmount0, uint256 halfAmount1) = simulateDepositV3Pair(shares / 2, _amount0Max, _amount1Max);

            // calculate actual share amount and deposit
            shares0 = halfAmount0 == 0 ? 0 : balance0.mulDiv(shares / 2, halfAmount0);
            shares1 = halfAmount1 == 0 ? 0 : balance1.mulDiv(shares / 2, halfAmount1);
            shares = shares0 > shares1 ? shares1 : shares0;
        }

        if (shares < _minShares) revert InsufficientSharesMinted();

        // deposit
        (depositedAmount0, depositedAmount1) = ITeaVaultV3Pair(vault).deposit(shares, _amount0Max, _amount1Max);

        // since vault is specified by the caller, it's safer to remove all allowances after depositing
        token0.forceApprove(vault, 0);
        token1.forceApprove(vault, 0);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function withdrawV3Pair(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external payable onlyInMulticall returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), _shares);
        (withdrawnAmount0, withdrawnAmount1) = ITeaVaultV3Pair(vault).withdraw(_shares, _amount0Min, _amount1Min);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function aaveSupply(address _asset, uint256 _amount) external payable onlyInMulticall {
        IPool.ReserveData memory data = aavePool.getReserveData(_asset);
        if (ITeaVaultV3PortfolioAssetType(vault).assetType(data.aTokenAddress) != ITeaVaultV3Portfolio.AssetType.AToken) revert InvalidAddress();

        ERC20Upgradeable(_asset).approve(address(aavePool), _amount);
        aavePool.supply(_asset, _amount, address(this), 0);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function aaveWithdraw(address _asset, uint256 _amount) external payable onlyInMulticall returns (uint256 withdrawAmount) {
        withdrawAmount = aavePool.withdraw(_asset, _amount, address(this));
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function aaveWithdrawMax(address _asset) external payable onlyInMulticall returns (uint256 withdrawAmount) {
        IPool.ReserveData memory data = aavePool.getReserveData(_asset);
        uint256 balance = ERC20Upgradeable(data.aTokenAddress).balanceOf(address(this));
        if (balance > 0) {
            withdrawAmount = aavePool.withdraw(_asset, balance, address(this));            
        }
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function v3PairDeposit(
        address _v3pair,
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external payable onlyInMulticall returns (uint256 depositedAmount0, uint256 depositedAmount1) {
        if (ITeaVaultV3PortfolioAssetType(vault).assetType(_v3pair) != ITeaVaultV3Portfolio.AssetType.TeaVaultV3Pair) revert InvalidAddress();
        ITeaVaultV3Pair v3pair = ITeaVaultV3Pair(_v3pair);
        IERC20 token0 = IERC20(v3pair.assetToken0());
        IERC20 token1 = IERC20(v3pair.assetToken1());        
        token0.forceApprove(_v3pair, type(uint256).max);
        token1.forceApprove(_v3pair, type(uint256).max);
        (depositedAmount0, depositedAmount1) = v3pair.deposit(_shares, _amount0Max, _amount1Max);

        // since v3pair is specified by the caller, it's safer to remove all allowances after depositing
        token0.forceApprove(_v3pair, 0);
        token1.forceApprove(_v3pair, 0);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function v3PairWithdraw(
        address _v3pair,
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external payable onlyInMulticall returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        (withdrawnAmount0, withdrawnAmount1) = ITeaVaultV3Pair(_v3pair).withdraw(_shares, _amount0Min, _amount1Min);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function v3PairWithdrawMax(
        address _v3pair
    ) external payable onlyInMulticall returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1) {
        uint256 shares = IERC20(_v3pair).balanceOf(address(this));
        if (shares > 0) {
            (withdrawnAmount0, withdrawnAmount1) = ITeaVaultV3Pair(_v3pair).withdraw(shares, 0, 0);
        }
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function swap(
        address _srcToken,
        address _dstToken,
        uint256 _amountInMax,
        uint256 _amountOutMin,
        address _swapRouter,
        bytes calldata _data
    ) external payable onlyInMulticall returns (uint256 convertedAmount) {
        IERC20(_srcToken).safeTransfer(address(swapper), _amountInMax);
        uint256 dstTokenBalanceBefore = IERC20(_dstToken).balanceOf(address(this));
        (bool success, bytes memory result) = address(swapper).call(
            abi.encodeWithSelector(
                Swapper.swap.selector,
                IERC20(_srcToken),
                IERC20(_dstToken),
                _amountInMax,
                _swapRouter,
                _data
            )
        );
        if (!success) revert ExecuteSwapFailed(result);
        uint256 dstTokenBalanceAfter = IERC20(_dstToken).balanceOf(address(this));
        convertedAmount = dstTokenBalanceAfter - dstTokenBalanceBefore;
        if (convertedAmount < _amountOutMin) revert InsufficientSwapResult(_amountOutMin, convertedAmount);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function convertWETH() external payable onlyInMulticall {
        uint256 balance = weth9.balanceOf(address(this));
        if (balance > 0) {
            weth9.withdraw(balance);
        }
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function checkV3PortfolioValue(uint256 _minValue) external payable onlyInMulticall {
        IERC20 vaultERC20 = IERC20(vault);
        ITeaVaultV3Portfolio vaultV3Port = ITeaVaultV3Portfolio(vault);
        ITeaVaultV3PortfolioAssetType vaultV3PortType = ITeaVaultV3PortfolioAssetType(vault);
        uint256 shares = vaultERC20.balanceOf(address(this));
        uint256 totalSupply = vaultERC20.totalSupply();
        ERC20Upgradeable[] memory assets = vaultV3Port.getAssets();

        // calculate total value
        uint256 totalValue = vaultV3Port.calculateTotalValue();
        uint256 assetValue;
        if (totalSupply > 0) {
            assetValue = totalValue.mulDiv(shares, totalSupply);
        }

        for (uint256 i; i < assets.length; ) {
            uint256 balance = assets[i].balanceOf(address(this));
            if (balance > 0) {
                ITeaVaultV3Portfolio.AssetType assetType = vaultV3PortType.assetType(address(assets[i]));
                IAssetOracle oracle;
                if (assetType == ITeaVaultV3Portfolio.AssetType.TeaVaultV3Pair) {
                    oracle = vaultV3PortType.teaVaultV3PairOracle();
                }
                else if (assetType == ITeaVaultV3Portfolio.AssetType.AToken) {
                    oracle = vaultV3PortType.aaveATokenOracle();
                }
                else {
                    oracle = vaultV3PortType.assetOracle();
                }
                assetValue += oracle.getValue(address(assets[i]), balance);
            }
            unchecked { i = i + 1; }
        }

        if (assetValue < _minValue) revert InsufficientValue(assetValue, _minValue);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function checkV3PairValue(uint256 _minValueInToken0, uint256 _minValueInToken1) external payable onlyInMulticall {
        IERC20 vaultERC20 = IERC20(vault);
        ITeaVaultV3Pair vaultV3Pair = ITeaVaultV3Pair(vault);
        uint256 shares = vaultERC20.balanceOf(address(this));
        uint256 totalSupply = vaultERC20.totalSupply();
        uint256 token0Balance = IERC20(vaultV3Pair.assetToken0()).balanceOf(address(this));
        uint256 token1Balance = IERC20(vaultV3Pair.assetToken1()).balanceOf(address(this));
        (,,,,, uint256 sqrtPriceX96,) = vaultV3Pair.getPoolInfo();

        if (_minValueInToken0 > 0) {
            uint256 totalValue = vaultV3Pair.estimatedValueInToken0();
            uint256 assetValue = totalSupply > 0 ? totalValue.mulDiv(shares, totalSupply) : 0;
            assetValue += token0Balance;
            uint256 token1Value = token1Balance.mulDiv(1 << 96, sqrtPriceX96);
            token1Value = token1Value.mulDiv(1 << 96, sqrtPriceX96);
            assetValue += token1Value;

            if (assetValue < _minValueInToken0) revert InsufficientValue(assetValue, _minValueInToken0);
        }

        if (_minValueInToken1 > 0) {
            uint256 totalValue = vaultV3Pair.estimatedValueInToken1();
            uint256 assetValue = totalSupply > 0 ? totalValue.mulDiv(shares, totalSupply) : 0;
            assetValue += token1Balance;
            uint256 token0Value = token1Balance.mulDiv(sqrtPriceX96, 1 << 96);
            token0Value = token0Value.mulDiv(sqrtPriceX96, 1 << 96);
            assetValue += token0Value;

            if (assetValue < _minValueInToken1) revert InsufficientValue(assetValue, _minValueInToken1);
        }        
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function refundTokens(
        address[] calldata _tokens
    ) external payable onlyInMulticall {
        uint256 tokensLength = _tokens.length;
        // AUDIT: TVH-03C
        for (uint256 i; i < tokensLength; ) {
            uint256 balance = IERC20(_tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, balance);
            }
            unchecked { i = i + 1; }
        }
    }    

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function rescueEth(uint256 _amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), _amount);
    }

    /// @inheritdoc ITeaVaultV3PortfolioHelper
    function rescueFund(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Simulate deposit to TeaVaultV3Pair
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    function simulateDepositV3Pair(uint256 _shares, uint256 _amount0Max, uint256 _amount1Max) internal returns (uint256 depositedAmount0, uint256 depositedAmount1) {
        (bool success, bytes memory returndata) = address(this).delegatecall(
            abi.encodeWithSelector(
                this.simulateFunctionCall.selector,
                abi.encodeWithSelector(ITeaVaultV3Pair.deposit.selector, _shares, _amount0Max, _amount1Max)
            )
        );
        
        if (success) {
            // shouldn't happen, revert
            revert();
        }
        else {
            if (returndata.length == 0) {
                // no result, revert
                revert();
            }

            (depositedAmount0, depositedAmount1) = abi.decode(returndata, (uint256, uint256));
        }
    }

    /// @dev Helper function for simulating function call
    /// @dev This function always revert, so there's no point calling it directly
    function simulateFunctionCall(bytes calldata _data) external payable onlyInMulticall {
        (bool success, bytes memory returndata) = vault.call(_data);
        
        uint256 length = returndata.length;
        if (success && length > 0) {
            assembly ("memory-safe") {
                revert(add(returndata, 32), length)
            }
        }
        else {
            revert();
        }
    }

    // modifiers
    modifier onlyInMulticall() {
        if (vault == address(0x1)) revert OnlyInMulticall();
        _;
    }
}