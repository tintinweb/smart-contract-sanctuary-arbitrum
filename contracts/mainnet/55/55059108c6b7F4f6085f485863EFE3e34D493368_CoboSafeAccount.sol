// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseAccount.sol";

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);
}

/// @title CoboSafeAccount - A GnosisSafe module that implements customized access control
/// @author Cobo Safe Dev Team https://www.cobo.com/
contract CoboSafeAccount is BaseAccount {
    using TxFlags for uint256;

    bytes32 public constant NAME = "CoboSafeAccount";
    uint256 public constant VERSION = 1;

    constructor(address _owner) BaseAccount(_owner) {}

    /// @notice The safe of the CoboSafeAccount.
    function safe() public view returns (address) {
        return owner;
    }

    /// @dev Execute the transaction from the safe.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal override returns (TransactionResult memory result) {
        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        (result.success, result.data) = IGnosisSafe(payable(safe())).execTransactionFromModuleReturnData(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.flag.isDelegateCall() ? Enum.Operation.DelegateCall : Enum.Operation.Call
        );
    }

    /// @dev Account address is the safe address.
    function _getAccountAddress() internal view override returns (address account) {
        account = safe();
    }
}

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "Types.sol";
import "BaseOwnable.sol";
import "IAuthorizer.sol";
import "IRoleManager.sol";
import "IAccount.sol";

