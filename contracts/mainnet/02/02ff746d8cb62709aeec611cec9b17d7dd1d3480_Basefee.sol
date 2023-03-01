/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

/**
 * @dev Contract that reads the block base fee on supported
 *  networks, including Ethereum, Fantom, and Arbitrum. Also
8*  deployed on Optimism, but no base fee there yet.
 *
 * Version 0.1.1
 */

contract Basefee {
    /// @notice Check the network's current base fee.
    /// @return Current network base fee, in wei.
    function basefee_global() external view returns (uint) {
        return block.basefee;
    }
}