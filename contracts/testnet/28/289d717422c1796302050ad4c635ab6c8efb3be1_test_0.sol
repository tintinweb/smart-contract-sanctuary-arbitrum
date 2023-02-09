/**
 *Submitted for verification at Arbiscan on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Itest_1 {
    function checkTest(uint256 _input) external pure;
}

contract test_0 {

    address testContract;

    constructor(address _address) {
        testContract = _address;
    }

    function setAddress(address _address) public { testContract = _address; }

    function callTest(uint256 _input) public view {
        Itest_1(testContract).checkTest(_input);
    }
}