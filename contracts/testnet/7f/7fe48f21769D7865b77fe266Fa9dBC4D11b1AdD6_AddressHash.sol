//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AddressHash {
    function getHash(address _addr) external returns(bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }
}