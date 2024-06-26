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

import "../ERC20/ITokenMinter.sol";
import "./IAnimaChamberData.sol";
import "./IAnimaStakerStorage.sol";
import "../Manager/ManagerModifier.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IAnimaStakingRewardsStorage.sol";
import "./IAnimaStakingRewardsEmitter.sol";

contract AnimaStakingRewardsEmitter is
  ManagerModifier,
  IAnimaStakingRewardsEmitter
{
  ITokenMinter public TOKEN_MINTER;
  IAnimaChamberData public CHAMBER_DATA;
  IAnimaStakingRewardsStorage public REWARDS_STORAGE;
  IAnimaStakerStorage public STAKER_STORAGE;
  IERC721 public CHAMBER;
  IERC721 public REALM;

  constructor(
    address _manager,
    address _tokenMinter,
    address _chamberData,
    address _stakerStorage,
    address _rewardsStorage,
    address _chamber,
    address _realm
  ) ManagerModifier(_manager) {
    TOKEN_MINTER = ITokenMinter(_tokenMinter);
    CHAMBER_DATA = IAnimaChamberData(_chamberData);
    REWARDS_STORAGE = IAnimaStakingRewardsStorage(_rewardsStorage);
    STAKER_STORAGE = IAnimaStakerStorage(_stakerStorage);
    CHAMBER = IERC721(_chamber);
    REALM = IERC721(_realm);
  }

  function emitStakerRewards(
    uint _tokenId,
    uint _rewardsAmount,
    bool _compound
  ) external onlyTokenEmitter {
    uint currentStake = CHAMBER_DATA.stakedAnima(_tokenId);

    address owner = CHAMBER.ownerOf(_tokenId);
    address target = owner;

    if (_compound) {
      target = address(STAKER_STORAGE);
      currentStake += _rewardsAmount;
      CHAMBER_DATA.getAndResetStakedAnima(_tokenId);
      CHAMBER_DATA.setStakedAnima(_tokenId, currentStake);
      REWARDS_STORAGE.registerChamberCompound(_tokenId, _rewardsAmount);
      STAKER_STORAGE.changeDelta(int(_rewardsAmount));
    }

    emit StakerRewardsEmitted(
      _tokenId,
      _rewardsAmount,
      owner,
      _compound,
      currentStake
    );

    TOKEN_MINTER.mint(target, _rewardsAmount, MINTER_STAKER_BUCKET);
  }

  function emitRealmerRewards(
    uint _tokenId,
    uint _realmId,
    uint _rewardsAmount
  ) external onlyTokenEmitter {
    address realmOwner = REALM.ownerOf(_realmId);
    TOKEN_MINTER.mint(realmOwner, _rewardsAmount, MINTER_REALM_BUCKET);

    emit RealmerRewardsEmitted(_tokenId, _realmId, _rewardsAmount, realmOwner);
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStakerStorage {
  function unstakeAndChangeDelta(address _for, uint256 _amount) external;

  function getTotal() external view returns (uint);

  function getEpochChanges(uint _epoch) external view returns (int);

  function getEpochChangesBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (int[] memory result);

  function changeDelta(int _delta) external;
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

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}