// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./WINRVesting.sol";

contract WINRStaking is WINRVesting {
  /*==================================================== State Variables ========================================================*/

  struct StakeDividend {
    uint256 amount;
    uint256 weight;
    uint256 profitDebt;
    uint256 depositTime;
    bool isVedted;
  }

  mapping(address => StakeDividend) public dividendWINRStakes;
  mapping(address => StakeDividend) public dividendVestedWINRStakes;

  /*==================================================== Constructor ===========================================================*/
  constructor(
    ITokenManager _tokenManager,
    address _governance
  ) WINRVesting(_tokenManager, _governance) {}

  /*===================================================== FUNCTIONS ============================================================*/
  /*=================================================== View Functions =========================================================*/

  /**
   *
   * @dev Retrieves the staked amount of dividend WINR tokens for a specified account and stake type.
   * @param account The address of the account to retrieve the staked amount for.
   * @param isVested A boolean flag indicating whether to retrieve the vested WINR or WINR dividend stake.
   * @return _amount The staked amount of dividend WINR/vWINR tokens for the specified account and stake type.
   * @dev The function retrieves the staked amount of dividend WINR/vWINR tokens for the specified account and stake type from the dividendWINRStakes or dividenVestedWINRdStakes mapping,
   *      depending on the value of the isVested parameter.
   */
  function dividendStakedAmount(
    address account,
    bool isVested
  ) external view returns (uint256 _amount) {
    if (isVested) {
      return dividendVestedWINRStakes[account].amount;
    } else {
      return dividendWINRStakes[account].amount;
    }
  }

  /**
   *
   * @dev Retrieves the dividend stake for a specified account and stake type.
   * @param account The address of the account to retrieve the dividend stake for.
   * @param isVested A boolean flag indicating whether to retrieve the vested or non-vested dividend stake.
   * @return stake A Stake struct representing the dividend stake for the specified account and stake type.
   * @dev The function retrieves the dividend stake for the specified account and stake type from the dividendWINRStakes or dividenVestedWINRdStakes mapping, depending on the value of the isVested parameter.
   */
  function getDividendStake(
    address account,
    bool isVested
  ) external view returns (StakeDividend memory stake) {
    if (isVested) {
      return dividendVestedWINRStakes[account];
    } else {
      return dividendWINRStakes[account];
    }
  }

  /**
   *
   * @param account The address of the account to retrieve the pending rewards data.
   */
  function pendingDividendRewards(address account) external view returns (uint256 pending) {
    // Calculate the pending reward based on the dividend vested WINR stake of the given account
    pending += _pendingByDividendStake(dividendVestedWINRStakes[account]);
    // Calculate the pending reward based on the dividend WINR stake of the given account
    pending += _pendingByDividendStake(dividendWINRStakes[account]);
  }

  /*================================================= External Functions =======================================================*/
  /**
   *
   * @dev Fallback function that handles incoming Ether transfers to the contract.
   * @dev The function emits a Donation event with the sender's address and the amount of Ether transferred.
   * @dev The function can receive Ether and can be called by anyone, but does not modify the state of the contract.
   */
  fallback() external payable {
    emit Donation(msg.sender, msg.value);
  }

  /**
   *
   * @dev Receive function that handles incoming Ether transfers to the contract.
   * @dev The function emits a Donation event with the sender's address and the amount of Ether transferred.
   * @dev The function can receive Ether and can be called by anyone, but does not modify the state of the contract.
   */
  receive() external payable {
    emit Donation(msg.sender, msg.value);
  }

  /**
   *
   * @dev Distributes a share of profits to all stakers based on their stake weight.
   * @param amount The amount of profits to distribute among stakers.
   * @notice The function can only be called by an address with the TOKEN_MANAGER_ROLE.
   * @notice The total weight of all staked tokens must be greater than zero for profits to be distributed.
   * @dev If the total weight of all staked tokens is greater than zero,
   *      the function adds the specified amount of profits to the total profit pool
   *      and updates the accumulated profit per weight value accordingly.
   * @dev The function emits a Share event to notify external systems about the distribution of profits.
   */
  function share(uint256 amount) external isAmountNonZero(amount) onlyRole(TOKEN_MANAGER_ROLE) {
    if (totalWeight > 0) {
      totalProfit += amount;
      accumProfitPerWeight += (amount * PRECISION) / totalWeight;

      emit Share(amount, totalWeight);
    }
  }

  /**
   *
   *  @dev Function to claim dividends for the caller.
   *  @notice The function can only be called when the contract is not paused and is non-reentrant.
   *  @notice The function calls the internal function '_claimDividend' passing the caller's address and 'isVested' boolean as parameters.
   */
  function claimDividend() external whenNotPaused nonReentrant {
    _claimDividend(msg.sender, true);
    _claimDividend(msg.sender, false);
  }

  /**
   * @notice Pauses the contract. Only the governance address can call this function.
   * @dev While the contract is paused, some functions may be disabled to prevent unexpected behavior.
   */
  function pause() public onlyGovernance {
    _pause();
  }

  /**
   * @notice Unpauses the contract. Only the governance address can call this function.
   * @dev Once the contract is unpaused, all functions should be enabled again.
   */
  function unpause() public onlyGovernance {
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
    require(duration >= minDuration, "Duration must be greater than or equal to minimum duration");
    require(claimDuration <= duration, "Claim duration must be less than or equal to duration");

    period.duration = duration;
    period.minDuration = minDuration;
    period.claimDuration = claimDuration;
    period.minPercent = minPercent;
  }

  /**
   *
   * @dev Internal function to deposit WINR/vWINR as dividends.
   * @param amount The amount of WINR/vWINR to be deposited.
   * @param isVested Boolean flag indicating if tokens are vWINR.
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
    uint256 amount,
    bool isVested
  ) external isAmountNonZero(amount) nonReentrant whenNotPaused {
    // Get the address of the stake owner.
    address sender = msg.sender;
    // Determine the stake details based on the boolean flag isVested.
    StakeDividend storage stake;

    if (isVested) {
      stake = dividendVestedWINRStakes[sender];
      tokenManager.takeVestedWINR(sender, amount);
      totalStakedVestedWINR += amount;
    } else {
      stake = dividendWINRStakes[sender];
      tokenManager.takeWINR(sender, amount);
      totalStakedWINR += amount;
    }

    // If the stake amount is greater than 0, claim dividends for the stake owner.
    if (stake.amount > 0) {
      _claimDividend(sender, isVested);
    }

    // Calculate the stake weight
    uint256 weight = _calculateWeight(stake.amount + amount, isVested, false);
    // increase the total staked weight
    totalWeight += (weight - stake.weight);
    // Update the stake with the new stake amount, start time, weight and profit debt.
    stake.amount += amount;
    stake.depositTime = block.timestamp;
    stake.weight = weight;
    stake.profitDebt = _calcDebt(weight);

    // Emit a DepositDividend event with the details of the deposited tokens.
    emit DepositDividend(sender, stake.amount, stake.profitDebt, isVested);
  }

  /**
   *
   * @dev Internal function to unstake tokens.
   * @param amount The amount of tokens to be unstaked.
   * @param isVested Boolean flag indicating if stake is Vested WINR.
   * @notice This function also claims rewards.
   * @dev This function performs the following steps:
   *    Check that the staker has sufficient stake amount.
   *    Claim dividends for the staker.
   *    Compute the weight of the unstaked tokens and update the total staked amount and weight.
   *    Compute the debt for the stake after unstaking tokens.
   *    Burn the necessary amount of tokens and send the remaining unstaked tokens to the staker.
   *    Emit an Unstake event with the details of the unstaked tokens.
   */
  function unstake(uint256 amount, bool isVested) external nonReentrant whenNotPaused {
    address sender = msg.sender;
    // Check that the staker has sufficient stake amount.
    if (isVested) {
      require(dividendVestedWINRStakes[sender].amount >= amount, "Insufficient stake amount");
    } else {
      require(dividendWINRStakes[sender].amount >= amount, "Insufficient stake amount");
    }

    // Claim dividends for the staker.
    _claimDividend(sender, isVested);

    // Compute the weight of the unstaked tokens and update the total staked amount and weight.
    uint256 unstakedWeight;
    StakeDividend storage stake;

    if (isVested) {
      stake = dividendVestedWINRStakes[sender];
      unstakedWeight = amount * weightMultipliers.vWinr;
      totalStakedVestedWINR -= amount;
    } else {
      stake = dividendWINRStakes[sender];
      unstakedWeight = amount * weightMultipliers.winr;
      totalStakedWINR -= amount;
    }

    totalWeight -= unstakedWeight;

    // Update the stake details after unstaking tokens.
    stake.amount -= amount;
    stake.weight -= unstakedWeight;
    stake.profitDebt = _calcDebt(stake.weight);

    // Compute the amount of tokens to be burned and sent to the staker.
    uint256 _burnAmount = _computeBurnAmount(amount);
    uint256 _sendAmount = amount - _burnAmount;

    // Burn the necessary amount of tokens and send the remaining unstaked tokens to the staker.
    if (isVested) {
      tokenManager.burnVestedWINR(_burnAmount);
      tokenManager.sendVestedWINR(sender, _sendAmount);
    } else {
      tokenManager.burnWINR(_burnAmount);
      tokenManager.sendWINR(sender, _sendAmount);
    }

    // Emit an Unstake event with the details of the unstaked tokens.
    emit Unstake(sender, block.timestamp, _sendAmount, _burnAmount, isVested);
  }

  /*================================================= Internal Functions =======================================================*/
  /**
   *
   * @dev Internal function to claim dividends for a stake.
   * @param account The address of the stake owner.
   * @param isVested Boolean flag indicating if stake is Vested WINR.
   * @return _reward The amount of dividends claimed.
   * @dev This function performs the following steps:
   *     Determine the stake details based on the boolean flag isVested.
   *     Calculate the pending rewards for the stake.
   *     Send the rewards to the stake owner.
   *     Update the profit debt for the stake.
   *     Update the total profit and total claimed for the stake owner.
   *     Emit a Claim event with the details of the claimed rewards.
   */
  function _claimDividend(address account, bool isVested) internal returns (uint256 _reward) {
    // Determine the stake details based on the boolean flag isVested.
    StakeDividend storage stake;
    if (isVested) {
      stake = dividendVestedWINRStakes[account];
    } else {
      stake = dividendWINRStakes[account];
    }

    // Calculate the pending rewards for the stake.
    _reward = _pendingByDividendStake(stake);

    if (_reward == 0) {
      return 0;
    }
    // Send the rewards to the stake owner.
    tokenManager.sendWLP(account, _reward);

    // Update the profit debt for the stake.
    stake.profitDebt = _calcDebt(stake.weight);

    // Update the total profit and total claimed for the stake owner.
    // totalProfit -= _reward;
    totalClaimed[account] += _reward;

    // Emit a Claim event with the details of the claimed rewards.
    emit ClaimDividend(account, _reward, isVested);
  }

  /**
   * @notice Computes the pending WLP amount of the stake.
   * @param stake The stake for which to compute the pending amount.
   * @return holderProfit The pending WLP amount.
   */
  function _pendingByDividendStake(
    StakeDividend memory stake
  ) internal view returns (uint256 holderProfit) {
    // Compute the holder's profit as the product of their stake's weight and the accumulated profit per weight.
    holderProfit = ((stake.weight * accumProfitPerWeight) / PRECISION);
    // If the holder's profit is less than their profit debt, return zero.
    if (holderProfit < stake.profitDebt) {
      return 0;
    } else {
      // Otherwise, subtract their profit debt from their total profit and return the result.
      holderProfit -= stake.profitDebt;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../core/Access.sol";
import "../../interfaces/core/ITokenManager.sol";
import "../../interfaces/tokens/IWINR.sol";

contract WINRVesting is Pausable, ReentrancyGuard, Access {
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

  event DepositDividend(address indexed user, uint256 amount, uint256 profitDebt, bool isVested);
  event Withdraw(
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
    uint256[] indexes,
    uint256 burnedAmount,
    uint256 sentAmount
  );
  event ClaimVesting(address indexed user, uint256 reward, uint256[] indexes);
  event ClaimDividend(address indexed user, uint256 reward, bool isVested);
  event WeightMultipliersUpdate(WeightMultipliers _weightMultipliers);
  event UnstakeBurnPercentageUpdate(uint256 _unstakeBurnPercentage);

  /*====================================================== Modifiers ===========================================================*/
  /**
   * @notice Throws if the amount is not greater than zero
   */
  modifier isAmountNonZero(uint256 amount) {
    require(amount > 0, "amount must be greater than zero");
    _;
  }

  /*====================================================== State Variables =====================================================*/

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
  //Interface of Token Manager contract
  ITokenManager public tokenManager;
  //This mapping stores an array of StakeVesting structures for each address that has staked tokens in the contract
  mapping(address => StakeVesting[]) public stakes;
  //This mapping stores an array of indexes into the stakes array for each address that has active vesting stakes in the contract
  mapping(address => uint256[]) public activeVestingIndexes;
  //This mapping stores the total amount of tokens claimed by each address that has staked tokens in the contract
  mapping(address => uint256) public totalClaimed;
  //Initializes default vesting period
  Period public period = Period(180 days, 15 days, 165, 5e17);
  //IInitializes default reward multipliers
  WeightMultipliers public weightMultipliers = WeightMultipliers(1, 2, 1);
  //Token manager role to share rewards
  bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

  /*==================================================== Constructor ===========================================================*/
  constructor(ITokenManager _tokenManager, address _governance) Access(_governance) {
    require(address(_tokenManager) != address(0), "token manager address can't be zero");
    tokenManager = _tokenManager;
    unstakeBurnPercentage = 5e15; // 0.5% default
  }

  /*===================================================== FUNCTIONS ============================================================*/
  /*=================================================== View Functions =========================================================*/
  /**
   *
   * @dev Calculates the pending reward for a given staker.
   * @param account The address of the staker for whom to calculate the pending reward.
   * @return pending The amount of pending WLP tokens that the staker is eligible to receive.
   * @dev The function iterates over all active stakes for the given staker and calculates the pending rewards for each stake using the _pendingByVestingStake() internal function.
   * @dev The function is view-only and does not modify the state of the contract.
   */
  function pendingVestingRewards(address account) external view returns (uint256 pending) {
    uint256[] memory activeIndexes = getActiveIndexes(account);

    for (uint256 i = 0; i < activeIndexes.length; i++) {
      StakeVesting memory stake = stakes[account][activeIndexes[i]];
      pending += _pendingByVestingStake(stake);
    }
  }

  /**
   *
   * @dev Calculates the pending reward for a given staker with given index.
   * @param account The address of the staker for whom to calculate the pending reward.
   * @return pending The amount of pending WLP tokens that the staker is eligible to receive.
   * @dev The function calculates the pending rewards for the stake using the _pendingByVestingStake() internal function.
   * @dev The function is view-only and does not modify the state of the contract.
   */
  function pendingVestingByIndex(
    address account,
    uint256 index
  ) external view returns (uint256 pending) {
    // Get the stake from the stakes mapping
    StakeVesting memory stake = stakes[account][index];
    // Calculate the pending reward for the stake
    pending = _pendingByVestingStake(stake);
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
    _withdrawable = _redeemableByVesting(_stake);

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
    _totalEarned = totalProfit;
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
    if (!vested) {
      return amount * weightMultipliers.winr;
    } else {
      if (vesting) {
        return amount * weightMultipliers.vWinrVesting;
      } else {
        return amount * weightMultipliers.vWinr;
      }
    }
  }

  /**
   * @notice Computes the pending WLP amount of the stake.
   * @param stake The stake for which to compute the pending amount.
   * @return holderProfit The pending WLP amount.
   */
  function _pendingByVestingStake(
    StakeVesting memory stake
  ) internal view returns (uint256 holderProfit) {
    // Compute the holder's profit as the product of their stake's weight and the accumulated profit per weight.
    holderProfit = ((stake.weight * accumProfitPerWeight) / PRECISION);
    // If the holder's profit is less than their profit debt, return zero.
    if (holderProfit < stake.profitDebt) {
      return 0;
    } else {
      // Otherwise, subtract their profit debt from their total profit and return the result.
      holderProfit -= stake.profitDebt;
    }
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
   * @return holderProfit The withdrawable amount of WINR.
   */
  function _redeemableByVesting(
    StakeVesting memory stake
  ) internal view returns (uint256 holderProfit) {
    // Compute the total amount of time that the stake has been staked, in days.
    uint256 _totalStakedTime = (block.timestamp - stake.startTime) / 1 days;

    // Compute the minimum number of days required for staking in order to be eligible for a reward.
    uint256 _minDays = period.minDuration / 1 days;

    // If the stake has been staked for less than the minimum number of days, then the holder cannot withdraw any tokens.
    if (_totalStakedTime < _minDays) {
      holderProfit = 0;
    } else {
      // Otherwise, calculate the holder's profit as follows:
      if (block.timestamp > stake.startTime + stake.vestingDuration) {
        // If the vesting period has expired, then the holder can withdraw their full stake amount.
        _totalStakedTime = stake.vestingDuration / 1 days;
      }

      // Calculate the profit for the holder as the sum of the tokens earned on the first day and the additional tokens earned over time.
      holderProfit =
        stake.accTokenFirstDay +
        ((stake.amount - stake.accTokenFirstDay) * (_totalStakedTime - _minDays)) /
        period.claimDuration;

      // If the holder's profit is greater than their stake amount, then they can only withdraw their full stake amount.
      if (holderProfit > stake.amount) {
        holderProfit = stake.amount;
      }
    }
  }

  /*================================================= External Functions =======================================================*/

  /**
   * @dev This function cancels vesting stakes without penalty and reward.
   * It sends the staked amount to the staker.
   * @param indexes array of indexes to cancel vesting for
   * @notice Throws an error if the stake has already been withdrawn
   * @notice Emits a Cancel event upon successful execution
   */
  function cancel(uint256[] calldata indexes) external {
    // Get the address of the caller
    address sender = msg.sender;

    // Declare local variables for stake and bool values
    StakeVesting memory _stake;

    // Initialize the total amount of staked tokens to be cancelled to 0
    uint256 totalAmount = 0;

    // Loop through all of the indexes to cancel
    for (uint256 i = 0; i < indexes.length; i++) {
      // Retrieve the stake and bool values for the given index and staker
      (_stake) = getVestingStake(sender, indexes[i]);

      // Check if the stake has already been withdrawn
      require(!_stake.withdrawn, "stake has withdrawn");

      // Remove the index from the staker's active stakes list
      _removeActiveIndex(sender, indexes[i]);

      // Add the staked amount to the total amount of tokens to be cancelled
      totalAmount += _stake.amount;

      // Mark the stake as cancelled in the stakeBools mapping
      stakes[sender][indexes[i]].cancelled = true;
    }

    // Calculate the amount of tokens to burn and the amount of tokens to send to the staker
    uint256 _burnAmount = _computeBurnAmount(totalAmount);
    uint256 _sendAmount = totalAmount - _burnAmount;

    // Send the staked tokens to the staker
    tokenManager.sendVestedWINR(sender, _sendAmount);

    // Burn the remaining vesting tokens
    tokenManager.burnVestedWINR(_burnAmount);

    // Emit a Cancel event to notify listeners of the cancellation
    emit Cancel(sender, block.timestamp, indexes, _burnAmount, _sendAmount);
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
    require(_weightMultipliers.vWinrVesting != 0, "vWINR vesting multiplier can not be zero");
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
    uint256 vestingDurationInSeconds = vestingDuration * 1 days;
    require(
      vestingDurationInSeconds >= period.minDuration && vestingDuration <= period.duration,
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
   * @param indexes Indexes to withdraw
   */
  function withdrawVesting(uint256[] calldata indexes) external whenNotPaused nonReentrant {
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
      _amounts[1] += _redeemableByVesting(stake);
      _amounts[2] += _pendingByVestingStake(stake);
      _amounts[3] += stake.amount;

      // Mark this stake as withdrawn and remove its index from the active list
      stake.withdrawn = true;
      _removeActiveIndex(sender, index);
    }

    // Interact with external contracts to complete the withdrawal process
    if (_amounts[1] > 0) {
      // Mint rewards tokens if necessary
      tokenManager.mintIfNecessary(sender, _amounts[1]);
    }

    uint256 amountToMint = _amounts[3] - _amounts[1];
    if (amountToMint > 0) {
      // Mint WINR tokens to the tokenManager contract
      tokenManager.mintWINR(address(tokenManager), amountToMint);
    }

    if (_amounts[3] > _amounts[1]) {
      // Burn excess WINR tokens
      tokenManager.burnWINR(_amounts[3] - _amounts[1]);
    }

    // Burn vested WINR tokens
    tokenManager.burnVestedWINR(_amounts[3]);

    // Update the total weight and total staked amount
    totalWeight -= _amounts[0];
    totalStakedVestedWINR -= _amounts[3];

    // Claim rewards for remaining stakes
    _claim(indexes, false);

    // Emit an event to log the withdrawal
    emit Withdraw(sender, block.timestamp, indexes, _amounts[1], _amounts[1], _amounts[3]);
  }

  /*================================================= Internal Functions =======================================================*/
  /**
   * @dev Claims the reward for the specified stakes
   * @param indexes Array of the indexes to claim
   * @param isClaim Checks if the caller is the claim function
   */
  function _claim(uint256[] calldata indexes, bool isClaim) internal {
    address sender = msg.sender;
    uint256 _totalFee;

    // Check
    for (uint256 i = 0; i < indexes.length; i++) {
      uint256 index = indexes[i];

      StakeVesting memory _stake = getVestingStake(sender, index);

      // Check that the stake has not been withdrawn
      if (isClaim) {
        require(!_stake.withdrawn, "Stake has already been withdrawn");
      }

      // Check that the stake has not been cancelled
      require(!_stake.cancelled, "Stake has been cancelled");

      uint256 _fee = _pendingByVestingStake(_stake);
      _totalFee += _fee;
    }

    // Effects
    for (uint256 i = 0; i < indexes.length; i++) {
      uint256 index = indexes[i];
      stakes[sender][index].profitDebt += _totalFee;
    }

    totalProfit -= _totalFee;
    totalClaimed[sender] += _totalFee;

    // Interactions
    if (_totalFee > 0) {
      tokenManager.sendWLP(sender, _totalFee);
    }

    // Emit event
    emit ClaimVesting(sender, _totalFee, indexes);
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
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Access is AccessControlEnumerable {
  constructor(address _gov) {
    _grantRole(DEFAULT_ADMIN_ROLE, _gov);
  }

  modifier onlyGovernance() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ACCESS: Not governance");
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

  function mintIfNecessary(address _to, uint256 _amount) external;

  function mintVestedWINR(address _input, uint256 _amount, address _recipient) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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