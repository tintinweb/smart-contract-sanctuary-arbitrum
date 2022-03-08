// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import { IAddressProvider } from "./interfaces/IAddressProvider.sol";
import { IOracleMaster } from "./interfaces/IOracleMaster.sol";
import "./CoreStorage.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title HedgeCore Upgradable Contract for `gohm`
 * @author Entropyfi
 * @notice Main Core contract for `Soft Hedge & Leverage` protocol
 * - Users(EOA or WhitelistedContracts) can:
 *   # deposit
 *   # withdraw
 *   # swap
 *   # sponsor & sponsorWithdraw
 */
contract Core is ICore, Initializable, UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, CoreStorageV1 {
	using SafeERC20 for IERC20;

	modifier hedgeCoreAllowed() {
		require(hedgeCoreStatus(), "HC: LOCKED");
		_;
	}

	/**
	 * @dev initialize function for upgradable contract
	 * @param name_ name of this contract
	 * @param addressProvider_ addressProvider
	 * @param wToken_ wrapped token (gohm)
	 */
	function initialize(
		string memory name_,
		address addressProvider_,
		address wToken_
	) public initializer {
		// 1. param checks
		require(bytes(name_).length != 0, "HC:STR MTY!");
		require(IAddressProvider(addressProvider_).getDAO() != address(0), "HT:AP INV");
		require(IERC20(wToken_).totalSupply() > 0, "HC:G INV");

		// 2. inheritance contract init
		__UUPSUpgradeable_init();
		__Pausable_init();
		__ReentrancyGuard_init();

		// 3. assign parameters
		name = name_;
		addressProvider = IAddressProvider(addressProvider_);
		wToken = IERC20(wToken_);

		// 4. other init
		/// 4.1 for `withdrawAllWhenPaused`
		withdrawAllPaused = true;
		/// 4.2 restricted period. defualt is 4 hours (can be modified no bigger than 8hours)
		resctrictedPeriod = 14400;
		/// 4.3 price ratio (RATIO_PRECISION = 1E5, default is 10%)
		isPriceRatioUp = true;
		priceRatio = 10000;
		/// 4.4 min single side deposit amount
		minSingleSideDepositAmount = 1;
	}

	/**
	 * @dev [onlyDAO] we init critical settings and variables for rebase here
	 * @param hgeToken_ Hedge token (interest bearing token)
	 * @param levToken_ Leverage token (interest bearing token)
	 * @param sponsorToken_ Sponsor token (normal ERC20 token)
	 * @param lastRebaseTime_  set the last rebase begin time. (for rebase and price update)
	 */
	function initGnesisHedge(
		address hgeToken_,
		address levToken_,
		address sponsorToken_,
		uint256 lastRebaseTime_
	) public onlyDAO {
		// 1. para checks
		require(!initialized, "HC:INITED!");
		require(lastRebaseTime_ != 0, "HC: T INV");

		// 2. tokens
		hgeToken = IHedgeToken(hgeToken_);
		levToken = IHedgeToken(levToken_);
		sponsorToken = ISponsorToken(sponsorToken_);
		/// check tokens // cannot check core address since the core address is the proxy address not address(this)
		hgeToken.index();
		levToken.index();
		sponsorToken.core();

		// 2 price and index fectch
		/// 2.1 price and index
		hedgeInfo.hedgeTokenPrice = wTokenPrice(); //(lastPrice is zero during the first warmup round)
		require(hedgeInfo.hedgeTokenPrice != 0, "HC:W P INV");
		currSTokenIndex = index();
		require(currSTokenIndex != 0, "HC:IDX INV");
		/// 2.2 timestamp (round 1 is warmup round since the initial price fectch is not at the `lastrebase time`)
		lastPriceUpdateTimestamp = lastRebaseTime_;
		hedgeInfo.rebaseTime = lastRebaseTime_;

		// 3. finish initialization set it to true.
		initialized = true;
	}

	//---------------------------------- core logic for user interactions ---------------------//
	/**
	 * @notice deposit sVSQ to soft hedge & leverage and get hgeToken and levToken
	 * @dev for frontend
	 */
	function deposit(uint256 hgeAmount_, uint256 levAmount_)
		public
		override
		nonReentrant
		onlyInitialized
		whenNotPaused
		hedgeCoreAllowed
		isEligibleSender
		minAmount(hgeAmount_, levAmount_)
	{
		_depositFor(msg.sender, hgeAmount_, levAmount_);
	}

	/**
	 * @notice caller depositFor depositFor `user_`.
	 */
	function depositFor(
		address user_,
		uint256 hgeAmount_,
		uint256 levAmount_
	) public override nonReentrant onlyInitialized whenNotPaused hedgeCoreAllowed isEligibleSender minAmount(hgeAmount_, levAmount_) {
		_depositFor(user_, hgeAmount_, levAmount_);
	}

	/**
	 * @notice withdraw sVSQ
	 * @dev for frontend
	 */
	function withdraw(uint256 hgeAmount_, uint256 levAmount_)
		public
		override
		nonReentrant
		onlyInitialized
		whenNotPaused
		hedgeCoreAllowed
		isEligibleSender
	{
		_withdrawTo(msg.sender, hgeAmount_, levAmount_);
	}

	/**
	 * @notice caller depositFor depositFor `user_`.
	 */
	function withdrawTo(
		address recipent_,
		uint256 hgeAmount_,
		uint256 levAmount_
	) public override nonReentrant onlyInitialized whenNotPaused hedgeCoreAllowed isEligibleSender {
		_withdrawTo(recipent_, hgeAmount_, levAmount_);
	}

	/**
	 * @notice redeem back all available sVSQ after game paused
	 * @dev for user to exit the game completely after the game paused. All hgeToken and levToken of `msg.sender` will be burned
	 */
	function withdrawAllWhenPaused() public override nonReentrant onlyInitialized whenPaused onlyWithdrawAllNotPaused isEligibleSender {
		// 1. cal hge and lev and sponsor balance
		uint256 hgeBalance = hgeToken.balanceOf(msg.sender);
		uint256 levBalance = levToken.balanceOf(msg.sender);
		uint256 sponsorBalance = sponsorToken.balanceOf(msg.sender);

		// 2. withdraw all to user
		_withdrawTo(msg.sender, hgeBalance, levBalance);
		_sponsorWithraw(sponsorBalance);
	}

	/**
	 * @notice swap between soft hedge and soft leverage
	 */
	function swap(bool fromLongToShort_, uint256 amount_)
		public
		override
		nonReentrant
		onlyInitialized
		whenNotPaused
		hedgeCoreAllowed
		isEligibleSender
	{
		_swap(fromLongToShort_, amount_);
	}

	function sponsorDeposit(uint256 amount_)
		public
		override
		nonReentrant
		onlyInitialized
		whenNotPaused
		isEligibleSender
		minAmount(amount_, minSingleSideDepositAmount)
	{
		_sponsorDeposit(amount_);
	}

	function sponsorWithdraw(uint256 amount_) public override nonReentrant onlyInitialized whenNotPaused isEligibleSender {
		_sponsorWithraw(amount_);
	}

	function startNewHedge() public override nonReentrant onlyInitialized whenNotPaused onlyAfterRebase(index()) {
		_startNewHedge();
	}

	/**
	 * @dev record price every 8 hours. called by keeper. can only be called before rebase
	 */
	function updatePriceBeforeRebase() external override nonReentrant onlyInitialized whenNotPaused returns (uint256 price_) {
		require(!_isSTokenRebased(index()), "HC:REBASED!"); // make sure not rebased
		require(!isPriceUpdatedBeforeRebase(), "HC: P UPDATED"); // make sure price updated before rebase
		require(block.timestamp >= lastPriceUpdateTimestamp + 8 hours, "HC:P NOT READY");
		price_ = _updatePrice();
	}

	// ----------------------------- internal core functions-------------------------------//
	/**
	 * @dev `msg.sender` transfer `hgeAmount_ + levAmount_` of sToken to contract and mint `user_` hgeToken and levToken
	 * @param hgeAmount_ The amount of gohm user wishes to soft hedge
	 * @param levAmount_ The amount of gohm user wishes to soft leverage
	 */
	function _depositFor(
		address user_,
		uint256 hgeAmount_,
		uint256 levAmount_
	) internal {
		require(user_ != address(0), "HC:ADDR ZR");
		require(hgeAmount_ + levAmount_ != 0, "HC:AMNT ZR");

		// gohm is not feeOnTransfer token so no need to check pre and post balance
		wToken.safeTransferFrom(msg.sender, address(this), hgeAmount_ + levAmount_);

		// calc balance in sToken
		uint256 hgeBalance = balanceFromWToken(hgeAmount_);
		uint256 levBalance = balanceFromWToken(levAmount_);
		// mint user sToken to game token for LONG and SHORT
		if (hgeBalance != 0) {
			hgeToken.mint(user_, hgeBalance);
		}
		if (levBalance != 0) {
			levToken.mint(user_, levBalance);
		}

		// update mappings for user view earned profits
		userDeposited[user_] += hgeAmount_ + levAmount_;

		// emit deposit event and game status
		emit Deposited(user_, hgeAmount_, levAmount_);
	}

	/**
	 * @dev burn `msg.sender`'s hgeToken and levToken and transfer gohm to `recipient`
	 * @param recipient_ The address which receives withrawed sVSQ
	 * @param hgeAmount_ The amount of hgeToken needs to burn
	 * @param levAmount_ The amount of levToken needs to burn
	 */
	function _withdrawTo(
		address recipient_,
		uint256 hgeAmount_,
		uint256 levAmount_
	) internal {
		require(hgeAmount_ + levAmount_ != 0, "HC:AMNT ZR");
		require(recipient_ != address(0), "HC:ADDR ZR");

		// 1. burn user hge & lev token
		if (hgeAmount_ != 0) {
			hgeToken.burn(msg.sender, hgeAmount_);
		}
		if (levAmount_ != 0) {
			levToken.burn(msg.sender, levAmount_);
		}

		uint256 wrappedTokenBalance = balanceToWToken(hgeAmount_ + levAmount_);

		// 2. convert game token to sToken
		wToken.safeTransfer(recipient_, wrappedTokenBalance);

		// 3. update mappings for user view earned profits (rough calculation. reference only)
		// note we need to be careful of underflow since balance would increase and user might withdraw more than they initially deposit
		uint256 deposited = userDeposited[msg.sender];
		uint256 left;
		if (deposited > wrappedTokenBalance) {
			left = deposited - wrappedTokenBalance;
		}
		userDeposited[msg.sender] = left;

		// 4. emit withdraw event and game status
		emit Withdrawn(recipient_, hgeAmount_, levAmount_);
	}

	/**
	 * @dev swap between soft hedge & leverage. (burn and mint the corresponding hge/lev tokens)
	 * @param fromLongToShort_ swap options
	 * @param amount_ The swap amount (hedgeToken amount)
	 */
	function _swap(bool fromLongToShort_, uint256 amount_) internal {
		require(amount_ != 0, "HC:AMNT ZR");
		if (fromLongToShort_) {
			levToken.burn(msg.sender, amount_);
			hgeToken.mint(msg.sender, amount_);
		} else {
			hgeToken.burn(msg.sender, amount_);
			levToken.mint(msg.sender, amount_);
		}

		emit Swaped(msg.sender, fromLongToShort_, amount_);
	}

	/**
	 * @dev sponsor `amount_` of gohm (sponsor will not receive rewards)
	 * @param amount_ gohm amount
	 */
	function _sponsorDeposit(uint256 amount_) internal {
		require(amount_ != 0, "HC:AMNT ZR");
		wToken.safeTransferFrom(msg.sender, address(this), amount_);
		uint256 sTokenBalance = balanceFromWToken(amount_);

		// 2. mint same amount of sponsorToken
		sponsorToken.mint(msg.sender, sTokenBalance);

		// emit events
		emit Sponsored(msg.sender, amount_);
	}

	/**
	 * @dev withdraw `amount_` sponsored sToken (sponsor will not receive the rebase rewards)
	 * @param amount_ sponsorToken amount
	 */
	function _sponsorWithraw(uint256 amount_) internal {
		require(amount_ > 0, "HC:AMNT ZR");
		// 1. burn sponsor token
		sponsorToken.burn(msg.sender, amount_);

		// 2. transfer gohm to msg.sender
		uint256 wrappedTokenBalance = balanceToWToken(amount_);
		wToken.safeTransfer(msg.sender, wrappedTokenBalance);

		// 3. emit events
		emit SponsorWithdrawn(msg.sender, wrappedTokenBalance);
	}

	/**
	 * @dev triggered after sToken rebased. (only when both hedge and leverage sides exsit)
	 */
	function _startNewHedge() internal {
		require(hgeToken.totalSupply() > 0 && levToken.totalSupply() > 0, "HC:B NON ZR TS");
		bool isLev;

		// 1. fetch price and determines the result of current round
		// check if price updated. if not update price here.
		if (isPriceUpdatedBeforeRebase()) {
			require(hedgeInfo.lastPrice != 0, "HC: INV"); // not possible but extra check (lastPrice is zero during the first warmup round before price updated)
			isLev = isLevWin(isPriceRatioUp, hedgeInfo.lastPrice, hedgeInfo.hedgeTokenPrice);
		} else {
			// if prcie update not called by chainlink, update the price here.
			_updatePrice();
			isLev = isLevWin(isPriceRatioUp, hedgeInfo.lastPrice, hedgeInfo.hedgeTokenPrice);
		}

		// 2. calc the rebaseDistributeAmount. (part of the interest(loser side's) will be sent to gauge if the setting's on)
		// 2.1 calc rebase amount
		uint256 rebaseTotalAmount;
		uint256 oldAmount = hgeToken.totalSupply() + levToken.totalSupply() + sponsorToken.totalSupply();
		uint256 wrappedTokenBalance = wToken.balanceOf(address(this));
		uint256 sTokenBalance = balanceFromWToken(wrappedTokenBalance);
		if (sTokenBalance > oldAmount) {
			//// in case of underflow
			rebaseTotalAmount = sTokenBalance - oldAmount;
		}

		// 2.2 calc the toGauge amount. The amount is only deducted from the (loser+ sponsor) side's interest(rebase amount) so winner's rewards >= the regular rebase rewards
		uint256 toGauge;
		// fee on if both non zero
		if (toGaugeRatio != 0 && gauge != address(0)) {
			if (isLev) {
				toGauge =
					((rebaseTotalAmount * toGaugeRatio * (hgeToken.totalSupply() + sponsorToken.totalSupply())) / (oldAmount)) /
					RATIO_PRECISION;
			} else {
				toGauge =
					((rebaseTotalAmount * toGaugeRatio * (levToken.totalSupply() + sponsorToken.totalSupply())) / (oldAmount)) /
					RATIO_PRECISION;
			}
		}

		//// no fee if toGauge is zero
		if (toGauge != 0) {
			wToken.safeTransfer(gauge, balanceToWToken(toGauge));
		}

		uint256 rebaseDistributeAmount = rebaseTotalAmount - toGauge;

		// 3 start new game
		/// 3.1 update epoch and rebaseEndTime
		currSTokenIndex = index();
		/// update rebase time
		hedgeInfo.rebaseTime = block.timestamp;
		/// 3.2 update token indices
		_rebaseHedgeToken(isLev, rebaseDistributeAmount, rebaseTotalAmount);

		// 4. emit event
		emit HedgeLog(logs.length, isLev, rebaseTotalAmount);
	}

	/**
	 * @dev update token index for winning side and store some logs
	 * @param isLev_ true: soft lev win. false: soft hge win
	 * @param atualRebasedAmount_ actual rebase rebase reward being distributed to user
	 * @param totalRebasedAmount_ totalRebase rewards
	 */
	function _rebaseHedgeToken(
		bool isLev_,
		uint256 atualRebasedAmount_,
		uint256 totalRebasedAmount_
	) internal {
		Log memory currLog;
		// 1. record results (do not affect the core logic, just for result recording)
		currLog.isLev = isLev_;
		currLog.atualRebasedAmount = atualRebasedAmount_;
		currLog.totalRebasedAmount = totalRebasedAmount_;
		currLog.index = index(); // cause logs length increse after this

		// 2. update token index
		if (isLev_) {
			// 2.1 if soft leverage win
			uint256 oldIdx = levToken.index();
			uint256 levIdx = oldIdx + (atualRebasedAmount_ * PRECISION) / levToken.rawTotalSupply();
			levToken.updateIndex(levIdx);
			currLog.tokenIdx = levIdx;
			logs.push(currLog);
			levRebaseCnt += 1;
		} else {
			// 2.2 if soft hedge win
			uint256 oldIdx = hgeToken.index();
			uint256 hgeIdx = oldIdx + (atualRebasedAmount_ * PRECISION) / hgeToken.rawTotalSupply();
			hgeToken.updateIndex(hgeIdx);
			currLog.tokenIdx = hgeIdx;
			logs.push(currLog);
			hedgeRebaseCnt += 1;
		}

		// 3. emit events
		emit Rebased(atualRebasedAmount_, totalRebasedAmount_);
	}

	function _updatePrice() internal returns (uint256 price_) {
		price_ = wTokenPrice();
		hedgeInfo.lastPrice = hedgeInfo.hedgeTokenPrice;
		hedgeInfo.hedgeTokenPrice = price_;
		hedgeInfo.cnt += 1; // equals to logs.length + 1
		lastPriceUpdateTimestamp = block.timestamp;
	}

	// ------------------------------------ADMIN / DAO---------------------------- //
	/**
	 * @dev onlyEmergencyAdmin can update implementation
	 */
	function _authorizeUpgrade(address) internal override onlyEmergencyAdmin {}

	/**
	 * @dev update toGauge address and ratio. The fee is activated when both are set correct. the fee is deducted from the loser' side rebase reward
	 * @param newGauge_ gauge address. set to address(0) to turn off fee
	 * @param ratio_ fee ratio. ratio is 10^5 precision. so 1000 => 1%. 20000 => 20%
	 */
	function updateGaugeAndRatio(address newGauge_, uint256 ratio_) external onlyDAO {
		gauge = newGauge_;
		require(ratio_ <= RATIO_PRECISION, "HC:R INV"); // <= 100%
		toGaugeRatio = ratio_;
	}

	/** @dev update price impact
	 *	@param newRatio_ no upper limit (0-100%)
	 */
	function updatePriceRatio(bool isUp_, uint256 newRatio_) external onlyDAO {
		require(newRatio_ <= RATIO_PRECISION, "HC:PR INV");
		priceRatio = newRatio_;
		isPriceRatioUp = isUp_;
	}

	/**
	 * @dev [onlyEmergencyAdmin] pause or unpause protocol
	 * @param paused_ true => pause, false => unpause
	 */
	function setPause(bool paused_) external onlyEmergencyAdmin {
		if (paused_) {
			_pause();
		} else {
			_unpause();
		}
	}

	/**
	 * @dev [onlyEmergencyAdmin] pause or unpause withdrawAll
	 * @param paused_ true => pause, false => unpause
	 */
	function setWithdrawAllPause(bool paused_) external onlyEmergencyAdmin {
		if (paused_) {
			// pause withdraw all
			require(!withdrawAllPaused, "HC:WA PAUSED");
			withdrawAllPaused = paused_;
		} else {
			// unpause withdraw all
			require(withdrawAllPaused, "HC:WA NOT PAUSED");
		}
		withdrawAllPaused = paused_;
	}

	/**
	 * @dev [onlyDAO] range 0-8hours => deposit available window (0 - 8 hours)
	 * @param value_ new restricted period
	 */
	function updateRestrictedPeriod(uint256 value_) external onlyDAO {
		require(value_ <= 8 hours, "HC:RP INV");
		resctrictedPeriod = value_;
	}

	/**
	 * @dev [onlyDAO] rescue leftover tokens and send them to DAO
	 * @param token_ reserve curreny
	 * @param amount_ amount of reserve token to transfer
	 */
	function rescueTokens(address token_, uint256 amount_) external onlyDAO whenPaused {
		IERC20(token_).safeTransfer(msg.sender, amount_);
	}

	function setSingleSideMinDepositAmount(uint256 minAmount_) external onlyDAO {
		minSingleSideDepositAmount = minAmount_;
	}

	//--------------------------- view / pure --------------------------------

	/**
	 * @notice fetch index. data source is chainlink oracle
	 * @dev get from oracle master and the mapping entry is set to the chainlink aggregator address
	 */
	function index() public view returns (uint256) {
		address oracleMaster = addressProvider.getOracleMaster();
		return IOracleMaster(oracleMaster).queryInfo(0x48C4721354A3B29D80EF03C65E6644A37338a0B1); //use chainlink ohm index aggregator address (on arbitrum)
	}

	/**
	 * @notice gohm => ohm balance
	 * @param amount_ gohm amount
	 * @return ohm/sohm amount
	 */
	function balanceFromWToken(uint256 amount_) public view returns (uint256) {
		return (amount_ * (index())) / (10**9);
	}

	/**
	 * @notice ohm => gohm balance
	 * @param amount_ ohm/sohm amount
	 * @return gohm amount
	 */
	function balanceToWToken(uint256 amount_) public view returns (uint256) {
		return (amount_ * (10**9)) / (index());
	}

	/**
	 * @notice gohm price.
	 */
	function wTokenPrice() public view returns (uint256) {
		address oracleMaster = addressProvider.getOracleMaster();
		return IOracleMaster(oracleMaster).queryInfo(address(wToken));
	}

	function priceAfterRatio() external view returns (uint256 price_) {
		return _priceAfterRatio(isPriceRatioUp, hedgeInfo.hedgeTokenPrice);
	}

	/**
	 * @notice get the (1 + ratio)% price
	 */
	function _priceAfterRatio(bool up_, uint256 originPrice_) internal view returns (uint256 price_) {
		uint256 deltaPrice = (originPrice_ * priceRatio) / RATIO_PRECISION;
		if (up_) {
			price_ = originPrice_ + deltaPrice;
		} else {
			price_ = originPrice_ - deltaPrice;
		}
	}

	/**
	 * @notice check if current round price fetched
	 * if updated before rebase. the priceCnt = logs.length(rebase cnt) + 1
	 * if updated after rebase or not updated before rebase. the priceCnt = rebaseCnt
	 */
	function isPriceUpdatedBeforeRebase() public view returns (bool updated) {
		uint256 rebaseCnt = logs.length;
		uint256 priceCnt = hedgeInfo.cnt;
		if (priceCnt == rebaseCnt + 1) {
			updated = true;
		}
	}

	/**
	 * @notice check if lev win. (>=: lev, <: hedge)
	 */
	function isLevWin(
		bool ispriceRatioUp_,
		uint256 lastPrice_,
		uint256 currPrice_
	) public view returns (bool isLev_) {
		if (currPrice_ >= _priceAfterRatio(ispriceRatioUp_, lastPrice_)) {
			isLev_ = true;
		}
	}

	/**
	 * @notice true: deposit open. false: deposit close
	 * @dev 2 & 3 is not likely to happen but tripple check
	 *		1. in allowed period,
	 * 		2. price updated is not called.
	 *		3. before rebased
	 */
	function hedgeCoreStatus() public view override returns (bool isUnlocked_) {
		bool isInAllowedPriod;
		bool isCurrentRoundPriceUpdated;
		bool isRebased;

		isInAllowedPriod = (block.timestamp <= hedgeInfo.rebaseTime + resctrictedPeriod) ? true : false;
		isCurrentRoundPriceUpdated = isPriceUpdatedBeforeRebase();
		isRebased = _isSTokenRebased(index());

		isUnlocked_ = isInAllowedPriod && (!isCurrentRoundPriceUpdated) && (!isRebased);
	}

	/**
	 * @notice check if sToken rebase since last time
	 */
	function isSTokenRebased() external view override returns (bool) {
		return _isSTokenRebased(index());
	}

	function _isSTokenRebased(uint256 index_) internal view returns (bool) {
		return index_ > currSTokenIndex ? true : false;
	}

	/**
	 * @notice view your earned profits
	 * @dev for user view and reference only! might not be accurate if user transfer their hge/lev tokens
	 * @param user_ user address
	 * @return earnedProfit_ earned profit for `user_`
	 */
	function earnedProfit(address user_) external view returns (uint256 earnedProfit_) {
		uint256 totalBalance = hgeToken.balanceOf(user_) + levToken.balanceOf(user_);
		uint256 totalBalanceInWrappedToken = balanceToWToken(totalBalance);
		uint256 userDepositedAmount = userDeposited[user_];
		if (totalBalanceInWrappedToken >= userDepositedAmount) {
			// in case of underflow since user might transfer token themselves
			earnedProfit_ = totalBalanceInWrappedToken - userDepositedAmount;
		}
	}

	function logsLen() external view returns (uint256) {
		return logs.length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAddressProvider {
	function getDAO() external view returns (address);

	function getOracleMaster() external view returns (address);

	function getEmergencyAdmin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracleMaster {
	function queryInfo(address token_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import { IAddressProvider } from "./interfaces/IAddressProvider.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ICore } from "./interfaces/ICore.sol";
import { IHedgeToken } from "./interfaces/IHedgeToken.sol";
import { ISponsorToken } from "./interfaces/ISponsorToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title HedgeCoreStorage
 * @author Entropyfi
 * @notice Contract used as storage of the `HedgeCoreUpgradable` contract.
 * @dev It defines the storage layout of the `HedgeCoreUpgradable` contract. For upgradable contract, place the storage at the last the inheritance contracts.
 */
contract CoreStorageV1 {
	// ------------------------------ modifiers ----------------------------------
	/// @dev dao
	modifier onlyDAO() {
		require(msg.sender == addressProvider.getDAO(), "HC:NO ACCESS");
		_;
	}

	/// @dev emergencyAdmin or dao
	modifier onlyEmergencyAdmin() {
		require((msg.sender == addressProvider.getEmergencyAdmin()) || (msg.sender == addressProvider.getDAO()), "HC:NO ACCESS");
		_;
	}

	/// @dev only EOA/whitelisted contract/admin can interact with this protocol
	modifier isEligibleSender() {
		bool isAdmin = (msg.sender == addressProvider.getDAO() || msg.sender == addressProvider.getEmergencyAdmin());
		// check if address whitelisted if it's not EOA or Admins
		if (AddressUpgradeable.isContract(msg.sender) && !isAdmin) {
			require(whitelistedContracts[msg.sender], "HC:CONTRACT NOT WHITELISTED");
		}
		_;
	}

	modifier onlyOwner() {
		if (address(addressProvider) != address(0)) {
			require((msg.sender == addressProvider.getEmergencyAdmin()) || (msg.sender == addressProvider.getDAO()), "HC:NO ACCESS");
		}
		_;
	}
	modifier onlyInitialized() {
		require(initialized, "HC:NOT INIT");
		_;
	}

	modifier onlyBeforeLockedTime() {
		require(block.timestamp <= hedgeInfo.rebaseTime + resctrictedPeriod, "HC:RESTRICTED");
		_;
	}

	modifier onlyWithdrawAllNotPaused() {
		require(!withdrawAllPaused, "HC:WA PAUSED");
		_;
	}

	modifier onlyAfterRebase(uint256 index_) {
		require(index_ > currSTokenIndex, "HC: NOT REBASED!");
		_;
	}

	modifier minAmount(uint256 hedgeAmount_, uint256 levAmount_) {
		if (hedgeAmount_ != 0) {
			require(hedgeAmount_ >= minSingleSideDepositAmount, "HC:H<= MIN");
		}
		if (levAmount_ != 0) {
			require(levAmount_ >= minSingleSideDepositAmount, "HC:L<= MIN");
		}

		_;
	}

	// precision for updating token index
	uint256 public constant PRECISION = 1E18;
	// precision for ratio calculation => priceRatio and toGaugeRatio
	uint256 public constant RATIO_PRECISION = 1E5;
	// precision for price
	uint256 public constant PRICE_PRECISION = 1E8;

	// contract name
	string public name;

	// for init gnensis hedge
	bool public initialized;

	// Address provider
	IAddressProvider public addressProvider;

	// tokens
	IERC20 public wToken; // the underlying token which user can deposit and withdraw
	IHedgeToken public hgeToken; // < for soft hedge
	IHedgeToken public levToken; // >= for soft leverage
	ISponsorToken public sponsorToken; // for sponsorship

	// game related
	bool public withdrawAllPaused; // for pause withdrawall
	uint256 public lastPriceUpdateTimestamp; // updated with price fetch
	uint256 public priceRatio; // 1e5 pricision (0-1e5) lev winning pric will be price*(1 + ratio(%))
	bool public isPriceRatioUp; // true: tune up, false tune down
	uint256 public resctrictedPeriod; // period of time when user can/cannot deposit withdraw and swap
	uint256 public currSTokenIndex; // current sToken epoch number
	uint256 public hedgeRebaseCnt; // increment when hedge win
	uint256 public levRebaseCnt; // increment when lev win
	ICore.HedgeInfo public hedgeInfo; // store important game related data

	// log related
	ICore.Log[] public logs;

	// gauge related
	address public gauge; // onlyOwner can change
	uint256 public toGaugeRatio; // 1000 means 1%.   div by 10^5 to get the actual number (e.g. 0.01)

	// for whitelist contract
	mapping(address => bool) public whitelistedContracts;

	// user view earned profits
	mapping(address => uint256) public userDeposited;

	uint256 public minSingleSideDepositAmount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ICore {
	event Initialized(address indexed initializer);
	event PriceUpdated(uint256 indexed price_);
	event Rebased(uint256 indexed rebaseDistributed_, uint256 indexed rebaseTotal_);
	event Logger(uint256 shortIndex, uint256 longIndex, uint256 indexed shortRebase_, uint256 indexed longRebased_);
	event Deposited(address indexed user_, uint256 indexed shortAmount_, uint256 indexed longAmount_);
	event Withdrawn(address indexed to_, uint256 indexed shortAmount_, uint256 indexed longAmount_);
	event Swaped(address indexed user_, bool indexed fromLongToShort_, uint256 indexed amount_);
	event Sponsored(address indexed user_, uint256 indexed amount_);
	event SponsorWithdrawn(address indexed user_, uint256 indexed amount_);

	event HedgeLog(uint256 epoch, bool isLong, uint256 rebaseTotalAmount);

	// soft-hedge data
	struct HedgeInfo {
		uint256 lastPrice;
		uint256 hedgeTokenPrice;
		uint256 rebaseTime;
		uint256 cnt; //
	}

	struct Log {
		bool isLev; // the win side
		uint256 atualRebasedAmount;
		uint256 totalRebasedAmount;
		uint256 timestampOccured;
		uint256 index; // ohm index
		uint256 tokenIdx; // idx of our HedgeToken
	}

	function deposit(uint256 shortAmount_, uint256 longAmount_) external;

	function depositFor(
		address user_,
		uint256 shortAmount_,
		uint256 longAmount_
	) external;

	function withdraw(uint256 shortAmount_, uint256 longAmount_) external;

	function withdrawTo(
		address recipent_,
		uint256 shortAmount_,
		uint256 longAmount_
	) external;

	function withdrawAllWhenPaused() external;

	function sponsorDeposit(uint256 amount_) external;

	function sponsorWithdraw(uint256 amount_) external;

	function swap(bool fromLongToShort_, uint256 amount_) external;

	function hedgeCoreStatus() external view returns (bool);

	function isSTokenRebased() external view returns (bool);

	function startNewHedge() external;

	function updatePriceBeforeRebase() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHedgeToken is IERC20 {
	function core() external view returns (address);

	function index() external view returns (uint256);

	function mint(address user_, uint256 amount_) external;

	function burn(address user_, uint256 amount_) external;

	function updateIndex(uint256 idx_) external;

	function rawTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISponsorToken is IERC20 {
	function core() external view returns (address);

	function mint(address user_, uint256 amount_) external;

	function burn(address user_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}