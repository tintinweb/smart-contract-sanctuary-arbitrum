// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Schema } from "./base/Schema.sol";
import { AttestationDelegation } from "./base/AttestationDelegation.sol";
import { Module } from "./base/Module.sol";
import {
    Query,
    SchemaUID,
    SchemaRecord,
    AttestationResolve,
    Attestation,
    AttestationRecord,
    ResolverUID,
    ResolverRecord,
    ModuleRecord
} from "./base/Query.sol";
import { IRegistry } from "./interface/IRegistry.sol";

/**
 * @author zeroknots
 */
contract Registry is Schema, Query, AttestationDelegation, Module {
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                            Helper Functions
    //////////////////////////////////////////////////////////////*/

    function getSchema(SchemaUID uid) public view override(Schema) returns (SchemaRecord memory) {
        return super.getSchema(uid);
    }

    function _getSchema(SchemaUID uid)
        internal
        view
        override(AttestationResolve, Schema)
        returns (SchemaRecord storage)
    {
        return super._getSchema({ schemaUID: uid });
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        override(Attestation, Query)
        returns (AttestationRecord storage)
    {
        return super._getAttestation(module, attester);
    }

    function getResolver(ResolverUID uid)
        public
        view
        virtual
        override(AttestationResolve, Module, Schema)
        returns (ResolverRecord memory)
    {
        return super.getResolver(uid);
    }

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        override(AttestationResolve, Module)
        returns (ModuleRecord storage)
    {
        return super._getModule(moduleAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AccessDenied, _time, ZERO_TIMESTAMP, ZERO_ADDRESS, InvalidResolver } from "../Common.sol";
import { ISchema, SchemaLib } from "../interface/ISchema.sol";
import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";

import { SchemaRecord, ResolverRecord, SchemaUID, ResolverUID } from "../DataTypes.sol";

/**
 * @title Schema
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 *
 */
abstract contract Schema is ISchema {
    using SchemaLib for SchemaRecord;
    using SchemaLib for ResolverRecord;

    // The global mapping between schema records and their IDs.
    mapping(SchemaUID uid => SchemaRecord schemaRecord) private _schemas;

    mapping(ResolverUID uid => ResolverRecord resolverRecord) private _resolvers;

    /**
     * @inheritdoc ISchema
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid)
    {
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        if (_schemas[uid].registeredAt != ZERO_TIMESTAMP) revert AlreadyExists();

        // Storing schema in the _schemas mapping
        _schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc ISchema
     */
    function registerResolver(IResolver _resolver) external returns (ResolverUID uid) {
        if (address(_resolver) == ZERO_ADDRESS) revert InvalidResolver();

        // build a ResolverRecord from the input
        ResolverRecord memory resolver =
            ResolverRecord({ resolver: _resolver, schemaOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolver.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(_resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        _resolvers[uid] = resolver;

        emit SchemaResolverRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc ISchema
     */
    function setResolver(ResolverUID uid, IResolver resolver) external onlySchemaOwner(uid) {
        ResolverRecord storage referrer = _resolvers[uid];
        referrer.resolver = resolver;
        emit NewSchemaResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc ISchema
     */
    function getSchema(SchemaUID uid) public view virtual returns (SchemaRecord memory) {
        return _schemas[uid];
    }

    /**
     * @dev Internal function to get a schema record
     *
     * @param schemaUID The UID of the schema.
     *
     * @return schemaRecord The schema record.
     */
    function _getSchema(SchemaUID schemaUID) internal view virtual returns (SchemaRecord storage) {
        return _schemas[schemaUID];
    }

    /**
     * @inheritdoc ISchema
     */
    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory) {
        return _resolvers[uid];
    }

    /**
     * @dev Modifier to require that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    modifier onlySchemaOwner(ResolverUID uid) {
        _onlySchemaOwner(uid);
        _;
    }

    /**
     * @dev Verifies that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    function _onlySchemaOwner(ResolverUID uid) private view {
        if (_resolvers[uid].schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IAttestation } from "../interface/IAttestation.sol";
import { Attestation } from "./Attestation.sol";
import {
    DelegatedAttestationRequest,
    MultiDelegatedAttestationRequest,
    DelegatedRevocationRequest,
    MultiDelegatedRevocationRequest,
    AttestationRequestData,
    ModuleRecord,
    ResolverUID,
    AttestationRecord,
    RevocationRequestData
} from "../DataTypes.sol";
import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    ZERO_TIMESTAMP,
    InvalidLength,
    uncheckedInc,
    InvalidSchema,
    _time
} from "../Common.sol";

/**
 * @title AttestationDelegation
 * @dev This contract provides a delegated approach to attesting and revoking attestations.
 *      The contract extends both IAttestation and Attestation.
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract AttestationDelegation is IAttestation, Attestation {
    /**
     * @dev Initializes the contract with a name and version for the attestation.
     */
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                            ATTEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest)
        external
        payable
        nonReentrant
    {
        _verifyAttest(delegatedRequest);

        AttestationRequestData calldata attestationRequestData = delegatedRequest.data;
        ModuleRecord storage moduleRecord =
            _getModule({ moduleAddress: delegatedRequest.data.subject });
        ResolverUID resolverUID = moduleRecord.resolverUID;

        (AttestationRecord memory attestationRecord, uint256 value) = _writeAttestation({
            schemaUID: delegatedRequest.schemaUID,
            resolverUID: resolverUID,
            attestationRequestData: attestationRequestData,
            attester: delegatedRequest.attester
        });

        _resolveAttestation({
            resolverUID: resolverUID,
            attestationRecord: attestationRecord,
            value: value,
            isRevocation: false,
            availableValue: msg.value,
            isLastAttestation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
        nonReentrant
    {
        uint256 length = multiDelegatedRequests.length;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiDelegatedRequests[0].data[0].subject });
        // I think it would be much better to move this into the for loop so we can iterate over the requests.
        // Its possible that the MultiAttestationRequests is attesting different modules, that thus have different resolvers
        // gas bad

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedAttestationRequest calldata multiDelegatedRequest =
                multiDelegatedRequests[i];
            AttestationRequestData[] calldata attestationRequestDatas = multiDelegatedRequest.data;
            uint256 dataLength = attestationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify signatures. Note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; j = uncheckedInc(j)) {
                _verifyAttest(
                    DelegatedAttestationRequest({
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: attestationRequestDatas[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester
                    })
                );
            }

            // Process the current batch of attestations.
            uint256 usedValue = _multiAttest({
                schemaUID: multiDelegatedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                attestationRequestDatas: attestationRequestDatas,
                attester: multiDelegatedRequest.attester,
                availableValue: availableValue,
                isLastAttestation: last
            });

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= usedValue;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              REVOKE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function revoke(DelegatedRevocationRequest calldata request) external payable nonReentrant {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.subject });

        _multiRevoke({
            schemaUID: request.schemaUID,
            resolverUID: moduleRecord.resolverUID,
            revocationRequestDatas: data,
            revoker: request.revoker,
            availableValue: msg.value,
            isLastRevocation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable
        nonReentrant
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;
        uint256 length = multiDelegatedRequests.length;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiDelegatedRequests[0].data[0].subject });

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedRevocationRequest memory multiDelegatedRequest = multiDelegatedRequests[i];
            RevocationRequestData[] memory revocationRequestDatas = multiDelegatedRequest.data;
            uint256 dataLength = revocationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; j = uncheckedInc(j)) {
                _verifyRevoke(
                    DelegatedRevocationRequest({
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: revocationRequestDatas[j],
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiDelegatedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                revocationRequestDatas: revocationRequestDatas,
                revoker: multiDelegatedRequest.revoker,
                availableValue: availableValue,
                isLastRevocation: last
            });
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/src/utils/ReentrancyGuard.sol";
import { CREATE3 } from "solady/src/utils/CREATE3.sol";

import { IModule } from "../interface/IModule.sol";
import { ISchema } from "../interface/ISchema.sol";
import { IRegistry } from "../interface/IRegistry.sol";

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { Schema } from "./Schema.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import { IResolver } from "../external/IResolver.sol";

import { InvalidResolver, _isContract, ZERO_ADDRESS } from "../Common.sol";
import {
    ResolverRecord,
    ModuleRecord,
    ResolverUID,
    AttestationRequestData,
    RevocationRequestData
} from "../DataTypes.sol";

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional metadata are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev In conclusion, the Module is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract Module is IModule, ReentrancyGuard {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;

    mapping(address moduleAddress => ModuleRecord) private _modules;

    /**
     * @inheritdoc IModule
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == ZERO_ADDRESS) revert InvalidResolver();

        (moduleAddr,,) = code.deploy(deployParams, salt, msg.value);

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
        emit ModuleDeployed(moduleAddr, salt, ResolverUID.unwrap(resolverUID));
    }

    /**
     * @inheritdoc IModule
     */
    function deployC3(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == ZERO_ADDRESS) revert InvalidResolver();
        bytes memory creationCode = abi.encodePacked(code, deployParams);
        bytes32 senderSalt = keccak256(abi.encodePacked(salt, msg.sender));
        moduleAddr = CREATE3.deploy(senderSalt, creationCode, msg.value);

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
        emit ModuleDeployed(moduleAddr, senderSalt, ResolverUID.unwrap(resolverUID));
    }

    /**
     * @inheritdoc IModule
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == ZERO_ADDRESS) revert InvalidResolver();
        (bool ok, bytes memory returnData) = factory.call{ value: msg.value }(callOnFactory);

        if (!ok) revert InvalidDeployment();
        moduleAddr = abi.decode(returnData, (address));
        if (moduleAddr == ZERO_ADDRESS) revert InvalidDeployment();
        if (_isContract(moduleAddr) != true) revert InvalidDeployment();

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
        emit ModuleDeployedExternalFactory(moduleAddr, factory, ResolverUID.unwrap(resolverUID));
    }

    /**
     * @inheritdoc IModule
     */
    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external
        nonReentrant
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == ZERO_ADDRESS) revert InvalidResolver();

        _register({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
        emit ModuleRegistration(moduleAddress, ResolverUID.unwrap(resolverUID));
    }

    /**
     * @dev Registers a module, ensuring it's not already registered.
     *  This function ensures that the module is a contract.
     *  Also ensures that moduleAddress is not ZERO_ADDRESS
     * 
     *
     * @param moduleAddress Address of the module.
     * @param sender Address of the sender registering the module.
     * @param resolver Resolver record associated with the module.
     * @param resolverUID Unique ID of the resolver.
     * @param metadata Data associated with the module.
     */
    function _register(
        address moduleAddress,
        address sender,
        ResolverRecord memory resolver,
        ResolverUID resolverUID,
        bytes calldata metadata
    )
        private
    {
        // ensure moduleAddress is not already registered
        if (_modules[moduleAddress].implementation != ZERO_ADDRESS) {
            revert AlreadyRegistered(moduleAddress);
        }
        // revert if moduleAddress is NOT a contract
        if (!_isContract(moduleAddress)) revert InvalidDeployment();

        // Store module metadata in _modules mapping
        ModuleRecord memory moduleRegistration = ModuleRecord({
            implementation: moduleAddress,
            resolverUID: resolverUID,
            sender: sender,
            metadata: metadata
        });

        _resolveRegistration({
            resolverContract: resolver.resolver,
            moduleRegistration: moduleRegistration
        });

        _modules[moduleAddress] = moduleRegistration;
    }

    /**
     * @dev Resolves the module registration using the provided resolver.
     *
     * @param resolverContract Resolver to validate the module registration.
     * @param moduleRegistration Module record to be registered.
     */
    function _resolveRegistration(
        IResolver resolverContract,
        ModuleRecord memory moduleRegistration
    )
        private
    {
        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.moduleRegistration(moduleRegistration) == false) {
            revert InvalidDeployment();
        }
    }

    /**
     * @notice Retrieves the resolver record for a given UID.
     *
     * @param uid The UID of the resolver to retrieve.
     *
     * @return The resolver record associated with the given UID.
     */
    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory);

    /**
     * @dev Retrieves the module record for a given address.
     *
     * @param moduleAddress The address of the module to retrieve.
     *
     * @return moduleRecord The module record associated with the given address.
     */
    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage)
    {
        return _modules[moduleAddress];
    }

    /**
     * @notice Retrieves the module record for a given address.
     *
     * @param moduleAddress The address of the module to retrieve.
     *
     * @return moduleRecord The module record associated with the given address.
     */

    function getModule(address moduleAddress) public view returns (ModuleRecord memory) {
        return _getModule(moduleAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IQuery } from "../interface/IQuery.sol";
import {
    AttestationRecord,
    SchemaUID,
    SchemaRecord,
    AttestationResolve,
    Attestation,
    ResolverUID,
    ResolverRecord,
    ModuleRecord
} from "./Attestation.sol";

import { AccessDenied, NotFound, ZERO_TIMESTAMP, InvalidLength, uncheckedInc } from "../Common.sol";

/**
 * @title Query
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract Query is IQuery {
    /**
     * @inheritdoc IQuery
     */
    function check(
        address module,
        address attester
    )
        public
        view
        override(IQuery)
        returns (uint256 attestedAt)
    {
        AttestationRecord storage attestation = _getAttestation(module, attester);

        uint256 expirationTime = attestation.expirationTime;
        attestedAt = expirationTime != ZERO_TIMESTAMP && expirationTime < block.timestamp
            ? ZERO_TIMESTAMP
            : attestation.time;
        if (attestedAt == ZERO_TIMESTAMP) revert AttestationNotFound();

        if (attestation.revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(attestation.attester);
        }
    }

    /**
     * @inheritdoc IQuery
     */
    function checkN(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        override(IQuery)
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            AttestationRecord storage attestation =
                _getAttestation({ moduleAddress: module, attester: attesters[i] });
            if (attestation.revocationTime != ZERO_TIMESTAMP) {
                revert RevokedAttestation(attestation.attester);
            }

            uint256 expirationTime = attestation.expirationTime;
            if (expirationTime != ZERO_TIMESTAMP && expirationTime < timeNow) {
                revert AttestationNotFound();
            }

            uint256 attestationTime = attestation.time;
            attestedAtArray[i] = attestationTime;

            if (attestationTime == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    /**
     * @inheritdoc IQuery
     */
    function checkNUnsafe(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            AttestationRecord storage attestation =
                _getAttestation({ moduleAddress: module, attester: attesters[i] });

            attestedAtArray[i] = attestation.time;

            if (attestation.revocationTime != ZERO_TIMESTAMP) continue;

            uint256 expirationTime = attestation.expirationTime;
            uint256 attestedAt = expirationTime != ZERO_TIMESTAMP && expirationTime < timeNow
                ? ZERO_TIMESTAMP
                : attestation.time;
            attestedAtArray[i] = attestedAt;
            if (attestedAt == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    /**
     * @inheritdoc IQuery
     */
    function findAttestation(
        address module,
        address attesters
    )
        public
        view
        override(IQuery)
        returns (AttestationRecord memory attestation)
    {
        attestation = _getAttestation(module, attesters);
    }

    /**
     * @inheritdoc IQuery
     */
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        override(IQuery)
        returns (AttestationRecord[] memory attestations)
    {
        uint256 attesterssLength = attesters.length;
        attestations = new AttestationRecord[](attesterssLength);
        for (uint256 i; i < attesterssLength; i = uncheckedInc(i)) {
            attestations[i] = findAttestation(module, attesters[i]);
        }
    }

    /**
     * @notice Internal function to retrieve an attestation record.
     *
     * @dev This is a virtual function and is meant to be overridden in derived contracts.
     *
     * @param moduleAddress The address of the module for which the attestation is retrieved.
     * @param attester The address of the attester whose record is being retrieved.
     *
     * @return Attestation record associated with the given module and attester.
     */

    function _getAttestation(
        address moduleAddress,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IRegistry {
    event Attested(
        address indexed subject,
        address indexed attester,
        bytes32 schema,
        address indexed dataPointer
    );
    event EIP712DomainChanged();
    event ModuleDeployed(address indexed implementation, bytes32 indexed salt, bytes32 resolver);
    event ModuleDeployedExternalFactory(
        address indexed implementation, address indexed factory, bytes32 resolver
    );
    event ModuleRegistration(address indexed implementation, bytes32 resolver);
    event NewSchemaResolver(bytes32 indexed uid, address resolver);
    event Revoked(address indexed subject, address indexed attester, bytes32 indexed schema);
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);
    event SchemaRegistered(bytes32 indexed uid, address registerer);
    event SchemaResolverRegistered(bytes32 indexed uid, address registerer);
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    struct AttestationRecord {
        bytes32 schemaUID;
        address subject;
        address attester;
        uint48 time;
        uint48 expirationTime;
        uint48 revocationTime;
        address dataPointer;
    }

    struct AttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData data;
    }

    struct AttestationRequestData {
        address subject;
        uint48 expirationTime;
        uint256 value;
        bytes data;
    }

    struct DelegatedAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData data;
        bytes signature;
        address attester;
    }

    struct DelegatedRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData data;
        bytes signature;
        address revoker;
    }

    struct ModuleRecord {
        bytes32 resolverUID;
        address implementation;
        address sender;
        bytes data;
    }

    struct MultiAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData[] data;
    }

    struct MultiDelegatedAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData[] data;
        bytes[] signatures;
        address attester;
    }

    struct MultiDelegatedRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData[] data;
        bytes[] signatures;
        address revoker;
    }

    struct MultiRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData[] data;
    }

    struct ResolverRecord {
        address resolver;
        address schemaOwner;
    }

    struct RevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData data;
    }

    struct RevocationRequestData {
        address subject;
        address attester;
        uint256 value;
    }

    struct SchemaRecord {
        uint48 registeredAt;
        address validator;
        string schema;
    }

    function attest(DelegatedAttestationRequest memory delegatedRequest) external payable;
    function attest(AttestationRequest memory request) external payable;
    function check(
        address module,
        address attester
    )
        external
        view
        returns (uint48 listedAt, uint48 revokedAt);
    function deploy(
        bytes memory code,
        bytes memory deployParams,
        bytes32 salt,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
    function deployC3(
        bytes memory code,
        bytes memory deployParams,
        bytes32 salt,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
    function deployViaFactory(
        address factory,
        bytes memory callOnFactory,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
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
    function findAttestation(
        address module,
        address attesters
    )
        external
        view
        returns (AttestationRecord memory attestation);
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);
    function getAttestTypeHash() external pure returns (bytes32);
    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUid,
        uint256 nonce
    )
        external
        view
        returns (bytes32 digest);
    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUid,
        address attester
    )
        external
        view
        returns (bytes32 digest);
    function getDomainSeparator() external view returns (bytes32);
    function getModule(address moduleAddress) external view returns (ModuleRecord memory);
    function getName() external view returns (string memory);
    function getNonce(address account) external view returns (uint256);
    function getResolver(bytes32 uid) external view returns (ResolverRecord memory);
    function getRevocationDigest(
        RevocationRequestData memory revData,
        bytes32 schemaUid,
        address revoker
    )
        external
        view
        returns (bytes32 digest);
    function getRevokeTypeHash() external pure returns (bytes32);
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
    function multiAttest(MultiDelegatedAttestationRequest[] memory multiDelegatedRequests)
        external
        payable;
    function multiAttest(MultiAttestationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiRevocationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiDelegatedRevocationRequest[] memory multiDelegatedRequests)
        external
        payable;
    function register(bytes32 resolverUID, address moduleAddress, bytes memory data) external;
    function registerResolver(address _resolver) external returns (bytes32);
    function registerSchema(string memory schema, address validator) external returns (bytes32);
    function revoke(RevocationRequest memory request) external payable;
    function setResolver(bytes32 uid, address resolver) external;
    function verify(address module, address[] memory attesters, uint256 threshold) external view;
    function verifyUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint256 constant ZERO_TIMESTAMP = 0;

address constant ZERO_ADDRESS = address(0);

error AccessDenied();
error InvalidSchema();
error InvalidResolver();
error InvalidLength();
error InvalidSignature();
error NotFound();

/**
 * @dev A helper function to work with unchecked iterators in loops.
 * @param i The current index.
 *
 * @return j The next index.
 */
function uncheckedInc(uint256 i) pure returns (uint256 j) {
    unchecked {
        j = i + 1;
    }
}

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
 * current block time.
 */
function _time() view returns (uint48) {
    return uint48(block.timestamp);
}

/**
 * @dev Returns whether an address is a contract.
 * @param account The address to check.
 *
 * @return true if `account` is a contract, false otherwise.
 */
function _isContract(address account) view returns (bool) {
    uint256 size;
    assembly {
        size := extcodesize(account)
    }
    return size > 0;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import { SchemaUID, SchemaRecord, ResolverUID, ResolverRecord } from "../DataTypes.sol";
import { IRegistry } from "./IRegistry.sol";

/**
 * @title The global schema interface.
 */
interface ISchema {
    // Error to throw if the SchemaID already exists
    error AlreadyExists();

    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */
    event SchemaRegistered(SchemaUID indexed uid, address registerer);

    event SchemaResolverRegistered(ResolverUID indexed uid, address registerer);

    /**
     * @dev Emitted when a new schema resolver
     *
     * @param uid The schema UID.
     * @param resolver The address of the resolver.
     */
    event NewSchemaResolver(ResolverUID indexed uid, address resolver);

    /**
     * @notice Registers a new schema.
     *
     * @dev Ensures that the schema does not already exist and calculates a unique ID for it.
     *
     * @param schema The schema as a string representation.
     * @param validator OPTIONAL Contract address that validates this schema.
     *     If not provided, all attestations made against this schema is assumed to be valid.
     *
     * @return uid The unique ID of the registered schema.
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator validator
    )
        external
        returns (SchemaUID);

    /**
     * @notice Registers a resolver and associates it with the caller.
     * @dev This function allows the registration of a resolver by computing a unique ID and associating it with the owner.
     *      Emits a SchemaResolverRegistered event upon successful registration.
     *
     * @param _resolver Address of the IResolver to be registered.
     *
     * @return uid The unique ID (ResolverUID) associated with the registered resolver.
     */

    function registerResolver(IResolver _resolver) external returns (ResolverUID);

    /**
     * @notice Updates the resolver for a given UID.
     *
     * @dev Can only be called by the owner of the schema.
     *
     * @param uid The UID of the schema to update.
     * @param resolver The new resolver interface.
     */
    function setResolver(ResolverUID uid, IResolver resolver) external;

    /**
     * @notice Retrieves the schema record for a given UID.
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema record associated with the given UID.
     */
    function getSchema(SchemaUID uid) external view returns (SchemaRecord memory);

    /**
     * @notice Retrieves the resolver record for a given UID.
     *
     * @param uid The UID of the resolver to retrieve.
     *
     * @return The resolver record associated with the given UID.
     */
    function getResolver(ResolverUID uid) external view returns (ResolverRecord memory);
}

library SchemaLib {
    /**
     * @dev Calculates a UID for a given schema.
     *
     * @param schemaRecord The input schema.
     *
     * @return schema UID.
     */
    function getUID(SchemaRecord memory schemaRecord) internal pure returns (SchemaUID) {
        return SchemaUID.wrap(
            keccak256(abi.encodePacked(schemaRecord.schema, address(schemaRecord.validator)))
        );
    }

    /**
     * @dev Calculates a UID for a given resolver.
     *
     * @param resolver The input schema.
     *
     * @return ResolverUID.
     */
    function getUID(ResolverRecord memory resolver) internal pure returns (ResolverUID) {
        return ResolverUID.wrap(keccak256(abi.encodePacked(resolver.resolver)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, ModuleRecord } from "../DataTypes.sol";
import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 * @title The interface of an optional schema resolver.
 * @dev The resolver is responsible for validating the schema and attestation data.
 * @dev The resolver is also responsible for processing the attestation and revocation requests.
 *
 */
interface IResolver is IERC165 {
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
    function attest(AttestationRecord calldata attestation) external payable returns (bool);

    /**
     * @dev Processes a Module Registration
     *
     * @param module Module registration artefact
     *
     * @return Whether the registration is valid
     */
    function moduleRegistration(ModuleRecord calldata module) external payable returns (bool);

    /**
     * @dev Processes multiple attestations and verifies whether they are valid.
     *
     * @param attestations The new attestations.
     * @param values Explicit ETH amounts which were sent with each attestation.
     *
     * @return Whether all the attestations are valid.
     */
    function multiAttest(
        AttestationRecord[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function revoke(AttestationRecord calldata attestation) external payable returns (bool);

    /**
     * @dev Processes revocation of multiple attestation and verifies they can be revoked.
     *
     * @param attestations The existing attestations to be revoked.
     * @param values Explicit ETH amounts which were sent with each revocation.
     *
     * @return Whether the attestations can be revoked.
     */
    function multiRevoke(
        AttestationRecord[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRequestData, ModuleRecord } from "../DataTypes.sol";
import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaValidator is IERC165 {
    /**
     * @notice Validates an attestation request.
     */
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool);

    /**
     * @notice Validates an array of attestation requests.
     */
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ISchemaValidator } from "./external/ISchemaValidator.sol";
import { IResolver } from "./external/IResolver.sol";

import { SSTORE2 } from "solady/src/utils/SSTORE2.sol";

/*//////////////////////////////////////////////////////////////
                          STORAGE 
//////////////////////////////////////////////////////////////*/

// Struct that represents an attestation.
struct AttestationRecord {
    SchemaUID schemaUID; // The unique identifier of the schema.
    address subject; // The implementation address of the module that is being attested.
    address attester; // The attesting account.
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    AttestationDataRef dataPointer; // SSTORE2 pointer to the attestation data.
}

// Struct that represents Module artefact.
struct ModuleRecord {
    ResolverUID resolverUID; // The unique identifier of the resolver.
    address implementation; // The deployed contract address
    address sender; // The address of the sender who deployed the contract
    bytes metadata; // Additional data related to the contract deployment
}

struct SchemaRecord {
    uint48 registeredAt; // The time when the schema was registered (Unix timestamp).
    ISchemaValidator validator; // Optional external schema validator.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

struct ResolverRecord {
    IResolver resolver; // Optional schema resolver.
    address schemaOwner; // The address of the account used to register the schema.
}

/*//////////////////////////////////////////////////////////////
                          Attestation Requests
//////////////////////////////////////////////////////////////*/

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address subject; // The subject of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
    bytes data; // Custom attestation data.
}

/**
 * @dev A struct representing the full arguments of the attestation request.
 */
struct AttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    address attester; // The attesting account.
    bytes signature; // The signature data.
}

/**
 * @dev A struct representing the full arguments of the multi attestation request.
 */
struct MultiAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    bytes[] signatures; // The signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
}

/*//////////////////////////////////////////////////////////////
                          Revocation Requests
//////////////////////////////////////////////////////////////*/

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequestData {
    address subject; // The module address.
    address attester; // The attesting account.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the revocation request.
 */
struct RevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    address revoker; // The revoking account.
    bytes signature; // The signature data.
}

/**
 * @dev A struct representing the full arguments of the multi revocation request.
 */
struct MultiRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    address revoker; // The revoking account.
    bytes[] signatures; // The signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
}

/*//////////////////////////////////////////////////////////////
                          CUSTOM TYPES
//////////////////////////////////////////////////////////////*/

//---------------------- SchemaUID ------------------------------|
type SchemaUID is bytes32;

using { schemaEq as == } for SchemaUID global;
using { schemaNotEq as != } for SchemaUID global;

function schemaEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) == SchemaUID.unwrap(uid);
}

function schemaNotEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) != SchemaUID.unwrap(uid);
}

//--------------------- ResolverUID -----------------------------|
type ResolverUID is bytes32;

using { resolverEq as == } for ResolverUID global;
using { resolverNotEq as != } for ResolverUID global;

function resolverEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) == ResolverUID.unwrap(uid2);
}

function resolverNotEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) != ResolverUID.unwrap(uid2);
}

