// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IComp {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
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

import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";
import { IComp } from "../interfaces/IComp.sol";

/// @title Comp Voting Strategy
/// @notice Uses delegated balances of Comp style tokens to determine voting power.
contract CompVotingStrategy is IVotingStrategy {
    /// @notice Thrown when the byte array is not long enough to represent an address.
    error InvalidByteArray();

    /// @notice Returns the voting power of an address at a given block number.
    /// @param blockNumber The block number to get the voting power at.
    /// @param voter The address to get the voting power of.
    /// @param params Parameter array containing the address of the Comp style token.
    function getVotingPower(
        uint32 blockNumber,
        address voter,
        bytes calldata params,
        bytes calldata /* userParams */
    ) external view override returns (uint256) {
        if (params.length < 20) revert InvalidByteArray();
        address tokenAddress = address(bytes20(params));
        // We subract 1 from the block number so that when blockNumber == block.number,
        // getPriorVotes can still be called.
        return uint256(IComp(tokenAddress).getPriorVotes(voter, blockNumber - 1));
    }
}