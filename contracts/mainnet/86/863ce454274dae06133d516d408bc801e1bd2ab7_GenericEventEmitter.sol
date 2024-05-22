// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/** 
@title GenericEventEmitter
@author alfu
@notice This is a helper contract to allow sending generic events
*/
contract GenericEventEmitter {

    /// @notice generic event
    event GenericEvent(
        bytes32 indexed id,
        uint256 timestamp,
        bytes data
    );

    function log(bytes32 id, bytes memory data) public {
        emit GenericEvent(id, block.timestamp, data);
    }
}