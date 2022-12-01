// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ERC20.sol";

contract USDC is ERC20 {

  constructor() ERC20("USDC Custom", "USDC") {
    _mint(msg.sender, 2000000e6);
  }
}