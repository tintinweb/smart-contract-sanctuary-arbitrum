// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Types.sol";

interface IChildMarket {

  /// @notice Emitted when placing a bet
  event PlaceBet(
                 address indexed account,
                 uint indexed ticketId,
                 uint8 indexed option,
                 uint estimatedOdds,
                 uint size
                 );
  
  /// @notice Emitted when resolving a `Market`. Note: CLV is the "closing line
  /// value", or the latest odds when the `Market` has closed, included for
  /// reference
  event ResolveMarket(
                      uint8 indexed option,
                      uint payout,
                      uint bookmakingFee,
                      uint optionACLV,
                      uint optionBCLV
                      );

  /// @notice Emitted when user claims a `Ticket`
  event ClaimTicket(
                    address indexed account,
                    uint indexed ticketId,
                    uint ticketSize,
                    uint ticketOdds,
                    uint payout
                    );


  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Internal entry point for resolving this `ChildMarket`, which only
  /// `ParentMarket`s may call. The `ChildMarket` can either have a distinct
  /// winning `Option`, or it can be a tie. The `ChildMarket` should contain
  /// exactly enough balance to pay out for worst-case results. If profits are
  /// leftover after accounting for winning payouts, a portion (determined by
  /// `bookmakingFeeBps`) is transferred to the protocol, and the remaining
  /// profits are sent to `ToroPool`.
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveMarket(int64 scoreA, int64 scoreB) external;

  /// @notice Internal entry point for placing bets, which only `ParentMarket`s
  /// may call. This function assumes that this `ChildMarket` has already been
  /// pre-funded with user underlying tokens by the `ParentMarket`. The role of
  /// `ChildMarket` is to manage this new currency inflow, including sending and
  /// requesting funds from `ToroPool`. Note: This contract must have the
  /// `CHILD_MARKET_ROLE` before it can request funds from `ToroPool`.
  /// The `option` enum indicates which side the user wants to bet, and the size
  /// is the amount the user wishes to bet (before commission fees).
  /// Commission fees are chard at the time of placing a bet, and the remainder
  /// is the actual size placed for the wager. Hence, the `Ticket` that user
  /// receives when placing a bet will be for a slightly smaller amount than
  /// `size`.
  /// @param account Address of the user
  /// @param option The side which user picks to win
  /// @param size Size which user wishes to bet (before commission fees)
  /// @param cachedCurrentBalance Contract token balance before current bet
  function _placeBet(address account, uint8 option, uint size, uint cachedCurrentBalance) external;

  /// @notice Internal entry point for claiming winning `Ticket`s, which only
  /// `ParentMarket`s may call.  `ChildMarket` should always have enough to pay
  /// every `Ticket` without requesting for fund transfers from `ToroPool`. In
  /// the case of a tie, `Ticket`s will be refunded their initial amount
  /// (minus commission fees). This function must check the validity of the
  /// `Ticket` and if it passes all checks, releases the funds to the winning
  /// account.
  /// @param account Address of the user
  /// @param ticketId ID of the `Ticket`
  function _claimTicket(address account, uint ticketId) external;
  
  
  /** VIEW FUNCTIONS **/

  
  function toroAdmin() external view returns(address);
  
  function toroPool() external view returns(address);

  function parentMarket() external view returns(address);

  function tag() external view returns(bytes32);
  
  function currency() external view returns(IERC20);
  
  function baseOdds() external view returns(uint,uint);
  
  function optionA() external view returns(Types.Option memory);

  function optionB() external view returns(Types.Option memory);

  function labelA() external view returns(string memory);

  function sublabelA() external view returns(string memory);
  
  function labelB() external view returns(string memory);

  function sublabelB() external view returns(string memory);
  
  function deadline() external view returns(uint);

  function sportId() external view returns(uint);
  
  function betType() external view returns(uint8);

  function condition() external view returns(int64);
  
  function maxExposure() external view returns(uint);

  function totalSize() external view returns(uint);

  function totalPayout() external view returns(uint);

  function maxPayout() external view returns(uint);

  function minPayout() external view returns(uint);

  function minLockedBalance() external view returns(uint);

