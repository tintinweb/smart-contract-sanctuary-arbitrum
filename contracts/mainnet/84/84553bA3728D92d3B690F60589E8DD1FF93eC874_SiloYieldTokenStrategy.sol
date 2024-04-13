// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method _must_ be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
  function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
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
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFlashLoans {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@cryptoalgebra/core/contracts/interfaces/callback/IAlgebraSwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ICamelotRouter is IAlgebraSwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IFactorLeverageVault {
    function isRegisteredUpgrade(
        address baseImplementation,
        address upgradeImplementation
    ) external view returns (bool);

    function registerUpgrade(address baseImplementation, address upgradeImplementation) external;

    function createPosition(address asset, address debt) external returns (uint256 id, address vault);

    function assets(address) external view returns (address);

    function asset() external view returns (address);

    function debtToken() external view returns (address);

    function assetBalance() external view returns (uint256);

    function debtBalance() external view returns (uint256);

    function leverageFee() external view returns (uint256);

    function debts(address) external view returns (address);

    function claimRewardFee() external view returns (uint256);

    function version() external view returns (string memory);

    function feeRecipient() external view returns (address);

    function FEE_SCALE() external view returns (uint256);

    function positions(uint256) external view returns (address);

    function initialize(uint256, address, address, address, address, address) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILeverageStrategy {
    function vaultManager() external view returns (address);

    function positionId() external view returns (uint256);

    function asset() external view returns (address);

    function debtToken() external view returns (address);

    function assetPool() external view returns (address);

    function debtPool() external view returns (address);

    function assetBalance() external returns (uint256);

    function debtBalance() external returns (uint256);

    function owner() external view returns (address);

    function addLeverage(uint256 amount, uint256 debt, bytes calldata data) external;

    function removeLeverage(uint256 amount, bytes calldata data) external;

    function closeLeverage(uint256 amount, bytes calldata data) external;

    function supply(uint256 withdraw) external;

    function borrow(uint256 debt) external;

    function repay(uint256 amount) external;

    function withdraw(uint256 withdraw) external;

    function version() external returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IOpenOceanExchange {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IPendleMarket {
    function redeemRewards(address user) external returns (uint256[] memory);
    function getRewardTokens() external view returns (address[] memory);
    function mint(
        address receiver,
        uint256 netSyDesired,
        uint256 netPtDesired
    ) external returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function readTokens() external view returns (address _SY, address _PT, address _YT);
}

interface IPLimitOrderType {
    enum OrderType {
        SY_FOR_PT,
        PT_FOR_SY,
        SY_FOR_YT,
        YT_FOR_SY
    }
}

interface IPendleRouterV3 {
    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }

    struct Order {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        IPLimitOrderType.OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
        bytes permit;
    }
    struct FillOrderParams {
        Order order;
        bytes signature;
        uint256 makingAmount;
    }

    struct LimitOrderData {
        address limitRouter;
        uint256 epsSkipMarket; // only used for swap operations, will be ignored otherwise
        FillOrderParams[] normalFills;
        FillOrderParams[] flashFills;
        bytes optData;
    }
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain; // pass 0 in to skip this variable
        uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
        uint256 eps; // the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
        // to 1e15 (1e18/1000 = 0.1%)
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    struct TokenInput {
        // Token/Sy data
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    struct TokenOutput {
        // Token/Sy data
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    ) external payable returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy,
        LimitOrderData calldata limit
    ) external returns (uint256 netPtOut, uint256 netSyFee);
}

interface IPendleRouter {
    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain; // pass 0 in to skip this variable
        uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
        uint256 eps;
    }
    struct TokenInput {
        // Token/Sy data
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }
    struct TokenOutput {
        // Token/Sy data
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        address bulk;
        // aggregator data
        address pendleSwap;
        SwapData swapData;
    }

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minLpOut,
        ApproxParams calldata guessPtReceivedFromSy,
        TokenInput calldata input
    ) external payable returns (uint256 netLpOut, uint256 netSyFee);

    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);

    function addLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netPtIn,
        uint256 minLpOut,
        ApproxParams calldata guessPtSwapToSy
    ) external returns (uint256 netLpOut, uint256 netSyFee);

    function removeLiquiditySinglePt(
        address receiver,
        address market,
        uint256 netLpToRemove,
        uint256 minPtOut,
        ApproxParams calldata guessPtReceivedFromSy
    ) external returns (uint256 netPtOut, uint256 netSyFee);
}

interface IPendleMarketFactory {
    function isValidMarket(address market) external view returns (bool);
}

interface IPYieldTokenV2 is IERC20Metadata {
    event Mint(
        address indexed caller,
        address indexed receiverPT,
        address indexed receiverYT,
        uint256 amountSyToMint,
        uint256 amountPYOut
    );

    event Burn(address indexed caller, address indexed receiver, uint256 amountPYToRedeem, uint256 amountSyOut);

    event RedeemRewards(address indexed user, uint256[] amountRewardsOut);

    event RedeemInterest(address indexed user, uint256 interestOut);

    event WithdrawFeeToTreasury(uint256[] amountRewardsOut, uint256 syOut);

    event CollectInterestFee(uint256 amountInterestFee);

    event CollectRewardFee(address indexed rewardToken, uint256 amountRewardFee);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256 amountPYOut);

    function redeemPY(address receiver) external returns (uint256 amountSyOut);

    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);

    function redeemPYMulti(
        address[] calldata receivers,
        uint256[] calldata amountPYToRedeems
    ) external returns (uint256[] memory amountSyOuts);

    function redeemDueInterestAndRewards(
        address user,
        bool redeemInterest,
        bool redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function pyIndexCurrent() external returns (uint256);

    function pyIndexStored() external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function SY() external view returns (address);

    function PT() external view returns (address);

    function YT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function doCacheIndexSameBlock() external view returns (bool);
}

