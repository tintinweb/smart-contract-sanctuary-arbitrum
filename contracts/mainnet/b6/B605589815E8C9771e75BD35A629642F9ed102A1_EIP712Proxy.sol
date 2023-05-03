// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint64 constant NO_EXPIRATION_TIME = 0;

error AccessDenied();
error InvalidEAS();
error InvalidLength();
error InvalidSignature();
error NotFound();

/**
 * @dev A struct representing EIP712 signature data.
 */
struct EIP712Signature {
    uint8 v; // The recovery ID.
    bytes32 r; // The x-coordinate of the nonce R.
    bytes32 s; // The signature data.
}

/**
 * @dev A struct representing a single attestation.
 */
struct Attestation {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schema; // The unique identifier of the schema.
    uint64 time; // The time when the attestation was created (Unix timestamp).
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bytes32 refUID; // The UID of the related attestation.
    address recipient; // The recipient of the attestation.
    address attester; // The attester/sender of the attestation.
    bool revocable; // Whether the attestation is revocable.
    bytes data; // Custom attestation data.
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaRegistry } from "./ISchemaRegistry.sol";
import { Attestation, EIP712Signature } from "./Common.sol";

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address recipient; // The recipient of the attestation.
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bytes32 refUID; // The UID of the related attestation.
    bytes data; // Custom attestation data.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the attestation request.
 */
struct AttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the full arguments of the multi attestation request.
 */
struct MultiAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequestData {
    bytes32 uid; // The UID of the attestation to revoke.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the revocation request.
 */
struct RevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    EIP712Signature signature; // The EIP712 signature data.
    address revoker; // The revoking account.
}

/**
 * @dev A struct representing the full arguments of the multi revocation request.
 */
struct MultiRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
}

/**
 * @title EAS - Ethereum Attestation Service interface.
 */
