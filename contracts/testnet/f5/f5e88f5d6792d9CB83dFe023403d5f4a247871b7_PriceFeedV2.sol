/**
 *Submitted for verification at Arbiscan.io on 2023-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// import "./interfaces/IPriceFeedV2.sol";
// import "./interfaces/IOracleChainLinkMock.sol";
interface IOracleChainLinkMock {
	function defaultTokenAddress() external view returns (address);

	function description() external view returns (string memory);

	function aggregator() external view returns (address);

	function latestRound() external view returns (uint80);

	function setPriceSet(uint256 _price) external;

	function getRoundData(
		uint256 _roundId
	) external view returns (uint80, int256, uint256, uint256, uint80);

	function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract PriceFeedV2 {
	mapping(address => uint256) public tokenPrices;
	bool public anybodyCanSetPrices = true;
	address public owner;
	mapping(address => bool) public priceSetters;
	bool public malfunction = false;

	address public defaultTokenAddress;
	mapping(address => address) public chainLinkOracle;

	error OracleMalfunctionSet();

	event PriceUpdate(
		address token, // address of token where the price has been set for
		uint256 price, // NOTE BERKANT: this is the actual relevant price that is set in the tx!
		address priceFeed // address of FastPriceFeed
	);

	constructor(address _newOwner) {
		owner = _newOwner;
		priceSetters[_newOwner] = true;
	}

	function addMockOracle(address _token, address _chainlinkMock) external {
		require(msg.sender == owner, "PriceFeedMock: Only owner can add a mock oracle");
		chainLinkOracle[_token] = _chainlinkMock;
	}

	function setDefaultTokenAddress(address _token) external {
		defaultTokenAddress = _token;
	}

	event MockOracle(address token, address mockOracle);

	function setPrice(address _token, uint256 _price) external {
		// require(_checkCaller(), "Caller cannot set price");
		emit PriceUpdate(_token, _price, address(this));
		tokenPrices[_token] = _price;
		address chainlinkMock = chainLinkOracle[_token];
		emit MockOracle(_token, chainlinkMock);
		require(
			chainlinkMock != address(0),
			"PriceFeedMock: No mock oracle set for this token"
		);
		IOracleChainLinkMock(chainlinkMock).setPriceSet(_price);
	}

	function makeOracleMalfunction(bool _setting) external {
		// require(_checkCaller(), "Caller cannot set malfunction");
		malfunction = _setting;
	}

	function setAnybodyCanSet(bool _setting) external {
		// require(msg.sender == owner, "PriceFeedMock: Only owner can flip this");
		anybodyCanSetPrices = _setting;
	}

	function setPriceSetter(address _setter, bool _setting) external {
		// require(msg.sender == owner, "PriceFeedMock: Only owner can add a setter");
		priceSetters[_setter] = _setting;
	}

	// View functions //

	function getPrimaryPrice(address _token, bool _bool) external view returns (uint256) {
		if (malfunction) {
			revert OracleMalfunctionSet();
		}
		// revert("getPrimaryPrice: New oracle system does not use this function");
		return tokenPrices[_token];
	}

	function getPrice(
		address _token,
		bool _maximise,
		bool _includeAmmPrice,
		bool _useSwapPricing
	) external view returns (uint256) {
		// if (malfunction) {
		// 	revert OracleMalfunctionSet();
		// }
		// revert("getPrice: New oracle system does not use this function");
		return tokenPrices[_token];
	}

	function getPriceMax(address _token) external view returns (uint256) {
		// revert("getPriceMax: New oracle system does not use this function");
		return tokenPrices[_token];
	}

	function getPriceMin(address _token) external view returns (uint256) {
		// revert("getPriceMin: New oracle system does not use this function");
		return tokenPrices[_token];
	}

	// mock function that is present in the 'real' pricefeed contract, has no function for WINR
	function isAdjustmentAdditive(address _token) external pure returns (bool) {
		return false;
	}

	// mock function that is present in the 'real' pricefeed contract, has no function for WINR
	function adjustmentBasisPoints(address _token) external pure returns (uint256) {
		return 0;
	}

	function _checkCaller() internal view returns (bool) {
		if (anybodyCanSetPrices) {
			return true;
		} else {
			return (priceSetters[msg.sender]);
		}
	}
}