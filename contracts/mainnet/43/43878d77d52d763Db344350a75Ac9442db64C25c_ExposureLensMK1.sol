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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceFeed.sol";
import "./Protocol.sol";
import "./OptionExchange.sol";
import "./VolatilityFeed.sol";

import "./libraries/Types.sol";
import "./libraries/BlackScholes.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/OptionsCompute.sol";

import "./interfaces/GammaInterface.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IOptionRegistry.sol";
import "./interfaces/IPortfolioValuesFeed.sol";
import "./interfaces/AddressBookInterface.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title AlphaPortfolioValuesFeed contract
 * @notice Options portfolio storage and calculations
 */
contract AlphaPortfolioValuesFeed is AccessControl, IPortfolioValuesFeed {
	using EnumerableSet for EnumerableSet.AddressSet;
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	struct OptionStores {
		Types.OptionSeries optionSeries;
		int256 shortExposure;
		int256 longExposure;
	}

	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	uint256 constant oTokenDecimals = 8;
	int256 private constant SCALE = 1e18;
	Protocol public immutable protocol;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	mapping(address => OptionStores) public storesForAddress;
	// series to loop over stored as issuance hashes
	EnumerableSet.AddressSet internal addressSet;
	// portfolio values
	mapping(address => mapping(address => Types.PortfolioValues)) private portfolioValues;
	// net dhv exposure of the option
	mapping(bytes32 => int256) public netDhvExposure;

	/////////////////////////////////
	/// govern settable variables ///
	/////////////////////////////////

	ILiquidityPool public liquidityPool;
	// handlers that can push to this contract
	mapping(address => bool) public handler;
	// keeper mapping
	mapping(address => bool) public keeper;
	// risk free rate
	uint256 public rfr = 0;
	// maximum absolute netDhvExposure
	uint256 public maxNetDhvExposure;

	//////////////
	/// events ///
	//////////////

	event DataFullfilled(
		address indexed underlying,
		address indexed strike,
		int256 delta,
		int256 gamma,
		int256 vega,
		int256 theta,
		int256 callPutsValue
	);
	event RequestedUpdate(address _underlying, address _strike);
	event StoresUpdated(
		address seriesAddress,
		int256 shortExposure,
		int256 longExposure,
		Types.OptionSeries optionSeries
	);
	event MaxNetDhvExposureUpdated(uint256 maxNetDhvExposure);
	event NetDhvExposureChanged(
		bytes32 indexed optionHash,
		int256 oldNetDhvExposure,
		int256 newNetDhvExposure
	);

	error OptionHasExpiredInStores(uint256 index, address seriesAddress);
	error MaxNetDhvExposureExceeded();
	error NoVaultForShortPositions();
	error IncorrectSeriesToRemove();
	error SeriesNotExpired();
	error NoShortPositions();

	/**
	 * @notice Executes once when a contract is created to initialize state variables
	 *		   Make sure the protocol is configured after deployment
	 */
	constructor(
		address _authority,
		uint256 _maxNetDhvExposure,
		address _protocol
	) AccessControl(IAuthority(_authority)) {
		maxNetDhvExposure = _maxNetDhvExposure;
		protocol = Protocol(_protocol);
	}

	///////////////
	/// setters ///
	///////////////

	function setLiquidityPool(address _liquidityPool) external {
		_onlyGovernor();
		liquidityPool = ILiquidityPool(_liquidityPool);
	}

	function setRFR(uint256 _rfr) external {
		_onlyGovernor();
		rfr = _rfr;
	}

	/**
	 * @notice change the status of a keeper
	 */
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
	}

	/**
	 * @notice change the status of a handler
	 */
	function setHandler(address _handler, bool _auth) external {
		_onlyGovernor();
		handler[_handler] = _auth;
	}

	/**
	 * @notice change the max net dhv exposure
	 */
	function setMaxNetDhvExposure(uint256 _maxNetDhvExposure) external {
		_onlyGovernor();
		maxNetDhvExposure = _maxNetDhvExposure;
		emit MaxNetDhvExposureUpdated(_maxNetDhvExposure);
	}

	/**
	 * @notice change the net dhv exposures for a specific option hash arrays, this is to manage risk in case of
	 *         mispricing scenarios
	 * @param  _optionHashes - list of optionhashes in bytes32 that defines the index of the net dhv exposure to be changed
	 * @param  _netDhvExposures - list of net dhv exposures that correspond to the option hashes above
	 */
	function setNetDhvExposures(
		bytes32[] memory _optionHashes,
		int256[] memory _netDhvExposures
	) external {
		_onlyGovernor();
		_isExchangePaused();
		uint256 arrayLength = _optionHashes.length;
		require(arrayLength == _netDhvExposures.length);
		for (uint i; i < arrayLength; i++) {
			if (uint256(_netDhvExposures[i].abs()) > maxNetDhvExposure) revert MaxNetDhvExposureExceeded();
			emit NetDhvExposureChanged(
				_optionHashes[i],
				netDhvExposure[_optionHashes[i]],
				_netDhvExposures[i]
			);
			netDhvExposure[_optionHashes[i]] = _netDhvExposures[i];
		}
	}

	/**
	 * @notice Fulfills the portfolio delta and portfolio value by doing a for loop over the stores.  This is then used to
	 *         update the portfolio values for external contracts to know what the liquidity pool's value is
	 *		   1/ Make sure any expired options are settled, otherwise this fulfillment will fail
	 *		   2/ Once the addressSet is cleared of any
	 * @param _underlying - response; underlying address
	 * @param _strikeAsset - response; strike address
	 */
	function fulfill(address _underlying, address _strikeAsset) external {
		int256 delta;
		int256 callPutsValue;
		// get the length of the address set here to save gas on the for loop
		uint256 lengthAddy = addressSet.length();
		// get the spot price
		uint256 spotPrice = _getUnderlyingPrice(_underlying, _strikeAsset);
		VolatilityFeed volFeed = _getVolatilityFeed();
		uint256 _rfr = rfr;
		for (uint256 i = 0; i < lengthAddy; i++) {
			// get series
			OptionStores memory _optionStores = storesForAddress[addressSet.at(i)];
			// check if the series has expired, if it has then flag this,
			// before retrying, settle all expired options and then clean the looper
			if (_optionStores.optionSeries.expiration < block.timestamp) {
				revert OptionHasExpiredInStores(i, addressSet.at(i));
			}
			// get the vol
			(uint256 vol, uint256 forward) = volFeed.getImpliedVolatilityWithForward(
				_optionStores.optionSeries.isPut,
				spotPrice,
				_optionStores.optionSeries.strike,
				_optionStores.optionSeries.expiration
			);
			// compute the delta and the price
			(uint256 _callPutsValue, int256 _delta) = BlackScholes.blackScholesCalcGreeks(
				forward,
				_optionStores.optionSeries.strike,
				_optionStores.optionSeries.expiration,
				vol,
				_rfr,
				_optionStores.optionSeries.isPut
			);
			_callPutsValue = _callPutsValue.mul(spotPrice).div(forward);
			// calculate the net exposure
			int256 netExposure = _optionStores.shortExposure - _optionStores.longExposure;
			// increment the deltas by adding if the option is long and subtracting if the option is short
			delta -= (_delta * netExposure) / SCALE;
			// increment the values by subtracting if the option is long (as this represents liabilities in the liquidity pool) and adding if the option is short as this value
			// represents liabilities
			callPutsValue += (int256(_callPutsValue) * netExposure) / SCALE;
		}
		// update the portfolio values
		Types.PortfolioValues memory portfolioValue = Types.PortfolioValues({
			delta: delta,
			gamma: 0,
			vega: 0,
			theta: 0,
			callPutsValue: callPutsValue,
			spotPrice: spotPrice,
			timestamp: block.timestamp
		});
		portfolioValues[_underlying][_strikeAsset] = portfolioValue;
		// reset these values as it is a feature necessary for future upgrades
		liquidityPool.resetEphemeralValues();
		emit DataFullfilled(_underlying, _strikeAsset, delta, 0, 0, 0, callPutsValue);
	}

	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice Updates the option series stores to be used for portfolio value calculation
	 * @param _optionSeries the option series that was created, strike in e18
	 * @param shortExposure the amount of short to increment the short exposure by
	 * @param longExposure the amount of long to increment the long exposure by
	 * @param _seriesAddress the address of the series represented by the oToken
	 * @dev   callable by the handler and also during migration
	 */
	function updateStores(
		Types.OptionSeries memory _optionSeries,
		int256 shortExposure,
		int256 longExposure,
		address _seriesAddress
	) external {
		_isHandler();
		if (!addressSet.contains(_seriesAddress)) {
			// maybe store them by expiry instead
			addressSet.add(_seriesAddress);
			storesForAddress[_seriesAddress] = OptionStores(_optionSeries, shortExposure, longExposure);
		} else {
			storesForAddress[_seriesAddress].shortExposure += shortExposure;
			storesForAddress[_seriesAddress].longExposure += longExposure;
		}
		// get the hash of the option (how the option is stored on the books)
		bytes32 oHash = keccak256(
			abi.encodePacked(_optionSeries.expiration, _optionSeries.strike, _optionSeries.isPut)
		);
		netDhvExposure[oHash] -= shortExposure;
		netDhvExposure[oHash] += longExposure;
		if (uint256(netDhvExposure[oHash].abs()) > maxNetDhvExposure) revert MaxNetDhvExposureExceeded();
		emit StoresUpdated(_seriesAddress, shortExposure, longExposure, _optionSeries);
	}

	////////////////////////////////////////////////////////////////////////////////////////////
	/**  LOOP CLEANING - FOR ALPHA
	 *   This is necessary to reduce the size of the foor loop when its not necessary to.
	 *   - Make sure the option has been settled!
	 */
	////////////////////////////////////////////////////////////////////////////////////////////
	address[] private addyList;

	/**
	 * @notice function to clean all expired series from the options storage to remove them from the looped array.
	 * @dev 	FOLLOW THE LOOP CLEANING INSTRUCTIONS ABOVE WHEN CALLING THIS FUNCTION
	 */
	function syncLooper() external {
		_isKeeper();
		uint256 lengthAddy = addressSet.length();
		for (uint256 i; i < lengthAddy; i++) {
			if (storesForAddress[addressSet.at(i)].optionSeries.expiration < block.timestamp) {
				addyList.push(addressSet.at(i));
			}
		}
		lengthAddy = addyList.length;
		for (uint256 j; j < lengthAddy; j++) {
			_cleanLooper(addyList[j]);
		}
		delete addyList;
	}

	/**
	 * @notice function to clean an expired series from the portfolio values feed, this function will make sure the series and index match
	 *			and will also check if the series has expired before any cleaning happens.
	 * @param  _series the series at the index input above
	 * @dev 	FOLLOW THE LOOP CLEANING INSTRUCTIONS ABOVE WHEN CALLING THIS FUNCTION
	 */
	function cleanLooperManually(address _series) external {
		_isKeeper();
		if (!addressSet.contains(_series)) {
			revert IncorrectSeriesToRemove();
		}
		if (storesForAddress[_series].optionSeries.expiration > block.timestamp) {
			revert SeriesNotExpired();
		}
		_cleanLooper(_series);
	}

	/**
	 * @notice internal function for removing an address from the address set and clearing all option stores for that series
	 * @param  _series the option series address to be cleared
	 */
	function _cleanLooper(address _series) internal {
		// clean out the address
		addressSet.remove(_series);
		// delete the stores
		delete storesForAddress[_series];
	}

	/**
	 * @notice if a vault has been liquidated we need to account for it, so adjust our short positions to reality
	 * @param  _series the option series address to be cleared
	 */
	function accountLiquidatedSeries(address _series) external {
		_isKeeper();
		if (!addressSet.contains(_series)) {
			revert IncorrectSeriesToRemove();
		}
		// get the series
		OptionStores memory _optionStores = storesForAddress[_series];
		// check if there are any short positions for this asset
		if (_optionStores.shortExposure == 0) {
			revert NoShortPositions();
		}
		// get the vault for this option series from the option registry
		IOptionRegistry optionRegistry = _getOptionRegistry();
		uint256 vaultId = optionRegistry.vaultIds(_series);
		// check if a vault id exists for that series
		if (vaultId == 0) {
			revert NoVaultForShortPositions();
		}
		// get the vault details and reset the short exposure to whatever it is
		uint256 shortAmounts = OptionsCompute.convertFromDecimals(
			IController(AddressBookInterface(optionRegistry.addressBook()).getController())
				.getVault(address(optionRegistry), vaultId)
				.shortAmounts[0],
			oTokenDecimals
		);
		storesForAddress[_series].shortExposure = int256(shortAmounts);
	}

	////////////////////////////////////////////////////////////////////////////////////////////
	/**  MIGRATION PROCESS - FOR ALPHA
	 *	  1/ On the migrate contract set this contract as a handler via Governance
	 *   2/ Make sure the storage of options in this contract is up to date and clean/synced
	 *   3/ Call migrate here via Governance
	 *   3i/ If the migration gas gets too big then
	 *   4/ Make sure the storage was correctly transferred to the new contract
	 *   5/ Properly configure the handlers on the new contract via Governance
	 *   6/ Properly configure the keepers on the new contract via Governance
	 *   7/ Set the liquidity pool on the new contract via Governance
	 *   8/ Change the PortfolioValuesFeed in the Protocol contract via Governance
	 */
	////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice migrate all stored options data to a new contract that has the IPortfolioValuesFeed interface
	 * @param  _migrateContract the new portfolio values feed contract to migrate option values too
	 * @dev 	FOLLOW THE MIGRATION PROCESS INSTRUCTIONS WHEN CALLING THIS FUNCTION
	 */
	function migrate(IPortfolioValuesFeed _migrateContract) external {
		_onlyGovernor();
		uint256 lengthAddy = addressSet.length();
		for (uint256 i = 0; i < lengthAddy; i++) {
			address oTokenAddy = addressSet.at(i);
			OptionStores memory _optionStores = storesForAddress[oTokenAddy];
			_migrateContract.updateStores(
				_optionStores.optionSeries,
				_optionStores.shortExposure,
				_optionStores.longExposure,
				oTokenAddy
			);
		}
	}

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice requests a portfolio data update
	 *
	 */
	function requestPortfolioData(address _underlying, address _strike) external returns (bytes32 id) {
		emit RequestedUpdate(_underlying, _strike);
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getPortfolioValues(
		address underlying,
		address strike
	) external view returns (Types.PortfolioValues memory) {
		return portfolioValues[underlying][strike];
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] && msg.sender != authority.governor() && msg.sender != authority.manager()
		) {
			revert CustomErrors.NotKeeper();
		}
	}

	/// @dev handlers can access
	function _isHandler() internal view {
		if (!handler[msg.sender]) {
			revert();
		}
	}

	/// get the address set details
	function isAddressInSet(address _a) external view returns (bool) {
		return addressSet.contains(_a);
	}

	function addressAtIndexInSet(uint256 _i) external view returns (address) {
		return addressSet.at(_i);
	}

	function addressSetLength() external view returns (uint256) {
		return addressSet.length();
	}

	function getAddressSet() external view returns (address[] memory) {
		return addressSet.values();
	}

	/**
	 * @notice get the volatility feed used by the liquidity pool
	 * @return the volatility feed contract interface
	 */
	function _getVolatilityFeed() internal view returns (VolatilityFeed) {
		return VolatilityFeed(protocol.volatilityFeed());
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
	function _getUnderlyingPrice(
		address underlying,
		address _strikeAsset
	) internal view returns (uint256) {
		return PriceFeed(protocol.priceFeed()).getNormalizedRate(underlying, _strikeAsset);
	}

	function _isExchangePaused() internal view {
		if (!OptionExchange(protocol.optionExchange()).paused()) {
			revert CustomErrors.ExchangeNotPaused();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Protocol.sol";
import "./PriceFeed.sol";
import "./OptionExchange.sol";
import "./VolatilityFeed.sol";
import "./tokens/ERC20.sol";
import "./libraries/Types.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";
import "./libraries/OptionsCompute.sol";
import "./libraries/SafeTransferLib.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/IMarginCalculator.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IPortfolioValuesFeed.sol";
import "./interfaces/AddressBookInterface.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 *  @title Contract used for all user facing options interactions
 *  @dev Interacts with liquidityPool to write options and quote their prices.
 */
contract BeyondPricer is AccessControl, ReentrancyGuard {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	struct DeltaBorrowRates {
		int sellLong; // when someone sells puts to DHV (we need to long to hedge)
		int sellShort; // when someone sells calls to DHV (we need to short to hedge)
		int buyLong; // when someone buys calls from DHV (we need to long to hedge)
		int buyShort; // when someone buys puts from DHV (we need to short to hedge)
	}

	struct DeltaBandMultipliers {
		// array of slippage multipliers for each delta band. e18
		int80[] callSlippageGradientMultipliers;
		int80[] putSlippageGradientMultipliers;
		// array of collateral lending spread multipliers for each delta band. e18
		int80[] callSpreadCollateralMultipliers;
		int80[] putSpreadCollateralMultipliers;
		// array of delta borrow spread multipliers for each delta band. e18
		int80[] callSpreadDeltaMultipliers;
		int80[] putSpreadDeltaMultipliers;
	}

	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	// Protocol management contracts
	ILiquidityPool public immutable liquidityPool;
	Protocol public immutable protocol;
	AddressBookInterface public immutable addressBook;
	// asset that denominates the strike price
	address public immutable strikeAsset;
	// asset that is used as the reference asset
	address public immutable underlyingAsset;
	// asset that is used for collateral asset
	address public immutable collateralAsset;

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	uint256 public bidAskIVSpread;
	uint256 public riskFreeRate;
	uint256 public feePerContract = 5e5;

	uint256 public slippageGradient;

	// represents the width of delta bands to apply slippage multipliers to. e18
	uint256 public deltaBandWidth;
	// represents the number of tenors for which we want to apply separate slippage and spread parameters to
	uint16 public numberOfTenors;
	// multiplier values for spread and slippage delta bands
	DeltaBandMultipliers[] internal tenorPricingParams;
	// maximum tenor value. Units are in sqrt(seconds)
	uint16 public maxTenorValue;

	// represents the lending rate of collateral used to collateralise short options by the DHV. denominated in 6 dps
	uint256 public collateralLendingRate;
	//  delta borrow rates for spread func. All denominated in 6 dps
	DeltaBorrowRates public deltaBorrowRates;
	// flat IV value which will override our pricing formula for bids on options below a low delta threshold
	uint256 public lowDeltaSellOptionFlatIV = 35e16;
	// threshold for delta of options below which lowDeltaSellOptionFlatIV kicks in
	uint256 public lowDeltaThreshold = 5e16; //0.05 delta options

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// BIPS
	uint256 private constant SIX_DPS = 1_000_000;
	uint256 private constant ONE_YEAR_SECONDS = 31557600;
	// used to convert e18 to e8
	uint256 private constant SCALE_FROM = 10 ** 10;
	uint256 private constant ONE_DELTA = 100e18;
	uint256 private constant ONE_SCALE = 1e18;
	int256 private constant ONE_SCALE_INT = 1e18;
	int256 private constant SIX_DPS_INT = 1_000_000;

	/////////////////////////
	/// structs && events ///
	/////////////////////////

	event TenorParamsSet();
	event SlippageGradientMultipliersChanged();
	event SpreadCollateralMultipliersChanged();
	event SpreadDeltaMultipliersChanged();
	event DeltaBandWidthChanged(uint256 newDeltaBandWidth, uint256 oldDeltaBandWidth);
	event CollateralLendingRateChanged(
		uint256 newCollateralLendingRate,
		uint256 oldCollateralLendingRate
	);
	event DeltaBorrowRatesChanged(
		DeltaBorrowRates newDeltaBorrowRates,
		DeltaBorrowRates oldDeltaBorrowRates
	);
	event SlippageGradientChanged(uint256 newSlippageGradient, uint256 oldSlippageGradient);
	event FeePerContractChanged(uint256 newFeePerContract, uint256 oldFeePerContract);
	event RiskFreeRateChanged(uint256 newRiskFreeRate, uint256 oldRiskFreeRate);
	event BidAskIVSpreadChanged(uint256 newBidAskIVSpread, uint256 oldBidAskIVSpread);
	event LowDeltaSellOptionFlatIVChanged(
		uint256 newLowDeltaSellOptionFlatIV,
		uint256 oldLowDeltaSellOptionFlatIV
	);
	event LowDeltaThresholdChanged(uint256 newLowDeltaThreshold, uint256 oldLowDeltaThreshold);
	error InvalidMultipliersArrayLength();
	error InvalidMultiplierValue();
	error InvalidTenorArrayLength();

	constructor(
		address _authority,
		address _protocol,
		address _liquidityPool,
		address _addressBook,
		uint256 _slippageGradient,
		uint256 _collateralLendingRate,
		DeltaBorrowRates memory _deltaBorrowRates
	) AccessControl(IAuthority(_authority)) {
		protocol = Protocol(_protocol);
		liquidityPool = ILiquidityPool(_liquidityPool);
		addressBook = AddressBookInterface(_addressBook);
		collateralAsset = liquidityPool.collateralAsset();
		underlyingAsset = liquidityPool.underlyingAsset();
		strikeAsset = liquidityPool.strikeAsset();
		slippageGradient = _slippageGradient;
		collateralLendingRate = _collateralLendingRate;
		deltaBorrowRates = _deltaBorrowRates;
	}

	///////////////
	/// setters ///
	///////////////

	function setLowDeltaSellOptionFlatIV(uint256 _lowDeltaSellOptionFlatIV) external {
		_onlyManager();
		_isExchangePaused();
		emit LowDeltaSellOptionFlatIVChanged(_lowDeltaSellOptionFlatIV, lowDeltaSellOptionFlatIV);
		lowDeltaSellOptionFlatIV = _lowDeltaSellOptionFlatIV;
	}

	function setLowDeltaThreshold(uint256 _lowDeltaThreshold) external {
		_onlyManager();
		_isExchangePaused();
		emit LowDeltaThresholdChanged(_lowDeltaThreshold, lowDeltaThreshold);
		lowDeltaThreshold = _lowDeltaThreshold;
	}

	function setRiskFreeRate(uint256 _riskFreeRate) external {
		_onlyManager();
		_isExchangePaused();
		emit RiskFreeRateChanged(_riskFreeRate, riskFreeRate);
		riskFreeRate = _riskFreeRate;
	}

	function setBidAskIVSpread(uint256 _bidAskIVSpread) external {
		_onlyManager();
		_isExchangePaused();
		emit BidAskIVSpreadChanged(_bidAskIVSpread, bidAskIVSpread);
		bidAskIVSpread = _bidAskIVSpread;
	}

	function setFeePerContract(uint256 _feePerContract) external {
		_onlyGovernor();
		_isExchangePaused();
		emit FeePerContractChanged(_feePerContract, feePerContract);
		feePerContract = _feePerContract;
	}

	function setSlippageGradient(uint256 _slippageGradient) external {
		_onlyManager();
		_isExchangePaused();
		emit SlippageGradientChanged(_slippageGradient, slippageGradient);
		slippageGradient = _slippageGradient;
	}

	function setCollateralLendingRate(uint256 _collateralLendingRate) external {
		_onlyManager();
		_isExchangePaused();
		emit CollateralLendingRateChanged(_collateralLendingRate, collateralLendingRate);
		collateralLendingRate = _collateralLendingRate;
	}

	function setDeltaBorrowRates(DeltaBorrowRates calldata _deltaBorrowRates) external {
		_onlyManager();
		_isExchangePaused();
		emit DeltaBorrowRatesChanged(_deltaBorrowRates, deltaBorrowRates);
		deltaBorrowRates = _deltaBorrowRates;
	}

	/** @notice function used to set the slippage and spread delta band multipliers initially, and
	 *  also if the number of tenors or the delta band width is changed, since this would require
	 *  all existing tenors to be adjusted.
	 */

	function initializeTenorParams(
		uint256 _deltaBandWidth,
		uint16 _numberOfTenors,
		uint16 _maxTenorValue,
		DeltaBandMultipliers[] memory _tenorPricingParams
	) external {
		_onlyManager();
		_isExchangePaused();
		if (_tenorPricingParams.length != _numberOfTenors) {
			revert InvalidTenorArrayLength();
		}
		for (uint16 i = 0; i < _numberOfTenors; i++) {
			if (
				_tenorPricingParams[i].callSlippageGradientMultipliers.length != ONE_DELTA / _deltaBandWidth ||
				_tenorPricingParams[i].putSlippageGradientMultipliers.length != ONE_DELTA / _deltaBandWidth ||
				_tenorPricingParams[i].callSpreadCollateralMultipliers.length != ONE_DELTA / _deltaBandWidth ||
				_tenorPricingParams[i].putSpreadCollateralMultipliers.length != ONE_DELTA / _deltaBandWidth ||
				_tenorPricingParams[i].callSpreadDeltaMultipliers.length != ONE_DELTA / _deltaBandWidth ||
				_tenorPricingParams[i].putSpreadDeltaMultipliers.length != ONE_DELTA / _deltaBandWidth
			) {
				revert InvalidMultipliersArrayLength();
			}
			uint256 len = _tenorPricingParams[i].callSlippageGradientMultipliers.length;
			for (uint256 j = 0; j < len; j++) {
				// arrays must be same length so can check all in same loop
				// ensure no multiplier is less than 1 due to human error.
				if (
					_tenorPricingParams[i].callSlippageGradientMultipliers[j] < ONE_SCALE_INT ||
					_tenorPricingParams[i].putSlippageGradientMultipliers[j] < ONE_SCALE_INT ||
					_tenorPricingParams[i].callSpreadCollateralMultipliers[j] < ONE_SCALE_INT ||
					_tenorPricingParams[i].putSpreadCollateralMultipliers[j] < ONE_SCALE_INT ||
					_tenorPricingParams[i].callSpreadDeltaMultipliers[j] < ONE_SCALE_INT ||
					_tenorPricingParams[i].putSpreadDeltaMultipliers[j] < ONE_SCALE_INT
				) {
					revert InvalidMultiplierValue();
				}
			}
		}
		numberOfTenors = _numberOfTenors;
		maxTenorValue = _maxTenorValue;
		deltaBandWidth = _deltaBandWidth;
		delete tenorPricingParams;
		for (uint i = 0; i < _numberOfTenors; i++) {
			tenorPricingParams.push(_tenorPricingParams[i]);
		}
		emit TenorParamsSet();
	}

	function setSlippageGradientMultipliers(
		uint16 _tenorIndex,
		int80[] memory _callSlippageGradientMultipliers,
		int80[] memory _putSlippageGradientMultipliers
	) public {
		_onlyManager();
		_isExchangePaused();
		if (
			_callSlippageGradientMultipliers.length != ONE_DELTA / deltaBandWidth ||
			_putSlippageGradientMultipliers.length != ONE_DELTA / deltaBandWidth
		) {
			revert InvalidMultipliersArrayLength();
		}
		uint256 len = _callSlippageGradientMultipliers.length;
		for (uint256 i = 0; i < len; i++) {
			// arrays must be same length so can check both in same loop
			// ensure no multiplier is less than 1 due to human error.
			if (
				_callSlippageGradientMultipliers[i] < ONE_SCALE_INT ||
				_putSlippageGradientMultipliers[i] < ONE_SCALE_INT
			) {
				revert InvalidMultiplierValue();
			}
		}
		tenorPricingParams[_tenorIndex]
			.callSlippageGradientMultipliers = _callSlippageGradientMultipliers;
		tenorPricingParams[_tenorIndex].putSlippageGradientMultipliers = _putSlippageGradientMultipliers;
		emit SlippageGradientMultipliersChanged();
	}

	function setSpreadCollateralMultipliers(
		uint16 _tenorIndex,
		int80[] memory _callSpreadCollateralMultipliers,
		int80[] memory _putSpreadCollateralMultipliers
	) public {
		_onlyManager();
		_isExchangePaused();
		if (
			_callSpreadCollateralMultipliers.length != ONE_DELTA / deltaBandWidth ||
			_putSpreadCollateralMultipliers.length != ONE_DELTA / deltaBandWidth
		) {
			revert InvalidMultipliersArrayLength();
		}
		uint256 len = _callSpreadCollateralMultipliers.length;
		for (uint256 i = 0; i < len; i++) {
			// arrays must be same length so can check both in same loop
			// ensure no multiplier is less than 1 due to human error.
			if (
				_callSpreadCollateralMultipliers[i] < ONE_SCALE_INT ||
				_putSpreadCollateralMultipliers[i] < ONE_SCALE_INT
			) {
				revert InvalidMultiplierValue();
			}
		}
		tenorPricingParams[_tenorIndex]
			.callSpreadCollateralMultipliers = _callSpreadCollateralMultipliers;
		tenorPricingParams[_tenorIndex].putSpreadCollateralMultipliers = _putSpreadCollateralMultipliers;
		emit SpreadCollateralMultipliersChanged();
	}

	function setSpreadDeltaMultipliers(
		uint16 _tenorIndex,
		int80[] memory _callSpreadDeltaMultipliers,
		int80[] memory _putSpreadDeltaMultipliers
	) public {
		_onlyManager();
		_isExchangePaused();
		if (
			_callSpreadDeltaMultipliers.length != ONE_DELTA / deltaBandWidth ||
			_putSpreadDeltaMultipliers.length != ONE_DELTA / deltaBandWidth
		) {
			revert InvalidMultipliersArrayLength();
		}
		uint256 len = _callSpreadDeltaMultipliers.length;
		for (uint256 i = 0; i < len; i++) {
			// arrays must be same length so can check both in same loop
			// ensure no multiplier is less than 1 due to human error.
			if (
				_callSpreadDeltaMultipliers[i] < ONE_SCALE_INT || _putSpreadDeltaMultipliers[i] < ONE_SCALE_INT
			) {
				revert InvalidMultiplierValue();
			}
		}
		tenorPricingParams[_tenorIndex].callSpreadDeltaMultipliers = _callSpreadDeltaMultipliers;
		tenorPricingParams[_tenorIndex].putSpreadDeltaMultipliers = _putSpreadDeltaMultipliers;
		emit SpreadDeltaMultipliersChanged();
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	function quoteOptionPrice(
		Types.OptionSeries memory _optionSeries,
		uint256 _amount,
		bool isSell,
		int256 netDhvExposure
	) external view returns (uint256 totalPremium, int256 totalDelta, uint256 totalFees) {
		uint256 underlyingPrice = _getUnderlyingPrice(underlyingAsset, strikeAsset);
		(uint256 iv, uint256 forward) = _getVolatilityFeed().getImpliedVolatilityWithForward(
			_optionSeries.isPut,
			underlyingPrice,
			_optionSeries.strike,
			_optionSeries.expiration
		);
		(uint256 vanillaPremium, int256 delta) = OptionsCompute.quotePriceGreeks(
			_optionSeries,
			isSell,
			bidAskIVSpread,
			riskFreeRate,
			iv,
			forward,
			false
		);
		vanillaPremium = vanillaPremium.mul(underlyingPrice).div(forward);
		uint256 premium = vanillaPremium.mul(
			_getSlippageMultiplier(_optionSeries, _amount, delta, isSell, netDhvExposure)
		);

		int spread = _getSpreadValue(
			isSell,
			_optionSeries,
			_amount,
			delta,
			netDhvExposure,
			underlyingPrice
		);
		if (spread < 0) {
			spread = 0;
		}
		totalPremium = isSell
			? uint(OptionsCompute.max(int(premium.mul(_amount)) - spread, 0))
			: premium.mul(_amount) + uint(spread);

		totalPremium = OptionsCompute.convertToDecimals(totalPremium, ERC20(collateralAsset).decimals());
		totalDelta = delta.mul(int256(_amount));
		totalFees = feePerContract.mul(_amount);

		if (isSell && uint256(delta.abs()) < lowDeltaThreshold) {
			(uint overridePremium, ) = OptionsCompute.quotePriceGreeks(
				_optionSeries,
				isSell,
				bidAskIVSpread,
				riskFreeRate,
				lowDeltaSellOptionFlatIV,
				forward,
				true // override IV
			);
			// discount by forward rate
			overridePremium = overridePremium.mul(underlyingPrice).div(forward);
			overridePremium = OptionsCompute.convertToDecimals(
				overridePremium.mul(_amount),
				ERC20(collateralAsset).decimals()
			);
			totalPremium = OptionsCompute.min(totalPremium, overridePremium);
		}
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getCallSlippageGradientMultipliers(
		uint16 _tenorIndex
	) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].callSlippageGradientMultipliers;
	}

	function getPutSlippageGradientMultipliers(
		uint16 _tenorIndex
	) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].putSlippageGradientMultipliers;
	}

	function getCallSpreadCollateralMultipliers(
		uint16 _tenorIndex
	) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].callSpreadCollateralMultipliers;
	}

	function getPutSpreadCollateralMultipliers(
		uint16 _tenorIndex
	) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].putSpreadCollateralMultipliers;
	}

	function getCallSpreadDeltaMultipliers(uint16 _tenorIndex) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].callSpreadDeltaMultipliers;
	}

	function getPutSpreadDeltaMultipliers(uint16 _tenorIndex) external view returns (int80[] memory) {
		return tenorPricingParams[_tenorIndex].putSpreadDeltaMultipliers;
	}

	/**
	 * @notice get the underlying price with just the underlying asset and strike asset
	 * @param underlying   the asset that is used as the reference asset
	 * @param _strikeAsset the asset that the underlying value is denominated in
	 * @return the underlying price
	 */
	function _getUnderlyingPrice(
		address underlying,
		address _strikeAsset
	) internal view returns (uint256) {
		return PriceFeed(protocol.priceFeed()).getNormalizedRate(underlying, _strikeAsset);
	}

	/**
	 * @notice get the volatility feed used by the liquidity pool
	 * @return the volatility feed contract interface
	 */
	function _getVolatilityFeed() internal view returns (VolatilityFeed) {
		return VolatilityFeed(protocol.volatilityFeed());
	}

	//////////////////////////
	/// internal functions ///
	//////////////////////////

	/**
	 * @notice function to add slippage to orders to prevent over-exposure to a single option type
	 * @param _amount amount of options contracts being traded. e18
	 * @param _optionDelta the delta exposure of the option
	 * @param _netDhvExposure how many contracts of this series the DHV is already exposed to. e18. negative if net short.
	 * @param _isSell true if someone is selling option to DHV. False if they're buying from DHV
	 */
	function _getSlippageMultiplier(
		Types.OptionSeries memory _optionSeries,
		uint256 _amount,
		int256 _optionDelta,
		bool _isSell,
		int256 _netDhvExposure
	) internal view returns (uint256 slippageMultiplier) {
		if (slippageGradient == 0) {
			slippageMultiplier = ONE_SCALE;
			return slippageMultiplier;
		}
		// slippage will be exponential with the exponent being the DHV's net exposure
		int256 newExposureExponent = _isSell
			? _netDhvExposure + int256(_amount)
			: _netDhvExposure - int256(_amount);
		int256 oldExposureExponent = _netDhvExposure;
		uint256 modifiedSlippageGradient;
		// not using math library here, want to reduce to a non e18 integer
		// integer division rounds down to nearest integer
		uint256 deltaBandIndex = (uint256(_optionDelta.abs()) * 100) / deltaBandWidth;
		(uint16 tenorIndex, int256 remainder) = _getTenorIndex(_optionSeries.expiration);
		if (_optionDelta < 0) {
			modifiedSlippageGradient = slippageGradient.mul(
				_interpolateSlippageGradient(tenorIndex, remainder, true, deltaBandIndex)
			);
		} else {
			modifiedSlippageGradient = slippageGradient.mul(
				_interpolateSlippageGradient(tenorIndex, remainder, false, deltaBandIndex)
			);
		}
		// integrate the exponential function to get the slippage multiplier as this represents the average exposure
		// if it is a sell then we need to do lower bound is old exposure exponent, upper bound is new exposure exponent
		// if it is a buy then we need to do lower bound is new exposure exponent, upper bound is old exposure exponent
		int256 slippageFactor = int256(ONE_SCALE + modifiedSlippageGradient);
		if (_isSell) {
			slippageMultiplier = uint256(
				(slippageFactor.pow(-oldExposureExponent) - slippageFactor.pow(-newExposureExponent)).div(
					slippageFactor.ln()
				)
			).div(_amount);
		} else {
			slippageMultiplier = uint256(
				(slippageFactor.pow(-newExposureExponent) - slippageFactor.pow(-oldExposureExponent)).div(
					slippageFactor.ln()
				)
			).div(_amount);
		}
	}

	/**
	 * @notice function to apply an additive spread premium to the order. Is applied to whole _amount and not per contract.
	 * @param _optionSeries the series detail of the option - strike decimals in e18
	 * @param _amount number of contracts being traded. e18
	 * @param _optionDelta the delta exposure of the option. e18
	 * @param _netDhvExposure how many contracts of this series the DHV is already exposed to. e18. negative if net short.
	 * @param _underlyingPrice the price of the underlying asset. e18
	 */
	function _getSpreadValue(
		bool _isSell,
		Types.OptionSeries memory _optionSeries,
		uint256 _amount,
		int256 _optionDelta,
		int256 _netDhvExposure,
		uint256 _underlyingPrice
	) internal view returns (int256 spreadPremium) {
		// get duration of option in years
		uint256 time = (_optionSeries.expiration - block.timestamp).div(ONE_YEAR_SECONDS);
		uint256 deltaBandIndex = (uint256(_optionDelta.abs()) * 100) / deltaBandWidth;
		(uint16 tenorIndex, int256 remainder) = _getTenorIndex(_optionSeries.expiration);

		if (!_isSell) {
			spreadPremium += int(
				_getCollateralLendingPremium(
					_optionSeries,
					_amount,
					_optionDelta,
					_netDhvExposure,
					time,
					deltaBandIndex,
					tenorIndex,
					remainder
				)
			);
		}

		spreadPremium += _getDeltaBorrowPremium(
			_isSell,
			_amount,
			_optionDelta,
			time,
			deltaBandIndex,
			_underlyingPrice,
			tenorIndex,
			remainder
		);
	}

	function _getCollateralLendingPremium(
		Types.OptionSeries memory _optionSeries,
		uint _amount,
		int256 _optionDelta,
		int256 _netDhvExposure,
		uint256 _time,
		uint256 _deltaBandIndex,
		uint16 _tenorIndex,
		int256 _remainder
	) internal view returns (uint256 collateralLendingPremium) {
		uint256 netShortContracts;
		if (_netDhvExposure <= 0) {
			// dhv is already short so apply collateral lending spread to all traded contracts
			netShortContracts = _amount;
		} else {
			// dhv is long so only apply spread to those contracts which make it net short.
			netShortContracts = int256(_amount) - _netDhvExposure < 0
				? 0
				: _amount - uint256(_netDhvExposure);
		}
		if (_optionSeries.collateral == collateralAsset) {
			// find collateral requirements for net short options
			uint256 collateralToLend = _getCollateralRequirements(_optionSeries, netShortContracts);
			// calculate the collateral cost portion of the spread
			collateralLendingPremium =
				((ONE_SCALE + (collateralLendingRate * ONE_SCALE) / SIX_DPS).pow(_time)).mul(collateralToLend) -
				collateralToLend;
			if (_optionDelta < 0) {
				collateralLendingPremium = collateralLendingPremium.mul(
					_interpolateSpreadCollateral(_tenorIndex, _remainder, true, _deltaBandIndex)
				);
			} else {
				collateralLendingPremium = collateralLendingPremium.mul(
					_interpolateSpreadCollateral(_tenorIndex, _remainder, false, _deltaBandIndex)
				);
			}
		}
	}

	function _getDeltaBorrowPremium(
		bool _isSell,
		uint _amount,
		int256 _optionDelta,
		uint256 _time,
		uint256 _deltaBandIndex,
		uint256 _underlyingPrice,
		uint16 _tenorIndex,
		int256 _remainder
	) internal view returns (int256 deltaBorrowPremium) {
		// calculate delta borrow premium on both buy and sells
		// dollarDelta is just a magnitude value, sign doesnt matter
		int256 dollarDelta = int256(uint256(_optionDelta.abs()).mul(_amount).mul(_underlyingPrice));
		if (_optionDelta < 0) {
			// option is negative delta, resulting in long delta exposure for DHV. needs hedging with a short pos
			deltaBorrowPremium =
				dollarDelta.mul(
					(ONE_SCALE_INT +
						((_isSell ? deltaBorrowRates.sellLong : deltaBorrowRates.buyShort) * ONE_SCALE_INT) /
						SIX_DPS_INT).pow(int(_time))
				) -
				dollarDelta;

			deltaBorrowPremium = deltaBorrowPremium.mul(
				_interpolateSpreadDelta(_tenorIndex, _remainder, true, _deltaBandIndex)
			);
		} else {
			// option is positive delta, resulting in short delta exposure for DHV. needs hedging with a long pos
			deltaBorrowPremium =
				dollarDelta.mul(
					(ONE_SCALE_INT +
						((_isSell ? deltaBorrowRates.sellShort : deltaBorrowRates.buyLong) * ONE_SCALE_INT) /
						SIX_DPS_INT).pow(int(_time))
				) -
				dollarDelta;

			deltaBorrowPremium = deltaBorrowPremium.mul(
				_interpolateSpreadDelta(_tenorIndex, _remainder, false, _deltaBandIndex)
			);
		}
	}

	function _getTenorIndex(
		uint256 _expiration
	) internal view returns (uint16 tenorIndex, int256 remainder) {
		// get the ratio of the square root of seconds to expiry and the max tenor value in e18 form
		uint unroundedTenorIndex = (((((_expiration - block.timestamp) * 1e18).sqrt()) *
			(numberOfTenors - 1)) / maxTenorValue);
		require(unroundedTenorIndex / 1e18 <= 65535, "tenor index overflow");
		tenorIndex = uint16(unroundedTenorIndex / 1e18); // always floors
		remainder = int256(unroundedTenorIndex - tenorIndex * 1e18); // will be between 0 and 1e18
	}

	function _interpolateSlippageGradient(
		uint16 _tenor,
		int256 _remainder,
		bool _isPut,
		uint256 _deltaBand
	) internal view returns (uint80 slippageGradientMultiplier) {
		if (_isPut) {
			int80 y1 = tenorPricingParams[_tenor].putSlippageGradientMultipliers[_deltaBand];
			if (_remainder == 0) {
				return uint80(y1);
			}
			int80 y2 = tenorPricingParams[_tenor + 1].putSlippageGradientMultipliers[_deltaBand];
			return uint80(int80(y1 + _remainder.mul(y2 - y1)));
		} else {
			int80 y1 = tenorPricingParams[_tenor].callSlippageGradientMultipliers[_deltaBand];
			if (_remainder == 0) {
				return uint80(y1);
			}
			int80 y2 = tenorPricingParams[_tenor + 1].callSlippageGradientMultipliers[_deltaBand];
			return uint80(int80(y1 + _remainder.mul(y2 - y1)));
		}
	}

	function _interpolateSpreadCollateral(
		uint16 _tenor,
		int256 _remainder,
		bool _isPut,
		uint256 _deltaBand
	) internal view returns (uint80 spreadCollateralMultiplier) {
		if (_isPut) {
			int80 y1 = tenorPricingParams[_tenor].putSpreadCollateralMultipliers[_deltaBand];
			if (_remainder == 0) {
				return uint80(y1);
			}
			int80 y2 = tenorPricingParams[_tenor + 1].putSpreadCollateralMultipliers[_deltaBand];
			return uint80(int80(y1 + _remainder.mul(y2 - y1)));
		} else {
			int80 y1 = tenorPricingParams[_tenor].callSpreadCollateralMultipliers[_deltaBand];
			if (_remainder == 0) {
				return uint80(y1);
			}
			int80 y2 = tenorPricingParams[_tenor + 1].callSpreadCollateralMultipliers[_deltaBand];
			return uint80(int80(y1 + _remainder.mul(y2 - y1)));
		}
	}

	function _interpolateSpreadDelta(
		uint16 _tenor,
		int256 _remainder,
		bool _isPut,
		uint256 _deltaBand
	) internal view returns (int80 spreadDeltaMultiplier) {
		if (_isPut) {
			int80 y1 = tenorPricingParams[_tenor].putSpreadDeltaMultipliers[_deltaBand];
			if (_remainder == 0) {
				return y1;
			}
			int80 y2 = tenorPricingParams[_tenor + 1].putSpreadDeltaMultipliers[_deltaBand];
			return int80(y1 + _remainder.mul(y2 - y1));
		} else {
			int80 y1 = tenorPricingParams[_tenor].callSpreadDeltaMultipliers[_deltaBand];
			if (_remainder == 0) {
				return y1;
			}
			int80 y2 = tenorPricingParams[_tenor + 1].callSpreadDeltaMultipliers[_deltaBand];
			return int80(y1 + _remainder.mul(y2 - y1));
		}
	}

	function _getCollateralRequirements(
		Types.OptionSeries memory _optionSeries,
		uint256 _amount
	) internal view returns (uint256) {
		IMarginCalculator marginCalc = IMarginCalculator(addressBook.getMarginCalculator());

		return
			marginCalc.getNakedMarginRequired(
				_optionSeries.underlying,
				_optionSeries.strikeAsset,
				_optionSeries.collateral,
				_amount / SCALE_FROM,
				_optionSeries.strike / SCALE_FROM, // assumes in e18
				IOracle(addressBook.getOracle()).getPrice(_optionSeries.underlying),
				_optionSeries.expiration,
				18, // always have the value return in e18
				_optionSeries.isPut
			);
	}

	function _isExchangePaused() internal view {
		if (!OptionExchange(protocol.optionExchange()).paused()) {
			revert CustomErrors.ExchangeNotPaused();
		}
	}
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

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

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);
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
	function setOperator(address _operator, bool _isOperator) external;
	
	function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

	function operate(ActionArgs[] calldata _actions) external;

	function getAccountVaultCounter(address owner) external view returns (uint256);

	function oracle() external view returns (address);

	function getVault(address _owner, uint256 _vaultId)
		external
		view
		returns (GammaTypes.Vault memory);

	function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

	function isOperator(address _owner, address _operator) external view returns (bool);
	
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
pragma solidity 0.8.9;

