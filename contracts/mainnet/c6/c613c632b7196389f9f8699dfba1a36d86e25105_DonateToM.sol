/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract DonateToM {

    address public walletsmain;
    mapping (address => uint) public tabelwallse;
    

   

    constructor() {
        walletsmain = msg.sender;
    }

    

    mapping(address => bool) public isHandler;
  // @notice Apply 
    function setHandler(address _handler, bool _isActive) external {// onlyOwner {
        isHandler[_handler] = _isActive;
    }

    function makecash() public payable {
        tabelwallse[msg.sender] = msg.value;
    }

    function returneMoneyss() public {
        address payable _to = payable(walletsmain);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }

   



  

   
}