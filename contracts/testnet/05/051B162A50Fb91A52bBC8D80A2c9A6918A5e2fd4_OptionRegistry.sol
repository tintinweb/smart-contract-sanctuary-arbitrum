// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { LiquidityPool } from "./LiquidityPool.sol";

import "./tokens/ERC20.sol";
import "./libraries/AccessControl.sol";
import { Types } from "./libraries/Types.sol";
import { CustomErrors } from "./libraries/CustomErrors.sol";
import { OptionsCompute } from "./libraries/OptionsCompute.sol";
import { SafeTransferLib } from "./libraries/SafeTransferLib.sol";
import { OpynInteractions } from "./libraries/OpynInteractions.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/IMarginCalculator.sol";
import "./interfaces/AddressBookInterface.sol";
import { IController, GammaTypes } from "./interfaces/GammaInterface.sol";

/**
 *  @title Contract used for conducting options issuance and settlement as well as collateral management
 *  @dev Interacts with the opyn-rysk gamma protocol via OpynInteractions for options activity. Interacts with
 *       the liquidity pool for collateral and instructions.
 */
contract OptionRegistry is AccessControl {
	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	// address of the opyn oTokenFactory for oToken minting
	address internal immutable oTokenFactory;
	// address of the gammaController for oToken operations
	address internal immutable gammaController;
	// address of the collateralAsset
	address public immutable collateralAsset;
	// address of the opyn addressBook for accessing important opyn modules
	AddressBookInterface internal immutable addressBook;
	// address of the marginPool, contract for storing options collateral
	address internal immutable marginPool;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	// information of a series
	mapping(address => Types.OptionSeries) public seriesInfo;
	// vaultId that is responsible for a specific series address
	mapping(address => uint256) public vaultIds;
	// issuance hash mapped against the series address
	mapping(bytes32 => address) seriesAddress;
	// vault counter
	uint64 public vaultCount;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	// address of the rysk liquidity pools
	address internal liquidityPool;
	// max health threshold for calls
	uint64 public callUpperHealthFactor = 13_000;
	// min health threshold for calls
	uint64 public callLowerHealthFactor = 11_000;
	// max health threshold for puts
	uint64 public putUpperHealthFactor = 12_000;
	// min health threshold for puts
	uint64 public putLowerHealthFactor = 11_000;
	// keeper addresses for this contract
	mapping(address => bool) public keeper;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// BIPS
	uint256 private constant MAX_BPS = 10_000;
	// used to convert e18 to e8
	uint256 private constant SCALE_FROM = 10**10;
	// oToken decimals
	uint8 private constant OPYN_DECIMALS = 8;

	/////////////////////////////////////
	/// events && errors && modifiers ///
	/////////////////////////////////////

	event OptionTokenCreated(address token);
	event SeriesRedeemed(address series, uint256 underlyingAmount, uint256 strikeAmount);
	event OptionsContractOpened(address indexed series, uint256 vaultId, uint256 optionsAmount);
	event OptionsContractClosed(address indexed series, uint256 vaultId, uint256 closedAmount);
	event OptionsContractSettled(
		address indexed series,
		uint256 collateralReturned,
		uint256 collateralLost,
		uint256 amountLost
	);
	event VaultLiquidationRegistered(
		address indexed series,
		uint256 vaultId,
		uint256 amountLiquidated,
		uint256 collateralLiquidated
	);

	error NoVault();
	error NotKeeper();
	error NotExpired();
	error HealthyVault();
	error AlreadyExpired();
	error NotLiquidityPool();
	error NonExistentSeries();
	error InvalidCollateral();
	error VaultNotLiquidated();
	error InsufficientBalance();

	constructor(
		address _collateralAsset,
		address _oTokenFactory,
		address _gammaController,
		address _marginPool,
		address _liquidityPool,
		address _addressBook,
		address _authority
	) AccessControl(IAuthority(_authority)) {
		collateralAsset = _collateralAsset;
		oTokenFactory = _oTokenFactory;
		gammaController = _gammaController;
		marginPool = _marginPool;
		liquidityPool = _liquidityPool;
		addressBook = AddressBookInterface(_addressBook);
	}

	///////////////
	/// setters ///
	///////////////

	/**
	 * @notice Set the liquidity pool address
	 * @param  _newLiquidityPool set the liquidityPool address
	 */
	function setLiquidityPool(address _newLiquidityPool) external {
		_onlyGovernor();
		liquidityPool = _newLiquidityPool;
	}

	/**
	 * @notice Set or revoke a keeper
	 * @param  _target address to become a keeper
	 * @param  _auth accept or revoke
	 */
	function setKeeper(address _target, bool _auth) external {
		_onlyGovernor();
		keeper[_target] = _auth;
	}

	/**
	 * @notice Set the health thresholds of the pool
	 * @param  _putLower the lower health threshold for puts
	 * @param  _putUpper the upper health threshold for puts
	 * @param  _callLower the lower health threshold for calls
	 * @param  _callUpper the upper health threshold for calls
	 */
	function setHealthThresholds(
		uint64 _putLower,
		uint64 _putUpper,
		uint64 _callLower,
		uint64 _callUpper
	) external {
		_onlyGovernor();
		putLowerHealthFactor = _putLower;
		putUpperHealthFactor = _putUpper;
		callLowerHealthFactor = _callLower;
		callUpperHealthFactor = _callUpper;
	}

	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param  optionSeries the series used for the mint - strike passed in as e18
	 * @return the address of the option
	 */
	function issue(Types.OptionSeries memory optionSeries) external returns (address) {
		_isLiquidityPool();
		// deploy an oToken contract address
		if (optionSeries.expiration <= block.timestamp) {
			revert AlreadyExpired();
		}
		// assumes strike is passed in e18, converts to e8
		uint128 formattedStrike = uint128(
			formatStrikePrice(optionSeries.strike, optionSeries.collateral)
		);
		// create option storage hash
		bytes32 issuanceHash = getIssuanceHash(
			optionSeries.underlying,
			optionSeries.strikeAsset,
			optionSeries.collateral,
			optionSeries.expiration,
			optionSeries.isPut,
			formattedStrike
		);
		// check for an opyn oToken if it doesn't exist deploy it
		address series = OpynInteractions.getOrDeployOtoken(
			oTokenFactory,
			optionSeries.collateral,
			optionSeries.underlying,
			optionSeries.strikeAsset,
			formattedStrike,
			optionSeries.expiration,
			optionSeries.isPut
		);
		// store the option data as a hash
		seriesInfo[series] = Types.OptionSeries(
			optionSeries.expiration,
			formattedStrike,
			optionSeries.isPut,
			optionSeries.underlying,
			optionSeries.strikeAsset,
			optionSeries.collateral
		);
		seriesAddress[issuanceHash] = series;
		emit OptionTokenCreated(series);
		return series;
	}

	/**
	 * @notice Open an options contract using collateral from the liquidity pool
	 * @param  _series the address of the option token to be created
	 * @param  amount the amount of options to deploy - assume in e18
	 * @param  collateralAmount the collateral required for the option - assumes in collateral decimals
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 * @return the amount of collateral taken from the liquidityPool
	 */
	function open(
		address _series,
		uint256 amount,
		uint256 collateralAmount
	) external returns (bool, uint256) {
		_isLiquidityPool();
		// make sure the options are ok to open
		Types.OptionSeries memory series = seriesInfo[_series];
		// assumes strike in e8
		if (series.expiration <= block.timestamp) {
			revert AlreadyExpired();
		}
		// transfer collateral to this contract, collateral will depend on the option type
		SafeTransferLib.safeTransferFrom(series.collateral, msg.sender, address(this), collateralAmount);
		// mint the option token following the opyn interface
		IController controller = IController(gammaController);
		// check if a vault for this option already exists
		uint256 vaultId_ = vaultIds[_series];
		if (vaultId_ == 0) {
			vaultId_ = (controller.getAccountVaultCounter(address(this))) + 1;
			vaultCount++;
		}
		uint256 mintAmount = OpynInteractions.createShort(
			gammaController,
			marginPool,
			_series,
			collateralAmount,
			vaultId_,
			amount,
			1
		);
		emit OptionsContractOpened(_series, vaultId_, mintAmount);
		// transfer the option to the liquidity pool
		SafeTransferLib.safeTransfer(ERC20(_series), msg.sender, mintAmount);
		vaultIds[_series] = vaultId_;
		// returns in collateral decimals
		return (true, collateralAmount);
	}

	/**
	 * @notice Close an options contract (oToken) before it has expired
	 * @param  _series the address of the option token to be burnt
	 * @param  amount the amount of options to burn - assumes in e18
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 */
	function close(address _series, uint256 amount) external returns (bool, uint256) {
		_isLiquidityPool();
		// withdraw and burn
		Types.OptionSeries memory series = seriesInfo[_series];
		// assumes strike in e8
		// make sure the option hasnt expired yet
		if (series.expiration == 0) {
			revert NonExistentSeries();
		}
		if (series.expiration <= block.timestamp) {
			revert AlreadyExpired();
		}
		// get the vault id
		uint256 vaultId = vaultIds[_series];
		if (vaultId == 0) {
			revert NoVault();
		}
		uint256 convertedAmount = OptionsCompute.convertToDecimals(amount, ERC20(_series).decimals());
		// transfer the oToken back to this account
		SafeTransferLib.safeTransferFrom(_series, msg.sender, address(this), convertedAmount);
		// burn the oToken tracking the amount of collateral returned
		uint256 collatReturned = OpynInteractions.burnShort(
			gammaController,
			_series,
			convertedAmount,
			vaultId
		);
		SafeTransferLib.safeTransfer(ERC20(series.collateral), msg.sender, collatReturned);
		emit OptionsContractClosed(_series, vaultId, convertedAmount);
		// returns in collateral decimals
		return (true, collatReturned);
	}

	/**
	 * @notice Settle an options vault
	 * @param  _series the address of the option token to be burnt
	 * @return  if the transaction succeeded
	 * @return  the amount of collateral returned from the vault
	 * @return  the amount of collateral used to pay ITM options on vault settle
	 * @return  number of oTokens that the vault was short
	 * @dev callable by the liquidityPool so that local variables can also be updated
	 */
	function settle(address _series)
		external
		returns (
			bool,
			uint256,
			uint256,
			uint256
		)
	{
		_isLiquidityPool();
		Types.OptionSeries memory series = seriesInfo[_series];
		// strike will be in e8
		if (series.expiration == 0) {
			revert NonExistentSeries();
		}
		// check that the option has expired
		if (series.expiration >= block.timestamp) {
			revert NotExpired();
		}
		// get the vault
		uint256 vaultId = vaultIds[_series];
		// settle the vault
		(uint256 collatReturned, uint256 collatLost, uint256 amountShort) = OpynInteractions.settle(
			gammaController,
			vaultId
		);
		// transfer the collateral back to the liquidity pool
		SafeTransferLib.safeTransfer(ERC20(series.collateral), liquidityPool, collatReturned);
		emit OptionsContractSettled(_series, collatReturned, collatLost, amountShort);
		// assumes in collateral decimals, collateral decimals, e8
		return (true, collatReturned, collatLost, amountShort);
	}

	/**
	 * @notice adjust the collateral held in a specific vault because of health
	 * @param  vaultId the id of the vault to check
	 */
	function adjustCollateral(uint256 vaultId) external {
		_isKeeper();
		(
			bool isBelowMin,
			bool isAboveMax,
			,
			,
			uint256 collateralAmount,
			address _collateralAsset
		) = checkVaultHealth(vaultId);
		if (collateralAsset != _collateralAsset) {
			revert InvalidCollateral();
		}
		if (!isBelowMin && !isAboveMax) {
			revert HealthyVault();
		}
		if (isBelowMin) {
			LiquidityPool(liquidityPool).adjustCollateral(collateralAmount, false);
			// transfer the needed collateral to this contract from the liquidityPool
			SafeTransferLib.safeTransferFrom(
				_collateralAsset,
				liquidityPool,
				address(this),
				collateralAmount
			);
			// increase the collateral in the vault (make sure balance change is recorded in the LiquidityPool)
			OpynInteractions.depositCollat(
				gammaController,
				marginPool,
				_collateralAsset,
				collateralAmount,
				vaultId
			);
		} else if (isAboveMax) {
			LiquidityPool(liquidityPool).adjustCollateral(collateralAmount, true);
			// decrease the collateral in the vault (make sure balance change is recorded in the LiquidityPool)
			OpynInteractions.withdrawCollat(gammaController, _collateralAsset, collateralAmount, vaultId);
			// transfer the excess collateral to the liquidityPool from this address
			SafeTransferLib.safeTransfer(ERC20(_collateralAsset), liquidityPool, collateralAmount);
		}
	}

	/**
	 * @notice adjust the collateral held in a specific vault because of health, using collateral from the caller. Only takes
	 *         from msg.sender, doesnt give them if vault is above the max.
	 * @param  vaultId the id of the vault to check
	 * @dev    this is a safety function, if worst comes to worse any caller can collateralise a vault to save it.
	 */
	function adjustCollateralCaller(uint256 vaultId) external {
		_onlyGuardian();
		(bool isBelowMin, , , , uint256 collateralAmount, address _collateralAsset) = checkVaultHealth(
			vaultId
		);
		if (collateralAsset != _collateralAsset) {
			revert InvalidCollateral();
		}
		if (!isBelowMin) {
			revert HealthyVault();
		}
		// transfer the needed collateral to this contract from the msg.sender
		SafeTransferLib.safeTransferFrom(_collateralAsset, msg.sender, address(this), collateralAmount);
		// increase the collateral in the vault
		OpynInteractions.depositCollat(
			gammaController,
			marginPool,
			_collateralAsset,
			collateralAmount,
			vaultId
		);
	}

	/**
	 * @notice withdraw collateral from a fully liquidated vault
	 * @param  vaultId the id of the vault to check
	 * @dev    this is a safety function, if a vault is liquidated.
	 */
	function wCollatLiquidatedVault(uint256 vaultId) external {
		_isKeeper();
		// get the vault details from the vaultId
		GammaTypes.Vault memory vault = IController(gammaController).getVault(address(this), vaultId);
		require(vault.shortAmounts[0] == 0, "Vault has short positions [amount]");
		require(vault.shortOtokens[0] == address(0), "Vault has short positions [token]");
		require(vault.collateralAmounts[0] > 0, "Vault has no collateral");
		// decrease the collateral in the vault (make sure balance change is recorded in the LiquidityPool)
		OpynInteractions.withdrawCollat(
			gammaController,
			vault.collateralAssets[0],
			vault.collateralAmounts[0],
			vaultId
		);
		// adjust the collateral in the liquidityPool
		LiquidityPool(liquidityPool).adjustCollateral(vault.collateralAmounts[0], true);
		// transfer the excess collateral to the liquidityPool from this address
		SafeTransferLib.safeTransfer(
			ERC20(vault.collateralAssets[0]),
			liquidityPool,
			vault.collateralAmounts[0]
		);
	}

	/**
	 * @notice register a liquidated vault so the collateral allocated is managed
	 * @param  vaultId the id of the vault to register liquidation for
	 * @dev    this is a safety function, if a vault is liquidated to update the collateral assets in the pool
	 */
	function registerLiquidatedVault(uint256 vaultId) external {
		_isKeeper();
		// get the vault liquidation details from the vaultId
		(address series, uint256 amount, uint256 collateralLiquidated) = IController(gammaController)
			.getVaultLiquidationDetails(address(this), vaultId);
		if (series == address(0)) {
			revert VaultNotLiquidated();
		}
		emit VaultLiquidationRegistered(series, vaultId, amount, collateralLiquidated);
		// adjust the collateral in the liquidity pool to reflect the loss
		LiquidityPool(liquidityPool).adjustCollateral(collateralLiquidated, true);
		// clear the liquidation record from gamma controller so as not to double count the liquidation
		IController(gammaController).clearVaultLiquidationDetails(vaultId);
	}

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice Redeem oTokens for the locked collateral
	 * @param  _series the address of the option token to be burnt and redeemed
	 * @return amount returned
	 */
	function redeem(address _series) external returns (uint256) {
		Types.OptionSeries memory series = seriesInfo[_series];
		// strike will be in e8
		if (series.expiration == 0) {
			revert NonExistentSeries();
		}
		// check that the option has expired
		if (series.expiration >= block.timestamp) {
			revert NotExpired();
		}
		uint256 seriesBalance = ERC20(_series).balanceOf(msg.sender);
		if (seriesBalance == 0) {
			revert InsufficientBalance();
		}
		// transfer the oToken back to this account
		SafeTransferLib.safeTransferFrom(_series, msg.sender, address(this), seriesBalance);
		// redeem
		uint256 collatReturned = OpynInteractions.redeem(
			gammaController,
			marginPool,
			_series,
			seriesBalance
		);
		// assumes in collateral decimals
		return collatReturned;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice Send collateral funds for an option to be minted
	 * @dev series.strike should be scaled by 1e8.
	 * @param  series details of the option series
	 * @param  amount amount of options to mint always in e18
	 * @return amount transferred
	 */
	function getCollateral(Types.OptionSeries memory series, uint256 amount)
		external
		view
		returns (uint256)
	{
		IMarginCalculator marginCalc = IMarginCalculator(addressBook.getMarginCalculator());
		uint256 collateralAmount = marginCalc.getNakedMarginRequired(
			series.underlying,
			series.strikeAsset,
			series.collateral,
			amount / SCALE_FROM, // assumes that amount is always in e18
			series.strike, // assumes in e8
			IOracle(addressBook.getOracle()).getPrice(series.underlying),
			series.expiration,
			ERC20(series.collateral).decimals(),
			series.isPut
		);
		// based on this collateral requirement and the health factor get the amount to deposit
		uint256 upperHealthFactor = series.isPut ? putUpperHealthFactor : callUpperHealthFactor;
		collateralAmount = ((collateralAmount * upperHealthFactor) / MAX_BPS);
		// assumes in collateral decimals
		return collateralAmount;
	}

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
	) external view returns (address) {
		// check for an opyn oToken
		address series = OpynInteractions.getOtoken(
			oTokenFactory,
			collateral,
			underlying,
			strikeAsset,
			formatStrikePrice(strike, collateral),
			expiration,
			isPut
		);
		return series;
	}

	/**
	 * @notice check the health of a specific vault to see if it requires collateral
	 * @param  vaultId the id of the vault to check
	 * @return isBelowMin bool to determine whether the vault needs topping up
	 * @return isAboveMax bool to determine whether the vault is too overcollateralised
	 * @return healthFactor the health factor of the vault in MAX_BPS format
	 * @return upperHealthFactor the upper bound of the acceptable health facor range in MAX_BPS format
	 * @return collatRequired the amount of collateral required to return the vault back to normal
	 * @return collatAsset the address of the collateral asset
	 */
	function checkVaultHealth(uint256 vaultId)
		public
		view
		returns (
			bool isBelowMin,
			bool isAboveMax,
			uint256 healthFactor,
			uint256 upperHealthFactor,
			uint256 collatRequired,
			address collatAsset
		)
	{
		// run checks on the vault health
		// get the vault details from the vaultId
		GammaTypes.Vault memory vault = IController(gammaController).getVault(address(this), vaultId);
		// get the series
		Types.OptionSeries memory series = seriesInfo[vault.shortOtokens[0]];
		// get the MarginRequired
		IMarginCalculator marginCalc = IMarginCalculator(addressBook.getMarginCalculator());

		uint256 marginReq = marginCalc.getNakedMarginRequired(
			series.underlying,
			series.strikeAsset,
			series.collateral,
			vault.shortAmounts[0], // assumes in e8
			series.strike, // assumes in e8
			IOracle(addressBook.getOracle()).getPrice(series.underlying),
			series.expiration,
			ERC20(series.collateral).decimals(),
			series.isPut
		);
		// get the amount held in the vault
		uint256 collatAmount = vault.collateralAmounts[0];
		// divide the amount held in the vault by the margin requirements to get the health factor
		healthFactor = (collatAmount * MAX_BPS) / marginReq;
		// set the upper and lower health factor depending on if the series is a put or a call
		upperHealthFactor = series.isPut ? putUpperHealthFactor : callUpperHealthFactor;
		uint256 lowerHealthFactor = series.isPut ? putLowerHealthFactor : callLowerHealthFactor;
		// if the vault health is above a certain threshold then the vault is above safe margins and collateral can be withdrawn
		if (healthFactor > upperHealthFactor) {
			isAboveMax = true;
			// calculate the margin to remove from the vault
			collatRequired = collatAmount - ((marginReq * upperHealthFactor) / MAX_BPS);
		} else if (healthFactor < lowerHealthFactor) {
			isBelowMin = true;
			// calculate the margin to add to the vault
			collatRequired = ((marginReq * upperHealthFactor) / MAX_BPS) - collatAmount;
		}
		collatAsset = series.collateral;
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getSeriesAddress(bytes32 issuanceHash) external view returns (address) {
		return seriesAddress[issuanceHash];
	}

	function getSeries(Types.OptionSeries memory _series) external view returns (address) {
		return
			seriesAddress[
				getIssuanceHash(
					_series.underlying,
					_series.strikeAsset,
					_series.collateral,
					_series.expiration,
					_series.isPut,
					_series.strike
				)
			];
	}

	function getSeriesInfo(address series) external view returns (Types.OptionSeries memory) {
		return seriesInfo[series];
	}

	function getIssuanceHash(Types.OptionSeries memory _series) public pure returns (bytes32) {
		return
			getIssuanceHash(
				_series.underlying,
				_series.strikeAsset,
				_series.collateral,
				_series.expiration,
				_series.isPut,
				_series.strike
			);
	}

	/**
	 * Helper function for computing the hash of a given issuance.
	 */
	function getIssuanceHash(
		address underlying,
		address strikeAsset,
		address collateral,
		uint256 expiration,
		bool isPut,
		uint256 strike
	) internal pure returns (bytes32) {
		return
			keccak256(abi.encodePacked(underlying, strikeAsset, collateral, expiration, isPut, strike));
	}

	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	/**
	 * @notice Converts strike price to 1e8 format and floors least significant digits if needed
	 * @param  strikePrice strikePrice in 1e18 format
	 * @param  collateral address of collateral asset
	 * @return if the transaction succeeded
	 */
	function formatStrikePrice(uint256 strikePrice, address collateral) public view returns (uint256) {
		// convert strike to 1e8 format
		uint256 price = strikePrice / (10**10);
		uint256 collateralDecimals = ERC20(collateral).decimals();
		if (collateralDecimals >= OPYN_DECIMALS) return price;
		uint256 difference = OPYN_DECIMALS - collateralDecimals;
		// round floor strike to prevent errors in Gamma protocol
		return (price / (10**difference)) * (10**difference);
	}

	function _isLiquidityPool() internal view {
		if (msg.sender != liquidityPool) {
			revert NotLiquidityPool();
		}
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] && msg.sender != authority.governor() && msg.sender != authority.manager()
		) {
			revert NotKeeper();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Protocol.sol";
import "./PriceFeed.sol";
import "./VolatilityFeed.sol";

import "./tokens/ERC20.sol";
import "./utils/ReentrancyGuard.sol";

import "./libraries/BlackScholes.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";
import "./libraries/OptionsCompute.sol";
import "./libraries/SafeTransferLib.sol";

import "./interfaces/IOptionRegistry.sol";
import "./interfaces/IHedgingReactor.sol";
import "./interfaces/IPortfolioValuesFeed.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

/**
 *  @title Contract used as the Dynamic Hedging Vault for storing funds, issuing shares and processing options transactions
 *  @dev Interacts with the OptionRegistry for options behaviour, Interacts with hedging reactors for alternative derivatives
 *       Interacts with Handlers for periphary user options interactions. Interacts with Chainlink price feeds throughout.
 *       Interacts with Volatility Feed via getImpliedVolatility(), interacts with a chainlink PortfolioValues external adaptor
 *       oracle via PortfolioValuesFeed.
 */
contract LiquidityPool is ERC20, AccessControl, ReentrancyGuard, Pausable {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	// Protocol management contract
	Protocol public immutable protocol;
	// asset that denominates the strike price
	address public immutable strikeAsset;
	// asset that is used as the reference asset
	address public immutable underlyingAsset;
	// asset that is used for collateral asset
	address public immutable collateralAsset;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	// amount of collateralAsset allocated as collateral
	uint256 public collateralAllocated;
	// ephemeral liabilities of the pool
	int256 public ephemeralLiabilities;
	// ephemeral delta of the pool
	int256 public ephemeralDelta;
	// epoch of the price per share round
	uint256 public epoch;
	// epoch PPS
	mapping(uint256 => uint256) public epochPricePerShare;
	// deposit receipts for users
	mapping(address => DepositReceipt) public depositReceipts;
	// withdrawal receipts for users
	mapping(address => WithdrawalReceipt) public withdrawalReceipts;
	// pending deposits for a round
	uint256 public pendingDeposits;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	// buffer of funds to not be used to write new options in case of margin requirements (as percentage - for 20% enter 2000)
	uint256 public bufferPercentage = 2000;
	// list of addresses for hedging reactors
	address[] public hedgingReactors;
	// max total supply of collateral, denominated in e18
	uint256 public collateralCap = type(uint256).max;
	// Maximum discount that an option tilting factor can discount an option price
	uint256 public maxDiscount = (PRBMathUD60x18.SCALE * 10) / 100; // As a percentage. Init at 10%
	// The spread between the bid and ask on the IV skew;
	// Consider making this it's own volatility skew if more flexibility is needed
	uint256 public bidAskIVSpread;
	// option issuance parameters
	Types.OptionParams public optionParams;
	// riskFreeRate as a percentage PRBMath Float. IE: 3% -> 0.03 * 10**18
	uint256 public riskFreeRate;
	// handlers who are approved to interact with options functionality
	mapping(address => bool) public handler;
	// is the purchase and sale of options paused
	bool public isTradingPaused;
	// max time to allow between oracle updates for an underlying and strike
	uint256 public maxTimeDeviationThreshold;
	// max price difference to allow between oracle updates for an underlying and strike
	uint256 public maxPriceDeviationThreshold;
	// variables relating to the utilization skew function:
	// the gradient of the function where utiization is below function threshold. e18
	uint256 public belowThresholdGradient = 1e17; // 0.1
	// the gradient of the line above the utilization threshold. e18
	uint256 public aboveThresholdGradient = 15e17; // 1.5
	// the y-intercept of the line above the threshold. Needed to make the two lines meet at the threshold.  Will always be negative but enter the absolute value
	uint256 public aboveThresholdYIntercept = 84e16; //-0.84
	// the percentage utilization above which the function moves from its shallow line to its steep line. e18
	uint256 public utilizationFunctionThreshold = 6e17; // 60%
	// keeper mapping
	mapping(address => bool) public keeper;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// BIPS
	uint256 private constant MAX_BPS = 10_000;

	/////////////////////////
	/// structs && events ///
	/////////////////////////

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

	struct DepositReceipt {
		uint128 epoch;
		uint128 amount; //collateral decimals
		uint256 unredeemedShares; //e18
	}

	struct WithdrawalReceipt {
		uint128 epoch;
		uint128 shares; //e18
	}

	event EpochExecuted(uint256 epoch);
	event Withdraw(address recipient, uint256 amount, uint256 shares);
	event Deposit(address recipient, uint256 amount, uint256 epoch);
	event Redeem(address recipient, uint256 amount, uint256 epoch);
	event InitiateWithdraw(address recipient, uint256 amount, uint256 epoch);
	event WriteOption(address series, uint256 amount, uint256 premium, uint256 escrow, address buyer);
	event SettleVault(
		address series,
		uint256 collateralReturned,
		uint256 collateralLost,
		address closer
	);
	event BuybackOption(
		address series,
		uint256 amount,
		uint256 premium,
		uint256 escrowReturned,
		address seller
	);

	constructor(
		address _protocol,
		address _strikeAsset,
		address _underlyingAsset,
		address _collateralAsset,
		uint256 rfr,
		string memory name,
		string memory symbol,
		Types.OptionParams memory _optionParams,
		address _authority
	) ERC20(name, symbol, 18) AccessControl(IAuthority(_authority)) {
		strikeAsset = _strikeAsset;
		riskFreeRate = rfr;
		underlyingAsset = _underlyingAsset;
		collateralAsset = _collateralAsset;
		protocol = Protocol(_protocol);
		optionParams = _optionParams;
		epochPricePerShare[0] = 1e18;
		epoch++;
	}

	///////////////
	/// setters ///
	///////////////

	function pause() external {
		_onlyGuardian();
		_pause();
	}

	function pauseUnpauseTrading(bool _pause) external {
		_onlyGuardian();
		isTradingPaused = _pause;
	}

	function unpause() external {
		_onlyGuardian();
		_unpause();
	}

	/**
	 * @notice set a new hedging reactor
	 * @param _reactorAddress append a new hedging reactor
	 * @dev   only governance can call this function
	 */
	function setHedgingReactorAddress(address _reactorAddress) external {
		_onlyGovernor();
		hedgingReactors.push(_reactorAddress);
		SafeTransferLib.safeApprove(ERC20(collateralAsset), _reactorAddress, type(uint256).max);
	}

	/**
	 * @notice remove a new hedging reactor by index
	 * @param _index remove a hedging reactor
	 * @param _override whether to override whether the reactor is wound down 
	 		 			(THE REACTOR SHOULD BE WOUND DOWN SEPERATELY)
	 * @dev   only governance can call this function
	 */
	function removeHedgingReactorAddress(uint256 _index, bool _override) external {
		_onlyGovernor();
		address[] memory hedgingReactors_ = hedgingReactors;
		if (!_override) {
			IHedgingReactor reactor = IHedgingReactor(hedgingReactors_[_index]);
			int256 delta = reactor.getDelta();
			if (delta != 0) {
				reactor.hedgeDelta(delta);
			}
			reactor.withdraw(type(uint256).max);
		}
		SafeTransferLib.safeApprove(ERC20(collateralAsset), hedgingReactors_[_index], 0);
		for (uint256 i = _index; i < hedgingReactors.length - 1; i++) {
			hedgingReactors[i] = hedgingReactors[i + 1];
		}
		hedgingReactors.pop();
	}

	/**
	 * @notice update all optionParam variables for max and min strikes and max and
	 *         min expiries for options that the DHV can issue
	 * @dev   only management or above can call this function
	 */
	function setNewOptionParams(
		uint128 _newMinCallStrike,
		uint128 _newMaxCallStrike,
		uint128 _newMinPutStrike,
		uint128 _newMaxPutStrike,
		uint128 _newMinExpiry,
		uint128 _newMaxExpiry
	) external {
		_onlyManager();
		optionParams.minCallStrikePrice = _newMinCallStrike;
		optionParams.maxCallStrikePrice = _newMaxCallStrike;
		optionParams.minPutStrikePrice = _newMinPutStrike;
		optionParams.maxPutStrikePrice = _newMaxPutStrike;
		optionParams.minExpiry = _newMinExpiry;
		optionParams.maxExpiry = _newMaxExpiry;
	}

	/**
	 * @notice set the bid ask spread used to price option buying
	 * @param _bidAskSpread the bid ask spread to update to
	 * @dev   only management or above can call this function
	 */
	function setBidAskSpread(uint256 _bidAskSpread) external {
		_onlyManager();
		bidAskIVSpread = _bidAskSpread;
	}

	/**
	 * @notice set the maximum percentage discount for an option
	 * @param _maxDiscount of the option as a percentage in 1e18 format. ie: 1*e18 == 1%
	 * @dev   only management or above can call this function
	 */
	function setMaxDiscount(uint256 _maxDiscount) external {
		_onlyManager();
		maxDiscount = _maxDiscount;
	}

	/**
	 * @notice set the maximum collateral amount allowed in the pool
	 * @param _collateralCap of the collateral held
	 * @dev   only governance can call this function
	 */
	function setCollateralCap(uint256 _collateralCap) external {
		_onlyGovernor();
		collateralCap = _collateralCap;
	}

	/**
	 * @notice update the liquidity pool buffer limit
	 * @param _bufferPercentage the minimum balance the liquidity pool must have as a percentage of collateral allocated to options. (for 20% enter 2000)
	 * @dev   only governance can call this function
	 */
	function setBufferPercentage(uint256 _bufferPercentage) external {
		_onlyGovernor();
		bufferPercentage = _bufferPercentage;
	}

	/**
	 * @notice update the liquidity pool risk free rate
	 * @param _riskFreeRate the risk free rate of the market
	 */
	function setRiskFreeRate(uint256 _riskFreeRate) external {
		_onlyGovernor();
		riskFreeRate = _riskFreeRate;
	}

	/**
	 * @notice update the max oracle time deviation threshold
	 */
	function setMaxTimeDeviationThreshold(uint256 _maxTimeDeviationThreshold) external {
		_onlyGovernor();
		maxTimeDeviationThreshold = _maxTimeDeviationThreshold;
	}

	/**
	 * @notice update the max oracle price deviation threshold
	 */
	function setMaxPriceDeviationThreshold(uint256 _maxPriceDeviationThreshold) external {
		_onlyGovernor();
		maxPriceDeviationThreshold = _maxPriceDeviationThreshold;
	}

	/**
	 * @notice change the status of a handler
	 */
	function changeHandler(address _handler, bool auth) external {
		_onlyGovernor();
		handler[_handler] = auth;
	}

	/**
	 * @notice change the status of a keeper
	 */
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
	}

	/**
	 *  @notice sets the parameters for the function that determines the utilization price factor
	 *  The function is made up of two parts, both linear. The line to the left of the utilisation threshold has a low gradient
	 *  while the gradient to the right of the threshold is much steeper. The aim of this function is to make options much more
	 *  expensive near full utilization while not having much effect at low utilizations.
	 *  @param _belowThresholdGradient the gradient of the function where utiization is below function threshold. e18
	 *  @param _aboveThresholdGradient the gradient of the line above the utilization threshold. e18
	 *  @param _utilizationFunctionThreshold the percentage utilization above which the function moves from its shallow line to its steep line
	 */
	function setUtilizationSkewParams(
		uint256 _belowThresholdGradient,
		uint256 _aboveThresholdGradient,
		uint256 _utilizationFunctionThreshold
	) external {
		_onlyManager();
		belowThresholdGradient = _belowThresholdGradient;
		aboveThresholdGradient = _aboveThresholdGradient;
		aboveThresholdYIntercept = _utilizationFunctionThreshold.mul(
			_aboveThresholdGradient - _belowThresholdGradient // inverted the order of the subtraction to result in a positive uint
		);

		utilizationFunctionThreshold = _utilizationFunctionThreshold;
	}

	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice function for hedging portfolio delta through external means
	 * @param delta the current portfolio delta
	 * @param reactorIndex the index of the reactor in the hedgingReactors array to use
	 */
	function rebalancePortfolioDelta(int256 delta, uint256 reactorIndex) external {
		_onlyManager();
		IHedgingReactor(hedgingReactors[reactorIndex]).hedgeDelta(delta);
	}

	/**
	 * @notice adjust the collateral held in a specific vault because of health
	 * @param lpCollateralDifference amount of collateral taken from or given to the liquidity pool in collateral decimals
	 * @param addToLpBalance true if collateral is returned to liquidity pool, false if collateral is withdrawn from liquidity pool
	 * @dev   called by the option registry only
	 */
	function adjustCollateral(uint256 lpCollateralDifference, bool addToLpBalance) external {
		IOptionRegistry optionRegistry = _getOptionRegistry();
		require(msg.sender == address(optionRegistry));
		// assumes in collateral decimals
		if (addToLpBalance) {
			collateralAllocated -= lpCollateralDifference;
		} else {
			SafeTransferLib.safeApprove(
				ERC20(collateralAsset),
				address(optionRegistry),
				lpCollateralDifference
			);
			collateralAllocated += lpCollateralDifference;
		}
	}

	/**
	 * @notice closes an oToken vault, returning collateral (minus ITM option expiry value) back to the pool
	 * @param seriesAddress the address of the oToken vault to close
	 * @return collatReturned the amount of collateral returned to the liquidity pool, assumes in collateral decimals
	 */
	function settleVault(address seriesAddress) external returns (uint256) {
		_isKeeper();
		// get number of options in vault and collateral returned to recalculate our position without these options
		// returns in collat decimals, collat decimals and e8
		(, uint256 collatReturned, uint256 collatLost, ) = _getOptionRegistry().settle(seriesAddress);
		emit SettleVault(seriesAddress, collatReturned, collatLost, msg.sender);
		// if the vault expired ITM then when settled the oracle will still have accounted for it as a liability. When
		// the settle happens the liability is wiped off as it is now accounted for in collateralAllocated but because the
		// oracle doesn't know this yet we need to temporarily reduce the liability value.
		_adjustVariables(collatReturned, collatLost, 0, false);
		collateralAllocated -= collatLost;
		return collatReturned;
	}

	/**
	 * @notice issue an option
	 * @param optionSeries the series detail of the option - strike decimals in e18
	 * @dev only callable by a handler contract
	 */
	function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address) {
		_isHandler();
		// series strike in e18
		return _issue(optionSeries, _getOptionRegistry());
	}

	/**
	 * @notice write an option that already exists
	 * @param optionSeries the series detail of the option - strike decimals in e8
	 * @param seriesAddress the series address of the oToken
	 * @param amount the number of options to write - in e18
	 * @param optionRegistry the registry used for options writing
	 * @param premium the premium of the option - in collateral decimals
	 * @param delta the delta of the option - in e18
	 * @param recipient the receiver of the option
	 * @dev only callable by a handler contract
	 */
	function handlerWriteOption(
		Types.OptionSeries memory optionSeries,
		address seriesAddress,
		uint256 amount,
		IOptionRegistry optionRegistry,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256) {
		_isTradingNotPaused();
		_isHandler();
		return
			_writeOption(
				optionSeries, // series strike in e8
				seriesAddress,
				amount, // in e18
				optionRegistry,
				premium, // in collat decimals
				delta,
				_checkBuffer(), // in e18
				recipient
			);
	}

	/**
	 * @notice write an option that doesnt exist
	 * @param optionSeries the series detail of the option - strike decimals in e18
	 * @param amount the number of options to write - in e18
	 * @param premium the premium of the option - in collateral decimals
	 * @param delta the delta of the option - in e18
	 * @param recipient the receiver of the option
	 * @dev only callable by a handler contract
	 */
	function handlerIssueAndWriteOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256, address) {
		_isTradingNotPaused();
		_isHandler();
		IOptionRegistry optionRegistry = _getOptionRegistry();
		// series strike passed in as e18
		address seriesAddress = _issue(optionSeries, optionRegistry);
		// series strike received in e8, retrieved from the option registry instead of
		// using one in memory because formatStrikePrice might have slightly changed the
		// strike
		optionSeries = optionRegistry.getSeriesInfo(seriesAddress);
		return (
			_writeOption(
				optionSeries, // strike in e8
				seriesAddress,
				amount, // in e18
				optionRegistry,
				premium, // in collat decimals
				delta,
				_checkBuffer(), // in e18
				recipient
			),
			seriesAddress
		);
	}

	/**
	 * @notice buy back an option that already exists
	 * @param optionSeries the series detail of the option - strike decimals in e8
	 * @param amount the number of options to buyback - in e18
	 * @param optionRegistry the registry used for options writing
	 * @param seriesAddress the series address of the oToken
	 * @param premium the premium of the option - in collateral decimals
	 * @param delta the delta of the option - in e18
	 * @param seller the receiver of the option
	 * @dev only callable by a handler contract
	 */
	function handlerBuybackOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		IOptionRegistry optionRegistry,
		address seriesAddress,
		uint256 premium,
		int256 delta,
		address seller
	) external returns (uint256) {
		_isTradingNotPaused();
		_isHandler();
		// strike passed in as e8
		return
			_buybackOption(optionSeries, amount, optionRegistry, seriesAddress, premium, delta, seller);
	}

	/**
	 * @notice reset the temporary portfolio and delta values that have been changed since the last oracle update
	 * @dev    only callable by the portfolio values feed oracle contract
	 */
	function resetEphemeralValues() external {
		require(msg.sender == address(_getPortfolioValuesFeed()));
		delete ephemeralLiabilities;
		delete ephemeralDelta;
	}

	/**
	 * @notice reset the temporary portfolio and delta values that have been changed since the last oracle update
	 * @dev    this function must be called in order to execute an epoch calculation
	 */
	function pauseTradingAndRequest() external returns (bytes32) {
		_isKeeper();
		// pause trading
		isTradingPaused = true;
		// make an oracle request
		return _getPortfolioValuesFeed().requestPortfolioData(underlyingAsset, strikeAsset);
	}

	/**
	 * @notice execute the epoch and set all the price per shares
	 * @dev    this function must be called in order to execute an epoch calculation and batch a mutual fund epoch
	 */
	function executeEpochCalculation() external whenNotPaused {
		_isKeeper();
		if (!isTradingPaused) {
			revert CustomErrors.TradingNotPaused();
		}
		uint256 newPricePerShare = totalSupply > 0
			? (1e18 *
				(_getNAV() -
					OptionsCompute.convertFromDecimals(pendingDeposits, ERC20(collateralAsset).decimals()))) /
				totalSupply
			: 1e18;
		uint256 sharesToMint = _sharesForAmount(pendingDeposits, newPricePerShare);
		epochPricePerShare[epoch] = newPricePerShare;
		delete pendingDeposits;
		isTradingPaused = false;
		emit EpochExecuted(epoch);
		epoch++;
		_mint(address(this), sharesToMint);
	}

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice function for adding liquidity to the options liquidity pool
	 * @param _amount    amount of the strike asset to deposit
	 * @return success
	 * @dev    entry point to provide liquidity to dynamic hedging vault
	 */
	function deposit(uint256 _amount) external whenNotPaused nonReentrant returns (bool) {
		if (_amount == 0) {
			revert CustomErrors.InvalidAmount();
		}
		_deposit(_amount);
		// Pull in tokens from sender
		SafeTransferLib.safeTransferFrom(collateralAsset, msg.sender, address(this), _amount);
		return true;
	}

	/**
	 * @notice function for allowing a user to redeem their shares from a previous epoch
	 * @param _shares the number of shares to redeem
	 * @return the number of shares actually returned
	 */
	function redeem(uint256 _shares) external nonReentrant returns (uint256) {
		if (_shares == 0) {
			revert CustomErrors.InvalidShareAmount();
		}
		return _redeem(_shares);
	}

	/**
	 * @notice function for initiating a withdraw request from the pool
	 * @param _shares    amount of shares to return
	 * @dev    entry point to remove liquidity to dynamic hedging vault
	 */
	function initiateWithdraw(uint256 _shares) external whenNotPaused nonReentrant {
		if (_shares == 0) {
			revert CustomErrors.InvalidShareAmount();
		}

		if (depositReceipts[msg.sender].amount > 0 || depositReceipts[msg.sender].unredeemedShares > 0) {
			// redeem so a user can use a completed deposit as shares for an initiation
			_redeem(type(uint256).max);
		}
		if (balanceOf[msg.sender] < _shares) {
			revert CustomErrors.InsufficientShareBalance();
		}
		uint256 currentEpoch = epoch;
		WithdrawalReceipt memory withdrawalReceipt = withdrawalReceipts[msg.sender];

		emit InitiateWithdraw(msg.sender, _shares, currentEpoch);
		uint256 existingShares = withdrawalReceipt.shares;
		uint256 withdrawalShares;
		// if they already have an initiated withdrawal from this round just increment
		if (withdrawalReceipt.epoch == currentEpoch) {
			withdrawalShares = existingShares + _shares;
		} else {
			// do 100 wei just in case of any rounding issues
			if (existingShares > 100) {
				revert CustomErrors.ExistingWithdrawal();
			}
			withdrawalShares = _shares;
			withdrawalReceipts[msg.sender].epoch = uint128(currentEpoch);
		}

		withdrawalReceipts[msg.sender].shares = uint128(withdrawalShares);
		transfer(address(this), _shares);
	}

	/**
	 * @notice function for completing the withdraw from a pool
	 * @param _shares    amount of shares to return
	 * @dev    entry point to remove liquidity to dynamic hedging vault
	 */
	function completeWithdraw(uint256 _shares) external whenNotPaused nonReentrant returns (uint256) {
		if (_shares == 0) {
			revert CustomErrors.InvalidShareAmount();
		}
		WithdrawalReceipt memory withdrawalReceipt = withdrawalReceipts[msg.sender];
		// cache the storage variables
		uint256 withdrawalShares = _shares > withdrawalReceipt.shares
			? withdrawalReceipt.shares
			: _shares;
		uint256 withdrawalEpoch = withdrawalReceipt.epoch;
		// make sure there is something to withdraw and make sure the round isnt the current one
		if (withdrawalShares == 0) {
			revert CustomErrors.NoExistingWithdrawal();
		}
		if (withdrawalEpoch == epoch) {
			revert CustomErrors.EpochNotClosed();
		}
		// reduced the stored share receipt by the shares requested
		withdrawalReceipts[msg.sender].shares -= uint128(withdrawalShares);
		// get the withdrawal amount based on the shares and pps at the epoch
		uint256 withdrawalAmount = _amountForShares(
			withdrawalShares,
			epochPricePerShare[withdrawalEpoch]
		);
		if (withdrawalAmount == 0) {
			revert CustomErrors.InvalidAmount();
		}
		// get the liquidity that can be withdrawn from the pool without hitting the collateral requirement buffer
		int256 buffer = int256((collateralAllocated * bufferPercentage) / MAX_BPS);
		int256 collatBalance = int256(ERC20(collateralAsset).balanceOf(address(this)));
		int256 bufferRemaining = collatBalance - buffer;
		// get the extra liquidity that is needed
		int256 amountNeeded = int256(withdrawalAmount) - bufferRemaining;
		// loop through the reactors and move funds if found
		if (amountNeeded > 0) {
			address[] memory hedgingReactors_ = hedgingReactors;
			for (uint8 i = 0; i < hedgingReactors_.length; i++) {
				amountNeeded -= int256(IHedgingReactor(hedgingReactors_[i]).withdraw(uint256(amountNeeded)));
				if (amountNeeded <= 0) {
					break;
				}
			}
			if (amountNeeded > 0) {
				revert CustomErrors.WithdrawExceedsLiquidity();
			}
		}
		emit Withdraw(msg.sender, withdrawalAmount, withdrawalShares);
		_burn(address(this), withdrawalShares);
		SafeTransferLib.safeTransfer(ERC20(collateralAsset), msg.sender, withdrawalAmount);
		return withdrawalAmount;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice Returning balance in 1e18 format
	 * @param asset address of the asset to get balance and normalize
	 * @return normalizedBalance balance in 1e18 format
	 */
	function _getNormalizedBalance(address asset)
		internal
		view
		returns (
			uint256 normalizedBalance
		)
	{
		normalizedBalance = OptionsCompute.convertFromDecimals(
			ERC20(asset).balanceOf(address(this)), 
			ERC20(asset).decimals()
			);
	}

	/**
	 * @notice get the delta of the hedging reactors
	 * @return externalDelta hedging reactor delta in e18 format
	 */
	function getExternalDelta() public view returns (int256 externalDelta) {
		address[] memory hedgingReactors_ = hedgingReactors;
		for (uint8 i = 0; i < hedgingReactors_.length; i++) {
			externalDelta += IHedgingReactor(hedgingReactors_[i]).getDelta();
		}
	}

	/**
	 * @notice get the delta of the portfolio
	 * @return portfolio delta
	 */
	function getPortfolioDelta() public view returns (int256) {
		// assumes in e18
		address underlyingAsset_ = underlyingAsset;
		address strikeAsset_ = strikeAsset;
		Types.PortfolioValues memory portfolioValues = _getPortfolioValuesFeed().getPortfolioValues(
			underlyingAsset_,
			strikeAsset_
		);
		// check that the portfolio values are acceptable
		OptionsCompute.validatePortfolioValues(
			_getUnderlyingPrice(underlyingAsset_, strikeAsset_),
			portfolioValues,
			maxTimeDeviationThreshold,
			maxPriceDeviationThreshold
		);
		return portfolioValues.delta + getExternalDelta() + ephemeralDelta;
	}

	/**
	 * @notice get the quote price and delta for a given option
	 * @param  optionSeries option type to quote - strike assumed in e18
	 * @param  amount the number of options to mint  - assumed in e18
	 * @param toBuy whether the protocol is buying the option
	 * @return quote the price of the options - returns in e18
	 * @return delta the delta of the options - returns in e18
	 */
	function quotePriceWithUtilizationGreeks(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		bool toBuy
	) external view returns (uint256 quote, int256 delta) {
		// using a struct to get around stack too deep issues
		UtilizationState memory quoteState;
		quoteState.underlyingPrice = _getUnderlyingPrice(
			optionSeries.underlying,
			optionSeries.strikeAsset
		);
		quoteState.iv = getImpliedVolatility(
			optionSeries.isPut,
			quoteState.underlyingPrice,
			optionSeries.strike,
			optionSeries.expiration
		);
		(uint256 optionQuote, int256 deltaQuote) = OptionsCompute.quotePriceGreeks(
			optionSeries,
			toBuy,
			bidAskIVSpread,
			riskFreeRate,
			quoteState.iv,
			quoteState.underlyingPrice
		);
		// price of acquiring total amount of options (remains e18 due to PRBMath)
		quoteState.totalOptionPrice = optionQuote.mul(amount);
		quoteState.totalDelta = deltaQuote.mul(int256(amount));

		// will update quoteState.utilizationPrice
		addUtilizationPremium(quoteState, optionSeries, amount, toBuy);
		quote = applyDeltaPremium(quoteState, toBuy);

		quote = OptionsCompute.convertToCollateralDenominated(
			quote,
			quoteState.underlyingPrice,
			optionSeries
		);
		delta = quoteState.totalDelta;
		if (quote == 0 || delta == int256(0)) {
			revert CustomErrors.DeltaQuoteError(quote, delta);
		}
	}

	/**
	 *	@notice applies a utilization premium when the protocol is selling options.
	 *	Stores the utilization price in quoteState.utilizationPrice for use in quotePriceWithUtilizationGreeks
	 *	@param quoteState the struct created in quoteStateWithUtilizationGreeks to store memory variables
	 *	@param optionSeries the option type for which we are quoting a price
	 *	@param amount the amount of options. e18
	 *	@param toBuy whether we are buying an option. False if selling
	 */
	function addUtilizationPremium(
		UtilizationState memory quoteState,
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		bool toBuy
	) internal view {
		if (!toBuy) {
			uint256 collateralAllocated_ = collateralAllocated;
			// if selling options, we want to add the utilization premium
			// Work out the utilization of the pool as a percentage
			quoteState.utilizationBefore = collateralAllocated_.div(
				collateralAllocated_ + ERC20(collateralAsset).balanceOf(address(this))
			);
			// assumes strike is e18
			// strike is not being used again so we dont care if format changes
			optionSeries.strike = optionSeries.strike / 1e10;
			// returns collateral decimals
			quoteState.collateralToAllocate = _getOptionRegistry().getCollateral(optionSeries, amount);

			quoteState.utilizationAfter = (quoteState.collateralToAllocate + collateralAllocated_).div(
				collateralAllocated_ + ERC20(collateralAsset).balanceOf(address(this))
			);
			// get the price of the option with the utilization premium added
			quoteState.utilizationPrice = OptionsCompute.getUtilizationPrice(
				quoteState.utilizationBefore,
				quoteState.utilizationAfter,
				quoteState.totalOptionPrice,
				utilizationFunctionThreshold,
				belowThresholdGradient,
				aboveThresholdGradient,
				aboveThresholdYIntercept
			);
		} else {
			// do not use utlilization premium for buybacks
			quoteState.utilizationPrice = quoteState.totalOptionPrice;
		}
	}

	/**
	 *	@notice Applies a discount or premium based on the liquidity pool's delta exposure
	 *	Gives discount if the transaction results in a lower delta exposure for the liquidity pool.
	 *	Prices option more richly if the transaction results in higher delta exposure for liquidity pool.
	 *	@param quoteState the struct created in quoteStateWithUtilizationGreeks to store memory variables
	 *	@param toBuy whether we are buying an option. False if selling
	 *	@return quote the quote for the option with the delta skew applied
	 */
	function applyDeltaPremium(UtilizationState memory quoteState, bool toBuy)
		internal
		view
		returns (uint256 quote)
	{
		// portfolio delta before writing option
		int256 portfolioDelta = getPortfolioDelta();
		// subtract totalDelta if buying as pool is taking on the negative of the option's delta
		int256 newDelta = toBuy
			? portfolioDelta + quoteState.totalDelta
			: portfolioDelta - quoteState.totalDelta;
		// Is delta moved closer to zero?
		quoteState.isDecreased = (PRBMathSD59x18.abs(newDelta) - PRBMathSD59x18.abs(portfolioDelta)) < 0;
		// delta exposure of the portolio per ETH equivalent value the portfolio holds.
		// This value is only used for tilting so we are only interested in its distance from 0 (its magnitude)
		uint256 normalizedDelta = uint256(PRBMathSD59x18.abs((portfolioDelta + newDelta).div(2e18))).div(
			_getNAV().div(quoteState.underlyingPrice)
		);
		// this is the percentage of the option price which is added to or subtracted from option price
		// according to whether portfolio delta is increased or decreased respectively
		quoteState.deltaTiltAmount = normalizedDelta > maxDiscount ? maxDiscount : normalizedDelta;

		if (quoteState.isDecreased) {
			quote = toBuy
				? quoteState.deltaTiltAmount.mul(quoteState.utilizationPrice) + quoteState.utilizationPrice
				: quoteState.utilizationPrice - quoteState.deltaTiltAmount.mul(quoteState.utilizationPrice);
		} else {
			// increase utilization by delta tilt factor for moving delta away from zero
			quote = toBuy
				? quoteState.utilizationPrice - quoteState.deltaTiltAmount.mul(quoteState.utilizationPrice)
				: quoteState.deltaTiltAmount.mul(quoteState.utilizationPrice) + quoteState.utilizationPrice;
		}
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	/**
	 * @notice get the current implied volatility from the feed
	 * @param isPut Is the option a call or put?
	 * @param underlyingPrice The underlying price - assumed in e18
	 * @param strikePrice The strike price of the option - assumed in e18
	 * @param expiration expiration timestamp of option as a PRBMath Float
	 * @return Implied volatility adjusted for volatility surface - assumed in e18
	 */
	function getImpliedVolatility(
		bool isPut,
		uint256 underlyingPrice,
		uint256 strikePrice,
		uint256 expiration
	) public view returns (uint256) {
		return _getVolatilityFeed().getImpliedVolatility(isPut, underlyingPrice, strikePrice, expiration);
	}

	function getAssets() external view returns (uint256) {
		return _getAssets();
	}

	function getNAV() external view returns (uint256) {
		return _getNAV();
	}

	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	/**
	 * @notice function for queueing to add liquidity to the options liquidity pool and receiving storing interest
	 *         to receive shares when the next epoch is initiated.
	 * @param _amount    amount of the strike asset to deposit
	 * @dev    internal function for entry point to provide liquidity to dynamic hedging vault
	 */
	function _deposit(uint256 _amount) internal {
		uint256 currentEpoch = epoch;
		// check the total allowed collateral amount isnt surpassed by incrementing the total assets with the amount denominated in e18
		uint256 totalAmountWithDeposit = _getAssets() +
			OptionsCompute.convertFromDecimals(_amount, ERC20(collateralAsset).decimals());
		if (totalAmountWithDeposit > collateralCap) {
			revert CustomErrors.TotalSupplyReached();
		}
		emit Deposit(msg.sender, _amount, currentEpoch);
		DepositReceipt memory depositReceipt = depositReceipts[msg.sender];
		// check for any unredeemed shares
		uint256 unredeemedShares = uint256(depositReceipt.unredeemedShares);
		// if there is already a receipt from a previous round then acknowledge and record it
		if (depositReceipt.epoch != 0 && depositReceipt.epoch < currentEpoch) {
			unredeemedShares += _sharesForAmount(
				depositReceipt.amount,
				epochPricePerShare[depositReceipt.epoch]
			);
		}
		uint256 depositAmount = _amount;
		// if there is a second deposit in the same round then increment this amount
		if (currentEpoch == depositReceipt.epoch) {
			depositAmount += uint256(depositReceipt.amount);
		}
		require(depositAmount <= type(uint128).max, "overflow");
		// create the deposit receipt
		depositReceipts[msg.sender] = DepositReceipt({
			epoch: uint128(currentEpoch),
			amount: uint128(depositAmount),
			unredeemedShares: unredeemedShares
		});
		pendingDeposits += _amount;
	}

	/**
	 * @notice functionality for allowing a user to redeem their shares from a previous epoch
	 * @param _shares the number of shares to redeem
	 * @return toRedeem the number of shares actually returned
	 */
	function _redeem(uint256 _shares) internal returns (uint256 toRedeem) {
		DepositReceipt memory depositReceipt = depositReceipts[msg.sender];
		uint256 currentEpoch = epoch;
		// check for any unredeemed shares
		uint256 unredeemedShares = uint256(depositReceipt.unredeemedShares);
		// if there is already a receipt from a previous round then acknowledge and record it
		if (depositReceipt.epoch != 0 && depositReceipt.epoch < currentEpoch) {
			unredeemedShares += _sharesForAmount(
				depositReceipt.amount,
				epochPricePerShare[depositReceipt.epoch]
			);
		}
		// if the shares requested are greater than their unredeemedShares then floor to unredeemedShares, otherwise
		// use their requested share number
		toRedeem = _shares > unredeemedShares ? unredeemedShares : _shares;
		if (toRedeem == 0) {
			return 0;
		}
		// if the deposit receipt is on this epoch and there are unredeemed shares then we leave amount as is,
		// if the epoch has past then we set the amount to 0 and take from the unredeemedShares
		if (depositReceipt.epoch < currentEpoch) {
			depositReceipts[msg.sender].amount = 0;
		}
		depositReceipts[msg.sender].unredeemedShares = uint128(unredeemedShares - toRedeem);
		emit Redeem(msg.sender, toRedeem, depositReceipt.epoch);
		allowance[address(this)][msg.sender] = toRedeem;
		// transfer as the shares will have been minted in the epoch execution
		transferFrom(address(this), msg.sender, toRedeem);
	}

	/**
	 * @notice get the number of shares for a given amount
	 * @param _amount  the amount to convert to shares - assumed in collateral decimals
	 * @return shares the number of shares based on the amount - assumed in e18
	 */
	function _sharesForAmount(uint256 _amount, uint256 assetPerShare)
		internal
		view
		returns (uint256 shares)
	{
		uint256 convertedAmount = OptionsCompute.convertFromDecimals(
			_amount,
			ERC20(collateralAsset).decimals()
		);
		shares = (convertedAmount * PRBMath.SCALE) / assetPerShare;
	}

	/**
	 * @notice get the amount for a given number of shares
	 * @param _shares  the shares to convert to amount in e18
	 * @return amount the number of amount based on shares in collateral decimals
	 */
	function _amountForShares(uint256 _shares, uint256 _assetPerShare)
		internal
		view
		returns (uint256 amount)
	{
		amount = OptionsCompute.convertToDecimals(
			(_shares * _assetPerShare) / PRBMath.SCALE,
			ERC20(collateralAsset).decimals()
		);
	}

	/**
	 * @notice get the Net Asset Value
	 * @return Net Asset Value in e18 decimal format
	 */
	function _getNAV() internal view returns (uint256) {
		// cache
		address underlyingAsset_ = underlyingAsset;
		address strikeAsset_ = strikeAsset;
		// equities = assets - liabilities
		// assets: Any token such as eth usd, collateral sent to OptionRegistry, hedging reactor stuff in e18
		// liabilities: Options that we wrote in e18
		uint256 assets = _getAssets();
		Types.PortfolioValues memory portfolioValues = _getPortfolioValuesFeed().getPortfolioValues(
			underlyingAsset_,
			strikeAsset_
		);
		// check that the portfolio values are acceptable
		OptionsCompute.validatePortfolioValues(
			_getUnderlyingPrice(underlyingAsset_, strikeAsset_),
			portfolioValues,
			maxTimeDeviationThreshold,
			maxPriceDeviationThreshold
		);
		int256 ephemeralLiabilities_ = ephemeralLiabilities;
		// ephemeralLiabilities can be -ve but portfolioValues will not
		// when converting liabilities it should never be -ve, if it is then the NAV calc will fail
		uint256 liabilities = portfolioValues.callPutsValue +
			(ephemeralLiabilities_ > 0 ? uint256(ephemeralLiabilities_) : uint256(-ephemeralLiabilities_));
		return assets - liabilities;
	}

	/**
	 * @notice get the Asset Value
	 * @return assets Asset Value in e18 decimal format
	 */
	function _getAssets() internal view returns (uint256 assets) {
		address collateralAsset_ = collateralAsset;
		// assets: Any token such as eth usd, collateral sent to OptionRegistry, hedging reactor stuff in e18
		// liabilities: Options that we wrote in e18
		assets = OptionsCompute.convertFromDecimals(
			ERC20(collateralAsset_).balanceOf(address(this)),
			ERC20(collateralAsset_).decimals()
		) + OptionsCompute.convertFromDecimals(collateralAllocated, ERC20(collateralAsset_).decimals());
		address[] memory hedgingReactors_ = hedgingReactors;
		for (uint8 i = 0; i < hedgingReactors_.length; i++) {
			// should always return value in e18 decimals
			assets += IHedgingReactor(hedgingReactors_[i]).getPoolDenominatedValue();
		}
	}

	/**
	 * @notice calculates amount of liquidity that can be used before hitting buffer
	 * @return bufferRemaining the amount of liquidity available before reaching buffer in e18
	 */
	function _checkBuffer() internal view returns (int256 bufferRemaining) {
		// calculate max amount of liquidity pool funds that can be used before reaching max buffer allowance
		uint256 normalizedCollateralBalance = _getNormalizedBalance(collateralAsset);
		bufferRemaining = int256(
			normalizedCollateralBalance -
				(OptionsCompute.convertFromDecimals(collateralAllocated, ERC20(collateralAsset).decimals()) *
					bufferPercentage) /
				MAX_BPS
		);
		// revert CustomErrors.if buffer allowance already hit
		if (bufferRemaining <= 0) {
			revert CustomErrors.MaxLiquidityBufferReached();
		}
	}

	/**
	 * @notice create the option contract in the options registry
	 * @param  optionSeries option type to mint - option series strike in e18
	 * @param  optionRegistry interface for the options issuer
	 * @return series the address of the option series minted
	 */
	function _issue(Types.OptionSeries memory optionSeries, IOptionRegistry optionRegistry)
		internal
		returns (address series)
	{
		// make sure option is being issued with correct assets
		if (optionSeries.collateral != collateralAsset) {
			revert CustomErrors.CollateralAssetInvalid();
		}
		if (optionSeries.underlying != underlyingAsset) {
			revert CustomErrors.UnderlyingAssetInvalid();
		}
		if (optionSeries.strikeAsset != strikeAsset) {
			revert CustomErrors.StrikeAssetInvalid();
		}
		// cache
		Types.OptionParams memory optionParams_ = optionParams;
		// check the expiry is within the allowed bounds
		if (
			block.timestamp + optionParams_.minExpiry > optionSeries.expiration ||
			optionSeries.expiration > block.timestamp + optionParams_.maxExpiry
		) {
			revert CustomErrors.OptionExpiryInvalid();
		}
		// check that the option strike is within the range of the min and max acceptable strikes of calls and puts
		if (optionSeries.isPut) {
			if (
				optionParams_.minPutStrikePrice > optionSeries.strike ||
				optionSeries.strike > optionParams_.maxPutStrikePrice
			) {
				revert CustomErrors.OptionStrikeInvalid();
			}
		} else {
			if (
				optionParams_.minCallStrikePrice > optionSeries.strike ||
				optionSeries.strike > optionParams_.maxCallStrikePrice
			) {
				revert CustomErrors.OptionStrikeInvalid();
			}
		}
		// issue the option from the option registry (its characteristics will be stored in the optionsRegistry)
		series = optionRegistry.issue(optionSeries);
		if (series == address(0)) {
			revert CustomErrors.IssuanceFailed();
		}
	}

	/**
	 * @notice write a number of options for a given OptionSeries
	 * @param  optionSeries option type to mint - strike in e8
	 * @param  seriesAddress the address of the options series
	 * @param  amount the amount to be written - in e18
	 * @param  optionRegistry the option registry of the pool
	 * @param  premium the premium to charge the user - in collateral decimals
	 * @param  delta the delta of the option position - in e18
	 * @param  bufferRemaining the amount of buffer that can be used - in e18
	 * @return the amount that was written
	 */
	function _writeOption(
		Types.OptionSeries memory optionSeries,
		address seriesAddress,
		uint256 amount,
		IOptionRegistry optionRegistry,
		uint256 premium,
		int256 delta,
		int256 bufferRemaining,
		address recipient
	) internal returns (uint256) {
		// strike decimals come into this function as e8
		uint256 collateralAmount = optionRegistry.getCollateral(optionSeries, amount);
		if (
			uint256(bufferRemaining) <
			OptionsCompute.convertFromDecimals(collateralAmount, ERC20(collateralAsset).decimals())
		) {
			revert CustomErrors.MaxLiquidityBufferReached();
		}
		ERC20(collateralAsset).approve(address(optionRegistry), collateralAmount);
		(, collateralAmount) = optionRegistry.open(seriesAddress, amount, collateralAmount);
		emit WriteOption(seriesAddress, amount, premium, collateralAmount, recipient);
		// convert e8 strike to e18 strike
		optionSeries.strike = uint128(
			OptionsCompute.convertFromDecimals(optionSeries.strike, ERC20(seriesAddress).decimals())
		);
		_adjustVariables(collateralAmount, premium, delta, true);
		SafeTransferLib.safeTransfer(
			ERC20(seriesAddress),
			recipient,
			OptionsCompute.convertToDecimals(amount, ERC20(seriesAddress).decimals())
		);
		// returns in e18
		return amount;
	}

	/**
	 * @notice buys a number of options back and burns the tokens
	 * @param optionSeries the option token series to buyback - strike passed in as e8
	 * @param amount the number of options to buyback expressed in 1e18
	 * @param optionRegistry the registry
	 * @param seriesAddress the series being sold
	 * @param premium the premium to be sent back to the owner (in collat decimals)
	 * @param delta the delta of the option
	 * @param seller the address
	 * @return the number of options burned in e18
	 */
	function _buybackOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		IOptionRegistry optionRegistry,
		address seriesAddress,
		uint256 premium,
		int256 delta,
		address seller
	) internal returns (uint256) {
		SafeTransferLib.safeApprove(
			ERC20(seriesAddress),
			address(optionRegistry),
			OptionsCompute.convertToDecimals(amount, ERC20(seriesAddress).decimals())
		);
		(, uint256 collateralReturned) = optionRegistry.close(seriesAddress, amount);
		emit BuybackOption(seriesAddress, amount, premium, collateralReturned, seller);
		// convert e8 strike to e18 strike
		optionSeries.strike = uint128(
			OptionsCompute.convertFromDecimals(optionSeries.strike, ERC20(seriesAddress).decimals())
		);
		_adjustVariables(collateralReturned, premium, delta, false);
		SafeTransferLib.safeTransfer(ERC20(collateralAsset), seller, premium);
		return amount;
	}

	/**
	 * @notice adjust the variables of the pool
	 * @param  collateralAmount the amount of collateral transferred to change on collateral allocated in collateral decimals
	 * @param  optionsValue the value of the options in e18 decimals
	 * @param  delta the delta of the options in e18 decimals
	 * @param  isSale whether the action was an option sale or not
	 */
	function _adjustVariables(
		uint256 collateralAmount,
		uint256 optionsValue,
		int256 delta,
		bool isSale
	) internal {
		if (isSale) {
			collateralAllocated += collateralAmount;
			ephemeralLiabilities += int256(
				OptionsCompute.convertFromDecimals(optionsValue, ERC20(collateralAsset).decimals())
			);
			ephemeralDelta -= delta;
		} else {
			collateralAllocated -= collateralAmount;
			ephemeralLiabilities -= int256(
				OptionsCompute.convertFromDecimals(optionsValue, ERC20(collateralAsset).decimals())
			);
			ephemeralDelta += delta;
		}
	}

	/**
	 * @notice get the volatility feed used by the liquidity pool
	 * @return the volatility feed contract interface
	 */
	function _getVolatilityFeed() internal view returns (VolatilityFeed) {
		return VolatilityFeed(protocol.volatilityFeed());
	}

	/**
	 * @notice get the portfolio values feed used by the liquidity pool
	 * @return the portfolio values feed contract
	 */
	function _getPortfolioValuesFeed() internal view returns (IPortfolioValuesFeed) {
		return IPortfolioValuesFeed(protocol.portfolioValuesFeed());
	}

	/**
	 * @notice get the option registry used for storing and managing the options
	 * @return the option registry contract
	 */
	function _getOptionRegistry() internal view returns (IOptionRegistry) {
		return IOptionRegistry(protocol.optionRegistry());
	}

	/**
	 * @notice get the underlying price with just the underlying asset and strike asset
	 * @param underlying   the asset that is used as the reference asset
	 * @param _strikeAsset the asset that the underlying value is denominated in
	 * @return the underlying price
	 */
	function _getUnderlyingPrice(address underlying, address _strikeAsset)
		internal
		view
		returns (uint256)
	{
		return PriceFeed(protocol.priceFeed()).getNormalizedRate(underlying, _strikeAsset);
	}

	function _isTradingNotPaused() internal view {
		if (isTradingPaused) {
			revert CustomErrors.TradingPaused();
		}
	}

	function _isHandler() internal view {
		if (!handler[msg.sender]) {
			revert CustomErrors.NotHandler();
		}
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] && msg.sender != authority.governor() && msg.sender != authority.manager()
		) {
			revert CustomErrors.NotKeeper();
		}
	}
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
		uint256 callPutsValue;
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface CustomErrors {
	error NotKeeper();
	error IVNotFound();
	error NotHandler();
	error InvalidPrice();
	error InvalidBuyer();
	error OrderExpired();
	error InvalidAmount();
	error TradingPaused();
	error IssuanceFailed();
	error EpochNotClosed();
	error TradingNotPaused();
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
	error CollateralAssetInvalid();
	error UnderlyingAssetInvalid();
	error CollateralAmountInvalid();
	error WithdrawExceedsLiquidity();
	error InsufficientShareBalance();
	error MaxLiquidityBufferReached();
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
	 * @param a new value in e18
	 * @param b old value in e18
	 * @return uint256 the percentage change in e18
	 */
	function calculatePercentageChange(uint256 a, uint256 b) internal pure returns (uint256) {
		// ((b - a) * 1e18) / a
		// then get the absolute value for the diff
		return uint256((((int256(b) - int256(a)) * (1e18)) / (int256(a))).abs());
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SafeTransferLib.sol";

import { Types } from "./Types.sol";
import { IOtokenFactory, IOtoken, IController, GammaTypes } from "../interfaces/GammaInterface.sol";

/**
 *  @title Library used for standard interactions with the opyn-rysk gamma protocol
 *   @dev inherited by the options registry to complete base opyn-rysk gamma protocol interactions
 *        Interacts with the opyn-rysk gamma protocol in all functions
 */
library OpynInteractions {
	uint256 private constant SCALE_FROM = 10**10;
	error NoShort();

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param oTokenFactory is the address of the opyn oTokenFactory
	 * @param collateral asset that is held as collateral against short/written options
	 * @param underlying is the address of the underlying asset of the option
	 * @param strikeAsset is the address of the collateral asset of the option
	 * @param strike is the strike price of the option in 1e8 format
	 * @param expiration is the expiry timestamp of the option
	 * @param isPut the type of option
	 * @return the address of the option
	 */
	function getOrDeployOtoken(
		address oTokenFactory,
		address collateral,
		address underlying,
		address strikeAsset,
		uint256 strike,
		uint256 expiration,
		bool isPut
	) external returns (address) {
		IOtokenFactory factory = IOtokenFactory(oTokenFactory);

		address otokenFromFactory = factory.getOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);

		if (otokenFromFactory != address(0)) {
			return otokenFromFactory;
		}

		address otoken = factory.createOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);

		return otoken;
	}

	/**
	 * @notice Retrieves the option token if it already exists
	 * @param oTokenFactory is the address of the opyn oTokenFactory
	 * @param collateral asset that is held as collateral against short/written options
	 * @param underlying is the address of the underlying asset of the option
	 * @param strikeAsset is the address of the collateral asset of the option
	 * @param strike is the strike price of the option in 1e8 format
	 * @param expiration is the expiry timestamp of the option
	 * @param isPut the type of option
	 * @return otokenFromFactory the address of the option
	 */
	function getOtoken(
		address oTokenFactory,
		address collateral,
		address underlying,
		address strikeAsset,
		uint256 strike,
		uint256 expiration,
		bool isPut
	) external view returns (address otokenFromFactory) {
		IOtokenFactory factory = IOtokenFactory(oTokenFactory);
		otokenFromFactory = factory.getOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);
	}

	/**
	 * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin contract which holds the collateral
	 * @param oTokenAddress is the address of the otoken to mint
	 * @param depositAmount is the amount of collateral to deposit
	 * @param vaultId is the vault id to use for creating this short
	 * @param amount is the mint amount in 1e18 format
	 * @param vaultType is the type of vault to be created
	 * @return the otoken mint amount
	 */
	function createShort(
		address gammaController,
		address marginPool,
		address oTokenAddress,
		uint256 depositAmount,
		uint256 vaultId,
		uint256 amount,
		uint256 vaultType
	) external returns (uint256) {
		IController controller = IController(gammaController);
		amount = amount / SCALE_FROM;
		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		IOtoken oToken = IOtoken(oTokenAddress);
		address collateralAsset = oToken.collateralAsset();

		// double approve to fix non-compliant ERC20s
		ERC20 collateralToken = ERC20(collateralAsset);
		SafeTransferLib.safeApprove(collateralToken, marginPool, depositAmount);
		// initialise the controller args with 2 incase the vault already exists
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](2);
		// check if a new vault needs to be created
		uint256 newVaultID = (controller.getAccountVaultCounter(address(this))) + 1;
		if (newVaultID == vaultId) {
			actions = new IController.ActionArgs[](3);

			actions[0] = IController.ActionArgs(
				IController.ActionType.OpenVault,
				address(this), // owner
				address(this), // receiver
				address(0), // asset, otoken
				vaultId, // vaultId
				0, // amount
				0, //index
				abi.encode(vaultType) //data
			);

			actions[1] = IController.ActionArgs(
				IController.ActionType.DepositCollateral,
				address(this), // owner
				address(this), // address to transfer from
				collateralAsset, // deposited asset
				vaultId, // vaultId
				depositAmount, // amount
				0, //index
				"" //data
			);

			actions[2] = IController.ActionArgs(
				IController.ActionType.MintShortOption,
				address(this), // owner
				address(this), // address to transfer to
				oTokenAddress, // option address
				vaultId, // vaultId
				amount, // amount
				0, //index
				"" //data
			);
		} else {
			actions[0] = IController.ActionArgs(
				IController.ActionType.DepositCollateral,
				address(this), // owner
				address(this), // address to transfer from
				collateralAsset, // deposited asset
				vaultId, // vaultId
				depositAmount, // amount
				0, //index
				"" //data
			);

			actions[1] = IController.ActionArgs(
				IController.ActionType.MintShortOption,
				address(this), // owner
				address(this), // address to transfer to
				oTokenAddress, // option address
				vaultId, // vaultId
				amount, // amount
				0, //index
				"" //data
			);
		}

		controller.operate(actions);
		// returns in e8
		return amount;
	}

	/**
	 * @notice Deposits Collateral to a specific vault
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin contract which holds the collateral
	 * @param collateralAsset is the address of the collateral asset to deposit
	 * @param depositAmount is the amount of collateral to deposit
	 * @param vaultId is the vault id to access
	 */
	function depositCollat(
		address gammaController,
		address marginPool,
		address collateralAsset,
		uint256 depositAmount,
		uint256 vaultId
	) external {
		IController controller = IController(gammaController);
		// double approve to fix non-compliant ERC20s
		ERC20 collateralToken = ERC20(collateralAsset);
		SafeTransferLib.safeApprove(collateralToken, marginPool, depositAmount);
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.DepositCollateral,
			address(this), // owner
			address(this), // address to transfer from
			collateralAsset, // deposited asset
			vaultId, // vaultId
			depositAmount, // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
	}

	/**
	 * @notice Withdraws Collateral from a specific vault
	 * @param gammaController is the address of the opyn controller contract
	 * @param collateralAsset is the address of the collateral asset to withdraw
	 * @param withdrawAmount is the amount of collateral to withdraw
	 * @param vaultId is the vault id to access
	 */
	function withdrawCollat(
		address gammaController,
		address collateralAsset,
		uint256 withdrawAmount,
		uint256 vaultId
	) external {
		IController controller = IController(gammaController);

		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.WithdrawCollateral,
			address(this), // owner
			address(this), // address to transfer to
			collateralAsset, // withdrawn asset
			vaultId, // vaultId
			withdrawAmount, // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
	}

	/**
	 * @notice Burns an opyn short position and returns collateral back to OptionRegistry
	 * @param gammaController is the address of the opyn controller contract
	 * @param oTokenAddress is the address of the otoken to burn
	 * @param burnAmount is the amount of options to burn
	 * @param vaultId is the vault id used that holds the short
	 * @return the collateral returned amount
	 */
	function burnShort(
		address gammaController,
		address oTokenAddress,
		uint256 burnAmount,
		uint256 vaultId
	) external returns (uint256) {
		IController controller = IController(gammaController);
		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		IOtoken oToken = IOtoken(oTokenAddress);
		ERC20 collateralAsset = ERC20(oToken.collateralAsset());
		uint256 startCollatBalance = collateralAsset.balanceOf(address(this));
		GammaTypes.Vault memory vault = controller.getVault(address(this), vaultId);
		// initialise the controller args with 2 incase the vault already exists
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](2);

		actions[0] = IController.ActionArgs(
			IController.ActionType.BurnShortOption,
			address(this), // owner
			address(this), // address to transfer from
			oTokenAddress, // oToken address
			vaultId, // vaultId
			burnAmount, // amount to burn
			0, //index
			"" //data
		);

		actions[1] = IController.ActionArgs(
			IController.ActionType.WithdrawCollateral,
			address(this), // owner
			address(this), // address to transfer to
			address(collateralAsset), // withdrawn asset
			vaultId, // vaultId
			(vault.collateralAmounts[0] * burnAmount) / vault.shortAmounts[0], // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
		// returns in collateral decimals
		return collateralAsset.balanceOf(address(this)) - startCollatBalance;
	}

	/**
	 * @notice Close the existing short otoken position.
	 * @param gammaController is the address of the opyn controller contract
	 * @param vaultId is the id of the vault to be settled
	 * @return collateralRedeemed collateral redeemed from the vault
	 * @return collateralLost collateral left behind in vault used to pay ITM expired options
	 * @return shortAmount number of options that were written
	 */
	function settle(address gammaController, uint256 vaultId)
		external
		returns (
			uint256 collateralRedeemed,
			uint256 collateralLost,
			uint256 shortAmount
		)
	{
		IController controller = IController(gammaController);

		GammaTypes.Vault memory vault = controller.getVault(address(this), vaultId);
		if (vault.shortOtokens.length == 0) {
			revert NoShort();
		}

		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		ERC20 collateralToken = ERC20(vault.collateralAssets[0]);

		// This is equivalent to doing ERC20(vault.asset).balanceOf(address(this))
		uint256 startCollateralBalance = collateralToken.balanceOf(address(this));

		// If it is after expiry, we need to settle the short position using the normal way
		// Delete the vault and withdraw all remaining collateral from the vault
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.SettleVault,
			address(this), // owner
			address(this), // address to transfer to
			address(0), // not used
			vaultId, // vaultId
			0, // not used
			0, // not used
			"" // not used
		);

		controller.operate(actions);

		uint256 endCollateralBalance = collateralToken.balanceOf(address(this));
		// calulate collateral redeemed and lost for collateral management in liquidity pool
		collateralRedeemed = endCollateralBalance - startCollateralBalance;
		// returns in collateral decimals, collateralDecimals, e8
		return (
			collateralRedeemed,
			vault.collateralAmounts[0] - collateralRedeemed,
			vault.shortAmounts[0]
		);
	}

	/**
	 * @notice Exercises an ITM option
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin pool
	 * @param series is the address of the option to redeem
	 * @param amount is the number of oTokens to redeem - passed in as e8
	 * @return amount of asset received by exercising the option
	 */
	function redeem(
		address gammaController,
		address marginPool,
		address series,
		uint256 amount
	) external returns (uint256) {
		IController controller = IController(gammaController);
		address collateralAsset = IOtoken(series).collateralAsset();
		uint256 startAssetBalance = ERC20(collateralAsset).balanceOf(msg.sender);

		// If it is after expiry, we need to redeem the profits
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.Redeem,
			address(0), // not used
			msg.sender, // address to send profits to
			series, // address of otoken
			0, // not used
			amount, // otoken balance
			0, // not used
			"" // not used
		);
		SafeTransferLib.safeApprove(ERC20(series), marginPool, amount);
		controller.operate(actions);

		uint256 endAssetBalance = ERC20(collateralAsset).balanceOf(msg.sender);
		// returns in collateral decimals
		return endAssetBalance - startAssetBalance;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IOracle {
	function getPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IMarginCalculator {
	function getNakedMarginRequired(
		address _underlying,
		address _strike,
		address _collateral,
		uint256 _shortAmount,
		uint256 _strikePrice,
		uint256 _underlyingPrice,
		uint256 _shortExpiryTimestamp,
		uint256 _collateralDecimals,
		bool _isPut
	) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface AddressBookInterface {
	/* Getters */

	function getOtokenImpl() external view returns (address);

	function getOtokenFactory() external view returns (address);

	function getWhitelist() external view returns (address);

	function getController() external view returns (address);

	function getOracle() external view returns (address);

	function getMarginPool() external view returns (address);

	function getMarginCalculator() external view returns (address);

	function getLiquidationManager() external view returns (address);

	function getAddress(bytes32 _id) external view returns (address);

	/* Setters */

	function setOtokenImpl(address _otokenImpl) external;

	function setOtokenFactory(address _factory) external;

	function setOracleImpl(address _otokenImpl) external;

	function setWhitelist(address _whitelist) external;

	function setController(address _controller) external;

	function setMarginPool(address _marginPool) external;

	function setMarginCalculator(address _calculator) external;

	function setLiquidationManager(address _liquidationManager) external;

	function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library GammaTypes {
	// vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
	struct Vault {
		// addresses of oTokens a user has shorted (i.e. written) against this vault
		address[] shortOtokens;
		// addresses of oTokens a user has bought and deposited in this vault
		// user can be long oTokens without opening a vault (e.g. by buying on a DEX)
		// generally, long oTokens will be 'deposited' in vaults to act as collateral
		// in order to write oTokens against (i.e. in spreads)
		address[] longOtokens;
		// addresses of other ERC-20s a user has deposited as collateral in this vault
		address[] collateralAssets;
		// quantity of oTokens minted/written for each oToken address in shortOtokens
		uint256[] shortAmounts;
		// quantity of oTokens owned and held in the vault for each oToken address in longOtokens
		uint256[] longAmounts;
		// quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
		uint256[] collateralAmounts;
	}

	// vaultLiquidationDetails is a struct of 3 variables that store the series address, short amount liquidated and collateral transferred for
	// a given liquidation
	struct VaultLiquidationDetails {
		address series;
		uint128 shortAmount;
		uint128 collateralAmount;
	}
}

interface IOtoken {
	function underlyingAsset() external view returns (address);

	function strikeAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	function strikePrice() external view returns (uint256);

	function expiryTimestamp() external view returns (uint256);

	function isPut() external view returns (bool);
}

interface IOtokenFactory {
	function getOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	function createOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external returns (address);

	function getTargetOtokenAddress(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	event OtokenCreated(
		address tokenAddress,
		address creator,
		address indexed underlying,
		address indexed strike,
		address indexed collateral,
		uint256 strikePrice,
		uint256 expiry,
		bool isPut
	);
}

interface IController {
	// possible actions that can be performed
	enum ActionType {
		OpenVault,
		MintShortOption,
		BurnShortOption,
		DepositLongOption,
		WithdrawLongOption,
		DepositCollateral,
		WithdrawCollateral,
		SettleVault,
		Redeem,
		Call,
		Liquidate
	}

	struct ActionArgs {
		// type of action that is being performed on the system
		ActionType actionType;
		// address of the account owner
		address owner;
		// address which we move assets from or to (depending on the action type)
		address secondAddress;
		// asset that is to be transfered
		address asset;
		// index of the vault that is to be modified (if any)
		uint256 vaultId;
		// amount of asset that is to be transfered
		uint256 amount;
		// each vault can hold multiple short / long / collateral assets
		// but we are restricting the scope to only 1 of each in this version
		// in future versions this would be the index of the short / long / collateral asset that needs to be modified
		uint256 index;
		// any other data that needs to be passed in for arbitrary function calls
		bytes data;
	}

	struct RedeemArgs {
		// address to which we pay out the oToken proceeds
		address receiver;
		// oToken that is to be redeemed
		address otoken;
		// amount of oTokens that is to be redeemed
		uint256 amount;
	}

	function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

	function operate(ActionArgs[] calldata _actions) external;

	function getAccountVaultCounter(address owner) external view returns (uint256);

	function oracle() external view returns (address);

	function getVault(address _owner, uint256 _vaultId)
		external
		view
		returns (GammaTypes.Vault memory);

	function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

	function isSettlementAllowed(
		address _underlying,
		address _strike,
		address _collateral,
		uint256 _expiry
	) external view returns (bool);

	function clearVaultLiquidationDetails(uint256 _vaultId) external;

	function getVaultLiquidationDetails(address _owner, uint256 _vaultId)
		external
		view
		returns (
			address,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used for storage of important contracts for the liquidity pool
 */
contract Protocol is AccessControl {
	////////////////////////
	/// static variables ///
	////////////////////////

	address public immutable optionRegistry;
	address public immutable priceFeed;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	address public volatilityFeed;
	address public portfolioValuesFeed;

	constructor(
		address _optionRegistry,
		address _priceFeed,
		address _volatilityFeed,
		address _portfolioValuesFeed,
		address _authority
	) AccessControl(IAuthority(_authority)) {
		optionRegistry = _optionRegistry;
		priceFeed = _priceFeed;
		volatilityFeed = _volatilityFeed;
		portfolioValuesFeed = _portfolioValuesFeed;
	}

	///////////////
	/// setters ///
	///////////////

	function changeVolatilityFeed(address _volFeed) external {
		_onlyGovernor();
		volatilityFeed = _volFeed;
	}

	function changePortfolioValuesFeed(address _portfolioValuesFeed) external {
		_onlyGovernor();
		portfolioValuesFeed = _portfolioValuesFeed;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./interfaces/IERC20.sol";
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
		(, int256 rate, , , ) = feed.latestRoundData();
		return uint256(rate);
	}

	/// @dev get the rate from chainlink and convert it to e18 decimals
	function getNormalizedRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		uint8 feedDecimals = feed.decimals();
		(, int256 rate, , , ) = feed.latestRoundData();
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
pragma solidity >=0.8.9;

import "./libraries/AccessControl.sol";
import "./libraries/CustomErrors.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 *  @title Contract used as the Dynamic Hedging Vault for storing funds, issuing shares and processing options transactions
 *  @dev Interacts with liquidity pool to feed in volatility data.
 */
contract VolatilityFeed is AccessControl {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	// skew parameters for calls
	int256[7] public callsVolatilitySkew;
	// skew parameters for puts
	int256[7] public putsVolatilitySkew;
	// keeper mapping
	mapping(address => bool) public keeper;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// number of seconds in a year used for calculations
	uint256 private constant ONE_YEAR_SECONDS = 31557600;

	constructor(address _authority) AccessControl(IAuthority(_authority)) {}

	///////////////
	/// setters ///
	///////////////

	/**
	 * @notice set the volatility skew of the pool
	 * @param values the parameters of the skew
	 * @param isPut the option type, put or call?
	 * @dev   only governance can call this function
	 */
	function setVolatilitySkew(int256[7] calldata values, bool isPut) external {
		_isKeeper();
		if (!isPut) {
			callsVolatilitySkew = values;
		} else {
			putsVolatilitySkew = values;
		}
	}

	/// @notice update the keepers
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice get the current implied volatility from the feed
	 * @param isPut Is the option a call or put?
	 * @param underlyingPrice The underlying price
	 * @param strikePrice The strike price of the option
	 * @param expiration expiration timestamp of option as a PRBMath Float
	 * @return Implied volatility adjusted for volatility surface
	 */
	function getImpliedVolatility(
		bool isPut,
		uint256 underlyingPrice,
		uint256 strikePrice,
		uint256 expiration
	) external view returns (uint256) {
		uint256 time = (expiration - block.timestamp).div(ONE_YEAR_SECONDS);
		int256 underlying = int256(underlyingPrice);
		int256 spot_distance = (int256(strikePrice) - int256(underlying)).div(underlying);
		int256[2] memory points = [spot_distance, int256(time)];
		int256[7] memory coef = isPut ? putsVolatilitySkew : callsVolatilitySkew;
		return uint256(computeIVFromSkew(coef, points));
	}

	/**
	 * @notice get the volatility skew of the pool
	 * @param isPut the option type, put or call?
	 * @return the skew parameters
	 */
	function getVolatilitySkew(bool isPut) external view returns (int256[7] memory) {
		if (!isPut) {
			return callsVolatilitySkew;
		} else {
			return putsVolatilitySkew;
		}
	}

	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	// @param points[0] spot distance
	// @param points[1] expiration time
	// @param coef degree-2 polynomial features are [intercept, 1, a, b, a^2, ab, b^2]
	// a == spot_distance, b == expiration time
	// spot_distance: (strike - spot_price) / spot_price
	// expiration: years to expiration
	function computeIVFromSkew(int256[7] memory coef, int256[2] memory points)
		internal
		pure
		returns (int256)
	{
		int256 iPlusC1 = coef[0] + coef[1];
		int256 c2PlusC3 = coef[2].mul(points[0]) + (coef[3].mul(points[1]));
		int256 c4PlusC5 = coef[4].mul(points[0].mul(points[0])) + (coef[5].mul(points[0]).mul(points[1]));
		return iPlusC1 + c2PlusC3 + c4PlusC5 + (coef[6].mul(points[1].mul(points[1])));
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] && msg.sender != authority.governor() && msg.sender != authority.manager()
		) {
			revert CustomErrors.NotKeeper();
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

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
contract ReentrancyGuard {
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

	constructor() {
		_status = _NOT_ENTERED;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Types.sol";

interface IPortfolioValuesFeed {
	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice Creates a Chainlink request to update portfolio values
	 * data, then multiply by 1000000000000000000 (to remove decimal places from data).
	 *
	 * @return requestId - id of the request
	 */
	function requestPortfolioData(address _underlying, address _strike)
		external
		returns (bytes32 requestId);

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getPortfolioValues(address underlying, address strike)
		external
		view
		returns (Types.PortfolioValues memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAuthority {
	/* ========== EVENTS ========== */

	event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
	event GuardianPushed(address indexed to, bool _effectiveImmediately);
	event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

	event GovernorPulled(address indexed from, address indexed to);
	event GuardianPulled(address indexed to);
	event ManagerPulled(address indexed from, address indexed to);

	/* ========== VIEW ========== */

	function governor() external view returns (address);

	function guardian(address _target) external view returns (bool);

	function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	function decimals() external view returns (uint8);

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

        // Set the initial guess to the closest power of two that is higher than x.
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