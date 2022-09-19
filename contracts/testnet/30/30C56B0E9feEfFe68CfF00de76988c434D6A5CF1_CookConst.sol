// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CookConst {
    uint256 private nonce;

    constructor()  {
       nonce=1;
    }

    function random(uint8 from, uint256 to) private returns (uint) {
        uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % to;
        randomnumber = from + randomnumber;
        nonce++;
        return randomnumber;
    }

    function revealChance() external returns(uint256){
        uint num =  random(1,100);
        return num;
    }
}