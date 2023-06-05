// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/oracles/IPrimaryOracleV1.sol";
import "../interfaces/oracles/IOracleRouterV1.sol";

contract OracleRouterV1 is IOracleRouterV1 {
	address public immutable primaryPriceFeedAddress =
		0x2d68011bcA022ed0E474264145F46CC4de96a002;
	IPrimaryOracleV1 public immutable primaryPriceFeed;

	constructor() {
		primaryPriceFeed = IPrimaryOracleV1(primaryPriceFeedAddress);
	}

	function getPriceMax(address _token) external view returns (uint256) {
		return primaryPriceFeed.getPrice(_token, true, false, false);
	}

	function getPriceMin(address _token) external view returns (uint256) {
		return primaryPriceFeed.getPrice(_token, false, false, false);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPrimaryOracleV1 {
	function getPrice(
		address _token,
		bool _maximise,
		bool _includeAmmPrice,
		bool _useSwapPricing
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IOracleRouterV1 {
	function getPriceMax(address _token) external view returns (uint256);

	function getPriceMin(address _token) external view returns (uint256);
}