// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AttestationRegistry.sol";
import "./interfaces/IAttestationServices.sol";
import "./interfaces/IAttestationRegistry.sol";

contract AttestationServices {
    // The AS global registry.
    IAttestationRegistry private immutable _asRegistry;
    address AttestationRegistryAddress;

    constructor(IAttestationRegistry registry) {
        if (address(registry) == address(0x0)) {
            revert("InvalidRegistry");
        }
        _asRegistry = registry;
        // AttestationRegistryAddress=_asRegistry;
    }

    struct Attestation {
        // A unique identifier of the attestation.
        bytes32 uuid;
        // A unique identifier of the AS.
        bytes32 schema;
        // The recipient of the attestation.
        address recipient;
        // The attester/sender of the attestation.
        address attester;
        // The time when the attestation was created (Unix timestamp).
        uint256 time;
        // The time when the attestation was revoked (Unix timestamp).
        uint256 revocationTime;
        // Custom attestation data.
        bytes data;
    }

    // The global counter for the total number of attestations.
    uint256 private _attestationsCount;

    bytes32 private constant EMPTY_UUID = 0;

    // The global mapping between attestations and their UUIDs.
    mapping(bytes32 => Attestation) private _db;

    /**
     *  Triggered when an attestation has been made.
     ~recipient The recipient of the attestation.
     ~attester The attesting account.
     ~uuid The UUID the revoked attestation.
     ~schema The UUID of the AS.
     */
    event Attested(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    event Revoked(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    function getASRegistry() external view returns (IAttestationRegistry) {
        return _asRegistry;
    }

     /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The UUID of the new attestation.
     */
    function attest(
        address recipient,
        bytes32 schema,
        bytes calldata data
    ) public virtual returns (bytes32) {
        return _attest(recipient, schema, data, msg.sender);
    }

     /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     */
    function revoke(bytes32 uuid) public virtual {
        _revoke(uuid, msg.sender);
    }

    function _attest(
        address recipient,
        bytes32 schema,
        bytes calldata data,
        address attester
    ) private returns (bytes32) {

        IAttestationRegistry.ASRecord memory asRecord = _asRegistry.getAS(
            schema
        );
        if (asRecord.uuid == EMPTY_UUID) {
            revert("InvalidSchema");
        }

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            schema: schema,
            recipient: recipient,
            attester: attester,
            time: block.timestamp,
            revocationTime: 0,
            data: data
        });

        bytes32 _lastUUID;
        _lastUUID = _getUUID(attestation);
        attestation.uuid = _lastUUID;

        _db[_lastUUID] = attestation;
        _attestationsCount++;

        emit Attested(recipient, attester, _lastUUID, schema);

        return _lastUUID;
    }

    function _revoke(bytes32 uuid, address attester) private {
        Attestation storage attestation = _db[uuid];
        if (attestation.uuid == EMPTY_UUID) {
            revert("Not found");
        }

        if (attestation.attester != attester) {
            revert("Access denied");
        }

        if (attestation.revocationTime != 0) {
            revert ("Already Revoked");
        }

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, attester, uuid, attestation.schema);
    }

    function _getUUID(Attestation memory attestation)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.data,
                    _attestationsCount
                )
            );
    }

    /**
     * @dev Checks whether an attestation is active.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation is active.
     */
    function isAddressActive(bytes32 uuid) public view returns (bool) {
        return
            isAddressValid(uuid) &&
            _db[uuid].revocationTime == 0;
    }

     /**
     * @dev Checks whether an attestation exists.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAddressValid(bytes32 uuid) public view returns (bool) {
        return _db[uuid].uuid != 0;
    }
}

pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationServices {
    function register(bytes calldata schema) external returns (bytes32);
}

pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

interface IAttestationRegistry {

    /**
     * @title A struct representing a record for a submitted AS (Attestation Schema).
     */
    struct ASRecord {
        // A unique identifier of the Attestation Registry.
        bytes32 uuid;
        // Auto-incrementing index for reference, assigned by the registry itself.
        uint256 index;
        // Custom specification of the Attestation Registry (e.g., an ABI).
        bytes schema;
    }

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema) external returns (bytes32);

     /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IAttestationServices.sol";
import "./interfaces/IAttestationRegistry.sol";

contract AttestationRegistry is IAttestationRegistry {
    mapping(bytes32 => ASRecord) public _registry;
    bytes32 private constant EMPTY_UUID = 0;
    event Registered(
        bytes32 indexed uuid,
        uint256 indexed index,
        bytes schema,
        address attester
    );

    uint256 private _asCount;

    function register(bytes calldata schema)
        external
        override
        returns (bytes32)
    {
        uint256 index = ++_asCount;
        bytes32 uuid = _getUUID(schema);
        if (_registry[uuid].uuid != EMPTY_UUID) {
            revert("AlreadyExists");
        }

        ASRecord memory asRecord = ASRecord({
            uuid: uuid,
            index: index,
            schema: schema
        });

        _registry[uuid] = asRecord;

        emit Registered(uuid, index, schema, msg.sender);

        return uuid;
    }

    function _getUUID(bytes calldata schema) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(schema));
    }

    function getAS(bytes32 uuid)
        external
        view
        override
        returns (ASRecord memory)
    {
        return _registry[uuid];
    }
}