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
import { Template } from "./ITemplateRegistry.sol";

interface ICloneFactory is IOwned {
  function deploy(Template memory template, bytes memory data) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { IOwned } from "../IOwned.sol";

interface ICloneRegistry is IOwned {
  function cloneExists(address clone) external view returns (bool);

  function addClone(
    bytes32 templateCategory,
    bytes32 templateId,
    address clone
  ) external;
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

import { Owned } from "../utils/Owned.sol";
import { IOwned } from "../interfaces/IOwned.sol";
import { ICloneFactory } from "../interfaces/vault/ICloneFactory.sol";
import { ICloneRegistry } from "../interfaces/vault/ICloneRegistry.sol";
import { ITemplateRegistry, Template } from "../interfaces/vault/ITemplateRegistry.sol";

/**
 * @title   DeploymentController
 * @author  RedVeil
 * @notice  Bundles contracts for creating and registering clones.
 * @dev     Allows interacting with them via a single transaction.
 */
contract DeploymentController is Owned {
  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  ICloneFactory public cloneFactory;
  ICloneRegistry public cloneRegistry;
  ITemplateRegistry public templateRegistry;

  /**
   * @notice Creates `DeploymentController`
   * @param _owner `AdminProxy`
   * @param _cloneFactory Creates clones.
   * @param _cloneRegistry Keeps track of new clones.
   * @param _templateRegistry Registry of templates used for deployments.
   * @dev Needs to call `acceptDependencyOwnership()` after the deployment.
   */
  constructor(
    address _owner,
    ICloneFactory _cloneFactory,
    ICloneRegistry _cloneRegistry,
    ITemplateRegistry _templateRegistry
  ) Owned(_owner) {
    cloneFactory = _cloneFactory;
    cloneRegistry = _cloneRegistry;
    templateRegistry = _templateRegistry;
  }

  /*//////////////////////////////////////////////////////////////
                          TEMPLATE LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Adds a new category for templates. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param templateCategory A new template category.
   * @dev (See TemplateRegistry for more details)
   */
  function addTemplateCategory(bytes32 templateCategory) external onlyOwner {
    templateRegistry.addTemplateCategory(templateCategory);
  }

  /**
   * @notice Adds a new category for templates.
   * @param templateCategory Category of the new template.
   * @param templateId Unique Id of the new template.
   * @param template New template (See ITemplateRegistry for more details)
   * @dev (See TemplateRegistry for more details)
   */
  function addTemplate(
    bytes32 templateCategory,
    bytes32 templateId,
    Template calldata template
  ) external {
    templateRegistry.addTemplate(templateCategory, templateId, template);
  }

  /**
   * @notice Toggles the endorsement of a template. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param templateCategory TemplateCategory of the template to endorse.
   * @param templateId TemplateId of the template to endorse.
   * @dev (See TemplateRegistry for more details)
   */
  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external onlyOwner {
    templateRegistry.toggleTemplateEndorsement(templateCategory, templateId);
  }

  /*//////////////////////////////////////////////////////////////
                          DEPLOY LOGIC
    //////////////////////////////////////////////////////////////*/

  error NotEndorsed(bytes32 templateId);

  /**
   * @notice Clones an implementation and initializes the clone. Caller must be owner.  (`VaultController` via `AdminProxy`)
   * @param templateCategory Category of the template to use.
   * @param templateId Unique Id of the template to use.
   * @param data The data to pass to the clone's initializer.
   * @dev Uses a template from `TemplateRegistry`. The template must be endorsed.
   * @dev Deploys and initializes a clone using `CloneFactory`.
   * @dev Registers the clone in `CloneRegistry`.
   */
  function deploy(
    bytes32 templateCategory,
    bytes32 templateId,
    bytes calldata data
  ) external onlyOwner returns (address clone) {
    Template memory template = templateRegistry.getTemplate(templateCategory, templateId);

    if (!template.endorsed) revert NotEndorsed(templateId);

    clone = cloneFactory.deploy(template, data);

    cloneRegistry.addClone(templateCategory, templateId, clone);
  }

  /*//////////////////////////////////////////////////////////////
                          OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Nominates a new owner for dependency contracts. Caller must be owner. (`VaultController` via `AdminProxy`)
   * @param _owner The new `DeploymentController` implementation
   */
  function nominateNewDependencyOwner(address _owner) external onlyOwner {
    IOwned(address(cloneFactory)).nominateNewOwner(_owner);
    IOwned(address(cloneRegistry)).nominateNewOwner(_owner);
    IOwned(address(templateRegistry)).nominateNewOwner(_owner);
  }

  /**
   * @notice Accept ownership of dependency contracts.
   * @dev Must be called after construction.
   */
  function acceptDependencyOwnership() external {
    IOwned(address(cloneFactory)).acceptOwnership();
    IOwned(address(cloneRegistry)).acceptOwnership();
    IOwned(address(templateRegistry)).acceptOwnership();
  }
}