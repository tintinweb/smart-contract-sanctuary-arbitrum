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

import { Owned } from "../utils/Owned.sol";
import { Template } from "../interfaces/vault/ITemplateRegistry.sol";

/**
 * @title   TemplateRegistry
 * @author  RedVeil
 * @notice  Adds Templates to be used for creating new clones.
 *
 * Templates are used by the `CloneFactory` to create new clones.
 * Templates can be added permissionlessly via `DeploymentController`.
 * Templates can be endorsed by the DAO via `VaultController`.
 */
contract TemplateRegistry is Owned {
  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  /// @param _owner `AdminProxy`
  constructor(address _owner) Owned(_owner) {}

  /*//////////////////////////////////////////////////////////////
                          TEMPLATE LOGIC
    //////////////////////////////////////////////////////////////*/

  // TemplateCategory => TemplateId => Template
  mapping(bytes32 => mapping(bytes32 => Template)) public templates;
  mapping(bytes32 => bytes32[]) public templateIds;
  mapping(bytes32 => bool) public templateExists;

  mapping(bytes32 => bool) public templateCategoryExists;
  bytes32[] public templateCategories;

  event TemplateCategoryAdded(bytes32 templateCategory);
  event TemplateAdded(bytes32 templateCategory, bytes32 templateId, address implementation);
  event TemplateUpdated(bytes32 templateCategory, bytes32 templateId);

  error KeyNotFound(bytes32 templateCategory);
  error TemplateExists(bytes32 templateId);
  error TemplateCategoryExists(bytes32 templateCategory);

  /**
   * @notice Adds a new templateCategory to the registry. Caller must be owner. (`DeploymentController`)
   * @param templateCategory A new category of templates.
   * @dev The basic templateCategories will be added via `VaultController` they are ("Vault", "Adapter", "Strategy" and "Staking").
   * @dev Allows for new categories to be added in the future.
   */
  function addTemplateCategory(bytes32 templateCategory) external onlyOwner {
    if (templateCategoryExists[templateCategory]) revert TemplateCategoryExists(templateCategory);

    templateCategoryExists[templateCategory] = true;
    templateCategories.push(templateCategory);

    emit TemplateCategoryAdded(templateCategory);
  }

  /**
   * @notice Adds a new template to the registry.
   * @param templateCategory TemplateCategory of the new template.
   * @param templateId Unique TemplateId of the new template.
   * @param template Contains the implementation address and necessary informations to clone the implementation.
   */
  function addTemplate(bytes32 templateCategory, bytes32 templateId, Template memory template) external onlyOwner {
    if (!templateCategoryExists[templateCategory]) revert KeyNotFound(templateCategory);
    if (templateExists[templateId]) revert TemplateExists(templateId);

    template.endorsed = false;
    templates[templateCategory][templateId] = template;

    templateIds[templateCategory].push(templateId);
    templateExists[templateId] = true;

    emit TemplateAdded(templateCategory, templateId, template.implementation);
  }

  /*//////////////////////////////////////////////////////////////
                          ENDORSEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

  event TemplateEndorsementToggled(
    bytes32 templateCategory,
    bytes32 templateId,
    bool oldEndorsement,
    bool newEndorsement
  );

  /**
   * @notice Toggles the endorsement of a template. Caller must be owner. (`DeploymentController`)
   * @param templateCategory TemplateCategory of the template to endorse.
   * @param templateId TemplateId of the template to endorse.
   * @dev A template must be endorsed before it can be used for clones.
   * @dev Only the DAO can endorse templates via `VaultController`.
   */
  function toggleTemplateEndorsement(bytes32 templateCategory, bytes32 templateId) external onlyOwner {
    if (!templateCategoryExists[templateCategory]) revert KeyNotFound(templateCategory);
    if (!templateExists[templateId]) revert KeyNotFound(templateId);

    bool oldEndorsement = templates[templateCategory][templateId].endorsed;
    templates[templateCategory][templateId].endorsed = !oldEndorsement;

    emit TemplateEndorsementToggled(templateCategory, templateId, oldEndorsement, !oldEndorsement);
  }

  /*//////////////////////////////////////////////////////////////
                          TEMPLATE VIEW LOGIC
    //////////////////////////////////////////////////////////////*/

  function getTemplateCategories() external view returns (bytes32[] memory) {
    return templateCategories;
  }

  function getTemplateIds(bytes32 templateCategory) external view returns (bytes32[] memory) {
    return templateIds[templateCategory];
  }

  function getTemplate(bytes32 templateCategory, bytes32 templateId) external view returns (Template memory) {
    return templates[templateCategory][templateId];
  }
}