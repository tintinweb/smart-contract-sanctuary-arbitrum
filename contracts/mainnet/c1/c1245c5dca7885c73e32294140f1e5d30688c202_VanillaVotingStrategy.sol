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

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Vanilla Voting Strategy
contract VanillaVotingStrategy is IVotingStrategy {
    function getVotingPower(
        uint32 /* timestamp */,
        address /* voter */,
        bytes calldata /* params */,
        bytes calldata /* userParams */
    ) external pure override returns (uint256) {
        return 1;
    }
}