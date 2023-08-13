// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeefyContractDeployer {

    event ContractDeployed(bytes32 indexed salt, address deploymentAddress);

    // Deploy a contract, if this address matches contract deployer on other chains it should match deployment address if salt/bytecode match., 
    function deploy(bytes32 _salt, bytes memory _bytecode) external returns (address deploymentAddress) {
        address addr;
        assembly {
            addr := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)
            if iszero(extcodesize(addr)) {
                 revert(0, 0)
            }
        }

        emit ContractDeployed(_salt, addr);
        return addr;
    }

    // Get address by salt and bytecode.
    function getAddress(bytes32 _salt, bytes memory _bytecode) external view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(_bytecode)
            )
        );
        return address (uint160(uint(hash)));
    }

    // Creat salt by int or string.
    function createSalt(uint _num, string calldata _string) external pure returns (bytes32) {
        return _num > 0 ? keccak256(abi.encode(_num)) : keccak256(abi.encode(_string));
    }
}