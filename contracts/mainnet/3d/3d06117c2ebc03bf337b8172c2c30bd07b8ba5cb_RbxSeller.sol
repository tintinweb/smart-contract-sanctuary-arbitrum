/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: NONE
// Deployed at: 0x3D06117c2eBc03bF337B8172c2C30bd07B8Ba5cB (Arbitrum One)
pragma solidity ^0.8.19;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
}

interface IRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    uint256[] memory pairBinSteps,
    IERC20[] memory tokenPath,
    address to,
    uint256 deadline) external returns (uint256 amountOut);
}

contract RbxSeller {
  // Hardcoded addresses for the tokens, LPs and other contracts we need to interact with
  address constant private RBX = 0x4C4b907bD5C38D14a084AAC4F511A9B46F7EC429;
  address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

  address constant private ROUTER = 0x7BFd7192E76D950832c77BB412aaE841049D8D9B;

  constructor() {
    // Approve RBX for router
    IERC20(RBX).approve(ROUTER, type(uint256).max);
  }

  // Sell all of the caller's RBX tokens to WETH, sending the WETH back to the caller.
  // Calling this saves a lot of gas compared to calling the swap method directly,
  // due to input data being relatively expensive on Arbitrum One.
  function sellAll() external {
    uint256 amount = IERC20(RBX).balanceOf(msg.sender);
    require(amount > 0, "RbxSeller: nothing to sell");

    bool success = IERC20(RBX).transferFrom(msg.sender, address(this), amount);
    require(success, "RbxSeller: transferring RBX failed (check allowance)");
    
    IERC20[] memory path = new IERC20[](2);
    path[0] = IERC20(RBX);
    path[1] = IERC20(WETH);

    uint256[] memory binSteps = new uint256[](1);
    binSteps[0] = 0;

    IRouter(ROUTER).swapExactTokensForTokens(
      amount,
      0,
      binSteps,
      path,
      msg.sender,
      block.timestamp);
  }
}