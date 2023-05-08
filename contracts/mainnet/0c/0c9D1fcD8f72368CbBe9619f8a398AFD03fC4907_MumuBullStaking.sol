/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Auth {
	address private owner;
	mapping (address => bool) private authorizations;

	constructor(address _owner) {
		owner = _owner;
		authorizations[_owner] = true;
	}

	modifier onlyOwner() {
		require(isOwner(msg.sender), "!OWNER"); _;
	}

	modifier authorized() {
		require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
	}

	function authorize(address adr) public onlyOwner {
		authorizations[adr] = true;
	}

	function unauthorize(address adr) public onlyOwner {
		authorizations[adr] = false;
	}

	function isOwner(address account) public view returns (bool) {
		return account == owner;
	}

	function isAuthorized(address adr) public view returns (bool) {
		return authorizations[adr];
	}

	function transferOwnership(address payable adr) public onlyOwner {
		owner = adr;
		authorizations[adr] = true;
		emit OwnershipTransferred(adr);
	}

	event OwnershipTransferred(address owner);
}

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MumuBullStaking is Auth {

	struct Stake {
		uint256 amount;
		uint128 totalExcluded;
		uint128 totalRealised;
	}

	address public immutable stakingToken;
	address public rewardToken;
	uint152 private _lastContractBalance;
	uint8 private constant _updatesPerPeriod = 7;
	uint32 private constant _distributionPeriod = 7 days;
	uint32 private _periodStarted;
	uint32 private _lastPeriodUpdate;
	uint128 private _periodTotalRewards;
	uint128 private _nextPeriodTokens;
	uint128 public totalRealised;
	uint128 public totalStaked;
	uint256 private constant _accuracyFactor = 10 ** 18;
	uint256 private _rewardsPerToken;
	mapping (address => Stake) public stakes;

	event Realised(address account, uint256 amount);
	event Staked(address account, uint256 amount);
	event Unstaked(address account, uint256 amount);

	error ZeroAmount();
	error InsufficientStake(uint256 attempted, uint256 available);
	error StakingTokenRescue();

	constructor (address _stakingToken, address _rewardToken) Auth(msg.sender) {
		stakingToken = _stakingToken;
		rewardToken = _rewardToken;
	}

	function getTotalRewards() external view returns (uint256) {
		return totalRealised + IERC20(rewardToken).balanceOf(address(this));
	}

	function getCumulativeRewardsPerToken() external view returns (uint256) {
		return _rewardsPerToken;
	}

	function getLastContractBalance() external view returns (uint256) {
		return _lastContractBalance;
	}

	function getStake(address account) external view returns (Stake memory) {
		return stakes[account];
	}

	function getStakedAmount(address account) public view returns (uint256) {
		return stakes[account].amount;
	}

	function getRealisedEarnings(address staker) external view returns (uint256) {
		return stakes[staker].totalRealised;
	}

	function getUnrealisedEarnings(address staker) external view returns (uint256) {
		uint256 amount = getStakedAmount(staker);
		if (amount == 0) {
			return 0;
		}

		uint256 stakerTotalRewards = amount * (_rewardsPerToken + _calculateRewardsToAdd()) / _accuracyFactor;
		uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

		if (stakerTotalRewards <= stakerTotalExcluded) {
			return 0;
		}

		return stakerTotalRewards - stakerTotalExcluded;
	}

	function getCumulativeRewards(uint256 amount) public view returns (uint256) {
		return amount * _rewardsPerToken / _accuracyFactor;
	}

	function stake(uint256 amount) external {
		if (amount == 0) {
			revert ZeroAmount();
		}
		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		_stake(msg.sender, amount);
	}

	function stakeFor(address staker, uint256 amount) external {
		if (amount == 0) {
			revert ZeroAmount();
		}

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		_stake(staker, amount);
	}

	function stakeAll() external {
		uint256 amount = IERC20(stakingToken).balanceOf(msg.sender);
		if (amount == 0) {
			revert ZeroAmount();
		}

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		_stake(msg.sender, amount);
	}

	function unstake(uint256 amount) external {
		if (amount == 0) {
			revert ZeroAmount();
		}

		_unstake(msg.sender, amount);
	}

	function forceUnstake(address account, uint256 amount) external authorized {
		if (amount == 0) {
			revert ZeroAmount();
		}
		_unstake(account, amount);
	}

	function unstakeAll() external {
		uint256 amount = getStakedAmount(msg.sender);
		if (amount == 0) {
			revert ZeroAmount();
		}

		_unstake(msg.sender, amount);
	}

	function realise() external {
		_realise(msg.sender);
	}

	function _realise(address staker) private {
		_updateRewards();

		if (getStakedAmount(staker) == 0) {
			return;
		}

		uint128 amount = uint128(earnt(staker));
		if (amount == 0) {
			return;
		}

		unchecked {
			stakes[staker].totalRealised += amount;
			stakes[staker].totalExcluded += amount;
			totalRealised += amount;
		}
		IERC20(rewardToken).transfer(staker, amount);
		_updateRewards();

		emit Realised(staker, amount);
	}

	function earnt(address staker) private view returns (uint256) {
		uint256 amount = getStakedAmount(msg.sender);
		if (amount == 0) {
			return 0;
		}

		uint256 stakerTotalRewards = getCumulativeRewards(amount);
		uint256 stakerTotalExcluded = stakes[staker].totalExcluded;
		if (stakerTotalRewards <= stakerTotalExcluded) {
			return 0;
		}

		return stakerTotalRewards - stakerTotalExcluded;
	}

	function _stake(address staker, uint256 amount) private {
		_realise(staker);

		unchecked {
			stakes[staker].amount += amount;
			stakes[staker].totalExcluded = uint128(getCumulativeRewards(stakes[staker].amount));
			totalStaked += uint128(amount);
		}

		emit Staked(staker, amount);
	}

	function _unstake(address staker, uint256 amount) private {
		uint256 stakedAmount = getStakedAmount(staker);
		if (stakedAmount < amount) {
			revert InsufficientStake(amount, stakedAmount);
		}

		_realise(staker);

		unchecked {
			stakes[staker].amount -= amount;
			totalStaked -= uint128(amount);
		}
		stakes[staker].totalExcluded = uint128(getCumulativeRewards(stakes[staker].amount));
		IERC20(stakingToken).transfer(staker, amount);

		emit Unstaked(staker, amount);
	}

	function updateRewards() external {
		_updateRewards();
	}

	function _updateRewards() private {
		uint256 tokenBalance = IERC20(rewardToken).balanceOf(address(this));
		uint256 lastBalance = _lastContractBalance;
		if (tokenBalance > lastBalance) {
			_nextPeriodTokens += uint128(tokenBalance - lastBalance);
		}
		_lastContractBalance = uint152(tokenBalance);

		uint128 nextPeriodTokens = _nextPeriodTokens;
		uint128 periodTotalRewards = _periodTotalRewards;
		if (periodTotalRewards == 0) {
			if (nextPeriodTokens == 0) {
				return;
			}
			_startPeriod(uint32(block.timestamp), nextPeriodTokens);
			return;
		}

		uint32 distributionPeriod = _distributionPeriod;
		uint8 updatesPerPeriod = _updatesPerPeriod;
		uint32 timeForUpdate = distributionPeriod / updatesPerPeriod;
		uint32 lastPeriodUpdate = _lastPeriodUpdate;
		uint32 timeElapsed = uint32(block.timestamp) - lastPeriodUpdate;
		if (timeElapsed < timeForUpdate) {
			return;
		}

		uint32 periodStarted = _periodStarted;
		uint256 updatesAlreadyDone = (lastPeriodUpdate - periodStarted) / timeForUpdate;
		uint32 periodEnds = periodStarted + distributionPeriod;
		uint256 tokensPerUpdate = periodTotalRewards / updatesPerPeriod;

		if (block.timestamp > periodEnds) {
			uint256 alreadyAdded = tokensPerUpdate * updatesAlreadyDone;
			uint256 remainder = periodTotalRewards - alreadyAdded;
			_rewardsPerToken += remainder * _accuracyFactor / totalStaked;
			_startPeriod(periodEnds, nextPeriodTokens);
		} else {
			uint32 newUpdates = timeElapsed / timeForUpdate;
			uint256 tokensToAdd = tokensPerUpdate * newUpdates;
			_lastPeriodUpdate = lastPeriodUpdate + (timeForUpdate * newUpdates);
			_rewardsPerToken += tokensToAdd * _accuracyFactor / totalStaked;
		}
	}

	function _calculateRewardsToAdd() private view returns (uint256) {
		uint32 distributionPeriod = _distributionPeriod;
		uint8 updatesPerPeriod = _updatesPerPeriod;
		uint32 timeForUpdate = distributionPeriod / updatesPerPeriod;
		uint32 lastPeriodUpdate = _lastPeriodUpdate;
		uint32 timeElapsed = uint32(block.timestamp) - lastPeriodUpdate;
		if (timeElapsed < timeForUpdate) {
			return 0;
		}
		uint128 periodTotalRewards = _periodTotalRewards;
		uint32 periodStarted = _periodStarted;
		uint256 updatesAlreadyDone = (lastPeriodUpdate - periodStarted) / timeForUpdate;
		uint32 periodEnds = periodStarted + distributionPeriod;
		uint256 tokensPerUpdate = periodTotalRewards / updatesPerPeriod;
		uint256 toAdd;
		if (block.timestamp > periodEnds) {
			uint256 alreadyAdded = tokensPerUpdate * updatesAlreadyDone;
			toAdd = periodTotalRewards - alreadyAdded;
		} else {
			uint32 newUpdates = timeElapsed / timeForUpdate;
			toAdd = tokensPerUpdate * newUpdates;
		}
		return toAdd * _accuracyFactor / totalStaked;
	}

	function _startPeriod(uint32 start, uint128 totalRewards) private {
		_periodStarted = start;
		_lastPeriodUpdate = start;
		_periodTotalRewards = totalRewards;
		_nextPeriodTokens = 0;
	}

	function emergencyUnstakeAll() external {
		uint256 amount = stakes[msg.sender].amount;
		if (amount == 0) {
            revert ZeroAmount();
        }
		IERC20(stakingToken).transfer(msg.sender, amount);
		unchecked {
			totalStaked -= uint128(amount);
		}
		stakes[msg.sender].amount = 0;
	}

	function setRewardToken(address reward) external authorized {
		rewardToken = reward;
	}

	function rescueToken(address token) external authorized {
		if (token == stakingToken) {
			revert StakingTokenRescue();
		}
		IERC20 t = IERC20(token);
		t.transfer(msg.sender, t.balanceOf(address(this)));
	}
}