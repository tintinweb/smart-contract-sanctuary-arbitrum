// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";
import "./PythErrors.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);

    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
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
    /// otherwise, please consider using `updatePriceFeeds`. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
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

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./AbstractPyth.sol";
import "./PythStructs.sol";
import "./PythErrors.sol";

contract MockPyth is AbstractPyth {
    mapping(bytes32 => PythStructs.PriceFeed) priceFeeds;

    uint singleUpdateFeeInWei;
    uint validTimePeriod;

    constructor(uint _validTimePeriod, uint _singleUpdateFeeInWei) {
        singleUpdateFeeInWei = _singleUpdateFeeInWei;
        validTimePeriod = _validTimePeriod;
    }

    function queryPriceFeed(
        bytes32 id
    ) public view override returns (PythStructs.PriceFeed memory priceFeed) {
        if (priceFeeds[id].id == 0) revert PythErrors.PriceFeedNotFound();
        return priceFeeds[id];
    }

    function priceFeedExists(bytes32 id) public view override returns (bool) {
        return (priceFeeds[id].id != 0);
    }

    function getValidTimePeriod() public view override returns (uint) {
        return validTimePeriod;
    }

    // Takes an array of encoded price feeds and stores them.
    // You can create this data either by calling createPriceFeedUpdateData or
    // by using web3.js or ethers abi utilities.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable override {
        uint requiredFee = getUpdateFee(updateData);
        if (msg.value < requiredFee) revert PythErrors.InsufficientFee();

        for (uint i = 0; i < updateData.length; i++) {
            PythStructs.PriceFeed memory priceFeed = abi.decode(
                updateData[i],
                (PythStructs.PriceFeed)
            );

            uint lastPublishTime = priceFeeds[priceFeed.id].price.publishTime;

            if (lastPublishTime < priceFeed.price.publishTime) {
                // Price information is more recent than the existing price information.
                priceFeeds[priceFeed.id] = priceFeed;
                emit PriceFeedUpdate(
                    priceFeed.id,
                    uint64(priceFeed.price.publishTime),
                    priceFeed.price.price,
                    priceFeed.price.conf
                );
            }
        }
    }

    function getUpdateFee(
        bytes[] calldata updateData
    ) public view override returns (uint feeAmount) {
        return singleUpdateFeeInWei * updateData.length;
    }

    function parsePriceFeedUpdatesInternal(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime,
        bool unique
    ) internal returns (PythStructs.PriceFeed[] memory feeds) {
        uint requiredFee = getUpdateFee(updateData);
        if (msg.value < requiredFee) revert PythErrors.InsufficientFee();

        feeds = new PythStructs.PriceFeed[](priceIds.length);

        for (uint i = 0; i < priceIds.length; i++) {
            for (uint j = 0; j < updateData.length; j++) {
                uint64 prevPublishTime;
                (feeds[i], prevPublishTime) = abi.decode(
                    updateData[j],
                    (PythStructs.PriceFeed, uint64)
                );

                uint publishTime = feeds[i].price.publishTime;
                if (priceFeeds[feeds[i].id].price.publishTime < publishTime) {
                    priceFeeds[feeds[i].id] = feeds[i];
                    emit PriceFeedUpdate(
                        feeds[i].id,
                        uint64(publishTime),
                        feeds[i].price.price,
                        feeds[i].price.conf
                    );
                }

                if (feeds[i].id == priceIds[i]) {
                    if (
                        minPublishTime <= publishTime &&
                        publishTime <= maxPublishTime &&
                        (!unique || prevPublishTime < minPublishTime)
                    ) {
                        break;
                    } else {
                        feeds[i].id = 0;
                    }
                }
            }

            if (feeds[i].id != priceIds[i])
                revert PythErrors.PriceFeedNotFoundWithinRange();
        }
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable override returns (PythStructs.PriceFeed[] memory feeds) {
        return
            parsePriceFeedUpdatesInternal(
                updateData,
                priceIds,
                minPublishTime,
                maxPublishTime,
                false
            );
    }

    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable override returns (PythStructs.PriceFeed[] memory feeds) {
        return
            parsePriceFeedUpdatesInternal(
                updateData,
                priceIds,
                minPublishTime,
                maxPublishTime,
                true
            );
    }

    function createPriceFeedUpdateData(
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo,
        int64 emaPrice,
        uint64 emaConf,
        uint64 publishTime,
        uint64 prevPublishTime
    ) public pure returns (bytes memory priceFeedData) {
        PythStructs.PriceFeed memory priceFeed;

        priceFeed.id = id;

        priceFeed.price.price = price;
        priceFeed.price.conf = conf;
        priceFeed.price.expo = expo;
        priceFeed.price.publishTime = publishTime;

        priceFeed.emaPrice.price = emaPrice;
        priceFeed.emaPrice.conf = emaConf;
        priceFeed.emaPrice.expo = expo;
        priceFeed.emaPrice.publishTime = publishTime;

        priceFeedData = abi.encode(priceFeed, prevPublishTime);
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    // Signature: 0xa9cb9e0d
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    // Signature: 0xe60dce71
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    // Signature: 0xe69ffece
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    // Signature: 0x025dbdd4
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    // Signature: 0xde2c57fa
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    // Signature: 0x45805f5d
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    // Signature: 0x14aebe68
    error PriceFeedNotFound();
    // Requested price is stale.
    // Signature: 0x19abf40e
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    // Signature: 0x2acbe915
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    // Signature: 0x97363b35
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    // Signature: 0x63daeb77
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    // Signature: 0x360f2d87
    error InvalidGovernanceDataSource();
    // Governance message is old.
    // Signature: 0x88d1b847
    error OldGovernanceMessage();
    // The wormhole address to set in SetWormholeAddress governance is invalid.
    // Signature: 0x13d3ed82
    error InvalidWormholeAddressToSet();
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
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressesProvider.sol";
import "./libraries/Errors.sol";

contract AddressesProvider is Ownable, Initializable, IAddressesProvider {
    bytes32 private constant TIMELOCK = "TIMELOCK";
    bytes32 private constant ROLE_MANAGER = "ROLE_MANAGER";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant INDEX_PRICE_ORACLE = "INDEX_PRICE_ORACLE";
    bytes32 private constant FUNDING_RATE = "FUNDING_RATE";
    bytes32 private constant EXECUTION_LOGIC = "EXECUTION_LOGIC";
    bytes32 private constant LIQUIDATION_LOGIC = "LIQUIDATION_LOGIC";
    bytes32 private constant BACKTRACKER = "BACKTRACKER";

    address public immutable override WETH;

    mapping(bytes32 => address) private _addresses;

    constructor(address _weth, address _timelock) {
        WETH = _weth;
        setAddress(TIMELOCK, _timelock);
    }

    modifier onlyTimelock() {
        require(msg.sender == _addresses[TIMELOCK], "only timelock");
        _;
    }

    function initialize(
        address _priceOracle,
        address _indexPriceOracle,
        address _fundingRate,
        address _executionLogic,
        address _liquidationLogic,
        address _backtracker
    ) external onlyOwner initializer {
        setAddress(PRICE_ORACLE, _priceOracle);
        setAddress(INDEX_PRICE_ORACLE, _indexPriceOracle);
        setAddress(FUNDING_RATE, _fundingRate);
        setAddress(EXECUTION_LOGIC, _executionLogic);
        setAddress(LIQUIDATION_LOGIC, _liquidationLogic);
        setAddress(BACKTRACKER, _backtracker);
    }

    function getAddress(bytes32 id) public view returns (address) {
        return _addresses[id];
    }

    function timelock() external view override returns (address) {
        return getAddress(TIMELOCK);
    }

    function roleManager() external view override returns (address) {
        return getAddress(ROLE_MANAGER);
    }

    function priceOracle() external view override returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function indexPriceOracle() external view override returns (address) {
        return getAddress(INDEX_PRICE_ORACLE);
    }

    function fundingRate() external view override returns (address) {
        return getAddress(FUNDING_RATE);
    }

    function executionLogic() external view override returns (address) {
        return getAddress(EXECUTION_LOGIC);
    }

    function liquidationLogic() external view override returns (address) {
        return getAddress(LIQUIDATION_LOGIC);
    }

    function backtracker() external view override returns (address) {
        return getAddress(BACKTRACKER);
    }

    function setAddress(bytes32 id, address newAddress) public onlyOwner {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    function setTimelock(address newAddress) public onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[TIMELOCK];
        _addresses[TIMELOCK] = newAddress;
        emit AddressSet(TIMELOCK, oldAddress, newAddress);
    }

    function setPriceOracle(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[PRICE_ORACLE];
        _addresses[PRICE_ORACLE] = newAddress;
        emit AddressSet(PRICE_ORACLE, oldAddress, newAddress);
    }

    function setIndexPriceOracle(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[INDEX_PRICE_ORACLE];
        _addresses[INDEX_PRICE_ORACLE] = newAddress;
        emit AddressSet(INDEX_PRICE_ORACLE, oldAddress, newAddress);
    }

    function setFundingRate(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[FUNDING_RATE];
        _addresses[FUNDING_RATE] = newAddress;
        emit AddressSet(FUNDING_RATE, oldAddress, newAddress);
    }

    function setExecutionLogic(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[EXECUTION_LOGIC];
        _addresses[EXECUTION_LOGIC] = newAddress;
        emit AddressSet(EXECUTION_LOGIC, oldAddress, newAddress);
    }

    function setLiquidationLogic(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[LIQUIDATION_LOGIC];
        _addresses[LIQUIDATION_LOGIC] = newAddress;
        emit AddressSet(LIQUIDATION_LOGIC, oldAddress, newAddress);
    }

    function setBacktracker(address newAddress) external onlyTimelock {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        address oldAddress = _addresses[BACKTRACKER];
        _addresses[BACKTRACKER] = newAddress;
        emit AddressSet(BACKTRACKER, oldAddress, newAddress);
    }

    function setRolManager(address newAddress) external onlyOwner {
        require(newAddress != address(0), Errors.NOT_ADDRESS_ZERO);
        setAddress(ROLE_MANAGER, newAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/TradingTypes.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFeeCollector.sol";

contract Apt is Ownable {
    mapping(address => bool) public robots;
    using SafeERC20 for IERC20;

    IRouter public router;
    IFeeCollector public feeCollector;
    address  public immutable stableCoin;
    enum PositionType {
        Long,
        Short,
        All
    }

    constructor(
        address _router,
        address _owner,
        address robot,
        address _stableCoin,
        address _feeCollector
    ){
        router = IRouter(_router);
        transferOwnership(_owner);
        robots[robot] = true;
        stableCoin = _stableCoin;
        feeCollector = IFeeCollector(_feeCollector);
        IERC20(stableCoin).safeApprove(_router, type(uint256).max);

    }

    modifier onlyRobot() {
        require(robots[msg.sender], "only robet");
        _;
    }

    function setRobot(address _address, bool isRobot) external onlyOwner {
        robots[_address] = isRobot;

    }

    function openPosition(
        uint256 pairIndex, PositionType positionType, uint256 openPrice, uint256 maxSlippage, int256 collateralSize, uint256 orderSize
    ) external payable onlyRobot {

        uint256 usedNetworkFee = 0;
        if (positionType == PositionType.All || positionType == PositionType.Long) {
            usedNetworkFee += msg.value / 2;
            router.createIncreaseOrder{value: msg.value / 2}(TradingTypes.IncreasePositionRequest({
                account: address(this),
                pairIndex: pairIndex,
                tradeType: TradingTypes.TradeType.MARKET,
                collateral: collateralSize,
                openPrice: openPrice,
                isLong: true,
                sizeAmount: orderSize,
                maxSlippage: maxSlippage,
                paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                networkFeeAmount: msg.value / 2
            }));
        }
        if (positionType == PositionType.All || positionType == PositionType.Short) {
            usedNetworkFee += msg.value / 2;
            router.createIncreaseOrder{value: msg.value / 2}(TradingTypes.IncreasePositionRequest({
                account: address(this),
                pairIndex: pairIndex,
                tradeType: TradingTypes.TradeType.MARKET,
                collateral: collateralSize,
                openPrice: openPrice,
                isLong: false,
                sizeAmount: orderSize,
                maxSlippage: maxSlippage,
                paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                networkFeeAmount: msg.value / 2
            }));
        }

        if (msg.value > usedNetworkFee) {
            payable(msg.sender).transfer(msg.value - usedNetworkFee);
        }
    }

    function closePosition(
        IRouter.CancelOrderRequest[] memory requests,
        uint256 pairIndex, PositionType positionType,
        uint256 openPrice, uint256 maxSlippage, int256 collateralSize, uint256 orderSize
    ) external payable onlyRobot {
        if (requests.length > 0) {
            router.cancelOrders(requests);
        }
        uint256 usedNetworkFee = 0;
        if (positionType == PositionType.All || positionType == PositionType.Long) {
            usedNetworkFee += msg.value / 2;
            router.createDecreaseOrder{value: msg.value / 2}(
                TradingTypes.DecreasePositionRequest(
                    {account: address(this),
                        pairIndex: pairIndex,
                        tradeType: TradingTypes.TradeType.MARKET,
                        collateral: collateralSize,
                        triggerPrice: openPrice,
                        sizeAmount: orderSize,
                        isLong: true,
                        maxSlippage: maxSlippage,
                        paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                        networkFeeAmount: msg.value / 2
                    }
                ));
        }
        if (positionType == PositionType.All || positionType == PositionType.Short) {
            usedNetworkFee += msg.value / 2;
            router.createDecreaseOrder{value: msg.value / 2}(
                TradingTypes.DecreasePositionRequest(
                    {account: address(this),
                        pairIndex: pairIndex,
                        tradeType: TradingTypes.TradeType.MARKET,
                        collateral: collateralSize,
                        triggerPrice: openPrice,
                        sizeAmount: orderSize,
                        isLong: false,
                        maxSlippage: maxSlippage,
                        paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                        networkFeeAmount: msg.value / 2
                    }
                ));
        }
        if (msg.value > usedNetworkFee) {
            payable(msg.sender).transfer(msg.value - usedNetworkFee);
        }
    }

    function callRouter(bytes[] calldata calls) external onlyOwner {
        for (uint256 i; i < calls.length;) {
            (bool success, bytes memory result) = address(router).delegatecall(
                calls[i]
            );
            require(success, "!su");
            unchecked {
                ++i;
            }
        }
    }

    function setPriceAndAdjustCollateral(
        uint256 pairIndex,
        bool isLong,
        int256 collateral,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable onlyOwner {
        router.setPriceAndAdjustCollateral{value: msg.value}(pairIndex, isLong, collateral, tokens, updateData, publishTimes);
    }

    function claimUserTradingFee() external returns (uint256) {
        return feeCollector.claimUserTradingFee();
    }

    function salvageToken(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        address payable recipient = payable(owner());
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Failed Ether");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IBacktracker.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";

contract Backtracker is IBacktracker {

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    bool public override backtracking;
    uint64 public override backtrackRound;
    address public executor;

    constructor(IAddressesProvider addressProvider) {
        ADDRESS_PROVIDER = addressProvider;
        backtracking = false;
    }

    modifier whenNotBacktracking() {
        _requireNotBacktracking();
        _;
    }

    modifier whenBacktracking() {
        _requireBacktracking();
        _;
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "only poolAdmin");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    function updateExecutorAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = newAddress;
        emit UpdatedExecutorAddress(msg.sender, oldAddress, newAddress);
    }

    function enterBacktracking(uint64 _backtrackRound) external whenNotBacktracking onlyExecutor {
        backtracking = true;
        backtrackRound = _backtrackRound;
        emit Backtracking(msg.sender, _backtrackRound);
    }

    function quitBacktracking() external whenBacktracking onlyExecutor {
        backtracking = false;
        emit UnBacktracking(msg.sender);
    }

    function _requireNotBacktracking() internal view {
        require(!backtracking, "Backtracker: backtracking");
    }

    function _requireBacktracking() internal view {
        require(backtracking, "Backtracker: not backtracking");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IExecutor.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IIndexPriceFeed.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/IExecutionLogic.sol";
import "../libraries/Roleable.sol";
import "../interfaces/ILiquidationLogic.sol";
import "./Backtracker.sol";
import "../interfaces/IPositionManager.sol";

contract Executor is IExecutor, Roleable, ReentrancyGuard, Pausable {

    IPositionManager public positionManager;

    constructor(
        IAddressesProvider addressProvider
    ) Roleable(addressProvider) {
    }

    modifier onlyPositionKeeper() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isKeeper(msg.sender), "opk");
        _;
    }

    function setPaused() external onlyPoolAdmin {
        _pause();
    }

    function setUnPaused() external onlyPoolAdmin {
        _unpause();
    }

    function updatePositionManager(address _positionManager) external onlyPoolAdmin {
        address oldAddress = address(positionManager);
        positionManager = IPositionManager(_positionManager);
        emit UpdatePositionManager(msg.sender, oldAddress, _positionManager);
    }

    function setPricesAndExecuteOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory orders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        for (uint256 i = 0; i < orders.length; i++) {
            IExecutionLogic.ExecuteOrder memory order = orders[i];
            if (order.isIncrease) {
                IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeIncreaseOrders(
                    msg.sender,
                    _fillOrders(order),
                    order.tradeType
                );
            } else {
                IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeDecreaseOrders(
                    msg.sender,
                    _fillOrders(order),
                    order.tradeType
                );
            }
        }
    }

    function setPricesAndExecuteIncreaseMarketOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory increaseOrders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeIncreaseOrders(
            msg.sender,
            increaseOrders,
            TradingTypes.TradeType.MARKET
        );
    }

    function setPricesAndExecuteDecreaseMarketOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory decreaseOrders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeDecreaseOrders(
            msg.sender,
            decreaseOrders,
            TradingTypes.TradeType.MARKET
        );
    }

    function setPricesAndExecuteIncreaseLimitOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory increaseOrders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeIncreaseOrders(
            msg.sender,
            increaseOrders,
            TradingTypes.TradeType.LIMIT
        );
    }

    function setPricesAndExecuteDecreaseLimitOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory decreaseOrders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeDecreaseOrders(
            msg.sender,
            decreaseOrders,
            TradingTypes.TradeType.LIMIT
        );
    }

    function setPricesAndExecuteADLOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        uint256 pairIndex,
        IExecution.ExecutePosition[] memory executePositions,
        IExecutionLogic.ExecuteOrder[] memory executeOrders
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(tokens.length == prices.length && tokens.length >= 0, "ip");

        _setPrices(tokens, prices, updateData, publishTimes);

        IExecutionLogic(ADDRESS_PROVIDER.executionLogic()).executeADLAndDecreaseOrders(
            msg.sender,
            pairIndex,
            executePositions,
            executeOrders
        );
    }

    function setPricesAndLiquidatePositions(
        address[] memory _tokens,
        uint256[] memory _prices,
        LiquidatePosition[] memory liquidatePositions
    ) external payable override whenNotPaused nonReentrant onlyPositionKeeper {
        require(_tokens.length == _prices.length && _tokens.length >= 0, "ip");

        IIndexPriceFeed(ADDRESS_PROVIDER.indexPriceOracle()).updatePrice(_tokens, _prices);

        for (uint256 i = 0; i < liquidatePositions.length; i++) {
            LiquidatePosition memory execute = liquidatePositions[i];

            IBacktracker(ADDRESS_PROVIDER.backtracker()).enterBacktracking(execute.backtrackRound);

            address[] memory tokens = new address[](1);
            tokens[0] = execute.token;
            bytes[] memory updatesData = new bytes[](1);
            updatesData[0] = execute.updateData;
            IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updateHistoricalPrice{value: execute.updateFee}(
                tokens,
                updatesData,
                execute.backtrackRound
            );

            try ILiquidationLogic(ADDRESS_PROVIDER.liquidationLogic()).liquidationPosition(
                msg.sender,
                execute.positionKey,
                execute.tier,
                execute.referralsRatio,
                execute.referralUserRatio,
                execute.referralOwner
            ) {} catch Error(string memory reason) {
                emit ExecutePositionError(execute.positionKey, reason);
            }

            IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).removeHistoricalPrice(
                execute.backtrackRound,
                tokens
            );

            IBacktracker(ADDRESS_PROVIDER.backtracker()).quitBacktracking();
        }
    }

    function _setPrices(
        address[] memory _tokens,
        uint256[] memory _prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes
    ) internal {
        IIndexPriceFeed(ADDRESS_PROVIDER.indexPriceOracle()).updatePrice(_tokens, _prices);

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(
            _tokens,
            updateData,
            publishTimes
        );
    }

//    function _setPricesHistorical(
//        address[] memory _tokens,
//        uint256[] memory _prices,
//        bytes[] memory updateData,
//        uint64 backtrackRound
//    ) internal {
//
//        IIndexPriceFeed(ADDRESS_PROVIDER.indexPriceOracle()).updatePrice(_tokens, _prices);
//
//        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updateHistoricalPrice{value: msg.value}(
//            _tokens,
//            updateData,
//            backtrackRound
//        );
//    }

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool need, uint256 needADLAmount) {
        return positionManager.needADL(pairIndex, isLong, executionSize, executionPrice);
    }

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external override whenNotPaused nonReentrant onlyPositionKeeper {
        ILiquidationLogic(ADDRESS_PROVIDER.liquidationLogic()).cleanInvalidPositionOrders(positionKeys);
    }

    function _fillOrders(
        IExecutionLogic.ExecuteOrder memory order
    ) private pure returns (IExecutionLogic.ExecuteOrder[] memory increaseOrders) {
        increaseOrders = new IExecutionLogic.ExecuteOrder[](1);
        increaseOrders[0] = order;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Int256Utils.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IPool.sol";
import "../libraries/TradingTypes.sol";

contract FeeCollector is IFeeCollector, ReentrancyGuardUpgradeable, Upgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Int256Utils for int256;
    using PrecisionUtils for uint256;

    // Trading fee of each tier (pairIndex => tier => fee)
    mapping(uint256 => mapping(uint8 => TradingFeeTier)) public tradingFeeTiers;

    // Maximum of referrals ratio
    uint256 public override maxReferralsRatio;

    uint256 public override stakingTradingFee;
    // upgrade(v1.1)
    uint256 public override stakingTradingFeeDebt;

    // user + keeper(v1)
    mapping(address => uint256) public override userTradingFee;
    // upgrade(v1.1)
    mapping(address => int256) public override keeperTradingFee;

    uint256 public override treasuryFee;
    // upgrade(v1.1)
    uint256 public override treasuryFeeDebt;

    int256 public override reservedTradingFee;

    int256 public override ecoFundTradingFee;

    mapping(address => uint256) public override referralFee;

    mapping(address => mapping(TradingTypes.InnerPaymentType => uint256)) public keeperNetworkFee;

    address public pledgeAddress;

    address public addressStakingPool;
    address public addressPositionManager;
    address public addressExecutionLogic;
    IPool public pool;

    function initialize(
        IAddressesProvider addressesProvider,
        IPool _pool,
        address _pledgeAddress
    ) public initializer {
        ADDRESS_PROVIDER = addressesProvider;
        pool = _pool;
        pledgeAddress = _pledgeAddress;
        maxReferralsRatio = 0.5e8;
    }

    modifier onlyPositionManagerOrLogic() {
        require(msg.sender == addressPositionManager || msg.sender == addressExecutionLogic, "onlyPositionManager");
        _;
    }

    modifier onlyTreasury() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isTreasurer(msg.sender), "onlyTreasury");
        _;
    }

    modifier onlyStakingPool() {
        require(msg.sender == addressStakingPool, "onlyStakingPool");
        _;
    }

    function getTradingFeeTier(uint256 pairIndex, uint8 tier) external view override returns (TradingFeeTier memory) {
        return tradingFeeTiers[pairIndex][tier];
    }

    function getRegularTradingFeeTier(uint256 pairIndex) external view override returns (TradingFeeTier memory) {
        return tradingFeeTiers[pairIndex][0];
    }

    function getKeeperNetworkFee(
        address account,
        TradingTypes.InnerPaymentType paymentType
    ) external view override returns (uint256) {
        return keeperNetworkFee[account][paymentType];
    }

    function updatePositionManagerAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = addressPositionManager;
        addressPositionManager = newAddress;

        emit UpdatedPositionManagerAddress(msg.sender, oldAddress, newAddress);
    }

    function updateExecutionLogicAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = addressExecutionLogic;
        addressExecutionLogic = newAddress;

        emit UpdateExecutionLogicAddress(msg.sender, oldAddress, newAddress);
    }

    function updateStakingPoolAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = addressStakingPool;
        addressStakingPool = newAddress;

        emit UpdatedStakingPoolAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePoolAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = address(pool);
        pool = IPool(newAddress);

        emit UpdatePoolAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePledgeAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = pledgeAddress;
        pledgeAddress = newAddress;

        emit UpdatePledgeAddress(msg.sender, oldAddress, newAddress);
    }

    function updateTradingFeeTiers(
        uint256 pairIndex,
        uint8[] memory tiers,
        TradingFeeTier[] memory tierFees
    ) external onlyPoolAdmin {
        require(tiers.length == tierFees.length, "inconsistent params length");

        for (uint256 i = 0; i < tiers.length; i++) {
            _updateTradingFeeTier(pairIndex, tiers[i], tierFees[i]);
        }
    }

    function updateTradingFeeTier(
        uint256 pairIndex,
        uint8 tier,
        TradingFeeTier memory tierFee
    ) external onlyPoolAdmin {
        _updateTradingFeeTier(pairIndex, tier, tierFee);
    }

    function updateMaxReferralsRatio(uint256 newRatio) external override onlyPoolAdmin {
        require(newRatio <= PrecisionUtils.percentage(), "exceeds max ratio");

        uint256 oldRatio = maxReferralsRatio;
        maxReferralsRatio = newRatio;

        emit UpdateMaxReferralsRatio(oldRatio, newRatio);
    }

    function claimStakingTradingFee() external override onlyStakingPool returns (uint256) {
        require(stakingTradingFee > stakingTradingFeeDebt, "insufficient available balance");

        uint256 claimableStakingTradingFee = stakingTradingFee - stakingTradingFeeDebt;
        stakingTradingFee = 0;
        stakingTradingFeeDebt = 0;
        pool.transferTokenTo(pledgeAddress, msg.sender, claimableStakingTradingFee);

        emit ClaimedStakingTradingFee(msg.sender, pledgeAddress, claimableStakingTradingFee);
        return claimableStakingTradingFee;
    }

    function claimTreasuryFee() external override onlyTreasury returns (uint256) {
        require(treasuryFee > treasuryFeeDebt, "insufficient available balance");

        uint256 claimableTreasuryFee = treasuryFee - treasuryFeeDebt;
        treasuryFee = 0;
        treasuryFeeDebt = 0;
        pool.transferTokenTo(pledgeAddress, msg.sender, claimableTreasuryFee);

        emit ClaimedDistributorTradingFee(msg.sender, pledgeAddress, claimableTreasuryFee);
        return claimableTreasuryFee;
    }

    function claimReferralFee() external override nonReentrant returns (uint256) {
        uint256 claimableReferralFee = referralFee[msg.sender];
        if (claimableReferralFee > 0) {
            referralFee[msg.sender] = 0;
            pool.transferTokenTo(pledgeAddress, msg.sender, claimableReferralFee);
        }
        emit ClaimedReferralsTradingFee(msg.sender, pledgeAddress, claimableReferralFee);
        return claimableReferralFee;
    }

    function claimUserTradingFee() external override nonReentrant returns (uint256) {
        uint256 claimableUserTradingFee = userTradingFee[msg.sender];
        if (claimableUserTradingFee > 0) {
            userTradingFee[msg.sender] = 0;
            pool.transferTokenTo(pledgeAddress, msg.sender, claimableUserTradingFee);
        }
        emit ClaimedUserTradingFee(msg.sender, pledgeAddress, claimableUserTradingFee);
        return claimableUserTradingFee;
    }

    function claimKeeperTradingFee() external override nonReentrant returns (uint256) {
        int256 claimableKeeperTradingFee = keeperTradingFee[msg.sender];

        require(claimableKeeperTradingFee > 0, "insufficient available balance");
        keeperTradingFee[msg.sender] = 0;
        pool.transferTokenTo(pledgeAddress, msg.sender, uint256(claimableKeeperTradingFee));

        emit ClaimedKeeperTradingFee(msg.sender, pledgeAddress, uint256(claimableKeeperTradingFee));
        return uint256(claimableKeeperTradingFee);
    }

    function claimKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType
    ) external override nonReentrant returns (uint256) {
        uint256 claimableNetworkFee = keeperNetworkFee[msg.sender][paymentType];
        address claimableToken = address(0);
        if (claimableNetworkFee > 0) {
            keeperNetworkFee[msg.sender][paymentType] = 0;
            if (paymentType == TradingTypes.InnerPaymentType.ETH) {
                pool.transferEthTo(msg.sender, claimableNetworkFee);
            } else if (paymentType == TradingTypes.InnerPaymentType.COLLATERAL) {
                claimableToken = pledgeAddress;
                pool.transferTokenTo(pledgeAddress, msg.sender, claimableNetworkFee);
            }
        }
        emit ClaimedKeeperNetworkFee(msg.sender, claimableToken, claimableNetworkFee);
        return claimableNetworkFee;
    }

    function distributeTradingFee(
        IPool.Pair memory pair,
        address account,
        uint256 orderId,
        address keeper,
        uint256 size,
        uint256 sizeDelta,
        uint256 executionPrice,
        uint256 tradingFee,
        bool isMaker,
        TradingFeeTier memory tradingFeeTier,
        int256 exposureAmount,
        int256 afterExposureAmount,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external override onlyPositionManagerOrLogic returns (int256 lpAmount, int256 vipTradingFee, uint256 givebackFeeAmount) {
        IPool.TradingFeeConfig memory tradingFeeConfig = pool.getTradingFeeConfig(pair.pairIndex);
        uint256 avgPrice = pool.getVault(pair.pairIndex).averagePrice;
        // vip discount

        // negative maker rate
        if (isMaker && tradingFeeTier.makerFee < 0 && exposureAmount != 0) {
            int256 offset;
            if (exposureAmount < 0) {
                uint256 diffRatio = executionPrice * PrecisionUtils.percentage() / avgPrice;
                offset = SignedMath.min(0, int256(diffRatio) - int256(PrecisionUtils.percentage()));
            } else {
                uint256 diffRatio = avgPrice * PrecisionUtils.percentage() / executionPrice;
                offset = SignedMath.min(0, int256(diffRatio) - int256(PrecisionUtils.percentage()));
            }

            int256 feeRate = afterExposureAmount.abs() < exposureAmount.abs() ? tradingFeeTier.makerFee : int256(0);
            uint256 rebateAmount = uint256(
                TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(size), avgPrice)
            ) * uint256(SignedMath.max(0, int256(feeRate.abs()) + offset)) / PrecisionUtils.percentage();

            (
                uint256 lpReturnAmount,
                uint256 keeperReturnAmount,
                uint256 stakingReturnAmount,
                uint256 reservedReturnAmount,
                uint256 ecoFundReturnAmount,
                uint256 treasuryReturnAmount
            ) = _collectTradingFee(pair.pairIndex, rebateAmount, tradingFeeConfig, keeper);

            givebackFeeAmount += tradingFee + rebateAmount;
            userTradingFee[account] += givebackFeeAmount;

            emit DistributeTradingFeeV2(
                account,
                pair.pairIndex,
                orderId,
                sizeDelta,
                tradingFee,
                isMaker,
                feeRate,
                -int256(rebateAmount),
                givebackFeeAmount,
                0,
                0,
                address(0),
                -int256(lpReturnAmount),
                -int256(keeperReturnAmount),
                -int256(stakingReturnAmount),
                -int256(reservedReturnAmount),
                -int256(ecoFundReturnAmount),
                -int256(treasuryReturnAmount)
            );
            return (-int256(lpReturnAmount), -int256(rebateAmount), givebackFeeAmount);
        }

        uint256 vipFeeRate = isMaker ? uint256(tradingFeeTier.makerFee) : tradingFeeTier.takerFee;
        vipTradingFee = int256(sizeDelta.mulPercentage(vipFeeRate));

        givebackFeeAmount = tradingFee > uint256(vipTradingFee) ? tradingFee - uint256(vipTradingFee) : 0;
        userTradingFee[account] += givebackFeeAmount;

        uint256 surplusFee = tradingFee - givebackFeeAmount;

        // referrals amount
        uint256 referralsAmount;
        uint256 referralUserAmount;
        if (referralOwner != address(0)) {
            referralsAmount = surplusFee.mulPercentage(
                Math.min(referralsRatio, maxReferralsRatio)
            );
            referralUserAmount = surplusFee.mulPercentage(Math.min(referralUserRatio, referralsRatio));

            referralFee[account] += referralUserAmount;
            referralFee[referralOwner] += referralsAmount - referralUserAmount;

            surplusFee = surplusFee - referralsAmount;
        }

        lpAmount = int256(surplusFee.mulPercentage(tradingFeeConfig.lpFeeDistributeP));
        pool.setLPStableProfit(pair.pairIndex, lpAmount);

        uint256 keeperAmount = surplusFee.mulPercentage(tradingFeeConfig.keeperFeeDistributeP);
        keeperTradingFee[keeper] += int256(keeperAmount);

        uint256 stakingAmount = surplusFee.mulPercentage(tradingFeeConfig.stakingFeeDistributeP);
        stakingTradingFee += stakingAmount;

        uint256 reservedAmount = surplusFee.mulPercentage(tradingFeeConfig.reservedFeeDistributeP);
        reservedTradingFee += int256(reservedAmount);

        uint256 ecoFundAmount = surplusFee.mulPercentage(tradingFeeConfig.ecoFundFeeDistributeP);
        ecoFundTradingFee += int256(ecoFundAmount);

        uint256 distributorAmount = surplusFee - uint256(lpAmount) - keeperAmount - stakingAmount - reservedAmount - ecoFundAmount;
        treasuryFee += distributorAmount;

        emit DistributeTradingFeeV2(
            account,
            pair.pairIndex,
            orderId,
            sizeDelta,
            tradingFee,
            isMaker,
            int256(vipFeeRate),
            vipTradingFee,
            givebackFeeAmount,
            referralsAmount,
            referralUserAmount,
            referralOwner,
            lpAmount,
            int256(keeperAmount),
            int256(stakingAmount),
            int256(reservedAmount),
            int256(ecoFundAmount),
            int256(distributorAmount)
        );
    }

    function distributeNetworkFee(
        address keeper,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    ) external override onlyPositionManagerOrLogic {
        if (paymentType != TradingTypes.InnerPaymentType.NONE) {
            keeperNetworkFee[keeper][paymentType] += networkFeeAmount;
        }
    }

    function _collectTradingFee(
        uint256 pairIndex,
        uint256 amount,
        IPool.TradingFeeConfig memory tradingFeeConfig,
        address keeper
    ) internal returns (
        uint256 lpReturnAmount,
        uint256 keeperReturnAmount,
        uint256 stakingReturnAmount,
        uint256 reservedReturnAmount,
        uint256 ecoFundReturnAmount,
        uint256 treasuryReturnAmount
    ){
        if (amount == 0) {
            return (0, 0, 0, 0, 0, 0);
        }
        lpReturnAmount = amount.mulPercentage(tradingFeeConfig.lpFeeDistributeP);
        pool.givebackTradingFee(pairIndex, lpReturnAmount);

        keeperReturnAmount = amount.mulPercentage(tradingFeeConfig.keeperFeeDistributeP);
        keeperTradingFee[keeper] -= int256(keeperReturnAmount);

        stakingReturnAmount = amount.mulPercentage(tradingFeeConfig.stakingFeeDistributeP);
        stakingTradingFeeDebt += stakingReturnAmount;

        reservedReturnAmount = amount.mulPercentage(tradingFeeConfig.reservedFeeDistributeP);
        reservedTradingFee -= int256(reservedReturnAmount);

        ecoFundReturnAmount = amount.mulPercentage(tradingFeeConfig.ecoFundFeeDistributeP);
        ecoFundTradingFee -= int256(ecoFundReturnAmount);

        treasuryReturnAmount = amount - (lpReturnAmount + keeperReturnAmount + stakingReturnAmount + reservedReturnAmount + ecoFundReturnAmount);
        treasuryFeeDebt += treasuryReturnAmount;
    }

    function _updateTradingFeeTier(
        uint256 pairIndex,
        uint8 tier,
        TradingFeeTier memory tierFee
    ) internal {
        TradingFeeTier memory regularTierFee = tradingFeeTiers[pairIndex][0];
        require(tier != 0 || tierFee.makerFee >= 0, "makerFee must be non-negative for tier 0");
        require(tier == 0
            || (tierFee.takerFee <= regularTierFee.takerFee && tierFee.makerFee <= regularTierFee.makerFee),
            "exceeds max ratio"
        );

        TradingFeeTier memory oldTierFee = tradingFeeTiers[pairIndex][tier];
        tradingFeeTiers[pairIndex][tier] = tierFee;

        emit UpdatedTradingFeeTier(
            msg.sender,
            tier,
            oldTierFee.takerFee,
            oldTierFee.makerFee,
            tradingFeeTiers[pairIndex][tier].takerFee,
            tradingFeeTiers[pairIndex][tier].makerFee
        );
    }

    function rescueKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType,
        RescueKeeperNetworkFee[] calldata rescues
    ) external override nonReentrant onlyAdmin {
        for (uint256 i = 0; i < rescues.length; i++) {
            uint256 claimableNetworkFee = keeperNetworkFee[rescues[i].keeper][paymentType];
            address claimableToken = address(0);
            if (claimableNetworkFee > 0) {
                keeperNetworkFee[rescues[i].keeper][paymentType] = 0;
                if (paymentType == TradingTypes.InnerPaymentType.ETH) {
                    pool.transferEthTo(rescues[i].receiver, claimableNetworkFee);
                } else if (paymentType == TradingTypes.InnerPaymentType.COLLATERAL) {
                    claimableToken = pledgeAddress;
                    pool.transferTokenTo(pledgeAddress, rescues[i].receiver, claimableNetworkFee);
                }
            }
            emit ClaimedKeeperNetworkFee(rescues[i].keeper, claimableToken, claimableNetworkFee);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IFundingRate.sol";
import "../interfaces/IPool.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Int256Utils.sol";
import "../helpers/TokenHelper.sol";

contract FundingRate is IFundingRate, Upgradeable {
    using PrecisionUtils for uint256;
    using Int256Utils for int256;
    using Math for uint256;
    using SafeMath for uint256;

    mapping(uint256 => FundingFeeConfig) public fundingFeeConfigs;

    function initialize(IAddressesProvider addressProvider) public initializer {
        ADDRESS_PROVIDER = addressProvider;
    }

    function updateFundingFeeConfig(
        uint256 _pairIndex,
        FundingFeeConfig calldata _fundingFeeConfig
    ) external onlyPoolAdmin {
        require(
            _fundingFeeConfig.growthRate.abs() <= PrecisionUtils.percentage() &&
                _fundingFeeConfig.baseRate.abs() <= PrecisionUtils.percentage() &&
                _fundingFeeConfig.maxRate.abs() <= PrecisionUtils.percentage() &&
                _fundingFeeConfig.fundingInterval <= 86400,
            "exceed max"
        );

        fundingFeeConfigs[_pairIndex] = _fundingFeeConfig;
    }

    function getFundingInterval(uint256 _pairIndex) public view override returns (uint256) {
        FundingFeeConfig memory fundingFeeConfig = fundingFeeConfigs[_pairIndex];
        return fundingFeeConfig.fundingInterval;
    }

    function getFundingRate(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) public view override returns (int256 fundingRate) {
        FundingFeeConfig memory fundingFeeConfig = fundingFeeConfigs[pair.pairIndex];

        int256 baseRate = fundingFeeConfig.baseRate;
        int256 maxRate = fundingFeeConfig.maxRate;
        int256 k = fundingFeeConfig.growthRate;

        int256 u = int256(vault.stableTotalAmount)
            + TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price)
            - int256(vault.stableReservedAmount);
        int256 v = TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexTotalAmount), price)
            + int256(vault.stableReservedAmount)
            - TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price);

        if (u == v) {
            return baseRate / int256(86400 / fundingFeeConfig.fundingInterval);
        }

        int256 precision = int256(PrecisionUtils.fundingRatePrecision());
        // S = (U-V)/(U+V)
        int256 s = (u - v) * precision / (u + v);

        // G1 = MIN((S+S*S/2) * k + r, r(max))
        int256 g1 = _min(
            (((s * s) / 2 / precision) + s) * k / precision + baseRate,
            maxRate
        );
        fundingRate = g1 / int256(86400 / fundingFeeConfig.fundingInterval);
    }

    function _min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../../libraries/Position.sol";
