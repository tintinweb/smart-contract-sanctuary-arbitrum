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

/// @title Whitelist Voting Strategy
/// @notice Allows a variable voting power whitelist to be used for voting power.
contract WhitelistVotingStrategy is IVotingStrategy {
    /// @notice Error thrown when the `voter` and address indicated by `voterIndex`
    ///         don't match.
    error VoterAndIndexMismatch();

    /// @dev Stores the data for each member of the whitelist.
    struct Member {
        // The address of the member.
        address addr;
        // The voting power of the member.
        uint96 vp;
    }

    /// @notice Returns the voting power of an address.
    /// @param voter The address to get the voting power of.
    /// @param params Parameter array containing the encoded whitelist of addresses and their voting power.
    ///               The array should be an ABI encoded array of Member structs.
    /// @param userParams Expected to contain a `uint256` corresponding to the voterIndex in the array provided by `params`.
    /// @return votingPower The voting power of the address if it exists in the whitelist, otherwise reverts.
    function getVotingPower(
        uint32 /* blockNumber */,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external pure override returns (uint256 votingPower) {
        Member[] memory members = abi.decode(params, (Member[]));
        uint256 voterIndex = abi.decode(userParams, (uint256));

        if (voter != members[voterIndex].addr) revert VoterAndIndexMismatch();

        return members[voterIndex].vp;
    }
}