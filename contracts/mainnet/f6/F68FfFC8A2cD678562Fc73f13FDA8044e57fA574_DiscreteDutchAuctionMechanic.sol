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
 * @notice Interfaces with the details of editions on collections
 * @author highlight.xyz
 */
interface IEditionCollection {
    /**
     * @notice Edition details
     * @param name Edition name
     * @param size Edition size
     * @param supply Total number of tokens minted on edition
     * @param initialTokenId Token id of first token minted in edition
     */
    struct EditionDetails {
        string name;
        uint256 size;
        uint256 supply;
        uint256 initialTokenId;
    }

    /**
     * @notice Get the edition a token belongs to
     * @param tokenId The token id of the token
     */
    function getEditionId(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get an edition's details
     * @param editionId Edition id
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory);

    /**
     * @notice Get the details and uris of a number of editions
     * @param editionIds List of editions to get info for
     */
    function getEditionsDetailsAndUri(
        uint256[] calldata editionIds
    ) external view returns (EditionDetails[] memory, string[] memory uris);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Get a Series based collection's supply metadata
 * @author highlight.xyz
 */
interface IERC721GeneralSupplyMetadata {
    /**
     * @notice Get a series based collection's supply, burned tokens notwithstanding
     */
    function supply() external view returns (uint256);

    /**
     * @notice Get a series based collection's total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get a series based collection's supply cap
     */
    function limitSupply() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./MechanicMintManagerClientUpgradeable.sol";
import "../../erc721/interfaces/IEditionCollection.sol";
import "../../erc721/interfaces/IERC721GeneralSupplyMetadata.sol";
import "./PackedPrices.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @notice Highlight's bespoke Dutch Auction mint mechanic (rebates, discrete prices, not continuous)
 * @dev Processes ether based auctions only
 *      DPP = Dynamic Price Period
 *      FPP = Fixed Price Period
 * @author highlight.xyz
 */
contract DiscreteDutchAuctionMechanic is MechanicMintManagerClientUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @notice Throw when an action is unauthorized
     */
    error Unauthorized();

    /**
     * @notice Throw when a vector is attempted to be created or updated with an invalid configuration
     */
    error InvalidVectorConfig();

    /**
     * @notice Throw when a vector is attempted to be updated or deleted at an invalid time
     */
    error InvalidUpdate();

    /**
     * @notice Throw when a vector is already created with a mechanic vector ID
     */
    error VectorAlreadyCreated();

    /**
     * @notice Throw when it is invalid to mint on a vector
     */
    error InvalidMint();

    /**
     * @notice Throw when it is invalid to withdraw funds from a DPP
     */
    error InvalidDPPFundsWithdrawl();

    /**
     * @notice Throw when it is invalid to collect a rebate
     */
    error InvalidRebate();

    /**
     * @notice Throw when a collector isn't owed any rebates
     */
    error CollectorNotOwedRebate();

    /**
     * @notice Throw when the contract fails to send ether to a payment recipient
     */
    error EtherSendFailed();

    /**
     * @notice Throw when the transaction sender has sent an invalid payment amount during a mint
     */
    error InvalidPaymentAmount();

    /**
     * @notice Vector data
     * @dev Guiding uint typing:
     *      log(periodDuration) <= log(timestamps)
     *      log(numTokensBought) <= log(maxUser)
     *      log(numToMint) <= log(numTokensBought)
     *      log(maxUser) <= log(maxTotal)
     *      log(lowestPriceSoldAtIndex) < log(numPrices)
     *      log(prices[i]) <= log(totalSales)
     *      log(totalPosted) <= log(totalSales)
     *      log(prices[i]) <= log(totalPosted)
     *      log(numTokensbought) + log(totalPosted) <= 256
     */
    struct DutchAuctionVector {
        // slot 0
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint32 periodDuration;
        uint32 maxUserClaimableViaVector;
        uint48 maxTotalClaimableViaVector;
        uint48 currentSupply;
        // slot 1
        uint32 lowestPriceSoldAtIndex;
        uint32 tokenLimitPerTx;
        uint32 numPrices;
        address payable paymentRecipient;
        // slot 2
        uint240 totalSales;
        uint8 bytesPerPrice;
        bool auctionExhausted;
        bool payeeRevenueHasBeenWithdrawn;
    }

