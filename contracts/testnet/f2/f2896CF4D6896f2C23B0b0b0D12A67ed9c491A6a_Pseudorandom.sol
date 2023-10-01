/**
 *Submitted for verification at Arbiscan.io on 2023-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pseudorandom {
    uint256[] public pseudorandomNumbers;
    bytes32[] public pseudorandomLetters;

    function addPseudorandomNumber() public {
        pseudorandomNumbers.push(uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100);
    }

    function addPseudorandomCharacter() public  {
        uint randomNum = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 26;
        pseudorandomLetters.push(getLetterFromNumber(randomNum));
    }

    function getLetterFromNumber(uint _num) internal pure returns (bytes32) {
        bytes memory alphabet = "abcdefghijklmnopqrstuvwxyz";
        return bytes32(alphabet[_num]);
    }
}