//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusTerminal.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Dependencies
import {IERC20Permit} from "./IERC20Permit.sol";

/**
 *  @title ICygnusTerminal
 *  @notice The interface to mint/redeem pool tokens (CygLP and CygUSD)
 */
interface ICygnusTerminal is IERC20Permit {

    /**
     *  @notice Redeems the specified amount of `shares` for the underlying asset and transfers it to `recipient`.
     *
     *  @dev shares must be greater than 0.
     *  @dev If the function is called by someone other than `owner`, then the function will reduce the allowance
     *       granted to the caller by `shares`.
     *
     *  @param shares The number of shares to redeem for the underlying asset.
     *  @param recipient The address that will receive the underlying asset.
     *  @param owner The address that owns the shares.
     *
     *  @return assets The amount of underlying assets received by the `recipient`.
     */
    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 assets);

    /**
     *  @notice Exchange Rate between the pool token and the asset
     */
    function exchangeRate() external view returns (uint256);

    /**
     *  @notice The lending pool ID (shared by borrowable/collateral)
     */
    function shuttleId() external view returns (uint256);

    /**
     *  @notice Get the collateral address from the borrowable
     */
    function collateral() external view returns (address);

    /**
     *  @notice Get the borrowable address from the collateral
     */
    function borrowable() external view returns (address);

    /**
     *  @notice Syncs the totalBalance in terms of its underlying (accrues interest in borrowable)
     */
    function sync() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    // Mint
    function mint(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

interface IBonusRewarder {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @dev Reverts if msg.sender is not admin
     *  @custom:error OnlyAdmin
     */
    error BonusRewarder__OnlyAdmin();

    /**
     *  @dev Reverts if msg.sender is not pillars
     *  @custom:error OnlyPillarsOfCreation
     */
    error BonusRewarder__OnlyPillarsOfCreation();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:event OnReward Logs when it's harvested
     */
    event OnReward(address indexed borrowable, address indexed collateral, address indexed borrower, uint256 newShares, uint256 pending);

    /**
     *  @custom:event SetReward Logs when a new reward per second is set
     */
    event NewRewardPerSec(uint256 rewardPerSec);

    /**
     *  @custom:event NewBonusReward Logs when a new bonus reward is set for a shuttle
     */
    event NewBonusReward(address indexed borrowable, address indexed collateral, uint256 allocPoint);

    /**
     *  @custom:event UpdateBonusShuttle Logs when a bonus reward is updated
     */
    event UpdateBonusShuttle(
        address indexed borrowable,
        address indexed collateral,
        uint256 lastRewardTime,
        uint256 totalShares,
        uint256 accRewardPerShare
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return pillarsOfCreation The address of the Pillars of Creation contract on this chain
     */
    function pillarsOfCreation() external view returns (address);

    /**
     *  @return totalAllocPoint The total allocation points accross all pools
     */
    function totalAllocPoint() external view returns (uint256);

    /**
     *  @return rewardPerSec The rewards per sec of the bonus token
     */
    function rewardPerSec() external view returns (uint256);

    /**
     *  @return rewardToken The address of the bonus reward token
     */
    function rewardToken() external view returns (address);

    /**
     *  @return admin The address of the admin
     */
    function admin() external view returns (address);

    /**
     *  @notice View function to get the pending tokens amount
     *  @param borrowable Address of the borrowable
     *  @param collateral Address of the collateral
     *  @param user The address of the user
     */
    function pendingReward(
        address borrowable,
        address collateral,
        address user
    ) external view returns (address token, uint256 amount);

    /**
     *  @return getBlockTimestamp The latest timestamp
     */
    function getBlockTimestamp() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Harvests bonus rewards
     *  @param borrowable Address of the borrowable contract
     *  @param collateral Address of the collateral contract
     *  @param user The address of the user
     *  @param recipient The address of the bonus rewards
     *  @param rewardAmount The amount of bonus rewards harvested
     *  @param newShares The shares after harvest
     */
    function onReward(
        address borrowable,
        address collateral,
        address user,
        address recipient,
        uint256 rewardAmount,
        uint256 newShares
    ) external;

    /**
     *  @notice Sets the reward per second of rewardToken
     *  @param newReward The new reward per sec
     *  @custom:security only-admin
     */
    function setRewardPerSec(uint256 newReward) external;

    /**
     *  @notice Sets new shuttle rewards
     *  @param borrowable Address of the borrowable
     *  @param collateral Address of the collateral
     *  @param allocPoint The alloc point for this shuttle
     *  @custom:security only-admin
     */
    function initializeBonusRewards(address borrowable, address collateral, uint256 allocPoint) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Interfaces
import {IHangar18} from "./core/IHangar18.sol";
import {IBonusRewarder} from "./IBonusRewarder.sol";

/**
 *  @notice Interface to interact with CYG rewards
 */
interface IPillarsOfCreation {
    /**
     *  @custom:struct Epoch Information on each epoch
     *  @custom:member epoch The ID for this epoch
     *  @custom:member cygPerBlock The CYG reward rate for this epoch
     *  @custom:member totalRewards The total amount of CYG estimated to be rewarded in this epoch
     *  @custom:member totalClaimed The total amount of claimed CYG
     *  @custom:member start The unix timestamp of when this epoch started
     *  @custom:member end The unix timestamp of when it ended or is estimated to end
     */
    struct EpochInfo {
        uint256 epoch;
        uint256 cygPerBlock;
        uint256 totalRewards;
        uint256 totalClaimed;
        uint256 start;
        uint256 end;
    }

    /**
     *  @custom:struct ShuttleInfo Info of each borrowable
     *  @custom:member active Whether the pool is active or not
     *  @custom:member shuttleId The ID for this shuttle to identify in hangar18
     *  @custom:member totalShares The total number of shares held in the pool
     *  @custom:member accRewardPerShare The accumulated reward per share
     *  @custom:member lastRewardTime The timestamp of the last reward distribution
     *  @custom:member allocPoint The allocation points of the pool
     *  @custom:member bonusRewarder The address of the bonus rewarder contract (if set)
     *  @custom:member pillarsId Unique ID of the rewards to separate shuttle ID between lenders/borrowers
     */
    struct ShuttleInfo {
        bool active;
        uint256 shuttleId;
        address borrowable;
        address collateral;
        uint256 totalShares;
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
        uint256 allocPoint;
        IBonusRewarder bonusRewarder;
        uint256 pillarsId;
    }

    /**
     *  @custom:struct UserInfo Shares and rewards paid to each user
     *  @custom:member shares The number of shares held by the user
     *  @custom:member rewardDebt The amount of reward debt the user has accrued
     */
    struct UserInfo {
        uint256 shares;
        int256 rewardDebt;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts if initializing pillars again
     *
     *  @custom:error PillarsAlreadyInitialized
     */
    error PillarsOfCreation__PillarsAlreadyInitialized();

    /**
     *  @dev Reverts if caller is not the Hangar18 Admin
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error PillarsOfCreation__MsgSenderNotAdmin();

    /**
     *  @dev Reverts if pool is not initialized in the rewarder
     *
     *  @custom:error ShuttleNotInitialized
     */
    error PillarsOfCreation__ShuttleNotInitialized();

    /**
     *  @dev Reverts if we are initializing shuttle rewards twice
     *
     *  @custom:error ShuttleAlreadyInitialized
     */
    error PillarsOfCreation__ShuttleAlreadyInitialized();

    /**
     *  @dev Reverts when the total weight is above 100% when setting lender/borrower splits
     *
     *  @custom:error InvalidTotalWeight
     */
    error PillarsOfCreation__InvalidTotalWeight();

    /**
     *  @dev Reverts when the artificer contract is enabled and the msg sender is not artificer
     *  @notice Mainly used to set/update rewards
     *
     *  @custom:error OnlyArtificer
     */
    error PillarsOfCreation__OnlyArtificer();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Logs when a new `cygPerBlock` is set manually by Admin
     *
     *  @param lastRewardRate The previous `cygPerBlock rate`
     *  @param newRewardRate The new `cygPerBlock` rate
     *
     *  @custom:event NewCygPerBlock
     */
    event NewCygPerBlock(uint256 lastRewardRate, uint256 newRewardRate);

    /**
     *  @dev Logs when a new collateral is set
     */
    event NewShuttleRewards(address borrowable, address collateral, uint256 totalAlloc, uint256 alloc);

    /**
     *  @dev Logs when a bonus rewarder is set for a shuttle
     */
    event NewBonusRewarder(address borrowable, address collateral, IBonusRewarder bonusRewarder);

    /**
     *  @dev Logs when a bonus rewarder is removed from a shuttle
     */
    event RemoveBonusRewarder(address borrowable, address collateral);

    /**
     *  @dev Logs when a lending pool is updated
     *
     *  @param borrowable Address of the CygnusBorrow contract
     *  @param collateral Address of the CygnusCollateral contract
     *  @param sender The msg.sender
     *  @param lastRewardTime The last reward time for this pool
     *  @param epoch The current epoch
     *
     *  @custom:event UpdateShuttle
     */
    event UpdateShuttle(address indexed borrowable, address indexed collateral, address sender, uint256 lastRewardTime, uint256 epoch);

    /**
     *  @notice Logs when user collects their pending CYG from a single pool pools
     *
     *  @param borrowable Address of the CygnusBorrow contract
     *  @param receiver The receiver of the CYG rewards
     *  @param reward CYG reward collected amount
     *
     *  @custom:event CollectCYG
     */
    event Collect(address indexed borrowable, address indexed collateral, address receiver, uint256 reward);

    /**
     *  @notice Logs when user collects their pending CYG from all pools
     *
     *  @param totalPools The total number of pools harvested
     *  @param reward The total amount of CYG collected
     */
    event CollectAll(uint256 totalPools, uint256 reward);

    /**
     *  @notice Logs when user collects their pending CYG from all specific borrow or lending pools
     *
     *  @param totalPools The total number of pools harvested
     *  @param reward The total amount of CYG collected
     *  @param borrowRewards Whether the user collected borrow or lending reward pools
     */
    event CollectAllSingle(uint256 totalPools, uint256 reward, bool borrowRewards);

    /**
     *  @dev Logs when a new Artificer Contract is set
     *
     *  @param oldArtificer The address of the old artificer contract
     *  @param newArtificer The address of the new artificer cntract
     *
     *  @custom:event NewArtificer
     */
    event NewArtificer(address oldArtificer, address newArtificer);

    /**
     *  @dev Logs when admin initializes pillars - Can only be initialized once!
     *
     *  @param birth The birth timestamp of the pillars
     *  @param death The death timestamp of the pillars (ie. when rewards have died out)
     *  @param _cygPerBlockRewards The CYG per block for borrowers/lenders at epoch 0
     *  @param _cygPerBlockDAO The CYG per block for the DAO at epoch 0
     */
    event InitializePillars(uint256 birth, uint256 death, uint256 _cygPerBlockRewards, uint256 _cygPerBlockDAO);

    /**
     *  @dev Logs when the complex rewarder tracks a lender or a borrower
     *
     *  @param borrowable The address of the borrowable asset.
     *  @param account The address of the lender or borrower
     *  @param balance The updated balance of the account
     *
     *  @custom:event TrackShuttle
     */
    event TrackRewards(address indexed borrowable, address indexed account, uint256 balance, address collateral);

    /**
     *  @dev Emitted when the contract self-destructs (can only self-destruct after the death unix timestamp)
     *
     *  @param sender msg.sender
     *  @param _birth The birth of this contract
     *  @param _death The planned death of this contract
     *  @param timestamp The current timestamp
     *
     *  @custom:event WeAreTheWormsThatCrawlOnTheBrokenWingsOfAnAngel
     */
    event Supernova(address sender, uint256 _birth, uint256 _death, uint256 timestamp);

    /**
     *  @dev Logs when we advance an epoch
     *
     *  @param previousEpoch The number of the previous epoch
     *  @param newEpoch The new epoch
     *  @param _oldCygPerBlock The old CYG per block
     *  @param _newCygPerBlock The new CYG per block
     *
     *  @custom:event NewEpoch
     */
    event NewEpoch(uint256 previousEpoch, uint256 newEpoch, uint256 _oldCygPerBlock, uint256 _newCygPerBlock);

    /**
     *  @dev Logs when the contract sweeps an ERC20 token
     *
     *  @param token The address of the ERC20 token that was swept.
     *  @param sender The address of the account that triggered the token sweep.
     *  @param amount The amount of tokens that were swept from the contract's balance.
     *  @param currentEpoch The current epoch at the time of the token sweep.
     *
     *  @custom:event SweepToken
     */
    event SweepToken(address indexed token, address indexed sender, uint256 amount, uint256 currentEpoch);

    /**
     *  @dev Logs when the allocation point of a borrowable asset in a Shuttle pool is updated.
     *
     *  @param borrowable The address of the borrowable asset whose allocation point was updated.
     *  @param collateral The address of the collateral asset whose allocation point was updated.
     *  @param oldAllocPoint The old allocation point of the borrowable asset in the Shuttle pool.
     *  @param newAllocPoint The new allocation point of the borrowable asset in the Shuttle pool.
     *
     *  @custom:event NewShuttleAllocPoint
     */
    event NewShuttleAllocPoint(address borrowable, address collateral, uint256 oldAllocPoint, uint256 newAllocPoint);

    /**
     *  @dev Logs when all pools get updated
     *
     *  @param shuttlesLength The total number of shuttles updated
     *  @param sender The msg.sender
     *  @param epoch The current epoch
     *
     *  @custom:event AccelerateTheUniverse
     */
    event AccelerateTheUniverse(uint256 shuttlesLength, address sender, uint256 epoch);

    /**
     *  @dev Logs when the doom switch is enabled by admin, cannot be turned off
     */
    event DoomSwitchSet(uint256 time, address sender, bool doomswitch);

    /**
     *  @dev Logs when CYG is dripped to the DAO reserves
     */
    event CygnusDAODrip(address receiver, uint256 amount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return Human readable name for this rewarder
     */
    function name() external view returns (string memory);

    /**
     *  @return Version of the rewarder
     */
    function version() external pure returns (string memory);

    /**
     *  @return The reduction factor per epoch of `cygPerBlock` (each epoch rewards reduce by this factor)
     */
    function REDUCTION_FACTOR_PER_EPOCH() external pure returns (uint256);

    /**
     *  @return Address of hangar18 in this chain
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return Unix timestamp representing the time of contract deployment
     */
    function birth() external view returns (uint256);

    /**
     *  @return Unix timestamp representing the time of contract destruction
     */
    function death() external view returns (uint256);

    /**
     *  @return The address of the CYG ERC20 Token
     */
    function cygToken() external view returns (address);

    /**
     *  @return Total allocation points across all pools
     */
    function totalAllocPoint() external view returns (uint256);

    /**
     *  @notice Mapping to keep track of PoolInfo for each borrowable asset
     *  @param borrowable The address of the Cygnus Borrow contract
     *  @return active Whether the pool has been initialized or not (can only be set once)
     *  @return totalShares The total number of shares held in the pool
     *  @return accRewardPerShare The accumulated reward per share of the pool
     *  @return lastRewardTime The timestamp of the last reward distribution
     *  @return allocPoint The allocation points of the pool
     *  @return bonusRewarder The rewarder contract to receive bonus token rewards apart from CYG
     *  @return shuttleId The ID of the lending pool (shared by borrowable/collateral)
     *  @return pillarsId The index of the shuttle in the array
     */
    function getShuttleInfo(
        address borrowable,
        address collateral
    ) external view returns (bool, uint256, address, address, uint256, uint256, uint256, uint256, IBonusRewarder, uint256);

    /**
     *  @notice Mapping to keep track of UserInfo for each user's deposit and borrow activity
     *  @param borrowable The address of the borrowable contract.
     *  @param user The address of the user to check rewards for.
     *  @return shares The number of shares held by the user
     *  @return rewardDebt The amount of reward debt the user has accrued
     */
    function getUserInfo(address borrowable, address collateral, address user) external view returns (uint256, int256);

    /**
     *  @notice Mapping to keep track of EpochInfo for each epoch
     *  @param id The epoch number (limited by TOTAL_EPOCHS)
     *  @return epoch The ID for this epoch
     *  @return rewardRate The CYG reward rate for this epoch
     *  @return totalRewards The total amount of CYG estimated to be rewarded in this epoch
     *  @return totalClaimed The total amount of claimed CYG
     *  @return start The unix timestamp of when this epoch started
     *  @return end The unix timestamp of when it ended or is estimated to end
     */
    function getEpochInfo(
        uint256 id
    ) external view returns (uint256 epoch, uint256 rewardRate, uint256 totalRewards, uint256 totalClaimed, uint256 start, uint256 end);

    /**
     *  @return The total amount of pools we have initialized
     */
    function shuttlesLength() external view returns (uint256);

    /**
     *  @return Constant variable representing the number of seconds in a year (not taking into account leap years)
     */
    function SECONDS_PER_YEAR() external pure returns (uint256);

    /**
     *  @return Constant variable representing the duration of the contract in seconds
     */
    function DURATION() external pure returns (uint256);

    /**
     *  @return The total number of epochs.
     */
    function TOTAL_EPOCHS() external pure returns (uint256);

    /**
     *  @return The duration of each epoch.
     */
    function BLOCKS_PER_EPOCH() external pure returns (uint256);

    /**
     *  @return The timestamp of the end of the last epoch.
     */
    function lastEpochTime() external view returns (uint256);

    /**
     *  @return Total rewards given out by this contract up to this point.
     */
    function totalCygClaimed() external view returns (uint256);

    /**
     *  @dev Calculates the emission curve for CYG emissions.
     *
     *  @param epoch The epoch we are calculating the curve for
     *  @return The CYG emissions curve at `epoch`
     */
    function emissionsCurve(uint256 epoch) external pure returns (uint256);

    /**
     *  @return The current block timestamp.
     */
    function getBlockTimestamp() external view returns (uint256);

    /**
     *  @return This function calculates the current epoch based on the current time and the contract deployment time
     *          It checks if the contract has expired and returns the total number of epochs if it has
     */
    function getCurrentEpoch() external view returns (uint256);

    /**
     *  @return The current epoch rewards for the DAO as per the emissions curve
     */
    function currentEpochRewardsDAO() external view returns (uint256);

    /**
     *  @return The current epoch rewards for borrowers/lenders as per the emissions curve
     */
    function currentEpochRewards() external view returns (uint256);

    /**
     *  @return The previous epoch rewards as per the emissions curve
     */
    function previousEpochRewards() external view returns (uint256);

    /**
     *  @return The amount of rewards to be released in the next epoch.
     */
    function nextEpochRewards() external view returns (uint256);

    /**
     *  @dev Get the time in seconds until this contract self-destructs
     */
    function untilSupernova() external view returns (uint256);

    /**
     *  @dev Calculates the amount of CYG tokens that should be emitted per block for a given epoch.
     *  @param epoch The epoch for which to calculate the emissions rate.
     *  @param totalRewards The total amount of rewards distributed by the end of total epochs
     *  @return The amount of CYG tokens to be emitted per block.
     */
    function calculateCygPerBlock(uint256 epoch, uint256 totalRewards) external view returns (uint256);

    /**
     *  @dev Calculates the total amount of CYG tokens that should be emitted during a given epoch.
     *  @param epoch The epoch for which to calculate the total emissions.
     *  @param totalRewards The total rewards given out by the end of the total epochs.
     *  @return The total amount of CYG tokens to be emitted during the epoch.
     */
    function calculateEpochRewards(uint256 epoch, uint256 totalRewards) external view returns (uint256);

    /**
     *  @return Whether the doom which is enabled or not
     */
    function doomswitch() external view returns (bool);

    /**
     *  @return The total amount of CYG tokens to be distributed to borrowers and lenders by `death` timestamp
     */
    function totalCygRewards() external view returns (uint256);

    /**
     *  @return The total amount of CYG to be distributed to the DAO by the end of this contract's lifetime
     */
    function totalCygDAO() external view returns (uint256);

    /**
     *  @return The amount of CYG this contract gives out to per block
     */
    function cygPerBlockRewards() external view returns (uint256);

    /**
     *  @return The current cygPerBlock for the dao
     */
    function cygPerBlockDAO() external view returns (uint256);

    /**
     *  @return The timestamp of last DAO drip
     */
    function lastDripDAO() external view returns (uint256);

    /**
     *  @return The address of the artificer, capable of manipulation individual pool rewards
     */
    function artificer() external view returns (address);

    /**
     *  @return Whether or not the artificer is enabled
     */
    function artificerEnabled() external view returns (bool);

    // Simple view functions

    /**
     * @return The current epoch progression.
     */
    function epochProgression() external view returns (uint256);

    /**
     * @return The distance travelled in blocks this epoch.
     */
    function blocksThisEpoch() external view returns (uint256);

    /**
     *  @return The pacing of rewards for the current epoch as a percentage
     */
    function epochRewardsPacing() external view returns (uint256);

    /**
     *  @return The time left until the next epoch starts.
     */
    function untilNextEpoch() external view returns (uint256);

    /**
     * @return The total contract progression.
     */
    function totalProgression() external view returns (uint256);

    /**
     *  @return Days until this epoch ends and the next epoch begins
     */
    function daysUntilNextEpoch() external view returns (uint256);

    /**
     *  @return The amount of days until this contract self-destructs
     */
    function daysUntilSupernova() external view returns (uint256);

    /**
     *  @return How many days have passed since the star tof this epoch
     */
    function daysPassedThisEpoch() external view returns (uint256);

    /**
     *  @notice Uses the library's `timestampToDateTime` function to avoid repeating ourselves
     */
    function timestampToDateTime(
        uint256 timestamp
    ) external pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice Uses the library's `diffDays` function to avoid repeating ourselves
     */
    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) external pure returns (uint256 result);

    /**
     *  @notice Returns the datetime that this contract self destructs
     */
    function dateSupernova() external view returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice Returns the datetime this epoch ends and next epoch begins
     */
    function dateNextEpochStart()
        external
        view
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice  Returns the datetime the current epoch started
     */
    function dateCurrentEpochStart()
        external
        view
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice Returns the datetime the last epoch started
     */
    function dateLastEpochStart()
        external
        view
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice Returns the datetime that `epoch` started
     *  @param epoch The epoch number to get the date time of
     */
    function dateEpochStart(
        uint256 epoch
    ) external view returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    /**
     *  @notice Returns the datetime that `epoch` ends
     *  @param epoch The epoch number to get the date time of
     */
    function dateEpochEnd(
        uint256 epoch
    ) external view returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);

    //  User functions  //

    /**
     *  @dev Returns the amount of CYG tokens that are pending to be claimed by the user.
     *
     *  @param borrowable The address of the Cygnus borrow contract
     *  @param account The address of the user
     *  @param borrowRewards Whether to check for pending borrow or lender rewards
     *  @return The amount of CYG tokens pending to be claimed by `account`.
     */
    function pendingCyg(address borrowable, address account, bool borrowRewards) external view returns (uint256);

    /**
     *  @notice Collects CYG rewards from all borrow or lend pools specifically.
     *  @notice Only msg.sender can collect their rewards.
     *  @param account The addres sof the user
     *  @param borrowRewards Whether to check for pending borrow or lender rewards
     *
     */
    function pendingCygSingle(address account, bool borrowRewards) external view returns (uint256 pending);

    /**
     *  @dev Returns the amount of CYG tokens that are pending to be claimed by the user for all pools.
     *
     *  @param account The address of the user.
     *  @return The amount of CYG tokens pending to be claimed by `account`.
     */
    function pendingCygAll(address account) external view returns (uint256);

    /**
     *  @dev Returns bonus rewards for a user
     *
     *  @param borrowable The address of the borrowable
     *  @param collateral The address of the collateral
     *  @param account The address of the user
     */
    function pendingBonusReward(address borrowable, address collateral, address account) external view returns (address, uint256);

    /**
     *  @dev Returns the amount of CYG tokens that are pending to be claimed by the DAO
     */
    function pendingCygDAO() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Main entry point into the Pillars. For borrowers, after taking out a loan the core contracts
     *          check for whether the pillars are set or not. If the pillars are set, then the borrowable
     *          contract passes the principal (ie the user's borrow amount) and the collateral address to this
     *          contract to track their rewards. For lenders this occurs after minting, redeeming or any transfer
     *          of CygUSD. After any transfer the borrowable checks the user's balance of CygUSD (borrowable vault
     *          token) and passes this to the Pillars along wtih to track lending rewards, using the zero address
     *          as collateral.
     *
     *          Effects:
     *            - Updates the shares and reward debt of the borrower or lender in this shuttle
     *            - Updates the total shares of the shuttle being tracked
     *
     *  @param account The address of the lender or borrower
     *  @param balance The latest balance of CygUSD (for lenders) and the borrowed principal of borrowers
     *  @param collateral The address of the collateral (this is the zero address for lenders)
     */
    function trackRewards(address account, uint256 balance, address collateral) external;

    /**
     *  @notice Main function used by borrowers or lenders to collect their CYG rewards for a specific pool.
     *  @notice Only msg.sender can collect their rewards.
     *  @param borrowable The address of the borrowable contract (CygUSD)
     *  @param to The address to which rewards are paid to
     *
     *  @custom:security non-reentrant
     */
    function collect(address borrowable, bool borrowRewards, address to) external returns (uint256 cygAmount);

    /**
     *  @notice Collects CYG rewards from all borrow or lend pools specifically.
     *  @notice Only msg.sender can collect their rewards.
     *  @param to The address to which rewards are paid to
     *  @param borrowRewards Whether user is collecting borrow rewards or lend rewards
     *
     *  @custom:security non-reentrant
     */
    function collectAllSingle(address to, bool borrowRewards) external returns (uint256 cygAmount);

    /**
     *  @notice Collects CYG rewards owed to borrowers or lenders for ALL pools in the Pillars.
     *  @notice Only msg.sender can collect their rewards.
     *  @param to The address to which rewards are paid to
     *
     *  @custom:security non-reentrant
     */
    function collectAll(address to) external returns (uint256 cygAmount);

    /**
     *  @notice Updates the reward per share for a given shuttle
     *
     *  @param borrowable The address of the borrowable contract (CygUSD)
     *  @param borrowRewards Whether the rewards we are updating are for borrowers or lenders
     *
     *  @custom:security non-reentrantoa
     */
    function updateShuttle(address borrowable, bool borrowRewards) external;

    /**
     *  @notice Updates rewards for all pools
     *
     *  @custom:security non-reentrant
     */
    function accelerateTheUniverse() external;

    /**
     *  @notice Mints Cyg to the DAO according to the `cygPerBlockDAO`
     */
    function dripCygDAO() external;

    /**
     *  @notice Self destructs the contract, stopping all CYG rewards. Reverts if we have passed TOTAL_EPOCHS
     *          and `doomswitch` is not set.
     *
     *  @custom:security non-reentrant
     */
    function supernova() external;

    /**
     *  @notice Manually try and advance the epoch
     */
    function advanceEpoch() external;

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                           ARTIFICER FUNCTIONS 🛠️                                          *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @notice Initializes CYG rewards for a specific shuttle (ie. sets lender or borrower rewards).
     *  @notice Can only be initialized once! If need to modifiy use `adjustRewards`.
     *
     *  @param borrowable The address of the borrowable contract (CygUSD)
     *  @param allocPoint The alloc point for this shuttle
     *  @param borrowRewards Whether the rewards being set are for borrowers or lenders
     *
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function setShuttleRewards(address borrowable, uint256 allocPoint, bool borrowRewards) external;

    /**
     *  @notice Adjusts CYG rewards to an already initialized shuttle (for borrowers or lender rewards)
     *
     *  @param borrowable The address of the borrowable contract (CygUSD)
     *  @param allocPoint The new alloc point for this shuttle
     *  @param borrowRewards Whether the rewards being set are for borrowers or lenders
     *
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function adjustRewards(address borrowable, uint256 allocPoint, bool borrowRewards) external;

    /**
     *  @notice Adds bonus rewards to a shuttle to reward borrowers with a bonus token (aside from CYG)
     *
     *  @param borrowable The address of the borrowable contract (CygUSD)
     *  @param borrowRewards Whether this is for lender or borrower rewards
     *  @param bonusRewarder The address of the bonus rewarder to reward users in another token other than CYG
     *
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function setBonusRewarder(address borrowable, bool borrowRewards, IBonusRewarder bonusRewarder) external;

    /**
     *  @notice Removes bonus rewards from a shuttle
     *
     *  @param borrowable The address of the borrowable
     *  @param borrowRewards Whether this is for lender or borrower rewards
     *
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function removeBonusRewarder(address borrowable, bool borrowRewards) external;

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                             ADMIN FUNCTIONS 👽                                            *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @notice Sets the artificer, capable of adjusting rewards
     *
     *  @param _artificer The address of the new artificer contract
     *
     *  @custom:security only-admin 👽
     */
    function setArtificer(address _artificer) external;

    /**
     *  @notice Set the doom switch - Cannot be turned off!
     *
     *  @custom:security only-admin 👽
     *
     */
    function setDoomswitch() external;

    /**
     *  @notice Sweeps any erc20 token that was incorrectly sent to this contract
     *
     *  @param token The address of the token we are recovering
     *
     *  @custom:security only-admin 👽
     */
    function sweepToken(address token) external;

    /**
     *  @notice Sweeps native that was incorrectly sent to this contract
     *
     *  @custom:security only-admin 👽
     */
    function sweepNative() external;

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                  INITIALIZE PILLARS - CAN ONLY BE INIT ONCE                               *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @notice Initializes the contract
     *
     *  @custom:security only-admin 👽
     */
    function initializePillars() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for date time operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DateTimeLib.sol)
///
/// Conventions:
/// --------------------------------------------------------------------+
/// Unit      | Range                | Notes                            |
/// --------------------------------------------------------------------|
/// timestamp | 0..0x1e18549868c76ff | Unix timestamp.                  |
/// epochDay  | 0..0x16d3e098039     | Days since 1970-01-01.           |
/// year      | 1970..0xffffffff     | Gregorian calendar year.         |
/// month     | 1..12                | Gregorian calendar month.        |
/// day       | 1..31                | Gregorian calendar day of month. |
/// weekday   | 1..7                 | The day of the week (1-indexed). |
/// --------------------------------------------------------------------+
/// All timestamps of days are rounded down to 00:00:00 UTC.
library DateTimeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Weekdays are 1-indexed for a traditional rustic feel.

    // "And on the seventh day God finished his work that he had done,
    // and he rested on the seventh day from all his work that he had done."
    // -- Genesis 2:2

    uint256 internal constant MON = 1;
    uint256 internal constant TUE = 2;
    uint256 internal constant WED = 3;
    uint256 internal constant THU = 4;
    uint256 internal constant FRI = 5;
    uint256 internal constant SAT = 6;
    uint256 internal constant SUN = 7;

    // Months and days of months are 1-indexed for ease of use.

    uint256 internal constant JAN = 1;
    uint256 internal constant FEB = 2;
    uint256 internal constant MAR = 3;
    uint256 internal constant APR = 4;
    uint256 internal constant MAY = 5;
    uint256 internal constant JUN = 6;
    uint256 internal constant JUL = 7;
    uint256 internal constant AUG = 8;
    uint256 internal constant SEP = 9;
    uint256 internal constant OCT = 10;
    uint256 internal constant NOV = 11;
    uint256 internal constant DEC = 12;

    // These limits are large enough for most practical purposes.
    // Inputs that exceed these limits result in undefined behavior.

    uint256 internal constant MAX_SUPPORTED_YEAR = 0xffffffff;
    uint256 internal constant MAX_SUPPORTED_EPOCH_DAY = 0x16d3e098039;
    uint256 internal constant MAX_SUPPORTED_TIMESTAMP = 0x1e18549868c76ff;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DATE TIME OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of days since 1970-01-01 from (`year`,`month`,`day`).
    /// See: https://howardhinnant.github.io/date_algorithms.html
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the inputs are supported.
    function dateToEpochDay(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 epochDay) {
        /// @solidity memory-safe-assembly
        assembly {
            year := sub(year, lt(month, 3))
            let doy := add(shr(11, add(mul(62719, mod(add(month, 9), 12)), 769)), day)
            let yoe := mod(year, 400)
            let doe := sub(add(add(mul(yoe, 365), shr(2, yoe)), doy), div(yoe, 100))
            epochDay := sub(add(mul(div(year, 400), 146097), doe), 719469)
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the number of days since 1970-01-01.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDays} to check if the inputs is supported.
    function epochDayToDate(uint256 epochDay) internal pure returns (uint256 year, uint256 month, uint256 day) {
        /// @solidity memory-safe-assembly
        assembly {
            epochDay := add(epochDay, 719468)
            let doe := mod(epochDay, 146097)
            let yoe := div(sub(sub(add(doe, div(doe, 36524)), div(doe, 1460)), eq(doe, 146096)), 365)
            let doy := sub(doe, sub(add(mul(365, yoe), shr(2, yoe)), div(yoe, 100)))
            let mp := div(add(mul(5, doy), 2), 153)
            day := add(sub(doy, shr(11, add(mul(mp, 62719), 769))), 1)
            month := sub(add(mp, 3), mul(gt(mp, 9), 12))
            year := add(add(yoe, mul(div(epochDay, 146097), 400)), lt(month, 3))
        }
    }

    /// @dev Returns the unix timestamp from (`year`,`month`,`day`).
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the inputs are supported.
    function dateToTimestamp(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 result) {
        unchecked {
            result = dateToEpochDay(year, month, day) * 86400;
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the given unix timestamp.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedTimestamp} to check if the inputs are supported.
    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = epochDayToDate(timestamp / 86400);
    }

    /// @dev Returns the unix timestamp from
    /// (`year`,`month`,`day`,`hour`,`minute`,`second`).
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDateTime} to check if the inputs are supported.
    function dateTimeToTimestamp(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 result) {
        unchecked {
            result = dateToEpochDay(year, month, day) * 86400 + hour * 3600 + minute * 60 + second;
        }
    }

    /// @dev Returns (`year`,`month`,`day`,`hour`,`minute`,`second`)
    /// from the given unix timestamp.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedTimestamp} to check if the inputs are supported.
    function timestampToDateTime(
        uint256 timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        unchecked {
            (year, month, day) = epochDayToDate(timestamp / 86400);
            uint256 secs = timestamp % 86400;
            hour = secs / 3600;
            secs = secs % 3600;
            minute = secs / 60;
            second = secs % 60;
        }
    }

    /// @dev Returns if the `year` is leap.
    function isLeapYear(uint256 year) internal pure returns (bool leap) {
        /// @solidity memory-safe-assembly
        assembly {
            leap := iszero(and(add(mul(iszero(mod(year, 25)), 12), 3), year))
        }
    }

    /// @dev Returns number of days in given `month` of `year`.
    function daysInMonth(uint256 year, uint256 month) internal pure returns (uint256 result) {
        bool flag = isLeapYear(year);
        /// @solidity memory-safe-assembly
        assembly {
            // `daysInMonths = [31,28,31,30,31,30,31,31,30,31,30,31]`.
            // `result = daysInMonths[month - 1] + isLeapYear(year)`.
            result := add(byte(month, shl(152, 0x1F1C1F1E1F1E1F1F1E1F1E1F)), and(eq(month, 2), flag))
        }
    }

    /// @dev Returns the weekday from the unix timestamp.
    /// Monday: 1, Tuesday: 2, ....., Sunday: 7.
    function weekday(uint256 timestamp) internal pure returns (uint256 result) {
        unchecked {
            result = ((timestamp / 86400 + 3) % 7) + 1;
        }
    }

    /// @dev Returns if (`year`,`month`,`day`) is a supported date.
    /// - `1970 <= year <= MAX_SUPPORTED_YEAR`.
    /// - `1 <= month <= 12`.
    /// - `1 <= day <= daysInMonth(year, month)`.
    function isSupportedDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool result) {
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0)
            result := and(lt(sub(year, 1970), sub(MAX_SUPPORTED_YEAR, 1969)), and(lt(add(month, w), 12), lt(add(day, w), md)))
        }
    }

    /// @dev Returns if (`year`,`month`,`day`,`hour`,`minute`,`second`) is a supported date time.
    /// - `1970 <= year <= MAX_SUPPORTED_YEAR`.
    /// - `1 <= month <= 12`.
    /// - `1 <= day <= daysInMonth(year, month)`.
    /// - `hour < 24`.
    /// - `minute < 60`.
    /// - `second < 60`.
    function isSupportedDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool result) {
        if (isSupportedDate(year, month, day)) {
            /// @solidity memory-safe-assembly
            assembly {
                result := and(lt(hour, 24), and(lt(minute, 60), lt(second, 60)))
            }
        }
    }

    /// @dev Returns if `epochDay` is a supported unix epoch day.
    function isSupportedEpochDay(uint256 epochDay) internal pure returns (bool result) {
        unchecked {
            result = epochDay < MAX_SUPPORTED_EPOCH_DAY + 1;
        }
    }

    /// @dev Returns if `timestamp` is a supported unix timestamp.
    function isSupportedTimestamp(uint256 timestamp) internal pure returns (bool result) {
        unchecked {
            result = timestamp < MAX_SUPPORTED_TIMESTAMP + 1;
        }
    }

    /// @dev Returns the unix timestamp of the given `n`th weekday `wd`, in `month` of `year`.
    /// Example: 3rd Friday of Feb 2022 is `nthWeekdayInMonthOfYearTimestamp(2022, 2, 3, 5)`
    /// Note: `n` is 1-indexed for traditional consistency.
    /// Invalid weekdays (i.e. `wd == 0 || wd > 7`) result in undefined behavior.
    function nthWeekdayInMonthOfYearTimestamp(uint256 year, uint256 month, uint256 n, uint256 wd) internal pure returns (uint256 result) {
        uint256 d = dateToEpochDay(year, month, 1);
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let diff := sub(wd, add(mod(add(d, 3), 7), 1))
            let date := add(mul(sub(n, 1), 7), add(mul(gt(diff, 6), 7), diff))
            result := mul(mul(86400, add(date, d)), and(lt(date, md), iszero(iszero(n))))
        }
    }

    /// @dev Returns the unix timestamp of the most recent Monday.
    function mondayTimestamp(uint256 timestamp) internal pure returns (uint256 result) {
        uint256 t = timestamp;
        /// @solidity memory-safe-assembly
        assembly {
            let day := div(t, 86400)
            result := mul(mul(sub(day, mod(add(day, 3), 7)), 86400), gt(t, 345599))
        }
    }

    /// @dev Returns whether the unix timestamp falls on a Saturday or Sunday.
    /// To check whether it is a week day, just take the negation of the result.
    function isWeekEnd(uint256 timestamp) internal pure returns (bool result) {
        result = weekday(timestamp) > FRI;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              DATE TIME ARITHMETIC OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Adds `numYears` to the unix timestamp, and returns the result.
    /// Note: The result will share the same Gregorian calendar month,
    /// but different Gregorian calendar years for non-zero `numYears`.
    /// If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function addYears(uint256 timestamp, uint256 numYears) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        result = _offsetted(year + numYears, month, day, timestamp);
    }

    /// @dev Adds `numMonths` to the unix timestamp, and returns the result.
    /// Note: If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function addMonths(uint256 timestamp, uint256 numMonths) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        month = _sub(month + numMonths, 1);
        result = _offsetted(year + month / 12, _add(month % 12, 1), day, timestamp);
    }

    /// @dev Adds `numDays` to the unix timestamp, and returns the result.
    function addDays(uint256 timestamp, uint256 numDays) internal pure returns (uint256 result) {
        result = timestamp + numDays * 86400;
    }

    /// @dev Adds `numHours` to the unix timestamp, and returns the result.
    function addHours(uint256 timestamp, uint256 numHours) internal pure returns (uint256 result) {
        result = timestamp + numHours * 3600;
    }

    /// @dev Adds `numMinutes` to the unix timestamp, and returns the result.
    function addMinutes(uint256 timestamp, uint256 numMinutes) internal pure returns (uint256 result) {
        result = timestamp + numMinutes * 60;
    }

    /// @dev Adds `numSeconds` to the unix timestamp, and returns the result.
    function addSeconds(uint256 timestamp, uint256 numSeconds) internal pure returns (uint256 result) {
        result = timestamp + numSeconds;
    }

    /// @dev Subtracts `numYears` from the unix timestamp, and returns the result.
    /// Note: The result will share the same Gregorian calendar month,
    /// but different Gregorian calendar years for non-zero `numYears`.
    /// If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function subYears(uint256 timestamp, uint256 numYears) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        result = _offsetted(year - numYears, month, day, timestamp);
    }

    /// @dev Subtracts `numYears` from the unix timestamp, and returns the result.
    /// Note: If the Gregorian calendar month of the result has less days
    /// than the Gregorian calendar month day of the `timestamp`,
    /// the result's month day will be the maximum possible value for the month.
    /// (e.g. from 29th Feb to 28th Feb)
    function subMonths(uint256 timestamp, uint256 numMonths) internal pure returns (uint256 result) {
        (uint256 year, uint256 month, uint256 day) = epochDayToDate(timestamp / 86400);
        uint256 yearMonth = _totalMonths(year, month) - _add(numMonths, 1);
        result = _offsetted(yearMonth / 12, _add(yearMonth % 12, 1), day, timestamp);
    }

    /// @dev Subtracts `numDays` from the unix timestamp, and returns the result.
    function subDays(uint256 timestamp, uint256 numDays) internal pure returns (uint256 result) {
        result = timestamp - numDays * 86400;
    }

    /// @dev Subtracts `numHours` from the unix timestamp, and returns the result.
    function subHours(uint256 timestamp, uint256 numHours) internal pure returns (uint256 result) {
        result = timestamp - numHours * 3600;
    }

    /// @dev Subtracts `numMinutes` from the unix timestamp, and returns the result.
    function subMinutes(uint256 timestamp, uint256 numMinutes) internal pure returns (uint256 result) {
        result = timestamp - numMinutes * 60;
    }

    /// @dev Subtracts `numSeconds` from the unix timestamp, and returns the result.
    function subSeconds(uint256 timestamp, uint256 numSeconds) internal pure returns (uint256 result) {
        result = timestamp - numSeconds;
    }

    /// @dev Returns the difference in Gregorian calendar years
    /// between `fromTimestamp` and `toTimestamp`.
    /// Note: Even if the true time difference is less than a year,
    /// the difference can be non-zero is the timestamps are
    /// from different Gregorian calendar years
    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        toTimestamp - fromTimestamp;
        (uint256 fromYear, , ) = epochDayToDate(fromTimestamp / 86400);
        (uint256 toYear, , ) = epochDayToDate(toTimestamp / 86400);
        result = _sub(toYear, fromYear);
    }

    /// @dev Returns the difference in Gregorian calendar months
    /// between `fromTimestamp` and `toTimestamp`.
    /// Note: Even if the true time difference is less than a month,
    /// the difference can be non-zero is the timestamps are
    /// from different Gregorian calendar months.
    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        toTimestamp - fromTimestamp;
        (uint256 fromYear, uint256 fromMonth, ) = epochDayToDate(fromTimestamp / 86400);
        (uint256 toYear, uint256 toMonth, ) = epochDayToDate(toTimestamp / 86400);
        result = _sub(_totalMonths(toYear, toMonth), _totalMonths(fromYear, fromMonth));
    }

    /// @dev Returns the difference in days between `fromTimestamp` and `toTimestamp`.
    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        result = (toTimestamp - fromTimestamp) / 86400;
    }

    /// @dev Returns the difference in hours between `fromTimestamp` and `toTimestamp`.
    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        result = (toTimestamp - fromTimestamp) / 3600;
    }

    /// @dev Returns the difference in minutes between `fromTimestamp` and `toTimestamp`.
    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        result = (toTimestamp - fromTimestamp) / 60;
    }

    /// @dev Returns the difference in seconds between `fromTimestamp` and `toTimestamp`.
    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 result) {
        result = toTimestamp - fromTimestamp;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unchecked arithmetic for computing the total number of months.
    function _totalMonths(uint256 numYears, uint256 numMonths) private pure returns (uint256 total) {
        unchecked {
            total = numYears * 12 + numMonths;
        }
    }

    /// @dev Unchecked arithmetic for adding two numbers.
    function _add(uint256 a, uint256 b) private pure returns (uint256 c) {
        unchecked {
            c = a + b;
        }
    }

    /// @dev Unchecked arithmetic for subtracting two numbers.
    function _sub(uint256 a, uint256 b) private pure returns (uint256 c) {
        unchecked {
            c = a - b;
        }
    }

    /// @dev Returns the offsetted timestamp.
    function _offsetted(uint256 year, uint256 month, uint256 day, uint256 timestamp) private pure returns (uint256 result) {
        uint256 dm = daysInMonth(year, month);
        if (day >= dm) {
            day = dm;
        }
        result = dateToEpochDay(year, month, day) * 86400 + (timestamp % 86400);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(
                    or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)),
                    96
                )
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {

            } 1 {

            } {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001), 0x3fffff)
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for {
                        let w := not(0)
                    } 1 {

                    } {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) {
                            break
                        }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Store the `from` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x60, amount) // Store the `amount` argument.

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, from) // Store the `from` argument.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x40, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x6a.
            amount := mload(0x60)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x3a, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x1a, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x3a.
            amount := mload(0x3a)
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0x095ea7b3000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, account) // Store the `account` argument.
            amount := mul(
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  PillarsOfCreation.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  
    .              .            .               .      🛰️     .           .                .           .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                      . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===.*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                           .⠀
           🛰️          ███ ░███  ███ ░███                .                 .                 .⠀
        .             ░░██████  ░░██████                🛰️                             .                 .     
                       ░░░░░░    ░░░░░░      -------=========*         🛰️             .                     ⠀
           .                            .       .          .            .                        .             .⠀
        
        Pillars of Creation - https://cygnusdao.finance                                                          .                     .
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {IPillarsOfCreation} from "./interfaces/IPillarsOfCreation.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";
import {DateTimeLib} from "./libraries/DateTimeLib.sol";

// Interfaces
import {IBonusRewarder} from "./interfaces/IBonusRewarder.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {IERC20} from "./interfaces/core/IERC20.sol";
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";

// TODO FIX TIME

/**
 *  @notice The only contract capable of minting the CYG token. The CYG token is divided between the DAO and lenders
 *          or borrowers of the Cygnus protocol.
 *          It is similar to a masterchef contract but the rewards are based on epochs. Each epoch the rewards get
 *          reduced by the `REDUCTION_FACTOR_PER_EPOCH` which is set at 1%. When deploying, the contract calculates
 *          the initial rewards per block based on:
 *            - the total amount of rewards
 *            - the total number of epochs
 *            - reduction factor.
 *
 *          rewardsAtEpochN = (totalRewards - accumulatedRewards) * reductionFactor / emissionsCurve(epochN)
 *
 *                        |
 *                   800k |_______.
 *                        |       |
 *                   700k |       |
 *                        |       |                Example with 1.75M totalRewards, 2% reduction and 100 epochs
 *                   600k |       |
 *                        |       |                                Epochs    |    Rewards
 *                   500M |       |                             -------------|---------------
 *                        |       |_______.                       00 - 24    |   800,037.32
 *          rewards  400k |       |       |                       25 - 49    |   482,794.30
 *                        |       |       |                       50 - 74    |   291,349.33
 *                   300k |       |       |_______.               75 - 99    |   175,819.05
 *                        |       |       |       |                          | 1,750,000.00
 *                   200k |       |       |       |_______
 *                        |       |       |       |       |
 *                   100k |       |       |       |       |
 *                        |       |       |       |       |
 *                        |_______|_______|_______|_______|__
 *                          00-24   25-49   50-74   75-99
 *                                     epochs
 *
 *          On any interaction the `advance` function is called to check if we can advance to a new epoch. The contract
 *          self-destructs once the final epoch is reached.
 *
 *  @title  PillarsOfCreation The only contract that can mint CYG into existence
 *  @author CygnusDAO
 */
contract PillarsOfCreation is IPillarsOfCreation, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib ERC20 transfer library that gracefully handles missing return values.
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Accounting precision for rewards per share
     */
    uint256 private constant ACC_PRECISION = 1e24;

    /**
     *  @notice Total pools receiving CYG rewards - This is different to the hangar18 shuttles. In Hangar18
     *          1 shuttle contains a borrowable and collateral. In this contract each hangar18 shuttle is divided
     *          into 2 shuttles to separate between lender and borrower rewards, and each shuttle has a unique
     *          `pillarsId`.
     */
    ShuttleInfo[] private _allShuttles;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    mapping(uint256 => EpochInfo) public override getEpochInfo;

    /**
     *  @notice For lender rewards the collateral is address zero.
     *  @inheritdoc IPillarsOfCreation
     */
    mapping(address => mapping(address => ShuttleInfo)) public override getShuttleInfo; // borrowable -> collateral = Shuttle

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    mapping(address => mapping(address => mapping(address => UserInfo))) public override getUserInfo; // borrowable -> collateral -> user address = User Info

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    string public override name = "Cygnus: Pillars of Creation";

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    string public constant override version = "1.0.0";

    // Pillars settings //

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public constant override SECONDS_PER_YEAR = 31536000; // Doesn't take into account leap years

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public constant override DURATION = SECONDS_PER_YEAR * 6;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public constant override TOTAL_EPOCHS = 156;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public constant override BLOCKS_PER_EPOCH = DURATION / TOTAL_EPOCHS;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public constant override REDUCTION_FACTOR_PER_EPOCH = 0.01e18; // 1% `cygPerblock` reduction per epoch

    // Immutables //

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    IHangar18 public immutable override hangar18;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    address public immutable override cygToken;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public immutable override totalCygRewards;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public immutable override totalCygDAO;

    // Current settings

    /**
     *  @notice Can only be set once via the `initializePillars` function
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override birth;

    /**
     *  @notice Can only be set once via the `initializePillars` function
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override death;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override cygPerBlockRewards; // Rewards for Borrowers & Lenders

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override cygPerBlockDAO; // Rewards for DAO

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override totalAllocPoint;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override lastDripDAO;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    uint256 public override lastEpochTime;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    address public override artificer;

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    bool public override doomswitch;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Constructor that initializes the contract with the given `_hangar18`, `_rewardToken`, and `_cygPerBlock` values.
     *
     *  @param _hangar18 The address of the Hangar18 contract.
     *  @param _rewardToken The address of the reward token contract.
     *  @param _totalCygRewardsBorrows The amount of CYG tokens to be distributed to borrowers and lenders
     *  @param _totalCygRewardsDAO The amount of CYG tokens to be distributed to the DAO
     */
    constructor(IHangar18 _hangar18, address _rewardToken, uint256 _totalCygRewardsBorrows, uint256 _totalCygRewardsDAO) {
        // Total CYG to be distributed as rewards to lenders/borrowers
        totalCygRewards = _totalCygRewardsBorrows;

        // Total CYG to go to the DAO
        totalCygDAO = _totalCygRewardsDAO;

        // Set CYG token
        cygToken = _rewardToken;

        // Set factory
        hangar18 = _hangar18;
    }

    /**
     *  @dev This function is called for plain Ether transfers
     */
    receive() external payable {}

    /**
     *  @dev Fallback function is executed if none of the other functions match the function identifier or no data was provided with the function call.
     */
    fallback() external payable {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier cygnusAdmin Controls important parameters in both Collateral and Borrow contracts 👽
     */
    modifier cygnusAdmin() {
        _checkAdmin();
        _;
    }

    /**
     *  @custom:modifier advance Advances the epoch if necessary and self-destructs contract if all epochs are finished
     */
    modifier advance() {
        // Try and advance epoch
        _advanceEpoch();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Internal check for msg.sender admin, checks factory's current admin 👽
     */
    function _checkAdmin() private view {
        // Current admin from the factory
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (msg.sender != admin) revert PillarsOfCreation__MsgSenderNotAdmin();
    }

    /**
     *  @notice Reverts if msg.sender is not artificer
     */
    function _checkArtificer() private view {
        // Check if artificer is enabled
        if (artificerEnabled()) {
            /// @custom:error OnlyArtificer Avoid if caller is not the artificer
            if (msg.sender != artificer) revert PillarsOfCreation__OnlyArtificer();
        }
        // Artificer not enabled, check caller is admin
        else _checkAdmin();
    }

    /**
     *  @notice Returns the latest pending CYG for `account` in this shuttle
     *  @param borrowable The address of the CygnusBorrow contract (CygUSD)
     *  @param collateral The address of the CygnusCollateral contract (CygLP)
     *  @param account The address of the user
     */
    function _pendingCyg(address borrowable, address collateral, address account) private view returns (uint256 pending) {
        // Load pool to memory
        ShuttleInfo memory shuttle = getShuttleInfo[borrowable][collateral];

        // Load user to memory
        UserInfo memory user = getUserInfo[borrowable][collateral][account];

        // Load the accumulated reward per share
        uint256 accRewardPerShare = shuttle.accRewardPerShare;

        // Load total shares from the pool
        uint256 totalShares = shuttle.totalShares;

        // Current timestamp
        uint256 timestamp = getBlockTimestamp();

        // If the current block's timestamp is after the last reward time and there are shares in the pool
        if (timestamp > shuttle.lastRewardTime && totalShares != 0) {
            // Calculate the time elapsed since the last reward
            uint256 timeElapsed = timestamp - shuttle.lastRewardTime;

            // Calculate the reward for the elapsed time, using the pool's allocation point and total allocation points
            uint256 reward = (timeElapsed * cygPerBlockRewards * shuttle.allocPoint) / totalAllocPoint;

            // Add the calculated reward per share to the accumulated reward per share
            accRewardPerShare = accRewardPerShare + (reward * ACC_PRECISION) / totalShares;
        }

        // Calculate the pending reward for the user, based on their shares and the accumulated reward per share
        pending = uint256(int256((user.shares * accRewardPerShare) / ACC_PRECISION) - (user.rewardDebt));
    }

    /**
     *  @dev The pillars consists of rewards for both borrowers and lenders in each shuttle. To separate between
     *       each rewards and alloc points we set different collaterals for each, but the same borrowable.
     *       If we are setting borrow rewards then we use the actual collateral of the borrowable, if we are setting
     *       lender rewards we set the collateral as the zero address.
     */
    function _isBorrowRewards(address borrowable, bool borrowRewards) private view returns (address collateral) {
        // Check if we are adding lender or borrower rewards
        collateral = borrowRewards ? ICygnusTerminal(borrowable).collateral() : address(0);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function shuttlesLength() public view override returns (uint256) {
        return _allShuttles.length;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function getBlockTimestamp() public view override returns (uint256) {
        // Return this block's timestamp
        return block.timestamp;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function getCurrentEpoch() public view override returns (uint256 currentEpoch) {
        // Get the current timestamp
        uint256 currentTime = getBlockTimestamp();

        // Contract has expired
        if (currentTime >= death) return TOTAL_EPOCHS;

        // Current epoch
        currentEpoch = (currentTime - birth) / BLOCKS_PER_EPOCH;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function calculateEpochRewards(uint256 epoch, uint256 totalRewards) public pure override returns (uint256 rewards) {
        // Get cyg per block for the epoch
        uint256 _cygPerBlock = calculateCygPerBlock(epoch, totalRewards);

        // Return total CYG in the epoch
        return _cygPerBlock * BLOCKS_PER_EPOCH;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function emissionsCurve(uint256 epoch) public pure override returns (uint) {
        // Create the emissions curve based on the reduction factor and epoch
        uint256 oneMinusReductionFactor = 1e18 - REDUCTION_FACTOR_PER_EPOCH;

        // Total Epochs
        uint256 totalEpochs = TOTAL_EPOCHS - epoch;

        // Start at 1
        uint256 result = 1e18;

        // Loop through total epochs left
        for (uint i = 0; i < totalEpochs; i++) {
            result = result.mulWad(oneMinusReductionFactor);
        }

        return 1e18 - result;
    }

    /**
     *  @notice Same claculation as in line 64. We calculate emissions at epoch 0 and then adjust the rewards by reduction
     *          factor for gas savings.
     *  @inheritdoc IPillarsOfCreation
     */
    function calculateCygPerBlock(uint256 epoch, uint256 totalRewards) public pure override returns (uint256 rewardRate) {
        // Calculate emissions curve at epoch 0 - This is what gives the slope of the curve at each epoch, given
        // total epochs and a reduction factor:
        // rewards_at_epoch_0 = (total_cyg_rewards * reduction_factor) / emissions_curve
        //                    = (1750000 * 0.02) / 0.867380
        //                    = 40351.38
        // From here we reduce 2% of the total rewards each epoch:
        // rewards_at_epoch_1 = 40351.38 * 0.98 = 39544.35
        // rewards_at_epoch_2 = 39544.35 * 0.98 = 38753.47, etc.
        uint256 emissionsAt0 = emissionsCurve(0);

        // Get rewards for epoch 0
        uint256 rewards = totalRewards.fullMulDiv(REDUCTION_FACTOR_PER_EPOCH, emissionsAt0);

        // Get total CYG rewards for `epoch`
        for (uint i = 0; i < epoch; i++) {
            rewards = rewards.mulWad(1e18 - REDUCTION_FACTOR_PER_EPOCH);
        }

        // Return the CYG per block rate at `epoch` given `totalRewards`
        rewardRate = rewards / BLOCKS_PER_EPOCH;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Get the shuttle by Pillars ID from the `_allShuttles` array. The shuttles differ from Hangar18's
     *          allShuttles array as for every shuttle ID there are 2 pillar IDs (one pillars for borrowers and
     *          one for lenders). This reads individual shuttle for either borrowers or lenders, and not by the
     *          factory's shuttle ID.
     */
    function allShuttles(uint256 pillarsId) external view returns (ShuttleInfo memory) {
        // Read from array
        return _allShuttles[pillarsId];
    }

    /**
     *  @notice Get the shuttle by ID (not the same as hangar18 `allShuttles`)
     */
    function getShuttleById(uint256 shuttleId) external view returns (ShuttleInfo memory lenders, ShuttleInfo memory borrowers) {
        // Get shuttle ID from hangar
        (, , address borrowable, address collateral, ) = hangar18.allShuttles(shuttleId);

        // Lender's pool is always with address zero as collateral
        lenders = getShuttleInfo[borrowable][address(0)];

        // Borrower's pool is with both
        borrowers = getShuttleInfo[borrowable][collateral];
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function pendingCyg(address borrowable, address account, bool borrowRewards) external view override returns (uint256 pending) {
        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Pending CYG for this unique shuttle
        pending = _pendingCyg(borrowable, collateral, account);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function pendingCygSingle(address account, bool borrowRewards) external view returns (uint256 pending) {
        // Gas savings
        ShuttleInfo[] memory shuttles = _allShuttles;

        // Length
        uint256 totalPools = shuttles.length;

        // Loop through each shuttle
        for (uint256 i = 0; i < totalPools; i++) {
            // Get collateral
            address collateral = shuttles[i].collateral;

            // If collecting borrow rewards then we skip if collateral is address zero (lenders)
            if (borrowRewards && collateral == address(0)) continue;

            // If collecting lender rewards then we skip if collateral is not address zero
            if (!borrowRewards && collateral != address(0)) continue;

            // Collect rewards
            pending += _pendingCyg(shuttles[i].borrowable, collateral, account);
        }
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function pendingCygAll(address account) external view returns (uint256 pending) {
        // Gas savings
        ShuttleInfo[] memory shuttles = _allShuttles;

        // Length
        uint256 totalShuttles = shuttles.length;

        // Loop through each shuttle
        for (uint256 i = 0; i < totalShuttles; i++) {
            // Get pending cyg for each shuttle
            // note that these shuttles are different from hangar18 shuttles as
            // collateral can be zero address here to represent lender pools
            pending += _pendingCyg(shuttles[i].borrowable, shuttles[i].collateral, account);
        }
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function pendingBonusReward(
        address borrowable,
        address collateral,
        address account
    ) external view override returns (address token, uint256 amount) {
        // Load pool to memory
        ShuttleInfo memory shuttle = getShuttleInfo[borrowable][collateral];

        // Return bonus rewards if any
        return shuttle.bonusRewarder.pendingReward(borrowable, collateral, account);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function pendingCygDAO() external view override returns (uint256 pending) {
        // Calculate time since last dao claim
        uint256 currentTime = block.timestamp;

        // Cyg accrued for the DAO
        return (currentTime - lastDripDAO) * cygPerBlockDAO;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function totalCygClaimed() public view override returns (uint256 claimed) {
        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Loop through each epoch
        for (uint256 i = 0; i <= currentEpoch; i++) {
            // Get total claimed in this epoch and add it to previous
            claimed += getEpochInfo[i].totalClaimed;
        }
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function artificerEnabled() public view returns (bool) {
        return artificer != address(0);
    }

    // Simple view functions to get quickly

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function epochRewardsPacing() external view override returns (uint256) {
        // Get the progress to then divide by far how along we in epoch
        uint256 epochProgress = (getBlockTimestamp() - lastEpochTime).divWad(BLOCKS_PER_EPOCH);

        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Total rewards this epoch
        uint256 rewards = getEpochInfo[currentEpoch].totalRewards;

        // Claimed rewards this epoch
        uint256 claimed = getEpochInfo[currentEpoch].totalClaimed;

        // Get rewards claimed progress relative to epoch progress. ie. epoch progression is 50% and 50%
        // of rewards in this epoch have been claimed then we are at 100% or 1e18
        return claimed.divWad(rewards.mulWad(epochProgress));
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function currentEpochRewardsDAO() external view override returns (uint256) {
        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Calculate current epoch rewards
        return calculateEpochRewards(currentEpoch, totalCygDAO);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function currentEpochRewards() external view override returns (uint256) {
        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Calculate current epoch rewards
        return calculateEpochRewards(currentEpoch, totalCygRewards);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function previousEpochRewards() external view override returns (uint256) {
        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Calculate next epoch rewards
        return currentEpoch == 0 ? 0 : calculateEpochRewards(currentEpoch - 1, totalCygRewards);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function nextEpochRewards() external view override returns (uint256) {
        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Calculate next epoch rewards
        return calculateEpochRewards(currentEpoch + 1, totalCygRewards);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function blocksThisEpoch() external view override returns (uint256) {
        // Get how far along we are in this epoch in seconds
        return getBlockTimestamp() - lastEpochTime;
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function untilNextEpoch() external view override returns (uint256) {
        // Return seconds left until next epoch
        return BLOCKS_PER_EPOCH - (getBlockTimestamp() - lastEpochTime);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function untilSupernova() external view override returns (uint256) {
        // Return seconds until death
        return death - getBlockTimestamp();
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function epochProgression() external view override returns (uint256) {
        // Return how far along we are in this epoch scaled by 1e18 (0.69e18 = 69%)
        return (getBlockTimestamp() - lastEpochTime).divWad(BLOCKS_PER_EPOCH);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function totalProgression() external view override returns (uint256) {
        // Return how far along we are in total scaled by 1e18 (0.69e18 = 69%)
        return (getBlockTimestamp() - birth).divWad(DURATION);
    }

    // Datetime functions

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function timestampToDateTime(
        uint256 timestamp
    ) public pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        // Avoid repeating ourselves
        return DateTimeLib.timestampToDateTime(timestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 result) {
        // Avoid repeating ourselves
        return DateTimeLib.diffDays(fromTimestamp, toTimestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function daysUntilNextEpoch() external view override returns (uint256) {
        // Current epoch
        uint256 epoch = getCurrentEpoch();

        // If we are in the last epoch return 0
        if (epoch == TOTAL_EPOCHS - 1) return (0);

        // Return the days left for this epoch
        return diffDays(block.timestamp, getEpochInfo[epoch].end);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function daysUntilSupernova() external view override returns (uint256) {
        // Return how many days until we self-destruct
        return diffDays(block.timestamp, death);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function daysPassedThisEpoch() external view override returns (uint256) {
        // Current epoch
        uint256 epoch = getCurrentEpoch();

        // Return how many days in we are in this epoch
        return diffDays(getEpochInfo[epoch].start, block.timestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateNextEpochStart()
        external
        view
        override
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        // Current epoch
        uint256 epoch = getCurrentEpoch();

        // Get epoch end
        uint256 nextEpochTimestamp = getEpochInfo[epoch].end;

        // Return the dateTime of the next epoch start
        return timestampToDateTime(nextEpochTimestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateCurrentEpochStart()
        external
        view
        override
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        // Currrent epoch
        uint256 epoch = getCurrentEpoch();

        // block.timestamp of the start of this epoch
        uint256 thisEpochTimestamp = getEpochInfo[epoch].start;

        // Return the date time of this epoch start
        return timestampToDateTime(thisEpochTimestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateLastEpochStart()
        external
        view
        override
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        // Current epoch
        uint256 epoch = getCurrentEpoch();

        // Account for epoch 0
        if (epoch == 0) return (0, 0, 0, 0, 0, 0);

        // Get when this epoch ends
        uint256 thisEpochTimestamp = getEpochInfo[epoch - 1].start;

        // Return the datetime the last epoch began
        return timestampToDateTime(thisEpochTimestamp);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateEpochStart(
        uint256 _epoch
    ) external view override returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        // Epoch start
        uint256 epochStart = getEpochInfo[_epoch].start;

        // Return datetime of past epoch start time
        return timestampToDateTime(epochStart);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateEpochEnd(
        uint256 _epoch
    ) external view override returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        // Epoch end
        uint256 epochEnd = getEpochInfo[_epoch].end;

        // Datetime of the end of the epoch
        return timestampToDateTime(epochEnd);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     */
    function dateSupernova()
        external
        view
        override
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        // Return the datetime this contract self-destructs
        return timestampToDateTime(death);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @dev Internal function that destroys the contract and transfers remaining funds to the owner.
     */
    function _supernova() private {
        // Get epoch, uses block.timestamp - keep this function separate to getCurrentEpoch for simplicity
        uint256 epoch = getCurrentEpoch();

        // Check if current epoch is less than total epochs
        if (epoch < TOTAL_EPOCHS) return;

        // Assert we are doomed, can only be set my admin and cannot be turned off
        assert(doomswitch);

        /// @custom:event Supernova
        emit Supernova(msg.sender, birth, death, epoch);

        // Hail Satan! ʕ•ᴥ•ʔ
        //
        // By now 8 years have passed and this contract would have minted exactly:
        //
        //   totalCygRewards + totalCygRewardsDAO
        //
        // Since the Pillars are the only minter of the CYG token, no more CYG can be minted into existence.
        // Hide self destruct as it will be deprecated and not all EVMs support it (ie ZKEVM).
        // selfdestruct(payable(admin));
    }

    /**
     *  @notice Try and advance the epoch based on the time that has passed since the last epoch
     *  @notice Called after most payable functions (except `trackRewards`) to try and advance epoch
     */
    function _advanceEpoch() private {
        // Get timestamp
        uint256 currentTime = getBlockTimestamp();

        // Time since last epoch
        uint256 timeSinceLastEpoch = currentTime - lastEpochTime;

        // Get epoch since last update
        uint256 epochsPassed = timeSinceLastEpoch / BLOCKS_PER_EPOCH;

        // Update if we are at new epoch
        if (epochsPassed > 0) {
            // Get this epoch
            uint256 currentEpoch = getCurrentEpoch();

            // Check that contract is not expired
            if (currentEpoch < TOTAL_EPOCHS) {
                // Store last epoch update
                lastEpochTime = currentTime;

                // The cygPerBlock up to this epoch
                uint256 oldCygPerBlock = cygPerBlockRewards;

                // Store new cygPerBlock
                cygPerBlockRewards = calculateCygPerBlock(currentEpoch, totalCygRewards);

                // Store this info once on each advance
                EpochInfo storage epoch = getEpochInfo[currentEpoch];

                // Store start time
                epoch.start = currentTime;

                // Store estimated end time
                epoch.end = currentTime + BLOCKS_PER_EPOCH;

                // Store current epoch number
                epoch.epoch = currentEpoch;

                // Store the `cygPerBlock` of this epoch
                epoch.cygPerBlock = cygPerBlockRewards;

                // Store the planned rewards for this epoch (same as `currentEpochRewards()`)
                epoch.totalRewards = cygPerBlockRewards * BLOCKS_PER_EPOCH;

                // Assurance
                epoch.totalClaimed = 0;

                // Store the new cyg per block for the dao
                cygPerBlockDAO = calculateCygPerBlock(currentEpoch, totalCygDAO);

                /// @custom:event NewEpoch
                emit NewEpoch(currentEpoch - 1, currentEpoch, oldCygPerBlock, cygPerBlockRewards);
            }
            // If we have passed 1 epoch and the current epoch is >= TOTAL EPOCHS then we self-destruct contract
            else _supernova();
        }
    }

    /**
     *  @notice Update the specified shuttle's reward variables to the current timestamp.
     *  @notice Updates the reward information for a specific borrowable asset. It retrieves the current
     *          ShuttleInfo for the asset, calculates the reward to be distributed based on the time elapsed
     *          since the last distribution and the pool's allocation point, updates the accumulated reward
     *          per share based on the reward distributed, and stores the updated ShuttleInfo for the asset.
     *  @param borrowable The address of the borrowable asset to update.
     *  @return shuttle The updated ShuttleInfo struct.
     */
    function _updateShuttle(address borrowable, address collateral) private returns (ShuttleInfo storage shuttle) {
        // Get the pool information
        shuttle = getShuttleInfo[borrowable][collateral];

        // Current timestamp
        uint256 timestamp = getBlockTimestamp();

        // Check if rewards can be distributed
        if (timestamp > shuttle.lastRewardTime) {
            // Calculate the reward to be distributed
            uint256 totalShares = shuttle.totalShares;

            if (totalShares > 0) {
                // Get the time elapsed to calculate the reward
                uint256 timeElapsed;

                // Never underflows
                unchecked {
                    // Calculate the time elapsed since the last reward distribution
                    timeElapsed = timestamp - shuttle.lastRewardTime;
                }

                // Calculate the reward to be distributed based on the time elapsed and the pool's allocation point
                uint256 reward = (timeElapsed * cygPerBlockRewards * shuttle.allocPoint) / totalAllocPoint;

                // Update the accumulated reward per share based on the reward distributed
                shuttle.accRewardPerShare += ((reward * ACC_PRECISION) / totalShares);
            }

            // Store last block tiemstamp
            shuttle.lastRewardTime = timestamp;
        }
    }

    /**
     *  @notice Updates all shuttles in the pillars. The shuttles are not the same as the `hangar18` shuttles,
     *          since 1 shuttle ID has 2 pillars ID.
     */
    function _accelerateTheUniverse() private {
        // Gas savings
        ShuttleInfo[] memory shuttles = _allShuttles;

        // Length
        uint256 totalShuttles = shuttles.length;

        // Loop through each shuttle and update all pools - Doesn't emit event
        for (uint256 i = 0; i < totalShuttles; i++) _updateShuttle(shuttles[i].borrowable, shuttles[i].collateral);

        // Drip CYG to DAO reserves
        _dripCygDAO();

        /// @custom:event AccelerateTheUniverse
        emit AccelerateTheUniverse(totalShuttles, msg.sender, getCurrentEpoch());
    }

    /**
     *  @notice Collects the CYG the msg.sender has accrued and sends to `to`
     *  @param borrowable The address of the borrowable where borrows are stored
     *  @param to The address to send msg.sender's rewards to
     */
    function _collect(address borrowable, address collateral, address to) private returns (uint256 cygAmount) {
        // Update the pool to ensure the user's reward calculation is up-to-date.
        ShuttleInfo storage shuttle = _updateShuttle(borrowable, collateral);

        // Retrieve the user's info for the specified borrowable address.
        UserInfo storage user = getUserInfo[borrowable][collateral][msg.sender];

        // Avoid stack too deep
        {
            // Calculate the user's accumulated reward based on their shares and the pool's accumulated reward per share.
            int256 accumulatedReward = int256((user.shares * shuttle.accRewardPerShare) / ACC_PRECISION);

            // Calculate the pending reward for the user by subtracting their stored reward debt from their accumulated reward.
            cygAmount = uint256(accumulatedReward - user.rewardDebt);

            // If no rewards then return and don't collect
            if (cygAmount == 0) return 0;

            // Update the user's reward debt to reflect the current accumulated reward.
            user.rewardDebt = accumulatedReward;

            // Check for bonus rewards
            if (address(shuttle.bonusRewarder) != address(0)) {
                // Bonus rewarder is set, harvest
                shuttle.bonusRewarder.onReward(borrowable, collateral, msg.sender, to, cygAmount, user.shares);
            }
        }

        // Get current epoch
        uint256 currentEpoch = getCurrentEpoch();

        // Update total claimed for this epoch
        getEpochInfo[currentEpoch].totalClaimed += cygAmount;

        // Check that total claimed this epoch is not above the max we can mint for this epoch
        if (getEpochInfo[currentEpoch].totalClaimed > getEpochInfo[currentEpoch].totalRewards) revert("Exceeds Epoch Limit");

        // Mint new CYG
        IERC20(cygToken).mint(to, cygAmount);
    }

    /**
     *  @notice Drips CYG to the DAO reserves given the `cygPerBlockDAO` and time elapsed
     */
    function _dripCygDAO() private {
        // Calculate time since last dao claim
        uint256 currentTime = block.timestamp;

        // Cyg accrued for the DAO
        uint256 _pendingCygDAO = (currentTime - lastDripDAO) * cygPerBlockDAO;

        // Return if none accrued
        if (_pendingCygDAO == 0) return;

        // Store current time
        lastDripDAO = currentTime;

        // Latest DAO reserves contract
        address daoReserves = hangar18.daoReserves();

        // Mint new CYG
        IERC20(cygToken).mint(daoReserves, _pendingCygDAO);

        /// @custom:event CygnusDAODrip
        emit CygnusDAODrip(daoReserves, _pendingCygDAO);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Main entry point into the Pillars contract to track borrowers and lenders.
     *  @notice Rewards are tracked only from borrowables. For borrowers, rewards are updated after any borrow,
     *          repay or liquidation (via the `_updateBorrow` function). For lenders, rewards are updated after
     *          any CygUSD mint, burn or transfer (via the `_afterTokenTransfer` function).
     *  @inheritdoc IPillarsOfCreation
     */
    function trackRewards(address account, uint256 balance, address collateral) external override {
        // Don't allow the DAO to receive CYG rewards from reserves
        if (account == address(0) || account == hangar18.daoReserves()) return;

        // Interactions
        address borrowable = msg.sender;

        // Update and load to storage for gas savings
        ShuttleInfo storage shuttle = _updateShuttle(borrowable, collateral);

        // Get the user information for the borrower in the borrowable asset's pool
        UserInfo storage user = getUserInfo[borrowable][collateral][account];

        // User's latest shares
        uint256 newShares = balance;

        // Calculate the difference in shares for the borrower and update their shares
        int256 diffShares = int256(newShares) - int256(user.shares);

        // Calculate the difference in reward debt for the borrower and update their reward debt
        int256 diffRewardDebt = (diffShares * int256(shuttle.accRewardPerShare)) / int256(ACC_PRECISION);

        // Update shares
        user.shares = newShares;

        // Update reward debt
        user.rewardDebt = user.rewardDebt + diffRewardDebt;

        // Update the total shares of the pool of `borrowable` and `position`
        shuttle.totalShares = uint256(int256(shuttle.totalShares) + diffShares);

        // Check if bonus rewarder is set
        if (address(shuttle.bonusRewarder) != address(0)) {
            // Assign shares for user to receive bonus rewards
            shuttle.bonusRewarder.onReward(borrowable, collateral, account, account, 0, newShares);
        }

        /// @custom:event TrackShuttle
        emit TrackRewards(borrowable, account, balance, collateral);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function collect(
        address borrowable,
        bool borrowRewards,
        address to
    ) external override nonReentrant advance returns (uint256 cygAmount) {
        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Checks to see if there is any pending CYG to be collected and sends to user
        cygAmount = _collect(borrowable, collateral, to);

        /// @custom:event Collect
        emit Collect(borrowable, collateral, to, cygAmount);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function collectAllSingle(address to, bool borrowRewards) external nonReentrant advance returns (uint256 cygAmount) {
        // Gas savings
        ShuttleInfo[] memory shuttles = _allShuttles;

        // Length
        uint256 totalPools = shuttles.length;

        // Loop through each shuttle
        for (uint256 i = 0; i < totalPools; i++) {
            // Get collateral
            address collateral = shuttles[i].collateral;

            // If collecting borrow rewards then we skip if collateral is address zero (lenders)
            if (borrowRewards && collateral == address(0)) continue;

            // If collecting lender rewards then we skip if collateral is not address zero
            if (!borrowRewards && collateral != address(0)) continue;

            // Collect rewards
            cygAmount += _collect(shuttles[i].borrowable, collateral, to);
        }

        /// @custom:event CollectAll
        emit CollectAllSingle(totalPools, cygAmount, borrowRewards);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function collectAll(address to) external override nonReentrant advance returns (uint256 cygAmount) {
        // Gas savings
        ShuttleInfo[] memory shuttles = _allShuttles;

        // Length
        uint256 totalPools = shuttles.length;

        // Loop through each shuttle
        for (uint256 i = 0; i < totalPools; i++) {
            // Collect lend rewards
            cygAmount += _collect(shuttles[i].borrowable, shuttles[i].collateral, to);
        }

        /// @custom:event CollectAll
        emit CollectAll(totalPools, cygAmount);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function updateShuttle(address borrowable, bool borrowRewards) external override nonReentrant {
        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Update the borrower's pool for this borrowable
        _updateShuttle(borrowable, collateral);

        /// @custom:event UpdateShuttle
        emit UpdateShuttle(borrowable, collateral, msg.sender, block.timestamp, getCurrentEpoch());
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function advanceEpoch() external override nonReentrant advance {}

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function accelerateTheUniverse() external override nonReentrant advance {
        // Manually updates all shuttles in the Pillars
        _accelerateTheUniverse();
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function dripCygDAO() external override nonReentrant advance {
        // Drip CYG to dao since `lastDripDAO`
        _dripCygDAO();
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security non-reentrant
     */
    function supernova() external override nonReentrant advance {
        // Manually updates all shuttles in the Pillars
        _accelerateTheUniverse();

        // Tries to self destruct the contract
        _supernova();
    }

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                           ARTIFICER FUNCTIONS 🛠️                                          *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function setShuttleRewards(address borrowable, uint256 allocPoint, bool borrowRewards) external override advance {
        // Check if artificer is enabled, else check admin
        _checkArtificer();

        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Load shuttle rewards
        ShuttleInfo storage shuttle = getShuttleInfo[borrowable][collateral];

        /// @custom:error ShuttleAlreadyInitialized Avoid initializing shuttle rewards twice
        if (shuttle.active) revert PillarsOfCreation__ShuttleAlreadyInitialized();

        // Update the total allocation points for Pillars
        totalAllocPoint = totalAllocPoint + allocPoint;

        // Enable shuttle rewards, cannot be initialized again
        shuttle.active = true;

        // Assign shuttle alloc points
        shuttle.allocPoint = allocPoint;

        // Assign core contracts
        shuttle.borrowable = borrowable;
        shuttle.collateral = collateral; // _isBorrowRewards returns address zero for lender rewards

        // Lending pool ID - Shared by borrow and lending rewards
        shuttle.shuttleId = ICygnusTerminal(borrowable).shuttleId();

        // Unique reward pool ID
        shuttle.pillarsId = _allShuttles.length;

        // Push to shuttles array
        _allShuttles.push(shuttle);

        /// @custom:event NewShuttleRewards
        emit NewShuttleRewards(borrowable, collateral, totalAllocPoint, allocPoint);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function adjustRewards(address borrowable, uint256 allocPoint, bool borrowRewards) external override advance {
        // Check if artificer is enabled, else check admin
        _checkArtificer();

        // Get collateral (lending rewards use address(0) as collateral)
        address collateral = borrowRewards ? ICygnusTerminal(borrowable).collateral() : address(0);

        // Load rewards
        ShuttleInfo storage shuttle = getShuttleInfo[borrowable][collateral];

        /// @custom:error ShuttleAlreadyInitialized Avoid initializing twice
        if (!shuttle.active) revert PillarsOfCreation__ShuttleNotInitialized();

        // Old alloc
        uint256 oldAlloc = shuttle.allocPoint;

        // Update the total allocation points (lender rewards have already been set, or else we revert)
        totalAllocPoint = (totalAllocPoint - oldAlloc) + allocPoint;

        // Assign new points
        shuttle.allocPoint = allocPoint;

        // Update pool in array
        _allShuttles[shuttle.pillarsId].allocPoint = allocPoint;

        /// @custom:event NewShuttleAllocPoint
        emit NewShuttleAllocPoint(borrowable, collateral, oldAlloc, allocPoint);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function setBonusRewarder(address borrowable, bool borrowRewards, IBonusRewarder bonusRewarder) external override advance {
        // Check if artificer is enabled, else check admin
        _checkArtificer();

        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Load lender rewards
        ShuttleInfo storage shuttle = getShuttleInfo[borrowable][collateral];

        /// @custom:error ShuttleAlreadyInitialized Avoid initializing twice
        if (!shuttle.active) revert PillarsOfCreation__ShuttleNotInitialized();

        // Assign bonus shuttle rewards
        shuttle.bonusRewarder = bonusRewarder;

        /// @custom:event NewBonusRewarder
        emit NewBonusRewarder(borrowable, collateral, bonusRewarder);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-artificer-or-admin 🛠️
     */
    function removeBonusRewarder(address borrowable, bool borrowRewards) external override advance {
        // Check if artificer is enabled, else check admin
        _checkArtificer();

        // Get collateral (lender rewards is the zero address, borrow rewards we get the borrowable's collateral)
        address collateral = _isBorrowRewards(borrowable, borrowRewards);

        // Load lender rewards
        ShuttleInfo storage shuttle = getShuttleInfo[borrowable][collateral];

        /// @custom:error ShuttleAlreadyInitialized Avoid initializing twice
        if (!shuttle.active) revert PillarsOfCreation__ShuttleNotInitialized();

        // Assign bonus shuttle rewards
        shuttle.bonusRewarder = IBonusRewarder(address(0));

        /// @custom:event NewBonusRewarder
        emit RemoveBonusRewarder(borrowable, collateral);
    }

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                             ADMIN FUNCTIONS 👽                                            *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-admin 👽
     */
    function setArtificer(address _artificer) external override advance cygnusAdmin {
        // Artificer up until now
        address oldArtificer = artificer;

        // Assign new artificer contract - Capable of adjusting shuttle rewards, bonus rewards, etc.
        artificer = _artificer;

        /// @custom;event NewArtificer
        emit NewArtificer(oldArtificer, _artificer);
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-admin 👽
     */
    function setDoomswitch() external override advance cygnusAdmin {
        // Set the doom switch, cannot be turned off!
        if (doomswitch) return;

        // Set the doomswitch - Contract can self destruct now
        doomswitch = true;

        /// @custom:event DoomSwitchSet
        emit DoomSwitchSet(block.timestamp, msg.sender, doomswitch);
    }

    /**
     *  @notice This contract should never have any token balance, including CYG
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-admin 👽
     */
    function sweepToken(address token) external override advance cygnusAdmin {
        // Balance this contract has of the erc20 token we are recovering
        uint256 balance = token.balanceOf(address(this));

        // Transfer token to admin
        if (balance > 0) token.safeTransfer(msg.sender, balance);

        /// @custom:event SweepToken
        emit SweepToken(token, msg.sender, balance, getCurrentEpoch());
    }

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-admin
     */
    function sweepNative() external override advance cygnusAdmin {
        // Get native balance
        uint256 balance = address(this).balance;

        // Get ETH out
        if (balance > 0) SafeTransferLib.safeTransferETH(msg.sender, balance);

        /// @custom:event SweepToken
        emit SweepToken(address(0), msg.sender, balance, getCurrentEpoch());
    }

    /*  -------------------------------------------------------------------------------------------------------  *
     *                                  INITIALIZE PILLARS - CAN ONLY BE INIT ONCE                               *
     *  -------------------------------------------------------------------------------------------------------  */

    /**
     *  @inheritdoc IPillarsOfCreation
     *  @custom:security only-admin 👽
     */
    function initializePillars() external override cygnusAdmin {
        /// @custom:error PillarsAlreadyInitialized Avoid initializing pillars twice
        if (birth != 0) revert PillarsOfCreation__PillarsAlreadyInitialized();

        // Calculate the cygPerBlock at epoch 0 for rewards
        cygPerBlockRewards = calculateCygPerBlock(0, totalCygRewards);

        // Calculate the cygPerBlock for the DAO
        cygPerBlockDAO = calculateCygPerBlock(0, totalCygDAO);

        // Gas savings
        uint256 _birth = block.timestamp;

        // Birth of pillars
        birth = _birth;

        // Timestamp of when the contract self-destructs
        death = _birth + DURATION;

        // Start epoch
        lastEpochTime = _birth;

        // Store the last drip as pillars initialized time
        lastDripDAO = _birth;

        // Store epoch
        getEpochInfo[0] = EpochInfo({
            epoch: 0,
            start: _birth,
            end: _birth + BLOCKS_PER_EPOCH,
            cygPerBlock: cygPerBlockRewards,
            totalRewards: cygPerBlockRewards * BLOCKS_PER_EPOCH,
            totalClaimed: 0
        });

        /// @custom;event InitializePillars
        emit InitializePillars(birth, death, cygPerBlockRewards, cygPerBlockDAO);

        /// @custom:event NewEpoch
        emit NewEpoch(0, 0, 0, cygPerBlockRewards);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}