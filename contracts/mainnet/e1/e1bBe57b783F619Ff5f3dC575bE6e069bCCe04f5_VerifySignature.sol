pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// Sourced from https://solidity-by-example.org/signature/
contract VerifySignature {

    function getMessageHash(address _to, uint256 _amount, string memory _message, uint256 _nonce) 
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce,
     bytes memory signature ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function getBigMessageHash(address _to, uint256[] memory _data) 
    public pure returns (bytes32) {
        bytes memory data = '';
        for (uint256 i = 0; i < _data.length; i++) {
            data = abi.encodePacked(data, _data[i]);
        }
        return keccak256(abi.encodePacked(_to, data));
    }

    function bigVerify( address _signer, address _to, uint256[] memory _data,
     bytes memory signature ) public pure returns (bool) {
        bytes32 messageHash = getBigMessageHash(_to, _data);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function splitSignature(bytes memory sig) public pure returns ( bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}