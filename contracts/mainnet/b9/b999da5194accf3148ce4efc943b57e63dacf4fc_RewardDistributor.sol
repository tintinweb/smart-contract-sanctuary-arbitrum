// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

//     _   ____________________           __  __       ____               _____ __                  
//    / | / / ____/_  __/ ____/___ ______/ /_/ /_     / __ \___ _   __   / ___// /_  ____ _________ 
//   /  |/ / /_    / / / __/ / __ `/ ___/ __/ __ \   / /_/ / _ \ | / /   \__ \/ __ \/ __ `/ ___/ _ \
//  / /|  / __/   / / / /___/ /_/ / /  / /_/ / / /  / _, _/  __/ |/ /   ___/ / / / / /_/ / /  /  __/
// /_/ |_/_/     /_/ /_____/\__,_/_/   \__/_/ /_/  /_/ |_|\___/|___/   /____/_/ /_/\__,_/_/   \___/ 
                                                                                                 

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import {IveNFTE} from "./IveNFTE.sol";

/// @notice This contract is used to distribute rewards to xNFTE holders
/// @dev This contract Distributes rewards based on user's checkpointed xNFTE balance.
contract RewardDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // @todo Update the below addresses
    address public constant EMERGENCY_RETURN = address(0xC24223341415Bc8CaB0ffA5C2A6200d835fB1FF5); // Emergency return address
    address public constant xNFTE = address(0xfD26252f8D76BbeBa001A06CBA94FE113DA8DcE6); // xNFTE contract address
    address public constant USDC = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); // Native Arbitrum USDC Token address
    uint256 public constant WEEK = 7 days;
    uint256 public constant REWARD_CHECKPOINT_DEADLINE = 1 days;

    uint256 public startTime; // Start time for reward distribution
    uint256 public lastRewardCheckpointTime; // Last time when reward was checkpointed
    uint256 public lastRewardBalance = 0; // Last reward balance of the contract
    uint256 public maxIterations = 50; // Max number of weeks a user can claim rewards in a transaction

    mapping(uint256 => uint256) public rewardsPerWeek; // Reward distributed per week
    mapping(address => uint256) public timeCursorOf; // Timestamp of last user checkpoint
    mapping(uint256 => uint256) public xNFTESupply; // Store the xNFTE supply per week

    bool public canCheckpointReward; // Checkpoint reward flag
    bool public isKilled = false;

    event Claimed(
    address indexed _recipient,
    uint256 _amount,
    uint256 _lastRewardClaimTime,
    uint256 _rewardClaimedTill
);
    event RewardsCheckpointed(uint256 _amount);
    event CheckpointAllowed(bool _allowed);
    event Killed();
    event RecoveredERC20(address _token, uint256 _amount);
    event MaxIterationsUpdated(uint256 _oldNo, uint256 _newNo);

    constructor(uint256 _startTime) public {
        uint256 t = (_startTime / WEEK) * WEEK;
        // All time initialization is rounded to the week
        startTime = t; // Decides the start time for reward distibution
        lastRewardCheckpointTime = t; //reward checkpoint timestamp
    }

    /// @notice Function to add rewards in the contract for distribution
    /// @param value The amount of Token to add
    /// @dev This function is only for sending in Token.
    function addRewards(uint256 value) external nonReentrant {
        require(!isKilled);
        require(value > 0, "Reward amount must be > 0");
        IERC20(USDC).safeTransferFrom(_msgSender(), address(this), value);
        if (
            canCheckpointReward &&
            (block.timestamp >
                lastRewardCheckpointTime + REWARD_CHECKPOINT_DEADLINE)
        ) {
            _checkpointReward();
        }
    }

    /// @notice Update the reward checkpoint
    /// @dev Calculates the total number of tokens to be distributed in a given week.
    ///     During setup for the initial distribution this function is only callable
    ///     by the contract owner. Beyond initial distro, it can be enabled for anyone
    ///     to call.
    function checkpointReward() external nonReentrant {
        require(
            _msgSender() == owner() ||
                (canCheckpointReward &&
                    block.timestamp >
                    (lastRewardCheckpointTime + REWARD_CHECKPOINT_DEADLINE)),
            "Checkpointing not allowed"
        );
        _checkpointReward();
    }

   function claim() external returns (uint256) {
    return claim(_msgSender());
}

    /// @notice Function to enable / disable checkpointing of tokens
    /// @dev To be called by the owner only
    function toggleAllowCheckpointReward() external onlyOwner {
        canCheckpointReward = !canCheckpointReward;
        emit CheckpointAllowed(canCheckpointReward);
    }

    /*****************************
     *  Emergency Control
     ******************************/

    /// @notice Function to update the maximum iterations for the claim function.
    /// @param newIterationNum  The new maximum iterations for the claim function.
    /// @dev To be called by the owner only.
    function updateMaxIterations(uint256 newIterationNum) external onlyOwner {
        require(newIterationNum > 0, "Max iterations must be > 0");
        uint256 oldIterationNum = maxIterations;
        maxIterations = newIterationNum;
        emit MaxIterationsUpdated(oldIterationNum, newIterationNum);
    }

    /// @notice Function to kill the contract.
    /// @dev Killing transfers the entire Token balance to the emergency return address
    ///      and blocks the ability to claim or addRewards.
    /// @dev The contract can't be unkilled.
    function killMe() external onlyOwner {
        require(!isKilled);
        isKilled = true;
        IERC20(USDC).safeTransfer(
            EMERGENCY_RETURN,
            IERC20(USDC).balanceOf(address(this))
        );
        emit Killed();
    }

    /// @notice Recover ERC20 tokens from this contract
    /// @dev Tokens are sent to the emergency return address
    /// @param _coin token address
    function recoverERC20(address _coin) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        require(_coin != USDC, "Can't recover Token tokens");
        uint256 amount = IERC20(_coin).balanceOf(address(this));
        IERC20(_coin).safeTransfer(EMERGENCY_RETURN, amount);
        emit RecoveredERC20(_coin, amount);
    }

    /// @notice Function to get the user earnings at a given timestamp.
    /// @param addr The address of the user
    /// @dev This function gets only for 50 days worth of rewards.
    /// @return total rewards earned by user, lastRewardCollectionTime, rewardsTill
    /// @dev lastRewardCollectionTime, rewardsTill are in terms of WEEK Cursor.
    function computeRewards(address addr)
        external
        view
        returns (
            uint256, // total rewards earned by user
            uint256, // lastRewardCollectionTime
            uint256 // rewardsTill
        )
    {
        uint256 _lastRewardCheckpointTime = lastRewardCheckpointTime;
        // Compute the rounded last token time
        _lastRewardCheckpointTime = (_lastRewardCheckpointTime / WEEK) * WEEK;
        (uint256 rewardsTill, uint256 totalRewards) = _computeRewards(
            addr,
            _lastRewardCheckpointTime
        );
        uint256 lastRewardCollectionTime = timeCursorOf[addr];
        if (lastRewardCollectionTime == 0) {
            lastRewardCollectionTime = startTime;
        }
        return (totalRewards, lastRewardCollectionTime, rewardsTill);
    }

    /// @notice Claim fees for the address


    function claim(address user) private nonReentrant returns (uint256) {
    uint256 lastClaimWeek =
        timeCursorOf[user] >= startTime
            ? (timeCursorOf[user] - startTime) / WEEK
            : 0;
    uint256 currentWeek = (block.timestamp - startTime) / WEEK;
    uint256 totalRewards = 0;

    for (uint256 i = lastClaimWeek; i <= currentWeek && i < maxIterations; i++) {
        uint256 xNFTEBalance = IveNFTE(xNFTE).balanceOf(user);
        xNFTEBalance = xNFTEBalance * rewardsPerWeek[i];
        if (xNFTESupply[i] != 0) {
            xNFTEBalance = xNFTEBalance / xNFTESupply[i];
        }

        totalRewards += xNFTEBalance;
        timeCursorOf[user] += WEEK; // move the cursor
    }

    require(totalRewards > 0, "Nothing to claim");

    // Transfer out the total rewards
    IERC20(USDC).safeTransfer(user, totalRewards);

    emit Claimed(user, totalRewards, lastClaimWeek, currentWeek);

    return totalRewards;
}
       

    /// @notice Checkpoint reward
    /// @dev Checkpoint rewards for at most 20 weeks at a time
    function _checkpointReward() internal {
        // Calculate the amount to distribute
        uint256 tokenBalance = IERC20(USDC).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - lastRewardBalance;
        lastRewardBalance = tokenBalance;

        uint256 t = lastRewardCheckpointTime;
        // Store the period of the last checkpoint
        uint256 sinceLast = block.timestamp - t;
        lastRewardCheckpointTime = block.timestamp;
        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;

        for (uint256 i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            xNFTESupply[thisWeek] = IveNFTE(xNFTE).totalSupply(thisWeek);
            // Calculate share for the ongoing week
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0) {
                    rewardsPerWeek[thisWeek] += toDistribute;
                } else {
                    // In case of a gap in time of the distribution
                    // Reward is divided across the remainder of the week
                    rewardsPerWeek[thisWeek] +=
                        (toDistribute * (block.timestamp - t)) /
                        sinceLast;
                }
                break;
                // Calculate share for all the past weeks
            } else {
                rewardsPerWeek[thisWeek] +=
                    (toDistribute * (nextWeek - t)) /
                    sinceLast;
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }

        emit RewardsCheckpointed(toDistribute);
    }

    /// @notice Get the nearest user epoch for a given timestamp
    /// @param addr The address of the user
    /// @param ts The timestamp
    /// @param maxEpoch The maximum possible epoch for the user.
    function _findUserTimestampEpoch(
        address addr,
        uint256 ts,
        uint256 maxEpoch
    ) internal view returns (uint256) {
        uint256 min = 0;
        uint256 max = maxEpoch;

        // Binary search
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (IveNFTE(xNFTE).getUserPointHistoryTS(addr, mid) <= ts) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /// @notice Function to initialize user's reward weekCursor
    /// @param addr The address of the user
    /// @return weekCursor The weekCursor of the user
    function _initializeUser(address addr)
        internal
        view
        returns (uint256 weekCursor)
    {
        uint256 userEpoch = 0;
        // Get the user's max epoch
        uint256 maxUserEpoch = IveNFTE(xNFTE).userPointEpoch(addr);

        require(maxUserEpoch > 0, "User has no deposit");

        // Find the Timestamp curresponding to reward distribution start time
        userEpoch = _findUserTimestampEpoch(addr, startTime, maxUserEpoch);

        // In case the User deposits after the startTime
        // binary search returns userEpoch as 0
        if (userEpoch == 0) {
            userEpoch = 1;
        }
        // Get the user deposit timestamp
        uint256 userPointTs = IveNFTE(xNFTE).getUserPointHistoryTS(
            addr,
            userEpoch
        );
        // Compute the initial week cursor for the user for claiming the reward.
        weekCursor = ((userPointTs + WEEK - 1) / WEEK) * WEEK;
        // If the week cursor is less than the reward start time
        // Update it to the reward start time.
        if (weekCursor < startTime) {
            weekCursor = startTime;
        }
        return weekCursor;
    }

    /// @notice Function to get the total rewards for the user.
    /// @param addr The address of the user
    /// @param _lastRewardCheckpointTime The last reward checkpoint
    /// @return WeekCursor of User, TotalRewards
    function _computeRewards(address addr, uint256 _lastRewardCheckpointTime)
        internal
        view
        returns (
            uint256, // WeekCursor
            uint256 // TotalRewards
        )
    {
        uint256 toDistrbute = 0;
        // Get the user's reward time cursor.
        uint256 weekCursor = timeCursorOf[addr];

        if (weekCursor == 0) {
            weekCursor = _initializeUser(addr);
        }

        // Iterate over the weeks
        for (uint256 i = 0; i < maxIterations; i++) {
            // Users can't claim the reward for the ongoing week.
            if (weekCursor >= _lastRewardCheckpointTime) {
                break;
            }

            // Get the week's balance for the user
            uint256 balance = IveNFTE(xNFTE).balanceOf(addr, weekCursor);
            if (balance > 0) {
                // Compute the user's share for the week.
                toDistrbute +=
                    (balance * rewardsPerWeek[weekCursor]) /
                    xNFTESupply[weekCursor];
            }

            weekCursor += WEEK;
        }

        return (weekCursor, toDistrbute);
    }
}