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

import {Position, Order, OrderType} from "../structs.sol";

interface ILiquidateVault {
    function validateLiquidationWithPosid(uint256 _posId) external view returns (bool, int256, int256, int256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
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

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/ILiquidateVault.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IOperators.sol";
import "../staking/interfaces/ITokenFarm.sol";
import "../tokens/interfaces/IVUSD.sol";
import {Constants} from "../access/Constants.sol";

contract SettingsManager is ISettingsManager, Initializable, ReentrancyGuardUpgradeable, Constants {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // constants
    ILiquidateVault public liquidateVault;
    IPositionVault public positionVault;
    ITokenFarm public tokenFarm;
    IOperators public operators;
    address public vusd;

    /* ========== VAULT SETTINGS ========== */
    uint256 public override cooldownDuration;
    mapping(address => bool) public override isWhitelistedFromCooldown;
    uint256 public override feeRewardBasisPoints;
    address public override feeManager;
    uint256 public override maxProfitPercent;

    event SetCooldownDuration(uint256 cooldownDuration);
    event SetIsWhitelistedFromCooldown(address addr, bool isWhitelisted);
    event SetFeeRewardBasisPoints(uint256 feeRewardBasisPoints);
    event SetFeeManager(address indexed feeManager);
    event SetMaxProfitPercent(uint256 maxProfitPercent);

    /* ========== VAULT SWITCH ========== */
    mapping(address => bool) public override isDeposit;
    mapping(address => bool) public override isWithdraw;
    mapping(address => bool) public override isStakingEnabled;
    mapping(address => bool) public override isUnstakingEnabled;

    event SetEnableDeposit(address indexed token, bool isEnabled);
    event SetEnableWithdraw(address indexed token, bool isEnabled);
    event SetEnableStaking(address indexed token, bool isEnabled);
    event SetEnableUnstaking(address indexed token, bool isEnabled);

    /* ========== VAULT FEE ========== */
    mapping(address => uint256) public override depositFee;
    mapping(address => uint256) public override withdrawFee;
    mapping(address => uint256) public override stakingFee;
    mapping(address => uint256) public override unstakingFee;

    event SetDepositFee(address indexed token, uint256 indexed fee);
    event SetWithdrawFee(address indexed token, uint256 indexed fee);
    event SetStakingFee(address indexed token, uint256 indexed fee);
    event SetUnstakingFee(address indexed token, uint256 indexed fee);

    /* ========== TRADING FEE ========== */
    mapping(uint256 => mapping(bool => uint256)) public override tradingFee; // 100 = 0.1%
    mapping(address => uint256) public override deductFeePercent;

    event SetTradingFee(uint256 indexed tokenId, bool isLong, uint256 tradingFee);
    event SetDeductFeePercent(address indexed account, uint256 deductFee);

    /* ========== FUNDING FEE ========== */
    uint256 public override basisFundingRateFactor;
    mapping(uint256 => uint256) public override fundingRateFactor;
    uint256 public override maxFundingRate;

    event SetBasisFundingRateFactor(uint256 basisFundingRateFactor);
    event SetFundingRateFactor(uint256 indexed tokenId, uint256 fundingRateFactor);
    event SetMaxFundingRate(uint256 maxFundingRateFactor);

    mapping(uint256 => int256) public override fundingIndex;
    mapping(uint256 => uint256) public override lastFundingTimes;

    event UpdateFunding(uint256 indexed tokenId, int256 fundingIndex);

    /* ========== BORROW FEE ========== */
    uint256 public override defaultBorrowFeeFactor;
    mapping(uint256 => uint256) public override borrowFeeFactor;

    event SetDefaultBorrowFeeFactor(uint256 borrowFeeFactor);
    event SetBorrowFeeFactor(uint256 tokenId, uint256 borrowFeeFactor);

    /* ========== REFER FEE ========== */
    mapping(address => uint256) public override referrerTiers;
    mapping(uint256 => uint256) public override tierFees;

    event SetReferrerTier(address referrer, uint256 tier);
    event SetTierFee(uint256 tier, uint256 fee);

    /* ========== INCREASE/DECREASE POSITION ========== */
    mapping(uint256 => bool) public override isIncreasingPositionDisabled;
    mapping(uint256 => bool) public override isDecreasingPositionDisabled;
    uint256 public override minCollateral;
    uint256 public override closeDeltaTime;

    event SetIsIncreasingPositionDisabled(uint256 tokenId, bool isDisabled);
    event SetIsDecreasingPositionDisabled(uint256 tokenId, bool isDisabled);
    event SetMinCollateral(uint256 minCollateral);
    event SetCloseDeltaTime(uint256 deltaTime);

    /* ========== OPEN INTEREST MECHANISM ========== */
    uint256 public defaultMaxOpenInterestPerUser;
    mapping(address => uint256) public maxOpenInterestPerUser;
    mapping(uint256 => mapping(bool => uint256)) public maxOpenInterestPerAssetPerSide;

    event SetDefaultMaxOpenInterestPerUser(uint256 maxOIAmount);
    event SetMaxOpenInterestPerUser(address indexed account, uint256 maxOIAmount);
    event SetMaxOpenInterestPerAssetPerSide(uint256 indexed tokenId, bool isLong, uint256 maxOIAmount);

    mapping(address => uint256) public override openInterestPerUser;
    mapping(uint256 => mapping(bool => uint256)) public override openInterestPerAssetPerSide;
    uint256 public override totalOpenInterest;

    event IncreaseOpenInterest(uint256 indexed id, bool isLong, uint256 amount);
    event DecreaseOpenInterest(uint256 indexed id, bool isLong, uint256 amount);

    /* ========== MARKET ORDER ========== */
    uint256 public override marketOrderGasFee;
    uint256 public override expiryDuration;
    uint256 public override selfExecuteCooldown;

    event SetMarketOrderGasFee(uint256 indexed fee);
    event SetExpiryDuration(uint256 expiryDuration);
    event SetSelfExecuteCooldown(uint256 selfExecuteCooldown);

    /* ========== TRIGGER ORDER ========== */
    uint256 public override triggerGasFee;
    uint256 public override maxTriggerPerPosition;
    uint256 public override priceMovementPercent;

    event SetTriggerGasFee(uint256 indexed fee);
    event SetMaxTriggerPerPosition(uint256 value);
    event SetPriceMovementPercent(uint256 priceMovementPercent);

    /* ========== ARTIFICIAL SLIPPAGE MECHANISM ========== */
    mapping(uint256 => uint256) public override slippageFactor;

    event SetSlippageFactor(uint256 indexed tokenId, uint256 slippageFactor);

    /* ========== LIQUIDATE MECHANISM ========== */
    mapping(uint256 => uint256) public liquidateThreshold;
    uint256 public override liquidationPendingTime;
    struct BountyPercent {
        uint32 firstCaller;
        uint32 resolver;
    } // pack to save gas
    BountyPercent private bountyPercent_;

    event SetLiquidateThreshold(uint256 indexed tokenId, uint256 newThreshold);
    event SetLiquidationPendingTime(uint256 liquidationPendingTime);
    event SetBountyPercent(uint32 bountyPercentFirstCaller, uint32 bountyPercentResolver);

    /* ========== DELEGATE MECHANISM========== */
    mapping(address => EnumerableSetUpgradeable.AddressSet) private _delegatesByMaster;
    mapping(address => bool) public globalDelegates; // treat these addrs already be delegated

    event GlobalDelegatesChange(address indexed delegate, bool allowed);

    /* ========== BAN MECHANISM========== */
    EnumerableSetUpgradeable.AddressSet private banWalletList;

    /* ========== MODIFIERS ========== */
    modifier onlyVault() {
        require(msg.sender == address(positionVault) || msg.sender == address(liquidateVault), "Only vault");
        _;
    }

    modifier onlyOperator(uint256 level) {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
        _;
    }

    /* ========== INITIALIZE FUNCTION========== */
    function initialize(
        address _liquidateVault,
        address _positionVault,
        address _operators,
        address _vusd,
        address _tokenFarm
    ) public initializer {
        __ReentrancyGuard_init();
        liquidateVault = ILiquidateVault(_liquidateVault);
        positionVault = IPositionVault(_positionVault);
        operators = IOperators(_operators);
        tokenFarm = ITokenFarm(_tokenFarm);
        vusd = _vusd;
        priceMovementPercent = 50; // 0.05%
        maxProfitPercent = 10000; // 10%
        bountyPercent_ = BountyPercent({firstCaller: 20000, resolver: 50000}); // first caller 20%, resolver 50% and leftover to team
        liquidationPendingTime = 10; // allow 10 seconds for manager to resolve liquidation
        cooldownDuration = 3 hours;
        expiryDuration = 60; // 60 seconds
        selfExecuteCooldown = 60; // 60 seconds
        feeRewardBasisPoints = 50000; // 50%
        minCollateral = 5 * PRICE_PRECISION; // min 5 USD
        defaultBorrowFeeFactor = 10; // 0.01% per hour
        triggerGasFee = 0; //100 gwei;
        marketOrderGasFee = 0;
        basisFundingRateFactor = 10000;
        tierFees[0] = 5000; // 5% refer fee for default tier
        maxTriggerPerPosition = 10;
        defaultMaxOpenInterestPerUser = 10000000000000000 * PRICE_PRECISION;
        maxFundingRate = FUNDING_RATE_PRECISION / 100; // 1% per hour
    }

    /* ========== VAULT SETTINGS ========== */
    /* OP FUNCTIONS */
    function setCooldownDuration(uint256 _cooldownDuration) external onlyOperator(3) {
        require(_cooldownDuration <= MAX_COOLDOWN_DURATION, "invalid cooldownDuration");
        cooldownDuration = _cooldownDuration;
        emit SetCooldownDuration(_cooldownDuration);
    }

    function setIsWhitelistedFromCooldown(address _addr, bool _isWhitelisted) external onlyOperator(3) {
        isWhitelistedFromCooldown[_addr] = _isWhitelisted;
        emit SetIsWhitelistedFromCooldown(_addr, _isWhitelisted);
    }

    function setFeeRewardBasisPoints(uint256 _feeRewardsBasisPoints) external onlyOperator(3) {
        require(_feeRewardsBasisPoints <= BASIS_POINTS_DIVISOR, "Above max");
        feeRewardBasisPoints = _feeRewardsBasisPoints;
        emit SetFeeRewardBasisPoints(_feeRewardsBasisPoints);
    }

    function setFeeManager(address _feeManager) external onlyOperator(3) {
        feeManager = _feeManager;
        emit SetFeeManager(_feeManager);
    }

    function setMaxProfitPercent(uint256 _maxProfitPercent) external onlyOperator(3) {
        maxProfitPercent = _maxProfitPercent;
        emit SetMaxProfitPercent(_maxProfitPercent);
    }

    /* ========== VAULT SWITCH ========== */
    /* OP FUNCTIONS */
    function setEnableDeposit(address _token, bool _isEnabled) external onlyOperator(3) {
        isDeposit[_token] = _isEnabled;
        emit SetEnableDeposit(_token, _isEnabled);
    }

    function setEnableWithdraw(address _token, bool _isEnabled) external onlyOperator(3) {
        isWithdraw[_token] = _isEnabled;
        emit SetEnableWithdraw(_token, _isEnabled);
    }

    function setEnableStaking(address _token, bool _isEnabled) external onlyOperator(3) {
        isStakingEnabled[_token] = _isEnabled;
        emit SetEnableStaking(_token, _isEnabled);
    }

    function setEnableUnstaking(address _token, bool _isEnabled) external onlyOperator(3) {
        isUnstakingEnabled[_token] = _isEnabled;
        emit SetEnableUnstaking(_token, _isEnabled);
    }

    /* ========== VAULT FEE ========== */
    /* OP FUNCTIONS */
    function setDepositFee(address token, uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_DEPOSIT_WITHDRAW_FEE, "Above max");
        depositFee[token] = _fee;
        emit SetDepositFee(token, _fee);
    }

    function setWithdrawFee(address token, uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_DEPOSIT_WITHDRAW_FEE, "Above max");
        withdrawFee[token] = _fee;
        emit SetWithdrawFee(token, _fee);
    }

