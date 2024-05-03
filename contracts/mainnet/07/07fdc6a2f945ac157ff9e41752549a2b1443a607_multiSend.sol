/**
 *Submitted for verification at Arbiscan.io on 2024-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract multiSend {

    address public owner;

    address[] public lists;

    uint256 public preNum; 

    modifier isOwner() {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public isOwner {
        require(msg.sender == owner, "only owner allow change");
        owner = _newOwner;
    }

    function setWallets(address[] calldata _lists) public isOwner {
        for(uint i=0; i<_lists.length; i++) {
            lists.push(_lists[i]);
        }
    } 

    function setPreNum(uint256 _num) public isOwner {
        preNum = _num;
    }

    function send() public payable  {
        require(msg.value > lists.length*preNum, "Insufficient funds");
        for (uint i=0; i<lists.length; i++) {
             payable(lists[i]).transfer(preNum);
        }
    }

    function getBalance(address _address) public view returns(uint256) {
        return _address.balance;
    }

    function recyle() public isOwner {
        payable(owner).transfer(address(this).balance);
    }

}