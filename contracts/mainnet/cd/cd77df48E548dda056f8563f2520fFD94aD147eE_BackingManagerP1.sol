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
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/Fixed.sol";
import "./IMain.sol";
import "./IRewardable.sol";

// Not used directly in the IAsset interface, but used by many consumers to save stack space
struct Price {
    uint192 low; // {UoA/tok}
    uint192 high; // {UoA/tok}
}

/**
 * @title IAsset
 * @notice Supertype. Any token that interacts with our system must be wrapped in an asset,
 * whether it is used as RToken backing or not. Any token that can report a price in the UoA
 * is eligible to be an asset.
 */
interface IAsset is IRewardable {
    /// Refresh saved price
    /// The Reserve protocol calls this at least once per transaction, before relying on
    /// the Asset's other functions.
    /// @dev Called immediately after deployment, before use
    function refresh() external;

    /// Should not revert
    /// low should be nonzero if the asset could be worth selling
    /// @return low {UoA/tok} The lower end of the price estimate
    /// @return high {UoA/tok} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero when the asset might be worth selling
    /// @dev Deprecated. Phased out in 3.1.0, but left on interface for backwards compatibility
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192);

    /// @return The ERC20 contract of the token with decimals() available
    function erc20() external view returns (IERC20Metadata);

    /// @return The number of decimals in the ERC20; just for gas optimization
    function erc20Decimals() external view returns (uint8);

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external view returns (bool);

    /// @return {UoA} The max trade volume, in UoA
    function maxTradeVolume() external view returns (uint192);

    /// @return {s} The timestamp of the last refresh() that saved prices
    function lastSave() external view returns (uint48);
}

// Used only in Testing. Strictly speaking an Asset does not need to adhere to this interface
interface TestIAsset is IAsset {
    /// @return The address of the chainlink feed
    function chainlinkFeed() external view returns (AggregatorV3Interface);

    /// {1} The max % deviation allowed by the oracle
    function oracleError() external view returns (uint192);

    /// @return {s} Seconds that an oracle value is considered valid
    function oracleTimeout() external view returns (uint48);

    /// @return {s} The maximum of all oracle timeouts on the plugin
    function maxOracleTimeout() external view returns (uint48);

    /// @return {s} Seconds that the price() should decay over, after stale price
    function priceTimeout() external view returns (uint48);

    /// @return {UoA/tok} The last saved low price
    function savedLowPrice() external view returns (uint192);

    /// @return {UoA/tok} The last saved high price
    function savedHighPrice() external view returns (uint192);
}

/// CollateralStatus must obey a linear ordering. That is:
/// - being DISABLED is worse than being IFFY, or SOUND
/// - being IFFY is worse than being SOUND.
enum CollateralStatus {
    SOUND,
    IFFY, // When a peg is not holding or a chainlink feed is stale
    DISABLED // When the collateral has completely defaulted
}

/// Upgrade-safe maximum operator for CollateralStatus
library CollateralStatusComparator {
    /// @return Whether a is worse than b
    function worseThan(CollateralStatus a, CollateralStatus b) internal pure returns (bool) {
        return uint256(a) > uint256(b);
    }
}

/**
 * @title ICollateral
 * @notice A subtype of Asset that consists of the tokens eligible to back the RToken.
 */
interface ICollateral is IAsset {
    /// Emitted whenever the collateral status is changed
    /// @param newStatus The old CollateralStatus
    /// @param newStatus The updated CollateralStatus
    event CollateralStatusChanged(
        CollateralStatus indexed oldStatus,
        CollateralStatus indexed newStatus
    );

    /// @dev refresh()
    /// Refresh exchange rates and update default status.
    /// VERY IMPORTANT: In any valid implemntation, status() MUST become DISABLED in refresh() if
    /// refPerTok() has ever decreased since last call.

    /// @return The canonical name of this collateral's target unit.
    function targetName() external view returns (bytes32);

    /// @return The status of this collateral asset. (Is it defaulting? Might it soon?)
    function status() external view returns (CollateralStatus);

    // ==== Exchange Rates ====

    /// @return {ref/tok} Quantity of whole reference units per whole collateral tokens
    function refPerTok() external view returns (uint192);

    /// @return {target/ref} Quantity of whole target units per whole reference unit in the peg
    function targetPerRef() external view returns (uint192);
}

// Used only in Testing. Strictly speaking a Collateral does not need to adhere to this interface
interface TestICollateral is TestIAsset, ICollateral {
    /// @return The epoch timestamp when the collateral will default from IFFY to DISABLED
    function whenDefault() external view returns (uint256);

    /// @return The amount of time a collateral must be in IFFY status until being DISABLED
    function delayUntilDefault() external view returns (uint48);

    /// @return The underlying refPerTok, likely not included in all collaterals however.
    function underlyingRefPerTok() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";
import "./IComponent.sol";

/// A serialization of the AssetRegistry to be passed around in the P1 impl for gas optimization
struct Registry {
    IERC20[] erc20s;
    IAsset[] assets;
}

/**
 * @title IAssetRegistry
 * @notice The AssetRegistry is in charge of maintaining the ERC20 tokens eligible
 *   to be handled by the rest of the system. If an asset is in the registry, this means:
 *      1. Its ERC20 contract has been vetted
 *      2. The asset is the only asset for that ERC20
 *      3. The asset can be priced in the UoA, usually via an oracle
 */
interface IAssetRegistry is IComponent {
    /// Emitted when an asset is added to the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract added to the registry
    event AssetRegistered(IERC20 indexed erc20, IAsset indexed asset);

    /// Emitted when an asset is removed from the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract removed from the registry
    event AssetUnregistered(IERC20 indexed erc20, IAsset indexed asset);

    // Initialization
    function init(IMain main_, IAsset[] memory assets_) external;

    /// Fully refresh all asset state
    /// @custom:refresher
    function refresh() external;

    /// Register `asset`
    /// If either the erc20 address or the asset was already registered, fail
    /// @return true if the erc20 address was not already registered.
    /// @custom:governance
    function register(IAsset asset) external returns (bool);

    /// Register `asset` if and only if its erc20 address is already registered.
    /// If the erc20 address was not registered, revert.
    /// @return swapped If the asset was swapped for a previously-registered asset
    /// @custom:governance
    function swapRegistered(IAsset asset) external returns (bool swapped);

    /// Unregister an asset, requiring that it is already registered
    /// @custom:governance
    function unregister(IAsset asset) external;

    /// @return {s} The timestamp of the last refresh
    function lastRefresh() external view returns (uint48);

    /// @return The corresponding asset for ERC20, or reverts if not registered
    function toAsset(IERC20 erc20) external view returns (IAsset);

    /// @return The corresponding collateral, or reverts if unregistered or not collateral
    function toColl(IERC20 erc20) external view returns (ICollateral);

    /// @return If the ERC20 is registered
    function isRegistered(IERC20 erc20) external view returns (bool);

    /// @return A list of all registered ERC20s
    function erc20s() external view returns (IERC20[] memory);

    /// @return reg The list of registered ERC20s and Assets, in the same order
    function getRegistry() external view returns (Registry memory reg);

    /// @return The number of registered ERC20s
    function size() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IBasketHandler.sol";
import "./IBroker.sol";
import "./IComponent.sol";
import "./IRToken.sol";
import "./IStRSR.sol";
import "./ITrading.sol";

/// Memory struct for RecollateralizationLibP1 + RTokenAsset
/// Struct purposes:
///   1. Configure trading
///   2. Stay under stack limit with fewer vars
///   3. Cache information such as component addresses and basket quantities, to save on gas
struct TradingContext {
    BasketRange basketsHeld; // {BU}
    // basketsHeld.top is the number of partial baskets units held
    // basketsHeld.bottom is the number of full basket units held

    // Components
    IBasketHandler bh;
    IAssetRegistry ar;
    IStRSR stRSR;
    IERC20 rsr;
    IRToken rToken;
    // Gov Vars
    uint192 minTradeVolume; // {UoA}
    uint192 maxTradeSlippage; // {1}
    // Cached values
    uint192[] quantities; // {tok/BU} basket quantities
    uint192[] bals; // {tok} balances in BackingManager + out on trades
}

/**
 * @title IBackingManager
 * @notice The BackingManager handles changes in the ERC20 balances that back an RToken.
 *   - It computes which trades to perform, if any, and initiates these trades with the Broker.
 *     - rebalance()
 *   - If already collateralized, excess assets are transferred to RevenueTraders.
 *     - forwardRevenue(IERC20[] calldata erc20s)
 */
interface IBackingManager is IComponent, ITrading {
    /// Emitted when the trading delay is changed
    /// @param oldVal The old trading delay
    /// @param newVal The new trading delay
    event TradingDelaySet(uint48 oldVal, uint48 newVal);

    /// Emitted when the backing buffer is changed
    /// @param oldVal The old backing buffer
    /// @param newVal The new backing buffer
    event BackingBufferSet(uint192 oldVal, uint192 newVal);

    // Initialization
    function init(
        IMain main_,
        uint48 tradingDelay_,
        uint192 backingBuffer_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    // Give RToken max allowance over a registered token
    /// @custom:refresher
    /// @custom:interaction
    function grantRTokenAllowance(IERC20) external;

    /// Apply the overall backing policy using the specified TradeKind, taking a haircut if unable
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @custom:interaction RCEI
    function rebalance(TradeKind kind) external;

    /// Forward revenue to RevenueTraders; reverts if not fully collateralized
    /// @param erc20s The tokens to forward
    /// @custom:interaction RCEI
    function forwardRevenue(IERC20[] calldata erc20s) external;

    /// Structs for trading
    /// @param basketsHeld The number of baskets held by the BackingManager
    /// @return ctx The TradingContext
    /// @return reg Contents of AssetRegistry.getRegistry()
    function tradingContext(BasketRange memory basketsHeld)
        external
        view
        returns (TradingContext memory ctx, Registry memory reg);
}

interface TestIBackingManager is IBackingManager, TestITrading {
    function tradingDelay() external view returns (uint48);

    function backingBuffer() external view returns (uint192);

    function setTradingDelay(uint48 val) external;

