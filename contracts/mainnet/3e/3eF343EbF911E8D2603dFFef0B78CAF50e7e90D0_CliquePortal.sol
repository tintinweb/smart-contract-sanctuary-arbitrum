// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AttestationPayload } from "../types/Structs.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

/**
 * @title Abstract Module
 * @author Consensys
 * @notice Defines the minimal Module interface
 */
abstract contract AbstractModule is IERC165 {
  /// @notice Error thrown when someone else than the portal's owner is trying to revoke
  error OnlyPortalOwner();

  /**
   * @notice Executes the module's custom logic.
   * @param attestationPayload The incoming attestation data.
   * @param validationPayload Additional data required for verification.
   * @param txSender The transaction sender's address.
   * @param value The transaction value.
   */
  function run(
    AttestationPayload memory attestationPayload,
    bytes memory validationPayload,
    address txSender,
    uint256 value
  ) public virtual;

  /**
   * @notice Checks if the contract implements the Module interface.
   * @param interfaceID The ID of the interface to check.
   * @return A boolean indicating interface support.
   */
  function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
    return interfaceID == type(AbstractModule).interfaceId || interfaceID == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AttestationRegistry } from "../AttestationRegistry.sol";
import { ModuleRegistry } from "../ModuleRegistry.sol";
import { PortalRegistry } from "../PortalRegistry.sol";
import { AttestationPayload } from "../types/Structs.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IRouter } from "../interfaces/IRouter.sol";
import { IPortal } from "../interfaces/IPortal.sol";

/**
 * @title Abstract Portal
 * @author Consensys
 * @notice This contract is an abstract contract with basic Portal logic
 *         to be inherited. We strongly encourage all Portals to implement
 *         this contract.
 */
abstract contract AbstractPortal is IPortal {
  IRouter public router;
  address[] public modules;
  ModuleRegistry public moduleRegistry;
  AttestationRegistry public attestationRegistry;
  PortalRegistry public portalRegistry;

  /// @notice Error thrown when someone else than the portal's owner is trying to revoke
  error OnlyPortalOwner();

  /**
   * @notice Contract constructor
   * @param _modules list of modules to use for the portal (can be empty)
   * @param _router Router's address
   * @dev This sets the addresses for the AttestationRegistry, ModuleRegistry and PortalRegistry
   */
  constructor(address[] memory _modules, address _router) {
    modules = _modules;
    router = IRouter(_router);
    attestationRegistry = AttestationRegistry(router.getAttestationRegistry());
    moduleRegistry = ModuleRegistry(router.getModuleRegistry());
    portalRegistry = PortalRegistry(router.getPortalRegistry());
  }

  /**
   * @notice Optional method to withdraw funds from the Portal
   * @param to the address to send the funds to
   * @param amount the amount to withdraw
   */
  function withdraw(address payable to, uint256 amount) external virtual;

  /**
   * @notice Attest the schema with given attestationPayload and validationPayload
   * @param attestationPayload the payload to attest
   * @param validationPayloads the payloads to validate via the modules to issue the attestations
   * @dev Runs all modules for the portal and registers the attestation using AttestationRegistry
   */
  function attest(AttestationPayload memory attestationPayload, bytes[] memory validationPayloads) public payable {
    moduleRegistry.runModules(modules, attestationPayload, validationPayloads, msg.value);

    _onAttest(attestationPayload, getAttester(), msg.value);

    attestationRegistry.attest(attestationPayload, getAttester());
  }

  /**
   * @notice Bulk attest the schema with payloads to attest and validation payloads
   * @param attestationsPayloads the payloads to attest
   * @param validationPayloads the payloads to validate via the modules to issue the attestations
   */
  function bulkAttest(AttestationPayload[] memory attestationsPayloads, bytes[][] memory validationPayloads) public {
    moduleRegistry.bulkRunModules(modules, attestationsPayloads, validationPayloads);

    _onBulkAttest(attestationsPayloads, validationPayloads);

    attestationRegistry.bulkAttest(attestationsPayloads, getAttester());
  }

  /**
   * @notice Replaces the attestation for the given identifier and replaces it with a new attestation
   * @param attestationId the ID of the attestation to replace
   * @param attestationPayload the attestation payload to create the new attestation and register it
   * @param validationPayloads the payloads to validate via the modules to issue the attestation
   * @dev Runs all modules for the portal and registers the attestation using AttestationRegistry
   */
  function replace(
    bytes32 attestationId,
    AttestationPayload memory attestationPayload,
    bytes[] memory validationPayloads
  ) public payable {
    moduleRegistry.runModules(modules, attestationPayload, validationPayloads, msg.value);

    _onReplace(attestationId, attestationPayload, getAttester(), msg.value);

    attestationRegistry.replace(attestationId, attestationPayload, getAttester());
  }

  /**
   * @notice Bulk replaces the attestation for the given identifiers and replaces them with new attestations
   * @param attestationIds the list of IDs of the attestations to replace
   * @param attestationsPayloads the list of attestation payloads to create the new attestations and register them
   * @param validationPayloads the payloads to validate via the modules to issue the attestations
   */
  function bulkReplace(
    bytes32[] memory attestationIds,
    AttestationPayload[] memory attestationsPayloads,
    bytes[][] memory validationPayloads
  ) public {
    moduleRegistry.bulkRunModules(modules, attestationsPayloads, validationPayloads);

    _onBulkReplace(attestationIds, attestationsPayloads, validationPayloads);

    attestationRegistry.bulkReplace(attestationIds, attestationsPayloads, getAttester());
  }

  /**
   * @notice Revokes an attestation for the given identifier
   * @param attestationId the ID of the attestation to revoke
   * @dev By default, revocation is only possible by the portal owner
   * We strongly encourage implementing such a rule in your Portal if you intend on overriding this method
   */
  function revoke(bytes32 attestationId) public {
    _onRevoke(attestationId);

    attestationRegistry.revoke(attestationId);
  }

  /**
   * @notice Bulk revokes a list of attestations for the given identifiers
   * @param attestationIds the IDs of the attestations to revoke
   */
  function bulkRevoke(bytes32[] memory attestationIds) public {
    _onBulkRevoke(attestationIds);

    attestationRegistry.bulkRevoke(attestationIds);
  }

  /**
   * @notice Get all the modules addresses used by the Portal
   * @return The list of modules addresses linked to the Portal
   */
  function getModules() external view returns (address[] memory) {
    return modules;
  }

  /**
   * @notice Verifies that a specific interface is implemented by the Portal, following ERC-165 specification
   * @param interfaceID the interface identifier checked in this call
   * @return The list of modules addresses linked to the Portal
   */
  function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
    return
      interfaceID == type(AbstractPortal).interfaceId ||
      interfaceID == type(IPortal).interfaceId ||
      interfaceID == type(IERC165).interfaceId;
  }

  /**
   * @notice Defines the address of the entity issuing attestations to the subject
   * @dev We strongly encourage a reflection when overriding this rule: who should be set as the attester?
   */
  function getAttester() public view virtual returns (address) {
    return msg.sender;
  }

  /**
   * @notice Optional method run before a payload is attested
   * @param attestationPayload the attestation payload supposed to be attested
   * @param attester the address of the attester
   * @param value the value sent with the attestation
   */
  function _onAttest(AttestationPayload memory attestationPayload, address attester, uint256 value) internal virtual {}

  /**
   * @notice Optional method run when an attestation is replaced
   * @param attestationId the ID of the attestation being replaced
   * @param attestationPayload the attestation payload to create attestation and register it
   * @param attester the address of the attester
   * @param value the value sent with the attestation
   */
  function _onReplace(
    bytes32 attestationId,
    AttestationPayload memory attestationPayload,
    address attester,
    uint256 value
  ) internal virtual {}

  /**
   * @notice Optional method run when attesting a batch of payloads
   * @param attestationsPayloads the payloads to attest
   * @param validationPayloads the payloads to validate in order to issue the attestations
   */
  function _onBulkAttest(
    AttestationPayload[] memory attestationsPayloads,
    bytes[][] memory validationPayloads
  ) internal virtual {}

  function _onBulkReplace(
    bytes32[] memory attestationIds,
    AttestationPayload[] memory attestationsPayloads,
    bytes[][] memory validationPayloads
  ) internal virtual {}

  /**
   * @notice Optional method run when an attestation is revoked or replaced
   * @dev    IMPORTANT NOTE: By default, revocation is only possible by the portal owner
   */
  function _onRevoke(bytes32 /*attestationId*/) internal virtual {
    if (msg.sender != portalRegistry.getPortalByAddress(address(this)).ownerAddress) revert OnlyPortalOwner();
  }

  /**
   * @notice Optional method run when a batch of attestations are revoked or replaced
   * @dev    IMPORTANT NOTE: By default, revocation is only possible by the portal owner
   */
  function _onBulkRevoke(bytes32[] memory /*attestationIds*/) internal virtual {
    if (msg.sender != portalRegistry.getPortalByAddress(address(this)).ownerAddress) revert OnlyPortalOwner();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Attestation, AttestationPayload } from "./types/Structs.sol";
