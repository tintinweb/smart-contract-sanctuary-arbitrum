// Deployed with the Atlas IDE
// https://app.atlaszk.com/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

contract GasEfficientFunction {
    uint256 private result;

    function performFunction(uint256 a, uint256 b) external {
        unchecked {
            result = a + b;
        }
    }

    function getResult() external view returns (uint256) {
        return result;
    }
}