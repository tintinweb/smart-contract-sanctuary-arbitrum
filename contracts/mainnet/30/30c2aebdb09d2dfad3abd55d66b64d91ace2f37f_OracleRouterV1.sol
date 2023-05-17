// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/oracles/IPrimaryOracleV1.sol";
import "../interfaces/oracles/IOracleRouterV1.sol";
import "../interfaces/gmx/IVaultPriceFeedGMX.sol";

contract OracleRouterV1 is IOracleRouterV1 {
	IPrimaryOracleV1 public immutable primaryPriceFeed; 

	constructor(
		address _primaryFeed
	) {
		primaryPriceFeed = IPrimaryOracleV1(_primaryFeed);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultPriceFeedGMX {
	function adjustmentBasisPoints(address _token) external view returns (uint256);

	function isAdjustmentAdditive(address _token) external view returns (bool);

	function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;

	function setUseV2Pricing(bool _useV2Pricing) external;

	function setIsAmmEnabled(bool _isEnabled) external;

	function setIsSecondaryPriceEnabled(bool _isEnabled) external;

	function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;

	function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;

	function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

	function setPriceSampleSpace(uint256 _priceSampleSpace) external;

	function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;

	function getPrice(
		address _token,
		bool _maximise,
		bool _includeAmmPrice,
		bool _useSwapPricing
	) external view returns (uint256);

	function getAmmPrice(address _token) external view returns (uint256);

	function getLatestPrimaryPrice(address _token) external view returns (uint256);

	function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);

	function setTokenConfig(
		address _token,
		address _priceFeed,
		uint256 _priceDecimals,
		bool _isStrictStable
	) external;

	// added by WINR

	function getPriceV1(
		address _token,
		bool _maximise,
		bool _includeAmmPrice
	) external view returns (uint256);

	function getPriceV2(
		address _token,
		bool _maximise,
		bool _includeAmmPrice
	) external view returns (uint256);

	function getAmmPriceV2(
		address _token,
		bool _maximise,
		uint256 _primaryPrice
	) external view returns (uint256);

	function getSecondaryPrice(
		address _token,
		uint256 _referencePrice,
		bool _maximise
	) external view returns (uint256);

	function getPairPrice(address _pair, bool _divByReserve0) external view returns (uint256);
}