type AttestationDataRef is address;

function readAttestationData(AttestationDataRef dataPointer) view returns (bytes memory data) {
    data = SSTORE2.read(AttestationDataRef.unwrap(dataPointer));
}

function writeAttestationData(
    bytes memory attestationData,
    bytes32 salt
)
    returns (AttestationDataRef dataPointer)
{
    /**
     * @dev We are using CREATE2 to deterministically generate the address of the attestation data.
     * Checking if an attestation pointer already exists, would cost more GAS in the average case.
     */
    dataPointer = AttestationDataRef.wrap(SSTORE2.writeDeterministic(attestationData, salt));
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    SchemaUID,
    AttestationDataRef,
    AttestationRequest,
    AttestationRecord,
    SchemaRecord,
    MultiAttestationRequest,
    ResolverRecord,
    ModuleRecord,
    IResolver,
    DelegatedAttestationRequest,
    MultiDelegatedAttestationRequest,
    RevocationRequest,
    ResolverUID,
    DelegatedRevocationRequest,
    MultiDelegatedRevocationRequest,
    MultiRevocationRequest
} from "../DataTypes.sol";
import { IRegistry } from "./IRegistry.sol";

/**
 * @dev The global attestation interface.
 */
interface IAttestation {
    error AlreadyRevoked();
    error AlreadyRevokedOffchain();
    error AlreadyTimestamped();
    error InsufficientValue();
    error InvalidAttestation();
    error InvalidAttestationRefUID(bytes32 missingRefUID);
    error IncompatibleAttestation(bytes32 sourceCodeHash, bytes32 targetCodeHash);
    error InvalidAttestations();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidRevocation();
    error InvalidRevocations();
    error InvalidVerifier();
    error NotPayable();
    error WrongSchema();
    error InvalidSender(address moduleAddr, address sender);

    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param subject The subject of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     */
    event Attested(
        address indexed subject,
        address indexed attester,
        SchemaUID schema,
        AttestationDataRef indexed dataPointer
    );

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param subject The subject of the attestation.
     * @param  revoker The attesting account.
     * @param schema The UID of the schema.
     */
    event Revoked(address indexed subject, address indexed revoker, SchemaUID indexed schema);

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
     * @notice Creates an attestation for a specified schema.
     *
     * @param request The attestation request.
     */

