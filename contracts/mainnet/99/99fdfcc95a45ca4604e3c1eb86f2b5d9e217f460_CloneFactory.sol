// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IOwned {
  function owner() external view returns (address);

  function nominatedOwner() external view returns (address);

  function nominateNewOwner(address owner) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

/// @notice Template used for creating new clones
struct Template {
  /// @Notice Cloneable implementation address
  address implementation;
  /// @Notice implementations can only be cloned if endorsed
  bool endorsed;
  /// @Notice Optional - Metadata CID which can be used by the frontend to add informations to a vault/adapter...
  string metadataCid;
  /// @Notice If true, the implementation will require an init data to be passed to the clone function
  bool requiresInitData;
  /// @Notice Optional - Address of an registry which can be used in an adapter initialization
  address registry;
  /// @Notice Optional - Only used by Strategies. EIP-165 Signatures of an adapter required by a strategy
  bytes4[8] requiredSigs;
}

interface ITemplateRegistry is IOwned {
  function templates(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function templateCategoryExists(bytes32 templateCategory) external view returns (bool);

  function templateExists(bytes32 templateId) external view returns (bool);

  function getTemplateCategories() external view returns (bytes32[] memory);

  function getTemplate(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory);

  function getTemplateIds(bytes32 templateCategory) external view returns (bytes32[] memory);

  function addTemplate(
    bytes32 templateType,
    bytes32 templateId,
    Template memory template
  ) external;

  function addTemplateCategory(bytes32 templateCategory) external;

  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
  address public owner;
  address public nominatedOwner;

  constructor(address _owner) {
    require(_owner != address(0), "Owner address cannot be 0");
    owner = _owner;
    emit OwnerChanged(address(0), _owner);
  }

  function nominateNewOwner(address _owner) external virtual onlyOwner {
    nominatedOwner = _owner;
    emit OwnerNominated(_owner);
  }

  function acceptOwnership() external virtual {
    require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
    emit OwnerChanged(owner, nominatedOwner);
    owner = nominatedOwner;
    nominatedOwner = address(0);
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    require(msg.sender == owner, "Only the contract owner may perform this action");
  }

  event OwnerNominated(address newOwner);
  event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";
import { Owned } from "../utils/Owned.sol";
import { Template } from "../interfaces/vault/ITemplateRegistry.sol";

/**
 * @title   CloneFactory
 * @author  RedVeil
 * @notice  Creates clones from a template and initializes it.
 *
 * Clones get created via the `DeploymentController`.
 */
contract CloneFactory is Owned {
  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  /// @param _owner `AdminProxy`
  constructor(address _owner) Owned(_owner) {}

  /*//////////////////////////////////////////////////////////////
                          DEPLOY LOGIC
    //////////////////////////////////////////////////////////////*/

  event Deployment(address indexed clone);

  error DeploymentInitFailed();
  error NotEndorsed(bytes32 templateKey);

  /**
   * @notice Clones an implementation and initializes the clone. Caller must be owner. (`DeploymentController`)
   * @param template The template to use for the deployment. (See TemplateRegistry for more details)
   * @param data The data to pass to the clone's initializer.
   */
  function deploy(Template calldata template, bytes calldata data) external onlyOwner returns (address clone) {
    clone = Clones.clone(template.implementation);

    bool success = true;
    if (template.requiresInitData) (success, ) = clone.call(data);

    if (!success) revert DeploymentInitFailed();

    emit Deployment(clone);
  }
}