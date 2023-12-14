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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

uint64 constant DAILY_EPOCH_DURATION = 1 days;
uint64 constant DAILY_EPOCH_OFFSET = 0 hours;

uint64 constant HOURLY_EPOCH_DURATION = 1 hours;
uint64 constant NO_OFFSET = 0 hours;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;
uint256 constant ACTION_ADVENTURER_ANIMA_REGENERATION = 1006;
uint256 constant ACTION_ADVENTURER_BATTLE_V3_OPPONENT = 1007;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM = 2001;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM = 2002;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM_SHARD = 2011;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM_SHARD = 2012;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL_SHARD = 2021;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL_SHARD = 2022;

uint256 constant ACTION_ARMORY_STAKE_LAB = 2031;
uint256 constant ACTION_ARMORY_UNSTAKE_LAB = 2032;

uint256 constant ACTION_ARMORY_STAKE_COLLECTIBLE = 2041;
uint256 constant ACTION_ARMORY_UNSTAKE_COLLECTIBLE = 2042;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL = 2051;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL = 2052;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Unauthorized(address _tokenAddr, uint256 _tokenId);
error EntityLocked(address _tokenAddr, uint256 _tokenId, uint _lockedUntil);
error MinEpochsTooLow(uint256 _minEpochs);
error InsufficientEpochSpan(
  uint256 _minEpochs,
  uint256 _epochs,
  address _tokenAddr,
  uint256 _tokenId
);
error DuplicateActionAttempt(address _tokenAddr, uint256 _tokenId);

interface IActionPermit {
  // Reverts if no permissions or action was already taken in the last _minEpochs
  function checkAndMarkActionComplete(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external;

  // Marks action complete even if already completed
  function forceMarkActionComplete(address _tokenAddr, uint256 _tokenId, uint256 _action) external;

  // Reverts if no permissions
  function checkPermissions(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof,
    uint256 _action
  ) external view;

  function checkOwner(
    address _tokenAddr,
    uint256 _tokenId,
    bytes32[] calldata _proof
  ) external view returns (address);

  function checkPermissionsMany(
    address _sender,
    address[] calldata _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address _tokenAddr,
    uint256[] calldata _tokenId,
    bytes32[][] calldata _proofs,
    uint256 _action
  ) external view;

  function checkOwnerBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs
  ) external view returns (address[] memory);

  // Reverts if action already taken this epoch
  function checkIfEnoughEpochsElapsed(
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;

  function checkIfEnoughEpochsElapsedBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256 _minEpochs,
    uint128 _epochConfig
  ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(address _addr, uint256 _id, uint256 _archetype) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant ADV_BASE_TRAIT_XP = 1;
  uint256 public constant ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant ADV_BASE_TRAIT_HP = 8;
  uint256 public constant ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant ADV_AOV_TRAIT_PROFESSION = 3;

  function traitNames() public pure returns (string[9] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "HP"
    ];
  }

  function traitName(uint256 traitId) public pure returns (string memory) {
    return traitNames()[traitId];
  }