    function attest(AttestationRequest calldata request) external payable;

    /**
     * @notice Creates multiple attestations for multiple schemas.
     * @dev Although the registry supports batched attestations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiRequests An array of multi attestation requests.
     */
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable;

    /**
     * @notice Handles a single delegated attestation request
     *
     * @dev The function verifies the attestation, wraps the data in an array and forwards it to the _multiAttest() function
     *
     * @param delegatedRequest A delegated attestation request
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest) external payable;

    /**
     * @notice Function to handle multiple delegated attestation requests
     *
     * @dev It iterates over the attestation requests and processes them. It collects the returned UIDs into a list.
     * @dev Although the registry supports batched attestations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiDelegatedRequests An array of multiple delegated attestation requests
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable;

    /**
     * @notice Revokes an existing attestation for a specified schema.
     *
     * @param request The revocation request.
     */
    function revoke(RevocationRequest calldata request) external payable;
    /**
     * @notice Handles a single delegated revocation request
     *
     * @dev The function verifies the revocation, prepares data for the _multiRevoke() function and revokes the requestZ
     *
     * @param request A delegated revocation request
     */
    function revoke(DelegatedRevocationRequest calldata request) external payable;

    /**
     * @notice Handles multiple delegated revocation requests
     *
     * @dev The function iterates over the multiDelegatedRequests array, verifies each revocation and revokes the request
     * @dev Although the registry supports batched revocations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiDelegatedRequests An array of multiple delegated revocation requests
     */
    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable;