    function setStakingFee(address token, uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_STAKING_UNSTAKING_FEE, "Above max");
        stakingFee[token] = _fee;
        emit SetStakingFee(token, _fee);
    }

    function setUnstakingFee(address token, uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_STAKING_UNSTAKING_FEE, "Above max");
        unstakingFee[token] = _fee;
        emit SetUnstakingFee(token, _fee);
    }

    /* ========== TRADING FEE ========== */
    /* OP FUNCTIONS */
    function setTradingFee(uint256 _tokenId, bool _isLong, uint256 _tradingFee) external onlyOperator(3) {
        require(_tradingFee <= MAX_FEE_BASIS_POINTS, "Above max");
        tradingFee[_tokenId][_isLong] = _tradingFee;
        emit SetTradingFee(_tokenId, _isLong, _tradingFee);
    }

    function setDeductFeePercentForUser(address _account, uint256 _deductFee) external onlyOperator(2) {
        require(_deductFee <= BASIS_POINTS_DIVISOR, "Above max");
        deductFeePercent[_account] = _deductFee;
        emit SetDeductFeePercent(_account, _deductFee);
    }

    /* VIEW FUNCTIONS */
    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view override returns (uint256) {
        return
            (getUndiscountedTradingFee(_tokenId, _isLong, _sizeDelta) *
                (BASIS_POINTS_DIVISOR - deductFeePercent[_account]) *
                tokenFarm.getTierVela(_account)) / BASIS_POINTS_DIVISOR ** 2;
    }

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) public view override returns (uint256) {
        return (_sizeDelta * tradingFee[_tokenId][_isLong]) / BASIS_POINTS_DIVISOR;
    }

    /* ========== FUNDING FEE ========== */
    /* OP FUNCTIONS */
    function setBasisFundingRateFactor(uint256 _basisFundingRateFactor) external onlyOperator(3) {
        basisFundingRateFactor = _basisFundingRateFactor;
        emit SetBasisFundingRateFactor(_basisFundingRateFactor);
    }

    function setFundingRateFactor(uint256 _tokenId, uint256 _fundingRateFactor) external onlyOperator(3) {
        fundingRateFactor[_tokenId] = _fundingRateFactor;
        emit SetFundingRateFactor(_tokenId, _fundingRateFactor);
    }

    function setMaxFundingRate(uint256 _maxFundingRate) external onlyOperator(3) {
        require(_maxFundingRate <= MAX_FUNDING_RATE, "Above max");
        maxFundingRate = _maxFundingRate;
        emit SetMaxFundingRate(_maxFundingRate);
    }

    /* VAULT FUNCTIONS */
    // to update the fundingIndex every time before open interest changes
    function updateFunding(uint256 _tokenId) external override onlyVault {
        if (lastFundingTimes[_tokenId] != 0) {
            int256 latestFundingIndex = getLatestFundingIndex(_tokenId);
            fundingIndex[_tokenId] = latestFundingIndex;

            emit UpdateFunding(_tokenId, latestFundingIndex);
        }

        lastFundingTimes[_tokenId] = block.timestamp;
    }

    /* VIEW FUNCTIONS */
    // calculate fundingFee based on fundingIndex difference
    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) public view override returns (int256) {
        return
            _isLong
                ? (int256(_size) * (getLatestFundingIndex(_tokenId) - _fundingIndex)) / int256(FUNDING_RATE_PRECISION)
                : (int256(_size) * (_fundingIndex - getLatestFundingIndex(_tokenId))) / int256(FUNDING_RATE_PRECISION);
    }

    // calculate latestFundingIndex based on fundingChange
    function getLatestFundingIndex(uint256 _tokenId) public view returns (int256) {
        return fundingIndex[_tokenId] + getFundingChange(_tokenId);
    }

    // calculate fundingChange based on fundingRate and period it has taken effect
    function getFundingChange(uint256 _tokenId) public view returns (int256) {
        uint256 interval = block.timestamp - lastFundingTimes[_tokenId];
        if (interval == 0) return int256(0);

        return (getFundingRate(_tokenId) * int256(interval)) / int256(1 hours);
    }

    // calculate funding rate per hour with 1e15 decimals
    function getFundingRate(uint256 _tokenId) public view override returns (int256) {
        uint256 assetLongOI = openInterestPerAssetPerSide[_tokenId][true];
        uint256 assetShortOI = openInterestPerAssetPerSide[_tokenId][false];
        uint256 assetTotalOI = assetLongOI + assetShortOI;

        if (assetTotalOI == 0) return int256(0);

        if (assetLongOI >= assetShortOI) {
            uint256 fundingRate = ((assetLongOI - assetShortOI) *
                fundingRateFactor[_tokenId] *
                basisFundingRateFactor *
                BASIS_POINTS_DIVISOR) / assetTotalOI;

            if (fundingRate > maxFundingRate) {
                return int256(maxFundingRate);
            } else {
                return int256(fundingRate);
            }
        } else {
            uint256 fundingRate = ((assetShortOI - assetLongOI) *
                fundingRateFactor[_tokenId] *
                basisFundingRateFactor *
                BASIS_POINTS_DIVISOR) / assetTotalOI;

            if (fundingRate > maxFundingRate) {
                return -1 * int256(maxFundingRate);
            } else {
                return -1 * int256(fundingRate);
            }
        }
    }

    /* ========== BORROW FEE ========== */
    /* OP FUNCTIONS */
    function setDefaultBorrowFeeFactor(uint256 _defaultBorrowFeeFactor) external onlyOperator(3) {
        require(_defaultBorrowFeeFactor <= MAX_BORROW_FEE_FACTOR, "Above max");
        defaultBorrowFeeFactor = _defaultBorrowFeeFactor;
        emit SetDefaultBorrowFeeFactor(_defaultBorrowFeeFactor);
    }

    function setBorrowFeeFactor(uint256 _tokenId, uint256 _borrowFeeFactor) external onlyOperator(3) {
        require(_borrowFeeFactor <= MAX_BORROW_FEE_FACTOR, "Above max");
        borrowFeeFactor[_tokenId] = _borrowFeeFactor;
        emit SetBorrowFeeFactor(_tokenId, _borrowFeeFactor);
    }

    /* VIEW FUNCTIONS */
    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId
    ) public view override returns (uint256) {
        return
            ((block.timestamp - _lastIncreasedTime) * _borrowedSize * getBorrowRate(_tokenId)) /
            BASIS_POINTS_DIVISOR /
            1 hours;
    }

    // get borrow rate per hour with 1e5 decimals
    function getBorrowRate(uint256 _tokenId) public view returns (uint256) {
        uint256 _borrowFeeFactor = borrowFeeFactor[_tokenId];
        return _borrowFeeFactor == 0 ? defaultBorrowFeeFactor : _borrowFeeFactor;
    }

    /* ========== REFER FEE ========== */
    /* OP FUNCTIONS */
    function setReferrerTier(address _referrer, uint256 _tier) external onlyOperator(1) {
        referrerTiers[_referrer] = _tier;
        emit SetReferrerTier(_referrer, _tier);
    }

    function setTierFee(uint256 _tier, uint256 _fee) external onlyOperator(3) {
        require(_fee <= BASIS_POINTS_DIVISOR, "Above max");
        tierFees[_tier] = _fee;
        emit SetTierFee(_tier, _fee);
    }

    /* VIEW FUNCTIONS */
    function getReferFee(address _refer) external view override returns (uint256) {
        return tierFees[referrerTiers[_refer]];
    }

    /* ========== INCREASE/DECREASE POSITION ========== */
    /* OP FUNCTIONS */
    function setIsIncreasingPositionDisabled(uint256 _tokenId, bool _isDisabled) external onlyOperator(2) {
        isIncreasingPositionDisabled[_tokenId] = _isDisabled;
        emit SetIsIncreasingPositionDisabled(_tokenId, _isDisabled);
    }

    function setIsDecreasingPositionDisabled(uint256 _tokenId, bool _isDisabled) external onlyOperator(2) {
        isDecreasingPositionDisabled[_tokenId] = _isDisabled;
        emit SetIsDecreasingPositionDisabled(_tokenId, _isDisabled);
    }

    function setMinCollateral(uint256 _minCollateral) external onlyOperator(3) {
        minCollateral = _minCollateral;
        emit SetMinCollateral(_minCollateral);
    }

    function setCloseDeltaTime(uint256 _deltaTime) external onlyOperator(2) {
        require(_deltaTime <= MAX_DELTA_TIME, "Above max");
        closeDeltaTime = _deltaTime;
        emit SetCloseDeltaTime(_deltaTime);
    }

    /* VIEW FUNCTIONS */
    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view override returns (int256 pnl, int256 fundingFee, int256 borrowFee) {
        require(_averagePrice > 0, "avgPrice > 0");

        if (_isLong) {
            if (_lastPrice >= _averagePrice) {
                pnl = int256((_size * (_lastPrice - _averagePrice)) / _averagePrice);
            } else {
                pnl = -1 * int256((_size * (_averagePrice - _lastPrice)) / _averagePrice);
            }
        } else {
            if (_lastPrice <= _averagePrice) {
                pnl = int256((_size * (_averagePrice - _lastPrice)) / _averagePrice);
            } else {
                pnl = -1 * int256((_size * (_lastPrice - _averagePrice)) / _averagePrice);
            }
        }

        fundingFee = getFundingFee(_tokenId, _isLong, _size, _fundingIndex);
        borrowFee = int256(getBorrowFee(_size, _lastIncreasedTime, _tokenId) + _accruedBorrowFee);

        pnl = pnl - fundingFee - borrowFee;
    }

    /* ========== OPEN INTEREST MECHANISM ========== */
    /* OP FUNCTIONS */
    function setDefaultMaxOpenInterestPerUser(uint256 _maxAmount) external onlyOperator(1) {
        defaultMaxOpenInterestPerUser = _maxAmount;
        emit SetDefaultMaxOpenInterestPerUser(_maxAmount);
    }

    function setMaxOpenInterestPerUser(address _account, uint256 _maxAmount) external onlyOperator(2) {
        maxOpenInterestPerUser[_account] = _maxAmount;
        emit SetMaxOpenInterestPerUser(_account, _maxAmount);
    }

    function setMaxOpenInterestPerAsset(uint256 _tokenId, uint256 _maxAmount) external onlyOperator(2) {
        setMaxOpenInterestPerAssetPerSide(_tokenId, true, _maxAmount);
        setMaxOpenInterestPerAssetPerSide(_tokenId, false, _maxAmount);
    }

    function setMaxOpenInterestPerAssetPerSide(
        uint256 _tokenId,
        bool _isLong,
        uint256 _maxAmount
    ) public onlyOperator(2) {
        maxOpenInterestPerAssetPerSide[_tokenId][_isLong] = _maxAmount;
        emit SetMaxOpenInterestPerAssetPerSide(_tokenId, _isLong, _maxAmount);
    }

    /* VAULT FUNCTIONS */
    function increaseOpenInterest(
        uint256 _tokenId,
        address _sender,
        bool _isLong,
        uint256 _amount
    ) external override onlyVault {
        // check and increase openInterestPerUser
        uint256 _openInterestPerUser = openInterestPerUser[_sender];
        uint256 _maxOpenInterestPerUser = maxOpenInterestPerUser[_sender];
        if (_maxOpenInterestPerUser == 0) _maxOpenInterestPerUser = defaultMaxOpenInterestPerUser;
        require(_openInterestPerUser + _amount <= _maxOpenInterestPerUser, "user maxOI exceeded");
        openInterestPerUser[_sender] = _openInterestPerUser + _amount;

        // check and increase openInterestPerAssetPerSide
        uint256 _openInterestPerAssetPerSide = openInterestPerAssetPerSide[_tokenId][_isLong];
        require(
            _openInterestPerAssetPerSide + _amount <= maxOpenInterestPerAssetPerSide[_tokenId][_isLong],
            "asset side maxOI exceeded"
        );
        openInterestPerAssetPerSide[_tokenId][_isLong] = _openInterestPerAssetPerSide + _amount;

        // increase totalOpenInterest
        totalOpenInterest += _amount;

        emit IncreaseOpenInterest(_tokenId, _isLong, _amount);
    }

    function decreaseOpenInterest(
        uint256 _tokenId,
        address _sender,
        bool _isLong,
        uint256 _amount
    ) external override onlyVault {
        uint256 _openInterestPerUser = openInterestPerUser[_sender];
        if (_openInterestPerUser < _amount) {
            openInterestPerUser[_sender] = 0;
        } else {
            openInterestPerUser[_sender] = _openInterestPerUser - _amount;
        }

        uint256 _openInterestPerAssetPerSide = openInterestPerAssetPerSide[_tokenId][_isLong];
        if (_openInterestPerAssetPerSide < _amount) {
            openInterestPerAssetPerSide[_tokenId][_isLong] = 0;
        } else {
            openInterestPerAssetPerSide[_tokenId][_isLong] = _openInterestPerAssetPerSide - _amount;
        }

        uint256 _totalOpenInterest = totalOpenInterest;
        if (_totalOpenInterest < _amount) {
            totalOpenInterest = 0;
        } else {
            totalOpenInterest = _totalOpenInterest - _amount;
        }

        emit DecreaseOpenInterest(_tokenId, _isLong, _amount);
    }

    /* ========== MARKET ORDER ========== */
    /* OP FUNCTIONS */
    function setMarketOrderGasFee(uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_MARKET_ORDER_GAS_FEE, "Above max");
        marketOrderGasFee = _fee;
        emit SetMarketOrderGasFee(_fee);
    }

    function setExpiryDuration(uint256 _expiryDuration) external onlyOperator(3) {
        require(_expiryDuration <= MAX_EXPIRY_DURATION, "Above max");
        expiryDuration = _expiryDuration;
        emit SetExpiryDuration(_expiryDuration);
    }

    function setSelfExecuteCooldown(uint256 _selfExecuteCooldown) external onlyOperator(3) {
        require(_selfExecuteCooldown <= MAX_SELF_EXECUTE_COOLDOWN, "Above max");
        selfExecuteCooldown = _selfExecuteCooldown;
        emit SetSelfExecuteCooldown(_selfExecuteCooldown);
    }

    /* ========== TRIGGER ORDER ========== */
    /* OP FUNCTIONS */
    function setTriggerGasFee(uint256 _fee) external onlyOperator(3) {
        require(_fee <= MAX_TRIGGER_GAS_FEE, "Above max");
        triggerGasFee = _fee;
        emit SetTriggerGasFee(_fee);
    }

    function setMaxTriggerPerPosition(uint256 _value) external onlyOperator(3) {
        maxTriggerPerPosition = _value;
        emit SetMaxTriggerPerPosition(_value);
    }

    function setPriceMovementPercent(uint256 _priceMovementPercent) external onlyOperator(3) {
        require(_priceMovementPercent <= MAX_PRICE_MOVEMENT_PERCENT, "Above max");
        priceMovementPercent = _priceMovementPercent;
        emit SetPriceMovementPercent(_priceMovementPercent);
    }

    /* ========== ARTIFICIAL SLIPPAGE MECHANISM ========== */
    /* OP FUNCTIONS */
    function setSlippageFactor(uint256 _tokenId, uint256 _slippageFactor) external onlyOperator(3) {
        require(_slippageFactor <= BASIS_POINTS_DIVISOR, "Above max");
        slippageFactor[_tokenId] = _slippageFactor;
        emit SetSlippageFactor(_tokenId, _slippageFactor);
    }

    /* VIEW FUNCTIONS */
    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view override returns (uint256) {
        uint256 _slippageFactor = slippageFactor[_tokenId];

        if (_slippageFactor == 0) return _price;

        uint256 slippage = getSlippage(_slippageFactor, _size);

        return
            _isLong
                ? (_price * (BASIS_POINTS_DIVISOR + slippage)) / BASIS_POINTS_DIVISOR
                : (_price * (BASIS_POINTS_DIVISOR - slippage)) / BASIS_POINTS_DIVISOR;
    }

    function getSlippage(uint256 _slippageFactor, uint256 _size) public view returns (uint256) {
        return (_slippageFactor * (2 * totalOpenInterest + _size)) / (2 * positionVault.getVaultUSDBalance());
    }

    /* ========== LIQUIDATE MECHANISM ========== */
    /* OP FUNCTIONS */
    // the liquidateThreshold should range between 80% to 100%
    function setLiquidateThreshold(uint256 _tokenId, uint256 _liquidateThreshold) external onlyOperator(3) {
        require(
            _liquidateThreshold >= 8 * BASIS_POINTS_DIVISOR && _liquidateThreshold <= LIQUIDATE_THRESHOLD_DIVISOR,
            "Out of range"
        );
        liquidateThreshold[_tokenId] = _liquidateThreshold;
        emit SetLiquidateThreshold(_tokenId, _liquidateThreshold);
    }

    function setLiquidationPendingTime(uint256 _liquidationPendingTime) external onlyOperator(3) {
        require(_liquidationPendingTime <= 60, "Above max");
        liquidationPendingTime = _liquidationPendingTime;
        emit SetLiquidationPendingTime(_liquidationPendingTime);
    }

    function setBountyPercent(
        uint32 _bountyPercentFirstCaller,
        uint32 _bountyPercentResolver
    ) external onlyOperator(3) {
        require(_bountyPercentFirstCaller + _bountyPercentResolver <= BASIS_POINTS_DIVISOR, "invalid bountyPercent");
        bountyPercent_.firstCaller = _bountyPercentFirstCaller;
        bountyPercent_.resolver = _bountyPercentResolver;
        emit SetBountyPercent(_bountyPercentFirstCaller, _bountyPercentResolver);
    }

    /* VIEW FUNCTIONS */
    function bountyPercent() external view override returns (uint32, uint32) {
        return (bountyPercent_.firstCaller, bountyPercent_.resolver);
    }

    /* ========== DELEGATE MECHANISM========== */
    /* USER FUNCTIONS */
    function delegate(address[] memory _delegates) external {
        for (uint256 i = 0; i < _delegates.length; ++i) {
            EnumerableSetUpgradeable.add(_delegatesByMaster[msg.sender], _delegates[i]);
        }
    }

    function undelegate(address[] memory _delegates) external {
        for (uint256 i = 0; i < _delegates.length; ++i) {
            EnumerableSetUpgradeable.remove(_delegatesByMaster[msg.sender], _delegates[i]);
        }
    }

    /* OP FUNCTIONS */
    function setGlobalDelegates(address _delegate, bool _allowed) external onlyOperator(2) {
        globalDelegates[_delegate] = _allowed;
        emit GlobalDelegatesChange(_delegate, _allowed);
    }

    /* VIEW FUNCTIONS */
    function getDelegates(address _master) external view override returns (address[] memory) {
        return enumerate(_delegatesByMaster[_master]);
    }

    function checkDelegation(address _master, address _delegate) public view override returns (bool) {
        require(!checkBanList(_master), "account banned");
        return
            _master == _delegate ||
            globalDelegates[_delegate] ||
            EnumerableSetUpgradeable.contains(_delegatesByMaster[_master], _delegate);
    }

    /* ========== BAN MECHANISM========== */
    /* OP FUNCTIONS */
    function addWalletsToBanList(address[] memory _wallets) external onlyOperator(1) {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            EnumerableSetUpgradeable.add(banWalletList, _wallets[i]);
        }
    }

    function removeWalletsFromBanList(address[] memory _wallets) external onlyOperator(1) {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            EnumerableSetUpgradeable.remove(banWalletList, _wallets[i]);
        }
    }

    /* VIEW FUNCTIONS */
    function checkBanList(address _addr) public view override returns (bool) {
        return EnumerableSetUpgradeable.contains(banWalletList, _addr);
    }

    function enumerate(EnumerableSetUpgradeable.AddressSet storage set) internal view returns (address[] memory) {
        uint256 length = EnumerableSetUpgradeable.length(set);
        address[] memory output = new address[](length);
        for (uint256 i; i < length; ++i) {
            output[i] = EnumerableSetUpgradeable.at(set, i);
        }
        return output;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function getTierVela(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVUSD {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);
}