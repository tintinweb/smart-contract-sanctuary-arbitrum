// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
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

interface IProposalValidationStrategy {
    function validate(address author, bytes calldata params, bytes calldata userParams) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Voting Strategy Interface
interface IVotingStrategy {
    /// @notice Gets the voting power of an address at a given block number.
    /// @param blockNumber The snapshot block number to get the voting power at.
    /// @param voter The address to get the voting power of.
    /// @param params The global parameters that can configure the voting strategy for a particular Space.
    /// @param userParams The user parameters that can be used in the voting strategy computation.
    /// @return votingPower The voting power of the address at the given block number. If there is no voting power,
    ///                     return 0.
    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external view returns (uint256 votingPower);
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

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { PropositionPower } from "../utils/PropositionPower.sol";

/// @title Proposition Power Proposal Validation Strategy
/// @notice Strategy that limits proposal creation to authors that exceed a threshold proposition power
///         over a set of voting strategies.
contract PropositionPowerProposalValidationStrategy is PropositionPower, IProposalValidationStrategy {
    /// @notice Validates an author by checking if the proposition power of the author exceeds a threshold
    ///         over a set of strategies.
    /// @param author Author of the proposal.
    /// @param params ABI encoded array that should contain the following:
    ///                 proposalThreshold: Minimum proposition power required to create a proposal.
    ///                 allowedStrategies: Array of allowed voting strategies.
    /// @param userParams ABI encoded array that should contain the user voting strategies.
    function validate(
        address author,
        bytes calldata params,
        bytes calldata userParams
    ) external override returns (bool) {
        (uint256 proposalThreshold, Strategy[] memory allowedStrategies) = abi.decode(params, (uint256, Strategy[]));
        IndexedStrategy[] memory userStrategies = abi.decode(userParams, (IndexedStrategy[]));

        return _validate(author, proposalThreshold, allowedStrategies, userStrategies);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SXUtils } from "./SXUtils.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Proposition Power Proposal Validation Strategy Module
/// @notice This module allows a proposal to be validated based on the proposition power of an author exceeding
///         a threshold over a set of voting strategies.
/// @dev The voting strategies used here are configured independently of the strategies set in the Space.
abstract contract PropositionPower {
    using SXUtils for IndexedStrategy[];

    /// @notice Thrown when an invalid strategy index is supplied.
    error InvalidStrategyIndex(uint256 index);

    /// @dev Validates an author based on the voting power of the author exceeding a threshold over a set of strategies.
    function _validate(
        address author,
        uint256 proposalThreshold,
        Strategy[] memory allowedStrategies,
        IndexedStrategy[] memory userStrategies
    ) internal returns (bool) {
        uint256 votingPower = _getCumulativePower(author, uint32(block.number), userStrategies, allowedStrategies);
        return (votingPower >= proposalThreshold);
    }

    /// @dev Computes the cumulative proposition power of an address at a given block number over a set of strategies.
    function _getCumulativePower(
        address userAddress,
        uint32 blockNumber,
        IndexedStrategy[] memory userStrategies,
        Strategy[] memory allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy.
        userStrategies.assertNoDuplicateIndicesMemory();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint256 strategyIndex = userStrategies[i].index;
            if (strategyIndex >= allowedStrategies.length) revert InvalidStrategyIndex(strategyIndex);
            Strategy memory strategy = allowedStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                blockNumber,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy } from "src/types.sol";

/// @title Snapshot X Types Utilities Library
library SXUtils {
    error DuplicateFound(uint8 index);

    /// @dev Reverts if a duplicate index is found in the given array of indexed strategies.
    function assertNoDuplicateIndicesCalldata(IndexedStrategy[] calldata strats) internal pure {
        if (strats.length < 2) {
            return;
        }

        uint256 bitMap;
        for (uint256 i = 0; i < strats.length; ++i) {
            // Check that bit at index `strats[i].index` is not set.
            uint256 s = 1 << strats[i].index;
            if (bitMap & s != 0) revert DuplicateFound(strats[i].index);
            // Update aforementioned bit.
            bitMap |= s;
        }
    }

    /// @dev Reverts if a duplicate index is found in the given array of indexed strategies.
    function assertNoDuplicateIndicesMemory(IndexedStrategy[] memory strats) internal pure {
        if (strats.length < 2) {
            return;
        }

        uint256 bitMap;
        for (uint256 i = 0; i < strats.length; ++i) {
            // Check that bit at index `strats[i].index` is not set.
            uint256 s = 1 << strats[i].index;
            if (bitMap & s != 0) revert DuplicateFound(strats[i].index);
            // Update aforementioned bit.
            bitMap |= s;
        }
    }
}