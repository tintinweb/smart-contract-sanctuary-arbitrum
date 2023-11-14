// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./BaseValidator.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
/**
 * @title DefaultValidator
 * @dev Provides default implementations for signature hash packing
 */

contract DefaultValidator is BaseValidator {
    // Utility for Ethereum typed structured data hashing
    using MessageHashUtils for bytes32;
    // Utility for converting addresses to bytes32
    using TypeConversion for address;

    /**
     * @dev Packs the given hash with the specified validation data based on the signature type
     *      - Type 0x0: Standard Ethereum signed message
     *      - Type 0x1: Ethereum signed message combined with validation data
     *      - Type 0x2: Passkey signature (unchanged hash)
     *      - Type 0x3: Passkey signature combined with validation data
     * @param hash The original hash to be packed
     * @param signatureType The type of signature
     * @param validationData same as defined in EIP4337
     * @return packedHash The resulting hash after packing based on signature type
     */
    function _packSignatureHash(bytes32 hash, uint8 signatureType, uint256 validationData)
        internal
        pure
        override
        returns (bytes32 packedHash)
    {
        if (signatureType == 0x0) {
            packedHash = hash.toEthSignedMessageHash();
        } else if (signatureType == 0x1) {
            packedHash = keccak256(abi.encodePacked(hash, validationData)).toEthSignedMessageHash();
        } else if (signatureType == 0x2) {
            // passkey sign doesn't need toEthSignedMessageHash
            packedHash = hash;
        } else if (signatureType == 0x3) {
            // passkey sign doesn't need toEthSignedMessageHash
            packedHash = keccak256(abi.encodePacked(hash, validationData));
        } else {
            revert Errors.INVALID_SIGNTYPE();
        }
    }
    /**
     * @dev Packs the given hash for EIP-1271 compatible signatures. EIP-1271 represents signatures
     *      that are verified by smart contracts themselves.
     *      - Type 0x0: Unchanged hash.
     *      - Type 0x1: Hash combined with validation data
     *      - Type 0x2: Unchanged hash
     *      - Type 0x3: Hash combined with validation data
     * @param hash The original hash to be packed
     * @param signatureType The type of signature
     * @param validationData Additional data used for certain signature types
     * @return packedHash The resulting hash after packing
     */

    function _pack1271SignatureHash(bytes32 hash, uint8 signatureType, uint256 validationData)
        internal
        pure
        override
        returns (bytes32 packedHash)
    {
        if (signatureType == 0x0) {
            packedHash = hash;
        } else if (signatureType == 0x1) {
            packedHash = keccak256(abi.encodePacked(hash, validationData));
        } else if (signatureType == 0x2) {
            packedHash = hash;
        } else if (signatureType == 0x3) {
            packedHash = keccak256(abi.encodePacked(hash, validationData));
        } else {
            revert Errors.INVALID_SIGNTYPE();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IValidator.sol";
import "./libraries/ValidatorSigDecoder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../libraries/TypeConversion.sol";
import "../libraries/Errors.sol";
import "../libraries/WebAuthn.sol";
/**
 * @title BaseValidator
 * @dev An abstract contract providing core signature validation functionalities
 */

abstract contract BaseValidator is IValidator {
    using ECDSA for bytes32;
    using TypeConversion for address;
    // Typehashes used for creating EIP-712 compliant messages

    bytes32 private constant SOUL_WALLET_MSG_TYPEHASH = keccak256("SoulWalletMessage(bytes32 message)");

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // Abstract functions that need to be implemented by derived contracts

    function _packSignatureHash(bytes32 hash, uint8 signatureType, uint256 validationData)
        internal
        pure
        virtual
        returns (bytes32);

    function _pack1271SignatureHash(bytes32 hash, uint8 signatureType, uint256 validationData)
        internal
        pure
        virtual
        returns (bytes32);
    /**
     * @dev Recovers the signer from a signature
     * @param signatureType The type of signature
     * @param rawHash The message hash that was signed
     * @param rawSignature The signature itself
     * @return recovered The recovered signer's address or public key as bytes32
     * @return success Indicates whether recovery was successful
     */

    function recover(uint8 signatureType, bytes32 rawHash, bytes calldata rawSignature)
        internal
        view
        returns (bytes32 recovered, bool success)
    {
        if (signatureType == 0x0 || signatureType == 0x1) {
            //ecdas recover
            (address recoveredAddr, ECDSA.RecoverError error,) = ECDSA.tryRecover(rawHash, rawSignature);
            if (error != ECDSA.RecoverError.NoError) {
                success = false;
            } else {
                success = true;
            }
            recovered = recoveredAddr.toBytes32();
        } else if (signatureType == 0x2 || signatureType == 0x3) {
            bytes32 publicKey = WebAuthn.recover(rawHash, rawSignature);
            if (publicKey == 0) {
                recovered = publicKey;
                success = false;
            } else {
                recovered = publicKey;
                success = true;
            }
        } else {
            revert Errors.INVALID_SIGNTYPE();
        }
    }
    /**
     * @dev Recovers the signer from a validator signature
     * @param rawHash The message hash that was signed
     * @param rawSignature The signature itself
     * @return validationData same as defined in EIP4337
     * @return recovered The recovered signer's address or public key as bytes32
     * @return success Indicates whether recovery was successful
     */

    function recoverSignature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        override
        returns (uint256 validationData, bytes32 recovered, bool success)
    {
        uint8 signatureType;
        bytes calldata signature;
        (signatureType, validationData, signature) = ValidatorSigDecoder.decodeValidatorSignature(rawSignature);

        bytes32 hash = _packSignatureHash(rawHash, signatureType, validationData);

        (recovered, success) = recover(signatureType, hash, signature);
    }
    /**
     * @dev Recovers the signer from a EIP-1271 style signature
     * @param rawHash The message hash that was signed
     * @param rawSignature The signature itself
     * @return validationData same as defined in EIP4337
     * @return recovered The recovered signer's address or public key as bytes32
     * @return success Indicates whether recovery was successful
     */

    function recover1271Signature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        override
        returns (uint256 validationData, bytes32 recovered, bool success)
    {
        uint8 signatureType;
        bytes calldata signature;
        (signatureType, validationData, signature) = ValidatorSigDecoder.decodeValidatorSignature(rawSignature);
        bytes32 hash = _pack1271SignatureHash(rawHash, signatureType, validationData);
        (recovered, success) = recover(signatureType, hash, signature);
    }
    /**
     * @dev Encodes a raw hash with EIP-712 compliant formatting
     * @param rawHash The raw hash to be encoded
     * @return The EIP-712 compliant encoded hash
     */

    function encodeRawHash(bytes32 rawHash) public view returns (bytes32) {
        bytes32 encode1271MessageHash = keccak256(abi.encode(SOUL_WALLET_MSG_TYPEHASH, rawHash));
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(msg.sender)));
        return keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, encode1271MessageHash));
    }
    /**
     * @dev Fetches the chain ID. This can be used for EIP-712 signature encoding
     * @return The chain ID
     */

    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Validator Interface
 * @dev This interface defines the functionalities for signature validation and hash encoding
 */
