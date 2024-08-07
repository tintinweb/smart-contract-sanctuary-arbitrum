// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Verifies stakingToken to be staked and unstaked, accruing rewardsToken.
/// @author Wayne (Ellerian Prince)
/// @notice Allows validation of signatures to enable gasless in-game actions.
/// @dev See the following links: 
///      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
///      https://eips.ethereum.org/EIPS/eip-712
///      Any contracts/logic reliant on this must also have logic guarding against replay attacks.
///      This contract was written with the specific intention of validating only a signature generated from the following parameter types:
///      {address, uint256, string, uint256} or {uint256[]}
contract VerifySignature {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // No error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /// @notice Verifies if a signature corresponds with the supplied data and signer.
    ///         This takes in a fixed set of parameters: {address, uint256, string, uint256}
    /// @dev If any parameter is supplied incorrectly, verification fails as the signature does not recover to the original signer.
    ///      This works on the assumption that all parameters are supplied properly and not falsified.
    /// @param _signer Address to validate against.
    /// @param _to Signature Payload.
    /// @param _amount Signature Payload.
    /// @param _message Signature Payload.
    /// @param _nonce Signature Payload.
    /// @param _signature Signature generated by the signer, using the specified payload.
    function verify( 
        address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory _signature 
        ) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (address recovered, RecoverError err) = tryRecover(ethSignedMessageHash, _signature);
        _throwError(err);

        return recovered == _signer;
    }

    /// @notice Verifies if a signature corresponds with the supplied data and signer.
    ///         This takes in a {uint256[]} of any length.
    /// @dev If any parameter is supplied incorrectly, verification fails as the signature does not recover to the original signer.
    ///      This works on the assumption that all parameters are supplied properly and not falsified.
    /// @param _signer Address to validate against.
    /// @param _data Signature Payload.
    /// @param _signature Signature generated by the signer, using the specified payload.
    function bigVerify( 
        address _signer, address _to, uint256[] memory _data, bytes memory _signature 
        ) external pure returns (bool) {
        bytes32 messageHash = getBigMessageHash(_to, _data);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (address recovered, RecoverError err) = tryRecover(ethSignedMessageHash, _signature);
        _throwError(err);

        return recovered == _signer;
    }
    
    /**
    * @dev Returns a hash based on the supplied parameters.
    * This must be used in conjunction with {getEthSignedMessageHash}.
    */
    function getMessageHash(address _to, uint256 _amount, string memory _message, uint256 _nonce) 
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    /**
    * @dev Returns a hash based on the supplied parameters.
    * This must be used in conjunction with {getEthSignedMessageHash}.
    */
    function getBigMessageHash(address _to, uint256[] memory _data) 
    public pure returns (bytes32) {
        bytes memory data = '';
        for (uint256 i = 0; i < _data.length; i++) {
            data = abi.encodePacked(data, _data[i]);
        }
        return keccak256(abi.encodePacked(_to, data));
    }

    /**
    * @dev A Ethereum specific signature is produced by signing a keccak256 hash with the following format:
    * "\x19Ethereum Signed Message\n" + len(msg) + msg
    * 
    * By adding a prefix to the message makes the calculated signature recognizable as an Ethereum specific signature.
    * This prevents misuse where a malicious dapp can sign arbitrary data (e.g. transaction) and use the signature to impersonate the victim.
    * 
    * See: https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_sign
    */
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
     */
    function tryRecover(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address, RecoverError) {
        if (_signature.length == 65) {

            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                // First 32 bytes stores the length of the signature.
                // {add(sig, 32) = pointer of sig + 32} effectively, skips first 32 bytes of the signature.
                // mload(p) loads next 32 bytes starting at the memory address p into memory.

                // First 32 bytes, after the length prefix.
                r := mload(add(_signature, 32))
                // Second 32 bytes.
                s := mload(add(_signature, 64))
                // Final byte (first byte of the next 32 bytes).
                v := byte(0, mload(add(_signature, 96)))
            }

            // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
            // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
            // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
            // signatures from current libraries generate a unique signature with an s-value in the lower half order.
            //
            // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
            // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
            // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
            // these malleable signatures as well.
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                return (address(0), RecoverError.InvalidSignatureS);
            }

            // If the signature is valid (and not malleable), return the signer address
            address signer = ecrecover(_ethSignedMessageHash, v, r, s);
            if (signer == address(0)) {
                return (address(0), RecoverError.InvalidSignature);
            }

            return (signer, RecoverError.NoError);
        } 
            
        return (address(0), RecoverError.InvalidSignatureLength);      
    }
}