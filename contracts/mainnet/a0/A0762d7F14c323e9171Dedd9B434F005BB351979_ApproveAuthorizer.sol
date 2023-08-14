// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseACL.sol";

/// @title ApproveAuthorizer - Manages ERC20/ETH approve permissons.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice This checks token-spender pairs, no value is restricted.
contract ApproveAuthorizer is BaseAuthorizer {
    bytes32 public constant NAME = "ApproveAuthorizer";
    uint256 public constant VERSION = 1;
    bytes32 public constant override TYPE = AuthType.APPROVE;
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    // function approve(address spender, uint256 value)
    bytes4 constant APPROVE_SELECTOR = 0x095ea7b3;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet tokenSet;

    mapping(address => EnumerableSet.AddressSet) tokenToSpenders;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    event TokenSpenderAdded(address indexed token, address indexed spender);
    event TokenSpenderRemoved(address indexed token, address indexed spender);

    struct TokenSpender {
        address token;
        address spender;
    }

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// @notice Add token-receiver pairs.
    function addTokenSpenders(TokenSpender[] calldata tokenSpenders) external onlyOwner {
        for (uint i = 0; i < tokenSpenders.length; i++) {
            address token = tokenSpenders[i].token;
            address spender = tokenSpenders[i].spender;
            if (tokenSet.add(token)) {
                emit TokenAdded(token);
            }

            if (tokenToSpenders[token].add(spender)) {
                emit TokenSpenderAdded(token, spender);
            }
        }
    }

    function removeTokenSpenders(TokenSpender[] calldata tokenSpenders) external onlyOwner {
        for (uint i = 0; i < tokenSpenders.length; i++) {
            address token = tokenSpenders[i].token;
            address spender = tokenSpenders[i].spender;
            if (tokenToSpenders[token].remove(spender)) {
                emit TokenSpenderRemoved(token, spender);
                if (tokenToSpenders[token].length() == 0) {
                    if (tokenSet.remove(token)) {
                        emit TokenRemoved(token);
                    }
                }
            }
        }
    }

    // View functions.

    function getAllToken() external view returns (address[] memory) {
        return tokenSet.values();
    }

    /// @dev View function allow user to specify the range in case we have very big token set
    ///      which can exhaust the gas of block limit.
    function getTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        uint256 size = tokenSet.length();
        if (end > size) end = size;
        require(start < end, "start >= end");
        address[] memory _tokens = new address[](end - start);
        for (uint i = 0; i < end - start; i++) {
            _tokens[i] = tokenSet.at(start + i);
        }
        return _tokens;
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return tokenToSpenders[token].values();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (
            transaction.data.length >= 68 && // 4 + 32 + 32
            bytes4(transaction.data[0:4]) == APPROVE_SELECTOR &&
            transaction.value == 0
        ) {
            (address spender /*uint256 value*/, ) = abi.decode(transaction.data[4:], (address, uint256));
            address token = transaction.to;
            if (tokenToSpenders[token].contains(spender)) {
                authData.result = AuthResult.SUCCESS;
                return authData;
            }
        }
        authData.result = AuthResult.FAILED;
        authData.message = "approve not allowed";
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }
}

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title BaseACL - Basic ACL template which uses the call-self trick to perform function and parameters check.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Steps to extend this:
///        1. Set the NAME, VERSION, TYPE.
///        2. Write ACL functions according the target contract.
///        3. Add a constructor. eg:
///           `constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}`
///        4. Override `contracts()` to only target contracts that you checks. Transactions
////          whose `to` address is not in the list will revert.
///        5. (Optional) If state changing operation in the checking method is required,
///           override `_preExecCheck()` to change `staticcall` to `call`.
///
///      NOTE for ACL developers:
///        1. The checking functions can be defined extractly the same as the target method
///           to control thus developers do not bother to write a lot `abi.decode` code.
///        2. Checking funtions should NOT contain return value, use `require` to perform check.
///        3. BaseACL may serve for multiple target contracts.
///            - Implement contracts() to manage the target contracts set.
///            - Use `onlyContract` modifier or check `_txn().to` in checking functions.
///        4. `onlyOwner` modifier should be used for customized setter functions.

