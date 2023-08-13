// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./dependencies/ArbSys.sol";

contract ArbiBlockNumber {

    ArbSys constant public arbSys = ArbSys(address(100));

    event Debug(uint8 layer, uint blockNumber);

    function getL1BlockNumber() external view returns (uint) {
        return block.number;
    }

    function getL2BlockNumber() external view returns (uint) {
        return arbSys.arbBlockNumber();
    }

    function writeL1BlockNumber() external {
        emit Debug(1, block.number);
    }

    function writeL2BlockNumber() external {
        emit Debug(2, arbSys.arbBlockNumber());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
}