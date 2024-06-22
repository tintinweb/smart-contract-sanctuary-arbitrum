// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import { IAnimaChamberData } from "./IAnimaChamberData.sol";
import { ManagerModifier } from "../Manager/ManagerModifier.sol";

error InvalidToken(uint _tokenId);
error AlreadyMinted(uint _tokenId);
error InvalidStakingAmount(uint _tokenId);

contract AnimaChamberData is IAnimaChamberData, ManagerModifier {
  //=======================================
  // Storage
  //=======================================
  mapping(uint256 => uint256) public STAKED_AMOUNTS;
  mapping(uint256 => uint256) public MINT_TIMESTAMPS;

  //=======================================
  // Events
  //=======================================
  event Staked(uint chamberId, uint256 amount);
  event Unstaked(uint chamberId, uint256 amount);

  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // Public
  //=======================================
  function stakedAnima(uint256 _tokenId) public view returns (uint256) {
    return STAKED_AMOUNTS[_tokenId];
  }

  function mintedAt(uint256 _tokenId) public view returns (uint256 timestamp) {
    timestamp = MINT_TIMESTAMPS[_tokenId];
    if (timestamp == 0 || STAKED_AMOUNTS[_tokenId] == 0) {
      revert InvalidToken(_tokenId);
    }
  }

  function stakedAnimaBatch(
    uint256[] calldata _tokenId
  ) external view returns (uint256[] memory result) {
    result = new uint256[](_tokenId.length);
    for (uint i = 0; i < _tokenId.length; i++) {
      result[i] = stakedAnima(_tokenId[i]);
    }
  }

  function setStakedAnima(
    uint256 _tokenId,
    uint256 _amount
  ) external onlyMinter {
    if (_amount <= 0) {
      revert InvalidStakingAmount(_amount);
    }
    if (STAKED_AMOUNTS[_tokenId] != 0) {
      revert AlreadyMinted(_tokenId);
    }

    emit Staked(_tokenId, _amount);

    STAKED_AMOUNTS[_tokenId] = _amount;
    MINT_TIMESTAMPS[_tokenId] = block.timestamp;
  }

  function setMintTimestamp(
    uint256 _tokenId,
    uint256 _timestamp
  ) external onlyMinter {
    if (STAKED_AMOUNTS[_tokenId] == 0) {
      revert InvalidToken(_tokenId);
    }

    MINT_TIMESTAMPS[_tokenId] = _timestamp;
  }

  function getAndResetStakedAnima(
    uint _tokenId
  ) external onlyMinter returns (uint256 result) {
    result = stakedAnima(_tokenId);

    emit Unstaked(_tokenId, result);

    STAKED_AMOUNTS[_tokenId] -= result;
    MINT_TIMESTAMPS[_tokenId] = 0;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaChamberData {
  function stakedAnima(uint256 _tokenId) external view returns (uint256);

  function mintedAt(uint256 _tokenId) external view returns (uint256);

  function stakedAnimaBatch(
    uint256[] calldata _tokenId
  ) external view returns (uint256[] memory result);

  function setStakedAnima(uint256 _tokenId, uint256 _amount) external;

  function getAndResetStakedAnima(
    uint _tokenId
  ) external returns (uint256 result);
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

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}