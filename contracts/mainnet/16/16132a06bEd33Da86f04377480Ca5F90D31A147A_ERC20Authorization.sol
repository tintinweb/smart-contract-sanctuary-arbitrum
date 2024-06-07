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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20Authorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_ERC20Authorization";
    int256 public constant VERSION = 1;

    string internal constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
    string internal constant ERC20_INCREASE_ALLOWANCE_FUNC = "increaseAllowance(address,uint256)";
    string internal constant ERC20_DECREASE_ALLOWANCE_FUNC = "decreaseAllowance(address,uint256)";
    bytes4 internal constant APPROVE_SELECTOR = 0x095ea7b3;
    bytes4 internal constant INCREASE_ALLOWANCE_SELECTOR = 0x39509351;
    bytes4 internal constant DECREASE_ALLOWANCE_SELECTOR = 0xa457c2d7;

    string internal constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";
    bytes4 internal constant TRANSFER_SELECTOR = 0xa9059cbb;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event TokenSpenderAdded(address indexed token, address indexed spender);
    event TokenReceiverAdded(address indexed token, address indexed receiver);

    struct TokenReceivers {
        address token;
        address[] receivers;
    }

    struct TokenSpenders {
        address token;
        address[] spenders;
    }

    address public safeAccount;

    string[] internal _approveFuncs;
    string[] internal _transferFuncs;

    EnumerableSet.AddressSet internal _tokenSet;

    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenSpenders;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenReceivers;

    constructor(
        address caller_,
        TokenSpenders[] memory tokenSpenders_,
        TokenReceivers[] memory tokenReceivers_
    ) FunctionAuthorization(caller_, Governable(caller_).governor()) {
        _approveFuncs = new string[](3);
        _approveFuncs[0] = ERC20_APPROVE_FUNC;
        _approveFuncs[1] = ERC20_INCREASE_ALLOWANCE_FUNC;
        _approveFuncs[2] = ERC20_DECREASE_ALLOWANCE_FUNC;
        _addTokenSpenders(tokenSpenders_);

        _transferFuncs = new string[](1);
        _transferFuncs[0] = ERC20_TRANSFER_FUNC;
        _addTokenReceivers(tokenReceivers_);
    }

    function addTokenSpenders(TokenSpenders[] calldata tokenSpendersList_) external virtual onlyGovernor {
        _addTokenSpenders(tokenSpendersList_);
    }

    function removeTokenSpenders(TokenSpenders[] calldata tokenSpendersList_) external virtual onlyGovernor {
        _removeTokenSpenders(tokenSpendersList_);
    }

    function addTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _addTokenReceivers(tokenReceiversList_);
    }

    function removeTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _removeTokenReceivers(tokenReceiversList_);
    }

    function removeToken(address token_) external virtual onlyGovernor {
        _removeToken(token_);
    }

    function _addTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _addTokenSpenders(_tokenSpendersList[i].token, _tokenSpendersList[i].spenders);
        }
    }

    function _removeTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _removeTokenSpenders(_tokenSpendersList[i].token, _tokenSpendersList[i].spenders);
        }
    }

    function _addTokenSpenders(address _token, address[] memory _spenders) internal virtual {
        if (_tokenSet.add(_token)) {
            emit TokenAdded(_token);
        }
        _addContractFuncs(_token, _approveFuncs);
        for (uint256 i = 0; i < _spenders.length; i++) {
            if (_allowedTokenSpenders[_token].add(_spenders[i])) {
                emit TokenSpenderAdded(_token, _spenders[i]);
            }
        }
    }

    function _removeTokenSpenders(address _token, address[] memory _spenders) internal virtual {
        for (uint256 i = 0; i < _spenders.length; i++) {
            if (_allowedTokenSpenders[_token].remove(_spenders[i])) {
                emit TokenSpenderAdded(_token, _spenders[i]);
            }
        }
    }

    function _addTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _addTokenReceivers(_tokenReceiversList[i].token, _tokenReceiversList[i].receivers);
        }
    }

    function _removeTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _removeTokenReceivers(_tokenReceiversList[i].token, _tokenReceiversList[i].receivers);
        }
    }

    function _addTokenReceivers(address _token, address[] memory _receivers) internal virtual {
        if (_tokenSet.add(_token)) {
            emit TokenAdded(_token);
        }
        _addContractFuncs(_token, _transferFuncs);
        for (uint256 i = 0; i < _receivers.length; i++) {
            if (_allowedTokenReceivers[_token].add(_receivers[i])) {
                emit TokenReceiverAdded(_token, _receivers[i]);
            }
        }
    }

    function _removeTokenReceivers(address _token, address[] memory _receivers) internal virtual {
        for (uint256 i = 0; i < _receivers.length; i++) {
            if (_allowedTokenReceivers[_token].remove(_receivers[i])) {
                emit TokenReceiverAdded(_token, _receivers[i]);
            }
        }
    }

    function _removeToken(address _token) internal virtual {
        _removeTokenSpenders(_token, _allowedTokenSpenders[_token].values());
        _removeTokenReceivers(_token, _allowedTokenReceivers[_token].values());
        if (_tokenSet.remove(_token)) {
            _removeContractFuncs(_token, _approveFuncs);
            _removeContractFuncs(_token, _transferFuncs);
            emit TokenRemoved(_token);
        }
    }

    function getAllTokens() external view returns (address[] memory) {
        return _tokenSet.values();
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return _allowedTokenSpenders[token].values();
    }

    function getTokenReceivers(address token) external view returns (address[] memory) {
        return _allowedTokenReceivers[token].values();
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        result = super._authorizationCheckTransaction(txData_);
        if (result.success) {
            bytes4 selector = _getSelector(txData_.data);
            if (selector == TRANSFER_SELECTOR) {
                (address receiver, /* uint256 value */ ) = abi.decode(txData_.data[4:], (address, uint256));
                if (!_allowedTokenReceivers[txData_.to].contains(receiver)) {
                    result.success = false;
                    result.message = "ERC20Authorization: ERC20 receiver not allowed";
                }
            } else if (selector == APPROVE_SELECTOR || selector == INCREASE_ALLOWANCE_SELECTOR || selector == DECREASE_ALLOWANCE_SELECTOR) {
                (address spender, /* uint256 allowance */ ) = abi.decode(txData_.data[4:], (address, uint256));
                if (!_allowedTokenSpenders[txData_.to].contains(spender)) {
                    result.success = false;
                    result.message = "ERC20Authorization: ERC20 spender not allowed";
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Type} from "./Type.sol";
import {IBaseACL} from "./IBaseACL.sol";

abstract contract BaseACL is IBaseACL, IERC165 {
    address public caller;
    address public safeAccount;
    address public solvGuard;

    fallback() external {}

    constructor(address caller_) {
        caller = caller_;
    }

    modifier onlyCaller() virtual {
        require(msg.sender == caller, "onlyCaller");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBaseACL).interfaceId;
    }

    function preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        external
        virtual
        onlyCaller
        returns (Type.CheckResult memory result_)
    {
        result_ = _preCheck(from_, to_, data_, value_);
    }

    function _preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        internal
        virtual
        returns (Type.CheckResult memory result_)
    {
        (bool success, bytes memory revertData) =
            address(this).staticcall(_packTxn(Type.TxData(from_, to_, value_, data_)));
        result_ = _parseReturnData(success, revertData);
    }

    function _parseReturnData(bool success, bytes memory revertData)
        internal
        pure
        returns (Type.CheckResult memory result_)
    {
        if (success) {
            // ACL checking functions should not return any bytes which differs from normal view functions.
            require(revertData.length == 0, "ACL Function return non empty");
            result_.success = true;
        } else {
            if (revertData.length < 68) {
                // 8(bool) + 32(length)
                result_.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                result_.message = abi.decode(revertData, (string));
            }
        }
    }

    function _packTxn(Type.TxData memory txData_) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(txData_);
        bytes memory callDataSize = abi.encode(txData_.data.length);
        return abi.encodePacked(txData_.data, txnData, callDataSize);
    }

    function _unpackTxn() internal view virtual returns (Type.TxData memory txData_) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        txData_ = abi.decode(msg.data[callDataSize:], (Type.TxData));
    }

    function _txn() internal view virtual returns (Type.TxData memory) {
        return _unpackTxn();
    }

    function _checkValueZero() internal view virtual {
        require(_txn().value == 0, "Value not zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {Type} from "./Type.sol";
import {IBaseAuthorization} from "./IBaseAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

abstract contract BaseAuthorization is IBaseAuthorization, Governable, IERC165 {
    address public caller;

    modifier onlyCaller() {
        require(msg.sender == caller, "BaseAuthorization: only caller");
        _;
    }

    constructor(address caller_, address governor_) Governable(governor_) {
        caller = caller_;
    }

    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBaseAuthorization).interfaceId;
    }

    function authorizationCheckTransaction(Type.TxData calldata txData_)
        external
        virtual
        onlyCaller
        returns (Type.CheckResult memory)
    {
        return _authorizationCheckTransaction(txData_);
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        returns (Type.CheckResult memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {BaseAuthorization} from "../common/BaseAuthorization.sol";
import {IBaseACL} from "../common/IBaseACL.sol";
import {BaseACL} from "../common/BaseACL.sol";
import {Multicall} from "../utils/Multicall.sol";

abstract contract FunctionAuthorization is BaseAuthorization, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddContractFunc(address indexed contract_, string func_, address indexed sender_);
    event AddContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event RemoveContractFunc(address indexed contract_, string func_, address indexed sender_);
    event RemoveContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event SetContractACL(address indexed contract_, address indexed acl_, address indexed sender_);

    EnumerableSet.AddressSet internal _contracts;
    mapping(address => EnumerableSet.Bytes32Set) internal _allowedContractToFunctions;
    mapping(address => address) internal _contractACL;

    constructor(address caller_, address governor_) BaseAuthorization(caller_, governor_) {}

    function _addContractFuncsWithACL(address contract_, address acl_, string[] memory funcList_) 
        internal 
        virtual 
    {
        _addContractFuncs(contract_, funcList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function _addContractFuncsSigWithACL(address contract_, address acl_, bytes4[] calldata funcSigList_)
        internal
        virtual
    {
        _addContractFuncsSig(contract_, funcSigList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function getAllContracts() public view virtual returns (address[] memory) {
        return _contracts.values();
    }

    function getFunctionsByContract(address contract_) public view virtual returns (bytes32[] memory) {
        return _allowedContractToFunctions[contract_].values();
    }

    function getACLByContract(address contract_) external view virtual returns (address) {
        return _contractACL[contract_];
    }

    function _addContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFunc(contract_, funcList_[index], msg.sender);
                emit AddContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _addContractFuncsSig(address contract_, bytes4[] memory funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _removeContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFunc(contract_, funcList_[index], msg.sender);
                emit RemoveContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _setContractACL(address contract_, address acl_) internal virtual {
        require(_contracts.contains(contract_), "FunctionAuthorization: contract not exist");
        if (acl_ != address(0)) {
            require(
                IERC165(acl_).supportsInterface(type(IBaseACL).interfaceId),
                "FunctionAuthorization: acl_ is not IBaseACL"
            );
        }
        _contractACL[contract_] = acl_;
        emit SetContractACL(contract_, acl_, msg.sender);
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result_)
    {
        if (_contracts.contains(txData_.to)) {
            bytes4 selector = _getSelector(txData_.data);
            if (_isAllowedSelector(txData_.to, selector)) {
                result_.success = true;
                // further check acl if contract is authorized
                address acl = _contractACL[txData_.to];
                if (acl != address(0)) {
                    try BaseACL(acl).preCheck(txData_.from, txData_.to, txData_.data, txData_.value) returns (
                        Type.CheckResult memory aclCheckResult
                    ) {
                        return aclCheckResult;
                    } catch Error(string memory reason) {
                        result_.success = false;
                        result_.message = reason;
                    } catch (bytes memory reason) {
                        result_.success = false;
                        result_.message = string(reason);
                    }
                }
            } else {
                result_.success = false;
                result_.message = "FunctionAuthorization: not allowed function";
            }
        } else {
            result_.success = false;
            result_.message = "FunctionAuthorization: not allowed contract";
        }
        
    }

    function _isAllowedSelector(address target_, bytes4 selector_) internal view virtual returns (bool) {
        return _allowedContractToFunctions[target_].contains(selector_);
    }

    function _getSelector(bytes calldata data_) internal pure virtual returns (bytes4 selector_) {
        assembly {
            selector_ := calldataload(data_.offset)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Type} from "./Type.sol";

interface IBaseACL {
    function preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        external
        returns (Type.CheckResult memory result_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Type} from "./Type.sol";

interface IBaseAuthorization {
    function authorizationCheckTransaction(Type.TxData calldata txData_) external returns (Type.CheckResult memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Type {
	struct TxData {
		address from; //msg.sender
		address to;
		uint256 value;
		bytes data; //calldata
	}

	struct CheckResult {
		bool success;
		string message;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Governable {
    
    event NewGovernor(address indexed previousGovernor, address indexed newGovernor);
	event NewPendingGovernor(address indexed previousPendingGovernor, address indexed newPendingGovernor);

    address public governor;
	address public pendingGovernor;

    bool public governanceAllowed = true;

    modifier onlyGovernor() {
        require(governanceAllowed && governor == msg.sender, "Governable: only governor");
        _;
    }

	modifier onlyPendingGovernor() {
		require(pendingGovernor == msg.sender, "Governable: only pending governor");
		_;
	}

	constructor(address governor_) {
		governor = governor_;
        emit NewGovernor(address(0), governor_);
	}

    function forbidGovernance() external onlyGovernor {
        governanceAllowed = false;
    }

    function transferGovernance(address newPendingGovernor_) external virtual onlyGovernor {
        emit NewPendingGovernor(pendingGovernor, newPendingGovernor_);
		pendingGovernor = newPendingGovernor_;
    }

	function acceptGovernance() external virtual onlyPendingGovernor {
		emit NewGovernor(governor, pendingGovernor);
		governor = pendingGovernor;
		delete pendingGovernor;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Multicall {
	/**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                _revertWithParsedMessage(result);
            }

            results[i] = result;
        }

        return results;
    }

	  function _revertWithParsedMessage(bytes memory result) internal pure {
        (string memory revertMessage, bool hasRevertMessage) = _getRevertMessage(result);

        if (hasRevertMessage) {
            revert(revertMessage);
        } else {
            _revertWithCustomError(result);
        }
    }

    function _revertWithCustomError(bytes memory result) internal pure {
        // referenced from https://ethereum.stackexchange.com/a/123588
        uint256 length = result.length;
        assembly {
            revert(add(result, 0x20), length)
        }
    }

	 // To get the revert reason, referenced from https://ethereum.stackexchange.com/a/83577
    function _getRevertMessage(bytes memory result) internal pure returns (string memory, bool) {
        // If the result length is less than 68, then the transaction either panicked or failed silently
        if (result.length < 68) {
            return ("", false);
        }

        bytes4 errorSelector = _getErrorSelectorFromData(result);

        // 0x08c379a0 is the selector for Error(string)
        // referenced from https://blog.soliditylang.org/2021/04/21/custom-errors/
        if (errorSelector == bytes4(0x08c379a0)) {
            assembly {
                result := add(result, 0x04)
            }

            return (abi.decode(result, (string)), true);
        }

        // error may be a custom error, return an empty string for this case
        return ("", false);
    }


    function _getErrorSelectorFromData(bytes memory data) internal pure returns (bytes4) {
        bytes4 errorSelector;

        assembly {
            errorSelector := mload(add(data, 0x20))
        }

        return errorSelector;
    }

}