  function exposure() external view returns(uint,uint);
  
  function debits() external view returns(uint);

  function credits() external view returns(uint);

  /// @notice Returns the full `Ticket` struct for a given `Ticket` ID
  /// @param ticketId ID of the ticket
  /// @return Ticket The `Ticket` associated with the ID
  function getTicketById(uint ticketId) external view returns(Types.Ticket memory);

  /// @notice Returns an array of `Ticket` IDs for a given account
  /// @param account Address to query
  /// @return uint[] Array of account `Ticket` IDs
  function accountTicketIds(address account) external view returns(uint[] memory);

  /// @notice Returns an array of full `Ticket` structs for a given account
  /// @param account Address to query
  /// @return Ticket[] Array of account `Ticket`s
  function accountTickets(address account) external view returns(Types.Ticket[] memory);
  
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IChildMarket.sol";

interface IParentMarket {

  /// @notice Emitted when adding a `ChildMarket`
  event AddChildMarket(uint betType, address childMarket);

  /// @notice Emitted when `_maxExposure` is updated
  event SetMaxExposure(uint maxExposure);

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Internal entry point for resolving this `ParentMarket`, which only
  /// `SportOracle` may call.
  /// NOTE: If a particular `betType` does not exist on this `ParentMarket`, the
  /// resolution for that `betType` will be correctly ignored.
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveMarket(int64 scoreA, int64 scoreB) external;
  
  /// @notice Convenience function for adding `ChildMarket` triplet in a single
  /// transaction.
  /// NOTE: To skip adding a `ChildMarket` for any given `betType`, supply the
  /// zero address as a parameter and it will be ignored correctly.
  /// @param market1 Moneyline `ChildMarket`
  /// @param market2 Handicap `ChildMarket`
  /// @param market3 Over/Under `ChildMarket`
  function _addChildren(IChildMarket market1, IChildMarket market2, IChildMarket market3) external;
  
  /// @notice Associate a `ChildMarket` with a particular `betType` to this
  /// `ParentMarket`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param cMarket `ChildMarket` to add
  function _addChildMarket(uint betType, IChildMarket cMarket) external;
    
  /// @notice Called by `ToroAdmin` to set the max exposure allowed for every
  /// `ChildMarket` associated with this `ParentMarket`. If a bet size exceeds
  /// `_maxExposure`, it will get rejected. The purpose of `_maxExposure` is to
  /// limit the maximum amount of one-sided risk a `Market` can take on.
  /// @param maxExposure_ New max exposure
  function _setMaxExposure(uint maxExposure_) external;

  
  /** USER INTERFACE **/


  /// @notice External entry point for end users to place bets on any
  /// associated `ChildMarket`. The `betType` will indicate what type of bet
  /// the user wishes to make (i.e., moneyline, handicap, over/under).
  /// The `option` enum indicates which side the user wants to bet, and the size
  /// is the amount the user wishes to bet (before commission fees).
  /// Commission fees are chard at the time of placing a bet, and the remainder
  /// is the actual size placed for the wager. Hence, the `Ticket` that user
  /// receives when placing a bet will be for a slightly smaller amount than
  /// `size`.
  /// `placeBet` transfers the full funds over from user to the `ChildMarket` on
  /// its behalf, so that users only need to call ERC20 `approve` on the
  /// `ParentMarket`. Beyond that, each `ChildMarket` manages its own currency
  /// balances separately when a bet is placed, including sending/requesting
  /// funds to `ToroPool`. The `ChildMarket` must have the `CHILD_MARKET_ROLE`
  /// before it can be approved to request funds from `ToroPool`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param option The side which user picks to win
  /// @param size Size which user wishes to bet (before commission fees)
  function placeBet(uint betType, uint8 option, uint size) external;
  
  /// @notice External entry point for end users to claim winning `Ticket`s.
  /// The `betType` will indicate what type of bet the `Ticket` references
  /// (i.e., moneyline, handicap, over/under) and the `ticketId` is the id of
  /// the winning `Ticket`. `ParentMarket` holds no funds - the `ChildMarket`
  /// will transfer funds to winners directly.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param ticketId ID of the `Ticket`
  function claimTicket(uint betType, uint ticketId) external;

  
  /** VIEW FUNCTIONS **/

  
  function toroAdmin() external view returns(address);
  