interface IEAS {
    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uid The UID the revoked attestation.
     * @param schema The UID of the schema.
     */
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema);

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     * @param uid The UID the revoked attestation.
     */
    event Revoked(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema);

    /**
     * @dev Emitted when a data has been timestamped.
     *
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @dev Emitted when a data has been revoked.
     *
     * @param revoker The address of the revoker.
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @dev Returns the address of the global schema registry.
     *
     * @return The address of the global schema registry.
     */
    function getSchemaRegistry() external view returns (ISchemaRegistry);

    /**
     * @dev Attests to a specific schema.
     *
     * @param request The arguments of the attestation request.
     *
     * Example:
     *
     * attest({
     *     schema: "0facc36681cbe2456019c1b0d1e7bedd6d1d40f6f324bf3dd3a4cef2999200a0",
     *     data: {
     *         recipient: "0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf",
     *         expirationTime: 0,
     *         revocable: true,
     *         refUID: "0x0000000000000000000000000000000000000000000000000000000000000000",
     *         data: "0xF00D",
     *         value: 0
     *     }
     * })
     *
     * @return The UID of the new attestation.
     */
    function attest(AttestationRequest calldata request) external payable returns (bytes32);

    /**
     * @dev Attests to a specific schema via the provided EIP712 signature.
     *
     * @param delegatedRequest The arguments of the delegated attestation request.
     *
     * Example:
     *
     * attestByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     signature: {
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     attester: '0xc5E8740aD971409492b1A63Db8d83025e0Fc427e'
     * })
     *
     * @return The UID of the new attestation.
     */
    function attestByDelegation(
        DelegatedAttestationRequest calldata delegatedRequest
    ) external payable returns (bytes32);

    /**
     * @dev Attests to multiple schemas.
     *
     * @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
     * schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiAttest([{
     *     schema: '0x33e9094830a5cba5554d1954310e4fbed2ef5f859ec1404619adea4207f391fd',
     *     data: [{
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 1000
     *     },
     *     {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 0,
     *         revocable: false,
     *         refUID: '0x480df4a039efc31b11bfdf491b383ca138b6bde160988222a2a3509c02cee174',
     *         data: '0x00',
     *         value: 0
     *     }],
     * },
     * {
     *     schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
     *     data: [{
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 0,
     *         revocable: true,
     *         refUID: '0x75bf2ed8dca25a8190c50c52db136664de25b2449535839008ccfdab469b214f',
     *         data: '0x12345678',
     *         value: 0
     *     },
     * }])
     *
     * @return The UIDs of the new attestations.
     */
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable returns (bytes32[] memory);

    /**
     * @dev Attests to multiple schemas using via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiAttestByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     {
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 0,
     *         revocable: false,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x00',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     attester: '0x1D86495b2A7B524D747d2839b3C645Bed32e8CF4'
     * }])
     *
     * @return The UIDs of the new attestations.
     */
    function multiAttestByDelegation(
        MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests
    ) external payable returns (bytes32[] memory);

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * Example:
     *
     * revoke({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0x101032e487642ee04ee17049f99a70590c735b8614079fc9275f9dd57c00966d',
     *         value: 0
     *     }
     * })
     *
     * @param request The arguments of the revocation request.
     */
    function revoke(RevocationRequest calldata request) external payable;

    /**
     * @dev Revokes an existing attestation to a specific schema via the provided EIP712 signature.
     *
     * Example:
     *
     * revokeByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0xcbbc12102578c642a0f7b34fe7111e41afa25683b6cd7b5a14caf90fa14d24ba',
     *         value: 0
     *     },
     *     signature: {
     *         v: 27,
     *         r: '0xb593...7142',
     *         s: '0x0f5b...2cce'
     *     },
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * })
     *
     * @param delegatedRequest The arguments of the delegated revocation request.
     */
    function revokeByDelegation(DelegatedRevocationRequest calldata delegatedRequest) external payable;

    /**
     * @dev Revokes existing attestations to multiple schemas.
     *
     * @param multiRequests The arguments of the multi revocation requests. The requests should be grouped by distinct
     * schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevoke([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     * },
     * {
     *     schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
     *     data: [{
     *         uid: '0x053d42abce1fd7c8fcddfae21845ad34dae287b2c326220b03ba241bc5a8f019',
     *         value: 0
     *     },
     * }])
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable;

    /**
     * @dev Revokes existing attestations to multiple schemas via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi revocation attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevokeByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * }])
     *
     */
    function multiRevokeByDelegation(
        MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests
    ) external payable;

    /**
     * @dev Timestamps the specified bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was timestamped with.
     */
    function timestamp(bytes32 data) external returns (uint64);

    /**
     * @dev Timestamps the specified multiple bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was timestamped with.
     */
    function multiTimestamp(bytes32[] calldata data) external returns (uint64);

    /**
     * @dev Revokes the specified bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was revoked with.
     */
    function revokeOffchain(bytes32 data) external returns (uint64);

    /**
     * @dev Revokes the specified multiple bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was revoked with.
     */
    function multiRevokeOffchain(bytes32[] calldata data) external returns (uint64);

    /**
     * @dev Returns an existing attestation by UID.
     *
     * @param uid The UID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(bytes32 uid) external view returns (Attestation memory);

    /**
     * @dev Checks whether an attestation exists.
     *
     * @param uid The UID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(bytes32 uid) external view returns (bool);

    /**
     * @dev Returns the timestamp that the specified data was timestamped with.
     *
     * @param data The data to query.
     *
     * @return The timestamp the data was timestamped with.
     */
    function getTimestamp(bytes32 data) external view returns (uint64);

    /**
     * @dev Returns the timestamp that the specified data was timestamped with.
     *
     * @param data The data to query.
     *
     * @return The timestamp the data was timestamped with.
     */
    function getRevokeOffchain(address revoker, bytes32 data) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

/**
 * @title A struct representing a record for a submitted schema.
 */
struct SchemaRecord {
    bytes32 uid; // The unique identifier of the schema.
    ISchemaResolver resolver; // Optional schema resolver.
    bool revocable; // Whether the schema allows revocations explicitly.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

/**
 * @title The global schema registry interface.
 */
interface ISchemaRegistry {
    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */
    event Registered(bytes32 indexed uid, address registerer);

    /**
     * @dev Submits and reserves a new schema
     *
     * @param schema The schema data schema.
     * @param resolver An optional schema resolver.
     * @param revocable Whether the schema allows revocations explicitly.
     *
     * @return The UID of the new schema.
     */
    function register(string calldata schema, ISchemaResolver resolver, bool revocable) external returns (bytes32);

