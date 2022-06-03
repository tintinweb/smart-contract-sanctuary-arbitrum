//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AddressHash {

    function getHash(address addr) view public  returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(addr));
    }
}