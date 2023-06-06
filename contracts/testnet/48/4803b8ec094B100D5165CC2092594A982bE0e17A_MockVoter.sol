// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MockVoter{
    mapping(address => bool) public isGauge;
    constructor(){}
    function set(address _gauge, bool _flag) external{
        isGauge[_gauge] = _flag;
    }
}