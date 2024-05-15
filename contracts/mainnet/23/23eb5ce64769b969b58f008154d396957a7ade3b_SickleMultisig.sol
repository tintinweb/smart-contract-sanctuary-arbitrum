// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SickleMultisig {
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
    error TransactionNoLongerValid();
    error TransactionAlreadyExists();
    error TransactionAlreadySigned();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyCancelled();

    error SignerAlreadyAdded();
    error SignerAlreadyRemoved();

    // Events

    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    event ThresholdChanged(uint256 newThreshold);

    event TransactionProposed(uint256 proposalId, address signer);
    event TransactionSigned(uint256 proposalId, address signer);
    event TransactionExecuted(uint256 proposalId, address signer);
    event TransactionCancelled(uint256 proposalId, address signer);

    // Storage

    uint256 public signers;
    uint256 public threshold;
    uint256 public settingsNonce;

    mapping(address => bool) public isSigner;
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

    /// @notice Set a new signatures threshold for the multisig
    /// @custom:access Restricted to multisig transactions.
    function setThreshold(uint256 newThreshold) public onlyMultisig {
        _setThreshold(newThreshold);
    }

    // Public functions

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
        if (!isSigner[msg.sender]) {
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

        // Update transaction state
        transaction.executed = true;

        // Execute calls
        for (uint256 i; i < transaction.proposal.targets.length;) {
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
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }

    function _addSigner(address signer) internal changesSettings {
        if (isSigner[signer]) revert SignerAlreadyAdded();

        isSigner[signer] = true;
        signers += 1;

        emit SignerAdded(signer);
    }

    function _removeSigner(address signer) internal changesSettings {
        if (!isSigner[signer]) revert SignerAlreadyRemoved();

        isSigner[signer] = false;
        signers -= 1;

        emit SignerRemoved(signer);
    }

    function _setThreshold(uint256 newThreshold) internal changesSettings {
        if (newThreshold > signers || newThreshold == 0) {
            revert InvalidThreshold();
        }

        threshold = newThreshold;

        emit ThresholdChanged(newThreshold);
    }
}