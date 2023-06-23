/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract AnswerFinder {
    function getCorrectAnswer() public view returns (uint256) {
        uint256 correctAnswer =
            uint256(keccak256(abi.encodePacked(msg.sender, block.prevrandao, block.timestamp))) % 100000;
        return correctAnswer;
    }
}