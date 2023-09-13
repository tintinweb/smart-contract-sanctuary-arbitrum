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