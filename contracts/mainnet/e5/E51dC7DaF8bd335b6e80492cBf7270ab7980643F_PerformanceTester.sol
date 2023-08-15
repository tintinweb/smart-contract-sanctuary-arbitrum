// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PerformanceTester {
    function test(uint256 useGas) external {
        uint256 gasLeftOnStart = gasleft();
        uint256 gasUsed = 75000;

        require(gasLeftOnStart >= useGas, "To little gas provided");

        while(gasUsed < useGas) {
            gasUsed = 75000 + gasLeftOnStart - gasleft();
        }
    }
}