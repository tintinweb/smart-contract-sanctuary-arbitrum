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

/**
 * @title   CloneRegistry
 * @author  RedVeil
 * @notice  Registers clones created by `CloneFactory`.
 *
 * Clones get saved on creation via `DeploymentController`.
 * Is used by `VaultController` to check if a target is a registerd clone.
 */
contract CloneRegistry is Owned {
  /*//////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  /// @param _owner `AdminProxy`
  constructor(address _owner) Owned(_owner) {}

  /*//////////////////////////////////////////////////////////////
                          ADD CLONE LOGIC
    //////////////////////////////////////////////////////////////*/

  mapping(address => bool) public cloneExists;
  // TemplateCategory => TemplateId => Clones
  mapping(bytes32 => mapping(bytes32 => address[])) public clones;
  address[] public allClones;

  event CloneAdded(address clone);

  /**
   * @notice Add a clone to the registry. Caller must be owner. (`DeploymentController`)
   * @param templateCategory Category of the template to use.
   * @param templateId Unique Id of the template to use.
   * @param clone Address of the clone to add.
   */
  function addClone(
    bytes32 templateCategory,
    bytes32 templateId,
    address clone
  ) external onlyOwner {
    cloneExists[clone] = true;
    clones[templateCategory][templateId].push(clone);
    allClones.push(clone);

    emit CloneAdded(clone);
  }

  /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

  function getClonesByCategoryAndId(bytes32 templateCategory, bytes32 templateId)
    external
    view
    returns (address[] memory)
  {
    return clones[templateCategory][templateId];
  }

  function getAllClones() external view returns (address[] memory) {
    return allClones;
  }
}