    /**
     * @notice Config used to control updating of fields in DutchAuctionVector
     */
    struct DutchAuctionVectorUpdateConfig {
        bool updateStartTimestamp;
        bool updateEndTimestamp;
        bool updatePeriodDuration;
        bool updateMaxUserClaimableViaVector;
        bool updateMaxTotalClaimableViaVector;
        bool updateTokenLimitPerTx;
        bool updatePaymentRecipient;
        bool updatePrices;
    }

    /**
     * @notice User purchase info per dutch auction per user
     * @param numTokensBought Number of tokens bought in the dutch auction
     * @param numRebates Number of times the user has requested a rebate
     * @param totalPosted Total amount paid by buyer minus rebates sent
     */
    struct UserPurchaseInfo {
        uint32 numTokensBought;
        uint24 numRebates;
        uint200 totalPosted;
    }

    /**
     * @notice Stores dutch auctions, indexed by global mechanic vector id
     */
    mapping(bytes32 => DutchAuctionVector) private vector;

    /**
     * @notice Stores dutch auction prices (packed), indexed by global mechanic vector id
     */
    mapping(bytes32 => bytes) private vectorPackedPrices;

    /**
     * @notice Stores user purchase info, per user per auction
     */
    mapping(bytes32 => mapping(address => UserPurchaseInfo)) public userPurchaseInfo;

    /**
     * @notice Emitted when a dutch auction is created
     */
    event DiscreteDutchAuctionCreated(bytes32 indexed mechanicVectorId);

    /**
     * @notice Emitted when a dutch auction is updated
     */
    event DiscreteDutchAuctionUpdated(bytes32 indexed mechanicVectorId);

    /**
     * @notice Emitted when a number of tokens are minted via a dutch auction
     */
    event DiscreteDutchAuctionMint(
        bytes32 indexed mechanicVectorId,
        address indexed recipient,
        uint200 pricePerToken,
        uint48 numMinted
    );

    /**
     * @notice Emitted when a collector receives a rebate
     * @param mechanicVectorId Mechanic vector ID
     * @param collector Collector receiving rebate
     * @param rebate The amount of ETH returned to the collector
     * @param currentPricePerNft The current price per NFT at the time of rebate
     */
    event DiscreteDutchAuctionCollectorRebate(
        bytes32 indexed mechanicVectorId,
        address indexed collector,
        uint200 rebate,
        uint200 currentPricePerNft
    );

    /**
     * @notice Emitted when the DPP revenue is withdrawn to the payment recipient once the auction hits the FPP.
     * @dev NOTE - amount of funds withdrawn may include sales from the FPP. After funds are withdrawn, payment goes
     *           straight to the payment recipient on mint
     * @param mechanicVectorId Mechanic vector ID
     * @param paymentRecipient Payment recipient at time of withdrawal
     * @param clearingPrice The final clearing price per NFT
     * @param currentSupply The number of minted tokens to withdraw sales for
     */
    event DiscreteDutchAuctionDPPFundsWithdrawn(
        bytes32 indexed mechanicVectorId,
        address indexed paymentRecipient,
        uint200 clearingPrice,
        uint48 currentSupply
    );

    /**
     * @notice Initialize mechanic contract
     * @param _mintManager Mint manager address
     * @param platform Platform owning the contract
     */
    function initialize(address _mintManager, address platform) external initializer {
        __MechanicMintManagerClientUpgradeable_initialize(_mintManager, platform);
    }

