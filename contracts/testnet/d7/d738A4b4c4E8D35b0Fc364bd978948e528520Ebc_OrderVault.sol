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

pragma solidity 0.8.9;

contract Constants {
    uint8 internal constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 internal constant BASIS_POINTS_DIVISOR = 100000;
    uint256 internal constant LIQUIDATE_THRESHOLD_DIVISOR = 10 * BASIS_POINTS_DIVISOR;
    uint256 internal constant DEFAULT_VLP_PRICE = 100000;
    uint256 internal constant FUNDING_RATE_PRECISION = BASIS_POINTS_DIVISOR ** 3; // 1e15
    uint256 internal constant MAX_DEPOSIT_WITHDRAW_FEE = 10000; // 10%
    uint256 internal constant MAX_DELTA_TIME = 24 hours;
    uint256 internal constant MAX_COOLDOWN_DURATION = 30 days;
    uint256 internal constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 internal constant MAX_PRICE_MOVEMENT_PERCENT = 10000; // 10%
    uint256 internal constant MAX_BORROW_FEE_FACTOR = 500; // 0.5% per hour
    uint256 internal constant MAX_FUNDING_RATE = FUNDING_RATE_PRECISION / 10; // 10% per hour
    uint256 internal constant MAX_STAKING_UNSTAKING_FEE = 10000; // 10%
    uint256 internal constant MAX_EXPIRY_DURATION = 60; // 60 seconds
    uint256 internal constant MAX_SELF_EXECUTE_COOLDOWN = 300; // 5 minutes
    uint256 internal constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 internal constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_MARKET_ORDER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_VESTING_DURATION = 700 days;
    uint256 internal constant MIN_LEVERAGE = 10000; // 1x
    uint256 internal constant POSITION_MARKET = 0;
    uint256 internal constant POSITION_LIMIT = 1;
    uint256 internal constant POSITION_STOP_MARKET = 2;
    uint256 internal constant POSITION_STOP_LIMIT = 3;
    uint256 internal constant POSITION_TRAILING_STOP = 4;
    uint256 internal constant PRICE_PRECISION = 10 ** 30;
    uint256 internal constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 internal constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 internal constant VLP_DECIMALS = 18;

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function checkSlippage(bool isLong, uint256 allowedPrice, uint256 actualMarketPrice) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <= allowedPrice,
                string(
                    abi.encodePacked(
                        "long: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        } else {
            require(
                actualMarketPrice >= allowedPrice,
                string(
                    abi.encodePacked(
                        "short: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Order, OrderType, OrderStatus, AddPositionOrder, DecreasePositionOrder, PositionTrigger} from "../structs.sol";

interface IOrderVault {
    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external;

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external;

    function cancelPendingOrder(address _account, uint256 _posId) external;

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) external;

    function cancelMarketOrder(uint256 _posId) external;

    function createNewOrder(
        uint256 _posId,
        address _accout,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external;

    function createAddPositionOrder(
        address _owner,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external;

    function createDecreasePositionOrder(uint256 _posId, uint256 _sizeDelta, uint256 _allowedPrice) external;

    function cancelAddPositionOrder(uint256 _posId) external;

    function deleteAddPositionOrder(uint256 _posId) external;

    function deleteDecreasePositionOrder(uint256 _posId) external;

    function getOrder(uint256 _posId) external view returns (Order memory);

    function getAddPositionOrder(uint256 _posId) external view returns (AddPositionOrder memory);

    function getDecreasePositionOrder(uint256 _posId) external view returns (DecreasePositionOrder memory);

    function getTriggerOrderInfo(uint256 _posId) external view returns (PositionTrigger memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType, PaidFees} from "../structs.sol";

interface IPositionVault {
    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function addOrRemoveCollateral(address _account, uint256 _posId, bool isPlus, uint256 _amount) external;

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function decreasePositionByOrderVault(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function removeUserOpenOrder(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceManager {
    function getLastPrice(uint256 _tokenId) external view returns (uint256);

    function maxLeverage(uint256 _tokenId) external view returns (uint256);

    function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);

    function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISettingsManager {
    function decreaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint32, uint32);

    function checkBanList(address _delegate) external view returns (bool);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function minCollateral() external view returns (uint256);

    function closeDeltaTime() external view returns (uint256);

    function expiryDuration() external view returns (uint256);

    function selfExecuteCooldown() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function liquidationPendingTime() external view returns (uint256);

    function depositFee(address token) external view returns (uint256);

    function withdrawFee(address token) external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(uint256 tokenId) external view returns (uint256);

    function totalOpenInterest() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function liquidationFee() external view returns (uint256);

    function deductFeePercent(address _account) external view returns (uint256);

    function referrerTiers(address _referrer) external view returns (uint256);

    function tierFees(uint256 _tier) external view returns (uint256);

    function fundingIndex(uint256 _tokenId) external view returns (int256);

    function fundingRateFactor(uint256 _tokenId) external view returns (uint256);

    function slippageFactor(uint256 _tokenId) external view returns (uint256);

    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getFundingChange(uint256 _tokenId) external view returns (int256);

    function getFundingRate(uint256 _tokenId) external view returns (int256);

    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view returns (int256, int256, int256);

    function updateFunding(uint256 _tokenId) external;

    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId
    ) external view returns (uint256);

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getReferFee(address _refer) external view returns (uint256);

    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isStakingEnabled(address _token) external view returns (bool);

    function isUnstakingEnabled(address _token) external view returns (bool);

    function isIncreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isDecreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isWhitelistedFromCooldown(address _addr) external view returns (bool);

    function isWithdraw(address _token) external view returns (bool);

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function liquidateThreshold(uint256) external view returns (uint256);

    function tradingFee(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function maxProfitPercent() external view returns (uint256);

    function priceMovementPercent() external view returns (uint256);

    function stakingFee(address token) external view returns (uint256);

    function unstakingFee(address token) external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function marketOrderGasFee() external view returns (uint256);

    function maxTriggerPerPosition() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVault {
    function accountDeltaIntoTotalUSD(bool _isIncrease, uint256 _delta) external;

    function distributeFee(uint256 _fee, address _refer) external;

    function takeVUSDIn(address _account, uint256 _amount) external;

    function takeVUSDOut(address _account, uint256 _amount) external;

    function lastStakedAt(address _account) external view returns (uint256);

    function getVaultUSDBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IOrderVault.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOperators.sol";

import {Constants} from "../access/Constants.sol";
import {OrderStatus, TriggerInfo, TriggerStatus, PositionTrigger, AddPositionOrder, DecreasePositionOrder} from "./structs.sol";

contract OrderVault is Constants, Initializable, ReentrancyGuardUpgradeable, IOrderVault {
    // constants
    IPriceManager private priceManager;
    IPositionVault private positionVault;
    ISettingsManager private settingsManager;
    IVault private vault;
    IOperators private operators;
    bool private isInitialized;

    // variables
    mapping(uint256 => Order) public orders;
    mapping(uint256 => AddPositionOrder) public addPositionOrders;
    mapping(uint256 => DecreasePositionOrder) public decreasePositionOrders;

    mapping(uint256 => PositionTrigger) private triggerOrders;
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private aliveTriggerIds;

    event NewOrder(
        uint256 posId,
        address account,
        bool isLong,
        uint256 tokenId,
        uint256 positionType,
        OrderStatus orderStatus,
        uint256[] triggerData,
        address refer
    );
    event UpdateOrder(uint256 posId, uint256 positionType, OrderStatus orderStatus);
    event FinishOrder(uint256 posId, uint256 positionType, OrderStatus orderStatus);

    event AddTriggerOrders(
        uint256 posId,
        uint256 orderId,
        bool isTP,
        uint256 price,
        uint256 amountPercent,
        TriggerStatus status
    );
    event ExecuteTriggerOrders(uint256 posId, uint256 amount, uint256 orderId, uint256 price);
    event UpdateTriggerOrderStatus(uint256 posId, uint256 orderId, TriggerStatus status);

    event AddTrailingStop(uint256 posId, uint256[] data);
    event UpdateTrailingStop(uint256 posId, uint256 stpPrice);

    modifier onlyVault() {
        require(msg.sender == address(vault), "Only vault");
        _;
    }

    modifier onlyPositionVault() {
        require(msg.sender == address(positionVault), "Only position vault");
        _;
    }

    modifier onlyOperator(uint256 level) {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
        _;
    }

    /* ========== INITIALIZE FUNCTIONS ========== */

    function initialize() public initializer {
        __ReentrancyGuard_init();
    }

    function init(
        IPriceManager _priceManager,
        IPositionVault _positionVault,
        ISettingsManager _settingsManager,
        IVault _vault,
        IOperators _operators
    ) external {
        require(!isInitialized, "initialized");
        require(AddressUpgradeable.isContract(address(_priceManager)), "priceManager invalid");
        require(AddressUpgradeable.isContract(address(_positionVault)), "positionVault invalid");
        require(AddressUpgradeable.isContract(address(_settingsManager)), "settingsManager invalid");
        require(AddressUpgradeable.isContract(address(_vault)), "vault invalid");
        require(AddressUpgradeable.isContract(address(_operators)), "operators is invalid");

        priceManager = _priceManager;
        settingsManager = _settingsManager;
        positionVault = _positionVault;
        vault = _vault;
        operators = _operators;

        isInitialized = true;
    }

    /* ========== FOR OPENING POSITIONS ========== */

    function createNewOrder(
        uint256 _posId,
        address _account,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external override onlyPositionVault {
        Order storage order = orders[_posId];
        order.status = OrderStatus.PENDING;
        order.positionType = _positionType;
        order.collateral = _params[2];
        order.size = _params[3];
        order.lmtPrice = _params[0];
        order.stpPrice = _params[1];
        order.timestamp = block.timestamp;
        emit NewOrder(_posId, _account, _isLong, _tokenId, order.positionType, order.status, _params, _refer);
    }

    function cancelMarketOrder(uint256 _posId) public override onlyPositionVault {
        // only cancel if the order still exists
        if (orders[_posId].size > 0) {
            Order storage order = orders[_posId];
            order.status = OrderStatus.CANCELED;

            Position memory position = positionVault.getPosition(_posId);
            vault.takeVUSDOut(position.owner, order.collateral + positionVault.getPaidFees(_posId).paidPositionFee);

            emit FinishOrder(_posId, order.positionType, order.status);
        }
    }

    function cancelPendingOrder(address _account, uint256 _posId) external override onlyVault {
        Order storage order = orders[_posId];
        Position memory position = positionVault.getPosition(_posId);
        require(_account == position.owner, "You are not allowed to cancel");
        require(order.status == OrderStatus.PENDING, "Not in Pending");
        require(order.positionType != POSITION_MARKET, "market order cannot be cancelled");
        if (order.positionType == POSITION_TRAILING_STOP) {
            order.status = OrderStatus.FILLED;
            order.positionType = POSITION_MARKET;
        } else {
            order.status = OrderStatus.CANCELED;
            vault.takeVUSDOut(position.owner, order.collateral + positionVault.getPaidFees(_posId).paidPositionFee);
        }
        order.collateral = 0;
        order.size = 0;
        order.lmtPrice = 0;
        order.stpPrice = 0;
        emit FinishOrder(_posId, order.positionType, order.status);
    }

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) public override onlyPositionVault {
        _updateOrder(_posId, _positionType, _collateral, _size, _status);
    }

    function _updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) private {
        Order storage order = orders[_posId];
        order.positionType = _positionType;
        order.collateral = _collateral;
        order.size = _size;
        order.status = _status;
        if (_status == OrderStatus.FILLED || _status == OrderStatus.CANCELED) {
            emit FinishOrder(_posId, _positionType, _status);
        } else {
            emit UpdateOrder(_posId, _positionType, _status);
        }
    }

    /* ========== FOR ADDING POSITIONS ========== */

    function createAddPositionOrder(
        address _owner,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external override onlyPositionVault {
        require(addPositionOrders[_posId].size == 0, "addPositionOrder already exists");

        addPositionOrders[_posId] = AddPositionOrder({
            owner: _owner,
            collateral: _collateralDelta,
            size: _sizeDelta,
            allowedPrice: _allowedPrice,
            timestamp: block.timestamp,
            fee: _fee
        });
    }

    function cancelAddPositionOrder(uint256 _posId) external override onlyPositionVault {
        AddPositionOrder memory addPositionOrder = addPositionOrders[_posId];

        if (addPositionOrder.size > 0) {
            vault.takeVUSDOut(addPositionOrder.owner, addPositionOrder.collateral + addPositionOrder.fee);
            delete addPositionOrders[_posId];
        }
    }

    function deleteAddPositionOrder(uint256 _posId) external override onlyPositionVault {
        delete addPositionOrders[_posId];
    }

    /* ========== FOR CLOSING POSITIONS (MARKET ORDER) ========== */

    function createDecreasePositionOrder(
        uint256 _posId,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external override onlyPositionVault {
        require(decreasePositionOrders[_posId].size == 0, "decreasePositionOrder already exists");

        decreasePositionOrders[_posId] = DecreasePositionOrder({
            size: _sizeDelta,
            allowedPrice: _allowedPrice,
            timestamp: block.timestamp
        });
    }

    function deleteDecreasePositionOrder(uint256 _posId) external override onlyPositionVault {
        delete decreasePositionOrders[_posId];
    }

    /* ========== FOR CLOSING POSITIONS (TPSL ORDER) ========== */

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external override onlyVault {
        Position memory position = positionVault.getPosition(_posId);
        require(position.owner == _account, "not allowed");
        require(_prices.length == _isTPs.length && _prices.length == _amountPercents.length, "invalid params");
        require(_prices.length > 0, "empty order");
        require(
            EnumerableSetUpgradeable.length(aliveTriggerIds[_posId]) + _prices.length <=
                settingsManager.maxTriggerPerPosition(),
            "too many triggers"
        );
        PositionTrigger storage triggerOrder = triggerOrders[_posId];

        for (uint256 i; i < _prices.length; ++i) {
            require(_amountPercents[i] > 0 && _amountPercents[i] <= BASIS_POINTS_DIVISOR, "invalid percent");

            uint256 triggersLength = triggerOrder.triggers.length;
            EnumerableSetUpgradeable.add(aliveTriggerIds[_posId], triggersLength);
            triggerOrder.triggers.push(
                TriggerInfo({
                    isTP: _isTPs[i],
                    amountPercent: _amountPercents[i],
                    createdAt: block.timestamp,
                    price: _prices[i],
                    triggeredAmount: 0,
                    triggeredAt: 0,
                    status: TriggerStatus.OPEN
                })
            );
            emit AddTriggerOrders(
                _posId,
                triggersLength,
                _isTPs[i],
                _prices[i],
                _amountPercents[i],
                TriggerStatus.OPEN
            );
        }
    }

    function cancelTriggerOrder(uint256 _posId, uint256 _orderId) public {
        PositionTrigger storage order = triggerOrders[_posId];
        Position memory position = positionVault.getPosition(_posId);
        require(position.owner == msg.sender, "not allowed");
        require(order.triggers[_orderId].status == TriggerStatus.OPEN, "TriggerOrder was cancelled");
        order.triggers[_orderId].status = TriggerStatus.CANCELLED;
        EnumerableSetUpgradeable.remove(aliveTriggerIds[_posId], _orderId);
        emit UpdateTriggerOrderStatus(_posId, _orderId, order.triggers[_orderId].status);
    }

    function cancelTriggerOrderPacked(uint256 x) external {
        uint256 posId = x / 2 ** 128;
        uint256 orderId = x % 2 ** 128;
        cancelTriggerOrder(posId, orderId);
    }

    function cancelAllTriggerOrders(uint256 _posId) external {
        PositionTrigger storage order = triggerOrders[_posId];
        Position memory position = positionVault.getPosition(_posId);
        require(position.owner == msg.sender, "not allowed");
        uint256 length = EnumerableSetUpgradeable.length(aliveTriggerIds[_posId]);
        require(length > 0, "already cancelled");
        uint256[] memory tmp = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint256 idx = EnumerableSetUpgradeable.at(aliveTriggerIds[_posId], i);
            TriggerInfo storage trigger = order.triggers[idx];
            trigger.status = TriggerStatus.CANCELLED;
            emit UpdateTriggerOrderStatus(_posId, idx, trigger.status);
            tmp[i] = idx;
        }
        for (uint256 i = 0; i < length; ++i) {
            EnumerableSetUpgradeable.remove(aliveTriggerIds[_posId], tmp[i]);
        }
    }

    function executeTriggerOrders(uint256 _posId) internal returns (uint256, uint256) {
        PositionTrigger storage order = triggerOrders[_posId];
        Position memory position = positionVault.getPosition(_posId);
        require(position.size > 0, "Trigger Not Open");
        uint256 price = priceManager.getLastPrice(position.tokenId);
        for (uint256 i = 0; i < EnumerableSetUpgradeable.length(aliveTriggerIds[_posId]); ++i) {
            uint256 idx = EnumerableSetUpgradeable.at(aliveTriggerIds[_posId], i);
            TriggerInfo storage trigger = order.triggers[idx];
            if (validateTrigger(trigger.status, trigger.isTP, position.isLong, trigger.price, price)) {
                uint256 triggerAmount = (position.size * trigger.amountPercent) / BASIS_POINTS_DIVISOR;
                trigger.triggeredAmount = triggerAmount;
                trigger.triggeredAt = block.timestamp;
                trigger.status = TriggerStatus.TRIGGERED;
                EnumerableSetUpgradeable.remove(aliveTriggerIds[_posId], idx);
                emit ExecuteTriggerOrders(_posId, trigger.triggeredAmount, idx, price);
                return (triggerAmount, price);
            }
        }
        revert("trigger not ready");
    }

    function validateTrigger(
        TriggerStatus _status,
        bool _isTP,
        bool _isLong,
        uint256 _triggerPrice,
        uint256 _lastPrice
    ) private pure returns (bool) {
        if (_status != TriggerStatus.OPEN) return false;

        if (_isTP) {
            if (_isLong) {
                if (_lastPrice >= _triggerPrice) return true;
            } else {
                if (_lastPrice <= _triggerPrice) return true;
            }
        } else {
            if (_isLong) {
                if (_lastPrice <= _triggerPrice) return true;
            } else {
                if (_lastPrice >= _triggerPrice) return true;
            }
        }

        return false;
    }

    /* ========== FOR CLOSING POSITIONS (TRAILING STOP ORDER) ========== */

    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external override onlyVault {
        Order storage order = orders[_posId];
        Position memory position = positionVault.getPosition(_posId);
        require(_account == position.owner, "you are not allowed to add trailing stop");
        require(position.size > 0, "position not alive");
        validateTrailingStopInputData(_posId, _params);
        order.collateral = _params[0];
        order.size = _params[1];
        order.status = OrderStatus.PENDING;
        order.positionType = POSITION_TRAILING_STOP;
        order.stepType = _params[2];
        order.stpPrice = _params[3];
        order.stepAmount = _params[4];
        emit AddTrailingStop(_posId, _params);
    }

    function validateTrailingStopInputData(uint256 _posId, uint256[] memory _params) public view returns (bool) {
        Position memory position = positionVault.getPosition(_posId);
        require(_params[1] > 0 && _params[1] <= position.size, "trailing size should be smaller than position size");
        require(_params[4] > 0 && _params[3] > 0, "invalid trailing data");
        require(_params[2] <= 1, "invalid type");
        if (_params[2] == TRAILING_STOP_TYPE_PERCENT) {
            require(_params[4] < BASIS_POINTS_DIVISOR, "percent cant exceed 100%");
        }
        return true;
    }

    function updateTrailingStop(uint256 _posId) external nonReentrant {
        Position memory position = positionVault.getPosition(_posId);
        Order storage order = orders[_posId];
        uint256 price = priceManager.getLastPrice(position.tokenId);
        require(position.owner == msg.sender || operators.getOperatorLevel(msg.sender) >= 1, "updateTStop not allowed");
        require(position.size > 0, "position not alive");
        validateTrailingStopPrice(position.tokenId, position.isLong, _posId, true);
        uint256 oldStpPrice = order.stpPrice;
        if (position.isLong) {
            order.stpPrice = order.stepType == 0
                ? price - order.stepAmount
                : (price * (BASIS_POINTS_DIVISOR - order.stepAmount)) / BASIS_POINTS_DIVISOR;
        } else {
            order.stpPrice = order.stepType == 0
                ? price + order.stepAmount
                : (price * (BASIS_POINTS_DIVISOR + order.stepAmount)) / BASIS_POINTS_DIVISOR;
        }
        uint256 diff;
        if (order.stpPrice > oldStpPrice) {
            diff = order.stpPrice - oldStpPrice;
        } else {
            diff = oldStpPrice - order.stpPrice;
        }
        require(
            (diff * BASIS_POINTS_DIVISOR) / oldStpPrice >= settingsManager.priceMovementPercent(),
            "!price movement"
        );
        emit UpdateTrailingStop(_posId, order.stpPrice);
    }

    function validateTrailingStopPrice(
        uint256 _tokenId,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) public view returns (bool) {
        Order memory order = orders[_posId];
        uint256 price = priceManager.getLastPrice(_tokenId);
        uint256 stopPrice;
        if (_isLong) {
            if (order.stepType == TRAILING_STOP_TYPE_AMOUNT) {
                stopPrice = order.stpPrice + order.stepAmount;
            } else {
                stopPrice = (order.stpPrice * BASIS_POINTS_DIVISOR) / (BASIS_POINTS_DIVISOR - order.stepAmount);
            }
        } else {
            if (order.stepType == TRAILING_STOP_TYPE_AMOUNT) {
                stopPrice = order.stpPrice - order.stepAmount;
            } else {
                stopPrice = (order.stpPrice * BASIS_POINTS_DIVISOR) / (BASIS_POINTS_DIVISOR + order.stepAmount);
            }
        }
        bool flag;
        if (
            _isLong &&
            order.status == OrderStatus.PENDING &&
            order.positionType == POSITION_TRAILING_STOP &&
            stopPrice <= price
        ) {
            flag = true;
        } else if (
            !_isLong &&
            order.status == OrderStatus.PENDING &&
            order.positionType == POSITION_TRAILING_STOP &&
            stopPrice >= price
        ) {
            flag = true;
        }
        if (_raise) {
            require(flag, "price incorrect");
        }
        return flag;
    }

    /* ========== EXECUTE ORDERS ========== */

    function triggerForOpenOrders(uint256 _posId) external nonReentrant onlyOperator(1) {
        Position memory position = positionVault.getPosition(_posId);
        Order memory order = orders[_posId];
        require(order.status == OrderStatus.PENDING, "order not pending");
        uint256 price = priceManager.getLastPrice(position.tokenId);

        if (order.positionType == POSITION_LIMIT) {
            if (position.isLong) {
                require(order.lmtPrice >= price, "trigger not met");
            } else {
                require(order.lmtPrice <= price, "trigger not met");
            }
            positionVault.increasePosition(
                _posId,
                position.owner,
                position.tokenId,
                position.isLong,
                price,
                order.collateral,
                order.size,
                positionVault.getPaidFees(_posId).paidPositionFee
            );
            _updateOrder(_posId, order.positionType, 0, 0, OrderStatus.FILLED);
            positionVault.removeUserOpenOrder(position.owner, _posId);
        } else if (order.positionType == POSITION_STOP_MARKET) {
            if (position.isLong) {
                require(order.stpPrice <= price, "trigger not met");
            } else {
                require(order.stpPrice >= price, "trigger not met");
            }
            positionVault.increasePosition(
                _posId,
                position.owner,
                position.tokenId,
                position.isLong,
                price,
                order.collateral,
                order.size,
                positionVault.getPaidFees(_posId).paidPositionFee
            );
            _updateOrder(_posId, order.positionType, 0, 0, OrderStatus.FILLED);
            positionVault.removeUserOpenOrder(position.owner, _posId);
        } else if (order.positionType == POSITION_STOP_LIMIT) {
            if (position.isLong) {
                require(order.stpPrice <= price, "trigger not met");
            } else {
                require(order.stpPrice >= price, "trigger not met");
            }
            _updateOrder(_posId, POSITION_LIMIT, order.collateral, order.size, order.status);
        } else if (order.positionType == POSITION_TRAILING_STOP) {
            if (position.isLong) {
                require(order.stpPrice >= price, "trigger not met");
            } else {
                require(order.stpPrice <= price, "trigger not met");
            }
            positionVault.decreasePositionByOrderVault(_posId, price, order.size);
            _updateOrder(_posId, POSITION_MARKET, 0, 0, OrderStatus.FILLED);
        } else {
            revert("!positionType");
        }
    }

    function triggerForTPSL(uint256 _posId) external nonReentrant onlyOperator(1) {
        (uint256 triggeredAmount, uint256 triggerPrice) = executeTriggerOrders(_posId);
        positionVault.decreasePositionByOrderVault(_posId, triggerPrice, triggeredAmount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getOrder(uint256 _posId) external view override returns (Order memory) {
        return orders[_posId];
    }

    function getAddPositionOrder(uint256 _posId) external view override returns (AddPositionOrder memory) {
        return addPositionOrders[_posId];
    }

    function getDecreasePositionOrder(uint256 _posId) external view override returns (DecreasePositionOrder memory) {
        return decreasePositionOrders[_posId];
    }

    function getTriggerOrderInfo(uint256 _posId) external view override returns (PositionTrigger memory) {
        return triggerOrders[_posId];
    }

    function getAliveTriggerIds(uint256 _posId) external view returns (uint256[] memory _aliveTriggerIds) {
        uint256 length = EnumerableSetUpgradeable.length(aliveTriggerIds[_posId]);
        _aliveTriggerIds = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            _aliveTriggerIds[i] = EnumerableSetUpgradeable.at(aliveTriggerIds[_posId], i);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    NONE,
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct Order {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 size;
    uint256 collateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 timestamp;
}

struct AddPositionOrder {
    address owner;
    uint256 collateral;
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
    uint256 fee;
}

struct DecreasePositionOrder {
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}

struct PaidFees {
    uint256 paidPositionFee;
    uint256 paidBorrowFee;
    int256 paidFundingFee;
}

struct Temp {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
}

struct TriggerInfo {
    bool isTP;
    uint256 amountPercent;
    uint256 createdAt;
    uint256 price;
    uint256 triggeredAmount;
    uint256 triggeredAt;
    TriggerStatus status;
}

struct PositionTrigger {
    TriggerInfo[] triggers;
}