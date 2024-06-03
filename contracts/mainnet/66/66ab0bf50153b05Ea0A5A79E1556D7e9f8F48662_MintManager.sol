// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
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
interface IBeacon {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Mint interface on editions contracts
 * @author highlight.xyz
 */
interface IERC721EditionMint {
    /**
     * @notice Mints one NFT to one recipient
     * @param editionId Edition to mint the NFT on
     * @param recipient Recipient of minted NFT
     */
    function mintOneToRecipient(uint256 editionId, address recipient) external returns (uint256);

    /**
     * @notice Mints an amount of NFTs to one recipient
     * @param editionId Edition to mint the NFTs on
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToRecipient(uint256 editionId, address recipient, uint256 amount) external returns (uint256);

    /**
     * @notice Mints one NFT each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients) external returns (uint256);

    /**
     * @notice Mints an amount of NFTs each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted per recipient
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice General721 mint interface
 * @author highlight.xyz
 */
interface IERC721GeneralMint {
    /**
     * @notice Mint one token to one recipient
     * @param recipient Recipient of minted NFT
     */
    function mintOneToOneRecipient(address recipient) external returns (uint256);

    /**
     * @notice Mint an amount of tokens to one recipient
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external;

    /**
     * @notice Mint one token to multiple recipients. Useful for use-cases like airdrops
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external;

    /**
     * @notice Mint the same amount of tokens to multiple recipients
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted to each recipient
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount) external;

    /**
     * @notice Mint a chosen token id to a single recipient
     * @param recipient Recipient of chosen NFT
     * @param tokenId ID of NFT to mint
     */
    function mintSpecificTokenToOneRecipient(address recipient, uint256 tokenId) external;

