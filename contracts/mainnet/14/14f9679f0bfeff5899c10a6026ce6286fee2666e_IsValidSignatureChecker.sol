/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.26;

contract IsValidSignatureChecker {
    function isValidSignature(address account, bytes32 hash, bytes calldata signature) public view returns (bytes4) {
        return IERC1271(account).isValidSignature(hash, signature);
    }
}

interface IERC1271 {
    function isValidSignature(bytes32, bytes calldata) external view returns (bytes4);
}