import { PortalRegistry } from "./PortalRegistry.sol";
import { SchemaRegistry } from "./SchemaRegistry.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { uncheckedInc256 } from "./Common.sol";

/**
 * @title Attestation Registry
 * @author Consensys
 * @notice This contract stores a registry of all attestations
 */
contract AttestationRegistry is OwnableUpgradeable {
  IRouter public router;

  uint16 private version;
  uint32 private attestationIdCounter;

  mapping(bytes32 attestationId => Attestation attestation) private attestations;

  uint256 private chainPrefix;

  /// @notice Error thrown when a non-portal tries to call a method that can only be called by a portal
  error OnlyPortal();
  /// @notice Error thrown when an invalid Router address is given
  error RouterInvalid();
  /// @notice Error thrown when an attestation is not registered in the AttestationRegistry
  error AttestationNotAttested();
  /// @notice Error thrown when an attempt is made to revoke an attestation by an entity other than the attesting portal
  error OnlyAttestingPortal();
  /// @notice Error thrown when a schema id is not registered
  error SchemaNotRegistered();
  /// @notice Error thrown when an attestation subject is empty
  error AttestationSubjectFieldEmpty();
  /// @notice Error thrown when an attestation data field is empty
  error AttestationDataFieldEmpty();
  /// @notice Error thrown when an attempt is made to bulk replace with mismatched parameter array lengths
  error ArrayLengthMismatch();
  /// @notice Error thrown when an attempt is made to revoke an attestation that was already revoked
  error AlreadyRevoked();
  /// @notice Error thrown when an attempt is made to revoke an attestation based on a non-revocable schema
  error AttestationNotRevocable();

  /// @notice Event emitted when an attestation is registered
  event AttestationRegistered(bytes32 indexed attestationId);
  /// @notice Event emitted when an attestation is replaced
  event AttestationReplaced(bytes32 attestationId, bytes32 replacedBy);
  /// @notice Event emitted when an attestation is revoked
  event AttestationRevoked(bytes32 attestationId);
  /// @notice Event emitted when the version number is incremented
  event VersionUpdated(uint16 version);

  /**
   * @notice Checks if the caller is a registered portal
   * @param portal the portal address
   */
  modifier onlyPortals(address portal) {
    bool isPortalRegistered = PortalRegistry(router.getPortalRegistry()).isRegistered(portal);
    if (!isPortalRegistered) revert OnlyPortal();
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Changes the address for the Router
   * @dev Only the registry owner can call this method
   */
  function updateRouter(address _router) public onlyOwner {
    if (_router == address(0)) revert RouterInvalid();
    router = IRouter(_router);
  }

  /**
   * @notice Changes the chain prefix for the attestation IDs
   * @dev Only the registry owner can call this method
   */
  function updateChainPrefix(uint256 _chainPrefix) public onlyOwner {
    chainPrefix = _chainPrefix;
  }

  /**
   * @notice Registers an attestation to the AttestationRegistry
   * @param attestationPayload the attestation payload to create attestation and register it
   * @param attester the account address issuing the attestation
   * @dev This method is only callable by a registered Portal
   */
  function attest(AttestationPayload calldata attestationPayload, address attester) public onlyPortals(msg.sender) {
    // Verify the schema id exists
    SchemaRegistry schemaRegistry = SchemaRegistry(router.getSchemaRegistry());
    if (!schemaRegistry.isRegistered(attestationPayload.schemaId)) revert SchemaNotRegistered();
    // Verify the subject field is not blank
    if (attestationPayload.subject.length == 0) revert AttestationSubjectFieldEmpty();
    // Verify the attestationData field is not blank
    if (attestationPayload.attestationData.length == 0) revert AttestationDataFieldEmpty();
    // Auto increment attestation counter
    attestationIdCounter++;
    // Generate the full attestation ID, padded with the chain prefix
    bytes32 id = generateAttestationId(attestationIdCounter);
    // Create attestation
    attestations[id] = Attestation(
      id,
      attestationPayload.schemaId,
      bytes32(0),
      attester,
      msg.sender,
      uint64(block.timestamp),
      attestationPayload.expirationDate,
      0,
      version,
      false,
      attestationPayload.subject,
      attestationPayload.attestationData
    );
    emit AttestationRegistered(id);
  }

  /**
   * @notice Registers attestations to the AttestationRegistry
   * @param attestationsPayloads the attestations payloads to create attestations and register them
   */
  function bulkAttest(AttestationPayload[] calldata attestationsPayloads, address attester) public {
    for (uint256 i = 0; i < attestationsPayloads.length; i = uncheckedInc256(i)) {
      attest(attestationsPayloads[i], attester);
    }
  }

  function massImport(AttestationPayload[] calldata attestationsPayloads, address portal) public onlyOwner {
    for (uint256 i = 0; i < attestationsPayloads.length; i = uncheckedInc256(i)) {
      // Auto increment attestation counter
      attestationIdCounter++;
      // Generate the full attestation ID, padded with the chain prefix
      bytes32 id = generateAttestationId(attestationIdCounter);
      // Create attestation
      attestations[id] = Attestation(
        id,
        attestationsPayloads[i].schemaId,
        bytes32(0),
        msg.sender,
        portal,
        uint64(block.timestamp),
        attestationsPayloads[i].expirationDate,
        0,
        version,
        false,
        attestationsPayloads[i].subject,
        attestationsPayloads[i].attestationData
      );
      emit AttestationRegistered(id);
    }
  }

  /**
   * @notice Replaces an attestation for the given identifier and replaces it with a new attestation
   * @param attestationId the ID of the attestation to replace
   * @param attestationPayload the attestation payload to create the new attestation and register it
   * @param attester the account address issuing the attestation
   */
  function replace(bytes32 attestationId, AttestationPayload calldata attestationPayload, address attester) public {
    attest(attestationPayload, attester);
    revoke(attestationId);
    bytes32 replacedBy = generateAttestationId(attestationIdCounter);
    attestations[attestationId].replacedBy = replacedBy;

    emit AttestationReplaced(attestationId, replacedBy);
  }

  /**
   * @notice Replaces attestations for given identifiers and replaces them with new attestations
   * @param attestationIds the list of IDs of the attestations to replace
   * @param attestationPayloads the list of attestation payloads to create the new attestations and register them
   * @param attester the account address issuing the attestation
   */
  function bulkReplace(
    bytes32[] calldata attestationIds,
    AttestationPayload[] calldata attestationPayloads,
    address attester
  ) public {
    if (attestationIds.length != attestationPayloads.length) revert ArrayLengthMismatch();
    for (uint256 i = 0; i < attestationIds.length; i = uncheckedInc256(i)) {
      replace(attestationIds[i], attestationPayloads[i], attester);
    }
  }

  /**
   * @notice Revokes an attestation for a given identifier
   * @param attestationId the ID of the attestation to revoke
   */
  function revoke(bytes32 attestationId) public {
    if (!isRegistered(attestationId)) revert AttestationNotAttested();
    if (attestations[attestationId].revoked) revert AlreadyRevoked();
    if (msg.sender != attestations[attestationId].portal) revert OnlyAttestingPortal();
    if (!isRevocable(attestations[attestationId].portal)) revert AttestationNotRevocable();

    attestations[attestationId].revoked = true;
    attestations[attestationId].revocationDate = uint64(block.timestamp);

    emit AttestationRevoked(attestationId);
  }

  /**
   * @notice Bulk revokes a list of attestations for the given identifiers
   * @param attestationIds the IDs of the attestations to revoke
   */
  function bulkRevoke(bytes32[] memory attestationIds) external {
    for (uint256 i = 0; i < attestationIds.length; i = uncheckedInc256(i)) {
      revoke(attestationIds[i]);
    }
  }

  /**
   * @notice Checks if an attestation is registered
   * @param attestationId the attestation identifier
   * @return true if the attestation is registered, false otherwise
   */
  function isRegistered(bytes32 attestationId) public view returns (bool) {
    return attestations[attestationId].attestationId != bytes32(0);
  }

  /**
   * @notice Checks whether a portal issues revocable attestations
   * @param portalId the portal address (ID)
   * @return true if the attestations issued by this portal are revocable, false otherwise
   */
  function isRevocable(address portalId) public view returns (bool) {
    PortalRegistry portalRegistry = PortalRegistry(router.getPortalRegistry());
    return portalRegistry.getPortalByAddress(portalId).isRevocable;
  }

  /**
   * @notice Gets an attestation by its identifier
   * @param attestationId the attestation identifier
   * @return the attestation
   */
  function getAttestation(bytes32 attestationId) public view returns (Attestation memory) {
    if (!isRegistered(attestationId)) revert AttestationNotAttested();
    return attestations[attestationId];
  }

  /**
   * @notice Increments the registry version
   * @return The new version number
   */
  function incrementVersionNumber() public onlyOwner returns (uint16) {
    ++version;
    emit VersionUpdated(version);
    return version;
  }

  /**
   * @notice Gets the registry version
   * @return The current version number
   */
  function getVersionNumber() public view returns (uint16) {
    return version;
  }

  /**
   * @notice Gets the attestation counter
   * @return The attestation counter
   */
  function getAttestationIdCounter() public view returns (uint32) {
    return attestationIdCounter;
  }

  /**
   * @notice Gets the chain prefix used to generate the attestation IDs
   * @return The chain prefix
   */
  function getChainPrefix() public view returns (uint256) {
    return chainPrefix;
  }

  /**
   * @notice Checks if an address owns a given attestation following ERC-1155
   * @param account The address of the token holder
   * @param id ID of the attestation
   * @return The _owner's balance of the attestations on a given attestation ID
   */
  function balanceOf(address account, uint256 id) public view returns (uint256) {
    bytes32 attestationId = generateAttestationId(id);
    Attestation memory attestation = attestations[attestationId];
    if (attestation.subject.length > 20 && keccak256(attestation.subject) == keccak256(abi.encode(account))) {
      return 1;
    }
    if (attestation.subject.length == 20 && keccak256(attestation.subject) == keccak256(abi.encodePacked(account))) {
      return 1;
    }
    return 0;
  }

  /**
   * @notice Get the balance of multiple account/attestation pairs following ERC-1155
   * @param accounts The addresses of the attestation holders
   * @param ids ID of the attestations
   * @return The _owner's balance of the attestation for a given address (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
    if (accounts.length != ids.length) revert ArrayLengthMismatch();
    uint256[] memory result = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; i = uncheckedInc256(i)) {
      result[i] = balanceOf(accounts[i], ids[i]);
    }
    return result;
  }

  /**
   * @notice Generate an attestation ID, prefixed by the Verax chain identifier
   * @param id The attestation ID (coming after the chain prefix)
   * @return The attestation ID
   */
  function generateAttestationId(uint256 id) internal view returns (bytes32) {
    // Combine the chain prefix and the ID
    return bytes32(abi.encode(chainPrefix + id));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice This function is inspired by PADO Labs' codebase
 * solhint-disable-next-line max-line-length
 * https://github.com/pado-labs/offchain-data-hooks/blob/c6f37ad2a42d0eb40cf2295aed68ea3b94ee0925/src/hooks/Common.sol#L45
 * @dev A helper function to work with unchecked uint256 iterators in loops
 */
function uncheckedInc256(uint256 i) pure returns (uint256 j) {
  unchecked {
    j = i + 1;
  }
}

/**
 * @notice This function is inspired by PADO Labs' codebase
 * solhint-disable-next-line max-line-length
 * https://github.com/pado-labs/offchain-data-hooks/blob/c6f37ad2a42d0eb40cf2295aed68ea3b94ee0925/src/hooks/Common.sol#L45
 * @dev A helper function to work with unchecked uint32 iterators in loops
 */
function uncheckedInc32(uint32 i) pure returns (uint32 j) {
  unchecked {
    j = i + 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AbstractPortal } from "./abstracts/AbstractPortal.sol";

/**
 * @title Default Portal
 * @author Consensys
 * @notice This contract aims to provide a default portal
 * @dev This Portal does not add any logic to the AbstractPortal
 */
contract DefaultPortal is AbstractPortal {
  /**
   * @notice Contract constructor
   * @param modules list of modules to use for the portal (can be empty)
   * @param router the Router's address
   * @dev This sets the addresses for the AttestationRegistry, ModuleRegistry and PortalRegistry
   */
  constructor(address[] memory modules, address router) AbstractPortal(modules, router) {}

  /// @inheritdoc AbstractPortal
  function withdraw(address payable to, uint256 amount) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/**
 * @title IPortal
 * @author Consensys
 * @notice This contract is the interface to be implemented by any Portal.
 *         NOTE: A portal must implement this interface to registered on
 *         the PortalRegistry contract.
 */
interface IPortal is IERC165 {
  /**
   * @notice Get all the modules addresses used by the Portal
   * @return The list of modules addresses linked to the Portal
   */
  function getModules() external view returns (address[] memory);

  /**
   * @notice Defines the address of the entity issuing attestations to the subject
   * @dev We strongly encourage a reflection when implementing this method
   */
  function getAttester() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title Router
 * @author Consensys
 * @notice This contract aims to provides a single entrypoint for the Verax registries
 */
interface IRouter {
  /**
   * @notice Gives the address for the AttestationRegistry contract
   * @return The current address of the AttestationRegistry contract
   */
  function getAttestationRegistry() external view returns (address);

  /**
   * @notice Gives the address for the ModuleRegistry contract
   * @return The current address of the ModuleRegistry contract
   */
  function getModuleRegistry() external view returns (address);

  /**
   * @notice Gives the address for the PortalRegistry contract
   * @return The current address of the PortalRegistry contract
   */
  function getPortalRegistry() external view returns (address);

  /**
   * @notice Gives the address for the SchemaRegistry contract
   * @return The current address of the SchemaRegistry contract
   */
  function getSchemaRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AttestationPayload, Module } from "./types/Structs.sol";
import { AbstractModule } from "./abstracts/AbstractModule.sol";
import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165CheckerUpgradeable.sol";
import { PortalRegistry } from "./PortalRegistry.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { uncheckedInc32 } from "./Common.sol";

/**
 * @title Module Registry
 * @author Consensys
 * @notice This contract aims to manage the Modules used by the Portals, including their discoverability
 */
contract ModuleRegistry is OwnableUpgradeable {
  IRouter public router;
  /// @dev The list of Modules, accessed by their address
  mapping(address id => Module module) public modules;
  /// @dev The list of Module addresses
  address[] public moduleAddresses;

  /// @notice Error thrown when an invalid Router address is given
  error RouterInvalid();
  /// @notice Error thrown when a non-issuer tries to call a method that can only be called by an issuer
  error OnlyIssuer();
  /// @notice Error thrown when an identical Module was already registered
  error ModuleAlreadyExists();
  /// @notice Error thrown when attempting to add a Module without a name
  error ModuleNameMissing();
  /// @notice Error thrown when attempting to add a Module without an address of deployed smart contract
  error ModuleAddressInvalid();
  /// @notice Error thrown when attempting to add a Module which has not implemented the IModule interface
  error ModuleInvalid();
  /// @notice Error thrown when attempting to run modules with no attestation payload provided
  error AttestationPayloadMissing();
  /// @notice Error thrown when module is not registered
  error ModuleNotRegistered();
  /// @notice Error thrown when module addresses and validation payload length mismatch
  error ModuleValidationPayloadMismatch();

  /// @notice Event emitted when a Module is registered
  event ModuleRegistered(string name, string description, address moduleAddress);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Checks if the caller is a registered issuer.
   * @param issuer the issuer address
   */
  modifier onlyIssuers(address issuer) {
    bool isIssuerRegistered = PortalRegistry(router.getPortalRegistry()).isIssuer(issuer);
    if (!isIssuerRegistered) revert OnlyIssuer();
    _;
  }

  /**
   * @notice Changes the address for the Router
   * @dev Only the registry owner can call this method
   */
  function updateRouter(address _router) public onlyOwner {
    if (_router == address(0)) revert RouterInvalid();
    router = IRouter(_router);
  }

  /**
   * Check if address is smart contract and not EOA
   * @param contractAddress address to be verified
   * @return the result as true if it is a smart contract else false
   */
  function isContractAddress(address contractAddress) public view returns (bool) {
    return contractAddress.code.length > 0;
  }

  /**
   * @notice Registers a Module, with its metadata and run some checks:
   * - mandatory name
   * - mandatory module's deployed smart contract address
   * - the module must be unique
   * @param name the module name
   * @param description the module description
   * @param moduleAddress the address of the deployed smart contract
   * @dev the module is stored in a mapping, the number of modules is incremented and an event is emitted
   */
  function register(
    string memory name,
    string memory description,
    address moduleAddress
  ) public onlyIssuers(msg.sender) {
    if (bytes(name).length == 0) revert ModuleNameMissing();
    // Check if moduleAddress is a smart contract address
    if (!isContractAddress(moduleAddress)) revert ModuleAddressInvalid();
    // Check if module has implemented AbstractModule
    if (!ERC165CheckerUpgradeable.supportsInterface(moduleAddress, type(AbstractModule).interfaceId)) {
      revert ModuleInvalid();
    }
    // Module address is used to identify uniqueness of the module
    if (bytes(modules[moduleAddress].name).length > 0) revert ModuleAlreadyExists();

    modules[moduleAddress] = Module(moduleAddress, name, description);
    moduleAddresses.push(moduleAddress);
    emit ModuleRegistered(name, description, moduleAddress);
  }

  /**
   * @notice Executes the run method for all given Modules that are registered
   * @param modulesAddresses the addresses of the registered modules
   * @param attestationPayload the payload to attest
   * @param validationPayloads the payloads to check for each module (one payload per module)
   * @dev check if modules are registered and execute run method for each module
   */
  function runModules(
    address[] memory modulesAddresses,
    AttestationPayload memory attestationPayload,
    bytes[] memory validationPayloads,
    uint256 value
  ) public {
    // If no modules provided, bypass module validation
    if (modulesAddresses.length == 0) return;
    // Each module involved must have a corresponding item from the validation payload
    if (modulesAddresses.length != validationPayloads.length) revert ModuleValidationPayloadMismatch();

    // For each module check if it is registered and call run method
    for (uint32 i = 0; i < modulesAddresses.length; i = uncheckedInc32(i)) {
      if (!isRegistered(modulesAddresses[i])) revert ModuleNotRegistered();
      AbstractModule(modulesAddresses[i]).run(attestationPayload, validationPayloads[i], tx.origin, value);
    }
  }

  /**
   * @notice Executes the modules validation for all attestations payloads for all given Modules that are registered
   * @param modulesAddresses the addresses of the registered modules
   * @param attestationsPayloads the payloads to attest
   * @param validationPayloads the payloads to check for each module
   * @dev NOTE: Currently the bulk run modules does not handle payable modules
   *            a default value of 0 is used.
   */
  function bulkRunModules(
    address[] memory modulesAddresses,
    AttestationPayload[] memory attestationsPayloads,
    bytes[][] memory validationPayloads
  ) public {
    for (uint32 i = 0; i < attestationsPayloads.length; i = uncheckedInc32(i)) {
      runModules(modulesAddresses, attestationsPayloads[i], validationPayloads[i], 0);
    }
  }

  /**
   * @notice Get the number of Modules managed by the contract
   * @return The number of Modules already registered
   * @dev Returns the length of the `moduleAddresses` array
   */
  function getModulesNumber() public view returns (uint256) {
    return moduleAddresses.length;
  }

  /**
   * @notice Checks that a module is registered in the module registry
   * @param moduleAddress The address of the Module to check
   * @return True if the Module is registered, False otherwise
   */
  function isRegistered(address moduleAddress) public view returns (bool) {
    return bytes(modules[moduleAddress].name).length > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/ERC165CheckerUpgradeable.sol";
import { AbstractPortal } from "./abstracts/AbstractPortal.sol";
import { DefaultPortal } from "./DefaultPortal.sol";
import { SchemaRegistry } from "./SchemaRegistry.sol";
import { Portal } from "./types/Structs.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { IPortal } from "./interfaces/IPortal.sol";

/**
 * @title Portal Registry
 * @author Consensys
 * @notice This contract aims to manage the Portals used by attestation issuers
 */
contract PortalRegistry is OwnableUpgradeable {
  IRouter public router;

  mapping(address id => Portal portal) private portals;

  mapping(address issuerAddress => bool isIssuer) private issuers;

  address[] private portalAddresses;

  /// @notice Error thrown when an invalid Router address is given
  error RouterInvalid();
  /// @notice Error thrown when a non-issuer tries to call a method that can only be called by an issuer
  error OnlyIssuer();
  /// @notice Error thrown when attempting to register a Portal twice
  error PortalAlreadyExists();
  /// @notice Error thrown when attempting to register a Portal that is not a smart contract
  error PortalAddressInvalid();
  /// @notice Error thrown when attempting to register a Portal with an empty name
  error PortalNameMissing();
  /// @notice Error thrown when attempting to register a Portal with an empty description
  error PortalDescriptionMissing();
  /// @notice Error thrown when attempting to register a Portal with an empty owner name
  error PortalOwnerNameMissing();
  /// @notice Error thrown when attempting to register a Portal that does not implement IPortal interface
  error PortalInvalid();
  /// @notice Error thrown when attempting to get a Portal that is not registered
  error PortalNotRegistered();

  /// @notice Event emitted when a Portal registered
  event PortalRegistered(string name, string description, address portalAddress);
  /// @notice Event emitted when a new issuer is added
  event IssuerAdded(address issuerAddress);
  /// @notice Event emitted when the issuer is removed
  event IssuerRemoved(address issuerAddress);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Changes the address for the Router
   * @dev Only the registry owner can call this method
   */
  function updateRouter(address _router) public onlyOwner {
    if (_router == address(0)) revert RouterInvalid();
    router = IRouter(_router);
  }

  /**
   * @notice Registers an address as been an issuer
   * @param issuer the address to register as an issuer
   */
  function setIssuer(address issuer) public onlyOwner {
    issuers[issuer] = true;
    // Emit event
    emit IssuerAdded(issuer);
  }

  /**
   * @notice Revokes issuer status from an address
   * @param issuer the address to be revoked as an issuer
   */
  function removeIssuer(address issuer) public onlyOwner {
    issuers[issuer] = false;
    SchemaRegistry(router.getSchemaRegistry()).updateMatchingSchemaIssuers(issuer, msg.sender);
    // Emit event
    emit IssuerRemoved(issuer);
  }

  /**
   * @notice Checks if a given address is an issuer
   * @return A flag indicating whether the given address is an issuer
   */
  function isIssuer(address issuer) public view returns (bool) {
    return issuers[issuer];
  }

  /**
   * @notice Checks if the caller is a registered issuer.
   * @param issuer the issuer address
   */
  modifier onlyIssuers(address issuer) {
    if (!isIssuer(issuer)) revert OnlyIssuer();
    _;
  }

  /**
   * @notice Registers a Portal to the PortalRegistry
   * @param id the portal address
   * @param name the portal name
   * @param description the portal description
   * @param isRevocable whether the portal issues revocable attestations
   * @param ownerName name of this portal's owner
   */
  function register(
    address id,
    string memory name,
    string memory description,
    bool isRevocable,
    string memory ownerName
  ) public onlyIssuers(msg.sender) {
    // Check if portal already exists
    if (portals[id].id != address(0)) revert PortalAlreadyExists();

    // Check if portal is a smart contract
    if (!isContractAddress(id)) revert PortalAddressInvalid();

    // Check if name is not empty
    if (bytes(name).length == 0) revert PortalNameMissing();

    // Check if description is not empty
    if (bytes(description).length == 0) revert PortalDescriptionMissing();

    // Check if the owner's name is not empty
    if (bytes(ownerName).length == 0) revert PortalOwnerNameMissing();

    // Check if portal has implemented AbstractPortal
    if (!ERC165CheckerUpgradeable.supportsInterface(id, type(IPortal).interfaceId)) revert PortalInvalid();

    // Get the array of modules implemented by the portal
    address[] memory modules = AbstractPortal(id).getModules();

    // Add portal to mapping
    Portal memory newPortal = Portal(id, msg.sender, modules, isRevocable, name, description, ownerName);
    portals[id] = newPortal;
    portalAddresses.push(id);

    // Emit event
    emit PortalRegistered(name, description, id);
  }

  /**
   * @notice Deploys and registers a clone of default portal
   * @param modules the modules addresses
   * @param name the portal name
   * @param description the portal description
   * @param ownerName name of this portal's owner
   */
  function deployDefaultPortal(
    address[] calldata modules,
    string memory name,
    string memory description,
    bool isRevocable,
    string memory ownerName
  ) external onlyIssuers(msg.sender) {
    DefaultPortal defaultPortal = new DefaultPortal(modules, address(router));
    register(address(defaultPortal), name, description, isRevocable, ownerName);
  }

  /**
   * @notice Get a Portal by its address
   * @param id The address of the Portal
   * @return The Portal
   */
  function getPortalByAddress(address id) public view returns (Portal memory) {
    if (!isRegistered(id)) revert PortalNotRegistered();
    return portals[id];
  }

  /**
   * @notice Check if a Portal is registered
   * @param id The address of the Portal
   * @return True if the Portal is registered, false otherwise
   */
  function isRegistered(address id) public view returns (bool) {
    return portals[id].id != address(0);
  }

  /**
   * @notice Get the number of Portals managed by the contract
   * @return The number of Portals already registered
   * @dev Returns the length of the `portalAddresses` array
   */
  function getPortalsCount() public view returns (uint256) {
    return portalAddresses.length;
  }

  /**
   * Check if address is smart contract and not EOA
   * @param contractAddress address to be verified
   * @return the result as true if it is a smart contract else false
   */
  function isContractAddress(address contractAddress) internal view returns (bool) {
    return contractAddress.code.length > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Schema } from "./types/Structs.sol";
import { PortalRegistry } from "./PortalRegistry.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { uncheckedInc256 } from "./Common.sol";

/**
 * @title Schema Registry
 * @author Consensys
 * @notice This contract aims to manage the Schemas used by the Portals, including their discoverability
 */
contract SchemaRegistry is OwnableUpgradeable {
  IRouter public router;
  /// @dev The list of Schemas, accessed by their ID
  mapping(bytes32 id => Schema schema) private schemas;
  /// @dev The list of Schema IDs
  bytes32[] public schemaIds;
  /// @dev Associates a Schema ID with the address of the Issuer who created it
  mapping(bytes32 id => address issuer) private schemasIssuers;

  /// @notice Error thrown when an invalid Router address is given
  error RouterInvalid();
  /// @notice Error thrown when a non-issuer tries to call a method that can only be called by an issuer
  error OnlyIssuer();
  /// @notice Error thrown when any address which is not a portal registry tries to call a method
  error OnlyPortalRegistry();
  /// @notice Error thrown when a non-assigned issuer tries to call a method that can only be called by an assigned issuer
  error OnlyAssignedIssuer();
  /// @notice Error thrown when an invalid Issuer address is given
  error IssuerInvalid();
  /// @notice Error thrown when an identical Schema was already registered
  error SchemaAlreadyExists();
  /// @notice Error thrown when attempting to add a Schema without a name
  error SchemaNameMissing();
  /// @notice Error thrown when attempting to add a Schema without a string to define it
  error SchemaStringMissing();
  /// @notice Error thrown when attempting to get a Schema that is not registered
  error SchemaNotRegistered();

  /// @notice Event emitted when a Schema is created and registered
  event SchemaCreated(bytes32 indexed id, string name, string description, string context, string schemaString);
  /// @notice Event emitted when a Schema context is updated
  event SchemaContextUpdated(bytes32 indexed id);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Contract initialization
   */
  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Checks if the caller is a registered issuer.
   * @param issuer the issuer address
   */
  modifier onlyIssuers(address issuer) {
    bool isIssuerRegistered = PortalRegistry(router.getPortalRegistry()).isIssuer(issuer);
    if (!isIssuerRegistered) revert OnlyIssuer();
    _;
  }

  /**
   * @notice Checks if the caller is the portal registry.
   * @param caller the caller address
   */
  modifier onlyPortalRegistry(address caller) {
    bool isCallerPortalRegistry = router.getPortalRegistry() == caller;
    if (!isCallerPortalRegistry) revert OnlyPortalRegistry();
    _;
  }

  /**
   * @notice Changes the address for the Router
   * @dev Only the registry owner can call this method
   */
  function updateRouter(address _router) public onlyOwner {
    if (_router == address(0)) revert RouterInvalid();
    router = IRouter(_router);
  }

  /**
   * @notice Updates a given Schema's Issuer
   * @param schemaId the Schema's ID
   * @param issuer the address of the issuer who created the given Schema
   * @dev Updates issuer for the given schemaId in the `schemaIssuers` mapping
   *      The issuer must already be registered as an Issuer via the `PortalRegistry`
   */
  function updateSchemaIssuer(bytes32 schemaId, address issuer) public onlyOwner {
    if (!isRegistered(schemaId)) revert SchemaNotRegistered();
    if (issuer == address(0)) revert IssuerInvalid();
    schemasIssuers[schemaId] = issuer;
  }

  /**
   * @notice Updates issuer address for all schemas associated with old issuer address
   * @param oldIssuer the address of old issuer
   * @param newIssuer the address of new issuer
   * @dev Finds all the schemaIds associated with old issuer and updates the mapping `schemasIssuers`
   *      for schemaIds found with new issuer
   */
  function updateMatchingSchemaIssuers(address oldIssuer, address newIssuer) public onlyPortalRegistry(msg.sender) {
    for (uint256 i = 0; i < schemaIds.length; i = uncheckedInc256(i)) {
      if (schemasIssuers[schemaIds[i]] == oldIssuer) {
        schemasIssuers[schemaIds[i]] = newIssuer;
      }
    }
  }

  /**
   * Generate an ID for a given schema
   * @param schema the string defining a schema
   * @return the schema ID
   * @dev encodes a schema string to unique bytes
   */
  function getIdFromSchemaString(string memory schema) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(schema));
  }

  /**
   * @notice Creates a Schema, with its metadata and runs some checks:
   * - mandatory name
   * - mandatory string defining the schema
   * - the Schema must be unique
   * @param name the Schema name
   * @param description the Schema description
   * @param context the Schema context
   * @param schemaString the string defining a Schema
   * @dev The Schema is stored in the `schemas` mapping, its ID is added to an array of IDs and an event is emitted
   *      The caller is assigned as the creator of the Schema, via the `schemasIssuers` mapping
   */
  function createSchema(
    string memory name,
    string memory description,
    string memory context,
    string memory schemaString
  ) public onlyIssuers(msg.sender) {
    if (bytes(name).length == 0) revert SchemaNameMissing();
    if (bytes(schemaString).length == 0) revert SchemaStringMissing();

    bytes32 schemaId = getIdFromSchemaString(schemaString);

    if (isRegistered(schemaId)) {
      revert SchemaAlreadyExists();
    }

    schemas[schemaId] = Schema(name, description, context, schemaString);
    schemaIds.push(schemaId);
    schemasIssuers[schemaId] = msg.sender;
    emit SchemaCreated(schemaId, name, description, context, schemaString);
  }

  /**
   * @notice Updates the context of a given schema
   * @param schemaId the schema ID
   * @param context the Schema context
   * @dev Retrieve the Schema with given ID and update its context with new value and an event is emitted
   *      The caller must be the creator of the given Schema (through the `schemaIssuers` mapping)
   */
  function updateContext(bytes32 schemaId, string memory context) public {
    if (!isRegistered(schemaId)) revert SchemaNotRegistered();
    if (schemasIssuers[schemaId] != msg.sender) revert OnlyAssignedIssuer();
    schemas[schemaId].context = context;
    emit SchemaContextUpdated(schemaId);
  }

  /**
   * @notice Gets a schema by its identifier
   * @param schemaId the schema ID
   * @return the schema
   */
  function getSchema(bytes32 schemaId) public view returns (Schema memory) {
    if (!isRegistered(schemaId)) revert SchemaNotRegistered();
    return schemas[schemaId];
  }

  /**
   * @notice Get the number of Schemas managed by the contract
   * @return The number of Schemas already registered
   * @dev Returns the length of the `schemaIds` array
   */
  function getSchemasNumber() public view returns (uint256) {
    return schemaIds.length;
  }

  /**
   * @notice Check if a Schema is registered
   * @param schemaId The ID of the Schema
   * @return True if the Schema is registered, false otherwise
   */
  function isRegistered(bytes32 schemaId) public view returns (bool) {
    return bytes(schemas[schemaId].name).length > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

struct AttestationPayload {
  bytes32 schemaId; // The identifier of the schema this attestation adheres to.
  uint64 expirationDate; // The expiration date of the attestation.
  bytes subject; // The ID of the attestee, EVM address, DID, URL etc.
  bytes attestationData; // The attestation data.
}

struct Attestation {
  bytes32 attestationId; // The unique identifier of the attestation.
  bytes32 schemaId; // The identifier of the schema this attestation adheres to.
  bytes32 replacedBy; // Whether the attestation was replaced by a new one.
  address attester; // The address issuing the attestation to the subject.
  address portal; // The id of the portal that created the attestation.
  uint64 attestedDate; // The date the attestation is issued.
  uint64 expirationDate; // The expiration date of the attestation.
  uint64 revocationDate; // The date when the attestation was revoked.
  uint16 version; // Version of the registry when the attestation was created.
  bool revoked; // Whether the attestation is revoked or not.
  bytes subject; // The ID of the attestee, EVM address, DID, URL etc.
  bytes attestationData; // The attestation data.
}

struct Schema {
  string name; // The name of the schema.
  string description; // A description of the schema.
  string context; // The context of the schema.
  string schema; // The schema definition.
}

struct Portal {
  address id; // The unique identifier of the portal.
  address ownerAddress; // The address of the owner of this portal.
  address[] modules; // Addresses of modules implemented by the portal.
  bool isRevocable; // Whether attestations issued can be revoked.
  string name; // The name of the portal.
  string description; // A description of the portal.
  string ownerName; // The name of the owner of this portal.
}

struct Module {
  address moduleAddress; // The address of the module.
  string name; // The name of the module.
  string description; // A description of the module.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AttestationPayload } from "linea-attestation-registry/types/Structs.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { AbstractPortal } from "linea-attestation-registry/abstracts/AbstractPortal.sol";

/**
 * @title Clique Portal
 * @author Clique
 * @notice This contract is a Portal used by Clique to issue attestations
 */
contract CliquePortal is AbstractPortal, Ownable {
  /// @dev Error thrown when the withdraw fails
  error WithdrawFail();

  constructor(address[] memory _modules, address _router) AbstractPortal(_modules, _router) {}

  function withdraw(address payable to, uint256 amount) external override onlyOwner {
    (bool s, ) = to.call{ value: amount }("");
    if (!s) revert WithdrawFail();
  }
}