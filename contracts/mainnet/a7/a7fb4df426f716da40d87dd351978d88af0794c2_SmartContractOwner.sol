// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

contract SmartContractOwner {
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    function isValidSignature(bytes32 _dataHash, bytes calldata _signature) external view returns (bytes4) {
        return MAGIC_VALUE;
    }
}