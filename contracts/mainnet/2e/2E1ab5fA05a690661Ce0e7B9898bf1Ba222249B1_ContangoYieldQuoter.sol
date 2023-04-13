// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
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
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.8.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";
import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC1155/IERC1155Receiver.sol";
import "../utils/Address.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl, IERC721Receiver, IERC1155Receiver {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when new proposal is scheduled with non-zero salt.
     */
    event CallSalt(bytes32 indexed id, bytes32 salt);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // optional admin
        if (admin != address(0)) {
            _setupRole(TIMELOCK_ADMIN_ROLE, admin);
        }

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at which an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits events {CallScheduled} and {CallSalt}.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits a {CallSalt} event and one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @dev Schedule an operation that is to become valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        _beforeCall(id, predecessor);
        _execute(target, value, payload);
        emit CallExecuted(id, 0, target, value, payload);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            _execute(target, value, payload);
            emit CallExecuted(id, i, target, value, payload);
        }
        _afterCall(id);
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(address target, uint256 value, bytes calldata data) internal virtual {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
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
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
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
    function admin() external payable ifAdmin returns (address admin_) {
        _requireZeroValue();
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
    function implementation() external payable ifAdmin returns (address implementation_) {
        _requireZeroValue();
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external payable virtual ifAdmin {
        _requireZeroValue();
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external payable ifAdmin {
        _requireZeroValue();
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

    /**
     * @dev To keep this contract fully transparent, all `ifAdmin` functions must be payable. This helper is here to
     * emulate some proxy functions being non-payable while still allowing value to pass through.
     */
    function _requireZeroValue() private {
        require(msg.value == 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../interfaces/IERC4906.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

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
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
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
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
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
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);


    // @dev Assets that are approved as collateral for a series
    function ilks(bytes6 seriesId, bytes6 assetId)
        external
        view
        returns (bool);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "lib/yield-utils-v2/src/token/IERC20.sol";

interface IERC5095 is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address underlyingAddress);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256 timestamp);

    /// @dev Converts a specified amount of principal to underlying
    function convertToUnderlying(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Converts a specified amount of underlying to principal
    function convertToPrincipal(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Gives the maximum amount an address holder can redeem in terms of the principal
    function maxRedeem(address holder) external view returns (uint256 maxPrincipalAmount);

    /// @dev Gives the amount in terms of underlying that the princiapl amount can be redeemed for plus accrual
    function previewRedeem(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Burn fyToken after maturity for an amount of principal.
    function redeem(uint256 principalAmount, address to, address from) external returns (uint256 underlyingAmount);

    /// @dev Gives the maximum amount an address holder can withdraw in terms of the underlying
    function maxWithdraw(address holder) external returns (uint256 maxUnderlyingAmount);

    /// @dev Gives the amount in terms of principal that the underlying amount can be withdrawn for plus accrual
    function previewWithdraw(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function withdraw(uint256 underlyingAmount, address to, address from) external returns (uint256 principalAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC5095.sol";
import "./IJoin.sol";
import "./IOracle.sol";

interface IFYToken is IERC5095 {

    /// @dev Oracle for the savings rate.
    function oracle() view external returns (IOracle);

    /// @dev Source of redemption funds.
    function join() view external returns (IJoin); 

    /// @dev Asset to be paid out on redemption.
    function underlying() view external returns (address);

    /// @dev Yield id of the asset to be paid out on redemption.
    function underlyingId() view external returns (bytes6);

    /// @dev Time at which redemptions are enabled.
    function maturity() view external returns (uint256);

    /// @dev Spot price (exchange rate) between the base and an interest accruing token at maturity, set to 2^256-1 before maturity
    function chiAtMaturity() view external returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "lib/yield-utils-v2/src/token/IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev amount of assets held by this contract
    function storedBalance() external view returns (uint256);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);

    /// @dev Retrieve any tokens other than the `asset`. Useful for airdropped tokens.
    function retrieve(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Router.sol";
import "./IJoin.sol";
import "./ICauldron.sol";
import "./IFYToken.sol";
import "./IOracle.sol";
import "lib/yield-utils-v2/src/interfaces/IWETH9.sol";
import "lib/yieldspace-tv/src/interfaces/IPool.sol";

interface ILadle {

    // ---- Storage ----

    function cauldron() 
        external view
         returns(ICauldron);
    
    function router() 
        external view
         returns(Router);
    
    function weth() 
        external view
         returns(IWETH9);
    
    function borrowingFee() 
        external view
         returns(uint256);

    function joins(bytes6) 
        external view 
        returns (IJoin);

    function pools(bytes6) 
        external view 
        returns (address);

    function modules(address) 
        external view 
        returns (bool);

    function integrations(address) 
        external view 
        returns (bool);

    function tokens(address) 
        external view 
        returns (bool);
    
    // ---- Administration ----

    /// @dev Add or remove an integration.
    function addIntegration(address integration, bool set)
        external;

    /// @dev Add or remove a token that the Ladle can call `transfer` or `permit` on.
    function addToken(address token, bool set)
        external;


    /// @dev Add a new Join for an Asset, or replace an existing one for a new one.
    /// There can be only one Join per Asset. Until a Join is added, no tokens of that Asset can be posted or withdrawn.
    function addJoin(bytes6 assetId, IJoin join)
        external;

    /// @dev Add a new Pool for a Series, or replace an existing one for a new one.
    /// There can be only one Pool per Series. Until a Pool is added, it is not possible to borrow Base.
    function addPool(bytes6 seriesId, IPool pool)
        external;

    /// @dev Add or remove a module.
    /// @notice Treat modules as you would Ladle upgrades. Modules have unrestricted access to the Ladle
    /// storage, and can wreak havoc easily.
    /// Modules must not do any changes to any vault (owner, seriesId, ilkId) because of vault caching.
    /// Modules must not be contracts that can self-destruct because of `moduleCall`.
    /// Modules can't use `msg.value` because of `batch`.
    function addModule(address module, bool set)
        external;

    /// @dev Set the fee parameter
    function setFee(uint256 fee)
        external;

    // ---- Call management ----

    /// @dev Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    function batch(bytes[] calldata calls)
        external payable
        returns(bytes[] memory results);

    /// @dev Allow users to route calls to a contract, to be used with batch
    function route(address integration, bytes calldata data)
        external payable
        returns (bytes memory result);

    /// @dev Allow users to use functionality coded in a module, to be used with batch
    function moduleCall(address module, bytes calldata data)
        external payable
        returns (bytes memory result);

    // ---- Token management ----

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(IERC2612 token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external payable;

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(IERC20 token, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        external payable;

    /// @dev Allow users to trigger a token transfer from themselves to a receiver through the ladle, to be used with batch
    function transfer(IERC20 token, address receiver, uint128 wad)
        external payable;

    /// @dev Retrieve any token in the Ladle
    function retrieve(IERC20 token, address to) 
        external payable
        returns (uint256 amount);

    /// @dev Accept Ether, wrap it and forward it to the WethJoin
    /// This function should be called first in a batch, and the Join should keep track of stored reserves
    /// Passing the id for a join that doesn't link to a contract implemnting IWETH9 will fail
    function joinEther(bytes6 etherId)
        external payable
        returns (uint256 ethTransferred);

    /// @dev Unwrap Wrapped Ether held by this Ladle, and send the Ether
    /// This function should be called last in a batch, and the Ladle should have no reason to keep an WETH balance
    function exitEther(address to)
        external payable
        returns (uint256 ethTransferred);

    // ---- Vault management ----

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function build(bytes6 seriesId, bytes6 ilkId, uint8 salt)
        external payable
        returns(bytes12, DataTypes.Vault memory);

    /// @dev Change a vault series or collateral.
    function tweak(bytes12 vaultId_, bytes6 seriesId, bytes6 ilkId)
        external payable
        returns(DataTypes.Vault memory vault);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId_, address receiver)
        external payable
        returns(DataTypes.Vault memory vault);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vaultId_)
        external payable;

    // ---- Asset and debt management ----

    /// @dev Move collateral and debt between vaults.
    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        external payable;

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    /// Borrow only before maturity.
    function pour(bytes12 vaultId_, address to, int128 ink, int128 art)
        external payable;

    /// @dev Add collateral and borrow from vault, so that a precise amount of base is obtained by the user.
    /// The base is obtained by borrowing fyToken and buying base with it in a pool.
    /// Only before maturity.
    function serve(bytes12 vaultId_, address to, uint128 ink, uint128 base, uint128 max)
        external payable
        returns (uint128 art);

    /// @dev Repay vault debt using underlying token at a 1:1 exchange rate, without trading in a pool.
    /// It can add or remove collateral at the same time.
    /// The debt to repay is denominated in fyToken, even if the tokens pulled from the user are underlying.
    /// The debt to repay must be entered as a negative number, as with `pour`.
    /// Debt cannot be acquired with this function.
    function close(bytes12 vaultId_, address to, int128 ink, int128 art)
        external payable
        returns (uint128 base);

    /// @dev Repay debt by selling base in a pool and using the resulting fyToken
    /// The base tokens need to be already in the pool, unaccounted for.
    /// Only before maturity. After maturity use close.
    function repay(bytes12 vaultId_, address to, int128 ink, uint128 min)
        external payable
        returns (uint128 art);

    /// @dev Repay all debt in a vault by buying fyToken from a pool with base.
    /// The base tokens need to be already in the pool, unaccounted for. The surplus base will be returned to msg.sender.
    /// Only before maturity. After maturity use close.
    function repayVault(bytes12 vaultId_, address to, int128 ink, uint128 max)
        external payable
        returns (uint128 base);

    /// @dev Change series and debt of a vault.
    function roll(bytes12 vaultId_, bytes6 newSeriesId, uint8 loan, uint128 max)
        external payable
        returns (DataTypes.Vault memory vault, uint128 newDebt);

    // ---- Ladle as a token holder ----

    /// @dev Use fyToken in the Ladle to repay debt. Return unused fyToken to `to`.
    /// Return as much collateral as debt was repaid, as well. This function is only used when
    /// removing liquidity added with "Borrow and Pool", so it's safe to assume the exchange rate
    /// is 1:1. If used in other contexts, it might revert, which is fine.
    function repayFromLadle(bytes12 vaultId_, address to)
        external payable
        returns (uint256 repaid);

    /// @dev Use base in the Ladle to repay debt. Return unused base to `to`.
    /// Return as much collateral as debt was repaid, as well. This function is only used when
    /// removing liquidity added with "Borrow and Pool", so it's safe to assume the exchange rate
    /// is 1:1. If used in other contexts, it might revert, which is fine.
    function closeFromLadle(bytes12 vaultId_, address to)
        external payable
        returns (uint256 repaid);

    /// @dev Allow users to redeem fyToken, to be used with batch.
    /// If 0 is passed as the amount to redeem, it redeems the fyToken balance of the Ladle instead.
    function redeem(bytes6 seriesId, address to, uint256 wad)
        external payable
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "lib/yield-utils-v2/src/access/AccessControl.sol";
import "lib/yield-utils-v2/src/utils/Cast.sol";
import "../../interfaces/IOracle.sol";

/**
 * @title CompositeMultiOracle
 */
contract CompositeMultiOracle is IOracle, AccessControl {
    using Cast for bytes32;

    event SourceSet(bytes6 indexed baseId, bytes6 indexed quoteId, IOracle indexed source);
    event PathSet(bytes6 indexed baseId, bytes6 indexed quoteId, bytes6[] indexed path);

    mapping(bytes6 => mapping(bytes6 => IOracle)) public sources;
    mapping(bytes6 => mapping(bytes6 => bytes6[])) public paths;

    /// @notice Set or reset a Yearn Vault Token oracle source and its inverse
    /// @param  baseId id used for underlying base token
    /// @param  quoteId id used for underlying quote token
    /// @param  source Oracle contract for source
    function setSource(
        bytes6 baseId,
        bytes6 quoteId,
        IOracle source
    ) external auth {
        sources[baseId][quoteId] = source;
        emit SourceSet(baseId, quoteId, source);

        if (baseId != quoteId) {
            sources[quoteId][baseId] = source;
            emit SourceSet(quoteId, baseId, source);
        }
    }

    /// @notice Set or reset an price path and its reverse path
    /// @param base Id of base token
    /// @param quote Id of quote token
    /// @param path Path from base to quote
    function setPath(
        bytes6 base,
        bytes6 quote,
        bytes6[] calldata path
    ) external auth {
        uint256 pathLength = path.length;
        bytes6[] memory reverse = new bytes6[](pathLength);
        bytes6 base_ = base;
        unchecked {
            for (uint256 p; p < pathLength; ++p) {
                require(sources[base_][path[p]] != IOracle(address(0)), "Source not found");
                base_ = path[p];
                reverse[pathLength - (p + 1)] = base_;
            }
        }
        paths[base][quote] = path;
        paths[quote][base] = reverse;
        emit PathSet(base, quote, path);
        emit PathSet(quote, base, path);
    }

    /// @notice Convert amountBase base into quote at the latest oracle price, through a path is exists.
    /// @param base Id of base token
    /// @param quote Id of quote token
    /// @param amountBase Amount of base to convert to quote
    /// @return amountQuote Amount of quote token converted from base
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amountBase
    ) external view virtual override returns (uint256 amountQuote, uint256 updateTime) {
        updateTime = type(uint256).max;
        amountQuote = amountBase;
        bytes6 base_ = base.b6();
        bytes6 quote_ = quote.b6();
        bytes6[] memory path = paths[base_][quote_];
        uint256 pathLength = path.length;
        unchecked {
            for (uint256 p; p < pathLength; ++p) {
                (amountQuote, updateTime) = _peek(base_, path[p], amountQuote, updateTime);
                base_ = path[p];
            }
        }
        (amountQuote, updateTime) = _peek(base_, quote_, amountQuote, updateTime);
        require(updateTime <= block.timestamp, "Invalid updateTime");
    }

    /// @notice Convert amountBase base into quote at the latest oracle price, through a path is exists.
    /// @dev This function is transactional
    /// @param base Id of base token
    /// @param quote Id of quote token
    /// @param amountBase Amount of base to convert to quote
    /// @return amountQuote Amount of quote token converted from base
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amountBase
    ) external virtual override returns (uint256 amountQuote, uint256 updateTime) {
        updateTime = type(uint256).max;
        amountQuote = amountBase;
        bytes6 base_ = base.b6();
        bytes6 quote_ = quote.b6();
        bytes6[] memory path = paths[base_][quote_];
        uint256 pathLength = path.length;
        unchecked {
            for (uint256 p; p < pathLength; ++p) {
                (amountQuote, updateTime) = _get(base_, path[p], amountQuote, updateTime);
                base_ = path[p];
            }
        }
        (amountQuote, updateTime) = _get(base_, quote_, amountQuote, updateTime);
        require(updateTime <= block.timestamp, "Invalid updateTime");
    }

    /// @notice Convert amountBase base into quote at the latest oracle price, through a path is exists.
    /// @param base Id of base token
    /// @param quote Id of quote token
    /// @param amountBase Amount of base to convert to quote
    /// @param updateTimeIn Lowest updateTime value obtained received seen until now
    /// @return amountQuote Amount of quote token converted from base
    /// @return updateTimeOut Lower of current price's updateTime or updateTimeIn
    function _peek(
        bytes6 base,
        bytes6 quote,
        uint256 amountBase,
        uint256 updateTimeIn
    ) private view returns (uint256 amountQuote, uint256 updateTimeOut) {
        IOracle source = sources[base][quote];
        require(address(source) != address(0), "Source not found");
        (amountQuote, updateTimeOut) = source.peek(base, quote, amountBase);
        updateTimeOut = (updateTimeOut < updateTimeIn) ? updateTimeOut : updateTimeIn; // Take the oldest update time
    }

    /// @notice Convert amountBase base into quote at the latest oracle price, through a path is exists.
    /// @param base Id of base token
    /// @param quote Id of quote token
    /// @param amountBase Amount of base to convert to quote
    /// @param updateTimeIn Lowest updateTime value obtained received seen until now
    /// @return amountQuote Amount of quote token converted from base
    /// @return updateTimeOut Lower of current price's updateTime or updateTimeIn
    function _get(
        bytes6 base,
        bytes6 quote,
        uint256 amountBase,
        uint256 updateTimeIn
    ) private returns (uint256 amountQuote, uint256 updateTimeOut) {
        IOracle source = sources[base][quote];
        require(address(source) != address(0), "Source not found");
        (amountQuote, updateTimeOut) = source.get(base, quote, amountBase);
        updateTimeOut = (updateTimeOut < updateTimeIn) ? updateTimeOut : updateTimeIn; // Take the oldest update time
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

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
        uint256 twos = (~denominator + 1) & denominator;
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
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

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
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./TickMath.sol";
import "./IUniswapV3Pool.sol";
import "./LowGasSafeMath.sol";
import "./PoolAddress.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @param period Number of seconds in the past to start calculating time-weighted average
    /// @return timeWeightedAverageTick The time-weighted average tick from (block.timestamp - period) to block.timestamp
    function consult(address pool, uint32 period)
        internal
        view
        returns (int24 timeWeightedAverageTick)
    {
        require(period != 0, "BP");

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(
            secondAgos
        );
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(
            tickCumulativesDelta / int56(uint56(period))
        );

        // Always round to negative infinity
        if (
            tickCumulativesDelta < 0 &&
            (tickCumulativesDelta % int56(uint56(period)) != 0)
        ) timeWeightedAverageTick--;
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtRatioX96,
                sqrtRatioX96,
                1 << 64
            );
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
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
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
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
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
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
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/ILadle.sol";

interface IContangoLadle is ILadle {
    function deterministicBuild(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory vault);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContangoWitchListener {
    function auctionStarted(bytes12 vaultId) external;

    function collateralBought(
        bytes12 vaultId,
        address buyer,
        uint256 ink,
        uint256 art
    ) external;

    function auctionEnded(bytes12 vaultId, address owner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;
import "lib/yield-utils-v2/src/utils/RevertMsgExtractor.sol";
import "lib/yield-utils-v2/src/utils/IsContract.sol";


/// @dev Router forwards calls between two contracts, so that any permissions
/// given to the original caller are stripped from the call.
/// This is useful when implementing generic call routing functions on contracts
/// that might have ERC20 approvals or AccessControl authorizations.
contract Router {
    using IsContract for address;

    address immutable public owner;

    constructor () {
        owner = msg.sender;
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function route(address target, bytes calldata data)
        external payable
        returns (bytes memory result)
    {
        require(msg.sender == owner, "Only owner");
        require(target.isContract(), "Target is not a contract");
        bool success;
        (success, result) = target.call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
     */
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
import "../token/IERC20.sol";

pragma solidity ^0.8.0;


interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/src/token/ERC20/ERC20Permit.sol
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC2612.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid),
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _setAllowance(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/src/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library Cast {
    ///@dev library for safe casting of value types

    function b12(bytes32 x) internal pure returns (bytes12 y) {
        require(bytes32(y = bytes12(x)) == x, "Cast overflow");
    }

    function b6(bytes32 x) internal pure returns (bytes6 y) {
        require(bytes32(y = bytes6(x)) == x, "Cast overflow");
    }

    function u256(int256 x) internal pure returns (uint256 y) {
        require(x >= 0, "Cast overflow");
        y = uint256(x);
    }

    function i256(uint256 x) internal pure returns (int256 y) {
        require(x <= uint256(type(int256).max), "Cast overflow");
        y = int256(x);
    }

    function u128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }

    function u128(int256 x) internal pure returns (uint128 y) {
        require(x >= 0, "Cast overflow");
        y = uint128(uint256(x));
    }

    function i128(uint256 x) internal pure returns (int128) {
        require(x <= uint256(int256(type(int128).max)), "Cast overflow");
        return int128(int256(x));
    }

    function i128(int256 x) internal pure returns (int128) {
        require(x <= type(int128).max, "Cast overflow");
        require(x >= type(int128).min, "Cast overflow");
        return int128(x);
    }

    function u112(uint256 x) internal pure returns (uint112 y) {
        require(x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
    }

    function u104(uint256 x) internal pure returns (uint104 y) {
        require(x <= type(uint104).max, "Cast overflow");
        y = uint104(x);
    }

    function u32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

// SPDX-License-Identifier: MIT
// Taken from Address.sol from OpenZeppelin.
pragma solidity ^0.8.0;


library IsContract {
  /// @dev Returns true if `account` is a contract.
  function isContract(address account) internal view returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.
      return account.code.length > 0;
  }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/src/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "lib/yield-utils-v2/src/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "lib/yield-utils-v2/src/token/IERC20.sol";
import "lib/yield-utils-v2/src/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "lib/yield-utils-v2/src/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./IPool.sol";

interface IPoolOracle {
    /// @notice returns the TWAR for a given `pool` using the moving average over the max available time range within the window
    /// @param pool Address of pool for which the observation is required
    /// @return twar The most up to date TWAR for `pool`
    function peek(IPool pool) external view returns (uint256 twar);

    /// @notice returns the TWAR for a given `pool` using the moving average over the max available time range within the window
    /// @dev will try to record a new observation if necessary, so equivalent to `update(pool); peek(pool);`
    /// @param pool Address of pool for which the observation is required
    /// @return twar The most up to date TWAR for `pool`
    function get(IPool pool) external returns (uint256 twar);

    /// @notice updates the cumulative ratio for the observation at the current timestamp. Each observation is updated at most
    /// once per epoch period.
    /// @param pool Address of pool for which the observation should be recorded
    /// @return updated Flag to indicate if the observation at the current timestamp was actually updated
    function updatePool(IPool pool) external returns(bool updated);

    /// @notice updates the cumulative ratio for the observation at the current timestamp. Each observation is updated at most
    /// once per epoch period.
    /// @param pools Addresses of pool for which the observation should be recorded
    function updatePools(IPool[] calldata pools) external;

    /// Returns how much fyToken would be required to buy `baseOut` base.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseOut Amount of base hypothetically desired.
    /// @return fyTokenIn Amount of fyToken hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function getBuyBasePreview(IPool pool, uint256 baseOut) external returns (uint256 fyTokenIn, uint256 updateTime);

    /// Returns how much base would be required to buy `fyTokenOut`.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @return baseIn Amount of base hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function getBuyFYTokenPreview(IPool pool, uint256 fyTokenOut) external returns (uint256 baseIn, uint256 updateTime);

    /// Returns how much fyToken would be obtained by selling `baseIn`.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseIn Amount of base hypothetically sold.
    /// @return fyTokenOut Amount of fyToken hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function getSellBasePreview(IPool pool, uint256 baseIn) external returns (uint256 fyTokenOut, uint256 updateTime);

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @notice This function will also record a new snapshot on the oracle if necessary,
    /// so it's the preferred one, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return baseOut Amount of base hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function getSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external
        returns (uint256 baseOut, uint256 updateTime);

    /// Returns how much fyToken would be required to buy `baseOut` base.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseOut Amount of base hypothetically desired.
    /// @return fyTokenIn Amount of fyToken hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekBuyBasePreview(IPool pool, uint256 baseOut) external view returns (uint256 fyTokenIn, uint256 updateTime);

    /// Returns how much base would be required to buy `fyTokenOut`.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @return baseIn Amount of base hypothetically required.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekBuyFYTokenPreview(IPool pool, uint256 fyTokenOut)
        external view
        returns (uint256 baseIn, uint256 updateTime);

    /// Returns how much fyToken would be obtained by selling `baseIn`.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param baseIn Amount of base hypothetically sold.
    /// @return fyTokenOut Amount of fyToken hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekSellBasePreview(IPool pool, uint256 baseIn) external view returns (uint256 fyTokenOut, uint256 updateTime);

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @notice This function is view and hence it will not try to update the oracle
    /// so it should be avoided when possible, as if the oracle doesn't get updated periodically, it'll stop working
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return baseOut Amount of base hypothetically bought.
    /// @return updateTime Timestamp for when this price was calculated.
    function peekSellFYTokenPreview(IPool pool, uint256 fyTokenIn)
        external view
        returns (uint256 baseOut, uint256 updateTime);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// Inspired by: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batchable {
    error TransactionRevertedSilently();

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @return results An array with the outputs for each call.
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i; i < calls.length;) {
            results[i] = _delegatecall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev modified from https://ethereum.stackexchange.com/questions/109457/how-to-bubble-up-a-custom-error-when-using-delegatecall
    function _delegatecall(bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (!success) {
            if (returnData.length == 0) revert TransactionRevertedSilently();
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }
        return returnData;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/dss-interfaces/src/dss/DaiAbstract.sol";
import "../libraries/ConfigStorageLib.sol";

abstract contract PermitForwarder {
    using SafeERC20 for IERC20Permit;

    error UnknownToken(address token);

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(
        IERC20Permit token,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.safePermit(msg.sender, spender, amount, deadline, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(
        DaiAbstract token,
        address spender,
        uint256 nonce,
        uint256 deadline,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (ConfigStorageLib.isTrustedToken(address(token))) {
            token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
        } else {
            revert UnknownToken(address(token));
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/WETH.sol";
import "lib/solmate/src/utils/SafeTransferLib.sol";
import "../libraries/Errors.sol";

abstract contract WethHandler {
    using SafeTransferLib for address payable;

    error NothingToWrap();

    WETH public immutable weth;

    constructor(WETH _weth) {
        weth = _weth;
    }

    function wrapETH() external payable returns (uint256 wrapped) {
        wrapped = address(this).balance;
        if (wrapped == 0) {
            revert NothingToWrap();
        }
        weth.deposit{value: wrapped}();
    }

    function unwrapWETH(address payable to) external payable returns (uint256 unwrapped) {
        unwrapped = weth.balanceOf(address(this));
        // We don't wanna act on 0 unwrap as some batch calls may add it just in case
        if (unwrapped != 0) {
            weth.withdraw(unwrapped);
            to.safeTransferETH(unwrapped);
        }
    }

    /// @dev `weth.withdraw` will send ether using this function.
    receive() external payable virtual {
        if (msg.sender != address(weth)) {
            revert OnlyFromWETH(msg.sender);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./libraries/DataTypes.sol";

/// @title ContangoPositionNFT
/// @notice An ERC721 NFT that represents ownership of each position created through the protocol
/// @author Bruno Bonanno
/// @dev Instances can only be minted by other contango contracts
contract ContangoPositionNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant ARTIST = keccak256("ARTIST");

    PositionId public nextPositionId = PositionId.wrap(1);

    constructor() ERC721("Contango Position", "CTGP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice creates a new position in the protocol by minting a new NFT instance
    /// @param to The would be owner of the newly minted position
    /// @return positionId The newly created positionId
    function mint(address to) external onlyRole(MINTER) returns (PositionId positionId) {
        positionId = nextPositionId;
        uint256 _positionId = PositionId.unwrap(positionId);
        nextPositionId = PositionId.wrap(_positionId + 1);
        _safeMint(to, _positionId);
    }

    /// @notice closes a position in the protocol by burning the NFT instance
    /// @param positionId positionId of the closed position
    function burn(PositionId positionId) external onlyRole(MINTER) {
        _burn(PositionId.unwrap(positionId));
    }

    function positionOwner(PositionId positionId) external view returns (address) {
        return ownerOf(PositionId.unwrap(positionId));
    }

    function positionURI(PositionId positionId) external view returns (string memory) {
        return tokenURI(PositionId.unwrap(positionId));
    }

    function setPositionURI(PositionId positionId, string memory _tokenURI) external onlyRole(ARTIST) {
        _setTokenURI(PositionId.unwrap(positionId), _tokenURI);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165.
     *
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return AccessControl.supportsInterface(interfaceId) || ERC721URIStorage.supportsInterface(interfaceId);
    }

    /// @dev returns all the positions a trader has between the provided boundaries
    /// @param owner Trader that owns the positions
    /// @param from Starting position to consider for the search (inclusive)
    /// @param to Ending position to consider for the search (exclusive)
    /// @return tokens Array with all the positions the trader owns within the range.
    /// Array size could be bigger than effective result set if the trader owns positions outside the range
    /// PositionId == 0 is always invalid, so as soon it shows up in the array is safe to assume the rest of it is empty
    function positions(address owner, PositionId from, PositionId to)
        external
        view
        returns (PositionId[] memory tokens)
    {
        uint256 count;
        uint256 balance = balanceOf(owner);
        tokens = new PositionId[](balance);
        uint256 _from = PositionId.unwrap(from);
        uint256 _to = Math.min(PositionId.unwrap(to), PositionId.unwrap(nextPositionId));

        for (uint256 i = _from; i < _to; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                tokens[count++] = PositionId.wrap(i);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFlashLoaner {
    function flashLoan(
        IFlashLoanRecipient recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @dev strip down version of https://github.com/Uniswap/v3-core/blob/864efb5bb57bd8bde4689cfd8f7fd7ddeb100524/contracts/libraries/TickMath.sol
/// the published version doesn't compile on solidity 0.8.x
library TickMath {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
}

/// @dev taken from https://github.com/Uniswap/v3-periphery/blob/090e908ba7d8006a616d41c8951aed26a8c3dd1c/contracts/libraries/PoolAddress.sol
/// added casting to uint160 on L49 to make it compile for solidity 0.8.x
/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1, "Invalid PoolKey");
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Force solc/typechain to compile test only dependencies
import "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {IPoolOracle} from "lib/yieldspace-tv/src/interfaces/IPoolOracle.sol";

import {CompositeMultiOracle} from "lib/vault-v2/src/oracles/composite/CompositeMultiOracle.sol";
import {IFYToken} from "lib/vault-v2/src/interfaces/IFYToken.sol";

import "./IWETH9.sol";
import "../periphery/CashSettler.sol";

// Stubs
import {ChainlinkAggregatorV2V3Mock} from "test/stub/ChainlinkAggregatorV2V3Mock.sol";
import {UniswapPoolStub} from "test/stub/UniswapPoolStub.sol";
import {IPoolStub} from "test/stub/IPoolStub.sol";
import {IOraclePoolStub} from "test/stub/IOraclePoolStub.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    // Only valid for Arbitrum
    function depositTo(address account) external payable;

    function withdrawTo(address account, uint256 amount) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "./interfaces/IContango.sol";
import "./interfaces/IFeeModel.sol";
import "./libraries/CodecLib.sol";
import "./libraries/ConfigStorageLib.sol";
import "./libraries/StorageLib.sol";
import "./libraries/TransferLib.sol";

/// @dev This set of methods process the result of an execution, update the internal accounting and transfer funds if required
library ExecutionProcessorLib {
    using SafeCast for *;
    using Math for uint256;
    using SignedMath for int256;
    using TransferLib for ERC20;
    using CodecLib for uint256;

    /// @dev IMPORTANT - make sure the events here are the same as in IContangoEvents
    /// this is needed because we're in a library and can't re-use events from an interface

    event PositionUpserted(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionLiquidated(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        int256 realisedPnL
    );

    event PositionClosed(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 closedQuantity,
        uint256 closedCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionDelivered(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        address to,
        uint256 deliveredQuantity,
        uint256 deliveryCost,
        uint256 totalFees
    );

    function deliverPosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 deliverableQuantity,
        uint256 deliveryCost,
        address payer,
        ERC20 quoteToken,
        address to
    ) internal {
        delete StorageLib.getPositionNotionals()[positionId];

        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (, uint256 protocolFees,) = _applyFees(trader, symbol, positionId, deliveryCost);
        delete balances[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(payer, ConfigStorageLib.getTreasury(), protocolFees);
        }

        emit PositionDelivered(symbol, trader, positionId, to, deliverableQuantity, deliveryCost, protocolFees);
    }

    function updateCollateral(Symbol symbol, PositionId positionId, address trader, int256 cost, int256 amount)
        internal
    {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) =
            _applyFees(trader, symbol, positionId, cost.abs() + amount.abs());

        openCost = (openCost.toInt256() + cost).toUint256();
        collateral = collateral + amount;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, 0);
    }

    function increasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        int256 positionCollateral;
        uint256 protocolFees;
        uint256 fee;

        // For a new position
        if (openQuantity == 0) {
            fee = _fee(trader, symbol, positionId, cost);
            positionCollateral = collateralDelta - fee.toInt256();
            protocolFees = fee;
        } else {
            (positionCollateral, protocolFees, fee) = _applyFees(trader, symbol, positionId, cost);
            positionCollateral = positionCollateral + collateralDelta;

            // When increasing positions, the user can request to withdraw part (or all) the free collateral
            if (collateralDelta < 0 && address(this) != to) {
                quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
            }
        }

        openCost = openCost + cost;
        _validateMinCost(openCost, minCost);
        openQuantity = openQuantity + size;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, positionCollateral, protocolFees, fee, 0);
    }

    function decreasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl;
        {
            // Proportion of the openCost based on the size of the fill respective of the overall position size
            uint256 closedCost = (size * openCost).ceilDiv(openQuantity);
            pnl = cost.toInt256() - closedCost.toInt256();
            openCost = openCost - closedCost;
            _validateMinCost(openCost, minCost);
            openQuantity = openQuantity - size;

            // Crystallised PnL is accounted on the collateral
            collateral = collateral + pnl + collateralDelta;
        }

        // When decreasing positions, the user can request to withdraw part (or all) the proceedings
        if (collateralDelta < 0 && address(this) != to) {
            quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
        }

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function closePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 cost,
        ERC20 quoteToken,
        address to
    ) internal {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl = cost.toInt256() - openCost.toInt256();

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        delete notionals[positionId];
        delete StorageLib.getPositionBalances()[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(address(this), ConfigStorageLib.getTreasury(), protocolFees);
        }
        if (collateral > 0 && to != address(this)) {
            quoteToken.transferOut(address(this), to, uint256(collateral));
        }

        emit PositionClosed(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function liquidatePosition(Symbol symbol, PositionId positionId, address trader, uint256 size, uint256 cost)
        internal
    {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, int256 protocolFees) = balances[positionId].decodeI128();

        // Proportion of the openCost based on the size of the fill respective of the overall position size
        uint256 closedCost = size == openQuantity ? openCost : (size * openCost).ceilDiv(openQuantity);
        int256 pnl = cost.toInt256() - closedCost.toInt256();
        openCost = openCost - closedCost;
        openQuantity = openQuantity - size;

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        notionals[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        balances[positionId] = CodecLib.encodeI128(collateral, protocolFees);
        emit PositionLiquidated(symbol, trader, positionId, openQuantity, openCost, collateral, pnl);
    }

    // ============= Private functions ================

    function _applyFees(address trader, Symbol symbol, PositionId positionId, uint256 cost)
        private
        view
        returns (int256 collateral, uint256 protocolFees, uint256 fee)
    {
        int256 iProtocolFees;
        (collateral, iProtocolFees) = StorageLib.getPositionBalances()[positionId].decodeI128();
        protocolFees = iProtocolFees.toUint256();
        fee = _fee(trader, symbol, positionId, cost);
        if (fee > 0) {
            collateral = collateral - fee.toInt256();
            protocolFees = protocolFees + fee;
        }
    }

    function _fee(address trader, Symbol symbol, PositionId positionId, uint256 cost) private view returns (uint256) {
        IFeeModel feeModel = StorageLib.getInstrumentFeeModel()[symbol];
        return address(feeModel) != address(0) ? feeModel.calculateFee(trader, positionId, cost) : 0;
    }

    function _updatePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 protocolFees,
        uint256 fee,
        int256 pnl
    ) private {
        StorageLib.getPositionNotionals()[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        StorageLib.getPositionBalances()[positionId] = CodecLib.encodeI128(collateral, protocolFees.toInt256());
        emit PositionUpserted(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function _validateMinCost(uint256 openCost, uint256 minCost) private pure {
        if (openCost < minCost * MIN_DEBT_MULTIPLIER) {
            revert IContango.PositionIsTooSmall(openCost, minCost * MIN_DEBT_MULTIPLIER);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IContangoView.sol";

uint256 constant MIN_DEBT_MULTIPLIER = 5;

interface IContangoEvents {
    /// @dev due to solidity technical limitations, the actual events are declared again where they are emitted, e.g. ExecutionProcessorLib

    event PositionUpserted(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionLiquidated(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        int256 realisedPnL
    );

    event PositionClosed(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 closedQuantity,
        uint256 closedCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionDelivered(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        address to,
        uint256 deliveredQuantity,
        uint256 deliveryCost,
        uint256 totalFees
    );

    event ContractBought(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );
    event ContractSold(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );

    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
}

/// @title Interface to allow for position management
interface IContango is IContangoView, IContangoEvents {
    // ====================================== Errors ======================================

    /// @dev when opening/modifying position, if resulting cost is less than min debt * MIN_DEBT_MULTIPLIER
    error PositionIsTooSmall(uint256 openCost, uint256 minCost);

    // ====================================== Functions ======================================

    /// @notice Creates a new position in the system by performing a trade of `quantity` at `limitCost` with `collateral`
    /// @param symbol Symbol of the instrument to be traded
    /// @param trader Which address will own the position
    /// @param quantity Desired position size. Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral Amount the user will post to secure the leveraged trade. Always expressed in quote currency
    /// @param payer Which address will post the `collateral`
    /// @param lendingLiquidity Liquidity for the lending leg, we'll mint tokens 1:1 if said liquidity is not enough
    /// @param uniswapFee The fee (pool) to be used for the trade
    /// @return positionId Id of the newly created position
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable returns (PositionId positionId);

    /// @notice Modifies an existing position, changing its size & collateral (optional)
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param quantity Quantity to be increased (> 0) or decreased (< 0). Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral < 0 ? How much equity should be sent to `payerOrReceiver` : How much collateral will be taken from `payerOrReceiver` and added to the position
    /// @param payerOrReceiver Which address will receive the funds if `collateral` > 0, or which address will pay for them if `collateral` > 0
    /// @param lendingLiquidity Deals with low liquidity, when decreasing, pay debt 1:1, when increasing lend tokens 1:1
    /// @param uniswapFee The fee (pool) to be used for the trade
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable;

    /// @notice Modifies an existing position, adding or removing collateral
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param collateral < 0 ? How much equity should be sent to `payerOrReceiver` : How much collateral will be taken from `payerOrReceiver` and added to the position
    /// @param slippageTolerance the min/max amount the trader is willing to receive/pay
    /// @param payerOrReceiver Which address will pay/receive the `collateral`
    /// @param lendingLiquidity Liquidity for the lending leg, we'll mint tokens 1:1 if said liquidity is not enough. Ignored if `collateral` < 0
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable;

    /// @notice Delivers an expired position by receiving the remaining payment for the leveraged position and physically delivering it
    /// @param positionId the id of an expired position, the caller of this method must be its owner
    /// @param payer Which address will pay for the remaining cost
    /// @param to Which address will receive the base currency
    function deliver(PositionId positionId, address payer, address to) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";
import "../ContangoPositionNFT.sol";

interface IContangoAdminEvents {
    event ClosingOnlySet(bool closingOnly);
    event ClosingOnlySet(Symbol indexed symbol, bool closingOnly);
    event FeeModelUpdated(Symbol indexed symbol, IFeeModel feeModel);
    event PositionNFTSet(ContangoPositionNFT positionNFT);
    event TokenTrusted(address indexed token, bool trusted);
    event TreasurySet(address treasury);
}

interface IContangoAdmin is IContangoAdminEvents {
    function setClosingOnly(bool closingOnly) external;
    function setClosingOnly(Symbol symbol, bool closingOnly) external;
    function setFeeModel(Symbol symbol, IFeeModel feeModel) external;
    function setTrustedToken(address token, bool trusted) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "src/libraries/DataTypes.sol";

interface IContangoOracle {
    function closingCost(PositionId positionId, uint24 uniswapFee, uint32 uniswapPeriod)
        external
        returns (uint256 cost);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/QuoterDataTypes.sol";

/// @title Interface to allow for quoting position operations
interface IContangoQuoter {
    error InsufficientLiquidity();

    /// @notice Quotes the position status
    /// @param positionId The id of a position
    /// @param uniswapFee The fee (pool) to be used for the quote
    /// @return position status
    function positionStatus(PositionId positionId, uint24 uniswapFee) external returns (PositionStatus memory);

    /// @notice Quotes the cost to open a position with the respective collateral used
    /// @param params opening cost parameters
    /// @param collateral How much quote ccy the user will post, if the value is too big/small, a calculated max/min will be used instead
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPositionWithCollateral(OpeningCostParams calldata params, uint256 collateral)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to open a position with the respective leverage used
    /// @param params opening cost parameters
    /// @param leverage Ratio between collateral and debt, if the value is too big/small, a calculated max/min will be used instead. 18 decimals number, 1e18 = 1x
    /// @return opening cost result
    /// Will either be the same as minCollateral in case the collateral passed is insufficient, the same as the collateral passed or capped to the maximum collateralisation possible
    function openingCostForPositionWithLeverage(OpeningCostParams calldata params, uint256 leverage)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and collateral
    /// @param params modify cost parameters
    /// @param collateral How much the collateral of the position should change by, if the value is too big/small, a calculated max/min will be used instead
    /// @return modify cost result
    function modifyCostForPositionWithCollateral(ModifyCostParams calldata params, int256 collateral)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to modify a position with the respective qty change and leverage
    /// @param params modify cost parameters
    /// @param leverage Ratio between collateral and debt, if the value is too big/small, a calculated max/min will be used instead. 18 decimals number, 1e18 = 1x
    /// @return modify cost result
    function modifyCostForPositionWithLeverage(ModifyCostParams calldata params, uint256 leverage)
        external
        returns (ModifyCostResult memory);

    /// @notice Quotes the cost to deliver an expired position
    /// @param positionId the id of an expired position
    /// @return Cost to deliver position
    function deliveryCostForPosition(PositionId positionId) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";
import "./IFeeModel.sol";

/// @title Interface to state querying
interface IContangoView {
    function closingOnly() external view returns (bool);
    function feeModel(Symbol symbol) external view returns (IFeeModel);
    function position(PositionId positionId) external view returns (Position memory _position);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";

interface IFeeModel {
    /// @notice Calculates fees for a given trade
    /// @param trader The trade trader
    /// @param positionId The trade position id
    /// @param cost The trade cost
    /// @return calculatedFee The calculated fee of the trade cost
    function calculateFee(address trader, PositionId positionId, uint256 cost)
        external
        view
        returns (uint256 calculatedFee);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";

interface IOrderManagerEvents {
    // ====================================== Linked Order Events ======================================

    enum OrderType {
        TakeProfit,
        StopLoss
    }

    event LinkedOrderPlaced(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost
    );

    event LinkedOrderCancelled(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost
    );

    event LinkedOrderExecuted(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost,
        uint256 keeperReward,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    );

    // ====================================== Lever Order Events ======================================

    event LeverOrderPlaced(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    );

    event LeverOrderCancelled(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    );

    event LeverOrderExecuted(
        bytes32 indexed orderHash,
        address indexed trader,
        PositionId indexed positionId,
        uint256 keeperReward,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 actualLeverage,
        uint256 oraclePriceTolerance,
        uint256 lendingLiquidity,
        bool recurrent
    );

    // ====================================== Errors ======================================

    error NotPositionOwner();
    error PositionNotApproved();
    error OrderNotFound();
    error PnlNotReached(int256 actualPnl, int256 expectedPnl);
    error LeverageNotReached(uint256 currentLeverage, uint256 triggerLeverage);
    error TriggerCostNotReached(uint256 currentCost, uint256 triggerCost);
}

interface IOrderManager is IOrderManagerEvents {
    // ====================================== Linked Orders ======================================

    function placeLinkedOrder(PositionId positionId, OrderType orderType, uint256 triggerCost, uint256 limitCost)
        external;

    function executeLinkedOrder(
        PositionId positionId,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external returns (uint256 keeperReward);

    function cancelLinkedOrder(PositionId positionId, OrderType orderType, uint256 triggerCost, uint256 limitCost)
        external;

    // ====================================== Lever Orders ======================================

    function placeLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    ) external;

    function executeLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        uint256 lendingLiquidity,
        bool recurrent
    ) external returns (uint256 keeperReward);

    function cancelLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    ) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library CodecLib {
    error InvalidInt128(int256 n);
    error InvalidUInt128(uint256 n);

    modifier validInt128(int256 n) {
        if (int128(n) != n) {
            revert InvalidInt128(n);
        }
        _;
    }

    modifier validUInt128(uint256 n) {
        if (uint128(n) != n) {
            revert InvalidUInt128(n);
        }
        _;
    }

    function encodeU128(uint256 a, uint256 b) internal pure validUInt128(a) validUInt128(b) returns (uint256 encoded) {
        encoded = a << 128 | b;
    }

    function decodeU128(uint256 encoded) internal pure returns (uint128 a, uint128 b) {
        a = uint128(encoded >> 128);
        b = uint128(encoded);
    }

    function encodeI128(int256 a, int256 b) internal pure validInt128(a) validInt128(b) returns (uint256 encoded) {
        encoded = uint256(a) << 128 | uint128(int128(b));
    }

    function decodeI128(uint256 encoded) internal pure returns (int128 a, int128 b) {
        a = int128(uint128(encoded >> 128));
        b = int128(uint128(encoded));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";

import "../ContangoPositionNFT.sol";

library ConfigStorageLib {
    bytes32 private constant TREASURY = keccak256("ConfigStorageLib.TREASURY");
    bytes32 private constant NFT = keccak256("ConfigStorageLib.NFT");
    bytes32 private constant CLOSING_ONLY = keccak256("ConfigStorageLib.CLOSING_ONLY");
    bytes32 private constant TRUSTED_TOKENS = keccak256("ConfigStorageLib.TRUSTED_TOKENS");
    bytes32 private constant PROXY_HASH = keccak256("ConfigStorageLib.PROXY_HASH");

    function getTreasury() internal view returns (address) {
        return StorageSlot.getAddressSlot(TREASURY).value;
    }

    function setTreasury(address treasury) internal {
        StorageSlot.getAddressSlot(TREASURY).value = treasury;
    }

    function getPositionNFT() internal view returns (ContangoPositionNFT) {
        return ContangoPositionNFT(StorageSlot.getAddressSlot(NFT).value);
    }

    function setPositionNFT(ContangoPositionNFT nft) internal {
        StorageSlot.getAddressSlot(NFT).value = address(nft);
    }

    function getClosingOnly() internal view returns (bool) {
        return StorageSlot.getBooleanSlot(CLOSING_ONLY).value;
    }

    function setClosingOnly(bool closingOnly) internal {
        StorageSlot.getBooleanSlot(CLOSING_ONLY).value = closingOnly;
    }

    function isTrustedToken(address token) internal view returns (bool) {
        return _getAddressToBoolMapping(TRUSTED_TOKENS)[token];
    }

    function setTrustedToken(address token, bool trusted) internal {
        _getAddressToBoolMapping(TRUSTED_TOKENS)[token] = trusted;
    }

    function getProxyHash() internal view returns (bytes32) {
        return StorageSlot.getBytes32Slot(PROXY_HASH).value;
    }

    function setProxyHash(bytes32 proxyHash) internal {
        StorageSlot.getBytes32Slot(PROXY_HASH).value = proxyHash;
    }

    // solhint-disable no-inline-assembly
    function _getAddressToBoolMapping(bytes32 slot) private pure returns (mapping(address => bool) storage store) {
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IFeeModel.sol";
import "lib/solmate/src/tokens/ERC20.sol";
import {IFYToken} from "lib/vault-v2/src/interfaces/IFYToken.sol";
import {IPool} from "lib/yieldspace-tv/src/interfaces/IPool.sol";

type Symbol is bytes32;

type PositionId is uint256;

struct Position {
    Symbol symbol;
    uint256 openQuantity; // total quantity to which the trader is exposed
    uint256 openCost; // total amount that the trader exchanged for base
    int256 collateral; // Trader collateral
    uint256 protocolFees; // Fees this position accrued
    uint32 maturity; // Position maturity
    IFeeModel feeModel; // Fee model for this position
}

// Represents an execution of a trade, kinda similar to an execution report in FIX
struct Fill {
    uint256 size; // Size of the fill (base ccy)
    uint256 cost; // Amount of quote traded in exchange for the base
    uint256 hedgeSize; // Actual amount of base ccy traded on the spot market
    uint256 hedgeCost; // Actual amount of quote ccy traded on the spot market
    int256 collateral; // Amount of collateral added/removed by this fill
}

struct YieldInstrument {
    uint32 maturity;
    bool closingOnly;
    bytes6 baseId;
    ERC20 base;
    IFYToken baseFyToken;
    IPool basePool;
    bytes6 quoteId;
    ERC20 quote;
    IFYToken quoteFyToken;
    IPool quotePool;
    uint96 minQuoteDebt;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

error ClosingOnly();

error InstrumentClosingOnly(Symbol symbol);

error InstrumentAlreadyExists(Symbol symbol);

error InstrumentExpired(Symbol symbol, uint32 maturity, uint256 timestamp);

error InvalidInstrument(Symbol symbol);

error InvalidPayer(PositionId positionId, address payer);

error InvalidPosition(PositionId positionId);

error InvalidPositionDecrease(PositionId positionId, int256 decreaseQuantity, uint256 currentQuantity);

error InvalidQuantity(int256 quantity);

error NotPositionOwner(PositionId positionId, address msgSender, address actualOwner);

error PositionActive(PositionId positionId, uint32 maturity, uint256 timestamp);

error PositionExpired(PositionId positionId, uint32 maturity, uint256 timestamp);

error ViewOnly();

error OnlyFromWETH(address sender);

error InvalidSelector(bytes4 selector);

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

library MathLib {
    /// Scales a value from a precision to another
    /// @param value value to be scaled
    /// @param fromPrecision param value precision on exponent form, e.g. 18 decimals -> 1e18
    /// @param toPrecision precision to scale value to on exponent form, e.g. 6 decimals -> 1e6
    /// @param roundCeiling whether to round ceiling or not when down scaling
    /// @return scaled value
    function scale(uint256 value, uint256 fromPrecision, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256 scaled)
    {
        if (fromPrecision > toPrecision) {
            uint256 adjustment = fromPrecision / toPrecision;
            scaled = roundCeiling ? Math.ceilDiv(value, adjustment) : value / adjustment;
        } else if (fromPrecision < toPrecision) {
            scaled = value * (toPrecision / fromPrecision);
        } else {
            scaled = value;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CodecLib.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ConfigStorageLib.sol";
import "./StorageLib.sol";

library PositionLib {
    using CodecLib for uint256;

    function lookupPositionOwner(PositionId positionId) internal view returns (address trader) {
        trader = ConfigStorageLib.getPositionNFT().positionOwner(positionId);
        if (msg.sender != trader) {
            revert NotPositionOwner(positionId, msg.sender, trader);
        }
    }

    function validatePosition(PositionId positionId) internal view returns (uint256 openQuantity) {
        (openQuantity,) = StorageLib.getPositionNotionals()[positionId].decodeU128();

        // Position was fully liquidated
        if (openQuantity == 0) {
            (int256 collateral,) = StorageLib.getPositionBalances()[positionId].decodeI128();
            // Negative collateral means there's nothing left for the trader to get
            if (0 > collateral) {
                revert InvalidPosition(positionId);
            }
        }
    }

    function validateExpiredPosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, InstrumentStorage memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrument.maturity, timestamp);
        }
    }

    function validateActivePosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, InstrumentStorage memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrument.maturity, timestamp);
        }
    }

    function loadActivePosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, address owner, Symbol symbol, InstrumentStorage memory instrument)
    {
        owner = lookupPositionOwner(positionId);
        (openQuantity, symbol, instrument) = validateActivePosition(positionId);
    }

    function validatePayer(PositionId positionId, address payer, address trader) internal view {
        if (payer != trader && payer != address(this) && payer != msg.sender) {
            revert InvalidPayer(positionId, payer);
        }
    }

    function deletePosition(PositionId positionId) internal {
        StorageLib.getPositionInstrument()[positionId] = Symbol.wrap("");
        ConfigStorageLib.getPositionNFT().burn(positionId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

library ProxyLib {
    /// Computes proxy address following EIP-1014 https://eips.ethereum.org/EIPS/eip-1014#specification
    /// @param positionId Position id used for the salt
    /// @param creator Address that created the proxy
    /// @param proxyHash Proxy bytecode hash
    /// @return computed proxy address
    function computeProxyAddress(PositionId positionId, address creator, bytes32 proxyHash)
        internal
        pure
        returns (address payable)
    {
        return payable(address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", creator, positionId, proxyHash))))));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

struct OpeningCostParams {
    Symbol symbol; // InstrumentStorage to be used
    uint256 quantity; // Size of the position
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
    uint24 uniswapFee; // The fee to be used for the quote
}

struct ModifyCostParams {
    PositionId positionId;
    int256 quantity; // How much the size of the position should change by
    uint256 collateralSlippage; // How much add to minCollateral and remove from maxCollateral to avoid issues with min/max debt. In %, 1e18 == 100%
    uint24 uniswapFee; // The fee to be used for the quote
}

// What does the signed cost mean?
// In general, it'll be negative when quoting cost to open/increase, and positive when quoting cost to close/decrease.
// However, there are certain situations where that general rule may not hold true, for example when the qty delta is small and the collateral delta is big.
// Scenarios include:
//      * increase position by a tiny bit, but add a lot of collateral at the same time (aka. burn existing debt)
//      * decrease position by a tiny bit, withdraw a lot of excess equity at the same time (aka. issue new debt)
// For this reason, we cannot get rid of the signing, and make assumptions about in which direction the cost will go based on the qty delta alone.
// The effect (or likeliness of this coming into play) is much greater when the funding currency (quote) has a high interest rate.
struct ModifyCostResult {
    int256 spotCost; // The current spot cost of a given position quantity
    int256 cost; // See comment above for explanation of why the cost is signed.
    int256 financingCost; // The cost to increase/decrease collateral. We need to return this breakdown of cost so the UI knows which values to pass to 'modifyCollateral'
    int256 debtDelta; // if negative, it's the amount repaid. If positive, it's the amount of new debt issued.
    int256 collateralUsed; // Collateral used to open/increase position with returned cost
    int256 minCollateral; // Minimum collateral needed to perform modification. If negative, it's the MAXIMUM amount that CAN be withdrawn.
    int256 maxCollateral; // Max collateral allowed to open/increase a position. If negative, it's the MINIMUM amount that HAS TO be withdrawn.
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    uint256 fee;
    uint128 minDebt;
    uint256 baseLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    uint256 quoteLendingLiquidity; // Liquidity available for lending, either in PV or FV depending on the operation(s) quoted
    // relevant to closing only
    bool needsBatchedCall;
}

struct PositionStatus {
    uint256 spotCost; // The current spot cost of a given position quantity
    uint256 underlyingDebt; // Value of debt 1:1 with real underlying (Future Value)
    uint256 underlyingCollateral; // Value of collateral in debt terms
    uint256 liquidationRatio; // The ratio at which a position becomes eligible for liquidation (underlyingCollateral/underlyingDebt)
    bool liquidating; // When true, no actions are allowed over the position
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IQuoter} from "lib/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../interfaces/IContangoView.sol";
import "../ContangoPositionNFT.sol";
import "./StorageDataTypes.sol";

library QuoterLib {
    function spot(IQuoter quoter, address base, address quote, int256 baseAmount, uint24 uniswapFee)
        internal
        returns (uint256)
    {
        if (baseAmount > 0) {
            return quoter.quoteExactInputSingle({
                tokenIn: base,
                tokenOut: quote,
                fee: uniswapFee,
                amountIn: uint256(baseAmount),
                sqrtPriceLimitX96: 0
            });
        } else {
            return quoter.quoteExactOutputSingle({
                tokenIn: quote,
                tokenOut: base,
                fee: uniswapFee,
                amountOut: uint256(-baseAmount),
                sqrtPriceLimitX96: 0
            });
        }
    }

    function fee(
        IContangoView contango,
        ContangoPositionNFT positionNFT,
        PositionId positionId,
        Symbol symbol,
        uint256 cost
    ) internal view returns (uint256) {
        address trader = PositionId.unwrap(positionId) == 0 ? msg.sender : positionNFT.positionOwner(positionId);
        IFeeModel feeModel = contango.feeModel(symbol);
        return address(feeModel) != address(0) ? feeModel.calculateFee(trader, positionId, cost) : 0;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Offset for the initial slot in lib storage, gives us this number of storage slots available
uint256 constant STORAGE_SLOT_BASE = 1_000_000;
uint256 constant YIELD_STORAGE_SLOT_BASE = 2_000_000;
uint256 constant NOTIONAL_STORAGE_SLOT_BASE = 3_000_000;

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataTypes.sol";

struct InstrumentStorage {
    uint32 maturity;
    uint24 _deprecated;
    ERC20 base;
    bool closingOnly;
    ERC20 quote;
}

struct YieldInstrumentStorage {
    bytes6 baseId;
    bytes6 quoteId;
    IFYToken quoteFyToken;
    IFYToken baseFyToken;
    IPool basePool;
    IPool quotePool;
    uint96 minQuoteDebt;
}

struct NotionalInstrumentStorage {
    uint16 baseId;
    uint16 quoteId;
    uint64 basePrecision;
    uint64 quotePrecision;
    bool isQuoteWeth;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol";

import "./Errors.sol";
import "./StorageDataTypes.sol";

import "./StorageConstants.sol";

library StorageLib {
    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum StorageId {
        Unused, // 0
        PositionBalances, // 1
        PositionNotionals, // 2
        InstrumentFeeModel, // 3
        PositionInstrument, // 4
        Instrument // 5
    }

    /// @dev Mapping from a position id to encoded position balances
    function getPositionBalances() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionBalances);
    }

    /// @dev Mapping from a position id to encoded position notionals
    function getPositionNotionals() internal pure returns (mapping(PositionId => uint256) storage store) {
        return _getUint256ToUint256Mapping(StorageId.PositionNotionals);
    }

    // solhint-disable no-inline-assembly
    /// @dev Mapping from an instrument symbol to a fee model
    function getInstrumentFeeModel() internal pure returns (mapping(Symbol => IFeeModel) storage store) {
        uint256 slot = getStorageSlot(StorageId.InstrumentFeeModel);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    /// @dev Mapping from a position id to a fee model
    function getInstrumentFeeModel(PositionId positionId) internal view returns (IFeeModel) {
        return getInstrumentFeeModel()[getPositionInstrument()[positionId]];
    }

    // solhint-disable no-inline-assembly
    /// @dev Mapping from a position id to an instrument symbol
    function getPositionInstrument() internal pure returns (mapping(PositionId => Symbol) storage store) {
        uint256 slot = getStorageSlot(StorageId.PositionInstrument);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    // solhint-disable no-inline-assembly
    /// @dev Mapping from an instrument symbol to an instrument
    function getInstruments() internal pure returns (mapping(Symbol => InstrumentStorage) storage store) {
        uint256 slot = getStorageSlot(StorageId.Instrument);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    function getInstrument(PositionId positionId)
        internal
        view
        returns (Symbol symbol, InstrumentStorage storage instrument)
    {
        symbol = StorageLib.getPositionInstrument()[positionId];
        instrument = getInstruments()[symbol];
    }

    function setFeeModel(Symbol symbol, IFeeModel feeModel) internal {
        StorageLib.getInstrumentFeeModel()[symbol] = feeModel;
    }

    function setClosingOnly(Symbol symbol, bool closingOnly) internal {
        StorageLib.getInstruments()[symbol].closingOnly = closingOnly;
    }

    // solhint-disable no-inline-assembly
    function _getUint256ToUint256Mapping(StorageId storageId)
        private
        pure
        returns (mapping(PositionId => uint256) storage store)
    {
        uint256 slot = getStorageSlot(storageId);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/solmate/src/utils/SafeTransferLib.sol";

library TransferLib {
    using SafeTransferLib for ERC20;

    error ZeroPayer();
    error ZeroDestination();

    function transferOut(ERC20 token, address payer, address to, uint256 amount) internal returns (uint256) {
        if (payer == address(0)) revert ZeroPayer();
        if (to == address(0)) revert ZeroDestination();

        // If we are the payer, it's because the funds where transferred first or it was WETH wrapping
        payer == address(this) ? token.safeTransfer(to, amount) : token.safeTransferFrom(payer, to, amount);

        return amount;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../utils/Balanceless.sol";
import "../ContangoPositionNFT.sol";
import "../batchable/Batchable.sol";
import "../batchable/PermitForwarder.sol";
import "../batchable/WethHandler.sol";
import "../interfaces/IContango.sol";
import "../interfaces/IContangoAdmin.sol";
import "../libraries/DataTypes.sol";
import "../libraries/CodecLib.sol";
import "../libraries/Errors.sol";
import "../libraries/StorageLib.sol";

/// @notice Base contract that implements all common interfaces and function for all underlying implementations
abstract contract ContangoBase is
    IContango,
    IContangoAdmin,
    IUniswapV3SwapCallback,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    Balanceless,
    Batchable,
    PermitForwarder,
    WethHandler
{
    using CodecLib for uint256;

    bytes32 public constant EMERGENCY_BREAK = keccak256("EMERGENCY_BREAK");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) WethHandler(_weth) {}

    // solhint-disable-next-line func-name-mixedcase
    function __ContangoBase_init(ContangoPositionNFT _positionNFT, address _treasury) public onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        ConfigStorageLib.setTreasury(_treasury);
        emit TreasurySet(_treasury);

        ConfigStorageLib.setPositionNFT(_positionNFT);
        emit PositionNFTSet(_positionNFT);
    }

    // ============================================== Admin functions ==============================================

    function pause() external onlyRole(EMERGENCY_BREAK) {
        _pause();
    }

    function unpause() external onlyRole(EMERGENCY_BREAK) {
        _unpause();
    }

    function setClosingOnly(bool _closingOnly) external override onlyRole(OPERATOR) {
        ConfigStorageLib.setClosingOnly(_closingOnly);
        emit ClosingOnlySet(_closingOnly);
    }

    function closingOnly() external view override returns (bool) {
        return ConfigStorageLib.getClosingOnly();
    }

    function setClosingOnly(Symbol symbol, bool _closingOnly) external override onlyRole(OPERATOR) {
        StorageLib.setClosingOnly(symbol, _closingOnly);
        emit ClosingOnlySet(symbol, _closingOnly);
    }

    function setTrustedToken(address token, bool trusted) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        ConfigStorageLib.setTrustedToken(token, trusted);
        emit TokenTrusted(token, trusted);
    }

    function setFeeModel(Symbol symbol, IFeeModel _feeModel) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFeeModel(symbol, _feeModel);
    }

    function _setFeeModel(Symbol symbol, IFeeModel _feeModel) internal {
        StorageLib.setFeeModel(symbol, _feeModel);
        emit FeeModelUpdated(symbol, _feeModel);
    }

    function collectBalance(ERC20 token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    modifier whenNotClosingOnly(int256 quantity) {
        if (quantity > 0 && ConfigStorageLib.getClosingOnly()) {
            revert ClosingOnly();
        }
        _;
    }

    function _authorizeUpgrade(address) internal view override {
        _checkRole(DEFAULT_ADMIN_ROLE);
    }

    // ============================================== View functions ==============================================

    /// @inheritdoc IContangoView
    function position(PositionId positionId) public view virtual override returns (Position memory _position) {
        _position.symbol = StorageLib.getPositionInstrument()[positionId];
        (_position.openQuantity, _position.openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, int256 fees) = StorageLib.getPositionBalances()[positionId].decodeI128();
        (_position.collateral, _position.protocolFees) = (collateral, uint256(fees));

        _position.maturity = StorageLib.getInstruments()[_position.symbol].maturity;
        _position.feeModel = feeModel(_position.symbol);
    }

    /// @inheritdoc IContangoView
    function feeModel(Symbol symbol) public view override returns (IFeeModel) {
        return StorageLib.getInstrumentFeeModel()[symbol];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ContangoBase.sol";

import "./interfaces/IContangoNotionalAdmin.sol";

import "./ContangoVaultProxyDeployer.sol";
import "./Notional.sol";

/// @title ContangoNotional
/// @notice Contango extension to support notional specific features
contract ContangoNotional is ContangoVaultProxyDeployer, ContangoBase, IContangoNotionalAdmin {
    using NotionalUtils for Symbol;
    using ProxyLib for PositionId;
    using SafeCast for uint256;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    error OnlyFromWETHOrProxy(address weth, address proxy, address sender);

    /// @dev this is ephemeral and must be set/clear within a tx via the context() modifier
    PositionId private contextPositionId;

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) ContangoBase(_weth) {}

    function initialize(ContangoPositionNFT _positionNFT, address _treasury) public initializer {
        __ContangoBase_init(_positionNFT, _treasury);
    }

    // ============================================== Trading functions ==============================================

    /// @inheritdoc IContango
    // TODO alfredo - natspec about quantities adjusted to notional precision
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        whenNotClosingOnly(quantity.toInt256())
        returns (PositionId positionId)
    {
        positionId = Notional.createPosition(
            Notional.CreatePositionParams(
                symbol, trader, quantity, limitCost, collateral, payer, lendingLiquidity, uniswapFee
            )
        );
    }

    /// @inheritdoc IContango
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused context(positionId) {
        Notional.modifyCollateral(positionId, collateral, slippageTolerance, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    // TODO alfredo - natspec about quantities adjusted to notional precision
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable override nonReentrant whenNotPaused whenNotClosingOnly(quantity) context(positionId) {
        Notional.modifyPosition(
            positionId, quantity, limitCost, collateral, payerOrReceiver, lendingLiquidity, uniswapFee
        );
    }

    /// @inheritdoc IContango
    function deliver(PositionId positionId, address payer, address to)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        context(positionId)
    {
        Notional.deliver(positionId, payer, to);
    }

    // ============================================== Callback functions ==============================================

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        Notional.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function onVaultAccountDeleverage(PositionId positionId, uint256 size, uint256 cost) external {
        Notional.onVaultAccountDeleverage(positionId, size, cost);
    }

    // ============================================== Admin functions ==============================================

    function createNotionalInstrument(
        Symbol _symbol,
        uint16 _baseId,
        uint16 _quoteId,
        uint256 _marketIndex,
        IFeeModel _feeModel,
        ContangoVault _vault
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (InstrumentStorage memory instrument_, NotionalInstrumentStorage memory notionalInstrument_)
    {
        (instrument_, notionalInstrument_) =
            NotionalStorageLib.createInstrument(_symbol, _baseId, _quoteId, _marketIndex, _vault, address(weth));
        _setFeeModel(_symbol, _feeModel);
    }

    function notionalInstrument(Symbol symbol)
        external
        view
        returns (
            InstrumentStorage memory instrument_,
            NotionalInstrumentStorage memory notionalInstrument_,
            ContangoVault vault_
        )
    {
        return symbol.loadInstrument();
    }

    function setProxyHash(bytes32 _proxyHash) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        ConfigStorageLib.setProxyHash(_proxyHash);
        emit ProxyHashSet(_proxyHash);
    }

    function proxyHash() external view returns (bytes32) {
        return ConfigStorageLib.getProxyHash();
    }

    // TODO alfredo - should we implement proxy approve() for claiming other tokens when necessary? e.g. airdrops, accidental transfers
    // revisit testCanNotCollectProxyBalanceForTokenNotInInstrument() if that's the case

    /// @notice this will only allow for recovery of the tokens that are either base or quote of position instrument and/or native ETH,
    /// other tokens will be locked due to lack of approval (currently not exposed externally on ContangoNotional, but possible via PermissionedProxy.approve())
    function collectProxyBalance(PositionId positionId, address token, address payable to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        context(positionId)
    {
        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        if (token == address(0)) {
            PermissionedProxy(proxy).collectBalance(amount);
            to.safeTransferETH(amount);
        } else {
            ERC20(token).safeTransferFrom(proxy, to, amount);
        }
    }

    receive() external payable override {
        if (msg.sender != address(weth)) {
            // delays proxy resolution and check to stay under 2300 gas limit
            address proxy = PositionId.unwrap(contextPositionId) != 0
                ? contextPositionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash())
                : address(0);

            if (msg.sender != proxy) {
                revert OnlyFromWETHOrProxy(address(weth), proxy, msg.sender);
            }
        }
    }

    modifier context(PositionId positionId) {
        contextPositionId = positionId;
        _;
        contextPositionId = PositionId.wrap(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/DataTypes.sol";
import "../../utils/PermissionedProxy.sol";

interface IContangoNotionalProxyDeployer is IPermissionedProxyDeployer {
    error NotSelf();

    function contangoNotionalParameters() external returns (PositionId positionId);
}

contract ContangoNotionalProxy is PermissionedProxy {
    PositionId public immutable positionId;

    constructor() PermissionedProxy() {
        positionId = IContangoNotionalProxyDeployer(msg.sender).contangoNotionalParameters();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/IContangoQuoter.sol";

import "../../libraries/QuoterLib.sol";

import "./ContangoNotional.sol";

// solhint-disable not-rely-on-time
contract ContangoNotionalQuoter is IContangoQuoter {
    using NotionalUtils for *;
    using ProxyLib for PositionId;
    using QuoterLib for IQuoter;
    using SafeCast for *;
    using SignedMath for int256;

    // TODO alfredo - this will probably have a lot in common with ContangoYieldQuoter.sol, check if code can be shared

    // TODO alfredo - look into optimising max usable liquidity via binary searching

    ContangoPositionNFT public immutable positionNFT;
    ContangoNotional public immutable contangoNotional;
    IQuoter public immutable quoter;
    NotionalProxy public immutable notional;

    struct CollateralAndLeverage {
        int256 collateral;
        int256 collateralSlippage;
        uint256 leverage;
    }

    struct InstrumentData {
        InstrumentStorage instrument;
        NotionalInstrumentStorage notionalInstrument;
        ContangoVault vault;
    }

    constructor(
        ContangoPositionNFT _positionNFT,
        ContangoNotional _contangoNotional,
        IQuoter _quoter,
        NotionalProxy _notional
    ) {
        positionNFT = _positionNFT;
        contangoNotional = _contangoNotional;
        quoter = _quoter;
        notional = _notional;
    }

    /// @inheritdoc IContangoQuoter
    function positionStatus(PositionId positionId, uint24 uniswapFee)
        external
        override
        returns (PositionStatus memory)
    {
        (, InstrumentData memory instrumentData) = _validateActivePosition(positionId);

        return _positionStatus(positionId, instrumentData, uniswapFee);
    }

    /// @inheritdoc IContangoQuoter
    function openingCostForPositionWithLeverage(OpeningCostParams calldata params, uint256 leverage)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _openingCostForPosition(params, 0, leverage);
    }

    /// @inheritdoc IContangoQuoter
    function openingCostForPositionWithCollateral(OpeningCostParams calldata params, uint256 collateral)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _openingCostForPosition(params, collateral, 0);
    }

    /// @inheritdoc IContangoQuoter
    function modifyCostForPositionWithLeverage(ModifyCostParams calldata params, uint256 leverage)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _modifyCostForPosition(params, 0, leverage);
    }

    /// @inheritdoc IContangoQuoter
    function modifyCostForPositionWithCollateral(ModifyCostParams calldata params, int256 collateral)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _modifyCostForPosition(params, collateral, 0);
    }

    /// @inheritdoc IContangoQuoter
    function deliveryCostForPosition(PositionId positionId) external view override returns (uint256) {
        (Position memory position, InstrumentData memory instrumentData) = _validateExpiredPosition(positionId);
        VaultAccount memory vaultAccount = _getVaultAccount(positionId, instrumentData.vault);

        return _deliveryCostForPosition(positionId, vaultAccount, instrumentData.notionalInstrument, position);
    }

    // ============================================== Private functions ==============================================

    function _openingCostForPosition(OpeningCostParams calldata params, uint256 collateral, uint256 leverage)
        private
        returns (ModifyCostResult memory result)
    {
        InstrumentData memory instrumentData = _instrument(params.symbol);

        _checkClosingOnly(params.symbol, instrumentData.instrument);

        VaultAccount memory vaultAccount; // empty account since it's a new position
        result = _modifyCostForPosition(
            instrumentData,
            vaultAccount,
            params.quantity.toInt256(),
            collateral.toInt256(),
            params.collateralSlippage,
            leverage,
            params.uniswapFee
        );

        result.fee = QuoterLib.fee(contangoNotional, positionNFT, PositionId.wrap(0), params.symbol, result.cost.abs());
    }

    function _modifyCostForPosition(ModifyCostParams calldata params, int256 collateral, uint256 leverage)
        private
        returns (ModifyCostResult memory result)
    {
        (Position memory position, InstrumentData memory instrumentData) = _validateActivePosition(params.positionId);
        VaultAccount memory vaultAccount = _getVaultAccount(params.positionId, instrumentData.vault);

        if (params.quantity > 0) {
            _checkClosingOnly(position.symbol, instrumentData.instrument);
        }

        result = _modifyCostForPosition(
            instrumentData,
            vaultAccount,
            params.quantity,
            collateral,
            params.collateralSlippage,
            leverage,
            params.uniswapFee
        );
        if (result.needsBatchedCall || params.quantity == 0) {
            uint256 aggregateCost = (result.cost + result.financingCost).abs() + result.debtDelta.abs();
            result.fee = QuoterLib.fee(contangoNotional, positionNFT, params.positionId, position.symbol, aggregateCost);
        } else {
            result.fee =
                QuoterLib.fee(contangoNotional, positionNFT, params.positionId, position.symbol, result.cost.abs());
        }
    }

    function _checkClosingOnly(Symbol symbol, InstrumentStorage memory instrument) private view {
        if (contangoNotional.closingOnly()) {
            revert ClosingOnly();
        }
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }
    }

    function _modifyCostForPosition(
        InstrumentData memory instrumentData,
        VaultAccount memory vaultAccount,
        int256 quantity,
        int256 collateral,
        uint256 collateralSlippage,
        uint256 leverage,
        uint24 uniswapFee
    ) internal returns (ModifyCostResult memory result) {
        VaultConfig memory vaultConfig = notional.getVaultConfig(address(instrumentData.vault));
        result.liquidationRatio = _liquidationRatio(vaultConfig);

        CollateralAndLeverage memory collateralAndLeverage =
            CollateralAndLeverage(collateral, 1e18 + collateralSlippage.toInt256(), leverage);

        // TODO alfredo - set proper liquidity
        result.baseLendingLiquidity = type(uint256).max;
        result.quoteLendingLiquidity = type(uint256).max;

        if (quantity >= 0) {
            // TODO alfredo - this will adjust the quantity for calculations but we're not telling we did it back to the result
            uint256 uQuantity =
                quantity.toUint256().roundFloorNotionalPrecision(instrumentData.notionalInstrument.basePrecision);
            _increasingCostForPosition(
                result, instrumentData, vaultAccount, vaultConfig, uQuantity, collateralAndLeverage, uniswapFee
            );
        } else {
            // TODO alfredo - this will adjust the quantity for calculations but we're not telling we did it back to the result
            uint256 uQuantity =
                (-quantity).toUint256().roundFloorNotionalPrecision(instrumentData.notionalInstrument.basePrecision);
            _decreasingCostForPosition(
                result, instrumentData, vaultAccount, vaultConfig, uQuantity, collateralAndLeverage, uniswapFee
            );
        }
    }

    function _minDebt(
        NotionalInstrumentStorage memory notionalInstrument,
        VaultConfig memory vaultConfig,
        uint256 underlyingCollateral
    ) private pure returns (uint256 fCashMinDebt, uint128 minDebt) {
        // cap min debt required by taking max collateral ratio into account
        int256 requiredDebt =
            (underlyingCollateral.toInt256() * Constants.RATE_PRECISION) / vaultConfig.maxRequiredAccountCollateralRatio;

        fCashMinDebt = Math.max(
            requiredDebt.toUint256().toNotionalPrecision(notionalInstrument.quotePrecision, true),
            vaultConfig.minAccountBorrowSize.toUint256()
        );
        minDebt = fCashMinDebt.fromNotionalPrecision(notionalInstrument.quotePrecision, true).toUint128();
    }

    function _increasingCostForPosition(
        ModifyCostResult memory result,
        InstrumentData memory instrumentData,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        uint256 quantity,
        CollateralAndLeverage memory collateralAndLeverage,
        uint24 uniswapFee
    ) private {
        uint256 fCashQuantity;
        uint256 fCashMinDebt;
        (fCashQuantity, result.underlyingCollateral, fCashMinDebt, result.minDebt) =
            _calculateMinDebtForIncrease(instrumentData, vaultAccount, vaultConfig, quantity);

        _evaluateIncreaseLiquidity(
            instrumentData.instrument, instrumentData.notionalInstrument, vaultAccount, fCashMinDebt
        );

        uint256 hedge;
        int256 hedgeCost;

        if (quantity > 0) {
            hedge =
                notional.quoteLendOpenCost(fCashQuantity, instrumentData.instrument, instrumentData.notionalInstrument);
            if (hedge == 0) {
                // no liquidity
                result.quoteLendingLiquidity = 0;
                hedge = quantity;
            }

            hedgeCost = -int256(
                quoter.spot(
                    address(instrumentData.instrument.base),
                    address(instrumentData.instrument.quote),
                    -int256(hedge),
                    uniswapFee
                )
            );
            result.spotCost = -int256(
                quoter.spot(
                    address(instrumentData.instrument.base),
                    address(instrumentData.instrument.quote),
                    -int256(quantity),
                    uniswapFee
                )
            );
        }

        _calculateMinCollateral(
            result,
            instrumentData.instrument,
            instrumentData.notionalInstrument,
            vaultAccount,
            hedgeCost,
            fCashMinDebt,
            collateralAndLeverage.collateralSlippage
        );
        _calculateMaxCollateral(
            result,
            instrumentData.instrument,
            instrumentData.notionalInstrument,
            vaultAccount,
            hedgeCost,
            fCashMinDebt,
            collateralAndLeverage.collateralSlippage
        );
        _assignCollateralUsed(
            instrumentData.instrument,
            instrumentData.notionalInstrument,
            vaultAccount,
            result,
            collateralAndLeverage,
            hedgeCost
        );
        _calculateCost(
            result, instrumentData.instrument, instrumentData.notionalInstrument, vaultAccount, hedgeCost, true
        );
    }

    function _calculateMinDebtForIncrease(
        InstrumentData memory instrumentData,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        uint256 quantity
    )
        private
        view
        returns (uint256 fCashQuantity, uint256 underlyingCollateral, uint256 fCashMinDebt, uint128 minDebt)
    {
        fCashQuantity = quantity.toNotionalPrecision(instrumentData.notionalInstrument.basePrecision, true);
        underlyingCollateral = _underlyingCollateral(
            instrumentData.vault, fCashQuantity + vaultAccount.vaultShares, instrumentData.instrument.maturity
        );
        (fCashMinDebt, minDebt) = _minDebt(instrumentData.notionalInstrument, vaultConfig, underlyingCollateral);
    }

    function _evaluateIncreaseLiquidity(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        uint256 fCashMinDebt
    ) private view {
        uint256 currentDebt = vaultAccount.fCash.abs();
        // currentDebt should be either 0 or >= minDebt
        if (
            currentDebt < fCashMinDebt
                && notional.quoteBorrowOpen(fCashMinDebt - currentDebt, instrument, notionalInstrument) == 0
        ) {
            revert InsufficientLiquidity();
        }
    }

    function _decreasingCostForPosition(
        ModifyCostResult memory result,
        InstrumentData memory instrumentData,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        uint256 quantity,
        CollateralAndLeverage memory collateralAndLeverage,
        uint24 uniswapFee
    ) private {
        uint256 fCashQuantity;
        uint256 fCashMinDebt;
        (fCashQuantity, result.underlyingCollateral, fCashMinDebt, result.minDebt) =
            _calculateMinDebtForDecrease(instrumentData, vaultAccount, vaultConfig, quantity);

        uint256 amountRealBaseReceivedFromSellingLendingPosition =
            notional.quoteLendClose(fCashQuantity, instrumentData.instrument, instrumentData.notionalInstrument);

        if (amountRealBaseReceivedFromSellingLendingPosition == 0) {
            revert InsufficientLiquidity();
        }

        result.spotCost = int256(
            quoter.spot(
                address(instrumentData.instrument.base),
                address(instrumentData.instrument.quote),
                int256(quantity),
                uniswapFee
            )
        );
        int256 hedgeCost = int256(
            quoter.spot(
                address(instrumentData.instrument.base),
                address(instrumentData.instrument.quote),
                int256(amountRealBaseReceivedFromSellingLendingPosition),
                uniswapFee
            )
        );

        // goes around possible rounding issues
        if (
            vaultAccount.vaultShares.fromNotionalPrecision(instrumentData.notionalInstrument.basePrecision, false)
                == quantity
        ) {
            _fullyCloseCost(
                result, instrumentData.instrument, instrumentData.notionalInstrument, vaultAccount, hedgeCost
            );
        } else {
            _calculateMinCollateral(
                result,
                instrumentData.instrument,
                instrumentData.notionalInstrument,
                vaultAccount,
                hedgeCost,
                fCashMinDebt,
                collateralAndLeverage.collateralSlippage
            );
            _calculateMaxCollateral(
                result,
                instrumentData.instrument,
                instrumentData.notionalInstrument,
                vaultAccount,
                hedgeCost,
                fCashMinDebt,
                collateralAndLeverage.collateralSlippage
            );
            _assignCollateralUsed(
                instrumentData.instrument,
                instrumentData.notionalInstrument,
                vaultAccount,
                result,
                collateralAndLeverage,
                hedgeCost
            );
            _calculateCost(
                result, instrumentData.instrument, instrumentData.notionalInstrument, vaultAccount, hedgeCost, false
            );
        }
    }

    function _fullyCloseCost(
        ModifyCostResult memory result,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        int256 hedgeCost
    ) private view {
        uint256 debt = vaultAccount.fCash.abs();
        uint256 borrowCloseCost = notional.quoteBorrowCloseCost(debt, instrument, notionalInstrument);
        if (borrowCloseCost == 0) {
            // TODO alfredo - need to find out how do we cancel de debt 1:1, otherwise this won't be possible
            revert NotImplemented(
                "_decreasingCostForPosition() - lack of quote lending liquidity - needs 1:1 debt repayment"
            );
        }

        uint256 costRecovered = debt.fromNotionalPrecision(notionalInstrument.quotePrecision, false) - borrowCloseCost;
        result.cost = hedgeCost + int256(costRecovered);
    }

    function _calculateMinDebtForDecrease(
        InstrumentData memory instrumentData,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        uint256 quantity
    )
        private
        view
        returns (uint256 fCashQuantity, uint256 underlyingCollateral, uint256 fCashMinDebt, uint128 minDebt)
    {
        fCashQuantity = quantity.toNotionalPrecision(instrumentData.notionalInstrument.basePrecision, true);
        underlyingCollateral = _underlyingCollateral(
            instrumentData.vault, vaultAccount.vaultShares - fCashQuantity, instrumentData.instrument.maturity
        );
        (fCashMinDebt, minDebt) = _minDebt(instrumentData.notionalInstrument, vaultConfig, underlyingCollateral);
    }

    function _positionStatus(PositionId positionId, InstrumentData memory instrumentData, uint24 uniswapFee)
        private
        returns (PositionStatus memory result)
    {
        VaultAccount memory vaultAccount = _getVaultAccount(positionId, instrumentData.vault);

        result.spotCost = quoter.spot(
            address(instrumentData.instrument.base),
            address(instrumentData.instrument.quote),
            int256(
                vaultAccount.vaultShares.fromNotionalPrecision(instrumentData.notionalInstrument.basePrecision, true)
            ),
            uniswapFee
        );
        result.underlyingDebt =
            uint256(-vaultAccount.fCash).fromNotionalPrecision(instrumentData.notionalInstrument.quotePrecision, true);
        result.underlyingCollateral =
            _underlyingCollateral(instrumentData.vault, vaultAccount.vaultShares, instrumentData.instrument.maturity);
        result.liquidationRatio = _liquidationRatio(notional.getVaultConfig(address(instrumentData.vault)));
    }

    function _getVaultAccount(PositionId positionId, ContangoVault vault) private view returns (VaultAccount memory) {
        address proxy = positionId.computeProxyAddress(address(contangoNotional), contangoNotional.proxyHash());
        return notional.getVaultAccount(proxy, address(vault));
    }

    function _underlyingCollateral(ContangoVault vault, uint256 fCash, uint256 maturity)
        private
        view
        returns (uint256)
    {
        return uint256(vault.convertStrategyToUnderlying(address(0), fCash, maturity));
    }

    function _liquidationRatio(VaultConfig memory vaultConfig) private pure returns (uint256) {
        // Notional stores minCollateralRatio as 1e9 (Constants.RATE_PRECISION) and assumes it's always over collateralised, so min 100%
        // e.g. 140% liquidation ratio is stored on Notional as 0.4e9 and we parse it to 1.4e6 for internal use
        return 1e6 + (uint256(vaultConfig.minCollateralRatio) / 1e3);
    }

    function _calculateMinCollateral(
        ModifyCostResult memory result,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        int256 hedgeCost,
        uint256 fCashMinDebt,
        int256 collateralSlippage
    ) private view {
        uint256 maxDebtAfterModify = ((result.underlyingCollateral * 1e6) / result.liquidationRatio).toNotionalPrecision(
            notionalInstrument.quotePrecision, false
        );

        uint256 currentDebt = vaultAccount.fCash.abs();
        if (currentDebt < maxDebtAfterModify) {
            // TODO alfredo - liquidation: how is debt valued? if not FV = PV then this doesn't work
            uint256 remainingAvailableDebt = maxDebtAfterModify - currentDebt;
            uint256 refinancingRoomPV = notional.quoteBorrowOpen(remainingAvailableDebt, instrument, notionalInstrument);
            if (refinancingRoomPV == 0) {
                // not enough liquidity but up to min debt is guaranteed due to earlier checks
                remainingAvailableDebt = currentDebt >= fCashMinDebt ? 0 : fCashMinDebt - currentDebt;
                refinancingRoomPV =
                    remainingAvailableDebt.fromNotionalPrecision(notionalInstrument.quotePrecision, true);
            }

            result.minCollateral -= hedgeCost + int256(refinancingRoomPV);
        }

        if (currentDebt > maxDebtAfterModify) {
            uint256 diff = vaultAccount.fCash.abs() - maxDebtAfterModify;
            uint256 closeCost = notional.quoteBorrowCloseCost(diff, instrument, notionalInstrument);
            if (closeCost == 0) {
                // TODO alfredo - need to find out how do we cancel de debt 1:1, otherwise this won't be possible
                revert NotImplemented(
                    "_calculateMinCollateral() - lack of quote lending liquidity - needs 1:1 debt repayment"
                );
            }

            result.minCollateral = int256(closeCost) - hedgeCost;
        }

        if (collateralSlippage != 1e18) {
            result.minCollateral = result.minCollateral > 0
                ? SignedMath.min((result.minCollateral * collateralSlippage) / 1e18, -hedgeCost)
                : (result.minCollateral * 1e18) / collateralSlippage;
        }
    }

    function _calculateMaxCollateral(
        ModifyCostResult memory result,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        int256 hedgeCost,
        uint256 fCashMinDebt,
        int256 collateralSlippage
    ) private view {
        // this covers the case where there is no existing debt, which applies to new positions or fully liquidated positions
        if (vaultAccount.fCash == 0) {
            // if there's no liquidity to borrow, will return zero and be the same as requesting to mint it all 1:1
            uint256 minDebtPV = notional.quoteBorrowOpen(fCashMinDebt, instrument, notionalInstrument);
            result.maxCollateral = int256(hedgeCost.abs() - minDebtPV);
        } else {
            int256 delta;
            uint256 fCash = vaultAccount.fCash.abs();

            if (fCash > fCashMinDebt) {
                uint256 maxDebtThatCanBeBurned = fCash - fCashMinDebt;
                delta = notional.quoteBorrowCloseCost(maxDebtThatCanBeBurned, instrument, notionalInstrument).toInt256();
                if (delta == 0) {
                    // TODO alfredo - need to find out how do we cancel de debt 1:1, otherwise this won't be possible
                    revert NotImplemented(
                        "_calculateMaxCollateral() - lack of quote lending liquidity - needs 1:1 debt repayment"
                    );
                }
            } else if (fCash < fCashMinDebt) {
                uint256 minDebtNeeded = fCashMinDebt - fCash;
                delta = -notional.quoteBorrowOpen(minDebtNeeded, instrument, notionalInstrument).toInt256();
                if (delta == 0) {
                    // if there's no liquidity to borrow, mint it all 1:1
                    delta = -minDebtNeeded.toInt256();
                }
            }
            result.maxCollateral = delta - hedgeCost;
        }

        if (collateralSlippage != 1e18) {
            result.maxCollateral = result.maxCollateral < 0
                ? (result.maxCollateral * collateralSlippage) / 1e18
                : (result.maxCollateral * collateralSlippage) / collateralSlippage;
        }
    }

    function _assignCollateralUsed(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        ModifyCostResult memory result,
        CollateralAndLeverage memory collateralAndLeverage,
        int256 hedgeCost
    ) private view {
        int256 collateral = collateralAndLeverage.leverage > 0
            ? _deriveCollateralFromLeverage(
                instrument, notionalInstrument, vaultAccount, result, collateralAndLeverage.leverage, hedgeCost
            )
            : collateralAndLeverage.collateral;

        // if 'collateral' is above the max, use result.maxCollateral
        result.collateralUsed = SignedMath.min(collateral, result.maxCollateral);
        // if result.collateralUsed is lower than max, but still lower than the min, use the min
        result.collateralUsed = SignedMath.max(result.minCollateral, result.collateralUsed);
    }

    // leverage = 1 / ((underlyingCollateral - underlyingDebt) / underlyingCollateral)
    // leverage = underlyingCollateral / (underlyingCollateral - underlyingDebt)
    // underlyingDebt = -underlyingCollateral / leverage + underlyingCollateral
    // collateral = hedgeCost - underlyingDebtPV
    function _deriveCollateralFromLeverage(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        ModifyCostResult memory result,
        uint256 leverage,
        int256 hedgeCost
    ) internal view returns (int256 collateral) {
        uint256 debtFV = (
            ((-int256(result.underlyingCollateral) * 1e18) / int256(leverage)) + int256(result.underlyingCollateral)
        ).toUint256().toNotionalPrecision(notionalInstrument.quotePrecision, false);

        uint256 currentDebt = vaultAccount.fCash.abs();
        int256 debtPV;
        if (debtFV > currentDebt) {
            // Debt needs to increase to reach the desired leverage
            debtPV = int256(notional.quoteBorrowOpen(debtFV - currentDebt, instrument, notionalInstrument));
        } else {
            // Debt needs to be burnt to reach the desired leverage
            debtPV = -int256(notional.quoteBorrowCloseCost(currentDebt - debtFV, instrument, notionalInstrument));
        }

        collateral = hedgeCost.abs().toInt256() - debtPV;
    }

    function _calculateCost(
        ModifyCostResult memory result,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        VaultAccount memory vaultAccount,
        int256 hedgeCost,
        bool isIncrease
    ) private view {
        int256 quoteUsedToRepayDebt = result.collateralUsed + hedgeCost;
        result.underlyingDebt = vaultAccount.fCash.abs().fromNotionalPrecision(notionalInstrument.quotePrecision, true);

        if (quoteUsedToRepayDebt > 0) {
            uint256 debtDelta = notional.quoteBorrowClose(uint256(quoteUsedToRepayDebt), instrument, notionalInstrument)
                .fromNotionalPrecision(notionalInstrument.quotePrecision, false);
            if (debtDelta == 0) {
                // TODO alfredo - need to find out how do we cancel de debt 1:1, otherwise this won't be possible
                revert NotImplemented("_calculateCost() - lack of quote lending liquidity - needs 1:1 debt repayment");
            }

            result.debtDelta = -debtDelta.toInt256();
            result.underlyingDebt -= debtDelta;
            if (isIncrease && hedgeCost != 0) {
                // this means we're increasing, and posting more than what we need to pay the spot
                result.needsBatchedCall = true;
            }
        }

        if (quoteUsedToRepayDebt < 0) {
            // should not have liquidity issues here since it's been already verified when calculating collateral
            uint256 fCashBorrow =
                notional.quoteBorrowOpenCost(quoteUsedToRepayDebt.abs(), instrument, notionalInstrument);
            result.debtDelta = fCashBorrow.fromNotionalPrecision(notionalInstrument.quotePrecision, true).toInt256();
            result.underlyingDebt += result.debtDelta.abs();

            if (!isIncrease && hedgeCost != 0) {
                // this means that we're decreasing, and withdrawing more than we get from the spot
                result.needsBatchedCall = true;
            }
        }

        result.financingCost = result.debtDelta + quoteUsedToRepayDebt;
        result.cost -= result.collateralUsed + result.debtDelta;
    }

    function _deliveryCostForPosition(
        PositionId positionId,
        VaultAccount memory vaultAccount,
        NotionalInstrumentStorage memory notionalInstrument,
        Position memory position
    ) internal view returns (uint256 deliveryCost) {
        deliveryCost = uint256(-vaultAccount.fCash).fromNotionalPrecision(notionalInstrument.quotePrecision, true)
            .buffer(notionalInstrument.quotePrecision);
        uint256 deliveryFee = QuoterLib.fee(contangoNotional, positionNFT, positionId, position.symbol, deliveryCost);

        deliveryCost += position.protocolFees + deliveryFee;
    }

    function _validatePosition(PositionId positionId)
        private
        view
        returns (Position memory position, InstrumentData memory instrumentData)
    {
        position = contangoNotional.position(positionId);
        if (position.openQuantity == 0 && position.openCost == 0) {
            if (position.collateral <= 0) {
                revert InvalidPosition(positionId);
            }
        }
        instrumentData = _instrument(position.symbol);
    }

    function _validateActivePosition(PositionId positionId)
        private
        view
        returns (Position memory position, InstrumentData memory instrumentData)
    {
        (position, instrumentData) = _validatePosition(positionId);

        uint256 timestamp = block.timestamp;
        if (instrumentData.instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrumentData.instrument.maturity, timestamp);
        }
    }

    function _validateExpiredPosition(PositionId positionId)
        private
        view
        returns (Position memory position, InstrumentData memory instrumentData)
    {
        (position, instrumentData) = _validatePosition(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrumentData.instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrumentData.instrument.maturity, timestamp);
        }
    }

    function _instrument(Symbol symbol) private view returns (InstrumentData memory instrumentData) {
        (instrumentData.instrument, instrumentData.notionalInstrument, instrumentData.vault) =
            contangoNotional.notionalInstrument(symbol);
    }

    receive() external payable {
        revert ViewOnly();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";

import "lib/solmate/src/tokens/WETH.sol";

import "../../utils/Balanceless.sol";

import "../../libraries/MathLib.sol";
import "../../libraries/ProxyLib.sol";

import "./internal/interfaces/IStrategyVault.sol";
import "./internal/interfaces/ITradingModule.sol";

import "./ContangoNotional.sol";
import "./ContangoNotionalProxy.sol";
import "./NotionalErrors.sol";
import "./NotionalUtils.sol";

// solhint-disable not-rely-on-time, var-name-mixedcase
contract ContangoVault is IStrategyVault, AccessControlUpgradeable, UUPSUpgradeable, Balanceless {
    using MathLib for uint256;
    using NotionalUtils for uint256;
    using ProxyLib for PositionId;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SignedMath for int256;

    error CanNotSettleBeforeMaturity();
    error InsufficientBorrowedAmount(uint256 expected, uint256 borrowed);
    error InsufficientWithdrawAmount(uint256 expected, uint256 borrowed);
    error InvalidContangoProxy(address expected, address actual);
    error OnlyContango();
    error OnlyNotional();
    error OnlyVault();

    struct EnterParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to lend
        uint256 lendAmount;
        // Amount of lent fCash to be received from lending lendAmount
        uint256 fCashLendAmount;
        // Amount of underlying borrowing token to send to the receiver
        uint256 borrowAmount;
        // Address paying for the lending position
        address payer;
        // Address receiving the borrowed underlying
        address receiver;
    }

    struct ExitParams {
        // Contango position Id for proxy validation
        PositionId positionId;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
    }

    struct SettleParams {
        // Address paying for the borrowing unwind
        address payer;
        // Address receiving the lending unwind
        address receiver;
        // Amount of underlying borrowing token to pay back on post maturity redeem
        uint256 repaymentAmount;
        // Amount of underlying lending token to send to the receiver
        uint256 withdrawAmount;
    }

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy public immutable notional;
    ITradingModule public immutable tradingModule;
    ContangoNotional public immutable contango;
    bytes32 public immutable contangoProxyHash;

    // TODO alfredo - evaluate using storage to facilitate upgrades

    // Borrow Currency ID the vault is configured with
    uint16 public immutable borrowCurrencyId;
    // True if borrow the underlying is ETH
    bool public immutable borrowUnderlyingIsEth;
    // Address of the borrow underlying token
    ERC20 public immutable borrowUnderlyingToken;
    // Borrow underlying token precision, e.g. 1e18
    uint256 public immutable borrowTokenPrecision;

    // Lend Currency ID the vault is configured with
    uint16 public immutable lendCurrencyId;
    // True if the lend underlying is ETH
    bool public immutable lendUnderlyingIsEth;
    // Address of the lend underlying token
    ERC20 public immutable lendUnderlyingToken;
    // Lend underlying token precision, e.g. 1e18
    uint256 public immutable lendTokenPrecision;

    // Name of the vault (cannot make string immutable)
    string public name;

    /// @dev deleverage redeem flag - should be handled by onDeleverage() only
    bool private isDeleverage;

    constructor(
        NotionalProxy _notional,
        ITradingModule _tradingModule,
        ContangoNotional _contango,
        bytes32 _contangoProxyHash,
        string memory _name,
        address _weth,
        uint16 _lendCurrencyId,
        uint16 _borrowCurrencyId
    ) {
        notional = _notional;
        tradingModule = _tradingModule;
        contango = _contango;
        contangoProxyHash = _contangoProxyHash;
        name = _name;

        (borrowCurrencyId, borrowUnderlyingIsEth, borrowUnderlyingToken, borrowTokenPrecision) =
            _currencyIdConfiguration(_borrowCurrencyId, _weth);
        (lendCurrencyId, lendUnderlyingIsEth, lendUnderlyingToken, lendTokenPrecision) =
            _currencyIdConfiguration(_lendCurrencyId, _weth);
    }

    function initialize() external initializer {
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Allow Notional to pull the lend underlying currency
        lendUnderlyingToken.approve(address(notional), type(uint256).max);
    }

    // ============================================== IStrategyVault functions ==============================================

    /// @notice All strategy vaults MUST implement 8 decimal precision
    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function strategy() external pure override returns (bytes4) {
        return bytes4(keccak256("ContangoVault"));
    }

    /// @notice Converts the amount of fCash the vault holds into underlying denomination for the borrow currency.
    /// @param strategyTokens each strategy token is equivalent to 1 unit of fCash
    /// @param maturity the maturity of the fCash
    /// @return underlyingValue the value of the lent fCash in terms of the borrowed currency
    function convertStrategyToUnderlying(
        address, // account
        uint256 strategyTokens,
        uint256 maturity
    ) public view override returns (int256 underlyingValue) {
        int256 pvInternal;
        if (maturity <= block.timestamp) {
            // After maturity, strategy tokens no longer have a present value
            pvInternal = strategyTokens.toInt256();
        } else {
            // This is the non-risk adjusted oracle price for fCash, present value is used in case
            // liquidation is required. The liquidator may need to exit the fCash position in order
            // to repay a flash loan.
            pvInternal = notional.getPresentfCashValue(
                lendCurrencyId, maturity, strategyTokens.toInt256(), block.timestamp, false
            );
        }

        (int256 rate, int256 rateDecimals) =
            tradingModule.getOraclePrice(address(lendUnderlyingToken), address(borrowUnderlyingToken));

        // Convert this back to the borrow currency, external precision
        // (pv (8 decimals) * borrowTokenPrecision * rate) / (rateDecimals * 8 decimals)
        underlyingValue = (pvInternal * int256(borrowTokenPrecision) * rate)
            / (rateDecimals * int256(Constants.INTERNAL_TOKEN_PRECISION));
    }

    // TODO alfredo - natspec
    function depositFromNotional(
        address account,
        uint256 depositUnderlyingExternal,
        uint256 maturity,
        bytes calldata data
    ) external payable override onlyNotional returns (uint256 lentFCashAmount) {
        if (maturity <= block.timestamp) {
            revert NotImplemented("deposit after maturity");
        }

        // 4. Take lending underlying from the payer and lend to get fCash
        EnterParams memory params = abi.decode(data, (EnterParams));

        if (depositUnderlyingExternal < params.borrowAmount) {
            revert InsufficientBorrowedAmount(params.borrowAmount, depositUnderlyingExternal);
        }

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        if (params.lendAmount > 0) {
            lendUnderlyingToken.safeTransferFrom(params.payer, address(this), params.lendAmount);
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).withdraw(params.lendAmount);
            }

            // should only have one portfolio for the lending currency (or none if first time entering)
            // and balance always positive since it's always lending
            (,, PortfolioAsset[] memory portfolio) = notional.getAccount(address(this));
            int256 balanceBefore = portfolio.length == 0 ? int256(0) : portfolio[0].notional;

            // Now we lend the underlying amount
            BalanceActionWithTrades[] memory lendAction = new BalanceActionWithTrades[](1);
            lendAction[0] = NotionalUtils.encodeOpenLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                depositActionAmount: params.lendAmount,
                fCashLendAmount: params.fCashLendAmount.toUint88()
            });
            uint256 sendValue = lendUnderlyingIsEth ? params.lendAmount : 0;
            notional.batchBalanceAndTradeAction{value: sendValue}(address(this), lendAction);

            (,, portfolio) = notional.getAccount(address(this));
            lentFCashAmount = uint256(portfolio[0].notional - balanceBefore);
        }

        // 5. Transfer borrowed underlying to the receiver
        if (borrowUnderlyingIsEth) {
            WETH(payable(address(borrowUnderlyingToken))).deposit{value: params.borrowAmount}();
        }
        borrowUnderlyingToken.safeTransfer(params.receiver, params.borrowAmount);
    }

    // TODO alfredo - natspec
    function redeemFromNotional(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external override onlyNotional returns (uint256 transferToReceiver) {
        // transferToReceiver is 0 by default, except when deleveraging, because all the transfers are made by the vault
        if (maturity > block.timestamp) {
            transferToReceiver =
                _redeemBeforeMaturity(account, receiver, strategyTokens, maturity, underlyingToRepayDebt, data);
        } else {
            _redeemAfterMaturity(account, strategyTokens, data);
        }
    }

    function _redeemBeforeMaturity(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) private returns (uint256 transferToReceiver) {
        if (isDeleverage) {
            transferToReceiver = _redeemDeleverage(receiver, strategyTokens, maturity);
        } else {
            _redeemExit(account, strategyTokens, maturity, underlyingToRepayDebt, data);
        }
    }

    function _redeemDeleverage(address receiver, uint256 strategyTokens, uint256 maturity)
        private
        returns (uint256 transferToReceiver)
    {
        uint256 fCashId = notional.encodeToId({
            currencyId: lendCurrencyId,
            maturity: maturity.toUint40(),
            assetType: Constants.FCASH_ASSET_TYPE
        });
        notional.safeTransferFrom({from: address(this), to: receiver, id: fCashId, amount: strategyTokens, data: ""});
        // return transferred strategy tokens so notional can report liquidator profits
        transferToReceiver = strategyTokens;
    }

    function _redeemExit(
        address account,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) private {
        ExitParams memory params = abi.decode(data, (ExitParams));

        // TODO alfredo - the assumption is that the account is guaranteed to be the msg.sender that called notional initially
        _validateAccount(params.positionId, account);

        // 4. Take borrowing underlying from the payer to pay for exiting the borrowing position
        if (!borrowUnderlyingIsEth) {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), underlyingToRepayDebt);
        }

        if (strategyTokens > 0) {
            // 5. Borrow lending fCash to close lending position
            uint256 balanceBefore =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

            BalanceActionWithTrades[] memory closeLendingAction = new BalanceActionWithTrades[](1);
            closeLendingAction[0] = NotionalUtils.encodeCloseLendAction({
                currencyId: lendCurrencyId,
                marketIndex: notional.getMarketIndex(maturity, block.timestamp),
                fCashAmount: strategyTokens.toUint88()
            });
            notional.batchBalanceAndTradeAction(address(this), closeLendingAction);

            uint256 balanceAfter =
                lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
            uint256 availableBalance = balanceAfter - balanceBefore;

            if (params.withdrawAmount > availableBalance) {
                revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
            }

            // 6. Transfer remaining lending underlying to the receiver
            if (lendUnderlyingIsEth) {
                WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
            }
            lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
        }
    }

    function _redeemAfterMaturity(address account, uint256 strategyTokens, bytes calldata data) private {
        // only vault can settle after maturity
        if (account != address(this)) {
            revert OnlyVault();
        }

        SettleParams memory params = abi.decode(data, (SettleParams));

        // take borrowing underlying from the payer to pay for exiting the full borrowing position
        if (borrowUnderlyingIsEth) {
            payable(address(notional)).safeTransferETH(params.repaymentAmount);
        } else {
            borrowUnderlyingToken.safeTransferFrom(params.payer, address(notional), params.repaymentAmount);
        }

        uint256 balanceBefore =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));

        // withdraw proportional lending fCash to underlying
        (,,, AssetRateParameters memory ar) = notional.getCurrencyAndRates(lendCurrencyId);
        int256 withdrawAmount = strategyTokens.fromNotionalPrecision(lendTokenPrecision, false).toInt256();
        int256 ratePrecision = int256(10 ** ar.rateOracle.decimals());
        int256 withdrawAmountInternal = ((withdrawAmount * ratePrecision) / ar.rate) + 1; // buffer

        BalanceAction[] memory withdrawAction = new BalanceAction[](1);
        withdrawAction[0] = NotionalUtils.encodeWithdrawAction({
            currencyId: lendCurrencyId,
            withdrawAmountInternal: uint256(withdrawAmountInternal)
        });
        notional.batchBalanceAction(address(this), withdrawAction);

        uint256 balanceAfter =
            lendUnderlyingIsEth ? address(this).balance : lendUnderlyingToken.balanceOf(address(this));
        uint256 availableBalance = balanceAfter - balanceBefore;

        if (params.withdrawAmount > availableBalance) {
            revert InsufficientWithdrawAmount(params.withdrawAmount, availableBalance);
        }

        // transfer received funds
        if (lendUnderlyingIsEth) {
            WETH(payable(address(lendUnderlyingToken))).deposit{value: params.withdrawAmount}();
        }
        lendUnderlyingToken.safeTransfer(params.receiver, params.withdrawAmount);
    }

    // TODO alfredo - natspec
    function settleAccount(address account, uint256 maturity, bytes calldata data) external payable onlyContango {
        if (maturity > block.timestamp) {
            revert CanNotSettleBeforeMaturity();
        }

        notional.redeemStrategyTokensToCash({
            maturity: maturity,
            strategyTokensToRedeem: notional.getVaultAccount(account, address(this)).vaultShares,
            vaultData: data
        });

        // If there are no more strategy tokens left, meaning all positions were delivered, then clean and fully settle the vault with Notional
        if (notional.getVaultState(address(this), maturity).totalStrategyTokens == 0) {
            // currency ids in ascending order
            (uint16 currencyId1, uint16 currencyId2) = borrowCurrencyId < lendCurrencyId
                ? (borrowCurrencyId, lendCurrencyId)
                : (lendCurrencyId, borrowCurrencyId);

            // withdraws any remaining balance (dust) on Notional
            BalanceAction[] memory withdrawalsAction = new BalanceAction[](2);
            withdrawalsAction[0] = NotionalUtils.encodeWithdrawAllAction(currencyId1);
            withdrawalsAction[1] = NotionalUtils.encodeWithdrawAllAction(currencyId2);
            notional.batchBalanceAction(address(this), withdrawalsAction);

            // fully settle vault
            notional.settleVault(address(this), maturity);
        }
    }

    function deleverageAccount(address account, address liquidator, uint256 depositAmountExternal)
        external
        onDeleverage
        returns (uint256 profitFromLiquidation)
    {
        uint256 debtBefore = notional.getVaultAccount({account: account, vault: address(this)}).fCash.abs();

        profitFromLiquidation = notional.deleverageAccount({
            account: account,
            vault: address(this),
            liquidator: liquidator,
            depositAmountExternal: depositAmountExternal,
            transferSharesToLiquidator: false,
            redeemData: new bytes(0)
        });

        uint256 debtBurnt = debtBefore - notional.getVaultAccount({account: account, vault: address(this)}).fCash.abs();

        contango.onVaultAccountDeleverage({
            positionId: ContangoNotionalProxy(payable(account)).positionId(),
            size: profitFromLiquidation.fromNotionalPrecision(lendTokenPrecision, true),
            cost: debtBurnt.fromNotionalPrecision(borrowTokenPrecision, false)
        });
    }

    function repaySecondaryBorrowCallback(
        address, // token,
        uint256, // underlyingRequired,
        bytes calldata // data
    ) external pure override returns (bytes memory) {
        revert Unsupported();
    }

    // ============================================== Admin functions ==============================================

    function collectBalance(ERC20 token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Allow ETH transfers to succeed
    }

    // ============================================== Private functions ==============================================

    function _currencyIdConfiguration(uint16 currencyId, address weth)
        private
        view
        returns (uint16 currencyId_, bool underlyingIsEth_, ERC20 underlyingToken_, uint256 tokenPrecision_)
    {
        currencyId_ = currencyId;
        address underlying = _getNotionalUnderlyingToken(currencyId);
        underlyingIsEth_ = underlying == address(0);
        underlyingToken_ = ERC20(underlyingIsEth_ ? weth : underlying);
        tokenPrecision_ = 10 ** underlyingToken_.decimals();
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) private view returns (address) {
        (Token memory assetToken, Token memory underlyingToken) = notional.getCurrency(currencyId);

        return assetToken.tokenType == TokenType.NonMintable ? assetToken.tokenAddress : underlyingToken.tokenAddress;
    }

    function _validateAccount(PositionId positionId, address proxy) private view {
        address expectedProxy = positionId.computeProxyAddress(address(contango), contangoProxyHash);

        if (proxy != expectedProxy) {
            revert InvalidContangoProxy(expectedProxy, proxy);
        }
    }

    modifier onlyContango() {
        if (msg.sender != address(contango)) {
            revert OnlyContango();
        }
        _;
    }

    modifier onlyNotional() {
        if (msg.sender != address(notional)) {
            revert OnlyNotional();
        }
        _;
    }

    modifier onDeleverage() {
        isDeleverage = true;
        _;
        isDeleverage = false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./NotionalStorageLib.sol";

import "./ContangoNotionalProxy.sol";

/// Contract responsible for deploying ContangoVault proxies, should be inherited by ContangoNotional.sol
/// inspired by https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3PoolDeployer.sol
contract ContangoVaultProxyDeployer is IContangoNotionalProxyDeployer {
    struct ProxyParameters {
        PositionId positionId;
        address payable owner;
        address payable delegate;
        ERC20[] tokens;
    }

    ProxyParameters private params;

    function deployVaultProxy(PositionId positionId, InstrumentStorage memory instrument)
        external
        returns (PermissionedProxy proxy)
    {
        // only allows itself to deploy a new vault proxy and avoid potential DoS attacks
        if (msg.sender != address(this)) {
            revert NotSelf();
        }

        // allows for owner to collect any balance in the instrument base/quote tokens that may end up in the proxy by mistake
        ERC20[] memory tokens = new ERC20[](2);
        tokens[0] = instrument.base;
        tokens[1] = instrument.quote;

        params = ProxyParameters({
            positionId: positionId,
            owner: payable(address(this)),
            delegate: payable(address(NotionalStorageLib.NOTIONAL)),
            tokens: tokens
        });
        proxy = new ContangoNotionalProxy{salt: bytes32(PositionId.unwrap(positionId))}();
        delete params;
    }

    function proxyParameters()
        external
        view
        returns (address payable owner, address payable delegate, ERC20[] memory tokens)
    {
        owner = params.owner;
        delegate = params.delegate;
        tokens = params.tokens;
    }

    function contangoNotionalParameters() external view returns (PositionId positionId) {
        positionId = params.positionId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IContangoNotionalAdminEvents {
    event ProxyHashSet(bytes32 proxyHash);
}

interface IContangoNotionalAdmin is IContangoNotionalAdminEvents {
    function setProxyHash(bytes32 proxyHash) external;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.17;

/// @dev https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/AssetRateAdapter.sol

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @dev only necessary constants from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Constants.sol
library Constants {
    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.17;

/// @dev https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/IStrategyVault.sol

interface IStrategyVault {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function strategy() external view returns (bytes4 strategyId);

    // Tells a vault to deposit some amount of tokens from Notional and mint strategy tokens with it.
    function depositFromNotional(address account, uint256 depositAmount, uint256 maturity, bytes calldata data)
        external
        payable
        returns (uint256 strategyTokensMinted);

    // Tells a vault to redeem some amount of strategy tokens from Notional and transfer the resulting asset cash
    function redeemFromNotional(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external returns (uint256 transferToReceiver);

    function convertStrategyToUnderlying(address account, uint256 strategyTokens, uint256 maturity)
        external
        view
        returns (int256 underlyingValue);

    function repaySecondaryBorrowCallback(address token, uint256 underlyingRequired, bytes calldata data)
        external
        returns (bytes memory returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @dev https://github.com/notional-finance/leveraged-vaults/blob/master/interfaces/trading/ITradingModule.sol
interface ITradingModule {
    event PriceOracleUpdated(address token, address oracle);
    event MaxOracleFreshnessUpdated(uint32 currentValue, uint32 newValue);

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external;
    function getOraclePrice(address inToken, address outToken) external view returns (int256 answer, int256 decimals);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

import "../Types.sol";

/// @dev only necessary function from https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/NotionalProxy.sol
interface NotionalProxy is IERC1155 {
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(uint256 maturity, uint256 blockTime) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashAmount, uint8 marketIndex, bytes32 encodedTrade);

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashDebt, uint8 marketIndex, bytes32 encodedTrade);

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 depositAmountUnderlying, uint256 depositAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 borrowAmountUnderlying, uint256 borrowAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);

    function settleVault(address vault, uint256 maturity) external;

    function getVaultState(address vault, uint256 maturity) external view returns (VaultState memory vaultState);

    function redeemStrategyTokensToCash(uint256 maturity, uint256 strategyTokensToRedeem, bytes calldata vaultData)
        external
        returns (int256 assetCashRequiredToSettle, int256 underlyingCashRequiredToSettle);

    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint256 depositAmountExternal,
        bool transferSharesToLiquidator,
        bytes calldata redeemData
    ) external returns (uint256 profitFromLiquidation);

    function encodeToId(uint16 currencyId, uint40 maturity, uint8 assetType) external pure returns (uint256 id);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./AssetRateAdapter.sol";

/// @dev only necessary types from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Types.sol

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType
// (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
{
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType
// No deposit action
{
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

struct VaultConfig {
    address vault;
    uint16 flags;
    uint16 borrowCurrencyId;
    int256 minAccountBorrowSize;
    int256 feeRate;
    int256 minCollateralRatio;
    int256 liquidationRate;
    int256 reserveFeeShare;
    uint256 maxBorrowMarketIndex;
    int256 maxDeleverageCollateralRatio;
    uint16[2] secondaryBorrowCurrencies;
    AssetRateParameters assetRate;
    int256 maxRequiredAccountCollateralRatio;
}

struct VaultAccount {
    int256 fCash;
    uint256 maturity;
    uint256 vaultShares;
    address account;
    // This cash balance is used just within a transaction to track deposits
    // and withdraws for an account. Must be zeroed by the time we store the account
    int256 tempCashBalance;
    uint256 lastEntryBlockHeight;
}

struct VaultState {
    uint256 maturity;
    int256 totalfCash;
    bool isSettled;
    uint256 totalVaultShares;
    uint256 totalAssetCash;
    uint256 totalStrategyTokens;
    int256 settlementStrategyTokenValue;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";

import "lib/solmate/src/tokens/WETH.sol";

import "../../libraries/CodecLib.sol";
import "../../libraries/PositionLib.sol";
import "../../libraries/ProxyLib.sol";
import "../../libraries/TransferLib.sol";

import "../../ExecutionProcessorLib.sol";
import "../SlippageLib.sol";
import "../UniswapV3Handler.sol";

import "./NotionalErrors.sol";
import "./NotionalStorageLib.sol";
import "./NotionalUtils.sol";
import "./ContangoVaultProxyDeployer.sol";

// solhint-disable not-rely-on-time
library Notional {
    using CodecLib for uint256;
    using NotionalUtils for *;
    using PositionLib for PositionId;
    using ProxyLib for PositionId;
    using SafeCast for *;
    using SignedMath for int256;
    using TransferLib for ERC20;

    // TODO alfredo - this will have a lot in common with Yield.sol, evaluate after implementation what can be shared
    // TODO alfredo - natspec

    // go around stack too deep issues
    struct CreatePositionParams {
        Symbol symbol;
        address trader;
        uint256 quantity;
        uint256 limitCost;
        uint256 collateral;
        address payer;
        uint256 lendingLiquidity;
        uint24 uniswapFee;
    }

    struct OpenEnterVaultParams {
        PositionId positionId;
        ContangoVault vault;
        uint256 maturity;
        uint256 fCashToBorrow;
        uint256 amountToBorrow;
        uint256 fCashLend;
        uint256 lendAmount;
    }

    struct CloseExitVaultParams {
        address proxy;
        ContangoVault vault;
        PositionId positionId;
        uint256 fCashLentToRedeem;
        uint256 fCashBorrowedToBurn;
        uint256 repaymentAmount;
        uint256 withdrawAmount;
        bool isQuoteWeth;
    }

    struct AddCollateralExitVaultParams {
        address proxy;
        ContangoVault vault;
        PositionId positionId;
        uint256 fCashBorrowedToBurn;
        uint256 collateral;
        bool isQuoteWeth;
    }

    struct RemoveCollateralEnterVaultParams {
        PositionId positionId;
        ContangoVault vault;
        uint256 maturity;
        uint256 fCashToBorrow;
        uint256 collateral;
        address receiver;
        uint256 quotePrecision;
    }

    struct SettleVaultAccountParams {
        ContangoVault vault;
        address proxy;
        uint256 maturity;
        uint256 repaymentAmount;
        uint256 withdrawAmount;
        address to;
        bool isQuoteWeth;
    }

    /// @dev IMPORTANT - make sure the events here are the same as in IContangoEvents
    /// this is needed because we're in a library and can't re-use events from an interface

    event ContractBought(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );
    event ContractSold(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );

    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );

    error InsufficientFCashFromLending(uint256 required, uint256 received);
    error OnlyFromVault(address expected, address actual);

    function createPosition(CreatePositionParams calldata params) external returns (PositionId positionId) {
        if (params.quantity == 0) {
            revert InvalidQuantity(int256(params.quantity));
        }

        positionId = ConfigStorageLib.getPositionNFT().mint(params.trader);
        positionId.validatePayer(params.payer, params.trader);

        StorageLib.getPositionInstrument()[positionId] = params.symbol;
        (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument) =
            _createPosition(params.symbol, positionId);

        _open(
            params.symbol,
            positionId,
            params.trader,
            instrument,
            notionalInstrument,
            params.quantity.roundFloorNotionalPrecision(notionalInstrument.basePrecision),
            params.limitCost,
            params.collateral.toInt256(),
            params.payer,
            params.lendingLiquidity,
            params.uniswapFee
        );
    }

    function _createPosition(Symbol symbol, PositionId positionId)
        private
        returns (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument)
    {
        (instrument, notionalInstrument,) = symbol.loadInstrument();

        if (instrument.maturity < block.timestamp) {
            revert InstrumentExpired(symbol, instrument.maturity, block.timestamp);
        }

        // no need to store the address since we can calculate it via ProxyLib.computeProxyAddress()
        ContangoVaultProxyDeployer(address(this)).deployVaultProxy(positionId, instrument);
    }

    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external {
        if (quantity == 0) {
            revert InvalidQuantity(quantity);
        }

        (uint256 openQuantity, address trader, Symbol symbol, InstrumentStorage memory instrument) =
            positionId.loadActivePosition();
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
        }

        if (quantity < 0 && uint256(-quantity) > openQuantity) {
            revert InvalidPositionDecrease(positionId, quantity, openQuantity);
        }

        _modifyPosition(
            symbol,
            positionId,
            trader,
            instrument,
            quantity,
            openQuantity,
            limitCost,
            collateral,
            payerOrReceiver,
            lendingLiquidity,
            uniswapFee
        );
    }

    function _modifyPosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        int256 quantity,
        uint256 openQuantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) private {
        NotionalInstrumentStorage memory notionalInstrument = NotionalStorageLib.getInstrument(positionId);
        uint256 uQuantity = quantity.abs().roundFloorNotionalPrecision(notionalInstrument.basePrecision);
        if (quantity > 0) {
            _open(
                symbol,
                positionId,
                trader,
                instrument,
                notionalInstrument,
                uQuantity,
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity,
                uniswapFee
            );
        } else {
            _close(
                symbol,
                positionId,
                trader,
                instrument,
                notionalInstrument,
                uQuantity,
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity,
                uniswapFee
            );
        }

        if (quantity < 0 && uint256(-quantity) == openQuantity) {
            positionId.deletePosition();
        }
    }

    function _open(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) private {
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }

        // Use a flash swap to buy enough base to hedge the position, pay directly to the pool where we'll lend it
        _flashBuyHedge(
            instrument,
            notionalInstrument,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: true,
                lendingLiquidity: lendingLiquidity,
                uniswapFee: uniswapFee
            }),
            quantity,
            collateral,
            address(this)
        );
    }

    function completeOpen(UniswapV3Handler.Callback memory callback) private {
        (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument, ContangoVault vault)
        = callback.info.symbol.loadInstrument();

        // needs to borrow at least to cover uniswap costs
        uint256 amountToBorrow = callback.fill.hedgeCost;
        uint256 collateralPosted;
        if (callback.fill.collateral > 0) {
            collateralPosted = callback.fill.collateral.toUint256();
            // fully covered by the collateral posted
            amountToBorrow = (collateralPosted < amountToBorrow) ? amountToBorrow - collateralPosted : 0;
        } else if (callback.fill.collateral < 0) {
            // uniswap cost + withdrawn collateral
            amountToBorrow += callback.fill.collateral.abs();
        }

        // 3. enter vault by borrowing the quote owed to uniswap minus collateral and pass base amount as param
        // -> continues inside vault
        uint256 debt = _openEnterVault(callback, instrument, notionalInstrument, vault, amountToBorrow);

        uint256 remainingUniswapDebt = callback.fill.hedgeCost;
        if (callback.fill.collateral > 0) {
            // Trader can contribute up to the spot cost
            uint256 collateralUsed = Math.min(collateralPosted, callback.fill.hedgeCost);
            callback.fill.cost = debt + collateralUsed;
            callback.fill.collateral = collateralUsed.toInt256();
            remainingUniswapDebt -= collateralUsed;

            instrument.quote.transferOut(callback.info.payerOrReceiver, msg.sender, collateralUsed);
        }

        if (callback.fill.collateral < 0) {
            callback.fill.cost = callback.fill.hedgeCost + (debt - amountToBorrow);
        } else {
            callback.fill.cost = debt + callback.fill.collateral.toUint256();
        }

        SlippageLib.requireCostBelowTolerance(callback.fill.cost, callback.info.limitCost);

        // 6. repay uniswap
        if (remainingUniswapDebt > 0) {
            instrument.quote.transferOut(address(this), msg.sender, remainingUniswapDebt);
        }

        ExecutionProcessorLib.increasePosition({
            symbol: callback.info.symbol,
            positionId: callback.info.positionId,
            trader: callback.info.trader,
            size: callback.fill.size,
            cost: callback.fill.cost,
            collateralDelta: callback.fill.collateral,
            quoteToken: callback.instrument.quote,
            to: callback.info.payerOrReceiver,
            minCost: 0 // TODO alfredo - get from vault config
        });

        emit ContractBought(
            callback.info.symbol,
            callback.info.trader,
            callback.info.positionId,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.hedgeSize,
            callback.fill.hedgeCost,
            callback.fill.collateral
        );
    }

    function _openEnterVault(
        UniswapV3Handler.Callback memory callback,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        ContangoVault vault,
        uint256 amountToBorrow
    ) private returns (uint256 debt) {
        uint256 fCashToBorrow = amountToBorrow > 0
            ? NotionalStorageLib.NOTIONAL.quoteBorrowOpenCost(amountToBorrow, instrument, notionalInstrument)
            : 0;

        _openEnterVaultCall(
            OpenEnterVaultParams({
                positionId: callback.info.positionId,
                vault: vault,
                maturity: instrument.maturity,
                fCashToBorrow: fCashToBorrow,
                amountToBorrow: amountToBorrow,
                fCashLend: callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true),
                lendAmount: callback.fill.hedgeSize
            })
        );

        debt = fCashToBorrow.fromNotionalPrecision(notionalInstrument.quotePrecision, true);
    }

    function _openEnterVaultCall(OpenEnterVaultParams memory params) private {
        address proxy = params.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        // -> continues inside vault
        uint256 lentFCashAmount = NotionalProxy(proxy).enterVault({
            account: proxy,
            vault: address(params.vault),
            depositAmountExternal: 0,
            maturity: params.maturity,
            fCash: params.fCashToBorrow,
            maxBorrowRate: 0,
            vaultData: abi.encode(
                ContangoVault.EnterParams({
                    positionId: params.positionId,
                    payer: address(this),
                    // TODO alfredo - check gas savings by having two extra params and save one transfer (transfer to uni and trader from inside the vault)
                    receiver: address(this),
                    borrowAmount: params.amountToBorrow,
                    lendAmount: params.lendAmount,
                    fCashLendAmount: params.fCashLend
                })
                )
        });

        if (lentFCashAmount < params.fCashLend) {
            revert InsufficientFCashFromLending(params.fCashLend, lentFCashAmount);
        }
    }

    function _close(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) private {
        // Execute a flash swap to undo the hedge
        _flashSellHedge(
            instrument,
            notionalInstrument,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: false,
                lendingLiquidity: lendingLiquidity,
                uniswapFee: uniswapFee
            }),
            quantity,
            collateral,
            address(this)
        );
    }

    function completeClose(UniswapV3Handler.Callback memory callback) private {
        (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument, ContangoVault vault)
        = callback.info.symbol.loadInstrument();
        (uint256 openQuantity,) = StorageLib.getPositionNotionals()[callback.info.positionId].decodeU128();

        bool fullyClosing = openQuantity - callback.fill.size == 0;
        {
            uint256 balanceBefore = instrument.quote.balanceOf(address(this));

            // 3. Exit vault
            uint256 debtRepaid = _closeExitVault(callback, instrument, notionalInstrument, vault, fullyClosing)
                .fromNotionalPrecision(notionalInstrument.quotePrecision, false);

            uint256 repaymentCost = balanceBefore - instrument.quote.balanceOf(address(this));
            callback.fill.cost = callback.fill.hedgeCost + (debtRepaid - repaymentCost);
        }

        // TODO alfredo - check second clause and why it is needed
        // discount posted collateral from fill cost if applicable
        if (callback.fill.collateral > 0 && uint256(callback.fill.collateral) < callback.fill.cost) {
            callback.fill.cost -= uint256(callback.fill.collateral);
        }

        // 7. Pay swap with remaining base and transfer quote (inside ExecutionProcessorLib)
        instrument.base.transferOut(address(this), msg.sender, callback.fill.hedgeSize);

        SlippageLib.requireCostAboveTolerance(callback.fill.cost, callback.info.limitCost);

        emit ContractSold(
            callback.info.symbol,
            callback.info.trader,
            callback.info.positionId,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.hedgeSize,
            callback.fill.hedgeCost,
            callback.fill.collateral
        );

        if (fullyClosing) {
            ExecutionProcessorLib.closePosition({
                symbol: callback.info.symbol,
                positionId: callback.info.positionId,
                trader: callback.info.trader,
                cost: callback.fill.cost,
                quoteToken: callback.instrument.quote,
                to: callback.info.payerOrReceiver
            });
        } else {
            ExecutionProcessorLib.decreasePosition({
                symbol: callback.info.symbol,
                positionId: callback.info.positionId,
                trader: callback.info.trader,
                size: callback.fill.size,
                cost: callback.fill.cost,
                collateralDelta: callback.fill.collateral,
                quoteToken: callback.instrument.quote,
                to: callback.info.payerOrReceiver,
                minCost: 0 // TODO alfredo - get from vault config
            });
        }
    }

    function _closeExitVault(
        UniswapV3Handler.Callback memory callback,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        ContangoVault vault,
        bool fullyClosing
    ) private returns (uint256 fCashBorrowedToBurn) {
        address payable proxy =
            callback.info.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        VaultAccount memory vaultAccount = NotionalStorageLib.NOTIONAL.getVaultAccount(proxy, address(vault));

        // Can't withdraw more than what we got from UNI
        if (callback.fill.collateral < 0) {
            callback.fill.collateral = SignedMath.max(callback.fill.collateral, -callback.fill.hedgeCost.toInt256());
        }
        int256 quoteUsedToRepayDebt = callback.fill.hedgeCost.toInt256() + callback.fill.collateral;

        if (fullyClosing) {
            fCashBorrowedToBurn = vaultAccount.fCash.abs();
        } else {
            if (quoteUsedToRepayDebt > 0) {
                // If the user is depositing, take the necessary tokens
                if (callback.fill.collateral > 0) {
                    instrument.quote.transferOut(
                        callback.info.payerOrReceiver, address(this), uint256(callback.fill.collateral)
                    );
                }

                fCashBorrowedToBurn = NotionalStorageLib.NOTIONAL.quoteBorrowClose(
                    uint256(quoteUsedToRepayDebt), instrument, notionalInstrument
                );
            }
        }

        // track balances as Notional will send back any excess
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        // unwrap ETH ahead if applicable
        if (notionalInstrument.isQuoteWeth && quoteUsedToRepayDebt > 0) {
            WETH(payable(address(instrument.quote))).withdraw(uint256(quoteUsedToRepayDebt));
        }

        // skips a precision conversion and avoid possible dust issues when fully closing a position
        uint256 fCashLentToRedeem = fullyClosing
            ? vaultAccount.vaultShares
            : callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);

        _closeExitVaultCall(
            CloseExitVaultParams({
                proxy: proxy,
                vault: vault,
                positionId: callback.info.positionId,
                fCashLentToRedeem: fCashLentToRedeem,
                fCashBorrowedToBurn: fCashBorrowedToBurn,
                repaymentAmount: quoteUsedToRepayDebt > 0 ? uint256(quoteUsedToRepayDebt) : 0,
                withdrawAmount: callback.fill.hedgeSize,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        // TODO alfredo - evaluate if we want to leave the dust in the proxy itself
        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _closeExitVaultCall(CloseExitVaultParams memory params) private {
        // --> continues inside vault
        uint256 sendValue = params.isQuoteWeth ? params.repaymentAmount : 0;
        NotionalProxy(params.proxy).exitVault{value: sendValue}({
            account: params.proxy,
            vault: address(params.vault),
            receiver: address(params.vault), // TODO alfredo - review where we want this dust sent
            vaultSharesToRedeem: params.fCashLentToRedeem,
            fCashToLend: params.fCashBorrowedToBurn,
            minLendRate: 0,
            exitVaultData: abi.encode(
                ContangoVault.ExitParams({
                    positionId: params.positionId,
                    // TODO alfredo - check gas savings by having two extra params and save one transfer (transfer from contango (swap) and trader from inside the vault)
                    payer: address(this),
                    receiver: address(this),
                    withdrawAmount: params.withdrawAmount
                })
                )
        });
    }

    function _flashBuyHedge(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;

        // 1. quote base fCash
        uint256 fCashQuantity = callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);
        callback.fill.hedgeSize =
            NotionalStorageLib.NOTIONAL.quoteLendOpenCost(fCashQuantity, instrument, notionalInstrument);

        callback.info = callbackInfo;

        // 2. flash swap to get quoted base
        // -> continues inside flashswap callback
        UniswapV3Handler.flashSwap(callback, instrument, false, to);
    }

    /// @dev calculates the amount of base ccy to sell based on the traded quantity and executes a flash swap
    function _flashSellHedge(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;

        // 1. Quote how much base for base fCash
        uint256 fCashQuantity = callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);
        callback.fill.hedgeSize =
            NotionalStorageLib.NOTIONAL.quoteLendClose(fCashQuantity, instrument, notionalInstrument);

        callback.info = callbackInfo;

        // 2. Flash swap to get quote
        // -> continues inside flashswap callback
        UniswapV3Handler.flashSwap(callback, instrument, true, to);
    }

    // ============== Uniswap functions ==============

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        UniswapV3Handler.uniswapV3SwapCallback(amount0Delta, amount1Delta, data, _onUniswapCallback);
    }

    function _onUniswapCallback(UniswapV3Handler.Callback memory callback) internal {
        if (callback.info.open) completeOpen(callback);
        else completeClose(callback);
    }

    // ============== Collateral management ==============

    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        (, address trader, Symbol symbol, InstrumentStorage memory instrument) = positionId.loadActivePosition();

        uint256 uCollateral = collateral.abs();
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
            _addCollateral(
                symbol,
                positionId,
                trader,
                instrument,
                uCollateral,
                slippageTolerance,
                payerOrReceiver,
                lendingLiquidity
            );
        } else if (collateral < 0) {
            _removeCollateral(symbol, positionId, trader, instrument, uCollateral, slippageTolerance, payerOrReceiver);
        }
    }

    function _addCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address payer,
        uint256 lendingLiquidity
    ) private {
        NotionalInstrumentStorage memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        _handleAddCollateralFunds(instrument, notionalInstrument, payer, proxy, collateral);

        if (lendingLiquidity == 0) {
            revert NotImplemented("_addCollateral() - force: true");
        }

        // Quote how much debt can be burned with collateral provided
        uint256 fCashBorrowedToBurn =
            NotionalStorageLib.NOTIONAL.quoteBorrowClose(collateral, instrument, notionalInstrument);
        uint256 debtBurnt = fCashBorrowedToBurn.fromNotionalPrecision(notionalInstrument.quotePrecision, false);
        // Burn debt
        _addCollateralExitVault(
            AddCollateralExitVaultParams({
                proxy: proxy,
                vault: vault,
                positionId: positionId,
                fCashBorrowedToBurn: fCashBorrowedToBurn,
                collateral: collateral,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        SlippageLib.requireCostAboveTolerance(debtBurnt, slippageTolerance);

        _processUpdateCollateral(symbol, positionId, trader, collateral, debtBurnt);

        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _handleAddCollateralFunds(
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument,
        address payer,
        address payable proxy,
        uint256 collateral
    ) private {
        if (notionalInstrument.isQuoteWeth) {
            WETH(payable(address(instrument.quote))).withdraw(collateral);
        } else {
            // TODO alfredo - see if we can tell Notional where to pull the funds from to avoid these transfers and approvals
            // Transfer the new collateral from the payer to the proxy and allow Notional to pull funds
            instrument.quote.transferOut(payer, proxy, collateral);
            PermissionedProxy(proxy).approve({
                token: instrument.quote,
                spender: address(NotionalStorageLib.NOTIONAL),
                amount: collateral
            });
        }
    }

    function _addCollateralExitVault(AddCollateralExitVaultParams memory params) private {
        // TODO alfredo - some operations can be done without wrap/unwrap and save some gas
        uint256 sendValue = params.isQuoteWeth ? params.collateral : 0;
        NotionalProxy(params.proxy).exitVault{value: sendValue}({
            account: params.proxy,
            vault: address(params.vault),
            receiver: address(params.vault), // TODO alfredo - review where we want this dust sent
            vaultSharesToRedeem: 0,
            fCashToLend: params.fCashBorrowedToBurn,
            minLendRate: 0,
            exitVaultData: abi.encode(
                ContangoVault.ExitParams({
                    positionId: params.positionId,
                    payer: address(0),
                    receiver: address(this),
                    withdrawAmount: 0
                })
                )
        });
    }

    function _processUpdateCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 collateral,
        uint256 debtBurnt
    ) private {
        // The interest pnl is reflected on the position cost
        int256 cost = -(debtBurnt - collateral).toInt256();

        ExecutionProcessorLib.updateCollateral({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            cost: cost,
            amount: int256(collateral)
        });

        emit CollateralAdded(symbol, trader, positionId, collateral, debtBurnt);
    }

    function _removeCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address receiver
    ) private {
        NotionalInstrumentStorage memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        // Borrow whatever the trader wants to withdraw
        uint256 debt = _removeCollateralEnterVault(
            RemoveCollateralEnterVaultParams({
                positionId: positionId,
                vault: vault,
                maturity: instrument.maturity,
                fCashToBorrow: NotionalStorageLib.NOTIONAL.quoteBorrowOpenCost(collateral, instrument, notionalInstrument),
                collateral: collateral,
                receiver: receiver,
                quotePrecision: notionalInstrument.quotePrecision
            })
        );

        SlippageLib.requireCostBelowTolerance(debt, slippageTolerance);

        // The interest pnl is reflected on the position cost
        int256 cost = int256(debt - collateral);

        // cast to int is safe as it was previously int256
        ExecutionProcessorLib.updateCollateral({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            cost: cost,
            amount: -int256(collateral)
        });

        emit CollateralRemoved(symbol, trader, positionId, collateral, debt);
    }

    function _removeCollateralEnterVault(RemoveCollateralEnterVaultParams memory params)
        private
        returns (uint256 debt)
    {
        debt = params.fCashToBorrow.fromNotionalPrecision(params.quotePrecision, true);

        address proxy = params.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        NotionalProxy(proxy).enterVault({
            account: proxy,
            vault: address(params.vault),
            depositAmountExternal: 0,
            maturity: params.maturity,
            fCash: params.fCashToBorrow,
            maxBorrowRate: 0,
            vaultData: abi.encode(
                ContangoVault.EnterParams({
                    positionId: params.positionId,
                    payer: address(0),
                    receiver: params.receiver,
                    borrowAmount: params.collateral,
                    lendAmount: 0,
                    fCashLendAmount: 0
                })
                )
        });
    }

    // ============== Physical delivery ==============

    function deliver(PositionId positionId, address payer, address to) external {
        address trader = positionId.lookupPositionOwner();
        positionId.validatePayer(payer, trader);

        (uint256 openQuantity, Symbol symbol, InstrumentStorage memory instrument) =
            positionId.validateExpiredPosition();

        _deliver(symbol, positionId, openQuantity, trader, instrument, payer, to);

        positionId.deletePosition();
    }

    function _deliver(
        Symbol symbol,
        PositionId positionId,
        uint256 openQuantity,
        address trader,
        InstrumentStorage memory instrument,
        address payer,
        address to
    ) private {
        NotionalInstrumentStorage memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        VaultAccount memory vaultAccount = NotionalStorageLib.NOTIONAL.getVaultAccount(proxy, address(vault));

        if (vaultAccount.fCash == 0) {
            // TODO alfredo - revisit on liquidation
            revert NotImplemented("_deliver() - no debt");
        }

        // debt/lend value remains the same either at maturity or any time after + buffer for rounding issues
        uint256 requiredQuote = uint256(-vaultAccount.fCash).fromNotionalPrecision(
            notionalInstrument.quotePrecision, true
        ).buffer(notionalInstrument.quotePrecision);

        // transfer required quote from payer and settle vault
        instrument.quote.transferOut(payer, address(this), requiredQuote);
        if (notionalInstrument.isQuoteWeth) {
            WETH(payable(address(instrument.quote))).withdraw(uint256(requiredQuote));
        }

        // by only doing the settling, the vault accounts will be left without its accounting being updated,
        // this is not a problem since we'll transfer the corresponding debt repayment to vault anyway and
        // Notional should clear all vault accounts once all vault shares are redeemed and the full vault is settled.
        _settleVaultAccount(
            SettleVaultAccountParams({
                vault: vault,
                proxy: proxy,
                maturity: instrument.maturity,
                repaymentAmount: requiredQuote,
                withdrawAmount: openQuantity,
                to: to,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        _processDeliverPosition({
            symbol: symbol,
            positionId: positionId,
            instrument: instrument,
            trader: trader,
            deliverableQuantity: openQuantity,
            deliveryCost: requiredQuote,
            payer: payer,
            to: to
        });

        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _settleVaultAccount(SettleVaultAccountParams memory params) private {
        uint256 sendValue = params.isQuoteWeth ? params.repaymentAmount : 0;
        params.vault.settleAccount{value: sendValue}({
            account: params.proxy,
            maturity: params.maturity,
            data: abi.encode(
                ContangoVault.SettleParams({
                    payer: address(this),
                    receiver: params.to,
                    repaymentAmount: params.repaymentAmount,
                    withdrawAmount: params.withdrawAmount
                })
                )
        });
    }

    function _processDeliverPosition(
        Symbol symbol,
        PositionId positionId,
        InstrumentStorage memory instrument,
        address trader,
        uint256 deliverableQuantity,
        uint256 deliveryCost,
        address payer,
        address to
    ) private {
        ExecutionProcessorLib.deliverPosition({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            deliverableQuantity: deliverableQuantity,
            deliveryCost: deliveryCost,
            payer: payer,
            quoteToken: instrument.quote,
            to: to
        });
    }

    // ============== Liquidation ==============

    function onVaultAccountDeleverage(PositionId positionId, uint256 size, uint256 cost) external {
        (uint256 openQuantity, Symbol symbol,) = positionId.validateActivePosition();
        address vault = address(NotionalStorageLib.getVaults()[symbol]);
        if (msg.sender != vault) {
            revert OnlyFromVault(vault, msg.sender);
        }

        // TODO alfredo - this is not pretty, confirm there's no other more elegant solution
        // go around off by one error on notional side, ensuring full liquidation is processed properly
        uint256 scaledOne =
            uint256(1).fromNotionalPrecision(NotionalStorageLib.getInstrument(positionId).basePrecision, true);
        if (size == openQuantity - scaledOne) {
            size = openQuantity;
        }

        ExecutionProcessorLib.liquidatePosition({
            symbol: symbol,
            positionId: positionId,
            trader: ConfigStorageLib.getPositionNFT().positionOwner(positionId),
            size: size,
            cost: cost
        });
    }

    function _collectProxyQuoteBalance(address payable proxy, uint256 floor, ERC20 quote, bool isQuoteWeth) private {
        // dust may accumulate due to:
        // - Notional debt repayment quoting mismatching with execution
        // - cost rounding in our protocol's favours
        uint256 currentBalance = isQuoteWeth ? proxy.balance : quote.balanceOf(proxy);
        uint256 collectableBalance = currentBalance - floor;
        if (collectableBalance > 0) {
            if (isQuoteWeth) {
                PermissionedProxy(proxy).collectBalance(collectableBalance);
                WETH(payable(address(quote))).deposit{value: collectableBalance}();
            } else {
                quote.transferOut(proxy, address(this), collectableBalance);
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO these should be removed before going live
error NotImplemented(string description);

error Unsupported();

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ContangoVault.sol";
import "./NotionalUtils.sol";

import "../../libraries/StorageLib.sol";

library NotionalStorageLib {
    using NotionalUtils for ERC20;
    using SafeCast for uint256;

    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum NotionalStorageId {
        Unused, // 0
        Instruments, // 1
        Vaults // 2
    }

    error InvalidBaseId(Symbol symbol, uint16 currencyId);
    error InvalidQuoteId(Symbol symbol, uint16 currencyId);
    error InvalidMarketIndex(uint16 currencyId, uint256 marketIndex, uint256 max);
    error MismatchedMaturity(Symbol symbol, uint16 baseId, uint32 baseMaturity, uint16 quoteId, uint32 quoteMaturity);

    event NotionalInstrumentCreated(
        InstrumentStorage instrument, NotionalInstrumentStorage notionalInstrument, ContangoVault vault
    );

    // solhint-disable no-inline-assembly
    function getVaults() internal pure returns (mapping(Symbol => ContangoVault) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Vaults);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    // solhint-disable no-inline-assembly
    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => NotionalInstrumentStorage) storage store) {
        uint256 slot = getStorageSlot(NotionalStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    function getInstrument(PositionId positionId) internal view returns (NotionalInstrumentStorage storage) {
        return getInstruments()[StorageLib.getPositionInstrument()[positionId]];
    }

    function createInstrument(
        Symbol symbol,
        uint16 baseId,
        uint16 quoteId,
        uint256 marketIndex,
        ContangoVault vault,
        address weth // sucks but beats doing another SLOAD to fetch from configs
    ) internal returns (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument) {
        uint32 maturity = _validInstrumentData(symbol, baseId, quoteId, marketIndex);
        (instrument, notionalInstrument) = _createInstrument(baseId, quoteId, maturity, weth);

        // since the contango contracts should not hold any funds once a transaction is done,
        // and createInstrument is a permissioned manually invoked admin function (therefore with controlled inputs),
        // infinite approve here to the vault is fine
        SafeTransferLib.safeApprove(ERC20(address(instrument.base)), address(vault), type(uint256).max);
        SafeTransferLib.safeApprove(ERC20(address(instrument.quote)), address(vault), type(uint256).max);

        StorageLib.getInstruments()[symbol] = instrument;
        getInstruments()[symbol] = notionalInstrument;
        getVaults()[symbol] = vault;

        emit NotionalInstrumentCreated(instrument, notionalInstrument, vault);
    }

    function _createInstrument(uint16 baseId, uint16 quoteId, uint32 maturity, address weth)
        private
        view
        returns (InstrumentStorage memory instrument, NotionalInstrumentStorage memory notionalInstrument)
    {
        notionalInstrument.baseId = baseId;
        notionalInstrument.quoteId = quoteId;

        instrument.maturity = maturity;

        (, Token memory baseUnderlyingToken) = NOTIONAL.getCurrency(baseId);
        (, Token memory quoteUnderlyingToken) = NOTIONAL.getCurrency(quoteId);

        address baseAddress = baseUnderlyingToken.tokenType == TokenType.Ether ? weth : baseUnderlyingToken.tokenAddress;
        address quoteAddress =
            quoteUnderlyingToken.tokenType == TokenType.Ether ? weth : quoteUnderlyingToken.tokenAddress;

        instrument.base = ERC20(baseAddress);
        instrument.quote = ERC20(quoteAddress);

        notionalInstrument.basePrecision = (10 ** instrument.base.decimals()).toUint64();
        notionalInstrument.quotePrecision = (10 ** instrument.quote.decimals()).toUint64();

        notionalInstrument.isQuoteWeth = address(instrument.quote) == address(weth);
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `NotionalStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(NotionalStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + NOTIONAL_STORAGE_SLOT_BASE;
    }

    function _validInstrumentData(Symbol symbol, uint16 baseId, uint16 quoteId, uint256 marketIndex)
        private
        view
        returns (uint32)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 baseMaturity = _validateMarket(NOTIONAL, baseId, marketIndex);
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        // should never happen in Notional since it validates that the currencyId is valid and has a valid maturity
        uint256 quoteMaturity = _validateMarket(NOTIONAL, quoteId, marketIndex);
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        // should never happen since we're using the exact marketIndex on the same block/timestamp
        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, uint32(baseMaturity), quoteId, uint32(quoteMaturity));
        }

        return uint32(baseMaturity);
    }

    function _validateMarket(NotionalProxy notional, uint16 currencyId, uint256 marketIndex)
        private
        view
        returns (uint256 maturity)
    {
        MarketParameters[] memory marketParameters = notional.getActiveMarkets(currencyId);
        if (marketIndex == 0 || marketIndex > marketParameters.length) {
            revert InvalidMarketIndex(currencyId, marketIndex, marketParameters.length);
        }

        maturity = marketParameters[marketIndex - 1].maturity;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "./internal/Constants.sol";
import "./internal/interfaces/NotionalProxy.sol";

import "../../libraries/DataTypes.sol";
import "../../libraries/Errors.sol";
import "../../libraries/MathLib.sol";
import "../../libraries/StorageLib.sol";

import "./ContangoVault.sol";
import "./NotionalStorageLib.sol";

library NotionalUtils {
    using MathLib for uint256;
    using NotionalUtils for uint256;
    using SafeCast for uint256;

    uint256 private constant NOTIONAL_PRECISION = uint256(Constants.INTERNAL_TOKEN_PRECISION);

    function loadInstrument(Symbol symbol)
        internal
        view
        returns (
            InstrumentStorage storage instrument,
            NotionalInstrumentStorage storage notionalInstrument,
            ContangoVault vault
        )
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        vault = NotionalStorageLib.getVaults()[symbol];
    }

    function quoteLendOpenCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.baseId,
            fCashAmount: fCashAmount + 1, // buffer lending open to go around dust issue when physically delivering
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteLendClose(
        NotionalProxy notional,
        uint256 fCashAmount,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.baseId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowOpenCost(
        NotionalProxy notional,
        uint256 borrow,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint88 fCashAmount) {
        (fCashAmount,,) = notional.getfCashBorrowFromPrincipal({
            currencyId: notionalInstrument.quoteId,
            borrowedAmountExternal: borrow,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
        // Empirically it appears that the fCash to cash exchange rate is at most 0.01 basis points (0.0001 percent)
        // amount input into the function. This is likely due to rounding errors in calculations. What you can do to
        // buffer these values is to increase the size by x += (x * 100) / 1e9 -> equivalent to x += x / 1e7
        fCashAmount += fCashAmount >= 1e7 ? fCashAmount / 1e7 : 1;
    }

    function quoteBorrowOpen(
        NotionalProxy notional,
        uint256 fCashAmount,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint256 principal) {
        (principal,,,) = notional.getPrincipalFromfCashBorrow({
            currencyId: notionalInstrument.quoteId,
            fCashBorrow: fCashAmount,
            maturity: instrument.maturity,
            maxBorrowRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowCloseCost(
        NotionalProxy notional,
        uint256 fCashAmount,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint256 deposit) {
        (deposit,,,) = notional.getDepositFromfCashLend({
            currencyId: notionalInstrument.quoteId,
            fCashAmount: fCashAmount,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp // solhint-disable-line not-rely-on-time
        });
    }

    function quoteBorrowClose(
        NotionalProxy notional,
        uint256 deposit,
        InstrumentStorage memory instrument,
        NotionalInstrumentStorage memory notionalInstrument
    ) internal view returns (uint256 fCashAmount) {
        (fCashAmount,,) = notional.getfCashLendFromDeposit({
            currencyId: notionalInstrument.quoteId,
            depositAmountExternal: deposit,
            maturity: instrument.maturity,
            minLendRate: 0, // no limit
            blockTime: block.timestamp, // solhint-disable-line not-rely-on-time
            useUnderlying: true
        });
    }

    function toNotionalPrecision(uint256 value, uint256 fromPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(fromPrecision, NOTIONAL_PRECISION, roundCeiling);
    }

    function fromNotionalPrecision(uint256 value, uint256 toPrecision, bool roundCeiling)
        internal
        pure
        returns (uint256)
    {
        return value.scale(NOTIONAL_PRECISION, toPrecision, roundCeiling);
    }

    function buffer(uint256 value, uint256 precision) internal pure returns (uint256) {
        if (value == 0) {
            return 0;
        }
        return value + (precision > NOTIONAL_PRECISION ? precision / NOTIONAL_PRECISION : 1);
    }

    function roundFloorNotionalPrecision(uint256 value, uint256 precision) internal pure returns (uint256 rounded) {
        if (precision > NOTIONAL_PRECISION) {
            rounded = value.toNotionalPrecision(precision, false).fromNotionalPrecision(precision, false);
        } else {
            rounded = value;
        }
    }

    function encodeOpenLendAction(
        uint16 currencyId,
        uint8 marketIndex,
        uint256 depositActionAmount,
        uint88 fCashLendAmount
    ) internal pure returns (BalanceActionWithTrades memory action) {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.DepositUnderlying;
        action.depositActionAmount = depositActionAmount;
        action.trades = new bytes32[](1);
        action.trades[0] = bytes32(abi.encodePacked(uint8(TradeActionType.Lend), marketIndex, fCashLendAmount));
    }

    function encodeCloseLendAction(uint16 currencyId, uint8 marketIndex, uint88 fCashAmount)
        internal
        pure
        returns (BalanceActionWithTrades memory action)
    {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawEntireCashBalance = true;
        action.redeemToUnderlying = true;
        action.trades = new bytes32[](1);
        action.trades[0] = bytes32(abi.encodePacked(uint8(TradeActionType.Borrow), marketIndex, fCashAmount));
    }

    function encodeWithdrawAction(uint16 currencyId, uint256 withdrawAmountInternal)
        internal
        pure
        returns (BalanceAction memory action)
    {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawAmountInternalPrecision = withdrawAmountInternal;
        action.redeemToUnderlying = true;
    }

    function encodeWithdrawAllAction(uint16 currencyId) internal pure returns (BalanceAction memory action) {
        action.currencyId = currencyId;
        action.actionType = DepositActionType.None;
        action.withdrawEntireCashBalance = true;
        action.redeemToUnderlying = true;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library SlippageLib {
    error CostAboveTolerance(uint256 limitCost, uint256 actualCost);
    error CostBelowTolerance(uint256 limitCost, uint256 actualCost);

    function requireCostAboveTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost < limitCost) revert CostBelowTolerance(limitCost, cost);
    }

    function requireCostBelowTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost > limitCost) revert CostAboveTolerance(limitCost, cost);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libraries/StorageDataTypes.sol";
import "../dependencies/Uniswap.sol";

library UniswapV3Handler {
    using Address for address;
    using SafeCast for uint256;
    using SignedMath for int256;
    using PoolAddress for address;

    error InvalidAmountDeltas(int256 amount0Delta, int256 amount1Delta);
    error InvalidCallbackCaller(address caller);
    error InvalidPoolKey(PoolAddress.PoolKey poolKey);
    error InsufficientHedgeAmount(uint256 hedgeSize, uint256 swapAmount);

    struct Callback {
        CallbackInfo info;
        InstrumentStorage instrument;
        Fill fill;
    }

    struct CallbackInfo {
        Symbol symbol;
        PositionId positionId;
        address trader;
        uint256 limitCost;
        address payerOrReceiver;
        bool open;
        uint256 lendingLiquidity;
        uint24 uniswapFee;
    }

    address internal constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @notice Executes a flash swap on Uni V3, to buy/sell the hedgeSize
    /// @param callback Info collected before the flash swap started
    /// @param instrument The instrument being swapped
    /// @param baseForQuote True if base if being sold
    /// @param to The address to receive the output of the swap
    function flashSwap(Callback memory callback, InstrumentStorage memory instrument, bool baseForQuote, address to)
        internal
    {
        callback.instrument = instrument;

        (address tokenIn, address tokenOut) = baseForQuote
            ? (address(instrument.base), address(instrument.quote))
            : (address(instrument.quote), address(instrument.base));

        bool zeroForOne = tokenIn < tokenOut;

        IUniswapV3Pool(lookupPoolAddress(tokenIn, tokenOut, callback.info.uniswapFee)).swap({
            recipient: to,
            zeroForOne: zeroForOne,
            amountSpecified: baseForQuote ? callback.fill.hedgeSize.toInt256() : -callback.fill.hedgeSize.toInt256(),
            sqrtPriceLimitX96: (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            data: abi.encode(callback)
        });
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data,
        function(UniswapV3Handler.Callback memory) internal onUniswapCallback
    ) internal {
        if (amount0Delta < 0 && amount1Delta < 0 || amount0Delta > 0 && amount1Delta > 0) {
            revert InvalidAmountDeltas(amount0Delta, amount1Delta);
        }

        Callback memory callback = abi.decode(data, (Callback));
        InstrumentStorage memory instrument = callback.instrument;
        address poolAddress =
            lookupPoolAddress(address(instrument.base), address(instrument.quote), callback.info.uniswapFee);

        if (msg.sender != poolAddress) {
            revert InvalidCallbackCaller(msg.sender);
        }

        bool amount0isBase = instrument.base < instrument.quote;
        uint256 swapAmount = (amount0isBase ? amount0Delta : amount1Delta).abs();

        if (callback.fill.hedgeSize != swapAmount) {
            revert InsufficientHedgeAmount(callback.fill.hedgeSize, swapAmount);
        }

        callback.fill.hedgeCost = (amount0isBase ? amount1Delta : amount0Delta).abs();
        onUniswapCallback(callback);
    }

    function lookupPoolAddress(address token0, address token1, uint24 fee)
        internal
        view
        returns (address poolAddress)
    {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(token0, token1, fee);
        poolAddress = UNISWAP_FACTORY.computeAddress(poolKey);
        if (!poolAddress.isContract()) {
            revert InvalidPoolKey(poolKey);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "lib/solmate/src/tokens/WETH.sol";
import {IContangoLadle} from "lib/vault-v2/src/other/contango/interfaces/IContangoLadle.sol";
import "lib/vault-v2/src/other/contango/interfaces/IContangoWitchListener.sol";

import "./interfaces/IContangoYield.sol";
import "./interfaces/IContangoYieldAdmin.sol";
import "./Yield.sol";
import "./YieldUtils.sol";

import "../ContangoBase.sol";

/// @notice Contract that acts as the main entry point to the protocol with yield-protocol as the underlying
/// @dev This is the main entry point to the system when using yield-protocol as the underlying
contract ContangoYield is ContangoBase, IContangoWitchListener, IContangoYield, IContangoYieldAdmin {
    using SafeCast for uint256;
    using YieldUtils for Symbol;

    bytes32 public constant WITCH = keccak256("WITCH");

    // solhint-disable-next-line no-empty-blocks
    constructor(WETH _weth) ContangoBase(_weth) {}

    function initialize(ContangoPositionNFT _positionNFT, address _treasury, IContangoLadle _ladle)
        public
        initializer
    {
        __ContangoBase_init(_positionNFT, _treasury);

        YieldStorageLib.setLadle(_ladle);
        emit LadleSet(_ladle);

        ICauldron cauldron = _ladle.cauldron();
        YieldStorageLib.setCauldron(cauldron);
        emit CauldronSet(cauldron);
    }

    // ============================================== Trading functions ==============================================

    /// @inheritdoc IContango
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        whenNotClosingOnly(quantity.toInt256())
        returns (PositionId)
    {
        return
            Yield.createPosition(symbol, trader, quantity, limitCost, collateral, payer, lendingLiquidity, uniswapFee);
    }

    /// @inheritdoc IContango
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable override nonReentrant whenNotPaused {
        Yield.modifyCollateral(positionId, collateral, slippageTolerance, payerOrReceiver, lendingLiquidity);
    }

    /// @inheritdoc IContango
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external payable override nonReentrant whenNotPaused whenNotClosingOnly(quantity) {
        Yield.modifyPosition(positionId, quantity, limitCost, collateral, payerOrReceiver, lendingLiquidity, uniswapFee);
    }

    /// @inheritdoc IContango
    function deliver(PositionId positionId, address payer, address to)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        Yield.deliver(positionId, payer, to);
    }

    // ============================================== Callback functions ==============================================

    // solhint-disable-next-line no-empty-blocks
    function auctionStarted(bytes12 vaultId) external override {}

    function collateralBought(bytes12 vaultId, address, uint256 ink, uint256 art)
        external
        override
        nonReentrant
        onlyRole(WITCH)
    {
        Yield.collateralBought(vaultId, ink, art);
    }

    // solhint-disable-next-line no-empty-blocks
    function auctionEnded(bytes12 vaultId, address owner) external override {}

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        Yield.uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    // ============================================== Yield specific functions ==============================================

    function createYieldInstrumentV2(Symbol _symbol, bytes6 _baseId, bytes6 _quoteId, IFeeModel _feeModel)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (YieldInstrument memory instrument)
    {
        ICauldron cauldron = YieldStorageLib.getCauldron();
        (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries) =
            _validInstrumentData(cauldron, _symbol, _baseId, _quoteId);

        IContangoLadle ladle = YieldStorageLib.getLadle();

        (InstrumentStorage memory instrumentStorage, YieldInstrumentStorage memory yieldInstrumentStorage) =
            _createInstrument(ladle, cauldron, _baseId, _quoteId, baseSeries, quoteSeries);

        YieldStorageLib.getJoins()[yieldInstrumentStorage.baseId] = address(ladle.joins(yieldInstrumentStorage.baseId));
        YieldStorageLib.getJoins()[yieldInstrumentStorage.quoteId] =
            address(ladle.joins(yieldInstrumentStorage.quoteId));

        StorageLib.getInstruments()[_symbol] = instrumentStorage;
        YieldStorageLib.getInstruments()[_symbol] = yieldInstrumentStorage;

        instrument = _yieldInstrument(instrumentStorage, yieldInstrumentStorage);
        emitInstrumentCreatedEvent(_symbol, instrument);
        _setFeeModel(_symbol, _feeModel);
    }

    function _yieldInstrument(
        InstrumentStorage memory instrumentStorage,
        YieldInstrumentStorage memory yieldInstrumentStorage
    ) private pure returns (YieldInstrument memory) {
        return YieldInstrument({
            maturity: instrumentStorage.maturity,
            closingOnly: instrumentStorage.closingOnly,
            base: instrumentStorage.base,
            baseId: yieldInstrumentStorage.baseId,
            baseFyToken: yieldInstrumentStorage.baseFyToken,
            basePool: yieldInstrumentStorage.basePool,
            quote: instrumentStorage.quote,
            quoteId: yieldInstrumentStorage.quoteId,
            quoteFyToken: yieldInstrumentStorage.quoteFyToken,
            quotePool: yieldInstrumentStorage.quotePool,
            minQuoteDebt: yieldInstrumentStorage.minQuoteDebt
        });
    }

    function emitInstrumentCreatedEvent(Symbol symbol, YieldInstrument memory instrument) private {
        emit YieldInstrumentCreatedV2({
            symbol: symbol,
            maturity: instrument.maturity,
            baseId: instrument.baseId,
            base: instrument.base,
            baseFyToken: instrument.baseFyToken,
            quoteId: instrument.quoteId,
            quote: instrument.quote,
            quoteFyToken: instrument.quoteFyToken,
            basePool: instrument.basePool,
            quotePool: instrument.quotePool
        });
    }

    function _createInstrument(
        IContangoLadle ladle,
        ICauldron cauldron,
        bytes6 baseId,
        bytes6 quoteId,
        DataTypes.Series memory baseSeries,
        DataTypes.Series memory quoteSeries
    ) private view returns (InstrumentStorage memory instrument_, YieldInstrumentStorage memory yieldInstrument_) {
        yieldInstrument_.baseId = baseId;
        yieldInstrument_.quoteId = quoteId;

        yieldInstrument_.basePool = IPool(ladle.pools(yieldInstrument_.baseId));
        yieldInstrument_.quotePool = IPool(ladle.pools(yieldInstrument_.quoteId));

        yieldInstrument_.baseFyToken = baseSeries.fyToken;
        yieldInstrument_.quoteFyToken = quoteSeries.fyToken;

        DataTypes.Debt memory debt = cauldron.debt(quoteSeries.baseId, yieldInstrument_.baseId);
        yieldInstrument_.minQuoteDebt = debt.min * uint96(10) ** debt.dec;

        instrument_.maturity = baseSeries.maturity;
        instrument_.base = ERC20(yieldInstrument_.baseFyToken.underlying());
        instrument_.quote = ERC20(yieldInstrument_.quoteFyToken.underlying());
    }

    function _validInstrumentData(ICauldron cauldron, Symbol symbol, bytes6 baseId, bytes6 quoteId)
        private
        view
        returns (DataTypes.Series memory baseSeries, DataTypes.Series memory quoteSeries)
    {
        if (StorageLib.getInstruments()[symbol].maturity != 0) {
            revert InstrumentAlreadyExists(symbol);
        }

        baseSeries = cauldron.series(baseId);
        uint256 baseMaturity = baseSeries.maturity;
        if (baseMaturity == 0 || baseMaturity > type(uint32).max) {
            revert InvalidBaseId(symbol, baseId);
        }

        quoteSeries = cauldron.series(quoteId);
        uint256 quoteMaturity = quoteSeries.maturity;
        if (quoteMaturity == 0 || quoteMaturity > type(uint32).max) {
            revert InvalidQuoteId(symbol, quoteId);
        }

        if (baseMaturity != quoteMaturity) {
            revert MismatchedMaturity(symbol, baseId, baseMaturity, quoteId, quoteMaturity);
        }
    }

    function yieldInstrumentV2(Symbol symbol) external view override returns (YieldInstrument memory) {
        (InstrumentStorage memory instrumentStorage, YieldInstrumentStorage memory yieldInstrumentStorage) =
            symbol.loadInstrument();
        return _yieldInstrument(instrumentStorage, yieldInstrumentStorage);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IQuoter} from "lib/v3-periphery/contracts/interfaces/IQuoter.sol";
import {DataTypes} from "lib/vault-v2/src/interfaces/DataTypes.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";

import "../../libraries/CodecLib.sol";
import "../../ContangoPositionNFT.sol";
import "../../interfaces/IContangoQuoter.sol";
import "../../libraries/QuoterDataTypes.sol";
import "../../libraries/Errors.sol";
import "../../libraries/QuoterLib.sol";
import "./YieldUtils.sol";
import "./YieldQuoterUtils.sol";
import "./interfaces/IContangoYield.sol";

/// @title Contract for quoting position operations
contract ContangoYieldQuoter is IContangoQuoter {
    using SafeCast for uint256;
    using SafeCast for int256;
    using SignedMath for int256;
    using CodecLib for uint256;
    using QuoterLib for IQuoter;
    using YieldUtils for *;
    using YieldQuoterUtils for *;

    ContangoPositionNFT public immutable positionNFT;
    IContangoYield public immutable contangoYield;
    ICauldron public immutable cauldron;
    IQuoter public immutable quoter;
    int256 private collateralSlippage;
    uint128 private maxAvailableDebt;

    constructor(ContangoPositionNFT _positionNFT, IContangoYield _contangoYield, ICauldron _cauldron, IQuoter _quoter) {
        positionNFT = _positionNFT;
        contangoYield = _contangoYield;
        cauldron = _cauldron;
        quoter = _quoter;
    }

    /// @inheritdoc IContangoQuoter
    function positionStatus(PositionId positionId, uint24 uniswapFee)
        external
        override
        returns (PositionStatus memory result)
    {
        (, YieldInstrument memory instrument) = _validatePosition(positionId);
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        result = _positionStatus(balances, instrument, uniswapFee);

        result.liquidating = cauldron.vaults(positionId.toVaultId()).owner != address(contangoYield);
    }

    /// @inheritdoc IContangoQuoter
    function modifyCostForPositionWithCollateral(ModifyCostParams calldata params, int256 collateral)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _modifyCostForPosition(params, collateral, 0);
    }

    /// @inheritdoc IContangoQuoter
    function modifyCostForPositionWithLeverage(ModifyCostParams calldata params, uint256 leverage)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _modifyCostForPosition(params, 0, leverage);
    }

    /// @inheritdoc IContangoQuoter
    function openingCostForPositionWithCollateral(OpeningCostParams calldata params, uint256 collateral)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _openingCostForPosition(params, collateral, 0);
    }

    /// @inheritdoc IContangoQuoter
    function openingCostForPositionWithLeverage(OpeningCostParams calldata params, uint256 leverage)
        external
        override
        returns (ModifyCostResult memory result)
    {
        result = _openingCostForPosition(params, 0, leverage);
    }

    /// @inheritdoc IContangoQuoter
    function deliveryCostForPosition(PositionId positionId) external override returns (uint256) {
        (Position memory position, YieldInstrument memory instrument) = _validateExpiredPosition(positionId);
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        return _deliveryCostForPosition(positionId, balances, instrument, position);
    }

    // ============================================== private functions ==============================================

    function _openingCostForPosition(OpeningCostParams calldata params, uint256 collateral, uint256 leverage)
        private
        returns (ModifyCostResult memory result)
    {
        YieldInstrument memory instrument = _instrument(params.symbol);

        _checkClosingOnly(params.symbol, instrument);

        result = _modifyCostForLongPosition(
            PositionId.wrap(0),
            DataTypes.Balances({art: 0, ink: 0}),
            instrument,
            int256(params.quantity),
            int256(collateral),
            params.collateralSlippage,
            leverage,
            params.uniswapFee
        );

        result.fee = QuoterLib.fee(contangoYield, positionNFT, PositionId.wrap(0), params.symbol, result.cost.abs());
    }

    function _modifyCostForPosition(ModifyCostParams calldata params, int256 collateral, uint256 leverage)
        private
        returns (ModifyCostResult memory result)
    {
        (Position memory position, YieldInstrument memory instrument) = _validateActivePosition(params.positionId);
        DataTypes.Balances memory balances = cauldron.balances(params.positionId.toVaultId());

        if (params.quantity > 0) {
            _checkClosingOnly(position.symbol, instrument);
        }

        result = _modifyCostForLongPosition(
            params.positionId,
            balances,
            instrument,
            params.quantity,
            collateral,
            params.collateralSlippage,
            leverage,
            params.uniswapFee
        );
        if (result.needsBatchedCall || params.quantity == 0) {
            uint256 aggregateCost = (result.cost + result.financingCost).abs() + result.debtDelta.abs();
            result.fee = QuoterLib.fee(contangoYield, positionNFT, params.positionId, position.symbol, aggregateCost);
        } else {
            result.fee =
                QuoterLib.fee(contangoYield, positionNFT, params.positionId, position.symbol, result.cost.abs());
        }
    }

    function _checkClosingOnly(Symbol symbol, YieldInstrument memory instrument) private view {
        if (contangoYield.closingOnly()) {
            revert ClosingOnly();
        }
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }
    }

    function _positionStatus(DataTypes.Balances memory balances, YieldInstrument memory instrument, uint24 uniswapFee)
        internal
        returns (PositionStatus memory result)
    {
        result.spotCost =
            quoter.spot(address(instrument.base), address(instrument.quote), int128(balances.ink), uniswapFee);
        result.underlyingDebt = balances.art;

        DataTypes.Series memory series = cauldron.series(instrument.quoteId);
        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, instrument.baseId);

        (result.underlyingCollateral,) = spotOracle.oracle.get(instrument.baseId, series.baseId, balances.ink);
        result.liquidationRatio = uint256(spotOracle.ratio);
    }

    function _modifyCostForLongPosition(
        PositionId positionId,
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        int256 quantity,
        int256 collateral,
        uint256 _collateralSlippage,
        uint256 leverage,
        uint24 uniswapFee
    ) internal returns (ModifyCostResult memory result) {
        collateralSlippage = 1e18 + int256(_collateralSlippage);
        result.minDebt = instrument.minQuoteDebt;
        DataTypes.Series memory series = cauldron.series(instrument.quoteId);
        DataTypes.Debt memory debt = cauldron.debt(series.baseId, instrument.baseId);
        maxAvailableDebt = uint128(debt.max * (10 ** debt.dec)) - debt.sum;

        if (quantity >= 0) {
            // If we're opening a new position
            if (
                balances.art == 0
                    && Math.min(instrument.quotePool.maxFYTokenIn.cap(), maxAvailableDebt) < result.minDebt
            ) revert InsufficientLiquidity();

            _increasingCostForLongPosition(
                result, balances, series, instrument, quantity.toUint256(), collateral, leverage, uniswapFee
            );
        } else {
            _closingCostForLongPosition(
                positionId, result, balances, series, instrument, quantity.abs(), collateral, leverage, uniswapFee
            );
        }

        _assignLiquidity(instrument, balances, result, quantity, result.collateralUsed);
    }

    // **** NEW **** //
    function _increasingCostForLongPosition(
        ModifyCostResult memory result,
        DataTypes.Balances memory balances,
        DataTypes.Series memory series,
        YieldInstrument memory instrument,
        uint256 quantity,
        int256 collateral,
        uint256 leverage,
        uint24 uniswapFee
    ) private {
        uint256 hedge;
        int256 quoteQty;

        if (quantity > 0) {
            hedge = instrument.basePool.buyFYTokenPreview.orMint(quantity.toUint128());
            quoteQty =
                -int256(quoter.spot(address(instrument.base), address(instrument.quote), -int256(hedge), uniswapFee));
            result.spotCost =
                -int256(quoter.spot(address(instrument.base), address(instrument.quote), -int256(quantity), uniswapFee));
        }

        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, instrument.baseId);
        (result.underlyingCollateral,) =
            spotOracle.oracle.get(instrument.baseId, series.baseId, balances.ink + quantity); // ink * spot
        result.liquidationRatio = uint256(spotOracle.ratio);

        _calculateMinCollateral(balances, instrument, result, quoteQty);
        _calculateMaxCollateral(balances, instrument, result, quoteQty);
        _assignCollateralUsed(instrument, balances, result, collateral, leverage, quoteQty);
        _calculateCost(balances, instrument, result, quoteQty);
    }

    /// @notice Quotes the bid rate, the base/quote are derived from the positionId
    // **** NEW **** //
    function _closingCostForLongPosition(
        PositionId positionId,
        ModifyCostResult memory result,
        DataTypes.Balances memory balances,
        DataTypes.Series memory series,
        YieldInstrument memory instrument,
        uint256 quantity,
        int256 collateral,
        uint256 leverage,
        uint24 uniswapFee
    ) private {
        if (instrument.basePool.maxFYTokenIn.cap() < cauldron.minLiquidityToCloseLendingPosition(positionId, quantity))
        {
            revert InsufficientLiquidity();
        }

        uint256 amountRealBaseReceivedFromSellingLendingPosition =
            cauldron.closeLendingPositionPreview(instrument.basePool, positionId, quantity);

        result.spotCost =
            int256(quoter.spot(address(instrument.base), address(instrument.quote), int256(quantity), uniswapFee));
        int256 hedgeCost = int256(
            quoter.spot(
                address(instrument.base),
                address(instrument.quote),
                int256(amountRealBaseReceivedFromSellingLendingPosition),
                uniswapFee
            )
        );

        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, instrument.baseId);
        result.liquidationRatio = uint256(spotOracle.ratio);

        if (balances.ink == quantity) {
            uint256 costRecovered;
            if (balances.art != 0) {
                costRecovered = balances.art - instrument.quotePool.buyFYTokenPreview.orMint(balances.art);
            }
            result.cost = hedgeCost + int256(costRecovered);
        } else {
            (result.underlyingCollateral,) =
                spotOracle.oracle.get(instrument.baseId, series.baseId, balances.ink - quantity);
            _calculateMinCollateral(balances, instrument, result, hedgeCost);
            _calculateMaxCollateral(balances, instrument, result, hedgeCost);
            _assignCollateralUsed(instrument, balances, result, collateral, leverage, hedgeCost);
            _calculateCost(balances, instrument, result, hedgeCost);
        }
    }

    function _calculateMinCollateral(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost
    ) private view {
        uint128 maxDebtAfterModify = ((result.underlyingCollateral * 1e6) / result.liquidationRatio).toUint128();

        if (balances.art < maxDebtAfterModify) {
            uint128 diff = maxDebtAfterModify - balances.art;
            uint128 maxBorrowableAmount = uint128(Math.min(instrument.quotePool.maxFYTokenIn.cap(), maxAvailableDebt));
            uint256 refinancingRoomPV =
                instrument.quotePool.sellFYTokenPreview(diff > maxBorrowableAmount ? maxBorrowableAmount : diff);
            result.minCollateral -= spotCost + int256(refinancingRoomPV);
        }

        if (balances.art > maxDebtAfterModify) {
            uint128 diff = balances.art - maxDebtAfterModify;
            uint256 minDebtThatHasToBeBurnedPV = instrument.quotePool.buyFYTokenPreview.orMint(diff);

            result.minCollateral = int256(minDebtThatHasToBeBurnedPV) - spotCost;
        }

        if (collateralSlippage != 1e18) {
            result.minCollateral = result.minCollateral > 0
                ? SignedMath.min((result.minCollateral * collateralSlippage) / 1e18, -spotCost)
                : (result.minCollateral * 1e18) / collateralSlippage;
        }
    }

    function _calculateMaxCollateral(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost
    ) private view {
        // this covers the case where there is no existing debt, which applies to new positions or fully liquidated positions
        if (balances.art == 0) {
            uint256 minDebtPV = instrument.quotePool.sellFYTokenPreview(result.minDebt);
            result.maxCollateral = int256(spotCost.abs()) - int256(minDebtPV);
        } else {
            uint128 maxDebtThatCanBeBurned = balances.art - result.minDebt;
            uint256 maxDebtThatCanBeBurnedPV = instrument.quotePool.buyFYTokenPreview.orMint(maxDebtThatCanBeBurned);
            result.maxCollateral = int256(maxDebtThatCanBeBurnedPV) - spotCost;
        }

        if (collateralSlippage != 1e18) {
            result.maxCollateral = result.maxCollateral < 0
                ? (result.maxCollateral * collateralSlippage) / 1e18
                : (result.maxCollateral * 1e18) / collateralSlippage;
        }
    }

    // NEEDS BATCHED CALL
    // * decrease and withdraw more than we get from spot
    // * decrease and post at the same time SUPPORTED
    // * increase and withdraw at the same time ???
    // * increase and post more than what we need to pay the spot

    function _calculateCost(
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        ModifyCostResult memory result,
        int256 spotCost
    ) private view {
        int256 quoteUsedToRepayDebt = result.collateralUsed + spotCost;
        result.underlyingDebt = balances.art;
        uint128 debtDelta128;

        if (quoteUsedToRepayDebt > 0) {
            debtDelta128 = instrument.quotePool.sellBasePreview.orMint(uint128(uint256(quoteUsedToRepayDebt)));
            result.debtDelta = -int128(debtDelta128);
            result.underlyingDebt -= debtDelta128;
            if (spotCost < 0) {
                // this means we're increasing, and posting more than what we need to pay the spot
                result.needsBatchedCall = true;
            }
        }
        if (quoteUsedToRepayDebt < 0) {
            debtDelta128 = instrument.quotePool.buyBasePreview(quoteUsedToRepayDebt.abs().toUint128());
            result.debtDelta = int128(debtDelta128);
            result.underlyingDebt += debtDelta128;
            if (spotCost > 0) {
                // this means that we're decreasing, and withdrawing more than we get from the spot
                result.needsBatchedCall = true;
            }
        }
        result.financingCost = result.debtDelta + quoteUsedToRepayDebt;
        result.cost -= result.collateralUsed + result.debtDelta;
    }

    function _assignLiquidity(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        ModifyCostResult memory result,
        int256 quantity,
        int256 collateral
    ) private view {
        // Opening / Increasing
        if (quantity > 0) {
            result.baseLendingLiquidity = instrument.basePool.maxFYTokenOut.cap();
        }

        // Add collateral
        if (balances.art != 0 && collateral > 0) {
            result.quoteLendingLiquidity = instrument.quotePool.maxBaseIn.cap();
        }

        // Decrease position
        if (quantity < 0) {
            result.quoteLendingLiquidity = instrument.quotePool.maxBaseIn.cap();
        }

        // Close position
        if (quantity == -int128(balances.ink)) {
            result.quoteLendingLiquidity = instrument.quotePool.maxFYTokenOut.cap();
        }
    }

    function _assignCollateralUsed(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        ModifyCostResult memory result,
        int256 collateral,
        uint256 leverage,
        int256 hedgeCost
    ) private view {
        collateral =
            leverage > 0 ? _deriveCollateralFromLeverage(instrument, balances, result, leverage, hedgeCost) : collateral;

        // if 'collateral' is above the max, use result.maxCollateral
        result.collateralUsed = SignedMath.min(collateral, result.maxCollateral);
        // if result.collateralUsed is lower than max, but still lower than the min, use the min
        result.collateralUsed = SignedMath.max(result.minCollateral, result.collateralUsed);
    }

    // leverage = 1 / ((underlyingCollateral - underlyingDebt) / underlyingCollateral)
    // leverage = underlyingCollateral / (underlyingCollateral - underlyingDebt)
    // underlyingDebt = -underlyingCollateral / leverage + underlyingCollateral
    // collateral = hedgeCost - underlyingDebtPV
    function _deriveCollateralFromLeverage(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        ModifyCostResult memory result,
        uint256 leverage,
        int256 hedgeCost
    ) internal view returns (int256 collateral) {
        uint256 debtFV = (
            ((-int256(result.underlyingCollateral) * 1e18) / int256(leverage)) + int256(result.underlyingCollateral)
        ).toUint256();

        int256 debtPV;

        if (debtFV > balances.art) {
            // Debt can grow bigger than the available liquidity
            debtFV = Math.min(debtFV, instrument.quotePool.maxFYTokenIn.cap());

            // Debt needs to increase to reach the desired leverage
            debtPV = -int128(instrument.quotePool.sellFYTokenPreview(debtFV.toUint128() - balances.art));
        } else {
            // Debt needs to be burnt to reach the desired leverage
            debtPV = int128(instrument.quotePool.buyFYTokenPreview.orMint(balances.art - debtFV.toUint128()));
        }

        collateral = debtPV - hedgeCost;
    }

    function _deliveryCostForPosition(
        PositionId positionId,
        DataTypes.Balances memory balances,
        YieldInstrument memory instrument,
        Position memory position
    ) internal returns (uint256 deliveryCost) {
        deliveryCost = cauldron.debtToBase(instrument.quoteId, balances.art);
        uint256 deliveryFee = QuoterLib.fee(contangoYield, positionNFT, positionId, position.symbol, deliveryCost);

        deliveryCost += position.protocolFees + deliveryFee;
    }

    function _validatePosition(PositionId positionId)
        private
        view
        returns (Position memory position, YieldInstrument memory instrument)
    {
        position = contangoYield.position(positionId);
        if (position.openQuantity == 0 && position.openCost == 0) {
            if (position.collateral <= 0) {
                revert InvalidPosition(positionId);
            }
        }
        instrument = _instrument(position.symbol);
    }

    function _validateActivePosition(PositionId positionId)
        private
        view
        returns (Position memory position, YieldInstrument memory instrument)
    {
        (position, instrument) = _validatePosition(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrument.maturity, timestamp);
        }
    }

    function _validateExpiredPosition(PositionId positionId)
        private
        view
        returns (Position memory position, YieldInstrument memory instrument)
    {
        (position, instrument) = _validatePosition(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrument.maturity, timestamp);
        }
    }

    function _instrument(Symbol symbol) private view returns (YieldInstrument memory) {
        return contangoYield.yieldInstrumentV2(symbol);
    }

    receive() external payable {
        revert ViewOnly();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../interfaces/IContango.sol";

interface IContangoYield is IContango {
    function yieldInstrumentV2(Symbol symbol) external view returns (YieldInstrument memory instrument);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DataTypes} from "lib/vault-v2/src/interfaces/DataTypes.sol";
import {IContangoLadle} from "lib/vault-v2/src/other/contango/interfaces/IContangoLadle.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";

import "../../../libraries/DataTypes.sol";

interface IContangoYieldAdminEvents {
    event YieldInstrumentCreatedV2(
        Symbol symbol,
        uint32 maturity,
        bytes6 baseId,
        ERC20 base,
        IFYToken baseFyToken,
        IPool basePool,
        bytes6 quoteId,
        ERC20 quote,
        IFYToken quoteFyToken,
        IPool quotePool
    );
    event LadleSet(IContangoLadle ladle);
    event CauldronSet(ICauldron cauldron);
}

interface IContangoYieldAdmin is IContangoYieldAdminEvents {
    error InvalidBaseId(Symbol symbol, bytes6 baseId);
    error InvalidQuoteId(Symbol symbol, bytes6 quoteId);
    error MismatchedMaturity(Symbol symbol, bytes6 baseId, uint256 baseMaturity, bytes6 quoteId, uint256 quoteMaturity);

    function createYieldInstrumentV2(Symbol symbol, bytes6 baseId, bytes6 quoteId, IFeeModel feeModel)
        external
        returns (YieldInstrument memory instrument);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IPool} from "lib/yieldspace-tv/src/interfaces/IPool.sol";
import {ILadle} from "lib/vault-v2/src/interfaces/ILadle.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";
import {IFYToken} from "lib/vault-v2/src/interfaces/IFYToken.sol";
import {DataTypes} from "lib/vault-v2/src/interfaces/DataTypes.sol";
import {IContangoLadle} from "lib/vault-v2/src/other/contango/interfaces/IContangoLadle.sol";

import "../UniswapV3Handler.sol";
import "./YieldUtils.sol";
import "../SlippageLib.sol";
import "../../libraries/PositionLib.sol";
import "../../libraries/Errors.sol";
import "../../ExecutionProcessorLib.sol";

library Yield {
    using YieldUtils for *;
    using SignedMath for int256;
    using SafeCast for *;
    using CodecLib for uint256;
    using PositionLib for PositionId;
    using TransferLib for ERC20;

    /// @dev IMPORTANT - make sure the events here are the same as in IContangoEvents
    /// this is needed because we're in a library and can't re-use events from an interface

    event ContractBought(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );
    event ContractSold(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 size,
        uint256 cost,
        uint256 hedgeSize,
        uint256 hedgeCost,
        int256 collateral
    );

    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );

    uint128 public constant BORROWING_BUFFER = 5;

    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external returns (PositionId positionId) {
        if (quantity == 0) {
            revert InvalidQuantity(int256(quantity));
        }

        positionId = ConfigStorageLib.getPositionNFT().mint(trader);
        positionId.validatePayer(payer, trader);

        StorageLib.getPositionInstrument()[positionId] = symbol;
        InstrumentStorage memory instrument = _createPosition(symbol, positionId);

        _open(
            symbol,
            positionId,
            trader,
            instrument,
            quantity,
            limitCost,
            collateral.toInt256(),
            payer,
            lendingLiquidity,
            uniswapFee
        );
    }

    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external {
        if (quantity == 0) {
            revert InvalidQuantity(quantity);
        }

        (uint256 openQuantity, address trader, Symbol symbol, InstrumentStorage memory instrument) =
            positionId.loadActivePosition();
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
        }

        if (quantity < 0 && uint256(-quantity) > openQuantity) {
            revert InvalidPositionDecrease(positionId, quantity, openQuantity);
        }

        if (quantity > 0) {
            _open(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity,
                uniswapFee
            );
        } else {
            _close(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(-quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity,
                uniswapFee
            );

            if (uint256(-quantity) == openQuantity) {
                _deletePosition(positionId);
            }
        }
    }

    function collateralBought(bytes12 vaultId, uint256 ink, uint256 art) external {
        PositionId positionId = PositionId.wrap(uint96(vaultId));
        ExecutionProcessorLib.liquidatePosition(
            StorageLib.getPositionInstrument()[positionId],
            positionId,
            ConfigStorageLib.getPositionNFT().positionOwner(positionId),
            ink,
            art
        );
    }

    function _createPosition(Symbol symbol, PositionId positionId)
        private
        returns (InstrumentStorage memory instrument)
    {
        YieldInstrumentStorage storage yieldInsturment;
        (instrument, yieldInsturment) = symbol.loadInstrument();

        // solhint-disable-next-line not-rely-on-time
        if (instrument.maturity < block.timestamp) {
            // solhint-disable-next-line not-rely-on-time
            revert InstrumentExpired(symbol, instrument.maturity, block.timestamp);
        }

        YieldStorageLib.getLadle().deterministicBuild(
            positionId.toVaultId(), yieldInsturment.quoteId, yieldInsturment.baseId
        );
    }

    function _deletePosition(PositionId positionId) private {
        positionId.deletePosition();
        YieldStorageLib.getLadle().destroy(positionId.toVaultId());
    }

    function _open(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) private {
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }

        UniswapV3Handler.CallbackInfo memory callbackInfo = UniswapV3Handler.CallbackInfo({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            limitCost: limitCost,
            payerOrReceiver: payerOrReceiver,
            open: true,
            lendingLiquidity: lendingLiquidity,
            uniswapFee: uniswapFee
        });

        IPool basePool = YieldStorageLib.getInstruments()[symbol].basePool;
        address receiver = lendingLiquidity < quantity ? address(this) : address(basePool);

        // Use a flash swap to buy enough base to hedge the position, pay directly to the pool where we'll lend it
        _flashBuyHedge(instrument, basePool, callbackInfo, quantity, collateral, receiver);
    }

    /// @dev Second step of trading, this executes on the back of the flash swap callback,
    /// it will pay part of the swap by using the trader collateral,
    /// then will borrow the rest from the lending protocol. Fill cost == swap cost + loan interest.
    /// @param callback Info collected before the flash swap started
    function completeOpen(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrumentStorage storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];

        uint128 ink = callback.fill.size.toUint128();

        // Lend the base we just flash bought
        _openLendingPosition(yieldInstrument, callback, ink);

        // Use the payer collateral (if any) to pay part/all of the flash swap
        if (callback.fill.collateral > 0) {
            // Trader can contribute up to the spot cost
            callback.fill.collateral = SignedMath.min(callback.fill.collateral, callback.fill.hedgeCost.toInt256());
            callback.instrument.quote.transferOut(
                callback.info.payerOrReceiver, msg.sender, uint256(callback.fill.collateral)
            );
        }

        uint128 amountToBorrow = (callback.fill.hedgeCost.toInt256() - callback.fill.collateral).toUint256().toUint128();
        uint128 art;

        // If the collateral wasn't enough to cover the whole trade
        if (amountToBorrow != 0) {
            // Math is not exact anymore with the PoolEuler, so we need to borrow a bit more
            amountToBorrow += BORROWING_BUFFER;
            // How much debt at future value (art) do I need to take on in order to get enough cash at present value (remainder)
            art = yieldInstrument.quotePool.buyBasePreview(amountToBorrow);
        }

        // Deposit collateral (ink) and take on debt if necessary (art)
        YieldStorageLib.getLadle().pour(
            callback.info.positionId.toVaultId(), // Vault that will issue the debt & store the collateral
            address(yieldInstrument.quotePool), // If taking any debt, send it to the pool so it can be sold
            ink.toInt256().toInt128(), // Use the fyTokens we bought using the flash swap as ink (collateral)
            art.toInt256().toInt128() // Amount to borrow in future value
        );

        address sendBorrowedFundsTo;

        if (callback.fill.collateral < 0) {
            // We need to keep the borrowed funds in this contract so we can pay both the trader and uniswap
            sendBorrowedFundsTo = address(this);
            // Cost is spot + financing costs
            callback.fill.cost = callback.fill.hedgeCost + (art - amountToBorrow);
        } else {
            // We can pay to uniswap directly as it's the only reason we are borrowing for
            sendBorrowedFundsTo = msg.sender;
            // Cost is spot + debt + financing costs
            callback.fill.cost = art + uint256(callback.fill.collateral);
        }

        SlippageLib.requireCostBelowTolerance(callback.fill.cost, callback.info.limitCost);

        if (amountToBorrow != 0) {
            // Sell the fyTokens for actual cash (borrow)
            yieldInstrument.quotePool.buyBase({to: sendBorrowedFundsTo, baseOut: amountToBorrow, max: art});
        }

        // Pay uniswap if necessary
        if (sendBorrowedFundsTo == address(this)) {
            callback.instrument.quote.transferOut(address(this), msg.sender, callback.fill.hedgeCost);
        }

        ExecutionProcessorLib.increasePosition(
            callback.info.symbol,
            callback.info.positionId,
            callback.info.trader,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.collateral,
            callback.instrument.quote,
            callback.info.payerOrReceiver,
            yieldInstrument.minQuoteDebt
        );

        emit ContractBought(
            callback.info.symbol,
            callback.info.trader,
            callback.info.positionId,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.hedgeSize,
            callback.fill.hedgeCost,
            callback.fill.collateral
        );
    }

    function _close(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) private {
        // Execute a flash swap to undo the hedge
        _flashSellHedge(
            instrument,
            YieldStorageLib.getInstruments()[symbol].basePool,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: false,
                lendingLiquidity: lendingLiquidity,
                uniswapFee: uniswapFee
            }),
            quantity,
            collateral,
            address(this) // We must receive the funds ourselves cause the TV pools have a bug & will consume them all otherwise
        );
    }

    /// @dev Second step to reduce/close a position. This executes on the back of the flash swap callback,
    /// then it will repay debt using the proceeds from the flash swap and deal with any excess appropriately.
    /// @param callback Info collected before the flash swap started
    function completeClose(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrumentStorage storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];
        DataTypes.Balances memory balances =
            YieldStorageLib.getCauldron().balances(callback.info.positionId.toVaultId());
        bool fullyClosing = callback.fill.size == balances.ink;
        int128 art;

        // If there's any debt to repay
        if (balances.art != 0) {
            // Use the quote we just bought to buy/mint fyTokens to reduce the debt and free up the amount we owe for the flash loan
            if (fullyClosing) {
                // If we're fully closing, pay all debt
                art = -balances.art.toInt256().toInt128();
                // Buy the exact amount of (fy)Quote we owe (art) using the money from the flash swap (money was sent directly to the quotePool).
                // Send the tokens to the fyToken contract so they can be burnt
                // Cost == swap cost + pnl of cancelling the debt
                uint128 baseIn = _buyFYToken({
                    pool: yieldInstrument.quotePool,
                    underlying: callback.instrument.quote,
                    fyToken: yieldInstrument.quoteFyToken,
                    to: address(yieldInstrument.quoteFyToken),
                    fyTokenOut: balances.art,
                    lendingLiquidity: callback.info.lendingLiquidity,
                    excessExpected: true
                });
                callback.fill.cost = callback.fill.hedgeCost + (balances.art - baseIn);
            } else {
                // Can't withdraw more than what we got from UNI
                if (callback.fill.collateral < 0) {
                    callback.fill.collateral =
                        SignedMath.max(callback.fill.collateral, -int256(callback.fill.hedgeCost));
                }

                int256 quoteUsedToRepayDebt = callback.fill.collateral + int256(callback.fill.hedgeCost);

                if (quoteUsedToRepayDebt > 0) {
                    // If the user is depositing, take the necessary tokens from the payer
                    if (callback.fill.collateral > 0) {
                        callback.instrument.quote.transferOut({
                            payer: callback.info.payerOrReceiver,
                            to: address(this),
                            amount: uint256(callback.fill.collateral)
                        });
                    }

                    // Under normal circumstances, send the required funds to the pool
                    if (uint256(quoteUsedToRepayDebt) < callback.info.lendingLiquidity) {
                        callback.instrument.quote.transferOut({
                            payer: address(this),
                            to: address(yieldInstrument.quotePool),
                            amount: uint256(quoteUsedToRepayDebt)
                        });
                    }

                    // Sell available base tokens for fyTokens to repay debt
                    art = -_sellBaseOrMint({
                        pool: yieldInstrument.quotePool,
                        underlying: callback.instrument.quote,
                        fyToken: yieldInstrument.quoteFyToken,
                        availableBase: uint256(quoteUsedToRepayDebt).toUint128(),
                        lendingLiquidity: callback.info.lendingLiquidity
                    }).toInt256().toInt128();
                }

                callback.fill.cost = (-(callback.fill.collateral + art)).toUint256();
            }
        } else {
            // Given there's no debt, the cost is the hedgeCost
            callback.fill.cost = callback.fill.hedgeCost;
        }

        SlippageLib.requireCostAboveTolerance(callback.fill.cost, callback.info.limitCost);

        // Retrieve real base ccy and pay the flash swap
        _closeLendingPosition(yieldInstrument, callback, art);

        emit ContractSold(
            callback.info.symbol,
            callback.info.trader,
            callback.info.positionId,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.hedgeSize,
            callback.fill.hedgeCost,
            callback.fill.collateral
        );

        if (fullyClosing) {
            ExecutionProcessorLib.closePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.cost,
                callback.instrument.quote,
                callback.info.payerOrReceiver
            );
        } else {
            ExecutionProcessorLib.decreasePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.size,
                callback.fill.cost,
                callback.fill.collateral,
                callback.instrument.quote,
                callback.info.payerOrReceiver,
                yieldInstrument.minQuoteDebt
            );
        }
    }

    // ============== Physical delivery ==============

    function deliver(PositionId positionId, address payer, address to) external {
        address trader = positionId.lookupPositionOwner();
        positionId.validatePayer(payer, trader);

        (, Symbol symbol, InstrumentStorage memory instrument) = positionId.validateExpiredPosition();

        _deliver(symbol, positionId, trader, instrument, payer, to);

        _deletePosition(positionId);
    }

    function _deliver(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        address payer,
        address to
    ) private {
        YieldInstrumentStorage storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IFYToken baseFyToken = yieldInstrument.baseFyToken;
        ILadle ladle = YieldStorageLib.getLadle();
        ICauldron cauldron = YieldStorageLib.getCauldron();
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        uint256 requiredQuote;
        if (balances.art != 0) {
            bytes6 quoteId = yieldInstrument.quoteId;

            // we need to cater for the interest rate accrued after maturity
            requiredQuote = cauldron.debtToBase(quoteId, balances.art);

            // Send the requiredQuote to the Join
            instrument.quote.transferOut(payer, address(ladle.joins(cauldron.series(quoteId).baseId)), requiredQuote);

            ladle.close(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                -int128(balances.art) // repay art
            );
        } else {
            ladle.pour(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                0 // no debt to repay
            );
        }

        ExecutionProcessorLib.deliverPosition(
            symbol,
            positionId,
            trader,
            // Burn fyTokens in exchange for underlying, send underlying to `to`
            baseFyToken.redeem(to, balances.ink),
            requiredQuote,
            payer,
            instrument.quote,
            to
        );
    }

    // ============== Collateral management ==============

    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        // uniswapFee is irrelevant as there'll be no trade on UNI
        (, address trader, Symbol symbol, InstrumentStorage memory instrument) = positionId.loadActivePosition();

        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
            _addCollateral(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(collateral),
                slippageTolerance,
                payerOrReceiver,
                lendingLiquidity
            );
        }
        if (collateral < 0) {
            _removeCollateral(symbol, positionId, trader, uint256(-collateral), slippageTolerance, payerOrReceiver);
        }
    }

    function _addCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        InstrumentStorage memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address payer,
        uint256 lendingLiquidity
    ) private {
        YieldInstrumentStorage storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IPool quotePool = yieldInstrument.quotePool;

        address to = collateral > lendingLiquidity ? address(this) : address(quotePool);
        if (to != payer) {
            // Collect the new collateral from the payer and send wherever's appropriate
            instrument.quote.transferOut({payer: payer, to: to, amount: collateral});
        }

        // Sell the collateral and get as much (fy)Quote (art) as possible
        uint256 art = _sellBaseOrMint({
            pool: quotePool,
            underlying: instrument.quote,
            fyToken: yieldInstrument.quoteFyToken,
            availableBase: collateral.toUint128(),
            lendingLiquidity: lendingLiquidity
        });

        SlippageLib.requireCostAboveTolerance(art, slippageTolerance);

        // Use the (fy)Quote (art) we bought to burn debt on the vault
        YieldStorageLib.getLadle().pour(
            positionId.toVaultId(),
            address(0), // We're not taking new debt, so no need to pass an address
            0, // We're not changing the collateral
            -art.toInt256().toInt128() // We burn all the (fy)Quote we just bought
        );

        // The interest pnl is reflected on the position cost
        int256 cost = -(art - collateral).toInt256();

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, int256(collateral));

        emit CollateralAdded(symbol, trader, positionId, collateral, art);
    }

    function _removeCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 collateral,
        uint256 slippageTolerance,
        address to
    ) private {
        // Borrow whatever the trader wants to withdraw
        uint128 art = YieldStorageLib.getLadle().serve(
            positionId.toVaultId(),
            to, // Send the borrowed funds directly
            0, // We don't deposit any new collateral
            collateral.toUint128(), // Amount to borrow
            type(uint128).max // We don't need slippage control here, we have a general check below
        );

        SlippageLib.requireCostBelowTolerance(art, slippageTolerance);

        // The interest pnl is reflected on the position cost
        int256 cost = (art - collateral).toInt256();

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, -int256(collateral));

        emit CollateralRemoved(symbol, trader, positionId, collateral, art);
    }

    // ============== Uniswap functions ==============

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        UniswapV3Handler.uniswapV3SwapCallback(amount0Delta, amount1Delta, data, _onUniswapCallback);
    }

    function _onUniswapCallback(UniswapV3Handler.Callback memory callback) internal {
        callback.info.open ? completeOpen(callback) : completeClose(callback);
    }

    function _flashBuyHedge(
        InstrumentStorage memory instrument,
        IPool basePool,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.info = callbackInfo;
        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        callback.fill.hedgeSize = _buyFYTokenPreview(basePool, quantity.toUint128(), callbackInfo.lendingLiquidity);

        UniswapV3Handler.flashSwap({callback: callback, instrument: instrument, baseForQuote: false, to: to});
    }

    function _flashSellHedge(
        InstrumentStorage memory instrument,
        IPool basePool,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.info = callbackInfo;
        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        callback.fill.hedgeSize =
            YieldStorageLib.getCauldron().closeLendingPositionPreview(basePool, callback.info.positionId, quantity);

        UniswapV3Handler.flashSwap({callback: callback, instrument: instrument, baseForQuote: true, to: to});
    }

    // ============== Private functions ==============

    function _sellBaseOrMint(
        IPool pool,
        ERC20 underlying,
        IFYToken fyToken,
        uint128 availableBase,
        uint256 lendingLiquidity
    ) private returns (uint128 fyTokenOut) {
        if (availableBase > lendingLiquidity) {
            uint128 maxBaseIn = lendingLiquidity.toUint128();
            fyTokenOut = pool.sellBasePreviewZero(maxBaseIn);
            if (fyTokenOut > 0) {
                // Transfer max amount that can be sold
                underlying.transferOut({payer: address(this), to: address(pool), amount: maxBaseIn});
                // Sell limited amount to the pool
                fyTokenOut = pool.sellBase({to: address(fyToken), min: fyTokenOut});
            } else {
                maxBaseIn = 0;
            }

            fyTokenOut += _forceLend(underlying, fyToken, address(fyToken), availableBase - maxBaseIn);
        } else {
            fyTokenOut = pool.sellBase({to: address(fyToken), min: availableBase});
        }
    }

    function _buyFYTokenPreview(IPool pool, uint128 fyTokenOut, uint256 lendingLiquidity)
        private
        view
        returns (uint128 baseIn)
    {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);
            baseIn = maxFYTokenOut == 0
                ? fyTokenOut
                : fyTokenOut - maxFYTokenOut + pool.buyFYTokenPreviewFixed(maxFYTokenOut);
        } else {
            baseIn = pool.buyFYTokenPreviewFixed(fyTokenOut);
        }
    }

    function _buyFYToken(
        IPool pool,
        ERC20 underlying,
        IFYToken fyToken,
        address to,
        uint128 fyTokenOut,
        uint256 lendingLiquidity,
        bool excessExpected
    ) private returns (uint128 baseIn) {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);

            if (maxFYTokenOut > 0) {
                baseIn = _buyFYToken(pool, underlying, to, maxFYTokenOut);
            }

            baseIn += _forceLend(underlying, fyToken, to, fyTokenOut - maxFYTokenOut);
        } else {
            baseIn = excessExpected
                ? _buyFYToken(pool, underlying, to, fyTokenOut)
                : pool.buyFYToken(to, fyTokenOut, type(uint128).max);
        }
    }

    function _buyFYToken(IPool pool, ERC20 underlying, address to, uint128 fyTokenOut)
        private
        returns (uint128 baseIn)
    {
        baseIn = uint128(underlying.transferOut(address(this), address(pool), pool.buyFYTokenPreviewFixed(fyTokenOut)));
        pool.buyFYToken(to, fyTokenOut, type(uint128).max);
    }

    function _forceLend(ERC20 underlying, IFYToken fyToken, address to, uint128 toMint) internal returns (uint128) {
        underlying.transferOut(address(this), address(fyToken.join()), toMint);
        fyToken.mintWithUnderlying(to, toMint);
        return toMint;
    }

    function _openLendingPosition(
        YieldInstrumentStorage storage yieldInstrument,
        UniswapV3Handler.Callback memory callback,
        uint128 fyTokenOut
    ) internal {
        address to = YieldStorageLib.getJoins()[yieldInstrument.baseId];
        if (fyTokenOut > callback.info.lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(callback.info.lendingLiquidity);

            if (maxFYTokenOut > 0) {
                _buyFYToken(yieldInstrument.basePool, callback.instrument.base, to, maxFYTokenOut);
            }

            _wrapBaseInFYTokens(yieldInstrument, callback, fyTokenOut - maxFYTokenOut, to);
        } else {
            yieldInstrument.basePool.buyFYToken({
                to: to, // send the (fy)Base to the join so it can be used as collateral for borrowing
                fyTokenOut: fyTokenOut,
                max: type(uint128).max
            });
        }
    }

    function _wrapBaseInFYTokens(
        YieldInstrumentStorage storage yieldInstrument,
        UniswapV3Handler.Callback memory callback,
        uint128 toWrap,
        address to
    ) internal {
        IContangoLadle ladle = YieldStorageLib.getLadle();
        ICauldron cauldron = YieldStorageLib.getCauldron();
        bytes12 baseVaultId = callback.info.positionId.toBaseVaultId();
        DataTypes.Vault memory baseVault = cauldron.vaults(baseVaultId);
        if (baseVault.owner == address(0)) {
            baseVault = ladle.deterministicBuild(
                baseVaultId, yieldInstrument.baseId, cauldron.series(yieldInstrument.baseId).baseId
            );
        }
        callback.instrument.base.transferOut(address(this), address(yieldInstrument.baseFyToken.join()), toWrap);
        ladle.pour(baseVaultId, to, int128(toWrap), int128(toWrap));
    }

    function _closeLendingPosition(
        YieldInstrumentStorage storage yieldInstrument,
        UniswapV3Handler.Callback memory callback,
        int128 art
    ) internal {
        uint128 amountToRepay = uint128(callback.fill.hedgeSize);

        IContangoLadle ladle = YieldStorageLib.getLadle();
        bytes12 baseVaultId = callback.info.positionId.toBaseVaultId();
        uint256 wrappedBase = YieldStorageLib.getCauldron().balances(baseVaultId).ink;

        // Burn debt and withdraw collateral from Yield, send the collateral directly to the basePool so it can be sold, or to this contract if we can uwrap it
        ladle.pour({
            vaultId_: callback.info.positionId.toVaultId(),
            to: wrappedBase > 0 ? address(this) : address(yieldInstrument.basePool),
            ink: -int256(callback.fill.size).toInt128(),
            art: art
        });

        if (wrappedBase > 0) {
            uint128 amountToUnwrap = uint128(Math.min(amountToRepay, wrappedBase));
            ERC20(address(yieldInstrument.baseFyToken)).transferOut(
                address(this), address(yieldInstrument.baseFyToken), amountToUnwrap
            );
            ladle.pour(baseVaultId, msg.sender, -int128(amountToUnwrap), -int128(amountToUnwrap));

            amountToRepay = uint128(callback.fill.size) - amountToUnwrap;
            ERC20(address(yieldInstrument.baseFyToken)).transferOut(
                address(this), address(yieldInstrument.basePool), amountToRepay
            );
        }

        // Sell collateral (ink) to pay for the flash swap, the amount of ink was pre-calculated to obtain the exact cost of the swap
        if (amountToRepay > 0) {
            yieldInstrument.basePool.sellFYToken(msg.sender, 0);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";
import {IPool} from "lib/yieldspace-tv/src/interfaces/IPool.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "../../libraries/Errors.sol";
import "../../libraries/DataTypes.sol";
import "./YieldUtils.sol";

library YieldQuoterUtils {
    using YieldUtils for *;
    using FixedPointMathLib for *;

    uint256 private constant SCALE_FACTOR_FOR_18_DECIMALS = 1;
    uint256 private constant SCALE_FACTOR_FOR_6_DECIMALS = 1e12;

    uint256 private constant LIQ_PRECISION_LIMIT_FOR_18_DECIMALS = 1e13;
    uint256 private constant LIQ_PRECISION_LIMIT_FOR_6_DECIMALS = 1e3;

    function liquidityHaircut(uint256 liquidity) internal pure returns (uint128) {
        // Using 95% of the liquidity to avoid reverts
        return uint128(liquidity.mulWadDown(0.95e18));
    }

    /// @dev Ignores liquidity values that are too small to be useful
    function cap(function() view external returns (uint128) f) internal view returns (uint128) {
        uint128 liquidity = liquidityHaircut(f());

        if (liquidity > 0) {
            IPool pool = IPool(f.address);
            uint256 scaleFactor = pool.scaleFactor();
            if (
                scaleFactor == SCALE_FACTOR_FOR_18_DECIMALS && liquidity <= LIQ_PRECISION_LIMIT_FOR_18_DECIMALS
                    || scaleFactor == SCALE_FACTOR_FOR_6_DECIMALS && liquidity <= LIQ_PRECISION_LIMIT_FOR_6_DECIMALS
            ) {
                liquidity = 0;
            } else if (f.selector == IPool.maxFYTokenOut.selector) {
                uint128 balance = uint128(pool.fyToken().balanceOf(f.address));
                if (balance < liquidity) {
                    liquidity = balance;
                }
            }
        }

        return liquidity;
    }

    function orMint(function(uint128) external view returns (uint128) previewFN, uint128 param)
        internal
        view
        returns (uint128 result)
    {
        if (param == 0) return 0;

        IPool pool = IPool(previewFN.address);

        if (previewFN.selector == IPool.buyFYTokenPreview.selector) {
            return _capPreview(previewFN, param, cap(pool.maxFYTokenOut));
        }

        if (previewFN.selector == IPool.sellBasePreview.selector) {
            return _capPreview(previewFN, param, cap(pool.maxBaseIn));
        }

        revert InvalidSelector(previewFN.selector);
    }

    function orMint(function(uint128) external view returns (uint128) previewFN, uint128 param, uint256 liquidity)
        internal
        view
        returns (uint128 result)
    {
        if (param == 0) return 0;

        if (
            previewFN.selector != IPool.buyFYTokenPreview.selector
                && previewFN.selector != IPool.sellBasePreview.selector
        ) revert InvalidSelector(previewFN.selector);

        return _capPreview(previewFN, param, liquidity);
    }

    function _capPreview(function(uint128) external view returns (uint128) previewFN, uint128 param, uint256 liquidity)
        private
        view
        returns (uint128)
    {
        if (liquidity == 0) return param;
        return liquidity > param ? previewFN(param) : previewFN(uint128(liquidity)) + (param - uint128(liquidity));
    }

    function minLiquidityToCloseLendingPosition(ICauldron cauldron, PositionId positionId, uint256 quantity)
        internal
        view
        returns (uint256)
    {
        return quantity - Math.min(quantity, cauldron.balances(positionId.toBaseVaultId()).ink);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {DataTypes} from "lib/vault-v2/src/interfaces/DataTypes.sol";
import {IContangoLadle} from "lib/vault-v2/src/other/contango/interfaces/IContangoLadle.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";

import "../../libraries/StorageLib.sol";

library YieldStorageLib {
    using SafeCast for uint256;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum YieldStorageId {
        Unused, // 0
        Instruments, // 1
        Joins, // 2
        Ladle, // 3
        Cauldron, // 4
        PoolView // 5
    }

    function getLadle() internal view returns (IContangoLadle) {
        return IContangoLadle(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value);
    }

    function setLadle(IContangoLadle ladle) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Ladle))).value = address(ladle);
    }

    function getCauldron() internal view returns (ICauldron) {
        return ICauldron(StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value);
    }

    function setCauldron(ICauldron cauldron) internal {
        StorageSlot.getAddressSlot(bytes32(getStorageSlot(YieldStorageId.Cauldron))).value = address(cauldron);
    }

    // solhint-disable no-inline-assembly
    /// @dev Mapping from a symbol to instrument
    function getInstruments() internal pure returns (mapping(Symbol => YieldInstrumentStorage) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Instruments);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    // solhint-disable no-inline-assembly
    function getJoins() internal pure returns (mapping(bytes12 => address) storage store) {
        uint256 slot = getStorageSlot(YieldStorageId.Joins);
        assembly {
            store.slot := slot
        }
    }
    // solhint-enable no-inline-assembly

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `YieldStorageId`
    /// @return slot The storage slot.
    function getStorageSlot(YieldStorageId storageId) internal pure returns (uint256 slot) {
        return uint256(storageId) + YIELD_STORAGE_SLOT_BASE;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import {IPool} from "lib/yieldspace-tv/src/interfaces/IPool.sol";

import "../../libraries/StorageLib.sol";
import "../../libraries/Errors.sol";
import "../../libraries/DataTypes.sol";

import "./YieldStorageLib.sol";

library YieldUtils {
    using SafeCast for *;

    error PositionIdTooLarge(PositionId positionId);

    function loadInstrument(Symbol symbol)
        internal
        view
        returns (InstrumentStorage storage instrument, YieldInstrumentStorage storage yieldInstrument)
    {
        instrument = StorageLib.getInstruments()[symbol];
        if (instrument.maturity == 0) {
            revert InvalidInstrument(symbol);
        }
        yieldInstrument = YieldStorageLib.getInstruments()[symbol];
    }

    function toVaultId(PositionId positionId) internal pure returns (bytes12) {
        // position id limit because uint48.max is added to it when using baseVaultId
        if (PositionId.unwrap(positionId) > type(uint48).max) {
            // realistically unlikely to hit this limit because 2^48 is 281+ trillion
            revert PositionIdTooLarge(positionId);
        }
        return bytes12(uint96(PositionId.unwrap(positionId)));
    }

    function toBaseVaultId(PositionId positionId) internal pure returns (bytes12) {
        return bytes12(uint96(PositionId.unwrap(positionId)) + type(uint48).max);
    }

    function buyFYTokenPreviewFixed(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = buyFYTokenPreviewZero(pool, fyTokenOut);
        // Math is not exact anymore with the PoolEuler, so we need to transfer a bit more to the pool
        baseIn = baseIn == 0 ? 0 : baseIn + 1;
    }

    function buyFYTokenPreviewZero(IPool pool, uint128 fyTokenOut) internal view returns (uint128 baseIn) {
        baseIn = fyTokenOut == 0 ? 0 : pool.buyFYTokenPreview(fyTokenOut);
    }

    function sellBasePreviewZero(IPool pool, uint128 baseIn) internal view returns (uint128 fyTokenOut) {
        fyTokenOut = baseIn == 0 ? 0 : pool.sellBasePreview(baseIn);
    }

    function closeLendingPositionPreview(ICauldron cauldron, IPool basePool, PositionId positionId, uint256 quantity)
        internal
        view
        returns (uint256 baseToSell)
    {
        uint256 amountToUnwrap = baseToSell = Math.min(quantity, cauldron.balances(toBaseVaultId(positionId)).ink);
        uint256 fyTokenToSell = quantity - amountToUnwrap;
        if (fyTokenToSell > 0) {
            baseToSell += basePool.sellFYTokenPreview(fyTokenToSell.toUint128());
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IFeeModel.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";

uint256 constant MAX_FIXED_FEE = 1e18; // 100%
uint256 constant MIN_FIXED_FEE = 0.000001e18; // 0.0001%

contract FixedFeeModel is IFeeModel {
    using FixedPointMathLib for uint256;

    error AboveMaxFee(uint256 fee);
    error BelowMinFee(uint256 fee);

    uint256 public immutable fee; // fee percentage in wad, e.g. 0.0015e18 -> 0.15%

    constructor(uint256 _fee) {
        if (_fee > MAX_FIXED_FEE) revert AboveMaxFee(_fee);
        if (_fee < MIN_FIXED_FEE) revert BelowMinFee(_fee);

        fee = _fee;
    }

    /// @inheritdoc IFeeModel
    function calculateFee(address, PositionId, uint256 cost) external view override returns (uint256 calculatedFee) {
        calculatedFee = cost.mulWadUp(fee);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/solmate/src/utils/FixedPointMathLib.sol";

import "../interfaces/IContangoView.sol";
import "../interfaces/IFeeModel.sol";

uint256 constant MAX_YEARLY_FEE = 5e18; // 500%
uint256 constant MIN_YEARLY_FEE = 0.05e18; // 5%
uint256 constant HOURS_PER_YEAR = 365 * 24;
uint256 constant MAX_GRACE_PERIOD = 4 weeks;

contract PenaltyModel is IFeeModel {
    using FixedPointMathLib for uint256;

    error AboveMaxFee(uint256 hourlyFee);
    error BelowMinFee(uint256 hourlyFee);
    error AboveMaxGracePeriod(uint256 gracePeriod);

    IFeeModel public immutable delegate;
    IContangoView public immutable contango;
    uint256 public immutable hourlyFee; // percentage in wad, e.g. 0.0015e18 -> 0.15%
    uint256 public immutable gracePeriod;

    constructor(IFeeModel _delegate, IContangoView _contango, uint256 yearlyFee, uint256 _gracePeriod) {
        if (yearlyFee > MAX_YEARLY_FEE) revert AboveMaxFee(yearlyFee);
        if (yearlyFee < MIN_YEARLY_FEE) revert BelowMinFee(yearlyFee);
        if (_gracePeriod > MAX_GRACE_PERIOD) revert AboveMaxGracePeriod(_gracePeriod);

        hourlyFee = yearlyFee / HOURS_PER_YEAR;

        delegate = _delegate;
        contango = _contango;
        gracePeriod = _gracePeriod / 1 hours;
    }

    /// @inheritdoc IFeeModel
    function calculateFee(address trader, PositionId positionId, uint256 cost)
        external
        view
        override
        returns (uint256 calculatedFee)
    {
        calculatedFee = delegate.calculateFee(trader, positionId, cost);

        uint256 positionMaturity = contango.position(positionId).maturity;

        uint256 hoursSinceExpiry =
            block.timestamp > positionMaturity ? (block.timestamp - positionMaturity) / 1 hours : 0; // solhint-disable-line not-rely-on-time

        if (hoursSinceExpiry > gracePeriod) {
            calculatedFee += cost.mulWadUp(hourlyFee) * (hoursSinceExpiry - gracePeriod);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/solmate/src/tokens/WETH.sol";
import "../dependencies/Balancer.sol";
import "../libraries/DataTypes.sol";
import "../ContangoPositionNFT.sol";
import "../interfaces/IContango.sol";
import "../interfaces/IContangoQuoter.sol";

contract CashSettler is IFlashLoanRecipient, IERC721Receiver {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    using Address for address;

    event PositionSettled(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        address to,
        uint256 equity,
        address spender,
        address dex
    );

    error NotBalancer(address sender);
    error NotPositionNFT(address sender);
    error NotWETH(address sender);

    struct NFTCallback {
        Symbol symbol;
        ERC20 base;
        ERC20 quote;
        uint256 openQuantity;
        address spender;
        address dex;
        bytes swapBytes;
        address to;
    }

    struct FlashLoanCallback {
        PositionId positionId;
        address owner;
        NFTCallback nftCb;
    }

    IFlashLoaner public constant BALANCER = IFlashLoaner(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ContangoPositionNFT public immutable positionNFT;
    IContango public immutable contango;
    IContangoQuoter public immutable contangoQuoter;
    WETH public immutable weth;

    constructor(ContangoPositionNFT _positionNFT, IContango _contango, IContangoQuoter _contangoQuoter, WETH _weth) {
        positionNFT = _positionNFT;
        contango = _contango;
        contangoQuoter = _contangoQuoter;
        weth = _weth;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        if (msg.sender != address(positionNFT)) {
            revert NotPositionNFT(msg.sender);
        }

        NFTCallback memory nftCallback = abi.decode(data, (NFTCallback));
        PositionId positionId = PositionId.wrap(tokenId);

        address[] memory tokens = new address[](1);
        tokens[0] = address(nftCallback.quote);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = contangoQuoter.deliveryCostForPosition(positionId);

        BALANCER.flashLoan(
            this,
            tokens,
            amounts,
            abi.encode(FlashLoanCallback({positionId: positionId, owner: from, nftCb: nftCallback}))
        );

        return IERC721Receiver.onERC721Received.selector;
    }

    function receiveFlashLoan(
        address[] memory,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        if (msg.sender != address(BALANCER)) {
            revert NotBalancer(msg.sender);
        }

        FlashLoanCallback memory cb = abi.decode(userData, (FlashLoanCallback));

        cb.nftCb.quote.safeTransfer(address(contango), amounts[0]);
        contango.deliver(cb.positionId, address(contango), address(this));

        cb.nftCb.base.safeApprove(cb.nftCb.spender, cb.nftCb.openQuantity);
        cb.nftCb.dex.functionCall(cb.nftCb.swapBytes);

        cb.nftCb.quote.safeTransfer(msg.sender, amounts[0] + feeAmounts[0]);

        uint256 equity = _transferEquity(cb.nftCb.quote, cb.nftCb.to);

        emit PositionSettled({
            symbol: cb.nftCb.symbol,
            trader: cb.owner,
            positionId: cb.positionId,
            to: cb.nftCb.to,
            equity: equity,
            spender: cb.nftCb.spender,
            dex: cb.nftCb.dex
        });
    }

    function _transferEquity(ERC20 token, address to) internal returns (uint256 balance) {
        balance = token.balanceOf(address(this));

        if (balance > 0) {
            if (address(token) == address(weth)) {
                weth.withdraw(balance);
                to.safeTransferETH(balance);
            } else {
                token.safeTransfer(to, balance);
            }
        }
    }

    receive() external payable {
        if (msg.sender != address(weth)) {
            revert NotWETH(msg.sender);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IOracle} from "lib/vault-v2/src/interfaces/IOracle.sol";
import {IPoolOracle} from "lib/yieldspace-tv/src/interfaces/IPoolOracle.sol";
import "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "lib/solmate/src/tokens/ERC20.sol";
import "lib/solmate/src/tokens/WETH.sol";
import "lib/solmate/src/utils/FixedPointMathLib.sol";
import "../liquiditysource/yield-protocol/interfaces/IContangoYield.sol";
import "../liquiditysource/yield-protocol/YieldUtils.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import "../interfaces/IOrderManager.sol";
import "../interfaces/IContangoOracle.sol";
import "../libraries/Errors.sol";
import "../utils/Balanceless.sol";
import "../ContangoPositionNFT.sol";

contract OrderManagerContangoYield is IOrderManager, ERC721Holder, AccessControl, Balanceless {
    using SafeTransferLib for *;
    using SafeCast for *;
    using SignedMath for int256;
    using YieldUtils for *;
    using FixedPointMathLib for *;

    bytes32 public constant KEEPER = keccak256("KEEPER");
    bytes6 public constant ETH_ID = "00";

    IContangoYield public immutable contango;
    ContangoPositionNFT public immutable positionNFT;
    ICauldron public immutable cauldron;
    WETH public immutable weth;
    IOracle public immutable oracle;
    IPoolOracle public immutable poolOracle;
    IContangoOracle public immutable contangoOracle;

    mapping(bytes32 => bool) public orders;
    uint256 public gasMultiplier;
    uint256 public gasStart = 21_000;

    constructor(
        uint256 _gasMultiplier,
        IContangoYield _contango,
        ContangoPositionNFT _positionNFT,
        ICauldron _cauldron,
        WETH _weth,
        IOracle _oracle,
        IPoolOracle _poolOracle,
        IContangoOracle _contangoOracle
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        gasMultiplier = _gasMultiplier;
        contango = _contango;
        positionNFT = _positionNFT;
        cauldron = _cauldron;
        weth = _weth;
        oracle = _oracle;
        poolOracle = _poolOracle;
        contangoOracle = _contangoOracle;
    }

    // ====================================== Setters ======================================

    function setGasMultiplier(uint256 _gasMultiplier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        gasMultiplier = _gasMultiplier;
    }

    // ====================================== Linked Orders ======================================

    function placeLinkedOrder(PositionId positionId, OrderType orderType, uint256 triggerCost, uint256 limitCost)
        external
        override
    {
        address owner = _verifyPosition(positionId);

        bytes32 orderHash = hashLinkedOrder(positionId, owner, orderType, triggerCost, limitCost);
        orders[orderHash] = true;

        emit LinkedOrderPlaced(orderHash, owner, positionId, orderType, triggerCost, limitCost);
    }

    function executeLinkedOrder(
        PositionId positionId,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external override gasMeasured onlyRole(KEEPER) returns (uint256 keeperReward) {
        address owner = positionNFT.positionOwner(positionId);

        bytes32 orderHash = hashLinkedOrder(positionId, owner, orderType, triggerCost, limitCost);

        if (!orders[orderHash]) revert OrderNotFound();
        // remove the order
        orders[orderHash] = false;

        positionNFT.safeTransferFrom(owner, address(this), PositionId.unwrap(positionId));

        keeperReward =
            _modifyPosition(positionId, owner, orderType, triggerCost, limitCost, lendingLiquidity, uniswapFee);

        emit LinkedOrderExecuted(
            orderHash, owner, positionId, orderType, triggerCost, limitCost, keeperReward, lendingLiquidity, uniswapFee
        );
    }

    function cancelLinkedOrder(PositionId positionId, OrderType orderType, uint256 triggerCost, uint256 limitCost)
        external
        override
    {
        bytes32 orderHash = hashLinkedOrder(positionId, msg.sender, orderType, triggerCost, limitCost);
        orders[orderHash] = false;

        emit LinkedOrderCancelled(orderHash, msg.sender, positionId, orderType, triggerCost, limitCost);
    }

    // ====================================== Lever Orders ======================================

    function placeLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    ) external override {
        address owner = _verifyPosition(positionId);

        bytes32 orderHash =
            hashLeverOrder(positionId, owner, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent);
        orders[orderHash] = true;

        emit LeverOrderPlaced(
            orderHash, owner, positionId, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent
        );
    }

    function executeLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        uint256 lendingLiquidity,
        bool recurrent
    ) external override gasMeasured onlyRole(KEEPER) returns (uint256 keeperReward) {
        address owner = positionNFT.positionOwner(positionId);

        bytes32 orderHash =
            hashLeverOrder(positionId, owner, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent);

        if (!orders[orderHash]) revert OrderNotFound();
        orders[orderHash] = recurrent;

        positionNFT.safeTransferFrom(owner, address(this), PositionId.unwrap(positionId));

        uint256 currentLeverage;
        (keeperReward, currentLeverage) = _modifyCollateral(
            ModifyCollateralParams(
                positionId, owner, triggerLeverage, targetLeverage, oraclePriceTolerance, lendingLiquidity
            )
        );

        emit LeverOrderExecuted(
            orderHash,
            owner,
            positionId,
            keeperReward,
            triggerLeverage,
            targetLeverage,
            currentLeverage,
            oraclePriceTolerance,
            lendingLiquidity,
            recurrent
        );
    }

    function cancelLeverOrder(
        PositionId positionId,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    ) external override {
        bytes32 orderHash =
            hashLeverOrder(positionId, msg.sender, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent);
        orders[orderHash] = false;

        emit LeverOrderCancelled(
            orderHash, msg.sender, positionId, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent
        );
    }

    // ====================================== Other ======================================

    function collectBalance(ERC20 token, address payable to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collectBalance(token, to, amount);
    }

    // ====================================== Internal ======================================

    function _modifyPosition(
        PositionId positionId,
        address owner,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) internal returns (uint256 keeperReward) {
        Position memory position = contango.position(positionId);

        YieldInstrument memory instrument = contango.yieldInstrumentV2(position.symbol);

        uint256 balanceBefore = instrument.quote.balanceOf(address(this));

        if (orderType == OrderType.StopLoss) {
            uint256 closingCost = contangoOracle.closingCost(positionId, uniswapFee, 60);
            if (triggerCost < closingCost) {
                revert TriggerCostNotReached(closingCost, triggerCost);
            }
        }

        contango.modifyPosition({
            positionId: positionId,
            quantity: -int256(position.openQuantity),
            limitCost: limitCost,
            collateral: 0,
            payerOrReceiver: address(this),
            lendingLiquidity: lendingLiquidity,
            uniswapFee: uniswapFee
        });

        uint256 balanceAfter = instrument.quote.balanceOf(address(this));

        keeperReward = _keeperReward(instrument.quote, instrument.quoteId);
        _transferOut(instrument.quote, msg.sender, keeperReward);
        _transferOut(instrument.quote, owner, balanceAfter - balanceBefore - keeperReward);
    }

    struct ModifyCollateralParams {
        PositionId positionId;
        address owner;
        uint256 triggerLeverage;
        uint256 targetLeverage;
        uint256 oraclePriceTolerance;
        uint256 lendingLiquidity;
    }

    function _modifyCollateral(ModifyCollateralParams memory params)
        internal
        returns (uint256 keeperReward, uint256 currentLeverage)
    {
        int256 collateral;
        uint256 collateralFV;
        ERC20 quote;
        bool isReLever;
        bytes6 quoteId;
        (currentLeverage, collateral, collateralFV, quote, isReLever, quoteId) = _collateral(params);

        uint256 multiplier = collateral < 0 ? 1e18 + params.oraclePriceTolerance : 1e18 - params.oraclePriceTolerance;
        uint256 slippageTolerance = collateralFV * multiplier / 1e18;

        if (!isReLever) {
            quote.safeTransferFrom(params.owner, address(contango), collateral.abs());
        }

        contango.modifyCollateral({
            positionId: params.positionId,
            collateral: collateral,
            slippageTolerance: slippageTolerance,
            payerOrReceiver: isReLever ? address(this) : address(contango),
            lendingLiquidity: params.lendingLiquidity
        });

        positionNFT.safeTransferFrom(address(this), params.owner, PositionId.unwrap(params.positionId));

        keeperReward = _keeperReward(quote, quoteId);
        if (isReLever) {
            _transferOut(quote, params.owner, collateral.abs() - keeperReward);
        } else {
            quote.safeTransferFrom(params.owner, address(this), keeperReward);
        }

        _transferOut(quote, msg.sender, keeperReward);
    }

    function _keeperReward(ERC20 quote, bytes6 quoteId) internal returns (uint256 keeperReward) {
        uint256 rate;
        if (address(quote) != address(weth)) {
            DataTypes.Series memory series = cauldron.series(quoteId);
            (rate,) = oracle.get(ETH_ID, series.baseId, 1 ether);
        }

        // 21000 min tx gas (starting gasStart value) + gas used so far + 16 gas per byte of data + 60k for the 2 ERC20 transfers
        uint256 gasSpent = gasStart - gasleft() + 16 * msg.data.length + 60_000;
        // Keeper receives a multiplier of the gas spent @ (current baseFee + 3 wei for tip)
        keeperReward = gasSpent * gasMultiplier * block.basefee + 3;

        if (rate > 0) {
            keeperReward = keeperReward * rate / 1 ether;
        }
    }

    function _transferOut(ERC20 token, address to, uint256 amount) internal {
        if (address(token) == address(weth)) {
            weth.withdraw(amount);
            to.safeTransferETH(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function _collateral(ModifyCollateralParams memory params)
        internal
        returns (
            uint256 currentLeverage,
            int256 collateral,
            uint256 collateralFV,
            ERC20 quote,
            bool isReLever,
            bytes6 quoteId
        )
    {
        Position memory position = contango.position(params.positionId);

        YieldInstrument memory instrument = contango.yieldInstrumentV2(position.symbol);
        quote = instrument.quote;
        quoteId = instrument.quoteId;

        DataTypes.Balances memory balances = cauldron.balances(params.positionId.toVaultId());

        isReLever = params.targetLeverage > params.triggerLeverage;

        uint256 underlyingCollateral;
        (currentLeverage, underlyingCollateral) = _positionLeverage(instrument, balances);

        {
            // take profit scenario, aka re-lever
            if (isReLever && currentLeverage > params.triggerLeverage) {
                revert LeverageNotReached(currentLeverage, params.triggerLeverage);
            }
            // stop loss scenario, aka de-lever
            if (!isReLever && currentLeverage < params.triggerLeverage) {
                revert LeverageNotReached(currentLeverage, params.triggerLeverage);
            }
        }

        (collateral, collateralFV) =
            _deriveCollateralFromLeverage(instrument, balances, underlyingCollateral, params.targetLeverage);
    }

    function _deriveCollateralFromLeverage(
        YieldInstrument memory instrument,
        DataTypes.Balances memory balances,
        uint256 underlyingCollateral,
        uint256 leverage
    ) internal returns (int256 collateral, uint128 collateralFV) {
        uint256 debtFV =
            (((-int256(underlyingCollateral) * 1e18) / int256(leverage)) + int256(underlyingCollateral)).toUint256();

        if (debtFV > balances.art) {
            // Debt needs to increase to reach the desired leverage
            collateralFV = debtFV.toUint128() - balances.art;
            (uint256 collateralPV,) = poolOracle.getSellFYTokenPreview(instrument.quotePool, collateralFV);
            collateral = -int256(collateralPV);
        } else {
            // Debt needs to be burnt to reach the desired leverage
            collateralFV = balances.art - debtFV.toUint128();
            (uint256 collateralPV,) = poolOracle.getBuyFYTokenPreview(instrument.quotePool, collateralFV);
            collateral = int256(collateralPV);
        }
    }

    function _positionLeverage(YieldInstrument memory instrument, DataTypes.Balances memory balances)
        private
        returns (uint256 leverage, uint256 underlyingCollateral)
    {
        DataTypes.Series memory series = cauldron.series(instrument.quoteId);
        DataTypes.SpotOracle memory spotOracle = cauldron.spotOracles(series.baseId, instrument.baseId);

        (underlyingCollateral,) = spotOracle.oracle.get(instrument.baseId, series.baseId, balances.ink);

        uint256 multiplier = 10 ** (instrument.quote.decimals());
        uint256 margin = (underlyingCollateral - balances.art) * multiplier / underlyingCollateral;
        leverage = 1e18 * multiplier / margin;
    }

    function _verifyPosition(PositionId positionId) internal view returns (address owner) {
        owner = positionNFT.positionOwner(positionId);
        if (owner != msg.sender) revert NotPositionOwner();
        if (
            positionNFT.getApproved(PositionId.unwrap(positionId)) != address(this)
                && !positionNFT.isApprovedForAll(owner, address(this))
        ) revert PositionNotApproved();
    }

    function hashLinkedOrder(
        PositionId positionId,
        address owner,
        OrderType orderType,
        uint256 triggerCost,
        uint256 limitCost
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(positionId, owner, orderType, triggerCost, limitCost));
    }

    function hashLeverOrder(
        PositionId positionId,
        address owner,
        uint256 triggerLeverage,
        uint256 targetLeverage,
        uint256 oraclePriceTolerance,
        bool recurrent
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(positionId, owner, triggerLeverage, targetLeverage, oraclePriceTolerance, recurrent)
        );
    }

    /// @dev `weth.withdraw` will send ether using this function.
    receive() external payable {
        if (msg.sender != address(weth)) {
            revert OnlyFromWETH(msg.sender);
        }
    }

    modifier gasMeasured() {
        gasStart += gasleft();
        _;
        gasStart = 21_000;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {DataTypes} from "lib/vault-v2/src/interfaces/DataTypes.sol";
import {ICauldron} from "lib/vault-v2/src/interfaces/ICauldron.sol";
import {OracleLibrary} from "lib/vault-v2/src/oracles/uniswap/uniswapv0.8/OracleLibrary.sol";
import {IPoolOracle} from "lib/yieldspace-tv/src/interfaces/IPoolOracle.sol";

import "src/interfaces/IContangoOracle.sol";
import "src/libraries/Errors.sol";
import "src/dependencies/Uniswap.sol";
import "src/liquiditysource/yield-protocol/ContangoYield.sol";

contract ContangoYieldOracle is IContangoOracle {
    using YieldUtils for *;
    using PoolAddress for address;
    using SafeCast for *;

    ContangoYield public immutable contangoYield;
    ICauldron public immutable cauldron;
    IPoolOracle public immutable oracle;

    constructor(ContangoYield _contangoYield, ICauldron _cauldron, IPoolOracle _oracle) {
        contangoYield = _contangoYield;
        cauldron = _cauldron;
        oracle = _oracle;
    }

    function closingCost(PositionId positionId, uint24 uniswapFee, uint32 uniswapPeriod)
        external
        override
        returns (uint256 cost)
    {
        YieldInstrument memory instrument = _validatePosition(positionId);
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        (uint256 inkPV,) = oracle.getSellFYTokenPreview(instrument.basePool, balances.ink);

        address pool = UniswapV3Handler.UNISWAP_FACTORY.computeAddress(
            PoolAddress.getPoolKey(address(instrument.base), address(instrument.quote), uniswapFee)
        );

        uint256 hedgeCost = OracleLibrary.getQuoteAtTick({
            tick: OracleLibrary.consult(pool, uniswapPeriod),
            baseAmount: inkPV.toUint128(),
            baseToken: address(instrument.base),
            quoteToken: address(instrument.quote)
        });

        (uint256 artPV,) = oracle.getBuyFYTokenPreview(instrument.quotePool, balances.art);

        cost = hedgeCost + balances.art - artPV;
    }

    function _validatePosition(PositionId positionId) private view returns (YieldInstrument memory instrument) {
        Position memory position = contangoYield.position(positionId);
        if (position.openQuantity == 0 && position.openCost == 0) {
            if (position.collateral <= 0) {
                revert InvalidPosition(positionId);
            }
        }
        instrument = contangoYield.yieldInstrumentV2(position.symbol);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/TransferLib.sol";

abstract contract Balanceless {
    using SafeTransferLib for address payable;
    using TransferLib for ERC20;

    event BalanceCollected(ERC20 indexed token, address indexed to, uint256 amount);

    /// @dev Contango contracts are never meant to hold a balance.
    function _collectBalance(ERC20 token, address payable to, uint256 amount) internal {
        if (address(token) == address(0)) {
            to.safeTransferETH(amount);
        } else {
            token.transferOut(address(this), to, amount);
        }
        emit BalanceCollected(token, to, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/solmate/src/utils/SafeTransferLib.sol";

interface IPermissionedProxyDeployer {
    function proxyParameters()
        external
        returns (address payable owner, address payable delegate, ERC20[] memory tokens);
}

contract PermissionedProxy {
    using SafeTransferLib for ERC20;

    error OnlyDelegate();
    error OnlyOwner();
    error OnlyOwnerOrDelegate();

    address payable public immutable owner;
    address payable public immutable delegate;

    constructor() {
        ERC20[] memory tokens;
        (owner, delegate, tokens) = IPermissionedProxyDeployer(msg.sender).proxyParameters();

        // msg.sender should be careful with how many tokens are passed here to avoid DoS gas limit
        // https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#gas-limit-dos-on-a-contract-via-unbounded-operations
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeApprove(owner, type(uint256).max);
        }
    }

    function approve(ERC20 token, address spender, uint256 amount) public onlyOwner {
        token.safeApprove(spender, amount);
    }

    function collectBalance(uint256 value) external onlyOwner {
        // restricted to owner, so no need to do a safe call
        owner.transfer(value);
    }

    fallback() external payable {
        _call();
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        /// @notice .send() and .transfer() only work for sending ETH to the owner (retrieved via .collectBalance())
        /// this is a deliberate decision, since any attempt to forward the transfer to either the owner or delegate
        /// spends more than the 2300 gas available
        if (msg.sender != delegate) revert OnlyDelegate();
    }

    /// @dev call version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/Proxy.sol#L22
    function _call() private {
        address implementation = _getImplementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), implementation, callvalue(), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() private view returns (address payable implementation) {
        if (msg.sender == owner) {
            implementation = delegate;
        } else if (msg.sender == delegate) {
            implementation = owner;
        } else {
            revert OnlyOwnerOrDelegate();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/ERC20.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

contract ChainlinkAggregatorV2V3Mock is AggregatorV2V3Interface {
    event PriceSet(int256 price, uint8 decimals, int256 priceParameter, uint8 priceDecimals, uint256 timestamp);

    uint8 public immutable override decimals;
    uint8 public immutable priceDecimals;
    int256 public price;
    uint256 public timestamp;

    constructor(uint8 _decimals, uint8 _priceDecimals) {
        decimals = _decimals;
        priceDecimals = _priceDecimals;
    }

    function set(int256 _price) external returns (ChainlinkAggregatorV2V3Mock) {
        if (priceDecimals > decimals) {
            price = _price / int256(10 ** (priceDecimals - decimals));
        } else if (decimals > priceDecimals) {
            price = _price * int256(10 ** (decimals - priceDecimals));
        } else {
            price = _price;
        }
        timestamp = block.timestamp;

        emit PriceSet({
            price: price,
            decimals: decimals,
            priceParameter: _price,
            priceDecimals: priceDecimals,
            timestamp: timestamp
        });

        return ChainlinkAggregatorV2V3Mock(address(this));
    }

    // V3

    function description() external pure override returns (string memory) {
        return "ChainlinkAggregatorV2V3Mock";
    }

    function version() external pure override returns (uint256) {
        return 3;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, price, 0, timestamp, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, price, 0, timestamp, 0);
    }

    // V2

    function latestAnswer() external view override returns (int256) {
        return price;
    }

    function latestTimestamp() external view override returns (uint256) {
        return timestamp;
    }

    function latestRound() external pure override returns (uint256) {
        return 0;
    }

    function getAnswer(uint256) external view override returns (int256) {
        return price;
    }

    function getTimestamp(uint256) external view override returns (uint256) {
        return timestamp;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/vault-v2/src/interfaces/IOracle.sol";
import "./IPoolStub.sol";

contract IOraclePoolStub is IOracle {
    bytes32 public asset;
    IPoolStub public immutable pool;

    constructor(IPoolStub _pool, bytes32 _asset) {
        pool = _pool;
        asset = _asset;
    }

    function peek(bytes32 base, bytes32, /* quote */ uint256 amount)
        public
        view
        override
        returns (uint256 value, uint256 updateTime)
    {
        value =
            base == asset ? pool.sellFYTokenPreviewUnsafe(uint128(amount)) : pool.sellBasePreviewUnsafe(uint128(amount));
        updateTime = block.timestamp;
    }

    function get(bytes32 base, bytes32 quote, uint256 amount)
        public
        view
        override
        returns (uint256 value, uint256 updateTime)
    {
        return peek(base, quote, amount);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/yieldspace-tv/src/interfaces/IPool.sol";
import "lib/yieldspace-tv/src/interfaces/IMaturingToken.sol";
import "lib/yield-utils-v2/src/token/ERC20Permit.sol";
import "lib/yield-utils-v2/src/token/IERC20Metadata.sol";

contract IPoolStub is IPool, ERC20Permit {
    error NotImplemented(string f);

    IERC20 public immutable override base;
    IMaturingToken public immutable override fyToken;
    uint32 public immutable override maturity;

    uint256 public bid;
    uint256 public ask;

    uint112 private baseCached;
    uint112 private fyTokenCached;

    constructor(IPool delegate)
        ERC20Permit(
            string(abi.encodePacked(IERC20Metadata(address(delegate.fyToken())).name(), " LP")),
            string(abi.encodePacked(IERC20Metadata(address(delegate.fyToken())).symbol(), "LP")),
            IERC20Metadata(address(delegate.fyToken())).decimals()
        )
    {
        base = delegate.base();
        fyToken = delegate.fyToken();
        maturity = uint32(fyToken.maturity());
    }

    function setBidAsk(uint128 _bid, uint128 _ask) external {
        bid = _bid;
        ask = _ask;
        sync();
    }

    function sync() public {
        _update(getBaseBalance(), getFYTokenBalance());
    }

    function _update(uint128 baseBalance, uint128 fyBalance) private {
        baseCached = uint112(baseBalance);
        fyTokenCached = uint112(fyBalance);
    }

    function ts() external pure override returns (int128) {
        revert NotImplemented("ts");
    }

    function g1() external pure override returns (int128) {
        revert NotImplemented("g1");
    }

    function g2() external pure override returns (int128) {
        revert NotImplemented("g2");
    }

    function scaleFactor() external view override returns (uint96) {
        return uint96(10 ** (18 - baseToken().decimals()));
    }

    function getCache() external pure returns (uint104, uint104, uint32, uint16) {
        revert NotImplemented("getCache");
    }

    function getBaseBalance() public view override returns (uint128) {
        return uint128(base.balanceOf(address(this)));
    }

    function getFYTokenBalance() public view override returns (uint128) {
        return uint128(fyToken.balanceOf(address(this)));
    }

    function retrieveBase(address /* to */ ) external pure override returns (uint128 /* retrieved */ ) {
        // TV pools don't properly implement this method
        // retrieved = getBaseBalance() - baseCached;
        // base.transfer(to, retrieved);
        revert NotImplemented("retrieveBase");
    }

    function retrieveFYToken(address to) external override returns (uint128 retrieved) {
        retrieved = getFYTokenBalance() - fyTokenCached;
        fyToken.transfer(to, retrieved);
    }

    error Balances(uint256 actual, uint256 cached);

    function sellBase(address to, uint128 min) external override returns (uint128 fyTokenOut) {
        uint128 _baseBalance = getBaseBalance();
        uint128 _fyTokenBalance = getFYTokenBalance();
        uint128 baseIn = _baseBalance - baseCached;
        fyTokenOut = sellBasePreview(baseIn);
        require(fyTokenOut >= min, "too little fyToken out");
        fyToken.transfer(to, fyTokenOut);
        _update(_baseBalance, _fyTokenBalance - fyTokenOut);
    }

    function buyBase(address to, uint128 baseOut, uint128 max) external override returns (uint128 fyTokenIn) {
        fyTokenIn = buyBasePreview(baseOut);
        require(fyTokenIn <= max, "too much fyToken in");

        base.transfer(to, baseOut);
        _update(baseCached - baseOut, fyTokenCached + fyTokenIn);
    }

    function sellFYToken(address to, uint128 min) external override returns (uint128 baseOut) {
        uint128 _fyTokenBalance = getFYTokenBalance();
        uint128 _baseBalance = getBaseBalance();
        uint128 fyTokenIn = _fyTokenBalance - fyTokenCached;
        baseOut = sellFYTokenPreview(fyTokenIn);
        require(baseOut >= min, "too little base out");
        base.transfer(to, baseOut);
        _update(_baseBalance - baseOut, _fyTokenBalance);
    }

    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external override returns (uint128 baseIn) {
        baseIn = buyFYTokenPreview(fyTokenOut);
        require(baseIn <= max, "too much base in");

        fyToken.transfer(to, fyTokenOut);
        _update(baseCached + baseIn, fyTokenCached - fyTokenOut);
    }

    function sellBasePreview(uint128 baseIn) public view override returns (uint128) {
        require(baseIn > 0, "sellBasePreview: Can't quote 0 baseIn");
        require(maxBaseIn() >= baseIn, "Not enough liquidity");
        return sellBasePreviewUnsafe(baseIn);
    }

    function buyBasePreview(uint128 baseOut) public view override returns (uint128) {
        require(baseOut > 0, "buyBasePreview: Can't quote 0 baseOut");
        require(maxBaseOut() >= baseOut, "Not enough liquidity");
        return uint128((baseOut * 10 ** decimals) / bid);
    }

    function sellFYTokenPreview(uint128 fyTokenIn) public view override returns (uint128) {
        require(fyTokenIn > 0, "sellFYTokenPreview: Can't quote 0 fyTokenIn");
        require(maxFYTokenIn() >= fyTokenIn, "Not enough liquidity");
        return sellFYTokenPreviewUnsafe(fyTokenIn);
    }

    function buyFYTokenPreview(uint128 fyTokenOut) public view override returns (uint128) {
        require(fyTokenOut > 0, "buyFYTokenPreview: Can't quote 0 fyTokenOut");
        require(maxFYTokenOut() >= fyTokenOut, "Not enough liquidity");
        return uint128((fyTokenOut * ask) / 10 ** decimals);
    }

    function sellBasePreviewUnsafe(uint128 baseIn) public view returns (uint128) {
        return uint128((baseIn * 10 ** decimals) / ask);
    }

    function sellFYTokenPreviewUnsafe(uint128 fyTokenIn) public view returns (uint128) {
        return uint128((fyTokenIn * bid) / 10 ** decimals);
    }

    function mint(
        address,
        /* to */
        address,
        /* remainder */
        uint256,
        /* minRatio */
        uint256 /* maxRatio */
    ) external pure override returns (uint256, uint256, uint256) {
        revert NotImplemented("mint");
    }

    function mintWithBase(
        address, /* to */
        address, /* remainder */
        uint256, /* fyTokenToBuy */
        uint256, /* minRatio */
        uint256 /* maxRatio */
    ) external pure override returns (uint256, uint256, uint256) {
        revert NotImplemented("mintWithBase");
    }

    function burn(
        address,
        /* baseTo */
        address,
        /* fyTokenTo */
        uint256,
        /* minRatio */
        uint256 /* maxRatio */
    ) external pure override returns (uint256, uint256, uint256) {
        revert NotImplemented("burn");
    }

    function burnForBase(
        address,
        /* to */
        uint256,
        /* minRatio */
        uint256 /* maxRatio */
    ) external pure override returns (uint256, uint256) {
        revert NotImplemented("burnForBase");
    }

    function baseToken() public view returns (IERC20Metadata) {
        return IERC20Metadata(address(base));
    }

    function cumulativeRatioLast() external pure returns (uint256) {
        revert NotImplemented("cumulativeRatioLast");
    }

    function currentCumulativeRatio() external pure returns (uint256, uint256) {
        revert NotImplemented("currentCumulativeRatio");
    }

    function getC() external pure returns (int128) {
        revert NotImplemented("getC");
    }

    function getCurrentSharePrice() external pure returns (uint256) {
        revert NotImplemented("getCurrentSharePrice");
    }

    function getSharesBalance() external pure returns (uint128) {
        revert NotImplemented("getSharesBalance");
    }

    function init(address) external pure returns (uint256, uint256, uint256) {
        revert NotImplemented("init");
    }

    function mu() external pure returns (int128) {
        revert NotImplemented("mu");
    }

    function retrieveShares(address) external pure returns (uint128) {
        revert NotImplemented("retrieveShares");
    }

    function setFees(uint16) external pure {
        revert NotImplemented("setFees");
    }

    function sharesToken() external pure returns (IERC20Metadata) {
        revert NotImplemented("sharesToken");
    }

    function unwrap(address) external pure returns (uint256) {
        revert NotImplemented("unwrap");
    }

    function unwrapPreview(uint256) external pure returns (uint256) {
        revert NotImplemented("unwrapPreview");
    }

    function wrap(address) external pure returns (uint256) {
        revert NotImplemented("wrap");
    }

    function wrapPreview(uint256) external pure returns (uint256) {
        revert NotImplemented("wrapPreview");
    }

    function maxFYTokenOut() public view override returns (uint128) {
        return getFYTokenBalance();
    }

    function maxFYTokenIn() public view override returns (uint128 _maxFYTokenIn) {
        uint128 _maxBaseOut = maxBaseOut();
        if (_maxBaseOut > 0) {
            _maxFYTokenIn = buyBasePreview(_maxBaseOut);
        }
    }

    function maxBaseIn() public view override returns (uint128 _maxBaseIn) {
        uint128 _maxFYTokenOut = maxFYTokenOut();
        if (_maxFYTokenOut > 0) {
            _maxBaseIn = buyFYTokenPreview(_maxFYTokenOut);
        }
    }

    function maxBaseOut() public view override returns (uint128) {
        return getBaseBalance();
    }

    function invariant() external pure override returns (uint128) {
        revert NotImplemented("invariant");
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/solmate/src/tokens/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../src/dependencies/Uniswap.sol";

contract UniswapPoolStub {
    using SafeTransferLib for ERC20;

    event UniswapPoolStubCreated(
        ERC20 token0,
        ERC20 token1,
        AggregatorV3Interface token0Oracle,
        AggregatorV3Interface token1Oracle,
        bool token0Quoted,
        int256 absoluteSpread
    );

    error TooMuchRepaid(uint256 expected, uint256 actual, uint256 diff);
    error TooLittleRepaid(uint256 expected, uint256 actual, uint256 diff);

    ERC20 public immutable token0;
    ERC20 public immutable token1;
    AggregatorV3Interface public immutable token0Oracle;
    AggregatorV3Interface public immutable token1Oracle;
    bool public immutable token0Quoted;
    int256 public immutable absoluteSpread;

    constructor(
        ERC20 _token0,
        ERC20 _token1,
        AggregatorV3Interface _token0Oracle,
        AggregatorV3Interface _token1Oracle,
        bool _token0Quoted,
        int256 _absoluteSpread
    ) {
        token0 = _token0;
        token1 = _token1;
        token0Oracle = _token0Oracle;
        token1Oracle = _token1Oracle;
        token0Quoted = _token0Quoted;
        absoluteSpread = _absoluteSpread;

        emit UniswapPoolStubCreated(token0, token1, token0Oracle, token1Oracle, token0Quoted, absoluteSpread);
    }

    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160, bytes calldata data)
        external
        returns (int256 amount0, int256 amount1)
    {
        bool oneForZero = !zeroForOne;
        bool exactInput = amountSpecified > 0;
        bool exactOutput = amountSpecified < 0;

        int256 token0Precision = int256(10 ** token0.decimals());
        int256 token1Precision = int256(10 ** token1.decimals());

        int256 oraclePrice = peek();
        int256 price;
        if (token0Quoted) {
            price = zeroForOne ? oraclePrice + absoluteSpread : oraclePrice - absoluteSpread;
        } else {
            price = zeroForOne ? oraclePrice - absoluteSpread : oraclePrice + absoluteSpread;
        }

        // swap exact input token0 for token1
        // swap token1 for exact output token0
        if ((zeroForOne && exactInput) || (oneForZero && exactOutput)) {
            amount0 = amountSpecified;

            if (token0Quoted) {
                // amountSpecified: token0 precision
                // price: token0 precision
                // amount1: token1 precision
                amount1 = (-amountSpecified * token1Precision) / price;
            } else {
                // amountSpecified: token0 precision
                // price: token1 precision
                // amount1: token1 precision
                amount1 = (-amountSpecified * price) / token0Precision;
            }
        }

        // swap token0 for exact output token1
        // swap exact input token1 for token0
        if ((zeroForOne && exactOutput) || (oneForZero && exactInput)) {
            if (token0Quoted) {
                // amountSpecified: token1 precision
                // price: token0 precision
                // amount0: token0 precision
                amount0 = (-amountSpecified * price) / token1Precision;
            } else {
                // amountSpecified: token1 precision
                // price: token1 precision
                // amount0: token0 precision
                amount0 = (-amountSpecified * token0Precision) / price;
            }

            amount1 = amountSpecified; // amountSpecified in token1 precision
        }

        if (amount0 < 0) {
            token0.safeTransfer(recipient, uint256(-amount0));
            uint256 expected = token1.balanceOf(address(this)) + uint256(amount1);
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            uint256 actual = token1.balanceOf(address(this));
            _validateRepayment(actual, expected);
        } else {
            token1.safeTransfer(recipient, uint256(-amount1));
            uint256 expected = token0.balanceOf(address(this)) + uint256(amount0);
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            uint256 actual = token0.balanceOf(address(this));
            _validateRepayment(actual, expected);
        }
    }

    function _validateRepayment(uint256 actual, uint256 expected) internal pure {
        if (actual > expected + 5) {
            revert TooMuchRepaid(expected, actual, actual - expected);
        }
        if (actual < expected) {
            revert TooLittleRepaid(expected, actual, expected - actual);
        }
    }

    function peek() internal view returns (int256 price) {
        AggregatorV3Interface baseOracle = token0Quoted ? token1Oracle : token0Oracle;
        AggregatorV3Interface quoteOracle = token0Quoted ? token0Oracle : token1Oracle;

        int256 baseOraclePrecision = int256(10 ** baseOracle.decimals());
        int256 quoteOraclePrecision = int256(10 ** quoteOracle.decimals());

        (, int256 basePrice,,,) = baseOracle.latestRoundData();
        (, int256 quotePrice,,,) = quoteOracle.latestRoundData();

        address quote = address(token0Quoted ? token0 : token1);
        int256 quotePrecision = int256(10 ** ERC20(quote).decimals());

        price = (basePrice * quoteOraclePrecision * quotePrecision) / (quotePrice * baseOraclePrecision);
    }
}