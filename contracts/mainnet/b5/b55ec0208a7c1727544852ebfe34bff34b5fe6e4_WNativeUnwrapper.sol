// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IWETH.sol";

contract WNativeUnwrapper {
  address public immutable wNative;

  constructor(address _wNative) {
    wNative = _wNative;
  }

  receive() external payable {}

  /**
   * @notice Convert WFTM to FTM and transfer to msg.sender
   * @dev msg.sender needs to send WFTM before calling this withdraw
   * @param _amount amount to withdraw.
   */
  function withdraw(uint256 _amount) external {
    IWETH(wNative).withdraw(_amount);
    (bool sent, ) = msg.sender.call{ value: _amount }("");
    require(sent, "Failed to send native");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
}