    /**
     * @notice Revokes multiple existing attestations for multiple schemas.
     * @dev Although the registry supports batched revocations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     * @param multiRequests An array of multi revocation requests.
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable;
}

/**
 * @dev Library for attestation related functions.
 */
library AttestationLib {
    /**
     * @dev Generates a unique salt for an attestation using the provided attester and module addresses.
     * The salt is generated using a keccak256 hash of the module address, attester address, current timestamp, and chain ID.
     *   This salt will be used for SSTORE2
     *
     * @param attester Address of the entity making the attestation.
     * @param module Address of the module being attested to.
     *
     * @return dataPointerSalt A unique salt for the attestation data storage.
     */
    function attestationSalt(
        address attester,
        address module
    )
        internal
        returns (bytes32 dataPointerSalt)
    {
        dataPointerSalt =
            keccak256(abi.encodePacked(module, attester, block.timestamp, block.chainid));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/src/utils/ReentrancyGuard.sol";

import { EIP712Verifier } from "./EIP712Verifier.sol";
import {
    IAttestation,
    AttestationRecord,
    AttestationRequest,
    MultiAttestationRequest,
    RevocationRequest,
    MultiRevocationRequest,
    AttestationLib,
    ResolverRecord,
    MultiDelegatedAttestationRequest
} from "../interface/IAttestation.sol";
import { SchemaUID, ResolverUID, SchemaRecord, ISchemaValidator } from "./Schema.sol";
import { ModuleRecord, AttestationRequestData, RevocationRequestData } from "./Module.sol";
import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    ZERO_TIMESTAMP,
    InvalidLength,
    uncheckedInc,
    InvalidSchema,
    _time
} from "../Common.sol";

import { AttestationDataRef, writeAttestationData, readAttestationData } from "../DataTypes.sol";
import { AttestationResolve } from "./AttestationResolve.sol";

/**
 * @title Attestation
 * @dev Manages attestations and revocations for modules.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract Attestation is IAttestation, AttestationResolve, ReentrancyGuard {
    using ModuleDeploymentLib for address;

    // Mapping of module addresses to attester addresses to their attestation records.
    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    /**
     * @notice Constructs a new Attestation contract instance.
     */
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                              ATTEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function attest(AttestationRequest calldata request) external payable nonReentrant {
        AttestationRequestData calldata requestData = request.data;

        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: request.data.subject });
        ResolverUID resolverUID = moduleRecord.resolverUID;

