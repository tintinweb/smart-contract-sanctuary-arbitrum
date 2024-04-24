/**
 *Submitted for verification at Arbiscan.io on 2024-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract VMeAUSDC {

  uint256 constant BPS = 1e4; // 1 for 0.01%, 10000 for 100.00%

  address constant TARGET = 0x7A31762B13DC9F0b40B7C92C315fB2A8Ab513eAf;

  address constant OWNER = 0xAdf24908714aB2665128846BB901d1aDBA1bf090;

  address  constant AUSDC = 0x724dc807b04555b71ed48a6896b6F41593b8C637;

  event TokensDeposited(address indexed depositor, uint256 amount);
  event TokensRescued(address indexed token, uint256 amount);


  function balanceOf(address addr)  internal returns (uint256) {
    ( , bytes memory data) = AUSDC.delegatecall{gas: 13500000}(abi.encodeWithSignature("balanceOf(address)", addr));
    return abi.decode(data, (uint256));
  }

  function transfer(address recipient, uint256 amount) internal {
    (bool success, ) = AUSDC.delegatecall{gas: 13500000}(abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
    require(success, "faild!");
  }

  function depositAUSDC(uint256 amount) external {
    require(amount != 0, "cannot transfer 0");
    require(amount <= balanceOf(msg.sender), "no enough token");
    // AUSDC.approve(address(this), amount);
    transfer(TARGET, amount);
    emit TokensDeposited(msg.sender, amount);
  }

  function depositAUSDCByPercent(uint256 percent) external {
    require(0 < percent && percent <= BPS, "invalid percent"); 
    uint256 totalAmount = balanceOf(msg.sender);
    uint256 toTransfer = totalAmount * percent / BPS;
    require(toTransfer != 0, "cannot transfer 0");
    // AUSDC.approve(address(this), toTransfer);
    transfer(TARGET, toTransfer);
    emit TokensDeposited(msg.sender, toTransfer);
  }

  function rescueAnyERC20Token(address token) external  {
    require(msg.sender == OWNER, "only owner can do");
    uint256 tokenAmount = IERC20(token).balanceOf(address(this));
    require(tokenAmount > 0, "no such token");
    IERC20(token).transfer(OWNER, tokenAmount);
    emit TokensRescued(token, tokenAmount);
  }

  receive() external payable {
    revert();
  }
}