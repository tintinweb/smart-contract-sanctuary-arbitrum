// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.10;

contract TestLODEOracle {
    bool public constant isSushiOracle = true;

    function price() public view returns (uint256) {
        uint256 price = 112693833393436;
        return price;
    }
}