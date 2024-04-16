/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Generate ID equivalent of your Safe address.
contract SafeID {
    function getSafeID(address safe) public pure returns (uint256) {
        return uint256(uint160(safe));
    }
}