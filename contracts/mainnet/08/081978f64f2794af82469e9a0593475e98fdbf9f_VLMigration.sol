// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IErrors} from "./interfaces/IErrors.sol";
import {ILockRewards} from "./interfaces/ILockRewards.sol";
import {IvlY2KV2} from "./interfaces/IvlY2KV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VLMigration is Ownable {
    ILockRewards public immutable lockV1_16_weeks;
    ILockRewards public immutable lockV1_32_weeks;
    IvlY2KV2 public immutable lockV2;
    address public immutable withdrawToken;
    bool public migrationActive;

    mapping(address => mapping(address => uint256)) public migratedAmount;

    event Migrated(address account, uint256 amount, address legacyLock);

    struct PrevMigration {
        address lockContract;
        address user;
        uint256 amount;
    }

    constructor(
        address _lockV1_16_weeks,
        address _lockV1_32_weeks,
        address _lockV2,
        address _withdrawToken,
        PrevMigration[] memory prevMigrations
    ) Ownable(msg.sender) {
        if (_lockV1_16_weeks == address(0)) revert IErrors.InvalidInput();
        if (_lockV1_32_weeks == address(0)) revert IErrors.InvalidInput();
        if (_lockV2 == address(0)) revert IErrors.InvalidInput();
        if (_withdrawToken == address(0)) revert IErrors.InvalidInput();

        lockV2 = IvlY2KV2(_lockV2);
        if (_withdrawToken != lockV2.LockToken()) revert IErrors.InvalidToken();

        lockV1_16_weeks = ILockRewards(_lockV1_16_weeks);
        lockV1_32_weeks = ILockRewards(_lockV1_32_weeks);
        withdrawToken = _withdrawToken;
        _updatePrevMigrators(prevMigrations);
    }

    /*//////////////////////////////////////////////////////////////
                               ADMIN
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Activate migration - once the configuration is checked this can be activated
     */
    function activateMigration() external onlyOwner {
        if (
            lockV1_16_weeks.owner() != address(this) ||
            lockV1_32_weeks.owner() != address(this)
        ) revert IErrors.InvalidSetup();
        migrationActive = true;
    }

    /**
        @notice Transfer ownership of the lockV1 contract to a new owner
        @param newOwner Address of the new owner
        @param lockContract Address of the lock contract
     */
    function transferLockRewardsOwnership(
        address newOwner,
        ILockRewards lockContract
    ) external onlyOwner {
        if (newOwner == address(0)) revert IErrors.ZeroAddress();
        if (lockContract != lockV1_16_weeks && lockContract != lockV1_32_weeks)
            revert IErrors.InvalidInput();
        lockContract.transferOwnership(newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                               PUBLIC
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Check called hasn't migrated yet, caller balance > 0, and caller has claimed rewards
        @dev Merkle tree used to check if the caller has migrated
     */
    function migrate() external {
        // Check migration is active
        if (!migrationActive) revert IErrors.MigrationInactive();
        _migrateFromLockV1(lockV1_16_weeks);
        _migrateFromLockV1(lockV1_32_weeks);
    }

    function _migrateFromLockV1(ILockRewards legacyLock) internal {
        // Check if the user has balance in legacyLock and has claimed rewards
        ILockRewards.Account memory account = legacyLock.accounts(msg.sender);
        if (account.balance == 0) return;

        // Deduct prevMigrated amount from balance for legacyLock and revert if 0 (i.e. already migrated)
        uint256 amount = account.balance -
            migratedAmount[address(legacyLock)][msg.sender];
        if (amount == 0) revert IErrors.MigrationCompleted();

        // Add migrating amount to mapping for legacyLock, pull ERC20 from legacyLock, and approve lockV2
        migratedAmount[address(legacyLock)][msg.sender] += amount;
        legacyLock.recoverERC20(withdrawToken, amount);
        IERC20(withdrawToken).approve(address(lockV2), amount);

        // Calculate lock duration and lock in lockV2
        uint lockEpochsToTransfer = account.lockEpochs == 0
            ? 0
            : account.lockEpochs - 1;
        // TODO: This may need to be adjusted depending on the community vote!!
        uint256 lockDuration = lockEpochsToTransfer < 16
            ? lockEpochsToTransfer * 7 days
            : 16 weeks;

        // Extension of vlY2KV2 for migration contract - to match previous lock duration
        // TODO: If two separate contracts then need lockV2Sixteen and lockV2ThirtyTwo
        lockV2.lockMigrate(msg.sender, amount, lockDuration);

        // TODO: Also need to emit an event with the relevant lockV2 contract
        emit Migrated(msg.sender, amount, address(legacyLock));
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNAL
    //////////////////////////////////////////////////////////////*/
    /**
        @notice Update the migratedAmount to their balance for invalid migrators i.e. force exited account
        @dev is used to update the migratedAmount for users who have already migrated
        @param prevMigrations Array of previous migrations
     */
    function _updatePrevMigrators(
        PrevMigration[] memory prevMigrations
    ) internal {
        for (uint i; i < prevMigrations.length; ) {
            PrevMigration memory prevMigration = prevMigrations[i];

            if (prevMigration.lockContract == address(0))
                revert IErrors.InvalidInput();
            if (prevMigration.user == address(0)) revert IErrors.ZeroAddress();
            if (prevMigration.amount == 0) revert IErrors.ZeroAmount();
            if (
                prevMigration.lockContract != address(lockV1_16_weeks) &&
                prevMigration.lockContract != address(lockV1_32_weeks)
            ) revert IErrors.InvalidInput();

            // Checks the amount being set in migration is less than balance of use in legacyLock
            ILockRewards.Account memory account = ILockRewards(
                prevMigration.lockContract
            ).accounts(prevMigration.user);
            if (account.balance < prevMigration.amount)
                revert IErrors.InvalidInput();

            // Check the migrating user hasn't already migrated
            if (
                migratedAmount[prevMigration.lockContract][
                    prevMigration.user
                ] != 0
            ) revert IErrors.DoubleMigration();

            migratedAmount[prevMigration.lockContract][
                prevMigration.user
            ] = prevMigration.amount;

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IErrors {
    error InvalidInput();
    error ZeroBalance();
    error ZeroAddress();
    error ZeroAmount();
    error RewardsUnclaimed();
    error MigrationCompleted();
    error InvalidMerkleProof();
    error MigrationInactive();
    error InvalidSetup();
    error InvalidToken();
    error DoubleMigration();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockRewards {
    struct Account {
        uint256 balance;
        uint256 lockEpochs;
        uint256 lastEpochPaid;
        uint256 rewards1;
        uint256 rewards2;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function currentEpoch() external view returns (uint256);

    function accounts(
        address owner
    ) external view returns (Account memory account);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function claimReward() external;

    function deposit(uint256 amount, uint256 lockEpochs) external;

    function pause() external;

    function withdraw(uint256 withdrawAmount) external;

    function changeRecoverWhitelist(address tokenAddress, bool flag) external;

    function whitelistRecoverERC20(
        address tokenAddress
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IvlY2KV2 {
    /**
        @notice Balance details
        @param  locked           uint224          Overall locked amount
        @param  nextUnlockIndex  uint32           Index of earliest next unlock
        @param  lockedBalances   LockedBalance[]  List of locked balances data
     */
    struct Balance {
        uint224 locked;
        uint32 nextUnlockIndex;
        LockedBalance[] lockedBalances;
    }

    /**
        @notice Lock balance details
        @param  amount      uint224  Locked amount in the lock
        @param  unlockTime  uint32   Unlock time of the lock
     */
    struct LockedBalance {
        uint224 amount;
        uint32 unlockTime;
    }

    function migrator() external view returns (address);

    function migrationActive() external view returns (bool);

    function owner() external view returns (address);

    function LockToken() external view returns (address);

    function epochDuration() external view returns (uint32);

    function lockDuration() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function lock(address account, uint256 amount) external;

    function lockMigrate(
        address account,
        uint256 amount,
        uint256 lockDuration
    ) external;

    function setMigrator(address migrator) external;

    function updateMigrationStatus(bool status) external;

    function lockedBalances(
        address account
    )
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function lockedBalanceOf(address account) external view returns (uint256);

    function processExpiredLocks(bool relock) external;

    function reduceLock(
        address account,
        uint256 index,
        uint256 newLock
    ) external;

    function initialize(
        address lpToken,
        string memory name,
        string memory symbol
    ) external;

    function upgradeToAndCall(address newImpl, bytes memory data) external;

    function proxiableUUID() external returns (bytes32);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function recoverERC721(address tokenAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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