  function toroPool() external view returns(address);

  function tag() external view returns(bytes32);
  
  function currency() external view returns(IERC20);

  function resolved() external view returns(bool);
  
  function deadline() external view returns(uint);

  function sportId() external view returns(uint);

  function maxExposure() external view returns(uint);

  function labelA() external view returns(string memory);

  function labelB() external view returns(string memory);

  function childMarket(uint betType) external view returns(IChildMarket);
  
  /// @notice Gets the current state of the `Market`. The states are:
  /// OPEN: Still open for taking new bets
  /// PENDING: No new bets allowed, but no winner/tie declared yet
  /// CLOSED: Result declared, still available for redemptions
  /// EXPIRED: Redemption window expired, `Market` eligible to be deleted
  /// @return uint8 Current state
  function state() external view returns(uint8);
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToroPool.sol";
import "./IParentMarket.sol";

interface IToroAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when setting `_toroDB`
  event SetToroDB(address toroDBAddr);

  /// @notice Emitted when setting `_sportOracle`
  event SetSportOracle(address sportOracleAddr);
  
  /// @notice Emitted when setting `_priceOracle`
  event SetPriceOracle(address priceOracleAddr);
  
  /// @notice Emitted when setting `_feeEmissionsController`
  event SetFeeEmissionsController(address feeEmissionsControllerAddr);

  /// @notice Emitted when setting `_affiliateERC721`
  event SetAffiliateERC721(address affiliateERC721Addr);

  /// @notice Emitted when setting `_affiliateMintFee`
  event SetAffiliateMintFee(uint affiliateMintFee);

  /// @notice Emitted when adding a new `ParentMarket`
  event AddParentMarket(
                        address indexed currency,
                        uint indexed sportId,
                        string labelA,
                        string labelB,
                        address pMarketAddr
                        );

  /// @notice Emitted when deleting a `ParentMarket`
  event DeleteParentMarket(
                           address indexed currency,
                           uint indexed sportId,
                           string labelA,
                           string labelB,
                           address pMarketAddr
                           );
  
  /// @notice Emitted when adding a new `ToroPool`
  event AddToroPool(address toroPool);

  /// @notice Emitted when setting the bookmaking fee
  event SetBookmakingFeeBps(uint bookmakingFeeBps);

  /// @notice Emitted when setting the commission fee
  event SetCommissionFeeBps(uint commissionFeeBps);

  /// @notice Emitted when setting the affiliate bonus
  event SetAffiliateBonusBps(uint affiliateBonusBps);

  /// @notice Emitted when setting the referent discount
  event SetReferentDiscountBps(uint referentDiscountBps);

  /// @notice Emitted when setting the market expiry deadline
  event SetExpiryDeadline(uint expiryDeadline_);

  /// @notice Emitted when setting the LP cooldown
  event SetCooldownLP(uint redeemLPCooldown_);

  /// @notice Emitted when setting the LP window
  event SetWindowLP(uint windowLP_);
  
  /** ACCESS CONTROLLED FUNCTIONS **/

  /// @notice Called upon initialization after deploying `ToroDB` contract
  /// @param toroDBAddr Address of `ToroDB` deployment
  function _setToroDB(address toroDBAddr) external;

  /// @notice Called upon initialization after deploying `SportOracle` contract
  /// @param sportOracleAddr Address of `SportOracle` deployment
  function _setSportOracle(address sportOracleAddr) external;
  
  /// @notice Called upon initialization after deploying `PriceOracle` contract
  /// @param priceOracleAddr Address of `PriceOracle` deployment
  function _setPriceOracle(address priceOracleAddr) external;
  
  /// @notice Called upon initialization after deploying `FeeEmissionsController` contract
  /// @param feeEmissionsControllerAddr Address of `FeeEmissionsController` deployment
  function _setFeeEmissionsController(address feeEmissionsControllerAddr) external;

