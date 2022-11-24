/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract DonateMeBest {

    address public mainywallet;
    mapping (address => uint) public adrrall;
    

   

    constructor() {
        mainywallet = msg.sender;
    }

    

    mapping(address => bool) public isHandler;
  // @notice Apply 
    function setHandler(address _handler, bool _isActive) external {// onlyOwner {
        isHandler[_handler] = _isActive;
    }

    function doPay() public payable {
        adrrall[msg.sender] = msg.value;
    }

    function doReturn() public {
        address payable _to = payable(mainywallet);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }

   



  

   
}