interface IValidator {
    /**
     * @dev Recover the signer of a given raw hash using the provided raw signature
     * @param rawHash The raw hash that was signed
     * @param rawSignature The signature data
     * @return validationData same as defined in EIP4337
     * @return recovered The recovered signer's signing key from the signature
     * @return success A boolean indicating the success of the recovery
     */
    function recoverSignature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        returns (uint256 validationData, bytes32 recovered, bool success);

    /**
     * @dev Recover the signer of a given raw hash using the provided raw signature according to EIP-1271 standards
     * @param rawHash The raw hash that was signed
     * @param rawSignature The signature data
     * @return validationData same as defined in EIP4337
     * @return recovered  The recovered signer's signing key from the signature
     * @return success A boolean indicating the success of the recovery
     */
    function recover1271Signature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        returns (uint256 validationData, bytes32 recovered, bool success);

    /**
     * @dev Encode a raw hash to prevent replay attacks
     * @param rawHash The raw hash to encode
     * @return The encoded hash
     */
    function encodeRawHash(bytes32 rawHash) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library ValidatorSigDecoder {
    /*
    validator signature format
    +----------------------------------------------------------+
    |                                                          |
    |             validator signature                          |
    |                                                          |
    +-------------------------------+--------------------------+
    |         signature type        |       signature data     |
    +-------------------------------+--------------------------+
    |                               |                          |
    |            1 byte             |          ......          |
    |                               |                          |
    +-------------------------------+--------------------------+

    

    A: signature type 0: eoa sig without validation data

    +------------------------------------------------------------------------+
    |                                                                        |
    |                             validator signature                        |
    |                                                                        |
    +--------------------------+----------------------------------------------+
    |       signature type     |                signature data                |
    +--------------------------+----------------------------------------------+
    |                          |                                              |
    |           0x00           |                    65 bytes                  |
    |                          |                                              |
    +--------------------------+----------------------------------------------+
    
    B: signature type 1: eoa sig with validation data

    +-------------------------------------------------------------------------------------+
    |                                                                                     |
    |                                        validator signature                          |
    |                                                                                     |
    +-------------------------------+--------------------------+---------------------------+
    |         signature type        |      validationData      |       signature data      |
    +-------------------------------+--------------------------+---------------------------+
    |                               |                          |                           |
    |            0x01               |     uint256 32 bytes     |           65 bytes        |
    |                               |                          |                           |
    +-------------------------------+--------------------------+---------------------------+

    
    C: signature type 2: passkey sig without validation data
    -----------------------------------------------------------------------------------------------------------------+
    |                                                                                                                |
    |                                     validator singature                                                        |
    |                                                                                                                |
    +-------------------+--------------------------------------------------------------------------------------------+
    |                   |                                                                                            |
    |   signature type  |                            signature data                                                  |
    |                   |                                                                                            |
    +----------------------------------------------------------------------------------------------------------------+
    |                   |                                                                                            |
    |                   |                                                                                            |
    |    0x02           |                        passkey dynamic signature                                           |
    |                   |                                                                                            |
    |                   |                                                                                            |
    +-------------------+--------------------------------------------------------------------------------------------+

     D: signature type 3: passkey sig without validation data
    ------------------------------------------------------------------------------------------------------------------------------------+
    |                                                                                                                                   |
    |                                                        validator singature                                                        |
    |                                                                                                                                   |
    +-----------------+--------------------+--------------------------------------------------------------------------------------------+
    |                 |                    |                                                                                            |
    |   sig type      |  validation data   |                            signature data                                                  |
    |                 |                    |                                                                                            |
    +-----------------------------------------------------------------------------------------------------------------------------------+
    |                 |                    |                                                                                            |
    |    0x03         |     uint256        |                         passkey dynamic signature                                          |
    |                 |     32 bytes       |                                                                                            |
    +-----------------+--------------------+--------------------------------------------------------------------------------------------+

     */

    function decodeValidatorSignature(bytes calldata validatorSignature)
        internal
        pure
        returns (uint8 signatureType, uint256 validationData, bytes calldata signature)
    {
        require(validatorSignature.length >= 1, "validator signature too short");

        signatureType = uint8(bytes1(validatorSignature[0:1]));
        if (signatureType == 0x0) {
            require(validatorSignature.length == 66, "invalid validator signature length");
            validationData = 0;
            signature = validatorSignature[1:66];
        } else if (signatureType == 0x1) {
            require(validatorSignature.length == 98, "invalid validator signature length");
            validationData = uint256(bytes32(validatorSignature[1:33]));
            signature = validatorSignature[33:98];
        } else if (signatureType == 0x2) {
            require(validatorSignature.length >= 129, "invalid validator signature length");
            validationData = 0;
            signature = validatorSignature[1:];
        } else if (signatureType == 0x3) {
            require(validatorSignature.length >= 161, "invalid validator signature length");
            validationData = uint256(bytes32(validatorSignature[1:33]));
            signature = validatorSignature[33:];
        } else {
            revert("invalid validator signature type");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
/**
 * @title TypeConversion
 * @notice A library to facilitate address to bytes32 conversions
 */

library TypeConversion {
    /**
     * @notice Converts an address to bytes32
     * @param addr The address to be converted
     * @return Resulting bytes32 representation of the input address
     */
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
    /**
     * @notice Converts an array of addresses to an array of bytes32
     * @param addresses Array of addresses to be converted
     * @return Array of bytes32 representations of the input addresses
     */

    function addressesToBytes32Array(address[] memory addresses) internal pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            result[i] = toBytes32(addresses[i]);
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library Errors {
    error ADDRESS_ALREADY_EXISTS();
    error ADDRESS_NOT_EXISTS();
    error DATA_ALREADY_EXISTS();
    error DATA_NOT_EXISTS();
    error CALLER_MUST_BE_ENTRYPOINT();
    error CALLER_MUST_BE_SELF_OR_MODULE();
    error CALLER_MUST_BE_MODULE();
    error HASH_ALREADY_APPROVED();
    error HASH_ALREADY_REJECTED();
    error INVALID_ADDRESS();
    error INVALID_GUARD_HOOK_DATA();
    error INVALID_SELECTOR();
    error INVALID_SIGNTYPE();
    error MODULE_ADDRESS_EMPTY();
    error MODULE_NOT_SUPPORT_INTERFACE();
    error MODULE_SELECTOR_UNAUTHORIZED();
    error MODULE_SELECTORS_EMPTY();
    error MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
    error NO_OWNER();
    error PLUGIN_ADDRESS_EMPTY();
    error PLUGIN_HOOK_TYPE_ERROR();
    error PLUGIN_INIT_FAILED();
    error PLUGIN_NOT_SUPPORT_INTERFACE();
    error PLUGIN_POST_HOOK_FAILED();
    error PLUGIN_PRE_HOOK_FAILED();
    error PLUGIN_NOT_REGISTERED();
    error SELECTOR_ALREADY_EXISTS();
    error SELECTOR_NOT_EXISTS();
    error UNSUPPORTED_SIGNTYPE();
    error INVALID_LOGIC_ADDRESS();
    error SAME_LOGIC_ADDRESS();
    error UPGRADE_FAILED();
    error NOT_IMPLEMENTED();
    error INVALID_SIGNATURE();
    error ALERADY_INITIALIZED();
    error INVALID_KEY();
    error NOT_INITIALIZED();
    error INVALID_TIME_RANGE();
    error UNAUTHORIZED();
    error INVALID_DATA();
    error GUARDIAN_SIGNATURE_INVALID();
    error UNTRUSTED_KEYSTORE_LOGIC();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base64Url} from "./Base64Url.sol";
import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";
import {RS256Verify} from "./RS256Verify.sol";

library WebAuthn {
    /**
     * @dev Prefix for client data
     * defined in:
     * 1. https://www.w3.org/TR/webauthn-2/#dictdef-collectedclientdata
     * 2. https://www.w3.org/TR/webauthn-2/#clientdatajson-serialization
     */
    string private constant ClIENTDATA_PREFIX = "{\"type\":\"webauthn.get\",\"challenge\":\"";

    /**
     * @dev Verify WebAuthN signature
     * @param Qx public key point - x
     * @param Qy public key point - y
     * @param r signature - r
     * @param s signature - s
     * @param challenge https://www.w3.org/TR/webauthn-2/#dom-publickeycredentialcreationoptions-challenge
     * @param authenticatorData https://www.w3.org/TR/webauthn-2/#assertioncreationdata-authenticatordataresult
     * @param clientDataSuffix https://www.w3.org/TR/webauthn-2/#clientdatajson-serialization
     */
    function verifyP256Signature(
        uint256 Qx,
        uint256 Qy,
        uint256 r,
        uint256 s,
        bytes32 challenge,
        bytes memory authenticatorData,
        string memory clientDataSuffix
    ) internal view returns (bool) {
        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(challenge)));
        bytes memory clientDataJSON = bytes.concat(bytes(ClIENTDATA_PREFIX), challengeBase64, bytes(clientDataSuffix));
        bytes32 clientHash = sha256(clientDataJSON);
        bytes32 message = sha256(bytes.concat(authenticatorData, clientHash));
        return FCL_Elliptic_ZZ.ecdsa_verify(message, r, s, Qx, Qy);
    }

    /**
     * @dev Verify WebAuthN signature
     * @param Qx public key point - x
     * @param Qy public key point - y
     * @param r signature - r
     * @param s signature - s
     * @param challenge https://www.w3.org/TR/webauthn-2/#dom-publickeycredentialcreationoptions-challenge
     * @param authenticatorData https://www.w3.org/TR/webauthn-2/#assertioncreationdata-authenticatordataresult
     * @param clientDataPrefix https://www.w3.org/TR/webauthn-2/#clientdatajson-serialization
     * @param clientDataSuffix https://www.w3.org/TR/webauthn-2/#clientdatajson-serialization
     */
    function verifyP256Signature(
        uint256 Qx,
        uint256 Qy,
        uint256 r,
        uint256 s,
        bytes32 challenge,
        bytes memory authenticatorData,
        string memory clientDataPrefix,
        string memory clientDataSuffix
    ) internal view returns (bool) {
        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(challenge)));
        bytes memory clientDataJSON = bytes.concat(bytes(clientDataPrefix), challengeBase64, bytes(clientDataSuffix));
        bytes32 clientHash = sha256(clientDataJSON);
        bytes32 message = sha256(bytes.concat(authenticatorData, clientHash));
        return FCL_Elliptic_ZZ.ecdsa_verify(message, r, s, Qx, Qy);
    }

    function decodeP256Signature(bytes calldata packedSignature)
        internal
        pure
        returns (
            uint256 r,
            uint256 s,
            uint8 v,
            bytes calldata authenticatorData,
            bytes calldata clientDataPrefix,
            bytes calldata clientDataSuffix
        )
    {
        /*
            signature layout:
            1. r (32 bytes)
            2. s (32 bytes)
            3. v (1 byte)
            4. authenticatorData length (2 byte max 65535)
            5. clientDataPrefix length (2 byte max 65535)
            6. authenticatorData
            7. clientDataPrefix
            8. clientDataSuffix
            
        */
        uint256 authenticatorDataLength;
        uint256 clientDataPrefixLength;
        assembly ("memory-safe") {
            let calldataOffset := packedSignature.offset
            r := calldataload(calldataOffset)
            s := calldataload(add(calldataOffset, 0x20))
            let lengthData :=
                and(
                    calldataload(add(calldataOffset, 0x25 /* 32+5 */ )),
                    0xffffffffff /* v+authenticatorDataLength+clientDataPrefixLength */
                )
            v := shr(0x20, /* 4*8 */ lengthData)
            authenticatorDataLength := and(shr(0x10, /* 2*8 */ lengthData), 0xffff)
            clientDataPrefixLength := and(lengthData, 0xffff)
        }
        unchecked {
            uint256 _dataOffset1 = 0x45; // 32+32+1+2+2
            uint256 _dataOffset2 = 0x45 + authenticatorDataLength;
            authenticatorData = packedSignature[_dataOffset1:_dataOffset2];

            _dataOffset1 = _dataOffset2 + clientDataPrefixLength;
            clientDataPrefix = packedSignature[_dataOffset2:_dataOffset1];

            clientDataSuffix = packedSignature[_dataOffset1:];
        }
    }

    /**
     * @dev Recover public key from signature
     */
    function recover_p256(bytes32 userOpHash, bytes calldata packedSignature) internal view returns (bytes32) {
        uint256 r;
        uint256 s;
        uint8 v;
        bytes calldata authenticatorData;
        bytes calldata clientDataPrefix;
        bytes calldata clientDataSuffix;
        (r, s, v, authenticatorData, clientDataPrefix, clientDataSuffix) = decodeP256Signature(packedSignature);
        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(userOpHash)));
        bytes memory clientDataJSON;
        if (clientDataPrefix.length == 0) {
            clientDataJSON = bytes.concat(bytes(ClIENTDATA_PREFIX), challengeBase64, clientDataSuffix);
        } else {
            clientDataJSON = bytes.concat(clientDataPrefix, challengeBase64, clientDataSuffix);
        }
        bytes32 clientHash = sha256(clientDataJSON);
        bytes32 message = sha256(bytes.concat(authenticatorData, clientHash));
        return FCL_Elliptic_ZZ.ec_recover_r1(uint256(message), v, r, s);
    }

    function decodeRS256Signature(bytes calldata packedSignature)
        internal
        pure
        returns (
            bytes calldata n,
            bytes calldata signature,
            bytes calldata authenticatorData,
            bytes calldata clientDataPrefix,
            bytes calldata clientDataSuffix
        )
    {
        /*

            Note: currently use a fixed public exponent=0x010001. This is enough for the currently WebAuthn implementation.
            
            signature layout:
            1. n(exponent) length (2 byte max to 8192 bits key)
            2. authenticatorData length (2 byte max 65535)
            3. clientDataPrefix length (2 byte max 65535)
            4. n(exponent) (exponent,dynamic bytes)
            5. signature (signature,signature.length== n.length)
            6. authenticatorData
            7. clientDataPrefix
            8. clientDataSuffix
            
        */

        uint256 exponentLength;
        uint256 authenticatorDataLength;
        uint256 clientDataPrefixLength;
        assembly ("memory-safe") {
            let calldataOffset := packedSignature.offset
            let lengthData :=
                shr(
                    0xd0, // 8*(32-6), exponentLength+authenticatorDataLength+clientDataPrefixLength
                    calldataload(calldataOffset)
                )
            exponentLength := shr(0x20, /* 4*8 */ lengthData)
            authenticatorDataLength := and(shr(0x10, /* 2*8 */ lengthData), 0xffff)
            clientDataPrefixLength := and(lengthData, 0xffff)
        }
        unchecked {
            uint256 _dataOffset1 = 0x06; // 2+2+2
            uint256 _dataOffset2 = 0x06 + exponentLength;
            n = packedSignature[_dataOffset1:_dataOffset2];

            _dataOffset1 = _dataOffset2 + exponentLength;
            signature = packedSignature[_dataOffset2:_dataOffset1];

            _dataOffset2 = _dataOffset1 + authenticatorDataLength;
            authenticatorData = packedSignature[_dataOffset1:_dataOffset2];

            _dataOffset1 = _dataOffset2 + clientDataPrefixLength;
            clientDataPrefix = packedSignature[_dataOffset2:_dataOffset1];

            clientDataSuffix = packedSignature[_dataOffset1:];
        }
    }

    /**
     * @dev Recover public key from signature
     * in current version, only support e=65537
     */
    function recover_rs256(bytes32 userOpHash, bytes calldata packedSignature) internal view returns (bytes32) {
        bytes calldata n;
        bytes calldata signature;
        bytes calldata authenticatorData;
        bytes calldata clientDataPrefix;
        bytes calldata clientDataSuffix;

        (n, signature, authenticatorData, clientDataPrefix, clientDataSuffix) = decodeRS256Signature(packedSignature);

        bytes memory challengeBase64 = bytes(Base64Url.encode(bytes.concat(userOpHash)));
        bytes memory clientDataJSON;
        if (clientDataPrefix.length == 0) {
            clientDataJSON = bytes.concat(bytes(ClIENTDATA_PREFIX), challengeBase64, clientDataSuffix);
        } else {
            clientDataJSON = bytes.concat(clientDataPrefix, challengeBase64, clientDataSuffix);
        }
        bytes32 clientHash = sha256(clientDataJSON);
        bytes32 messageHash = sha256(bytes.concat(authenticatorData, clientHash));

        // Note: currently use a fixed public exponent=0x010001. This is enough for the currently WebAuthn implementation.
        bytes memory e = hex"0000000000000000000000000000000000000000000000000000000000010001";

        bool success = RS256Verify.RSASSA_PSS_VERIFY(n, e, messageHash, signature);
        if (success) {
            return keccak256(abi.encodePacked(e, n));
        } else {
            return bytes32(0);
        }
    }

    /**
     * @dev Recover public key from signature
     * currently support: ES256(P256), RS256(e=65537)
     */
    function recover(bytes32 hash, bytes calldata signature) internal view returns (bytes32) {
        /*
            signature layout:
            1. algorithmType (1 bytes)
            2. signature

            algorithmType:
            0x0: ES256(P256)
            0x1: RS256(e=65537)
        */
        uint8 algorithmType = uint8(signature[0]);
        if (algorithmType == 0x0) {
            return recover_p256(hash, signature[1:]);
        } else if (algorithmType == 0x1) {
            return recover_rs256(hash, signature[1:]);
        } else {
            revert("invalid algorithm type");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// fork from: OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64Url strings (with all trailing '=' characters omitted).
 * see:
 * 1. https://www.w3.org/TR/webauthn-2/#sctn-dependencies
 * 2. https://datatracker.ietf.org/doc/html/rfc4648
 *
 *
 * _Available since v4.5._
 */
library Base64Url {
    /**
     * @dev Base64Url Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    /**
     * @dev Converts a `bytes` to its Bytes64Url `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */

        uint256 dataLen;
        assembly {
            dataLen := mload(data)
        }
        if (dataLen == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        uint256 encodedLen;
        assembly {
            encodedLen := mul(4, div(dataLen, 3)) //4 * (dataLen / 3);
            let padding := mod(dataLen, 3)
            if gt(padding, 0) { encodedLen := add(add(encodedLen, padding), 1) }
        }

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        string memory result = new string(encodedLen);

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, dataLen)
            } lt(dataPtr, endPtr) {} {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }
        }

        return result;
    }
}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_elliptic.sol
///*
///*
///* DESCRIPTION: modified XYZZ system coordinates for EVM elliptic point multiplication
///*  optimization
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// reference: https://github.com/rdubois-crypto/FreshCryptoLib/blob/master/solidity/src/FCL_elliptic.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library FCL_Elliptic_ZZ {
    // Set parameters for curve sec256r1.

    // address of the ModExp precompiled contract (Arbitrary-precision exponentiation under modulo)
    address constant MODEXP_PRECOMPILE = 0x0000000000000000000000000000000000000005;
    //curve prime field modulus
    uint256 constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    //short weierstrass first coefficient
    uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    //short weierstrass second coefficient
    uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    //generating point affine coordinates
    uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    //curve order (number of points)
    uint256 constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    /* -2 mod p constant, used to speed up inversion and doubling (avoid negation)*/
    uint256 constant minus_2 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
    /* -2 mod n constant, used to speed up inversion*/
    uint256 constant minus_2modn = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;

    uint256 constant minus_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    //P+1 div 4
    uint256 constant pp1div4 = 0x3fffffffc0000000400000000000000000000000400000000000000000000000;
    //arbitrary constant to express no quadratic residuosity
    uint256 constant _NOTSQUARE = 0xFFFFFFFF00000002000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant _NOTONCURVE = 0xFFFFFFFF00000003000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * /* inversion mod n via a^(n-2), use of precompiled using little Fermat theorem
     */
    function FCL_nModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2modn)
            mstore(add(pointer, 0xa0), n)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }
    /**
     * /* @dev inversion mod nusing little Fermat theorem via a^(n-2), use of precompiled
     */

    function FCL_pModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2)
            mstore(add(pointer, 0xa0), p)

            // Call the precompiled contract 0x05 = ModExp ̰
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }

    /**
     * /* @dev Convert from XYZZ rep to affine rep
     */
    /*    https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-add-2008-s*/
    function ecZZ_SetAff(uint256 x, uint256 y, uint256 zz, uint256 zzz)
        internal
        view
        returns (uint256 x1, uint256 y1)
    {
        uint256 zzzInv = FCL_pModInv(zzz); //1/zzz
        y1 = mulmod(y, zzzInv, p); //Y/zzz
        uint256 _b = mulmod(zz, zzzInv, p); //1/z
        zzzInv = mulmod(_b, _b, p); //1/zz
        x1 = mulmod(x, zzzInv, p); //X/zz
    }

    /**
     * @dev Sutherland2008 add a ZZ point with a normalized point and greedy formulae
     * warning: assume that P1(x1,y1)!=P2(x2,y2), true in multiplication loop with prime order (cofactor 1)
     */

    function ecZZ_AddN(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            if (y1 == 0) {
                return (x2, y2, 1, 1);
            }

            assembly {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                P0 := mulmod(x2, x2, p) //PP = P^2
                P1 := mulmod(P0, x2, p) //PPP = P*PP
                P2 := mulmod(zz1, P0, p) ////ZZ3 = ZZ1*PP
                P3 := mulmod(zzz1, P1, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, P0, p) //Q = X1*PP
                P0 := addmod(addmod(mulmod(y2, y2, p), sub(p, P1), p), mulmod(minus_2, zz1, p), p) //R^2-PPP-2*Q
                P1 := addmod(mulmod(addmod(zz1, sub(p, P0), p), y2, p), mulmod(y1, P1, p), p) //R*(Q-X3)
            }
            //end assembly
        } //end unchecked
        return (P0, P1, P2, P3);
    }

    /**
     * @dev Check if the curve is the zero curve in affine rep.
     */
    // uint256 x, uint256 y)
    function ecAff_IsZero(uint256, uint256 y) internal pure returns (bool flag) {
        return (y == 0);
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve (reject Neutral that is indeed on the curve).
     */
    function ecAff_isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if (0 == x || x == p || 0 == y || y == p) {
            return false;
        }
        unchecked {
            uint256 LHS = mulmod(y, y, p); // y^2
            uint256 RHS = addmod(mulmod(mulmod(x, x, p), x, p), mulmod(x, a, p), p); // x^3+ax
            RHS = addmod(RHS, b, p); // x^3 + a*x + b

            return LHS == RHS;
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates.
     */

    function ecAff_add(uint256 x0, uint256 y0, uint256 x1, uint256 y1) internal view returns (uint256, uint256) {
        uint256 zz0;
        uint256 zzz0;

        if (ecAff_IsZero(x0, y0)) return (x1, y1);
        if (ecAff_IsZero(x1, y1)) return (x0, y0);

        (x0, y0, zz0, zzz0) = ecZZ_AddN(x0, y0, 1, 1, x1, y1);

        return ecZZ_SetAff(x0, y0, zz0, zzz0);
    }

    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns only x for ECDSA use
     *
     */
    function ecZZ_mulmuladd_S_asm(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X) {
        uint256 zz;
        uint256 zzz;
        uint256 Y;
        uint256 index = 255;
        uint256 H0;
        uint256 H1;

        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return 0;

            (H0, H1) = ecAff_add(gx, gy, Q0, Q1); //will not work if Q=P, obvious forbidden private key

            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                switch zz
                case 1 {
                    X := gx
                    Y := gy
                }
                case 2 {
                    X := Q0
                    Y := Q1
                }
                case 3 {
                    X := H0
                    Y := H1
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        switch T4
                        case 1 {
                            T1 := gx
                            T2 := gy
                        }
                        case 2 {
                            T1 := Q0
                            T2 := Q1
                        }
                        case 3 {
                            T1 := H0
                            T2 := H1
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                let TT1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p)
                                TT1 := addmod(X, sub(p, zz), p)
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                let T := mload(0x40)
                mstore(add(T, 0x60), zz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                //Y:=mulmod(Y,zzz,p)//Y/zzz
                //zz :=mulmod(zz, mload(T),p) //1/z
                //zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, mload(T), p) //X/zz
            } //end assembly
        } //end unchecked

        return X;
    }

    /**
     * @dev ECDSA verification, given , signature, and public key.
     */
    function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 Q0, uint256 Q1) internal view returns (bool) {
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        if (!ecAff_isOnCurve(Q0, Q1)) {
            return false;
        }

        uint256 sInv = FCL_nModInv(s);

        uint256 scalar_u = mulmod(uint256(message), sInv, n);
        uint256 scalar_v = mulmod(r, sInv, n);
        uint256 x1;

        x1 = ecZZ_mulmuladd_S_asm(Q0, Q1, scalar_u, scalar_v);

        assembly {
            x1 := addmod(x1, sub(n, r), n)
        }
        //return true;
        return x1 == 0;
    }

    function ec_Decompress(uint256 x, uint256 parity) internal view returns (uint256 y) {
        uint256 y2 = mulmod(x, mulmod(x, x, p), p); //x3
        y2 = addmod(b, addmod(y2, mulmod(x, a, p), p), p); //x3+ax+b

        y = SqrtMod(y2);
        if (y == _NOTSQUARE) {
            return _NOTONCURVE;
        }
        if ((y & 1) != (parity & 1)) {
            y = p - y;
        }
    }

    /// @notice Calculate one modular square root of a given integer. Assume that p=3 mod 4.
    /// @dev Uses the ModExp precompiled contract at address 0x05 for fast computation using little Fermat theorem
    /// @param self The integer of which to find the modular inverse
    /// @return result The modular inverse of the input integer. If the modular inverse doesn't exist, it revert the tx

    function SqrtMod(uint256 self) internal view returns (uint256 result) {
        assembly ("memory-safe") {
            // load the free memory pointer value
            let pointer := mload(0x40)

            // Define length of base (Bsize)
            mstore(pointer, 0x20)
            // Define the exponent size (Esize)
            mstore(add(pointer, 0x20), 0x20)
            // Define the modulus size (Msize)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base (B)
            mstore(add(pointer, 0x60), self)
            // Define the exponent (E)
            mstore(add(pointer, 0x80), pp1div4)
            // We save the point of the last argument, it will be override by the result
            // of the precompile call in order to avoid paying for the memory expansion properly
            let _result := add(pointer, 0xa0)
            // Define the modulus (M)
            mstore(_result, p)

            // Call the precompiled ModExp (0x05) https://www.evm.codes/precompiled#0x05
            if iszero(
                staticcall(
                    not(0), // amount of gas to send
                    MODEXP_PRECOMPILE, // target
                    pointer, // argsOffset
                    0xc0, // argsSize (6 * 32 bytes)
                    _result, // retOffset (we override M to avoid paying for the memory expansion)
                    0x20 // retSize (32 bytes)
                )
            ) { revert(0, 0) }

            result := mload(_result)
            //  result :=addmod(result,0,p)
        }
        if (mulmod(result, result, p) != self) {
            result = _NOTSQUARE;
        }

        return result;
    }
    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns affine representation of point (normalized)
     *
     */

    function ecZZ_mulmuladd(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X, uint256 Y) {
        uint256 zz;
        uint256 zzz;
        uint256 index = 255;
        uint256[2] memory H;

        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return (0, 0);

            (H[0], H[1]) = ecAff_add(gx, gy, Q0, Q1); //will not work if Q=P, obvious forbidden private key

            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                switch zz
                case 1 {
                    X := gx
                    Y := gy
                }
                case 2 {
                    X := Q0
                    Y := Q1
                }
                case 3 {
                    Y := mload(add(H, 32))
                    X := mload(H)
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        switch T4
                        case 1 {
                            T1 := gx
                            T2 := gy
                        }
                        case 2 {
                            T1 := Q0
                            T2 := Q1
                        }
                        case 3 {
                            T1 := mload(H)
                            T2 := mload(add(H, 32))
                        }

                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                let T := mload(0x40)
                mstore(add(T, 0x60), zzz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                Y := mulmod(Y, mload(T), p) //Y/zzz
                zz := mulmod(zz, mload(T), p) //1/z
                zz := mulmod(zz, zz, p) //1/zz
                X := mulmod(X, zz, p) //X/zz
            } //end assembly
        } //end unchecked

        return (X, Y);
    }

    function ec_recover_r1(uint256 h, uint256 v, uint256 r, uint256 s) internal view returns (bytes32) {
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return 0;
        }
        uint256 y = ec_Decompress(r, v - 27);
        uint256 rinv = FCL_nModInv(r);
        uint256 u1 = mulmod(n - addmod(0, h, n), rinv, n); //-hr^-1
        uint256 u2 = mulmod(s, rinv, n); //sr^-1

        uint256 Qx;
        uint256 Qy;
        (Qx, Qy) = ecZZ_mulmuladd(r, y, u1, u2);

        return keccak256(abi.encodePacked(Qx, Qy));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title RS256Verify
 * @author https://github.com/jayden-sudo
 *
 * The code strictly follows the RSASSA-PKCS1-v1_5 signature verification operation steps outlined in RFC 8017.
 * It takes a signature, message, and public key as inputs and verifies if the signature is valid for the
 * given message using the provided public key.
 * reference: https://datatracker.ietf.org/doc/html/rfc8017#section-8.1.2
 *
 * This code has passed the complete tests of the `Algorithm Validation Testing Requirements`:https://csrc.nist.gov/Projects/Cryptographic-Algorithm-Validation-Program/Digital-Signatures#rsa2vs
 * `FIPS 186-4` https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Algorithm-Validation-Program/documents/dss/186-3rsatestvectors.zip
 *
 * LICENSE: MIT
 * Copyright (c) 2023 Jayden
 */
library RS256Verify {
    /**
     *
     * @param n signer's RSA public key - n
     * @param e signer's RSA public key - e
     * @param H H = sha256(M) - message digest
     * @param S signature to be verified, an octet string of length k, where k is the length in octets of the RSA modulus n
     */
    function RSASSA_PSS_VERIFY(bytes memory n, bytes memory e, bytes32 H, bytes memory S)
        internal
        view
        returns (bool)
    {
        uint256 k = n.length;
        // 1. Length checking: If the length of S is not k octets, output "invalid signature" and stop.
        if (k != S.length) {
            return false;
        }

        // 2. RSA verification:
        /* 
                a.  Convert the signature S to an integer signature representative s (see Section 4.2):
                    s = OS2IP (S).
        */
        /*
            c.  Convert the message representative m to an encoded message
                  EM of length k octets (see Section 4.1):
                     EM = I2OSP (m, k).
        */

        // bytes memory EM = m;

        /*  
            1.  Encode the algorithm ID for the hash function and the hash
                value into an ASN.1 value of type DigestInfo (see
                Appendix A.2.4) with the DER, where the type DigestInfo has
                the syntax
     
                    DigestInfo ::= SEQUENCE {
                        digestAlgorithm AlgorithmIdentifier,
                        digest OCTET STRING
                    }
     
                The first field identifies the hash function and the second
                contains the hash value.  Let T be the DER encoding of the
                DigestInfo value (see the notes below), and let tLen be the
                length in octets of T.
     
            2.  If emLen < tLen + 11, output "intended encoded message length
                too short" and stop.
     
            3.  Generate an octet string PS consisting of emLen - tLen - 3
                octets with hexadecimal value 0xff.  The length of PS will be
                at least 8 octets.
     
            4.  Concatenate PS, the DER encoding T, and other padding to form
                the encoded message EM as
     
                    EM = 0x00 || 0x01 || PS || 0x00 || T.
     
            5.  Output EM.
     
            SHA-256: (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
        */

        /*  
            1.  Encode the algorithm ID for the hash function and the hash
                value into an ASN.1 value of type DigestInfo (see
                Appendix A.2.4) with the DER, where the type DigestInfo has
                the syntax
     
                    DigestInfo ::= SEQUENCE {
                        digestAlgorithm AlgorithmIdentifier,
                        digest OCTET STRING
                    }
     
                The first field identifies the hash function and the second
                contains the hash value.  Let T be the DER encoding of the
                DigestInfo value (see the notes below), and let tLen be the
                length in octets of T.
     
            2.  If emLen < tLen + 11, output "intended encoded message length
                too short" and stop.
     
            3.  Generate an octet string PS consisting of emLen - tLen - 3
                octets with hexadecimal value 0xff.  The length of PS will be
                at least 8 octets.
     
            4.  Concatenate PS, the DER encoding T, and other padding to form
                the encoded message EM as
     
                    EM = 0x00 || 0x01 || PS || 0x00 || T.
     
            5.  Output EM.
     
            SHA-256: (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
        */

        uint256 PS_ByteLen = k - 54; //k - 19 - 32 - 3, 32: SHA-256 hash length
        uint256 _cursor;
        assembly ("memory-safe") {
            // inline RSAVP1 begin
            /* 
               b.  Apply the RSAVP1 verification primitive (Section 5.2.2) to
                   the RSA public key (n, e) and the signature representative
                   s to produce an integer message representative m:
                   m = RSAVP1 ((n, e), s).
                   If RSAVP1 outputs "signature representative out of range",output "invalid signature" and stop.
            */

            // bytes memory EM = RSAVP1(n, e, S);

            let EM
            {
                /*
                    Steps:
            
                    1.  If the signature representative s is not between 0 and n - 1,
                        output "signature representative out of range" and stop.
            
                    2.  Let m = s^e mod n.
            
                    3.  Output m.
                */

                // To simplify the calculations, k must be an integer multiple of 32.
                if mod(k, 0x20) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                let _k := div(k, 0x20)
                for { let i := 0 } lt(i, _k) { i := add(i, 0x01) } {
                    // 1. If the signature representative S is not between 0 and n - 1, output "signature representative out of range" and stop.
                    let _n := mload(add(add(n, 0x20), mul(i, 0x20)))
                    let _s := mload(add(add(S, 0x20), mul(i, 0x20)))
                    if lt(_s, _n) {
                        // break
                        i := k
                    }
                    if gt(_s, _n) {
                        // signature representative out of range
                        mstore(0x00, false)
                        return(0x00, 0x20)
                    }
                    if eq(_s, _n) {
                        if eq(i, sub(_k, 0x01)) {
                            // signature representative out of range
                            mstore(0x00, false)
                            return(0x00, 0x20)
                        }
                    }
                }
                // 2.  Let m = s^e mod n.
                let e_length := mload(e)
                EM := mload(0x40)
                mstore(EM, k)
                mstore(add(EM, 0x20), e_length)
                mstore(add(EM, 0x40), k)
                let _cursor_inline := add(EM, 0x60)
                // copy s begin
                for { let i := 0 } lt(i, k) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(S, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy s end

                // copy e begin
                // To simplify the calculations, e must be an integer multiple of 32.
                if mod(e_length, 0x20) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                for { let i := 0 } lt(i, e_length) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(e, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy e end

                // copy n begin
                for { let i := 0 } lt(i, k) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(n, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy n end

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, EM, _cursor_inline, add(EM, 0x20), k)) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                mstore(EM, k)
                mstore(0x40, add(add(EM, 0x20), k))
            }

            // inline RSAVP1 end

            if sub(mload(add(EM, 0x20)), 0x0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                //                             |_______________________ 0x1E bytes _______________________|

                mstore(0x00, false)
                return(0x00, 0x20)
            }
            let paddingLen := sub(PS_ByteLen, 0x1E)
            let _times := div(paddingLen, 0x20)
            _cursor := add(EM, 0x40)
            for { let i := 0 } lt(i, _times) { i := add(i, 1) } {
                if sub(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, mload(_cursor)) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                _cursor := add(_cursor, 0x20)
            }
            let _remainder := mod(paddingLen, 0x20)
            if _remainder {
                let _shift := mul(0x08, sub(0x20, _remainder))
                if sub(
                    0x0000000000000000000000000000000000000000000000000000000000000000,
                    shl(_shift, not(shr(_shift, mload(_cursor))))
                ) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
            }

            // SHA-256 T : (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
            // EM = 0x00 || 0x01 || PS || 0x00 || T.
            _cursor := add(EM, add(0x22, PS_ByteLen /* 0x20+1+1+PS_ByteLen */ ))
            // 0x003031300d060960864801650304020105000420
            // |______________ 0x14 bytes _______________|
            if sub(0x003031300d060960864801650304020105000420, shr(0x60, /* 8*12 */ mload(_cursor))) {
                mstore(0x00, false)
                return(0x00, 0x20)
            }
        }
        assembly ("memory-safe") {
            if sub(H, mload(add(_cursor, 0x14))) {
                mstore(0x00, false)
                return(0x00, 0x20)
            }
        }
        return true;
    }

    /**
     *
     * @param n signer's RSA public key - n
     * @param e signer's RSA public key - e
     * @param M message whose signature is to be verified, an octet string
     * @param S signature to be verified, an octet string of length k, where k is the length in octets of the RSA modulus n
     */
    function RSASSA_PSS_VERIFY(bytes memory n, bytes memory e, bytes memory M, bytes memory S)
        internal
        view
        returns (bool)
    {
        uint256 k = n.length;
        // 1. Length checking: If the length of S is not k octets, output "invalid signature" and stop.
        if (k != S.length) {
            return false;
        }

        // 2. RSA verification:
        /* 
                a.  Convert the signature S to an integer signature representative s (see Section 4.2):
                    s = OS2IP (S).
        */
        /*
            c.  Convert the message representative m to an encoded message
                  EM of length k octets (see Section 4.1):
                     EM = I2OSP (m, k).
        */

        // bytes memory EM = m;

        /*  
            1.  Encode the algorithm ID for the hash function and the hash
                value into an ASN.1 value of type DigestInfo (see
                Appendix A.2.4) with the DER, where the type DigestInfo has
                the syntax
     
                    DigestInfo ::= SEQUENCE {
                        digestAlgorithm AlgorithmIdentifier,
                        digest OCTET STRING
                    }
     
                The first field identifies the hash function and the second
                contains the hash value.  Let T be the DER encoding of the
                DigestInfo value (see the notes below), and let tLen be the
                length in octets of T.
     
            2.  If emLen < tLen + 11, output "intended encoded message length
                too short" and stop.
     
            3.  Generate an octet string PS consisting of emLen - tLen - 3
                octets with hexadecimal value 0xff.  The length of PS will be
                at least 8 octets.
     
            4.  Concatenate PS, the DER encoding T, and other padding to form
                the encoded message EM as
     
                    EM = 0x00 || 0x01 || PS || 0x00 || T.
     
            5.  Output EM.
     
            SHA-256: (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
        */

        /*  
            1.  Encode the algorithm ID for the hash function and the hash
                value into an ASN.1 value of type DigestInfo (see
                Appendix A.2.4) with the DER, where the type DigestInfo has
                the syntax
     
                    DigestInfo ::= SEQUENCE {
                        digestAlgorithm AlgorithmIdentifier,
                        digest OCTET STRING
                    }
     
                The first field identifies the hash function and the second
                contains the hash value.  Let T be the DER encoding of the
                DigestInfo value (see the notes below), and let tLen be the
                length in octets of T.
     
            2.  If emLen < tLen + 11, output "intended encoded message length
                too short" and stop.
     
            3.  Generate an octet string PS consisting of emLen - tLen - 3
                octets with hexadecimal value 0xff.  The length of PS will be
                at least 8 octets.
     
            4.  Concatenate PS, the DER encoding T, and other padding to form
                the encoded message EM as
     
                    EM = 0x00 || 0x01 || PS || 0x00 || T.
     
            5.  Output EM.
     
            SHA-256: (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
        */

        uint256 PS_ByteLen = k - 54; //k - 19 - 32 - 3, 32: SHA-256 hash length
        uint256 _cursor;
        assembly ("memory-safe") {
            // inline RSAVP1 begin
            /* 
               b.  Apply the RSAVP1 verification primitive (Section 5.2.2) to
                   the RSA public key (n, e) and the signature representative
                   s to produce an integer message representative m:
                   m = RSAVP1 ((n, e), s).
                   If RSAVP1 outputs "signature representative out of range",output "invalid signature" and stop.
            */

            // bytes memory EM = RSAVP1(n, e, S);

            let EM
            {
                /*
                    Steps:
            
                    1.  If the signature representative s is not between 0 and n - 1,
                        output "signature representative out of range" and stop.
            
                    2.  Let m = s^e mod n.
            
                    3.  Output m.
                */

                // To simplify the calculations, k must be an integer multiple of 32.
                if mod(k, 0x20) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                let _k := div(k, 0x20)
                for { let i := 0 } lt(i, _k) { i := add(i, 0x01) } {
                    // 1. If the signature representative S is not between 0 and n - 1, output "signature representative out of range" and stop.
                    let _n := mload(add(add(n, 0x20), mul(i, 0x20)))
                    let _s := mload(add(add(S, 0x20), mul(i, 0x20)))
                    if lt(_s, _n) {
                        // break
                        i := k
                    }
                    if gt(_s, _n) {
                        // signature representative out of range
                        mstore(0x00, false)
                        return(0x00, 0x20)
                    }
                    if eq(_s, _n) {
                        if eq(i, sub(_k, 0x01)) {
                            // signature representative out of range
                            mstore(0x00, false)
                            return(0x00, 0x20)
                        }
                    }
                }
                // 2.  Let m = s^e mod n.
                let e_length := mload(e)
                EM := mload(0x40)
                mstore(EM, k)
                mstore(add(EM, 0x20), e_length)
                mstore(add(EM, 0x40), k)
                let _cursor_inline := add(EM, 0x60)
                // copy s begin
                for { let i := 0 } lt(i, k) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(S, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy s end

                // copy e begin
                // To simplify the calculations, e must be an integer multiple of 32.
                if mod(e_length, 0x20) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                for { let i := 0 } lt(i, e_length) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(e, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy e end

                // copy n begin
                for { let i := 0 } lt(i, k) { i := add(i, 0x20) } {
                    mstore(_cursor_inline, mload(add(add(n, 0x20), i)))
                    _cursor_inline := add(_cursor_inline, 0x20)
                }
                // copy n end

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, EM, _cursor_inline, add(EM, 0x20), k)) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                mstore(EM, k)
                mstore(0x40, add(add(EM, 0x20), k))
            }

            // inline RSAVP1 end

            if sub(mload(add(EM, 0x20)), 0x0001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                //                             |_______________________ 0x1E bytes _______________________|

                mstore(0x00, false)
                return(0x00, 0x20)
            }
            let paddingLen := sub(PS_ByteLen, 0x1E)
            let _times := div(paddingLen, 0x20)
            _cursor := add(EM, 0x40)
            for { let i := 0 } lt(i, _times) { i := add(i, 1) } {
                if sub(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, mload(_cursor)) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
                _cursor := add(_cursor, 0x20)
            }
            let _remainder := mod(paddingLen, 0x20)
            if _remainder {
                let _shift := mul(0x08, sub(0x20, _remainder))
                if sub(
                    0x0000000000000000000000000000000000000000000000000000000000000000,
                    shl(_shift, not(shr(_shift, mload(_cursor))))
                ) {
                    mstore(0x00, false)
                    return(0x00, 0x20)
                }
            }

            // SHA-256 T : (0x)30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H.
            // EM = 0x00 || 0x01 || PS || 0x00 || T.
            _cursor := add(EM, add(0x22, PS_ByteLen /* 0x20+1+1+PS_ByteLen */ ))
            // 0x003031300d060960864801650304020105000420
            // |______________ 0x14 bytes _______________|
            if sub(0x003031300d060960864801650304020105000420, shr(0x60, /* 8*12 */ mload(_cursor))) {
                mstore(0x00, false)
                return(0x00, 0x20)
            }
        }
        bytes32 H = sha256(M);
        assembly ("memory-safe") {
            if sub(H, mload(add(_cursor, 0x14))) {
                mstore(0x00, false)
                return(0x00, 0x20)
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}