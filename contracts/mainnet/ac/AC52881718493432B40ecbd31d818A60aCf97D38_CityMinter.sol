// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "./ICity.sol";
import "../RealmLock/IRealmLock.sol";
import "../Collectible/ICollectible.sol";
import "../BatchStaker/IBatchStaker.sol";
import "./ICityStorage.sol";

import "../Manager/ManagerModifier.sol";

contract CityMinter is ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  ICity public immutable CITY;
  IRealmLock public immutable REALM_LOCK;
  ICollectible public immutable COLLECTIBLE;
  IBatchStaker public immutable BATCH_STAKER;
  ICityStorage public immutable CITY_STORAGE;
  address public immutable COLLECTIBLE_HOLDER;

  //=======================================
  // Ints
  //=======================================
  uint256 public collectibleCostPerCity = 10;
  uint256 public maxCities = 15;
  uint256 public hoursPerCity = 24;

  //=======================================
  // Arrays
  //=======================================
  uint256[] public cityRequirements;
  uint256[] public cityRequirementAmounts;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256[]) public primeCollectibles;

  //=======================================
  // Events
  //=======================================
  event Minted(uint256 realmId, uint256 cityId, uint256 quantity);
  event CollectiblesUsed(
    uint256 realmId,
    uint256 collectibleId,
    uint256 amount
  );
  event StakedCities(
    uint256 realmId,
    address addr,
    uint256[] cityIds,
    uint256[] amounts
  );
  event UnstakedCities(
    uint256 realmId,
    address addr,
    uint256[] cityIds,
    uint256[] amounts
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    address _collectible,
    address _batchStaker,
    address _cityStorage,
    address _city,
    address _realmLock,
    address _collectibleHolder,
    uint256[][] memory _primeCollectible,
    uint256[] memory _cityRequirements,
    uint256[] memory _cityRequirementAmounts
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    COLLECTIBLE = ICollectible(_collectible);
    BATCH_STAKER = IBatchStaker(_batchStaker);
    CITY_STORAGE = ICityStorage(_cityStorage);
    CITY = ICity(_city);
    REALM_LOCK = IRealmLock(_realmLock);
    COLLECTIBLE_HOLDER = _collectibleHolder;

    primeCollectibles[0] = _primeCollectible[0];
    primeCollectibles[1] = _primeCollectible[1];
    primeCollectibles[2] = _primeCollectible[2];
    primeCollectibles[3] = _primeCollectible[3];
    primeCollectibles[4] = _primeCollectible[4];
    primeCollectibles[5] = _primeCollectible[5];
    primeCollectibles[6] = _primeCollectible[6];

    cityRequirements = _cityRequirements;
    cityRequirementAmounts = _cityRequirementAmounts;
  }

  //=======================================
  // External
  //=======================================
  function mint(
    uint256 _realmId,
    uint256[] calldata _collectibleIds,
    uint256[] calldata _cityIds,
    uint256[] calldata _quantities
  ) external nonReentrant whenNotPaused {
    // Check if Realm owner
    require(
      REALM.ownerOf(_realmId) == msg.sender,
      "CityMinter: Must be Realm owner"
    );

    uint256 totalQuantity;

    for (uint256 j = 0; j < _cityIds.length; j++) {
      uint256 collectibleId = _collectibleIds[j];
      uint256 cityId = _cityIds[j];
      uint256 desiredQuantity = _quantities[j];

      // Check collectibleId is prime collectible
      _checkPrimeCollectibles(cityId, collectibleId);

      // Check city requirements
      _checkCityRequirements(_realmId, cityId);

      // Mint
      _mint(_realmId, cityId, desiredQuantity);

      // Add to quantity
      totalQuantity = totalQuantity + desiredQuantity;

      uint256 collectibleAmount = collectibleCostPerCity * desiredQuantity;

      // Burn collectibles
      COLLECTIBLE.safeTransferFrom(
        msg.sender,
        COLLECTIBLE_HOLDER,
        collectibleId,
        collectibleAmount,
        ""
      );

      emit CollectiblesUsed(_realmId, collectibleId, collectibleAmount);
    }

    // Check if totalQuantity is below max cities
    require(
      totalQuantity <= maxCities,
      "CityMinter: Max cities per transaction reached"
    );

    // Build
    CITY_STORAGE.build(_realmId, totalQuantity * hoursPerCity);
  }

  function stakeBatch(
    uint256[] calldata _realmIds,
    uint256[][] calldata _cityIds,
    uint256[][] calldata _amounts
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];
      uint256[] memory cityIds = _cityIds[j];
      uint256[] memory amounts = _amounts[j];

      BATCH_STAKER.stakeBatchFor(
        msg.sender,
        address(CITY),
        realmId,
        cityIds,
        amounts
      );

      emit StakedCities(realmId, address(CITY), cityIds, amounts);
    }
  }

  function unstakeBatch(
    uint256[] calldata _realmIds,
    uint256[][] calldata _cityIds,
    uint256[][] calldata _amounts
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];

      // Check if Realm is locked
      require(REALM_LOCK.isUnlocked(realmId), "CityMinter: Realm is locked");

      uint256[] memory cityIds = _cityIds[j];
      uint256[] memory amounts = _amounts[j];

      BATCH_STAKER.unstakeBatchFor(
        msg.sender,
        address(CITY),
        realmId,
        cityIds,
        amounts
      );

      emit UnstakedCities(realmId, address(CITY), cityIds, amounts);
    }
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateCollectibleCostPerCity(uint256 _collectibleCostPerCity)
    external
    onlyAdmin
  {
    collectibleCostPerCity = _collectibleCostPerCity;
  }

  function updateMaxCities(uint256 _maxCities) external onlyAdmin {
    maxCities = _maxCities;
  }

  function updateHoursPerCity(uint256 _hoursPerCity) external onlyAdmin {
    hoursPerCity = _hoursPerCity;
  }

  function updateCityRequirements(uint256[] calldata _cityRequirements)
    external
    onlyAdmin
  {
    cityRequirements = _cityRequirements;
  }

  function updateCityRequirementAmounts(
    uint256[] calldata _cityRequirementAmounts
  ) external onlyAdmin {
    cityRequirementAmounts = _cityRequirementAmounts;
  }

  //=======================================
  // Internal
  //=======================================
  function _checkCityRequirements(uint256 _realmId, uint256 _cityId)
    internal
    view
  {
    // Town does not require any staked cities
    if (_cityId == 0) return;

    // Check they have right amount of staked cities
    require(
      BATCH_STAKER.hasStaked(
        _realmId,
        address(CITY),
        cityRequirements[_cityId],
        cityRequirementAmounts[_cityId]
      ),
      "CityMinter: Don't have the required Cities staked"
    );
  }

  function _checkPrimeCollectibles(uint256 _cityId, uint256 _collectibleId)
    internal
    view
  {
    bool invalid;

    for (uint256 j = 0; j < primeCollectibles[_cityId].length; j++) {
      // Check collectibleId matches prime collectible IDs
      if (_collectibleId == primeCollectibles[_cityId][j]) {
        invalid = false;
        break;
      }

      invalid = true;
    }

    require(
      !invalid,
      "CityMinter: Collectible doesn't match City requirements"
    );
  }

  function _mint(
    uint256 _realmId,
    uint256 _cityId,
    uint256 _desiredQuantity
  ) internal {
    // Mint
    CITY.mintFor(msg.sender, _cityId, _desiredQuantity);

    // Add Nourishment credits
    CITY_STORAGE.addNourishmentCredit(_realmId, _desiredQuantity);

    emit Minted(_realmId, _cityId, _desiredQuantity);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

interface ICity {
  function mintFor(
    address _for,
    uint256 _id,
    uint256 _amount
  ) external;

  function mintBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] calldata ids, uint256[] calldata amounts)
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmLock {
  function lock(uint256 _realmId, uint256 _hours) external;

  function unlock(uint256 _realmId) external;

  function isUnlocked(uint256 _realmId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICollectible {
  function mintFor(
    address _for,
    uint256 _id,
    uint256 _amount
  ) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _ids,
    uint256 _amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchStaker {
  function stakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function unstakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function hasStaked(
    uint256 _realmId,
    address _addr,
    uint256 _id,
    uint256 _count
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICityStorage {
  function build(uint256 _realmId, uint256 _hours) external;

  function addNourishmentCredit(uint256 _realmId, uint256 _amount) external;

  function canBuild(uint256 _realmId) external view returns (bool);
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

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}