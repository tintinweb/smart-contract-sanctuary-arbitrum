// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract Owned {

  address payable owner;
  address payable newOwner;

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "Owner only"
    );
    _;
  }

  function getOwner() external view returns (address) {
    return owner;
  }

  function transferOwnership(address payable _newOwner) external onlyOwner {
    require(
      _newOwner != owner,
      "Owner already"
    );

    require(_newOwner != address(0), "Owner not 0x0");

    newOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == newOwner);
    owner = newOwner;
  }

}

contract Faucet is Owned {

  receive() external payable {}

  function withdraw(uint amount) external onlyOwner {
    require(
      address(this).balance >= amount,
      "Insufficient fund"
    );

    payable(msg.sender).transfer(amount);
  }

  function drip(address reciever, uint amount) external onlyOwner {
    require(
      address(this).balance >= amount,
      "Insufficient fund"
    );

    payable(reciever).transfer(amount);
  }

}