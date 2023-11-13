// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Lottery {
    function play() public payable {
        require(msg.value > 0, "Must send some Ether to play");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;
        
        if(randomNumber == 0) {
            payable(msg.sender).transfer(3 * msg.value);
        }
    }
}