    /**
     * @notice Mint chosen token ids to a single recipient
     * @param recipient Recipient of chosen NFT
     * @param tokenIds IDs of NFTs to mint
     */
    function mintSpecificTokensToOneRecipient(address recipient, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 *      Openzeppelin contract slightly modified by ishan@ highlight.xyz to be upgradeable.
 */
abstract contract ERC2771ContextUpgradeable is Initializable {
    address private _trustedForwarder;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function __ERC2771ContextUpgradeable__init__(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /* solhint-disable no-inline-assembly */
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            /* solhint-enable no-inline-assembly */
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title MintManager interface for onchain abridged mint vectors
 * @author highlight.xyz
 */
interface IAbridgedMintVector {
    /**
     * @notice On-chain mint vector (stored data)
     * @param contractAddress NFT smart contract address
     * @param startTimestamp When minting opens on vector
     * @param endTimestamp When minting ends on vector
     * @param paymentRecipient Payment recipient
     * @param maxTotalClaimableViaVector Max number of tokens that can be minted via vector
     * @param totalClaimedViaVector Total number of tokens minted via vector
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param tokenLimitPerTx Max number of tokens that can be minted in one transaction
     * @param maxUserClaimableViaVector Max number of tokens that can be minted by user via vector
     * @param pricePerToken Price that has to be paid per minted token
     * @param editionId Edition ID, if vector is for edition based collection
     * @param editionBasedCollection If vector is for an edition based collection
     * @param requireDirectEOA Require minters to directly be EOAs
     * @param allowlistRoot Root of merkle tree with allowlist
     */
    struct AbridgedVectorData {
        uint160 contractAddress;
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint160 paymentRecipient;
        uint48 maxTotalClaimableViaVector;
        uint48 totalClaimedViaVector;
        uint160 currency;
        uint48 tokenLimitPerTx;
        uint48 maxUserClaimableViaVector;
        uint192 pricePerToken;
        uint48 editionId;
        bool editionBasedCollection;
        bool requireDirectEOA;
        bytes32 allowlistRoot;
    }

    /**
     * @notice On-chain mint vector (public) - See {AbridgedVectorData}
     */
    struct AbridgedVector {
        address contractAddress;
        uint48 startTimestamp;
        uint48 endTimestamp;
        address paymentRecipient;
        uint48 maxTotalClaimableViaVector;
        uint48 totalClaimedViaVector;
        address currency;
        uint48 tokenLimitPerTx;
        uint48 maxUserClaimableViaVector;
        uint192 pricePerToken;
        uint48 editionId;
        bool editionBasedCollection;
        bool requireDirectEOA;
        bytes32 allowlistRoot;
    }

    /**
     * @notice Config defining what fields to update
     * @param updateStartTimestamp If 1, update startTimestamp
     * @param updateEndTimestamp If 1, update endTimestamp
     * @param updatePaymentRecipient If 1, update paymentRecipient
     * @param updateMaxTotalClaimableViaVector If 1, update maxTotalClaimableViaVector
     * @param updateTokenLimitPerTx If 1, update tokenLimitPerTx
     * @param updateMaxUserClaimableViaVector If 1, update maxUserClaimableViaVector
     * @param updatePricePerToken If 1, update pricePerToken
     * @param updateCurrency If 1, update currency
     * @param updateRequireDirectEOA If 1, update requireDirectEOA
     * @param updateMetadata If 1, update MintVector metadata
     */
    struct UpdateAbridgedVectorConfig {
        uint16 updateStartTimestamp;
        uint16 updateEndTimestamp;
        uint16 updatePaymentRecipient;
        uint16 updateMaxTotalClaimableViaVector;
        uint16 updateTokenLimitPerTx;
        uint16 updateMaxUserClaimableViaVector;
        uint8 updatePricePerToken;
        uint8 updateCurrency;
        uint8 updateRequireDirectEOA;
        uint8 updateMetadata;
    }

    /**
     * @notice Creates on-chain vector
     * @param _vector Vector to create
     */
    function createAbridgedVector(AbridgedVectorData memory _vector) external;

    /**
     * @notice Updates on-chain vector
     * @param vectorId ID of vector to update
     * @param _newVector New vector details
     * @param updateConfig Number encoding what fields to update
     * @param pause Pause / unpause vector
     * @param flexibleData Flexible data in vector metadata
     */
    function updateAbridgedVector(
        uint256 vectorId,
        AbridgedVector calldata _newVector,
        UpdateAbridgedVectorConfig calldata updateConfig,
        bool pause,
        uint128 flexibleData
    ) external;

    /**
     * @notice Pauses or unpauses an on-chain mint vector
     * @param vectorId ID of abridged vector to pause
     * @param pause True to pause, False to unpause
     * @param flexibleData Flexible data that can be interpreted differently
     */
    function setAbridgedVectorMetadata(uint256 vectorId, bool pause, uint128 flexibleData) external;

    /**
     * @notice Get on-chain abridged vector
     * @param vectorId ID of abridged vector to get
     */
    function getAbridgedVector(uint256 vectorId) external view returns (AbridgedVector memory);

    /**
     * @notice Get on-chain abridged vector metadata
     * @param vectorId ID of abridged vector to get
     */
    function getAbridgedVectorMetadata(uint256 vectorId) external view returns (bool, uint128);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title MintManager interface for a mint fee oracle
 * @author highlight.xyz
 */
interface IMintFeeOracle {
    /**
     * @notice Process the mint fee for a classic mv
     * @param vectorId Vector ID
     * @param payoutCreatorReward Payout creator reward
     * @param vectorPaymentRecipient Vector payment recipient
     * @param currency Mint fee currency currency
     * @param amount Sale amount
     * @param minter Minter address
     */
    function processClassicVectorMintFeeCap(
        bytes32 vectorId,
        bool payoutCreatorReward,
        address vectorPaymentRecipient,
        address currency,
        uint256 amount,
        address minter
    ) external payable returns (uint256);

    /**
     * @notice Get the mint fee cap for a classic mv
     * @param vectorId Vector ID (bytes32)
     * @param numToMint Number of tokens to mint in this transaction
     * @param minter Minter address
     * @param currency Sale currency
     */
    function getClassicVectorMintFeeCap(
        bytes32 vectorId,
        uint256 numToMint,
        address minter,
        address currency
    ) external view returns (uint256);

    /**
     * @notice Get the mint fee for a mechanic mint mv
     * @param vectorId Vector ID
     * @param numToMint Number of tokens to mint in this transaction
     * @param mechanic Address of mechanic facilitating mint
     * @param minter Address minting
     */
    function getMechanicMintFee(
        bytes32 vectorId,
        uint32 numToMint,
        address mechanic,
        address minter
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title NativeMetaTransaction interface. Used by eg. wETH on Polygon
 * @author highlight.xyz
 */
interface INativeMetaTransaction {
    /**
     * @notice Meta-transaction object
     * @param nonce Account nonce
     * @param from Account to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
     * @notice Execute meta transaction on contract containing EIP-712 stuff natively
     * @param userAddress User to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IMechanicData.sol";

/**
 * @notice Interface that mint mechanics are forced to adhere to,
 *         provided they support both collector's choice and sequential minting
 */
interface IMechanic is IMechanicData {
    /**
     * @notice Create a mechanic vector on the mechanic
     * @param mechanicVectorId Global mechanic vector ID
     * @param vectorData Mechanic vector data
     */
    function createVector(bytes32 mechanicVectorId, bytes calldata vectorData) external;

    /**
     * @notice Process a sequential mint
     * @param mechanicVectorId Global ID identifying mint vector, using this mechanic
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     * @param minter Account that called mint on the MintManager
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processNumMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        address minter,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable;

    /**
     * @notice Process a collector's choice mint
     * @param mechanicVectorId Global ID identifying mint vector, using this mechanic
     * @param recipient Mint recipient
     * @param tokenIds IDs of tokens to mint
     * @param minter Account that called mint on the MintManager
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processChooseMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        address minter,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Defines a mechanic's metadata on the MintManager
 */
interface IMechanicData {
    /**
     * @notice A mechanic's metadata
     * @param contractAddress Collection contract address
     * @param editionId Edition ID if the collection is edition based
     * @param mechanic Address of mint mechanic contract
     * @param isEditionBased True if collection is edition based
     * @param isChoose True if collection uses a collector's choice mint paradigm
     * @param paused True if mechanic vector is paused
     */
    struct MechanicVectorMetadata {
        address contractAddress;
        uint96 editionId;
        address mechanic;
        bool isEditionBased;
        bool isChoose;
        bool paused;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IMechanicData.sol";

/**
 * @notice Capabilities on MintManager pertaining to mechanics
 */
interface IMechanicMintManager is IMechanicData {
    /**
     * @notice Register a new mechanic vector
     * @param _mechanicVectorMetadata Mechanic vector metadata
     * @param seed Used to seed uniqueness into mechanic vector ID generation
     * @param vectorData Vector data to store on mechanic (optional)
     */
    function registerMechanicVector(
        MechanicVectorMetadata calldata _mechanicVectorMetadata,
        uint96 seed,
        bytes calldata vectorData
    ) external;

    /**
     * @notice Pause or unpause a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param pause If true, pause the mechanic mint vector. If false, unpause
     */
    function setPauseOnMechanicMintVector(bytes32 mechanicVectorId, bool pause) external;

    /**
     * @notice Mint a number of tokens sequentially via a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     * @param data Custom data to be processed by mechanic
     */
    function mechanicMintNum(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        bytes calldata data
    ) external payable;

    /**
     * @notice Mint a specific set of token ids via a mechanic vector
     * @param mechanicVectorId Global mechanic ID
     * @param recipient Mint recipient
     * @param tokenIds IDs of tokens to mint
     * @param data Custom data to be processed by mechanic
     */
    function mechanicMintChoose(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../erc721/interfaces/IERC721GeneralMint.sol";
import "../erc721/interfaces/IERC721EditionMint.sol";
import "../utils/ERC721/IERC721.sol";
import "./interfaces/INativeMetaTransaction.sol";
import "../utils/EIP712Upgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";
import "./interfaces/IAbridgedMintVector.sol";
import "./interfaces/IMintFeeOracle.sol";
import "./mechanics/interfaces/IMechanicMintManager.sol";
import "./mechanics/interfaces/IMechanic.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintManager
 * @author highlight.xyz
 * @notice Faciliates lion's share of minting in Highlight protocol V2 by managing mint "vectors" on-chain and off-chain
 */
contract MintManager is
    EIP712Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    IAbridgedMintVector,
    IMechanicMintManager
{
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Throw when sender is unauthorized to complete action
     */
    error Unauthorized();

    /**
     * @notice Throw when the executor being added or removed is invalid
     */
    error InvalidExecutorChanged();

    /**
     * @notice Throw when the action being applied to the vector has been frozen
     */
    error VectorUpdateActionFrozen();

    /**
     * @notice Throw when the totalClaimedViaVector passed in is invalid
     */
    error InvalidTotalClaimed();

    /**
     * @notice Throw when an invalid allowlist proof is used, or a regular mint is attempted on an allowlist vector
     */
    error AllowlistInvalid();

    /**
     * @notice Throw when a native gas token payment is attempted on a payment packet mint
     */
    error CurrencyTypeInvalid();

    /**
     * @notice Throw when the mint fee sent is too low
     */
    error MintFeeTooLow();

    /**
     * @notice Throw when an internal transfer of ether fails
     */
    error EtherSendFailed();

    /**
     * @notice Throw when a transaction signer is not the claimer passed in via a claim
     */
    error SenderNotClaimer();

    /**
     * @notice Throw when a claim is invalid
     */
    error InvalidClaim();

    /**
     * @notice Throw when an invalid amount is sent for a payment (native gas token or erc20)
     */
    error InvalidPaymentAmount();

    /**
     * @notice Throw when an on-chain mint vector's config parameter isn't met
     */
    error OnchainVectorMintGuardFailed();

    /**
     * @notice Throw when a mint is tried on a vector of the
     *         wrong collection type (edition -> series, series -> edition)
     */
    error VectorWrongCollectionType();

    /**
     * @notice Throw when msgSender is not directly an EOA
     */
    error SenderNotDirectEOA();

    /**
     * @notice Throw when a mint recipient on a gated claim is different from the claimer,
     *         and tx sender is not the claimer
     */
    error UnsafeMintRecipient();

    /**
     * @notice Throw when a mint is paused.
     */
    error MintPaused();

    /**
     * @notice Throw when an entity is already registered with a given ID
     */
    error AlreadyRegisteredWithId();

    /**
     * @notice Throw when a mechanic is invalid
     */
    error InvalidMechanic();

    /**
     * @notice Throw when a mechanic is paused
     */
    error MechanicPaused();

    /**
     * @notice On-chain mint vector
     * @param contractAddress NFT smart contract address
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param paymentRecipient Payment recipient
     * @param startTimestamp When minting opens on vector
     * @param endTimestamp When minting ends on vector
     * @param pricePerToken Price that has to be paid per minted token
     * @param tokenLimitPerTx Max number of tokens that can be minted in one transaction
     * @param maxTotalClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxUserClaimableViaVector Max number of tokens that can be minted by user via vector
     * @param totalClaimedViaVector Total number of tokens minted via vector
     * @param allowlistRoot Root of merkle tree with allowlist
     * @param paused If vector is paused
     */
    struct Vector {
        address contractAddress;
        address currency;
        address payable paymentRecipient;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 pricePerToken;
        uint64 tokenLimitPerTx;
        uint64 maxTotalClaimableViaVector;
        uint64 maxUserClaimableViaVector;
        uint64 totalClaimedViaVector;
        bytes32 allowlistRoot;
        uint8 paused;
    }

    /**
     * @notice On-chain mint vector mutability rules
     * @param updatesFrozen If true, vector cannot be updated
     * @param deleteFrozen If true, vector cannot be deleted
     * @param pausesFrozen If true, vector cannot be paused
     */
    struct VectorMutability {
        uint8 updatesFrozen;
        uint8 deleteFrozen;
        uint8 pausesFrozen;
    }

    /**
     * @notice Packet enabling impersonation of purchaser for currencies supporting meta-transactions
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    struct PurchaserMetaTxPacket {
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    /**
     * @notice Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param numTokensToMint Number of NFTs to mint in this transaction
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param editionId ID of edition to mint on. Unused if claim is passed into ERC721General minting function
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct Claim {
        address currency;
        address contractAddress;
        address claimer;
        address payable paymentRecipient;
        uint256 pricePerToken;
        uint64 numTokensToMint;
        uint256 maxClaimableViaVector;
        uint256 maxClaimablePerUser;
        uint256 editionId;
        uint256 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @notice Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint on a Series
     * @dev Max number claimable per transaction is enforced off-chain
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param maxPerTxn Max number of tokens that can be minted in a transaction
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct SeriesClaim {
        address currency;
        address contractAddress;
        address claimer;
        address payable paymentRecipient;
        uint256 pricePerToken;
        uint64 maxPerTxn;
        uint64 maxClaimableViaVector;
        uint64 maxClaimablePerUser;
        uint64 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @notice Tracks current claim state of offchain vectors
     * @param numClaimed Total claimed on vector
     * @param numClaimedPerUser Tracks totals claimed per user on vector
     */
    struct OffchainVectorClaimState {
        uint256 numClaimed;
        mapping(address => uint256) numClaimedPerUser;
    }

    /* solhint-disable max-line-length */
    /**
     * @notice DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_TYPEHASH =
        keccak256(
            "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /**
     * @notice DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_WITH_META_TX_PACKET_TYPEHASH =
        keccak256(
            "ClaimWithMetaTxPacket(address currency,address contractAddress,address claimer,uint256 pricePerToken,uint64 numTokensToMint,PurchaserMetaTxPacket purchaseToCreatorPacket,PurchaserMetaTxPacket purchaseToCreatorPacket,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /* solhint-enable max-line-length */

    /**
     * @notice Platform receiving portion of payment
     */
    address payable private _platform;

    /**
     * @notice System-wide mint vectors
     */
    mapping(uint256 => Vector) public vectors;

    /**
     * @notice System-wide mint vectors' mutabilities
     */
    mapping(uint256 => VectorMutability) public vectorMutabilities;

    /**
     * @notice System-wide vector ids to (user to user claims count)
     */
    mapping(uint256 => mapping(address => uint64)) public userClaims;

    /**
     * @notice Tracks what nonces used in signed mint keys have been used for vectors enforced offchain
     *      Requires the platform to not re-use offchain vector IDs.
     */
    mapping(bytes32 => EnumerableSet.Bytes32Set) private _offchainVectorsToNoncesUsed;

    /**
     * @notice Tracks running state of offchain vectors
     */
    mapping(bytes32 => OffchainVectorClaimState) public offchainVectorsClaimState;

    /**
     * @notice Maps vector ids to edition ids
     */
    mapping(uint256 => uint256) public vectorToEditionId;

    /**
     * @notice Current vector id index
     */
    uint256 private _vectorSupply;

    /**
     * @notice Platform transaction executors
     */
    EnumerableSet.AddressSet internal _platformExecutors;

    /**
     * @notice Platform mint fee
     */
    uint256 private _platformMintFee;

    /**
     * @notice System-wide mint vectors
     */
    mapping(uint256 => AbridgedVectorData) private _abridgedVectors;

    /**
     * @notice Extra data about an abridged mint vector
     * Bits Layout:
     * - [0] `paused`
     * - [1..127] `unused` (for now)
     * - [128..255] `flexible data`
     */
    mapping(uint256 => uint256) private _abridgedVectorMetadata;

    /**
     @notice The bit position of `flexibleData` in packed abridged vector metadata.
     */
    uint256 private constant _BITPOS_AV_FLEXIBLE_DATA = 128;

    /**
     @notice The bitmask of `paused` in packed abridged vector metadata.
     */
    uint256 private constant _BITMASK_AV_PAUSED = 1;

    /**
     * @notice Global mechanic vector metadatas
     */
    mapping(bytes32 => MechanicVectorMetadata) public mechanicVectorMetadata;

    /**
     * @notice Mint fee oracle
     */
    address private _mintFeeOracle;

    /**
     * @notice Gasless mechanic address
     */
    address private _gaslessMechanicAddress;

    /**
     * @notice Emitted when platform executor is added or removed
     * @param executor Changed executor
     * @param added True if executor was added and false otherwise
     */
    event PlatformExecutorChanged(address indexed executor, bool indexed added);

    /**
     * @notice Emitted when vector for edition based colletction is created on-chain
     * @param vectorId ID of vector
     * @param editionId Edition id of vector
     * @param contractAddress Collection contract address
     */
    event EditionVectorCreated(uint256 indexed vectorId, uint48 indexed editionId, address indexed contractAddress);

    /**
     * @notice Emitted when vector for series based collection is created on-chain
     * @param vectorId ID of vector
     * @param contractAddress Collection contract address
     */
    event SeriesVectorCreated(uint256 indexed vectorId, address indexed contractAddress);

    /**
     * @notice Emitted when vector is updated on-chain
     * @param vectorId ID of vector
     */
    event VectorUpdated(uint256 indexed vectorId);

    /**
     * @notice Emitted when vector is deleted on-chain
     * @param vectorId ID of vector to delete
     */
    event VectorDeleted(uint256 indexed vectorId);

    /**
     * @notice Emitted when vector metadata is set
     * @param vectorId ID of vector
     * @param paused True if vector was paused, false otherwise
     * @param flexibleData Flexible data set in a vector's metadata
     */
    event VectorMetadataSet(uint256 indexed vectorId, bool indexed paused, uint128 indexed flexibleData);

    /**
     * @notice Emitted when payment is made in native gas token
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event NativeGasTokenPayment(
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @notice Emitted when payment is made in ERC20
     * @param currency ERC20 currency
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param payer Payer
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event ERC20Payment(
        address indexed currency,
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        address payer,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @notice Emitted on a mint where discrete token ids are minted
     * @param vectorId Vector that payment was for
     * @param contractAddress Address of contract being minted on
     * @param onChainVector Denotes whether mint vector is on-chain
     * @param tokenIds Array of token ids to mint
     */
    event ChooseTokenMint(
        bytes32 indexed vectorId,
        address indexed contractAddress,
        bool indexed onChainVector,
        uint256[] tokenIds
    );

    /**
     * @notice Emitted on a mint where a number of tokens are minted monotonically
     * @param vectorId Vector that payment was for
     * @param contractAddress Address of contract being minted on
     * @param onChainVector Denotes whether mint vector is on-chain
     * @param numMinted Number of tokens minted
     */
    event NumTokenMint(
        bytes32 indexed vectorId,
        address indexed contractAddress,
        bool indexed onChainVector,
        uint256 numMinted
    );

    /**
     * @notice Emitted on a mint where a number of tokens are minted monotonically by the owner
     * @param contractAddress Address of contract being minted on
     * @param isEditionBased Denotes whether collection is edition-based
     * @param editionId Edition ID, if applicable
     * @param numMinted Number of tokens minted
     */
    event CreatorReservesNumMint(
        address indexed contractAddress,
        bool indexed isEditionBased,
        uint256 indexed editionId,
        uint256 numMinted
    );

    /**
     * @notice Emitted on a mint where a number of tokens are minted monotonically by the owner
     * @param contractAddress Address of contract being minted on
     * @param tokenIds IDs of tokens minted
     */
    event CreatorReservesChooseMint(address indexed contractAddress, uint256[] tokenIds);

    /**
     * @notice Emitted when a mechanic vector is registered
     * @param mechanicVectorId Global mechanic vector ID
     * @param mechanic Mechanic's address
     * @param contractAddress Address of collection the mechanic is minting on
     * @param editionId ID of edition, if applicable
     * @param isEditionBased If true, edition based
     */
    event MechanicVectorRegistered(
        bytes32 indexed mechanicVectorId,
        address indexed mechanic,
        address indexed contractAddress,
        uint256 editionId,
        bool isEditionBased
    );

    /**
     * @notice Emitted when a mechanic vector's pause state is toggled
     * @param mechanicVectorId Global mechanic vector ID
     * @param paused If true, mechanic was paused. If false, mechanic was unpaused
     */
    event MechanicVectorPauseSet(bytes32 indexed mechanicVectorId, bool indexed paused);

    /**
     * @notice Emitted when the platform mint fee is updated
     * @param newPlatformMintFee New platform mint fee
     */
    event PlatformMintFeeUpdated(uint256 indexed newPlatformMintFee);

    /**
     * @notice Emit when creator is paid out
     * @param currency Currency creator reward is in
     * @param rewardRecipient Creator reward recipient
     * @param amount Amount of payout
     */
    event CreatorRewardPayout(
        bytes32 indexed vectorId,
        address indexed currency,
        address indexed rewardRecipient,
        uint256 amount
    );

    /**
     * @notice Restricts calls to platform
     */
    modifier onlyPlatform() {
        if (_msgSender() != _platform) {
            _revert(Unauthorized.selector);
        }
        _;
    }

    /**
     * @notice Initializes MintManager
     * @param platform Platform address
     * @param _owner MintManager owner
     * @param trustedForwarder Trusted meta-tx executor
     * @param initialExecutor Initial platform executor
     * @param initialPlatformMintFee Initial platform mint fee
     */
    function initialize(
        address payable platform,
        address _owner,
        address trustedForwarder,
        address initialExecutor,
        uint256 initialPlatformMintFee
    ) external initializer {
        _platform = platform;
        __EIP721Upgradeable_initialize("MintManager", "1.0.0");
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        __Ownable_init();
        _transferOwnership(_owner);
        _platformExecutors.add(initialExecutor);
        _platformMintFee = initialPlatformMintFee;
    }

    /**
     * @notice Add or deprecate platform executor
     * @param _executor Platform executor to add or deprecate
     */
    function addOrDeprecatePlatformExecutor(address _executor) external onlyOwner {
        if (_executor == address(0)) {
            _revert(InvalidExecutorChanged.selector);
        }
        if (_platformExecutors.contains(_executor)) {
            // remove exeuctor
            _platformExecutors.remove(_executor);
        } else {
            // add executor
            _platformExecutors.add(_executor);
        }
    }

    /**
     * @notice See {IAbridgedMintVector-createAbridgedVector}
     */
    function createAbridgedVector(AbridgedVectorData calldata _vector) external {
        address msgSender = _msgSender();

        if (
            address(_vector.contractAddress) == msgSender ||
            Ownable(address(_vector.contractAddress)).owner() == msgSender
        ) {
            if (_vector.totalClaimedViaVector > 0) {
                _revert(InvalidTotalClaimed.selector);
            }

            _vectorSupply++;

            _abridgedVectors[_vectorSupply] = _vector;

            if (_vector.editionBasedCollection) {
                emit EditionVectorCreated(_vectorSupply, _vector.editionId, address(_vector.contractAddress));
            } else {
                emit SeriesVectorCreated(_vectorSupply, address(_vector.contractAddress));
            }
        } else {
            _revert(Unauthorized.selector);
        }
    }

    /* solhint-disable code-complexity */
    /**
     * @notice See {IAbridgedMintVector-updateAbridgedVector}
     */
    function updateAbridgedVector(
        uint256 vectorId,
        AbridgedVector calldata _newVector,
        UpdateAbridgedVectorConfig calldata updateConfig,
        bool pause,
        uint128 flexibleData
    ) external {
        address contractAddress = address(_abridgedVectors[vectorId].contractAddress);
        address msgSender = _msgSender();
        // check owner() first, more likely
        if (Ownable(contractAddress).owner() == msgSender || msgSender == contractAddress) {
            if (updateConfig.updateStartTimestamp > 0) {
                _abridgedVectors[vectorId].startTimestamp = _newVector.startTimestamp;
            }
            if (updateConfig.updateEndTimestamp > 0) {
                _abridgedVectors[vectorId].endTimestamp = _newVector.endTimestamp;
            }
            if (updateConfig.updatePaymentRecipient > 0) {
                _abridgedVectors[vectorId].paymentRecipient = uint160(_newVector.paymentRecipient);
            }
            if (updateConfig.updateMaxTotalClaimableViaVector > 0) {
                _abridgedVectors[vectorId].maxTotalClaimableViaVector = _newVector.maxTotalClaimableViaVector;
            }
            if (updateConfig.updateTokenLimitPerTx > 0) {
                _abridgedVectors[vectorId].tokenLimitPerTx = _newVector.tokenLimitPerTx;
            }
            if (updateConfig.updateMaxUserClaimableViaVector > 0) {
                _abridgedVectors[vectorId].maxUserClaimableViaVector = _newVector.maxUserClaimableViaVector;
            }
            if (updateConfig.updatePricePerToken > 0) {
                _abridgedVectors[vectorId].pricePerToken = _newVector.pricePerToken;
            }
            if (updateConfig.updateCurrency > 0) {
                _abridgedVectors[vectorId].currency = uint160(_newVector.currency);
            }
            if (updateConfig.updateRequireDirectEOA > 0) {
                _abridgedVectors[vectorId].requireDirectEOA = _newVector.requireDirectEOA;
            }
            if (updateConfig.updateMetadata > 0) {
                _abridgedVectorMetadata[vectorId] = _composeAbridgedVectorMetadata(pause, flexibleData);

                emit VectorMetadataSet(vectorId, pause, flexibleData);
            }

            emit VectorUpdated(vectorId);
        } else {
            _revert(Unauthorized.selector);
        }
    }

    /* solhint-enable code-complexity */

    /**
     * @notice See {IAbridgedMintVector-setAbridgedVectorMetadata}
     */
    function setAbridgedVectorMetadata(uint256 vectorId, bool pause, uint128 flexibleData) external {
        address contractAddress = address(_abridgedVectors[vectorId].contractAddress);
        address msgSender = _msgSender();
        // check .owner() first, more likely
        if (Ownable(contractAddress).owner() == msgSender || msgSender == contractAddress) {
            _abridgedVectorMetadata[vectorId] = _composeAbridgedVectorMetadata(pause, flexibleData);

            emit VectorMetadataSet(vectorId, pause, flexibleData);
        } else {
            _revert(Unauthorized.selector);
        }
    }

    /**
     * @notice See {IMechanicMintManager-registerMechanicVector}
     */
    function registerMechanicVector(
        MechanicVectorMetadata memory _mechanicVectorMetadata,
        uint96 seed,
        bytes calldata vectorData
    ) external {
        address msgSender = _msgSender();
        bytes32 mechanicVectorId = _produceMechanicVectorId(_mechanicVectorMetadata, seed);
        if (
            msgSender == _mechanicVectorMetadata.contractAddress ||
            Ownable(_mechanicVectorMetadata.contractAddress).owner() == msgSender
        ) {
            if (mechanicVectorMetadata[mechanicVectorId].contractAddress != address(0)) {
                _revert(AlreadyRegisteredWithId.selector);
            }
            if (
                _mechanicVectorMetadata.contractAddress == address(0) ||
                _mechanicVectorMetadata.mechanic == address(0) ||
                (_mechanicVectorMetadata.isEditionBased && _mechanicVectorMetadata.isChoose) ||
                mechanicVectorId == bytes32(0)
            ) {
                _revert(InvalidMechanic.selector);
            }
            _mechanicVectorMetadata.paused = false;
            mechanicVectorMetadata[mechanicVectorId] = _mechanicVectorMetadata;
        } else {
            _revert(Unauthorized.selector);
        }

        IMechanic(_mechanicVectorMetadata.mechanic).createVector(mechanicVectorId, vectorData);

        emit MechanicVectorRegistered(
            mechanicVectorId,
            _mechanicVectorMetadata.mechanic,
            _mechanicVectorMetadata.contractAddress,
            _mechanicVectorMetadata.editionId,
            _mechanicVectorMetadata.isEditionBased
        );
    }

    /**
     * @notice See {IMechanicMintManager-setPauseOnMechanicMintVector}
     */
    function setPauseOnMechanicMintVector(bytes32 mechanicVectorId, bool pause) external {
        address msgSender = _msgSender();
        address contractAddress = mechanicVectorMetadata[mechanicVectorId].contractAddress;
        if (contractAddress == address(0)) {
            _revert(InvalidMechanic.selector);
        }

        if (Ownable(contractAddress).owner() == msgSender || msgSender == contractAddress) {
            mechanicVectorMetadata[mechanicVectorId].paused = pause;
        } else {
            _revert(Unauthorized.selector);
        }

        emit MechanicVectorPauseSet(mechanicVectorId, pause);
    }

    /* solhint-disable code-complexity */
    /**
     * @notice See {IMechanicMintManager-mechanicMintNum}
     */
    function mechanicMintNum(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        bytes memory data
    ) external payable {
        MechanicVectorMetadata memory _mechanicVectorMetadata = mechanicVectorMetadata[mechanicVectorId];
        address msgSender = _msgSender();

        if (_mechanicVectorMetadata.paused) {
            _revert(MechanicPaused.selector);
        }
        if (_mechanicVectorMetadata.isChoose) {
            _revert(InvalidMechanic.selector);
        }

        uint256 _platformFee = 0;
        // constant gasless mechanic address
        if (_mechanicVectorMetadata.mechanic == _gaslessMechanicAddress) {
            uint256 fee;
            address feeCollector;
            assembly {
                fee := calldataload(sub(calldatasize(), 32))
                feeCollector := shr(96, calldataload(sub(calldatasize(), 72)))
            }

            data = abi.encode(fee, feeCollector, data);
        } else {
            _platformFee = IMintFeeOracle(_mintFeeOracle).getMechanicMintFee(
                mechanicVectorId,
                numToMint,
                _mechanicVectorMetadata.mechanic,
                msgSender
            );
            if (msg.value < _platformFee) {
                _revert(MintFeeTooLow.selector);
            }
        }

        IMechanic(_mechanicVectorMetadata.mechanic).processNumMint{ value: msg.value - _platformFee }(
            mechanicVectorId,
            recipient,
            numToMint,
            msgSender,
            _mechanicVectorMetadata,
            data
        );

        if (_mechanicVectorMetadata.isEditionBased) {
            if (numToMint == 1) {
                IERC721EditionMint(_mechanicVectorMetadata.contractAddress).mintOneToRecipient(
                    _mechanicVectorMetadata.editionId,
                    recipient
                );
            } else {
                IERC721EditionMint(_mechanicVectorMetadata.contractAddress).mintAmountToRecipient(
                    _mechanicVectorMetadata.editionId,
                    recipient,
                    uint256(numToMint)
                );
            }
        } else {
            if (numToMint == 1) {
                IERC721GeneralMint(_mechanicVectorMetadata.contractAddress).mintOneToOneRecipient(recipient);
            } else {
                IERC721GeneralMint(_mechanicVectorMetadata.contractAddress).mintAmountToOneRecipient(
                    recipient,
                    uint256(numToMint)
                );
            }
        }

        emit NumTokenMint(mechanicVectorId, _mechanicVectorMetadata.contractAddress, true, uint256(numToMint));
    }

    /**
     * @notice See {IMechanicMintManager-mechanicMintChoose}
     */
    function mechanicMintChoose(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        bytes memory data
    ) external payable {
        MechanicVectorMetadata memory _mechanicVectorMetadata = mechanicVectorMetadata[mechanicVectorId];
        address msgSender = _msgSender();

        if (_mechanicVectorMetadata.paused) {
            _revert(MechanicPaused.selector);
        }
        if (!_mechanicVectorMetadata.isChoose) {
            _revert(InvalidMechanic.selector);
        }
        uint32 numToMint = uint32(tokenIds.length);
        uint256 _platformFee = IMintFeeOracle(_mintFeeOracle).getMechanicMintFee(
            mechanicVectorId,
            numToMint,
            _mechanicVectorMetadata.mechanic,
            msgSender
        );
        if (msg.value < _platformFee) {
            _revert(MintFeeTooLow.selector);
        }

        // send value without amount needed for mint fee
        IMechanic(_mechanicVectorMetadata.mechanic).processChooseMint{ value: msg.value - _platformFee }(
            mechanicVectorId,
            recipient,
            tokenIds,
            msgSender,
            _mechanicVectorMetadata,
            data
        );

        if (numToMint == 1) {
            IERC721GeneralMint(_mechanicVectorMetadata.contractAddress).mintSpecificTokenToOneRecipient(
                recipient,
                tokenIds[0]
            );
        } else {
            IERC721GeneralMint(_mechanicVectorMetadata.contractAddress).mintSpecificTokensToOneRecipient(
                recipient,
                tokenIds
            );
        }

        emit ChooseTokenMint(mechanicVectorId, _mechanicVectorMetadata.contractAddress, true, tokenIds);
    }

    /* solhint-disable code-complexity */

    /**
     * @notice Let the owner of a collection mint creator reserves
     * @param collection Collection contract address
     * @param isEditionBased If true, collection is edition-based
     * @param editionId Edition ID of collection, if applicable
     * @param numToMint Number of tokens to mint on sequential mints
     * @param tokenIds To reserve mint collector's choice based mints
     * @param isCollectorsChoice If true, mint via collector's choice based paradigm
     * @param recipient Recipient of minted tokens
     */
    function creatorReservesMint(
        address collection,
        bool isEditionBased,
        uint256 editionId,
        uint256 numToMint,
        uint256[] calldata tokenIds,
        bool isCollectorsChoice,
        address recipient
    ) external payable {
        address msgSender = _msgSender();

        uint256 tokenIdsLength = tokenIds.length;
        if (tokenIdsLength > 0) {
            numToMint = tokenIdsLength;
        }

        if (Ownable(collection).owner() == msgSender || msgSender == collection) {
            // platform mint fee deprecated for creator reserves mints
            /*
            uint256 mintFeeAmount = _platformMintFee * numToMint;
            if (mintFeeAmount > msg.value) {
                _revert(InvalidPaymentAmount.selector);
            }
            */

            if (isEditionBased) {
                if (numToMint == 1) {
                    IERC721EditionMint(collection).mintOneToRecipient(editionId, recipient);
                } else {
                    IERC721EditionMint(collection).mintAmountToRecipient(editionId, recipient, numToMint);
                }
            } else {
                if (numToMint == 1) {
                    if (isCollectorsChoice) {
                        IERC721GeneralMint(collection).mintSpecificTokenToOneRecipient(recipient, tokenIds[0]);
                    } else {
                        IERC721GeneralMint(collection).mintOneToOneRecipient(recipient);
                    }
                } else {
                    if (isCollectorsChoice) {
                        IERC721GeneralMint(collection).mintSpecificTokensToOneRecipient(recipient, tokenIds);
                    } else {
                        IERC721GeneralMint(collection).mintAmountToOneRecipient(recipient, numToMint);
                    }
                }
            }

            if (isCollectorsChoice) {
                emit CreatorReservesChooseMint(collection, tokenIds);
            } else {
                emit CreatorReservesNumMint(collection, isEditionBased, editionId, numToMint);
            }
        } else {
            _revert(Unauthorized.selector);
        }
    }

    /* solhint-enable code-complexity */

    /**
     * @notice Mint on a Series with a valid claim where one can choose the tokens to mint
     * @param claim Series Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to.
     *                      Can't mint to different recipient if tx isn't sent by claim.claimer.
     * @param tokenIds IDs of NFTs to mint
     */
    function gatedSeriesMintChooseToken(
        SeriesClaim calldata claim,
        bytes calldata claimSignature,
        address mintRecipient,
        uint256[] calldata tokenIds
    ) external payable {
        address msgSender = _msgSender();
        uint256 numTokensToMint = tokenIds.length;
        if (claim.claimer != msgSender && mintRecipient != claim.claimer) {
            _revert(UnsafeMintRecipient.selector);
        }

        _verifyAndUpdateSeriesClaim(claim, claimSignature, numTokensToMint);
        _processClassicVectorPayments(
            claim.offchainVectorId,
            numTokensToMint,
            msgSender,
            claim.currency,
            claim.pricePerToken,
            claim.paymentRecipient
        );
        emit ChooseTokenMint(claim.offchainVectorId, claim.contractAddress, false, tokenIds);

        // mint NFT(s)
        if (numTokensToMint == 1) {
            IERC721GeneralMint(claim.contractAddress).mintSpecificTokenToOneRecipient(mintRecipient, tokenIds[0]);
        } else {
            IERC721GeneralMint(claim.contractAddress).mintSpecificTokensToOneRecipient(mintRecipient, tokenIds);
        }
    }

    /**
     * @notice Mint on a collection with sequentially minted token IDs with a valid claim
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to.
     *                      Can't mint to different recipient if tx isn't sent by claim.claimer.
     */
    function gatedNumMint(
        Claim calldata claim,
        bytes calldata claimSignature,
        address mintRecipient,
        bool isEditionBased
    ) external payable {
        address msgSender = _msgSender();
        if (claim.claimer != msgSender && mintRecipient != claim.claimer) {
            _revert(UnsafeMintRecipient.selector);
        }

        _verifyAndUpdateClaim(claim, claimSignature);
        _processClassicVectorPayments(
            claim.offchainVectorId,
            claim.numTokensToMint,
            msgSender,
            claim.currency,
            claim.pricePerToken,
            claim.paymentRecipient
        );
        emit NumTokenMint(claim.offchainVectorId, claim.contractAddress, false, claim.numTokensToMint);

        if (isEditionBased) {
            if (claim.numTokensToMint == 1) {
                IERC721EditionMint(claim.contractAddress).mintOneToRecipient(claim.editionId, mintRecipient);
            } else {
                IERC721EditionMint(claim.contractAddress).mintAmountToRecipient(
                    claim.editionId,
                    mintRecipient,
                    claim.numTokensToMint
                );
            }
        } else {
            if (claim.numTokensToMint == 1) {
                IERC721GeneralMint(claim.contractAddress).mintOneToOneRecipient(mintRecipient);
            } else {
                IERC721GeneralMint(claim.contractAddress).mintAmountToOneRecipient(
                    mintRecipient,
                    claim.numTokensToMint
                );
            }
        }
    }

    /**
     * @notice Mint via an abridged vector
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function vectorMint721(uint256 vectorId, uint48 numTokensToMint, address mintRecipient) external payable {
        address msgSender = _msgSender();
        address user = mintRecipient;
        if (_useSenderForUserLimit(vectorId)) {
            user = msgSender;
        }

        AbridgedVectorData memory _vector = _abridgedVectors[vectorId];
        uint48 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint48 newNumClaimedForUser = uint48(userClaims[vectorId][user]) + numTokensToMint;

        if (_vector.allowlistRoot != 0) {
            _revert(AllowlistInvalid.selector);
        }
        if (_vector.requireDirectEOA && msgSender != tx.origin) {
            _revert(SenderNotDirectEOA.selector);
        }

        _abridgedVectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][user] = uint64(newNumClaimedForUser);

        if (_vector.editionBasedCollection) {
            _vectorMintEdition721(
                vectorId,
                _vector,
                numTokensToMint,
                mintRecipient,
                msgSender,
                newNumClaimedViaVector,
                newNumClaimedForUser
            );
        } else {
            _vectorMintGeneral721(
                vectorId,
                _vector,
                numTokensToMint,
                mintRecipient,
                msgSender,
                newNumClaimedViaVector,
                newNumClaimedForUser
            );
        }
    }

    /**
     * @notice Withdraw native gas token owed to platform
     */
    function withdrawNativeGasToken(uint256 amountToWithdraw) external onlyPlatform {
        (bool sentToPlatform, bytes memory dataPlatform) = _platform.call{ value: amountToWithdraw }("");
        if (!sentToPlatform) {
            _revert(EtherSendFailed.selector);
        }
    }

    /**
     * @notice Update platform payment address
     */
    function updatePlatformAndMintFeeOracle(
        address payable newPlatform,
        address newOracle,
        address gaslessMechanic
    ) external onlyOwner {
        if (newPlatform == address(0)) {
            _revert(Unauthorized.selector);
        }
        _platform = newPlatform;
        if (_mintFeeOracle != newOracle) {
            _mintFeeOracle = newOracle;
        }
        if (_gaslessMechanicAddress != gaslessMechanic) {
            _gaslessMechanicAddress = gaslessMechanic;
        }
    }

    /**
     * @notice Returns if an address is a platform executor
     */
    function isPlatformExecutor(address _executor) external view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /**
     * @notice Returns number of NFTs minted by user on vector
     * @param vectorId ID of offchain vector
     * @param user Minting user
     */
    function getNumClaimedPerUserOffchainVector(bytes32 vectorId, address user) external view returns (uint256) {
        return offchainVectorsClaimState[vectorId].numClaimedPerUser[user];
    }

    /**
     * @notice Verify that claim and claim signature are valid for a mint
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param expectedMsgSender *DEPRECATED*, keep for interface adherence
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata signature,
        address expectedMsgSender
    ) external view returns (bool) {
        address signer = _claimSigner(claim, signature);

        return
            _platformExecutors.contains(signer) &&
            !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
            block.timestamp <= claim.claimExpiryTimestamp &&
            (claim.maxClaimableViaVector == 0 ||
                claim.numTokensToMint + offchainVectorsClaimState[claim.offchainVectorId].numClaimed <=
                claim.maxClaimableViaVector) &&
            (claim.maxClaimablePerUser == 0 ||
                claim.numTokensToMint +
                    offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[claim.claimer] <=
                claim.maxClaimablePerUser);
    }

    /**
     * @notice Returns if nonce is used for the vector
     * @param vectorId ID of offchain vector
     * @param nonce Nonce being checked
     */
    function isNonceUsed(bytes32 vectorId, bytes32 nonce) external view returns (bool) {
        return _offchainVectorsToNoncesUsed[vectorId].contains(nonce);
    }

    /**
     * @notice See {IAbridgedMintVector-getAbridgedVector}
     */
    function getAbridgedVector(uint256 vectorId) external view returns (AbridgedVector memory) {
        AbridgedVectorData memory data = _abridgedVectors[vectorId];
        return
            AbridgedVector(
                address(data.contractAddress),
                data.startTimestamp,
                data.endTimestamp,
                address(data.paymentRecipient),
                data.maxTotalClaimableViaVector,
                data.totalClaimedViaVector,
                address(data.currency),
                data.tokenLimitPerTx,
                data.maxUserClaimableViaVector,
                data.pricePerToken,
                data.editionId,
                data.editionBasedCollection,
                data.requireDirectEOA,
                data.allowlistRoot
            );
    }

    /**
     * @notice See {IAbridgedMintVector-getAbridgedVectorMetadata}
     */
    function getAbridgedVectorMetadata(uint256 vectorId) external view returns (bool, uint128) {
        return _decomposeAbridgedVectorMetadata(_abridgedVectorMetadata[vectorId]);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice Limit upgrades of contract to MintManager owner
     * @param // New implementation address
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @notice Verify, and update the state of a gated mint claim
     * @param claim Claim
     * @param signature Signed + encoded claim
     */
    function _verifyAndUpdateClaim(Claim calldata claim, bytes calldata signature) private {
        address signer = _claimSigner(claim, signature);

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            claim.numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            claim.claimer
        ] + claim.numTokensToMint;

        if (
            !_platformExecutors.contains(signer) ||
            _offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) ||
            block.timestamp > claim.claimExpiryTimestamp ||
            (expectedNumClaimedViaVector > claim.maxClaimableViaVector && claim.maxClaimableViaVector != 0) ||
            (expectedNumClaimedByUser > claim.maxClaimablePerUser && claim.maxClaimablePerUser != 0)
        ) {
            _revert(InvalidClaim.selector);
        }

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[claim.claimer] = expectedNumClaimedByUser;
    }

    /**
     * @notice Verify, and update the state of a gated series mint claim
     * @param claim Series Claim
     * @param signature Signed + encoded claim
     * @param numTokensToMint How many tokens to mint in this series claim
     */
    function _verifyAndUpdateSeriesClaim(
        SeriesClaim calldata claim,
        bytes calldata signature,
        uint256 numTokensToMint
    ) private {
        address signer = _seriesClaimSigner(claim, signature);

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            claim.claimer
        ] + numTokensToMint;

        if (
            !_platformExecutors.contains(signer) ||
            (numTokensToMint > claim.maxPerTxn && claim.maxPerTxn != 0) ||
            _offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) ||
            block.timestamp > claim.claimExpiryTimestamp ||
            (expectedNumClaimedViaVector > claim.maxClaimableViaVector && claim.maxClaimableViaVector != 0) ||
            (expectedNumClaimedByUser > claim.maxClaimablePerUser && claim.maxClaimablePerUser != 0)
        ) {
            _revert(InvalidClaim.selector);
        }

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[claim.claimer] = expectedNumClaimedByUser;
    }

    /**
     * @notice Process a mint on an on-chain vector
     * @param _vectorId ID of vector being minted on
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of NFTs to mint on vector
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     * @param msgSender Minter
     */
    function _processVectorMint(
        uint256 _vectorId,
        AbridgedVectorData memory _vector,
        uint48 numTokensToMint,
        uint48 newNumClaimedViaVector,
        uint48 newNumClaimedForUser,
        address msgSender
    ) private {
        if (
            (_vector.maxTotalClaimableViaVector < newNumClaimedViaVector && _vector.maxTotalClaimableViaVector != 0) ||
            (_vector.maxUserClaimableViaVector < newNumClaimedForUser && _vector.maxUserClaimableViaVector != 0) ||
            ((_vector.startTimestamp > block.timestamp && _vector.startTimestamp != 0) ||
                (block.timestamp > _vector.endTimestamp && _vector.endTimestamp != 0)) ||
            (numTokensToMint == 0) ||
            (numTokensToMint > _vector.tokenLimitPerTx && _vector.tokenLimitPerTx != 0)
        ) {
            _revert(OnchainVectorMintGuardFailed.selector);
        }

        if (_isVectorPaused(_abridgedVectorMetadata[_vectorId])) {
            _revert(MintPaused.selector);
        }

        _processClassicVectorPayments(
            bytes32(_vectorId),
            uint256(numTokensToMint),
            msgSender,
            address(_vector.currency),
            _vector.pricePerToken,
            payable(address(_vector.paymentRecipient))
        );

        emit NumTokenMint(bytes32(_vectorId), address(_vector.contractAddress), true, numTokensToMint);
    }

    /**
     * @notice Mint on vector pointing to ERC721General collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param msgSender Minter
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintGeneral721(
        uint256 _vectorId,
        AbridgedVectorData memory _vector,
        uint48 numTokensToMint,
        address mintRecipient,
        address msgSender,
        uint48 newNumClaimedViaVector,
        uint48 newNumClaimedForUser
    ) private {
        _processVectorMint(
            _vectorId,
            _vector,
            numTokensToMint,
            newNumClaimedViaVector,
            newNumClaimedForUser,
            msgSender
        );
        if (numTokensToMint == 1) {
            IERC721GeneralMint(address(_vector.contractAddress)).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(address(_vector.contractAddress)).mintAmountToOneRecipient(
                mintRecipient,
                numTokensToMint
            );
        }
    }

    /**
     * @notice Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param msgSender Minter
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintEdition721(
        uint256 _vectorId,
        AbridgedVectorData memory _vector,
        uint48 numTokensToMint,
        address mintRecipient,
        address msgSender,
        uint48 newNumClaimedViaVector,
        uint48 newNumClaimedForUser
    ) private {
        _processVectorMint(
            _vectorId,
            _vector,
            numTokensToMint,
            newNumClaimedViaVector,
            newNumClaimedForUser,
            msgSender
        );
        if (numTokensToMint == 1) {
            IERC721EditionMint(address(_vector.contractAddress)).mintOneToRecipient(_vector.editionId, mintRecipient);
        } else {
            IERC721EditionMint(address(_vector.contractAddress)).mintAmountToRecipient(
                _vector.editionId,
                mintRecipient,
                numTokensToMint
            );
        }
    }

    /**
     * @notice Process payment in native gas token
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processNativeGasTokenPayment(uint256 totalAmount, address payable recipient, bytes32 vectorId) private {
        (bool sentToRecipient, ) = recipient.call{ value: totalAmount }("");
        if (!sentToRecipient) {
            _revert(EtherSendFailed.selector);
        }
        emit NativeGasTokenPayment(recipient, vectorId, totalAmount, 10000);
    }

    /**
     * @notice Process payment in ERC20
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param payer Payer
     * @param currency ERC20 currency
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processERC20Payment(
        uint256 totalAmount,
        address recipient,
        address payer,
        address currency,
        bytes32 vectorId
    ) private {
        IERC20(currency).transferFrom(payer, recipient, totalAmount);
        emit ERC20Payment(currency, recipient, vectorId, payer, totalAmount, 10000);
    }

    /**
     * @notice Recover claim signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimSigner(Claim calldata claim, bytes calldata signature) private view returns (address) {
        return
            _hashTypedDataV4(
                keccak256(bytes.concat(_claimABIEncoded1(claim), _claimABIEncoded2(claim.offchainVectorId)))
            ).recover(signature);
    }

    /**
     * @notice Recover series claim signature signer
     * @param claim Series Claim
     * @param signature Series Claim signature
     */
    function _seriesClaimSigner(SeriesClaim calldata claim, bytes calldata signature) private view returns (address) {
        return _hashTypedDataV4(keccak256(_seriesClaimABIEncoded(claim))).recover(signature);
    }

    /**
     * @dev Understand whether to use the transaction sender or the nft recipient for per-user limits on onchain vectors
     */
    function _useSenderForUserLimit(uint256 mintVectorId) private view returns (bool) {
        return false;
        /*
            ((block.chainid == 1 && mintVectorId < 19) ||
            (block.chainid == 5 && mintVectorId < 188) ||
            (block.chainid == 42161 && mintVectorId < 6) ||
            (block.chainid == 421613 && mintVectorId < 3) ||
            (block.chainid == 84531 && mintVectorId < 14) ||
            (block.chainid == 8453 && mintVectorId < 60) ||
            (block.chainid == 7777777 && mintVectorId < 20) ||
            (block.chainid == 999 && mintVectorId < 10) ||
            (block.chainid == 10 && mintVectorId < 11) ||
            (block.chainid == 420 && mintVectorId < 3) ||
            (block.chainid == 137 && mintVectorId < 7) ||
            (block.chainid == 80001 && mintVectorId < 16));
        */
    }

    /* solhint-disable code-complexity */
    /**
     * @notice Process payments (sale + mint fee) for classic vectors (direct + gated)
     * @param vectorId Vector ID
     * @param numToMint Number of tokens being minted
     * @param msgSender Minter
     * @param currency Sale currency
     * @param salePrice Sale price
     * @param salePaymentRecipient Sale payment recipient
     */
    function _processClassicVectorPayments(
        bytes32 vectorId,
        uint256 numToMint,
        address msgSender,
        address currency,
        uint256 salePrice,
        address payable salePaymentRecipient
    ) private {
        address _oracle = _mintFeeOracle;
        uint256 mintFeeCap = IMintFeeOracle(_oracle).getClassicVectorMintFeeCap(
            vectorId,
            numToMint,
            msgSender,
            currency
        );
        uint256 mintFeeEtherValue = currency == address(0) ? mintFeeCap : 0;
        uint256 saleAmount = numToMint * salePrice;
        if (currency == address(0)) {
            if (mintFeeEtherValue + saleAmount != msg.value) {
                _revert(InvalidPaymentAmount.selector);
            }
            if (saleAmount > 0) {
                // pay in native gas token
                _processNativeGasTokenPayment(saleAmount, salePaymentRecipient, vectorId);
            }
        } else if (saleAmount > 0) {
            // pay in ERC20
            // tx.origin instead of msgSender for referrals
            _processERC20Payment(saleAmount, salePaymentRecipient, tx.origin, currency, vectorId);
        }

        _processClassicVectorMintFee(
            mintFeeCap,
            msgSender,
            currency,
            _oracle,
            salePaymentRecipient,
            vectorId,
            mintFeeEtherValue,
            salePrice == 0
        );
    }

    /**
     * @notice Helper util to process the classic vector mint fee
     */
    function _processClassicVectorMintFee(
        uint256 mintFeeCap,
        address msgSender,
        address currency,
        address _oracle,
        address salePaymentRecipient,
        bytes32 vectorId,
        uint256 mintFeeEtherValue,
        bool isSaleFree
    ) private {
        if (mintFeeCap > 0) {
            if (currency != address(0)) {
                // send erc20 mint fee cap to the mint fee oracle
                // tx.origin instead of msgSender for referrals
                IERC20(currency).transferFrom(tx.origin, _oracle, mintFeeCap);
            }
            uint256 creatorPayout = IMintFeeOracle(_oracle).processClassicVectorMintFeeCap{ value: mintFeeEtherValue }(
                vectorId,
                isSaleFree,
                salePaymentRecipient,
                currency,
                mintFeeCap,
                msgSender
            );
            if (creatorPayout != 0) {
                emit CreatorRewardPayout(vectorId, currency, salePaymentRecipient, creatorPayout);
            }
        }
    }

    /* solhint-enable code-complexity */

    /**
     * @notice Deterministically produce mechanic vector ID from mechanic vector inputs
     * @param metadata Mechanic vector metadata
     * @param seed Used to seed uniqueness
     */
    function _produceMechanicVectorId(
        MechanicVectorMetadata memory metadata,
        uint96 seed
    ) private pure returns (bytes32 mechanicVectorId) {
        mechanicVectorId = keccak256(
            abi.encodePacked(
                metadata.contractAddress,
                metadata.editionId,
                metadata.mechanic,
                metadata.isEditionBased,
                seed
            )
        );
    }

    /* solhint-disable max-line-length */
    /**
     * @notice Get claim typehash
     */
    function _getClaimTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /**
     * @notice Get series claim typehash
     */
    function _getSeriesClaimTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "SeriesClaim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 maxPerTxn,uint64 maxClaimableViaVector,uint64 maxClaimablePerUser,uint64 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /* solhint-enable max-line-length */

    /**
     * @notice Return abi-encoded claim part one
     * @param claim Claim
     */
    function _claimABIEncoded1(Claim calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.paymentRecipient,
                claim.pricePerToken,
                claim.numTokensToMint,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.editionId,
                claim.claimExpiryTimestamp,
                claim.claimNonce
            );
    }

    /**
     * @notice Return abi-encoded series claim part one
     * @param claim SeriesClaim
     */
    function _seriesClaimABIEncoded(SeriesClaim calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getSeriesClaimTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.paymentRecipient,
                claim.pricePerToken,
                claim.maxPerTxn,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.claimExpiryTimestamp,
                claim.claimNonce,
                claim.offchainVectorId
            );
    }

    /**
     * @notice Return abi-encoded claim part two
     * @param offchainVectorId Offchain vector ID of claim
     */
    function _claimABIEncoded2(bytes32 offchainVectorId) private pure returns (bytes memory) {
        return abi.encode(offchainVectorId);
    }

    /**
     * @notice Compose abridged vector metadata into a `uint256`
     * @param paused If the abridged vector is paused
     * @param flexibleData Flexible data
     */
    function _composeAbridgedVectorMetadata(bool paused, uint128 flexibleData) private pure returns (uint256) {
        uint256 metadata = 0;
        if (paused) {
            metadata = metadata | _BITMASK_AV_PAUSED;
        }
        metadata = metadata | (uint256(flexibleData) << 128);

        return metadata;
    }

    /**
     * @notice Decompose abridged vector metadata from a `uint256` into its constituent parts
     * @param packedMetadata Packed abridged vector metadata
     */
    function _decomposeAbridgedVectorMetadata(uint256 packedMetadata) private pure returns (bool, uint128) {
        bool paused = packedMetadata & _BITMASK_AV_PAUSED != 0;
        uint128 flexibleData = uint128(packedMetadata >> _BITPOS_AV_FLEXIBLE_DATA);

        return (paused, flexibleData);
    }

    /**
     * @notice Grab paused status for an onchain abridged mint vector
     * @param packedMetadata Packed abridged vector metadata
     */
    function _isVectorPaused(uint256 packedMetadata) private pure returns (bool) {
        return packedMetadata & _BITMASK_AV_PAUSED != 0;
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) private pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @author OpenZeppelin, modified by highlight.xyz to make compliant to upgradeable contracts
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
 */
/* solhint-disable */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    uint256 private _CACHED_CHAIN_ID;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

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
    function __EIP721Upgradeable_initialize(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        /* solhint-disable max-line-length */
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        /* solhint-enable max-line-length */
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
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
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/* solhint-disable */
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

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
/* solhint-disable */
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