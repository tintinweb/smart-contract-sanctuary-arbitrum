// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld{

    mapping(address => string) public info;

    event NewInfo(address indexed user, string info);

    function say(string calldata _str) external {
        info[msg.sender] = _str;
        emit NewInfo(msg.sender, _str);
    }

    uint256 public A;

    function setA(uint256 a) external {
        A = a;
    }

    function getBlockInfo() view public returns(uint256 bn,uint256 bt) {
        bn = block.number;
        bt = block.timestamp;
    }
}