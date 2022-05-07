// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdvancedQuesting {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LegionMetadataStoreState.sol";

interface ILegionMetadataStore {
    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(address _owner, uint256 _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity, uint256 _oldId) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(uint256 _tokenId, Constellation _constellation, uint8 _to) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns(LegionMetadata memory);

    // Returns the tokenUri for the given token.
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

// As this will likely change in the future, this should not be used to store state, but rather
// as parameters and return values from functions.
struct LegionMetadata {
    LegionGeneration legionGeneration;
    LegionClass legionClass;
    LegionRarity legionRarity;
    uint8 questLevel;
    uint8 craftLevel;
    uint8[6] constellationRanks;
    uint256 oldId;
}

enum Constellation {
    FIRE,
    EARTH,
    WIND,
    WATER,
    LIGHT,
    DARK
}

enum LegionRarity {
    LEGENDARY,
    RARE,
    SPECIAL,
    UNCOMMON,
    COMMON,
    RECRUIT
}

enum LegionClass {
    RECRUIT,
    SIEGE,
    FIGHTER,
    ASSASSIN,
    RANGED,
    SPELLCASTER,
    RIVERMAN,
    NUMERAIRE,
    ALL_CLASS,
    ORIGIN
}

enum LegionGeneration {
    GENESIS,
    AUXILIARY,
    RECRUIT
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./ILegionMetadataStore.sol";

abstract contract LegionMetadataStoreState is Initializable, AdminableUpgradeable {

    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(address indexed _owner, uint256 indexed _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity);

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint256) internal idToOldId;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    mapping(LegionGeneration => mapping(LegionClass => mapping(LegionRarity => mapping(uint256 => string)))) internal _genToClassToRarityToOldIdToUri;

    function __LegionMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TreasureMetadataStoreState.sol";

interface ITreasureMetadataStore {
    // Sets the metadata for the given Ids.
    // Admin only.
    function setMetadataForIds(uint256[] calldata _ids, TreasureMetadata[] calldata _metadatas) external;

    // Returns if the given ID has metadata set.
    function hasMetadataForTreasureId(uint256 _treasureId) external view returns(bool);

    // Returns the metadata for the given ID. Reverts if no metadata for the ID is set.
    function getMetadataForTreasureId(uint256 _treasureId) external view returns(TreasureMetadata memory);

    // For the given tier, gets a random MINTABLE treasure id.
    function getRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);

    // For the given tier AND category, gets a random MINTABLE treasure id.
    function getRandomTreasureForTierAndCategory(
        uint8 _tier,
        TreasureCategory _category,
        uint256 _randomNumber)
    external view returns(uint256);

    // For the given tier, gets a random treasure id, MINTABLE OR NOT.
    function getAnyRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);
}

// Do not change. Stored in state.
struct TreasureMetadata {
    TreasureCategory category;
    uint8 tier;
    // Out of 100,000
    uint32 craftingBreakOdds;
    bool isMintable;
    uint256 consumableIdDropWhenBreak;
}

enum TreasureCategory {
    ALCHEMY,
    ARCANA,
    BREWING,
    ENCHANTER,
    LEATHERWORKING,
    SMITHING
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/AdminableUpgradeable.sol";
import "./ITreasureMetadataStore.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract TreasureMetadataStoreState is AdminableUpgradeable {

    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToMintableTreasureIds;
    mapping(uint256 => TreasureMetadata) internal treasureIdToMetadata;
    mapping(uint8 => mapping(TreasureCategory => EnumerableSetUpgradeable.UintSet)) internal tierToCategoryToMintableTreasureIds;
    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToTreasureIds;

    function __TreasureMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";

interface ITreasureTriad {
    function generateBoardAndPlayGame(
        uint256 _randomNumber,
        LegionClass _legionClass,
        UserMove[] calldata _userMoves)
    external
    view
    returns(GameOutcome memory);

}

enum PlayerType {
    NONE,
    NATURE,
    USER
}

// Represents the information contained in a single cell of the game grid.
struct GridCell {
    // The treasure played on this cell. May be 0 if PlayerType == NONE
    uint256 treasureId;

    // The type of player that has played on this cell.
    PlayerType playerType;

    // In the case that playerType == NATURE, if this is true, the player has flipped this card to their side.
    bool isFlipped;

    // Indicates if the cell is corrupted.
    // If the cell is empty, the player must place a card on it to make it uncorrupted.
    // If the cell has a contract/nature card, the player must flip the card to make it uncorrupted.
    bool isCorrupted;

