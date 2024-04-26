/**
 *Submitted for verification at Arbiscan.io on 2024-04-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Emojis {
    string public emoji;

    function setEmoji(string memory str) external {
        emoji = str;
    }
}