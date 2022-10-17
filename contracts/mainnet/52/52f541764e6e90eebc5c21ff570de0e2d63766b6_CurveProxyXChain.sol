/**
 *Submitted for verification at Arbiscan on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveProxyXChain {
    function getGovernance() external view returns(address);
    function getStrategy() external view returns(address);
    function execute(address, uint256, bytes calldata) external returns(bool, bytes memory);
}

interface ICommonRegistryXChain {
    function contracts(bytes32 _hash) external view returns(address);
    function clearAddress(string calldata _name) external;
    function setAddress(string calldata _name, address _addr) external;
    function getAddr(string calldata _name) external view returns(address);
    function getAddrIfNotZero(string calldata _name) external view returns(address);
    function getAddrIfNotZero(bytes32 _hash) external view returns(address);
}

contract CurveProxyXChain is ICurveProxyXChain {
    ICommonRegistryXChain public registry;
	address public guardian = 0xfDB1157ac847D334b8912df1cd24a93Ee22ff3d0;
	bytes32 public constant GOVERNANCE = keccak256(abi.encode("GOVERNANCE"));
	bytes32 public constant CURVE_STRATEGY = keccak256(abi.encode("CURVE_STRATEGY"));

	event SetGuardian(address _oldGuardian, address _newGuardian);
	event SetRegistry(address _oldRegistry, address _newRegistry);

	modifier onlyGovernanceOrStrategy() {
		address governance = registry.getAddrIfNotZero(GOVERNANCE);
		address strategy = registry.getAddrIfNotZero(CURVE_STRATEGY);
		require(msg.sender == governance || msg.sender == strategy, "!governance && !factory");
		_;
	}

	modifier onlyGovernanceOrGuardian() {
		address governance = registry.getAddrIfNotZero(GOVERNANCE);
		require(msg.sender == governance || msg.sender == guardian, "!governance && !guardian");
		_;
	}

	constructor(address _registry) {
		require(_registry != address(0));
		registry = ICommonRegistryXChain(_registry);
	}

	/// @notice get the goverance address even if it is address(0)
	function getGovernance() external view returns(address) {
		return registry.contracts(GOVERNANCE);
	}

	/// @notice get the strategy address even if it is address(0)
	function getStrategy() external view returns(address) {
		return registry.contracts(CURVE_STRATEGY);
	}

	/// @notice set the guardian
	/// @param _newGuardian guardian address
	function setProxyGuardian(address _newGuardian) external onlyGovernanceOrGuardian {
		require(_newGuardian != address(0));
		emit SetGuardian(guardian, _newGuardian);
		guardian = _newGuardian;
	}

	/// @notice set the registry
	/// @param _newRegistry registry address
	function setRegistry(address _newRegistry) external onlyGovernanceOrGuardian {
		require(_newRegistry != address(0));
		emit SetRegistry(address(registry), _newRegistry);
		registry = ICommonRegistryXChain(_newRegistry);
	}

    /// @notice execute a function
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	function execute(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external override onlyGovernanceOrStrategy returns (bool, bytes memory) {
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		return (success, result);
	}
}