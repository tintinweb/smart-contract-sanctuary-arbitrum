// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AttestationPayload } from "../types/Structs.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

abstract contract AbstractModule is IERC165 {
  function run(
    AttestationPayload memory attestationPayload,
    bytes memory validationPayload,
    address txSender,
    uint256 value
  ) public virtual;

  /**
   * @notice To check this contract implements the Module interface
   */
  function supportsInterface(bytes4 interfaceID) public pure virtual override returns (bool) {
    return interfaceID == type(AbstractModule).interfaceId || interfaceID == type(IERC165).interfaceId;
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

import { AbstractModule } from "linea-attestation-registry/interface/AbstractModule.sol";
import { AttestationPayload } from "linea-attestation-registry/types/Structs.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

/**
 * @title SchemaChecker Module
 * @author Clique
 * @notice This contract is an example of a module,
 *         able to check for accepted schemaIds
 */
contract SchemaCheckerModule is Ownable, AbstractModule {
  mapping(bytes32 schemaId => bool accepted) public acceptedSchemaIds;

  /// @notice Error thrown when an array length mismatch occurs
  error ArraylengthMismatch();
  /// @notice Error thrown when a schemaId is not accepted by the module
  error SchemaIdNotAccepted();

  /**
   * @notice Set the accepted status of schemaIds
   * @param schemaIds The schemaIds to be set
   * @param acceptedStatus The accepted status of schemaIds
   */
  function setAcceptedSchemaIds(bytes32[] memory schemaIds, bool[] memory acceptedStatus) public onlyOwner {
    if (schemaIds.length != acceptedStatus.length) revert ArraylengthMismatch();

    for (uint256 i = 0; i < schemaIds.length; i++) {
      acceptedSchemaIds[schemaIds[i]] = acceptedStatus[i];
    }
  }

  /**
   * @notice The main method for the module, running the check
   * @param _attestationPayload The Payload of the attestation The value sent for the attestation
   */
  function run(
    AttestationPayload memory _attestationPayload,
    bytes memory /*_validationPayload*/,
    address /*_txSender*/,
    uint256 /*_value*/
  ) public view override {
    if (!acceptedSchemaIds[_attestationPayload.schemaId]) revert SchemaIdNotAccepted();
  }
}