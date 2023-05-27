// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
library EnumerableSetUpgradeable {
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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
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
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
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
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
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
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

// Used for calculating decimal-point percentages (10000 = 100%)
uint256 constant PERCENTAGE_RANGE = 10000;

// Pauser Role - Can pause the game
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

// Minter Role - Can mint items, NFTs, and ERC20 currency
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

// Manager Role - Can manage the shop, loot tables, and other game data
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

// Game Logic Contract - Contract that executes game logic and accesses other systems
bytes32 constant GAME_LOGIC_CONTRACT_ROLE = keccak256(
    "GAME_LOGIC_CONTRACT_ROLE"
);

// Game Currency Contract - Allowlisted currency ERC20 contract
bytes32 constant GAME_CURRENCY_CONTRACT_ROLE = keccak256(
    "GAME_CURRENCY_CONTRACT_ROLE"
);

// Game NFT Contract - Allowlisted game NFT ERC721 contract
bytes32 constant GAME_NFT_CONTRACT_ROLE = keccak256("GAME_NFT_CONTRACT_ROLE");

// Game Items Contract - Allowlist game items ERC1155 contract
bytes32 constant GAME_ITEMS_CONTRACT_ROLE = keccak256(
    "GAME_ITEMS_CONTRACT_ROLE"
);

// Depositor role - used by Polygon bridge to mint on child chain
bytes32 constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

// Randomizer role - Used by the randomizer contract to callback
bytes32 constant RANDOMIZER_ROLE = keccak256("RANDOMIZER_ROLE");

// Trusted forwarder role - Used by meta transactions to verify trusted forwader(s)
bytes32 constant TRUSTED_FORWARDER_ROLE = keccak256("TRUSTED_FORWARDER_ROLE");

// =====
// All of the possible traits in the system
// =====

/// @dev Trait that points to another token/template id
uint256 constant TEMPLATE_ID_TRAIT_ID = uint256(keccak256("template_id"));

// Generation of a token
uint256 constant GENERATION_TRAIT_ID = uint256(keccak256("generation"));

// XP for a token
uint256 constant XP_TRAIT_ID = uint256(keccak256("xp"));

// Current level of a token
uint256 constant LEVEL_TRAIT_ID = uint256(keccak256("level"));

// Whether or not a token is a pirate
uint256 constant IS_PIRATE_TRAIT_ID = uint256(keccak256("is_pirate"));

// Whether or not a token is a ship
uint256 constant IS_SHIP_TRAIT_ID = uint256(keccak256("is_ship"));

// Whether or not an item is equippable on ships
uint256 constant EQUIPMENT_TYPE_TRAIT_ID = uint256(keccak256("equipment_type"));

// Combat modifiers for items and tokens
uint256 constant COMBAT_MODIFIERS_TRAIT_ID = uint256(
    keccak256("combat_modifiers")
);

// Animation URL for the token
uint256 constant ANIMATION_URL_TRAIT_ID = uint256(keccak256("animation_url"));

// Item slots
uint256 constant ITEM_SLOTS_TRAIT_ID = uint256(keccak256("item_slots"));

// Rank of the ship
uint256 constant SHIP_RANK_TRAIT_ID = uint256(keccak256("ship_rank"));

// Current Health trait
uint256 constant CURRENT_HEALTH_TRAIT_ID = uint256(keccak256("current_health"));

// Health trait
uint256 constant HEALTH_TRAIT_ID = uint256(keccak256("health"));

// Damage trait
uint256 constant DAMAGE_TRAIT_ID = uint256(keccak256("damage"));

// Speed trait
uint256 constant SPEED_TRAIT_ID = uint256(keccak256("speed"));

// Accuracy trait
uint256 constant ACCURACY_TRAIT_ID = uint256(keccak256("accuracy"));

// Evasion trait
uint256 constant EVASION_TRAIT_ID = uint256(keccak256("evasion"));

// Image hash of token's image, used for verifiable / fair drops
uint256 constant IMAGE_HASH_TRAIT_ID = uint256(keccak256("image_hash"));

// Name of a token
uint256 constant NAME_TRAIT_ID = uint256(keccak256("name_trait"));

// Description of a token
uint256 constant DESCRIPTION_TRAIT_ID = uint256(keccak256("description_trait"));

// General rarity for a token (corresponds to IGameRarity)
uint256 constant RARITY_TRAIT_ID = uint256(keccak256("rarity"));

// The character's affinity for a specific element
uint256 constant ELEMENTAL_AFFINITY_TRAIT_ID = uint256(
    keccak256("affinity_id")
);

// The character's expertise value
uint256 constant EXPERTISE_TRAIT_ID = uint256(keccak256("expertise"));

// Expertise damage mod ID from SoT
uint256 constant EXPERTISE_DAMAGE_ID = uint256(
    keccak256("expertise.multiplierperlevel.damage")
);

// Expertise evasion mod ID from SoT
uint256 constant EXPERTISE_EVASION_ID = uint256(
    keccak256("expertise.multiplierperlevel.evasion")
);

// Expertise speed mod ID from SoT
uint256 constant EXPERTISE_SPEED_ID = uint256(
    keccak256("expertise.multiplierperlevel.speed")
);

// Expertise accuracy mod ID from SoT
uint256 constant EXPERTISE_ACCURACY_ID = uint256(
    keccak256("expertise.multiplierperlevel.accuracy")
);

// Expertise health mod ID from SoT
uint256 constant EXPERTISE_HEALTH_ID = uint256(
    keccak256("expertise.multiplierperlevel.health")
);

// Boss start time trait
uint256 constant BOSS_START_TIME_TRAIT_ID = uint256(
    keccak256("boss_start_time")
);

// Boss end time trait
uint256 constant BOSS_END_TIME_TRAIT_ID = uint256(keccak256("boss_end_time"));

// Boss type trait
uint256 constant BOSS_TYPE_TRAIT_ID = uint256(keccak256("boss_type"));

// The character's dice rolls
uint256 constant DICE_ROLL_1_TRAIT_ID = uint256(keccak256("dice_roll_1"));
uint256 constant DICE_ROLL_2_TRAIT_ID = uint256(keccak256("dice_roll_2"));

// The character's star sign (astrology)
uint256 constant STAR_SIGN_TRAIT_ID = uint256(keccak256("star_sign"));

// Image for the token
uint256 constant IMAGE_TRAIT_ID = uint256(keccak256("image_trait"));

// How much energy the token provides if used
uint256 constant ENERGY_PROVIDED_TRAIT_ID = uint256(
    keccak256("energy_provided")
);

// Whether a given token is soulbound, meaning it is unable to be transferred
uint256 constant SOULBOUND_TRAIT_ID = uint256(keccak256("soulbound"));

// ------
// Avatar Profile Picture related traits

// If an avatar is a 1 of 1, this is their only trait
uint256 constant PROFILE_IS_LEGENDARY_TRAIT_ID = uint256(
    keccak256("profile_is_legendary")
);

// Avatar's archetype -- possible values: Human (including Druid, Mage, Berserker, Crusty), Robot, Animal, Zombie, Vampire, Ghost
uint256 constant PROFILE_CHARACTER_TYPE = uint256(
    keccak256("profile_character_type")
);

// Avatar's profile picture's background image
uint256 constant PROFILE_BACKGROUND_TRAIT_ID = uint256(
    keccak256("profile_background")
);

// Avatar's eye style
uint256 constant PROFILE_EYES_TRAIT_ID = uint256(keccak256("profile_eyes"));

// Avatar's facial hair type
uint256 constant PROFILE_FACIAL_HAIR_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's hair style
uint256 constant PROFILE_HAIR_TRAIT_ID = uint256(keccak256("profile_hair"));

// Avatar's skin color
uint256 constant PROFILE_SKIN_TRAIT_ID = uint256(keccak256("profile_skin"));

// Avatar's coat color
uint256 constant PROFILE_COAT_TRAIT_ID = uint256(keccak256("profile_coat"));

// Avatar's earring(s) type
uint256 constant PROFILE_EARRING_TRAIT_ID = uint256(
    keccak256("profile_facial_hair")
);

// Avatar's eye covering
uint256 constant PROFILE_EYE_COVERING_TRAIT_ID = uint256(
    keccak256("profile_eye_covering")
);

// Avatar's headwear
uint256 constant PROFILE_HEADWEAR_TRAIT_ID = uint256(
    keccak256("profile_headwear")
);

// Avatar's (Mages only) gem color
uint256 constant PROFILE_MAGE_GEM_TRAIT_ID = uint256(
    keccak256("profile_mage_gem")
);

// ------
// Dungeon traits

// Whether this token template is a dungeon trigger
uint256 constant IS_DUNGEON_TRIGGER_TRAIT_ID = uint256(
    keccak256("is_dungeon_trigger")
);

// Dungeon start time trait
uint256 constant DUNGEON_START_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.start_time")
);

