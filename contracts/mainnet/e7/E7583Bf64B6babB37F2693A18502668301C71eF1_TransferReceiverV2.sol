/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

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

abstract contract AdminableInitializable {
    address public admin;
    address public candidate;

    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor() {}

    function __Adminable_init(address _admin) internal {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminUpdated(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminUpdated(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }

    uint256[64] private __gap;
}



abstract contract PausableInitializable is AdminableInitializable {
    bool public paused;

    event Paused();
    event Resumed();

    constructor() {}

    function __Pausable_init(address _admin) internal {
        __Adminable_init(_admin);
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function pause() external onlyAdmin {
        paused = true;
        emit Paused();
    }

    function resume() external onlyAdmin {
        paused = false;
        emit Resumed();
    }

    uint256[64] private __gap;
}


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


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool); //
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //
    function balanceOf(address account) external view returns (uint256); //
    function mint(address account, uint256 amount) external returns (bool); //
    function approve(address spender, uint256 amount) external returns (bool); //
    function allowance(address owner, address spender) external view returns (uint256); //
}

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



interface IReserved {

    struct Reserved {
        address to;
        uint256 at;
    }

}


interface IRewardRouter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function glp() external view returns (address);
    function weth() external view returns (address);
    function bnGmx() external view returns (address);

    function stakedGmxTracker() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);

    function stakeEsGmx(uint256 _amount) external;
    
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;
    function pendingReceivers(address _account) external view returns (address);
}



interface ITransferReceiver is IReserved {
    function initialize(
        address _admin,
        address _config,
        address _converter,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards
    ) external;
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGlpTracker() external view returns (address);
    function weth() external view returns (address);
    function esGmx() external view returns (address);
    function stakedGlp() external view returns (address);
    function converter() external view returns (address);
    function rewards() external view returns (address);
    function transferSender() external view returns (address);
    function transferSenderReserved() external view returns (address to, uint256 at);
    function newTransferReceiverReserved() external view returns (address to, uint256 at);
    function accepted() external view returns (bool);
    function isForMpKey() external view returns (bool);
    function reserveTransferSender(address _transferSender, uint256 _at) external;
    function setTransferSender() external;
    function reserveNewTransferReceiver(address _newTransferReceiver, uint256 _at) external;
    function claimAndUpdateReward(address feeTo) external;
    function signalTransfer(address to) external;
    function acceptTransfer(address sender, bool _isForMpKey) external;
    function version() external view returns (uint256);
    event TransferAccepted(address indexed sender);
    event SignalTransfer(address indexed from, address indexed to);
    event TokenWithdrawn(address token, address to, uint256 balance);
    event TransferSenderReserved(address transferSender, uint256 at);
    event NewTransferReceiverReserved(address indexed to, uint256 at);
}



interface ITransferReceiverV2 is ITransferReceiver {
    function claimAndUpdateRewardFromTransferSender(address feeTo) external;
    function defaultTransferSender() external view returns (address);
}



interface ITransferSender {
    struct Lock {
        address account;
        uint256 startedAt;
    }

    struct Price {
        uint256 gmxKey;
        uint256 gmxKeyFee;
        uint256 esGmxKey;
        uint256 esGmxKeyFee;
        uint256 mpKey;
        uint256 mpKeyFee;
    }

    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function converter() external view returns (address);
    function treasury() external view returns (address);
    function converterReserved() external view returns (address, uint256);
    function feeCalculator() external view returns (address);
    function feeCalculatorReserved() external view returns (address, uint256);
    function addressLock(address _receiver) external view returns (address, uint256);
    function addressPrice(address _receiver) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function unwrappedReceivers(uint256 index) external view returns (address);
    function unwrappedReceiverLength() external view returns (uint256);
    function isUnwrappedReceiver(address _receiver) external view returns (bool);
    function unwrappedAmount(address account, address token) external view returns (uint256);
    function setTreasury(address _treasury) external;
    function reserveConverter(address _converter, uint256 _at) external;
    function setConverter() external;
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external;
    function setFeeCalculator() external;
    function lock(address _receiver) external returns (Lock memory, Price memory);
    function unwrap(address _receiver) external;
    function changeAcceptableAccount(address _receiver, address account) external;
    function isUnlocked(address _receiver) external view returns (bool);


