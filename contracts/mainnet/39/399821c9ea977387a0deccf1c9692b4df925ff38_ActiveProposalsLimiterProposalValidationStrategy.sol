// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProposalValidationStrategy {
    function validate(address author, bytes calldata params, bytes calldata userParams) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { ActiveProposalsLimiter } from "../utils/ActiveProposalsLimiter.sol";

/// @title Active Proposals Limiter Proposal Validation Strategy
/// @notice Strategy to limit proposal creation to a maximum number of active proposals per author.
contract ActiveProposalsLimiterProposalValidationStrategy is ActiveProposalsLimiter, IProposalValidationStrategy {
    /// @notice Validates an author by checking if they have reached the maximum number of active proposals at the
    ///         current timestamp.
    /// @param author Author of the proposal.
    /// @param params ABI encoded array that should contain the following:
    ///                 cooldown: Duration to wait before the proposal counter gets reset.
    ///                 maxActiveProposals: Maximum number of active proposals per author. Must be != 0.
    /// @return success Whether the proposal was validated.
    function validate(
        address author,
        bytes calldata params,
        bytes calldata /* userParams*/
    ) external override returns (bool success) {
        (uint256 cooldown, uint256 maxActiveProposals) = abi.decode(params, (uint256, uint256));
        return _validate(author, cooldown, maxActiveProposals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Active Proposals Limiter Proposal Validation Module
/// @notice This module can be used to limit the number of active proposals per author.
abstract contract ActiveProposalsLimiter {
    /// @dev Active proposal data stored for each author in a space.
    struct PackedData {
        uint32 activeProposals;
        uint32 lastUpdate;
    }

    /// @notice Thrown when the maximum number of active proposals per user is set to 0.
    error MaxActiveProposalsCannotBeZero();

    /// @dev Mapping that stores a data struct for each author in a space.
    mapping(address space => mapping(address author => PackedData)) private usersPackedData;

    /// @dev Validates an author by checking if they have reached the maximum number of active proposals at the current timestamp.
    function _validate(address author, uint256 cooldown, uint256 maxActiveProposals) internal returns (bool success) {
        if (maxActiveProposals == 0) revert MaxActiveProposalsCannotBeZero();

        // The space calls the proposal validation strategy, therefore msg.sender corresponds to the space address.
        PackedData memory packedData = usersPackedData[msg.sender][author];

        if (packedData.lastUpdate == 0) {
            // First time the user proposes, activeProposals is 1 no matter what.
            packedData.activeProposals = 1;
        } else if (block.timestamp >= packedData.lastUpdate + cooldown) {
            // Cooldown passed, reset counter.
            packedData.activeProposals = 1;
        } else if (packedData.activeProposals >= maxActiveProposals) {
            // Cooldown has not passed, but user has reached maximum active proposals.
            return false;
        } else {
            // Cooldown has not passed, user has not reached maximum active proposals: increase counter.
            packedData.activeProposals += 1;
        }
        packedData.lastUpdate = uint32(block.timestamp);
        usersPackedData[msg.sender][author] = packedData;
        return true;
    }
}