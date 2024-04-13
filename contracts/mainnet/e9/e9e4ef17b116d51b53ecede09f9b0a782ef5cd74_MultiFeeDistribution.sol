// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {RecoverERC20} from "../libraries/RecoverERC20.sol";
import {IChefIncentivesController} from "../../interfaces/IChefIncentivesController.sol";
import {IMiddleFeeDistribution} from "../../interfaces/IMiddleFeeDistribution.sol";
import {IBountyManager} from "../../interfaces/IBountyManager.sol";
import {IMultiFeeDistribution, IFeeDistribution} from "../../interfaces/IMultiFeeDistribution.sol";
import {IMintableToken} from "../../interfaces/IMintableToken.sol";
import {LockedBalance, Balances, Reward, EarnedBalance} from "../../interfaces/LockedBalance.sol";
import {IPriceProvider} from "../../interfaces/IPriceProvider.sol";

/// @title Multi Fee Distribution Contract
/// @author Radiant
contract MultiFeeDistribution is
	IMultiFeeDistribution,
	Initializable,
	PausableUpgradeable,
	OwnableUpgradeable,
	RecoverERC20
{
	using SafeERC20 for IERC20;
	using SafeERC20 for IMintableToken;

	address private _priceProvider;

	/********************** Constants ***********************/

	uint256 public constant QUART = 25000; //  25%
	uint256 public constant HALF = 65000; //  65%
	uint256 public constant WHOLE = 100000; // 100%

	// Maximum slippage allowed to be set by users (used for compounding).
	uint256 public constant MAX_SLIPPAGE = 9500; //5%
	uint256 public constant PERCENT_DIVISOR = 10000; //100%

	uint256 public constant AGGREGATION_EPOCH = 6 days;

	/// @notice Proportion of burn amount
	uint256 public burn;

	/// @notice Duration that rewards are streamed over
	uint256 public rewardsDuration;

	/// @notice Duration that rewards loop back
	uint256 public rewardsLookback;

	/// @notice Default lock index
	uint256 public constant DEFAULT_LOCK_INDEX = 1;

	/// @notice Duration of lock/earned penalty period, used for earnings
	uint256 public defaultLockDuration;

	/// @notice Duration of vesting RDNT
	uint256 public vestDuration;

	/// @notice Returns reward converter
	address public rewardConverter;

	/********************** Contract Addresses ***********************/

	/// @notice Address of Middle Fee Distribution Contract
	IMiddleFeeDistribution public middleFeeDistribution;

	/// @notice Address of CIC contract
	IChefIncentivesController public incentivesController;

	/// @notice Address of RDNT
	IMintableToken public rdntToken;

	/// @notice Address of LP token
	address public stakingToken;

	// Address of Lock Zapper
	/// @custom:oz-renamed-from lockZap
	address internal _lockZap;

	/********************** Lock & Earn Info ***********************/

	// Private mappings for balance data
	/// @custom:oz-renamed-from balances
	mapping(address => Balances) private _balances;
	/// @custom:oz-renamed-from userLocks
	mapping(address => LockedBalance[]) internal _userLocks;
	/// @custom:oz-renamed-from userEarnings
	mapping(address => LockedBalance[]) private _userEarnings;

	/**
	 * @dev The following slot `autocompoundEnabled` was deprecated in an upgrade.
	 * Was: it allowed to know "who opted into autocompounding"
	 * Is: Autocompounded is enabled for all users by default and it can be disabled by the user
	 */
	mapping(address => bool) private _deprecatedAutocompoundEnabledSlot;

	mapping(address => uint256) public lastAutocompound;

	/// @notice Total locked value
	uint256 public lockedSupply;

	/// @notice Total locked value in multipliers
	uint256 public lockedSupplyWithMultiplier;

	// Time lengths
	/// @custom:oz-renamed-from lockPeriod
	uint256[] internal _lockPeriod;

	// Multipliers
	/// @custom:oz-renamed-from rewardMultipliers
	uint256[] internal _rewardMultipliers;

	/********************** Reward Info ***********************/

	/// @notice Reward tokens being distributed
	address[] public rewardTokens;

	/// @notice Reward data per token
	mapping(address => Reward) public rewardData;

	/// @notice user -> reward token -> rpt; RPT for paid amount
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

	/// @notice user -> reward token -> amount; used to store reward amount
	mapping(address => mapping(address => uint256)) public rewards;

	/********************** Other Info ***********************/

	/// @notice DAO wallet
	address public daoTreasury;

	/// @notice treasury wallet
	/// @custom:oz-renamed-from startfleetTreasury
	address public starfleetTreasury;

	/// @notice Addresses approved to call mint
	mapping(address => bool) public minters;

	// Addresses to relock
	mapping(address => bool) public autoRelockDisabled;

	// Default lock index for relock
	mapping(address => uint256) public defaultLockIndex;

	/// @notice Flag to prevent more minter addings
	bool public mintersAreSet;

	/// @notice Legacy state variable, kept to preserve storage layout
	address public userlist;

	/// @notice Last claim time of the user
	mapping(address => uint256) public lastClaimTime;

	/// @notice Bounty manager contract
	address public bountyManager;

	/// @notice Maximum slippage for each trade excepted by the individual user when performing compound trades
	mapping(address => uint256) public userSlippage;

	mapping(address => bool) public autocompoundDisabled;

	/********************** Events ***********************/

	event Locked(address indexed user, uint256 amount, uint256 lockedBalance, uint256 indexed lockLength, bool isLP);
	event Withdrawn(
		address indexed user,
		uint256 receivedAmount,
		uint256 lockedBalance,
		uint256 penalty,
		uint256 burn,
		bool isLP
	);
	event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
	event Relocked(address indexed user, uint256 amount, uint256 lockIndex);
	event BountyManagerUpdated(address indexed _bounty);
	event RewardConverterUpdated(address indexed _rewardConverter);
	event LockTypeInfoUpdated(uint256[] lockPeriod, uint256[] rewardMultipliers);
	event AddressesUpdated(
		IChefIncentivesController _controller,
		IMiddleFeeDistribution _middleFeeDistribution,
		address indexed _treasury
	);
	event LPTokenUpdated(address indexed _stakingToken);
	event RewardAdded(address indexed _rewardToken);
	event LockerAdded(address indexed locker);
	event LockerRemoved(address indexed locker);
	event UserAutocompoundUpdated(address indexed user, bool indexed state);
	event UserSlippageUpdated(address indexed user, uint256 slippage);

	/********************** Errors ***********************/
	error AddressZero();
	error AmountZero();
	error InvalidBurn();
	error InvalidLookback();
	error MintersSet();
	error InvalidLockPeriod();
	error InsufficientPermission();
	error AlreadyAdded();
	error AlreadySet();
	error InvalidType();
	error ActiveReward();
	error InvalidAmount();
	error InvalidEarned();
	error InvalidTime();
	error InvalidPeriod();
	error UnlockTimeNotFound();
	error InvalidAddress();
	error InvalidAction();

	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev Initializer
	 *  First reward MUST be the RDNT token or things will break
	 *  related to the 50% penalty and distribution to locked balances.
	 * @param rdntToken_ RDNT token address
	 * @param lockZap_ LockZap contract address
	 * @param dao_ DAO address
	 * @param priceProvider_ PriceProvider contract address
	 * @param rewardsDuration_ Duration that rewards are streamed over
	 * @param rewardsLookback_ Duration that rewards loop back
	 * @param lockDuration_ lock duration
	 * @param burnRatio_ Proportion of burn amount
	 * @param vestDuration_ vest duration
	 */
	function initialize(
		address rdntToken_,
		address lockZap_,
		address dao_,
		address priceProvider_,
		uint256 rewardsDuration_,
		uint256 rewardsLookback_,
		uint256 lockDuration_,
		uint256 burnRatio_,
		uint256 vestDuration_
	) public initializer {
		if (rdntToken_ == address(0)) revert AddressZero();
		if (lockZap_ == address(0)) revert AddressZero();
		if (dao_ == address(0)) revert AddressZero();
		if (priceProvider_ == address(0)) revert AddressZero();
		if (rewardsDuration_ == uint256(0)) revert AmountZero();
		if (rewardsLookback_ == uint256(0)) revert AmountZero();
		if (lockDuration_ == uint256(0)) revert AmountZero();
		if (vestDuration_ == uint256(0)) revert AmountZero();
		if (burnRatio_ > WHOLE) revert InvalidBurn();
		if (rewardsLookback_ > rewardsDuration_) revert InvalidLookback();

		__Pausable_init();
		__Ownable_init();

		rdntToken = IMintableToken(rdntToken_);
		_lockZap = lockZap_;
		daoTreasury = dao_;
		_priceProvider = priceProvider_;
		rewardTokens.push(rdntToken_);
		rewardData[rdntToken_].lastUpdateTime = block.timestamp;

		rewardsDuration = rewardsDuration_;
		rewardsLookback = rewardsLookback_;
		defaultLockDuration = lockDuration_;
		burn = burnRatio_;
		vestDuration = vestDuration_;
	}

	/********************** Setters ***********************/

	/**
	 * @notice Set minters
	 * @dev Can be called only once
	 * @param minters_ array of address
	 */
	function setMinters(address[] calldata minters_) external onlyOwner {
		if (mintersAreSet) revert MintersSet();
		uint256 length = minters_.length;
		for (uint256 i; i < length; ) {
			if (minters_[i] == address(0)) revert AddressZero();
			minters[minters_[i]] = true;
			unchecked {
				i++;
			}
		}
		mintersAreSet = true;
	}

	/**
	 * @notice Sets bounty manager contract.
	 * @param bounty contract address
	 */
	function setBountyManager(address bounty) external onlyOwner {
		if (bounty == address(0)) revert AddressZero();
		bountyManager = bounty;
		minters[bounty] = true;
		emit BountyManagerUpdated(bounty);
	}

	/**
	 * @notice Sets reward converter contract.
	 * @param rewardConverter_ contract address
	 */
	function addRewardConverter(address rewardConverter_) external onlyOwner {
		if (rewardConverter_ == address(0)) revert AddressZero();
		rewardConverter = rewardConverter_;
		emit RewardConverterUpdated(rewardConverter_);
	}

	/**
	 * @notice Sets lock period and reward multipliers.
	 * @param lockPeriod_ lock period array
	 * @param rewardMultipliers_ multipliers per lock period
	 */
	function setLockTypeInfo(uint256[] calldata lockPeriod_, uint256[] calldata rewardMultipliers_) external onlyOwner {
		if (lockPeriod_.length != rewardMultipliers_.length) revert InvalidLockPeriod();
		delete _lockPeriod;
		delete _rewardMultipliers;
		uint256 length = lockPeriod_.length;
		for (uint256 i; i < length; ) {
			_lockPeriod.push(lockPeriod_[i]);
			_rewardMultipliers.push(rewardMultipliers_[i]);
			unchecked {
				i++;
			}
		}
		emit LockTypeInfoUpdated(lockPeriod_, rewardMultipliers_);
	}

	/**
	 * @notice Set CIC, MFD and Treasury.
	 * @param controller_ CIC address
	 * @param middleFeeDistribution_ address
	 * @param treasury_ address
	 */
	function setAddresses(
		IChefIncentivesController controller_,
		IMiddleFeeDistribution middleFeeDistribution_,
		address treasury_
	) external onlyOwner {
		if (address(controller_) == address(0)) revert AddressZero();
		if (address(middleFeeDistribution_) == address(0)) revert AddressZero();
		incentivesController = controller_;
		middleFeeDistribution = middleFeeDistribution_;
		starfleetTreasury = treasury_;
		emit AddressesUpdated(controller_, middleFeeDistribution_, treasury_);
	}

	/**
	 * @notice Set LP token.
	 * @param stakingToken_ LP token address
	 */
	function setLPToken(address stakingToken_) external onlyOwner {
		if (stakingToken_ == address(0)) revert AddressZero();
		if (stakingToken != address(0)) revert AlreadySet();
		stakingToken = stakingToken_;
		emit LPTokenUpdated(stakingToken_);
	}

	/**
	 * @notice Add a new reward token to be distributed to stakers.
	 * @param rewardToken address
	 */
	function addReward(address rewardToken) external {
		if (rewardToken == address(0)) revert AddressZero();
		if (!minters[msg.sender]) revert InsufficientPermission();
		if (rewardData[rewardToken].lastUpdateTime != 0) revert AlreadyAdded();
		rewardTokens.push(rewardToken);

		Reward storage rd = rewardData[rewardToken];
		rd.lastUpdateTime = block.timestamp;
		rd.periodFinish = block.timestamp;

		emit RewardAdded(rewardToken);
	}

	/**
	 * @notice Remove an existing reward token.
	 * @param _rewardToken address to be removed
	 */
	function removeReward(address _rewardToken) external {
		if (!minters[msg.sender]) revert InsufficientPermission();

		bool isTokenFound;
		uint256 indexToRemove;

		uint256 length = rewardTokens.length;
		for (uint256 i; i < length; i++) {
			if (rewardTokens[i] == _rewardToken) {
				isTokenFound = true;
				indexToRemove = i;
				break;
			}
		}

		if (!isTokenFound) revert InvalidAddress();

		// Reward token order is changed, but that doesn't have an impact
		if (indexToRemove < length - 1) {
			rewardTokens[indexToRemove] = rewardTokens[length - 1];
		}

		rewardTokens.pop();

		// Scrub historical reward token data
		Reward storage rd = rewardData[_rewardToken];
		rd.lastUpdateTime = 0;
		rd.periodFinish = 0;
		rd.balance = 0;
		rd.rewardPerSecond = 0;
		rd.rewardPerTokenStored = 0;
	}

	/**
	 * @notice Set default lock type index for user relock.
	 * @param index of default lock length
	 */
	function setDefaultRelockTypeIndex(uint256 index) external {
		if (index >= _lockPeriod.length) revert InvalidType();
		defaultLockIndex[msg.sender] = index;
	}

	/**
	 * @notice Sets the autocompound status and the desired max slippage.
	 * @param enable true if autocompound is to be enabled
	 * @param slippage the maximum amount of slippage that the user will incur for each compounding trade
	 */
	function setAutocompound(bool enable, uint256 slippage) external {
		if (enable == autocompoundDisabled[msg.sender]) {
			toggleAutocompound();
		}
		setUserSlippage(slippage);
	}

	/**
	 * @notice Set what slippage to use for tokens traded during the auto compound process on behalf of the user
	 * @param slippage the maximum amount of slippage that the user will incur for each compounding trade
	 */
	function setUserSlippage(uint256 slippage) public {
		if (slippage < MAX_SLIPPAGE || slippage >= PERCENT_DIVISOR) {
			revert InvalidAmount();
		}
		userSlippage[msg.sender] = slippage;
		emit UserSlippageUpdated(msg.sender, slippage);
	}

	/**
	 * @notice Toggle a users autocompound status.
	 */
	function toggleAutocompound() public {
		bool newStatus = !autocompoundDisabled[msg.sender];
		autocompoundDisabled[msg.sender] = newStatus;
		emit UserAutocompoundUpdated(msg.sender, newStatus);
	}

	/**
	 * @notice Set relock status
	 * @param status true if auto relock is enabled.
	 */
	function setRelock(bool status) external virtual {
		autoRelockDisabled[msg.sender] = !status;
	}

	/**
	 * @notice Sets the lookback period
	 * @param lookback in seconds
	 */
	function setLookback(uint256 lookback) external onlyOwner {
		if (lookback == uint256(0)) revert AmountZero();
		if (lookback > rewardsDuration) revert InvalidLookback();

		rewardsLookback = lookback;
	}

	/********************** External functions ***********************/

	/**
	 * @notice Stake tokens to receive rewards.
	 * @dev Locked tokens cannot be withdrawn for defaultLockDuration and are eligible to receive rewards.
	 * @param amount to stake.
	 * @param onBehalfOf address for staking.
	 * @param typeIndex lock type index.
	 */
	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external {
		_stake(amount, onBehalfOf, typeIndex, false);
	}

	/**
	 * @notice Add to earnings
	 * @dev Minted tokens receive rewards normally but incur a 50% penalty when
	 *  withdrawn before vestDuration has passed.
	 * @param user vesting owner.
	 * @param amount to vest.
	 * @param withPenalty does this bear penalty?
	 */
	function vestTokens(address user, uint256 amount, bool withPenalty) external whenNotPaused {
		if (!minters[msg.sender]) revert InsufficientPermission();
		if (amount == 0) return;

		if (user == address(this)) {
			// minting to this contract adds the new tokens as incentives for lockers
			_notifyReward(address(rdntToken), amount);
			return;
		}

		Balances storage bal = _balances[user];
		bal.total = bal.total + amount;
		if (withPenalty) {
			bal.earned = bal.earned + amount;
			LockedBalance[] storage earnings = _userEarnings[user];

			uint256 currentDay = block.timestamp / 1 days;
			uint256 lastIndex = earnings.length > 0 ? earnings.length - 1 : 0;
			uint256 vestingDurationDays = vestDuration / 1 days;

			// We check if an entry for the current day already exists. If yes, add new amount to that entry
			if (earnings.length > 0 && (earnings[lastIndex].unlockTime / 1 days) == currentDay + vestingDurationDays) {
				earnings[lastIndex].amount = earnings[lastIndex].amount + amount;
			} else {
				// If there is no entry for the current day, create a new one
				uint256 unlockTime = block.timestamp + vestDuration;
				earnings.push(
					LockedBalance({amount: amount, unlockTime: unlockTime, multiplier: 1, duration: vestDuration})
				);
			}
		} else {
			bal.unlocked = bal.unlocked + amount;
		}
	}

	/**
	 * @notice Withdraw tokens from earnings and unlocked.
	 * @dev First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
	 *  incurs a 50% penalty which is distributed based on locked balances.
	 * @param amount for withdraw
	 */
	function withdraw(uint256 amount) external {
		address _address = msg.sender;
		if (amount == 0) revert AmountZero();

		uint256 penaltyAmount;
		uint256 burnAmount;
		Balances storage bal = _balances[_address];

		if (amount <= bal.unlocked) {
			bal.unlocked = bal.unlocked - amount;
		} else {
			uint256 remaining = amount - bal.unlocked;
			if (bal.earned < remaining) revert InvalidEarned();
			bal.unlocked = 0;
			uint256 sumEarned = bal.earned;
			uint256 i;
			for (i = 0; ; ) {
				uint256 earnedAmount = _userEarnings[_address][i].amount;
				if (earnedAmount == 0) continue;
				(
					uint256 withdrawAmount,
					uint256 penaltyFactor,
					uint256 newPenaltyAmount,
					uint256 newBurnAmount
				) = _penaltyInfo(_userEarnings[_address][i]);

				uint256 requiredAmount = earnedAmount;
				if (remaining >= withdrawAmount) {
					remaining = remaining - withdrawAmount;
					if (remaining == 0) i++;
				} else {
					requiredAmount = (remaining * WHOLE) / (WHOLE - penaltyFactor);
					_userEarnings[_address][i].amount = earnedAmount - requiredAmount;
					remaining = 0;

					newPenaltyAmount = (requiredAmount * penaltyFactor) / WHOLE;
					newBurnAmount = (newPenaltyAmount * burn) / WHOLE;
				}
				sumEarned = sumEarned - requiredAmount;

				penaltyAmount = penaltyAmount + newPenaltyAmount;
				burnAmount = burnAmount + newBurnAmount;

				if (remaining == 0) {
					break;
				} else {
					if (sumEarned == 0) revert InvalidEarned();
				}
				unchecked {
					i++;
				}
			}
			if (i > 0) {
				uint256 length = _userEarnings[_address].length;
				for (uint256 j = i; j < length; ) {
					_userEarnings[_address][j - i] = _userEarnings[_address][j];
					unchecked {
						j++;
					}
				}
				for (uint256 j = 0; j < i; ) {
					_userEarnings[_address].pop();
					unchecked {
						j++;
					}
				}
			}
			bal.earned = sumEarned;
		}

		// Update values
		bal.total = bal.total - amount - penaltyAmount;

		_withdrawTokens(_address, amount, penaltyAmount, burnAmount, false);
	}

	/**
	 * @notice Withdraw individual unlocked balance and earnings, optionally claim pending rewards.
	 * @param claimRewards true to claim rewards when exit
	 * @param unlockTime of earning
	 */
	function individualEarlyExit(bool claimRewards, uint256 unlockTime) external {
		address onBehalfOf = msg.sender;
		if (unlockTime <= block.timestamp) revert InvalidTime();
		(uint256 amount, uint256 penaltyAmount, uint256 burnAmount, uint256 index) = _ieeWithdrawableBalance(
			onBehalfOf,
			unlockTime
		);

		uint256 length = _userEarnings[onBehalfOf].length;
		for (uint256 i = index + 1; i < length; ) {
			_userEarnings[onBehalfOf][i - 1] = _userEarnings[onBehalfOf][i];
			unchecked {
				i++;
			}
		}
		_userEarnings[onBehalfOf].pop();

		Balances storage bal = _balances[onBehalfOf];
		bal.total = bal.total - amount - penaltyAmount;
		bal.earned = bal.earned - amount - penaltyAmount;

		_withdrawTokens(onBehalfOf, amount, penaltyAmount, burnAmount, claimRewards);
	}

	/**
	 * @notice Withdraw full unlocked balance and earnings, optionally claim pending rewards.
	 * @param claimRewards true to claim rewards when exit
	 */
	function exit(bool claimRewards) external {
		address onBehalfOf = msg.sender;
		(uint256 amount, uint256 penaltyAmount, uint256 burnAmount) = withdrawableBalance(onBehalfOf);

		delete _userEarnings[onBehalfOf];

		Balances storage bal = _balances[onBehalfOf];
		bal.total = bal.total - bal.unlocked - bal.earned;
		bal.unlocked = 0;
		bal.earned = 0;

		_withdrawTokens(onBehalfOf, amount, penaltyAmount, burnAmount, claimRewards);
	}

	/**
	 * @notice Claim all pending staking rewards.
	 */
	function getAllRewards() external {
		return getReward(rewardTokens);
	}

	/**
	 * @notice Withdraw expired locks with options
	 * @param address_ for withdraw
	 * @param limit_ of lock length for withdraw
	 * @param isRelockAction_ option to relock
	 * @return withdraw amount
	 */
	function withdrawExpiredLocksForWithOptions(
		address address_,
		uint256 limit_,
		bool isRelockAction_
	) external returns (uint256) {
		if (limit_ == 0) limit_ = _userLocks[address_].length;

		return _withdrawExpiredLocksFor(address_, isRelockAction_, true, limit_);
	}

	/**
	 * @notice Zap vesting RDNT tokens to LP
	 * @param user address
	 * @return zapped amount
	 */
	function zapVestingToLp(address user) external returns (uint256 zapped) {
		if (msg.sender != _lockZap) revert InsufficientPermission();

		_updateReward(user);

		uint256 currentTimestamp = block.timestamp;
		LockedBalance[] storage earnings = _userEarnings[user];
		for (uint256 i = earnings.length; i > 0; ) {
			if (earnings[i - 1].unlockTime > currentTimestamp) {
				zapped = zapped + earnings[i - 1].amount;
				earnings.pop();
			} else {
				break;
			}
			unchecked {
				i--;
			}
		}

		rdntToken.safeTransfer(_lockZap, zapped);

		Balances storage bal = _balances[user];
		bal.earned = bal.earned - zapped;
		bal.total = bal.total - zapped;

		IPriceProvider(_priceProvider).update();

		return zapped;
	}

	/**
	 * @notice Claim rewards by converter.
	 * @dev Rewards are transfered to converter. In the Radiant Capital protocol
	 * 		the role of the Converter is taken over by Compounder.sol.
	 * @param onBehalf address to claim.
	 */
	function claimFromConverter(address onBehalf) external whenNotPaused {
		if (msg.sender != rewardConverter) revert InsufficientPermission();
		_updateReward(onBehalf);
		middleFeeDistribution.forwardReward(rewardTokens);
		uint256 length = rewardTokens.length;
		for (uint256 i; i < length; ) {
			address token = rewardTokens[i];
			if (token != address(rdntToken)) {
				_notifyUnseenReward(token);
				uint256 reward = rewards[onBehalf][token] / 1e12;
				if (reward > 0) {
					rewards[onBehalf][token] = 0;
					rewardData[token].balance = rewardData[token].balance - reward;

					IERC20(token).safeTransfer(rewardConverter, reward);
					emit RewardPaid(onBehalf, token, reward);
				}
			}
			unchecked {
				i++;
			}
		}
		IPriceProvider(_priceProvider).update();
		lastClaimTime[onBehalf] = block.timestamp;
	}

	/**
	 * @notice Withdraw and restake assets.
	 */
	function relock() external virtual {
		uint256 amount = _withdrawExpiredLocksFor(msg.sender, true, true, _userLocks[msg.sender].length);
		emit Relocked(msg.sender, amount, defaultLockIndex[msg.sender]);
	}

	/**
	 * @notice Requalify user
	 */
	function requalify() external {
		requalifyFor(msg.sender);
	}

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders.
	 * @param tokenAddress to recover.
	 * @param tokenAmount to recover.
	 */
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		_recoverERC20(tokenAddress, tokenAmount);
	}

	/********************** External View functions ***********************/

	/**
	 * @notice Return lock duration.
	 */
	function getLockDurations() external view returns (uint256[] memory) {
		return _lockPeriod;
	}

	/**
	 * @notice Return reward multipliers.
	 */
	function getLockMultipliers() external view returns (uint256[] memory) {
		return _rewardMultipliers;
	}

	/**
	 * @notice Returns all locks of a user.
	 * @param user address.
	 * @return lockInfo of the user.
	 */
	function lockInfo(address user) external view returns (LockedBalance[] memory) {
		return _userLocks[user];
	}

	/**
	 * @notice Total balance of an account, including unlocked, locked and earned tokens.
	 * @param user address.
	 */
	function totalBalance(address user) external view returns (uint256) {
		if (stakingToken == address(rdntToken)) {
			return _balances[user].total;
		}
		return _balances[user].locked;
	}

	/**
	 * @notice Returns price provider address
	 */
	function getPriceProvider() external view returns (address) {
		return _priceProvider;
	}

	/**
	 * @notice Reward amount of the duration.
	 * @param rewardToken for the reward
	 * @return reward amount for duration
	 */
	function getRewardForDuration(address rewardToken) external view returns (uint256) {
		return (rewardData[rewardToken].rewardPerSecond * rewardsDuration) / 1e12;
	}

	/**
	 * @notice Total balance of an account, including unlocked, locked and earned tokens.
	 * @param user address of the user for which the balances are fetched
	 */
	function getBalances(address user) external view returns (Balances memory) {
		return _balances[user];
	}

	/********************** Public functions ***********************/

	/**
	 * @notice Claims bounty.
	 * @dev Remove expired locks
	 * @param user address
	 * @param execute true if this is actual execution
	 * @return issueBaseBounty true if needs to issue base bounty
	 */
	function claimBounty(address user, bool execute) public whenNotPaused returns (bool issueBaseBounty) {
		if (msg.sender != address(bountyManager)) revert InsufficientPermission();

		(, uint256 unlockable, , , ) = lockedBalances(user);
		if (unlockable == 0) {
			return (false);
		} else {
			issueBaseBounty = true;
		}

		if (!execute) {
			return (issueBaseBounty);
		}
		// Withdraw the user's expried locks
		_withdrawExpiredLocksFor(user, false, true, _userLocks[user].length);
	}

	/**
	 * @notice Claim all pending staking rewards.
	 * @param rewardTokens_ array of reward tokens
	 */
	function getReward(address[] memory rewardTokens_) public {
		_updateReward(msg.sender);
		_getReward(msg.sender, rewardTokens_);
		IPriceProvider(_priceProvider).update();
	}

	/**
	 * @notice Pause MFD functionalities
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @notice Resume MFD functionalities
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @notice Requalify user for reward elgibility
	 * @param user address
	 */
	function requalifyFor(address user) public {
		incentivesController.afterLockUpdate(user);
	}

	/**
	 * @notice Information on a user's lockings
	 * @return total balance of locks
	 * @return unlockable balance
	 * @return locked balance
	 * @return lockedWithMultiplier
	 * @return lockData which is an array of locks
	 */
	function lockedBalances(
		address user
	)
		public
		view
		returns (
			uint256 total,
			uint256 unlockable,
			uint256 locked,
			uint256 lockedWithMultiplier,
			LockedBalance[] memory lockData
		)
	{
		LockedBalance[] storage locks = _userLocks[user];
		uint256 length = locks.length;
		lockData = new LockedBalance[](length);
		for (uint256 i; i < length; ) {
			lockData[i] = locks[i];
			if (locks[i].unlockTime > block.timestamp) {
				locked = locked + locks[i].amount;
				lockedWithMultiplier = lockedWithMultiplier + (locks[i].amount * locks[i].multiplier);
			} else {
				unlockable = unlockable + locks[i].amount;
			}
			unchecked {
				i++;
			}
		}
		total = _balances[user].locked;
	}

	/**
	 * @notice Reward locked amount of the user.
	 * @param user address
	 * @return locked amount
	 */
	function lockedBalance(address user) public view returns (uint256 locked) {
		LockedBalance[] storage locks = _userLocks[user];
		uint256 length = locks.length;
		uint256 currentTimestamp = block.timestamp;
		for (uint256 i; i < length; ) {
			if (locks[i].unlockTime > currentTimestamp) {
				locked = locked + locks[i].amount;
			}
			unchecked {
				i++;
			}
		}
	}

	/**
	 * @notice Earnings which are vesting, and earnings which have vested for full duration.
	 * @dev Earned balances may be withdrawn immediately, but will incur a penalty between 25-90%, based on a linear schedule of elapsed time.
	 * @return totalVesting sum of vesting tokens
	 * @return unlocked earnings
	 * @return earningsData which is an array of all infos
	 */
	function earnedBalances(
		address user
	) public view returns (uint256 totalVesting, uint256 unlocked, EarnedBalance[] memory earningsData) {
		unlocked = _balances[user].unlocked;
		LockedBalance[] storage earnings = _userEarnings[user];
		uint256 idx;
		uint256 length = earnings.length;
		uint256 currentTimestamp = block.timestamp;
		for (uint256 i; i < length; ) {
			if (earnings[i].unlockTime > currentTimestamp) {
				if (idx == 0) {
					earningsData = new EarnedBalance[](earnings.length - i);
				}
				(, uint256 penaltyAmount, , ) = _ieeWithdrawableBalance(user, earnings[i].unlockTime);
				earningsData[idx].amount = earnings[i].amount;
				earningsData[idx].unlockTime = earnings[i].unlockTime;
				earningsData[idx].penalty = penaltyAmount;
				idx++;
				totalVesting = totalVesting + earnings[i].amount;
			} else {
				unlocked = unlocked + earnings[i].amount;
			}
			unchecked {
				i++;
			}
		}
		return (totalVesting, unlocked, earningsData);
	}

	/**
	 * @notice Final balance received and penalty balance paid by user upon calling exit.
	 * @dev This is earnings, not locks.
	 * @param user address.
	 * @return amount total withdrawable amount.
	 * @return penaltyAmount penalty amount.
	 * @return burnAmount amount to burn.
	 */
	function withdrawableBalance(
		address user
	) public view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount) {
		uint256 earned = _balances[user].earned;
		if (earned > 0) {
			uint256 length = _userEarnings[user].length;
			for (uint256 i; i < length; ) {
				uint256 earnedAmount = _userEarnings[user][i].amount;
				if (earnedAmount == 0) continue;
				(, , uint256 newPenaltyAmount, uint256 newBurnAmount) = _penaltyInfo(_userEarnings[user][i]);
				penaltyAmount = penaltyAmount + newPenaltyAmount;
				burnAmount = burnAmount + newBurnAmount;
				unchecked {
					i++;
				}
			}
		}
		amount = _balances[user].unlocked + earned - penaltyAmount;
		return (amount, penaltyAmount, burnAmount);
	}

	/**
	 * @notice Returns reward applicable timestamp.
	 * @param rewardToken for the reward
	 * @return end time of reward period
	 */
	function lastTimeRewardApplicable(address rewardToken) public view returns (uint256) {
		uint256 periodFinish = rewardData[rewardToken].periodFinish;
		return block.timestamp < periodFinish ? block.timestamp : periodFinish;
	}

	/**
	 * @notice Reward amount per token
	 * @dev Reward is distributed only for locks.
	 * @param rewardToken for reward
	 * @return rptStored current RPT with accumulated rewards
	 */
	function rewardPerToken(address rewardToken) public view returns (uint256 rptStored) {
		rptStored = rewardData[rewardToken].rewardPerTokenStored;
		if (lockedSupplyWithMultiplier > 0) {
			uint256 newReward = (lastTimeRewardApplicable(rewardToken) - rewardData[rewardToken].lastUpdateTime) *
				rewardData[rewardToken].rewardPerSecond;
			rptStored = rptStored + ((newReward * 1e18) / lockedSupplyWithMultiplier);
		}
	}

	/**
	 * @notice Address and claimable amount of all reward tokens for the given account.
	 * @param account for rewards
	 * @return rewardsData array of rewards
	 */
	function claimableRewards(address account) public view returns (IFeeDistribution.RewardData[] memory rewardsData) {
		rewardsData = new IFeeDistribution.RewardData[](rewardTokens.length);

		uint256 length = rewardTokens.length;
		for (uint256 i; i < length; ) {
			rewardsData[i].token = rewardTokens[i];
			rewardsData[i].amount =
				_earned(
					account,
					rewardsData[i].token,
					_balances[account].lockedWithMultiplier,
					rewardPerToken(rewardsData[i].token)
				) /
				1e12;
			unchecked {
				i++;
			}
		}
		return rewardsData;
	}

	/********************** Internal functions ***********************/

	/**
	 * @notice Stake tokens to receive rewards.
	 * @dev Locked tokens cannot be withdrawn for defaultLockDuration and are eligible to receive rewards.
	 * @param amount to stake.
	 * @param onBehalfOf address for staking.
	 * @param typeIndex lock type index.
	 * @param isRelock true if this is with relock enabled.
	 */
	function _stake(uint256 amount, address onBehalfOf, uint256 typeIndex, bool isRelock) internal whenNotPaused {
		if (amount == 0) return;
		if (bountyManager != address(0)) {
			if (amount < IBountyManager(bountyManager).minDLPBalance()) revert InvalidAmount();
		}
		if (typeIndex >= _lockPeriod.length) revert InvalidType();

		_updateReward(onBehalfOf);

		LockedBalance[] memory userLocks = _userLocks[onBehalfOf];
		uint256 userLocksLength = userLocks.length;

		Balances storage bal = _balances[onBehalfOf];
		bal.total = bal.total + amount;

		bal.locked = bal.locked + amount;
		lockedSupply = lockedSupply + amount;

		uint256 rewardMultiplier = _rewardMultipliers[typeIndex];
		bal.lockedWithMultiplier = bal.lockedWithMultiplier + (amount * rewardMultiplier);
		lockedSupplyWithMultiplier = lockedSupplyWithMultiplier + (amount * rewardMultiplier);

		uint256 unlockTime = block.timestamp + _lockPeriod[typeIndex];
		uint256 unlockWeek = unlockTime / AGGREGATION_EPOCH;
		bool isAggregated;
		for (uint256 i; i < userLocksLength; ) {
			if (
				userLocks[i].unlockTime / AGGREGATION_EPOCH == unlockWeek && userLocks[i].multiplier == rewardMultiplier
			) {
				_userLocks[onBehalfOf][i].amount = userLocks[i].amount + amount;
				isAggregated = true;
				break;
			}
			unchecked {
				i++;
			}
		}
		if (!isAggregated) {
			_userLocks[onBehalfOf].push(
				LockedBalance({
					amount: amount,
					unlockTime: unlockTime,
					multiplier: rewardMultiplier,
					duration: _lockPeriod[typeIndex]
				})
			);
			emit LockerAdded(onBehalfOf);
		}

		if (!isRelock) {
			IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
		}

		incentivesController.afterLockUpdate(onBehalfOf);
		emit Locked(
			onBehalfOf,
			amount,
			_balances[onBehalfOf].locked,
			_lockPeriod[typeIndex],
			stakingToken != address(rdntToken)
		);
	}

	/**
	 * @notice Update user reward info.
	 * @param account address
	 */
	function _updateReward(address account) internal {
		uint256 balance = _balances[account].lockedWithMultiplier;
		uint256 length = rewardTokens.length;
		for (uint256 i = 0; i < length; ) {
			address token = rewardTokens[i];
			uint256 rpt = rewardPerToken(token);

			Reward storage r = rewardData[token];
			r.rewardPerTokenStored = rpt;
			r.lastUpdateTime = lastTimeRewardApplicable(token);

			if (account != address(this)) {
				rewards[account][token] = _earned(account, token, balance, rpt);
				userRewardPerTokenPaid[account][token] = rpt;
			}
			unchecked {
				i++;
			}
		}
	}

	/**
	 * @notice Add new reward.
	 * @dev If prev reward period is not done, then it resets `rewardPerSecond` and restarts period
	 * @param rewardToken address
	 * @param reward amount
	 */
	function _notifyReward(address rewardToken, uint256 reward) internal {
		Reward storage r = rewardData[rewardToken];
		if (block.timestamp >= r.periodFinish) {
			r.rewardPerSecond = (reward * 1e12) / rewardsDuration;
		} else {
			uint256 remaining = r.periodFinish - block.timestamp;
			uint256 leftover = (remaining * r.rewardPerSecond) / 1e12;
			r.rewardPerSecond = ((reward + leftover) * 1e12) / rewardsDuration;
		}

		r.lastUpdateTime = block.timestamp;
		r.periodFinish = block.timestamp + rewardsDuration;
		r.balance = r.balance + reward;
	}

	/**
	 * @notice Notify unseen rewards.
	 * @dev for rewards other than RDNT token, every 24 hours we check if new
	 *  rewards were sent to the contract or accrued via aToken interest.
	 * @param token address
	 */
	function _notifyUnseenReward(address token) internal {
		if (token == address(0)) revert AddressZero();
		if (token == address(rdntToken)) {
			return;
		}
		Reward storage r = rewardData[token];
		uint256 periodFinish = r.periodFinish;
		if (periodFinish == 0) revert InvalidPeriod();
		if (periodFinish < block.timestamp + rewardsDuration - rewardsLookback) {
			uint256 unseen = IERC20(token).balanceOf(address(this)) - r.balance;
			if (unseen > 0) {
				_notifyReward(token, unseen);
			}
		}
	}

	/**
	 * @notice User gets reward
	 * @param user address
	 * @param rewardTokens_ array of reward tokens
	 */
	function _getReward(address user, address[] memory rewardTokens_) internal whenNotPaused {
		middleFeeDistribution.forwardReward(rewardTokens_);
		uint256 length = rewardTokens_.length;
		IChefIncentivesController chefIncentivesController = incentivesController;
		chefIncentivesController.setEligibilityExempt(user, true);
		for (uint256 i; i < length; ) {
			address token = rewardTokens_[i];
			_notifyUnseenReward(token);
			uint256 reward = rewards[user][token] / 1e12;
			if (reward > 0) {
				rewards[user][token] = 0;
				rewardData[token].balance = rewardData[token].balance - reward;

				IERC20(token).safeTransfer(user, reward);
				emit RewardPaid(user, token, reward);
			}
			unchecked {
				i++;
			}
		}
		chefIncentivesController.setEligibilityExempt(user, false);
		chefIncentivesController.afterLockUpdate(user);
	}

	/**
	 * @notice Withdraw tokens from MFD
	 * @param onBehalfOf address to withdraw
	 * @param amount of withdraw
	 * @param penaltyAmount penalty applied amount
	 * @param burnAmount amount to burn
	 * @param claimRewards option to claim rewards
	 */
	function _withdrawTokens(
		address onBehalfOf,
		uint256 amount,
		uint256 penaltyAmount,
		uint256 burnAmount,
		bool claimRewards
	) internal {
		if (onBehalfOf != msg.sender) revert InsufficientPermission();
		_updateReward(onBehalfOf);

		rdntToken.safeTransfer(onBehalfOf, amount);
		if (penaltyAmount > 0) {
			if (burnAmount > 0) {
				rdntToken.safeTransfer(starfleetTreasury, burnAmount);
			}
			rdntToken.safeTransfer(daoTreasury, penaltyAmount - burnAmount);
		}

		if (claimRewards) {
			_getReward(onBehalfOf, rewardTokens);
			lastClaimTime[onBehalfOf] = block.timestamp;
		}

		IPriceProvider(_priceProvider).update();

		emit Withdrawn(onBehalfOf, amount, _balances[onBehalfOf].locked, penaltyAmount, burnAmount, false);
	}

	/**
	 * @notice Withdraw all lockings tokens where the unlock time has passed
	 * @param user address
	 * @param limit limit for looping operation
	 * @return lockAmount withdrawable lock amount
	 * @return lockAmountWithMultiplier withdraw amount with multiplier
	 */
	function _cleanWithdrawableLocks(
		address user,
		uint256 limit
	) internal returns (uint256 lockAmount, uint256 lockAmountWithMultiplier) {
		LockedBalance[] storage locks = _userLocks[user];

		if (locks.length != 0) {
			uint256 length = locks.length <= limit ? locks.length : limit;
			for (uint256 i = 0; i < length; ) {
				if (locks[i].unlockTime <= block.timestamp) {
					lockAmount = lockAmount + locks[i].amount;
					lockAmountWithMultiplier = lockAmountWithMultiplier + (locks[i].amount * locks[i].multiplier);
					locks[i] = locks[locks.length - 1];
					locks.pop();
					length = length - 1;
				} else {
					i = i + 1;
				}
			}
			if (locks.length == 0) {
				emit LockerRemoved(user);
			}
		}
	}

	/**
	 * @notice Withdraw all currently locked tokens where the unlock time has passed.
	 * @param address_ of the user.
	 * @param isRelockAction true if withdraw with relock
	 * @param doTransfer true to transfer tokens to user
	 * @param limit limit for looping operation
	 * @return amount for withdraw
	 */
	function _withdrawExpiredLocksFor(
		address address_,
		bool isRelockAction,
		bool doTransfer,
		uint256 limit
	) internal whenNotPaused returns (uint256 amount) {
		if (isRelockAction && address_ != msg.sender && _lockZap != msg.sender) revert InsufficientPermission();
		_updateReward(address_);

		uint256 amountWithMultiplier;
		Balances storage bal = _balances[address_];
		(amount, amountWithMultiplier) = _cleanWithdrawableLocks(address_, limit);
		bal.locked = bal.locked - amount;
		bal.lockedWithMultiplier = bal.lockedWithMultiplier - amountWithMultiplier;
		bal.total = bal.total - amount;
		lockedSupply = lockedSupply - amount;
		lockedSupplyWithMultiplier = lockedSupplyWithMultiplier - amountWithMultiplier;

		if (isRelockAction || (address_ != msg.sender && !autoRelockDisabled[address_])) {
			_stake(amount, address_, defaultLockIndex[address_], true);
		} else {
			if (doTransfer) {
				IERC20(stakingToken).safeTransfer(address_, amount);
				incentivesController.afterLockUpdate(address_);
				emit Withdrawn(address_, amount, _balances[address_].locked, 0, 0, stakingToken != address(rdntToken));
			} else {
				revert InvalidAction();
			}
		}
		return amount;
	}

	/********************** Internal View functions ***********************/

	/**
	 * @notice Returns withdrawable balance at exact unlock time
	 * @param user address for withdraw
	 * @param unlockTime exact unlock time
	 * @return amount total withdrawable amount
	 * @return penaltyAmount penalty amount
	 * @return burnAmount amount to burn
	 * @return index of earning
	 */
	function _ieeWithdrawableBalance(
		address user,
		uint256 unlockTime
	) internal view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount, uint256 index) {
		uint256 length = _userEarnings[user].length;
		for (index; index < length; ) {
			if (_userEarnings[user][index].unlockTime == unlockTime) {
				(amount, , penaltyAmount, burnAmount) = _penaltyInfo(_userEarnings[user][index]);
				return (amount, penaltyAmount, burnAmount, index);
			}
			unchecked {
				index++;
			}
		}
		revert UnlockTimeNotFound();
	}

	/**
	 * @notice Calculate earnings.
	 * @param user address of earning owner
	 * @param rewardToken address
	 * @param balance of the user
	 * @param currentRewardPerToken current RPT
	 * @return earnings amount
	 */
	function _earned(
		address user,
		address rewardToken,
		uint256 balance,
		uint256 currentRewardPerToken
	) internal view returns (uint256 earnings) {
		earnings = rewards[user][rewardToken];
		uint256 realRPT = currentRewardPerToken - userRewardPerTokenPaid[user][rewardToken];
		earnings = earnings + ((balance * realRPT) / 1e18);
	}

	/**
	 * @notice Penalty information of individual earning
	 * @param earning earning info.
	 * @return amount of available earning.
	 * @return penaltyFactor penalty rate.
	 * @return penaltyAmount amount of penalty.
	 * @return burnAmount amount to burn.
	 */
	function _penaltyInfo(
		LockedBalance memory earning
	) internal view returns (uint256 amount, uint256 penaltyFactor, uint256 penaltyAmount, uint256 burnAmount) {
		if (earning.unlockTime > block.timestamp) {
			// 90% on day 1, decays to 25% on day 90
			penaltyFactor = ((earning.unlockTime - block.timestamp) * HALF) / vestDuration + QUART; // 25% + timeLeft/vestDuration * 65%
			penaltyAmount = (earning.amount * penaltyFactor) / WHOLE;
			burnAmount = (penaltyAmount * burn) / WHOLE;
		}
		amount = earning.amount - penaltyAmount;
	}
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecoverERC20 contract
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
contract RecoverERC20 {
	using SafeERC20 for IERC20;

	/// @notice Emitted when ERC20 token is recovered
	event Recovered(address indexed token, uint256 amount);

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	 */
	function _recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Called by the locking contracts after locking or unlocking happens
	 * @param user The address of the user
	 **/
	function beforeLockUpdate(address user) external;

	/**
	 * @notice Hook for lock update.
	 * @dev Called by the locking contracts after locking or unlocking happens
	 */
	function afterLockUpdate(address _user) external;

	function addPool(address _token, uint256 _allocPoint) external;

	function claim(address _user, address[] calldata _tokens) external;

	function setClaimReceiver(address _user, address _receiver) external;

	function getRegisteredTokens() external view returns (address[] memory);

	function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

	function bountyForUser(address _user) external view returns (uint256 bounty);

	function allPendingRewards(address _user) external view returns (uint256 pending);

	function claimAll(address _user) external;

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function setEligibilityExempt(address _address, bool _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import {IFeeDistribution} from "./IMultiFeeDistribution.sol";

interface IMiddleFeeDistribution is IFeeDistribution {
	function forwardReward(address[] memory _rewardTokens) external;

	function getRdntTokenAddress() external view returns (address);

	function getMultiFeeDistributionAddress() external view returns (address);

	function operationExpenseRatio() external view returns (uint256);

	function operationExpenses() external view returns (address);

	function isRewardToken(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBountyManager {
	function quote(address _param) external returns (uint256 bounty);

	function claim(address _param) external returns (uint256 bounty);

	function minDLPBalance() external view returns (uint256 amt);

	function executeBounty(
		address _user,
		bool _execute,
		uint256 _actionType
	) external returns (uint256 bounty, uint256 actionType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
	function exit(bool claimRewards) external;

	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

	function rdntToken() external view returns (IMintableToken);

	function getPriceProvider() external view returns (address);

	function lockInfo(address user) external view returns (LockedBalance[] memory);

	function autocompoundDisabled(address user) external view returns (bool);

	function defaultLockIndex(address _user) external view returns (uint256);

	function autoRelockDisabled(address user) external view returns (bool);

	function totalBalance(address user) external view returns (uint256);

	function lockedBalance(address user) external view returns (uint256);

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);

	function getBalances(address _user) external view returns (Balances memory);

	function zapVestingToLp(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function userSlippage(address) external view returns (uint256);

	function claimFromConverter(address) external;

	function vestTokens(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 bountyAmt);

	function setAutocompound(bool state, uint256 slippage) external;

	function setUserSlippage(uint256 slippage) external;

	function toggleAutocompound() external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
	function mint(address _receiver, uint256 _amount) external returns (bool);

	function burn(uint256 _amount) external returns (bool);

	function setMinter(address _minter) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IPriceProvider {
	function getTokenPrice() external view returns (uint256);

	function getTokenPriceUsd() external view returns (uint256);

	function getLpTokenPrice() external view returns (uint256);

	function getLpTokenPriceUsd() external view returns (uint256);

	function decimals() external view returns (uint256);

	function update() external;

	function baseAssetChainlinkAdapter() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function removeReward(address _rewardToken) external;
}