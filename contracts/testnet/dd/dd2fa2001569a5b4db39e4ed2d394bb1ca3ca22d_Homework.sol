/**
 *Submitted for verification at Arbiscan on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Homework {
    struct TestStruct {
        string param_1;
        uint param_2;
        bool param_3;
    }

    TestStruct public testStruct;

    function setParams(string calldata _param_1, uint _param_2, bool _param_3) public {
        // TestStruct memory testStruct = TestStruct({
        //     param_1: _param_1,
        //     param_2: _param_2,
        //     param_3: _param_3
        // });

        testStruct.param_1 = _param_1;
        testStruct.param_2 = _param_2;
        testStruct.param_3 = _param_3;
    }

    function getParams() public view returns (string memory param_1, uint param_2, bool param_3) {
        return (testStruct.param_1, testStruct.param_2, testStruct.param_3);
    }
}