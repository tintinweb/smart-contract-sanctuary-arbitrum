// SPDX-License-Identifier:MIT
pragma solidity 0.6.12;

contract test {
    uint256 number = 42424;

    function getData() public view returns (uint256) {
        return number;
    }
}