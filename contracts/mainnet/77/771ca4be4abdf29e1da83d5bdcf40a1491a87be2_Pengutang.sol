/**
 *Submitted for verification at Arbiscan on 2023-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
interface BukanBadex{
  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external;
}
interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function withdraw(uint256 wad) external;
  function deposit(uint256 wad) external returns (bool);
}

interface IBalancerVault {
  function flashLoan(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

contract Pengutang is BukanBadex {
  IERC20 dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
  IBalancerVault vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  function Gas() public returns (bool) {
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1 ether;
    vault.flashLoan(address(this), tokens, amounts, "");
    return true;
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override{
      tokens;
      amounts;
      feeAmounts;
      userData;

    uint256 dai_balance = dai.balanceOf(address(this));
    //terserah mau ngapain
    //end terserah mau ngapain
    dai.transfer(address(vault), dai_balance);
    dai_balance = dai.balanceOf(address(this));
  }
}