    event ConverterReserved(address to, uint256 at);
    event ConverterSet(address to, uint256 at);
    event FeeCalculatorReserved(address to, uint256 at);
    event FeeCalculatorSet(address to, uint256 at);
    event UnwrapLocked(address indexed account, address indexed receiver, Lock _lock, Price _price);
    event UnwrapCompleted(address indexed account, address indexed receiver, Price _price);
    event AcceptableAccountChanged(address indexed account, address indexed receiver, address indexed to);
}



contract ConfigUserInitializable {
    address public config;

    constructor() {}

    function __ConfigUser_init(address _config) internal {
        require(_config != address(0), "ConfigUserInitializable: config is the zero address");
        config = _config;
    }

    uint256[64] private __gap;
}




interface IConfig {
    function MIN_DELAY_TIME() external pure returns (uint256);
    function upgradeDelayTime() external view returns (uint256);
    function setUpgradeDelayTime(uint256 time) external;
    function getUpgradeableAt() external view returns (uint256);
}




interface IRewards {
    function FEE_PERCENTAGE_BASE() external view returns (uint16);
    function FEE_PERCENTAGE_MAX() external view returns (uint16);
    function FEE_TIER_LENGTH_MAX() external view returns (uint128);
    function PRECISION() external view returns (uint128);
    function PERIOD() external view returns (uint256);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function weth() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function staker() external view returns (address);
    function converter() external view returns (address);
    function treasury() external view returns (address);
    function feeCalculator() external view returns (address);
    function rewardPerUnit(address stakingToken, address rewardToken, uint256 periodIndex) external view returns (uint256);
    function lastRewardPerUnit(address account, address stakingToken, address rewardToken, uint256 periodIndex) external view returns (uint256);
    function reward(address account, address stakingToken, address rewardToken) external view returns (uint256);
    function lastDepositBalancesForReceivers(address receiver, address token) external view returns (uint256);
    function cumulatedReward(address stakingToken, address rewardToken) external view returns (uint256);
    function feeTiers(address rewardToken, uint256 index) external view returns (uint256);
    function feePercentages(address rewardToken, uint256 index) external view returns (uint16);
    function feeLength(address rewardToken) external view returns (uint256);
    function lastUpdatedAt(address receiver) external view returns (uint256);
    function currentPeriodIndex() external view returns (uint256);
    function maxPeriodsToUpdateRewards() external view returns (uint256);
    function feeCalculatorReserved() external view returns (address, uint256);
    function setTreasury(address _treasury) external;
    function setConverter(address _converter) external;
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external;
    function setFeeCalculator() external;
    function setFeeTiersAndPercentages(address _rewardToken, uint256[] memory _feeTiers, uint16[] memory _feePercentages) external;
    function setMaxPeriodsToUpdateRewards(uint256 _maxPeriodsToUpdateRewards) external;
    function claimRewardWithIndices(address account, uint256[] memory periodIndices) external;
    function claimRewardWithCount(address account, uint256 count) external;
    function claimableRewardWithIndices(address account, uint256[] memory periodIndices) external view returns(uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey);
    function claimableRewardWithCount(address account, uint256 count) external view returns (uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey);
    function initTransferReceiver() external;
    function updateAllRewardsForTransferReceiverAndTransferFee(address feeTo) external;
    event RewardClaimed(
        address indexed account,
        uint256 esGMXKeyAmountByGMXkey, uint256 esGMXKeyFeeByGMXkey, uint256 mpKeyAmountByGMXKey, uint256 mpKeyFeeByGMXkey,
        uint256 esGmxKeyAmountByEsGMXkey, uint256 esGmxKeyFeeByEsGMXkey, uint256 mpKeyAmountByEsGMXkey, uint256 mpKeyFeeByEsGMXkey,
        uint256 ethAmountByGMXkey, uint256 ethFeeByGMXkey,
        uint256 ethAmountByEsGMXkey, uint256 ethFeeByEsGMXkey,
        uint256 ethAmountByMPkey, uint256 ethFeeByMPkey);
    event ReceiverInitialized(address indexed receiver, uint256 stakedGmxAmount, uint256 stakedEsGmxAmount, uint256 stakedMpAmount);
    event RewardsCalculated(address indexed receiver, uint256 esGmxKeyAmountToMint, uint256 mpKeyAmountToMint, uint256 wethAmountToTransfer);
    event FeeUpdated(address token, uint256[] newFeeTiers, uint16[] newFeePercentages);
    event StakingFeeCalculatorReserved(address to, uint256 at);
}

