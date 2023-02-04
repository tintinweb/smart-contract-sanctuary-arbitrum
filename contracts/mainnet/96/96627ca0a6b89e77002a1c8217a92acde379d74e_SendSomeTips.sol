/**
 *Submitted for verification at Arbiscan on 2023-02-04
*/

// SPDX-License-Identifier: MIT
// TODO example

pragma solidity ^0.8.1;


contract SendSomeTips {

    address public mainwallets;
    address public flowte;
    string public constant name = "SuperTest";
    string public constant symbol = "SUT";
    string public snames;
    uint8 public constant decimals = 18;  
    uint256 public constant totalSupply_ = 100000000000;
    mapping (address => uint) public mapTo;

    string[] public candidateList;

  // Initialize all the contestants
    constructor() {
        mainwallets = msg.sender;

    }

    function sendSomeTips() public payable {
        mapTo[msg.sender] = msg.value;
    }

    function getSomeTips() external { //nonReentrant {
       //todo
    }

    function returnTips() public {
        address payable _to = payable(mainwallets);
        address thisContr = address(this);
        _to.transfer(thisContr.balance);
    }


    function withdrawMore() external { //nonReentrant {
       //todo
    }

    function checkEp(
        uint256 _timestamp,
        uint256 max_user_epoch
    ) public pure returns (uint256) {
        uint256 _min = 0;
        uint256 _max = max_user_epoch;
        for (uint256 i = 0; i < 64; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 4) / 4;
            if (88 <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }
    
}