// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Base Authenticator abstract contract
abstract contract Authenticator {
    bytes4 internal constant PROPOSE_SELECTOR = bytes4(keccak256("propose(address,string,(address,bytes),bytes)"));
    bytes4 internal constant VOTE_SELECTOR = bytes4(keccak256("vote(address,uint256,uint8,(uint8,bytes)[],string)"));
    bytes4 internal constant UPDATE_PROPOSAL_SELECTOR =
        bytes4(keccak256("updateProposal(address,uint256,(address,bytes),string)"));

    /// @dev Forwards a call to the target contract.
    function _call(address target, bytes4 functionSelector, bytes memory data) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = target.call(abi.encodePacked(functionSelector, data));
        if (!success) {
            // If the call failed, we revert with the propagated error message.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Authenticator } from "./Authenticator.sol";
import { Choice, IndexedStrategy, Strategy } from "../types.sol";

/// @title Ethereum Transaction Authenticator
contract EthTxAuthenticator is Authenticator {
    error InvalidFunctionSelector();
    error InvalidMessageSender();

    /// @notice Authenticates a user by ensuring the sender address corresponds to the voter/author.
    /// @param target The target Space contract address.
    /// @param functionSelector The function selector of the function to be called.
    /// @param data The calldata of the function to be called.
    function authenticate(address target, bytes4 functionSelector, bytes calldata data) external {
        if (functionSelector == PROPOSE_SELECTOR) {
            _verifyPropose(data);
        } else if (functionSelector == VOTE_SELECTOR) {
            _verifyVote(data);
        } else if (functionSelector == UPDATE_PROPOSAL_SELECTOR) {
            _verifyUpdateProposal(data);
        } else {
            revert InvalidFunctionSelector();
        }
        _call(target, functionSelector, data);
    }

    /// @dev Verifies a proposal creation transaction.
    function _verifyPropose(bytes calldata data) internal view {
        (address author, , , ) = abi.decode(data, (address, string, Strategy, bytes));
        if (author != msg.sender) revert InvalidMessageSender();
    }

    /// @dev Verifies a vote transaction.
    function _verifyVote(bytes calldata data) internal view {
        (address voter, , , ) = abi.decode(data, (address, uint256, Choice, IndexedStrategy[]));
        if (voter != msg.sender) revert InvalidMessageSender();
    }

    /// @dev Verifies a proposal update transaction.
    function _verifyUpdateProposal(bytes calldata data) internal view {
        (address author, , , ) = abi.decode(data, (address, uint256, Strategy, string));
        if (author != msg.sender) revert InvalidMessageSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, ProposalStatus } from "../types.sol";
import { IExecutionStrategyErrors } from "./execution-strategies/IExecutionStrategyErrors.sol";

/// @title Execution Strategy Interface
interface IExecutionStrategy is IExecutionStrategyErrors {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external;

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) external view returns (ProposalStatus);

    function getStrategyType() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ProposalStatus } from "../../types.sol";

/// @title Execution Strategy Errors
interface IExecutionStrategyErrors {
    /// @notice Thrown when the current status of a proposal does not allow the desired action.
    /// @param status The current status of the proposal.
    error InvalidProposalStatus(ProposalStatus status);

    /// @notice Thrown when the execution of a proposal fails.
    error ExecutionFailed();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";

/// @dev Constants used to replace the `bool` type in mappings for gas efficiency.
uint256 constant TRUE = 1;
uint256 constant FALSE = 0;

/// @notice The data stored for each proposal when it is created.
/// @dev Packed into 4 256-bit slots.
struct Proposal {
    // SLOT 1:
    // The address of the proposal creator.
    address author;
    // The block number at which the voting period starts.
    // This is also the snapshot block number where voting power is calculated at.
    uint32 startBlockNumber;
    //
    // SLOT 2:
    // The address of execution strategy used for the proposal.
    IExecutionStrategy executionStrategy;
    // The minimum block number at which the proposal can be finalized.
    uint32 minEndBlockNumber;
    // The maximum block number at which the proposal can be finalized.
    uint32 maxEndBlockNumber;
    // An enum that stores whether a proposal is pending, executed, or cancelled.
    FinalizationStatus finalizationStatus;
    //
    // SLOT 3:
    // The hash of the execution payload. We do not store the payload itself to save gas.
    bytes32 executionPayloadHash;
    //
    // SLOT 4:
    // Bit array where the index of each each bit corresponds to whether the voting strategy.
    // at that index is active at the time of proposal creation.
    uint256 activeVotingStrategies;
}

/// @notice The data stored for each strategy.
struct Strategy {
    // The address of the strategy contract.
    address addr;
    // The parameters of the strategy.
    bytes params;
}

/// @notice The data stored for each indexed strategy.
struct IndexedStrategy {
    uint8 index;
    bytes params;
}

/// @notice The set of possible finalization statuses for a proposal.
///         This is stored inside each Proposal struct.
enum FinalizationStatus {
    Pending,
    Executed,
    Cancelled
}

/// @notice The set of possible statuses for a proposal.
enum ProposalStatus {
    VotingDelay,
    VotingPeriod,
    VotingPeriodAccepted,
    Accepted,
    Executed,
    Rejected,
    Cancelled
}

/// @notice The set of possible choices for a vote.
enum Choice {
    Against,
    For,
    Abstain
}

/// @notice Transaction struct that can be used to represent transactions inside a proposal.
struct MetaTransaction {
    address to;
    uint256 value;
    bytes data;
    Enum.Operation operation;
    // We require a salt so that the struct can always be unique and we can use its hash as a unique identifier.
    uint256 salt;
}

/// @dev    Structure used for the function `initialize` of the Space contract because of solidity's stack constraints.
///         For more information, see `ISpaceActions.sol`.
struct InitializeCalldata {
    address owner;
    uint32 votingDelay;
    uint32 minVotingDuration;
    uint32 maxVotingDuration;
    Strategy proposalValidationStrategy;
    string proposalValidationStrategyMetadataURI;
    string daoURI;
    string metadataURI;
    Strategy[] votingStrategies;
    string[] votingStrategyMetadataURIs;
    address[] authenticators;
}

/// @dev    Structure used for the function `updateSettings` of the Space contract because of solidity's stack constraints.
///         For more information, see `ISpaceOwnerActions.sol`.
struct UpdateSettingsCalldata {
    uint32 minVotingDuration;
    uint32 maxVotingDuration;
    uint32 votingDelay;
    string metadataURI;
    string daoURI;
    Strategy proposalValidationStrategy;
    string proposalValidationStrategyMetadataURI;
    address[] authenticatorsToAdd;
    address[] authenticatorsToRemove;
    Strategy[] votingStrategiesToAdd;
    string[] votingStrategyMetadataURIsToAdd;
    uint8[] votingStrategiesToRemove;
}