    function setBackingBuffer(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";

struct BasketRange {
    uint192 bottom; // {BU}
    uint192 top; // {BU}
}

/**
 * @title IBasketHandler
 * @notice The BasketHandler aims to maintain a reference basket of constant target unit amounts.
 * When a collateral token defaults, a new reference basket of equal target units is set.
 * When _all_ collateral tokens default for a target unit, only then is the basket allowed to fall
 *   in terms of target unit amounts. The basket is considered defaulted in this case.
 */
interface IBasketHandler is IComponent {
    /// Emitted when the prime basket is set
    /// @param erc20s The collateral tokens for the prime basket
    /// @param targetAmts {target/BU} A list of quantities of target unit per basket unit
    /// @param targetNames Each collateral token's targetName
    event PrimeBasketSet(IERC20[] erc20s, uint192[] targetAmts, bytes32[] targetNames);

    /// Emitted when the reference basket is set
    /// @param nonce {basketNonce} The basket nonce
    /// @param erc20s The list of collateral tokens in the reference basket
    /// @param refAmts {ref/BU} The reference amounts of the basket collateral tokens
    /// @param disabled True when the list of erc20s + refAmts may not be correct
    event BasketSet(uint256 indexed nonce, IERC20[] erc20s, uint192[] refAmts, bool disabled);

    /// Emitted when a backup config is set for a target unit
    /// @param targetName The name of the target unit as a bytes32
    /// @param max The max number to use from `erc20s`
    /// @param erc20s The set of backup collateral tokens
    event BackupConfigSet(bytes32 indexed targetName, uint256 max, IERC20[] erc20s);

    /// Emitted when the warmup period is changed
    /// @param oldVal The old warmup period
    /// @param newVal The new warmup period
    event WarmupPeriodSet(uint48 oldVal, uint48 newVal);

    /// Emitted when the status of a basket has changed
    /// @param oldStatus The previous basket status
    /// @param newStatus The new basket status
    event BasketStatusChanged(CollateralStatus oldStatus, CollateralStatus newStatus);

    /// Emitted when the last basket nonce available for redemption is changed
    /// @param oldVal The old value of lastCollateralized
    /// @param newVal The new value of lastCollateralized
    event LastCollateralizedChanged(uint48 oldVal, uint48 newVal);

    // Initialization
    function init(
        IMain main_,
        uint48 warmupPeriod_,
        bool reweightable_
    ) external;

    /// Set the prime basket
    /// For an index RToken (reweightable = true), use forceSetPrimeBasket to skip normalization
    /// @param erc20s The collateral tokens for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    ///                   required range: 1e9 values; absolute range irrelevant.
    /// @custom:governance
    function setPrimeBasket(IERC20[] calldata erc20s, uint192[] calldata targetAmts) external;

    /// Set the prime basket without normalizing targetAmts by the UoA of the current basket
    /// Works the same as setPrimeBasket for non-index RTokens (reweightable = false)
    /// @param erc20s The collateral tokens for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    ///                   required range: 1e9 values; absolute range irrelevant.
    /// @custom:governance
    function forceSetPrimeBasket(IERC20[] calldata erc20s, uint192[] calldata targetAmts) external;

    /// Set the backup configuration for a given target
    /// @param targetName The name of the target as a bytes32
    /// @param max The maximum number of collateral tokens to use from this target
    ///            Required range: 1-255
    /// @param erc20s A list of ordered backup collateral tokens
    /// @custom:governance
    function setBackupConfig(
        bytes32 targetName,
        uint256 max,
        IERC20[] calldata erc20s
    ) external;

    /// Default the basket in order to schedule a basket refresh
    /// @custom:protected
    function disableBasket() external;

    /// Governance-controlled setter to cause a basket switch explicitly
    /// @custom:governance
    /// @custom:interaction
    function refreshBasket() external;

    /// Track the basket status changes
    /// @custom:refresher
    function trackStatus() external;

    /// Track when last collateralized
    /// @custom:refresher
    function trackCollateralization() external;

    /// @return If the BackingManager has sufficient collateral to redeem the entire RToken supply
    function fullyCollateralized() external view returns (bool);

    /// @return status The worst CollateralStatus of all collateral in the basket
    function status() external view returns (CollateralStatus status);

    /// @return If the basket is ready to issue and trade
    function isReady() external view returns (bool);

    /// @param erc20 The ERC20 token contract for the asset
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantity(IERC20 erc20) external view returns (uint192);

    /// Like quantity(), but unsafe because it DOES NOT CONFIRM THAT THE ASSET IS CORRECT
    /// @param erc20 The ERC20 token contract for the asset
    /// @param asset The registered asset plugin contract for the erc20
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantityUnsafe(IERC20 erc20, IAsset asset) external view returns (uint192);

    /// @param amount {BU}
    /// @return erc20s The addresses of the ERC20 tokens in the reference basket
    /// @return quantities {qTok} The quantity of each ERC20 token to issue `amount` baskets
    function quote(uint192 amount, RoundingMode rounding)
        external
        view
        returns (address[] memory erc20s, uint256[] memory quantities);

    /// Return the redemption value of `amount` BUs for a linear combination of historical baskets
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param amount {BU}
    /// @return erc20s The backing collateral erc20s
    /// @return quantities {qTok} ERC20 token quantities equal to `amount` BUs
    function quoteCustomRedemption(
        uint48[] memory basketNonces,
        uint192[] memory portions,
        uint192 amount
    ) external view returns (address[] memory erc20s, uint256[] memory quantities);

    /// @return top {BU} The number of partial basket units: e.g max(coll.map((c) => c.balAsBUs())
    ///         bottom {BU} The number of whole basket units held by the account
    function basketsHeldBy(address account) external view returns (BasketRange memory);

    /// Should not revert
    /// low should be nonzero when BUs are worth selling
    /// @return low {UoA/BU} The lower end of the price estimate
    /// @return high {UoA/BU} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero if a BU could be worth selling
    /// @dev Deprecated. Phased out in 3.1.0, but left on interface for backwards compatibility
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return timestamp The timestamp at which the basket was last set
    function timestamp() external view returns (uint48);

    /// @return The current basket nonce, regardless of status
    function nonce() external view returns (uint48);
}

interface TestIBasketHandler is IBasketHandler {
    function warmupPeriod() external view returns (uint48);

    function setWarmupPeriod(uint48 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IAsset.sol";
import "./IComponent.sol";
import "./IGnosis.sol";
import "./ITrade.sol";

enum TradeKind {
    DUTCH_AUCTION,
    BATCH_AUCTION
}

/// Cache of all prices for a pair to prevent re-lookup
struct TradePrices {
    uint192 sellLow; // {UoA/sellTok} can be 0
    uint192 sellHigh; // {UoA/sellTok} should not be 0
    uint192 buyLow; // {UoA/buyTok} should not be 0
    uint192 buyHigh; // {UoA/buyTok} should not be 0 or FIX_MAX
}

/// The data format that describes a request for trade with the Broker
struct TradeRequest {
    IAsset sell;
    IAsset buy;
    uint256 sellAmount; // {qSellTok}
    uint256 minBuyAmount; // {qBuyTok}
}

/**
 * @title IBroker
 * @notice The Broker deploys oneshot Trade contracts for Traders and monitors
 *   the continued proper functioning of trading platforms.
 */
interface IBroker is IComponent {
    event GnosisSet(IGnosis oldVal, IGnosis newVal);
    event BatchTradeImplementationSet(ITrade oldVal, ITrade newVal);
    event DutchTradeImplementationSet(ITrade oldVal, ITrade newVal);
    event BatchAuctionLengthSet(uint48 oldVal, uint48 newVal);
    event DutchAuctionLengthSet(uint48 oldVal, uint48 newVal);
    event BatchTradeDisabledSet(bool prevVal, bool newVal);
    event DutchTradeDisabledSet(IERC20Metadata indexed erc20, bool prevVal, bool newVal);

    // Initialization
    function init(
        IMain main_,
        IGnosis gnosis_,
        ITrade batchTradeImplemention_,
        uint48 batchAuctionLength_,
        ITrade dutchTradeImplemention_,
        uint48 dutchAuctionLength_
    ) external;

    /// Request a trade from the broker
    /// @dev Requires setting an allowance in advance
    /// @custom:interaction
    function openTrade(
        TradeKind kind,
        TradeRequest memory req,
        TradePrices memory prices
    ) external returns (ITrade);

    /// Only callable by one of the trading contracts the broker deploys
    function reportViolation() external;

    function batchTradeDisabled() external view returns (bool);

    function dutchTradeDisabled(IERC20Metadata erc20) external view returns (bool);
}

interface TestIBroker is IBroker {
    function gnosis() external view returns (IGnosis);

    function batchTradeImplementation() external view returns (ITrade);

    function dutchTradeImplementation() external view returns (ITrade);

    function batchAuctionLength() external view returns (uint48);

    function dutchAuctionLength() external view returns (uint48);

    function setGnosis(IGnosis newGnosis) external;

    function setBatchTradeImplementation(ITrade newTradeImplementation) external;

    function setBatchAuctionLength(uint48 newAuctionLength) external;

    function setDutchTradeImplementation(ITrade newTradeImplementation) external;

    function setDutchAuctionLength(uint48 newAuctionLength) external;

    function enableBatchTrade() external;

    function enableDutchTrade(IERC20Metadata erc20) external;

    // only present on pre-3.0.0 Brokers; used by EasyAuction regression test
    function disabled() external view returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IMain.sol";
import "./IVersioned.sol";

/**
 * @title IComponent
 * @notice A Component is the central building block of all our system contracts. Components
 *   contain important state that must be migrated during upgrades, and they delegate
 *   their ownership to Main's owner.
 */
interface IComponent is IVersioned {
    function main() external view returns (IMain);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";

uint256 constant MAX_DISTRIBUTION = 1e4; // 10,000
uint8 constant MAX_DESTINATIONS = 100; // maximum number of RevenueShare destinations

struct RevenueShare {
    uint16 rTokenDist; // {revShare} A value between [0, 10,000]
    uint16 rsrDist; // {revShare} A value between [0, 10,000]
}

/// Assumes no more than 100 independent distributions.
struct RevenueTotals {
    uint24 rTokenTotal; // {revShare}
    uint24 rsrTotal; // {revShare}
}

/**
 * @title IDistributor
 * @notice The Distributor Component maintains a revenue distribution table that dictates
 *   how to divide revenue across the Furnace, StRSR, and any other destinations.
 */
interface IDistributor is IComponent {
    /// Emitted when a distribution is set
    /// @param dest The address set to receive the distribution
    /// @param rTokenDist The distribution of RToken that should go to `dest`
    /// @param rsrDist The distribution of RSR that should go to `dest`
    event DistributionSet(address indexed dest, uint16 rTokenDist, uint16 rsrDist);

    /// Emitted when revenue is distributed
    /// @param erc20 The token being distributed, either RSR or the RToken itself
    /// @param source The address providing the revenue
    /// @param amount The amount of the revenue
    event RevenueDistributed(IERC20 indexed erc20, address indexed source, uint256 amount);

    // Initialization
    function init(IMain main_, RevenueShare memory dist) external;

    /// @custom:governance
    function setDistribution(address dest, RevenueShare memory share) external;

    /// Distribute the `erc20` token across all revenue destinations
    /// Only callable by RevenueTraders
    /// @custom:protected
    function distribute(IERC20 erc20, uint256 amount) external;

    /// @return revTotals The total of all  destinations
    function totals() external view returns (RevenueTotals memory revTotals);
}

interface TestIDistributor is IDistributor {
    // solhint-disable-next-line func-name-mixedcase
    function FURNACE() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function ST_RSR() external view returns (address);

    /// @return rTokenDist The RToken distribution for the address
    /// @return rsrDist The RSR distribution for the address
    function distribution(address) external view returns (uint16 rTokenDist, uint16 rsrDist);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "../libraries/Fixed.sol";
import "./IComponent.sol";

/**
 * @title IFurnace
 * @notice A helper contract to burn RTokens slowly and permisionlessly.
 */
interface IFurnace is IComponent {
    // Initialization
    function init(IMain main_, uint192 ratio_) external;

    /// Emitted when the melting ratio is changed
    /// @param oldRatio The old ratio
    /// @param newRatio The new ratio
    event RatioSet(uint192 oldRatio, uint192 newRatio);

    function ratio() external view returns (uint192);

    ///    Needed value range: [0, 1], granularity 1e-9
    /// @custom:governance
    function setRatio(uint192) external;

    /// Performs any RToken melting that has vested since the last payout.
    /// @custom:refresher
    function melt() external;
}

interface TestIFurnace is IFurnace {
    function lastPayout() external view returns (uint256);

    function lastPayoutBal() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct GnosisAuctionData {
    IERC20 auctioningToken;
    IERC20 biddingToken;
    uint256 orderCancellationEndDate;
    uint256 auctionEndDate;
    bytes32 initialAuctionOrder;
    uint256 minimumBiddingAmountPerOrder;
    uint256 interimSumBidAmount;
    bytes32 interimOrder;
    bytes32 clearingPriceOrder;
    uint96 volumeClearingPriceOrder;
    bool minFundingThresholdNotReached;
    bool isAtomicClosureAllowed;
    uint256 feeNumerator;
    uint256 minFundingThreshold;
}

/// The relevant portion of the interface of the live Gnosis EasyAuction contract
/// https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
interface IGnosis {
    function initiateAuction(
        IERC20 auctioningToken,
        IERC20 biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 auctionedSellAmount,
        uint96 minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256 auctionId);

    function auctionData(uint256 auctionId) external view returns (GnosisAuctionData memory);

    /// @param auctionId The external auction id
    /// @dev See here for decoding: https://git.io/JMang
    /// @return encodedOrder The order, encoded in a bytes 32
    function settleAuction(uint256 auctionId) external returns (bytes32 encodedOrder);

    /// @return The numerator over a 1000-valued denominator
    function feeNumerator() external returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IBasketHandler.sol";
import "./IBackingManager.sol";
import "./IBroker.sol";
import "./IGnosis.sol";
import "./IFurnace.sol";
import "./IDistributor.sol";
import "./IRToken.sol";
import "./IRevenueTrader.sol";
import "./IStRSR.sol";
import "./ITrading.sol";
import "./IVersioned.sol";

// === Auth roles ===

bytes32 constant OWNER = bytes32(bytes("OWNER"));
bytes32 constant SHORT_FREEZER = bytes32(bytes("SHORT_FREEZER"));
bytes32 constant LONG_FREEZER = bytes32(bytes("LONG_FREEZER"));
bytes32 constant PAUSER = bytes32(bytes("PAUSER"));

/**
 * Main is a central hub that maintains a list of Component contracts.
 *
 * Components:
 *   - perform a specific function
 *   - defer auth to Main
 *   - usually (but not always) contain sizeable state that require a proxy
 */
struct Components {
    // Definitely need proxy
    IRToken rToken;
    IStRSR stRSR;
    IAssetRegistry assetRegistry;
    IBasketHandler basketHandler;
    IBackingManager backingManager;
    IDistributor distributor;
    IFurnace furnace;
    IBroker broker;
    IRevenueTrader rsrTrader;
    IRevenueTrader rTokenTrader;
}

interface IAuth is IAccessControlUpgradeable {
    /// Emitted when `unfreezeAt` is changed
    /// @param oldVal The old value of `unfreezeAt`
    /// @param newVal The new value of `unfreezeAt`
    event UnfreezeAtSet(uint48 oldVal, uint48 newVal);

    /// Emitted when the short freeze duration governance param is changed
    /// @param oldDuration The old short freeze duration
    /// @param newDuration The new short freeze duration
    event ShortFreezeDurationSet(uint48 oldDuration, uint48 newDuration);

    /// Emitted when the long freeze duration governance param is changed
    /// @param oldDuration The old long freeze duration
    /// @param newDuration The new long freeze duration
    event LongFreezeDurationSet(uint48 oldDuration, uint48 newDuration);

    /// Emitted when the system is paused or unpaused for trading
    /// @param oldVal The old value of `tradingPaused`
    /// @param newVal The new value of `tradingPaused`
    event TradingPausedSet(bool oldVal, bool newVal);

    /// Emitted when the system is paused or unpaused for issuance
    /// @param oldVal The old value of `issuancePaused`
    /// @param newVal The new value of `issuancePaused`
    event IssuancePausedSet(bool oldVal, bool newVal);

    /**
     * Trading Paused: Disable everything except for OWNER actions, RToken.issue, RToken.redeem,
     * StRSR.stake, and StRSR.payoutRewards
     * Issuance Paused: Disable RToken.issue
     * Frozen: Disable everything except for OWNER actions + StRSR.stake (for governance)
     */

    function tradingPausedOrFrozen() external view returns (bool);

    function issuancePausedOrFrozen() external view returns (bool);

    function frozen() external view returns (bool);

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    // ====

    // onlyRole(OWNER)
    function freezeForever() external;

    // onlyRole(SHORT_FREEZER)
    function freezeShort() external;

    // onlyRole(LONG_FREEZER)
    function freezeLong() external;

    // onlyRole(OWNER)
    function unfreeze() external;

    function pauseTrading() external;

    function unpauseTrading() external;

    function pauseIssuance() external;

    function unpauseIssuance() external;
}

interface IComponentRegistry {
    // === Component setters/getters ===

    event RTokenSet(IRToken indexed oldVal, IRToken indexed newVal);

    function rToken() external view returns (IRToken);

    event StRSRSet(IStRSR oldVal, IStRSR newVal);

    function stRSR() external view returns (IStRSR);

    event AssetRegistrySet(IAssetRegistry oldVal, IAssetRegistry newVal);

    function assetRegistry() external view returns (IAssetRegistry);

    event BasketHandlerSet(IBasketHandler oldVal, IBasketHandler newVal);

    function basketHandler() external view returns (IBasketHandler);

    event BackingManagerSet(IBackingManager oldVal, IBackingManager newVal);

    function backingManager() external view returns (IBackingManager);

    event DistributorSet(IDistributor oldVal, IDistributor newVal);

    function distributor() external view returns (IDistributor);

    event RSRTraderSet(IRevenueTrader oldVal, IRevenueTrader newVal);

    function rsrTrader() external view returns (IRevenueTrader);

    event RTokenTraderSet(IRevenueTrader oldVal, IRevenueTrader newVal);

    function rTokenTrader() external view returns (IRevenueTrader);

    event FurnaceSet(IFurnace oldVal, IFurnace newVal);

    function furnace() external view returns (IFurnace);

    event BrokerSet(IBroker oldVal, IBroker newVal);

    function broker() external view returns (IBroker);
}

/**
 * @title IMain
 * @notice The central hub for the entire system. Maintains components and an owner singleton role
 */
interface IMain is IVersioned, IAuth, IComponentRegistry {
    function poke() external; // not used in p1

    // === Initialization ===

    event MainInitialized();

    function init(
        Components memory components,
        IERC20 rsr_,
        uint48 shortFreeze_,
        uint48 longFreeze_
    ) external;

    function rsr() external view returns (IERC20);
}

interface TestIMain is IMain {
    /// @custom:governance
    function setShortFreeze(uint48) external;

    /// @custom:governance
    function setLongFreeze(uint48) external;

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    function longFreezes(address account) external view returns (uint256);

    function tradingPaused() external view returns (bool);

    function issuancePaused() external view returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IBroker.sol";
import "./IComponent.sol";
import "./ITrading.sol";

/**
 * @title IRevenueTrader
 * @notice The RevenueTrader is an extension of the trading mixin that trades all
 *   assets at its address for a single target asset. There are two runtime instances
 *   of the RevenueTrader, 1 for RToken and 1 for RSR.
 */
interface IRevenueTrader is IComponent, ITrading {
    // Initialization
    function init(
        IMain main_,
        IERC20 tokenToBuy_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    /// Distribute tokenToBuy to its destinations
    /// @dev Special-case of manageTokens()
    /// @custom:interaction
    function distributeTokenToBuy() external;

    /// Return registered ERC20s to the BackingManager if distribution for tokenToBuy is 0
    /// @custom:interaction
    function returnTokens(IERC20[] memory erc20s) external;

    /// Process some number of tokens
    /// If the tokenToBuy is included in erc20s, RevenueTrader will distribute it at end of the tx
    /// @param erc20s The ERC20s to manage; can be tokenToBuy or anything registered
    /// @param kinds The kinds of auctions to launch: DUTCH_AUCTION | BATCH_AUCTION
    /// @custom:interaction
    function manageTokens(IERC20[] memory erc20s, TradeKind[] memory kinds) external;

    function tokenToBuy() external view returns (IERC20);
}

// solhint-disable-next-line no-empty-blocks
interface TestIRevenueTrader is IRevenueTrader, TestITrading {

}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IRewardable
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardable {
    /// Emitted whenever a reward token balance is claimed
    /// @param erc20 The ERC20 of the reward token
    /// @param amount {qTok}
    event RewardsClaimed(IERC20 indexed erc20, uint256 amount);

    /// Claim rewards earned by holding a balance of the ERC20 token
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewards() external;
}

/**
 * @title IRewardableComponent
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardableComponent is IRewardable {
    /// Claim rewards for a single ERC20
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewardsSingle(IERC20 erc20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../libraries/Fixed.sol";
import "../libraries/Throttle.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./IMain.sol";
import "./IRewardable.sol";

/**
 * @title IRToken
 * @notice An RToken is an ERC20 that is permissionlessly issuable/redeemable and tracks an
 *   exchange rate against a single unit: baskets, or {BU} in our type notation.
 */
interface IRToken is IComponent, IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    /// Emitted when an issuance of RToken occurs, whether it occurs via slow minting or not
    /// @param issuer The address holding collateral tokens
    /// @param recipient The address of the recipient of the RTokens
    /// @param amount The quantity of RToken being issued
    /// @param baskets The corresponding number of baskets
    event Issuance(
        address indexed issuer,
        address indexed recipient,
        uint256 amount,
        uint192 baskets
    );

    /// Emitted when a redemption of RToken occurs
    /// @param redeemer The address holding RToken
    /// @param recipient The address of the account receiving the backing collateral tokens
    /// @param amount The quantity of RToken being redeemed
    /// @param baskets The corresponding number of baskets
    /// @param amount {qRTok} The amount of RTokens canceled
    event Redemption(
        address indexed redeemer,
        address indexed recipient,
        uint256 amount,
        uint192 baskets
    );

    /// Emitted when the number of baskets needed changes
    /// @param oldBasketsNeeded Previous number of baskets units needed
    /// @param newBasketsNeeded New number of basket units needed
    event BasketsNeededChanged(uint192 oldBasketsNeeded, uint192 newBasketsNeeded);

    /// Emitted when RToken is melted, i.e the RToken supply is decreased but basketsNeeded is not
    /// @param amount {qRTok}
    event Melted(uint256 amount);

    /// Emitted when issuance SupplyThrottle params are set
    event IssuanceThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    /// Emitted when redemption SupplyThrottle params are set
    event RedemptionThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        string memory mandate_,
        ThrottleLib.Params calldata issuanceThrottleParams,
        ThrottleLib.Params calldata redemptionThrottleParams
    ) external;

    /// Issue an RToken with basket collateral
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issue(uint256 amount) external;

    /// Issue an RToken with basket collateral, to a particular recipient
    /// @param recipient The address to receive the issued RTokens
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issueTo(address recipient, uint256 amount) external;

    /// Redeem RToken for basket collateral
    /// @dev Use redeemCustom for non-current baskets
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeem(uint256 amount) external;

    /// Redeem RToken for basket collateral to a particular recipient
    /// @dev Use redeemCustom for non-current baskets
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeemTo(address recipient, uint256 amount) external;

    /// Redeem RToken for a linear combination of historical baskets, to a particular recipient
    /// @dev Allows partial redemptions up to the minAmounts
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param expectedERC20sOut An array of ERC20s expected out
    /// @param minAmounts {qTok} The minimum ERC20 quantities the caller should receive
    /// @custom:interaction
    function redeemCustom(
        address recipient,
        uint256 amount,
        uint48[] memory basketNonces,
        uint192[] memory portions,
        address[] memory expectedERC20sOut,
        uint256[] memory minAmounts
    ) external;

    /// Mint an amount of RToken equivalent to baskets BUs, scaling basketsNeeded up
    /// Callable only by BackingManager
    /// @param baskets {BU} The number of baskets to mint RToken for
    /// @custom:protected
    function mint(uint192 baskets) external;

    /// Melt a quantity of RToken from the caller's account
    /// @param amount {qRTok} The amount to be melted
    /// @custom:protected
    function melt(uint256 amount) external;

    /// Burn an amount of RToken from caller's account and scale basketsNeeded down
    /// Callable only by BackingManager
    /// @custom:protected
    function dissolve(uint256 amount) external;

    /// Set the number of baskets needed directly, callable only by the BackingManager
    /// @param basketsNeeded {BU} The number of baskets to target
    ///                      needed range: pretty interesting
    /// @custom:protected
    function setBasketsNeeded(uint192 basketsNeeded) external;

    /// @return {BU} How many baskets are being targeted
    function basketsNeeded() external view returns (uint192);

    /// @return {qRTok} The maximum issuance that can be performed in the current block
    function issuanceAvailable() external view returns (uint256);

    /// @return {qRTok} The maximum redemption that can be performed in the current block
    function redemptionAvailable() external view returns (uint256);
}

interface TestIRToken is IRToken {
    function setIssuanceThrottleParams(ThrottleLib.Params calldata) external;

    function setRedemptionThrottleParams(ThrottleLib.Params calldata) external;

    function issuanceThrottleParams() external view returns (ThrottleLib.Params memory);

    function redemptionThrottleParams() external view returns (ThrottleLib.Params memory);

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    function monetizeDonations(IERC20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../libraries/Fixed.sol";
import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IStRSR
 * @notice An ERC20 token representing shares of the RSR over-collateralization pool.
 *
 * StRSR permits the BackingManager to take RSR in times of need. In return, the BackingManager
 * benefits the StRSR pool with RSR rewards purchased with a portion of its revenue.
 *
 * In the absence of collateral default or losses due to slippage, StRSR should have a
 * monotonically increasing exchange rate with respect to RSR, meaning that over time
 * StRSR is redeemable for more RSR. It is non-rebasing.
 */
interface IStRSR is IERC20MetadataUpgradeable, IERC20PermitUpgradeable, IComponent {
    /// Emitted when RSR is staked
    /// @param era The era at time of staking
    /// @param staker The address of the staker
    /// @param rsrAmount {qRSR} How much RSR was staked
    /// @param stRSRAmount {qStRSR} How much stRSR was minted by this staking
    event Staked(
        uint256 indexed era,
        address indexed staker,
        uint256 rsrAmount,
        uint256 stRSRAmount
    );

    /// Emitted when an unstaking is started
    /// @param draftId The id of the draft.
    /// @param draftEra The era of the draft.
    /// @param staker The address of the unstaker
    ///   The triple (staker, draftEra, draftId) is a unique ID
    /// @param rsrAmount {qRSR} How much RSR this unstaking will be worth, absent seizures
    /// @param stRSRAmount {qStRSR} How much stRSR was burned by this unstaking
    event UnstakingStarted(
        uint256 indexed draftId,
        uint256 indexed draftEra,
        address indexed staker,
        uint256 rsrAmount,
        uint256 stRSRAmount,
        uint256 availableAt
    );

    /// Emitted when RSR is unstaked
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCompleted(
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 draftEra,
        address indexed staker,
        uint256 rsrAmount
    );

    /// Emitted when RSR unstaking is cancelled
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCancelled(
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 draftEra,
        address indexed staker,
        uint256 rsrAmount
    );

    /// Emitted whenever the exchange rate changes
    event ExchangeRateSet(uint192 oldVal, uint192 newVal);

    /// Emitted whenever RSR are paids out
    event RewardsPaid(uint256 rsrAmt);

    /// Emitted if all the RSR in the staking pool is seized and all balances are reset to zero.
    event AllBalancesReset(uint256 indexed newEra);
    /// Emitted if all the RSR in the unstakin pool is seized, and all ongoing unstaking is voided.
    event AllUnstakingReset(uint256 indexed newEra);

    event UnstakingDelaySet(uint48 oldVal, uint48 newVal);
    event RewardRatioSet(uint192 oldVal, uint192 newVal);
    event WithdrawalLeakSet(uint192 oldVal, uint192 newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        uint48 unstakingDelay_,
        uint192 rewardRatio_,
        uint192 withdrawalLeak_
    ) external;

    /// Gather and payout rewards from rsrTrader
    /// @custom:interaction
    function payoutRewards() external;

    /// Stakes an RSR `amount` on the corresponding RToken to earn yield and over-collateralized
    /// the system
    /// @param amount {qRSR}
    /// @custom:interaction
    function stake(uint256 amount) external;

    /// Begins a delayed unstaking for `amount` stRSR
    /// @param amount {qStRSR}
    /// @custom:interaction
    function unstake(uint256 amount) external;

    /// Complete delayed unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function withdraw(address account, uint256 endId) external;

    /// Cancel unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function cancelUnstake(uint256 endId) external;

    /// Seize RSR, only callable by main.backingManager()
    /// @custom:protected
    function seizeRSR(uint256 amount) external;

    /// Reset all stakes and advance era
    /// @custom:governance
    function resetStakes() external;

    /// Return the maximum valid value of endId such that withdraw(endId) should immediately work
    function endIdForWithdraw(address account) external view returns (uint256 endId);

    /// @return {qRSR/qStRSR} The exchange rate between RSR and StRSR
    function exchangeRate() external view returns (uint192);
}

interface TestIStRSR is IStRSR {
    function rewardRatio() external view returns (uint192);

    function setRewardRatio(uint192) external;

    function unstakingDelay() external view returns (uint48);

    function setUnstakingDelay(uint48) external;

    function withdrawalLeak() external view returns (uint192);

    function setWithdrawalLeak(uint192) external;

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    /// @return {qStRSR/qRSR} The exchange rate between StRSR and RSR
    function exchangeRate() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IBroker.sol";
import "./IVersioned.sol";

enum TradeStatus {
    NOT_STARTED, // before init()
    OPEN, // after init() and before settle()
    CLOSED, // after settle()
    // === Intermediate-tx state ===
    PENDING // during init() or settle() (reentrancy protection)
}

/**
 * Simple generalized trading interface for all Trade contracts to obey
 *
 * Usage: if (canSettle()) settle()
 */
interface ITrade is IVersioned {
    /// Complete the trade and transfer tokens back to the origin trader
    /// @return soldAmt {qSellTok} The quantity of tokens sold
    /// @return boughtAmt {qBuyTok} The quantity of tokens bought
    function settle() external returns (uint256 soldAmt, uint256 boughtAmt);

    function sell() external view returns (IERC20Metadata);

    function buy() external view returns (IERC20Metadata);

    /// @return {tok} The sell amount of the trade, in whole tokens
    function sellAmount() external view returns (uint192);

    /// @return The timestamp at which the trade is projected to become settle-able
    function endTime() external view returns (uint48);

    /// @return True if the trade can be settled
    /// @dev Should be guaranteed to be true eventually as an invariant
    function canSettle() external view returns (bool);

    /// @return TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    // solhint-disable-next-line func-name-mixedcase
    function KIND() external view returns (TradeKind);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./ITrade.sol";
import "./IRewardable.sol";

/**
 * @title ITrading
 * @notice Common events and refresher function for all Trading contracts
 */
interface ITrading is IComponent, IRewardableComponent {
    event MaxTradeSlippageSet(uint192 oldVal, uint192 newVal);
    event MinTradeVolumeSet(uint192 oldVal, uint192 newVal);

    /// Emitted when a trade is started
    /// @param trade The one-time-use trade contract that was just deployed
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the selling token
    /// @param minBuyAmount {qBuyTok} The minimum quantity of the buying token to accept
    event TradeStarted(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    /// Emitted after a trade ends
    /// @param trade The one-time-use trade contract
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the token sold
    /// @param buyAmount {qBuyTok} The quantity of the token bought
    event TradeSettled(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 buyAmount
    );

    /// Settle a single trade, expected to be used with multicall for efficient mass settlement
    /// @param sell The sell token in the trade
    /// @return The trade settled
    /// @custom:refresher
    function settleTrade(IERC20 sell) external returns (ITrade);

    /// @return {%} The maximum trade slippage acceptable
    function maxTradeSlippage() external view returns (uint192);

    /// @return {UoA} The minimum trade volume in UoA, applies to all assets
    function minTradeVolume() external view returns (uint192);

    /// @return The ongoing trade for a sell token, or the zero address
    function trades(IERC20 sell) external view returns (ITrade);

    /// @return The number of ongoing trades open
    function tradesOpen() external view returns (uint48);

    /// @return The number of total trades ever opened
    function tradesNonce() external view returns (uint256);
}

interface TestITrading is ITrading {
    /// @custom:governance
    function setMaxTradeSlippage(uint192 val) external;

    /// @custom:governance
    function setMinTradeVolume(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

interface IVersioned {
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

interface IERC20ApproveOnly {
    function approve(address spender, uint256 value) external;

    function allowance(address owner, address spender) external view returns (uint256);
}

library AllowanceLib {
    /// An approve helper that:
    ///   1. Sets initial allowance to 0
    ///   2. Tries to set the provided allowance
    ///   3. Falls back to setting a maximum allowance, if (2) fails
    /// Context: Some new-age ERC20s think it's a good idea to revert for allowances
    /// that are > 0 but < type(uint256).max.
    function safeApproveFallbackToMax(
        address tokenAddress,
        address spender,
        uint256 value
    ) internal {
        IERC20ApproveOnly token = IERC20ApproveOnly(tokenAddress);

        // 1. Set initial allowance to 0
        token.approve(spender, 0);
        require(token.allowance(address(this), spender) == 0, "allowance not 0");

        if (value == 0) return;

        // 2. Try to set the provided allowance
        bool success; // bool success = false;
        try token.approve(spender, value) {
            success = token.allowance(address(this), spender) == value;
            // solhint-disable-next-line no-empty-blocks
        } catch {}

        // 3. Fall-back to setting a maximum allowance
        if (!success) {
            token.approve(spender, type(uint256).max);
            require(token.allowance(address(this), spender) >= value, "allowance missing");
        }
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ArrayLib {
    /// O(n^2)
    /// @return If the array contains all unique addresses
    function allUnique(IERC20[] memory arr) internal pure returns (bool) {
        uint256 arrLen = arr.length;
        for (uint256 i = 1; i < arrLen; ++i) {
            for (uint256 j = 0; j < i; ++j) {
                if (arr[i] == arr[j]) return false;
            }
        }
        return true;
    }

    /// O(n) -- must already be in sorted ascending order!
    /// @return If the array contains all unique addresses, in ascending order
    function sortedAndAllUnique(IERC20[] memory arr) internal pure returns (bool) {
        uint256 arrLen = arr.length;
        for (uint256 i = 1; i < arrLen; ++i) {
            if (uint160(address(arr[i])) <= uint160(address(arr[i - 1]))) return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
// solhint-disable func-name-mixedcase func-visibility
// slither-disable-start divide-before-multiply
pragma solidity ^0.8.19;

/// @title FixedPoint, a fixed-point arithmetic library defining the custom type uint192
/// @author Matt Elder <[email protected]> and the Reserve Team <https://reserve.org>

/** The logical type `uint192 ` is a 192 bit value, representing an 18-decimal Fixed-point
    fractional value.  This is what's described in the Solidity documentation as
    "fixed192x18" -- a value represented by 192 bits, that makes 18 digits available to
    the right of the decimal point.

    The range of values that uint192 can represent is about [-1.7e20, 1.7e20].
    Unless a function explicitly says otherwise, it will fail on overflow.
    To be clear, the following should hold:
    toFix(0) == 0
    toFix(1) == 1e18
*/

// Analysis notes:
//   Every function should revert iff its result is out of bounds.
//   Unless otherwise noted, when a rounding mode is given, that mode is applied to
//     a single division that may happen as the last step in the computation.
//   Unless otherwise noted, when a rounding mode is *not* given but is needed, it's FLOOR.
//   For each, we comment:
//   - @return is the value expressed  in "value space", where uint192(1e18) "is" 1.0
//   - as-ints: is the value expressed in "implementation space", where uint192(1e18) "is" 1e18
//   The "@return" expression is suitable for actually using the library
//   The "as-ints" expression is suitable for testing

// A uint value passed to this library was out of bounds for uint192 operations
error UIntOutOfBounds();
bytes32 constant UIntOutofBoundsHash = keccak256(abi.encodeWithSignature("UIntOutOfBounds()"));

// Used by P1 implementation for easier casting
uint256 constant FIX_ONE_256 = 1e18;
uint8 constant FIX_DECIMALS = 18;

// If a particular uint192 is represented by the uint192 n, then the uint192 represents the
// value n/FIX_SCALE.
uint64 constant FIX_SCALE = 1e18;

// FIX_SCALE Squared:
uint128 constant FIX_SCALE_SQ = 1e36;

// The largest integer that can be converted to uint192 .
// This is a bit bigger than 3.1e39
uint192 constant FIX_MAX_INT = type(uint192).max / FIX_SCALE;

uint192 constant FIX_ZERO = 0; // The uint192 representation of zero.
uint192 constant FIX_ONE = FIX_SCALE; // The uint192 representation of one.
uint192 constant FIX_MAX = type(uint192).max; // The largest uint192. (Not an integer!)
uint192 constant FIX_MIN = 0; // The smallest uint192.

/// An enum that describes a rounding approach for converting to ints
enum RoundingMode {
    FLOOR, // Round towards zero
    ROUND, // Round to the nearest int
    CEIL // Round away from zero
}

RoundingMode constant FLOOR = RoundingMode.FLOOR;
RoundingMode constant ROUND = RoundingMode.ROUND;
RoundingMode constant CEIL = RoundingMode.CEIL;

/* @dev Solidity 0.8.x only allows you to change one of type or size per type conversion.
   Thus, all the tedious-looking double conversions like uint256(uint256 (foo))
   See: https://docs.soliditylang.org/en/v0.8.17/080-breaking-changes.html#new-restrictions
 */

/// Explicitly convert a uint256 to a uint192. Revert if the input is out of bounds.
function _safeWrap(uint256 x) pure returns (uint192) {
    if (FIX_MAX < x) revert UIntOutOfBounds();
    return uint192(x);
}

/// Convert a uint to its Fix representation.
/// @return x
// as-ints: x * 1e18
function toFix(uint256 x) pure returns (uint192) {
    return _safeWrap(x * FIX_SCALE);
}

/// Convert a uint to its fixed-point representation, and left-shift its value `shiftLeft`
/// decimal digits.
/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(uint256 x, int8 shiftLeft) pure returns (uint192) {
    return shiftl_toFix(x, shiftLeft, FLOOR);
}

/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(
    uint256 x,
    int8 shiftLeft,
    RoundingMode rounding
) pure returns (uint192) {
    // conditions for avoiding overflow
    if (x == 0) return 0;
    if (shiftLeft <= -96) return (rounding == CEIL ? 1 : 0); // 0 < uint.max / 10**77 < 0.5
    if (40 <= shiftLeft) revert UIntOutOfBounds(); // 10**56 < FIX_MAX < 10**57

    shiftLeft += 18;

    uint256 coeff = 10**abs(shiftLeft);
    uint256 shifted = (shiftLeft >= 0) ? x * coeff : _divrnd(x, coeff, rounding);

    return _safeWrap(shifted);
}

/// Divide a uint by a uint192, yielding a uint192
/// This may also fail if the result is MIN_uint192! not fixing this for optimization's sake.
/// @return x / y
// as-ints: x * 1e36 / y
function divFix(uint256 x, uint192 y) pure returns (uint192) {
    // If we didn't have to worry about overflow, we'd just do `return x * 1e36 / _y`
    // If it's safe to do this operation the easy way, do it:
    if (x < uint256(type(uint256).max / FIX_SCALE_SQ)) {
        return _safeWrap(uint256(x * FIX_SCALE_SQ) / y);
    } else {
        return _safeWrap(mulDiv256(x, FIX_SCALE_SQ, y));
    }
}

/// Divide a uint by a uint, yielding a  uint192
/// @return x / y
// as-ints: x * 1e18 / y
function divuu(uint256 x, uint256 y) pure returns (uint192) {
    return _safeWrap(mulDiv256(FIX_SCALE, x, y));
}

/// @return min(x,y)
// as-ints: min(x,y)
function fixMin(uint192 x, uint192 y) pure returns (uint192) {
    return x < y ? x : y;
}

/// @return max(x,y)
// as-ints: max(x,y)
function fixMax(uint192 x, uint192 y) pure returns (uint192) {
    return x > y ? x : y;
}

/// @return absoluteValue(x,y)
// as-ints: absoluteValue(x,y)
function abs(int256 x) pure returns (uint256) {
    return x < 0 ? uint256(-x) : uint256(x);
}

/// Divide two uints, returning a uint, using rounding mode `rounding`.
/// @return numerator / divisor
// as-ints: numerator / divisor
function _divrnd(
    uint256 numerator,
    uint256 divisor,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = numerator / divisor;

    if (rounding == FLOOR) return result;

    if (rounding == ROUND) {
        if (numerator % divisor > (divisor - 1) / 2) {
            result++;
        }
    } else {
        if (numerator % divisor > 0) {
            result++;
        }
    }

    return result;
}

library FixLib {
    /// Again, all arithmetic functions fail if and only if the result is out of bounds.

    /// Convert this fixed-point value to a uint. Round towards zero if needed.
    /// @return x
    // as-ints: x / 1e18
    function toUint(uint192 x) internal pure returns (uint136) {
        return toUint(x, FLOOR);
    }

    /// Convert this uint192 to a uint
    /// @return x
    // as-ints: x / 1e18 with rounding
    function toUint(uint192 x, RoundingMode rounding) internal pure returns (uint136) {
        return uint136(_divrnd(uint256(x), FIX_SCALE, rounding));
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(uint192 x, int8 decimals) internal pure returns (uint192) {
        return shiftl(x, decimals, FLOOR);
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Handle overflow cases
        if (x == 0) return 0;
        if (decimals <= -59) return (rounding == CEIL ? 1 : 0); // 59, because 1e58 > 2**192
        if (58 <= decimals) revert UIntOutOfBounds(); // 58, because x * 1e58 > 2 ** 192 if x != 0

        uint256 coeff = uint256(10**abs(decimals));
        return _safeWrap(decimals >= 0 ? x * coeff : _divrnd(x, coeff, rounding));
    }

    /// Add a uint192 to this uint192
    /// @return x + y
    // as-ints: x + y
    function plus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x + y;
    }

    /// Add a uint to this uint192
    /// @return x + y
    // as-ints: x + y*1e18
    function plusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x + y * FIX_SCALE);
    }

    /// Subtract a uint192 from this uint192
    /// @return x - y
    // as-ints: x - y
    function minus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x - y;
    }

    /// Subtract a uint from this uint192
    /// @return x - y
    // as-ints: x - y*1e18
    function minusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(uint256(x) - uint256(y * FIX_SCALE));
    }

    /// Multiply this uint192 by a uint192
    /// Round truncated values to the nearest available value. 5e-19 rounds away from zero.
    /// @return x * y
    // as-ints: x * y/1e18  [division using ROUND, not FLOOR]
    function mul(uint192 x, uint192 y) internal pure returns (uint192) {
        return mul(x, y, ROUND);
    }

    /// Multiply this uint192 by a uint192
    /// @return x * y
    // as-ints: x * y/1e18
    function mul(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(uint256(x) * uint256(y), FIX_SCALE, rounding));
    }

    /// Multiply this uint192 by a uint
    /// @return x * y
    // as-ints: x * y
    function mulu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x * y);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(uint192 x, uint192 y) internal pure returns (uint192) {
        return div(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Multiply-in FIX_SCALE before dividing by y to preserve precision.
        return _safeWrap(_divrnd(uint256(x) * FIX_SCALE, y, rounding));
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(uint192 x, uint256 y) internal pure returns (uint192) {
        return divu(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(x, y, rounding));
    }

    uint64 constant FIX_HALF = uint64(FIX_SCALE) / 2;

    /// Raise this uint192 to a nonnegative integer power. Requires that x_ <= FIX_ONE
    /// Gas cost is O(lg(y)), precision is +- 1e-18.
    /// @return x_ ** y
    // as-ints: x_ ** y / 1e18**(y-1)    <- technically correct for y = 0. :D
    function powu(uint192 x_, uint48 y) internal pure returns (uint192) {
        require(x_ <= FIX_ONE);
        if (y == 1) return x_;
        if (x_ == FIX_ONE || y == 0) return FIX_ONE;
        uint256 x = uint256(x_) * FIX_SCALE; // x is D36
        uint256 result = FIX_SCALE_SQ; // result is D36
        while (true) {
            if (y & 1 == 1) result = (result * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
            if (y <= 1) break;
            y = (y >> 1);
            x = (x * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
        }
        return _safeWrap(result / FIX_SCALE);
    }

    /// Comparison operators...
    function lt(uint192 x, uint192 y) internal pure returns (bool) {
        return x < y;
    }

    function lte(uint192 x, uint192 y) internal pure returns (bool) {
        return x <= y;
    }

    function gt(uint192 x, uint192 y) internal pure returns (bool) {
        return x > y;
    }

    function gte(uint192 x, uint192 y) internal pure returns (bool) {
        return x >= y;
    }

    function eq(uint192 x, uint192 y) internal pure returns (bool) {
        return x == y;
    }

    function neq(uint192 x, uint192 y) internal pure returns (bool) {
        return x != y;
    }

    /// Return whether or not this uint192 is less than epsilon away from y.
    /// @return |x - y| < epsilon
    // as-ints: |x - y| < epsilon
    function near(
        uint192 x,
        uint192 y,
        uint192 epsilon
    ) internal pure returns (bool) {
        uint192 diff = x <= y ? y - x : x - y;
        return diff < epsilon;
    }

    // ================ Chained Operations ================
    // The operation foo_bar() always means:
    //   Do foo() followed by bar(), and overflow only if the _end_ result doesn't fit in an uint192

    /// Shift this uint192 left by `decimals` digits, and convert to a uint
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(uint192 x, int8 decimals) internal pure returns (uint256) {
        return shiftl_toUint(x, decimals, FLOOR);
    }

    /// Shift this uint192 left by `decimals` digits, and convert to a uint.
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        // Handle overflow cases
        if (x == 0) return 0; // always computable, no matter what decimals is
        if (decimals <= -42) return (rounding == CEIL ? 1 : 0);
        if (96 <= decimals) revert UIntOutOfBounds();

        decimals -= 18; // shift so that toUint happens at the same time.

        uint256 coeff = uint256(10**abs(decimals));
        return decimals >= 0 ? uint256(x * coeff) : uint256(_divrnd(x, coeff, rounding));
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(uint192 x, uint256 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE);
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE, rounding);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(uint192 x, uint192 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ, rounding);
    }

    /// Compute x * y / z avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint192) {
        return muluDivu(x, y, z, FLOOR);
    }

    /// Compute x * y / z, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z
    ) internal pure returns (uint192) {
        return mulDiv(x, y, z, FLOOR);
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    // === safe*() ===

    /// Multiply two fixes, rounding up to FIX_MAX and down to 0
    /// @param a First param to multiply
    /// @param b Second param to multiply
    function safeMul(
        uint192 a,
        uint192 b,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // untestable:
        //      a will never = 0 here because of the check in _price()
        if (a == 0 || b == 0) return 0;
        // untestable:
        //      a = FIX_MAX iff b = 0
        if (a == FIX_MAX || b == FIX_MAX) return FIX_MAX;

        // return FIX_MAX instead of throwing overflow errors.
        unchecked {
            // p and mul *are* Fix values, so have 18 decimals (D18)
            uint256 rawDelta = uint256(b) * a; // {D36} = {D18} * {D18}
            // if we overflowed, then return FIX_MAX
            if (rawDelta / b != a) return FIX_MAX;
            uint256 shiftDelta = rawDelta;

            // add in rounding
            if (rounding == RoundingMode.ROUND) shiftDelta += (FIX_ONE / 2);
            else if (rounding == RoundingMode.CEIL) shiftDelta += FIX_ONE - 1;

            // untestable (here there be dragons):
            // (below explanation is for the ROUND case, but it extends to the FLOOR/CEIL too)
            //          A)  shiftDelta = rawDelta + (FIX_ONE / 2)
            //      shiftDelta overflows if:
            //          B)  shiftDelta = MAX_UINT256 - FIX_ONE/2 + 1
            //              rawDelta + (FIX_ONE/2) = MAX_UINT256 - FIX_ONE/2 + 1
            //              b * a = MAX_UINT256 - FIX_ONE + 1
            //      therefore shiftDelta overflows if:
            //          C)  b = (MAX_UINT256 - FIX_ONE + 1) / a
            //      MAX_UINT256 ~= 1e77 , FIX_MAX ~= 6e57 (6e20 difference in magnitude)
            //      a <= 1e21 (MAX_TARGET_AMT)
            //      a must be between 1e19 & 1e20 in order for b in (C) to be uint192,
            //      but a would have to be < 1e18 in order for (A) to overflow
            if (shiftDelta < rawDelta) return FIX_MAX;

            // return FIX_MAX if return result would truncate
            if (shiftDelta / FIX_ONE > FIX_MAX) return FIX_MAX;

            // return _div(rawDelta, FIX_ONE, rounding)
            return uint192(shiftDelta / FIX_ONE); // {D18} = {D36} / {D18}
        }
    }

    /// Divide two fixes, rounding up to FIX_MAX and down to 0
    /// @param a Numerator
    /// @param b Denominator
    function safeDiv(
        uint192 a,
        uint192 b,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        if (a == 0) return 0;
        if (b == 0) return FIX_MAX;

        uint256 raw = _divrnd(FIX_ONE_256 * a, uint256(b), rounding);
        if (raw >= FIX_MAX) return FIX_MAX;
        return uint192(raw); // don't need _safeWrap
    }

    /// Multiplies two fixes and divide by a third
    /// @param a First to multiply
    /// @param b Second to multiply
    /// @param c Denominator
    function safeMulDiv(
        uint192 a,
        uint192 b,
        uint192 c,
        RoundingMode rounding
    ) internal pure returns (uint192 result) {
        if (a == 0 || b == 0) return 0;
        if (a == FIX_MAX || b == FIX_MAX || c == 0) return FIX_MAX;

        uint256 result_256;
        unchecked {
            (uint256 hi, uint256 lo) = fullMul(a, b);
            if (hi >= c) return FIX_MAX;
            uint256 mm = mulmod(a, b, c);
            if (mm > lo) hi -= 1;
            lo -= mm;
            uint256 pow2 = c & (0 - c);

            uint256 c_256 = uint256(c);
            // Warning: Should not access c below this line

            c_256 /= pow2;
            lo /= pow2;
            lo += hi * ((0 - pow2) / pow2 + 1);
            uint256 r = 1;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            result_256 = lo * r;

            // Apply rounding
            if (rounding == CEIL) {
                if (mm > 0) result_256 += 1;
            } else if (rounding == ROUND) {
                if (mm > ((c_256 - 1) / 2)) result_256 += 1;
            }
        }

        if (result_256 >= FIX_MAX) return FIX_MAX;
        return uint192(result_256);
    }
}

// ================ a couple pure-uint helpers================
// as-ints comments are omitted here, because they're the same as @return statements, because
// these are all pure uint functions

/// Return (x*y/z), avoiding intermediate overflow.
//  Adapted from sources:
//    https://medium.com/coinmonks/4db014e080b1, https://medium.com/wicketh/afa55870a65
//    and quite a few of the other excellent "Mathemagic" posts from https://medium.com/wicketh
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return result x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256 result) {
    unchecked {
        (uint256 hi, uint256 lo) = fullMul(x, y);
        if (hi >= z) revert UIntOutOfBounds();
        uint256 mm = mulmod(x, y, z);
        if (mm > lo) hi -= 1;
        lo -= mm;
        uint256 pow2 = z & (0 - z);
        z /= pow2;
        lo /= pow2;
        lo += hi * ((0 - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        result = lo * r;
    }
}

/// Return (x*y/z), avoiding intermediate overflow.
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = mulDiv256(x, y, z);
    if (rounding == FLOOR) return result;

    uint256 mm = mulmod(x, y, z);
    if (rounding == CEIL) {
        if (mm > 0) result += 1;
    } else {
        if (mm > ((z - 1) / 2)) result += 1; // z should be z-1
    }
    return result;
}

/// Return (x*y) as a "virtual uint512" (lo, hi), representing (hi*2**256 + lo)
///   Adapted from sources:
///   https://medium.com/wicketh/27650fec525d, https://medium.com/coinmonks/4db014e080b1
/// @dev Intended to be internal to this library
/// @return hi (hi, lo) satisfies  hi*(2**256) + lo == x * y
/// @return lo (paired with `hi`)
function fullMul(uint256 x, uint256 y) pure returns (uint256 hi, uint256 lo) {
    unchecked {
        uint256 mm = mulmod(x, y, uint256(0) - uint256(1));
        lo = x * y;
        hi = mm - lo;
        if (mm < lo) hi -= 1;
    }
}
// slither-disable-end divide-before-multiply

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
}

ArbSys constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064); // arb precompile

/**
 * @title NetworkConfigLib
 * @notice Provides network-specific configuration parameters
 */
library NetworkConfigLib {
    error InvalidNetwork();

    // Returns the blocktime based on the current network (e.g. 12s for Ethereum PoS)
    // See docs/system-design.md for discussion of handling longer or shorter times
    /// @dev Round up to 1 if block time <1s
    function blocktime() internal view returns (uint48) {
        uint256 chainId = block.chainid;
        // untestable:
        //    most of the branches will be shown as uncovered, because we only run coverage
        //    on local Ethereum PoS network (31337). Manual testing was performed.
        if (chainId == 1 || chainId == 3 || chainId == 5 || chainId == 31337) {
            return 12; // Ethereum PoS, Goerli, HH (tests)
        } else if (chainId == 8453 || chainId == 84531) {
            return 2; // Base, Base Goerli
        } else if (chainId == 42161 || chainId == 421614) {
            return 1; // round up to 1 even though Arbitrum is ~0.26s
        } else {
            revert InvalidNetwork();
        }
    }

    // Returns the current blocknumber based on the current network
    // Some L2s such as Arbitrum have special-cased their block number function
    function blockNumber() internal view returns (uint256) {
        // untestable:
        //    most of the branches will be shown as uncovered, because we only run coverage
        //    on local Ethereum PoS network (31337). Manual testing was performed.
        if (block.chainid == 42161 || block.chainid == 421614) {
            return ARB_SYS.arbBlockNumber(); // use arbitrum precompile
        } else {
            return block.number;
        }
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./Fixed.sol";

uint48 constant ONE_HOUR = 3600; // {seconds/hour}

/**
 * @title ThrottleLib
 * A library that implements a usage throttle that can be used to ensure net issuance
 * or net redemption for an RToken never exceeds some bounds per unit time (hour).
 *
 * It is expected for the RToken to use this library with two instances, one for issuance
 * and one for redemption. Issuance causes the available redemption amount to increase, and
 * visa versa.
 */
library ThrottleLib {
    using FixLib for uint192;

    struct Params {
        uint256 amtRate; // {qRTok/hour} a quantity of RToken hourly; cannot be 0
        uint192 pctRate; // {1/hour} a fraction of RToken hourly; can be 0
    }

    struct Throttle {
        // === Gov params ===
        Params params;
        // === Cache ===
        uint48 lastTimestamp; // {seconds}
        uint256 lastAvailable; // {qRTok}
    }

    /// Reverts if usage amount exceeds available amount
    /// @param supply {qRTok} Total RToken supply beforehand
    /// @param amount {qRTok} Amount of RToken to use. Should be negative for the issuance
    ///   throttle during redemption and for the redemption throttle during issuance.
    function useAvailable(
        Throttle storage throttle,
        uint256 supply,
        int256 amount
    ) internal {
        // untestable: amtRate will always be greater > 0 due to previous validations
        if (throttle.params.amtRate == 0 && throttle.params.pctRate == 0) return;

        // Calculate hourly limit
        uint256 limit = hourlyLimit(throttle, supply); // {qRTok}

        // Calculate available amount before supply change
        uint256 available = currentlyAvailable(throttle, limit);

        // Update throttle.timestamp if available amount changed or at limit
        if (available != throttle.lastAvailable || available == limit) {
            throttle.lastTimestamp = uint48(block.timestamp);
        }

        // Update throttle.lastAvailable
        if (amount > 0) {
            require(uint256(amount) <= available, "supply change throttled");
            available -= uint256(amount);
            // untestable: the final else statement, amount will never be 0
        } else if (amount < 0) {
            available += uint256(-amount);
        }
        throttle.lastAvailable = available;
    }

    /// @param limit {qRTok/hour} The hourly limit
    /// @return available {qRTok} Amount currently available for consumption
    function currentlyAvailable(Throttle storage throttle, uint256 limit)
        internal
        view
        returns (uint256 available)
    {
        uint48 delta = uint48(block.timestamp) - throttle.lastTimestamp; // {seconds}
        available = throttle.lastAvailable + (limit * delta) / ONE_HOUR;
        if (available > limit) available = limit;
    }

    /// @return limit {qRTok} The hourly limit
    function hourlyLimit(Throttle storage throttle, uint256 supply)
        internal
        view
        returns (uint256 limit)
    {
        Params storage params = throttle.params;

        // Calculate hourly limit as: max(params.amtRate, supply.mul(params.pctRate))
        limit = (supply * params.pctRate) / FIX_ONE_256; // {qRTok}
        if (params.amtRate > limit) limit = params.amtRate;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "../interfaces/IVersioned.sol";

// This value should be updated on each release
string constant VERSION = "3.4.0";

/**
 * @title Versioned
 * @notice A mix-in to track semantic versioning uniformly across contracts.
 */
abstract contract Versioned is IVersioned {
    function version() public pure virtual override returns (string memory) {
        return VERSION;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IBackingManager.sol";
import "../interfaces/IMain.sol";
import "../libraries/Array.sol";
import "../libraries/Fixed.sol";
import "../libraries/NetworkConfigLib.sol";
import "./mixins/Trading.sol";
import "./mixins/RecollateralizationLib.sol";

/**
 * @title BackingManager
 * @notice The backing manager holds + manages the backing for an RToken
 */

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract BackingManagerP1 is TradingP1, IBackingManager {
    using FixLib for uint192;
    using SafeERC20 for IERC20;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    // solhint-disable-next-line var-name-mixedcase
    uint48 public immutable ONE_BLOCK; // {s} 1 block based on network

    // Cache of peer components
    IAssetRegistry private assetRegistry;
    IBasketHandler private basketHandler;
    IDistributor private distributor;
    IRToken private rToken;
    IERC20 private rsr;
    IStRSR private stRSR;
    IRevenueTrader private rsrTrader;
    IRevenueTrader private rTokenTrader;
    uint48 public constant MAX_TRADING_DELAY = 31536000; // {s} 1 year
    uint192 public constant MAX_BACKING_BUFFER = FIX_ONE; // {1} 100%

    uint48 public tradingDelay; // {s} how long to wait until resuming trading after switching
    uint192 public backingBuffer; // {1} how much extra backing collateral to keep

    // === 3.0.0 ===
    IFurnace private furnace;
    mapping(TradeKind => uint48) private tradeEnd; // {s} last endTime() of an auction per kind

    // === 3.1.0 ===
    mapping(IERC20 => uint192) private tokensOut; // {tok} token balances out in ITrades

    // ==== Invariants ====
    // tradingDelay <= MAX_TRADING_DELAY and backingBuffer <= MAX_BACKING_BUFFER

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        ONE_BLOCK = NetworkConfigLib.blocktime();
    }

    function init(
        IMain main_,
        uint48 tradingDelay_,
        uint192 backingBuffer_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external initializer {
        __Component_init(main_);
        __Trading_init(main_, maxTradeSlippage_, minTradeVolume_);

        cacheComponents();
        setTradingDelay(tradingDelay_);
        setBackingBuffer(backingBuffer_);
    }

    /// Give RToken max allowance over the registered token `erc20`
    /// @custom:interaction CEI
    // checks: erc20 in assetRegistry
    // action: set allowance on erc20 for rToken to UINT_MAX
    // Using two safeApprove calls instead of safeIncreaseAllowance to support USDT
    function grantRTokenAllowance(IERC20 erc20) external notFrozen {
        require(assetRegistry.isRegistered(erc20), "erc20 unregistered");
        // == Interaction ==
        IERC20(address(erc20)).safeApprove(address(rToken), 0);
        IERC20(address(erc20)).safeApprove(address(rToken), type(uint256).max);
    }

    /// Settle a single trade. If the caller is the trade, try chaining into rebalance()
    /// While this function is not nonReentrant, its two subsets each individually are
    /// If the caller is a trade contract, initiate the next trade.
    /// This is done in order to better align incentives,
    /// and have the last bidder be the one to start the next auction.
    /// This behaviour currently only happens for Dutch Trade.
    /// @param sell The sell token in the trade
    /// @return trade The ITrade contract settled
    /// @custom:interaction
    function settleTrade(IERC20 sell) public override(ITrading, TradingP1) returns (ITrade trade) {
        delete tokensOut[sell];
        trade = super.settleTrade(sell); // nonReentrant

        // if the settler is the trade contract itself, try chaining with another rebalance()
        if (_msgSender() == address(trade)) {
            // solhint-disable-next-line no-empty-blocks
            try this.rebalance(trade.KIND()) {} catch (bytes memory errData) {
                // prevent MEV searchers from providing less gas on purpose by reverting if OOG
                // untested:
                //     OOG pattern tested in other contracts, cost to test here is high
                // see: docs/solidity-style.md#Catching-Empty-Data
                if (errData.length == 0) revert(); // solhint-disable-line reason-string
            }
        }

        basketHandler.trackCollateralization();
    }

    /// Apply the overall backing policy using the specified TradeKind, taking a haircut if unable
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @custom:interaction not RCEI; nonReentrant
    // untested:
    //      OZ nonReentrant line is assumed to be working. cost/benefit of direct testing is high
    function rebalance(TradeKind kind) external nonReentrant {
        requireNotTradingPausedOrFrozen();

        // == Refresh ==
        assetRegistry.refresh();

        // DoS prevention: unless caller is self, require 1 empty block between like-kind auctions
        require(
            _msgSender() == address(this) || tradeEnd[kind] + ONE_BLOCK < block.timestamp,
            "already rebalancing"
        );

        require(tradesOpen == 0, "trade open");
        require(basketHandler.isReady(), "basket not ready");
        require(block.timestamp >= basketHandler.timestamp() + tradingDelay, "trading delayed");

        BasketRange memory basketsHeld = basketHandler.basketsHeldBy(address(this));
        require(basketsHeld.bottom < rToken.basketsNeeded(), "already collateralized");
        // require(!basketHandler.fullyCollateralized())

        // First dissolve any held RToken balance (above Distributor-dust)
        // gas-optimization: 1 whole RToken must be worth 100 trillion dollars for this to skip $1
        uint256 balance = rToken.balanceOf(address(this));
        if (balance >= MAX_DISTRIBUTION * MAX_DESTINATIONS) rToken.dissolve(balance);
        if (basketsHeld.bottom >= rToken.basketsNeeded()) return; // return if now capitalized

        /*
         * Recollateralization
         *
         * Strategy: iteratively move the system on a forgiving path towards collateralization
         * through a narrowing BU price band. The initial large spread reflects the
         * uncertainty associated with the market price of defaulted/volatile collateral, as
         * well as potential losses due to trading slippage. In the absence of further
         * collateral default, the size of the BU price band should decrease with each trade
         * until it is 0, at which point collateralization is restored.
         *
         * If we run out of capital and are still undercollateralized, we compromise
         * rToken.basketsNeeded to the current basket holdings. Haircut time.
         */

        (TradingContext memory ctx, Registry memory reg) = tradingContext(basketsHeld);
        (
            bool doTrade,
            TradeRequest memory req,
            TradePrices memory prices
        ) = RecollateralizationLibP1.prepareRecollateralizationTrade(ctx, reg);

        if (doTrade) {
            IERC20 sellERC20 = req.sell.erc20();

            // Seize RSR if needed
            if (sellERC20 == rsr) {
                uint256 bal = sellERC20.balanceOf(address(this));
                if (req.sellAmount > bal) stRSR.seizeRSR(req.sellAmount - bal);
            }

            // Execute Trade
            ITrade trade = tryTrade(kind, req, prices);
            tradeEnd[kind] = trade.endTime(); // {s}
            tokensOut[sellERC20] = trade.sellAmount(); // {tok}
        } else {
            // Haircut time
            compromiseBasketsNeeded(basketsHeld.bottom);
        }
    }

    /// Forward revenue to RevenueTraders; reverts if not fully collateralized
    /// @param erc20s The tokens to forward
    /// @custom:interaction not RCEI; nonReentrant
    // untested:
    //      OZ nonReentrant line is assumed to be working. cost/benefit of direct testing is high
    function forwardRevenue(IERC20[] calldata erc20s) external nonReentrant {
        requireNotTradingPausedOrFrozen();
        require(ArrayLib.allUnique(erc20s), "duplicate tokens");

        assetRegistry.refresh();

        BasketRange memory basketsHeld = basketHandler.basketsHeldBy(address(this));

        require(tradesOpen == 0, "trade open");
        require(basketHandler.isReady(), "basket not ready");
        require(block.timestamp >= basketHandler.timestamp() + tradingDelay, "trading delayed");
        require(basketsHeld.bottom >= rToken.basketsNeeded(), "undercollateralized");
        // require(basketHandler.fullyCollateralized())

        /**
         * Assumptions:
         *   - Fully collateralized. All collateral meet balance requirements.
         *   - All backing capital is held at BackingManager's address. No capital is out on-trade
         *   - Neither RToken nor RSR are in the basket
         *   - Each address in erc20s is unique
         *
         * Steps:
         *   1. Forward all held RSR to the RSR trader to prevent using it for RToken appreciation
         *      (action: send rsr().balanceOf(this) to rsrTrader)
         *   2. Using whatever balances of collateral are there, fast-issue all RToken possible.
         *      (in detail: mint RToken and set basketsNeeded so that the BU/rtok exchange rate is
         *       roughly constant, and strictly does not decrease,
         *   3. Handout all RToken held above the backingBuffer portion of the supply, and all
         *      non-RToken surplus asset balances to the RSR and
         *      RToken traders according to the distribution totals.
         */

        // Forward any RSR held to StRSR pool and payout rewards
        // RSR should never be sold for RToken yield
        if (rsr.balanceOf(address(this)) > 0) {
            // For CEI, this is an interaction "within our system" even though RSR is already live
            IERC20(address(rsr)).safeTransfer(address(stRSR), rsr.balanceOf(address(this)));
            stRSR.payoutRewards();
        }

        // Mint revenue RToken
        // Keep backingBuffer worth of collateral before recognizing revenue
        uint192 baskets = (basketsHeld.bottom.div(FIX_ONE + backingBuffer));
        if (baskets > rToken.basketsNeeded()) {
            rToken.mint(baskets - rToken.basketsNeeded());
        }

        uint192 needed = rToken.basketsNeeded().mul(FIX_ONE + backingBuffer); // {BU}

        // At this point, even though basketsNeeded may have changed, we are:
        // - We're fully collateralized
        // - The BU exchange rate {BU/rTok} did not decrease

        // Handout surplus assets + newly minted RToken

        uint256 length = erc20s.length;
        RevenueTotals memory totals = distributor.totals();
        for (uint256 i = 0; i < length; ++i) {
            IAsset asset = assetRegistry.toAsset(erc20s[i]);

            // {tok} = {BU} * {tok/BU}
            uint192 req = needed.mul(basketHandler.quantity(erc20s[i]), CEIL);
            uint192 bal = asset.bal(address(this));

            if (bal.gt(req)) {
                // delta: {qTok}, the excess quantity of this asset that we hold
                uint256 delta = bal.minus(req).shiftl_toUint(int8(asset.erc20Decimals()));
                uint256 tokensPerShare = delta / (totals.rTokenTotal + totals.rsrTotal);
                if (tokensPerShare == 0) continue;

                // no div-by-0: Distributor guarantees (totals.rTokenTotal + totals.rsrTotal) > 0
                // initial division is intentional here! We'd rather save the dust than be unfair

                if (totals.rsrTotal > 0) {
                    erc20s[i].safeTransfer(address(rsrTrader), tokensPerShare * totals.rsrTotal);
                }
                if (totals.rTokenTotal > 0) {
                    erc20s[i].safeTransfer(
                        address(rTokenTrader),
                        tokensPerShare * totals.rTokenTotal
                    );
                }
            }
        }
        // It's okay if there is leftover dust for RToken or a surplus asset (not RSR)
    }

    // === View ===

    /// Structs for trading
    /// @param basketsHeld The number of baskets held by the BackingManager
    /// @return ctx The TradingContext
    /// @return reg Contents of AssetRegistry.getRegistry()
    function tradingContext(BasketRange memory basketsHeld)
        public
        view
        returns (TradingContext memory ctx, Registry memory reg)
    {
        reg = assetRegistry.getRegistry();

        ctx.basketsHeld = basketsHeld;
        ctx.bh = basketHandler;
        ctx.ar = assetRegistry;
        ctx.stRSR = stRSR;
        ctx.rsr = rsr;
        ctx.rToken = rToken;
        ctx.minTradeVolume = minTradeVolume;
        ctx.maxTradeSlippage = maxTradeSlippage;
        ctx.quantities = new uint192[](reg.erc20s.length);
        for (uint256 i = 0; i < reg.erc20s.length; ++i) {
            ctx.quantities[i] = basketHandler.quantityUnsafe(reg.erc20s[i], reg.assets[i]);
        }
        ctx.bals = new uint192[](reg.erc20s.length);
        for (uint256 i = 0; i < reg.erc20s.length; ++i) {
            ctx.bals[i] = reg.assets[i].bal(address(this)) + tokensOut[reg.erc20s[i]];

            // include StRSR's balance for RSR
            if (reg.erc20s[i] == rsr) ctx.bals[i] += reg.assets[i].bal(address(stRSR));
        }
    }

    // === Private ===

    /// Compromise on how many baskets are needed in order to recollateralize-by-accounting
    /// @param basketsHeldBottom {BU} The number of full basket units held by the BackingManager
    function compromiseBasketsNeeded(uint192 basketsHeldBottom) private {
        // assert(tradesOpen == 0 && !basketHandler.fullyCollateralized());
        assert(tradesOpen == 0);
        rToken.setBasketsNeeded(basketsHeldBottom);
    }

    // === Governance Setters ===

    /// @custom:governance
    function setTradingDelay(uint48 val) public governance {
        require(val <= MAX_TRADING_DELAY, "invalid tradingDelay");
        emit TradingDelaySet(tradingDelay, val);
        tradingDelay = val;
    }

    /// @custom:governance
    function setBackingBuffer(uint192 val) public governance {
        require(val <= MAX_BACKING_BUFFER, "invalid backingBuffer");
        emit BackingBufferSet(backingBuffer, val);
        backingBuffer = val;
    }

    /// Call after upgrade to >= 3.0.0
    function cacheComponents() public {
        assetRegistry = main.assetRegistry();
        basketHandler = main.basketHandler();
        distributor = main.distributor();
        rToken = main.rToken();
        rsr = main.rsr();
        stRSR = main.stRSR();
        rsrTrader = main.rsrTrader();
        rTokenTrader = main.rTokenTrader();
        furnace = main.furnace();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[38] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../../interfaces/IComponent.sol";
import "../../interfaces/IMain.sol";
import "../../mixins/Versioned.sol";

/**
 * Abstract superclass for system contracts registered in Main
 */
abstract contract ComponentP1 is
    Versioned,
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    IComponent
{
    IMain public main;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    // Sets main for the component - Can only be called during initialization
    // untestable:
    //      `else` branch of `onlyInitializing` (ie. revert) is currently untestable.
    //      This function is only called inside other `init` functions, each of which is wrapped
    //      in an `initializer` modifier, which would fail first.
    // solhint-disable-next-line func-name-mixedcase
    function __Component_init(IMain main_) internal onlyInitializing {
        require(address(main_) != address(0), "main is zero address");
        __UUPSUpgradeable_init();
        main = main_;
    }

    // === See docs/security.md ===

    modifier notTradingPausedOrFrozen() {
        require(!main.tradingPausedOrFrozen(), "frozen or trading paused");
        _;
    }

    modifier notIssuancePausedOrFrozen() {
        require(!main.issuancePausedOrFrozen(), "frozen or issuance paused");
        _;
    }

    modifier notFrozen() {
        require(!main.frozen(), "frozen");
        _;
    }

    modifier governance() {
        require(main.hasRole(OWNER, _msgSender()), "governance only");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override governance {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IAsset.sol";
import "../../interfaces/IAssetRegistry.sol";
import "../../interfaces/IBackingManager.sol";
import "../../libraries/Fixed.sol";
import "./TradeLib.sol";

/**
 * @title RecollateralizationLibP1
 * @notice An informal extension of BackingManager that implements the rebalancing logic
 *   Users:
 *     - BackingManager
 *     - RTokenAsset (uses `basketRange()`)
 *
 * Interface:
 *  1. prepareRecollateralizationTrade() (external)
 *  2. basketRange() (internal)
 */
library RecollateralizationLibP1 {
    using FixLib for uint192;
    using TradeLib for TradeInfo;
    using TradeLib for IBackingManager;

    /// Select and prepare a trade that moves us closer to capitalization, using the
    /// basket range to avoid overeager/duplicate trading.
    /// The basket range is the full range of projected outcomes for the rebalancing process.
    // This is the "main loop" for recollateralization trading:
    // actions:
    //   let range = basketRange(...)
    //   let trade = nextTradePair(...)
    //   if trade.sell is not a defaulted collateral, prepareTradeToCoverDeficit(...)
    //   otherwise, prepareTradeSell(...) taking the minBuyAmount as the dependent variable
    function prepareRecollateralizationTrade(TradingContext memory ctx, Registry memory reg)
        external
        view
        returns (
            bool doTrade,
            TradeRequest memory req,
            TradePrices memory prices
        )
    {
        // Compute a target basket range for trading -  {BU}
        // The basket range is the full range of projected outcomes for the rebalancing process
        BasketRange memory range = basketRange(ctx, reg);

        // Select a pair to trade next, if one exists
        TradeInfo memory trade = nextTradePair(ctx, reg, range);

        // Don't trade if no pair is selected
        if (address(trade.sell) == address(0) || address(trade.buy) == address(0)) {
            return (false, req, prices);
        }

        // If we are selling a fully unpriced asset or UNSOUND collateral, do not cover deficit
        // untestable:
        //     sellLow will not be zero, those assets are skipped in nextTradePair
        if (
            trade.prices.sellLow == 0 ||
            (trade.sell.isCollateral() &&
                ICollateral(address(trade.sell)).status() != CollateralStatus.SOUND)
        ) {
            // Emergency case
            // Set minBuyAmount as a function of sellAmount
            (doTrade, req) = trade.prepareTradeSell(ctx.minTradeVolume, ctx.maxTradeSlippage);
        } else {
            // Normal case
            // Set sellAmount as a function of minBuyAmount
            (doTrade, req) = trade.prepareTradeToCoverDeficit(
                ctx.minTradeVolume,
                ctx.maxTradeSlippage
            );
        }

        // At this point doTrade _must_ be true, otherwise nextTradePair assumptions are broken
        assert(doTrade);

        return (doTrade, req, trade.prices);
    }

    // Compute the target basket range
    // Algorithm intuition: Trade conservatively. Quantify uncertainty based on the proportion of
    // token balances requiring trading vs not requiring trading. Seek to decrease uncertainty
    // the largest amount possible with each trade.
    //
    // Algorithm Invariant: every increase of basketsHeld.bottom causes basketsRange().low to
    //  reach a new maximum. Note that basketRange().low may decrease slightly along the way.
    // Assumptions: constant oracle prices; monotonically increasing refPerTok; no supply changes
    //
    // Preconditions:
    // - ctx is correctly populated, with current basketsHeld.bottom + basketsHeld.top
    // - reg contains erc20 + asset + quantities arrays in same order and without duplicates
    // Trading Strategy:
    // - We will not aim to hold more than rToken.basketsNeeded() BUs
    // - No double trades: capital converted from token A to token B should not go to token C
    //       unless the clearing price was outside the expected price range
    // - The best price we might get for a trade is at the high sell price and low buy price
    // - The worst price we might get for a trade is at the low sell price and
    //     the high buy price, multiplied by ( 1 - maxTradeSlippage )
    // - In the worst-case an additional dust balance can be lost, up to minTradeVolume
    // - Given all that, we're aiming to hold as many BUs as possible using the assets we own.
    //
    // More concretely:
    // - range.top = min(rToken.basketsNeeded, basketsHeld.top - least baskets missing
    //                                                                   + most baskets surplus)
    // - range.bottom = min(rToken.basketsNeeded, basketsHeld.bottom + least baskets purchaseable)
    //   where "least baskets purchaseable" involves trading at the worst price,
    //   incurring the full maxTradeSlippage, and taking up to a minTradeVolume loss due to dust.
    function basketRange(TradingContext memory ctx, Registry memory reg)
        internal
        view
        returns (BasketRange memory range)
    {
        // tradesOpen will be 0 when called by prepareRecollateralizationTrade()
        // tradesOpen can be > 0 when called by RTokenAsset.basketRange()

        (uint192 buPriceLow, uint192 buPriceHigh) = ctx.bh.price(); // {UoA/BU}
        require(buPriceLow > 0 && buPriceHigh < FIX_MAX, "BUs unpriced");

        uint192 basketsNeeded = ctx.rToken.basketsNeeded(); // {BU}

        // Cap ctx.basketsHeld.top
        if (ctx.basketsHeld.top > basketsNeeded) {
            ctx.basketsHeld.top = basketsNeeded;
        }

        // === (1/3) Calculate contributions from surplus/deficits ===

        // for range.top, anchor to min(ctx.basketsHeld.top, basketsNeeded)
        // for range.bottom, anchor to min(ctx.basketsHeld.bottom, basketsNeeded)

        // a signed delta to be applied to range.top
        int256 deltaTop; // D18{BU} even though this is int256, it is D18
        // not required for range.bottom

        // to minimize total operations, range.bottom is calculated from a summed UoA
        uint192 uoaBottom; // {UoA} pessimistic UoA estimate of balances above basketsHeld.bottom

        // (no space on the stack to cache erc20s.length)
        for (uint256 i = 0; i < reg.erc20s.length; ++i) {
            // Exclude RToken balances to avoid double counting value
            if (reg.erc20s[i] == IERC20(address(ctx.rToken))) continue;

            (uint192 low, uint192 high) = reg.assets[i].price(); // {UoA/tok}

            // Skip over dust-balance assets not in the basket
            // Intentionally include value of IFFY/DISABLED collateral
            if (
                ctx.quantities[i] == 0 &&
                !TradeLib.isEnoughToSell(reg.assets[i], ctx.bals[i], low, ctx.minTradeVolume)
            ) {
                continue;
            }

            // throughout these sections +/- is same as Fix.plus/Fix.minus and </> is Fix.gt/.lt

            // deltaTop: optimistic case
            // if in deficit relative to ctx.basketsHeld.top: deduct missing baskets
            // if in surplus relative to ctx.basketsHeld.top: add-in surplus baskets
            {
                // {tok} = {tok/BU} * {BU}
                uint192 anchor = ctx.quantities[i].mul(ctx.basketsHeld.top, CEIL);

                if (anchor > ctx.bals[i]) {
                    // deficit: deduct optimistic estimate of baskets missing

                    // {BU} = {UoA/tok} * {tok} / {UoA/BU}
                    deltaTop -= int256(
                        uint256(low.mulDiv(anchor - ctx.bals[i], buPriceHigh, FLOOR))
                    );
                    // does not need underflow protection: using low price of asset
                } else {
                    // surplus: add-in optimistic estimate of baskets purchaseable

                    //  {BU} = {UoA/tok} * {tok} / {UoA/BU}
                    deltaTop += int256(
                        uint256(high.safeMulDiv(ctx.bals[i] - anchor, buPriceLow, CEIL))
                    );
                }
            }

            // range.bottom: pessimistic case
            // add-in surplus baskets relative to ctx.basketsHeld.bottom
            {
                // {tok} = {tok/BU} * {BU}
                uint192 anchor = ctx.quantities[i].mul(ctx.basketsHeld.bottom, FLOOR);

                // (1) Sum token value at low price
                // {UoA} = {UoA/tok} * {tok}
                uint192 val = low.mul(ctx.bals[i] - anchor, FLOOR);

                // (2) Lose minTradeVolume to dust (why: auctions can return tokens)
                // Q: Why is this precisely where we should take out minTradeVolume?
                // A: Our use of isEnoughToSell always uses the low price,
                //   so min trade volumes are always assessed based on low prices. At this point
                //   in the calculation we have already calculated the UoA amount corresponding to
                //   the excess token balance based on its low price, so we are already set up
                //   to straightforwardly deduct the minTradeVolume before trying to buy BUs.
                uoaBottom += (val < ctx.minTradeVolume) ? 0 : val - ctx.minTradeVolume;
            }
        }

        // ==== (2/3) Add-in ctx.*BasketsHeld safely ====

        // range.top
        if (deltaTop < 0) {
            range.top = ctx.basketsHeld.top - _safeWrap(uint256(-deltaTop));
            // reverting on underflow is appropriate here
        } else {
            // guard against overflow; > is same as Fix.gt
            if (uint256(deltaTop) + ctx.basketsHeld.top > FIX_MAX) range.top = FIX_MAX;
            else range.top = ctx.basketsHeld.top + _safeWrap(uint256(deltaTop));
        }

        // range.bottom
        // (3) Buy BUs at their high price with the remaining value
        // (4) Assume maximum slippage in trade
        // {BU} = {UoA} * {1} / {UoA/BU}
        range.bottom =
            ctx.basketsHeld.bottom +
            uoaBottom.mulDiv(FIX_ONE.minus(ctx.maxTradeSlippage), buPriceHigh, FLOOR);
        // reverting on overflow is appropriate here

        // ==== (3/3) Enforce (range.bottom <= range.top <= basketsNeeded) ====

        if (range.top > basketsNeeded) range.top = basketsNeeded;
        if (range.bottom > range.top) range.bottom = range.top;
    }

    // ===========================================================================================

    // === Private ===

    // Used in memory in `nextTradePair` to duck the stack limit
    struct MaxSurplusDeficit {
        CollateralStatus surplusStatus; // starts SOUND
        uint192 surplus; // {UoA}
        uint192 deficit; // {UoA}
    }

    // Choose next sell/buy pair to trade, with reference to the basket range
    // Skip over trading surplus dust amounts
    /// @return trade
    ///   sell: Surplus collateral OR address(0)
    ///   deficit Deficit collateral OR address(0)
    ///   sellAmount {sellTok} Surplus amount (whole tokens)
    ///   buyAmount {buyTok} Deficit amount (whole tokens)
    ///   prices.sellLow {UoA/sellTok} The worst-case price of the sell token on secondary markets
    ///   prices.sellHigh {UoA/sellTok} The best-case price of the sell token on secondary markets
    ///   prices.buyLow {UoA/buyTok} The best-case price of the buy token on secondary markets
    ///   prices.buyHigh {UoA/buyTok} The worst-case price of the buy token on secondary markets
    ///
    // For each asset e:
    //   If bal(e) > (quantity(e) * range.top), then e is in surplus by the difference
    //   If bal(e) < (quantity(e) * range.bottom), then e is in deficit by the difference
    //
    // First, ignoring RSR:
    //   `trade.sell` is the token from erc20s with the greatest surplus value (in UoA),
    //   and sellAmount is the quantity of that token that it's in surplus (in qTok).
    //   if `trade.sell` == 0, then no token is in surplus by at least minTradeSize,
    //        and `trade.sellAmount` and `trade.sellLow` / `trade.sellHigh are unset.
    //
    //   `trade.buy` is the token from erc20s with the greatest deficit value (in UoA),
    //   and buyAmount is the quantity of that token that it's in deficit (in qTok).
    //   if `trade.buy` == 0, then no token is in deficit at all,
    //        and `trade.buyAmount` and `trade.buyLow` / `trade.buyHigh` are unset.
    //
    // Then, just if we have a buy asset and no sell asset, consider selling available RSR.
    //
    // Prefer selling assets in this order: DISABLED -> SOUND -> IFFY.
    // Sell IFFY last because it may recover value in the future.
    // All collateral in the basket have already been guaranteed to be SOUND by upstream checks.
    function nextTradePair(
        TradingContext memory ctx,
        Registry memory reg,
        BasketRange memory range
    ) private view returns (TradeInfo memory trade) {
        // assert(tradesOpen == 0); // guaranteed by BackingManager.rebalance()

        MaxSurplusDeficit memory maxes;
        maxes.surplusStatus = CollateralStatus.IFFY; // least-desirable sell status

        uint256 rsrIndex = reg.erc20s.length; // invalid index, to-start

        // Iterate over non-RSR/non-RToken assets
        // (no space on the stack to cache erc20s.length)
        for (uint256 i = 0; i < reg.erc20s.length; ++i) {
            if (address(reg.erc20s[i]) == address(ctx.rToken)) continue;
            else if (reg.erc20s[i] == ctx.rsr) {
                rsrIndex = i;
                continue;
            }

            // {tok} = {BU} * {tok/BU}
            // needed(Top): token balance needed for range.top baskets: quantity(e) * range.top
            uint192 needed = range.top.mul(ctx.quantities[i], CEIL); // {tok}

            if (ctx.bals[i].gt(needed)) {
                (uint192 low, uint192 high) = reg.assets[i].price(); // {UoA/sellTok}

                if (high == 0) continue; // skip over worthless assets

                // {UoA} = {sellTok} * {UoA/sellTok}
                uint192 delta = ctx.bals[i].minus(needed).mul(low, FLOOR);

                // status = asset.status() if asset.isCollateral() else SOUND
                CollateralStatus status; // starts SOUND
                if (reg.assets[i].isCollateral()) {
                    status = ICollateral(address(reg.assets[i])).status();
                }

                // Select the most-in-surplus "best" asset still enough to sell,
                // as defined by a (status, surplusAmt) ordering
                if (
                    isBetterSurplus(maxes, status, delta) &&
                    TradeLib.isEnoughToSell(
                        reg.assets[i],
                        ctx.bals[i].minus(needed),
                        low,
                        ctx.minTradeVolume
                    )
                ) {
                    trade.sell = reg.assets[i];
                    trade.sellAmount = ctx.bals[i].minus(needed);
                    trade.prices.sellLow = low;
                    trade.prices.sellHigh = high;

                    maxes.surplusStatus = status;
                    maxes.surplus = delta;
                }
            } else {
                // needed(Bottom): token balance needed at bottom of the basket range
                needed = range.bottom.mul(ctx.quantities[i], CEIL); // {buyTok};

                if (ctx.bals[i].lt(needed)) {
                    uint192 amtShort = needed.minus(ctx.bals[i]); // {buyTok}
                    (uint192 low, uint192 high) = reg.assets[i].price(); // {UoA/buyTok}

                    // {UoA} = {buyTok} * {UoA/buyTok}
                    uint192 delta = amtShort.mul(high, CEIL);

                    // The best asset to buy is whichever asset has the largest deficit
                    if (delta.gt(maxes.deficit)) {
                        trade.buy = reg.assets[i];
                        trade.buyAmount = amtShort;
                        trade.prices.buyLow = low;
                        trade.prices.buyHigh = high;

                        maxes.deficit = delta;
                    }
                }
            }
        }

        // Use RSR if needed
        if (address(trade.sell) == address(0) && address(trade.buy) != address(0)) {
            (uint192 low, uint192 high) = reg.assets[rsrIndex].price(); // {UoA/RSR}

            // if rsr does not have a registered asset the below array accesses will revert
            if (
                high > 0 &&
                TradeLib.isEnoughToSell(
                    reg.assets[rsrIndex],
                    ctx.bals[rsrIndex],
                    low,
                    ctx.minTradeVolume
                )
            ) {
                trade.sell = reg.assets[rsrIndex];
                trade.sellAmount = ctx.bals[rsrIndex];
                trade.prices.sellLow = low;
                trade.prices.sellHigh = high;
            }
        }
    }

    /// @param curr The current MaxSurplusDeficit containing the best surplus so far
    /// @param other The collateral status of the asset in consideration
    /// @param surplusAmt {UoA} The amount by which the asset in consideration is in surplus
    function isBetterSurplus(
        MaxSurplusDeficit memory curr,
        CollateralStatus other,
        uint192 surplusAmt
    ) private pure returns (bool) {
        // NOTE: If the CollateralStatus enum changes then this has to change!
        if (curr.surplusStatus == CollateralStatus.DISABLED) {
            return other == CollateralStatus.DISABLED && surplusAmt.gt(curr.surplus);
        } else if (curr.surplusStatus == CollateralStatus.SOUND) {
            return
                other == CollateralStatus.DISABLED ||
                (other == CollateralStatus.SOUND && surplusAmt.gt(curr.surplus));
        } else {
            // curr is IFFY
            return other != CollateralStatus.IFFY || surplusAmt.gt(curr.surplus);
        }
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/IAssetRegistry.sol";
import "../../interfaces/IBackingManager.sol";

/**
 * @title RewardableLibP1
 * @notice A library that allows a contract to claim rewards
 * @dev The caller must implement the IRewardable interface!
 */
library RewardableLibP1 {
    using Address for address;
    using SafeERC20 for IERC20;

    // === Used by Traders + RToken ===

    /// Claim all rewards
    // actions:
    //   do asset.delegatecall(abi.encodeWithSignature("claimRewards()")) for asset in assets
    function claimRewards(IAssetRegistry reg) internal {
        Registry memory registry = reg.getRegistry();
        uint256 len = registry.assets.length;
        for (uint256 i = 0; i < len; ++i) {
            // Claim rewards via delegatecall
            address(registry.assets[i]).functionDelegateCall(
                abi.encodeWithSignature("claimRewards()"),
                "rewards claim failed"
            );
        }
    }

    /// Claim rewards for a single ERC20
    // actions:
    //   do asset.delegatecall(abi.encodeWithSignature("claimRewards()"))
    function claimRewardsSingle(IAsset asset) internal {
        // Claim rewards via delegatecall
        address(asset).functionDelegateCall(
            abi.encodeWithSignature("claimRewards()"),
            "rewards claim failed"
        );
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IAsset.sol";
import "../../interfaces/IAssetRegistry.sol";
import "../../interfaces/ITrading.sol";
import "../../libraries/Fixed.sol";
import "./RecollateralizationLib.sol";

struct TradeInfo {
    IAsset sell;
    IAsset buy;
    uint192 sellAmount; // {sellTok}
    uint192 buyAmount; // {buyTok}
    TradePrices prices;
}

/**
 * @title TradeLib
 * @notice An internal lib for preparing individual trades on particular asset pairs
 *   Users:
 *     - RecollateralizationLib
 *     - RevenueTrader
 */
library TradeLib {
    using FixLib for uint192;

    /// Prepare a trade to sell `trade.sellAmount` that guarantees a reasonable closing price,
    /// without explicitly aiming at a particular buy amount.
    /// @param trade:
    ///   sell != 0, sellAmount >= 0 {sellTok}, prices.sellLow >= 0 {UoA/sellTok}
    ///   buy != 0, buyAmount (unused) {buyTok}, prices.buyHigh > 0 {UoA/buyTok}
    /// @return notDust True when the trade is larger than the dust amount
    /// @return req The prepared trade request to send to the Broker
    //
    // If notDust is true, then the returned trade request satisfies:
    //   req.sell == trade.sell and req.buy == trade.buy,
    //   req.minBuyAmount * trade.prices.buyHigh ~=
    //        trade.sellAmount * trade.prices.sellLow * (1-maxTradeSlippage),
    //   req.sellAmount == min(trade.sell.maxTradeSize(), trade.sellAmount)
    //   1 < req.sellAmount
    //
    // If notDust is false, no trade exists that satisfies those constraints.
    function prepareTradeSell(
        TradeInfo memory trade,
        uint192 minTradeVolume,
        uint192 maxTradeSlippage
    ) internal view returns (bool notDust, TradeRequest memory req) {
        // checked for in RevenueTrader / CollateralizatlionLib
        assert(
            trade.prices.buyHigh > 0 &&
                trade.prices.buyHigh < FIX_MAX &&
                trade.prices.sellLow < FIX_MAX
        );

        notDust = isEnoughToSell(
            trade.sell,
            trade.sellAmount,
            trade.prices.sellLow,
            minTradeVolume
        );

        // Cap sell amount
        uint192 maxSell = maxTradeSize(trade.sell, trade.buy, trade.prices.sellLow); // {sellTok}
        uint192 s = trade.sellAmount > maxSell ? maxSell : trade.sellAmount; // {sellTok}

        // Calculate equivalent buyAmount within [0, FIX_MAX]
        // {buyTok} = {sellTok} * {1} * {UoA/sellTok} / {UoA/buyTok}
        uint192 b = s.mul(FIX_ONE.minus(maxTradeSlippage)).safeMulDiv(
            trade.prices.sellLow,
            trade.prices.buyHigh,
            CEIL
        );

        // {*tok} => {q*Tok}
        req.sellAmount = s.shiftl_toUint(int8(trade.sell.erc20Decimals()), FLOOR);
        req.minBuyAmount = b.shiftl_toUint(int8(trade.buy.erc20Decimals()), CEIL);
        req.sell = trade.sell;
        req.buy = trade.buy;

        return (notDust, req);
    }

    /// Assuming we have `trade.sellAmount` sell tokens available, prepare a trade to cover as
    /// much of our deficit of `trade.buyAmount` buy tokens as possible, given expected trade
    /// slippage and maxTradeVolume().
    /// @param trade:
    ///   sell != 0
    ///   buy != 0
    ///   sellAmount (unused) {sellTok}
    ///   buyAmount >= 0 {buyTok}
    ///   prices.sellLow > 0 {UoA/sellTok}
    ///   prices.buyHigh > 0 {UoA/buyTok}
    /// @return notDust Whether the prepared trade is large enough to be worth trading
    /// @return req The prepared trade request to send to the Broker
    //
    // Returns prepareTradeSell(trade, rules), where
    //   req.sellAmount = min(trade.sellAmount,
    //                trade.buyAmount * (buyHigh / sellLow) / (1-maxTradeSlippage))
    //   i.e, the minimum of trade.sellAmount and (a sale amount that, at current prices and
    //   maximum slippage, will yield at least the requested trade.buyAmount)
    //
    // Which means we should get that, if notDust is true, then:
    //   req.sell = sell and req.buy = buy
    //
    //   1 <= req.minBuyAmount <= max(trade.buyAmount, buy.minTradeSize()))
    //   1 < req.sellAmount <= min(trade.sellAmount, sell.maxTradeSize())
    //   req.minBuyAmount ~= trade.sellAmount * sellLow / buyHigh * (1-maxTradeSlippage)
    //
    //   req.sellAmount (and req.minBuyAmount) are maximal satisfying all these conditions
    function prepareTradeToCoverDeficit(
        TradeInfo memory trade,
        uint192 minTradeVolume,
        uint192 maxTradeSlippage
    ) internal view returns (bool notDust, TradeRequest memory req) {
        assert(
            trade.prices.sellLow > 0 &&
                trade.prices.sellLow < FIX_MAX &&
                trade.prices.buyHigh > 0 &&
                trade.prices.buyHigh < FIX_MAX
        );

        // Don't buy dust.
        trade.buyAmount = fixMax(
            trade.buyAmount,
            minTradeSize(minTradeVolume, trade.prices.buyHigh)
        );

        // {sellTok} = {buyTok} * {UoA/buyTok} / {UoA/sellTok}
        uint192 exactSellAmount = trade.buyAmount.mulDiv(
            trade.prices.buyHigh,
            trade.prices.sellLow,
            CEIL
        );
        // exactSellAmount: Amount to sell to buy `deficitAmount` if there's no slippage

        // slippedSellAmount: Amount needed to sell to buy `deficitAmount`, counting slippage
        uint192 slippedSellAmount = exactSellAmount.div(FIX_ONE.minus(maxTradeSlippage), CEIL);

        trade.sellAmount = fixMin(slippedSellAmount, trade.sellAmount); // {sellTok}
        return prepareTradeSell(trade, minTradeVolume, maxTradeSlippage);
    }

    /// @param asset The asset in consideration
    /// @param amt {tok} The number of whole tokens we plan to sell
    /// @param price {UoA/tok} The price to use for sizing
    /// @param minTradeVolume {UoA} The min trade volume, passed in for gas optimization
    /// @return If amt is sufficiently large to be worth selling into our trading platforms
    function isEnoughToSell(
        IAsset asset,
        uint192 amt,
        uint192 price,
        uint192 minTradeVolume
    ) internal view returns (bool) {
        return
            amt.gte(minTradeSize(minTradeVolume, price)) &&
            // Trading platforms often don't allow token quanta trades for rounding reasons
            // {qTok} = {tok} / {tok/qTok}
            amt.shiftl_toUint(int8(asset.erc20Decimals())) > 1;
    }

    // === Private ===

    /// Calculates the minTradeSize for an asset based on the given minTradeVolume and price
    /// @param minTradeVolume {UoA} The min trade volume, passed in for gas optimization
    /// @return {tok} The min trade size for the asset in whole tokens
    function minTradeSize(uint192 minTradeVolume, uint192 price) private pure returns (uint192) {
        // {tok} = {UoA} / {UoA/tok}
        uint192 size = price == 0 ? FIX_MAX : minTradeVolume.div(price, CEIL);
        return size > 0 ? size : 1;
    }

    /// Calculates the maximum trade size for a trade pair of tokens
    /// @return {tok} The max trade size for the trade overall
    function maxTradeSize(
        IAsset sell,
        IAsset buy,
        uint192 price
    ) private view returns (uint192) {
        // D18{tok} = D18{UoA} / D18{UoA/tok}
        uint192 size = fixMin(sell.maxTradeVolume(), buy.maxTradeVolume()).safeDiv(price, FLOOR);
        return size > 0 ? size : 1;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../../interfaces/ITrade.sol";
import "../../interfaces/ITrading.sol";
import "../../libraries/Allowance.sol";
import "../../libraries/Fixed.sol";
import "./Component.sol";
import "./RewardableLib.sol";

/// Abstract trading mixin for BackingManager + RevenueTrader.
/// @dev The use of Multicall here instead of MulticallUpgradeable cannot be
///   changed without breaking <3.0.0 RTokens. The only difference in
///   MulticallUpgradeable is the 50 slot storage gap and an empty constructor.
///   It should be fine to leave the non-upgradeable Multicall here permanently.
abstract contract TradingP1 is Multicall, ComponentP1, ReentrancyGuardUpgradeable, ITrading {
    using FixLib for uint192;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint192 public constant MAX_TRADE_VOLUME = 1e29; // {UoA}
    uint192 public constant MAX_TRADE_SLIPPAGE = 1e18; // {%}

    // Peer contracts, immutable after init()
    IBroker private broker;

    // All open trades
    mapping(IERC20 => ITrade) public trades;
    uint48 public tradesOpen;

    // === Governance param ===
    uint192 public maxTradeSlippage; // {%}
    uint192 public minTradeVolume; // {UoA}

    // === 3.0.0 ===
    uint256 public tradesNonce; // to keep track of how many trades have been opened in total

    // ==== Invariants ====
    // tradesOpen = len(values(trades))
    // trades[sell] != 0 iff trade[sell] has been opened and not yet settled

    // untestable:
    //      `else` branch of `onlyInitializing` (ie. revert) is currently untestable.
    //      This function is only called inside other `init` functions, each of which is wrapped
    //      in an `initializer` modifier, which would fail first.
    // solhint-disable-next-line func-name-mixedcase
    function __Trading_init(
        IMain main_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) internal onlyInitializing {
        broker = main_.broker();
        setMaxTradeSlippage(maxTradeSlippage_);
        setMinTradeVolume(minTradeVolume_);
    }

    /// Contract-size helper
    // solhint-disable-next-line no-empty-blocks
    function requireNotTradingPausedOrFrozen() internal view notTradingPausedOrFrozen {}

    /// Claim all rewards
    /// Collective Action
    /// @custom:interaction CEI
    function claimRewards() external {
        requireNotTradingPausedOrFrozen();
        RewardableLibP1.claimRewards(main.assetRegistry());
    }

    /// Claim rewards for a single asset
    /// Collective Action
    /// @param erc20 The ERC20 to claimRewards on
    /// @custom:interaction CEI
    function claimRewardsSingle(IERC20 erc20) external {
        requireNotTradingPausedOrFrozen();
        RewardableLibP1.claimRewardsSingle(main.assetRegistry().toAsset(erc20));
    }

    /// Settle a single trade, expected to be used with multicall for efficient mass settlement
    /// @param sell The sell token in the trade
    /// @return trade The ITrade contract settled
    /// @custom:interaction (only reads or writes trades, and is marked `nonReentrant`)
    // checks:
    //   !paused (trading), !frozen
    //   trade[sell].canSettle()
    //   (see override)
    // actions:
    //   trade[sell].settle()
    // effects:
    //   trades.set(sell, 0)
    //   tradesOpen' = tradesOpen - 1
    // untested:
    //      OZ nonReentrant line is assumed to be working. cost/benefit of direct testing is high
    function settleTrade(IERC20 sell) public virtual nonReentrant returns (ITrade trade) {
        trade = trades[sell];
        require(address(trade) != address(0), "no trade open");
        require(trade.canSettle(), "cannot settle yet");

        delete trades[sell];
        tradesOpen--;

        // == Interactions ==
        (uint256 soldAmt, uint256 boughtAmt) = trade.settle();
        emit TradeSettled(trade, sell, trade.buy(), soldAmt, boughtAmt);
    }

    /// Try to initiate a trade with a trading partner provided by the broker
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @return trade The trade contract created
    /// @custom:interaction Assumption: Caller is nonReentrant
    // checks:
    //   (not external, so we don't need auth or pause checks)
    //   trades[req.sell] == 0
    // actions:
    //   req.sell.increaseAllowance(broker, req.sellAmount) - two safeApprove calls to support USDT
    //   tradeID = broker.openTrade(req)
    // effects:
    //   trades' = trades.set(req.sell, tradeID)
    //   tradesOpen' = tradesOpen + 1
    function tryTrade(
        TradeKind kind,
        TradeRequest memory req,
        TradePrices memory prices
    ) internal returns (ITrade trade) {
        IERC20 sell = req.sell.erc20();
        assert(address(trades[sell]) == address(0)); // ensure calling class has checked this

        // Set allowance via custom approval -- first sets allowance to 0, then sets allowance
        // to either the requested amount or the maximum possible amount, if that fails.
        //
        // Context: wcUSDCv3 has a non-standard approve() function that reverts if the approve
        // amount is > 0 and < type(uint256).max.
        AllowanceLib.safeApproveFallbackToMax(address(sell), address(broker), req.sellAmount);

        trade = broker.openTrade(kind, req, prices);
        trades[sell] = trade;
        tradesOpen++;
        tradesNonce++;

        emit TradeStarted(trade, sell, req.buy.erc20(), req.sellAmount, req.minBuyAmount);
    }

    // === Setters ===

    /// @custom:governance
    function setMaxTradeSlippage(uint192 val) public governance {
        require(val < MAX_TRADE_SLIPPAGE, "invalid maxTradeSlippage");
        emit MaxTradeSlippageSet(maxTradeSlippage, val);
        maxTradeSlippage = val;
    }

    /// @custom:governance
    function setMinTradeVolume(uint192 val) public governance {
        require(val <= MAX_TRADE_VOLUME, "invalid minTradeVolume");
        emit MinTradeVolumeSet(minTradeVolume, val);
        minTradeVolume = val;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}