    // Indicates if this cell has an affinity. If so, look at the affinity field.
    bool hasAffinity;

    // The affinity of this field. Only consider this field if hasAffinity is true.
    TreasureCategory affinity;
}

// Represents a move the end user will make.
struct UserMove {
    // The x coordinate of the location
    uint8 x;
    // The y coordinate of the location.
    uint8 y;
    // The treasure to place at this location.
    uint256 treasureId;
}

struct GameOutcome {
    uint8 numberOfFlippedCards;
    uint8 numberOfCorruptedCardsLeft;
    bool playerWon;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TreasureTriadBoardGeneration.sol";

contract TreasureTriad is Initializable, TreasureTriadBoardGeneration {

    function initialize() external initializer {
        TreasureTriadBoardGeneration.__TreasureTriadBoardGeneration_init();
    }

    // _userMoves length has already been verified.
    function generateBoardAndPlayGame(
        uint256 _randomNumber,
        LegionClass _legionClass,
        UserMove[] calldata _userMoves)
    external
    view
    override
    returns(GameOutcome memory)
    {
        GridCell[3][3] memory _gameBoard = generateBoard(_randomNumber);

        return playGame(_gameBoard, _legionClass, _userMoves);
    }

    function playGame(
        GridCell[3][3] memory _gameBoard,
        LegionClass _legionClass,
        UserMove[] calldata _userMoves)
    public
    view
    returns(GameOutcome memory)
    {
        // Loop through moves and play the cards.
        for(uint256 i = 0; i < _userMoves.length; i++) {
            UserMove calldata _userMove = _userMoves[i];

            _placeAndFlipCards(_gameBoard, _legionClass, _userMove);
        }

        return _determineOutcome(_gameBoard);
    }

    function _determineOutcome(GridCell[3][3] memory _gameBoard) private view returns(GameOutcome memory) {
        GameOutcome memory _outcome;
        for(uint256 x = 0; x < 3; x++) {
            for(uint256 y = 0; y < 3; y++) {
                if(_gameBoard[y][x].isFlipped) {
                    _outcome.numberOfFlippedCards++;
                }
                if(_gameBoard[y][x].isCorrupted) {
                    // Either they didn't place a card on the corrupted cell.
                    // Or the corrupted cell was a nature cell and they did not flip it.
                    if(_gameBoard[y][x].playerType == PlayerType.NONE) {
                        _outcome.numberOfCorruptedCardsLeft++;
                    } else if(_gameBoard[y][x].playerType == PlayerType.NATURE && !_gameBoard[y][x].isFlipped) {
                        _outcome.numberOfCorruptedCardsLeft++;
                    }
                }
            }
        }

        _outcome.playerWon = _outcome.numberOfFlippedCards >= numberOfFlippedCardsToWin;

        return _outcome;
    }

    function _placeAndFlipCards(GridCell[3][3] memory _gameBoard, LegionClass _legionClass, UserMove calldata _userMove) private view {
        require(_userMove.x < 3 && _userMove.y < 3, "TreasureTriad: Bad move indices");

        GridCell memory _playerCell = _gameBoard[_userMove.y][_userMove.x];

        require(_playerCell.playerType == PlayerType.NONE, "TreasureTriad: Cell is occupied");

        _playerCell.playerType = PlayerType.USER;
        _playerCell.treasureId = _userMove.treasureId;

        uint8 _playerCardBoost = _getCardBoost(_playerCell, _legionClass);

        if(_userMove.x > 0) { // West
            GridCell memory _cellToWest = _gameBoard[_userMove.y][_userMove.x - 1];
            if(_cellToWest.playerType == PlayerType.NATURE && !_cellToWest.isFlipped) {
                uint8 _natureCardBoost = _getCardBoost(_cellToWest, _legionClass);
                uint8 _natureCardValue = treasureIdToCardInfo[_cellToWest.treasureId].east + _natureCardBoost;
                uint8 _playerCardValue = treasureIdToCardInfo[_playerCell.treasureId].west + _playerCardBoost;
                if(_playerCardValue > _natureCardValue) {
                    _cellToWest.isFlipped = true;
                }
            }
        }
        if(_userMove.x < 2) { // East
            GridCell memory _cellToEast = _gameBoard[_userMove.y][_userMove.x + 1];
            if(_cellToEast.playerType == PlayerType.NATURE && !_cellToEast.isFlipped) {
                uint8 _natureCardBoost = _getCardBoost(_cellToEast, _legionClass);
                uint8 _natureCardValue = treasureIdToCardInfo[_cellToEast.treasureId].west + _natureCardBoost;
                uint8 _playerCardValue = treasureIdToCardInfo[_playerCell.treasureId].east + _playerCardBoost;
                if(_playerCardValue > _natureCardValue) {
                    _cellToEast.isFlipped = true;
                }
            }
        }
        if(_userMove.y > 0) { // North
            GridCell memory _cellToNorth = _gameBoard[_userMove.y - 1][_userMove.x];
            if(_cellToNorth.playerType == PlayerType.NATURE && !_cellToNorth.isFlipped) {
                uint8 _natureCardBoost = _getCardBoost(_cellToNorth, _legionClass);
                uint8 _natureCardValue = treasureIdToCardInfo[_cellToNorth.treasureId].south + _natureCardBoost;
                uint8 _playerCardValue = treasureIdToCardInfo[_playerCell.treasureId].north + _playerCardBoost;
                if(_playerCardValue > _natureCardValue) {
                    _cellToNorth.isFlipped = true;
                }
            }
        }
        if(_userMove.y < 2) { // South
            GridCell memory _cellToSouth = _gameBoard[_userMove.y + 1][_userMove.x];
            if(_cellToSouth.playerType == PlayerType.NATURE && !_cellToSouth.isFlipped) {
                uint8 _natureCardBoost = _getCardBoost(_cellToSouth, _legionClass);
                uint8 _natureCardValue = treasureIdToCardInfo[_cellToSouth.treasureId].north + _natureCardBoost;
                uint8 _playerCardValue = treasureIdToCardInfo[_playerCell.treasureId].south + _playerCardBoost;
                if(_playerCardValue > _natureCardValue) {
                    _cellToSouth.isFlipped = true;
                }
            }
        }
    }

    function _getCardBoost(GridCell memory _gridCell, LegionClass _legionClass) private view returns(uint8) {
        uint8 _boost;

        // No treasure placed or no affinity on cell.
        if(_gridCell.playerType == PlayerType.NONE || !_gridCell.hasAffinity) {
            return _boost;
        }

        if(_gridCell.playerType == PlayerType.USER
            && classToTreasureCategoryToHasAffinity[_legionClass][_gridCell.affinity])
        {
             _boost++;
        }

        if(_gridCell.affinity == affinityForTreasure(_gridCell.treasureId)) {
            _boost++;
        }

        return _boost;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TreasureTriadSettings.sol";

abstract contract TreasureTriadBoardGeneration is Initializable, TreasureTriadSettings {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function __TreasureTriadBoardGeneration_init() internal initializer {
        TreasureTriadSettings.__TreasureTriadSettings_init();
    }

    function generateGameBoardForRequest(
        uint256 _requestId)
    external
    view
    returns(GridCell[3][3] memory)
    {
        uint256 _randomNumber = randomizer.revealRandomNumber(_requestId);

        return generateBoard(_randomNumber);
    }

    function generateBoard(uint256 _randomNumber) public view returns(GridCell[3][3] memory) {
        // Scramble the random with a constant number to get something fresh. The original random number may have been used.
        // Each random "thing" will use 8 bits, so we have 32 randoms within this number.
        _randomNumber = uint256(keccak256(abi.encode(_randomNumber,
            87286653073518694003612111662158573257766609697701829039857854141943741550340)));

        GridCell[3][3] memory _gameBoard;

        // Uses 72 bits of the random number
        _randomNumber = _placeNatureCards(_gameBoard, _randomNumber);

        // Uses 32 bits of the random number
        _randomNumber = _placeAffinities(_gameBoard, _randomNumber);

        // Uses 8-24 bits of the random number.
        _placeCorruptCells(_gameBoard, _randomNumber);

        return _gameBoard;
    }

    function _placeCorruptCells(
        GridCell[3][3] memory _gameBoard,
        uint256 _randomNumber)
    private
    pure
    {
        // The options for number of corrupted cells are 0, 1, 2.
        uint8 _numberOfCorruptedCells = uint8(_randomNumber % MAX_NUMBER_OF_CORRUPTED_CELLS + 1);
        if(_numberOfCorruptedCells == 0) {
            return;
        }

        _randomNumber >>= 8;

        uint8[2][] memory _corruptedCellCoordinates = _pickRandomUniqueCoordinates(_numberOfCorruptedCells, _randomNumber);

        for(uint256 i = 0; i < _numberOfCorruptedCells; i++) {
            _gameBoard[_corruptedCellCoordinates[i][0]][_corruptedCellCoordinates[i][1]].isCorrupted = true;
        }
    }

    function _placeAffinities(
        GridCell[3][3] memory _gameBoard,
        uint256 _randomNumber)
    private
    pure
    returns(uint256)
    {
        uint8[2][] memory _affinityCellCoordinates = _pickRandomUniqueCoordinates(NUMBER_OF_CELLS_WITH_AFFINITY, _randomNumber);

        _randomNumber >>= (8 * NUMBER_OF_CELLS_WITH_AFFINITY);

        for(uint256 i = 0; i < NUMBER_OF_CELLS_WITH_AFFINITY; i++) {
            // Pick affinity type. Six affinities in total.
            TreasureCategory _affinity = TreasureCategory(_randomNumber % 6);

            _randomNumber >>= 8;

            _gameBoard[_affinityCellCoordinates[i][0]][_affinityCellCoordinates[i][1]].hasAffinity = true;
            _gameBoard[_affinityCellCoordinates[i][0]][_affinityCellCoordinates[i][1]].affinity = _affinity;
        }

        return _randomNumber;
    }

    function _placeNatureCards(
        GridCell[3][3] memory _gameBoard,
        uint256 _randomNumber)
    private
    view
    returns(uint256)
    {
        uint8[2][] memory _contractTreasureCoordinates = _pickRandomUniqueCoordinates(NUMBER_OF_CONTRACT_CARDS, _randomNumber);

        _randomNumber >>= (8 * NUMBER_OF_CONTRACT_CARDS);

        for(uint256 i = 0; i < NUMBER_OF_CONTRACT_CARDS; i++) {
            // Pick tier
            uint256 _tierResult = _randomNumber % 256;
            _randomNumber >>= 8;

            uint256 _topRange = 0;

            uint8 _tier;

            for(uint256 j = 0; j < 5; j++) {
                _topRange += baseTreasureRarityPerTier[j];

                if(_tierResult < _topRange) {
                    _tier = uint8(j + 1);
                    break;
                }
            }

            uint256 _treasureId = treasureMetadataStore.getAnyRandomTreasureForTier(_tier, _randomNumber);

            _randomNumber >>= 8;

            _gameBoard[_contractTreasureCoordinates[i][0]][_contractTreasureCoordinates[i][1]].treasureId = _treasureId;
            _gameBoard[_contractTreasureCoordinates[i][0]][_contractTreasureCoordinates[i][1]].playerType = PlayerType.NATURE;
        }

        return _randomNumber;
    }

    // Need to adjust random number after calling this function.
    // Adjust be 8 * _amount bits.
    function _pickRandomUniqueCoordinates(
        uint8 _amount,
        uint256 _randomNumber)
    private
    pure
    returns(uint8[2][] memory)
    {
        uint8[2][9] memory _gridCells = [
            [0,0],
            [0,1],
            [0,2],
            [1,0],
            [1,1],
            [1,2],
            [2,0],
            [2,1],
            [2,2]
        ];

        uint8 _numCells = 9;

        uint8[2][] memory _pickedCoordinates = new uint8[2][](_amount);

        for(uint256 i = 0; i < _amount; i++) {
            uint256 _cell = _randomNumber % _numCells;
            _pickedCoordinates[i] = _gridCells[_cell];
            _randomNumber >>= 8;
            _numCells--;
            if(_cell != _numCells) {
                _gridCells[_cell] = _gridCells[_numCells];
            }
        }

        return _pickedCoordinates;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TreasureTriadState.sol";

abstract contract TreasureTriadContracts is Initializable, TreasureTriadState {

    function __TreasureTriadContracts_init() internal initializer {
        TreasureTriadState.__TreasureTriadState_init();
    }

    function setContracts(
        address _advancedQuestingAddress,
        address _treasureMetadataStoreAddress,
        address _randomizerAddress)
    external onlyAdminOrOwner
    {
        advancedQuesting = IAdvancedQuesting(_advancedQuestingAddress);
        treasureMetadataStore = ITreasureMetadataStore(_treasureMetadataStoreAddress);
        randomizer = IRandomizer(_randomizerAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "TreasureTriad: Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(advancedQuesting) != address(0)
            && address(treasureMetadataStore) != address(0)
            && address(randomizer) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TreasureTriadContracts.sol";

abstract contract TreasureTriadSettings is Initializable, TreasureTriadContracts {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function __TreasureTriadSettings_init() internal initializer {
        TreasureTriadContracts.__TreasureTriadContracts_init();
    }

    function addTreasureCardInfo(
        uint256[] calldata _treasureIds,
        CardInfo[] calldata _cardInfo)
    external
    onlyAdminOrOwner
    {
        require(_treasureIds.length > 0 && _treasureIds.length == _cardInfo.length,
            "TreasureTriad: Bad array lengths");

        for(uint256 i = 0; i < _treasureIds.length; i++) {
            require(_cardInfo[i].north > 0
                && _cardInfo[i].east > 0
                && _cardInfo[i].south > 0
                && _cardInfo[i].west > 0,
                "TreasureTriad: Cards must have a value on each side");

            treasureIds.add(_treasureIds[i]);

            treasureIdToCardInfo[_treasureIds[i]] = _cardInfo[i];

            emit TreasureCardInfoSet(_treasureIds[i], _cardInfo[i]);
        }
    }

    function affinityForTreasure(uint256 _treasureId) public view returns(TreasureCategory) {
        return treasureIdToCardInfo[_treasureId].category;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../advancedquesting/IAdvancedQuesting.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "./ITreasureTriad.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../../shared/randomizer/IRandomizer.sol";

abstract contract TreasureTriadState is Initializable, ITreasureTriad, AdminableUpgradeable {

    event TreasureCardInfoSet(uint256 _treasureId, CardInfo _cardInfo);

    uint8 constant NUMBER_OF_CONTRACT_CARDS = 3;
    uint8 constant NUMBER_OF_CELLS_WITH_AFFINITY = 2;
    uint8 constant MAX_NUMBER_OF_CORRUPTED_CELLS = 2;

    IAdvancedQuesting public advancedQuesting;
    ITreasureMetadataStore public treasureMetadataStore;

    // Used to check if the given legion class has an afinity for the treasure category (i.e. alchemy, arcana, etc.)
    mapping(LegionClass => mapping(TreasureCategory => bool)) public classToTreasureCategoryToHasAffinity;

    EnumerableSetUpgradeable.UintSet internal treasureIds;
    // Maps the treasure id to the info about the card.
    // Used for both contract and player placed cards.
    mapping(uint256 => CardInfo) public treasureIdToCardInfo;

    // The base rarities for each tier of treasure out of 256.
    uint8[5] public baseTreasureRarityPerTier;

    uint8 public numberOfFlippedCardsToWin;

    IRandomizer public randomizer;

    function __TreasureTriadState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        baseTreasureRarityPerTier = [51, 51, 51, 51, 52];

        numberOfFlippedCardsToWin = 2;

        _setInitialClassToCategory();
    }

    function _setInitialClassToCategory() private {
        classToTreasureCategoryToHasAffinity[LegionClass.SIEGE][TreasureCategory.ALCHEMY] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.SIEGE][TreasureCategory.ENCHANTER] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.FIGHTER][TreasureCategory.SMITHING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.FIGHTER][TreasureCategory.ENCHANTER] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.ASSASSIN][TreasureCategory.BREWING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ASSASSIN][TreasureCategory.LEATHERWORKING] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.RANGED][TreasureCategory.ALCHEMY] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.RANGED][TreasureCategory.LEATHERWORKING] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.SPELLCASTER][TreasureCategory.ARCANA] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.SPELLCASTER][TreasureCategory.ENCHANTER] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.RIVERMAN][TreasureCategory.BREWING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.RIVERMAN][TreasureCategory.ENCHANTER] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.NUMERAIRE][TreasureCategory.ARCANA] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.NUMERAIRE][TreasureCategory.ALCHEMY] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.ALCHEMY] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.ARCANA] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.BREWING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.ENCHANTER] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.LEATHERWORKING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ALL_CLASS][TreasureCategory.SMITHING] = true;

        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.ALCHEMY] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.ARCANA] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.BREWING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.ENCHANTER] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.LEATHERWORKING] = true;
        classToTreasureCategoryToHasAffinity[LegionClass.ORIGIN][TreasureCategory.SMITHING] = true;
    }
}

struct CardInfo {
    // While this is a repeat of the information stored in TreasureMetadataStore, overall it is beneficial
    // to have this information readily available in this contract.
    TreasureCategory category;
    uint8 north;
    uint8 east;
    uint8 south;
    uint8 west;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}