// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/oracles/IPrimaryOracleV2.sol";
import "../interfaces/oracles/ISecondaryOracleV2.sol";
import "../interfaces/oracles/IOracleRouterV2.sol";
import "../interfaces/gmx/IVaultPriceFeedGMX.sol";

contract OracleRouterV3 is IOracleRouterV2 {
	IPrimaryOracleV2 public  primaryPriceFeed; // this is the GMX price feed
	ISecondaryOracleV2 public  secondaryPriceFeed; // this is the alternative price feed
	address public  secondaryToken;



	function updateAddresses(address _primaryFeed, address _secondaryFeed, address _tokenToSecondary) external {
		primaryPriceFeed = IPrimaryOracleV2(_primaryFeed);
		secondaryPriceFeed = ISecondaryOracleV2(_secondaryFeed);
		secondaryToken = _tokenToSecondary;
	}

	function getPriceMax(address _token) external view returns (uint256) {
		if (_token != secondaryToken) {
			// call the gmx/primary oracle
			return primaryPriceFeed.getPrice(_token, true, false, false);
		} else {
			require(
				_token == secondaryToken,
				"OracleRouterV2: only works for secondary token"
			);
			return secondaryPriceFeed.getPriceMax(_token);
		}
	}

	function getPriceMin(address _token) external view returns (uint256) {
		if (_token != secondaryToken) {
			// call the gmx/primary oracle
			return primaryPriceFeed.getPrice(_token, false, false, false);
		} else {
			require(
				_token == secondaryToken,
				"OracleRouterV2: only works for secondary token"
			);
			return secondaryPriceFeed.getPriceMin(_token);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPrimaryOracleV2 {
	function getPrice(
		address _token,
		bool _maximise,
		bool _includeAmmPrice,
		bool _useSwapPricing
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface ISecondaryOracleV2 {
	function getPriceMax(address _token) external view returns (uint256);

	function getPriceMin(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IOracleRouterV2 {
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