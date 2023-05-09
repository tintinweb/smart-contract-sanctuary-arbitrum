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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.11;

import "../utils/Types.sol";

    
interface IFeesManager {

    enum FeeType{
        NOT_SET,
        FIXED,
        LINEAR_DECAY_WITH_AUCTION
    }


    struct RateData{
        FeeType rateType;
        uint48 startRate;
        uint48 endRate;
        uint48 auctionStartDate;
        uint48 auctionEndDate;
        uint48 poolExpiry;
    }

    error ZeroAddress();
    error NotAPool();
    error NoPermission();
    error InvalidType();
    error InvalidExpiry();
    error InvalidFeeRate();
    error InvalidFeeDates();

    event ChangeFee(address indexed pool, FeeType rateType, uint48 startRate, uint48 endRate, uint48 auctionStartDate, uint48 auctionEndDate);

    function setPoolRates(
        address _lendingPool,
        bytes32 _ratesAndType,
        uint48 _expiry,
        uint48 _protocolFee
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../utils/Types.sol";
interface IGenericPool {

    error TransferFailed();

    function getPoolSettings() external view returns (GeneralPoolSettings memory);
    function deposit(
        uint256 _depositAmount
    ) external;
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

interface IOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

import "../utils/Types.sol";

interface IPoolFactory {
    
    event DeployPool(
        address poolAddress,
        address deployer,
        address implementation,
        FactoryParameters factorySettings,
        GeneralPoolSettings poolSettings
    );

    error InvalidPauseTime();
    error OperationsPaused();
    error LendTokenNotSupported();
    error ColTokenNotSupported();
    error InvalidTokenPair();
    error LendRatio0();
    error InvalidExpiry();
    error ImplementationNotWhitelisted();
    error StrategyNotWhitelisted();
    error TokenNotSupportedWithStrategy();
    error ZeroAddress();
    error InvalidParameters();
    error NotGranted();
    error NotOwner();
    error NotAuthorized();



    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function protocolFee() external view returns (uint48);

    function repaymentsPaused() external view returns (bool);

    function isPoolPaused(address _pool, address _lendTokenAddr, address _colTokenAddr) external view returns (bool);

    function allowUpgrade() external view returns (bool);

    function implementations(PoolType _type) external view returns (address);

}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

interface IPositionTracker {

    struct Entry {
        bytes32 id;
        bytes32 prev;
        bytes32 next;
        address user;
        address pool;
    }

    error PositionIsAlreadyOpen();
    error PositionNotFound();
    error ZeroAddress();
    error NotAPool();
    error NotFactoryOrPool();
    
    function openBorrowPosition(address _borrower, address _pool) external;
    function openLendPosition(address _lender, address _pool) external;
    function closeBorrowPosition(address _borrower) external;
    function closeLendPosition(address _lender) external;
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */



pragma solidity ^0.8.11;
interface IStrategy {
    error NotAPool();

    function getDestination() external view returns (address);
    function currentBalance() external view returns (uint256);
    function beforeLendTokensSent(uint256 _amount) external;
    function afterLendTokensReceived(uint256 _amount) external;
    function beforeColTokensSent(uint256 _amount) external;
    function afterColTokensReceived(uint256 _amount) external;
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../../interfaces/IGenericPool.sol";

interface ILendingPool is IGenericPool {
    
    /* ========== EVENTS ========== */
    event Borrow(address indexed borrower, uint256 vendorFees, uint256 lenderFees, uint48 borrowRate, uint256 additionalColAmount, uint256 additionalDebt);
    event RollIn(address indexed borrower, address originPool, uint256 originDebt, uint256 lendToRepay, uint256 lenderFeeAmt, uint256 protocolFeeAmt, uint256 colRolled, uint256 colToReimburse);
    event Repay(address indexed borrower, uint256 debtRepaid, uint256 colReturned);
    event Collect(address indexed lender, uint256 lenderLend, uint256 lenderCol);
    event UpdateBorrower(address indexed borrower, bool allowed);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event RolloverPoolSet(address pool, bool enabled);
    event Withdraw(address indexed lender, uint256 amount);
    event Deposit(address indexed lender, uint256 amount);
    event WithdrawStrategyTokens(uint256 sharesAmount);
    event Pause(uint48 timestamp);
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== STRUCTS ========== */
    struct UserReport {
        uint256 debt;           // total borrowed in lend token
        uint256 colAmount;      // total collateral deposited by the borrower
    }

    /* ========== ERRORS ========== */
    error PoolNotWhitelisted();
    error OperationsPaused();
    error NotOwner();
    error ZeroAddress();
    error InvalidParameters();
    error PrivatePool();
    error PoolExpired();
    error FeeTooHigh();
    error BorrowingPaused();
    error NotEnoughLiquidity();
    error FailedStrategyWithdraw();
    error NoDebt();
    error PoolStillActive();
    error NotGranted();
    error UpgradeNotAllowed();
    error ImplementationNotWhitelisted();
    error RolloverPartialAmountNotSupported();
    error NotValidPrice();
    error NotPrivatePool();
    error DebtIsLess();
    error InvalidCollateralReceived();
    
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint48 _rate
    ) external returns (uint256 assetsBorrowed, uint256 lenderFees, uint256 vendorFees);

    function repayOnBehalfOf(
        address _borrower,
        uint256 _repayAmount
    ) external returns (uint256 lendTokenReceived, uint256 colReturnAmount);

    function debts(address _borrower) external returns (uint256, uint256);
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IPositionTracker.sol";
import "../../interfaces/IGenericPool.sol";
import "../../interfaces/IFeesManager.sol";
import "../../interfaces/IPoolFactory.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IOracle.sol";
import "../../utils/GenericUtils.sol";
import "./LendingPoolUtils.sol";
import "../../utils/Types.sol";
import "./ILendingPool.sol";

contract LendingPool is IGenericPool, ILendingPool, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    
    PoolType private constant poolType = PoolType.LENDING_ONE_TO_MANY;
    uint256 internal constant HUNDRED_PERCENT = 100_0000;
    address private _grantedOwner;

    mapping(address => UserReport) public debts;                        // Registry of all borrowers and their debt
    mapping(address => bool) public allowedBorrowers;                   // Mapping of allowed borrowers. 
    mapping(address => bool) public allowedRollovers;                   // Pools to which we can rollover.
    GeneralPoolSettings public poolSettings;                            // All the main setting of this pool.
    uint256 public lenderTotalFees;

    IPositionTracker public positionTracker;
    IFeesManager public feesManager;
    IPoolFactory public factory;
    IStrategy public strategy;
    IOracle public oracle;
    address public treasury;
    
    /// @notice                              Acts as lending pool contract constructor when pool is deployed. This function validates params,
    ///                                      establishes user defined pool settings and factory settings, whitelists addresses for private pool
    ///                                      if applicatble, and initializes strategy if applicable.
    /// @param _factoryParametersBytes       Contains addresses for external contracts that support this pool. These params should remain constant
    ///                                      for all pools, and are passed by the pool factory, not the user.
    /// @param _poolSettingsBytes            Pool specific settings (set by user). The fields for these settings can be found in: Types.sol  
    /// @dev                                 The third bytes param is used for any kind of additional data needed in a pool. Not used in this pool type.  
    function initialize(
        bytes calldata _factoryParametersBytes,
        bytes calldata _poolSettingsBytes,
        bytes calldata /*_additionalData*/  // Not used in this type of pool.
    ) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        FactoryParameters memory _factoryParameters = abi.decode(_factoryParametersBytes, (FactoryParameters));
        GeneralPoolSettings memory _poolSettings = abi.decode(_poolSettingsBytes, (GeneralPoolSettings));
        
        factory = IPoolFactory(msg.sender);
        if (
            address(_poolSettings.colToken) == address(0) ||
            address(_poolSettings.lendToken) == address(0) ||
            _poolSettings.owner == address(0) ||
            _factoryParameters.feesManager == address(0) ||
            _factoryParameters.oracle == address(0) ||
            _factoryParameters.treasury == address(0) ||
            _factoryParameters.posTracker == address(0)
        ) revert ZeroAddress();
        if (
            _poolSettings.lendRatio == 0 ||
            _poolSettings.expiry <= block.timestamp ||
            _poolSettings.poolType != poolType
        ) revert InvalidParameters();
        poolSettings = _poolSettings;
        feesManager = IFeesManager(_factoryParameters.feesManager);
        oracle = IOracle(_factoryParameters.oracle);
        treasury = _factoryParameters.treasury;
        positionTracker = IPositionTracker(_factoryParameters.posTracker);

        if (_poolSettings.allowlist.length > 0) {
            for (uint256 j = 0; j != _poolSettings.allowlist.length;) {
                allowedBorrowers[_poolSettings.allowlist[j]] = true;
                unchecked {++j;}
            }
        }
        if (_factoryParameters.strategy != bytes32(0)){
            strategy = GenericUtils.initiateStrategy(_factoryParameters.strategy, _poolSettings.lendToken, _poolSettings.colToken);
        }
    }

    /// @notice                        Facilitates borrowing on behalf of the _borrower param address. A user shall deposit collateral
    ///                                in exchange for lend tokens. See Vendor documentation for more information on borrowing: 
    ///                                https://docs.vendor.finance/how-to-use/borrow
    /// @param _borrower               The address to which the lend funds will be sent. The entire borrow position will be setup for this borrower address, 
    ///                                the idea here being that a user could borrow on behalf of another address.
    /// @param _colDepositAmount       The amount of collateral a borrower wishes to deposit in exchange for N amount of lend tokens.
    /// @param _rate                   The borrow rate for the pool. This is passed by users to prevent possible front running by lenders.
    /// @return assetsBorrowed         The amount of lend tokens the specified _borrower address will receive._borrower
    /// @return lenderFees             The amount of lend tokens paid to lender. Also known as a lender fee.
    /// @return vendorFees             The amount of lend tokens paid to protocol. Also known as the protocol fee.
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint48 _rate
    ) external nonReentrant returns (uint256 assetsBorrowed, uint256 lenderFees, uint256 vendorFees){
        uint48 effectiveBorrowRate = feesManager.getCurrentRate(address(this)); //Term fee rate that the borrower will actually be charged.
        uint48 maxLTV = poolSettings.ltv;
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        uint256 lendRatio = poolSettings.lendRatio;
        // Validations
        if (_colDepositAmount == 0) revert NoDebt();
        if (factory.isPoolPaused(address(this), address(lendToken), address(colToken))) revert OperationsPaused();
        if ((poolSettings.allowlist.length > 0) && (!allowedBorrowers[_borrower])) revert PrivatePool();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();
        // Undercollateralized loans skip price check.
        if(maxLTV != type(uint48).max && !GenericUtils.isValidPrice(oracle, colToken, lendToken, lendRatio, maxLTV, poolType)) revert NotValidPrice();
        // User passed _rate must be larger or equal to the current pool's rate. Otherwise lender might front run borrow transaction and set the fee to a high number. 
        if (_rate < effectiveBorrowRate) revert FeeTooHigh();
        if (poolSettings.pauseTime <= block.timestamp) revert BorrowingPaused(); // If lender disabled borrowing. Repay and rollover out should still work.

        uint256 collateralReceived =  GenericUtils.safeTransferFrom(colToken, msg.sender, address(this), _colDepositAmount);
        // Compute the principal and the owed fees for this borrow based on the collateral passed in
        // Fees are included in the assetsBorrowed as well
        (
            lenderFees,     // Fees borrower will pay to lender
            assetsBorrowed  // Principal borrower will get before lender fee and protocol fee is subtracted
        ) = LendingPoolUtils.computeDebt(
            lendToken, 
            colToken, 
            lendRatio, 
            collateralReceived, 
            effectiveBorrowRate
        );
        UserReport storage report = debts[_borrower];
        // Start a new position tracker if does not yet exist
        if (report.debt == 0) positionTracker.openBorrowPosition(_borrower, address(this));
        // Save the users debt
        report.colAmount += collateralReceived;
        report.debt += assetsBorrowed;

        if (lendBalance() < assetsBorrowed)
            revert NotEnoughLiquidity();
        if (address(strategy) != address(0)) {
            uint256 initLendTokenBalance = lendToken.balanceOf(address(this));
            strategy.beforeLendTokensSent(assetsBorrowed- lenderFees); // We only need to withdraw the parts that need to be sent from the contract, lender fee stays. NOTE: Taxable tokens should not work with strategy. 
            if (lendToken.balanceOf(address(this)) - initLendTokenBalance < assetsBorrowed - lenderFees) revert FailedStrategyWithdraw();
        }
        // Vendor fee is charged from the loaned funds
        vendorFees = assetsBorrowed * poolSettings.protocolFee / HUNDRED_PERCENT;
        GenericUtils.safeTransfer(lendToken, treasury, vendorFees);
        GenericUtils.safeTransfer(lendToken, _borrower, assetsBorrowed - vendorFees - lenderFees);
    
        lenderTotalFees += lenderFees;
        emit Borrow(_borrower, vendorFees, lenderFees, effectiveBorrowRate, collateralReceived, assetsBorrowed);
    }

    /// @notice                         Facilitates the repayment of debt (lend tokens) on behalf of the _borrower param address.
    /// @param _borrower                The borrower address whose debt will be paid off.
    /// @param _repayAmount             The amount of lend tokens that are to be repaid. In cases where the lend token is taxable, 
    ///                                 this is the pre-tax value.
    /// @return lendTokenReceived       The actual amount of lend tokens repaid/received in this pool.
    /// @return colReturnAmount         The amount of collateral tokens returned to _borrower address when lent funds are repaid.
    function repayOnBehalfOf(
        address _borrower,
        uint256 _repayAmount
    ) external nonReentrant returns (uint256 lendTokenReceived, uint256 colReturnAmount){
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        onlyNotPausedRepayments();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired(); // Collateral was defaulted
        UserReport storage report = debts[_borrower];
        if (report.debt == 0) revert NoDebt();
        if (_repayAmount > report.debt)
            revert DebtIsLess();
        if (factory.pools(msg.sender)) { // If rollover
            if (_repayAmount != report.debt) revert RolloverPartialAmountNotSupported();
            if (!allowedRollovers[msg.sender]) revert PoolNotWhitelisted();
            GenericUtils.safeTransfer(colToken, msg.sender, report.colAmount);
            delete debts[_borrower];
        }else{
            lendTokenReceived = GenericUtils.safeTransferFrom(lendToken, msg.sender, address(this), _repayAmount);
            // If we are repaying the whole debt, then the borrow amount should be set to 0 and all collateral should be returned
            // without computation to avoid  dust remaining in the pool
            colReturnAmount = lendTokenReceived == report.debt
                ? report.colAmount
                : LendingPoolUtils.computeCollateralReturn(
                    lendTokenReceived,
                    poolSettings.lendRatio,
                    colToken,
                    lendToken
                );
            report.debt -= lendTokenReceived;
            report.colAmount -= colReturnAmount;
            GenericUtils.safeTransfer(colToken, _borrower, colReturnAmount);
            if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendTokenReceived);
        }
        if (report.debt == 0){
            positionTracker.closeBorrowPosition(_borrower);
        }
        emit Repay(_borrower, lendTokenReceived, colReturnAmount);
    }

    /// @notice       After pool expiry, the pool owner (lender) can collect any repaid lend funds and or any defaulted collateral.
    function collect() external nonReentrant {
        IERC20 lendToken = poolSettings.lendToken;
        IERC20 colToken = poolSettings.colToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(colToken))) revert OperationsPaused();
        if (block.timestamp <= poolSettings.expiry) revert PoolStillActive();     // Withdraw should be used before pool expiry
        if (address(strategy) != address(0)) strategy.beforeLendTokensSent(type(uint256).max);
        address owner = poolSettings.owner;
        // We record the amount that are pre-tax for taxable tokens. As far as we concerned we need to know how much we sent.
        // Receiver can compute how much they got themselves.
        uint256 lendAmount = lendToken.balanceOf(address(this));
        GenericUtils.safeTransfer(lendToken, owner, lendAmount);
        uint256 colAmount = colToken.balanceOf(address(this));
        GenericUtils.safeTransfer(colToken, owner, colAmount);

