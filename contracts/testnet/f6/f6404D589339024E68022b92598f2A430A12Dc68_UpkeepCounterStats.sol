// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../KeeperBase.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/KeeperCompatibleInterface.sol";
import "../../interfaces/automation/1_2/KeeperRegistryInterface1_2.sol";
import "../../interfaces/automation/MigratableKeeperRegistryInterface.sol";
import "../../interfaces/automation/UpkeepTranscoderInterface.sol";
import "../../interfaces/ERC677ReceiverInterface.sol";

struct Upkeep {
  uint96 balance;
  address lastKeeper; // 1 storage slot full
  uint32 executeGas;
  uint64 maxValidBlocknumber;
  address target; // 2 storage slots full
  uint96 amountSpent;
  address admin; // 3 storage slots full
}

/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry1_2 is
  TypeAndVersionInterface,
  ConfirmedOwner,
  KeeperBase,
  ReentrancyGuard,
  Pausable,
  KeeperRegistryExecutableInterface,
  MigratableKeeperRegistryInterface,
  ERC677ReceiverInterface
{
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  address private constant ZERO_ADDRESS = address(0);
  address private constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 private constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 private constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 private constant PERFORM_GAS_MIN = 2_300;
  uint256 private constant CANCELATION_DELAY = 50;
  uint256 private constant PERFORM_GAS_CUSHION = 5_000;
  uint256 private constant REGISTRY_GAS_OVERHEAD = 80_000;
  uint256 private constant PPB_BASE = 1_000_000_000;
  uint64 private constant UINT64_MAX = 2**64 - 1;
  uint96 private constant LINK_TOTAL_SUPPLY = 1e27;

  address[] private s_keeperList;
  EnumerableSet.UintSet private s_upkeepIDs;
  mapping(uint256 => Upkeep) private s_upkeep;
  mapping(address => KeeperInfo) private s_keeperInfo;
  mapping(address => address) private s_proposedPayee;
  mapping(uint256 => bytes) private s_checkData;
  mapping(address => MigrationPermission) private s_peerRegistryMigrationPermission;
  Storage private s_storage;
  uint256 private s_fallbackGasPrice; // not in config object for gas savings
  uint256 private s_fallbackLinkPrice; // not in config object for gas savings
  uint96 private s_ownerLinkBalance;
  uint256 private s_expectedLinkBalance;
  address private s_transcoder;
  address private s_registrar;

  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  AggregatorV3Interface public immutable FAST_GAS_FEED;

  /**
   * @notice versions:
   * - KeeperRegistry 1.2.0: allow funding within performUpkeep
   *                       : allow configurable registry maxPerformGas
   *                       : add function to let admin change upkeep gas limit
   *                       : add minUpkeepSpend requirement
                           : upgrade to solidity v0.8
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 1.2.0";

  error CannotCancel();
  error UpkeepNotActive();
  error MigrationNotPermitted();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error NotAContract();
  error PaymentGreaterThanAllLINK();
  error OnlyActiveKeepers();
  error InsufficientFunds();
  error KeepersMustTakeTurns();
  error ParameterLengthError();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByLINKToken();
  error InvalidPayee();
  error DuplicateEntry();
  error ValueNotChanged();
  error IndexOutOfRange();
  error TranscoderNotSet();
  error ArrayHasNoEntries();
  error GasLimitOutsideRange();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedPayee();
  error GasLimitCanOnlyIncrease();
  error OnlyCallableByAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error InvalidRecipient();
  error InvalidDataLength();
  error TargetCheckReverted(bytes reason);

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  /**
   * @notice storage of the registry, contains a mix of config and state data
   */
  struct Storage {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink;
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend; // 1 evm word
    uint32 maxPerformGas;
    uint32 nonce; // 2 evm words
  }

  struct KeeperInfo {
    address payee;
    uint96 balance;
    bool active;
  }

  struct PerformParams {
    address from;
    uint256 id;
    bytes performData;
    uint256 maxLinkPayment;
    uint256 gasLimit;
    uint256 adjustedGasWei;
    uint256 linkEth;
  }

  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    address indexed from,
    uint96 payment,
    bytes performData
  );
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event OwnerFundsWithdrawn(uint96 amount);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event ConfigSet(Config config);
  event KeepersUpdated(address[] keepers, address[] payees);
  event PaymentWithdrawn(address indexed keeper, uint256 indexed amount, address indexed to, address payee);
  event PayeeshipTransferRequested(address indexed keeper, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed keeper, address indexed from, address indexed to);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);

  /**
   * @param link address of the LINK Token
   * @param linkEthFeed address of the LINK/ETH price feed
   * @param fastGasFeed address of the Fast Gas price feed
   * @param config registry config settings
   */
  constructor(
    address link,
    address linkEthFeed,
    address fastGasFeed,
    Config memory config
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    FAST_GAS_FEED = AggregatorV3Interface(fastGasFeed);
    setConfig(config);
  }

  // ACTIONS

  /**
   * @notice adds a new upkeep
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external override onlyOwnerOrRegistrar returns (uint256 id) {
    id = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), s_storage.nonce)));
    _createUpkeep(id, target, gasLimit, admin, 0, checkData);
    s_storage.nonce++;
    emit UpkeepRegistered(id, gasLimit, admin);
    return id;
  }

  /**
   * @notice simulated by keepers via eth_call to see if the upkeep needs to be
   * performed. If upkeep is needed, the call then simulates performUpkeep
   * to make sure it succeeds. Finally, it returns the success status along with
   * payment information and the perform data payload.
   * @param id identifier of the upkeep to check
   * @param from the address to simulate performing the upkeep from
   */
  function checkUpkeep(uint256 id, address from)
    external
    override
    cannotExecute
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    )
  {
    Upkeep memory upkeep = s_upkeep[id];

    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[id]);
    (bool success, bytes memory result) = upkeep.target.call{gas: s_storage.checkGasLimit}(callData);

    if (!success) revert TargetCheckReverted(result);

    (success, performData) = abi.decode(result, (bool, bytes));
    if (!success) revert UpkeepNotNeeded();

    PerformParams memory params = _generatePerformParams(from, id, performData, false);
    _prePerformUpkeep(upkeep, params.from, params.maxLinkPayment);

    return (performData, params.maxLinkPayment, params.gasLimit, params.adjustedGasWei, params.linkEth);
  }

  /**
   * @notice executes the upkeep with the perform data returned from
   * checkUpkeep, validates the keeper's permissions, and pays the keeper.
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   */
  function performUpkeep(uint256 id, bytes calldata performData)
    external
    override
    whenNotPaused
    returns (bool success)
  {
    return _performUpkeepWithParams(_generatePerformParams(msg.sender, id, performData, true));
  }

  /**
   * @notice prevent an upkeep from being performed in the future
   * @param id upkeep to be canceled
   */
  function cancelUpkeep(uint256 id) external override {
    uint64 maxValid = s_upkeep[id].maxValidBlocknumber;
    bool canceled = maxValid != UINT64_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && maxValid > block.number)) revert CannotCancel();
    if (!isOwner && msg.sender != s_upkeep[id].admin) revert OnlyCallableByOwnerOrAdmin();

    uint256 height = block.number;
    if (!isOwner) {
      height = height + CANCELATION_DELAY;
    }
    s_upkeep[id].maxValidBlocknumber = uint64(height);
    s_upkeepIDs.remove(id);

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @notice adds LINK funding for an upkeep by transferring from the sender's
   * LINK balance
   * @param id upkeep to fund
   * @param amount number of LINK to transfer
   */
  function addFunds(uint256 id, uint96 amount) external override onlyActiveUpkeep(id) {
    s_upkeep[id].balance = s_upkeep[id].balance + amount;
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    LINK.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external override {
    if (msg.sender != address(LINK)) revert OnlyCallableByLINKToken();
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (s_upkeep[id].maxValidBlocknumber != UINT64_MAX) revert UpkeepNotActive();

    s_upkeep[id].balance = s_upkeep[id].balance + uint96(amount);
    s_expectedLinkBalance = s_expectedLinkBalance + amount;

    emit FundsAdded(id, sender, uint96(amount));
  }

  /**
   * @notice removes funding from a canceled upkeep
   * @param id upkeep to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(uint256 id, address to) external validRecipient(to) onlyUpkeepAdmin(id) {
    if (s_upkeep[id].maxValidBlocknumber > block.number) revert UpkeepNotCanceled();

    uint96 minUpkeepSpend = s_storage.minUpkeepSpend;
    uint96 amountLeft = s_upkeep[id].balance;
    uint96 amountSpent = s_upkeep[id].amountSpent;

    uint96 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minUpkeepSpend - amountSpent,0), amountLeft)
    if (amountSpent < minUpkeepSpend) {
      cancellationFee = minUpkeepSpend - amountSpent;
      if (cancellationFee > amountLeft) {
        cancellationFee = amountLeft;
      }
    }
    uint96 amountToWithdraw = amountLeft - cancellationFee;

    s_upkeep[id].balance = 0;
    s_ownerLinkBalance = s_ownerLinkBalance + cancellationFee;

    s_expectedLinkBalance = s_expectedLinkBalance - amountToWithdraw;
    emit FundsWithdrawn(id, amountToWithdraw, to);

    LINK.transfer(to, amountToWithdraw);
  }

  /**
   * @notice withdraws LINK funds collected through cancellation fees
   */
  function withdrawOwnerFunds() external onlyOwner {
    uint96 amount = s_ownerLinkBalance;

    s_expectedLinkBalance = s_expectedLinkBalance - amount;
    s_ownerLinkBalance = 0;

    emit OwnerFundsWithdrawn(amount);
    LINK.transfer(msg.sender, amount);
  }

  /**
   * @notice allows the admin of an upkeep to modify gas limit
   * @param id upkeep to be change the gas limit for
   * @param gasLimit new gas limit for the upkeep
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external override onlyActiveUpkeep(id) onlyUpkeepAdmin(id) {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();

    s_upkeep[id].executeGas = gasLimit;

    emit UpkeepGasLimitSet(id, gasLimit);
  }

  /**
   * @notice recovers LINK funds improperly transferred to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gas limit. However, in our anticipated deployment, the number of upkeeps and
   * keepers will be low enough to avoid this problem.
   */
  function recoverFunds() external onlyOwner {
    uint256 total = LINK.balanceOf(address(this));
    LINK.transfer(msg.sender, total - s_expectedLinkBalance);
  }

  /**
   * @notice withdraws a keeper's payment, callable only by the keeper's payee
   * @param from keeper address
   * @param to address to send the payment to
   */
  function withdrawPayment(address from, address to) external validRecipient(to) {
    KeeperInfo memory keeper = s_keeperInfo[from];
    if (keeper.payee != msg.sender) revert OnlyCallableByPayee();

    s_keeperInfo[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance - keeper.balance;
    emit PaymentWithdrawn(from, keeper.balance, to, msg.sender);

    LINK.transfer(to, keeper.balance);
  }

  /**
   * @notice proposes the safe transfer of a keeper's payee to another address
   * @param keeper address of the keeper to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(address keeper, address proposed) external {
    if (s_keeperInfo[keeper].payee != msg.sender) revert OnlyCallableByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedPayee[keeper] != proposed) {
      s_proposedPayee[keeper] = proposed;
      emit PayeeshipTransferRequested(keeper, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the safe transfer of payee role for a keeper
   * @param keeper address to accept the payee role for
   */
  function acceptPayeeship(address keeper) external {
    if (s_proposedPayee[keeper] != msg.sender) revert OnlyCallableByProposedPayee();
    address past = s_keeperInfo[keeper].payee;
    s_keeperInfo[keeper].payee = msg.sender;
    s_proposedPayee[keeper] = ZERO_ADDRESS;

    emit PayeeshipTransferred(keeper, past, msg.sender);
  }

  /**
   * @notice signals to keepers that they should not perform upkeeps until the
   * contract has been unpaused
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice signals to keepers that they can perform upkeeps once again after
   * having been paused
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  // SETTERS

  /**
   * @notice updates the configuration of the registry
   * @param config registry config fields
   */
  function setConfig(Config memory config) public onlyOwner {
    if (config.maxPerformGas < s_storage.maxPerformGas) revert GasLimitCanOnlyIncrease();
    s_storage = Storage({
      paymentPremiumPPB: config.paymentPremiumPPB,
      flatFeeMicroLink: config.flatFeeMicroLink,
      blockCountPerTurn: config.blockCountPerTurn,
      checkGasLimit: config.checkGasLimit,
      stalenessSeconds: config.stalenessSeconds,
      gasCeilingMultiplier: config.gasCeilingMultiplier,
      minUpkeepSpend: config.minUpkeepSpend,
      maxPerformGas: config.maxPerformGas,
      nonce: s_storage.nonce
    });
    s_fallbackGasPrice = config.fallbackGasPrice;
    s_fallbackLinkPrice = config.fallbackLinkPrice;
    s_transcoder = config.transcoder;
    s_registrar = config.registrar;
    emit ConfigSet(config);
  }

  /**
   * @notice update the list of keepers allowed to perform upkeep
   * @param keepers list of addresses allowed to perform upkeep
   * @param payees addresses corresponding to keepers who are allowed to
   * move payments which have been accrued
   */
  function setKeepers(address[] calldata keepers, address[] calldata payees) external onlyOwner {
    if (keepers.length != payees.length || keepers.length < 2) revert ParameterLengthError();
    for (uint256 i = 0; i < s_keeperList.length; i++) {
      address keeper = s_keeperList[i];
      s_keeperInfo[keeper].active = false;
    }
    for (uint256 i = 0; i < keepers.length; i++) {
      address keeper = keepers[i];
      KeeperInfo storage s_keeper = s_keeperInfo[keeper];
      address oldPayee = s_keeper.payee;
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) || (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (s_keeper.active) revert DuplicateEntry();
      s_keeper.active = true;
      if (newPayee != IGNORE_ADDRESS) {
        s_keeper.payee = newPayee;
      }
    }
    s_keeperList = keepers;
    emit KeepersUpdated(keepers, payees);
  }

  // GETTERS

  /**
   * @notice read all of the details about an upkeep
   */
  function getUpkeep(uint256 id)
    external
    view
    override
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    )
  {
    Upkeep memory reg = s_upkeep[id];
    return (
      reg.target,
      reg.executeGas,
      s_checkData[id],
      reg.balance,
      reg.lastKeeper,
      reg.admin,
      reg.maxValidBlocknumber,
      reg.amountSpent
    );
  }

  /**
   * @notice retrieve active upkeep IDs
   * @param startIndex starting index in list
   * @param maxCount max count to retrieve (0 = unlimited)
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a wholistic picture of the contract state
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view override returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice read the current info about any keeper address
   */
  function getKeeperInfo(address query)
    external
    view
    override
    returns (
      address payee,
      bool active,
      uint96 balance
    )
  {
    KeeperInfo memory keeper = s_keeperInfo[query];
    return (keeper.payee, keeper.active, keeper.balance);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    override
    returns (
      State memory state,
      Config memory config,
      address[] memory keepers
    )
  {
    Storage memory store = s_storage;
    state.nonce = store.nonce;
    state.ownerLinkBalance = s_ownerLinkBalance;
    state.expectedLinkBalance = s_expectedLinkBalance;
    state.numUpkeeps = s_upkeepIDs.length();
    config.paymentPremiumPPB = store.paymentPremiumPPB;
    config.flatFeeMicroLink = store.flatFeeMicroLink;
    config.blockCountPerTurn = store.blockCountPerTurn;
    config.checkGasLimit = store.checkGasLimit;
    config.stalenessSeconds = store.stalenessSeconds;
    config.gasCeilingMultiplier = store.gasCeilingMultiplier;
    config.minUpkeepSpend = store.minUpkeepSpend;
    config.maxPerformGas = store.maxPerformGas;
    config.fallbackGasPrice = s_fallbackGasPrice;
    config.fallbackLinkPrice = s_fallbackLinkPrice;
    config.transcoder = s_transcoder;
    config.registrar = s_registrar;
    return (state, config, s_keeperList);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance) {
    return getMaxPaymentForGas(s_upkeep[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(uint256 gasLimit) public view returns (uint96 maxPayment) {
    (uint256 gasWei, uint256 linkEth) = _getFeedData();
    uint256 adjustedGasWei = _adjustGasPrice(gasWei, false);
    return _calculatePaymentAmount(gasLimit, adjustedGasWei, linkEth);
  }

  /**
   * @notice retrieves the migration permission for a peer registry
   */
  function getPeerRegistryMigrationPermission(address peer) external view returns (MigrationPermission) {
    return s_peerRegistryMigrationPermission[peer];
  }

  /**
   * @notice sets the peer registry migration permission
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external onlyOwner {
    s_peerRegistryMigrationPermission[peer] = permission;
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination) external override {
    if (
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.OUTGOING &&
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    if (s_transcoder == ZERO_ADDRESS) revert TranscoderNotSet();
    if (ids.length == 0) revert ArrayHasNoEntries();
    uint256 id;
    Upkeep memory upkeep;
    uint256 totalBalanceRemaining;
    bytes[] memory checkDatas = new bytes[](ids.length);
    Upkeep[] memory upkeeps = new Upkeep[](ids.length);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      id = ids[idx];
      upkeep = s_upkeep[id];
      if (upkeep.admin != msg.sender) revert OnlyCallableByAdmin();
      if (upkeep.maxValidBlocknumber != UINT64_MAX) revert UpkeepNotActive();
      upkeeps[idx] = upkeep;
      checkDatas[idx] = s_checkData[id];
      totalBalanceRemaining = totalBalanceRemaining + upkeep.balance;
      delete s_upkeep[id];
      delete s_checkData[id];
      s_upkeepIDs.remove(id);
      emit UpkeepMigrated(id, upkeep.balance, destination);
    }
    s_expectedLinkBalance = s_expectedLinkBalance - totalBalanceRemaining;
    bytes memory encodedUpkeeps = abi.encode(ids, upkeeps, checkDatas);
    MigratableKeeperRegistryInterface(destination).receiveUpkeeps(
      UpkeepTranscoderInterface(s_transcoder).transcodeUpkeeps(
        UpkeepFormat.V1,
        MigratableKeeperRegistryInterface(destination).upkeepTranscoderVersion(),
        encodedUpkeeps
      )
    );
    LINK.transfer(destination, totalBalanceRemaining);
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  UpkeepFormat public constant override upkeepTranscoderVersion = UpkeepFormat.V1;

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external override {
    if (
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.INCOMING &&
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    (uint256[] memory ids, Upkeep[] memory upkeeps, bytes[] memory checkDatas) = abi.decode(
      encodedUpkeeps,
      (uint256[], Upkeep[], bytes[])
    );
    for (uint256 idx = 0; idx < ids.length; idx++) {
      _createUpkeep(
        ids[idx],
        upkeeps[idx].target,
        upkeeps[idx].executeGas,
        upkeeps[idx].admin,
        upkeeps[idx].balance,
        checkDatas[idx]
      );
      emit UpkeepReceived(ids[idx], upkeeps[idx].balance, msg.sender);
    }
  }

  /**
   * @notice creates a new upkeep with the given fields
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function _createUpkeep(
    uint256 id,
    address target,
    uint32 gasLimit,
    address admin,
    uint96 balance,
    bytes memory checkData
  ) internal whenNotPaused {
    if (!target.isContract()) revert NotAContract();
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    s_upkeep[id] = Upkeep({
      target: target,
      executeGas: gasLimit,
      balance: balance,
      admin: admin,
      maxValidBlocknumber: UINT64_MAX,
      lastKeeper: ZERO_ADDRESS,
      amountSpent: 0
    });
    s_expectedLinkBalance = s_expectedLinkBalance + balance;
    s_checkData[id] = checkData;
    s_upkeepIDs.add(id);
  }

  /**
   * @dev retrieves feed data for fast gas/eth and link/eth prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData() private view returns (uint256 gasWei, uint256 linkEth) {
    uint32 stalenessSeconds = s_storage.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = FAST_GAS_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = LINK_ETH_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      linkEth = s_fallbackLinkPrice;
    } else {
      linkEth = uint256(feedValue);
    }
    return (gasWei, linkEth);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   */
  function _calculatePaymentAmount(
    uint256 gasLimit,
    uint256 gasWei,
    uint256 linkEth
  ) private view returns (uint96 payment) {
    uint256 weiForGas = gasWei * (gasLimit + REGISTRY_GAS_OVERHEAD);
    uint256 premium = PPB_BASE + s_storage.paymentPremiumPPB;
    uint256 total = ((weiForGas * (1e9) * (premium)) / (linkEth)) + (uint256(s_storage.flatFeeMicroLink) * (1e12));
    if (total > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function _callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * keeper and the exact gas required by the Upkeep
   */
  function _performUpkeepWithParams(PerformParams memory params)
    private
    nonReentrant
    validUpkeep(params.id)
    returns (bool success)
  {
    Upkeep memory upkeep = s_upkeep[params.id];
    _prePerformUpkeep(upkeep, params.from, params.maxLinkPayment);

    uint256 gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, params.performData);
    success = _callWithExactGas(params.gasLimit, upkeep.target, callData);
    gasUsed = gasUsed - gasleft();

    uint96 payment = _calculatePaymentAmount(gasUsed, params.adjustedGasWei, params.linkEth);

    s_upkeep[params.id].balance = s_upkeep[params.id].balance - payment;
    s_upkeep[params.id].amountSpent = s_upkeep[params.id].amountSpent + payment;
    s_upkeep[params.id].lastKeeper = params.from;
    s_keeperInfo[params.from].balance = s_keeperInfo[params.from].balance + payment;

    emit UpkeepPerformed(params.id, success, params.from, payment, params.performData);
    return success;
  }

  /**
   * @dev ensures all required checks are passed before an upkeep is performed
   */
  function _prePerformUpkeep(
    Upkeep memory upkeep,
    address from,
    uint256 maxLinkPayment
  ) private view {
    if (!s_keeperInfo[from].active) revert OnlyActiveKeepers();
    if (upkeep.balance < maxLinkPayment) revert InsufficientFunds();
    if (upkeep.lastKeeper == from) revert KeepersMustTakeTurns();
  }

  /**
   * @dev adjusts the gas price to min(ceiling, tx.gasprice) or just uses the ceiling if tx.gasprice is disabled
   */
  function _adjustGasPrice(uint256 gasWei, bool useTxGasPrice) private view returns (uint256 adjustedPrice) {
    adjustedPrice = gasWei * s_storage.gasCeilingMultiplier;
    if (useTxGasPrice && tx.gasprice < adjustedPrice) {
      adjustedPrice = tx.gasprice;
    }
  }

  /**
   * @dev generates a PerformParams struct for use in _performUpkeepWithParams()
   */
  function _generatePerformParams(
    address from,
    uint256 id,
    bytes memory performData,
    bool useTxGasPrice
  ) private view returns (PerformParams memory) {
    uint256 gasLimit = s_upkeep[id].executeGas;
    (uint256 gasWei, uint256 linkEth) = _getFeedData();
    uint256 adjustedGasWei = _adjustGasPrice(gasWei, useTxGasPrice);
    uint96 maxLinkPayment = _calculatePaymentAmount(gasLimit, adjustedGasWei, linkEth);

    return
      PerformParams({
        from: from,
        id: id,
        performData: performData,
        maxLinkPayment: maxLinkPayment,
        gasLimit: gasLimit,
        adjustedGasWei: adjustedGasWei,
        linkEth: linkEth
      });
  }

  // MODIFIERS

  /**
   * @dev ensures a upkeep is valid
   */
  modifier validUpkeep(uint256 id) {
    if (s_upkeep[id].maxValidBlocknumber <= block.number) revert UpkeepNotActive();
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the admin of upkeep #id
   */
  modifier onlyUpkeepAdmin(uint256 id) {
    if (msg.sender != s_upkeep[id].admin) revert OnlyCallableByAdmin();
    _;
  }

  /**
   * @dev Reverts if called on a cancelled upkeep
   */
  modifier onlyActiveUpkeep(uint256 id) {
    if (s_upkeep[id].maxValidBlocknumber != UINT64_MAX) revert UpkeepNotActive();
    _;
  }

  /**
   * @dev ensures that burns don't accidentally happen by sending to the zero
   * address
   */
  modifier validRecipient(address to) {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    _;
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner or registrar.
   */
  modifier onlyOwnerOrRegistrar() {
    if (msg.sender != owner() && msg.sender != s_registrar) revert OnlyCallableByOwnerOrRegistrar();
    _;
  }
}

pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import "../../vendor/@eth-optimism/contracts/0.8.6/contracts/L2/predeploys/OVM_GasPriceOracle.sol";
import "../ExecutionPrevention.sol";
import {Config, State, Upkeep} from "../../interfaces/automation/1_3/AutomationRegistryInterface1_3.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/KeeperCompatibleInterface.sol";
import "../../interfaces/automation/UpkeepTranscoderInterface.sol";

/**
 * @notice Base Keeper Registry contract, contains shared logic between
 * KeeperRegistry and KeeperRegistryLogic
 */
abstract contract KeeperRegistryBase1_3 is ConfirmedOwner, ExecutionPrevention, ReentrancyGuard, Pausable {
  address internal constant ZERO_ADDRESS = address(0);
  address internal constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 internal constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 internal constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 internal constant PERFORM_GAS_MIN = 2_300;
  uint256 internal constant CANCELLATION_DELAY = 50;
  uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
  uint256 internal constant PPB_BASE = 1_000_000_000;
  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint96 internal constant LINK_TOTAL_SUPPLY = 1e27;
  UpkeepFormat internal constant UPKEEP_TRANSCODER_VERSION_BASE = UpkeepFormat.V2;
  // L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  // MAX_INPUT_DATA represents the estimated max size of the sum of L1 data padding and msg.data in performUpkeep
  // function, which includes 4 bytes for function selector, 32 bytes for upkeep id, 35 bytes for data padding, and
  // 64 bytes for estimated perform data
  bytes internal constant MAX_INPUT_DATA =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  address[] internal s_keeperList;
  EnumerableSet.UintSet internal s_upkeepIDs;
  mapping(uint256 => Upkeep) internal s_upkeep;
  mapping(address => KeeperInfo) internal s_keeperInfo;
  mapping(address => address) internal s_proposedPayee;
  mapping(uint256 => address) internal s_proposedAdmin;
  mapping(uint256 => bytes) internal s_checkData;
  mapping(address => MigrationPermission) internal s_peerRegistryMigrationPermission;
  Storage internal s_storage;
  uint256 internal s_fallbackGasPrice; // not in config object for gas savings
  uint256 internal s_fallbackLinkPrice; // not in config object for gas savings
  uint96 internal s_ownerLinkBalance;
  uint256 internal s_expectedLinkBalance;
  address internal s_transcoder;
  address internal s_registrar;

  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  AggregatorV3Interface public immutable FAST_GAS_FEED;
  OVM_GasPriceOracle public immutable OPTIMISM_ORACLE = OVM_GasPriceOracle(0x420000000000000000000000000000000000000F);
  ArbGasInfo public immutable ARB_NITRO_ORACLE = ArbGasInfo(0x000000000000000000000000000000000000006C);
  PaymentModel public immutable PAYMENT_MODEL;
  uint256 public immutable REGISTRY_GAS_OVERHEAD;

  error ArrayHasNoEntries();
  error CannotCancel();
  error DuplicateEntry();
  error EmptyAddress();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidPayee();
  error InvalidRecipient();
  error KeepersMustTakeTurns();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveKeepers();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyPausedUpkeep();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error TargetCheckReverted(bytes reason);
  error TranscoderNotSet();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  enum PaymentModel {
    DEFAULT,
    ARBITRUM,
    OPTIMISM
  }

  /**
   * @notice storage of the registry, contains a mix of config and state data
   */
  struct Storage {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink;
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend; // 1 full evm word
    uint32 maxPerformGas;
    uint32 nonce;
  }

  struct KeeperInfo {
    address payee;
    uint96 balance;
    bool active;
  }

  struct PerformParams {
    address from;
    uint256 id;
    bytes performData;
    uint256 maxLinkPayment;
    uint256 gasLimit;
    uint256 fastGasWei;
    uint256 linkEth;
  }

  event ConfigSet(Config config);
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event KeepersUpdated(address[] keepers, address[] payees);
  event OwnerFundsWithdrawn(uint96 amount);
  event PayeeshipTransferRequested(address indexed keeper, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed keeper, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed keeper, uint256 indexed amount, address indexed to, address payee);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataUpdated(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    address indexed from,
    uint96 payment,
    bytes performData
  );
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepUnpaused(uint256 indexed id);
  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);

  /**
   * @param paymentModel the payment model of default, Arbitrum, or Optimism
   * @param registryGasOverhead the gas overhead used by registry in performUpkeep
   * @param link address of the LINK Token
   * @param linkEthFeed address of the LINK/ETH price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    PaymentModel paymentModel,
    uint256 registryGasOverhead,
    address link,
    address linkEthFeed,
    address fastGasFeed
  ) ConfirmedOwner(msg.sender) {
    PAYMENT_MODEL = paymentModel;
    REGISTRY_GAS_OVERHEAD = registryGasOverhead;
    if (ZERO_ADDRESS == link || ZERO_ADDRESS == linkEthFeed || ZERO_ADDRESS == fastGasFeed) {
      revert EmptyAddress();
    }
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    FAST_GAS_FEED = AggregatorV3Interface(fastGasFeed);
  }

  /**
   * @dev retrieves feed data for fast gas/eth and link/eth prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData() internal view returns (uint256 gasWei, uint256 linkEth) {
    uint32 stalenessSeconds = s_storage.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = FAST_GAS_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = LINK_ETH_FEED.latestRoundData();
    if ((staleFallback && stalenessSeconds < block.timestamp - timestamp) || feedValue <= 0) {
      linkEth = s_fallbackLinkPrice;
    } else {
      linkEth = uint256(feedValue);
    }
    return (gasWei, linkEth);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   * @param gasLimit the amount of gas used
   * @param fastGasWei the fast gas price
   * @param linkEth the exchange ratio between LINK and ETH
   * @param isExecution if this is triggered by a perform upkeep function
   */
  function _calculatePaymentAmount(
    uint256 gasLimit,
    uint256 fastGasWei,
    uint256 linkEth,
    bool isExecution
  ) internal view returns (uint96 payment) {
    Storage memory store = s_storage;
    uint256 gasWei = fastGasWei * store.gasCeilingMultiplier;
    // in case it's actual execution use actual gas price, capped by fastGasWei * gasCeilingMultiplier
    if (isExecution && tx.gasprice < gasWei) {
      gasWei = tx.gasprice;
    }

    uint256 weiForGas = gasWei * (gasLimit + REGISTRY_GAS_OVERHEAD);
    uint256 premium = PPB_BASE + store.paymentPremiumPPB;
    uint256 l1CostWei = 0;
    if (PAYMENT_MODEL == PaymentModel.OPTIMISM) {
      bytes memory txCallData = new bytes(0);
      if (isExecution) {
        txCallData = bytes.concat(msg.data, L1_FEE_DATA_PADDING);
      } else {
        txCallData = MAX_INPUT_DATA;
      }
      l1CostWei = OPTIMISM_ORACLE.getL1Fee(txCallData);
    } else if (PAYMENT_MODEL == PaymentModel.ARBITRUM) {
      l1CostWei = ARB_NITRO_ORACLE.getCurrentTxL1GasFees();
    }
    // if it's not performing upkeeps, use gas ceiling multiplier to estimate the upper bound
    if (!isExecution) {
      l1CostWei = store.gasCeilingMultiplier * l1CostWei;
    }

    uint256 total = ((weiForGas + l1CostWei) * 1e9 * premium) / linkEth + uint256(store.flatFeeMicroLink) * 1e12;
    if (total > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
  }

  /**
   * @dev ensures all required checks are passed before an upkeep is performed
   */
  function _prePerformUpkeep(
    Upkeep memory upkeep,
    address from,
    uint256 maxLinkPayment
  ) internal view {
    if (upkeep.paused) revert OnlyUnpausedUpkeep();
    if (!s_keeperInfo[from].active) revert OnlyActiveKeepers();
    if (upkeep.balance < maxLinkPayment) revert InsufficientFunds();
    if (upkeep.lastKeeper == from) revert KeepersMustTakeTurns();
  }

  /**
   * @dev ensures the upkeep is not cancelled and the caller is the upkeep admin
   */
  function requireAdminAndNotCancelled(Upkeep memory upkeep) internal view {
    if (msg.sender != upkeep.admin) revert OnlyCallableByAdmin();
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
  }

  /**
   * @dev generates a PerformParams struct for use in _performUpkeepWithParams()
   */
  function _generatePerformParams(
    address from,
    uint256 id,
    bytes memory performData,
    bool isExecution
  ) internal view returns (PerformParams memory) {
    uint256 gasLimit = s_upkeep[id].executeGas;
    (uint256 fastGasWei, uint256 linkEth) = _getFeedData();
    uint96 maxLinkPayment = _calculatePaymentAmount(gasLimit, fastGasWei, linkEth, isExecution);

    return
      PerformParams({
        from: from,
        id: id,
        performData: performData,
        maxLinkPayment: maxLinkPayment,
        gasLimit: gasLimit,
        fastGasWei: fastGasWei,
        linkEth: linkEth
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/2_0/AutomationRegistryInterface2_0.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/ERC677ReceiverInterface.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract KeeperRegistrar2_0 is TypeAndVersionInterface, ConfirmedOwner, ERC677ReceiverInterface {
  /**
   * DISABLED: No auto approvals, all new upkeeps should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new upkeeps subject to max allowed.
   */
  enum AutoApproveType {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  mapping(bytes32 => PendingRequest) private s_pendingRequests;

  LinkTokenInterface public immutable LINK;

  /**
   * @notice versions:
   * - KeeperRegistrar 2.0.0: Remove source from register
   *                          Breaks our example of "Register an Upkeep using your own deployed contract"
   * - KeeperRegistrar 1.1.0: Add functionality for sender allowlist in auto approve
   *                        : Remove rate limit and add max allowed for auto approve
   * - KeeperRegistrar 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistrar 2.0.0";

  struct RegistrarConfig {
    AutoApproveType autoApproveConfigType;
    uint32 autoApproveMaxAllowed;
    uint32 approvedCount;
    AutomationRegistryBaseInterface keeperRegistry;
    uint96 minLINKJuels;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
  }

  RegistrarConfig private s_config;
  // Only applicable if s_config.configType is ENABLED_SENDER_ALLOWLIST
  mapping(address => bool) private s_autoApproveAllowedSenders;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes checkData,
    uint96 amount
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed upkeepId);

  event RegistrationRejected(bytes32 indexed hash);

  event AutoApproveAllowedSenderSet(address indexed senderAddress, bool allowed);

  event ConfigChanged(
    AutoApproveType autoApproveConfigType,
    uint32 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  );

  error InvalidAdminAddress();
  error RequestNotFound();
  error HashMismatch();
  error OnlyAdminOrOwner();
  error InsufficientPayment();
  error RegistrationRequestFailed();
  error OnlyLink();
  error AmountMismatch();
  error SenderMismatch();
  error FunctionNotPermitted();
  error LinkTransferFailed(address to);
  error InvalidDataLength();

  /*
   * @param LINKAddress Address of Link token
   * @param autoApproveConfigType setting for auto-approve registrations
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  constructor(
    address LINKAddress,
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(LINKAddress);
    setRegistrationConfig(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param name string of the upkeep to be registered
   * @param encryptedEmail email address of upkeep contact
   * @param upkeepContract address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when performing upkeep
   * @param adminAddress address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param amount quantity of LINK upkeep is funded with (specified in Juels)
   * @param offchainConfig offchainConfig for upkeep in bytes
   * @param sender address of the sender making the request
   */
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    uint96 amount,
    address sender
  ) external onlyLINK {
    _register(
      RegistrationParams({
        name: name,
        encryptedEmail: encryptedEmail,
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: amount
      }),
      sender
    );
  }

  /**
   * @notice Allows external users to register upkeeps; assumes amount is approved for transfer by the contract
   * @param requestParams struct of all possible registration parameters
   */
  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256) {
    if (requestParams.amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }

    LINK.transferFrom(msg.sender, address(this), requestParams.amount);

    return _register(requestParams, msg.sender);
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    bytes32 hash
  ) external onlyOwner {
    PendingRequest memory request = s_pendingRequests[hash];
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    bytes32 expectedHash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData, offchainConfig));
    if (hash != expectedHash) {
      revert HashMismatch();
    }
    delete s_pendingRequests[hash];
    _approve(
      RegistrationParams({
        name: name,
        encryptedEmail: "",
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: request.balance
      }),
      expectedHash
    );
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the request.admin
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = s_pendingRequests[hash];
    if (!(msg.sender == request.admin || msg.sender == owner())) {
      revert OnlyAdminOrOwner();
    }
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    delete s_pendingRequests[hash];
    bool success = LINK.transfer(request.admin, request.balance);
    if (!success) {
      revert LinkTransferFailed(request.admin);
    }
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
   * @param autoApproveConfigType setting for auto-approve registrations
   *                   note: autoApproveAllowedSenders list persists across config changes irrespective of type
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry new keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  function setRegistrationConfig(
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) public onlyOwner {
    uint32 approvedCount = s_config.approvedCount;
    s_config = RegistrarConfig({
      autoApproveConfigType: autoApproveConfigType,
      autoApproveMaxAllowed: autoApproveMaxAllowed,
      approvedCount: approvedCount,
      minLINKJuels: minLINKJuels,
      keeperRegistry: AutomationRegistryBaseInterface(keeperRegistry)
    });

    emit ConfigChanged(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  /**
   * @notice owner calls this function to set allowlist status for senderAddress
   * @param senderAddress senderAddress to set the allowlist status for
   * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
   */
  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external onlyOwner {
    s_autoApproveAllowedSenders[senderAddress] = allowed;

    emit AutoApproveAllowedSenderSet(senderAddress, allowed);
  }

  /**
   * @notice read the allowlist status of senderAddress
   * @param senderAddress address to read the allowlist status for
   */
  function getAutoApproveAllowedSender(address senderAddress) external view returns (bool) {
    return s_autoApproveAllowedSenders[senderAddress];
  }

  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
      AutoApproveType autoApproveConfigType,
      uint32 autoApproveMaxAllowed,
      uint32 approvedCount,
      address keeperRegistry,
      uint256 minLINKJuels
    )
  {
    RegistrarConfig memory config = s_config;
    return (
      config.autoApproveConfigType,
      config.autoApproveMaxAllowed,
      config.approvedCount,
      address(config.keeperRegistry),
      config.minLINKJuels
    );
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = s_pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender transfering LINK
   * @param amount Amount of LINK sent (specified in Juels)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    onlyLINK
    permittedFunctionsForLINK(data)
    isActualAmount(amount, data)
    isActualSender(sender, data)
  {
    if (data.length < 292) revert InvalidDataLength();
    if (amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }
    (bool success, ) = address(this).delegatecall(data);
    // calls register
    if (!success) {
      revert RegistrationRequestFailed();
    }
  }

  //PRIVATE

  /**
   * @dev verify registration request and emit RegistrationRequested event
   */
  function _register(RegistrationParams memory params, address sender) private returns (uint256) {
    if (params.adminAddress == address(0)) {
      revert InvalidAdminAddress();
    }
    bytes32 hash = keccak256(
      abi.encode(params.upkeepContract, params.gasLimit, params.adminAddress, params.checkData, params.offchainConfig)
    );

    emit RegistrationRequested(
      hash,
      params.name,
      params.encryptedEmail,
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.amount
    );

    uint256 upkeepId;
    RegistrarConfig memory config = s_config;
    if (_shouldAutoApprove(config, sender)) {
      s_config.approvedCount = config.approvedCount + 1;

      upkeepId = _approve(params, hash);
    } else {
      uint96 newBalance = s_pendingRequests[hash].balance + params.amount;
      s_pendingRequests[hash] = PendingRequest({admin: params.adminAddress, balance: newBalance});
    }

    return upkeepId;
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function _approve(RegistrationParams memory params, bytes32 hash) private returns (uint256) {
    AutomationRegistryBaseInterface keeperRegistry = s_config.keeperRegistry;

    // register upkeep
    uint256 upkeepId = keeperRegistry.registerUpkeep(
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.offchainConfig
    );
    // fund upkeep
    bool success = LINK.transferAndCall(address(keeperRegistry), params.amount, abi.encode(upkeepId));
    if (!success) {
      revert LinkTransferFailed(address(keeperRegistry));
    }

    emit RegistrationApproved(hash, params.name, upkeepId);

    return upkeepId;
  }

  /**
   * @dev verify sender allowlist if needed and check max limit
   */
  function _shouldAutoApprove(RegistrarConfig memory config, address sender) private view returns (bool) {
    if (config.autoApproveConfigType == AutoApproveType.DISABLED) {
      return false;
    }
    if (
      config.autoApproveConfigType == AutoApproveType.ENABLED_SENDER_ALLOWLIST && (!s_autoApproveAllowedSenders[sender])
    ) {
      return false;
    }
    if (config.approvedCount < config.autoApproveMaxAllowed) {
      return true;
    }
    return false;
  }

  //MODIFIERS

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    if (msg.sender != address(LINK)) {
      revert OnlyLink();
    }
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32)) // First 32 bytes contain length of data
    }
    if (funcSelector != REGISTER_REQUEST_SELECTOR) {
      revert FunctionNotPermitted();
    }
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(uint256 expected, bytes calldata data) {
    // decode register function arguments to get actual amount
    (, , , , , , , uint96 amount, ) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != amount) {
      revert AmountMismatch();
    }
    _;
  }

  /**
   * @dev Reverts if the actual sender address does not match the expected sender address
   * @param expected address that should match the actual sender address
   * @param data bytes
   */
  modifier isActualSender(address expected, bytes calldata data) {
    // decode register function arguments to get actual sender
    (, , , , , , , , address sender) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != sender) {
      revert SenderMismatch();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/proxy/Proxy.sol";
import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import "./KeeperRegistryBase2_0.sol";
import {AutomationRegistryExecutableInterface, UpkeepInfo} from "../../interfaces/automation/2_0/AutomationRegistryInterface2_0.sol";
import "../../interfaces/automation/MigratableKeeperRegistryInterface.sol";
import "../../interfaces/automation/MigratableKeeperRegistryInterfaceV2.sol";
import "../../interfaces/ERC677ReceiverInterface.sol";
import "../../OCR2Abstract.sol";

/**
 _.  _|_ _ ._ _  _._|_o _ ._  o _  _    ._  _| _  __|_o._
(_||_||_(_)| | |(_| |_|(_)| | |_> (_)|_||  (_|(/__> |_|| |\/
                                                          /
 */
/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry2_0 is
  KeeperRegistryBase2_0,
  Proxy,
  OCR2Abstract,
  AutomationRegistryExecutableInterface,
  MigratableKeeperRegistryInterface,
  MigratableKeeperRegistryInterfaceV2,
  ERC677ReceiverInterface
{
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  // Immutable address of logic contract where some functionality is delegated to
  address private immutable i_keeperRegistryLogic;

  /**
   * @notice versions:
   * - KeeperRegistry 2.0.1: implements workaround for buggy migrate function in 1.X
   * - KeeperRegistry 2.0.0: implement OCR interface
   * - KeeperRegistry 1.3.0: split contract into Proxy and Logic
   *                       : account for Arbitrum and Optimism L1 gas fee
   *                       : allow users to configure upkeeps
   * - KeeperRegistry 1.2.0: allow funding within performUpkeep
   *                       : allow configurable registry maxPerformGas
   *                       : add function to let admin change upkeep gas limit
   *                       : add minUpkeepSpend requirement
   *                       : upgrade to solidity v0.8
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 2.0.1";

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  UpkeepFormat public constant override upkeepTranscoderVersion = UPKEEP_TRANSCODER_VERSION_BASE;

  /**
   * @inheritdoc MigratableKeeperRegistryInterfaceV2
   */
  uint8 public constant override upkeepVersion = UPKEEP_VERSION_BASE;

  /**
   * @param keeperRegistryLogic address of the logic contract
   */
  constructor(KeeperRegistryBase2_0 keeperRegistryLogic)
    KeeperRegistryBase2_0(
      keeperRegistryLogic.getPaymentModel(),
      keeperRegistryLogic.getLinkAddress(),
      keeperRegistryLogic.getLinkNativeFeedAddress(),
      keeperRegistryLogic.getFastGasFeedAddress()
    )
  {
    i_keeperRegistryLogic = address(keeperRegistryLogic);
  }

  ////////
  // ACTIONS
  ////////

  /**
   * @dev This struct is used to maintain run time information about an upkeep in transmit function
   * @member upkeep the upkeep struct
   * @member earlyChecksPassed whether the upkeep passed early checks before perform
   * @member paymentParams the paymentParams for this upkeep
   * @member performSuccess whether the perform was successful
   * @member gasUsed gasUsed by this upkeep in perform
   */
  struct UpkeepTransmitInfo {
    Upkeep upkeep;
    bool earlyChecksPassed;
    uint96 maxLinkPayment;
    bool performSuccess;
    uint256 gasUsed;
    uint256 gasOverhead;
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function transmit(
    bytes32[3] calldata reportContext,
    bytes calldata rawReport,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) external override {
    uint256 gasOverhead = gasleft();
    HotVars memory hotVars = s_hotVars;

    if (hotVars.paused) revert RegistryPaused();
    if (!s_transmitters[msg.sender].active) revert OnlyActiveTransmitters();

    Report memory report = _decodeReport(rawReport);
    UpkeepTransmitInfo[] memory upkeepTransmitInfo = new UpkeepTransmitInfo[](report.upkeepIds.length);
    uint16 numUpkeepsPassedChecks;

    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      upkeepTransmitInfo[i].upkeep = s_upkeep[report.upkeepIds[i]];

      upkeepTransmitInfo[i].maxLinkPayment = _getMaxLinkPayment(
        hotVars,
        upkeepTransmitInfo[i].upkeep.executeGas,
        uint32(report.wrappedPerformDatas[i].performData.length),
        report.fastGasWei,
        report.linkNative,
        true
      );
      upkeepTransmitInfo[i].earlyChecksPassed = _prePerformChecks(
        report.upkeepIds[i],
        report.wrappedPerformDatas[i],
        upkeepTransmitInfo[i].upkeep,
        upkeepTransmitInfo[i].maxLinkPayment
      );

      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        numUpkeepsPassedChecks += 1;
      }
    }
    // No upkeeps to be performed in this report
    if (numUpkeepsPassedChecks == 0) revert StaleReport();

    // Verify signatures
    if (s_latestConfigDigest != reportContext[0]) revert ConfigDigestMismatch();
    if (rs.length != hotVars.f + 1 || rs.length != ss.length) revert IncorrectNumberOfSignatures();
    _verifyReportSignature(reportContext, rawReport, rs, ss, rawVs);

    // Actually perform upkeeps
    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        // Check if this upkeep was already performed in this report
        if (s_upkeep[report.upkeepIds[i]].lastPerformBlockNumber == uint32(block.number)) {
          revert InvalidReport();
        }

        // Actually perform the target upkeep
        (upkeepTransmitInfo[i].performSuccess, upkeepTransmitInfo[i].gasUsed) = _performUpkeep(
          upkeepTransmitInfo[i].upkeep,
          report.wrappedPerformDatas[i].performData
        );

        // Deduct that gasUsed by upkeep from our running counter
        gasOverhead -= upkeepTransmitInfo[i].gasUsed;

        // Store last perform block number for upkeep
        s_upkeep[report.upkeepIds[i]].lastPerformBlockNumber = uint32(block.number);
      }
    }

    // This is the overall gas overhead that will be split across performed upkeeps
    // Take upper bound of 16 gas per callData bytes, which is approximated to be reportLength
    // Rest of msg.data is accounted for in accounting overheads
    gasOverhead =
      (gasOverhead - gasleft() + 16 * rawReport.length) +
      ACCOUNTING_FIXED_GAS_OVERHEAD +
      (ACCOUNTING_PER_SIGNER_GAS_OVERHEAD * (hotVars.f + 1));
    gasOverhead = gasOverhead / numUpkeepsPassedChecks + ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD;

    uint96 totalReimbursement;
    uint96 totalPremium;
    {
      uint96 reimbursement;
      uint96 premium;
      for (uint256 i = 0; i < report.upkeepIds.length; i++) {
        if (upkeepTransmitInfo[i].earlyChecksPassed) {
          upkeepTransmitInfo[i].gasOverhead = _getCappedGasOverhead(
            gasOverhead,
            uint32(report.wrappedPerformDatas[i].performData.length),
            hotVars.f
          );

          (reimbursement, premium) = _postPerformPayment(
            hotVars,
            report.upkeepIds[i],
            upkeepTransmitInfo[i],
            report.fastGasWei,
            report.linkNative,
            numUpkeepsPassedChecks
          );
          totalPremium += premium;
          totalReimbursement += reimbursement;

          emit UpkeepPerformed(
            report.upkeepIds[i],
            upkeepTransmitInfo[i].performSuccess,
            report.wrappedPerformDatas[i].checkBlockNumber,
            upkeepTransmitInfo[i].gasUsed,
            upkeepTransmitInfo[i].gasOverhead,
            reimbursement + premium
          );
        }
      }
    }
    // record payments
    s_transmitters[msg.sender].balance += totalReimbursement;
    s_hotVars.totalPremium += totalPremium;

    uint40 epochAndRound = uint40(uint256(reportContext[1]));
    uint32 epoch = uint32(epochAndRound >> 8);
    if (epoch > hotVars.latestEpoch) {
      s_hotVars.latestEpoch = epoch;
    }
  }

  /**
   * @notice simulates the upkeep with the perform data returned from
   * checkUpkeep
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   */
  function simulatePerformUpkeep(uint256 id, bytes calldata performData)
    external
    cannotExecute
    returns (bool success, uint256 gasUsed)
  {
    if (s_hotVars.paused) revert RegistryPaused();

    Upkeep memory upkeep = s_upkeep[id];
    return _performUpkeep(upkeep, performData);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external override {
    if (msg.sender != address(i_link)) revert OnlyCallableByLINKToken();
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (s_upkeep[id].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = s_upkeep[id].balance + uint96(amount);
    s_expectedLinkBalance = s_expectedLinkBalance + amount;

    emit FundsAdded(id, sender, uint96(amount));
  }

  ////////
  // SETTERS
  ////////

  /**
   * @inheritdoc OCR2Abstract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external override onlyOwner {
    if (signers.length > maxNumOracles) revert TooManyOracles();
    if (f == 0) revert IncorrectNumberOfFaultyOracles();
    if (signers.length != transmitters.length || signers.length <= 3 * f) revert IncorrectNumberOfSigners();

    // move all pooled payments out of the pool to each transmitter's balance
    uint96 totalPremium = s_hotVars.totalPremium;
    uint96 oldLength = uint96(s_transmittersList.length);
    for (uint256 i = 0; i < oldLength; i++) {
      _updateTransmitterBalanceFromPool(s_transmittersList[i], totalPremium, oldLength);
    }

    // remove any old signer/transmitter addresses
    address signerAddress;
    address transmitterAddress;
    for (uint256 i = 0; i < oldLength; i++) {
      signerAddress = s_signersList[i];
      transmitterAddress = s_transmittersList[i];
      delete s_signers[signerAddress];
      // Do not delete the whole transmitter struct as it has balance information stored
      s_transmitters[transmitterAddress].active = false;
    }
    delete s_signersList;
    delete s_transmittersList;

    // add new signer/transmitter addresses
    {
      Transmitter memory transmitter;
      address temp;
      for (uint256 i = 0; i < signers.length; i++) {
        if (s_signers[signers[i]].active) revert RepeatedSigner();
        s_signers[signers[i]] = Signer({active: true, index: uint8(i)});

        temp = transmitters[i];
        transmitter = s_transmitters[temp];
        if (transmitter.active) revert RepeatedTransmitter();
        transmitter.active = true;
        transmitter.index = uint8(i);
        transmitter.lastCollected = totalPremium;
        s_transmitters[temp] = transmitter;
      }
    }
    s_signersList = signers;
    s_transmittersList = transmitters;

    // Set the onchain config
    OnchainConfig memory onchainConfigStruct = abi.decode(onchainConfig, (OnchainConfig));
    if (onchainConfigStruct.maxPerformGas < s_storage.maxPerformGas) revert GasLimitCanOnlyIncrease();
    if (onchainConfigStruct.maxCheckDataSize < s_storage.maxCheckDataSize) revert MaxCheckDataSizeCanOnlyIncrease();
    if (onchainConfigStruct.maxPerformDataSize < s_storage.maxPerformDataSize)
      revert MaxPerformDataSizeCanOnlyIncrease();

    s_hotVars = HotVars({
      f: f,
      paymentPremiumPPB: onchainConfigStruct.paymentPremiumPPB,
      flatFeeMicroLink: onchainConfigStruct.flatFeeMicroLink,
      stalenessSeconds: onchainConfigStruct.stalenessSeconds,
      gasCeilingMultiplier: onchainConfigStruct.gasCeilingMultiplier,
      paused: false,
      reentrancyGuard: false,
      totalPremium: totalPremium,
      latestEpoch: 0
    });

    s_storage = Storage({
      checkGasLimit: onchainConfigStruct.checkGasLimit,
      minUpkeepSpend: onchainConfigStruct.minUpkeepSpend,
      maxPerformGas: onchainConfigStruct.maxPerformGas,
      transcoder: onchainConfigStruct.transcoder,
      registrar: onchainConfigStruct.registrar,
      maxCheckDataSize: onchainConfigStruct.maxCheckDataSize,
      maxPerformDataSize: onchainConfigStruct.maxPerformDataSize,
      nonce: s_storage.nonce,
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      ownerLinkBalance: s_storage.ownerLinkBalance
    });
    s_fallbackGasPrice = onchainConfigStruct.fallbackGasPrice;
    s_fallbackLinkPrice = onchainConfigStruct.fallbackLinkPrice;

    uint32 previousConfigBlockNumber = s_storage.latestConfigBlockNumber;
    s_storage.latestConfigBlockNumber = uint32(block.number);
    s_storage.configCount += 1;

    s_latestConfigDigest = _configDigestFromConfigData(
      block.chainid,
      address(this),
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );

    emit ConfigSet(
      previousConfigBlockNumber,
      s_latestConfigDigest,
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );
  }

  ////////
  // GETTERS
  ////////

  /**
   * @notice read all of the details about an upkeep
   */
  function getUpkeep(uint256 id) external view override returns (UpkeepInfo memory upkeepInfo) {
    Upkeep memory reg = s_upkeep[id];
    upkeepInfo = UpkeepInfo({
      target: reg.target,
      executeGas: reg.executeGas,
      checkData: s_checkData[id],
      balance: reg.balance,
      admin: s_upkeepAdmin[id],
      maxValidBlocknumber: reg.maxValidBlocknumber,
      lastPerformBlockNumber: reg.lastPerformBlockNumber,
      amountSpent: reg.amountSpent,
      paused: reg.paused,
      offchainConfig: s_upkeepOffchainConfig[id]
    });
    return upkeepInfo;
  }

  /**
   * @notice retrieve active upkeep IDs. Active upkeep is defined as an upkeep which is not paused and not canceled.
   * @param startIndex starting index in list
   * @param maxCount max count to retrieve (0 = unlimited)
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view override returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice read the current info about any transmitter address
   */
  function getTransmitterInfo(address query)
    external
    view
    override
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    )
  {
    Transmitter memory transmitter = s_transmitters[query];
    uint96 totalDifference = s_hotVars.totalPremium - transmitter.lastCollected;
    uint96 pooledShare = totalDifference / uint96(s_transmittersList.length);

    return (
      transmitter.active,
      transmitter.index,
      (transmitter.balance + pooledShare),
      transmitter.lastCollected,
      s_transmitterPayees[query]
    );
  }

  /**
   * @notice read the current info about any signer address
   */
  function getSignerInfo(address query) external view returns (bool active, uint8 index) {
    Signer memory signer = s_signers[query];
    return (signer.active, signer.index);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    override
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    )
  {
    state = State({
      nonce: s_storage.nonce,
      ownerLinkBalance: s_storage.ownerLinkBalance,
      expectedLinkBalance: s_expectedLinkBalance,
      totalPremium: s_hotVars.totalPremium,
      numUpkeeps: s_upkeepIDs.length(),
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      latestConfigDigest: s_latestConfigDigest,
      latestEpoch: s_hotVars.latestEpoch,
      paused: s_hotVars.paused
    });

    config = OnchainConfig({
      paymentPremiumPPB: s_hotVars.paymentPremiumPPB,
      flatFeeMicroLink: s_hotVars.flatFeeMicroLink,
      checkGasLimit: s_storage.checkGasLimit,
      stalenessSeconds: s_hotVars.stalenessSeconds,
      gasCeilingMultiplier: s_hotVars.gasCeilingMultiplier,
      minUpkeepSpend: s_storage.minUpkeepSpend,
      maxPerformGas: s_storage.maxPerformGas,
      maxCheckDataSize: s_storage.maxCheckDataSize,
      maxPerformDataSize: s_storage.maxPerformDataSize,
      fallbackGasPrice: s_fallbackGasPrice,
      fallbackLinkPrice: s_fallbackLinkPrice,
      transcoder: s_storage.transcoder,
      registrar: s_storage.registrar
    });

    return (state, config, s_signersList, s_transmittersList, s_hotVars.f);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance) {
    return getMaxPaymentForGas(s_upkeep[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(uint32 gasLimit) public view returns (uint96 maxPayment) {
    HotVars memory hotVars = s_hotVars;
    (uint256 fastGasWei, uint256 linkNative) = _getFeedData(hotVars);
    return _getMaxLinkPayment(hotVars, gasLimit, s_storage.maxPerformDataSize, fastGasWei, linkNative, false);
  }

  /**
   * @notice retrieves the migration permission for a peer registry
   */
  function getPeerRegistryMigrationPermission(address peer) external view returns (MigrationPermission) {
    return s_peerRegistryMigrationPermission[peer];
  }

  /**
   * @notice retrieves the address of the logic address
   */
  function getKeeperRegistryLogicAddress() external view returns (address) {
    return i_keeperRegistryLogic;
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDetails()
    external
    view
    override
    returns (
      uint32 configCount,
      uint32 blockNumber,
      bytes32 configDigest
    )
  {
    return (s_storage.configCount, s_storage.latestConfigBlockNumber, s_latestConfigDigest);
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDigestAndEpoch()
    external
    view
    override
    returns (
      bool scanLogs,
      bytes32 configDigest,
      uint32 epoch
    )
  {
    return (false, s_latestConfigDigest, s_hotVars.latestEpoch);
  }

  ////////
  // INTERNAL FUNCTIONS
  ////////

  /**
   * @dev This is the address to which proxy functions are delegated to
   */
  function _implementation() internal view override returns (address) {
    return i_keeperRegistryLogic;
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function _callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev _decodeReport decodes a serialized report into a Report struct
   */
  function _decodeReport(bytes memory rawReport) internal pure returns (Report memory) {
    (
      uint256 fastGasWei,
      uint256 linkNative,
      uint256[] memory upkeepIds,
      PerformDataWrapper[] memory wrappedPerformDatas
    ) = abi.decode(rawReport, (uint256, uint256, uint256[], PerformDataWrapper[]));
    if (upkeepIds.length != wrappedPerformDatas.length) revert InvalidReport();

    return
      Report({
        fastGasWei: fastGasWei,
        linkNative: linkNative,
        upkeepIds: upkeepIds,
        wrappedPerformDatas: wrappedPerformDatas
      });
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   */
  function _prePerformChecks(
    uint256 upkeepId,
    PerformDataWrapper memory wrappedPerformData,
    Upkeep memory upkeep,
    uint96 maxLinkPayment
  ) internal returns (bool) {
    if (wrappedPerformData.checkBlockNumber < upkeep.lastPerformBlockNumber) {
      // Can happen when another report performed this upkeep after this report was generated
      emit StaleUpkeepReport(upkeepId);
      return false;
    }

    if (blockhash(wrappedPerformData.checkBlockNumber) != wrappedPerformData.checkBlockhash) {
      // Can happen when the block on which report was generated got reorged
      // We will also revert if checkBlockNumber is older than 256 blocks. In this case we rely on a new transmission
      // with the latest checkBlockNumber
      emit ReorgedUpkeepReport(upkeepId);
      return false;
    }

    if (upkeep.maxValidBlocknumber <= block.number) {
      // Can happen when an upkeep got cancelled after report was generated.
      // However we have a CANCELLATION_DELAY of 50 blocks so shouldn't happen in practice
      emit CancelledUpkeepReport(upkeepId);
      return false;
    }

    if (upkeep.balance < maxLinkPayment) {
      // Can happen due to flucutations in gas / link prices
      emit InsufficientFundsUpkeepReport(upkeepId);
      return false;
    }

    return true;
  }

  /**
   * @dev Verify signatures attached to report
   */
  function _verifyReportSignature(
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) internal view {
    bytes32 h = keccak256(abi.encode(keccak256(report), reportContext));
    // i-th byte counts number of sigs made by i-th signer
    uint256 signedCount = 0;

    Signer memory signer;
    address signerAddress;
    for (uint256 i = 0; i < rs.length; i++) {
      signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
      signer = s_signers[signerAddress];
      if (!signer.active) revert OnlyActiveSigners();
      unchecked {
        signedCount += 1 << (8 * signer.index);
      }
    }

    if (signedCount & ORACLE_MASK != signedCount) revert DuplicateSigners();
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * transmitter and the exact gas required by the Upkeep
   */
  function _performUpkeep(Upkeep memory upkeep, bytes memory performData)
    private
    nonReentrant
    returns (bool success, uint256 gasUsed)
  {
    gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, performData);
    success = _callWithExactGas(upkeep.executeGas, upkeep.target, callData);
    gasUsed = gasUsed - gasleft();

    return (success, gasUsed);
  }

  /**
   * @dev does postPerform payment processing for an upkeep. Deducts upkeep's balance and increases
   * amount spent.
   */
  function _postPerformPayment(
    HotVars memory hotVars,
    uint256 upkeepId,
    UpkeepTransmitInfo memory upkeepTransmitInfo,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps
  ) internal returns (uint96 gasReimbursement, uint96 premium) {
    (gasReimbursement, premium) = _calculatePaymentAmount(
      hotVars,
      upkeepTransmitInfo.gasUsed,
      upkeepTransmitInfo.gasOverhead,
      fastGasWei,
      linkNative,
      numBatchedUpkeeps,
      true
    );

    uint96 payment = gasReimbursement + premium;
    s_upkeep[upkeepId].balance -= payment;
    s_upkeep[upkeepId].amountSpent += payment;

    return (gasReimbursement, premium);
  }

  /**
   * @dev Caps the gas overhead by the constant overhead used within initial payment checks in order to
   * prevent a revert in payment processing.
   */
  function _getCappedGasOverhead(
    uint256 calculatedGasOverhead,
    uint32 performDataLength,
    uint8 f
  ) private pure returns (uint256 cappedGasOverhead) {
    cappedGasOverhead = _getMaxGasOverhead(performDataLength, f);
    if (calculatedGasOverhead < cappedGasOverhead) {
      return calculatedGasOverhead;
    }
    return cappedGasOverhead;
  }

  ////////
  // PROXY FUNCTIONS - EXECUTED THROUGH FALLBACK
  ////////

  /**
   * @notice adds a new upkeep
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external override returns (uint256 id) {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice simulated by keepers via eth_call to see if the upkeep needs to be
   * performed. It returns the success status / failure reason along with the perform data payload.
   * @param id identifier of the upkeep to check
   */
  function checkUpkeep(uint256 id)
    external
    override
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice prevent an upkeep from being performed in the future
   * @param id upkeep to be canceled
   */
  function cancelUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice pause an upkeep
   * @param id upkeep to be paused
   */
  function pauseUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice unpause an upkeep
   * @param id upkeep to be resumed
   */
  function unpauseUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice update the check data of an upkeep
   * @param id the id of the upkeep whose check data needs to be updated
   * @param newCheckData the new check data
   */
  function updateCheckData(uint256 id, bytes calldata newCheckData) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice adds LINK funding for an upkeep by transferring from the sender's
   * LINK balance
   * @param id upkeep to fund
   * @param amount number of LINK to transfer
   */
  function addFunds(uint256 id, uint96 amount) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice removes funding from a canceled upkeep
   * @param id upkeep to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(uint256 id, address to) external {
    // Executed through logic contract
    // Restricted to nonRentrant in logic contract as this is not callable from a user's performUpkeep
    _fallback();
  }

  /**
   * @notice allows the admin of an upkeep to modify gas limit
   * @param id upkeep to be change the gas limit for
   * @param gasLimit new gas limit for the upkeep
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice allows the admin of an upkeep to modify the offchain config
   * @param id upkeep to be change the gas limit for
   * @param config instructs oracles of offchain config preferences
   */
  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice withdraws a transmitter's payment, callable only by the transmitter's payee
   * @param from transmitter address
   * @param to address to send the payment to
   */
  function withdrawPayment(address from, address to) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice proposes the safe transfer of a transmitter's payee to another address
   * @param transmitter address of the transmitter to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(address transmitter, address proposed) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice accepts the safe transfer of payee role for a transmitter
   * @param transmitter address to accept the payee role for
   */
  function acceptPayeeship(address transmitter) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice proposes the safe transfer of an upkeep's admin role to another address
   * @param id the upkeep id to transfer admin
   * @param proposed address to nominate for the new upkeep admin
   */
  function transferUpkeepAdmin(uint256 id, address proposed) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice accepts the safe transfer of admin role for an upkeep
   * @param id the upkeep id
   */
  function acceptUpkeepAdmin(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination)
    external
    override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2)
  {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps)
    external
    override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2)
  {
    // Executed through logic contract
    _fallback();
  }

  ////////
  // OWNER RESTRICTED FUNCTIONS
  ////////

  /**
   * @notice recovers LINK funds improperly transferred to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gas limit. However, in our anticipated deployment, the number of upkeeps and
   * transmitters will be low enough to avoid this problem.
   */
  function recoverFunds() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice withdraws LINK funds collected through cancellation fees
   */
  function withdrawOwnerFunds() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice update the list of payees corresponding to the transmitters
   * @param payees addresses corresponding to transmitters who are allowed to
   * move payments which have been accrued
   */
  function setPayees(address[] calldata payees) external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice signals to transmitters that they should not perform upkeeps until the
   * contract has been unpaused
   */
  function pause() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice signals to transmitters that they can perform upkeeps once again after
   * having been paused
   */
  function unpause() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice sets the peer registry migration permission
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import "../../vendor/@eth-optimism/contracts/0.8.6/contracts/L2/predeploys/OVM_GasPriceOracle.sol";
import "../ExecutionPrevention.sol";
import {OnchainConfig, State, UpkeepFailureReason} from "../../interfaces/automation/2_0/AutomationRegistryInterface2_0.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/KeeperCompatibleInterface.sol";
import "../../interfaces/automation/UpkeepTranscoderInterface.sol";

/**
 * @notice relevant state of an upkeep which is used in transmit function
 * @member executeGas the gas limit of upkeep execution
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member paused if this upkeep has been paused
 * @member target the contract which needs to be serviced
 * @member amountSpent the amount this upkeep has spent
 * @member balance the balance of this upkeep
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 */
struct Upkeep {
  uint32 executeGas;
  uint32 maxValidBlocknumber;
  bool paused;
  address target;
  // 3 bytes left in 1st EVM word - not written to in transmit
  uint96 amountSpent;
  uint96 balance;
  uint32 lastPerformBlockNumber;
  // 4 bytes left in 2nd EVM word - written in transmit path
}

/**
 * @notice Base Keeper Registry contract, contains shared logic between
 * KeeperRegistry and KeeperRegistryLogic
 */
abstract contract KeeperRegistryBase2_0 is ConfirmedOwner, ExecutionPrevention {
  address internal constant ZERO_ADDRESS = address(0);
  address internal constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 internal constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 internal constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 internal constant PERFORM_GAS_MIN = 2_300;
  uint256 internal constant CANCELLATION_DELAY = 50;
  uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
  uint256 internal constant PPB_BASE = 1_000_000_000;
  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint96 internal constant LINK_TOTAL_SUPPLY = 1e27;
  // The first byte of the mask can be 0, because we only ever have 31 oracles
  uint256 internal constant ORACLE_MASK = 0x0001010101010101010101010101010101010101010101010101010101010101;
  /**
   * @dev UPKEEP_TRANSCODER_VERSION_BASE is temporary necessity for backwards compatibility with
   * MigratableKeeperRegistryInterfaceV1 - it should be removed in future versions in favor of
   * UPKEEP_VERSION_BASE and MigratableKeeperRegistryInterfaceV2
   */
  UpkeepFormat internal constant UPKEEP_TRANSCODER_VERSION_BASE = UpkeepFormat.V1;
  uint8 internal constant UPKEEP_VERSION_BASE = uint8(UpkeepFormat.V3);
  // L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  uint256 internal constant REGISTRY_GAS_OVERHEAD = 65_000; // Used only in maxPayment estimation, not in actual payment
  uint256 internal constant REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD = 20; // Used only in maxPayment estimation, not in actual payment. Value scales with performData length.
  uint256 internal constant REGISTRY_PER_SIGNER_GAS_OVERHEAD = 7_500; // Used only in maxPayment estimation, not in actual payment. Value scales with f.

  uint256 internal constant ACCOUNTING_FIXED_GAS_OVERHEAD = 26_900; // Used in actual payment. Fixed overhead per tx
  uint256 internal constant ACCOUNTING_PER_SIGNER_GAS_OVERHEAD = 1_100; // Used in actual payment. overhead per signer
  uint256 internal constant ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD = 5_800; // Used in actual payment. overhead per upkeep performed

  OVM_GasPriceOracle internal constant OPTIMISM_ORACLE = OVM_GasPriceOracle(0x420000000000000000000000000000000000000F);
  ArbGasInfo internal constant ARB_NITRO_ORACLE = ArbGasInfo(0x000000000000000000000000000000000000006C);

  LinkTokenInterface internal immutable i_link;
  AggregatorV3Interface internal immutable i_linkNativeFeed;
  AggregatorV3Interface internal immutable i_fastGasFeed;
  PaymentModel internal immutable i_paymentModel;

  // @dev - The storage is gas optimised for one and only function - transmit. All the storage accessed in transmit
  // is stored compactly. Rest of the storage layout is not of much concern as transmit is the only hot path
  // Upkeep storage
  EnumerableSet.UintSet internal s_upkeepIDs;
  mapping(uint256 => Upkeep) internal s_upkeep; // accessed during transmit
  mapping(uint256 => address) internal s_upkeepAdmin;
  mapping(uint256 => address) internal s_proposedAdmin;
  mapping(uint256 => bytes) internal s_checkData;
  // Registry config and state
  mapping(address => Transmitter) internal s_transmitters;
  mapping(address => Signer) internal s_signers;
  address[] internal s_signersList; // s_signersList contains the signing address of each oracle
  address[] internal s_transmittersList; // s_transmittersList contains the transmission address of each oracle
  mapping(address => address) internal s_transmitterPayees; // s_payees contains the mapping from transmitter to payee.
  mapping(address => address) internal s_proposedPayee; // proposed payee for a transmitter
  bytes32 internal s_latestConfigDigest; // Read on transmit path in case of signature verification
  HotVars internal s_hotVars; // Mixture of config and state, used in transmit
  Storage internal s_storage; // Mixture of config and state, not used in transmit
  uint256 internal s_fallbackGasPrice;
  uint256 internal s_fallbackLinkPrice;
  uint256 internal s_expectedLinkBalance; // Used in case of erroneous LINK transfers to contract
  mapping(address => MigrationPermission) internal s_peerRegistryMigrationPermission; // Permissions for migration to and fro
  mapping(uint256 => bytes) internal s_upkeepOffchainConfig; // general configuration preferences

  error ArrayHasNoEntries();
  error CannotCancel();
  error DuplicateEntry();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidPayee();
  error InvalidRecipient();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyPausedUpkeep();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error TargetCheckReverted(bytes reason);
  error TranscoderNotSet();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();
  error ConfigDigestMismatch();
  error IncorrectNumberOfSignatures();
  error OnlyActiveSigners();
  error DuplicateSigners();
  error StaleReport();
  error TooManyOracles();
  error IncorrectNumberOfSigners();
  error IncorrectNumberOfFaultyOracles();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error OnchainConfigNonEmpty();
  error CheckDataExceedsLimit();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error InvalidReport();
  error RegistryPaused();
  error ReentrantCall();
  error UpkeepAlreadyExists();

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  enum PaymentModel {
    DEFAULT,
    ARBITRUM,
    OPTIMISM
  }

  // Config + State storage struct which is on hot transmit path
  struct HotVars {
    uint8 f; // maximum number of faulty oracles
    uint32 paymentPremiumPPB; // premium percentage charged to user over tx cost
    uint32 flatFeeMicroLink; // flat fee charged to user for every perform
    uint24 stalenessSeconds; // Staleness tolerance for feeds
    uint16 gasCeilingMultiplier; // multiplier on top of fast gas feed for upper bound
    bool paused; // pause switch for all upkeeps in the registry
    bool reentrancyGuard; // guard against reentrancy
    uint96 totalPremium; // total historical payment to oracles for premium
    uint32 latestEpoch; // latest epoch for which a report was transmitted
    // 1 EVM word full
  }

  // Config + State storage struct which is not on hot transmit path
  struct Storage {
    uint96 minUpkeepSpend; // Minimum amount an upkeep must spend
    address transcoder; // Address of transcoder contract used in migrations
    // 1 EVM word full
    uint96 ownerLinkBalance; // Balance of owner, accumulates minUpkeepSpend in case it is not spent
    address registrar; // Address of registrar used to register upkeeps
    // 2 EVM word full
    uint32 checkGasLimit; // Gas limit allowed in checkUpkeep
    uint32 maxPerformGas; // Max gas an upkeep can use on this registry
    uint32 nonce; // Nonce for each upkeep created
    uint32 configCount; // incremented each time a new config is posted, The count
    // is incorporated into the config digest to prevent replay attacks.
    uint32 latestConfigBlockNumber; // makes it easier for offchain systems to extract config from logs
    uint32 maxCheckDataSize; // max length of checkData bytes
    uint32 maxPerformDataSize; // max length of performData bytes
    // 4 bytes to 3rd EVM word
  }

  struct Transmitter {
    bool active;
    uint8 index; // Index of oracle in s_signersList/s_transmittersList
    uint96 balance;
    uint96 lastCollected;
  }

  struct Signer {
    bool active;
    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }

  // This struct is used to pack information about the user's check function
  struct PerformDataWrapper {
    uint32 checkBlockNumber; // Block number-1 on which check was simulated
    bytes32 checkBlockhash; // blockhash of checkBlockNumber. Used for reorg protection
    bytes performData; // actual performData that user's check returned
  }

  // Report transmitted by OCR to transmit function
  struct Report {
    uint256 fastGasWei;
    uint256 linkNative;
    uint256[] upkeepIds; // Ids of upkeeps
    PerformDataWrapper[] wrappedPerformDatas; // Contains checkInfo and performData for the corresponding upkeeps
  }

  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event OwnerFundsWithdrawn(uint96 amount);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataUpdated(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint32 checkBlockNumber,
    uint256 gasUsed,
    uint256 gasOverhead,
    uint96 totalPayment
  );
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepUnpaused(uint256 indexed id);
  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event StaleUpkeepReport(uint256 indexed id);
  event ReorgedUpkeepReport(uint256 indexed id);
  event InsufficientFundsUpkeepReport(uint256 indexed id);
  event CancelledUpkeepReport(uint256 indexed id);
  event Paused(address account);
  event Unpaused(address account);

  /**
   * @param paymentModel the payment model of default, Arbitrum, or Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    PaymentModel paymentModel,
    address link,
    address linkNativeFeed,
    address fastGasFeed
  ) ConfirmedOwner(msg.sender) {
    i_paymentModel = paymentModel;
    i_link = LinkTokenInterface(link);
    i_linkNativeFeed = AggregatorV3Interface(linkNativeFeed);
    i_fastGasFeed = AggregatorV3Interface(fastGasFeed);
  }

  ////////
  // GETTERS
  ////////

  function getPaymentModel() external view returns (PaymentModel) {
    return i_paymentModel;
  }

  function getLinkAddress() external view returns (address) {
    return address(i_link);
  }

  function getLinkNativeFeedAddress() external view returns (address) {
    return address(i_linkNativeFeed);
  }

  function getFastGasFeedAddress() external view returns (address) {
    return address(i_fastGasFeed);
  }

  ////////
  // INTERNAL
  ////////

  /**
   * @dev retrieves feed data for fast gas/native and link/native prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData(HotVars memory hotVars) internal view returns (uint256 gasWei, uint256 linkNative) {
    uint32 stalenessSeconds = hotVars.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = i_fastGasFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = i_linkNativeFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      linkNative = s_fallbackLinkPrice;
    } else {
      linkNative = uint256(feedValue);
    }
    return (gasWei, linkNative);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   * @param gasLimit the amount of gas used
   * @param gasOverhead the amount of gas overhead
   * @param fastGasWei the fast gas price
   * @param linkNative the exchange ratio between LINK and Native token
   * @param numBatchedUpkeeps the number of upkeeps in this batch. Used to divide the L1 cost
   * @param isExecution if this is triggered by a perform upkeep function
   */
  function _calculatePaymentAmount(
    HotVars memory hotVars,
    uint256 gasLimit,
    uint256 gasOverhead,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps,
    bool isExecution
  ) internal view returns (uint96, uint96) {
    uint256 gasWei = fastGasWei * hotVars.gasCeilingMultiplier;
    // in case it's actual execution use actual gas price, capped by fastGasWei * gasCeilingMultiplier
    if (isExecution && tx.gasprice < gasWei) {
      gasWei = tx.gasprice;
    }

    uint256 l1CostWei = 0;
    if (i_paymentModel == PaymentModel.OPTIMISM) {
      bytes memory txCallData = new bytes(0);
      if (isExecution) {
        txCallData = bytes.concat(msg.data, L1_FEE_DATA_PADDING);
      } else {
        // @dev fee is 4 per 0 byte, 16 per non-zero byte. Worst case we can have
        // s_storage.maxPerformDataSize non zero-bytes. Instead of setting bytes to non-zero
        // we initialize 'new bytes' of length 4*maxPerformDataSize to cover for zero bytes.
        txCallData = new bytes(4 * s_storage.maxPerformDataSize);
      }
      l1CostWei = OPTIMISM_ORACLE.getL1Fee(txCallData);
    } else if (i_paymentModel == PaymentModel.ARBITRUM) {
      l1CostWei = ARB_NITRO_ORACLE.getCurrentTxL1GasFees();
    }
    // if it's not performing upkeeps, use gas ceiling multiplier to estimate the upper bound
    if (!isExecution) {
      l1CostWei = hotVars.gasCeilingMultiplier * l1CostWei;
    }
    // Divide l1CostWei among all batched upkeeps. Spare change from division is not charged
    l1CostWei = l1CostWei / numBatchedUpkeeps;

    uint256 gasPayment = ((gasWei * (gasLimit + gasOverhead) + l1CostWei) * 1e18) / linkNative;
    uint256 premium = (((gasWei * gasLimit) + l1CostWei) * 1e9 * hotVars.paymentPremiumPPB) /
      linkNative +
      uint256(hotVars.flatFeeMicroLink) *
      1e12;
    // LINK_TOTAL_SUPPLY < UINT96_MAX
    if (gasPayment + premium > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return (uint96(gasPayment), uint96(premium));
  }

  /**
   * @dev generates the max link payment for an upkeep
   */
  function _getMaxLinkPayment(
    HotVars memory hotVars,
    uint32 executeGas,
    uint32 performDataLength,
    uint256 fastGasWei,
    uint256 linkNative,
    bool isExecution // Whether this is an actual perform execution or just a simulation
  ) internal view returns (uint96) {
    uint256 gasOverhead = _getMaxGasOverhead(performDataLength, hotVars.f);
    (uint96 reimbursement, uint96 premium) = _calculatePaymentAmount(
      hotVars,
      executeGas,
      gasOverhead,
      fastGasWei,
      linkNative,
      1, // Consider only 1 upkeep in batch to get maxPayment
      isExecution
    );

    return reimbursement + premium;
  }

  /**
   * @dev returns the max gas overhead that can be charged for an upkeep
   */
  function _getMaxGasOverhead(uint32 performDataLength, uint8 f) internal pure returns (uint256) {
    // performData causes additional overhead in report length and memory operations
    return
      REGISTRY_GAS_OVERHEAD +
      (REGISTRY_PER_SIGNER_GAS_OVERHEAD * (f + 1)) +
      (REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD * performDataLength);
  }

  /**
   * @dev move a transmitter's balance from total pool to withdrawable balance
   */
  function _updateTransmitterBalanceFromPool(
    address transmitterAddress,
    uint96 totalPremium,
    uint96 payeeCount
  ) internal returns (uint96) {
    Transmitter memory transmitter = s_transmitters[transmitterAddress];

    uint96 uncollected = totalPremium - transmitter.lastCollected;
    uint96 due = uncollected / payeeCount;
    transmitter.balance += due;
    transmitter.lastCollected = totalPremium;

    // Transfer spare change to owner
    s_storage.ownerLinkBalance += (uncollected - due * payeeCount);
    s_transmitters[transmitterAddress] = transmitter;

    return transmitter.balance;
  }

  /**
   * @notice replicates Open Zeppelin's ReentrancyGuard but optimized to fit our storage
   */
  modifier nonReentrant() {
    if (s_hotVars.reentrancyGuard) revert ReentrantCall();
    s_hotVars.reentrancyGuard = true;
    _;
    s_hotVars.reentrancyGuard = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import "./KeeperRegistryBase2_0.sol";
import "../../interfaces/automation/MigratableKeeperRegistryInterfaceV2.sol";
import "../../interfaces/automation/UpkeepTranscoderInterfaceV2.sol";

/**
 * @notice Logic contract, works in tandem with KeeperRegistry as a proxy
 */
contract KeeperRegistryLogic2_0 is KeeperRegistryBase2_0 {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  /**
   * @param paymentModel one of Default, Arbitrum, Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    PaymentModel paymentModel,
    address link,
    address linkNativeFeed,
    address fastGasFeed
  ) KeeperRegistryBase2_0(paymentModel, link, linkNativeFeed, fastGasFeed) {}

  function checkUpkeep(uint256 id)
    external
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    HotVars memory hotVars = s_hotVars;
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_CANCELLED, gasUsed, 0, 0);
    if (upkeep.paused) return (false, bytes(""), UpkeepFailureReason.UPKEEP_PAUSED, gasUsed, 0, 0);

    (fastGasWei, linkNative) = _getFeedData(hotVars);
    uint96 maxLinkPayment = _getMaxLinkPayment(
      hotVars,
      upkeep.executeGas,
      s_storage.maxPerformDataSize,
      fastGasWei,
      linkNative,
      false
    );
    if (upkeep.balance < maxLinkPayment)
      return (false, bytes(""), UpkeepFailureReason.INSUFFICIENT_BALANCE, gasUsed, fastGasWei, linkNative);

    gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[id]);
    (bool success, bytes memory result) = upkeep.target.call{gas: s_storage.checkGasLimit}(callData);
    gasUsed = gasUsed - gasleft();

    if (!success) return (false, bytes(""), UpkeepFailureReason.TARGET_CHECK_REVERTED, gasUsed, fastGasWei, linkNative);

    bytes memory userPerformData;
    (upkeepNeeded, userPerformData) = abi.decode(result, (bool, bytes));
    if (!upkeepNeeded)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_NOT_NEEDED, gasUsed, fastGasWei, linkNative);
    if (userPerformData.length > s_storage.maxPerformDataSize)
      return (false, bytes(""), UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT, gasUsed, fastGasWei, linkNative);

    performData = abi.encode(
      PerformDataWrapper({
        checkBlockNumber: uint32(block.number - 1),
        checkBlockhash: blockhash(block.number - 1),
        performData: userPerformData
      })
    );
    return (true, performData, UpkeepFailureReason.NONE, gasUsed, fastGasWei, linkNative);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawOwnerFunds() external onlyOwner {
    uint96 amount = s_storage.ownerLinkBalance;

    s_expectedLinkBalance = s_expectedLinkBalance - amount;
    s_storage.ownerLinkBalance = 0;

    emit OwnerFundsWithdrawn(amount);
    i_link.transfer(msg.sender, amount);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function recoverFunds() external onlyOwner {
    uint256 total = i_link.balanceOf(address(this));
    i_link.transfer(msg.sender, total - s_expectedLinkBalance);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setPayees(address[] calldata payees) external onlyOwner {
    if (s_transmittersList.length != payees.length) revert ParameterLengthError();
    for (uint256 i = 0; i < s_transmittersList.length; i++) {
      address transmitter = s_transmittersList[i];
      address oldPayee = s_transmitterPayees[transmitter];
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) || (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (newPayee != IGNORE_ADDRESS) {
        s_transmitterPayees[transmitter] = newPayee;
      }
    }
    emit PayeesUpdated(s_transmittersList, payees);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function pause() external onlyOwner {
    s_hotVars.paused = true;

    emit Paused(msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function unpause() external onlyOwner {
    s_hotVars.paused = false;

    emit Unpaused(msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external onlyOwner {
    s_peerRegistryMigrationPermission[peer] = permission;
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id) {
    if (msg.sender != owner() && msg.sender != s_storage.registrar) revert OnlyCallableByOwnerOrRegistrar();

    id = uint256(keccak256(abi.encode(blockhash(block.number - 1), address(this), s_storage.nonce)));
    _createUpkeep(id, target, gasLimit, admin, 0, checkData, false);
    s_storage.nonce++;
    s_upkeepOffchainConfig[id] = offchainConfig;
    emit UpkeepRegistered(id, gasLimit, admin);
    return id;
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function cancelUpkeep(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    bool canceled = upkeep.maxValidBlocknumber != UINT32_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && upkeep.maxValidBlocknumber > block.number)) revert CannotCancel();
    if (!isOwner && msg.sender != s_upkeepAdmin[id]) revert OnlyCallableByOwnerOrAdmin();

    uint256 height = block.number;
    if (!isOwner) {
      height = height + CANCELLATION_DELAY;
    }
    s_upkeep[id].maxValidBlocknumber = uint32(height);
    s_upkeepIDs.remove(id);

    // charge the cancellation fee if the minUpkeepSpend is not met
    uint96 minUpkeepSpend = s_storage.minUpkeepSpend;
    uint96 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minUpkeepSpend - amountSpent,0), amountLeft)
    if (upkeep.amountSpent < minUpkeepSpend) {
      cancellationFee = minUpkeepSpend - upkeep.amountSpent;
      if (cancellationFee > upkeep.balance) {
        cancellationFee = upkeep.balance;
      }
    }
    s_upkeep[id].balance = upkeep.balance - cancellationFee;
    s_storage.ownerLinkBalance = s_storage.ownerLinkBalance + cancellationFee;

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function addFunds(uint256 id, uint96 amount) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = upkeep.balance + amount;
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    i_link.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawFunds(uint256 id, address to) external nonReentrant {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    Upkeep memory upkeep = s_upkeep[id];
    if (s_upkeepAdmin[id] != msg.sender) revert OnlyCallableByAdmin();
    if (upkeep.maxValidBlocknumber > block.number) revert UpkeepNotCanceled();

    uint96 amountToWithdraw = s_upkeep[id].balance;
    s_expectedLinkBalance = s_expectedLinkBalance - amountToWithdraw;
    s_upkeep[id].balance = 0;
    i_link.transfer(to, amountToWithdraw);
    emit FundsWithdrawn(id, amountToWithdraw, to);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    _requireAdminAndNotCancelled(id);
    s_upkeep[id].executeGas = gasLimit;

    emit UpkeepGasLimitSet(id, gasLimit);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external {
    _requireAdminAndNotCancelled(id);

    s_upkeepOffchainConfig[id] = config;

    emit UpkeepOffchainConfigSet(id, config);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawPayment(address from, address to) external {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    if (s_transmitterPayees[from] != msg.sender) revert OnlyCallableByPayee();

    uint96 balance = _updateTransmitterBalanceFromPool(from, s_hotVars.totalPremium, uint96(s_transmittersList.length));
    s_transmitters[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance - balance;

    i_link.transfer(to, balance);

    emit PaymentWithdrawn(from, balance, to, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function transferPayeeship(address transmitter, address proposed) external {
    if (s_transmitterPayees[transmitter] != msg.sender) revert OnlyCallableByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedPayee[transmitter] != proposed) {
      s_proposedPayee[transmitter] = proposed;
      emit PayeeshipTransferRequested(transmitter, msg.sender, proposed);
    }
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function acceptPayeeship(address transmitter) external {
    if (s_proposedPayee[transmitter] != msg.sender) revert OnlyCallableByProposedPayee();
    address past = s_transmitterPayees[transmitter];
    s_transmitterPayees[transmitter] = msg.sender;
    s_proposedPayee[transmitter] = ZERO_ADDRESS;

    emit PayeeshipTransferred(transmitter, past, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function transferUpkeepAdmin(uint256 id, address proposed) external {
    _requireAdminAndNotCancelled(id);
    if (proposed == msg.sender) revert ValueNotChanged();
    if (proposed == ZERO_ADDRESS) revert InvalidRecipient();

    if (s_proposedAdmin[id] != proposed) {
      s_proposedAdmin[id] = proposed;
      emit UpkeepAdminTransferRequested(id, msg.sender, proposed);
    }
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function acceptUpkeepAdmin(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    if (s_proposedAdmin[id] != msg.sender) revert OnlyCallableByProposedAdmin();
    address past = s_upkeepAdmin[id];
    s_upkeepAdmin[id] = msg.sender;
    s_proposedAdmin[id] = ZERO_ADDRESS;

    emit UpkeepAdminTransferred(id, past, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function pauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.paused) revert OnlyUnpausedUpkeep();
    s_upkeep[id].paused = true;
    s_upkeepIDs.remove(id);
    emit UpkeepPaused(id);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function unpauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (!upkeep.paused) revert OnlyPausedUpkeep();
    s_upkeep[id].paused = false;
    s_upkeepIDs.add(id);
    emit UpkeepUnpaused(id);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function updateCheckData(uint256 id, bytes calldata newCheckData) external {
    _requireAdminAndNotCancelled(id);
    if (newCheckData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    s_checkData[id] = newCheckData;
    emit UpkeepCheckDataUpdated(id, newCheckData);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination) external {
    if (
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.OUTGOING &&
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    if (s_storage.transcoder == ZERO_ADDRESS) revert TranscoderNotSet();
    if (ids.length == 0) revert ArrayHasNoEntries();
    uint256 id;
    Upkeep memory upkeep;
    uint256 totalBalanceRemaining;
    bytes[] memory checkDatas = new bytes[](ids.length);
    address[] memory admins = new address[](ids.length);
    Upkeep[] memory upkeeps = new Upkeep[](ids.length);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      id = ids[idx];
      upkeep = s_upkeep[id];
      _requireAdminAndNotCancelled(id);
      upkeeps[idx] = upkeep;
      checkDatas[idx] = s_checkData[id];
      admins[idx] = s_upkeepAdmin[id];
      totalBalanceRemaining = totalBalanceRemaining + upkeep.balance;
      delete s_upkeep[id];
      delete s_checkData[id];
      // nullify existing proposed admin change if an upkeep is being migrated
      delete s_proposedAdmin[id];
      s_upkeepIDs.remove(id);
      emit UpkeepMigrated(id, upkeep.balance, destination);
    }
    s_expectedLinkBalance = s_expectedLinkBalance - totalBalanceRemaining;
    bytes memory encodedUpkeeps = abi.encode(ids, upkeeps, checkDatas, admins);
    MigratableKeeperRegistryInterfaceV2(destination).receiveUpkeeps(
      UpkeepTranscoderInterfaceV2(s_storage.transcoder).transcodeUpkeeps(
        UPKEEP_VERSION_BASE,
        MigratableKeeperRegistryInterfaceV2(destination).upkeepVersion(),
        encodedUpkeeps
      )
    );
    i_link.transfer(destination, totalBalanceRemaining);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external {
    if (
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.INCOMING &&
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    (uint256[] memory ids, Upkeep[] memory upkeeps, bytes[] memory checkDatas, address[] memory upkeepAdmins) = abi
      .decode(encodedUpkeeps, (uint256[], Upkeep[], bytes[], address[]));
    for (uint256 idx = 0; idx < ids.length; idx++) {
      _createUpkeep(
        ids[idx],
        upkeeps[idx].target,
        upkeeps[idx].executeGas,
        upkeepAdmins[idx],
        upkeeps[idx].balance,
        checkDatas[idx],
        upkeeps[idx].paused
      );
      emit UpkeepReceived(ids[idx], upkeeps[idx].balance, msg.sender);
    }
  }

  /**
   * @notice creates a new upkeep with the given fields
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param paused if this upkeep is paused
   */
  function _createUpkeep(
    uint256 id,
    address target,
    uint32 gasLimit,
    address admin,
    uint96 balance,
    bytes memory checkData,
    bool paused
  ) internal {
    if (s_hotVars.paused) revert RegistryPaused();
    if (!target.isContract()) revert NotAContract();
    if (checkData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    if (s_upkeep[id].target != address(0)) revert UpkeepAlreadyExists();
    s_upkeep[id] = Upkeep({
      target: target,
      executeGas: gasLimit,
      balance: balance,
      maxValidBlocknumber: UINT32_MAX,
      lastPerformBlockNumber: 0,
      amountSpent: 0,
      paused: paused
    });
    s_upkeepAdmin[id] = admin;
    s_expectedLinkBalance = s_expectedLinkBalance + balance;
    s_checkData[id] = checkData;
    s_upkeepIDs.add(id);
  }

  /**
   * @dev ensures the upkeep is not cancelled and the caller is the upkeep admin
   */
  function _requireAdminAndNotCancelled(uint256 upkeepId) internal view {
    if (msg.sender != s_upkeepAdmin[upkeepId]) revert OnlyCallableByAdmin();
    if (s_upkeep[upkeepId].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
  }
}

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

abstract contract ExecutionPrevention {
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
/**
 * @notice This is a deprecated interface. Please use AutomationBase directly.
 */
pragma solidity ^0.8.0;
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum UpkeepFormat {
  V1,
  V2,
  V3
}

// SPDX-License-Identifier: MIT

/**
  The Cron contract is a chainlink keepers-powered cron job runner for smart contracts.
  The contract enables developers to trigger actions on various targets using cron
  strings to specify the cadence. For example, a user may have 3 tasks that require
  regular service in their dapp ecosystem:
    1) 0xAB..CD, update(1), "0 0 * * *"     --> runs update(1) on 0xAB..CD daily at midnight
    2) 0xAB..CD, update(2), "30 12 * * 0-4" --> runs update(2) on 0xAB..CD weekdays at 12:30
    3) 0x12..34, trigger(), "0 * * * *"     --> runs trigger() on 0x12..34 hourly

  To use this contract, a user first deploys this contract and registers it on the chainlink
  keeper registry. Then the user adds cron jobs by following these steps:
    1) Convert a cron string to an encoded cron spec by calling encodeCronString()
    2) Take the encoding, target, and handler, and create a job by sending a tx to createCronJob()
    3) Cron job is running :)
*/

pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../ConfirmedOwner.sol";
import "../KeeperBase.sol";
import "../../interfaces/automation/KeeperCompatibleInterface.sol";
import {Cron as CronInternal, Spec} from "../../libraries/internal/Cron.sol";
import {Cron as CronExternal} from "../../libraries/external/Cron.sol";
import {getRevertMsg} from "../../utils/utils.sol";

/**
 * @title The CronUpkeep contract
 * @notice A keeper-compatible contract that runs various tasks on cron schedules.
 * Users must use the encodeCronString() function to encode their cron jobs before
 * setting them. This keeps all the string manipulation off chain and reduces gas costs.
 */
contract CronUpkeep is KeeperCompatibleInterface, KeeperBase, ConfirmedOwner, Pausable, Proxy {
  using EnumerableSet for EnumerableSet.UintSet;

  event CronJobExecuted(uint256 indexed id, uint256 timestamp);
  event CronJobCreated(uint256 indexed id, address target, bytes handler);
  event CronJobUpdated(uint256 indexed id, address target, bytes handler);
  event CronJobDeleted(uint256 indexed id);

  error CallFailed(uint256 id, string reason);
  error CronJobIDNotFound(uint256 id);
  error ExceedsMaxJobs();
  error InvalidHandler();
  error TickInFuture();
  error TickTooOld();
  error TickDoesntMatchSpec();

  address immutable s_delegate;
  uint256 public immutable s_maxJobs;
  uint256 private s_nextCronJobID = 1;
  EnumerableSet.UintSet private s_activeCronJobIDs;

  mapping(uint256 => uint256) private s_lastRuns;
  mapping(uint256 => Spec) private s_specs;
  mapping(uint256 => address) private s_targets;
  mapping(uint256 => bytes) private s_handlers;
  mapping(uint256 => bytes32) private s_handlerSignatures;

  /**
   * @param owner the initial owner of the contract
   * @param delegate the contract to delegate checkUpkeep calls to
   * @param maxJobs the max number of cron jobs this contract will support
   * @param firstJob an optional encoding of the first cron job
   */
  constructor(
    address owner,
    address delegate,
    uint256 maxJobs,
    bytes memory firstJob
  ) ConfirmedOwner(owner) {
    s_delegate = delegate;
    s_maxJobs = maxJobs;
    if (firstJob.length > 0) {
      (address target, bytes memory handler, Spec memory spec) = abi.decode(firstJob, (address, bytes, Spec));
      createCronJobFromSpec(target, handler, spec);
    }
  }

  /**
   * @notice Executes the cron job with id encoded in performData
   * @param performData abi encoding of cron job ID and the cron job's next run-at datetime
   */
  function performUpkeep(bytes calldata performData) external override whenNotPaused {
    (uint256 id, uint256 tickTime, address target, bytes memory handler) = abi.decode(
      performData,
      (uint256, uint256, address, bytes)
    );
    validate(id, tickTime, target, handler);
    s_lastRuns[id] = block.timestamp;
    (bool success, bytes memory payload) = target.call(handler);
    if (!success) {
      revert CallFailed(id, getRevertMsg(payload));
    }
    emit CronJobExecuted(id, block.timestamp);
  }

  /**
   * @notice Creates a cron job from the given encoded spec
   * @param target the destination contract of a cron job
   * @param handler the function signature on the target contract to call
   * @param encodedCronSpec abi encoding of a cron spec
   */
  function createCronJobFromEncodedSpec(
    address target,
    bytes memory handler,
    bytes memory encodedCronSpec
  ) external onlyOwner {
    if (s_activeCronJobIDs.length() >= s_maxJobs) {
      revert ExceedsMaxJobs();
    }
    Spec memory spec = abi.decode(encodedCronSpec, (Spec));
    createCronJobFromSpec(target, handler, spec);
  }

  /**
   * @notice Updates a cron job from the given encoded spec
   * @param id the id of the cron job to update
   * @param newTarget the destination contract of a cron job
   * @param newHandler the function signature on the target contract to call
   * @param newEncodedCronSpec abi encoding of a cron spec
   */
  function updateCronJob(
    uint256 id,
    address newTarget,
    bytes memory newHandler,
    bytes memory newEncodedCronSpec
  ) external onlyOwner onlyValidCronID(id) {
    Spec memory newSpec = abi.decode(newEncodedCronSpec, (Spec));
    s_targets[id] = newTarget;
    s_handlers[id] = newHandler;
    s_specs[id] = newSpec;
    s_handlerSignatures[id] = handlerSig(newTarget, newHandler);
    emit CronJobUpdated(id, newTarget, newHandler);
  }

  /**
   * @notice Deletes the cron job matching the provided id. Reverts if
   * the id is not found.
   * @param id the id of the cron job to delete
   */
  function deleteCronJob(uint256 id) external onlyOwner onlyValidCronID(id) {
    delete s_lastRuns[id];
    delete s_specs[id];
    delete s_targets[id];
    delete s_handlers[id];
    delete s_handlerSignatures[id];
    s_activeCronJobIDs.remove(id);
    emit CronJobDeleted(id);
  }

  /**
   * @notice Pauses the contract, which prevents executing performUpkeep
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpauses the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Get the id of an eligible cron job
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoding
   * of the id and "next tick" of the elligible cron job
   */
  function checkUpkeep(bytes calldata) external override whenNotPaused cannotExecute returns (bool, bytes memory) {
    _delegate(s_delegate);
  }

  /**
   * @notice gets a list of active cron job IDs
   * @return list of active cron job IDs
   */
  function getActiveCronJobIDs() external view returns (uint256[] memory) {
    uint256 length = s_activeCronJobIDs.length();
    uint256[] memory jobIDs = new uint256[](length);
    for (uint256 idx = 0; idx < length; idx++) {
      jobIDs[idx] = s_activeCronJobIDs.at(idx);
    }
    return jobIDs;
  }

  /**
   * @notice gets a cron job
   * @param id the cron job ID
   * @return target - the address a cron job forwards the eth tx to
             handler - the encoded function sig to execute when forwarding a tx
             cronString - the string representing the cron job
             nextTick - the timestamp of the next time the cron job will run
   */
  function getCronJob(uint256 id)
    external
    view
    onlyValidCronID(id)
    returns (
      address target,
      bytes memory handler,
      string memory cronString,
      uint256 nextTick
    )
  {
    Spec memory spec = s_specs[id];
    return (s_targets[id], s_handlers[id], CronExternal.toCronString(spec), CronExternal.nextTick(spec));
  }

  /**
   * @notice Adds a cron spec to storage and the ID to the list of jobs
   * @param target the destination contract of a cron job
   * @param handler the function signature on the target contract to call
   * @param spec the cron spec to create
   */
  function createCronJobFromSpec(
    address target,
    bytes memory handler,
    Spec memory spec
  ) internal {
    uint256 newID = s_nextCronJobID;
    s_activeCronJobIDs.add(newID);
    s_targets[newID] = target;
    s_handlers[newID] = handler;
    s_specs[newID] = spec;
    s_lastRuns[newID] = block.timestamp;
    s_handlerSignatures[newID] = handlerSig(target, handler);
    s_nextCronJobID++;
    emit CronJobCreated(newID, target, handler);
  }

  function _implementation() internal view override returns (address) {
    return s_delegate;
  }

  /**
   * @notice validates the input to performUpkeep
   * @param id the id of the cron job
   * @param tickTime the observed tick time
   * @param target the contract to forward the tx to
   * @param handler the handler of the contract receiving the forwarded tx
   */
  function validate(
    uint256 id,
    uint256 tickTime,
    address target,
    bytes memory handler
  ) private {
    tickTime = tickTime - (tickTime % 60); // remove seconds from tick time
    if (block.timestamp < tickTime) {
      revert TickInFuture();
    }
    if (tickTime <= s_lastRuns[id]) {
      revert TickTooOld();
    }
    if (!CronInternal.matches(s_specs[id], tickTime)) {
      revert TickDoesntMatchSpec();
    }
    if (handlerSig(target, handler) != s_handlerSignatures[id]) {
      revert InvalidHandler();
    }
  }

  /**
   * @notice returns a unique identifier for target/handler pairs
   * @param target the contract to forward the tx to
   * @param handler the handler of the contract receiving the forwarded tx
   * @return a hash of the inputs
   */
  function handlerSig(address target, bytes memory handler) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(target, handler));
  }

  modifier onlyValidCronID(uint256 id) {
    if (!s_activeCronJobIDs.contains(id)) {
      revert CronJobIDNotFound(id);
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Cron, Spec} from "../../libraries/internal/Cron.sol";

/**
 * @title The CronUpkeepDelegate contract
 * @notice This contract serves as a delegate for all instances of CronUpkeep. Those contracts
 * delegate their checkUpkeep calls onto this contract. Utilizing this pattern reduces the size
 * of the CronUpkeep contracts.
 */
contract CronUpkeepDelegate {
  using EnumerableSet for EnumerableSet.UintSet;
  using Cron for Spec;

  address private s_owner; // from ConfirmedOwner
  address private s_delegate;
  uint256 private s_nextCronJobID;
  EnumerableSet.UintSet private s_activeCronJobIDs;
  mapping(uint256 => uint256) private s_lastRuns;
  mapping(uint256 => Spec) private s_specs;
  mapping(uint256 => address) private s_targets;
  mapping(uint256 => bytes) private s_handlers;

  /**
   * @notice Get the id of an eligible cron job
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoding
   * of the id and "next tick" of the eligible cron job
   */
  function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
    // DEV: start at a random spot in the list so that checks are
    // spread evenly among cron jobs
    uint256 numCrons = s_activeCronJobIDs.length();
    if (numCrons == 0) {
      return (false, bytes(""));
    }
    uint256 startIdx = block.number % numCrons;
    bool result;
    bytes memory payload;
    (result, payload) = checkInRange(startIdx, numCrons);
    if (result) {
      return (result, payload);
    }
    (result, payload) = checkInRange(0, startIdx);
    if (result) {
      return (result, payload);
    }
    return (false, bytes(""));
  }

  /**
   * @notice checks the cron jobs in a given range
   * @param start the starting id to check (inclusive)
   * @param end the ending id to check (exclusive)
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoding
   * of the id and "next tick" of the eligible cron job
   */
  function checkInRange(uint256 start, uint256 end) private view returns (bool, bytes memory) {
    uint256 id;
    uint256 lastTick;
    for (uint256 idx = start; idx < end; idx++) {
      id = s_activeCronJobIDs.at(idx);
      lastTick = s_specs[id].lastTick();
      if (lastTick > s_lastRuns[id]) {
        return (true, abi.encode(id, lastTick, s_targets[id], s_handlers[id]));
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./CronUpkeep.sol";
import "./CronUpkeepDelegate.sol";
import "../../ConfirmedOwner.sol";
import {Spec, Cron as CronExternal} from "../../libraries/external/Cron.sol";

/**
 * @title The CronUpkeepFactory contract
 * @notice This contract serves as a delegate for all instances of CronUpkeep. Those contracts
 * delegate their checkUpkeep calls onto this contract. Utilizing this pattern reduces the size
 * of the CronUpkeep contracts.
 */
contract CronUpkeepFactory is ConfirmedOwner {
  event NewCronUpkeepCreated(address upkeep, address owner);

  address private immutable s_cronDelegate;
  uint256 public s_maxJobs = 5;

  constructor() ConfirmedOwner(msg.sender) {
    s_cronDelegate = address(new CronUpkeepDelegate());
  }

  /**
   * @notice Creates a new CronUpkeep contract, with msg.sender as the owner
   */
  function newCronUpkeep() external {
    newCronUpkeepWithJob(bytes(""));
  }

  /**
   * @notice Creates a new CronUpkeep contract, with msg.sender as the owner, and registers a cron job
   */
  function newCronUpkeepWithJob(bytes memory encodedJob) public {
    emit NewCronUpkeepCreated(address(new CronUpkeep(msg.sender, s_cronDelegate, s_maxJobs, encodedJob)), msg.sender);
  }

  /**
   * @notice Sets the max job limit on new cron upkeeps
   */
  function setMaxJobs(uint256 maxJobs) external onlyOwner {
    s_maxJobs = maxJobs;
  }

  /**
   * @notice Gets the address of the delegate contract
   * @return the address of the delegate contract
   */
  function cronDelegateAddress() external view returns (address) {
    return s_cronDelegate;
  }

  /**
   * @notice Converts a cron string to a Spec, validates the spec, and encodes the spec.
   * This should only be called off-chain, as it is gas expensive!
   * @param cronString the cron string to convert and encode
   * @return the abi encoding of the Spec struct representing the cron string
   */
  function encodeCronString(string memory cronString) external pure returns (bytes memory) {
    return CronExternal.toEncodedSpec(cronString);
  }

  /**
   * @notice Converts, validates, and encodes a full cron spec. This payload is then passed to newCronUpkeepWithJob.
   * @param target the destination contract of a cron job
   * @param handler the function signature on the target contract to call
   * @param cronString the cron string to convert and encode
   * @return the abi encoding of the entire cron job
   */
  function encodeCronJob(
    address target,
    bytes memory handler,
    string memory cronString
  ) external pure returns (bytes memory) {
    Spec memory spec = CronExternal.toSpec(cronString);
    return abi.encode(target, handler, spec);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title BatchBlockhashStore
 * @notice The BatchBlockhashStore contract acts as a proxy to write many blockhashes to the
 *   provided BlockhashStore contract efficiently in a single transaction. This results
 *   in plenty of gas savings and higher throughput of blockhash storage, which is desirable
 *   in times of high network congestion.
 */
contract BatchBlockhashStore {
  BlockhashStore public immutable BHS;

  constructor(address blockhashStoreAddr) {
    BHS = BlockhashStore(blockhashStoreAddr);
  }

  /**
   * @notice stores blockhashes of the given block numbers in the configured blockhash store, assuming
   *   they are availble though the blockhash() instruction.
   * @param blockNumbers the block numbers to store the blockhashes of. Must be available via the
   *   blockhash() instruction, otherwise this function call will revert.
   */
  function store(uint256[] memory blockNumbers) public {
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      // skip the block if it's not storeable, the caller will have to check
      // after the transaction is mined to see if the blockhash was truly stored.
      if (!storeableBlock(blockNumbers[i])) {
        continue;
      }
      BHS.store(blockNumbers[i]);
    }
  }

  /**
   * @notice stores blockhashes after verifying blockheader of child/subsequent block
   * @param blockNumbers the block numbers whose blockhashes should be stored, in decreasing order
   * @param headers the rlp-encoded block headers of blockNumbers[i] + 1.
   */
  function storeVerifyHeader(uint256[] memory blockNumbers, bytes[] memory headers) public {
    require(blockNumbers.length == headers.length, "input array arg lengths mismatch");
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      BHS.storeVerifyHeader(blockNumbers[i], headers[i]);
    }
  }

  /**
   * @notice retrieves blockhashes of all the given block numbers from the blockhash store, if available.
   * @param blockNumbers array of block numbers to fetch blockhashes for
   * @return blockhashes array of block hashes corresponding to each block number provided in the `blockNumbers`
   *   param. If the blockhash is not found, 0x0 is returned instead of the real blockhash, indicating
   *   that it is not in the blockhash store.
   */
  function getBlockhashes(uint256[] memory blockNumbers) external view returns (bytes32[] memory) {
    bytes32[] memory blockHashes = new bytes32[](blockNumbers.length);
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      try BHS.getBlockhash(blockNumbers[i]) returns (bytes32 bh) {
        blockHashes[i] = bh;
      } catch Error(
        string memory /* reason */
      ) {
        blockHashes[i] = 0x0;
      }
    }
    return blockHashes;
  }

  /**
   * @notice returns true if and only if the given block number's blockhash can be retrieved
   *   using the blockhash() instruction.
   * @param blockNumber the block number to check if it's storeable with blockhash()
   */
  function storeableBlock(uint256 blockNumber) private view returns (bool) {
    // handle edge case on simulated chains which possibly have < 256 blocks total.
    return block.number <= 256 ? true : blockNumber >= (block.number - 256);
  }
}

interface BlockhashStore {
  function storeVerifyHeader(uint256 n, bytes memory header) external;

  function store(uint256 n) external;

  function getBlockhash(uint256 n) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./VRFTypes.sol";

/**
 * @title BatchVRFCoordinatorV2
 * @notice The BatchVRFCoordinatorV2 contract acts as a proxy to write many random responses to the
 *   provided VRFCoordinatorV2 contract efficiently in a single transaction.
 */
contract BatchVRFCoordinatorV2 {
  VRFCoordinatorV2 public immutable COORDINATOR;

  event ErrorReturned(uint256 indexed requestId, string reason);
  event RawErrorReturned(uint256 indexed requestId, bytes lowLevelData);

  constructor(address coordinatorAddr) {
    COORDINATOR = VRFCoordinatorV2(coordinatorAddr);
  }

  /**
   * @notice fulfills multiple randomness requests with the provided proofs and commitments.
   * @param proofs the randomness proofs generated by the VRF provider.
   * @param rcs the request commitments corresponding to the randomness proofs.
   */
  function fulfillRandomWords(VRFTypes.Proof[] memory proofs, VRFTypes.RequestCommitment[] memory rcs) external {
    require(proofs.length == rcs.length, "input array arg lengths mismatch");
    for (uint256 i = 0; i < proofs.length; i++) {
      try COORDINATOR.fulfillRandomWords(proofs[i], rcs[i]) returns (
        uint96 /* payment */
      ) {
        continue;
      } catch Error(string memory reason) {
        uint256 requestId = getRequestIdFromProof(proofs[i]);
        emit ErrorReturned(requestId, reason);
      } catch (bytes memory lowLevelData) {
        uint256 requestId = getRequestIdFromProof(proofs[i]);
        emit RawErrorReturned(requestId, lowLevelData);
      }
    }
  }

  /**
   * @notice Returns the proving key hash associated with this public key.
   * @param publicKey the key to return the hash of.
   */
  function hashOfKey(uint256[2] memory publicKey) internal pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  /**
   * @notice Returns the request ID of the request associated with the given proof.
   * @param proof the VRF proof provided by the VRF oracle.
   */
  function getRequestIdFromProof(VRFTypes.Proof memory proof) internal pure returns (uint256) {
    bytes32 keyHash = hashOfKey(proof.pk);
    return uint256(keccak256(abi.encode(keyHash, proof.seed)));
  }
}

interface VRFCoordinatorV2 {
  function fulfillRandomWords(VRFTypes.Proof memory proof, VRFTypes.RequestCommitment memory rc)
    external
    returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/proxy/Proxy.sol";
import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import "./KeeperRegistryBase2_1.sol";
import {AutomationRegistryExecutableInterface, UpkeepInfo} from "../../interfaces/automation/2_1/AutomationRegistryInterface2_1.sol";
import "../../../interfaces/automation/MigratableKeeperRegistryInterface.sol";
import "../../../interfaces/automation/MigratableKeeperRegistryInterfaceV2.sol";
import "../../../interfaces/ERC677ReceiverInterface.sol";
import "../../../OCR2Abstract.sol";

/**
 _.  _|_ _ ._ _  _._|_o _ ._  o _  _    ._  _| _  __|_o._
(_||_||_(_)| | |(_| |_|(_)| | |_> (_)|_||  (_|(/__> |_|| |\/
                                                          /
 */
/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry2_1 is
  KeeperRegistryBase2_1,
  Proxy,
  OCR2Abstract,
  AutomationRegistryExecutableInterface,
  MigratableKeeperRegistryInterface,
  MigratableKeeperRegistryInterfaceV2,
  ERC677ReceiverInterface
{
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  // Immutable address of logic contract where some functionality is delegated to
  address private immutable i_keeperRegistryLogic;

  /**
   * @notice versions:
   * - KeeperRegistry 2.0.1: implements workaround for buggy migrate function in 1.X
   * - KeeperRegistry 2.0.0: implement OCR interface
   * - KeeperRegistry 1.3.0: split contract into Proxy and Logic
   *                       : account for Arbitrum and Optimism L1 gas fee
   *                       : allow users to configure upkeeps
   * - KeeperRegistry 1.2.0: allow funding within performUpkeep
   *                       : allow configurable registry maxPerformGas
   *                       : add function to let admin change upkeep gas limit
   *                       : add minUpkeepSpend requirement
   *                       : upgrade to solidity v0.8
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 2.0.1";

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  UpkeepFormat public constant override upkeepTranscoderVersion = UPKEEP_TRANSCODER_VERSION_BASE;

  /**
   * @inheritdoc MigratableKeeperRegistryInterfaceV2
   */
  uint8 public constant override upkeepVersion = UPKEEP_VERSION_BASE;

  /**
   * @param keeperRegistryLogic address of the logic contract
   */
  constructor(KeeperRegistryBase2_1 keeperRegistryLogic)
    KeeperRegistryBase2_1(
      keeperRegistryLogic.getPaymentModel(),
      keeperRegistryLogic.getLinkAddress(),
      keeperRegistryLogic.getLinkNativeFeedAddress(),
      keeperRegistryLogic.getFastGasFeedAddress()
    )
  {
    i_keeperRegistryLogic = address(keeperRegistryLogic);
  }

  ////////
  // ACTIONS
  ////////

  /**
   * @dev This struct is used to maintain run time information about an upkeep in transmit function
   * @member upkeep the upkeep struct
   * @member earlyChecksPassed whether the upkeep passed early checks before perform
   * @member paymentParams the paymentParams for this upkeep
   * @member performSuccess whether the perform was successful
   * @member gasUsed gasUsed by this upkeep in perform
   */
  struct UpkeepTransmitInfo {
    Upkeep upkeep;
    bool earlyChecksPassed;
    uint96 maxLinkPayment;
    bool performSuccess;
    uint256 gasUsed;
    uint256 gasOverhead;
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function transmit(
    bytes32[3] calldata reportContext,
    bytes calldata rawReport,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) external override {
    uint256 gasOverhead = gasleft();
    HotVars memory hotVars = s_hotVars;

    if (hotVars.paused) revert RegistryPaused();
    if (!s_transmitters[msg.sender].active) revert OnlyActiveTransmitters();

    Report memory report = _decodeReport(rawReport);
    UpkeepTransmitInfo[] memory upkeepTransmitInfo = new UpkeepTransmitInfo[](report.upkeepIds.length);
    uint16 numUpkeepsPassedChecks;

    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      upkeepTransmitInfo[i].upkeep = s_upkeep[report.upkeepIds[i]];

      upkeepTransmitInfo[i].maxLinkPayment = _getMaxLinkPayment(
        hotVars,
        upkeepTransmitInfo[i].upkeep.executeGas,
        uint32(report.wrappedPerformDatas[i].performData.length),
        report.fastGasWei,
        report.linkNative,
        true
      );
      upkeepTransmitInfo[i].earlyChecksPassed = _prePerformChecks(
        report.upkeepIds[i],
        report.wrappedPerformDatas[i],
        upkeepTransmitInfo[i].upkeep,
        upkeepTransmitInfo[i].maxLinkPayment
      );

      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        numUpkeepsPassedChecks += 1;
      }
    }
    // No upkeeps to be performed in this report
    if (numUpkeepsPassedChecks == 0) revert StaleReport();

    // Verify signatures
    if (s_latestConfigDigest != reportContext[0]) revert ConfigDigestMismatch();
    if (rs.length != hotVars.f + 1 || rs.length != ss.length) revert IncorrectNumberOfSignatures();
    _verifyReportSignature(reportContext, rawReport, rs, ss, rawVs);

    // Actually perform upkeeps
    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        // Check if this upkeep was already performed in this report
        if (s_upkeep[report.upkeepIds[i]].lastPerformBlockNumber == uint32(block.number)) {
          revert InvalidReport();
        }

        // Actually perform the target upkeep
        (upkeepTransmitInfo[i].performSuccess, upkeepTransmitInfo[i].gasUsed) = _performUpkeep(
          upkeepTransmitInfo[i].upkeep,
          report.wrappedPerformDatas[i].performData
        );

        // Deduct that gasUsed by upkeep from our running counter
        gasOverhead -= upkeepTransmitInfo[i].gasUsed;

        // Store last perform block number for upkeep
        s_upkeep[report.upkeepIds[i]].lastPerformBlockNumber = uint32(block.number);
      }
    }

    // This is the overall gas overhead that will be split across performed upkeeps
    // Take upper bound of 16 gas per callData bytes, which is approximated to be reportLength
    // Rest of msg.data is accounted for in accounting overheads
    gasOverhead =
      (gasOverhead - gasleft() + 16 * rawReport.length) +
      ACCOUNTING_FIXED_GAS_OVERHEAD +
      (ACCOUNTING_PER_SIGNER_GAS_OVERHEAD * (hotVars.f + 1));
    gasOverhead = gasOverhead / numUpkeepsPassedChecks + ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD;

    uint96 totalReimbursement;
    uint96 totalPremium;
    {
      uint96 reimbursement;
      uint96 premium;
      for (uint256 i = 0; i < report.upkeepIds.length; i++) {
        if (upkeepTransmitInfo[i].earlyChecksPassed) {
          upkeepTransmitInfo[i].gasOverhead = _getCappedGasOverhead(
            gasOverhead,
            uint32(report.wrappedPerformDatas[i].performData.length),
            hotVars.f
          );

          (reimbursement, premium) = _postPerformPayment(
            hotVars,
            report.upkeepIds[i],
            upkeepTransmitInfo[i],
            report.fastGasWei,
            report.linkNative,
            numUpkeepsPassedChecks
          );
          totalPremium += premium;
          totalReimbursement += reimbursement;

          emit UpkeepPerformed(
            report.upkeepIds[i],
            upkeepTransmitInfo[i].performSuccess,
            report.wrappedPerformDatas[i].checkBlockNumber,
            upkeepTransmitInfo[i].gasUsed,
            upkeepTransmitInfo[i].gasOverhead,
            reimbursement + premium
          );
        }
      }
    }
    // record payments
    s_transmitters[msg.sender].balance += totalReimbursement;
    s_hotVars.totalPremium += totalPremium;

    uint40 epochAndRound = uint40(uint256(reportContext[1]));
    uint32 epoch = uint32(epochAndRound >> 8);
    if (epoch > hotVars.latestEpoch) {
      s_hotVars.latestEpoch = epoch;
    }
  }

  /**
   * @notice simulates the upkeep with the perform data returned from
   * checkUpkeep
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   */
  function simulatePerformUpkeep(uint256 id, bytes calldata performData)
    external
    cannotExecute
    returns (bool success, uint256 gasUsed)
  {
    if (s_hotVars.paused) revert RegistryPaused();

    Upkeep memory upkeep = s_upkeep[id];
    return _performUpkeep(upkeep, performData);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external override {
    if (msg.sender != address(i_link)) revert OnlyCallableByLINKToken();
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (s_upkeep[id].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = s_upkeep[id].balance + uint96(amount);
    s_expectedLinkBalance = s_expectedLinkBalance + amount;

    emit FundsAdded(id, sender, uint96(amount));
  }

  ////////
  // SETTERS
  ////////

  /**
   * @inheritdoc OCR2Abstract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external override onlyOwner {
    if (signers.length > maxNumOracles) revert TooManyOracles();
    if (f == 0) revert IncorrectNumberOfFaultyOracles();
    if (signers.length != transmitters.length || signers.length <= 3 * f) revert IncorrectNumberOfSigners();

    // move all pooled payments out of the pool to each transmitter's balance
    uint96 totalPremium = s_hotVars.totalPremium;
    uint96 oldLength = uint96(s_transmittersList.length);
    for (uint256 i = 0; i < oldLength; i++) {
      _updateTransmitterBalanceFromPool(s_transmittersList[i], totalPremium, oldLength);
    }

    // remove any old signer/transmitter addresses
    address signerAddress;
    address transmitterAddress;
    for (uint256 i = 0; i < oldLength; i++) {
      signerAddress = s_signersList[i];
      transmitterAddress = s_transmittersList[i];
      delete s_signers[signerAddress];
      // Do not delete the whole transmitter struct as it has balance information stored
      s_transmitters[transmitterAddress].active = false;
    }
    delete s_signersList;
    delete s_transmittersList;

    // add new signer/transmitter addresses
    {
      Transmitter memory transmitter;
      address temp;
      for (uint256 i = 0; i < signers.length; i++) {
        if (s_signers[signers[i]].active) revert RepeatedSigner();
        s_signers[signers[i]] = Signer({active: true, index: uint8(i)});

        temp = transmitters[i];
        transmitter = s_transmitters[temp];
        if (transmitter.active) revert RepeatedTransmitter();
        transmitter.active = true;
        transmitter.index = uint8(i);
        transmitter.lastCollected = totalPremium;
        s_transmitters[temp] = transmitter;
      }
    }
    s_signersList = signers;
    s_transmittersList = transmitters;

    // Set the onchain config
    OnchainConfig memory onchainConfigStruct = abi.decode(onchainConfig, (OnchainConfig));
    if (onchainConfigStruct.maxPerformGas < s_storage.maxPerformGas) revert GasLimitCanOnlyIncrease();
    if (onchainConfigStruct.maxCheckDataSize < s_storage.maxCheckDataSize) revert MaxCheckDataSizeCanOnlyIncrease();
    if (onchainConfigStruct.maxPerformDataSize < s_storage.maxPerformDataSize)
      revert MaxPerformDataSizeCanOnlyIncrease();

    s_hotVars = HotVars({
      f: f,
      paymentPremiumPPB: onchainConfigStruct.paymentPremiumPPB,
      flatFeeMicroLink: onchainConfigStruct.flatFeeMicroLink,
      stalenessSeconds: onchainConfigStruct.stalenessSeconds,
      gasCeilingMultiplier: onchainConfigStruct.gasCeilingMultiplier,
      paused: false,
      reentrancyGuard: false,
      totalPremium: totalPremium,
      latestEpoch: 0
    });

    s_storage = Storage({
      checkGasLimit: onchainConfigStruct.checkGasLimit,
      minUpkeepSpend: onchainConfigStruct.minUpkeepSpend,
      maxPerformGas: onchainConfigStruct.maxPerformGas,
      transcoder: onchainConfigStruct.transcoder,
      registrar: onchainConfigStruct.registrar,
      maxCheckDataSize: onchainConfigStruct.maxCheckDataSize,
      maxPerformDataSize: onchainConfigStruct.maxPerformDataSize,
      nonce: s_storage.nonce,
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      ownerLinkBalance: s_storage.ownerLinkBalance
    });
    s_fallbackGasPrice = onchainConfigStruct.fallbackGasPrice;
    s_fallbackLinkPrice = onchainConfigStruct.fallbackLinkPrice;

    uint32 previousConfigBlockNumber = s_storage.latestConfigBlockNumber;
    s_storage.latestConfigBlockNumber = uint32(block.number);
    s_storage.configCount += 1;

    s_latestConfigDigest = _configDigestFromConfigData(
      block.chainid,
      address(this),
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );

    emit ConfigSet(
      previousConfigBlockNumber,
      s_latestConfigDigest,
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );
  }

  ////////
  // GETTERS
  ////////

  /**
   * @notice read all of the details about an upkeep
   */
  function getUpkeep(uint256 id) external view override returns (UpkeepInfo memory upkeepInfo) {
    Upkeep memory reg = s_upkeep[id];
    upkeepInfo = UpkeepInfo({
      target: reg.target,
      executeGas: reg.executeGas,
      checkData: s_checkData[id],
      balance: reg.balance,
      admin: s_upkeepAdmin[id],
      maxValidBlocknumber: reg.maxValidBlocknumber,
      lastPerformBlockNumber: reg.lastPerformBlockNumber,
      amountSpent: reg.amountSpent,
      paused: reg.paused,
      offchainConfig: s_upkeepOffchainConfig[id]
    });
    return upkeepInfo;
  }

  /**
   * @notice retrieve active upkeep IDs. Active upkeep is defined as an upkeep which is not paused and not canceled.
   * @param startIndex starting index in list
   * @param maxCount max number of upkeep IDs to retrieve (0 = unlimited)
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view override returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0 || maxCount + startIndex > maxIdx) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice read the current info about any transmitter address
   */
  function getTransmitterInfo(address query)
    external
    view
    override
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    )
  {
    Transmitter memory transmitter = s_transmitters[query];
    uint96 totalDifference = s_hotVars.totalPremium - transmitter.lastCollected;
    uint96 pooledShare = totalDifference / uint96(s_transmittersList.length);

    return (
      transmitter.active,
      transmitter.index,
      (transmitter.balance + pooledShare),
      transmitter.lastCollected,
      s_transmitterPayees[query]
    );
  }

  /**
   * @notice read the current info about any signer address
   */
  function getSignerInfo(address query) external view returns (bool active, uint8 index) {
    Signer memory signer = s_signers[query];
    return (signer.active, signer.index);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    override
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    )
  {
    state = State({
      nonce: s_storage.nonce,
      ownerLinkBalance: s_storage.ownerLinkBalance,
      expectedLinkBalance: s_expectedLinkBalance,
      totalPremium: s_hotVars.totalPremium,
      numUpkeeps: s_upkeepIDs.length(),
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      latestConfigDigest: s_latestConfigDigest,
      latestEpoch: s_hotVars.latestEpoch,
      paused: s_hotVars.paused
    });

    config = OnchainConfig({
      paymentPremiumPPB: s_hotVars.paymentPremiumPPB,
      flatFeeMicroLink: s_hotVars.flatFeeMicroLink,
      checkGasLimit: s_storage.checkGasLimit,
      stalenessSeconds: s_hotVars.stalenessSeconds,
      gasCeilingMultiplier: s_hotVars.gasCeilingMultiplier,
      minUpkeepSpend: s_storage.minUpkeepSpend,
      maxPerformGas: s_storage.maxPerformGas,
      maxCheckDataSize: s_storage.maxCheckDataSize,
      maxPerformDataSize: s_storage.maxPerformDataSize,
      fallbackGasPrice: s_fallbackGasPrice,
      fallbackLinkPrice: s_fallbackLinkPrice,
      transcoder: s_storage.transcoder,
      registrar: s_storage.registrar
    });

    return (state, config, s_signersList, s_transmittersList, s_hotVars.f);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance) {
    return getMaxPaymentForGas(s_upkeep[id].executeGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(uint32 gasLimit) public view returns (uint96 maxPayment) {
    HotVars memory hotVars = s_hotVars;
    (uint256 fastGasWei, uint256 linkNative) = _getFeedData(hotVars);
    return _getMaxLinkPayment(hotVars, gasLimit, s_storage.maxPerformDataSize, fastGasWei, linkNative, false);
  }

  /**
   * @notice retrieves the migration permission for a peer registry
   */
  function getPeerRegistryMigrationPermission(address peer) external view returns (MigrationPermission) {
    return s_peerRegistryMigrationPermission[peer];
  }

  /**
   * @notice retrieves the address of the logic address
   */
  function getKeeperRegistryLogicAddress() external view returns (address) {
    return i_keeperRegistryLogic;
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDetails()
    external
    view
    override
    returns (
      uint32 configCount,
      uint32 blockNumber,
      bytes32 configDigest
    )
  {
    return (s_storage.configCount, s_storage.latestConfigBlockNumber, s_latestConfigDigest);
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDigestAndEpoch()
    external
    view
    override
    returns (
      bool scanLogs,
      bytes32 configDigest,
      uint32 epoch
    )
  {
    return (false, s_latestConfigDigest, s_hotVars.latestEpoch);
  }

  ////////
  // INTERNAL FUNCTIONS
  ////////

  /**
   * @dev This is the address to which proxy functions are delegated to
   */
  function _implementation() internal view override returns (address) {
    return i_keeperRegistryLogic;
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available
   */
  function _callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  /**
   * @dev _decodeReport decodes a serialized report into a Report struct
   */
  function _decodeReport(bytes memory rawReport) internal pure returns (Report memory) {
    (
      uint256 fastGasWei,
      uint256 linkNative,
      uint256[] memory upkeepIds,
      PerformDataWrapper[] memory wrappedPerformDatas
    ) = abi.decode(rawReport, (uint256, uint256, uint256[], PerformDataWrapper[]));
    if (upkeepIds.length != wrappedPerformDatas.length) revert InvalidReport();

    return
      Report({
        fastGasWei: fastGasWei,
        linkNative: linkNative,
        upkeepIds: upkeepIds,
        wrappedPerformDatas: wrappedPerformDatas
      });
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   */
  function _prePerformChecks(
    uint256 upkeepId,
    PerformDataWrapper memory wrappedPerformData,
    Upkeep memory upkeep,
    uint96 maxLinkPayment
  ) internal returns (bool) {
    if (wrappedPerformData.checkBlockNumber < upkeep.lastPerformBlockNumber) {
      // Can happen when another report performed this upkeep after this report was generated
      emit StaleUpkeepReport(upkeepId);
      return false;
    }

    if (blockhash(wrappedPerformData.checkBlockNumber) != wrappedPerformData.checkBlockhash) {
      // Can happen when the block on which report was generated got reorged
      // We will also revert if checkBlockNumber is older than 256 blocks. In this case we rely on a new transmission
      // with the latest checkBlockNumber
      emit ReorgedUpkeepReport(upkeepId);
      return false;
    }

    if (upkeep.maxValidBlocknumber <= block.number) {
      // Can happen when an upkeep got cancelled after report was generated.
      // However we have a CANCELLATION_DELAY of 50 blocks so shouldn't happen in practice
      emit CancelledUpkeepReport(upkeepId);
      return false;
    }

    if (upkeep.balance < maxLinkPayment) {
      // Can happen due to flucutations in gas / link prices
      emit InsufficientFundsUpkeepReport(upkeepId);
      return false;
    }

    return true;
  }

  /**
   * @dev Verify signatures attached to report
   */
  function _verifyReportSignature(
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) internal view {
    bytes32 h = keccak256(abi.encode(keccak256(report), reportContext));
    // i-th byte counts number of sigs made by i-th signer
    uint256 signedCount = 0;

    Signer memory signer;
    address signerAddress;
    for (uint256 i = 0; i < rs.length; i++) {
      signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
      signer = s_signers[signerAddress];
      if (!signer.active) revert OnlyActiveSigners();
      unchecked {
        signedCount += 1 << (8 * signer.index);
      }
    }

    if (signedCount & ORACLE_MASK != signedCount) revert DuplicateSigners();
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * transmitter and the exact gas required by the Upkeep
   */
  function _performUpkeep(Upkeep memory upkeep, bytes memory performData)
    private
    nonReentrant
    returns (bool success, uint256 gasUsed)
  {
    gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(PERFORM_SELECTOR, performData);
    success = _callWithExactGas(upkeep.executeGas, upkeep.target, callData);
    gasUsed = gasUsed - gasleft();

    return (success, gasUsed);
  }

  /**
   * @dev does postPerform payment processing for an upkeep. Deducts upkeep's balance and increases
   * amount spent.
   */
  function _postPerformPayment(
    HotVars memory hotVars,
    uint256 upkeepId,
    UpkeepTransmitInfo memory upkeepTransmitInfo,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps
  ) internal returns (uint96 gasReimbursement, uint96 premium) {
    (gasReimbursement, premium) = _calculatePaymentAmount(
      hotVars,
      upkeepTransmitInfo.gasUsed,
      upkeepTransmitInfo.gasOverhead,
      fastGasWei,
      linkNative,
      numBatchedUpkeeps,
      true
    );

    uint96 payment = gasReimbursement + premium;
    s_upkeep[upkeepId].balance -= payment;
    s_upkeep[upkeepId].amountSpent += payment;

    return (gasReimbursement, premium);
  }

  /**
   * @dev Caps the gas overhead by the constant overhead used within initial payment checks in order to
   * prevent a revert in payment processing.
   */
  function _getCappedGasOverhead(
    uint256 calculatedGasOverhead,
    uint32 performDataLength,
    uint8 f
  ) private pure returns (uint256 cappedGasOverhead) {
    cappedGasOverhead = _getMaxGasOverhead(performDataLength, f);
    if (calculatedGasOverhead < cappedGasOverhead) {
      return calculatedGasOverhead;
    }
    return cappedGasOverhead;
  }

  ////////
  // PROXY FUNCTIONS - EXECUTED THROUGH FALLBACK
  ////////

  /**
   * @notice adds a new upkeep
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external override returns (uint256 id) {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice simulated by keepers via eth_call to see if the upkeep needs to be
   * performed. It returns the success status / failure reason along with the perform data payload.
   * @param id identifier of the upkeep to check
   */
  function checkUpkeep(uint256 id)
    external
    override
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice prevent an upkeep from being performed in the future
   * @param id upkeep to be canceled
   */
  function cancelUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice pause an upkeep
   * @param id upkeep to be paused
   */
  function pauseUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice unpause an upkeep
   * @param id upkeep to be resumed
   */
  function unpauseUpkeep(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice update the check data of an upkeep
   * @param id the id of the upkeep whose check data needs to be updated
   * @param newCheckData the new check data
   */
  function updateCheckData(uint256 id, bytes calldata newCheckData) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice adds LINK funding for an upkeep by transferring from the sender's
   * LINK balance
   * @param id upkeep to fund
   * @param amount number of LINK to transfer
   */
  function addFunds(uint256 id, uint96 amount) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice removes funding from a canceled upkeep
   * @param id upkeep to withdraw funds from
   * @param to destination address for sending remaining funds
   */
  function withdrawFunds(uint256 id, address to) external {
    // Executed through logic contract
    // Restricted to nonRentrant in logic contract as this is not callable from a user's performUpkeep
    _fallback();
  }

  /**
   * @notice allows the admin of an upkeep to modify gas limit
   * @param id upkeep to be change the gas limit for
   * @param gasLimit new gas limit for the upkeep
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice allows the admin of an upkeep to modify the offchain config
   * @param id upkeep to be change the gas limit for
   * @param config instructs oracles of offchain config preferences
   */
  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice withdraws a transmitter's payment, callable only by the transmitter's payee
   * @param from transmitter address
   * @param to address to send the payment to
   */
  function withdrawPayment(address from, address to) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice proposes the safe transfer of a transmitter's payee to another address
   * @param transmitter address of the transmitter to transfer payee role
   * @param proposed address to nominate for next payeeship
   */
  function transferPayeeship(address transmitter, address proposed) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice accepts the safe transfer of payee role for a transmitter
   * @param transmitter address to accept the payee role for
   */
  function acceptPayeeship(address transmitter) external {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice proposes the safe transfer of an upkeep's admin role to another address
   * @param id the upkeep id to transfer admin
   * @param proposed address to nominate for the new upkeep admin
   */
  function transferUpkeepAdmin(uint256 id, address proposed) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @notice accepts the safe transfer of admin role for an upkeep
   * @param id the upkeep id
   */
  function acceptUpkeepAdmin(uint256 id) external override {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination)
    external
    override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2)
  {
    // Executed through logic contract
    _fallback();
  }

  /**
   * @inheritdoc MigratableKeeperRegistryInterface
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps)
    external
    override(MigratableKeeperRegistryInterface, MigratableKeeperRegistryInterfaceV2)
  {
    // Executed through logic contract
    _fallback();
  }

  ////////
  // OWNER RESTRICTED FUNCTIONS
  ////////

  /**
   * @notice recovers LINK funds improperly transferred to the registry
   * @dev In principle this function’s execution cost could exceed block
   * gas limit. However, in our anticipated deployment, the number of upkeeps and
   * transmitters will be low enough to avoid this problem.
   */
  function recoverFunds() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice withdraws LINK funds collected through cancellation fees
   */
  function withdrawOwnerFunds() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice update the list of payees corresponding to the transmitters
   * @param payees addresses corresponding to transmitters who are allowed to
   * move payments which have been accrued
   */
  function setPayees(address[] calldata payees) external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice signals to transmitters that they should not perform upkeeps until the
   * contract has been unpaused
   */
  function pause() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice signals to transmitters that they can perform upkeeps once again after
   * having been paused
   */
  function unpause() external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }

  /**
   * @notice sets the peer registry migration permission
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external {
    // Executed through logic contract
    // Restricted to onlyOwner in logic contract
    _fallback();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import "../../../vendor/@eth-optimism/contracts/0.8.6/contracts/L2/predeploys/OVM_GasPriceOracle.sol";
import "../../../automation/ExecutionPrevention.sol";
import {OnchainConfig, State, UpkeepFailureReason} from "../../interfaces/automation/2_1/AutomationRegistryInterface2_1.sol";
import "../../../ConfirmedOwner.sol";
import "../../../interfaces/AggregatorV3Interface.sol";
import "../../../interfaces/LinkTokenInterface.sol";
import "../../../interfaces/automation/KeeperCompatibleInterface.sol";
import "../../../interfaces/automation/UpkeepTranscoderInterface.sol";

/**
 * @notice relevant state of an upkeep which is used in transmit function
 * @member executeGas the gas limit of upkeep execution
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member paused if this upkeep has been paused
 * @member target the contract which needs to be serviced
 * @member amountSpent the amount this upkeep has spent
 * @member balance the balance of this upkeep
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 */
struct Upkeep {
  uint32 executeGas;
  uint32 maxValidBlocknumber;
  bool paused;
  address target;
  // 3 bytes left in 1st EVM word - not written to in transmit
  uint96 amountSpent;
  uint96 balance;
  uint32 lastPerformBlockNumber;
  // 4 bytes left in 2nd EVM word - written in transmit path
}

/**
 * @notice Base Keeper Registry contract, contains shared logic between
 * KeeperRegistry and KeeperRegistryLogic
 */
abstract contract KeeperRegistryBase2_1 is ConfirmedOwner, ExecutionPrevention {
  address internal constant ZERO_ADDRESS = address(0);
  address internal constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 internal constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 internal constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  uint256 internal constant PERFORM_GAS_MIN = 2_300;
  uint256 internal constant CANCELLATION_DELAY = 50;
  uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
  uint256 internal constant PPB_BASE = 1_000_000_000;
  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint96 internal constant LINK_TOTAL_SUPPLY = 1e27;
  // The first byte of the mask can be 0, because we only ever have 31 oracles
  uint256 internal constant ORACLE_MASK = 0x0001010101010101010101010101010101010101010101010101010101010101;
  /**
   * @dev UPKEEP_TRANSCODER_VERSION_BASE is temporary necessity for backwards compatibility with
   * MigratableKeeperRegistryInterfaceV1 - it should be removed in future versions in favor of
   * UPKEEP_VERSION_BASE and MigratableKeeperRegistryInterfaceV2
   */
  UpkeepFormat internal constant UPKEEP_TRANSCODER_VERSION_BASE = UpkeepFormat.V1;
  uint8 internal constant UPKEEP_VERSION_BASE = uint8(UpkeepFormat.V3);
  // L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  uint256 internal constant REGISTRY_GAS_OVERHEAD = 65_000; // Used only in maxPayment estimation, not in actual payment
  uint256 internal constant REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD = 20; // Used only in maxPayment estimation, not in actual payment. Value scales with performData length.
  uint256 internal constant REGISTRY_PER_SIGNER_GAS_OVERHEAD = 7_500; // Used only in maxPayment estimation, not in actual payment. Value scales with f.

  uint256 internal constant ACCOUNTING_FIXED_GAS_OVERHEAD = 26_900; // Used in actual payment. Fixed overhead per tx
  uint256 internal constant ACCOUNTING_PER_SIGNER_GAS_OVERHEAD = 1_100; // Used in actual payment. overhead per signer
  uint256 internal constant ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD = 5_800; // Used in actual payment. overhead per upkeep performed

  OVM_GasPriceOracle internal constant OPTIMISM_ORACLE = OVM_GasPriceOracle(0x420000000000000000000000000000000000000F);
  ArbGasInfo internal constant ARB_NITRO_ORACLE = ArbGasInfo(0x000000000000000000000000000000000000006C);

  LinkTokenInterface internal immutable i_link;
  AggregatorV3Interface internal immutable i_linkNativeFeed;
  AggregatorV3Interface internal immutable i_fastGasFeed;
  PaymentModel internal immutable i_paymentModel;

  // @dev - The storage is gas optimised for one and only function - transmit. All the storage accessed in transmit
  // is stored compactly. Rest of the storage layout is not of much concern as transmit is the only hot path
  // Upkeep storage
  EnumerableSet.UintSet internal s_upkeepIDs;
  mapping(uint256 => Upkeep) internal s_upkeep; // accessed during transmit
  mapping(uint256 => address) internal s_upkeepAdmin;
  mapping(uint256 => address) internal s_proposedAdmin;
  mapping(uint256 => bytes) internal s_checkData;
  // Registry config and state
  mapping(address => Transmitter) internal s_transmitters;
  mapping(address => Signer) internal s_signers;
  address[] internal s_signersList; // s_signersList contains the signing address of each oracle
  address[] internal s_transmittersList; // s_transmittersList contains the transmission address of each oracle
  mapping(address => address) internal s_transmitterPayees; // s_payees contains the mapping from transmitter to payee.
  mapping(address => address) internal s_proposedPayee; // proposed payee for a transmitter
  bytes32 internal s_latestConfigDigest; // Read on transmit path in case of signature verification
  HotVars internal s_hotVars; // Mixture of config and state, used in transmit
  Storage internal s_storage; // Mixture of config and state, not used in transmit
  uint256 internal s_fallbackGasPrice;
  uint256 internal s_fallbackLinkPrice;
  uint256 internal s_expectedLinkBalance; // Used in case of erroneous LINK transfers to contract
  mapping(address => MigrationPermission) internal s_peerRegistryMigrationPermission; // Permissions for migration to and fro
  mapping(uint256 => bytes) internal s_upkeepOffchainConfig; // general configuration preferences

  error ArrayHasNoEntries();
  error CannotCancel();
  error DuplicateEntry();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidPayee();
  error InvalidRecipient();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyPausedUpkeep();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error TargetCheckReverted(bytes reason);
  error TranscoderNotSet();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();
  error ConfigDigestMismatch();
  error IncorrectNumberOfSignatures();
  error OnlyActiveSigners();
  error DuplicateSigners();
  error StaleReport();
  error TooManyOracles();
  error IncorrectNumberOfSigners();
  error IncorrectNumberOfFaultyOracles();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error OnchainConfigNonEmpty();
  error CheckDataExceedsLimit();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error InvalidReport();
  error RegistryPaused();
  error ReentrantCall();
  error UpkeepAlreadyExists();

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  enum PaymentModel {
    DEFAULT,
    ARBITRUM,
    OPTIMISM
  }

  // Config + State storage struct which is on hot transmit path
  struct HotVars {
    uint8 f; // maximum number of faulty oracles
    uint32 paymentPremiumPPB; // premium percentage charged to user over tx cost
    uint32 flatFeeMicroLink; // flat fee charged to user for every perform
    uint24 stalenessSeconds; // Staleness tolerance for feeds
    uint16 gasCeilingMultiplier; // multiplier on top of fast gas feed for upper bound
    bool paused; // pause switch for all upkeeps in the registry
    bool reentrancyGuard; // guard against reentrancy
    uint96 totalPremium; // total historical payment to oracles for premium
    uint32 latestEpoch; // latest epoch for which a report was transmitted
    // 1 EVM word full
  }

  // Config + State storage struct which is not on hot transmit path
  struct Storage {
    uint96 minUpkeepSpend; // Minimum amount an upkeep must spend
    address transcoder; // Address of transcoder contract used in migrations
    // 1 EVM word full
    uint96 ownerLinkBalance; // Balance of owner, accumulates minUpkeepSpend in case it is not spent
    address registrar; // Address of registrar used to register upkeeps
    // 2 EVM word full
    uint32 checkGasLimit; // Gas limit allowed in checkUpkeep
    uint32 maxPerformGas; // Max gas an upkeep can use on this registry
    uint32 nonce; // Nonce for each upkeep created
    uint32 configCount; // incremented each time a new config is posted, The count
    // is incorporated into the config digest to prevent replay attacks.
    uint32 latestConfigBlockNumber; // makes it easier for offchain systems to extract config from logs
    uint32 maxCheckDataSize; // max length of checkData bytes
    uint32 maxPerformDataSize; // max length of performData bytes
    // 4 bytes to 3rd EVM word
  }

  struct Transmitter {
    bool active;
    uint8 index; // Index of oracle in s_signersList/s_transmittersList
    uint96 balance;
    uint96 lastCollected;
  }

  struct Signer {
    bool active;
    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }

  // This struct is used to pack information about the user's check function
  struct PerformDataWrapper {
    uint32 checkBlockNumber; // Block number-1 on which check was simulated
    bytes32 checkBlockhash; // blockhash of checkBlockNumber. Used for reorg protection
    bytes performData; // actual performData that user's check returned
  }

  // Report transmitted by OCR to transmit function
  struct Report {
    uint256 fastGasWei;
    uint256 linkNative;
    uint256[] upkeepIds; // Ids of upkeeps
    PerformDataWrapper[] wrappedPerformDatas; // Contains checkInfo and performData for the corresponding upkeeps
  }

  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event OwnerFundsWithdrawn(uint96 amount);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataUpdated(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint32 checkBlockNumber,
    uint256 gasUsed,
    uint256 gasOverhead,
    uint96 totalPayment
  );
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepUnpaused(uint256 indexed id);
  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event StaleUpkeepReport(uint256 indexed id);
  event ReorgedUpkeepReport(uint256 indexed id);
  event InsufficientFundsUpkeepReport(uint256 indexed id);
  event CancelledUpkeepReport(uint256 indexed id);
  event Paused(address account);
  event Unpaused(address account);

  /**
   * @param paymentModel the payment model of default, Arbitrum, or Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    PaymentModel paymentModel,
    address link,
    address linkNativeFeed,
    address fastGasFeed
  ) ConfirmedOwner(msg.sender) {
    i_paymentModel = paymentModel;
    i_link = LinkTokenInterface(link);
    i_linkNativeFeed = AggregatorV3Interface(linkNativeFeed);
    i_fastGasFeed = AggregatorV3Interface(fastGasFeed);
  }

  ////////
  // GETTERS
  ////////

  function getPaymentModel() external view returns (PaymentModel) {
    return i_paymentModel;
  }

  function getLinkAddress() external view returns (address) {
    return address(i_link);
  }

  function getLinkNativeFeedAddress() external view returns (address) {
    return address(i_linkNativeFeed);
  }

  function getFastGasFeedAddress() external view returns (address) {
    return address(i_fastGasFeed);
  }

  ////////
  // INTERNAL
  ////////

  /**
   * @dev retrieves feed data for fast gas/native and link/native prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData(HotVars memory hotVars) internal view returns (uint256 gasWei, uint256 linkNative) {
    uint32 stalenessSeconds = hotVars.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = i_fastGasFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = i_linkNativeFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      linkNative = s_fallbackLinkPrice;
    } else {
      linkNative = uint256(feedValue);
    }
    return (gasWei, linkNative);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   * @param gasLimit the amount of gas used
   * @param gasOverhead the amount of gas overhead
   * @param fastGasWei the fast gas price
   * @param linkNative the exchange ratio between LINK and Native token
   * @param numBatchedUpkeeps the number of upkeeps in this batch. Used to divide the L1 cost
   * @param isExecution if this is triggered by a perform upkeep function
   */
  function _calculatePaymentAmount(
    HotVars memory hotVars,
    uint256 gasLimit,
    uint256 gasOverhead,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps,
    bool isExecution
  ) internal view returns (uint96, uint96) {
    uint256 gasWei = fastGasWei * hotVars.gasCeilingMultiplier;
    // in case it's actual execution use actual gas price, capped by fastGasWei * gasCeilingMultiplier
    if (isExecution && tx.gasprice < gasWei) {
      gasWei = tx.gasprice;
    }

    uint256 l1CostWei = 0;
    if (i_paymentModel == PaymentModel.OPTIMISM) {
      bytes memory txCallData = new bytes(0);
      if (isExecution) {
        txCallData = bytes.concat(msg.data, L1_FEE_DATA_PADDING);
      } else {
        // @dev fee is 4 per 0 byte, 16 per non-zero byte. Worst case we can have
        // s_storage.maxPerformDataSize non zero-bytes. Instead of setting bytes to non-zero
        // we initialize 'new bytes' of length 4*maxPerformDataSize to cover for zero bytes.
        txCallData = new bytes(4 * s_storage.maxPerformDataSize);
      }
      l1CostWei = OPTIMISM_ORACLE.getL1Fee(txCallData);
    } else if (i_paymentModel == PaymentModel.ARBITRUM) {
      l1CostWei = ARB_NITRO_ORACLE.getCurrentTxL1GasFees();
    }
    // if it's not performing upkeeps, use gas ceiling multiplier to estimate the upper bound
    if (!isExecution) {
      l1CostWei = hotVars.gasCeilingMultiplier * l1CostWei;
    }
    // Divide l1CostWei among all batched upkeeps. Spare change from division is not charged
    l1CostWei = l1CostWei / numBatchedUpkeeps;

    uint256 gasPayment = ((gasWei * (gasLimit + gasOverhead) + l1CostWei) * 1e18) / linkNative;
    uint256 premium = (((gasWei * gasLimit) + l1CostWei) * 1e9 * hotVars.paymentPremiumPPB) /
      linkNative +
      uint256(hotVars.flatFeeMicroLink) *
      1e12;
    // LINK_TOTAL_SUPPLY < UINT96_MAX
    if (gasPayment + premium > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return (uint96(gasPayment), uint96(premium));
  }

  /**
   * @dev generates the max link payment for an upkeep
   */
  function _getMaxLinkPayment(
    HotVars memory hotVars,
    uint32 executeGas,
    uint32 performDataLength,
    uint256 fastGasWei,
    uint256 linkNative,
    bool isExecution // Whether this is an actual perform execution or just a simulation
  ) internal view returns (uint96) {
    uint256 gasOverhead = _getMaxGasOverhead(performDataLength, hotVars.f);
    (uint96 reimbursement, uint96 premium) = _calculatePaymentAmount(
      hotVars,
      executeGas,
      gasOverhead,
      fastGasWei,
      linkNative,
      1, // Consider only 1 upkeep in batch to get maxPayment
      isExecution
    );

    return reimbursement + premium;
  }

  /**
   * @dev returns the max gas overhead that can be charged for an upkeep
   */
  function _getMaxGasOverhead(uint32 performDataLength, uint8 f) internal pure returns (uint256) {
    // performData causes additional overhead in report length and memory operations
    return
      REGISTRY_GAS_OVERHEAD +
      (REGISTRY_PER_SIGNER_GAS_OVERHEAD * (f + 1)) +
      (REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD * performDataLength);
  }

  /**
   * @dev move a transmitter's balance from total pool to withdrawable balance
   */
  function _updateTransmitterBalanceFromPool(
    address transmitterAddress,
    uint96 totalPremium,
    uint96 payeeCount
  ) internal returns (uint96) {
    Transmitter memory transmitter = s_transmitters[transmitterAddress];

    uint96 uncollected = totalPremium - transmitter.lastCollected;
    uint96 due = uncollected / payeeCount;
    transmitter.balance += due;
    transmitter.lastCollected = totalPremium;

    // Transfer spare change to owner
    s_storage.ownerLinkBalance += (uncollected - due * payeeCount);
    s_transmitters[transmitterAddress] = transmitter;

    return transmitter.balance;
  }

  /**
   * @notice replicates Open Zeppelin's ReentrancyGuard but optimized to fit our storage
   */
  modifier nonReentrant() {
    if (s_hotVars.reentrancyGuard) revert ReentrantCall();
    s_hotVars.reentrancyGuard = true;
    _;
    s_hotVars.reentrancyGuard = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import "./KeeperRegistryBase2_1.sol";
import "../../../interfaces/automation/UpkeepTranscoderInterfaceV2.sol";
import "../../../interfaces/automation/MigratableKeeperRegistryInterfaceV2.sol";

/**
 * @notice Logic contract, works in tandem with KeeperRegistry as a proxy
 */
contract KeeperRegistryLogic2_1 is KeeperRegistryBase2_1 {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;

  /**
   * @param paymentModel one of Default, Arbitrum, Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    PaymentModel paymentModel,
    address link,
    address linkNativeFeed,
    address fastGasFeed
  ) KeeperRegistryBase2_1(paymentModel, link, linkNativeFeed, fastGasFeed) {}

  function checkUpkeep(uint256 id)
    external
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    HotVars memory hotVars = s_hotVars;
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_CANCELLED, gasUsed, 0, 0);
    if (upkeep.paused) return (false, bytes(""), UpkeepFailureReason.UPKEEP_PAUSED, gasUsed, 0, 0);

    (fastGasWei, linkNative) = _getFeedData(hotVars);
    uint96 maxLinkPayment = _getMaxLinkPayment(
      hotVars,
      upkeep.executeGas,
      s_storage.maxPerformDataSize,
      fastGasWei,
      linkNative,
      false
    );
    if (upkeep.balance < maxLinkPayment)
      return (false, bytes(""), UpkeepFailureReason.INSUFFICIENT_BALANCE, gasUsed, fastGasWei, linkNative);

    gasUsed = gasleft();
    bytes memory callData = abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[id]);
    (bool success, bytes memory result) = upkeep.target.call{gas: s_storage.checkGasLimit}(callData);
    gasUsed = gasUsed - gasleft();

    if (!success) return (false, bytes(""), UpkeepFailureReason.TARGET_CHECK_REVERTED, gasUsed, fastGasWei, linkNative);

    bytes memory userPerformData;
    (upkeepNeeded, userPerformData) = abi.decode(result, (bool, bytes));
    if (!upkeepNeeded)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_NOT_NEEDED, gasUsed, fastGasWei, linkNative);
    if (userPerformData.length > s_storage.maxPerformDataSize)
      return (false, bytes(""), UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT, gasUsed, fastGasWei, linkNative);

    performData = abi.encode(
      PerformDataWrapper({
        checkBlockNumber: uint32(block.number - 1),
        checkBlockhash: blockhash(block.number - 1),
        performData: userPerformData
      })
    );
    return (true, performData, UpkeepFailureReason.NONE, gasUsed, fastGasWei, linkNative);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawOwnerFunds() external onlyOwner {
    uint96 amount = s_storage.ownerLinkBalance;

    s_expectedLinkBalance = s_expectedLinkBalance - amount;
    s_storage.ownerLinkBalance = 0;

    emit OwnerFundsWithdrawn(amount);
    i_link.transfer(msg.sender, amount);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function recoverFunds() external onlyOwner {
    uint256 total = i_link.balanceOf(address(this));
    i_link.transfer(msg.sender, total - s_expectedLinkBalance);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setPayees(address[] calldata payees) external onlyOwner {
    if (s_transmittersList.length != payees.length) revert ParameterLengthError();
    for (uint256 i = 0; i < s_transmittersList.length; i++) {
      address transmitter = s_transmittersList[i];
      address oldPayee = s_transmitterPayees[transmitter];
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) || (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (newPayee != IGNORE_ADDRESS) {
        s_transmitterPayees[transmitter] = newPayee;
      }
    }
    emit PayeesUpdated(s_transmittersList, payees);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function pause() external onlyOwner {
    s_hotVars.paused = true;

    emit Paused(msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function unpause() external onlyOwner {
    s_hotVars.paused = false;

    emit Unpaused(msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external onlyOwner {
    s_peerRegistryMigrationPermission[peer] = permission;
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id) {
    if (msg.sender != owner() && msg.sender != s_storage.registrar) revert OnlyCallableByOwnerOrRegistrar();

    id = uint256(keccak256(abi.encode(blockhash(block.number - 1), address(this), s_storage.nonce)));
    _createUpkeep(id, target, gasLimit, admin, 0, checkData, false, offchainConfig);
    s_storage.nonce++;
    emit UpkeepRegistered(id, gasLimit, admin);
    return id;
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function cancelUpkeep(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    bool canceled = upkeep.maxValidBlocknumber != UINT32_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && upkeep.maxValidBlocknumber > block.number)) revert CannotCancel();
    if (!isOwner && msg.sender != s_upkeepAdmin[id]) revert OnlyCallableByOwnerOrAdmin();

    uint256 height = block.number;
    if (!isOwner) {
      height = height + CANCELLATION_DELAY;
    }
    s_upkeep[id].maxValidBlocknumber = uint32(height);
    s_upkeepIDs.remove(id);

    // charge the cancellation fee if the minUpkeepSpend is not met
    uint96 minUpkeepSpend = s_storage.minUpkeepSpend;
    uint96 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minUpkeepSpend - amountSpent,0), amountLeft)
    if (upkeep.amountSpent < minUpkeepSpend) {
      cancellationFee = minUpkeepSpend - upkeep.amountSpent;
      if (cancellationFee > upkeep.balance) {
        cancellationFee = upkeep.balance;
      }
    }
    s_upkeep[id].balance = upkeep.balance - cancellationFee;
    s_storage.ownerLinkBalance = s_storage.ownerLinkBalance + cancellationFee;

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function addFunds(uint256 id, uint96 amount) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();

    s_upkeep[id].balance = upkeep.balance + amount;
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    i_link.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawFunds(uint256 id, address to) external nonReentrant {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    Upkeep memory upkeep = s_upkeep[id];
    if (s_upkeepAdmin[id] != msg.sender) revert OnlyCallableByAdmin();
    if (upkeep.maxValidBlocknumber > block.number) revert UpkeepNotCanceled();

    uint96 amountToWithdraw = s_upkeep[id].balance;
    s_expectedLinkBalance = s_expectedLinkBalance - amountToWithdraw;
    s_upkeep[id].balance = 0;
    i_link.transfer(to, amountToWithdraw);
    emit FundsWithdrawn(id, amountToWithdraw, to);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    _requireAdminAndNotCancelled(id);
    s_upkeep[id].executeGas = gasLimit;

    emit UpkeepGasLimitSet(id, gasLimit);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external {
    _requireAdminAndNotCancelled(id);

    s_upkeepOffchainConfig[id] = config;

    emit UpkeepOffchainConfigSet(id, config);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function withdrawPayment(address from, address to) external {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    if (s_transmitterPayees[from] != msg.sender) revert OnlyCallableByPayee();

    uint96 balance = _updateTransmitterBalanceFromPool(from, s_hotVars.totalPremium, uint96(s_transmittersList.length));
    s_transmitters[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance - balance;

    i_link.transfer(to, balance);

    emit PaymentWithdrawn(from, balance, to, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function transferPayeeship(address transmitter, address proposed) external {
    if (s_transmitterPayees[transmitter] != msg.sender) revert OnlyCallableByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedPayee[transmitter] != proposed) {
      s_proposedPayee[transmitter] = proposed;
      emit PayeeshipTransferRequested(transmitter, msg.sender, proposed);
    }
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function acceptPayeeship(address transmitter) external {
    if (s_proposedPayee[transmitter] != msg.sender) revert OnlyCallableByProposedPayee();
    address past = s_transmitterPayees[transmitter];
    s_transmitterPayees[transmitter] = msg.sender;
    s_proposedPayee[transmitter] = ZERO_ADDRESS;

    emit PayeeshipTransferred(transmitter, past, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function transferUpkeepAdmin(uint256 id, address proposed) external {
    _requireAdminAndNotCancelled(id);
    if (proposed == msg.sender) revert ValueNotChanged();
    if (proposed == ZERO_ADDRESS) revert InvalidRecipient();

    if (s_proposedAdmin[id] != proposed) {
      s_proposedAdmin[id] = proposed;
      emit UpkeepAdminTransferRequested(id, msg.sender, proposed);
    }
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function acceptUpkeepAdmin(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    if (s_proposedAdmin[id] != msg.sender) revert OnlyCallableByProposedAdmin();
    address past = s_upkeepAdmin[id];
    s_upkeepAdmin[id] = msg.sender;
    s_proposedAdmin[id] = ZERO_ADDRESS;

    emit UpkeepAdminTransferred(id, past, msg.sender);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function pauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.paused) revert OnlyUnpausedUpkeep();
    s_upkeep[id].paused = true;
    s_upkeepIDs.remove(id);
    emit UpkeepPaused(id);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function unpauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (!upkeep.paused) revert OnlyPausedUpkeep();
    s_upkeep[id].paused = false;
    s_upkeepIDs.add(id);
    emit UpkeepUnpaused(id);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function updateCheckData(uint256 id, bytes calldata newCheckData) external {
    _requireAdminAndNotCancelled(id);
    if (newCheckData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    s_checkData[id] = newCheckData;
    emit UpkeepCheckDataUpdated(id, newCheckData);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination) external {
    if (
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.OUTGOING &&
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    if (s_storage.transcoder == ZERO_ADDRESS) revert TranscoderNotSet();
    if (ids.length == 0) revert ArrayHasNoEntries();
    uint256 id;
    Upkeep memory upkeep;
    uint256 totalBalanceRemaining;
    bytes[] memory checkDatas = new bytes[](ids.length);
    address[] memory admins = new address[](ids.length);
    Upkeep[] memory upkeeps = new Upkeep[](ids.length);
    bytes[] memory offchainConfigs = new bytes[](ids.length);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      id = ids[idx];
      upkeep = s_upkeep[id];
      _requireAdminAndNotCancelled(id);
      upkeeps[idx] = upkeep;
      checkDatas[idx] = s_checkData[id];
      admins[idx] = s_upkeepAdmin[id];
      offchainConfigs[idx] = s_upkeepOffchainConfig[id];
      totalBalanceRemaining = totalBalanceRemaining + upkeep.balance;
      delete s_upkeep[id];
      delete s_checkData[id];
      delete s_upkeepOffchainConfig[id];
      // nullify existing proposed admin change if an upkeep is being migrated
      delete s_proposedAdmin[id];
      s_upkeepIDs.remove(id);
      emit UpkeepMigrated(id, upkeep.balance, destination);
    }
    s_expectedLinkBalance = s_expectedLinkBalance - totalBalanceRemaining;
    bytes memory encodedUpkeeps = abi.encode(ids, upkeeps, checkDatas, admins, offchainConfigs);
    MigratableKeeperRegistryInterfaceV2(destination).receiveUpkeeps(
      UpkeepTranscoderInterfaceV2(s_storage.transcoder).transcodeUpkeeps(
        UPKEEP_VERSION_BASE,
        MigratableKeeperRegistryInterfaceV2(destination).upkeepVersion(),
        encodedUpkeeps
      )
    );
    i_link.transfer(destination, totalBalanceRemaining);
  }

  /**
   * @dev Called through KeeperRegistry main contract
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external {
    if (
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.INCOMING &&
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    (uint256[] memory ids, Upkeep[] memory upkeeps, bytes[] memory checkDatas, address[] memory upkeepAdmins, bytes[] memory offchainConfigs) = abi
      .decode(encodedUpkeeps, (uint256[], Upkeep[], bytes[], address[], bytes[]));
    for (uint256 idx = 0; idx < ids.length; idx++) {
      _createUpkeep(
        ids[idx],
        upkeeps[idx].target,
        upkeeps[idx].executeGas,
        upkeepAdmins[idx],
        upkeeps[idx].balance,
        checkDatas[idx],
        upkeeps[idx].paused,
        offchainConfigs[idx]
      );
      emit UpkeepReceived(ids[idx], upkeeps[idx].balance, msg.sender);
    }
  }

  /**
   * @notice creates a new upkeep with the given fields
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param paused if this upkeep is paused
   * @param offchainConfig the upkeep's offchain config
   */
  function _createUpkeep(
    uint256 id,
    address target,
    uint32 gasLimit,
    address admin,
    uint96 balance,
    bytes memory checkData,
    bool paused,
    bytes memory offchainConfig
  ) internal {
    if (s_hotVars.paused) revert RegistryPaused();
    if (!target.isContract()) revert NotAContract();
    if (checkData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    if (s_upkeep[id].target != address(0)) revert UpkeepAlreadyExists();
    s_upkeep[id] = Upkeep({
      target: target,
      executeGas: gasLimit,
      balance: balance,
      maxValidBlocknumber: UINT32_MAX,
      lastPerformBlockNumber: 0,
      amountSpent: 0,
      paused: paused
    });
    s_upkeepAdmin[id] = admin;
    s_expectedLinkBalance = s_expectedLinkBalance + balance;
    s_checkData[id] = checkData;
    s_upkeepOffchainConfig[id] = offchainConfig;
    s_upkeepIDs.add(id);
  }

  /**
   * @dev ensures the upkeep is not cancelled and the caller is the upkeep admin
   */
  function _requireAdminAndNotCancelled(uint256 upkeepId) internal view {
    if (msg.sender != s_upkeepAdmin[upkeepId]) revert OnlyCallableByAdmin();
    if (s_upkeep[upkeepId].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../../interfaces/automation/UpkeepTranscoderInterface.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import {Upkeep as UpkeepV1} from "../../automation/1_2/KeeperRegistry1_2.sol";
import {Upkeep as UpkeepV2} from "../../automation/1_3/KeeperRegistryBase1_3.sol";
import {Upkeep as UpkeepV3} from "../../automation/2_0/KeeperRegistryBase2_0.sol";
import "../../automation/UpkeepFormat.sol";

/**
 * @notice UpkeepTranscoder 3_0 allows converting upkeep data from previous keeper registry versions 1.2 and 1.3 to
 * registry 2.0
 */
contract UpkeepTranscoder3_0 is UpkeepTranscoderInterface, TypeAndVersionInterface {
  error InvalidTranscoding();

  /**
   * @notice versions:
   * - UpkeepTranscoder 3.0.0: version 3.0.0 works with registry 2.0; adds temporary workaround for UpkeepFormat enum bug
   */
  string public constant override typeAndVersion = "UpkeepTranscoder 3.0.0";
  uint32 internal constant UINT32_MAX = type(uint32).max;

  /**
   * @notice transcodeUpkeeps transforms upkeep data from the format expected by
   * one registry to the format expected by another. It future-proofs migrations
   * by allowing keepers team to customize migration paths and set sensible defaults
   * when new fields are added
   * @param fromVersion struct version the upkeep is migrating from
   * @param encodedUpkeeps encoded upkeep data
   * @dev this transcoder should ONLY be use for V1/V2 --> V3 migrations
   * @dev this transcoder **ignores** the toVersion param, as it assumes all migrations are
   * for the V3 version. Therefore, it is the responsibility of the deployer of this contract
   * to ensure it is not used in any other migration paths.
   */
  function transcodeUpkeeps(
    UpkeepFormat fromVersion,
    UpkeepFormat,
    bytes calldata encodedUpkeeps
  ) external view override returns (bytes memory) {
    // this transcoder only handles upkeep V1/V2 to V3, all other formats are invalid.
    if (fromVersion == UpkeepFormat.V1) {
      (uint256[] memory ids, UpkeepV1[] memory upkeepsV1, bytes[] memory checkDatas) = abi.decode(
        encodedUpkeeps,
        (uint256[], UpkeepV1[], bytes[])
      );

      if (ids.length != upkeepsV1.length || ids.length != checkDatas.length) {
        revert InvalidTranscoding();
      }

      address[] memory admins = new address[](ids.length);
      UpkeepV3[] memory newUpkeeps = new UpkeepV3[](ids.length);
      UpkeepV1 memory upkeepV1;
      for (uint256 idx = 0; idx < ids.length; idx++) {
        upkeepV1 = upkeepsV1[idx];
        newUpkeeps[idx] = UpkeepV3({
          executeGas: upkeepV1.executeGas,
          maxValidBlocknumber: UINT32_MAX, // maxValidBlocknumber is uint64 in V1, hence a new default value is provided
          paused: false, // migrated upkeeps are not paused by default
          target: upkeepV1.target,
          amountSpent: upkeepV1.amountSpent,
          balance: upkeepV1.balance,
          lastPerformBlockNumber: 0
        });
        admins[idx] = upkeepV1.admin;
      }
      return abi.encode(ids, newUpkeeps, checkDatas, admins);
    }

    if (fromVersion == UpkeepFormat.V2) {
      (uint256[] memory ids, UpkeepV2[] memory upkeepsV2, bytes[] memory checkDatas) = abi.decode(
        encodedUpkeeps,
        (uint256[], UpkeepV2[], bytes[])
      );

      if (ids.length != upkeepsV2.length || ids.length != checkDatas.length) {
        revert InvalidTranscoding();
      }

      address[] memory admins = new address[](ids.length);
      UpkeepV3[] memory newUpkeeps = new UpkeepV3[](ids.length);
      UpkeepV2 memory upkeepV2;
      for (uint256 idx = 0; idx < ids.length; idx++) {
        upkeepV2 = upkeepsV2[idx];
        newUpkeeps[idx] = UpkeepV3({
          executeGas: upkeepV2.executeGas,
          maxValidBlocknumber: upkeepV2.maxValidBlocknumber,
          paused: upkeepV2.paused,
          target: upkeepV2.target,
          amountSpent: upkeepV2.amountSpent,
          balance: upkeepV2.balance,
          lastPerformBlockNumber: 0
        });
        admins[idx] = upkeepV2.admin;
      }
      return abi.encode(ids, newUpkeeps, checkDatas, admins);
    }

    revert InvalidTranscoding();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/TypeAndVersionInterface.sol";
import "./../ConfirmedOwner.sol";

// defines some interfaces for type safety and reduces encoding/decoding
// does not use the full interfaces intentionally because the requester only uses a fraction of them
interface IAggregatorProxy {
  function aggregator() external view returns (address);
}

interface IOffchainAggregator {
  function requestNewRound() external returns (uint80);
}

/**
 * @notice The heartbeat requester will maintain a mapping from allowed callers to corresponding proxies. When requested
 *         by eligible caller, it will call a proxy for an aggregator address and request a new round. The aggregator
 *         is gated by permissions and this requester address needs to be whitelisted.
 */
contract HeartbeatRequester is TypeAndVersionInterface, ConfirmedOwner {
  event HeartbeatPermitted(address indexed permittedCaller, address newProxy, address oldProxy);
  event HeartbeatRemoved(address indexed permittedCaller, address removedProxy);

  error HeartbeatNotPermitted();

  mapping(address => IAggregatorProxy) internal s_heartbeatList;

  /**
   * @notice versions:
   * - HeartbeatRequester 1.0.0: The requester fetches the latest aggregator address from proxy, and request a new round
   *                             using the aggregator address.
   */
  string public constant override typeAndVersion = "HeartbeatRequester 1.0.0";

  constructor() ConfirmedOwner(msg.sender) {}

  /**
   * @notice adds a permitted caller and proxy combination.
   * @param permittedCaller the permitted caller
   * @param proxy the proxy corresponding to this caller
   */
  function permitHeartbeat(address permittedCaller, IAggregatorProxy proxy) external onlyOwner {
    address oldProxy = address(s_heartbeatList[permittedCaller]);
    s_heartbeatList[permittedCaller] = proxy;
    emit HeartbeatPermitted(permittedCaller, address(proxy), oldProxy);
  }

  /**
   * @notice removes a permitted caller and proxy combination.
   * @param permittedCaller the permitted caller
   */
  function removeHeartbeat(address permittedCaller) external onlyOwner {
    address removedProxy = address(s_heartbeatList[permittedCaller]);
    delete s_heartbeatList[permittedCaller];
    emit HeartbeatRemoved(permittedCaller, removedProxy);
  }

  /**
   * @notice fetches aggregator address from proxy and requests a new round.
   * @param proxy the proxy address
   */
  function getAggregatorAndRequestHeartbeat(address proxy) external {
    IAggregatorProxy proxyInterface = s_heartbeatList[msg.sender];
    if (address(proxyInterface) != proxy) revert HeartbeatNotPermitted();

    IOffchainAggregator aggregator = IOffchainAggregator(proxyInterface.aggregator());
    aggregator.requestNewRound();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(address query)
    external
    view
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    );

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../ConfirmedOwner.sol";
import "../interfaces/automation/KeeperCompatibleInterface.sol";
import "../interfaces/VRFCoordinatorV2Interface.sol";
import "../interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title The VRFSubscriptionBalanceMonitor contract.
 * @notice A keeper-compatible contract that monitors and funds VRF subscriptions.
 */
contract VRFSubscriptionBalanceMonitor is ConfirmedOwner, Pausable, KeeperCompatibleInterface {
  VRFCoordinatorV2Interface public COORDINATOR;
  LinkTokenInterface public LINKTOKEN;

  uint256 private constant MIN_GAS_FOR_TRANSFER = 55_000;

  event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
  event FundsWithdrawn(uint256 amountWithdrawn, address payee);
  event TopUpSucceeded(uint64 indexed subscriptionId);
  event TopUpFailed(uint64 indexed subscriptionId);
  event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
  event VRFCoordinatorV2AddressUpdated(address oldAddress, address newAddress);
  event LinkTokenAddressUpdated(address oldAddress, address newAddress);
  event MinWaitPeriodUpdated(uint256 oldMinWaitPeriod, uint256 newMinWaitPeriod);
  event OutOfGas(uint256 lastId);

  error InvalidWatchList();
  error OnlyKeeperRegistry();
  error DuplicateSubcriptionId(uint64 duplicate);

  struct Target {
    bool isActive;
    uint96 minBalanceJuels;
    uint96 topUpAmountJuels;
    uint56 lastTopUpTimestamp;
  }

  address public s_keeperRegistryAddress; // the address of the keeper registry
  uint256 public s_minWaitPeriodSeconds; // minimum time to wait between top-ups
  uint64[] public s_watchList; // the watchlist on which subscriptions are stored
  mapping(uint64 => Target) internal s_targets;

  /**
   * @param linkTokenAddress the Link token address
   * @param coordinatorAddress the address of the vrf coordinator contract
   * @param keeperRegistryAddress the address of the keeper registry contract
   * @param minWaitPeriodSeconds the minimum wait period for addresses between funding
   */
  constructor(
    address linkTokenAddress,
    address coordinatorAddress,
    address keeperRegistryAddress,
    uint256 minWaitPeriodSeconds
  ) ConfirmedOwner(msg.sender) {
    setLinkTokenAddress(linkTokenAddress);
    setVRFCoordinatorV2Address(coordinatorAddress);
    setKeeperRegistryAddress(keeperRegistryAddress);
    setMinWaitPeriodSeconds(minWaitPeriodSeconds);
  }

  /**
   * @notice Sets the list of subscriptions to watch and their funding parameters.
   * @param subscriptionIds the list of subscription ids to watch
   * @param minBalancesJuels the minimum balances for each subscription
   * @param topUpAmountsJuels the amount to top up each subscription
   */
  function setWatchList(
    uint64[] calldata subscriptionIds,
    uint96[] calldata minBalancesJuels,
    uint96[] calldata topUpAmountsJuels
  ) external onlyOwner {
    if (subscriptionIds.length != minBalancesJuels.length || subscriptionIds.length != topUpAmountsJuels.length) {
      revert InvalidWatchList();
    }
    uint64[] memory oldWatchList = s_watchList;
    for (uint256 idx = 0; idx < oldWatchList.length; idx++) {
      s_targets[oldWatchList[idx]].isActive = false;
    }
    for (uint256 idx = 0; idx < subscriptionIds.length; idx++) {
      if (s_targets[subscriptionIds[idx]].isActive) {
        revert DuplicateSubcriptionId(subscriptionIds[idx]);
      }
      if (subscriptionIds[idx] == 0) {
        revert InvalidWatchList();
      }
      if (topUpAmountsJuels[idx] <= minBalancesJuels[idx]) {
        revert InvalidWatchList();
      }
      s_targets[subscriptionIds[idx]] = Target({
        isActive: true,
        minBalanceJuels: minBalancesJuels[idx],
        topUpAmountJuels: topUpAmountsJuels[idx],
        lastTopUpTimestamp: 0
      });
    }
    s_watchList = subscriptionIds;
  }

  /**
   * @notice Gets a list of subscriptions that are underfunded.
   * @return list of subscriptions that are underfunded
   */
  function getUnderfundedSubscriptions() public view returns (uint64[] memory) {
    uint64[] memory watchList = s_watchList;
    uint64[] memory needsFunding = new uint64[](watchList.length);
    uint256 count = 0;
    uint256 minWaitPeriod = s_minWaitPeriodSeconds;
    uint256 contractBalance = LINKTOKEN.balanceOf(address(this));
    Target memory target;
    for (uint256 idx = 0; idx < watchList.length; idx++) {
      target = s_targets[watchList[idx]];
      (uint96 subscriptionBalance, , , ) = COORDINATOR.getSubscription(watchList[idx]);
      if (
        target.lastTopUpTimestamp + minWaitPeriod <= block.timestamp &&
        contractBalance >= target.topUpAmountJuels &&
        subscriptionBalance < target.minBalanceJuels
      ) {
        needsFunding[count] = watchList[idx];
        count++;
        contractBalance -= target.topUpAmountJuels;
      }
    }
    if (count < watchList.length) {
      assembly {
        mstore(needsFunding, count)
      }
    }
    return needsFunding;
  }

  /**
   * @notice Send funds to the subscriptions provided.
   * @param needsFunding the list of subscriptions to fund
   */
  function topUp(uint64[] memory needsFunding) public whenNotPaused {
    uint256 minWaitPeriodSeconds = s_minWaitPeriodSeconds;
    uint256 contractBalance = LINKTOKEN.balanceOf(address(this));
    Target memory target;
    for (uint256 idx = 0; idx < needsFunding.length; idx++) {
      target = s_targets[needsFunding[idx]];
      (uint96 subscriptionBalance, , , ) = COORDINATOR.getSubscription(needsFunding[idx]);
      if (
        target.isActive &&
        target.lastTopUpTimestamp + minWaitPeriodSeconds <= block.timestamp &&
        subscriptionBalance < target.minBalanceJuels &&
        contractBalance >= target.topUpAmountJuels
      ) {
        bool success = LINKTOKEN.transferAndCall(
          address(COORDINATOR),
          target.topUpAmountJuels,
          abi.encode(needsFunding[idx])
        );
        if (success) {
          s_targets[needsFunding[idx]].lastTopUpTimestamp = uint56(block.timestamp);
          contractBalance -= target.topUpAmountJuels;
          emit TopUpSucceeded(needsFunding[idx]);
        } else {
          emit TopUpFailed(needsFunding[idx]);
        }
      }
      if (gasleft() < MIN_GAS_FOR_TRANSFER) {
        emit OutOfGas(idx);
        return;
      }
    }
  }

  /**
   * @notice Gets list of subscription ids that are underfunded and returns a keeper-compatible payload.
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of subscription ids that need funds
   */
  function checkUpkeep(bytes calldata)
    external
    view
    override
    whenNotPaused
    returns (bool upkeepNeeded, bytes memory performData)
  {
    uint64[] memory needsFunding = getUnderfundedSubscriptions();
    upkeepNeeded = needsFunding.length > 0;
    performData = abi.encode(needsFunding);
    return (upkeepNeeded, performData);
  }

  /**
   * @notice Called by the keeper to send funds to underfunded addresses.
   * @param performData the abi encoded list of addresses to fund
   */
  function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
    uint64[] memory needsFunding = abi.decode(performData, (uint64[]));
    topUp(needsFunding);
  }

  /**
   * @notice Withdraws the contract balance in LINK.
   * @param amount the amount of LINK (in juels) to withdraw
   * @param payee the address to pay
   */
  function withdraw(uint256 amount, address payable payee) external onlyOwner {
    require(payee != address(0));
    emit FundsWithdrawn(amount, payee);
    LINKTOKEN.transfer(payee, amount);
  }

  /**
   * @notice Sets the LINK token address.
   */
  function setLinkTokenAddress(address linkTokenAddress) public onlyOwner {
    require(linkTokenAddress != address(0));
    emit LinkTokenAddressUpdated(address(LINKTOKEN), linkTokenAddress);
    LINKTOKEN = LinkTokenInterface(linkTokenAddress);
  }

  /**
   * @notice Sets the VRF coordinator address.
   */
  function setVRFCoordinatorV2Address(address coordinatorAddress) public onlyOwner {
    require(coordinatorAddress != address(0));
    emit VRFCoordinatorV2AddressUpdated(address(COORDINATOR), coordinatorAddress);
    COORDINATOR = VRFCoordinatorV2Interface(coordinatorAddress);
  }

  /**
   * @notice Sets the keeper registry address.
   */
  function setKeeperRegistryAddress(address keeperRegistryAddress) public onlyOwner {
    require(keeperRegistryAddress != address(0));
    emit KeeperRegistryAddressUpdated(s_keeperRegistryAddress, keeperRegistryAddress);
    s_keeperRegistryAddress = keeperRegistryAddress;
  }

  /**
   * @notice Sets the minimum wait period (in seconds) for subscription ids between funding.
   */
  function setMinWaitPeriodSeconds(uint256 period) public onlyOwner {
    emit MinWaitPeriodUpdated(s_minWaitPeriodSeconds, period);
    s_minWaitPeriodSeconds = period;
  }

  /**
   * @notice Gets configuration information for a subscription on the watchlist.
   */
  function getSubscriptionInfo(uint64 subscriptionId)
    external
    view
    returns (
      bool isActive,
      uint96 minBalanceJuels,
      uint96 topUpAmountJuels,
      uint56 lastTopUpTimestamp
    )
  {
    Target memory target = s_targets[subscriptionId];
    return (target.isActive, target.minBalanceJuels, target.topUpAmountJuels, target.lastTopUpTimestamp);
  }

  /**
   * @notice Gets the list of subscription ids being watched.
   */
  function getWatchList() external view returns (uint64[] memory) {
    return s_watchList;
  }

  /**
   * @notice Pause the contract, which prevents executing performUpkeep.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the contract.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  modifier onlyKeeperRegistry() {
    if (msg.sender != s_keeperRegistryAddress) {
      revert OnlyKeeperRegistry();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationRegistryInterface1_2 directly.
 */
pragma solidity ^0.8.0;
import {Config, State} from "./AutomationRegistryInterface1_2.sol";
import {AutomationRegistryBaseInterface as KeeperRegistryBaseInterface} from "./AutomationRegistryInterface1_2.sol";
import {AutomationRegistryInterface as KeeperRegistryInterface} from "./AutomationRegistryInterface1_2.sol";
import {AutomationRegistryExecutableInterface as KeeperRegistryExecutableInterface} from "./AutomationRegistryInterface1_2.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

/**
 * @notice relevant state of an upkeep
 * @member balance the balance of this upkeep
 * @member lastKeeper the keeper which last performs the upkeep
 * @member executeGas the gas limit of upkeep execution
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member target the contract which needs to be serviced
 * @member amountSpent the amount this upkeep has spent
 * @member admin the upkeep admin
 * @member paused if this upkeep has been paused
 */
struct Upkeep {
  uint96 balance;
  address lastKeeper; // 1 full evm word
  uint96 amountSpent;
  address admin; // 2 full evm words
  uint32 executeGas;
  uint32 maxValidBlocknumber;
  address target;
  bool paused; // 24 bits to 3 full evm words
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent,
      bool paused
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(address query)
    external
    view
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    );

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../automation/UpkeepFormat.sol";

interface MigratableKeeperRegistryInterface {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepTranscoderVersion() external returns (UpkeepFormat version);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../automation/UpkeepFormat.sol";

interface MigratableKeeperRegistryInterfaceV2 {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepVersion() external returns (uint8 version);
}

// SPDX-License-Identifier: MIT

import "../../automation/UpkeepFormat.sol";

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterface {
  function transcodeUpkeeps(
    UpkeepFormat fromVersion,
    UpkeepFormat toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterfaceV2 {
  function transcodeUpkeeps(
    uint8 fromVersion,
    uint8 toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC677ReceiverInterface {
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

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
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

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

pragma solidity 0.8.6;

import {Cron as CronInternal, Spec} from "../internal/Cron.sol";

/**
 * @title The Cron library
 * @notice A utility contract for encoding/decoding cron strings (ex: 0 0 * * *) into an
 * abstraction called a Spec. The library also includes a spec function, nextTick(), which
 * determines the next time a cron job should fire based on the current block timestamp.
 * @dev this is the external version of the library, which relies on the internal library
 * by the same name.
 */
library Cron {
  using CronInternal for Spec;
  using CronInternal for string;

  /**
   * @notice nextTick calculates the next datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function nextTick(Spec calldata spec) public view returns (uint256) {
    return spec.nextTick();
  }

  /**
   * @notice lastTick calculates the previous datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function lastTick(Spec calldata spec) public view returns (uint256) {
    return spec.lastTick();
  }

  /**
   * @notice matches evaluates whether or not a spec "ticks" at a given timestamp
   * @param spec the spec to evaluate
   * @param timestamp the timestamp to compare against
   * @return true / false if they match
   */
  function matches(Spec calldata spec, uint256 timestamp) public view returns (bool) {
    return spec.matches(timestamp);
  }

  /**
   * @notice toSpec converts a cron string to a spec struct. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the spec struct
   */
  function toSpec(string calldata cronString) public pure returns (Spec memory) {
    return cronString.toSpec();
  }

  /**
   * @notice toEncodedSpec converts a cron string to an abi-encoded spec. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the abi-encoded spec
   */
  function toEncodedSpec(string calldata cronString) public pure returns (bytes memory) {
    return cronString.toEncodedSpec();
  }

  /**
   * @notice toCronString converts a cron spec to a human-readable cron string. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param spec the cron spec
   * @return the corresponding cron string
   */
  function toCronString(Spec calldata spec) public pure returns (string memory) {
    return spec.toCronString();
  }
}

// SPDX-License-Identifier: MIT

/*
  The Cron contract serves two primary functions:
    * parsing cron-formatted strings like "0 0 * * *" into
      structs called "Specs"
    * computing the "next tick" of a cron spec

  Because manipulating strings is gas-expensive in solidity,
  the intended use of this contract is for users to first convert
  their cron strings to encoded Spec structs via toEncodedSpec().
  Then, the user stores the Spec on chain. Finally, users use the nextTick(),
  function to determine the datetime of the next cron job run.

  Cron jobs are interpreted according to this format:

  ┌───────────── minute (0 - 59)
  │ ┌───────────── hour (0 - 23)
  │ │ ┌───────────── day of the month (1 - 31)
  │ │ │ ┌───────────── month (1 - 12)
  │ │ │ │ ┌───────────── day of the week (0 - 6) (Monday to Sunday)
  │ │ │ │ │
  │ │ │ │ │
  │ │ │ │ │
  * * * * *

  Special limitations:
    * there is no year field
    * no special characters: ? L W #
    * lists can have a max length of 26
    * no words like JAN / FEB or MON / TUES
*/

pragma solidity 0.8.6;

import "../../vendor/Strings.sol";
import "../../vendor/DateTime.sol";

// The fields of a cron spec, by name
string constant MINUTE = "minute";
string constant HOUR = "hour";
string constant DAY = "day";
string constant MONTH = "month";
string constant DAY_OF_WEEK = "day of week";

error UnknownFieldType();
error InvalidSpec(string reason);
error InvalidField(string field, string reason);
error ListTooLarge();

// Set of enums representing a cron field type
enum FieldType {
  WILD,
  EXACT,
  INTERVAL,
  RANGE,
  LIST
}

// A spec represents a cron job by decomposing it into 5 fields
struct Spec {
  Field minute;
  Field hour;
  Field day;
  Field month;
  Field dayOfWeek;
}

// A field represents a single element in a cron spec. There are 5 types
// of fields (see above). Not all properties of this struct are present at once.
struct Field {
  FieldType fieldType;
  uint8 singleValue;
  uint8 interval;
  uint8 rangeStart;
  uint8 rangeEnd;
  uint8 listLength;
  uint8[26] list;
}

/**
 * @title The Cron library
 * @notice A utility contract for encoding/decoding cron strings (ex: 0 0 * * *) into an
 * abstraction called a Spec. The library also includes a spec function, nextTick(), which
 * determines the next time a cron job should fire based on the current block timestamp.
 */
library Cron {
  using strings for *;

  /**
   * @notice nextTick calculates the next datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   * @dev this is the internal version of the library. There is also an external version.
   */
  function nextTick(Spec memory spec) internal view returns (uint256) {
    uint16 year = DateTime.getYear(block.timestamp);
    uint8 month = DateTime.getMonth(block.timestamp);
    uint8 day = DateTime.getDay(block.timestamp);
    uint8 hour = DateTime.getHour(block.timestamp);
    uint8 minute = DateTime.getMinute(block.timestamp);
    uint8 dayOfWeek;
    for (; true; year++) {
      for (; month <= 12; month++) {
        if (!matches(spec.month, month)) {
          day = 1;
          hour = 0;
          minute = 0;
          continue;
        }
        uint8 maxDay = DateTime.getDaysInMonth(month, year);
        for (; day <= maxDay; day++) {
          if (!matches(spec.day, day)) {
            hour = 0;
            minute = 0;
            continue;
          }
          dayOfWeek = DateTime.getWeekday(DateTime.toTimestamp(year, month, day));
          if (!matches(spec.dayOfWeek, dayOfWeek)) {
            hour = 0;
            minute = 0;
            continue;
          }
          for (; hour < 24; hour++) {
            if (!matches(spec.hour, hour)) {
              minute = 0;
              continue;
            }
            for (; minute < 60; minute++) {
              if (!matches(spec.minute, minute)) {
                continue;
              }
              return DateTime.toTimestamp(year, month, day, hour, minute);
            }
            minute = 0;
          }
          hour = 0;
        }
        day = 1;
      }
      month = 1;
    }
  }

  /**
   * @notice lastTick calculates the previous datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function lastTick(Spec memory spec) internal view returns (uint256) {
    uint16 year = DateTime.getYear(block.timestamp);
    uint8 month = DateTime.getMonth(block.timestamp);
    uint8 day = DateTime.getDay(block.timestamp);
    uint8 hour = DateTime.getHour(block.timestamp);
    uint8 minute = DateTime.getMinute(block.timestamp);
    uint8 dayOfWeek;
    bool resetDay;
    for (; true; year--) {
      for (; month > 0; month--) {
        if (!matches(spec.month, month)) {
          resetDay = true;
          hour = 23;
          minute = 59;
          continue;
        }
        if (resetDay) {
          day = DateTime.getDaysInMonth(month, year);
        }
        for (; day > 0; day--) {
          if (!matches(spec.day, day)) {
            hour = 23;
            minute = 59;
            continue;
          }
          dayOfWeek = DateTime.getWeekday(DateTime.toTimestamp(year, month, day));
          if (!matches(spec.dayOfWeek, dayOfWeek)) {
            hour = 23;
            minute = 59;
            continue;
          }
          for (; hour >= 0; hour--) {
            if (!matches(spec.hour, hour)) {
              minute = 59;
              if (hour == 0) {
                break;
              }
              continue;
            }
            for (; minute >= 0; minute--) {
              if (!matches(spec.minute, minute)) {
                if (minute == 0) {
                  break;
                }
                continue;
              }
              return DateTime.toTimestamp(year, month, day, hour, minute);
            }
            minute = 59;
            if (hour == 0) {
              break;
            }
          }
          hour = 23;
        }
        resetDay = true;
      }
      month = 12;
    }
  }

  /**
   * @notice matches evaluates whether or not a spec "ticks" at a given timestamp
   * @param spec the spec to evaluate
   * @param timestamp the timestamp to compare against
   * @return true / false if they match
   */
  function matches(Spec memory spec, uint256 timestamp) internal view returns (bool) {
    DateTime._DateTime memory dt = DateTime.parseTimestamp(timestamp);
    return
      matches(spec.month, dt.month) &&
      matches(spec.day, dt.day) &&
      matches(spec.hour, dt.hour) &&
      matches(spec.minute, dt.minute);
  }

  /**
   * @notice toSpec converts a cron string to a spec struct. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the spec struct
   */
  function toSpec(string memory cronString) internal pure returns (Spec memory) {
    strings.slice memory space = strings.toSlice(" ");
    strings.slice memory cronSlice = strings.toSlice(cronString);
    if (cronSlice.count(space) != 4) {
      revert InvalidSpec("4 spaces required");
    }
    strings.slice memory minuteSlice = cronSlice.split(space);
    strings.slice memory hourSlice = cronSlice.split(space);
    strings.slice memory daySlice = cronSlice.split(space);
    strings.slice memory monthSlice = cronSlice.split(space);
    // DEV: dayOfWeekSlice = cronSlice
    // The cronSlice now contains the last section of the cron job,
    // which corresponds to the day of week
    if (
      minuteSlice.len() == 0 ||
      hourSlice.len() == 0 ||
      daySlice.len() == 0 ||
      monthSlice.len() == 0 ||
      cronSlice.len() == 0
    ) {
      revert InvalidSpec("some fields missing");
    }
    return
      validate(
        Spec({
          minute: sliceToField(minuteSlice),
          hour: sliceToField(hourSlice),
          day: sliceToField(daySlice),
          month: sliceToField(monthSlice),
          dayOfWeek: sliceToField(cronSlice)
        })
      );
  }

  /**
   * @notice toEncodedSpec converts a cron string to an abi-encoded spec. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the abi-encoded spec
   */
  function toEncodedSpec(string memory cronString) internal pure returns (bytes memory) {
    return abi.encode(toSpec(cronString));
  }

  /**
   * @notice toCronString converts a cron spec to a human-readable cron string. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param spec the cron spec
   * @return the corresponding cron string
   */
  function toCronString(Spec memory spec) internal pure returns (string memory) {
    return
      string(
        bytes.concat(
          fieldToBstring(spec.minute),
          " ",
          fieldToBstring(spec.hour),
          " ",
          fieldToBstring(spec.day),
          " ",
          fieldToBstring(spec.month),
          " ",
          fieldToBstring(spec.dayOfWeek)
        )
      );
  }

  /**
   * @notice matches evaluates if a values matches a field.
   * ex: 3 matches *, 3 matches 0-5, 3 does not match 0,2,4
   * @param field the field struct to match against
   * @param value the value of a field
   * @return true / false if they match
   */
  function matches(Field memory field, uint8 value) private pure returns (bool) {
    if (field.fieldType == FieldType.WILD) {
      return true;
    } else if (field.fieldType == FieldType.INTERVAL) {
      return value % field.interval == 0;
    } else if (field.fieldType == FieldType.EXACT) {
      return value == field.singleValue;
    } else if (field.fieldType == FieldType.RANGE) {
      return value >= field.rangeStart && value <= field.rangeEnd;
    } else if (field.fieldType == FieldType.LIST) {
      for (uint256 idx = 0; idx < field.listLength; idx++) {
        if (value == field.list[idx]) {
          return true;
        }
      }
      return false;
    }
    revert UnknownFieldType();
  }

  // VALIDATIONS

  /**
   * @notice validate validates a spec, reverting if any errors are found
   * @param spec the spec to validate
   * @return the original spec
   */
  function validate(Spec memory spec) private pure returns (Spec memory) {
    validateField(spec.dayOfWeek, DAY_OF_WEEK, 0, 6);
    validateField(spec.month, MONTH, 1, 12);
    uint8 maxDay = maxDayForMonthField(spec.month);
    validateField(spec.day, DAY, 1, maxDay);
    validateField(spec.hour, HOUR, 0, 23);
    validateField(spec.minute, MINUTE, 0, 59);
    return spec;
  }

  /**
   * @notice validateField validates the value of a field. It reverts if an error is found.
   * @param field the field to validate
   * @param fieldName the name of the field ex "minute" or "hour"
   * @param min the minimum value a field can have (usually 1 or 0)
   * @param max the maximum value a field can have (ex minute = 59, hour = 23)
   */
  function validateField(
    Field memory field,
    string memory fieldName,
    uint8 min,
    uint8 max
  ) private pure {
    if (field.fieldType == FieldType.WILD) {
      return;
    } else if (field.fieldType == FieldType.EXACT) {
      if (field.singleValue < min || field.singleValue > max) {
        string memory reason = string(
          bytes.concat("value must be >=,", uintToBString(min), " and <=", uintToBString(max))
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.INTERVAL) {
      if (field.interval < 1 || field.interval > max) {
        string memory reason = string(
          bytes.concat("inverval must be */(", uintToBString(1), "-", uintToBString(max), ")")
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.RANGE) {
      if (field.rangeEnd > max || field.rangeEnd <= field.rangeStart) {
        string memory reason = string(
          bytes.concat("inverval must be within ", uintToBString(min), "-", uintToBString(max))
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.LIST) {
      if (field.listLength < 2) {
        revert InvalidField(fieldName, "lists must have at least 2 items");
      }
      string memory reason = string(
        bytes.concat("items in list must be within ", uintToBString(min), "-", uintToBString(max))
      );
      uint8 listItem;
      for (uint256 idx = 0; idx < field.listLength; idx++) {
        listItem = field.list[idx];
        if (listItem < min || listItem > max) {
          revert InvalidField(fieldName, reason);
        }
      }
    } else {
      revert UnknownFieldType();
    }
  }

  /**
   * @notice maxDayForMonthField returns the maximum valid day given the month field
   * @param month the month field
   * @return the max day
   */
  function maxDayForMonthField(Field memory month) private pure returns (uint8) {
    // DEV: ranges are always safe because any two consecutive months will always
    // contain a month with 31 days
    if (month.fieldType == FieldType.WILD || month.fieldType == FieldType.RANGE) {
      return 31;
    } else if (month.fieldType == FieldType.EXACT) {
      // DEV: assume leap year in order to get max value
      return DateTime.getDaysInMonth(month.singleValue, 4);
    } else if (month.fieldType == FieldType.INTERVAL) {
      if (month.interval == 9 || month.interval == 11) {
        return 30;
      } else {
        return 31;
      }
    } else if (month.fieldType == FieldType.LIST) {
      uint8 result;
      for (uint256 idx = 0; idx < month.listLength; idx++) {
        // DEV: assume leap year in order to get max value
        uint8 daysInMonth = DateTime.getDaysInMonth(month.list[idx], 4);
        if (daysInMonth == 31) {
          return daysInMonth;
        }
        if (daysInMonth > result) {
          result = daysInMonth;
        }
      }
      return result;
    } else {
      revert UnknownFieldType();
    }
  }

  /**
   * @notice sliceToField converts a strings.slice to a field struct
   * @param fieldSlice the slice of a string representing the field of a cron job
   * @return the field
   */
  function sliceToField(strings.slice memory fieldSlice) private pure returns (Field memory) {
    strings.slice memory star = strings.toSlice("*");
    strings.slice memory dash = strings.toSlice("-");
    strings.slice memory slash = strings.toSlice("/");
    strings.slice memory comma = strings.toSlice(",");
    Field memory field;
    if (fieldSlice.equals(star)) {
      field.fieldType = FieldType.WILD;
    } else if (fieldSlice.contains(dash)) {
      field.fieldType = FieldType.RANGE;
      strings.slice memory start = fieldSlice.split(dash);
      field.rangeStart = sliceToUint8(start);
      field.rangeEnd = sliceToUint8(fieldSlice);
    } else if (fieldSlice.contains(slash)) {
      field.fieldType = FieldType.INTERVAL;
      fieldSlice.split(slash);
      field.interval = sliceToUint8(fieldSlice);
    } else if (fieldSlice.contains(comma)) {
      field.fieldType = FieldType.LIST;
      strings.slice memory token;
      while (fieldSlice.len() > 0) {
        if (field.listLength > 25) {
          revert ListTooLarge();
        }
        token = fieldSlice.split(comma);
        field.list[field.listLength] = sliceToUint8(token);
        field.listLength++;
      }
    } else {
      // needs input validation
      field.fieldType = FieldType.EXACT;
      field.singleValue = sliceToUint8(fieldSlice);
    }
    return field;
  }

  /**
   * @notice fieldToBstring converts a field to the bytes representation of that field string
   * @param field the field to stringify
   * @return bytes representing the string, ex: bytes("*")
   */
  function fieldToBstring(Field memory field) private pure returns (bytes memory) {
    if (field.fieldType == FieldType.WILD) {
      return "*";
    } else if (field.fieldType == FieldType.EXACT) {
      return uintToBString(uint256(field.singleValue));
    } else if (field.fieldType == FieldType.RANGE) {
      return bytes.concat(uintToBString(field.rangeStart), "-", uintToBString(field.rangeEnd));
    } else if (field.fieldType == FieldType.INTERVAL) {
      return bytes.concat("*/", uintToBString(uint256(field.interval)));
    } else if (field.fieldType == FieldType.LIST) {
      bytes memory result = uintToBString(field.list[0]);
      for (uint256 idx = 1; idx < field.listLength; idx++) {
        result = bytes.concat(result, ",", uintToBString(field.list[idx]));
      }
      return result;
    }
    revert UnknownFieldType();
  }

  /**
   * @notice uintToBString converts a uint256 to a bytes representation of that uint as a string
   * @param n the number to stringify
   * @return bytes representing the string, ex: bytes("1")
   */
  function uintToBString(uint256 n) private pure returns (bytes memory) {
    if (n == 0) {
      return "0";
    }
    uint256 j = n;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (n != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(n - (n / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      n /= 10;
    }
    return bstr;
  }

  /**
   * @notice sliceToUint8 converts a strings.slice to uint8
   * @param slice the string slice to convert to a uint8
   * @return the number that the string represents ex: "20" --> 20
   */
  function sliceToUint8(strings.slice memory slice) private pure returns (uint8) {
    bytes memory b = bytes(slice.toString());
    uint8 i;
    uint8 result = 0;
    for (i = 0; i < b.length; i++) {
      uint8 c = uint8(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/TypeAndVersionInterface.sol";

abstract contract OCR2Abstract is TypeAndVersionInterface {
  // Maximum number of oracles the offchain reporting protocol is designed for
  uint256 internal constant maxNumOracles = 31;
  uint256 private constant prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
  uint256 private constant prefix = 0x0001 << (256 - 16); // 0x000100..00

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configDigest configDigest of this configuration
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param signers addresses with which oracles sign the reports
   * @param transmitters addresses oracles use to transmit the reports
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external virtual;

  /**
   * @notice information about current offchain reporting protocol configuration
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
   */
  function latestConfigDetails()
    external
    view
    virtual
    returns (
      uint32 configCount,
      uint32 blockNumber,
      bytes32 configDigest
    );

  function _configDigestFromConfigData(
    uint256 chainId,
    address contractAddress,
    uint64 configCount,
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(
      keccak256(
        abi.encode(
          chainId,
          contractAddress,
          configCount,
          signers,
          transmitters,
          f,
          onchainConfig,
          offchainConfigVersion,
          offchainConfig
        )
      )
    );
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /**
  * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
  event Transmitted(bytes32 configDigest, uint32 epoch);

  /**
   * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch()
    external
    view
    virtual
    returns (
      bool scanLogs,
      bytes32 configDigest,
      uint32 epoch
    );

  /**
   * @notice transmit is called to post a new report to the contract
   * @param reportContext [0]: ConfigDigest, [1]: 27 byte padding, 4-byte epoch and 1-byte round, [2]: ExtraHash
   * @param report serialized report, which the signatures are signing.
   * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs // signatures
  ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../automation/upkeeps/CronUpkeep.sol";
import {Cron, Spec} from "../libraries/internal/Cron.sol";

/**
 * @title The CronUpkeepTestHelper contract
 * @notice This contract exposes core functionality of the CronUpkeep contract.
 * It is only intended for use in tests.
 */
contract CronUpkeepTestHelper is CronUpkeep {
  using Cron for Spec;
  using Cron for string;

  constructor(
    address owner,
    address delegate,
    uint256 maxJobs,
    bytes memory firstJob
  ) CronUpkeep(owner, delegate, maxJobs, firstJob) {}

  /**
   * @notice createCronJobFromString is a helper function for creating cron jobs
   * directly from strings. This is gas-intensive and shouldn't be done outside
   * of testing environments.
   */
  function createCronJobFromString(
    address target,
    bytes memory handler,
    string memory cronString
  ) external {
    Spec memory spec = cronString.toSpec();
    createCronJobFromSpec(target, handler, spec);
  }

  /**
   * @notice txCheckUpkeep is a helper function for sending real txs to the
   * checkUpkeep function. This allows us to do gas analysis on it.
   */
  function txCheckUpkeep(bytes calldata checkData) external {
    address(this).call(abi.encodeWithSelector(bytes4(keccak256("checkUpkeep(bytes)")), checkData));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../automation/2_0/KeeperRegistrar2_0.sol";
import "../automation/2_0/KeeperRegistry2_0.sol";

/**
 * @notice this contract must have plenty LINKs bc it will check for every active upkeeps and top up
 * addLinkAmount if their balance is lower than minBalanceThresholdMultiplier * min balance.
 * if it does not have enough LINKs, upkeeps won't perform due to low LINK balance of this contract.
 */
contract UpkeepCounterStats is ConfirmedOwner {
  error IndexOutOfRange();

  event UpkeepsRegistered(uint256[] upkeepIds);
  event UpkeepsCancelled(uint256[] upkeepIds);
  event RegistrarSet(address newRegistrar);
  event FundsAdded(uint256 upkeepId, uint96 amount);
  event UpkeepTopUp(uint256 upkeepId, uint96 amount, uint256 blockNum);
  event InsufficientFunds(uint256 balance, uint256 blockNum);
  event Received(address sender, uint256 value);
  event PerformingUpkeep(
    uint256 firstPerformBlock,
    uint256 lastBlock,
    uint256 previousBlock,
    uint256 counter
  );

  using EnumerableSet for EnumerableSet.UintSet;

  mapping(uint256 => uint256) public lastTopUpBlocks;
  mapping(uint256 => uint256) public intervals;
  mapping(uint256 => uint256) public previousPerformBlocks;
  mapping(uint256 => uint256) public firstPerformBlocks;
  mapping(uint256 => uint256) public counters;
  mapping(uint256 => uint256) public performGasToBurns;
  mapping(uint256 => uint256) public checkGasToBurns;
  mapping(uint256 => uint256) public performDataSizes;
  mapping(uint256 => uint256) public gasLimits;
  mapping(uint256 => bytes) public checkDatas;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  mapping(uint256 => uint256[]) public delays;  // how to query for delays for a certain past period: calendar day and/or past 24 hours

  mapping(uint256 => mapping(uint16 => uint256[])) public bucketedDelays;
  mapping(uint256 => mapping(uint16 => uint256[])) public timestampDelays;
  mapping(uint256 => uint256[]) public timestamps;
  mapping(uint256 => uint16) public timestampBuckets;
  mapping(uint256 => uint16) public buckets;
  EnumerableSet.UintSet internal s_upkeepIDs;
  KeeperRegistrar2_0 public registrar;
  LinkTokenInterface public linkToken;
  KeeperRegistry2_0 public registry;
  uint256 public upkeepTopUpCheckInterval = 5;
  uint96 public addLinkAmount = 200000000000000000; // 0.2 LINK
  uint8 public minBalanceThresholdMultiplier = 20;

  // the following fields are immutable bc if they are adjusted, the existing upkeeps' delays will be stored in
  // different sizes of buckets. it's better to redeploy this contract with new values.
  uint16 public immutable BUCKET_SIZE = 100;
  uint16 public immutable TIMESTAMP_INTERVAL = 3600;

  constructor(address registrarAddress) ConfirmedOwner(msg.sender) {
    registrar = KeeperRegistrar2_0(registrarAddress);
    (,,, address registryAddress,) = registrar.getRegistrationConfig();
    registry = KeeperRegistry2_0(payable(address(registryAddress)));
    linkToken = registrar.LINK();
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @notice withdraws LINKs from this contract to msg sender when testing is finished.
   */
  function withdrawLinks() external onlyOwner {
    uint256 balance = linkToken.balanceOf(address(this));
    linkToken.transfer(msg.sender, balance);
  }

  /**
   * @notice sets registrar, registry, and link token address.
   * @param newRegistrar the new registrar address
   */
  function setConfig(KeeperRegistrar2_0 newRegistrar) external {
    registrar = newRegistrar;
    (,,, address registryAddress,) = registrar.getRegistrationConfig();
    registry = KeeperRegistry2_0(payable(address(registryAddress)));
    linkToken = registrar.LINK();

    emit RegistrarSet(address(registrar));
  }

  /**
   * @notice gets an array of active upkeep IDs.
   * @param startIndex the start index of upkeep IDs
   * @param maxCount the max number of upkeep IDs requested
   * @return an array of active upkeep IDs
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice register an upkeep via the registrar.
   * @param params a registration params struct
   * @return an upkeep ID
   */
  function _registerUpkeep(KeeperRegistrar2_0.RegistrationParams memory params) private returns (uint256) {
    uint256 upkeepId = registrar.registerUpkeep(params);
    s_upkeepIDs.add(upkeepId);
    gasLimits[upkeepId] = params.gasLimit;
    checkDatas[upkeepId] = params.checkData;
    return upkeepId;
  }

  /**
   * @notice batch registering upkeeps.
   * @param number the number of upkeeps to be registered
   * @param gasLimit the gas limit of each upkeep
   * @param amount the amount of LINK to fund each upkeep
   * @param checkGasToBurn the amount of check gas to burn
   * @param performGasToBurn the amount of perform gas to burn
   */
  function batchRegisterUpkeeps(uint8 number, uint32 gasLimit, uint96 amount, uint256 checkGasToBurn, uint256 performGasToBurn) external {
    KeeperRegistrar2_0.RegistrationParams memory params = KeeperRegistrar2_0.RegistrationParams({
      name: "test",
      encryptedEmail: bytes(""),
      upkeepContract: address(this),
      gasLimit: gasLimit,
      adminAddress: address(this), // use address of this contract as the admin
      checkData: bytes(""), // update check data later bc upkeep id is not available now
      offchainConfig: bytes(""),
      amount: amount
    });

    linkToken.approve(address(registrar), amount * number);

    uint256[] memory upkeepIds = new uint256[](number);
    for (uint8 i = 0; i < number; i++) {
      uint256 upkeepId = _registerUpkeep(params);
      upkeepIds[i] = upkeepId;
      checkGasToBurns[upkeepId] = checkGasToBurn;
      performGasToBurns[upkeepId] = performGasToBurn;
    }
    emit UpkeepsRegistered(upkeepIds);
  }

  /**
   * @notice adds fund for an upkeep.
   * @param upkeepId the upkeep ID
   * @param amount the amount of LINK to be funded for the upkeep
   */
  function addFunds(uint256 upkeepId, uint96 amount) external {
    linkToken.approve(address(registry), amount);
    registry.addFunds(upkeepId, amount);
    emit FundsAdded(upkeepId, amount);
  }

  /**
   * @notice updates check data for an upkeep. In order for the upkeep to be performed, the check data must be the abi encoded upkeep ID.
   * @param upkeepId the upkeep ID
   * @param checkData the new check data for the upkeep
   */
  function updateCheckData(uint256 upkeepId, bytes calldata checkData) external {
    registry.updateCheckData(upkeepId, checkData);
    checkDatas[upkeepId] = checkData;
  }

  /**
   * @notice cancel an upkeep.
   * @param upkeepId the upkeep ID
   */
  function cancelUpkeep(uint256 upkeepId) external {
    registry.cancelUpkeep(upkeepId);
    s_upkeepIDs.remove(upkeepId);
  }

  function withdrawLinks(uint256 upkeepId) external {
    registry.withdrawFunds(upkeepId, address(this));
  }

  /**
   * @notice batch canceling upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchCancelUpkeeps(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint8 i = 0; i < len; i++) {
      this.cancelUpkeep(upkeepIds[i]);
    }
    emit UpkeepsCancelled(upkeepIds);
  }

  function checkUpkeep(bytes calldata checkData) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    (uint256 upkeepId) = abi.decode(
      checkData,
      (uint256)
    );

    uint256 performDataSize = performDataSizes[upkeepId];
    uint256 checkGasToBurn = checkGasToBurns[upkeepId];
    bytes memory pData = abi.encode(upkeepId, new bytes(performDataSize));
    uint256 blockNum = block.number;
    bool needed = eligible(upkeepId);
    while (startGas - gasleft() + 10000 < checkGasToBurn) {
      // 10K margin over gas to burn
      // Hard coded check gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
    return (needed, pData);
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    (uint256 upkeepId, ) = abi.decode(
      performData,
      (uint256, bytes)
    );
    uint256 firstPerformBlock = firstPerformBlocks[upkeepId];
    uint256 previousPerformBlock = previousPerformBlocks[upkeepId];
    uint256 blockNum = block.number;
    if (firstPerformBlock == 0) {
      firstPerformBlocks[upkeepId] = blockNum;
      firstPerformBlock = blockNum;
      timestamps[upkeepId].push(block.timestamp);
    } else {
      // Calculate and append delay
      uint256 delay = blockNum - previousPerformBlock - intervals[upkeepId];

      uint16 timestampBucket = timestampBuckets[upkeepId];
      if (block.timestamp - TIMESTAMP_INTERVAL > timestamps[upkeepId][timestampBucket]) {
        timestamps[upkeepId].push(block.timestamp);
        timestampBucket++;
        timestampBuckets[upkeepId] = timestampBucket;
      }

      uint16 bucket = buckets[upkeepId];
      uint256[] memory bucketDelays = bucketedDelays[upkeepId][bucket];
      if (bucketDelays.length == BUCKET_SIZE) {
        bucket++;
        buckets[upkeepId] = bucket;
      }
      bucketedDelays[upkeepId][bucket].push(delay);
      timestampDelays[upkeepId][timestampBucket].push(delay);
      delays[upkeepId].push(delay);
    }

    uint256 counter = counters[upkeepId] + 1;
    counters[upkeepId] = counter;
    emit PerformingUpkeep(firstPerformBlock, blockNum, previousPerformBlock, counter);
    previousPerformBlocks[upkeepId] = blockNum;

    // for every upkeepTopUpCheckInterval (5), check if the upkeep balance is at least
    // minBalanceThresholdMultiplier (20) * min balance. If not, add addLinkAmount (0.2) to the upkeep
    // upkeepTopUpCheckInterval, minBalanceThresholdMultiplier, and addLinkAmount are configurable
    if (blockNum - lastTopUpBlocks[upkeepId] > upkeepTopUpCheckInterval) {
      UpkeepInfo memory info = registry.getUpkeep(upkeepId);
      uint96 minBalance = registry.getMinBalanceForUpkeep(upkeepId);
      if (info.balance < minBalanceThresholdMultiplier * minBalance) {
        this.addFunds(upkeepId, addLinkAmount);
        lastTopUpBlocks[upkeepId] = blockNum;
        emit UpkeepTopUp(upkeepId, addLinkAmount, blockNum);
      }
    }

    uint256 performGasToBurn = performGasToBurns[upkeepId];
    while (startGas - gasleft() + 10000 < performGasToBurn) {
      // 10K margin over gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
  }

  function eligible(uint256 upkeepId) public view returns (bool) {
    if (firstPerformBlocks[upkeepId] == 0) {
      return true;
    }
    return (block.number - previousPerformBlocks[upkeepId]) >= intervals[upkeepId];
  }

  /**
   * @notice set a new add LINK amount.
   * @param amount the new value
   */
  function setAddLinkAmount(uint96 amount) external {
    addLinkAmount = amount;
  }

  function setUpkeepTopUpCheckInterval(uint256 newInterval) external {
    upkeepTopUpCheckInterval = newInterval;
  }

  function setMinBalanceThresholdMultiplier(uint8 newMinBalanceThresholdMultiplier) external {
    minBalanceThresholdMultiplier = newMinBalanceThresholdMultiplier;
  }

  function setPerformGasToBurn(uint256 upkeepId, uint256 value) public {
    performGasToBurns[upkeepId] = value;
  }

  function setCheckGasToBurn(uint256 upkeepId, uint256 value) public {
    checkGasToBurns[upkeepId] = value;
  }

  function setPerformDataSize(uint256 upkeepId, uint256 value) public {
    performDataSizes[upkeepId] = value;
  }

  function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) public {
    registry.setUpkeepGasLimit(upkeepId, gasLimit);
    gasLimits[upkeepId] = gasLimit;
  }

  function setInterval(uint256 upkeepId, uint256 _interval) external {
    intervals[upkeepId] = _interval;
    firstPerformBlocks[upkeepId] = 0;
    counters[upkeepId] = 0;

    delete delays[upkeepId];
    uint16 currentBucket = buckets[upkeepId];
    for (uint16 i = 0; i <= currentBucket; i++) {
      delete bucketedDelays[upkeepId][i];
    }
    delete buckets[upkeepId];

    currentBucket = timestampBuckets[upkeepId];
    for (uint16 i = 0; i <= currentBucket; i++) {
      delete timestampDelays[upkeepId][i];
    }
    delete timestamps[upkeepId];
    delete timestampBuckets[upkeepId];
  }

  /**
   * @notice batch setting intervals for an array of upkeeps.
   * @param upkeepIds an array of upkeep IDs
   * @param interval a new interval
   */
  function batchSetIntervals(uint256[] calldata upkeepIds, uint32 interval) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      this.setInterval(upkeepIds[i], interval);
    }
  }

  /**
   * @notice batch updating check data for all upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchUpdateCheckData(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];
      this.updateCheckData(upkeepId, abi.encode(upkeepId));
    }
  }

  function getDelaysLength(uint256 upkeepId) public view returns (uint256) {
    return delays[upkeepId].length;
  }

  function getDelaysLengthAtBucket(uint256 upkeepId, uint16 bucket) public view returns (uint256) {
    return bucketedDelays[upkeepId][bucket].length;
  }

  function getDelaysLengthAtTimestampBucket(uint256 upkeepId, uint16 timestampBucket) public view returns (uint256) {
    return timestampDelays[upkeepId][timestampBucket].length;
  }

  function getBucketedDelaysLength(uint256 upkeepId) public view returns (uint256) {
    uint16 currentBucket = buckets[upkeepId];
    uint256 len = 0;
    for (uint16 i = 0; i <= currentBucket; i++) {
      len += bucketedDelays[upkeepId][i].length;
    }
    return len;
  }

  function getTimestampBucketedDelaysLength(uint256 upkeepId) public view returns (uint256) {
    uint16 timestampBucket = timestampBuckets[upkeepId];
    uint256 len = 0;
    for (uint16 i = 0; i <= timestampBucket; i++) {
      len += timestampDelays[upkeepId][i].length;
    }
    return len;
  }

  function getDelays(uint256 upkeepId) public view returns (uint256[] memory) {
    return delays[upkeepId];
  }

  function getTimestampDelays(uint256 upkeepId, uint16 timestampBucket) public view returns (uint256[] memory) {
    return timestampDelays[upkeepId][timestampBucket];
  }

  function getBucketedDelays(uint256 upkeepId, uint16 bucket) public view returns (uint256[] memory) {
    return bucketedDelays[upkeepId][bucket];
  }

  function getSumDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256[] memory delays = delays[upkeepId];
    return getSumDelayLastNPerforms(delays, n);
  }

  function getSumBucketedDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256 len = this.getBucketedDelaysLength(upkeepId);
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 nn = n;
    uint256 sum = 0;
    uint16 currentBucket = buckets[upkeepId];
    for (uint16 i = currentBucket; i >= 0; i--) {
      uint256[] memory delays = bucketedDelays[upkeepId][i];
      (uint256 s, uint256 m) = getSumDelayLastNPerforms(delays, nn);
      sum += s;
      nn -= m;
      if (nn <= 0) {
        break;
      }
    }
    return (sum, n);
  }

  function getSumTimestampBucketedDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256 len = this.getTimestampBucketedDelaysLength(upkeepId);
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 nn = n;
    uint256 sum = 0;
    uint16 timestampBucket = timestampBuckets[upkeepId];
    for (uint16 i = timestampBucket; i >= 0; i--) {
      uint256[] memory delays = timestampDelays[upkeepId][i];
      (uint256 s, uint256 m) = getSumDelayLastNPerforms(delays, nn);
      sum += s;
      nn -= m;
      if (nn <= 0) {
        break;
      }
    }
    return (sum, n);
  }

  function getSumDelayInBucket(uint256 upkeepId, uint16 bucket) public view returns (uint256, uint256) {
    uint256[] memory delays = bucketedDelays[upkeepId][bucket];
    return getSumDelayLastNPerforms(delays, delays.length);
  }

  function getSumDelayInTimestampBucket(uint256 upkeepId, uint16 timestampBucket) public view returns (uint256, uint256) {
    uint256[] memory delays = timestampDelays[upkeepId][timestampBucket];
    return getSumDelayLastNPerforms(delays, delays.length);
  }

  function getSumDelayLastNPerforms(uint256[] memory delays, uint256 n) internal view returns (uint256, uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 sum = 0;

    for (i = 0; i < n; i++) sum = sum + delays[len - i - 1];
    return (sum, n);
  }

  function getPxDelayForAllUpkeeps(uint256 p) public view returns (uint256[] memory, uint256[] memory) {
    uint256 len = s_upkeepIDs.length();
    uint256[] memory upkeepIds = new uint256[](len);
    uint256[] memory pxDelays = new uint256[](len);

    for (uint256 idx = 0; idx < len; idx++) {
      uint256 upkeepId = s_upkeepIDs.at(idx);
      uint256[] memory delays = delays[upkeepId];
      upkeepIds[idx] = upkeepId;
      pxDelays[idx] = getPxDelayLastNPerforms(delays, p, delays.length);
    }

    return (upkeepIds, pxDelays);
  }

  function getPxBucketedDelaysForAllUpkeeps(uint256 p) public view returns (uint256[] memory, uint256[] memory) {
    uint256 len = s_upkeepIDs.length();
    uint256[] memory upkeepIds = new uint256[](len);
    uint256[] memory pxDelays = new uint256[](len);

    for (uint256 idx = 0; idx < len; idx++) {
      uint256 upkeepId = s_upkeepIDs.at(idx);
      upkeepIds[idx] = upkeepId;
      uint16 currentBucket = buckets[upkeepId];
      uint256 delayLen = this.getBucketedDelaysLength(upkeepId);
      uint256[] memory delays = new uint256[](delayLen);
      uint256 i = 0;
      mapping(uint16 => uint256[]) storage bucketedDelays = bucketedDelays[upkeepId];
      for (uint16 j = 0; j <= currentBucket; j++) {
        uint256[] memory d = bucketedDelays[j];
        for (uint256 k = 0; k < d.length; k++) {
          delays[i++] = d[k];
        }
      }
      pxDelays[idx] = getPxDelayLastNPerforms(delays, p, delayLen);
    }

    return (upkeepIds, pxDelays);
  }

  function getPxDelayInTimestampBucket(uint256 upkeepId, uint256 p, uint16 timestampBucket) public view returns (uint256) {
    uint256[] memory delays = timestampDelays[upkeepId][timestampBucket];
    return getPxDelayLastNPerforms(delays, p, delays.length);
  }

  function getPxDelayInBucket(uint256 upkeepId, uint256 p, uint16 bucket) public view returns (uint256) {
    uint256[] memory delays = bucketedDelays[upkeepId][bucket];
    return getPxDelayLastNPerforms(delays, p, delays.length);
  }

  function getPxDelayLastNPerforms(uint256 upkeepId, uint256 p, uint256 n) public view returns (uint256) {
    return getPxDelayLastNPerforms(delays[upkeepId], p, n);
  }

  function getPxDelayLastNPerforms(uint256[] memory delays, uint256 p, uint256 n) internal view returns (uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256[] memory subArr = new uint256[](n);

    for (i = 0; i < n; i++) subArr[i] = (delays[len - i - 1]);
    quickSort(subArr, int256(0), int256(subArr.length - 1));

    if (p == 100) {
      return  subArr[subArr.length - 1];
    }
    return subArr[(p * subArr.length) / 100];
  }

  function quickSort(
    uint256[] memory arr,
    int256 left,
    int256 right
  ) private pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../dev/VRFSubscriptionBalanceMonitor.sol";

contract VRFSubscriptionBalanceMonitorExposed is VRFSubscriptionBalanceMonitor {
  constructor(
    address linkTokenAddress,
    address coordinatorAddress,
    address keeperRegistryAddress,
    uint256 minWaitPeriodSeconds
  ) VRFSubscriptionBalanceMonitor(linkTokenAddress, coordinatorAddress, keeperRegistryAddress, minWaitPeriodSeconds) {}

  function setLastTopUpXXXTestOnly(uint64 target, uint56 lastTopUpTimestamp) external {
    s_targets[target].lastTopUpTimestamp = lastTopUpTimestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice getRevertMsg extracts a revert reason from a failed contract call
 */
function getRevertMsg(bytes memory payload) pure returns (string memory) {
  if (payload.length < 68) return "transaction reverted silently";
  assembly {
    payload := add(payload, 0x04)
  }
  return abi.decode(payload, (string));
}

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * All public variables are set while generating the initial L2 state. The
 * constructor doesn't run in practice as the L2 state generation script uses
 * the deployed bytecode instead of running the initcode.
 */
contract OVM_GasPriceOracle is Ownable {
    /*************
     * Variables *
     *************/

    // Current L2 gas price
    uint256 public gasPrice;
    // Current L1 base fee
    uint256 public l1BaseFee;
    // Amortized cost of batch submission per transaction
    uint256 public overhead;
    // Value to scale the fee up by
    uint256 public scalar;
    // Number of decimals of the scalar
    uint256 public decimals;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _owner Address that will initially own this contract.
     */
    constructor(address _owner) Ownable() {
        transferOwnership(_owner);
    }

    /**********
     * Events *
     **********/

    event GasPriceUpdated(uint256);
    event L1BaseFeeUpdated(uint256);
    event OverheadUpdated(uint256);
    event ScalarUpdated(uint256);
    event DecimalsUpdated(uint256);

    /********************
     * Public Functions *
     ********************/

    /**
     * Allows the owner to modify the l2 gas price.
     * @param _gasPrice New l2 gas price.
     */
    // slither-disable-next-line external-function
    function setGasPrice(uint256 _gasPrice) public onlyOwner {
        gasPrice = _gasPrice;
        emit GasPriceUpdated(_gasPrice);
    }

    /**
     * Allows the owner to modify the l1 base fee.
     * @param _baseFee New l1 base fee
     */
    // slither-disable-next-line external-function
    function setL1BaseFee(uint256 _baseFee) public onlyOwner {
        l1BaseFee = _baseFee;
        emit L1BaseFeeUpdated(_baseFee);
    }

    /**
     * Allows the owner to modify the overhead.
     * @param _overhead New overhead
     */
    // slither-disable-next-line external-function
    function setOverhead(uint256 _overhead) public onlyOwner {
        overhead = _overhead;
        emit OverheadUpdated(_overhead);
    }

    /**
     * Allows the owner to modify the scalar.
     * @param _scalar New scalar
     */
    // slither-disable-next-line external-function
    function setScalar(uint256 _scalar) public onlyOwner {
        scalar = _scalar;
        emit ScalarUpdated(_scalar);
    }

    /**
     * Allows the owner to modify the decimals.
     * @param _decimals New decimals
     */
    // slither-disable-next-line external-function
    function setDecimals(uint256 _decimals) public onlyOwner {
        decimals = _decimals;
        emit DecimalsUpdated(_decimals);
    }

    /**
     * Computes the L1 portion of the fee
     * based on the size of the RLP encoded tx
     * and the current l1BaseFee
     * @param _data Unsigned RLP encoded tx, 6 elements
     * @return L1 fee that should be paid for the tx
     */
    // slither-disable-next-line external-function
    function getL1Fee(bytes memory _data) public view returns (uint256) {
        uint256 l1GasUsed = getL1GasUsed(_data);
        uint256 l1Fee = l1GasUsed * l1BaseFee;
        uint256 divisor = 10**decimals;
        uint256 unscaled = l1Fee * scalar;
        uint256 scaled = unscaled / divisor;
        return scaled;
    }

    // solhint-disable max-line-length
    /**
     * Computes the amount of L1 gas used for a transaction
     * The overhead represents the per batch gas overhead of
     * posting both transaction and state roots to L1 given larger
     * batch sizes.
     * 4 gas for 0 byte
     * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
     * 16 gas for non zero byte
     * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
     * This will need to be updated if calldata gas prices change
     * Account for the transaction being unsigned
     * Padding is added to account for lack of signature on transaction
     * 1 byte for RLP V prefix
     * 1 byte for V
     * 1 byte for RLP R prefix
     * 32 bytes for R
     * 1 byte for RLP S prefix
     * 32 bytes for S
     * Total: 68 bytes of padding
     * @param _data Unsigned RLP encoded tx, 6 elements
     * @return Amount of L1 gas used for a transaction
     */
    // solhint-enable max-line-length
    function getL1GasUsed(bytes memory _data) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _data.length; i++) {
            if (_data[i] == 0) {
                total += 4;
            } else {
                total += 16;
            }
        }
        uint256 unsigned = total + overhead;
        return unsigned + (68 * 16);
    }
}

// SPDX-License-Identifier: MIT

// sourced from https://github.com/pipermerriam/ethereum-datetime

pragma solidity ^0.8.0;

library DateTime {
  /*
   *  Date and Time utilities for ethereum contracts
   *
   */
  struct _DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  uint256 constant DAY_IN_SECONDS = 86400;
  uint256 constant YEAR_IN_SECONDS = 31536000;
  uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint256 constant HOUR_IN_SECONDS = 3600;
  uint256 constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint256 year) internal pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year)
    internal
    pure
    returns (uint8)
  {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (isLeapYear(year)) {
      return 29;
    } else {
      return 28;
    }
  }

  function parseTimestamp(uint256 timestamp)
    internal
    pure
    returns (_DateTime memory dt)
  {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;

    // Year
    dt.year = getYear(timestamp);
    buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

    // Month
    uint256 secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dt.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dt.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dt.hour = getHour(timestamp);

    // Minute
    dt.minute = getMinute(timestamp);

    // Second
    dt.second = getSecond(timestamp);

    // Day of week.
    dt.weekday = getWeekday(timestamp);
  }

  function getYear(uint256 timestamp) internal pure returns (uint16) {
    uint256 secondsAccountedFor = 0;
    uint16 year;
    uint256 numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor +=
      YEAR_IN_SECONDS *
      (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) internal pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, minute, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) internal pure returns (uint256 timestamp) {
    uint16 i;

    // Year
    for (i = ORIGIN_YEAR; i < year; i++) {
      if (isLeapYear(i)) {
        timestamp += LEAP_YEAR_IN_SECONDS;
      } else {
        timestamp += YEAR_IN_SECONDS;
      }
    }

    // Month
    uint8[12] memory monthDayCounts;
    monthDayCounts[0] = 31;
    if (isLeapYear(year)) {
      monthDayCounts[1] = 29;
    } else {
      monthDayCounts[1] = 28;
    }
    monthDayCounts[2] = 31;
    monthDayCounts[3] = 30;
    monthDayCounts[4] = 31;
    monthDayCounts[5] = 30;
    monthDayCounts[6] = 31;
    monthDayCounts[7] = 31;
    monthDayCounts[8] = 30;
    monthDayCounts[9] = 31;
    monthDayCounts[10] = 30;
    monthDayCounts[11] = 31;

    for (i = 1; i < month; i++) {
      timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
    }

    // Day
    timestamp += DAY_IN_SECONDS * (day - 1);

    // Hour
    timestamp += HOUR_IN_SECONDS * (hour);

    // Minute
    timestamp += MINUTE_IN_SECONDS * (minute);

    // Second
    timestamp += second;

    return timestamp;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

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
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
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
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

// SPDX-License-Identifier: Apache 2.0

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
    uint256 _len;
    uint256 _ptr;
  }

  function memcpy(
    uint256 dest,
    uint256 src,
    uint256 len
  ) private pure {
    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = type(uint256).max;
    if (len > 0) {
      mask = 256**(32 - len) - 1;
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
    uint256 ptr;
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
  function len(bytes32 self) internal pure returns (uint256) {
    uint256 ret;
    if (self == 0) return 0;
    if (uint256(self) & type(uint128).max == 0) {
      ret += 16;
      self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
    }
    if (uint256(self) & type(uint64).max == 0) {
      ret += 8;
      self = bytes32(uint256(self) / 0x10000000000000000);
    }
    if (uint256(self) & type(uint32).max == 0) {
      ret += 4;
      self = bytes32(uint256(self) / 0x100000000);
    }
    if (uint256(self) & type(uint16).max == 0) {
      ret += 2;
      self = bytes32(uint256(self) / 0x10000);
    }
    if (uint256(self) & type(uint8).max == 0) {
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
    uint256 retptr;
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
  function len(slice memory self) internal pure returns (uint256 l) {
    // Starting at ptr-31 means the LSB will be the byte we care about
    uint256 ptr = self._ptr - 31;
    uint256 end = ptr + self._len;
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
  function compare(slice memory self, slice memory other)
    internal
    pure
    returns (int256)
  {
    uint256 shortest = self._len;
    if (other._len < self._len) shortest = other._len;

    uint256 selfptr = self._ptr;
    uint256 otherptr = other._ptr;
    for (uint256 idx = 0; idx < shortest; idx += 32) {
      uint256 a;
      uint256 b;
      assembly {
        a := mload(selfptr)
        b := mload(otherptr)
      }
      if (a != b) {
        // Mask out irrelevant bytes and check again
        uint256 mask = type(uint256).max; // 0xffff...
        if (shortest < 32) {
          mask = ~(2**(8 * (32 - shortest + idx)) - 1);
        }
        unchecked {
          uint256 diff = (a & mask) - (b & mask);
          if (diff != 0) return int256(diff);
        }
      }
      selfptr += 32;
      otherptr += 32;
    }
    return int256(self._len) - int256(other._len);
  }

  /*
   * @dev Returns true if the two slices contain the same text.
   * @param self The first slice to compare.
   * @param self The second slice to compare.
   * @return True if the slices are equal, false otherwise.
   */
  function equals(slice memory self, slice memory other)
    internal
    pure
    returns (bool)
  {
    return compare(self, other) == 0;
  }

  /*
   * @dev Extracts the first rune in the slice into `rune`, advancing the
   *      slice to point to the next rune and returning `self`.
   * @param self The slice to operate on.
   * @param rune The slice that will contain the first rune.
   * @return `rune`.
   */
  function nextRune(slice memory self, slice memory rune)
    internal
    pure
    returns (slice memory)
  {
    rune._ptr = self._ptr;

    if (self._len == 0) {
      rune._len = 0;
      return rune;
    }

    uint256 l;
    uint256 b;
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
  function nextRune(slice memory self)
    internal
    pure
    returns (slice memory ret)
  {
    nextRune(self, ret);
  }

  /*
   * @dev Returns the number of the first codepoint in the slice.
   * @param self The slice to operate on.
   * @return The number of the first codepoint in the slice.
   */
  function ord(slice memory self) internal pure returns (uint256 ret) {
    if (self._len == 0) {
      return 0;
    }

    uint256 word;
    uint256 length;
    uint256 divisor = 2**248;

    // Load the rune into the MSBs of b
    assembly {
      word := mload(mload(add(self, 32)))
    }
    uint256 b = word / divisor;
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

    for (uint256 i = 1; i < length; i++) {
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
  function startsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
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
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
  function beyond(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let selfptr := mload(add(self, 0x20))
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
  function endsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    if (self._len < needle._len) {
      return false;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;

    if (selfptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
  function until(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;
    bool equal = true;
    if (selfptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr = selfptr;
    uint256 idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        uint256 end = selfptr + selflen - needlelen;
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
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
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
  function find(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
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
  function rfind(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
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
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
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
  function split(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
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
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
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
  function rsplit(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    rsplit(self, needle, token);
  }

  /*
   * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return The number of occurrences of `needle` found in `self`.
   */
  function count(slice memory self, slice memory needle)
    internal
    pure
    returns (uint256 cnt)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
      needle._len;
    while (ptr <= self._ptr + self._len) {
      cnt++;
      ptr =
        findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) +
        needle._len;
    }
  }

  /*
   * @dev Returns True if `self` contains `needle`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return True if `needle` is found in `self`, false otherwise.
   */
  function contains(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    return
      rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
  }

  /*
   * @dev Returns a newly allocated string containing the concatenation of
   *      `self` and `other`.
   * @param self The first slice to concatenate.
   * @param other The second slice to concatenate.
   * @return The concatenation of the two strings.
   */
  function concat(slice memory self, slice memory other)
    internal
    pure
    returns (string memory)
  {
    string memory ret = new string(self._len + other._len);
    uint256 retptr;
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
  function join(slice memory self, slice[] memory parts)
    internal
    pure
    returns (string memory)
  {
    if (parts.length == 0) return "";

    uint256 length = self._len * (parts.length - 1);
    for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

    string memory ret = new string(length);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    for (uint256 i = 0; i < parts.length; i++) {
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
pragma solidity 0.8.6;

/**
 * @title VRFTypes
 * @notice The VRFTypes library is a collection of types that is required to fulfill VRF requests
 * 	on-chain. They must be ABI-compatible with the types used by the coordinator contracts.
 */
library VRFTypes {
  // ABI-compatible with VRF.Proof.
  // This proof is used for VRF V2.
  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  // ABI-compatible with VRFCoordinatorV2.RequestCommitment.
  // This is only used for VRF V2.
  struct RequestCommitment {
    uint64 blockNum;
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }
}