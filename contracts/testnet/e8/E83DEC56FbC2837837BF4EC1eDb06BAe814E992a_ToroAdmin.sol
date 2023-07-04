// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
library EnumerableSetUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IAffiliateERC721 is IERC721 {

  
  /** USER INTERFACE **/
  
  /// @notice Function for minting a `Referral` NFT
  function mint() external;

  /// @notice Users call this to bind their address to a affiliate's `Referral`
  /// to earn a discount on protocol fees when making bets
  /// @param code Token ID of the target `Referral` NFT
  function useReferralCode(uint code) external;

  
  /** VIEW FUNCTIONS **/  
  
  /// @notice Returns the referral code being used by the referent
  /// @param referent Address of the referent
  /// @return uint Referral code
  function referralCodes(address referent) external view returns(uint);

  
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

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IFeeEmissionsController {

  /// @notice Emitted when affiliate/referent earn bonus/discount
  event ReferralFee(
                    address indexed currency,
                    address indexed affiliate,
                    address indexed referent,
                    uint affiliateBonus,
                    uint referentDiscount
                    );
  
  /** ACCESS-CONTROLLED FUNCTIONS **/
  
  function receiveFees(address account, IERC20 currency, uint preFeeSize, uint fee) external;
  
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceOracle {

  /// @notice Emitted when setting DIA oracle
  event SetDIAOracle(address DIAOracleAddr);

  /// @notice Emitted when setting oracle feeds
  event SetOracleFeed(address token, address oracleFeed);

  /** ADMIN/RESTRICTED FUNCTIONS **/
  
  function _setDIAOracle(address DIAOracleAddr) external;

  function _setOracleFeed(IERC20 token, address oracleFeed) external;
  
  /** VIEW FUNCTIONS **/

  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 digit precision)
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param token Address of the underlying token
  /// @return answer uint256, decimals uint8
  function priceFeed(IERC20 token) external view returns(uint256, uint8);
  
  /// @notice Get the address of the `ToroAdmin` contract
  /// @return address Address of `ToroAdmin` contract
  function toroAdmin() external view returns(address);

}

// SPDX-License-Identifier:NONE
pragma solidity ^0.8.17;

import "./IParentMarket.sol";
import "../libraries/Types.sol";

interface ISportOracle {

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  function _addTagToMarket(bytes32 tag, address pMarketAddr) external;
  
  /// @notice Updates the base odds for an array of matches. This function
  /// accepts an array of bytes data, where each bytes element is encoded as:
  /// b[0:1] => Version Number (uint8)
  /// b[1:33] => Tag (bytes32), Tag of the match
  /// b[j+33:j+34] => BetType (uint8), 
  /// b[j+34:j+42] => oddsA (uint8)
  /// b[j+42:j+50] => oddsB (uint*)
  /// The odds should expressed in DECIMAL ODDS format, scaled by 1e8
  function _updateBaseOdds(uint8 version, bytes[] calldata data) external;

  /// @notice Resolves the market for an array of matches. This function
  /// accepts an array of bytes data, where each bytes element is encoded as:
  /// b[0:32] => Tag (bytes32), Tag of the match
  /// b[32:40] => scoreA (int64), Score of side A, scaled by 1e8
  /// b[40:48] => scoreB (int64), Score of side B, scaled by 1e8
  function _resolveMarket(uint8 version, bytes[] calldata data) external;
  
  
  /** VIEW FUNCTIONS **/

  
  function getParentMarket(bytes32 tag) external view returns(IParentMarket);

  function baseOdds(bytes32 tag, uint8 betType) external view returns(Types.Odds memory);
  
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

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToroDB {

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  /// @notice Called by `Market` contracts anytime a user successfully places a
  /// bet. Betting volumes by address are tracked and can be used for various
  /// analytics, pricing, and limits calculations. All betting volumes are
  /// tracked in USD value.
  /// @param account Address of user
  /// @param currency Currency of the bet
  /// @param amountLocal Amount bet, in local currency terms
  function _addUserVolumes(address account, IERC20 currency, uint amountLocal) external;

  /// @notice Called by `Market` contracts anytime a user claims profits.
  /// Profits by address are tracked and can be used for various analytics,
  /// pricing, and limits calculations. All profits are tracked in USD value.
  /// @param account Address of user
  /// @param currency Currency of the bet
  /// @param amountLocal Amoutn of profits, in local currency terms
  function _addUserProfits(address account, IERC20 currency, uint amountLocal) external;

  /** VIEW FUNCTIONS **/

  function toroAdmin() external view returns(address);

  function priceOracle() external view returns(address);
  
  function getUserVolumes(address account) external view returns(uint);

  function getUserProfits(address account) external view returns(uint);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


library AddressSetLib {

  /// @notice Set data structure for easier traversal of arrays of type address
  /// @member elements Stores the actual address array
  /// @member indices Mapping from address element to its array index
  struct AddressSet {
    address[] elements;
    mapping(address => uint) indices;
  }
  
  function contains(AddressSet storage set, address candidate) internal view returns (bool) {
    if (set.elements.length == 0) {
      return false;
    }
    uint index = set.indices[candidate];
    return index != 0 || set.elements[0] == candidate;
  }

  function getPage(
                   AddressSet storage set,
                   uint index,
                   uint pageSize
                   ) internal view returns (address[] memory) {
    // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
    uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

    // If the page extends past the end of the list, truncate it.
    if (endIndex > set.elements.length) {
      endIndex = set.elements.length;
    }
    if (endIndex <= index) {
      return new address[](0);
    }

    uint n = endIndex - index; // We already checked for negative overflow.
    address[] memory page = new address[](n);
    for (uint i; i < n; i++) {
      page[i] = set.elements[i + index];
    }
    return page;
  }

  function add(AddressSet storage set, address element) internal {
    // Adding to a set is an idempotent operation.
    if (!contains(set, element)) {
      set.indices[element] = set.elements.length;
      set.elements.push(element);
    }
  }

  function remove(AddressSet storage set, address element) internal {
    require(contains(set, element), "Element not in set.");
    // Replace the removed element with the last element of the list.
    uint index = set.indices[element];
    uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
    if (index != lastIndex) {
      // No need to shift the last element if it is the one we want to delete.
      address shiftedElement = set.elements[lastIndex];
      set.elements[index] = shiftedElement;
      set.indices[shiftedElement] = index;
    }
    set.elements.pop();
    delete set.indices[element];
  }
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

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAffiliateERC721.sol";
import "./interfaces/IChildMarket.sol";
import "./interfaces/IFeeEmissionsController.sol";
import "./interfaces/IParentMarket.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IToroAdmin.sol";
import "./interfaces/IToroDB.sol";
import "./interfaces/ISportOracle.sol";
import "./interfaces/IToroPool.sol";
import "./libraries/AddressSetLib.sol";

contract ToroAdmin is Initializable, AccessControlEnumerableUpgradeable, IToroAdmin {

  using AddressSetLib for AddressSetLib.AddressSet;
  
  /// @notice Contract for useful persistent storage data
  IToroDB private _toroDB;
  
  /// @notice Contract for price conversions
  IPriceOracle private _priceOracle;

  /// @notice Contract for sportsbook oracle
  ISportOracle private _sportOracle;
  
  /// @notice Contract for handling fee charging and emission
  IFeeEmissionsController private _feeEmissionsController;

  /// @notice Contract address for `Affiliate` NFT
  IAffiliateERC721 private _affiliateERC721;
  
  /// @notice Identifier of the admin role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @notice Identifier of the parent market role
  bytes32 public constant PARENT_MARKET_ROLE = keccak256("PARENT_MARKET");

  /// @notice Identifier of the child market role
  bytes32 public constant CHILD_MARKET_ROLE = keccak256("CHILD_MARKET");
  
  // @notice Identifier of the bookmaker role
  bytes32 public constant BOOKMAKER_ROLE = keccak256("BOOKMAKER");
  
  /// @notice Cost to mint an `Affiliate` NFT (in USDC, scaled to 1e6)
  uint _affiliateMintFee;

  /// @notice Commission fee charged as a percentage of bet size, scaled by 1e4
  uint _commissionFeeBps;

  /// @notice Bookmaking fee charged on profitable markets against LPs, scaled by 1e4
  uint _bookmakingFeeBps;
  
  /// @notice Bonus to affiliates anytime a user bets using their code
  uint _affiliateBonusBps;

  /// @notice Discount for users with a valid referral code, scaled by 1e4
  uint _referentDiscountBps;

  /// @notice Amount of time before CLOSED `ParentMarket` expires (is deleted)
  uint _expiryDeadline;

  /// @notice Amount of cooldown time (in seconds) before users can perform
  /// LP actions
  uint _cooldownLP;
  
  /// @notice Window of time (in seconds) after cooldown period before users
  /// can perform LP actions
  uint _windowLP;
  
  /// @notice Mapping of all `ToroPool` tokens by currency
  mapping(IERC20 => IToroPool) private _toroPools;
  
  /// @notice Mapping of all `ParentMarket`s by currency and sport ID
  /// IERC20 => sportId => Set of `ParentMarket` addresses
  mapping(IERC20 => mapping(uint => AddressSetLib.AddressSet)) private _parentMarkets;
  
  /// @notice Constructor for upgradeable contracts
  function initialize(address admin) public initializer {
    
    // Initialize access control
    __AccessControlEnumerable_init();
    _setupRole(ADMIN_ROLE, admin);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(PARENT_MARKET_ROLE, ADMIN_ROLE);
    _setRoleAdmin(CHILD_MARKET_ROLE, PARENT_MARKET_ROLE);
    _setRoleAdmin(BOOKMAKER_ROLE, ADMIN_ROLE);
    
    // Set initial fees
    _bookmakingFeeBps = 500;
    _commissionFeeBps = 150;
    _affiliateBonusBps = 0;
    _referentDiscountBps = 0;    
    _expiryDeadline = 7776000; // 90 days
    _cooldownLP = 86400; // 1 day
    _windowLP = 86400; // 1 day
  }

  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "ToroAdmin: only admin");
    _;
  }

  modifier onlyBookmaker() {
    require(hasRole(BOOKMAKER_ROLE, msg.sender), "ToroAdmin: only bookmaker");
    _;
  }
  
  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Called upon initialization after deploying `ToroDB` contract
  /// @param toroDBAddr Address of `ToroDB` deployment
  function _setToroDB(address toroDBAddr) external onlyAdmin {

    _toroDB = IToroDB(toroDBAddr);

    // Emit the event
    emit SetToroDB(toroDBAddr);
  }

  /// @notice Called upon initialization after deploying `SportOracle` contract
  /// @param sportOracleAddr Address of `SportOracle` deployment
  function _setSportOracle(address sportOracleAddr) external onlyAdmin {

    _sportOracle = ISportOracle(sportOracleAddr);

    // Emit the event
    emit SetSportOracle(sportOracleAddr);
  }
  
  /// @notice Called upon initialization after deploying `PriceOracle` contract
  /// @param priceOracleAddr Address of `PriceOracle` deployment
  function _setPriceOracle(address priceOracleAddr) external onlyAdmin {

    _priceOracle = IPriceOracle(priceOracleAddr);

    // Emit the event
    emit SetPriceOracle(priceOracleAddr);
  }
  
  /// @notice Called upon initialization after deploying `FeeEmissionsController` contract
  /// @param feeEmissionsControllerAddr Address of `FeeEmissionsController` deployment
  function _setFeeEmissionsController(address feeEmissionsControllerAddr) external onlyAdmin {

    _feeEmissionsController = IFeeEmissionsController(feeEmissionsControllerAddr);

    // Emit the event
    emit SetFeeEmissionsController(feeEmissionsControllerAddr);
  }

  /// @notice Called up initialization after deploying `AffiliateERC721` contract
  /// @param affiliateERC721Addr Address of `AffiliateERC721` deployment
  function _setAffiliateERC721(address affiliateERC721Addr) external onlyAdmin {

    // Address for contract can only be set once
    require(address(_affiliateERC721) == address(0), "already set");
    
    _affiliateERC721 = IAffiliateERC721(affiliateERC721Addr);

    // Emit the event
    emit SetAffiliateERC721(affiliateERC721Addr);
  }

  /// @notice Adds a new `ToroPool` currency contract 
  /// @param toroPool_ New `ToroPool` currency contract
  function _addToroPool(IToroPool toroPool_) external onlyAdmin {

    // `ToroPool` can only be set once
    require(address(_toroPools[toroPool_.currency()]) == address(0), "already set");
    
    _toroPools[toroPool_.currency()] = toroPool_;

    // Emit the event
    emit AddToroPool(address(toroPool_));
  }

  /// @notice Adds a new `ParentMarket`. `ParentMarket`s can only be added if
  /// there is a matching `ToroPool` contract that supports the currency
  /// @param pMarket `ParentMarket` to add
  function _addParentMarket(IParentMarket pMarket) external onlyAdmin {
  
    // Get the underlying currency of the `ParentMarket`
    IERC20 currency = pMarket.currency();

    // LP token must exist for this currency before a `ParentMarket` can be created
    require(address(_toroPools[currency]) != address(0), "currency not supported");

    // Add the `Market` to the list of open `Market`s for this currency
    AddressSetLib.AddressSet storage pMarkets_ = _parentMarkets[currency][pMarket.sportId()];
    pMarkets_.add(address(pMarket));

    // Give `ParentMarket` the `PARENT_MARKET` access control role. The
    // `PARENT_MARKET` role is the admin (ie can call `grantRole`) for
    // `CHILD_MARKET` role.
    _setupRole(PARENT_MARKET_ROLE, address(pMarket));

    // Add the `tag` mapping to `SportOracle` for this `ParentMarket`
    _sportOracle._addTagToMarket(pMarket.tag(), address(pMarket));
    
    // Emit the event
    emit AddParentMarket(
                         address(currency),
                         pMarket.sportId(),
                         pMarket.labelA(),
                         pMarket.labelB(),
                         address(pMarket)
                         );
  }

  /// @notice Removes a `ParentMarket` completely from being associated with the
  /// `ToroPool` token completely. This should only done after a minimum period
  /// of time after the `ParentMarket` has closed, or else users won't be able
  /// to redeem from it.
  /// @param pMarketAddr Address of target `ParentMarket` to be deleted
  function _deleteParentMarket(address pMarketAddr) external onlyAdmin {
    
    IParentMarket pMarket = IParentMarket(pMarketAddr);
    
    // `ParentMarket` must be marked expired before it can be deleted
    require(pMarket.state() == STATE_EXPIRED(), "parent market not expired");
    
    // Get the set of currently open `ParentMarket`s as a storage variable since
    // we will be deleting the target `ParentMarket` from this set
    AddressSetLib.AddressSet storage pMarkets_ = _parentMarkets[pMarket.currency()][pMarket.sportId()];
    
    // Remove the element if found. Otherwise, revert
    pMarkets_.remove(pMarketAddr);
    
    // Emit the event
    emit DeleteParentMarket(
                            address(pMarket.currency()),
                            pMarket.sportId(),
                            pMarket.labelA(),
                            pMarket.labelB(),
                            address(pMarket)
                            );
  }
  
  /// @notice Sets the max exposure for a particular `ParentMarket`
  /// @param pMarketAddr Address of the target `ParentMarket`
  /// @param maxExposure_ New max exposure, in local currency
  function _setMaxExposure(address pMarketAddr, uint maxExposure_) external onlyAdmin {

    IParentMarket pMarket = IParentMarket(pMarketAddr);

    pMarket._setMaxExposure(maxExposure_);    
  }
      
  /// @notice Sets affiliate mint fee. The fee is in USDC, scaled to 1e6
  /// @param affiliateMintFee_ New mint fee
  function _setAffiliateMintFee(uint affiliateMintFee_) external onlyAdmin {

    // Set the new mint fee
    _affiliateMintFee = affiliateMintFee_;

    // Emit the event
    emit SetAffiliateMintFee(affiliateMintFee_);
  }

  /// @notice Set the bookmaking fee
  /// param bookmakingFeeBps_ New bookmaking fee, scaled to 1e4  
  function _setBookmakingFeeBps(uint bookmakingFeeBps_) external onlyAdmin {

    // bookmaking fee cannot exceed 100%
    require(bookmakingFeeBps_ < 10000, "bookmaking fee must be less than 100%");

    _bookmakingFeeBps = bookmakingFeeBps_;

    // Emit the event
    emit SetBookmakingFeeBps(bookmakingFeeBps_);
  }  
  
  /// @notice Set the commission fee
  /// param commissionFeeBps_ New commission fee, scaled to 1e4  
  function _setCommissionFeeBps(uint commissionFeeBps_) external onlyAdmin {

    // commission fee cannot exceed 100%
    require(commissionFeeBps_ < 10000, "commission fee must be less than 100%");

    _commissionFeeBps = commissionFeeBps_;

    // Emit the event
    emit SetCommissionFeeBps(commissionFeeBps_);
  }

  /// @notice Set the affiliate bonus
  /// param affiliateBonusBps_ New affiliate bonus, scaled to 1e4 
  function _setAffiliateBonusBps(uint affiliateBonusBps_) external onlyAdmin {

    // The affiliate bonus and referent discount are paid out from the
    // commission fees so they cannot sum up to more than that amount
    require(
            _referentDiscountBps + affiliateBonusBps_ <= _commissionFeeBps,
            "bonus plus discount must be less than commission fee"
            );

    _affiliateBonusBps = affiliateBonusBps_;

    // Emit the event
    emit SetAffiliateBonusBps(affiliateBonusBps_);
  }

  /// @notice Set the referent discount
  /// @param referentDiscountBps_ New referent discount, scaled to 1e4
  function _setReferentDiscountBps(uint referentDiscountBps_) external onlyAdmin {

    // The affiliate bonus and referent discount are paid out from the
    // commission fees so they cannot sum up to more than that amount
    require(
            referentDiscountBps_ + _affiliateBonusBps <= _commissionFeeBps,
            "bonus plus discount must be less than commission fee"
            );

    _referentDiscountBps = referentDiscountBps_;

    // Emit the event
    emit SetReferentDiscountBps(referentDiscountBps_);
  }

  /// @notice Set the global `Market` expiry deadline
  /// @param expiryDeadline_ New `Market` expiry deadline (in seconds)
  function _setExpiryDeadline(uint expiryDeadline_) external onlyAdmin {

    _expiryDeadline = expiryDeadline_;

    // Emit the event
    emit SetExpiryDeadline(expiryDeadline_);
  }

  /// @notice Set the global cooldown timer for LP actions
  /// @param cooldownLP_ New cooldown time (in seconds)
  function _setCooldownLP(uint cooldownLP_) external onlyAdmin {

    _cooldownLP = cooldownLP_;

    // Emit the event
    emit SetCooldownLP(cooldownLP_);
  }

  /// @notice Set the global window for LP actions
  /// @param windowLP_ New window time (in seconds)
  function _setWindowLP(uint windowLP_) external onlyAdmin {

    _windowLP = windowLP_;

    // Emit the event
    emit SetWindowLP(windowLP_);
  }

  
  /** USER INTERFACE **/
  
  /** VIEW FUNCTIONS **/

  function affiliateERC721() external view returns(address) {
    return address(_affiliateERC721);
  }

  function toroDB() external view returns(address) {
    return address(_toroDB);
  }
  
  function priceOracle() external view returns(address) {
    return address(_priceOracle);
  }

  function sportOracle() external view returns(address) {
    return address(_sportOracle);
  }
  
  function feeEmissionsController() external view returns(address) {
    return address(_feeEmissionsController);
  }
  
  function toroPool(IERC20 currency) external view returns(IToroPool) {
    return _toroPools[currency];
  }

  function parentMarkets(IERC20 currency, uint sportId) external view returns(address[] memory) {
    return _parentMarkets[currency][sportId].elements;
  }

  function affiliateMintFee() external view returns(uint) {
    return _affiliateMintFee;
  }

  function bookmakingFeeBps() external view returns(uint) {
    return _bookmakingFeeBps;
  }
  
  function commissionFeeBps() external view returns(uint) {
    return _commissionFeeBps;
  }

  function affiliateBonusBps() external view returns(uint) {
    return _affiliateBonusBps;
  }

  function referentDiscountBps() external view returns(uint) {
    return _referentDiscountBps;
  }

  function expiryDeadline() external view returns(uint) {
    return _expiryDeadline;
  }

  function cooldownLP() external view returns(uint) {
    return _cooldownLP;
  }

  function windowLP() external view returns(uint) {
    return _windowLP;
  }
  
  function MANTISSA_BPS() public pure returns(uint) {
    return 1e4;
  }
  
  function MANTISSA_ODDS() public pure returns(uint) {
    return 1e8;
  }

  function MANTISSA_USD() public pure returns(uint) {
    return 1e18;
  }
  
  function NULL_AFFILIATE() public pure returns(uint) {
    return 0;
  }

  function OPTION_TIE() public pure returns(uint8) {
    return 0;
  }
  
  function OPTION_A() public pure returns(uint8) {
    return 1;
  }

  function OPTION_B() public pure returns(uint8) {
    return 2;
  }

  function OPTION_UNDEFINED() public pure returns(uint8) {
    return type(uint8).max;
  }
  
  function STATE_OPEN() public pure returns(uint8) {
    return 0;
  }

  function STATE_PENDING() public pure returns(uint8) {
    return 1;
  }

  function STATE_CLOSED() public pure returns(uint8) {
    return 2;
  }

  function STATE_EXPIRED() public pure returns(uint8) {
    return 3;
  }

  function BET_TYPE_MONEYLINE() public pure returns(uint8) {
    return 1;
  }

  function BET_TYPE_HANDICAP() public pure returns(uint8) {
    return 2;
  }

  function BET_TYPE_OVER_UNDER() public pure returns(uint8) {
    return 3;
  }
  
  function SPORT_TYPE_UFC() public pure returns(uint) {
    return 1;
  }

  function SPORT_TYPE_BOXING() public pure returns(uint) {
    return 2;
  }

  function SPORT_TYPE_EPL() public pure returns(uint) {
    return 3;
  }  
  
}