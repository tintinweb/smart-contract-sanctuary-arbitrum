// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint64 constant NO_EXPIRATION_TIME = 0;

error AccessDenied();
error DeadlineExpired();
error InvalidEAS();
error InvalidLength();
error InvalidSignature();
error NotFound();

/// @notice A struct representing ECDSA signature data.
struct Signature {
    uint8 v; // The recovery ID.
    bytes32 r; // The x-coordinate of the nonce R.
    bytes32 s; // The signature data.
}

/// @notice A struct representing a single attestation.
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

/// @notice A helper function to work with unchecked iterators in loops.
function uncheckedInc(uint256 i) pure returns (uint256 j) {
    unchecked {
        j = i + 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { EIP1271Verifier } from "./eip1271/EIP1271Verifier.sol";

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

// prettier-ignore
import {
    AccessDenied,
    EMPTY_UID,
    Signature,
    InvalidLength,
    NotFound,
    NO_EXPIRATION_TIME,
    uncheckedInc
} from "./Common.sol";

// prettier-ignore
import {
    Attestation,
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
} from "./IEAS.sol";

import { Semver } from "./Semver.sol";
import { ISchemaRegistry, SchemaRecord } from "./ISchemaRegistry.sol";

/// @title EAS
/// @notice The Ethereum Attestation Service protocol.
contract EAS is IEAS, Semver, EIP1271Verifier {
    using Address for address payable;

    error AlreadyRevoked();
    error AlreadyRevokedOffchain();
    error AlreadyTimestamped();
    error InsufficientValue();
    error InvalidAttestation();
    error InvalidAttestations();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidRevocation();
    error InvalidRevocations();
    error InvalidSchema();
    error InvalidVerifier();
    error Irrevocable();
    error NotPayable();
    error WrongSchema();

    /// @notice A struct representing an internal attestation result.
    struct AttestationsResult {
        uint256 usedValue; // Total ETH amount that was sent to resolvers.
        bytes32[] uids; // UIDs of the new attestations.
    }

    // The global schema registry.
    ISchemaRegistry private immutable _schemaRegistry;

    // The global mapping between attestations and their UIDs.
    mapping(bytes32 uid => Attestation attestation) private _db;

    // The global mapping between data and their timestamps.
    mapping(bytes32 data => uint64 timestamp) private _timestamps;

    // The global mapping between data and their revocation timestamps.
    mapping(address revoker => mapping(bytes32 data => uint64 timestamp) timestamps) private _revocationsOffchain;

    /// @dev Creates a new EAS instance.
    /// @param registry The address of the global schema registry.
    constructor(ISchemaRegistry registry) Semver(1, 3, 0) EIP1271Verifier("EAS", "1.3.0") {
        if (address(registry) == address(0)) {
            revert InvalidRegistry();
        }

        _schemaRegistry = registry;
    }

    /// @inheritdoc IEAS
    function getSchemaRegistry() external view returns (ISchemaRegistry) {
        return _schemaRegistry;
    }

    /// @inheritdoc IEAS
    function attest(AttestationRequest calldata request) external payable returns (bytes32) {
        AttestationRequestData[] memory data = new AttestationRequestData[](1);
        data[0] = request.data;

        return _attest(request.schema, data, msg.sender, msg.value, true).uids[0];
    }

    /// @inheritdoc IEAS
    function attestByDelegation(
        DelegatedAttestationRequest calldata delegatedRequest
    ) external payable returns (bytes32) {
        _verifyAttest(delegatedRequest);

        AttestationRequestData[] memory data = new AttestationRequestData[](1);
        data[0] = delegatedRequest.data;

        return _attest(delegatedRequest.schema, data, delegatedRequest.attester, msg.value, true).uids[0];
    }

    /// @inheritdoc IEAS
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable returns (bytes32[] memory) {
        // Since a multi-attest call is going to make multiple attestations for multiple schemas, we'd need to collect
        // all the returned UIDs into a single list.
        uint256 length = multiRequests.length;
        bytes32[][] memory totalUIDs = new bytes32[][](length);
        uint256 totalUIDCount = 0;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            // Process the current batch of attestations.
            MultiAttestationRequest calldata multiRequest = multiRequests[i];

            // Ensure that data isn't empty.
            if (multiRequest.data.length == 0) {
                revert InvalidLength();
            }

            AttestationsResult memory res = _attest(
                multiRequest.schema,
                multiRequest.data,
                msg.sender,
                availableValue,
                last
            );

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= res.usedValue;

            // Collect UIDs (and merge them later).
            totalUIDs[i] = res.uids;
            unchecked {
                totalUIDCount += res.uids.length;
            }
        }

        // Merge all the collected UIDs and return them as a flatten array.
        return _mergeUIDs(totalUIDs, totalUIDCount);
    }

    /// @inheritdoc IEAS
    function multiAttestByDelegation(
        MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests
    ) external payable returns (bytes32[] memory) {
        // Since a multi-attest call is going to make multiple attestations for multiple schemas, we'd need to collect
        // all the returned UIDs into a single list.
        uint256 length = multiDelegatedRequests.length;
        bytes32[][] memory totalUIDs = new bytes32[][](length);
        uint256 totalUIDCount = 0;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedAttestationRequest calldata multiDelegatedRequest = multiDelegatedRequests[i];
            AttestationRequestData[] calldata data = multiDelegatedRequest.data;

            // Ensure that no inputs are missing.
            uint256 dataLength = data.length;
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j = 0; j < dataLength; j = uncheckedInc(j)) {
                _verifyAttest(
                    DelegatedAttestationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester,
                        deadline: multiDelegatedRequest.deadline
                    })
                );
            }

            // Process the current batch of attestations.
            AttestationsResult memory res = _attest(
                multiDelegatedRequest.schema,
                data,
                multiDelegatedRequest.attester,
                availableValue,
                last
            );

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= res.usedValue;

            // Collect UIDs (and merge them later).
            totalUIDs[i] = res.uids;
            unchecked {
                totalUIDCount += res.uids.length;
            }
        }

        // Merge all the collected UIDs and return them as a flatten array.
        return _mergeUIDs(totalUIDs, totalUIDCount);
    }

    /// @inheritdoc IEAS
    function revoke(RevocationRequest calldata request) external payable {
        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        _revoke(request.schema, data, msg.sender, msg.value, true);
    }

    /// @inheritdoc IEAS
    function revokeByDelegation(DelegatedRevocationRequest calldata delegatedRequest) external payable {
        _verifyRevoke(delegatedRequest);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = delegatedRequest.data;

        _revoke(delegatedRequest.schema, data, delegatedRequest.revoker, msg.value, true);
    }

    /// @inheritdoc IEAS
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        uint256 length = multiRequests.length;
        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiRevocationRequest calldata multiRequest = multiRequests[i];

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _revoke(multiRequest.schema, multiRequest.data, msg.sender, availableValue, last);
        }
    }

    /// @inheritdoc IEAS
    function multiRevokeByDelegation(
        MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests
    ) external payable {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        uint256 length = multiDelegatedRequests.length;
        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedRevocationRequest memory multiDelegatedRequest = multiDelegatedRequests[i];
            RevocationRequestData[] memory data = multiDelegatedRequest.data;

            // Ensure that no inputs are missing.
            uint256 dataLength = data.length;
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j = 0; j < dataLength; j = uncheckedInc(j)) {
                _verifyRevoke(
                    DelegatedRevocationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker,
                        deadline: multiDelegatedRequest.deadline
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _revoke(
                multiDelegatedRequest.schema,
                data,
                multiDelegatedRequest.revoker,
                availableValue,
                last
            );
        }
    }

    /// @inheritdoc IEAS
    function timestamp(bytes32 data) external returns (uint64) {
        uint64 time = _time();

        _timestamp(data, time);

        return time;
    }

    /// @inheritdoc IEAS
    function revokeOffchain(bytes32 data) external returns (uint64) {
        uint64 time = _time();

        _revokeOffchain(msg.sender, data, time);

        return time;
    }

    /// @inheritdoc IEAS
    function multiRevokeOffchain(bytes32[] calldata data) external returns (uint64) {
        uint64 time = _time();

        uint256 length = data.length;
        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            _revokeOffchain(msg.sender, data[i], time);
        }

        return time;
    }

    /// @inheritdoc IEAS
    function multiTimestamp(bytes32[] calldata data) external returns (uint64) {
        uint64 time = _time();

        uint256 length = data.length;
        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            _timestamp(data[i], time);
        }

        return time;
    }

    /// @inheritdoc IEAS
    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        return _db[uid];
    }

    /// @inheritdoc IEAS
    function isAttestationValid(bytes32 uid) public view returns (bool) {
        return _db[uid].uid != EMPTY_UID;
    }

    /// @inheritdoc IEAS
    function getTimestamp(bytes32 data) external view returns (uint64) {
        return _timestamps[data];
    }

    /// @inheritdoc IEAS
    function getRevokeOffchain(address revoker, bytes32 data) external view returns (uint64) {
        return _revocationsOffchain[revoker][data];
    }

    /// @dev Attests to a specific schema.
    /// @param schemaUID The unique identifier of the schema to attest to.
    /// @param data The arguments of the attestation requests.
    /// @param attester The attesting account.
    /// @param availableValue The total available ETH amount that can be sent to the resolver.
    /// @param last Whether this is the last attestations/revocations set.
    /// @return The UID of the new attestations and the total sent ETH amount.
    function _attest(
        bytes32 schemaUID,
        AttestationRequestData[] memory data,
        address attester,
        uint256 availableValue,
        bool last
    ) private returns (AttestationsResult memory) {
        uint256 length = data.length;

        AttestationsResult memory res;
        res.uids = new bytes32[](length);

        // Ensure that we aren't attempting to attest to a non-existing schema.
        SchemaRecord memory schemaRecord = _schemaRegistry.getSchema(schemaUID);
        if (schemaRecord.uid == EMPTY_UID) {
            revert InvalidSchema();
        }

        Attestation[] memory attestations = new Attestation[](length);
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            AttestationRequestData memory request = data[i];

            // Ensure that either no expiration time was set or that it was set in the future.
            if (request.expirationTime != NO_EXPIRATION_TIME && request.expirationTime <= _time()) {
                revert InvalidExpirationTime();
            }

            // Ensure that we aren't trying to make a revocable attestation for a non-revocable schema.
            if (!schemaRecord.revocable && request.revocable) {
                revert Irrevocable();
            }

            Attestation memory attestation = Attestation({
                uid: EMPTY_UID,
                schema: schemaUID,
                refUID: request.refUID,
                time: _time(),
                expirationTime: request.expirationTime,
                revocationTime: 0,
                recipient: request.recipient,
                attester: attester,
                revocable: request.revocable,
                data: request.data
            });

            // Look for the first non-existing UID (and use a bump seed/nonce in the rare case of a conflict).
            bytes32 uid;
            uint32 bump = 0;
            while (true) {
                uid = _getUID(attestation, bump);
                if (_db[uid].uid == EMPTY_UID) {
                    break;
                }

                unchecked {
                    ++bump;
                }
            }
            attestation.uid = uid;

            _db[uid] = attestation;

            if (request.refUID != EMPTY_UID) {
                // Ensure that we aren't trying to attest to a non-existing referenced UID.
                if (!isAttestationValid(request.refUID)) {
                    revert NotFound();
                }
            }

            attestations[i] = attestation;
            values[i] = request.value;

            res.uids[i] = uid;

            emit Attested(request.recipient, attester, uid, schemaUID);
        }

        res.usedValue = _resolveAttestations(schemaRecord, attestations, values, false, availableValue, last);

        return res;
    }

    /// @dev Revokes an existing attestation to a specific schema.
    /// @param schemaUID The unique identifier of the schema to attest to.
    /// @param data The arguments of the revocation requests.
    /// @param revoker The revoking account.
    /// @param availableValue The total available ETH amount that can be sent to the resolver.
    /// @param last Whether this is the last attestations/revocations set.
    /// @return Returns the total sent ETH amount.
    function _revoke(
        bytes32 schemaUID,
        RevocationRequestData[] memory data,
        address revoker,
        uint256 availableValue,
        bool last
    ) private returns (uint256) {
        // Ensure that a non-existing schema ID wasn't passed by accident.
        SchemaRecord memory schemaRecord = _schemaRegistry.getSchema(schemaUID);
        if (schemaRecord.uid == EMPTY_UID) {
            revert InvalidSchema();
        }

        uint256 length = data.length;
        Attestation[] memory attestations = new Attestation[](length);
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory request = data[i];

            Attestation storage attestation = _db[request.uid];

            // Ensure that we aren't attempting to revoke a non-existing attestation.
            if (attestation.uid == EMPTY_UID) {
                revert NotFound();
            }

            // Ensure that a wrong schema ID wasn't passed by accident.
            if (attestation.schema != schemaUID) {
                revert InvalidSchema();
            }

            // Allow only original attesters to revoke their attestations.
            if (attestation.attester != revoker) {
                revert AccessDenied();
            }

            // Please note that also checking of the schema itself is revocable is unnecessary, since it's not possible to
            // make revocable attestations to an irrevocable schema.
            if (!attestation.revocable) {
                revert Irrevocable();
            }

            // Ensure that we aren't trying to revoke the same attestation twice.
            if (attestation.revocationTime != 0) {
                revert AlreadyRevoked();
            }
            attestation.revocationTime = _time();

            attestations[i] = attestation;
            values[i] = request.value;

            emit Revoked(attestations[i].recipient, revoker, request.uid, schemaUID);
        }

        return _resolveAttestations(schemaRecord, attestations, values, true, availableValue, last);
    }

    /// @dev Resolves a new attestation or a revocation of an existing attestation.
    /// @param schemaRecord The schema of the attestation.
    /// @param attestation The data of the attestation to make/revoke.
    /// @param value An explicit ETH amount to send to the resolver.
    /// @param isRevocation Whether to resolve an attestation or its revocation.
    /// @param availableValue The total available ETH amount that can be sent to the resolver.
    /// @param last Whether this is the last attestations/revocations set.
    /// @return Returns the total sent ETH amount.
    function _resolveAttestation(
        SchemaRecord memory schemaRecord,
        Attestation memory attestation,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool last
    ) private returns (uint256) {
        ISchemaResolver resolver = schemaRecord.resolver;
        if (address(resolver) == address(0)) {
            // Ensure that we don't accept payments if there is no resolver.
            if (value != 0) {
                revert NotPayable();
            }

            if (last) {
                _refund(availableValue);
            }

            return 0;
        }

        // Ensure that we don't accept payments which can't be forwarded to the resolver.
        if (value != 0) {
            if (!resolver.isPayable()) {
                revert NotPayable();
            }

            // Ensure that the attester/revoker doesn't try to spend more than available.
            if (value > availableValue) {
                revert InsufficientValue();
            }

            // Ensure to deduct the sent value explicitly.
            unchecked {
                availableValue -= value;
            }
        }

        if (isRevocation) {
            if (!resolver.revoke{ value: value }(attestation)) {
                revert InvalidRevocation();
            }
        } else if (!resolver.attest{ value: value }(attestation)) {
            revert InvalidAttestation();
        }

        if (last) {
            _refund(availableValue);
        }

        return value;
    }

    /// @dev Resolves multiple attestations or revocations of existing attestations.
    /// @param schemaRecord The schema of the attestation.
    /// @param attestations The data of the attestations to make/revoke.
    /// @param values Explicit ETH amounts to send to the resolver.
    /// @param isRevocation Whether to resolve an attestation or its revocation.
    /// @param availableValue The total available ETH amount that can be sent to the resolver.
    /// @param last Whether this is the last attestations/revocations set.
    /// @return Returns the total sent ETH amount.
    function _resolveAttestations(
        SchemaRecord memory schemaRecord,
        Attestation[] memory attestations,
        uint256[] memory values,
        bool isRevocation,
        uint256 availableValue,
        bool last
    ) private returns (uint256) {
        uint256 length = attestations.length;
        if (length == 1) {
            return _resolveAttestation(schemaRecord, attestations[0], values[0], isRevocation, availableValue, last);
        }

        ISchemaResolver resolver = schemaRecord.resolver;
        if (address(resolver) == address(0)) {
            // Ensure that we don't accept payments if there is no resolver.
            for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
                if (values[i] != 0) {
                    revert NotPayable();
                }
            }

            if (last) {
                _refund(availableValue);
            }

            return 0;
        }

        uint256 totalUsedValue = 0;
        bool isResolverPayable = resolver.isPayable();

        for (uint256 i = 0; i < length; i = uncheckedInc(i)) {
            uint256 value = values[i];

            // Ensure that we don't accept payments which can't be forwarded to the resolver.
            if (value == 0) {
                continue;
            }

            if (!isResolverPayable) {
                revert NotPayable();
            }

            // Ensure that the attester/revoker doesn't try to spend more than available.
            if (value > availableValue) {
                revert InsufficientValue();
            }

            // Ensure to deduct the sent value explicitly and add it to the total used value by the batch.
            unchecked {
                availableValue -= value;
                totalUsedValue += value;
            }
        }

        if (isRevocation) {
            if (!resolver.multiRevoke{ value: totalUsedValue }(attestations, values)) {
                revert InvalidRevocations();
            }
        } else if (!resolver.multiAttest{ value: totalUsedValue }(attestations, values)) {
            revert InvalidAttestations();
        }

        if (last) {
            _refund(availableValue);
        }

        return totalUsedValue;
    }

    /// @dev Calculates a UID for a given attestation.
    /// @param attestation The input attestation.
    /// @param bump A bump value to use in case of a UID conflict.
    /// @return Attestation UID.
    function _getUID(Attestation memory attestation, uint32 bump) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.expirationTime,
                    attestation.revocable,
                    attestation.refUID,
                    attestation.data,
                    bump
                )
            );
    }

    /// @dev Refunds remaining ETH amount to the attester.
    /// @param remainingValue The remaining ETH amount that was not sent to the resolver.
    function _refund(uint256 remainingValue) private {
        if (remainingValue > 0) {
            // Using a regular transfer here might revert, for some non-EOA attesters, due to exceeding of the 2300
            // gas limit which is why we're using call instead (via sendValue), which the 2300 gas limit does not
            // apply for.
            payable(msg.sender).sendValue(remainingValue);
        }
    }

    /// @dev Timestamps the specified bytes32 data.
    /// @param data The data to timestamp.
    /// @param time The timestamp.
    function _timestamp(bytes32 data, uint64 time) private {
        if (_timestamps[data] != 0) {
            revert AlreadyTimestamped();
        }

        _timestamps[data] = time;

        emit Timestamped(data, time);
    }

    /// @dev Revokes the specified bytes32 data.
    /// @param revoker The revoking account.
    /// @param data The data to revoke.
    /// @param time The timestamp the data was revoked with.
    function _revokeOffchain(address revoker, bytes32 data, uint64 time) private {
        mapping(bytes32 data => uint64 timestamp) storage revocations = _revocationsOffchain[revoker];

        if (revocations[data] != 0) {
            revert AlreadyRevokedOffchain();
        }

        revocations[data] = time;

        emit RevokedOffchain(revoker, data, time);
    }

    /// @dev Merges lists of UIDs.
    /// @param uidLists The provided lists of UIDs.
    /// @param uidCount Total UID count.
    /// @return A merged and flatten list of all the UIDs.
    function _mergeUIDs(bytes32[][] memory uidLists, uint256 uidCount) private pure returns (bytes32[] memory) {
        bytes32[] memory uids = new bytes32[](uidCount);

        uint256 currentIndex = 0;
        uint256 uidListLength = uidLists.length;
        for (uint256 i = 0; i < uidListLength; i = uncheckedInc(i)) {
            bytes32[] memory currentUIDs = uidLists[i];
            uint256 currentUIDsLength = currentUIDs.length;
            for (uint256 j = 0; j < currentUIDsLength; j = uncheckedInc(j)) {
                uids[currentIndex] = currentUIDs[j];

                unchecked {
                    ++currentIndex;
                }
            }
        }

        return uids;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// prettier-ignore
import {
    AttestationRequestData,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest,
    RevocationRequestData
} from "../IEAS.sol";

import { DeadlineExpired, NO_EXPIRATION_TIME, Signature, InvalidSignature } from "../Common.sol";

/// @title EIP1271Verifier
/// @notice EIP1271Verifier typed signatures verifier for EAS delegated attestations.
abstract contract EIP1271Verifier is EIP712 {
    using Address for address;

    error InvalidNonce();

    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(address attester,bytes32 schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint256 value,uint256 nonce,uint64 deadline)").
    bytes32 private constant ATTEST_TYPEHASH = 0xfeb2925a02bae3dae48d424a0437a2b6ac939aa9230ddc55a1a76f065d988076;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(address revoker,bytes32 schema,bytes32 uid,uint256 value,uint256 nonce,uint64 deadline)").
    bytes32 private constant REVOKE_TYPEHASH = 0xb5d556f07587ec0f08cf386545cc4362c702a001650c2058002615ee5c9d1e75;

    // The user readable name of the signing domain.
    string private _name;

    // Replay protection nonces.
    mapping(address attester => uint256 nonce) private _nonces;

    /// @notice Emitted when users invalidate nonces by increasing their nonces to (higher) new values.
    /// @param oldNonce The previous nonce.
    /// @param newNonce The new value.
    event NonceIncreased(uint256 oldNonce, uint256 newNonce);

    /// @dev Creates a new EIP1271Verifier instance.
    /// @param version The current major version of the signing domain
    constructor(string memory name, string memory version) EIP712(name, version) {
        _name = name;
    }

    /// @notice Returns the domain separator used in the encoding of the signatures for attest, and revoke.
    /// @return The domain separator used in the encoding of the signatures for attest, and revoke.
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice Returns the current nonce per-account.
    /// @param account The requested account.
    /// @return The current nonce.
    function getNonce(address account) external view returns (uint256) {
        return _nonces[account];
    }

    /// @notice Returns the EIP712 type hash for the attest function.
    /// @return The EIP712 type hash for the attest function.
    function getAttestTypeHash() external pure returns (bytes32) {
        return ATTEST_TYPEHASH;
    }

    /// @notice Returns the EIP712 type hash for the revoke function.
    /// @return The EIP712 type hash for the revoke function.
    function getRevokeTypeHash() external pure returns (bytes32) {
        return REVOKE_TYPEHASH;
    }

    /// @notice Returns the EIP712 name.
    /// @return The EIP712 name.
    function getName() external view returns (string memory) {
        return _name;
    }

    /// @notice Provides users an option to invalidate nonces by increasing their nonces to (higher) new values.
    /// @param newNonce The (higher) new value.
    function increaseNonce(uint256 newNonce) external {
        uint256 oldNonce = _nonces[msg.sender];
        if (newNonce <= oldNonce) {
            revert InvalidNonce();
        }

        _nonces[msg.sender] = newNonce;

        emit NonceIncreased({ oldNonce: oldNonce, newNonce: newNonce });
    }

    /// @dev Verifies delegated attestation request.
    /// @param request The arguments of the delegated attestation request.
    function _verifyAttest(DelegatedAttestationRequest memory request) internal {
        if (request.deadline != NO_EXPIRATION_TIME && request.deadline < _time()) {
            revert DeadlineExpired();
        }

        AttestationRequestData memory data = request.data;
        Signature memory signature = request.signature;

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTEST_TYPEHASH,
                    request.attester,
                    request.schema,
                    data.recipient,
                    data.expirationTime,
                    data.revocable,
                    data.refUID,
                    keccak256(data.data),
                    data.value,
                    _nonces[request.attester]++,
                    request.deadline
                )
            )
        );
        if (
            !SignatureChecker.isValidSignatureNow(
                request.attester,
                hash,
                abi.encodePacked(signature.r, signature.s, signature.v)
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @dev Verifies delegated revocation request.
    /// @param request The arguments of the delegated revocation request.
    function _verifyRevoke(DelegatedRevocationRequest memory request) internal {
        if (request.deadline != NO_EXPIRATION_TIME && request.deadline < _time()) {
            revert DeadlineExpired();
        }

        RevocationRequestData memory data = request.data;
        Signature memory signature = request.signature;

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    REVOKE_TYPEHASH,
                    request.revoker,
                    request.schema,
                    data.uid,
                    data.value,
                    _nonces[request.revoker]++,
                    request.deadline
                )
            )
        );
        if (
            !SignatureChecker.isValidSignatureNow(
                request.revoker,
                hash,
                abi.encodePacked(signature.r, signature.s, signature.v)
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
    ///     current block time.
    function _time() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaRegistry } from "./ISchemaRegistry.sol";
import { Attestation, Signature } from "./Common.sol";

/// @notice A struct representing the arguments of the attestation request.
struct AttestationRequestData {
    address recipient; // The recipient of the attestation.
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bytes32 refUID; // The UID of the related attestation.
    bytes data; // Custom attestation data.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/// @notice A struct representing the full arguments of the attestation request.
struct AttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/// @notice A struct representing the full arguments of the full delegated attestation request.
struct DelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    Signature signature; // The ECDSA signature data.
    address attester; // The attesting account.
    uint64 deadline; // The deadline of the signature/request.
}

/// @notice A struct representing the full arguments of the multi attestation request.
struct MultiAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/// @notice A struct representing the full arguments of the delegated multi attestation request.
struct MultiDelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    Signature[] signatures; // The ECDSA signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
    uint64 deadline; // The deadline of the signature/request.
}

