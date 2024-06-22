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

import "@openzeppelin/contracts/security/Pausable.sol";
import "../Manager/ManagerModifier.sol";
import "../Realm/IRealm.sol";
import "./IAnimaStaker.sol";
import "./IAnimaStakingRewards.sol";
import "./IAnimaStakingRewardsStorage.sol";
import "./IAnimaChamberData.sol";
import "./IAnimaStakingRewardsCalculator.sol";
import "./IAnimaChamber.sol";
import "../ERC20/ITokenMinter.sol";
import "../Resource/IResource.sol";
import "../lib/FloatingPointConstants.sol";
import "../Resource/IResource.sol";
import "../Resource/ResourceConstants.sol";
import "../Utils/ArrayUtils.sol";
import "./IAnimaStakingRewardsEmitter.sol";

error NotOwner(
  address _owner,
  address _sender,
  address _tokenAddress,
  uint256 _tokenId
);

contract AnimaStakingRewards is
  ManagerModifier,
  IAnimaStakingRewards,
  Pausable
{
  IRealm public immutable REALM;
  IAnimaChamber public immutable ANIMA_CHAMBER;
  IAnimaChamberData public ANIMA_CHAMBER_DATA;
  IAnimaStakingRewardsStorage public ANIMA_STAKING_REWARDS_STORAGE;
  IAnimaStakingRewardsCalculator public ANIMA_STAKING_REWARDS_CALCULATOR;
  IAnimaStakingRewardsEmitter public REWARDS_EMITTER;
  IResource public RESOURCE;

  uint256 public CAPACITY_EXCEEDED_REWARDS = 20000;
  uint256 public MAX_REWARDS_PERIOD;
  uint256 public immutable YEAR = 365 days;

  constructor(
    address _manager,
    address _realm,
    address _animaChamber,
    address _animaChamberData,
    address _animaStakingRewardsData,
    address _animaStakingRewardsCalculator,
    address _rewardsEmitter,
    address _resource
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    ANIMA_CHAMBER = IAnimaChamber(_animaChamber);
    ANIMA_CHAMBER_DATA = IAnimaChamberData(_animaChamberData);
    ANIMA_STAKING_REWARDS_STORAGE = IAnimaStakingRewardsStorage(
      _animaStakingRewardsData
    );
    ANIMA_STAKING_REWARDS_CALCULATOR = IAnimaStakingRewardsCalculator(
      _animaStakingRewardsCalculator
    );
    MAX_REWARDS_PERIOD = ANIMA_STAKING_REWARDS_CALCULATOR.MAX_REWARDS_PERIOD();
    REWARDS_EMITTER = IAnimaStakingRewardsEmitter(_rewardsEmitter);
    RESOURCE = IResource(_resource);
  }

  function availableStakerRewards(
    uint[] calldata _tokenIds,
    uint[][] calldata _params
  ) external view returns (uint[] memory, uint[] memory) {
    uint[] memory rewards = new uint[](_tokenIds.length);
    uint[] memory vestedAmounts = new uint[](_tokenIds.length);
    for (uint i = 0; i < _tokenIds.length; i++) {
      ChamberRewardsStorage memory info = ANIMA_STAKING_REWARDS_STORAGE
        .loadChamberInfo(_tokenIds[i]);
      uint chamberAnima = ANIMA_CHAMBER_DATA.stakedAnima(_tokenIds[i]);
      (
        uint stakerRewards,
        ,
        uint vestedAmount
      ) = ANIMA_STAKING_REWARDS_CALCULATOR.calculateRewardsView(
          chamberAnima,
          info,
          _params[i]
        );
      rewards[i] = stakerRewards;
      vestedAmounts[i] = vestedAmount;
    }
    return (rewards, vestedAmounts);
  }

  function availableRealmerRewards(
    uint[] calldata _realmIds
  ) public view returns (uint[] memory) {
    ArrayUtils.checkForDuplicates(_realmIds);

    uint[] memory rewards = new uint[](_realmIds.length);
    uint totalRewards = 0;
    uint totalStake = 0;
    for (uint i = 0; i < _realmIds.length; i++) {
      RealmRewardsStorage memory realmInfo = ANIMA_STAKING_REWARDS_STORAGE
        .loadRealmInfo(_realmIds[i]);
      uint[] memory chamberIds = ANIMA_STAKING_REWARDS_STORAGE.realmChamberIds(
        _realmIds[i]
      );

      // account for staking capacity
      for (uint j = 0; j < chamberIds.length; j++) {
        ChamberRewardsStorage memory chamberInfo = ANIMA_STAKING_REWARDS_STORAGE
          .loadChamberInfo(chamberIds[j]);
        uint chamberAnima = ANIMA_CHAMBER_DATA.stakedAnima(chamberIds[j]);
        (
          ,
          uint realmerRewards,
          uint vestedStake
        ) = ANIMA_STAKING_REWARDS_CALCULATOR.calculateRewardsView(
            chamberAnima,
            chamberInfo,
            new uint[](0)
          );
        rewards[i] += realmerRewards;
        totalRewards += realmerRewards;
        totalStake += vestedStake;
        (rewards[i], ) = _updateRealmerRewardsBasedOnCapacity(
          realmInfo.lastCapacityUsed,
          realmInfo.lastCapacityAdjustedAt,
          chamberInfo.realmId,
          chamberInfo.lastRealmerCollectedAt,
          rewards[i],
          totalStake
        );
      }
    }
    return rewards;
  }

  function stakerCollect(
    uint256 _tokenId,
    bool _compound,
    uint[] calldata _params
  ) external whenNotPaused {
    _collect(_tokenId, true, false, true, _compound, _params);
  }

  function stakerCollectBatch(
    uint256[] calldata _tokenId,
    bool[] calldata _compound,
    uint[][] calldata _params
  ) external whenNotPaused {
    for (uint256 i = 0; i < _tokenId.length; i++) {
      _collect(_tokenId[i], true, false, true, _compound[i], _params[i]);
    }
  }

  function realmerCollect(uint256 _realmId) external whenNotPaused {
    _realmerCollect(_realmId);
  }

  function realmerCollectBatch(
    uint256[] calldata _realmIds
  ) external whenNotPaused {
    ArrayUtils.checkForDuplicates(_realmIds);
    for (uint256 i = 0; i < _realmIds.length; i++) {
      _realmerCollect(_realmIds[i]);
    }
  }

  function _realmerCollect(uint256 _realmId) internal {
    uint[] memory chamberIds = ANIMA_STAKING_REWARDS_STORAGE.realmChamberIds(
      _realmId
    );
    for (uint i = 0; i < chamberIds.length; i++) {
      _collect(chamberIds[i], false, true, true, false, new uint[](0));
    }
  }

  function collectManager(
    uint256 _tokenId,
    bool _forStaker,
    bool _forRealmer
  ) external onlyManager whenNotPaused {
    _collect(_tokenId, _forStaker, _forRealmer, false, false, new uint[](0));
  }

  function registerChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external onlyManager {
    _collect(_chamberId, true, true, false, false, new uint[](0));
    ANIMA_STAKING_REWARDS_STORAGE.registerChamberStaked(_chamberId, _realmId);
  }

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external onlyManager {
    _collect(_chamberId, true, true, false, false, new uint[](0));
    ANIMA_STAKING_REWARDS_STORAGE.unregisterChamberStaked(_chamberId, _realmId);
  }

  function _collect(
    uint256 _tokenId,
    bool _forStaker,
    bool _forRealmer,
    bool _verifyOwnership,
    bool _compound,
    uint[] memory params
  ) internal {
    require(
      _forStaker || _forRealmer,
      "AnimaStakingRewards: no rewards to emit"
    );

    ChamberRewardsStorage memory info = ANIMA_STAKING_REWARDS_STORAGE
      .loadChamberInfo(_tokenId);

    uint chamberAnima = ANIMA_CHAMBER_DATA.stakedAnima(_tokenId);
    (
      uint stakerRewards,
      uint realmerRewards,
      uint vestedStake
    ) = ANIMA_STAKING_REWARDS_CALCULATOR.calculateRewards(
        chamberAnima,
        info,
        params
      );

    if (_forStaker && stakerRewards > 0) {
      address chamberOwner = ANIMA_CHAMBER.ownerOf(_tokenId);
      if (_verifyOwnership && chamberOwner != msg.sender) {
        revert NotOwner(
          chamberOwner,
          msg.sender,
          address(ANIMA_CHAMBER),
          _tokenId
        );
      }

      REWARDS_EMITTER.emitStakerRewards(_tokenId, stakerRewards, _compound);
    }

    RealmRewardsStorage memory realmInfo;
    if (_forRealmer && realmerRewards > 0 && info.stakedAt > 0) {
      address realmOwner = REALM.ownerOf(info.realmId);
      if (_verifyOwnership && realmOwner != msg.sender) {
        revert NotOwner(realmOwner, msg.sender, address(REALM), _tokenId);
      }

      realmInfo = ANIMA_STAKING_REWARDS_STORAGE.loadRealmInfo(info.realmId);
      _calculateAvailableCapacityBasedOnTimeElapsed(realmInfo);
      (
        realmerRewards,
        realmInfo.lastCapacityUsed
      ) = _updateRealmerRewardsBasedOnCapacity(
        realmInfo.lastCapacityUsed,
        realmInfo.lastCapacityAdjustedAt,
        info.realmId,
        info.lastRealmerCollectedAt,
        realmerRewards,
        vestedStake
      );

      REWARDS_EMITTER.emitRealmerRewards(
        _tokenId,
        info.realmId,
        realmerRewards
      );
    }

    ANIMA_STAKING_REWARDS_STORAGE.updateStakingRewards(
      _tokenId,
      _forStaker && stakerRewards > 0,
      _forRealmer && realmerRewards > 0,
      realmInfo.lastCapacityUsed
    );
  }

  function _calculateAvailableCapacityBasedOnTimeElapsed(
    RealmRewardsStorage memory _info
  ) internal {
    uint elapsedTime = block.timestamp - uint(_info.lastCapacityAdjustedAt);
    uint lastRealmerUsedCapacity = 0;
    _info.lastCapacityAdjustedAt = uint32(block.timestamp);
    if (elapsedTime > MAX_REWARDS_PERIOD) {
      _info.lastCapacityUsed = 0;
      return;
    }

    _info.lastCapacityUsed =
      (_info.lastCapacityUsed * (MAX_REWARDS_PERIOD - elapsedTime)) /
      MAX_REWARDS_PERIOD;
  }

  function _updateRealmerRewardsBasedOnCapacity(
    uint _lastUsedCapacity,
    uint _lastUsedCapacityTimestamp,
    uint _realmId,
    uint _lastRealmerCollectedAt,
    uint _realmerRewards,
    uint _vestedStake
  ) internal view returns (uint, uint) {
    if (_vestedStake <= 0 || _realmerRewards <= 0) {
      return (0, 0);
    }

    uint _realmCapacity = RESOURCE.data(_realmId, resources.ANIMA_CAPACITY);
    uint availableCapacity;
    if (_realmCapacity > _lastUsedCapacity) {
      availableCapacity = _realmCapacity - _lastUsedCapacity;
    }

    uint timeSinceLastCollected = block.timestamp - _lastRealmerCollectedAt;
    if (timeSinceLastCollected > MAX_REWARDS_PERIOD) {
      timeSinceLastCollected = MAX_REWARDS_PERIOD;
    }
    uint usedCapacity;
    if (timeSinceLastCollected > 0) {
      usedCapacity =
        (_vestedStake * timeSinceLastCollected) /
        MAX_REWARDS_PERIOD;
    }

    // full rewards if capacity not exceeded
    if (usedCapacity <= availableCapacity) {
      return (_realmerRewards, _lastUsedCapacity + usedCapacity);
    }

    // partial rewards if capacity is exceeded
    uint _fullRewards = (_realmerRewards * availableCapacity) / usedCapacity;
    uint _capacityExceededRewards = ((_realmerRewards - _fullRewards) *
      CAPACITY_EXCEEDED_REWARDS) / ONE_HUNDRED;
    return (_fullRewards + _capacityExceededRewards, _realmCapacity);
  }

  //-----------------------------------------------------------------------------------
  // Admin
  //-----------------------------------------------------------------------------------

  function pause() external onlyPauser {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateAnimaChamberData(
    address _animaChamberData
  ) external onlyAdmin {
    ANIMA_CHAMBER_DATA = IAnimaChamberData(_animaChamberData);
  }

  function updateAnimaRewardsStorage(
    address _animaRewardsStorage
  ) external onlyAdmin {
    ANIMA_STAKING_REWARDS_STORAGE = IAnimaStakingRewardsStorage(
      _animaRewardsStorage
    );
  }

  function updateAnimaRewardsCalculator(
    address _animaStakingRewardsCalculator
  ) external onlyAdmin {
    ANIMA_STAKING_REWARDS_CALCULATOR = IAnimaStakingRewardsCalculator(
      _animaStakingRewardsCalculator
    );
    MAX_REWARDS_PERIOD = ANIMA_STAKING_REWARDS_CALCULATOR.MAX_REWARDS_PERIOD();
  }

  function updateAnimaStakingRewardsEmitter(
    address _rewardsEmitter
  ) external onlyAdmin {
    REWARDS_EMITTER = IAnimaStakingRewardsEmitter(_rewardsEmitter);
  }

  function updateCapacityExceededRewards(
    uint256 _capacity
  ) external onlyConfigManager {
    CAPACITY_EXCEEDED_REWARDS = _capacity;
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

interface IAnimaStaker {
  function stake(uint256 _amount) external;

  function stakeBatch(uint256[] calldata _amounts) external;

  function unstake(uint256 _tokenId) external;

  function unstakeBatch(uint256[] calldata _tokenId) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStakingRewards {
  function stakerCollect(
    uint256 _tokenId,
    bool _compound,
    uint[] calldata _params
  ) external;

  function stakerCollectBatch(
    uint256[] calldata _tokenId,
    bool[] calldata _compound,
    uint[][] calldata _params
  ) external;

  function realmerCollect(uint256 _realmId) external;

  function realmerCollectBatch(uint256[] calldata _realmIds) external;

  function collectManager(
    uint256 _tokenId,
    bool _forStaker,
    bool _forRealmer
  ) external;

  function registerChamberStaked(uint256 _chamberId, uint256 _realmId) external;

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IAnimaStakingRewardsStorage.sol";

interface IAnimaStakingRewardsCalculator {
  function MAX_REWARDS_PERIOD() external view returns (uint256);

  function currentBaseRewards()
    external
    view
    returns (
      uint stakerRewards,
      uint realmerRewards,
      uint burnRatio,
      uint rewardsPool
    );

  function baseRewardsAtEpochBatch(
    uint startEpoch,
    uint endEpoch
  )
    external
    view
    returns (
      uint[] memory stakerRewards,
      uint[] memory realmerRewards,
      uint[] memory burnRatios,
      uint[] memory rewardPools
    );

  function estimateChamberRewards(
    uint _additionalAnima,
    uint _realmId
  ) external view returns (uint boost, uint rewards, uint stakedAverage);

  function estimateChamberRewardsBatch(
    uint _additionalAnima,
    uint[] calldata _realmId
  )
    external
    view
    returns (
      uint[] memory bonuses,
      uint[] memory rewards,
      uint[] memory stakedAverage
    );

  function calculateRewardsView(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    view
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );

  function calculateRewards(
    uint _animaAmount,
    ChamberRewardsStorage memory _chamberInfo,
    uint256[] calldata params
  )
    external
    returns (
      uint256 stakerRewards,
      uint256 realmerRewards,
      uint256 vestedStake
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStakingRewardsEmitter {
  event StakerRewardsEmitted(
    uint _tokenId,
    uint _amount,
    address _receiver,
    bool _compounded,
    uint _totalAnimaStaked
  );

  event RealmerRewardsEmitted(
    uint _tokenId,
    uint _realmId,
    uint _amount,
    address _receiver
  );

  function emitStakerRewards(
    uint _tokenId,
    uint _rewardsAmount,
    bool _compound
  ) external;

  function emitRealmerRewards(
    uint _tokenId,
    uint _realmId,
    uint _rewardsAmount
  ) external;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant MINTER_ADVENTURER_BUCKET = 1;
uint constant MINTER_REALM_BUCKET = 2;
uint constant MINTER_STAKER_BUCKET = 3;

interface ITokenMinter is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function mint(address _owner, uint _amount, uint _bucket) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IResource {
  function data(
    uint256 _realmId,
    uint256 _resourceId
  ) external view returns (uint256);

  function add(uint256 _realmId, uint256 _resourceId, uint256 _amount) external;

  function remove(
    uint256 _realmId,
    uint256 _resourceId,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library resources {
  // Season 1 resources
  uint256 public constant MINERAL_DEPOSIT = 0;
  uint256 public constant LAND_ABUNDANCE = 1;
  uint256 public constant AQUATIC_RESOURCES = 2;
  uint256 public constant ANCIENT_ARTIFACTS = 3;

  // Staking capacities
  uint256 public constant ANIMA_CAPACITY = 100;

  uint256 public constant PARTICLE_CAPACITY = 110;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}