interface IPActionMintRedeemStatic {
    function getAmountTokenToMintSy(
        address SY,
        address tokenIn,
        uint256 netSyOut
    ) external view returns (uint256 netTokenIn);

    function mintPyFromSyStatic(address YT, uint256 netSyToMint) external view returns (uint256 netPYOut);

    function mintPyFromTokenStatic(
        address YT,
        address tokenIn,
        uint256 netTokenIn
    ) external view returns (uint256 netPyOut);

    function mintSyFromTokenStatic(
        address SY,
        address tokenIn,
        uint256 netTokenIn
    ) external view returns (uint256 netSyOut);

    function redeemPyToSyStatic(address YT, uint256 netPYToRedeem) external view returns (uint256 netSyOut);

    function redeemPyToTokenStatic(
        address YT,
        uint256 netPYToRedeem,
        address tokenOut
    ) external view returns (uint256 netTokenOut);

    function redeemSyToTokenStatic(
        address SY,
        address tokenOut,
        uint256 netSyIn
    ) external view returns (uint256 netTokenOut);

    function pyIndexCurrentViewMarket(address market) external view returns (uint256);

    function pyIndexCurrentViewYt(address yt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloStrategy {
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        address collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        address collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        address debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    function assetStorage(address _asset) external view returns (AssetStorage memory);

    function deposit(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 collateralAmount, uint256 collateralShare);

    function withdraw(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    function borrow(address _asset, uint256 _amount) external returns (uint256 debtAmount, uint256 debtShare);

    function repay(address _asset, uint256 _amount) external returns (uint256 repaidAmount, uint256 burnedShare);

    function accrueInterest(address _asset) external;

    function getAssetsWithState() external view returns (address[] memory assets, AssetStorage[] memory assetsStorage);
}

interface ISiloLens {
    function depositAPY(ISiloStrategy _silo, address _asset) external view returns (uint256);

    function totalDepositsWithInterest(address _silo, address _asset) external view returns (uint256 _totalDeposits);

    function totalBorrowAmountWithInterest(
        address _silo,
        address _asset
    ) external view returns (uint256 _totalBorrowAmount);

    function collateralBalanceOfUnderlying(
        address _silo,
        address _asset,
        address _user
    ) external view returns (uint256);

    function debtBalanceOfUnderlying(address _silo, address _asset, address _user) external view returns (uint256);

    function balanceOfUnderlying(
        uint256 _assetTotalDeposits,
        address _shareToken,
        address _user
    ) external view returns (uint256);

    function calculateCollateralValue(address _silo, address _user, address _asset) external view returns (uint256);

    function calculateBorrowValue(
        address _silo,
        address _user,
        address _asset,
        uint256,
        uint256
    ) external view returns (uint256);

    function totalBorrowAmount(address _silo, address _asset) external view returns (uint256);
}

interface ISiloIncentiveController {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

    function getUserUnclaimedRewards(address user) external view returns (uint256);

    function REWARD_TOKEN() external view returns (address);
}

interface ISiloRepository {
    function isSiloPaused(address _silo, address _asset) external view returns (bool);

    function getSilo(address _asset) external view returns (address);
}

interface ISiloToken {
    function silo() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { ISiloStrategy, ISiloIncentiveController, ISiloRepository, ISiloLens } from '../interfaces/ISiloStrategy.sol';
import { IFlashLoans } from '../interfaces/balancer/IFlashLoans.sol';
import { IPendleRouterV3 } from '../interfaces/IPendle.sol';
import { ICamelotRouter } from 'contracts/interfaces/camelot/ICamelotRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { TransferHelper } from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

error INVALID_TOKEN();
error NOT_SELF();

library SiloReward {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // Silo
    address public constant provider = 0x8658047e48CC09161f4152c79155Dac1d710Ff0a; //Silo Repository
    address public constant siloLens = 0xBDb843c7a7e48Dc543424474d7Aa63b61B5D9536; // New Silo Lens
    address public constant siloIncentive = 0x7e5BFBb25b33f335e34fa0d78b878092931F8D20; // New Silo Incenctive
    address public constant siloIncentiveSTIP = 0xd592F705bDC8C1B439Bd4D665Ed99C4FaAd5A680; // Silo STIP ARB

    address public constant siloToken = 0x0341C0C0ec423328621788d4854119B97f44E391; // Silo Token
    address public constant arb = 0x912CE59144191C1204E64559FE8253a0e49E6548; // Arb Token

    //Pendle
    address public constant ptweETH = 0x9bEcd6b4Fb076348A455518aea23d3799361FE95; // // PT WETH 25 April 2024
    address public constant pendleRouterV3 = 0x00000000005BBB0EF59571E58418F9a4357b68A0;
    address public constant pendleMarket = 0xE11f9786B06438456b044B3E21712228ADcAA0D1;
    address public constant weETH = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe; // Wrapped Ether.Fi

    // Camelot
    address public constant camelotRouter = 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18;

    // WETH
    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @notice Calculates the balance of an asset held in a pool.
    /// @param poolAddress The address of the Silo pool.
    /// @param assetPool The address of the asset pool contract.
    /// @param asset The address of the asset token.
    /// @return The underlying balance of the asset in the pool for this contract.
    function assetBalance(address poolAddress, address assetPool, address asset) public view returns (uint256) {
        return
            ISiloLens(siloLens).balanceOfUnderlying(
                ISiloLens(siloLens).totalDepositsWithInterest(poolAddress, asset),
                assetPool,
                address(this)
            );
    }

    /// @notice Calculates the debt balance of a token held in a pool.
    /// @param poolAddress The address of the Silo pool.
    /// @param debtPool The address of the debt pool contract.
    /// @param debtToken The address of the debt token.
    /// @return The underlying debt balance of the token in the pool for this contract.
    function debtBalance(address poolAddress, address debtPool, address debtToken) public view returns (uint256) {
        return
            ISiloLens(siloLens).balanceOfUnderlying(
                ISiloLens(siloLens).totalBorrowAmountWithInterest(poolAddress, debtToken),
                debtPool,
                address(this)
            );
    }

    /// @notice Retrieves all asset tokens associated with a pool, including both collateral and debt tokens.
    /// @param poolAddress The address of the Silo pool.
    /// @return allTokens An array of addresses, where the first half contains collateral tokens and the second half contains debt tokens.
    function getAssetTokens(address poolAddress) public view returns (address[] memory allTokens) {
        (, ISiloStrategy.AssetStorage[] memory assetsStorage) = ISiloStrategy(poolAddress).getAssetsWithState();

        // Each asset has both a collateral and a debt token, so we double the length
        allTokens = new address[](assetsStorage.length * 2);

        for (uint i = 0; i < assetsStorage.length; i++) {
            // Store collateral tokens in the first half of the array
            allTokens[i] = assetsStorage[i].collateralToken;
            // Store debt tokens in the second half of the array
            allTokens[assetsStorage.length + i] = assetsStorage[i].debtToken;
        }

        return allTokens;
    }

    /// @notice Claims specified reward tokens from the given incentive contract and charges a fee.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the primary reward to be claimed.
    /// @param assetsToken The array of token addresses to claim rewards for.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount (typically 1e18 for percentages).
    /// @param recipient The address receiving the fee.
    /// @return The net amount of primary reward tokens claimed after deducting the fee.
    function claimReward(
        address incentiveContractAddress,
        address rewardToken,
        address[] memory assetsToken,
        uint256 fee,
        uint256 feeScale,
        address recipient
    ) public returns (uint256) {
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assetsToken, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        IERC20(rewardToken).safeTransfer(msg.sender, balance - feeCharge);

        return balance - feeCharge;
    }

    /// @notice Claims rewards, swaps them to a specified asset, and then supplies the asset to a pool.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the primary reward to be claimed.
    /// @param assetsToken The array of token addresses to claim rewards for.
    /// @param asset The asset token to swap the rewards into and supply to the pool.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount (typically 1e18 for percentages).
    /// @param recipient The address receiving the fee.
    /// @param amountOutMin The minimum amount expected from the swap operation.
    /// @param poolAddress The address of the pool where the asset will be supplied.
    /// @return The net amount of primary reward tokens claimed after the swap and fee deduction.
    function claimRewardsSupply(
        address incentiveContractAddress,
        address rewardToken,
        address[] memory assetsToken,
        address asset,
        uint256 fee,
        uint256 feeScale,
        address recipient,
        uint256 amountOutMin,
        address poolAddress
    ) public returns (uint256) {
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assetsToken, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        uint256 netBalance = balance - feeCharge;

        if (netBalance > 0) {
            if (asset == weETH) {
                IERC20(rewardToken).approve(camelotRouter, netBalance);
                netBalance = swapCamelot(rewardToken, weth, netBalance, amountOutMin);
                swapUniswap(weth, asset, netBalance, amountOutMin);
            } else {
                IERC20(rewardToken).approve(camelotRouter, netBalance);
                swapCamelot(rewardToken, asset, netBalance, amountOutMin);
            }

            IERC20(asset).approve(poolAddress, IERC20(asset).balanceOf(address(this)));
            ISiloStrategy(poolAddress).deposit(asset, IERC20(asset).balanceOf(address(this)), false);
        }
        return netBalance;
    }

    /// @notice Claims rewards, swaps them to a specified debt token, and then uses them to repay debt.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the primary reward to be claimed.
    /// @param assetsToken The array of token addresses to claim rewards for.
    /// @param debtToken The debt token to swap the rewards into for repayment.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount (typically 1e18 for percentages).
    /// @param recipient The address receiving the fee.
    /// @param amountOutMin The minimum amount expected from the swap operation.
    /// @param poolAddress The address of the pool where the debt will be repaid.
    /// @return The net amount of primary reward tokens claimed after the swap and fee deduction.
    function claimRewardsRepay(
        address incentiveContractAddress,
        address rewardToken,
        address[] memory assetsToken,
        address debtToken,
        uint256 fee,
        uint256 feeScale,
        address recipient,
        uint256 amountOutMin,
        address poolAddress
    ) public returns (uint256) {
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assetsToken, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        uint256 netBalance = balance - feeCharge;

        if (netBalance > 0) {
            // Swap to debtToken
            IERC20(rewardToken).approve(camelotRouter, netBalance);
            swapCamelot(rewardToken, debtToken, netBalance, amountOutMin);

            // Repay
            uint256 amount = IERC20(debtToken).balanceOf(address(this));
            IERC20(debtToken).approve(poolAddress, amount);
            ISiloStrategy(poolAddress).repay(debtToken, amount);
        }
        return netBalance;
    }

    /// @notice Calculates and transfers a fee based on the specified parameters.
    /// @dev This function is internal and used to handle fee deductions for various reward claiming operations.
    /// @param amount The total amount from which the fee is to be calculated.
    /// @param token The address of the token on which the fee is being charged.
    /// @param fee The fee percentage to be charged.
    /// @param feeScale The scale used for fee calculation, typically a value like 10000 for percentages.
    /// @param recipient The address that will receive the fee.
    /// @return depositFeeAmount The calculated fee amount that has been transferred to the recipient.
    function rewardFeeCharge(
        uint256 amount,
        address token,
        uint256 fee,
        uint256 feeScale,
        address recipient
    ) internal returns (uint256) {
        uint256 depositFeeAmount = amount.mulDiv(fee, feeScale);
        IERC20(token).safeTransfer(recipient, depositFeeAmount);
        return depositFeeAmount;
    }

    /**
     * @notice Executes a swap on Camelot, converting the input token to the desired output token.
     * @dev This function approves the Camelot router to transfer the input token, then performs the swap, and returns the amount received.
     * @param tokenIn The address of the input token to swap.
     * @param tokenOut The address of the desired output token.
     * @param amount The amount of input token to swap.
     * @param amountOutMinimum The minimum amount of output token expected to receive.
     * @return The amount of output token received after the swap.
     */
    function swapCamelot(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 amountOutMinimum
    ) public returns (uint256) {
        TransferHelper.safeApprove(tokenIn, address(camelotRouter), amount);

        ICamelotRouter.ExactInputSingleParams memory params = ICamelotRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: amountOutMinimum,
            limitSqrtPrice: 0
        });

        return ICamelotRouter(camelotRouter).exactInputSingle(params);
    }

    /**
     * @notice Executes a swap on Uniswap, converting the input token to the desired output token.
     * @param tokenIn The address of the input token to swap.
     * @param tokenOut The address of the desired output token.
     * @param amount The amount of input token to swap.
     * @param amountOutMinimum The minimum amount of output token expected to receive.
     * @return The amount of output token received after the swap.
     */
    function swapUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 amountOutMinimum
    ) public returns (uint256) {
        TransferHelper.safeApprove(tokenIn, uniswapV3Router, type(uint256).max);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: 100, // Fee tier, change if needed
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = ISwapRouter(uniswapV3Router).exactInputSingle(params);

        TransferHelper.safeApprove(tokenIn, uniswapV3Router, 0);

        return amountOut;
    }

    // =============================================================
    //                 Helpers
    // =============================================================

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        uint256 result = numerator / totalShares;

        // Round up
        if (numerator % totalShares != 0) {
            result += 1;
        }

        return result;
    }

