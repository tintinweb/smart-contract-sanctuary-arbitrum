// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.8.15;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        l1Address = address(uint160(l2Address) - offset);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../BaseBridgeReceiver.sol";
import "./AddressAliasHelper.sol";

contract ArbitrumBridgeReceiver is BaseBridgeReceiver {
    fallback() external payable {
        processMessage(AddressAliasHelper.undoL1ToL2Alias(msg.sender), msg.data);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../ITimelock.sol";

contract BaseBridgeReceiver {
    /** Custom errors **/
    error AlreadyInitialized();
    error BadData();
    error InvalidProposalId();
    error InvalidTimelockAdmin();
    error ProposalNotExecutable();
    error TransactionAlreadyQueued();
    error Unauthorized();

    /** Events **/
    event Initialized(address indexed govTimelock, address indexed localTimelock);
    event ProposalCreated(address indexed rootMessageSender, uint id, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint eta);
    event ProposalExecuted(uint indexed id);

    /** Public variables **/

    /// @notice Address of the governing contract that this bridge receiver expects to
    ///  receive messages from; likely an address from another chain (e.g. mainnet)
    address public govTimelock;

    /// @notice Address of the timelock on this chain that the bridge receiver
    /// will send messages to
    address public localTimelock;

    /// @notice Whether contract has been initialized
    bool public initialized;

    /// @notice Total count of proposals generated
    uint public proposalCount;

    struct Proposal {
        uint id;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint eta;
        bool executed;
    }

    /// @notice Mapping of proposal ids to their full proposal data
    mapping (uint => Proposal) public proposals;

    enum ProposalState {
        Queued,
        Expired,
        Executed
    }

    /**
     * @notice Initialize the contract
     * @param _govTimelock Address of the governing contract that this contract
     * will receive messages from (likely on another chain)
     * @param _localTimelock Address of the timelock contract that this contract
     * will send messages to
     */
    function initialize(address _govTimelock, address _localTimelock) external {
        if (initialized) revert AlreadyInitialized();
        if (ITimelock(_localTimelock).admin() != address(this)) revert InvalidTimelockAdmin();
        govTimelock = _govTimelock;
        localTimelock = _localTimelock;
        initialized = true;
        emit Initialized(_govTimelock, _localTimelock);
    }

    /**
     * @notice Process a message sent from the governing timelock (across a bridge)
     * @param rootMessageSender Address of the contract that sent the bridged message
     * @param data ABI-encoded bytes containing the transactions to be queued on the local timelock
     */
    function processMessage(
        address rootMessageSender,
        bytes calldata data
    ) internal {
        if (rootMessageSender != govTimelock) revert Unauthorized();

        address[] memory targets;
        uint256[] memory values;
        string[] memory signatures;
        bytes[] memory calldatas;

        (targets, values, signatures, calldatas) = abi.decode(
            data,
            (address[], uint256[], string[], bytes[])
        );

        if (values.length != targets.length) revert BadData();
        if (signatures.length != targets.length) revert BadData();
        if (calldatas.length != targets.length) revert BadData();

        uint delay = ITimelock(localTimelock).delay();
        uint eta = block.timestamp + delay;

        for (uint i = 0; i < targets.length; i++) {
            if (ITimelock(localTimelock).queuedTransactions(keccak256(abi.encode(targets[i], values[i], signatures[i], calldatas[i], eta)))) revert TransactionAlreadyQueued();
            ITimelock(localTimelock).queueTransaction(targets[i], values[i], signatures[i], calldatas[i], eta);
        }

        proposalCount++;
        Proposal memory proposal = Proposal({
            id: proposalCount,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            eta: eta,
            executed: false
        });

        proposals[proposal.id] = proposal;
        emit ProposalCreated(rootMessageSender, proposal.id, targets, values, signatures, calldatas, eta);
    }

    /**
     * @notice Execute a queued proposal
     * @param proposalId The id of the proposal to execute
     */
    function executeProposal(uint proposalId) external {
        if (state(proposalId) != ProposalState.Queued) revert ProposalNotExecutable();
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            ITimelock(localTimelock).executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Get the state of a proposal
     * @param proposalId Id of the proposal
     * @return The state of the given proposal (queued, expired or executed)
     */
    function state(uint proposalId) public view returns (ProposalState) {
        if (proposalId > proposalCount || proposalId == 0) revert InvalidProposalId();
        Proposal memory proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp > (proposal.eta + ITimelock(localTimelock).GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @dev Interface for interacting with a Timelock
 */
interface ITimelock {
    /// @notice Event emitted when a pending admin accepts admin position
    event NewAdmin(address indexed newAdmin);

    /// @notice Event emitted when new pending admin is set by the timelock
    event NewPendingAdmin(address indexed newPendingAdmin);

    /// @notice Event emitted when Timelock sets new delay value
    event NewDelay(uint indexed newDelay);

    /// @notice Event emitted when admin cancels an enqueued transaction
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    /// @notice Event emitted when admin executes an enqueued transaction
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    /// @notice Event emitted when admin enqueues a transaction
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    /// @notice The length of time, once the delay has passed, in which a transaction can be executed before it becomes stale
    function GRACE_PERIOD() virtual external view returns (uint);

    /// @notice The minimum value that the `delay` variable can be set to
    function MINIMUM_DELAY() virtual external view returns (uint);

    /// @notice The maximum value that the `delay` variable can be set to
    function MAXIMUM_DELAY() virtual external view returns (uint);

    /// @notice Address that has admin privileges
    function admin() virtual external view returns (address);

    /// @notice The address that may become the new admin by calling `acceptAdmin()`
    function pendingAdmin() virtual external view returns (address);

    /**
     * @notice Set the pending admin
     * @param pendingAdmin_ New pending admin address
     */
    function setPendingAdmin(address pendingAdmin_) virtual external;

    /**
     * @notice Accept the position of admin (if caller is the current pendingAdmin)
     */
    function acceptAdmin() virtual external;

    /// @notice Duration that a transaction must be queued before it can be executed
    function delay() virtual external view returns (uint);

    /**
     * @notice Set the delay value
     * @param delay New delay value
     */
    function setDelay(uint delay) virtual external;

    /// @notice Mapping of transaction hashes to whether that transaction is currently enqueued
    function queuedTransactions(bytes32 txHash) virtual external returns (bool);

    /**
     * @notice Enque a transaction
     * @param target Address that the transaction is targeted at
     * @param value Value to send to target address
     * @param signature Function signature to call on target address
     * @param data Calldata for function called on target address
     * @param eta Timestamp of when the transaction can be executed
     * @return txHash of the enqueued transaction
     */
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external returns (bytes32);

    /**
     * @notice Cancel an enqueued transaction
     * @param target Address that the transaction is targeted at
     * @param value Value of the transaction to cancel
     * @param signature Function signature of the transaction to cancel
     * @param data Calldata for the transaction to cancel
     * @param eta Timestamp of the transaction to cancel
     */
    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external;

    /**
     * @notice Execute an enqueued transaction
     * @param target Target address of the transaction to execute
     * @param value Value of the transaction to execute
     * @param signature Function signature of the transaction to execute
     * @param data Calldata for the transaction to execute
     * @param eta Timestamp of the transaction to execute
     * @return bytes returned from executing transaction
     */
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external payable returns (bytes memory);
}