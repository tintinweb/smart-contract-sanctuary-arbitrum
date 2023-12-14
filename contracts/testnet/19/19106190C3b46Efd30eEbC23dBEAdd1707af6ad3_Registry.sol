// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../interface/IRegistry.sol";

contract Registry is IRegistry {
	mapping(bytes32 => mapping(bytes32 => bytes)) public configs; // key => mapping(hash of name => data)

	function getConfig(
		string memory _key,
		string memory _name
	) external view override returns (bytes memory) {
		bytes32 _keyId = keccak256(abi.encode(_key));
		bytes32 _nameId = keccak256(abi.encode(_name));
		return configs[_keyId][_nameId];
	}

	function setConfig(
		string memory _key,
		string memory _name,
		bytes memory _data
	) external override returns (bool) {
		bytes32 _keyId = keccak256(abi.encode(_key));
		bytes32 _nameId = keccak256(abi.encode(_name));
		configs[_keyId][_nameId] = _data;
		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Use to store contests addrses allowed for the template name
interface IRegistry {
	function getConfig(
		string memory _key,
		string memory _name
	) external view returns (bytes memory);

	function setConfig(
		string memory _key,
		string memory _name,
		bytes memory _data
	) external returns (bool);
}