interface IRewardTracker {
    function unstake(address _depositToken, uint256 _amount) external;
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function stakedAmounts(address account) external view returns (uint256);
    function depositBalances(address account, address depositToken) external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function glp() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function averageStakedAmounts(address account) external view returns (uint256);
    function cumulativeRewards(address account) external view returns (uint256);

}



/**
 * @title TransferReceiver
 * @author Key Finance
 * @notice
 * This contract is used to receive tokens (GMX, esGMX) and MP(Multiplier Point) when they are liquidated (during Convert).
 * Due to GMX protocol constraints, an unused account capable of receiving GMX, esGMX, and MP is needed when liquidating them. 
 * This contract serves as that account.
 * A new contract is deployed and used each time a new account uses the Convert feature.
 * 
 * This contract includes functions for initially receiving tokens and for settling rewards generated later.
 */
contract TransferReceiver is ITransferReceiver, Initializable, UUPSUpgradeable, ConfigUserInitializable, ReentrancyGuardUpgradeable, PausableInitializable {
    using SafeERC20 for IERC20;

    uint256 private _version;

    // external contracts
    IRewardRouter public rewardRouter;
    address public stakedGlpTracker;
    address public weth;
    address public esGmx;
    address public stakedGlp;

    // key protocol contracts
    address public converter;
    address public rewards;
    address public transferSender;

    // state variables
    Reserved public transferSenderReserved;
    Reserved public newTransferReceiverReserved;
    bool public accepted;
    bool public isForMpKey;

    constructor() {
        stakedGlpTracker = address(0xdead);
        // prevent any update on the state variables
    }

    function initialize(
        address _admin,
        address _config,
        address _converter,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards
    ) external initializer {
        require(stakedGlpTracker == address(0), "TransferReceiver: already initialized");

        __UUPSUpgradeable_init();
        __ConfigUser_init(_config);
        __Pausable_init(_admin);
        __ReentrancyGuard_init();

        require(_converter != address(0), "TransferReceiver: converter is the zero address");
        require(address(_rewardRouter) != address(0), "TransferReceiver: rewardRouter is the zero address");
        require(_stakedGlp != address(0), "TransferReceiver: stakedGlp is the zero address");
        require(_rewards != address(0), "TransferReceiver: rewards is the zero address");
        converter = _converter;
        rewardRouter = _rewardRouter;
        stakedGlpTracker = _rewardRouter.stakedGlpTracker();
        require(stakedGlpTracker != address(0), "TransferReceiver: stakedGlpTracker is the zero address");
        esGmx = _rewardRouter.esGmx();
        require(esGmx != address(0), "TransferReceiver: esGmx is the zero address");
        stakedGlp = _stakedGlp;
        require(stakedGlp != address(0), "TransferReceiver: stakedGlp is the zero address");
        weth = _rewardRouter.weth();
        require(weth != address(0), "TransferReceiver: stakedGlp is the zero address");
        rewards = _rewards;
        _version = 0;
    }

    modifier onlyTransferSender() virtual {
        require(msg.sender == transferSender, "only transferSender");
        _;
    }

    // - config functions - //

    /**
     * @notice Reserves to set TransferSender contract.
     * @param _transferSender contract address
     * @param _at transferSender can be set after this time
     *
     */
    function reserveTransferSender(address _transferSender, uint256 _at) external onlyAdmin {
        require(_transferSender != address(0), "TransferReceiver: transferSender is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "TransferReceiver: at should be later");
        transferSenderReserved = Reserved(_transferSender, _at);
        emit TransferSenderReserved(_transferSender, _at);
    }

    /**
     * @notice Sets reserved TransferSender contract.
     */
    function setTransferSender() external onlyAdmin {
        require(transferSenderReserved.at != 0 && transferSenderReserved.at <= block.timestamp, "TransferReceiver: transferSender is not yet available");
        transferSender = transferSenderReserved.to;
    }

    /**
     * @notice Reserves TransferReceiver upgrade. Only can be upgraded after a certain time.
     * @param _newTransferReceiver The new TransferReceiver contract to be upgraded.
     * @param _at After this time, _authorizeUpgrade function can be passed.
     */
    function reserveNewTransferReceiver(address _newTransferReceiver, uint256 _at) external onlyAdmin {
        require(accepted, "TransferReceiver: not yet accepted");
        require(_newTransferReceiver != address(0), "TransferReceiver: _newTransferReceiver is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "TransferReceiver: at should be later");
        newTransferReceiverReserved = Reserved(_newTransferReceiver, _at);
        emit NewTransferReceiverReserved(_newTransferReceiver, _at);
    }

    // - external state-changing functions - //

    /**
     * @notice Settles various rewards allocated by the GMX protocol to this contract.
     * Claims rewards in the form of GMX, esGMX, and WETH,
     * calculates and updates related values for the resulting esGMXkey and MPkey staking rewards.
     * Transfers esGMXkey, MPkey, and WETH fees to the calling account.
     * @param feeTo Account to transfer fee to.
     */
    function claimAndUpdateReward(address feeTo) external virtual nonReentrant whenNotPaused {
        uint256 wethBalanceDiff = IERC20(weth).balanceOf(address(this));
        rewardRouter.handleRewards(false, false, true, true, true, true, false);
        wethBalanceDiff = IERC20(weth).balanceOf(address(this)) - wethBalanceDiff;
        if (wethBalanceDiff > 0) IERC20(weth).safeIncreaseAllowance(rewards, wethBalanceDiff);
        IRewards(rewards).updateAllRewardsForTransferReceiverAndTransferFee(feeTo);
    }

    /**
     * @notice Calls signalTransfer to make 'to' account able to accept transfer.
     * @param to Account to transfer tokens to.
     */
    function signalTransfer(address to) external virtual nonReentrant whenNotPaused onlyTransferSender {
        require(accepted, "TransferReceiver: not yet accepted");
        _signalTransfer(to);
    }

    // - external function called by other key protocol contracts - //

    /**
     * @notice Receives tokens and performs processing for tokens that need to be additionally staked or returned.
     * @param sender Account that transferred tokens to this contract.
     * @param _isForMpKey Whether the transferred tokens are for minting MPkey.
     */
    function acceptTransfer(address sender, bool _isForMpKey) external nonReentrant whenNotPaused {
        require(msg.sender == converter, "only converter");

        // Transfers all remaining staked tokens, possibly GMX, esGMX, GLP, etc.
        rewardRouter.acceptTransfer(sender);
        emit TransferAccepted(sender);

        // All esGMX balances will be staked, which will be converted to esGMXkeys.
        uint256 esGmxBalance = IERC20(esGmx).balanceOf(address(this));
        if (esGmxBalance > 0) rewardRouter.stakeEsGmx(esGmxBalance);

        // Transfer GLP back to the sender.
        uint256 stakedGlpBalance = IRewardTracker(stakedGlpTracker).balanceOf(address(this));
        if (stakedGlpBalance > 0) IERC20(stakedGlp).safeTransfer(sender, stakedGlpBalance);

        isForMpKey = _isForMpKey;

        IRewards(rewards).initTransferReceiver();
        accepted = true;
    }

    // - external view functions - //

    function version() external view virtual returns (uint256) {
        return _version;
    }

    // - internal functions - //

    /**
     * Call RewardRouter.signalTransfer to notify the new receiver contract 'to' that it can accept the transfer.
     */
    function _signalTransfer(address to) internal virtual {
        rewardRouter.signalTransfer(to);
        // Approval is needed for a later upgrade of this contract (enabling transfer process including signalTransfer & acceptTransfer).
        // According to the RewardTracker contract, this allowance can only be used for staking GMX to stakedGmxTracker itself.
        // https://github.com/gmx-io/gmx-contracts/blob/master/contracts/staking/RewardTracker.sol#L241
        IERC20 gmxToken = IERC20(rewardRouter.gmx());
        address stakedGmxTracker = rewardRouter.stakedGmxTracker();
        gmxToken.safeIncreaseAllowance(stakedGmxTracker, type(uint256).max);
        emit SignalTransfer(address(this), to);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyAdmin {
        require(address(newImplementation) == newTransferReceiverReserved.to, "TransferReceiver: should be same address with newTransferReceiverReserved.to");
        require(newTransferReceiverReserved.at != 0 && newTransferReceiverReserved.at <= block.timestamp, "TransferReceiver: newTransferReceiver is not yet available");
    }
}


// File contracts/TransferReceiverV2.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;




contract TransferReceiverV2 is TransferReceiver {
    using SafeERC20 for IERC20;

    // @dev replace this as a deployed TransferSender contract address before deploying TransferReceiverV2
    address public constant defaultTransferSender = 0xc6d79DeE3049319eDdB52F040A64167396a2928d;

    function version() external view virtual override returns (uint256) {
        return 1;
    }

    modifier onlyTransferSender() override {
        require(msg.sender == _getTransferSender(), "only transferSender");
        _;
    }

    /**
     * @notice Settles various rewards allocated by the GMX protocol to this contract.
     * Claims rewards in the form of GMX, esGMX, and WETH,
     * calculates and updates related values for the resulting esGMXkey and MPkey staking rewards.
     * Transfers esGMXkey, MPkey, and WETH fees to the calling account.
     * @param feeTo Account to transfer fee to.
     */
    function claimAndUpdateReward(address feeTo) external override nonReentrant whenNotPaused {
        _validateReceiver();
        uint256 wethBalanceDiff = IERC20(weth).balanceOf(address(this));
        rewardRouter.handleRewards(false, false, true, true, true, true, false);
        wethBalanceDiff = IERC20(weth).balanceOf(address(this)) - wethBalanceDiff;
        if (wethBalanceDiff > 0) IERC20(weth).safeIncreaseAllowance(rewards, wethBalanceDiff);
        IRewards(rewards).updateAllRewardsForTransferReceiverAndTransferFee(feeTo);
    }

    /**
     * @notice claimAndUpdateReward which guarantees unwrap by TransferSender even in paused state
     */
    function claimAndUpdateRewardFromTransferSender(address feeTo) external virtual nonReentrant onlyTransferSender {
        _validateReceiver();
        uint256 wethBalanceDiff = IERC20(weth).balanceOf(address(this));
        if (paused) {
            // claim only wETH
            rewardRouter.handleRewards(false, false, false, false, false, true, false);
            wethBalanceDiff = IERC20(weth).balanceOf(address(this)) - wethBalanceDiff;
            if (wethBalanceDiff > 0) IERC20(weth).transfer(feeTo, wethBalanceDiff);
        } else {
            rewardRouter.handleRewards(false, false, true, true, true, true, false);
            wethBalanceDiff = IERC20(weth).balanceOf(address(this)) - wethBalanceDiff;
            if (wethBalanceDiff > 0) IERC20(weth).safeIncreaseAllowance(rewards, wethBalanceDiff);
            IRewards(rewards).updateAllRewardsForTransferReceiverAndTransferFee(feeTo);
        }
    }

    /**
     * @notice Calls signalTransfer to make 'to' account able to accept transfer.
     * @param to Account to transfer tokens to.
     */
    function signalTransfer(address to) external override nonReentrant onlyTransferSender {
        require(accepted, "TransferReceiver: not yet accepted");
        _signalTransfer(to);
    }

    /**
     * Call RewardRouter.signalTransfer to notify the new receiver contract 'to' that it can accept the transfer.
     */
    function _signalTransfer(address to) internal override {
        rewardRouter.signalTransfer(to);
        // Approval is needed for a later upgrade of this contract (enabling transfer process including signalTransfer & acceptTransfer).
        // According to the RewardTracker contract, this allowance can only be used for staking GMX to stakedGmxTracker itself.
        // https://github.com/gmx-io/gmx-contracts/blob/master/contracts/staking/RewardTracker.sol#L241
        IERC20 gmxToken = IERC20(rewardRouter.gmx());
        address stakedGmxTracker = rewardRouter.stakedGmxTracker();
        if (gmxToken.allowance(address(this), stakedGmxTracker) == 0) {
            gmxToken.safeIncreaseAllowance(stakedGmxTracker, type(uint256).max);
        }
        emit SignalTransfer(address(this), to);
    }

    function _getTransferSender() private view returns (address) {
        if (transferSender == address(0)) return defaultTransferSender;
        else return transferSender;
    }

    function _validateReceiver() internal view {
        address _transferSender = _getTransferSender();
        require(!ITransferSender(_transferSender).isUnwrappedReceiver(address(this)), "TransferReceiver: unwrapped receiver");
        require(ITransferSender(_transferSender).isUnlocked(address(this)), "TransferReceiver: lock not yet expired");
    }
}