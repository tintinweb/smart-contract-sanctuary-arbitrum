// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IRewarder, IERC20 } from "./IRewarder.sol";

// @dev This is an internal struct, placed here as its shared between multiple libraries.
struct RewardPool {
    uint256 accRewardPerShare;
    address rewardToken;
    uint48 lastRewardTime;
    uint48 allocPoints;
    IERC20 stakingToken;
    bool removed;
    mapping(address => uint256) rewardDebt;
}

/// @notice A rewarder that can distribute multiple reward tokens (ERC20 and native) to `StargateStaking` pools.
/// @dev The native token is encoded as 0x0.
interface IMultiRewarder is IRewarder {
    struct RewardDetails {
        uint256 rewardPerSec;
        uint160 totalAllocPoints;
        uint48 start;
        uint48 end;
        bool exists;
    }

    /// @notice MultiRewarder renounce ownership is disabled.
    error MultiRewarderRenounceOwnershipDisabled();
    /// @notice The token is not connected to the staking contract, connect it first.
    error MultiRewarderDisconnectedStakingToken(address token);
    /// @notice This token is not registered via `setReward` yet, register it first.
    error MultiRewarderUnregisteredToken(address token);
    /**
     *  @notice Due to various functions looping over the staking tokens connected to a reward token,
     *          a maximum number of such links is instated.
     */
    error MultiRewarderMaxPoolsForRewardToken();
    /**
     *  @notice Due to various functions looping over the reward tokens connected to a staking token,
     *          a maximum number of such links is instated.
     */
    error MultiRewarderMaxActiveRewardTokens();
    /// @notice The function can only be called while the pool hasn't ended yet.
    error MultiRewarderPoolFinished(address rewardToken);
    /// @notice The pool emission duration cannot be set to zero, as this would cause the rewards to be voided.
    error MultiRewarderZeroDuration();
    /// @notice The pool start time cannot be set in the past, as this would cause the rewards to be voided.
    error MultiRewarderStartInPast(uint256 start);
    /**
     *  @notice The recipient failed to handle the receipt of the native tokens, do they have a receipt hook?
     *          If not, use `emergencyWithdraw`.
     */
    error MultiRewarderNativeTransferFailed(address to, uint256 amount);
    /**
     *  @notice A wrong `msg.value` was provided while setting a native reward, make sure it matches the function
     *          `amount`.
     */
    error MultiRewarderIncorrectNative(uint256 expected, uint256 actual);
    /**
     *  @notice Due to a zero input or rounding, the reward rate while setting this pool would be zero,
     *          which is not allowed.
     */
    error MultiRewarderZeroRewardRate();

    /// @notice Emitted when additional rewards were added to a pool, extending the reward duration.
    event RewardExtended(address indexed rewardToken, uint256 amountAdded, uint48 newEnd);
    /**
     *  @notice Emitted when a reward token has been registered. Can be emitted again for the same token after it has
     *          been explicitly stopped.
     */
    event RewardRegistered(address indexed rewardToken);
    /// @notice Emitted when the reward pool has been adjusted or intialized, with the new params.
    event RewardSet(
        address indexed rewardToken,
        uint256 amountAdded,
        uint256 amountPeriod,
        uint48 start,
        uint48 duration
    );
    /// @notice Emitted whenever rewards are claimed via the staking pool.
    event RewardsClaimed(address indexed user, address[] rewardTokens, uint256[] amounts);
    /**
     *  @notice Emitted whenever a new staking pool combination was registered via the allocation point adjustment
     *          function.
     */
    event PoolRegistered(address indexed rewardToken, IERC20 indexed stakeToken);
    /// @notice Emitted when the owner adjusts the allocation points for pools.
    event AllocPointsSet(address indexed rewardToken, IERC20[] indexed stakeToken, uint48[] allocPoint);
    /// @notice Emitted when a reward token is stopped.
    event RewardStopped(address indexed rewardToken, address indexed receiver, bool pullTokens);

    /**
     *  @notice Sets the reward for `rewards` of `rewardToken` over `duration` seconds, starting at `start`. The actual
     *          reward over this period will be increased by any rewards on the pool that haven't been distributed yet.
     */
    function setReward(address rewardToken, uint256 rewards, uint48 start, uint48 duration) external payable;
    /**
     *  @notice Extends the reward duration for `rewardToken` by `amount` tokens, extending the duration by the
     *          equivalent time according to the `rewardPerSec` rate of the pool.
     */
    function extendReward(address rewardToken, uint256 amount) external payable;
    /**
     *  @notice Configures allocation points for a reward token over multiple staking tokens, setting the `allocPoints`
     *          for each `stakingTokens` and updating the `totalAllocPoint` for the `rewardToken`. The allocation
     *          points of any non-provided staking tokens will be left as-is, and won't be reset to zero.
     */
    function setAllocPoints(
        address rewardToken,
        IERC20[] calldata stakingTokens,
        uint48[] calldata allocPoints
    ) external;
    /**
     *  @notice Unregisters a reward token fully, immediately preventing users from ever harvesting their pending
     *          accumulated rewards. Optionally `pullTokens` can be set to false which causes the token balance to
     *          not be sent to the owner, this should only be set to false in case the token is bugged and reverts.
     */
    function stopReward(address rewardToken, address receiver, bool pullTokens) external;

