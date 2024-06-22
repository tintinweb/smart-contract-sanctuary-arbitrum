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

pragma solidity ^0.8.17;

import "../Action/IActionPermit.sol";
import "../Armory/IArmory.sol";
import "../Manager/ManagerModifier.sol";
import "../Utils/ArrayUtils.sol";
import "../Armory/IArmoryERC721OwnerCheck.sol";
import "./IAnimaChamber.sol";
import "./IAnimaChamberData.sol";

struct AnimaChamberStakerRequest {
  uint256[] realmIds;
  bytes32[][] proofs;
  uint256[][] chamberIds;
  uint256[][] amounts; // always 1
}

contract AnimaChamberStaker is ManagerModifier, Pausable {
  IArmory public ARMORY;
  IArmoryERC721OwnerCheck public ARMORY_OWNER_CHECK;
  address public REALM;
  IAnimaChamber public ANIMA_CHAMBER;
  IAnimaChamberData public ANIMA_CHAMBER_DATA;

  constructor(
    address _manager,
    address _armory,
    address _armoryOwnerCheck,
    address _realm,
    address _animaChamber,
    address _animaChamberData
  ) ManagerModifier(_manager) {
    ARMORY = IArmory(_armory);
    ARMORY_OWNER_CHECK = IArmoryERC721OwnerCheck(_armoryOwnerCheck);
    REALM = _realm;
    ANIMA_CHAMBER = IAnimaChamber(_animaChamber);
    ANIMA_CHAMBER_DATA = IAnimaChamberData(_animaChamberData);
  }

  function findUnstakedByWallet(
    address _wallet
  )
    external
    view
    returns (
      uint256[] memory chambers,
      uint256[] memory unstakedAmounts,
      uint256 totalUnstakedAmount
    )
  {
    uint256[] memory allChambers = ANIMA_CHAMBER.tokensOfOwner(_wallet);

    (bool[] memory areOwned, , ) = ARMORY_OWNER_CHECK.ownerOfBatch(
      address(ANIMA_CHAMBER),
      allChambers
    );

    uint256 unstakedChambersCount = 0;
    for (uint256 i = 0; i < allChambers.length; i++) {
      if (!areOwned[i]) {
        unstakedChambersCount++;
      }
    }

    chambers = new uint256[](unstakedChambersCount);
    uint256 index = 0;
    for (uint256 i = 0; i < allChambers.length; i++) {
      if (!areOwned[i]) {
        chambers[index] = allChambers[i];
        index++;
      }
    }

    unstakedAmounts = ANIMA_CHAMBER_DATA.stakedAnimaBatch(chambers);
    for (uint256 i = 0; i < unstakedAmounts.length; i++) {
      totalUnstakedAmount += unstakedAmounts[i];
    }
  }

  function changeStakes(
    AnimaChamberStakerRequest calldata _stakeRequest
  ) external whenNotPaused {
    _stake(_stakeRequest);
  }

  function _stake(AnimaChamberStakerRequest calldata _request) internal {
    if (_request.realmIds.length == 0) {
      return;
    }

    ArrayUtils.ensureSameLength(
      _request.realmIds.length,
      _request.chamberIds.length
    );

    address[] memory realmAddresses = new address[](_request.realmIds.length);
    for (uint256 i = 0; i < _request.realmIds.length; i++) {
      realmAddresses[i] = REALM;
    }

    ARMORY.stakeBatch(
      msg.sender,
      realmAddresses,
      _request.realmIds,
      _request.proofs,
      address(ANIMA_CHAMBER),
      _request.chamberIds,
      _request.amounts
    );
  }

  //------------------------------------------------------------------------------------------------
  // Admin
  //------------------------------------------------------------------------------------------------

  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "../Utils/ArrayUtils.sol";
import "./IArmoryEntityStorageAdapter.sol";
import "./ArmoryConstants.sol";
import "./IArmory.sol";

contract Armory is IArmory, ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => IArmoryEntityStorageAdapter) public adapters;
  mapping(address => uint) public entityTypes; // gas efficiency
  mapping(address => uint) public adapterListIndex;
  address[] public entityList;
  uint public enabledEntitiesCount;

  //=======================================
  // Events
  //=======================================

  // Batch events (as this is the most common usage)

  event Staked(
    address staker,
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Unstaked(
    address staker,
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Burned(
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Minted(
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    bytes32[] calldata _proof,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].stake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Staked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatchMulti(
    MultiStakeRequest calldata _request
  ) external onlyManager nonReentrant whenNotPaused {
    for (uint i = 0; i < _request._entityAddresses.length; i++) {
      _stakeBatchInternal(
        _request._staker,
        _request._ownerAddresses,
        _request._ownerTokenIds,
        _request._proofs,
        _request._entityAddresses[i],
        _request._entityIds[i],
        _request._entityAmounts[i]
      );
    }
  }

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].unstake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Unstaked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatchMulti(
    MultiStakeRequest calldata _request
  ) external onlyManager nonReentrant whenNotPaused {
    for (uint i = 0; i < _request._entityAddresses.length; i++) {
      _unstakeBatchInternal(
        _request._staker,
        _request._ownerAddresses,
        _request._ownerTokenIds,
        _request._proofs,
        _request._entityAddresses[i],
        _request._entityIds[i],
        _request._entityAmounts[i]
      );
    }
  }

  function burn(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].burn(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Burned(
      adapters[_entityAddress].entityType(),
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _burnBatchInternal(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _burnBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function burnBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _burnBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function mint(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyMinter nonReentrant whenNotPaused {
    adapters[_entityAddress].mint(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Minted(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function mintBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    _mintBatchInternal(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    _mintBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function checkMinimumAmounts(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external view whenNotPaused {
    adapters[_entityAddress].batchCheckAmounts(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function checkMinimumAmounts(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256 _entityAmount
  ) external view whenNotPaused {
    adapters[_entityAddress].batchCheckAmounts(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmount
    );
  }

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external view whenNotPaused {
    for (uint256 j = 0; j < _ownerTokenIds.length; j++) {
      adapters[_entityAddress].batchCheckAmounts(
        _ownerAddresses[j],
        _ownerTokenIds[j],
        _entityAddress,
        _entityIds[j],
        _entityAmounts[j]
      );
    }
  }

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256 _entityAmounts
  ) external view whenNotPaused {
    for (uint256 j = 0; j < _ownerTokenIds.length; j++) {
      adapters[_entityAddress].batchCheckAmounts(
        _ownerAddresses[j],
        _ownerTokenIds[j],
        _entityAddress,
        _entityIds[j],
        _entityAmounts
      );
    }
  }

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint) {
    return
      adapters[_entityAddress].balanceOf(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityTokenId
      );
  }

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] memory _entityTokenIds
  ) external view returns (uint[] memory) {
    return
      adapters[_entityAddress].balanceOfBatch(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityTokenIds
      );
  }

  function totalEntityCount() external view returns (uint) {
    return entityList.length;
  }

  function enabledEntities() external view returns (address[] memory) {
    address[] memory result = new address[](enabledEntitiesCount);
    uint enabledEntityIndex = 0;
    for (uint i = 0; i < entityList.length; i++) {
      address entity = entityList[i];
      if (entityTypes[entity] != ARMORY_ENTITY_DISABLED) {
        result[enabledEntityIndex++] = address(adapters[entity]);
      }
    }
    return result;
  }

  //=======================================
  // Internals
  //=======================================

  function _stakeBatchInternal(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].stakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Staked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _stakeBatchInternal(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].stakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Staked(
        _staker,
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _unstakeBatchInternal(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].unstakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Unstaked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _unstakeBatchInternal(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].unstakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Unstaked(
        _staker,
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _mintBatchInternal(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].mintBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Minted(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _mintBatchInternal(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].mintBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Minted(
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _burnBatchInternal(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].burnBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Burned(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _burnBatchInternal(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].burnBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Burned(
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  //=======================================
  // Admin
  //=======================================
  function enableEntity(
    address _entity,
    address _adapter
  ) public virtual onlyAdmin {
    require(
      address(adapters[_entity]) == address(0),
      "Collection already enabled"
    );
    adapters[_entity] = IArmoryEntityStorageAdapter(_adapter);
    if (adapterListIndex[_entity] == 0) {
      adapterListIndex[_entity] = entityList.length;
      entityList.push(_entity);
    }
    entityTypes[_entity] = adapters[_entity].entityType();
    enabledEntitiesCount++;
  }

  function disableEntity(address _entity) public virtual onlyAdmin {
    require(
      address(adapters[_entity]) != address(0),
      "Collection already disabled"
    );
    adapters[_entity] = IArmoryEntityStorageAdapter(address(0));
    entityTypes[_entity] = ARMORY_ENTITY_DISABLED;
    enabledEntitiesCount--;
  }

  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }
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

import "./Armory.sol";
import "./IDurabilityEnabledArmory.sol";
import "./IDurabilityEnabledAdapter.sol";

contract DurabilityEnabledArmory is Armory, IDurabilityEnabledArmory {
  error DurabilityNotSupported(address _address);

  constructor(address _manager) Armory(_manager) {}

  // durability support, ownedEntity => support
  mapping(address => bool) public durabilitySupport;

  struct ProcessingMemory {
    address _ownerAddress;
    uint _ownerTokenId;
    address _entityAddress;
    uint _entityTokenId;
    uint durabilityLoss;
  }

  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) public view returns (uint) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurability(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityId
      );
  }

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatch(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatch(
        _ownerAddresses,
        _ownerIds,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory result) {
    result = new uint[][][](_entityAddresses.length);
    for (uint i = 0; i < _entityAddresses.length; i++) {
      result[i] = _getDurabilityAdapter(_entityAddresses[i])
        .currentDurabilityBatch(
          _ownerAddresses,
          _ownerIds,
          _entityAddresses[i],
          _entityIds[i]
        );
    }
  }

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityPercentage(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityId
      );
  }

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatchPercentage(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityPercentageBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatchPercentage(
        _ownerAddresses,
        _ownerIds,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityPercentageBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory result) {
    result = new uint[][][](_entityAddresses.length);
    for (uint i = 0; i < _entityAddresses.length; i++) {
      result[i] = _getDurabilityAdapter(_entityAddresses[i])
        .currentDurabilityBatchPercentage(
          _ownerAddresses,
          _ownerIds,
          _entityAddresses[i],
          _entityIds[i]
        );
    }
  }

  function reduceDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) public whenNotPaused onlyManager {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    uint brokenAmount = adapter.reduceDurability(
      msg.sender,
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityTokenId,
      durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );

    if (brokenAmount > 0) {
      emit Burned(
        IArmoryEntityStorageAdapter(address(adapter)).entityType(),
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        ArrayUtils.toMemoryArray(_entityTokenId, 1),
        ArrayUtils.toMemoryArray(brokenAmount, 1)
      );
    }
  }

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    _reduceDurabilityBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );
  }

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    _reduceDurabilityBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLosses,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );
  }

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _reduceDurabilityBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityTokenIds[i],
        _durabilityLoss,
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );
    }
  }

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint[][][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _reduceDurabilityBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityTokenIds[i],
        _durabilityLosses[i],
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );
    }
  }

  function _reduceDurabilityBatchInternal(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) internal returns (bool anyBroken, uint[][] memory brokenAmounts) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    (anyBroken, brokenAmounts) = adapter.reduceDurabilityBatch(
      msg.sender,
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );

    _emitBurnEvents(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      brokenAmounts,
      anyBroken
    );
  }

  function _reduceDurabilityBatchInternal(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) internal returns (bool anyBroken, uint[][] memory brokenAmounts) {
    (anyBroken, brokenAmounts) = _getDurabilityAdapter(_entityAddress)
      .reduceDurabilityBatch(
        msg.sender,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddress,
        _entityTokenIds,
        _durabilityLosses,
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );

    _emitBurnEvents(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      brokenAmounts,
      anyBroken
    );
  }

  function _emitBurnEvents(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] memory _brokenAmounts,
    bool anyBroken
  ) internal {
    if (!anyBroken) {
      return;
    }
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      emit Burned(
        adapters[_entityAddress].entityType(),
        _ownerAddresses[i],
        _ownerTokenIds[i],
        _entityAddress,
        _entityTokenIds[i],
        _brokenAmounts[i]
      );
    }
  }

  function enableEntity(
    address _entity,
    address _adapter
  ) public override onlyAdmin {
    super.enableEntity(_entity, _adapter);
    durabilitySupport[_entity] = true;
  }

  function disableEntity(address _entity) public override onlyAdmin {
    super.disableEntity(_entity);
    durabilitySupport[_entity] = false;
  }

  function forceChangeDurabilitySupport(
    address _entity,
    bool _durabilitySupport
  ) external onlyAdmin {
    durabilitySupport[_entity] = _durabilitySupport;
  }

  function _getDurabilityAdapter(
    address _entityAddress
  ) internal view returns (IDurabilityEnabledAdapter) {
    if (!durabilitySupport[_entityAddress]) {
      revert DurabilityNotSupported(_entityAddress);
    }
    return IDurabilityEnabledAdapter(address(adapters[_entityAddress]));
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "./IArmoryEntityStorageAdapter.sol";

struct MultiStakeRequest {
  address _staker;
  address[] _ownerAddresses;
  uint256[] _ownerTokenIds;
  bytes32[][] _proofs;
  address[] _entityAddresses;
  uint256[][][] _entityIds;
  uint256[][][] _entityAmounts;
}

interface IArmory {
  function adapters(
    address _entityAddress
  ) external view returns (IArmoryEntityStorageAdapter);

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    bytes32[] calldata _proof,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function stakeBatchMulti(MultiStakeRequest calldata _request) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function unstakeBatchMulti(MultiStakeRequest calldata _request) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function burnBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function mint(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external view;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256 _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256 _entityAmount
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] memory _entityTokenIds
  ) external view returns (uint[] memory);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Armory/DurabilityEnabledArmory.sol";

interface IArmoryERC721OwnerCheck {
  function ownerOf(
    address _entityAddress,
    uint256 _entityId
  )
    external
    view
    returns (bool isOwned, address _ownerAddress, uint256 _ownerTokenId);

  function ownerOfBatch(
    address _entityAddress,
    uint256[] calldata _entityIds
  )
    external
    view
    returns (
      bool[] memory areOwned,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../AdventurerEquipment/IBrokenEquipmentHandler.sol";
import "./IArmoryEntityStorageAdapter.sol";

interface IDurabilityEnabledAdapter {
  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatchPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatchPercentage(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function reduceDurability(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (uint);

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint[] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[][] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[][] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import { IArmory } from "./IArmory.sol";

interface IDurabilityEnabledArmory is IArmory {
  function durabilitySupport(
    address _entityAddress
  ) external view returns (bool);

  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityPercentageBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentageBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function reduceDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _ownedTokenAddress,
    uint _ownedTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _ownedTokenAddress,
    uint[][] calldata _ownedTokenIds,
    uint durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _ownedTokenAddresses,
    uint[][][] calldata _ownedTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint[][][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
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