import "../../interfaces/IExecutionLogic.sol";
import "../../interfaces/IAddressesProvider.sol";
import "../../interfaces/IRoleManager.sol";
import "../../interfaces/IOrderManager.sol";
import "../../interfaces/IPositionManager.sol";
import "../../interfaces/IPool.sol";
import "../../helpers/ValidationHelper.sol";
import "../../helpers/TradingHelper.sol";
import "../../interfaces/IFeeCollector.sol";
import "../../interfaces/IExecutor.sol";

contract ExecutionLogic is IExecutionLogic {
    using PrecisionUtils for uint256;
    using Math for uint256;
    using Int256Utils for int256;
    using Int256Utils for uint256;
    using Position for Position.Info;

    uint256 public override maxTimeDelay;

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    IPool public immutable pool;
    IOrderManager public immutable orderManager;
    IPositionManager public immutable positionManager;
    address public executor;

    IFeeCollector public immutable feeCollector;

    constructor(
        IAddressesProvider addressProvider,
        IPool _pool,
        IOrderManager _orderManager,
        IPositionManager _positionManager,
        IFeeCollector _feeCollector,
        uint256 _maxTimeDelay
    ) {
        ADDRESS_PROVIDER = addressProvider;
        pool = _pool;
        orderManager = _orderManager;
        positionManager = _positionManager;
        feeCollector = _feeCollector;
        maxTimeDelay = _maxTimeDelay;
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutorOrSelf() {
        require(msg.sender == executor || msg.sender == address(this), "oe");
        _;
    }

    function updateExecutor(address _executor) external override onlyPoolAdmin {
        address oldAddress = executor;
        executor = _executor;
        emit UpdateExecutorAddress(msg.sender, oldAddress, _executor);
    }

    function updateMaxTimeDelay(uint256 newMaxTimeDelay) external override onlyPoolAdmin {
        uint256 oldDelay = maxTimeDelay;
        maxTimeDelay = newMaxTimeDelay;
        emit UpdateMaxTimeDelay(oldDelay, newMaxTimeDelay);
    }

    function executeIncreaseOrders(
        address keeper,
        ExecuteOrder[] memory orders,
        TradingTypes.TradeType tradeType
    ) external override onlyExecutorOrSelf {
        for (uint256 i = 0; i < orders.length; i++) {
            ExecuteOrder memory order = orders[i];

            try
                this.executeIncreaseOrder(
                    keeper,
                    order.orderId,
                    tradeType,
                    order.tier,
                    order.referralsRatio,
                    order.referralUserRatio,
                    order.referralOwner
                )
            {} catch Error(string memory reason) {
                emit ExecuteOrderError(order.orderId, reason);
                orderManager.cancelOrder(
                    order.orderId,
                    tradeType,
                    true,
                    reason
                );
            }
        }
    }

    function executeIncreaseOrder(
        address keeper,
        uint256 _orderId,
        TradingTypes.TradeType _tradeType,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external override onlyExecutorOrSelf {
        TradingTypes.OrderNetworkFee memory orderNetworkFee;
        TradingTypes.IncreasePositionOrder memory order;
        (order, orderNetworkFee) = orderManager.getIncreaseOrder(_orderId, _tradeType);
        if (order.account == address(0)) {
            emit InvalidOrder(keeper, _orderId, 'address 0');
            return;
        }

        // is expired
        if (order.tradeType == TradingTypes.TradeType.MARKET) {
            require(order.blockTime + maxTimeDelay >= block.timestamp, "order expired");
        }

        // check pair enable
        uint256 pairIndex = order.pairIndex;
        IPool.Pair memory pair = pool.getPair(pairIndex);
        if (!pair.enable) {
            orderManager.cancelOrder(order.orderId, order.tradeType, true, "!enable");
            return;
        }

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);

        // validate can be triggered
        uint256 executionPrice = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );
        bool isAbove = order.isLong &&
            (order.tradeType == TradingTypes.TradeType.MARKET ||
                order.tradeType == TradingTypes.TradeType.LIMIT);
        ValidationHelper.validatePriceTriggered(
            tradingConfig,
            order.tradeType,
            true,
            order.isLong,
            isAbove,
            executionPrice,
            order.openPrice,
            order.maxSlippage
        );

        bytes32 positionKey = positionManager.getPositionKey(order.account, order.pairIndex, order.isLong);
        // get position
        Position.Info memory position = positionManager.getPosition(order.account, order.pairIndex, order.isLong);
        require(
            position.positionAmount == 0 || !positionManager.needLiquidation(positionKey, executionPrice),
            "need liquidation"
        );

        // compare openPrice and oraclePrice
        if (order.tradeType == TradingTypes.TradeType.LIMIT) {
            if (order.isLong) {
                executionPrice = Math.min(order.openPrice, executionPrice);
            } else {
                executionPrice = Math.max(order.openPrice, executionPrice);
            }
        }

        IPool.Vault memory lpVault = pool.getVault(pairIndex);
        int256 exposureAmount = positionManager.getExposedPositions(pairIndex);

        uint256 orderSize = order.sizeAmount - order.executedSize;
        uint256 executionSize;
        if (orderSize > 0) {
            (executionSize) = TradingHelper.exposureAmountChecker(
                lpVault,
                pair,
                exposureAmount,
                order.isLong,
                orderSize,
                executionPrice
            );
            if (executionSize == 0) {
                orderManager.cancelOrder(order.orderId, order.tradeType, true, "nal");
                return;
            }
        }

        int256 collateral;
        if (order.collateral > 0) {
            collateral = order.executedSize == 0 || order.tradeType == TradingTypes.TradeType.MARKET
                ? order.collateral
                : int256(0);
        } else {
            collateral = order.executedSize + executionSize >= order.sizeAmount ||
                order.tradeType == TradingTypes.TradeType.MARKET
                ? order.collateral
                : int256(0);
        }
        // check position and leverage
        (uint256 afterPosition, ) = position.validLeverage(
            pair,
            executionPrice,
            collateral,
            executionSize,
            true,
            tradingConfig.maxLeverage,
            tradingConfig.maxPositionAmount,
            false,
            positionManager.getFundingFee(order.account, order.pairIndex, order.isLong)
        );
        require(afterPosition > 0, "zpa");

        // increase position
        (uint256 tradingFee, int256 fundingFee) = positionManager.increasePosition(
            pairIndex,
            order.orderId,
            order.account,
            keeper,
            executionSize,
            order.isLong,
            collateral,
            feeCollector.getTradingFeeTier(pairIndex, tier),
            referralsRatio,
            referralUserRatio,
            referralOwner,
            executionPrice
        );

        // add executed size
        order.executedSize += executionSize;
        orderManager.increaseOrderExecutedSize(order.orderId, order.tradeType, true, executionSize);

        // remove order
        if (
            order.tradeType == TradingTypes.TradeType.MARKET ||
            order.executedSize >= order.sizeAmount
        ) {
            orderManager.removeOrderFromPosition(
                IOrderManager.PositionOrder(
                    order.account,
                    order.pairIndex,
                    order.isLong,
                    true,
                    order.tradeType,
                    _orderId,
                    order.sizeAmount
                )
            );

            // delete order
            if (_tradeType == TradingTypes.TradeType.MARKET) {
                orderManager.removeIncreaseMarketOrders(_orderId);
            } else if (_tradeType == TradingTypes.TradeType.LIMIT) {
                orderManager.removeIncreaseLimitOrders(_orderId);
            }

            feeCollector.distributeNetworkFee(keeper, orderNetworkFee.paymentType, orderNetworkFee.networkFeeAmount);
        }

        emit ExecuteIncreaseOrder(
            order.account,
            order.orderId,
            order.pairIndex,
            order.tradeType,
            order.isLong,
            collateral,
            order.sizeAmount,
            order.openPrice,
            executionSize,
            executionPrice,
            order.executedSize,
            tradingFee,
            fundingFee,
            orderNetworkFee.paymentType,
            orderNetworkFee.networkFeeAmount
        );
    }

    function executeDecreaseOrders(
        address keeper,
        ExecuteOrder[] memory orders,
        TradingTypes.TradeType tradeType
    ) external override onlyExecutorOrSelf {
        for (uint256 i = 0; i < orders.length; i++) {
            ExecuteOrder memory order = orders[i];
            try
                this.executeDecreaseOrder(
                    keeper,
                    order.orderId,
                    tradeType,
                    order.tier,
                    order.referralsRatio,
                    order.referralUserRatio,
                    order.referralOwner,
                    false,
                    0,
                    tradeType == TradingTypes.TradeType.MARKET
                )
            {} catch Error(string memory reason) {
                emit ExecuteOrderError(order.orderId, reason);
                orderManager.cancelOrder(
                    order.orderId,
                    tradeType,
                    false,
                    reason
                );
            }
        }
    }

    function executeDecreaseOrder(
        address keeper,
        uint256 _orderId,
        TradingTypes.TradeType _tradeType,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        bool isSystem,
        uint256 executionSize,
        bool onlyOnce
    ) external override onlyExecutorOrSelf {
        TradingTypes.OrderNetworkFee memory orderNetworkFee;
        TradingTypes.DecreasePositionOrder memory order;
        (order, orderNetworkFee) = orderManager.getDecreaseOrder(_orderId, _tradeType);
        if (order.account == address(0)) {
            emit InvalidOrder(keeper, _orderId, 'address 0');
            return;
        }

        // is expired
        if (order.tradeType == TradingTypes.TradeType.MARKET) {
            require(order.blockTime + maxTimeDelay >= block.timestamp, "order expired");
        }

        // check pair enable
        uint256 pairIndex = order.pairIndex;
        IPool.Pair memory pair = pool.getPair(pairIndex);
        if (!pair.enable) {
            orderManager.cancelOrder(order.orderId, order.tradeType, false, "!enable");
            return;
        }

        // get position
        Position.Info memory position = positionManager.getPosition(
            order.account,
            order.pairIndex,
            order.isLong
        );
        if (position.positionAmount == 0) {
            orderManager.cancelAllPositionOrders(order.account, order.pairIndex, order.isLong);
            return;
        }

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);

        if (executionSize == 0) {
            executionSize = order.sizeAmount - order.executedSize;
//            if (executionSize > tradingConfig.maxTradeAmount && !isSystem) {
//                executionSize = tradingConfig.maxTradeAmount;
//            }
        }

        // valid order size
        executionSize = Math.min(executionSize, position.positionAmount);

        // validate can be triggered
        uint256 executionPrice = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );
        ValidationHelper.validatePriceTriggered(
            tradingConfig,
            order.tradeType,
            false,
            order.isLong,
            order.abovePrice,
            executionPrice,
            order.triggerPrice,
            order.maxSlippage
        );

//        bytes32 positionKey = positionManager.getPositionKey(order.account, order.pairIndex, order.isLong);
//        require(!positionManager.needLiquidation(positionKey, executionPrice), "need liquidation");

        // compare openPrice and oraclePrice
        if (order.tradeType == TradingTypes.TradeType.LIMIT) {
            if (!order.isLong) {
                executionPrice = Math.min(order.triggerPrice, executionPrice);
            } else {
                executionPrice = Math.max(order.triggerPrice, executionPrice);
            }
        }

        // check position and leverage
        position.validLeverage(
            pair,
            executionPrice,
            order.collateral,
            executionSize,
            false,
            tradingConfig.maxLeverage,
            tradingConfig.maxPositionAmount,
            isSystem,
            positionManager.getFundingFee(order.account, order.pairIndex, order.isLong)
        );

        (bool _needADL, ) = positionManager.needADL(
            order.pairIndex,
            order.isLong,
            executionSize,
            executionPrice
        );
        if (_needADL) {
            orderManager.setOrderNeedADL(_orderId, order.tradeType, _needADL);

            emit ExecuteDecreaseOrder(
                order.account,
                _orderId,
                pairIndex,
                order.tradeType,
                order.isLong,
                order.collateral,
                order.sizeAmount,
                order.triggerPrice,
                executionSize,
                executionPrice,
                order.executedSize,
                _needADL,
                0,
                0,
                0,
                TradingTypes.InnerPaymentType.NONE,
                0
            );
            return;
        }

        int256 collateral;
        if (order.collateral > 0) {
            collateral = order.executedSize == 0 || onlyOnce ? order.collateral : int256(0);
        } else {
            collateral = order.executedSize + executionSize >= order.sizeAmount || onlyOnce
                ? order.collateral
                : int256(0);
        }

        (uint256 tradingFee, int256 fundingFee, int256 pnl) = positionManager.decreasePosition(
            pairIndex,
            order.orderId,
            order.account,
            keeper,
            executionSize,
            order.isLong,
            collateral,
            feeCollector.getTradingFeeTier(pairIndex, tier),
            referralsRatio,
            referralUserRatio,
            referralOwner,
            executionPrice,
            false
        );

        // add executed size
        order.executedSize += executionSize;
        orderManager.increaseOrderExecutedSize(
            order.orderId,
            order.tradeType,
            false,
            executionSize
        );

        position = positionManager.getPosition(order.account, order.pairIndex, order.isLong);
        // remove order
        if (onlyOnce || order.executedSize >= order.sizeAmount || position.positionAmount == 0) {
            // remove decrease order
            orderManager.removeOrderFromPosition(
                IOrderManager.PositionOrder(
                    order.account,
                    order.pairIndex,
                    order.isLong,
                    false,
                    order.tradeType,
                    order.orderId,
                    executionSize
                )
            );

            // delete order
            if (order.tradeType == TradingTypes.TradeType.MARKET) {
                orderManager.removeDecreaseMarketOrders(_orderId);
            } else if (order.tradeType == TradingTypes.TradeType.LIMIT) {
                orderManager.removeDecreaseLimitOrders(_orderId);
            } else {
                orderManager.removeDecreaseLimitOrders(_orderId);
            }

            feeCollector.distributeNetworkFee(keeper, orderNetworkFee.paymentType, orderNetworkFee.networkFeeAmount);
        }

        if (position.positionAmount == 0) {
            // cancel all decrease order
            IOrderManager.PositionOrder[] memory orders = orderManager.getPositionOrders(
                PositionKey.getPositionKey(order.account, order.pairIndex, order.isLong)
            );

            for (uint256 i = 0; i < orders.length; i++) {
                IOrderManager.PositionOrder memory positionOrder = orders[i];
                orderManager.cancelOrder(
                    positionOrder.orderId,
                    positionOrder.tradeType,
                    positionOrder.isIncrease,
                    "closed position"
                );
            }
        }

        emit ExecuteDecreaseOrder(
            order.account,
            _orderId,
            pairIndex,
            order.tradeType,
            order.isLong,
            collateral,
            order.sizeAmount,
            order.triggerPrice,
            executionSize,
            executionPrice,
            order.executedSize,
            _needADL,
            pnl,
            tradingFee,
            fundingFee,
            orderNetworkFee.paymentType,
            orderNetworkFee.networkFeeAmount
        );
    }

    function executeADLAndDecreaseOrders(
        address keeper,
        uint256 pairIndex,
        ExecutePosition[] memory executePositions,
        IExecutionLogic.ExecuteOrder[] memory executeOrders
    ) external override onlyExecutorOrSelf {
        uint256 longOrderSize;
        uint256 shortOrderSize;
        for (uint256 i = 0; i < executeOrders.length; i++) {
            IExecutionLogic.ExecuteOrder memory executeOrder = executeOrders[i];
            (TradingTypes.DecreasePositionOrder memory order,) = orderManager.getDecreaseOrder(
                executeOrder.orderId,
                executeOrder.tradeType
            );
            require(order.pairIndex == pairIndex, "mismatch pairIndex");
            if (order.isLong) {
                longOrderSize += order.sizeAmount - order.executedSize;
            } else {
                shortOrderSize += order.sizeAmount - order.executedSize;
            }
        }

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);
        IPool.Pair memory pair = pool.getPair(pairIndex);
        // execution price
        uint256 executionPrice = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );

        uint256 totalNeedADLAmount;
        if (longOrderSize > shortOrderSize) {
            (, totalNeedADLAmount) = positionManager.needADL(pairIndex, true, longOrderSize - shortOrderSize, executionPrice);
        } else if (longOrderSize < shortOrderSize) {
            (, totalNeedADLAmount) = positionManager.needADL(pairIndex, false, shortOrderSize - longOrderSize, executionPrice);
        }

        uint256[] memory adlOrderIds = new uint256[](executePositions.length);
        bytes32[] memory adlPositionKeys = new bytes32[](executePositions.length);
        if (totalNeedADLAmount > 0) {
            uint256 executeTotalAmount;
            ExecutePositionInfo[] memory adlPositions = new ExecutePositionInfo[](executePositions.length);
            for (uint256 i = 0; i < executePositions.length; i++) {
                if (executeTotalAmount == totalNeedADLAmount) {
                    break;
                }
                ExecutePosition memory executePosition = executePositions[i];
                Position.Info memory position = positionManager.getPositionByKey(executePosition.positionKey);
                require(position.pairIndex == pairIndex, "mismatch pairIndex");

                uint256 adlExecutionSize;
                if (position.positionAmount >= totalNeedADLAmount - executeTotalAmount) {
                    adlExecutionSize = totalNeedADLAmount - executeTotalAmount;
                } else {
                    adlExecutionSize = position.positionAmount;
                }
                if (adlExecutionSize > 0) {
                    executeTotalAmount += adlExecutionSize;

                    ExecutePositionInfo memory adlPosition = adlPositions[i];
                    adlPosition.position = position;
                    adlPosition.executionSize = adlExecutionSize;
                    adlPosition.tier = executePosition.tier;
                    adlPosition.referralsRatio = executePosition.referralsRatio;
                    adlPosition.referralUserRatio = executePosition.referralUserRatio;
                    adlPosition.referralOwner = executePosition.referralOwner;
                }
            }

            for (uint256 i = 0; i < adlPositions.length; i++) {
                ExecutePositionInfo memory adlPosition = adlPositions[i];
                if (adlPosition.executionSize > 0) {
                    uint256 orderId = orderManager.createOrder(
                        TradingTypes.CreateOrderRequest({
                            account: adlPosition.position.account,
                            pairIndex: adlPosition.position.pairIndex,
                            tradeType: TradingTypes.TradeType.MARKET,
                            collateral: 0,
                            openPrice: executionPrice,
                            isLong: adlPosition.position.isLong,
                            sizeAmount: -(adlPosition.executionSize.safeConvertToInt256()),
                            maxSlippage: 0,
                            paymentType: TradingTypes.InnerPaymentType.NONE,
                            networkFeeAmount: 0,
                            data: abi.encode(adlPosition.position.account)
                        })
                    );
                    this.executeDecreaseOrder(
                        keeper,
                        orderId,
                        TradingTypes.TradeType.MARKET,
                        adlPosition.tier,
                        adlPosition.referralsRatio,
                        adlPosition.referralUserRatio,
                        adlPosition.referralOwner,
                        true,
                        0,
                        true
                    );
                    adlOrderIds[i] = orderId;
                    adlPositionKeys[i] = PositionKey.getPositionKey(
                        adlPosition.position.account,
                        adlPosition.position.pairIndex,
                        adlPosition.position.isLong
                    );
                }
            }
        }

        uint256[] memory orders = new uint256[](executeOrders.length);
        for (uint256 i = 0; i < executeOrders.length; i++) {
            IExecutionLogic.ExecuteOrder memory executeOrder = executeOrders[i];

            (TradingTypes.DecreasePositionOrder memory order,) = orderManager.getDecreaseOrder(
                executeOrder.orderId,
                executeOrder.tradeType
            );

            // execution size
            uint256 executionSize = order.sizeAmount - order.executedSize;

            if (order.tradeType == TradingTypes.TradeType.LIMIT) {
                if (!order.isLong) {
                    executionPrice = Math.min(order.triggerPrice, executionPrice);
                } else {
                    executionPrice = Math.max(order.triggerPrice, executionPrice);
                }
            }

            orders[i] = executeOrder.orderId;

            (bool _needADL, uint256 needADLAmount) = positionManager.needADL(
                order.pairIndex,
                order.isLong,
                executionSize,
                executionPrice
            );
            if (!_needADL && !order.needADL) {
                this.executeDecreaseOrder(
                    keeper,
                    order.orderId,
                    order.tradeType,
                    executeOrder.tier,
                    executeOrder.referralsRatio,
                    executeOrder.referralUserRatio,
                    executeOrder.referralOwner,
                    false,
                    0,
                    executeOrder.tradeType == TradingTypes.TradeType.MARKET
                );
            } else {
                this.executeDecreaseOrder(
                    keeper,
                    order.orderId,
                    order.tradeType,
                    executeOrder.tier,
                    executeOrder.referralsRatio,
                    executeOrder.referralUserRatio,
                    executeOrder.referralOwner,
                    true,
                    executionSize - needADLAmount,
                    false
                );
            }
        }

        emit ExecuteAdlOrder(adlOrderIds, adlPositionKeys, orders);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../../libraries/Position.sol';
import '../../interfaces/ILiquidationLogic.sol';
import '../../interfaces/IAddressesProvider.sol';
import '../../interfaces/IRoleManager.sol';
import '../../interfaces/IOrderManager.sol';
import '../../interfaces/IPositionManager.sol';
import '../../interfaces/IPool.sol';
import '../../helpers/TradingHelper.sol';
import '../../interfaces/IFeeCollector.sol';

