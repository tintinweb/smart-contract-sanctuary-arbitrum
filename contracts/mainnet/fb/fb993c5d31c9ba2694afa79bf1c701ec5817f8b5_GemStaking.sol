// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeERC20 } from "./SafeERC20.sol";
import { IERC20 } from "./IERC20.sol";
import { Address } from "./Address.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";
import { Ownable, Ownable2Step } from "./Ownable2Step.sol";

/// @title Staking contract
/// @notice The staking contract allows you to stake the token for one year,
/// and there will be no rewards or interest, withdraw will only be after the year of the staking date is completed.

contract GemStaking is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @member The stake amount of staker
    /// @member The stake end time
    struct Stake {
        uint256 amount;
        uint256 endTime;
    }

    /// @notice The ERC20 token
    IERC20 public token;

    /// @notice Lockup period in seconds only
    uint256 public immutable LOCKUP_PERIOD;

    /// @notice Minimum amount a staker can stake
    uint256 public minStakeAmount;

    /// @notice Number of time a staker has staked
    mapping(address => mapping(uint256 => Stake)) public stakes;

    /// @notice Index for tracking latest staker stakes
    mapping(address => uint256) public stakeIndex;

    /// @dev Emitted when a staker stakes tokens
    event Staked(address indexed staker, uint256 amount, uint256 indexed stakerStakeIndex, uint256 stakeEndTime);

    /// @dev Emitted when a staker unstakes tokens
    event Unstaked(address indexed staker, uint256 amount, uint256 indexed stakerUnstakeIndex);

    /// @dev Emitted when the owner updates the minimum stake amount
    event MinimumAmountChanged(uint256 previousMinStakeAmount, uint256 newMinStakeAmount);

    /// @notice Thrown when the amount is less than minimum stake amount
    error InvalidAmount();

    /// @notice Thrown when the amount is equal to 0
    error ZeroAmount();

    /// @notice Thrown when the address is equal to 0
    error ZeroAddress();

    /// @notice Thrown when the minimum amount being set is same as current
    error SameMinValue();

    /// @notice Thrown when the lockedup period is not completed
    error LockupPeriodNotOver();

    /// @dev Constructor
    /// @param tokenAddress The address of the ERC20 token to stake
    /// @param minStakeValue The minimum stake amount
    /// @param lockupDuration The lockup time
    /// @param owner The address of owner wallet
    constructor(IERC20 tokenAddress, uint256 minStakeValue, uint256 lockupDuration, address owner) Ownable(owner) {
        if (address(tokenAddress) == address(0)) {
            revert ZeroAddress();
        }

        if (minStakeValue == 0 || lockupDuration == 0) {
            revert ZeroAmount();
        }

        token = tokenAddress;
        minStakeAmount = minStakeValue;
        LOCKUP_PERIOD = lockupDuration;
    }

    /// @notice Stakes staker tokens
    /// @param amount The amount to stake
    function stake(uint256 amount) external nonReentrant {
        if (amount < minStakeAmount) {
            revert InvalidAmount();
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 stakeEndTime = block.timestamp + LOCKUP_PERIOD;
        uint256 stakerStakeIndex = stakeIndex[msg.sender]++;
        stakes[msg.sender][stakerStakeIndex] = Stake({ amount: amount, endTime: stakeEndTime });
        emit Staked({
            staker: msg.sender,
            amount: amount,
            stakerStakeIndex: stakerStakeIndex,
            stakeEndTime: stakeEndTime
        });
    }

    /// @notice Unstakes tokens in a batch
    /// @param indexes The array of indexes at which the amount lies to unstake
    function unstake(uint256[] calldata indexes) external nonReentrant {
        uint256 indexesLength = indexes.length;
        for (uint256 i; i < indexesLength; ++i) {
            _unstake(indexes[i]);
        }
    }

    /// @notice Changes the minimum stake amount
    /// @param newMinAmount The minimum amount to stake
    function changeMinStakeAmount(uint256 newMinAmount) external onlyOwner {
        if (newMinAmount == 0) {
            revert ZeroAmount();
        }

        uint256 previoustMinAmount = minStakeAmount;
        _checkForIdenticalValue(newMinAmount, previoustMinAmount);
        emit MinimumAmountChanged({ previousMinStakeAmount: previoustMinAmount, newMinStakeAmount: newMinAmount });
        minStakeAmount = newMinAmount;
    }

    /// @dev Checks and reverts if updating the previous value with the same value
    function _checkForIdenticalValue(uint256 previousValue, uint256 newValue) private pure {
        if (previousValue == newValue) {
            revert SameMinValue();
        }
    }

    /// @dev Unstakes tokens after a year
    /// @param index The index at which the amount lies to unstake
    function _unstake(uint256 index) private {
        Stake memory stakerStake = stakes[msg.sender][index];
        if (stakerStake.amount == 0) {
            revert ZeroAmount();
        }

        if (block.timestamp < stakerStake.endTime) {
            revert LockupPeriodNotOver();
        }

        delete stakes[msg.sender][index];
        token.safeTransfer(msg.sender, stakerStake.amount);
        emit Unstaked({ staker: msg.sender, amount: stakerStake.amount, stakerUnstakeIndex: index });
    }
}