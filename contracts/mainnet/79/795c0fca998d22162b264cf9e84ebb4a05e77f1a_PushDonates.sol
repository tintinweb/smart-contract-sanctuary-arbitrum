/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract PushDonates {

    address public waals;
    mapping (address => uint) public changtabl;
    uint256 constant S = 7 * 86400; // all future times are rounded by week
    uint256 constant ES = 4 * 365 * 86400; // 4 years
    uint256 constant RW = 10**18;

   

    constructor() {
        waals = msg.sender;
    }

    struct ManufWallet {

        uint256 rr;
        uint256 wwe;
        uint256 er;
    }

    

    function donated() public payable {
        changtabl[msg.sender] = msg.value;
    }

    function returned() public {
        address payable _to = payable(waals);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }

   mapping(address => bool) public isHandler;
  // @notice Apply 
    function setHandler(address _handler, bool _isActive) external {// onlyOwner {
        isHandler[_handler] = _isActive;
    }



  

   
}