    /**
     * @notice Create a dutch auction vector
     * @param mechanicVectorId Global mechanic vector ID
     * @param vectorData Vector data, to be deserialized into dutch auction vector data
     */
    function createVector(bytes32 mechanicVectorId, bytes memory vectorData) external onlyMintManager {
        // precaution, although MintManager tightly controls creation and prevents double creation
        if (vector[mechanicVectorId].periodDuration != 0) {
            _revert(VectorAlreadyCreated.selector);
        }
        (
            uint48 startTimestamp,
            uint48 endTimestamp,
            uint32 periodDuration,
            uint32 maxUserClaimableViaVector,
            uint48 maxTotalClaimableViaVector,
            uint32 tokenLimitPerTx,
            uint32 numPrices,
            uint8 bytesPerPrice,
            address paymentRecipient,
            bytes memory packedPrices
        ) = abi.decode(vectorData, (uint48, uint48, uint32, uint32, uint48, uint32, uint32, uint8, address, bytes));

        DutchAuctionVector memory _vector = DutchAuctionVector(
            startTimestamp == 0 ? uint48(block.timestamp) : startTimestamp,
            endTimestamp,
            periodDuration,
            maxUserClaimableViaVector,
            maxTotalClaimableViaVector,
            0,
            0,
            tokenLimitPerTx,
            numPrices,
            payable(paymentRecipient),
            0,
            bytesPerPrice,
            false,
            false
        );

        _validateVectorConfig(_vector, packedPrices, true);

        vector[mechanicVectorId] = _vector;
        vectorPackedPrices[mechanicVectorId] = packedPrices;

        emit DiscreteDutchAuctionCreated(mechanicVectorId);
    }

    /* solhint-disable code-complexity */
    /**
     * @notice Update a dutch auction vector
     * @param mechanicVectorId Global mechanic vector ID
     * @param newVector New vector fields
     * @param updateConfig Config denoting what fields on vector to update
     */
    function updateVector(
        bytes32 mechanicVectorId,
        DutchAuctionVector calldata newVector,
        bytes calldata newPackedPrices,
        DutchAuctionVectorUpdateConfig calldata updateConfig
    ) external {
        MechanicVectorMetadata memory metadata = _getMechanicVectorMetadata(mechanicVectorId);
        if (
            metadata.contractAddress != msg.sender && OwnableUpgradeable(metadata.contractAddress).owner() != msg.sender
        ) {
            _revert(Unauthorized.selector);
        }
        DutchAuctionVector memory currentVector = vector[mechanicVectorId];

        // after first token has been minted, cannot update: prices, period, start time, max total claimable via vector
        if (
            currentVector.currentSupply > 0 &&
            (updateConfig.updatePrices ||
                updateConfig.updatePeriodDuration ||
                updateConfig.updateStartTimestamp ||
                updateConfig.updateMaxTotalClaimableViaVector)
        ) {
            _revert(InvalidUpdate.selector);
        }

        // construct end state of vector with updates applied, then validate
        if (updateConfig.updateStartTimestamp) {
            currentVector.startTimestamp = newVector.startTimestamp == 0
                ? uint48(block.timestamp)
                : newVector.startTimestamp;
        }
        if (updateConfig.updateEndTimestamp) {
            currentVector.endTimestamp = newVector.endTimestamp;
        }
        if (updateConfig.updatePeriodDuration) {
            currentVector.periodDuration = newVector.periodDuration;
        }
        if (updateConfig.updateMaxUserClaimableViaVector) {
            currentVector.maxUserClaimableViaVector = newVector.maxUserClaimableViaVector;
        }
        if (updateConfig.updateMaxTotalClaimableViaVector) {
            currentVector.maxTotalClaimableViaVector = newVector.maxTotalClaimableViaVector;
        }
        if (updateConfig.updateTokenLimitPerTx) {
            currentVector.tokenLimitPerTx = newVector.tokenLimitPerTx;
        }
        if (updateConfig.updatePaymentRecipient) {
            currentVector.paymentRecipient = newVector.paymentRecipient;
        }
        if (updateConfig.updatePrices) {
            currentVector.bytesPerPrice = newVector.bytesPerPrice;
            currentVector.numPrices = newVector.numPrices;
        }

        _validateVectorConfig(currentVector, newPackedPrices, updateConfig.updatePrices);

        // rather than updating entire vector, update per-field
        if (updateConfig.updateStartTimestamp) {
            vector[mechanicVectorId].startTimestamp = currentVector.startTimestamp;
        }
        if (updateConfig.updateEndTimestamp) {
            vector[mechanicVectorId].endTimestamp = currentVector.endTimestamp;
        }
        if (updateConfig.updatePeriodDuration) {
            vector[mechanicVectorId].periodDuration = currentVector.periodDuration;
        }
        if (updateConfig.updateMaxUserClaimableViaVector) {
            vector[mechanicVectorId].maxUserClaimableViaVector = currentVector.maxUserClaimableViaVector;
        }
        if (updateConfig.updateMaxTotalClaimableViaVector) {
            vector[mechanicVectorId].maxTotalClaimableViaVector = currentVector.maxTotalClaimableViaVector;
        }
        if (updateConfig.updateTokenLimitPerTx) {
            vector[mechanicVectorId].tokenLimitPerTx = currentVector.tokenLimitPerTx;
        }
        if (updateConfig.updatePaymentRecipient) {
            vector[mechanicVectorId].paymentRecipient = currentVector.paymentRecipient;
        }
        if (updateConfig.updatePrices) {
            vectorPackedPrices[mechanicVectorId] = newPackedPrices;
            vector[mechanicVectorId].bytesPerPrice = currentVector.bytesPerPrice;
            vector[mechanicVectorId].numPrices = currentVector.numPrices;
        }

        emit DiscreteDutchAuctionUpdated(mechanicVectorId);
    }

