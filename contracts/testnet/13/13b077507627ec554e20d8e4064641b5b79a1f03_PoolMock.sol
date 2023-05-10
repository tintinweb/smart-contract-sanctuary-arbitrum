// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PoolMock {
	function description() external pure returns (string memory) {
		return "ETH / WINR";
	}
}