import "../libraries/Types.sol";
import "../AlphaPortfolioValuesFeed.sol";

interface IAlphaPortfolioValuesFeed {
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

	function updateStores(Types.OptionSeries memory _optionSeries, int256 _shortExposure, int256 _longExposure, address _seriesAddress) external;
	function netDhvExposure(bytes32 oHash) external view returns (int256);
	///////////////////////////
	/// non-complex getters ///
	///////////////////////////


	function getPortfolioValues(address underlying, address strike)
		external
		view
		returns (Types.PortfolioValues memory);

	function storesForAddress(address seriesAddress) external view returns (AlphaPortfolioValuesFeed.OptionStores memory);
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

	function pullManager() external;
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

	function adjustVariables(uint256 collateralAmount, uint256 optionsValue, int256 delta, bool isSale) external;
	
	function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address);

	function resetEphemeralValues() external;

	function rebalancePortfolioDelta(int256 delta, uint256 index) external;
	
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
	function getSeries(Types.OptionSeries memory _series) external view returns (address);
	function vaultIds(address series) external view returns (uint256);
	function addressBook() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IOracle {
	function getPrice(address _asset) external view returns (uint256);

	function getExpiryPrice(address _asset, uint256 _expiryTimestamp)
		external
		view
		returns (uint256, bool);

	function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../libraries/Types.sol";

interface IPortfolioValuesFeed {
	struct OptionStore {
		Types.OptionSeries optionSeries;
		int256 shortExposure;
		int256 longExposure;
	}
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

	function updateStores(Types.OptionSeries memory _optionSeries, int256 _shortExposure, int256 _longExposure, address _seriesAddress) external;
	
	///////////////////////////
	/// non-complex getters ///
	///////////////////////////


	function getPortfolioValues(address underlying, address strike)
		external
		view
		returns (Types.PortfolioValues memory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IWhitelist {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isCoveredWhitelistedCollateral(
        address _collateral,
        address _underlying,
        bool _isPut
    ) external view returns (bool);

    function isNakedWhitelistedCollateral(
        address _collateral,
        address _underlying,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface OtokenInterface {
    function controller() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../Protocol.sol";
import "../interfaces/GammaInterface.sol";
import "../interfaces/IAlphaPortfolioValuesFeed.sol";

/**
 *  @title Lens contract to get user vault positions
 */
contract ExposureLensMK1 {

    // protocol
    Protocol public protocol;

	///////////////
	/// structs ///
	///////////////

	struct SeriesAddressDrill {
		string name;
		string symbol;
        int256 netDhvExposure; // e18
        uint64 expiration;
        bool isPut;
        uint128 strike; // e18
        address collateralAsset;
        bytes32 optionHash;
	}

	constructor(address _protocol) {
        protocol = Protocol(_protocol);
	}

	function getSeriesAddressDetails(address seriesAddress) external view returns (SeriesAddressDrill memory) {
		IOtoken otoken = IOtoken(seriesAddress);
        uint64 expiry = uint64(otoken.expiryTimestamp());
        bool isPut = otoken.isPut();
        uint128 strike = uint128(otoken.strikePrice() * 1e10);
        bytes32 oHash = keccak256(
			abi.encodePacked(expiry, strike, isPut)
		);
		int256 netDhvExposure = IAlphaPortfolioValuesFeed(protocol.portfolioValuesFeed()).netDhvExposure(oHash);
        SeriesAddressDrill memory seriesAddressDrill = SeriesAddressDrill(
            otoken.name(),
            otoken.symbol(),
            netDhvExposure,
            expiry,
            isPut,
            strike,
            otoken.collateralAsset(),
            oHash
            );

        return seriesAddressDrill;
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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.4;

import "./Types.sol";
import "./RyskActions.sol";
import { IController } from "../interfaces/GammaInterface.sol";

library CombinedActions {

	enum OperationType {
		OPYN,
		RYSK
	}

	struct OperationProcedures {
		OperationType operation;
		CombinedActions.ActionArgs[] operationQueue;
	}

    struct ActionArgs {
        // type of action that is being performed on the system
        uint256 actionType;
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
        // option series (if any)
        Types.OptionSeries optionSeries;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // OR for rysk actions it is the acceptable premium (if option is being sold to the dhv then the actual premium should be more than this number (i.e. max price),
        // if option is being bought from the dhv then the actual premium should be less than this number (i.e. max price))
        uint256 indexOrAcceptablePremium;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an opyn action
     * @param _args general action arguments structure
     * @return arguments for an opyn action
     */
    function _parseOpynArgs(ActionArgs memory _args) internal pure returns (IController.ActionArgs memory) {
        return IController.ActionArgs({
            actionType: IController.ActionType(_args.actionType),
            owner: _args.owner,
            secondAddress: _args.secondAddress,
            asset: _args.asset,
            vaultId: _args.vaultId,
            amount: _args.amount,
            index: _args.indexOrAcceptablePremium,
            data: _args.data
        });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an opyn action
     * @param _args general action arguments structure
     * @return arguments for an opyn action
     */
    function _parseRyskArgs(ActionArgs memory _args) internal pure returns (RyskActions.ActionArgs memory) {
        return RyskActions.ActionArgs({
            actionType: RyskActions.ActionType(_args.actionType),
            secondAddress: _args.secondAddress,
            asset: _args.asset,
            vaultId: _args.vaultId,
            amount: _args.amount,
            optionSeries: _args.optionSeries,
            acceptablePremium: _args.indexOrAcceptablePremium,
            data: _args.data
        });
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface CustomErrors {
	error NotKeeper();
	error IVNotFound();
	error NotHandler();
	error NotUpdater();
	error VaultExpired();
	error InvalidInput();
	error InvalidPrice();
	error InvalidBuyer();
	error InvalidOrder();
	error OrderExpired();
	error InvalidExpiry();
	error InvalidAmount();
	error TradingPaused();
	error InvalidAddress();
	error IssuanceFailed();
	error EpochNotClosed();
	error NoPositionsOpen();
	error InvalidDecimals();
	error InActivePosition();
	error NoActivePosition();
	error TradingNotPaused();
	error NotLiquidityPool();
	error UnauthorizedExit();
	error UnapprovedSeries();
	error SeriesNotBuyable();
	error ExchangeNotPaused();
	error DeltaNotDecreased();
	error NonExistentOtoken();
	error SeriesNotSellable();
	error InvalidGmxCallback();
	error GmxCallbackPending();
	error OrderExpiryTooLong();
	error InvalidShareAmount();
	error ExistingWithdrawal();
	error TotalSupplyReached();
	error StrikeAssetInvalid();
	error InsufficientBalance();
	error OptionStrikeInvalid();
	error OptionExpiryInvalid();
	error RangeOrderNotFilled();
	error NoExistingWithdrawal();
	error SpotMovedBeyondRange();
	error ReactorAlreadyExists();
	error UnauthorizedFulfill();
	error NonWhitelistedOtoken();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
pragma solidity >=0.8.9;

import "./Types.sol";
import "./CustomErrors.sol";
import "./BlackScholes.sol";
import "../tokens/ERC20.sol";

import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title Library used for various helper functionality for the Liquidity Pool
 */
library OptionsCompute {
	using PRBMathUD60x18 for uint256;
	using PRBMathSD59x18 for int256;

	uint8 private constant SCALE_DECIMALS = 18;
	uint256 private constant SCALE_UP = 10 ** 18;
	// oToken decimals
	uint8 private constant OPYN_DECIMALS = 8;
	// otoken conversion decimal
	uint8 private constant OPYN_CONVERSION_DECIMAL = 10;

	/// @dev assumes decimals are coming in as e18
	function convertToDecimals(uint256 value, uint256 decimals) internal pure returns (uint256) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		uint256 difference = SCALE_DECIMALS - decimals;
		return value / (10 ** difference);
	}

	/// @dev converts from specified decimals to e18
	function convertFromDecimals(
		uint256 value,
		uint256 decimals
	) internal pure returns (uint256 difference) {
		if (decimals > SCALE_DECIMALS) {
			revert();
		}
		difference = SCALE_DECIMALS - decimals;
		return value * (10 ** difference);
	}

	/// @dev converts from specified decimalsA to decimalsB
	function convertFromDecimals(
		uint256 value,
		uint8 decimalsA,
		uint8 decimalsB
	) internal pure returns (uint256) {
		uint8 difference;
		if (decimalsA > decimalsB) {
			difference = decimalsA - decimalsB;
			return value / (10 ** difference);
		}
		difference = decimalsB - decimalsA;
		return value * (10 ** difference);
	}

	// doesnt allow for interest bearing collateral
	function convertToCollateralDenominated(
		uint256 quote,
		uint256 underlyingPrice,
		Types.OptionSeries memory optionSeries
	) internal pure returns (uint256 convertedQuote) {
		if (optionSeries.strikeAsset != optionSeries.collateral) {
			// convert value from strike asset to collateral asset
			return (quote * SCALE_UP) / underlyingPrice;
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
	 * @notice Converts strike price to 1e8 format and floors least significant digits if needed
	 * @param  strikePrice strikePrice in 1e18 format
	 * @param  collateral address of collateral asset
	 * @return if the transaction succeeded
	 */
	function formatStrikePrice(uint256 strikePrice, address collateral) public view returns (uint256) {
		// convert strike to 1e8 format
		uint256 price = strikePrice / (10 ** OPYN_CONVERSION_DECIMAL);
		uint256 collateralDecimals = ERC20(collateral).decimals();
		if (collateralDecimals >= OPYN_DECIMALS) return price;
		uint256 difference = OPYN_DECIMALS - collateralDecimals;
		// round floor strike to prevent errors in Gamma protocol
		return (price / (10 ** difference)) * (10 ** difference);
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
		uint256 underlyingPrice,
		bool overrideIV
	) internal view returns (uint256 quote, int256 delta) {
		if (iv == 0) {
			revert CustomErrors.IVNotFound();
		}
		// reduce IV by a factor of bidAskIVSpread if we are buying the options
		if (isBuying && !overrideIV) {
			iv = (iv * (SCALE_UP - (bidAskIVSpread))) / SCALE_UP;
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

	function min(uint256 v1, uint256 v2) internal pure returns (uint256) {
		return v1 > v2 ? v2 : v1;
	}

	function max(int256 v1, int256 v2) internal pure returns (int256) {
		return v1 > v2 ? v1 : v2;
	}

	function toInt256(uint256 value) internal pure returns (int256) {
		// Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
		require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
		return int256(value);
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

	/**
	 * @notice Exercises an ITM option to a specific address
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin pool
	 * @param series is the address of the option to redeem
	 * @param amount is the number of oTokens to redeem - passed in as e8
	 * @return amount of asset received by exercising the option
	 */
	function redeemToAddress(
		address gammaController,
		address marginPool,
		address series,
		uint256 amount,
		address recipient
	) external returns (uint256) {
		IController controller = IController(gammaController);
		address collateralAsset = IOtoken(series).collateralAsset();
		uint256 startAssetBalance = ERC20(collateralAsset).balanceOf(recipient);

		// If it is after expiry, we need to redeem the profits
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.Redeem,
			address(0), // not used
			recipient, // address to send profits to
			series, // address of otoken
			0, // not used
			amount, // otoken balance
			0, // not used
			"" // not used
		);
		SafeTransferLib.safeApprove(ERC20(series), marginPool, amount);
		controller.operate(actions);

		uint256 endAssetBalance = ERC20(collateralAsset).balanceOf(recipient);
		// returns in collateral decimals
		return endAssetBalance - startAssetBalance;
	}
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.4;

import "./Types.sol";

/**
 * @title Actions
 * @author Rysk Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 * errorCode
 * A1 can only parse arguments for create otoken actions
 * A2 can only parse arguments for issue actions
 * A3 can only parse arguments for buy option actions
 * A4 can only parse arguments for sell option or close option actions
 */
library RyskActions {
    // possible actions that can be performed
    enum ActionType {
        Issue,
        BuyOption,
        SellOption,
        CloseOption
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // option series (if any)
        Types.OptionSeries optionSeries;
        // acceptable premium (if option is being sold to the dhv then the actual premium should be more than this number (i.e. max price),
        // if option is being bought from the dhv then the actual premium should be less than this number (i.e. max price))
        uint256 acceptablePremium;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct IssueArgs {
        // option series 
        Types.OptionSeries optionSeries;
    }

    struct BuyOptionArgs {
        // option series
        Types.OptionSeries optionSeries;
        // series address
        address seriesAddress;
        // amount of options to buy, always in e18
        uint256 amount;
        // recipient of the options
        address recipient;
        // acceptable premium for the trade, the actual premium must be smaller than this number
        uint256 acceptablePremium;
    }

    struct SellOptionArgs {
        // option series
        Types.OptionSeries optionSeries;
        // series address
        address seriesAddress;
        // vault id
        uint256 vaultId;
        // amount of options to sell, always in e18
        uint256 amount;
        // recipient of premium
        address recipient;
        // acceptable premium for the trade, the actual premium must be bigger than this number
        uint256 acceptablePremium;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an issue action
     * @param _args general action arguments structure
     * @return arguments for an issue action
     */
    function _parseIssueArgs(ActionArgs memory _args) internal pure returns (IssueArgs memory) {
        require(_args.actionType == ActionType.Issue, "A2");
        return IssueArgs({optionSeries: _args.optionSeries});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a buy option action
     * @param _args general action arguments structure
     * @return arguments for a buy option action
     */
    function _parseBuyOptionArgs(ActionArgs memory _args) internal pure returns (BuyOptionArgs memory) {
        require(_args.actionType == ActionType.BuyOption, "A3");
        return
            BuyOptionArgs({
                optionSeries: _args.optionSeries,
                seriesAddress: _args.asset,
                amount: _args.amount,
                recipient: _args.secondAddress,
                acceptablePremium: _args.acceptablePremium
            });
    }


    /**
     * @notice parses the passed in action arguments to get the arguments for a sell option action
     * @param _args general action arguments structure
     * @return arguments for a sell option action
     */
    function _parseSellOptionArgs(ActionArgs memory _args) internal pure returns (SellOptionArgs memory) {
        require(_args.actionType == ActionType.SellOption || _args.actionType == ActionType.CloseOption, "A4");
        return
            SellOptionArgs({
                optionSeries: _args.optionSeries,
                seriesAddress: _args.asset,
                vaultId: _args.vaultId,
                amount: _args.amount,
                recipient: _args.secondAddress,
                acceptablePremium: _args.acceptablePremium
            });
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "prb-math/contracts/PRBMath.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

library SABR {
	using PRBMathSD59x18 for int256;

	int256 private constant eps = 1e11;

	struct IntermediateVariables {
		int256 a;
		int256 b;
		int256 c;
		int256 d;
		int256 v;
		int256 w;
		int256 z;
		int256 k;
		int256 f;
		int256 t;
	}

	function lognormalVol(
		int256 k,
		int256 f,
		int256 t,
		int256 alpha,
		int256 beta,
		int256 rho,
		int256 volvol
	) internal pure returns (int256 iv) {
		// Hagan's 2002 SABR lognormal vol expansion.

		// negative strikes or forwards
		if (k <= 0 || f <= 0) {
			return 0;
		}

		IntermediateVariables memory vars;

		vars.k = k;
		vars.f = f;
		vars.t = t;
		if (beta == 1e18) {
			vars.a = 0;
			vars.v = 0;
			vars.w = 0;
		} else {
			vars.a = ((1e18 - beta).pow(2e18)).mul(alpha.pow(2e18)).div(
				int256(24e18).mul(_fkbeta(vars.f, vars.k, beta))
			);
			vars.v = ((1e18 - beta).pow(2e18)).mul(_logfk(vars.f, vars.k).powu(2)).div(24e18);
			vars.w = ((1e18 - beta).pow(4e18)).mul(_logfk(vars.f, vars.k).powu(4)).div(1920e18);
		}
		vars.b = int256(25e16).mul(rho).mul(beta).mul(volvol).mul(alpha).div(
			_fkbeta(vars.f, vars.k, beta).sqrt()
		);
		vars.c = (2e18 - int256(3e18).mul(rho.powu(2))).mul(volvol.pow(2e18)).div(24e18);
		vars.d = _fkbeta(vars.f, vars.k, beta).sqrt();
		vars.z = volvol.mul(_fkbeta(vars.f, vars.k, beta).sqrt()).mul(_logfk(vars.f, vars.k)).div(alpha);

		// if |z| > eps
		if (vars.z.abs() > eps) {
			int256 vz = alpha.mul(vars.z).mul(1e18 + (vars.a + vars.b + vars.c).mul(vars.t)).div(
				vars.d.mul(1e18 + vars.v + vars.w).mul(_x(rho, vars.z))
			);
			return vz;
			// if |z| <= eps
		} else {
			int256 v0 = alpha.mul(1e18 + (vars.a + vars.b + vars.c).mul(vars.t)).div(
				vars.d.mul(1e18 + vars.v + vars.w)
			);
			return v0;
		}
	}

	function _logfk(int256 f, int256 k) internal pure returns (int256) {
		return (f.div(k)).ln();
	}

	function _fkbeta(
		int256 f,
		int256 k,
		int256 beta
	) internal pure returns (int256) {
		return (f.mul(k)).pow(1e18 - beta);
	}

	function _x(int256 rho, int256 z) internal pure returns (int256) {
		int256 a = (1e18 - 2 * rho.mul(z) + z.powu(2)).sqrt() + z - rho;
		int256 b = 1e18 - rho;
		return (a.div(b)).ln();
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
	struct Option {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		bool isBuyable;
		bool isSellable;
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
pragma solidity >=0.8.9;

import "./tokens/ERC20.sol";
import "./libraries/Types.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";
import "./libraries/OptionsCompute.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";

/**
 *  @title OptionCatalogue
 *  @dev Store information on options approved for sale and to buy as well as netDhvExposure of the option
 */
contract OptionCatalogue is AccessControl {
	using PRBMathSD59x18 for int256;
	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	// asset that is used for collateral asset
	address public immutable collateralAsset;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	// storage of option information and approvals
	mapping(bytes32 => OptionStores) public optionStores;
	// array of expirations currently supported (mainly for frontend use)
	uint64[] public expirations;
	// details of supported options first key is expiration then isPut then an array of strikes (mainly for frontend use)
	mapping(uint256 => mapping(bool => uint128[])) public optionDetails;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// oToken decimals
	uint8 private constant OPYN_DECIMALS = 8;
	// scale otoken conversion decimals
	uint8 private constant CONVERSION_DECIMALS = 18 - OPYN_DECIMALS;

	/////////////////////////
	/// structs && events ///
	/////////////////////////

	struct OptionStores {
		bool approvedOption;
		bool isBuyable;
		bool isSellable;
	}

	event SeriesApproved(
		bytes32 indexed optionHash,
		uint64 expiration,
		uint128 strike,
		bool isPut,
		bool isBuyable,
		bool isSellable
	);
	event SeriesAltered(
		bytes32 indexed optionHash,
		uint64 expiration,
		uint128 strike,
		bool isPut,
		bool isBuyable,
		bool isSellable
	);

	constructor(address _authority, address _collateralAsset) AccessControl(IAuthority(_authority)) {
		collateralAsset = _collateralAsset;
	}

	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/**
	 * @notice issue an option series for buying or sale
	 * @param  options option type to approve - strike in e18
	 * @dev    only callable by the manager
	 */
	function issueNewSeries(Types.Option[] memory options) external {
		_onlyManager();
		uint256 addressLength = options.length;
		for (uint256 i = 0; i < addressLength; i++) {
			Types.Option memory o = options[i];
			// make sure the strike gets formatted properly
			uint128 strike = uint128(
				OptionsCompute.formatStrikePrice(o.strike, collateralAsset) * 10 ** (CONVERSION_DECIMALS)
			);
			if ((o.expiration - 28800) % 86400 != 0) {
				revert CustomErrors.InvalidExpiry();
			}
			// get the hash of the option (how the option is stored on the books)
			bytes32 optionHash = keccak256(abi.encodePacked(o.expiration, strike, o.isPut));
			// if the option is already issued then skip it
			if (optionStores[optionHash].approvedOption) {
				continue;
			}
			// store information on the series
			optionStores[optionHash] = OptionStores(
				true, // approval
				o.isBuyable,
				o.isSellable
			);
			// store it in an array, these are mainly for frontend/informational use
			// if the strike array is empty for calls and puts for that expiry it means that this expiry hasnt been issued yet
			// so we should save the expory
			if (
				optionDetails[o.expiration][true].length == 0 && optionDetails[o.expiration][false].length == 0
			) {
				expirations.push(o.expiration);
			}
			// we wouldnt get here if the strike already existed, so we store it in the array
			// there shouldnt be any duplicates in the strike array or expiration array
			optionDetails[o.expiration][o.isPut].push(strike);
			// emit an event of the series creation, now users can write options on this series
			emit SeriesApproved(optionHash, o.expiration, strike, o.isPut, o.isBuyable, o.isSellable);
		}
	}

	/**
	 * @notice change whether an issued option is for buy or sale
	 * @param  options option type to change status on - strike in e18
	 * @dev    only callable by the manager
	 */
	function changeOptionBuyOrSell(Types.Option[] memory options) external {
		_onlyManager();
		uint256 adLength = options.length;
		for (uint256 i = 0; i < adLength; i++) {
			Types.Option memory o = options[i];
			// make sure the strike gets formatted properly, we get it to e8 format in the converter
			// then convert it back to e18
			uint128 strike = uint128(
				OptionsCompute.formatStrikePrice(o.strike, collateralAsset) * 10 ** (CONVERSION_DECIMALS)
			);
			// get the option hash
			bytes32 optionHash = keccak256(abi.encodePacked(o.expiration, strike, o.isPut));
			// if its already approved then we can change its parameters, if its not approved then revert as there is a mistake
			if (optionStores[optionHash].approvedOption) {
				optionStores[optionHash].isBuyable = o.isBuyable;
				optionStores[optionHash].isSellable = o.isSellable;
				emit SeriesAltered(optionHash, o.expiration, strike, o.isPut, o.isBuyable, o.isSellable);
			} else {
				revert CustomErrors.UnapprovedSeries();
			}
		}
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	/**
	 * @notice get list of all expirations ever activated
	 * @return list of expirations
	 */
	function getExpirations() external view returns (uint64[] memory) {
		return expirations;
	}

	/**
	 * @notice get list of all strikes for a specific expiration and flavour
	 * @return list of strikes for a specific expiry and flavour
	 */
	function getOptionDetails(uint64 expiration, bool isPut) external view returns (uint128[] memory) {
		return optionDetails[expiration][isPut];
	}

	function getOptionStores(bytes32 oHash) external view returns (OptionStores memory) {
		return optionStores[oHash];
	}

	function isBuyable(bytes32 oHash) external view returns (bool) {
		return optionStores[oHash].isBuyable;
	}

	function isSellable(bytes32 oHash) external view returns (bool) {
		return optionStores[oHash].isSellable;
	}

	function approvedOptions(bytes32 oHash) external view returns (bool) {
		return optionStores[oHash].approvedOption;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./Protocol.sol";
import "./PriceFeed.sol";
import "./BeyondPricer.sol";
import "./OptionCatalogue.sol";

import "./tokens/ERC20.sol";
import "./libraries/Types.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";
import "./libraries/OptionsCompute.sol";
import "./libraries/SafeTransferLib.sol";
import "./libraries/OpynInteractions.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IHedgingReactor.sol";
import "./interfaces/IOptionRegistry.sol";
import "./interfaces/OtokenInterface.sol";
import "./interfaces/AddressBookInterface.sol";
import "./interfaces/IAlphaPortfolioValuesFeed.sol";

import "./libraries/RyskActions.sol";
import "./libraries/CombinedActions.sol";

import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IOtoken, IController } from "./interfaces/GammaInterface.sol";

/**
 *  @title Contract used for all user facing options interactions
 *  @dev Interacts with liquidityPool to write options and quote their prices.
 */
contract OptionExchange is Pausable, AccessControl, ReentrancyGuard, IHedgingReactor {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	///////////////////////////
	/// immutable variables ///
	///////////////////////////

	// Liquidity pool contract
	ILiquidityPool public immutable liquidityPool;
	// protocol management contract
	Protocol public immutable protocol;
	// asset that denominates the strike price
	address public immutable strikeAsset;
	// asset that is used as the reference asset
	address public immutable underlyingAsset;
	// asset that is used for collateral asset
	address public immutable collateralAsset;
	/// @notice address book used for the gamma protocol
	AddressBookInterface public immutable addressbook;
	/// @notice instance of the uniswap V3 router interface
	ISwapRouter public immutable swapRouter;

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	// pricer contract used for pricing options
	BeyondPricer public pricer;
	/// @notice pool fees for different swappable assets
	mapping(address => uint24) public poolFees;
	/// @notice fee recipient
	address public feeRecipient;
	/// @notice option catalogue
	OptionCatalogue public catalogue;
	/// @notice maximum amount allowed for a single trade
	uint256 public maxTradeSize = 1000e18;
	/// @notice minimum amount allowed for a single trade
	uint256 public minTradeSize = 1e17;
	/// @notice mapping of approved collateral for puts and calls
	mapping(address => mapping(bool => bool)) public approvedCollateral;

	///////////////////////////
	/// transient variables ///
	///////////////////////////

	// user -> token addresses interacted with in this transaction
	mapping(address => address[]) internal tempTokenQueue;
	// user -> token address -> amount
	mapping(address => mapping(address => uint256)) public heldTokens;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	/// @notice max bips used for percentages
	uint256 private constant MAX_BIPS = 10_000;
	// oToken decimals
	uint8 private constant OPYN_DECIMALS = 8;
	// scale otoken conversion decimals
	uint8 private constant CONVERSION_DECIMALS = 10;
	/// @notice used for unlimited token approval
	uint256 private constant MAX_UINT = 2 ** 256 - 1;

	/////////////////////////
	/// structs && events ///
	/////////////////////////

	struct SellParams {
		address seriesAddress;
		Types.OptionSeries seriesToStore;
		Types.OptionSeries optionSeries;
		uint256 premium;
		int256 delta;
		uint256 fee;
		uint256 amount;
		uint256 tempHoldings;
		uint256 transferAmount;
		uint256 premiumSent;
	}

	struct BuyParams {
		address seriesAddress;
		Types.OptionSeries seriesToStore;
		Types.OptionSeries optionSeries;
		uint128 strikeDecimalConverted;
		uint256 premium;
		int256 delta;
		uint256 fee;
	}

	event OptionsIssued(address indexed series);
	event OptionsBought(
		address indexed series,
		address indexed buyer,
		uint256 optionAmount,
		uint256 premium,
		uint256 fee
	);
	event OptionsSold(
		address indexed series,
		address indexed seller,
		uint256 optionAmount,
		uint256 premium,
		uint256 fee
	);
	event OptionsRedeemed(
		address indexed series,
		uint256 optionAmount,
		uint256 redeemAmount,
		address redeemAsset
	);
	event RedemptionSent(uint256 redeemAmount, address redeemAsset, address recipient);
	event OtokenMigrated(address newOptionExchange, address otoken, uint256 amount);

	error TradeTooSmall();
	error TradeTooLarge();
	error PoolFeeNotSet();
	error TokenImbalance();
	error NothingToClose();
	error PremiumTooSmall();
	error ForbiddenAction();
	error CloseSizeTooLarge();
	error UnauthorisedSender();
	error OperatorNotApproved();
	error TooMuchSlippage();

	constructor(
		address _authority,
		address _protocol,
		address _liquidityPool,
		address _pricer,
		address _addressbook,
		address _swapRouter,
		address _feeRecipient,
		address _catalogue
	) AccessControl(IAuthority(_authority)) {
		protocol = Protocol(_protocol);
		liquidityPool = ILiquidityPool(_liquidityPool);
		collateralAsset = liquidityPool.collateralAsset();
		underlyingAsset = liquidityPool.underlyingAsset();
		strikeAsset = liquidityPool.strikeAsset();
		addressbook = AddressBookInterface(_addressbook);
		swapRouter = ISwapRouter(_swapRouter);
		pricer = BeyondPricer(_pricer);
		catalogue = OptionCatalogue(_catalogue);
		feeRecipient = _feeRecipient;
	}

	///////////////
	/// setters ///
	///////////////

	function pause() external {
		_onlyGuardian();
		_pause();
	}

	function unpause() external {
		_onlyGuardian();
		_unpause();
	}

	/**
	 * @notice change the pricer
	 */
	function setPricer(address _pricer) external {
		_onlyGovernor();
		pricer = BeyondPricer(_pricer);
	}

	/**
	 * @notice change the catalogue
	 */
	function setOptionCatalogue(address _catalogue) external {
		_onlyGovernor();
		catalogue = OptionCatalogue(_catalogue);
	}

	/**
	 * @notice change the fee recipient
	 */
	function setFeeRecipient(address _feeRecipient) external {
		_onlyGovernor();
		feeRecipient = _feeRecipient;
	}

	/// @notice set the uniswap v3 pool fee for a given asset, also give the asset max approval on the uni v3 swap router
	function setPoolFee(address asset, uint24 fee) external {
		_onlyGovernor();
		poolFees[asset] = fee;
		SafeTransferLib.safeApprove(ERC20(asset), address(swapRouter), MAX_UINT);
	}

	/// @notice set the maximum and minimum trade size
	function setTradeSizeLimits(uint256 _minTradeSize, uint256 _maxTradeSize) external {
		_onlyGovernor();
		minTradeSize = _minTradeSize;
		maxTradeSize = _maxTradeSize;
	}

	/// @notice set whether a collateral is approved for selling to the vault
	function changeApprovedCollateral(address collateral, bool isPut, bool isApproved) external {
		_onlyGovernor();
		approvedCollateral[collateral][isPut] = isApproved;
	}

	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	/// @inheritdoc IHedgingReactor
	function withdraw(uint256 _amount) external returns (uint256) {
		require(msg.sender == address(liquidityPool));
		address _token = collateralAsset;
		// check the holdings if enough just lying around then transfer it
		uint256 balance = ERC20(_token).balanceOf(address(this));
		if (balance == 0) {
			return 0;
		}
		if (_amount <= balance) {
			SafeTransferLib.safeTransfer(ERC20(_token), msg.sender, _amount);
			// return in collat decimals format
			return _amount;
		} else {
			SafeTransferLib.safeTransfer(ERC20(_token), msg.sender, balance);
			// return in collatDecimals format
			return balance;
		}
	}

	/**
	 * @notice get the dhv to redeem an expired otoken
	 * @param _series the list of series to redeem
	 */
	function redeem(address[] memory _series, uint256[] memory amountOutMinimums) external {
		_onlyManager();
		uint256 adLength = _series.length;
		if (adLength != amountOutMinimums.length) revert CustomErrors.InvalidInput();
		for (uint256 i; i < adLength; i++) {
			// get the number of otokens held by this address for the specified series
			uint256 optionAmount = ERC20(_series[i]).balanceOf(address(this));
			IOtoken otoken = IOtoken(_series[i]);
			// redeem from opyn to this address
			uint256 redeemAmount = OpynInteractions.redeemToAddress(
				addressbook.getController(),
				addressbook.getMarginPool(),
				_series[i],
				optionAmount,
				address(this)
			);

			address otokenCollateralAsset = otoken.collateralAsset();
			emit OptionsRedeemed(_series[i], optionAmount, redeemAmount, otokenCollateralAsset);
			// if the collateral used by the otoken is the collateral asset then transfer the redemption to the liquidity pool
			// if the collateral used by the otoken is anything else (or if underlying and sellRedemptions is true) then swap it on uniswap and send the proceeds to the liquidity pool
			if (otokenCollateralAsset == collateralAsset) {
				SafeTransferLib.safeTransfer(ERC20(collateralAsset), address(liquidityPool), redeemAmount);
				emit RedemptionSent(redeemAmount, collateralAsset, address(liquidityPool));
			} else {
				uint256 redeemableCollateral = _swapExactInputSingle(
					redeemAmount,
					amountOutMinimums[i],
					otokenCollateralAsset
				);
				SafeTransferLib.safeTransfer(
					ERC20(collateralAsset),
					address(liquidityPool),
					redeemableCollateral
				);
				emit RedemptionSent(redeemableCollateral, collateralAsset, address(liquidityPool));
			}
		}
	}

	/**
	 * @notice transfer otokens held by this address to a new option exchange or to the option handler
	 * @param newOptionExchange the option exchange to migrate to or handler
	 * @param otokens the otoken addresses to transfer
	 */
	function transferOtokens(address newOptionExchange, address[] memory otokens) external {
		_onlyGovernor();
		uint256 len = otokens.length;
		for (uint256 i = 0; i < len; i++) {
			if (OtokenInterface(otokens[i]).underlyingAsset() != underlyingAsset) {
				revert CustomErrors.NonWhitelistedOtoken();
			}
			uint256 balance = ERC20(otokens[i]).balanceOf(address(this));
			SafeTransferLib.safeTransfer(ERC20(otokens[i]), newOptionExchange, balance);
			emit OtokenMigrated(newOptionExchange, otokens[i], balance);
		}
	}

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice create an otoken, distinguished from issue because we may not want this option on the option registry
	 * @param optionSeries - otoken to create (strike in e18)
	 * @return series the address of the otoken created
	 */
	function createOtoken(Types.OptionSeries memory optionSeries) external returns (address series) {
		// deploy an oToken contract address
		// assumes strike is passed in e18, converts to e8
		uint128 formattedStrike = uint128(
			OptionsCompute.formatStrikePrice(optionSeries.strike, collateralAsset)
		);
		// check for an opyn oToken if it doesn't exist deploy it
		series = OpynInteractions.getOrDeployOtoken(
			address(addressbook.getOtokenFactory()),
			optionSeries.collateral,
			optionSeries.underlying,
			optionSeries.strikeAsset,
			formattedStrike,
			optionSeries.expiration,
			optionSeries.isPut
		);
	}

	/**
	 * @notice entry point to the contract for users, takes a queue of actions for both opyn and rysk and executes them sequentially
	 * @param  _operationProcedures an array of actions to be executed sequentially
	 */
	function operate(
		CombinedActions.OperationProcedures[] memory _operationProcedures
	) external nonReentrant whenNotPaused {
		_runActions(_operationProcedures);
		_verifyFinalState();
	}

	//////////////////////////////////
	/// primary internal functions ///
	//////////////////////////////////

	function _runActions(CombinedActions.OperationProcedures[] memory _operationProcedures) internal {
		for (uint256 i = 0; i < _operationProcedures.length; i++) {
			CombinedActions.OperationProcedures memory operationProcedure = _operationProcedures[i];
			CombinedActions.OperationType operation = operationProcedure.operation;
			if (operation == CombinedActions.OperationType.OPYN) {
				_runOpynActions(operationProcedure.operationQueue);
			} else if (operation == CombinedActions.OperationType.RYSK) {
				_runRyskActions(operationProcedure.operationQueue);
			}
		}
	}

	/**
	 * @notice verify all final state
	 */
	function _verifyFinalState() internal {
		address[] memory interactedTokens = tempTokenQueue[msg.sender];
		uint256 arr = interactedTokens.length;
		for (uint256 i = 0; i < arr; i++) {
			uint256 tempTokens = heldTokens[msg.sender][interactedTokens[i]];
			if (tempTokens != 0) {
				if (interactedTokens[i] == collateralAsset) {
					SafeTransferLib.safeTransfer(ERC20(collateralAsset), msg.sender, tempTokens);
					heldTokens[msg.sender][interactedTokens[i]] = 0;
				} else {
					revert TokenImbalance();
				}
			}
		}
		delete tempTokenQueue[msg.sender];
	}

	function _runOpynActions(CombinedActions.ActionArgs[] memory _opynActions) internal {
		IController controller = IController(addressbook.getController());
		uint256 arr = _opynActions.length;
		IController.ActionArgs[] memory _opynArgs = new IController.ActionArgs[](arr);
		// users need to have this contract approved as an operator so it can carry out actions on the user's behalf
		if (!controller.isOperator(msg.sender, address(this))) {
			revert OperatorNotApproved();
		}
		for (uint256 i = 0; i < arr; i++) {
			// loop through the opyn actions, if any involve opening a vault then make sure the msg.sender gets the ownership and if there are any more vault ids make sure the msg.sender is the owners
			IController.ActionArgs memory action = CombinedActions._parseOpynArgs(_opynActions[i]);
			IController.ActionType actionType = action.actionType;
			// make sure the owner parameter being sent in is the msg.sender this makes sure senders arent messing around with other vaults
			if (action.owner != msg.sender) {
				revert UnauthorisedSender();
			}
			if (actionType == IController.ActionType.DepositLongOption) {
				if (action.secondAddress != msg.sender) {
					revert UnauthorisedSender();
				}
			} else if (actionType == IController.ActionType.OpenVault) {
				// check the from address to make sure it comes from the user or if we are holding them temporarily then they are held here
			} else if (actionType == IController.ActionType.WithdrawLongOption) {
				// check the to address to see whether it is being sent to the user or held here temporarily
				if (action.secondAddress == address(this)) {
					_updateTempHoldings(action.asset, action.amount * 10 ** CONVERSION_DECIMALS);
				}
			} else if (actionType == IController.ActionType.DepositCollateral) {
				// check the from address is the msg.sender so the sender cant take collat from elsewhere
				if (action.secondAddress != msg.sender && action.secondAddress != address(this)) {
					revert UnauthorisedSender();
				}
				// if the address is this address then for UX purposes the collateral will be handled here
				// (this means the user only needs to do one approval for collateral to this address)
				if (action.secondAddress == address(this)) {
					SafeTransferLib.safeTransferFrom(action.asset, msg.sender, address(this), action.amount);
					// approve the margin pool from this account
					SafeTransferLib.safeApprove(ERC20(action.asset), addressbook.getMarginPool(), action.amount);
				}
			} else if (actionType == IController.ActionType.MintShortOption) {
				if (action.secondAddress == address(this)) {
					_updateTempHoldings(action.asset, action.amount * 10 ** CONVERSION_DECIMALS);
				}
				// check the to address to see whether it is being sent to the user or held here temporarily
			} else if (actionType == IController.ActionType.BurnShortOption) {
				if (action.secondAddress != msg.sender) {
					revert UnauthorisedSender();
				}
			} else if (actionType == IController.ActionType.WithdrawCollateral) {
				if (action.secondAddress != msg.sender) {
					revert UnauthorisedSender();
				}
			} else if (actionType == IController.ActionType.SettleVault) {
				if (action.secondAddress != msg.sender) {
					revert UnauthorisedSender();
				}
			} else {
				revert ForbiddenAction();
			}
			_opynArgs[i] = action;
		}
		controller.operate(_opynArgs);
	}

	function _runRyskActions(CombinedActions.ActionArgs[] memory _ryskActions) internal {
		for (uint256 i = 0; i < _ryskActions.length; i++) {
			// loop through the rysk actions
			RyskActions.ActionArgs memory action = CombinedActions._parseRyskArgs(_ryskActions[i]);
			RyskActions.ActionType actionType = action.actionType;
			if (actionType == RyskActions.ActionType.Issue) {
				_issue(RyskActions._parseIssueArgs(action));
			} else if (actionType == RyskActions.ActionType.BuyOption) {
				_buyOption(RyskActions._parseBuyOptionArgs(action));
			} else if (actionType == RyskActions.ActionType.SellOption) {
				_sellOption(RyskActions._parseSellOptionArgs(action), false);
			} else if (actionType == RyskActions.ActionType.CloseOption) {
				_sellOption(RyskActions._parseSellOptionArgs(action), true);
			}
		}
	}

	/**
	 * @notice issue an otoken that the dhv can now sell to buyers
	 * @param _args RyskAction struct containing details on the option to issue
	 * @return series the address of the option activated for selling by the dhv
	 */
	function _issue(RyskActions.IssueArgs memory _args) internal returns (address series) {
		// format the strike correctly
		uint128 strike = uint128(
			OptionsCompute.formatStrikePrice(_args.optionSeries.strike, collateralAsset) *
				10 ** CONVERSION_DECIMALS
		);
		// check if the option series is approved
		bytes32 oHash = keccak256(
			abi.encodePacked(_args.optionSeries.expiration, strike, _args.optionSeries.isPut)
		);
		OptionCatalogue.OptionStores memory optionStore = catalogue.getOptionStores(oHash);
		if (!optionStore.approvedOption) {
			revert CustomErrors.UnapprovedSeries();
		}
		// check if the series is buyable
		if (!optionStore.isBuyable) {
			revert CustomErrors.SeriesNotBuyable();
		}
		if (_args.optionSeries.strikeAsset != _args.optionSeries.collateral) {
			revert CustomErrors.CollateralAssetInvalid();
		}
		series = liquidityPool.handlerIssue(_args.optionSeries);
		emit OptionsIssued(series);
	}

	/**
	 * @notice function that allows a user to buy options from the dhv where they pay the dhv using the collateral asset
	 * @param _args RyskAction struct containing details on the option to buy
	 */
	function _buyOption(RyskActions.BuyOptionArgs memory _args) internal {
		if (_args.amount < minTradeSize) revert TradeTooSmall();
		if (_args.amount > maxTradeSize) revert TradeTooLarge();
		// get the option details in the correct formats
		IOptionRegistry optionRegistry = getOptionRegistry();
		IAlphaPortfolioValuesFeed portfolioValuesFeed = getPortfolioValuesFeed();
		BuyParams memory buyParams;
		bytes32 oHash;
		(buyParams.seriesAddress, buyParams.seriesToStore, buyParams.optionSeries, oHash) = _preChecks(
			_args.seriesAddress,
			_args.optionSeries,
			optionRegistry,
			false
		);
		address recipient = _args.recipient;
		// calculate premium and delta from the option pricer, returning the premium in collateral decimals and delta in e18
		(buyParams.premium, buyParams.delta, buyParams.fee) = pricer.quoteOptionPrice(
			buyParams.seriesToStore,
			_args.amount,
			false,
			portfolioValuesFeed.netDhvExposure(oHash)
		);
		if (buyParams.premium > _args.acceptablePremium) {
			revert TooMuchSlippage();
		}
		_handlePremiumTransfer(buyParams.premium, buyParams.fee);
		// get what the exchange's balance is on this asset, as this can be used instead of the dhv having to lock up collateral
		uint256 longExposure = ERC20(buyParams.seriesAddress).balanceOf(address(this)) *
			10 ** CONVERSION_DECIMALS;
		uint256 amount = _args.amount;
		emit OptionsBought(buyParams.seriesAddress, recipient, amount, buyParams.premium, buyParams.fee);
		if (longExposure > 0) {
			// calculate the maximum amount that should be bought by the user
			uint256 boughtAmount = longExposure > amount ? amount : uint256(longExposure);
			// transfer the otokens to the user
			SafeTransferLib.safeTransfer(
				ERC20(buyParams.seriesAddress),
				recipient,
				boughtAmount / (10 ** CONVERSION_DECIMALS)
			);
			// update the series on the stores
			portfolioValuesFeed.updateStores(
				buyParams.seriesToStore,
				0,
				-int256(boughtAmount),
				buyParams.seriesAddress
			);
			liquidityPool.adjustVariables(
				0,
				buyParams.premium.mul(boughtAmount).div(_args.amount),
				buyParams.delta.mul(int256(boughtAmount)).div(int256(_args.amount)),
				true
			);
			amount -= boughtAmount;
			if (amount == 0) {
				return;
			}
		}
		if (buyParams.optionSeries.collateral != collateralAsset) {
			revert CustomErrors.CollateralAssetInvalid();
		}
		// add this series to the portfolio values feed so its stored on the book
		portfolioValuesFeed.updateStores(
			buyParams.seriesToStore,
			int256(amount),
			0,
			buyParams.seriesAddress
		);
		// get the liquidity pool to write the options
		liquidityPool.handlerWriteOption(
			buyParams.optionSeries,
			buyParams.seriesAddress,
			amount,
			optionRegistry,
			buyParams.premium.mul(amount).div(_args.amount),
			buyParams.delta.mul(int256(amount)).div(int256(_args.amount)),
			recipient
		);
	}

	/**
	 * @notice function that allows a user to sell options to the dhv and pays them a premium in the vaults collateral asset
	 * @param _args RyskAction struct containing details on the option to sell
	 * @param isClose if true then we only close positions the dhv has open, we do not conduct any more sales beyond that
	 */
	function _sellOption(RyskActions.SellOptionArgs memory _args, bool isClose) internal {
		if (_args.amount < minTradeSize) revert TradeTooSmall();
		if (_args.amount > maxTradeSize) revert TradeTooLarge();
		IOptionRegistry optionRegistry = getOptionRegistry();
		IAlphaPortfolioValuesFeed portfolioValuesFeed = getPortfolioValuesFeed();
		SellParams memory sellParams;
		bytes32 oHash;
		(sellParams.seriesAddress, sellParams.seriesToStore, sellParams.optionSeries, oHash) = _preChecks(
			_args.seriesAddress,
			_args.optionSeries,
			optionRegistry,
			true
		);
		// get the unit price for premium and delta
		(sellParams.premium, sellParams.delta, sellParams.fee) = pricer.quoteOptionPrice(
			sellParams.seriesToStore,
			_args.amount,
			true,
			portfolioValuesFeed.netDhvExposure(oHash)
		);
		if (sellParams.premium < _args.acceptablePremium) {
			revert TooMuchSlippage();
		}
		sellParams.amount = _args.amount;
		sellParams.tempHoldings = OptionsCompute.min(
			heldTokens[msg.sender][sellParams.seriesAddress],
			_args.amount
		);
		heldTokens[msg.sender][sellParams.seriesAddress] -= sellParams.tempHoldings;
		int256 shortExposure = portfolioValuesFeed
			.storesForAddress(sellParams.seriesAddress)
			.shortExposure;
		if (shortExposure > 0) {
			// if they are just closing and the amount to close is bigger than the dhv's position then we revert
			if (isClose && OptionsCompute.toInt256(sellParams.amount) > shortExposure) {
				revert CloseSizeTooLarge();
			}
			sellParams = _handleDHVBuyback(sellParams, shortExposure, optionRegistry);
		} else if (isClose) {
			// if they are closing and there is nothing to close then we revert
			revert NothingToClose();
		}
		// if they are not closing and the premium / 8 is less than or equal to the fee then we revert
		// because the sale doesnt make sense
		if (!isClose && (sellParams.premium >> 3) <= sellParams.fee) {
			revert PremiumTooSmall();
		}
		if (sellParams.amount > 0) {
			if (sellParams.amount > sellParams.tempHoldings) {
				// transfer the otokens to this exchange
				SafeTransferLib.safeTransferFrom(
					sellParams.seriesAddress,
					msg.sender,
					address(this),
					OptionsCompute.convertToDecimals(
						sellParams.amount - sellParams.tempHoldings,
						ERC20(sellParams.seriesAddress).decimals()
					)
				);
			}
			// update on the pvfeed stores
			portfolioValuesFeed.updateStores(
				sellParams.seriesToStore,
				0,
				int256(sellParams.amount),
				sellParams.seriesAddress
			);
			liquidityPool.adjustVariables(
				0,
				sellParams.premium.mul(sellParams.amount).div(_args.amount),
				sellParams.delta.mul(int256(sellParams.amount)).div(int256(_args.amount)),
				false
			);
		}
		// this accounts for premium sent from buyback as well as any rounding errors from the dhv buyback
		if (sellParams.premium > sellParams.premiumSent) {
			// we need to make sure we arent eating into the withdraw partition or the liquidity buffer with this trade
			if (ILiquidityPool(liquidityPool).checkBuffer() < int256((sellParams.premium - sellParams.premiumSent))) {
				revert CustomErrors.MaxLiquidityBufferReached();
		}
			// take the funds from the liquidity pool and pay them here
			SafeTransferLib.safeTransferFrom(
				collateralAsset,
				address(liquidityPool),
				address(this),
				sellParams.premium - sellParams.premiumSent
			);
		}
		// transfer any fees
		// bitshift to the right 3 times to get to 1/8
		if ((sellParams.premium >> 3) > sellParams.fee) {
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), feeRecipient, sellParams.fee);
		} else {
			// if the total fee is greater than premium / 8 then the fee is capped at , this is to avoid disincentivising selling back to the pool for collateral release
			sellParams.fee = sellParams.premium >> 3;
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), feeRecipient, sellParams.fee);
		}
		// if the recipient is this address then update the temporary holdings now to indicate the premium is temporarily being held here
		if (_args.recipient == address(this)) {
			_updateTempHoldings(collateralAsset, sellParams.premium - sellParams.fee);
		} else {
			// transfer premium to the recipient
			SafeTransferLib.safeTransfer(
				ERC20(collateralAsset),
				_args.recipient,
				sellParams.premium - sellParams.fee
			);
		}
		emit OptionsSold(
			sellParams.seriesAddress,
			_args.recipient,
			_args.amount,
			sellParams.premium,
			sellParams.fee
		);
	}

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	/**
	 * @notice get the option registry used for storing and managing the options
	 * @return the option registry contract
	 */
	function getOptionRegistry() internal view returns (IOptionRegistry) {
		return IOptionRegistry(protocol.optionRegistry());
	}

	/**
	 * @notice get the portfolio values feed used by the liquidity pool
	 * @return the portfolio values feed contract
	 */
	function getPortfolioValuesFeed() internal view returns (IAlphaPortfolioValuesFeed) {
		return IAlphaPortfolioValuesFeed(protocol.portfolioValuesFeed());
	}

	/// @inheritdoc IHedgingReactor
	function getDelta() external view returns (int256 delta) {
		return 0;
	}

	/// @inheritdoc IHedgingReactor
	function getPoolDenominatedValue() external view returns (uint256) {
		return ERC20(collateralAsset).balanceOf(address(this));
	}

	function getOptionDetails(
		address seriesAddress,
		Types.OptionSeries memory optionSeries
	) external view returns (address, Types.OptionSeries memory, uint128) {
		return _getOptionDetails(seriesAddress, optionSeries, getOptionRegistry());
	}

	function checkHash(
		Types.OptionSeries memory optionSeries,
		uint128 strikeDecimalConverted,
		bool isSell
	) external view returns (bytes32 oHash) {
		return _checkHash(optionSeries, strikeDecimalConverted, isSell);
	}

	//////////////////////////
	/// internal utilities ///
	//////////////////////////

	function _getOptionDetails(
		address seriesAddress,
		Types.OptionSeries memory optionSeries,
		IOptionRegistry optionRegistry
	) internal view returns (address, Types.OptionSeries memory, uint128) {
		// if the series address is not known then we need to find it by looking for the otoken,
		// if we cant find it then it means the otoken hasnt been created yet, strike is e18
		if (seriesAddress == address(0)) {
			seriesAddress = optionRegistry.getOtoken(
				optionSeries.underlying,
				optionSeries.strikeAsset,
				optionSeries.expiration,
				optionSeries.isPut,
				optionSeries.strike,
				optionSeries.collateral
			);
			optionSeries = Types.OptionSeries(
				optionSeries.expiration,
				uint128(OptionsCompute.formatStrikePrice(optionSeries.strike, collateralAsset)),
				optionSeries.isPut,
				optionSeries.underlying,
				optionSeries.strikeAsset,
				optionSeries.collateral
			);
		} else {
			// if the series address was passed in as non zero then we'll first check the option registry storage,
			// if its not there then we know this isnt a buyback operation
			optionSeries = optionRegistry.getSeriesInfo(seriesAddress);
			// make sure the expiry actually exists, if it doesnt then get the otoken itself
			if (optionSeries.expiration == 0) {
				IOtoken otoken = IOtoken(seriesAddress);
				// get the option details
				optionSeries = Types.OptionSeries(
					uint64(otoken.expiryTimestamp()),
					uint128(otoken.strikePrice()),
					otoken.isPut(),
					otoken.underlyingAsset(),
					otoken.strikeAsset(),
					otoken.collateralAsset()
				);
			}
		}
		if (seriesAddress == address(0)) {
			revert CustomErrors.NonExistentOtoken();
		}
		// strike is in e18
		// make sure the expiry actually exists
		if (optionSeries.expiration == 0) {
			revert CustomErrors.NonExistentOtoken();
		}
		// strikeDecimalConverted is the formatted strike price (for e8) in e18 format
		// option series returned with e8
		uint128 strikeDecimalConverted = uint128(optionSeries.strike * 10 ** CONVERSION_DECIMALS);
		// we need to make sure the seriesAddress is actually whitelisted as an otoken in case the actor wants to
		// try sending a made up otoken
		IWhitelist whitelist = IWhitelist(addressbook.getWhitelist());
		if (!whitelist.isWhitelistedOtoken(seriesAddress)) {
			revert CustomErrors.NonWhitelistedOtoken();
		}
		return (seriesAddress, optionSeries, strikeDecimalConverted);
	}

	function _checkHash(
		Types.OptionSeries memory optionSeries,
		uint128 strikeDecimalConverted,
		bool isSell
	) internal view returns (bytes32 oHash) {
		// check if the option series is approved
		oHash = keccak256(
			abi.encodePacked(optionSeries.expiration, strikeDecimalConverted, optionSeries.isPut)
		);
		OptionCatalogue.OptionStores memory optionStore = catalogue.getOptionStores(oHash);
		if (!optionStore.approvedOption) {
			revert CustomErrors.UnapprovedSeries();
		}
		if (isSell) {
			if (!optionStore.isSellable) {
				revert CustomErrors.SeriesNotSellable();
			}
		} else {
			if (!optionStore.isBuyable) {
				revert CustomErrors.SeriesNotBuyable();
			}
		}
	}

	/** @notice function to sell exact amount of assetIn to the minimum amountOutMinimum of collateralAsset
	 *  @param _amountIn the exact amount of assetIn to sell
	 *  @param _amountOutMinimum the min amount of collateral asset willing to receive. Slippage limit.
	 *  @param _assetIn the asset to swap from
	 *  @return the amount of usdc received
	 */
	function _swapExactInputSingle(
		uint256 _amountIn,
		uint256 _amountOutMinimum,
		address _assetIn
	) internal returns (uint256) {
		uint24 poolFee = poolFees[_assetIn];
		if (poolFee == 0) {
			revert PoolFeeNotSet();
		}
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: _assetIn,
			tokenOut: collateralAsset,
			fee: poolFee,
			recipient: address(this),
			deadline: block.timestamp,
			amountIn: _amountIn,
			amountOutMinimum: _amountOutMinimum,
			sqrtPriceLimitX96: 0
		});

		// The call to `exactInputSingle` executes the swap.
		uint256 amountOut = swapRouter.exactInputSingle(params);
		return amountOut;
	}

	function _updateTempHoldings(address asset, uint256 amount) internal {
		if (heldTokens[msg.sender][asset] == 0) {
			tempTokenQueue[msg.sender].push(asset);
		}
		heldTokens[msg.sender][asset] += amount;
	}

	function _handlePremiumTransfer(uint256 premium, uint256 fee) internal {
		// check if we need to transfer anything from the user into this wallet
		if (premium + fee > heldTokens[msg.sender][collateralAsset]) {
			uint256 diff = premium + fee - heldTokens[msg.sender][collateralAsset];
			// reduce their temporary holdings to 0
			heldTokens[msg.sender][collateralAsset] = 0;
			SafeTransferLib.safeTransferFrom(collateralAsset, msg.sender, address(this), diff);
		} else {
			// reduce their temporary holdings by the premium and fee
			heldTokens[msg.sender][collateralAsset] -= premium + fee;
		}
		// handle fees
		if (fee > 0) {
			SafeTransferLib.safeTransfer(ERC20(collateralAsset), feeRecipient, fee);
		}
		// transfer premium to liquidity pool
		SafeTransferLib.safeTransfer(ERC20(collateralAsset), address(liquidityPool), premium);
	}

	function _preChecks(
		address _seriesAddress,
		Types.OptionSeries memory _optionSeries,
		IOptionRegistry _optionRegistry,
		bool isSell
	) internal view returns (address, Types.OptionSeries memory, Types.OptionSeries memory, bytes32) {
		(
			address seriesAddress,
			Types.OptionSeries memory optionSeries,
			uint128 strikeDecimalConverted
		) = _getOptionDetails(_seriesAddress, _optionSeries, _optionRegistry);
		// check the option hash and option series for validity
		bytes32 oHash = _checkHash(optionSeries, strikeDecimalConverted, isSell);
		// check details of the option series
		if (optionSeries.expiration <= block.timestamp) {
			revert CustomErrors.OptionExpiryInvalid();
		}
		if (optionSeries.underlying != underlyingAsset) {
			revert CustomErrors.UnderlyingAssetInvalid();
		}
		if (optionSeries.strikeAsset != strikeAsset) {
			revert CustomErrors.StrikeAssetInvalid();
		}
		if (!approvedCollateral[optionSeries.collateral][optionSeries.isPut]) {
			revert CustomErrors.CollateralAssetInvalid();
		}
		// convert the strike to e18 decimals for storage
		Types.OptionSeries memory seriesToStore = Types.OptionSeries(
			optionSeries.expiration,
			strikeDecimalConverted,
			optionSeries.isPut,
			underlyingAsset,
			strikeAsset,
			optionSeries.collateral
		);
		return (seriesAddress, seriesToStore, optionSeries, oHash);
	}

	function _handleDHVBuyback(
		SellParams memory sellParams,
		int256 shortExposure,
		IOptionRegistry optionRegistry
	) internal returns (SellParams memory) {
		sellParams.transferAmount = OptionsCompute.min(uint256(shortExposure), sellParams.amount);
		// will transfer any tempHoldings they have here to the liquidityPool
		if (sellParams.tempHoldings > 0) {
			SafeTransferLib.safeTransfer(
				ERC20(sellParams.seriesAddress),
				address(liquidityPool),
				OptionsCompute.convertToDecimals(
					OptionsCompute.min(sellParams.tempHoldings, sellParams.transferAmount),
					ERC20(sellParams.seriesAddress).decimals()
				)
			);
		}
		// want to check if they have any otokens in their wallet and send those here
		if (sellParams.transferAmount > sellParams.tempHoldings) {
			SafeTransferLib.safeTransferFrom(
				sellParams.seriesAddress,
				msg.sender,
				address(liquidityPool),
				OptionsCompute.convertToDecimals(
					sellParams.transferAmount - sellParams.tempHoldings,
					ERC20(sellParams.seriesAddress).decimals()
				)
			);
		}
		sellParams.premiumSent = sellParams.premium.mul(sellParams.transferAmount).div(sellParams.amount);
		uint256 soldBackAmount = liquidityPool.handlerBuybackOption(
			sellParams.optionSeries,
			sellParams.transferAmount,
			optionRegistry,
			sellParams.seriesAddress,
			sellParams.premiumSent,
			sellParams.delta.mul(OptionsCompute.toInt256(sellParams.transferAmount)).div(
				OptionsCompute.toInt256(sellParams.amount)
			),
			address(this)
		);
		// update the series on the stores
		getPortfolioValuesFeed().updateStores(
			sellParams.seriesToStore,
			-int256(soldBackAmount),
			0,
			sellParams.seriesAddress
		);
		sellParams.amount -= soldBackAmount;
		sellParams.tempHoldings -= OptionsCompute.min(sellParams.tempHoldings, sellParams.transferAmount);
		return sellParams;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	/// @inheritdoc IHedgingReactor
	function update() external pure returns (uint256) {
		return 0;
	}

	/// @inheritdoc IHedgingReactor
	function hedgeDelta(int256 _delta) external returns (int256) {
		revert();
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
	address public sequencerUptimeFeedAddress;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	uint8 private constant SCALE_DECIMALS = 18;
	// seconds since the last price feed update until we deem the data to be stale
	uint32 private constant STALE_PRICE_DELAY = 3600;
	// seconds after arbitrum sequencer comes back online that we start accepting price feed data
	uint32 private constant GRACE_PERIOD_TIME = 1800; // 30 minutes

	//////////////
	/// errors ///
	//////////////

	error SequencerDown();
	error GracePeriodNotOver();

	constructor(address _authority, address _sequencerUptimeFeedAddress)
		AccessControl(IAuthority(_authority))
	{
		sequencerUptimeFeedAddress = _sequencerUptimeFeedAddress;
	}

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

	function setSequencerUptimeFeedAddress(address _sequencerUptimeFeedAddress) external {
		_onlyGovernor();
		sequencerUptimeFeedAddress = _sequencerUptimeFeedAddress;
	}

	///////////////////////
	/// complex getters ///
	///////////////////////

	function getRate(address underlying, address strike) external view returns (uint256) {
		address feedAddress = priceFeeds[underlying][strike];
		require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		// check arbitrum sequencer status
		_checkSequencerUp();
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
		// check arbitrum sequencer status
		_checkSequencerUp();
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

	/// @dev check arbitrum sequencer status and time since it last came back online
	function _checkSequencerUp() internal view {
		AggregatorV3Interface sequencerUptimeFeed = AggregatorV3Interface(sequencerUptimeFeedAddress);
		(, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed.latestRoundData();
		if (!(answer == 0)) {
			revert SequencerDown();
		}

		uint256 timeSinceUp = block.timestamp - startedAt;
		if (timeSinceUp <= GRACE_PERIOD_TIME) {
			revert GracePeriodNotOver();
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./libraries/AccessControl.sol";

/**
 *  @title Contract used for storage of important contracts for the liquidity pool
 */
contract Protocol is AccessControl {
	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	address public optionRegistry;
	address public volatilityFeed;
	address public portfolioValuesFeed;
	address public accounting;
	address public priceFeed;
	address public optionExchange;

	constructor(address _authority) AccessControl(IAuthority(_authority)) {}

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

	function changeAccounting(address _accounting) external {
		_onlyGovernor();
		accounting = _accounting;
	}

	function changePriceFeed(address _priceFeed) external {
		_onlyGovernor();
		priceFeed = _priceFeed;
	}

	function changeOptionRegistry(address _optionRegistry) external {
		_onlyGovernor();
		optionRegistry = _optionRegistry;
	}

	function changeOptionExchange(address _optionExchange) external {
		_onlyGovernor();
		optionExchange = _optionExchange;
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
pragma solidity >=0.8.9;

import "./libraries/AccessControl.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/SABR.sol";
import "./Protocol.sol";
import "./OptionExchange.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 *  @title Contract used as the Dynamic Hedging Vault for storing funds, issuing shares and processing options transactions
 *  @dev Interacts with liquidity pool to feed in volatility data.
 */
contract VolatilityFeed is AccessControl {
	using PRBMathSD59x18 for int256;
	using PRBMathUD60x18 for uint256;

	//////////////////////////
	/// settable variables ///
	//////////////////////////

	// Parameters for the sabr volatility model
	mapping(uint256 => SABRParams) public sabrParams;
	// keeper mapping
	mapping(address => bool) public keeper;
	// expiry array
	uint256[] public expiries;

	//////////////////////////
	/// constant variables ///
	//////////////////////////

	// number of seconds in a year used for calculations
	int256 private constant ONE_YEAR_SECONDS = 31557600;
	int256 private constant BIPS_SCALE = 1e12;
	int256 private constant BIPS = 1e6;
	int256 private constant maxInterestRate = 200e18;
	int256 private constant minInterestRate = -200e18;

	///////////////////////////
	/// immutable variables ///
	///////////////////////////
	Protocol public immutable protocol;

	struct SABRParams {
		int32 callAlpha; // not bigger or less than an int32 and above 0
		int32 callBeta; // greater than 0 and less than or equal to 1
		int32 callRho; // between 1 and -1
		int32 callVolvol; // not bigger or less than an int32 and above 0
		int32 putAlpha;
		int32 putBeta;
		int32 putRho;
		int32 putVolvol;
		int256 interestRate; // interest rate in e18
	}

	constructor(address _authority, address _protocol) AccessControl(IAuthority(_authority)) {
		protocol = Protocol(_protocol);
	}

	///////////////
	/// setters ///
	///////////////

	error AlphaError();
	error BetaError();
	error RhoError();
	error VolvolError();
	error InterestRateError();

	event SabrParamsSet(
		uint256 indexed _expiry,
		int32 callAlpha,
		int32 callBeta,
		int32 callRho,
		int32 callVolvol,
		int32 putAlpha,
		int32 putBeta,
		int32 putRho,
		int32 putVolvol,
		int256 interestRate
	);
	event KeeperUpdated(address keeper, bool auth);

	/**
	 * @notice set the sabr volatility params
	 * @param _sabrParams set the SABR parameters
	 * @param _expiry the expiry that the SABR parameters represent
	 * @dev   only keepers can call this function
	 */
	function setSabrParameters(SABRParams memory _sabrParams, uint256 _expiry) external {
		_isKeeper();
		_isExchangePaused();
		if (_sabrParams.callAlpha <= 0 || _sabrParams.putAlpha <= 0) {
			revert AlphaError();
		}
		if (_sabrParams.callVolvol <= 0 || _sabrParams.putVolvol <= 0) {
			revert VolvolError();
		}
		if (
			_sabrParams.callBeta <= 0 ||
			_sabrParams.callBeta > BIPS ||
			_sabrParams.putBeta <= 0 ||
			_sabrParams.putBeta > BIPS
		) {
			revert BetaError();
		}
		if (
			_sabrParams.callRho <= -BIPS ||
			_sabrParams.callRho >= BIPS ||
			_sabrParams.putRho <= -BIPS ||
			_sabrParams.putRho >= BIPS
		) {
			revert RhoError();
		}
		if (_sabrParams.interestRate > maxInterestRate || _sabrParams.interestRate < minInterestRate) {
			revert InterestRateError();
		}
		// if the expiry is not already a registered expiry then add it to the expiry list
		if (sabrParams[_expiry].callAlpha == 0) {
			expiries.push(_expiry);
		}
		sabrParams[_expiry] = _sabrParams;
		emit SabrParamsSet(
			_expiry,
			_sabrParams.callAlpha,
			_sabrParams.callBeta,
			_sabrParams.callRho,
			_sabrParams.callVolvol,
			_sabrParams.putAlpha,
			_sabrParams.putBeta,
			_sabrParams.putRho,
			_sabrParams.putVolvol,
			_sabrParams.interestRate
		);
	}

	/// @notice update the keepers
	function setKeeper(address _keeper, bool _auth) external {
		_onlyGovernor();
		keeper[_keeper] = _auth;
		emit KeeperUpdated(_keeper, _auth);
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
	 * @return vol Implied volatility adjusted for volatility surface
	 */
	function getImpliedVolatility(
		bool isPut,
		uint256 underlyingPrice,
		uint256 strikePrice,
		uint256 expiration
	) external view returns (uint256 vol) {
		(vol, ) = _getImpliedVolatility(isPut, underlyingPrice, strikePrice, expiration);
	}

	/**
	 * @notice get the current implied volatility from the feed
	 * @param isPut Is the option a call or put?
	 * @param underlyingPrice The underlying price
	 * @param strikePrice The strike price of the option
	 * @param expiration expiration timestamp of option as a PRBMath Float
	 * @return vol Implied volatility adjusted for volatility surface
	 * @return forward price of spot accounting for the interest rate
	 */
	function getImpliedVolatilityWithForward(
		bool isPut,
		uint256 underlyingPrice,
		uint256 strikePrice,
		uint256 expiration
	) external view returns (uint256 vol, uint256 forward) {
		(vol, forward) = _getImpliedVolatility(isPut, underlyingPrice, strikePrice, expiration);
	}

	/**
	 * @notice get the current implied volatility from the feed
	 * @param isPut Is the option a call or put?
	 * @param underlyingPrice The underlying price
	 * @param strikePrice The strike price of the option
	 * @param expiration expiration timestamp of option as a PRBMath Float
	 * @return Implied volatility adjusted for volatility surface
	 * @return forward price of spot accounting for the interest rate
	 */
	function _getImpliedVolatility(
		bool isPut,
		uint256 underlyingPrice,
		uint256 strikePrice,
		uint256 expiration
	) internal view returns (uint256, uint256) {
		int256 time = (int256(expiration) - int256(block.timestamp)).div(ONE_YEAR_SECONDS);
		if (time <= 0) {
			revert CustomErrors.OptionExpiryInvalid();
		}
		int256 vol;
		SABRParams memory sabrParams_ = sabrParams[expiration];
		if (sabrParams_.callAlpha == 0) {
			revert CustomErrors.IVNotFound();
		}
		int256 forwardPrice = int256(underlyingPrice).mul(
			(PRBMathSD59x18.exp(sabrParams_.interestRate.mul(time)))
		);
		if (!isPut) {
			vol = SABR.lognormalVol(
				int256(strikePrice),
				forwardPrice,
				time,
				sabrParams_.callAlpha * BIPS_SCALE,
				sabrParams_.callBeta * BIPS_SCALE,
				sabrParams_.callRho * BIPS_SCALE,
				sabrParams_.callVolvol * BIPS_SCALE
			);
		} else {
			vol = SABR.lognormalVol(
				int256(strikePrice),
				forwardPrice,
				time,
				sabrParams_.putAlpha * BIPS_SCALE,
				sabrParams_.putBeta * BIPS_SCALE,
				sabrParams_.putRho * BIPS_SCALE,
				sabrParams_.putVolvol * BIPS_SCALE
			);
		}
		if (vol <= 0) {
			revert CustomErrors.IVNotFound();
		}
		return (uint256(vol), uint256(forwardPrice));
	}

	/**
	 @notice get the expiry array
	 @return the expiry array
	 */
	function getExpiries() external view returns (uint256[] memory) {
		return expiries;
	}

	/// @dev keepers, managers or governors can access
	function _isKeeper() internal view {
		if (
			!keeper[msg.sender] && msg.sender != authority.governor() && msg.sender != authority.manager()
		) {
			revert CustomErrors.NotKeeper();
		}
	}

	function _isExchangePaused() internal view {
		if (!OptionExchange(protocol.optionExchange()).paused()) {
			revert CustomErrors.ExchangeNotPaused();
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