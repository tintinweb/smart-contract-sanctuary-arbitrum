// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import {FundRaisingGuild} from "./FundRaisingGuild.sol";


/// @title Fund raising platform facilitated by launch pool
/// @author BlockRocket.tech, Syndika
/// @notice Fork of MasterChef.sol from SushiSwap
/// @dev Only the POOL_MANAGEMENT_ROLE role can add new pools
contract LaunchPoolAccessControlERC20FundRaisingWithDelayedVesting is ReentrancyGuard, AccessControl {
    // keccak256("ADMIN_ROLE")
    bytes32 public constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
    // keccak256("POOL_MANAGEMENT_ROLE")
    bytes32 public constant POOL_MANAGEMENT_ROLE = 0x748e6e704f9e8a0607dcd3ee9838387c62f0e3ff37c2fdfde1bff8fd2bfd2729;
    // keccak256("FUND_MANAGEMENT_ROLE")
    bytes32 public constant FUND_MANAGEMENT_ROLE = 0x242fde9ae62216221a403f62519bf9b82fc4b05920f032ad90c1f21986721dc2;

    using SafeERC20 for IERC20;

    /// @dev Details about each user in a pool
    struct UserInfo {
        uint256 amount; // How many tokens are staked in a pool
        uint256 pledgeFundingAmount; // Based on staked tokens, the funding that has come from the user (or not if they choose to pull out)
        uint256 rewardDebtRewards; // Reward debt. See explanation below.
        uint256 tokenAllocDebt;
        //
        // We do some fancy math here. Basically, once vesting has started in a pool (if they have deposited), the amount of reward tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebtRewards
        //
        // The amount can never change once the staking period has ended
    }

    /// @dev Info of each pool.
    struct PoolInfo {
        IERC20 rewardToken; // Address of the reward token contract.
        IERC20 fundRaisingToken; // Address of the fund raising token contract.
        uint256 tokenAllocationStartTimestamp; // Timestamp when users stake counts towards earning reward token allocation
        uint256 stakingEndTimestamp; // Before this timestamp, staking is permitted
        uint256 pledgeFundingEndTimestamp; // Between stakingEndTimestamp and this number pledge funding is permitted
        uint256 targetRaise; // Amount that the project wishes to raise
        uint256 maxStakingAmountPerUser; // Max. amount of tokens that can be staked per account/user
    }

    /// @notice staking token is fixed for all pools
    IERC20 public stakingToken;

    /// @notice Container for holding all rewards
    FundRaisingGuild public rewardGuildBank;

    /// @notice List of pools that users can stake into
    PoolInfo[] public poolInfo;

    /// @notice Pool to accumulated share counters
    mapping(uint256 => uint256) public poolIdToAccPercentagePerShare;
    mapping(uint256 => uint256) public poolIdToLastPercentageAllocTimestamp;

    /// @notice Number of reward tokens distributed per timestamp for this pool
    mapping(uint256 => uint256) public poolIdToRewardPerTimestamp;

    /// @notice Last timestamp number that reward token distribution took place
    mapping(uint256 => uint256) public poolIdToLastRewardTimestamp;

    /// @notice Timestamp number when rewards start
    mapping(uint256 => uint256) public poolIdToRewardStartTimestamp;

    /// @notice Timestamp number when cliff ends
    mapping(uint256 => uint256) public poolIdToRewardCliffEndTimestamp;

    /// @notice Timestamp number when rewards end
    mapping(uint256 => uint256) public poolIdToRewardEndTimestamp;

    /// @notice Per LPOOL token staked, how much reward token earned in pool that users will get
    mapping(uint256 => uint256) public poolIdToAccRewardPerShareVesting;

    /// @notice Total rewards being distributed up to rewardEndTimestamp
    mapping(uint256 => uint256) public poolIdToMaxRewardTokensAvailableForVesting;

    /// @notice Total amount staked into the pool
    mapping(uint256 => uint256) public poolIdToTotalStaked;

    /// @notice Total amount of funding received by stakers after stakingEndTimestamp and before pledgeFundingEndTimestamp
    mapping(uint256 => uint256) public poolIdToTotalRaised;

    /// @notice For every staker that funded their pledge, the sum of all of their allocated percentages
    mapping(uint256 => uint256) public poolIdToTotalFundedPercentageOfTargetRaise;

    /// @notice True when funds have been claimed
    mapping(uint256 => bool) public poolIdToFundsClaimed;

    /// @notice Per pool, info of each user that stakes ERC20 tokens.
    /// @notice Pool ID => User Address => User Info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice Available before staking ends for any given project. Essentitally 100% to 18 dp
    uint256 public constant TOTAL_TOKEN_ALLOCATION_POINTS = (100 * (10 ** 18));

    event ContractDeployed(address indexed guildBank);
    event PoolAdded(uint256 indexed pid);
    event PoolRewardTokenAdded(uint256 indexed pid, address rewardToken);
    event Pledge(address indexed user, uint256 indexed pid, uint256 amount);
    event PledgeFunded(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsSetUp(uint256 indexed pid, uint256 amount, uint256 rewardEndTimestamp);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event FundRaisingClaimed(uint256 indexed pid, address indexed recipient, uint256 amount);

    /// @param _stakingToken Address of the staking token for all pools
    /// @param admins Addresses of the admins who will be able to grant roles
    constructor(IERC20 _stakingToken, address[] memory admins) {
        require(
            _checkZeroAddress(address(_stakingToken)) && _checkDeadAddress(address(_stakingToken)),
            "constructor: _stakingToken must not be zero address"
        );

        stakingToken = _stakingToken;
        rewardGuildBank = new FundRaisingGuild(address(this));

        _setRoleAdmin(POOL_MANAGEMENT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(FUND_MANAGEMENT_ROLE, ADMIN_ROLE);

        for (uint256 i = 0; i < admins.length; ) {
            _grantRole(ADMIN_ROLE, admins[i]);
            unchecked {
                ++i;
            }
        }

        emit ContractDeployed(address(rewardGuildBank));
    }

    /**
     * @notice Batch grant roles. Can be called only by admin.
     * @param roles Roles to be granted
     * @param accounts Accounts
     */
    function batchGrantRole(bytes32[] memory roles, address[] memory accounts) public onlyRole(ADMIN_ROLE) {
        require(roles.length == accounts.length, "batchGrantRole: roles and accounts must be same length");

        for (uint256 i = 0; i < accounts.length; ) {
            _grantRole(roles[i], accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the number of pools that have been added by the owner
    /// @return Number of pools
    function numberOfPools() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @dev Can only be called by the contract pool manager
    function add(
        IERC20 _rewardToken,
        IERC20 _fundRaisingToken,
        uint256 _tokenAllocationStartTimestamp,
        uint256 _stakingEndTimestamp,
        uint256 _pledgeFundingEndTimestamp,
        uint256 _targetRaise,
        uint256 _maxStakingAmountPerUser,
        bool _withUpdate
    ) public onlyRole(POOL_MANAGEMENT_ROLE) {
        address fundRaisingTokenAddress = address(_fundRaisingToken);
        require(
            _checkZeroAddress(fundRaisingTokenAddress) && _checkDeadAddress(fundRaisingTokenAddress),
            "add: _fundRaisingToken is zero address"
        );
        require(
            _tokenAllocationStartTimestamp < _stakingEndTimestamp,
            "add: _tokenAllocationStartTimestamp must be before staking end"
        );
        require(_stakingEndTimestamp < _pledgeFundingEndTimestamp, "add: staking end must be before funding end");
        require(_targetRaise > 0, "add: Invalid raise amount");

        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo.push(
            PoolInfo({
                rewardToken: _rewardToken,
                fundRaisingToken: _fundRaisingToken,
                tokenAllocationStartTimestamp: _tokenAllocationStartTimestamp,
                stakingEndTimestamp: _stakingEndTimestamp,
                pledgeFundingEndTimestamp: _pledgeFundingEndTimestamp,
                targetRaise: _targetRaise,
                maxStakingAmountPerUser: _maxStakingAmountPerUser
            })
        );

        poolIdToLastPercentageAllocTimestamp[poolInfo.length - 1] = _tokenAllocationStartTimestamp;

        emit PoolAdded(poolInfo.length - 1);
    }

    /**
     * @notice Step 1. Enter to stake the `_amount` of `stakingToken`. Then the allocation mining starts.
     * @param _pid Pool Id.
     * @param _amount Amount to stake.
     */
    function pledge(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "pledge: Invalid PID");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_amount > 0, "pledge: No pledge specified");
        require(block.timestamp <= pool.stakingEndTimestamp, "pledge: Staking no longer permitted");

        require(
            user.amount + _amount <= pool.maxStakingAmountPerUser,
            "pledge: can not exceed max staking amount per user"
        );

        updatePool(_pid);

        user.amount = user.amount + _amount;
        user.tokenAllocDebt = user.tokenAllocDebt + (_amount * poolIdToAccPercentagePerShare[_pid]) / 1e18;

        poolIdToTotalStaked[_pid] = poolIdToTotalStaked[_pid] + _amount;

        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit Pledge(msg.sender, _pid, _amount);
    }

    /**
     * @notice Get the mined allocation to be funded.
     * @param _pid Pool Id.
     */
    function getPledgeFundingAmount(uint256 _pid) public view returns (uint256) {
        require(_pid < poolInfo.length, "getPledgeFundingAmount: Invalid PID");
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][msg.sender];

        (uint256 accPercentPerShare, ) = getAccPercentagePerShareAndLastAllocTimestamp(_pid);

        uint256 userPercentageAllocated = (user.amount * accPercentPerShare) / 1e18 - user.tokenAllocDebt;
        return (userPercentageAllocated * pool.targetRaise) / TOTAL_TOKEN_ALLOCATION_POINTS;
    }

    /**
     * @notice Step 2. Pay for allocation.
     * @param _pid Pool Id
     */
    function fundPledge(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "fundPledge: Invalid PID");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.pledgeFundingAmount == 0, "fundPledge: Pledge has already been funded");

        require(block.timestamp > pool.stakingEndTimestamp, "fundPledge: Staking is still taking place");
        require(
            block.timestamp <= pool.pledgeFundingEndTimestamp,
            "fundPledge: Deadline has passed to fund your pledge"
        );

        require(user.amount > 0, "fundPledge: Must have staked");
        uint256 pledgeFundingAmount = getPledgeFundingAmount(_pid);
        require(pledgeFundingAmount > 0, "fundPledge: must have positive pledge amount");

        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.safeTransferFrom(msg.sender, address(this), pledgeFundingAmount);

        poolIdToTotalRaised[_pid] = poolIdToTotalRaised[_pid] + pledgeFundingAmount;

        (uint256 accPercentPerShare, ) = getAccPercentagePerShareAndLastAllocTimestamp(_pid);
        uint256 userPercentageAllocated = (user.amount * accPercentPerShare) / 1e18 - user.tokenAllocDebt;
        poolIdToTotalFundedPercentageOfTargetRaise[_pid] =
            poolIdToTotalFundedPercentageOfTargetRaise[_pid] +
            userPercentageAllocated;

        user.pledgeFundingAmount = pledgeFundingAmount; // ensures pledges can only be done once

        stakingToken.safeTransfer(address(msg.sender), user.amount);

        emit PledgeFunded(msg.sender, _pid, pledgeFundingAmount);
    }

    /**
     * @param _pid Pool Id
     * @return raised - Total amount raised.
     * @return target - Target amount to be raised.
     */
    function getTotalRaisedVsTarget(uint256 _pid) external view returns (uint256 raised, uint256 target) {
        return (poolIdToTotalRaised[_pid], poolInfo[_pid].targetRaise);
    }

    /**
     * @notice Pool management role set up the reward token.
     * @param _pid Pool Id
     * @param _rewardToken Reward token that will be distributed
     */
    function setRewardTokenOnPool(uint256 _pid, IERC20 _rewardToken) external onlyRole(POOL_MANAGEMENT_ROLE) {
        require(_pid < poolInfo.length, "setRewardTokenOnPool: Invalid PID");
        address rewardTokenAddress = address(_rewardToken);
        require(
            _checkZeroAddress(rewardTokenAddress) && _checkDeadAddress(rewardTokenAddress),
            "setRewardTokenOnPool: _rewardToken is zero address"
        );
        PoolInfo storage pool = poolInfo[_pid];
        require(address(pool.rewardToken) == address(0), "setRewardTokenOnPool: rewardToken already set");
        pool.rewardToken = _rewardToken;
        emit PoolRewardTokenAdded(_pid, rewardTokenAddress);
    }

    /**
     * @notice Step 3. Setup vesting be pool management role.
     * @param _pid - Pool Id
     * @param _rewardAmount - Amount of reward tokens to be distributed
     * @param _rewardStartTimestamp - Reward Start Timestamp
     * @param _rewardCliffEndTimestamp - Timestamp number when cliff ends
     * @param _rewardEndTimestamp - Vesting end timestamp
     */
    function setupVestingRewards(
        uint256 _pid,
        uint256 _rewardAmount,
        uint256 _rewardStartTimestamp,
        uint256 _rewardCliffEndTimestamp,
        uint256 _rewardEndTimestamp
    ) external nonReentrant onlyRole(POOL_MANAGEMENT_ROLE) {
        require(_pid < poolInfo.length, "setupVestingRewards: Invalid PID");
        require(_rewardStartTimestamp > block.timestamp, "setupVestingRewards: start timestamp in the past");
        require(
            _rewardCliffEndTimestamp >= _rewardStartTimestamp,
            "setupVestingRewards: Cliff must be after or equal to start timestamp"
        );
        require(
            _rewardEndTimestamp > _rewardCliffEndTimestamp,
            "setupVestingRewards: end timestamp must be after cliff timestamp"
        );

        PoolInfo storage pool = poolInfo[_pid];
        address rewardTokenAddress = address(pool.rewardToken);
        require(
            _checkZeroAddress(rewardTokenAddress) && _checkDeadAddress(rewardTokenAddress),
            "setupVestingRewards: rewardToken is zero address"
        );

        require(block.timestamp > pool.pledgeFundingEndTimestamp, "setupVestingRewards: Stakers are still pledging");

        uint256 vestingLength = _rewardEndTimestamp - _rewardStartTimestamp;

        poolIdToMaxRewardTokensAvailableForVesting[_pid] = _rewardAmount;
        poolIdToRewardPerTimestamp[_pid] = _rewardAmount / vestingLength;

        poolIdToRewardStartTimestamp[_pid] = _rewardStartTimestamp;
        poolIdToLastRewardTimestamp[_pid] = _rewardStartTimestamp;

        poolIdToRewardCliffEndTimestamp[_pid] = _rewardCliffEndTimestamp;

        poolIdToRewardEndTimestamp[_pid] = _rewardEndTimestamp;

        pool.rewardToken.safeTransferFrom(msg.sender, address(rewardGuildBank), _rewardAmount);

        emit RewardsSetUp(_pid, _rewardAmount, _rewardEndTimestamp);
    }

    /**
     * @notice Get pending vesting rewards for user
     * @param _pid Pool Id
     * @param _user User address
     */
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "pendingRewards: invalid _pid");

        UserInfo memory user = userInfo[_pid][_user];

        // If they have staked but have not funded their pledge, they are not entitled to rewards
        if (user.pledgeFundingAmount == 0) {
            return 0;
        }

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];
        uint256 rewardEndTimestamp = poolIdToRewardEndTimestamp[_pid];
        uint256 lastRewardTimestamp = poolIdToLastRewardTimestamp[_pid];
        uint256 rewardPerTimestamp = poolIdToRewardPerTimestamp[_pid];
        if (block.timestamp > lastRewardTimestamp && rewardEndTimestamp != 0 && poolIdToTotalStaked[_pid] != 0) {
            uint256 maxEndTimestamp = block.timestamp <= rewardEndTimestamp ? block.timestamp : rewardEndTimestamp;
            uint256 multiplier = getMultiplier(lastRewardTimestamp, maxEndTimestamp);
            uint256 reward = multiplier * rewardPerTimestamp;
            accRewardPerShare = accRewardPerShare + (reward * 1e18) / poolIdToTotalFundedPercentageOfTargetRaise[_pid];
        }

        (uint256 accPercentPerShare, ) = getAccPercentagePerShareAndLastAllocTimestamp(_pid);
        uint256 userPercentageAllocated = (user.amount * accPercentPerShare) / 1e18 - user.tokenAllocDebt;
        return (userPercentageAllocated * accRewardPerShare) / 1e18 - user.rewardDebtRewards;
    }

    /**
     * @dev update all pools.
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update pool parameters
     * @param _pid Pool Id
     */
    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "updatePool: invalid _pid");

        PoolInfo storage _poolInfo = poolInfo[_pid];

        // staking not started
        if (block.timestamp < _poolInfo.tokenAllocationStartTimestamp) {
            return;
        }

        // if no one staked, nothing to do
        if (poolIdToTotalStaked[_pid] == 0) {
            poolIdToLastPercentageAllocTimestamp[_pid] = block.timestamp;
            return;
        }

        // token allocation not finished
        uint256 maxEndTimestampForPercentAlloc = block.timestamp <= _poolInfo.stakingEndTimestamp
            ? block.timestamp
            : _poolInfo.stakingEndTimestamp;
        uint256 timestampsSinceLastPercentAlloc = getMultiplier(
            poolIdToLastPercentageAllocTimestamp[_pid],
            maxEndTimestampForPercentAlloc
        );

        if (poolIdToRewardEndTimestamp[_pid] == 0 && timestampsSinceLastPercentAlloc > 0) {
            (uint256 accPercentPerShare, uint256 lastAllocTimestamp) = getAccPercentagePerShareAndLastAllocTimestamp(
                _pid
            );
            poolIdToAccPercentagePerShare[_pid] = accPercentPerShare;
            poolIdToLastPercentageAllocTimestamp[_pid] = lastAllocTimestamp;
        }

        // project has not sent rewards
        if (poolIdToRewardEndTimestamp[_pid] == 0) {
            return;
        }

        // cliff has not passed for pool
        if (block.timestamp < poolIdToRewardCliffEndTimestamp[_pid]) {
            return;
        }

        uint256 rewardEndTimestamp = poolIdToRewardEndTimestamp[_pid];
        uint256 lastRewardTimestamp = poolIdToLastRewardTimestamp[_pid];
        uint256 maxEndTimestamp = block.timestamp <= rewardEndTimestamp ? block.timestamp : rewardEndTimestamp;
        uint256 multiplier = getMultiplier(lastRewardTimestamp, maxEndTimestamp);

        // No point in doing any more logic as the rewards have ended
        if (multiplier == 0) {
            return;
        }

        uint256 rewardPerTimestamp = poolIdToRewardPerTimestamp[_pid];
        uint256 reward = multiplier * rewardPerTimestamp;

        poolIdToAccRewardPerShareVesting[_pid] =
            poolIdToAccRewardPerShareVesting[_pid] +
            (reward * 1e18) /
            poolIdToTotalFundedPercentageOfTargetRaise[_pid];
        poolIdToLastRewardTimestamp[_pid] = maxEndTimestamp;
    }

    /**
     * @notice Get accumulated percentage per share and last allocation timestamp
     * @param _pid Pool Id
     * @return accPercentPerShare - accumulated percentage per share
     * @return lastAllocTimestamp - last allocation timestamp
     */
    function getAccPercentagePerShareAndLastAllocTimestamp(
        uint256 _pid
    ) internal view returns (uint256 accPercentPerShare, uint256 lastAllocTimestamp) {
        PoolInfo memory _poolInfo = poolInfo[_pid];
        uint256 tokenAllocationPeriodInTimestamps = _poolInfo.stakingEndTimestamp -
            _poolInfo.tokenAllocationStartTimestamp;

        uint256 allocationAvailablePerTimestamp = TOTAL_TOKEN_ALLOCATION_POINTS / tokenAllocationPeriodInTimestamps;

        uint256 maxEndTimestampForPercentAlloc = block.timestamp <= _poolInfo.stakingEndTimestamp
            ? block.timestamp
            : _poolInfo.stakingEndTimestamp;
        uint256 multiplier = getMultiplier(poolIdToLastPercentageAllocTimestamp[_pid], maxEndTimestampForPercentAlloc);
        uint256 totalPercentageUnlocked = multiplier * allocationAvailablePerTimestamp;

        return (
            poolIdToAccPercentagePerShare[_pid] + (totalPercentageUnlocked * 1e18) / poolIdToTotalStaked[_pid],
            maxEndTimestampForPercentAlloc
        );
    }

    /**
     * @notice Claim vested rewards
     * @param _pid Pool Id
     */
    function claimReward(uint256 _pid) public nonReentrant {
        updatePool(_pid);

        require(block.timestamp >= poolIdToRewardCliffEndTimestamp[_pid], "claimReward: Not past cliff");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.pledgeFundingAmount > 0, "claimReward: Nice try pal");

        PoolInfo storage pool = poolInfo[_pid];
        address rewardTokenAddress = address(pool.rewardToken);
        require(
            _checkZeroAddress(address(rewardTokenAddress)) && _checkDeadAddress(address(rewardTokenAddress)),
            "claimReward: rewardToken is zero address"
        );

        uint256 accRewardPerShare = poolIdToAccRewardPerShareVesting[_pid];

        (uint256 accPercentPerShare, ) = getAccPercentagePerShareAndLastAllocTimestamp(_pid);
        uint256 userPercentageAllocated = (user.amount * accPercentPerShare) / 1e18 - user.tokenAllocDebt;
        uint256 pending = (userPercentageAllocated * accRewardPerShare) / 1e18 - user.rewardDebtRewards;

        if (pending > 0) {
            user.rewardDebtRewards = (userPercentageAllocated * accRewardPerShare) / 1e18;
            safeRewardTransfer(pool.rewardToken, msg.sender, pending);

            emit RewardClaimed(msg.sender, _pid, pending);
        }
    }

    /**
     * @notice withdraw only permitted post `pledgeFundingEndTimestamp` and you can only take out full amount if you did not fund the pledge
     * @dev functions like the old emergency withdraw as it does not concern itself with claiming rewards
     * @param _pid Pool Id
     */
    function withdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "withdraw: invalid _pid");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "withdraw: No stake to withdraw");
        require(user.pledgeFundingAmount == 0, "withdraw: Only allow non-funders to withdraw");
        require(block.timestamp > pool.pledgeFundingEndTimestamp, "withdraw: Not yet permitted");

        uint256 withdrawAmount = user.amount;

        // remove the record for this user
        delete userInfo[_pid][msg.sender];

        stakingToken.safeTransfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    /**
     * @notice Claim fundRaising token by Pool management role.
     * @param _pid Pool Id
     */
    function claimFundRaising(uint256 _pid) external nonReentrant onlyRole(FUND_MANAGEMENT_ROLE) {
        require(_pid < poolInfo.length, "claimFundRaising: invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];

        uint256 rewardPerTimestamp = poolIdToRewardPerTimestamp[_pid];
        require(rewardPerTimestamp != 0, "claimFundRaising: rewards not yet sent");
        require(poolIdToFundsClaimed[_pid] == false, "claimFundRaising: Already claimed funds");

        poolIdToFundsClaimed[_pid] = true;
        // this will fail if the sender does not have the right amount of the token
        pool.fundRaisingToken.transfer(msg.sender, poolIdToTotalRaised[_pid]);

        emit FundRaisingClaimed(_pid, msg.sender, poolIdToTotalRaised[_pid]);
    }

    ////////////
    // Private /
    ////////////

    /// @dev Safe reward transfer function, just in case if rounding error causes pool to not have enough rewards.
    function safeRewardTransfer(IERC20 _rewardToken, address _to, uint256 _amount) private {
        uint256 bal = rewardGuildBank.tokenBalance(_rewardToken);
        if (_amount > bal) {
            rewardGuildBank.withdrawTo(_rewardToken, _to, bal);
        } else {
            rewardGuildBank.withdrawTo(_rewardToken, _to, _amount);
        }
    }

    /// @notice Return reward multiplier over the given _from to _to timestamp.
    /// @param _from Timestamp number
    /// @param _to Timestamp number
    /// @return Number of timestamps that have passed
    function getMultiplier(uint256 _from, uint256 _to) private pure returns (uint256) {
        return _to - _from;
    }

    /**
     * @notice Cheap check `_wallet` to not be `0xdeaD` address
     * @param _wallet Address to check
     * @return _res false if `_wallet` equals Dead address
     */
    function _checkDeadAddress(address _wallet) internal pure returns (bool _res) {
        assembly {
            _res := true
            if eq(_wallet, 0xdEaD) {
                _res := false
            }
        }
    }

    /**
     * @notice Cheap check `_wallet` to not be `0x0` address
     * @param _wallet Address to check
     * @return _res false if `_wallet` equals Zero address
     */
    function _checkZeroAddress(address _wallet) internal pure returns (bool _res) {
        assembly {
            _res := true
            if eq(_wallet, 0x0) {
                _res := false
            }
        }
    }
}