abstract contract BaseACL is BaseAuthorizer {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev Set such constants in sub contract.
    // bytes32 public constant NAME = "BaseACL";
    // bytes32 public constant override TYPE = "ACLType";
    // uint256 public constant VERSION = 0;

    /// Only preExecCheck is used in BaseACL and hint is not supported.
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// Internal functions.
    function _parseReturnData(
        bool success,
        bytes memory revertData
    ) internal pure returns (AuthorizerReturnData memory authData) {
        if (success) {
            // ACL checking functions should not return any bytes which differs from normal view functions.
            require(revertData.length == 0, Errors.ACL_FUNC_RETURNS_NON_EMPTY);
            authData.result = AuthResult.SUCCESS;
        } else {
            if (revertData.length < 68) {
                // 4(Error sig) + 32(offset) + 32(length)
                authData.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                authData.message = abi.decode(revertData, (string));
            }
        }
    }

    function _contractCheck(TransactionData calldata transaction) internal virtual returns (bool result) {
        // This works as a catch-all check. Sample but safer.
        address to = transaction.to;
        address[] memory _contracts = contracts();
        for (uint i = 0; i < _contracts.length; i++) {
            if (to == _contracts[i]) return true;
        }
        return false;
    }

    function _packTxn(TransactionData calldata transaction) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(transaction);
        bytes memory callDataSize = abi.encode(transaction.data.length);
        return abi.encodePacked(transaction.data, txnData, callDataSize);
    }

    function _unpackTxn() internal pure virtual returns (TransactionData memory transaction) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        transaction = abi.decode(msg.data[callDataSize:], (TransactionData));
    }

    // @dev Only valid in self-call checking functions.
    function _txn() internal pure virtual returns (TransactionData memory transaction) {
        return _unpackTxn();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (!_contractCheck(transaction)) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.NOT_IN_CONTRACT_LIST;
            return authData;
        }
        (bool success, bytes memory revertData) = address(this).staticcall(_packTxn(transaction));
        return _parseReturnData(success, revertData);
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }

    // Internal view functions.

    // Utilities for checking functions.
    function _checkRecipient(address _recipient) internal view {
        require(_recipient == _txn().from, "Invalid recipient");
    }

    function _checkContract(address _contract) internal view {
        require(_contract == _txn().to, "Invalid contract");
    }

    // Modifiers.

    modifier onlyContract(address _contract) {
        _checkContract(_contract);
        _;
    }

    modifier nonPayable() {
        require(_txn().value == 0, "Invalid tx value");
        _;
    }

    /// External functions

    /// @dev Implement your own access control checking functions here.

    // example:

    // function transfer(address to, uint256 amount)
    //     onlyContract(USDT_ADDR)
    //     external view
    // {
    //     require(amount > 0 & amount < 10000, "amount not in range");
    // }

    /// @dev Override this cause it is used by `_preExecCheck`.
    /// @notice Target contracts this BaseACL controls.
    function contracts() public view virtual returns (address[] memory _contracts) {}

    fallback() external virtual {
        revert(Errors.METHOD_NOT_ALLOW);
    }
}

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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
    // Currently only used to lookup `roleManager`.
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
        require(_caller != address(0), "Invalid caller");
        caller = _caller;
        emit CallerSet(_caller);
    }

    /// @notice Change the account.
    /// @param _account the account which the authorizer get role manager from.
    function setAccount(address _account) external onlyOwner {
        require(_account != address(0), "Invalid account");
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

    /// @dev `onlyCaller` check is forced on pre/post Check/Process handlers
    ///       to prevent attackers from polluting our data by calling this directly.

    /// @notice Check if the transaction can be executed.
    /// @return authData Return check status, error message and other data.
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
    function preExecProcess(TransactionData calldata transaction) external virtual onlyCaller {
        if (!paused) _preExecProcess(transaction);
    }

    /// @dev Perform actions after the transaction execution.
    function postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) external virtual onlyCaller {
        if (!paused) _postExecProcess(transaction, callResult);
    }

    /// @dev Extract the roles of the delegate. If no roleManager set return empty lists.

    function _getRoleManager() internal view returns (address roleManager) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
    }

    function _getRoles(TransactionData calldata transaction) internal view returns (bytes32[] memory roles) {
        address roleManager = _getRoleManager();
        roles = IRoleManager(roleManager).getRoles(transaction.delegate);
    }

    /// @dev Call `roleManager` to validate the role of delegate.
    function _hasRole(TransactionData calldata transaction, bytes32 role) internal view returns (bool) {
        address roleManager = _getRoleManager();
        return IRoleManager(roleManager).hasRole(transaction.delegate, role);
    }

    /// @dev Override these functions to while extending this contract.
    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {}

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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Errors.sol";
import "BaseVersion.sol";

/// @title BaseOwnable - Simple ownership access control contract.
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
        require(!initialized, "Already initialized");
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

struct CallData {
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra; // for future support: signatures etc.
}

struct TransactionData {
    address from; // `msg.sender` who performs the transaction a.k.a wallet address.
    address delegate; // Delegate who calls executeTransactions().
    // Same as CallData
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra;
}

/// @dev Use enum instead of bool in case of when other status, like PENDING,
///      is needed in the future.
enum AuthResult {
    FAILED,
    SUCCESS
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
    uint256 internal constant ALLOW_REVERT_MASK = 0x2; // 1 for allow, 0 for not

    function isDelegateCall(uint256 flag) internal pure returns (bool) {
        return flag & DELEGATE_CALL_MASK > 0;
    }

    function allowsRevert(uint256 flag) internal pure returns (bool) {
        return flag & ALLOW_REVERT_MASK > 0;
    }
}

library AuthType {
    bytes32 internal constant FUNC = "FunctionType";
    bytes32 internal constant TRANSFER = "TransferType";
    bytes32 internal constant APPROVE = "ApproveType";
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
        return flag & HAS_PRE_CHECK_MASK > 0;
    }

    function hasPostCheck(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_CHECK_MASK > 0;
    }

    function hasPreProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_PRE_PROC_MASK > 0;
    }

    function hasPostProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_PROC_MASK > 0;
    }

    function supportHint(uint256 flag) internal pure returns (bool) {
        return flag & SUPPORT_HINT_MASK > 0;
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

library VarName {
    bytes5 internal constant TEMP = "temp.";

    function isTemp(bytes32 name) internal pure returns (bool) {
        return bytes5(name) == TEMP;
    }
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAccount {
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

// commit b6c3fbfce7de808c18de3897cd6e6243710e18b6
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