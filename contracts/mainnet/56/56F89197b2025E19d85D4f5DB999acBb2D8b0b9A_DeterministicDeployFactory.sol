// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeterministicDeployFactory {
    event Deploy(address addr);

    error DeployError();

    function deploy(bytes memory bytecode, uint256 salt) external payable returns (address addr) {
        uint256 value = msg.value;
        assembly {
            addr := create2(value, add(0x20, bytecode), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert DeployError();
        }
        emit Deploy(addr);
    }

    function getAddress(bytes memory bytecode, uint256 salt) external view returns (address addr) {
        addr = address(uint160(uint256(keccak256(abi.encodePacked(uint8(0xff), this, salt, keccak256(bytecode))))));
    }
}