/// @notice A struct representing the arguments of the revocation request.
struct RevocationRequestData {
    bytes32 uid; // The UID of the attestation to revoke.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/// @notice A struct representing the full arguments of the revocation request.
struct RevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/// @notice A struct representing the arguments of the full delegated revocation request.
struct DelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    Signature signature; // The ECDSA signature data.
    address revoker; // The revoking account.
    uint64 deadline; // The deadline of the signature/request.
}

/// @notice A struct representing the full arguments of the multi revocation request.
struct MultiRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/// @notice A struct representing the full arguments of the delegated multi revocation request.
struct MultiDelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    Signature[] signatures; // The ECDSA signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
    uint64 deadline; // The deadline of the signature/request.
}

/// @title IEAS
/// @notice EAS - Ethereum Attestation Service interface.
interface IEAS {
    /// @notice Emitted when an attestation has been made.
    /// @param recipient The recipient of the attestation.
    /// @param attester The attesting account.
    /// @param uid The UID the revoked attestation.
    /// @param schemaUID The UID of the schema.
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schemaUID);

    /// @notice Emitted when an attestation has been revoked.
    /// @param recipient The recipient of the attestation.
    /// @param attester The attesting account.
    /// @param schemaUID The UID of the schema.
    /// @param uid The UID the revoked attestation.
    event Revoked(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schemaUID);

    /// @notice Emitted when a data has been timestamped.
    /// @param data The data.
    /// @param timestamp The timestamp.
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    /// @notice Emitted when a data has been revoked.
    /// @param revoker The address of the revoker.
    /// @param data The data.
    /// @param timestamp The timestamp.
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);

    /// @notice Returns the address of the global schema registry.
    /// @return The address of the global schema registry.
    function getSchemaRegistry() external view returns (ISchemaRegistry);

    /// @notice Attests to a specific schema.
    /// @param request The arguments of the attestation request.
    /// @return The UID of the new attestation.
    ///
    /// Example:
    ///     attest({
    ///         schema: "0facc36681cbe2456019c1b0d1e7bedd6d1d40f6f324bf3dd3a4cef2999200a0",
    ///         data: {
    ///             recipient: "0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf",
    ///             expirationTime: 0,
    ///             revocable: true,
    ///             refUID: "0x0000000000000000000000000000000000000000000000000000000000000000",
    ///             data: "0xF00D",
    ///             value: 0
    ///         }
    ///     })
    function attest(AttestationRequest calldata request) external payable returns (bytes32);

    /// @notice Attests to a specific schema via the provided ECDSA signature.
    /// @param delegatedRequest The arguments of the delegated attestation request.
    /// @return The UID of the new attestation.
    ///
    /// Example:
    ///     attestByDelegation({
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: {
    ///             recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    ///             expirationTime: 1673891048,
    ///             revocable: true,
    ///             refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
    ///             data: '0x1234',
    ///             value: 0
    ///         },
    ///         signature: {
    ///             v: 28,
    ///             r: '0x148c...b25b',
    ///             s: '0x5a72...be22'
    ///         },
    ///         attester: '0xc5E8740aD971409492b1A63Db8d83025e0Fc427e',
    ///         deadline: 1673891048
    ///     })
    function attestByDelegation(
        DelegatedAttestationRequest calldata delegatedRequest
    ) external payable returns (bytes32);

    /// @notice Attests to multiple schemas.
    /// @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
    ///     schema ids to benefit from the best batching optimization.
    /// @return The UIDs of the new attestations.
    ///
    /// Example:
    ///     multiAttest([{
    ///         schema: '0x33e9094830a5cba5554d1954310e4fbed2ef5f859ec1404619adea4207f391fd',
    ///         data: [{
    ///             recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
    ///             expirationTime: 1673891048,
    ///             revocable: true,
    ///             refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
    ///             data: '0x1234',
    ///             value: 1000
    ///         },
    ///         {
    ///             recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    ///             expirationTime: 0,
    ///             revocable: false,
    ///             refUID: '0x480df4a039efc31b11bfdf491b383ca138b6bde160988222a2a3509c02cee174',
    ///             data: '0x00',
    ///             value: 0
    ///         }],
    ///     },
    ///     {
    ///         schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
    ///         data: [{
    ///             recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
    ///             expirationTime: 0,
    ///             revocable: true,
    ///             refUID: '0x75bf2ed8dca25a8190c50c52db136664de25b2449535839008ccfdab469b214f',
    ///             data: '0x12345678',
    ///             value: 0
    ///         },
    ///     }])
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable returns (bytes32[] memory);

    /// @notice Attests to multiple schemas using via provided ECDSA signatures.
    /// @param multiDelegatedRequests The arguments of the delegated multi attestation requests. The requests should be
    ///     grouped by distinct schema ids to benefit from the best batching optimization.
    /// @return The UIDs of the new attestations.
    ///
    /// Example:
    ///     multiAttestByDelegation([{
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: [{
    ///             recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    ///             expirationTime: 1673891048,
    ///             revocable: true,
    ///             refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
    ///             data: '0x1234',
    ///             value: 0
    ///         },
    ///         {
    ///             recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
    ///             expirationTime: 0,
    ///             revocable: false,
    ///             refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
    ///             data: '0x00',
    ///             value: 0
    ///         }],
    ///         signatures: [{
    ///             v: 28,
    ///             r: '0x148c...b25b',
    ///             s: '0x5a72...be22'
    ///         },
    ///         {
    ///             v: 28,
    ///             r: '0x487s...67bb',
    ///             s: '0x12ad...2366'
    ///         }],
    ///         attester: '0x1D86495b2A7B524D747d2839b3C645Bed32e8CF4',
    ///         deadline: 1673891048
    ///     }])
    function multiAttestByDelegation(
        MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests
    ) external payable returns (bytes32[] memory);

    /// @notice Revokes an existing attestation to a specific schema.
    /// @param request The arguments of the revocation request.
    ///
    /// Example:
    ///     revoke({
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: {
    ///             uid: '0x101032e487642ee04ee17049f99a70590c735b8614079fc9275f9dd57c00966d',
    ///             value: 0
    ///         }
    ///     })
    function revoke(RevocationRequest calldata request) external payable;

    /// @notice Revokes an existing attestation to a specific schema via the provided ECDSA signature.
    /// @param delegatedRequest The arguments of the delegated revocation request.
    ///
    /// Example:
    ///     revokeByDelegation({
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: {
    ///             uid: '0xcbbc12102578c642a0f7b34fe7111e41afa25683b6cd7b5a14caf90fa14d24ba',
    ///             value: 0
    ///         },
    ///         signature: {
    ///             v: 27,
    ///             r: '0xb593...7142',
    ///             s: '0x0f5b...2cce'
    ///         },
    ///         revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992',
    ///         deadline: 1673891048
    ///     })
    function revokeByDelegation(DelegatedRevocationRequest calldata delegatedRequest) external payable;

    /// @notice Revokes existing attestations to multiple schemas.
    /// @param multiRequests The arguments of the multi revocation requests. The requests should be grouped by distinct
    ///     schema ids to benefit from the best batching optimization.
    ///
    /// Example:
    ///     multiRevoke([{
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: [{
    ///             uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
    ///             value: 1000
    ///         },
    ///         {
    ///             uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
    ///             value: 0
    ///         }],
    ///     },
    ///     {
    ///         schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
    ///         data: [{
    ///             uid: '0x053d42abce1fd7c8fcddfae21845ad34dae287b2c326220b03ba241bc5a8f019',
    ///             value: 0
    ///         },
    ///     }])
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable;

    /// @notice Revokes existing attestations to multiple schemas via provided ECDSA signatures.
    /// @param multiDelegatedRequests The arguments of the delegated multi revocation attestation requests. The requests
    ///     should be grouped by distinct schema ids to benefit from the best batching optimization.
    ///
    /// Example:
    ///     multiRevokeByDelegation([{
    ///         schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
    ///         data: [{
    ///             uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
    ///             value: 1000
    ///         },
    ///         {
    ///             uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
    ///             value: 0
    ///         }],
    ///         signatures: [{
    ///             v: 28,
    ///             r: '0x148c...b25b',
    ///             s: '0x5a72...be22'
    ///         },
    ///         {
    ///             v: 28,
    ///             r: '0x487s...67bb',
    ///             s: '0x12ad...2366'
    ///         }],
    ///         revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992',
    ///         deadline: 1673891048
    ///     }])
    function multiRevokeByDelegation(
        MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests
    ) external payable;

    /// @notice Timestamps the specified bytes32 data.
    /// @param data The data to timestamp.
    /// @return The timestamp the data was timestamped with.
    function timestamp(bytes32 data) external returns (uint64);

    /// @notice Timestamps the specified multiple bytes32 data.
    /// @param data The data to timestamp.
    /// @return The timestamp the data was timestamped with.
    function multiTimestamp(bytes32[] calldata data) external returns (uint64);

    /// @notice Revokes the specified bytes32 data.
    /// @param data The data to timestamp.
    /// @return The timestamp the data was revoked with.
    function revokeOffchain(bytes32 data) external returns (uint64);

    /// @notice Revokes the specified multiple bytes32 data.
    /// @param data The data to timestamp.
    /// @return The timestamp the data was revoked with.
    function multiRevokeOffchain(bytes32[] calldata data) external returns (uint64);

    /// @notice Returns an existing attestation by UID.
    /// @param uid The UID of the attestation to retrieve.
    /// @return The attestation data members.
    function getAttestation(bytes32 uid) external view returns (Attestation memory);

    /// @notice Checks whether an attestation exists.
    /// @param uid The UID of the attestation to retrieve.
    /// @return Whether an attestation exists.
    function isAttestationValid(bytes32 uid) external view returns (bool);

    /// @notice Returns the timestamp that the specified data was timestamped with.
    /// @param data The data to query.
    /// @return The timestamp the data was timestamped with.
    function getTimestamp(bytes32 data) external view returns (uint64);

    /// @notice Returns the timestamp that the specified data was timestamped with.
    /// @param data The data to query.
    /// @return The timestamp the data was timestamped with.
    function getRevokeOffchain(address revoker, bytes32 data) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

/// @notice A struct representing a record for a submitted schema.
struct SchemaRecord {
    bytes32 uid; // The unique identifier of the schema.
    ISchemaResolver resolver; // Optional schema resolver.
    bool revocable; // Whether the schema allows revocations explicitly.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

/// @title ISchemaRegistry
/// @notice The interface of global attestation schemas for the Ethereum Attestation Service protocol.
interface ISchemaRegistry {
    /// @notice Emitted when a new schema has been registered
    /// @param uid The schema UID.
    /// @param registerer The address of the account used to register the schema.
    /// @param schema The schema data.
    event Registered(bytes32 indexed uid, address indexed registerer, SchemaRecord schema);

    /// @notice Submits and reserves a new schema
    /// @param schema The schema data schema.
    /// @param resolver An optional schema resolver.
    /// @param revocable Whether the schema allows revocations explicitly.
    /// @return The UID of the new schema.
    function register(string calldata schema, ISchemaResolver resolver, bool revocable) external returns (bytes32);

    /// @notice Returns an existing schema by UID
    /// @param uid The UID of the schema to retrieve.
    /// @return The schema data members.
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Attestation } from "../Common.sol";

/// @title ISchemaResolver
/// @notice The interface of an optional schema resolver.
interface ISchemaResolver {
    /// @notice Checks if the resolver can be sent ETH.
    /// @return Whether the resolver supports ETH transfers.
    function isPayable() external pure returns (bool);

    /// @notice Processes an attestation and verifies whether it's valid.
    /// @param attestation The new attestation.
    /// @return Whether the attestation is valid.
    function attest(Attestation calldata attestation) external payable returns (bool);

    /// @notice Processes multiple attestations and verifies whether they are valid.
    /// @param attestations The new attestations.
    /// @param values Explicit ETH amounts which were sent with each attestation.
    /// @return Whether all the attestations are valid.
    function multiAttest(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);

    /// @notice Processes an attestation revocation and verifies if it can be revoked.
    /// @param attestation The existing attestation to be revoked.
    /// @return Whether the attestation can be revoked.
    function revoke(Attestation calldata attestation) external payable returns (bool);

    /// @notice Processes revocation of multiple attestation and verifies they can be revoked.
    /// @param attestations The existing attestations to be revoked.
    /// @param values Explicit ETH amounts which were sent with each revocation.
    /// @return Whether the attestations can be revoked.
    function multiRevoke(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Semver
/// @notice A simple contract for managing contract versions.
contract Semver {
    // Contract's major version number.
    uint256 private immutable _major;

    // Contract's minor version number.
    uint256 private immutable _minor;

    // Contract's patch version number.
    uint256 private immutable _path;

    /// @dev Create a new Semver instance.
    /// @param major Major version number.
    /// @param minor Minor version number.
    /// @param patch Patch version number.
    constructor(uint256 major, uint256 minor, uint256 patch) {
        _major = major;
        _minor = minor;
        _path = patch;
    }

    /// @notice Returns the full semver contract version.
    /// @return Semver contract version as a string.
    function version() external view returns (string memory) {
        return
            string(
                abi.encodePacked(Strings.toString(_major), ".", Strings.toString(_minor), ".", Strings.toString(_path))
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

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
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

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
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
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

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { AttestationRequest, AttestationRequestData, IEAS, Attestation, MultiAttestationRequest, MultiRevocationRequest } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";


/**
 * @title GitcoinAttester
 * @dev A contract that allows a Verifier contract to add passport information for users using Ethereum Attestation Service.
 */
contract GitcoinAttester is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
  // An allow-list of Verifiers that are authorized and trusted to call the submitAttestations function.
  mapping(address => bool) public verifiers;

  // The instance of the EAS contract.
  IEAS public eas;

  // Emitted when a verifier is added to the allow-list.
  event VerifierAdded(address verifier);

  // Emitted when a verifier is removed from the allow-list.
  event VerifierRemoved(address verifier);

  // Emitted when the EAS contract is set.
  event EASSet(address eas);

  function initialize() public initializer {
    __Ownable_init();
    __Pausable_init();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  /**
   * @dev Adds a verifier to the allow-list.
   * @param _verifier The address of the verifier to add.
   */
  function addVerifier(address _verifier) public onlyOwner {
    require(!verifiers[_verifier], "Verifier already added");
    verifiers[_verifier] = true;
    emit VerifierAdded(_verifier);
  }

  /**
   * @dev Removes a verifier from the allow-list.
   * @param _verifier The address of the verifier to remove.
   */
  function removeVerifier(address _verifier) public onlyOwner {
    require(verifiers[_verifier], "Verifier does not exist");
    verifiers[_verifier] = false;
    emit VerifierRemoved(_verifier);
  }

  /**
   * @dev Sets the address of the EAS contract.
   * @param _easContractAddress The address of the EAS contract.
   */
  function setEASAddress(address _easContractAddress) public onlyOwner {
    eas = IEAS(_easContractAddress);
    emit EASSet(_easContractAddress);
  }

  /**
   * @dev Adds passport information for a user using EAS
   * @param multiAttestationRequest An array of `MultiAttestationRequest` structures containing the user's passport information.
   */
  function submitAttestations(
    MultiAttestationRequest[] calldata multiAttestationRequest
  ) public payable whenNotPaused returns (bytes32[] memory) {
    require(
      verifiers[msg.sender],
      "Only authorized verifiers can call this function"
    );

    return eas.multiAttest(multiAttestationRequest);
  }

  /**
   * @dev Revoke attestations by schema and uid
   * @param multiRevocationRequest An array of `MultiRevocationRequest` structures containing the attestations to revoke.
   */
  function revokeAttestations(
    MultiRevocationRequest[] calldata multiRevocationRequest
  ) public payable whenNotPaused {
    require(verifiers[msg.sender] || msg.sender == owner(), "Only authorized verifiers or owner can call this function");
    eas.multiRevoke(multiRevocationRequest);
  }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { AttestationRequest, AttestationRequestData, EAS, Attestation, MultiAttestationRequest } from "@ethereum-attestation-service/eas-contracts/contracts/EAS.sol";

import "./GitcoinAttester.sol";

/**
 * @title GitcoinVerifier
 * @notice This contract is used to verify a passport's authenticity and to add a passport to the GitcoinAttester contract using the verifyAndAttest() function.
 */
contract GitcoinVerifier is
  UUPSUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using ECDSA for bytes32;

  // Instance of the GitcoinAttester contract
  GitcoinAttester public attester;

  // Address of the issuer of the passport
  address public issuer;

  // Domain Separator, as defined by EIP-712 (`hashstruct(eip712Domain)`)
  bytes32 private DOMAIN_SEPARATOR;

  // Name of the contract
  string public name;

  // Nonces for each recipient address
  mapping(address => uint) public recipientNonces;

  error InsufficientFee();
  error InvalidNonce();
  error InvalidSignature();

  /**
   * @dev EIP712Domain represents the domain separator struct for EIP-712 typed data hashing.
   */
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  /**
   * @dev PassportAttestationRequest represents a signed data structure that once verified will be written to EAS.
   */
  struct PassportAttestationRequest {
    MultiAttestationRequest[] multiAttestationRequest;
    uint256 nonce;
    uint256 fee;
  }

  // Hash type for the EIP712 domain separator
  bytes32 private constant EIP712DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  // Hash type for the Stamp struct
  bytes32 private constant STAMP_TYPEHASH =
    keccak256(
      "AttestationRequestData(address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint256 value)"
    );

  bytes32 private constant MULTI_ATTESTATION_REQUEST_TYPEHASH =
    keccak256(
      "MultiAttestationRequest(bytes32 schema,AttestationRequestData[] data)AttestationRequestData(address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint256 value)"
    );

  // Hash type for the Passport struct
  bytes32 private constant PASSPORT_TYPEHASH =
    keccak256(
      "PassportAttestationRequest(MultiAttestationRequest[] multiAttestationRequest,uint256 nonce,uint256 fee)AttestationRequestData(address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint256 value)MultiAttestationRequest(bytes32 schema,AttestationRequestData[] data)"
    );

  /**
   * @notice Initializer function responsible for setting up the contract's initial state.
   * @param _issuer The address of the issuer of the passport.
   * @param _attester The address of the GitcoinAttester contract.
   */
  function initialize(address _issuer, address _attester) public initializer {
    __GitcoinVerifier_init(_issuer, _attester);
  }

  function __GitcoinVerifier_init(address _issuer, address _attester) internal onlyInitializing {
    __Ownable_init();
    __Pausable_init();

    attester = GitcoinAttester(_attester);
    issuer = _issuer;
    name = "GitcoinVerifier";

    uint256 chainId = _getChainId();

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes("1")), // version
        chainId, // chainId
        address(this) // verifyingContract
      )
    );

  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  /**
   * @notice Gets the current chain ID.
   * @return chainId The chain ID.
   */
  function _getChainId() private view returns (uint256 chainId) {
    assembly {
      chainId := chainid()
    }
  }

  /**
   * @dev Hashes the provided AttestationRequestData object. This function creates
   * a keccak256 hash from the recipient, expirationTime, revocable, refUID, data and value
   * fields of the _data object. The data field is hashed separately and included
   * in the final hash.
   * @param _data The AttestationRequestData object that will be hashed
   * @return bytes32 The keccak256 hash of the _data
   */
  function hashAttestationRequestData(
    AttestationRequestData memory _data
  ) private pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          STAMP_TYPEHASH,
          _data.recipient,
          _data.expirationTime,
          _data.revocable,
          _data.refUID,
          keccak256(_data.data),
          _data.value
        )
      );
  }

  /**
   * @dev Creates a hash for the provided MultiAttestationRequest object. This function
   * hashes each AttestationRequestData item in the data array, then generates and returns
   * a final keccak256 hash combining these hashes with the schema from the _request.
   * @param _request The MultiAttestationRequest object that will be hashed
   * @return bytes32 The keccak256 hash of the _request
   */
  function hashMultiAttestationRequest(
    MultiAttestationRequest memory _request
  ) private pure returns (bytes32) {
    bytes32[] memory dataHashes = new bytes32[](_request.data.length);
    for (uint i = 0; i < _request.data.length; ) {
      dataHashes[i] = hashAttestationRequestData(_request.data[i]);
      unchecked {
        ++i;
      }
    }

    return
      keccak256(
        abi.encode(
          MULTI_ATTESTATION_REQUEST_TYPEHASH,
          _request.schema,
          keccak256(abi.encodePacked(dataHashes))
        )
      );
  }

  /**
   * @dev Creates a hash for the provided PassportAttestationRequest object. This function
   * hashes each multiAttestationRequest, then generates and returns a final keccak256 hash
   * combining these hashes with additional data from the attestationRequest.
   * @param attestationRequest The PassportAttestationRequest object that will be hashed
   * @return bytes32 The keccak256 hash of the attestationRequest
   */
  function _hashAttestations(
    PassportAttestationRequest calldata attestationRequest
  ) private pure returns (bytes32) {
    bytes32[] memory multiAttestHashes = new bytes32[](
      attestationRequest.multiAttestationRequest.length
    );
    for (uint i = 0; i < attestationRequest.multiAttestationRequest.length; ) {
      multiAttestHashes[i] = hashMultiAttestationRequest(
        attestationRequest.multiAttestationRequest[i]
      );
      unchecked {
        ++i;
      }
    }

    return
      keccak256(
        abi.encode(
          PASSPORT_TYPEHASH,
          keccak256(abi.encodePacked(multiAttestHashes)),
          attestationRequest.nonce,
          attestationRequest.fee
        )
      );
  }

  /**
   * @dev Verifies a passport signature.
   * @param v The v component of the signature.
   * @param r The r component of the signature.
   * @param s The s component of the signature.
   * @param attestationRequest The attestation data to verify.
   */
  function _verify(
    uint8 v,
    bytes32 r,
    bytes32 s,
    PassportAttestationRequest calldata attestationRequest
  ) internal {
    // TODO: Check that all recipients are equivalent(We can currently trust this is true becuase it is being enforced when passport signs the request, but would be good to verify here as well)
    address recipient = attestationRequest
      .multiAttestationRequest[0]
      .data[0]
      .recipient;
    if (attestationRequest.nonce != recipientNonces[recipient]) {
      revert InvalidNonce();
    }

    bytes32 attestationHash = _hashAttestations(attestationRequest);
    bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, attestationHash);

    // Compare the recovered signer with the expected signer
    if (ECDSA.recover(digest, v, r, s) != issuer) {
      revert InvalidSignature();
    }

    // Increment the nonce for this recipient
    recipientNonces[recipient]++;
  }

  /**
   * @dev Adds a passport to the attester contract, verifying it using the provided signature.
   * @param attestationRequest The passport to add.
   * @param v The v component of the signature.
   * @param r The r component of the signature.
   * @param s The s component of the signature.
   */
  function verifyAndAttest(
    PassportAttestationRequest calldata attestationRequest,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual payable whenNotPaused returns (bytes32[] memory) {
    _verify(v, r, s, attestationRequest);

    if (msg.value < attestationRequest.fee) {
      revert InsufficientFee();
    }

    return
      attester.submitAttestations(attestationRequest.multiAttestationRequest);
  }

  /**
   * @dev Allows the contract owner to withdraw the contract's balance.
   */
  function withdrawFees(uint256 _amount) external onlyOwner {
    uint256 balance = address(this).balance;

    require(_amount <= balance, "Insufficient contract balance");

    payable(owner()).transfer(_amount);
  }
}