// Dungeon end time trait
uint256 constant DUNGEON_END_TIME_TRAIT_ID = uint256(
    keccak256("dungeon.end_time")
);

// Dungeon SoT map id trait
uint256 constant DUNGEON_MAP_TRAIT_ID = uint256(keccak256("dungeon.map_id"));

// Whether this token template is a mob
uint256 constant IS_MOB_TRAIT_ID = uint256(keccak256("is_mob"));

// ------
// Island traits

// Whether a game item is placeable on an island
uint256 constant IS_PLACEABLE_TRAIT_ID = uint256(keccak256("is_placeable"));

// The size of an item.
uint256 constant ITEM_SIZE_TRAIT_ID = uint256(keccak256("item_size"));

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@opengsn/contracts/src/interfaces/IERC2771Recipient.sol";

import {PERCENTAGE_RANGE, TRUSTED_FORWARDER_ROLE} from "./Constants.sol";

import {ISystem} from "./core/ISystem.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "./interfaces/ITraitsProvider.sol";
import {ILockingSystem, ID as LOCKING_SYSTEM_ID} from "./locking/ILockingSystem.sol";
import {IRandomizer, IRandomizerCallback, ID as RANDOMIZER_ID} from "./randomizer/IRandomizer.sol";
import {ILootSystem, ID as LOOT_SYSTEM_ID} from "./loot/ILootSystem.sol";
import {IGameRegistry, IERC165} from "./core/IGameRegistry.sol";