  struct TraitBonus {
    uint256 traitId;
    uint256 traitValue;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAnima is IERC20 {
  function mintFor(address _for, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

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

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Action/Actions.sol";
import "../Adventurer/TraitConstants.sol";
import "../lib/FloatingPointConstants.sol";
import "./IRenown.sol";
import "./IFocus.sol";
import "./IActivityRenown.sol";
import "../Action/IActionPermit.sol";
import "../Manager/ManagerModifier.sol";
import "../Adventurer/IAdventurerData.sol";
import "../Anima/IAnima.sol";

struct AnimaRegenerationConfig {
  int64 minimumRenownPerLevel;
  int64 renownCapPerLevel;
  uint baseAnimaAtCap;
  uint aboveCapLinearMultiplier;
}

contract AnimaRegeneration is ReentrancyGuard, ManagerModifier, Pausable {
  error InvalidArrayOrder(uint index);
  error InvalidRequest(address _adventurerAddress, uint _adventurerId, uint renownSpend);
  error InsufficientRenown(
    address _adventurerAddress,
    uint _adventurerId,
    uint renownSpend,
    int currentRenown
  );

  event InsufficientRenownToRegenerate(
    address _adventurerAddress,
    uint _adventurerId,
    int currentRenown
  );
  event AnimaRegenerated(address _adventurerAddress, uint _adventurerId, uint level, uint anima);

  IFocus public FOCUS;
  IRenown public RENOWN;
  IAdventurerData public ADVENTURER_DATA;
  IActionPermit public ACTION_PERMIT;
  IAnima public ANIMA;
  address public AOV;

  AnimaRegenerationConfig public config;

  constructor(
    address _manager,
    address _focus,
    address _renown,
    address _adventurerData,
    address _actionPermit,
    address _aov,
    address _anima
  ) ManagerModifier(_manager) {
    FOCUS = IFocus(_focus);
    RENOWN = IRenown(_renown);
    ADVENTURER_DATA = IAdventurerData(_adventurerData);
    ACTION_PERMIT = IActionPermit(_actionPermit);
    AOV = _aov;
    ANIMA = IAnima(_anima);
    config.minimumRenownPerLevel = int64(SIGNED_ONE_HUNDRED / 10);
    config.renownCapPerLevel = int64(SIGNED_ONE_HUNDRED);
    config.baseAnimaAtCap = 10 ether;
    config.aboveCapLinearMultiplier = ONE_HUNDRED;
  }

  struct CalculationMemory {
    uint totalAnima;
    address lastAddress;
    int256 lastTokenId;
    uint lastAnima;
    uint[] levels;
    int[] renown;
    int[] focus;
  }

  function regenerate(
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerIds,
    uint256[] calldata _percentagesToSpend,
    bytes32[][] calldata _proofs
  ) external whenNotPaused nonReentrant {
    require(msg.sender == tx.origin, "Regeneration is not allowed through another contract");

    ACTION_PERMIT.checkPermissionsMany(
      msg.sender,
      _adventurerAddresses,
      _adventurerIds,
      _proofs,
      ACTION_ADVENTURER_ANIMA_REGENERATION
    );

    CalculationMemory memory mem;
    // This is first the current focus/renown, then after the loop it's used as the delta that's used to regenerate anima
    mem.focus = FOCUS.currentFocusBatch(_adventurerAddresses, _adventurerIds);
    mem.levels = new uint[](_adventurerAddresses.length);
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      mem.levels[i] = ADVENTURER_DATA.aov(
        _adventurerAddresses[i],
        _adventurerIds[i],
        traits.ADV_AOV_TRAIT_LEVEL
      );
    }
    mem.renown = RENOWN.currentRenownBatch(_adventurerAddresses, _adventurerIds, mem.levels);
    AnimaRegenerationConfig memory cfg = config;
    for (uint i = 0; i < _adventurerAddresses.length; i++) {
      if (_adventurerAddresses[i] > mem.lastAddress) {
        mem.lastTokenId = -1;
      }

      if (_adventurerAddresses[i] < mem.lastAddress || int(_adventurerIds[i]) <= mem.lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      mem.lastAddress = _adventurerAddresses[i];
      mem.lastTokenId = int(_adventurerIds[i]);

      (mem.focus[i], mem.renown[i], mem.lastAnima) = _regenerateInternal(
        _adventurerAddresses[i],
        _adventurerIds[i],
        mem.levels[i],
        mem.renown[i],
        _percentagesToSpend[i],
        mem.focus[i],
        cfg
      );
      mem.totalAnima += mem.lastAnima;
    }
    ANIMA.mintFor(msg.sender, mem.totalAnima);
    RENOWN.changeBatch(_adventurerAddresses, _adventurerIds, mem.levels, mem.renown);
    FOCUS.spendFocusBatch(_adventurerAddresses, _adventurerIds, mem.focus);
  }

  function estimateAnima(
    uint _level,
    int _renown,
    int _focus
  ) external view returns (uint availableAnima, int renownDelta) {
    return _calculateAvailableAnima(_level, _renown, _focus, config);
  }

  function _calculateAvailableAnima(
    uint _level,
    int _renown,
    int _focus,
    AnimaRegenerationConfig memory cfg
  ) internal pure returns (uint availableAnima, int renownDelta) {
    if (_focus > SIGNED_ONE_HUNDRED) {
      _focus = SIGNED_ONE_HUNDRED;
    }
    if (_focus < 0) {
      _focus = 0;
    }

    int minRenown = int(_level) * cfg.minimumRenownPerLevel;
    if (_focus <= 0 || _renown < minRenown) {
      return (0, 0);
    }
    renownDelta = -(_renown - minRenown);

    int focusAdjustedRenown = ((SIGNED_ONE_HUNDRED * (_renown - minRenown)) / _focus);
    int cap = int(_level) * int(cfg.renownCapPerLevel);
    int cappedRenown = focusAdjustedRenown > cap ? cap : focusAdjustedRenown;
    availableAnima = (cfg.baseAnimaAtCap * uint(cappedRenown)) / uint(cap);
    if (focusAdjustedRenown > cap) {
      availableAnima +=
        (cfg.aboveCapLinearMultiplier * availableAnima * uint(focusAdjustedRenown - cap)) /
        uint(focusAdjustedRenown * SIGNED_ONE_HUNDRED);
    }
    availableAnima = (availableAnima * uint(_focus)) / ONE_HUNDRED;
  }

  function _regenerateInternal(
    address _adventurerAddress,
    uint _adventurerId,
    uint level,
    int _currentRenown,
    uint _percentageToSpend,
    int _focus,
    AnimaRegenerationConfig memory cfg
  ) internal returns (int focusSpent, int renownDelta, uint animaGained) {
    if (_percentageToSpend > ONE_HUNDRED) {
      revert InvalidRequest(_adventurerAddress, _adventurerId, _percentageToSpend);
    }

    focusSpent = (_focus * int(_percentageToSpend)) / SIGNED_ONE_HUNDRED;
    (animaGained, renownDelta) = _calculateAvailableAnima(level, _currentRenown, _focus, cfg);
    if (_currentRenown + renownDelta < 0) {
      emit InsufficientRenownToRegenerate(_adventurerAddress, _adventurerId, _currentRenown);
      return (0, 0, 0);
    }
    animaGained = ((animaGained * _percentageToSpend) / ONE_HUNDRED);
    if (_adventurerAddress != AOV) {
      animaGained /= 5;
    }
    renownDelta = ((renownDelta * int(_percentageToSpend)) / SIGNED_ONE_HUNDRED);
    if (animaGained > 0) {
      if (focusSpent == 0) {
        focusSpent++;
      }
      if (renownDelta == 0) {
        renownDelta--;
      }
    }
    emit AnimaRegenerated(_adventurerAddress, _adventurerId, level, animaGained);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IActivityRenown {
  function markActive(
    address _sender,
    address[] calldata _adventurerAddresses,
    uint256[] calldata _adventurerTokenIds,
    uint[] calldata levels
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

interface IFocus is IEpochConfigurable {
  error InsufficientFocus(
    address adventurerAddress,
    uint adventurerId,
    int64 spentFocus,
    int64 currentFocus
  );

  function currentFocus(address _adventurerAddress, uint _adventurerId) external view returns (int);

  function currentFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (int[] memory result);

  function isFocusedThisEpoch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external view returns (bool[] memory result);

  function setCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _newValues
  ) external;

  function setCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _newValue
  ) external;

  function addToCounterBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _addValues
  ) external;

  function addToCounterBatchSingleValue(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int64 _addValue
  ) external;

  function markFocusedBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds
  ) external;

  function spendFocusBatch(
    address[] calldata _adventurerAddresses,
    uint[] calldata _adventurerIds,
    int[] calldata _spendings
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenown {
  event RenownInitialized(address adventurerAddress, uint adventurerId, uint level, int baseAmount);
  event RenownChange(address adventurerAddress, uint adventurerId, uint level, int delta);

  // All time Renown
  function currentRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _level
  ) external view returns (int);

  function currentRenowns(
    address _tokenAddress1,
    uint256 _tokenId1,
    uint _level1,
    address _tokenAddress2,
    uint256 _tokenId2,
    uint _level2
  ) external view returns (int, int);

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels
  ) external view returns (int[] memory);

  function forceInitIfNeeded(
    address _tokenAddress,
    uint256 _tokenId,
    uint _level
  ) external returns (int);

  function change(address _tokenAddress, uint256 _tokenId, uint _level, int _delta) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int[] calldata _deltas
  ) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int _delta
  ) external;
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}