    /* solhint-enable code-complexity */

    /**
     * @notice See {IMechanic-processNumMint}
     */
    function processNumMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable onlyMintManager {
        _processMint(mechanicVectorId, recipient, numToMint);
    }

    /**
     * @notice See {IMechanic-processChooseMint}
     */
    function processChooseMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable onlyMintManager {
        _processMint(mechanicVectorId, recipient, uint32(tokenIds.length));
    }

    /**
     * @notice Rebate a collector any rebates they're eligible for
     * @param mechanicVectorId Mechanic vector ID
     * @param collector Collector to send rebates to
     */
    function rebateCollector(bytes32 mechanicVectorId, address payable collector) external {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][collector];

        if (_vector.currentSupply == 0) {
            _revert(InvalidRebate.selector);
        }
        bool _auctionExhausted = _vector.auctionExhausted;
        if (!_auctionExhausted) {
            _auctionExhausted = _isAuctionExhausted(
                mechanicVectorId,
                _vector.currentSupply,
                _vector.maxTotalClaimableViaVector
            );
            if (_auctionExhausted) {
                vector[mechanicVectorId].auctionExhausted = true;
            }
        }

        // rebate collector at the price:
        // - lowest price sold at if auction is exhausted (vector sold out or collection sold out)
        // - current price otherwise
        uint200 currentPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            _auctionExhausted
                ? _vector.lowestPriceSoldAtIndex
                : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices)
        );
        uint200 currentPriceObligation = _userPurchaseInfo.numTokensBought * currentPrice;
        uint200 amountOwed = _userPurchaseInfo.totalPosted - currentPriceObligation;

        if (amountOwed == 0) {
            _revert(CollectorNotOwedRebate.selector);
        }

        userPurchaseInfo[mechanicVectorId][collector].totalPosted = currentPriceObligation;
        userPurchaseInfo[mechanicVectorId][collector].numRebates = _userPurchaseInfo.numRebates + 1;

        (bool sentToCollector, bytes memory data) = collector.call{ value: amountOwed }("");
        if (!sentToCollector) {
            _revert(EtherSendFailed.selector);
        }

        emit DiscreteDutchAuctionCollectorRebate(mechanicVectorId, collector, amountOwed, currentPrice);
    }

    /**
     * @notice Withdraw funds collected through the dynamic period of a dutch auction
     * @param mechanicVectorId Mechanic vector ID
     */
    function withdrawDPPFunds(bytes32 mechanicVectorId) external {
        // all slots are used, so load entire object from storage
        DutchAuctionVector memory _vector = vector[mechanicVectorId];

        if (_vector.payeeRevenueHasBeenWithdrawn || _vector.currentSupply == 0) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }
        bool _auctionExhausted = _vector.auctionExhausted;
        if (!_auctionExhausted) {
            _auctionExhausted = _isAuctionExhausted(
                mechanicVectorId,
                _vector.currentSupply,
                _vector.maxTotalClaimableViaVector
            );
            if (_auctionExhausted) {
                vector[mechanicVectorId].auctionExhausted = true;
            }
        }
        uint32 priceIndex = _auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);

        // if any of the following 3 are met, DPP funds can be withdrawn:
        //  - auction is in FPP
        //  - maxTotalClaimableViaVector is reached
        //  - all tokens have been minted on collection (outside of vector knowledge)
        if (!_auctionExhausted && !_auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices)) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }

        vector[mechanicVectorId].payeeRevenueHasBeenWithdrawn = true;

        uint200 clearingPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            priceIndex
        );
        uint200 totalRefund = _vector.currentSupply * clearingPrice;
        // precaution: protect against pulling out more than total sales ->
        // guards against bad actor pulling out more via
        // funds collection + rebate price ascending setup (theoretically not possible)
        if (totalRefund > _vector.totalSales) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }

        (bool sentToPaymentRecipient, bytes memory data) = _vector.paymentRecipient.call{ value: totalRefund }("");
        if (!sentToPaymentRecipient) {
            _revert(EtherSendFailed.selector);
        }

        emit DiscreteDutchAuctionDPPFundsWithdrawn(
            mechanicVectorId,
            _vector.paymentRecipient,
            clearingPrice,
            _vector.currentSupply
        );
    }

    /**
     * @notice Get how much of a rebate a user is owed
     * @param mechanicVectorId Mechanic vector ID
     * @param user User to get rebate information for
     */
    function getUserInfo(
        bytes32 mechanicVectorId,
        address user
    ) external view returns (uint256 rebate, UserPurchaseInfo memory) {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][user];

        if (_vector.currentSupply == 0) {
            return (0, _userPurchaseInfo);
        }

        // rebate collector at the price:
        // - lowest price sold at if vector is sold out or collection is sold out
        // - current price otherwise
        uint200 currentPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector)
                ? _vector.lowestPriceSoldAtIndex
                : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices)
        );
        uint200 currentPriceObligation = _userPurchaseInfo.numTokensBought * currentPrice;
        uint256 amountOwed = uint256(_userPurchaseInfo.totalPosted - currentPriceObligation);

        return (amountOwed, _userPurchaseInfo);
    }

    /**
     * @notice Get how much is owed to the payment recipient (currently)
     * @param mechanicVectorId Mechanic vector ID
     * @param escrowFunds Amount owed to the creator currently
     * @param amountFinalized Whether this is the actual amount that will be owed (will decrease until the auction ends)
     */
    function getPayeePotentialEscrowedFunds(
        bytes32 mechanicVectorId
    ) external view returns (uint256 escrowFunds, bool amountFinalized) {
        return _getPayeePotentialEscrowedFunds(mechanicVectorId);
    }

    /**
     * @notice Get raw vector data
     * @param mechanicVectorId Mechanic vector ID
     */
    function getRawVector(
        bytes32 mechanicVectorId
    ) external view returns (DutchAuctionVector memory _vector, bytes memory packedPrices) {
        _vector = vector[mechanicVectorId];
        packedPrices = vectorPackedPrices[mechanicVectorId];
    }

    /**
     * @notice Get a vector's full state, including the refund currently owed to the creator and human-readable prices
     * @param mechanicVectorId Mechanic vector ID
     */
    function getVectorState(
        bytes32 mechanicVectorId
    )
        external
        view
        returns (
            DutchAuctionVector memory _vector,
            uint200[] memory prices,
            uint200 currentPrice,
            uint256 payeePotentialEscrowedFunds,
            uint256 collectionSupply,
            uint256 collectionSize,
            bool escrowedFundsAmountFinalized,
            bool auctionExhausted,
            bool auctionInFPP
        )
    {
        _vector = vector[mechanicVectorId];
        (payeePotentialEscrowedFunds, escrowedFundsAmountFinalized) = _getPayeePotentialEscrowedFunds(mechanicVectorId);
        (collectionSupply, collectionSize) = _collectionSupplyAndSize(mechanicVectorId);
        auctionExhausted =
            _vector.auctionExhausted ||
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector);
        uint32 priceIndex = auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        currentPrice = PackedPrices.priceAt(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, priceIndex);
        auctionInFPP = _auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices);
        prices = PackedPrices.unpack(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, _vector.numPrices);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice Limit upgrades of contract to DiscreteDutchAuctionMechanic owner
     * @param // New implementation address
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Process mint logic common through sequential and collector's choice based mints
     * @param mechanicVectorId Mechanic vector ID
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     */
    function _processMint(bytes32 mechanicVectorId, address recipient, uint32 numToMint) private {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][recipient];

        uint48 newSupply = _vector.currentSupply + numToMint;
        if (
            block.timestamp < _vector.startTimestamp ||
            (block.timestamp > _vector.endTimestamp && _vector.endTimestamp != 0) ||
            (_vector.maxTotalClaimableViaVector != 0 && newSupply > _vector.maxTotalClaimableViaVector) ||
            (_vector.maxUserClaimableViaVector != 0 &&
                _userPurchaseInfo.numTokensBought + numToMint > _vector.maxUserClaimableViaVector) ||
            (_vector.tokenLimitPerTx != 0 && numToMint > _vector.tokenLimitPerTx) ||
            _vector.auctionExhausted
        ) {
            _revert(InvalidMint.selector);
        }

        // can safely cast down here since the value is dependent on array length
        uint32 priceIndex = _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        uint200 price = PackedPrices.priceAt(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, priceIndex);
        uint200 totalPrice = price * numToMint;

        if (totalPrice > msg.value) {
            _revert(InvalidPaymentAmount.selector);
        }

        // update lowestPriceSoldAtindex, currentSupply, totalSales and user purchase info
        if (_vector.lowestPriceSoldAtIndex != priceIndex) {
            vector[mechanicVectorId].lowestPriceSoldAtIndex = priceIndex;
        }
        vector[mechanicVectorId].currentSupply = newSupply;
        vector[mechanicVectorId].totalSales = _vector.totalSales + totalPrice;
        _userPurchaseInfo.numTokensBought += numToMint;
        _userPurchaseInfo.totalPosted += uint200(msg.value); // if collector sent more, let them collect the difference
        userPurchaseInfo[mechanicVectorId][recipient] = _userPurchaseInfo;

        if (_vector.payeeRevenueHasBeenWithdrawn) {
            // send ether value to payment recipient
            (bool sentToPaymentRecipient, bytes memory data) = _vector.paymentRecipient.call{ value: totalPrice }("");
            if (!sentToPaymentRecipient) {
                _revert(EtherSendFailed.selector);
            }
        }

        emit DiscreteDutchAuctionMint(mechanicVectorId, recipient, price, numToMint);
    }

    /**
     * @notice Validate a dutch auction vector
     * @param _vector Dutch auction vector being validated
     */
    function _validateVectorConfig(
        DutchAuctionVector memory _vector,
        bytes memory packedPrices,
        bool validateIndividualPrices
    ) private {
        if (
            _vector.periodDuration == 0 ||
            _vector.paymentRecipient == address(0) ||
            _vector.numPrices < 2 ||
            _vector.bytesPerPrice > 32
        ) {
            _revert(InvalidVectorConfig.selector);
        }
        if (_vector.endTimestamp != 0) {
            // allow the last period to be truncated
            if (_vector.startTimestamp + ((_vector.numPrices - 1) * _vector.periodDuration) >= _vector.endTimestamp) {
                _revert(InvalidVectorConfig.selector);
            }
        }
        if (validateIndividualPrices) {
            if (_vector.bytesPerPrice * _vector.numPrices != packedPrices.length) {
                _revert(InvalidVectorConfig.selector);
            }
            uint200[] memory prices = PackedPrices.unpack(packedPrices, _vector.bytesPerPrice, _vector.numPrices);
            uint200 lastPrice = prices[0];
            uint256 numPrices = uint256(_vector.numPrices); // cast up into uint256 for gas savings on array check
            for (uint256 i = 1; i < _vector.numPrices; i++) {
                if (prices[i] >= lastPrice) {
                    _revert(InvalidVectorConfig.selector);
                }
                lastPrice = prices[i];
            }
        }
    }

    /**
     * @notice Get how much is owed to the payment recipient currently
     * @param mechanicVectorId Mechanic vector ID
     * @return escrowFunds + isFinalAmount
     */
    function _getPayeePotentialEscrowedFunds(bytes32 mechanicVectorId) private view returns (uint256, bool) {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];

        if (_vector.payeeRevenueHasBeenWithdrawn) {
            // escrowed funds have already been withdrawn / finalized
            return (0, true);
        }
        if (_vector.currentSupply == 0) {
            return (0, false);
        }

        bool auctionExhausted = _vector.auctionExhausted ||
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector);
        uint32 priceIndex = auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        uint200 potentialClearingPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            priceIndex
        );

        // escrowFunds is only final if auction is exhausted or in FPP
        return (
            uint256(_vector.currentSupply * potentialClearingPrice),
            (auctionExhausted || _auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices))
        );
    }

    /**
     * @notice Return true if an auction has reached its max supply or if the underlying collection has
     * @param mechanicVectorId Mechanic vector ID
     * @param currentSupply Current supply minted through the vector
     * @param maxTotalClaimableViaVector Max claimable via the vector
     */
    function _isAuctionExhausted(
        bytes32 mechanicVectorId,
        uint48 currentSupply,
        uint48 maxTotalClaimableViaVector
    ) private view returns (bool) {
        if (maxTotalClaimableViaVector != 0 && currentSupply >= maxTotalClaimableViaVector) return true;
        (uint256 supply, uint256 size) = _collectionSupplyAndSize(mechanicVectorId);
        return size != 0 && supply >= size;
    }

    /**
     * @notice Returns a collection's current supply
     * @param mechanicVectorId Mechanic vector ID
     */
    function _collectionSupplyAndSize(bytes32 mechanicVectorId) private view returns (uint256 supply, uint256 size) {
        MechanicVectorMetadata memory metadata = _getMechanicVectorMetadata(mechanicVectorId);
        if (metadata.contractAddress == address(0)) {
            revert("Vector doesn't exist");
        }
        if (metadata.isEditionBased) {
            IEditionCollection.EditionDetails memory edition = IEditionCollection(metadata.contractAddress)
                .getEditionDetails(metadata.editionId);
            supply = edition.supply;
            size = edition.size;
        } else {
            // supply holds a tighter constraint (no burns), some old contracts don't have it
            try IERC721GeneralSupplyMetadata(metadata.contractAddress).supply() returns (uint256 _supply) {
                supply = _supply;
            } catch {
                supply = IERC721GeneralSupplyMetadata(metadata.contractAddress).totalSupply();
            }
            size = IERC721GeneralSupplyMetadata(metadata.contractAddress).limitSupply();
        }
    }

    /**
     * @notice Calculate what price the dutch auction is at
     * @param startTimestamp Auction start time
     * @param periodDuration Time per period
     * @param numPrices Number of prices
     */
    function _calculatePriceIndex(
        uint48 startTimestamp,
        uint32 periodDuration,
        uint32 numPrices
    ) private view returns (uint32) {
        if (block.timestamp <= startTimestamp) {
            return 0;
        }
        uint256 hypotheticalIndex = uint256((block.timestamp - startTimestamp) / periodDuration);
        if (hypotheticalIndex >= numPrices) {
            return numPrices - 1;
        } else {
            return uint32(hypotheticalIndex);
        }
    }

    /**
     * @notice Return if the auction is in the fixed price period
     * @param currentSupply Current supply of tokens minted via mechanic vector
     * @param priceIndex Index of price prices
     * @param numPrices Number of prices
     */
    function _auctionIsInFPP(uint48 currentSupply, uint256 priceIndex, uint32 numPrices) private pure returns (bool) {
        return currentSupply > 0 && priceIndex == numPrices - 1;
    }
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
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processNumMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable;

    /**
     * @notice Process a collector's choice mint
     * @param mechanicVectorId Global ID identifying mint vector, using this mechanic
     * @param recipient Mint recipient
     * @param tokenIds IDs of tokens to mint
     * @param mechanicVectorMetadata Mechanic vector metadata
     * @param data Custom data that can be deserialized and processed according to implementation
     */
    function processChooseMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
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