/** @title Contract that lets a child contract access the GameRegistry contract */
abstract contract GameRegistryConsumerUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC2771Recipient,
    IRandomizerCallback,
    ISystem
{
    /// @notice Whether or not the contract is paused
    bool private _paused;

    /// @notice Reference to the game registry that this contract belongs to
    IGameRegistry internal _gameRegistry;

    /// @notice Id for the system/component
    uint256 private _id;

    /** EVENTS **/

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /** ERRORS **/

    /// @notice Not authorized to perform action
    error MissingRole(address account, bytes32 expectedRole);

    /** MODIFIERS **/

    /// @notice Modifier to verify a user has the appropriate role to call a given function
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
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

    /** ERRORS **/

    /// @notice Error if the game registry specified is invalid
    error InvalidGameRegistry();

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     * @param id                  Id of the system/component
     */
    function __GameRegistryConsumer_init(
        address gameRegistryAddress,
        uint256 id
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();

        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }

        _paused = true;
        _id = id;
    }

    /** @return ID for this system */
    function getId() public view override returns (uint256) {
        return _id;
    }

    /**
     * Pause/Unpause the contract
     *
     * @param shouldPause Whether or pause or unpause
     */
    function setPaused(bool shouldPause) external onlyOwner {
        if (shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Returns true if the contract OR the GameRegistry is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused || _gameRegistry.paused();
    }

    /**
     * Sets the GameRegistry contract address for this contract
     *
     * @param gameRegistryAddress  Address for the GameRegistry contract
     */
    function setGameRegistry(address gameRegistryAddress) external onlyOwner {
        _gameRegistry = IGameRegistry(gameRegistryAddress);

        if (gameRegistryAddress == address(0)) {
            revert InvalidGameRegistry();
        }
    }

    /** @return GameRegistry contract for this contract */
    function getGameRegistry() external view returns (IGameRegistry) {
        return _gameRegistry;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(
        address forwarder
    ) public view virtual override(IERC2771Recipient) returns (bool) {
        return
            address(_gameRegistry) != address(0) &&
            _hasAccessRole(TRUSTED_FORWARDER_ROLE, forwarder);
    }

    /**
     * Callback for when a random number request has returned with random words
     *
     * @param requestId     Id of the request
     * @param randomWords   Random words
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external virtual override {
        // Do nothing by default
    }

    /** INTERNAL **/

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasAccessRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _gameRegistry.hasAccessRole(role, account);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_gameRegistry.hasAccessRole(role, account)) {
            revert MissingRole(account, role);
        }
    }

    /** @return Returns the traits provider for this contract */
    function _traitsProvider() internal view returns (ITraitsProvider) {
        return ITraitsProvider(_getSystem(TRAITS_PROVIDER_ID));
    }

    /** @return Interface to the LockingSystem */
    function _lockingSystem() internal view returns (ILockingSystem) {
        return ILockingSystem(_gameRegistry.getSystem(LOCKING_SYSTEM_ID));
    }

    /** @return Interface to the LootSystem */
    function _lootSystem() internal view returns (ILootSystem) {
        return ILootSystem(_gameRegistry.getSystem(LOOT_SYSTEM_ID));
    }

    /** @return Interface to the Randomizer */
    function _randomizer() internal view returns (IRandomizer) {
        return IRandomizer(_gameRegistry.getSystem(RANDOMIZER_ID));
    }

    /** @return Address for a given system */
    function _getSystem(uint256 systemId) internal view returns (address) {
        return _gameRegistry.getSystem(systemId);
    }

    /**
     * Requests randomness from the game's Randomizer contract
     *
     * @param numWords Number of words to request from the VRF
     *
     * @return Id of the randomness request
     */
    function _requestRandomWords(uint32 numWords) internal returns (uint256) {
        return
            _randomizer().requestRandomWords(
                IRandomizerCallback(this),
                numWords
            );
    }

    /**
     * Returns the Player address for the Operator account
     * @param operatorAccount address of the Operator account to retrieve the player for
     */
    function _getPlayerAccount(
        address operatorAccount
    ) internal view returns (address playerAccount) {
        return _gameRegistry.getPlayerAccount(operatorAccount);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, IERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /** PAUSABLE **/

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
    function _pause() internal virtual {
        require(_paused == false, "Pausable: not paused");
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
    function _unpause() internal virtual {
        require(_paused == true, "Pausable: not paused");
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant MAX_UINT96 = 2 ** 96 - 1;

/** @title Entity related helpers **/
library EntityLibrary {
    /** ERRORS **/
    error TokenIdExceedsMaxValue(uint256 tokenId);

    /** INTERNAL **/

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address from a single uint256 which is the entity ID
     *
     * @return tokenAddress Address of the unpacked token
     */
    function entityToAddress(
        uint256 value
    ) internal pure returns (address tokenAddress) {
        tokenAddress = address(uint160(value));
        uint256 tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * Packs an address into a single uint256 entity
     *
     * @param addr    Address to convert to entity
     * @return Converted address to entity
     */
    function addressToEntity(address addr) internal pure returns (uint256) {
        return uint160(addr);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Unpacks a token address and token id from a single uint256
     *
     * @return tokenAddress Address of the unpacked token
     * @return tokenId      Id of the unpacked token
     */
    function entityToToken(
        uint256 value
    ) internal pure returns (address tokenAddress, uint256 tokenId) {
        tokenAddress = address(uint160(value));
        tokenId = uint256(value >> 160);
        uint256 verify = (tokenId << 160) | uint160(tokenAddress);
        require(verify == value);
    }

    /**
     * @dev Note this function will require the tokenId is < uint96.MAX
     * Packs a token address and token id into a single uint256
     *
     * @param tokenAddress  Address of the unpacked token
     * @param tokenId       Id of the unpacked token
     * @return              Token address and token id packed into single uint256
     */
    function tokenToEntity(
        address tokenAddress,
        uint256 tokenId
    ) internal pure returns (uint256) {
        if (tokenId > MAX_UINT96) {
            revert TokenIdExceedsMaxValue(tokenId);
        }
        return (tokenId << 160) | uint160(tokenAddress);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// @title Interface the game's ACL / Management Layer
interface IGameRegistry is IERC165 {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasAccessRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /** @return Whether or not the registry is paused */
    function paused() external view returns (bool);

    /**
     * Registers a system by id
     *
     * @param systemId          Id of the system
     * @param systemAddress     Address of the system contract
     */
    function registerSystem(uint256 systemId, address systemAddress) external;

    /** @return System based on an id */
    function getSystem(uint256 systemId) external view returns (address);

    /**
     * Registers a component using an id and contract address
     * @param componentId Id of the component to register
     * @param componentAddress Address of the component contract
     */
    function registerComponent(
        uint256 componentId,
        address componentAddress
    ) external;

    /** @return A component's contract address given its ID */
    function getComponent(uint256 componentId) external view returns (address);

    /** @return A component's id given its contract address */
    function getComponentIdFromAddress(
        address componentAddr
    ) external view returns (uint256);

    /**
     * Register a component value update.
     * Emits the `ComponentValueSet` event for clients to reconstruct the state.
     */
    function registerComponentValueSet(
        uint256 entity,
        bytes calldata data
    ) external;

    /**
     * Register a component value removal.
     * Emits the `ComponentValueRemoved` event for clients to reconstruct the state.
     */
    function registerComponentValueRemoved(uint256 entity) external;

    /**
     * Generate a new general-purpose entity GUID
     */
    function generateGUID() external returns (uint256);

    /** @return Authorized Player account for an address
     * @param operatorAddress   Address of the Operator account
     */
    function getPlayerAccount(
        address operatorAddress
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Defines a system the game engine
 */
interface ISystem {
    /** @return The ID for the system. Ex: a uint256 casted keccak256 hash */
    function getId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import {COMBAT_MODIFIERS_TRAIT_ID, EQUIPMENT_TYPE_TRAIT_ID, GAME_ITEMS_CONTRACT_ROLE} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {Item, IEquippable} from "./IEquippable.sol";

import "../GameRegistryConsumerUpgradeable.sol";

/**
 * @title Equippable
 *
 * @dev implement this to add equipment loadout management to a contract
 * @dev requires role GAME_LOGIC_CONTRACT_ROLE and MINTER_ROLE
 */
abstract contract Equippable is GameRegistryConsumerUpgradeable, IEquippable {
    /** ERRORS **/

    /// @notice Invalid item cannot be equipped by parent
    error InvalidItem(uint256 parentEntity, uint256 itemEntity);

    /// @notice Item cannot be equipped by invalid parent
    error InvalidParent();

    /// @notice Desired slot is invalid for item
    error InvalidSlot(uint256 slottedItemEntity, uint256 replaceItemEntity);

    /// @notice Desired slot index is invalid
    error InvalidSlotIndex(uint256 index);

    /** EXTERNAL **/

    /**
     * @inheritdoc IEquippable
     */
    function getCombatModifiers(
        uint256 parentEntity
    ) external view override returns (int256[] memory) {
        ITraitsProvider traitsProvider = _traitsProvider();

        // Get all slot types
        uint256[] memory slotTypes = _getSlotTypes(parentEntity);

        // Loop through slot types and get equipment loadout for each
        int256[] memory combatModifiers = new int256[](5);
        for (uint256 i = 0; i < slotTypes.length; i++) {
            uint256[] memory equipment = _getItems(
                parentEntity,
                slotTypes[i],
                traitsProvider
            );
            for (uint256 j = 0; j < equipment.length; j++) {
                // Get combat modifiers for item
                int256[] memory itemCombatModifiers = _getItemCombatModifiers(
                    equipment[j],
                    traitsProvider
                );

                // Add item combat modifiers to parent combat modifiers
                for (uint256 k = 0; k < itemCombatModifiers.length; k++) {
                    combatModifiers[k] += itemCombatModifiers[k];
                }
            }
        }

        return combatModifiers;
    }

    /**
     * @inheritdoc IEquippable
     */
    function getItems(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256[] memory) {
        return _getItems(parentEntity, slotType, _traitsProvider());
    }

    /**
     * @inheritdoc IEquippable
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) public view virtual returns (uint256);

    /**
     * @inheritdoc IEquippable
     */
    function removeItems(
        uint256 parentEntity,
        Item[] calldata items
    ) external whenNotPaused {
        address account = _getPlayerAccount(_msgSender());

        // Vaidate parentEntity belongs to caller
        if (!_isParentOwner(account, parentEntity)) {
            revert InvalidParent();
        }

        for (uint256 i = 0; i < items.length; ++i) {
            _removeItem(account, parentEntity, items[i], _traitsProvider());
        }
    }

    /**
     * @inheritdoc IEquippable
     */
    function setItems(
        uint256 parentEntity,
        uint256[] calldata existingItems,
        Item[] calldata items
    ) external whenNotPaused {
        address account = _getPlayerAccount(_msgSender());

        // Vaidate parentEntity belongs to caller
        if (!_isParentOwner(account, parentEntity)) {
            revert InvalidParent();
        }

        for (uint256 i = 0; i < items.length; ++i) {
            _setItem(
                account,
                parentEntity,
                existingItems[items[i].slotIndex],
                items[i]
            );
        }
    }

    /** INTERNAL **/

    /**
     * @dev Returns the equipment loadout at a parent entity's slotType, or initializes a new one
     */
    function _getItems(
        uint256 parentEntity,
        uint256 slotType,
        ITraitsProvider traitsProvider
    ) internal view returns (uint256[] memory) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );

        // Pull current slots from trait provider or initialize new array if no trait exists
        return
            traitsProvider.hasTrait(tokenContract, tokenId, slotType)
                ? traitsProvider.getTraitUint256Array(
                    tokenContract,
                    tokenId,
                    slotType
                )
                : new uint256[](getSlotCount(parentEntity, slotType));
    }

    /**
     * @dev Returns the combat modifiers for an item
     */
    function _getItemCombatModifiers(
        uint256 itemEntity,
        ITraitsProvider traitsProvider
    ) internal view returns (int256[] memory) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            itemEntity
        );

        // Return combat modifiers for item if it has them
        return
            traitsProvider.hasTrait(
                tokenContract,
                tokenId,
                COMBAT_MODIFIERS_TRAIT_ID
            )
                ? traitsProvider.getTraitInt256Array(
                    tokenContract,
                    tokenId,
                    COMBAT_MODIFIERS_TRAIT_ID
                )
                : new int256[](5);
    }

    /**
     * @dev Returns the slot types available for a parent entity
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     */
    function _getSlotTypes(
        uint256 parentEntity
    ) internal view virtual returns (uint256[] memory);

    /**
     * @dev Function to override with custom validation logic
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     * @param item Item params which specify entity, slot type, and slot index to remove
     * @param traitsProvider Reference to TraitsProvider system for reading traits
     */
    function _isItemEquippable(
        uint256 parentEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal virtual returns (bool);

    /**
     * @dev Returns boolean representing if account is the owner of parent
     */
    function _isParentOwner(
        address account,
        uint256 parentEntity
    ) internal view returns (bool) {
        (address parentContract, uint256 parentTokenId) = EntityLibrary
            .entityToToken(parentEntity);
        return IERC721(parentContract).ownerOf(parentTokenId) == account;
    }

    /**
     * @dev Reverts if an item is not safe to equip to parent
     */
    function _requireValidItem(
        address account,
        uint256 parentEntity,
        uint256 existingItemEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            item.itemEntity
        );

        // Ensure item a burnable game item; for now must be ERC1155
        // Also requires item to implement TraitConsumer which aids in reading traits
        if (_hasAccessRole(GAME_ITEMS_CONTRACT_ROLE, tokenContract) == false) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Check if parent is owner of item
        if (IERC1155(tokenContract).balanceOf(account, tokenId) == 0) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Check if valid slot index for parent
        if (getSlotCount(parentEntity, item.slotType) <= item.slotIndex) {
            revert InvalidSlotIndex(item.slotIndex);
        }

        // Check if slot is occupied; if so it must match existingItemEntity
        uint256[] memory slots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );
        if (
            slots[item.slotIndex] != 0 &&
            slots[item.slotIndex] != existingItemEntity
        ) {
            revert InvalidSlot(slots[item.slotIndex], existingItemEntity);
        }

        // Check item has `equipment_type` trait
        if (
            !traitsProvider.hasTrait(
                tokenContract,
                tokenId,
                EQUIPMENT_TYPE_TRAIT_ID
            )
        ) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Run custom validation checks:
        // > Check that item is valid for parent
        // > Check that slot type is valid for implementor
        if (!_isItemEquippable(parentEntity, item, traitsProvider)) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }
    }

    /**
     * @dev Safely sets an item to parent entity at slotType and slotIndex
     */
    function _setItem(
        address account,
        uint256 parentEntity,
        uint256 existingItemEntity,
        Item calldata item
    ) internal {
        ITraitsProvider traitsProvider = _traitsProvider();
        uint256[] memory currentSlots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );

        // Validate item and parent are compatible
        _requireValidItem(
            account,
            parentEntity,
            existingItemEntity,
            item,
            traitsProvider
        );

        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            item.itemEntity
        );

        // Burn the item when storing it in a slot
        ERC1155Burnable(tokenContract).burn(account, tokenId, 1);

        // For now we do not mint items back to the user, but we can someday
        // Check if slot is occupied and remove it if so
        // if (currentSlots[item.slotIndex] != 0) {
        //     _removeItem(
        //         account,
        //         parentEntity,
        //         Item({
        //             itemEntity: currentSlots[item.slotIndex],
        //             slotType: item.slotType,
        //             slotIndex: item.slotIndex
        //         }),
        //         traitsProvider
        //     );
        // }

        // Set item in traits provider; for now this clobbers any equipped item
        currentSlots[item.slotIndex] = item.itemEntity;
        (tokenContract, tokenId) = EntityLibrary.entityToToken(parentEntity);
        traitsProvider.setTraitUint256Array(
            tokenContract,
            tokenId,
            item.slotType,
            currentSlots
        );
    }

    /**
     * @dev Removes and mints an item from parent entity at slotType if present
     */
    function _removeItem(
        address,
        uint256 parentEntity,
        Item memory item,
        ITraitsProvider traitsProvider
    ) internal {
        uint256[] memory slots = _getItems(
            parentEntity,
            item.slotType,
            traitsProvider
        );

        // Check equipped slot at slotIndex
        if (
            slots[item.slotIndex] == 0 ||
            slots[item.slotIndex] != item.itemEntity
        ) {
            revert InvalidItem(parentEntity, item.itemEntity);
        }

        // Remove item from slots
        delete slots[item.slotIndex];

        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );
        traitsProvider.setTraitUint256Array(
            tokenContract,
            tokenId,
            item.slotType,
            slots
        );

        // Default behavior is not to mint the item back to caller
        // (tokenContract, tokenId) = EntityLibrary.entityToToken(item.itemEntity);
        // IGameItems(tokenContract).mint(account, tokenId, 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Enum describing the kind of items that can be equipped
enum EquipmentType {
    UNDEFINED,
    SHIPS,
    length // This must remain as last member in enum; currently == 2
}

/**
 * Input for setting an item to a slot; may remove any existing items in slot
 * @param itemEntity Entity of item to equip
 * @param slotType Keccak256 identifier of the slot type to equip item to
 * @param slotIndex Slot index to equip item to
 */
struct Item {
    uint256 itemEntity;
    uint256 slotType;
    uint256 slotIndex;
}

/**
 * @title IEquippable
 *
 * IEquippable is an interface for defining how game nft's can be equipped with other entities.
 */
interface IEquippable {
    /**
     * @dev Returns the total combat modifiers given a parent entity's equipment loadout
     * @param parentEntity A packed tokenId and address for a parent entity which equips items
     */
    function getCombatModifiers(
        uint256 parentEntity
    ) external view returns (int256[] memory);

    /**
     * @dev Returns the equipment loadout at a parent entity's slotType, or initializes a new one
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to get equipment loadout for
     */
    function getItems(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256[] memory);

    /**
     * @dev Return the number of item slots a parent entity has for a specific slot type
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to equip item to return item count for
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) external view returns (uint256);

    /**
     * @dev Stores an array of items to equipment slots
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param existingItems Array of existing items that are expected to be overrode
     * @param items Array of params which specify entity, slot type, and slot index to equip to
     */
    function setItems(
        uint256 parentEntity,
        uint256[] calldata existingItems,
        Item[] calldata items
    ) external;

    /**
     * @dev Removes an array of items from equipment slots
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param items Array of params which specify entity, slot type, and slot index to remove from
     */
    function removeItems(uint256 parentEntity, Item[] calldata items) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {EQUIPMENT_TYPE_TRAIT_ID, IS_SHIP_TRAIT_ID, ITEM_SLOTS_TRAIT_ID} from "../Constants.sol";
import {EntityLibrary} from "../core/EntityLibrary.sol";
import {ITraitsProvider} from "../interfaces/ITraitsProvider.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../tokens/ITokenTemplateSystem.sol";
import {Equippable} from "./Equippable.sol";
import {EquipmentType, Item} from "./IEquippable.sol";

// Constants
uint256 constant ID = uint256(keccak256("game.piratenation.shipequipment"));
uint256 constant SHIP_CORE_SLOT_TYPE = uint256(
    keccak256("equipment.ship.core")
);

contract ShipEquipment is Equippable {
    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /** EXTERNAL **/

    /**
     * @dev Return the number of item slots a parent entity has for a specific slot type
     * @param parentEntity A packed tokenId and address for the parent entity which will equip the item
     * @param slotType Keccak256 identifier of the slot type to equip item to return item count for
     */
    function getSlotCount(
        uint256 parentEntity,
        uint256 slotType
    ) public view override returns (uint256) {
        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );

        // Ships only have a single slot type
        if (slotType != SHIP_CORE_SLOT_TYPE) {
            return 0;
        }

        // Get ITEM_SLOTS_TRAIT_ID from TokenTemplateSystem
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );
        return
            tokenTemplateSystem.hasTrait(
                tokenContract,
                tokenId,
                ITEM_SLOTS_TRAIT_ID
            )
                ? tokenTemplateSystem.getTraitUint256(
                    tokenContract,
                    tokenId,
                    ITEM_SLOTS_TRAIT_ID
                )
                : 0;
    }

    /** INTERNAL **/

    /**
     * @dev Returns the slot types available for a parent entity
     */
    function _getSlotTypes(
        uint256
    ) internal pure override returns (uint256[] memory) {
        uint256[] memory slotTypes = new uint256[](1);
        slotTypes[0] = SHIP_CORE_SLOT_TYPE;
        return slotTypes;
    }

    /**
     * @dev Function to override with custom validation logic
     */
    function _isItemEquippable(
        uint256 parentEntity,
        Item calldata item,
        ITraitsProvider traitsProvider
    ) internal view override returns (bool) {
        (address tokenContract, uint256 tokenId) = EntityLibrary.entityToToken(
            parentEntity
        );

        // Check is valid slot type
        if (item.slotType != SHIP_CORE_SLOT_TYPE) {
            return false;
        }

        // Check that parent is a ship
        if (
            traitsProvider.getTraitBool(
                tokenContract,
                tokenId,
                IS_SHIP_TRAIT_ID
            ) == false
        ) {
            return false;
        }

        // Check if item is equippable by parent
        (tokenContract, tokenId) = EntityLibrary.entityToToken(item.itemEntity);
        if (
            traitsProvider.getTraitUint256(
                tokenContract,
                tokenId,
                EQUIPMENT_TYPE_TRAIT_ID
            ) != uint256(EquipmentType.SHIPS)
        ) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {ITraitsProvider} from "./ITraitsProvider.sol";

/** @title Consumer of traits, exposes functions to get traits for this contract */
interface ITraitsConsumer {
    /** @return Token name for the given tokenId */
    function tokenName(uint256 tokenId) external view returns (string memory);

    /** @return Token name for the given tokenId */
    function tokenDescription(uint256 tokenId)
        external
        view
        returns (string memory);

    /** @return Image URI for the given tokenId */
    function imageURI(uint256 tokenId) external view returns (string memory);

    /** @return External URI for the given tokenId */
    function externalURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.traitsprovider"));

// Enum describing how the trait can be modified
enum TraitBehavior {
    NOT_INITIALIZED, // Trait has not been initialized
    UNRESTRICTED, // Trait can be changed unrestricted
    IMMUTABLE, // Trait can only be set once and then never changed
    INCREMENT_ONLY, // Trait can only be incremented
    DECREMENT_ONLY // Trait can only be decremented
}

// Type of data to allow in the trait
enum TraitDataType {
    NOT_INITIALIZED, // Trait has not been initialized
    INT, // int256 data type
    UINT, // uint256 data type
    BOOL, // bool data type
    STRING, // string data type
    INT_ARRAY, // int256 array data type
    UINT_ARRAY // uint256 array data type
}

// Holds metadata for a given trait type
struct TraitMetadata {
    // Name of the trait, used in tokenURIs
    string name;
    // How the trait can be modified
    TraitBehavior behavior;
    // Trait type
    TraitDataType dataType;
    // Whether or not the trait is a top-level property and should not be in the attribute array
    bool isTopLevelProperty;
    // Whether or not the trait should be hidden from end-users
    bool hidden;
}

// Used to pass traits around for URI generation
struct TokenURITrait {
    string name;
    bytes value;
    TraitDataType dataType;
    bool isTopLevelProperty;
    bool hidden;
}

/** @title Provides a set of traits to a set of ERC721/ERC1155 contracts */
interface ITraitsProvider is IERC165 {
    /**
     * Sets the value for the string trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        string calldata value
    ) external;

    /**
     * Sets several string traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitString(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        string[] calldata values
    ) external;

    /**
     * Sets the value for the uint256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 value
    ) external;

    /**
     * Sets several uint256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitUint256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        uint256[] calldata values
    ) external;

    /**
     * Sets the value for the int256 trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256 value
    ) external;

    /**
     * Sets several int256 traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitInt256(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        int256[] calldata values
    ) external;

    /**
     * Sets the value for the int256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        int256[] calldata value
    ) external;

    /**
     * Sets the value for the uint256[] trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256[] calldata value
    ) external;

    /**
     * Sets the value for the bool trait of a token, also checks to make sure trait can be modified
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param value          New value for the given trait
     */
    function setTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        bool value
    ) external;

    /**
     * Sets several bool traits for a given token
     *
     * @param tokenContract Address of the token's contract
     * @param tokenIds       Ids of the token to set traits for
     * @param traitIds       Ids of traits to set
     * @param values         Values of traits to set
     */
    function batchSetTraitBool(
        address tokenContract,
        uint256[] calldata tokenIds,
        uint256[] calldata traitIds,
        bool[] calldata values
    ) external;

    /**
     * Increments the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to increment trait by
     */
    function incrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Decrements the trait for a token by the given amount
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to modify
     * @param amount         Amount to decrement trait by
     */
    function decrementTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId,
        uint256 amount
    ) external;

    /**
     * Returns the trait data for a given token
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     *
     * @return A struct containing all traits for the token
     */
    function getTraitIds(
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a raw abi-encoded byte data for the given trait
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a int256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256[] memory);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a uint256 array trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256Array(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256[] memory);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * @param traitId  Id of the trait to get metadata for
     * @return Metadata for the given trait
     */
    function getTraitMetadata(
        uint256 traitId
    ) external view returns (TraitMetadata memory);

    /**
     * Generate a tokenURI based on a set of global properties and traits
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

/**
 * @title Array utility functions
 */
library ArrayLibrary {
    /**
     * @dev Returns array of uint256's sorted in place and in ascending order
     */
    function sortUint256Array(
        uint256[] memory data
    ) internal pure returns (uint256[] memory) {
        _quickSortUint256Array(data, 0, int256(data.length - 1), true);
        return data;
    }

    /**
     * @dev Returns array of uint256's sorted in place and in descending order
     */
    function sortUint256ArrayDesc(
        uint256[] memory data
    ) internal pure returns (uint256[] memory) {
        _quickSortUint256Array(data, 0, int256(data.length - 1), false);
        return data;
    }

    /** INTERNAL **/

    function _quickSortUint256Array(
        uint256[] memory arr,
        int256 left,
        int256 right,
        bool asc
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) {
            return;
        }
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (asc ? arr[uint256(i)] < pivot : arr[uint256(i)] > pivot) {
                i++;
            }
            while (asc ? pivot < arr[uint256(j)] : pivot > arr[uint256(j)]) {
                j--;
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) {
            _quickSortUint256Array(arr, left, j, asc);
        }
        if (i < right) {
            _quickSortUint256Array(arr, i, right, asc);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lockingsystem"));

/// @title Interface for the LockingSystem that allows tokens to be locked by the game to prevent transfer
interface ILockingSystem is IERC165 {
    /**
     * Whether or not an NFT is locked
     *
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     */
    function isNFTLocked(address tokenContract, uint256 tokenId)
        external
        view
        returns (bool);

    /**
     * Amount of token locked in the system by a given owner
     *
     * @param account   	  Token owner
     * @param tokenContract	Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountLocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Amount of tokens available for unlock
     *
     * @param account       Token owner
     * @param tokenContract Token contract address
     * @param tokenId       Id of the token
     *
     * @return Number of tokens locked
     */
    function itemAmountUnlocked(
        address account,
        address tokenContract,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * Whether or not the given items can be transferred
     *
     * @param account   	    Token owner
     * @param tokenContract	    Token contract address
     * @param ids               Ids of the tokens
     * @param amounts           Amounts of the tokens
     *
     * @return Whether or not the given items can be transferred
     */
    function canTransferItems(
        address account,
        address tokenContract,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external view returns (bool);

    /**
     * Lets the game add a reservation to a given NFT, this prevents the NFT from being unlocked
     *
     * @param tokenContract   Token contract address
     * @param tokenId         Token id to reserve
     * @param exclusive       Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addNFTReservation(
        address tokenContract,
        uint256 tokenId,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param tokenContract Token contract
     * @param tokenId       Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeNFTReservation(
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;

    /**
     * Lets the game add a reservation to a given token, this prevents the token from being unlocked
     *
     * @param account  			    Owner of the token to reserver
     * @param tokenContract   Token contract address
     * @param tokenId  				Token id to reserve
     * @param amount 					Number of tokens to reserve (1 for NFTs, >=1 for ERC1155)
     * @param exclusive				Whether or not the reservation is exclusive. Exclusive reservations prevent other reservations from using the tokens by removing them from the pool.
     * @param data            Data determined by the reserver, can be used to identify the source of the reservation for display in UI
     */
    function addItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint256 amount,
        bool exclusive,
        uint32 data
    ) external returns (uint32);

    /**
     * Lets the game remove a reservation from a given token
     *
     * @param account   			Owner to remove reservation from
     * @param tokenContract	Token contract
     * @param tokenId  			Id of the token
     * @param reservationId Id of the reservation to remove
     */
    function removeItemReservation(
        address account,
        address tokenContract,
        uint256 tokenId,
        uint32 reservationId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.lootsystem"));

/// @title Interface for the LootSystem that gives player loot (tokens, XP, etc) for playing the game
interface ILootSystem is IERC165 {
    // Type of loot
    enum LootType {
        UNDEFINED,
        ERC20,
        ERC721,
        ERC1155,
        LOOT_TABLE,
        CALLBACK
    }

    // Individual loot to grant
    struct Loot {
        // Type of fulfillment (ERC721, ERC1155, ERC20, LOOT_TABLE)
        LootType lootType;
        // Contract to grant tokens from
        address tokenContract;
        // Id of the token to grant (ERC1155/LOOT TABLE/CALLBACK types only)
        uint256 lootId;
        // Amount of token to grant (XP, ERC20, ERC1155)
        uint256 amount;
    }

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     */
    function grantLoot(address to, Loot[] calldata loots) external;

    /**
     * Grants the given user loot(s), calls VRF to ensure it's truly random
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param randomWord  Optional random word to skip VRF callback if we already have words generated / are in a VRF callback
     */
    function grantLootWithRandomWord(
        address to,
        Loot[] calldata loots,
        uint256 randomWord
    ) external;

    /**
     * Grants the given user loot(s) in batches. Presumes no randomness or loot tables
     *
     * @param to          Address to grant loot to
     * @param loots       Loots to grant
     * @param amount      Amount of each loot to grant
     */
    function batchGrantLootWithoutRandomness(
        address to,
        Loot[] calldata loots,
        uint8 amount
    ) external;

    /**
     * Validate that loots are properly formed. Reverts if the loots are not valid
     *
     * @param loots Loots to validate
     * @return needsVRF Whether or not the loots specified require VRF to generate
     */
    function validateLoots(
        Loot[] calldata loots
    ) external view returns (bool needsVRF);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRandomizerCallback} from "./IRandomizerCallback.sol";

uint256 constant ID = uint256(keccak256("game.piratenation.randomizer"));

interface IRandomizer is IERC165 {
    /**
     * Starts a VRF random number request
     *
     * @param callbackAddress Address to callback with the random numbers
     * @param numWords        Number of words to request from VRF
     *
     * @return requestId for the random number, will be passed to the callback contract
     */
    function requestRandomWords(
        IRandomizerCallback callbackAddress,
        uint32 numWords
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRandomizerCallback {
    /**
     * Callback for when the Chainlink request returns
     *
     * @param requestId     Id of the random word request
     * @param randomWords   Random words that were generated by the VRF
     */
    function fulfillRandomWordsCallback(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract ContractTraits {
    // Add the library methods
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct Asset {
        /// @dev Name of the rendered trait
        string traitName;
        /// @dev partial URI to the asset, tokenId is appended
        string uri;
        /// @dev mimeType of the asset
        string mimeType;
        /// @dev width of the asset
        uint16 width;
        /// @dev height of the asset
        uint16 height;
    }

    struct ContractInfo {
        /// @dev All asset trait ids for this contract
        EnumerableSetUpgradeable.UintSet assetSet;
        /// @dev All assets for this contract
        mapping(uint256 => Asset) assets;
    }

    /// @notice Traits for a given contract
    mapping(address => ContractInfo) _contracts;

    /** EXTERNAL **/

    /**
     * Adds a new asset type for a contract
     *
     * @param tokenContract Contract to add asset types for
     * @param asset         Asset to add to the contract
     */
    function _addAsset(address tokenContract, Asset calldata asset) internal {
        ContractInfo storage contractInfo = _contracts[tokenContract];
        uint256 traitId = uint256(keccak256(bytes(asset.traitName)));
        contractInfo.assetSet.add(traitId);
        contractInfo.assets[traitId] = asset;
    }

    /**
     * Removes an asset from a contract
     *
     * @param tokenContract Contract to remove asset from
     * @param traitId       Keccak256 traitId of the asset to remove
     */
    function _removeAsset(address tokenContract, uint256 traitId) internal {
        ContractInfo storage contractInfo = _contracts[tokenContract];
        delete contractInfo.assets[traitId];
        contractInfo.assetSet.remove(traitId);
    }

    /** @return All asset trait ids for the given token contract */
    function getAssetTraitIds(address tokenContract)
        external
        view
        returns (uint256[] memory)
    {
        ContractInfo storage contractInfo = _contracts[tokenContract];
        return contractInfo.assetSet.values();
    }

    /**
     * @param tokenContract Token contract to get asset from
     * @param traitId Id of the asset to retrieve
     * @return Returns the asset with the given id
     */
    function getAsset(address tokenContract, uint256 traitId)
        external
        view
        returns (Asset memory)
    {
        ContractInfo storage contractInfo = _contracts[tokenContract];
        return contractInfo.assets[traitId];
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import {TokenURITrait} from "../interfaces/ITraitsProvider.sol";

uint256 constant ID = uint256(
    keccak256("game.piratenation.tokentemplatesystem")
);

/**
 * @title Interface to access token template system
 */
interface ITokenTemplateSystem {
    /**
     * @return Whether or not a template has been defined yet
     *
     * @param templateId    TemplateId to check
     */
    function exists(uint256 templateId) external view returns (bool);

    /**
     * Sets a template for a given token
     *
     * @param tokenContract Token contract to set template for
     * @param tokenId       Token id to set template for
     * @param templateId    Id of the template to set
     */
    function setTemplate(
        address tokenContract,
        uint256 tokenId,
        uint256 templateId
    ) external;

    /**
     * @return Returns the template token for the given token contract/token id, if it exists
     *
     * @param tokenContract Token to get the template for
     * @param tokenId to get the template for
     */
    function getTemplate(
        address tokenContract,
        uint256 tokenId
    ) external view returns (address, uint256);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURI(
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * Generates a token URI for a given token that inherits traits from its templates
     *
     * @param tokenContract     Address of the token contract
     * @param tokenId           Id of the token to generate traits for
     * @param extraTraits       Dyanmically generated traits to add on to the generated url
     *
     * @return base64-encoded fully-formed tokenURI
     */
    function generateTokenURIWithExtra(
        address tokenContract,
        uint256 tokenId,
        TokenURITrait[] memory extraTraits
    ) external view returns (string memory);

    /**
     * Returns whether or not the given token has a trait recursively
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Whether or not the token has the trait
     */
    function hasTrait(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Returns the trait data for a given token and checks the templates
     *
     * @param tokenContract  Address of the token's contract
     * @param tokenId        NFT tokenId or ERC1155 token type id
     * @param traitId        Id of the trait to retrieve
     *
     * @return Trait value as abi-encoded bytes
     */
    function getTraitBytes(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bytes memory);

    /**
     * Retrieves a int256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitInt256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (int256);

    /**
     * Retrieves a uint256 trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitUint256(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (uint256);

    /**
     * Retrieves a bool trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitBool(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (bool);

    /**
     * Retrieves a string trait for the given token
     *
     * @param tokenContract   Token contract (ERC721 or ERC1155)
     * @param tokenId         Id of the NFT or token type
     * @param traitId         Id of the trait to retrieve
     *
     * @return The value of the trait if it exists, reverts if the trait has not been set or is of a different type.
     */
    function getTraitString(
        address tokenContract,
        uint256 tokenId,
        uint256 traitId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface ITokenURIHandler {
    /**
     * Generates the TokenURI for a given token
     *
     * @param operator          Sender requesting the tokenURI
     * @param tokenContract     TokenContract to get URI for
     * @param tokenId           Id of the token to get URI for
     *
     * @return TokenURI for the given token
     */
    function tokenURI(
        address operator,
        address tokenContract,
        uint256 tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

import {ITokenURIHandler} from "../ITokenURIHandler.sol";
import {ITraitsConsumer} from "../../interfaces/ITraitsConsumer.sol";
import {ITraitsProvider, TokenURITrait, TraitDataType} from "../../interfaces/ITraitsProvider.sol";
import {GameRegistryConsumerUpgradeable} from "../../GameRegistryConsumerUpgradeable.sol";
import {ContractTraits} from "../ContractTraits.sol";
import {MANAGER_ROLE, NAME_TRAIT_ID, IMAGE_TRAIT_ID, DESCRIPTION_TRAIT_ID} from "../../Constants.sol";
import {EntityLibrary} from "../../core/EntityLibrary.sol";
import {IEquippable} from "../../equipment/IEquippable.sol";
import {ID as SHIP_EQUIPMENT_ID, SHIP_CORE_SLOT_TYPE} from "../../equipment/ShipEquipment.sol";
import {ITraitsProvider, ID as TRAITS_PROVIDER_ID} from "../../interfaces/ITraitsProvider.sol";
import {ArrayLibrary} from "../../libraries/ArrayLibrary.sol";
import {ITokenTemplateSystem, ID as TOKEN_TEMPLATE_SYSTEM_ID} from "../../tokens/ITokenTemplateSystem.sol";

uint256 constant EQUIPMENT_LIMIT = 6;
uint256 constant ID = uint256(
    keccak256("game.piratenation.shipnfttokenurihandler")
);

contract ShipNFTTokenURIHandler is
    GameRegistryConsumerUpgradeable,
    ContractTraits,
    ITokenURIHandler
{
    using Strings for uint256;

    /** SETUP **/

    /**
     * Initializer for this upgradeable contract
     *
     * @param gameRegistryAddress Address of the GameRegistry contract
     */
    function initialize(address gameRegistryAddress) public initializer {
        __GameRegistryConsumer_init(gameRegistryAddress, ID);
    }

    /** EXTERNAL **/

    /**
     * @notice Generates metadata for the given tokenId
     * @param
     * @param tokenId  Token to generate metadata for
     * @return A normal URI
     */
    function tokenURI(
        address,
        address tokenContract,
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );

        return
            tokenTemplateSystem.generateTokenURIWithExtra(
                tokenContract,
                tokenId,
                getExtraTraits(tokenContract, tokenId)
            );
    }

    /**
     * @dev This override includes the locked and soulbound traits
     * @param tokenId  Token to generate extra traits array for
     * @return Extra traits to include in the tokenURI metadata
     */
    function getExtraTraits(
        address tokenContract,
        uint256 tokenId
    ) public view returns (TokenURITrait[] memory) {
        ITraitsConsumer traitsConsumer = ITraitsConsumer(tokenContract);

        ITraitsProvider traitsProvider = ITraitsProvider(
            _getSystem(TRAITS_PROVIDER_ID)
        );

        ITokenTemplateSystem tokenTemplateSystem = ITokenTemplateSystem(
            _getSystem(TOKEN_TEMPLATE_SYSTEM_ID)
        );

        (
            address templateTokenAddress,
            uint256 templateTokenId
        ) = tokenTemplateSystem.getTemplate(tokenContract, tokenId);

        // Get equipment traits
        TokenURITrait[] memory equipmentTraits = _getEquipmentTraits(
            tokenContract,
            tokenId
        );

        uint256 numStaticTraits = 6 + equipmentTraits.length;
        TokenURITrait[] memory extraTraits = new TokenURITrait[](
            numStaticTraits
        );

        // Note: All of the below try to get the data from the template system so that inherited traits show up

        // External URL
        extraTraits[0] = TokenURITrait({
            name: "external_url",
            value: abi.encode(traitsConsumer.externalURI(tokenId)),
            dataType: TraitDataType.STRING,
            hidden: false,
            isTopLevelProperty: true
        });

        // Locked
        extraTraits[1] = TokenURITrait({
            name: "locked",
            isTopLevelProperty: false,
            dataType: TraitDataType.BOOL,
            hidden: false,
            value: abi.encode(
                _lockingSystem().isNFTLocked(tokenContract, tokenId)
            )
        });

        // Name
        extraTraits[2] = TokenURITrait({
            name: "name",
            value: tokenTemplateSystem.hasTrait(
                tokenContract,
                tokenId,
                NAME_TRAIT_ID
            )
                ? tokenTemplateSystem.getTraitBytes(
                    tokenContract,
                    tokenId,
                    NAME_TRAIT_ID
                )
                : abi.encode(traitsConsumer.tokenName(tokenId)),
            dataType: TraitDataType.STRING,
            hidden: false,
            isTopLevelProperty: true
        });

        // Ship type (name of template), get specifically from template via traitsprovider
        extraTraits[3] = TokenURITrait({
            name: "ship_type",
            value: abi.encode(
                tokenTemplateSystem.hasTrait(
                    templateTokenAddress,
                    templateTokenId,
                    NAME_TRAIT_ID
                )
                    ? traitsProvider.getTraitString(
                        templateTokenAddress,
                        templateTokenId,
                        NAME_TRAIT_ID
                    )
                    : traitsConsumer.tokenName(tokenId)
            ),
            dataType: TraitDataType.STRING,
            hidden: false,
            isTopLevelProperty: false
        });

        // Image
        extraTraits[4] = TokenURITrait({
            name: "image",
            value: tokenTemplateSystem.hasTrait(
                tokenContract,
                tokenId,
                IMAGE_TRAIT_ID
            )
                ? tokenTemplateSystem.getTraitBytes(
                    tokenContract,
                    tokenId,
                    IMAGE_TRAIT_ID
                )
                : abi.encode(traitsConsumer.imageURI(tokenId)),
            dataType: TraitDataType.STRING,
            isTopLevelProperty: true,
            hidden: false
        });

        // Description
        extraTraits[5] = TokenURITrait({
            name: "description",
            value: tokenTemplateSystem.hasTrait(
                tokenContract,
                tokenId,
                DESCRIPTION_TRAIT_ID
            )
                ? tokenTemplateSystem.getTraitBytes(
                    tokenContract,
                    tokenId,
                    DESCRIPTION_TRAIT_ID
                )
                : abi.encode(traitsConsumer.tokenDescription(tokenId)),
            dataType: TraitDataType.STRING,
            isTopLevelProperty: true,
            hidden: false
        });

        // Loop through equipment traits and add them to the extra traits array
        for (uint256 i = 0; i < equipmentTraits.length; i++) {
            extraTraits[
                i + numStaticTraits - equipmentTraits.length
            ] = equipmentTraits[i];
        }

        return extraTraits;
    }

    /** INTERNAL **/

    /**
     * @dev This override includes the locked and soulbound traits
     * @param tokenId  Token to generate extra traits array for
     * @return Extra traits to include in the tokenURI metadata
     */
    function _getEquipmentTraits(
        address tokenContract,
        uint256 tokenId
    ) public view returns (TokenURITrait[] memory) {
        // Extend static traits by number of equipped items bounded by EQUIPMENT_LIMIT
        uint256[] memory equippedItems = IEquippable(
            _getSystem(SHIP_EQUIPMENT_ID)
        ).getItems(
                EntityLibrary.tokenToEntity(tokenContract, tokenId),
                SHIP_CORE_SLOT_TYPE
            );

        // Make sure to have an upper bound on number of items to avoid OOG
        uint256 itemLength = equippedItems.length > EQUIPMENT_LIMIT
            ? EQUIPMENT_LIMIT
            : equippedItems.length;

        // Loop through equipped items on trait provider and add them to the extra traits
        uint256 count = 0;
        uint256 traitCount = 0;
        uint256 itemTokenId;
        address itemTokenContract;

        bool[] memory visited = new bool[](itemLength);
        TokenURITrait[] memory extraTraits = new TokenURITrait[](itemLength);
        for (uint256 i = 0; i < itemLength; i++) {
            // Skip if we've already counted this item or if it's 0
            if (visited[i] == true || equippedItems[i] == 0) {
                continue;
            }

            // Iterate through remainder of itemLength and count occurrences
            count = 1;
            for (uint256 j = i + 1; j < itemLength; j++) {
                if (equippedItems[i] == equippedItems[j]) {
                    count++;
                    visited[j] = true;
                }
            }

            // Get the item's token contract and id
            (itemTokenContract, itemTokenId) = EntityLibrary.entityToToken(
                equippedItems[i]
            );

            // Add the item's name to the extra traits
            extraTraits[traitCount] = TokenURITrait({
                name: string.concat(
                    "Has ",
                    ITraitsConsumer(itemTokenContract).tokenName(itemTokenId)
                ),
                value: abi.encode(count),
                dataType: TraitDataType.UINT,
                hidden: false,
                isTopLevelProperty: false
            });
            traitCount++;
        }

        // Resize the extra traits array to the number of traits added
        TokenURITrait[] memory resizedExtraTraits = new TokenURITrait[](
            traitCount
        );
        for (uint256 i = 0; i < traitCount; i++) {
            resizedExtraTraits[i] = extraTraits[i];
        }

        return resizedExtraTraits;
    }
}