        positionTracker.closeLendPosition(owner);
        emit Collect(msg.sender, lendAmount, colAmount);
    }

    /// @notice                     The pool owner (lender) can call this function to add funds they wish to lend out into the pool.
    /// @param _depositAmount       The amount of lend tokens that a lender wishes to seed pool with. In cases where the lend token is taxable, 
    ///                             this is the pre-tax value.
    function deposit(
        uint256 _depositAmount
    ) external nonReentrant {
        IERC20 lendToken = poolSettings.lendToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(poolSettings.colToken))) revert OperationsPaused();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();
        uint256 lendTokenReceived = GenericUtils.safeTransferFrom(lendToken, msg.sender, address(this), _depositAmount);
        if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendTokenReceived);
        emit Deposit(msg.sender, lendTokenReceived);
    }

    /// @notice                  Rollover loan into a pool that has been deployed by the same lender as the original one.
    /// @dev                     Pools must have the same lend/col tokens as well as lender. New pool must also have longer expiry.
    /// @param _originPool       Address of the pool we are trying to rollover from.
    /// @param _rate             Max rate that this pool should charge the user.
    /// @param _originDebt       The original debt of the user, passed as param to reduce external calls.
    ///
    /// There are three cases that we need to consider: new and old pools have same mint ratio,
    /// new pool has higher mint ratio or new pool has lower mint ratio.
    /// Same Mint Ratio - In this case we simply move the old collateral to the new pool and pass old debt.
    /// New MR > Old MR - In this case new pool gives more lend token per unit of collateral so we need less collateral to 
    /// maintain same debt. We compute the collateral amount to reimburse using the following formula:
    ///             oldColAmount * (newMR-oldMR)
    ///             ---------------------------- ;
    ///                        newMR
    /// Derivation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio 3m, 
    /// that we would like to rollover into, then m/3m=1/3 is the amount of collateral required to borrow the same amount
    /// of lend token in pool B. If we give 3 times more debt for unit of collateral, then we need 3 times less collateral
    /// to maintain same debt level.
    /// Now if we do that with a slightly different notation:
    /// Assuming we have a mint ratio of pool A that is m and we also have a new pool that has a mint ratio M, 
    /// that we would like to rollover into. Then m/M is the amount of collateral required to borrow the same amount of lend token in pool B. 
    /// In that case fraction of the collateral amount to reimburse is: 
    ///            m            M     m           (M-m) 
    ///       1 - ----    OR   --- - ----   OR   ------ ;
    ///            M            M     M             M
    /// If we multiply this fraction by the original collateral amount, we will get the formula above. 
    /// Third and last case New MR < Old MR - In this case we need more collateral to maintain the same debt. Since we can not expect borrower
    /// to have more collateral token on hand it is easier to ask them to return a fraction of borrowed funds using formula:
    ///             oldColAmount * (oldMR - newMR) ;
    /// This formula basically computes how much over the new mint ratio you were lent given you collateral deposit.
    function rollInFrom(
        address _originPool,
        uint256 _originDebt,
        uint48 _rate
    ) external nonReentrant {
        ILendingPool originPool = ILendingPool(_originPool);
        GeneralPoolSettings memory settings = poolSettings; // Need to load struct, otherwise the stack depth becomes an issue
        GeneralPoolSettings memory originSettings = originPool.getPoolSettings();
        if ((settings.allowlist.length > 0) && (!allowedBorrowers[msg.sender])) revert PrivatePool();
        uint48 effectiveBorrowRate = feesManager.getCurrentRate(address(this));
        if (settings.pauseTime <= block.timestamp) revert BorrowingPaused();
        if (effectiveBorrowRate > _rate) revert FeeTooHigh();
        if (factory.isPoolPaused(address(this), address(settings.lendToken), address(settings.colToken))) revert OperationsPaused();
        if (block.timestamp > settings.expiry) revert PoolExpired();    // Can not roll into an expired pool
        LendingPoolUtils.validatePoolForRollover(
            originSettings,
            settings,
            _originPool,
            factory
        );
        uint256 colReturned;
        { // Saving some stack space
            (, uint256 colExpected) = originPool.debts(msg.sender);
            uint256 initColBalance = settings.colToken.balanceOf(address(this));
            originPool.repayOnBehalfOf(msg.sender, _originDebt);
            colReturned = settings.colToken.balanceOf(address(this)) - initColBalance;
            if (colReturned != colExpected) revert InvalidCollateralReceived();
        }
        (uint256 colToReimburse, uint256 lendToRepay) = LendingPoolUtils.computeRolloverDifferences(originSettings, settings, colReturned);
        if (colToReimburse > 0) GenericUtils.safeTransfer(settings.colToken, msg.sender, colToReimburse);

        UserReport storage report = debts[msg.sender];
        // Start a new position tracker if does not yet exist
        if (report.debt == 0) positionTracker.openBorrowPosition(msg.sender, address(this));
        // Save the users debt
        uint256 newDebt = (_originDebt - lendToRepay); // _originDebt was checked in the repayMethod of the origin pool
        report.colAmount += colReturned - colToReimburse;
        report.debt += newDebt;
        uint256 fee = (newDebt * effectiveBorrowRate) / HUNDRED_PERCENT; // Lender Fee
        lendToRepay += fee; // Add the lender fee to the amount the borrower needs to reimburse (if any) to pull all tokens at once
        lenderTotalFees += fee;
        if (GenericUtils.safeTransferFrom(settings.lendToken, msg.sender, address(this), lendToRepay) != lendToRepay) revert TransferFailed();
        uint256 protocolFee = (newDebt * settings.protocolFee) / HUNDRED_PERCENT; // Vendor fee
        if (GenericUtils.safeTransferFrom(settings.lendToken, msg.sender, treasury, protocolFee) != protocolFee) revert TransferFailed();
        if (address(strategy) != address(0)) strategy.afterLendTokensReceived(lendToRepay);

        emit RollIn(msg.sender, _originPool, _originDebt, lendToRepay - fee, fee, protocolFee, colReturned, colToReimburse);
    }

    /// @notice                      Enables the pool owner (lender) to withdraw funds they have deposited into the pool. These funds cannot 
    ///                              have been lent out yet.
    /// @param _withdrawAmount       The amount of lend tokens not currently lent out that the pool owner (lender) wishes to withdraw from the pool.
    function withdraw(
        uint256 _withdrawAmount
    ) external nonReentrant {
        onlyOwner();
        IERC20 lendToken = poolSettings.lendToken;
        if (factory.isPoolPaused(address(this), address(lendToken), address(poolSettings.colToken))) revert OperationsPaused();
        if (block.timestamp > poolSettings.expiry) revert PoolExpired();    // Use collect after expiry of the pool
        uint256 balanceChange;
        uint256 availableLendBalance;
        if (address(strategy) != address(0)) {
            uint256 initLendTokenBalance = lendToken.balanceOf(address(this));
            strategy.beforeLendTokensSent(_withdrawAmount); // Taxable tokens should not work with strategy.
            balanceChange = lendToken.balanceOf(address(this)) - initLendTokenBalance;
            availableLendBalance = balanceChange;
            if (_withdrawAmount != type(uint256).max && balanceChange < _withdrawAmount) revert FailedStrategyWithdraw();
        } else {
            balanceChange = _withdrawAmount;
            availableLendBalance = lendToken.balanceOf(address(this));
        }
        lenderTotalFees = _withdrawAmount < lenderTotalFees ? lenderTotalFees - _withdrawAmount : 0;
        // availableLendBalance < balanceChange when we want to withdraw the whole pool by passing the uint256.max and no strat
        // availableLendBalance > balanceChange when we only withdraw a part of the lend funds
        _withdrawAmount = availableLendBalance > balanceChange ? balanceChange : availableLendBalance;
        GenericUtils.safeTransfer(lendToken, poolSettings.owner, _withdrawAmount);

        emit Withdraw(msg.sender, _withdrawAmount);
    }

    /// @notice       In cases where pool is using a strategy, the pool owner (lender) can withdraw the actual share tokens 
    ///               representing their underlying lend tokens. For more information about strategies, see: https://docs.vendor.finance/overview/what-is-vendor-finance
    /// @dev          Shares represent invested idle funds, thus I should be able to withdraw them without issues.
    function withdrawStrategyTokens() external nonReentrant {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        if (address(strategy) == address(0)) revert FailedStrategyWithdraw();
        delete lenderTotalFees; // Assuming there is a strat all lender fees are there. If we pool all funds from strat, that means we also pull the fees.
        // Assumption that is made here is that destination is ERC20 compatible, otherwise it will revert. For example a ERC4626 vault.
        uint256 sharesAmount = IERC20(strategy.getDestination()).balanceOf(address(this));
        GenericUtils.safeTransfer(IERC20(strategy.getDestination()), poolSettings.owner, sharesAmount);
        emit WithdrawStrategyTokens(sharesAmount);
    }

    /// @notice                Allows the lender to whitelist or blacklist an address in a private pool
    /// @param _borrower       Address to whitelist or blacklist in private pool.
    /// @param _allowed        Determines whether provided address will be whitelisted or blacklisted.
    /// @dev                   Will not affect anything if the pool is not private
    function updateBorrower(address _borrower, bool _allowed) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        if (poolSettings.allowlist.length == 0) revert NotPrivatePool();
        allowedBorrowers[_borrower] = _allowed;
        emit UpdateBorrower(_borrower, _allowed);
    }

    /// @notice                First step in a process of changing the owner.
    /// @param _newOwner       Address to be made pool owner. 
    function grantOwnership(address _newOwner) external {
        onlyOwner();
        _grantedOwner = _newOwner;
    }

    /// @notice       Second step in the process of changing the owner. The set owner in step1 calls this fc to claim ownership.
    function claimOwnership() external {
        if (_grantedOwner != msg.sender) revert NotGranted();
        emit OwnershipTransferred(poolSettings.owner, _grantedOwner);
        poolSettings.owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /* ========== SETTERS ========== */
    /// @notice               Allow the lender to select rollover pools.
    /// @param _pool          The pool address the pool owner (lender) would like to whitelist or black list for rollovers.
    /// @param _enabled       Determines whether the _pool param address is whitelisted or blacklisted.
    function setRolloverPool(address _pool, bool _enabled) external {
        onlyOwner();
        allowedRollovers[_pool] = _enabled;
        emit RolloverPoolSet(_pool, _enabled);
    }

    /// @notice                    Sets new rates for lending pool.
    /// @param _ratesAndType       The bytes string used to set rates.
    /// @dev                       Setting fees should be done via the pool and not directly in FeesManager contract for two reasons:
    ///                            - 1) All changes to this contract should be visible by tracking transactions to this contract. 
    ///                            - 2) Different pool types might have different fee changing rules so we can ensure they are followed.
    function setPoolRates(bytes32 _ratesAndType) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        feesManager.setPoolRates(address(this), _ratesAndType, poolSettings.expiry, poolSettings.protocolFee);
    }

    /// @notice                 Pool owner (lender) can pause borrowing for this pool
    /// @param _timestamp       The timestamp that denotes when borrowing for this pool is to be paused.
    function setPauseBorrowing(uint48 _timestamp) external {
        onlyOwner();
        if (factory.isPoolPaused(address(this), address(poolSettings.lendToken), address(poolSettings.colToken))) 
            revert OperationsPaused();
        poolSettings.pauseTime = _timestamp;
        emit Pause(_timestamp);
    }

    /* ========== GETTERS ========== */
    /// @return       Returns the pool settings used in this pool.
    function getPoolSettings() external view returns (GeneralPoolSettings memory){
        return poolSettings;
    }

    /// @return       The amount of lend funds that are available to be lent out.
    function lendBalance() public view returns (uint256) {
        uint256 fullLendTokenBalance = address(strategy) == address(0) ? poolSettings.lendToken.balanceOf(address(this)) : strategy.currentBalance();
        // Due to rounding it is possible that strat returns a few wei less than actual fees earned. To avoid revert send 0.
        // On rollover it is possible that lender fees are present since they are paid up front but there was no deposits for lending. In this case entire strategy balance 
        // consists of rollover fees. They should not be borrowable. 
        return fullLendTokenBalance <= lenderTotalFees ? 0 : fullLendTokenBalance - lenderTotalFees; 
    }

    /// @return       The total balance of collateral tokens in pool.
    function colBalance() public view returns (uint256) {        
        return poolSettings.colToken.balanceOf(address(this));  
    }

    /* ========== MODIFIERS ========== */
    /// @notice       Validates that the caller is the pool owner (lender).
    function onlyOwner() private view {
        if (msg.sender != poolSettings.owner) revert NotOwner();
    }

    /// @notice       Validates that the pool has not been paused by the pool factory. 
    function onlyNotPausedRepayments() private view {
        if (factory.repaymentsPaused()) revert OperationsPaused();
    }

    /* ========== UPGRADES ========== */
    /// @notice                  Contract version for history.
    /// @return                  Contract version.
    function version() external pure returns (uint256) {
        return 1;
    }

    /// @notice      Allows for the upgrade of pool to new implementation.
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        onlyOwner();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed();
        if (newImplementation != factory.implementations(poolType)) revert ImplementationNotWhitelisted();
    }
  
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "../../interfaces/IPoolFactory.sol";
import "../../interfaces/IFeesManager.sol";
import "../../interfaces/IGenericPool.sol";
import "../../utils/Types.sol";
import "./ILendingPool.sol";