        // write attestations to registry storge
        (AttestationRecord memory attestationRecord, uint256 value) = _writeAttestation({
            schemaUID: request.schemaUID,
            resolverUID: resolverUID,
            attestationRequestData: requestData,
            attester: msg.sender
        });

        // trigger the resolver procedure
        _resolveAttestation({
            resolverUID: resolverUID,
            attestationRecord: attestationRecord,
            value: value,
            isRevocation: false,
            availableValue: msg.value,
            isLastAttestation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiAttest(MultiAttestationRequest[] calldata multiRequests)
        external
        payable
        nonReentrant
    {
        uint256 length = multiRequests.length;
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord storage moduleRecord =
            _getModule({ moduleAddress: multiRequests[0].data[0].subject });

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            // Process the current batch of attestations.
            MultiAttestationRequest calldata multiRequest = multiRequests[i];
            uint256 usedValue = _multiAttest({
                schemaUID: multiRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                attestationRequestDatas: multiRequest.data,
                attester: msg.sender,
                availableValue: availableValue,
                isLastAttestation: last
            });

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= usedValue;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              REVOKE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function revoke(RevocationRequest calldata request) external payable nonReentrant {
        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.subject });

        AttestationRecord memory attestationRecord =
            _revoke({ schemaUID: request.schemaUID, request: request.data, revoker: msg.sender });

        _resolveAttestation({
            resolverUID: moduleRecord.resolverUID,
            attestationRecord: attestationRecord,
            value: 0,
            isRevocation: true,
            availableValue: msg.value,
            isLastAttestation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests)
        external
        payable
        nonReentrant
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiRequests[0].data[0].subject });
        uint256 requestsLength = multiRequests.length;

        // should cache length
        for (uint256 i; i < requestsLength; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool isLastRevocation;
            unchecked {
                isLastRevocation = i == requestsLength - 1;
            }

            MultiRevocationRequest calldata multiRequest = multiRequests[i];

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                revocationRequestDatas: multiRequest.data,
                revoker: msg.sender,
                availableValue: availableValue,
                isLastRevocation: isLastRevocation
            });
        }
    }

    /**
     * @dev Attests to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema to attest to.
     * @param resolverUID The unique identifier of the resolver.
     * @param attestationRequestDatas The attestation data.
     * @param attester The attester's address.
     * @param availableValue Amount of ETH available for the operation.
     * @param isLastAttestation Indicates if this is the last batch.
     *
     * @return usedValue Amount of ETH used.
     */
    function _multiAttest(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData[] calldata attestationRequestDatas,
        address attester,
        uint256 availableValue,
        bool isLastAttestation
    )
        internal
        returns (uint256 usedValue)
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS) {
            // revert if ISchemaValidator returns false
            if (!schema.validator.validateSchema(attestationRequestDatas)) {
                revert InvalidAttestation();
            }
        }

        // caching length
        uint256 length = attestationRequestDatas.length;
        // caching current time as it will be used in the for loop

        // for loop will run and save the return values in these two arrays
        AttestationRecord[] memory attestationRecords = new AttestationRecord[](
            length
        );

        // msg.values used for resolver
        uint256[] memory values = new uint256[](length);

        // write every attesatation provided to registry's storage
        for (uint256 i; i < length; i = uncheckedInc(i)) {
            (attestationRecords[i], values[i]) = _writeAttestation({
                schemaUID: schemaUID,
                resolverUID: resolverUID,
                attestationRequestData: attestationRequestDatas[i],
                attester: attester
            });
        }

        // trigger the resolver procedure
        usedValue = _resolveAttestations({
            resolverUID: resolverUID,
            attestationRecords: attestationRecords,
            values: values,
            isRevocation: false,
            availableValue: availableValue,
            isLast: isLastAttestation
        });
    }

    /**
     * Writes an attestation record to storage and emits an event.
     *
     * @dev the bytes metadata provided in the AttestationRequestData
     * is writted to the EVM with SSTORE2 to allow for large attestations without spending a lot of gas
     *
     * @param schemaUID The unique identifier of the schema being attested to.
     * @param resolverUID The unique identifier of the resolver for the module.
     * @param attestationRequestData The data for the attestation request.
     * @param attester The address of the entity making the attestation.
     *
     * @return attestationRecord The written attestation record.
     * @return value The value associated with the attestation request.
     */
    function _writeAttestation(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData calldata attestationRequestData,
        address attester
    )
        internal
        returns (AttestationRecord memory attestationRecord, uint256 value)
    {
        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (
            attestationRequestData.expirationTime != ZERO_TIMESTAMP
                && attestationRequestData.expirationTime <= timeNow
        ) {
            revert InvalidExpirationTime();
        }
        // caching module address. gas bad
        address module = attestationRequestData.subject;
        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: module });

        // Ensure that attestation is for module that was registered.
        if (moduleRecord.implementation == ZERO_ADDRESS) {
            revert InvalidAttestation();
        }

        // Ensure that attestation for a module is using the modules resolver
        if (moduleRecord.resolverUID != resolverUID) {
            revert InvalidAttestation();
        }

        // get salt used for SSTORE2 to avoid collisions during CREATE2
        bytes32 attestationSalt = AttestationLib.attestationSalt(attester, module);
        AttestationDataRef sstore2Pointer = writeAttestationData({
            attestationData: attestationRequestData.data,
            salt: attestationSalt
        });

        // write attestationdata with SSTORE2 to EVM, and prepare return value
        attestationRecord = AttestationRecord({
            schemaUID: schemaUID,
            subject: module,
            attester: attester,
            time: timeNow,
            expirationTime: attestationRequestData.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            dataPointer: sstore2Pointer
        });

        value = attestationRequestData.value;

        // SSTORE attestation on registry storage
        _moduleToAttesterToAttestations[module][attester] = attestationRecord;
        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _revoke(
        SchemaUID schemaUID,
        RevocationRequestData memory request,
        address revoker
    )
        internal
        returns (AttestationRecord memory)
    {
        AttestationRecord storage attestation =
            _moduleToAttesterToAttestations[request.subject][request.attester];

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (AttestationDataRef.unwrap(attestation.dataPointer) == ZERO_ADDRESS) {
            revert NotFound();
        }

        // Ensure that a wrong schema ID wasn't passed by accident.
        if (attestation.schemaUID != schemaUID) {
            revert InvalidSchema();
        }

        // Allow only original attesters to revoke their attestations.
        if (attestation.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (attestation.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        attestation.revocationTime = _time();
        emit Revoked({
            subject: attestation.subject,
            revoker: revoker,
            schema: attestation.schemaUID
        });
        return attestation;
    }

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema that was used to attest.
     * @param revocationRequestDatas The arguments of the revocation requests.
     * @param revoker The revoking account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param isLastRevocation Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _multiRevoke(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        RevocationRequestData[] memory revocationRequestDatas,
        address revoker,
        uint256 availableValue,
        bool isLastRevocation
    )
        internal
        returns (uint256)
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();

        // caching length
        uint256 length = revocationRequestDatas.length;
        AttestationRecord[] memory attestationRecords = new AttestationRecord[](
            length
        );
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory revocationRequests = revocationRequestDatas[i];

            attestationRecords[i] =
                _revoke({ schemaUID: schemaUID, request: revocationRequests, revoker: revoker });
            values[i] = revocationRequests.value;
        }

        return _resolveAttestations({
            resolverUID: resolverUID,
            attestationRecords: attestationRecords,
            values: values,
            isRevocation: true,
            availableValue: availableValue,
            isLast: isLastRevocation
        });
    }

    /**
     * @dev Returns the attestation record for a specific module and attester.
     *
     * @param module The module address.
     * @param attester The attester address.
     *
     * @return attestationRecord The attestation record.
     */
    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage)
    {
        return _moduleToAttesterToAttestations[module][attester];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/CREATE3.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the contract.
    error DeploymentFailed();

    /// @dev Unable to initialize the contract.
    error InitializationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BYTECODE CONSTANTS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * -------------------------------------------------------------------+
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 36          | CALLDATASIZE     | cds          |                    |
     * 3d          | RETURNDATASIZE   | 0 cds        |                    |
     * 3d          | RETURNDATASIZE   | 0 0 cds      |                    |
     * 37          | CALLDATACOPY     |              | [0..cds): calldata |
     * 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
     * 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
     * 34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
     * f0          | CREATE           | newContract  | [0..cds): calldata |
     * -------------------------------------------------------------------|
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
     * 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
     * 52          | MSTORE           |              | [0..8): bytecode   |
     * 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
     * 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
     * f3          | RETURN           |              | [0..8): bytecode   |
     * -------------------------------------------------------------------+
     */

    /// @dev The proxy bytecode.
    uint256 private constant _PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

    /// @dev Hash of the `_PROXY_BYTECODE`.
    /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
    bytes32 private constant _PROXY_BYTECODE_HASH =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      CREATE3 OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys `creationCode` deterministically with a `salt`.
    /// The deployed contract is funded with `value` (in wei) ETH.
    /// Returns the deterministic address of the deployed contract,
    /// which solely depends on `salt`.
    function deploy(bytes32 salt, bytes memory creationCode, uint256 value)
        internal
        returns (address deployed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the `_PROXY_BYTECODE` into scratch space.
            mstore(0x00, _PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x14, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the deterministic address for `salt`.
    function getDeployed(bytes32 salt) internal view returns (address deployed) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverUID } from "../DataTypes.sol";

/**
 * Module interface allows for the deployment and registering of modules.
 *
 * @author zeroknots
 */
interface IModule {
    // Event triggered when a module is deployed.
    event ModuleRegistration(address indexed implementation, bytes32 resolver);
    event ModuleDeployed(address indexed implementation, bytes32 indexed salt, bytes32 resolver);
    event ModuleDeployedExternalFactory(
        address indexed implementation, address indexed factory, bytes32 resolver
    );

    error AlreadyRegistered(address module);
    error InvalidDeployment();

    /**
     * @notice Deploys a new module.
     *
     * @dev Ensures the resolver is valid and then deploys the module.
     *
     * @param code The bytecode for the module.
     * @param deployParams Parameters required for deployment.
     * @param salt Salt for creating the address.
     * @param metadata Data associated with the module.
     *          Entities can use this to store additional information about the module.
     *          This metadata will be forwarded to the resolver.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Deploys a new module using the CREATE3 method.
     *
     * @dev Similar to the deploy function but uses CREATE3 for deployment.
     * @dev the salt supplied here will be hashed again with msg.sender
     *
     * @param code The bytecode for the module.
     * @param deployParams Parameters required for deployment.
     * @param salt Initial salt for creating the final salt.
     * @param metadata Data associated with the module.
     *          Entities can use this to store additional information about the module.
     *          This metadata will be forwarded to the resolver.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deployC3(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Deploys a new module via an external factory contract.
     *
     * @param factory Address of the factory contract.
     * @param callOnFactory Encoded call to be made on the factory contract.
     * @param metadata Data associated with the module.
     *          Entities can use this to store additional information about the module.
     *          This metadata will be forwarded to the resolver.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Registers an existing module with the contract.
     * @dev since anyone can register an existing module,
     *      the 'sender' attribute in ModuleRecord will be address(0)
     *
     * @param resolverUID Unique ID of the resolver.
     * @param moduleAddress Address of the module.
     * @param metadata Data associated with the module.
     *          Entities can use this to store additional information about the module.
     *          This metadata will be forwarded to the resolver.
     */
    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
 * @title ModuleDeploymentLib
 * @dev A library that can be used to deploy the Registry
 * @author zeroknots
 */
library ModuleDeploymentLib {
    /**
     * @dev Gets the code hash of a contract at a given address.
     *
     * @param contractAddr The address of the contract.
     *
     * @return hash The hash of the contract code.
     */
    function codeHash(address contractAddr) internal view returns (bytes32 hash) {
        assembly {
            if iszero(extcodesize(contractAddr)) { revert(0, 0) }
            hash := extcodehash(contractAddr)
        }
    }

    /**
     * @notice Creates a new contract using CREATE2 opcode.
     * @dev This method uses the CREATE2 opcode to deploy a new contract with a deterministic address.
     *
     * @param createCode The creationCode for the contract.
     * @param params The parameters for creating the contract. If the contract has a constructor, this MUST be provided. Function will fail if params are abi.encodePacked in createCode.
     * @param salt The salt for creating the contract.
     *
     * @return moduleAddress The address of the deployed contract.
     * @return initCodeHash packed (creationCode, constructor params)
     * @return contractCodeHash hash of deployed bytecode
     */
    function deploy(
        bytes memory createCode,
        bytes memory params,
        bytes32 salt,
        uint256 value
    )
        internal
        returns (address moduleAddress, bytes32 initCodeHash, bytes32 contractCodeHash)
    {
        bytes memory initCode = abi.encodePacked(createCode, params);
        // this enforces, that constructor params were supplied via params argument
        // if params were abi.encodePacked in createCode, this will revert
        initCodeHash = keccak256(initCode);

        assembly {
            moduleAddress := create2(value, add(initCode, 0x20), mload(initCode), salt)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
            contractCodeHash := extcodehash(moduleAddress)
        }
    }

    /**
     * @notice Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.
     * @dev The calculated address is based on the contract's code, a salt, and the address of the current contract.
     * @dev This function uses the formula specified in EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014).
     *
     * @param _code The contract code that would be deployed.
     * @param _salt A salt used for the address calculation. This must be the same salt that would be passed to the CREATE2 opcode.
     *
     * @return The address that the contract would be deployed at if the CREATE2 opcode was called with the specified _code and _salt.
     */
    function calcAddress(bytes memory _code, bytes32 _salt) internal view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_code)));
        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    error InvalidDeployment();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord } from "../DataTypes.sol";
