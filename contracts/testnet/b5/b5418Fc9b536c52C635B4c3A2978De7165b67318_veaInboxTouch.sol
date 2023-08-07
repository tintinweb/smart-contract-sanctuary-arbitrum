/**
 *Submitted for verification at Arbiscan on 2023-08-06
*/

// SPDX-License-Identifier: MIT

/// @custom:authors: [@shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;


interface IVeaInbox {
    /// @dev Sends an arbitrary message to receiving chain.
    /// Note: Calls authenticated by receiving gateway checking the sender argument.
    /// @param _to The cross-domain contract address which receives the calldata.
    /// @param _fnSelection The function selector of the receiving contract.
    /// @param _data The message calldata, abi.encode(...)
    /// @return msgId The index of the message in the inbox, as a message Id, needed to relay the message.
    function sendMessage(address _to, bytes4 _fnSelection, bytes memory _data) external returns (uint64 msgId);

    /// @dev Snapshots can be saved a maximum of once per epoch.
    ///      Saves snapshot of state root.
    ///      `O(log(count))` where count number of messages in the inbox.
    function saveSnapshot() external;
}


/// @dev Vea Inbox Calldata Optimization.
///      No function selector required, only fallback function.
contract veaInboxTouch {
    IVeaInbox public immutable veaInbox;

    constructor(IVeaInbox _veaInbox) {
        veaInbox = _veaInbox;
    }

    function touch(uint256 random) external payable {
        veaInbox.sendMessage(
            0x0000000000000000000000000000000000000000, 
            0x00000000, 
            abi.encode(random));
        veaInbox.saveSnapshot();
    }
}