library LendingPoolUtils {
    
    /* ========== ERRORS ========== */ 
    error NotAPool();
    error DifferentLendToken();
    error DifferentColToken();
    error DifferentPoolOwner();
    error InvalidExpiry();
    error PoolTypesDiffer();
    error UnableToChargeFullFee();

    /* ========== CONSTANTS ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== FUNCTIONS ========== */

    /// @notice                     Performs validation checks to ensure that both origin and destination pools are valid for the rollover transaction.
    /// @param originSettings       The pool settings of the origin pool.
    /// @param settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _originPool          The address of the origin pool.
    /// @param _factory             The address of the pool factory.
    function validatePoolForRollover(
        GeneralPoolSettings memory originSettings,
        GeneralPoolSettings memory settings,
        address _originPool,
        IPoolFactory _factory
    ) external view {
        if (!_factory.pools(_originPool)) revert NotAPool();
        
        if (originSettings.lendToken != settings.lendToken)
            revert DifferentLendToken();

        if (originSettings.colToken != settings.colToken)
            revert DifferentColToken();

        if (originSettings.owner != settings.owner) revert DifferentPoolOwner();

        if (settings.expiry <= originSettings.expiry) revert InvalidExpiry(); // This also prevents pools to rollover into itself

        if (settings.poolType != originSettings.poolType ) revert PoolTypesDiffer();
    }

    /// @notice                      Computes lend token and collateral token amount differences in origin pool and destination pools.
    /// @param _originSettings       The pool settings of the origin pool.
    /// @param _settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _colReturned          The amount of collateral moved xfered from origin pool to destination pool.
    /// @return colToReimburse       The amount of collateral to refund borrower in cases where the destination pool's lend ratio is greater than origin pool's lend ratio.
    /// @return lendToRepay          The amount of lend tokens that the borrower must repay in cases where the destination pool's lend ratio less than the origin pool's lend ratio.
    function computeRolloverDifferences(
        GeneralPoolSettings memory _originSettings,
        GeneralPoolSettings memory _settings,
        uint256 _colReturned
    ) external view returns (uint256 colToReimburse, uint256 lendToRepay){
        if (_settings.lendRatio <= _originSettings.lendRatio) { // Borrower needs to repay
            lendToRepay = _computePayoutAmount(
                _colReturned,
                _originSettings.lendRatio - _settings.lendRatio,
                _settings.colToken,
                _settings.lendToken
            );
        }else{ // We need to send collateral
            colToReimburse = _computeReimbursement(
                _colReturned,
                _originSettings.lendRatio,
                _settings.lendRatio
            );
            _colReturned -= colToReimburse;
        }
    }

    /// @notice                        Computes the amount of lend tokens that the borrower will receive. Also computes lender fee amount.
    /// @param _lendToken              Address of lend token.
    /// @param _colToken               Address of collateral token.
    /// @param _mintRatio              Amount of lend tokens to lend for every one unit of deposited collateral.
    /// @param _colDepositAmount       Actual amount of collateral tokens deposited by borrower.
    /// @param _effectiveRate          Borrow rate of pool.
    /// @return additionalFees         Fee amount owed to the lender.
    /// @return rawPayoutAmount        Lend token amount borrower will receive before lender fees and protocol fees are subtracted.
    function computeDebt(
        IERC20 _lendToken,
        IERC20 _colToken,
        uint256 _mintRatio,
        uint256 _colDepositAmount,
        uint48 _effectiveRate
    ) external view returns (uint256 additionalFees, uint256 rawPayoutAmount){
        
        rawPayoutAmount = _computePayoutAmount(
            _colDepositAmount,
            _mintRatio,
            _colToken,
            _lendToken
        );
        additionalFees = (rawPayoutAmount * _effectiveRate) / HUNDRED_PERCENT;
    }
    
    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _lendRatio           LendRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral.
    /// LendRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = lendRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(
        uint256 _colDepositAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) private view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals) {
            return
                (_colDepositAmount * _lendRatio) /
                (10**(colDecimals + mintDecimals - lendDecimals));
        } else {
            return
                (_colDepositAmount * _lendRatio) *
                (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    
    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _lendRatio           LendRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    /// Amount of collateral to return is always computed as:
    ///                                 lendTokenAmount
    /// amountOfCollateralReturned  =   ---------------
    ///                                    lendRatio
    /// 
    /// We also need to ensure that the correct amount of decimals are used. Output should always be in
    /// collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_lendRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _lendRatio;
        }
    }

    /// @notice                  Compute the amount of collateral that needs to be sent to user when rolling into a pool with higher mint ratio
    /// @param _colAmount        Collateral amount deposited into the original pool
    /// @param _lendRatio        LendRatio of the original pool
    /// @param _newLendRatio     LendRatio of the new pool
    /// @return                  Collateral reimbursement amount.
    function _computeReimbursement(
        uint256 _colAmount,
        uint256 _lendRatio,
        uint256 _newLendRatio
    ) private pure returns (uint256) {
        return (_colAmount * (_newLendRatio - _lendRatio)) / _newLendRatio;
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IPoolFactory.sol";
import "../interfaces/IFeesManager.sol";
import "../interfaces/IGenericPool.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IOracle.sol";
import "./Types.sol";

library GenericUtils {
    using SafeERC20 for IERC20;

    uint256 internal constant HUNDRED_PERCENT = 100_0000;
    bytes32 private constant APPROVE_LEND = 0x1000000000000000000000000000000000000000000000000000000000000000; //1<<255
    bytes32 private constant APPROVE_COL = 0x0100000000000000000000000000000000000000000000000000000000000000; //2<<255
    bytes32 private constant APPROVE_LEND_STRATEGY = 0x0010000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant APPROVE_COL_STRATEGY = 0x0001000000000000000000000000000000000000000000000000000000000000;
   
    /* ========== EVENTS ========== */
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== ERRORS ========== */
    error OracleNotSet();

    /* ========== FUNCTIONS ========== */
    
    /// @notice                Makes required strategy approvals based off whether the collateral or lend token is being used.
    /// @param _strategy       The key used with the strategy.
    /// @param _lendToken      The address of lend token being used. 
    /// @param _colToken      The address of collateral token being used. 
    function initiateStrategy(bytes32 _strategy, IERC20 _lendToken, IERC20 _colToken) external returns (
        IStrategy strategy
    ){
        address strategyAddress = address(uint160(uint256(_strategy)));
        strategy = IStrategy(strategyAddress);
        // Allow strategy to manage the lend vault tokens on behalf of the pool. Useful with strategies that wrap EIP4626 vaults.
        if ((_strategy & APPROVE_LEND_STRATEGY) == APPROVE_LEND_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL_STRATEGY) == APPROVE_COL_STRATEGY) {
            IERC20(IStrategy(strategyAddress).getDestination()).approve(strategyAddress, type(uint256).max);
        }
        if ((_strategy & APPROVE_LEND) == APPROVE_LEND) {
            _lendToken.approve(strategyAddress, type(uint256).max);
        } 
        if ((_strategy & APPROVE_COL) == APPROVE_COL) {
            _colToken.approve(strategyAddress, type(uint256).max);
        }
    }
  
    /// @notice                  Check if col price is valid based off of LTV requirement
    /// @dev                     We need to ensure that 1 unit of collateral is worth more than what 1 unit of collateral allows to borrow
    /// @param _priceFeed        Address of the oracle to use
    /// @param _colToken         Address of the collateral token
    /// @param _lendToken        Address of the lend token
    /// @param _mintRatio        Mint ratio of the pool
    /// @param _ltv              Dictated as minLTV or maxLTV dependent on _poolType
    /// @param _poolType         The type of pool calling this function
    function isValidPrice(
        IOracle _priceFeed,
        IERC20 _colToken,
        IERC20 _lendToken,
        uint256 _mintRatio,
        uint48 _ltv,
        PoolType _poolType
    ) external view returns (bool) {
        if (address(_priceFeed) == address(0)) revert OracleNotSet();
        int256 priceLend = _priceFeed.getPriceUSD(address(_lendToken));
        int256 priceCol = _priceFeed.getPriceUSD(address(_colToken));
        if (priceLend > 0 && priceCol > 0) { // Check that -1 or other invalid value was not returned for both assets
            if (_poolType == PoolType.LENDING_ONE_TO_MANY) {
                uint256 maxLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return maxLendValue >= ((_mintRatio * uint256(priceLend)) / 1e18);
            } else if (_poolType == PoolType.BORROWING_ONE_TO_MANY) {
                uint256 minLendValue = (uint256(priceCol) * _ltv) / HUNDRED_PERCENT;
                return minLendValue <= ((_mintRatio * uint256(priceLend)) / 1e18);
            }
        }
        return false;
    }

    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _mintRatio           MintRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    // Amount of collateral to return is always computed as:
    //                                 lendTokenAmount
    // amountOfCollateralReturned  =   ---------------
    //                                    mintRatio
    // 
    // We also need to ensure that the correct amount of decimals are used. Output should always be in
    // collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _mintRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _mintRatio;
        }
    }

    /// @notice               Used when xfering tokens to an address from a pool.
    /// @param _token         Address of token that is to be xfered.
    /// @param _account       Address to send tokens to.
    /// @param _amount        Amount of tokens to xfer.
    function safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) external{
        if (_amount > 0){
            _token.safeTransfer(_account, _amount);
            emit BalanceChange(address(_token), _account, false, _amount);
        }
    }

    /// @notice              Used when xfering tokens on an addresses behalf. Approval must be done in a seperate transaction.
    /// @param _token        Address of token that is to be xfered.
    /// @param _from         Address of the sender.
    /// @param _to           Address of the recipient.
    /// @param _amount       Amount of tokens to xfer.
    /// @return received     Actual amount of tokens that _to receives.
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256 received){
        if (_amount > 0){
            uint256 initialBalance = _token.balanceOf(_to);
            _token.safeTransferFrom(_from, _to, _amount);
            received = _token.balanceOf(_to) - initialBalance;
            emit BalanceChange(address(_token), _to, true, received);
        }
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

enum PoolType{
    LENDING_ONE_TO_MANY,
    BORROWING_ONE_TO_MANY
}

/* ========== STRUCTS ========== */
struct DeploymentParameters {
    uint256 lendRatio;
    address colToken;
    address lendToken;
    bytes32 feeRatesAndType;
    PoolType poolType;
    bytes32 strategy;
    address[] allowlist;
    uint256 initialDeposit;
    uint48 expiry;
    uint48 ltv;
    uint48 pauseTime;
}

struct FactoryParameters {
    address feesManager;
    bytes32 strategy;
    address oracle;
    address treasury;
    address posTracker;
}

struct GeneralPoolSettings {
    PoolType poolType;
    address owner;
    uint48 expiry;
    IERC20 colToken;
    uint48 protocolFee;
    IERC20 lendToken;
    uint48 ltv;
    uint48 pauseTime;
    uint256 lendRatio;
    address[] allowlist;
    bytes32 feeRatesAndType;
}