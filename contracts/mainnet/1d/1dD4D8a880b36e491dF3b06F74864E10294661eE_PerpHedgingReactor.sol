// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../PriceFeed.sol";

import "../libraries/AccessControl.sol";
import "../libraries/OptionsCompute.sol";
import "../libraries/SafeTransferLib.sol";

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IHedgingReactor.sol";

import "@rage/core/contracts/interfaces/IClearingHouse.sol";
import "@rage/core/contracts/extsloads/ClearingHouseExtsload.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 *  @title A hedging reactor that will manage delta by opening or closing short or long perp positions using rage trade
 *  @dev interacts with LiquidityPool via hedgeDelta, getDelta, getPoolDenominatedValue and withdraw,
 *       interacts with Rage Trade and chainlink via the change position, update and sync
 */

contract PerpHedgingReactor is IHedgingReactor, AccessControl {
	using ClearingHouseExtsload for IClearingHouse;
	/////////////////////////////////
	/// immutable state variables ///
	/////////////////////////////////

	/// @notice address of the parent liquidity pool contract
	address public immutable parentLiquidityPool;
	/// @notice address of the price feed used for getting asset prices
	address public immutable priceFeed;
	/// @notice collateralAsset used for collateralising the pool
	address public immutable collateralAsset;
	/// @notice address of the wETH contract
	address public immutable wETH;
	/// @notice instance of the clearing house interface
	IClearingHouse public immutable clearingHouse;
	/// @notice collateralId to be used in the perp pool
	uint32 public immutable collateralId;
	/// @notice poolId to be used in the perp pool
	uint32 public immutable poolId;
	/// @notice accountId for the perp pool
	uint256 public immutable accountId;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	/// @notice delta of the pool
	int256 public internalDelta;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	/// @notice address of the keeper of this pool
	mapping(address => bool) public keeper;
	/// @notice desired healthFactor of the pool
	uint256 public healthFactor = 5_000;
	/// @notice should change position also sync state
	bool public syncOnChange;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	/// @notice used for unlimited token approval
	uint256 private constant MAX_UINT = 2**256 - 1;
	/// @notice max bips
	uint256 private constant MAX_BIPS = 10_000;

	//////////////
	/// errors ///
	//////////////

	error ValueFailure();
	error IncorrectCollateral();
	error IncorrectDeltaChange();
	error InvalidTransactionNotEnoughMargin(int256 accountMarketValue, int256 totalRequiredMargin);

	constructor(
		address _clearingHouse,
		address _collateralAsset,
		address _wethAddress,
		address _parentLiquidityPool,
		uint32 _poolId,
		uint32 _collateralId,
		address _priceFeed,
		address _authority
	) AccessControl(IAuthority(_authority)) {
		clearingHouse = IClearingHouse(_clearingHouse);
		collateralAsset = _collateralAsset;
		wETH = _wethAddress;
		parentLiquidityPool = _parentLiquidityPool;
		priceFeed = _priceFeed;
		poolId = _poolId;
		collateralId = _collateralId;
		// make a perp account
		accountId = clearingHouse.createAccount();
	}

	///////////////
	/// setters ///
	///////////////

	/// @notice update the health factor parameter
	function setHealthFactor(uint256 _healthFactor) external {
		_onlyGovernor();
		healthFactor = _healthFactor;
	}

	/// @notice update the keepers
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
	}

	/// @notice set whether changing a position should trigger a sync before updating
	function setSyncOnChange(bool _syncOnChange) external {
		_onlyGovernor();
		syncOnChange = _syncOnChange;
	}

	////////////////////////////////////////////
	/// access-controlled external functions ///
	////////////////////////////////////////////

	/// @notice function to deposit 1 wei of USDC into the margin account so that a margin account is made, cannot be
	///         be called if an account already exists
	function initialiseReactor() external {
		(IERC20 collateral, uint256 collat) = clearingHouse.getAccountCollateralInfo(accountId, collateralId);
		if (collat != 0) {
			revert();
		}
		SafeTransferLib.safeTransferFrom(collateralAsset, msg.sender, address(this), 1);
		SafeTransferLib.safeApprove(ERC20(collateralAsset), address(clearingHouse), MAX_UINT);
		clearingHouse.updateMargin(accountId, collateralId, 1);
	}

	/// @inheritdoc IHedgingReactor
	function hedgeDelta(int256 _delta) external returns (int256 deltaChange) {
		// delta is passed in as the delta that the pool has so this function must hedge the opposite
		// if delta comes in negative then the pool must go long
		// if delta comes in positive then the pool must go short
		// the signs must be flipped when going into _changePosition
		// make sure the caller is the vault
		require(msg.sender == parentLiquidityPool, "!vault");
		deltaChange = _changePosition(-_delta);
		// record the delta change internally
		internalDelta += deltaChange;
	}

	/// @inheritdoc IHedgingReactor
	function withdraw(uint256 _amount) external returns (uint256) {
		require(msg.sender == parentLiquidityPool, "!vault");
		// check the holdings if enough just lying around then transfer it
		// assume amount is passed in as collateral decimals
		uint256 balance = ERC20(collateralAsset).balanceOf(address(this));
		if (balance == 0) {
			return 0;
		}
		if (_amount <= balance) {
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), msg.sender, _amount);
			// return in collateral format
			return _amount;
		} else {
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), msg.sender, balance);
			// return in collateral format
			return balance;
		}
	}

	/// @notice function to poke the margin account to update the profits of the vault and also manage
	///         the collateral to safe bounds.
	/// @dev    only callable by a keeper
	function syncAndUpdate() external {
		sync();
		update();
	}

	/// @notice function to poke the margin account to update the profits of the vault
	/// @dev    only callable by a keeper
	function sync() public {
		_isKeeper();
		clearingHouse.settleProfit(accountId);
	}

	/// @inheritdoc IHedgingReactor
	function update() public returns (uint256) {
		_isKeeper();
		int256 netPosition = clearingHouse.getAccountNetTokenPosition(accountId, poolId);
		(IERC20 collateral, uint256 collat) = clearingHouse.getAccountCollateralInfo(accountId, collateralId);
		// just make sure the collateral at index 0 is correct (this is unlikely to ever fail, but should be checked)
		if (collat == 0) {
			revert IncorrectCollateral();
		}
		if (address(collateral) != collateralAsset) {
			revert IncorrectCollateral();
		}
		// we want 1 wei at all times, so if there is only 1 wei of collat and the net position is 0 then just return
		if (collat == 1 && netPosition == 0) {
			return 0;
		}
		// get the current price of the underlying asset from chainlink to be used to calculate position sizing
		uint256 currentPrice = OptionsCompute.convertToDecimals(
			PriceFeed(priceFeed).getNormalizedRate(wETH, collateralAsset),
			ERC20(collateralAsset).decimals()
		);
		// check the collateral health of positions
		// get the amount of collateral that should be expected for a given amount
		uint256 collatRequired = netPosition >= 0
			? (((uint256(netPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS
			: (((uint256(-netPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS;
		// if there is not enough collateral then request more
		// if there is too much collateral then return some to the pool
		if (collatRequired > collat) {
			if (ILiquidityPool(parentLiquidityPool).getBalance(collateralAsset) < (collatRequired - collat)) {
				revert CustomErrors.WithdrawExceedsLiquidity();
			}
			// transfer assets from the liquidityPool to here to collateralise the pool
			SafeTransferLib.safeTransferFrom(
				collateralAsset,
				parentLiquidityPool,
				address(this),
				collatRequired - collat
			);
			// deposit the collateral into the margin account
			clearingHouse.updateMargin(accountId, collateralId, int256(collatRequired - collat));
			return collatRequired - collat;
		} else if (collatRequired < collat) {
			// withdraw excess collateral from the margin account
			clearingHouse.updateMargin(accountId, collateralId, -int256(collat - collatRequired));
			// transfer assets back to the liquidityPool
			SafeTransferLib.safeTransfer(
				ERC20(collateralAsset),
				parentLiquidityPool,
				collat - collatRequired
			);
			return collat - collatRequired;
		} else {
			return 0;
		}
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/// @inheritdoc IHedgingReactor
	function getDelta() external view returns (int256 delta) {
		return internalDelta;
	}

	/// @inheritdoc IHedgingReactor
	function getPoolDenominatedValue() external view returns (uint256 value) {
		// get the account market value
		(int256 accountMarketValue,) = clearingHouse.getAccountMarketValueAndRequiredMargin(accountId, false);
		// increment any loose balance held by the pool
		value += ERC20(collateralAsset).balanceOf(address(this));
		// if there is ever a case where value is negative then something has gone very wrong and this should be dealt with
		// by the reactor manager so the transaction should revert here
		if (accountMarketValue < 0) {
			revert ValueFailure();
		}
		value += uint256(accountMarketValue);
		// value to be returned in e18
		value = OptionsCompute.convertFromDecimals(value, ERC20(collateralAsset).decimals());
	}

	/** @notice function to check the health of the margin account
     *  @return isBelowMin is the margin below the health factor
     *  @return isAboveMax is the margin above the health factor
	 *  @return health     the health factor of the account currently
	 *  @return collatToTransfer the amount of collateral required to return the margin account back to the health factor
     */
	function checkVaultHealth() external view returns (
		bool isBelowMin,
		bool isAboveMax,
		uint256 health,
		uint256 collatToTransfer
	) {
		int256 netPosition = clearingHouse.getAccountNetTokenPosition(accountId, poolId);
		(int256 accountMarketValue,) = clearingHouse.getAccountMarketValueAndRequiredMargin(accountId, false);
		(IERC20 collateral, uint256 collat) = clearingHouse.getAccountCollateralInfo(accountId, collateralId);
		if (accountMarketValue < 0) {
			revert ValueFailure();
		}
		uint256 unsignedAccountMarketValue = uint256(accountMarketValue);
		// just make sure the collateral at index 0 is correct (this is unlikely to ever fail, but should be checked)
		if (collat == 0) {
			revert IncorrectCollateral();
		}
		if (address(collateral) != collateralAsset) {
			revert IncorrectCollateral();
		}
		// we want 1 wei at all times, so if there is only 1 wei of collat and the net position is 0 then just return
		if (collat == 1 && netPosition == 0) {
			return (false, false, healthFactor, 0);
		}
		// get the current price of the underlying asset from chainlink to be used to calculate position sizing
		uint256 currentPrice = OptionsCompute.convertToDecimals(
			PriceFeed(priceFeed).getNormalizedRate(wETH, collateralAsset),
			ERC20(collateralAsset).decimals()
		);
		// check the collateral health of positions
		// get the amount of collateral that should be expected for a given amount
		health = netPosition >= 0
			? (unsignedAccountMarketValue * MAX_BIPS) / ((uint256(netPosition) * currentPrice) / 1e18)
			: (unsignedAccountMarketValue * MAX_BIPS) / ((uint256(-netPosition) * currentPrice)/ 1e18);
		uint256 collatRequired = netPosition >= 0
			? (((uint256(netPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS
			: (((uint256(-netPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS;
		// if there is not enough collateral then request more
		// if there is too much collateral then return some to the pool
		if (collatRequired > unsignedAccountMarketValue) {
			isBelowMin = true;
			isAboveMax = false;
			collatToTransfer = collatRequired - unsignedAccountMarketValue;
		} else if (collatRequired < unsignedAccountMarketValue) {
			isBelowMin = false;
			isAboveMax = true;
			collatToTransfer = unsignedAccountMarketValue - collatRequired;
		}
	}
	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	/** @notice function to change the perp position
        @param _amount the amount of position to open or close
        @return deltaChange The resulting difference in delta exposure
    */
	function _changePosition(int256 _amount) internal returns (int256) {
		if (syncOnChange) {
			sync();
		}
		uint256 collatToDeposit;
		uint256 collatToWithdraw;
		int256 positionOpened;
		// access the collateral held in the account
		(, uint256 collat) = clearingHouse.getAccountCollateralInfo(accountId, collateralId);
		// just make sure the collateral at index 0 is correct (this is unlikely to ever fail, but should be checked)
		if (collat == 0) {
			revert IncorrectCollateral();
		}
		// getAccountNetProfit and updateProfit
		// check the net position of the margin account
		int256 netPosition = clearingHouse.getAccountNetTokenPosition(accountId, poolId);
		// get the new net position with the amount of the swap added
		int256 newPosition = netPosition + _amount;
		// get the current price of the underlying asset from chainlink to be used to calculate position sizing
		uint256 currentPrice = OptionsCompute.convertToDecimals(
			PriceFeed(priceFeed).getNormalizedRate(wETH, collateralAsset),
			ERC20(collateralAsset).decimals()
		);
		// calculate the margin requirement for newPosition making sure to account for the health factor of the pool
		// as we want the position to be overcollateralised
		uint256 totalCollatNeeded = newPosition >= 0
			? (((uint256(newPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS
			: (((uint256(-newPosition) * currentPrice) / 1e18) * healthFactor) / MAX_BIPS;
		// if there is not enough collateral then increase the margin collateral balance
		// if there is too much collateral then decrease the margin collateral balance
		if (totalCollatNeeded > collat) {
			collatToDeposit = totalCollatNeeded - collat;
		} else if (totalCollatNeeded < collat) {
			collatToWithdraw = collat - Math.max(totalCollatNeeded, 1);
		} else if (totalCollatNeeded == collat && _amount != 0) {
			// highly improbable but if collateral is exactly equal if the amount to hedge is exactly opposite of the current
			// hedge then just swap without changing the margin
			// make the swapParams
			IClearingHouseStructures.SwapParams memory swapParams = IClearingHouseStructures.SwapParams(
				_amount,
				0,
				false,
				false,
				false
			);
			// execute the swap
			(positionOpened, ) = clearingHouse.swapToken(accountId, poolId, swapParams);
		} else {
			// this will happen if amount is 0
			return 0;
		}
		// if the current margin held is smaller than the new margin required then deposit more collateral
		// and open more positions
		// if the current margin held is larger than the new margin required then swap tokens out and
		// withdraw the excess margin
		if (collatToDeposit > 0) {
			if (ILiquidityPool(parentLiquidityPool).getBalance(collateralAsset) < collatToDeposit) {
				revert CustomErrors.WithdrawExceedsLiquidity();
			}
			// transfer assets from the liquidityPool to here to collateralise the pool
			SafeTransferLib.safeTransferFrom(collateralAsset, msg.sender, address(this), collatToDeposit);
			// deposit the collateral into the margin account
			clearingHouse.updateMargin(accountId, collateralId, int256(collatToDeposit));
			// make the swapParams
			IClearingHouseStructures.SwapParams memory swapParams = IClearingHouseStructures.SwapParams(
				_amount,
				0,
				false,
				false,
				false
			);
			// execute the swap
			(positionOpened, ) = clearingHouse.swapToken(accountId, poolId, swapParams);
		} else if (collatToWithdraw > 0) {
			// make the swapParams to close the position
			IClearingHouseStructures.SwapParams memory swapParams = IClearingHouseStructures.SwapParams(
				_amount,
				0,
				false,
				false,
				false
			);
			// execute the swap, since this is a withdrawal and we may withdraw all we want to make sure the account is properly settled
			// so we update the margin, if it fails then we settle any profits and update
			(positionOpened, ) = clearingHouse.swapToken(accountId, poolId, swapParams);
			try clearingHouse.updateMargin(accountId, collateralId, -int256(collatToWithdraw)) {} catch (
				bytes memory reason
			) {
				// way of catching custom errors referenced here: https://ethereum.stackexchange.com/questions/125238/catching-custom-error
				bytes4 expectedSelector = InvalidTransactionNotEnoughMargin.selector;
				bytes4 receivedSelector = bytes4(reason);
				assert(expectedSelector == receivedSelector);
				// settle the profits to make sure the collateral is covered
				clearingHouse.settleProfit(accountId);
				// get the new collat
				(, collat) = clearingHouse.getAccountCollateralInfo(accountId, collateralId);
				// if the collat value is smaller than collatToWithdraw then withdraw all collat
				if (collat <= collatToWithdraw && collat != 0) {
					collatToWithdraw = collat - 1;
				}
				clearingHouse.updateMargin(accountId, collateralId, -int256(collatToWithdraw));
			}
			// transfer assets back to the liquidityPool
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), msg.sender, uint256(collatToWithdraw));
		}
		// make sure that _amount and positionOpened are the same, if they are not then revert
		if (positionOpened != _amount) { revert IncorrectDeltaChange();}
		return _amount;
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] &&
			msg.sender != authority.governor() &&
			msg.sender != authority.manager() &&
			msg.sender != parentLiquidityPool
		) {
			revert CustomErrors.NotKeeper();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/AggregatorV3Interface.sol";

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used for accessing exchange rates using chainlink price feeds
 *  @dev Interacts with chainlink price feeds and services all contracts in the system for price data.
 */
contract PriceFeed is AccessControl {
	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	mapping(address => mapping(address => address)) public priceFeeds;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	uint8 private constant SCALE_DECIMALS = 18;
	// seconds since the last price feed update until we deem the data to be stale
	uint32 private constant STALE_PRICE_DELAY = 3600;

	constructor(address _authority) AccessControl(IAuthority(_authority)) {}

	///////////////
	/// setters ///
	///////////////

	function addPriceFeed(
		address underlying,
		address strike,
		address feed
	) public {
		_onlyGovernor();
		priceFeeds[underlying][strike] = feed;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	function getRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		(uint80 roundId, int256 rate, , uint256 timestamp, uint80 answeredInRound) = feed
			.latestRoundData();
		require(rate > 0, "ChainLinkPricer: price is lower than 0");
		require(timestamp != 0, "ROUND_NOT_COMPLETE");
		require(block.timestamp <= timestamp + STALE_PRICE_DELAY, "STALE_PRICE");
		require(answeredInRound >= roundId, "STALE_PRICE");
		return uint256(rate);
	}

	/// @dev get the rate from chainlink and convert it to e18 decimals
	function getNormalizedRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		uint8 feedDecimals = feed.decimals();
		(uint80 roundId, int256 rate, , uint256 timestamp, uint80 answeredInRound) = feed
			.latestRoundData();
		require(rate > 0, "ChainLinkPricer: price is lower than 0");
		require(timestamp != 0, "ROUND_NOT_COMPLETE");
		require(block.timestamp <= timestamp + STALE_PRICE_DELAY, "STALE_PRICE");
		require(answeredInRound >= roundId, "STALE_PRICE_ROUND");
		uint8 difference;
		if (SCALE_DECIMALS > feedDecimals) {
			difference = SCALE_DECIMALS - feedDecimals;
			return uint256(rate) * (10**difference);
		}
		difference = feedDecimals - SCALE_DECIMALS;
		return uint256(rate) / (10**difference);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Types.sol";
import "./CustomErrors.sol";
import "./BlackScholes.sol";

import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title Library used for various helper functionality for the Liquidity Pool
 */
library OptionsCompute {
	using PRBMathUD60x18 for uint256;
	using PRBMathSD59x18 for int256;

	uint8 private constant SCALE_DECIMALS = 18;

	/// @dev assumes decimals are coming in as e18
	function convertToDecimals(uint256 value, uint256 decimals) internal pure returns (uint256) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		uint256 difference = SCALE_DECIMALS - decimals;
		return value / (10**difference);
	}

	/// @dev converts from specified decimals to e18
	function convertFromDecimals(uint256 value, uint256 decimals) internal pure returns (uint256) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		uint256 difference = SCALE_DECIMALS - decimals;
		return value * (10**difference);
	}

	// doesnt allow for interest bearing collateral
	function convertToCollateralDenominated(
		uint256 quote,
		uint256 underlyingPrice,
		Types.OptionSeries memory optionSeries
	) internal pure returns (uint256 convertedQuote) {
		if (optionSeries.strikeAsset != optionSeries.collateral) {
			// convert value from strike asset to collateral asset
			return (quote * 1e18) / underlyingPrice;
		} else {
			return quote;
		}
	}

	/**
	 * @dev computes the percentage change between two integers
	 * @param n new value in e18
	 * @param o old value in e18
	 * @return pC uint256 the percentage change in e18
	 */
	function calculatePercentageChange(uint256 n, uint256 o) internal pure returns (uint256 pC) {
		// if new > old then its a percentage increase so do:
		// ((new - old) * 1e18) / old
		// if new < old then its a percentage decrease so do:
		// ((old - new) * 1e18) / old
		if (n > o) {
			pC = (n - o).div(o);
		} else {
			pC = (o - n).div(o);
		}
	}

	/**
	 * @notice get the latest oracle fed portfolio values and check when they were last updated and make sure this is within a reasonable window in
	 *		   terms of price and time
	 */
	function validatePortfolioValues(
		uint256 spotPrice,
		Types.PortfolioValues memory portfolioValues,
		uint256 maxTimeDeviationThreshold,
		uint256 maxPriceDeviationThreshold
	) public view {
		uint256 timeDelta = block.timestamp - portfolioValues.timestamp;
		// If too much time has passed we want to prevent a possible oracle attack
		if (timeDelta > maxTimeDeviationThreshold) {
			revert CustomErrors.TimeDeltaExceedsThreshold(timeDelta);
		}
		uint256 priceDelta = calculatePercentageChange(spotPrice, portfolioValues.spotPrice);
		// If price has deviated too much we want to prevent a possible oracle attack
		if (priceDelta > maxPriceDeviationThreshold) {
			revert CustomErrors.PriceDeltaExceedsThreshold(priceDelta);
		}
	}

	/**
	 *	@notice calculates the utilization price of an option using the liquidity pool's utilisation skew algorithm
	 */
	function getUtilizationPrice(
		uint256 _utilizationBefore,
		uint256 _utilizationAfter,
		uint256 _totalOptionPrice,
		uint256 _utilizationFunctionThreshold,
		uint256 _belowThresholdGradient,
		uint256 _aboveThresholdGradient,
		uint256 _aboveThresholdYIntercept
	) internal pure returns (uint256 utilizationPrice) {
		if (
			_utilizationBefore <= _utilizationFunctionThreshold &&
			_utilizationAfter <= _utilizationFunctionThreshold
		) {
			// linear function up to threshold utilization
			// take average of before and after utilization and multiply the average by belowThresholdGradient

			uint256 multiplicationFactor = (_utilizationBefore + _utilizationAfter)
				.mul(_belowThresholdGradient)
				.div(2e18);
			return _totalOptionPrice + _totalOptionPrice.mul(multiplicationFactor);
		} else if (
			_utilizationBefore >= _utilizationFunctionThreshold &&
			_utilizationAfter >= _utilizationFunctionThreshold
		) {
			// over threshold utilization the skew factor will follow a steeper line

			uint256 multiplicationFactor = _aboveThresholdGradient
				.mul(_utilizationBefore + _utilizationAfter)
				.div(2e18) - _aboveThresholdYIntercept;

			return _totalOptionPrice + _totalOptionPrice.mul(multiplicationFactor);
		} else {
			// in this case the utilization after is above the threshold and
			// utilization before is below it.
			// _utilizationAfter will always be greater than _utilizationBefore
			// finds the ratio of the distance below the threshold to the distance above the threshold
			uint256 weightingRatio = (_utilizationFunctionThreshold - _utilizationBefore).div(
				_utilizationAfter - _utilizationFunctionThreshold
			);
			// finds the average y value on the part of the function below threshold
			uint256 averageFactorBelow = (_utilizationFunctionThreshold + _utilizationBefore).div(2e18).mul(
				_belowThresholdGradient
			);
			// finds average y value on part of the function above threshold
			uint256 averageFactorAbove = (_utilizationAfter + _utilizationFunctionThreshold).div(2e18).mul(
				_aboveThresholdGradient
			) - _aboveThresholdYIntercept;
			// finds the weighted average of the two above averaged to find the average utilization skew over the range of utilization
			uint256 multiplicationFactor = (weightingRatio.mul(averageFactorBelow) + averageFactorAbove).div(
				1e18 + weightingRatio
			);
			return _totalOptionPrice + _totalOptionPrice.mul(multiplicationFactor);
		}
	}

	/**
	 * @notice get the greeks of a quotePrice for a given optionSeries
	 * @param  optionSeries Types.OptionSeries struct for describing the option to price greeks - strike in e18
	 * @return quote           Quote price of the option - in e18
	 * @return delta           delta of the option being priced - in e18
	 */
	function quotePriceGreeks(
		Types.OptionSeries memory optionSeries,
		bool isBuying,
		uint256 bidAskIVSpread,
		uint256 riskFreeRate,
		uint256 iv,
		uint256 underlyingPrice
	) internal view returns (uint256 quote, int256 delta) {
		if (iv == 0) {
			revert CustomErrors.IVNotFound();
		}
		// reduce IV by a factor of bidAskIVSpread if we are buying the options
		if (isBuying) {
			iv = (iv * (1e18 - (bidAskIVSpread))) / 1e18;
		}
		// revert CustomErrors.if the expiry is in the past
		if (optionSeries.expiration <= block.timestamp) {
			revert CustomErrors.OptionExpiryInvalid();
		}
		(quote, delta) = BlackScholes.blackScholesCalcGreeks(
			underlyingPrice,
			optionSeries.strike,
			optionSeries.expiration,
			iv,
			riskFreeRate,
			optionSeries.isPut
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IAuthority.sol";

error UNAUTHORIZED();

/**
 *  @title Contract used for access control functionality, based off of OlympusDao Access Control
 */
abstract contract AccessControl {
	/* ========== EVENTS ========== */

	event AuthorityUpdated(IAuthority authority);

	/* ========== STATE VARIABLES ========== */

	IAuthority public authority;

	/* ========== Constructor ========== */

	constructor(IAuthority _authority) {
		authority = _authority;
		emit AuthorityUpdated(_authority);
	}

	/* ========== GOV ONLY ========== */

	function setAuthority(IAuthority _newAuthority) external {
		_onlyGovernor();
		authority = _newAuthority;
		emit AuthorityUpdated(_newAuthority);
	}

	/* ========== INTERNAL CHECKS ========== */

	function _onlyGovernor() internal view {
		if (msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyGuardian() internal view {
		if (!authority.guardian(msg.sender) && msg.sender != authority.governor()) revert UNAUTHORIZED();
	}

	function _onlyManager() internal view {
		if (msg.sender != authority.manager() && msg.sender != authority.governor())
			revert UNAUTHORIZED();
	}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";
import "../interfaces/IOptionRegistry.sol";
import "../interfaces/IAccounting.sol";
import "../interfaces/I_ERC20.sol";

interface ILiquidityPool is I_ERC20 {
	///////////////////////////
	/// immutable variables ///
	///////////////////////////
	function strikeAsset() external view returns (address);

	function underlyingAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	function collateralAllocated() external view returns (uint256);

	function ephemeralLiabilities() external view returns (int256);

	function ephemeralDelta() external view returns (int256);

	function depositEpoch() external view returns (uint256);

	function withdrawalEpoch() external view returns (uint256);

	function depositEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function withdrawalEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function depositReceipts(address depositor)
		external
		view
		returns (IAccounting.DepositReceipt memory);

	function withdrawalReceipts(address withdrawer)
		external
		view
		returns (IAccounting.WithdrawalReceipt memory);

	function pendingDeposits() external view returns (uint256);

	function pendingWithdrawals() external view returns (uint256);

	function partitionedFunds() external view returns (uint256);

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	function bufferPercentage() external view returns (uint256);

	function collateralCap() external view returns (uint256);

	/////////////////
	/// functions ///
	/////////////////

	function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address);

	function resetEphemeralValues() external;

	function getAssets() external view returns (uint256);

	function redeem(uint256) external returns (uint256);

	function handlerWriteOption(
		Types.OptionSeries memory optionSeries,
		address seriesAddress,
		uint256 amount,
		IOptionRegistry optionRegistry,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256);

	function handlerBuybackOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		IOptionRegistry optionRegistry,
		address seriesAddress,
		uint256 premium,
		int256 delta,
		address seller
	) external returns (uint256);

	function handlerIssueAndWriteOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256, address);

	function getPortfolioDelta() external view returns (int256);

	function quotePriceWithUtilizationGreeks(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		bool toBuy
	) external view returns (uint256 quote, int256 delta);

	function checkBuffer() external view returns (int256 bufferRemaining);

	function getBalance(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Reactors to hedge delta using means outside of the option pricing skew.

interface IHedgingReactor {
	/// @notice Execute a strategy to hedge delta exposure
	/// @param delta The exposure of the liquidity pool that the reactor needs to hedge against
	/// @return deltaChange The difference in delta exposure as a result of strategy execution
	function hedgeDelta(int256 delta) external returns (int256);

	/// @notice Returns the delta exposure of the reactor
	function getDelta() external view returns (int256 delta);

	/// @notice Returns the value of the reactor denominated in the liquidity pool asset
	/// @return value the value of the reactor in the liquidity pool asset
	function getPoolDenominatedValue() external view returns (uint256 value);

	/// @notice Withdraw a given asset from the hedging reactor to the calling liquidity pool.
	/// @param amount The amount to withdraw
	/// @return the amount actually withdrawn from the reactor denominated in the liquidity pool asset
	function withdraw(uint256 amount) external returns (uint256);

	/// @notice Handle events such as collateralisation rebalancing
	function update() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IClearingHouse } from '../interfaces/IClearingHouse.sol';
import { IExtsload } from '../interfaces/IExtsload.sol';
import { IOracle } from '../interfaces/IOracle.sol';
import { IVQuote } from '../interfaces/IVQuote.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';
import { IVToken } from '../interfaces/IVToken.sol';

import { Uint48Lib } from '../libraries/Uint48.sol';
import { WordHelper } from '../libraries/WordHelper.sol';

library ClearingHouseExtsload {
    // Terminology:
    // SLOT is a storage location value which can be sloaded, typed in bytes32.
    // OFFSET is an slot offset value which should not be sloaded, henced typed in uint256.

    using WordHelper for bytes32;
    using WordHelper for WordHelper.Word;

    /**
     * PROTOCOL
     */

    bytes32 constant PROTOCOL_SLOT = bytes32(uint256(100));
    uint256 constant PROTOCOL_POOLS_MAPPING_OFFSET = 0;
    uint256 constant PROTOCOL_COLLATERALS_MAPPING_OFFSET = 1;
    uint256 constant PROTOCOL_SETTLEMENT_TOKEN_OFFSET = 3;
    uint256 constant PROTOCOL_VQUOTE_OFFSET = 4;
    uint256 constant PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET = 5;
    uint256 constant PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET = 6;
    uint256 constant PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET = 7;
    uint256 constant PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET = 8;

    function _decodeLiquidationParamsSlot(bytes32 data)
        internal
        pure
        returns (IClearingHouse.LiquidationParams memory liquidationParams)
    {
        WordHelper.Word memory result = data.copyToMemory();
        liquidationParams.rangeLiquidationFeeFraction = result.popUint16();
        liquidationParams.tokenLiquidationFeeFraction = result.popUint16();
        liquidationParams.closeFactorMMThresholdBps = result.popUint16();
        liquidationParams.partialLiquidationCloseFactorBps = result.popUint16();
        liquidationParams.insuranceFundFeeShareBps = result.popUint16();
        liquidationParams.liquidationSlippageSqrtToleranceBps = result.popUint16();
        liquidationParams.maxRangeLiquidationFees = result.popUint64();
        liquidationParams.minNotionalLiquidatable = result.popUint64();
    }

    /// @notice Gets the protocol info, global protocol settings
    /// @return settlementToken the token in which profit is settled
    /// @return vQuote the vQuote token contract
    /// @return liquidationParams the liquidation parameters
    /// @return minRequiredMargin minimum required margin an account has to keep with non-zero netPosition
    /// @return removeLimitOrderFee the fee charged for using removeLimitOrder service
    /// @return minimumOrderNotional the minimum order notional
    function getProtocolInfo(IClearingHouse clearingHouse)
        internal
        view
        returns (
            IERC20 settlementToken,
            IVQuote vQuote,
            IClearingHouse.LiquidationParams memory liquidationParams,
            uint256 minRequiredMargin,
            uint256 removeLimitOrderFee,
            uint256 minimumOrderNotional
        )
    {
        bytes32[] memory arr = new bytes32[](6);
        arr[0] = PROTOCOL_SLOT.offset(PROTOCOL_SETTLEMENT_TOKEN_OFFSET);
        arr[1] = PROTOCOL_SLOT.offset(PROTOCOL_VQUOTE_OFFSET);
        arr[2] = PROTOCOL_SLOT.offset(PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET);
        arr[3] = PROTOCOL_SLOT.offset(PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET);
        arr[4] = PROTOCOL_SLOT.offset(PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET);
        arr[5] = PROTOCOL_SLOT.offset(PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET);
        arr = clearingHouse.extsload(arr);
        settlementToken = IERC20(arr[0].toAddress());
        vQuote = IVQuote(arr[1].toAddress());
        liquidationParams = _decodeLiquidationParamsSlot(arr[2]);
        minRequiredMargin = arr[3].toUint256();
        removeLimitOrderFee = arr[4].toUint256();
        minimumOrderNotional = arr[5].toUint256();
    }

    /**
     * PROTOCOL POOLS MAPPING
     */

    uint256 constant POOL_VTOKEN_OFFSET = 0;
    uint256 constant POOL_VPOOL_OFFSET = 1;
    uint256 constant POOL_VPOOLWRAPPER_OFFSET = 2;
    uint256 constant POOL_SETTINGS_STRUCT_OFFSET = 3;

    function poolStructSlot(uint32 poolId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: PROTOCOL_SLOT.offset(PROTOCOL_POOLS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(poolId)
            });
    }

    function _decodePoolSettingsSlot(bytes32 data) internal pure returns (IClearingHouse.PoolSettings memory settings) {
        WordHelper.Word memory result = data.copyToMemory();
        settings.initialMarginRatioBps = result.popUint16();
        settings.maintainanceMarginRatioBps = result.popUint16();
        settings.maxVirtualPriceDeviationRatioBps = result.popUint16();
        settings.twapDuration = result.popUint32();
        settings.isAllowedForTrade = result.popBool();
        settings.isCrossMargined = result.popBool();
        settings.oracle = IOracle(result.popAddress());
    }

    /// @notice Gets the info about a supported pool in the protocol
    /// @param poolId the id of the pool
    /// @return pool the Pool struct
    function getPoolInfo(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IClearingHouse.Pool memory pool)
    {
        bytes32 POOL_SLOT = poolStructSlot(poolId);
        bytes32[] memory arr = new bytes32[](4);
        arr[0] = POOL_SLOT; // POOL_VTOKEN_OFFSET
        arr[1] = POOL_SLOT.offset(POOL_VPOOL_OFFSET);
        arr[2] = POOL_SLOT.offset(POOL_VPOOLWRAPPER_OFFSET);
        arr[3] = POOL_SLOT.offset(POOL_SETTINGS_STRUCT_OFFSET);
        arr = clearingHouse.extsload(arr);
        pool.vToken = IVToken(arr[0].toAddress());
        pool.vPool = IUniswapV3Pool(arr[1].toAddress());
        pool.vPoolWrapper = IVPoolWrapper(arr[2].toAddress());
        pool.settings = _decodePoolSettingsSlot(arr[3]);
    }

    function getVPool(IClearingHouse clearingHouse, uint32 poolId) internal view returns (IUniswapV3Pool vPool) {
        bytes32 result = clearingHouse.extsload(poolStructSlot(poolId).offset(POOL_VPOOL_OFFSET));
        assembly {
            vPool := result
        }
    }

    function getPoolSettings(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IClearingHouse.PoolSettings memory)
    {
        bytes32 SETTINGS_SLOT = poolStructSlot(poolId).offset(POOL_SETTINGS_STRUCT_OFFSET);
        return _decodePoolSettingsSlot(clearingHouse.extsload(SETTINGS_SLOT));
    }

    function getTwapDuration(IClearingHouse clearingHouse, uint32 poolId) internal view returns (uint32 twapDuration) {
        bytes32 result = clearingHouse.extsload(poolStructSlot(poolId).offset(POOL_SETTINGS_STRUCT_OFFSET));
        twapDuration = result.slice(0x30, 0x50).toUint32();
    }

    function getVPoolAndTwapDuration(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IUniswapV3Pool vPool, uint32 twapDuration)
    {
        bytes32[] memory arr = new bytes32[](2);

        bytes32 POOL_SLOT = poolStructSlot(poolId);
        arr[0] = POOL_SLOT.offset(POOL_VPOOL_OFFSET); // vPool
        arr[1] = POOL_SLOT.offset(POOL_SETTINGS_STRUCT_OFFSET); // settings
        arr = clearingHouse.extsload(arr);

        vPool = IUniswapV3Pool(arr[0].toAddress());
        twapDuration = arr[1].slice(0xB0, 0xD0).toUint32();
    }

    /// @notice Checks if a poolId is unused
    /// @param poolId the id of the pool
    /// @return true if the poolId is unused, false otherwise
    function isPoolIdAvailable(IClearingHouse clearingHouse, uint32 poolId) internal view returns (bool) {
        bytes32 VTOKEN_SLOT = poolStructSlot(poolId).offset(POOL_VTOKEN_OFFSET);
        bytes32 result = clearingHouse.extsload(VTOKEN_SLOT);
        return result == WordHelper.fromUint(0);
    }

    /**
     * PROTOCOL COLLATERALS MAPPING
     */

    uint256 constant COLLATERAL_TOKEN_OFFSET = 0;
    uint256 constant COLLATERAL_SETTINGS_OFFSET = 1;

    function collateralStructSlot(uint32 collateralId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: PROTOCOL_SLOT.offset(PROTOCOL_COLLATERALS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(collateralId)
            });
    }

    function _decodeCollateralSettings(bytes32 data)
        internal
        pure
        returns (IClearingHouse.CollateralSettings memory settings)
    {
        WordHelper.Word memory result = data.copyToMemory();
        settings.oracle = IOracle(result.popAddress());
        settings.twapDuration = result.popUint32();
        settings.isAllowedForDeposit = result.popBool();
    }

    /// @notice Gets the info about a supported collateral in the protocol
    /// @param collateralId the id of the collateral
    /// @return collateral the Collateral struct
    function getCollateralInfo(IClearingHouse clearingHouse, uint32 collateralId)
        internal
        view
        returns (IClearingHouse.Collateral memory collateral)
    {
        bytes32[] memory arr = new bytes32[](2);
        bytes32 COLLATERAL_STRUCT_SLOT = collateralStructSlot(collateralId);
        arr[0] = COLLATERAL_STRUCT_SLOT; // COLLATERAL_TOKEN_OFFSET
        arr[1] = COLLATERAL_STRUCT_SLOT.offset(COLLATERAL_SETTINGS_OFFSET);
        arr = clearingHouse.extsload(arr);
        collateral.token = IVToken(arr[0].toAddress());
        collateral.settings = _decodeCollateralSettings(arr[1]);
    }

    /**
     * ACCOUNT MAPPING
     */
    bytes32 constant ACCOUNTS_MAPPING_SLOT = bytes32(uint256(211));
    uint256 constant ACCOUNT_ID_OWNER_OFFSET = 0;
    uint256 constant ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET = 1;
    uint256 constant ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET = 2;
    uint256 constant ACCOUNT_VQUOTE_BALANCE_OFFSET = 3;
    uint256 constant ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET = 104;
    uint256 constant ACCOUNT_COLLATERAL_MAPPING_OFFSET = 105;

    // VTOKEN POSITION STRUCT
    uint256 constant ACCOUNT_VTOKENPOSITION_BALANCE_OFFSET = 0;
    uint256 constant ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET = 1;
    uint256 constant ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET = 2;
    uint256 constant ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET = 3;
    uint256 constant ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET = 4;

    // LIQUIDITY POSITION STRUCT
    uint256 constant ACCOUNT_TP_LP_SLOT0_OFFSET = 0; // limit order type, tl, tu, liquidity
    uint256 constant ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET = 1;
    uint256 constant ACCOUNT_TP_LP_SUM_A_LAST_OFFSET = 2;
    uint256 constant ACCOUNT_TP_LP_SUM_B_LAST_OFFSET = 3;
    uint256 constant ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET = 4;
    uint256 constant ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET = 5;

    function accountStructSlot(uint256 accountId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({ mappingSlot: ACCOUNTS_MAPPING_SLOT, paddedKey: WordHelper.fromUint(accountId) });
    }

    function accountCollateralStructSlot(bytes32 ACCOUNT_STRUCT_SLOT, uint32 collateralId)
        internal
        pure
        returns (bytes32)
    {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_STRUCT_SLOT.offset(ACCOUNT_COLLATERAL_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(collateralId)
            });
    }

    function accountVTokenPositionStructSlot(bytes32 ACCOUNT_STRUCT_SLOT, uint32 poolId)
        internal
        pure
        returns (bytes32)
    {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(poolId)
            });
    }

    function accountLiquidityPositionStructSlot(
        bytes32 ACCOUNT_VTOKENPOSITION_STRUCT_SLOT,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_VTOKENPOSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(Uint48Lib.concat(tickLower, tickUpper))
            });
    }

    function getAccountInfo(IClearingHouse clearingHouse, uint256 accountId)
        internal
        view
        returns (
            address owner,
            int256 vQuoteBalance,
            uint32[] memory activeCollateralIds,
            uint32[] memory activePoolIds
        )
    {
        bytes32[] memory arr = new bytes32[](4);
        bytes32 ACCOUNT_SLOT = accountStructSlot(accountId);
        arr[0] = ACCOUNT_SLOT; // ACCOUNT_ID_OWNER_OFFSET
        arr[1] = ACCOUNT_SLOT.offset(ACCOUNT_VQUOTE_BALANCE_OFFSET);
        arr[2] = ACCOUNT_SLOT.offset(ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET);
        arr[3] = ACCOUNT_SLOT.offset(ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET);

        arr = clearingHouse.extsload(arr);

        owner = arr[0].slice(0, 160).toAddress();
        vQuoteBalance = arr[1].toInt256();
        activeCollateralIds = arr[2].convertToUint32Array();
        activePoolIds = arr[3].convertToUint32Array();
    }

    function getAccountCollateralInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 collateralId
    ) internal view returns (IERC20 collateral, uint256 balance) {
        bytes32[] memory arr = new bytes32[](2);
        arr[0] = accountCollateralStructSlot(accountStructSlot(accountId), collateralId); // ACCOUNT_COLLATERAL_BALANCE_SLOT
        arr[1] = collateralStructSlot(collateralId); // COLLATERAL_TOKEN_ADDRESS_SLOT

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toUint256();
        collateral = IERC20(arr[1].toAddress());
    }

    function getAccountCollateralBalance(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 collateralId
    ) internal view returns (uint256 balance) {
        bytes32 COLLATERAL_BALANCE_SLOT = accountCollateralStructSlot(accountStructSlot(accountId), collateralId);

        balance = clearingHouse.extsload(COLLATERAL_BALANCE_SLOT).toUint256();
    }

    function getAccountTokenPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    )
        internal
        view
        returns (
            int256 balance,
            int256 netTraderPosition,
            int256 sumALastX128
        )
    {
        bytes32 VTOKEN_POSITION_STRUCT_SLOT = accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId);

        bytes32[] memory arr = new bytes32[](3);
        arr[0] = VTOKEN_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET);
        arr[2] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET);

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toInt256();
        netTraderPosition = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
    }

    function getAccountPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    )
        internal
        view
        returns (
            int256 balance,
            int256 netTraderPosition,
            int256 sumALastX128,
            IClearingHouse.TickRange[] memory activeTickRanges
        )
    {
        bytes32 VTOKEN_POSITION_STRUCT_SLOT = accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId);

        bytes32[] memory arr = new bytes32[](4);
        arr[0] = VTOKEN_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET);
        arr[2] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET);
        arr[3] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET);

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toInt256();
        netTraderPosition = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
        activeTickRanges = arr[3].convertToTickRangeArray();
    }

    function getAccountLiquidityPositionList(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    ) internal view returns (IClearingHouse.TickRange[] memory activeTickRanges) {
        return
            clearingHouse
                .extsload(
                    accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId).offset(
                        ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET
                    )
                )
                .convertToTickRangeArray();
    }

    function getAccountLiquidityPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        view
        returns (
            uint8 limitOrderType,
            uint128 liquidity,
            int256 vTokenAmountIn,
            int256 sumALastX128,
            int256 sumBInsideLastX128,
            int256 sumFpInsideLastX128,
            uint256 sumFeeInsideLastX128
        )
    {
        bytes32 LIQUIDITY_POSITION_STRUCT_SLOT = accountLiquidityPositionStructSlot(
            accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId),
            tickLower,
            tickUpper
        );

        bytes32[] memory arr = new bytes32[](6);
        arr[0] = LIQUIDITY_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET);
        arr[2] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_A_LAST_OFFSET);
        arr[3] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_B_LAST_OFFSET);
        arr[4] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET);
        arr[5] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET);

        arr = clearingHouse.extsload(arr);

        WordHelper.Word memory slot0 = arr[0].copyToMemory();
        limitOrderType = slot0.popUint8();
        slot0.pop(48); // discard 48 bits
        liquidity = slot0.popUint128();
        vTokenAmountIn = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
        sumBInsideLastX128 = arr[3].toInt256();
        sumFpInsideLastX128 = arr[4].toInt256();
        sumFeeInsideLastX128 = arr[5].toUint256();
    }

    function _getProtocolSlot() internal pure returns (bytes32) {
        return PROTOCOL_SLOT;
    }

    function _getProtocolOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            PROTOCOL_POOLS_MAPPING_OFFSET,
            PROTOCOL_COLLATERALS_MAPPING_OFFSET,
            PROTOCOL_SETTLEMENT_TOKEN_OFFSET,
            PROTOCOL_VQUOTE_OFFSET,
            PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET,
            PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET,
            PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET,
            PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET
        );
    }

    function _getPoolOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (POOL_VTOKEN_OFFSET, POOL_VPOOL_OFFSET, POOL_VPOOLWRAPPER_OFFSET, POOL_SETTINGS_STRUCT_OFFSET);
    }

    function _getCollateralOffsets() internal pure returns (uint256, uint256) {
        return (COLLATERAL_TOKEN_OFFSET, COLLATERAL_SETTINGS_OFFSET);
    }

    function _getAccountsMappingSlot() internal pure returns (bytes32) {
        return ACCOUNTS_MAPPING_SLOT;
    }

    function _getAccountOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_ID_OWNER_OFFSET,
            ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET,
            ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET,
            ACCOUNT_VQUOTE_BALANCE_OFFSET,
            ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET,
            ACCOUNT_COLLATERAL_MAPPING_OFFSET
        );
    }

    function _getVTokenPositionOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_VTOKENPOSITION_BALANCE_OFFSET,
            ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET,
            ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET,
            ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET,
            ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET
        );
    }

    function _getLiquidityPositionOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_TP_LP_SLOT0_OFFSET,
            ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET,
            ACCOUNT_TP_LP_SUM_A_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_B_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IGovernable } from './IGovernable.sol';

