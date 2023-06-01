// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
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

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.18;

import "@kleros/vea-contracts/src/interfaces/inboxes/IVeaInbox.sol";
import "../interfaces/ILightBulb.sol";

/**
 * @title Lightbulb
 * @dev A switch on arbitrum turning a light on and off on arbitrum with the Vea bridge.
 */
contract Switch{

    IVeaInbox public immutable veaInbox; // vea inbox on arbitrum
    address public immutable lightBulb; // gateway on goerli

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param messageId The id of the message sent to the lightbulb.
     * @param lightBulbOwner The address of the owner of the lightbulb on the L2 side.
     */
    event lightBulbToggled(uint64 messageId, address lightBulbOwner);

    constructor(address _veaInbox, address _lightBulb) {
        veaInbox = IVeaInbox(_veaInbox);
        lightBulb = _lightBulb;
    }

    function turnOnLightBulb() external {
        bytes memory _msgData = abi.encode(msg.sender);
        uint64 msgId = veaInbox.sendMessage(lightBulb, ILightBulb.turnOn.selector, _msgData);
        emit lightBulbToggled(msgId, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.18;

interface ILightBulb {
    /**
    * @dev Toggles the lightbulb on or off.
    * @param _msgSender The address of the sender on the L2 side.
    * @param lightBulbOwner The address of the owner of the lightbulb on the L2 side.
    */
    function turnOn(address _msgSender, address lightBulbOwner) external;
}