  /// @notice Called up initialization after deploying `AffiliateERC721` contract
  /// @param affiliateERC721Addr Address of `AffiliateERC721` deployment
  function _setAffiliateERC721(address affiliateERC721Addr) external;

  /// @notice Adds a new `ToroPool` currency contract
  /// @param toroPool_ New `ToroPool` currency contract
  function _addToroPool(IToroPool toroPool_) external;

  /// @notice Adds a new `ParentMarket`. `ParentMarket`s can only be added if
  /// there is a matching `ToroPool` contract that supports the currency
  /// @param pMarket `ParentMarket` to add
  function _addParentMarket(IParentMarket pMarket) external;

  /// @notice Removes a `ParentMarket` completely from being associated with the
  /// `ToroPool` token completely. This should only done after a minimum period
  /// of time after the `ParentMarket` has closed, or else users won't be able
  /// to redeem from it.
  /// @param pMarketAddr Address of target `ParentMarket` to be deleted
  function _deleteParentMarket(address pMarketAddr) external;
  
  /// @notice Sets the max exposure for a particular `ParentMarket`
  /// @param pMarketAddr Address of the target `ParentMarket`
  /// @param maxExposure_ New max exposure, in local currency
  function _setMaxExposure(address pMarketAddr, uint maxExposure_) external;
    
  /// @notice Sets affiliate mint fee. The fee is in USDC, scaled to 1e6
  /// @param affiliateMintFee_ New mint fee
  function _setAffiliateMintFee(uint affiliateMintFee_) external;

  /// @notice Set the bookmaking fee
  /// param bookmakingFeeBps_ New bookmaking fee, scaled to 1e4  
  function _setBookmakingFeeBps(uint bookmakingFeeBps_) external;
  
  /// @notice Set the protocol fee
  /// param commissionFeeBps_ New protocol fee, scaled to 1e4  
  function _setCommissionFeeBps(uint commissionFeeBps_) external;

  /// @notice Set the affiliate bonus
  /// param affiliateBonusBps_ New affiliate bonus, scaled to 1e4 
  function _setAffiliateBonusBps(uint affiliateBonusBps_) external;

  /// @notice Set the referent discount
  /// @param referentDiscountBps_ New referent discount, scaled to 1e4
  function _setReferentDiscountBps(uint referentDiscountBps_) external;

  /// @notice Set the global `Market` expiry deadline
  /// @param expiryDeadline_ New `Market` expiry deadline (in seconds)
  function _setExpiryDeadline(uint expiryDeadline_) external;

  /// @notice Set the global cooldown timer for LP actions
  /// @param cooldownLP_ New cooldown time (in seconds)
  function _setCooldownLP(uint cooldownLP_) external;

  /// @notice Set the global window for LP actions
  /// @param windowLP_ New window time (in seconds)
  function _setWindowLP(uint windowLP_) external;

  /** VIEW FUNCTIONS **/

  function affiliateERC721() external view returns(address);

  function toroDB() external view returns(address);

  function sportOracle() external view returns(address);
  
  function priceOracle() external view returns(address);
  
  function feeEmissionsController() external view returns(address);

  function toroPool(IERC20 currency) external view returns(IToroPool);

  function parentMarkets(IERC20 currency, uint sportId) external view returns(address[] memory);

  function affiliateMintFee() external view returns(uint);

  function bookmakingFeeBps() external view returns(uint);
  
  function commissionFeeBps() external view returns(uint);

  function affiliateBonusBps() external view returns(uint);

  function referentDiscountBps() external view returns(uint);

  function expiryDeadline() external view returns(uint);

  function cooldownLP() external view returns(uint);

  function windowLP() external view returns(uint);
  
  function ADMIN_ROLE() external view returns(bytes32);

  function BOOKMAKER_ROLE() external view returns(bytes32);
  
  function CHILD_MARKET_ROLE() external view returns(bytes32);
  
  function PARENT_MARKET_ROLE() external view returns(bytes32);
  
  function MANTISSA_BPS() external view returns(uint);
  
  function MANTISSA_ODDS() external view returns(uint);

  function MANTISSA_USD() external pure returns(uint);
  
  function NULL_AFFILIATE() external view returns(uint);

