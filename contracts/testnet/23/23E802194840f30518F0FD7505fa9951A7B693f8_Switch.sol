// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface ILightBulb {
    /**
    * @dev Toggles the lightbulb on or off.
    * @param _msgSender The address of the sender on the L2 side.
    * @param lightBulbOwner The address of the owner of the lightbulb on the L2 side.
    */
    function toggleMyLightBulb(address _msgSender, address lightBulbOwner) external;
    /**
    * @dev Toggles the global lightbulb on or off.
    * @param _msgSender The address of the sender on the L2 side.
    */
    function toggleGlobalLightBulb(address _msgSender) external;
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IVeaInbox {
    /**
     * Note: Calls authenticated by receiving gateway checking the sender argument.
     * @dev Sends an arbitrary message to Ethereum.
     * @param to The cross-domain contract address which receives the calldata.
     * @param data The message calldata, abi.encodeWithSelector(...)
     * @return msgId The index of the message in the inbox, as a message Id, needed to relay the message.
     */
    function sendMsg(address to, bytes memory data) external returns (uint64 msgId);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "../interfaces/IVeaInbox.sol";
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
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event lightBulbToggled(uint256 indexed _epoch, bytes32 _batchMerkleRoot);

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event Claimed(uint256 indexed _epoch, bytes32 _batchMerkleRoot);

    constructor(address _veaInbox, address _lightBulb) {
        veaInbox = IVeaInbox(_veaInbox);
        lightBulb = _lightBulb;
    }

    function toggleMyLightBulb() external {
        bytes memory _calldata = abi.encodeWithSelector(ILightBulb.toggleMyLightBulb.selector, msg.sender);
        veaInbox.sendMsg(lightBulb, _calldata);
    }

    function toggleGlobalLightBulb() external {
        bytes memory _calldata = abi.encodeWithSelector(ILightBulb.toggleGlobalLightBulb.selector);
        veaInbox.sendMsg(lightBulb, _calldata);
    }
}