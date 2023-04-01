// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Mintable {
  function mint(address to, uint256 amount) external; 
}

contract ClaimWlp {
  uint256 feeAmount;
  Mintable WLP;

  constructor(uint256 _feeAmount, Mintable _WLP) {
    feeAmount = _feeAmount;
    WLP = _WLP;
  }

  function setFeeAmount(uint256 _feeAmount) public {
    feeAmount = _feeAmount;
  }

  function claim() public returns (uint256 _amount) {
    WLP.mint(msg.sender, feeAmount);
    return feeAmount;
  }
}