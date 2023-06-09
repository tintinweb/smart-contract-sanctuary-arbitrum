// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title ArgusRootAuthorizer - Default root authorizers for Argus platform.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice ArgusRootAuthorizer is a authorizer manager which dispatch the correct
///         sub authorizer according to role of delegate and call type.
///         Hint is supported here so user can get the hint, the correct authorizer
///         in this case,  off-chain (this can be expensive on-chain) and preform
///         on-chain transaction to save gas.
contract ArgusRootAuthorizer is BaseAuthorizer, IAuthorizerSupportingHint {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    bytes32 public constant NAME = "ArgusRootAuthorizer";
    uint256 public constant VERSION = 1;
    bytes32 public constant override TYPE = AuthType.SET;

    /// @dev This changes when authorizer adds.
    uint256 private _unionFlag;

    // Roles in the authorizer. Only used for enumeration.
    EnumerableSet.Bytes32Set roles;

    // `isDelegateCall` => `Role` => `Authorizer address set`
    // true for delegatecall, false for call.
    mapping(bool => mapping(bytes32 => EnumerableSet.AddressSet)) internal authorizerSet;

    // Authorizers who implement process handler (with flag `HAS_POST_PROC_MASK` or `HAS_POST_PROC_MASK`)
    // will added into `processSet` and will be invoked unconditionally at each tx.
    mapping(bool => EnumerableSet.AddressSet) internal processSet;

    /// Events.
    event NewAuthorizerAdded(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event NewProcessAdded(bool indexed isDelegateCall, address indexed authorizer);
    event AuthorizerRemoved(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event ProcessRemoved(bool indexed isDelegateCall, address indexed authorizer);

    constructor(address _owner, address _caller, address _account) BaseAuthorizer(_owner, _caller) {
        // We need role manager.
        account = _account;
    }

    /// @dev pack/unpack should match.
    function _packHint(bytes32 role, address auth, bytes memory subHint) internal pure returns (bytes memory hint) {
        return abi.encodePacked(abi.encode(role, auth), subHint);
    }

    function _unpackHint(bytes calldata hint) internal pure returns (bytes32 role, address auth, bytes memory subHint) {
        (role, auth) = abi.decode(hint[0:64], (bytes32, address));
        subHint = hint[64:];
    }

    /// @dev Catch error of sub authorizers to prevent the case when one authorizer fails reverts the entire
    ///      check chain process.
    function _safePreExecCheck(
        address auth,
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory preData) {
        try IAuthorizer(auth).preExecCheck(transaction) returns (AuthorizerReturnData memory _preData) {
            return _preData;
        } catch Error(string memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = reason;
        } catch (bytes memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = string(reason);
        }
    }

    function _safePostExecCheck(
        address auth,
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData memory preData
    ) internal returns (AuthorizerReturnData memory postData) {
        try IAuthorizer(auth).postExecCheck(transaction, callResult, preData) returns (
            AuthorizerReturnData memory _postData
        ) {
            return _postData;
        } catch Error(string memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = reason;
        } catch (bytes memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = string(reason);
        }
    }

    function _safeCollectHint(
        address auth,
        AuthorizerReturnData memory preData,
        AuthorizerReturnData memory postData
    ) internal returns (bytes memory subHint) {
        try IAuthorizerSupportingHint(auth).collectHint(preData, postData) returns (bytes memory _subHint) {
            return _subHint;
        } catch {
            return subHint;
        }
    }

    /// @dev preExecCheck and postExecCheck use extractly the same hint thus
    /// the same sub authorizer is called.
    function _preExecCheckWithHint(
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        // The authorizer from hint should have either PreCheck or PostCheck.
        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        if (!_flag.hasPreCheck()) {
            // If pre check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        // Cut the hint to sub hint.
        TransactionData memory txn = transaction;
        txn.hint = subHint;

        // In hint path, this should never revert so `_safePreExecCheck()` is not used here.
        return IAuthorizer(auth).preExecCheck(txn);
    }

    function _postExecCheckWithHint(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);
        if (!_flag.hasPostCheck()) {
            // If post check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        TransactionData memory txn = transaction;
        txn.hint = subHint;
        return IAuthorizer(auth).postExecCheck(txn, callResult, preData);
    }

    struct PreCheckData {
        bytes32 role;
        address authorizer;
        AuthorizerReturnData authData;
    }

    // This is very expensive on-chain.
    // Should only used to collect hint off-chain.
    PreCheckData[] internal preCheckDataCache;

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal override returns (AuthorizerReturnData memory authData) {
        if (transaction.hint.length > 0) {
            return _preExecCheckWithHint(transaction);
        }

        authData.result = AuthResult.FAILED;
        bytes32[] memory txRoles = _authenticate(transaction);
        uint256 roleLength = txRoles.length;
        if (roleLength == 0) {
            authData.message = Errors.EMPTY_ROLE_SET;
            return authData;
        }

        bool isDelegateCall = transaction.flag.isDelegateCall();
        for (uint256 i = 0; i < roleLength; ++i) {
            bytes32 role = txRoles[i];
            EnumerableSet.AddressSet storage authSet = authorizerSet[isDelegateCall][role];

            uint256 length = authSet.length();

            // Run all pre checks and record auth results.
            for (uint256 j = 0; j < length; ++j) {
                address auth = authSet.at(j);
                AuthorizerReturnData memory preData = _safePreExecCheck(auth, transaction);

                if (preData.result == AuthResult.SUCCESS) {
                    authData.result = AuthResult.SUCCESS;

                    // Only save success results.
                    preCheckDataCache.push(PreCheckData(role, auth, preData));
                }
            }
        }

        if (authData.result == AuthResult.SUCCESS) {
            // Temporary data for post checker to collect hint.
            authData.data = abi.encode(preCheckDataCache);
        } else {
            authData.message = Errors.ALL_AUTH_FAILED;
        }

        delete preCheckDataCache; // gas refund.
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal override returns (AuthorizerReturnData memory postData) {
        if (transaction.hint.length > 0) {
            return _postExecCheckWithHint(transaction, callResult, preData);
        }

        // Get pre check results from preData.
        PreCheckData[] memory preResults = abi.decode(preData.data, (PreCheckData[]));
        uint256 length = preResults.length;

        // We should have reverted in preExecCheck. But safer is better.
        require(length > 0, Errors.INVALID_HINT_COLLECTED);

        bool isDelegateCall = transaction.flag.isDelegateCall();

        for (uint256 i = 0; i < length; ++i) {
            bytes32 role = preResults[i].role;
            address authAddress = preResults[i].authorizer;

            require(authorizerSet[isDelegateCall][role].contains(authAddress), Errors.INVALID_HINT_COLLECTED);

            // Run post check.
            AuthorizerReturnData memory preCheckData = preResults[i].authData;
            postData = _safePostExecCheck(authAddress, transaction, callResult, preCheckData);

            // If pre and post both succeeded, we pass.
            if (postData.result == AuthResult.SUCCESS) {
                // Collect hint of sub authorizer if needed.
                bytes memory subHint;
                if (IAuthorizer(authAddress).flag().supportHint()) {
                    subHint = _safeCollectHint(authAddress, preCheckData, postData);
                }
                postData.data = _packHint(role, authAddress, subHint);
                return postData;
            }
        }
        postData.result = AuthResult.FAILED;
        postData.message = Errors.ALL_AUTH_FAILED;
    }

    function collectHint(
        AuthorizerReturnData calldata preAuthData,
        AuthorizerReturnData calldata postAuthData
    ) public view returns (bytes memory hint) {
        // Use post data as hint.
        hint = postAuthData.data;
    }

    /// @dev All sub preExecProcess / postExecProcess handlers are supposed be called.
    function _preExecProcess(TransactionData calldata transaction) internal virtual override {
        if (!_unionFlag.hasPreProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPreProcess()) {
                // Ignore reverts.
                try auth.preExecProcess(transaction) {} catch {}
            }
        }
    }

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual override {
        if (!_unionFlag.hasPostProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPostProcess()) {
                // Ignore reverts.
                try auth.postExecProcess(transaction, callResult) {} catch {}
            }
        }
    }

    /// External / Public funtions.
    function addAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        roles.add(role);

        if (authorizerSet[isDelegateCall][role].add(authorizer)) {
            emit NewAuthorizerAdded(isDelegateCall, role, authorizer);

            // Collect flag.
            _unionFlag |= _flag;

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // An authorizer with process handler can NOT be installed twice as this cause
                // confusion when running process handler twice in one transaction.
                require(processSet[isDelegateCall].add(authorizer), Errors.SAME_PROCESS_TWICE);

                emit NewProcessAdded(isDelegateCall, authorizer);
            }
        }
    }

    function removeAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        if (authorizerSet[isDelegateCall][role].remove(authorizer)) {
            emit AuthorizerRemoved(isDelegateCall, role, authorizer);

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // It is ok to remove here as we has checked duplication in `addAuthorizer()`.
                if (processSet[isDelegateCall].remove(authorizer)) {
                    emit ProcessRemoved(isDelegateCall, authorizer);

                    if (processSet[isDelegateCall].length() == 0 && processSet[!isDelegateCall].length() == 0) {
                        _unionFlag -= (_unionFlag & (AuthFlags.HAS_PRE_PROC_MASK | AuthFlags.HAS_POST_PROC_MASK));
                    }
                }
            }
        }
    }

    /// External view funtions.

    function flag() external view returns (uint256) {
        return _unionFlag | AuthFlags.SUPPORT_HINT_MASK;
    }

    function authorizerSize(bool isDelegateCall, bytes32 role) external view returns (uint256) {
        return authorizerSet[isDelegateCall][role].length();
    }

    function hasAuthorizer(bool isDelegateCall, bytes32 role, address auth) external view returns (bool) {
        return authorizerSet[isDelegateCall][role].contains(auth);
    }

    function getAuthorizer(bool isDelegateCall, bytes32 role, uint256 i) external view returns (address) {
        return authorizerSet[isDelegateCall][role].at(i);
    }

    /// @dev View function allow user to specify the range in case we have very big set
    ///      which can exhaust the gas of block limit when enumerating the entire list.
    function getAuthorizers(
        bool isDelegateCall,
        bytes32 role,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory auths) {
        uint256 authorizerSetSize = authorizerSet[isDelegateCall][role].length();
        if (end > authorizerSetSize) end = authorizerSetSize;
        auths = new address[](end - start);
        for (uint256 i = 0; i < end - start; i++) {
            auths[i] = authorizerSet[isDelegateCall][role].at(start + i);
        }
    }

    function getAllAuthorizers(bool isDelegateCall, bytes32 role) external view returns (address[] memory) {
        return authorizerSet[isDelegateCall][role].values();
    }

    function getAllRoles() external view returns (bytes32[] memory) {
        return roles.values();
    }
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
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

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseOwnable.sol";
import "Errors.sol";
import "IAuthorizer.sol";
import "IAccount.sol";
import "IRoleManager.sol";

