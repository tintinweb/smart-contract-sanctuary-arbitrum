/**
 *Submitted for verification at Arbiscan on 2022-10-17
*/

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

contract CommonRegistryXChain is ICommonRegistryXChain {

    mapping(bytes32 => address) public contracts;

    event ClearAddress(string _name, bytes32 _hash, address _oldAddr);
    event SetAddress(string _name, bytes32 _hash, address _addr);
    event SetGovernance(address _oldGov, address _newGov);

    modifier onlyGovernance() {
		bytes32 _hash = keccak256(abi.encode("GOVERNANCE"));
        address governance = contracts[_hash];
		require(msg.sender == governance, "!gov");
		_;
	}

    constructor(address _governance) {
        require(_governance != address(0), "zero address");
        bytes32 _hash = keccak256(abi.encode("GOVERNANCE"));
        contracts[_hash] = _governance;
    }

    /**
	 * @dev Function to set a new name <-> address
	 * @param _name string name
	 * @param _addr address to set for the given name
	 */
    function setAddress(string calldata _name, address _addr) public override onlyGovernance {
        require(_addr != address(0), "zero address");
        bytes32 _hash = keccak256(abi.encode(_name));
        contracts[_hash] = _addr;
        emit SetAddress(_name, _hash, _addr);
    }

    /**
	 * @dev Function to set zero address for the given name
	 * @param _name string name
	 */
    function clearAddress(string calldata _name) external override onlyGovernance {
        bytes32 _hash = keccak256(abi.encode(_name));
        require(contracts[_hash] != address(0), "nothing to clear");
        emit ClearAddress(_name, _hash, contracts[_hash]);
        contracts[_hash] = address(0);
    }

    /**
	 * @dev Function to get the address given the name
	 * @param _name string name
	 */
    function getAddr(string calldata _name) external view override returns(address) {
        bytes32 _hash = keccak256(abi.encode(_name));
        return contracts[_hash];
    }

    /**
	 * @dev Function to get the address only if it is not zero address
     * @notice it accepts a string name calculating the hash
	 * @param _name string name
	 */
    function getAddrIfNotZero(string calldata _name) external view override returns(address) {
        bytes32 _hash = keccak256(abi.encode(_name));
        address returnAddr = contracts[_hash];
        require(returnAddr != address(0), "zero address");
        return returnAddr;
    }

    /**
	 * @dev Function to get the address only if it is not zero address
     * @notice it accepts directly the hash
	 * @param _hash hash of the name
	 */
    function getAddrIfNotZero(bytes32 _hash) external view override returns(address) {
        address returnAddr = contracts[_hash];
        require(returnAddr != address(0), "zero address");
        return returnAddr;
    }
}