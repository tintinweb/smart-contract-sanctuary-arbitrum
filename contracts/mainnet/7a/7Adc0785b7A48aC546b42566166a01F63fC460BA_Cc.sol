/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

// SPDX-License-Identifier: MIT


// File: contracts/Choco.sol




pragma solidity ^0.8.0;


interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);
}

contract Cc {
    uint256 public uploadTime;
    uint256 public uploadBlock;

    constructor() {
       uploadTime = block.timestamp;
       uploadBlock = getBlockNumber();
    }

    function getTimeStats() public view returns (uint256 min,uint256 day,uint256 year) {
        min = blocksAmin();
        day = blocksAday();
        year = blocksAyear();
    }

    function blocksAyear() public view returns (uint256){
        return secondsToBlocks(365 days);
    }

    function blocksAday() public view returns (uint256){
        return secondsToBlocks(1 days);
    }
    function blocksAmin() public view returns (uint256){
        return secondsToBlocks(1 minutes);
    }

    // estimate blocks in a second, some
    function secondsToBlocks(uint256 time) public view returns (uint256){
        uint256 deltaB =  getBlockNumber() - uploadBlock;
        uint256 deltaT = block.timestamp - uploadTime;
        return time * deltaB / deltaT;      
    }

    // unified location to query for block number
    function getBlockNumber() public view returns (uint256) {
        // Query the ArbSysOS for L2 Aribtrum block
        return ArbSys(address(100)).arbBlockNumber(); 
    }
}