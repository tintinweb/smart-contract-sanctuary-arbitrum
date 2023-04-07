/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract NFT {

    mapping (uint256 => bytes32[8]) cellData;

    function getCellData (uint256 idx) public view returns (bytes32 [8] memory) {
        return cellData[idx];
    }

    function setCellData (uint256 idx, bytes32 [8] calldata data) public {
        cellData[idx] = data;
    }

    constructor() {
        cellData[42] = [
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293)),
            bytes32(uint256(182319231293))
        ];
    }

}