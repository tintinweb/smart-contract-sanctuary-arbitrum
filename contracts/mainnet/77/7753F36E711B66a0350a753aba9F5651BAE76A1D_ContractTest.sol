/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ZZZ_ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);
}

contract ContractTest {

    struct STORE_DATA {
        uint128 timestamp;
        uint64 blockL1;
        uint64 blockL2;
    }

    STORE_DATA[] public data; 

    constructor() {}

    function getL2BlockNumber() public view returns (uint64) {
        return uint64(ZZZ_ArbSys(address(100)).arbBlockNumber());
    }

    function getL1BlockNumber() public view returns (uint64) {
        return uint64(block.number);
    }

    function getCurrentBlockTimestamp() public view returns (uint128) {
        return uint128(block.timestamp);
    }

    function storeIt() external {
        STORE_DATA memory myData = STORE_DATA({
            timestamp: getCurrentBlockTimestamp(),
            blockL1: getL1BlockNumber(),
            blockL2: getL2BlockNumber()
        });
        
        data.push(myData);
    }
}