import { IERC7484 } from "./IERC7484.sol";

/**
 * Query interface allows for the verification of attestations
 * with potential for reversion in case of invalid attestation.
 *
 * @author zeroknots
 */
interface IQuery is IERC7484 {
    error RevokedAttestation(address attester);
    error AttestationNotFound();
    error InsufficientAttestations();

    /**
     * @notice Queries the attestation status of a specific attester for a given module.
     *
     * @dev If an attestation is not found or is revoked, the function will revert.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester whose status is being queried.
     *
     * @return attestedAt The time the attestation was listed. Returns 0 if not listed or expired.
     */
    function check(address module, address attester) external view returns (uint256 attestedAt);

    /**
     * @notice Verifies the validity of attestations for a given module against a threshold.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Will also revert if any of the attestations have been revoked (even if threshold is met).
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     *
     * @return attestedAtArray The list of attestation times associated with the given module and attesters.
     */
    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);

    /**
     * @notice Verifies attestations for a given module against a threshold, but does not check revocation.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Does not revert on revoked attestations but treats them the same as non-existent attestations.
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     */
    function checkNUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);

    /**
     * @notice Retrieves the attestation record for a given module and attester.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester whose record is being retrieved.
     *
     * @return attestation The attestation record associated with the given module and attester.
     */
    function findAttestation(
        address module,
        address attester
    )
        external
        view
        returns (AttestationRecord memory attestation);

    /**
     * Find an attestations associated with a given module and attester.
     *
     * @notice Retrieves attestation records for a given module and a list of attesters.
     *
     * @param module The address of the module being queried.
     * @param attesters The list of attesters whose records are being retrieved.
     *
     * @return attestations The list of attestation records associated with the given module and attesters.
     */
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 dataSize | PUSH2 dataSize  | dataSize                |                     |
             * 80          | DUP1            | dataSize dataSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa dataSize dataSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa dataSize dataSize |                     |
             * 39          | CODECOPY        | dataSize                | [0..dataSize): code |
             * 3D          | RETURNDATASIZE  | 0 dataSize              | [0..dataSize): code |
             * F3          | RETURN          |                         | [0..dataSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(dataSize, 0xffff)),
                // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its deterministic address.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(
                // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(dataSize, 0xffff)),
                // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
            )

            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(dataSize, 0xa), salt)

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), shr(16, dataSize))

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            hash := keccak256(add(data, 0x15), add(dataSize, 0xa))

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { EIP712 } from "solady/src/utils/EIP712.sol";

