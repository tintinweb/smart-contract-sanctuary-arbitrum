// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

contract MockPriceProvider {
	function update() external {}

	function getTokenPrice() public pure returns (uint256) {
		return 10000000; // Mock price
	}

	function decimals() public pure returns (uint256) {
		return 8;
	}
}