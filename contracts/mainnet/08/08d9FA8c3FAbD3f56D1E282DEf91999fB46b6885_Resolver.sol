// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/**
 * @dev A helper function to work with unchecked iterators in loops.
 */
function uncheckedInc(uint256 i) pure returns (uint256 j) {
    unchecked {
        j = i + 1;
    }
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

pragma solidity 0.8.19;

import { IEAS, Attestation } from "../IEAS.sol";
import { InvalidEAS, uncheckedInc } from "../Common.sol";

import { ISchemaResolver } from "./ISchemaResolver.sol";

/**
 * @title A base resolver contract
 */
abstract contract SchemaResolver is ISchemaResolver {
    error AccessDenied();
    error InsufficientValue();
    error NotPayable();

    // The version of the contract.
    string public constant VERSION = "0.28";

    // The global EAS contract.
    IEAS internal immutable _eas;

    /**
     * @dev Creates a new resolver.
     *
     * @param eas The address of the global EAS contract.
     */
    constructor(IEAS eas) {
        if (address(eas) == address(0)) {
            revert InvalidEAS();
        }

        _eas = eas;
    }

    /**
     * @dev Ensures that only the EAS contract can make this call.
     */
    modifier onlyEAS() {
        _onlyEAS();

        _;
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function isPayable() public pure virtual returns (bool) {
        return false;
    }

    /**
     * @dev ETH callback.
     */
    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function attest(Attestation calldata attestation) external payable onlyEAS returns (bool) {
        return onAttest(attestation, msg.value);
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function multiAttest(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable onlyEAS returns (bool) {
        uint256 length = attestations.length;

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the attestation to the underlying resolver and revert in case it isn't approved.
            if (!onAttest(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function revoke(Attestation calldata attestation) external payable onlyEAS returns (bool) {
        return onRevoke(attestation, msg.value);
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function multiRevoke(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable onlyEAS returns (bool) {
        uint256 length = attestations.length;

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the revocation to the underlying resolver and revert in case it isn't approved.
            if (!onRevoke(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /**
     * @dev A resolver callback that should be implemented by child contracts.
     *
     * @param attestation The new attestation.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     * both attest() and multiAttest() callbacks EAS-only callbacks and that in case of multi attestations, it'll
     * usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all the attestations
     * in the batch.
     *
     * @return Whether the attestation is valid.
     */
    function onAttest(Attestation calldata attestation, uint256 value) internal virtual returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     * both revoke() and multiRevoke() callbacks EAS-only callbacks and that in case of multi attestations, it'll
     * usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all the attestations
     * in the batch.
     *
     * @return Whether the attestation can be revoked.
     */
    function onRevoke(Attestation calldata attestation, uint256 value) internal virtual returns (bool);

    /**
     * @dev Ensures that only the EAS contract can make this call.
     */
    function _onlyEAS() private view {
        if (msg.sender != address(_eas)) {
            revert AccessDenied();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solmate/src/tokens/ERC721.sol";

contract OnChainCredential is ERC721 {
    error InvalidMintAuthority();
    error TransferNotAllowed();
    error InvalidCaller();

    mapping(uint256 => string) private metadata;
    address internal mint_authority;
    address public owner;
    uint256 tokenIDs = 0;

    constructor(
        string memory name,
        string memory symbol,
        address _mint_authority,
        address _owner
    ) ERC721(name, symbol) {
        mint_authority = _mint_authority;
        owner = _owner;
    }

    /// @notice Mints NFT Credential
    /// @dev Explain to a developer any extra details
    /// @param token_metadata Metadata of the token
    /// @param to Address of the receiver
    function mint(string calldata token_metadata, address to) external {
        if (msg.sender != mint_authority) revert InvalidMintAuthority();
        uint256 current_token_index = tokenIDs;
        metadata[current_token_index] = token_metadata;
        _mint(to, current_token_index);
        unchecked {
            tokenIDs++;
        }
    }

    /// @notice Returns the metadata of the token
    /// @param id ID of the token
    /// @return Documents the return variables of a contract’s function state variable
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return metadata[id];
    }

    /// @notice Internal Transfer Function
    /// @param from address of current owner
    /// @param to address of new owner
    /// @param id ID of the token
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (msg.sender != owner) revert TransferNotAllowed();
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    /// @notice Updates the mint authority
    /// @param newAuthority Address of the new mint authority
    function updateMintAuthority(address newAuthority) external {
        if (msg.sender != owner) revert InvalidCaller();
        mint_authority = newAuthority;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {Attestation, IEAS} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {OnChainCredential} from "./Credential.sol";

contract Resolver is SchemaResolver {
    /// @notice Stores the address of a whitelisted attester
    address public attester;
    address public owner;

    error ValueMismatch();
    error InvalidCaller();

    constructor(IEAS eas) SchemaResolver(eas) {
        attester = msg.sender;
        owner = msg.sender;
    }

    /// @notice Updates the attester for future
    /// @param newAttester The new attester address to be set in the contract state.

    function updateAttester(address newAttester) external {
        if (msg.sender != owner) revert InvalidCaller();
        attester = newAttester;
    }

    function getEAS() external view returns (IEAS) {
        return _eas;
    }

    /// @notice Called by EAS Contracts if a schema has resolver set while attesting.
    /// @param attestation The attestation calldata forwarded by EAS Contracts.
    /// @return returns bool to have custom logic to accept or reject an attestation.

    function onAttest(
        Attestation calldata attestation,
        uint256 /**value**/
    ) internal virtual override returns (bool) {
        if (attestation.attester != attester) revert InvalidCaller();
        (
            string memory nft_metadata_ipfs_url,
            string memory user_uuid,
            string memory credential_uuid,
            string memory hackathon_uuid,
            string memory user_hackathon_credential_uuid,
            address nft_contract
        ) = abi.decode(
                attestation.data,
                (string, string, string, string, string, address)
            );

        OnChainCredential credential_contract = OnChainCredential(nft_contract);

        credential_contract.mint(nft_metadata_ipfs_url, attestation.recipient);

        return true;
    }

    /// @notice Called by EAS Contracts if a schema has resolver set while revoking attestations.
    /// @param attestation The attestation calldata forwarded by EAS Contracts.
    /// @return returns bool to have custom logic to accept or reject a revoke request.

    function onRevoke(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal virtual override returns (bool) {
        return attestation.attester == attester;
    }

    function isPayable() public pure virtual override returns (bool) {
        return false;
    }

    function updateOwner(address newOwner) external {
        if (msg.sender != owner) revert InvalidCaller();
        owner = newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}