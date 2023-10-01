// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library StorageSlotUpgradeable {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

library MiscUtils {
	function toString(int256 value) internal pure returns (string memory) {
		// Adapted from OpenZepplin Strings.sol
		if (value == 0) {
			return "0";
		}
		bool negative = value < 0;
		uint256 unsignedValue = uint256(negative ? -value : value);
		uint256 temp = unsignedValue;
		uint256 digits = negative ? 1 : 0;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (unsignedValue != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(unsignedValue % 10)));
			unsignedValue /= 10;
		}

		if (negative) {
			buffer[0] = "-";
		}

		return string(buffer);
	}

	// generate a random number between min and max
	function random(uint256 min, uint256 max) internal view returns (uint256) {
		require(min <= max, "Min must be less than max");
		if (min == max) return min;
		
		uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
		return (randomHash % (max - min)) + min;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library StringSplitter {
    function splitString(string memory input) internal pure returns (string memory part1, string memory part2) {
        bytes memory inputBytes = bytes(input);
        uint256 delimiterIndex = indexOfDelimiter(inputBytes, bytes("_"));

        if (delimiterIndex == uint256(0)) {
            // Delimiter not found, return the original string as part1
            return (input, "");
        }

        part1 = string(slice(inputBytes, 0, delimiterIndex));
        part2 = string(slice(inputBytes, delimiterIndex + 1, inputBytes.length - delimiterIndex - 1));
    }

    function indexOfDelimiter(bytes memory input, bytes memory delimiter) private pure returns (uint256) {
        for (uint256 i = 0; i < input.length - delimiter.length + 1; i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiter.length; j++) {
                if (input[i + j] != delimiter[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return i;
            }
        }
        return uint256(0);
    }

    function slice(bytes memory input, uint256 start, uint256 length) private pure returns (bytes memory) {
        bytes memory output = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = input[start + i];
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT

/*
                                                 .
        .-=-:    ..:  .:::::::  ::::::---:     -##++*+*.::----:  -==-   ---.--::---=.
      =#=-=+=+#=@+=+%##=#@=--%+##=@*-=##==#=-*#==*#= :%@*-:**+=#*@-=@%-+@:@@+-:+**=#=
     =%..%@@@--@@+.-@=+@@@@=.:%%-@@*::@@+.+@@::*@@@#=.#@#::@@%..@@=.:*@@@.@@#. %=-+=
     =@-..*@@@@@@*:::.*@@@@@+..-@@@#:.#*-:*@@.-@@@@%=:=@#:.*=:+%@@=+=.:%@:@@#..%*++:
      *@*-..-+@@@+.-@=.-%@@@@.:#@@@*:-@@@=.*@-.+*@@@:.+@#.:@%::#@@=*@#:.*:@@#..=+=%-
     -#*@@%=-:.%@*.-@@#-.:=#%==++@@*..#%#:=%@%-.:--.:#@@*..@@@-.-#+*@@@-..@@%..#+:.
     +*.@@@@#..#@=::@@@@%*+=--=+%@@@@@@@@@@@@@@@%##%@@@@@%%@@@@%=-::--#@*.@@%..*+..:
      %*=+*+:=*@@@@@@@@%#%##****##**+++*###+##*###**+++**#*****#%##@@@@@@@@@@#*+**+%+
       -#@@@@@@@@@@%%%%%%#*++**%%#++++*#%*******#%#*+++*#%%#*++*#%%%#%%@@@@@@@@@@@%#
     :+***+++***@@@%###*****#@@#**#@@@@%**#@@#***#****#@@@@%**+**#%@@###%@@@@%#******%+
   .#*-:::---:::%@@@-:--====:@@@-::=@@@@=:#@@@-:=+++++-@@%-:=+++--=@@#::@@@#=::----::-@
  :@+::=#@@@@@%*+@@@-:*@@@@@@%@@--=--%@@=-+@@@-:#@@@@%@@@+--%@@@@@+@@%::@@%-:=@@@@@%#=%-
  %*::+@@@@%%%%%#%@@=--====-@@@@--##-:#@=-*@@%--:::::=@@@@+-::-=+#@@@#-:@@%--:=+*#%@@@%*
 .@+--*@@@@------%@@=-+**#**@@@@=-%@%=-+=-*@@@=-#%%%%#@@@#@@%##*=--%@#-:@@@@*+=---::-+@-
 .@#---@@@%%@@+--@@@=-*@@@@@%%@%=-%@@@+-==*@@@==+*###**#@*-*#%@@%=-+@#--@@*%@@@@@%#+---@
  +@+--=#@@@@%+=-@@@==------=%@%==*@@@@*+++@@%+*+++++++@@@++=---==*@@#=-@@%-=*#%@%%*=-=@:
   *@#+==----====%@%##%%%%%@@@@@@%%%#*#####**##*#########%##@@@@@@#%@%#*#@@*===---===*@*
    :*@%##**##%@%#=+==--::..                                  ..    :-==+=%@@@%%%%%@%*-
       :-=++=-:                                                            .  .:--:.
*/
pragma solidity 0.8.17;

interface ITokenTraitsProvider {
	// ====================================================
	// ENUMS
	// ====================================================
	enum Behavior {
		NOT_SET, // 0
		IMMUTABLE, // 1
		INCREMENT, // 2
		DECREMENT, // 3
		UNRESTRICTED // 4
	}

	enum DataType {
		NULL, // 0
		STRING, // 1
		INT, // 2
		UINT, // 3
		BOOL // 4
	}

	// ====================================================
	// STRUCTS
	// ====================================================
	struct TraitMetadata {
		string name;
		Behavior behavior;
		DataType dataType;
		bool topLevel;
		bool isCommon;
	}

	struct TokenTrait {
		string metaId;
		bytes value;
		DataType dataType;
	}

	struct TokenURITrait {
		string name;
		bytes value;
		DataType dataType;
		bool isTopLevelProperty;
	}

	// ====================================================
	// API - ACCESS
	// ====================================================
	function getTraitMetadata(address tokenAddress, uint256 traitId) external view returns (TraitMetadata memory);

	function getTokenTraitIds(address tokenAddress, uint256 tokenId) external view returns (uint256[] memory);

	function getTraitBytesValue(
		address tokenAddress,
		uint256 tokenId,
		uint256 traitId
	) external view returns (bytes memory);

	function getTraitMetaId(address tokenAddress, uint256 tokenId, uint256 traitId) external returns (string memory);

	function getTraitStringValue(
		address tokenContract,
		uint256 tokenId,
		uint256 traitId
	) external returns (string memory);

	function getTraitIntValue(address tokenContract, uint256 tokenId, uint256 traitId) external returns (int256);

	function getTraitUintValue(address tokenContract, uint256 tokenId, uint256 traitId) external returns (uint256);

	function getTraitBoolValue(address tokenContract, uint256 tokenId, uint256 traitId) external returns (bool);

	function hasTrait(address tokenContract, uint256 tokenId, uint256 traitId) external view returns (bool);

	function generateTokenURI(
		address tokenContract,
		uint256 tokenId,
		TokenURITrait[] memory extraTraits
	) external view returns (string memory);

	function getAllTraits(address tokenAddress, uint256 tokenId) external view returns (TokenURITrait[] memory);

	// ====================================================
	// API - MUTATE
	// ====================================================
	function setStringTrait(
		address tokenAddress,
		uint256 tokenId,
		uint256 traitId,
		string memory metaId,
		string memory value
	) external;

	function setStringTraitBatch(
		address tokenAddress,
		uint256[] calldata tokenIds,
		uint256[] calldata traitIds,
		string[] calldata metaIds,
		string[] calldata values
	) external;

	function setUintTrait(
		address tokenAddress,
		uint256 tokenId,
		uint256 traitId,
		string memory metaId,
		uint256 value
	) external;

	function setUintTraitBatch(
		address tokenAddress,
		uint256[] calldata tokenIds,
		uint256[] calldata traitIds,
		string[] calldata metaIds,
		uint256[] calldata values
	) external;

	function setIntTrait(
		address tokenAddress,
		uint256 tokenId,
		uint256 traitId,
		string memory metaId,
		int256 value
	) external;

	function setIntTraitBatch(
		address tokenAddress,
		uint256[] calldata tokenIds,
		uint256[] calldata traitIds,
		string[] calldata metaIds,
		int256[] calldata values
	) external;

	function setBoolTrait(
		address tokenAddress,
		uint256 tokenId,
		uint256 traitId,
		string memory metaId,
		bool value
	) external;

	function setBoolTraitBatch(
		address tokenAddress,
		uint256[] calldata tokenIds,
		uint256[] calldata traitIds,
		string[] calldata metaIds,
		bool[] calldata values
	) external;

	function incrementTrait(address tokenAddress, uint256 tokenId, uint256 traitId, uint256 amount) external;

	function decrementTrait(address tokenAddress, uint256 tokenId, uint256 traitId, uint256 amount) external;

	function setRawTokenTraits(
		address tokenAddress,
		uint256 tokenId,
		uint256[] memory traitIds,
		string[] memory metaIds,
		bytes[] memory values,
		DataType[] memory dataTypes
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

bytes32 constant COLLECTION_ADMIN_ROLE = keccak256("COLLECTION_ADMIN_ROLE");
bytes32 constant QUESTING_CONTRACT_ROLE = keccak256("QUESTING_CONTRACT_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
bytes32 constant QUEST_MANAGER_ROLE = keccak256("QUEST_MANAGER_ROLE");

bytes32 constant REDEMPTION_CONTRACT_ROLE = keccak256("REDEMPTION_CONTRACT_ROLE");

bytes32 constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

bytes32 constant ITEM_MANAGEMENT_ROLE = keccak256("ITEM_MANAGEMENT_ROLE");

bytes32 constant TOKEN_TRAITS_WRITER_ROLE = keccak256("TOKEN_TRAITS_WRITER_ROLE");

bytes32 constant IMMORTALS_CHILDCHAIN_MINTER_ROLE = keccak256("IMMORTALS_CHILDCHAIN_MINTER_ROLE");

// trait ids
uint256 constant TRAIT_ID_NAME = uint256(keccak256("trait_name"));
uint256 constant TRAIT_ID_DESCRIPTION = uint256(keccak256("trait_description"));
uint256 constant TRAIT_ID_IMAGE = uint256(keccak256("trait_image"));
uint256 constant TRAIT_ID_EXTERNAL_URL = uint256(keccak256("trait_external_url"));
uint256 constant TRAIT_ID_LOCKED = uint256(keccak256("trait_locked"));
uint256 constant TRAIT_ID_SEASON = uint256(keccak256("trait_season"));
uint256 constant TRAIT_ID_RACE = uint256(keccak256("trait_race"));

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library ERC2771RecipientStorage {
	bytes32 constant STRUCT_POSITION = keccak256("erc2771recipient.storage");

	struct Layout {
		address _trustedForwarder;
	}

	function layout() internal pure returns (Layout storage l) {
		bytes32 position = STRUCT_POSITION;
		assembly {
			l.slot := position
		}
	}
}

/**
 * @title Upgradeable version of the ERC2771Recipient contract.
 * @notice See {ERC2771Recipient} for more info
 * */
abstract contract ERC2771RecipientUpgradeable is Initializable, IERC2771Recipient {
	using ERC2771RecipientStorage for ERC2771RecipientStorage.Layout;

	function __ERC2771Recipient_init() internal onlyInitializing {}

	function __ERC2771Recipient_init_unchained() internal onlyInitializing {}

	/**
	 * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
	 * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
	 * @return forwarder The address of the Forwarder contract that is being used.
	 */
	function getTrustedForwarder() public view virtual returns (address forwarder) {
		return ERC2771RecipientStorage.layout()._trustedForwarder;
	}

	function _setTrustedForwarder(address _forwarder) internal {
		ERC2771RecipientStorage.layout()._trustedForwarder = _forwarder;
	}

	/// @inheritdoc IERC2771Recipient
	function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
		return forwarder == ERC2771RecipientStorage.layout()._trustedForwarder;
	}

	/// @inheritdoc IERC2771Recipient
	function _msgSender() internal view virtual override returns (address ret) {
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			// At this point we know that the sender is a trusted forwarder,
			// so we trust that the last bytes of msg.data are the verified sender address.
			// extract sender address from the end of msg.data
			assembly {
				ret := shr(96, calldataload(sub(calldatasize(), 20)))
			}
		} else {
			ret = msg.sender;
		}
	}

	/// @inheritdoc IERC2771Recipient
	function _msgData() internal view virtual override returns (bytes calldata ret) {
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			return msg.data[0:msg.data.length - 20];
		} else {
			return msg.data;
		}
	}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IWalletDelegation
{
    function getDelegateWalletsForEoa(address eoa)
        external view
        returns(address[] memory);

    function getEoaForDelegateWallet(address delegateWallet)
        external view
        returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBackpackItems {
	function mintWithItemMetaId(
		address account,
		string memory _metaId,
		uint256 amount,
		bytes memory data
	) external;

	function mintWithItemId(
		address account,
		uint256 _id,
		uint256 amount,
		bytes memory data
	) external;

	function burnBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory values
	) external;

	function burn(
		address account,
		uint256 id,
		uint256 value
	) external;

	function pause() external;

	function unpause() external;

	function balanceOf(address account, uint256 id) external view returns (uint256);

	function totalSupply(uint256 id) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

// TODO make upgradable

interface ICampaignProgression
{
    function getUserProgress(address userAddress) external view returns (uint256);

    // TODO access control - system
    function incrementUserProgress(address userAddress) external;

    // TODO access control and/or owner
    function resetProgress(address userAddress) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IImmortals {
	function lockSingleToken(uint256 tokenId, uint256 lockDuration) external;

	function lockTokens(uint256[] calldata tokenIds, uint256 lockDuration) external;

	function unlockSingleToken(uint256 tokenId) external;

	function unlockTokens(uint256[] memory tokenId) external;

	function burn(uint256 tokenId) external;

	function locked(uint256 tokenId) external view returns (bool);

	function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IQuestsV1.sol";

interface IQuestsManager {

	enum QuestType {
		SIDE_QUEST,
		CAMPAIGN_QUEST
	}

	struct QuestState {
		string questId;
		string pinId;
		uint256 startTime;
		uint256 endTime;
		uint256[] heroTokens;
		QuestType questType;
		uint256[4] rewardChances;
 	}

	struct Reward{
		string rewardType;
		uint256 amount;
	}

	function startQuest(
		string calldata questId,
		string memory pinId,
		uint256[] calldata heroTokens,
		bool isCampaign,
		bool fromDelegate
	) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IQuestsV1
{
    enum QuestType { TUTORIAL, CAMPAIGN, SIDE }

	// EVENTS
	event QuestConfigAdded(string questId);
    event QuestConfigDeleted(string questId);
    event QuestCostsSet(string questId);
    event QuestTraitsSet(string questId);
    event QuestRewardsSet(string questId);

	// TODO: Quest heroes count
	// TODO: campaign quest start condition or maybe have a id of the previous quest
    struct Quest
    {
        string id;
        string pinId; // TODO: introduce map pins -> only for campaign quests
        QuestType questType;
        uint256 duration;
        bool dangerous;
		uint256 progressionLevel;
		uint256 heroSlotPoints;
    }

    struct QuestCost
    {
        string costType; // TODO this will likely be an 1155 token type id
        uint256 amount;
    }

    struct QuestTraits
    {
        string[][] traitType;
		string[][] value;
		uint256[][] points;
    }

    struct QuestReward
    {
        string rewardType; // TODO for now it will be an 1155 token type id
        uint256 amount;
        uint32 minChance;
        uint32 maxChance;
		uint32 minThreshold;
		uint32 maxThreshold;
    }

	function getQuest(string memory questId) external view returns (
        Quest memory quest,
        QuestCost[] memory costs,
        QuestTraits memory traits,
        QuestReward[] memory rewards
    );

    function getQuestBase(string memory questId) external view returns (Quest memory quest);

    function getQuestCost(string memory questId) external view returns (QuestCost[] memory cost);

    function getQuestTraits(string memory questId) external view returns (QuestTraits memory traits);

    function getQuestRewards(string memory questId) external view returns (QuestReward[] memory rewards);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { IQuestsV1 } from "../game/interfaces/IQuestsV1.sol";
import { IQuestsManager } from "../game/interfaces/IQuestsManager.sol";
import { ICampaignProgression } from "../game/interfaces/ICampaignProgression.sol";
import { IBackpackItems } from "../game/interfaces/IBackpackItems.sol";
import { IImmortals } from "../game/interfaces/IImmortals.sol";
import { ITokenTraitsProvider } from "../../thirdparty/falkor-contracts/tokens/utils/interfaces/ITokenTraitsProvider.sol";
import { IWalletDelegation } from "../delegation-registry/IWalletDelegation.sol";
import { ERC2771RecipientUpgradeable } from "../delegation-registry/ERC2771RecipientUpgradeable.sol";
import { QUEST_MANAGER_ROLE } from "../WLRoleConstants.sol";
import { MiscUtils } from "../../libraries/MiscUtils.sol";
import { StringSplitter } from "../../libraries/StringSplitter.sol";

contract QuestsManager is
	IQuestsManager,
	Initializable,
	AccessControlUpgradeable,
	UUPSUpgradeable,
	ERC2771RecipientUpgradeable
{
	// ==================================================
	// =================== STATEV1 ======================
	// ==================================================

	using StringsUpgradeable for uint256;
	using StringSplitter for string;

	// address of SideQuestsV1 contract
	IQuestsV1 public sideQuestsV1;

	// address of CampaignQuestsV1 contract
	IQuestsV1 public campaignQuestsV1;

	//IBackpackItems BackpackItems contract
	IBackpackItems public backpackItems;

	// Immortal contract
	IImmortals public immortal;

	// Traits Provider contract
	ITokenTraitsProvider public traitsProvider;

	// CampaignProgression contract
	ICampaignProgression public campaignProgression;

	// WalletDelegation contract
	IWalletDelegation public delegationRegistry;

	// mapping of inProgress quests for each player
	// address -> questId -> QuestState
	mapping(address => mapping(string => QuestState)) private inProgressQuests;

	// mapping of inProgress quests for each player
	mapping(address => string[]) private inProgressQuestsIds;

	// compound trait mapping
	mapping(string => string[]) private compoundTraits;

	// Base divider for calculating reward chances to incorporate decimal points
	uint256 private immutable BASE_DIVDER = 10000;

	bool private _paused;

	// =============================================================
	// ===== DO NOT EDIT ABOVE THIS LINE IF UPGRADING CONTRACT =====
	// =============================================================

	// ==================================================
	// =================== ERRORS =======================
	// ==================================================

	/// @dev reverts if no EOA address is found for the delegate address
	error noEoaForDelegateFound(address _delegate);

	/// @dev reverts if the user does not have the required backpack items
	error missingBackpackItems(string _backpackItem);

	/// @dev reverts if the hero is already locked
	error heroAlreadyLocked(uint256 _heroToken);

	/// @dev reverts if the hero is not owned by the player
	error heroNotOwnedByPlayer(address user, uint256 _heroToken);

	/// @dev reverts if the quest is not available
	error incorrectProgressionLevel(uint256 _progressionLevel, uint256 _userProgress);

	/// @dev reverts if the contracts are not set
	error contractsNotSet();

	/// @dev reverts if the quest is not in progress
	error QuestNotInProgress(string _questId);

	/// @dev reverts if the quest is in progress
	error QuestInProgress(string _questId, uint256 _endTime);

	/// @dev reverts if the user is not authorized to end the quest
	error Unauthorized();

	// ================================================
	// ================== EVENTS ======================
	// ================================================

	event QuestStarted(
		string questId,
		address user,
		uint256[] heroIds,
		uint256 startTime,
		uint256 endTime,
		uint256[4] rewardChances
	);
	event QuestEnded(string questId, address user, uint256[] heroIds, Reward[] rewards);

	// ==================================================
	// ================== MODIFIERS =====================
	// ==================================================

	modifier whenNotPaused() {
		require(!_paused, "Questing is paused");
		_;
	}
	modifier whenPaused() {
		require(_paused, "Questing is not paused");
		_;
	}

	// ==================================================
	// ================== INITIALIZER ===================
	// ==================================================

	function initialize() public initializer {
		__AccessControl_init();
		__UUPSUpgradeable_init();
		__ERC2771Recipient_init();
		_paused = true;

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(QUEST_MANAGER_ROLE, msg.sender);
		_setRoleAdmin(QUEST_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
	}

	// ==================================================
	// ================== ROLE - GATED ==================
	// ==================================================
	function startQuest(
		string memory questId,
		string memory pinId,
		uint256[] memory heroTokens,
		bool isCampaign,
		bool fromDelegate
	) external whenNotPaused {
		address user = _delegatedMsgSender(fromDelegate);
		if (user == address(0)) {
			revert noEoaForDelegateFound(_msgSender());
		}

		(
			IQuestsV1.Quest memory quest,
			IQuestsV1.QuestCost[] memory costs,
			IQuestsV1.QuestTraits memory traits,

		) = isCampaign
				? campaignQuestsV1.getQuest(string(abi.encodePacked(questId)))
				: sideQuestsV1.getQuest(string(abi.encodePacked(questId)));

		// scoped to reduce stack size
		{
			require(
				keccak256(abi.encodePacked(quest.id)) == keccak256(abi.encodePacked(questId)),
				"Quest is not available"
			);
			require(inProgressQuests[user][questId].startTime == 0, "Quest already in-progress");
		}

		// require correct progression in case of campaign quests
		if (isCampaign) {
			if (quest.progressionLevel != campaignProgression.getUserProgress(user)) {
				revert incorrectProgressionLevel(quest.progressionLevel, campaignProgression.getUserProgress(user));
			}
		}

		// check if the player owns the required hero tokens and they are not locked - scoped to reduce stack size
		{
			uint256 slottedHeroCount = 0;
			// check if the heroes are owned by the player
			for (uint256 i = 0; i < heroTokens.length; i++) {
				if (heroTokens[i] == 0) {
					continue;
				}
				slottedHeroCount++;
				if (!(immortal.ownerOf(heroTokens[i]) == user)) revert heroNotOwnedByPlayer(user, heroTokens[i]);
				bool lockedState = immortal.locked(heroTokens[i]);
				if (lockedState) revert heroAlreadyLocked(heroTokens[i]);
			}
			// require at least one hero to be slotted
			require(slottedHeroCount > 0, "No heroes slotted");
		}

		// Burning the quest costs - scoped to reduce stack size
		{
			// Burning the quest costs
			uint256[] memory backpackItemIds = new uint256[](costs.length);
			uint256[] memory amounts = new uint256[](costs.length);

			for (uint256 i = 0; i < costs.length; i++) {
				// require user to have the required backpack items
				if (backpackItems.balanceOf(user, _toUint256(costs[i].costType)) < costs[i].amount) {
					revert missingBackpackItems(costs[i].costType);
				}
				backpackItemIds[i] = _toUint256(costs[i].costType);
				amounts[i] = costs[i].amount;
			}

			backpackItems.burnBatch(user, backpackItemIds, amounts);
		}

		// check if the heroes have the required traits - scoped to reduce stack size
		{
			uint256 userTotalPoints = 0;

			{
				for (uint256 i = 0; i < heroTokens.length; i++) {
					// continue if the hero is not slotted
					if (heroTokens[i] == 0) {
						continue;
					}
					// for each hero add the slotting points
					userTotalPoints += quest.heroSlotPoints;

					for (uint256 j = 0; j < traits.traitType[i].length; j++) {
						if (compoundTraits[traits.traitType[i][j]].length > 0) {
							// check if the traits metadata is set in traits provider
							ITokenTraitsProvider.DataType dataType1;
							ITokenTraitsProvider.DataType dataType2;
							{
								ITokenTraitsProvider.TraitMetadata memory traitMetadata1 = traitsProvider
									.getTraitMetadata(
										address(immortal),
										_toUint256(compoundTraits[traits.traitType[i][j]][0])
									);
								ITokenTraitsProvider.TraitMetadata memory traitMetadata2 = traitsProvider
									.getTraitMetadata(
										address(immortal),
										_toUint256(compoundTraits[traits.traitType[i][j]][1])
									);

								dataType1 = traitMetadata1.dataType;
								dataType2 = traitMetadata2.dataType;

								if (
									traitMetadata1.behavior == ITokenTraitsProvider.Behavior.NOT_SET ||
									traitMetadata2.behavior == ITokenTraitsProvider.Behavior.NOT_SET
								) {
									continue;
								}
							}

							try
								traitsProvider.getTraitBytesValue(
									address(immortal),
									heroTokens[i],
									_toUint256(compoundTraits[traits.traitType[i][j]][0])
								)
							returns (bytes memory traitValueInBytes1) {
								try
									traitsProvider.getTraitBytesValue(
										address(immortal),
										heroTokens[i],
										_toUint256(compoundTraits[traits.traitType[i][j]][1])
									)
								returns (bytes memory traitValueInBytes2) {
									// check if the trait value matches and increment the count
									// first get the string value using the utility function
									string memory traitValue1 = _traitValueToString(traitValueInBytes1, dataType1);
									string memory traitValue2 = _traitValueToString(traitValueInBytes2, dataType2);
									// if the expected trait value is true, then increment the points if the trait is not None or False

									// split the trait value into two parts
									(string memory expectValue1, string memory expectedValue2) = traits
									.value[i][j].splitString();
									if (
										_compareValues(traitValue1, expectValue1) &&
										_compareValues(traitValue2, expectedValue2)
									) {
										userTotalPoints += traits.points[i][j];
									}
								} catch {
									// if the trait is not present, then continue
									continue;
								}
							} catch {
								// if the trait is not present, then continue
								continue;
							}
						}
						// check if the traits metadata is set in traits provider
						ITokenTraitsProvider.TraitMetadata memory traitMetadata = traitsProvider.getTraitMetadata(
							address(immortal),
							_toUint256(traits.traitType[i][j])
						);
						if (traitMetadata.behavior == ITokenTraitsProvider.Behavior.NOT_SET) {
							continue;
						}

						try
							traitsProvider.getTraitBytesValue(
								address(immortal),
								heroTokens[i],
								_toUint256(traits.traitType[i][j])
							)
						returns (bytes memory traitValueInBytes) {
							// check if the trait value matches and increment the count
							// first get the string value using the utility function
							string memory traitValue = _traitValueToString(traitValueInBytes, traitMetadata.dataType);
							// if the expected trait value is true, then increment the points if the trait is not None or False
							if (_compareValues(traitValue, traits.value[i][j])) {
								userTotalPoints += traits.points[i][j];
							}
						} catch {
							// if the trait is not present, then continue
							continue;
						}
					}
				}
			}

			{
				// Locking the hero tokens until end time
				for (uint256 i = 0; i < heroTokens.length; i++) {
					if (heroTokens[i] == 0) {
						continue;
					}
					immortal.lockSingleToken(heroTokens[i], quest.duration);
				}
			}

			// calculate reward chances - scoped to reduce stack size
			uint256[4] memory rewardChances = [uint256(100), 0, 0, 0];
			unchecked {
				IQuestsV1.QuestReward[] memory rewards = isCampaign
					? campaignQuestsV1.getQuestRewards(string(abi.encodePacked(questId)))
					: sideQuestsV1.getQuestRewards(string(abi.encodePacked(questId)));

				for (uint256 i = 0; i < rewards.length; i++) {
					// if points are less than min threshold, set chance to 0
					if (userTotalPoints < rewards[i].minThreshold) {
						rewardChances[i] = rewards[i].minChance;
						continue;
					}

					uint256 percentChance = (((userTotalPoints - rewards[i].minThreshold) * BASE_DIVDER) * 100) /
						(rewards[i].maxThreshold - rewards[i].minThreshold);

					// make sure the chance is not greater than 100%
					if (percentChance > (BASE_DIVDER * 100)) {
						percentChance = BASE_DIVDER * 100;
					}
					rewardChances[i] =
						((rewards[i].minChance * BASE_DIVDER) +
							(((percentChance / 100) * (rewards[i].maxChance - rewards[i].minChance)) +
								(BASE_DIVDER / 2))) /
						BASE_DIVDER;
				}
			}

			// scoped to reduce stack size
			{
				// add quest to inProgress quests
				inProgressQuests[user][questId] = QuestState(
					questId,
					pinId,
					block.timestamp,
					block.timestamp + quest.duration,
					heroTokens,
					isCampaign ? QuestType.CAMPAIGN_QUEST : QuestType.SIDE_QUEST,
					rewardChances
				);

				// add quest id to inProgress quests ids
				inProgressQuestsIds[user].push(questId);
			}

			// emit event that quest is started
			emit QuestStarted(
				questId,
				user,
				heroTokens,
				block.timestamp,
				block.timestamp + quest.duration,
				rewardChances
			);
		}
	}

	function endQuest(
		address user,
		string calldata questId,
		bool cancelIfNotComplete,
		bool fromDelegate
	) external whenNotPaused {
		if (inProgressQuests[user][questId].startTime == 0) {
			revert QuestNotInProgress(questId);
		}

		// get the quest instance
		QuestState storage questState = inProgressQuests[user][questId];

		if (
			_delegatedMsgSender(fromDelegate) != user && !hasRole(QUEST_MANAGER_ROLE, _delegatedMsgSender(fromDelegate))
		) {
			revert Unauthorized();
		}

		// set up variables
		IQuestsV1 questContract = questState.questType == QuestType.CAMPAIGN_QUEST ? campaignQuestsV1 : sideQuestsV1;

		// get rewards from quest config contract
		IQuestsV1.QuestReward[] memory rewards = questContract.getQuestRewards(questId);
		Reward[] memory rewardsToMint = new Reward[](rewards.length);

		bool cancel = false;

		for (uint256 i = 0; i < questState.heroTokens.length; i++) {
			if (questState.heroTokens[i] == 0) {
				continue;
			}
			try immortal.ownerOf(questState.heroTokens[i]) returns (address owner) {
				// token exists, but the owner is changed or the state isn't locked
				if (owner == user && immortal.locked(questState.heroTokens[i])) {
					immortal.unlockSingleToken(questState.heroTokens[i]);
				} else {
					// token exists, but the owner is changed or the state isn't locked
					cancel = true;
				}
			} catch {
				// token doesnt exist
				cancel = true;
			}
		}

		if (block.timestamp < (questState.endTime - 5 seconds)) {
			if (cancelIfNotComplete == false && cancel == false) {
				revert QuestInProgress(questId, questState.endTime);
			} else {
				cancel = true;
			}
		}

		if (cancel == false) {
			for (uint256 idx = 0; idx < rewards.length; idx++) {
				// calculate the percentage chance of getting a reward
				uint256 random_num = MiscUtils.random(0, 100); // generate a random number between 0 and 100

				if (random_num > questState.rewardChances[idx]) {
					rewardsToMint[idx] = Reward(rewards[idx].rewardType, 0);
				} else {
					// add the reward to rewardsToMint
					rewardsToMint[idx] = Reward(rewards[idx].rewardType, rewards[idx].amount);
				}

				backpackItems.mintWithItemMetaId(user, rewards[idx].rewardType, rewardsToMint[idx].amount, "");
			}
			// increment user's progress if campaign quest
			if (questState.questType == QuestType.CAMPAIGN_QUEST) {
				campaignProgression.incrementUserProgress(user);
			}
		}

		// remove the quest id from inProgress quests ids
		for (uint256 i = 0; i < inProgressQuestsIds[user].length; i++) {
			if (keccak256(abi.encodePacked(inProgressQuestsIds[user][i])) == keccak256(abi.encodePacked(questId))) {
				inProgressQuestsIds[user][i] = inProgressQuestsIds[user][inProgressQuestsIds[user].length - 1];
				inProgressQuestsIds[user].pop();
				break;
			}
		}

		// emit event
		emit QuestEnded(questId, user, questState.heroTokens, rewardsToMint);

		// delete the quest from inProgress quests
		delete inProgressQuests[user][questId];
	}

	function setContracts(
		address sideQuestsV1Address,
		address campaignQuestsV1Address,
		address backpackItemsAddress,
		address immortalAddress,
		address traitsProviderAddress,
		address campaignProgressionAddress,
		address walletDelegationContractAddress
	) external onlyRole(QUEST_MANAGER_ROLE) whenPaused {
		sideQuestsV1 = IQuestsV1(sideQuestsV1Address);
		campaignQuestsV1 = IQuestsV1(campaignQuestsV1Address);
		backpackItems = IBackpackItems(backpackItemsAddress);
		immortal = IImmortals(immortalAddress);
		traitsProvider = ITokenTraitsProvider(traitsProviderAddress);
		campaignProgression = ICampaignProgression(campaignProgressionAddress);
		delegationRegistry = IWalletDelegation(walletDelegationContractAddress);
	}

	function addCompoundTrait(string memory traitId, string[] memory traitTypes) public onlyRole(QUEST_MANAGER_ROLE) {
		compoundTraits[traitId] = traitTypes;
	}

	function pause() public onlyRole(QUEST_MANAGER_ROLE) whenNotPaused {
		_paused = true;
	}

	function unpause() public onlyRole(QUEST_MANAGER_ROLE) whenPaused {
		// require that all the contracts are set
		if (
			address(sideQuestsV1) == address(0) &&
			address(campaignQuestsV1) == address(0) &&
			address(backpackItems) == address(0) &&
			address(immortal) == address(0) &&
			address(traitsProvider) == address(0) &&
			address(campaignProgression) == address(0) &&
			address(delegationRegistry) == address(0)
		) {
			revert contractsNotSet();
		}
		_paused = false;
	}

	// ==================================================
	// ===================== APIs =======================
	// ==================================================
	function getInProgressQuest(address user, string calldata questId) external view returns (QuestState memory) {
		return inProgressQuests[user][questId];
	}

	function batchGetInProgressQuests(
		address user,
		string[] calldata questIds
	) external view returns (QuestState[] memory) {
		QuestState[] memory quests = new QuestState[](questIds.length);

		for (uint256 i = 0; i < questIds.length; i++) {
			quests[i] = inProgressQuests[user][questIds[i]];
		}

		return quests;
	}

	function getInProgressQuestIds(address user) external view returns (string[] memory) {
		return inProgressQuestsIds[user];
	}

	// ==================================================
	// =================== INTERNAL =====================
	// ==================================================

	function _delegatedMsgSender(bool fromDelegate) internal view returns (address) {
		if (fromDelegate) {
			return delegationRegistry.getEoaForDelegateWallet(_msgSender());
		} else {
			return _msgSender();
		}
	}

	function _getDelegateForUser(address user) internal view returns (address) {
		return delegationRegistry.getEoaForDelegateWallet(user);
	}

	function _toUint256(string memory _str) internal pure returns (uint256 val) {
		val = uint256(keccak256(bytes(_str)));
	}

	function _traitValueToString(
		bytes memory traitValue,
		ITokenTraitsProvider.DataType dataType
	) internal pure returns (string memory) {
		if (dataType == ITokenTraitsProvider.DataType.STRING) {
			string memory value = abi.decode(traitValue, (string));
			return value;
		} else if (dataType == ITokenTraitsProvider.DataType.BOOL) {
			bool value = abi.decode(traitValue, (bool));
			return value ? "true" : "false";
		} else if (dataType == ITokenTraitsProvider.DataType.UINT) {
			uint256 value = abi.decode(traitValue, (uint256));
			return value.toString();
		} else if (dataType == ITokenTraitsProvider.DataType.INT) {
			int256 value = abi.decode(traitValue, (int256));
			return MiscUtils.toString(value);
		}
	}

	function _compareValues(string memory traitValue, string memory expectedValue) internal pure returns (bool) {
		if (keccak256(abi.encodePacked(expectedValue)) == keccak256(abi.encodePacked("True"))) {
			if (
				keccak256(abi.encodePacked(traitValue)) != keccak256(abi.encodePacked("None")) &&
				keccak256(abi.encodePacked(traitValue)) != keccak256(abi.encodePacked("False"))
			) {
				return true;
			}
		} else if (keccak256(abi.encodePacked(traitValue)) == keccak256(abi.encodePacked(expectedValue))) {
			return true;
		}
		return false;
	}

	// ====================================================
	// ERC2771Recipient overrides
	// ====================================================
	function setTrustedForwarder(address forwarder) external onlyRole(QUEST_MANAGER_ROLE) {
		_setTrustedForwarder(forwarder);
	}

	function _msgSender()
		internal
		view
		override(ContextUpgradeable, ERC2771RecipientUpgradeable)
		returns (address ret)
	{
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			assembly {
				ret := shr(96, calldataload(sub(calldatasize(), 20)))
			}
		} else {
			ret = msg.sender;
		}
	}

	function _msgData()
		internal
		view
		override(ContextUpgradeable, ERC2771RecipientUpgradeable)
		returns (bytes calldata ret)
	{
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			return msg.data[0:msg.data.length - 20];
		} else {
			return msg.data;
		}
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}