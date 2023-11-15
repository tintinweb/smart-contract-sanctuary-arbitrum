// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */

    /// @notice storage slot in proxy should be unique, we use hunt nft prefix to avoid mixed slot
    bytes32 internal constant Initialized_Slot = keccak256("HuntNft.Initialized");

    /// @notice initialzie instead of constructor to make sure the bytecode is consistent.Can only be called once
    function initializeBeacon(address beacon, bytes memory data) public payable {
        bytes32 Initialized_Slot = Initialized_Slot;
        bool initialized;
        bytes memory reason = "already initialized";
        assembly {
            initialized := sload(Initialized_Slot)
            if gt(initialized, 0) {
                revert(add(reason, 0x20), mload(reason))
            }
            sstore(Initialized_Slot, 1)
        }
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/// @notice remove the constructor for upgrade contract
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interface/IHuntGameRandomRequester.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./HuntGameDeployer.sol";
import "../interface/IHunterValidator.sol";
import "../interface/IHuntNFTFactory.sol";
import "../helper/ReentrancyGuard.sol";
import "../libraries/GlobalNftLib.sol";

contract HuntGame is ERC721Holder, ERC1155Holder, ReentrancyGuard, IHuntGame, IHuntGameRandomRequester {
    /// cfg in factory
    IHuntNFTFactory public override factory;
    uint64 public override gameId;
    uint256 public override userNonce;

    /// cfg in game
    address public override owner;
    IHunterValidator public override validator;
    uint64 public override ddl;
    uint256 public override bulletPrice;
    uint64 public override totalBullets;
    address public override getPayment;
    /// cfg about nft
    IHuntGame.NFTStandard public override nftStandard;
    address public override nftContract;
    uint64 public override originChain;
    uint256 public override tokenId;

    IHuntGame.Status public override status;
    HunterInfo[] public override tempHunters;
    uint256 public override randomNum;
    uint256 public override requestId;
    address private _winner;
    bool public override nftPaid;
    bool public override ownerPaid;

    /////////////////////////////

    modifier depositing() {
        require(status == Status.Depositing, "only depositing");
        _;
    }

    modifier hunting() {
        /// @notice should not reach the ddl when hunting
        require(block.timestamp < ddl, "ddl");
        require(status == Status.Hunting, "only hunting");
        _;
    }

    modifier waiting() {
        require(status == Status.Waiting, "only waiting");
        _;
    }

    modifier timeout() {
        require(status == Status.Timeout, "only timeout");
        _;
    }

    modifier unclaimed() {
        require(status == Status.Unclaimed, "only unclaimed");
        _;
    }

    function initialize(
        IHunterValidator _hunterValidator,
        IHuntGame.NFTStandard _nftStandard,
        uint64 _totalBullets,
        uint256 _bulletPrice,
        address _nftContract,
        uint64 _originChain,
        address _getPayment,
        IHuntNFTFactory _factory,
        uint256 _tokenId,
        uint64 _gameId,
        uint64 _ddl,
        address _owner
    ) public {
        require(gameId == 0 && _gameId > 0); // notice avoid initialize twice and reentrancy
        gameId = _gameId;

        userNonce = IHuntGameDeployer(msg.sender).userNonce(_owner);
        validator = _hunterValidator;
        nftStandard = _nftStandard;
        totalBullets = _totalBullets;
        bulletPrice = _bulletPrice;
        nftContract = _nftContract;
        originChain = _originChain;
        getPayment = _getPayment;
        factory = _factory;
        tokenId = _tokenId;
        ddl = _ddl;
        owner = _owner;
        if (address(validator) != address(0)) {
            validator.huntGameRegister();
        }
    }

    function startHunt() public nonReentrant depositing {
        require(
            GlobalNftLib.isOwned(
                factory.getHuntBridge(),
                originChain,
                nftStandard == NFTStandard.GlobalERC1155,
                nftContract,
                tokenId
            ),
            "depositing"
        );
        /// @dev now start hunt
        status = Status.Hunting;
        emit Hunting();
    }

    function hunt(uint64 bullet) public payable {
        hunt(msg.sender, bullet, false, "");
    }

    function hunt(address hunter, uint64 bullet, bool _isFromAssetManager, bytes memory payload) public payable {
        if (getPayment == address(0)) {
            huntInNative(hunter, bullet, bullet, _isFromAssetManager, payload);
        } else {
            hunt(hunter, bullet, bullet, _isFromAssetManager, payload);
        }
    }

    function huntInNative(
        address _hunter,
        uint64 _bulletNum,
        uint64 _minNum,
        bool _isFromAssetManager,
        bytes memory _payload
    ) public payable nonReentrant hunting returns (uint64) {
        require(getPayment == address(0), "eth wanted");
        require(_bulletNum * bulletPrice == msg.value, "wrong value");
        require(_bulletNum > 0, "empty bullet");

        uint64 _before = 0;
        if (tempHunters.length > 0) {
            _before = tempHunters[tempHunters.length - 1].totalBullets;
        }
        require(_before < totalBullets, "over bullet");
        if (_before + _bulletNum > totalBullets) {
            _bulletNum = totalBullets - _before;
        }
        require(_bulletNum >= _minNum, "left not enough");
        /// @dev should never happen except reentrancy
        assert(_before + _bulletNum <= totalBullets);

        _beforeBuy(_hunter, _bulletNum, _payload);
        if (_before + _bulletNum == totalBullets) {
            _waitForRandom();
        }
        HunterInfo memory _info = HunterInfo({
            hunter: _hunter,
            bulletsAmountBefore: _before,
            bulletNum: _bulletNum,
            totalBullets: _before + _bulletNum,
            isFromAssetManager: _isFromAssetManager
        });
        tempHunters.push(_info);
        emit Hunted(uint64(tempHunters.length) - 1, _info);

        /// overflow same
        uint256 _refund = (msg.value - _bulletNum * bulletPrice);
        /// @dev if there left some eth, refund to sender
        if (_refund > 0) {
            payable(msg.sender).transfer(_refund);
        }
        _afterBuy();
        return _bulletNum;
    }

    function hunt(
        address _hunter,
        uint64 _bulletNum,
        uint64 _minNum,
        bool _isFromAssetManager,
        bytes memory _payload
    ) public nonReentrant hunting returns (uint64) {
        /// @notice receive erc20 token
        require(getPayment != address(0), "eth not allowed");
        require(_bulletNum > 0);
        uint64 _before = 0;
        if (tempHunters.length > 0) {
            _before = tempHunters[tempHunters.length - 1].totalBullets;
        }
        require(_before < totalBullets, "over bullet");
        if (_before + _bulletNum > totalBullets) {
            _bulletNum = totalBullets - _before;
        }
        require(_bulletNum >= _minNum, "left not enough");
        /// @dev should never happen
        assert(_before + _bulletNum <= totalBullets);

        _beforeBuy(_hunter, _bulletNum, _payload);
        /// overflow safe
        uint256 _amount = _bulletNum * bulletPrice;
        factory.huntGameClaimPayment(msg.sender, getPayment, _amount);
        if (_before + _bulletNum == totalBullets) {
            _waitForRandom();
        }
        HunterInfo memory _info = HunterInfo({
            hunter: _hunter,
            bulletsAmountBefore: _before,
            bulletNum: _bulletNum,
            totalBullets: _before + _bulletNum,
            isFromAssetManager: _isFromAssetManager
        });
        tempHunters.push(_info);
        emit Hunted(uint64(tempHunters.length) - 1, _info);

        _afterBuy();
        return _bulletNum;
    }

    function fillRandom(uint256 _randomNum) public waiting {
        require(msg.sender == address(factory));
        assert(randomNum == 0);
        randomNum = _randomNum;
        status = Status.Unclaimed;
        emit Unclaimed();
    }

    function claimTimeout() public {
        require(status == Status.Hunting || status == Status.Waiting);
        require(block.timestamp > ddl, "in time");
        status = Status.Timeout;
        emit Timeout();
    }

    function timeoutWithdrawBullets(uint64[] calldata _hunterIndexes) public timeout {
        require(_hunterIndexes.length > 0);
        for (uint256 i = 0; i < _hunterIndexes.length; i++) {
            uint64 _num = tempHunters[_hunterIndexes[i]].bulletNum;
            require(_num > 0, "no bullets");
            tempHunters[_hunterIndexes[i]].bulletNum = 0;
            uint256 _amount = uint256(_num) * bulletPrice;
            _pay(tempHunters[_hunterIndexes[i]].hunter, _amount, tempHunters[_hunterIndexes[i]].isFromAssetManager);
        }
        emit HunterWithdrawal(_hunterIndexes);
    }

    function timeoutWithdrawNFT() public payable {
        timeoutClaimNFT(true);
    }

    function timeoutClaimNFT(bool withdraw) public payable timeout {
        /// @notice do not try to pay twice
        require(!nftPaid, "paid");
        nftPaid = true;
        GlobalNftLib.transfer(
            factory.getHuntBridge(),
            originChain,
            nftStandard == NFTStandard.GlobalERC1155,
            nftContract,
            tokenId,
            owner,
            withdraw
        );
        emit NFTClaimed(owner);
    }

    function claimNft(uint64 _winnerIndex) public payable {
        claimNft(_winnerIndex, true);
    }

    function claimNft(uint64 _winnerIndex, bool _withdraw) public payable unclaimed {
        /// @notice do not try to pay twice
        require(!nftPaid, "paid");
        nftPaid = true;
        uint256 luckyBullet = (randomNum % totalBullets) + 1;
        require(_winnerIndex < tempHunters.length, "Index overflow");
        require(
            tempHunters[_winnerIndex].bulletsAmountBefore < luckyBullet &&
                tempHunters[_winnerIndex].totalBullets >= luckyBullet,
            "Not winner"
        );
        if (nftPaid && ownerPaid) {
            status = Status.Claimed;
            emit Claimed();
        }
        _winner = tempHunters[_winnerIndex].hunter;
        GlobalNftLib.transfer(
            factory.getHuntBridge(),
            originChain,
            nftStandard == NFTStandard.GlobalERC1155,
            nftContract,
            tokenId,
            _winner,
            _withdraw
        );
        emit NFTClaimed(_winner);
    }

    function claimReward() public unclaimed {
        require(!ownerPaid, "paid");
        ownerPaid = true;
        emit OwnerPaid();
        if (nftPaid && ownerPaid) {
            status = Status.Claimed;
            emit Claimed();
        }
        uint256 _amount = uint256(totalBullets) * bulletPrice;
        uint256 _fee = factory.getFeeManager().calcFee(_amount);
        _pay(owner, _amount - _fee, false);
        _pay(address(factory.getFeeManager()), _fee, false);
    }

    function getWinnerIndex() public view returns (uint64) {
        require(randomNum != 0, "not filled yet");
        uint256 luckyBullet = (randomNum % totalBullets) + 1;
        for (uint256 i = 0; i < tempHunters.length; i++) {
            if (tempHunters[i].bulletsAmountBefore < luckyBullet && tempHunters[i].totalBullets >= luckyBullet) {
                return uint64(i);
            }
        }
        revert("wired");
    }

    function winner() public view returns (address) {
        require(randomNum != 0, "not filled yet");
        if (_winner != address(0)) {
            return _winner;
        }
        uint256 luckyBullet = (randomNum % totalBullets) + 1;
        for (uint256 i = 0; i < tempHunters.length; i++) {
            if (tempHunters[i].bulletsAmountBefore < luckyBullet && tempHunters[i].totalBullets >= luckyBullet) {
                return tempHunters[i].hunter;
            }
        }
        revert("wired");
    }

    function estimateFees() public view returns (uint256) {
        if (originChain == block.chainid) {
            //no need to bridge back
            return 0;
        }
        return factory.getHuntBridge().estimateFees(originChain);
    }

    function canHunt(address hunter, uint64 bullet) public view returns (bool) {
        return canHunt(msg.sender, hunter, bullet, "");
    }

    function canHunt(address sender, address hunter, uint64 bullet, bytes memory payload) public view returns (bool) {
        if (address(validator) == address(0)) {
            /// @dev all pass
            return true;
        }
        return validator.isHunterPermitted(sender, msg.sender, hunter, bullet, payload);
    }

    function leftBullet() public view returns (uint64) {
        return tempHunters.length == 0 ? totalBullets : totalBullets - tempHunters[tempHunters.length - 1].totalBullets;
    }

    function _waitForRandom() internal {
        status = Status.Waiting;
        emit Waiting();
        requestId = factory.requestRandomWords();
    }

    function _beforeBuy(address _hunter, uint64 _bulletNum, bytes memory _payload) internal {
        if (address(validator) != address(0)) {
            validator.validateHunter(address(this), msg.sender, _hunter, _bulletNum, _payload);
        }
    }

    function _afterBuy() internal {}

    /// @notice reduce the bullets before call this method
    function _pay(address addr, uint256 _amount, bool isFromAssetManager) internal {
        if (getPayment == address(0)) {
            //eth, transfer
            if (isFromAssetManager) {
                factory.getHunterAssetManager().deposit{ value: _amount }(addr);
            } else {
                payable(addr).transfer(_amount);
            }
        } else {
            if (isFromAssetManager) {
                factory.getHunterAssetManager().deposit(addr, getPayment, _amount);
            } else {
                IERC20(getPayment).transfer(addr, _amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../helper/BeaconProxy.sol";
import "../interface/IHuntGameDeployer.sol";
import "./HuntGame.sol";
import "../libraries/Consts.sol";

/**huntnft
 * @title HunterPoolDeployer depoly hunter pool with provided params
 * @notice every unique paymentToken, nft , bulletPrice will create a unique pool
 */
contract HuntGameDeployer is IHuntGameDeployer {
    address beacon;
    /// @dev used to make game address unique
    mapping(address => uint256) public userNonce;
    struct DeployParams {
        IHunterValidator hunterValidator;
        IHuntGame.NFTStandard nftStandard;
        uint64 totalBullets;
        uint256 bulletPrice;
        address nftContract;
        uint64 originChain;
        address getPayment;
        IHuntNFTFactory factory;
        uint256 tokenId;
        uint64 gameId;
        uint64 ddl;
        address owner;
    }

    function calcGameAddr(address creator, uint256 nonce) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                keccak256(abi.encode(creator, nonce)),
                                Consts.BEACON_PROXY_CODE_HASH
                            )
                        )
                    )
                )
            );
    }

    function getPendingGame(address creator) public view returns (address) {
        return calcGameAddr(creator, userNonce[creator]);
    }

    function _deploy(DeployParams storage tempDeployParams) internal returns (address game) {
        BeaconProxy proxy = new BeaconProxy{ salt: keccak256(abi.encode(msg.sender, userNonce[msg.sender])) }();
        proxy.initializeBeacon(beacon, "");
        game = address(proxy);
        HuntGame(game).initialize(
            tempDeployParams.hunterValidator,
            tempDeployParams.nftStandard,
            tempDeployParams.totalBullets,
            tempDeployParams.bulletPrice,
            tempDeployParams.nftContract,
            tempDeployParams.originChain,
            tempDeployParams.getPayment,
            tempDeployParams.factory,
            tempDeployParams.tokenId,
            tempDeployParams.gameId,
            tempDeployParams.ddl,
            tempDeployParams.owner
        );
        userNonce[msg.sender]++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "../interface/IHuntGameRandomRequester.sol";
import "../interface/IHuntNFTFactory.sol";
import "./HuntGameDeployer.sol";
import "../helper/ReentrancyGuard.sol";
import "../interface/IBulletOracle.sol";

contract HuntNFTFactory is OwnableUpgradeable, VRFConsumerBaseV2, HuntGameDeployer, ReentrancyGuard, IHuntNFTFactory {
    address constant ETH_PAYMENT = address(0);

    IHuntBridge public override getHuntBridge;
    IHunterAssetManager public override getHunterAssetManager;
    IFeeManager public override getFeeManager;
    IBulletOracle getBulletOracle;

    uint64 public override totalGames;
    mapping(uint64 => address) public getGameById;
    mapping(address => bool) public override isHuntGame;
    mapping(address => bool) public override isPaymentEnabled;

    DeployParams deployParams;
    bytes public override tempValidatorParams;

    /// @dev vrf states
    // Your subscription ID.
    uint64 vrfSubscriptionId;
    VRFCoordinatorV2Interface vrfCordinator;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 vrfKeyHash;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant numWords = 1;
    // Your rquest ID.
    mapping(uint256 => address) public getRequestGame;

    /// @dev GOERLI COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
    function initialize(
        address _beacon,
        uint64 _vrfSubscriptionId,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash
    ) public initializer {
        __Ownable_init();
        beacon = _beacon;
        VRFConsumerBaseV2._initialize(_vrfCoordinator);

        vrfSubscriptionId = _vrfSubscriptionId;
        vrfCordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfKeyHash = _vrfKeyHash;

        callbackGasLimit = 100000;
        requestConfirmations = 32;
    }

    function createWithPayETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) public payable {
        address _game = createETHHuntGame(
            gameOwner,
            wantedGame,
            hunterValidator,
            nftStandard,
            totalBullets,
            bulletPrice,
            nftContract,
            originChain,
            tokenId,
            ddl,
            registerParams
        );
        if (originChain != block.chainid) {
            address nft = IGlobalNftDeployer(getHuntBridge).calcAddr(originChain, nftContract);
            if (nftStandard == IHuntGame.NFTStandard.GlobalERC721) {
                IERC721(nft).transferFrom(msg.sender, _game, tokenId);
            } else {
                IERC1155(nft).safeTransferFrom(msg.sender, _game, tokenId, 1, "");
            }
            IHuntGame(_game).startHunt();
        }
    }

    function createETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) public payable nonReentrant returns (address _game) {
        require(tempValidatorParams.length == 0);
        tempValidatorParams = registerParams;
        if (gameOwner == address(0)) {
            gameOwner = msg.sender;
        }
        uint64 _gameId = totalGames + 1;
        totalGames += 1;
        deployParams = DeployParams(
            hunterValidator,
            nftStandard,
            totalBullets,
            bulletPrice,
            nftContract,
            originChain,
            address(0),
            this,
            tokenId,
            _gameId,
            ddl,
            gameOwner
        );
        _game = _createHuntGame();
        delete deployParams;
        if (wantedGame != address(0)) {
            require(_game == wantedGame, string(abi.encodePacked("wanted ", wantedGame, ",but got ", _game)));
        }
        delete tempValidatorParams;
    }

    function createHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) public payable nonReentrant returns (address _game) {
        require(tempValidatorParams.length == 0);
        require(isPaymentEnabled[payment], "PAYMENT_ERR");
        tempValidatorParams = registerParams;
        uint64 _gameId = totalGames + 1;
        totalGames += 1;
        deployParams = DeployParams(
            hunterValidator,
            nftStandard,
            totalBullets,
            bulletPrice,
            nftContract,
            originChain,
            payment,
            this,
            tokenId,
            _gameId,
            ddl,
            gameOwner
        );
        _game = _createHuntGame();
        delete deployParams;
        if (wantedGame != address(0)) {
            require(_game == wantedGame, string(abi.encodePacked("wanted ", wantedGame, ",but got ", _game)));
        }
        delete tempValidatorParams;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external returns (uint256 requestId) {
        require(isHuntGame[msg.sender], "only hunt game");
        // Will revert if subscription is not set and funded.
        requestId = vrfCordinator.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        require(getRequestGame[requestId] == address(0), "already registered");
        getRequestGame[requestId] = msg.sender;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        IHuntGameRandomRequester(getRequestGame[_requestId]).fillRandom(_randomWords[0]);
    }

    function huntGameClaimPayment(address _hunter, address _erc20, uint256 _amount) public {
        require(isHuntGame[msg.sender] && _erc20 != address(0));
        IERC20(_erc20).transferFrom(_hunter, msg.sender, _amount);
    }

    /// dao
    function setCallbackGasLimit(uint32 l) public onlyOwner {
        callbackGasLimit = l;
    }

    function setRequestConfirmations(uint16 l) public onlyOwner {
        requestConfirmations = l;
    }

    function enablePayment(address payment, bool enable) public onlyOwner {
        isPaymentEnabled[payment] = enable;
    }

    function setHuntBridge(IHuntBridge i) public onlyOwner {
        getHuntBridge = i;
    }

    function setHunterAssetManager(IHunterAssetManager i) public onlyOwner {
        getHunterAssetManager = i;
    }

    function setFeeManager(IFeeManager i) public onlyOwner {
        getFeeManager = i;
    }

    function setBulletOracle(IBulletOracle i) public onlyOwner {
        getBulletOracle = i;
    }

    function prepareSubBridgeParam() internal {
        if (msg.sender != address(getHuntBridge)) {
            return;
        }
        // bridge exceed total bullet will be recap to max bullet, make sure the value of asset not changed
        uint64 maxBullet = getBulletOracle.getMaxBullet(
            deployParams.owner,
            deployParams.originChain,
            deployParams.nftContract
        );
        if (deployParams.totalBullets > maxBullet) {
            uint256 value = deployParams.totalBullets * deployParams.bulletPrice;
            deployParams.totalBullets = maxBullet;
            deployParams.bulletPrice = value / maxBullet;
        }
        //too old timestamp just append 12 hours, which happens when creator set
        // a narrow ddl and layerzero relayer have a heavy network.But to avoid long time price loss of nft, creator will try set a so closed ddl.
        // so just make game near timeout
        if (deployParams.ddl <= block.timestamp) {
            deployParams.ddl = uint64(block.timestamp) + 1;
        }
        // @notice validator params should only be guaranteed by application, so wrong params have to revoke message itself
    }

    function _createHuntGame() internal returns (address _game) {
        prepareSubBridgeParam();
        require(deployParams.ddl > block.timestamp, "ERR_DDL");
        require(deployParams.totalBullets > 0, "ERR_BULLET");
        require(
            deployParams.totalBullets <=
                getBulletOracle.getMaxBullet(
                    msg.sender == address(getHuntBridge) ? deployParams.owner : msg.sender,
                    deployParams.originChain,
                    deployParams.nftContract
                ),
            "TOO_LARGE_BULLET"
        );
        if (msg.sender != address(getHuntBridge)) {
            //bridge already paid in sub chain
            getFeeManager.payBaseFee{ value: msg.value }();
        }
        _game = _deploy(deployParams);
        getGameById[deployParams.gameId] = _game;
        isHuntGame[_game] = true;
        emit HuntGameCreated(
            deployParams.owner,
            _game,
            deployParams.gameId,
            address(deployParams.hunterValidator),
            deployParams.nftStandard,
            deployParams.totalBullets,
            deployParams.bulletPrice,
            deployParams.nftContract,
            deployParams.originChain,
            deployParams.getPayment,
            deployParams.tokenId,
            deployParams.ddl,
            tempValidatorParams
        );
        if (deployParams.originChain == block.chainid) {
            //pay nft to the game and then start game
            _payNativeNFT(deployParams.nftStandard, deployParams.nftContract, deployParams.tokenId, _game);
            IHuntGame(_game).startHunt();
        }
    }

    function _payNativeNFT(
        IHuntGame.NFTStandard nftStandard,
        address nftContract,
        uint256 tokenId,
        address _recipient
    ) internal {
        if (nftStandard == IHuntGame.NFTStandard.GlobalERC721) {
            /// native chain
            IERC721(nftContract).transferFrom(msg.sender, _recipient, tokenId);
        } else if (nftStandard == IHuntGame.NFTStandard.GlobalERC1155) {
            IERC1155(nftContract).safeTransferFrom(msg.sender, _recipient, tokenId, 1, "");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function _initialize(address _vrfCoordinator) internal {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBulletOracle {
    function getMaxBullet(address _sender, uint64 _originChain, address _collection) external view returns (uint64);

    function baseLimit() external view returns (uint64);

    function getBulletLimitBySender(address _sender) external view returns (uint64);

    function getBulletLimitByCollection(uint64 _originChain, address _collection) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeManager {
    //********************EVENT*******************************//
    event Withdrawal(address payment, address account, uint256 amount);
    event ApproveAdded(address payment, address account, uint256 amount);
    event ApproveReduced(address payment, address account, uint256 amount);

    //********************FUNCTION*******************************//

    /// @dev pay the baseFee
    /// @notice the msg.value should be equal to baseFee
    function payBaseFee() external payable;

    /// @dev approve payment to spender.
    /// @notice  only allowed by owner.
    function addApprove(address payment, address spender, uint256 amount) external;

    /// @notice  only allowed by owner.
    function reduceApprove(address payment, address spender, uint256 amount) external;

    /// @dev set base fee of create a game, the payment is eth
    /// @notice only owner
    function setBaseFee(uint256 amount) external;

    /// @dev set factory to calc fee
    /// @notice only owner, factor<=100
    function setFactor(uint256 factor) external;

    /// @dev withdraw if have enough allowance
    function withdraw(address payment, uint256 amount) external;

    /// @dev calc fee
    function calcFee(uint256 amount) external view returns (uint256);

    function baseFee() external view returns (uint256);

    function getFactor() external view returns (uint256);

    function allowance(address payment, address spender) external view returns (uint256);

    function totalBaseFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGlobalNftDeployer {
    //********************EVENT*******************************//
    event GlobalNftMinted(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);
    event GlobalNftBurned(uint64 originChain, bool isERC1155, address originAddr, uint256 tokenId, address globalAddr);

    //********************FUNCTION*******************************//
    function calcAddr(uint64 originChain, address originAddr) external view returns (address);

    function tokenURI(address globalNft, uint256 tokenId) external view returns (string memory);

    function isGlobalNft(address collection) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Types.sol";
import "./IGlobalNftDeployer.sol";

/**huntnft
 * @title the interface hunt main bridge which is used to receive msg from sub bridge and send withdraw method to sub bridge
 */
interface IHuntBridge is IGlobalNftDeployer {
    //********************EVENT*******************************//
    event NftTransfer(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient
    );
    event NftDepositFinalized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    //withdraw initialized event
    event NftWithdrawInitialized(
        uint64 originChain,
        bool isErc1155,
        address indexed nft,
        uint256 tokenId,
        address indexed from,
        address recipient,
        bytes extraData,
        uint64 nonce
    );

    // dao event
    event SubBridgeInfoChanged(uint64[] _originChains, address[] _addrs);
    event Paused(bool);

    //********************FUNCTION*******************************//

    /**
     * @dev owener of nft withdraw nft to recipient located at it's src network
     * @param originChain origin chain id of nft
     * @param addr nft address
     * @param tokenId tokenId
     * @param recipient recipient address of nft origin network
     * @param refund refund account who receive the lz refund
     */
    function withdraw(
        uint64 originChain,
        address addr,
        uint256 tokenId,
        address recipient,
        address payable refund
    ) external payable;

    /**
     * @dev set subbridge info lz chainId => subBridge
     * @param _originChains a slice of various origin chainId
     * @param _addrs a slice of subBridge of specific lz chainId
     * @notice only owner
     */
    function setSubBridgeInfo(uint64[] calldata _originChains, address[] calldata _addrs) external;

    /// @return get sub bridge address by lz id
    function getSubBridgeByLzId(uint16 lzId) external view returns (address);

    /// @return get layerzero id by chainId
    function getLzIdByChainId(uint64 chainId) external view returns (uint16);

    /// @return estimate fee for withdraw nft back to origin chain
    function estimateFees(uint64 destChainId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IHuntGameValidator.sol";

/**huntnft
 * @title the interface manage the asset that user deposited, which can be used when hunt game fulfilled user's condition
 * by IHuntGameValidator
 */
interface IHunterAssetManager {
    //********************EVENT*******************************//
    /// @notice if payment is zero, means native token
    event HunterAssetUsed(address indexed _hunter, address _huntGame, address _payment, uint256 _value);
    event HunterAssetDeposited(address indexed _hunter, address _payment, uint256 _value);
    event HunterAssetWithdrawal(address indexed _hunter, address _payment, uint256 _value);
    event HuntGameValidatorChanged(address indexed _hunter, address _huntGameValidator);
    event OfficialHuntGameValidatorChanged(uint8 _type, address _huntGameValidator);

    //********************FUNCTION*******************************//
    /**
     * @dev help a hunter to participate in a hunt game with bullet
     * @param _hunter choose a hunter to try to participate in a hunt game
     * @param _huntGame the hunt game that want to participate in
     * @param _bullet the bullet num try to buy
     * @notice the hunt game should record in huntnft factory;the asset manager will check the hunt using IHuntGameValidator.isHuntGamePermitted,and then
     * need to invoke IHuntGameValidator.afterValidated to change state if needed.
     */
    function hunt(address _hunter, IHuntGame _huntGame, uint64 _bullet) external;

    /**
     * @dev hunter try to deposit payment token to asset manager
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to deposit
     */
    function deposit(address _payment, uint256 _value) external;

    /// @dev same, but support help others to deposit
    function deposit(address _hunter, address _payment, uint256 _value) external;

    /**
     * @dev deposit native token to asset manager
     */
    function deposit() external payable;

    ///@dev same, but help others to deposit
    function deposit(address _hunter) external payable;

    /**
     * dev withdraw token from asset manager, address(0) means native token
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to withdraw
     */
    function withdraw(address _payment, uint256 _value) external;

    /**
     * @dev user set its own hunt game validator to check the hunt game when try to
     * participate in a hunt game.If not set, just use official blue chip validator
     * @param _huntGameValidator the contract that realize the IHuntGameValidator interface
     * @notice all zero address means using official blue chip verifier
     */
    function setHuntGameValidator(IHuntGameValidator _huntGameValidator) external;

    /**
     * @dev set official hunt game validator
     * @param _huntGameValidator used for validate hunt game
     * @notice allowed by owner:
     * - 0: blue chip
     */
    function setOfficialValidator(uint8 _type, IHuntGameValidator _huntGameValidator) external;

    /// @return hunt game validator of hunter
    function getHuntGameValidator(address _hunter) external view returns (IHuntGameValidator);

    function officialValidator(uint8 _type) external view returns (IHuntGameValidator);

    function getBalance(address _hunter, address _payment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IHunterValidator is used for HuntGame to check whether a hunter is allowed to join hunt game.useful for whitelist
 */
interface IHunterValidator {
    /// @dev hunt game may register some info to validator when needed.
    /// @dev the params between register is stored in HuntNFTFactory.tempValidatorParams();
    function huntGameRegister() external;

    /**
     * @dev use validate to check the hunter, revert if check failed
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     * @notice check sender should be hunt game, just use HuntNFTFactory.isHuntGame(msg.sender);
     */
    function validateHunter(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external;

    /**
     * @dev hunt game check whether hunter can hunt on this game,the simply way is just use offline cert for hunter or
     * whitelist or check whether a hunter hold some kind of nft and so on
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     */
    function isHunterPermitted(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntNFTFactory.sol";
import "./IHunterValidator.sol";

struct HunterInfo {
    address hunter;
    uint64 bulletsAmountBefore;
    uint64 bulletNum;
    uint64 totalBullets;
    bool isFromAssetManager;
}

/**huntnft
 * @title interface of HuntGame contract
 */
interface IHuntGame {
    /**
     * @dev NFTStandard, now support standard ERC721, ERC1155
     */
    enum NFTStandard {
        GlobalERC721,
        GlobalERC1155
    }

    enum Status {
        Depositing,
        Hunting,
        Waiting,
        Timeout,
        Unclaimed,
        Claimed
    }

    //********************EVENT*******************************//
    /// emit when hunt game started, allowing hunter to hunt
    event Hunting();

    /// emit when hunter hunt in game
    event Hunted(uint64 hunterIndex, HunterInfo hunterInfo);

    /// emit when all bullet sold out, and wait for VRF
    event Waiting();

    /// emit when timeout, game is over
    event Timeout();

    /// emit when timeout and hunter withdraw asset back
    event HunterWithdrawal(uint64[] hunterIndexes);

    /// emit when NFT claimed to recipient either winner or owner of nft
    event NFTClaimed(address recipient);

    /// emit when VRF arrived, so winner is chosen, but nft and reward of owner is unclaimed
    event Unclaimed();

    /// all claimed, game is over
    event Claimed();

    /// emit when game creator claimed the reward
    event OwnerPaid();

    //********************FUNCTION*******************************//

    /**
     * @dev start hunt game when NFT is indeed owned by hunt game contract
     * @notice anyone can invoke this contract, be sure transfer exactly right contract
     */
    function startHunt() external;

    /**
     * @dev hunter hunt game by buy bullet to this game
     * @param bullet bullet num hunter try to buy
     * @notice only in hunting period and hunter should be permitted
     * if hunt game has hunter validator
     */
    function hunt(uint64 bullet) external payable;

    /// @dev same, can fulfill the payload
    function hunt(address hunter, uint64 bullet, bool _isFromAssetManager, bytes calldata payload) external payable;

    /**
     * @dev buy bullet in native token(ETH), hunter need bullet to hunt nft, just like tickets in raffle
     * @param hunter hunter
     * @param bullet bullet num
     * @param minNum how much bullet at least, tolerate async of action
     * @param isFromAssetManager whether to refund to asset manager
     * @param payload useful for hunter verify extension
     * @notice require :
     * - hunt game do accept native token
     * - hunt game is in hunting period
     */
    function huntInNative(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external payable returns (uint64);

    /// @dev same, but accept erc20
    function hunt(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external returns (uint64);

    /// @dev claim timeout when in hunting period and waiting period
    /// @notice only block.timestamp beyond the ddl and in hunting and waiting period
    function claimTimeout() external;

    /**
     * @dev withdraw bullet when timeout.the asset form HunterAssetManager will return back to HunterAssetManager.Others
     * just return back to users wallet
     * @param _hunterIndexes a set of hunter index prepared to withdraw
     * @notice if hunter already withdraw in provided index, just revert
     */
    function timeoutWithdrawBullets(uint64[] memory _hunterIndexes) external;

    /// @dev withdraw nft to creator when game timeout.The nft deposited from other chain will be returned back.
    /// @notice only in timeout period and the nft should not paid in twice.
    function timeoutWithdrawNFT() external payable;

    /// @dev same but can chose to keep in this network other than withdraw back to origin chain
    function timeoutClaimNFT(bool withdraw) external payable;

    /**
     * @dev claim nft with winner index.The NFT will be transferred to winner by native chain  or bridge.
     * @param _winnerIndex winner index which can get by getWinnerIndex method.
     * @notice only allowed when random num is filled and game is in unclaimed status,and do not try to claim twice
     */
    function claimNft(uint64 _winnerIndex) external payable;

    /// @dev same, but do not withdraw in other chain, just transfer to winner
    function claimNft(uint64 _winnerIndex, bool _withdraw) external payable;

    /**
     * @dev claim hunt game reward to the creator
     * @notice only allowed when in unclaimed status, and do not try to claim twice
     */
    function claimReward() external;

    /// @return get winner index
    /// @notice revert if random num is not filled yet
    function getWinnerIndex() external view returns (uint64);

    /// @return check hunter has the right to hunt in this game
    function canHunt(address hunter, uint64 bullet) external view returns (bool);

    /// @dev same
    function canHunt(address sender, address hunter, uint64 bullet, bytes memory payload) external view returns (bool);

    function factory() external view returns (IHuntNFTFactory);

    function gameId() external view returns (uint64);

    function owner() external view returns (address);

    function validator() external view returns (IHunterValidator);

    function ddl() external view returns (uint64);

    function bulletPrice() external view returns (uint256);

    function totalBullets() external view returns (uint64);

    function getPayment() external view returns (address);

    function nftStandard() external view returns (NFTStandard);

    function nftContract() external view returns (address);

    function tokenId() external view returns (uint256);

    function status() external view returns (Status);

    function tempHunters(
        uint256 index
    )
        external
        view
        returns (
            address hunter,
            uint64 bulletsAmountBefore,
            uint64 bulletNum,
            uint64 totalBullets,
            bool isFromAssetManager
        );

    function randomNum() external view returns (uint256);

    function requestId() external view returns (uint256);

    function winner() external view returns (address);

    function nftPaid() external view returns (bool);

    function ownerPaid() external view returns (bool);

    function leftBullet() external view returns (uint64);

    function estimateFees() external view returns (uint256);

    function userNonce() external view returns (uint256);

    function originChain() external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IHunterValidator.sol";
import "./IHuntGame.sol";
import "./IHuntNFTFactory.sol";

interface IHuntGameDeployer {
    function getPendingGame(address creator) external view returns (address);

    function calcGameAddr(address creator, uint256 nonce) external view returns (address);

    function userNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**huntnft
 * @title interface of IHuntGameRandomRequester
 * @dev this specify the action of random oracle feed the request of hunt game
 */

interface IHuntGameRandomRequester {
    /**
     * @dev ChainLink VRF fill random word to hunt game
     * @param _randomNum random word filled from ChainLink
     * @notice only invoked by factory
     */
    function fillRandom(uint256 _randomNum) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IHuntGame.sol";

/**huntnft
 * @title hunt game validator is use for hunter's asset in HuntAsseManager to check whether to join a hunt game with bullet
 */
interface IHuntGameValidator is IERC165 {
    /**
     * @dev validate hunt game and may change the status
     * @param _huntGame hunt game contract, the role is already checked before
     * @param _sender sender to want to move asset of hunter
     * @param _hunter hunter
     * @param _bullet  bullet num prepare to buy at that game
     * @notice this function should only be called by hunt asset manager.
     */
    function validateGame(IHuntGame _huntGame, address _sender, address _hunter, uint64 _bullet) external;

    /**
     * @dev this is used for hunter to check the condition of a hunt game that want to join in
     * @param _huntGame hunt game contract that want to consume the hunter's asset, the role aleady checked before
     * @param _sender sender to want to move asset of hunter
     * @param _hunter hunter
     * @param _bullet bullet num prepare to buy at that game
     */
    function isHuntGamePermitted(
        IHuntGame _huntGame,
        address _sender,
        address _hunter,
        uint64 _bullet
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntBridge.sol";
import "./IHunterAssetManager.sol";
import "./IFeeManager.sol";
import "./IHunterValidator.sol";
import "./IHuntGameDeployer.sol";

/**huntnft
 * @title interface of HuntNFTFactory
 */
interface IHuntNFTFactory {
    //********************EVENT*******************************//
    event HuntGameCreated(
        address indexed owner,
        address game,
        uint64 indexed gameId,
        address indexed hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes validatorParams
    );

    //********************FUNCTION*******************************//

    /**
     * @dev create hunt game with native token payment(hunter need eth to buy bullet)
     * @param gameOwner owner of game
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param nftContract nft
     * @param originChain origin chain id of nft
     * @param tokenId token id of nft
     * @param ddl the ddl of game,
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice required:
     * - totalBullets should less than 10_000 and large than 0
     * - ddl should larger than block.timestamp, if not, which is useless
     * - sender should approve nft first if nft is in local network.
     * - sender have enough baseFee paied to feeManager the fee is used for VRF and oracle service(such as help offline-users and so on).
     */
    function createETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /**
     * @dev create hunt game with erc20 payment
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param  nftContract nft
     * @param originChain origin chain id of nft
     * @param payment the erc20 used to buy bullet, now only support usdt
     * @param tokenId token id of nft
     * @param ddl the ddl of game
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice creator should pay the fee to create a game, the fee is used for VRF and oracle service(such as help offline-users).
     * payment should be in whitelist, which prevent malicious attach hunters.
     */
    function createHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /// @dev pay the nft as well
    /// @notice approve factory first
    function createWithPayETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable;

    /**
     * @dev request random words from ChainLink VRF
     * @return requestId the requestId of VRF
     * @notice only hunt game can invoke, and the questId should never be used before
     */
    function requestRandomWords() external returns (uint256 requestId);

    /**
     * @dev hunt game transfer erc20 from a hunter to its game
     * @dev _hunter the hunter who want to participate in hunt game
     * @dev _erc20 erc20 token
     * @dev _amount erc20 amount
     * @notice only allowed by hunt game, which guarantee the logic is right
     */
    function huntGameClaimPayment(address _hunter, address _erc20, uint256 _amount) external;

    function isHuntGame(address _addr) external view returns (bool);

    function getGameById(uint64 _gameId) external view returns (address);

    function isPaymentEnabled(address _erc20) external view returns (bool);

    function getHuntBridge() external view returns (IHuntBridge);

    function getHunterAssetManager() external view returns (IHunterAssetManager);

    function getFeeManager() external view returns (IFeeManager);

    function totalGames() external view returns (uint64);

    function tempValidatorParams() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Consts {
    bytes1 constant FLAG_ERC721 = bytes1(uint8(0));
    bytes1 constant FLAG_ERC1155 = bytes1(uint8(1));

    bytes32 constant BEACON_PROXY_CODE_HASH = 0x3f74a55adef768b97d182c8a1b516d04f0c3e0c4c1b1b534037d7c6104a39a2b;
    address constant CREATE_GAME_RECIPIENT = address(0xAAAA00000000000000000000000000000000aaaa);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interface/IHuntBridge.sol";
import "../interface/IGlobalNftDeployer.sol";

library GlobalNftLib {
    function transfer(
        IHuntBridge bridge,
        uint64 originChain,
        bool isErc1155,
        address addr,
        uint256 tokenId,
        address recipient,
        bool withdraw
    ) internal {
        address nft = originChain == block.chainid ? addr : bridge.calcAddr(originChain, addr);
        if (originChain == block.chainid || !withdraw) {
            /// native chain or dont want to withdraw
            if (isErc1155) {
                IERC1155(nft).safeTransferFrom(address(this), recipient, tokenId, 1, "");
            } else {
                IERC721(nft).transferFrom(address(this), recipient, tokenId);
            }
        } else {
            if (isErc1155) {
                IERC1155(nft).setApprovalForAll(address(bridge), true);
            } else {
                IERC721(nft).approve(address(bridge), tokenId);
            }
            bridge.withdraw{ value: msg.value }(originChain, addr, tokenId, recipient, payable(msg.sender));
        }
    }

    function isOwned(
        IHuntBridge bridge,
        uint64 originChain,
        bool isErc1155,
        address addr,
        uint256 tokenId
    ) internal view returns (bool) {
        address nft = originChain == block.chainid ? addr : bridge.calcAddr(originChain, addr);
        if (isErc1155) {
            return IERC1155(nft).balanceOf(address(this), tokenId) == 1;
        } else {
            return IERC721(nft).ownerOf(tokenId) == address(this);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Consts.sol";

library Types {
    function toHex(address addr) internal pure returns (string memory) {
        bytes memory ret = new bytes(42);
        uint ptr;
        assembly {
            mstore(add(ret, 0x20), "0x")
            ptr := add(ret, 0x22)
        }
        for (uint160 i = 0; i < 20; i++) {
            uint160 n = (uint160(addr) & (uint160(0xff) << ((20 - 1 - i) * 8))) >> ((20 - 1 - i) * 8);
            uint first = (n / 16);
            uint second = n % 16;
            bytes1 symbol1 = hexByte(first);
            bytes1 symbol2 = hexByte(second);
            assembly {
                mstore(ptr, symbol1)
                ptr := add(ptr, 1)
                mstore(ptr, symbol2)
                ptr := add(ptr, 1)
            }
        }
        return string(ret);
    }

    function hexByte(uint i) internal pure returns (bytes1) {
        require(i < 16, "wrong hex");
        if (i < 10) {
            // number ascii start from 48
            return bytes1(uint8(48 + i));
        }
        // charactor ascii start from 97
        return bytes1(uint8(97 + i - 10));
    }

    function encodeAdapterParams(uint64 extraGas) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes2(0x0001), uint256(extraGas));
    }

    function encodeNftBridgeParams(
        uint256 srcChainId,
        bool isERC1155,
        address addr,
        uint256 tokenId,
        address from,
        address recipient,
        bytes memory extraData
    ) internal pure returns (bytes memory) {
        require(srcChainId < type(uint64).max, "too large chain id");
        bytes1 flag = isERC1155 ? Consts.FLAG_ERC1155 : Consts.FLAG_ERC721;
        return abi.encodePacked(flag, abi.encode(uint64(srcChainId), addr, tokenId, from, recipient, extraData));
    }

    function decodeNftBridgeParams(
        bytes calldata data
    )
        internal
        pure
        returns (
            uint64 srcChainId,
            bool isERC1155,
            address addr,
            uint256 tokenId,
            address from,
            address recipient,
            bytes memory extraData
        )
    {
        bytes1 flag = bytes1(data);
        require(uint8(flag) <= 1);
        isERC1155 = flag == Consts.FLAG_ERC1155;
        (srcChainId, addr, tokenId, from, recipient, extraData) = abi.decode(
            data[1:data.length],
            (uint64, address, uint256, address, address, bytes)
        );
    }
}