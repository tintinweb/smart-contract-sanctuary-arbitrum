// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Realm/IRealm.sol";

import "../Manager/ManagerModifier.sol";

contract RealmLock is ReentrancyGuard, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;

  //=======================================
  // Int
  //=======================================
  uint256 public maxLock;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256) public locked;

  //=======================================
  // Modifiers
  //=======================================
  modifier isRealmOwner(uint256 _realmId) {
    _isRealmOwner(_realmId);
    _;
  }

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    uint256 _maxLock
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);

    maxLock = _maxLock;
  }

  //=======================================
  // External
  //=======================================
  function lock(uint256 _realmId, uint256 _hours)
    external
    nonReentrant
    isRealmOwner(_realmId)
  {
    // Hours must be greater than zero
    require(_hours > 0, "RealmLock: Hours must be greater than zero");

    // Check if hours are less than or equal to max allowed
    require(_hours <= maxLock, "RealmLock: Must be below max allowed");

    // Lock
    locked[_realmId] = block.timestamp + (_hours * 3600);
  }

  function unlock(uint256 _realmId)
    external
    nonReentrant
    isRealmOwner(_realmId)
  {
    // Check if locked time has elapsed
    require(block.timestamp > locked[_realmId], "RealmLock: Cannot unlock yet");

    // Unlcok
    locked[_realmId] = 0;
  }

  function isUnlocked(uint256 _realmId) external view returns (bool) {
    return block.timestamp > locked[_realmId];
  }

  //=======================================
  // Admin
  //=======================================
  function updateMaxLock(uint256 _maxLock) external onlyAdmin {
    maxLock = _maxLock;
  }

  //=======================================
  // Internal
  //=======================================
  function _isRealmOwner(uint256 _realmId) internal view {
    require(
      REALM.ownerOf(_realmId) == msg.sender,
      "RealmLock: You do not own this Realm"
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);

  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);
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