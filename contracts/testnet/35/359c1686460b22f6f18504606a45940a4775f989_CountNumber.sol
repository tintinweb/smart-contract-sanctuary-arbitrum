/**
 *Submitted for verification at Arbiscan on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CountNumber {
    uint256 private _time;
    
    mapping (address => uint256) private _luckyNumber;

    constructor() {}

    function count(uint256 lucky_) public {
        _luckyNumber[msg.sender] = lucky_;
        _time++;
    }

    function getCount() public view returns (uint256) {
        return _time;
    }

    function getLuckyNumber(address account) public view returns (uint256) {
        return _luckyNumber[account];
    }
}