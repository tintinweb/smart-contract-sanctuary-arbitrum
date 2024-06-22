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
uint256 constant ACTION_ADVENTURER_TRAINING = 1008;
uint256 constant ACTION_ADVENTURER_TRANSCENDENCE = 1009;
uint256 constant ACTION_ADVENTURER_MINT_MULTIPASS = 1010;

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

uint256 constant ACTION_ARMORY_STAKE_CITY = 2061;
uint256 constant ACTION_ARMORY_UNSTAKE_CITY = 2062;

uint256 constant ACTION_ARMORY_STAKE_MONUMENT = 2071;
uint256 constant ACTION_ARMORY_UNSTAKE_MONUMENT = 2072;

uint256 constant ACTION_ARMORY_STAKE_ANIMA_CHAMBER = 2081;
uint256 constant ACTION_ARMORY_UNSTAKE_ANIMA_CHAMBER = 2082;
uint256 constant ACTION_ANIMA_STAKING_COLLECT_STAKER_REWARDS = 2083;
uint256 constant ACTION_ANIMA_STAKING_COLLECT_REALMER_REWARDS = 2084;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;
uint256 constant ACTION_REALM_BUILD_MONUMENT = 4012;
uint256 constant ACTION_REALM_BUILD_CITY = 4013;

// SPDX-License-Identifier: Unlicensed

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

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    bytes32[][] calldata _proofs,
    uint256 _action,
    uint256[] calldata _minEpochs,
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

  function checkIfEnoughEpochsElapsedBatch(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint256[] calldata _minEpochs,
    uint128 _epochConfig
  ) external view;

  function getElapsedEpochs(
    address[] calldata _tokenAddrs,
    uint256[] calldata _tokenIds,
    uint256 _action,
    uint128 _epochConfig
  ) external view returns (uint[] memory result);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Armory/SoftStakingERC721ArmoryAdapter.sol";
import "../Action/Actions.sol";
import "./IAnimaStakingRewardsCalculator.sol";
import "./IAnimaStakingRewards.sol";

contract AnimaChamberArmoryAdapter is SoftStakingERC721ArmoryAdapter {
  IAnimaStakingRewards public ANIMA_STAKING_REWARDS;

  constructor(
    address _manager,
    address _actionPermit,
    address _collectionAddress,
    address _animaStakingRewards
  )
    SoftStakingERC721ArmoryAdapter(
      _manager,
      _collectionAddress,
      _actionPermit,
      ACTION_ARMORY_STAKE_ANIMA_CHAMBER,
      ACTION_ARMORY_UNSTAKE_ANIMA_CHAMBER
    )
  {
    ANIMA_STAKING_REWARDS = IAnimaStakingRewards(_animaStakingRewards);
  }

  function _stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) internal override {
    ANIMA_STAKING_REWARDS.collectManager(_entityTokenId, true, true);
    super._stake(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityTokenId,
      _entityAmount
    );
    ANIMA_STAKING_REWARDS.registerChamberStaked(_entityTokenId, _ownerId);
  }

  function _unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) internal override {
    ANIMA_STAKING_REWARDS.collectManager(_entityTokenId, true, true);
    super._unstake(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityTokenId,
      _entityAmount
    );
    ANIMA_STAKING_REWARDS.unregisterChamberStaked(_entityTokenId, _ownerId);
  }

  //---------------------------
  // Admin
  //---------------------------

  function updateRewards(address _animaStaker) external onlyAdmin {
    ANIMA_STAKING_REWARDS = IAnimaStakingRewards(_animaStaker);
  }
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

