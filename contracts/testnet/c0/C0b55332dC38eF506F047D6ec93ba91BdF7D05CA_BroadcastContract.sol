// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract BroadcastContract {

    event Broadcast(address indexed _user, string _message);
    event ReplyBroadcast(address indexed _user, string _messageId, string _message);

    function broadcast(string memory _message) external {
      emit Broadcast(msg.sender, _message);
    }

    function reply(string memory _message, string memory _messageId) external {
      emit ReplyBroadcast(msg.sender, _messageId, _message);
    }
}