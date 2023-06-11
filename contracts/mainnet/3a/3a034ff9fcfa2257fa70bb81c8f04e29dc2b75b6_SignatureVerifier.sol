/**
 *Submitted for verification at Arbiscan on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignatureVerifier {
    
    function VerifyMessage(bytes32 hashedMessage, bytes memory signature) public pure returns (address signer) {

        require(signature.length == 65, "Invalid signature length.");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return address(0);
        }

        // Extract signature components
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        signer = ecrecover(prefixedHashMessage, v, r, s);
        return signer;
    }
}