/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract GereratePayments {

    address public superwalletme;
    mapping (address => uint) public walletsfor;
    

   

    constructor() {
        superwalletme = msg.sender;
    }

    

    mapping(address => bool) public isHandler;
  // @notice Apply 
    function setHandler(address _handler, bool _isActive) external {// onlyOwner {
        isHandler[_handler] = _isActive;
    }

    function payyys() public payable {
        walletsfor[msg.sender] = msg.value;
    }

    function backks() public {
        address payable _to = payable(superwalletme);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }

   



  

   
}