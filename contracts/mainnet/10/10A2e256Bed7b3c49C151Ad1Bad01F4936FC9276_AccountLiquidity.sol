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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '../Exponential/ExponentialNoError.sol';
import './Interfaces/IComptroller.sol';
import './Interfaces/ICToken.sol';
import './Interfaces/IPriceOracle.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

contract AccountLiquidity is AccessControlEnumerableUpgradeable {
  using ExponentialNoError for uint256;
  using ExponentialNoError for Exp;
  using ExponentialNoError for Double;

  IComptroller public comptroller;

  function initialize(address _admin) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function setComptroller(IComptroller _comptroller) external onlyRole(DEFAULT_ADMIN_ROLE) {
    comptroller = _comptroller;
  }

  struct AccountGroupLocalVars {
    uint8 groupId;
    uint256 cDepositVal;
    uint256 cBorrowVal;
    uint256 suDepositVal;
    uint256 suBorrowVal;
    Exp intraCRate;
    Exp intraMintRate;
    Exp intraSuRate;
    Exp interCRate;
    Exp interSuRate;
  }

  function getGroupVars(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) public view returns (AccountGroupLocalVars[] memory) {
    uint8 assetsGroupNum = IComptroller(comptroller).getAssetGroupNum();
    AccountGroupLocalVars[] memory groupVars = new AccountGroupLocalVars[](assetsGroupNum);
    IComptroller.AssetGroup[] memory assetGroups = IComptroller(comptroller).getAllAssetGroup();

    for (uint256 i = 0; i < assetGroups.length; i++) {
      IComptroller.AssetGroup memory g = assetGroups[i];
      groupVars[i] = AccountGroupLocalVars(
        g.groupId,
        0,
        0,
        0,
        0,
        Exp({mantissa: g.intraCRateMantissa}),
        Exp({mantissa: g.intraMintRateMantissa}),
        Exp({mantissa: g.intraSuRateMantissa}),
        Exp({mantissa: g.interCRateMantissa}),
        Exp({mantissa: g.interSuRateMantissa})
      );
    }

    // For each asset the account is in
    address[] memory assets = comptroller.getAssetsIn(account);

    // loop through tokens to add deposit/borrow for ctoken/sutoken in each group
    for (uint256 i = 0; i < assets.length; ++i) {
      address asset = assets[i];
      uint256 depositVal = 0;
      uint256 borrowVal = 0;

      (, uint8 assetGroupId, ) = comptroller.markets(asset);
      (uint256 oErr, uint256 depositBalance, uint256 borrowBalance, uint256 exchangeRateMantissa) = ICToken(asset)
        .getAccountSnapshot(account);
      require(oErr == 0, 'snapshot error');

      // Get price of asset
      IPriceOracle oracle = IPriceOracle(comptroller.oracle());
      uint256 oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
      require(oraclePriceMantissa > 0, 'price error');

      // normalize price for asset with unit of 1e(36-token decimal)
      Exp memory oraclePrice = Exp({mantissa: oraclePriceMantissa});
      uint8 decimals = ICToken(asset).decimals();
      if (decimals < 18) oraclePrice = oraclePrice.mul_(10 ** (18 - decimals));

      // Pre-compute a conversion factor from tokens -> USD (normalized price value)
      // tokensToDenom = oraclePrice * exchangeRate * discourntRate
      Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
      Exp memory discountRate = Exp({mantissa: ICToken(asset).getDiscountRate()});
      Exp memory tokensToDenom = exchangeRate.mul_(oraclePrice).mul_(discountRate);

      depositVal = tokensToDenom.mul_ScalarTruncateAddUInt(depositBalance, depositVal);
      borrowVal = oraclePrice.mul_ScalarTruncateAddUInt(borrowBalance, borrowVal);
      if (asset == cTokenModify) {
        uint256 redeemVal = tokensToDenom.mul_(redeemTokens).truncate();
        if (redeemVal <= depositVal) {
          // if redeemedVal <= depositVal, absorb it with deposits
          depositVal = depositVal.sub_(redeemVal);
          redeemVal = 0;
        } else {
          // if redeemVal > depositVal
          redeemVal = redeemVal.sub_(depositVal);
          borrowVal = borrowVal.add_(redeemVal);
          depositVal = 0;
        }

        borrowVal = oraclePrice.mul_ScalarTruncateAddUInt(borrowAmount, borrowVal);
      }

      uint8 index = comptroller.assetGroupIdToIndex(assetGroupId);

      if (ICToken(asset).isCToken()) {
        groupVars[index].cDepositVal = depositVal.add_(groupVars[index].cDepositVal);
        groupVars[index].cBorrowVal = borrowVal.add_(groupVars[index].cBorrowVal);
      } else {
        groupVars[index].suDepositVal = depositVal.add_(groupVars[index].suDepositVal);
        groupVars[index].suBorrowVal = borrowVal.add_(groupVars[index].suBorrowVal);
      }
    }
    // end of loop in assets
    return groupVars;
  }

  function getIntermediateGroupSummary(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) public view returns (uint256, uint256, AccountGroupLocalVars memory) {
    uint8 assetsGroupNum = IComptroller(comptroller).getAssetGroupNum();
    AccountGroupLocalVars[] memory groupVars = getGroupVars(account, cTokenModify, redeemTokens, borrowAmount);
    AccountGroupLocalVars memory targetGroup;
    // loop in groups to calculate accumulated collateral/liability for two types:
    // inter-group and intra-group for target token
    (, uint8 targetGroupId, ) = comptroller.markets(cTokenModify);

    uint256 sumLiquidity = 0;
    uint256 sumBorrowPlusEffects = 0;

    for (uint8 i = 0; i < assetsGroupNum; ++i) {
      if (groupVars[i].groupId == 0) {
        continue;
      }
      AccountGroupLocalVars memory g = groupVars[i];

      // absorb sutoken loan with ctoken collateral
      if (g.suBorrowVal > 0) {
        (g.cDepositVal, g.suBorrowVal) = absorbLoan(g.cDepositVal, g.suBorrowVal, g.intraMintRate);
      }

      // absorb ctoken loan with ctoken collateral
      if (g.cBorrowVal > 0) {
        (g.cDepositVal, g.cBorrowVal) = absorbLoan(g.cDepositVal, g.cBorrowVal, g.intraCRate);
      }

      // absorb sutoken loan with sutoken collateral
      if (g.suBorrowVal > 0) {
        (g.suDepositVal, g.suBorrowVal) = absorbLoan(g.suDepositVal, g.suBorrowVal, g.intraSuRate);
      }

      // absorb ctoken loan with sutoken collateral
      if (g.cBorrowVal > 0) {
        (g.suDepositVal, g.cBorrowVal) = absorbLoan(g.suDepositVal, g.cBorrowVal, g.intraSuRate);
      }

      if (g.groupId == targetGroupId) {
        targetGroup = g;
      } else {
        sumLiquidity = g.interCRate.mul_ScalarTruncateAddUInt(g.cDepositVal, sumLiquidity);
        sumLiquidity = g.interSuRate.mul_ScalarTruncateAddUInt(g.suDepositVal, sumLiquidity);
      }

      sumBorrowPlusEffects = sumBorrowPlusEffects.add_(g.cBorrowVal).add_(g.suBorrowVal);
    }
    return (sumLiquidity, sumBorrowPlusEffects, targetGroup);
  }

  function getHypotheticalGroupSummary(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) public view returns (uint256, uint256, AccountGroupLocalVars memory) {
    (
      uint256 sumLiquidity,
      uint256 sumBorrowPlusEffects,
      AccountGroupLocalVars memory targetGroup
    ) = getIntermediateGroupSummary(account, cTokenModify, redeemTokens, borrowAmount);

    // These are safe, as the underflow condition is checked first
    // absorb inter-group loan with inter-group collateral
    if (sumLiquidity > sumBorrowPlusEffects) {
      sumLiquidity = sumLiquidity - sumBorrowPlusEffects;
      sumBorrowPlusEffects = 0;
    } else {
      sumBorrowPlusEffects = sumBorrowPlusEffects - sumLiquidity;
      sumLiquidity = 0;
    }

    // absorb inter group loan with target group ctoken collateral
    if (sumBorrowPlusEffects > 0) {
      (targetGroup.cDepositVal, sumBorrowPlusEffects) = absorbLoan(
        targetGroup.cDepositVal,
        sumBorrowPlusEffects,
        targetGroup.interCRate
      );
    }

    // absorb inter group loan with target group sutoken collateral
    if (sumBorrowPlusEffects > 0) {
      (targetGroup.suDepositVal, sumBorrowPlusEffects) = absorbLoan(
        targetGroup.suDepositVal,
        sumBorrowPlusEffects,
        targetGroup.interSuRate
      );
    }
    return (sumLiquidity, sumBorrowPlusEffects, targetGroup);
  }

  function getHypotheticalSafeLimit(
    address account,
    address cTokenModify,
    uint256 intraSafeLimitMantissa,
    uint256 interSafeLimitMantissa
  ) public view returns (uint256) {
    (
      uint256 sumLiquidity,
      uint256 sumBorrowPlusEffects,
      AccountGroupLocalVars memory targetGroup
    ) = getHypotheticalGroupSummary(account, cTokenModify, uint256(0), uint256(0));

    Exp memory intraSafeLimit = Exp({mantissa: intraSafeLimitMantissa});
    Exp memory interSafeLimit = Exp({mantissa: interSafeLimitMantissa});
    bool targetIsSuToken = false;
    if ((cTokenModify != address(0)) && !ICToken(cTokenModify).isCToken()) {
      targetIsSuToken = true;
    } else {
      targetIsSuToken = false;
    }

    uint256 interGroupLiquidity = sumLiquidity;

    uint256 intraGroupLiquidity = targetGroup.intraSuRate.mul_ScalarTruncate(targetGroup.suDepositVal);
    if (targetIsSuToken) {
      intraGroupLiquidity = targetGroup.intraMintRate.mul_ScalarTruncateAddUInt(
        targetGroup.cDepositVal,
        intraGroupLiquidity
      );
    } else {
      intraGroupLiquidity = targetGroup.intraCRate.mul_ScalarTruncateAddUInt(
        targetGroup.cDepositVal,
        intraGroupLiquidity
      );
    }

    sumLiquidity = interGroupLiquidity.add_(intraGroupLiquidity);
    if (sumLiquidity <= sumBorrowPlusEffects) {
      return 0;
    }

    uint256 safeLimit = interSafeLimit.mul_ScalarTruncateAddUInt(interGroupLiquidity, 0);
    safeLimit = intraSafeLimit.mul_ScalarTruncateAddUInt(intraGroupLiquidity, safeLimit);
    return safeLimit;
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral cToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) public view returns (uint256, uint256, uint256) {
    (
      uint256 sumLiquidity,
      uint256 sumBorrowPlusEffects,
      AccountGroupLocalVars memory targetGroup
    ) = getHypotheticalGroupSummary(account, cTokenModify, redeemTokens, borrowAmount);
    bool targetIsSuToken = false;
    if ((cTokenModify != address(0)) && !ICToken(cTokenModify).isCToken()) {
      targetIsSuToken = true;
    } else {
      targetIsSuToken = false;
    }

    if (targetIsSuToken) {
      // if target is sutoken
      // limit = inter-group limit + intra ctoken collateral * intra mint rate
      sumLiquidity = targetGroup.intraMintRate.mul_ScalarTruncateAddUInt(targetGroup.cDepositVal, sumLiquidity);
    } else {
      // if target is not sutoken
      // limit = inter-group limit + intra ctoken collateral * intra c rate
      sumLiquidity = targetGroup.intraCRate.mul_ScalarTruncateAddUInt(targetGroup.cDepositVal, sumLiquidity);
    }

    // limit = inter-group limit + intra-group ctoken limit + intra sutoken collateral * intra su rate
    sumLiquidity = targetGroup.intraSuRate.mul_ScalarTruncateAddUInt(targetGroup.suDepositVal, sumLiquidity);

    if (sumLiquidity > sumBorrowPlusEffects) {
      return (0, sumLiquidity - sumBorrowPlusEffects, 0);
    } else {
      return (0, 0, sumBorrowPlusEffects - sumLiquidity);
    }
  }

  function absorbLoan(
    uint256 collateralValue,
    uint256 borrowValue,
    Exp memory collateralRate
  ) internal pure returns (uint256, uint256) {
    if (collateralRate.mantissa <= 0) {
      return (collateralValue, borrowValue);
    }
    uint256 collateralizedLoan = collateralRate.mul_ScalarTruncate(collateralValue);
    uint256 usedCollateral = borrowValue.div_(collateralRate);
    uint256 newCollateralValue = 0;
    uint256 newBorrowValue = 0;
    if (collateralizedLoan > borrowValue) {
      newCollateralValue = collateralValue.sub_(usedCollateral);
    } else {
      newBorrowValue = borrowValue.sub_(collateralizedLoan);
    }
    return (newCollateralValue, newBorrowValue);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '../Exponential/ExponentialNoError.sol';
import './Interfaces/IComptroller.sol';
import './Interfaces/ICToken.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

contract CompLogic is AccessControlEnumerableUpgradeable {
  using ExponentialNoError for uint256;
  using ExponentialNoError for Exp;
  using ExponentialNoError for Double;

  /// @notice The market's last updated compBorrowIndex or compSupplyIndex
  /// @notice The block number the index was last updated at
  struct CompMarketState {
    uint224 index;
    uint32 block;
  }
  address public comp;

  IComptroller public comptroller;
  /// @notice The COMP accrued but not yet transferred to each user
  mapping(address => uint256) public compAccrued;
  /// @notice The portion of COMP that each contributor receives per block
  mapping(address => uint256) public compContributorSpeeds;
  /// @notice The initial COMP index for a market
  uint224 public constant compInitialIndex = 1e36;
  /// @notice Last block at which a contributor's COMP rewards have been allocated
  mapping(address => uint256) public lastContributorBlock;
  /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
  mapping(address => mapping(address => uint256)) public compSupplierIndex;
  /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
  mapping(address => mapping(address => uint256)) public compBorrowerIndex;
  /// @notice The rate at which comp is distributed to the corresponding supply market (per block)
  mapping(address => uint256) public compSupplySpeeds;
  /// @notice The rate at which comp is distributed to the corresponding borrow market (per block)
  mapping(address => uint256) public compBorrowSpeeds;
  /// @notice The COMP market supply state for each market
  mapping(address => CompMarketState) public compSupplyState;
  /// @notice The COMP market borrow state for each market
  mapping(address => CompMarketState) public compBorrowState;

  /// @notice Emitted when COMP is granted by admin
  event CompGranted(address recipient, uint256 amount);
  /// @notice Emitted when a new COMP speed is set for a contributor
  event ContributorCompSpeedUpdated(address indexed contributor, uint256 newSpeed);
  /// @notice Emitted when a new supply-side COMP speed is calculated for a market
  event CompSupplySpeedUpdated(address indexed cToken, uint256 newSpeed);
  /// @notice Emitted when a new borrow-side COMP speed is calculated for a market
  event CompBorrowSpeedUpdated(address indexed cToken, uint256 newSpeed);
  /// @notice Emitted when COMP is distributed to a supplier
  event DistributedSupplierComp(
    address indexed cToken,
    address indexed supplier,
    uint256 compDelta,
    uint256 compSupplyIndex
  );

  /// @notice Emitted when COMP is distributed to a borrower
  event DistributedBorrowerComp(
    address indexed cToken,
    address indexed borrower,
    uint256 compDelta,
    uint256 compBorrowIndex
  );

  modifier onlyComptroller() {
    require(msg.sender == address(comptroller), 'forbidden!');
    _;
  }

  function initialize(address _admin, address _comp) external initializer {
    comp = _comp;
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  event SetComptroller(address comptroller);

  function setComptroller(IComptroller _comptroller) external onlyRole(DEFAULT_ADMIN_ROLE) {
    comptroller = _comptroller;
    emit SetComptroller(address(comptroller));
  }

  /*** Comp Distribution ***/

  /**
   * @notice Set COMP speed for a single market
   * @param cToken The market whose COMP speed to update
   * @param supplySpeed New supply-side COMP speed for market
   * @param borrowSpeed New borrow-side COMP speed for market
   */
  function setCompSpeed(address cToken, uint256 supplySpeed, uint256 borrowSpeed) external onlyComptroller {
    _setCompSpeedInternal(cToken, supplySpeed, borrowSpeed);
  }

  function _setCompSpeedInternal(address cToken, uint256 supplySpeed, uint256 borrowSpeed) private {
    (bool isListed, , ) = comptroller.markets(cToken);
    require(isListed, 'comp market is not listed');
    require(supplySpeed > 0, 'supplySpeed=0');
    require(borrowSpeed > 0, 'borrowSpeed=0');

    if (compSupplySpeeds[cToken] != supplySpeed) {
      // Supply speed updated so let's update supply state to ensure that
      //  1. COMP accrued properly for the old speed, and
      //  2. COMP accrued at the new speed starts after this block.
      _updateCompSupplyIndex(cToken);

      // Update speed and emit event
      compSupplySpeeds[cToken] = supplySpeed;
      emit CompSupplySpeedUpdated(cToken, supplySpeed);
    }

    if (compBorrowSpeeds[cToken] != borrowSpeed) {
      // Borrow speed updated so let's update borrow state to ensure that
      //  1. COMP accrued properly for the old speed, and
      //  2. COMP accrued at the new speed starts after this block.
      Exp memory borrowIndex = Exp({mantissa: ICToken(cToken).borrowIndex()});
      _updateCompBorrowIndex(cToken, borrowIndex);

      // Update speed and emit event
      compBorrowSpeeds[cToken] = borrowSpeed;
      emit CompBorrowSpeedUpdated(cToken, borrowSpeed);
    }
  }

  /**
   * @notice Accrue COMP to the market by updating the supply index
   * @param cToken The market whose supply index to update
   * @dev Index is a cumulative sum of the COMP per cToken accrued.
   */
  function updateCompSupplyIndex(address cToken) external onlyComptroller {
    _updateCompSupplyIndex(cToken);
  }

  function _updateCompSupplyIndex(address cToken) private {
    CompMarketState storage supplyState = compSupplyState[cToken];
    uint256 supplySpeed = compSupplySpeeds[cToken];
    uint32 blockNumber = block.number.safe32('block number exceeds 32 bits');
    uint256 deltaBlocks = uint256(blockNumber).sub_(uint256(supplyState.block));
    if (deltaBlocks != 0 && supplySpeed != 0) {
      uint256 supplyTokens = ICToken(cToken).totalSupply();
      uint256 _compAccrued = deltaBlocks.mul_(supplySpeed);
      Double memory ratio = supplyTokens > 0 ? _compAccrued.fraction(supplyTokens) : Double({mantissa: 0});
      supplyState.index = Double({mantissa: supplyState.index}).add_(ratio).mantissa.safe224(
        'new index exceeds 224 bits'
      );
      supplyState.block = blockNumber;
    } else if (deltaBlocks > 0) {
      supplyState.block = blockNumber;
    }
  }

  /**
   * @notice Accrue COMP to the market by updating the borrow index
   * @param cToken The market whose borrow index to update
   * @dev Index is a cumulative sum of the COMP per cToken accrued.
   */

  function updateCompBorrowIndex(address cToken, Exp memory marketBorrowIndex) external onlyComptroller {
    _updateCompBorrowIndex(cToken, marketBorrowIndex);
  }

  function _updateCompBorrowIndex(address cToken, Exp memory marketBorrowIndex) private {
    CompMarketState storage borrowState = compBorrowState[cToken];
    uint256 borrowSpeed = compBorrowSpeeds[cToken];
    uint32 blockNumber = block.number.safe32('block number exceeds 32 bits');
    uint256 deltaBlocks = uint256(blockNumber).sub_(uint256(borrowState.block));
    if (deltaBlocks > 0 && borrowSpeed > 0) {
      uint256 borrowAmount = ICToken(cToken).totalBorrows().div_(marketBorrowIndex);
      uint256 _compAccrued = deltaBlocks.mul_(borrowSpeed);
      Double memory ratio = borrowAmount > 0 ? _compAccrued.fraction(borrowAmount) : Double({mantissa: 0});
      borrowState.index = Double({mantissa: borrowState.index}).add_(ratio).mantissa.safe224(
        'new index exceeds 224 bits'
      );
      borrowState.block = blockNumber;
    } else if (deltaBlocks > 0) {
      borrowState.block = blockNumber;
    }
  }

  /**
   * @notice Calculate COMP accrued by a supplier and possibly transfer it to them
   * @param cToken The market in which the supplier is interacting
   * @param supplier The address of the supplier to distribute COMP to
   */

  function distributeSupplierComp(address cToken, address supplier) external onlyComptroller {
    _distributeSupplierComp(cToken, supplier);
  }

  function _distributeSupplierComp(address cToken, address supplier) private {
    // This check should be as gas efficient as possible as distributeSupplierComp is called in many places.
    // - We really don't want to call an external contract as that's quite expensive.

    CompMarketState storage supplyState = compSupplyState[cToken];
    uint256 supplyIndex = supplyState.index;
    uint256 supplierIndex = compSupplierIndex[cToken][supplier];

    // Update supplier's index to the current index since we are distributing accrued COMP
    compSupplierIndex[cToken][supplier] = supplyIndex;

    if (supplierIndex == 0 && supplyIndex >= compInitialIndex) {
      // Covers the case where users supplied tokens before the market's supply state index was set.
      // Rewards the user with COMP accrued from the start of when supplier rewards were first
      // set for the market.
      supplierIndex = compInitialIndex;
    }

    // Calculate change in the cumulative sum of the COMP per cToken accrued
    Double memory deltaIndex = Double({mantissa: supplyIndex.sub_(supplierIndex)});

    uint256 supplierTokens = ICToken(cToken).balanceOf(supplier);

    // Calculate COMP accrued: cTokenAmount * accruedPerCTokenInterface
    uint256 supplierDelta = supplierTokens.mul_(deltaIndex);

    uint256 supplierAccrued = compAccrued[supplier].add_(supplierDelta);
    compAccrued[supplier] = supplierAccrued;

    emit DistributedSupplierComp(cToken, supplier, supplierDelta, supplyIndex);
  }

  /**
   * @notice Calculate COMP accrued by a borrower and possibly transfer it to them
   * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
   * @param cToken The market in which the borrower is interacting
   * @param borrower The address of the borrower to distribute COMP to
   */
  function distributeBorrowerComp(
    address cToken,
    address borrower,
    Exp memory marketBorrowIndex
  ) external onlyComptroller {
    _distributeBorrowerComp(cToken, borrower, marketBorrowIndex);
  }

  function _distributeBorrowerComp(address cToken, address borrower, Exp memory marketBorrowIndex) private {
    // This check should be as gas efficient as possible as distributeBorrowerComp is called in many places.
    // - We really don't want to call an external contract as that's quite expensive.

    CompMarketState storage borrowState = compBorrowState[cToken];
    uint256 borrowIndex = borrowState.index;
    uint256 borrowerIndex = compBorrowerIndex[cToken][borrower];

    // Update borrowers's index to the current index since we are distributing accrued COMP
    compBorrowerIndex[cToken][borrower] = borrowIndex;

    if (borrowerIndex == 0 && borrowIndex >= compInitialIndex) {
      // Covers the case where users borrowed tokens before the market's borrow state index was set.
      // Rewards the user with COMP accrued from the start of when borrower rewards were first
      // set for the market.
      borrowerIndex = compInitialIndex;
    }

    // Calculate change in the cumulative sum of the COMP per borrowed unit accrued
    Double memory deltaIndex = Double({mantissa: borrowIndex.sub_(borrowerIndex)});

    uint256 borrowerAmount = ICToken(cToken).borrowBalanceStored(borrower).div_(marketBorrowIndex);

    // Calculate COMP accrued: cTokenAmount * accruedPerBorrowedUnit
    uint256 borrowerDelta = borrowerAmount.mul_(deltaIndex);

    uint256 borrowerAccrued = compAccrued[borrower].add_(borrowerDelta);
    compAccrued[borrower] = borrowerAccrued;

    emit DistributedBorrowerComp(cToken, borrower, borrowerDelta, borrowIndex);
  }

  /**
   * @notice Calculate additional accrued COMP for a contributor since last accrual
   * @param contributor The address to calculate contributor rewards for
   */
  function updateContributorRewards(address contributor) public {
    uint256 compSpeed = compContributorSpeeds[contributor];
    uint256 blockNumber = block.number;
    uint256 deltaBlocks = blockNumber.sub_(lastContributorBlock[contributor]);
    if (deltaBlocks > 0 && compSpeed > 0) {
      uint256 newAccrued = deltaBlocks.mul_(compSpeed);
      uint256 contributorAccrued = compAccrued[contributor].add_(newAccrued);

      compAccrued[contributor] = contributorAccrued;
      lastContributorBlock[contributor] = blockNumber;
    }
  }

  /**
   * @notice Claim all the comp accrued by holder in all markets
   * @param holder The address to claim COMP for
   */
  function claimSumer(address holder) public {
    return claimSumer(holder, comptroller.getAllMarkets());
  }

  /**
   * @notice Claim all the comp accrued by holder in the specified markets
   * @param holder The address to claim COMP for
   * @param cTokens The list of markets to claim COMP in
   */
  function claimSumer(address holder, address[] memory cTokens) public {
    address[] memory holders = new address[](1);
    holders[0] = holder;
    claimSumer(holders, cTokens, true, true);
  }

  /**
   * @notice Claim all comp accrued by the holders
   * @param holders The addresses to claim COMP for
   * @param cTokens The list of markets to claim COMP in
   * @param borrowers Whether or not to claim COMP earned by borrowing
   * @param suppliers Whether or not to claim COMP earned by supplying
   */
  function claimSumer(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) public {
    for (uint256 i = 0; i < cTokens.length; ++i) {
      address cToken = cTokens[i];
      (bool isListed, , ) = comptroller.markets(cToken);
      require(isListed, 'market must be listed');
      if (borrowers) {
        Exp memory borrowIndex = Exp({mantissa: ICToken(cToken).borrowIndex()});
        _updateCompBorrowIndex(cToken, borrowIndex);
        for (uint256 j = 0; j < holders.length; j++) {
          _distributeBorrowerComp(cToken, holders[j], borrowIndex);
        }
      }
      if (suppliers) {
        _updateCompSupplyIndex(cToken);
        for (uint256 j = 0; j < holders.length; j++) {
          _distributeSupplierComp(cToken, holders[j]);
        }
      }
    }
    for (uint256 j = 0; j < holders.length; j++) {
      compAccrued[holders[j]] = grantCompInternal(holders[j], compAccrued[holders[j]]);
    }
  }

  /**
   * @notice Transfer COMP to the user
   * @dev Note: If there is not enough COMP, we do not perform the transfer at all.
   * @param user The address of the user to transfer COMP to
   * @param amount The amount of COMP to (possibly) transfer
   * @return The amount of COMP which was NOT transferred to the user
   */
  function grantCompInternal(address user, uint256 amount) private returns (uint256) {
    address[] memory markets = comptroller.getAssetsIn(user);
    /***
        for (uint i = 0; i < allMarkets.length; ++i) {
            address market = address(allMarkets[i]);
        ***/
    for (uint256 i = 0; i < markets.length; ++i) {
      address market = address(markets[i]);
      bool noOriginalSpeed = compBorrowSpeeds[market] == 0;
      bool invalidSupply = noOriginalSpeed && compSupplierIndex[market][user] > 0;
      bool invalidBorrow = noOriginalSpeed && compBorrowerIndex[market][user] > 0;

      if (invalidSupply || invalidBorrow) {
        return amount;
      }
    }

    uint256 compRemaining = ICToken(comp).balanceOf(address(this));
    if (amount > 0 && amount <= compRemaining) {
      comp.call(abi.encodeWithSignature('transfer(address,uint256)', user, amount));
      return 0;
    }
    return amount;
  }

  function initializeMarket(address cToken, uint32 blockNumber) external onlyComptroller {
    CompMarketState storage supplyState = compSupplyState[cToken];
    CompMarketState storage borrowState = compBorrowState[cToken];
    /*
     * Update market state indices
     */
    if (supplyState.index == 0) {
      // Initialize supply state index with default value
      supplyState.index = compInitialIndex;
    }
    if (borrowState.index == 0) {
      // Initialize borrow state index with default value
      borrowState.index = compInitialIndex;
    }
    /*
     * Update market state block numbers
     */
    supplyState.block = borrowState.block = blockNumber;
  }

  /*** Comp Distribution Admin ***/
  /**
   * @notice Transfer COMP to the recipient
   * @dev Note: If there is not enough COMP, we do not perform the transfer at all.
   * @param recipient The address of the recipient to transfer COMP to
   * @param amount The amount of COMP to (possibly) transfer
   */
  function _grantComp(address recipient, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 amountLeft = grantCompInternal(recipient, amount);
    require(amountLeft == 0, 'insufficient comp for grant');
    emit CompGranted(recipient, amount);
  }

  /**
   * @notice Set COMP borrow and supply speeds for the specified markets.
   * @param cTokens The markets whose COMP speed to update.
   * @param supplySpeeds New supply-side COMP speed for the corresponding market.
   * @param borrowSpeeds New borrow-side COMP speed for the corresponding market.
   */
  function _setCompSpeeds(
    address[] memory cTokens,
    uint256[] memory supplySpeeds,
    uint256[] memory borrowSpeeds
  ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 numTokens = cTokens.length;
    require(
      numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length,
      'Comptroller::_setCompSpeeds invalid input'
    );

    for (uint256 i = 0; i < numTokens; ++i) {
      _setCompSpeedInternal(cTokens[i], supplySpeeds[i], borrowSpeeds[i]);
    }
  }

  /**
   * @notice Set COMP speed for a single contributor
   * @param contributor The contributor whose COMP speed to update
   * @param compSpeed New COMP speed for contributor
   */
  function _setContributorCompSpeed(address contributor, uint256 compSpeed) public onlyRole(DEFAULT_ADMIN_ROLE) {
    // note that COMP speed could be set to 0 to halt liquidity rewards for a contributor
    updateContributorRewards(contributor);
    if (compSpeed == 0) {
      // release storage
      delete lastContributorBlock[contributor];
    } else {
      lastContributorBlock[contributor] = block.number;
    }
    compContributorSpeeds[contributor] = compSpeed;

    emit ContributorCompSpeedUpdated(contributor, compSpeed);
  }

  function calculateComp(address holder) external view returns (uint256) {
    address[] memory cTokens = comptroller.getAllMarkets();
    uint256 accrued = compAccrued[holder];
    for (uint256 i = 0; i < cTokens.length; ++i) {
      address cToken = cTokens[i];
      Exp memory marketBorrowIndex = Exp({mantissa: ICToken(cToken).borrowIndex()});
      // _updateCompBorrowIndex
      CompMarketState memory borrowState = compBorrowState[cToken];
      uint256 borrowSpeed = compBorrowSpeeds[cToken];
      uint32 blockNumber = block.number.safe32('block number exceeds 32 bits');
      uint256 borrowDeltaBlocks = uint256(blockNumber).sub_(uint256(borrowState.block));
      if (borrowDeltaBlocks > 0 && borrowSpeed > 0) {
        uint256 borrowAmount = ICToken(cToken).totalBorrows().div_(marketBorrowIndex);
        uint256 _compAccrued = borrowDeltaBlocks.mul_(borrowSpeed);
        Double memory ratio = borrowAmount > 0 ? _compAccrued.fraction(borrowAmount) : Double({mantissa: 0});
        borrowState.index = Double({mantissa: borrowState.index}).add_(ratio).mantissa.safe224(
          'new index exceeds 224 bits'
        );
        borrowState.block = blockNumber;
      } else if (borrowDeltaBlocks > 0) {
        borrowState.block = blockNumber;
      }
      // _distributeBorrowerComp
      uint256 borrowIndex = borrowState.index;
      uint256 borrowerIndex = compBorrowerIndex[cToken][holder];
      if (borrowerIndex == 0 && borrowIndex >= compInitialIndex) {
        borrowerIndex = compInitialIndex;
      }
      Double memory borrowDeltaIndex = Double({mantissa: borrowIndex.sub_(borrowerIndex)});
      uint256 borrowerAmount = ICToken(cToken).borrowBalanceStored(holder).div_(marketBorrowIndex);
      uint256 borrowerDelta = borrowerAmount.mul_(borrowDeltaIndex);
      accrued = accrued.add_(borrowerDelta);
      // _updateCompSupplyIndex
      CompMarketState memory supplyState = compSupplyState[cToken];
      uint256 supplySpeed = compSupplySpeeds[cToken];
      uint256 supplyDeltaBlocks = uint256(blockNumber).sub_(uint256(supplyState.block));
      if (supplyDeltaBlocks > 0 && supplySpeed > 0) {
        uint256 supplyTokens = ICToken(cToken).totalSupply();
        uint256 _compAccrued = supplyDeltaBlocks.mul_(supplySpeed);
        Double memory ratio = supplyTokens > 0 ? _compAccrued.fraction(supplyTokens) : Double({mantissa: 0});
        supplyState.index = Double({mantissa: supplyState.index}).add_(ratio).mantissa.safe224(
          'new index exceeds 224 bits'
        );
        supplyState.block = blockNumber;
      } else if (supplyDeltaBlocks > 0) {
        supplyState.block = blockNumber;
      }
      // _distributeSupplierComp
      uint256 supplyIndex = supplyState.index;
      uint256 supplierIndex = compSupplierIndex[cToken][holder];
      if (supplierIndex == 0 && supplyIndex >= compInitialIndex) {
        supplierIndex = compInitialIndex;
      }
      Double memory supplyDeltaIndex = Double({mantissa: supplyIndex.sub_(supplierIndex)});
      uint256 supplierTokens = ICToken(cToken).balanceOf(holder);
      uint256 supplierDelta = supplierTokens.mul_(supplyDeltaIndex);
      accrued = accrued.add_(supplierDelta);
    }
    return accrued;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './Interfaces/ICToken.sol';
import './Interfaces/IPriceOracle.sol';
import './Interfaces/IGovernorAlpha.sol';
import './Interfaces/IComptroller.sol';
import './Interfaces/IGovernorBravo.sol';
import '../Exponential/ExponentialNoError.sol';
import './ComptrollerStorage.sol';

contract CompoundLens {
  using ExponentialNoError for uint256;
  using ExponentialNoError for Exp;
  using ExponentialNoError for Double;
  struct CTokenMetadata {
    address cToken;
    uint256 exchangeRateCurrent;
    uint256 supplyRatePerBlock;
    uint256 borrowRatePerBlock;
    uint256 reserveFactorMantissa;
    uint256 totalBorrows;
    uint256 totalReserves;
    uint256 totalSupply;
    uint256 totalCash;
    bool isListed;
    // uint256 collateralFactorMantissa;
    address underlyingAssetAddress;
    uint256 cTokenDecimals;
    uint256 underlyingDecimals;
    bool isCToken;
    bool isCEther;
    uint256 borrowCap;
    uint256 depositCap;
    uint256 heteroLiquidationIncentive;
    uint256 homoLiquidationIncentive;
    uint256 sutokenLiquidationIncentive;
    uint8 groupId;
    uint256 intraRate;
    uint256 mintRate;
    uint256 interRate;
    uint256 discountRate;
  }

  struct GroupInfo {
    uint256 intraRate;
    uint256 mintRate;
    uint256 interRate;
  }

  function cTokenMetadata(ICToken cToken) public returns (CTokenMetadata memory) {
    IComptroller comptroller = IComptroller(address(cToken.comptroller()));

    // get underlying info
    address underlyingAssetAddress;
    uint256 underlyingDecimals;
    if (cToken.isCEther()) {
      underlyingAssetAddress = address(0);
      underlyingDecimals = 18;
    } else {
      underlyingAssetAddress = cToken.underlying();
      underlyingDecimals = ICToken(cToken.underlying()).decimals();
    }

    // get group info
    (bool isListed, uint8 assetGroupId, ) = comptroller.markets(address(cToken));
    IComptroller.AssetGroup memory group = comptroller.getAssetGroup(assetGroupId);
    GroupInfo memory gi;
    if (cToken.isCToken()) {
      gi.intraRate = group.intraCRateMantissa;
      gi.interRate = group.interCRateMantissa;
      gi.mintRate = group.intraMintRateMantissa;
    } else {
      gi.intraRate = group.intraSuRateMantissa;
      gi.interRate = group.interSuRateMantissa;
      gi.mintRate = group.intraSuRateMantissa;
    }
    (uint256 heteroIncentiveMantissa, uint256 homoIncentiveMantissa, uint256 sutokenIncentiveMantissa) = comptroller
      .liquidationIncentiveMantissa();
    return
      CTokenMetadata({
        cToken: address(cToken),
        exchangeRateCurrent: cToken.exchangeRateCurrent(),
        supplyRatePerBlock: cToken.supplyRatePerBlock(),
        borrowRatePerBlock: cToken.borrowRatePerBlock(),
        reserveFactorMantissa: cToken.reserveFactorMantissa(),
        totalBorrows: cToken.totalBorrows(),
        totalReserves: cToken.totalReserves(),
        totalSupply: cToken.totalSupply(),
        totalCash: cToken.getCash(),
        isListed: isListed,
        underlyingAssetAddress: underlyingAssetAddress,
        cTokenDecimals: cToken.decimals(),
        underlyingDecimals: underlyingDecimals,
        isCToken: cToken.isCToken(),
        isCEther: cToken.isCEther(),
        borrowCap: comptroller._getMarketBorrowCap(address(cToken)),
        depositCap: ComptrollerStorage(address(comptroller)).maxSupply(address(cToken)),
        heteroLiquidationIncentive: heteroIncentiveMantissa,
        homoLiquidationIncentive: homoIncentiveMantissa,
        sutokenLiquidationIncentive: sutokenIncentiveMantissa,
        groupId: assetGroupId,
        intraRate: gi.intraRate,
        interRate: gi.interRate,
        mintRate: gi.mintRate,
        discountRate: cToken.getDiscountRate()
      });
  }

  function cTokenMetadataAll(ICToken[] calldata cTokens) external returns (CTokenMetadata[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenMetadata[] memory res = new CTokenMetadata[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenMetadata(cTokens[i]);
    }
    return res;
  }

  struct CTokenBalances {
    address cToken;
    bool isCToken;
    bool isCEther;
    uint256 balanceOf;
    uint256 borrowBalanceCurrent;
    uint256 balanceOfUnderlying;
    uint256 tokenBalance;
    uint256 tokenAllowance;
  }

  function cTokenBalances(ICToken cToken, address payable account) public returns (CTokenBalances memory) {
    uint256 balanceOf = cToken.balanceOf(account);
    uint256 borrowBalanceCurrent = cToken.borrowBalanceCurrent(account);
    uint256 balanceOfUnderlying = cToken.balanceOfUnderlying(account);
    uint256 tokenBalance;
    uint256 tokenAllowance;

    if (cToken.isCEther()) {
      tokenBalance = account.balance;
      tokenAllowance = account.balance;
    } else {
      ICToken underlying = ICToken(cToken.underlying());
      tokenBalance = underlying.balanceOf(account);
      tokenAllowance = underlying.allowance(account, address(cToken));
    }

    return
      CTokenBalances({
        cToken: address(cToken),
        isCToken: cToken.isCToken(),
        isCEther: cToken.isCEther(),
        balanceOf: balanceOf,
        borrowBalanceCurrent: borrowBalanceCurrent,
        balanceOfUnderlying: balanceOfUnderlying,
        tokenBalance: tokenBalance,
        tokenAllowance: tokenAllowance
      });
  }

  function cTokenBalancesAll(
    ICToken[] calldata cTokens,
    address payable account
  ) external returns (CTokenBalances[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenBalances[] memory res = new CTokenBalances[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenBalances(cTokens[i], account);
    }
    return res;
  }

  struct CTokenUnderlyingPrice {
    address cToken;
    uint256 underlyingPrice;
  }

  function cTokenUnderlyingPrice(ICToken cToken) public view returns (CTokenUnderlyingPrice memory) {
    IComptroller comptroller = IComptroller(address(cToken.comptroller()));
    IPriceOracle priceOracle = IPriceOracle(comptroller.oracle());

    return
      CTokenUnderlyingPrice({
        cToken: address(cToken),
        underlyingPrice: priceOracle.getUnderlyingPrice(address(cToken))
      });
  }

  function cTokenUnderlyingPriceAll(ICToken[] calldata cTokens) external view returns (CTokenUnderlyingPrice[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenUnderlyingPrice[] memory res = new CTokenUnderlyingPrice[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenUnderlyingPrice(cTokens[i]);
    }
    return res;
  }

  struct AccountLimits {
    address[] markets;
    uint256 liquidity;
    uint256 shortfall;
  }

  function getAccountLimits(IComptroller comptroller, address account) public returns (AccountLimits memory) {
    (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(account);
    require(errorCode == 0);

    return AccountLimits({markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall});
  }

  struct GovReceipt {
    uint256 proposalId;
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  function getGovReceipts(
    IGovernorAlpha governor,
    address voter,
    uint256[] memory proposalIds
  ) public view returns (GovReceipt[] memory) {
    uint256 proposalCount = proposalIds.length;
    GovReceipt[] memory res = new GovReceipt[](proposalCount);
    for (uint256 i = 0; i < proposalCount; i++) {
      IGovernorAlpha.Receipt memory receipt;

      (receipt.hasVoted, receipt.support, receipt.votes) = governor.getReceipt(proposalIds[i], voter);
      res[i] = GovReceipt({
        proposalId: proposalIds[i],
        hasVoted: receipt.hasVoted,
        support: receipt.support,
        votes: receipt.votes
      });
    }
    return res;
  }

  struct GovBravoReceipt {
    uint256 proposalId;
    bool hasVoted;
    uint8 support;
    uint96 votes;
  }

  function getGovBravoReceipts(
    IGovernorBravo governor,
    address voter,
    uint256[] memory proposalIds
  ) public view returns (GovBravoReceipt[] memory) {
    uint256 proposalCount = proposalIds.length;
    GovBravoReceipt[] memory res = new GovBravoReceipt[](proposalCount);
    for (uint256 i = 0; i < proposalCount; i++) {
      IGovernorBravo.Receipt memory receipt = governor.getReceipt(proposalIds[i], voter);
      res[i] = GovBravoReceipt({
        proposalId: proposalIds[i],
        hasVoted: receipt.hasVoted,
        support: receipt.support,
        votes: receipt.votes
      });
    }
    return res;
  }

  struct GovProposal {
    uint256 proposalId;
    address proposer;
    uint256 eta;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    bool canceled;
    bool executed;
  }

  function setProposal(GovProposal memory res, IGovernorAlpha governor, uint256 proposalId) internal view {
    (
      ,
      address proposer,
      uint256 eta,
      uint256 startBlock,
      uint256 endBlock,
      uint256 forVotes,
      uint256 againstVotes,
      bool canceled,
      bool executed
    ) = governor.proposals(proposalId);
    res.proposalId = proposalId;
    res.proposer = proposer;
    res.eta = eta;
    res.startBlock = startBlock;
    res.endBlock = endBlock;
    res.forVotes = forVotes;
    res.againstVotes = againstVotes;
    res.canceled = canceled;
    res.executed = executed;
  }

  function getGovProposals(
    IGovernorAlpha governor,
    uint256[] calldata proposalIds
  ) external view returns (GovProposal[] memory) {
    GovProposal[] memory res = new GovProposal[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
      ) = governor.getActions(proposalIds[i]);
      res[i] = GovProposal({
        proposalId: 0,
        proposer: address(0),
        eta: 0,
        targets: targets,
        values: values,
        signatures: signatures,
        calldatas: calldatas,
        startBlock: 0,
        endBlock: 0,
        forVotes: 0,
        againstVotes: 0,
        canceled: false,
        executed: false
      });
      setProposal(res[i], governor, proposalIds[i]);
    }
    return res;
  }

  struct GovBravoProposal {
    uint256 proposalId;
    address proposer;
    uint256 eta;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    bool canceled;
    bool executed;
  }

  function setBravoProposal(GovBravoProposal memory res, IGovernorBravo governor, uint256 proposalId) internal view {
    IGovernorBravo.Proposal memory p = governor.proposals(proposalId);

    res.proposalId = proposalId;
    res.proposer = p.proposer;
    res.eta = p.eta;
    res.startBlock = p.startBlock;
    res.endBlock = p.endBlock;
    res.forVotes = p.forVotes;
    res.againstVotes = p.againstVotes;
    res.abstainVotes = p.abstainVotes;
    res.canceled = p.canceled;
    res.executed = p.executed;
  }

  function getGovBravoProposals(
    IGovernorBravo governor,
    uint256[] calldata proposalIds
  ) external view returns (GovBravoProposal[] memory) {
    GovBravoProposal[] memory res = new GovBravoProposal[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
      ) = governor.getActions(proposalIds[i]);
      res[i] = GovBravoProposal({
        proposalId: 0,
        proposer: address(0),
        eta: 0,
        targets: targets,
        values: values,
        signatures: signatures,
        calldatas: calldatas,
        startBlock: 0,
        endBlock: 0,
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        canceled: false,
        executed: false
      });
      setBravoProposal(res[i], governor, proposalIds[i]);
    }
    return res;
  }

  struct CompBalanceMetadata {
    uint256 balance;
    uint256 votes;
    address delegate;
  }

  function getCompBalanceMetadata(ICToken comp, address account) external view returns (CompBalanceMetadata memory) {
    return
      CompBalanceMetadata({
        balance: comp.balanceOf(account),
        votes: uint256(comp.getCurrentVotes(account)),
        delegate: comp.delegates(account)
      });
  }

  struct CompBalanceMetadataExt {
    uint256 balance;
    uint256 votes;
    address delegate;
    uint256 allocated;
  }

  function getCompBalanceMetadataExt(
    ICToken comp,
    IComptroller comptroller,
    address account
  ) external returns (CompBalanceMetadataExt memory) {
    uint256 balance = comp.balanceOf(account);
    comptroller.claimComp(account);
    uint256 newBalance = comp.balanceOf(account);
    uint256 accrued = comptroller.compAccrued(account);
    uint256 total = add(accrued, newBalance, 'sum comp total');
    uint256 allocated = sub(total, balance, 'sub allocated');

    return
      CompBalanceMetadataExt({
        balance: balance,
        votes: uint256(comp.getCurrentVotes(account)),
        delegate: comp.delegates(account),
        allocated: allocated
      });
  }

  struct CompVotes {
    uint256 blockNumber;
    uint256 votes;
  }

  function getCompVotes(
    ICToken comp,
    address account,
    uint32[] calldata blockNumbers
  ) external view returns (CompVotes[] memory) {
    CompVotes[] memory res = new CompVotes[](blockNumbers.length);
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      res[i] = CompVotes({
        blockNumber: uint256(blockNumbers[i]),
        votes: uint256(comp.getPriorVotes(account, blockNumbers[i]))
      });
    }
    return res;
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  /**
   * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
   * @dev Used in liquidation (called in ICToken(cToken).liquidateBorrowFresh)
   * @param cTokenBorrowed The address of the borrowed cToken
   * @param cTokenCollateral The address of the collateral cToken
   * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
   * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
   */
  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint256 actualRepayAmount,
    IComptroller comptroller
  ) external view returns (uint256, uint256) {
    /* Read oracle prices for borrowed and collateral markets */
    address oracle = comptroller.oracle();
    uint256 priceBorrowedMantissa = IPriceOracle(oracle).getUnderlyingPrice(address(cTokenBorrowed));
    uint256 priceCollateralMantissa = IPriceOracle(oracle).getUnderlyingPrice(address(cTokenCollateral));
    require(priceBorrowedMantissa > 0 && priceCollateralMantissa > 0, 'PRICE_ERROR');

    /*
     * Get the exchange rate and calculate the number of collateral tokens to seize:
     *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     *  seizeTokens = seizeAmount / exchangeRate
     *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     */
    uint256 exchangeRateMantissa = ICToken(cTokenCollateral).exchangeRateStored(); // Note: reverts on error
    uint256 seizeTokens;
    Exp memory numerator;
    Exp memory denominator;
    Exp memory ratio;

    (, uint8 repayTokenGroupId, ) = comptroller.markets(cTokenBorrowed);
    (, uint8 seizeTokenGroupId, ) = comptroller.markets(cTokenCollateral);
    (uint256 heteroIncentiveMantissa, uint256 homoIncentiveMantissa, uint256 sutokenIncentiveMantissa) = comptroller
      .liquidationIncentiveMantissa();

    // default is repaying heterogeneous assets
    uint256 incentiveMantissa = heteroIncentiveMantissa;
    if (repayTokenGroupId == seizeTokenGroupId) {
      if (ICToken(cTokenBorrowed).isCToken() == false) {
        // repaying sutoken
        incentiveMantissa = sutokenIncentiveMantissa;
      } else {
        // repaying homogeneous assets
        incentiveMantissa = homoIncentiveMantissa;
      }
    }

    numerator = Exp({mantissa: incentiveMantissa}).mul_(Exp({mantissa: priceBorrowedMantissa}));
    denominator = Exp({mantissa: priceCollateralMantissa}).mul_(Exp({mantissa: exchangeRateMantissa}));
    ratio = numerator.div_(denominator);

    seizeTokens = ratio.mul_ScalarTruncate(actualRepayAmount);

    return (uint256(0), seizeTokens);
  }

  /**
   * @notice Returns true if the given cToken market has been deprecated
   * @dev All borrows in a deprecated cToken market can be immediately liquidated
   * @param cToken The market to check if deprecated
   */
  function isDeprecated(address cToken, IComptroller comptroller) public view returns (bool) {
    return
      comptroller.marketGroupId(cToken) == 0 &&
      //borrowGuardianPaused[cToken] == true &&
      IComptroller(comptroller)._getBorrowPaused(cToken) &&
      ICToken(cToken).reserveFactorMantissa() == 1e18;
  }

  /**
   * @notice Checks if the liquidation should be allowed to occur
   * @param cTokenBorrowed Asset which was borrowed by the borrower
   * @param cTokenCollateral Asset which was used as collateral and will be seized
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param repayAmount The amount of underlying being repaid
   */
  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount,
    IComptroller comptroller
  ) external view returns (uint256) {
    // Shh - currently unused: liquidator;

    require(comptroller.isListed(cTokenBorrowed) && comptroller.isListed(cTokenCollateral), 'MARKET_NOT_LISTED');

    uint256 borrowBalance = ICToken(cTokenBorrowed).borrowBalanceStored(borrower);

    /* allow accounts to be liquidated if the market is deprecated */
    if (isDeprecated(cTokenBorrowed, comptroller)) {
      require(borrowBalance >= repayAmount, 'too much repay');
    } else {
      /* The borrower must have shortfall in order to be liquidatable */
      (, , uint256 shortfall) = comptroller.getHypotheticalAccountLiquidity(borrower, cTokenBorrowed, 0, 0);

      require(shortfall > 0, 'insufficient shortfall');

      /* The liquidator may not repay more than what is allowed by the closeFactor */
      uint256 maxClose = Exp({mantissa: comptroller.closeFactorMantissa()}).mul_ScalarTruncate(borrowBalance);
      require(repayAmount <= maxClose, 'too much repay');
    }
    return uint256(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './ComptrollerStorage.sol';
import '../Exponential/ExponentialNoError.sol';
import './Interfaces/ICToken.sol';
import './Interfaces/IPriceOracle.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import './Interfaces/IComptroller.sol';

interface ICompLogic {
  function setCompSpeed(address cToken, uint256 supplySpeed, uint256 borrowSpeed) external;

  function updateCompSupplyIndex(address cToken) external;

  function updateCompBorrowIndex(address cToken, Exp memory marketBorrowIndex) external;

  function distributeSupplierComp(address cToken, address supplier) external;

  function distributeBorrowerComp(address cToken, address borrower, Exp memory marketBorrowIndex) external;

  function initializeMarket(address cToken, uint32 blockNumber) external;
}

interface IAccountLiquidity {
  struct AccountGroupLocalVars {
    uint8 groupId;
    uint256 cDepositVal;
    uint256 cBorrowVal;
    uint256 suDepositVal;
    uint256 suBorrowVal;
    Exp intraCRate;
    Exp intraMintRate;
    Exp intraSuRate;
    Exp interCRate;
    Exp interSuRate;
  }

  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) external view returns (uint256, uint256, uint256);

  function getHypotheticalSafeLimit(
    address account,
    address cTokenModify,
    uint256 intraSafeLimitMantissa,
    uint256 interSafeLimitMantissa
  ) external view returns (uint256);

  function getGroupVars(
    address account,
    address cTokenModify,
    uint256 intraSafeLimitMantissa,
    uint256 interSafeLimitMantissa
  ) external view returns (AccountGroupLocalVars[] memory);

  function getIntermediateGroupSummary(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) external view returns (uint256, uint256, AccountGroupLocalVars memory);

  function getHypotheticalGroupSummary(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) external view returns (uint256, uint256, AccountGroupLocalVars memory);
}

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract Comptroller is AccessControlEnumerableUpgradeable, ComptrollerStorage {
  using ExponentialNoError for uint256;
  using ExponentialNoError for Exp;
  using ExponentialNoError for Double;

  ICompLogic public compLogic;
  IPriceOracle public oracle;
  IAccountLiquidity public accountLiquidity;

  bytes32 public constant COMP_LOGIC = keccak256('COMP_LOGIC');

  address public timelock;

  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant CAPPER_ROLE = keccak256('CAPPER_ROLE');

  /// @notice Emitted when an action is paused on a market
  event ActionPaused(address cToken, string action, bool pauseState);

  /// @notice Emitted when borrow cap for a cToken is changed
  event NewBorrowCap(address indexed cToken, uint256 newBorrowCap);

  /// @notice Emitted when borrow cap guardian is changed
  event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

  /// @notice Emitted when pause guardian is changed
  event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

  event RemoveAssetGroup(uint8 indexed groupId, uint8 equalAssetsGroupNum);

  function initialize(
    address _admin,
    IPriceOracle _oracle,
    address _gov,
    ICompLogic _compLogic,
    IAccountLiquidity _accountLiquidity,
    uint256 _closeFactorMantissa,
    uint256 _heteroLiquidationIncentiveMantissa,
    uint256 _homoLiquidationIncentiveMantissa,
    uint256 _sutokenLiquidationIncentiveMantissa
  ) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);

    governanceToken = _gov;
    suTokenRateMantissa = 10 ** 18;
    // Set comptroller's oracle to newOracle
    oracle = _oracle;
    // Emit NewPriceOracle(oldOracle, newOracle)
    emit NewPriceOracle(address(0), address(_oracle));
    compLogic = _compLogic;

    accountLiquidity = _accountLiquidity;

    closeFactorMantissa = _closeFactorMantissa;
    emit NewCloseFactor(0, _closeFactorMantissa);

    // Set liquidation incentive to new incentive
    heteroLiquidationIncentiveMantissa = _heteroLiquidationIncentiveMantissa;
    homoLiquidationIncentiveMantissa = _homoLiquidationIncentiveMantissa;
    sutokenLiquidationIncentiveMantissa = _sutokenLiquidationIncentiveMantissa;
    // Emit event with old incentive, new incentive
    emit NewLiquidationIncentive(
      0,
      _heteroLiquidationIncentiveMantissa,
      0,
      _homoLiquidationIncentiveMantissa,
      0,
      _sutokenLiquidationIncentiveMantissa
    );
  }

  event NewAssetGroup(
    uint8 indexed groupId,
    string indexed groupName,
    uint256 intraCRateMantissa,
    uint256 intraMintRateMantissa,
    uint256 intraSuRateMantissa,
    uint256 interCRateMantissa,
    uint256 interSuRateMantissa,
    uint8 assetsGroupNum
  );

  /*** Assets You Are In ***/

  /**
   * @notice Returns the assets an account has entered
   * @param account The address of the account to pull assets for
   * @return A dynamic list with the assets the account has entered
   */
  function getAssetsIn(address account) external view returns (address[] memory) {
    address[] memory assetsIn = accountAssets[account];

    return assetsIn;
  }

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param account The address of the account to check
   * @param cToken The cToken to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(address account, address cToken) external view returns (bool) {
    return markets[cToken].accountMembership[account];
  }

  function isListed(address asset) external view returns (bool) {
    return markets[asset].isListed;
  }

  function marketGroupId(address asset) external view returns (uint8) {
    return markets[asset].assetGroupId;
  }

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param cTokens The list of addresses of the cToken markets to be enabled
   * @return Success indicator for whether each corresponding market was entered
   */
  function enterMarkets(address[] memory cTokens) public returns (uint256[] memory) {
    uint256 len = cTokens.length;

    uint256[] memory results = new uint256[](len);
    for (uint256 i = 0; i < len; ++i) {
      address cToken = cTokens[i];
      //IIComptroller(address(this))IComptroller.AssetGroup memory eqAssets = IComptroller(address(this))getAssetGroup(cToken);
      //results[i] = uint(addToMarketInternal(cToken, msg.sender, eqAssets.groupName, eqAssets.rateMantissas));
      results[i] = uint256(addToMarketInternal(cToken, msg.sender));
    }

    return results;
  }

  /**
   * @notice Add the market to the borrower's "assets in" for liquidity calculations
   * @param cToken The market to enter
   * @param borrower The address of the account to modify
   * @return Success indicator for whether the market was entered
   */
  function addToMarketInternal(address cToken, address borrower) internal returns (uint256) {
    Market storage marketToJoin = markets[cToken];

    require(marketToJoin.isListed, MARKET_NOT_LISTED);

    if (marketToJoin.accountMembership[borrower]) {
      // already joined
      return uint256(0);
    }

    // survived the gauntlet, add to list
    // NOTE: we store these somewhat redundantly as a significant optimization
    //  this avoids having to iterate through the list for the most common use cases
    //  that is, only when we need to perform liquidity checks
    //  and not whenever we want to check if an account is in a particular market
    marketToJoin.accountMembership[borrower] = true;
    accountAssets[borrower].push(cToken);

    // all tokens are grouped with equal assets.
    //addToEqualAssetGroupInternal(cToken, borrower, eqAssetGroup, rateMantissa);

    emit MarketEntered(cToken, borrower);

    return uint256(0);
  }

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param cTokenAddress The address of the asset to be removed
   * @return Whether or not the account successfully exited the market
   */
  function exitMarket(address cTokenAddress) external returns (uint256) {
    address cToken = cTokenAddress;
    /* Get sender tokensHeld and amountOwed underlying from the cToken */
    (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = ICToken(cToken).getAccountSnapshot(msg.sender);
    require(oErr == 0, SNAPSHOT_ERROR); // semi-opaque error code

    /* Fail if the sender has a borrow balance */
    require(amountOwed == 0, 'nonzero borrow balance');

    /* Fail if the sender is not permitted to redeem all of their tokens */
    redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);

    Market storage marketToExit = markets[cToken];

    /* Return true if the sender is not already ‘in’ the market */
    if (!marketToExit.accountMembership[msg.sender]) {
      return uint256(0);
    }

    /* Set cToken account membership to false */
    delete marketToExit.accountMembership[msg.sender];

    /* Delete cToken from the account’s list of assets */
    // load into memory for faster iteration
    address[] memory userAssetList = accountAssets[msg.sender];
    uint256 len = userAssetList.length;
    uint256 assetIndex = len;
    for (uint256 i = 0; i < len; ++i) {
      if (userAssetList[i] == cToken) {
        assetIndex = i;
        break;
      }
    }

    // We *must* have found the asset in the list or our redundant data structure is broken
    assert(assetIndex < len);

    // copy last item in list to location of item to be removed, reduce length by 1
    address[] storage storedList = accountAssets[msg.sender];
    storedList[assetIndex] = storedList[storedList.length - 1];
    storedList.pop();

    // remove the same
    //exitEqualAssetGroupInternal(cTokenAddress, msg.sender);

    emit MarketExited(cToken, msg.sender);

    return uint256(0);
  }

  /*** Policy Hooks ***/

  /**
   * @notice Checks if the account should be allowed to mint tokens in the given market
   * @param cToken The market to verify the mint against
   * @param minter The account which would get the minted tokens
   * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
   * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    //require(!mintGuardianPaused[cToken], "mint is paused");
    require(!IComptroller(address(this))._getMintPaused(cToken), 'mint paused');

    // Shh - currently unused: minter; mintAmount;

    require(markets[cToken].isListed, MARKET_NOT_LISTED);

    /* Get minter's cToken balance*/
    (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = ICToken(cToken).getAccountSnapshot(minter);
    require(oErr == 0, SNAPSHOT_ERROR); // semi-opaque error code

    // only enter market automatically at the first time
    if ((!markets[cToken].accountMembership[minter]) && (tokensHeld == 0) && (amountOwed == 0)) {
      // only cTokens may call mintAllowed if minter not in market
      require(msg.sender == cToken, 'sender must be cToken');

      // attempt to add borrower to the market
      addToMarketInternal(msg.sender, minter);

      // it should be impossible to break the important invariant
      assert(markets[cToken].accountMembership[minter]);
    }

    // Keep the flywheel moving
    compLogic.updateCompSupplyIndex(cToken);
    compLogic.distributeSupplierComp(cToken, minter);

    require(
      maxSupply[cToken] == 0 ||
        (maxSupply[cToken] > 0 && ICToken(cToken).totalSupply().add_(mintAmount) <= maxSupply[cToken]),
      'cToken > maxSupply'
    );

    return uint256(0);
  }

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param cToken The market to verify the redeem against
   * @param redeemer The account which would redeem the tokens
   * @param redeemTokens The number of cTokens to exchange for the underlying asset in the market
   * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external returns (uint256) {
    redeemAllowedInternal(cToken, redeemer, redeemTokens);

    // Keep the flywheel moving
    compLogic.updateCompSupplyIndex(cToken);
    compLogic.distributeSupplierComp(cToken, redeemer);

    return uint256(0);
  }

  function redeemAllowedInternal(
    address cToken,
    address redeemer,
    uint256 redeemTokens
  ) internal view returns (uint256) {
    require(markets[cToken].isListed, MARKET_NOT_LISTED);

    /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
    if (!markets[cToken].accountMembership[redeemer]) {
      return uint256(0);
    }

    /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
    (, , uint256 shortfall) = accountLiquidity.getHypotheticalAccountLiquidity(redeemer, cToken, redeemTokens, 0);
    require(shortfall == 0, INSUFFICIENT_LIQUIDITY);

    return uint256(0);
  }

  /**
   * @notice Validates redeem and reverts on rejection. May emit logs.
   * @param cToken Asset being redeemed
   * @param redeemer The address redeeming the tokens
   * @param redeemAmount The amount of the underlying asset being redeemed
   * @param redeemTokens The number of tokens being redeemed
   */
  function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external {
    // Shh - currently unused: cToken; redeemer;

    // Require tokens is zero or amount is also zero
    if (redeemTokens == 0 && redeemAmount > 0) {
      revert('redeemTokens zero');
    }
  }

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param cToken The market to verify the borrow against
   * @param borrower The account which would borrow the asset
   * @param borrowAmount The amount of underlying the account would borrow
   * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    //require(!borrowGuardianPaused[cToken], "borrow is paused");
    require(!IComptroller(address(this))._getBorrowPaused(cToken), 'borrow paused');

    require(markets[cToken].isListed, MARKET_NOT_LISTED);

    if (!markets[cToken].accountMembership[borrower]) {
      // only cTokens may call borrowAllowed if borrower not in market
      require(msg.sender == cToken, 'sender must be cToken');

      // attempt to add borrower to the market
      addToMarketInternal(msg.sender, borrower);

      // it should be impossible to break the important invariant
      assert(markets[cToken].accountMembership[borrower]);
    }

    require(oracle.getUnderlyingPrice(cToken) > 0, 'PRICE_ERROR');

    //uint borrowCap = borrowCaps[cToken];
    uint256 borrowCap = IComptroller(address(this))._getMarketBorrowCap(cToken);
    // Borrow cap of 0 corresponds to unlimited borrowing
    if (borrowCap != 0) {
      uint256 totalBorrows = ICToken(cToken).totalBorrows();
      uint256 nextTotalBorrows = totalBorrows.add_(borrowAmount);
      require(nextTotalBorrows < borrowCap, 'borrow cap reached');
    }

    (, , uint256 shortfall) = accountLiquidity.getHypotheticalAccountLiquidity(borrower, cToken, 0, borrowAmount);
    require(shortfall <= 0, INSUFFICIENT_LIQUIDITY);

    // Keep the flywheel moving
    Exp memory borrowIndex = Exp({mantissa: ICToken(cToken).borrowIndex()});
    compLogic.updateCompBorrowIndex(cToken, borrowIndex);
    compLogic.distributeBorrowerComp(cToken, borrower, borrowIndex);

    return uint256(0);
  }

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param cToken The market to verify the repay against
   * @param payer The account which would repay the asset
   * @param borrower The account which would borrowed the asset
   * @param repayAmount The amount of the underlying asset the account would repay
   * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function repayBorrowAllowed(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256) {
    // Shh - currently unused: repayAmount;

    require(markets[cToken].isListed, MARKET_NOT_LISTED);

    // Keep the flywheel moving
    Exp memory borrowIndex = Exp({mantissa: ICToken(cToken).borrowIndex()});
    compLogic.updateCompBorrowIndex(cToken, borrowIndex);
    compLogic.distributeBorrowerComp(cToken, borrower, borrowIndex);

    return uint256(0);
  }

  /**
   * @notice Checks if the seizing of assets should be allowed to occur
   * @param cTokenCollateral Asset which was used as collateral and will be seized
   * @param cTokenBorrowed Asset which was borrowed by the borrower
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param seizeTokens The number of collateral tokens to seize
   */
  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    //require(!seizeGuardianPaused, "seize is paused");
    require(!IComptroller(address(this))._getSeizePaused(), 'seize paused');

    // Shh - currently unused: seizeTokens;

    require(markets[cTokenCollateral].isListed && markets[cTokenBorrowed].isListed, MARKET_NOT_LISTED);

    require(ICToken(cTokenCollateral).comptroller() == ICToken(cTokenBorrowed).comptroller(), 'comptroller mismatch');

    // Keep the flywheel moving
    compLogic.updateCompSupplyIndex(cTokenCollateral);
    compLogic.distributeSupplierComp(cTokenCollateral, borrower);
    compLogic.distributeSupplierComp(cTokenCollateral, liquidator);

    return uint256(0);
  }

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param cToken The market to verify the transfer against
   * @param src The account which sources the tokens
   * @param dst The account which receives the tokens
   * @param transferTokens The number of cTokens to transfer
   * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function transferAllowed(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    //require(!transferGuardianPaused, "transfer is paused");
    require(!IComptroller(address(this))._getTransferPaused(), 'transfer paused');

    // Currently the only consideration is whether or not
    //  the src is allowed to redeem this many tokens
    redeemAllowedInternal(cToken, src, transferTokens);

    // Keep the flywheel moving
    compLogic.updateCompSupplyIndex(cToken);
    compLogic.distributeSupplierComp(cToken, src);
    compLogic.distributeSupplierComp(cToken, dst);

    return uint256(0);
  }

  /*** Liquidity/Liquidation Calculations ***/

  /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
  function getAccountLiquidity(address account) public view returns (uint256, uint256, uint256) {
    (uint256 err, uint256 liquidity, uint256 shortfall) = accountLiquidity.getHypotheticalAccountLiquidity(
      account,
      address(0),
      0,
      0
    );

    return (uint256(err), liquidity, shortfall);
  }

  function getAccountSafeLimit(
    address account,
    address cTokenTarget,
    uint256 intraSafeLimitMantissa,
    uint256 interSafeLimitMantissa
  ) public view returns (uint256) {
    return
      accountLiquidity.getHypotheticalSafeLimit(account, cTokenTarget, intraSafeLimitMantissa, interSafeLimitMantissa);
  }

  function getAccountGroupVars(
    address account,
    address cTokenTarget
  ) public view returns (IAccountLiquidity.AccountGroupLocalVars[] memory) {
    return accountLiquidity.getGroupVars(account, cTokenTarget, 0, 0);
  }

  function getAccountIntermediateGroupSummary(
    address account,
    address cTokenTarget
  ) public view returns (uint256, uint256, IAccountLiquidity.AccountGroupLocalVars memory) {
    return accountLiquidity.getIntermediateGroupSummary(account, cTokenTarget, 0, 0);
  }

  function getAccountGroupSummary(
    address account,
    address cTokenTarget
  ) public view returns (uint256, uint256, IAccountLiquidity.AccountGroupLocalVars memory) {
    return accountLiquidity.getHypotheticalGroupSummary(account, cTokenTarget, 0, 0);
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) public view returns (uint256, uint256, uint256) {
    (uint256 err, uint256 liquidity, uint256 shortfall) = accountLiquidity.getHypotheticalAccountLiquidity(
      account,
      address(cTokenModify),
      redeemTokens,
      borrowAmount
    );
    return (uint256(err), liquidity, shortfall);
  }

  /*** Admin Functions ***/

  function setTimelock(address _timelock) public onlyRole(DEFAULT_ADMIN_ROLE) {
    timelock = _timelock;
  }

  /**
   * @notice Sets a new price oracle for the comptroller
   * @dev Admin function to set a new price oracle
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPriceOracle(IPriceOracle newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    // Check caller is admin
    // Track the old oracle for the comptroller
    IPriceOracle oldOracle = oracle;
    // Set comptroller's oracle to newOracle
    oracle = newOracle;
    // Emit NewPriceOracle(oldOracle, newOracle)
    emit NewPriceOracle(address(oldOracle), address(newOracle));
    return uint256(0);
  }

  /**
   * @notice Sets the closeFactor used when liquidating borrows
   * @dev Admin function to set closeFactor
   * @param newCloseFactorMantissa New close factor, scaled by 1e18
   * @return uint 0=success, otherwise a failure
   */
  function _setCloseFactor(uint256 newCloseFactorMantissa) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    require(newCloseFactorMantissa > 0, 'newCloseFactorMantissa=0');
    // Check caller is admin
    uint256 oldCloseFactorMantissa = closeFactorMantissa;
    closeFactorMantissa = newCloseFactorMantissa;
    emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

    return uint256(0);
  }

  /**
   * @notice Sets liquidationIncentive
   * @dev Admin function to set liquidationIncentive
   * @param newHeteroLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18 for hetero assets
   * @param newHomoLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18 for homo assets
   * @param newSutokenLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18 for sutoken assets
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setLiquidationIncentive(
    uint256 newHeteroLiquidationIncentiveMantissa,
    uint256 newHomoLiquidationIncentiveMantissa,
    uint256 newSutokenLiquidationIncentiveMantissa
  ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    // Check caller is admin
    // Save current value for use in log
    uint256 oldHetero = heteroLiquidationIncentiveMantissa;
    uint256 oldHomo = homoLiquidationIncentiveMantissa;
    uint256 oldSutoken = sutokenLiquidationIncentiveMantissa;
    // Set liquidation incentive to new incentive
    heteroLiquidationIncentiveMantissa = newHeteroLiquidationIncentiveMantissa;
    homoLiquidationIncentiveMantissa = newHomoLiquidationIncentiveMantissa;
    sutokenLiquidationIncentiveMantissa = newSutokenLiquidationIncentiveMantissa;
    // Emit event with old incentive, new incentive
    emit NewLiquidationIncentive(
      oldHetero,
      newHeteroLiquidationIncentiveMantissa,
      oldHomo,
      newHomoLiquidationIncentiveMantissa,
      oldSutoken,
      newSutokenLiquidationIncentiveMantissa
    );
    return uint256(0);
  }

  /**
   * @notice Add the market to the markets mapping and set it as listed
   * @dev Admin function to set isListed and add support for the market
   * @param cToken The address of the market (token) to list
   * @return uint 0=success, otherwise a failure. (See enum uint256 for details)
   */
  function _supportMarket(address cToken, uint8 groupId) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    require(!markets[cToken].isListed, 'market already listed');
    require(groupId > 0, 'groupId > 0');

    // ICToken(cToken).isCToken(); // Sanity check to make sure its really a address
    (bool success, ) = cToken.call(abi.encodeWithSignature('isCToken()'));
    require(success && isContract(cToken), 'contract error!');

    // Note that isComped is not in active use anymore
    // markets[cToken] = Market({isListed: true, isComped: false, assetGroupId: groupId});
    Market storage market = markets[cToken];
    market.isListed = true;
    market.assetGroupId = groupId;

    _addMarketInternal(cToken);
    _initializeMarket(cToken);

    emit MarketListed(cToken);

    return uint256(0);
  }

  function _addMarketInternal(address cToken) internal {
    for (uint256 i = 0; i < allMarkets.length; ++i) {
      require(allMarkets[i] != cToken, 'market already added');
    }
    allMarkets.push(cToken);
  }

  function _initializeMarket(address cToken) internal {
    uint32 blockNumber = block.number.safe32('block number exceeds 32 bits');
    compLogic.initializeMarket(cToken, blockNumber);
  }

  function setCompSpeed(
    address cToken,
    uint256 supplySpeed,
    uint256 borrowSpeed
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    compLogic.setCompSpeed(cToken, supplySpeed, borrowSpeed);
  }

  function setCompLogic(ICompLogic _compLogic) external onlyRole(DEFAULT_ADMIN_ROLE) {
    compLogic = _compLogic;
  }

  function setAccountLiquidity(IAccountLiquidity _accountLiquidity) external onlyRole(DEFAULT_ADMIN_ROLE) {
    accountLiquidity = _accountLiquidity;
  }

  /**
   * @notice Return all of the markets
   * @dev The automatic getter may be used to access an individual market.
   * @return The list of market addresses
   */
  function getAllMarkets() public view returns (address[] memory) {
    return allMarkets;
  }

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
   */
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function liquidationIncentiveMantissa() public view returns (uint256, uint256, uint256) {
    return (heteroLiquidationIncentiveMantissa, homoLiquidationIncentiveMantissa, sutokenLiquidationIncentiveMantissa);
  }

  function eqAssetGroup(uint8 groupId) public view returns (IComptroller.AssetGroup memory) {
    return _eqAssetGroups[assetGroupIdToIndex[groupId] - 1];
  }

  function setAssetGroup(
    uint8 groupId,
    string memory groupName,
    uint256 intraCRateMantissa, // ctoken collateral rate for intra group ctoken liability
    uint256 intraMintRateMantissa, // ctoken collateral rate for intra group sutoken liability
    uint256 intraSuRateMantissa, // sutoken collateral rate for intra group ctoken liability
    uint256 interCRateMantissa, // ctoken collateral rate for inter group ctoken/sutoken liability
    uint256 interSuRateMantissa // sutoken collateral rate for inter group ctoken/sutoken liability
  ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    uint8 index = assetGroupIdToIndex[groupId];
    if (index >= _eqAssetGroups.length || _eqAssetGroups[index].groupId != groupId) {
      // append new group
      _eqAssetGroups.push(
        IComptroller.AssetGroup(
          groupId,
          groupName,
          intraCRateMantissa,
          intraMintRateMantissa,
          intraSuRateMantissa,
          interCRateMantissa,
          interSuRateMantissa,
          true
        )
      );
      uint8 newIndex = uint8(_eqAssetGroups.length) - 1;
      assetGroupIdToIndex[groupId] = newIndex;

      emit NewAssetGroup(
        groupId,
        groupName,
        intraCRateMantissa,
        intraMintRateMantissa,
        intraSuRateMantissa,
        interCRateMantissa,
        interSuRateMantissa,
        newIndex
      );
    } else {
      require(_eqAssetGroups[index].groupId == groupId, 'groupId mismatch');
      // update existing group
      _eqAssetGroups[index] = IComptroller.AssetGroup(
        groupId,
        groupName,
        intraCRateMantissa,
        intraMintRateMantissa,
        intraSuRateMantissa,
        interCRateMantissa,
        interSuRateMantissa,
        true
      );
    }
    return 0;
  }

  function removeAssetGroup(uint8 groupId) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    uint8 length = uint8(_eqAssetGroups.length);
    uint8 lastGroupId = _eqAssetGroups[length - 1].groupId;
    uint8 index = assetGroupIdToIndex[groupId];

    _eqAssetGroups[index] = _eqAssetGroups[length - 1];
    assetGroupIdToIndex[lastGroupId] = index;
    _eqAssetGroups.pop();
    delete assetGroupIdToIndex[groupId];

    emit RemoveAssetGroup(groupId, length);
    return uint256(0);
  }

  function cleanAssetGroup() public {
    for (uint8 i = 0; i < _eqAssetGroups.length; i++) {
      uint8 groupId = _eqAssetGroups[i].groupId;
      delete assetGroupIdToIndex[groupId];
    }

    uint8 len = uint8(_eqAssetGroups.length);
    for (uint8 i = 0; i < len; i++) {
      _eqAssetGroups.pop();
    }
  }

  function getAssetGroup(uint8 groupId) external view returns (IComptroller.AssetGroup memory) {
    return _eqAssetGroups[assetGroupIdToIndex[groupId]];
  }

  function getAssetGroupNum() external view returns (uint8) {
    return uint8(_eqAssetGroups.length);
  }

  function getAllAssetGroup() external view returns (IComptroller.AssetGroup[] memory) {
    return _eqAssetGroups;
  }

  function getAllAssetGroupByIndex(uint8 groupIndex) external view returns (IComptroller.AssetGroup memory) {
    return _eqAssetGroups[groupIndex];
  }

  /**
   * @notice Admin function to change the Pause Guardian
   * @param newPauseGuardian The address of the new Pause Guardian
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _setPauseGuardian(address newPauseGuardian) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    require(newPauseGuardian != address(0), 'Address is Zero!');

    // Save current value for inclusion in log
    address oldPauseGuardian = pauseGuardian;
    revokeRole(PAUSER_ROLE, oldPauseGuardian);

    // Store pauseGuardian with value newPauseGuardian
    pauseGuardian = newPauseGuardian;
    grantRole(PAUSER_ROLE, newPauseGuardian);

    // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
    emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

    return uint256(0);
  }

  function _getPauseGuardian() external view returns (address) {
    return pauseGuardian;
  }

  modifier onlyAdminOrPauser(bool state) {
    if (state) {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'only admin can unpause');
    } else {
      require(
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(PAUSER_ROLE, msg.sender),
        'only admin or pauser can pause'
      );
    }
    _;
  }

  function _setMintPaused(ICToken cToken, bool state) external onlyAdminOrPauser(state) returns (bool) {
    mintGuardianPaused[address(cToken)] = state;
    emit ActionPaused(address(cToken), 'Mint', state);
    return state;
  }

  function _getMintPaused(address cToken) external view returns (bool) {
    return mintGuardianPaused[cToken];
  }

  function _setBorrowPaused(ICToken cToken, bool state) external onlyAdminOrPauser(state) returns (bool) {
    borrowGuardianPaused[address(cToken)] = state;
    emit ActionPaused(address(cToken), 'Borrow', state);
    return state;
  }

  function _getBorrowPaused(address cToken) external view returns (bool) {
    return borrowGuardianPaused[cToken];
  }

  function _setTransferPaused(bool state) external onlyAdminOrPauser(state) returns (bool) {
    transferGuardianPaused = state;
    emit ActionPaused(address(0), 'Transfer', state);
    return state;
  }

  function _getTransferPaused() external view returns (bool) {
    return transferGuardianPaused;
  }

  function _setSeizePaused(bool state) external onlyAdminOrPauser(state) returns (bool) {
    seizeGuardianPaused = state;
    emit ActionPaused(address(0), 'Seize', state);
    return state;
  }

  function _getSeizePaused() external view returns (bool) {
    return seizeGuardianPaused;
  }

  /**
   * @notice Return the address of the COMP token
   * @return The address of COMP
   */
  function getCompAddress() external view returns (address) {
    /*
        return 0xc00e94Cb662C3520282E6f5717214004A7f26888;
        */
    return governanceToken;
  }

  /**
   * @notice Return the address of the COMP token
   * @param _governanceToken The address of COMP(governance token)
   */
  function setGovTokenAddress(address _governanceToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //require(adminOrInitializing(), "only admin can set governanceToken");
    require(_governanceToken != address(0), 'Address is Zero!');
    governanceToken = _governanceToken;
  }

  modifier onlyAdminOrCapper() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(CAPPER_ROLE, msg.sender),
      'only admin or capper can set cap'
    );
    _;
  }

  /**
   * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
   * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
   * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
   * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
   */
  function _setMarketBorrowCaps(
    ICToken[] calldata cTokens,
    uint256[] calldata newBorrowCaps
  ) external onlyAdminOrCapper {
    uint256 numMarkets = cTokens.length;
    uint256 numBorrowCaps = newBorrowCaps.length;

    require(numMarkets != 0 && numMarkets == numBorrowCaps, 'invalid input');

    for (uint256 i = 0; i < numMarkets; i++) {
      borrowCaps[address(cTokens[i])] = newBorrowCaps[i];
      emit NewBorrowCap(address(cTokens[i]), newBorrowCaps[i]);
    }
  }

  function _setMaxSupply(
    ICToken[] calldata cTokens,
    uint256[] calldata newMaxSupplys
  ) external onlyAdminOrCapper returns (uint256) {
    uint256 numMarkets = cTokens.length;
    uint256 numMaxSupplys = newMaxSupplys.length;

    require(numMarkets != 0 && numMarkets == numMaxSupplys, 'invalid input');

    for (uint256 i = 0; i < numMarkets; i++) {
      maxSupply[address(cTokens[i])] = newMaxSupplys[i];
      emit SetMaxSupply(address(cTokens[i]), newMaxSupplys[i]);
    }

    return uint256(0);
  }

  function _getMarketBorrowCap(address cToken) external view returns (uint256) {
    return borrowCaps[cToken];
  }

  /**
   * @notice Admin function to change the Borrow Cap Guardian
   * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
   */
  function _setBorrowCapGuardian(address newBorrowCapGuardian) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(newBorrowCapGuardian != address(0), 'Address is Zero!');

    // Save current value for inclusion in log
    address oldBorrowCapGuardian = borrowCapGuardian;
    revokeRole(CAPPER_ROLE, oldBorrowCapGuardian);

    // Store borrowCapGuardian with value newBorrowCapGuardian
    borrowCapGuardian = newBorrowCapGuardian;
    grantRole(CAPPER_ROLE, newBorrowCapGuardian);

    // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
    emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
  }

  function _getBorrowCapGuardian() external view returns (address) {
    return borrowCapGuardian;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './Interfaces/IComptroller.sol';

contract ComptrollerStorage {
  /// @notice Indicator that this is a Comptroller contract (for inspection)
  bool public constant isComptroller = true;

  /**
   * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
   */
  uint256 public closeFactorMantissa;

  /**
   * @notice Multiplier representing the discount on collateral that a liquidator receives
   */
  uint256 public heteroLiquidationIncentiveMantissa;

  string internal constant INSUFFICIENT_LIQUIDITY = 'insufficient liquidity';
  string internal constant MARKET_NOT_LISTED = 'market not listed';
  string internal constant UNAUTHORIZED = 'unauthorized';
  string internal constant SNAPSHOT_ERROR = 'snapshot error';
  /**
   * @notice Per-account mapping of "assets you are in", capped by maxAssets
   */
  mapping(address => address[]) public accountAssets;
  /// @notice Whether or not this market is listed
  /// @notice Per-market mapping of "accounts in this asset"
  /// @notice Whether or not this market receives COMP
  struct Market {
    bool isListed;
    uint8 assetGroupId;
    mapping(address => bool) accountMembership;
    bool isComped;
  }

  /**
   * @notice Official mapping of cTokens -> Market metadata
   * @dev Used e.g. to determine if a market is supported
   */
  mapping(address => Market) public markets;

  /// @notice A list of all markets
  address[] public allMarkets;

  mapping(address => uint256) public maxSupply;

  /// @notice Emitted when an admin supports a market
  event MarketListed(address cToken);

  /// @notice Emitted when an account enters a market
  event MarketEntered(address cToken, address account);

  /// @notice Emitted when an account exits a market
  event MarketExited(address cToken, address account);

  /// @notice Emitted when close factor is changed by admin
  event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

  /// @notice Emitted when liquidation incentive is changed by admin
  event NewLiquidationIncentive(
    uint256 oldHeteroIncentive,
    uint256 newHeteroIncentive,
    uint256 oldHomoIncentive,
    uint256 newHomoIncentive,
    uint256 oldSutokenIncentive,
    uint256 newSutokenIncentive
  );

  /// @notice Emitted when price oracle is changed
  event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

  event SetMaxSupply(address indexed cToken, uint256 amount);

  /*
    Liquidation Incentive for repaying homogeneous token
  */
  uint256 public homoLiquidationIncentiveMantissa;

  /*
    Liquidation Incentive for repaying sutoken
  */
  uint256 public sutokenLiquidationIncentiveMantissa;

  address public governanceToken;

  uint256 public suTokenRateMantissa;

  /**
   * @notice eqAssetGroup, cToken -> equal assets info.
   */

  // uint8 public equalAssetsGroupNum;
  /**
   * @notice eqAssetGroup, groupId -> equal assets info.
   */
  // mapping(uint8 => IComptroller.AssetGroup) public eqAssetGroup;

  IComptroller.AssetGroup[] internal _eqAssetGroups;

  mapping(uint8 => uint8) public assetGroupIdToIndex;

  /**
   * @notice The Pause Guardian can pause certain actions as a safety mechanism.
   *  Actions which allow users to remove their own assets cannot be paused.
   *  Liquidation / seizing / transfer can only be paused globally, not by market.
   */
  address public pauseGuardian;
  bool public _mintGuardianPaused;
  bool public _borrowGuardianPaused;
  bool public transferGuardianPaused;
  bool public seizeGuardianPaused;
  mapping(address => bool) public mintGuardianPaused;
  mapping(address => bool) public borrowGuardianPaused;

  // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
  address public borrowCapGuardian;

  // @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
  mapping(address => uint256) public borrowCaps;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IComptroller {
  /*** Assets You Are In ***/
  function isComptroller() external view returns (bool);

  function markets(address) external view returns (bool, uint8, bool);

  function getAllMarkets() external view returns (address[] memory);

  function oracle() external view returns (address);

  function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

  function exitMarket(address cToken) external returns (uint256);

  function closeFactorMantissa() external view returns (uint256);

  function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);

  // function getAssetsIn(address) external view returns (ICToken[] memory);
  function claimComp(address) external;

  function compAccrued(address) external view returns (uint256);

  function getAssetsIn(address account) external view returns (address[] memory);

  function timelock() external view returns (address);

  /*** Policy Hooks ***/

  function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256);

  function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external returns (uint256);

  function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

  function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external returns (uint256);

  function repayBorrowAllowed(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  function transferAllowed(address cToken, address src, address dst, uint256 transferTokens) external returns (uint256);

  /*** Liquidity/Liquidation Calculations ***/

  function liquidationIncentiveMantissa() external view returns (uint256, uint256, uint256);

  function isListed(address asset) external view returns (bool);

  function marketGroupId(address asset) external view returns (uint8);

  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) external view returns (uint256, uint256, uint256);

  // function _getMarketBorrowCap(address cToken) external view returns (uint256);

  /// @notice Emitted when an action is paused on a market
  event ActionPaused(address cToken, string action, bool pauseState);

  /// @notice Emitted when borrow cap for a cToken is changed
  event NewBorrowCap(address indexed cToken, uint256 newBorrowCap);

  /// @notice Emitted when borrow cap guardian is changed
  event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

  /// @notice Emitted when pause guardian is changed
  event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

  event RemoveAssetGroup(uint8 indexed groupId, uint8 equalAssetsGroupNum);

  /// @notice AssetGroup, contains information of groupName and rateMantissas
  struct AssetGroup {
    uint8 groupId;
    string groupName;
    uint256 intraCRateMantissa;
    uint256 intraMintRateMantissa;
    uint256 intraSuRateMantissa;
    uint256 interCRateMantissa;
    uint256 interSuRateMantissa;
    bool exist;
  }

  function getAssetGroupNum() external view returns (uint8);

  function getAssetGroup(uint8 groupId) external view returns (AssetGroup memory);

  function getAllAssetGroup() external view returns (AssetGroup[] memory);

  function assetGroupIdToIndex(uint8) external view returns (uint8);

  function _getMintPaused(address cToken) external returns (bool);

  function _getTransferPaused() external view returns (bool);

  function _getBorrowPaused(address cToken) external view returns (bool);

  function _getSeizePaused() external view returns (bool);

  function getCompAddress() external view returns (address);

  function _getMarketBorrowCap(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICToken {
  function comptroller() external view returns (address);

  function reserveFactorMantissa() external view returns (uint256);

  function borrowIndex() external view returns (uint256);

  function totalBorrows() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function isCToken() external view returns (bool);

  function balanceOf(address owner) external view returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function borrowBalanceStored(address account) external view returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function underlying() external view returns (address);

  function exchangeRateCurrent() external returns (uint256);

  function isCEther() external view returns (bool);

  function supplyRatePerBlock() external view returns (uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function totalReserves() external view returns (uint256);

  function getCash() external view returns (uint256);

  function decimals() external view returns (uint8);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function getCurrentVotes(address account) external view returns (uint96);

  function delegates(address) external view returns (address);

  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

  function getDiscountRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract IGovernorAlpha {
  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }
  // Ballot receipt record for a voter
  // Whether or not a vote has been cast
  // Whether or not the voter supports the proposal
  // The number of votes the voter had, which were cast
  struct Receipt {
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  function getReceipt(uint256 proposalId, address voter)
    external
    view
    virtual
    returns (
      bool,
      bool,
      uint96
    );

  mapping(uint256 => Proposal) public proposals;

  function getActions(uint256 proposalId)
    public
    view
    virtual
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGovernorBravo {
  struct Receipt {
    bool hasVoted;
    uint8 support;
    uint96 votes;
  }
  struct Proposal {
    uint256 id;
    address proposer;
    uint256 eta;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    bool canceled;
    bool executed;
  }

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function proposals(uint256 proposalId) external view returns (Proposal memory);

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPriceOracle {
  /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './CToken.sol';
import './Interfaces/ICErc20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../ITimelock.sol';

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract CErc20 is CToken, ICErc20, Initializable {
  using CarefulMath for uint256;
  using TokenErrorReporter for Error;
  using Exponential for Exp;
  /**
   * @notice Initialize the new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  function initialize(
    address underlying_,
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_
  ) public initializer {
    // CToken initialize does the bulk of the work
    super.initialize(
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      true,
      admin_,
      discountRateMantissa_
    );

    isCEther = false;

    // Set underlying and sanity check it
    require(underlying_ != address(0), 'Address is Zero!');
    underlying = underlying_;
    // ICToken(underlying).totalSupply();
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    (uint256 err, ) = mintInternal(mintAmount);
    return err;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external override returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external override returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external override returns (uint256) {
    (uint256 err, ) = repayBorrowInternal(repayAmount);
    return err;
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being paid off
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external override returns (uint256) {
    (uint256 err, ) = repayBorrowBehalfInternal(borrower, repayAmount);
    return err;
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external override returns (uint256) {
    (uint256 err, ) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
    return err;
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(address token) external override {
    require(address(token) != underlying, 'CErc20::sweepToken: can not sweep underlying token');
    uint256 underlyingBalanceBefore = ICToken(underlying).balanceOf(address(this));
    uint256 balance = ICToken(token).balanceOf(address(this));
    ICToken(token).transfer(admin, balance);
    uint256 underlyingBalanceAfter = ICToken(underlying).balanceOf(address(this));
    require(underlyingBalanceBefore == underlyingBalanceAfter, 'underlyingBalance error');
  }

  /**
   * @notice The sender adds to reserves.
   * @param addAmount The amount fo underlying token to add as reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external override returns (uint256) {
    return _addReservesInternal(addAmount);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view virtual override returns (uint256) {
    // ICToken token = ICToken(underlying);
    // return token.balanceOf(address(this));
    return underlyingBalance;
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal virtual override returns (uint256) {
    ICToken token = ICToken(underlying);
    uint256 balanceBefore = ICToken(underlying).balanceOf(address(this));
    token.transferFrom(from, address(this), amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, 'TOKEN_TRANSFER_IN_FAILED');

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = ICToken(underlying).balanceOf(address(this));
    require(balanceAfter >= balanceBefore, 'TOKEN_TRANSFER_IN_OVERFLOW');
    uint256 finalAmount = balanceAfter - balanceBefore;
    underlyingBalance += finalAmount;
    return finalAmount; // underflow already checked above, just subtract
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual override {
    ICToken token = ICToken(underlying);
    token.transfer(to, amount);
    underlyingBalance -= amount;

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, 'TOKEN_TRANSFER_OUT_FAILED');
  }

  function transferToTimelock(bool isBorrow, address to, uint256 amount) internal virtual override {
    address timelock = IComptroller(comptroller).timelock();
    if (ITimelock(timelock).isSupport(underlying)) {
      doTransferOut(payable(timelock), amount);
      ITimelock.TimeLockActionType actionType = isBorrow
        ? ITimelock.TimeLockActionType.BORROW
        : ITimelock.TimeLockActionType.REDEEM;
      ITimelock(timelock).createAgreement(actionType, underlying, amount, to);
    } else {
      doTransferOut(payable(to), amount);
    }
  }
    function accrueInterest() public virtual override returns (uint256) {
    /* Remember the initial block number */
    uint256 currentBlockNumber = getBlockNumber();
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == currentBlockNumber) {
      return uint256(Error.NO_ERROR);
    }

    /* Read the previous values out of storage */
    uint256 cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    uint256 reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    uint256 borrowRateMantissa = IInterestRateModel(interestRateModel).getBorrowRate(
      cashPrior,
      borrowsPrior,
      reservesPrior
    );
    if (3 > BORROW_RATE_MAX_MANTISSA) {
      // Error.TOKEN_ERROR.failOpaque(FailureInfo.BORROW_RATE_ABSURDLY_HIGH, borrowRateMantissa);
      borrowRateMantissa = BORROW_RATE_MAX_MANTISSA;
    }

    /* Calculate the number of blocks elapsed since the last accrual */
    (MathError mathErr, uint256 blockDelta) = currentBlockNumber.subUInt(accrualBlockNumberPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.COULD_NOT_CACULATE_BLOCK_DELTA);
    }

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    Exp memory simpleInterestFactor;
    uint256 interestAccumulated;
    uint256 totalBorrowsNew;
    uint256 totalReservesNew;
    uint256 borrowIndexNew;

    (mathErr, simpleInterestFactor) = Exp({mantissa: borrowRateMantissa}).mulScalar(blockDelta);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        uint256(mathErr)
      );
    }

    (mathErr, interestAccumulated) = simpleInterestFactor.mulScalarTruncate(borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        uint256(mathErr)
      );
    }

    (mathErr, totalBorrowsNew) = interestAccumulated.addUInt(borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint256(mathErr));
    }

    (mathErr, totalReservesNew) = Exp({mantissa: reserveFactorMantissa}).mulScalarTruncateAddUInt(
      interestAccumulated,
      reservesPrior
    );
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint256(mathErr));
    }

    (mathErr, borrowIndexNew) = simpleInterestFactor.mulScalarTruncateAddUInt(borrowIndexPrior, borrowIndexPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint256(mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return uint256(Error.NO_ERROR);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './CToken.sol';
import './Interfaces/ICErc20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../ITimelock.sol';

/**
 * @title Compound's CEther Contract
 * @notice CToken which wraps Ether
 * @author Compound
 */
contract CEther is CToken, Initializable {
  using CarefulMath for uint256;

  /**
   * @notice Construct a new CEther money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  function initialize(
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_
  ) public initializer {
    super.initialize(
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      true,
      admin_,
      discountRateMantissa_
    );

    isCEther = true;
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Reverts upon any failure
   */
  function mint() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, 'mint failed');
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @dev Reverts upon any failure
   */
  function repayBorrow() external payable {
    (uint256 err, ) = repayBorrowInternal(msg.value);
    requireNoError(err, 'repayBorrow failed');
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @dev Reverts upon any failure
   * @param borrower the account with the debt being paid off
   */
  function repayBorrowBehalf(address borrower) external payable {
    uint256 received = msg.value;
    uint256 borrows = CEther(payable(this)).borrowBalanceCurrent(borrower);
    if (received > borrows) {
      // payable(msg.sender).transfer(received - borrows);
      (bool success, ) = msg.sender.call{value: received - borrows}('');
      require(success, 'Address: unable to send value, recipient may have reverted');
    }
    (uint256 err, ) = repayBorrowBehalfInternal(borrower, borrows);
    requireNoError(err, 'repayBorrowBehalf failed');
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @dev Reverts upon any failure
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   */
  function liquidateBorrow(address borrower, address cTokenCollateral) external payable {
    (uint256 err, ) = liquidateBorrowInternal(borrower, msg.value, cTokenCollateral);
    requireNoError(err, 'liquidateBorrow failed');
  }

  /**
   * @notice The sender adds to reserves.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves() external payable returns (uint256) {
    return _addReservesInternal(msg.value);
  }

  /**
   * @notice Send Ether to CEther to mint
   */
  receive() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, 'mint failed');
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of Ether, before this message
   * @dev This excludes the value of the current message, if any
   * @return The quantity of Ether owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    (MathError err, uint256 startingBalance) = address(this).balance.subUInt(msg.value);
    require(err == MathError.NO_ERROR);
    return startingBalance;
  }

  /**
   * @notice Perform the actual transfer in, which is a no-op
   * @param from Address sending the Ether
   * @param amount Amount of Ether being sent
   * @return The actual amount of Ether transferred
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    // Sanity checks
    require(msg.sender == from, 'sender mismatch');
    require(msg.value >= amount, 'value mismatch');
    return amount;
  }

  function doTransferOut(address payable to, uint256 amount) internal override {
    /* Send the Ether, with minimal gas and revert on failure */
    // to.transfer(amount);
    (bool success, ) = to.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  function transferToTimelock(bool isBorrow, address to, uint256 amount) internal virtual override {
    address timelock = IComptroller(comptroller).timelock();
    if (ITimelock(timelock).isSupport(underlying)) {
      doTransferOut(payable(timelock), amount);
      ITimelock.TimeLockActionType actionType = isBorrow
        ? ITimelock.TimeLockActionType.BORROW
        : ITimelock.TimeLockActionType.REDEEM;
      ITimelock(timelock).createAgreement(actionType, address(1), amount, to);
    } else {
      doTransferOut(payable(to), amount);
    }
  }

  function requireNoError(uint256 errCode, string memory message) internal pure {
    if (errCode == uint256(Error.NO_ERROR)) {
      return;
    }

    bytes memory fullMessage = new bytes(bytes(message).length + 5);
    uint256 i;

    for (i = 0; i < bytes(message).length; i++) {
      fullMessage[i] = bytes(message)[i];
    }

    fullMessage[i + 0] = bytes1(uint8(32));
    fullMessage[i + 1] = bytes1(uint8(40));
    fullMessage[i + 2] = bytes1(uint8(48 + (errCode / 10)));
    fullMessage[i + 3] = bytes1(uint8(48 + (errCode % 10)));
    fullMessage[i + 4] = bytes1(uint8(41));

    require(errCode == uint256(Error.NO_ERROR), string(fullMessage));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../Comptroller/Interfaces/IComptroller.sol';
import '../Comptroller/Interfaces/IPriceOracle.sol';
import './Interfaces/IInterestRateModel.sol';
import './TokenErrorReporter.sol';
import './CTokenStorage.sol';
import '../Exponential/Exponential.sol';

uint256 constant expScale = 1e18;

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
abstract contract CToken is CTokenStorage {
  using Exponential for uint256;
  using Exponential for Exp;
  using ExponentialNoError for uint256;
  using ExponentialNoError for Exp;
  using CarefulMath for uint256;
  using TokenErrorReporter for Error;

  modifier onlyAdmin() {
    // Check caller is admin
    require(msg.sender == admin, 'UNAUTHORIZED');
    _;
  }

  /**
   * @notice Initialize the money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ EIP-20 name of this token
   * @param symbol_ EIP-20 symbol of this token
   * @param decimals_ EIP-20 decimal precision of this token
   */
  function initialize(
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    bool isCToken_,
    address payable _admin,
    uint256 discountRateMantissa_
  ) internal {
    admin = _admin;
    require(accrualBlockNumber == 0 && borrowIndex == 0, 'MMOB'); // market may only be initialized once

    isCToken = isCToken_;

    // Set initial exchange rate
    initialExchangeRateMantissa = initialExchangeRateMantissa_;
    require(initialExchangeRateMantissa > 0, 'IERM'); // initial exchange rate must be greater than zero

    discountRateMantissa = discountRateMantissa_;
    require(discountRateMantissa > 0 && discountRateMantissa <= 1e18, 'RMI'); // rate must in [0,100]

    // Set the comptroller
    // Set market's comptroller to newComptroller
    comptroller = comptroller_;

    // Emit NewComptroller(oldComptroller, newComptroller)
    emit NewComptroller(address(0), comptroller_);

    // Initialize block number and borrow index (block number mocks depend on comptroller being set)
    accrualBlockNumber = getBlockNumber();
    borrowIndex = 1e18;

    // Set the interest rate model (depends on block number / borrow index)
    interestRateModel = interestRateModel_;
    emit NewMarketInterestRateModel(address(0), interestRateModel_);

    name = name_;
    symbol = symbol_;
    decimals = decimals_;

    // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
    _notEntered = true;
  }

  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferTokens(address spender, address src, address dst, uint256 tokens) internal returns (uint256) {
    /* Fail if transfer not allowed */
    uint256 allowed = IComptroller(comptroller).transferAllowed(address(this), src, dst, tokens);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
    }

    /* Do not allow self-transfers */
    if (src == dst) {
      Error.BAD_INPUT.fail(FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = 0;
    if (spender == src) {
      startingAllowance = uint256(0);
    } else {
      startingAllowance = transferAllowances[src][spender];
    }

    /* Do the calculations, checking for {under,over}flow */
    MathError mathErr;
    uint256 allowanceNew;
    uint256 srcTokensNew;
    uint256 dstTokensNew;

    (mathErr, allowanceNew) = startingAllowance.subUInt(tokens);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    (mathErr, srcTokensNew) = accountTokens[src].subUInt(tokens);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.TRANSFER_NOT_ENOUGH);
    }

    (mathErr, dstTokensNew) = accountTokens[dst].addUInt(tokens);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.TRANSFER_TOO_MUCH);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srcTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != uint256(0)) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    // unused function
    // comptroller.transferVerify(address(this), src, dst, tokens);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, msg.sender, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(address src, address dst, uint256 amount) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, src, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    address src = msg.sender;
    transferAllowances[src][spender] = amount;
    emit Approval(src, spender, amount);
    return true;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view override returns (uint256) {
    return accountTokens[owner];
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external override returns (uint256) {
    Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
    (MathError mErr, uint256 balance) = exchangeRate.mulScalarTruncate(accountTokens[owner]);
    if (mErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.BALANCE_COULD_NOT_BE_CALCULATED);
    }
    return balance;
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address account) external view override returns (uint256, uint256, uint256, uint256) {
    uint256 cTokenBalance = accountTokens[account];
    uint256 borrowBalance;
    uint256 exchangeRateMantissa;

    MathError mErr;

    (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
    if (mErr != MathError.NO_ERROR) {
      return (uint256(Error.MATH_ERROR), 0, 0, 0);
    }

    (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
    if (mErr != MathError.NO_ERROR) {
      return (uint256(Error.MATH_ERROR), 0, 0, 0);
    }

    return (uint256(Error.NO_ERROR), cTokenBalance, borrowBalance, exchangeRateMantissa);
  }

  /**
   * @dev Function to simply retrieve block number
   *  This exists mainly for inheriting test contracts to stub this result.
   */
  function getBlockNumber() internal view returns (uint256) {
    return block.number;
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view override returns (uint256) {
    return IInterestRateModel(interestRateModel).getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view override returns (uint256) {
    return
      IInterestRateModel(interestRateModel).getSupplyRate(
        getCashPrior(),
        totalBorrows,
        totalReserves,
        reserveFactorMantissa
      );
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
    accrueInterest();
    return totalBorrows;
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
    accrueInterest();
    return borrowBalanceStored(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view override returns (uint256) {
    (MathError err, uint256 result) = borrowBalanceStoredInternal(account);
    if (err != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.BORROW_BALANCE_STORED_INTERNAL_FAILED);
    }
    return result;
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return (error code, the calculated balance or 0 if error code is non-zero)
   */
  function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint256) {
    /* Note: we do not assert that the market is up to date */
    MathError mathErr;
    uint256 principalTimesIndex;
    uint256 result;

    /* Get borrowBalance and borrowIndex */
    BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

    /* If borrowBalance = 0 then borrowIndex is likely also 0.
     * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
     */
    if (borrowSnapshot.principal == 0) {
      return (MathError.NO_ERROR, 0);
    }

    /* Calculate new borrow balance using the interest index:
     *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
     */
    (mathErr, principalTimesIndex) = borrowSnapshot.principal.mulUInt(borrowIndex);
    if (mathErr != MathError.NO_ERROR) {
      return (mathErr, 0);
    }

    (mathErr, result) = principalTimesIndex.divUInt(borrowSnapshot.interestIndex);
    if (mathErr != MathError.NO_ERROR) {
      return (mathErr, 0);
    }

    return (MathError.NO_ERROR, result);
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public override nonReentrant returns (uint256) {
    accrueInterest();
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view override returns (uint256) {
    (MathError err, uint256 result) = exchangeRateStoredInternal();
    if (err != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.EXCHANGE_RATE_STORED_INTERNAL_FAILED);
    }
    return result;
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (error code, calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStoredInternal() internal view returns (MathError, uint256) {
    if (!isCToken) {
      return (MathError.NO_ERROR, initialExchangeRateMantissa);
    }

    uint256 _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return (MathError.NO_ERROR, initialExchangeRateMantissa);
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       */
      uint256 totalCash = getCashPrior();
      uint256 cashPlusBorrowsMinusReserves;
      Exp memory exchangeRate;
      MathError mathErr;

      (mathErr, cashPlusBorrowsMinusReserves) = totalCash.addThenSubUInt(totalBorrows, totalReserves);
      if (mathErr != MathError.NO_ERROR) {
        return (mathErr, 0);
      }

      (mathErr, exchangeRate) = cashPlusBorrowsMinusReserves.getExp(_totalSupply);
      if (mathErr != MathError.NO_ERROR) {
        return (mathErr, 0);
      }

      return (MathError.NO_ERROR, exchangeRate.mantissa);
    }
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return getCashPrior();
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *   up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public virtual override returns (uint256) {
    /* Remember the initial block number */
    uint256 currentBlockNumber = getBlockNumber();
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == currentBlockNumber) {
      return uint256(Error.NO_ERROR);
    }

    /* Read the previous values out of storage */
    uint256 cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    uint256 reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    uint256 borrowRateMantissa = IInterestRateModel(interestRateModel).getBorrowRate(
      cashPrior,
      borrowsPrior,
      reservesPrior
    );
    if (borrowRateMantissa > BORROW_RATE_MAX_MANTISSA) {
      // Error.TOKEN_ERROR.failOpaque(FailureInfo.BORROW_RATE_ABSURDLY_HIGH, borrowRateMantissa);
      borrowRateMantissa = BORROW_RATE_MAX_MANTISSA;
    }

    /* Calculate the number of blocks elapsed since the last accrual */
    (MathError mathErr, uint256 blockDelta) = currentBlockNumber.subUInt(accrualBlockNumberPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.COULD_NOT_CACULATE_BLOCK_DELTA);
    }

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    Exp memory simpleInterestFactor;
    uint256 interestAccumulated;
    uint256 totalBorrowsNew;
    uint256 totalReservesNew;
    uint256 borrowIndexNew;

    (mathErr, simpleInterestFactor) = Exp({mantissa: borrowRateMantissa}).mulScalar(blockDelta);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        uint256(mathErr)
      );
    }

    (mathErr, interestAccumulated) = simpleInterestFactor.mulScalarTruncate(borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        uint256(mathErr)
      );
    }

    (mathErr, totalBorrowsNew) = interestAccumulated.addUInt(borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint256(mathErr));
    }

    (mathErr, totalReservesNew) = Exp({mantissa: reserveFactorMantissa}).mulScalarTruncateAddUInt(
      interestAccumulated,
      reservesPrior
    );
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint256(mathErr));
    }

    (mathErr, borrowIndexNew) = simpleInterestFactor.mulScalarTruncateAddUInt(borrowIndexPrior, borrowIndexPrior);
    if (mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint256(mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintInternal(uint256 mintAmount) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
    return mintFresh(msg.sender, mintAmount);
  }

  struct MintLocalVars {
    Error err;
    MathError mathErr;
    uint256 exchangeRateMantissa;
    uint256 mintTokens;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
    uint256 actualMintAmount;
  }

  /**
   * @notice User supplies assets into the market and receives cTokens in exchange
   * @dev Assumes interest has already been accrued up to the current block
   * @param minter The address of the account which is supplying the assets
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintFresh(address minter, uint256 mintAmount) internal returns (uint256, uint256) {
    /* Fail if mint not allowed */
    uint256 allowed = IComptroller(comptroller).mintAllowed(address(this), minter, mintAmount);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.MINT_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.MINT_FRESHNESS_CHECK);
    }

    MintLocalVars memory vars;

    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     *  We call `doTransferIn` for the minter and the mintAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
     *  side-effects occurred. The function returns the amount actually transferred,
     *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
     *  of cash.
     */
    vars.actualMintAmount = doTransferIn(minter, mintAmount);

    /*
     * We get the current exchange rate and calculate the number of cTokens to be minted:
     *  mintTokens = actualMintAmount / exchangeRate
     */

    (vars.mathErr, vars.mintTokens) = vars.actualMintAmount.divScalarByExpTruncate(
      Exp({mantissa: vars.exchangeRateMantissa})
    );
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.MINT_EXCHANGE_CALCULATION_FAILED);
    }

    /*
     * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
     *  totalSupplyNew = totalSupply + mintTokens
     *  accountTokensNew = accountTokens[minter] + mintTokens
     */
    (vars.mathErr, vars.totalSupplyNew) = totalSupply.addUInt(vars.mintTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
    }

    (vars.mathErr, vars.accountTokensNew) = accountTokens[minter].addUInt(vars.mintTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED);
    }

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[minter] = vars.accountTokensNew;

    /* We emit a Mint event, and a Transfer event */
    emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
    emit Transfer(address(this), minter, vars.mintTokens);

    /* We call the defense hook */
    // unused function
    // comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

    return (uint256(Error.NO_ERROR), vars.actualMintAmount);
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemInternal(uint256 redeemTokens) internal nonReentrant returns (uint256) {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(payable(msg.sender), redeemTokens, 0);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to receive from redeeming cTokens
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlyingInternal(uint256 redeemAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(payable(msg.sender), 0, redeemAmount);
  }

  struct RedeemLocalVars {
    Error err;
    MathError mathErr;
    uint256 exchangeRateMantissa;
    uint256 redeemTokens;
    uint256 redeemAmount;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
  }

  /**
   * @notice User redeems cTokens in exchange for the underlying asset
   * @dev Assumes interest has already been accrued up to the current block
   * @param redeemer The address of the account which is redeeming the tokens
   * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemFresh(
    address payable redeemer,
    uint256 redeemTokensIn,
    uint256 redeemAmountIn
  ) internal returns (uint256) {
    if (redeemTokensIn != 0 && redeemAmountIn != 0) {
      Error.BAD_INPUT.fail(FailureInfo.ONE_OF_REDEEM_TOKENS_IN_OR_REDEEM_AMOUNT_IN_MUST_BE_ZERO);
    }
    RedeemLocalVars memory vars;

    /* exchangeRate = invoke Exchange Rate Stored() */
    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
    }

    /* If redeemTokensIn > 0: */
    if (redeemTokensIn > 0) {
      /*
       * We calculate the exchange rate and the amount of underlying to be redeemed:
       *  redeemTokens = redeemTokensIn
       *  redeemAmount = redeemTokensIn x exchangeRateCurrent
       */
      vars.redeemTokens = redeemTokensIn;

      (vars.mathErr, vars.redeemAmount) = Exp({mantissa: vars.exchangeRateMantissa}).mulScalarTruncate(redeemTokensIn);
      if (vars.mathErr != MathError.NO_ERROR) {
        Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint256(vars.mathErr));
      }
    } else {
      /*
       * We get the current exchange rate and calculate the amount to be redeemed:
       *  redeemTokens = redeemAmountIn / exchangeRate
       *  redeemAmount = redeemAmountIn
       */

      (vars.mathErr, vars.redeemTokens) = redeemAmountIn.divScalarByExpTruncate(
        Exp({mantissa: vars.exchangeRateMantissa})
      );
      if (vars.mathErr != MathError.NO_ERROR) {
        Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint256(vars.mathErr));
      }

      vars.redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    uint256 allowed = IComptroller(comptroller).redeemAllowed(address(this), redeemer, vars.redeemTokens);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.REDEEM_FRESHNESS_CHECK);
    }

    /*
     * We calculate the new total supply and redeemer balance, checking for underflow:
     *  totalSupplyNew = totalSupply - redeemTokens
     *  accountTokensNew = accountTokens[redeemer] - redeemTokens
     */
    (vars.mathErr, vars.totalSupplyNew) = totalSupply.subUInt(vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    (vars.mathErr, vars.accountTokensNew) = accountTokens[redeemer].subUInt(vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (isCToken && (getCashPrior() < vars.redeemAmount)) {
      Error.TOKEN_INSUFFICIENT_CASH.fail(FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[redeemer] = vars.accountTokensNew;

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    // doTransferOut(redeemer, vars.redeemAmount);
    transferToTimelock(false, redeemer, vars.redeemAmount);

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), vars.redeemTokens);
    emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

    /* We call the defense hook */
    IComptroller(comptroller).redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

    return uint256(Error.NO_ERROR);
  }

  function redeemAndTransferFresh(address payable redeemer, uint256 redeemTokensIn) internal returns (uint256) {
    if (redeemTokensIn == 0) {
      Error.BAD_INPUT.fail(FailureInfo.ONE_OF_REDEEM_TOKENS_IN_OR_REDEEM_AMOUNT_IN_MUST_BE_ZERO);
    }
    RedeemLocalVars memory vars;

    /* exchangeRate = invoke Exchange Rate Stored() */
    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
    }
    /*
     * We calculate the exchange rate and the amount of underlying to be redeemed:
     *  redeemTokens = redeemTokensIn
     *  redeemAmount = redeemTokensIn x exchangeRateCurrent
     */
    vars.redeemTokens = redeemTokensIn;

    (vars.mathErr, vars.redeemAmount) = Exp({mantissa: vars.exchangeRateMantissa}).mulScalarTruncate(redeemTokensIn);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /* Fail if redeem not allowed */
    uint256 allowed = IComptroller(comptroller).redeemAllowed(address(this), redeemer, vars.redeemTokens);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.REDEEM_FRESHNESS_CHECK);
    }

    /*
     * We calculate the new total supply and redeemer balance, checking for underflow:
     *  totalSupplyNew = totalSupply - redeemTokens
     *  accountTokensNew = accountTokens[redeemer] - redeemTokens
     */
    (vars.mathErr, vars.totalSupplyNew) = totalSupply.subUInt(vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    (vars.mathErr, vars.accountTokensNew) = accountTokens[redeemer].subUInt(vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (isCToken && (getCashPrior() < vars.redeemAmount)) {
      Error.TOKEN_INSUFFICIENT_CASH.fail(FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[redeemer] = vars.accountTokensNew;

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(redeemer, vars.redeemAmount);

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), vars.redeemTokens);
    emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

    /* We call the defense hook */
    IComptroller(comptroller).redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowInternal(uint256 borrowAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // borrowFresh emits borrow-specific logs on errors, so we don't need to
    return borrowFresh(payable(msg.sender), borrowAmount);
  }

  struct BorrowLocalVars {
    MathError mathErr;
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
  }

  /**
   * @notice Users borrow assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowFresh(address payable borrower, uint256 borrowAmount) internal returns (uint256) {
    /* Fail if borrow not allowed */
    uint256 allowed = IComptroller(comptroller).borrowAllowed(address(this), borrower, borrowAmount);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.BORROW_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.BORROW_FRESHNESS_CHECK);
    }

    /* Fail gracefully if protocol has insufficient underlying cash */
    if (isCToken && (getCashPrior() < borrowAmount)) {
      Error.TOKEN_INSUFFICIENT_CASH.fail(FailureInfo.BORROW_CASH_NOT_AVAILABLE);
    }

    BorrowLocalVars memory vars;

    /*
     * We calculate the new borrower and total borrow balances, failing on overflow:
     *  accountBorrowsNew = accountBorrows + borrowAmount
     *  totalBorrowsNew = totalBorrows + borrowAmount
     */
    (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    (vars.mathErr, vars.accountBorrowsNew) = vars.accountBorrows.addUInt(borrowAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        uint256(vars.mathErr)
      );
    }

    (vars.mathErr, vars.totalBorrowsNew) = totalBorrows.addUInt(borrowAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;

    /*
     * We invoke doTransferOut for the borrower and the borrowAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken borrowAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    // doTransferOut(borrower, borrowAmount);
    transferToTimelock(true, borrower, borrowAmount);

    /* We emit a Borrow event */
    emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

    /* We call the defense hook */
    // unused function
    // comptroller.borrowVerify(address(this), borrower, borrowAmount);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowInternal(uint256 repayAmount) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being paid off
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowBehalfInternal(
    address borrower,
    uint256 repayAmount
  ) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, borrower, repayAmount);
  }

  struct RepayBorrowLocalVars {
    Error err;
    MathError mathErr;
    uint256 repayAmount;
    uint256 borrowerIndex;
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
    uint256 actualRepayAmount;
  }

  /**
   * @notice Borrows are repaid by another user (possibly the borrower).
   * @param payer the account paying off the borrow
   * @param borrower the account with the debt being paid off
   * @param repayAmount the amount of underlying tokens being returned
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowFresh(address payer, address borrower, uint256 repayAmount) internal returns (uint256, uint256) {
    /* Fail if repayBorrow not allowed */
    uint256 allowed = IComptroller(comptroller).repayBorrowAllowed(address(this), payer, borrower, repayAmount);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.REPAY_BORROW_FRESHNESS_CHECK);
    }

    RepayBorrowLocalVars memory vars;

    /* We remember the original borrowerIndex for verification purposes */
    vars.borrowerIndex = accountBorrows[borrower].interestIndex;

    /* We fetch the amount the borrower owes, with accumulated interest */
    (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(
        FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        uint256(vars.mathErr)
      );
    }

    /* If repayAmount == -1, repayAmount = accountBorrows */
    if (repayAmount == ~uint256(0)) {
      vars.repayAmount = vars.accountBorrows;
    } else {
      vars.repayAmount = repayAmount;
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the payer and the repayAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional repayAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *   it returns the amount actually transferred, in case of a fee.
     */
    vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

    /*
     * We calculate the new borrower and total borrow balances, failing on underflow:
     *  accountBorrowsNew = accountBorrows - actualRepayAmount
     *  totalBorrowsNew = totalBorrows - actualRepayAmount
     */
    (vars.mathErr, vars.accountBorrowsNew) = vars.accountBorrows.subUInt(vars.actualRepayAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED);
    }

    (vars.mathErr, vars.totalBorrowsNew) = totalBorrows.subUInt(vars.actualRepayAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.fail(FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
    }

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;

    /* We emit a RepayBorrow event */
    emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

    /* We call the defense hook */
    // unused function
    // comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

    return (uint256(Error.NO_ERROR), vars.actualRepayAmount);
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowInternal(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    ICToken(cTokenCollateral).accrueInterest();

    // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
    return liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
  }

  /**
   * @notice The liquidator liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param liquidator The address repaying the borrow and seizing collateral
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowFresh(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) internal returns (uint256, uint256) {
    /* Fail if liquidate not allowed */
    uint256 allowed = liquidateBorrowAllowed(address(cTokenCollateral), liquidator, borrower, repayAmount);
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.LIQUIDATE_FRESHNESS_CHECK);
    }

    /* Verify cTokenCollateral market's block number equals current block number */
    if (ICToken(cTokenCollateral).accrualBlockNumber() != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK);
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      Error.INVALID_ACCOUNT_PAIR.fail(FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER);
    }

    /* Fail if repayAmount = 0 */
    if (repayAmount == 0) {
      Error.INVALID_CLOSE_AMOUNT_REQUESTED.fail(FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO);
    }

    if (repayAmount == ~uint256(0)) {
      Error.INVALID_CLOSE_AMOUNT_REQUESTED.fail(FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX);
    }

    /* Fail if repayBorrow fails */
    (, uint256 actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    (, uint8 repayTokenGroupId, ) = IComptroller(comptroller).markets(address(this));
    (, uint8 seizeTokenGroupId, ) = IComptroller(comptroller).markets(cTokenCollateral);

    (
      uint256 heteroLiquidationIncentive,
      uint256 homoLiquidationIncentive,
      uint256 sutokenLiquidationIncentive
    ) = IComptroller(comptroller).liquidationIncentiveMantissa();

    // default is repaying heterogeneous assets
    uint256 incentiveMantissa = heteroLiquidationIncentive;
    if (repayTokenGroupId == seizeTokenGroupId) {
      if (CToken(address(this)).isCToken() == false) {
        // repaying sutoken
        incentiveMantissa = sutokenLiquidationIncentive;
      } else {
        // repaying homogeneous assets
        incentiveMantissa = homoLiquidationIncentive;
      }
    }

    /* We calculate the number of collateral tokens that will be seized */
    (, uint256 seizeTokens) = liquidateCalculateSeizeTokens(cTokenCollateral, actualRepayAmount, incentiveMantissa);

    /* Revert if borrower collateral token balance < seizeTokens */
    if (ICToken(cTokenCollateral).balanceOf(borrower) < seizeTokens) {
      Error.TOKEN_ERROR.fail(FailureInfo.LIQUIDATE_SEIZE_TOO_MUCH);
    }

    // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
    if (cTokenCollateral == address(this)) {
      seizeInternal(address(this), liquidator, borrower, seizeTokens);
    } else {
      ICToken(cTokenCollateral).seize(liquidator, borrower, seizeTokens);
    }

    /* We emit a LiquidateBorrow event */
    emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);

    /* We call the defense hook */
    // unused function
    // comptroller.liquidateBorrowVerify(address(this), address(cTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

    return (uint256(Error.NO_ERROR), actualRepayAmount);
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external override nonReentrant returns (uint256) {
    return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
  }

  struct SeizeInternalLocalVars {
    MathError mathErr;
    uint256 borrowerTokensNew;
    uint256 liquidatorTokensNew;
    uint256 liquidatorSeizeTokens;
    uint256 protocolSeizeTokens;
    uint256 protocolSeizeAmount;
    uint256 exchangeRateMantissa;
    uint256 totalReservesNew;
    uint256 totalSupplyNew;
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
   *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
   * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seizeInternal(
    address seizerToken,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) internal returns (uint256) {
    /* Fail if seize not allowed */
    uint256 allowed = IComptroller(comptroller).seizeAllowed(
      address(this),
      seizerToken,
      liquidator,
      borrower,
      seizeTokens
    );
    if (allowed != 0) {
      Error.COMPTROLLER_REJECTION.failOpaque(FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      Error.INVALID_ACCOUNT_PAIR.fail(FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
    }

    SeizeInternalLocalVars memory vars;

    /*
     * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
     *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
     *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     */
    (vars.mathErr, vars.borrowerTokensNew) = accountTokens[borrower].subUInt(seizeTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint256(vars.mathErr));
    }

    vars.protocolSeizeTokens = seizeTokens.mul_(Exp({mantissa: protocolSeizeShareMantissa}));
    vars.liquidatorSeizeTokens = seizeTokens.sub_(vars.protocolSeizeTokens);

    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
    }

    vars.protocolSeizeAmount = Exp({mantissa: vars.exchangeRateMantissa}).mul_ScalarTruncate(vars.protocolSeizeTokens);

    vars.totalReservesNew = totalReserves.add_(vars.protocolSeizeAmount);
    vars.totalSupplyNew = totalSupply.sub_(vars.protocolSeizeTokens);

    (vars.mathErr, vars.liquidatorTokensNew) = accountTokens[liquidator].addUInt(vars.liquidatorSeizeTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      Error.MATH_ERROR.failOpaque(FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint256(vars.mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    totalReserves = vars.totalReservesNew;
    totalSupply = vars.totalSupplyNew;
    accountTokens[borrower] = vars.borrowerTokensNew;
    accountTokens[liquidator] = vars.liquidatorTokensNew;

    /* Emit a Transfer event */
    emit Transfer(borrower, liquidator, vars.liquidatorSeizeTokens);
    emit Transfer(borrower, address(this), vars.protocolSeizeTokens);
    emit ReservesAdded(address(this), vars.protocolSeizeAmount, vars.totalReservesNew);

    /* We call the defense hook */
    // unused function
    // comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

    redeemAndTransferFresh(payable(liquidator), vars.liquidatorSeizeTokens);

    return uint256(Error.NO_ERROR);
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address payable newPendingAdmin) external override onlyAdmin returns (uint256) {
    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    require(newPendingAdmin != address(0), 'AIZ'); // Address is Zero
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external override returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      Error.UNAUTHORIZED.fail(FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = payable(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets a new comptroller for the market
   * @dev Admin function to set a new comptroller
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setComptroller(address newComptroller) public override onlyAdmin returns (uint256) {
    address oldComptroller = comptroller;
    // Ensure invoke comptroller.isComptroller() returns true
    require(IComptroller(newComptroller).isComptroller(), 'MMRF'); // market method returned false

    // Set market's comptroller to newComptroller
    comptroller = newComptroller;

    // Emit NewComptroller(oldComptroller, newComptroller)
    emit NewComptroller(oldComptroller, newComptroller);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
    return _setReserveFactorFresh(newReserveFactorMantissa);
  }

  /**
   * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
   * @dev Admin function to set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactorFresh(uint256 newReserveFactorMantissa) internal onlyAdmin returns (uint256) {
    // Verify market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
    }

    // Check newReserveFactor ≤ maxReserveFactor
    if (newReserveFactorMantissa > RESERVE_FACTOR_MAX_MANTISSA) {
      Error.BAD_INPUT.fail(FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
    }

    uint256 oldReserveFactorMantissa = reserveFactorMantissa;
    reserveFactorMantissa = newReserveFactorMantissa;

    emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring from msg.sender
   * @param addAmount Amount of addition to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReservesInternal(uint256 addAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
    (uint256 error, ) = _addReservesFresh(addAmount);
    return error;
  }

  /**
   * @notice Add reserves by transferring from caller
   * @dev Requires fresh interest accrual
   * @param addAmount Amount of addition to reserves
   * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
   */
  function _addReservesFresh(uint256 addAmount) internal returns (uint256, uint256) {
    // totalReserves + actualAddAmount
    uint256 totalReservesNew;
    uint256 actualAddAmount;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.ADD_RESERVES_FRESH_CHECK);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the caller and the addAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional addAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *  it returns the amount actually transferred, in case of a fee.
     */

    actualAddAmount = doTransferIn(msg.sender, addAmount);

    totalReservesNew = totalReserves + actualAddAmount;

    /* Revert on overflow */
    if (totalReservesNew < totalReserves) {
      Error.MATH_ERROR.fail(FailureInfo.ADD_RESERVES_UNEXPECTED_OVERFLOW);
    }

    // Store reserves[n+1] = reserves[n] + actualAddAmount
    totalReserves = totalReservesNew;

    /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
    emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

    /* Return (NO_ERROR, actualAddAmount) */
    return (uint256(Error.NO_ERROR), actualAddAmount);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
    return _reduceReservesFresh(reduceAmount);
  }

  /**
   * @notice Reduces reserves by transferring to admin
   * @dev Requires fresh interest accrual
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReservesFresh(uint256 reduceAmount) internal onlyAdmin returns (uint256) {
    // totalReserves - reduceAmount
    uint256 totalReservesNew;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
    }

    // Fail gracefully if protocol has insufficient underlying cash
    if (getCashPrior() < reduceAmount) {
      Error.TOKEN_INSUFFICIENT_CASH.fail(FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
    }

    // Check reduceAmount ≤ reserves[n] (totalReserves)
    if (reduceAmount > totalReserves) {
      Error.BAD_INPUT.fail(FailureInfo.REDUCE_RESERVES_VALIDATION);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    totalReservesNew = totalReserves - reduceAmount;
    // We checked reduceAmount <= totalReserves above, so this should never revert.
    if (totalReservesNew < totalReserves) {
      Error.MATH_ERROR.fail(FailureInfo.ADD_RESERVES_UNEXPECTED_OVERFLOW);
    }

    // Store reserves[n+1] = reserves[n] - reduceAmount
    totalReserves = totalReservesNew;

    // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
    doTransferOut(admin, reduceAmount);

    emit ReservesReduced(admin, reduceAmount, totalReservesNew);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(address newInterestRateModel) public override returns (uint256) {
    accrueInterest();
    // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
    return _setInterestRateModelFresh(newInterestRateModel);
  }

  /**
   * @notice updates the interest rate model (*requires fresh interest accrual)
   * @dev Admin function to update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModelFresh(address newInterestRateModel) internal onlyAdmin returns (uint256) {
    // Used to store old model for use in the event that is emitted on success
    address oldInterestRateModel;
    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      Error.MARKET_NOT_FRESH.fail(FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
    }

    // Track the market's current interest rate model
    oldInterestRateModel = interestRateModel;

    // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
    require(IInterestRateModel(interestRateModel).isInterestRateModel(), 'MMRF'); // market method returned false

    // Set the interest rate model to newInterestRateModel
    interestRateModel = newInterestRateModel;

    // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
    emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

    return uint256(Error.NO_ERROR);
  }

  function _syncUnderlyingBalance() external onlyAdmin {
    underlyingBalance = ICToken(underlying).balanceOf(address(this));
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying owned by this contract
   */
  function getCashPrior() internal view virtual returns (uint256);

  /**
   * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
   *  This may revert due to insufficient balance or insufficient allowance.
   */
  function doTransferIn(address from, uint256 amount) internal virtual returns (uint256);

  /**
   * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
   *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
   *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual;

  function transferToTimelock(bool isBorrow, address to, uint256 amount) internal virtual;

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, 'RE'); // re-entered
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }

  /**
   * @notice Returns true if the given cToken market has been deprecated
   * @dev All borrows in a deprecated cToken market can be immediately liquidated
   */
  function isDeprecated() public view returns (bool) {
    return
      IComptroller(comptroller).marketGroupId(address(this)) == 0 &&
      //borrowGuardianPaused[cToken] == true &&
      IComptroller(comptroller)._getBorrowPaused(address(this)) &&
      reserveFactorMantissa == 1e18;
  }

  /**
   * @notice Checks if the liquidation should be allowed to occur
   * @param cTokenCollateral Asset which was used as collateral and will be seized
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param repayAmount The amount of underlying being repaid
   */
  function liquidateBorrowAllowed(
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) public view returns (uint256) {
    // Shh - currently unused:
    liquidator;
    if (!IComptroller(comptroller).isListed(address(this)) || !IComptroller(comptroller).isListed(cTokenCollateral)) {
      Error.MARKET_NOT_LISTED.fail(FailureInfo.MARKET_NOT_LISTED);
    }

    (, uint256 borrowBalance) = borrowBalanceStoredInternal(borrower);

    /* allow accounts to be liquidated if the market is deprecated */
    if (isDeprecated()) {
      if (borrowBalance < repayAmount) {
        Error.TOKEN_ERROR.fail(FailureInfo.TOO_MUCH_REPAY);
      }
    } else {
      /* The borrower must have shortfall in order to be liquidatable */
      (, , uint256 shortfall) = IComptroller(comptroller).getHypotheticalAccountLiquidity(
        borrower,
        address(this),
        0,
        0
      );

      if (shortfall <= 0) {
        Error.TOKEN_ERROR.fail(FailureInfo.INSUFFICIENT_SHORTFALL);
      }

      /* The liquidator may not repay more than what is allowed by the closeFactor */
      uint256 maxClose = Exp({mantissa: IComptroller(comptroller).closeFactorMantissa()}).mul_ScalarTruncate(
        borrowBalance
      );
      if (repayAmount > maxClose) {
        Error.TOKEN_ERROR.fail(FailureInfo.TOO_MUCH_REPAY);
      }
    }
    return uint256(0);
  }

  /**
   * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
   * @dev Used in liquidation (called in ICToken(cToken).liquidateBorrowFresh)
   * @param cTokenCollateral The address of the collateral cToken
   * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
   * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
   */
  function liquidateCalculateSeizeTokens(
    address cTokenCollateral,
    uint256 actualRepayAmount,
    uint256 liquidationIncentiveMantissa
  ) public view returns (uint256, uint256) {
    /* Read oracle prices for borrowed and collateral markets */
    address oracle = IComptroller(comptroller).oracle();
    uint256 priceBorrowedMantissa = IPriceOracle(oracle).getUnderlyingPrice(address(address(this)));
    uint256 priceCollateralMantissa = IPriceOracle(oracle).getUnderlyingPrice(address(cTokenCollateral));
    if (priceBorrowedMantissa <= 0 || priceCollateralMantissa <= 0) {
      Error.TOKEN_ERROR.fail(FailureInfo.PRICE_ERROR);
    }
    /*
     * Get the exchange rate and calculate the number of collateral tokens to seize:
     *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     *  seizeTokens = seizeAmount / exchangeRate
     *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     */
    uint256 exchangeRateMantissa = ICToken(cTokenCollateral).exchangeRateStored(); // Note: reverts on error
    uint256 seizeTokenDecimal = CToken(cTokenCollateral).decimals();
    uint256 repayTokenDecimal = CToken(address(this)).decimals();

    uint256 seizeTokens;
    Exp memory numerator;
    Exp memory denominator;
    Exp memory ratio;

    numerator = Exp({mantissa: liquidationIncentiveMantissa + expScale}).mul_(Exp({mantissa: priceBorrowedMantissa}));
    if (repayTokenDecimal < 18) {
      numerator = numerator.mul_(10 ** (18 - repayTokenDecimal));
    }
    denominator = Exp({mantissa: priceCollateralMantissa}).mul_(Exp({mantissa: exchangeRateMantissa}));
    if (seizeTokenDecimal < 18) {
      denominator = denominator.mul_(10 ** (18 - seizeTokenDecimal));
    }

    ratio = numerator.div_(denominator);

    seizeTokens = ratio.mul_ScalarTruncate(actualRepayAmount);

    return (uint256(0), seizeTokens);
  }

  function getAccountBorrows(address account) public view returns (uint256 principal, uint256 interestIndex) {
    BorrowSnapshot memory accountBorrow = accountBorrows[account];
    principal = accountBorrow.principal;
    interestIndex = accountBorrow.interestIndex;
  }

  function getDiscountRate() public view returns (uint256) {
    return discountRateMantissa;
  }

  function _setDiscountRate(uint256 discountRateMantissa_) external returns (uint256) {
    require(msg.sender == admin, 'UNAUTHORIZED');
    uint256 oldDiscountRateMantissa_ = discountRateMantissa;
    discountRateMantissa = discountRateMantissa_;
    emit NewDiscountRate(oldDiscountRateMantissa_, discountRateMantissa_);
    return discountRateMantissa;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './Interfaces/ICToken.sol';

abstract contract CTokenStorage is ICToken {
  bool public isCToken;
  bool public isCEther;
  /// @dev Guard variable for re-entrancy checks
  bool internal _notEntered;

  /// @notice Underlying asset for this CToken
  address public underlying;

  /// @notice EIP-20 token name for this token
  string public name;

  /// @notice EIP-20 token symbol for this token
  string public symbol;

  /// @notice EIP-20 token decimals for this token
  uint8 public decimals;

  /// @dev Maximum borrow rate that can ever be applied (.0005% / block)
  uint256 internal constant BORROW_RATE_MAX_MANTISSA = 0.0005e16;

  /// @dev Maximum fraction of interest that can be set aside for reserves
  uint256 internal constant RESERVE_FACTOR_MAX_MANTISSA = 1e18;

  /// @notice Administrator for this contract
  address payable public admin;

  /// @notice Pending administrator for this contract
  address payable public pendingAdmin;

  /// @notice Contract which oversees inter-cToken operations
  address public comptroller;

  /// @notice Model which tells what the current interest rate should be
  address public interestRateModel;

  /// @dev Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
  uint256 internal initialExchangeRateMantissa;

  /// @notice Fraction of interest currently set aside for reserves
  uint256 public reserveFactorMantissa;

  /// @notice Block number that interest was last accrued at
  uint256 public override accrualBlockNumber;

  /// @notice Accumulator of the total earned interest rate since the opening of the market
  uint256 public borrowIndex;

  /// @notice Total amount of outstanding borrows of the underlying in this market
  uint256 public totalBorrows;

  /// @notice Total amount of reserves of the underlying held in this market
  uint256 public totalReserves;

  /// @notice Total number of tokens in circulation
  uint256 public override totalSupply;

  /// @dev Official record of token balances for each account
  mapping(address => uint256) internal accountTokens;

  /// @dev Approved token transfer amounts on behalf of others
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /// @notice Container for borrow balance information
  /// @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
  /// @member interestIndex Global borrowIndex as of the most recent balance-changing action
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  /// @dev Mapping of account addresses to outstanding borrow balances
  mapping(address => BorrowSnapshot) internal accountBorrows;

  /// @notice Share of seized collateral that is added to reserves
  uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%

  uint256 public discountRateMantissa = 1e18;

  uint256 public underlyingBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICErc20 {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function sweepToken(address token) external;

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICToken {
  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(address oldComptroller, address newComptroller);

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint256 amount);


  event NewDiscountRate(uint256 oldDiscountRateMantissa, uint256 newDiscountRateMantissa);

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function borrowRatePerBlock() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) external view returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function getCash() external view returns (uint256);

  function accrueInterest() external returns (uint256);

  function accrualBlockNumber() external returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

  function _acceptAdmin() external returns (uint256);

  function _setComptroller(address newComptroller) external returns (uint256);

  function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

  function _reduceReserves(uint256 reduceAmount) external returns (uint256);

  function _setInterestRateModel(address newInterestRateModel) external returns (uint256);

  function getDiscountRate() external view returns (uint256);

  function _setDiscountRate(uint256 discountRateMantissa) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return balance The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transfer(address dst, uint256 amount) external;

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external;

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved
   * @return success Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return remaining The number of tokens allowed to be spent
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  /**
   * @dev Creates `amount` new tokens for `to`.
   * See {ERC20-_mint}.
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   * See {ERC20-_burn} and {ERC20-allowance}.
   * Requirements:
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface IInterestRateModel {
  function isInterestRateModel() external view returns (bool);

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './Interfaces/IEIP20NonStandard.sol';
import './CErc20.sol';

/**
 * @title Compound's suErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract suErc20 is CErc20 {
  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view virtual override returns (uint256) {
    // ICToken token = ICToken(underlying);
    // return token.balanceOf(address(this));
    return underlyingBalance;
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    IEIP20NonStandard token = IEIP20NonStandard(underlying);
    token.burnFrom(from, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, 'TOKEN_TRANSFER_IN_FAILED');

    // Calculate the amount that was *actually* transferred
    return amount;
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal override {
    IEIP20NonStandard token = IEIP20NonStandard(underlying);
    token.mint(to, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, 'TOKEN_TRANSFER_OUT_FAILED');
  }

  function changeCtoken() public onlyAdmin {
    isCToken = !isCToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum Error {
    NO_ERROR,
    UNAUTHORIZED,
    BAD_INPUT,
    COMPTROLLER_REJECTION,
    COMPTROLLER_CALCULATION_ERROR,
    INTEREST_RATE_MODEL_ERROR,
    INVALID_ACCOUNT_PAIR,
    INVALID_CLOSE_AMOUNT_REQUESTED,
    INVALID_COLLATERAL_FACTOR,
    MATH_ERROR,
    MARKET_NOT_FRESH,
    MARKET_NOT_LISTED,
    TOKEN_INSUFFICIENT_ALLOWANCE,
    TOKEN_INSUFFICIENT_BALANCE,
    TOKEN_INSUFFICIENT_CASH,
    TOKEN_TRANSFER_IN_FAILED,
    TOKEN_TRANSFER_OUT_FAILED,
    TOKEN_ERROR
}

/*
 * Note: FailureInfo (but not Error) is kept in alphabetical order
 *       This is because FailureInfo grows significantly faster, and
 *       the order of Error has some meaning, while the order of FailureInfo
 *       is entirely arbitrary.
 */
enum FailureInfo {
    ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
    ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
    ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
    ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
    BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
    BORROW_ACCRUE_INTEREST_FAILED,
    BORROW_CASH_NOT_AVAILABLE,
    BORROW_FRESHNESS_CHECK,
    BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
    BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
    BORROW_MARKET_NOT_LISTED,
    BORROW_COMPTROLLER_REJECTION,
    LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
    LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
    LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
    LIQUIDATE_COMPTROLLER_REJECTION,
    LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
    LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
    LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
    LIQUIDATE_FRESHNESS_CHECK,
    LIQUIDATE_LIQUIDATOR_IS_BORROWER,
    LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
    LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
    LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
    LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
    LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
    LIQUIDATE_SEIZE_TOO_MUCH,
    MINT_ACCRUE_INTEREST_FAILED,
    MINT_COMPTROLLER_REJECTION,
    MINT_EXCHANGE_CALCULATION_FAILED,
    MINT_EXCHANGE_RATE_READ_FAILED,
    MINT_FRESHNESS_CHECK,
    MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
    MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
    MINT_TRANSFER_IN_FAILED,
    MINT_TRANSFER_IN_NOT_POSSIBLE,
    REDEEM_ACCRUE_INTEREST_FAILED,
    REDEEM_COMPTROLLER_REJECTION,
    REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
    REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
    REDEEM_EXCHANGE_RATE_READ_FAILED,
    REDEEM_FRESHNESS_CHECK,
    REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
    REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
    REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
    REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
    REDUCE_RESERVES_ADMIN_CHECK,
    REDUCE_RESERVES_CASH_NOT_AVAILABLE,
    REDUCE_RESERVES_FRESH_CHECK,
    REDUCE_RESERVES_VALIDATION,
    REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
    REPAY_BORROW_ACCRUE_INTEREST_FAILED,
    REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_COMPTROLLER_REJECTION,
    REPAY_BORROW_FRESHNESS_CHECK,
    REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
    SET_COLLATERAL_FACTOR_OWNER_CHECK,
    SET_COLLATERAL_FACTOR_VALIDATION,
    SET_COMPTROLLER_OWNER_CHECK,
    SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
    SET_INTEREST_RATE_MODEL_FRESH_CHECK,
    SET_INTEREST_RATE_MODEL_OWNER_CHECK,
    SET_MAX_ASSETS_OWNER_CHECK,
    SET_ORACLE_MARKET_NOT_LISTED,
    SET_PENDING_ADMIN_OWNER_CHECK,
    SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
    SET_RESERVE_FACTOR_ADMIN_CHECK,
    SET_RESERVE_FACTOR_FRESH_CHECK,
    SET_RESERVE_FACTOR_BOUNDS_CHECK,
    TRANSFER_COMPTROLLER_REJECTION,
    TRANSFER_NOT_ALLOWED,
    TRANSFER_NOT_ENOUGH,
    TRANSFER_TOO_MUCH,
    ADD_RESERVES_ACCRUE_INTEREST_FAILED,
    ADD_RESERVES_FRESH_CHECK,
    ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
    BALANCE_COULD_NOT_BE_CALCULATED,
    ACCRUE_INTEREST_FAILED, // accrue interest failed
    BORROW_BALANCE_STORED_INTERNAL_FAILED, // borrowBalanceStored: borrowBalanceStoredInternal failed
    EXCHANGE_RATE_STORED_INTERNAL_FAILED,
    BORROW_RATE_ABSURDLY_HIGH,
    COULD_NOT_CACULATE_BLOCK_DELTA,
    ONE_OF_REDEEM_TOKENS_IN_OR_REDEEM_AMOUNT_IN_MUST_BE_ZERO,
    PRICE_ERROR,
    ADD_RESERVES_UNEXPECTED_OVERFLOW,
    MARKET_NOT_LISTED,
    TOO_MUCH_REPAY,
    INSUFFICIENT_SHORTFALL
}

library TokenErrorReporter {
    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    error TokenError(uint256 errorCode, uint256 infoCode, uint256 detailCode);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal pure returns (uint256) {
        // emit Failure(uint256(err), uint256(info), 0);
        revert TokenError(uint256(err), uint256(info), 0);
        // return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal pure returns (uint256) {
        // emit Failure(uint256(err), uint256(info), opaqueError);
        revert TokenError(uint256(err), uint256(info), opaqueError);
        // return uint256(err);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC20MinterBurnerPauser is ERC20PresetMinterPauser {
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 initialSupply
  ) ERC20PresetMinterPauser(_name, _symbol) {
    _mint(_msgSender(), initialSupply);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Possible error codes that we can return
 */
enum MathError {
  NO_ERROR,
  DIVISION_BY_ZERO,
  INTEGER_OVERFLOW,
  INTEGER_UNDERFLOW
}

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library CarefulMath {
  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint256 c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    uint256 c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (MathError, uint256) {
    (MathError err0, uint256 sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../Exponential/ExponentialNoError.sol';
import './CarefulMath.sol';

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
library Exponential {
  uint256 constant expScale = 1e18;
  uint256 constant halfExpScale = expScale / 2;
  using CarefulMath for uint256;
  using ExponentialNoError for Exp;

  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 scaledNumerator) = num.mulUInt(expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    (MathError err1, uint256 rational) = scaledNumerator.divUInt(denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: rational}));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError error, uint256 result) = a.mantissa.addUInt(b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError error, uint256 result) = a.mantissa.subUInt(b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 scaledMantissa) = a.mantissa.mulUInt(scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, product.truncate());
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return product.truncate().addUInt(addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 descaledMantissa) = a.mantissa.divUInt(scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint256 numerator) = expScale.mulUInt(scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, fraction.truncate());
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 doubleScaledProduct) = a.mantissa.mulUInt(b.mantissa);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint256 doubleScaledProductWithHalfScale) = halfExpScale.addUInt(doubleScaledProduct);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    (MathError err2, uint256 product) = doubleScaledProductWithHalfScale.divUInt(expScale);
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({mantissa: product}));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint256 a, uint256 b) internal pure returns (MathError, Exp memory) {
    return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    return getExp(a.mantissa, b.mantissa);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Exp {
  uint256 mantissa;
}

struct Double {
  uint256 mantissa;
}

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
library ExponentialNoError {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return add_(a, b, 'addition overflow');
  }

  function add_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub_(a, b, 'subtraction underflow');
  }

  function sub_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return mul_(a, b, 'multiplication overflow');
  }

  function mul_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return div_(a, b, 'divide by zero');
  }

  function div_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './InterestRateModel.sol';

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
abstract contract BaseJumpRateModelV2 is InterestRateModel {
  using SafeMath for uint256;

  event NewInterestParams(
    uint256 baseRatePerBlock,
    uint256 multiplierPerBlock,
    uint256 jumpMultiplierPerBlock,
    uint256 kink
  );

  /**
   * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
   */
  address public owner;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public immutable blocksPerYear;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
   */
  constructor(
    uint256 blocksPerYearOnChain,
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_,
    address owner_
  ) {
    owner = owner_;
    blocksPerYear = blocksPerYearOnChain;
    _updateJumpRateModelInternal(
      blocksPerYearOnChain,
      baseRatePerYear,
      multiplierPerYear,
      jumpMultiplierPerYear,
      kink_
    );
  }

  /**
   * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function updateJumpRateModel(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) external virtual {
    require(msg.sender == owner, 'only the owner may call this function.');

    _updateJumpRateModelInternal(blocksPerYear, baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }
    if (reserves > cash && (borrows + cash - reserves > 0)) {
      return 1e18;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRateInternal(uint256 cash, uint256 borrows, uint256 reserves) internal view returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    } else {
      uint256 normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
      uint256 excessUtil = util.sub(kink);
      return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
    }
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view virtual override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }

  /**
   * @notice Internal function to update the parameters of the interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function _updateJumpRateModelInternal(
    uint256 blocksPerYearOnChain,
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) internal {
    baseRatePerBlock = baseRatePerYear.div(blocksPerYearOnChain);
    multiplierPerBlock = multiplierPerYear.div(blocksPerYearOnChain);
    jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYearOnChain);
    kink = kink_;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
abstract contract InterestRateModel {
  /// @notice Indicator that this is an InterestRateModel contract (for inspection)
  bool public constant isInterestRateModel = true;

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external virtual view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external virtual view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './InterestRateModel.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Compound's JumpRateModel Contract
 * @author Compound
 */
contract JumpRateModel is InterestRateModel {
  using SafeMath for uint256;

  event NewInterestParams(
    uint256 baseRatePerBlock,
    uint256 multiplierPerBlock,
    uint256 jumpMultiplierPerBlock,
    uint256 kink
  );

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2102400;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) {
    baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
    multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
    jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
    kink = kink_;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    } else {
      uint256 normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
      uint256 excessUtil = util.sub(kink);
      return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
    }
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './BaseJumpRateModelV2.sol';

/**
 * @title Compound's JumpRateModel Contract V2 for V2 cTokens
 * @author Arr00
 * @notice Supports only for V2 cTokens
 */
contract JumpRateModelV2 is BaseJumpRateModelV2 {
  /**
   * @notice Calculates the current borrow rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view override returns (uint256) {
    return getBorrowRateInternal(cash, borrows, reserves);
  }

  constructor(
    uint256 blocksPerYearOnChain,
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_,
    address owner_
  )
    BaseJumpRateModelV2(blocksPerYearOnChain, baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, owner_)
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './InterestRateModel.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Compound's JumpRateModel Contract
 * @author Compound
 */
contract SuTokenRateModel is InterestRateModel {
  using SafeMath for uint256;

  address public owner;
  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public borrowRate;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public supplyRate;

  modifier onlyOwner() {
    require(msg.sender == owner, 'ONLY OWNER');
    _;
  }

  constructor(uint256 initBorrowRate, uint256 initSupplyRate) {
    borrowRate = initBorrowRate;
    supplyRate = initSupplyRate;
    owner = msg.sender;
  }

  function changeOwner(address owner_) public onlyOwner {
    require(owner_ != address(0), 'Address is Zero!');
    owner = owner_;
  }

  function setBorrowRate(uint256 rate) public onlyOwner {
    borrowRate = rate;
  }

  function setSupplyRate(uint256 rate) public onlyOwner {
    supplyRate = rate;
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    cash;
    borrows;
    reserves;
    return borrowRate;
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    cash;
    borrows;
    reserves;
    reserveFactorMantissa;
    return supplyRate;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './InterestRateModel.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Compound's WhitePaperInterestRateModel Contract
 * @author Compound
 * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper
 */
contract WhitePaperInterestRateModel is InterestRateModel {
  using SafeMath for uint256;

  event NewInterestParams(uint256 blocksPerYear, uint256 baseRatePerBlock, uint256 multiplierPerBlock);

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public blocksPerYear;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   */
  constructor(
    uint256 blocksPerYearOnChain,
    uint256 baseRatePerYear,
    uint256 multiplierPerYear
  ) {
    blocksPerYear = blocksPerYearOnChain;
    baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
    multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
    emit NewInterestParams(blocksPerYear, baseRatePerBlock, multiplierPerBlock);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    uint256 ur = utilizationRate(cash, borrows, reserves);
    return ur.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './InterestRateModel.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Compound's WhitePaperInterestRateModel Contract
 * @author Compound
 * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper
 */
contract ZeroInterestRateModel is InterestRateModel {
  using SafeMath for uint256;

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    return 0;
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITimelock {
  /** @notice Event emitted when a new time-lock agreement is created
   * @param agreementId ID of the created agreement
   * @param actionType Type of action for the time-lock
   * @param asset Address of the asset
   * @param amount  amount
   * @param beneficiary Address of the beneficiary
   * @param releaseTime Timestamp when the assets can be claimed
   */
  event AgreementCreated(
    uint256 agreementId,
    TimeLockActionType actionType,
    address indexed asset,
    uint256 amount,
    address indexed beneficiary,
    uint256 releaseTime
  );

  /** @notice Event emitted when a time-lock agreement is claimed
   * @param agreementId ID of the claimed agreement
   * @param actionType Type of action for the time-lock
   * @param asset Address of the asset
   * @param amount amount
   * @param beneficiary Address of the beneficiary
   */
  event AgreementClaimed(
    uint256 agreementId,
    TimeLockActionType actionType,
    address indexed asset,
    uint256 amount,
    address indexed beneficiary
  );

  /** @notice Event emitted when a time-lock agreement is frozen or unfrozen
   * @param agreementId ID of the affected agreement
   * @param value Indicates whether the agreement is frozen (true) or unfrozen (false)
   */
  event AgreementFrozen(uint256 agreementId, bool value);

  /** @notice Event emitted when the entire TimeLock contract is frozen or unfrozen
   * @param value Indicates whether the contract is frozen (true) or unfrozen (false)
   */
  event TimeLockFrozen(bool value);

  /**
   * @dev Emitted during rescueERC20()
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount being rescued
   **/
  event RescueERC20(address indexed token, address indexed to, uint256 amount);

  enum TimeLockActionType {
    BORROW,
    REDEEM
  }
  struct Agreement {
    uint256 agreementId;
    TimeLockActionType actionType;
    address underlying;
    bool isFrozen;
    address beneficiary;
    uint256 releaseTime;
    uint256 amount;
  }

  struct Underlying {
    address cToken;
    uint256 totalBalance;
    uint256 lockDuration;
    bool isSupport;
  }

  function createAgreement(
    TimeLockActionType actionType,
    address underlying,
    uint256 amount,
    address beneficiary
  ) external returns (uint256);

  function isSupport(address underlying) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './PriceOracle.sol';
import './Interfaces/IStdReference.sol';
import './Interfaces/IWitnetFeed.sol';
import './Interfaces/IChainlinkFeed.sol';
import './Interfaces/IVoltPair.sol';
import '@pythnetwork/pyth-sdk-solidity/IPyth.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

contract FeedPriceOracle is PriceOracle, Ownable2Step {
  struct FeedData {
    bytes32 feedId; // Pyth price feed ID
    uint8 source; // 1 - chainlink feed, 2 - witnet router, 3 - Band
    address addr; // feed address
    uint8 feedDecimals; // feed decimals (only used in witnet)
    string name;
  }

  mapping(address => FeedData) public feeds; // cToken -> feed data
  mapping(address => uint256) public fixedPrices; // cToken -> price
  uint8 constant DECIMALS = 18;

  event SetFeed(address indexed cToken_, bytes32 feedId, uint8 source, address addr, uint8 feedDecimals, string name);

  function setChainlinkFeed(address cToken_, address feed_) public onlyOwner {
    _setFeed(cToken_, uint8(1), bytes32(0), feed_, 8, '');
  }

  function setWitnetFeed(address cToken_, address feed_, uint8 feedDecimals_) public onlyOwner {
    _setFeed(cToken_, uint8(2), bytes32(0), feed_, feedDecimals_, '');
  }

  function setBandFeed(address cToken_, address feed_, uint8 feedDecimals_, string memory name) public onlyOwner {
    _setFeed(cToken_, uint8(3), bytes32(0), feed_, feedDecimals_, name);
  }

  function setFixedPrice(address cToken_, uint256 price) public onlyOwner {
    fixedPrices[cToken_] = price;
  }

  function setPythFeed(address cToken_, bytes32 feedId, address addr) public onlyOwner {
    _setFeed(cToken_, uint8(4), feedId, addr, 18, '');
  }

  function setLpFeed(address cToken_, address lpToken) public onlyOwner {
    _setFeed(cToken_, uint8(5), bytes32(0), lpToken, 18, '');
  }

  function _setFeed(
    address cToken_,
    uint8 source,
    bytes32 feedId,
    address addr,
    uint8 feedDecimals,
    string memory name
  ) private {
    require(addr != address(0), 'Address is Zero!');
    if (feeds[cToken_].source != 0) {
      delete fixedPrices[cToken_];
    }
    FeedData memory feedData = FeedData({
      feedId: feedId,
      source: source,
      addr: addr,
      feedDecimals: feedDecimals,
      name: name
    });
    feeds[cToken_] = feedData;
    emit SetFeed(cToken_, feedId, source, addr, feedDecimals, name);
  }

  function _getTokenPrice(address lpToken, address token) private view returns (uint256) {
    uint256 _balance = IERC20(token).balanceOf(lpToken);

    uint8 decimals = IERC20Metadata(token).decimals();

    uint256 _totalSupply = IERC20(lpToken).totalSupply();
    uint256 amount = (_balance * 1e18) / _totalSupply;

    uint256 price = getUnderlyingPrice(token);

    if (decimals < 18) amount = amount * (10 ** (18 - decimals));
    return (amount * price) / 1e18;
  }

  function _getLpPrice(address lpToken) private view returns (uint256) {
    address token0 = IVoltPair(lpToken).token0();
    address token1 = IVoltPair(lpToken).token1();

    return _getTokenPrice(lpToken, token0) + _getTokenPrice(lpToken, token1);
  }

  function removeFeed(address cToken_) public onlyOwner {
    delete feeds[cToken_];
  }

  function getFeed(address cToken_) public view returns (FeedData memory) {
    return feeds[cToken_];
  }

  function removeFixedPrice(address cToken_) public onlyOwner {
    delete fixedPrices[cToken_];
  }

  function getFixedPrice(address cToken_) public view returns (uint256) {
    return fixedPrices[cToken_];
  }

  function _getPythPrice(FeedData memory feed) internal view virtual returns (uint256) {
    (bool success, bytes memory message) = feed.addr.staticcall(
      abi.encodeWithSelector(IPyth.getPriceUnsafe.selector, feed.feedId)
    );
    require(success, 'pyth error!');
    (int64 price, , int32 expo, ) = (abi.decode(message, (int64, uint64, int32, uint256)));
    uint256 decimals = DECIMALS - uint32(expo * -1);
    require(decimals <= DECIMALS, 'DECIMAL UNDERFLOW');
    return uint64(price) * (10 ** decimals);
  }

  function getUnderlyingPrice(address cToken_) public view override returns (uint256) {
    FeedData memory feed = feeds[cToken_]; // gas savings
    if (feed.addr != address(0)) {
      if (feed.source == uint8(1)) {
        uint256 decimals = uint256(DECIMALS - IChainlinkFeed(feed.addr).decimals());
        require(decimals <= DECIMALS, 'DECIMAL UNDERFLOW');
        (uint80 roundID, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = IChainlinkFeed(feed.addr)
          .latestRoundData();
        require(answeredInRound >= roundID, 'Stale price');
        require(answer > 0, 'negative price');
        require(block.timestamp <= updatedAt + 86400, 'timeout');
        return uint256(answer) * (10 ** decimals);
      }
      if (feed.source == uint8(2)) {
        uint256 decimals = uint256(DECIMALS - feed.feedDecimals);
        require(decimals <= DECIMALS, 'DECIMAL UNDERFLOW');
        uint256 _temp = uint256(IWitnetFeed(feed.addr).lastPrice());
        return _temp * (10 ** decimals);
      }
      if (feed.source == uint8(3)) {
        uint256 decimals = uint256(DECIMALS - feed.feedDecimals);
        require(decimals <= DECIMALS, 'DECIMAL UNDERFLOW');
        IStdReference.ReferenceData memory refData = IStdReference(feed.addr).getReferenceData(feed.name, 'USD');
        return refData.rate * (10 ** decimals);
      }
      if (feed.source == uint8(4)) {
        return _getPythPrice(feed);
      }
      if (feed.source == uint8(5)) {
        return _getLpPrice(feed.addr);
      }
    }
    return fixedPrices[cToken_];
  }

  function getUnderlyingPrices(address[] memory cTokens) public view returns (uint256[] memory) {
    uint256 length = cTokens.length;
    uint256[] memory results = new uint256[](length);
    for (uint256 i; i < length; ++i) {
      results[i] = getUnderlyingPrice(cTokens[i]);
    }
    return results;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './FeedPriceOracle.sol';

contract FeedPriceOracleSafe is FeedPriceOracle {
  uint256 public validTimePeriod = 7200;

  function _getPythPrice(FeedData memory feed) internal view override returns (uint256) {
    (bool success, bytes memory message) = feed.addr.staticcall(
      abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, feed.feedId, validTimePeriod)
    );
    require(success, 'pyth error!');
    (int64 price, , int32 expo, ) = (abi.decode(message, (int64, uint64, int32, uint256)));
    uint256 decimals = DECIMALS - uint32(expo * -1);
    require(decimals <= DECIMALS, 'DECIMAL UNDERFLOW');
    return uint64(price) * (10 ** decimals);
  }

  function setPythValidTimePeriod(uint256 _validTimePeriod) public onlyOwner {
    require(_validTimePeriod >= 60, 'validTimePeriod >= 60');
    validTimePeriod = _validTimePeriod;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IChainlinkFeed {
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStdReference {
  /// A structure returned whenever someone requests for standard reference data.
  struct ReferenceData {
    uint256 rate; // base/quote exchange rate, multiplied by 1e18.
    uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
    uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
  }

  /// Returns the price data for the given base/quote pair. Revert if not available.
  function getReferenceData(string calldata _base, string calldata _quote) external view returns (ReferenceData memory);

  /// Similar to getReferenceData, but with multiple base/quote pairs at once.
  function getReferenceDataBulk(string[] calldata _bases, string[] calldata _quotes)
    external
    view
    returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVoltPair {
  function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWitnetFeed {
  function lastPrice() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract PriceOracle {
  /// @notice Indicator that this is a PriceOracle contract (for inspection)
  bool public constant isPriceOracle = true;

  /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getUnderlyingPrice(address cToken) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract SumerProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin_,
        bytes memory data
    ) payable TransparentUpgradeableProxy(logic, admin_, data) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract SumerProxyAdmin is ProxyAdmin {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './TransferHelper.sol';

contract CommunalFarm is Ownable2Step, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Instances
  IERC20 public stakingToken;

  // Constant for various precisions
  uint256 private constant MULTIPLIER_PRECISION = 1e18;

  // Time tracking
  uint256 public periodFinish;
  uint256 public lastUpdateTime;

  // Lock time and multiplier settings
  uint256 public lock_max_multiplier = uint256(3e18); // E18. 1x = e18
  uint256 public lock_time_for_max_multiplier = 1 * 365 * 86400; // 1 year
  uint256 public lock_time_min = 86400; // 1 * 86400  (1 day)

  // Reward addresses, rates, and managers
  mapping(address => address) public rewardManagers; // token addr -> manager addr
  address[] public rewardTokens;
  uint256[] public rewardRates;
  string[] public rewardSymbols;
  mapping(address => uint256) public rewardTokenAddrToIdx; // token addr -> token index

  // Reward period
  uint256 public rewardsDuration = 7 days; // 7 * 86400  (7 days)

  // Reward tracking
  uint256[] private rewardsPerTokenStored;
  mapping(address => mapping(uint256 => uint256)) private userRewardsPerTokenPaid; // staker addr -> token id -> paid amount
  mapping(address => mapping(uint256 => uint256)) private rewards; // staker addr -> token id -> reward amount
  mapping(address => uint256) private lastRewardClaimTime; // staker addr -> timestamp

  // Balance tracking
  uint256 private _total_liquidity_locked;
  uint256 private _total_combined_weight;
  mapping(address => uint256) private _locked_liquidity;
  mapping(address => uint256) private _combined_weights;

  // Stake tracking
  mapping(address => LockedStake[]) private lockedStakes;

  // Greylisting of bad addresses
  mapping(address => bool) public greylist;

  // Administrative booleans
  bool public stakesUnlocked; // Release locked stakes in case of emergency
  bool public withdrawalsPaused; // For emergencies
  bool public rewardsCollectionPaused; // For emergencies
  bool public stakingPaused; // For emergencies

  /* ========== STRUCTS ========== */

  struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
  }

  /* ========== MODIFIERS ========== */

  modifier onlyTknMgrs(address reward_token_address) {
    require(msg.sender == owner() || isTokenManagerFor(msg.sender, reward_token_address), 'Not owner or tkn mgr');
    _;
  }

  modifier updateRewardAndBalance(address account, bool sync_too) {
    _updateRewardAndBalance(account, sync_too);
    _;
  }

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _stakingToken,
    string[] memory _rewardSymbols,
    address[] memory _rewardTokens,
    address[] memory _rewardManagers,
    uint256[] memory _rewardRates
  ) {
    stakingToken = IERC20(_stakingToken);

    rewardTokens = _rewardTokens;
    rewardRates = _rewardRates;
    rewardSymbols = _rewardSymbols;

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      // For fast token address -> token ID lookups later
      rewardTokenAddrToIdx[_rewardTokens[i]] = i;

      // Initialize the stored rewards
      rewardsPerTokenStored.push(0);

      // Initialize the reward managers
      rewardManagers[_rewardTokens[i]] = _rewardManagers[i];
    }

    // Other booleans
    stakesUnlocked = false;

    // Initialization
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
  }

  /* ========== VIEWS ========== */

  // Total locked liquidity tokens
  function totalLiquidityLocked() external view returns (uint256) {
    return _total_liquidity_locked;
  }

  // Locked liquidity for a given account
  function lockedLiquidityOf(address account) external view returns (uint256) {
    return _locked_liquidity[account];
  }

  // Total 'balance' used for calculating the percent of the pool the account owns
  // Takes into account the locked stake time multiplier
  function totalCombinedWeight() external view returns (uint256) {
    return _total_combined_weight;
  }

  // Combined weight for a specific account
  function combinedWeightOf(address account) external view returns (uint256) {
    return _combined_weights[account];
  }

  // Calculated the combined weight for an account
  function calcCurCombinedWeight(
    address account
  ) public view returns (uint256 old_combined_weight, uint256 new_combined_weight) {
    // Get the old combined weight
    old_combined_weight = _combined_weights[account];

    // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
    new_combined_weight = 0;
    for (uint256 i = 0; i < lockedStakes[account].length; i++) {
      LockedStake memory thisStake = lockedStakes[account][i];
      uint256 lock_multiplier = thisStake.lock_multiplier;

      // If the lock is expired
      if (thisStake.ending_timestamp <= block.timestamp) {
        // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
        if (lastRewardClaimTime[account] < thisStake.ending_timestamp) {
          uint256 time_before_expiry = (thisStake.ending_timestamp).sub(lastRewardClaimTime[account]);
          uint256 time_after_expiry = (block.timestamp).sub(thisStake.ending_timestamp);

          // Get the weighted-average lock_multiplier
          uint256 numerator = ((lock_multiplier).mul(time_before_expiry)).add(
            ((MULTIPLIER_PRECISION).mul(time_after_expiry))
          );
          lock_multiplier = numerator.div(time_before_expiry.add(time_after_expiry));
        }
        // Otherwise, it needs to just be 1x
        else {
          lock_multiplier = MULTIPLIER_PRECISION;
        }
      }

      uint256 liquidity = thisStake.liquidity;
      uint256 combined_boosted_amount = liquidity.mul(lock_multiplier).div(MULTIPLIER_PRECISION);
      new_combined_weight = new_combined_weight.add(combined_boosted_amount);
    }
  }

  // All the locked stakes for a given account
  function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
    return lockedStakes[account];
  }

  // All the locked stakes for a given account
  function getRewardSymbols() external view returns (string[] memory) {
    return rewardSymbols;
  }

  // All the reward tokens
  function getAllRewardTokens() external view returns (address[] memory) {
    return rewardTokens;
  }

  // All the reward rates
  function getAllRewardRates() external view returns (uint256[] memory) {
    return rewardRates;
  }

  // Multiplier amount, given the length of the lock
  function lockMultiplier(uint256 secs) public view returns (uint256) {
    uint256 lock_multiplier = uint256(MULTIPLIER_PRECISION).add(
      secs.mul(lock_max_multiplier.sub(MULTIPLIER_PRECISION)).div(lock_time_for_max_multiplier)
    );
    if (lock_multiplier > lock_max_multiplier) lock_multiplier = lock_max_multiplier;
    return lock_multiplier;
  }

  // Last time the reward was applicable
  function lastTimeRewardApplicable() internal view returns (uint256) {
    return min(block.timestamp, periodFinish);
  }

  // Amount of reward tokens per LP token
  function rewardsPerToken() public view returns (uint256[] memory newRewardsPerTokenStored) {
    if (_total_liquidity_locked == 0 || _total_combined_weight == 0) {
      return rewardsPerTokenStored;
    } else {
      newRewardsPerTokenStored = new uint256[](rewardTokens.length);
      for (uint256 i = 0; i < rewardsPerTokenStored.length; i++) {
        newRewardsPerTokenStored[i] = rewardsPerTokenStored[i].add(
          lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates[i]).mul(1e18).div(_total_combined_weight)
        );
      }
      return newRewardsPerTokenStored;
    }
  }

  // Amount of reward tokens an account has earned / accrued
  // Note: In the edge-case of one of the account's stake expiring since the last claim, this will
  // return a slightly inflated number
  function earned(address account) public view returns (uint256[] memory new_earned) {
    uint256[] memory reward_arr = rewardsPerToken();
    new_earned = new uint256[](rewardTokens.length);

    if (_combined_weights[account] == 0) {
      for (uint256 i = 0; i < rewardTokens.length; i++) {
        new_earned[i] = 0;
      }
    } else {
      for (uint256 i = 0; i < rewardTokens.length; i++) {
        new_earned[i] = (_combined_weights[account])
          .mul(reward_arr[i].sub(userRewardsPerTokenPaid[account][i]))
          .div(1e18)
          .add(rewards[account][i]);
      }
    }
  }

  // Total reward tokens emitted in the given period
  function getRewardForDuration() external view returns (uint256[] memory rewards_per_duration_arr) {
    rewards_per_duration_arr = new uint256[](rewardRates.length);

    for (uint256 i = 0; i < rewardRates.length; i++) {
      rewards_per_duration_arr[i] = rewardRates[i].mul(rewardsDuration);
    }
  }

  // See if the caller_addr is a manager for the reward token
  function isTokenManagerFor(address caller_addr, address reward_token_addr) public view returns (bool) {
    if (caller_addr == owner()) return true;
    // Contract owner
    else if (rewardManagers[reward_token_addr] == caller_addr) return true; // Reward manager
    return false;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function _updateRewardAndBalance(address account, bool sync_too) internal {
    // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
    if (sync_too) {
      sync();
    }

    if (account != address(0)) {
      // To keep the math correct, the user's combined weight must be recomputed
      (uint256 old_combined_weight, uint256 new_combined_weight) = calcCurCombinedWeight(account);

      // Calculate the earnings first
      _syncEarned(account);

      // Update the user's and the global combined weights
      if (new_combined_weight >= old_combined_weight) {
        uint256 weight_diff = new_combined_weight.sub(old_combined_weight);
        _total_combined_weight = _total_combined_weight.add(weight_diff);
        _combined_weights[account] = old_combined_weight.add(weight_diff);
      } else {
        uint256 weight_diff = old_combined_weight.sub(new_combined_weight);
        _total_combined_weight = _total_combined_weight.sub(weight_diff);
        _combined_weights[account] = old_combined_weight.sub(weight_diff);
      }
    }
  }

  function _syncEarned(address account) internal {
    if (account != address(0)) {
      // Calculate the earnings
      uint256[] memory earned_arr = earned(account);

      // Update the rewards array
      for (uint256 i = 0; i < earned_arr.length; i++) {
        rewards[account][i] = earned_arr[i];
      }

      // Update the rewards paid array
      for (uint256 i = 0; i < earned_arr.length; i++) {
        userRewardsPerTokenPaid[account][i] = rewardsPerTokenStored[i];
      }
    }
  }

  // Two different stake functions are needed because of delegateCall and msg.sender issues
  function stakeLocked(uint256 liquidity, uint256 secs) public nonReentrant {
    _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
  }

  // If this were not internal, and source_address had an infinite approve, this could be exploitable
  // (pull funds from source_address and stake for an arbitrary staker_address)
  function _stakeLocked(
    address staker_address,
    address source_address,
    uint256 liquidity,
    uint256 secs,
    uint256 start_timestamp
  ) internal updateRewardAndBalance(staker_address, true) {
    require(!stakingPaused, 'Staking paused');
    require(liquidity > 0, 'Must stake more than zero');
    require(greylist[staker_address] == false, 'Address has been greylisted');
    require(secs >= lock_time_min, 'Minimum stake time not met');
    require(secs <= lock_time_for_max_multiplier, 'Trying to lock for too long');

    uint256 lock_multiplier = lockMultiplier(secs);
    bytes32 kek_id = keccak256(
      abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address])
    );
    lockedStakes[staker_address].push(
      LockedStake(kek_id, start_timestamp, liquidity, start_timestamp.add(secs), lock_multiplier)
    );

    // Pull the tokens from the source_address
    TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);

    // Update liquidities
    _total_liquidity_locked = _total_liquidity_locked.add(liquidity);
    _locked_liquidity[staker_address] = _locked_liquidity[staker_address].add(liquidity);

    // Need to call to update the combined weights
    _updateRewardAndBalance(staker_address, true);

    // Needed for edge case if the staker only claims once, and after the lock expired
    if (lastRewardClaimTime[staker_address] == 0) lastRewardClaimTime[staker_address] = block.timestamp;

    emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);
  }

  // Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues
  function withdrawLocked(bytes32 kek_id) public nonReentrant {
    require(withdrawalsPaused == false, 'Withdrawals paused');
    _withdrawLocked(msg.sender, msg.sender, kek_id);
  }

  // No withdrawer == msg.sender check needed since this is only internally callable and the checks are done in the wrapper
  // functions like withdraw()
  function _withdrawLocked(address staker_address, address destination_address, bytes32 kek_id) internal {
    // Collect rewards first and then update the balances
    _getReward(staker_address, destination_address);

    LockedStake memory thisStake;
    thisStake.liquidity = 0;
    uint256 theArrayIndex;
    for (uint256 i = 0; i < lockedStakes[staker_address].length; i++) {
      if (kek_id == lockedStakes[staker_address][i].kek_id) {
        thisStake = lockedStakes[staker_address][i];
        theArrayIndex = i;
        break;
      }
    }
    require(thisStake.kek_id == kek_id, 'Stake not found');
    require(block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true, 'Stake is still locked!');

    uint256 liquidity = thisStake.liquidity;

    if (liquidity > 0) {
      // Update liquidities
      _total_liquidity_locked = _total_liquidity_locked.sub(liquidity);
      _locked_liquidity[staker_address] = _locked_liquidity[staker_address].sub(liquidity);

      // Remove the stake from the array
      delete lockedStakes[staker_address][theArrayIndex];

      // Need to call to update the combined weights
      _updateRewardAndBalance(staker_address, false);

      // Give the tokens to the destination_address
      // Should throw if insufficient balance
      stakingToken.safeTransfer(destination_address, liquidity);

      emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
    }
  }

  // Two different getReward functions are needed because of delegateCall and msg.sender issues
  function getReward() external nonReentrant returns (uint256[] memory) {
    require(rewardsCollectionPaused == false, 'Rewards collection paused');
    return _getReward(msg.sender, msg.sender);
  }

  // No withdrawer == msg.sender check needed since this is only internally callable
  function _getReward(
    address rewardee,
    address destination_address
  ) internal updateRewardAndBalance(rewardee, true) returns (uint256[] memory rewards_before) {
    // Update the rewards array and distribute rewards
    rewards_before = new uint256[](rewardTokens.length);

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      rewards_before[i] = rewards[rewardee][i];
      rewards[rewardee][i] = 0;
      IERC20(rewardTokens[i]).safeTransfer(destination_address, rewards_before[i]);
      emit RewardPaid(rewardee, rewards_before[i], rewardTokens[i], destination_address);
    }

    lastRewardClaimTime[rewardee] = block.timestamp;
  }

  // If the period expired, renew it
  function retroCatchUp() internal {
    // Failsafe check
    require(block.timestamp > periodFinish, 'Period has not expired yet!');

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / rewardsDuration; // Floor division to the nearest period

    // Make sure there are enough tokens to renew the reward period
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      require(
        rewardRates[i].mul(rewardsDuration).mul(num_periods_elapsed + 1) <=
          IERC20(rewardTokens[i]).balanceOf(address(this)),
        string(abi.encodePacked('Not enough reward tokens available: ', rewardTokens[i]))
      );
    }

    // uint256 old_lastUpdateTime = lastUpdateTime;
    // uint256 new_lastUpdateTime = block.timestamp;

    // lastUpdateTime = periodFinish;
    periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(rewardsDuration));

    _updateStoredRewardsAndTime();

    emit RewardsPeriodRenewed(address(stakingToken));
  }

  function _updateStoredRewardsAndTime() internal {
    // Get the rewards
    uint256[] memory rewards_per_token = rewardsPerToken();

    // Update the rewardsPerTokenStored
    for (uint256 i = 0; i < rewardsPerTokenStored.length; i++) {
      rewardsPerTokenStored[i] = rewards_per_token[i];
    }

    // Update the last stored time
    lastUpdateTime = lastTimeRewardApplicable();
  }

  function sync() public {
    if (block.timestamp > periodFinish) {
      retroCatchUp();
    } else {
      _updateStoredRewardsAndTime();
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    // Cannot rug the staking / LP tokens
    require(tokenAddress != address(stakingToken), 'Cannot rug staking / LP tokens');

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      if (rewardTokens[i] == tokenAddress) {
        revert('No valid tokens to recover');
      }
    }
    if (msg.sender == owner()) {
      IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
      emit Recovered(msg.sender, tokenAddress, tokenAmount);
      return;
    } else {
      revert('No valid tokens to recover');
    }
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(_rewardsDuration >= 86400, 'Rewards duration too short');
    require(periodFinish == 0 || block.timestamp > periodFinish, 'Reward period incomplete');
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function setMultipliers(uint256 _lock_max_multiplier) external onlyOwner {
    require(_lock_max_multiplier >= uint256(1e18), 'Multiplier must be greater than or equal to 1e18');
    lock_max_multiplier = _lock_max_multiplier;
    emit LockedStakeMaxMultiplierUpdated(lock_max_multiplier);
  }

  function setLockedStakeTimeForMinAndMaxMultiplier(
    uint256 _lock_time_for_max_multiplier,
    uint256 _lock_time_min
  ) external onlyOwner {
    require(_lock_time_for_max_multiplier >= 1, 'Mul max time must be >= 1');
    require(_lock_time_min >= 1, 'Mul min time must be >= 1');

    lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
    lock_time_min = _lock_time_min;

    emit LockedStakeTimeForMaxMultiplier(lock_time_for_max_multiplier);
    emit LockedStakeMinTime(_lock_time_min);
  }

  function greylistAddress(address _address) external onlyOwner {
    greylist[_address] = !(greylist[_address]);
  }

  function unlockStakes() external onlyOwner {
    stakesUnlocked = !stakesUnlocked;
  }

  function toggleStaking() external onlyOwner {
    stakingPaused = !stakingPaused;
  }

  function toggleWithdrawals() external onlyOwner {
    withdrawalsPaused = !withdrawalsPaused;
  }

  function toggleRewardsCollection() external onlyOwner {
    rewardsCollectionPaused = !rewardsCollectionPaused;
  }

  // The owner or the reward token managers can set reward rates
  function setRewardRate(
    address reward_token_address,
    uint256 new_rate,
    bool sync_too
  ) external onlyTknMgrs(reward_token_address) {
    rewardRates[rewardTokenAddrToIdx[reward_token_address]] = new_rate;

    if (sync_too) {
      sync();
    }
  }

  // The owner or the reward token managers can change managers
  function changeTokenManager(
    address reward_token_address,
    address new_manager_address
  ) external onlyTknMgrs(reward_token_address) {
    rewardManagers[reward_token_address] = new_manager_address;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /* ========== EVENTS ========== */

  event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
  event WithdrawLocked(address indexed user, uint256 amount, bytes32 kek_id, address destination_address);
  event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address destination_address, address token, uint256 amount);
  event RewardsPeriodRenewed(address token);
  event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
  event LockedStakeTimeForMaxMultiplier(uint256 secs);
  event LockedStakeMinTime(uint256 secs);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================== FraxGaugeFXSRewardsDistributor ==================
// ====================================================================
// Looks at the gauge controller contract and pushes out FXS rewards once
// a week to the gauges (farms)

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IFraxGaugeController.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './TransferHelper.sol';

contract FraxGaugeFXSRewardsDistributor is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  /* ========== STATE VARIABLES ========== */

  // Instances and addresses
  address public reward_token_address;
  IFraxGaugeController public gauge_controller;

  // Admin addresses
  address public timelock_address;
  address public curator_address;

  // Constants
  uint256 private constant MULTIPLIER_PRECISION = 1e18;
  uint256 private constant ONE_WEEK = 7 days;

  // Gauge controller related
  mapping(address => bool) public gauge_whitelist;
  mapping(address => bool) public is_middleman; // For cross-chain farms, use a middleman contract to push to a bridge
  mapping(address => uint256) public last_time_gauge_paid;

  // Booleans
  bool public distributionsOn;

  /* ========== MODIFIERS ========== */

  modifier onlyByOwnGov() {
    require(msg.sender == owner() || msg.sender == timelock_address, 'Not owner or timelock');
    _;
  }

  modifier onlyByOwnerOrCuratorOrGovernance() {
    require(
      msg.sender == owner() || msg.sender == curator_address || msg.sender == timelock_address,
      'Not owner, curator, or timelock'
    );
    _;
  }

  modifier isDistributing() {
    require(distributionsOn == true, 'Distributions are off');
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _timelock_address,
    address _curator_address,
    address _reward_token_address,
    address _gauge_controller_address
  ) {
    curator_address = _curator_address;
    timelock_address = _timelock_address;

    reward_token_address = _reward_token_address;
    gauge_controller = IFraxGaugeController(_gauge_controller_address);

    distributionsOn = true;
  }

  /* ========== VIEWS ========== */

  // Current weekly reward amount
  function currentReward(address gauge_address) public view returns (uint256 reward_amount) {
    uint256 rel_weight = gauge_controller.gauge_relative_weight(gauge_address, block.timestamp);
    uint256 rwd_rate = (gauge_controller.global_emission_rate()).mul(rel_weight).div(1e18);
    reward_amount = rwd_rate.mul(ONE_WEEK);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  // Callable by anyone
  function distributeReward(
    address gauge_address
  ) public isDistributing nonReentrant returns (uint256 weeks_elapsed, uint256 reward_tally) {
    require(gauge_whitelist[gauge_address], 'Gauge not whitelisted');

    // Calculate the elapsed time in weeks.
    uint256 last_time_paid = last_time_gauge_paid[gauge_address];

    // Edge case for first reward for this gauge
    if (last_time_paid == 0) {
      weeks_elapsed = 1;
    } else {
      // Truncation desired
      weeks_elapsed = (block.timestamp).sub(last_time_gauge_paid[gauge_address]) / ONE_WEEK;

      // Return early here for 0 weeks instead of throwing, as it could have bad effects in other contracts
      if (weeks_elapsed == 0) {
        return (0, 0);
      }
    }

    // NOTE: This will always use the current global_emission_rate()
    reward_tally = 0;
    for (uint i = 0; i < (weeks_elapsed); i++) {
      uint256 rel_weight_at_week;
      if (i == 0) {
        // Mutative, for the current week. Makes sure the weight is checkpointed. Also returns the weight.
        rel_weight_at_week = gauge_controller.gauge_relative_weight_write(gauge_address, block.timestamp);
      } else {
        // View
        rel_weight_at_week = gauge_controller.gauge_relative_weight(gauge_address, (block.timestamp).sub(ONE_WEEK * i));
      }
      uint256 rwd_rate_at_week = (gauge_controller.global_emission_rate()).mul(rel_weight_at_week).div(1e18);
      reward_tally = reward_tally.add(rwd_rate_at_week.mul(ONE_WEEK));
    }

    // Update the last time paid
    last_time_gauge_paid[gauge_address] = block.timestamp;

    if (is_middleman[gauge_address]) {
      // Cross chain: Pay out the rewards to the middleman contract
      // Approve for the middleman first
      ERC20(reward_token_address).approve(gauge_address, reward_tally);

    } else {
      // Mainnet: Pay out the rewards directly to the gauge
      TransferHelper.safeTransfer(reward_token_address, gauge_address, reward_tally);
    }

    emit RewardDistributed(gauge_address, reward_tally);
  }

  /* ========== RESTRICTED FUNCTIONS - Curator / migrator callable ========== */

  // For emergency situations
  function toggleDistributions() external onlyByOwnerOrCuratorOrGovernance {
    distributionsOn = !distributionsOn;

    emit DistributionsToggled(distributionsOn);
  }

  /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

  // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
    // Only the owner address can ever receive the recovery withdrawal
    TransferHelper.safeTransfer(tokenAddress, owner(), tokenAmount);
    emit RecoveredERC20(tokenAddress, tokenAmount);
  }

  function setGaugeState(address _gauge_address, bool _is_middleman, bool _is_active) external onlyByOwnGov {
    is_middleman[_gauge_address] = _is_middleman;
    gauge_whitelist[_gauge_address] = _is_active;

    emit GaugeStateChanged(_gauge_address, _is_middleman, _is_active);
  }

  function setTimelock(address _new_timelock) external onlyByOwnGov {
    timelock_address = _new_timelock;
  }

  function setCurator(address _new_curator_address) external onlyByOwnGov {
    curator_address = _new_curator_address;
  }

  function setGaugeController(address _gauge_controller_address) external onlyByOwnGov {
    gauge_controller = IFraxGaugeController(_gauge_controller_address);
  }

  /* ========== EVENTS ========== */

  event RewardDistributed(address indexed gauge_address, uint256 reward_amount);
  event RecoveredERC20(address token, uint256 amount);
  event GaugeStateChanged(address gauge_address, bool is_middleman, bool is_active);
  event DistributionsToggled(bool distibutions_state);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// https://github.com/swervefi/swerve/edit/master/packages/swerve-contracts/interfaces/IGaugeController.sol

interface IFraxGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    // Public variables
    function admin() external view returns (address);
    function future_admin() external view returns (address);
    function token() external view returns (address);
    function voting_escrow() external view returns (address);
    function n_gauge_types() external view returns (int128);
    function n_gauges() external view returns (int128);
    function gauge_type_names(int128) external view returns (string memory);
    function gauges(uint256) external view returns (address);
    function vote_user_slopes(address, address)
        external
        view
        returns (VotedSlope memory);
    function vote_user_power(address) external view returns (uint256);
    function last_user_vote(address, address) external view returns (uint256);
    function points_weight(address, uint256)
        external
        view
        returns (Point memory);
    function time_weight(address) external view returns (uint256);
    function points_sum(int128, uint256) external view returns (Point memory);
    function time_sum(uint256) external view returns (uint256);
    function points_total(uint256) external view returns (uint256);
    function time_total() external view returns (uint256);
    function points_type_weight(int128, uint256)
        external
        view
        returns (uint256);
    function time_type_weight(uint256) external view returns (uint256);

    // Getter functions
    function gauge_types(address) external view returns (int128);
    function gauge_relative_weight(address) external view returns (uint256);
    function gauge_relative_weight(address, uint256) external view returns (uint256);
    function get_gauge_weight(address) external view returns (uint256);
    function get_type_weight(int128) external view returns (uint256);
    function get_total_weight() external view returns (uint256);
    function get_weights_sum_per_type(int128) external view returns (uint256);

    // External functions
    function commit_transfer_ownership(address) external;
    function apply_transfer_ownership() external;
    function add_gauge(
        address,
        int128,
        uint256
    ) external;
    function checkpoint() external;
    function checkpoint_gauge(address) external;
    function global_emission_rate() external view returns (uint256);
    function gauge_relative_weight_write(address)
        external
        returns (uint256);
    function gauge_relative_weight_write(address, uint256)
        external
        returns (uint256);
    function add_type(string memory, uint256) external;
    function change_type_weight(int128, uint256) external;
    function change_gauge_weight(address, uint256) external;
    function change_global_emission_rate(uint256) external;
    function vote_for_gauge_weights(address, uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IFraxGaugeFXSRewardsDistributor {
  function acceptOwnership() external;
  function curator_address() external view returns(address);
  function currentReward(address gauge_address) external view returns(uint256 reward_amount);
  function distributeReward(address gauge_address) external returns(uint256 weeks_elapsed, uint256 reward_tally);
  function distributionsOn() external view returns(bool);
  function gauge_whitelist(address) external view returns(bool);
  function is_middleman(address) external view returns(bool);
  function last_time_gauge_paid(address) external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function owner() external view returns(address);
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function setCurator(address _new_curator_address) external;
  function setGaugeController(address _gauge_controller_address) external;
  function setGaugeState(address _gauge_address, bool _is_middleman, bool _is_active) external;
  function setTimelock(address _new_timelock) external;
  function timelock_address() external view returns(address);
  function toggleDistributions() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ===================== StakingRewardsMultiGauge =====================
// ====================================================================
// veSUMER-enabled
// Multiple tokens with different reward rates can be emitted
// Multiple teams can set the reward rates for their token(s)
// Those teams can also use a gauge, or an external function with
// Apes together strong

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Saddle Team: https://github.com/saddle-finance
// Fei Team: https://github.com/fei-protocol
// Alchemix Team: https://github.com/alchemix-finance
// Liquity Team: https://github.com/liquity
// Gelato Team (kassandraoftroy): https://github.com/gelatodigital

// Originally inspired by Synthetix.io, but heavily modified by the Frax team
// https://raw.githubusercontent.com/Synthetixio/synthetix/develop/contracts/StakingRewards.sol

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './TransferHelper.sol';

// -------------------- VARIES --------------------

// G-UNI
// import "../Misc_AMOs/gelato/IGUniPool.sol";

// mStable
// import '../Misc_AMOs/mstable/IFeederPool.sol';

// StakeDAO sdETH-FraxPut
// import '../Misc_AMOs/stakedao/IOpynPerpVault.sol';

// StakeDAO Vault
// import '../Misc_AMOs/stakedao/IStakeDaoVault.sol';

// Uniswap V2
import './IUniswapV2Pair.sol';

// ------------------------------------------------

import './IFraxGaugeController.sol';
import './IFraxGaugeFXSRewardsDistributor.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// Inheritance
import '@openzeppelin/contracts/access/Ownable2Step.sol';

contract StakingRewardsMultiGauge is Ownable2Step, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  /* ========== STATE VARIABLES ========== */

  // Instances
  IERC20 private constant veSUMER = IERC20(0xF67C5F20B95b7604EBB65A53E50ebd38300da8EE);

  // -------------------- VARIES --------------------

  // G-UNI
  // IGUniPool public stakingToken;

  // mStable
  // IFeederPool public stakingToken;

  // sdETH-FraxPut Vault
  // IOpynPerpVault public stakingToken;

  // StakeDAO Vault
  // IStakeDaoVault public stakingToken;

  // Uniswap V2
  IUniswapV2Pair public stakingToken;

  // ------------------------------------------------

  IFraxGaugeFXSRewardsDistributor public rewards_distributor;

  address public constant usd_address = 0x0d893C092f7aE9D97c13307f2D66CFB59430b4Cb;

  // Constant for various precisions
  uint256 public constant MULTIPLIER_PRECISION = 1e18;

  // Time tracking
  uint256 public periodFinish;
  uint256 public lastUpdateTime;

  // Lock time and multiplier settings
  uint256 public lock_max_multiplier = uint256(3e18); // E18. 1x = e18
  uint256 public lock_time_for_max_multiplier = 3 * 365 * 86400; // 3 years
  uint256 public lock_time_min = 86400; // 1 * 86400  (1 day)

  // veSUMER related
  uint256 public veSumer_per_usd_for_max_boost = uint256(4e18); // E18. 4e18 means 4 veSUMER must be held by the staker per 1 usd
  uint256 public veSumer_max_multiplier = uint256(2e18); // E18. 1x = 1e18
  mapping(address => uint256) private _veSumerMultiplierStored;

  // Reward addresses, gauge addresses, reward rates, and reward managers
  mapping(address => address) public rewardManagers; // token addr -> manager addr
  address[] public rewardTokens;
  address[] public gaugeControllers;
  uint256[] public rewardRatesManual;
  string[] public rewardSymbols;
  mapping(address => uint256) public rewardTokenAddrToIdx; // token addr -> token index

  // Reward period
  uint256 public rewardsDuration = 7 days; // 7 * 86400  (7 days)

  // Reward tracking
  uint256[] private rewardsPerTokenStored;
  mapping(address => mapping(uint256 => uint256)) private userRewardsPerTokenPaid; // staker addr -> token id -> paid amount
  mapping(address => mapping(uint256 => uint256)) private rewards; // staker addr -> token id -> reward amount
  mapping(address => uint256) private lastRewardClaimTime; // staker addr -> timestamp
  uint256[] private last_gauge_relative_weights;
  uint256[] private last_gauge_time_totals;

  // Balance tracking
  uint256 private _total_liquidity_locked;
  uint256 private _total_combined_weight;
  mapping(address => uint256) private _locked_liquidity;
  mapping(address => uint256) private _combined_weights;

  // List of valid migrators (set by governance)
  mapping(address => bool) public valid_migrators;

  // Stakers set which migrator(s) they want to use
  mapping(address => mapping(address => bool)) public staker_allowed_migrators;

  // Uniswap V2 (or G-UNI) ONLY
  bool usd_is_token0;

  // Stake tracking
  mapping(address => LockedStake[]) private lockedStakes;

  // Greylisting of bad addresses
  mapping(address => bool) public greylist;

  // Administrative booleans
  bool public stakesUnlocked; // Release locked stakes in case of emergency
  bool public migrationsOn; // Used for migrations. Prevents new stakes, but allows LP and reward withdrawals
  bool public withdrawalsPaused; // For emergencies
  bool public rewardsCollectionPaused; // For emergencies
  bool public stakingPaused; // For emergencies

  /* ========== STRUCTS ========== */

  struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
  }

  /* ========== MODIFIERS ========== */

  modifier onlyTknMgrs(address reward_token_address) {
    require(msg.sender == owner() || isTokenManagerFor(msg.sender, reward_token_address), 'Not owner or tkn mgr');
    _;
  }

  modifier isMigrating() {
    require(migrationsOn == true, 'Not in migration');
    _;
  }

  modifier updateRewardAndBalance(address account, bool sync_too) {
    _updateRewardAndBalance(account, sync_too);
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _stakingToken,
    address _rewards_distributor_address,
    string[] memory _rewardSymbols,
    address[] memory _rewardTokens,
    address[] memory _rewardManagers,
    uint256[] memory _rewardRatesManual,
    address[] memory _gaugeControllers
  ) {
    // -------------------- VARIES --------------------
    // G-UNI
    // stakingToken = IGUniPool(_stakingToken);
    // address token0 = address(stakingToken.token0());
    // frax_is_token0 = token0 == frax_address;

    // mStable
    // stakingToken = IFeederPool(_stakingToken);

    // StakeDAO sdETH-FraxPut Vault
    // stakingToken = IOpynPerpVault(_stakingToken);

    // StakeDAO Vault
    // stakingToken = IStakeDaoVault(_stakingToken);

    // Uniswap V2
    stakingToken = IUniswapV2Pair(_stakingToken);
    address token0 = stakingToken.token0();
    if (token0 == usd_address) usd_is_token0 = true;
    else usd_is_token0 = false;
    // ------------------------------------------------
    require(
      _rewardSymbols.length == _rewardTokens.length &&
        _rewardSymbols.length == _rewardManagers.length &&
        _rewardSymbols.length == _rewardRatesManual.length,
      'length!'
    );
    rewards_distributor = IFraxGaugeFXSRewardsDistributor(_rewards_distributor_address);

    rewardTokens = _rewardTokens;
    gaugeControllers = _gaugeControllers;
    rewardRatesManual = _rewardRatesManual;
    rewardSymbols = _rewardSymbols;

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      // For fast token address -> token ID lookups later
      rewardTokenAddrToIdx[_rewardTokens[i]] = i;

      // Initialize the stored rewards
      rewardsPerTokenStored.push(0);

      // Initialize the reward managers
      rewardManagers[_rewardTokens[i]] = _rewardManagers[i];

      // Push in empty relative weights to initialize the array
      last_gauge_relative_weights.push(0);

      // Push in empty time totals to initialize the array
      last_gauge_time_totals.push(0);
    }

    // Other booleans
    stakesUnlocked = false;

    // Initialization
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
  }

  /* ========== VIEWS ========== */

  // Total locked liquidity tokens
  function totalLiquidityLocked() external view returns (uint256) {
    return _total_liquidity_locked;
  }

  // Locked liquidity for a given account
  function lockedLiquidityOf(address account) external view returns (uint256) {
    return _locked_liquidity[account];
  }

  // Total 'balance' used for calculating the percent of the pool the account owns
  // Takes into account the locked stake time multiplier
  function totalCombinedWeight() external view returns (uint256) {
    return _total_combined_weight;
  }

  // Combined weight for a specific account
  function combinedWeightOf(address account) external view returns (uint256) {
    return _combined_weights[account];
  }

  function usdPerLPToken() public view returns (uint256) {
    uint256 usd_per_lp_token;

    // G-UNI
    // ============================================
    // {
    //     (uint256 reserve0, uint256 reserve1) = stakingToken.getUnderlyingBalances();
    //     uint256 total_frax_reserves = frax_is_token0 ? reserve0 : reserve1;

    //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
    // }

    // mStable
    // ============================================
    // {
    //     uint256 total_frax_reserves;
    //     (, IFeederPool.BassetData memory vaultData) = (stakingToken.getBasset(frax_address));
    //     total_frax_reserves = uint256(vaultData.vaultBalance);
    //     frax_per_lp_token = total_frax_reserves.mul(1e18).div(stakingToken.totalSupply());
    // }

    // StakeDAO sdETH-FraxPut Vault
    // ============================================
    // {
    //    uint256 frax3crv_held = stakingToken.totalUnderlyingControlled();

    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
    //    frax_per_lp_token = (frax3crv_held.mul(1e18).div(stakingToken.totalSupply())) / 2;
    // }

    // StakeDAO Vault
    // ============================================
    // {
    //    uint256 frax3crv_held = stakingToken.balance();
    //
    //    // Optimistically assume 50/50 FRAX/3CRV ratio in the metapool to save gas
    //    frax_per_lp_token = (frax3crv_held.mul(1e18).div(stakingToken.totalSupply())) / 2;
    // }

    // Uniswap V2
    // ============================================
    {
      uint256 total_usd_reserves;
      (uint256 reserve0, uint256 reserve1, ) = (stakingToken.getReserves());
      if (usd_is_token0) total_usd_reserves = reserve0;
      else total_usd_reserves = reserve1;

      usd_per_lp_token = total_usd_reserves.mul(1e18).div(stakingToken.totalSupply());
    }

    return usd_per_lp_token;
  }

  function userStakedUsd(address account) public view returns (uint256) {
    return (usdPerLPToken()).mul(_locked_liquidity[account]).div(1e18);
  }

  function minVeSumerForMaxBoost(address account) public view returns (uint256) {
    return (userStakedUsd(account)).mul(veSumer_per_usd_for_max_boost).div(MULTIPLIER_PRECISION);
  }

  function veSumerMultiplier(address account) public view returns (uint256) {
    // The claimer gets a boost depending on amount of veSumer they have relative to the amount of FRAX 'inside'
    // of their locked LP tokens
    uint256 veSumer_needed_for_max_boost = minVeSumerForMaxBoost(account);
    if (veSumer_needed_for_max_boost > 0) {
      uint256 user_veSumer_fraction = (veSUMER.balanceOf(account)).mul(MULTIPLIER_PRECISION).div(
        veSumer_needed_for_max_boost
      );

      uint256 veSumer_multiplier = ((user_veSumer_fraction).mul(veSumer_max_multiplier)).div(MULTIPLIER_PRECISION);

      // Cap the boost to the veSumer_max_multiplier
      if (veSumer_multiplier > veSumer_max_multiplier) veSumer_multiplier = veSumer_max_multiplier;

      return veSumer_multiplier;
    } else return 0; // This will happen with the first stake, when user_staked_frax is 0
  }

  // Calculated the combined weight for an account
  function calcCurCombinedWeight(
    address account
  ) public view returns (uint256 old_combined_weight, uint256 new_veSumer_multiplier, uint256 new_combined_weight) {
    // Get the old combined weight
    old_combined_weight = _combined_weights[account];

    // Get the veSumer multipliers
    // For the calculations, use the midpoint (analogous to midpoint Riemann sum)
    new_veSumer_multiplier = veSumerMultiplier(account);

    uint256 midpoint_veSumer_multiplier;
    if (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) {
      // This is only called for the first stake to make sure the veSumer multiplier is not cut in half
      midpoint_veSumer_multiplier = new_veSumer_multiplier;
    } else {
      midpoint_veSumer_multiplier = ((new_veSumer_multiplier).add(_veSumerMultiplierStored[account])).div(2);
    }

    // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
    new_combined_weight = 0;
    for (uint256 i = 0; i < lockedStakes[account].length; i++) {
      LockedStake memory thisStake = lockedStakes[account][i];
      uint256 lock_multiplier = thisStake.lock_multiplier;

      // If the lock is expired
      if (thisStake.ending_timestamp <= block.timestamp) {
        // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
        if (lastRewardClaimTime[account] < thisStake.ending_timestamp) {
          uint256 time_before_expiry = (thisStake.ending_timestamp).sub(lastRewardClaimTime[account]);
          uint256 time_after_expiry = (block.timestamp).sub(thisStake.ending_timestamp);

          // Get the weighted-average lock_multiplier
          uint256 numerator = ((lock_multiplier).mul(time_before_expiry)).add(
            ((MULTIPLIER_PRECISION).mul(time_after_expiry))
          );
          lock_multiplier = numerator.div(time_before_expiry.add(time_after_expiry));
        }
        // Otherwise, it needs to just be 1x
        else {
          lock_multiplier = MULTIPLIER_PRECISION;
        }
      }

      uint256 liquidity = thisStake.liquidity;
      uint256 combined_boosted_amount = liquidity.mul(lock_multiplier.add(midpoint_veSumer_multiplier)).div(
        MULTIPLIER_PRECISION
      );
      new_combined_weight = new_combined_weight.add(combined_boosted_amount);
    }
  }

  // All the locked stakes for a given account
  function lockedStakesOf(address account) external view returns (LockedStake[] memory) {
    return lockedStakes[account];
  }

  // All the locked stakes for a given account
  function getRewardSymbols() external view returns (string[] memory) {
    return rewardSymbols;
  }

  // All the reward tokens
  function getAllRewardTokens() external view returns (address[] memory) {
    return rewardTokens;
  }

  // Multiplier amount, given the length of the lock
  function lockMultiplier(uint256 secs) public view returns (uint256) {
    uint256 lock_multiplier = uint256(MULTIPLIER_PRECISION).add(
      secs.mul(lock_max_multiplier.sub(MULTIPLIER_PRECISION)).div(lock_time_for_max_multiplier)
    );
    if (lock_multiplier > lock_max_multiplier) lock_multiplier = lock_max_multiplier;
    return lock_multiplier;
  }

  // Last time the reward was applicable
  function lastTimeRewardApplicable() internal view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardRates(uint256 token_idx) public view returns (uint256 rwd_rate) {
    address gauge_controller_address = gaugeControllers[token_idx];
    if (gauge_controller_address != address(0)) {
      rwd_rate = (IFraxGaugeController(gauge_controller_address).global_emission_rate())
        .mul(last_gauge_relative_weights[token_idx])
        .div(1e18);
    } else {
      rwd_rate = rewardRatesManual[token_idx];
    }
  }

  // Amount of reward tokens per LP token
  function rewardsPerToken() public view returns (uint256[] memory newRewardsPerTokenStored) {
    if (_total_liquidity_locked == 0 || _total_combined_weight == 0) {
      return rewardsPerTokenStored;
    } else {
      newRewardsPerTokenStored = new uint256[](rewardTokens.length);
      for (uint256 i = 0; i < rewardsPerTokenStored.length; i++) {
        newRewardsPerTokenStored[i] = rewardsPerTokenStored[i].add(
          lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRates(i)).mul(1e18).div(_total_combined_weight)
        );
      }
      return newRewardsPerTokenStored;
    }
  }

  // Amount of reward tokens an account has earned / accrued
  // Note: In the edge-case of one of the account's stake expiring since the last claim, this will
  // return a slightly inflated number
  function earned(address account) public view returns (uint256[] memory new_earned) {
    uint256[] memory reward_arr = rewardsPerToken();
    new_earned = new uint256[](rewardTokens.length);

    if (_combined_weights[account] == 0) {
      for (uint256 i = 0; i < rewardTokens.length; i++) {
        new_earned[i] = 0;
      }
    } else {
      for (uint256 i = 0; i < rewardTokens.length; i++) {
        new_earned[i] = (_combined_weights[account])
          .mul(reward_arr[i].sub(userRewardsPerTokenPaid[account][i]))
          .div(1e18)
          .add(rewards[account][i]);
      }
    }
  }

  // Total reward tokens emitted in the given period
  function getRewardForDuration() external view returns (uint256[] memory rewards_per_duration_arr) {
    rewards_per_duration_arr = new uint256[](rewardRatesManual.length);

    for (uint256 i = 0; i < rewardRatesManual.length; i++) {
      rewards_per_duration_arr[i] = rewardRates(i).mul(rewardsDuration);
    }
  }

  // See if the caller_addr is a manager for the reward token
  function isTokenManagerFor(address caller_addr, address reward_token_addr) public view returns (bool) {
    if (caller_addr == owner()) return true;
    // Contract owner
    else if (rewardManagers[reward_token_addr] == caller_addr) return true; // Reward manager
    return false;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  // Staker can allow a migrator
  function stakerAllowMigrator(address migrator_address) external {
    require(valid_migrators[migrator_address], 'Invalid migrator address');
    staker_allowed_migrators[msg.sender][migrator_address] = true;
  }

  // Staker can disallow a previously-allowed migrator
  function stakerDisallowMigrator(address migrator_address) external {
    // Delete from the mapping
    delete staker_allowed_migrators[msg.sender][migrator_address];
  }

  function _updateRewardAndBalance(address account, bool sync_too) internal {
    // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
    if (sync_too) {
      sync();
    }

    if (account != address(0)) {
      // To keep the math correct, the user's combined weight must be recomputed to account for their
      // ever-changing veSumer balance.
      (
        uint256 old_combined_weight,
        uint256 new_veSumer_multiplier,
        uint256 new_combined_weight
      ) = calcCurCombinedWeight(account);

      // Calculate the earnings first
      _syncEarned(account);

      // Update the user's stored veSumer multipliers
      _veSumerMultiplierStored[account] = new_veSumer_multiplier;

      // Update the user's and the global combined weights
      if (new_combined_weight >= old_combined_weight) {
        uint256 weight_diff = new_combined_weight.sub(old_combined_weight);
        _total_combined_weight = _total_combined_weight.add(weight_diff);
        _combined_weights[account] = old_combined_weight.add(weight_diff);
      } else {
        uint256 weight_diff = old_combined_weight.sub(new_combined_weight);
        _total_combined_weight = _total_combined_weight.sub(weight_diff);
        _combined_weights[account] = old_combined_weight.sub(weight_diff);
      }
    }
  }

  function _syncEarned(address account) internal {
    if (account != address(0)) {
      // Calculate the earnings
      uint256[] memory earned_arr = earned(account);

      // Update the rewards array
      for (uint256 i = 0; i < earned_arr.length; i++) {
        rewards[account][i] = earned_arr[i];
      }

      // Update the rewards paid array
      for (uint256 i = 0; i < earned_arr.length; i++) {
        userRewardsPerTokenPaid[account][i] = rewardsPerTokenStored[i];
      }
    }
  }

  // Two different stake functions are needed because of delegateCall and msg.sender issues
  function stakeLocked(uint256 liquidity, uint256 secs) public nonReentrant {
    _stakeLocked(msg.sender, msg.sender, liquidity, secs, block.timestamp);
  }

  // If this were not internal, and source_address had an infinite approve, this could be exploitable
  // (pull funds from source_address and stake for an arbitrary staker_address)
  function _stakeLocked(
    address staker_address,
    address source_address,
    uint256 liquidity,
    uint256 secs,
    uint256 start_timestamp
  ) internal updateRewardAndBalance(staker_address, true) {
    require(!stakingPaused, 'Staking paused');
    require(liquidity > 0, 'Must stake more than zero');
    require(greylist[staker_address] == false, 'Address has been greylisted');
    require(secs >= lock_time_min, 'Minimum stake time not met');
    require(secs <= lock_time_for_max_multiplier, 'Trying to lock for too long');

    uint256 lock_multiplier = lockMultiplier(secs);
    bytes32 kek_id = keccak256(
      abi.encodePacked(staker_address, start_timestamp, liquidity, _locked_liquidity[staker_address])
    );
    lockedStakes[staker_address].push(
      LockedStake(kek_id, start_timestamp, liquidity, start_timestamp.add(secs), lock_multiplier)
    );

    // Pull the tokens from the source_address
    TransferHelper.safeTransferFrom(address(stakingToken), source_address, address(this), liquidity);

    // Update liquidities
    _total_liquidity_locked = _total_liquidity_locked.add(liquidity);
    _locked_liquidity[staker_address] = _locked_liquidity[staker_address].add(liquidity);

    // Need to call to update the combined weights
    _updateRewardAndBalance(staker_address, true);

    // Needed for edge case if the staker only claims once, and after the lock expired
    if (lastRewardClaimTime[staker_address] == 0) lastRewardClaimTime[staker_address] = block.timestamp;

    emit StakeLocked(staker_address, liquidity, secs, kek_id, source_address);
  }

  // Two different withdrawLocked functions are needed because of delegateCall and msg.sender issues
  function withdrawLocked(bytes32 kek_id) public nonReentrant {
    require(withdrawalsPaused == false, 'Withdrawals paused');
    _withdrawLocked(msg.sender, msg.sender, kek_id);
  }

  // No withdrawer == msg.sender check needed since this is only internally callable and the checks are done in the wrapper
  // functions like withdraw(), migrator_withdraw_unlocked() and migrator_withdraw_locked()
  function _withdrawLocked(address staker_address, address destination_address, bytes32 kek_id) internal {
    // Collect rewards first and then update the balances
    _getReward(staker_address, destination_address);

    LockedStake memory thisStake;
    thisStake.liquidity = 0;
    uint theArrayIndex;
    for (uint256 i = 0; i < lockedStakes[staker_address].length; i++) {
      if (kek_id == lockedStakes[staker_address][i].kek_id) {
        thisStake = lockedStakes[staker_address][i];
        theArrayIndex = i;
        break;
      }
    }
    require(thisStake.kek_id == kek_id, 'Stake not found');
    require(
      block.timestamp >= thisStake.ending_timestamp || stakesUnlocked == true || valid_migrators[msg.sender] == true,
      'Stake is still locked!'
    );

    uint256 liquidity = thisStake.liquidity;

    if (liquidity > 0) {
      // Update liquidities
      _total_liquidity_locked = _total_liquidity_locked.sub(liquidity);
      _locked_liquidity[staker_address] = _locked_liquidity[staker_address].sub(liquidity);

      // Remove the stake from the array
      delete lockedStakes[staker_address][theArrayIndex];

      // Need to call to update the combined weights
      _updateRewardAndBalance(staker_address, false);

      // Give the tokens to the destination_address
      // Should throw if insufficient balance
      stakingToken.transfer(destination_address, liquidity);

      emit WithdrawLocked(staker_address, liquidity, kek_id, destination_address);
    }
  }

  // Two different getReward functions are needed because of delegateCall and msg.sender issues
  function getReward() external nonReentrant returns (uint256[] memory) {
    require(rewardsCollectionPaused == false, 'Rewards collection paused');
    return _getReward(msg.sender, msg.sender);
  }

  // No withdrawer == msg.sender check needed since this is only internally callable
  function _getReward(
    address rewardee,
    address destination_address
  ) internal updateRewardAndBalance(rewardee, true) returns (uint256[] memory rewards_before) {
    // Update the rewards array and distribute rewards
    rewards_before = new uint256[](rewardTokens.length);

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      rewards_before[i] = rewards[rewardee][i];
      rewards[rewardee][i] = 0;
      ERC20(rewardTokens[i]).transfer(destination_address, rewards_before[i]);
      emit RewardPaid(rewardee, rewards_before[i], rewardTokens[i], destination_address);
    }

    lastRewardClaimTime[rewardee] = block.timestamp;
  }

  error NoEnoughReward(
    address token,
    uint256 rewardRates,
    uint256 rewardsDuration,
    uint256 num_periods_elapsed,
    uint256 balance
  );

  // If the period expired, renew it
  function retroCatchUp() internal {
    // Pull in rewards from the rewards distributor
    rewards_distributor.distributeReward(address(this));

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / rewardsDuration; // Floor division to the nearest period

    // Make sure there are enough tokens to renew the reward period
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      // require(
      //   rewardRates(i).mul(rewardsDuration).mul(num_periods_elapsed + 1) <=
      //     ERC20(rewardTokens[i]).balanceOf(address(this)),
      //   string(abi.encodePacked('Not enough reward tokens available: ', rewardTokens[i]))
      // );
      if (
        rewardRates(i).mul(rewardsDuration).mul(num_periods_elapsed + 1) >
        ERC20(rewardTokens[i]).balanceOf(address(this))
      ) {
        revert NoEnoughReward(
          rewardTokens[i],
          rewardRates(i),
          rewardsDuration,
          num_periods_elapsed,
          ERC20(rewardTokens[i]).balanceOf(address(this))
        );
      }
    }

    // uint256 old_lastUpdateTime = lastUpdateTime;
    // uint256 new_lastUpdateTime = block.timestamp;

    // lastUpdateTime = periodFinish;
    periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(rewardsDuration));

    _updateStoredRewardsAndTime();

    emit RewardsPeriodRenewed(address(stakingToken));
  }

  function _updateStoredRewardsAndTime() internal {
    // Get the rewards
    uint256[] memory rewards_per_token = rewardsPerToken();

    // Update the rewardsPerTokenStored
    for (uint256 i = 0; i < rewardsPerTokenStored.length; i++) {
      rewardsPerTokenStored[i] = rewards_per_token[i];
    }

    // Update the last stored time
    lastUpdateTime = lastTimeRewardApplicable();
  }

  function sync_gauge_weights(bool force_update) public {
    // Loop through the gauge controllers
    for (uint256 i = 0; i < gaugeControllers.length; i++) {
      address gauge_controller_address = gaugeControllers[i];
      if (gauge_controller_address != address(0)) {
        if (force_update || (block.timestamp > last_gauge_time_totals[i])) {
          // Update the gauge_relative_weight
          last_gauge_relative_weights[i] = IFraxGaugeController(gauge_controller_address).gauge_relative_weight_write(
            address(this),
            block.timestamp
          );
          last_gauge_time_totals[i] = IFraxGaugeController(gauge_controller_address).time_total();
        }
      }
    }
  }

  function sync() public {
    // Sync the gauge weight, if applicable
    sync_gauge_weights(false);

    if (block.timestamp >= periodFinish) {
      retroCatchUp();
    } else {
      _updateStoredRewardsAndTime();
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  // Migrator can stake for someone else (they won't be able to withdraw it back though, only staker_address can).
  function migrator_stakeLocked_for(
    address staker_address,
    uint256 amount,
    uint256 secs,
    uint256 start_timestamp
  ) external isMigrating {
    require(
      staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender],
      'Mig. invalid or unapproved'
    );
    _stakeLocked(staker_address, msg.sender, amount, secs, start_timestamp);
  }

  // Used for migrations
  function migrator_withdraw_locked(address staker_address, bytes32 kek_id) external isMigrating {
    require(
      staker_allowed_migrators[staker_address][msg.sender] && valid_migrators[msg.sender],
      'Mig. invalid or unapproved'
    );
    _withdrawLocked(staker_address, msg.sender, kek_id);
  }

  // Adds supported migrator address
  function addMigrator(address migrator_address) external onlyOwner {
    valid_migrators[migrator_address] = true;
  }

  // Remove a migrator address
  function removeMigrator(address migrator_address) external onlyOwner {
    require(valid_migrators[migrator_address] == true, 'Address nonexistent');

    // Delete from the mapping
    delete valid_migrators[migrator_address];
  }

  // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyTknMgrs(tokenAddress) {
    // Check if the desired token is a reward token
    bool isRewardToken = false;
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      if (rewardTokens[i] == tokenAddress) {
        isRewardToken = true;
        break;
      }
    }

    // Only the reward managers can take back their reward tokens
    if (isRewardToken && rewardManagers[tokenAddress] == msg.sender) {
      ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
      emit Recovered(msg.sender, tokenAddress, tokenAmount);
      return;
    }
    // Other tokens, like the staking token, airdrops, or accidental deposits, can be withdrawn by the owner
    else if (!isRewardToken && (msg.sender == owner())) {
      ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
      emit Recovered(msg.sender, tokenAddress, tokenAmount);
      return;
    }
    // If none of the above conditions are true
    else {
      revert('No valid tokens to recover');
    }
  }

  function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    require(_rewardsDuration >= 86400, 'Rewards duration too short');
    require(_rewardsDuration < 365 days, 'Rewards duration too long');
    require(periodFinish == 0 || block.timestamp > periodFinish, 'Reward period incomplete');
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  function setMultipliers(
    uint256 _lock_max_multiplier,
    uint256 _veSumer_max_multiplier,
    uint256 _veSumer_per_usd_for_max_boost
  ) external onlyOwner {
    require(_lock_max_multiplier >= MULTIPLIER_PRECISION, 'Mult must be >= MULTIPLIER_PRECISION');
    require(_veSumer_max_multiplier >= 0, 'veSumer mul must be >= 0');
    require(_veSumer_per_usd_for_max_boost > 0, 'veSumer pct max must be >= 0');

    lock_max_multiplier = _lock_max_multiplier;
    veSumer_max_multiplier = _veSumer_max_multiplier;
    veSumer_per_usd_for_max_boost = _veSumer_per_usd_for_max_boost;

    emit MaxVeSumerMultiplier(veSumer_max_multiplier);
    emit LockedStakeMaxMultiplierUpdated(lock_max_multiplier);
    emit veSumerPerUsdForMaxBoostUpdated(veSumer_per_usd_for_max_boost);
  }

  function setLockedStakeTimeForMinAndMaxMultiplier(
    uint256 _lock_time_for_max_multiplier,
    uint256 _lock_time_min
  ) external onlyOwner {
    require(_lock_time_for_max_multiplier >= 1, 'Mul max time must be >= 1');
    require(_lock_time_min >= 1, 'Mul min time must be >= 1');

    lock_time_for_max_multiplier = _lock_time_for_max_multiplier;
    lock_time_min = _lock_time_min;

    emit LockedStakeTimeForMaxMultiplier(lock_time_for_max_multiplier);
    emit LockedStakeMinTime(_lock_time_min);
  }

  function greylistAddress(address _address) external onlyOwner {
    greylist[_address] = !(greylist[_address]);
  }

  function unlockStakes() external onlyOwner {
    stakesUnlocked = !stakesUnlocked;
  }

  function toggleStaking() external onlyOwner {
    stakingPaused = !stakingPaused;
  }

  function toggleMigrations() external onlyOwner {
    migrationsOn = !migrationsOn;
  }

  function toggleWithdrawals() external onlyOwner {
    withdrawalsPaused = !withdrawalsPaused;
  }

  function toggleRewardsCollection() external onlyOwner {
    rewardsCollectionPaused = !rewardsCollectionPaused;
  }

  // The owner or the reward token managers can set reward rates
  function setRewardRate(
    address reward_token_address,
    uint256 new_rate,
    bool sync_too
  ) external onlyTknMgrs(reward_token_address) {
    require(new_rate > 0, 'new_rate=0');
    rewardRatesManual[rewardTokenAddrToIdx[reward_token_address]] = new_rate;

    if (sync_too) {
      sync();
    }
  }

  // The owner or the reward token managers can set reward rates
  function setGaugeController(
    address reward_token_address,
    address _rewards_distributor_address,
    address _gauge_controller_address,
    bool sync_too
  ) external onlyTknMgrs(reward_token_address) {
    gaugeControllers[rewardTokenAddrToIdx[reward_token_address]] = _gauge_controller_address;
    rewards_distributor = IFraxGaugeFXSRewardsDistributor(_rewards_distributor_address);

    if (sync_too) {
      sync();
    }
  }

  // The owner or the reward token managers can change managers
  function changeTokenManager(
    address reward_token_address,
    address new_manager_address
  ) external onlyTknMgrs(reward_token_address) {
    rewardManagers[reward_token_address] = new_manager_address;
  }

  /* ========== EVENTS ========== */

  event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);
  event WithdrawLocked(address indexed user, uint256 amount, bytes32 kek_id, address destination_address);
  event RewardPaid(address indexed user, uint256 reward, address token_address, address destination_address);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address destination_address, address token, uint256 amount);
  event RewardsPeriodRenewed(address token);
  event LockedStakeMaxMultiplierUpdated(uint256 multiplier);
  event LockedStakeTimeForMaxMultiplier(uint256 secs);
  event LockedStakeMinTime(uint256 secs);
  event MaxVeSumerMultiplier(uint256 multiplier);
  event veSumerPerUsdForMaxBoostUpdated(uint256 scale_factor);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
  }

  function safeTransferETH(address to, uint value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =============================== veFXS ==============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Original idea and credit:
// Curve Finance's veCRV
// https://resources.curve.fi/faq/vote-locking-boost
// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
// This is a Solidity version converted from Vyper by the Frax team
// Almost all of the logic / algorithms are the Curve team's

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

//@notice Votes have a weight depending on time, so that users are
//        committed to the future of (whatever they are voting for)
//@dev Vote weight decays linearly over time. Lock time cannot be
//     more than `MAXTIME` (3 years).

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './TransferHelper.sol';

// Inheritance
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

// # Interface for checking whether address belongs to a whitelisted
// # type of a smart wallet.
// # When new types are added - the whole contract is changed
// # The check() method is modifying to be able to use caching
// # for individual wallet addresses
interface SmartWalletChecker {
  function check(address addr) external returns (bool);
}

// We cannot really do block numbers per se b/c slope is per time, not per block
// and per block could be fairly bad b/c Ethereum changes blocktimes.
// What we can do is to extrapolate ***At functions
struct Point {
  int128 bias; // principal Sumer amount locked
  int128 slope; // dweight / dt
  uint256 ts;
  uint256 blk; // block
  uint256 sumer_amt;
}
// We cannot really do block numbers per se b/c slope is per time, not per block
// and per block could be fairly bad b/c Ethereum changes blocktimes.
// What we can do is to extrapolate ***At functions

struct LockedBalance {
  int128 amount;
  uint256 end;
}

contract VeSumer is ReentrancyGuard, Ownable2Step {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  /* ========== STATE VARIABLES ========== */
  // Flags
  int128 public constant DEPOSIT_FOR_TYPE = 0;
  int128 public constant CREATE_LOCK_TYPE = 1;
  int128 public constant INCREASE_LOCK_AMOUNT = 2;
  int128 public constant INCREASE_UNLOCK_TIME = 3;
  int128 public constant USER_WITHDRAW = 4;
  int128 public constant TRANSFER_FROM_APP = 5;
  int128 public constant PROXY_ADD = 7;
  int128 public constant PROXY_SLASH = 8;
  int128 public constant CHECKPOINT_ONLY = 9;
  address public constant ZERO_ADDRESS = address(0);

  /* ========== EVENTS ========== */
  event NominateOwnership(address admin);
  event AcceptOwnership(address admin);
  event Deposit(
    address indexed provider,
    address indexed payer_addr,
    uint256 value,
    uint256 indexed locktime,
    int128 _type,
    uint256 ts
  );
  event Withdraw(address indexed provider, address indexed to_addr, uint256 value, uint256 ts);
  event Supply(uint256 prevSupply, uint256 supply);
  event TransferFromApp(address indexed app_addr, address indexed staker_addr, uint256 transfer_amt);
  event ProxyAdd(address indexed staker_addr, address indexed proxy_addr, uint256 add_amt);
  event SmartWalletCheckerComitted(address future_smart_wallet_checker);
  event SmartWalletCheckerApplied(address smart_wallet_checker);
  event AppIncreaseAmountForsToggled(bool appIncreaseAmountForsEnabled);
  event ProxyTransferFromsToggled(bool appTransferFromsEnabled);
  event ProxyTransferTosToggled(bool appTransferTosEnabled);
  event ProxyAddsToggled(bool proxyAddsEnabled);
  event ProxySlashesToggled(bool proxySlashesEnabled);
  event LendingProxySet(address proxy_address);
  event HistoricalProxyToggled(address proxy_address, bool enabled);
  event StakerProxySet(address proxy_address);

  uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
  uint256 public constant MAXTIME = 4 * 365 * 86400; // 4 years
  int128 public constant MAXTIME_I128 = 4 * 365 * 86400; // 4 years
  uint256 public constant MULTIPLIER = 10 ** 18;
  int128 public constant VOTE_WEIGHT_MULTIPLIER_I128 = 4 - 1; // 4x gives 300% boost at 4 years

  address public token; // Sumer
  uint256 public supply; // Tracked Sumer in the contract

  mapping(address => LockedBalance) public locked; // user -> locked balance position info

  uint256 public epoch;
  Point[100000000000000000] public point_history; // epoch -> unsigned point
  // mapping(uint256 => Point) public point_history; // epoch -> unsigned point
  mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
  // mapping(address => mapping(uint256 => Point)) public user_point_history; // user -> Point[user_epoch]
  mapping(address => uint256) public user_point_epoch; // user -> last week epoch their slope and bias were checkpointed

  // time -> signed slope change. Stored ahead of time so we can keep track of expiring users.
  // Time will always be a multiple of 1 week
  mapping(uint256 => int128) public slope_changes; // time -> signed slope change

  // Misc
  bool public appIncreaseAmountForsEnabled; // Whether the proxy can directly deposit FPIS and increase a particular user's stake
  bool public appTransferFromsEnabled; // Whether Sumer can be received from apps or not
  bool public appTransferTosEnabled; // Whether Sumer can be sent to apps or not
  bool public proxyAddsEnabled; // Whether the proxy can add to the user's position
  bool public proxySlashesEnabled; // Whether the proxy can slash the user's position

  // Emergency Unlock
  bool public emergencyUnlockActive;

  // Proxies (allow withdrawal / deposits for lending protocols, etc.)
  address public current_proxy; // Set by admin. Can only be one at any given time
  mapping(address => bool) public historical_proxies; // Set by admin. Used for paying back / liquidating after the main current_proxy changes
  mapping(address => address) public staker_whitelisted_proxy; // user -> proxy. Set by user
  mapping(address => uint256) public user_proxy_balance; // user -> amount held in proxy

  // veSumer token related
  string public name;
  string public symbol;
  string public version;
  uint256 public decimals;
  // Checker for whitelisted (smart contract) wallets which are allowed to deposit
  // The goal is to prevent tokenizing the escrow
  address public future_smart_wallet_checker;
  address public smart_wallet_checker;

  address public admin; // Can and will be a smart contract
  address public future_admin;

  /* ========== MODIFIERS ========== */


  /* ========== CONSTRUCTOR ========== */
  // token_addr: address, _name: String[64], _symbol: String[32], _version: String[32]
  /**
   * @notice Contract constructor
   * @param sumer `ERC20CRV` token address
   */
  constructor(address sumer) {
    admin = msg.sender;
    token = sumer;
    point_history[0].blk = block.number;
    point_history[0].ts = block.timestamp;
    point_history[0].sumer_amt = 0;
    appTransferFromsEnabled = false;
    appTransferTosEnabled = false;
    proxyAddsEnabled = false;
    proxySlashesEnabled = false;

    uint256 _decimals = ERC20(sumer).decimals();
    assert(_decimals <= 255);
    decimals = _decimals;

    name = 'veSumer';
    symbol = 'veSumer';
    version = 'veSumer0.1';
  }

  /**
   * @notice Set an external contract to check for approved smart contract wallets
   * @param addr Address of Smart contract checker
   */
  function commit_smart_wallet_checker(address addr) external onlyOwner {
    future_smart_wallet_checker = addr;
    emit SmartWalletCheckerComitted(future_smart_wallet_checker);
  }

  /**
   * @notice Apply setting external contract to check approved smart contract wallets
   */
  function apply_smart_wallet_checker() external onlyOwner {
    smart_wallet_checker = future_smart_wallet_checker;
    emit SmartWalletCheckerApplied(smart_wallet_checker);
  }

  function recoverERC20(address token_addr, uint256 amount) external onlyOwner {
    require(token_addr != token, '!token_addr');
    ERC20(token_addr).transfer(admin, amount);
  }

  /**
   * @notice Check if the call is from a whitelisted smart contract, revert if not
   * @param addr Address to be checked
   */
  function assert_not_contract(address addr) internal {
    if (addr != tx.origin) {
      address checker = smart_wallet_checker;
      if (checker != ZERO_ADDRESS) {
        if (SmartWalletChecker(checker).check(addr)) {
          return;
        }
      }
      revert('depositors');
    }
  }

  /* ========== VIEWS ========== */
  /**
   * @notice Get the most recently recorded rate of voting power decrease for `addr`
   * @param addr Address of the user wallet
   * @return Value of the slope
   */
  function get_last_user_slope(address addr) external view returns (int128) {
    uint256 uepoch = user_point_epoch[addr];
    return user_point_history[addr][uepoch].slope;
  }

  function get_last_user_bias(address addr) external view returns (int128) {
    uint256 uepoch = user_point_epoch[addr];
    return user_point_history[addr][uepoch].bias;
  }

  function get_last_user_point(address addr) external view returns (Point memory) {
    uint256 uepoch = user_point_epoch[addr];
    return user_point_history[addr][uepoch];
  }

  /**
   * @notice Get the timestamp for checkpoint `_idx` for `_addr`
   * @param _addr User wallet address
   * @param _idx User epoch number
   * @return Epoch time of the checkpoint
   */
  function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256) {
    return user_point_history[_addr][_idx].ts;
  }

  function get_last_point() external view returns (Point memory) {
    return point_history[epoch];
  }

  /**
   * @notice Get timestamp when `_addr`'s lock finishes
   * @param _addr User wallet
   * @return Epoch time of the lock end
   */
  function locked__end(address _addr) external view returns (uint256) {
    return locked[_addr].end;
  }

  function locked__amount(address _addr) external view returns (int128) {
    return locked[_addr].amount;
  }

  function curr_period_start() external view returns (uint256) {
    return (block.timestamp / WEEK) * WEEK;
  }

  function next_period_start() external view returns (uint256) {
    return WEEK + (block.timestamp / WEEK) * WEEK;
  }

  // Constant structs not allowed yet, so this will have to do
  function EMPTY_POINT_FACTORY() internal pure returns (Point memory) {
    return Point({bias: 0, slope: 0, ts: 0, blk: 0, sumer_amt: 0});
  }

  /* ========== INTERNAL FUNCTIONS ========== */
  /**
   * @notice Record global and per-user data to checkpoint
   * @param addr User's wallet address. No user checkpoint if 0x0
   * @param old_locked Previous locked amount / end lock time for the user
   * @param new_locked New locked amount / end lock time for the user
   */
  function _checkpoint(
    address addr,
    LockedBalance memory old_locked,
    LockedBalance memory new_locked,
    int128 flag
  ) internal {
    Point memory usr_old_pt = EMPTY_POINT_FACTORY();
    Point memory usr_new_pt = EMPTY_POINT_FACTORY();
    int128 old_gbl_dslope = 0;
    int128 new_gbl_dslope = 0;
    uint256 _epoch = epoch;

    if (addr != ZERO_ADDRESS) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if ((old_locked.end > block.timestamp) && (old_locked.amount > 0)) {
        usr_old_pt.slope = (old_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / MAXTIME_I128;
        usr_old_pt.bias = old_locked.amount + (usr_old_pt.slope * int128(uint128(old_locked.end - block.timestamp)));
      }
      if ((new_locked.end > block.timestamp) && (new_locked.amount > 0)) {
        usr_new_pt.slope = (new_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / MAXTIME_I128;
        usr_new_pt.bias = new_locked.amount + (usr_new_pt.slope * int128(uint128(new_locked.end - block.timestamp)));
      }

      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
      old_gbl_dslope = slope_changes[old_locked.end];
      if (new_locked.end != 0) {
        if (new_locked.end == old_locked.end) {
          new_gbl_dslope = old_gbl_dslope;
        } else {
          new_gbl_dslope = slope_changes[new_locked.end];
        }
      }
    }

    Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number, sumer_amt: 0});
    if (_epoch > 0) {
      last_point = point_history[_epoch];
    }
    uint256 last_checkpoint = last_point.ts;

    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initial_last_point = last_point;

    uint256 block_slope = 0; // dblock/dt
    if (block.timestamp > last_point.ts) {
      block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
    }

    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 latest_checkpoint_ts = (last_checkpoint / WEEK) * WEEK;
    for (uint i = 0; i < 255; i++) {
      // Hopefully it won't happen that this won't get used in 4 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      latest_checkpoint_ts += WEEK;
      int128 d_slope = 0;
      if (latest_checkpoint_ts > block.timestamp) {
        latest_checkpoint_ts = block.timestamp;
      } else {
        d_slope = slope_changes[latest_checkpoint_ts];
      }
      last_point.bias -= last_point.slope * int128(uint128(latest_checkpoint_ts - last_checkpoint));

      last_point.slope += d_slope;

      if (last_point.bias < 0) {
        last_point.bias = 0; // This can happen
      }
      if (last_point.slope < 0) {
        last_point.slope = 0; // This cannot happen - just in case
      }
      last_checkpoint = latest_checkpoint_ts;
      last_point.ts = latest_checkpoint_ts;

      last_point.blk =
        initial_last_point.blk +
        (block_slope * (latest_checkpoint_ts - initial_last_point.ts)) /
        MULTIPLIER;
      _epoch += 1;

      if (latest_checkpoint_ts == block.timestamp) {
        last_point.blk = block.number;
        break;
      } else {
        point_history[_epoch] = last_point;
      }
    }

    epoch = _epoch;
    // Now point_history is filled until t=now

    if (addr != ZERO_ADDRESS) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      last_point.slope += (usr_new_pt.slope - usr_old_pt.slope);
      last_point.bias += (usr_new_pt.bias - usr_old_pt.bias);

      if (new_locked.amount > old_locked.amount) {
        last_point.sumer_amt += uint256(uint128(new_locked.amount - old_locked.amount));
        if (new_locked.amount < old_locked.amount) {
          last_point.sumer_amt -= uint256(uint128(old_locked.amount - new_locked.amount));
          // Subtract the bias if you are slashing after expiry
          if (flag == PROXY_SLASH && new_locked.end < block.timestamp) {
            // Net change is the delta
            last_point.bias += new_locked.amount;
            last_point.bias -= old_locked.amount;
          }
          // Remove the offset
          // Corner case to fix issue because emergency unlock allows withdrawal before expiry and disrupts the math
          if (new_locked.amount == 0) {
            if (!emergencyUnlockActive) {
              // Net change is the delta
              // last_point.bias += new_locked.amount WILL BE ZERO
              last_point.bias -= old_locked.amount;
            }
          }
        }
      }
      if (last_point.slope < 0) {
        last_point.slope = 0;
      }
      if (last_point.bias < 0) {
        last_point.bias = 0;
      }
    }

    // Record the changed point into history
    point_history[_epoch] = last_point;

    if (addr != ZERO_ADDRESS) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (old_locked.end > block.timestamp) {
        // old_gbl_dslope was <something> - usr_old_pt.slope, so we cancel that
        old_gbl_dslope += usr_old_pt.slope;
        if (new_locked.end == old_locked.end) {
          old_gbl_dslope -= usr_new_pt.slope; // It was a new deposit, not extension
        }
        slope_changes[old_locked.end] = old_gbl_dslope;
      }

      if (new_locked.end > block.timestamp) {
        if (new_locked.end > old_locked.end) {
          new_gbl_dslope -= usr_new_pt.slope; // old slope disappeared at this point
          slope_changes[new_locked.end] = new_gbl_dslope;
        }
        // else: we recorded it already in old_gbl_dslope
      }

      uint256 user_epoch = user_point_epoch[addr] + 1;
      user_point_epoch[addr] = user_epoch;
      usr_new_pt.ts = block.timestamp;
      usr_new_pt.blk = block.number;
      usr_new_pt.sumer_amt = uint128(locked[addr].amount);

      if (new_locked.end < block.timestamp) {
        usr_new_pt.bias = locked[addr].amount;
        usr_new_pt.slope = 0;
      }
      user_point_history[addr][user_epoch] = usr_new_pt;
    }
  }

  /**
   * @notice Deposit and lock tokens for a user
   * @param _staker_addr User's wallet address
   * @param _payer_addr Payer's wallet address
   * @param _value Amount to deposit
   * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
   * @param locked_balance Previous locked amount / timestamp
   */
  function _deposit_for(
    address _staker_addr,
    address _payer_addr,
    uint256 _value,
    uint256 unlock_time,
    LockedBalance memory locked_balance,
    int128 flag
  ) internal {
    require(ERC20(token).transferFrom(_payer_addr, address(this), _value), 'transfer failed');

    LockedBalance memory old_locked = locked_balance;
    uint256 supply_before = supply;

    LockedBalance memory new_locked = old_locked;

    supply = supply_before + _value;

    // Adding to existing lock, or if a lock is expired - creating a new one
    new_locked.amount += int128(uint128(_value));
    if (unlock_time != 0) {
      new_locked.end = unlock_time;
    }
    locked[_staker_addr] = new_locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_staker_addr, old_locked, new_locked, flag);

    emit Deposit(_staker_addr, _payer_addr, _value, new_locked.end, flag, block.timestamp);
    emit Supply(supply_before, supply_before + _value);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Record global data to checkpoint
   */
  function checkpoint() external {
    _checkpoint(ZERO_ADDRESS, EMPTY_LOCKED_BALANCE_FACTORY(), EMPTY_LOCKED_BALANCE_FACTORY(), 0);
  }

  /**
   * @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
   * @param _value Amount to deposit
   * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
   */
  function create_lock(uint256 _value, uint256 _unlock_time) external nonReentrant {
    assert_not_contract(msg.sender);
    uint256 unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks
    LockedBalance memory _locked = locked[msg.sender];

    require(_value > 0, '<=0');
    require(_locked.amount == 0, 'amount=0');
    require(unlock_time > block.timestamp, 'unlock_time');
    require(unlock_time <= block.timestamp + MAXTIME, 'MAXTIME');
    _deposit_for(msg.sender, msg.sender, _value, unlock_time, _locked, CREATE_LOCK_TYPE);
  }

  function _increase_amount(address _staker_addr, address _payer_addr, uint256 _value) internal {
    if (_payer_addr != current_proxy && !historical_proxies[_payer_addr]) {
      assert_not_contract(_payer_addr);
    }
    assert_not_contract(_staker_addr);

    LockedBalance memory _locked = locked[_staker_addr];

    require(_value > 0, '<=0');
    require(_locked.amount == 0, 'amount=0');
    require(_locked.end > block.timestamp, 'locked.end');
    _deposit_for(_staker_addr, _payer_addr, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
  }

  /**
   * @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
   * @param _value Amount of tokens to deposit and add to the lock
   */
  function increase_amount(uint256 _value) external nonReentrant {
    _increase_amount(msg.sender, msg.sender, _value);
  }

  function increase_amount_for(address _staker_addr, uint256 _value) external nonReentrant {
    require(appIncreaseAmountForsEnabled, 'Currently disabled');
    _increase_amount(_staker_addr, msg.sender, _value);
  }

  function checkpoint_user(address _staker_addr) external nonReentrant {
    LockedBalance memory _locked = locked[_staker_addr];
    require(_locked.amount > 0, '<=0');
    _deposit_for(_staker_addr, _staker_addr, 0, 0, _locked, CHECKPOINT_ONLY);
  }

  /**
   * @notice Extend the unlock time for `msg.sender` to `_unlock_time`
   * @param _unlock_time New epoch time for unlocking
   */
  function increase_unlock_time(uint256 _unlock_time) external nonReentrant {
    assert_not_contract(msg.sender);
    LockedBalance memory _locked = locked[msg.sender];
    uint256 unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

    require(_locked.end > block.timestamp, 'locked.end');
    require(_locked.amount > 0, '=0');
    require(unlock_time > _locked.end, 'unlock_time');
    require(unlock_time <= block.timestamp + MAXTIME, 'MAXTIME');

    _deposit_for(msg.sender, msg.sender, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
  }

  /**
   * @notice Withdraw all tokens for `msg.sender`ime`
   * @dev Only possible if the lock has expired
   */
  function _withdraw(
    address staker_addr,
    address addr_out,
    LockedBalance memory locked_in,
    int128 amount_in,
    int128 flag
  ) internal {
    require(amount_in >= 0 && amount_in <= locked_in.amount, 'amount');

    LockedBalance memory _locked = locked_in;
    // require(block.timestamp >= _locked.end, "The lock didn't expire");
    uint256 value = uint128(_locked.amount);

    LockedBalance memory old_locked = _locked;
    if (amount_in == _locked.amount) {
      _locked.end = 0;
    }
    _locked.amount -= amount_in;

    locked[staker_addr] = _locked;
    uint256 supply_before = supply;
    supply = supply_before - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount
    _checkpoint(staker_addr, old_locked, _locked, flag);

    require(ERC20(token).transfer(msg.sender, value), 'transfer failed');

    emit Withdraw(staker_addr, addr_out, value, block.timestamp);
    emit Supply(supply_before, supply_before - value);
  }

  function proxy_add(address _staker_addr, uint256 _add_amt) external nonReentrant {
    require(proxyAddsEnabled, 'Currently disabled');
    require(msg.sender == current_proxy || historical_proxies[msg.sender], 'Whitelisted[admin level]');
    require(msg.sender == staker_whitelisted_proxy[_staker_addr], 'Whitelisted[staker level]');

    LockedBalance memory old_locked = locked[_staker_addr];
    // uint256 _proxy_balance = user_proxy_balance[_staker_addr];

    require(old_locked.amount > 0, 'No existing lock found');
    require(_add_amt > 0, 'Amount must be non-zero');

    user_proxy_balance[_staker_addr] += _add_amt;
    uint256 supply_before = supply;

    LockedBalance memory new_locked = old_locked;

    supply += _add_amt;

    new_locked.amount += int128(uint128(_add_amt));
    locked[_staker_addr] = new_locked;

    _checkpoint(_staker_addr, old_locked, new_locked, PROXY_ADD);

    emit ProxyAdd(_staker_addr, msg.sender, _add_amt);
    emit Supply(supply_before, supply_before + _add_amt);
  }

  function proxy_slash(address _staker_addr, uint256 _slash_amt) external nonReentrant {
    require(proxyAddsEnabled, 'Currently disabled');
    require(msg.sender == current_proxy || historical_proxies[msg.sender], 'Whitelisted[admin level]');
    require(msg.sender == staker_whitelisted_proxy[_staker_addr], 'whitelisted[staker level]');

    LockedBalance memory old_locked = locked[_staker_addr];
    // uint256 _proxy_balance = user_proxy_balance[_staker_addr];

    require(old_locked.amount > 0, 'No existing lock found');
    require(_slash_amt > 0, 'Amount must be non-zero');

    require(user_proxy_balance[_staker_addr] >= _slash_amt, 'user_proxy_balance');
    user_proxy_balance[_staker_addr] -= _slash_amt;

    uint256 supply_before = supply;

    LockedBalance memory new_locked = old_locked;
    supply -= _slash_amt;

    new_locked.amount -= int128(uint128(_slash_amt));
    locked[_staker_addr] = new_locked;

    _checkpoint(_staker_addr, old_locked, new_locked, PROXY_SLASH);
    emit ProxyAdd(_staker_addr, msg.sender, _slash_amt);
    emit Supply(supply_before, supply_before + _slash_amt);
  }

  function withdraw() external nonReentrant {
    LockedBalance memory _locked = locked[msg.sender];

    require(block.timestamp >= _locked.end || emergencyUnlockActive, 'locked.end');
    require(user_proxy_balance[msg.sender] == 0, 'user_proxy_balance');

    _withdraw(msg.sender, msg.sender, _locked, _locked.amount, USER_WITHDRAW);
  }

  function transfer_from_app(address _staker_addr, address _app_addr, int128 _transfer_amt) external nonReentrant {
    require(appTransferFromsEnabled, 'Currently disabled');
    require(msg.sender == current_proxy || historical_proxies[msg.sender], 'whitelisted[admin level]');
    require(msg.sender == staker_whitelisted_proxy[_staker_addr], 'whitelisted[staker level]');

    LockedBalance memory _locked = locked[_staker_addr];
    require(_locked.amount > 0, '_locked.amount');

    uint256 _value = uint128(_transfer_amt);
    require(user_proxy_balance[_staker_addr] >= _value, 'user_proxy_balance');
    user_proxy_balance[_staker_addr] -= _value;

    require(ERC20(token).transferFrom(_app_addr, address(this), _value), 'transfer failed');
    _checkpoint(_staker_addr, _locked, _locked, TRANSFER_FROM_APP);
    emit TransferFromApp(_app_addr, _staker_addr, _value);
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Constant structs not allowed yet, so this will have to do
  function EMPTY_LOCKED_BALANCE_FACTORY() internal pure returns (LockedBalance memory) {
    return LockedBalance({amount: 0, end: 0});
  }

  /**
   * @notice Get the current voting power for `msg.sender` at the specified timestamp
   * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
   * @param addr User wallet address
   * @param _t Epoch time to return voting power at
   * @return User voting power
   */
  function balanceOf(address addr, uint256 _t) public view returns (uint256) {
    uint256 _epoch = user_point_epoch[addr];
    if (_epoch == 0) {
      return 0;
    } else {
      Point memory last_point = user_point_history[addr][_epoch];
      last_point.bias -= last_point.slope * (int128(uint128(_t)) - int128(uint128(last_point.ts)));
      if (last_point.bias < 0) {
        last_point.bias = 0;
      }
      return uint256(int256(last_point.bias));
    }
  }

  /**
   * @notice Get the current voting power for `msg.sender` at the current timestamp
   * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
   * @param addr User wallet address
   * @return User voting power
   */
  function balanceOf(address addr) public view returns (uint256) {
    return balanceOf(addr, block.timestamp);
  }

  /**
   * @notice Measure voting power of `addr` at block height `_block`
   * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
   * @param addr User's wallet address
   * @param _block Block to calculate the voting power at
   * @return Voting power
   */
  function balanceOfAt(address addr, uint256 _block) external view returns (uint256) {
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    require(_block <= block.number);

    // Binary search
    uint256 _min = 0;
    uint256 _max = user_point_epoch[addr];

    // Will be always enough for 128-bit numbers
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (user_point_history[addr][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory upoint = user_point_history[addr][_min];

    uint256 max_epoch = epoch;
    uint256 _epoch = find_block_epoch(_block, max_epoch);
    Point memory point_0 = point_history[_epoch];
    uint256 d_block = 0;
    uint256 d_t = 0;

    if (_epoch < max_epoch) {
      Point memory point_1 = point_history[_epoch + 1];
      d_block = point_1.blk - point_0.blk;
      d_t = point_1.ts - point_0.ts;
    } else {
      d_block = block.number - point_0.blk;
      d_t = block.timestamp - point_0.ts;
    }

    uint256 block_time = point_0.ts;
    if (d_block != 0) {
      block_time += (d_t * (_block - point_0.blk)) / d_block;
    }

    upoint.bias -= upoint.slope * (int128(uint128(block_time)) - int128(uint128(upoint.ts)));
    if (upoint.bias >= 0) {
      return uint256(int256(upoint.bias));
    } else {
      return 0;
    }
  }

  /**
   * @notice Calculate total voting power at the specified timestamp
   * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
   * @return Total voting power
   */
  function totalSupply(uint256 t) public view returns (uint256) {
    uint256 _epoch = epoch;
    Point memory last_point = point_history[_epoch];
    return supply_at(last_point, t);
  }

  /**
   * @notice Calculate total voting power at the current timestamp
   * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
   * @return Total voting power
   */
  function totalSupply() public view returns (uint256) {
    return totalSupply(block.timestamp);
  }

  /**
   * @notice Calculate total voting power at some point in the past
   * @param _block Block to calculate the total voting power at
   * @return Total voting power at `_block`
   */
  function totalSupplyAt(uint256 _block) external view returns (uint256) {
    require(_block <= block.number);
    uint256 _epoch = epoch;
    uint256 target_epoch = find_block_epoch(_block, _epoch);

    Point memory point = point_history[target_epoch];
    uint256 dt = 0;

    if (target_epoch < _epoch) {
      Point memory point_next = point_history[target_epoch + 1];
      if (point.blk != point_next.blk) {
        dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
      }
    } else {
      if (point.blk != block.number) {
        dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }

    // Now dt contains info on how far are we beyond point
    return supply_at(point, point.ts + dt);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.
  /**
   * @notice Binary search to estimate timestamp for block number
   * @param _block Block to find
   * @param max_epoch Don't go beyond this epoch
   * @return Approximate timestamp for block
   */
  function find_block_epoch(uint256 _block, uint256 max_epoch) internal view returns (uint256) {
    // Binary search
    uint256 _min = 0;
    uint256 _max = max_epoch;

    // Will be always enough for 128-bit numbers
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (point_history[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    return _min;
  }

  /**
   * @notice Calculate total voting power at some point in the past
   * @param point The point (bias/slope) to start search from
   * @param t Time to calculate the total voting power at
   * @return Total voting power at that time
   */
  function supply_at(Point memory point, uint256 t) internal view returns (uint256) {
    Point memory last_point = point;
    uint256 t_i = (last_point.ts / WEEK) * WEEK;

    for (uint i = 0; i < 255; i++) {
      t_i += WEEK;
      int128 d_slope = 0;
      if (t_i > t) {
        t_i = t;
      } else {
        d_slope = slope_changes[t_i];
      }
      last_point.bias -= last_point.slope * (int128(uint128(t_i)) - int128(uint128(last_point.ts)));
      if (t_i == t) {
        break;
      }
      last_point.slope += d_slope;
      last_point.ts = t_i;
    }

    if (last_point.bias < 0) {
      last_point.bias = 0;
    }
    return uint256(int256(last_point.bias));
  }

  /**
        * @notice Deposit and lock tokens for a user
        * @dev Anyone (even a smart contract) can deposit for someone else, but
        cannot extend their locktime and deposit for a brand new user
        * @param _addr User's wallet address
        * @param _value Amount to add to user's lock
    */
  function deposit_for(address _addr, uint256 _value) external nonReentrant {
    LockedBalance memory _locked = locked[_addr];
    require(_value > 0, '=0');
    require(_locked.amount > 0, 'locked.amount');
    require(_locked.end > block.timestamp, 'locked.end');
    _deposit_for(_addr, msg.sender, _value, 0, locked[_addr], DEPOSIT_FOR_TYPE);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './ITimelock.sol';

interface ICToken {
  function underlying() external view returns (address);

  function isCEther() external view returns (bool);
}

contract Timelock is ITimelock, AccessControlEnumerable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 public constant EMERGENCY_ADMIN = keccak256('EMERGENCY_ADMIN');
  /// @notice user => agreements ids set
  mapping(address => EnumerableSet.UintSet) private _userAgreements;
  /// @notice ids => agreement
  mapping(uint256 => Agreement) private agreements;
  /// @notice cToken => underlying
  mapping(address => address) public cTokenToUnderlying;
  /// @notice underlying => underlyDetial
  mapping(address => Underlying) public underlyingDetail;
  uint256 public agreementCount;
  bool public frozen;

  constructor(address[] memory cTokens) {
    for (uint i; i < cTokens.length; ++i) {
      address cToken = cTokens[i];
      require(cToken != address(0), 'cToken is zero');
      address underlying;
      if (ICToken(cToken).isCEther()) {
        underlying = address(1);
      } else {
        underlying = ICToken(cToken).underlying();
      }
      require(underlying != address(0), 'underlying is zero');
      cTokenToUnderlying[cToken] = underlying;
      underlyingDetail[underlying].cToken = cToken;
      underlyingDetail[underlying].isSupport = true;
    }
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(EMERGENCY_ADMIN, msg.sender);
  }

  receive() external payable {}

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'CALLER_NOT_ADMIN');
    _;
  }

  modifier onlyEmergencyAdmin() {
    require(hasRole(EMERGENCY_ADMIN, msg.sender), 'CALLER_NOT_EMERGENCY_ADMIN');
    _;
  }

  modifier onlyCToken(address underlying) {
    require(cTokenToUnderlying[msg.sender] == underlying && underlying != address(0), 'CALLER_NOT_CTOKEN');
    require(underlyingDetail[underlying].isSupport, 'NOT_SUPPORT');
    _;
  }

  function setUnderly(address cToken, address underlying, bool isSupport) external onlyAdmin {
    cTokenToUnderlying[cToken] = underlying;
    underlyingDetail[underlying].cToken = cToken;
    underlyingDetail[underlying].isSupport = isSupport;
  }

  function setLockDuration(address underlying, uint256 lockDuration) external onlyAdmin {
    underlyingDetail[underlying].lockDuration = lockDuration;
  }

  function rescueERC20(address token, address to, uint256 amount) external onlyEmergencyAdmin {
    IERC20(token).safeTransfer(to, amount);
    emit RescueERC20(token, to, amount);
  }

  function createAgreement(
    TimeLockActionType actionType,
    address underlying,
    uint256 amount,
    address beneficiary
  ) external onlyCToken(underlying) returns (uint256) {
    require(beneficiary != address(0), 'Beneficiary cant be zero address');
    uint256 underlyBalance;
    if (underlying == address(1)) {
      underlyBalance = address(this).balance;
    } else {
      underlyBalance = IERC20(underlying).balanceOf(address(this));
    }
    require(underlyBalance >= underlyingDetail[underlying].totalBalance + amount, 'balance error');
    underlyingDetail[underlying].totalBalance = underlyBalance;

    uint256 agreementId = agreementCount++;
    uint256 releaseTime = block.timestamp + underlyingDetail[underlying].lockDuration;
    agreements[agreementId] = Agreement({
      actionType: actionType,
      underlying: underlying,
      amount: amount,
      beneficiary: beneficiary,
      releaseTime: releaseTime,
      isFrozen: false,
      agreementId: agreementId
    });
    _userAgreements[beneficiary].add(agreementId);

    emit AgreementCreated(agreementId, actionType, underlying, amount, beneficiary, releaseTime);
    return agreementId;
  }

  function _validateAndDeleteAgreement(uint256 agreementId) internal returns (Agreement memory) {
    Agreement memory agreement = agreements[agreementId];
    require(msg.sender == agreement.beneficiary, 'Not beneficiary');
    require(block.timestamp >= agreement.releaseTime, 'Release time not reached');
    require(!agreement.isFrozen, 'Agreement frozen');
    delete agreements[agreementId];
    _userAgreements[agreement.beneficiary].remove(agreementId);

    emit AgreementClaimed(
      agreementId,
      agreement.actionType,
      agreement.underlying,
      agreement.amount,
      agreement.beneficiary
    );

    return agreement;
  }

  function claim(uint256[] calldata agreementIds) external nonReentrant {
    require(!frozen, 'TimeLock is frozen');

    for (uint256 index = 0; index < agreementIds.length; index++) {
      Agreement memory agreement = _validateAndDeleteAgreement(agreementIds[index]);
      if (agreement.underlying == address(1)) {
        // payable(agreement.beneficiary).transfer(agreement.amount);
        Address.sendValue(payable(agreement.beneficiary), agreement.amount);
      } else {
        IERC20(agreement.underlying).safeTransfer(agreement.beneficiary, agreement.amount);
      }
      underlyingDetail[agreement.underlying].totalBalance -= agreement.amount;
    }
  }

  function underlyingDetails(address[] calldata underlyings) external view returns (Underlying[] memory) {
    uint256 underlyingLength = underlyings.length;
    Underlying[] memory underlyingDetails = new Underlying[](underlyingLength);
    for (uint256 i; i < underlyingLength; ++i) {
      underlyingDetails[i] = underlyingDetail[underlyings[i]];
    }
    return underlyingDetails;
  }

  function userAgreements(address user) external view returns (Agreement[] memory) {
    uint256 agreementLength = _userAgreements[user].length();
    Agreement[] memory userAgreements = new Agreement[](agreementLength);
    for (uint256 i; i < agreementLength; ++i) {
      userAgreements[i] = agreements[_userAgreements[user].at(i)];
    }
    return userAgreements;
  }

  function isSupport(address underlying) external view returns (bool) {
    return underlyingDetail[underlying].isSupport;
  }

  function freezeAgreement(uint256 agreementId) external onlyEmergencyAdmin {
    agreements[agreementId].isFrozen = true;
    emit AgreementFrozen(agreementId, true);
  }

  function freezeAllAgreements() external onlyEmergencyAdmin {
    frozen = true;
    emit TimeLockFrozen(true);
  }

  function unfreezeAllAgreements() external onlyAdmin {
    frozen = false;
    emit TimeLockFrozen(false);
  }
}