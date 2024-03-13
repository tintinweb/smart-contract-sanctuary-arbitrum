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

uint256 constant ACTION_ARMORY_STAKE_MONUMENT = 2061;
uint256 constant ACTION_ARMORY_UNSTAKE_MONUMENT = 2062;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;
uint256 constant ACTION_REALM_BUILD_MONUMENT = 4012;
uint256 constant ACTION_REALM_BUILD_CITY = 4013;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAnima is IERC20 {
  function mintFor(address _for, uint256 _amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ITokenSpender {
  function spend(address _owner, uint _amount) external;
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

import { IArmory } from "./IArmory.sol";

interface IDurabilityEnabledArmory is IArmory {
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IMaterial {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(address _for, uint256[] memory _ids, uint256[] memory _amounts) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IMonumentHomage {
  struct StakedMonument {
    uint256 tokenId;
    uint256 amount;
  }

  struct HomageDestination {
    uint256 realmId;
    uint256 structureId;
    uint256 structureAmount;
  }

  struct HomageRequest {
    address adventurerAddress;
    uint256 adventurerId;
    bytes32[] proofs;
    HomageDestination[] destinations;
  }

  function payHomage(HomageRequest[] calldata _requests) external;

  function getEligibleStructureAmounts(
    uint256[] calldata _realmIds,
    uint256[] calldata _tokenIds
  ) external view returns (uint256[] calldata);

  function getAdventurerHomagePoints(
    address[] calldata _addresses,
    uint256[] calldata _adventurerIds
  ) external view returns (uint256[] calldata);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

struct RiftHomageConfigStruct {
  uint[4] structureId;
  uint[4] realmTokenCost;
  uint[4] voidTokenCost;
  uint[4] durabilityLossPercentage;
  uint[4] structureAnimaCapacity;
}

interface IRiftHomageConfigProvider {
  function config() external view returns (RiftHomageConfigStruct memory);

  function animaCapacityPerStructure() external view returns (uint[7] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Manager/ManagerModifier.sol";
import "../Action/Actions.sol";
import "../Utils/Epoch.sol";
import "../Utils/Random.sol";
import "./IRiftHomageConfigProvider.sol";
import "../Anima/IAnima.sol";
import "../Armory/IDurabilityEnabledArmory.sol";
import "./IMonumentHomage.sol";
import "../Structure/IRandomStructureBurner.sol";
import "../Anima/ITokenSpender.sol";
import "../Item/IMaterial.sol";
import { EpochConfigurable } from "../Utils/EpochConfigurable.sol";

struct ConfigCache {
  uint epoch;
  RiftHomageConfigStruct config;
}

struct RiftHomageRequest {
  uint[] realmRequests;
  uint[] voidRequests;
}

contract RiftHomage is EpochConfigurable, ReentrancyGuard {
  ConfigCache private CONFIG_CACHE;

  IRiftHomageConfigProvider public CONFIG_PROVIDER;
  IRandomStructureBurner public RANDOM_STRUCTURE_BURNER;
  IDurabilityEnabledArmory public REALM_ARMORY;
  IMaterial public MATERIAL;
  address public immutable DURABILITY_LOSS_HANDLER;

  ITokenSpender public TOKEN_SPENDER;
  address public STRUCTURE;
  address public REALM;

  constructor(
    address _manager,
    address _realmArmory,
    address _realm,
    address _structure,
    address _configProvider,
    address _tokenSpender,
    address _durabilityLossHandler,
    address _material,
    address _structureBurner
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    CONFIG_PROVIDER = IRiftHomageConfigProvider(_configProvider);
    STRUCTURE = _structure;
    TOKEN_SPENDER = ITokenSpender(_tokenSpender);
    REALM_ARMORY = IDurabilityEnabledArmory(_realmArmory);
    REALM = _realm;
    DURABILITY_LOSS_HANDLER = _durabilityLossHandler;
    MATERIAL = IMaterial(_material);
    RANDOM_STRUCTURE_BURNER = IRandomStructureBurner(_structureBurner);
  }

  function availableRealmHomageCounts() external view returns (uint[] memory) {
    RiftHomageConfigStruct memory cfg = config();

    uint[] memory structureIds = new uint[](4);
    uint[] memory durabilityLosses = new uint[](4);
    for (uint i = 0; i < 4; i++) {
      structureIds[i] = cfg.structureId[i];
      durabilityLosses[i] = cfg.durabilityLossPercentage[i];
    }
    return
      RANDOM_STRUCTURE_BURNER.availableUsageCounts(
        STRUCTURE,
        structureIds,
        durabilityLosses
      );
  }

  function homage(
    RiftHomageRequest calldata _request
  ) external whenNotPaused nonReentrant {
    require(
      msg.sender == tx.origin,
      "Homage is not allowed through another contract"
    );

    uint randomBase = Random.startRandomBase(
      ACTION_ADVENTURER_HOMAGE,
      uint(uint160(msg.sender))
    );

    uint[] memory materialIds = new uint[](4);
    for (uint i = 0; i < 4; i++) {
      materialIds[i] = i + 1;
    }

    // Mint materials and configuration
    RiftHomageConfigStruct memory cfg = _config();
    uint[] memory structureIds = new uint[](4);
    uint[] memory durabilityLosses = new uint[](4);
    uint totalAnimaSpent;
    bool areMonumentsAffected = false;
    for (uint i = 0; i < 4; i++) {
      structureIds[i] = cfg.structureId[i];
      durabilityLosses[i] = cfg.durabilityLossPercentage[i];

      if (_request.realmRequests[i] + _request.voidRequests[i] <= 0) {
        continue;
      }
      if (_request.realmRequests[i] > 0) {
        areMonumentsAffected = true;
      }

      totalAnimaSpent += _request.realmRequests[i] * cfg.realmTokenCost[i];
      totalAnimaSpent += _request.voidRequests[i] * cfg.voidTokenCost[i];
      MATERIAL.mintFor(
        msg.sender,
        i + 1,
        _request.realmRequests[i] + _request.voidRequests[i]
      );
    }

    TOKEN_SPENDER.spend(msg.sender, totalAnimaSpent);

    if (areMonumentsAffected) {
      RANDOM_STRUCTURE_BURNER.randomReduceDurability(
        randomBase,
        STRUCTURE,
        structureIds,
        durabilityLosses,
        _request.realmRequests,
        DURABILITY_LOSS_HANDLER
      );
    }
  }

  function _config() internal returns (RiftHomageConfigStruct memory) {
    uint epochNow = currentEpoch();
    if (CONFIG_CACHE.epoch != epochNow) {
      CONFIG_CACHE.config = CONFIG_PROVIDER.config();
      CONFIG_CACHE.epoch = epochNow;
    }
    return CONFIG_CACHE.config;
  }

  function config() public view returns (RiftHomageConfigStruct memory) {
    uint epochNow = currentEpoch();
    if (CONFIG_CACHE.epoch != epochNow) {
      return CONFIG_PROVIDER.config();
    }
    return CONFIG_CACHE.config;
  }

  function clearCache() external onlyAdmin {
    CONFIG_CACHE.epoch = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurner {
  function availableUsageCounts(
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _lossPerUsage
  ) external view returns (uint[] memory);

  function randomReduceDurability(
    uint _randomBase,
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _durabilityLoss,
    uint[] calldata _amounts,
    address _durabilityLossHandler
  ) external returns (uint nextRandomBase);
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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
  /**
   * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
   * @return block number as int
   */
  function arbBlockNumber() external view returns (uint256);

  /**
   * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
   * @return block hash
   */
  function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

  /**
   * @notice Gets the rollup's unique chain identifier
   * @return Chain identifier as int
   */
  function arbChainID() external view returns (uint256);

  /**
   * @notice Get internal version number identifying an ArbOS build
   * @return version number as int
   */
  function arbOSVersion() external view returns (uint256);

  /**
   * @notice Returns 0 since Nitro has no concept of storage gas
   * @return uint 0
   */
  function getStorageGasAvailable() external view returns (uint256);

  /**
   * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
   * @dev this call has been deprecated and may be removed in a future release
   * @return true if current execution frame is not a call by another L2 contract
   */
  function isTopLevelCall() external view returns (bool);

  /**
   * @notice map L1 sender contract address to its L2 alias
   * @param sender sender address
   * @param unused argument no longer used
   * @return aliased sender address
   */
  function mapL1SenderContractAddressToL2Alias(
    address sender,
    address unused
  ) external pure returns (address);

  /**
   * @notice check if the caller (of this caller of this) is an aliased L1 contract address
   * @return true iff the caller's address is an alias for an L1 contract address
   */
  function wasMyCallersAddressAliased() external view returns (bool);

  /**
   * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
   * @return address of the caller's caller, without applying L1 contract address aliasing
   */
  function myCallersAddressWithoutAliasing() external view returns (address);

  /**
   * @notice Send given amount of Eth to dest from sender.
   * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
   * @param destination recipient address on L1
   * @return unique identifier for this L2-to-L1 transaction.
   */
  function withdrawEth(address destination) external payable returns (uint256);

  /**
   * @notice Send a transaction to L1
   * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
   * to a contract address without any code (as enforced by the Bridge contract).
   * @param destination recipient address on L1
   * @param data (optional) calldata for L1 contract call
   * @return a unique identifier for this L2-to-L1 transaction.
   */
  function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

  /**
   * @notice Get send Merkle tree .state
   * @return size number of sends in the history
   * @return root root hash of the send history
   * @return partials hashes of partial subtrees in the send history tree
   */
  function sendMerkleTreeState()
    external
    view
    returns (uint256 size, bytes32 root, bytes32[] memory partials);

  /**
   * @notice creates a send txn from L2 to L1
   * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
   */
  event L2ToL1Tx(
    address caller,
    address indexed destination,
    uint256 indexed hash,
    uint256 indexed position,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
  event L2ToL1Transaction(
    address caller,
    address indexed destination,
    uint256 indexed uniqueId,
    uint256 indexed batchNumber,
    uint256 indexInBatch,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /**
   * @notice logs a merkle branch for proof synthesis
   * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
   * @param hash the merkle hash
   * @param position = (level << 192) + leaf
   */
  event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);

  error InvalidBlockNumber(uint256 requested, uint256 current);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IArbSys.sol";

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
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 200033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(uint256 _highSalt, uint256 _lowSalt) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _getPreviousBlockhash(),
            block.timestamp,
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 _randomBase,
    uint256 _range
  ) internal view returns (uint256, uint256) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > _range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (_range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = _randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (_randomBase % _range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(abi.encodePacked(_getPreviousBlockhash(), msg.sender, _randomBase, _range))
    );
    return (nextBaseNumber % _range, nextBaseNumber / nextNumberSeparator);
  }

  function _getPreviousBlockhash() internal view returns (bytes32) {
    // Arbitrum One, Nova, Goerli, Sepolia, Stylus or Rinkeby
    if (
      block.chainid == 42161 ||
      block.chainid == 42170 ||
      block.chainid == 421613 ||
      block.chainid == 421614 ||
      block.chainid == 23011913 ||
      block.chainid == 421611
    ) {
      return ArbSys(address(0x64)).arbBlockHash(ArbSys(address(0x64)).arbBlockNumber() - 1);
    } else {
      // WARNING: THIS IS HIGHLY INSECURE ON ETH MAINNET, it is currently used mostly for testing
      return blockhash(block.number - 1);
    }
  }
}