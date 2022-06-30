// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract MockOracle {
	uint256 public currentPrice;
	uint256 public lastPrice;
	uint256 public lastUpdate;
	uint8 public decimals;

	function setUp(
		uint256 current,
		uint256 last,
		uint8 dec
	) external {
		currentPrice = current;
		lastPrice = last;
		lastUpdate = block.timestamp;
		decimals = dec;
	}

	function setDecimals(uint8 _decimals) external {
		decimals = _decimals;
	}

	function setLastPrice(uint256 _lastPrice) external {
		lastPrice = _lastPrice;
	}

	function update(uint256 newPrice) external {
		lastPrice = currentPrice;
		currentPrice = newPrice;
		lastUpdate = block.timestamp;
	}
}