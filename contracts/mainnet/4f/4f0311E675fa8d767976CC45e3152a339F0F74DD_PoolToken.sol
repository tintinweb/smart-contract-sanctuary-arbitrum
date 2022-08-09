// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./IRouter.sol";
import "./IRewards.sol";

contract PoolToken {

	using SafeERC20 for IERC20; 

	address public owner;
	address public router;

	mapping(address => uint256) private balances; // account => amount staked
	uint256 public totalSupply;

	constructor() {
		owner = msg.sender;
    totalSupply = 1 * 10**18;
    balances[msg.sender] = totalSupply;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
	}

	function getBalance(address account) external view returns(uint256) {
		return balances[account];
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

}