contract LiquidationLogic is ILiquidationLogic {
    using PrecisionUtils for uint256;
    using Math for uint256;
    using Int256Utils for int256;
    using Int256Utils for uint256;
    using Position for Position.Info;

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    IPool public immutable pool;
    IOrderManager public immutable orderManager;
    IPositionManager public immutable positionManager;
    IFeeCollector public immutable feeCollector;
    address public executor;

    constructor(
        IAddressesProvider addressProvider,
        IPool _pool,
        IOrderManager _orderManager,
        IPositionManager _positionManager,
        IFeeCollector _feeCollector
    ) {
        ADDRESS_PROVIDER = addressProvider;
        pool = _pool;
        orderManager = _orderManager;
        positionManager = _positionManager;
        feeCollector = _feeCollector;
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutorOrSelf() {
        require(msg.sender == executor || msg.sender == address(this), "oe");
        _;
    }

    function updateExecutor(address _executor) external override onlyPoolAdmin {
        address oldAddress = executor;
        executor = _executor;
        emit UpdateExecutorAddress(msg.sender, oldAddress, _executor);
    }

    function liquidationPosition(
        address keeper,
        bytes32 positionKey,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external override onlyExecutorOrSelf {
        Position.Info memory position = positionManager.getPositionByKey(positionKey);
        if (position.positionAmount == 0) {
            emit ZeroPosition(keeper, position.account, position.pairIndex, position.isLong, 'liquidation');
            return;
        }
        IPool.Pair memory pair = pool.getPair(position.pairIndex);
        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(position.pairIndex);

        uint256 price = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );

        bool needLiquidate = positionManager.needLiquidation(positionKey, price);
        if (!needLiquidate) {
            return;
        }

        uint256 orderId = orderManager.createOrder(
            TradingTypes.CreateOrderRequest({
                account: position.account,
                pairIndex: position.pairIndex,
                tradeType: TradingTypes.TradeType.MARKET,
                collateral: 0,
                openPrice: price,
                isLong: position.isLong,
                sizeAmount: -(position.positionAmount.safeConvertToInt256()),
                maxSlippage: 0,
                paymentType: TradingTypes.InnerPaymentType.NONE,
                networkFeeAmount: 0,
                data: abi.encode(position.account)
            })
        );

        _executeLiquidationOrder(keeper, orderId, tier, referralsRatio, referralUserRatio, referralOwner);

        emit ExecuteLiquidation(
            positionKey,
            position.account,
            position.pairIndex,
            position.isLong,
            position.collateral,
            position.positionAmount,
            price,
            orderId
        );
    }

    function _executeLiquidationOrder(
        address keeper,
        uint256 orderId,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) private {
        TradingTypes.OrderNetworkFee memory orderNetworkFee;
        TradingTypes.DecreasePositionOrder memory order;
        (order, orderNetworkFee) = orderManager.getDecreaseOrder(orderId, TradingTypes.TradeType.MARKET);
        if (order.account == address(0)) {
            emit InvalidOrder(keeper, orderId, 'zero account');
            return;
        }

        uint256 pairIndex = order.pairIndex;
        IPool.Pair memory pair = pool.getPair(pairIndex);

        Position.Info memory position = positionManager.getPosition(
            order.account,
            pairIndex,
            order.isLong
        );
        if (position.positionAmount == 0) {
            emit ZeroPosition(keeper, position.account, pairIndex, position.isLong, 'liquidation');
            return;
        }

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);

        uint256 executionSize = order.sizeAmount - order.executedSize;
        executionSize = Math.min(executionSize, position.positionAmount);

        uint256 executionPrice = TradingHelper.getValidPrice(
            ADDRESS_PROVIDER,
            pair.indexToken,
            tradingConfig
        );

        (bool needADL, ) = positionManager.needADL(
            pairIndex,
            order.isLong,
            executionSize,
            executionPrice
        );
        if (needADL) {
            orderManager.setOrderNeedADL(orderId, order.tradeType, needADL);

            emit ExecuteDecreaseOrder(
                order.account,
                orderId,
                pairIndex,
                order.tradeType,
                order.isLong,
                order.collateral,
                order.sizeAmount,
                order.triggerPrice,
                executionSize,
                executionPrice,
                order.executedSize,
                needADL,
                0,
                0,
                0,
                TradingTypes.InnerPaymentType.NONE,
                0
            );
            return;
        }

        (uint256 tradingFee, int256 fundingFee, int256 pnl) = positionManager.decreasePosition(
            pairIndex,
            order.orderId,
            order.account,
            keeper,
            executionSize,
            order.isLong,
            0,
            feeCollector.getTradingFeeTier(pairIndex, tier),
            referralsRatio,
            referralUserRatio,
            referralOwner,
            executionPrice,
            true
        );

        // add executed size
        order.executedSize += executionSize;

        // remove order
        orderManager.removeDecreaseMarketOrders(orderId);

        emit ExecuteDecreaseOrder(
            order.account,
            orderId,
            pairIndex,
            order.tradeType,
            order.isLong,
            0,
            order.sizeAmount,
            order.triggerPrice,
            executionSize,
            executionPrice,
            order.executedSize,
            needADL,
            pnl,
            tradingFee,
            fundingFee,
            orderNetworkFee.paymentType,
            orderNetworkFee.networkFeeAmount
        );
    }

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external override onlyExecutorOrSelf {
        for (uint256 i = 0; i < positionKeys.length; i++) {
            Position.Info memory position = positionManager.getPositionByKey(positionKeys[i]);
            if (position.positionAmount == 0) {
                orderManager.cancelAllPositionOrders(position.account, position.pairIndex, position.isLong);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/PrecisionUtils.sol";
import "../libraries/PositionKey.sol";
import "../libraries/Int256Utils.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/TradingTypes.sol";

import "../helpers/ValidationHelper.sol";

import "../interfaces/IPriceFeed.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IOrderManager.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IOrderCallback.sol";

contract OrderManager is IOrderManager, Upgradeable {
    using SafeERC20 for IERC20;
    using PrecisionUtils for uint256;
    using Math for uint256;
    using SafeMath for uint256;
    using Int256Utils for int256;
    using Int256Utils for uint256;
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    uint256 public override ordersIndex;

    mapping(uint256 => TradingTypes.IncreasePositionOrder) public increaseMarketOrders;
    mapping(uint256 => TradingTypes.DecreasePositionOrder) public decreaseMarketOrders;
    mapping(uint256 => TradingTypes.IncreasePositionOrder) public increaseLimitOrders;
    mapping(uint256 => TradingTypes.DecreasePositionOrder) public decreaseLimitOrders;
    mapping(uint256 => TradingTypes.OrderNetworkFee) public orderNetworkFees;

    // positionKey
    mapping(bytes32 => PositionOrder[]) public positionOrders;
    mapping(bytes32 => mapping(uint256 => uint256)) public positionOrderIndex;

    mapping(TradingTypes.NetworkFeePaymentType => mapping(uint256 => NetworkFee)) public networkFees;

    IPool public pool;
    IPositionManager public positionManager;
    address public router;

    function initialize(
        IAddressesProvider addressProvider,
        IPool _pool,
        IPositionManager _positionManager
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
        pool = _pool;
        positionManager = _positionManager;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "onlyRouter");
        _;
    }

    modifier onlyExecutor() {
        require(
            msg.sender == ADDRESS_PROVIDER.executionLogic() ||
                msg.sender == ADDRESS_PROVIDER.liquidationLogic(),
            "onlyExecutor"
        );
        _;
    }

    modifier onlyExecutorAndRouter() {
        require(
            msg.sender == router ||
            msg.sender == ADDRESS_PROVIDER.executionLogic() ||
            msg.sender == ADDRESS_PROVIDER.liquidationLogic(),
            "onlyExecutor&Router"
        );
        _;
    }

    function setRouter(address _router) external onlyPoolAdmin {
        address oldAddress = router;
        router = _router;
        emit UpdateRouterAddress(msg.sender, oldAddress, _router);
    }

    function updateNetworkFees(
        TradingTypes.NetworkFeePaymentType[] memory paymentTypes,
        uint256[] memory pairIndexes,
        NetworkFee[] memory fees
    ) external onlyPoolAdmin {
        require(paymentTypes.length == pairIndexes.length && pairIndexes.length == fees.length, "inconsistent params length");

        for (uint256 i = 0; i < fees.length; i++) {
            _updateNetworkFee(paymentTypes[i], pairIndexes[i], fees[i]);
        }
    }

    function _updateNetworkFee(
        TradingTypes.NetworkFeePaymentType paymentType,
        uint256 pairIndex,
        NetworkFee memory fee
    ) internal {
        networkFees[paymentType][pairIndex] = fee;
        emit UpdatedNetworkFee(msg.sender, paymentType, pairIndex, fee.basicNetworkFee, fee.discountThreshold, fee.discountedNetworkFee);
    }

    function getNetworkFee(TradingTypes.NetworkFeePaymentType paymentType, uint256 pairIndex) external view override returns (NetworkFee memory) {
        return networkFees[paymentType][pairIndex];
    }

    function createOrder(
        TradingTypes.CreateOrderRequest calldata request
    ) public payable onlyExecutorAndRouter returns (uint256 orderId) {
        address account = request.account;

        // account is frozen
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, account);

        // pair enabled
        IPool.Pair memory pair = pool.getPair(request.pairIndex);
        require(pair.enable, "disabled");

        // network fees
        int256 collateral = request.collateral;
        if (request.paymentType == TradingTypes.InnerPaymentType.ETH) {
            NetworkFee memory networkFee = networkFees[TradingTypes.NetworkFeePaymentType.ETH][request.pairIndex];
            if (networkFee.basicNetworkFee > 0) {
                if ((request.sizeAmount.abs() >= networkFee.discountThreshold && msg.value < networkFee.discountedNetworkFee)
                    || (request.sizeAmount.abs() < networkFee.discountThreshold && msg.value < networkFee.basicNetworkFee)) {
                    revert("insufficient network fee");
                }
                (bool success, ) = address(pool).call{value: msg.value}(new bytes(0));
                require(success, "transfer eth failed");
            }
        } else if (request.paymentType == TradingTypes.InnerPaymentType.COLLATERAL) {
            NetworkFee memory networkFee = networkFees[TradingTypes.NetworkFeePaymentType.COLLATERAL][request.pairIndex];
            if (networkFee.basicNetworkFee > 0) {
                if ((request.sizeAmount.abs() >= networkFee.discountThreshold && request.networkFeeAmount < networkFee.discountedNetworkFee)
                    || (request.sizeAmount.abs() < networkFee.discountThreshold && request.networkFeeAmount < networkFee.basicNetworkFee)) {
                    revert("insufficient network fee");
                }
                _transferOrderCollateral(
                    pair.stableToken,
                    request.networkFeeAmount,
                    address(pool),
                    request.data
                );
            }
        }

        if (
            request.tradeType == TradingTypes.TradeType.MARKET ||
            request.tradeType == TradingTypes.TradeType.LIMIT
        ) {
            IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(request.pairIndex);
            if (request.sizeAmount >= 0) {
                require(
                    request.sizeAmount == 0 ||
                        (request.sizeAmount.abs() >= tradingConfig.minTradeAmount &&
                            request.sizeAmount.abs() <= tradingConfig.maxTradeAmount),
                    "invalid trade size"
                );
            }
        }

        // transfer collateral
        if (collateral > 0) {
            _transferOrderCollateral(
                pair.stableToken,
                collateral.abs(),
                address(pool),
                request.data
            );
        }

        if (request.sizeAmount > 0) {
            return
                _saveIncreaseOrder(
                    TradingTypes.IncreasePositionRequest({
                        account: account,
                        pairIndex: request.pairIndex,
                        tradeType: request.tradeType,
                        collateral: collateral,
                        openPrice: request.openPrice,
                        isLong: request.isLong,
                        sizeAmount: request.sizeAmount.abs(),
                        maxSlippage: request.maxSlippage,
                        paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                        networkFeeAmount: request.networkFeeAmount
                    }),
                    request.paymentType
                );
        } else if (request.sizeAmount < 0) {
            return
                _saveDecreaseOrder(
                    TradingTypes.DecreasePositionRequest({
                        account: account,
                        pairIndex: request.pairIndex,
                        tradeType: request.tradeType,
                        collateral: collateral,
                        triggerPrice: request.openPrice,
                        sizeAmount: request.sizeAmount.abs(),
                        isLong: request.isLong,
                        maxSlippage: request.maxSlippage,
                        paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                        networkFeeAmount: request.networkFeeAmount
                    }),
                    request.paymentType
                );
        } else {
            require(collateral != 0, "collateral required");
            return
                _saveIncreaseOrder(
                    TradingTypes.IncreasePositionRequest({
                        account: account,
                        pairIndex: request.pairIndex,
                        tradeType: request.tradeType,
                        collateral: collateral,
                        openPrice: request.openPrice,
                        isLong: request.isLong,
                        sizeAmount: 0,
                        maxSlippage: request.maxSlippage,
                        paymentType: TradingTypes.NetworkFeePaymentType.ETH,
                        networkFeeAmount: request.networkFeeAmount
                    }),
                    request.paymentType
                );
        }
    }

    function cancelOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        string memory reason
    ) external onlyExecutorAndRouter {
        _cancelOrder(orderId, tradeType, isIncrease, reason);
    }

    function _cancelOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        string memory reason
    ) private {
        if (isIncrease) {
            (TradingTypes.IncreasePositionOrder memory order,) = getIncreaseOrder(orderId, tradeType);
            if (order.account == address(0)) {
                return;
            }
            _cancelIncreaseOrder(order);
        } else {
            (TradingTypes.DecreasePositionOrder memory order,) = getDecreaseOrder(orderId, tradeType);
            if (order.account == address(0)) {
                return;
            }
            _cancelDecreaseOrder(order);
        }
        emit CancelOrder(orderId, tradeType, reason);
    }

    function cancelAllPositionOrders(
        address account,
        uint256 pairIndex,
        bool isLong
    ) external onlyExecutor {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, account);

        bytes32 key = PositionKey.getPositionKey(account, pairIndex, isLong);

        uint256 total = positionOrders[key].length;
        uint256 count = total > 256 ? 256 : total;

        for (uint256 i = 1; i <= count; i++) {
            PositionOrder memory positionOrder = positionOrders[key][count - i];
            _cancelOrder(
                positionOrder.orderId,
                positionOrder.tradeType,
                positionOrder.isIncrease,
                "cancelAllPositionOrders"
            );
        }
    }

    function increaseOrderExecutedSize(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        uint256 increaseSize
    ) external override onlyExecutor {
        if (isIncrease) {
            if (tradeType == TradingTypes.TradeType.MARKET) {
                increaseMarketOrders[orderId].executedSize += increaseSize;
            } else if (tradeType == TradingTypes.TradeType.LIMIT) {
                increaseLimitOrders[orderId].executedSize += increaseSize;
            }
        } else {
            if (tradeType == TradingTypes.TradeType.MARKET) {
                decreaseMarketOrders[orderId].executedSize += increaseSize;
            } else {
                decreaseLimitOrders[orderId].executedSize += increaseSize;
            }
        }
    }

    function removeOrderFromPosition(PositionOrder memory order) public onlyExecutor {
        _removeOrderFromPosition(order);
    }

    function removeIncreaseMarketOrders(uint256 orderId) external onlyExecutor {
        delete increaseMarketOrders[orderId];
        delete orderNetworkFees[orderId];
    }

    function removeIncreaseLimitOrders(uint256 orderId) external onlyExecutor {
        delete increaseLimitOrders[orderId];
        delete orderNetworkFees[orderId];
    }

    function removeDecreaseMarketOrders(uint256 orderId) external onlyExecutor {
        delete decreaseMarketOrders[orderId];
        delete orderNetworkFees[orderId];
    }

    function removeDecreaseLimitOrders(uint256 orderId) external onlyExecutor {
        delete decreaseLimitOrders[orderId];
        delete orderNetworkFees[orderId];
    }

    function setOrderNeedADL(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool needADL
    ) external onlyExecutor {
        TradingTypes.DecreasePositionOrder storage order;
        if (tradeType == TradingTypes.TradeType.MARKET) {
            order = decreaseMarketOrders[orderId];
        } else {
            order = decreaseLimitOrders[orderId];
            require(order.tradeType == tradeType, "trade type not match");
        }
        order.needADL = needADL;
    }

    function _transferOrderCollateral(
        address collateral,
        uint256 collateralAmount,
        address to,
        bytes calldata data
    ) internal {
        uint256 balanceBefore = IERC20(collateral).balanceOf(to);

        if (collateralAmount > 0) {
            IOrderCallback(msg.sender).createOrderCallback(collateral, collateralAmount, to, data);
        }
        require(balanceBefore.add(collateralAmount) <= IERC20(collateral).balanceOf(to), "tc");
    }

    function _saveIncreaseOrder(
        TradingTypes.IncreasePositionRequest memory _request,
        TradingTypes.InnerPaymentType paymentType
    ) internal returns (uint256) {
        TradingTypes.IncreasePositionOrder memory order = TradingTypes.IncreasePositionOrder({
            orderId: ordersIndex,
            account: _request.account,
            pairIndex: _request.pairIndex,
            tradeType: _request.tradeType,
            collateral: _request.collateral,
            openPrice: _request.openPrice,
            isLong: _request.isLong,
            sizeAmount: _request.sizeAmount,
            executedSize: 0,
            maxSlippage: _request.maxSlippage,
            blockTime: block.timestamp
        });

        TradingTypes.OrderNetworkFee memory orderNetworkFee = TradingTypes.OrderNetworkFee({
            paymentType: paymentType,
            networkFeeAmount: _request.networkFeeAmount
        });
        orderNetworkFees[ordersIndex] = orderNetworkFee;

        if (_request.tradeType == TradingTypes.TradeType.MARKET) {
            increaseMarketOrders[ordersIndex] = order;
        } else if (_request.tradeType == TradingTypes.TradeType.LIMIT) {
            increaseLimitOrders[ordersIndex] = order;
        } else {
            revert("invalid trade type");
        }
        ordersIndex++;

        _addOrderToPosition(
            PositionOrder(
                order.account,
                order.pairIndex,
                order.isLong,
                true,
                order.tradeType,
                order.orderId,
                order.sizeAmount
            )
        );

        emit CreateIncreaseOrder(
            order.account,
            order.orderId,
            _request.pairIndex,
            _request.tradeType,
            _request.collateral,
            _request.openPrice,
            _request.isLong,
            _request.sizeAmount,
            paymentType,
            _request.networkFeeAmount
        );
        return order.orderId;
    }

    function _saveDecreaseOrder(
        TradingTypes.DecreasePositionRequest memory _request,
        TradingTypes.InnerPaymentType paymentType
    ) internal returns (uint256) {
        TradingTypes.DecreasePositionOrder memory order = TradingTypes.DecreasePositionOrder({
            orderId: ordersIndex, // orderId
            account: _request.account,
            pairIndex: _request.pairIndex,
            tradeType: _request.tradeType,
            collateral: _request.collateral,
            triggerPrice: _request.triggerPrice,
            sizeAmount: _request.sizeAmount,
            executedSize: 0,
            maxSlippage: _request.maxSlippage,
            isLong: _request.isLong,
            abovePrice: false, // abovePrice
            blockTime: block.timestamp,
            needADL: false
        });

        TradingTypes.OrderNetworkFee memory orderNetworkFee = TradingTypes.OrderNetworkFee({
            paymentType: paymentType,
            networkFeeAmount: _request.networkFeeAmount
        });
        orderNetworkFees[ordersIndex] = orderNetworkFee;

        // abovePrice
        // market：long: true,  short: false
        //  limit：long: false, short: true
        //     tp：long: false, short: true
        //     sl：long: true,  short: false
        if (_request.tradeType == TradingTypes.TradeType.MARKET) {
            order.abovePrice = _request.isLong;

            decreaseMarketOrders[ordersIndex] = order;
        } else if (_request.tradeType == TradingTypes.TradeType.LIMIT) {
            order.abovePrice = !_request.isLong;

            decreaseLimitOrders[ordersIndex] = order;
        } else if (_request.tradeType == TradingTypes.TradeType.TP) {
            order.abovePrice = !_request.isLong;

            decreaseLimitOrders[ordersIndex] = order;
        } else if (_request.tradeType == TradingTypes.TradeType.SL) {
            order.abovePrice = _request.isLong;

            decreaseLimitOrders[ordersIndex] = order;
        } else {
            revert("invalid trade type");
        }
        ordersIndex++;

        // add decrease order
        _addOrderToPosition(
            PositionOrder(
                order.account,
                order.pairIndex,
                order.isLong,
                false,
                order.tradeType,
                order.orderId,
                order.sizeAmount
            )
        );

        emit CreateDecreaseOrder(
            order.account,
            order.orderId,
            _request.tradeType,
            _request.collateral,
            _request.pairIndex,
            _request.triggerPrice,
            _request.sizeAmount,
            _request.isLong,
            order.abovePrice,
            paymentType,
            _request.networkFeeAmount
        );
        return order.orderId;
    }

    function _cancelIncreaseOrder(TradingTypes.IncreasePositionOrder memory order) internal {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, order.account);

        _removeOrderAndRefundCollateral(
            order.account,
            order.pairIndex,
            order.executedSize == 0 ? order.collateral : int256(0),
            PositionOrder({
                account: order.account,
                pairIndex: order.pairIndex,
                isLong: order.isLong,
                isIncrease: true,
                tradeType: order.tradeType,
                orderId: order.orderId,
                sizeAmount: order.sizeAmount
            })
        );

        if (order.tradeType == TradingTypes.TradeType.MARKET) {
            delete increaseMarketOrders[order.orderId];
        } else if (order.tradeType == TradingTypes.TradeType.LIMIT) {
            delete increaseLimitOrders[order.orderId];
        }

        emit CancelIncreaseOrder(order.account, order.orderId, order.tradeType);
    }

    function _cancelDecreaseOrder(TradingTypes.DecreasePositionOrder memory order) internal {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, order.account);

        _removeOrderAndRefundCollateral(
            order.account,
            order.pairIndex,
            order.executedSize == 0 ? order.collateral : int256(0),
            PositionOrder({
                account: order.account,
                pairIndex: order.pairIndex,
                isLong: order.isLong,
                isIncrease: false,
                tradeType: order.tradeType,
                orderId: order.orderId,
                sizeAmount: order.sizeAmount
            })
        );

        if (order.tradeType == TradingTypes.TradeType.MARKET) {
            delete decreaseMarketOrders[order.orderId];
        } else if (order.tradeType == TradingTypes.TradeType.LIMIT) {
            delete decreaseLimitOrders[order.orderId];
        } else {
            delete decreaseLimitOrders[order.orderId];
        }

        emit CancelDecreaseOrder(order.account, order.orderId, order.tradeType);
    }

    function _removeOrderAndRefundCollateral(
        address account,
        uint256 pairIndex,
        int256 collateral,
        PositionOrder memory positionOrder
    ) internal {
        _removeOrderFromPosition(positionOrder);

        if (collateral > 0) {
            IPool.Pair memory pair = pool.getPair(pairIndex);
            pool.transferTokenOrSwap(pairIndex, pair.stableToken, account, collateral.abs());
        }
    }

    function _addOrderToPosition(PositionOrder memory order) private {
        bytes32 positionKey = PositionKey.getPositionKey(
            order.account,
            order.pairIndex,
            order.isLong
        );
        positionOrderIndex[positionKey][order.orderId] = positionOrders[positionKey].length;
        positionOrders[positionKey].push(order);
    }

    function _removeOrderFromPosition(PositionOrder memory order) private {
        bytes32 positionKey = PositionKey.getPositionKey(
            order.account,
            order.pairIndex,
            order.isLong
        );

        uint256 index = positionOrderIndex[positionKey][order.orderId];
        uint256 lastIndex = positionOrders[positionKey].length - 1;

        if (index < lastIndex) {
            // swap last order
            PositionOrder memory lastOrder = positionOrders[positionKey][
                positionOrders[positionKey].length - 1
            ];

            positionOrders[positionKey][index] = lastOrder;
            positionOrderIndex[positionKey][lastOrder.orderId] = index;
        }
        delete positionOrderIndex[positionKey][order.orderId];
        positionOrders[positionKey].pop();
    }

    function getIncreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) public view returns (
        TradingTypes.IncreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    ) {
        if (tradeType == TradingTypes.TradeType.MARKET) {
            order = increaseMarketOrders[orderId];
        } else if (tradeType == TradingTypes.TradeType.LIMIT) {
            order = increaseLimitOrders[orderId];
        } else {
            revert("invalid trade type");
        }
        orderNetworkFee = orderNetworkFees[order.orderId];
    }

    function getDecreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) public view returns (
        TradingTypes.DecreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    ) {
        if (tradeType == TradingTypes.TradeType.MARKET) {
            order = decreaseMarketOrders[orderId];
        } else {
            order = decreaseLimitOrders[orderId];
        }
        orderNetworkFee = orderNetworkFees[order.orderId];
    }

    function getPositionOrders(bytes32 key) public view override returns (PositionOrder[] memory) {
        return positionOrders[key];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {PositionStatus, IPositionManager} from "../interfaces/IPositionManager.sol";
import "../libraries/Position.sol";
import "../libraries/PositionKey.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/Int256Utils.sol";
import "../interfaces/IFundingRate.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IRiskReserve.sol";
import "../interfaces/IFeeCollector.sol";
import "../libraries/Upgradeable.sol";
import "../helpers/TokenHelper.sol";
import "../helpers/TradingHelper.sol";

contract PositionManager is IPositionManager, Upgradeable {
    using SafeERC20 for IERC20;
    using PrecisionUtils for uint256;
    using Math for uint256;
    using SafeMath for uint256;
    using Int256Utils for int256;
    using Int256Utils for uint256;
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    mapping(bytes32 => Position.Info) public positions;

    mapping(uint256 => uint256) public override longTracker;
    mapping(uint256 => uint256) public override shortTracker;

    // gobleFundingRateIndex tracks the funding rates based on utilization
    mapping(uint256 => int256) public globalFundingFeeTracker;

    mapping(uint256 => int256) public currentFundingRate;

    // lastFundingRateUpdateTimes tracks the last time funding was updated for a token
    mapping(uint256 => uint256) public lastFundingRateUpdateTimes;

    IRiskReserve public riskReserve;
    IPool public pool;
    IFeeCollector public feeCollector;
    address public pledgeAddress;
    address public router;

    function initialize(
        IAddressesProvider addressProvider,
        IPool _pool,
        address _pledgeAddress,
        IFeeCollector _feeCollector,
        IRiskReserve _riskReserve
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
        pledgeAddress = _pledgeAddress;
        pool = _pool;
        feeCollector = _feeCollector;
        riskReserve = _riskReserve;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "onlyRouter");
        _;
    }

    modifier onlyExecutor() {
        require(
            msg.sender == ADDRESS_PROVIDER.executionLogic() ||
                msg.sender == ADDRESS_PROVIDER.liquidationLogic(),
            "onlyExecutor"
        );
        _;
    }

    function setRouter(address _router) external onlyPoolAdmin {
        address oldAddress = router;
        router = _router;
        emit UpdateRouterAddress(msg.sender, oldAddress, _router);
    }

    function increasePosition(
        uint256 pairIndex,
        uint256 orderId,
        address account,
        address keeper,
        uint256 sizeAmount,
        bool isLong,
        int256 collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 oraclePrice
    ) external onlyExecutor returns (uint256 tradingFee, int256 fundingFee) {
        IPool.Pair memory pair = pool.getPair(pairIndex);
        require(pair.stableToken == pledgeAddress, "!pledge");
        bytes32 positionKey = PositionKey.getPositionKey(account, pairIndex, isLong);
        Position.Info storage position = positions[positionKey];

        uint256 beforeCollateral = position.collateral;
        uint256 beforePositionAmount = position.positionAmount;
        uint256 sizeDelta = sizeAmount.mulPrice(oraclePrice);

        if (position.positionAmount == 0) {
            position.init(pairIndex, account, isLong, oraclePrice);
        }

        if (position.positionAmount > 0 && sizeDelta > 0) {
            position.averagePrice = (position.positionAmount.mulPrice(position.averagePrice) +
                sizeDelta).mulDiv(
                    PrecisionUtils.pricePrecision(),
                    (position.positionAmount + sizeAmount)
                );
        }

        // update funding fee
        _updateFundingRate(pairIndex, oraclePrice);
        _handleCollateral(pairIndex, position, collateral);

        // settlement trading fee and funding fee
        int256 charge;
        (charge, tradingFee, fundingFee) = _takeFundingFeeAddTraderFee(
            pairIndex,
            account,
            keeper,
            orderId,
            sizeAmount,
            true,
            isLong,
            tradingFeeTier,
            referralsRatio,
            referralUserRatio,
            referralOwner,
            oraclePrice
        );

        if (charge >= 0) {
            position.collateral = position.collateral.add(charge.abs());
        } else {
            if (position.collateral >= charge.abs()) {
                position.collateral = position.collateral.sub(charge.abs());
            } else {
                // adjust position averagePrice
                uint256 lossPer = charge.abs().divPrice(position.positionAmount);
                position.isLong
                    ? position.averagePrice = position.averagePrice + lossPer
                    : position.averagePrice = position.averagePrice - lossPer;
            }
        }

        position.fundingFeeTracker = globalFundingFeeTracker[pairIndex];
        position.positionAmount += sizeAmount;

        // settlement lp position
        _settleLPPosition(pairIndex, sizeAmount, isLong, true, oraclePrice);
        emit UpdatePosition(
            account,
            positionKey,
            pairIndex,
            orderId,
            isLong,
            beforeCollateral,
            position.collateral,
            oraclePrice,
            beforePositionAmount,
            position.positionAmount,
            position.averagePrice,
            position.fundingFeeTracker,
            0
        );
    }

    function decreasePosition(
        uint256 pairIndex,
        uint256 orderId,
        address account,
        address keeper,
        uint256 sizeAmount,
        bool isLong,
        int256 collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 oraclePrice,
        bool useRiskReserve
    ) external onlyExecutor returns (uint256 tradingFee, int256 fundingFee, int256 pnl) {
        bytes32 positionKey = PositionKey.getPositionKey(account, pairIndex, isLong);
        Position.Info storage position = positions[positionKey];
        require(position.account != address(0), "!0");

        uint256 beforeCollateral = position.collateral;
        uint256 beforePositionAmount = position.positionAmount;

        // update funding fee
        _updateFundingRate(pairIndex, oraclePrice);

        // settlement trading fee and funding fee
        int256 charge;
        (charge, tradingFee, fundingFee) = _takeFundingFeeAddTraderFee(
            pairIndex,
            account,
            keeper,
            orderId,
            sizeAmount,
            false,
            isLong,
            tradingFeeTier,
            referralsRatio,
            referralUserRatio,
            referralOwner,
            oraclePrice
        );

        position.fundingFeeTracker = globalFundingFeeTracker[pairIndex];
        position.positionAmount -= sizeAmount;

        IPool.Pair memory pair = pool.getPair(pairIndex);

        // settlement lp position
        _settleLPPosition(pairIndex, sizeAmount, isLong, false, oraclePrice);

        pnl = position.getUnrealizedPnl(pair, sizeAmount, oraclePrice);

        int256 totalSettlementAmount = pnl + charge;
        if (totalSettlementAmount >= 0) {
            position.collateral = position.collateral.add(totalSettlementAmount.abs());
        } else {
            if (position.collateral >= totalSettlementAmount.abs()) {
                position.collateral = position.collateral.sub(totalSettlementAmount.abs());
            } else {
                if (position.positionAmount == 0) {
                    uint256 subsidy = totalSettlementAmount.abs() - position.collateral;
                    riskReserve.decrease(pair.stableToken, subsidy);
                    position.collateral = 0;
                } else {
                    // adjust position averagePrice
                    uint256 lossPer = totalSettlementAmount.abs().divPrice(position.positionAmount);
                    position.isLong
                        ? position.averagePrice = position.averagePrice + lossPer
                        : position.averagePrice = position.averagePrice - lossPer;
                }
            }
        }

        _handleCollateral(pairIndex, position, collateral);

        if (position.positionAmount == 0 && position.collateral > 0) {
            if (useRiskReserve) {
                riskReserve.increase(pair.stableToken, position.collateral);
            } else {
                pool.transferTokenOrSwap(
                    pairIndex,
                    pledgeAddress,
                    position.account,
                    position.collateral
                );
            }
            position.collateral = 0;
        }

        emit UpdatePosition(
            account,
            positionKey,
            pairIndex,
            orderId,
            isLong,
            beforeCollateral,
            position.collateral,
            oraclePrice,
            beforePositionAmount,
            position.positionAmount,
            position.averagePrice,
            position.fundingFeeTracker,
            pnl
        );
    }

    function adjustCollateral(
        uint256 pairIndex,
        address account,
        bool isLong,
        int256 collateral
    ) external override onlyRouter {
        bytes32 positionKey = PositionKey.getPositionKey(account, pairIndex, isLong);
        Position.Info storage position = positions[positionKey];
        if (position.positionAmount == 0) {
            revert("position not exists");
        }

        IPool.Pair memory pair = pool.getPair(pairIndex);

        uint256 price = IPriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);

        require(!needLiquidation(positionKey, price), "need liquidation");

        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);
        position.validLeverage(
            pair,
            price,
            collateral,
            0,
            true,
            tradingConfig.maxLeverage,
            tradingConfig.maxPositionAmount,
            false,
            getFundingFee(account, pairIndex, isLong)
        );

        if (collateral > 0) {
            IERC20(pair.stableToken).safeTransferFrom(account, address(pool), uint256(collateral));
        }

        uint256 collateralBefore = position.collateral;
        _handleCollateral(pairIndex, position, collateral);

        emit AdjustCollateral(
            position.account,
            position.pairIndex,
            position.isLong,
            positionKey,
            collateralBefore,
            position.collateral
        );
    }

    function updateFundingRate(uint256 _pairIndex) external onlyRouter {
        IPool.Pair memory pair = pool.getPair(_pairIndex);
        uint256 price = IPriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);
        _updateFundingRate(_pairIndex, price);
    }

    function _takeFundingFeeAddTraderFee(
        uint256 _pairIndex,
        address _account,
        address _keeper,
        uint256 _orderId,
        uint256 _sizeAmount,
        bool _isIncrease,
        bool _isLong,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price
    ) internal returns (int256 charge, uint256 tradingFee, int256 fundingFee) {
        IPool.Pair memory pair = pool.getPair(_pairIndex);
        uint256 sizeDeltaStable = uint256(
            TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(_sizeAmount), _price)
        );

        bool isMaker;
        (tradingFee, isMaker) = _regularTradingFee(_pairIndex, _isLong, _isIncrease, sizeDeltaStable, _price);
        charge -= int256(tradingFee);

        int256 exposureAmount = getExposedPositions(_pairIndex);

        int256 afterExposureAmount;
        if ((_isIncrease && _isLong) || (!_isIncrease && !_isLong)) {
            afterExposureAmount = exposureAmount + _sizeAmount.safeConvertToInt256();
        } else {
            afterExposureAmount = exposureAmount - _sizeAmount.safeConvertToInt256();
        }

        (int256 lpAmount, int256 vipTradingFee, uint256 givebackFeeAmount) = feeCollector.distributeTradingFee(
            pair,
            _account,
            _orderId,
            _keeper,
            _sizeAmount,
            sizeDeltaStable,
            _price,
            tradingFee,
            isMaker,
            tradingFeeTier,
            exposureAmount,
            afterExposureAmount,
            referralsRatio,
            referralUserRatio,
            referralOwner
        );

        fundingFee = getFundingFee(_account, _pairIndex, _isLong);
        charge += fundingFee;
        emit TakeFundingFeeAddTraderFeeV2(
            _account,
            _pairIndex,
            _orderId,
            sizeDeltaStable,
            fundingFee,
            tradingFee,
            vipTradingFee,
            givebackFeeAmount,
            lpAmount
        );
    }

    function _settleLPPosition(
        uint256 _pairIndex,
        uint256 _sizeAmount,
        bool _isLong,
        bool isIncrease,
        uint256 _price
    ) internal {
        if (_sizeAmount == 0) {
            return;
        }
        int256 currentExposureAmountChecker = getExposedPositions(_pairIndex);
        if (isIncrease) {
            _isLong
                ? longTracker[_pairIndex] += _sizeAmount
                : shortTracker[_pairIndex] += _sizeAmount;
        } else {
            _isLong
                ? longTracker[_pairIndex] -= _sizeAmount
                : shortTracker[_pairIndex] -= _sizeAmount;
        }
        int256 nextExposureAmountChecker = getExposedPositions(_pairIndex);
        uint256 sizeDelta = _sizeAmount.mulPrice(_price);

        PositionStatus currentPositionStatus = PositionStatus.Balance;
        if (currentExposureAmountChecker > 0) {
            currentPositionStatus = PositionStatus.NetLong;
        } else if (currentExposureAmountChecker < 0) {
            currentPositionStatus = PositionStatus.NetShort;
        }

        PositionStatus nextPositionStatus = PositionStatus.Balance;
        if (nextExposureAmountChecker > 0) {
            nextPositionStatus = PositionStatus.NetLong;
        } else if (nextExposureAmountChecker < 0) {
            nextPositionStatus = PositionStatus.NetShort;
        }

        bool isAddPosition = (currentPositionStatus == PositionStatus.NetLong &&
            nextExposureAmountChecker > currentExposureAmountChecker) ||
            (currentPositionStatus == PositionStatus.NetShort &&
                nextExposureAmountChecker < currentExposureAmountChecker);

        IPool.Vault memory lpVault = pool.getVault(_pairIndex);
        IPool.Pair memory pair = pool.getPair(_pairIndex);

        if (currentPositionStatus == PositionStatus.Balance) {
            if (nextExposureAmountChecker > 0) {
                pool.increaseReserveAmount(_pairIndex, _sizeAmount, 0);
            } else {
                uint256 sizeDeltaStable = uint256(
                    TokenHelper.convertIndexAmountToStable(pair, int256(sizeDelta))
                );
                pool.increaseReserveAmount(_pairIndex, 0, sizeDeltaStable);
            }
            pool.updateAveragePrice(_pairIndex, _price);
            return;
        }

        if (currentPositionStatus == PositionStatus.NetLong) {
            if (isAddPosition) {
                pool.increaseReserveAmount(_pairIndex, _sizeAmount, 0);

                uint256 averagePrice = (uint256(currentExposureAmountChecker).mulPrice(
                    lpVault.averagePrice
                ) + sizeDelta).calculatePrice(uint256(currentExposureAmountChecker) + _sizeAmount);

                pool.updateAveragePrice(_pairIndex, averagePrice);
            } else {
                uint256 decreaseLong;
                uint256 increaseShort;
                if (nextPositionStatus != PositionStatus.NetShort) {
                    decreaseLong = _sizeAmount;
                } else {
                    decreaseLong = uint256(currentExposureAmountChecker);
                    increaseShort = _sizeAmount - decreaseLong;
                }
                pool.decreaseReserveAmount(_pairIndex, decreaseLong, 0);
                if (increaseShort > 0) {
                    pool.increaseReserveAmount(
                        _pairIndex,
                        0,
                        uint256(
                            TokenHelper.convertIndexAmountToStableWithPrice(
                                pair,
                                int256(increaseShort),
                                _price
                            )
                        )
                    );
                    pool.updateAveragePrice(_pairIndex, _price);
                }

                _calLpProfit(pair, false, decreaseLong, _price);
            }
        } else if (currentPositionStatus == PositionStatus.NetShort) {
            if (isAddPosition) {
                uint256 sizeDeltaStable = uint256(
                    TokenHelper.convertIndexAmountToStable(pair, int256(sizeDelta))
                );
                pool.increaseReserveAmount(_pairIndex, 0, sizeDeltaStable);

                uint256 averagePrice = (uint256(-currentExposureAmountChecker).mulPrice(
                    lpVault.averagePrice
                ) + sizeDelta).calculatePrice(uint256(-currentExposureAmountChecker) + _sizeAmount);
                pool.updateAveragePrice(_pairIndex, averagePrice);
            } else {
                uint256 decreaseShort;
                uint256 increaseLong;
                if (nextExposureAmountChecker <= 0) {
                    decreaseShort = _sizeAmount;
                } else {
                    decreaseShort = uint256(-currentExposureAmountChecker);
                    increaseLong = _sizeAmount - decreaseShort;
                }

                pool.decreaseReserveAmount(
                    _pairIndex,
                    0,
                    nextExposureAmountChecker >= 0
                        ? lpVault.stableReservedAmount
                        : uint256(
                            TokenHelper.convertIndexAmountToStableWithPrice(
                                pair,
                                int256(decreaseShort),
                                lpVault.averagePrice
                            )
                        )
                );
                if (increaseLong > 0) {
                    pool.increaseReserveAmount(_pairIndex, increaseLong, 0);
                    pool.updateAveragePrice(_pairIndex, _price);
                }

                _calLpProfit(pair, true, decreaseShort, _price);
            }
        }
        // zero exposure
        if (nextPositionStatus == PositionStatus.Balance) {
            pool.updateAveragePrice(_pairIndex, 0);
        }
    }

    function _calLpProfit(
        IPool.Pair memory pair,
        bool lpIsLong,
        uint amount,
        uint256 price
    ) internal {
        int256 profit = pool.getLpPnl(pair.pairIndex, lpIsLong, amount, price);
        pool.setLPStableProfit(
            pair.pairIndex,
            TokenHelper.convertIndexAmountToStable(pair, profit)
        );
    }

    function _handleCollateral(
        uint256 pairIndex,
        Position.Info storage position,
        int256 collateral
    ) internal {
        if (collateral == 0) {
            return;
        }
        if (collateral < 0) {
            require(position.collateral >= collateral.abs(), "collateral not enough");
            position.collateral = position.collateral.sub(collateral.abs());
            pool.transferTokenOrSwap(pairIndex, pledgeAddress, position.account, collateral.abs());
        } else {
            position.collateral = position.collateral.add(collateral.abs());
        }
    }

    function _regularTradingFee(
        uint256 pairIndex,
        bool isLong,
        bool isIncrease,
        uint256 sizeDeltaStable,
        uint256 executionPrice
    ) internal view returns (uint256 tradingFee, bool isMaker) {
        IFeeCollector.TradingFeeTier memory regularFeeTier = feeCollector.getRegularTradingFeeTier(pairIndex);

        (,, int256 availableLiquidityBefore) = pool.getAvailableLiquidity(pairIndex, executionPrice);

        int256 availableLiquidityAfter;
        if ((isIncrease && isLong) || (!isIncrease && !isLong)) {
            availableLiquidityAfter = availableLiquidityBefore - sizeDeltaStable.safeConvertToInt256();
        } else {
            availableLiquidityAfter = availableLiquidityBefore + sizeDeltaStable.safeConvertToInt256();
        }

        if ((availableLiquidityBefore > 0 && availableLiquidityBefore > availableLiquidityAfter && availableLiquidityAfter >= 0)
            || (availableLiquidityBefore < 0 && availableLiquidityBefore < availableLiquidityAfter && availableLiquidityAfter <= 0)) {
            isMaker = true;
        }

        uint256 rate = isMaker ? regularFeeTier.makerFee.abs() : regularFeeTier.takerFee;
        tradingFee = sizeDeltaStable.mulPercentage(rate);
        return (tradingFee, isMaker);
    }

    function _updateFundingRate(uint256 _pairIndex, uint256 _price) internal {
        uint256 fundingInterval = IFundingRate(ADDRESS_PROVIDER.fundingRate()).getFundingInterval(
            _pairIndex
        );
        if (lastFundingRateUpdateTimes[_pairIndex] == 0) {
            lastFundingRateUpdateTimes[_pairIndex] =
                (block.timestamp / fundingInterval) *
                fundingInterval;
            return;
        }
        if (block.timestamp - lastFundingRateUpdateTimes[_pairIndex] < fundingInterval) {
            return;
        }
        int256 nextFundingRate = _nextFundingRate(_pairIndex, _price);

        globalFundingFeeTracker[_pairIndex] =
            globalFundingFeeTracker[_pairIndex] +
            (nextFundingRate * int256(_price)) /
            int256(PrecisionUtils.pricePrecision());
        lastFundingRateUpdateTimes[_pairIndex] =
            (block.timestamp / fundingInterval) *
            fundingInterval;
        currentFundingRate[_pairIndex] = nextFundingRate;

        IPool.Vault memory vault = pool.getVault(_pairIndex);

        // fund rate for settlement lp
        if (longTracker[_pairIndex] > shortTracker[_pairIndex]) {
            uint256 lpPosition = longTracker[_pairIndex] - shortTracker[_pairIndex];
            int256 profit = (nextFundingRate * int256(lpPosition)) /
                int256(PrecisionUtils.fundingRatePrecision());
            uint256 priceChangePer = profit.abs().calculatePrice(lpPosition);
            if (profit > 0) {
                pool.updateAveragePrice(_pairIndex, vault.averagePrice + priceChangePer);
            } else if (profit < 0) {
                pool.updateAveragePrice(_pairIndex, vault.averagePrice - priceChangePer);
            }
        } else if (longTracker[_pairIndex] < shortTracker[_pairIndex]) {
            uint256 lpPosition = shortTracker[_pairIndex] - longTracker[_pairIndex];
            int256 profit = (-nextFundingRate * int256(lpPosition)) /
                int256(PrecisionUtils.fundingRatePrecision());
            uint256 priceChangePer = profit.abs().calculatePrice(lpPosition);
            if (profit > 0) {
                pool.updateAveragePrice(_pairIndex, vault.averagePrice - priceChangePer);
            } else if (profit < 0) {
                pool.updateAveragePrice(_pairIndex, vault.averagePrice + priceChangePer);
            }
        }

        emit UpdateFundingRate(
            _pairIndex,
            _price,
            nextFundingRate,
            lastFundingRateUpdateTimes[_pairIndex]
        );
    }

    function _nextFundingRate(
        uint256 _pairIndex,
        uint256 _price
    ) internal view returns (int256 fundingRate) {
        IPool.Vault memory vault = pool.getVault(_pairIndex);
        IPool.Pair memory pair = pool.getPair(_pairIndex);

        fundingRate = IFundingRate(ADDRESS_PROVIDER.fundingRate()).getFundingRate(
            pair,
            vault,
            _price
        );
    }

    function getTradingFee(
        uint256 _pairIndex,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeAmount,
        uint256 price
    ) public view override returns (uint256 tradingFee) {
        IPool.Pair memory pair = pool.getPair(_pairIndex);
        uint256 sizeDeltaStable = uint256(
            TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(_sizeAmount), price)
        );

        (tradingFee, ) = _regularTradingFee(_pairIndex, _isLong, _isIncrease, sizeDeltaStable, price);
        return tradingFee;
    }

    function getFundingFee(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) public view override returns (int256 fundingFee) {
        Position.Info memory position = positions.get(_account, _pairIndex, _isLong);
        IPool.Pair memory pair = pool.getPair(_pairIndex);
        int256 fundingFeeTracker = globalFundingFeeTracker[_pairIndex] - position.fundingFeeTracker;
        if ((_isLong && fundingFeeTracker > 0) || (!_isLong && fundingFeeTracker < 0)) {
            fundingFee = -1;
        } else {
            fundingFee = 1;
        }
        fundingFee *= TokenHelper.convertIndexAmountToStable(
            pair,
            int256(
                (position.positionAmount * fundingFeeTracker.abs()) /
                    PrecisionUtils.fundingRatePrecision()
            )
        );
    }

    function getCurrentFundingRate(uint256 _pairIndex) external view override returns (int256) {
        return currentFundingRate[_pairIndex];
    }

    function getNextFundingRate(
        uint256 _pairIndex,
        uint256 price
    ) external view override returns (int256) {
        return _nextFundingRate(_pairIndex, price);
    }

    function getNextFundingRateUpdateTime(
        uint256 _pairIndex
    ) external view override returns (uint256) {
        return
            lastFundingRateUpdateTimes[_pairIndex] +
            IFundingRate(ADDRESS_PROVIDER.fundingRate()).getFundingInterval(_pairIndex);
    }

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool need, uint256 needADLAmount) {
        IPool.Vault memory vault = pool.getVault(pairIndex);
        IPool.Pair memory pair = pool.getPair(pairIndex);
        int256 exposedPositions = getExposedPositions(pairIndex);

        int256 afterExposedPositions = exposedPositions;
        if (isLong) {
            afterExposedPositions -= executionSize.safeConvertToInt256();
        } else {
            afterExposedPositions += executionSize.safeConvertToInt256();
        }

        uint256 maxAvailableLiquidity = TradingHelper.maxAvailableLiquidity(vault, pair, exposedPositions, !isLong, executionPrice);

        if (executionSize <= maxAvailableLiquidity || afterExposedPositions == 0) {
            return (false, 0);
        }

        int256 available;
        if (afterExposedPositions > 0) {
            available = int256(vault.indexTotalAmount) - exposedPositions;
        } else {
            int256 stableToIndexAmount = TokenHelper.convertStableAmountToIndex(
                pair,
                int256(vault.stableTotalAmount)
            );

            int256 exposedPositionDelta = exposedPositions * int256(vault.averagePrice) / int256(PrecisionUtils.pricePrecision());
            available = _max(0, exposedPositions) +
                (stableToIndexAmount + _min(0, exposedPositionDelta)) * int256(PrecisionUtils.pricePrecision()) / int256(executionPrice);
        }

        if (available <= 0) {
            return (true, executionSize);
        }

        if (executionSize > available.abs()) {
            need = true;
            needADLAmount = executionSize - available.abs();
        }
        return (need, needADLAmount);
    }

    function needLiquidation(
        bytes32 positionKey,
        uint256 price
    ) public view returns (bool) {
        Position.Info memory position = positions[positionKey];

        IPool.Pair memory pair = pool.getPair(position.pairIndex);
        IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(position.pairIndex);

        int256 unrealizedPnl = position.getUnrealizedPnl(pair, position.positionAmount, price);
        uint256 tradingFee = getTradingFee(
            position.pairIndex,
            position.isLong,
            false,
            position.positionAmount,
            price
        );
        int256 fundingFee = getFundingFee(
            position.account,
            position.pairIndex,
            position.isLong
        );
        int256 exposureAsset = int256(position.collateral) + unrealizedPnl - int256(tradingFee) + fundingFee;

        bool need;
        if (exposureAsset <= 0) {
            need = true;
        } else {
            uint256 maintainMarginWad = uint256(
                TokenHelper.convertTokenAmountWithPrice(
                    pair.indexToken,
                    int256(position.positionAmount),
                    18,
                    position.averagePrice
                )
            ) * tradingConfig.maintainMarginRate;
            uint256 netAssetWad = uint256(
                TokenHelper.convertTokenAmountTo(pair.stableToken, exposureAsset, 18)
            );

            uint256 riskRate = maintainMarginWad / netAssetWad;
            need = riskRate >= PrecisionUtils.percentage();
        }
        return need;
    }

    function getExposedPositions(uint256 _pairIndex) public view override returns (int256) {
        if (longTracker[_pairIndex] > shortTracker[_pairIndex]) {
            return int256(longTracker[_pairIndex] - shortTracker[_pairIndex]);
        } else {
            return -int256(shortTracker[_pairIndex] - longTracker[_pairIndex]);
        }
    }

    function getPosition(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) public view returns (Position.Info memory) {
        Position.Info memory position = positions.get(_account, _pairIndex, _isLong);
        return position;
    }

    function getPositionByKey(bytes32 key) public view returns (Position.Info memory) {
        Position.Info memory position = positions[key];
        return position;
    }

    function getPositionKey(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) public pure returns (bytes32) {
        return PositionKey.getPositionKey(_account, _pairIndex, _isLong);
    }

    function _max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function _min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRiskReserve.sol";
import "../interfaces/IPool.sol";
import "../libraries/Upgradeable.sol";