import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";

import { InvalidSignature } from "../Common.sol";
import {
    AttestationRequestData,
    SchemaUID,
    DelegatedAttestationRequest,
    RevocationRequestData,
    DelegatedRevocationRequest
} from "../DataTypes.sol";

/**
 * @title Singature Verifier. If provided signed is a contract, this function will fallback to ERC1271
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract EIP712Verifier is EIP712 {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 private constant ATTEST_TYPEHASH =
        keccak256("AttestationRequestData(address,uint48,uint256,bytes)");

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 private constant REVOKE_TYPEHASH =
        keccak256("RevocationRequestData(address,address,uint256)");

    // Replay protection nonces.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Creates a new EIP712Verifier instance.
     */
    constructor() { }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Registry";
        version = "0.2";
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signatures for attest, and revoke.
     */
    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparator();
    }

    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested account.
     *
     * @return The current nonce.
     */
    function getNonce(address account) public view returns (uint256) {
        return _nonces[account];
    }

    /**
     * Returns the EIP712 type hash for the attest function.
     */
    function getAttestTypeHash() public pure returns (bytes32) {
        return ATTEST_TYPEHASH;
    }

    /**
     * Returns the EIP712 type hash for the revoke function.
     */
    function getRevokeTypeHash() public pure returns (bytes32) {
        return REVOKE_TYPEHASH;
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param attData The data in the attestation request.
     * @param schemaUid The UID of the schema.
     * @param nonce The nonce of the attestation request.
     *
     * @return digest The attestation digest.
     */
    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUid,
        uint256 nonce
    )
        public
        view
        returns (bytes32 digest)
    {
        digest = _attestationDigest(attData, schemaUid, nonce);
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param attData The data in the attestation request.
     * @param schemaUid The UID of the schema.
     * @param attester The address of the attester.
     *
     * @return digest The attestation digest.
     */
    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUid,
        address attester
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(attester) + 1;
        digest = _attestationDigest(attData, schemaUid, nonce);
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param data The data in the attestation request.
     * @param schemaUid The UID of the schema.
     * @param nonce  The nonce of the attestation request.
     *
     * @return digest The attestation digest.
     */
    function _attestationDigest(
        AttestationRequestData memory data,
        SchemaUID schemaUid,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(
            keccak256(
                abi.encode(
                    ATTEST_TYPEHASH,
                    block.chainid,
                    schemaUid,
                    data.subject,
                    data.expirationTime,
                    keccak256(data.data),
                    nonce
                )
            )
        );
    }

    /**
     * @dev Verifies delegated attestation request.
     *
     * @param request The arguments of the delegated attestation request.
     */
    function _verifyAttest(DelegatedAttestationRequest memory request) internal {
        AttestationRequestData memory data = request.data;

        uint256 nonce = _newNonce(request.attester);
        bytes32 digest = _attestationDigest(data, request.schemaUID, nonce);
        bool valid =
            SignatureCheckerLib.isValidSignatureNow(request.attester, digest, request.signature);
        if (!valid) revert InvalidSignature();
    }

    /**
     * @dev Gets a new sequential nonce
     *
     * @param account The requested account.
     *
     * @return nonce The new nonce.
     */
    function _newNonce(address account) private returns (uint256 nonce) {
        unchecked {
            nonce = ++_nonces[account];
        }
    }

    /**
     * @dev Gets the revocation digest
     * @param revData The data in the revocation request.
     * @param schemaUid The UID of the schema.
     * @param revoker  The address of the revoker.
     *
     * @return digest The revocation digest.
     */
    function getRevocationDigest(
        RevocationRequestData memory revData,
        SchemaUID schemaUid,
        address revoker
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(revoker) + 1;
        digest = _revocationDigest(schemaUid, revData.subject, revData.attester, nonce);
    }

    /**
     * @dev Gets the revocation digest
     * @param schemaUid The UID of the schema.
     * @param subject The address of the subject.
     * @param nonce  The nonce of the attestation request.
     *
     * @return digest The revocation digest.
     */
    function _revocationDigest(
        SchemaUID schemaUid,
        address subject,
        address attester,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(
            keccak256(
                abi.encode(REVOKE_TYPEHASH, block.chainid, schemaUid, subject, attester, nonce)
            )
        );
    }

    /**
     * @dev Verifies delegated revocation request.
     *
     * @param request The arguments of the delegated revocation request.
     */
    function _verifyRevoke(DelegatedRevocationRequest memory request) internal {
        RevocationRequestData memory data = request.data;

        uint256 nonce = _newNonce(request.revoker);
        bytes32 digest = _revocationDigest(request.schemaUID, data.subject, data.attester, nonce);
        bool valid =
            SignatureCheckerLib.isValidSignatureNow(request.revoker, digest, request.signature);
        if (!valid) revert InvalidSignature();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import {
    IAttestation,
    ResolverUID,
    AttestationRecord,
    SchemaUID,
    SchemaRecord,
    ModuleRecord,
    ResolverRecord,
    IResolver
} from "../interface/IAttestation.sol";
import { EIP712Verifier } from "./EIP712Verifier.sol";

import { ZERO_ADDRESS, AccessDenied, uncheckedInc } from "../Common.sol";
import { AttestationDataRef, writeAttestationData, readAttestationData } from "../DataTypes.sol";

/**
 * @title AttestationResolve
 * @dev This contract provides functions to resolve non-delegated attestations and revocations.
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract AttestationResolve is IAttestation, EIP712Verifier {
    using Address for address payable;

    /**
     * @dev Resolves a new attestation or a revocation of an existing attestation.
     *
     * @param resolverUID The schema of the attestation.
     * @param attestationRecord The data of the attestation to make/revoke.
     * @param value An explicit ETH amount to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param isLastAttestation Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestation(
        ResolverUID resolverUID,
        AttestationRecord memory attestationRecord,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool isLastAttestation
    )
        internal
        returns (uint256)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        IResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) {
            // Ensure that we don't accept payments if there is no resolver.
            if (value != 0) revert NotPayable();

            return 0;
        }

        // Ensure that we don't accept payments which can't be forwarded to the resolver.
        if (value != 0 && !resolverContract.isPayable()) {
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

        // Resolve a revocation with external IResolver
        if (isRevocation) {
            if (!resolverContract.revoke{ value: value }(attestationRecord)) {
                revert InvalidRevocation();
            }
            // Resolve an attestation with external IResolver
        } else if (!resolverContract.attest{ value: value }(attestationRecord)) {
            revert InvalidAttestation();
        }

        if (isLastAttestation) {
            _refund(availableValue);
        }

        return value;
    }

    /**
     * @dev Resolves multiple attestations or revocations of existing attestations.
     *
     * @param resolverUID THe bytes32 uid of the resolver
     * @param attestationRecords The data of the attestations to make/revoke.
     * @param values Explicit ETH amounts to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param isLast Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestations(
        ResolverUID resolverUID,
        AttestationRecord[] memory attestationRecords,
        uint256[] memory values,
        bool isRevocation,
        uint256 availableValue,
        bool isLast
    )
        internal
        returns (uint256)
    {
        uint256 length = attestationRecords.length;
        if (length == 1) {
            return _resolveAttestation({
                resolverUID: resolverUID,
                attestationRecord: attestationRecords[0],
                value: values[0],
                isRevocation: isRevocation,
                availableValue: availableValue,
                isLastAttestation: isLast
            });
        }
        ResolverRecord memory resolver = getResolver({ resolverUID: resolverUID });
        IResolver resolverContract = resolver.resolver;
        if (address(resolverContract) == ZERO_ADDRESS) {
            // Ensure that we don't accept payments if there is no resolver.
            for (uint256 i; i < length; i = uncheckedInc(i)) {
                if (values[i] != 0) revert NotPayable();
            }

            return 0;
        }

        uint256 totalUsedValue;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            uint256 value = values[i];

            // Ensure that we don't accept payments which can't be forwarded to the resolver.
            if (value != 0 && !resolverContract.isPayable()) {
                revert NotPayable();
            }

            // Ensure that the attester/revoker doesn't try to spend more than available.
            if (value > availableValue) revert InsufficientValue();

            // Ensure to deduct the sent value explicitly and add it to the total used value by the batch.
            unchecked {
                availableValue -= value;
                totalUsedValue += value;
            }
        }

        // Resolve a revocation with external IResolver
        if (isRevocation) {
            if (!resolverContract.multiRevoke{ value: totalUsedValue }(attestationRecords, values))
            {
                revert InvalidRevocations();
            }
            // Resolve an attestation with external IResolver
        } else if (
            !resolverContract.multiAttest{ value: totalUsedValue }(attestationRecords, values)
        ) {
            revert InvalidAttestations();
        }

        if (isLast) {
            _refund({ remainingValue: availableValue });
        }

        return totalUsedValue;
    }

    /**
     * @dev Refunds remaining ETH amount to the attester.
     *
     * @param remainingValue The remaining ETH amount that was not sent to the resolver.
     */
    function _refund(uint256 remainingValue) private {
        if (remainingValue > 0) {
            // Using a regular transfer here might revert, for some non-EOA attesters, due to exceeding of the 2300
            // gas limit which is why we're using call instead (via sendValue), which the 2300 gas limit does not
            // apply for.
            payable(msg.sender).sendValue(remainingValue);
        }
    }

    /**
     * @dev Internal function to get a schema record
     *
     * @param schemaUID The UID of the schema.
     *
     * @return schemaRecord The schema record.
     */
    function _getSchema(SchemaUID schemaUID) internal view virtual returns (SchemaRecord storage);

    /**
     * @dev Function to get a resolver record
     *
     * @param resolverUID The UID of the resolver.
     *
     * @return resolverRecord The resolver record.
     */
    function getResolver(ResolverUID resolverUID)
        public
        view
        virtual
        returns (ResolverRecord memory);

    /**
     * @dev Internal function to get a module record
     *
     * @param moduleAddress The address of the module.
     *
     * @return moduleRecord The module record.
     */
    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * ERC-7484 compliant interface for the registry.
 *
 * @author zeroknots
 */
interface IERC7484 {
    /**
     * @notice Queries the attestation of a specific attester for a given module.
     *
     * @dev If an attestation is not found, expired or is revoked, the function will revert.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester attestation is being queried.
     *
     * @return attestedAt The time the attestation was listed. Returns 0 if not listed or expired.
     */
    function check(address module, address attester) external view returns (uint256 attestedAt);

    /**
     * @notice Verifies the validity of attestations for a given module against a threshold.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Will also revert if any of the attestations have been revoked (even if threshold is met).
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     *
     * @return attestedAtArray The list of attestation times associated with the given module and attesters.
     */
    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
/// Note, this implementation:
/// - Uses `address(this)` for the `verifyingContract` field.
/// - Does NOT use the optional EIP-712 salt.
/// - Does NOT use any EIP-712 extensions.
/// This is for simplicity and to save gas.
/// If you need to customize, please fork / modify accordingly.
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    address private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedNameHash;
    bytes32 private immutable _cachedVersionHash;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() {
        _cachedThis = address(this);
        _cachedChainId = block.chainid;

        (string memory name, string memory version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 versionHash = keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
        _cachedDomainSeparator = separator;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the domain name and version.
    /// ```
    ///     function _domainNameAndVersion()
    ///         internal
    ///         pure
    ///         virtual
    ///         returns (string memory name, string memory version)
    ///     {
    ///         name = "Solady";
    ///         version = "1";
    ///     }
    /// ```
    function _domainNameAndVersion()
        internal
        pure
        virtual
        returns (string memory name, string memory version);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        bytes32 separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, separator) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-5267 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
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
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator() private view returns (bytes32 separator) {
        bytes32 nameHash = _cachedNameHash;
        bytes32 versionHash = _cachedVersionHash;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
///
/// @dev Note:
/// - The signature checking functions use the ecrecover precompile (0x1).
/// - The `bytes memory signature` variants use the identity precompile (0x4)
///   to copy memory internally.
/// - Unlike ECDSA signatures, contract signatures are revocable.
///
/// WARNING! Do NOT use signatures as unique identifiers.
/// Please use EIP712 with a nonce included in the digest to prevent replay attacks.
/// This implementation does NOT check if a signature is non-malleable.
library SignatureCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                if eq(mload(signature), 65) {
                    mstore(0x00, hash)
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x40, mload(add(signature, 0x20))) // `r`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                // Copy the `signature` over.
                let n := add(0x20, mload(signature))
                pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(returndatasize(), 0x44), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                if eq(signature.length, 65) {
                    mstore(0x00, hash)
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // `r`, `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), signature.length)
                // Copy the `signature` over.
                calldatacopy(add(m, 0x64), signature.offset, signature.length)
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, add(shr(255, vs), 27)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, shr(1, shl(1, vs))) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), mload(0x60)) // `s`.
                mstore8(add(m, 0xa4), mload(0x20)) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, and(v, 0xff)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, s) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), s) // `s`.
                mstore8(add(m, 0xa4), v) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            // Copy the `signature` over.
            let n := add(0x20, mload(signature))
            pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(returndatasize(), 0x44), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether `signature` is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), shr(1, shl(1, vs))) // `s`.
            mstore8(add(m, 0xa4), add(shr(255, vs), 27)) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), s) // `s`.
            mstore8(add(m, 0xa4), v) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}