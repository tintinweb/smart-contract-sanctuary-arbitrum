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

    mapping (uint256 => bytes32[8]) private cellData;

    mapping (uint256 => uint32) private microCellData;

    function getCellData (uint256 idx) public view returns (bytes32 [8] memory) {
        return cellData[idx];
    }

    function setCellData (uint256 idx, bytes32 [8] calldata data) public {
        cellData[idx] = data;
    }


    function getMicrocCellData (uint256 idx) public view returns (uint32) {
        return microCellData[idx];
    }

    function setMicrocCellData(uint256 idx, uint32 c) public {
        microCellData[idx] = c;
    }

    function setMicrocCellDataBulk(uint256[] calldata idx, uint32[] calldata c) public {
        require(idx.length == c.length);
        
        // WARN: This unbounded for loop is an anti-pattern
        for (uint i=0; i<idx.length; i++) {
            microCellData[i] = c[i];
        }
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