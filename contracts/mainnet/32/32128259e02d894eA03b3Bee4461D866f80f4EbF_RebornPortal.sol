// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

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
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(
        address owner_
    ) internal onlyInitializing {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }

        _claimOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        // compatible with hardhat-deploy, maybe removed later
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";

contract AirdropVault is IAirdropVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public immutable rebornToken;

    /**
     * @dev receive native token
     */
    receive() external payable {}

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardDegen(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function rewardNative(
        address to,
        uint256 amount
    ) external virtual override nonReentrant onlyOwner {
        payable(to).sendValue(amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        uint256 degenBalance = IERC20(rebornToken).balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        IERC20(rebornToken).safeTransfer(to, degenBalance);

        payable(to).sendValue(nativeBalance);

        emit WithdrawEmergency(to, rebornToken, degenBalance, nativeBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAirdropVaultDef {
    error ZeroAddressSet();

    event WithdrawEmergency(
        address indexed to,
        address degenToken,
        uint256 degenAmount,
        uint256 nativeAmount
    );
}

interface IAirdropVault is IAirdropVaultDef {
    function rewardDegen(address to, uint256 amount) external; // send degen reward

    function rewardNative(address to, uint256 amount) external; // send native reward

    function withdrawEmergency(address to) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IBurnPool {
    error ZeroRebornTokenSet();
    error ZeroOwnerSet();

    event Burn(uint256 amount);

    // burn expect amount of $REBORN
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IDegenShovel is IERC721AUpgradeable {
    function mint(
        address to,
        uint256 quantity
    ) external returns (uint256 startTokenId);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IPiggyBankDefinition {
    struct SeasonInfo {
        uint256 totalAmount;
        uint256 startBlock;
        bool stopped;
    }

    struct RoundInfo {
        uint256 totalAmount;
        uint256 target;
        uint256 currentIndex;
        uint256 startBlock;
    }

    struct PiggyBankSumReturns {
        uint256 seasonTotalAmount;
        bool isEnd;
        uint256 roundTotalAmount;
        uint256 roundTarget;
        uint256 roundNextMultiple;
        uint256 roundIndex;
        uint256 roundStartBlock;
        uint256 countDownBlockLong;
    }

    struct UserInfo {
        uint256 amount;
        uint256 claimedAmount;
    }

    event WithdrawEmergency(address receiver, uint256 amount);
    event InitializeSeason(
        uint256 season,
        uint256 seasonStartBlock,
        RoundInfo roundInfo
    );
    event SetNewMultiple(uint8 multiple);
    event Deposit(
        uint256 season,
        address account,
        uint256 roundIndex,
        uint256 amount,
        uint256 roundTotalAmount
    );
    event SeasonStopped(uint256 season, uint256 stopBlockNumber);
    event SignerUpdate(address indexed signer, bool valid);
    event SetStoppedHash(
        uint256 season,
        bytes32 stoppedHash,
        address verifySigner
    );
    event ClaimedReward(uint256 season, address account, uint256 amount);
    event SetNewCountDownBlockLong(uint256 countDownBlockLong);
    event SetIsClaimOpened(bool isClaimOpened);
    event SetNewRoundRewardPercentage(uint16 percentage);
    event RewardUserWhoChangeRound(
        address account,
        uint256 season,
        uint256 roundIndex,
        uint256 amount
    );

    error CallerNotPortal();
    error InvalidRoundInfo();
    error SeasonOver();
    error InvalidSeason();
    error AlreadyClaimed();
    error SeasonNotOver();
    error CountDownBlockLongNotSet();
    error CanNotClaim();
}

interface IPiggyBank is IPiggyBankDefinition {
    function deposit(
        uint256 season,
        address account,
        uint256 income
    ) external payable;

    function setMultiple(uint8 multiple_) external;

    function checkIsSeasonEnd(uint256 season) external view returns (bool);

    function stop(uint256 season) external;

    function initializeSeason(
        uint256 season,
        uint256 seasonStartBlock,
        uint256 initRoundTarget
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {PortalLib} from "src/PortalLib.sol";
import {BitMapsUpgradeable} from "src/oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

interface IRebornDefinition {
    struct InnateParams {
        uint256 talentNativePrice;
        uint256 talentDegenPrice;
        uint256 propertyNativePrice;
        uint256 propertyDegenPrice;
    }

    struct ReferParams {
        address parent;
        address grandParent;
    }

    struct SoupParams {
        uint256 soupPrice;
        uint256 charTokenId;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct ExhumeParams {
        address exhumee;
        uint256 tokenId;
        uint256 nativeCost;
        uint256 degenCost;
        uint256 shovelTokenId; // if no shovel, tokenId is 0
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct PermitParams {
        uint256 amount;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct LifeDetail {
        bytes32 seed;
        address creator; // ---
        // uint96 max 7*10^28  7*10^10 eth  //   |
        uint96 reward; // ---
        uint96 rebornCost; // ---
        uint16 age; //   |
        uint32 round; //   |
        // uint64 max 1.8*10^19             //   |
        uint64 score; //   |
        uint48 nativeCost; // only with decimal of 10^6 // ---
        string creatorName;
    }

    struct SeasonData {
        mapping(uint256 => PortalLib.Pool) pools;
        /// @dev user address => pool tokenId => Portfolio
        mapping(address => mapping(uint256 => PortalLib.Portfolio)) portfolios;
        uint256 _placeholder;
        uint256 _placeholder2;
        uint256 _placeholder3;
        uint256 _placeholder4;
        uint256 _placeholder5;
        uint256 _jackpot;
    }

    struct AirDropDebt {
        uint128 nativeDebt;
        uint128 degenDebt;
    }

    struct ClaimRewardParams {
        address user;
        uint256 amount;
        uint256 t;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    event AirdropNative();
    event AirdropDegen();

    event Exhume(
        address indexed exhumer,
        address exhumee,
        uint256 indexed tokenId,
        uint256 indexed shovelTokenId,
        uint256 nonce,
        uint256 nativeCost,
        uint256 degenCost,
        uint256 nativeToJackpot
    );

    enum AirdropVrfType {
        Invalid,
        DropReborn,
        DropNative
    }

    enum TributeDirection {
        Reverse,
        Forward
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        bool executed; // whether the airdrop is executed
        AirdropVrfType t;
        uint256 randomWords; // we only need one random word. keccak256 to generate more
    }

    struct VrfConf {
        bytes32 keyHash;
        uint64 s_subscriptionId;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint16 requestConfirmations;
    }

    struct AirdropConf {
        bool _dropOn; //                  ---
        bool _lockRequestDropReborn;
        bool _lockRequestDropNative;
        uint24 _rebornDropInterval; //        |
        uint24 _nativeDropInterval; //        |
        uint32 _rebornDropLastUpdate; //      |
        uint32 _nativeDropLastUpdate; //      |
        uint120 _placeholder;
    }

    struct EngraveParams {
        uint256 tokenId;
        bytes32 seed;
        uint256 reward;
        uint256 score;
        uint256 age;
        uint256 nativeCost;
        uint256 rebornCost;
        uint256 shovelAmount;
        uint256 charTokenId;
        uint256 recoveredAP;
        string creatorName;
    }

    // define degen reward is odd, native reward is even
    enum RewardToClaimType {
        Invalid,
        EngraveDegen, // 1
        ReferNative, // 2
        ReferDegen // 3
    }

    struct RewardStore {
        uint256 totalReward;
        uint256 rewardDebt;
    }

    event ClaimReward(
        address indexed user,
        RewardToClaimType indexed t,
        uint256 amount
    );

    event ClaimDegenReward(
        address indexed user,
        uint256 indexed nonce,
        uint256 amount,
        uint256 t,
        bytes32 r,
        bytes32 s,
        uint8 v
    );

    event Refer(address referee, address referrer);

    event Incarnate(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed charTokenId,
        uint256 talentNativePrice,
        uint256 talentRebornPrice,
        uint256 propertyNativePrice,
        uint256 propertyRebornPrice,
        uint256 soupPrice
    );

    event Engrave(
        bytes32 indexed seed,
        address indexed user,
        uint256 indexed tokenId,
        uint256 score,
        uint256 reward,
        uint256 shovelAmount,
        uint256 startTokenId,
        uint256 charTokenId,
        uint256 recoveredAP
    );

    event Infuse(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    );

    event Baptise(
        address indexed user,
        uint256 amount,
        uint256 indexed baptiseType
    );

    event NewSoupPrice(uint256 price);

    event SwitchPool(
        address indexed user,
        uint256 indexed fromTokenId,
        uint256 indexed toTokenId,
        uint256 fromAmount,
        uint256 reStakeAmount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    );

    /// @dev event about the vault address is set
    event VaultSet(address rewardVault);

    event AirdropVaultSet(address airdropVault);

    event NewSeason(uint256 newSeason);

    event NewIncarnationLimit(uint256 limit);

    event ForgedTo(
        uint256 indexed tokenId,
        uint256 newLevel,
        uint256 burnTokenAmount
    );

    event SetNewPiggyBankFee(uint256 piggyBankFee);

    event ClaimNativeAirdrop(uint256 amount);
    event ClaimDegenAirdrop(uint256 amount);

    event NativeDropRootSet(bytes32, uint256);
    event DegenDropRootSet(bytes32, uint256);

    /// @dev revert when the random seed is duplicated
    error SameSeed();

    /// @dev revert when incarnation count exceed limit
    error IncarnationExceedLimit();

    error InvalidProof();

    error NoRemainingReward();

    error SeasonAlreadyStopped();
}

interface IRebornPortal is IRebornDefinition {
    /**
     * @dev user buy the innate for the life
     * @param innate talent and property choice
     * @param referParams refer params
     */
    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata charParams
    ) external payable;

    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata charParams,
        PermitParams calldata permitParams
    ) external payable;

    function engrave(EngraveParams calldata engraveParams) external;

    /**
     * @dev reward for share the game
     * @param user user address
     * @param amount amount for reward
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external;

    /**
     * @dev stake $REBORN on this tombstone
     * @param tokenId tokenId of the life to stake
     * @param amount stake amount, decimal 10^18
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external;

    /**
     * @dev stake $REBORN with permit
     * @param tokenId tokenId of the life to stake
     * @param amount amount of $REBORN to stake
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        PermitParams calldata permitParams
    ) external;

    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    ) external;

    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata proof
    ) external;

    /**
     * @dev switch to next season, call by owner
     */
    function toNextSeason() external;

    /**
     * @dev claim reward set by merkle tree
     */
    function claimReward(RewardToClaimType t) external;

    /**
     * @dev claim $DEGEN reward via signer signature
     */
    function claimDegenReward(
        ClaimRewardParams calldata claimRewardParams
    ) external;

    /**
     * @dev get current nonce for claim $DEGEN reward via signature
     */
    function getClaimDegenNonces(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC20Upgradeable} from "src/oz/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20PermitUpgradeable} from "src/oz/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface IRebornTokenDef {
    /// @dev revert when the caller is not minter
    error NotMinter();
    /// @dev disable upgrade
    error CannotUpgradeAnyMore();
    /// @dev emit when minter is updated
    event MinterUpdate(address minter, bool valid);
}

interface IRebornToken is
    IERC20Upgradeable,
    IERC20PermitUpgradeable,
    IRebornTokenDef
{
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRegistry {
    event SignerUpdate(address signer, bool valid);

    function checkIsSigner(address addr) external view returns (bool);

    function getDegen() external view returns (address);

    function getPortal() external view returns (address);

    function getShovel() external view returns (address);

    function getPiggyBank() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IRewardVault {
    error ZeroAddressSet();
    
    function reward(address to, uint256 amount) external; // send reward

    function withdrawEmergency(address to) external;

    event WithdrawEmergency(address p12Token, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ArbSys} from "src/interfaces/ArbSys.sol";

library BlockNumberReader {
    function getBlockNumber() internal view returns (uint256) {
        // arbitrum one  arbitrum goerli
        if (block.chainid == 0xa4b1 || block.chainid == 0x66eed) {
            return ArbSys(address(0x64)).arbBlockNumber();
        }
        // in other case, just return BlockNumberReader.getBlockNumber()
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library CommonError {
    error ZeroAddressSet();
    error InvalidParams();
    /// @dev revert when to caller is not signer
    error NotSigner();
    error NotPortal();
    error ExhumeeNotTombStoneOwner();
    error NotShovelOwner();
    error TombstoneNotEngraved();
    error SignatureExpired();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant {
    string internal constant _P1 =
        '<svg width="1244" height="704" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path d="M2.5 701.5V95.051L97.02 2.5H1241.5v699H2.5z" fill="url(#prefix__p0)" stroke="url(#prefix__p1)" stroke-width="5"/><path d="M1240 10H86.11v2.346H1240V10zM76.727 19.384H1240v2.346H76.727v-2.346zM4 169.529h1236v2.346H4v-2.346zM1240 56.92H39.19v2.346H1240V56.92zM4 207.066h1236v2.346H4v-2.346zM1240 94.457H4v2.346h1236v-2.346zM4 329.059h1236v2.346H4v-2.346zM1240 244.602H4v2.346h1236v-2.346zM4 131.993h1236v2.346H4v-2.346zM1240 282.138H4v2.346h1236v-2.346zM57.959 38.152H1240v2.346H57.959v-2.346zM1240 188.298H4v2.346h1236v-2.346zM20.422 75.689H1240v2.346H20.422v-2.346zM1240 310.291H4v2.346h1236v-2.346zM4 225.834h1236v2.346H4v-2.346zM1240 113.225H4v2.346h1236v-2.346zM4 263.37h1236v2.346H4v-2.346zM1240 150.761H4v2.346h1236v-2.346zM4 300.907h1236v2.346H4v-2.346zM4 160.145h1236v2.346H4v-2.346zM1240 47.536H48.574v2.346H1240v-2.346zM4 197.682h1236v2.346H4v-2.346zM1240 85.073H11.038v2.346H1240v-2.346zM4 319.675h1236v2.346H4v-2.346zM1240 235.218H4v2.346h1236v-2.346zM4 122.609h1236v2.346H4v-2.346zM1240 272.754H4v2.346h1236v-2.346zM67.343 28.768H1240v2.346H67.343v-2.346zM1240 178.913H4v2.347h1236v-2.347zM29.806 66.305H1240v2.345H29.806v-2.346zM1240 216.45H4v2.346h1236v-2.346zM4 103.841h1236v2.346H4v-2.346zM1240 338.443H4v2.346h1236v-2.346zM4 253.986h1236v2.346H4v-2.346zM1240 141.377H4v2.346h1236v-2.346zM4 291.522h1236v2.346H4v-2.346zM4 347.827h1236v2.346H4v-2.346zM1240 357.211H4v2.346h1236v-2.346zM1240 507.356H4v2.346h1236v-2.346zM4 394.747h1236v2.346H4v-2.346zM1240 544.893H4v2.346h1236v-2.346zM4 432.284h1236v2.346H4v-2.346zM1240 666.886H4v2.346h1236v-2.346zM4 582.429h1236v2.346H4v-2.346zM1240 469.82H4v2.346h1236v-2.346zM4 619.965h1236v2.346H4v-2.346zM1240 375.979H4v2.346h1236v-2.346zM4 526.125h1236v2.346H4v-2.346zM1240 413.516H4v2.346h1236v-2.346zM4 648.118h1236v2.346H4v-2.346zM1240 563.661H4v2.346h1236v-2.346zM4 451.052h1236v2.346H4v-2.346zM1240 601.197H4v2.346h1236v-2.346zM4 488.588h1236v2.346H4v-2.346zM1240 638.734H4v2.346h1236v-2.346zM1240 497.972H4v2.346h1236v-2.346zM4 385.363h1236v2.346H4v-2.346zM1240 535.509H4v2.346h1236v-2.346zM4 422.9h1236v2.346H4V422.9zM1240 657.502H4v2.346h1236v-2.346zM4 573.045h1236v2.346H4v-2.346zM1240 460.436H4v2.346h1236v-2.346zM4 610.581h1236v2.346H4v-2.346zM1240 366.595H4v2.346h1236v-2.346zM4 516.74h1236v2.346H4v-2.346zM1240 404.131H4v2.347h1236v-2.347zM4 554.277h1236v2.346H4v-2.346zM1240 441.668H4v2.346h1236v-2.346zM4 676.27h1236v2.346H4v-2.346zM1240 685.654H4V688h1236v-2.346zM4 591.813h1236v2.346H4v-2.346zM1240 479.204H4v2.346h1236v-2.346zM4 629.349h1236v2.346H4v-2.346z" fill="url(#prefix__p2)"/><path d="M1244 12V0H96L0 94v18L102 12h1142z" fill="#F98701"/><text dx="76" dy="605" dominant-baseline="central" style="height:100px" font-family="VT323" textLength="1075" font-size="60" fill="#FF8A01">Seed: ';
    string internal constant _P2 =
        '</text><text dx="76" dy="100" dominant-baseline="central" font-family="Black Ops One" textLength="300" font-weight="400" font-size="60" fill="#FF8A01">LifeScore</text><text dx="76" dy="230" dominant-baseline="central" font-family="Black Ops One" font-weight="400" font-size="120" fill="#FF8A01">';
    string internal constant _P3 =
        '</text><text dx="697" dy="425" dominant-baseline="central" font-family="VT323" font-weight="100" font-size="79" fill="#FFF">Re:';
    string internal constant _P4 =
        '</text><text dx="955" dy="425" dominant-baseline="central" font-family="VT323" font-weight="400" font-size="78" fill="#FFF">Age:';
    string internal constant _P5 =
        '</text><text dx="200" dy="425" dominant-baseline="central" text-anchor="left" font-family="VT323" font-weight="400" font-size="60" fill="#FFF">';
    string internal constant _P6 =
        '</text><text dx="975" dy="100" dominant-baseline="central" text-anchor="middle" style="height:100px" font-family="Black Ops One" font-size="56" fill="#FF8A01">DegenReborn</text><text dx="1070" dy="190" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P7 =
        '</text><text dx="1070" dy="275" dominant-baseline="central" text-anchor="end" font-family="VT323" font-weight="400" font-size="80" fill="url(#prefix__p75)">';
    string internal constant _P8 =
        '</text><svg version="1.1" id="prefix__Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="1100" y="145" viewBox="0 13 1000 540" xml:space="preserve"><circle cx="32" cy="32" r="29.5" fill="#ECEFF0"/><path opacity=".2" fill-rule="evenodd" clip-rule="evenodd" d="M32 9.87L18 32.5l14 8 14-8L32 9.87z" fill="#828384"/><path d="M18 32.5L32 9.87V40.5l-14-8z" fill="#343535"/><path d="M46 32.5L32 9.87V40.5l14-8z" fill="#131313"/><path d="M18 32.5L32 9.87V26.5l-14 6z" fill="#828384"/><path d="M46 32.5L32 9.87V26.5l14 6zM46 34.5L32 43v11l14-19.5z" fill="#2F3030"/><path d="M18 34.5L32 43v11L18 34.5z" fill="#828384"/></svg>';

    string internal constant _P9 =
        '<path fill="#FFD058" d="M1125 256v5h-5v-5z"/><path fill="#E86609" d="M1145 256v5h-5v-5z"/><path fill="#F8C156" d="M1165 256v5h-5v-5z"/><path fill="#fff" d="M1115 256v5h-5v-5z"/><path fill="#E86609" d="M1135 256v5h-5v-5z"/><path fill="#F8C156" d="M1155 256v5h-5v-5z"/><path fill="#000" d="M1175 256v5h-5v-5zM1110 256v5h-5v-5z"/><path fill="#FFD058" d="M1130 256v5h-5v-5z"/><path fill="#C04A07" d="M1150 256v5h-5v-5z"/><path fill="#F29914" d="M1170 256v5h-5v-5z"/><path fill="#FFD058" d="M1120 256v5h-5v-5z"/><path fill="#E86609" d="M1140 256v5h-5v-5z"/><path fill="#F8C156" d="M1160 256v5h-5v-5z"/><path fill="#fff" d="M1125 246v5h-5v-5z"/><path fill="#F8C156" d="M1145 246v5h-5v-5z"/><path fill="#000" d="M1165 246v5h-5v-5z"/><path fill="#FFD058" d="M1135 246v5h-5v-5z"/><path fill="#F29914" d="M1155 246v5h-5v-5z"/><path fill="#fff" d="M1130 246v5h-5v-5z"/><path fill="#F8C156" d="M1150 246v5h-5v-5z"/><path fill="#000" d="M1120 246v5h-5v-5z"/><path fill="#FFD058" d="M1140 246v5h-5v-5z"/><path fill="#F29914" d="M1160 246v5h-5v-5z"/><path fill="#000" d="M1130 236h5v5h-5zM1105 266v5h-5v-5z"/><path fill="#FFD058" d="M1125 266v5h-5v-5z"/><path fill="#F8C156" d="M1145 266v5h-5v-5zM1165 266v5h-5v-5z"/><path fill="#FFD058" d="M1115 266v5h-5v-5z"/><path fill="#C04A07" d="M1135 266v5h-5v-5zM1155 266v5h-5v-5z"/><path fill="#F29914" d="M1175 266v5h-5v-5z"/><path fill="#fff" d="M1110 266v5h-5v-5z"/><path fill="#E86609" d="M1130 266v5h-5v-5zM1150 266v5h-5v-5z"/><path fill="#F8C156" d="M1170 266v5h-5v-5z"/><path fill="#FFD058" d="M1120 266v5h-5v-5zM1140 266v5h-5v-5z"/><path fill="#F8C156" d="M1160 266v5h-5v-5z"/><path fill="#000" d="M1180 266v5h-5v-5zM1125 241v5h-5v-5z"/><path fill="#F29914" d="M1145 241v5h-5v-5z"/><path fill="#fff" d="M1135 241v5h-5v-5z"/><path fill="#000" d="M1155 241v5h-5v-5zM1130 241v5h-5v-5z"/><path fill="#F29914" d="M1150 241v5h-5v-5z"/><path fill="#fff" d="M1140 241v5h-5v-5z"/><path fill="#000" d="M1160 241v5h-5v-5z"/><path fill="#FFD058" d="M1125 261v5h-5v-5z"/><path fill="#F8C056" d="M1145 261v5h-5v-5z"/><path fill="#F8C156" d="M1165 261v5h-5v-5z"/><path fill="#fff" d="M1115 261v5h-5v-5z"/><path fill="#C04A07" d="M1135 261v5h-5v-5zM1155 261v5h-5v-5z"/><path fill="#000" d="M1175 261v5h-5v-5zM1110 261v5h-5v-5z"/><path fill="#E86609" d="M1130 261v5h-5v-5zM1150 261v5h-5v-5z"/><path fill="#F29914" d="M1170 261v5h-5v-5z"/><path fill="#FFD058" d="M1120 261v5h-5v-5zM1140 261v5h-5v-5z"/><path fill="#F8C156" d="M1160 261v5h-5v-5z"/><path fill="#FFD058" d="M1125 251v5h-5v-5z"/><path fill="#F8C156" d="M1145 251v5h-5v-5z"/><path fill="#F29914" d="M1165 251v5h-5v-5z"/><path fill="#000" d="M1115 251v5h-5v-5z"/><path fill="#FFD058" d="M1135 251v5h-5v-5z"/><path fill="#F8C156" d="M1155 251v5h-5v-5z"/><path fill="#FFD058" d="M1130 251v5h-5v-5z"/><path fill="#F8C156" d="M1150 251v5h-5v-5z"/><path fill="#000" d="M1170 251v5h-5v-5z"/><path fill="#fff" d="M1120 251v5h-5v-5z"/><path fill="#FFD058" d="M1140 251v5h-5v-5z"/><path fill="#F8C156" d="M1160 251v5h-5v-5z"/><path fill="#000" d="M1135 236h5v5h-5zM1105 271v5h-5v-5z"/><path fill="#FFD058" d="M1125 271v5h-5v-5z"/><path fill="#E86609" d="M1145 271v5h-5v-5z"/><path fill="#F8C156" d="M1165 271v5h-5v-5z"/><path fill="#FFD058" d="M1115 271v5h-5v-5z"/><path fill="#E86609" d="M1135 271v5h-5v-5z"/><path fill="#F8C156" d="M1155 271v5h-5v-5z"/><path fill="#F29914" d="M1175 271v5h-5v-5z"/><path fill="#fff" d="M1110 271v5h-5v-5z"/><path fill="#E86609" d="M1130 271v5h-5v-5z"/><path fill="#C04A07" d="M1150 271v5h-5v-5z"/><path fill="#F8C156" d="M1170 271v5h-5v-5z"/><path fill="#FFD058" d="M1120 271v5h-5v-5z"/><path fill="#E86609" d="M1140 271v5h-5v-5z"/><path fill="#F8C156" d="M1160 271v5h-5v-5z"/><path fill="#000" d="M1180 271v5h-5v-5zM1140 236h5v5h-5zM1105 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 276v5h-5v-5z"/><path fill="#F8C056" d="M1145 276v5h-5v-5z"/><path fill="#F8C156" d="M1165 276v5h-5v-5z"/><path fill="#FFD058" d="M1115 276v5h-5v-5z"/><path fill="#C04A07" d="M1135 276v5h-5v-5zM1155 276v5h-5v-5z"/><path fill="#F29914" d="M1175 276v5h-5v-5z"/><path fill="#fff" d="M1110 276v5h-5v-5z"/><path fill="#E86609" d="M1130 276v5h-5v-5zM1150 276v5h-5v-5z"/><path fill="#F8C156" d="M1170 276v5h-5v-5z"/><path fill="#FFD058" d="M1120 276v5h-5v-5zM1140 276v5h-5v-5z"/><path fill="#F8C156" d="M1160 276v5h-5v-5z"/><path fill="#000" d="M1180 276v5h-5v-5z"/><path fill="#FFD058" d="M1125 296v5h-5v-5z"/><path fill="#F8C156" d="M1145 296v5h-5v-5z"/><path fill="#F29914" d="M1165 296v5h-5v-5z"/><path fill="#000" d="M1115 296v5h-5v-5z"/><path fill="#FFD058" d="M1135 296v5h-5v-5z"/><path fill="#F8C156" d="M1155 296v5h-5v-5z"/><path fill="#FFD058" d="M1130 296v5h-5v-5z"/><path fill="#F8C156" d="M1150 296v5h-5v-5z"/><path fill="#000" d="M1170 296v5h-5v-5z"/><path fill="#fff" d="M1120 296v5h-5v-5z"/><path fill="#FFD058" d="M1140 296v5h-5v-5z"/><path fill="#F8C156" d="M1160 296v5h-5v-5z"/><path fill="#FFD058" d="M1125 286v5h-5v-5z"/><path fill="#F8C156" d="M1145 286v5h-5v-5zM1165 286v5h-5v-5z"/><path fill="#fff" d="M1115 286v5h-5v-5z"/><path fill="#C04A07" d="M1135 286v5h-5v-5z"/><path fill="#E86609" d="M1155 286v5h-5v-5z"/><path fill="#000" d="M1175 286v5h-5v-5zM1110 286v5h-5v-5z"/><path fill="#E86609" d="M1130 286v5h-5v-5z"/><path fill="#F8C056" d="M1150 286v5h-5v-5z"/><path fill="#F29914" d="M1170 286v5h-5v-5z"/><path fill="#FFD058" d="M1120 286v5h-5v-5zM1140 286v5h-5v-5z"/><path fill="#C04A07" d="M1160 286v5h-5v-5z"/><path fill="#000" d="M1125 306v5h-5v-5z"/><path fill="#F29914" d="M1145 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1135 306v5h-5v-5z"/><path fill="#000" d="M1155 306v5h-5v-5zM1130 306v5h-5v-5z"/><path fill="#F29914" d="M1150 306v5h-5v-5z"/><path fill="#FFE6A6" d="M1140 306v5h-5v-5z"/><path fill="#000" d="M1160 306v5h-5v-5zM1145 236h5v5h-5zM1105 281v5h-5v-5z"/><path fill="#FFD058" d="M1125 281v5h-5v-5z"/><path fill="#F8C056" d="M1145 281v5h-5v-5z"/><path fill="#F8C156" d="M1165 281v5h-5v-5z"/><path fill="#FFD058" d="M1115 281v5h-5v-5z"/><path fill="#C04A07" d="M1135 281v5h-5v-5zM1155 281v5h-5v-5z"/><path fill="#F29914" d="M1175 281v5h-5v-5z"/><path fill="#fff" d="M1110 281v5h-5v-5z"/><path fill="#E86609" d="M1130 281v5h-5v-5zM1150 281v5h-5v-5z"/><path fill="#F8C156" d="M1170 281v5h-5v-5z"/><path fill="#FFD058" d="M1120 281v5h-5v-5zM1140 281v5h-5v-5z"/><path fill="#F8C156" d="M1160 281v5h-5v-5z"/><path fill="#000" d="M1180 281v5h-5v-5z"/><path fill="#fff" d="M1125 301v5h-5v-5z"/><path fill="#F8C156" d="M1145 301v5h-5v-5z"/><path fill="#000" d="M1165 301v5h-5v-5z"/><path fill="#FFD058" d="M1135 301v5h-5v-5z"/><path fill="#F29914" d="M1155 301v5h-5v-5z"/><path fill="#fff" d="M1130 301v5h-5v-5z"/><path fill="#F8C156" d="M1150 301v5h-5v-5z"/><path fill="#000" d="M1120 301v5h-5v-5z"/><path fill="#FFD058" d="M1140 301v5h-5v-5z"/><path fill="#F29914" d="M1160 301v5h-5v-5z"/><path fill="#FFD058" d="M1125 291v5h-5v-5z"/><path fill="#F8C156" d="M1145 291v5h-5v-5zM1165 291v5h-5v-5z"/><path fill="#fff" d="M1115 291v5h-5v-5z"/><path fill="#FFD058" d="M1135 291v5h-5v-5z"/><path fill="#F8C056" d="M1155 291v5h-5v-5z"/><path fill="#000" d="M1175 291v5h-5v-5zM1110 291v5h-5v-5z"/><path fill="#FFD058" d="M1130 291v5h-5v-5z"/><path fill="#F8C156" d="M1150 291v5h-5v-5z"/><path fill="#F29914" d="M1170 291v5h-5v-5z"/><path fill="#FFD058" d="M1120 291v5h-5v-5zM1140 291v5h-5v-5z"/><path fill="#F8C056" d="M1160 291v5h-5v-5z"/><path fill="#000" d="M1145 311v5h-5v-5zM1135 311v5h-5v-5zM1150 311v5h-5v-5zM1140 311v5h-5v-5z"/>';

    function P1() public pure returns (string memory) {
        return _P1;
    }

    function P2() public pure returns (string memory) {
        return _P2;
    }

    function P3() public pure returns (string memory) {
        return _P3;
    }

    function P4() public pure returns (string memory) {
        return _P4;
    }

    function P5() public pure returns (string memory) {
        return _P5;
    }

    function P6() public pure returns (string memory) {
        return _P6;
    }

    function P7() public pure returns (string memory) {
        return _P7;
    }

    function P8() public pure returns (string memory) {
        return _P8;
    }

    function P9() public pure returns (string memory) {
        return _P9;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";

library RenderConstant2 {

    string internal constant _P10 =
        '<svg xmlns="http://www.w3.org/2000/svg" x="72" y="380"><svg width="120" height="120"><clipPath id="prefix__clipCircle"><circle cx="48" cy="48" r="48"/></clipPath><circle cx="48" cy="48" r="48" fill="#C8145C"/><g clip-path="url(#prefix__clipCircle)"><path fill="#FA6000" d="M29.633 48.617l-86.61-83.057 83.056-86.611 86.611 83.057z"/><path fill="#F5AF00" d="M63.4 142.048l-119.678 8.788-8.788-119.677L54.61 22.37z"/><path fill="#03585E" d="M21.906-1.682l9.833 119.597-119.596 9.832L-97.69 8.151z"/></g></svg></svg><defs><linearGradient id="prefix__p0" x1="622.044" y1="-2.347" x2="622.044" y2="678.332" gradientUnits="userSpaceOnUse"><stop stop-color="#452F16"/><stop offset="1" stop-color="#1B2023"/></linearGradient><linearGradient id="prefix__p1" x1="622.044" y1="-2.347" x2="622.044" y2="668.943" gradientUnits="userSpaceOnUse"><stop stop-color="#FF8A00"/><stop offset="1" stop-color="#52391B"/></linearGradient><linearGradient id="prefix__p2" x1="622.171" y1="-1.73" x2="622.171" y2="347.827" gradientUnits="userSpaceOnUse"><stop stop-color="#F78602" stop-opacity=".35"/><stop offset="1" stop-color="#F78602" stop-opacity="0"/></linearGradient><linearGradient id="prefix__p75" x1="919" y1="180" x2="919" y2="276" gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFDA"/><stop offset=".503" stop-color="#FFE7B6"/><stop offset="1" stop-color="#A87945"/></linearGradient><pattern id="prefix__pattern0" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#prefix__image0_539_2800" transform="matrix(.00255 0 0 .00255 -.639 -1.77)"/></pattern></defs><style>@font-face{font-family:&apos;Black Ops One&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,d09GMgABAAAAAAe0AAoAAAAAEBwAAAdnAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmAAhAoKj2CKLws4AAE2AiQDbAQgBYcrB1gbgQxRlG1Si+zngW1MPbihDBOihmC7LZoLmHL+w+L7alc4tb07Sb6TLCvArudVcokgSMYCOeyWnQJyUmK7gOyU2cnT1dpu6AyhbsQlvku/F5GQMzxf3Ojttr80wCYIJIkgMEjkUC//+6v/b63VE2+INR28VC+BkInr7/7NCWLLYOaVTqZEc6lEoqdISZn/938VOLtupE7d8MC/NdYBXGLQbDzgb+4KgKXnNfHPoSp2HgbAWFBlhyuLfAmEjkPNM0jT598+EP161wHmAQDu4usAgIoAMlY5CACgAbLSlOP9LQA0pt5IiJqaaY8kMbhCsVLTjw5RDVZD1FBVr/6lqmp5taJaSa1cIbBC0P8kghh5Xe8incP3Z3Fcbyc3XXTBSUfttMN2xTZf2fvb+8H73vvO+8r7zFvixSM98T72Pnry6clHQDwQINSQALAIAgBMOF7QUCZKxE4Lsk6nhODn/48lIBCCgkMgFAAgLBwgAgjWY2ljSWu/6CkA3gdyLg8DAkylRJjJMS/b2nhai9NqKNVwEvciazRUI4CIUzl/f3E2gj8ncpwgcJwMoIVeEK9aYLzESYzjKCeKHI12OvMLrOZYizXGZIkym+ITRSLjOIXITDILJp1FY5Wxllp5EcUqwjDijyViVXjJjE06XICsMmghHyngz2uRfCw8KlozQoJ3lmdBMshYccqChEUoiHFycRJO5QOxH7ZDDUoCzo3lMkCE1HYikchmyCOYdkrSh3eS2ECsgzynnCdbNpExxEvEEhhKSEiEiHA0kUtN9yeSZitTMI2weFEUTOnrgoQVIhMtwtFEgTkHOOV8JUqjhYLfjkGiIxIJydi/QLZbueSz/AJmx44wNn1avDZh2JFR/InOQqwSVswNddQiJVqWgCE8EkldVVoycybZwvtE04HtEbOQdM4fQuIWW+X8YUiBKJYgocxubuFMlLA5BiltoIG5ggRRTlYe5zGZ+mvyitFCwIa+YBpIOAnKiyAyA8kWMZC4R5Kj8ZpNIPRIGQuzYdo/a9y0eZPmG4uay9RG6zc1Zk4t1hc1XTbMpQXU2cjdaCeFAayHcRelBkq/MiIy+vfuCmFAp5InrgmuwHcLO7EsBoMeRzCpGwC66jd1R79uzCZG734xnuAyx3wp+QI76zZ80zBsF6P8ctfyiTLTtJkXeYvS0oiuJ6XASEqvuD1d9VCGr1PkWEgWHmp//ZDtV3WHUf4qfSMwoN+Trcxwe1W//gk+ibImlN5ldIFnQW0GObW5jVi2ybCJ6SacSV/LIilNr3zqDNvTJMmHyPeWlALpkNR7vKsqK7tI9yTpbz3fHB74POoYglaOXzmOY3QQOy4e9x3XH2ed2RX9Fd8V8QqzUYpXuK7GCqAaUNhGw0YW2/ydffnCWE1Go9mGmj3Esi+MxrvjNzDIZl31Xd+YMgwxqnOpOjyjCPg6bsw49AYrLq2npfQITzfSmT3aPGcXTKnXqM7dzF6h3uVtK9FZTCWwd/ne/6GbgXou6hk7wcwrV8ou3PfMWDZD/VFQ9K01YzUYXXgvA1gnSqWKnsKML4GvXs9oSzxPaaF7ZdevYAPe4wbe09l3tvLZiePGf2c0iFGwURpE6S4jG7XqNMumdNWoUb7The4sevyMOxUdeud+x3IpdYwp8vV3THDBLIOd2VeIf76ytru5BgZMyxhMd7gKM/RFGQonUnGgI/TgtU9nTxgPwvziCE+Efm+x0WOEmoajWfPm//78uckY41FjGWNXY47KDl9n35DKQ1jVg7pgM7qNOAIf9nxM7d0/gQIAAABAAFAJLSP/rVNXLX9RiQIAwNMfu6cCAO/F9yUg/6cLp3IaAIUjuJvicM3j0EDt32DtXr/VgrVdYl4eGTSzzMxBg3KPLcNgmYcG2rwlEBquPH5kj8/OVaOZ0uit6WaHOSM9nSBKDUhNA0hdpjGmJaT2DPb0pBJrxnxkK9lNrwIyAHbpx89ZQJLiIYoQWTzCNCyIMBiMOMGmIl51q5Ag0AXQEenjpmgYAOz2ByMkoooQpqtTiGheNxCnekuIF9WNkMDYU4boNO4dd6KYZxva/sOUSmpczGVxH1K4o87/M4Y+6z+8HG6N96J6546j3jiqT+HM/UV8el92+EFx4s1KCpSJKfyvkxzjcqxbt2GLSJP4OWhGM9MBt/U2Aeefa+Ki0tWsLrivWjqKiw7WOUfeq2nthrWb1GpkejibbEI1+X8uS9o4u8e9E4UWEaFUmTVioUgH1FfXUEJURR1Ifdz33hjMMFzcq2POSKWzQmOxSvjMrthOf2YVKaHFuGo+6IBjtb7qqMMqdpbtOY4yCeQWHAnGaRlgSrHi07LtZTBXkoM+8b03hwpgF1BAQTck1Lt+t3FRW111NdRCJBPhF8cKXvRzwJ3N3h9IYvPbiONe6QvlYbXNJIB7g5SiduHuDOeAoKmRNvTeRC2NmAYhw6Z+7fdob8eIkNaxPiRzJBC6Pr4PmmgBAAD+b+bQvTpG1lEEChLsHiilNMJpy27LqayKOupqpLFOaCwOT6TRWQAAAA==) format(&apos;woff2&apos;);unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}@font-face{font-family:&apos;VT323&apos;;font-style:normal;font-weight:400;src:url(data:application/font;base64,d09GMgABAAAAABpUAA4AAAAAwJAAABn7AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGigbHhyEWAZgAIRkEQgKgt9ogpQEC4NUAAE2AiQDhxQEIAWDMAeFORvkl7OierTQkYFg44D8Br48ijKxSrP/QwI9xDJPsV1kGEewHZHdaEZDW0vovnTgTesJ6y6hT6byUn9rJv+1GZUb+4yM74yReC7Pf7/f69rnBskCaRQKFaHQMS6l8dW+HZ+4/vrYd3/+nfPPTVJV8AXzVHAvYsGkYkA7CBNzeWafbzz8/2Xet71wE1yqtjq8JTyU4sHWuCPGPOdDgLo2c3ia6aWYpXkTR8yXmWUiwC+3cmc6HhS4Is+RbX+VTfWXCEcU5z6FA0kVOeHCDOPvVCsrn1fWBSGTmdp7fntXe6g32TkbxObEBrF3YgXfOYEmTfhi0CK+g3pR7SCmvzThS1SKyZq1VlUnu3ekPaFOAj6xMSA8W51MlvN/lIfGuAAI+H9rv68zb3CNtgkN9ZFoiQznLu++ZVDPIraDb0S8ERohikhy/RqKhvjPD7H85H7f0pLu9qUEqTPgRuzetqT/FEZ1Ue0oOekd2mdAp7pq5kbVo7hZckwEGWC0a7Rid8wWTjP6rVAUCvugRCzPqFYzu76sJPtbIYzYjxI/1y/zhm39uxA6JYTMmhzufo2l/7OJbd+RtDMT5k/SyyZeHKIiIiIQIYn/vYUCzAFQCIThkBFGwYw2BnLcEwgCZvjyhbYFhlrgIgC9gwAz1gUNmGHr0/JOphfE3NirpnwSTJvsWhIaNtVBA8Muu4mErGzioc+6pTzcRfWGQ0LVSWxiSolFRCERhOQSTkDmg+GTlhaEJ4zWyCnq+0MYIthXhKncbu2EHT4uYzdsYmvYMraAzfI7BQicYQwxggFjMU5tNp4zdiTFvTIo+ZW5MHLsnVN5tBpjbPydixAsXbV2C10qXLDA741TEuMaBdNsJEy1ETAVEKTi/TDRMGp8CGEe3HoTYcTY5g74nIqPX4nccSYIAv9eLAjaCxsowfhwiBISqzhQFkJqqXeMkgzgC39304yI35mHBequGgBc0fzZg9YfAIzXxaEn/VRedvXlcA7sjHGyX4Oxnj9I6B2Ql6KALThQQAPW4BCwhijcAzhGIsiBeXGSjfEjmtRgp+pKvahXW0rSm/QnA8lQMoXMW2aWdwUEBsoDVT8OYB6JkmJdaFLN91GQnqRvSMnvQdIXcAfoO2AIHtaH+aEAHx8AH+ejIl3JO+nbPW6POwcB7AOXHoA8QXJuvtrD/7hmmTVWOOm6m9baZrv5zlpil5XWW2ydyy66ZJUbCEIiEjJqHjx58TcIKUCgYNFixaFoaCVKkixFmi0W2OqRDT5Ll69AkRIVKlWp1qhJsxat2lnZOTj16NWPMWCI4TZ5YLOrjlnuuNNOOOOh2z65Y7Q9rtntri/uu2KGmd574paFPphujL3mmmOe1bhY2Pg4eATEVOQUlPx48+FLKki4EKEihTkvQgIdvXipYnTLliFTriw58hQqV8qgTINadWjF2hh16GTW5QKTPi5ugw1lM0wUi512OOiQAxCUukWAESB/IFcAJ//gfAqQHCA9AICCp24siPggZQ0RLAV2qeMoaWdIEdpawZF0qJ1A0IA389YDdwNQ+0cxUei9TY/AVQtSvQsTwwAaLaHtiQzgD+zMWQThCmGFvzLQWiVT3Ahx4Aet5I2CkziWU866tKKHNjYeBm3FlbM1Za3k88/Sf0vV2DLkcjoZnaMzlBl8fp6bbn1+zyv6Td0ySeugzNGw3VLtZmiOSpfnOGjdImhO/Fk+Qz7l6//MQ3mYz8s85IsVILFNMekd4fAg35NgO132Lq6wLGkByk9dJvZUXNlrSq8Jm8WLJjkb123HVc77k7aUDJIAbrv9u/8oH+FRYnxffLhA20Apks3h0XocvVnICrGpUV6v24irSxV3G/tuQwPsC6VsBMquMjYDEuXR72S/Yrdbr5NmkwXeZ7ON07veN++F2K/Lc825QECxqGnaiyYmv+LT+deUJJOanKSM62jMpqiursb30ywrSGmayOO0BmfrxSN8/qkD2MEXniJuY2ivQAya207GAkIereBJKYft6NiiOE4XbQPcFwJGAZlaZlqGlDA1//TH2cDROjQogZ/GFyrySodq+msKvmXKl70NXeB0MEQg7GgntcRhRfGCJXgFkv6y7n8gXdEWh637CJmgy9kXPyNsEuzL7HNAixqY6Gjdbk6MjsFkDJGk6cjabsDfg0hFlkbv7k9FQcDS0OoZ2QAk7bOdi0GKg91RpecKtN0RsXt3sRiOAcm3AqlQBVqQvyR2TB1QVcedXQygRXs1pSQsesup7bT9gvQQMDCJDWrnyfErsM1AfK9z2ETLUebytexXx1TB5wLddHDv6+lV7KuvRwZQOhQ0Va8Hymcpe4Mv8UJaGaQWxVIN9JBmjniNXkHY4mbvc7/wHGV3s0SlnoNb7fKbcIs645Gv+oo9dtGOh06kTeBCk/jPa1FOb+eu6pzu2Nx8h4TiDPst6j4RM2uwxdIL00nzSSlzuzsuYHcggM4xxIGz090CzgobulOaO4snMNbzWS45aGagRtQiAIj5i/QUMXXr5ptRBF72dp1wvdsrK2I3UGyomH9ro3T53NmqxxnaKtg0hmd35ajtgmTd7F0ANQ2Lw1e3qngrN8mUYakyPq1kkR4SnkhMp7RRdC/Vmset3HEAq6TOa5bXpMasK5qr8+IKZnAtoH5pA93ltnyJyjPkHqG/lvACx6A56ysuPmKWBK4nC0G5qeSJeQxhQlcXIlyutMf8PN82OcLDF0NanI27zsqsDTBvY6KJ2HH1CmXEFepnDV4qUxVagjk61q0AhCixdlH9ij1JoFi8Z5ytA97rQedJLivPaT4wilNHv9pHk7y0jk67Qhe2fMrlKr0z8nbY7w6oZuwKjNhFb4BOuUHb8hnrdvlBGDzizoYYrHaU2XfboMh4ZwEpl1sUzMAyig/XaDq9uF1LQiIuO0zlM7UdQO0a8Ruu+h1FKoIAVwFg70mwwlxGlmpmnan72xPm6NoydOJ6rCUlK7/9Ap3K9gmjEWEJDxxsEREU3gx1gDX/jF9QEc2T7oqowqHYvR1GmmUp84XMsd6qi4eC0+i/1+mFwE9CWIaHlblV8WZKNlux4/NBL355BoWLDZajXDxlS88ftCmyf6FkzYvoqqAyF5YlVhrJz5R/rcWxPDicmCpqIy45cEb9OxhhxJTIuh1MKGSu992N8RMc2t56d0SA3YvLf72sWYPTXFVmJxJDyOtDzscwIO7YhPlKIOw2cHo82CcxU9TwG7kyDp3MiWCvOomyBky624y37k23MMkVoO7N1ZNcBrZXV1PzaKTVistym4RMLxTa03xzGJoQC6SIIrTz4ngJZGbRxtrlvRntEInvu2ZpLET1JU3JDShqgE6+wv2ofvd9dCPgd0PS1BLGyqRIdv681pjMix1OByezC+w01fgjLMBJgo/Oys27KMoypjnPKTGKPBvVIevOCsXY6968lWm11zXO8J17n+XK51re93pvD/4bxkCT1W4aHiw8SYNpNgUT+Gxmnq1u9+Iix8XpteEcFX/6gfDGYPT/POdSDXaXfy1cuV2lZdtXJs/F2ZtVceErqUo5PZSQeXUqN7Buc2NyanHR1LiavOICACtqXoQbwjhad0t+2kbvtE7nmWsNd5tH9QJa8UicHz8tN5Fpg5GLELSsQ2oYWgk/q3F7t8/LTivg7oQwdsNW8KGAYy1fPr1iz9Wuiisg3Gsh8Jk5hOMW+PavSGQ+pI0/Ubr0mpWdprHqKMrpPGdiHxLfjI1xIjNtWH+CPufij5SGSB392dJqND6tAsWtVBtcaS8T/onOWKIOIa1rjYX+tp/HkoWKXaSlU+aWVJnVZmgxfBOulRJigPIqc8ksAvkfiuaPdjOchrXKncOwALVUg0+wSCb+/Ty/yxhYeQZmWr2JGLFGy3xPpg3XHU6TuBOzYAz2LodySJv7DZUb+h/g/JlgQ1TYF6Auo3xVo+ZO1sJeTmcS1baThqTx1goMmmlRDGISLd7UNQZ/rOfJM19UeoH5sKF8gtrrQhlODausHG3Bvv0Tj1SikmfvOLxTpXt9lL7Xu0woYn7mhfGXqfbHnqVGo2147bw2UGxWOwz/+qANgzkklCEwRHIOHf2Fp/r06AyiTx1VoGMgopvml8G4xxw38AsJXpPqMNQR0GHwekw6Zu3CDbokTluSvHkQ+SVG/PW4MoOxAxkqR+PY10QnBUWwwhaIKlZrbgbbJznAqHX4GhyFrKE4Esktbavkz0or6Y6hPuo+o+4jGGiLk69axDDylOGLndQr586pITgsDVQ7qPeVALBU2jEHI5YgqceAWGXhSzFq10RMAj2xD54XYQntmtRFFZp8gmGDUR6fwbMAVBZ+hc7N8UktlwpYGgTLKJ+T9blTW1/K4Q9dcH4zdXUtqRFOIImfHUGybEgSqxLuHLKDUqFOsFM6xrB9pUjBS4fVISKXdwZISTGkTnBRU88DrPAjiBtaLLXFnxEMlNlEf5yD2ctklia6J9oA4sjh0cCZ4p0QD1P6g5WDrwG3fBC4bWSX026SbXN1fHupTsudLMIj8YJdhsqmDbjC5O7LmRCi4jc0awgAP5HOZ1ObYVDWEzmEu/KixoPbKsmDxpO7WKDx6LbKAhuMcbo5IwCkYR8Z2x/S94c3o6n/R02zwceTjfocdNAj/3lSsBK8z6mCDnEBK764u9z7PIo/jp8Gp7eu4ujTe6B9iw2z2lXoVKdIAUuQNLKZXEPppH0TNj/OFsczMVQROM/zUOJzB/KX2X0YCAYuU553hW3fxfQjF5xxnnuL4Lqu7fvAJNoMWX/FwAmCL8cCQLDrcololMBdudatvi6sMazbs66B5vUCgeZ1iw6AV6IoZYxEZ1yjMkM+mwsFJWbYIiGkk8I0SBVrM9HiumV7bqzqxMKNg8SVQTNiDbaZI8kbI21TzCPaG9n4BKQY2wYD4erYFOc1I/HSdvQWrd6pvoHku9Mw7YTIUef3COEAThKbfwzNjf/s3MSJa8mN4I1Nn7vF68Jx4/Ly4cAIMxlz9/Cxs0HrV5Fzfu4E5CSJubKRzi9P6LSOhLB93wyTjJuvH83E0NK3eDABeJTAw/hXS2qni5oVjzjkWl3kOugK1U5366Z0uNhx0g2v8Cr4vHE4kdiJKi/RfcdENLO7U9Sk31punPmpeZODMbNIb2Z7u/DcuYZq72MN4Q2shMzGmXBcq05soMOX7KdN8wtBcpEWndjpHEKO0ToMEKZ6OrNJugrkLo0B0n4bLyvLMLO3ipq7YASTVO6SQyaH/tyWMGb65wvgyW5Qan2ZGwLRvLh+fWdQQHkFg142PXnqntkyHhRTtNte0p83XF5VociQJilbDDCc6en58oY7O5Q09gbOL9g3UFLKSdlIobFZX1UslvwNzyHDkmI2FmmFRPVq6rizr7Bno9Sx4Jj47Uwif8bAIZ1NuERe1vJr6agN8XuFC3OpchYaf+Z8gca5uVw18H4gd08MYpgNt05EaSCTBBDH9WmAqGsFXCshpiLvDnW+vJ4JuMjT8kMsbzFK0HPB2Z9KeVqlspDNSkUT84Lkjef1EObFItckkjtnikZxVAmsL4l7CdPQuyYG+sFuzVcULP3qHtAJxxtsbuc8mDjRevFuMp/YccQXOewjKJTS6/WwBnLklYKCEgnMcQ/nL2C9RqmX6ijBEa4+u9G8isK4vaK9a2ryNHdZd4Js7l7RSj9wjI4K99QX4Z2uUNuXGM6pKcI39TBc45lapUGaFG8KQ1zIKb4ljgQR4SSNzOLd5o+KPJp5fFs6+hoLf3HgeTpEuVmQPYRLXjoRb2uSqEzH76XpuNtY38zUq0jSVBss0tX4Uuoed/GFIIJiZd0wlixeybRdcBo6NKUql/oILi0N9+Qb/dlfMgc+zPuHZ73KAxxE2Qp3cwxNgN8lbh04wXE0oMwM/aoxHCcZHw6rT5sbaPUybrY9P31oy0NSL2oIUU3xd8dyPAduTZcwkwBirYHWOm25CYavoKQ6ESi3bJNJwpvDZZ+I/nBkNE+nlnjeu9lZ6qg5vAO7tRWskW/x/pMJNk4sV62ZpsIPQuby70PrgC7r1Yuq+7PSZJSTdSV28ZxyEse+24BgheIykmOC8Sj2EvQcDtKVjbDjVzh8/eB16WT+s4efWKhQLv0hIaeaeR9fvYLUAiQRkY2jB3IJfmN4m12HG0x+ayBEJogosmQUCzCCkPmgmYXIRGKp09BcuRtOGgay5M2gpcg0OO2rdYzBpOvnd4q+pd8GpjNBsMOh3vlOmV1vliiSasdvifU5xk5hihyd+B7X+Qed8fRn0XsAXPbU2g2qsARvEbFwoS7QMZ5V+OQuTWg4z+UKcS0zR+BEelgYQTuLwhCiMEHAgDyDuHRVr5tcD9G+yDpGQptliM5DVxAIYlyAiKue8k/fEr79OjgIx6LCKs/ESYtjWAMDfaiG8CQZXeL4CTcR472yNO7pn0GI6g6+bfUoKdOruDViFnph4LTBb1i0OKkOTZisznJNW8GstbB93kHrxMC//SUR+CbSeqXQK8G3B0cMz1nnDPxGnNvlvsiFz758gNxZXRvgEKLbAMGX3gQFcDmlsMkULQWeVQDSM4UO5LoqKvimUCXLAJXa+ET4tA+NBHLHb5AZcp5rxDhXFOMhJmNYjmIyw+73EPbM3wMf+ngjyuUYsCSWIP94iyT+ewQOUwL+EZJJTwKc9qKBJIXl1vEoh9NMAdcaOO6/Fa14bI95UY8WIN6wxuZqhymxovk5NIqCG1iOOIrBDv3WcNCM8aMPxXwQDq5qH7MorIWH9doMtP//AgdfuDp6NGN3DNE5oenpb2XgMLFth6KGvXC3bRejjr1mEJY9Erlv9DeaOSVXN+LcEk9LMfyUeLwzthKSbEqGXSbFW8xbm8JWGrz14aK0hFjLa7rU1HyliBw5zxlGSyAY1i5EHIiJNYFRA+wMjZWk7IFenOYZhvxI3ViiEIpr0YmgrsAVgWuM+bmoGlfKT8ACPMAVSSCxJrshFLB4yTgAsu2JO+JIM9nq8mAjBD7Wwsaeg5EYil+rb9cezhC6q1DXQvBf6B8Dh4xT3wxI9q4A3wt0lNU4fDPoRB2cCvXH4PQhqpSR1eH8xieP3tQxFiuGDJCRoWLmyMiLy7tVzas0xyiVJKVKM5X6mTBnrsyKi3YNvtF0rX2XCNTRFS/pZ6Npqack3JZG/PRGw0OQfODZ0hnDt7on/oFNiNwyW2YuiTx/ZIIzuBBCB4DTBI3UpBgy1EThRP4WRmw+CEurhkY0p2dOxyRS8gE01DA7rGwYTYlHoJ+DtebPvfI7pwxTakD0KoDoheJMNlEc1LWS8j7ECdQyW+mlcWQcpKBnFNbSbyw1sxxS7xscZ+RRnq5O1KmQ1eF9vOCV9ED+j+B/0eZmhiugkBL/RxhZ+RYKZdOCx3Q8TgDjfXAzYlmvOp2N5rKoTtVb4czhqIjmv7XQIdy5kO9arC4oo7CHgm/LrpIfkgAZqQpiHk7q8+CxhrhfVlPc+QI6v1fsg/WmnMSPNgwNZuGmLgv62goLd/9u7ITPrOjZnkE4SXVmPNiYiSwFxkyX4o/jQe8skoRT9YQcegtFEpUo7pcCjXgj7F2uVcFoQdpM9eNEyYUh/CRtBJROfBc+dQQKdElaMoyM3Yiy3QhgBwFMehnzrJMd6L8yfU1Fjs1bClqZjdYL2kDEBeuREPpams4bzEH/lelrbYGMmBIbtimuxoFKmT7TtiKunYWEevNeH1B26V4YfGKQ0zytTJ+TNygb3V1anUmlcpKLjqZYdQHjAIwBeL8G9kBynKQe7qFF0p4YxUC3pTTIgtMZssXGxd0jcJWG5gFcYhVH6TqEqTv8gQ6TBaviXXxRf0HS4QKvQ5piNABcGBkK7R/Z5HBPMNDDIaDA//GpgPb5tK+p1v4B/vzOdgL+zme++f+xS7NtTApMwgACbmAmIS8G8g1IiPnnBneEIaN4r4PfgQEq60BG66wOu20JpsuS5MYwdFqC+VzLBoe8lWCT0chy5GRJaNlluirL6XbHZIzadew2O1VM0u6CjFHZAnRXKZj4pqJVU/BAu9Myxm/CdRiBMld2I8croDZsImkXZVWk3czypsQq5pFpir4FwynQ5yrTTzFXsphFel6XFa9VFqAfkGFAC4aAkefYruDClGg2E/hsq+EQMMUCh0rTwDc3dBLCd07CiB2QcJQJEsGbjbJMyynbVP/2iumBNwyGW4o4cfoZ9bFzY/SL1c+uWyyXPlZxKhQwoNXS0dKJUc3MakC3Tn1oZn0W3+rSi6QVi0Kh3kMg1eZPNVWdUvXKpboXB2pO5VwubsOlR1lXCXwHp2hoRCMjptQsiFAqqbKLg5mR2zjbAIaNawUak8K5mTErlBXL5rFxtywuds7iB4xl5NIjAgag/6IFIn7uEUgBBhfsuqu67Ga0xzwhQpmE+S6c2TU33BQhUpRot9x2x10xt1N0PxZa99xn9dB8e+2j8yu9eAkSJXnkMZsnkqVIleZn6fKkKt0B7V1pnXwFXAr9pIh7NT+ewYqVKGXwFGOIoYEbUKZchUpVhqk23EijjLDeaPvV+E2tOrTp6jUYY5zxxt7E0cF+cUJrEM45b7U1FJRUt4oEt1n0KxOsTGQyU075B/6F/0Ak00VT+ZHYibARm0ygDVj4/MnlBE+bDhmyCAgddIA0+Lbb4YyzLjvksCOOuhQCk5zGiTmTLSH2uz/gGFKAQRbqtAlXEJ5ppphphlkmavdNdoiykMUsRRZ5FFFGFXU84mm2N56ZI9cLrz0vldcZDDx7bPeLsbu2uhS3tFs4A712isqJVKZena9ISyXq1bfuFWO8ZjP4X3Zudu1fUrLzlOgmbisf+DlaTby9TK46Kql3Iu8pymjNL/SlkNdpHGCaSH2MlibJnmLs3aZfE32iNhHhnMScHAA=) format(&apos;woff2&apos;)}</style></svg>';

 
    function P10() public pure returns (string memory) {
        return _P10;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RenderConstant} from "src/library/RenderConstant.sol";
import {RenderConstant2} from "src/library/RenderConstant2.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IRebornDefinition} from "src/interfaces/IRebornPortal.sol";
import {strings} from "src/library/strings.sol";

library Renderer {
    using strings for *;

    function renderByTokenId(
        mapping(uint256 => IRebornDefinition.LifeDetail) storage details,
        uint256 tokenId
    ) public view returns (string memory) {
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    "Degen Tombstone",
                    '","description":"',
                    "",
                    '","image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            renderSvg(
                                details[tokenId].seed,
                                details[tokenId].score,
                                details[tokenId].round,
                                details[tokenId].age,
                                details[tokenId].creatorName,
                                details[tokenId].nativeCost,
                                details[tokenId].rebornCost
                            )
                        )
                    ),
                    '","attributes": ',
                    renderTrait(
                        details[tokenId].seed,
                        details[tokenId].score,
                        details[tokenId].round,
                        details[tokenId].age,
                        details[tokenId].creator,
                        details[tokenId].creatorName,
                        details[tokenId].reward,
                        details[tokenId].nativeCost
                    ),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
    }

    function renderSvg(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        string memory creatorName,
        uint256 nativeCost,
        uint256 rebornCost
    ) public pure returns (string memory) {
        string memory Part1 = _renderSvgPart1(seed, lifeScore, round, age);
        string memory Part2 = _renderSvgPart2(
            creatorName,
            nativeCost,
            rebornCost
        );

        return string(abi.encodePacked(Part1, Part2));
    }

    function renderTrait(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderTraitPart1(seed, lifeScore, round, age),
                    _renderTraitPart2(creator, creatorName, reward, cost)
                )
            );
    }

    function _renderTraitPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Seed", "value": "',
                    Strings.toHexString(uint256(seed), 32),
                    '"},{"trait_type": "Life Score", "value": ',
                    Strings.toString(lifeScore),
                    '},{"trait_type": "Round", "value": ',
                    Strings.toString(round),
                    '},{"trait_type": "Age", "value": ',
                    Strings.toString(age)
                )
            );
    }

    function _renderTraitPart2(
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '},{"trait_type": "Creator", "value": "',
                    Strings.toHexString(uint160(creator), 20),
                    '"},{"trait_type": "CreatorName", "value": "',
                    creatorName,
                    '"},{"trait_type": "Reward", "value": ',
                    Strings.toString(reward),
                    '},{"trait_type": "Cost", "value": ',
                    Strings.toString(cost),
                    "}]"
                )
            );
    }

    function _renderSvgPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P1(),
                    _transformBytes32Seed(seed),
                    RenderConstant.P2(),
                    _transformUint256(lifeScore),
                    RenderConstant.P3(),
                    Strings.toString(round),
                    RenderConstant.P4(),
                    Strings.toString(age)
                )
            );
    }

    function _renderSvgPart2(
        string memory creator,
        uint256 nativeCost,
        uint256 degenCost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P5(),
                    _compressUtf8(creator),
                    RenderConstant.P6(),
                    // Complete accuracy
                    _transformWeiToDecimal2(nativeCost * 10 ** 12),
                    RenderConstant.P7(),
                    _transformUint256(degenCost / 1 ether),
                    RenderConstant.P8(),
                    RenderConstant.P9(),
                    RenderConstant2.P10()
                )
            );
    }

    function _transformWeiToDecimal2(
        uint256 value
    ) public pure returns (string memory str) {
        if (value > 100 ether) {
            return Strings.toString(value / 1 ether);
        } else {
            uint256 secondFractional = value % (1 ether / 10);
            uint256 firstFractional = (value - secondFractional) % (1 ether);
            uint256 integer;
            if (firstFractional != 0 || secondFractional != 0) {
                integer = value - firstFractional - secondFractional;
            } else {
                integer = value;
            }

            return
                string.concat(
                    Strings.toString(integer / 1 ether),
                    ".",
                    Strings.toString(firstFractional / 10 ** 17),
                    Strings.toString(secondFractional / 10 ** 16)
                );
        }
    }

    function _transformUint256(
        uint256 value
    ) public pure returns (string memory str) {
        if (value < 10 ** 7) {
            return _recursiveAddComma(value);
        } else if (value < 10 ** 11) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 6), "M")
                );
        } else if (value < 10 ** 15) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 9), "B")
                );
        } else {
            revert ValueOutOfRange();
        }
    }

    function _recursiveAddComma(
        uint256 value
    ) internal pure returns (string memory str) {
        if (value / 1000 == 0) {
            str = string(abi.encodePacked(Strings.toString(value), str));
        } else {
            str = string(
                abi.encodePacked(
                    _recursiveAddComma(value / 1000),
                    ",",
                    _numberStringToLengthThree(Strings.toString(value % 1000)),
                    str
                )
            );
        }
    }

    function _transformBytes32Seed(
        bytes32 b
    ) public pure returns (string memory) {
        string memory str = Strings.toHexString(uint256(b), 32);
        return
            string(
                abi.encodePacked(
                    _substring(str, 0, 14),
                    unicode"…",
                    _substring(str, 45, 66)
                )
            );
    }

    function _numberStringToLengthThree(
        string memory number
    ) internal pure returns (string memory) {
        if (bytes(number).length == 1) {
            return string(abi.encodePacked("00", number));
        } else if (bytes(number).length == 2) {
            return string(abi.encodePacked("0", number));
        } else {
            return number;
        }
    }

    error ValueOutOfRange();

    function _shortenAddr(address addr) private pure returns (string memory) {
        uint256 value = uint160(addr);
        bytes memory allBytes = bytes(Strings.toHexString(value, 20));

        string memory newString = string(allBytes);

        return
            string(
                abi.encodePacked(
                    _substring(newString, 0, 6),
                    unicode"…",
                    _substring(newString, 38, 42)
                )
            );
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _compressUtf8(
        string memory str
    ) public pure returns (string memory res) {
        strings.slice memory sl = str.toSlice();
        strings.slice memory resl = res.toSlice();

        uint256 length = sl.len();
        if (length > 12) {
            for (uint256 i = 0; i < 5; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            for (uint256 i = 5; i < length - 7; i++) {
                sl.nextRune().toString();
            }

            resl = resl.concat(unicode"…".toSlice()).toSlice();
            for (uint256 i = length - 7; i < length; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            return resl.toString();
        }
        return str;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0) return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(
        slice memory self,
        slice memory other
    ) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0) return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(
        slice memory self,
        slice memory other
    ) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(
        slice memory self,
        slice memory rune
    ) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(
        slice memory self
    ) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint selflen,
        uint selfptr,
        uint needlelen,
        uint needleptr
    ) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(
        slice memory self,
        slice memory needle
    ) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(
        slice memory self,
        slice memory other
    ) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(
        slice memory self,
        slice[] memory parts
    ) internal pure returns (string memory) {
        if (parts.length == 0) return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICustomError {
    /**********************************
     * Generic errors
     **********************************/
    error ZeroOwnerSet();

    /**********************************
     * Initializable
     **********************************/
    error ContractAlreadyInitialized();
    error ContractIsNotInitializing();
    error ContractIsInitializing();

    /**********************************
     * ReentrancyGuardUpgradeable
     **********************************/
    error ReentrantCall();

    /**********************************
     * PausableUpgradeable
     **********************************/
    error PauseablePaused();
    error PausableNotPaused();

    /**********************************
     * UUPSUpgradeable
     **********************************/
    error MustBeCalledThroughDelegatecall();
    error MustBeCalledThroughActiveProxy();

    /**********************************
     * ERC1967UpgradeUpgradeable
     **********************************/
    error NewImplementationIsNotContract();
    error UnsupportedProxiableUUID();
    error NewImplementationIsNotUUPS();
    error NewAdminIsZeroAddress();
    error NewBeaconIsNotContract();
    error BeaconImplementationIsNotContract();
    error DelegateCallToNonContract();

    /**********************************
     * ERC721
     **********************************/
    error InvalidTokenID();
    error ApproveToCurrentOwner();
    error CallerNotTokenOwnerOrApproved();
    error TransferToNonERC721ReceiverImplementer();
    error MintToZeroAddress();
    error TokenAlreadyMinted();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error ApproveToCaller();

    /**********************************
     * ERC20Upgradeable
     **********************************/
    error DecreasedAllowanceBelowZero();
    error TransferFromZeroAddress();
    error TransferAmountExceedsBalance();
    error BurnFromZeroAddress();
    error BurnAmountExceedsBalance();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();
    error InsufficientAllowance();

    /**********************************
     * SafeERC20Upgradeable
     **********************************/
    error ApproveFromNonZeroToNonZeroAllowance();
    error PermitDidNotSucceed();
    error ERC20OperationDidNotSucceed();
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
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!AddressUpgradeable.isContract(newImplementation)) {
            revert NewImplementationIsNotContract();
        }
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                // require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
                if (slot != _IMPLEMENTATION_SLOT) {
                    revert UnsupportedProxiableUUID();
                }
            } catch {
                revert NewImplementationIsNotUUPS();
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        if (newAdmin == address(0)) {
            revert NewAdminIsZeroAddress();
        }
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        if (!AddressUpgradeable.isContract(newBeacon)) {
            revert NewBeaconIsNotContract();
        }

        if (
            !AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            )
        ) {
            revert BeaconImplementationIsNotContract();
        }
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(
        address target,
        bytes memory data
    ) private returns (bytes memory) {
        if (!AddressUpgradeable.isContract(target)) {
            revert DelegateCallToNonContract();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
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
import "../../ICustomError.sol";

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
abstract contract Initializable is ICustomError {
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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        if (_initializing || _initialized >= version) {
            revert ContractAlreadyInitialized();
        }
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
        if (!_initializing) {
            revert ContractIsNotInitializing();
        }
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
        if (_initializing) {
            revert ContractIsInitializing();
        }
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
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
        if (address(this) == __self) {
            revert MustBeCalledThroughDelegatecall();
        }
        if (_getImplementation() != __self) {
            revert MustBeCalledThroughActiveProxy();
        }
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) {
            revert MustBeCalledThroughDelegatecall();
        }
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
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
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable virtual onlyProxy {
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
        // require(!paused(), "Pausable: paused");
        if (paused()) {
            revert PauseablePaused();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert PausableNotPaused();
        }
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
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }

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
contract ERC20Upgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
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
    function __ERC20_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < subtractedValue) {
            revert DecreasedAllowanceBelowZero();
        }
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
        if (from == address(0)) {
            revert TransferFromZeroAddress();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert TransferAmountExceedsBalance();
        }
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
        if (account == address(0)) {
            revert MintToZeroAddress();
        }

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
        if (account == address(0)) {
            revert BurnFromZeroAddress();
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            revert BurnAmountExceedsBalance();
        }
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
        if (owner == address(0)) {
            revert ApproveFromZeroAddress();
        }

        if (spender == address(0)) {
            revert ApproveToZeroAddress();
        }

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
            if (currentAllowance < amount) {
                revert InsufficientAllowance();
            }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(
        string memory
    ) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(
        address owner
    ) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(
        address owner
    ) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is
    Initializable,
    ContextUpgradeable,
    ERC20Upgradeable
{
    function __ERC20Burnable_init() internal onlyInitializing {}

    function __ERC20Burnable_init_unchained() internal onlyInitializing {}

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 *
 * @custom:storage-size 51
 */
abstract contract ERC20CappedUpgradeable is Initializable, ERC20Upgradeable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    function __ERC20Capped_init(uint256 cap_) internal onlyInitializing {
        __ERC20Capped_init_unchained(cap_);
    }

    function __ERC20Capped_init_unchained(
        uint256 cap_
    ) internal onlyInitializing {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            ERC20Upgradeable.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        // require(
        //     owner != address(0),
        //     "ERC721: address zero is not a valid owner"
        // );
        if (owner == address(0)) {
            revert ZeroOwnerSet();
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert InvalidTokenID();
        }
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
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {}

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        if (to == owner) {
            revert ApproveToCurrentOwner();
        }

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert CallerNotTokenOwnerOrApproved();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // //solhint-disable-next-line max-line-length
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert CallerNotTokenOwnerOrApproved();
        // }
        // _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert CallerNotTokenOwnerOrApproved();
        // }
        // _safeTransfer(from, to, tokenId, data);
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
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
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
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
        if (to == address(0)) {
            revert MintToZeroAddress();
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        if (_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ERC721Upgradeable.ownerOf(tokenId) != from) {
            revert TransferFromIncorrectOwner();
        }

        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        if (ERC721Upgradeable.ownerOf(tokenId) != from) {
            revert TransferFromIncorrectOwner();
        }

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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) {
            revert ApproveToCaller();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert InvalidTokenID();
        }
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
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
library AddressUpgradeable {
    error InsufficientBalance();
    error UnableToSendValue();
    error CallToNoContract();

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
        if (address(this).balance < amount) {
            revert InsufficientBalance();
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert UnableToSendValue();
        }
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        if (address(this).balance < value) {
            revert InsufficientBalance();
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
                if (!isContract(target)) {
                    revert CallToNoContract();
                }
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
    error InvalidSignature();
    error InvalidSignatureLength();
    error InvalidSignatureSValue();

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert InvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert InvalidSignatureLength();
        } else if (error == RecoverError.InvalidSignatureS) {
            revert InvalidSignatureSValue();
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
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
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
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {IRebornDefinition} from "src/interfaces/IRebornPortal.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IRewardVault} from "src/RewardVault.sol";
import {CommonError} from "src/library/CommonError.sol";
import {ECDSAUpgradeable} from "src/oz/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IAirdropVault} from "src/AirdropVault.sol";
import {IRegistry} from "src/Registry.sol";

library PortalLib {
    uint256 public constant PERSHARE_BASE = 10e18;
    // percentage base of refer reward fees
    uint256 public constant PERCENTAGE_BASE = 10000;

    bytes32 public constant _SOUPPARAMS_TYPEHASH =
        keccak256(
            "AuthenticateSoupArg(address user,uint256 soupPrice,uint256 incarnateCounter,uint256 tokenId,uint256 deadline)"
        );

    bytes32 public constant _EXHUME_TYPEHASH =
        keccak256(
            "ExhumeArg(address exhumer,address exhumee,uint256 tokenId,uint256 nonce,uint256 nativeCost,uint256 degenCost,uint256 shovelTokenId,uint256 deadline)"
        );

    bytes32 public constant _CLAIM_TYPEHASH =
        keccak256(
            "ClaimRewardArg(address user,uint256 amount,uint256 type,uint256 nonce,uint256 deadline)"
        );

    bytes32 public constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    uint256 public constant ONE_HUNDRED = 100;

    struct CharacterParams {
        uint256 maxAP;
        uint256 restoreTimePerAP;
        uint256 level;
    }

    // TODO: use more compact storage
    struct CharacterProperty {
        uint8 currentAP;
        uint8 maxAP;
        uint24 restoreTimePerAP; // Time Needed to Restore One Action Point
        uint32 lastTimeAPUpdate;
        uint8 level;
    }

    struct CurrentAPReturn {
        uint256 currentAP;
        uint256 lastAPUpdateTime;
    }

    enum RewardType {
        NativeToken,
        RebornToken
    }

    struct ReferrerRewardFees {
        uint16 incarnateRef1Fee;
        uint16 incarnateRef2Fee;
        uint16 vaultRef1Fee;
        uint16 vaultRef2Fee;
        uint192 _slotPlaceholder;
    }

    struct Pool {
        uint256 totalAmount;
        uint256 accRebornPerShare;
        uint256 accNativePerShare;
        uint128 droppedRebornTotal;
        uint128 droppedNativeTotal;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
        uint32 lastDropNativeTime;
        uint32 lastDropRebornTime;
        uint128 validTVL;
        uint64 placeholder;
    }

    //
    // We do some fancy math here. Basically, any point in time, the amount
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (Amount * pool.accPerShare) - user.rewardDebt
    //
    // Whenever a user infuse or switchPool. Here's what happens:
    //   1. The pool's `accPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
    struct Portfolio {
        uint256 accumulativeAmount;
        uint128 rebornRewardDebt;
        uint128 nativeRewardDebt;
        /// @dev reward for holding the NFT when the NFT is selected
        uint128 pendingOwnerRebornReward;
        uint128 pendingOwnerNativeReward;
        uint256 coindayCumulant;
        uint32 coindayUpdateLastTime;
        uint112 totalForwardTribute;
        uint112 totalReverseTribute;
    }

    event SignerUpdate(address signer, bool valid);
    event ReferReward(
        address indexed user,
        address indexed ref1,
        uint256 amount1,
        address indexed ref2,
        uint256 amount2,
        RewardType rewardType
    );

    function _toLastHour(uint256 timestamp) public pure returns (uint256) {
        return timestamp - (timestamp % (1 hours));
    }

    /**
     * @dev returns referrer and referrer reward
     * @return ref1  level1 of referrer. direct referrer
     * @return ref1Reward  level 1 referrer reward
     * @return ref2  level2 of referrer. referrer's referrer
     * @return ref2Reward  level 2 referrer reward
     */
    function _calculateReferReward(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        address account,
        uint256 amount,
        RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        ref1 = referrals[account];
        ref2 = referrals[ref1];

        if (rewardType == RewardType.NativeToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.incarnateRef2Fee) / PERCENTAGE_BASE;
        }

        if (rewardType == RewardType.RebornToken) {
            ref1Reward = ref1 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef1Fee) / PERCENTAGE_BASE;
            ref2Reward = ref2 == address(0)
                ? 0
                : (amount * rewardFees.vaultRef2Fee) / PERCENTAGE_BASE;
        }
    }

    /**
     * @dev send NativeToken to referrers
     */
    function _sendNativeRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefinition.RewardToClaimType => IRebornDefinition.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public returns (uint256 total) {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.NativeToken
            );

        unchecked {
            _rewardToClaim[ref1][
                IRebornDefinition.RewardToClaimType.ReferNative
            ].totalReward += ref1Reward;
            _rewardToClaim[ref2][
                IRebornDefinition.RewardToClaimType.ReferNative
            ].totalReward += ref2Reward;
        }

        unchecked {
            total = ref1Reward + ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.NativeToken
        );
    }

    /**
     * @dev vault $REBORN token to referrers
     */
    function _rewardDegenRewardToRefs(
        mapping(address => address) storage referrals,
        ReferrerRewardFees storage rewardFees,
        mapping(address => mapping(IRebornDefinition.RewardToClaimType => IRebornDefinition.RewardStore))
            storage _rewardToClaim,
        address account,
        uint256 amount
    ) public {
        (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        ) = _calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                RewardType.RebornToken
            );

        unchecked {
            _rewardToClaim[ref1][IRebornDefinition.RewardToClaimType.ReferDegen]
                .totalReward += ref1Reward;
            _rewardToClaim[ref2][IRebornDefinition.RewardToClaimType.ReferDegen]
                .totalReward += ref2Reward;
        }

        emit ReferReward(
            account,
            ref1,
            ref1Reward,
            ref2,
            ref2Reward,
            RewardType.RebornToken
        );
    }

    function _calculateCurrentAP(
        CharacterProperty memory charProperty
    ) public view returns (CurrentAPReturn memory) {
        // if restoreTimePerAP is not set, no process
        if (charProperty.restoreTimePerAP == 0) {
            return
                CurrentAPReturn(
                    charProperty.currentAP,
                    charProperty.lastTimeAPUpdate
                );
        }

        uint256 calculatedRestoreAp = (block.timestamp -
            charProperty.lastTimeAPUpdate) / charProperty.restoreTimePerAP;

        uint256 calculatedCurrentAP = calculatedRestoreAp +
            charProperty.currentAP;

        uint256 lastAPUpdateTime = charProperty.lastTimeAPUpdate +
            calculatedRestoreAp *
            charProperty.restoreTimePerAP;

        uint256 currentAP;

        // min(calculatedCurrentAP, maxAp)
        if (calculatedCurrentAP <= charProperty.maxAP) {
            currentAP = calculatedCurrentAP;
        } else {
            currentAP = charProperty.maxAP;
        }

        return CurrentAPReturn(currentAP, lastAPUpdateTime);
    }

    function _consumeAP(
        uint256 tokenId,
        mapping(uint256 => CharacterProperty) storage _characterProperties
    ) public {
        CharacterProperty storage charProperty = _characterProperties[tokenId];

        CurrentAPReturn memory car = _calculateCurrentAP(charProperty);

        // if current ap is max, recover starts from now
        if (car.currentAP == charProperty.maxAP) {
            charProperty.lastTimeAPUpdate = uint32(block.timestamp);
        } else {
            charProperty.lastTimeAPUpdate = uint32(car.lastAPUpdateTime);
        }

        // Reduce AP
        charProperty.currentAP = uint8(car.currentAP - 1);
    }

    function _useSoupParam(
        IRebornDefinition.SoupParams calldata soupParams,
        uint256 nonce,
        mapping(uint256 => PortalLib.CharacterProperty)
            storage _characterProperties,
        address registry
    ) public {
        _checkSoupSig(soupParams, nonce, registry);

        if (soupParams.charTokenId != 0) {
            // use degen2009 nft character
            _consumeAP(soupParams.charTokenId, _characterProperties);
        }
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _altarDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("Altar"),
                keccak256("1")
            );
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _degenPortalDomainSeparatorV4() public view returns (bytes32) {
        return
            _buildDomainSeparator(
                PortalLib._TYPE_HASH,
                keccak256("DegenPortal"),
                keccak256("1")
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _checkExhumeSig(
        IRebornDefinition.ExhumeParams calldata exhumeParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= exhumeParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._EXHUME_TYPEHASH,
                msg.sender,
                exhumeParams.exhumee,
                exhumeParams.tokenId,
                nonce,
                exhumeParams.nativeCost,
                exhumeParams.degenCost,
                exhumeParams.shovelTokenId,
                exhumeParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _degenPortalDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            exhumeParams.v,
            exhumeParams.r,
            exhumeParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkClaimRewardSig(
        IRebornDefinition.ClaimRewardParams calldata claimRewardParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= claimRewardParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._CLAIM_TYPEHASH,
                claimRewardParams.user,
                claimRewardParams.amount,
                claimRewardParams.t,
                nonce,
                claimRewardParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _degenPortalDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            claimRewardParams.v,
            claimRewardParams.r,
            claimRewardParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkSoupSig(
        IRebornDefinition.SoupParams calldata soupParams,
        uint256 nonce,
        address registry
    ) public view {
        if (block.timestamp >= soupParams.deadline) {
            revert CommonError.SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PortalLib._SOUPPARAMS_TYPEHASH,
                msg.sender,
                soupParams.soupPrice,
                nonce,
                soupParams.charTokenId,
                soupParams.deadline
            )
        );

        bytes32 hash = ECDSAUpgradeable.toTypedDataHash(
            _altarDomainSeparatorV4(),
            structHash
        );

        address signer = ECDSAUpgradeable.recover(
            hash,
            soupParams.v,
            soupParams.r,
            soupParams.s
        );

        if (!IRegistry(registry).checkIsSigner(signer)) {
            revert CommonError.NotSigner();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20CappedUpgradeable, ERC20Upgradeable} from "src/oz/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {SafeOwnableUpgradeable} from "src/utils/SafeOwnableUpgradeable.sol";
import {UUPSUpgradeable} from "src/oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20PermitUpgradeable} from "src/oz/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "src/oz/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {IRebornToken} from "src/interfaces/IRebornToken.sol";
import {RBTStorage} from "src/RBTStorage.sol";

contract RBT is
    ERC20PermitUpgradeable,
    ERC20CappedUpgradeable,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    IRebornToken,
    RBTStorage,
    ERC20BurnableUpgradeable
{
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        address owner_
    ) public initializer {
        __ERC20_init_unchained(name_, symbol_);
        __ERC20Capped_init(cap_);
        __ERC20Permit_init(name_);
        __Ownable_init(owner_);
    }

    // directly revert upgrade
    function _authorizeUpgrade(address) internal override onlyOwner {
        revert CannotUpgradeAnyMore();
    }

    /**
     * @dev allow minter to mint it
     */
    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    /**
     * @dev update minters
     */
    function updateMinter(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            minters[toAdd[i]] = true;
            emit MinterUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete minters[toRemove[i]];
            emit MinterUpdate(toRemove[i], false);
        }
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20CappedUpgradeable, ERC20Upgradeable) {
        require(
            ERC20Upgradeable.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        ERC20Upgradeable._mint(account, amount);
    }

    modifier onlyMinter() {
        if (!minters[msg.sender]) {
            revert NotMinter();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

contract RBTStorage {
    mapping(address => bool) public minters;

    /// @dev gap for potential variable
    uint256[49] private _gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC721Upgradeable} from "src/oz/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "src/oz/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "src/oz/contracts-upgradeable/security/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "src/oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BitMapsUpgradeable} from "src/oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {AddressUpgradeable} from "src/oz/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {SafeOwnableUpgradeable} from "src/utils/SafeOwnableUpgradeable.sol";
import {IRebornPortal} from "src/interfaces/IRebornPortal.sol";
import {IBurnPool} from "src/interfaces/IBurnPool.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {Renderer} from "src/library/Renderer.sol";
import {CommonError} from "src/library/CommonError.sol";
import {PortalLib} from "src/PortalLib.sol";
import {IPiggyBank} from "src/interfaces/IPiggyBank.sol";
import {IPiggyBank} from "src/interfaces/IPiggyBank.sol";
import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IRegistry} from "src/interfaces/IRegistry.sol";
import {IDegenShovel} from "src/interfaces/IDegenShovel.sol";
import {BlockNumberReader} from "src/library/BlockNumberReader.sol";

// for storage compatible
abstract contract StorageCompat is RebornPortalStorage {

}

contract RebornPortal is
    IRebornPortal,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    RebornPortalStorage,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    StorageCompat,
    AutomationCompatible
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using AddressUpgradeable for address payable;

    /**
     * @dev initialize function
     * @param owner_ owner address
     * @param name_ ERC712 name
     * @param symbol_ ERC721 symbol
     */
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        IRegistry registry_
    ) public initializer {
        if (owner_ == address(0) || address(registry_) == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        _registry = registry_;
        __Ownable_init(owner_);
        __ERC721_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata soupParams
    )
        external
        payable
        override
        whenNotStopped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referParams);
        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function incarnate(
        InnateParams calldata innate,
        ReferParams calldata referParams,
        SoupParams calldata soupParams,
        PermitParams calldata permitParams
    )
        external
        payable
        override
        whenNotStopped
        nonReentrant
        checkIncarnationCount
    {
        _refer(referParams);
        _permit(permitParams);
        _incarnate(innate, soupParams);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function engrave(
        EngraveParams calldata engraveParams
    ) external override onlySigner {
        if (_seeds.get(uint256(engraveParams.seed))) {
            revert SameSeed();
        }
        _seeds.set(uint256(engraveParams.seed));

        address creator = details[engraveParams.tokenId].creator;

        details[engraveParams.tokenId] = LifeDetail(
            engraveParams.seed,
            creator,
            uint96(engraveParams.reward),
            uint96(engraveParams.rebornCost),
            uint16(engraveParams.age),
            uint16(++rounds[creator]),
            uint64(engraveParams.score),
            uint48(engraveParams.nativeCost / 10 ** 12),
            engraveParams.creatorName
        );

        uint256 startTokenId;
        // mint shovel
        if (engraveParams.shovelAmount > 0) {
            startTokenId = IDegenShovel(_registry.getShovel()).mint(
                creator,
                engraveParams.shovelAmount
            );
        }

        // record reward for incarnation owner
        _rewardToClaim[creator][RewardToClaimType.EngraveDegen]
            .totalReward += engraveParams.reward;

        // record reward for referrer
        _rewardDegenRewardToRefs(creator, engraveParams.reward);

        // recover AP
        _recoverAP(engraveParams.charTokenId, engraveParams.recoveredAP);

        emit Engrave(
            engraveParams.seed,
            creator,
            engraveParams.tokenId,
            engraveParams.score,
            engraveParams.reward,
            engraveParams.shovelAmount,
            startTokenId,
            engraveParams.charTokenId,
            engraveParams.recoveredAP
        );
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function baptise(
        address user,
        uint256 amount,
        uint256 baptiseType
    ) external override onlySigner {
        vault.reward(user, amount);

        emit Baptise(user, amount, baptiseType);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) external override whenNotStopped {
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection,
        PermitParams calldata permitParams
    ) external override whenNotStopped {
        _permit(permitParams);
        _infuse(tokenId, amount, tributeDirection);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function switchPool(
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 amount,
        TributeDirection fromDirection,
        TributeDirection toDirection
    ) external override whenNotStopped {
        uint256 reStakeAmount = (amount * 95) / 100;

        emit SwitchPool(
            msg.sender,
            fromTokenId,
            toTokenId,
            amount,
            reStakeAmount,
            fromDirection,
            toDirection
        );
    }

    function exhume(
        ExhumeParams calldata exhumeParams
    ) external payable whenNotPaused {
        _exhume(exhumeParams);
    }

    function exhume(
        ExhumeParams calldata exhumeParams,
        PermitParams calldata permitParams
    ) external payable whenNotPaused {
        _permit(permitParams);
        _exhume(exhumeParams);
    }

    function claimReward(
        RewardToClaimType t
    ) external override whenNotPaused nonReentrant {
        uint256 remainingAmount = _rewardToClaim[msg.sender][t].totalReward -
            _rewardToClaim[msg.sender][t].rewardDebt;

        if (remainingAmount == 0) {
            revert NoRemainingReward();
        }

        _rewardToClaim[msg.sender][t].rewardDebt = _rewardToClaim[msg.sender][t]
            .totalReward;

        // if t is even, native reward
        if (uint8(t) % 2 == 0) {
            payable(msg.sender).sendValue(remainingAmount);
        } else {
            // t is odd, degen reward
            vault.reward(msg.sender, remainingAmount);
        }

        emit ClaimReward(msg.sender, t, remainingAmount);
    }

    function claimDegenReward(
        ClaimRewardParams calldata claimRewardParams
    ) external override {
        address user = claimRewardParams.user;
        uint256 nonce = ++_claimRewardNonce[user];

        PortalLib._checkClaimRewardSig(
            claimRewardParams,
            nonce,
            address(_registry)
        );

        vault.reward(user, claimRewardParams.amount);

        emit ClaimDegenReward(
            user,
            nonce,
            claimRewardParams.amount,
            claimRewardParams.t,
            claimRewardParams.r,
            claimRewardParams.s,
            claimRewardParams.v
        );
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimNativeDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override nonReentrant whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropNativeRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingNativeAmount = totalAmount -
            _airdropDebt[msg.sender].nativeDebt;

        if (remainingNativeAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].nativeDebt = uint128(totalAmount);

        // transfer from portal directly, so the remaining native in airdrop vault will become a part of jackpot
        payable(msg.sender).sendValue(remainingNativeAmount);

        emit ClaimNativeAirdrop(remainingNativeAmount);
    }

    /**
     * @inheritdoc IRebornPortal
     */
    function claimDegenDrops(
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, totalAmount)))
        );

        bool valid = MerkleProof.verify(merkleProof, _dropDegenRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }

        uint256 remainingDegenAmount = totalAmount -
            _airdropDebt[msg.sender].degenDebt;

        if (remainingDegenAmount == 0) {
            revert NoRemainingReward();
        }

        _airdropDebt[msg.sender].degenDebt = uint128(totalAmount);

        airdropVault.rewardDegen(msg.sender, remainingDegenAmount);

        emit ClaimDegenAirdrop(remainingDegenAmount);
    }

    /**
     * @dev Upkeep perform of chainlink automation
     */
    function performUpkeep(
        bytes calldata performData
    ) external override whenNotStopped {}

    /**
     * @inheritdoc IRebornPortal
     */
    function toNextSeason() external onlyOwner {
        _getPiggyBank().stop(_season);

        unchecked {
            _season++;
        }

        // update piggyBank
        _getPiggyBank().initializeSeason(
            _season,
            uint32(block.timestamp),
            0.1 ether
        );

        // pause the contract
        _pause();

        emit NewSeason(_season);
    }

    /**
     * @dev manually set season, for convenient
     * @param season the season to set
     */
    function setSeason(uint256 season) public onlyOwner {
        _season = season;
        emit NewSeason(_season);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function setCharProperty(
        uint256[] calldata tokenIds,
        PortalLib.CharacterParams[] calldata charParams
    ) external onlySigner {
        uint256 tokenIdLength = tokenIds.length;
        uint256 charParamsLength = charParams.length;
        if (tokenIdLength != charParamsLength) {
            revert CommonError.InvalidParams();
        }
        for (uint256 i = 0; i < tokenIdLength; ) {
            uint256 tokenId = tokenIds[i];
            PortalLib.CharacterParams memory charParam = charParams[i];
            PortalLib.CharacterProperty
                storage charProperty = _characterProperties[tokenId];

            charProperty.maxAP = uint8(charParam.maxAP);
            charProperty.restoreTimePerAP = uint24(charParam.restoreTimePerAP);

            // restore all AP immediately when upgrade
            charProperty.currentAP = uint8(charParam.maxAP);

            charProperty.level = uint8(charParam.level);

            unchecked {
                i++;
            }
        }
    }

    function setNativeDropRoot(
        bytes32 nativeDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropNativeRoot = nativeDropRoot;

        emit NativeDropRootSet(nativeDropRoot, timestamp);
    }

    function setDegenDropRoot(
        bytes32 degenDropRoot,
        uint256 timestamp
    ) external onlySigner {
        _dropDegenRoot = degenDropRoot;

        emit DegenDropRootSet(degenDropRoot, timestamp);
    }

    /**
     * @notice mul 100 when set. eg: 8% -> 800 18%-> 1800
     * @dev set percentage of referrer reward
     * @param rewardType 0: incarnate reward 1: engrave reward
     */
    function setReferrerRewardFee(
        uint16 refL1Fee,
        uint16 refL2Fee,
        PortalLib.RewardType rewardType
    ) external onlyOwner {
        if (rewardType == PortalLib.RewardType.NativeToken) {
            rewardFees.incarnateRef1Fee = refL1Fee;
            rewardFees.incarnateRef2Fee = refL2Fee;
        } else if (rewardType == PortalLib.RewardType.RebornToken) {
            rewardFees.vaultRef1Fee = refL1Fee;
            rewardFees.vaultRef2Fee = refL2Fee;
        }
    }

    /**
     * @dev set vault
     * @param vault_ new vault address
     */
    function setVault(RewardVault vault_) external onlyOwner {
        vault = vault_;
        emit VaultSet(address(vault_));
    }

    function setRegistry(address r) external onlyOwner {
        _registry = IRegistry(r);
    }

    /**
     * @dev set airdrop vault
     * @param vault_ new airdrop vault address
     */
    function setAirdropVault(IAirdropVault vault_) external onlyOwner {
        airdropVault = vault_;
        emit AirdropVaultSet(address(vault_));
    }

    /**
     * @dev set incarnation limit
     */
    function setIncarnationLimit(uint256 limit) external onlyOwner {
        _incarnateCountLimit = limit;
        emit NewIncarnationLimit(limit);
    }

    /**
     * @dev withdraw token from vault
     * @param to the address which owner withdraw token to
     */
    function withdrawVault(address to) external onlyOwner {
        vault.withdrawEmergency(to);
    }

    /**
     * @dev withdraw token from airdrop vault
     * @param to the address which owner withdraw token to
     */
    function withdrawAirdropVault(address to) external onlyOwner {
        airdropVault.withdrawEmergency(to);
    }

    /**
     * @dev burn $REBORN from burn pool
     * @param amount burn from burn pool
     */
    function burnFromBurnPool(uint256 amount) external onlyOwner {
        IBurnPool(burnPool).burn(amount);
    }

    /**
     * @dev forging with permit
     */
    function forging(
        uint256 tokenId,
        uint256 toLevel,
        PermitParams calldata permitParams
    ) external {
        _permit(permitParams);
        _forging(tokenId, toLevel);
    }

    function forging(uint256 tokenId, uint256 toLevel) external {
        _forging(tokenId, toLevel);
    }

    function _forging(uint256 tokenId, uint256 toLevel) internal {
        uint256 currentLevel = _characterProperties[tokenId].level;
        if (currentLevel >= toLevel) {
            revert CommonError.InvalidParams();
        }
        uint256 requiredAmount;
        for (uint256 i = currentLevel; i < toLevel; ) {
            uint256 thisLevelAmount = _forgeRequiredMaterials[i];

            if (thisLevelAmount == 0) {
                revert CommonError.InvalidParams();
            }

            unchecked {
                requiredAmount += thisLevelAmount;
                i++;
            }
        }

        _getDegen().transferFrom(msg.sender, burnPool, requiredAmount);

        emit ForgedTo(tokenId, toLevel, requiredAmount);
    }

    function initializeSeason(uint256 target) external payable onlyOwner {
        _getPiggyBank().initializeSeason{value: msg.value}(
            _season,
            BlockNumberReader.getBlockNumber(),
            target
        );
    }

    function setForgingRequiredAmount(
        uint256[] memory levels,
        uint256[] memory amounts
    ) external onlyOwner {
        uint256 levelsLength = levels.length;
        uint256 amountsLength = amounts.length;

        if (levelsLength != amountsLength) {
            revert CommonError.InvalidParams();
        }

        for (uint256 i = 0; i < levelsLength; ) {
            _forgeRequiredMaterials[levels[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    // set burnPool address for pre burn $REBORN
    function setBurnPool(address burnPool_) external onlyOwner {
        if (burnPool_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        burnPool = burnPool_;
    }

    function setPiggyBankFee(uint256 piggyBankFee_) external onlyOwner {
        piggyBankFee = piggyBankFee_;

        emit SetNewPiggyBankFee(piggyBankFee_);
    }

    /**
     * @dev withdraw native token for reward distribution
     * @dev amount how much to withdraw
     */
    function withdrawNativeToken(
        address to,
        uint256 amount
    ) external onlyOwner {
        payable(to).sendValue(amount);
    }

    /**
     * @dev checkUpkeep for chainlink automation
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {}

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return Renderer.renderByTokenId(details, tokenId);
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(PermitParams calldata permitParams) internal {
        _getDegen().permit(
            msg.sender,
            address(this),
            permitParams.amount,
            permitParams.deadline,
            permitParams.v,
            permitParams.r,
            permitParams.s
        );
    }

    function _infuse(
        uint256 tokenId,
        uint256 amount,
        TributeDirection tributeDirection
    ) internal {
        // it's not necessary to check the whether the address of burnPool is zero
        // as function transferFrom does not allow transfer to zero address by default
        _getDegen().transferFrom(msg.sender, burnPool, amount);

        emit Infuse(msg.sender, tokenId, amount, tributeDirection);
    }

    /**
     * @dev record referrer relationship
     */
    function _refer(ReferParams calldata referParams) internal {
        // parent refer msg.sender
        if (
            referrals[msg.sender] == address(0) &&
            referParams.parent != address(0) &&
            referParams.parent != msg.sender
        ) {
            referrals[msg.sender] = referParams.parent;
            emit Refer(msg.sender, referParams.parent);
        }
        // grandParent refer parent
        if (
            referrals[referParams.parent] == address(0) &&
            referParams.grandParent != address(0) &&
            referParams.parent != referParams.grandParent
        ) {
            referrals[referParams.parent] = referParams.grandParent;
            emit Refer(referParams.parent, referParams.grandParent);
        }
    }

    /**
     * @dev implementation of incarnate
     */
    function _incarnate(
        InnateParams calldata innate,
        SoupParams calldata soupParams
    ) internal {
        // use soup
        PortalLib._useSoupParam(
            soupParams,
            getIncarnateCount(_season, msg.sender),
            _characterProperties,
            address(_registry)
        );

        uint256 nativeFee = soupParams.soupPrice +
            innate.talentNativePrice +
            innate.propertyNativePrice;

        uint256 degenFee = innate.talentDegenPrice + innate.propertyDegenPrice;

        // both larger and smaller are invalid
        if (msg.value != nativeFee) {
            revert CommonError.InvalidParams();
        }

        // reward referrers
        uint256 referNativeAmount = PortalLib._sendNativeRewardToRefs(
            referrals,
            rewardFees,
            _rewardToClaim,
            msg.sender,
            nativeFee
        );

        uint256 netNativeAmount;
        unchecked {
            netNativeAmount = nativeFee - referNativeAmount;
        }

        uint256 piggyBankAmount = (netNativeAmount * piggyBankFee) /
            PortalLib.PERCENTAGE_BASE;

        // more check
        // piggy bank amount should be less than net native amount
        if (piggyBankAmount > netNativeAmount) {
            revert CommonError.InvalidParams();
        }

        // x% to piggyBank
        _getPiggyBank().deposit{value: piggyBankAmount}(
            _season,
            msg.sender,
            nativeFee
        );

        // degen to burn pool
        _getDegen().transferFrom(msg.sender, burnPool, degenFee);

        // mint erc721
        uint256 tokenId;
        unchecked {
            // tokenId auto increment
            tokenId = ++idx + (block.chainid * 1e18);
        }
        _safeMint(msg.sender, tokenId);
        // set creator
        details[tokenId].creator = msg.sender;

        emit Incarnate(
            msg.sender,
            tokenId,
            soupParams.charTokenId,
            innate.talentNativePrice,
            innate.talentDegenPrice,
            innate.propertyNativePrice,
            innate.propertyDegenPrice,
            soupParams.soupPrice
        );
    }

    function _exhume(ExhumeParams calldata exhumeParams) internal nonReentrant {
        uint256 nativeCost = exhumeParams.nativeCost;
        uint256 degenCost = exhumeParams.degenCost;
        address exhumee = exhumeParams.exhumee;
        uint256 tombstoneTokenId = exhumeParams.tokenId;
        address creator = details[tombstoneTokenId].creator;

        if (details[tombstoneTokenId].score == 0) {
            revert CommonError.TombstoneNotEngraved();
        }

        uint256 currentCount;
        unchecked {
            currentCount = ++_exhumeCount[tombstoneTokenId];
        }

        // check signature and param
        PortalLib._checkExhumeSig(
            exhumeParams,
            currentCount,
            address(_registry)
        );

        // check tombstone tokenId owner
        if (ownerOf(tombstoneTokenId) != exhumee) {
            revert CommonError.ExhumeeNotTombStoneOwner();
        }

        // check shovel and burn
        if (exhumeParams.shovelTokenId != 0) {
            if (
                _getShovel().ownerOf(exhumeParams.shovelTokenId) != msg.sender
            ) {
                revert CommonError.NotShovelOwner();
            }
            _getShovel().burn(exhumeParams.shovelTokenId);
        }

        // check native token
        // minus directly as if msg.value is not enough, it will overflow
        uint256 extraAmount = msg.value - nativeCost;
        payable(msg.sender).sendValue(extraAmount);

        // distribute native and degen token
        if (currentCount == 1) {
            // 80% native to last owner
            payable(exhumee).sendValue((nativeCost * 80) / 100);
            // 10%  to creator
            payable(exhumee).sendValue((nativeCost * 10) / 100);
        } else {
            // 85% native to last owner
            payable(exhumee).sendValue((nativeCost * 85) / 100);
            // 5% native to creator
            payable(creator).sendValue((nativeCost * 5) / 100);
        }

        // 70% degen burn
        _getDegen().transferFrom(msg.sender, burnPool, (degenCost * 70) / 100);

        // 25% degen to last owner
        _getDegen().transferFrom(msg.sender, exhumee, (degenCost * 25) / 100);

        // 5% degen to creator
        _getDegen().transferFrom(msg.sender, creator, (degenCost * 5) / 100);

        // transfer nft ownership
        // it will check old ownership again
        _transfer(exhumee, msg.sender, tombstoneTokenId);

        // emit event
        emit Exhume(
            msg.sender,
            exhumee,
            tombstoneTokenId,
            exhumeParams.shovelTokenId,
            currentCount,
            nativeCost,
            degenCost,
            (nativeCost * 1) / 10
        );
    }

    function _recoverAP(uint256 charTokenId, uint256 recoveredAP) internal {
        // recover char AP
        if (charTokenId != 0) {
            uint256 increasedAP = _characterProperties[charTokenId].currentAP +
                recoveredAP;
            if (increasedAP > _characterProperties[charTokenId].maxAP) {
                _characterProperties[charTokenId]
                    .currentAP = _characterProperties[charTokenId].maxAP;
            } else {
                _characterProperties[charTokenId].currentAP = uint8(
                    increasedAP
                );
            }
        }
    }

    function _rewardDegenRewardToRefs(
        address creator,
        uint256 reward
    ) internal {
        // record reward for referrer
        PortalLib._rewardDegenRewardToRefs(
            referrals,
            rewardFees,
            _rewardToClaim,
            creator,
            reward
        );
    }

    /**
     * @dev returns referrer and referrer reward
     * @return ref1 level1 of referrer. direct referrer
     * @return ref1Reward level 1 referrer reward
     * @return ref2 level2 of referrer. referrer's referrer
     * @return ref2Reward level 2 referrer reward
     */
    function calculateReferReward(
        address account,
        uint256 amount,
        PortalLib.RewardType rewardType
    )
        public
        view
        returns (
            address ref1,
            uint256 ref1Reward,
            address ref2,
            uint256 ref2Reward
        )
    {
        return
            PortalLib._calculateReferReward(
                referrals,
                rewardFees,
                account,
                amount,
                rewardType
            );
    }

    function getIncarnateCount(
        uint256 season,
        address user
    ) public view returns (uint256) {
        return _incarnateCounts[season][user];
    }

    function getIncarnateLimit() public view returns (uint256) {
        return _incarnateCountLimit;
    }

    function getClaimDegenNonces(
        address user
    ) public view override returns (uint256) {
        return _claimRewardNonce[user];
    }

    /**
     * A -> B -> C: B: level1 A: level2
     * @dev referrer1: level1 of referrers referrer2: level2 of referrers
     */
    function getReferrers(
        address account
    ) public view returns (address referrer1, address referrer2) {
        referrer1 = referrals[account];
        referrer2 = referrals[referrer1];
    }

    function getAirdropDebt(
        address user
    ) public view returns (AirDropDebt memory) {
        return _airdropDebt[user];
    }

    function getRewardToClaim(
        address user,
        RewardToClaimType t
    ) public view returns (RewardStore memory) {
        return _rewardToClaim[user][t];
    }

    function readCharProperty(
        uint256 tokenId
    ) public view returns (PortalLib.CharacterProperty memory) {
        PortalLib.CharacterProperty memory charProperty = _characterProperties[
            tokenId
        ];

        PortalLib.CurrentAPReturn memory car = PortalLib._calculateCurrentAP(
            charProperty
        );

        charProperty.currentAP = uint8(car.currentAP);

        charProperty.lastTimeAPUpdate = uint32(car.lastAPUpdateTime);

        return charProperty;
    }

    function _checkIncarnationCount() internal {
        uint256 currentIncarnateCount = getIncarnateCount(_season, msg.sender);
        if (currentIncarnateCount >= _incarnateCountLimit) {
            revert IncarnationExceedLimit();
        }

        unchecked {
            _incarnateCounts[_season][msg.sender] = ++currentIncarnateCount;
        }
    }

    /**
     * @dev check signer implementation
     */
    function _checkSigner() internal view {
        if (!_registry.checkIsSigner(msg.sender)) {
            revert CommonError.NotSigner();
        }
    }

    function _checkStopped() internal view {
        if (_getPiggyBank().checkIsSeasonEnd(_season)) {
            revert SeasonAlreadyStopped();
        }

        if (paused()) {
            revert PauseablePaused();
        }
    }

    function _getPiggyBank() internal view returns (IPiggyBank) {
        return IPiggyBank(_registry.getPiggyBank());
    }

    function _getDegen() internal view returns (RBT) {
        return RBT(_registry.getDegen());
    }

    function _getShovel() internal view returns (IDegenShovel) {
        return IDegenShovel(_registry.getShovel());
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }

    /**
     * @dev check incarnation Count and auto increment if it meets
     */
    modifier checkIncarnationCount() {
        _checkIncarnationCount();
        _;
    }

    modifier whenNotStopped() {
        _checkStopped();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IRebornDefinition} from "src/interfaces/IRebornPortal.sol";
import {IRebornToken} from "src/interfaces/IRebornToken.sol";
import {IRewardVault} from "src/interfaces/IRewardVault.sol";
import {BitMapsUpgradeable} from "src/oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {PortalLib} from "src/PortalLib.sol";
import {IPiggyBank} from "src/interfaces/IPiggyBank.sol";
import {IAirdropVault} from "src/interfaces/IAirdropVault.sol";
import {IRegistry} from "src/interfaces/IRegistry.sol";

abstract contract RebornPortalStorage is IRebornDefinition {
    //########### Link Contract Address ########## //
    IRebornToken private rebornToken;
    IRewardVault public vault;
    address public burnPool;
    IPiggyBank private piggyBank;

    uint256 internal _season;

    //#### Access #####//
    mapping(address => bool) private signers;

    //#### Incarnation ######//
    uint256 internal idx;
    mapping(address => uint256) internal rounds;
    mapping(uint256 => LifeDetail) internal details;
    BitMapsUpgradeable.BitMap internal _seeds;
    // season => user address => count
    mapping(uint256 => mapping(address => uint256)) internal _incarnateCounts;
    // max incarnation count
    uint256 internal _incarnateCountLimit;

    //##### Tribute ###### //
    mapping(uint256 => SeasonData) internal _seasonData;

    //#### Refer #######//
    mapping(address => address) internal referrals;
    PortalLib.ReferrerRewardFees internal rewardFees;

    //#### airdrop config #####//
    AirdropConf private _dropConf;
    VrfConf private _vrfConf;
    // requestId => request status
    mapping(uint256 => RequestStatus) private _vrfRequests;
    uint256[3] private _placeholder2;

    //########### NFT ############//
    // tokenId => character property
    mapping(uint256 => PortalLib.CharacterProperty)
        internal _characterProperties;
    // tokenId => token amount required
    mapping(uint256 => uint256) internal _forgeRequiredMaterials;

    //######### Piggy Bank #########//
    // X% to piggyBank piggyBankFee / 10000
    uint256 internal piggyBankFee;

    // airdrop vault
    IAirdropVault public airdropVault;

    mapping(address => AirDropDebt) internal _airdropDebt;

    bytes32 internal _dropNativeRoot;
    bytes32 internal _dropDegenRoot;

    IRegistry public _registry;
    uint96 internal _placeholder;

    // tokenId => exhumed count
    mapping(uint256 => uint256) internal _exhumeCount;

    mapping(address => mapping(RewardToClaimType => RewardStore))
        internal _rewardToClaim;

    mapping(address => uint256) internal _claimRewardNonce;

    /// @dev gap for potential variable
    uint256[19] private _gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeOwnableUpgradeable} from "@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol";
import {IRegistry} from "src/interfaces/IRegistry.sol";
import {CommonError} from "src/library/CommonError.sol";

contract Registry is IRegistry, UUPSUpgradeable, SafeOwnableUpgradeable {
    event DegenSet(address degen);
    event PortalSet(address portal);
    event ShovelSet(address shovel);
    event PiggyBankSet(address piggyBank);

    mapping(address => bool) private _signers;
    address private _degen;
    address private _portal;
    address private _shovel;
    address private _piggyBank;

    uint256[45] private __gap;

    function initialize(address owner_) public initializer {
        if (owner_ == address(0)) {
            revert CommonError.ZeroAddressSet();
        }
        __Ownable_init_unchained(owner_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev update signers
     * @param toAdd list of to be added signer
     * @param toRemove list of to be removed signer
     */
    function updateSigners(
        address[] calldata toAdd,
        address[] calldata toRemove
    ) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            _signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], true);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete _signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], false);
        }
    }

    function setDegen(address addr) public onlyOwner {
        _degen = addr;
        emit DegenSet(address(addr));
    }

    function setPortal(address addr) public onlyOwner {
        _portal = addr;
        emit PortalSet(address(addr));
    }

    function setShovel(address addr) public onlyOwner {
        _shovel = addr;
        emit ShovelSet(address(addr));
    }

    function setPiggyBank(address addr) public onlyOwner {
        _piggyBank = addr;
        emit PiggyBankSet(address(addr));
    }

    function checkIsSigner(address addr) public override view returns (bool) {
        return _signers[addr];
    }

    function getDegen() public view override returns (address) {
        return _degen;
    }

    function getPortal() public view override returns (address) {
        return _portal;
    }

    function getShovel() public view override returns (address) {
        return _shovel;
    }

    function getPiggyBank() public view override returns (address) {
        return _piggyBank;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardVault} from "src/interfaces/IRewardVault.sol";

contract RewardVault is IRewardVault, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rebornToken;

    constructor(address owner_, address rebornToken_) {
        if (rebornToken_ == address(0)) revert ZeroAddressSet();
        _transferOwnership(owner_);
        rebornToken = rebornToken_;
    }

    /**
     * @notice Send reward to user
     * @param to The address of awards
     * @param amount number of awards
     */
    function reward(
        address to,
        uint256 amount
    ) external virtual override onlyOwner {
        IERC20(rebornToken).safeTransfer(to, amount);
    }

    /**
     * @notice withdraw token Emergency
     */
    function withdrawEmergency(address to) external virtual override onlyOwner {
        if (to == address(0)) revert ZeroAddressSet();
        IERC20(rebornToken).safeTransfer(
            to,
            IERC20(rebornToken).balanceOf(address(this))
        );
        emit WithdrawEmergency(
            rebornToken,
            IERC20(rebornToken).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
// Thanks Yos Riady
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity ^0.8.0;

import "src/oz/contracts-upgradeable/proxy/utils/Initializable.sol";
import "src/oz/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    error CallerNotOwner();
    error ZeroAddressOwnerSet();
    error CallerNotPendingOwner();
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(
        address owner_
    ) internal onlyInitializing {
        _transferOwnership(owner_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Return the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert CallerNotOwner();
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
     * only happens when the pending owner claim the ownership
     */
    function transferOwnership(
        address newOwner,
        bool direct
    ) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressOwnerSet();
        }
        if (direct) {
            _transferOwnership(newOwner);
        } else {
            _transferPendingOwnership(newOwner);
        }
    }

    /**
     * @dev pending owner call this function to claim ownership
     */
    function claimOwnership() public {
        if (msg.sender != _pendingOwner) {
            revert CallerNotPendingOwner();
        }

        _claimOwnership();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        // compatible with hardhat-deploy, maybe removed later
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev set the pending owner address
     * Internal function without access restriction.
     */
    function _transferPendingOwnership(address newOwner) internal virtual {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _claimOwnership() internal virtual {
        address oldOwner = _owner;
        emit OwnershipTransferred(oldOwner, _pendingOwner);

        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}