import { IClearingHouseActions } from './clearinghouse/IClearingHouseActions.sol';
import { IClearingHouseCustomErrors } from './clearinghouse/IClearingHouseCustomErrors.sol';
import { IClearingHouseEnums } from './clearinghouse/IClearingHouseEnums.sol';
import { IClearingHouseEvents } from './clearinghouse/IClearingHouseEvents.sol';
import { IClearingHouseOwnerActions } from './clearinghouse/IClearingHouseOwnerActions.sol';
import { IClearingHouseStructures } from './clearinghouse/IClearingHouseStructures.sol';
import { IClearingHouseSystemActions } from './clearinghouse/IClearingHouseSystemActions.sol';
import { IClearingHouseView } from './clearinghouse/IClearingHouseView.sol';

interface IClearingHouse is
    IGovernable,
    IClearingHouseEnums,
    IClearingHouseStructures,
    IClearingHouseActions,
    IClearingHouseCustomErrors,
    IClearingHouseEvents,
    IClearingHouseOwnerActions,
    IClearingHouseSystemActions,
    IClearingHouseView
{}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to);
	event GuardianPushed(address indexed to);
	event ManagerPushed(address indexed from, address indexed to);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianRevoked(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Types {
	struct OptionSeries {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		address underlying;
		address strikeAsset;
		address collateral;
	}
	struct PortfolioValues {
		int256 delta;
		int256 gamma;
		int256 vega;
		int256 theta;
		int256 callPutsValue;
		uint256 timestamp;
		uint256 spotPrice;
	}
	struct Order {
		OptionSeries optionSeries;
		uint256 amount;
		uint256 price;
		uint256 orderExpiry;
		address buyer;
		address seriesAddress;
		uint128 lowerSpotMovementRange;
		uint128 upperSpotMovementRange;
		bool isBuyBack;
	}
	// strike and expiry date range for options
	struct OptionParams {
		uint128 minCallStrikePrice;
		uint128 maxCallStrikePrice;
		uint128 minPutStrikePrice;
		uint128 maxPutStrikePrice;
		uint128 minExpiry;
		uint128 maxExpiry;
	}

	struct UtilizationState {
		uint256 totalOptionPrice; //e18
		int256 totalDelta; // e18
		uint256 collateralToAllocate; //collateral decimals
		uint256 utilizationBefore; // e18
		uint256 utilizationAfter; //e18
		uint256 utilizationPrice; //e18
		bool isDecreased;
		uint256 deltaTiltAmount; //e18
		uint256 underlyingPrice; // strike asset decimals
		uint256 iv; // e18
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import { NormalDist } from "./NormalDist.sol";

/**
 *  @title Library used to calculate an option price using Black Scholes
 */
library BlackScholes {
	using PRBMathSD59x18 for int256;
	using PRBMathSD59x18 for int8;
	using PRBMathUD60x18 for uint256;

	uint256 private constant ONE_YEAR_SECONDS = 31557600;
	uint256 private constant ONE = 1000000000000000000;
	uint256 private constant TWO = 2000000000000000000;

	struct Intermediates {
		uint256 d1Denominator;
		int256 d1;
		int256 eToNegRT;
	}

	function callOptionPrice(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256) {
		int256 d2 = d1 - d1Denominator;
		int256 cdfD1 = NormalDist.cdf(d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(priceCdf >= strikeBy);
		return uint256(priceCdf - strikeBy);
	}

	function callOptionPriceGreeks(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256 quote, int256 delta) {
		int256 d2 = d1 - d1Denominator;
		int256 cdfD1 = NormalDist.cdf(d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(priceCdf >= strikeBy);
		quote = uint256(priceCdf - strikeBy);
		delta = cdfD1;
	}

	function putOptionPriceGreeks(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256 quote, int256 delta) {
		int256 d2 = d1Denominator - d1;
		int256 cdfD1 = NormalDist.cdf(-d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(strikeBy >= priceCdf);
		quote = uint256(strikeBy - priceCdf);
		delta = -cdfD1;
	}

	function putOptionPrice(
		int256 d1,
		int256 d1Denominator,
		int256 price,
		int256 strike,
		int256 eToNegRT
	) public pure returns (uint256) {
		int256 d2 = d1Denominator - d1;
		int256 cdfD1 = NormalDist.cdf(-d1);
		int256 cdfD2 = NormalDist.cdf(d2);
		int256 priceCdf = price.mul(cdfD1);
		int256 strikeBy = strike.mul(eToNegRT).mul(cdfD2);
		assert(strikeBy >= priceCdf);
		return uint256(strikeBy - priceCdf);
	}

	function getTimeStamp() private view returns (uint256) {
		return block.timestamp;
	}

	function getD1(
		uint256 price,
		uint256 strike,
		uint256 time,
		uint256 vol,
		uint256 rfr
	) private pure returns (int256 d1, uint256 d1Denominator) {
		uint256 d1Right = (vol.mul(vol).div(TWO) + rfr).mul(time);
		int256 d1Left = int256(price.div(strike)).ln();
		int256 d1Numerator = d1Left + int256(d1Right);
		d1Denominator = vol.mul(time.sqrt());
		d1 = d1Numerator.div(int256(d1Denominator));
	}

	function getIntermediates(
		uint256 price,
		uint256 strike,
		uint256 time,
		uint256 vol,
		uint256 rfr
	) private pure returns (Intermediates memory) {
		(int256 d1, uint256 d1Denominator) = getD1(price, strike, time, vol, rfr);
		return
			Intermediates({
				d1Denominator: d1Denominator,
				d1: d1,
				eToNegRT: (int256(rfr).mul(int256(time)).mul(-int256(ONE))).exp()
			});
	}

	function blackScholesCalc(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (uint256) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		Intermediates memory i = getIntermediates(price, strike, time, vol, rfr);
		if (!isPut) {
			return
				callOptionPrice(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		} else {
			return
				putOptionPrice(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		}
	}

	function blackScholesCalcGreeks(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (uint256 quote, int256 delta) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		Intermediates memory i = getIntermediates(price, strike, time, vol, rfr);
		if (!isPut) {
			return
				callOptionPriceGreeks(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		} else {
			return
				putOptionPriceGreeks(
					int256(i.d1),
					int256(i.d1Denominator),
					int256(price),
					int256(strike),
					i.eToNegRT
				);
		}
	}

	function getDelta(
		uint256 price,
		uint256 strike,
		uint256 expiration,
		uint256 vol,
		uint256 rfr,
		bool isPut
	) public view returns (int256) {
		uint256 time = (expiration - getTimeStamp()).div(ONE_YEAR_SECONDS);
		(int256 d1, ) = getD1(price, strike, time, vol, rfr);
		if (!isPut) {
			return NormalDist.cdf(d1);
		} else {
			return -NormalDist.cdf(-d1);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface CustomErrors {
	error NotKeeper();
	error IVNotFound();
	error NotHandler();
	error VaultExpired();
	error InvalidInput();
	error InvalidPrice();
	error InvalidBuyer();
	error InvalidOrder();
	error OrderExpired();
	error InvalidAmount();
	error TradingPaused();
	error InvalidAddress();
	error IssuanceFailed();
	error EpochNotClosed();
	error InvalidDecimals();
	error TradingNotPaused();
	error NotLiquidityPool();
	error DeltaNotDecreased();
	error NonExistentOtoken();
	error OrderExpiryTooLong();
	error InvalidShareAmount();
	error ExistingWithdrawal();
	error TotalSupplyReached();
	error StrikeAssetInvalid();
	error OptionStrikeInvalid();
	error OptionExpiryInvalid();
	error NoExistingWithdrawal();
	error SpotMovedBeyondRange();
	error ReactorAlreadyExists();
	error CollateralAssetInvalid();
	error UnderlyingAssetInvalid();
	error CollateralAmountInvalid();
	error WithdrawExceedsLiquidity();
	error InsufficientShareBalance();
	error MaxLiquidityBufferReached();
	error LiabilitiesGreaterThanAssets();
	error CustomOrderInsufficientPrice();
	error CustomOrderInvalidDeltaValue();
	error DeltaQuoteError(uint256 quote, int256 delta);
	error TimeDeltaExceedsThreshold(uint256 timeDelta);
	error PriceDeltaExceedsThreshold(uint256 priceDelta);
	error StrikeAmountExceedsLiquidity(uint256 strikeAmount, uint256 strikeLiquidity);
	error MinStrikeAmountExceedsLiquidity(uint256 strikeAmount, uint256 strikeAmountMin);
	error UnderlyingAmountExceedsLiquidity(uint256 underlyingAmount, uint256 underlyingLiquidity);
	error MinUnderlyingAmountExceedsLiquidity(uint256 underlyingAmount, uint256 underlyingAmountMin);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title Library used for approximating a normal distribution
 */
library NormalDist {
	using PRBMathSD59x18 for int256;

	int256 private constant ONE = 1000000000000000000;
	int256 private constant ONE_HALF = 500000000000000000;
	int256 private constant SQRT_TWO = 1414213562373095048;
	// z-scores
	// A1 0.254829592
	int256 private constant A1 = 254829592000000000;
	// A2 -0.284496736
	int256 private constant A2 = -284496736000000000;
	// A3 1.421413741
	int256 private constant A3 = 1421413741000000000;
	// A4 -1.453152027
	int256 private constant A4 = -1453152027000000000;
	// A5 1.061405429
	int256 private constant A5 = 1061405429000000000;
	// P 0.3275911
	int256 private constant P = 327591100000000000;

	function cdf(int256 x) public pure returns (int256) {
		int256 phiParam = x.div(SQRT_TWO);
		int256 onePlusPhi = ONE + (phi(phiParam));
		return ONE_HALF.mul(onePlusPhi);
	}

	function phi(int256 x) public pure returns (int256) {
		int256 sign = x >= 0 ? ONE : -ONE;
		int256 abs = x.abs();

		// A&S formula 7.1.26
		int256 t = ONE.div(ONE + (P.mul(abs)));
		int256 scoresByT = getScoresFromT(t);
		int256 eToXs = abs.mul(-ONE).mul(abs).exp();
		int256 y = ONE - (scoresByT.mul(eToXs));
		return sign.mul(y);
	}

	function getScoresFromT(int256 t) public pure returns (int256) {
		int256 byA5T = A5.mul(t);
		int256 byA4T = (byA5T + A4).mul(t);
		int256 byA3T = (byA4T + A3).mul(t);
		int256 byA2T = (byA3T + A2).mul(t);
		int256 byA1T = (byA2T + A1).mul(t);
		return byA1T;
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Accounting contract to calculate the dhv token value and handle deposit/withdraw mechanics

interface IAccounting {
	struct DepositReceipt {
		uint128 epoch;
		uint128 amount; // collateral decimals
		uint256 unredeemedShares; // e18
	}

	struct WithdrawalReceipt {
		uint128 epoch;
		uint128 shares; // e18
	}

	/**
	 * @notice logic for adding liquidity to the options liquidity pool
	 * @param  depositor the address making the deposit
	 * @param  _amount amount of the collateral asset to deposit
	 * @return depositAmount the amount to deposit from the round
	 * @return unredeemedShares number of shares held in the deposit receipt that havent been redeemed
	 */
	function deposit(address depositor, uint256 _amount)
		external
		returns (uint256 depositAmount, uint256 unredeemedShares);

	/**
	 * @notice logic for allowing a user to redeem their shares from a previous epoch
	 * @param  redeemer the address making the deposit
	 * @param  shares amount of the collateral asset to deposit
	 * @return toRedeem the amount to actually redeem
	 * @return depositReceipt the updated deposit receipt after the redeem has completed
	 */
	function redeem(address redeemer, uint256 shares)
		external
		returns (uint256 toRedeem, DepositReceipt memory depositReceipt);

	/**
	 * @notice logic for accounting a user to initiate a withdraw request from the pool
	 * @param  withdrawer the address carrying out the withdrawal
	 * @param  shares the amount of shares to withdraw for
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function initiateWithdraw(address withdrawer, uint256 shares)
		external
		returns (WithdrawalReceipt memory withdrawalReceipt);

	/**
	 * @notice logic for accounting a user to complete a withdrawal
	 * @param  withdrawer the address carrying out the withdrawal
	 * @return withdrawalAmount  the amount of collateral to withdraw
	 * @return withdrawalShares  the number of shares to withdraw
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function completeWithdraw(address withdrawer)
		external
		returns (
			uint256 withdrawalAmount,
			uint256 withdrawalShares,
			WithdrawalReceipt memory withdrawalReceipt
		);

	/**
	 * @notice execute the next epoch
	 * @param totalSupply  the total number of share tokens
	 * @param assets the amount of collateral assets
	 * @param liabilities the amount of liabilities of the pool
	 * @return newPricePerShareDeposit the price per share for deposits
	 * @return newPricePerShareWithdrawal the price per share for withdrawals
	 * @return sharesToMint the number of shares to mint this epoch
	 * @return totalWithdrawAmount the amount of collateral to set aside for partitioning
	 * @return amountNeeded the amount needed to reach the total withdraw amount if collateral balance of lp is insufficient
	 */
	function executeEpochCalculation(
		uint256 totalSupply,
		uint256 assets,
		int256 liabilities
	)
		external
		view
		returns (
			uint256 newPricePerShareDeposit,
			uint256 newPricePerShareWithdrawal,
			uint256 sharesToMint,
			uint256 totalWithdrawAmount,
			uint256 amountNeeded
		);

	/**
	 * @notice get the number of shares for a given amount
	 * @param _amount  the amount to convert to shares - assumed in collateral decimals
	 * @param assetPerShare the amount of assets received per share
	 * @return shares the number of shares based on the amount - assumed in e18
	 */
	function sharesForAmount(uint256 _amount, uint256 assetPerShare)
		external
		view
		returns (uint256 shares);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";

interface IOptionRegistry {
	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param  optionSeries option series to issue
	 * @return the address of the option
	 */
	function issue(Types.OptionSeries memory optionSeries) external returns (address);

	/**
	 * @notice Open an options contract using collateral from the liquidity pool
	 * @param  _series the address of the option token to be created
	 * @param  amount the amount of options to deploy
	 * @param  collateralAmount the collateral required for the option
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 * @return the amount of collateral taken from the liquidityPool
	 */
	function open(
		address _series,
		uint256 amount,
		uint256 collateralAmount
	) external returns (bool, uint256);

	/**
	 * @notice Close an options contract (oToken) before it has expired
	 * @param  _series the address of the option token to be burnt
	 * @param  amount the amount of options to burn
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 */
	function close(address _series, uint256 amount) external returns (bool, uint256);

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice Settle an options vault
	 * @param  _series the address of the option token to be burnt
	 * @return success if the transaction succeeded
	 * @return collatReturned the amount of collateral returned from the vault
	 * @return collatLost the amount of collateral used to pay ITM options on vault settle
	 * @return amountShort number of oTokens that the vault was short
	 * @dev callable by anyone but returns funds to the liquidityPool
	 */
	function settle(address _series)
		external
		returns (
			bool success,
			uint256 collatReturned,
			uint256 collatLost,
			uint256 amountShort
		);

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice Send collateral funds for an option to be minted
	 * @dev series.strike should be scaled by 1e8.
	 * @param  series details of the option series
	 * @param  amount amount of options to mint
	 * @return amount transferred
	 */
	function getCollateral(Types.OptionSeries memory series, uint256 amount)
		external
		view
		returns (uint256);

	/**
	 * @notice Retrieves the option token if it exists
	 * @param  underlying is the address of the underlying asset of the option
	 * @param  strikeAsset is the address of the collateral asset of the option
	 * @param  expiration is the expiry timestamp of the option
	 * @param  isPut the type of option
	 * @param  strike is the strike price of the option - 1e18 format
	 * @param  collateral is the address of the asset to collateralize the option with
	 * @return the address of the option
	 */
	function getOtoken(
		address underlying,
		address strikeAsset,
		uint256 expiration,
		bool isPut,
		uint256 strike,
		address collateral
	) external view returns (address);

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getSeriesInfo(address series) external view returns (Types.OptionSeries memory);
	function vaultIds(address series) external view returns (uint256);
	function gammaController() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface I_ERC20 {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title This is an interface to read contract's state that supports extsload.
interface IExtsload {
    /// @notice Returns a value from the storage.
    /// @param slot to read from.
    /// @return value stored at the slot.
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Returns multiple values from storage.
    /// @param slots to read from.
    /// @return values stored at the slots.
    function extsload(bytes32[] memory slots) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOracle {
    function getTwapPriceX128(uint32 twapDuration) external view returns (uint256 priceX128);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function setVPoolWrapper(address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IVQuote } from './IVQuote.sol';
import { IVToken } from './IVToken.sol';

interface IVPoolWrapper {
    struct InitializeVPoolWrapperParams {
        address clearingHouse; // address of clearing house contract (proxy)
        IVToken vToken; // address of vToken contract
        IVQuote vQuote; // address of vQuote contract
        IUniswapV3Pool vPool; // address of Uniswap V3 Pool contract, created using vToken and vQuote
        uint24 liquidityFeePips; // liquidity fee fraction (in 1e6)
        uint24 protocolFeePips; // protocol fee fraction (in 1e6)
    }

    struct SwapResult {
        int256 amountSpecified; // amount of tokens/vQuote which were specified in the swap request
        int256 vTokenIn; // actual amount of vTokens paid by account to the Pool
        int256 vQuoteIn; // actual amount of vQuotes paid by account to the Pool
        uint256 liquidityFees; // actual amount of fees paid by account to the Pool
        uint256 protocolFees; // actual amount of fees paid by account to the Protocol
        uint160 sqrtPriceX96Start; // sqrt price at the beginning of the swap
        uint160 sqrtPriceX96End; // sqrt price at the end of the swap
    }

    struct WrapperValuesInside {
        int256 sumAX128; // sum of all the A terms in the pool
        int256 sumBInsideX128; // sum of all the B terms in side the tick range in the pool
        int256 sumFpInsideX128; // sum of all the Fp terms in side the tick range in the pool
        uint256 sumFeeInsideX128; // sum of all the fee terms in side the tick range in the pool
    }

    /// @notice Emitted whenever a swap takes place
    /// @param swapResult the swap result values
    event Swap(SwapResult swapResult);

    /// @notice Emitted whenever liquidity is added
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was added
    /// @param vTokenPrincipal the amount of vToken that was sent to UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was sent to UniswapV3Pool
    event Mint(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever liquidity is removed
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was removed
    /// @param vTokenPrincipal the amount of vToken that was received from UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was received from UniswapV3Pool
    event Burn(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever clearing house enquired about the accrued protocol fees
    /// @param amount the amount of accrued protocol fees
    event AccruedProtocolFeeCollected(uint256 amount);

    /// @notice Emitted when governance updates the liquidity fees
    /// @param liquidityFeePips the new liquidity fee ratio
    event LiquidityFeeUpdated(uint24 liquidityFeePips);

    /// @notice Emitted when governance updates the protocol fees
    /// @param protocolFeePips the new protocol fee ratio
    event ProtocolFeeUpdated(uint24 protocolFeePips);

    /// @notice Emitted when funding rate override is updated
    /// @param fundingRateOverrideX128 the new funding rate override value
    event FundingRateOverrideUpdated(int256 fundingRateOverrideX128);

    function initialize(InitializeVPoolWrapperParams memory params) external;

    function vPool() external view returns (IUniswapV3Pool);

    function getValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function getExtrapolatedValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function swap(
        bool swapVTokenForVQuote, // zeroForOne
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (SwapResult memory swapResult);

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function getSumAX128() external view returns (int256);

    function getExtrapolatedSumAX128() external view returns (int256);

    function liquidityFeePips() external view returns (uint24);

    function protocolFeePips() external view returns (uint24);

    /// @notice Used by clearing house to update funding rate when clearing house is paused or unpaused.
    /// @param useZeroFundingRate: used to discount funding payment during the duration ch was paused.
    function updateGlobalFundingState(bool useZeroFundingRate) external;

    /// @notice Used by clearing house to know how much protocol fee was collected.
    /// @return accruedProtocolFeeLast amount of protocol fees accrued since last collection.
    /// @dev Does not do any token transfer, just reduces the state in wrapper by accruedProtocolFeeLast.
    ///     Clearing house already has the amount of settlement tokens to send to treasury.
    function collectAccruedProtocolFee() external returns (uint256 accruedProtocolFeeLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVQuote is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function authorize(address vPoolWrapper) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title Uint48 concating functions
library Uint48Lib {
    /// @notice Packs two int24 values into uint48
    /// @dev Used for concating two ticks into 48 bits value
    /// @param val1 First 24 bits value
    /// @param val2 Second 24 bits value
    /// @return concatenated value
    function concat(int24 val1, int24 val2) internal pure returns (uint48 concatenated) {
        assembly {
            concatenated := add(shl(24, val1), and(val2, 0x000000ffffff))
        }
    }

    /// @notice Unpacks uint48 into two int24 values
    /// @dev Used for unpacking 48 bits value into two 24 bits values
    /// @param concatenated 48 bits value
    /// @return val1 First 24 bits value
    /// @return val2 Second 24 bits value
    function unconcat(uint48 concatenated) internal pure returns (int24 val1, int24 val2) {
        assembly {
            val2 := concatenated
            val1 := shr(24, concatenated)
        }
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

pragma solidity >=0.5.0;

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';

import { Uint48Lib } from '../libraries/Uint48.sol';

library WordHelper {
    using WordHelper for bytes32;

    struct Word {
        bytes32 data;
    }

    // struct Word methods

    function copyToMemory(bytes32 data) internal pure returns (Word memory) {
        return Word(data);
    }

    function pop(Word memory input, uint256 bits) internal pure returns (uint256 value) {
        (value, input.data) = pop(input.data, bits);
    }

    function popAddress(Word memory input) internal pure returns (address value) {
        (value, input.data) = popAddress(input.data);
    }

    function popUint8(Word memory input) internal pure returns (uint8 value) {
        (value, input.data) = popUint8(input.data);
    }

    function popUint16(Word memory input) internal pure returns (uint16 value) {
        (value, input.data) = popUint16(input.data);
    }

    function popUint32(Word memory input) internal pure returns (uint32 value) {
        (value, input.data) = popUint32(input.data);
    }

    function popUint64(Word memory input) internal pure returns (uint64 value) {
        (value, input.data) = popUint64(input.data);
    }

    function popUint128(Word memory input) internal pure returns (uint128 value) {
        (value, input.data) = popUint128(input.data);
    }

    function popBool(Word memory input) internal pure returns (bool value) {
        (value, input.data) = popBool(input.data);
    }

    function slice(
        Word memory input,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes32 val) {
        return slice(input.data, start, end);
    }

    // primitive uint256 methods

    function fromUint(uint256 input) internal pure returns (bytes32 output) {
        assembly {
            output := input
        }
    }

    // primitive bytes32 methods

    function keccak256One(bytes32 input) internal pure returns (bytes32 result) {
        assembly {
            mstore(0, input)
            result := keccak256(0, 0x20)
        }
    }

    function keccak256Two(bytes32 paddedKey, bytes32 mappingSlot) internal pure returns (bytes32 result) {
        assembly {
            mstore(0, paddedKey)
            mstore(0x20, mappingSlot)
            result := keccak256(0, 0x40)
        }
    }

    function offset(bytes32 key, uint256 offset_) internal pure returns (bytes32) {
        assembly {
            key := add(key, offset_)
        }
        return key;
    }

    function slice(
        bytes32 input,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes32 val) {
        assembly {
            val := shl(start, input)
            val := shr(add(start, sub(256, end)), val)
        }
    }

    /// @notice pops bits from the right side of the input
    /// @dev E.g. input = 0x0102030405060708091011121314151617181920212223242526272829303132
    ///          input.pop(16) -> 0x3132
    ///          input.pop(16) -> 0x2930
    ///          input -> 0x0000000001020304050607080910111213141516171819202122232425262728
    /// @dev this does not throw on underflow, value returned would be zero
    /// @param input the input bytes
    /// @param bits the number of bits to pop
    /// @return value of the popped bits
    /// @return inputUpdated the input bytes shifted right by bits
    function pop(bytes32 input, uint256 bits) internal pure returns (uint256 value, bytes32 inputUpdated) {
        assembly {
            let shift := sub(256, bits)
            value := shr(shift, shl(shift, input))
            inputUpdated := shr(bits, input)
        }
    }

    function popAddress(bytes32 input) internal pure returns (address value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 160);
        assembly {
            value := temp
        }
    }

    function popUint8(bytes32 input) internal pure returns (uint8 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 8);
        value = uint8(temp);
    }

    function popUint16(bytes32 input) internal pure returns (uint16 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 16);
        value = uint16(temp);
    }

    function popUint32(bytes32 input) internal pure returns (uint32 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 32);
        value = uint32(temp);
    }

    function popUint64(bytes32 input) internal pure returns (uint64 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 64);
        value = uint64(temp);
    }

    function popUint128(bytes32 input) internal pure returns (uint128 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 128);
        value = uint128(temp);
    }

    function popBool(bytes32 input) internal pure returns (bool value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 8);
        value = temp != 0;
    }

    function toAddress(bytes32 input) internal pure returns (address value) {
        return address(toUint160(input));
    }

    function toUint8(bytes32 input) internal pure returns (uint8 value) {
        return uint8(toUint256(input));
    }

    function toUint16(bytes32 input) internal pure returns (uint16 value) {
        return uint16(toUint256(input));
    }

    function toUint32(bytes32 input) internal pure returns (uint32 value) {
        return uint32(toUint256(input));
    }

    function toUint48(bytes32 input) internal pure returns (uint48 value) {
        return uint48(toUint256(input));
    }

    function toUint64(bytes32 input) internal pure returns (uint64 value) {
        return uint64(toUint256(input));
    }

    function toUint128(bytes32 input) internal pure returns (uint128 value) {
        return uint128(toUint256(input));
    }

    function toUint160(bytes32 input) internal pure returns (uint160 value) {
        return uint160(toUint256(input));
    }

    function toUint256(bytes32 input) internal pure returns (uint256 value) {
        assembly {
            value := input
        }
    }

    function toInt256(bytes32 input) internal pure returns (int256 value) {
        assembly {
            value := input
        }
    }

    function toBool(bytes32 input) internal pure returns (bool value) {
        (value, ) = popBool(input);
    }

    bytes32 constant ZERO = bytes32(uint256(0));

    function convertToUint32Array(bytes32 active) internal pure returns (uint32[] memory activeArr) {
        unchecked {
            uint256 i = 8;
            while (i > 0) {
                bytes32 id = active.slice((i - 1) * 32, i * 32);
                if (id == ZERO) {
                    break;
                }
                i--;
            }
            activeArr = new uint32[](8 - i);
            while (i < 8) {
                activeArr[7 - i] = active.slice(i * 32, (i + 1) * 32).toUint32();
                i++;
            }
        }
    }

    function convertToTickRangeArray(bytes32 active)
        internal
        pure
        returns (IClearingHouseStructures.TickRange[] memory activeArr)
    {
        unchecked {
            uint256 i = 5;
            while (i > 0) {
                bytes32 id = active.slice((i - 1) * 48, i * 48);
                if (id == ZERO) {
                    break;
                }
                i--;
            }
            activeArr = new IClearingHouseStructures.TickRange[](5 - i);
            while (i < 5) {
                // 256 - 48 * 5 = 16
                (int24 tickLower, int24 tickUpper) = Uint48Lib.unconcat(
                    active.slice(16 + i * 48, 16 + (i + 1) * 48).toUint48()
                );
                activeArr[4 - i].tickLower = tickLower;
                activeArr[4 - i].tickUpper = tickUpper;
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IGovernable {
    function governance() external view returns (address);

    function governancePending() external view returns (address);

    function teamMultisig() external view returns (address);

    function teamMultisigPending() external view returns (address);

    function initiateGovernanceTransfer(address newGovernancePending) external;

    function acceptGovernanceTransfer() external;

    function initiateTeamMultisigTransfer(address newTeamMultisigPending) external;

    function acceptTeamMultisigTransfer() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseCustomErrors is IClearingHouseStructures {
    /// @notice error to denote invalid account access
    /// @param senderAddress address of msg sender
    error AccessDenied(address senderAddress);

    /// @notice error to denote usage of uninitialized token
    /// @param collateralId address of token
    error CollateralDoesNotExist(uint32 collateralId);

    /// @notice error to denote usage of unsupported collateral token
    /// @param collateralId address of token
    error CollateralNotAllowedForUse(uint32 collateralId);

    /// @notice error to denote unpause is in progress, hence cannot pause
    error CannotPauseIfUnpauseInProgress();

    /// @notice error to denote pause is in progress, hence cannot unpause
    error CannotUnpauseIfPauseInProgress();

    /// @notice error to denote incorrect address is supplied while updating collateral settings
    /// @param incorrectAddress incorrect address of collateral token
    /// @param correctAddress correct address of collateral token
    error IncorrectCollateralAddress(IERC20 incorrectAddress, IERC20 correctAddress);

    /// @notice error to denote invalid address supplied as a collateral token
    /// @param invalidAddress invalid address of collateral token
    error InvalidCollateralAddress(address invalidAddress);

    /// @notice error to denote invalid token liquidation (fraction to liquidate> 1)
    error InvalidTokenLiquidationParameters();

    /// @notice this is errored when the enum (uint8) value is out of bounds
    /// @param multicallOperationType is the value that is out of bounds
    error InvalidMulticallOperationType(MulticallOperationType multicallOperationType);

    /// @notice error to denote that keeper fee is negative or zero
    error KeeperFeeNotPositive(int256 keeperFee);

    /// @notice error to denote low notional value of txn
    /// @param notionalValue notional value of txn
    error LowNotionalValue(uint256 notionalValue);

    /// @notice error to denote that caller is not ragetrade factory
    error NotRageTradeFactory();

    /// @notice error to denote usage of uninitialized pool
    /// @param poolId unitialized truncated address supplied
    error PoolDoesNotExist(uint32 poolId);

    /// @notice error to denote usage of unsupported pool
    /// @param poolId address of token
    error PoolNotAllowedForTrade(uint32 poolId);

    /// @notice error to denote slippage of txn beyond set threshold
    error SlippageBeyondTolerance();

    /// @notice error to denote that zero amount is passed and it's prohibited
    error ZeroAmount();

    /// @notice error to denote an invalid setting for parameters
    error InvalidSetting(uint256 errorCode);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClearingHouseEnums {
    enum LimitOrderType {
        NONE,
        LOWER_LIMIT,
        UPPER_LIMIT
    }

    enum MulticallOperationType {
        UPDATE_MARGIN,
        UPDATE_PROFIT,
        SWAP_TOKEN,
        UPDATE_RANGE_ORDER,
        REMOVE_LIMIT_ORDER,
        LIQUIDATE_LIQUIDITY_POSITIONS,
        LIQUIDATE_TOKEN_POSITION
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseActions is IClearingHouseStructures {
    /// @notice creates a new account and adds it to the accounts map
    /// @return newAccountId - serial number of the new account created
    function createAccount() external returns (uint256 newAccountId);

    /// @notice deposits 'amount' of token associated with 'poolId'
    /// @param accountId account id
    /// @param collateralId truncated address of token to deposit
    /// @param amount amount of token to deposit
    function updateMargin(
        uint256 accountId,
        uint32 collateralId,
        int256 amount
    ) external;

    /// @notice creates a new account and deposits 'amount' of token associated with 'poolId'
    /// @param collateralId truncated address of collateral token to deposit
    /// @param amount amount of token to deposit
    /// @return newAccountId - serial number of the new account created
    function createAccountAndAddMargin(uint32 collateralId, uint256 amount) external returns (uint256 newAccountId);

    /// @notice withdraws 'amount' of settlement token from the profit made
    /// @param accountId account id
    /// @param amount amount of token to withdraw
    function updateProfit(uint256 accountId, int256 amount) external;

    /// @notice settles the profit/loss made with the settlement token collateral deposits
    /// @param accountId account id
    function settleProfit(uint256 accountId) external;

    /// @notice swaps token associated with 'poolId' by 'amount' (Long if amount>0 else Short)
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param swapParams swap parameters
    function swapToken(
        uint256 accountId,
        uint32 poolId,
        SwapParams memory swapParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice updates range order of token associated with 'poolId' by 'liquidityDelta' (Adds if amount>0 else Removes)
    /// @notice also can be used to update limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param liquidityChangeParams liquidity change parameters
    function updateRangeOrder(
        uint256 accountId,
        uint32 poolId,
        LiquidityChangeParams calldata liquidityChangeParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice keeper call to remove a limit order
    /// @dev checks the position of current price relative to limit order and checks limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param tickLower liquidity change parameters
    /// @param tickUpper liquidity change parameters
    function removeLimitOrder(
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper
    ) external;

    /// @notice keeper call for liquidation of range position
    /// @dev removes all the active range positions and gives liquidator a percent of notional amount closed + fixedFee
    /// @param accountId account id
    function liquidateLiquidityPositions(uint256 accountId) external;

    /// @notice keeper call for liquidation of token position
    /// @dev transfers the fraction of token position at a discount to current price to liquidators account and gives liquidator some fixedFee
    /// @param targetAccountId account id
    /// @param poolId truncated address of token to withdraw
    /// @return keeperFee - amount of fees transferred to keeper
    function liquidateTokenPosition(uint256 targetAccountId, uint32 poolId) external returns (int256 keeperFee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseEvents is IClearingHouseStructures {
    /// @notice denotes new account creation
    /// @param ownerAddress wallet address of account owner
    /// @param accountId serial number of the account
    event AccountCreated(address indexed ownerAddress, uint256 accountId);

    /// @notice new collateral supported as margin
    /// @param cTokenInfo collateral token info
    event CollateralSettingsUpdated(IERC20 cToken, CollateralSettings cTokenInfo);

    /// @notice maintainance margin ratio of a pool changed
    /// @param poolId id of the rage trade pool
    /// @param settings new settings
    event PoolSettingsUpdated(uint32 poolId, PoolSettings settings);

    /// @notice protocol settings changed
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    event ProtocolSettingsUpdated(
        LiquidationParams liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    );

    event PausedUpdated(bool paused);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseOwnerActions is IClearingHouseStructures {
    /// @notice updates the collataral settings
    /// @param cToken collateral token
    /// @param collateralSettings settings
    function updateCollateralSettings(IERC20 cToken, CollateralSettings memory collateralSettings) external;

    /// @notice updates the rage trade pool settings
    /// @param poolId rage trade pool id
    /// @param newSettings updated rage trade pool settings
    function updatePoolSettings(uint32 poolId, PoolSettings calldata newSettings) external;

    /// @notice updates the protocol settings
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    function updateProtocolSettings(
        LiquidationParams calldata liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    ) external;

    /// @notice withdraws protocol fees collected in the supplied wrappers to team multisig
    /// @param numberOfPoolsToUpdateInThisTx number of pools to collect fees from
    function withdrawProtocolFee(uint256 numberOfPoolsToUpdateInThisTx) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IOracle } from '../IOracle.sol';
import { IVToken } from '../IVToken.sol';
import { IVPoolWrapper } from '../IVPoolWrapper.sol';

import { IClearingHouseEnums } from './IClearingHouseEnums.sol';

interface IClearingHouseStructures is IClearingHouseEnums {
    struct BalanceAdjustments {
        int256 vQuoteIncrease; // specifies the increase in vQuote balance
        int256 vTokenIncrease; // specifies the increase in token balance
        int256 traderPositionIncrease; // specifies the increase in trader position
    }

    struct Collateral {
        IERC20 token; // address of the collateral token
        CollateralSettings settings; // collateral settings, changable by governance later
    }

    struct CollateralSettings {
        IOracle oracle; // address of oracle which gives price to be used for collateral
        uint32 twapDuration; // duration of the twap in seconds
        bool isAllowedForDeposit; // whether the collateral is allowed to be deposited at the moment
    }

    struct CollateralDepositView {
        IERC20 collateral; // address of the collateral token
        uint256 balance; // balance of the collateral in the account
    }

    struct LiquidityChangeParams {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        int128 liquidityDelta; // positive to add liquidity, negative to remove liquidity
        uint160 sqrtPriceCurrent; // hint for virtual price, to prevent sandwitch attack
        uint16 slippageToleranceBps; // slippage tolerance in bps, to prevent sandwitch attack
        bool closeTokenPosition; // whether to close the token position generated due to the liquidity change
        LimitOrderType limitOrderType; // limit order type
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct LiquidityPositionView {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        uint128 liquidity; // liquidity in the range by the account
        int256 vTokenAmountIn; // amount of token supplied by the account, to calculate net position
        int256 sumALastX128; // checkpoint of the term A in funding payment math
        int256 sumBInsideLastX128; // checkpoint of the term B in funding payment math
        int256 sumFpInsideLastX128; // checkpoint of the term Fp in funding payment math
        uint256 sumFeeInsideLastX128; // checkpoint of the trading fees
        LimitOrderType limitOrderType; // limit order type
    }

    struct LiquidationParams {
        uint16 rangeLiquidationFeeFraction; // fraction of net token position rm from the range to be charged as liquidation fees (in 1e5)
        uint16 tokenLiquidationFeeFraction; // fraction of traded amount of vquote to be charged as liquidation fees (in 1e5)
        uint16 closeFactorMMThresholdBps; // fraction the MM threshold for partial liquidation (in 1e4)
        uint16 partialLiquidationCloseFactorBps; // fraction the % of position to be liquidated if partial liquidation should occur (in 1e4)
        uint16 insuranceFundFeeShareBps; // fraction of the fee share for insurance fund out of the total liquidation fee (in 1e4)
        uint16 liquidationSlippageSqrtToleranceBps; // fraction of the max sqrt price slippage threshold (in 1e4) (can be set to - actual price slippage tolerance / 2)
        uint64 maxRangeLiquidationFees; // maximum range liquidation fees (in settlement token amount decimals)
        uint64 minNotionalLiquidatable; // minimum notional value of position for it to be eligible for partial liquidation (in settlement token amount decimals)
    }

    struct MulticallOperation {
        MulticallOperationType operationType; // operation type
        bytes data; // abi encoded data for the operation
    }

    struct Pool {
        IVToken vToken; // address of the vToken, poolId = vToken.truncate()
        IUniswapV3Pool vPool; // address of the UniswapV3Pool(token0=vToken, token1=vQuote, fee=500)
        IVPoolWrapper vPoolWrapper; // wrapper address
        PoolSettings settings; // pool settings, which can be updated by governance later
    }

    struct PoolSettings {
        uint16 initialMarginRatioBps; // margin ratio (1e4) considered for create/update position, removing margin or profit
        uint16 maintainanceMarginRatioBps; // margin ratio (1e4) considered for liquidations by keeper
        uint16 maxVirtualPriceDeviationRatioBps; // maximum deviation (1e4) from the current virtual price
        uint32 twapDuration; // twap duration (seconds) for oracle
        bool isAllowedForTrade; // whether the pool is allowed to be traded at the moment
        bool isCrossMargined; // whether cross margined is done for positions of this pool
        IOracle oracle; // spot price feed twap oracle for this pool
    }

    struct SwapParams {
        int256 amount; // amount of tokens/vQuote to swap
        uint160 sqrtPriceLimit; // threshold sqrt price which should not be crossed
        bool isNotional; // whether the amount represents vQuote amount
        bool isPartialAllowed; // whether to end swap (partial) when sqrtPriceLimit is reached, instead of reverting
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct TickRange {
        int24 tickLower;
        int24 tickUpper;
    }

    struct VTokenPositionView {
        uint32 poolId; // id of the pool of which this token position is for
        int256 balance; // vTokenLong - vTokenShort
        int256 netTraderPosition; // net position due to trades and liquidity change carries
        int256 sumALastX128; // checkoint of the term A in funding payment math
        LiquidityPositionView[] liquidityPositions; // liquidity positions of the account in the pool
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IInsuranceFund } from '../IInsuranceFund.sol';
import { IOracle } from '../IOracle.sol';
import { IVQuote } from '../IVQuote.sol';
import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseSystemActions is IClearingHouseStructures {
    /// @notice initializes clearing house contract
    /// @param rageTradeFactoryAddress rage trade factory address
    /// @param defaultCollateralToken address of default collateral token
    /// @param defaultCollateralTokenOracle address of default collateral token oracle
    /// @param insuranceFund address of insurance fund
    /// @param vQuote address of vQuote
    function initialize(
        address rageTradeFactoryAddress,
        address initialGovernance,
        address initialTeamMultisig,
        IERC20 defaultCollateralToken,
        IOracle defaultCollateralTokenOracle,
        IInsuranceFund insuranceFund,
        IVQuote vQuote
    ) external;

    function registerPool(Pool calldata poolInfo) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';
import { IExtsload } from '../IExtsload.sol';

interface IClearingHouseView is IClearingHouseStructures, IExtsload {
    /// @notice Gets the market value and required margin of an account
    /// @dev This method can be used to check if an account is under water or not.
    ///     If accountMarketValue < requiredMargin then liquidation can take place.
    /// @param accountId the account id
    /// @param isInitialMargin true is initial margin, false is maintainance margin
    /// @return accountMarketValue the market value of the account, due to collateral and positions
    /// @return requiredMargin margin needed due to positions
    function getAccountMarketValueAndRequiredMargin(uint256 accountId, bool isInitialMargin)
        external
        view
        returns (int256 accountMarketValue, int256 requiredMargin);

    /// @notice Gets the net profit of an account
    /// @param accountId the account id
    /// @return accountNetProfit the net profit of the account
    function getAccountNetProfit(uint256 accountId) external view returns (int256 accountNetProfit);

    /// @notice Gets the net position of an account
    /// @param accountId the account id
    /// @param poolId the id of the pool (vETH, ... etc)
    /// @return netPosition the net position of the account
    function getAccountNetTokenPosition(uint256 accountId, uint32 poolId) external view returns (int256 netPosition);

    /// @notice Gets the real twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return realPriceX128 the real price of the pool
    function getRealTwapPriceX128(uint32 poolId) external view returns (uint256 realPriceX128);

    /// @notice Gets the virtual twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return virtualPriceX128 the virtual price of the pool
    function getVirtualTwapPriceX128(uint32 poolId) external view returns (uint256 virtualPriceX128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IInsuranceFund {
    function initialize(
        IERC20 settlementToken,
        address clearingHouse,
        string calldata name,
        string calldata symbol
    ) external;

    function claim(uint256 amount) external;
}