    // =============================================================
    //                  Supply, Borrow, Repay, Withdraw
    // =============================================================

    function supply(address asset, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // supply
        IERC20(asset).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).deposit(asset, amount, false);

        return amount;
    }

    function borrow(address debtToken, uint256 amount, address poolAddress) public returns (uint256) {
        ISiloStrategy(poolAddress).borrow(debtToken, amount);
        IERC20(debtToken).safeTransfer(msg.sender, amount);
        return amount;
    }

    function repay(address debtToken, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(debtToken).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(debtToken).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).repay(debtToken, amount);

        return amount;
    }

    function withdraw(address asset, address assetPool, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(assetPool).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).withdraw(asset, amount, false);
        IERC20(asset).safeTransfer(msg.sender, amount);

        return amount;
    }

    function _swapPendle(bool isDeposit, uint256 amount) internal returns (uint256 netAmountOut) {
        IPendleRouterV3.SwapData memory swapData = IPendleRouterV3.SwapData({
            swapType: IPendleRouterV3.SwapType.NONE,
            extRouter: address(0),
            extCalldata: '0x',
            needScale: false
        });

        IPendleRouterV3.LimitOrderData memory limitOrder = _createLimitOrderData();

        if (isDeposit) {
            IPendleRouterV3.TokenInput memory tokenInput = IPendleRouterV3.TokenInput({
                tokenIn: address(weETH),
                netTokenIn: amount,
                tokenMintSy: address(weETH),
                pendleSwap: address(0),
                swapData: swapData
            });

            IPendleRouterV3.ApproxParams memory approx = _createApproxParams();

            (uint256 netPtOut, , ) = IPendleRouterV3(pendleRouterV3).swapExactTokenForPt(
                address(this),
                pendleMarket,
                0,
                approx,
                tokenInput,
                limitOrder
            );
            netAmountOut = netPtOut;
        } else {
            IPendleRouterV3.TokenOutput memory tokenOutput = IPendleRouterV3.TokenOutput({
                tokenOut: address(weETH),
                minTokenOut: 0,
                tokenRedeemSy: address(weETH),
                pendleSwap: address(0),
                swapData: swapData
            });

            (uint256 netTokenOut, , ) = IPendleRouterV3(pendleRouterV3).swapExactPtForToken(
                address(this),
                pendleMarket,
                amount,
                tokenOutput,
                limitOrder
            );
            netAmountOut = netTokenOut;
        }

        return (netAmountOut);
    }

    function _createLimitOrderData() internal pure returns (IPendleRouterV3.LimitOrderData memory) {
        return
            IPendleRouterV3.LimitOrderData({
                limitRouter: address(0),
                epsSkipMarket: 0,
                normalFills: new IPendleRouterV3.FillOrderParams[](0),
                flashFills: new IPendleRouterV3.FillOrderParams[](0),
                optData: '0x'
            });
    }

    function _createApproxParams() internal pure returns (IPendleRouterV3.ApproxParams memory) {
        return
            IPendleRouterV3.ApproxParams({
                guessMin: 0,
                guessMax: type(uint256).max,
                guessOffchain: 0,
                maxIteration: 256,
                eps: 1e15
            });
    }

    function withdrawTokenInCaseStuck(
        address tokenAddress,
        uint256 amount,
        address assetPool,
        address debtPool
    ) public returns (address, uint256) {
        if (tokenAddress == assetPool || tokenAddress == debtPool) revert INVALID_TOKEN();
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        return (tokenAddress, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IOpenOceanExchange, IOpenOceanCaller } from '../../interfaces/IOpenOceanExchange.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library OpenOceanAggregator {
    // =============================================================
    //                         Errors
    // =============================================================

    error WRONG_TOKEN_IN(); // 0xf6b8648c
    error WRONG_TOKEN_OUT(); // 0x5e8f1f5b
    error WRONG_AMOUNT(); // 0xc6ea1a16
    error WRONG_DST(); // 0xcb0b65a6
    error SWAP_ERROR(); // 0xcbe60bba
    error SWAP_METHOD_NOT_IDENTIFIED(); // 0xc257a710

    // =============================================================
    //                        Constants
    // =============================================================

    address constant router = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;

    // =============================================================
    //                        Functions
    // =============================================================

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bytes calldata data
    ) public returns (uint256 outAmount) {
        IERC20(tokenIn).approve(address(router), amount);

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        bytes4 method = _getMethod(data);

        // swap
        if (
            method ==
            bytes4(
                keccak256(
                    'swap(address,(address,address,address,address,uint256,uint256,uint256,uint256,address,bytes),(uint256,uint256,uint256,bytes)[])'
                )
            )
        ) {
            (, IOpenOceanExchange.SwapDescription memory desc, ) = abi.decode(
                data[4:],
                (IOpenOceanCaller, IOpenOceanExchange.SwapDescription, IOpenOceanCaller.CallDescription[])
            );

            if (tokenIn != address(desc.srcToken)) revert WRONG_TOKEN_IN();
            if (tokenOut != address(desc.dstToken)) revert WRONG_TOKEN_OUT();
            if (amount != desc.amount) revert WRONG_AMOUNT();
            if (address(this) != desc.dstReceiver) revert WRONG_DST();

            _callOpenOcean(data);
        }
        // uniswapV3SwapTo
        else if (method == bytes4(keccak256('uniswapV3SwapTo(address,uint256,uint256,uint256[])'))) {
            (address recipient, uint256 swapAmount, , ) = abi.decode(data[4:], (address, uint256, uint256, uint256[]));
            if (address(this) != recipient) revert WRONG_DST();
            if (amount != swapAmount) revert WRONG_AMOUNT();

            _callOpenOcean(data);
        }
        // callUniswapTo
        else if (method == bytes4(keccak256('callUniswapTo(address,uint256,uint256,bytes32[],address)'))) {
            (address srcToken, uint256 swapAmount, , , address recipient) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[], address)
            );
            if (tokenIn != srcToken) revert WRONG_TOKEN_IN();
            if (amount != swapAmount) revert WRONG_AMOUNT();
            if (address(this) != recipient) revert WRONG_DST();

            _callOpenOcean(data);
        } else {
            revert SWAP_METHOD_NOT_IDENTIFIED();
        }

        return IERC20(tokenOut).balanceOf(address(this)) - balanceBefore;
    }

    function _getMethod(bytes memory data) internal pure returns (bytes4 method) {
        assembly {
            method := mload(add(data, add(32, 0)))
        }
    }

    function _callOpenOcean(bytes memory data) internal {
        (bool success, bytes memory result) = address(router).call(data);
        if (!success) {
            if (result.length < 68) revert SWAP_ERROR();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// inheritances
import { ILeverageStrategy } from '../../interfaces/ILeverageStrategy.sol';
import { IFlashLoanRecipient } from '../../interfaces/balancer/IFlashLoanRecipient.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { UUPSUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

// libraries
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { OpenOceanAggregator } from '../../libraries/swap/OpenOceanAggregator.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { TransferHelper } from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import { SiloReward } from '../../libraries/SiloReward.sol';

// interfaces
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Extended } from '../../interfaces/IERC20Extended.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IFlashLoans } from '../../interfaces/balancer/IFlashLoans.sol';
import { ISiloStrategy, ISiloLens, ISiloIncentiveController, ISiloToken, ISiloRepository } from '../../interfaces/ISiloStrategy.sol';
import { IFactorLeverageVault } from '../../interfaces/IFactorLeverageVault.sol';
import { IPYieldTokenV2 } from '../../interfaces/IPendle.sol';

contract SiloYieldTokenStrategy is
    Initializable,
    ILeverageStrategy,
    IFlashLoanRecipient,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // =============================================================
    //                         Libraries
    // =============================================================

    using SafeERC20 for IERC20;
    using Math for uint256;

    // =============================================================
    //                         Events
    // =============================================================

    event LeverageAdded(uint256 amount, uint256 debt);
    event LeverageRemoved(uint256 debt);
    event LeverageClosed(uint256 amount, uint256 debt, uint256 lrtAmount);
    event Withdraw(uint256 amount);
    event Repay(uint256 amount);
    event Supply(uint256 amount);
    event Borrow(uint256 amount);
    event WithdrawTokenInCaseStuck(address tokenAddress, uint256 amount);
    event RewardClaimed(uint256 amount, address token);
    event RewardClaimedSupply(uint256 amount, address token);
    event RewardClaimedRepay(uint256 amount, address token);
    event LeverageChargeFee(uint256 amount);

    // =============================================================
    //                         Errors
    // =============================================================

    error NOT_OWNER();
    error NOT_BALANCER();
    error NOT_SELF();
    error INVALID_ASSET();
    error INVALID_DEBT();
    error INVALID_TOKEN();
    error AMOUNT_TOO_MUCH();
    error SAME_AS_DEBTTOKEN();

    // =============================================================
    //                         Constants
    // =============================================================
    // Silo
    address public constant provider = 0x8658047e48CC09161f4152c79155Dac1d710Ff0a; //Silo Repository
    address public constant siloLens = 0xBDb843c7a7e48Dc543424474d7Aa63b61B5D9536; // New Silo Lens

    //Pendle
    address public constant ptweETH = 0x9bEcd6b4Fb076348A455518aea23d3799361FE95; // // PT WETH 25 April 2024
    address public constant pendleRouterV3 = 0x00000000005BBB0EF59571E58418F9a4357b68A0;
    address public constant weETH = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe; // Wrapped Ether.Fi

    // balancer
    address public constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address public constant uniswapV3Pool = 0xA169d1aB5c948555954D38700a6cDAA7A4E0c3A0;

    // =============================================================
    //                         Storages
    // =============================================================

    uint256 private _positionId;

    IERC721 private _vaultManager;

    IERC20 private _asset;

    IERC20 private _debtToken;

    IERC20 public _assetPool;

    IERC20 public _debtPool;

    uint8 private flMode; // 1 = addLeverage, 2 = removeLeverage, 5 = close leverage

    // =============================================================
    //                      Functions
    // =============================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 __positionId,
        address _vaultManagerAddress,
        address _assetAddress,
        address _debtAddress,
        address _assetPoolAddress,
        address _debtPoolAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _positionId = __positionId;
        _vaultManager = IERC721(_vaultManagerAddress);
        _asset = IERC20(_assetAddress);
        _debtToken = IERC20(_debtAddress);
        _assetPool = IERC20(_assetPoolAddress);
        _debtPool = IERC20(_debtPoolAddress);
    }

    function vaultManager() public view returns (address) {
        return address(_vaultManager);
    }

    function positionId() public view returns (uint256) {
        return _positionId;
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function getAssetTokens() public view returns (address[] memory allTokens) {
        return SiloReward.getAssetTokens(getPoolAddress());
    }

    function debtToken() public view returns (address) {
        return address(_debtToken);
    }

    function assetPool() public view returns (address) {
        return address(_assetPool);
    }

    function debtPool() public view returns (address) {
        return address(_debtPool);
    }

    function assetBalance() public view returns (uint256) {
        return SiloReward.assetBalance(getPoolAddress(), assetPool(), asset());
    }

    function debtBalance() public view returns (uint256) {
        return SiloReward.debtBalance(getPoolAddress(), debtPool(), debtToken());
    }

    function owner() public view returns (address) {
        return _vaultManager.ownerOf(_positionId);
    }

    function addLeverage(uint256 amount, uint256 debt, bytes calldata data) external onlyOwner {
        // process = flashloan the expected debt -> swap the expected debt to asset -> supply the asset -> borrow to repay the flashloan
        address poolAddress = ISiloToken(assetPool()).silo();

        if (amount > 0) {
            IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

            // supply
            TransferHelper.safeApprove(asset(), poolAddress, amount);
            ISiloStrategy(poolAddress).deposit(asset(), amount, false);
        }

        if (debt > 0) {
            // execute flashloan
            bytes memory params = abi.encode(debt, poolAddress, data);
            address[] memory tokens = new address[](1);
            tokens[0] = debtToken();
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = debt;
            flMode = 1;
            IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
            flMode = 0;
        }

        emit LeverageAdded(amount, debt);
    }

    function _flAddLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, address poolAddress, bytes memory data) = abi.decode(params, (uint256, address, bytes));
        uint256 outAmount;

        // Swap debt to weETH and get the swapped amount
        outAmount = this.swapBySelf(debtToken(), weETH, amount, data);
        // deposit and get ptweETH
        TransferHelper.safeApprove(weETH, pendleRouterV3, outAmount);
        outAmount = SiloReward._swapPendle(true, outAmount);
        TransferHelper.safeApprove(weETH, pendleRouterV3, 0);

        // Supply the asset to the Silo Vault
        TransferHelper.safeApprove(asset(), poolAddress, outAmount);
        ISiloStrategy(poolAddress).deposit(asset(), outAmount, false);
        TransferHelper.safeApprove(asset(), poolAddress, 0);

        // Borrow the original amount plus the fee amount
        ISiloStrategy(poolAddress).borrow(debtToken(), amount + feeAmount);

        // Repay the flash loan
        IERC20(debtToken()).safeTransfer(balancerVault, amount + feeAmount);
    }

    function removeLeverage(uint256 amount, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> withdraw the asset -> swap the asset -> borrow to repay the flashloan

        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(amount, repayAmount, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 2;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;

        // transfer to owner
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        IERC20(asset()).safeTransfer(owner(), balance);

        emit LeverageRemoved(amount);
    }

    function _flRemoveLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, uint256 repayAmount, address poolAddress, bytes memory data) = abi.decode(
            params,
            (uint256, uint256, address, bytes)
        );

        uint256 outAmount;

        // repay
        TransferHelper.safeApprove(debtToken(), poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        // withdraw
        ISiloStrategy(poolAddress).withdraw(asset(), amount, false);

        // withdraw and get weETH
        TransferHelper.safeApprove(ptweETH, pendleRouterV3, amount);
        outAmount = SiloReward._swapPendle(false, amount);
        TransferHelper.safeApprove(ptweETH, pendleRouterV3, 0);

        // Swap weETH to debtToken and get the swapped amount
        uint256 amountOutMinimum = abi.decode(data, (uint256));
        outAmount = _swapUniswap(weETH, debtToken(), outAmount, amountOutMinimum);

        // you can't swap asset more than debt value
        if (outAmount > repayAmount) revert AMOUNT_TOO_MUCH();

        uint256 remainingFlashLoanAmount = repayAmount - _debtToken.balanceOf(address(this));

        // borrow
        ISiloStrategy(poolAddress).borrow(debtToken(), remainingFlashLoanAmount + feeAmount);

        // repay debt Flashloan
        IERC20(debtToken()).safeTransfer(balancerVault, repayAmount + feeAmount);
    }

    function closeLeverage(uint256 amount, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> withdraw all asset -> swap the asset to repay the flash loan

        // notes: if amount > debt value then the all position become debtToken
        // for example, when wstETH/USDC closes the leverage can be withdrawn as wstETH or USDC
        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(amount, repayAmount, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 5;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;

        uint256 closedAsset = IERC20(asset()).balanceOf(address(this));
        uint256 closedDebt = IERC20(debtToken()).balanceOf(address(this));
        uint256 lrtAmount = IERC20(weETH).balanceOf(address(this));

        // transfer asset & debt token to owner
        IERC20(asset()).safeTransfer(owner(), closedAsset);
        IERC20(debtToken()).safeTransfer(owner(), closedDebt);
        IERC20(weETH).safeTransfer(owner(), lrtAmount);

        emit LeverageClosed(closedAsset, closedDebt, lrtAmount);
    }

    function _flCloseLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, uint256 repayAmount, address poolAddress, bytes memory data) = abi.decode(
            params,
            (uint256, uint256, address, bytes)
        );

        uint256 outAmount;
        uint256 netSyOut;
        uint256 amountTokenOut;

        // repay
        TransferHelper.safeApprove(debtToken(), poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        ISiloStrategy(poolAddress).withdraw(asset(), type(uint256).max, false);

        (uint256 amountOutMinimum, bool closeToAsset) = abi.decode(data, (uint256, bool));

        // Handles the case when the PT token is expired.
        if (isExpired()) {
            IERC20(ptweETH).transfer(YT(), IERC20(ptweETH).balanceOf(address(this)));
            netSyOut = IPYieldTokenV2(YT()).redeemPY(SY());
            amountTokenOut = IPYieldTokenV2(SY()).redeem(address(this), netSyOut, weETH, 0, true);

            // When both expired and close to asset, swap certain amount redeemed to debtToken to repay.
            if (closeToAsset) {
                _swapUniswap(weETH, debtToken(), repayAmount + feeAmount, amountOutMinimum);
            } else {
                // If expired but not closing to asset, swapp all to debtToken.
                _swapUniswap(weETH, debtToken(), amountTokenOut, amountOutMinimum);
            }
        } else {
            // Common initial step when not expired.
            TransferHelper.safeApprove(ptweETH, pendleRouterV3, type(uint256).max);
            outAmount = SiloReward._swapPendle(false, IERC20(ptweETH).balanceOf(address(this)));
            TransferHelper.safeApprove(ptweETH, pendleRouterV3, 0);

            if (closeToAsset) {
                // If choosing to close to asset, calculate swap amount and perform swap.
                uint256 swapAmt = (repayAmount + feeAmount);
                _swapUniswap(weETH, debtToken(), swapAmt, amountOutMinimum);
            } else {
                // If not closing to asset, perform swap with the original outAmount.
                _swapUniswap(weETH, debtToken(), outAmount, amountOutMinimum);
            }
        }
        // Repay debt Flashloan (common final step)
        IERC20(debtToken()).safeTransfer(balancerVault, repayAmount + feeAmount);
    }

    function swapBySelf(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bytes calldata data
    ) public returns (uint256) {
        if (msg.sender != address(this)) revert NOT_SELF();
        uint256 outAmount = OpenOceanAggregator.swap(tokenIn, tokenOut, amount, data);
        uint256 feeCharge = leverageFeeCharge(outAmount, tokenOut);
        return outAmount - feeCharge;
    }

    function _swapUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 amountOutMinimum
    ) internal returns (uint256) {
        uint256 amountInput = Math.min(IERC20(tokenIn).balanceOf(address(this)), amount);
        uint256 outAmount = SiloReward.swapUniswap(tokenIn, tokenOut, amountInput, amountOutMinimum);
        uint256 feeCharge = leverageFeeCharge(outAmount, tokenOut);
        return outAmount - feeCharge;
    }

    function leverageFeeCharge(uint256 amount, address token) internal returns (uint256) {
        uint256 leverageFee = IFactorLeverageVault(vaultManager()).leverageFee();
        uint256 feeScale = IFactorLeverageVault(vaultManager()).FEE_SCALE();
        address factorFeeRecipient = IFactorLeverageVault(vaultManager()).feeRecipient();
        uint256 depositFeeAmount = amount.mulDiv(leverageFee, feeScale);

        IERC20(token).safeTransfer(factorFeeRecipient, depositFeeAmount);

        emit LeverageChargeFee(depositFeeAmount);

        return depositFeeAmount;
    }

    function _getRepayAmount(address poolAddress) internal view returns (uint256) {
        uint256 repayShare = _debtPool.balanceOf(address(this));
        uint256 debtTokenTotalSupply = _debtPool.totalSupply();
        uint256 totalBorrowed = ISiloLens(siloLens).totalBorrowAmount(poolAddress, debtToken());

        return toAmountRoundUp(repayShare, totalBorrowed, debtTokenTotalSupply);
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        return SiloReward.toAmountRoundUp(share, totalAmount, totalShares);
    }

    function getPoolAddress() internal view returns (address) {
        return ISiloToken(assetPool()).silo();
    }

    function withdrawTokenInCaseStuck(address tokenAddress, uint256 amount) external onlyOwner {
        SiloReward.withdrawTokenInCaseStuck(tokenAddress, amount, assetPool(), debtPool());

        emit WithdrawTokenInCaseStuck(tokenAddress, amount);
    }

    function supply(uint256 amount) external onlyOwner {
        SiloReward.supply(asset(), amount, getPoolAddress());
        emit Supply(amount);
    }

    function borrow(uint256 amount) external onlyOwner {
        SiloReward.borrow(debtToken(), amount, getPoolAddress());
        emit Borrow(amount);
    }

    function repay(uint256 amount) external onlyOwner {
        SiloReward.repay(debtToken(), amount, getPoolAddress());
        emit Repay(amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        SiloReward.withdraw(asset(), assetPool(), amount, getPoolAddress());
        emit Withdraw(amount);
    }

    /**
     * @notice Claims rewards based on the specified reward type.
     * @param rewardsToken address of reward token.
     * @dev Emits a RewardClaimed event upon successful execution.
     */
    function claimRewards(address rewardsToken) external onlyOwner {
        (uint256 fee, uint256 feeScale, address feeRecipient) = _getVaultDetails();
        address[] memory assetTokens = getAssetTokens();
        address incentiveAddress = _getIncentiveAddress(rewardsToken);

        uint256 transferredAmount = SiloReward.claimReward(
            incentiveAddress,
            rewardsToken,
            assetTokens,
            fee,
            feeScale,
            feeRecipient
        );
        emit RewardClaimed(transferredAmount, rewardsToken);
    }

    /**
     * @notice Claims supply rewards based on the specified reward type and supplies them to a pool.
     * @param rewardsToken address of reward token.
     * @param amountOutMin The minimum amount expected from the swap operation.
     * @dev Emits a RewardClaimedSupply event upon successful execution.
     */
    function claimRewardsSupply(address rewardsToken, uint256 amountOutMin) external onlyOwner {
        (uint256 fee, uint256 feeScale, address feeRecipient, address poolAddress) = _getVaultAndPoolDetails();
        address[] memory assetTokens = getAssetTokens();

        uint256 transferredAmount = _claimRewards(
            rewardsToken,
            assetTokens,
            fee,
            feeScale,
            feeRecipient,
            amountOutMin,
            poolAddress,
            false
        );

        emit RewardClaimedSupply(transferredAmount, rewardsToken);
    }

    /**
     * @notice Claims repay rewards based on the specified reward type and uses them to repay debt.
     * @param rewardsToken address of reward token.
     * @param amountOutMin The minimum amount expected from the swap operation.
     * @dev Emits a RewardClaimedRepay event upon successful execution.
     */
    function claimRewardsRepay(address rewardsToken, uint256 amountOutMin) external onlyOwner {
        (uint256 fee, uint256 feeScale, address feeRecipient, address poolAddress) = _getVaultAndPoolDetails();
        address[] memory assetTokens = getAssetTokens();

        uint256 transferredAmount = _claimRewards(
            rewardsToken,
            assetTokens,
            fee,
            feeScale,
            feeRecipient,
            amountOutMin,
            poolAddress,
            true
        );

        emit RewardClaimedRepay(transferredAmount, rewardsToken);
    }

    /**
     * @dev Internal function to handle the core logic of claiming rewards.
     * @param rewardsToken address of reward token.
     * @param assetTokens The array of asset tokens associated with the pool.
     * @param fee The fee percentage to be charged on the claimed rewards.
     * @param feeScale The scale to calculate the actual fee amount.
     * @param feeRecipient The address receiving the fee.
     * @param amountOutMin The minimum amount expected from the swap operation.
     * @param poolAddress The address of the pool where the asset will be supplied or debt repaid.
     * @param isRepay A boolean flag to determine if the function should handle repay logic.
     * @return The net amount of reward tokens claimed after all deductions.
     */
    function _claimRewards(
        address rewardsToken,
        address[] memory assetTokens,
        uint256 fee,
        uint256 feeScale,
        address feeRecipient,
        uint256 amountOutMin,
        address poolAddress,
        bool isRepay
    ) internal returns (uint256) {
        address incentiveAddress = _getIncentiveAddress(rewardsToken);
        uint256 transferredAmount;

        if (isRepay) {
            transferredAmount = SiloReward.claimRewardsRepay(
                incentiveAddress,
                rewardsToken,
                assetTokens,
                debtToken(),
                fee,
                feeScale,
                feeRecipient,
                amountOutMin,
                poolAddress
            );
        } else {
            transferredAmount = SiloReward.claimRewardsSupply(
                incentiveAddress,
                rewardsToken,
                assetTokens,
                asset(),
                fee,
                feeScale,
                feeRecipient,
                amountOutMin,
                poolAddress
            );
        }

        return transferredAmount;
    }

    /**
     * @dev Retrieves the incentive address based on the reward type.
     * @param rewardsToken address of reward token.
     * @return The address of the incentive contract.
     */
    function _getIncentiveAddress(address rewardsToken) internal pure returns (address) {
        if (rewardsToken == SiloReward.siloToken) {
            return SiloReward.siloIncentive;
        } else if (rewardsToken == SiloReward.arb) {
            return SiloReward.siloIncentiveSTIP;
        }
        revert('Wrong Rewards Token Address');
    }

    function _getVaultDetails() internal view returns (uint256 fee, uint256 feeScale, address factorFeeRecipient) {
        IFactorLeverageVault vault = IFactorLeverageVault(vaultManager());
        fee = vault.claimRewardFee();
        feeScale = vault.FEE_SCALE();
        factorFeeRecipient = vault.feeRecipient();
    }

    function _getVaultAndPoolDetails()
        internal
        view
        returns (uint256 fee, uint256 feeScale, address factorFeeRecipient, address poolAddress)
    {
        (fee, feeScale, factorFeeRecipient) = _getVaultDetails();
        poolAddress = ISiloToken(assetPool()).silo();
    }

    function expiry() public view returns (uint256) {
        return IPYieldTokenV2(ptweETH).expiry();
    }

    function isExpired() public view returns (bool) {
        return IPYieldTokenV2(ptweETH).isExpired();
    }

    function SY() public view returns (address) {
        return IPYieldTokenV2(ptweETH).SY();
    }

    function YT() public view returns (address) {
        return IPYieldTokenV2(ptweETH).YT();
    }

    function version() external pure returns (string memory) {
        return '0.2';
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes calldata params
    ) external override nonReentrant {
        if (msg.sender != balancerVault) revert NOT_BALANCER();
        uint256 feeAmount = 0;
        if (feeAmounts.length > 0) {
            feeAmount = feeAmounts[0];
        }
        if (flMode == 1) _flAddLeverage(params, feeAmount);
        if (flMode == 2) _flRemoveLeverage(params, feeAmount);
        if (flMode == 5) _flCloseLeverage(params, feeAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        // check if the new implementation is registered
        if (IFactorLeverageVault(vaultManager()).isRegisteredUpgrade(_getImplementation(), newImplementation) == false)
            revert('INVALID_UPGRADE');
    }

    // =============================================================
    //                      modifiers
    // =============================================================

    modifier onlyOwner() {
        if (msg.sender != _vaultManager.ownerOf(_positionId)) revert NOT_OWNER();
        _;
    }
}