uint constant ARMORY_ENTITY_DISABLED = 0;
uint constant ARMORY_ENTITY_ERC20 = 1;
uint constant ARMORY_ENTITY_ERC721 = 2;
uint constant ARMORY_ENTITY_ERC1155 = 3;
uint constant ARMORY_ENTITY_DATA = 4;

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IArmoryEntityStorageAdapter {
  error Unauthorized(address _staker, address _ownerAddress, uint _ownerId);
  error UnsupportedOperation(address _entityAddress, string operation);
  error UnsupportedEntity(address _entityAddress);
  error AlreadyStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityId,
    uint _tokenAmounts
  );
  error InsufficientAmountStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _tokenIds,
    uint _tokenAmounts
  );

  function entityType() external pure returns (uint);

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mint(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256 _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IArmoryEntityStorageAdapter.sol";

interface IArmoryERC721Adapter is IArmoryEntityStorageAdapter {
  function ownerOf(
    address _entityAddress,
    uint _entityId
  ) external view returns (bool, address, uint);

  function ownerOfBatch(
    address _entityAddress,
    uint[] calldata _entityIds
  )
    external
    view
    returns (
      bool[] memory areStaked,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    );

  function ownerOfBatch(
    address _entityAddress,
    uint[][] calldata _entityIds
  )
    external
    view
    returns (
      bool[][] memory areStaked,
      address[][] memory ownerAddresses,
      uint[][] memory ownerIds
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../Action/Actions.sol";
import "./ArmoryConstants.sol";
import "./IArmoryEntityStorageAdapter.sol";
import "../Manager/ManagerModifier.sol";
import "../Action/IActionPermit.sol";
import "./IArmoryERC721Adapter.sol";

uint64 constant ZERO_TIMESTAMP = 0;

struct StakeInfo {
  uint64 timestamp;
  address ownerAddress;
  uint256 ownerId;
}

abstract contract SoftStakingERC721ArmoryAdapter is
  ReentrancyGuard,
  ManagerModifier,
  IArmoryEntityStorageAdapter,
  IArmoryERC721Adapter
{
  address public immutable STAKED_ENTITY;
  IActionPermit public ACTION_PERMIT;

  // staked entity id => owner
  mapping(uint256 => StakeInfo) public STAKING_DATA;

  uint immutable REQUIRED_STAKE_ACTION_PERMISSION;
  uint immutable REQUIRED_UNSTAKE_ACTION_PERMISSION;

  constructor(
    address _manager,
    address _stakedEntity,
    address _actionPermit,
    uint _actionStakePermission,
    uint _actionUnstakePermission
  ) ManagerModifier(_manager) {
    STAKED_ENTITY = _stakedEntity;
    ACTION_PERMIT = IActionPermit(_actionPermit);
    REQUIRED_STAKE_ACTION_PERMISSION = _actionStakePermission;
    REQUIRED_UNSTAKE_ACTION_PERMISSION = _actionUnstakePermission;
  }

  function entityType() external pure override returns (uint) {
    return ARMORY_ENTITY_ERC721;
  }

  function ownerOf(
    address _entityAddress,
    uint _entityId
  ) external view override returns (bool, address, uint) {
    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }
    StakeInfo memory stakingData = STAKING_DATA[_entityId];
    return (
      stakingData.timestamp > 0,
      stakingData.ownerAddress,
      stakingData.ownerId
    );
  }

  function ownerOfBatch(
    address _entityAddress,
    uint[] calldata _entityIds
  )
    external
    view
    override
    returns (
      bool[] memory areStaked,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    )
  {
    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }

    areStaked = new bool[](_entityIds.length);
    ownerAddresses = new address[](_entityIds.length);
    ownerIds = new uint[](_entityIds.length);

    for (uint i = 0; i < _entityIds.length; i++) {
      StakeInfo memory stakingData = STAKING_DATA[_entityIds[i]];
      areStaked[i] = stakingData.timestamp > 0;
      ownerAddresses[i] = stakingData.ownerAddress;
      ownerIds[i] = stakingData.ownerId;
    }
  }

  function ownerOfBatch(
    address _entityAddress,
    uint[][] calldata _entityIds
  )
    external
    view
    override
    returns (
      bool[][] memory areStaked,
      address[][] memory ownerAddresses,
      uint[][] memory ownerIds
    )
  {
    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }

    areStaked = new bool[][](_entityIds.length);
    ownerAddresses = new address[][](_entityIds.length);
    ownerIds = new uint[][](_entityIds.length);

    for (uint j = 0; j < _entityIds.length; j++) {
      areStaked[j] = new bool[](_entityIds[j].length);
      ownerAddresses[j] = new address[](_entityIds[j].length);
      ownerIds[j] = new uint[](_entityIds[j].length);
      for (uint i = 0; i < _entityIds.length; i++) {
        StakeInfo memory stakingData = STAKING_DATA[_entityIds[j][i]];
        areStaked[j][i] = stakingData.timestamp > 0;
        ownerAddresses[j][i] = stakingData.ownerAddress;
        ownerIds[j][i] = stakingData.ownerId;
      }
    }
  }

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external override onlyManager {
    _stake(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityTokenId,
      _entityAmount
    );
  }

  function stakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      _stake(
        _staker,
        _ownerAddresses,
        _ownerIds,
        _proof,
        _entityAddress,
        _entityTokenIds[i],
        _entityAmounts[i]
      );
    }
  }

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        _stake(
          _staker,
          _ownerAddresses[i],
          _ownerIds[i],
          _proofs[i],
          _entityAddress,
          _entityTokenIds[i][j],
          _entityAmounts[i][j]
        );
      }
    }
  }

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external override onlyManager {
    _unstake(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityTokenId,
      _entityAmount
    );
  }

  function unstakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      _unstake(
        _staker,
        _ownerAddresses,
        _ownerIds,
        _proof,
        _entityAddress,
        _entityTokenIds[i],
        _entityAmounts[i]
      );
    }
  }

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        _unstake(
          _staker,
          _ownerAddresses[i],
          _ownerIds[i],
          _proofs[i],
          _entityAddress,
          _entityTokenIds[i][j],
          _entityAmounts[i][j]
        );
      }
    }
  }

  function burn(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Burn not supported");
  }

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Burn not supported");
  }

  function burnBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Burn not supported");
  }

  function mint(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Mint not supported");
  }

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Mint not supported");
  }

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external override onlyManager {
    revert UnsupportedOperation(_entityAddress, "Mint not supported");
  }

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view override {
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      for (uint j = 0; j < _entityTokenIds[i].length; j++) {
        if (
          balanceOf(
            _ownerAddresses[i],
            _ownerIds[i],
            _entityAddress,
            _entityTokenIds[i][j]
          ) < _entityAmounts[i][j]
        ) {
          revert InsufficientAmountStaked(
            _ownerAddresses[i],
            _ownerIds[i],
            _entityAddress,
            _entityTokenIds[i][j],
            _entityAmounts[i][j]
          );
        }
      }
    }
  }

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view override {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      if (
        balanceOf(
          _ownerAddresses,
          _ownerIds,
          _entityAddress,
          _entityTokenIds[i]
        ) < _entityAmounts[i]
      ) {
        revert InsufficientAmountStaked(
          _ownerAddresses,
          _ownerIds,
          _entityAddress,
          _entityTokenIds[i],
          _entityAmounts[i]
        );
      }
    }
  }

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256 _entityAmounts // only used for ERC-20, ERC-1155
  ) external view override {
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      if (
        balanceOf(
          _ownerAddresses,
          _ownerIds,
          _entityAddress,
          _entityTokenIds[i]
        ) < _entityAmounts
      ) {
        revert InsufficientAmountStaked(
          _ownerAddresses,
          _ownerIds,
          _entityAddress,
          _entityTokenIds[i],
          _entityAmounts
        );
      }
    }
  }

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) public view override returns (uint) {
    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }

    StakeInfo storage stakingData = STAKING_DATA[_entityTokenId];
    if (
      stakingData.timestamp == ZERO_TIMESTAMP ||
      stakingData.ownerAddress != _ownerAddress ||
      stakingData.ownerId != _ownerId
    ) {
      return 0;
    }

    return 1;
  }

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds
  ) external view override returns (uint[] memory) {
    uint[] memory result = new uint[](_entityTokenIds.length);
    for (uint i = 0; i < _entityTokenIds.length; i++) {
      result[i] = balanceOf(
        _ownerAddress,
        _ownerIds,
        _entityAddress,
        _entityTokenIds[i]
      );
    }
    return result;
  }

  //---------------------------
  // Internal
  //---------------------------

  function _stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) internal virtual {
    if (_entityAmount == 0) {
      return;
    }

    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }

    if (_entityAmount > 1) {
      revert UnsupportedOperation(
        _entityAddress,
        "Can not stake more than 1 of ERC721"
      );
    }

    ACTION_PERMIT.checkPermissions(
      _staker,
      _entityAddress,
      _entityTokenId,
      _proof,
      REQUIRED_STAKE_ACTION_PERMISSION
    );

    StakeInfo storage stakingData = STAKING_DATA[_entityTokenId];
    STAKING_DATA[_entityTokenId] = StakeInfo({
      timestamp: uint64(block.timestamp),
      ownerAddress: _ownerAddress,
      ownerId: _ownerId
    });
  }

  function _unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) internal virtual {
    if (_entityAmount == 0) {
      return;
    }

    if (_entityAddress != STAKED_ENTITY) {
      revert UnsupportedEntity(_entityAddress);
    }

    if (_entityAmount != 1) {
      revert UnsupportedOperation(
        _entityAddress,
        "Can not unstake more than 1 of ERC721"
      );
    }
    ACTION_PERMIT.checkPermissions(
      _staker,
      _entityAddress,
      _entityTokenId,
      _proof,
      REQUIRED_UNSTAKE_ACTION_PERMISSION
    );

    StakeInfo storage stakingData = STAKING_DATA[_entityTokenId];
    if (
      stakingData.timestamp == ZERO_TIMESTAMP ||
      stakingData.ownerAddress != _ownerAddress ||
      stakingData.ownerId != _ownerId
    ) {
      revert InsufficientAmountStaked(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityTokenId,
        _entityAmount
      );
    }

    STAKING_DATA[_entityTokenId] = StakeInfo({
      timestamp: ZERO_TIMESTAMP,
      ownerAddress: address(0),
      ownerId: 0
    });
  }

  //---------------------------
  // Admin
  //---------------------------
  function updatePermit(address _actionPermit) external onlyAdmin {
    ACTION_PERMIT = IActionPermit(_actionPermit);
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