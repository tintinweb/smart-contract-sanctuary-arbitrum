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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library LiquityMath {
  using SafeMath for uint;

  uint internal constant DECIMAL_PRECISION = 1e18;

  /* Precision for Nominal ICR (independent of price). Rationale for the value:
   *
   * - Making it “too high” could lead to overflows.
   * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
   *
   * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
   * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
   *
   */
  uint internal constant NICR_PRECISION = 1e20;

  function _min(uint _a, uint _b) internal pure returns (uint) {
    return (_a < _b) ? _a : _b;
  }

  function _max(uint _a, uint _b) internal pure returns (uint) {
    return (_a >= _b) ? _a : _b;
  }

  /*
   * Multiply two decimal numbers and use normal rounding rules:
   * -round product up if 19'th mantissa digit >= 5
   * -round product down if 19'th mantissa digit < 5
   *
   * Used only inside the exponentiation, _decPow().
   */
  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x.mul(y);

    decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
  }

  /*
   * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
   *
   * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
   *
   * Called by two functions that represent time in units of minutes:
   * 1) TroveManager._calcDecayedBaseRate
   * 2) CommunityIssuance._getCumulativeIssuanceFraction
   *
   * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
   * "minutes in 1000 years": 60 * 24 * 365 * 1000
   *
   * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
   * negligibly different from just passing the cap, since:
   *
   * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
   * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
   */
  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
    if (_minutes > 525600000) {
      _minutes = 525600000;
    } // cap to avoid overflow

    if (_minutes == 0) {
      return DECIMAL_PRECISION;
    }

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n.div(2);
      } else {
        // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n.sub(1)).div(2);
      }
    }

    return decMul(x, y);
  }

  function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
    return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
  }

  function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
    if (_debt > 0) {
      return _coll.mul(NICR_PRECISION).div(_debt);
    }
    // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
    else {
      // if (_debt == 0)
      return 2 ** 256 - 1;
    }
  }

  function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
    if (_debt > 0) {
      uint newCollRatio = _coll.mul(_price).div(_debt);

      return newCollRatio;
    }
    // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
    else {
      // if (_debt == 0)
      return 2 ** 256 - 1;
    }
  }
}

pragma solidity 0.8.19;

import '../Interfaces/IRedemptionManager.sol';
import '../Interfaces/IComptroller.sol';
import './SortedBorrows.sol';
import '../Interfaces/IPriceOracle.sol';
import './LiquityMath.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../Exponential/ExponentialNoErrorNew.sol';
import '../SumerErrors.sol';
import '../Interfaces/IEIP712.sol';

