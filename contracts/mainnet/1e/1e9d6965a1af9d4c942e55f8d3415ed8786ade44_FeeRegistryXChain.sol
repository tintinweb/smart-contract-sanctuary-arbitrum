// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IFeeRegistryXChain } from "./interfaces/IFeeRegistryXChain.sol";
import { ICommonRegistryXChain } from "./interfaces/ICommonRegistryXChain.sol";

contract FeeRegistryXChain is IFeeRegistryXChain {

	ICommonRegistryXChain public immutable registry;
	bytes32 public constant GOVERNANCE = keccak256(abi.encode("GOVERNANCE"));
	bytes32 public constant CURVE_FACTORY = keccak256(abi.encode("CURVE_FACTORY"));
	uint256 public constant override BASE_FEE = 10000;

    mapping(address => mapping(address => uint256)) public perfFees; // gauge -> token -> fee
	mapping(address => mapping(address => uint256)) public accumulatorFees; // gauge -> token -> fee
	mapping(address => mapping(address => uint256)) public claimerRewardFees; // gauge -> token -> fee
	mapping(address => mapping(address => uint256)) public veSDTFees; // gauge -> token -> fee

    event SetFee(address gauge, address token, MANAGEFEE feeType, uint256 newFee);

	modifier onlyGovernanceOrFactory() {
		address governance = registry.getAddrIfNotZero(GOVERNANCE);
		address factory = registry.getAddrIfNotZero(CURVE_FACTORY);
		require(msg.sender == governance || msg.sender == factory, "!governance && !factory");
		_;
	}

    constructor(address _registry) {
        require(_registry != address(0), "zero address");
		registry = ICommonRegistryXChain(_registry);
    }

	/// @notice function to set fee
	/// @param _manageFee manageFee type
	/// @param _gauge gauge address
	/// @param _token token address
	/// @param _newFee new fee to set
	function manageFee(
		MANAGEFEE _manageFee, 
		address _gauge, 
		address _token, 
		uint256 _newFee
	) external override onlyGovernanceOrFactory {
		_setFee(_manageFee, _gauge, _token, _newFee);
	}

    /// @notice function to set multi fees
	/// @param _manageFees manageFees type
	/// @param _gauges gauge addresses
	/// @param _tokens token addresses
	/// @param _newFees new fees to set
	function manageFees(
		MANAGEFEE[] calldata _manageFees,
        address[] calldata _gauges,
		address[] calldata _tokens,
		uint256[] calldata _newFees
	) external override onlyGovernanceOrFactory {
		for (uint256 i; i < _gauges.length; i++) {
			_setFee(_manageFees[i], _gauges[i], _tokens[i], _newFees[i]);
		}
	}

    /// @notice internal function to new fees
	/// @param _manageFee manageFee type
	/// @param _gauge gauge address
	/// @param _token token address
	/// @param _newFee new fee to set
	function _setFee(
		MANAGEFEE _manageFee,
        address _gauge,
		address _token,
		uint256 _newFee
	) internal {
		require(_gauge != address(0), "zero address");
        require(_token != address(0), "zero address");
		if (_manageFee == MANAGEFEE.PERFFEE) {
			// 0
			perfFees[_gauge][_token] = _newFee;
		} else if (_manageFee == MANAGEFEE.VESDTFEE) {
			// 1
			veSDTFees[_gauge][_token] = _newFee;
		} else if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
			//2
			accumulatorFees[_gauge][_token] = _newFee;
		} else if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
			// 3
			claimerRewardFees[_gauge][_token] = _newFee;
		}
		require(
			perfFees[_gauge][_token] + 
			veSDTFees[_gauge][_token] + 
			accumulatorFees[_gauge][_token] + 
			claimerRewardFees[_gauge][_token] <= BASE_FEE,
			"fee to high"
		);
        emit SetFee(_gauge, _token, _manageFee, _newFee);
	}

	/// @notice utility function to get fees
	/// @param _gauge gauge address
	/// @param _token token address
	/// @param _manageFee type of fee 
    function getFee(address _gauge, address _token, MANAGEFEE _manageFee) external view override returns(uint256) {
        if (_manageFee == MANAGEFEE.PERFFEE) {
			// 0
			return perfFees[_gauge][_token];
		}
		if (_manageFee == MANAGEFEE.VESDTFEE) {
			// 1
			return veSDTFees[_gauge][_token];
		}
		if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
			//2
			return accumulatorFees[_gauge][_token];
		}
		if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
			// 3
			return claimerRewardFees[_gauge][_token];
		}
		return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICommonRegistryXChain {
    function contracts(bytes32 _hash) external view returns(address);
    function clearAddress(string calldata _name) external;
    function setAddress(string calldata _name, address _addr) external;
    function getAddr(string calldata _name) external view returns(address);
    function getAddrIfNotZero(string calldata _name) external view returns(address);
    function getAddrIfNotZero(bytes32 _hash) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeRegistryXChain {
    enum MANAGEFEE {
		PERFFEE,
		VESDTFEE,
		ACCUMULATORFEE,
		CLAIMERREWARD
	}
    function BASE_FEE() external returns(uint256);
    function manageFee(MANAGEFEE, address, address, uint256) external;
    function manageFees(MANAGEFEE[] calldata, address[] calldata, address[] calldata, uint256[] calldata) external; 
    function getFee(address, address, MANAGEFEE) external view returns(uint256);
}