    /**
     * @dev Returns an existing schema by UID
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema data members.
     */
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Attestation } from "../Common.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaResolver {
    /**
     * @dev Returns whether the resolver supports ETH transfers.
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Processes an attestation and verifies whether it's valid.
     *
     * @param attestation The new attestation.
     *
     * @return Whether the attestation is valid.
     */
    function attest(Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes multiple attestations and verifies whether they are valid.
     *
     * @param attestations The new attestations.
     * @param values Explicit ETH amounts which were sent with each attestation.
     *
     * @return Whether all the attestations are valid.
     */
    function multiAttest(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function revoke(Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes revocation of multiple attestation and verifies they can be revoked.
     *
     * @param attestations The existing attestations to be revoked.
     * @param values Explicit ETH amounts which were sent with each revocation.
     *
     * @return Whether the attestations can be revoked.
     */
    function multiRevoke(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
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
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// prettier-ignore
import {
    AccessDenied,
    EIP712Signature,
    InvalidEAS,
    InvalidLength,
    InvalidSignature,
    NotFound,
    NO_EXPIRATION_TIME
} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";

// prettier-ignore
import {
    AttestationRequest,
    AttestationRequestData,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest,
    IEAS,
    MultiAttestationRequest,
    MultiDelegatedAttestationRequest,
    MultiDelegatedRevocationRequest,
    MultiRevocationRequest,
    RevocationRequest,
    RevocationRequestData
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedProxyAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
    uint64 deadline; // The deadline of the signature/request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedProxyAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
    uint64 deadline; // The deadline of the signature/request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedProxyRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    EIP712Signature signature; // The EIP712 signature data.
    address revoker; // The revoking account.
    uint64 deadline; // The deadline of the signature/request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedProxyRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
    uint64 deadline; // The deadline of the signature/request.
}

/**
 * @title This utility contract an be used to aggregate delegated attestations without requiring a specific order via
 * nonces. The contract doesn't request nonces and implements replay protection by storing ***immalleable*** signatures.
 */
contract EIP712Proxy is EIP712 {
    error DeadlineExpired();
    error UsedSignature();
    error InvalidAttester();

    // The version of the contract.
    string public constant VERSION = "0.1";

    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(bytes32 schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint64 deadline)").
    bytes32 private constant ATTEST_PROXY_TYPEHASH =
        0x4120d3b28306666b714826ad7cb70744d9658ad3e6cd873411bedadcf55afda7;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(bytes32 schema,bytes32 uid,uint64 deadline)").
    bytes32 private constant REVOKE_PROXY_TYPEHASH =
        0x96bdbea8fa280f8a0d0835587e1fbb1470e81d05c44514158443340cea40a05d;

    // The global EAS contract.
    IEAS private immutable _eas;

    // The user readable name of the signing domain.
    string private _name;

    address internal _attester;

    // The global mapping between proxy attestations and their attesters, so that we can verify that only the original
    // attester is able to revert attestations by proxy.
    mapping(bytes32 uid => address attester) private _attesters;

    // Replay protection signatures.
    mapping(bytes signature => bool used) private _signatures;

    /**
     * @dev Creates a new EIP712Verifier instance.
     *
     * @param eas The address of the global EAS contract.
     * @param name The user readable name of the signing domain.
     */
    constructor(IEAS eas, string memory name) EIP712(name, VERSION) {
        if (address(eas) == address(0)) {
            revert InvalidEAS();
        }

        _eas = eas;
        _name = name;
        _attester = msg.sender;
    }

    /**
     * @dev Returns the EAS.
     */
    function getEAS() external view returns (IEAS) {
        return _eas;
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signatures for attest, and revoke.
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * Returns the EIP712 type hash for the attest function.
     */
    function getAttestTypeHash() external pure returns (bytes32) {
        return ATTEST_PROXY_TYPEHASH;
    }

    /**
     * Returns the EIP712 type hash for the revoke function.
     */
    function getRevokeTypeHash() external pure returns (bytes32) {
        return REVOKE_PROXY_TYPEHASH;
    }

    /**
     * Returns the EIP712 name.
     */
    function getName() external view returns (string memory) {
        return _name;
    }

    /**
     * Returns the attester for a given uid.
     */
    function getAttester(bytes32 uid) external view returns (address) {
        return _attesters[uid];
    }

    /**
     * @dev Attests to a specific schema via the provided EIP712 signature.
     *
     * @param delegatedRequest The arguments of the delegated attestation request.
     *
     * Example:
     *
     * attestByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     signature: {
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     attester: '0xc5E8740aD971409492b1A63Db8d83025e0Fc427e'
     * })
     *
     * @return The UID of the new attestation.
     */
    function attestByDelegation(
        DelegatedProxyAttestationRequest calldata delegatedRequest
    ) public payable virtual returns (bytes32) {
        _verifyAttest(delegatedRequest);

        bytes32 uid = _eas.attest{value: msg.value}(
            AttestationRequest({
                schema: delegatedRequest.schema,
                data: delegatedRequest.data
            })
        );

        _attesters[uid] = delegatedRequest.attester;

        return uid;
    }

    /**
     * @dev Attests to multiple schemas using via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiAttestByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     {
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 0,
     *         revocable: false,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x00',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     attester: '0x1D86495b2A7B524D747d2839b3C645Bed32e8CF4'
     * }])
     *
     * @return The UIDs of the new attestations.
     */
    function multiAttestByDelegation(
        MultiDelegatedProxyAttestationRequest[] calldata multiDelegatedRequests
    ) public payable virtual returns (bytes32[] memory) {
        MultiAttestationRequest[]
            memory multiRequests = new MultiAttestationRequest[](
                multiDelegatedRequests.length
            );

        for (uint256 i = 0; i < multiDelegatedRequests.length; ) {
            MultiDelegatedProxyAttestationRequest
                calldata multiDelegatedRequest = multiDelegatedRequests[i];
            AttestationRequestData[] calldata data = multiDelegatedRequest.data;

            // Ensure that no inputs are missing.
            if (
                data.length == 0 ||
                data.length != multiDelegatedRequest.signatures.length
            ) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j = 0; j < data.length; ) {
                _verifyAttest(
                    DelegatedProxyAttestationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester,
                        deadline: multiDelegatedRequest.deadline
                    })
                );

                unchecked {
                    ++j;
                }
            }

            multiRequests[i] = MultiAttestationRequest({
                schema: multiDelegatedRequest.schema,
                data: data
            });

            unchecked {
                ++i;
            }
        }

        bytes32[] memory uids = _eas.multiAttest{value: msg.value}(
            multiRequests
        );

        // Store all attesters, according to the order of the attestation requests.
        uint256 uidCounter = 0;

        for (uint256 i = 0; i < multiDelegatedRequests.length; ) {
            MultiDelegatedProxyAttestationRequest
                calldata multiDelegatedRequest = multiDelegatedRequests[i];
            AttestationRequestData[] calldata data = multiDelegatedRequest.data;

            for (uint256 j = 0; j < data.length; ) {
                _attesters[uids[uidCounter]] = multiDelegatedRequest.attester;

                unchecked {
                    ++uidCounter;

                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        return uids;
    }

    /**
     * @dev Revokes an existing attestation to a specific schema via the provided EIP712 signature.
     *
     * Example:
     *
     * revokeByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0xcbbc12102578c642a0f7b34fe7111e41afa25683b6cd7b5a14caf90fa14d24ba',
     *         value: 0
     *     },
     *     signature: {
     *         v: 27,
     *         r: '0xb593...7142',
     *         s: '0x0f5b...2cce'
     *     },
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * })
     *
     * @param delegatedRequest The arguments of the delegated revocation request.
     */
    function revokeByDelegation(
        DelegatedProxyRevocationRequest calldata delegatedRequest
    ) public payable virtual {
        _verifyRevoke(delegatedRequest);

        return
            _eas.revoke{value: msg.value}(
                RevocationRequest({
                    schema: delegatedRequest.schema,
                    data: delegatedRequest.data
                })
            );
    }

    /**
     * @dev Revokes existing attestations to multiple schemas via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi revocation attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevokeByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * }])
     *
     */
    function multiRevokeByDelegation(
        MultiDelegatedProxyRevocationRequest[] calldata multiDelegatedRequests
    ) public payable virtual {
        MultiRevocationRequest[]
            memory multiRequests = new MultiRevocationRequest[](
                multiDelegatedRequests.length
            );

        for (uint256 i = 0; i < multiDelegatedRequests.length; ) {
            MultiDelegatedProxyRevocationRequest
                memory multiDelegatedRequest = multiDelegatedRequests[i];
            RevocationRequestData[] memory data = multiDelegatedRequest.data;

            // Ensure that no inputs are missing.
            if (
                data.length == 0 ||
                data.length != multiDelegatedRequest.signatures.length
            ) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j = 0; j < data.length; ) {
                RevocationRequestData memory requestData = data[j];

                _verifyRevoke(
                    DelegatedProxyRevocationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: requestData,
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker,
                        deadline: multiDelegatedRequest.deadline
                    })
                );

                unchecked {
                    ++j;
                }
            }

            multiRequests[i] = MultiRevocationRequest({
                schema: multiDelegatedRequest.schema,
                data: data
            });

            unchecked {
                ++i;
            }
        }

        _eas.multiRevoke{value: msg.value}(multiRequests);
    }

    /**
     * @dev Verifies delegated attestation request.
     *
     * @param request The arguments of the delegated attestation request.
     */
    function _verifyAttest(
        DelegatedProxyAttestationRequest memory request
    ) internal {
        if (request.attester != _attester) revert InvalidAttester();

        if (
            request.deadline != NO_EXPIRATION_TIME &&
            request.deadline <= _time()
        ) {
            revert DeadlineExpired();
        }

        AttestationRequestData memory data = request.data;
        EIP712Signature memory signature = request.signature;

        _verifyUnusedSignature(signature);

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTEST_PROXY_TYPEHASH,
                    request.schema,
                    data.recipient,
                    data.expirationTime,
                    data.revocable,
                    data.refUID,
                    keccak256(data.data),
                    request.deadline
                )
            )
        );

        if (
            ECDSA.recover(digest, signature.v, signature.r, signature.s) !=
            request.attester
        ) {
            revert InvalidSignature();
        }
    }