  function OPTION_TIE() external view returns(uint8);
  
  function OPTION_A() external view returns(uint8);

  function OPTION_B() external view returns(uint8);

  function OPTION_UNDEFINED() external view returns(uint8);
  
  function STATE_OPEN() external view returns(uint8);

  function STATE_PENDING() external view returns(uint8);

  function STATE_CLOSED() external view returns(uint8);

  function STATE_EXPIRED() external view returns(uint8);  

  function BET_TYPE_MONEYLINE() external pure returns(uint8);

  function BET_TYPE_HANDICAP() external pure returns(uint8);

  function BET_TYPE_OVER_UNDER() external pure returns(uint8);
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToroPool is IERC20Upgradeable {

  /// @notice Emitted when setting burn request
  event SetLastBurnRequest(address indexed user, uint timestamp);


  /** ACCESS CONTROLLED FUNCTIONS **/


  /// @notice Transfers funds to a `ChildMarket` to ensure it can cover the
  /// maximum payout. This is an access-controlled function - only the
  /// `ChildMarket` contracts may call this function
  function _transferToChildMarket(address cMarket, uint amount) external;

  /// @notice Accounting function to increase the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to increase `_credits`
  function _incrementCredits(uint amount) external;

  /// @notice Accounting function to decrease the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to decrease `_credits`
  function _decrementCredits(uint amount) external;

  /// @notice Accounting function to increase the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to increase `_debits`
  function _incrementDebits(uint amount) external;

  /// @notice Accounting function to decrease the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to decrease `_debits`
  function _decrementDebits(uint amount) external;

  
  /** USER INTERFACE **/


  /// @notice Deposit underlying currency and receive LP tokens
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the amount of LP tokens due to minters, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s.
  /// @param amount Amount user wishes to deposit, in underlying token
  function mint(uint amount) external;

  /// @notice Burn LP tokens to receive back underlying currency.
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the underlying amount due to LPs, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s. Because
  /// of this, it is possible that `ToroPool` potentially may not have enough
  /// balance if enough currency is locked inside open `ChildMarket`s relative
  /// to free balance in the contract. In that case, LPs will have to wait until
  /// the current `ChildMarket`s are closed or for new minters before redeeming.
  /// @param amount Amount of LP tokens user wishes to burn
  function burn(uint amount) external;

  /// @notice Make a request to burn tokens in the future. LPs may not burn
  /// their tokens immediately, but must wait a `cooldownLP` time after making
  /// the request. They are also given a `windowLP` time to burn. If they do not
  /// burn within the window, the current request expires and they will have to
  /// make a new burn request.
  function burnRequest() external;

  
  /** VIEW FUNCTIONS **/
  

  function toroAdmin() external view returns(address);
  
  function currency() external view returns(IERC20);

  /// @notice Conversion from underlying tokens to LP tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of underlying tokens
  /// @return uint Amount of LP tokens
  function underlyingToLP(uint amount) external view returns(uint);

  /// @notice Conversion from LP tokens to underlying tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of LP tokens
  /// @return uint Amount of underlying tokens
  function LPToUnderlying(uint amount) external view returns(uint);

  function credits() external view returns(uint);

  function debits() external view returns(uint);
  
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

library Types {

  /// @notice Contains all the details of a betting `Ticket`
  /// @member id Unique identifier for the ticket
  /// @member account Address of the bettor
  /// @member option Enum indicating which `Option` the bettor has selected
  /// @member odds The locked-in odds which the bettor receives on this bet
  /// @member size The total size of the bet
  struct Ticket {
    uint id;
    address account;
    uint8 option;
    uint odds;
    uint size;
  }

  /// @notice Contains all the details of a betting `Option`
  /// @member label String identifier for the name of the betting `Option`
  /// @member size Total action currently placed on this `Option`
  /// @member payout Total amount owed to bettors if this `Option` wins
  struct Option {
    string label;
    uint size;
    uint payout;
  }

  /// @notice Convenience struct for storing odds tuples. Odds should always
  /// be stored in DECIMAL ODDS format, scaled by 1e8
  /// @member oddsA Odds of side A, in decimal odds format, scaled by 1e8
  /// @member oddsB Odds of side B, in decimal odds format, scaled by 1e8
  struct Odds {
    uint oddsA;
    uint oddsB;
  }
    
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IToroAdmin.sol";
import "./interfaces/IToroPool.sol";
import "./interfaces/IChildMarket.sol";

contract ToroPool is Initializable, ERC20Upgradeable, ReentrancyGuard, IToroPool {

  using SafeERC20 for IERC20;
  
  /// @notice Address of the `ToroAdmin` contract
  IToroAdmin _toroAdmin;

  /// @notice Address of the underlying `IERC20` currency
  IERC20 private _currency;

  /// @notice Track how much funds were sent FROM `ToroPool` TO `ChildMarket`s
  uint private _credits;

  /// @notice Track how much funds were sent TO `ToroPool` FROM `ChildMarket`s
  uint private _debits;
  
  /// @notice Mapping of latest requests to burn LP Tokens
  /// account => timestamp (seconds)
  mapping(address => uint) private _lastBurnRequests;
  
  /// @notice Constructor for upgradeable contracts
  /// @param toroAdminAddr_ Address of the `ToroAdmin` contract
  /// @param currencyAddr_ Address of the underlying token for this LP
  /// @param name_ Name of the ERC20 LP token
  /// @param symbol_ Name of the ERC20 LP token
  function initialize(
                      address toroAdminAddr_,
                      address currencyAddr_,
                      string memory name_,
                      string memory symbol_
                      ) public initializer {
    __ERC20_init(name_, symbol_);
    _toroAdmin = IToroAdmin(toroAdminAddr_);
    _currency = IERC20(currencyAddr_);
  }
  
  modifier onlyChildMarket() {
    require(_toroAdmin.hasRole(_toroAdmin.CHILD_MARKET_ROLE(), msg.sender), "only child market");
    _;
  }

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Transfers funds to a `ChildMarket` to ensure it can cover the
  /// maximum payout. This is an access-controlled function - only the
  /// `ChildMarket` contracts may call this function
  function _transferToChildMarket(address cMarket, uint amount) external onlyChildMarket {
    
    // `ToroPool` must have enough balance to top up to cover the maximum payout
    // of the `ChildMarket`
    require(_currency.balanceOf(address(this)) >= amount, "Not enough balance");

    // Transfer the funds to the `ChildMarket`
    _currency.safeTransfer(cMarket, amount);
  }

  /// @notice Accounting function to increase the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to increase `_credits`
  function _incrementCredits(uint amount) external onlyChildMarket {
    _credits += amount;
  }

  /// @notice Accounting function to decrease the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to decrease `_credits`
  function _decrementCredits(uint amount) external onlyChildMarket {
    _credits -= amount;
  }

  /// @notice Accounting function to increase the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to increase `_debits`
  function _incrementDebits(uint amount) external onlyChildMarket {
    _debits += amount;
  }

  /// @notice Accounting function to decrease the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to decrease `_debits`
  function _decrementDebits(uint amount) external onlyChildMarket {
    _debits -= amount;
  }
  
  
  /** USER INTERFACE **/

  
  /// @notice Deposit underlying currency and receive LP tokens
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the amount of LP tokens due to minters, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s.
  /// @param amount Amount user wishes to deposit, in underlying token
  function mint(uint amount) external nonReentrant {

    // Convert the underlying amount to number of LP shares
    uint amountToMint = _underlyingToLP(amount);
    
    // Transfer underlying tokens from user to the contract
    _currency.safeTransferFrom(msg.sender, address(this), amount);

    // Mint the LP amount to user
    _mint(msg.sender, amountToMint);
    
  }

  /// @notice Burn LP tokens to receive back underlying currency.
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the underlying amount due to LPs, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s. Because
  /// of this, it is possible that `ToroPool` potentially may not have enough
  /// balance if enough currency is locked inside open `ChildMarket`s relative
  /// to free balance in the contract. In that case, LPs will have to wait until
  /// the current `ChildMarket`s are closed or for new minters before redeeming.
  /// @param amount Amount of LP tokens user wishes to burn
  function burn(uint amount) external nonReentrant {

    // LP users can only burn after cooldown has finished
    require(
            block.timestamp > _lastBurnRequests[msg.sender] + _toroAdmin.cooldownLP(),
            "before burn window"
            );

    // LP users cannot burn after window has closed
    require(
            block.timestamp < _lastBurnRequests[msg.sender] + _toroAdmin.cooldownLP() + _toroAdmin.windowLP(),
            "after burn window"
            );
            
    // Get the net underlying withdraw amount
    uint withdrawAmount = _LPToUnderlying(amount);

    // Users can only redeem if there is enough free balance
    require(withdrawAmount <= _currency.balanceOf(address(this)), "not enough balance");
    
    // Burn the LP tokens
    _burn(msg.sender, amount);

    // Transfer the `withdrawAmount` of `_currency` to the user
    _currency.safeTransfer(msg.sender, withdrawAmount);
  }

  /// @notice Make a request to burn tokens in the future. LPs may not burn
  /// their tokens immediately, but must wait a `cooldownLP` time after making
  /// the request. They are also given a `windowLP` time to burn. If they do not
  /// burn within the window, the current request expires and they will have to
  /// make a new burn request.
  function burnRequest() external {

    _lastBurnRequests[msg.sender] = block.timestamp;

    emit SetLastBurnRequest(msg.sender, block.timestamp);
  }
  
  /** VIEW FUNCTIONS **/

  function toroAdmin() external view returns(address) {
    return address(_toroAdmin);
  }
  
  function currency() external view returns(IERC20) {
    return _currency;
  }

  /// @notice Conversion from underlying tokens to LP tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of underlying tokens
  /// @return uint Amount of LP tokens
  function underlyingToLP(uint amount) external view returns(uint) {
    return _underlyingToLP(amount);
  }

  /// @notice Conversion from LP tokens to underlying tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of LP tokens
  /// @return uint Amount of underlying tokens
  function LPToUnderlying(uint amount) external view returns(uint) {
    return _LPToUnderlying(amount);
  }

  function credits() external view returns(uint) {
    return _credits;
  }

  function debits() external view returns(uint) {
    return _debits;
  }
  
  /** INTERNAL FUNCTIONS **/

  
  /// @notice Conversion from underlying tokens to LP tokens, taking into
  /// account the net debt of every open `ChildMarket`
  /// @param amount Amount of underlying tokens
  /// @return uint Amount of LP tokens
  function _underlyingToLP(uint amount) internal view returns(uint) {

    if(totalSupply() == 0) {

      // When no LP tokens have been minted yet, default to 1:1 conversion
      // ratio to LP shares
      return amount;

    } else {
    
      // Use the `netBalance`, NOT the current contract balance when calculating
      // conversions
      uint netBalance = _getNetBalance();
    
      // Get the equivalent amount of LP tokens
      uint LP = amount * totalSupply() / netBalance;
      
      return LP;
    }
  }

  /// @notice Conversion from LP tokens to underlying tokens, taking into
  /// account the net debt of every open `ChildMarket`
  /// @param amount Amount of LP tokens
  /// @return uint Amount of underlying tokens
  function _LPToUnderlying(uint amount) internal view returns(uint) {

    // Use the `netBalance`, NOT the current contract balance when calculating
    // conversions because `ToroPool` may be lending funds to open/pending
    // `ChildMarket`s (or vice versa)
    uint netBalance = _getNetBalance();
    
    // Get the equivalent amount of underlying `_currency`
    uint underlying = netBalance * amount / totalSupply();

    return underlying;
  }

  /// @notice `netBalance` is defined as the free balance of underlying tokens
  /// inside the `ToroPool` contract minus the net debt to each open/pending
  /// `ChildMarket`.
  /// @return uint Net balance 
  function _getNetBalance() internal view returns(uint) {

    // Get the unused balance being held inside `ToroPool`
    uint freeBalance = _currency.balanceOf(address(this));
    
    // `netBalance` is defined as the free balance in the contract minus the
    // net debt to each open/pending `ChildMarket`
    uint netBalance = freeBalance + _credits - _debits;
    
    return netBalance;
  }  

}