/// @title BaseAuthorizer - A basic pausable authorizer with caller restriction.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Base contract to extend to implement specific authorizer.
abstract contract BaseAuthorizer is IAuthorizer, BaseOwnable {
    /// @dev Override such constants while extending BaseAuthorizer.

    bool public paused = false;

    // Often used for off-chain system.
    // Each contract instance has its own value.
    bytes32 public tag = "";

    // The caller which is able to call this contract's pre/postExecProcess
    // and pre/postExecCheck having side-effect.
    // It is usually the account or the parent authorizer(set) on higher level.
    address public caller;

    // This is the account this authorizer works for.
    // Currently used to lookup `roleManager`.
    // If not used it is OK to keep it unset.
    address public account;

    event CallerSet(address indexed caller);
    event AccountSet(address indexed account);
    event TagSet(bytes32 indexed tag);
    event PausedSet(bool indexed status);

    constructor(address _owner, address _caller) BaseOwnable(_owner) {
        caller = _caller;
    }

    function initialize(address _owner, address _caller) public {
        initialize(_owner);
        caller = _caller;
        emit CallerSet(_caller);
    }

    function initialize(address _owner, address _caller, address _account) public {
        initialize(_owner, _caller);
        account = _account;
        emit AccountSet(_account);
    }

    modifier onlyCaller() virtual {
        require(msg.sender == caller, Errors.INVALID_CALLER);
        _;
    }

    /// @notice Change the caller.
    /// @param _caller the caller which calls the authorizer.
    function setCaller(address _caller) external onlyOwner {
        caller = _caller;
        emit CallerSet(_caller);
    }

    /// @notice Change the account.
    /// @param _account the account which the authorizer get role manager from.
    function setAccount(address _account) external onlyOwner {
        account = _account;
        emit AccountSet(_account);
    }

    /// @notice Change the tag for the contract instance.
    /// @dev For off-chain index.
    /// @param _tag the tag
    function setTag(bytes32 _tag) external onlyOwner {
        tag = _tag;
        emit TagSet(_tag);
    }

    /// @notice Set the pause status. Authorizer just denies all when paused.
    /// @param _paused the paused status: true or false.
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PausedSet(_paused);
    }

    /// @notice Function check if a transaction can be executed.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @return authData Return check status, error message and hint (if needed)
    function preExecCheck(
        TransactionData calldata transaction
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _preExecCheck(transaction);
        }
    }

    /// @notice Check after transaction execution.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @param callResult Transaction call status and return data.
    function postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _postExecCheck(transaction, callResult, preData);
        }
    }

    /// @dev Perform actions before the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function preExecProcess(TransactionData calldata transaction) external virtual onlyCaller {
        if (!paused) _preExecProcess(transaction);
    }

    /// @dev Perform actions after the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) external virtual onlyCaller {
        if (!paused) _postExecProcess(transaction, callResult);
    }

    /// @dev Extract the roles of the delegate. If no roleManager set return empty lists.
    function _authenticate(TransactionData calldata transaction) internal view returns (bytes32[] memory roles) {
        return _authenticate(transaction.delegate);
    }

    function _authenticate(address delegate) internal view returns (bytes32[] memory roles) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        roles = IRoleManager(roleManager).getRoles(delegate);
    }

    /// @dev Call `roleManager` to validate the role of delegate.
    function _hasRole(TransactionData calldata transaction, bytes32 role) internal view returns (bool) {
        return _hasRole(transaction.delegate, role);
    }

    function _hasRole(address delegate, bytes32 role) internal view returns (bool) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        return IRoleManager(roleManager).hasRole(delegate, role);
    }

    /// @dev Override this to implement new authorization.
    ///      NOTE: If your check involves side-effect, onlyCaller should be used.
    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {}

    /// @dev Override this to implement new authorization.
    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual returns (AuthorizerReturnData memory) {}

    function _preExecProcess(TransactionData calldata transaction) internal virtual {}

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual {}

    /// @dev Override this if you implement new type of authorizer.
    function TYPE() external view virtual returns (bytes32) {
        return AuthType.COMMON;
    }
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Errors.sol";
import "BaseVersion.sol";

