/**
 *Submitted for verification at Etherscan.io on 2019-10-19
 */

pragma solidity >=0.8.19;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

contract Disperse {
  function disperseEther(address[] calldata recipients, uint256[] calldata values) external payable {
    for (uint256 i = 0; i < recipients.length; i++) {
      (bool success, ) = recipients[i].call{ value: values[i] }("");
      require(success, "Failed to send ether");
    }
    uint256 balance = address(this).balance;
    if (balance > 0) {
      (bool success, ) = msg.sender.call{ value: balance }("");
      require(success, "Failed to refund ETH");
    }
  }

  function disperseToken(
    IERC20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    uint256 total = 0;
    for (uint256 i = 0; i < recipients.length; i++) total += values[i];
    require(token.transferFrom(msg.sender, address(this), total));
    for (uint256 i = 0; i < recipients.length; i++) require(token.transfer(recipients[i], values[i]));
  }

  function disperseTokenSimple(
    IERC20 token,
    address[] calldata recipients,
    uint256[] calldata values
  ) external {
    for (uint256 i = 0; i < recipients.length; i++) require(token.transferFrom(msg.sender, recipients[i], values[i]));
  }
}