contract RiskReserve is IRiskReserve, Upgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => int256) public getReservedAmount;

    address public addressDao;
    address public addressPositionManager;
    IPool public pool;

    function initialize(
        address _addressDao,
        IAddressesProvider addressProvider
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
        addressDao = _addressDao;
    }

    modifier onlyDao() {
        require(msg.sender == addressDao, "onlyDao");
        _;
    }

    modifier onlyPositionManager() {
        require(msg.sender == addressPositionManager, "onlyPositionManager");
        _;
    }

    function updateDaoAddress(address newAddress) external override onlyPoolAdmin {
        address oldAddress = addressDao;
        addressDao = newAddress;
        emit UpdatedDaoAddress(msg.sender, oldAddress, addressDao);
    }

    function updatePositionManagerAddress(address newAddress) external override onlyPoolAdmin {
        address oldAddress = addressPositionManager;
        addressPositionManager = newAddress;
        emit UpdatedPositionManagerAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePoolAddress(address newAddress) external override onlyPoolAdmin {
        address oldAddress = address(pool);
        pool = IPool(newAddress);
        emit UpdatedPoolAddress(msg.sender, oldAddress, address(pool));
    }

    function increase(address asset, uint256 amount) external override onlyPositionManager {
        getReservedAmount[asset] += int256(amount);
    }

    function decrease(address asset, uint256 amount) external override onlyPositionManager {
        getReservedAmount[asset] -= int256(amount);
    }

    function recharge(address asset, uint256 amount) external override {
        IERC20(asset).safeTransferFrom(msg.sender, address(pool), amount);
        getReservedAmount[asset] += int256(amount);
    }

    function withdraw(address asset, address to, uint256 amount) external override onlyDao {
        require(int256(amount) <= getReservedAmount[asset], "insufficient balance");

        if (amount > 0) {
            getReservedAmount[asset] -= int256(amount);

            pool.transferTokenTo(asset, to, amount);
            emit Withdraw(msg.sender, asset, amount, to);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/PositionKey.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Multicall.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IOrderManager.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/ILiquidityCallback.sol";
import "../interfaces/ISwapCallback.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IOrderCallback.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../libraries/TradingTypes.sol";

contract Router is
    Multicall,
    IRouter,
    ILiquidityCallback,
    IOrderCallback,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using Int256Utils for uint256;

    IAddressesProvider public immutable ADDRESS_PROVIDER;
    IOrderManager public immutable orderManager;
    IPositionManager public immutable positionManager;
    IPool public immutable pool;

    mapping(uint256 => OperationStatus) public operationStatus;

    constructor(
        IAddressesProvider addressProvider,
        IOrderManager _orderManager,
        IPositionManager _positionManager,
        IPool _pool
    ){
        ADDRESS_PROVIDER = addressProvider;
        orderManager = _orderManager;
        positionManager = _positionManager;
        pool = _pool;
    }

    modifier onlyPoolAdmin() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender),
            "onlyPoolAdmin"
        );
        _;
    }

    modifier onlyOrderManager() {
        require(msg.sender == address(orderManager), "onlyOrderManager");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(pool), "onlyPool");
        _;
    }

    function salvageToken(address token, uint amount) external onlyPoolAdmin {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function setPaused() external onlyPoolAdmin {
        _pause();
    }

    function setUnPaused() external onlyPoolAdmin {
        _unpause();
    }

    function updateIncreasePositionStatus(uint256 pairIndex, bool enabled) external onlyPoolAdmin {
        operationStatus[pairIndex].increasePositionDisabled = !enabled;
        emit UpdateIncreasePositionStatus(msg.sender, pairIndex, enabled);
    }

    function updateDecreasePositionStatus(uint256 pairIndex, bool enabled) external onlyPoolAdmin {
        operationStatus[pairIndex].decreasePositionDisabled = !enabled;
        emit UpdateDecreasePositionStatus(msg.sender, pairIndex, enabled);
    }

    function updateOrderStatus(uint256 pairIndex, bool enabled) external onlyPoolAdmin {
        operationStatus[pairIndex].orderDisabled = !enabled;
        emit UpdateOrderStatus(msg.sender, pairIndex, enabled);
    }

    function updateAddLiquidityStatus(uint256 pairIndex, bool enabled) external onlyPoolAdmin {
        operationStatus[pairIndex].addLiquidityDisabled = !enabled;
        emit UpdateAddLiquidityStatus(msg.sender, pairIndex, enabled);
    }

    function updateRemoveLiquidityStatus(uint256 pairIndex, bool enabled) external onlyPoolAdmin {
        operationStatus[pairIndex].removeLiquidityDisabled = !enabled;
        emit UpdateRemoveLiquidityStatus(msg.sender, pairIndex, enabled);
    }

    function wrapWETH(address recipient) external payable {
        IWETH(ADDRESS_PROVIDER.WETH()).deposit{value: msg.value}();
        IWETH(ADDRESS_PROVIDER.WETH()).transfer(recipient, msg.value);
    }

    function getOperationStatus(uint256 pairIndex) external view returns (OperationStatus memory) {
        return operationStatus[pairIndex];
    }

    function setPriceAndAdjustCollateral(
        uint256 pairIndex,
        bool isLong,
        int256 collateral,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable whenNotPaused nonReentrant {
        require(!operationStatus[pairIndex].orderDisabled, "disabled");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        positionManager.adjustCollateral(pairIndex, msg.sender, isLong, collateral);
    }

    function setPriceAndUpdateFundingRate(
        uint256 pairIndex,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable whenNotPaused nonReentrant {
        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        positionManager.updateFundingRate(pairIndex);
    }

    function createIncreaseOrderWithTpSl(
        TradingTypes.IncreasePositionWithTpSlRequest memory request
    ) external payable whenNotPaused nonReentrant returns (uint256 orderId) {
        require(!operationStatus[request.pairIndex].increasePositionDisabled, "disabled");
        require(
            request.tradeType != TradingTypes.TradeType.TP &&
            request.tradeType != TradingTypes.TradeType.SL,
            "not support"
        );
        require(
            request.paymentType == TradingTypes.NetworkFeePaymentType.COLLATERAL ||
            (request.paymentType == TradingTypes.NetworkFeePaymentType.ETH
                && msg.value == request.networkFeeAmount + request.tpNetworkFeeAmount + request.slNetworkFeeAmount),
            "incorrect value"
        );
        request.account = msg.sender;

        orderId = orderManager.createOrder{value: request.networkFeeAmount}(
            TradingTypes.CreateOrderRequest({
                account: request.account,
                pairIndex: request.pairIndex,
                tradeType: request.tradeType,
                collateral: request.collateral,
                openPrice: request.openPrice,
                isLong: request.isLong,
                sizeAmount: uint256(request.sizeAmount).safeConvertToInt256(),
                maxSlippage: request.maxSlippage,
                paymentType: TradingTypes.convertPaymentType(request.paymentType),
                networkFeeAmount: request.networkFeeAmount,
                data: abi.encode(request.account)
            })
        );

        // tp、sl
        _createTpSl(
            request.account,
            request.pairIndex,
            request.isLong,
            request.tpPrice,
            request.tp,
            request.slPrice,
            request.sl,
            request.paymentType,
            request.tpNetworkFeeAmount,
            request.slNetworkFeeAmount
        );
        return orderId;
    }

    function _createTpSl(
        address account,
        uint256 pairIndex,
        bool isLong,
        uint256 tpPrice,
        uint128 tp,
        uint256 slPrice,
        uint128 sl,
        TradingTypes.NetworkFeePaymentType paymentType,
        uint256 tpNetworkFeeAmount,
        uint256 slNetworkFeeAmount
    ) internal returns (uint256 tpOrderId, uint256 slOrderId) {
        if (tp > 0) {
            tpOrderId = orderManager.createOrder{value: tpNetworkFeeAmount}(
                TradingTypes.CreateOrderRequest({
                    account: account,
                    pairIndex: pairIndex,
                    tradeType: TradingTypes.TradeType.TP,
                    collateral: 0,
                    openPrice: tpPrice,
                    isLong: isLong,
                    sizeAmount: -(uint256(tp).safeConvertToInt256()),
                    maxSlippage: 0,
                    paymentType: TradingTypes.convertPaymentType(paymentType),
                    networkFeeAmount: tpNetworkFeeAmount,
                    data: abi.encode(account)
                })
            );
        }
        if (sl > 0) {
            slOrderId = orderManager.createOrder{value: slNetworkFeeAmount}(
                TradingTypes.CreateOrderRequest({
                    account: account,
                    pairIndex: pairIndex,
                    tradeType: TradingTypes.TradeType.SL,
                    collateral: 0,
                    openPrice: slPrice,
                    isLong: isLong,
                    sizeAmount: -(uint256(sl).safeConvertToInt256()),
                    maxSlippage: 0,
                    paymentType: TradingTypes.convertPaymentType(paymentType),
                    networkFeeAmount: slNetworkFeeAmount,
                    data: abi.encode(account)
                })
            );
        }
        return (tpOrderId, slOrderId);
    }

    function createIncreaseOrder(
        TradingTypes.IncreasePositionRequest memory request
    ) external payable whenNotPaused nonReentrant returns (uint256 orderId) {
        require(!operationStatus[request.pairIndex].increasePositionDisabled, "disabled");
        require(
            request.tradeType != TradingTypes.TradeType.TP &&
            request.tradeType != TradingTypes.TradeType.SL,
            "not support"
        );
        require(
            request.paymentType == TradingTypes.NetworkFeePaymentType.COLLATERAL ||
            (request.paymentType == TradingTypes.NetworkFeePaymentType.ETH && msg.value == request.networkFeeAmount),
            "incorrect value"
        );

        request.account = msg.sender;

        return
            orderManager.createOrder{value: msg.value}(
                TradingTypes.CreateOrderRequest({
                    account: request.account,
                    pairIndex: request.pairIndex,
                    tradeType: request.tradeType,
                    collateral: request.collateral,
                    openPrice: request.openPrice,
                    isLong: request.isLong,
                    sizeAmount: request.sizeAmount.safeConvertToInt256(),
                    maxSlippage: request.maxSlippage,
                    paymentType: TradingTypes.convertPaymentType(request.paymentType),
                    networkFeeAmount: request.networkFeeAmount,
                    data: abi.encode(request.account)
                })
            );
    }

    function createDecreaseOrder(
        TradingTypes.DecreasePositionRequest memory request
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(!operationStatus[request.pairIndex].decreasePositionDisabled, "disabled");
        require(
            request.paymentType == TradingTypes.NetworkFeePaymentType.COLLATERAL ||
            (request.paymentType == TradingTypes.NetworkFeePaymentType.ETH && msg.value == request.networkFeeAmount),
            "incorrect value"
        );

        request.account = msg.sender;

        return
            orderManager.createOrder{value: msg.value}(
                TradingTypes.CreateOrderRequest({
                    account: request.account,
                    pairIndex: request.pairIndex,
                    tradeType: request.tradeType,
                    collateral: request.collateral,
                    openPrice: request.triggerPrice,
                    isLong: request.isLong,
                    sizeAmount: -(request.sizeAmount.safeConvertToInt256()),
                    maxSlippage: request.maxSlippage,
                    paymentType: TradingTypes.convertPaymentType(request.paymentType),
                    networkFeeAmount: request.networkFeeAmount,
                    data: abi.encode(request.account)
                })
            );
    }

    function createDecreaseOrders(
        TradingTypes.DecreasePositionRequest[] memory requests
    ) external payable whenNotPaused nonReentrant returns (uint256[] memory orderIds) {
        orderIds = new uint256[](requests.length);

        uint256 surplus = msg.value;
        for (uint256 i = 0; i < requests.length; i++) {
            TradingTypes.DecreasePositionRequest memory request = requests[i];

            require(!operationStatus[request.pairIndex].decreasePositionDisabled, "disabled");
            require(surplus >= request.networkFeeAmount, "insufficient network fee");
            surplus -= request.networkFeeAmount;

            orderIds[i] = orderManager.createOrder{value: request.networkFeeAmount}(
                TradingTypes.CreateOrderRequest({
                    account: msg.sender,
                    pairIndex: request.pairIndex,
                    tradeType: request.tradeType,
                    collateral: request.collateral,
                    openPrice: request.triggerPrice,
                    isLong: request.isLong,
                    sizeAmount: -(request.sizeAmount.safeConvertToInt256()),
                    maxSlippage: request.maxSlippage,
                    paymentType: TradingTypes.convertPaymentType(request.paymentType),
                    networkFeeAmount: request.networkFeeAmount,
                    data: abi.encode(msg.sender)
                })
            );
        }
        if (surplus > 0) {
            payable(msg.sender).transfer(surplus);
        }
        return orderIds;
    }

    function _checkOrderAccount(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease
    ) private view {
        if (isIncrease) {
            (TradingTypes.IncreasePositionOrder memory order,) = orderManager.getIncreaseOrder(
                orderId,
                tradeType
            );
            require(order.account == msg.sender, "onlyAccount");
        } else {
            (TradingTypes.DecreasePositionOrder memory order,) = orderManager.getDecreaseOrder(
                orderId,
                tradeType
            );
            require(order.account == msg.sender, "onlyAccount");
        }
    }

    function cancelOrder(CancelOrderRequest memory request) external whenNotPaused nonReentrant {
        _checkOrderAccount(request.orderId, request.tradeType, request.isIncrease);
        orderManager.cancelOrder(
            request.orderId,
            request.tradeType,
            request.isIncrease,
            "cancelOrder"
        );
    }

    function cancelOrders(
        CancelOrderRequest[] memory requests
    ) external whenNotPaused nonReentrant {
        for (uint256 i = 0; i < requests.length; i++) {
            CancelOrderRequest memory request = requests[i];
            _checkOrderAccount(request.orderId, request.tradeType, request.isIncrease);
            orderManager.cancelOrder(
                request.orderId,
                request.tradeType,
                request.isIncrease,
                "cancelOrders"
            );
        }
    }

    function cancelPositionOrders(
        uint256 pairIndex,
        bool isLong,
        bool isIncrease
    ) external whenNotPaused nonReentrant {
        bytes32 key = PositionKey.getPositionKey(msg.sender, pairIndex, isLong);
        IOrderManager.PositionOrder[] memory orders = orderManager.getPositionOrders(key);

        for (uint256 i = 0; i < orders.length; i++) {
            IOrderManager.PositionOrder memory positionOrder = orders[i];
            require(positionOrder.account == msg.sender, "onlyAccount");
            if (isIncrease && positionOrder.isIncrease) {
                orderManager.cancelOrder(
                    positionOrder.orderId,
                    positionOrder.tradeType,
                    true,
                    "cancelOrders"
                );
            } else if (!isIncrease && !positionOrder.isIncrease) {
                orderManager.cancelOrder(
                    positionOrder.orderId,
                    positionOrder.tradeType,
                    false,
                    "cancelOrders"
                );
            }
        }
    }

    function addOrderTpSl(
        AddOrderTpSlRequest memory request
    ) external payable whenNotPaused nonReentrant returns (uint256 tpOrderId, uint256 slOrderId) {
        uint256 pairIndex;
        bool isLong;
        if (request.isIncrease) {
            (TradingTypes.IncreasePositionOrder memory order,) = orderManager.getIncreaseOrder(
                request.orderId,
                request.tradeType
            );
            require(order.account == msg.sender, "no access");
            pairIndex = order.pairIndex;
            isLong = order.isLong;
        } else {
            (TradingTypes.DecreasePositionOrder memory order,) = orderManager.getDecreaseOrder(
                request.orderId,
                request.tradeType
            );
            require(order.account == msg.sender, "no access");
            pairIndex = order.pairIndex;
            isLong = order.isLong;
        }
        require(!operationStatus[pairIndex].orderDisabled, "disabled");

        require(
            request.paymentType == TradingTypes.NetworkFeePaymentType.COLLATERAL ||
            (request.paymentType == TradingTypes.NetworkFeePaymentType.ETH
                && msg.value == request.tpNetworkFeeAmount + request.slNetworkFeeAmount),
            "incorrect value"
        );

        if (request.tp > 0 || request.sl > 0) {
            _createTpSl(
                msg.sender,
                pairIndex,
                isLong,
                request.tpPrice,
                request.tp,
                request.slPrice,
                request.sl,
                request.paymentType,
                request.tpNetworkFeeAmount,
                request.slNetworkFeeAmount
            );
        }
        return (tpOrderId, slOrderId);
    }

    function createTpSl(
        TradingTypes.CreateTpSlRequest memory request
    ) external payable whenNotPaused nonReentrant returns (uint256 tpOrderId, uint256 slOrderId) {
        require(!operationStatus[request.pairIndex].orderDisabled, "disabled");

        require(
            request.paymentType == TradingTypes.NetworkFeePaymentType.COLLATERAL ||
            (request.paymentType == TradingTypes.NetworkFeePaymentType.ETH
                && msg.value == request.tpNetworkFeeAmount + request.slNetworkFeeAmount),
            "incorrect value"
        );

        (tpOrderId, slOrderId) = _createTpSl(
            msg.sender,
            request.pairIndex,
            request.isLong,
            request.tpPrice,
            request.tp,
            request.slPrice,
            request.sl,
            request.paymentType,
            request.tpNetworkFeeAmount,
            request.slNetworkFeeAmount
        );
        return (tpOrderId, slOrderId);
    }

    function addLiquidityETH(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes,
        uint256 updateFee
    ) external payable whenNotPaused nonReentrant returns (uint256 mintAmount, address slipToken, uint256 slipAmount){
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        require(pairIndex > 0, "!exists");
        require(!operationStatus[pairIndex].addLiquidityDisabled, "disabled");
        require(msg.value >= indexAmount + updateFee, "ne");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: updateFee}(tokens, updateData, publishTimes);

        uint256 wrapAmount = msg.value - updateFee;
        this.wrapWETH{value: wrapAmount}(address(this));

        (mintAmount, slipToken, slipAmount) = IPool(pool).addLiquidity(
            msg.sender,
            pairIndex,
            indexAmount,
            stableAmount,
            abi.encode(msg.sender)
        );

        if (wrapAmount - indexAmount > 0 && indexToken == ADDRESS_PROVIDER.WETH()) {
            IWETH(ADDRESS_PROVIDER.WETH()).safeTransfer(msg.sender, wrapAmount - indexAmount);
        }
    }

    function addLiquidity(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 mintAmount, address slipToken, uint256 slipAmount)
    {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        require(pairIndex > 0, "!exists");
        require(!operationStatus[pairIndex].addLiquidityDisabled, "disabled");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        if (indexToken == ADDRESS_PROVIDER.WETH()) {
            IWETH(ADDRESS_PROVIDER.WETH()).safeTransferFrom(msg.sender, address(this), indexAmount);
        }

        return
            IPool(pool).addLiquidity(
                msg.sender,
                pairIndex,
                indexAmount,
                stableAmount,
                abi.encode(msg.sender)
            );
    }

    function addLiquidityForAccount(
        address indexToken,
        address stableToken,
        address receiver,
        uint256 indexAmount,
        uint256 stableAmount,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 mintAmount, address slipToken, uint256 slipAmount)
    {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        require(pairIndex > 0, "!exists");
        require(!operationStatus[pairIndex].addLiquidityDisabled, "disabled");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        if (indexToken == ADDRESS_PROVIDER.WETH()) {
            IWETH(ADDRESS_PROVIDER.WETH()).safeTransferFrom(msg.sender, address(this), indexAmount);
        }
        return
            IPool(pool).addLiquidity(
                receiver,
                pairIndex,
                indexAmount,
                stableAmount,
                abi.encode(msg.sender)
            );
    }

    function removeLiquidity(
        address indexToken,
        address stableToken,
        uint256 amount,
        bool useETH,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount)
    {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        require(pairIndex > 0, "!exists");
        require(!operationStatus[pairIndex].removeLiquidityDisabled, "disabled");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        return
            IPool(pool).removeLiquidity(
                payable(msg.sender),
                pairIndex,
                amount,
                useETH,
                abi.encode(msg.sender)
            );
    }

    function removeLiquidityForAccount(
        address indexToken,
        address stableToken,
        address receiver,
        uint256 amount,
        bool useETH,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount)
    {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        require(pairIndex > 0, "!exists");
        require(!operationStatus[pairIndex].removeLiquidityDisabled, "disabled");

        IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).updatePrice{value: msg.value}(tokens, updateData, publishTimes);

        return
            IPool(pool).removeLiquidity(
                payable(receiver),
                pairIndex,
                amount,
                useETH,
                abi.encode(msg.sender)
            );
    }

    function removeLiquidityCallback(
        address pairToken,
        uint256 amount,
        bytes calldata data
    ) external override onlyPool {
        address sender = abi.decode(data, (address));
        IERC20(pairToken).safeTransferFrom(sender, msg.sender, amount);
    }

    function createOrderCallback(
        address collateral,
        uint256 amount,
        address to,
        bytes calldata data
    ) external override onlyOrderManager {
        address sender = abi.decode(data, (address));

        if (amount > 0) {
            IERC20(collateral).safeTransferFrom(sender, to, uint256(amount));
        }
    }

    function addLiquidityCallback(
        address indexToken,
        address stableToken,
        uint256 amountIndex,
        uint256 amountStable,
        bytes calldata data
    ) external override onlyPool {
        address sender = abi.decode(data, (address));

        if (amountIndex > 0) {
            if (indexToken == ADDRESS_PROVIDER.WETH()) {
                IERC20(indexToken).safeTransfer(msg.sender, uint256(amountIndex));
            } else {
                IERC20(indexToken).safeTransferFrom(sender, msg.sender, uint256(amountIndex));
            }
        }
        if (amountStable > 0) {
            IERC20(stableToken).safeTransferFrom(sender, msg.sender, uint256(amountStable));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import '../token/interfaces/IBaseToken.sol';

contract Convertor is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public convertToken;
    address public claimToken;
    address public communityPool;

    struct Conversion {
        uint256 initAmount;
        uint256 convertAmount;
        uint256 lockPeriod;
        uint256 lastVestingTimes;
        uint256 claimedAmount;
    }

    event Convert(
        address indexed account,
        uint256 initAmount,
        uint256 lockDays,
        uint256 convertAmount,
        uint256 remainingAmount
    );

    event Claim(address indexed account, uint256 amount);

    mapping(address => Conversion[]) public userConversions;

    constructor(address _convertToken, address _claimToken) {
        convertToken = _convertToken;
        claimToken = _claimToken;
    }

    function setCommunityPool(address _communityPool) external onlyOwner {
        communityPool = _communityPool;
    }

    function convert(uint256 amount, uint256 lockDays) external {
        require(
            lockDays == 0 || lockDays == 14 || lockDays == 30 || lockDays == 90 || lockDays == 180,
            'Convertor: invalid unlock period'
        );

        // claim before convert
        _claim(msg.sender);

        IERC20(convertToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 convertAmount;
        if (lockDays == 0) {
            convertAmount = (amount * 50) / 100;
        } else if (lockDays == 14) {
            convertAmount = (amount * 60) / 100;
        } else if (lockDays == 30) {
            convertAmount = (amount * 70) / 100;
        } else if (lockDays == 90) {
            convertAmount = (amount * 85) / 100;
        } else if (lockDays == 180) {
            convertAmount = amount;
        }

        // burn remaining raMYX and transfer myx
        uint256 remainingAmount = amount - convertAmount;
        IBaseToken(convertToken).burn(address(this), remainingAmount);
        IERC20(claimToken).safeTransfer(communityPool, remainingAmount);

        // convert immediately
        if (lockDays == 0) {
            IBaseToken(convertToken).burn(address(this), convertAmount);
            IERC20(claimToken).safeTransfer(msg.sender, convertAmount);
        } else {
            userConversions[msg.sender].push(Conversion(amount, convertAmount, lockDays * 1 days, block.timestamp, 0));
        }

        emit Convert(msg.sender, amount, lockDays, convertAmount, remainingAmount);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function _claim(address account) internal {
        address account = msg.sender;

        Conversion[] storage conversions = userConversions[account];

        if (conversions.length == 0) {
            return;
        }
        uint256 claimableAmount;
        for (uint256 i = conversions.length - 1; i >= 0; i--) {
            Conversion storage conversion = conversions[i];
            uint256 timeDiff = block.timestamp - conversion.lastVestingTimes;
            uint256 nextVestedAmount = (conversion.convertAmount * timeDiff) / conversion.lockPeriod;

            if (nextVestedAmount + conversion.claimedAmount >= conversion.convertAmount) {
                nextVestedAmount = conversion.convertAmount - conversion.claimedAmount;
                // remove conversion
                Conversion storage lastConversion = conversions[conversions.length - 1];
                conversions[i] = lastConversion;
                conversions.pop();
            } else {
                conversion.claimedAmount += nextVestedAmount;
                conversion.lastVestingTimes = block.timestamp;
            }
            claimableAmount += nextVestedAmount;
            if (conversions.length == 0 || i == 0) {
                break;
            }
        }

        IBaseToken(convertToken).burn(address(this), claimableAmount);
        IERC20(claimToken).safeTransfer(account, claimableAmount);

        emit Claim(msg.sender, claimableAmount);
    }

    function claimableAmount(address _account) public view returns (uint256 claimableAmount) {
        Conversion[] memory conversions = userConversions[_account];
        for (uint256 i = 0; i < conversions.length; i++) {
            Conversion memory conversion = conversions[i];
            uint256 timeDiff = block.timestamp - conversion.lastVestingTimes;
            uint256 nextVestedAmount = (conversion.convertAmount * timeDiff) / conversion.lockPeriod;

            if (nextVestedAmount + conversion.claimedAmount >= conversion.convertAmount) {
                nextVestedAmount = conversion.convertAmount - conversion.claimedAmount;
            }
            claimableAmount += nextVestedAmount;
        }
    }

    function totalConverts(
        address _account
    ) public view returns (uint256 amount, uint256 convertAmount, uint256 claimedAmount) {
        Conversion[] memory conversions = userConversions[_account];
        for (uint256 i = 0; i < conversions.length; i++) {
            Conversion memory conversion = conversions[i];
            amount += conversion.initAmount;
            convertAmount += conversion.convertAmount;
            claimedAmount += conversion.claimedAmount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../token/interfaces/IBaseToken.sol";
import "./interfaces/IRewardDistributor.sol";
import "../interfaces/IPositionManager.sol";

// distribute reward myx for staking
contract FeeDistributor is IRewardDistributor, Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public rewardToken;

    // increment after update root
    uint256 public round;

    // merkle root for round
    mapping(uint256 => bytes32) public merkleRoots;

    mapping(bytes32 => bool) public merkleRootUsed;

    mapping(uint256 => mapping(address => bool)) public userClaimed;

    // total rewards claimed by user
    mapping(address => uint256) public userClaimedAmount;

    uint256 public totalReward;

    uint256 public totalClaimed;

    mapping(address => bool) public isHandler;

    IPositionManager public positionManager;

    event Claim(address indexed account, uint256 indexed round, uint256 amount);
    event Compound(address indexed account, uint256 indexed round, uint256 amount);

    constructor(address _rewardToken) {
        rewardToken = _rewardToken;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender], "RewardDistributor: handler forbidden");
        _;
    }

    function setHandler(address _handler, bool enable) external onlyOwner {
        isHandler[_handler] = enable;
    }

    function setPositionManager(IPositionManager _positionManager) external onlyOwner {
        positionManager = _positionManager;
    }

    // update root by handler
    // amount: total reward
    function updateRoot(
        bytes32 _merkleRoot,
        uint256 transferInAmount,
        uint256 _amount
    ) external override onlyHandler {
        require(!merkleRootUsed[_merkleRoot], "RewardDistributor: root already used");
        require(totalReward + transferInAmount >= _amount, "RewardDistributor: reward not enough");
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), transferInAmount);

        round++;
        merkleRoots[round] = _merkleRoot;
        merkleRootUsed[_merkleRoot] = true;
        totalReward += transferInAmount;
    }

    // claim reward by user
    function claim(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused nonReentrant {
        _claim(msg.sender, msg.sender, _amount, round, _merkleProof);
    }

    // claim reward by handler
    function claimForAccount(
        address account,
        address receiver,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external override onlyHandler whenNotPaused nonReentrant {
        _claim(account, receiver, _amount, round, _merkleProof);
    }

    function _claim(
        address account,
        address receiver,
        uint256 _amount,
        uint256 _round,
        bytes32[] calldata _merkleProof
    ) private returns (uint256) {
        require(!userClaimed[_round][account], "RewardDistributor: already claimed");

        (bool canClaim, uint256 adjustedAmount) = _canClaim(account, _amount, _merkleProof);

        require(canClaim, "RewardDistributor: cannot claim");

        userClaimed[_round][account] = true;

        userClaimedAmount[account] += adjustedAmount;
        totalClaimed += adjustedAmount;

        IBaseToken(rewardToken).mint(receiver, adjustedAmount);

        emit Claim(account, _round, adjustedAmount);
        return adjustedAmount;
    }

    function canClaim(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool, uint256) {
        return _canClaim(msg.sender, _amount, _merkleProof);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _canClaim(
        address account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool, uint256) {
        bytes32 node = keccak256(abi.encodePacked(account, _amount));
        bool canClaim = MerkleProof.verify(_merkleProof, merkleRoots[round], node);

        if ((!canClaim) || (userClaimed[round][account])) {
            return (false, 0);
        } else {
            return (true, _amount - userClaimedAmount[account]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardDistributor {
    event UpdateRoot(uint256 round);

    function updateRoot(bytes32 _merkleRoot, uint256 transferInAmount, uint256 _amount) external;

    function claimForAccount(
        address account,
        address receiver,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingPool {
    function stakeForAccount(address funder, address account, address stakeToken, uint256 amount) external;

    function unstakeForAccount(address account, address receiver, address stakeToken, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../token/interfaces/IBaseToken.sol';
import '../interfaces/IPool.sol';

// staking pool for MLP
contract LPStakingPool is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IPool public pool;

    mapping(uint256 => mapping(address => uint256)) public userStaked;

    mapping(uint256 => uint256) public maxStakeAmount;

    mapping(uint256 => uint256) public totalStaked;

    mapping(address => bool) public isHandler;

    event Stake(uint256 indexed pairIndex, address indexed pairToken, address indexed account, uint256 amount);
    event Unstake(uint256 indexed pairIndex, address indexed pairToken, address indexed account, uint256 amount);

    constructor(IPool _pool) {
        pool = _pool;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender], 'LPStakingPool: handler forbidden');
        _;
    }

    function setHandler(address _handler, bool enable) external onlyOwner {
        isHandler[_handler] = enable;
    }

    function setPairInfo(IPool _pool) external onlyOwner {
        pool = _pool;
    }

    function setMaxStakeAmount(uint256 _pairIndex, uint256 _maxStakeAmount) external onlyOwner {
        maxStakeAmount[_pairIndex] = _maxStakeAmount;
    }

    function stake(uint256 pairIndex, uint256 amount) external whenNotPaused {
        _stake(pairIndex, msg.sender, msg.sender, amount);
    }

    function stakeForAccount(
        uint256 pairIndex,
        address funder,
        address account,
        uint256 amount
    ) external onlyHandler whenNotPaused {
        _stake(pairIndex, funder, account, amount);
    }

    function unstake(uint256 pairIndex, uint256 amount) external whenNotPaused {
        _unstake(pairIndex, msg.sender, msg.sender, amount);
    }

    function unstakeForAccount(
        uint256 pairIndex,
        address account,
        address receiver,
        uint256 amount
    ) external onlyHandler whenNotPaused {
        _unstake(pairIndex, account, receiver, amount);
    }

    function _stake(uint256 pairIndex, address funder, address account, uint256 amount) private {
        require(amount > 0, 'LPStakingPool: invalid stake amount');

        IPool.Pair memory pair = pool.getPair(pairIndex);
        require(pair.enable && pair.pairToken != address(0), 'LPStakingPool: invalid pair');
        require(
            userStaked[pairIndex][account] + amount <= maxStakeAmount[pairIndex],
            'LPStakingPool :exceed max stake amount'
        );

        userStaked[pairIndex][account] += amount;
        totalStaked[pairIndex] += amount;

        IERC20(pair.pairToken).safeTransferFrom(funder, address(this), amount);

        emit Stake(pairIndex, pair.pairToken, account, amount);
    }

    function _unstake(uint256 pairIndex, address account, address receiver, uint256 amount) private {
        IPool.Pair memory pair = pool.getPair(pairIndex);
        require(pair.pairToken != address(0), 'LPStakingPool: invalid pair');

        require(userStaked[pairIndex][account] > 0, 'LPStakingPool: none staked');
        require(amount > 0 && amount <= userStaked[pairIndex][account], 'LPStakingPool: invalid unstake amount');

        userStaked[pairIndex][account] -= amount;
        totalStaked[pairIndex] -= amount;

        IERC20(pair.pairToken).safeTransfer(receiver, amount);

        emit Unstake(pairIndex, pair.pairToken, account, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import '../token/interfaces/IBaseToken.sol';
import './interfaces/IRewardDistributor.sol';
import './interfaces/IStakingPool.sol';

// distribute reward myx for staking
contract RewardDistributor is IRewardDistributor, Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public rewardToken;

    // increment after update root
    uint256 public round;

    // merkle root for round
    mapping(uint256 => bytes32) public merkleRoots;

    mapping(bytes32 => bool) public merkleRootUsed;

    mapping(uint256 => mapping(address => bool)) public userClaimed;

    // total rewards claimed by user
    mapping(address => uint256) public userClaimedAmount;

    uint256 public totalClaimed;

    mapping(address => bool) public isHandler;

    IStakingPool public stakingPool;

    event Claim(address indexed account, uint256 indexed round, uint256 amount);
    event Compound(address indexed account, uint256 indexed round, uint256 amount);

    constructor(address _rewardToken) {
        rewardToken = _rewardToken;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender], 'RewardDistributor: handler forbidden');
        _;
    }

    function setHandler(address _handler, bool enable) external onlyOwner {
        isHandler[_handler] = enable;
    }

    function setStakingPool(IStakingPool _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
    }

    // update root by handler
    function updateRoot(bytes32 _merkleRoot, uint256 transferInAmount, uint256 amount) external override onlyHandler {
        require(!merkleRootUsed[_merkleRoot], 'RewardDistributor: root already used');

        round++;
        merkleRoots[round] = _merkleRoot;
        merkleRootUsed[_merkleRoot] = true;

        emit UpdateRoot(round);
    }

    // claim reward by user
    function claim(uint256 _amount, bytes32[] calldata _merkleProof) external whenNotPaused nonReentrant {
        _claim(msg.sender, msg.sender, _amount, _merkleProof);
    }

    // claim reward by handler
    function claimForAccount(
        address account,
        address receiver,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external override onlyHandler whenNotPaused nonReentrant {
        _claim(account, receiver, _amount, _merkleProof);
    }

    function compound(uint256 _amount, bytes32[] calldata _merkleProof) external whenNotPaused nonReentrant {
        require(address(stakingPool) != address(0), 'RewardDistributor: stakingPool not exist');
        uint256 claimAmount = _claim(msg.sender, address(this), _amount, _merkleProof);
        IERC20(rewardToken).approve(address(stakingPool), claimAmount);
        stakingPool.stakeForAccount(address(this), msg.sender, rewardToken, claimAmount);
        emit Compound(msg.sender, round, _amount);
    }

    function _claim(
        address account,
        address receiver,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private returns (uint256) {
        require(!userClaimed[round][account], 'RewardDistributor: already claimed');

        (bool canClaim, uint256 adjustedAmount) = _canClaim(account, _amount, _merkleProof);

        require(canClaim, 'RewardDistributor: cannot claim');

        userClaimed[round][account] = true;

        userClaimedAmount[account] += adjustedAmount;
        totalClaimed += adjustedAmount;

        IBaseToken(rewardToken).mint(receiver, adjustedAmount);

        emit Claim(account, round, adjustedAmount);
        return adjustedAmount;
    }

    function canClaim(uint256 _amount, bytes32[] calldata _merkleProof) external view returns (bool, uint256) {
        return _canClaim(msg.sender, _amount, _merkleProof);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _canClaim(
        address account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool, uint256) {
        bytes32 node = keccak256(abi.encodePacked(account, _amount));
        bool canClaim = MerkleProof.verify(_merkleProof, merkleRoots[round], node);

        if ((!canClaim) || (userClaimed[round][account])) {
            return (false, 0);
        } else {
            return (true, _amount - userClaimedAmount[account]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import '../token/interfaces/IBaseToken.sol';
import './interfaces/IStakingPool.sol';
import './interfaces/IRewardDistributor.sol';
import '../interfaces/IFeeCollector.sol';

// staking pool for MYX / raMYX
contract StakingPool is IStakingPool, Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant PRECISION = 1e30;

    IRewardDistributor rewardDistributor;

    address public stToken;
    address public rewardToken;
    mapping(address => bool) public isStakeToken;
    mapping(address => uint256) public maxStakeAmount;
    // rewardToken -> stakeAmount
    mapping(address => uint256) public totalStaked;
    // rewardToken -> user -> stakeAmount
    mapping(address => mapping(address => uint256)) public userStaked;

    IFeeCollector public feeCollector;

    uint256 public cumulativeRewardPerToken;
    mapping(address => uint256) public userCumulativeRewardPerTokens;

    mapping(address => bool) public isHandler;

    event Stake(address indexed stakeToken, address indexed account, uint256 amount);
    event Unstake(address indexed stakeToken, address indexed account, uint256 amount);
    event Claim(address receiver, uint256 amount);

    constructor(
        address[] memory _stakeTokens,
        address _stToken,
        address _rewardToken,
        IFeeCollector _feeCollector
    ) {
        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            address stakeToken = _stakeTokens[i];
            isStakeToken[stakeToken] = true;
        }
        stToken = _stToken;
        rewardToken = _rewardToken;
        feeCollector = _feeCollector;
    }

    modifier onlyHandler() {
        require(isHandler[msg.sender], 'StakingPool: handler forbidden');
        _;
    }

    function setHandler(address _handler, bool enable) external onlyOwner {
        isHandler[_handler] = enable;
    }

    function setStakeToken(address _stakeToken, bool _isStakeToken) external onlyOwner {
        isStakeToken[_stakeToken] = _isStakeToken;
    }

    function setMaxStakeAmount(address _stakeToken, uint256 _maxStakeAmount) external onlyOwner {
        maxStakeAmount[_stakeToken] = _maxStakeAmount;
    }

    function stake(address stakeToken, uint256 amount) external whenNotPaused {
        _stake(msg.sender, msg.sender, stakeToken, amount);
    }

    function stakeForAccount(
        address funder,
        address account,
        address stakeToken,
        uint256 amount
    ) external override onlyHandler whenNotPaused {
        _stake(funder, account, stakeToken, amount);
    }

    function unstake(address stakeToken, uint256 amount) external whenNotPaused {
        _unstake(msg.sender, msg.sender, stakeToken, amount);
    }

    function unstakeForAccount(
        address account,
        address receiver,
        address stakeToken,
        uint256 amount
    ) external override onlyHandler whenNotPaused {
        _unstake(account, receiver, stakeToken, amount);
    }

    function _stake(address funder, address account, address stakeToken, uint256 amount) private {
        require(isStakeToken[stakeToken], 'StakingPool: invalid depositToken');
        require(amount > 0, 'StakingPool: invalid stake amount');
        require(
            userStaked[stakeToken][account] + amount <= maxStakeAmount[stakeToken],
            'StakingPool: exceed max stake amount'
        );
        _claimReward(account);

        userStaked[stakeToken][account] += amount;
        totalStaked[stakeToken] += amount;

        IERC20(stakeToken).safeTransferFrom(funder, address(this), amount);
        IBaseToken(stToken).mint(account, amount);

        emit Stake(stakeToken, account, amount);
    }

    function _unstake(address account, address receiver, address stakeToken, uint256 amount) private {
        require(isStakeToken[stakeToken], 'StakingPool: invalid depositToken');
        require(amount > 0, 'StakingPool: invalid stake amount');
        require(amount <= userStaked[stakeToken][account], 'StakingPool: exceed staked amount');

        _claimReward(account);

        userStaked[stakeToken][account] -= amount;
        totalStaked[stakeToken] -= amount;

        IERC20(stakeToken).safeTransfer(receiver, amount);
        IBaseToken(stToken).burn(account, amount);

        emit Unstake(stakeToken, account, amount);
    }

    function claimReward() external whenNotPaused {
        _claimReward(msg.sender);
    }

    function _claimReward(address account) internal returns (uint256 claimReward) {
        uint256 totalSupply = IERC20(stToken).totalSupply();
        if (totalSupply == 0) {
            return 0;
        }

        uint256 pendingReward = feeCollector.claimStakingTradingFee();
        if (pendingReward > 0) {
            cumulativeRewardPerToken += pendingReward.mulDiv(PRECISION, totalSupply);
        }
        uint256 balance = IERC20(stToken).balanceOf(account);
        uint256 claimableReward = balance.mulDiv(
            cumulativeRewardPerToken - userCumulativeRewardPerTokens[account],
            PRECISION
        );
        IERC20(rewardToken).safeTransfer(account, claimableReward);
        userCumulativeRewardPerTokens[account] = cumulativeRewardPerToken;
    }

    function claimableReward(address account) public view returns (uint256 claimableReward) {
        uint256 totalSupply = IERC20(stToken).totalSupply();
        uint256 balance = IERC20(stToken).balanceOf(account);
        if (totalSupply == 0 || balance == 0) {
            return 0;
        }
        uint256 pendingReward = feeCollector.stakingTradingFee();
        uint256 nextCumulativeFeePerToken = cumulativeRewardPerToken + pendingReward.mulDiv(PRECISION, totalSupply);
        claimableReward = balance.mulDiv(nextCumulativeFeePerToken - userCumulativeRewardPerTokens[account], PRECISION);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

contract Vester is ReentrancyGuard, Ownable, Initializable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    enum DistributeType {
        TEAM_ADVISOR,
        PRIVATE_PLACEMENT,
        COMMUNITY,
        INITIAL_LIQUIDITY,
        MARKET_OPERATION,
        ECO_KEEPER,
        DEVELOPMENT_RESERVE
    }

    event Release(
        DistributeType indexed distributeType,
        address indexed recevier,
        uint256 releaseAmount,
        uint256 totalRelease,
        uint256 releasedAmount
    );

    uint256 public constant PERCENTAGE = 10000;
    uint256 public constant MONTH = 30 days;
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    address public token;

    mapping(DistributeType => address) receiver;
    mapping(DistributeType => uint256) totalRelease;
    mapping(DistributeType => uint256) tge;
    mapping(DistributeType => uint256) releaseInterval;
    mapping(DistributeType => uint256) releaseRounds;
    mapping(DistributeType => uint256) nextReleaseTime;
    mapping(DistributeType => uint256) releasedAmount;

    constructor(
        address _token,
        address _teamAndAdvisorReceiver,
        address _privatePlacementReceiver,
        address _communityReceiver,
        address _initLiquidityReceiver,
        address _marketOperationReceiver,
        address _ecoKeeperReceiver,
        address _developmentReserveReceiver
    ) {
        require(_token != address(0), 'Vester: invalid token');
        token = _token;

        receiver[DistributeType.TEAM_ADVISOR] = _teamAndAdvisorReceiver;
        totalRelease[DistributeType.TEAM_ADVISOR] = (TOTAL_SUPPLY * 2000) / PERCENTAGE;
        releaseInterval[DistributeType.TEAM_ADVISOR] = MONTH;
        releaseRounds[DistributeType.TEAM_ADVISOR] = 24;
        nextReleaseTime[DistributeType.TEAM_ADVISOR] = block.timestamp + 12 * MONTH;

        receiver[DistributeType.PRIVATE_PLACEMENT] = _privatePlacementReceiver;
        totalRelease[DistributeType.PRIVATE_PLACEMENT] = (TOTAL_SUPPLY * 2000) / PERCENTAGE;
        releaseInterval[DistributeType.PRIVATE_PLACEMENT] = MONTH;
        releaseRounds[DistributeType.PRIVATE_PLACEMENT] = 18;
        nextReleaseTime[DistributeType.PRIVATE_PLACEMENT] = block.timestamp + 6 * MONTH;

        receiver[DistributeType.COMMUNITY] = _communityReceiver;
        totalRelease[DistributeType.COMMUNITY] = (TOTAL_SUPPLY * 3000) / PERCENTAGE;

        receiver[DistributeType.INITIAL_LIQUIDITY] = _initLiquidityReceiver;
        totalRelease[DistributeType.INITIAL_LIQUIDITY] = (TOTAL_SUPPLY * 550) / PERCENTAGE;

        receiver[DistributeType.MARKET_OPERATION] = _marketOperationReceiver;
        totalRelease[DistributeType.MARKET_OPERATION] = (TOTAL_SUPPLY * 800) / PERCENTAGE;
        tge[DistributeType.MARKET_OPERATION] = (totalRelease[DistributeType.MARKET_OPERATION] * 250) / PERCENTAGE;
        releaseInterval[DistributeType.MARKET_OPERATION] = 3 * MONTH;
        releaseRounds[DistributeType.MARKET_OPERATION] = 6;
        nextReleaseTime[DistributeType.MARKET_OPERATION] = block.timestamp;

        receiver[DistributeType.ECO_KEEPER] = _ecoKeeperReceiver;
        totalRelease[DistributeType.ECO_KEEPER] = (TOTAL_SUPPLY * 850) / PERCENTAGE;
        tge[DistributeType.ECO_KEEPER] = (totalRelease[DistributeType.ECO_KEEPER] * 250) / PERCENTAGE;
        releaseInterval[DistributeType.ECO_KEEPER] = 3 * MONTH;
        releaseRounds[DistributeType.ECO_KEEPER] = 6;
        nextReleaseTime[DistributeType.ECO_KEEPER] = block.timestamp;

        receiver[DistributeType.DEVELOPMENT_RESERVE] = _developmentReserveReceiver;
        totalRelease[DistributeType.DEVELOPMENT_RESERVE] = (TOTAL_SUPPLY * 800) / PERCENTAGE;
    }

    function updateReceiver(DistributeType _distributeType, address _receiver) external onlyOwner {
        require(_receiver != address(0), 'Vester: invalid receiver');
        receiver[_distributeType] = _receiver;
    }

    function releaseToken(DistributeType distributeType) external nonReentrant returns (uint256 releaseAmount) {
        require(releasedAmount[distributeType] < totalRelease[distributeType], 'Vester: all released');
        require(receiver[distributeType] != address(0), 'Vester: invalid receiver');

        if (
            distributeType == DistributeType.TEAM_ADVISOR ||
            distributeType == DistributeType.PRIVATE_PLACEMENT ||
            distributeType == DistributeType.COMMUNITY ||
            distributeType == DistributeType.INITIAL_LIQUIDITY ||
            distributeType == DistributeType.DEVELOPMENT_RESERVE
        ) {
            require(block.timestamp >= nextReleaseTime[distributeType], 'Vester: locking time');

            releaseAmount = getReleaseAmount(distributeType);
            require(releaseAmount > 0, 'Vester: none release');

            releasedAmount[distributeType] += releaseAmount;
            nextReleaseTime[distributeType] += releaseInterval[distributeType];
            IERC20(token).safeTransfer(receiver[distributeType], releaseAmount);
        } else if (
            distributeType == DistributeType.COMMUNITY ||
            distributeType == DistributeType.INITIAL_LIQUIDITY ||
            distributeType == DistributeType.DEVELOPMENT_RESERVE
        ) {
            releaseAmount = getReleaseAmount(distributeType);
            require(releaseAmount > 0, 'Vester: none release');
            releasedAmount[distributeType] += releaseAmount;
            IERC20(token).safeTransfer(receiver[distributeType], releaseAmount);
        }
        emit Release(
            distributeType,
            receiver[distributeType],
            releaseAmount,
            totalRelease[distributeType],
            releasedAmount[distributeType]
        );
    }

    function getReleaseAmount(DistributeType distributeType) public view returns (uint256 releaseAmount) {
        if (releasedAmount[distributeType] >= totalRelease[distributeType]) {
            return 0;
        }

        if (distributeType == DistributeType.TEAM_ADVISOR || distributeType == DistributeType.PRIVATE_PLACEMENT) {
            if (block.timestamp < nextReleaseTime[distributeType]) {
                return 0;
            }

            // first release
            if (releasedAmount[distributeType] == 0) {
                return totalRelease[distributeType] / releaseRounds[distributeType];
            }

            uint256 interval = block.timestamp - nextReleaseTime[distributeType];
            if (interval < releaseInterval[distributeType]) {
                return 0;
            }
            // todo releaseAmount.min(total - released)
            releaseAmount = totalRelease[distributeType] / releaseRounds[distributeType];
        } else if (distributeType == DistributeType.MARKET_OPERATION || distributeType == DistributeType.ECO_KEEPER) {

            if (block.timestamp < nextReleaseTime[distributeType]) {
                return 0;
            }

            if (releasedAmount[distributeType] == 0) {
                return tge[distributeType];
            }

            uint256 interval = block.timestamp - nextReleaseTime[distributeType];
            if (interval < releaseInterval[distributeType]) {
                return 0;
            }

            releaseAmount = (totalRelease[distributeType] - tge[distributeType]) / releaseRounds[distributeType];
        } else if (
            distributeType == DistributeType.COMMUNITY ||
            distributeType == DistributeType.INITIAL_LIQUIDITY ||
            distributeType == DistributeType.DEVELOPMENT_RESERVE
        ) {
            releaseAmount = totalRelease[distributeType] - releasedAmount[distributeType];
        }
        return releaseAmount.min(totalRelease[distributeType] - releasedAmount[distributeType]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pythnetwork/pyth-sdk-solidity/MockPyth.sol';

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libraries/PrecisionUtils.sol";
import "../interfaces/IPool.sol";

library TokenHelper {
    using PrecisionUtils for uint256;
    using SafeMath for uint256;

    function convertIndexAmountToStable(
        IPool.Pair memory pair,
        int256 indexTokenAmount
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountTo(pair.indexToken, indexTokenAmount, stableTokenDec);
    }

    function convertIndexAmountToStableWithPrice(
        IPool.Pair memory pair,
        int256 indexTokenAmount,
        uint256 price
    ) internal view returns (int256 amount) {
        if (indexTokenAmount == 0) return 0;

        uint8 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();
        return convertTokenAmountWithPrice(pair.indexToken, indexTokenAmount, stableTokenDec, price);
    }

    function convertTokenAmountWithPrice(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals,
        uint256 price
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);

        amount = (tokenAmount * int256(tokenWad)) * int256(price) / int256(targetTokenWad) / int256(PrecisionUtils.PRICE_PRECISION);
    }

    function convertStableAmountToIndex(
        IPool.Pair memory pair,
        int256 stableTokenAmount
    ) internal view returns (int256 amount) {
        if (stableTokenAmount == 0) return 0;

        uint8 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        return convertTokenAmountTo(pair.stableToken, stableTokenAmount, indexTokenDec);
    }

    function convertTokenAmountTo(
        address token,
        int256 tokenAmount,
        uint8 targetDecimals
    ) internal view returns (int256 amount) {
        if (tokenAmount == 0) return 0;

        uint256 tokenDec = uint256(IERC20Metadata(token).decimals());

        uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
        uint256 targetTokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - targetDecimals);
        amount = (tokenAmount * int256(tokenWad)) / int256(targetTokenWad);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../libraries/PrecisionUtils.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IOraclePriceFeed.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IBacktracker.sol";
import "../helpers/TokenHelper.sol";
import "../libraries/Int256Utils.sol";

library TradingHelper {
    using PrecisionUtils for uint256;
    using Int256Utils for int256;

    function getValidPrice(
        IAddressesProvider addressesProvider,
        address token,
        IPool.TradingConfig memory tradingConfig
    ) internal view returns (uint256) {
        bool backtracking = IBacktracker(addressesProvider.backtracker()).backtracking();
        if (backtracking) {
            uint64 backtrackRound = IBacktracker(addressesProvider.backtracker()).backtrackRound();
            return IOraclePriceFeed(addressesProvider.priceOracle()).getHistoricalPrice(backtrackRound, token);
        }
        uint256 oraclePrice = IPriceFeed(addressesProvider.priceOracle()).getPriceSafely(token);
        uint256 indexPrice = IPriceFeed(addressesProvider.indexPriceOracle()).getPrice(token);

        uint256 diffP = oraclePrice > indexPrice
            ? oraclePrice - indexPrice
            : indexPrice - oraclePrice;
        diffP = diffP.calculatePercentage(oraclePrice);

        require(diffP <= tradingConfig.maxPriceDeviationP, "exceed max price deviation");
        return oraclePrice;
    }

    function exposureAmountChecker(
        IPool.Vault memory lpVault,
        IPool.Pair memory pair,
        int256 exposedPositions,
        bool isLong,
        uint256 orderSize,
        uint256 executionPrice
    ) internal view returns (uint256 executionSize) {
        executionSize = orderSize;

        uint256 available = maxAvailableLiquidity(lpVault, pair, exposedPositions, isLong, executionPrice);
        if (executionSize > available) {
            executionSize = available;
        }
        return executionSize;
    }

    function maxAvailableLiquidity(
        IPool.Vault memory lpVault,
        IPool.Pair memory pair,
        int256 exposedPositions,
        bool isLong,
        uint256 executionPrice
    ) internal view returns (uint256 amount) {
        if (exposedPositions >= 0) {
            if (isLong) {
                amount = lpVault.indexTotalAmount >= lpVault.indexReservedAmount ?
                    lpVault.indexTotalAmount - lpVault.indexReservedAmount : 0;
            } else {
                int256 availableStable = int256(lpVault.stableTotalAmount) - int256(lpVault.stableReservedAmount);
                int256 stableToIndexAmount = TokenHelper.convertStableAmountToIndex(
                    pair,
                    availableStable
                );
                if (stableToIndexAmount < 0) {
                    if (uint256(exposedPositions) <= stableToIndexAmount.abs().divPrice(executionPrice)) {
                        amount = 0;
                    } else {
                        amount = uint256(exposedPositions) - stableToIndexAmount.abs().divPrice(executionPrice);
                    }
                } else {
                    amount = uint256(exposedPositions) + stableToIndexAmount.abs().divPrice(executionPrice);
                }
            }
        } else {
            if (isLong) {
                int256 availableIndex = int256(lpVault.indexTotalAmount) - int256(lpVault.indexReservedAmount);
                if (availableIndex > 0) {
                    amount = uint256(-exposedPositions) + availableIndex.abs();
                } else {
                    amount = uint256(-exposedPositions) >= availableIndex.abs() ?
                        uint256(-exposedPositions) - availableIndex.abs() : 0;
                }
            } else {
                int256 availableStable = int256(lpVault.stableTotalAmount) - int256(lpVault.stableReservedAmount);
                int256 stableToIndexAmount = TokenHelper.convertStableAmountToIndex(
                    pair,
                    availableStable
                );
                if (stableToIndexAmount < 0) {
                    amount = 0;
                } else {
                    amount = stableToIndexAmount.abs().divPrice(executionPrice);
                }
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPool.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/TradingTypes.sol";

library ValidationHelper {
    using PrecisionUtils for uint256;

    function validateAccountBlacklist(
        IAddressesProvider addressesProvider,
        address account
    ) internal view {
        require(
            !IRoleManager(addressesProvider.roleManager()).isBlackList(account),
            "blacklist account"
        );
    }

    function validatePriceTriggered(
        IPool.TradingConfig memory tradingConfig,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        bool isLong,
        bool isAbove,
        uint256 currentPrice,
        uint256 orderPrice,
        uint256 maxSlippage
    ) internal pure {
        if (tradeType == TradingTypes.TradeType.MARKET) {
            bool valid;
            if ((isIncrease && isLong) || (!isIncrease && !isLong)) {
                valid = currentPrice <= orderPrice.mulPercentage(PrecisionUtils.percentage() + maxSlippage);
            } else {
                valid = currentPrice >= orderPrice.mulPercentage(PrecisionUtils.percentage() - maxSlippage);
            }
            require(maxSlippage == 0 || valid, "exceeds max slippage");
        } else if (tradeType == TradingTypes.TradeType.LIMIT) {
            require(
                isAbove
                    ? currentPrice.mulPercentage(
                        PrecisionUtils.percentage() - tradingConfig.priceSlipP
                    ) <= orderPrice
                    : currentPrice.mulPercentage(
                        PrecisionUtils.percentage() + tradingConfig.priceSlipP
                    ) >= orderPrice,
                "not reach trigger price"
            );
        } else {
            require(
                isAbove ? currentPrice <= orderPrice : currentPrice >= orderPrice,
                "not reach trigger price"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface AggregatorV3Interface {
    function description() external view returns (string memory);

    // function aggregator() external view returns (address);

    function latestAnswer() external view returns (int256);

    // function latestRound() external view returns (uint80);

    function getRoundData(
        uint80 roundId
    ) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAddressesProvider {
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    function WETH() external view returns (address);

    function timelock() external view returns (address);

    function priceOracle() external view returns (address);

    function indexPriceOracle() external view returns (address);

    function fundingRate() external view returns (address);

    function executionLogic() external view returns (address);

    function liquidationLogic() external view returns (address);

    function roleManager() external view returns (address);

    function backtracker() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBacktracker {

    event Backtracking(address account, uint64 round);

    event UnBacktracking(address account);

    event UpdatedExecutorAddress(address sender, address oldAddress, address newAddress);

    function backtracking() external view returns (bool);

    function backtrackRound() external view returns (uint64);

    function enterBacktracking(uint64 _backtrackRound) external;

    function quitBacktracking() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IChainlinkFlags {
    function getFlag(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOraclePriceFeed.sol";

interface IChainlinkPriceFeed is IOraclePriceFeed {

    event FeedUpdate(address asset, address feed);

    event UpdatedExecutorAddress(address sender, address oldAddress, address newAddress);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../libraries/TradingTypes.sol';
import '../libraries/Position.sol';

interface IExecution {

    event ExecuteIncreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        bool isLong,
        int256 collateral,
        uint256 orderSize,
        uint256 orderPrice,
        uint256 executionSize,
        uint256 executionPrice,
        uint256 executedSize,
        uint256 tradingFee,
        int256 fundingFee,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event ExecuteDecreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        bool isLong,
        int256 collateral,
        uint256 orderSize,
        uint256 orderPrice,
        uint256 executionSize,
        uint256 executionPrice,
        uint256 executedSize,
        bool needADL,
        int256 pnl,
        uint256 tradingFee,
        int256 fundingFee,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event ExecuteAdlOrder(
        uint256[] adlOrderIds,
        bytes32[] adlPositionKeys,
        uint256[] orders
    );

    event ExecuteOrderError(uint256 orderId, string errorMessage);
    event ExecutePositionError(bytes32 positionKey, string errorMessage);

    event InvalidOrder(address sender, uint256 orderId, string message);
    event ZeroPosition(address sender, address account, uint256 pairIndex, bool isLong, string message);

    struct ExecutePosition {
        bytes32 positionKey;
        uint256 sizeAmount;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    struct LiquidatePosition {
        address token;
        bytes updateData;
        uint256 updateFee;
        uint64 backtrackRound;
        bytes32 positionKey;
        uint256 sizeAmount;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    struct PositionOrder {
        address account;
        uint256 pairIndex;
        bool isLong;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/TradingTypes.sol";
import "../libraries/Position.sol";
import "./IExecution.sol";

interface IExecutionLogic is IExecution {
    event UpdateMaxTimeDelay(uint256 oldDelay, uint256 newDelay);

    event UpdateExecutorAddress(address sender, address oldAddress, address newAddress);

    struct ExecuteOrder {
        uint256 orderId;
        TradingTypes.TradeType tradeType;
        bool isIncrease;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    struct ExecutePositionInfo {
        Position.Info position;
        uint256 executionSize;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    function maxTimeDelay() external view returns (uint256);

    function updateExecutor(address _executor) external;

    function updateMaxTimeDelay(uint256 newMaxTimeDelay) external;

    function executeIncreaseOrders(
        address keeper,
        ExecuteOrder[] memory orders,
        TradingTypes.TradeType tradeType
    ) external;

    function executeIncreaseOrder(
        address keeper,
        uint256 _orderId,
        TradingTypes.TradeType _tradeType,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external;

    function executeDecreaseOrders(
        address keeper,
        ExecuteOrder[] memory orders,
        TradingTypes.TradeType tradeType
    ) external;

    function executeDecreaseOrder(
        address keeper,
        uint256 _orderId,
        TradingTypes.TradeType _tradeType,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        bool isSystem,
        uint256 executionSize,
        bool onlyOnce
    ) external;

    function executeADLAndDecreaseOrders(
        address keeper,
        uint256 pairIndex,
        ExecutePosition[] memory executePositions,
        IExecutionLogic.ExecuteOrder[] memory executeOrders
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../libraries/TradingTypes.sol';
import "./IExecutionLogic.sol";

interface IExecutor is IExecution {

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    function setPricesAndExecuteOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory orders
    ) external payable;

    function setPricesAndExecuteIncreaseMarketOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory increaseOrders
    ) external payable;

    function setPricesAndExecuteDecreaseMarketOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory decreaseOrders
    ) external payable;

    function setPricesAndExecuteIncreaseLimitOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory increaseOrders
    ) external payable;

    function setPricesAndExecuteDecreaseLimitOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        IExecutionLogic.ExecuteOrder[] memory decreaseOrders
    ) external payable;

    function setPricesAndExecuteADLOrders(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        uint64[] memory publishTimes,
        uint256 pairIndex,
        IExecution.ExecutePosition[] memory executePositions,
        IExecutionLogic.ExecuteOrder[] memory executeOrders
    ) external payable;

    function setPricesAndLiquidatePositions(
        address[] memory _tokens,
        uint256[] memory _prices,
        LiquidatePosition[] memory liquidatePositions
    ) external payable;

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool need, uint256 needADLAmount);

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPool.sol";
import "../libraries/TradingTypes.sol";
import "./IPositionManager.sol";

interface IFeeCollector {

    event UpdatedTradingFeeTier(
        address sender,
        uint8 tier,
        uint256 oldTakerFee,
        int256 oldMakerFee,
        uint256 newTakerFee,
        int256 newMakerFee
    );

    event UpdateMaxReferralsRatio(uint256 oldRatio, uint256 newRatio);

    event UpdatedStakingPoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePoolAddress(address sender, address oldAddress, address newAddress);
    event UpdatePledgeAddress(address sender, address oldAddress, address newAddress);

    event UpdatedPositionManagerAddress(address sender, address oldAddress, address newAddress);

    event UpdateExecutionLogicAddress(address sender, address oldAddress, address newAddress);

    event DistributeTradingFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        uint256 regularTradingFee,
        bool isMaker,
        int256 feeRate,
        int256 vipTradingFee,
        uint256 returnAmount,
        uint256 referralsAmount,
        uint256 referralUserAmount,
        address referralOwner,
        int256 lpAmount,
        int256 keeperAmount,
        int256 stakingAmount,
        int256 reservedAmount,
        int256 ecoFundAmount,
        int256 treasuryAmount
    );

    event ClaimedStakingTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedDistributorTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedReferralsTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedUserTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperTradingFee(address account, address claimToken, uint256 amount);

    event ClaimedKeeperNetworkFee(address account, address claimToken, uint256 amount);

    struct TradingFeeTier {
        int256 makerFee;
        uint256 takerFee;
    }

    function maxReferralsRatio() external view returns (uint256 maxReferenceRatio);

    function stakingTradingFee() external view returns (uint256);
    function stakingTradingFeeDebt() external view returns (uint256);

    function treasuryFee() external view returns (uint256);

    function treasuryFeeDebt() external view returns (uint256);

    function reservedTradingFee() external view returns (int256);

    function ecoFundTradingFee() external view returns (int256);

    function userTradingFee(address _account) external view returns (uint256);

    function keeperTradingFee(address _account) external view returns (int256);

    function referralFee(address _referralOwner) external view returns (uint256);

    function getTradingFeeTier(uint256 pairIndex, uint8 tier) external view returns (TradingFeeTier memory);

    function getRegularTradingFeeTier(uint256 pairIndex) external view returns (TradingFeeTier memory);

    function getKeeperNetworkFee(
        address account,
        TradingTypes.InnerPaymentType paymentType
    ) external view returns (uint256);

    function updateMaxReferralsRatio(uint256 newRatio) external;

    function claimStakingTradingFee() external returns (uint256);

    function claimTreasuryFee() external returns (uint256);

    function claimReferralFee() external returns (uint256);

    function claimUserTradingFee() external returns (uint256);

    function claimKeeperTradingFee() external returns (uint256);

    function claimKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType
    ) external returns (uint256);

    struct RescueKeeperNetworkFee {
        address keeper;
        address receiver;
    }

    function rescueKeeperNetworkFee(
        TradingTypes.InnerPaymentType paymentType,
        RescueKeeperNetworkFee[] calldata rescues
    ) external;

    function distributeTradingFee(
        IPool.Pair memory pair,
        address account,
        uint256 orderId,
        address keeper,
        uint256 size,
        uint256 sizeDelta,
        uint256 executionPrice,
        uint256 tradingFee,
        bool isMaker,
        TradingFeeTier memory tradingFeeTier,
        int256 exposureAmount,
        int256 afterExposureAmount,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external returns (int256 lpAmount, int256 vipTradingFee, uint256 givebackFeeAmount);

    function distributeNetworkFee(
        address keeper,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPool.sol";

interface IFundingRate {
    struct FundingFeeConfig {
        int256 growthRate; // Growth rate base
        int256 baseRate; // Base interest rate
        int256 maxRate; // Maximum interest rate
        uint256 fundingInterval;
    }

    function getFundingInterval(uint256 _pairIndex) external view returns (uint256);

    function getFundingRate(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) external view returns (int256 fundingRate);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IPriceFeed.sol";

interface IIndexPriceFeed is IPriceFeed {

    event UpdateExecutorAddress(address sender, address oldAddress, address newAddress);

    event PriceUpdate(address asset, uint256 price, address sender);

    function updatePrice(address[] calldata tokens, uint256[] memory prices) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IExecution.sol";

interface ILiquidationLogic is IExecution {

    event ExecuteLiquidation(
        bytes32 positionKey,
        address account,
        uint256 pairIndex,
        bool isLong,
        uint256 collateral,
        uint256 sizeAmount,
        uint256 price,
        uint256 orderId
    );

    event UpdateExecutorAddress(address sender, address oldAddress, address newAddress);

    function updateExecutor(address _executor) external;

    function liquidationPosition(
        address keeper,
        bytes32 positionKey,
        uint8 tier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner
    ) external;

    function cleanInvalidPositionOrders(
        bytes32[] calldata positionKeys
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ILiquidityCallback {
    function addLiquidityCallback(
        address indexToken,
        address stableToken,
        uint256 amountIndex,
        uint256 amountStable,
        bytes calldata data
    ) external;

    function removeLiquidityCallback(address poolToken, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IPeripheryImmutableState.sol";
import "./IPoolInitializer.sol";

interface INonfungiblePositionManager is IPeripheryImmutableState, IPoolInitializer {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    function factory() external view returns (address);

    function getPositionInfo(
        address factory,
        uint256 tokenId
    ) external view returns (address pool, int24 tickLower, int24 tickUpper, uint128 liquidity);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPriceFeed} from "./IPriceFeed.sol";

interface IOraclePriceFeed is IPriceFeed {

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 backtrackRound
    ) external payable;

    function removeHistoricalPrice(
        uint64 backtrackRound,
        address[] calldata tokens
    ) external;

    function getHistoricalPrice(
        uint64 backtrackRound,
        address token
    ) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IOrderCallback {
    function createOrderCallback(address collateral, uint256 amount, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../libraries/TradingTypes.sol';

interface IOrderManager {
    event UpdatePositionManager(address oldAddress, address newAddress);
    event CancelOrder(uint256 orderId, TradingTypes.TradeType tradeType, string reason);

    event CreateIncreaseOrder(
        address account,
        uint256 orderId,
        uint256 pairIndex,
        TradingTypes.TradeType tradeType,
        int256 collateral,
        uint256 openPrice,
        bool isLong,
        uint256 sizeAmount,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event CreateDecreaseOrder(
        address account,
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        int256 collateral,
        uint256 pairIndex,
        uint256 openPrice,
        uint256 sizeAmount,
        bool isLong,
        bool abovePrice,
        TradingTypes.InnerPaymentType paymentType,
        uint256 networkFeeAmount
    );

    event UpdateRouterAddress(address sender, address oldAddress, address newAddress);

    event CancelIncreaseOrder(address account, uint256 orderId, TradingTypes.TradeType tradeType);
    event CancelDecreaseOrder(address account, uint256 orderId, TradingTypes.TradeType tradeType);

    event UpdatedNetworkFee(
        address sender,
        TradingTypes.NetworkFeePaymentType paymentType,
        uint256 pairIndex,
        uint256 basicNetworkFee,
        uint256 discountThreshold,
        uint256 discountedNetworkFee
    );

    struct PositionOrder {
        address account;
        uint256 pairIndex;
        bool isLong;
        bool isIncrease;
        TradingTypes.TradeType tradeType;
        uint256 orderId;
        uint256 sizeAmount;
    }

    struct NetworkFee {
        uint256 basicNetworkFee;
        uint256 discountThreshold;
        uint256 discountedNetworkFee;
    }

    function ordersIndex() external view returns (uint256);

    function getPositionOrders(bytes32 key) external view returns (PositionOrder[] memory);

    function getNetworkFee(TradingTypes.NetworkFeePaymentType paymentType, uint256 pairIndex) external view returns (NetworkFee memory);

    function createOrder(TradingTypes.CreateOrderRequest memory request) external payable returns (uint256 orderId);

    function cancelOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        string memory reason
    ) external;

    function cancelAllPositionOrders(address account, uint256 pairIndex, bool isLong) external;

    function getIncreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) external view returns (
        TradingTypes.IncreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    );

    function getDecreaseOrder(
        uint256 orderId,
        TradingTypes.TradeType tradeType
    ) external view returns (
        TradingTypes.DecreasePositionOrder memory order,
        TradingTypes.OrderNetworkFee memory orderNetworkFee
    );

    function increaseOrderExecutedSize(
        uint256 orderId,
        TradingTypes.TradeType tradeType,
        bool isIncrease,
        uint256 increaseSize
    ) external;

    function removeOrderFromPosition(PositionOrder memory order) external;

    function removeIncreaseMarketOrders(uint256 orderId) external;

    function removeIncreaseLimitOrders(uint256 orderId) external;

    function removeDecreaseMarketOrders(uint256 orderId) external;

    function removeDecreaseLimitOrders(uint256 orderId) external;

    function setOrderNeedADL(uint256 orderId, TradingTypes.TradeType tradeType, bool needADL) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
    // Events
    event PairAdded(
        address indexed indexToken,
        address indexed stableToken,
        address lpToken,
        uint256 index
    );

    event UpdateTotalAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexTotalAmount,
        uint256 stableTotalAmount
    );

    event UpdateReserveAmount(
        uint256 indexed pairIndex,
        int256 indexAmount,
        int256 stableAmount,
        uint256 indexReservedAmount,
        uint256 stableReservedAmount
    );

    event UpdateLPProfit(
        uint256 indexed pairIndex,
        address token,
        int256 profit,
        uint256 totalAmount
    );

    event GivebackTradingFee(
        uint256 indexed pairIndex,
        address token,
        uint256 amount
    );

    event UpdateAveragePrice(uint256 indexed pairIndex, uint256 averagePrice);

    event UpdateSpotSwap(address sender, address oldAddress, address newAddress);

    event UpdatePoolView(address sender, address oldAddress, address newAddress);

    event UpdateRouter(address sender, address oldAddress, address newAddress);

    event UpdateRiskReserve(address sender, address oldAddress, address newAddress);

    event UpdateFeeCollector(address sender, address oldAddress, address newAddress);

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    event UpdateOrderManager(address sender, address oldAddress, address newAddress);

    event AddStableToken(address sender, address token);

    event RemoveStableToken(address sender, address token);

    event AddLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 indexFeeAmount,
        uint256 stableFeeAmount,
        address slipToken,
        uint256 slipFeeAmount,
        uint256 lpPrice
    );

    event RemoveLiquidity(
        address indexed recipient,
        uint256 indexed pairIndex,
        uint256 indexAmount,
        uint256 stableAmount,
        uint256 lpAmount,
        uint256 feeAmount,
        uint256 lpPrice
    );

    event ClaimedFee(address sender, address token, uint256 amount);

    struct Vault {
        uint256 indexTotalAmount; // total amount of tokens
        uint256 indexReservedAmount; // amount of tokens reserved for open positions
        uint256 stableTotalAmount;
        uint256 stableReservedAmount;
        uint256 averagePrice;
    }

    struct Pair {
        uint256 pairIndex;
        address indexToken;
        address stableToken;
        address pairToken;
        bool enable;
        uint256 kOfSwap; //Initial k value of liquidity
        uint256 expectIndexTokenP; //   for 100%
        uint256 maxUnbalancedP;
        uint256 unbalancedDiscountRate;
        uint256 addLpFeeP; // Add liquidity fee
        uint256 removeLpFeeP; // remove liquidity fee
    }

    struct TradingConfig {
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 maxPositionAmount;
        uint256 maintainMarginRate; // Maintain the margin rate of  for 100%
        uint256 priceSlipP; // Price slip point
        uint256 maxPriceDeviationP; // Maximum offset of index price
    }

    struct TradingFeeConfig {
        uint256 lpFeeDistributeP;
        uint256 stakingFeeDistributeP;
        uint256 keeperFeeDistributeP;
        uint256 treasuryFeeDistributeP;
        uint256 reservedFeeDistributeP;
        uint256 ecoFundFeeDistributeP;
    }

    function pairsIndex() external view returns (uint256);

    function getPairIndex(address indexToken, address stableToken) external view returns (uint256);

    function getPair(uint256) external view returns (Pair memory);

    function getTradingConfig(uint256 _pairIndex) external view returns (TradingConfig memory);

    function getTradingFeeConfig(uint256) external view returns (TradingFeeConfig memory);

    function getVault(uint256 _pairIndex) external view returns (Vault memory vault);

    function transferTokenTo(address token, address to, uint256 amount) external;

    function transferEthTo(address to, uint256 amount) external;

    function transferTokenOrSwap(
        uint256 pairIndex,
        address token,
        address to,
        uint256 amount
    ) external;

    function getLpPnl(
        uint256 _pairIndex,
        bool lpIsLong,
        uint amount,
        uint256 _price
    ) external view returns (int256);

    function lpProfit(
        uint pairIndex,
        address token,
        uint256 price
    ) external view returns (int256);

    function increaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function decreaseReserveAmount(
        uint256 _pairToken,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external;

    function updateAveragePrice(uint256 _pairIndex, uint256 _averagePrice) external;

    function setLPStableProfit(uint256 _pairIndex, int256 _profit) external;

    function givebackTradingFee(
        uint256 pairIndex,
        uint256 amount
    ) external;

    function getAvailableLiquidity(uint256 pairIndex, uint256 price) external view returns(int256 v, int256 u, int256 e);

    function addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) external returns (uint256 mintAmount, address slipToken, uint256 slipAmount);

    function removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    )
        external
        returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount);

    function claimFee(address token, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPoolToken {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPoolTokenFactory {
    function createPoolToken(address indexToken, address stableToken) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolView {

    event UpdatePool(address sender, address oldAddress, address newAddress);

    event UpdatePositionManager(address sender, address oldAddress, address newAddress);

    function getMintLpAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        uint256 price
    ) external view returns (
            uint256 mintAmount,
            address slipToken,
            uint256 slipAmount,
            uint256 indexFeeAmount,
            uint256 stableFeeAmount,
            uint256 afterFeeIndexAmount,
            uint256 afterFeeStableAmount
        );

    function getDepositAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (uint256 depositIndexAmount, uint256 depositStableAmount);

    function getReceivedAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (
        uint256 receiveIndexTokenAmount,
        uint256 receiveStableTokenAmount,
        uint256 feeAmount,
        uint256 feeIndexTokenAmount,
        uint256 feeStableTokenAmount
    );

    function lpFairPrice(uint256 _pairIndex, uint256 price) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import '../libraries/Position.sol';
import "./IFeeCollector.sol";

enum PositionStatus {
    Balance,
    NetLong,
    NetShort
}

interface IPositionManager {
    event UpdateFundingInterval(uint256 oldInterval, uint256 newInterval);

    event UpdatePosition(
        address account,
        bytes32 positionKey,
        uint256 pairIndex,
        uint256 orderId,
        bool isLong,
        uint256 beforCollateral,
        uint256 afterCollateral,
        uint256 price,
        uint256 beforPositionAmount,
        uint256 afterPositionAmount,
        uint256 averagePrice,
        int256 fundFeeTracker,
        int256 pnl
    );

    event UpdatedExecutionLogic(address sender, address oldAddress, address newAddress);

    event UpdatedLiquidationLogic(address sender, address oldAddress, address newAddress);

    event UpdateRouterAddress(address sender, address oldAddress, address newAddress);

    event UpdateFundingRate(uint256 pairIndex, uint price, int256 fundingRate, uint256 lastFundingTime);

    event TakeFundingFeeAddTraderFeeV2(
        address account,
        uint256 pairIndex,
        uint256 orderId,
        uint256 sizeDelta,
        int256 fundingFee,
        uint256 regularTradingFee,
        int256 vipTradingFee,
        uint256 returnAmount,
        int256 lpTradingFee
    );

    event AdjustCollateral(
        address account,
        uint256 pairIndex,
        bool isLong,
        bytes32 positionKey,
        uint256 collateralBefore,
        uint256 collateralAfter
    );

    function getExposedPositions(uint256 pairIndex) external view returns (int256);

    function longTracker(uint256 pairIndex) external view returns (uint256);

    function shortTracker(uint256 pairIndex) external view returns (uint256);

    function getTradingFee(
        uint256 _pairIndex,
        bool _isLong,
        bool _isIncrease,
        uint256 _sizeAmount,
        uint256 price
    ) external view returns (uint256 tradingFee);

    function getFundingFee(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (int256 fundingFee);

    function getCurrentFundingRate(uint256 _pairIndex) external view returns (int256);

    function getNextFundingRate(uint256 _pairIndex, uint256 price) external view returns (int256);

    function getNextFundingRateUpdateTime(uint256 _pairIndex) external view returns (uint256);

    function needADL(
        uint256 pairIndex,
        bool isLong,
        uint256 executionSize,
        uint256 executionPrice
    ) external view returns (bool needADL, uint256 needADLAmount);

    function needLiquidation(
        bytes32 positionKey,
        uint256 price
    ) external view returns (bool);

    function getPosition(
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) external view returns (Position.Info memory);

    function getPositionByKey(bytes32 key) external view returns (Position.Info memory);

    function getPositionKey(address _account, uint256 _pairIndex, bool _isLong) external pure returns (bytes32);

    function increasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price
    ) external returns (uint256 tradingFee, int256 fundingFee);

    function decreasePosition(
        uint256 _pairIndex,
        uint256 orderId,
        address _account,
        address _keeper,
        uint256 _sizeAmount,
        bool _isLong,
        int256 _collateral,
        IFeeCollector.TradingFeeTier memory tradingFeeTier,
        uint256 referralsRatio,
        uint256 referralUserRatio,
        address referralOwner,
        uint256 _price,
        bool useRiskReserve
    ) external returns (uint256 tradingFee, int256 fundingFee, int256 pnl);

    function adjustCollateral(uint256 pairIndex, address account, bool isLong, int256 collateral) external;

    function updateFundingRate(uint256 _pairIndex) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceFeed {

    event PriceAgeUpdated(uint256 oldAge, uint256 newAge);

    function getPrice(address token) external view returns (uint256);

    function getPriceSafely(address token) external view returns (uint256);

    function decimals() external pure returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

interface IPythOracle is IPyth {

    function latestPriceInfoPublishTime(
        bytes32 priceId
    ) external view returns (uint64);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOraclePriceFeed.sol";

interface IPythOraclePriceFeed is IOraclePriceFeed {

    event TokenPriceIdUpdated(
        address token,
        bytes32 priceId
    );

    event PythPriceUpdated(address token, uint256 price, uint64 publishTime);

    event PythAddressUpdated(address oldAddress, address newAddress);

    event UpdatedExecutorAddress(address sender, address oldAddress, address newAddress);

    event UnneededPricePublishWarn();

    function updatePrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IRiskReserve {

    event UpdatedDaoAddress(
        address sender,
        address oldAddress,
        address newAddress
    );

    event UpdatedPositionManagerAddress(
        address sender,
        address oldAddress,
        address newAddress
    );

    event UpdatedPoolAddress(
        address sender,
        address oldAddress,
        address newAddress
    );

    event Withdraw(
        address sender,
        address asset,
        uint256 amount,
        address to
    );

    function updateDaoAddress(address newAddress) external;

    function updatePositionManagerAddress(address newAddress) external;

    function updatePoolAddress(address newAddress) external;

    function increase(address asset, uint256 amount) external;

    function decrease(address asset, uint256 amount) external;

    function recharge(address asset, uint256 amount) external;

    function withdraw(address asset, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IRoleManager {
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function isAdmin(address) external view returns (bool);

    function isPoolAdmin(address poolAdmin) external view returns (bool);

    function isOperator(address operator) external view returns (bool);

    function isTreasurer(address treasurer) external view returns (bool);

    function isKeeper(address) external view returns (bool);

    function isBlackList(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/TradingTypes.sol";

interface IRouter {
    struct AddOrderTpSlRequest {
        uint256 orderId;
        TradingTypes.TradeType tradeType;
        bool isIncrease;
        uint256 tpPrice; // Stop profit price 1e30
        uint128 tp; // The number of profit stops
        uint256 slPrice; // Stop price 1e30
        uint128 sl; // Stop loss quantity
        TradingTypes.NetworkFeePaymentType paymentType;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct CancelOrderRequest {
        uint256 orderId;
        TradingTypes.TradeType tradeType;
        bool isIncrease;
    }

    struct OperationStatus {
        bool increasePositionDisabled;
        bool decreasePositionDisabled;
        bool orderDisabled;
        bool addLiquidityDisabled;
        bool removeLiquidityDisabled;
    }

    event UpdateTradingRouter(address oldAddress, address newAddress);

    event UpdateIncreasePositionStatus(address sender, uint256 pairIndex, bool enabled);
    event UpdateDecreasePositionStatus(address sender, uint256 pairIndex, bool enabled);
    event UpdateOrderStatus(address sender, uint256 pairIndex, bool enabled);
    event UpdateAddLiquidityStatus(address sender, uint256 pairIndex, bool enabled);
    event UpdateRemoveLiquidityStatus(address sender, uint256 pairIndex, bool enabled);

    function getOperationStatus(uint256 pairIndex) external view returns (OperationStatus memory);


    function createIncreaseOrder(
        TradingTypes.IncreasePositionRequest memory request
    ) external payable returns (uint256 orderId);

    function createDecreaseOrder(
        TradingTypes.DecreasePositionRequest memory request
    ) external payable returns (uint256);


    function cancelOrders(
        CancelOrderRequest[] memory requests
    ) external;

    function setPriceAndAdjustCollateral(
        uint256 pairIndex,
        bool isLong,
        int256 collateral,
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";

interface ISpotSwap {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external ;

    function getSwapData(
        IPool.Pair memory pair,
        address _tokenOut,
        uint256 _expectAmountOut
    ) external view returns (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapCallback {
    function swapCallback(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/TradingTypes.sol";

interface IUiPoolDataProvider {

    struct PairData {
        uint256 pairIndex;
        address indexToken;
        address stableToken;
        address pairToken;
        bool increasePositionIsEnabled;
        bool decreasePositionIsEnabled;
        bool orderIsEnabled;
        bool addLiquidityIsEnabled;
        bool removeLiquidityIsEnabled;
        bool enable;
        uint256 kOfSwap;
        uint256 expectIndexTokenP;
        uint256 maxUnbalancedP;
        uint256 unbalancedDiscountRate;
        uint256 addLpFeeP;
        uint256 removeLpFeeP;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 minTradeAmount;
        uint256 maxTradeAmount;
        uint256 maxPositionAmount;
        uint256 maintainMarginRate;
        uint256 priceSlipP;
        uint256 maxPriceDeviationP;
        uint256 takerFee;
        int256 makerFee;
        uint256 lpFeeDistributeP;
        uint256 stakingFeeDistributeP;
        uint256 keeperFeeDistributeP;
        uint256 indexTotalAmount;
        uint256 indexReservedAmount;
        uint256 stableTotalAmount;
        uint256 stableReservedAmount;
        uint256 poolAvgPrice;
        uint256 longTracker;
        uint256 shortTracker;
        int256 currentFundingRate;
        int256 nextFundingRate;
        uint256 nextFundingRateUpdateTime;
        uint256 lpPrice;
        uint256 lpTotalSupply;
        NetworkFeeData[] networkFees;
    }

    struct NetworkFeeData {
        TradingTypes.NetworkFeePaymentType paymentType;
        uint256 basicNetworkFee;
        uint256 discountThreshold;
        uint256 discountedNetworkFee;
    }

    struct UserTokenData {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint256 balance;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUiPositionDataProvider {

    struct PositionData {
        uint256 pairIndex;
        int256 exposedPositions;
        uint256 longTracker;
        uint256 shortTracker;
        uint256 indexTotalAmount;
        uint256 indexReservedAmount;
        uint256 stableTotalAmount;
        uint256 stableReservedAmount;
        uint256 poolAvgPrice;
        int256 currentFundingRate;
        int256 nextFundingRate;
        uint256 nextFundingRateUpdateTime;
        uint256 lpPrice;
        uint256 lpTotalSupply;
        uint256 longLiquidity;
        uint256 shortLiquidity;
    }

    struct UserPositionData {
        address account;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
        int256 fundingFeeTracker;
    }

    struct UserPositionDataV2 {
        bytes32 key;
        address account;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
        int256 fundingFeeTracker;
        uint256 positionCloseTradingFee;
        int256 positionFundingFee;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;
pragma abicoder v2;



/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniSwapV3Router  {
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

library AMMUtils {
    function getReserve(
        uint256 k,
        uint256 price,
        uint256 pricePrecision
    ) internal pure returns (uint256 reserveA, uint256 reserveB) {
        require(price > 0, "Invalid price");
        require(k > 0, "Invalid k");

        reserveA = Math.sqrt(Math.mulDiv(k, pricePrecision, price));
        reserveB = k / reserveA;
        return (reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }

        require(reserveIn > 0 && reserveOut > 0, "Invalid reserve");
        amountOut = Math.mulDiv(amountIn, reserveOut, reserveIn + amountIn);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library AmountMath {
    using Math for uint256;
    using SafeMath for uint256;
    uint256 public constant PRICE_PRECISION = 1e30;

    function getStableDelta(uint256 amount, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(amount, price, PRICE_PRECISION);
    }

    function getIndexAmount(uint256 delta, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "onlyPoolAdmin"; // The caller of the function is not a pool admin
    string public constant NOT_ADDRESS_ZERO = "is 0"; // The caller of the function is not a pool admin
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library Int256Utils {
    using Strings for uint256;

    function abs(int256 a) internal pure returns (uint256) {
        return a >= 0 ? uint256(a) : uint256(-a);
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function safeConvertToInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "Value too large to fit in int256.");
        return int256(value);
    }

    function toString(int256 amount) internal pure returns (string memory) {
        return string.concat(amount >= 0 ? '' : '-', abs(amount).toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
pragma abicoder v2;

import '../interfaces/IMulticall.sol';

abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import '../libraries/PrecisionUtils.sol';
import '../libraries/Int256Utils.sol';
import '../libraries/TradingTypes.sol';
import '../libraries/PositionKey.sol';
import "../interfaces/IPool.sol";
import "../helpers/TokenHelper.sol";

library Position {
    using Int256Utils for int256;
    using Math for uint256;
    using PrecisionUtils for uint256;

    struct Info {
        address account;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
        int256 fundingFeeTracker;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        address _account,
        uint256 _pairIndex,
        bool _isLong
    ) internal view returns (Position.Info storage position) {
        position = self[PositionKey.getPositionKey(_account, _pairIndex, _isLong)];
    }

    function getPositionByKey(
        mapping(bytes32 => Info) storage self,
        bytes32 key
    ) internal view returns (Position.Info storage position) {
        position = self[key];
    }

    function init(Info storage self, uint256 pairIndex, address account, bool isLong, uint256 oraclePrice) internal {
        self.pairIndex = pairIndex;
        self.account = account;
        self.isLong = isLong;
        self.averagePrice = oraclePrice;
    }

    function getUnrealizedPnl(
        Info memory self,
        IPool.Pair memory pair,
        uint256 _sizeAmount,
        uint256 price
    ) internal view returns (int256 pnl) {
        if (price == self.averagePrice || self.averagePrice == 0 || _sizeAmount == 0) {
            return 0;
        }

        if (self.isLong) {
            if (price > self.averagePrice) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    price - self.averagePrice
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    self.averagePrice - price
                );
            }
        } else {
            if (self.averagePrice > price) {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    int256(_sizeAmount),
                    self.averagePrice - price
                );
            } else {
                pnl = TokenHelper.convertIndexAmountToStableWithPrice(
                    pair,
                    -int256(_sizeAmount),
                    price - self.averagePrice
                );
            }
        }

        return pnl;
    }

    function validLeverage(
        Info memory self,
        IPool.Pair memory pair,
        uint256 price,
        int256 _collateral,
        uint256 _sizeAmount,
        bool _increase,
        uint256 maxLeverage,
        uint256 maxPositionAmount,
        bool simpleVerify,
        int256 fundingFee
    ) internal view returns (uint256, uint256) {
        // only increase collateral
        if (_sizeAmount == 0 && _collateral >= 0) {
            return (self.positionAmount, self.collateral);
        }

        uint256 afterPosition;
        if (_increase) {
            afterPosition = self.positionAmount + _sizeAmount;
        } else {
            afterPosition = self.positionAmount >= _sizeAmount ? self.positionAmount - _sizeAmount : 0;
        }

        if (_increase && afterPosition > maxPositionAmount) {
            revert("exceeds max position");
        }

        int256 availableCollateral = int256(self.collateral) + fundingFee;

        // pnl
        if (!simpleVerify) {
            int256 pnl = getUnrealizedPnl(self, pair, self.positionAmount, price);
            if (!_increase && _sizeAmount > 0 && _sizeAmount < self.positionAmount) {
                if (pnl >= 0) {
                    availableCollateral += getUnrealizedPnl(self, pair, self.positionAmount - _sizeAmount, price);
                } else {
//                    availableCollateral += getUnrealizedPnl(self, pair, _sizeAmount, price);
                    availableCollateral += pnl;
                }
            } else {
                availableCollateral += pnl;
            }
        }

        // adjust collateral
        if (_collateral != 0) {
            availableCollateral += _collateral;
        }
        require(simpleVerify || availableCollateral >= 0, 'collateral not enough');

        if (!simpleVerify && ((_increase && _sizeAmount > 0) || _collateral < 0)) {
            uint256 collateralDec = uint256(IERC20Metadata(pair.stableToken).decimals());
            uint256 tokenDec = uint256(IERC20Metadata(pair.indexToken).decimals());

            uint256 tokenWad = 10 ** (PrecisionUtils.maxTokenDecimals() - tokenDec);
            uint256 collateralWad = 10 ** (PrecisionUtils.maxTokenDecimals() - collateralDec);

            uint256 afterPositionD = afterPosition * tokenWad;
            uint256 availableD = (availableCollateral.abs() * maxLeverage * collateralWad).divPrice(price);
            require(afterPositionD <= availableD, 'exceeds max leverage');
        }

        return (afterPosition, availableCollateral.abs());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PositionKey {
    function getPositionKey(address account, uint256 pairIndex, bool isLong) internal pure returns (bytes32) {
        require(pairIndex < 2 ** (96 - 32), "ptl");
        return bytes32(
            uint256(uint160(account)) << 96 | pairIndex << 32 | (isLong ? 1 : 0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';

library PrecisionUtils {
    uint256 public constant PERCENTAGE = 1e8;
    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant MAX_TOKEN_DECIMALS = 18;

    function mulPrice(uint256 amount, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(amount, price, PRICE_PRECISION);
    }

    function divPrice(uint256 delta, uint256 price) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, price);
    }

    function calculatePrice(uint256 delta, uint256 amount) internal pure returns (uint256) {
        return Math.mulDiv(delta, PRICE_PRECISION, amount);
    }

    function mulPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, _percentage, PERCENTAGE);
    }

    function divPercentage(uint256 amount, uint256 _percentage) internal pure returns (uint256) {
        return Math.mulDiv(amount, PERCENTAGE, _percentage);
    }

    function calculatePercentage(uint256 amount0, uint256 amount1) internal pure returns (uint256) {
        return Math.mulDiv(amount0, PERCENTAGE, amount1);
    }

    function percentage() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function fundingRatePrecision() internal pure returns (uint256) {
        return PERCENTAGE;
    }

    function pricePrecision() internal pure returns (uint256) {
        return PRICE_PRECISION;
    }

    function maxTokenDecimals() internal pure returns (uint256) {
        return MAX_TOKEN_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";

abstract contract Roleable {
    IAddressesProvider public immutable ADDRESS_PROVIDER;

    constructor(IAddressesProvider _addressProvider) {
        ADDRESS_PROVIDER = _addressProvider;
    }

    modifier onlyAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyPoolAdmin() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender),
            "onlyPoolAdmin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TradingTypes {
    enum TradeType {
        MARKET,
        LIMIT,
        TP,
        SL
    }

    enum NetworkFeePaymentType {
        ETH,
        COLLATERAL
    }

    struct CreateOrderRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        int256 sizeAmount; // size
        uint256 maxSlippage;
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
        bytes data;
    }

    struct OrderWithTpSl {
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
    }

    struct IncreasePositionRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint256 sizeAmount; // size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct IncreasePositionWithTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT 2: TP 3: SL
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 openPrice; // 1e30, price
        bool isLong; // long or short
        uint128 sizeAmount; // size
        uint256 tpPrice; // 1e30, tp price
        uint128 tp; // tp size
        uint256 slPrice; // 1e30, sl price
        uint128 sl; // sl size
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType; // 1: eth 2: collateral
        uint256 networkFeeAmount;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct DecreasePositionRequest {
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 collateral amount，negative number is withdrawal
        uint256 triggerPrice; // 1e30, price
        uint256 sizeAmount; // size
        bool isLong;
        uint256 maxSlippage;
        NetworkFeePaymentType paymentType;
        uint256 networkFeeAmount;
    }

    struct CreateTpSlRequest {
        address account;
        uint256 pairIndex; // pair index
        bool isLong;
        uint256 tpPrice; // Stop profit price 1e30
        uint128 tp; // The number of profit stops
        uint256 slPrice; // Stop price 1e30
        uint128 sl; // Stop loss quantity
        NetworkFeePaymentType paymentType;
        uint256 tpNetworkFeeAmount;
        uint256 slNetworkFeeAmount;
    }

    struct IncreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex; // pair index
        TradeType tradeType; // 0: MARKET, 1: LIMIT
        int256 collateral; // 1e18 Margin amount
        uint256 openPrice; // 1e30 Market acceptable price/Limit opening price
        bool isLong; // Long/short
        uint256 sizeAmount; // Number of positions
        uint256 executedSize;
        uint256 maxSlippage;
        uint256 blockTime;
    }

    struct DecreasePositionOrder {
        uint256 orderId;
        address account;
        uint256 pairIndex;
        TradeType tradeType;
        int256 collateral; // 1e18 Margin amount
        uint256 triggerPrice; // Limit trigger price
        uint256 sizeAmount; // Number of customs documents
        uint256 executedSize;
        uint256 maxSlippage;
        bool isLong;
        bool abovePrice; // Above or below the trigger price
        // market：long: true,  short: false
        //  limit：long: false, short: true
        //     tp：long: false, short: true
        //     sl：long: true,  short: false
        uint256 blockTime;
        bool needADL;
    }

    struct OrderNetworkFee {
        InnerPaymentType paymentType;
        uint256 networkFeeAmount;
    }

    enum InnerPaymentType {
        NONE,
        ETH,
        COLLATERAL
    }

    function convertPaymentType(
        NetworkFeePaymentType paymentType
    ) internal pure returns (InnerPaymentType) {
        if (paymentType == NetworkFeePaymentType.ETH) {
            return InnerPaymentType.ETH;
        } else if (paymentType == NetworkFeePaymentType.COLLATERAL) {
            return InnerPaymentType.COLLATERAL;
        } else {
            revert("Invalid payment type");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";

contract Upgradeable is Initializable, UUPSUpgradeable {
    IAddressesProvider public ADDRESS_PROVIDER;

    modifier onlyAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isAdmin(msg.sender), "onlyAdmin");
        _;
    }

    modifier onlyPoolAdmin() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender),
            "onlyPoolAdmin"
        );
        _;
    }

    function _authorizeUpgrade(address) internal virtual override {
        require(msg.sender == ADDRESS_PROVIDER.timelock(), "Unauthorized access");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Faucet is IERC20Permit, ERC20 {
    bytes public constant EIP712_REVISION = bytes('1');
    bytes32 internal constant EIP712_DOMAIN =
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    // Map of address nonces (address => nonce)
    mapping(address => uint256) internal _nonces;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() ERC20('ERC20Faucet', 'ERC20Faucet') {
        uint256 chainId = block.chainid;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes('ERC20Faucet')),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0), 'INVALID_OWNER');
        //solium-disable-next-line
        require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
            )
        );
        require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
        _nonces[owner] = currentValidNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(_msgSender(), value);
        return true;
    }

    /**
     * @dev Function to mint tokens to address
     * @param account The account to mint tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address account, uint256 value) public returns (bool) {
        _mint(account, value);
        return true;
    }

    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Faucet {

    address[] public assets;

    uint256[] public amounts;

    address public admin;

    mapping(address => uint256) public interval;

    constructor(address[] memory _assets, uint256[] memory _amounts) {
        admin = msg.sender;
        assets = _assets;
        amounts = _amounts;
    }

    function getAssetList() external view returns (IERC20Metadata[] memory assetList, uint256[] memory amountList) {
        assetList = new IERC20Metadata[](assets.length);
        amountList = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assetList[i] = IERC20Metadata(assets[i]);
            amountList[i] = amounts[i];
        }
        return (assetList, amountList);
    }

    function getAsset() external {
        require(interval[msg.sender] + 86400 <= block.timestamp, "next interval");

        bool received;
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20Metadata token = IERC20Metadata(assets[i]);

            uint256 amount = amounts[i];

            if (token.balanceOf(address(this)) >= amount) {
                token.transfer(msg.sender, amount);
                received = true;
            }
        }

        if (received) {
            interval[msg.sender] = block.timestamp;
        }
    }

    function adminTransfer(address asset, address recipient) external {
        require(msg.sender == admin, "not admin");

        IERC20Metadata token = IERC20Metadata(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/AggregatorV3Interface.sol";

contract MockChainLink is AggregatorV3Interface {
    uint80[] roundIds;
    int256[] answers;

    uint256[] timestamps;

    function getRoundData(
        uint80
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundIds[0];
        return (1, 0, 1, 1, 1);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        uint256 index = roundIds.length - 1;
        return (roundIds[index], answers[index], 8, timestamps[index], 1);
    }

    function latestAnswer() external view returns (int256) {
        uint256 index = roundIds.length - 1;
        return answers[index];
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function description() external pure returns (string memory) {
        return "";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function setAnswer(uint80 _roundId, int256 _answer, uint256 _updatedAt) external {
        roundIds.push(_roundId);
        answers.push(_answer);
        timestamps.push(_updatedAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20Token is ERC20, Ownable {
    uint8 private immutable _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockMultipleTransfer {

    constructor(){
    }

    function sendEthToMultipleAddresses(address payable[] memory recipients, uint256[] memory amounts) public payable {
        require(recipients.length == amounts.length, "Arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0 && amounts[i] < 1 ether, "Amount must be greater than 0 and less than 1 ether");
            recipients[i].transfer(amounts[i]);
        }
    }

    function sendTokensToMultipleAddresses(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(recipients.length == amounts.length, "Arrays must have the same length");

        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than 0");
            require(token.transfer(recipients[i], amounts[i]), "Transfer failed");
        }
    }

    receive() external payable {}

    function withdrawBalance(address admin) public {
        payable(admin).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IBacktracker.sol";

contract MockPythOraclePriceFeed is IPythOraclePriceFeed {
    IAddressesProvider public immutable ADDRESS_PROVIDER;
    uint256 public immutable PRICE_DECIMALS = 30;
    IPyth public pyth;
    address public executor;

    mapping(address => bytes32) public tokenPriceIds;

    uint256 public priceAge;

    mapping(bytes32 => mapping(address => uint256)) public backtrackTokenPrices;

    constructor(
        IAddressesProvider addressProvider,
        address _pyth,
        address[] memory assets,
        bytes32[] memory priceIds
    ) {
        priceAge = 10;
        ADDRESS_PROVIDER = addressProvider;
        pyth = IPyth(_pyth);
        _setAssetPriceIds(assets, priceIds);
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    modifier onlyBacktracking() {
        require(IBacktracker(ADDRESS_PROVIDER.backtracker()).backtracking(), "only backtracking");
        _;
    }

    function updateExecutorAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = newAddress;
        emit UpdatedExecutorAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePriceAge(uint256 age) external onlyPoolAdmin {
        uint256 oldAge = priceAge;
        priceAge = age;
        emit PriceAgeUpdated(oldAge, priceAge);
    }

    function updatePythAddress(IPyth _pyth) external onlyPoolAdmin {
        address oldAddress = address(pyth);
        pyth = _pyth;
        emit PythAddressUpdated(oldAddress, address(_pyth));
    }

    function setTokenPriceIds(
        address[] memory assets,
        bytes32[] memory priceIds
    ) external onlyPoolAdmin {
        _setAssetPriceIds(assets, priceIds);
    }

    function updatePrice(
        address[] calldata tokens,
        bytes[] calldata _updateData,
        uint64[] calldata
    ) external payable override {
        uint256[] memory prices = new uint256[](_updateData.length);
        for (uint256 i = 0; i < _updateData.length; i++) {
            prices[i] = abi.decode(_updateData[i], (uint256));
        }
        bytes[] memory updateData = getUpdateData(tokens, prices);

        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }

        pyth.updatePriceFeeds{value: fee}(updateData);
    }

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 publishTime
    ) external payable onlyExecutor onlyBacktracking override {
        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }
        for (uint256 i = 0; i < updateData.length; i++) {
            address token = tokens[i];
            bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
            backtrackTokenPrices[backtrackRound][token] = abi.decode(updateData[i], (uint256));
        }
    }

    function removeHistoricalPrice(uint64 _backtrackRound, address[] calldata tokens) external {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), _backtrackRound));
        for (uint256 i = 0; i < tokens.length; i++) {
            delete backtrackTokenPrices[backtrackRound][tokens[i]];
        }
    }

    function getHistoricalPrice(
        uint64 publishTime,
        address token
    ) external view onlyBacktracking override returns (uint256) {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
        uint256 price = backtrackTokenPrices[backtrackRound][token];
        return price * (10 ** (PRICE_DECIMALS - 8));
    }

    function _setAssetPriceIds(address[] memory assets, bytes32[] memory priceIds) private {
        require(assets.length == priceIds.length, "inconsistent params length");
        for (uint256 i = 0; i < assets.length; i++) {
            tokenPriceIds[assets[i]] = priceIds[i];
        }
    }

    function getPythPriceUnsafe(address token) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPriceUnsafe(priceId);
    }

    function getPythPriceNoOlderThan(address token, uint256 _priceAge) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPriceNoOlderThan(priceId, _priceAge);
    }

    function getPythPrice(address token) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPrice(priceId);
    }

    function getPrice(address token) external view override returns (uint256) {
        bytes32 priceId = _getPriceId(token);
        PythStructs.Price memory pythPrice = pyth.getPriceUnsafe(priceId);
        return _returnPriceWithDecimals(pythPrice);
    }

    function getPriceSafely(address token) external view override returns (uint256) {
        bytes32 priceId = _getPriceId(token);
        PythStructs.Price memory pythPrice;
        try pyth.getPriceNoOlderThan(priceId, priceAge) returns (PythStructs.Price memory _pythPrice) {
            pythPrice = _pythPrice;
        } catch {
            revert("get price failed");
        }
        return _returnPriceWithDecimals(pythPrice);
    }

    function _getPriceId(address token) internal view returns (bytes32) {
        require(token != address(0), "zero token address");
        bytes32 priceId = tokenPriceIds[token];
        require(priceId != 0, "unknown price id");
        return priceId;
    }

    function _returnPriceWithDecimals(
        PythStructs.Price memory pythPrice
    ) internal pure returns (uint256) {
        if (pythPrice.price < 0) {
            return 0;
        }
        return uint256(uint64(pythPrice.price)) * (10 ** (PRICE_DECIMALS - 8));
    }

    function getUpdateData(
        address[] memory tokens,
        uint256[] memory prices
    ) public view returns (bytes[] memory updateData) {
        require(tokens.length == prices.length, "inconsistent params length");

        updateData = new bytes[](prices.length);

        for (uint256 i = 0; i < prices.length; i++) {
            bytes32 id = tokenPriceIds[tokens[i]];
            int64 price = int64(int256(prices[i]));
            uint64 conf = 0;
            int32 expo = 0;
            int64 emaPrice = int64(int256(prices[i]));
            uint64 emaConf = 0;
            uint64 publishTime = uint64(block.timestamp);
            updateData[i] = createPriceFeedUpdateData(
                id,
                price,
                conf,
                expo,
                emaPrice,
                emaConf,
                publishTime
            );
        }
    }

    function decimals() public pure returns (uint256) {
        return PRICE_DECIMALS;
    }

    function createPriceFeedUpdateData(
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo,
        int64 emaPrice,
        uint64 emaConf,
        uint64 publishTime
    ) public pure returns (bytes memory) {
        PythStructs.PriceFeed memory priceFeed;

        priceFeed.id = id;

        priceFeed.price.price = price;
        priceFeed.price.conf = conf;
        priceFeed.price.expo = expo;
        priceFeed.price.publishTime = publishTime;

        priceFeed.emaPrice.price = emaPrice;
        priceFeed.emaPrice.conf = emaConf;
        priceFeed.emaPrice.expo = expo;
        priceFeed.emaPrice.publishTime = publishTime;

        return abi.encode(priceFeed);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/AMMUtils.sol";

contract TestAmmUtils {

    constructor(){}

    function getReserve(
        uint256 k,
        uint256 price,
        uint256 pricePrecision
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        return AMMUtils.getReserve(k, price, pricePrecision);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view returns (uint256 amountOut) {
        return AMMUtils.getAmountOut(amountIn, reserveIn, reserveOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IPool.sol";
import "../interfaces/ILiquidityCallback.sol";
import "../interfaces/ISwapCallback.sol";

contract TestCallBack is ILiquidityCallback, ISwapCallback {
    function addLiquidity(
        address pool,
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount
    ) external {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        IPool(pool).addLiquidity(
            msg.sender,
            pairIndex,
            indexAmount,
            stableAmount,
            abi.encode(msg.sender)
        );
    }

    function addLiquidityForAccount(
        address pool,
        address indexToken,
        address stableToken,
        address receiver,
        uint256 indexAmount,
        uint256 stableAmount
    ) external {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        IPool(pool).addLiquidity(
            receiver,
            pairIndex,
            indexAmount,
            stableAmount,
            abi.encode(msg.sender)
        );
    }

    function addLiquidityCallback(
        address indexToken,
        address stableToken,
        uint256 amountIndex,
        uint256 amountStable,
        bytes calldata data
    ) external override {
        address sender = abi.decode(data, (address));

        if (amountIndex > 0) {
            IERC20(indexToken).transferFrom(sender, msg.sender, uint256(amountIndex));
        }
        if (amountStable > 0) {
            IERC20(stableToken).transferFrom(sender, msg.sender, uint256(amountStable));
        }
    }

    function removeLiquidity(
        address pool,
        address indexToken,
        address stableToken,
        uint256 amount,
        bool useETH
    ) external {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        IPool(pool).removeLiquidity(
            payable(msg.sender),
            pairIndex,
            amount,
            useETH,
            abi.encode(msg.sender)
        );
    }

    function removeLiquidityForAccount(
        address pool,
        address indexToken,
        address stableToken,
        address receiver,
        uint256 amount,
        bool useETH
    ) external {
        uint256 pairIndex = IPool(pool).getPairIndex(indexToken, stableToken);
        IPool(pool).removeLiquidity(
            payable(receiver),
            pairIndex,
            amount,
            useETH,
            abi.encode(msg.sender)
        );
    }

    function removeLiquidityCallback(
        address pairToken,
        uint256 amount,
        bytes calldata data
    ) external {
        address sender = abi.decode(data, (address));
        IERC20(pairToken).transferFrom(sender, msg.sender, amount);
    }

    function swapCallback(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        bytes calldata data
    ) external {
        address sender = abi.decode(data, (address));

        if (indexAmount > 0) {
            IERC20(indexToken).transferFrom(sender, msg.sender, indexAmount);
        } else if (stableAmount > 0) {
            IERC20(stableToken).transferFrom(sender, msg.sender, stableAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../libraries/TradingTypes.sol';

contract TestGas {
    struct Info {
        uint256 collateral;
        uint256 positionAmount;
        uint256 averagePrice;
    }

    struct Params {
        bytes32 positionKey;
        uint256 sizeAmount;
        uint8 tier;
        uint256 referralsRatio;
        uint256 referralUserRatio;
        address referralOwner;
    }

    uint256 public key;
    mapping(address => uint256) keys;
    mapping(address => TradingTypes.IncreasePositionRequest) keyPositionRequests;
    mapping(address => TradingTypes.OrderWithTpSl) keyOrderWithTpSl;
    Info[] infos;

    address public owner;

    mapping(uint256 => int256) public uint256Tests;
    mapping(uint32 => int256) public uint32Tests;

    constructor() {
        owner = msg.sender;
    }

    function testKey(uint256 i) external {
        key = i;
    }

    function testKeys(uint256 i) external {
        keys[owner] = i;
    }

    function saveIncreasePosit() external {
        keyPositionRequests[owner] = TradingTypes.IncreasePositionRequest({
            account: msg.sender,
            pairIndex: 1,
            tradeType: TradingTypes.TradeType.LIMIT,
            collateral: 1,
            openPrice: 3000,
            isLong: true,
            sizeAmount: 1000,
            maxSlippage: 1000000,
            paymentType: TradingTypes.NetworkFeePaymentType.ETH,
            networkFeeAmount: 0
        });
    }

    function saveOrderWithTpSl() external {
        keyOrderWithTpSl[owner] = TradingTypes.OrderWithTpSl({tpPrice: 1000, tp: 1, slPrice: 1000, sl: 1});
    }

    function saveInfos() external {
        infos = [Info({collateral: 0, positionAmount: 0, averagePrice: 0})];
    }

    function saveUint256Tests() external {
        uint256Tests[1] = 1;
    }

    function saveUint32Tests() external {
        uint32Tests[1] = 1;
    }

    function calldataParams(
        address[] calldata tokens,
        uint256[] calldata prices,
        bytes[] calldata updateData,
        Params[] calldata params
    ) external returns (bool) {
        return true;
    }

    function memoryParams(
        address[] memory tokens,
        uint256[] memory prices,
        bytes[] memory updateData,
        Params[] memory params
    ) external returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;
pragma abicoder v2;

import '../libraries/Multicall.sol';

contract TestMulticall is Multicall {
    function functionThatRevertsWithError(string memory error) external pure {
        revert(error);
    }

    struct Tuple {
        uint256 a;
        uint256 b;
    }

    function functionThatReturnsTuple(uint256 a, uint256 b) external pure returns (Tuple memory tuple) {
        tuple = Tuple({b: a, a: b});
    }

    uint256 public paid;

    function pays() external payable {
        paid += msg.value;
    }

    function returnSender() external view returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TestOwnableToken is ERC20, Ownable {
    constructor() ERC20('test', 'test') {
        _mint(msg.sender, 1000 * 1e10);
    }

    function mint(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {PositionStatus, IPositionManager} from "../interfaces/IPositionManager.sol";
import "../libraries/Position.sol";
import "../libraries/PositionKey.sol";
import "../libraries/PrecisionUtils.sol";
import "../libraries/Int256Utils.sol";
import "../interfaces/IFundingRate.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IRiskReserve.sol";
import "../interfaces/IFeeCollector.sol";
import "../libraries/Upgradeable.sol";
import "../helpers/TokenHelper.sol";

contract TradingHelperMock {
    IPool public pool;

    constructor(address _pool) {
        pool = IPool(_pool);
    }

    function convertIndexAmountToStable(
        uint256 pairIndex,
        int256 indexTokenAmount
    ) external view returns (int256 amount) {
        IPool.Pair memory pair = pool.getPair(pairIndex);
        return TokenHelper.convertIndexAmountToStable(pair, indexTokenAmount);
    }
}

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.19;

contract WETH9 {
    string public name = 'Wrapped Ether';
    string public symbol = 'WETH';
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../libraries/Roleable.sol";
import "../interfaces/IChainlinkPriceFeed.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IBacktracker.sol";

contract ChainlinkPriceFeed is IChainlinkPriceFeed, Roleable {
    using SafeMath for uint256;

    uint256 public immutable PRICE_DECIMALS = 30;
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    uint256 public priceAge;
    address public executor;

    // token -> sequencerUptimeFeed
    mapping(address => address) public sequencerUptimeFeeds;

    mapping(address => address) public dataFeeds;

    mapping(bytes32 => mapping(address => uint256)) public backtrackTokenPrices;

    constructor(
        IAddressesProvider _addressProvider,
        address[] memory _assets,
        address[] memory _feeds
    ) Roleable(_addressProvider) {
        _setAssetPrices(_assets, _feeds);
        priceAge = 10;
    }

    modifier onlyTimelock() {
        require(msg.sender == ADDRESS_PROVIDER.timelock(), "only timelock");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    modifier onlyBacktracking() {
        require(IBacktracker(ADDRESS_PROVIDER.backtracker()).backtracking(), "only backtracking");
        _;
    }

    function updateExecutorAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = newAddress;
        emit UpdatedExecutorAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePriceAge(uint256 age) external onlyPoolAdmin {
        uint256 oldAge = priceAge;
        priceAge = age;
        emit PriceAgeUpdated(oldAge, priceAge);
    }

    function decimals() public pure override returns (uint256) {
        return PRICE_DECIMALS;
    }

    function setTokenConfig(address[] memory assets, address[] memory feeds) external onlyTimelock {
        _setAssetPrices(assets, feeds);
    }

    function _setAssetPrices(address[] memory assets, address[] memory feeds) private {
        require(assets.length == feeds.length, "inconsistent params length");
        for (uint256 i = 0; i < assets.length; i++) {
            require(assets[i] != address(0), "!0");
            dataFeeds[assets[i]] = feeds[i];
            emit FeedUpdate(assets[i], feeds[i]);
        }
    }

    function getPrice(address token) public view override returns (uint256) {
        (, uint256 price,,,) = latestRoundData(token);
        return price;
    }

    function getPriceSafely(address token) external view override returns (uint256) {
        (, uint256 price,, uint256 updatedAt,) = latestRoundData(token);
        if (block.timestamp > updatedAt + priceAge) {
            revert("invalid price");
        }
        return price;
    }

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata,
        uint64 roundId
    ) external payable onlyExecutor onlyBacktracking override {
        for (uint256 i = 0; i < tokens.length; i++) {
            (, uint256 price,,,) = getRoundData(tokens[i], uint80(roundId));
            address token = tokens[i];
            bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), roundId));
            backtrackTokenPrices[backtrackRound][token] = price;
        }
    }

    function removeHistoricalPrice(
        uint64 _backtrackRound,
        address[] calldata tokens
    ) external onlyExecutor onlyBacktracking {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), _backtrackRound));
        for (uint256 i = 0; i < tokens.length; i++) {
            delete backtrackTokenPrices[backtrackRound][tokens[i]];
        }
    }

    function getHistoricalPrice(
        uint64 publishTime,
        address token
    ) external view onlyBacktracking override returns (uint256) {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
        return backtrackTokenPrices[backtrackRound][token];
    }

    function latestRoundData(address token) public view returns (uint80 roundId, uint256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        address dataFeedAddress = dataFeeds[token];
        require(dataFeedAddress != address(0), "invalid data feed");

        if (sequencerUptimeFeeds[token] != address(0)) {
            checkSequencerStatus(token);
        }
        AggregatorV3Interface dataFeed = AggregatorV3Interface(dataFeedAddress);
        uint256 _decimals = uint256(dataFeed.decimals());
        int256 answer;
        (roundId, answer, startedAt, updatedAt, answeredInRound) = dataFeed.latestRoundData();
        require(answer > 0, "invalid price");
        price = uint256(answer) * (10 ** (PRICE_DECIMALS - _decimals));
    }

    function getRoundData(
        address token,
        uint80 _roundId
    ) public view returns (uint80 roundId, uint256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        address dataFeedAddress = dataFeeds[token];
        require(dataFeedAddress != address(0), "invalid data feed");

        if (sequencerUptimeFeeds[token] != address(0)) {
            checkSequencerStatus(token);
        }
        AggregatorV3Interface dataFeed = AggregatorV3Interface(dataFeedAddress);
        uint256 _decimals = uint256(dataFeed.decimals());
        int256 answer;
        (roundId, answer, startedAt, updatedAt, answeredInRound) = dataFeed.getRoundData(_roundId);
        require(answer > 0, "invalid price");
        price = uint256(answer) * (10 ** (PRICE_DECIMALS - _decimals));
    }

    function checkSequencerStatus(address token) public view {
        address sequencerAddress = sequencerUptimeFeeds[token];
        require(sequencerAddress != address(0), "invalid sequencer");

        AggregatorV3Interface sequencer = AggregatorV3Interface(sequencerAddress);
        (, int256 answer, uint256 startedAt,,) = sequencer.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert("SequencerDown");
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert("GracePeriodNotOver");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIndexPriceFeed.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IRoleManager.sol";

contract IndexPriceFeed is IIndexPriceFeed {
    IAddressesProvider public immutable ADDRESS_PROVIDER;
    uint256 public immutable PRICE_DECIMALS = 30;
    mapping(address => uint256) public assetPrices;

    address public executor;

    constructor(
        IAddressesProvider addressProvider,
        address[] memory assets,
        uint256[] memory prices,
        address _executor
    ) {
        ADDRESS_PROVIDER = addressProvider;
        _setAssetPrices(assets, prices);
        executor = _executor;
    }

    modifier onlyExecutorOrPoolAdmin() {
        require(executor == msg.sender || IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "oep");
        _;
    }

    modifier onlyPoolAdmin() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender),
            "onlyPoolAdmin"
        );
        _;
    }

    function updateExecutorAddress(address _executor) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = _executor;
        emit UpdateExecutorAddress(msg.sender, oldAddress, _executor);
    }

    function decimals() public pure override returns (uint256) {
        return PRICE_DECIMALS;
    }

    function updatePrice(
        address[] calldata tokens,
        uint256[] memory prices
    ) external override onlyExecutorOrPoolAdmin {
        _setAssetPrices(tokens, prices);
    }

    function getPrice(address token) external view override returns (uint256) {
        return assetPrices[token];
    }

    function getPriceSafely(address token) external view override returns (uint256) {
        return assetPrices[token];
    }

    function _setAssetPrices(address[] memory assets, uint256[] memory prices) private {
        require(assets.length == prices.length, "inconsistent params length");
        for (uint256 i = 0; i < assets.length; i++) {
            assetPrices[assets[i]] = prices[i];
            emit PriceUpdate(assets[i], prices[i], msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IPythOracle.sol";
import "../interfaces/IBacktracker.sol";

contract PythOraclePriceFeed is IPythOraclePriceFeed {
    IAddressesProvider public immutable ADDRESS_PROVIDER;
    uint256 public immutable PRICE_DECIMALS = 30;

    uint256 public priceAge;

    IPythOracle public pyth;
    address public executor;

    mapping(address => bytes32) public tokenPriceIds;
    mapping(bytes32 => address) public priceIdTokens;

    // blockTime + backtrackRound => token => price
    mapping(bytes32 => mapping(address => uint256)) public backtrackTokenPrices;

    constructor(
        IAddressesProvider addressProvider,
        address _pyth,
        address[] memory tokens,
        bytes32[] memory priceIds
    ) {
        priceAge = 10;
        ADDRESS_PROVIDER = addressProvider;
        pyth = IPythOracle(_pyth);
        _setTokenPriceIds(tokens, priceIds);
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    modifier onlyBacktracking() {
        require(IBacktracker(ADDRESS_PROVIDER.backtracker()).backtracking(), "only backtracking");
        _;
    }

    function updateExecutorAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = newAddress;
        emit UpdatedExecutorAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePriceAge(uint256 age) external onlyPoolAdmin {
        uint256 oldAge = priceAge;
        priceAge = age;
        emit PriceAgeUpdated(oldAge, priceAge);
    }

    function updatePythAddress(IPythOracle _pyth) external onlyPoolAdmin {
        address oldAddress = address(pyth);
        pyth = _pyth;
        emit PythAddressUpdated(oldAddress, address(pyth));
    }

    function setTokenPriceIds(
        address[] memory tokens,
        bytes32[] memory priceIds
    ) external onlyPoolAdmin {
        _setTokenPriceIds(tokens, priceIds);
    }

    function updatePrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable override {
        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }
        bytes32[] memory priceIds = new bytes32[](tokens.length);
        bool update = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "zero token address");
            require(tokenPriceIds[tokens[i]] != 0, "unknown price id");

            priceIds[i] = tokenPriceIds[tokens[i]];

            if (pyth.latestPriceInfoPublishTime(tokenPriceIds[tokens[i]]) < publishTimes[i]) {
                update = true;
            }
        }

        if (update && priceIds.length > 0) {
            pyth.updatePriceFeedsIfNecessary{value: fee}(updateData, priceIds, publishTimes);
        }
    }

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 publishTime
    ) external payable onlyExecutor onlyBacktracking override {
        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }
        bytes32[] memory priceIds = new bytes32[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "zero token address");
            require(tokenPriceIds[tokens[i]] != 0, "unknown price id");

            priceIds[i] = tokenPriceIds[tokens[i]];
        }
        PythStructs.PriceFeed[] memory priceFeeds;
        try pyth.parsePriceFeedUpdates{value: msg.value}(updateData, priceIds, publishTime, publishTime) returns (PythStructs.PriceFeed[] memory _priceFeeds) {
            priceFeeds = _priceFeeds;
        } catch {
            revert("parse price failed");
        }
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            PythStructs.PriceFeed memory priceFeed = priceFeeds[i];

            address token = priceIdTokens[priceFeed.id];
            bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
            backtrackTokenPrices[backtrackRound][token] = _returnPriceWithDecimals(priceFeed.price);
        }
    }

    function removeHistoricalPrice(
        uint64 _backtrackRound,
        address[] calldata tokens
    ) external onlyExecutor onlyBacktracking {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), _backtrackRound));
        for (uint256 i = 0; i < tokens.length; i++) {
            delete backtrackTokenPrices[backtrackRound][tokens[i]];
        }
    }

    function getHistoricalPrice(
        uint64 publishTime,
        address token
    ) external view onlyBacktracking override returns (uint256) {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
        uint256 price = backtrackTokenPrices[backtrackRound][token];
        if (price == 0) {
            revert("invalid price");
        }
        return price;
    }

    function getPythPriceUnsafe(address token) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPriceUnsafe(priceId);
    }

    function getPythPriceNoOlderThan(address token, uint256 _priceAge) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPriceNoOlderThan(priceId, _priceAge);
    }

    function getPythPrice(address token) external view returns (PythStructs.Price memory) {
        bytes32 priceId = _getPriceId(token);
        return pyth.getPrice(priceId);
    }

    function getPrice(address token) external view override returns (uint256) {
        bytes32 priceId = _getPriceId(token);
        PythStructs.Price memory pythPrice = pyth.getPriceUnsafe(priceId);
        return _returnPriceWithDecimals(pythPrice);
    }

    function getPriceSafely(address token) external view override returns (uint256) {
        bytes32 priceId = _getPriceId(token);
        PythStructs.Price memory pythPrice;
        try pyth.getPriceNoOlderThan(priceId, priceAge) returns (PythStructs.Price memory _pythPrice) {
            pythPrice = _pythPrice;
        } catch {
            revert("get price failed");
        }
        return _returnPriceWithDecimals(pythPrice);
    }

    function _getPriceId(address token) internal view returns (bytes32) {
        require(token != address(0), "zero token address");
        bytes32 priceId = tokenPriceIds[token];
        require(priceId != 0, "unknown price id");
        return priceId;
    }

    function _returnPriceWithDecimals(
        PythStructs.Price memory pythPrice
    ) internal pure returns (uint256) {
        if (pythPrice.price <= 0) {
            revert("invalid price");
        }
        uint256 _decimals = pythPrice.expo < 0 ? uint256(uint32(- pythPrice.expo)) : uint256(uint32(pythPrice.expo));
        return uint256(uint64(pythPrice.price)) * (10 ** (PRICE_DECIMALS - _decimals));
    }

    function _setTokenPriceIds(address[] memory tokens, bytes32[] memory priceIds) internal {
        require(tokens.length == priceIds.length, "inconsistent params length");
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenPriceIds[tokens[i]] = priceIds[i];
            priceIdTokens[priceIds[i]] = tokens[i];
            emit TokenPriceIdUpdated(tokens[i], priceIds[i]);
        }
    }

    function decimals() public pure override returns (uint256) {
        return PRICE_DECIMALS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/IRoleManager.sol";
import "../interfaces/IPythOracle.sol";
import "../interfaces/IBacktracker.sol";

contract PythOraclePriceFeedV2 is IPythOraclePriceFeed {
    IAddressesProvider public immutable ADDRESS_PROVIDER;
    uint256 public immutable PRICE_DECIMALS = 30;

    uint256 public priceAge;

    IPythOracle public pyth;
    address public executor;

    mapping(address => bytes32) public tokenPriceIds;
    mapping(bytes32 => address) public priceIdTokens;

    // blockTime + round => token => price
    mapping(bytes32 => mapping(address => uint256)) public backtrackTokenPrices;

    mapping(uint64 => mapping(address => uint256)) public tokenPrices;

    mapping(address => uint64) public tokenPricePublishTime;

    constructor(
        IAddressesProvider addressProvider,
        address _pyth,
        address[] memory tokens,
        bytes32[] memory priceIds
    ) {
        priceAge = 10;
        ADDRESS_PROVIDER = addressProvider;
        pyth = IPythOracle(_pyth);
        _setTokenPriceIds(tokens, priceIds);
    }

    modifier onlyPoolAdmin() {
        require(IRoleManager(ADDRESS_PROVIDER.roleManager()).isPoolAdmin(msg.sender), "opa");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    modifier onlyBacktracking() {
        require(IBacktracker(ADDRESS_PROVIDER.backtracker()).backtracking(), "only backtracking");
        _;
    }

    function updateExecutorAddress(address newAddress) external onlyPoolAdmin {
        address oldAddress = executor;
        executor = newAddress;
        emit UpdatedExecutorAddress(msg.sender, oldAddress, newAddress);
    }

    function updatePriceAge(uint256 age) external onlyPoolAdmin {
        uint256 oldAge = priceAge;
        priceAge = age;
        emit PriceAgeUpdated(oldAge, priceAge);
    }

    function updatePythAddress(IPythOracle _pyth) external onlyPoolAdmin {
        address oldAddress = address(pyth);
        pyth = _pyth;
        emit PythAddressUpdated(oldAddress, address(pyth));
    }

    function setTokenPriceIds(
        address[] memory tokens,
        bytes32[] memory priceIds
    ) external onlyPoolAdmin {
        _setTokenPriceIds(tokens, priceIds);
    }

    function updatePrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64[] calldata publishTimes
    ) external payable override {
        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }

        bytes32[] memory priceIds = new bytes32[](tokens.length);
        (uint64 min, uint64 max) = _getMinMax(publishTimes);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "zero token address");
            require(tokenPriceIds[tokens[i]] != 0, "unknown price id");

            priceIds[i] = tokenPriceIds[tokens[i]];
        }

        PythStructs.PriceFeed[] memory priceFeeds;
        try pyth.parsePriceFeedUpdates{value: msg.value}(updateData, priceIds, min, max) returns (PythStructs.PriceFeed[] memory _priceFeeds) {
            priceFeeds = _priceFeeds;
        } catch {
            revert("parse price failed");
        }

        for (uint256 i = 0; i < priceFeeds.length; i++) {
            PythStructs.PriceFeed memory priceFeed = priceFeeds[i];

            uint64 publishTime = uint64(priceFeed.price.publishTime);
            require(publishTime + priceAge >= block.timestamp, "too old price");

            address token = priceIdTokens[priceFeed.id];
            uint256 price = _returnPriceWithDecimals(priceFeed.price);
            tokenPrices[publishTime][token] = price;

            if (publishTime > tokenPricePublishTime[token]) {
                tokenPricePublishTime[token] = publishTime;
            }

            emit PythPriceUpdated(token, price, publishTime);
        }
    }

    function _getMinMax(uint64[] calldata array) internal pure returns (uint64 min, uint64 max) {
        require(array.length > 0, "Array must not be empty");

        min = array[0];
        max = array[0];

        for (uint256 i = 1; i < array.length; i++) {
            uint64 currentValue = array[i];
            if (currentValue < min) {
                min = currentValue;
            } else if (currentValue > max) {
                max = currentValue;
            }
        }
    }

    function updateHistoricalPrice(
        address[] calldata tokens,
        bytes[] calldata updateData,
        uint64 publishTime
    ) external payable onlyExecutor onlyBacktracking override {
        uint fee = pyth.getUpdateFee(updateData);
        if (msg.value < fee) {
            revert("insufficient fee");
        }
        bytes32[] memory priceIds = new bytes32[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "zero token address");
            require(tokenPriceIds[tokens[i]] != 0, "unknown price id");

            priceIds[i] = tokenPriceIds[tokens[i]];
        }
        PythStructs.PriceFeed[] memory priceFeeds;
        try pyth.parsePriceFeedUpdates{value: msg.value}(updateData, priceIds, publishTime, publishTime) returns (PythStructs.PriceFeed[] memory _priceFeeds) {
            priceFeeds = _priceFeeds;
        } catch {
            revert("parse price failed");
        }
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            PythStructs.PriceFeed memory priceFeed = priceFeeds[i];

            address token = priceIdTokens[priceFeed.id];
            bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
            backtrackTokenPrices[backtrackRound][token] = _returnPriceWithDecimals(priceFeed.price);
        }
    }

    function removeHistoricalPrice(
        uint64 _backtrackRound,
        address[] calldata tokens
    ) external onlyExecutor onlyBacktracking {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), _backtrackRound));
        for (uint256 i = 0; i < tokens.length; i++) {
            delete backtrackTokenPrices[backtrackRound][tokens[i]];
        }
    }

    function getHistoricalPrice(
        uint64 publishTime,
        address token
    ) external view onlyBacktracking override returns (uint256) {
        bytes32 backtrackRound = bytes32(abi.encodePacked(uint64(block.timestamp), publishTime));
        uint256 price = backtrackTokenPrices[backtrackRound][token];
        if (price == 0) {
            revert("invalid price");
        }
        return price;
    }

    function getPrice(address token) external view override returns (uint256) {
        return tokenPrices[tokenPricePublishTime[token]][token];
    }

    function getPriceSafely(address token) external view override returns (uint256) {
        uint64 publishTime = tokenPricePublishTime[token];
        require(publishTime + priceAge >= block.timestamp, "too old price");

        return tokenPrices[publishTime][token];
    }

    function _getPriceId(address token) internal view returns (bytes32) {
        require(token != address(0), "zero token address");
        bytes32 priceId = tokenPriceIds[token];
        require(priceId != 0, "unknown price id");
        return priceId;
    }

    function _returnPriceWithDecimals(
        PythStructs.Price memory pythPrice
    ) internal pure returns (uint256) {
        if (pythPrice.price <= 0) {
            revert("invalid price");
        }
        uint256 _decimals = pythPrice.expo < 0 ? uint256(uint32(- pythPrice.expo)) : uint256(uint32(pythPrice.expo));
        return uint256(uint64(pythPrice.price)) * (10 ** (PRICE_DECIMALS - _decimals));
    }

    function _setTokenPriceIds(address[] memory tokens, bytes32[] memory priceIds) internal {
        require(tokens.length == priceIds.length, "inconsistent params length");
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenPriceIds[tokens[i]] = priceIds[i];
            priceIdTokens[priceIds[i]] = tokens[i];
            emit TokenPriceIdUpdated(tokens[i], priceIds[i]);
        }
    }

    function decimals() public pure override returns (uint256) {
        return PRICE_DECIMALS;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MultipleTransfer is Pausable, Ownable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant MERKLE_MANAGER_ROLE = keccak256("MERKLE_MANAGER");

    bytes32 public merkleRoot;

    constructor() Ownable() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        _checkRole(OPERATOR_ROLE);
        _;
    }

    modifier onlyMerkleManager() {
        _checkRole(MERKLE_MANAGER_ROLE);
        _;
    }

    receive() external payable {}

    function addOperator(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(OPERATOR_ROLE, account);
    }

    function addMerkleManager(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MERKLE_MANAGER_ROLE, account);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyMerkleManager {
        merkleRoot = _merkleRoot;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function batchTransferETH(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[][] memory proofs
    ) public onlyOperator whenNotPaused {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        for (uint i = 0; i < recipients.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(recipients[i]));
            require(MerkleProof.verify(proofs[i], merkleRoot, leaf), "Invalid Merkle Proof");

            payable(recipients[i]).transfer(amounts[i]);
        }
    }

    function batchTransferERC20(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory amounts,
        bytes32[][] memory proofs
    ) public onlyOperator whenNotPaused {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

        for (uint i = 0; i < recipients.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(recipients[i]));
            require(MerkleProof.verify(proofs[i], merkleRoot, leaf), "Invalid Merkle Proof");
            token.safeTransfer(recipients[i], amounts[i]);
        }
    }

    function emergencyWithdrawETH(address recipient) public onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function emergencyWithdrawERC20(IERC20 token, address recipient) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(recipient, balance);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IUiPoolDataProvider.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IPoolView.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IOrderManager.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    constructor(IAddressesProvider addressProvider){
        ADDRESS_PROVIDER = addressProvider;
    }

    function getPairsData(
        IPool pool,
        IPoolView poolView,
        IOrderManager orderManager,
        IPositionManager positionManager,
        IRouter router,
        IFeeCollector feeCollector,
        uint256[] memory pairIndexes,
        uint256[] memory prices
    ) public view returns (PairData[] memory) {
        require(pairIndexes.length == prices.length, "nl");

        PairData[] memory pairsData = new PairData[](pairIndexes.length);
        for (uint256 i = 0; i < pairIndexes.length; i++) {
            uint256 pairIndex = pairIndexes[i];
            uint256 price = prices[i];
            PairData memory pairData = pairsData[i];

            IPool.Pair memory pair = pool.getPair(pairIndex);
            pairData.pairIndex = pair.pairIndex;
            pairData.indexToken = pair.indexToken;
            pairData.stableToken = pair.stableToken;
            pairData.pairToken = pair.pairToken;
            pairData.enable = pair.enable;
            pairData.kOfSwap = pair.kOfSwap;
            pairData.expectIndexTokenP = pair.expectIndexTokenP;
            pairData.maxUnbalancedP = pair.maxUnbalancedP;
            pairData.unbalancedDiscountRate = pair.unbalancedDiscountRate;
            pairData.addLpFeeP = pair.addLpFeeP;
            pairData.removeLpFeeP = pair.removeLpFeeP;

            IRouter.OperationStatus memory operationStatus = router.getOperationStatus(pairIndex);
            pairData.increasePositionIsEnabled = !operationStatus.increasePositionDisabled;
            pairData.decreasePositionIsEnabled = !operationStatus.decreasePositionDisabled;
            pairData.orderIsEnabled = !operationStatus.orderDisabled;
            pairData.addLiquidityIsEnabled = !operationStatus.addLiquidityDisabled;
            pairData.removeLiquidityIsEnabled = !operationStatus.removeLiquidityDisabled;

            IPool.TradingConfig memory tradingConfig = pool.getTradingConfig(pairIndex);
            pairData.minLeverage = tradingConfig.minLeverage;
            pairData.maxLeverage = tradingConfig.maxLeverage;
            pairData.minTradeAmount = tradingConfig.minTradeAmount;
            pairData.maxTradeAmount = tradingConfig.maxTradeAmount;
            pairData.maxPositionAmount = tradingConfig.maxPositionAmount;
            pairData.maintainMarginRate = tradingConfig.maintainMarginRate;
            pairData.priceSlipP = tradingConfig.priceSlipP;
            pairData.maxPriceDeviationP = tradingConfig.maxPriceDeviationP;

            IFeeCollector.TradingFeeTier memory tradingFeeTier = feeCollector.getRegularTradingFeeTier(pairIndex);
            pairData.takerFee = tradingFeeTier.takerFee;
            pairData.makerFee = tradingFeeTier.makerFee;

            IPool.TradingFeeConfig memory tradingFeeConfig = pool.getTradingFeeConfig(pairIndex);
            pairData.lpFeeDistributeP = tradingFeeConfig.lpFeeDistributeP;
            pairData.stakingFeeDistributeP = tradingFeeConfig.stakingFeeDistributeP;
            pairData.keeperFeeDistributeP = tradingFeeConfig.keeperFeeDistributeP;

            IPool.Vault memory vault = pool.getVault(pairIndex);
            pairData.indexTotalAmount = vault.indexTotalAmount;
            pairData.indexReservedAmount = vault.indexReservedAmount;
            pairData.stableTotalAmount = vault.stableTotalAmount;
            pairData.stableReservedAmount = vault.stableReservedAmount;
            pairData.poolAvgPrice = vault.averagePrice;

            pairData.longTracker = positionManager.longTracker(pairIndex);
            pairData.shortTracker = positionManager.shortTracker(pairIndex);

            pairData.currentFundingRate = positionManager.getCurrentFundingRate(pairIndex);
            pairData.nextFundingRate = positionManager.getNextFundingRate(pairIndex, price);
            pairData.nextFundingRateUpdateTime = positionManager.getNextFundingRateUpdateTime(pairIndex);

            pairData.lpPrice = poolView.lpFairPrice(pairIndex, price);
            pairData.lpTotalSupply = IERC20(pair.pairToken).totalSupply();

            pairData.networkFees = new NetworkFeeData[](2);
            NetworkFeeData memory networkFeeDataETH = pairData.networkFees[0];
            IOrderManager.NetworkFee memory ethFee = orderManager.getNetworkFee(TradingTypes.NetworkFeePaymentType.ETH, pairIndex);
            networkFeeDataETH.paymentType = TradingTypes.NetworkFeePaymentType.ETH;
            networkFeeDataETH.basicNetworkFee = ethFee.basicNetworkFee;
            networkFeeDataETH.discountThreshold = ethFee.discountThreshold;
            networkFeeDataETH.discountedNetworkFee = ethFee.discountedNetworkFee;

            NetworkFeeData memory networkFeeDataCollateral = pairData.networkFees[1];
            IOrderManager.NetworkFee memory collateralFee = orderManager.getNetworkFee(TradingTypes.NetworkFeePaymentType.COLLATERAL, pairIndex);
            networkFeeDataCollateral.paymentType = TradingTypes.NetworkFeePaymentType.COLLATERAL;
            networkFeeDataCollateral.basicNetworkFee = collateralFee.basicNetworkFee;
            networkFeeDataCollateral.discountThreshold = collateralFee.discountThreshold;
            networkFeeDataCollateral.discountedNetworkFee = collateralFee.discountedNetworkFee;
        }

        return pairsData;
    }

    function getUserTokenData(
        IERC20Metadata[] memory tokens,
        address user
    ) external view returns (UserTokenData[] memory) {
        UserTokenData[] memory userTokensData = new UserTokenData[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            UserTokenData memory userTokenData = userTokensData[i];
            userTokenData.token = address(tokens[i]);
            if (address(tokens[i]) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                userTokenData.name = "";
                userTokenData.symbol = "";
                userTokenData.decimals = 18;
                userTokenData.totalSupply = 0;
                if (user != address(0)) {
                    userTokenData.balance = user.balance;
                }
            } else {
                userTokenData.name = tokens[i].name();
                userTokenData.symbol = tokens[i].symbol();
                userTokenData.decimals = tokens[i].decimals();
                userTokenData.totalSupply = tokens[i].totalSupply();
                if (user != address(0)) {
                    userTokenData.balance = tokens[i].balanceOf(user);
                }
            }
        }
        return userTokensData;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "../interfaces/IUiPositionDataProvider.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IPoolView.sol";
import "../helpers/TradingHelper.sol";

contract UiPositionDataProvider is IUiPositionDataProvider {

    IAddressesProvider public immutable ADDRESS_PROVIDER;

    constructor(IAddressesProvider addressProvider){
        ADDRESS_PROVIDER = addressProvider;
    }

    function getPositionsData(
        IPool pool,
        IPoolView poolView,
        IPositionManager positionManager,
        uint256[] memory pairIndexes,
        uint256[] memory prices
    ) public view returns (PositionData[] memory) {
        require(pairIndexes.length == prices.length, "nl");

        PositionData[] memory positionsData = new PositionData[](pairIndexes.length);
        for (uint256 i = 0; i < pairIndexes.length; i++) {
            uint256 pairIndex = pairIndexes[i];
            uint256 price = prices[i];
            PositionData memory positionData = positionsData[i];

            IPool.Pair memory pair = pool.getPair(pairIndex);
            positionData.pairIndex = pair.pairIndex;
            positionData.exposedPositions = positionManager.getExposedPositions(pairIndex);
            positionData.longTracker = positionManager.longTracker(pairIndex);
            positionData.shortTracker = positionManager.shortTracker(pairIndex);

            IPool.Vault memory vault = pool.getVault(pairIndex);
            positionData.indexTotalAmount = vault.indexTotalAmount;
            positionData.indexReservedAmount = vault.indexReservedAmount;
            positionData.stableTotalAmount = vault.stableTotalAmount;
            positionData.stableReservedAmount = vault.stableReservedAmount;
            positionData.poolAvgPrice = vault.averagePrice;

            positionData.currentFundingRate = positionManager.getCurrentFundingRate(pairIndex);
            positionData.nextFundingRate = positionManager.getNextFundingRate(pairIndex, price);
            positionData.nextFundingRateUpdateTime = positionManager.getNextFundingRateUpdateTime(pairIndex);

            positionData.lpPrice = poolView.lpFairPrice(pairIndex, price);
            positionData.lpTotalSupply = IERC20(pair.pairToken).totalSupply();

            int256 exposedPositions = positionManager.getExposedPositions(pairIndex);
            positionData.longLiquidity = TradingHelper.maxAvailableLiquidity(vault, pair, exposedPositions, true, price);
            positionData.shortLiquidity = TradingHelper.maxAvailableLiquidity(vault, pair, exposedPositions, false, price);
        }

        return positionsData;
    }

    function getUserPositionData(
        IPositionManager positionManager,
        bytes32[] memory positionKeys
    ) external view returns (UserPositionData[] memory) {
        UserPositionData[] memory positions = new UserPositionData[](positionKeys.length);
        for (uint256 i = 0; i < positionKeys.length; i++) {
            UserPositionData memory position = positions[i];
            Position.Info memory info = positionManager.getPositionByKey(positionKeys[i]);

            position.account = info.account;
            position.pairIndex = info.pairIndex;
            position.isLong = info.isLong;
            position.collateral = info.collateral;
            position.positionAmount = info.positionAmount;
            position.averagePrice = info.averagePrice;
            position.fundingFeeTracker = info.fundingFeeTracker;
        }
        return positions;
    }

    struct PairPrice {
        uint256 pairIndex;
        uint256 price;
    }

    function getUserPositionDataV2(
        IPositionManager positionManager,
        address account,
        PairPrice[] memory pairs
    ) external view returns (UserPositionDataV2[] memory) {
        UserPositionDataV2[] memory positions = new UserPositionDataV2[](pairs.length * 2);
        for (uint256 i = 0; i < pairs.length; i++) {
            uint256 price = pairs[i].price;

            bytes32 positionKey1 = PositionKey.getPositionKey(account, pairs[i].pairIndex, true);
            Position.Info memory info1 = positionManager.getPositionByKey(positionKey1);
            UserPositionDataV2 memory position1 = positions[i * 2];
            position1.key = positionKey1;
            position1.account = info1.account;
            position1.pairIndex = info1.pairIndex;
            position1.isLong = info1.isLong;
            position1.collateral = info1.collateral;
            position1.positionAmount = info1.positionAmount;
            position1.averagePrice = info1.averagePrice;
            position1.fundingFeeTracker = info1.fundingFeeTracker;
            position1.positionCloseTradingFee = positionManager.getTradingFee(pairs[i].pairIndex, true, false, info1.positionAmount, price);
            position1.positionFundingFee = positionManager.getFundingFee(account, pairs[i].pairIndex, true);

            bytes32 positionKey2 = PositionKey.getPositionKey(account, pairs[i].pairIndex, false);
            Position.Info memory info2 = positionManager.getPositionByKey(positionKey2);
            UserPositionDataV2 memory position2 = positions[i * 2 + 1];
            position2.key = positionKey2;
            position2.account = info2.account;
            position2.pairIndex = info2.pairIndex;
            position2.isLong = info2.isLong;
            position2.collateral = info2.collateral;
            position2.positionAmount = info2.positionAmount;
            position2.averagePrice = info2.averagePrice;
            position2.fundingFeeTracker = info2.fundingFeeTracker;
            position2.positionCloseTradingFee = positionManager.getTradingFee(pairs[i].pairIndex, false, false, info2.positionAmount, price);
            position2.positionFundingFee = positionManager.getFundingFee(account, pairs[i].pairIndex, false);
        }
        return positions;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IUniSwapV3Router.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IPoolToken.sol";
import "../interfaces/IPoolTokenFactory.sol";
import "../interfaces/ISwapCallback.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import "../interfaces/ISpotSwap.sol";
import "../interfaces/ILiquidityCallback.sol";
import "../interfaces/IWETH.sol";
import "../libraries/AmountMath.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Int256Utils.sol";
import "../libraries/AMMUtils.sol";
import "../libraries/PrecisionUtils.sol";
import "../token/interfaces/IBaseToken.sol";
import "../helpers/ValidationHelper.sol";
import "../helpers/TokenHelper.sol";
import "../interfaces/IPoolView.sol";

contract Pool is IPool, Upgradeable {
    using PrecisionUtils for uint256;
    using SafeERC20 for IERC20;
    using Int256Utils for int256;
    using Math for uint256;
    using SafeMath for uint256;

    IPoolTokenFactory public poolTokenFactory;
    IPoolView public poolView;

    address public riskReserve;
    address public feeCollector;

    mapping(uint256 => TradingConfig) public tradingConfigs;
    mapping(uint256 => TradingFeeConfig) public tradingFeeConfigs;

    mapping(address => mapping(address => uint256)) public override getPairIndex;

    uint256 public pairsIndex;
    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => Vault) public vaults;
    address public positionManager;
    address public orderManager;
    address public router;

    mapping(address => uint256) public feeTokenAmounts;
    mapping(address => bool) public isStableToken;
    address public spotSwap;

    function initialize(
        IAddressesProvider addressProvider,
        IPoolTokenFactory _poolTokenFactory
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
        poolTokenFactory = _poolTokenFactory;
        pairsIndex = 1;
    }

    modifier transferAllowed() {
        require(
            positionManager == msg.sender ||
                orderManager == msg.sender ||
                riskReserve == msg.sender ||
                feeCollector == msg.sender,
            "pd"
        );
        _;
    }

    receive() external payable {
        require(msg.sender == ADDRESS_PROVIDER.WETH() || msg.sender == orderManager, "nw");
    }

    modifier onlyPositionManager() {
        require(positionManager == msg.sender, "opm");
        _;
    }

    modifier onlyRouter() {
        require(router == msg.sender, "or");
        _;
    }

    modifier onlyPositionManagerOrFeeCollector() {
        require(
            positionManager == msg.sender || msg.sender == feeCollector,
            "opmof"
        );
        _;
    }

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "only fc");
        _;
    }

    modifier onlyTreasury() {
        require(
            IRoleManager(ADDRESS_PROVIDER.roleManager()).isTreasurer(msg.sender),
            "ot"
        );
        _;
    }

    function _unwrapWETH(uint256 amount, address payable to) private {
        IWETH(ADDRESS_PROVIDER.WETH()).withdraw(amount);
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "err-eth");
    }

    function setPoolView(address _poolView) external onlyPoolAdmin {
        address oldAddress = address(poolView);
        poolView = IPoolView(_poolView);
        emit UpdatePoolView(msg.sender, oldAddress, _poolView);
    }

    function setSpotSwap(address _spotSwap) external onlyPoolAdmin {
        address oldAddress = spotSwap;
        spotSwap = _spotSwap;
        emit UpdateSpotSwap(msg.sender, oldAddress, _spotSwap);
    }

    function setRiskReserve(address _riskReserve) external onlyPoolAdmin {
        address oldAddress = riskReserve;
        riskReserve = _riskReserve;
        emit UpdateRiskReserve(msg.sender, oldAddress, _riskReserve);
    }

    function setFeeCollector(address _feeCollector) external onlyPoolAdmin {
        address oldAddress = feeCollector;
        feeCollector = _feeCollector;
        emit UpdateFeeCollector(msg.sender, oldAddress, _feeCollector);
    }

    function setPositionManager(address _positionManager) external onlyPoolAdmin {
        address oldAddress = positionManager;
        positionManager = _positionManager;
        emit UpdatePositionManager(msg.sender, oldAddress, _positionManager);
    }

    function setOrderManager(address _orderManager) external onlyPoolAdmin {
        address oldAddress = orderManager;
        orderManager = _orderManager;
        emit UpdateOrderManager(msg.sender, oldAddress, _orderManager);
    }

    function setRouter(address _router) external onlyPoolAdmin {
        address oldAddress = router;
        router = _router;
        emit UpdateRouter(msg.sender, oldAddress, _router);
    }

    function addStableToken(address _token) external onlyPoolAdmin {
        isStableToken[_token] = true;
        emit AddStableToken(msg.sender, _token);
    }

    function removeStableToken(address _token) external onlyPoolAdmin {
        delete isStableToken[_token];
        emit RemoveStableToken(msg.sender, _token);
    }

    function addPair(address _indexToken, address _stableToken) external onlyPoolAdmin {
        require(_indexToken != address(0) && _stableToken != address(0), "!0");
        require(isStableToken[_stableToken], "!st");
        require(getPairIndex[_indexToken][_stableToken] == 0, "ex");
        require(IERC20Metadata(_indexToken).decimals() <= 18 && IERC20Metadata(_stableToken).decimals() <= 18, "!de");

        address pairToken = poolTokenFactory.createPoolToken(_indexToken, _stableToken);

        getPairIndex[_indexToken][_stableToken] = pairsIndex;
        getPairIndex[_stableToken][_indexToken] = pairsIndex;

        Pair storage pair = pairs[pairsIndex];
        pair.pairIndex = pairsIndex;
        pair.indexToken = _indexToken;

        pair.stableToken = _stableToken;
        pair.pairToken = pairToken;

        emit PairAdded(_indexToken, _stableToken, pairToken, pairsIndex++);
    }

    function updatePair(uint256 _pairIndex, Pair calldata _pair) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "nex"
        );
        require(
            _pair.expectIndexTokenP <= PrecisionUtils.percentage() &&
                _pair.maxUnbalancedP <= PrecisionUtils.percentage() &&
                _pair.unbalancedDiscountRate <= PrecisionUtils.percentage() &&
                _pair.addLpFeeP <= PrecisionUtils.percentage() &&
                _pair.removeLpFeeP <= PrecisionUtils.percentage(),
            "ex"
        );

        pair.enable = _pair.enable;
        pair.kOfSwap = _pair.kOfSwap;
        pair.expectIndexTokenP = _pair.expectIndexTokenP;
        pair.maxUnbalancedP = _pair.maxUnbalancedP;
        pair.unbalancedDiscountRate = _pair.unbalancedDiscountRate;
        pair.addLpFeeP = _pair.addLpFeeP;
        pair.removeLpFeeP = _pair.removeLpFeeP;
    }

    function updateTradingConfig(
        uint256 _pairIndex,
        TradingConfig calldata _tradingConfig
    ) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "pnt"
        );
        require(
            _tradingConfig.maintainMarginRate <= PrecisionUtils.percentage() &&
                _tradingConfig.priceSlipP <= PrecisionUtils.percentage() &&
                _tradingConfig.maxPriceDeviationP <= PrecisionUtils.percentage(),
            "ex"
        );
        tradingConfigs[_pairIndex] = _tradingConfig;
    }

    function updateTradingFeeConfig(
        uint256 _pairIndex,
        TradingFeeConfig calldata _tradingFeeConfig
    ) external onlyPoolAdmin {
        Pair storage pair = pairs[_pairIndex];
        require(
            pair.indexToken != address(0) && pair.stableToken != address(0),
            "pne"
        );
        require(
            _tradingFeeConfig.lpFeeDistributeP +
                _tradingFeeConfig.keeperFeeDistributeP +
                _tradingFeeConfig.stakingFeeDistributeP +
                _tradingFeeConfig.treasuryFeeDistributeP +
                _tradingFeeConfig.reservedFeeDistributeP +
                _tradingFeeConfig.ecoFundFeeDistributeP <=
                PrecisionUtils.percentage(),
            "ex"
        );
        tradingFeeConfigs[_pairIndex] = _tradingFeeConfig;
    }

    function _increaseTotalAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) internal {
        Vault storage vault = vaults[_pairIndex];
        vault.indexTotalAmount = vault.indexTotalAmount + _indexAmount;
        vault.stableTotalAmount = vault.stableTotalAmount + _stableAmount;
        emit UpdateTotalAmount(
            _pairIndex,
            int256(_indexAmount),
            int256(_stableAmount),
            vault.indexTotalAmount,
            vault.stableTotalAmount
        );
    }

    function _decreaseTotalAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) internal {
        Vault storage vault = vaults[_pairIndex];
        require(vault.indexTotalAmount >= _indexAmount, "ix");
        require(vault.stableTotalAmount >= _stableAmount, "ix");

        vault.indexTotalAmount = vault.indexTotalAmount - _indexAmount;
        vault.stableTotalAmount = vault.stableTotalAmount - _stableAmount;
        emit UpdateTotalAmount(
            _pairIndex,
            -int256(_indexAmount),
            -int256(_stableAmount),
            vault.indexTotalAmount,
            vault.stableTotalAmount
        );
    }

    function increaseReserveAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external onlyPositionManager {
        Vault storage vault = vaults[_pairIndex];
        vault.indexReservedAmount = vault.indexReservedAmount + _indexAmount;
        vault.stableReservedAmount = vault.stableReservedAmount + _stableAmount;
        emit UpdateReserveAmount(
            _pairIndex,
            int256(_indexAmount),
            int256(_stableAmount),
            vault.indexReservedAmount,
            vault.stableReservedAmount
        );
    }

    function decreaseReserveAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount
    ) external onlyPositionManager {
        Vault storage vault = vaults[_pairIndex];
        require(vault.indexReservedAmount >= _indexAmount, "ex");
        require(vault.stableReservedAmount >= _stableAmount, "ex");

        vault.indexReservedAmount = vault.indexReservedAmount - _indexAmount;
        vault.stableReservedAmount = vault.stableReservedAmount - _stableAmount;
        emit UpdateReserveAmount(
            _pairIndex,
            -int256(_indexAmount),
            -int256(_stableAmount),
            vault.indexReservedAmount,
            vault.stableReservedAmount
        );
    }

    function updateAveragePrice(
        uint256 _pairIndex,
        uint256 _averagePrice
    ) external onlyPositionManager {
        vaults[_pairIndex].averagePrice = _averagePrice;
        emit UpdateAveragePrice(_pairIndex, _averagePrice);
    }

    function setLPStableProfit(
        uint256 _pairIndex,
        int256 _profit
    ) external onlyPositionManagerOrFeeCollector {
        Vault storage vault = vaults[_pairIndex];
        Pair memory pair = pairs[_pairIndex];
        if (_profit > 0) {
            vault.stableTotalAmount += _profit.abs();
        } else {
            if (vault.stableTotalAmount < _profit.abs()) {
                _swapInUni(_pairIndex, pair.stableToken, _profit.abs());
            }
            vault.stableTotalAmount -= _profit.abs();
        }

        emit UpdateLPProfit(_pairIndex, pair.stableToken, _profit, vault.stableTotalAmount);
    }

    function givebackTradingFee(
        uint256 pairIndex,
        uint256 amount
    ) external onlyFeeCollector {
        Vault storage vault = vaults[pairIndex];
        require(vault.stableTotalAmount >= amount, "insufficient liquidity");

        vault.stableTotalAmount -= amount;

        Pair memory pair = pairs[pairIndex];
        emit GivebackTradingFee(pairIndex, pair.stableToken, amount);
    }

    function getAvailableLiquidity(uint256 pairIndex, uint256 price) external view returns(int256 v, int256 u, int256 e) {
        Vault memory vault = getVault(pairIndex);
        Pair memory pair = getPair(pairIndex);

        v = TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexTotalAmount), price)
            + int256(vault.stableReservedAmount)
            - TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price);
        u = int256(vault.stableTotalAmount)
            + TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(vault.indexReservedAmount), price)
            - int256(vault.stableReservedAmount);
        e = v - u;
    }

    function addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) external onlyRouter returns (uint256 mintAmount, address slipToken, uint256 slipAmount) {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, recipient);

        Pair memory pair = pairs[_pairIndex];
        require(pair.enable, "disabled");

        return _addLiquidity(recipient, _pairIndex, _indexAmount, _stableAmount, data);
    }

    function removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    ) external onlyRouter returns (uint256 receivedIndexAmount, uint256 receivedStableAmount, uint256 feeAmount) {
        ValidationHelper.validateAccountBlacklist(ADDRESS_PROVIDER, _receiver);

        Pair memory pair = pairs[_pairIndex];
        require(pair.enable, "disabled");

        (receivedIndexAmount, receivedStableAmount, feeAmount) = _removeLiquidity(
            _receiver,
            _pairIndex,
            _amount,
            useETH,
            data
        );

        return (receivedIndexAmount, receivedStableAmount, feeAmount);
    }

    function _transferToken(
        address indexToken,
        address stableToken,
        uint256 indexAmount,
        uint256 stableAmount,
        bytes calldata data
    ) internal {
        uint256 balanceIndexBefore;
        uint256 balanceStableBefore;
        if (indexAmount > 0) balanceIndexBefore = IERC20(indexToken).balanceOf(address(this));
        if (stableAmount > 0) balanceStableBefore = IERC20(stableToken).balanceOf(address(this));
        ILiquidityCallback(msg.sender).addLiquidityCallback(
            indexToken,
            stableToken,
            indexAmount,
            stableAmount,
            data
        );

        if (indexAmount > 0)
            require(
                balanceIndexBefore.add(indexAmount) <= IERC20(indexToken).balanceOf(address(this)),
                "ti"
            );
        if (stableAmount > 0) {
            require(
                balanceStableBefore.add(stableAmount) <=
                    IERC20(stableToken).balanceOf(address(this)),
                "ts"
            );
        }
    }

    function _swapInUni(uint256 _pairIndex, address _tokenOut, uint256 _expectAmountOut) private {
        Pair memory pair = pairs[_pairIndex];
        (
            address tokenIn,
            address tokenOut,
            uint256 amountInMaximum,
            uint256 expectAmountOut
        ) = ISpotSwap(spotSwap).getSwapData(pair, _tokenOut, _expectAmountOut);

        if (IERC20(tokenIn).allowance(address(this), spotSwap) < amountInMaximum) {
            IERC20(tokenIn).safeApprove(spotSwap, type(uint256).max);
        }
        ISpotSwap(spotSwap).swap(tokenIn, tokenOut, amountInMaximum, expectAmountOut);
    }

    function _getStableTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = lpProfit(pair.pairIndex, pair.stableToken, price);
        if (profit < 0) {
            return vault.stableTotalAmount > profit.abs() ? vault.stableTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.stableTotalAmount.add(profit.abs());
        }
    }

    function _getIndexTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = lpProfit(pair.pairIndex, pair.indexToken, price);
        if (profit < 0) {
            return vault.indexTotalAmount > profit.abs() ? vault.indexTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.indexTotalAmount.add(profit.abs());
        }
    }

    function _addLiquidity(
        address recipient,
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        bytes calldata data
    ) private returns (uint256 mintAmount, address slipToken, uint256 slipAmount) {
        require(_indexAmount > 0 || _stableAmount > 0, "ia");

        IPool.Pair memory pair = getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        _transferToken(pair.indexToken, pair.stableToken, _indexAmount, _stableAmount, data);

        uint256 price = IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);
        uint256 lpPrice = poolView.lpFairPrice(_pairIndex, price);

        uint256 indexFeeAmount;
        uint256 stableFeeAmount;
        uint256 afterFeeIndexAmount;
        uint256 afterFeeStableAmount;
        (
            mintAmount,
            slipToken,
            slipAmount,
            indexFeeAmount,
            stableFeeAmount,
            afterFeeIndexAmount,
            afterFeeStableAmount
        ) = poolView.getMintLpAmount(_pairIndex, _indexAmount, _stableAmount, price);

        feeTokenAmounts[pair.indexToken] += indexFeeAmount;
        feeTokenAmounts[pair.stableToken] += stableFeeAmount;

        if (slipToken == pair.indexToken) {
            afterFeeIndexAmount += slipAmount;
        } else if (slipToken == pair.stableToken) {
            afterFeeStableAmount += slipAmount;
        }
        _increaseTotalAmount(_pairIndex, afterFeeIndexAmount, afterFeeStableAmount);

        IBaseToken(pair.pairToken).mint(recipient, mintAmount);

        emit AddLiquidity(
            recipient,
            _pairIndex,
            _indexAmount,
            _stableAmount,
            mintAmount,
            indexFeeAmount,
            stableFeeAmount,
            slipToken,
            slipAmount,
            lpPrice
        );

        return (mintAmount, slipToken, slipAmount);
    }

    function _removeLiquidity(
        address payable _receiver,
        uint256 _pairIndex,
        uint256 _amount,
        bool useETH,
        bytes calldata data
    )
        private
        returns (
            uint256 receiveIndexTokenAmount,
            uint256 receiveStableTokenAmount,
            uint256 feeAmount
        )
    {
        require(_amount > 0, "ia");
        IPool.Pair memory pair = getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        uint256 price = IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).getPriceSafely(pair.indexToken);
        uint256 lpPrice = poolView.lpFairPrice(_pairIndex, price);

        uint256 feeIndexTokenAmount;
        uint256 feeStableTokenAmount;
        (
            receiveIndexTokenAmount,
            receiveStableTokenAmount,
            feeAmount,
            feeIndexTokenAmount,
            feeStableTokenAmount
        ) = poolView.getReceivedAmount(_pairIndex, _amount, price);

        ILiquidityCallback(msg.sender).removeLiquidityCallback(pair.pairToken, _amount, data);
        IPoolToken(pair.pairToken).burn(_amount);

        IPool.Vault memory vault = getVault(_pairIndex);
        uint256 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        uint256 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();

        uint256 availableIndexTokenWad;
        if (vault.indexTotalAmount > vault.indexReservedAmount) {
            uint256 availableIndexToken = vault.indexTotalAmount - vault.indexReservedAmount;
            availableIndexTokenWad = availableIndexToken * (10 ** (18 - indexTokenDec));
        }

        uint256 availableStableTokenWad;
        if (vault.stableTotalAmount > vault.stableReservedAmount) {
            uint256 availableStableToken = vault.stableTotalAmount - vault.stableReservedAmount;
            availableStableTokenWad = availableStableToken * (10 ** (18 - stableTokenDec));
        }

        uint256 receiveIndexTokenAmountWad = receiveIndexTokenAmount * (10 ** (18 - indexTokenDec));
        uint256 receiveStableTokenAmountWad = receiveStableTokenAmount * (10 ** (18 - stableTokenDec));

        uint256 totalAvailable = availableIndexTokenWad.mulPrice(price) + availableStableTokenWad;
        uint256 totalReceive = receiveIndexTokenAmountWad.mulPrice(price) + receiveStableTokenAmountWad;
        require(totalReceive <= totalAvailable, "il");

        feeTokenAmounts[pair.indexToken] += feeIndexTokenAmount;
        feeTokenAmounts[pair.stableToken] += feeStableTokenAmount;

        _decreaseTotalAmount(
            _pairIndex,
            receiveIndexTokenAmount + feeIndexTokenAmount,
            receiveStableTokenAmount + feeStableTokenAmount
        );

        if (receiveIndexTokenAmount > 0) {
            if (useETH && pair.indexToken == ADDRESS_PROVIDER.WETH()) {
                _unwrapWETH(receiveIndexTokenAmount, _receiver);
            } else {
                IERC20(pair.indexToken).safeTransfer(_receiver, receiveIndexTokenAmount);
            }
        }

        if (receiveStableTokenAmount > 0) {
            IERC20(pair.stableToken).safeTransfer(_receiver, receiveStableTokenAmount);
        }

        emit RemoveLiquidity(
            _receiver,
            _pairIndex,
            receiveIndexTokenAmount,
            receiveStableTokenAmount,
            _amount,
            feeAmount,
            lpPrice
        );

        return (receiveIndexTokenAmount, receiveStableTokenAmount, feeAmount);
    }

    function claimFee(address token, uint256 amount) external onlyTreasury {
        require(feeTokenAmounts[token] >= amount, "ex");

        feeTokenAmounts[token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);

        emit ClaimedFee(msg.sender, token, amount);
    }

    function transferTokenTo(address token, address to, uint256 amount) external transferAllowed {
        require(IERC20(token).balanceOf(address(this)) > amount, "Insufficient balance");
        IERC20(token).safeTransfer(to, amount);
    }

    function transferEthTo(address to, uint256 amount) external transferAllowed {
        require(address(this).balance > amount, "Insufficient balance");
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "transfer failed");
    }

    function transferTokenOrSwap(
        uint256 pairIndex,
        address token,
        address to,
        uint256 amount
    ) external transferAllowed {
        if (amount == 0) {
            return;
        }
        Pair memory pair = pairs[pairIndex];
        require(token == pair.indexToken || token == pair.stableToken, "bt");

        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal < amount) {
            _swapInUni(pairIndex, token, amount);
        }
        IERC20(token).safeTransfer(to, amount);
    }

    function getLpPnl(
        uint256 _pairIndex,
        bool lpIsLong,
        uint amount,
        uint256 _price
    ) public view override returns (int256) {
        Vault memory lpVault = getVault(_pairIndex);
        if (lpIsLong) {
            if (_price > lpVault.averagePrice) {
                return int256(amount.mulPrice(_price - lpVault.averagePrice));
            } else {
                return -int256(amount.mulPrice(lpVault.averagePrice - _price));
            }
        } else {
            if (_price < lpVault.averagePrice) {
                return int256(amount.mulPrice(lpVault.averagePrice - _price));
            } else {
                return -int256(amount.mulPrice(_price - lpVault.averagePrice));
            }
        }
    }

    function lpProfit(
        uint pairIndex,
        address token,
        uint256 price
    ) public view override returns (int256) {
        int256 currentExposureAmountChecker = IPositionManager(positionManager).getExposedPositions(pairIndex);
        if (currentExposureAmountChecker == 0) {
            return 0;
        }

        int256 profit = getLpPnl(
            pairIndex,
            currentExposureAmountChecker < 0,
            currentExposureAmountChecker.abs(),
            price
        );

        Pair memory pair = getPair(pairIndex);
        return
            TokenHelper.convertTokenAmountTo(
            pair.indexToken,
            profit,
            IERC20Metadata(token).decimals()
        );
    }

    function getVault(uint256 _pairIndex) public view returns (Vault memory vault) {
        return vaults[_pairIndex];
    }

    function getPair(uint256 _pairIndex) public view override returns (Pair memory) {
        return pairs[_pairIndex];
    }

    function getTradingConfig(
        uint256 _pairIndex
    ) external view override returns (TradingConfig memory) {
        return tradingConfigs[_pairIndex];
    }

    function getTradingFeeConfig(
        uint256 _pairIndex
    ) external view override returns (TradingFeeConfig memory) {
        return tradingFeeConfigs[_pairIndex];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IPoolToken.sol";

import "../libraries/Roleable.sol";

contract PoolToken is IPoolToken, Roleable, ERC20 {
    address public indexToken;
    address public stableToken;

    mapping(address => bool) public miners;

    constructor(
        IAddressesProvider addressProvider,
        address _indexToken,
        address _stableToken,
        address _miner,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Roleable(addressProvider) {
        indexToken = _indexToken;
        stableToken = _stableToken;
        miners[_miner] = true;
    }

    modifier onlyMiner() {
        require(miners[msg.sender], "miner forbidden");
        _;
    }

    function mint(address to, uint256 amount) external onlyMiner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setMiner(address account, bool enable) external {
        require(msg.sender == ADDRESS_PROVIDER.timelock(), "onlyTimelock");
        miners[account] = enable;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IPoolTokenFactory.sol";
import "./PoolToken.sol";

contract PoolTokenFactory is IPoolTokenFactory {
    IAddressesProvider public immutable ADDRESS_PROVIDER;

    constructor(IAddressesProvider addressProvider) {
        ADDRESS_PROVIDER = addressProvider;
    }

    function createPoolToken(
        address indexToken,
        address stableToken
    ) external override returns (address) {
        string memory name = string(
            abi.encodePacked(
                IERC20Metadata(indexToken).name(),
                "-",
                IERC20Metadata(stableToken).name(),
                "-lp"
            )
        );
        string memory symbol = string(
            abi.encodePacked(
                IERC20Metadata(indexToken).symbol(),
                "-",
                IERC20Metadata(stableToken).symbol(),
                "-lp"
            )
        );
        PoolToken pairToken = new PoolToken(
            ADDRESS_PROVIDER,
            indexToken,
            stableToken,
            msg.sender,
            name,
            symbol
        );
        return address(pairToken);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPositionManager.sol";
import "../interfaces/IPoolView.sol";
import "../libraries/AmountMath.sol";
import "../libraries/Upgradeable.sol";
import "../libraries/Int256Utils.sol";
import "../libraries/AMMUtils.sol";
import "../libraries/PrecisionUtils.sol";
import "../helpers/TokenHelper.sol";

contract PoolView is IPoolView, Upgradeable {
    using PrecisionUtils for uint256;
    using SafeERC20 for IERC20;
    using Int256Utils for int256;
    using Math for uint256;
    using SafeMath for uint256;

    IPool public pool;
    IPositionManager public positionManager;

    function initialize(
        IAddressesProvider addressProvider
    ) public initializer {
        ADDRESS_PROVIDER = addressProvider;
    }

    function setPool(address _pool) external onlyPoolAdmin {
        address oldAddress = address(pool);
        pool = IPool(_pool);
        emit UpdatePool(msg.sender, oldAddress, _pool);
    }

    function setPositionManager(address _positionManager) external onlyPoolAdmin {
        address oldAddress = address(positionManager);
        positionManager = IPositionManager(_positionManager);
        emit UpdatePositionManager(msg.sender, oldAddress, _positionManager);
    }

    function getMintLpAmount(
        uint256 _pairIndex,
        uint256 _indexAmount,
        uint256 _stableAmount,
        uint256 price
    )
        external
        view
        override
        returns (
            uint256 mintAmount,
            address slipToken,
            uint256 slipAmount,
            uint256 indexFeeAmount,
            uint256 stableFeeAmount,
            uint256 afterFeeIndexAmount,
            uint256 afterFeeStableAmount
        )
    {
        if (_indexAmount == 0 && _stableAmount == 0) return (0, address(0), 0, 0, 0, 0, 0);
        require(price > 0, "ip");

        IPool.Pair memory pair = pool.getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        IPool.Vault memory vault = pool.getVault(_pairIndex);

        // transfer fee
        indexFeeAmount = _indexAmount.mulPercentage(pair.addLpFeeP);
        stableFeeAmount = _stableAmount.mulPercentage(pair.addLpFeeP);

        afterFeeIndexAmount = _indexAmount - indexFeeAmount;
        afterFeeStableAmount = _stableAmount - stableFeeAmount;

        uint256 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        uint256 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();

        uint256 indexTotalDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.indexToken, int256(_getIndexTotalAmount(pair, vault, price)), 18, price));
        uint256 stableTotalDeltaWad = uint256(TokenHelper.convertTokenAmountTo(
            pair.stableToken, int256(_getStableTotalAmount(pair, vault, price)), 18));

        uint256 indexDepositDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.indexToken, int256(afterFeeIndexAmount), 18, price));
        uint256 stableDepositDeltaWad = uint256(TokenHelper.convertTokenAmountTo(
            pair.stableToken, int256(afterFeeStableAmount), 18));

        uint256 slipDeltaWad;
        uint256 discountRate;
        uint256 discountAmount;
        if (indexTotalDeltaWad + stableTotalDeltaWad > 0) {
            // after deposit
            uint256 totalIndexTotalDeltaWad = indexTotalDeltaWad + indexDepositDeltaWad;
            uint256 totalStableTotalDeltaWad = stableTotalDeltaWad + stableDepositDeltaWad;

            // expect delta
            uint256 totalDelta = totalIndexTotalDeltaWad + totalStableTotalDeltaWad;
            uint256 expectIndexDeltaWad = totalDelta.mulPercentage(pair.expectIndexTokenP);
            uint256 expectStableDeltaWad = totalDelta - expectIndexDeltaWad;

            if (_indexAmount > 0 && _stableAmount == 0) {
                (discountRate, discountAmount) =
                    _getDiscount(pair, true, totalIndexTotalDeltaWad, expectIndexDeltaWad, totalDelta);
            }

            if (_stableAmount > 0 && _indexAmount == 0) {
                (discountRate, discountAmount) =
                    _getDiscount(pair, false, totalStableTotalDeltaWad, expectStableDeltaWad, totalDelta);
            }

            (uint256 reserveA, uint256 reserveB) = AMMUtils.getReserve(
                pair.kOfSwap,
                price,
                AmountMath.PRICE_PRECISION
            );
            if (totalIndexTotalDeltaWad > expectIndexDeltaWad) {
                uint256 needSwapIndexDeltaWad = totalIndexTotalDeltaWad - expectIndexDeltaWad;
                uint256 swapIndexDeltaWad = Math.min(indexDepositDeltaWad, needSwapIndexDeltaWad);

                slipDeltaWad = swapIndexDeltaWad
                    - AMMUtils.getAmountOut(
                        AmountMath.getIndexAmount(swapIndexDeltaWad, price),
                        reserveA,
                        reserveB
                    );
                slipAmount = AmountMath.getIndexAmount(slipDeltaWad, price) / (10 ** (18 - indexTokenDec));
                if (slipAmount > 0) {
                    slipToken = pair.indexToken;
                }

                afterFeeIndexAmount -= slipAmount;
            } else if (totalStableTotalDeltaWad > expectStableDeltaWad) {
                uint256 needSwapStableDeltaWad = totalStableTotalDeltaWad - expectStableDeltaWad;
                uint256 swapStableDeltaWad = Math.min(stableDepositDeltaWad, needSwapStableDeltaWad);

                slipDeltaWad = swapStableDeltaWad
                    - AMMUtils.getAmountOut(swapStableDeltaWad, reserveB, reserveA).mulPrice(price);
                slipAmount = slipDeltaWad / (10 ** (18 - stableTokenDec));
                if (slipAmount > 0) {
                    slipToken = pair.stableToken;
                }
                afterFeeStableAmount -= slipAmount;
            }
        }

        uint256 mintDeltaWad = indexDepositDeltaWad + stableDepositDeltaWad - slipDeltaWad;

        // mint with discount
        if (discountRate > 0) {
            if (mintDeltaWad > discountAmount) {
                mintAmount += AmountMath.getIndexAmount(
                    discountAmount,
                    lpFairPrice(_pairIndex, price).mulPercentage(
                        PrecisionUtils.percentage() - discountRate
                    )
                );
                mintDeltaWad -= discountAmount;
            } else {
                mintAmount += AmountMath.getIndexAmount(
                    mintDeltaWad,
                    lpFairPrice(_pairIndex, price).mulPercentage(
                        PrecisionUtils.percentage() - discountRate
                    )
                );
                mintDeltaWad = 0;
            }
        }

        if (mintDeltaWad > 0) {
            mintAmount += AmountMath.getIndexAmount(mintDeltaWad, lpFairPrice(_pairIndex, price));
        }

        return (
            mintAmount,
            slipToken,
            slipAmount,
            indexFeeAmount,
            stableFeeAmount,
            afterFeeIndexAmount,
            afterFeeStableAmount
        );
    }

    function lpFairPrice(uint256 _pairIndex, uint256 price) public view returns (uint256) {
        IPool.Pair memory pair = pool.getPair(_pairIndex);
        IPool.Vault memory vault = pool.getVault(_pairIndex);
        uint256 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        uint256 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();

        uint256 indexTotalAmountWad = _getIndexTotalAmount(pair, vault, price) * (10 ** (18 - indexTokenDec));
        uint256 stableTotalAmountWad = _getStableTotalAmount(pair, vault, price) * (10 ** (18 - stableTokenDec));

        uint256 lpFairDelta = AmountMath.getStableDelta(indexTotalAmountWad, price) + stableTotalAmountWad;

        return
            lpFairDelta > 0 && IERC20(pair.pairToken).totalSupply() > 0
                ? Math.mulDiv(
                    lpFairDelta,
                    AmountMath.PRICE_PRECISION,
                    IERC20(pair.pairToken).totalSupply()
                )
                : 1 * AmountMath.PRICE_PRECISION;
    }

    function getDepositAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (uint256 depositIndexAmount, uint256 depositStableAmount) {
        if (_lpAmount == 0) return (0, 0);
        require(price > 0, "ipr");

        IPool.Pair memory pair = pool.getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        IPool.Vault memory vault = pool.getVault(_pairIndex);

        uint256 indexReserveDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.indexToken,
            int256(vault.indexTotalAmount),
            18,
            price
        ));
        uint256 stableReserveDeltaWad = uint256(TokenHelper.convertTokenAmountTo(
            pair.stableToken,
            int256(vault.stableTotalAmount),
            18
        ));
        uint256 depositDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.pairToken,
            int256(_lpAmount),
            18,
            lpFairPrice(_pairIndex, price)
        ));

        // expect delta
        uint256 totalDelta = (indexReserveDeltaWad + stableReserveDeltaWad + depositDeltaWad);
        uint256 expectIndexDelta = totalDelta.mulPercentage(pair.expectIndexTokenP);
        uint256 expectStableDelta = totalDelta - expectIndexDelta;

        uint256 depositIndexTokenDelta;
        uint256 depositStableTokenDelta;
        if (expectIndexDelta >= indexReserveDeltaWad) {
            uint256 extraIndexReserveDelta = expectIndexDelta - indexReserveDeltaWad;
            if (extraIndexReserveDelta >= depositDeltaWad) {
                depositIndexTokenDelta = depositDeltaWad;
            } else {
                depositIndexTokenDelta = extraIndexReserveDelta;
                depositStableTokenDelta = depositDeltaWad - extraIndexReserveDelta;
            }
        } else {
            uint256 extraStableReserveDelta = expectStableDelta - stableReserveDeltaWad;
            if (extraStableReserveDelta >= depositDeltaWad) {
                depositStableTokenDelta = depositDeltaWad;
            } else {
                depositIndexTokenDelta = depositDeltaWad - extraStableReserveDelta;
                depositStableTokenDelta = extraStableReserveDelta;
            }
        }
        uint256 indexTokenDec = uint256(IERC20Metadata(pair.indexToken).decimals());
        uint256 stableTokenDec = uint256(IERC20Metadata(pair.stableToken).decimals());

        depositIndexAmount = depositIndexTokenDelta * PrecisionUtils.pricePrecision() / price / (10 ** (18 - indexTokenDec));
        depositStableAmount = depositStableTokenDelta / (10 ** (18 - stableTokenDec));

        // add fee
        depositIndexAmount = depositIndexAmount.divPercentage(
            PrecisionUtils.percentage() - pair.addLpFeeP
        );
        depositStableAmount = depositStableAmount.divPercentage(
            PrecisionUtils.percentage() - pair.addLpFeeP
        );

        return (depositIndexAmount, depositStableAmount);
    }

    function getReceivedAmount(
        uint256 _pairIndex,
        uint256 _lpAmount,
        uint256 price
    ) external view returns (
            uint256 receiveIndexTokenAmount,
            uint256 receiveStableTokenAmount,
            uint256 feeAmount,
            uint256 feeIndexTokenAmount,
            uint256 feeStableTokenAmount
        )
    {
        if (_lpAmount == 0) return (0, 0, 0, 0, 0);
        require(price > 0, "ipr");

        IPool.Pair memory pair = pool.getPair(_pairIndex);
        require(pair.pairToken != address(0), "ip");

        IPool.Vault memory vault = pool.getVault(_pairIndex);

        uint256 indexTokenDec = IERC20Metadata(pair.indexToken).decimals();
        uint256 stableTokenDec = IERC20Metadata(pair.stableToken).decimals();

        uint256 indexReserveDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.indexToken,
            int256(vault.indexTotalAmount),
            18,
            price));
        uint256 stableReserveDeltaWad = uint256(TokenHelper.convertTokenAmountTo(
            pair.stableToken,
            int256(vault.stableTotalAmount),
            18));
        uint256 receiveDeltaWad = uint256(TokenHelper.convertTokenAmountWithPrice(
            pair.pairToken,
            int256(_lpAmount),
            18,
            lpFairPrice(_pairIndex, price)));

        require(indexReserveDeltaWad + stableReserveDeltaWad >= receiveDeltaWad, "insufficient liquidity");

        // expect delta
        uint256 totalDeltaWad = indexReserveDeltaWad + stableReserveDeltaWad - receiveDeltaWad;
        uint256 expectIndexDeltaWad = totalDeltaWad.mulPercentage(pair.expectIndexTokenP);
        uint256 expectStableDeltaWad = totalDeltaWad - expectIndexDeltaWad;

        // received delta of indexToken and stableToken
        uint256 receiveIndexTokenDeltaWad;
        uint256 receiveStableTokenDeltaWad;
        if (indexReserveDeltaWad > expectIndexDeltaWad) {
            uint256 extraIndexReserveDelta = indexReserveDeltaWad - expectIndexDeltaWad;
            if (extraIndexReserveDelta >= receiveDeltaWad) {
                receiveIndexTokenDeltaWad = receiveDeltaWad;
            } else {
                receiveIndexTokenDeltaWad = extraIndexReserveDelta;
                receiveStableTokenDeltaWad = receiveDeltaWad - extraIndexReserveDelta;
            }
        } else {
            uint256 extraStableReserveDelta = stableReserveDeltaWad - expectStableDeltaWad;
            if (extraStableReserveDelta >= receiveDeltaWad) {
                receiveStableTokenDeltaWad = receiveDeltaWad;
            } else {
                receiveIndexTokenDeltaWad = receiveDeltaWad - extraStableReserveDelta;
                receiveStableTokenDeltaWad = extraStableReserveDelta;
            }
        }
        receiveIndexTokenAmount = AmountMath.getIndexAmount(receiveIndexTokenDeltaWad, price) / (10 ** (18 - indexTokenDec));
        receiveStableTokenAmount = receiveStableTokenDeltaWad / (10 ** (18 - stableTokenDec));

        feeIndexTokenAmount = receiveIndexTokenAmount.mulPercentage(pair.removeLpFeeP);
        feeStableTokenAmount = receiveStableTokenAmount.mulPercentage(pair.removeLpFeeP);
        feeAmount = uint256(TokenHelper.convertIndexAmountToStableWithPrice(pair, int256(feeIndexTokenAmount), price)) + feeStableTokenAmount;

        receiveIndexTokenAmount -= feeIndexTokenAmount;
        receiveStableTokenAmount -= feeStableTokenAmount;

        uint256 availableIndexToken = vault.indexTotalAmount - vault.indexReservedAmount;
        uint256 availableStableToken = vault.stableTotalAmount - vault.stableReservedAmount;

        uint256 indexTokenAdd;
        uint256 stableTokenAdd;
        if (availableIndexToken < receiveIndexTokenAmount) {
            stableTokenAdd = uint256(TokenHelper.convertIndexAmountToStableWithPrice(
                pair,
                int256(receiveIndexTokenAmount - availableIndexToken),
                price));
            receiveIndexTokenAmount = availableIndexToken;
        }

        if (availableStableToken < receiveStableTokenAmount) {
            indexTokenAdd = uint256(TokenHelper.convertStableAmountToIndex(
                pair,
                int256(receiveStableTokenAmount - availableStableToken)
            )).divPrice(price);
            receiveStableTokenAmount = availableStableToken;
        }
        receiveIndexTokenAmount += indexTokenAdd;
        receiveStableTokenAmount += stableTokenAdd;

        return (
            receiveIndexTokenAmount,
            receiveStableTokenAmount,
            feeAmount,
            feeIndexTokenAmount,
            feeStableTokenAmount
        );
    }

    function _getDiscount(
        IPool.Pair memory pair,
        bool isIndex,
        uint256 delta,
        uint256 expectDelta,
        uint256 totalDelta
    ) internal pure returns (uint256 rate, uint256 amount) {
        uint256 ratio = delta.divPercentage(totalDelta);
        uint256 expectP = isIndex ? pair.expectIndexTokenP : PrecisionUtils.percentage().sub(pair.expectIndexTokenP);

        int256 unbalancedP = int256(ratio.divPercentage(expectP)) - int256(PrecisionUtils.percentage());
        if (unbalancedP < 0 && unbalancedP.abs() > pair.maxUnbalancedP) {
            rate = pair.unbalancedDiscountRate;
            amount = expectDelta.sub(delta);
        }
        return (rate, amount);
    }

    function _getStableTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = pool.lpProfit(pair.pairIndex, pair.stableToken, price);
        if (profit < 0) {
            return vault.stableTotalAmount > profit.abs() ? vault.stableTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.stableTotalAmount.add(profit.abs());
        }
    }

    function _getIndexTotalAmount(
        IPool.Pair memory pair,
        IPool.Vault memory vault,
        uint256 price
    ) internal view returns (uint256) {
        int256 profit = pool.lpProfit(pair.pairIndex, pair.indexToken, price);
        if (profit < 0) {
            return vault.indexTotalAmount > profit.abs() ? vault.indexTotalAmount.sub(profit.abs()) : 0;
        } else {
            return vault.indexTotalAmount.add(profit.abs());
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRoleManager.sol";

contract RoleManager is AccessControl, IRoleManager {
    using Address for address;

    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    mapping(address => bool) public accountBlackList;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    function addAdmin(address admin) external {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function removeAdmin(address admin) external {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function isAdmin(address admin) external view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function addPoolAdmin(address poolAdmin) external {
        grantRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function removePoolAdmin(address poolAdmin) external {
        revokeRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function isPoolAdmin(address poolAdmin) external view override returns (bool) {
        return hasRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function addOperator(address operator) external {
        grantRole(OPERATOR_ROLE, operator);
    }

    function removeOperator(address operator) external {
        revokeRole(OPERATOR_ROLE, operator);
    }

    function isOperator(address operator) external view override returns (bool) {
        return hasRole(OPERATOR_ROLE, operator);
    }

    function addTreasurer(address treasurer) external {
        grantRole(TREASURER_ROLE, treasurer);
    }

    function removeTreasurer(address treasurer) external {
        revokeRole(TREASURER_ROLE, treasurer);
    }

    function isTreasurer(address treasurer) external view override returns (bool) {
        return hasRole(TREASURER_ROLE, treasurer);
    }

    function addKeeper(address keeper) external {
        grantRole(KEEPER_ROLE, keeper);
    }

    function removeKeeper(address keeper) external {
        revokeRole(KEEPER_ROLE, keeper);
    }

    function isKeeper(address keeper) external view override returns (bool) {
        return hasRole(KEEPER_ROLE, keeper);
    }

    function addAccountBlackList(address account) public onlyRole(OPERATOR_ROLE) {
        accountBlackList[account] = true;
    }

    function removeAccountBlackList(address account) public onlyRole(OPERATOR_ROLE) {
        delete accountBlackList[account];
    }

    function isBlackList(address account) external view override returns (bool) {
        return accountBlackList[account];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBaseToken.sol";

abstract contract BaseToken is IBaseToken, ERC20, Ownable {
    bool public privateTransferMode;

    mapping(address => bool) public miners;
    mapping(address => bool) public isHandler;

    modifier onlyMiner() {
        require(miners[msg.sender], "miner forbidden");
        _;
    }

    function setPrivateTransferMode(bool _privateTransferMode) external onlyOwner {
        privateTransferMode = _privateTransferMode;
    }

    function setMiner(address account, bool enable) external virtual onlyOwner {
        miners[account] = enable;
    }

    function setHandler(address _handler, bool enable) external onlyOwner {
        isHandler[_handler] = enable;
    }

    function mint(address to, uint256 amount) public virtual onlyMiner {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public virtual onlyMiner {
        _burn(account, amount);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (privateTransferMode) {
            require(isHandler[msg.sender], "msg.sender not whitelisted");
        }
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (privateTransferMode) {
            require(isHandler[msg.sender], "msg.sender not whitelisted");
        }
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseToken {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setMiner(address account, bool enable) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

contract MYX is ERC20, Initializable {
    constructor() ERC20('MYX Token', 'MYX') {}

    function initialize(address tokenLock, uint256 supply) external initializer {
        _mint(tokenLock, supply);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import './BaseToken.sol';

contract RaMYX is BaseToken {
    constructor() ERC20('Raw MYX', 'raMYX') {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import './BaseToken.sol';

contract StMYX is BaseToken {
    constructor() ERC20('Staked MYX', 'stMYX') {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../libraries/Position.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/IPositionManager.sol";
import "../libraries/TradingTypes.sol";


contract PositionCaller {
    bytes32 private constant POSITION_MANAGER = "POSITION_MANAGER";
    bytes32 private constant FEE_COLLECTOR = "FEE_COLLECTOR";

    mapping(bytes32 => address) private _addresses;

    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    struct FundingFeeParam {
        address account;
        uint256 pairIndex;
        bool isLong;
    }

    struct TradingFeeParam{
        uint256 pairIndex;
        bool isLong;
        uint256 sizeAmount;
        uint256 price;
    }

    struct KeeperNetworkFeeParam{
        address account;
        TradingTypes.InnerPaymentType paymentType;
    }

    constructor( address _positionManager, address _feeCollector ){
        setAddress(POSITION_MANAGER, _positionManager);
        setAddress(FEE_COLLECTOR, _feeCollector);
    }

    function getAddress(bytes32 id) public view returns (address) {
        return _addresses[id];
    }

    function setAddress(bytes32 id, address newAddress) private {
        _addresses[id] = newAddress;
    }

    function getFundingFees(
        FundingFeeParam[] memory params
    ) public view returns (int256[] memory) {
        int256[] memory fundingFees = new int256[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            FundingFeeParam memory fundingFeeParam = params[i];
            int256 fundingFee = IPositionManager(getAddress(POSITION_MANAGER)).getFundingFee(fundingFeeParam.account, fundingFeeParam.pairIndex, fundingFeeParam.isLong);
            fundingFees[i] = fundingFee;
        }
        return fundingFees;
    }

    function getTradingFees(
        TradingFeeParam[] memory params
    ) public view returns (uint256[] memory) {
        uint256[] memory tradingFees = new uint256[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            TradingFeeParam memory tradingFeeParam = params[i];
            uint256 fundingFee = IPositionManager(getAddress(POSITION_MANAGER)).getTradingFee(tradingFeeParam.pairIndex, tradingFeeParam.isLong, false, tradingFeeParam.sizeAmount, tradingFeeParam.price);
            tradingFees[i] = fundingFee;
        }
        return tradingFees;
    }

    function getUserTradingFees(
        address[] memory params
    ) public view returns (uint256[] memory) {
        uint256[] memory vipRebates = new uint256[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            uint256 vipRebate = IFeeCollector(getAddress(FEE_COLLECTOR)).userTradingFee(params[i]);
            vipRebates[i] = vipRebate;
        }
        return vipRebates;
    }

    function getReferralFees(
        address[] memory params
    ) public view returns (uint256[] memory) {
        uint256[] memory referralFees = new uint256[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            uint256 referralFee = IFeeCollector(getAddress(FEE_COLLECTOR)).referralFee(params[i]);
            referralFees[i] = referralFee;
        }
        return referralFees;
    }

    function getKeeperNetworkFees(
        KeeperNetworkFeeParam[] memory params
    ) public view returns (uint256[] memory) {
        uint256[] memory networkFees = new uint256[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            KeeperNetworkFeeParam memory networkFeeParam = params[i];
            uint256 networkFee = IFeeCollector(getAddress(FEE_COLLECTOR)).getKeeperNetworkFee(networkFeeParam.account, networkFeeParam.paymentType);
            networkFees[i] = networkFee;
        }
        return networkFees;
    }

    function batchErcBalance(
        address tokenAddress,
        address[] memory accounts
    ) public view returns (uint256[] memory)  {
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 balance = IERC20(tokenAddress).balanceOf(accounts[i]);
            balances[i] = balance;
        }
        return balances;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/Upgradeable.sol";
import "../libraries/PrecisionUtils.sol";
import "../helpers/TokenHelper.sol";
import "../interfaces/ISpotSwap.sol";
import "../interfaces/IUniSwapV3Router.sol";
import "../interfaces/IPythOraclePriceFeed.sol";
import {IPool} from "../interfaces/IPool.sol";

contract SpotSwap is ISpotSwap, Upgradeable {
    using PrecisionUtils for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public swapRouter;
    mapping(address => mapping(address => bytes)) public tokenPath;

    function initialize(IAddressesProvider addressProvider) public initializer {
        ADDRESS_PROVIDER = addressProvider;
    }

    function setSwapRouter(address _router) external onlyPoolAdmin {
        swapRouter = _router;
    }

    function updateTokenPath(
        address tokenIn,
        address tokenOut,
        bytes memory path
    ) external onlyPoolAdmin {
        tokenPath[tokenIn][tokenOut] = path;
    }

    function getSwapData(
        IPool.Pair memory pair,
        address _tokenOut,
        uint256 _expectAmountOut
    ) external view returns (address tokenIn, address tokenOut, uint256 amountInMaximum, uint256 expectAmountOut) {
        uint256 price = IPythOraclePriceFeed(ADDRESS_PROVIDER.priceOracle()).getPrice(pair.indexToken);
        if (_tokenOut == pair.indexToken) {
            tokenIn = pair.stableToken;
            uint256 amountOutWithIndex = (_expectAmountOut * 12).mulPrice(price) / 10;
            amountInMaximum = uint256(TokenHelper.convertIndexAmountToStable(pair, int256(amountOutWithIndex)));
        } else if (_tokenOut == pair.stableToken) {
            tokenIn = pair.indexToken;
            uint256 amountInWithStable = (_expectAmountOut * 12).divPrice(price * 10);
            amountInMaximum = uint256(TokenHelper.convertStableAmountToIndex(pair, int256(amountInWithStable)));
        }
        return (tokenIn, _tokenOut, amountInMaximum, _expectAmountOut);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external {
        bytes memory path = tokenPath[tokenIn][tokenOut];
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        if (IERC20(tokenIn).allowance(address(this), swapRouter) < amountIn) {
            IERC20(tokenIn).safeApprove(swapRouter, type(uint256).max);
        }
        uint256 useAmountIn = IUniSwapV3Router(swapRouter).exactOutput(
            IUniSwapV3Router.ExactOutputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 1000,
                amountOut: amountOut,
                amountInMaximum: amountIn
            })
        );
        uint256 blaOut = IERC20(tokenOut).balanceOf(address(this));
        if (blaOut >= amountOut) {
            IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        } else {
            IERC20(tokenOut).safeTransfer(msg.sender, blaOut);
        }
        if (useAmountIn < amountIn) {
            IERC20(tokenIn).safeTransfer(msg.sender, amountIn.sub(useAmountIn));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    // uint256 public constant MINIMUM_DELAY = 0;
    uint256 public constant MINIMUM_DELAY = 12 hours;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;
    bool public adminInitialized;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(uint256 delay_) {
        // require(delay_ >= MINIMUM_DELAY, " Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, " Delay must not exceed maximum delay.");

        admin = msg.sender;
        delay = delay_;
        adminInitialized = false;
    }

    function setDelay(uint256 delay_) public {
        require(msg.sender == address(this), "Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (adminInitialized) {
            require(msg.sender == address(this), "Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "First call must come from admin.");
            adminInitialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "queueTransaction: Call must come from admin.");
        require(
            eta >= block.timestamp.add(delay),
            "queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Transaction hasn't been queued.");
        require(block.timestamp >= eta, "Transaction hasn't surpassed time lock.");
        require(block.timestamp <= eta.add(GRACE_PERIOD), "Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}