interface IMechanicMintManagerView is IMechanicData {
    /**
     * @notice Get a mechanic vector's metadata
     * @param mechanicVectorId Global mechanic vector ID
     */
    function mechanicVectorMetadata(bytes32 mechanicVectorId) external view returns (MechanicVectorMetadata memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMechanic.sol";
import "./interfaces/IMechanicMintManagerView.sol";

/**
 * @notice MintManager client, to be used by mechanic contracts
 * @author highlight.xyz
 */
abstract contract MechanicMintManagerClientUpgradeable is OwnableUpgradeable, IMechanic {
    /**
     * @notice Throw when caller is not MintManager
     */
    error NotMintManager();

    /**
     * @notice Throw when input mint manager is invalid
     */
    error InvalidMintManager();

    /**
     * @notice Mint manager
     */
    address public mintManager;

    /**
     * @notice Enforce caller to be mint manager
     */
    modifier onlyMintManager() {
        if (msg.sender != mintManager) {
            _revert(NotMintManager.selector);
        }
        _;
    }

    /**
     * @notice Update the mint manager
     * @param _mintManager New mint manager
     */
    function updateMintManager(address _mintManager) external onlyOwner {
        if (_mintManager == address(0)) {
            _revert(InvalidMintManager.selector);
        }

        mintManager = _mintManager;
    }

    /**
     * @notice Initialize mechanic mint manager client
     * @param _mintManager Mint manager address
     * @param platform Platform owning the contract
     */
    function __MechanicMintManagerClientUpgradeable_initialize(
        address _mintManager,
        address platform
    ) internal onlyInitializing {
        __Ownable_init();
        mintManager = _mintManager;
        _transferOwnership(platform);
    }

    /**
     * @notice Get a mechanic mint vector's metadata
     * @param mechanicVectorId Mechanic vector ID
     */
    function _getMechanicVectorMetadata(
        bytes32 mechanicVectorId
    ) internal view returns (MechanicVectorMetadata memory) {
        return IMechanicMintManagerView(mintManager).mechanicVectorMetadata(mechanicVectorId);
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Util library to pack, unpack, and access packed prices data
 * @author highlight.xyz
 */
library PackedPrices {
    /**
     * @notice Return unpacked prices
     * @dev Assume length validations are met
     */
    function unpack(
        bytes memory packedPrices,
        uint8 bytesPerPrice,
        uint32 numPrices
    ) internal view returns (uint200[] memory prices) {
        prices = new uint200[](numPrices);

        for (uint32 i = 0; i < numPrices; i++) {
            prices[i] = priceAt(packedPrices, bytesPerPrice, i);
        }
    }

    /**
     * @notice Return price at an index
     * @dev Assume length validations are met
     */
    function priceAt(bytes memory packedPrices, uint8 bytesPerPrice, uint32 index) internal view returns (uint200) {
        uint256 readIndex = index * bytesPerPrice;
        uint256 price;

        assembly {
            // Load 32 bytes starting from the correct position in packedPrices
            price := mload(add(packedPrices, add(32, readIndex)))
        }

        return uint200(price >> (256 - (bytesPerPrice * 8)));
    }
}