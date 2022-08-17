//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ExplorationSettings.sol";
import "../interfaces/IAtlasMine.sol";
contract Exploration is Initializable, ExplorationSettings, ReentrancyGuardUpgradeable {
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	function initialize() external initializer {
		ExplorationSettings.__ExplorationSettings_init();
	}

	function setMinStakingTimeInSeconds(uint256 _minStakingTime) 
		external
		override  
		onlyAdminOrOwner 
	{
		require(_minStakingTime >= 0, "Staking time cannot be negative");
		minStakingTimeInSeconds = _minStakingTime;
	}

	function claimBarns(uint256[] calldata _tokenIds)
		external
		onlyEOA
		whenNotPaused
		contractsAreSet
		nonZeroLength(_tokenIds)
	{
		require(minStakingTimeInSeconds > 0, "Minimum staking time is not defined");
		for(uint256 i = 0; i < _tokenIds.length; i++) {
			require(ownerForStakedDonkey(_tokenIds[i]) == msg.sender, "Exploration: User does not own Donkey");
			//User will only be allowed to claim if donkey is staked
			require(locationForStakedDonkey(_tokenIds[i]) == Location.EXPLORATION, "Exploration: Donkey is not exploring");
			require(isBarnClaimEligible(_tokenIds[i]), "Donkey is not eligible for claim");
			_claimBarn(_tokenIds[i], msg.sender);
		}
	}

	function _claimBarn(uint256 _tokenId, address _to) private {
		uint256 lastStakedTime = tokenToStakeInfo[_tokenId].lastStakedTime;
		require(lastStakedTime > 0, "Exploration: Cannot have last staked time of 0");

		uint256 totalTimeStaked = (block.timestamp - lastStakedTime);

		//Seconds as time unit
		require(totalTimeStaked > minStakingTimeInSeconds, "Exploration: Donkey has not been staked long enough");

		tokenIdToBarnClaimed[_tokenId] = true;

		barn.mint(_to, 1);

		emit ClaimedBarn(_tokenId, _to, block.timestamp);
	}

	function isBarnClaimedForToken(uint256 _tokenId) external view returns(bool) {
		return tokenIdToBarnClaimed[_tokenId];
	}

	function transferDonkeysToExploration(uint256[] calldata _tokenIds)
		external
		whenNotPaused
		contractsAreSet
		onlyEOA
		nonZeroLength(_tokenIds)
	{
		for(uint256 i = 0; i < _tokenIds.length; i++) {
			uint256 _tokenId = _tokenIds[i];
			_requireValidDonkeyAndLocation(_tokenId, Location.EXPLORATION);
			_transferFromLocation(_tokenId);
		}

		emit DonkeyLocationChanged(_tokenIds, msg.sender, Location.EXPLORATION);
	}

	function transferDonkeysOutOfExploration(uint256[] calldata _tokenIds)
		external
		whenNotPaused
		contractsAreSet
		onlyEOA
		nonZeroLength(_tokenIds)
	{	
		for(uint256 i = 0; i < _tokenIds.length; i++) {
			uint256 _tokenId = _tokenIds[i];
			_requireValidDonkeyAndLocation(_tokenId, Location.NOT_STAKED);
			//Cannot transfer out donkeys until all stakes have been removed
			_requireFlywheelUnstakeInvariants();
			_transferFromLocation(_tokenId);
		}
		emit DonkeyLocationChanged(_tokenIds, msg.sender, Location.NOT_STAKED);
	}

	function _transferFromLocation(uint256 _tokenId) private {
		Location _oldLocation = tokenIdToInfo[_tokenId].location;		
		// If old location is exploration, then we want to unstake it
		if(_oldLocation == Location.EXPLORATION) {
			ownerToStakedTokens[msg.sender].remove(_tokenId);
			delete tokenIdToInfo[_tokenId];
			tokenToStakeInfo[_tokenId].lastStakedTime = 0;
			tld.safeTransferFrom(address(this), msg.sender, _tokenId);
			emit StoppedExploring(_tokenId, msg.sender);
		} else if(_oldLocation == Location.NOT_STAKED) {
			ownerToStakedTokens[msg.sender].add(_tokenId);
			tokenIdToInfo[_tokenId].owner = msg.sender;
			tokenIdToInfo[_tokenId].location = Location.EXPLORATION;
			tokenToStakeInfo[_tokenId].lastStakedTime = block.timestamp;
			// Will revert if user doesn't own token.
			tld.safeTransferFrom(msg.sender, address(this), _tokenId);
			emit StartedExploring(_tokenId, msg.sender);
		} else {
			revert("Exploration: Unknown location");
		}
	}

	function _requireValidDonkeyAndLocation(uint256 _tokenId, Location _newLocation) private view {
		Location _oldLocation = tokenIdToInfo[_tokenId].location;
		// Donkey is Exploring
		if(_oldLocation != Location.NOT_STAKED) {
			require(ownerToStakedTokens[msg.sender].contains(_tokenId), "Exploration: Caller does not own Donkey");
		}
		require(_oldLocation != _newLocation, "Exploration: Location must be different");
	}

	function balanceOf(address _owner) external view override returns (uint256) {
		return ownerToStakedTokens[_owner].length();
	}

	function ownerForStakedDonkey(uint256 _tokenId) public view override returns(address) {
		address _owner = tokenIdToInfo[_tokenId].owner;
		require(_owner != address(0), "Exploration: Donkey is not staked");
		return _owner;
	}

	function totalStakedTimeForDonkeyInSec(uint256 _tokenId) internal view returns (uint256) {
		uint256 lastStakedTime = tokenToStakeInfo[_tokenId].lastStakedTime;
		// require(lastStakedTime > 0, "Exploration: Donkey is not staked");
		if (lastStakedTime == 0) {
			return 0;
		}

		return ((tokenIdToStakeTimeInSeconds[_tokenId]) + (block.timestamp - lastStakedTime));
	}

	function locationForStakedDonkey(uint256 _tokenId) public view override returns(Location) {
		return tokenIdToInfo[_tokenId].location;
	}

	function isDonkeyStaked(uint256 _tokenId) public view returns(bool) {
		return tokenIdToInfo[_tokenId].owner != address(0);
	}

	function infoForDonkey(uint256 _tokenId) external view returns(TokenInfo memory) {
		require(isDonkeyStaked(_tokenId), "Exploration: Donkey is not staked");
		return tokenIdToInfo[_tokenId];
	}

	function isBarnClaimEligible(uint256 _tokenId) public view returns(bool) {
		if (minStakingTimeInSeconds <= 0) {
			return false;
		}
		uint256 lastStakedTime = tokenToStakeInfo[_tokenId].lastStakedTime;
		uint256 totalTimeStaked = (block.timestamp - lastStakedTime);
		bool isBarnClaimed =  tokenIdToBarnClaimed[_tokenId];
		return (totalTimeStaked >= minStakingTimeInSeconds) && (lastStakedTime > 0) && !isBarnClaimed;
	}

	function timeStakedForDonkey(uint256 _tokenId) public view returns(uint256) {
		uint256 lastStakedTime = tokenToStakeInfo[_tokenId].lastStakedTime;
		require(lastStakedTime > 0, "Exploration: Donkey is not staked");
		return lastStakedTime;
	}

	// Flywheel
	/**
		Method for donkey holders to deposit funds to Exploration contract.
		Deposits will be compiled daily and sent to Atlas Mine depending
		on lock period.
	*/
	function deposit(uint256 _amount,
	 	LockPeriod _lock, //Using local LockPeriod for testing, TODO: Change to AtlasMine.Lock
		bool _isAutoCom,
		bool _useFW) 
	 	public
		nonReentrant
		onlyDonkeyHolders
		atlasStakerIsSet
		returns (uint256 depositId)
	{
		require(_amount > 0, "FlyWheel: Need to deposit more than 0");
		uint64 currentEpoch = currentEpoch();
		MAGIC.safeTransferFrom(msg.sender, address(this), _amount);
		depositId = numDeposits;
		UserStake memory userStake = UserStake(
			msg.sender,
			depositId,
			currentEpoch,
			_amount,
			_isAutoCom,
			_lock,
			_useFW,
			0,
			true
		);
		stakesByUser[msg.sender].add(depositId);
		stakes[depositId] = userStake;
		allStakesByDay[currentEpoch].add(depositId);
		++numDeposits;
		return depositId;
	}
	/**
		Method that lets users withdraw funds from Exploration.

		Note: Withdrawing from Atlas will be handled differently.
	*/
	function withdraw(uint256[] memory _depositIds) 
		public
		// nonReentrant
		onlyDonkeyHolders
		atlasStakerIsSet
		nonZeroLength(_depositIds)
		returns(uint256 withdrawAmount)
	{
		for (uint256 i = 0; i < _depositIds.length; i++) {
			withdrawAmount += _withdraw(_depositIds[i]);
		}
		return withdrawAmount;
	}

	function _withdraw(uint256 _depositId) internal returns (uint256 amount) {
		require(0 <= _depositId && _depositId <= numDeposits, "FlyWheel: Invalid depositId");
		require(msg.sender == stakes[_depositId].user_, "FlyWheel: User did not make this deposit");
		UserStake memory userStake = stakes[_depositId];
		require(!userStake.isLocked_, "FlyWheel: Cannot withdraw stake");
		uint256 userAmount = userStake.amount_;
		delete stakes[_depositId];
		stakesByUser[msg.sender].remove(_depositId);
		MAGIC.safeTransfer(_msgSender(), userAmount);
		++numWithdrawals;
		return amount;
	}

	function claim(uint256 _depositId) public 
		nonReentrant 
		atlasStakerIsSet
		onlyDonkeyHolders
		returns (uint256 emissionAmount)
	{
		emissionAmount = _claim(_depositId);
	}

	function claimAll() external 
		// nonReentrant
		atlasStakerIsSet
		onlyDonkeyHolders
		returns (uint256 emissionAmount) 
	{
		require(stakesByUser[msg.sender].length() != 0, "FlyWheel: User does not have stakes");
		EnumerableSetUpgradeable.UintSet storage userStakes = stakesByUser[msg.sender];

        for (uint256 i; i < userStakes.length(); i++) {
			emissionAmount += _claim(userStakes.at(i));
        }
		//Emit here
	}

	function _claim(uint256 _depositId) internal returns (uint256 emissionAmount) {
		require(0 <= _depositId && _depositId <= numDeposits, "FlyWheel: Invalid depositId");
		require(msg.sender == stakes[_depositId].user_, "FlyWheel: User did not make this deposit");
		UserStake memory userStake = stakes[_depositId];
		require(msg.sender == userStake.user_, "FlyWheel: User did not stake");
		emissionAmount = userStake.emissionAmount_;
		userStake.emissionAmount_ = 0;
		MAGIC.safeTransfer(_msgSender(), emissionAmount);
		// emit a message 
	}

	function canWithdraw(uint256 _depositId) public view returns(bool withdrawable) {
		ATLAS_STAKER.canWithdraw(_depositId);
	}


	// function retentionLock(uint256 _depositId) public view returns(bool) {
	// 	return ATLAS_STAKER.getVaultStake(_depositId).retentionUnlock;
	// }
	//Keep retentionLock to two weeks
	
	function getCurrentEpoch() public view returns(uint64) {
		return ATLAS_STAKER.currentEpoch();
	}
	
	function getAllowedLocks() public view returns(IAtlasMine.Lock[] memory) {
		return ATLAS_STAKER.getAllowedLocks();
	}

	function getClaimableEmission(uint256 _depositId) public view returns(uint256 emissionAmount) {
		(emissionAmount, ) = ATLAS_STAKER.getClaimableEmission(_depositId); // ? 
	}
	
	function _requireFlywheelUnstakeInvariants() public view {
		require(stakesByUser[msg.sender].length() == 0, "FlyWheel: Cannot have stakes");
	}

	modifier onlyDonkeyHolders() {
		require(isAllowListed(msg.sender), "FlyWheel: User is not a donkey holder");
		_;
	}

	function isAllowListed(address _user) public view returns(bool) {
		return ownerToStakedTokens[_user].length() > 0;
	}


	// // ******* Methods to interact with AtlasMine ******** \\
	// function _getExplorationDailyDeposits() internal 
	// 	onlyAdminOrOwner 
	// 	atlasStakerIsSet	
	// {
	// 	uint256 testingAmount = 0;
	// 	uint256 twoWeeksAmount = 0;
	// 	uint256 oneMonthAmount = 0;
	// 	uint256 threeMonthsAmount = 0; 
	// 	uint256 sixMonthsAmount = 0;
	// 	uint256 twelveMonthsAmount = 0;
	// 	uint64 currentEpoch = currentEpoch();
	// 	EnumerableSetUpgradeable.UintSet storage dailyDepositIds = allStakesByDay[currentEpoch];
	// 	for (uint256 i = 0; i < dailyDepositIds.length(); i++) {
	// 		UserStake memory userStake = stakes[dailyDepositIds.at(i)];
	// 		if (LockPeriod.testing == userStake.lock_) {	
	// 			testingAmount += userStake.amount_;
	// 		} else if (LockPeriod.twoWeeks  == userStake.lock_) {
	// 			twoWeeksAmount += userStake.amount_;
			
	// 		} else if (LockPeriod.oneMonth  == userStake.lock_) {
	// 			oneMonthAmount += userStake.amount_;
				
	// 		} else if (LockPeriod.threeMonths  == userStake.lock_) {
	// 			threeMonthsAmount += userStake.amount_;
				
	// 		} else if (LockPeriod.sixMonths  == userStake.lock_) {
	// 			sixMonthsAmount += userStake.amount_;
				
	// 		} else if (LockPeriod.twelveMonths  == userStake.lock_) {
	// 			twelveMonthsAmount += userStake.amount_;
				
	// 		}
    //     }

	// 	DailyDepositAmounts memory dailyDepositAmounts = DailyDepositAmounts(
	// 		currentEpoch,
	// 		testingAmount,
	// 		twoWeeksAmount,
	// 		oneMonthAmount,
	// 		threeMonthsAmount,
	// 		sixMonthsAmount,
	// 		twelveMonthsAmount
	// 	);
	// 	dailyDeposits[currentEpoch] = dailyDepositAmounts;
	// }

	// //While testing, replace IAtlasMine with LockPeriod local
	// function _depositToAtlas() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner 
	// {
	// 	// Get today's deposits, TODO: Make sure this is the current day and that 
	// 	// Atlas didn't change day
	// 	uint64 current = currentEpoch();
	// 	DailyDepositAmounts memory amounts = dailyDeposits[current];


	// 	//Make sure that its been deposited
	// 	require(amounts.day_ > 0, "FlyWheel: Daily deposits have not been compiled");
	// 	//Make 2 week deposit
	// 	MAGIC.safeApprove(address(ATLAS_STAKER), amounts.twoWeeksAmount_);
    //     uint256 twoWeeksAtlasDepositId = ATLAS_STAKER.deposit(uint256(amounts.twoWeeksAmount_), IAtlasMine.Lock.twoWeeks);
	// 	//Make one month deposit
	// 	MAGIC.safeApprove(address(ATLAS_STAKER), amounts.oneMonthAmount_);
    //     uint256 oneMonthAtlasDepositId = ATLAS_STAKER.deposit(uint256(amounts.oneMonthAmount_), IAtlasMine.Lock.oneMonth);
	// 	//Make three months deposit
	// 	MAGIC.safeApprove(address(ATLAS_STAKER), amounts.threeMonthsAmount_);
    //     uint256 threeMonthsAtlasDepositId = ATLAS_STAKER.deposit(uint256(amounts.threeMonthsAmount_), IAtlasMine.Lock.threeMonths);
	// 	//Make six months deposit
	// 	MAGIC.safeApprove(address(ATLAS_STAKER), amounts.sixMonthsAmount_);
    //     uint256 sixMonthsAtlasDepositId = ATLAS_STAKER.deposit(uint256(amounts.sixMonthsAmount_), IAtlasMine.Lock.sixMonths);
	// 	//Make twelve months deposit
	// 	MAGIC.safeApprove(address(ATLAS_STAKER), amounts.twelveMonthsAmount_);
    //     uint256 twelveMonthsAtlasDepositId = ATLAS_STAKER.deposit(uint256(amounts.twelveMonthsAmount_), IAtlasMine.Lock.twelveMonths);

	// 	EnumerableSetUpgradeable.UintSet storage dailyStakes = allStakesByDay[current];
	// 	EnumerableSetUpgradeable.UintSet storage twoWeeksWithdrawable = dummySet;
	// 	EnumerableSetUpgradeable.UintSet storage oneMonthWithdrawable = dummySet;
	// 	EnumerableSetUpgradeable.UintSet storage threeMonthsWithdrawable = dummySet;
	// 	EnumerableSetUpgradeable.UintSet storage sixMonthsWithdrawable = dummySet;
	// 	EnumerableSetUpgradeable.UintSet storage twelveMonthsWithdrawable = dummySet;
	// 	for (uint256 i = 0; i < dailyStakes.length(); i++) {
	// 		UserStake memory stake = stakes[dailyStakes.at(i)];
	// 		LockPeriod _lock = stake.lock_;
	// 		if (LockPeriod.twoWeeks == _lock) {
	// 			twoWeeksWithdrawable.add(stake.depositId_);
	// 		} else if (LockPeriod.oneMonth == _lock) {
	// 			oneMonthWithdrawable.add(stake.depositId_);
	// 		} else if (LockPeriod.threeMonths == _lock) {
	// 			threeMonthsWithdrawable.add(stake.depositId_);
	// 		} else if (LockPeriod.sixMonths == _lock) {
	// 			sixMonthsWithdrawable.add(stake.depositId_);
	// 		} else if (LockPeriod.twelveMonths == _lock) {
	// 			twelveMonthsWithdrawable.add(stake.depositId_);
	// 		}
	// 	}

	// 	//2 Weeks
	// 	IBattleflyAtlasStakerV02.VaultStake memory vaultStakeOne = ATLAS_STAKER.getVaultStake(twoWeeksAtlasDepositId);
	// 	uint64 unlockAt = vaultStakeOne.unlockAt;

	// 	if (withdrawStakeIds[unlockAt].day_ == unlockAt) {
	// 		DailyWithdrawStakes storage stakes = withdrawStakeIds[unlockAt];
	// 		stakes.twoWeeks_ = twoWeeksWithdrawable;
	// 	} else {
	// 		DailyWithdrawStakes memory stakes = DailyWithdrawStakes(
	// 		unlockAt,
	// 		twoWeeksWithdrawable,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet
	// 		);
	// 		withdrawStakeIds[unlockAt] = stakes;
	// 	}
	// 	if (unlockAtlasDepositIds[unlockAt].day_ == unlockAt) {
	// 		UnlockDateDepositIds memory depositIds = unlockAtlasDepositIds[unlockAt];
	// 		UnlockDateDepositIds.twoWeeksId_ = twoWeeksAtlasDepositId;
	// 	} else {
	// 		UnlockDateDepositIds memory depositIds = UnlockDateDepositIds(
	// 			unlockAt,
	// 			twoWeeksAtlasDepositId,
	// 			0,
	// 			0,
	// 			0,
	// 			0
	// 		);
	// 		unlockAtlasDepositIds[unlockAt] = depositIds;
	// 	}

	// 	//1 Month 
	// 	IBattleflyAtlasStakerV02.VaultStake memory oneMonthStake = ATLAS_STAKER.getVaultStake(oneMonthAtlasDepositId);
	// 	uint64 oneMonthUnlock = oneMonthStake.unlockAt;
	// 	if (withdrawStakeIds[oneMonthUnlock].day_ == oneMonthUnlock) {
	// 		DailyWithdrawStakes memory stakes = withdrawStakeIds[unlockAt];
	// 		stakes.oneMonth_ = oneMonthWithdrawable;
	// 	} else {
	// 		DailyWithdrawStakes memory stakes = DailyWithdrawStakes(
	// 		oneMonthUnlock,
	// 		dummySet,
	// 		oneMonthWithdrawable,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet
	// 		);
	// 		withdrawStakeIds[oneMonthUnlock] = stakes;
	// 	}

	// 	if (unlockAtlasDepositIds[oneMonthUnlock].day_ == oneMonthUnlock) {
	// 		UnlockDateDepositIds memory depositIds = unlockAtlasDepositIds[oneMonthUnlock];
	// 		UnlockDateDepositIds.oneMonthId_ = oneMonthAtlasDepositId;
	// 	} else {
	// 		UnlockDateDepositIds memory depositIds = UnlockDateDepositIds(
	// 			unlockAt,
	// 			0,
	// 			oneMonthAtlasDepositId,
	// 			0,
	// 			0,
	// 			0
	// 		);
	// 		unlockAtlasDepositIds[oneMonthUnlock] = depositIds;
	// 	}


	// 	//3 Months
	// 	IBattleflyAtlasStakerV02.VaultStake memory threeMonthsStake = ATLAS_STAKER.getVaultStake(threeMonthsAtlasDepositId);
	// 	uint64 threeMonthsUnlock = threeMonthsStake.unlockAt;
	// 	if (withdrawStakeIds[threeMonthsUnlock].day_ == threeMonthsUnlock) {
	// 		DailyWithdrawStakes memory stakes = withdrawStakeIds[threeMonthsUnlock];
	// 		stakes.threeMonths_ = threeMonthsWithdrawable;
	// 	} else {
	// 		DailyWithdrawStakes memory stakes = DailyWithdrawStakes(
	// 		threeMonthsUnlock,
	// 		dummySet,
	// 		dummySet,
	// 		threeMonthsWithdrawable,
	// 		dummySet,
	// 		dummySet
	// 		);
	// 		withdrawStakeIds[threeMonthsUnlock] = stakes;
	// 	}

	// 	if (unlockAtlasDepositIds[threeMonthsUnlock].day_ == threeMonthsUnlock) {
	// 		UnlockDateDepositIds memory depositIds = unlockAtlasDepositIds[threeMonthsUnlock];
	// 		UnlockDateDepositIds.threeMonthsId_ = threeMonthsAtlasDepositId;
	// 	} else {
	// 		UnlockDateDepositIds memory depositIds = UnlockDateDepositIds(
	// 			unlockAt,
	// 			0,
	// 			0,
	// 			threeMonthsAtlasDepositId,
	// 			0,
	// 			0
	// 		);
	// 		unlockAtlasDepositIds[threeMonthsUnlock] = depositIds;
	// 	}
	// 	// //6 Months
	// 	IBattleflyAtlasStakerV02.VaultStake memory sixMonthsStake = ATLAS_STAKER.getVaultStake(sixMonthsAtlasDepositId);
	// 	uint64 sixMonthsUnlock = sixMonthsStake.unlockAt;
	// 	if (withdrawStakeIds[sixMonthsStake].day_ == sixMonthsStake) {
	// 		DailyWithdrawStakes memory stakes = withdrawStakeIds[sixMonthsStake];
	// 		stakes.sixMonths_ = sixMonthsWithdrawable;
	// 	} else {
	// 		DailyWithdrawStakes memory stakes = DailyWithdrawStakes(
	// 		sixMonthsStake,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet,
	// 		sixMonthsWithdrawable,
	// 		dummySet
	// 		);
	// 		withdrawStakeIds[sixMonthsUnlock] = stakes;
	// 	}

	// 	if (unlockAtlasDepositIds[sixMonthsUnlock].day_ == sixMonthsUnlock) {
	// 		UnlockDateDepositIds memory depositIds = unlockAtlasDepositIds[sixMonthsUnlock];
	// 		UnlockDateDepositIds.sixMonthsId_ = sixMonthsAtlasDepositId;
	// 	} else {
	// 		UnlockDateDepositIds memory depositIds = UnlockDateDepositIds(
	// 			unlockAt,
	// 			0,
	// 			0,
	// 			0,
	// 			sixMonthsAtlasDepositId,
	// 			0
	// 		);
	// 		unlockAtlasDepositIds[sixMonthsUnlock] = depositIds;
	// 	}

	// 	//12 Months
	// 	IBattleflyAtlasStakerV02.VaultStake memory twelveMonthsStake = ATLAS_STAKER.getVaultStake(twelveMonthsAtlasDepositId);
	// 	uint64 twelveMonthsUnlock = twelveMonthsStake.unlockAt;
	// 	if (withdrawStakeIds[twelveMonthsUnlock].day_ == twelveMonthsUnlock) {
	// 		DailyWithdrawStakes memory stakes = withdrawStakeIds[twelveMonthsUnlock];
	// 		stakes.twelveMonths_ = twelveMonthsWithdrawable;
	// 	} else {
	// 		DailyWithdrawStakes memory stakes = DailyWithdrawStakes(
	// 		twelveMonthsUnlock,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet,
	// 		dummySet,
	// 		twelveMonthsWithdrawable
	// 		);
	// 		withdrawStakeIds[twelveMonthsUnlock] = stakes;
	// 	}

	// 	if (unlockAtlasDepositIds[twelveMonthsUnlock].day_ == twelveMonthsUnlock) {
	// 		UnlockDateDepositIds memory depositIds = unlockAtlasDepositIds[twelveMonthsUnlock];
	// 		UnlockDateDepositIds.twelveMonthsId_ = twelveMonthsAtlasDepositId;
	// 	} else {
	// 		UnlockDateDepositIds memory depositIds = UnlockDateDepositIds(
	// 			unlockAt,
	// 			0,
	// 			0,
	// 			0,
	// 			0,
	// 			twelveMonthsAtlasDepositId
	// 		);
	// 		unlockAtlasDepositIds[twelveMonthsUnlock] = depositIds;
	// 	}


	// 	//Save daily depositIds
	// 	DailyDepositReceipts memory receipt = DailyDepositReceipts(
	// 		current,
	// 		0,
	// 		twoWeeksAtlasDepositId,
	// 		oneMonthAtlasDepositId,
	// 		threeMonthsAtlasDepositId,
	// 		sixMonthsAtlasDepositId,
	// 		twelveMonthsAtlasDepositId
	// 	);

	// 	dailyReceipts[current] = receipt;



	// 	//Emit event

	// 	//Create withdraw map
	// }

	// function _createWithdrawMapping(uint64 _epoch, DailyDepositReceipts memory _receipt) private 
	// 	atlasStakerIsSet
	// {
	
	// 	//2 Weeks 
	// 	IBattleflyAtlasStakerV02.VaultStake memory vaultStake = ATLAS_STAKER.getVaultStake(_receipt.twoWeeksDepositId_);
	// 	uint64 unlockAt = vaultStake.unlockAt;
	// 	uint256 amount = vaultStake.amount;
	// 	if (withdrawMap[unlockAt].day_ == unlockAt) {
	// 		//Exists
	// 		DailyDepositWithdrawEpoch memory dayEpoch = withdrawMap[unlockAt];
	// 		dayEpoch.twoWeeksAmount_ += amount;
	// 	} else {
	// 		DailyDepositWithdrawEpoch memory dayEpoch = DailyDepositWithdrawEpoch(
	// 		_epoch,
	// 		0,
	// 		amount,
	// 		0,
	// 		0,
	// 		0,
	// 		0
	// 		);
	// 		withdrawMap[unlockAt] = dayEpoch;
	// 	}

	// 	//1 month
	// 	IBattleflyAtlasStakerV02.VaultStake memory oneMonthStake = ATLAS_STAKER.getVaultStake(_receipt.oneMonthDepositId_);
	// 	uint64 oneMonthUnlock = oneMonthStake.unlockAt;
	// 	uint256 oneMonthAmount = oneMonthStake.amount;
	// 	if (withdrawMap[oneMonthUnlock].day_ == oneMonthUnlock) {
	// 		//Exists
	// 		DailyDepositWithdrawEpoch memory dayEpoch = withdrawMap[oneMonthUnlock];
	// 		dayEpoch.oneMonthAmount_ += oneMonthAmount;
	// 	} else {
	// 		DailyDepositWithdrawEpoch memory dayEpoch = DailyDepositWithdrawEpoch(
	// 		_epoch,
	// 		0,
	// 		0,
	// 		oneMonthAmount,
	// 		0,
	// 		0,
	// 		0
	// 		);
	// 		withdrawMap[oneMonthUnlock] = dayEpoch;
	// 	}
	// 	//3 months
	// 	IBattleflyAtlasStakerV02.VaultStake memory threeMonthsStake = ATLAS_STAKER.getVaultStake(_receipt.threeMonthsDepositId_);
	// 	uint64 threeMonthsUnlock = threeMonthsStake.unlockAt;
	// 	uint256 threeMonthsAmount = threeMonthsStake.amount;
	// 	if (withdrawMap[threeMonthsUnlock].day_ == threeMonthsUnlock) {
	// 		//Exists
	// 		DailyDepositWithdrawEpoch memory dayEpoch = withdrawMap[threeMonthsUnlock];
	// 		dayEpoch.threeMonthsAmount_ += threeMonthsAmount;
	// 	} else {
	// 		DailyDepositWithdrawEpoch memory dayEpoch = DailyDepositWithdrawEpoch(
	// 		_epoch,
	// 		0,
	// 		0,
	// 		0,
	// 		threeMonthsAmount,
	// 		0,
	// 		0
	// 		);
	// 		withdrawMap[threeMonthsUnlock] = dayEpoch;
	// 	}
	// 	//6 months
	// 	IBattleflyAtlasStakerV02.VaultStake memory sixMonthsStake = ATLAS_STAKER.getVaultStake(_receipt.sixMonthsDepositId_);
	// 	uint64 sixMonthsUnlock = sixMonthsStake.unlockAt;
	// 	uint256 sixMonthsAmount = sixMonthsStake.amount;
	// 	if (withdrawMap[sixMonthsUnlock].day_ == sixMonthsUnlock) {
	// 		//Exists
	// 		DailyDepositWithdrawEpoch memory dayEpoch = withdrawMap[sixMonthsUnlock];
	// 		dayEpoch.sixMonthsAmount_ += sixMonthsAmount;
	// 	} else {
	// 		DailyDepositWithdrawEpoch memory dayEpoch = DailyDepositWithdrawEpoch(
	// 		_epoch,
	// 		0,
	// 		0,
	// 		0,
	// 		0,
	// 		sixMonthsAmount,
	// 		0
	// 		);
	// 		withdrawMap[sixMonthsUnlock] = dayEpoch;
	// 	}
	// 	//12 months
	// 	IBattleflyAtlasStakerV02.VaultStake memory twelveMonthsStake = ATLAS_STAKER.getVaultStake(_receipt.twelveMonthsDepositId_);
	// 	uint64 twelveMonthsUnlock = twelveMonthsStake.unlockAt;
	// 	uint256 twelveMonthsAmount = twelveMonthsStake.amount;
	// 	if (withdrawMap[twelveMonthsUnlock].day_ == twelveMonthsUnlock) {
	// 		//Exists
	// 		DailyDepositWithdrawEpoch memory dayEpoch = withdrawMap[twelveMonthsUnlock];
	// 		dayEpoch.twelveMonthsAmount_ += twelveMonthsAmount;
	// 	} else {
	// 		DailyDepositWithdrawEpoch memory dayEpoch = DailyDepositWithdrawEpoch(
	// 		_epoch,
	// 		0,
	// 		0,
	// 		0,
	// 		0,
	// 		0,
	// 		twelveMonthsAmount
	// 		);
	// 		withdrawMap[twelveMonthsUnlock] = dayEpoch;
	// 	}
	// }
	// /**
	// 	Method to withdraw from Atlas. 
	// 	We will withdraw from Atlas each day in order to let users withdraw from Exploration
	// 	Users will have a window where they can withdraw funds
	// 	For the stakes that are autocompounded, they will be deposited into Atlas as a new deposit
	// 	For the stakes that aren't, will be kept in Exploration - ready to be withdrawn wheneever 
	// 	the user decides.
	// */
	// function _withdrawFromAtlasTwoWeeks() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage twoWeekDeposits = withdrawStakeIds.twoWeeks_;
	// 	uint256 depositId = atlasDepositIds.twoWeeksId_;
	// 	if (canWithdraw(depositId)) {
	// 		uint256 atlasTwoWeekAmount = ATLAS_STAKER.withdraw(depositId);
	// 		for (uint256 i = 0; i < twoWeekDeposits.length(); i++) {
	// 			UserStake memory userStake = stakes[twoWeekDeposits.at(i)];
	// 			if (userStake.isAutoCompounded_) {
	// 				//Create a new stake
	// 				uint256 currDepositId = numDeposits;
	// 				UserStake memory newStake = UserStake(
	// 					userStake.user_,
	// 					currDepositId,
	// 					currentEpoch,
	// 					userStake.amount_,
	// 					userStake.isAutoCompounded_,
	// 					userStake.lock_,
	// 					userStake.isFW_,
	// 					userStake.emissionAmount_,
	// 					true
	// 				);
	// 				stakesByUser[userStake.user_].add(currDepositId);
	// 				stakes[currDepositId] = newStake;
	// 				allStakesByDay[currentEpoch()].add(currDepositId);
	// 				++numDeposits;
	// 				delete stakes[userStake.depositId_];
	// 				stakesByUser[newStake.user_].remove(userStake.depositId_);
	// 			} else {
	// 				// withdrawableFunds[userStake.user_] = userStake.amount_;
	// 				userStake.isLocked_ = false;
	// 			}
	// 			stakesByUser[userStake.user_].remove(userStake.depositId_);
	// 			delete stakes[userStake.depositId_];
	// 			atlasTwoWeekAmount -= userStake.amount_;
	// 		}
	// 	}
		
	// }

	// function _withdrawFromAtlasOneMonth() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage oneMonthDeposits = withdrawStakeIds.oneMonth_;
	// 	uint256 depositId = atlasDepositIds.oneMonthId_;
	// 	if (canWithdraw(depositId)) {
	// 		uint256 atlasOneMonthAmount = ATLAS_STAKER.withdraw(depositId);
	// 		for (uint256 i = 0; i < oneMonthDeposits.length(); i++) {
	// 			UserStake memory userStake = stakes[oneMonthDeposits.at(i)];
	// 			if (userStake.isAutoCompounded_) {
	// 				//Create a new stake
	// 				uint256 currDepositId = numDeposits;
	// 				UserStake memory newStake = UserStake(
	// 					userStake.user_,
	// 					currDepositId,
	// 					currentEpoch,
	// 					userStake.amount_,
	// 					userStake.isAutoCompounded_,
	// 					userStake.lock_,
	// 					userStake.isFW_,
	// 					userStake.emissionAmount_,
	// 					true
	// 				);
	// 				stakesByUser[userStake.user_].add(currDepositId);
	// 				stakes[currDepositId] = newStake;
	// 				allStakesByDay[currentEpoch()].add(currDepositId);
	// 				++numDeposits;
	// 				delete stakes[userStake.depositId_];
	// 				stakesByUser[newStake.user_].remove(userStake.depositId_);
	// 			} else {
	// 				// withdrawableFunds[userStake.user_] = userStake.amount_;
	// 				userStake.isLocked_ = false;
	// 			}
	// 			stakesByUser[userStake.user_].remove(userStake.depositId_);
	// 			delete stakes[userStake.depositId_];
	// 			atlasOneMonthAmount -= userStake.amount_;
	// 		}
	// 	}
	// }

	// function _withdrawFromAtlasThreeMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage threeMonthsDeposits = withdrawStakeIds.threeMonths_;
	// 	uint256 depositId = atlasDepositIds.threeMonthsId_;
	// 	if (canWithdraw(depositId)) {
	// 		uint256 atlasThreeMonthsAmount = ATLAS_STAKER.withdraw(depositId);
	// 		for (uint256 i = 0; i < threeMonthsDeposits.length(); i++) {
	// 			UserStake memory userStake = stakes[threeMonthsDeposits.at(i)];
	// 			if (userStake.isAutoCompounded_) {
	// 				//Create a new stake
	// 				uint256 currDepositId = numDeposits;
	// 				UserStake memory newStake = UserStake(
	// 					userStake.user_,
	// 					currDepositId,
	// 					currentEpoch,
	// 					userStake.amount_,
	// 					userStake.isAutoCompounded_,
	// 					userStake.lock_,
	// 					userStake.isFW_,
	// 					userStake.emissionAmount_,
	// 					true
	// 				);
	// 				stakesByUser[userStake.user_].add(currDepositId);
	// 				stakes[currDepositId] = newStake;
	// 				allStakesByDay[currentEpoch()].add(currDepositId);
	// 				++numDeposits;
	// 				delete stakes[userStake.depositId_];
	// 				stakesByUser[newStake.user_].remove(userStake.depositId_);
	// 			} else {
	// 				// withdrawableFunds[userStake.user_] = userStake.amount_;
	// 				userStake.isLocked_ = false;
	// 			}
	// 			stakesByUser[userStake.user_].remove(userStake.depositId_);
	// 			delete stakes[userStake.depositId_];
	// 			atlasThreeMonthsAmount -= userStake.amount_;
	// 		}
	// 	}
	// }

	// function _withdrawFromAtlasSixMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage sixMonthsDeposits = withdrawStakeIds.sixMonths_;
	// 	uint256 depositId = atlasDepositIds.sixMonthsId_;
	// 	if (canWithdraw(depositId)) {
	// 		uint256 atlasSixMonthsAmount = ATLAS_STAKER.withdraw(depositId);
	// 		for (uint256 i = 0; i < sixMonthsDeposits.length(); i++) {
	// 			UserStake memory userStake = stakes[sixMonthsDeposits.at(i)];
	// 			if (userStake.isAutoCompounded_) {
	// 				//Create a new stake
	// 				uint256 currDepositId = numDeposits;
	// 				UserStake memory newStake = UserStake(
	// 					userStake.user_,
	// 					currDepositId,
	// 					currentEpoch,
	// 					userStake.amount_,
	// 					userStake.isAutoCompounded_,
	// 					userStake.lock_,
	// 					userStake.isFW_,
	// 					userStake.emissionAmount_,
	// 					true
	// 				);
	// 				stakesByUser[userStake.user_].add(currDepositId);
	// 				stakes[currDepositId] = newStake;
	// 				allStakesByDay[currentEpoch()].add(currDepositId);
	// 				++numDeposits;
	// 				delete stakes[userStake.depositId_];
	// 				stakesByUser[newStake.user_].remove(userStake.depositId_);
	// 			} else {
	// 				// withdrawableFunds[userStake.user_] = userStake.amount_;
	// 				userStake.isLocked_ = false;
	// 			}
	// 			stakesByUser[userStake.user_].remove(userStake.depositId_);
	// 			delete stakes[userStake.depositId_];
	// 			atlasSixMonthsAmount -= userStake.amount_;
	// 		}
	// 	}
	// }

	// function _withdrawFromAtlasTwelveMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage twelveMonthsDeposits = withdrawStakeIds.twelveMonths_;
	// 	uint256 depositId = atlasDepositIds.twelveMonthsId_;
	// 	if (canWithdraw(depositId)) {
	// 		uint256 atlasTwelveMonthsAmount = ATLAS_STAKER.withdraw(depositId);
	// 		for (uint256 i = 0; i < twelveMonthsDeposits.length(); i++) {
	// 			UserStake memory userStake = stakes[twelveMonthsDeposits.at(i)];
	// 			if (userStake.isAutoCompounded_) {
	// 				//Create a new stake
	// 				uint256 currDepositId = numDeposits;
	// 				UserStake memory newStake = UserStake(
	// 					userStake.user_,
	// 					currDepositId,
	// 					currentEpoch,
	// 					userStake.amount_,
	// 					userStake.isAutoCompounded_,
	// 					userStake.lock_,
	// 					userStake.isFW_,
	// 					userStake.emissionAmount_,
	// 					true
	// 				);
	// 				stakesByUser[userStake.user_].add(currDepositId);
	// 				stakes[currDepositId] = newStake;
	// 				allStakesByDay[currentEpoch()].add(currDepositId);
	// 				++numDeposits;
	// 				delete stakes[userStake.depositId_];
	// 				stakesByUser[newStake.user_].remove(userStake.depositId_);
	// 			} else {
	// 				// withdrawableFunds[userStake.user_] = userStake.amount_;
	// 				userStake.isLocked_ = false;
	// 			}
	// 			stakesByUser[userStake.user_].remove(userStake.depositId_);
	// 			delete stakes[userStake.depositId_];
	// 			atlasTwelveMonthsAmount -= userStake.amount_;
	// 		}
	// 	}
	// }
	
	// function _withdrawFromAtlas() external
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	//TODO: Before finishing withdraws, get emissions
	// 	_withdrawFromAtlasTwoWeeks();
	// 	_withdrawFromAtlasOneMonth();
	// 	_withdrawFromAtlasThreeMonths();
	// 	_withdrawFromAtlasSixMonths();
	// 	_withdrawFromAtlasTwelveMonths();
	// }

	// function _claimEmissionsFromAtlasTwoWeeks() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// 	returns(uint256 emission)
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.twoWeeks_;
	// 	uint256 depositId = atlasDepositIds.twoWeeksId_;

	// 	emission = ATLAS_STAKER.claim(depositId);
	// }

	// function _claimEmissionsFromAtlasOneMonth() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// 	returns(uint256 emission)
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.oneMonth_;
	// 	uint256 depositId = atlasDepositIds.oneMonthId_;

	// 	emission = ATLAS_STAKER.claim(depositId);
	// }

	// function _claimEmissionsFromAtlasThreeMonths() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// 	returns(uint256 emission)
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.threeMonths_;
	// 	uint256 depositId = atlasDepositIds.threeMonthsId_;

	// 	emission = ATLAS_STAKER.claim(depositId);
	// }

	// function _claimEmissionsFromAtlasSixMonths() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// 	returns(uint256 emission)
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.sixMonths_;
	// 	uint256 depositId = atlasDepositIds.sixMonthsId_;

	// 	emission = ATLAS_STAKER.claim(depositId);
	// }

	// function _claimEmissionsFromAtlasTwelveMonths() internal
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// 	returns(uint256 emission)
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	UnlockDateDepositIds memory atlasDepositIds = unlockAtlasDepositIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.twelveMonths_;
	// 	uint256 depositId = atlasDepositIds.twelveMonthsId_;

	// 	emission = ATLAS_STAKER.claim(depositId);
	// }

	// function _claimEmissionsFromAtlas() external 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyEmissions memory dailyEmission = DailyEmissions(
	// 		block.timestamp,
	// 		0,
	// 		_claimEmissionsFromAtlasTwoWeeks(),
	// 		_claimEmissionsFromAtlasOneMonth(),
	// 		_claimEmissionsFromAtlasThreeMonths(),
	// 		_claimEmissionsFromAtlasSixMonths(),
	// 		_claimEmissionsFromAtlasTwelveMonths()
	// 	);

	// 	dailyEmissions[currentEpoch] = dailyEmission;
	// }

	// function _distributeDailyEmissionsTwoWeeks() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {	
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.twoWeeks_;
	// 	DailyEmissions memory emissions = dailyEmissions[currentEpoch];
	// 	uint256 emission = emissions.twoWeeksAmount_;
	// 	uint256 amount = withdrawMap[currentEpoch].twoWeeksAmount_;
	// 	for (uint256 i = 0; i < deposits.length(); i++) {
	// 		UserStake memory userStake = stakes[deposits.at(i)];
	// 		uint256 userEmission = (userStake.amount_ / amount) * emission;
	// 		userStake.emissionAmount_ = userEmission;
	// 	}
	// }

	// function _distributeDailyEmissionsOneMonth() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {	
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.oneMonth_;
	// 	DailyEmissions memory emissions = dailyEmissions[currentEpoch];
	// 	uint256 emission = emissions.oneMonthAmount_;
	// 	uint256 amount = withdrawMap[currentEpoch].oneMonthAmount_;
	// 	for (uint256 i = 0; i < deposits.length(); i++) {
	// 		UserStake memory userStake = stakes[deposits.at(i)];
	// 		uint256 userEmission = (userStake.amount_ / amount) * emission;
	// 		userStake.emissionAmount_ = userEmission;
	// 	}
	// }
	
	// function _distributeDailyEmissionsThreeMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {	
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.threeMonths_;
	// 	DailyEmissions memory emissions = dailyEmissions[currentEpoch];
	// 	uint256 emission = emissions.threeMonthsAmount_;
	// 	uint256 amount = withdrawMap[currentEpoch].threeMonthsAmount_;
	// 	for (uint256 i = 0; i < deposits.length(); i++) {
	// 		UserStake memory userStake = stakes[deposits.at(i)];
	// 		uint256 userEmission = (userStake.amount_ / amount) * emission;
	// 		userStake.emissionAmount_ = userEmission;
	// 	}
	// }

	// function _distributeDailyEmissionsSixMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {	
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.sixMonths_;
	// 	DailyEmissions memory emissions = dailyEmissions[currentEpoch];
	// 	uint256 emission = emissions.sixMonthsAmount_;
	// 	uint256 amount = withdrawMap[currentEpoch].sixMonthsAmount_;
	// 	for (uint256 i = 0; i < deposits.length(); i++) {
	// 		UserStake memory userStake = stakes[deposits.at(i)];
	// 		uint256 userEmission = (userStake.amount_ / amount) * emission;
	// 		userStake.emissionAmount_ = userEmission;
	// 	}
	// }

	// function _distributeDailyEmissionsTwelveMonths() internal 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {	
	// 	uint64 currentEpoch = currentEpoch();
	// 	DailyWithdrawStakes memory stakes = withdrawStakeIds[currentEpoch];
	// 	EnumerableSetUpgradeable.UintSet storage deposits = stakes.twelveMonths_;
	// 	DailyEmissions memory emissions = dailyEmissions[currentEpoch];
	// 	uint256 emission = emissions.twelveMonthsAmount_;
	// 	uint256 amount = withdrawMap[currentEpoch].twelveMonthsAmount_;
	// 	for (uint256 i = 0; i < deposits.length(); i++) {
	// 		UserStake memory userStake = stakes[deposits.at(i)];
	// 		uint256 userEmission = (userStake.amount_ / amount) * emission;
	// 		userStake.emissionAmount_ = userEmission;
	// 	}
	// }

	// function _distributeDailyEmissions() external 
	// 	atlasStakerIsSet
	// 	onlyAdminOrOwner
	// {
	// 	_distributeDailyEmissionsTwoWeeks();
	// 	_distributeDailyEmissionsOneMonth();
	// 	_distributeDailyEmissionsThreeMonths();
	// 	_distributeDailyEmissionsSixMonths();
	// 	_distributeDailyEmissionsTwelveMonths();
	// }

	function currentEpoch() internal view returns (uint64 epoch) {
		return ATLAS_STAKER.currentEpoch();
	}

	// //TODO: Update to AtlasMine.Lock after testing
	// function _getLockPeriodEpoch(LockPeriod _lock) internal returns(uint256 lockEpoch) {
	// 	if (LockPeriod.testing == _lock) {	
	// 		return 300; //5 minutes
	// 	} else if (LockPeriod.twoWeeks == _lock) {
	// 		return oneWeek * 2;
	// 	} else if (LockPeriod.oneMonth == _lock) {
	// 		return oneWeek * 4;
	// 	} else if (LockPeriod.threeMonths == _lock) {
	// 		return oneWeek * 12;
	// 	} else if (LockPeriod.sixMonths == _lock) {
	// 		return oneWeek * 24;
	// 	} else if (LockPeriod.twelveMonths == _lock) {
	// 		return oneWeek * 52;
	// 	} else {
	// 		return oneWeek * 60;
	// 	}
	// }
	
	// function initialLock(uint256 _depositId) public
	// 	view
	// 	returns(uint64)
	// {
	// 	return ATLAS_STAKER.getVaultStake(_depositId).unlockAt;
	// }

	// function _getReceiptForLockPeriod(LockPeriod _lock, DailyDepositReceipts memory _receipt) internal returns(uint256 depositId) {
	// 	if (LockPeriod.twoWeeks == _lock) {
	// 		return _receipt.twoWeeksDepositId_;
	// 	} else if (LockPeriod.oneMonth == _lock) {
	// 		return _receipt.oneMonthDepositId_;
	// 	} else if (LockPeriod.threeMonths == _lock) {
	// 		return _receipt.threeMonthsDepositId_;
	// 	} else if (LockPeriod.sixMonths == _lock) {
	// 		return _receipt.sixMonthsDepositId_;
	// 	} else if (LockPeriod.twelveMonths == _lock) {
	// 		return _receipt.twelveMonthsDepositId_;
	// 	}
	// }
	// function autoCompoundEmissions()
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ExplorationContracts.sol";

abstract contract ExplorationSettings is Initializable, ExplorationContracts {

	function __ExplorationSettings_init() internal initializer {
		ExplorationContracts.__ExplorationContracts_init();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(address user, uint256 depositId)
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.2;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ExplorationState.sol";

abstract contract ExplorationContracts is Initializable, ExplorationState {
	
	function __ExplorationContracts_init() internal initializer {
		ExplorationState.__ExplorationState_init();
	}

	function setContracts(address _tldAddress, address _barnAddress)
		external
		onlyAdminOrOwner
	{
		tld = IERC721Upgradeable(_tldAddress);
		barn = IBarn(_barnAddress);
	}

	modifier contractsAreSet() {
		require(areContractsSet(), "Exploration: Contracts aren't set");
		_;
	}

	function areContractsSet() public view returns(bool) {
		return address(tld) != address(0)
			&& address(barn) != address(0);
	}

	function setAtlasStaker(address _atlasStaker) 
		external
		onlyAdminOrOwner
	{
		ATLAS_STAKER = IBattleflyAtlasStakerV02(_atlasStaker);
	}

	function isAtlasStakerSet() public view returns(bool) {
		return address(ATLAS_STAKER) != address(0);
	}

	modifier atlasStakerIsSet() {
		require(isAtlasStakerSet(), "FlyWheel: Atlas Staker not set");
		_;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../interfaces/IExploration.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../shared/AdminableUpgradeable.sol";
import "../interfaces/IBarn.sol";
import "../interfaces/IAtlasMine.sol";
import "../interfaces/IBattleflyAtlasStakerV02.sol";

abstract contract ExplorationState is Initializable, IExploration, ERC721HolderUpgradeable, AdminableUpgradeable {
	event StartedExploring(uint256 _tokenId, address _owner);
	event ClaimedBarn(uint256 _tokenId, address _owner, uint256 _timestamp);
	event StoppedExploring(uint256 _tokenId, address _owner);
	event DonkeyLocationChanged(uint256[] _tokenIds, address _owner, Location _newLocation);
	using SafeERC20Upgradeable for IERC20Upgradeable;

	IERC721Upgradeable public tld;
	IBarn public barn;
	
	mapping(uint256 => bool) tokenIdToBarnClaimed;
	mapping(uint256 => StakeInfo) tokenToStakeInfo;
	mapping(uint256 => uint256) tokenIdToStakeTimeInSeconds;
	uint256 public minStakingTimeInSeconds;
	mapping(uint256 => TokenInfo) internal tokenIdToInfo;
	mapping(address => EnumerableSetUpgradeable.UintSet) internal ownerToStakedTokens;

	//FlyWheel
	IERC20Upgradeable public MAGIC;
	mapping(address => EnumerableSetUpgradeable.UintSet) internal stakesByUser;
	mapping(uint256 => UserStake) internal stakes;
	mapping(uint64 => EnumerableSetUpgradeable.UintSet) internal allStakesByDay;
	mapping(address => uint256) internal withdrawableFunds;

	//Atlas 
	mapping(uint64 => DailyDepositAmounts) internal dailyDeposits;
	mapping(uint64 => DailyDepositReceipts) internal dailyReceipts;
	mapping(uint64 => DailyEmissions) internal dailyEmissions;
	EnumerableSetUpgradeable.UintSet internal dailyDepositIds;
	IBattleflyAtlasStakerV02 public ATLAS_STAKER;
	mapping(uint64 => DailyDepositWithdrawEpoch) internal withdrawMap;
	mapping(uint64 => DailyWithdrawStakes) internal withdrawStakeIds;
	EnumerableSetUpgradeable.UintSet internal dummySet;
	mapping(uint64 => UnlockDateDepositIds) internal unlockAtlasDepositIds;
	uint256 internal numDeposits;
	uint256 internal numWithdrawals;
	// uint256 oneWeek = 604800;
	event ExplorationDeposit(address _user, uint256 _amount, uint256 _depositId, LockPeriod _lock);
	event ExplorationWithdraw(address _user, uint256 _amount, uint256 _depositId);
	event ExplorationClaim(address _user, uint256 _amount, uint256 _depositId, LockPeriod _lock);
	event ExplorationEmission(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);
	event AtlasDepositAmounts(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);
	event AtlasDepositIds(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);
	event AtlasWithdrawAmounts(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);
	event AtlasWithdrawIds(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);
	event AtlasClaim(uint64 _day, uint256 _timeStamp, uint256 _twoWeeks, uint256 _oneMonth, uint256 _threeMonths, uint256 _sixMonths, uint256 _twelveMonths);

	function __ExplorationState_init() internal initializer {
		AdminableUpgradeable.__Adminable_init();
		ERC721HolderUpgradeable.__ERC721Holder_init();
	}
}

struct StakeInfo {
	address owner;
	uint256 lastStakedTime;
}

struct TokenInfo {
	address owner;
	Location location;
}

// Expands on StakeInfo, can replace StakeInfo in mainnet implementation
struct DonkeyStakeInfo {
	address owner;
	bool isStaked;
	uint256 totalStakedTime;
	uint256 lastStakedTime;
}

/**
	Flywheel
	Requirements:
	- Is user allowed to deposit to contract
	- Can user withdraw funds from the contract 
	- How much does a user have staked
	- What are the total transactions that have taken placed
	- User has to have all funds withdrawn in order to unstake all donkeys
	- Check if user is allowed to withdraw 
	- Check if user can claim
	- Autocompound emissions and withdraws

	- Transaction
	- UserStake
	- Withdraw
	- Deposit
	- Atlas methods
 */
//TODO: Think about if its worth having withdraw date map
struct UserStake {
	address user_;
	uint256 depositId_;
	uint64 lockedAt_;
	uint256 amount_;
	bool isAutoCompounded_;
	LockPeriod lock_; //TODO: Change back to AtlasMine.Lock
	bool isFW_;
	uint256 emissionAmount_;
	bool isLocked_;
 }

struct DailyDepositAmounts {
	uint64 day_;
	uint256 testingAmount_;
	uint256 twoWeeksAmount_;
	uint256 oneMonthAmount_;
	uint256 threeMonthsAmount_;
	uint256 sixMonthsAmount_;
	uint256 twelveMonthsAmount_;
}

struct DailyWithdrawStakes {
	uint64 day_;
	EnumerableSetUpgradeable.UintSet twoWeeks_;
	EnumerableSetUpgradeable.UintSet oneMonth_;
	EnumerableSetUpgradeable.UintSet threeMonths_;
	EnumerableSetUpgradeable.UintSet sixMonths_;
	EnumerableSetUpgradeable.UintSet twelveMonths_;
}

struct DailyDepositWithdrawEpoch {
	uint64 day_;
	uint256 testingAmount_;
	uint256 twoWeeksAmount_;
	uint256 oneMonthAmount_;
	uint256 threeMonthsAmount_;
	uint256 sixMonthsAmount_;
	uint256 twelveMonthsAmount_;
}

struct DailyDepositReceipts {
	uint64 day_;
	uint256 testingDepositId_;
	uint256 twoWeeksDepositId_;
	uint256 oneMonthDepositId_;
	uint256 threeMonthsDepositId_;
	uint256 sixMonthsDepositId_;
	uint256 twelveMonthsDepositId_;
}

struct UnlockDateDepositIds {
	uint64 day_;
	uint256 twoWeeksId_;
	uint256 oneMonthId_;
	uint256 threeMonthsId_;
	uint256 sixMonthsId_;
	uint256 twelveMonthsId_;
}

struct DailyEmissions {
	uint256 day_;
	uint256 testingAmount_;
	uint256 twoWeeksAmount_;
	uint256 oneMonthAmount_;
	uint256 threeMonthsAmount_;
	uint256 sixMonthsAmount_;
	uint256 twelveMonthsAmount_;
}

enum LockPeriod {
	testing,
	twoWeeks,
	oneMonth,
	threeMonths,
	sixMonths,
	twelveMonths
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IExploration {

	// Returns minimum staking time in seconds
	function setMinStakingTimeInSeconds(uint256 _minStakingTime) external;

	// Returns address of owner if donkey is staked
	function ownerForStakedDonkey(uint256 _tokenId) external view returns(address);

	// Returns location for donkey
	function locationForStakedDonkey(uint256 _tokenId) external view returns(Location);

	// Total number of staked donkeys for address
	function balanceOf(address _owner) external view returns (uint256);
}

enum Location {
	NOT_STAKED,
	EXPLORATION
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBarn {

	function mint(address _to, uint256 _amount) external;

    function setMaxSupply(uint256 _maxSupply) external;

    function adminSafeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./IAtlasMine.sol";

interface IBattleflyAtlasStakerV02 {
    struct Vault {
        uint16 fee;
        uint16 claimRate;
        bool enabled;
    }

    struct VaultStake {
        uint64 lockAt;
        uint64 unlockAt;
        uint64 retentionUnlock;
        uint256 amount;
        uint256 paidEmission;
        address vault;
        IAtlasMine.Lock lock;
    }

    function deposit(uint256, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function claim(uint256) external returns (uint256);

    function requestWithdrawal(uint256) external returns (uint64);

    function currentDepositId() external view returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getVaultStake(uint256) external view returns (VaultStake memory);

    function getClaimableEmission(uint256) external view returns (uint256, uint256);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function currentEpoch() external view returns (uint64 epoch);

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC165Upgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */ //Cannot be called by another contract
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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