/// @title BaseAccount - A basic smart contract wallet with access control supported.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Extend this and implement `_executeTransaction()` and `_getFromAddress()`.
abstract contract BaseAccount is IAccount, BaseOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    address public roleManager;
    address public authorizer;

    // Simple and basic delegate check.
    EnumerableSet.AddressSet delegates;

    event RoleManagerSet(address indexed roleManager);
    event AuthorizerSet(address indexed authorizer);
    event DelegateAdded(address indexed delegate);
    event DelegateRemoved(address indexed delegate);
    event TransactionExecuted(
        address indexed to,
        bytes4 indexed selector,
        uint256 indexed value,
        TransactionData transaction
    );

    /// @dev RoleManager need BaseAccount to create thus we can not init it in constructor
    /// @param _owner Who owns the wallet.
    constructor(address _owner) BaseOwnable(_owner) {}

    /// @dev Only used in proxy mode. Can be called only once.
    function initialize(address _owner, address _roleManager, address _authorizer) public {
        initialize(_owner);
        _setRoleManager(_roleManager);
        _setAuthorizer(_authorizer);
    }

    /// Modifiers

    /// @dev Only added delegates are allowed to call `execTransaction`. This provides a kind
    ///      of catch-all rule and simple but strong protection from malicious/compromised/buggy
    ///      authorizers which permits any operations.
    modifier onlyDelegate() {
        require(hasDelegate(msg.sender), Errors.INVALID_DELEGATE);
        _;
    }

    // Public/External functions.
    function setRoleManager(address _roleManager) external onlyOwner {
        _setRoleManager(_roleManager);
    }

    function setAuthorizer(address _authorizer) external onlyOwner {
        _setAuthorizer(_authorizer);
    }

    function addDelegate(address _delegate) external onlyOwner {
        _addDelegate(_delegate);
    }

    function addDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _addDelegate(_delegates[i]);
        }
    }

    function removeDelegate(address _delegate) external onlyOwner {
        _removeDelegate(_delegate);
    }

    function removeDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _removeDelegate(_delegates[i]);
        }
    }

    /// @notice Called by authenticated delegates to execute transaction on behalf of the wallet account.
    /// @param callData A structure contains `to`, `value`, `data`.
    function execTransaction(
        CallData calldata callData
    ) external onlyDelegate returns (TransactionResult memory result) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;
        transaction.flag = callData.flag;
        transaction.to = callData.to;
        transaction.value = callData.value;
        transaction.data = callData.data;
        transaction.hint = callData.hint;
        transaction.extra = callData.extra;

        result = _executeTransactionWithCheck(transaction);
        emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
    }

    /// @notice A Multicall method.
    /// @param callDataList `CallData` array to execute in sequence.
    function execTransactions(
        CallData[] calldata callDataList
    ) external onlyDelegate returns (TransactionResult[] memory resultList) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;

        resultList = new TransactionResult[](callDataList.length);

        for (uint256 i = 0; i < callDataList.length; i++) {
            CallData calldata callData = callDataList[i];
            transaction.to = callData.to;
            transaction.value = callData.value;
            transaction.data = callData.data;
            transaction.flag = callData.flag;
            transaction.hint = callData.hint;
            transaction.extra = callData.extra;

            resultList[i] = _executeTransactionWithCheck(transaction);

            emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
        }
    }

    /// External view functions.

    function hasDelegate(address _delegate) public view returns (bool) {
        return delegates.contains(_delegate);
    }

    function getAllDelegates() external view returns (address[] memory) {
        return delegates.values();
    }

    /// @notice The real address of your smart contract wallet address where
    ///         stores your assets and sends transactions from.
    function getAccountAddress() external view returns (address account) {
        account = _getAccountAddress();
    }

    /// Internal functions.

    function _addDelegate(address _delegate) internal {
        if (delegates.add(_delegate)) {
            emit DelegateAdded(_delegate);
        }
    }

    function _removeDelegate(address _delegate) internal {
        if (delegates.remove(_delegate)) {
            emit DelegateRemoved(_delegate);
        }
    }

    function _setRoleManager(address _roleManager) internal {
        roleManager = _roleManager;
        emit RoleManagerSet(_roleManager);
    }

    function _setAuthorizer(address _authorizer) internal {
        authorizer = _authorizer;
        emit AuthorizerSet(_authorizer);
    }

    /// @dev Override this if we prefer not to revert the entire transaction in
    //       out wallet contract implementation.
    function _preExecCheck(
        TransactionData memory transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        authData = IAuthorizer(authorizer).preExecCheck(transaction);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _revertIfTxFails(TransactionResult memory callResult) internal pure {
        bool success = callResult.success;
        bytes memory data = callResult.data;
        if (!success) {
            assembly {
                revert(add(data, 32), data)
            }
        }
    }

    function _postExecCheck(
        TransactionData memory transaction,
        TransactionResult memory callResult,
        AuthorizerReturnData memory predata
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        _revertIfTxFails(callResult);
        authData = IAuthorizer(authorizer).postExecCheck(transaction, callResult, predata);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _preExecProcess(TransactionData memory transaction) internal virtual {
        IAuthorizer(authorizer).preExecProcess(transaction);
    }

    function _postExecProcess(
        TransactionData memory transaction,
        TransactionResult memory callResult
    ) internal virtual {
        IAuthorizer(authorizer).postExecProcess(transaction, callResult);
    }

    function _executeTransactionWithCheck(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result) {
        require(authorizer != address(0), Errors.AUTHORIZER_NOT_SET);
        uint256 flag = IAuthorizer(authorizer).flag();
        bool doCollectHint = transaction.hint.length == 0;

        // Ensures either _preExecCheck or _postExecCheck (or both) will run.
        require(flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        // 1. Do pre check, revert the entire txn if failed.
        AuthorizerReturnData memory preData;
        if (doCollectHint || flag.hasPreCheck()) {
            // Always run _preExecCheck When collecting hint.
            // If not collecting hint, only run if the sub authorizer requires.
            preData = _preExecCheck(transaction);
        }

        // 2. Do pre process.
        if (flag.hasPreProcess()) _preExecProcess(transaction);

        // 3. Execute the transaction.
        result = _executeTransaction(transaction);

        // 4. Do post check, revert the entire txn if failed.
        AuthorizerReturnData memory postData;
        if (doCollectHint || flag.hasPostCheck()) {
            postData = _postExecCheck(transaction, result, preData);
        }

        // 5. Do post process.
        if (flag.hasPostProcess()) _postExecProcess(transaction, result);

        // 6. Collect hint if when (1) no hint provided and (2) the authorizer supports hint mode.
        if (doCollectHint && flag.supportHint()) {
            result.hint = IAuthorizerSupportingHint(authorizer).collectHint(preData, postData);
        }
    }

    /// @dev Instance should implement at least two `virtual` function below.

    /// @param transaction Transaction to execute.
    /// @return result `TransactionResult` which contains call status and return/revert data.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result);

    /// @dev The address of wallet which sends the transaction a.k.a `msg.sender`
    function _getAccountAddress() internal view virtual returns (address account);

    // To receive ETH as a wallet.
    receive() external payable {}
}

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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

// commit 4a1e464ba0e7d0bc60b79fcbe742d43c6c344f2a
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