    /**
     *  @notice Returns the reward pools linked to the `stakingToken` alongside the pending rewards for `user`
     *          for these pools.
     */
    function getRewards(IERC20 stakingToken, address user) external view returns (address[] memory, uint256[] memory);

    /// @notice Returns the allocation points for the `rewardToken` over all staking tokens linked to it.
    function allocPointsByReward(
        address rewardToken
    ) external view returns (IERC20[] memory stakingTokens, uint48[] memory allocPoints);
    /// @notice Returns the allocation points for the `stakingToken` over all reward tokens linked to it.
    function allocPointsByStake(
        IERC20 stakingToken
    ) external view returns (address[] memory rewardTokens, uint48[] memory allocPoints);

    /// @notice Returns all enabled reward tokens. Stopped reward tokens are not included, while ended rewards are.
    function rewardTokens() external view returns (address[] memory);
    /// @notice Returns the emission details of a `rewardToken`, configured via `setReward`.
    function rewardDetails(address rewardToken) external view returns (RewardDetails memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *  @notice A rewarder is connected to the staking contract and distributes rewards whenever the staking contract
 *          updates the rewarder.
 */
interface IRewarder {
    /**
     *  @notice This function is only callable by the staking contract.
     */
    error MultiRewarderUnauthorizedCaller(address caller);
    /**
     *  @notice The rewarder cannot be reconnected to the same staking token as it would cause wrongful reward
     *          attribution through reconfiguration.
     */
    error RewarderAlreadyConnected(IERC20 stakingToken);

    /**
     *  @notice Emitted when the rewarder is connected to a staking token.
     */
    event RewarderConnected(IERC20 indexed stakingToken);

    /**
     *  @notice Informs the rewarder of an update in the staking contract, such as a deposit, withdraw or claim.
     *  @dev Emergency withdrawals draw the balance of a user to 0, and DO NOT call `onUpdate`.
     *       The rewarder logic must keep this in mind!
     */
    function onUpdate(IERC20 token, address user, uint256 oldStake, uint256 oldSupply, uint256 newStake) external;

    /**
     *  @notice Called by the staking contract whenever this rewarder is connected to a staking token in the staking
     *          contract. Should only be callable once per staking token to avoid wrongful reward attribution through
     *          reconfiguration.
     */
    function connect(IERC20 stakingToken) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IMultiRewarder, RewardPool } from "../interfaces/IMultiRewarder.sol";

/// @dev Library which handles staking rewards.
library RewardLib {
    uint256 private constant PRECISION = 10 ** 24;

    function indexAndUpdate(
        RewardPool storage pool,
        IMultiRewarder.RewardDetails storage rewardDetails,
        address user,
        uint256 oldStake,
        uint256 totalSupply
    ) internal returns (uint256) {
        uint256 accRewardPerShare = index(pool, rewardDetails, totalSupply);
        return update(pool, user, oldStake, accRewardPerShare);
    }

    function update(
        RewardPool storage pool,
        address user,
        uint256 oldStake,
        uint256 accRewardPerShare
    ) internal returns (uint256) {
        uint256 rewardsForUser = ((accRewardPerShare - pool.rewardDebt[user]) * oldStake) / PRECISION;
        pool.rewardDebt[user] = accRewardPerShare;
        return rewardsForUser;
    }

    function index(
        RewardPool storage pool,
        IMultiRewarder.RewardDetails storage rewardDetails,
        uint256 totalSupply
    ) internal returns (uint256 accRewardPerShare) {
        accRewardPerShare = _index(pool, rewardDetails, totalSupply);
        pool.accRewardPerShare = accRewardPerShare;
        pool.lastRewardTime = uint48(block.timestamp);
    }

    function _index(
        RewardPool storage pool,
        IMultiRewarder.RewardDetails storage rewardDetails,
        uint256 totalSupply
    ) internal view returns (uint256) {
        // max(start, lastRewardTime)
        uint256 start = rewardDetails.start > pool.lastRewardTime ? rewardDetails.start : pool.lastRewardTime;
        // min(end, now)
        uint256 end = rewardDetails.end < block.timestamp ? rewardDetails.end : block.timestamp;
        if (start >= end || totalSupply == 0 || rewardDetails.totalAllocPoints == 0) {
            return pool.accRewardPerShare;
        }

        return
            (rewardDetails.rewardPerSec * (end - start) * pool.allocPoints * PRECISION) /
            rewardDetails.totalAllocPoints /
            totalSupply +
            pool.accRewardPerShare;
    }

    function getRewards(
        RewardPool storage pool,
        IMultiRewarder.RewardDetails storage rewardDetails,
        address user,
        uint256 oldStake,
        uint256 oldSupply
    ) internal view returns (uint256) {
        uint256 accRewardPerShare = _index(pool, rewardDetails, oldSupply);
        return ((accRewardPerShare - pool.rewardDebt[user]) * oldStake) / PRECISION;
    }
}