// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EnumerableSet } from
    "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SickleMultisig {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Data structures

    struct Proposal {
        address[] targets;
        bytes[] calldatas;
        string description;
    }

    struct Transaction {
        // Calls to be executed in the transaction
        Proposal proposal;
        // Transaction state
        bool exists;
        bool executed;
        bool cancelled;
        // Settings nonce that the transaction was created with
        uint256 settingsNonce;
        // Signing state
        uint256 signatures;
        mapping(address => bool) signed;
    }

    // Errors

    error NotASigner();
    error NotMultisig();

    error InvalidProposal();
    error InvalidThreshold();

    error TransactionDoesNotExist();
    error TransactionNotReadyToExecute();
    error TransactionNoLongerValid();
    error TransactionAlreadyExists();
    error TransactionAlreadySigned();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyCancelled();

    error SignerAlreadyAdded();
    error SignerAlreadyRemoved();
    error SignerCannotBeRemoved();

    // Events

    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    event ThresholdChanged(uint256 newThreshold);

    event TransactionProposed(uint256 proposalId, address signer);
    event TransactionSigned(uint256 proposalId, address signer);
    event TransactionExecuted(uint256 proposalId, address signer);
    event TransactionCancelled(uint256 proposalId, address signer);

    // Public storage

    uint256 public threshold;
    uint256 public settingsNonce;
    mapping(uint256 => Transaction) public transactions;

    // Initialization

    constructor(address initialSigner) {
        // Initialize with only a single signer and a threshold of 1. The signer
        // can add more signers and update the threshold using a proposal.
        _addSigner(initialSigner);
        _setThreshold(1);
    }

    // Signer-only actions

    /// @notice Propose a new transaction to be executed from the multisig
    /// @custom:access Restricted to multisig signers.
    function propose(Proposal memory proposal)
        public
        onlySigner
        returns (uint256)
    {
        return _propose(proposal);
    }

    /// @notice Sign a transaction
    /// @custom:access Restricted to multisig signers.
    function sign(uint256 proposalId) public onlySigner {
        _sign(proposalId);
    }

    /// @notice Cancel a transaction that hasn't been executed or invalidated
    /// @custom:access Restricted to multisig signers.
    function cancel(uint256 proposalId) public onlySigner {
        _cancel(proposalId);
    }

    /// @notice Execute a transaction that has passed the signatures threshold
    /// @custom:access Restricted to multisig signers.
    function execute(uint256 proposalId) public onlySigner {
        _execute(proposalId);
    }

    // Multisig-only actions

    /// @notice Add a signer to the multisig
    /// @custom:access Restricted to multisig transactions.
    function addSigner(address signer) public onlyMultisig {
        _addSigner(signer);
    }

    /// @notice Remove a signer from the multisig
    /// @custom:access Restricted to multisig transactions.
    function removeSigner(address signer) public onlyMultisig {
        _removeSigner(signer);
    }

    /// @notice Remove a signer from the multisig
    /// @custom:access Restricted to multisig transactions.
    function replaceSigner(
        address oldSigner,
        address newSigner
    ) public onlyMultisig {
        _addSigner(newSigner);
        _removeSigner(oldSigner);
    }

    /// @notice Set a new signatures threshold for the multisig
    /// @custom:access Restricted to multisig transactions.
    function setThreshold(uint256 newThreshold) public onlyMultisig {
        _setThreshold(newThreshold);
    }

    // Public functions

    function signerCount() public view returns (uint256) {
        return _signers.length();
    }

    function signerAddresses() public view returns (address[] memory) {
        return _signers.values();
    }

    function isSigner(address signer) public view returns (bool) {
        return _signers.contains(signer);
    }

    function hashProposal(Proposal memory proposal)
        public
        view
        returns (uint256)
    {
        return uint256(
            keccak256(
                abi.encode(
                    block.chainid,
                    proposal.targets,
                    proposal.calldatas,
                    proposal.description
                )
            )
        );
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return transactions[proposalId].proposal;
    }

    function exists(uint256 proposalId) public view returns (bool) {
        return transactions[proposalId].exists;
    }

    function executed(uint256 proposalId) public view returns (bool) {
        return transactions[proposalId].executed;
    }

    function cancelled(uint256 proposalId) public view returns (bool) {
        return transactions[proposalId].cancelled;
    }

    function signatures(uint256 proposalId) public view returns (uint256) {
        return transactions[proposalId].signatures;
    }

    function signed(
        uint256 proposalId,
        address signer
    ) public view returns (bool) {
        return transactions[proposalId].signed[signer];
    }

    // Modifiers

    modifier onlySigner() {
        if (!isSigner(msg.sender)) {
            revert NotASigner();
        }

        _;
    }

    modifier onlyMultisig() {
        if (msg.sender != address(this)) {
            revert NotMultisig();
        }

        _;
    }

    modifier changesSettings() {
        _;
        settingsNonce += 1;
    }

    // Internals

    EnumerableSet.AddressSet private _signers;

    function _propose(Proposal memory proposal) internal returns (uint256) {
        // Check that the proposal is valid
        if (proposal.targets.length != proposal.calldatas.length) {
            revert InvalidProposal();
        }

        // Retrieve transaction details
        uint256 proposalId = hashProposal(proposal);
        Transaction storage transaction = transactions[proposalId];

        // Validate transaction state
        if (transaction.exists) revert TransactionAlreadyExists();

        // Initialize transaction statue
        transaction.exists = true;
        transaction.proposal = proposal;
        transaction.settingsNonce = settingsNonce;

        // Emit event
        emit TransactionProposed(proposalId, msg.sender);

        // Add a signature from the current signer
        _sign(proposalId);

        return proposalId;
    }

    function _validateTransaction(Transaction storage transaction)
        internal
        view
    {
        if (!transaction.exists) revert TransactionDoesNotExist();
        if (transaction.executed) revert TransactionAlreadyExecuted();
        if (transaction.cancelled) revert TransactionAlreadyCancelled();
        if (transaction.settingsNonce != settingsNonce) {
            revert TransactionNoLongerValid();
        }
    }

    function _sign(uint256 proposalId) internal {
        // Retrieve transaction details
        Transaction storage transaction = transactions[proposalId];

        // Validate transaction state
        _validateTransaction(transaction);
        if (transaction.signed[msg.sender]) revert TransactionAlreadySigned();

        // Update transaction state
        transaction.signatures += 1;
        transaction.signed[msg.sender] = true;

        // Emit event
        emit TransactionSigned(proposalId, msg.sender);
    }

    function _cancel(uint256 proposalId) internal {
        // Retrieve transaction details
        Transaction storage transaction = transactions[proposalId];

        // Validate transaction state
        _validateTransaction(transaction);

        // Update transaction state
        transaction.cancelled = true;

        // Emit event
        emit TransactionCancelled(proposalId, msg.sender);
    }

    function _execute(uint256 proposalId) internal {
        // Retrieve transaction details
        Transaction storage transaction = transactions[proposalId];

        // Validate transaction state
        _validateTransaction(transaction);

        // Check if the transaction has enough signatures
        if (transaction.signatures < threshold) {
            revert TransactionNotReadyToExecute();
        }

        // Update transaction state
        transaction.executed = true;

        // Execute calls
        uint256 length = transaction.proposal.targets.length;
        for (uint256 i; i < length;) {
            _call(
                transaction.proposal.targets[i],
                transaction.proposal.calldatas[i]
            );

            unchecked {
                ++i;
            }
        }

        // And finally emit event
        emit TransactionExecuted(proposalId, msg.sender);
    }

    function _call(address target, bytes memory data) internal {
        (bool success, bytes memory result) = target.call(data);

        if (!success) {
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }

    function _addSigner(address signer) internal changesSettings {
        if (isSigner(signer)) revert SignerAlreadyAdded();

        _signers.add(signer);

        emit SignerAdded(signer);
    }

    function _removeSigner(address signer) internal changesSettings {
        if (!isSigner(signer)) revert SignerAlreadyRemoved();
        if (signerCount() == 1) revert SignerCannotBeRemoved();

        _signers.remove(signer);

        emit SignerRemoved(signer);

        if (threshold > signerCount()) {
            _setThreshold(signerCount());
        }
    }

    function _setThreshold(uint256 newThreshold) internal changesSettings {
        if (newThreshold > signerCount() || newThreshold == 0) {
            revert InvalidThreshold();
        }

        threshold = newThreshold;

        emit ThresholdChanged(newThreshold);
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