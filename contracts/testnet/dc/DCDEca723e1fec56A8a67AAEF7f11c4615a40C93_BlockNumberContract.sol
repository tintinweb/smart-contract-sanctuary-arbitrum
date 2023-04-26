// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockNumberContract {
    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }
}