    /**
     * @dev Verifies delegated revocation request.
     *
     * @param request The arguments of the delegated revocation request.
     */
    function _verifyRevoke(
        DelegatedProxyRevocationRequest memory request
    ) internal {
        if (request.revoker != _attester) revert InvalidAttester();

        if (
            request.deadline != NO_EXPIRATION_TIME &&
            request.deadline <= _time()
        ) {
            revert DeadlineExpired();
        }

        RevocationRequestData memory data = request.data;

        // Allow only original attesters to revoke their attestations.
        address attester = _attesters[data.uid];
        if (attester == address(0)) {
            revert NotFound();
        }

        if (attester != msg.sender) {
            revert AccessDenied();
        }

        EIP712Signature memory signature = request.signature;

        _verifyUnusedSignature(signature);

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REVOKE_PROXY_TYPEHASH,
                    request.schema,
                    data.uid,
                    request.deadline
                )
            )
        );

        if (
            ECDSA.recover(digest, signature.v, signature.r, signature.s) !=
            request.revoker
        ) {
            revert InvalidSignature();
        }
    }

    /**
     * @dev Ensures that the provided EIP712 signature wasn't already used.
     *
     * @param signature The EIP712 signature data.
     */
    function _verifyUnusedSignature(EIP712Signature memory signature) internal {
        bytes memory packedSignature = abi.encodePacked(
            signature.v,
            signature.r,
            signature.s
        );

        if (_signatures[packedSignature]) {
            revert UsedSignature();
        }

        _signatures[packedSignature] = true;
    }

    /**
     * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
     * current block time.
     */
    function _time() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * @dev Returns the addresss of the attester whitelisted to attest using this proxy.
     */
    function currentAttester() external view returns (address) {
        return _attester;
    }

    /**
     * @dev Updates the whitelisted address for this proxy address
     *
     * @param newAttester New address to give attestation rights to.
     */
    function updateAttester(address newAttester) external {
        if (msg.sender != _attester) revert InvalidAttester();
        _attester = newAttester;
    }
}