contract RedemptionManager is
  AccessControlEnumerableUpgradeable,
  IRedemptionManager,
  ExponentialNoErrorNew,
  SumerErrors
{
  // deprecated, leaving to keep storage layout the same
  IComptroller public comptroller;

  /*
   * Half-life of 12h. 12h = 720 min
   * (1/2) = d^720 => d = (1/2)^(1/720)
   */
  uint public constant DECIMAL_PRECISION = 1e18;
  uint public constant SECONDS_IN_ONE_MINUTE = 60;
  uint public constant MINUTE_DECAY_FACTOR = 999037758833783000;
  uint public constant REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
  uint public constant MAX_BORROWING_FEE = (DECIMAL_PRECISION / 100) * 5; // 5%

  /*
   * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
   * Corresponds to (1 / ALPHA) in the white paper.
   */
  uint public constant BETA = 2;

  // deprecated field
  // leave it here for compatibility for storage layout
  uint public baseRate;

  // deprecated field
  // leave it here for compatibility for storage layout
  // The timestamp of the latest fee operation (redemption or new LUSD issuance)
  uint public lastFeeOperationTime;

  mapping(address => uint) public baseRateMap;

  // The timestamp of the latest fee operation (redemption or new LUSD issuance)
  mapping(address => uint) public lastFeeOperationTimeMap;

  address public redemptionSigner;

  event BaseRateUpdated(address asset, uint _baseRate);
  event LastFeeOpTimeUpdated(address asset, uint256 timestamp);
  event NewComptroller(address oldComptroller, address newComptroller);
  event NewRedemptionSigner(address oldSigner, address newSigner);

  constructor() {
    _disableInitializers();
  }

  function initialize(address _admin, IComptroller _comptroller, address _redemptionSigner) external initializer {
    comptroller = _comptroller;
    emit NewComptroller(address(0), address(comptroller));
    redemptionSigner = _redemptionSigner;
    emit NewRedemptionSigner(address(0), redemptionSigner);
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function setComptroller(IComptroller _comptroller) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!_comptroller.isComptroller()) {
      revert InvalidComptroller();
    }
    address oldComptroller = address(comptroller);
    comptroller = _comptroller;
    emit NewComptroller(oldComptroller, address(comptroller));
  }

  function setRedemptionSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
    address oldSigner = redemptionSigner;
    if (signer == address(0)) {
      revert InvalidAddress();
    }
    redemptionSigner = signer;
    emit NewRedemptionSigner(oldSigner, redemptionSigner);
  }

  // function setSortedBorrows(ISortedBorrows _sortedBorrows) external onlyRole(DEFAULT_ADMIN_ROLE) {
  //   require(sortedBorrows.isSortedBorrows(), 'invalid sorted borrows');
  //   sortedBorrows = _sortedBorrows;
  // }

  /*
   * This function has two impacts on the baseRate state variable:
   * 1) decays the baseRate based on time passed since last redemption or LUSD borrowing operation.
   * then,
   * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
   */
  function updateBaseRateFromRedemption(address asset, uint redeemAmount, uint _totalSupply) internal returns (uint) {
    uint newBaseRate = _calcNewBaseRate(asset, redeemAmount, _totalSupply);
    _updateBaseRate(asset, newBaseRate);
    _updateLastFeeOpTime(asset);

    return newBaseRate;
  }

  function _minutesPassedSinceLastFeeOp(address asset) internal view returns (uint) {
    return (block.timestamp - lastFeeOperationTimeMap[asset]) / SECONDS_IN_ONE_MINUTE;
  }

  function getCurrentRedemptionRate(address asset, uint redeemAmount, uint _totalSupply) public view returns (uint) {
    return _calcRedemptionRate(_calcNewBaseRate(asset, redeemAmount, _totalSupply));
  }

  function _calcNewBaseRate(address asset, uint redeemAmount, uint _totalSupply) internal view returns (uint) {
    if (_totalSupply <= 0) {
      return DECIMAL_PRECISION;
    }
    // require(msg.sender == address(comptroller), 'only comptroller');
    uint decayedBaseRate = _calcDecayedBaseRate(asset);

    /* Convert the drawn ETH back to LUSD at face value rate (1 LUSD:1 USD), in order to get
     * the fraction of total supply that was redeemed at face value. */
    uint redeemedLUSDFraction = (redeemAmount * DECIMAL_PRECISION) / _totalSupply;

    uint newBaseRate = decayedBaseRate + (redeemedLUSDFraction / BETA);
    newBaseRate = LiquityMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
    //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in the line above
    assert(newBaseRate > 0); // Base rate is always non-zero after redemption
    return newBaseRate;
  }

  function _calcDecayedBaseRate(address asset) internal view returns (uint) {
    uint minutesPassed = _minutesPassedSinceLastFeeOp(asset);
    uint decayFactor = LiquityMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

    return (baseRateMap[asset] * decayFactor) / DECIMAL_PRECISION;
  }

  // function _getRedemptionFee(uint _ETHDrawn) internal view returns (uint) {
  //   return _calcRedemptionFee(getRedemptionRate(), _ETHDrawn);
  // }

  function getRedemptionRate(address asset) public view returns (uint) {
    return _calcRedemptionRate(baseRateMap[asset]);
  }

  function _calcRedemptionRate(uint _baseRate) internal pure returns (uint) {
    return
      LiquityMath._min(
        REDEMPTION_FEE_FLOOR + _baseRate,
        DECIMAL_PRECISION // cap at a maximum of 100%
      );
  }

  function calcActualRepayAndSeize(
    uint256 redeemAmount,
    address provider,
    address cToken,
    address csuToken
  ) public returns (uint256, uint256, uint256, uint256) {
    ICToken(cToken).accrueInterest();
    ICToken(csuToken).accrueInterest();

    (uint256 oErr, uint256 depositBalance, , uint256 cExRateMantissa) = ICToken(cToken).getAccountSnapshot(provider);
    require(oErr == 0, 'snapshot error');

    if (depositBalance <= 0) {
      return (0, 0, 0, 0);
    }

    uint256 borrowBalance = ICToken(csuToken).borrowBalanceCurrent(provider);
    if (borrowBalance <= 0) {
      return (0, 0, 0, 0);
    }

    uint256 cash = ICToken(cToken).getCash();
    if (cash <= 0) {
      return (0, 0, 0, 0);
    }

    // get price for csuToken
    uint256 suPriceMantissa = comptroller.getUnderlyingPriceNormalized(csuToken);

    // get price for cToken
    uint256 cPriceMantissa = comptroller.getUnderlyingPriceNormalized(cToken);

    uint256 providerCollateralVal = (cPriceMantissa * depositBalance * cExRateMantissa) / expScale;
    uint256 providerLiabilityVal = (suPriceMantissa * borrowBalance);
    uint256 maxRepayable = LiquityMath._min(providerCollateralVal, providerLiabilityVal) / suPriceMantissa;
    uint256 actualRepay = 0;
    uint256 actualSeize = 0;
    if (redeemAmount <= maxRepayable) {
      actualRepay = redeemAmount;
      actualSeize = (suPriceMantissa * redeemAmount * expScale) / cPriceMantissa / cExRateMantissa;
    } else {
      actualRepay = maxRepayable;
      if (providerCollateralVal <= providerLiabilityVal) {
        actualSeize = depositBalance;
      } else {
        actualSeize = (providerLiabilityVal * expScale) / cPriceMantissa / cExRateMantissa;
      }
    }

    uint256 maxSeize = (cash * expScale) / cExRateMantissa;
    // if there's not enough cash, re-calibrate repay/seize
    if (maxSeize < actualSeize) {
      actualSeize = maxSeize;
      actualRepay = (cPriceMantissa * actualSeize * cExRateMantissa) / suPriceMantissa / expScale;
    }

    return (actualRepay, actualSeize, suPriceMantissa, cPriceMantissa);
  }

  // function hasNoProvider(address _asset) external view returns (bool) {
  //   return sortedBorrows.isEmpty(_asset);
  // }

  // function getFirstProvider(address _asset) external view returns (address) {
  //   return sortedBorrows.getFirst(_asset);
  // }

  // function getNextProvider(address _asset, address _id) external view returns (address) {
  //   return sortedBorrows.getNext(_asset, _id);
  // }

  // Updates the baseRate state variable based on time elapsed since the last redemption or LUSD borrowing operation.
  function decayBaseRateFromBorrowing(address asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint decayedBaseRate = _calcDecayedBaseRate(asset);
    assert(decayedBaseRate <= DECIMAL_PRECISION); // The baseRate can decay to 0

    baseRateMap[asset] = decayedBaseRate;
    emit BaseRateUpdated(asset, decayedBaseRate);

    _updateLastFeeOpTime(asset);
  }

  function _updateBaseRate(address asset, uint newBaseRate) internal {
    // Update the baseRate state variable
    baseRateMap[asset] = newBaseRate;
    emit BaseRateUpdated(asset, newBaseRate);
  }

  // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
  function _updateLastFeeOpTime(address asset) internal {
    uint timePassed = block.timestamp - lastFeeOperationTimeMap[asset];

    if (timePassed >= SECONDS_IN_ONE_MINUTE) {
      lastFeeOperationTimeMap[asset] = block.timestamp;
      emit LastFeeOpTimeUpdated(asset, block.timestamp);
    }
  }

  function redeemFaceValueWithProviderPreview(
    address redeemer,
    address provider,
    address cToken,
    address csuToken,
    uint256 redeemAmount,
    uint256 redemptionRateMantissa
  ) external returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    if (redeemer == provider) {
      return (0, 0, 0, 0, 0, 0);
    }

    (uint256 actualRepay, uint256 actualSeize, uint256 repayPrice, uint256 seizePrice) = calcActualRepayAndSeize(
      redeemAmount,
      provider,
      cToken,
      csuToken
    );
    if (actualRepay <= 0 || actualSeize <= 0) {
      return (0, 0, 0, repayPrice, seizePrice, 0);
    }
    // uint256 redemptionRateMantissa = getCurrentRedemptionRate(csuToken, actualRepay, ICToken(csuToken).totalBorrows());
    // uint256 collateralRateMantissa = getCollateralRate(cToken, csuToken);
    uint256 protocolSeizeTokens = (actualSeize * redemptionRateMantissa) / expScale;
    // .mul_( Exp({mantissa: collateralRateMantissa}));
    actualSeize = actualSeize - protocolSeizeTokens;
    return (
      actualRepay,
      actualSeize,
      protocolSeizeTokens,
      repayPrice,
      seizePrice,
      redemptionRateMantissa
      // collateralRateMantissa
    );
  }

  function redeemFaceValueWithProvider(
    address redeemer,
    address provider,
    address cToken,
    address csuToken,
    uint256 redeemAmount,
    uint256 redemptionRateMantissa
  ) internal returns (uint256) {
    (uint256 actualRepay, uint256 actualSeize, , ) = calcActualRepayAndSeize(redeemAmount, provider, cToken, csuToken);
    if (actualRepay <= 0 || actualSeize <= 0) {
      return 0;
    }
    ICToken(csuToken).executeRedemption(redeemer, provider, actualRepay, cToken, actualSeize, redemptionRateMantissa);
    return actualRepay;
  }

  function redeemFaceValueWithPermit(
    address csuToken,
    uint256 amount,
    address[] memory providers,
    uint256 providersDeadline,
    bytes memory providersSignature,
    uint256 permitDeadline,
    bytes memory permitSignature
  ) external {
    address underlying = ICToken(csuToken).underlying();
    IEIP712(underlying).permit(msg.sender, csuToken, amount, permitDeadline, permitSignature);
    return redeemFaceValue(csuToken, amount, providers, providersDeadline, providersSignature);
  }

  // function permit(address[] memory providers, uint256 deadline, bytes memory signature) public pure returns (address) {
  //   bytes32 hash = keccak256(abi.encodePacked(deadline, providers));
  //   bytes memory prefixedMessage = abi.encodePacked('\x19Ethereum Signed Message:\n', '32', hash);

  //   address signer = ECDSAUpgradeable.recover(keccak256(prefixedMessage), signature);
  //   return signer;
  // }

  /**
   * @notice Redeems csuToken with face value
   * @param csuToken The market to do the redemption
   * @param amount The amount of csuToken being redeemed to the market in exchange for collateral
   */
  function redeemFaceValue(
    address csuToken,
    uint256 amount,
    address[] memory providers,
    uint256 deadline,
    bytes memory signature
  ) public {
    if (ICToken(csuToken).isCToken() || !comptroller.isListed(csuToken)) {
      revert InvalidSuToken();
    }
    if (redemptionSigner == address(0)) {
      revert RedemptionSignerNotInitialized();
    }

    if (signature.length != 65) {
      revert InvalidSignatureLength();
    }

    if (block.timestamp >= deadline) {
      revert ExpiredSignature();
    }

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    bytes32 hash = keccak256(abi.encodePacked(deadline, providers, chainId));
    bytes memory prefixedMessage = abi.encodePacked('\x19Ethereum Signed Message:\n', '32', hash);
    address signer = ECDSAUpgradeable.recover(keccak256(prefixedMessage), signature);
    if (signer != redemptionSigner) {
      revert InvalidSignatureForRedeemFaceValue();
    }

    (, uint8 suGroupId, ) = comptroller.markets(csuToken);
    uint256 actualRedeem = 0;

    updateBaseRateFromRedemption(csuToken, amount, ICToken(csuToken).totalBorrows());
    uint256 redemptionRateMantissa = getRedemptionRate(csuToken);
    uint256 targetRedeemAmount = amount;
    for (uint256 p = 0; p < providers.length && targetRedeemAmount > 0; ++p) {
      address provider = providers[p];
      address[] memory assets = comptroller.getAssetsIn(provider);
      if (msg.sender == provider) {
        continue;
      }

      // redeem face value with homo collateral
      for (uint256 i = 0; i < assets.length && targetRedeemAmount > 0; ++i) {
        // only cToken is allowed to be collateral
        if (!ICToken(assets[i]).isCToken()) {
          continue;
        }
        (, uint8 cGroupId, ) = comptroller.markets(assets[i]);
        if (cGroupId == suGroupId) {
          actualRedeem = redeemFaceValueWithProvider(
            msg.sender,
            provider,
            assets[i],
            csuToken,
            targetRedeemAmount,
            redemptionRateMantissa
          );
          if (actualRedeem < targetRedeemAmount) {
            targetRedeemAmount = targetRedeemAmount - actualRedeem;
          } else {
            targetRedeemAmount = 0;
          }
        }
      }

      // redeem face value with hetero collateral
      for (uint256 i = 0; i < assets.length && targetRedeemAmount > 0; ++i) {
        // only cToken is allowed to be collateral
        if (!ICToken(assets[i]).isCToken()) {
          continue;
        }

        (, uint8 cGroupId, ) = comptroller.markets(assets[i]);
        if (cGroupId != suGroupId) {
          actualRedeem = redeemFaceValueWithProvider(
            msg.sender,
            provider,
            assets[i],
            csuToken,
            targetRedeemAmount,
            redemptionRateMantissa
          );
          if (actualRedeem < targetRedeemAmount) {
            targetRedeemAmount = targetRedeemAmount - actualRedeem;
          } else {
            targetRedeemAmount = 0;
          }
        }
      }
    }

    if (targetRedeemAmount > 0) {
      revert NoRedemptionProvider();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import '../Interfaces/ISortedBorrows.sol';
import '../Interfaces/ICTokenExternal.sol';
import '../Interfaces/IComptroller.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

/*
 * A sorted doubly linked list with nodes sorted in descending order.
 *
 * Nodes map to active Vessels in the system - the ID property is the address of a Vessel owner.
 * Nodes are ordered according to their current borrow balance (NBB),
 *
 * The list optionally accepts insert position hints.
 *
 * NBBs are computed dynamically at runtime, and not stored on the Node. This is because NBBs of active Vessels
 * change dynamically as liquidation events occur.
 *
 * The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NBBs of all active Vessels,
 * but maintains their order. A node inserted based on current NBB will maintain the correct position,
 * relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
 * Thus, Nodes remain sorted by current NBB.
 *
 * Nodes need only be re-inserted upon a Vessel operation - when the owner adds or removes collateral or debt
 * to their position.
 *
 * The list is a modification of the following audited SortedDoublyLinkedList:
 * https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 *
 *
 * Changes made in the Gravita implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an NBB argument to the current NBB, calculated at runtime.
 *   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 */
contract SortedBorrows is AccessControlEnumerableUpgradeable, ISortedBorrows {
  string public constant NAME = 'SortedBorrows';

  // Information for the list
  struct Data {
    address head; // Head of the list. Also the node in the list with the largest NBB
    address tail; // Tail of the list. Also the node in the list with the smallest NBB
    uint256 size; // Current size of the list
    // Depositor address => node
    mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
  }

  // Collateral type address => ordered list
  mapping(address => Data) public data;

  address public redemptionManager;

  // --- Initializer ---

  constructor() {
    _disableInitializers();
  }

  function initialize(address _admin) external initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  function setRedemptionManager(address _redemptionManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
    redemptionManager = _redemptionManager;
  }

  /*
   * @dev Add a node to the list
   * @param _id Node's id
   * @param _NBB Node's NBB
   * @param _prevId Id of previous node for the insert position
   * @param _nextId Id of next node for the insert position
   */

  function insert(address _asset, address _id, uint256 _NBB, address _prevId, address _nextId) external override {
    _requireCallerIsRedemptionManager();
    _insert(_asset, _id, _NBB, _prevId, _nextId);
  }

  function _insert(address _asset, address _id, uint256 _NBB, address _prevId, address _nextId) internal {
    Data storage assetData = data[_asset];

    // List must not already contain node
    require(!_contains(assetData, _id), 'SortedBorrows: List already contains the node');
    // Node id must not be null
    require(_id != address(0), 'SortedBorrows: Id cannot be zero');
    // NBB must be non-zero
    require(_NBB != 0, 'SortedBorrows: NBB must be positive');

    address prevId = _prevId;
    address nextId = _nextId;

    if (!_validInsertPosition(_asset, _NBB, prevId, nextId)) {
      // Sender's hint was not a valid insert position
      // Use sender's hint to find a valid insert position
      (prevId, nextId) = _findInsertPosition(_asset, _NBB, prevId, nextId);
    }

    Node storage node = assetData.nodes[_id];
    node.exists = true;

    if (prevId == address(0) && nextId == address(0)) {
      // Insert as head and tail
      assetData.head = _id;
      assetData.tail = _id;
    } else if (prevId == address(0)) {
      // Insert before `prevId` as the head
      node.nextId = assetData.head;
      assetData.nodes[assetData.head].prevId = _id;
      assetData.head = _id;
    } else if (nextId == address(0)) {
      // Insert after `nextId` as the tail
      node.prevId = assetData.tail;
      assetData.nodes[assetData.tail].nextId = _id;
      assetData.tail = _id;
    } else {
      // Insert at insert position between `prevId` and `nextId`
      node.nextId = nextId;
      node.prevId = prevId;
      assetData.nodes[prevId].nextId = _id;
      assetData.nodes[nextId].prevId = _id;
    }

    assetData.size = assetData.size + 1;
    emit NodeAdded(_asset, _id, _NBB);
  }

  function remove(address _asset, address _id) external override {
    _requireCallerIsRedemptionManager();
    _remove(_asset, _id);
  }

  /*
   * @dev Remove a node from the list
   * @param _id Node's id
   */
  function _remove(address _asset, address _id) internal {
    Data storage assetData = data[_asset];

    // List must contain the node
    require(_contains(assetData, _id), 'SortedBorrows: List does not contain the id');

    Node storage node = assetData.nodes[_id];
    if (assetData.size > 1) {
      // List contains more than a single node
      if (_id == assetData.head) {
        // The removed node is the head
        // Set head to next node
        assetData.head = node.nextId;
        // Set prev pointer of new head to null
        assetData.nodes[assetData.head].prevId = address(0);
      } else if (_id == assetData.tail) {
        // The removed node is the tail
        // Set tail to previous node
        assetData.tail = node.prevId;
        // Set next pointer of new tail to null
        assetData.nodes[assetData.tail].nextId = address(0);
      } else {
        // The removed node is neither the head nor the tail
        // Set next pointer of previous node to the next node
        assetData.nodes[node.prevId].nextId = node.nextId;
        // Set prev pointer of next node to the previous node
        assetData.nodes[node.nextId].prevId = node.prevId;
      }
    } else {
      // List contains a single node
      // Set the head and tail to null
      assetData.head = address(0);
      assetData.tail = address(0);
    }

    delete assetData.nodes[_id];
    assetData.size = assetData.size - 1;
    emit NodeRemoved(_asset, _id);
  }

  /*
   * @dev Re-insert the node at a new position, based on its new NBB
   * @param _id Node's id
   * @param _newNBB Node's new NBB
   * @param _prevId Id of previous node for the new insert position
   * @param _nextId Id of next node for the new insert position
   */
  function reInsert(address _asset, address _id, uint256 _newNBB, address _prevId, address _nextId) external override {
    _requireCallerIsRedemptionManager();
    // List must contain the node
    require(contains(_asset, _id), 'SortedBorrows: List does not contain the id');
    // NBB must be non-zero
    require(_newNBB != 0, 'SortedBorrows: NBB must be positive');

    // Remove node from the list
    _remove(_asset, _id);

    _insert(_asset, _id, _newNBB, _prevId, _nextId);
  }

  /*
   * @dev Checks if the list contains a node
   */
  function contains(address _asset, address _id) public view override returns (bool) {
    return data[_asset].nodes[_id].exists;
  }

  function _contains(Data storage _dataAsset, address _id) internal view returns (bool) {
    return _dataAsset.nodes[_id].exists;
  }

  /*
   * @dev Checks if the list is empty
   */
  function isEmpty(address _asset) public view override returns (bool) {
    return data[_asset].size == 0;
  }

  /*
   * @dev Returns the current size of the list
   */
  function getSize(address _asset) external view override returns (uint256) {
    return data[_asset].size;
  }

  /*
   * @dev Returns the first node in the list (node with the largest NBB)
   */
  function getFirst(address _asset) external view override returns (address) {
    return data[_asset].head;
  }

  /*
   * @dev Returns the last node in the list (node with the smallest NBB)
   */
  function getLast(address _asset) external view override returns (address) {
    return data[_asset].tail;
  }

  /*
   * @dev Returns the next node (with a smaller NBB) in the list for a given node
   * @param _id Node's id
   */
  function getNext(address _asset, address _id) external view override returns (address) {
    return data[_asset].nodes[_id].nextId;
  }

  /*
   * @dev Returns the previous node (with a larger NBB) in the list for a given node
   * @param _id Node's id
   */
  function getPrev(address _asset, address _id) external view override returns (address) {
    return data[_asset].nodes[_id].prevId;
  }

  /*
   * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NBB
   * @param _NBB Node's NBB
   * @param _prevId Id of previous node for the insert position
   * @param _nextId Id of next node for the insert position
   */
  function validInsertPosition(
    address _asset,
    uint256 _NBB,
    address _prevId,
    address _nextId
  ) external view override returns (bool) {
    return _validInsertPosition(_asset, _NBB, _prevId, _nextId);
  }

  function _validInsertPosition(
    address _asset,
    uint256 _NBB,
    address _prevId,
    address _nextId
  ) internal view returns (bool) {
    if (_prevId == address(0) && _nextId == address(0)) {
      // `(null, null)` is a valid insert position if the list is empty
      return isEmpty(_asset);
    } else if (_prevId == address(0)) {
      // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
      return data[_asset].head == _nextId && _NBB >= ICToken(_asset).borrowBalanceStored(_nextId);
    } else if (_nextId == address(0)) {
      // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
      return data[_asset].tail == _prevId && _NBB <= ICToken(_asset).borrowBalanceStored(_prevId);
    } else {
      // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NBB` falls between the two nodes' NBBs
      return
        data[_asset].nodes[_prevId].nextId == _nextId &&
        ICToken(_asset).borrowBalanceStored(_prevId) >= _NBB &&
        _NBB >= ICToken(_asset).borrowBalanceStored(_nextId);
    }
  }

  /*
   * @dev Descend the list (larger NBBs to smaller NBBs) to find a valid insert position
   * @param _vesselManager VesselManager contract, passed in as param to save SLOAD’s
   * @param _NBB Node's NBB
   * @param _startId Id of node to start descending the list from
   */
  function _descendList(address _asset, uint256 _NBB, address _startId) internal view returns (address, address) {
    Data storage assetData = data[_asset];

    // If `_startId` is the head, check if the insert position is before the head
    if (assetData.head == _startId && _NBB >= ICToken(_asset).borrowBalanceStored(_startId)) {
      return (address(0), _startId);
    }

    address prevId = _startId;
    address nextId = assetData.nodes[prevId].nextId;

    // Descend the list until we reach the end or until we find a valid insert position
    while (prevId != address(0) && !_validInsertPosition(_asset, _NBB, prevId, nextId)) {
      prevId = assetData.nodes[prevId].nextId;
      nextId = assetData.nodes[prevId].nextId;
    }

    return (prevId, nextId);
  }

  /*
   * @dev Ascend the list (smaller NBBs to larger NBBs) to find a valid insert position
   * @param _vesselManager VesselManager contract, passed in as param to save SLOAD’s
   * @param _NBB Node's NBB
   * @param _startId Id of node to start ascending the list from
   */
  function _ascendList(address _asset, uint256 _NBB, address _startId) internal view returns (address, address) {
    Data storage assetData = data[_asset];

    // If `_startId` is the tail, check if the insert position is after the tail
    if (assetData.tail == _startId && _NBB <= ICToken(_asset).borrowBalanceStored(_startId)) {
      return (_startId, address(0));
    }

    address nextId = _startId;
    address prevId = assetData.nodes[nextId].prevId;

    // Ascend the list until we reach the end or until we find a valid insertion point
    while (nextId != address(0) && !_validInsertPosition(_asset, _NBB, prevId, nextId)) {
      nextId = assetData.nodes[nextId].prevId;
      prevId = assetData.nodes[nextId].prevId;
    }

    return (prevId, nextId);
  }

  /*
   * @dev Find the insert position for a new node with the given NBB
   * @param _NBB Node's NBB
   * @param _prevId Id of previous node for the insert position
   * @param _nextId Id of next node for the insert position
   */
  function findInsertPosition(
    address _asset,
    uint256 _NBB,
    address _prevId,
    address _nextId
  ) external view override returns (address, address) {
    return _findInsertPosition(_asset, _NBB, _prevId, _nextId);
  }

  function _findInsertPosition(
    address _asset,
    uint256 _NBB,
    address _prevId,
    address _nextId
  ) internal view returns (address, address) {
    address prevId = _prevId;
    address nextId = _nextId;

    if (prevId != address(0)) {
      if (!contains(_asset, prevId) || _NBB > ICToken(_asset).borrowBalanceStored(prevId)) {
        // `prevId` does not exist anymore or now has a smaller NBB than the given NBB
        prevId = address(0);
      }
    }

    if (nextId != address(0)) {
      if (!contains(_asset, nextId) || _NBB < ICToken(_asset).borrowBalanceStored(nextId)) {
        // `nextId` does not exist anymore or now has a larger NBB than the given NBB
        nextId = address(0);
      }
    }

    if (prevId == address(0) && nextId == address(0)) {
      // No hint - descend list starting from head
      return _descendList(_asset, _NBB, data[_asset].head);
    } else if (prevId == address(0)) {
      // No `prevId` for hint - ascend list starting from `nextId`
      return _ascendList(_asset, _NBB, nextId);
    } else if (nextId == address(0)) {
      // No `nextId` for hint - descend list starting from `prevId`
      return _descendList(_asset, _NBB, prevId);
    } else {
      // Descend list starting from `prevId`
      return _descendList(_asset, _NBB, prevId);
    }
  }

  // --- 'require' functions ---

  function _requireCallerIsRedemptionManager() internal view {
    require(msg.sender == redemptionManager, 'only redemption manager');
  }

  function isSortedBorrows() external pure returns (bool) {
    return true;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.19;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoErrorNew {
  uint constant expScale = 1e18;
  uint constant doubleScale = 1e36;
  uint constant halfExpScale = expScale / 2;
  uint constant mantissaOne = expScale;

  struct Exp {
    uint mantissa;
  }

  struct Double {
    uint mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint scalar) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2 ** 224, errorMessage);
    return uint224(n);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2 ** 32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint a, uint b) internal pure returns (uint) {
    return a + b;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint a, uint b) internal pure returns (uint) {
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Exp memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Double memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint a, uint b) internal pure returns (uint) {
    return a * b;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Exp memory b) internal pure returns (uint) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Double memory b) internal pure returns (uint) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint a, uint b) internal pure returns (uint) {
    return a / b;
  }

  function fraction(uint a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IComptroller {
  /*** Assets You Are In ***/
  function isComptroller() external view returns (bool);

  function markets(address) external view returns (bool, uint8, bool);

  function getAllMarkets() external view returns (address[] memory);

  function oracle() external view returns (address);

  function redemptionManager() external view returns (address);

  function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

  function exitMarket(address cToken) external returns (uint256);

  function closeFactorMantissa() external view returns (uint256);

  function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);

  // function getAssetsIn(address) external view returns (ICToken[] memory);
  function claimComp(address) external;

  function compAccrued(address) external view returns (uint256);

  function getAssetsIn(address account) external view returns (address[] memory);

  function timelock() external view returns (address);

  function getUnderlyingPriceNormalized(address cToken) external view returns (uint256);
  /*** Policy Hooks ***/

  function mintAllowed(address cToken, address minter, uint256 mintAmount) external;

  function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external;
  // function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

  function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external;
  function borrowVerify(address borrower, uint borrowAmount) external;

  function repayBorrowAllowed(address cToken, address payer, address borrower, uint256 repayAmount) external;
  // function repayBorrowVerify(
  //   address cToken,
  //   address payer,
  //   address borrower,
  //   uint repayAmount,
  //   uint borrowerIndex
  // ) external;

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external;
  function seizeVerify(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint seizeTokens
  ) external;

  function transferAllowed(address cToken, address src, address dst, uint256 transferTokens) external;

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

  function borrowGuardianPaused(address cToken) external view returns (bool);

  function getCompAddress() external view returns (address);

  function borrowCaps(address cToken) external view returns (uint256);

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external view;
  // function liquidateBorrowVerify(
  //   address cTokenBorrowed,
  //   address cTokenCollateral,
  //   address liquidator,
  //   address borrower,
  //   uint repayAmount,
  //   uint seizeTokens
  // ) external;

  function getCollateralRate(address collateralToken, address liabilityToken) external view returns (uint256);
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

  function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

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

  function isDeprecated() external view returns (bool);

  function executeRedemption(
    address redeemer,
    address provider,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeAmount,
    uint256 redemptionRateMantissa
  ) external returns (uint256);

  function discountRateMantissa() external view returns (uint256);

  function accrueInterest() external returns (uint256);

  function liquidateCalculateSeizeTokens(
    address cTokenCollateral,
    uint256 actualRepayAmount
  ) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEIP712 {
  function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external;
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

  /**
   * @notice Get the underlying price of cToken asset (normalized)
   * = getUnderlyingPrice * (10 ** (18 - cToken.decimals))
   */
  function getUnderlyingPriceNormalized(address cToken_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import './IPriceOracle.sol';

interface IRedemptionManager {
  function calcActualRepayAndSeize(
    uint256 redeemAmount,
    address provider,
    address cToken,
    address csuToken
  ) external returns (uint256, uint256, uint256, uint256);

  // function updateSortedBorrows(address csuToken, address borrower) external;

  function getRedemptionRate(address asset) external view returns (uint);

  function getCurrentRedemptionRate(address asset, uint redeemAmount, uint _totalSupply) external returns (uint);

  function redeemFaceValueWithProviderPreview(
    address redeemer,
    address provider,
    address cToken,
    address csuToken,
    uint256 redeemAmount,
    uint256 redemptionRateMantissa
  ) external returns (uint256, uint256, uint256, uint256, uint256, uint256);

  function redeemFaceValue(
    address csuToken,
    uint256 amount,
    address[] memory providers,
    uint256 deadline,
    bytes memory signature
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ISortedBorrows {
  // Information for a node in the list
  struct Node {
    bool exists;
    address nextId; // Id of next node (smaller NBB) in the list
    address prevId; // Id of previous node (larger NBB) in the list
  }

  // --- Events ---

  event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
  event NodeRemoved(address indexed _asset, address _id);

  // --- Functions ---

  function insert(address _asset, address _id, uint256 _ICR, address _prevId, address _nextId) external;

  function remove(address _asset, address _id) external;

  function reInsert(address _asset, address _id, uint256 _newICR, address _prevId, address _nextId) external;

  function contains(address _asset, address _id) external view returns (bool);

  function isEmpty(address _asset) external view returns (bool);

  function getSize(address _asset) external view returns (uint256);

  function getFirst(address _asset) external view returns (address);

  function getLast(address _asset) external view returns (address);

  function getNext(address _asset, address _id) external view returns (address);

  function getPrev(address _asset, address _id) external view returns (address);

  function validInsertPosition(
    address _asset,
    uint256 _ICR,
    address _prevId,
    address _nextId
  ) external view returns (bool);

  function findInsertPosition(
    address _asset,
    uint256 _ICR,
    address _prevId,
    address _nextId
  ) external view returns (address, address);

  function isSortedBorrows() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract SumerErrors {
  error PriceError();

  error RedemptionSignerNotInitialized();
  error NotEnoughForSeize();
  error NoRedemptionProvider();
  error MarketNotListed();
  error InsufficientShortfall();
  error TooMuchRepay();
  error OneOfRedeemTokensAndRedeemAmountMustBeZero();
  error InvalidMinSuBorrowValue();
  error BorrowValueMustBeLargerThanThreshold(uint256 usdThreshold);
  error ProtocolIsPaused();
  error MarketAlreadyListed();
  error InvalidAddress();
  error InvalidGroupId();
  error InvalidCloseFactor();
  error InvalidSuToken();
  error InvalidSignatureLength();
  error ExpiredSignature();
  error SenderMustBeCToken();
  error MintPaused();
  error BorrowPaused();
  error TransferPaused();
  error SeizePaused();
  error InsufficientCollateral();
  error GroupIdMismatch();
  error OneOfNetAssetAndNetDebtMustBeZero();

  error OnlyAdminOrCapper();
  error OnlyAdminOrPauser();

  // general errors
  error OnlyAdmin();
  error OnlyPendingAdmin();
  error OnlyRedemptionManager();
  error OnlyListedCToken();
  error OnlyCToken();
  error UnderlyingBalanceError();
  error MarketCanOnlyInitializeOnce();
  error CantSweepUnderlying();
  error TokenTransferInFailed();
  error TokenTransferOutFailed();
  error TransferNotAllowed();
  error TokenInOrAmountInMustBeZero();
  error AddReservesOverflow();
  error ReduceReservesOverflow();
  error RedeemTransferOutNotPossible();
  error BorrowCashNotAvailable();
  error ReduceReservesCashNotAvailable();
  error InvalidDiscountRate();
  error InvalidExchangeRate();
  error InvalidReduceAmount();
  error InvalidReserveFactor();
  error InvalidComptroller();
  error InvalidInterestRateModel();
  error InvalidAmount();
  error InvalidInput();
  error BorrowAndDepositBackFailed();
  error InvalidSignatureForRedeemFaceValue();

  error BorrowCapReached();
  error SupplyCapReached();
  error ComptrollerMismatch();

  error MintMarketNotFresh();
  error BorrowMarketNotFresh();
  error RepayBorrowMarketNotFresh();
  error RedeemMarketNotFresh();
  error LiquidateMarketNotFresh();
  error LiquidateCollateralMarketNotFresh();
  error ReduceReservesMarketNotFresh();
  error SetInterestRateModelMarketNotFresh();
  error AddReservesMarketNotFresh();
  error SetReservesFactorMarketNotFresh();
  error CantExitMarketWithNonZeroBorrowBalance();

  // error
  error NotCToken();
  error NotSuToken();

  // error in liquidateBorrow
  error LiquidateBorrow_RepayAmountIsZero();
  error LiquidateBorrow_RepayAmountIsMax();
  error LiquidateBorrow_LiquidatorIsBorrower();
  error LiquidateBorrow_SeizeTooMuch();

  // error in seize
  error Seize_LiquidatorIsBorrower();

  // error in protected mint
  error ProtectedMint_OnlyAllowAssetsInTheSameGroup();

  error RedemptionSeizeTooMuch();

  error MinDelayNotReached();

  error NotLiquidatableYet();
}