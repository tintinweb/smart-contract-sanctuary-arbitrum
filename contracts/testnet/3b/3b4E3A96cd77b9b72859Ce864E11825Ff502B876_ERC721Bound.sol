// SPDX-License-Identifier: MIT

import "./IERC721Bound.sol";

import "../Manager/ManagerModifier.sol";

pragma solidity ^0.8.4;

contract ERC721Bound is IERC721Bound, ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => mapping(uint256 => bool)) public unbound;

  //=======================================
  // Events
  //=======================================
  event Unbounded(address _addr, uint256 tokenId);
  event Bounded(address _addr, uint256 tokenId);

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================
  function isUnbound(address _addr, uint256 _tokenId)
    external
    view
    override
    returns (bool)
  {
    return unbound[_addr][_tokenId] == true;
  }

  function unbind(address[] calldata _addresses, uint256[] calldata _tokenIds)
    external
    override
    onlyBinder
  {
    for (uint256 j = 0; j < _tokenIds.length; j++) {
      address addr = _addresses[j];
      uint256 tokenId = _tokenIds[j];

      unbound[addr][tokenId] = true;

      emit Unbounded(addr, tokenId);
    }
  }

  function unbind(address _addr, uint256 _tokenId)
    external
    override
    onlyBinder
  {
    unbound[_addr][_tokenId] = true;

    emit Unbounded(_addr, _tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721Bound {
  function unbind(address[] calldata _addresses, uint256[] calldata _tokenIds)
    external;

  function unbind(address _addr, uint256 _tokenId) external;

  function isUnbound(address _addr, uint256 _tokenId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}