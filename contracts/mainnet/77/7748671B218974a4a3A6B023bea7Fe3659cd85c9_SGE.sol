// SPDX-License-Identifier: MIT
//   _   _ __  ____  __
//  | | | |  \/  \ \/ /
//  | |_| | |\/| |\  /
//  |  _  | |  | |/  \
//  |_| |_|_|  |_/_/\_\
pragma solidity 0.8.18;

// OZ
import {Ownable} from "./Ownable.sol";
import {IERC20} from "./IERC20.sol";

import {LHMX} from "./LHMX.sol";

contract SGE is Ownable {
  LHMX public lhmx;
  IERC20 public usdc;
  mapping(address => uint256) public allocations;
  uint256 public deadline;

  constructor(
    IERC20 _usdc,
    LHMX _lhmx,
    address[] memory _accounts,
    uint256[] memory _amounts,
    uint256 _deadline
  ) {
    // Check
    require(_accounts.length == _amounts.length, "bad alloc");

    // Effect
    usdc = IERC20(_usdc);
    lhmx = LHMX(_lhmx);
    deadline = _deadline;

    for (uint256 i = 0; i < _accounts.length;) {
      allocations[_accounts[i]] = _amounts[i];
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Execute the allocation. msgSender will get LHMX.
  function execute() external {
    // Check
    require(block.timestamp <= deadline, "expired");
    require(allocations[msg.sender] > 0, "no alloc");

    // Effect
    uint256 _amount = allocations[msg.sender];
    allocations[msg.sender] = 0;

    // Interaction
    usdc.transferFrom(msg.sender, address(this), _amount);
    lhmx.mint(msg.sender, _amount * 2e12);
  }

  /// @notice Pull USDC to "_to".
  /// @dev This function is only callable by the owner.
  /// @param _to The address to pull USDC to.
  function pull(address _to) external onlyOwner {
    require(_to != address(0), "zero");
    usdc.transfer(_to, usdc.balanceOf(address(this)));
  }
}