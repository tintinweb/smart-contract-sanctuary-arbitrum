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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRarityItemCharacteristicDefinitions {
  function characteristicCount() external view returns (uint16);

  function characteristicNames(
    uint16 _characteristic
  ) external view returns (string memory);

  function getCharacteristicValues(
    uint16 _characteristic,
    uint16 _id
  ) external view returns (string memory);

  function characteristicValuesCount(
    uint16 _characteristic
  ) external view returns (uint16);

  function allCharacteristicValues(
    uint16 _characteristic
  ) external view returns (string[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./IRarityItemCharacteristicDefinitions.sol";

interface IRarityItemMinter {
  function mintRandom(
    uint16 _rarity,
    uint256 _randomBase,
    address _recipient
  ) external returns (uint256, uint256, address);

  event RarityItemMinted(
    uint256 _tokenId,
    string _name,
    address _recipient,
    uint256 _count
  );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

//=======================================
// Enums
//=======================================

enum RewardTokenType {
  ERC20,
  ERC721,
  ERC1155
}

//=======================================
// Structs
//=======================================
struct DispensedRewards {
  uint256 nextRandomBase;
  DispensedReward[] rewards;
}

struct DispensedReward {
  RewardTokenType tokenType;
  address token;
  uint256 tokenId;
  uint256 amount;
}

//=========================================================================================================================================
// Rewards will use 10^3 decimal point to calculate drop rates. This means if something has a drop rate of 100% it's represented as 100000
//=========================================================================================================================================
uint256 constant DECIMAL_POINT = 1000;
uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;

//=======================================================================================================================================================
// Dispenser contract for rewards. Each RewardPool is divided into subpools (in case of lootboxes: for different rarities, or realm specific pools, etc).
//=======================================================================================================================================================
interface IRewardsPool {
  //==============================================================================================================================
  // Dispenses random rewards from the pool
  //==============================================================================================================================
  function dispenseRewards(
    uint64 subPoolId,
    uint256 randomNumberBase,
    address receiver
  ) external returns (DispensedRewards memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../Item/IRarityItemMinter.sol";
import "../../Manager/ManagerModifier.sol";
import "../../Utils/Random.sol";
import "./IRewardsPool.sol";
import "../../Treasure/IMasterOfInflation.sol";
import "../../Treasure/IPoolConfigProvider.sol";

contract MasterOfInflationLootBoxRewardsPool is
  IRewardsPool,
  ReentrancyGuard,
  Pausable,
  ManagerModifier,
  IPoolConfigProvider
{
  //=======================================
  // Interfaces
  //=======================================
  IMasterOfInflation public masterOfInflation;
  IRewardsPool public backupRewardsPool;

  //=======================================
  // Addresses
  //=======================================
  address public masterOfInflationTokenAddress;

  //=======================================
  // Constants
  //=======================================
  uint256 public masterOfInflationVariableRateConfig;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint64 => uint256) public dropRateCap;
  mapping(uint64 => uint64) public masterOfInflationPool;
  mapping(uint64 => uint64) public masterOfInflationMintAmount;
  mapping(uint64 => uint256[]) public masterOfInflationItemIds;

  //=======================================
  // Events
  //=======================================
  event MasterOfInflationIntegrationFailed(
    uint64 subPoolId,
    address receiver,
    uint256 roll
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _masterOfInflation,
    address _masterOfInflationTokenAddress,
    address _backupRewardsPool
  ) ManagerModifier(_manager) {
    masterOfInflation = IMasterOfInflation(_masterOfInflation);
    masterOfInflationTokenAddress = _masterOfInflationTokenAddress;
    backupRewardsPool = IRewardsPool(_backupRewardsPool);
  }

  // This function returns the chance of receiving a reward from Master of Inflation contract
  function rewardChance(uint64 _subPoolId) external view returns (uint256) {
    uint256 moiChance = masterOfInflation.chanceOfItemFromPool(
      masterOfInflationPool[_subPoolId],
      masterOfInflationMintAmount[_subPoolId],
      0,
      0
    );
    return
      dropRateCap[_subPoolId] < moiChance ? dropRateCap[_subPoolId] : moiChance;
  }

  // Dispenses rewards based on a random roll. Falls back to another reward pool if necessary.
  function dispenseRewards(
    uint64 _subPoolId,
    uint256 _randomBase,
    address _receiver
  ) external onlyManager whenNotPaused returns (DispensedRewards memory) {
    (uint256 roll, uint256 nextBase) = Random.getNextRandom(
      _randomBase,
      ONE_HUNDRED
    );

    bool mintedRewards = false;
    // If the roll is below the drop rate cap, attempt to mint a reward from the master of inflation pool.
    if (roll < dropRateCap[_subPoolId]) {
      uint256 itemId = masterOfInflationItemIds[_subPoolId][
        roll % masterOfInflationItemIds[_subPoolId].length
      ];

      try
        masterOfInflation.tryMintFromPool(
          MintFromPoolParams(
            masterOfInflationPool[_subPoolId], // poolId
            masterOfInflationMintAmount[_subPoolId], // mint amount
            0, // bonus
            itemId, // random item id
            roll, // random number
            _receiver, // recipient
            0 // negative bonus
          )
        )
      returns (bool success) {
        mintedRewards = success;
      } catch {
        emit MasterOfInflationIntegrationFailed(_subPoolId, _receiver, roll);
      }

      // If successfully minted rewards, return the dispensed rewards and the next base for randomization.
      if (mintedRewards) {
        DispensedReward[] memory dispensedRewards = new DispensedReward[](1);
        dispensedRewards[0] = DispensedReward(
          RewardTokenType.ERC1155,
          masterOfInflationTokenAddress,
          itemId,
          masterOfInflationMintAmount[_subPoolId]
        );
        return DispensedRewards(nextBase, dispensedRewards);
      }
    }

    // If the minting from the master of inflation pool fails or the roll is above the drop rate cap, use the backup rewards pool if present.
    if (address(backupRewardsPool) != address(0)) {
      return backupRewardsPool.dispenseRewards(_subPoolId, nextBase, _receiver);
    }

    // If everything failed we just return 0 rewards
    return DispensedRewards(nextBase, new DispensedReward[](0));
  }

  // Configures the addresses of the master of inflation contract,
  // the master of inflation token address, and the backup rewards pool.
  function configureContracts(
    address _masterOfInflation,
    address _masterOfInflationTokenAddress,
    address _backupRewards
  ) external onlyAdmin {
    masterOfInflation = IMasterOfInflation(_masterOfInflation);
    masterOfInflationTokenAddress = _masterOfInflationTokenAddress;
    backupRewardsPool = IRewardsPool(_backupRewards);
  }

  // Configures the parameters of a sub-pool,
  // including drop rate cap, master of inflation pool, mint amount, and item IDs.
  function configureSubPool(
    uint64 _subPoolId,
    uint256 _dropRateCap,
    uint64 _masterOfInflationPool,
    uint64 _amount,
    uint256[] memory itemIds
  ) external onlyAdmin {
    dropRateCap[_subPoolId] = _dropRateCap;
    masterOfInflationPool[_subPoolId] = _masterOfInflationPool;
    masterOfInflationMintAmount[_subPoolId] = _amount;
    masterOfInflationItemIds[_subPoolId] = itemIds;
  }

  function configureVariableRate(
    uint256 _variableRate
  ) external onlyAdmin {
    masterOfInflationVariableRateConfig = _variableRate;
  }

  function getN(uint64 _poolId) external view returns (uint256) {
    return masterOfInflationVariableRateConfig;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMasterOfInflation {
  function chanceOfItemFromPool(
    uint64 _poolId,
    uint64 _amount,
    uint32 _bonus,
    uint32 _negativeBonus
  ) external view returns (uint256);

  function tryMintFromPool(
    MintFromPoolParams calldata _params
  ) external returns (bool _didMintItem);
}

struct MintFromPoolParams {
  // Slot 1 (160/256)
  uint64 poolId;
  uint64 amount;
  // Extra odds (out of 100,000) of pulling the item. Will be multiplied against the base odds
  // (1 + bonus) * dynamicBaseOdds
  uint32 bonus;
  // Slot 2
  uint256 itemId;
  // Slot 3
  uint256 randomNumber;
  // Slot 4 (192/256)
  address user;
  uint32 negativeBonus;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPoolConfigProvider {
  // Returns the numerator in the dynamic rate formula.
  //
  function getN(uint64 _poolId) external view returns (uint256);
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

//=========================================================================================================================================
// We're trying to normalize all chances close to 100%, which is 100 000 with decimal point 10^3. Assuming this, we can get more "random"
// numbers by dividing the "random" number by this prime. To be honest most primes larger than 100% should work, but to be safe we'll
// use an order of magnitude higher (10^3) relative to the decimal point
// We're using uint256 (2^256 ~= 10^77), which means we're safe to derive 8 consecutive random numbers from each hash.
// If we, by any chance, run out of random numbers (hash being lower than the range) we can in turn
// use the remainder of the hash to regenerate a new random number.
// Example: assuming our hash function result would be 1132134687911000 (shorter number picked for explanation) and we're using
// % 100000 range for our drop chance. The first "random" number is 11000. We then divide 1000000011000 by the 100000037 prime,
// leaving us at 11321342. The second derived random number would be 11321342 % 100000 = 21342. 11321342/100000037 is in turn less than
// 100000037, so we'll instead regenerate a new hash using 11321342.
// Primes are used for additional safety, but we could just deal with the "range".
//=========================================================================================================================================
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 1000033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(
    uint256 _highSalt,
    uint256 _lowSalt
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 randomBase,
    uint256 range
  ) internal view returns (uint256 random, uint256 nextBase) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (randomBase % range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          msg.sender,
          randomBase,
          range
        )
      )
    );
    return (nextBaseNumber % range, nextBaseNumber / nextNumberSeparator);
  }
}