/// @title BaseOwnable - Provides simple ownership access control.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Can be used in both proxy and non-proxy mode.
abstract contract BaseOwnable is BaseVersion {
    address public owner;
    address public pendingOwner;
    bool private initialized = false;

    event PendingOwnerSet(address indexed to);
    event NewOwnerSet(address indexed owner);

    modifier onlyOwner() {
        require(owner == msg.sender, Errors.CALLER_IS_NOT_OWNER);
        _;
    }

    /// @dev `owner` is set by argument, thus the owner can any address.
    ///      When used in non-proxy mode, `initialize` can not be called
    ///      after deployment.
    constructor(address _owner) {
        initialize(_owner);
    }

    /// @dev When used in proxy mode, `initialize` can be called by anyone
    ///      to claim the ownership.
    ///      This function can be called only once.
    function initialize(address _owner) public {
        require(!initialized, Errors.ALREADY_INITIALIZED);
        _setOwner(_owner);
        initialized = true;
    }

    /// @notice User should ensure the corrent owner address set, or the
    ///         ownership may be transferred to blackhole. It is recommended to
    ///         take a safer way with setPendingOwner() + acceptOwner().
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New Owner is zero");
        _setOwner(newOwner);
    }

    /// @notice The original owner calls `setPendingOwner(newOwner)` and the new
    ///         owner calls `acceptOwner()` to take the ownership.
    function setPendingOwner(address to) external onlyOwner {
        pendingOwner = to;
        emit PendingOwnerSet(pendingOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        _setOwner(pendingOwner);
    }

    /// @notice Make the contract immutable.
    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    // Internal functions

    /// @dev Clear pendingOwner to prevent from reclaiming the ownership.
    function _setOwner(address _owner) internal {
        owner = _owner;
        pendingOwner = address(0);
        emit NewOwnerSet(owner);
    }
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

/// @dev Common errors. This helps reducing the contract size.
library Errors {
    // "E1";

    // Call/Static-call failed.
    string constant CALL_FAILED = "E2";

    // Argument's type not supported in View Variant.
    string constant INVALID_VIEW_ARG_SOL_TYPE = "E3";

    // Invalid length for variant raw data.
    string constant INVALID_VARIANT_RAW_DATA = "E4";

    // "E5";

    // Invalid variant type.
    string constant INVALID_VAR_TYPE = "E6";

    // Rule not exists
    string constant RULE_NOT_EXISTS = "E7";

    // Variant name not found.
    string constant VAR_NAME_NOT_FOUND = "E8";

    // Rule: v1/v2 solType mismatch
    string constant SOL_TYPE_MISMATCH = "E9";

    // "E10";

    // Invalid rule OP.
    string constant INVALID_RULE_OP = "E11";

    //  "E12";

    // "E13";

    //  "E14";

    // "E15";

    // "E16";

    // "E17";

    // "E18";

    // "E19";

    // "E20";

    // checkCmpOp: OP not support
    string constant CMP_OP_NOT_SUPPORT = "E21";

    // checkBySolType: Invalid op for bool
    string constant INVALID_BOOL_OP = "E22";

    // checkBySolType: Invalid op
    string constant CHECK_INVALID_OP = "E23";

    // Invalid solidity type.
    string constant INVALID_SOL_TYPE = "E24";

    // computeBySolType: invalid vm op
    string constant INVALID_VM_BOOL_OP = "E25";

    // computeBySolType: invalid vm arith op
    string constant INVALID_VM_ARITH_OP = "E26";

    // onlyCaller: Invalid caller
    string constant INVALID_CALLER = "E27";

    // "E28";

    // Side-effect is not allowed here.
    string constant SIDE_EFFECT_NOT_ALLOWED = "E29";

    // Invalid variant count for the rule op.
    string constant INVALID_VAR_COUNT = "E30";

    // extractCallData: Invalid op.
    string constant INVALID_EXTRACTOR_OP = "E31";

    // extractCallData: Invalid array index.
    string constant INVALID_ARRAY_INDEX = "E32";

    // extractCallData: No extract op.
    string constant NO_EXTRACT_OP = "E33";

    // extractCallData: No extract path.
    string constant NO_EXTRACT_PATH = "E34";

    // BaseOwnable: caller is not owner
    string constant CALLER_IS_NOT_OWNER = "E35";

    // BaseOwnable: Already initialized
    string constant ALREADY_INITIALIZED = "E36";

    // "E37";

    // "E38";

    // BaseACL: ACL check method should not return anything.
    string constant ACL_FUNC_RETURNS_NON_EMPTY = "E39";

    // "E40";

    // BaseAccount: Invalid delegate.
    string constant INVALID_DELEGATE = "E41";

    // RootAuthorizer: delegateCallAuthorizer not set
    string constant DELEGATE_CALL_AUTH_NOT_SET = "E42";

    // RootAuthorizer: callAuthorizer not set.
    string constant CALL_AUTH_NOT_SET = "E43";

    // BaseAccount: Authorizer not set.
    string constant AUTHORIZER_NOT_SET = "E44";

    // BaseAccount: Invalid authorizer flag.
    string constant INVALID_AUTHORIZER_FLAG = "E45";

    // BaseAuthorizer: Authorizer paused.
    string constant AUTHORIZER_PAUSED = "E46";

    // Authorizer set: Invalid hint.
    string constant INVALID_HINT = "E47";

    // Authorizer set: All auth deny.
    string constant ALL_AUTH_FAILED = "E48";

    // BaseACL: Method not allow.
    string constant METHOD_NOT_ALLOW = "E49";

    // AuthorizerUnionSet: Invalid hint collected.
    string constant INVALID_HINT_COLLECTED = "E50";

    // AuthorizerSet: Empty auth set
    string constant EMPTY_AUTH_SET = "E51";

    // AuthorizerSet: hint not implement.
    string constant HINT_NOT_IMPLEMENT = "E52";

    // RoleAuthorizer: Empty role set
    string constant EMPTY_ROLE_SET = "E53";

    // RoleAuthorizer: No auth for the role
    string constant NO_AUTH_FOR_THE_ROLE = "E54";

    // BaseACL: No in contract white list.
    string constant NOT_IN_CONTRACT_LIST = "E55";

    // BaseACL: Same process not allowed to install twice.
    string constant SAME_PROCESS_TWICE = "E56";

    // BaseAuthorizer: Account not set (then can not find roleManger)
    string constant ACCOUNT_NOT_SET = "E57";

    // BaseAuthorizer: roleManger not set
    string constant ROLE_MANAGER_NOT_SET = "E58";
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";

/// @title BaseVersion - Provides version information
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev
///    Implement NAME() and VERSION() methods according to IVersion interface.
///
///    Or just:
///      bytes32 public constant NAME = "<Your contract name>";
///      uint256 public constant VERSION = <Your contract version>;
///
///    Change the NAME when writing new kind of contract.
///    Change the VERSION when upgrading existing contract.
abstract contract BaseVersion is IVersion {
    /// @dev Convert to `string` which looks prettier on Etherscan viewer.
    function _NAME() external view virtual returns (string memory) {
        return string(abi.encodePacked(this.NAME()));
    }
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAuthorizer {
    function flag() external view returns (uint256 authFlags);

    function setCaller(address _caller) external;

    function preExecCheck(TransactionData calldata transaction) external returns (AuthorizerReturnData memory authData);

    function postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preAuthData
    ) external returns (AuthorizerReturnData memory authData);

    function preExecProcess(TransactionData calldata transaction) external;

    function postExecProcess(TransactionData calldata transaction, TransactionResult calldata callResult) external;
}

interface IAuthorizerSupportingHint is IAuthorizer {
    // When IAuthorizer(auth).flag().supportHint() == true;
    function collectHint(
        AuthorizerReturnData calldata preAuthData,
        AuthorizerReturnData calldata postAuthData
    ) external view returns (bytes memory hint);
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

enum AuthResult {
    FAILED,
    SUCCESS
}

struct CallData {
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra; // for future support: signatures etc.
}

struct TransactionData {
    address from; // Sender who performs the transaction a.k.a wallet address.
    address delegate; // Delegate who calls executeTransactions().
    // Same as CallData
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra;
}

struct AuthorizerReturnData {
    AuthResult result;
    string message;
    bytes data; // Authorizer return data. usually used for hint purpose.
}

struct TransactionResult {
    bool success; // Call status.
    bytes data; // Return/Revert data.
    bytes hint;
}

library TxFlags {
    uint256 internal constant DELEGATE_CALL_MASK = 0x1; // 1 for delegatecall, 0 for call

    function isDelegateCall(uint256 flag) internal pure returns (bool) {
        return flag & DELEGATE_CALL_MASK == DELEGATE_CALL_MASK;
    }
}

library VarName {
    bytes5 internal constant TEMP = "temp.";

    function isTemp(bytes32 name) internal pure returns (bool) {
        return bytes5(name) == TEMP;
    }
}

library AuthType {
    bytes32 internal constant FUNC = "FunctionType";
    bytes32 internal constant TRANSFER = "TransferType";
    bytes32 internal constant DEX = "DexType";
    bytes32 internal constant LENDING = "LendingType";
    bytes32 internal constant COMMON = "CommonType";
    bytes32 internal constant SET = "SetType";
    bytes32 internal constant VM = "VM";
}

library AuthFlags {
    uint256 internal constant HAS_PRE_CHECK_MASK = 0x1;
    uint256 internal constant HAS_POST_CHECK_MASK = 0x2;
    uint256 internal constant HAS_PRE_PROC_MASK = 0x4;
    uint256 internal constant HAS_POST_PROC_MASK = 0x8;

    uint256 internal constant SUPPORT_HINT_MASK = 0x40;

    uint256 internal constant FULL_MODE =
        HAS_PRE_CHECK_MASK | HAS_POST_CHECK_MASK | HAS_PRE_PROC_MASK | HAS_POST_PROC_MASK;

    function isValid(uint256 flag) internal pure returns (bool) {
        // At least one check handler is activated.
        return hasPreCheck(flag) || hasPostCheck(flag);
    }

    function hasPreCheck(uint256 flag) internal pure returns (bool) {
        return flag & HAS_PRE_CHECK_MASK == HAS_PRE_CHECK_MASK;
    }

    function hasPostCheck(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_CHECK_MASK == HAS_POST_CHECK_MASK;
    }

    function hasPreProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_PRE_PROC_MASK == HAS_PRE_PROC_MASK;
    }

    function hasPostProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_PROC_MASK == HAS_POST_PROC_MASK;
    }

    function supportHint(uint256 flag) internal pure returns (bool) {
        return flag & SUPPORT_HINT_MASK == SUPPORT_HINT_MASK;
    }
}

// For Rule VM.

// For each VariantType, an extractor should be implement.
enum VariantType {
    INVALID, // Mark for delete.
    EXTRACT_CALLDATA, // extract calldata by path bytes.
    NAME, // name for user-defined variant.
    RAW, // encoded solidity values.
    VIEW, // staticcall view non-side-effect function and get return value.
    CALL, // call state changing function and get returned value.
    RULE, // rule expression.
    ANY
}

// How the data should be decoded.
enum SolidityType {
    _invalid, // Mark for delete.
    _any,
    _bytes,
    _bool,
    ///// START 1
    ///// Generated by gen_rulelib.py (start)
    _address,
    _uint256,
    _int256,
    ///// Generated by gen_rulelib.py (end)
    ///// END 1
    _end
}

// A common operand in rule.
struct Variant {
    VariantType varType;
    SolidityType solType;
    bytes data;
}

// OpCode for rule expression which returns v0.
enum OP {
    INVALID,
    // One opnd.
    VAR, // v1
    NOT, // !v1
    // Two opnds.
    // checkBySolType() which returns boolean.
    EQ, // v1 == v2
    NE, // v1 != v2
    GT, // v1 > v2
    GE, // v1 >= v2
    LT, // v1 < v2
    LE, // v1 <= v2
    IN, // v1 in [...]
    NOTIN, // v1 not in [...]
    // computeBySolType() which returns bytes (with same solType)
    AND, // v1 & v2
    OR, // v1 | v2
    ADD, // v1 + v2
    SUB, // v1 - v2
    MUL, // v1 * v2
    DIV, // v1 / v2
    MOD, // v1 % v2
    // Three opnds.
    IF, // v1? v2: v3
    // Side-effect ones.
    ASSIGN, // v1 := v2
    VM, // rule list bytes.
    NOP // as end.
}

struct Rule {
    OP op;
    Variant[] vars;
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAccount {
    /// @notice Call Gnosis Safe to execute a transaction
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract
    ///      The function can only be called by delegates.
    /// @param callData The callData  to be called by Gnosis Safe
    function execTransaction(CallData calldata callData) external returns (TransactionResult memory result);

    function execTransactions(
        CallData[] calldata callDataList
    ) external returns (TransactionResult[] memory resultList);

    function setAuthorizer(address _authorizer) external;

    function setRoleManager(address _roleManager) external;

    function addDelegate(address _delegate) external;

    function addDelegates(address[] calldata _delegates) external;

    /// @dev Sub instance should override this to set `from` for transaction
    /// @return account The address for the contract wallet, also the
    ///         `msg.sender` address which send the transaction.
    function getAccountAddress() external view returns (address account);

    function roleManager() external view returns (address _roleManager);

    function authorizer() external view returns (address _authorizer);
}

// commit 5f44df01b85750d0fd9727dbcb77ceaafed3a7f4
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IRoleManager {
    function getRoles(address delegate) external view returns (bytes32[] memory);

    function hasRole(address delegate, bytes32 role) external view returns (bool);
}

interface IFlatRoleManager is IRoleManager {
    function addRoles(bytes32[] calldata roles) external;

    function grantRoles(bytes32[] calldata roles, address[] calldata delegates) external;

    function revokeRoles(bytes32[] calldata roles, address[] calldata delegates) external;

    function getDelegates() external view returns (address[] memory);

    function getAllRoles() external view returns (bytes32[] memory);
}