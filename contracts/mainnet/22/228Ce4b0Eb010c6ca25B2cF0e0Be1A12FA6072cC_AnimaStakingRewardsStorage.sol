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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IAnimaChamber.sol";
import "../Realm/IRealm.sol";
import "./IAnimaChamberData.sol";
import "./IAnimaStakingRewardsStorage.sol";
import { EpochConfigurable } from "../Utils/EpochConfigurable.sol";

contract AnimaStakingRewardsStorage is
  EpochConfigurable,
  IAnimaStakingRewardsStorage
{
  IAnimaChamberData public ANIMA_CHAMBER_DATA;
  IRealm public REALM;

  event ChamberStaked(
    uint256 chamberId,
    uint256 realmId,
    uint256 stakedAmountDelta,
    uint256 stakedAmountTotal
  );

  event ChamberCompounded(
    uint256 chamberId,
    uint256 realmId,
    uint256 stakedAmountDelta,
    uint256 stakedAmountTotal
  );
  event ChamberUnstaked(
    uint256 chamberId,
    uint256 realmId,
    uint256 stakedAmountDelta,
    uint256 stakedAmountTotal
  );

  constructor(
    address _manager,
    address _realm,
    address _animaChamberData
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    REALM = IRealm(_realm);
    ANIMA_CHAMBER_DATA = IAnimaChamberData(_animaChamberData);
  }

  // Chamber ID => ChamberRewardsStorage
  mapping(uint => uint[]) public REALM_STAKED_CHAMBERS;
  mapping(uint256 => ChamberRewardsStorage) public STAKER_STORAGE;
  mapping(uint256 => RealmRewardsStorage) public REALM_STORAGE;

  // realm => current capacity
  mapping(uint => uint) public REALM_STAKED_CHAMBERS_CAPACITY;
  mapping(uint => mapping(uint => int))
    public EPOCH_HISTORICAL_STAKED_CHAMBERS_CAPACITY_DELTA;

  function realmChamberIds(
    uint _realmId
  ) external view returns (uint[] memory) {
    return REALM_STAKED_CHAMBERS[_realmId];
  }

  function loadChamberInfo(
    uint256 _chamberId
  ) external view returns (ChamberRewardsStorage memory) {
    return _loadChamberInfo(_chamberId);
  }

  function loadRealmInfo(
    uint256 _realmId
  ) external view returns (RealmRewardsStorage memory) {
    return REALM_STORAGE[_realmId];
  }

  function updateStakingRewards(
    uint256 _chamberId,
    bool _updateStakerTimestamp,
    bool _updateRealmerTimestamp,
    uint256 _newUsedCapacity
  ) external onlyManager {
    if (!_updateStakerTimestamp && !_updateRealmerTimestamp) {
      return;
    }
    ChamberRewardsStorage storage stakerStorage = STAKER_STORAGE[_chamberId];
    if (_updateStakerTimestamp) {
      stakerStorage.lastStakerCollectedAt = uint32(block.timestamp);
    }

    if (_updateRealmerTimestamp && stakerStorage.stakedAt > 0) {
      RealmRewardsStorage storage realmStorage = REALM_STORAGE[
        stakerStorage.realmId
      ];
      stakerStorage.lastRealmerCollectedAt = uint32(block.timestamp);
      realmStorage.lastCapacityAdjustedAt = uint32(block.timestamp);
      realmStorage.lastCapacityUsed = _newUsedCapacity;
    }
  }

  function getAndUpdateLastStakerCollectedAt(
    uint256 _chamberId
  ) external onlyManager returns (uint256) {
    ChamberRewardsStorage memory info = _loadChamberInfo(_chamberId);
    uint256 lastCollectedAt = info.lastStakerCollectedAt;
    info.lastStakerCollectedAt = uint32(block.timestamp);
    STAKER_STORAGE[_chamberId] = info;
    return lastCollectedAt;
  }

  function stakedAmountWithDeltas(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) public view returns (uint current, int[] memory deltas) {
    require(
      _startEpoch <= _endEpoch,
      "AnimaStakingRewardsStorage: invalid range"
    );

    current = REALM_STAKED_CHAMBERS_CAPACITY[_realmId];
    uint length = _endEpoch - _startEpoch;
    deltas = new int[](length);
    for (uint i = 0; i < length; i++) {
      deltas[i] = EPOCH_HISTORICAL_STAKED_CHAMBERS_CAPACITY_DELTA[_realmId][
        _startEpoch + i
      ];
    }
  }

  function checkStaked(
    uint256 _chamberId
  ) external view returns (bool, uint256) {
    ChamberRewardsStorage memory info = _loadChamberInfo(_chamberId);
    return (info.stakedAt > 0, info.realmId);
  }

  function registerChamberCompound(
    uint256 _chamberId,
    uint _rewardsAmount
  ) external onlyManager {
    ChamberRewardsStorage memory info = _loadChamberInfo(_chamberId);
    if (info.stakedAt == 0) {
      return;
    }

    EPOCH_HISTORICAL_STAKED_CHAMBERS_CAPACITY_DELTA[info.realmId][
      currentEpoch()
    ] += int(_rewardsAmount);
    REALM_STAKED_CHAMBERS_CAPACITY[info.realmId] += _rewardsAmount;

    emit ChamberCompounded(
      _chamberId,
      info.realmId,
      _rewardsAmount,
      REALM_STAKED_CHAMBERS_CAPACITY[info.realmId]
    );
  }

  function registerChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external onlyManager {
    ChamberRewardsStorage memory info = _loadChamberInfo(_chamberId);
    if (info.stakedAt > 0) {
      _unregisterInternal(_chamberId, info.realmId, info);
    }
    _registerInternal(_chamberId, _realmId, info);
  }

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external onlyManager {
    ChamberRewardsStorage memory info = _loadChamberInfo(_chamberId);
    if (info.stakedAt == 0) {
      return;
    }
    _unregisterInternal(_chamberId, _realmId, info);
  }

  function _registerInternal(
    uint256 _chamberId,
    uint256 _realmId,
    ChamberRewardsStorage memory info
  ) internal {
    info.chamberStakedIndex = uint32(REALM_STAKED_CHAMBERS[_realmId].length);
    REALM_STAKED_CHAMBERS[_realmId].push(_chamberId);

    info.realmId = uint32(_realmId);
    info.stakedAt = uint32(block.timestamp);
    STAKER_STORAGE[_chamberId] = info;

    uint chamberAnimaAmount = ANIMA_CHAMBER_DATA.stakedAnima(_chamberId);
    EPOCH_HISTORICAL_STAKED_CHAMBERS_CAPACITY_DELTA[_realmId][
      currentEpoch()
    ] += int(chamberAnimaAmount);

    uint totalChambersValue = REALM_STAKED_CHAMBERS_CAPACITY[_realmId];
    totalChambersValue += chamberAnimaAmount;
    REALM_STAKED_CHAMBERS_CAPACITY[_realmId] = totalChambersValue;

    emit ChamberStaked(
      _chamberId,
      _realmId,
      chamberAnimaAmount,
      totalChambersValue
    );
  }

  function _unregisterInternal(
    uint256 _chamberId,
    uint256 _realmId,
    ChamberRewardsStorage memory info
  ) internal {
    uint currentIndex = info.chamberStakedIndex;
    uint lastIndex = REALM_STAKED_CHAMBERS[_realmId].length - 1;
    if (currentIndex != lastIndex) {
      uint lastChamberId = REALM_STAKED_CHAMBERS[_realmId][lastIndex];
      STAKER_STORAGE[lastChamberId].chamberStakedIndex = uint32(currentIndex);
      REALM_STAKED_CHAMBERS[_realmId][currentIndex] = lastChamberId;
    }
    REALM_STAKED_CHAMBERS[_realmId].pop();

    info.realmId = 0;
    info.stakedAt = 0;
    STAKER_STORAGE[_chamberId] = info;

    uint chamberAnimaAmount = ANIMA_CHAMBER_DATA.stakedAnima(_chamberId);
    EPOCH_HISTORICAL_STAKED_CHAMBERS_CAPACITY_DELTA[_realmId][
      currentEpoch()
    ] -= int(chamberAnimaAmount);
    uint totalChambersValue = REALM_STAKED_CHAMBERS_CAPACITY[_realmId];
    totalChambersValue -= chamberAnimaAmount;
    REALM_STAKED_CHAMBERS_CAPACITY[_realmId] = totalChambersValue;

    emit ChamberUnstaked(
      _chamberId,
      _realmId,
      chamberAnimaAmount,
      REALM_STAKED_CHAMBERS_CAPACITY[_realmId]
    );
  }

  function _loadChamberInfo(
    uint256 _chamberId
  ) internal view returns (ChamberRewardsStorage memory) {
    ChamberRewardsStorage memory chamberInfo = STAKER_STORAGE[_chamberId];
    if (chamberInfo.mintedAt == 0) {
      chamberInfo.mintedAt = uint32(ANIMA_CHAMBER_DATA.mintedAt(_chamberId));
    }
    return chamberInfo;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAnimaChamber is IERC721 {
  function burn(uint256 _tokenId) external;

  function mintFor(address _for) external returns (uint256);

  function tokensOfOwner(
    address _owner
  ) external view returns (uint256[] memory);
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

struct ChamberRewardsStorage {
  uint32 realmId;
  uint32 mintedAt;
  uint32 stakedAt;
  uint32 chamberStakedIndex;
  uint32 lastRealmerCollectedAt;
  uint32 lastStakerCollectedAt;
}

struct RealmRewardsStorage {
  uint32 lastCapacityAdjustedAt;
  uint lastCapacityUsed;
}

error ChamberAlreadyStaked(uint _realmId, uint _chamberId);
error ChamberNotStaked(uint _realmId, uint _chamberId);

interface IAnimaStakingRewardsStorage {
  function realmChamberIds(uint _realmId) external view returns (uint[] memory);

  function loadChamberInfo(
    uint256 _chamberId
  ) external view returns (ChamberRewardsStorage memory);

  function loadRealmInfo(
    uint256 _realmId
  ) external view returns (RealmRewardsStorage memory);

  function updateStakingRewards(
    uint256 _chamberId,
    bool _updateStakerTimestamp,
    bool _updateRealmerTimestamp,
    uint256 _lastUsedCapacity
  ) external;

  function stakedAmountWithDeltas(
    uint _realmId,
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (uint current, int[] memory deltas);

  function checkStaked(
    uint256 _chamberId
  ) external view returns (bool, uint256);

  function registerChamberStaked(uint256 _chamberId, uint256 _realmId) external;

  function registerChamberCompound(
    uint256 _chamberId,
    uint _rewardsAmount
  ) external;

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function isApprovedForAll(
    address owner,
    address operator
  ) external returns (bool);

  function realmFeatures(
    uint256 realmId,
    uint256 index
  ) external view returns (uint256);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
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

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}