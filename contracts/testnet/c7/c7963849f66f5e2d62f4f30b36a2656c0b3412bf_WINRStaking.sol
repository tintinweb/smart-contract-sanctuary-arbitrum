// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./WINRVesting.sol";

contract WINRStaking is WINRVesting {
	/*==================================================== State Variables ========================================================*/
	mapping(address => StakeDividend) public dividendWINRStakes;
	mapping(address => StakeDividend) public dividendVestedWINRStakes;

	/*==================================================== Constructor ===========================================================*/
	constructor(
		address _vaultRegistry,
		address _timelock
	) WINRVesting(_vaultRegistry, _timelock) {}

	/*===================================================== FUNCTIONS ============================================================*/
	/*=================================================== View Functions =========================================================*/

	/**
	 *
	 * @dev Retrieves the staked amount of dividend WINR tokens for a specified account and stake type.
	 * @param _account The address of the account to retrieve the staked amount for.
	 * @param _isVested A boolean flag indicating whether to retrieve the vested WINR or WINR dividend stake.
	 * @return _amount The staked amount of dividend WINR/vWINR tokens for the specified account and stake type.
	 * @dev The function retrieves the staked amount of dividend WINR/vWINR tokens for the specified account and stake type from the dividendWINRStakes or dividenVestedWINRdStakes mapping,
	 *      depending on the value of the isVested parameter.
	 */
	function dividendStakedAmount(
		address _account,
		bool _isVested
	) external view returns (uint256) {
		return
			_isVested
				? dividendVestedWINRStakes[_account].amount
				: dividendWINRStakes[_account].amount;
	}

	/**
	 *
	 * @dev Retrieves the dividend stake for a specified account and stake type.
	 * @param _account The address of the account to retrieve the dividend stake for.
	 * @param _isVested A boolean flag indicating whether to retrieve the vested or non-vested dividend stake.
	 * @return stake A Stake struct representing the dividend stake for the specified account and stake type.
	 * @dev The function retrieves the dividend stake for the specified account and stake type from the dividendWINRStakes or dividenVestedWINRdStakes mapping, depending on the value of the isVested parameter.
	 */
	function getDividendStake(
		address _account,
		bool _isVested
	) external view returns (StakeDividend memory) {
		return
			_isVested
				? dividendVestedWINRStakes[_account]
				: dividendWINRStakes[_account];
	}

	/**
	 *
	 * @param _account The address of the account to retrieve the pending rewards data.
	 */
	function pendingDividendRewards(address _account) external view returns (uint256 pending_) {
		// Calculate the pending reward based on the dividend vested WINR stake of the given account
		pending_ += _pendingByDividendStake(dividendVestedWINRStakes[_account]);
		// Calculate the pending reward based on the dividend WINR stake of the given account
		pending_ += _pendingByDividendStake(dividendWINRStakes[_account]);
	}

	/*================================================= External Functions =======================================================*/
	/**
	 *
	 * @dev Fallback function that handles incoming Ether transfers to the contract.
	 * @dev The function emits a Donation event with the sender's address and the amount of Ether transferred.
	 * @dev The function can receive Ether and can be called by anyone, but does not modify the state of the contract.
	 */
	fallback() external payable {
		emit Donation(_msgSender(), msg.value);
	}

	/**
	 *
	 * @dev Receive function that handles incoming Ether transfers to the contract.
	 * @dev The function emits a Donation event with the sender's address and the amount of Ether transferred.
	 * @dev The function can receive Ether and can be called by anyone, but does not modify the state of the contract.
	 */
	receive() external payable {
		emit Donation(_msgSender(), msg.value);
	}

	/**
	 *
	 * @dev Distributes a share of profits to all stakers based on their stake weight.
	 * @param _amount The amount of profits to distribute among stakers.
	 * @notice The function can only be called by an address with the PROTOCOL_ROLE.
	 * @notice The total weight of all staked tokens must be greater than zero for profits to be distributed.
	 * @dev If the total weight of all staked tokens is greater than zero,
	 *      the function adds the specified amount of profits to the total profit pool
	 *      and updates the accumulated profit per weight value accordingly.
	 * @dev The function emits a Share event to notify external systems about the distribution of profits.
	 */
	function share(uint256 _amount) external override isAmountNonZero(_amount) onlyProtocol {
		if (totalWeight > 0) {
			totalProfit += _amount;
			totalEarned += _amount;
			accumProfitPerWeight += (_amount * PRECISION) / totalWeight;

			emit Share(_amount, totalWeight);
		}
	}

	/**
	 *
	 *  @dev Function to claim dividends for the caller.
	 *  @notice The function can only be called when the contract is not paused and is non-reentrant.
	 *  @notice The function calls the internal function '_claimDividend' passing the caller's address and 'isVested' boolean as parameters.
	 */
	function claimDividend() external whenNotPaused nonReentrant {
		_claimDividendBatch(_msgSender());
	}

	/**
	 * @notice Pauses the contract. Only the governance address can call this function.
	 * @dev While the contract is paused, some functions may be disabled to prevent unexpected behavior.
	 */
	function pause() public onlyTeam {
		_pause();
	}

	/**
	 * @notice Unpauses the contract. Only the governance address can call this function.
	 * @dev Once the contract is unpaused, all functions should be enabled again.
	 */
	function unpause() public onlyTeam {
		_unpause();
	}

	/**
	 * @notice Allows the governance to withdraw a certain amount of donations and transfer them to a specified address
	 * @param to The address to transfer the donations to
	 * @param amount The amount of donations to withdraw
	 */
	function withdrawDonations(address payable to, uint256 amount) external onlyGovernance {
		require(address(this).balance >= amount, "Insufficient balance");
		(bool sent, ) = to.call{value: amount}("");
		require(sent, "Withdraw failed");
	}

	/**
	 * @dev Updates the vesting period configuration.
	 * @param duration Total vesting duration in seconds.
	 * @param minDuration Minimum vesting duration in seconds.
	 * @param claimDuration Duration in seconds during which rewards can be claimed.
	 * @param minPercent Minimum percentage of the total stake that must be vested.
	 */
	function updatePeriod(
		uint256 duration,
		uint256 minDuration,
		uint256 claimDuration,
		uint256 minPercent
	) external onlyGovernance {
		require(
			duration >= minDuration,
			"Duration must be greater than or equal to minimum duration"
		);
		require(
			claimDuration <= duration,
			"Claim duration must be less than or equal to duration"
		);

		period.duration = duration;
		period.minDuration = minDuration;
		period.claimDuration = claimDuration;
		period.minPercent = minPercent;
	}

	/**
	 *
	 * @dev Internal function to deposit WINR/vWINR as dividends.
	 * @param _amount The amount of WINR/vWINR to be deposited.
	 * @param _isVested Boolean flag indicating if tokens are vWINR.
	 * @dev This function performs the following steps:
	 *     Get the address of the stake owner.
	 *     Determine the stake details based on the boolean flag isVested.
	 *     Take the tokens from the stake owner and update the stake amount.
	 *     If the stake amount is greater than 0, claim dividends for the stake owner.
	 *     Calculate the stake weight based on the updated stake amount and isVested flag.
	 *     Update the stake with the new stake amount, start time, weight and profit debt.
	 *     Emit a Deposit event with the details of the deposited tokens.
	 */
	function depositDividend(
		uint256 _amount,
		bool _isVested
	) external isAmountNonZero(_amount) nonReentrant whenNotPaused {
		// Get the address of the stake owner.
		address sender_ = _msgSender();
		// Determine the stake details based on the boolean flag isVested.
		StakeDividend storage stake_;

		if (_isVested) {
			tokenManager.takeVestedWINR(sender_, _amount);
			stake_ = dividendVestedWINRStakes[sender_];
			totalStakedVestedWINR += _amount;
		} else {
			tokenManager.takeWINR(sender_, _amount);
			stake_ = dividendWINRStakes[sender_];
			totalStakedWINR += _amount;
		}

		// If the stake amount is greater than 0, claim dividends for the stake owner.
		if (stake_.amount > 0) {
			_claimDividend(sender_, _isVested);
		}

		// Calculate the stake weight
		uint256 weight_ = _calculateWeight(stake_.amount + _amount, _isVested, false);
		// increase the total staked weight
		totalWeight += (weight_ - stake_.weight);
		// Update the stake with the new stake amount, start time, weight and profit debt.
		stake_.amount += _amount;
		stake_.depositTime = uint128(block.timestamp);
		stake_.weight = weight_;
		stake_.profitDebt = _calcDebt(weight_);

		// Emit a DepositDividend event with the details of the deposited tokens.
		emit DepositDividend(sender_, stake_.amount, stake_.profitDebt, _isVested);
	}

	/**
	 *
	 * @dev Internal function to unstake tokens.
	 * @param _amount The amount of tokens to be unstaked.
	 * @param _isVested Boolean flag indicating if stake is Vested WINR.
	 * @notice This function also claims rewards.
	 * @dev This function performs the following steps:
	 *    Check that the staker has sufficient stake amount.
	 *    Claim dividends for the staker.
	 *    Compute the weight of the unstaked tokens and update the total staked amount and weight.
	 *    Compute the debt for the stake after unstaking tokens.
	 *    Burn the necessary amount of tokens and send the remaining unstaked tokens to the staker.
	 *    Emit an Unstake event with the details of the unstaked tokens.
	 */
	function unstake(uint256 _amount, bool _isVested) external nonReentrant whenNotPaused {
		address sender_ = _msgSender();
		StakeDividend storage stake_ = _isVested
			? dividendVestedWINRStakes[sender_]
			: dividendWINRStakes[sender_];
		require(stake_.amount >= _amount, "Insufficient stake amount");
		ITokenManager tokenManager_ = tokenManager;

		// Compute the amount of tokens to be burned and sent to the staker.
		uint256 burnAmount_ = _computeBurnAmount(_amount);
		uint256 sendAmount_ = _amount - burnAmount_;
		// Compute the weight of the unstaked tokens and update the total staked amount and weight.
		uint256 unstakedWeight_;

		// Claim dividends for the staker.
		_claimDividend(sender_, _isVested);

		// Burn the necessary amount of tokens and send the remaining unstaked tokens to the staker.
		if (_isVested) {
			tokenManager_.burnVestedWINR(burnAmount_);
			tokenManager_.sendVestedWINR(sender_, sendAmount_);
			unstakedWeight_ = _amount * weightMultipliers.vWinr;
			totalStakedVestedWINR -= _amount;
		} else {
			tokenManager_.burnWINR(burnAmount_);
			tokenManager_.sendWINR(sender_, sendAmount_);
			unstakedWeight_ = _amount * weightMultipliers.winr;
			totalStakedWINR -= _amount;
		}

		totalWeight -= unstakedWeight_;

		// Update the stake details after unstaking tokens.
		stake_.amount -= _amount;
		stake_.weight -= unstakedWeight_;
		stake_.profitDebt = _calcDebt(stake_.weight);

		// Emit an Unstake event with the details of the unstaked tokens.
		emit Unstake(sender_, block.timestamp, sendAmount_, burnAmount_, _isVested);
	}

	/*================================================= Internal Functions =======================================================*/
	/**
	 *
	 * @dev Internal function to claim dividends for a stake.
	 * @param _account The address of the stake owner.
	 * @param _isVested Boolean flag indicating if stake is Vested WINR.
	 * @return reward_ The amount of dividends claimed.
	 * @dev This function performs the following steps:
	 *     Determine the stake details based on the boolean flag isVested.
	 *     Calculate the pending rewards for the stake.
	 *     Send the rewards to the stake owner.
	 *     Update the profit debt for the stake.
	 *     Update the total profit and total claimed for the stake owner.
	 *     Emit a Claim event with the details of the claimed rewards.
	 */
	function _claimDividend(
		address _account,
		bool _isVested
	) internal returns (uint256 reward_) {
		// Determine the stake details based on the boolean flag isVested.
		StakeDividend storage stake_ = _isVested
			? dividendVestedWINRStakes[_account]
			: dividendWINRStakes[_account];

		// Calculate the pending rewards for the stake.
		reward_ = _pendingByDividendStake(stake_);

		if (reward_ == 0) {
			return 0;
		}

		// Send the rewards to the stake owner.
		tokenManager.sendWLP(_account, reward_);

		// Update the profit debt for the stake.
		stake_.profitDebt = _calcDebt(stake_.weight);

		// Update the total profit and total claimed for the stake owner.
		// totalProfit -= _reward;
		totalClaimed[_account] += reward_;

		// Emit a Claim event with the details of the claimed rewards.
		emit ClaimDividend(_account, reward_, _isVested);
	}

	/**
	 *
	 * @dev Internal function to claim dividends for all stake.
	 * @param _account The address of the stake owner.
	 * @return reward_ The amount of dividends claimed.
	 */
	function _claimDividendBatch(address _account) internal returns (uint256 reward_) {
		// Determine the stake details based on the boolean flag isVested.
		StakeDividend storage stakeVWINR_ = dividendVestedWINRStakes[_account];
		StakeDividend storage stakeWINR_ = dividendWINRStakes[_account];

		// Calculate the pending rewards for the stake.
		reward_ = _pendingByDividendStake(stakeVWINR_);
		reward_ += _pendingByDividendStake(stakeWINR_);

		if (reward_ == 0) {
			return 0;
		}

		// Send the rewards to the stake owner.
		tokenManager.sendWLP(_account, reward_);

		// Update the profit debt for the stake.
		stakeVWINR_.profitDebt = _calcDebt(stakeVWINR_.weight);
		stakeWINR_.profitDebt = _calcDebt(stakeWINR_.weight);

		// Update the total profit and total claimed for the stake owner.
		totalClaimed[_account] += reward_;

		// Emit a Claim event with the details of the claimed rewards.
		emit ClaimDividendBatch(_account, reward_);
	}

	/**
	 * @notice Computes the pending WLP amount of the stake.
	 * @param _stake The stake for which to compute the pending amount.
	 * @return holderProfit_ The pending WLP amount.
	 */
	function _pendingByDividendStake(
		StakeDividend memory _stake
	) internal view returns (uint256 holderProfit_) {
		// Compute the holder's profit as the product of their stake's weight and the accumulated profit per weight.
		holderProfit_ = ((_stake.weight * accumProfitPerWeight) / PRECISION);
		// If the holder's profit is less than their profit debt, return zero.
		if (holderProfit_ < _stake.profitDebt) {
			return 0;
		} else {
			// Otherwise, subtract their profit debt from their total profit and return the result.
			holderProfit_ -= _stake.profitDebt;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../core/AccessControlBase.sol";
import "../../interfaces/core/ITokenManager.sol";
import "../../interfaces/tokens/IWINR.sol";
import "../../interfaces/stakings/IWINRStaking.sol";

contract WINRVesting is IWINRStaking, Pausable, ReentrancyGuard, AccessControlBase {
	/*====================================================== Modifiers ===========================================================*/
	/**
	 * @notice Throws if the amount is not greater than zero
	 */
	modifier isAmountNonZero(uint256 amount) {
		require(amount > 0, "amount must be greater than zero");
		_;
	}

	/*====================================================== State Variables =====================================================*/

	// 18 decimal precision
	uint256 internal constant PRECISION = 1e18;
	//The total profit earned by all staked tokens in the contract
	uint256 public totalProfit;
	//The total weight of all stakes in the contract
	uint256 public totalWeight;
	//The total amount of WINR tokens staked in the contract
	uint256 public totalStakedWINR;
	//The total amount of vWINR tokens staked in the contract
	uint256 public totalStakedVestedWINR;
	//The accumulated profit per weight of all stakes in the contract. It is used in the calculation of rewards earned by each stakeholder
	uint256 public accumProfitPerWeight;
	//The percentage of staked tokens that will be burned when a stake is withdrawn
	uint256 public unstakeBurnPercentage;
	//The total profit history earned by all staked tokens in the contract
	uint256 public totalEarned;
	//Interface of Token Manager contract
	ITokenManager public tokenManager;
	//This mapping stores an array of StakeVesting structures for each address that has staked tokens in the contract
	mapping(address => StakeVesting[]) public stakes;
	//This mapping stores an array of indexes into the stakes array for each address that has active vesting stakes in the contract
	mapping(address => uint256[]) public activeVestingIndexes;
	//This mapping stores the total amount of tokens claimed by each address that has staked tokens in the contract
	mapping(address => uint256) public totalClaimed;
	//Initializes default vesting period
	Period public period = Period(180 minutes, 15 minutes, 165, 5e17);
	//IInitializes default reward multipliers
	WeightMultipliers public weightMultipliers = WeightMultipliers(1, 2, 1);

	/*==================================================== Constructor ===========================================================*/
	constructor(
		address _vaultRegistry,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) {
		unstakeBurnPercentage = 5e15; // 0.5% default
	}

	/*===================================================== FUNCTIONS ============================================================*/
	/*=================================================== View Functions =========================================================*/
	/**
	 *
	 * @dev Calculates the pending reward for a given staker.
	 * @param account The address of the staker for whom to calculate the pending reward.
	 * @return pending The amount of pending WLP tokens that the staker is eligible to receive.
	 * @dev The function iterates over all active stakes for the given staker and calculates the pending rewards for each stake using the _pendingWLPOfStake() internal function.
	 * @dev The function is view-only and does not modify the state of the contract.
	 */
	function pendingVestingRewards(address account) external view returns (uint256 pending) {
		uint256[] memory activeIndexes = getActiveIndexes(account);

		for (uint256 i = 0; i < activeIndexes.length; i++) {
			StakeVesting memory stake = stakes[account][activeIndexes[i]];
			pending += _pendingWLPOfStake(stake);
		}
	}

	/**
	 *
	 * @dev Calculates the pending reward for a given staker with given index.
	 * @param account The address of the staker for whom to calculate the pending reward.
	 * @return pending The amount of pending WLP tokens that the staker is eligible to receive.
	 * @dev The function calculates the pending rewards for the stake using the _pendingWLPOfStake() internal function.
	 * @dev The function is view-only and does not modify the state of the contract.
	 */
	function pendingVestingByIndex(
		address account,
		uint256 index
	) external view returns (uint256 pending) {
		// Get the stake from the stakes mapping
		StakeVesting memory stake = stakes[account][index];
		if(stake.withdrawn || stake.cancelled) return 0;
		// Calculate the pending reward for the stake
		pending = _pendingWLPOfStake(stake);
	}

	/**
	 *
	 * @param _account Address of staker
	 * @param _index index to calculate the withdrawable amount
	 * @return _withdrawable  withdrawable amount of WINR/vWINR
	 */
	function withdrawableTokens(
		address _account,
		uint256 _index
	) external view returns (uint256 _withdrawable) {
		// Get the stake from the stakes mapping
		StakeVesting memory _stake = stakes[_account][_index];
		// Calculate the withdrawable amount for the stake
		_withdrawable = _withdrawableByVesting(_stake);

		// Check if the vesting period has passed
		if (_stake.startTime + _stake.vestingDuration > block.timestamp) {
			_withdrawable = 0;
		}
	}

	/**
	 * @notice This function returns an array of indexes representing the active vesting stakes indexes for a given staker.
	 * @param staker The address of the staker
	 */
	function getActiveIndexes(address staker) public view returns (uint[] memory indexes) {
		indexes = activeVestingIndexes[staker];
	}

	/**
	 *
	 * @param _account Address of the staker
	 * @param _indexes Indexes of the vesting stakes to calculate the total staked amount
	 * @return _totalStaked The total amount of staked tokens across the specified vesting stakes
	 */
	function vestingStakedAmount(
		address _account,
		uint256[] calldata _indexes
	) external view returns (uint256 _totalStaked) {
		for (uint256 i = 0; i < _indexes.length; i++) {
			StakeVesting memory _stake = stakes[_account][_indexes[i]];
			_totalStaked += _stake.amount;
		}
	}

	/**
	 * @return _totalStakedVWINR The total amount of vWINR tokens staked in the contract
	 * @return _totalStakedWINR The total amount of WINR tokens staked in the contract
	 * @return _totalEarned The total profit earned
	 */
	function globalData()
		external
		view
		returns (uint256 _totalStakedVWINR, uint256 _totalStakedWINR, uint256 _totalEarned)
	{
		_totalStakedVWINR = totalStakedVestedWINR;
		_totalStakedWINR = totalStakedWINR;
		_totalEarned = totalEarned;
	}

	/**
	 *
	 * @param _account Address of staker
	 * @param _index Index of stake
	 * @return _stake Data of the stake
	 */
	function getVestingStake(
		address _account,
		uint256 _index
	) public view returns (StakeVesting memory _stake) {
		_stake = stakes[_account][_index];
	}

	/**
	 *
	 * @param _account Address of staker
	 * @return _length total stake count of the _account
	 */
	function getVestingStakeLength(address _account) external view returns (uint256 _length) {
		_length = stakes[_account].length;
	}

	function _calcDebt(uint256 _weight) internal view returns (uint256 debt) {
		debt = (_weight * accumProfitPerWeight) / PRECISION;
	}

	/**
	 *
	 * @dev Computes the weight of a specified amount of tokens based on its type and vesting status.
	 * @param amount The amount of tokens to compute the weight for.
	 * @param vested A boolean flag indicating whether the tokens are vested or not.
	 * @param vesting A boolean flag indicating whether the tokens are vesting or not, applicable only if the tokens are vested.
	 * @return The weight of the specified amount of tokens.
	 * @dev The function computes the weight of the specified amount of tokens based on its type and vesting status, using the weightMultipliers mapping.
	 * @dev The function does not modify the state of the contract and can only be called internally.
	 */
	function _calculateWeight(
		uint256 amount,
		bool vested,
		bool vesting
	) internal view returns (uint256) {
		return
			!vested ? amount * weightMultipliers.winr : vesting
				? amount * weightMultipliers.vWinrVesting
				: amount * weightMultipliers.vWinr;
	}

	/**
	 * @notice Computes the pending WLP amount of the stake.
	 * @param stake The stake for which to compute the pending amount.
	 * @return holderProfit The pending WLP amount.
	 */
	function _pendingWLPOfStake(StakeVesting memory stake) internal view returns (uint256) {
	// Compute the holder's profit as the product of their stake's weight and the accumulated profit per weight.
		uint256 holderProfit = ((stake.weight * accumProfitPerWeight) / PRECISION);
		// If the holder's profit is less than their profit debt, return zero.
		return holderProfit < stake.profitDebt ? 0 : holderProfit - stake.profitDebt;
	}

	/**
	 * @notice Calculates the amount of WINR/vWINR that should be burned upon unstaking.
	 * @param amount The amount of WINR/vWINR being unstaked.
	 * @return _burnAmount The amount of WINR/vWINR to be burned.
	 */
	function _computeBurnAmount(uint256 amount) internal view returns (uint256 _burnAmount) {
		// Calculate the burn amount as the product of the unstake burn percentage and the amount being unstaked.
		_burnAmount = (amount * unstakeBurnPercentage) / PRECISION;
	}

	/**
	 * @notice Computes the withdrawable amount of WINR for the stake.
	 * @param stake The stake for which to compute the withdrawable amount.
	 * @return withdrawable_ The withdrawable amount of WINR.
	 */
	function _withdrawableByVesting(
		StakeVesting memory stake
	) internal view returns (uint256 withdrawable_) {
		// Compute the total amount of time that the stake has been staked, in days.
		uint256 totalStakedDuration_ = (block.timestamp - stake.startTime) / 1 minutes;
		// Compute the minimum number of days required for staking in order to be eligible for a reward.
		uint256 _minDays = period.minDuration / 1 minutes;

		// If the stake duration is less than the minimum number of days, the holder cannot withdraw any tokens.
		if (totalStakedDuration_ < _minDays) {
			return 0;
		}

		// Otherwise, calculate the holder's profit as follows:
		if (block.timestamp > stake.startTime + stake.vestingDuration) {
			// If the vesting period has expired, then the holder can withdraw their full stake amount.
			totalStakedDuration_ = stake.vestingDuration / 1 minutes;
		}

		// Calculate the profit for the holder as the sum of the tokens earned on the first day and the additional tokens earned over time.
		withdrawable_ =
			stake.accTokenFirstDay +
			((stake.amount - stake.accTokenFirstDay) *
				(totalStakedDuration_ - _minDays)) /
			period.claimDuration;
	}

	/*================================================= External Functions =======================================================*/

	/**
	 * @dev This function cancels vesting stakes without penalty and reward.
	 * It sends the staked amount to the staker.
	 * @param _index index to cancel vesting for
	 * @notice Throws an error if the stake has already been withdrawn
	 * @notice Emits a Cancel event upon successful execution
	 */
	function cancel(uint256 _index) external {
		// Get the address of the caller
		address sender_ = msg.sender;
		// Declare local variables for stake and bool values
		StakeVesting memory stake;
		

		// Retrieve the stake and bool values for the given index and staker
		(stake) = getVestingStake(sender_, _index);

		// Check if the stake has already been withdrawn
		require(!stake.withdrawn, "stake has withdrawn");

		// Remove the index from the staker's active stakes list
		_removeActiveIndex(sender_, _index);

		uint256 amount_ = stake.amount;

		// Mark the stake as cancelled in the mapping
		stakes[sender_][_index].cancelled = true;

		// Calculate the amount of tokens to burn and the amount of tokens to send to the staker
		uint256 burnAmount_ = _computeBurnAmount(amount_);
		uint256 sendAmount_ = amount_ - burnAmount_;
		totalStakedVestedWINR -= amount_;
		totalWeight -= stake.weight;
		// claim rewards
		uint256 reward_ = _pendingWLPOfStake(stake);

		if(reward_ > 0) {
			tokenManager.sendWLP(sender_, reward_);

			stakes[sender_][_index].profitDebt += reward_;
			totalProfit -= reward_;
			totalClaimed[sender_] += reward_;

			emit ClaimVesting(sender_, reward_, _index);
		}
		// Send the staked tokens to the staker
		tokenManager.sendVestedWINR(sender_, sendAmount_);

		// Burn the remaining vesting tokens
		tokenManager.burnVestedWINR(burnAmount_);

		// Emit a Cancel event to notify listeners of the cancellation
		emit Cancel(sender_, block.timestamp, _index, burnAmount_, sendAmount_);
	}

	/**
	 * @dev Set the weight multipliers for each type of stake. Only callable by the governance address.
	 * @param _weightMultipliers Multiplier per weight for each type of stake
	 * @notice Emits a WeightMultipliersUpdate event upon successful execution
	 */
	function setWeightMultipliers(
		WeightMultipliers memory _weightMultipliers
	) external onlyGovernance {
		require(_weightMultipliers.vWinr != 0, "vWINR dividend multiplier can not be zero");
		require(
			_weightMultipliers.vWinrVesting != 0,
			"vWINR vesting multiplier can not be zero"
		);
		require(_weightMultipliers.winr != 0, "WINR multiplier can not be zero");
		// Set the weight multipliers to the provided values
		weightMultipliers = _weightMultipliers;

		// Emit an event to notify listeners of the update
		emit WeightMultipliersUpdate(_weightMultipliers);
	}

	/**
	 * @dev Set the percentage of tokens to burn upon unstaking. Only callable by the governance address.
	 * @param _unstakeBurnPercentage The percentage of tokens to burn upon unstaking
	 * @notice Emits an UnstakeBurnPercentageUpdate event upon successful execution
	 */
	function setUnstakeBurnPercentage(uint256 _unstakeBurnPercentage) external onlyGovernance {
		// Set the unstake burn percentage to the provided value
		unstakeBurnPercentage = _unstakeBurnPercentage;

		// Emit an event to notify listeners of the update
		emit UnstakeBurnPercentageUpdate(_unstakeBurnPercentage);
	}

	/**
	 * @dev Set the address of the token manager contract. Only callable by the governance address.
	 * @param _tokenManager The address of the token manager contract
	 */
	function setTokenManager(ITokenManager _tokenManager) external onlyGovernance {
		require(
			address(_tokenManager) != address(0),
			"token manager address can not be zero"
		);
		// Set the token manager to the provided address
		tokenManager = _tokenManager;
	}

	/**
	 * @dev Deposit vWINR tokens into the contract and create a vesting stake with the specified parameters
	 * @param amount The amount of vWINR tokens to deposit
	 * @param vestingDuration The duration of the vesting period in seconds
	 */
	function depositVesting(
		uint256 amount,
		uint256 vestingDuration
	) external isAmountNonZero(amount) nonReentrant whenNotPaused {
		uint256 vestingDurationInSeconds = vestingDuration * 1 minutes;
		require(
			vestingDurationInSeconds >= period.minDuration &&
				vestingDuration <= period.duration,
			"duration must be in period"
		);
		// Get the address of the caller
		address sender = msg.sender;
		uint256 weight = _calculateWeight(amount, true, true);
		// Calculate the profit debt for the stake based on its weight
		uint256 profitDebt = _calcDebt(weight);
		// Get the current timestamp as the start time for the stake
		uint256 startTime = block.timestamp;
		// Calculate the accumulated token value for the first day of the claim period
		uint256 accTokenFirstDay = (amount * period.minPercent) / PRECISION;
		// Calculate the daily accumulation rate for the claim period
		uint256 accTokenPerDay = (amount - accTokenFirstDay) / period.claimDuration;

		// Transfer the vWINR tokens from the sender to the token manager contract
		tokenManager.takeVestedWINR(sender, amount);

		totalWeight += weight;
		totalStakedVestedWINR += amount;

		// Create a new stake with the specified parameters and add it to the list of stakes for the sender
		stakes[sender].push(
			StakeVesting(
				amount,
				weight,
				vestingDurationInSeconds,
				profitDebt,
				startTime,
				accTokenFirstDay,
				accTokenPerDay,
				false,
				false
			)
		);

		// Get the index of the newly added stake and add it to the list of active stakes for the sender
		uint256 _index = stakes[msg.sender].length - 1;
		_addActiveIndex(msg.sender, _index);

		// Emit a Deposit event to notify listeners of the new stake
		emit DepositVesting(
			sender,
			_index,
			startTime,
			vestingDurationInSeconds,
			amount,
			profitDebt,
			true,
			true
		);
	}

	/**
	 *
	 *  @dev Function to claim rewards for a specified array of indexes.
	 *  @param indexes The array of indexes to claim rewards for.
	 *  @notice The function can only be called when the contract is not paused and is non-reentrant.
	 *  @notice The function throws an error if the array of indexes is empty.
	 */
	function claimVesting(uint256[] calldata indexes) external whenNotPaused nonReentrant {
		require(indexes.length > 0, "empty indexes");
		_claim(indexes, true);
	}

	/**
	 * @dev Withdraws staked tokens and claims rewards
	 * @param _index Index to withdraw
	 */
	function withdrawVesting(uint256 _index) external whenNotPaused nonReentrant {
		address sender_ = _msgSender();
		// Initialize an array of size 4 to store the amounts
		StakeVesting storage stake_ = stakes[sender_][_index];

		// Check that the withdrawal period for this stake has passed
		require(
			block.timestamp >= stake_.startTime + stake_.vestingDuration,
			"You can't withdraw the stake yet"
		);
		// Check that this stake has not already been withdrawn
		require(!stake_.withdrawn, "already withdrawn");
		// Check that this stake has not been cancelled
		require(!stake_.cancelled, "stake cancelled");

		// Redeemable WINR amount by stake
		uint256 redeemable_ = _withdrawableByVesting(stake_);
		// Redeemable WLP amount by stake
		uint256 reward_ = _pendingWLPOfStake(stake_);
		
		// Interact with external contracts to complete the withdrawal process
		if (redeemable_ > 0) {
			// Mint reward tokens if necessary
			tokenManager.mintOrTransferByPool(sender_, redeemable_);
		}

		uint256 amountToBurn = stake_.amount - redeemable_;

		// Mint WINR tokens to decrease total supply
		if (amountToBurn > 0) {
			// this code piece is used to decrease burn amount from WINR total supply
			tokenManager.mintWINR(address(tokenManager), amountToBurn);
			tokenManager.burnWINR(amountToBurn);
		}

		// Burn vested WINR tokens
		tokenManager.burnVestedWINR(stake_.amount);

		// Interactions
		if (reward_ > 0) {
			tokenManager.sendWLP(sender_, reward_);

			stakes[sender_][_index].profitDebt += reward_;
			totalProfit -= reward_;
			totalClaimed[sender_] += reward_;

			emit ClaimVesting(sender_, reward_, _index);
		}

		// Calculate the total amounts to be withdrawn
		// Mark this stake as withdrawn and remove its index from the active list
		stake_.withdrawn = true;
		_removeActiveIndex(sender_, _index);

		// Update the total weight and total staked amount
		totalWeight -= stake_.weight;
		totalStakedVestedWINR -= stake_.amount;

		// Emit an event to log the withdrawal
		emit Withdraw(
			sender_,
			block.timestamp,
			_index,
			stake_.weight,
			stake_.weight,
			stake_.amount
		);
	}

	/**
	 * @dev Withdraws staked tokens and claims rewards
	 * @param indexes Indexes to withdraw
	 */
	function withdrawVestingBatch(
		uint256[] calldata indexes
	) external whenNotPaused nonReentrant {
		address sender = msg.sender;
		// Initialize an array of size 4 to store the amounts
		uint256[4] memory _amounts;

		// Check effects for each stake to be withdrawn
		for (uint256 i = 0; i < indexes.length; i++) {
			// Get the stake and boolean values for this index
			uint256 index = indexes[i];
			StakeVesting storage stake = stakes[sender][index];

			// Check that the withdrawal period for this stake has passed
			require(
				block.timestamp >= stake.startTime + stake.vestingDuration,
				"You can't withdraw the stake yet"
			);

			// Check that this stake has not already been withdrawn
			require(!stake.withdrawn, "already withdrawn");

			// Check that this stake has not been cancelled
			require(!stake.cancelled, "stake cancelled");

			// Calculate the total amounts to be withdrawn
			_amounts[0] += stake.weight;
			_amounts[1] += _withdrawableByVesting(stake);
			_amounts[2] += _pendingWLPOfStake(stake);
			_amounts[3] += stake.amount;

			// Mark this stake as withdrawn and remove its index from the active list
			stake.withdrawn = true;
			_removeActiveIndex(sender, index);
		}

		// Interact with external contracts to complete the withdrawal process
		if (_amounts[1] > 0) {
			// Mint rewards tokens if necessary
			tokenManager.mintOrTransferByPool(sender, _amounts[1]);
		}

		// the calculation is amountToBurn = total withdraw weight - total withdraw amount;
		uint256 amountToBurn = _amounts[3] - _amounts[1];

		// Mint WINR tokens to decrease total supply
		if (amountToBurn > 0) {
			// this code piece is used to decrease burn amount from WINR total supply
			// Mint WINR tokens to the tokenManager contract
			tokenManager.mintWINR(address(tokenManager), amountToBurn);
			tokenManager.burnWINR(amountToBurn);
		}

		// Burn total vested WINR tokens
		tokenManager.burnVestedWINR(_amounts[3]);

		// Update the total weight and total staked amount
		totalWeight -= _amounts[0];
		totalStakedVestedWINR -= _amounts[3];

		// Claim rewards for remaining stakes
		_claim(indexes, false);

		// Emit an event to log the withdrawal
		emit WithdrawBatch(
			sender,
			block.timestamp,
			indexes,
			_amounts[1],
			_amounts[1],
			_amounts[3]
		);
	}

	/*================================================= Internal Functions =======================================================*/
	/**
	 * @dev Claims the reward for the specified stakes
	 * @param indexes Array of the indexes to claim
	 * @param isClaim Checks if the caller is the claim function
	 */
	function _claim(uint256[] memory indexes, bool isClaim) internal {
		address sender_ = msg.sender;
		uint256 totalFee_;

		// Check
		for (uint256 i = 0; i < indexes.length; i++) {
			uint256 index_ = indexes[i];

			StakeVesting storage stake_ = stakes[sender_][index_];

			// Check that the stake has not been withdrawn
			if (isClaim) {
				require(!stake_.withdrawn, "Stake has already been withdrawn");
			}

			// Check that the stake has not been cancelled
			require(!stake_.cancelled, "Stake has been cancelled");

			 uint256 fee_ = _pendingWLPOfStake(stake_);
			 stake_.profitDebt += fee_;
			totalFee_ += fee_;
			 
		}
		// Effects


		totalProfit -= totalFee_;
		totalClaimed[sender_] += totalFee_;
		// Interactions
		if (totalFee_ > 0) {
			
			tokenManager.sendWLP(sender_, totalFee_);
		}

		// Emit event
		emit ClaimVestingBatch(sender_, totalFee_, indexes);
	}

	/**
	 *
	 *  @dev Internal function to remove an active vesting index for a staker.
	 *  @param staker The address of the staker.
	 *  @param index The index of the vesting schedule to remove.
	 */
	function _removeActiveIndex(address staker, uint index) internal {
		uint[] storage indexes;

		indexes = activeVestingIndexes[staker];

		uint length = indexes.length;

		// Find the index to remove
		for (uint i = 0; i < length; i++) {
			if (indexes[i] == index) {
				// Shift all subsequent elements left by one position
				for (uint j = i; j < length - 1; j++) {
					indexes[j] = indexes[j + 1];
				}
				// Remove the last element
				indexes.pop();
				return;
			}
		}
	}

	function _addActiveIndex(address staker, uint256 index) internal {
		uint[] storage indexes;

		indexes = activeVestingIndexes[staker];
		indexes.push(index);
	}

	function share(uint256 amount) external virtual override {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

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

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.19;

contract AccessControlBase is Context {
	IVaultAccessControlRegistry public immutable registry;
	address public immutable timelockAddressImmutable;

	constructor(address _vaultRegistry, address _timelock) {
		registry = IVaultAccessControlRegistry(_vaultRegistry);
		timelockAddressImmutable = _timelock;
	}

	/*==================== Managed in VaultAccessControlRegistry *====================*/

	modifier onlyGovernance() {
		require(registry.isCallerGovernance(_msgSender()), "Forbidden: Only Governance");
		_;
	}

	modifier onlyEmergency() {
		require(registry.isCallerEmergency(_msgSender()), "Forbidden: Only Emergency");
		_;
	}

	modifier onlySupport() {
		require(registry.isCallerEmergency(_msgSender()), "Forbidden: Only Support");
		_;
	}

	modifier onlyTeam() {
		require(registry.isCallerTeam(_msgSender()), "Forbidden: Only Team");
		_;
	}

	modifier onlyProtocol() {
		require(registry.isCallerProtocol(_msgSender()), "Forbidden: Only Protocol");
		_;
	}

	modifier protocolNotPaused() {
		require(!registry.isProtocolPaused(), "Forbidden: Protocol Paused");
		_;
	}

	/*==================== Managed in WINRTimelock *====================*/

	modifier onlyTimelockGovernance() {
		address timelockActive_;
		if (!registry.timelockActivated()) {
			// the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
			timelockActive_ = registry.governanceAddress();
		} else {
			// the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
			timelockActive_ = timelockAddressImmutable;
		}
		require(_msgSender() == timelockActive_, "Forbidden: Only TimelockGovernance");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenManager {
	function takeVestedWINR(address _from, uint256 _amount) external;

	function takeWINR(address _from, uint256 _amount) external;

	function sendVestedWINR(address _to, uint256 _amount) external;

	function sendWINR(address _to, uint256 _amount) external;

	function burnVestedWINR(uint256 _amount) external;

	function burnWINR(uint256 _amount) external;

	function mintWINR(address _to, uint256 _amount) external;

	function sendWLP(address _to, uint256 _amount) external;

	function mintOrTransferByPool(address _to, uint256 _amount) external;

	function mintVestedWINR(address _input, uint256 _amount, address _recipient) external returns(uint256 _mintAmount);

	function mintedByGames() external returns (uint256);

	function MAX_MINT() external returns (uint256);

	function share(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWINR is IERC20 {
	function mint(address account, uint256 amount) external returns (uint256, uint256);

	function burn(uint256 amount) external;

	function MAX_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWINRStaking {
	function share(uint256 amount) external;

	function totalWeight() external view returns (uint256);

	struct StakeDividend {
		uint256 amount;
		uint256 profitDebt;
		uint256 weight;
		uint128 depositTime;
	}

	struct StakeVesting {
		uint256 amount; // The amount of tokens being staked
		uint256 weight; // The weight of the stake, used for calculating rewards
		uint256 vestingDuration; // The duration of the vesting period in seconds
		uint256 profitDebt; // The amount of profit earned by the stake, used for calculating rewards
		uint256 startTime; // The timestamp at which the stake was created
		uint256 accTokenFirstDay; // The accumulated  WINR tokens earned on the first day of the stake
		uint256 accTokenPerDay; // The rate at which WINR tokens are accumulated per day
		bool withdrawn; // Indicates whether the stake has been withdrawn or not
		bool cancelled; // Indicates whether the stake has been cancelled or not
	}

	struct Period {
		uint256 duration;
		uint256 minDuration;
		uint256 claimDuration;
		uint256 minPercent;
	}

	struct WeightMultipliers {
		uint256 winr;
		uint256 vWinr;
		uint256 vWinrVesting;
	}

	/*==================================================== Events =============================================================*/

	event Donation(address indexed player, uint amount);
	event Share(uint256 amount, uint256 totalDeposit);
	event DepositVesting(
		address indexed user,
		uint256 index,
		uint256 startTime,
		uint256 endTime,
		uint256 amount,
		uint256 profitDebt,
		bool isVested,
		bool isVesting
	);

	event DepositDividend(
		address indexed user,
		uint256 amount,
		uint256 profitDebt,
		bool isVested
	);
	event Withdraw(
		address indexed user,
		uint256 withdrawTime,
		uint256 index,
		uint256 amount,
		uint256 redeem,
		uint256 vestedBurn
	);
	event WithdrawBatch(
		address indexed user,
		uint256 withdrawTime,
		uint256[] indexes,
		uint256 amount,
		uint256 redeem,
		uint256 vestedBurn
	);

	event Unstake(
		address indexed user,
		uint256 unstakeTime,
		uint256 amount,
		uint256 burnedAmount,
		bool isVested
	);
	event Cancel(
		address indexed user,
		uint256 cancelTime,
		uint256 index,
		uint256 burnedAmount,
		uint256 sentAmount
	);
	event ClaimVesting(address indexed user, uint256 reward, uint256 index);
	event ClaimVestingBatch(address indexed user, uint256 reward, uint256[] indexes);
	event ClaimDividend(address indexed user, uint256 reward, bool isVested);
	event ClaimDividendBatch(address indexed user, uint256 reward);
	event WeightMultipliersUpdate(WeightMultipliers _weightMultipliers);
	event UnstakeBurnPercentageUpdate(uint256 _unstakeBurnPercentage);
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

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
	function timelockActivated() external view returns (bool);

	function governanceAddress() external view returns (address);

	function pauseProtocol() external;

	function unpauseProtocol() external;

	function isCallerGovernance(address _account) external view returns (bool);

	function isCallerEmergency(address _account) external view returns (bool);

	function isCallerProtocol(address _account) external view returns (bool);

	function isCallerTeam(address _account) external view returns (bool);

	function isCallerSupport(address _account) external view returns (bool);

	function isProtocolPaused() external view returns (bool);

	function changeGovernanceAddress(address _governanceAddress) external;

	/*==================== Events *====================*/

	event DeadmanSwitchFlipped();
	event GovernanceChange(address newGovernanceAddress);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}