// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

pragma solidity ^0.8.17;

interface IBrokenTokenHandler {
  function handleBrokenToken(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint _brokenEntityTokenId,
    uint _brokenAmount
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint[] calldata _brokenEntityTokenIds,
    uint[] calldata _brokenAmounts
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _brokenEntityAddress,
    uint[][] calldata _brokenEntityTokenIds,
    uint[][] calldata _brokenAmounts
  ) external;
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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomPicker {
  function addToQueue(uint256 queueType, uint256 subQueue, uint256 owner, uint256 number) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function useRandomizer(
    uint256 queueType,
    uint256 subQueue,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase);

  function useRandomizerBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase);

  function getQueueSizes(
    uint256 queueType,
    uint256[] calldata subQueues
  ) external view returns (uint256[] memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../Manager/ManagerModifier.sol";
import "../AdventurerEquipment/IBrokenEquipmentHandler.sol";
import "../RandomPicker/IRandomPicker.sol";

contract StructureBreakHandler is Pausable, ManagerModifier, IBrokenTokenHandler {
  IRandomPicker public RANDOM_PICKER;
  address public REALM_ADDRESS;

  constructor(
    address _manager,
    address _randomPicker,
    address _realmAddress
  ) ManagerModifier(_manager) {
    RANDOM_PICKER = IRandomPicker(_randomPicker);
    REALM_ADDRESS = _realmAddress;
  }

  function handleBrokenToken(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint _brokenEntityTokenId,
    uint _brokenAmount
  ) external onlyManager {
    if (_ownerAddress != REALM_ADDRESS) {
      return;
    }
    RANDOM_PICKER.removeFromQueue(
      uint256(uint160(_brokenEntityAddress)),
      _brokenEntityTokenId,
      _ownerTokenId,
      _brokenAmount
    );
  }

  function handleBrokenTokenBatch(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint[] calldata _brokenEntityTokenIds,
    uint[] calldata _brokenAmounts
  ) external onlyManager {
    if (_ownerAddress != REALM_ADDRESS) {
      return;
    }

    RANDOM_PICKER.removeFromQueueBatch(
      uint256(uint160(_brokenEntityAddress)),
      _brokenEntityTokenIds,
      _ownerTokenId,
      _brokenAmounts
    );
  }

  function handleBrokenTokenBatch(
    address _breakerContract,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _brokenEntityAddress,
    uint[][] memory _brokenEntityTokenIds,
    uint[][] memory _brokenAmounts
  ) external onlyManager {
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      if (_ownerAddresses[i] != REALM_ADDRESS) {
        _brokenEntityTokenIds[i] = new uint[](0);
        _brokenAmounts[i] = new uint[](0);
      }
    }

    RANDOM_PICKER.removeFromQueueBatch(
      uint256(uint160(_brokenEntityAddress)),
      _brokenEntityTokenIds,
      _ownerTokenIds,
      _brokenAmounts
    );
  }
}