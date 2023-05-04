// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/core/IVault.sol";
import "../core/AccessControlBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract FeeStrategy is AccessControlBase {
	/*==================================================== Events =============================================================*/

	event FeeMultiplierChanged(uint256 multiplier);

	event ConfigUpdated(uint256 maxMultiplier, uint256 minMultiplier);

	/*==================================================== State Variables ====================================================*/

	enum ReserveChangeType {
		PROFIT,
		LOSS
	}

	struct Config {
		uint256 maxMultiplier;
		uint256 minMultiplier;
	}

	struct PeriodReserve {
		uint256 totalAmount;
		uint256 profit;
		uint256 loss;
		ReserveChangeType changeType;
		uint256 currentMultiplier;
	}

	Config public config = Config(12_500_000_000_000_000, 7_500_000_000_000_000);

	/// @notice Last calculated multipliers index id
	uint256 public lastCalculatedIndex = 0;
	/// @notice Start time of periods
	uint256 public periodStartTime = block.timestamp - 40 minutes;
	/// @notice The reserve changes of given period duration
	mapping(uint256 => PeriodReserve) public periodReserves;
	/// @notice Last calculated multiplier
	uint256 public currentMultiplier;
	/// @notice Vault address
	IVault public vault;

	/*==================================================== Constant Variables ==================================================*/

	/// @notice used to calculate precise decimals
	uint256 private constant PRECISION = 1e18;

	/*==================================================== FUNCTIONS ===========================================================*/

	constructor(
		IVault _vault,
		address _vaultRegistry,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) {
		require(address(_vault) != address(0), "Vault address zero");
		vault = _vault;
		currentMultiplier = config.maxMultiplier;

	}

	/**
	 *
	 * @param config_ max, min multipliers
	 * @notice funtion to set new max min multipliers config
	 */
	function updateConfig(Config memory config_) public onlyGovernance {
		require(config_.maxMultiplier != 0, "Max zero");
		require(config_.minMultiplier != 0, "Min zero");
		require(config_.minMultiplier < config_.maxMultiplier, "Min greater than max");

		config.maxMultiplier = config_.maxMultiplier;
		config.minMultiplier = config_.minMultiplier;

		emit ConfigUpdated(config_.maxMultiplier, config_.minMultiplier);
	}

	/**
	 * @param _vault address of vault
	 * @notice function to set vault address
	 */
	function setVault(IVault _vault) public onlyGovernance {
		require(address(_vault) != address(0), "vault zero address");
		vault = _vault;
	}

	/**
	 * @dev Public function to calculate the dollar value of a given token amount.
	 * @param _token The address of the whitelisted token on the vault.
	 * @param _amount The amount of the given token.
	 * @return _dollarValue The dollar value of the given token amount.
	 * @notice This function takes the address of a whitelisted token on the vault and an amount of that token,
	 *  and calculates the dollar value of that amount by multiplying the amount by the current dollar value of the token
	 *  on the vault and dividing by 10^decimals of the token. The result is then divided by 1e12 to convert to USD.
	 */
	function computeDollarValue(
		address _token,
		uint256 _amount
	) public view returns (uint256 _dollarValue) {
		uint256 _decimals = IERC20Metadata(_token).decimals(); // Get the decimals of the token using the IERC20Metadata interface
		_dollarValue = ((_amount * vault.getMinPrice(_token)) / 10 ** _decimals); // Calculate the dollar value by multiplying the amount by the current dollar value of the token on the vault and dividing by 10^decimals
		_dollarValue = _dollarValue / 1e12; // Convert the result to USD by dividing by 1e12
	}

	/**
	 * @param _token address of the wl token
	 * @return _totalLoss total loss on vault
	 * @return _totalProfit total profit on vault
	 * @notice function to read profit and loss from vault
	 */
	function _getProfitLoss(
		address _token
	) internal view returns (uint256 _totalLoss, uint256 _totalProfit) {
		(_totalLoss, _totalProfit) = vault.returnTotalOutAndIn(_token);
	}

	/**
	 * @dev Internal function to calculate the total profit and loss for the vault.
	 * @return _totalLoss The total loss in USD.
	 * @return _totalProfit The total profit in USD.
	 * @notice This function iterates over all whitelisted tokens in the vault and calculates the profit and loss
	 * in USD for each token using the _getProfitLoss() function. The dollar value of the profit and loss is
	 * calculated using the computeDollarValue() function, and the total profit and loss values are returned.
	 */
	function _computeProfitLoss()
		internal
		view
		returns (uint256 _totalLoss, uint256 _totalProfit)
	{
		// Get the length of the allWhitelistedTokens array
		uint256 _allWhitelistedTokensLength = vault.allWhitelistedTokensLength();

		// Iterate over all whitelisted tokens in the vault
		for (uint256 i = 0; i < _allWhitelistedTokensLength; i++) {
			address _token = vault.allWhitelistedTokens(i); // Get the address of the current token
			(uint256 _loss, uint256 _profit) = _getProfitLoss(_token); // Calculate the profit and loss for the current token
			uint256 _lossInDollar = computeDollarValue(_token, _loss); // Convert the loss value to USD using the computeDollarValue() function
			uint256 _profitInDollar = computeDollarValue(_token, _profit); // Convert the profit value to USD using the computeDollarValue() function
			_totalLoss += _lossInDollar; // Add the loss value in USD to the total loss
			_totalProfit += _profitInDollar; // Add the profit value in USD to the total profit
		}
	}

	/**
	 * @param _index day index
	 * @param _wagerFee wager fee percentage in 1e18
	 * @notice function to set wager fee to vault for a given day
	 */
	function _setWagerFee(uint256 _index, uint256 _wagerFee) internal {
		periodReserves[_index].currentMultiplier = _wagerFee;
		vault.setWagerFee(_wagerFee);
		emit FeeMultiplierChanged(currentMultiplier);
	}

	/*================================================== Mining =================================================*/
	/**
	 * @dev Public function to get the current period index.
	 * @return periodIndex index of the day
	 */
	function getPeriodIndex() public view returns (uint256 periodIndex) {
		periodIndex = (block.timestamp - periodStartTime) / 20 minutes;
	}

	/**
	 *
	 * @dev Internal function to set period reserve with profit loss calculation.
	 * @param index The index of the day being processed.
	 * @notice This function updates the reserve for a given day based on the total profit and loss values
	 *  calculated by the _computeProfitLoss() function. It determines whether the reserve should be updated
	 *  due to a profit or loss and stores the result in the periodReserves array.
	 */
	function setReserve(uint256 index) internal {
		// Calculate the total loss and total profit values using the _computeProfitLoss() function
		(uint256 _totalLoss, uint256 _totalProfit) = _computeProfitLoss();

		// Declare variables for use in determining reserve change type and amount
		ReserveChangeType changeType_;
		uint256 amount_;

		// Determine whether the total profit is greater than or equal to the total loss
		if (_totalProfit >= _totalLoss) {
			amount_ = _totalProfit - _totalLoss; // Calculate the reserve amount as the difference between total profit and total loss
		} else {
			amount_ = _totalLoss - _totalProfit; // Calculate the reserve amount as the difference between total loss and total profit
		}

		// Determine whether the reserve change type should be set to PROFIT or LOSS
		bool isProfit = _totalProfit > _totalLoss;

		if (isProfit) {
			changeType_ = ReserveChangeType.PROFIT; // Set the reserve change type to PROFIT
		} else if (_totalLoss > _totalProfit) {
			changeType_ = ReserveChangeType.LOSS; // Set the reserve change type to LOSS
		}
		// If this is not the first day, check the previous day's reserve to see if it should be updated
		if (index > 2) {
			PeriodReserve memory prevReserve_ = periodReserves[index - 1]; // Get the previous day's reserve
			_totalProfit - prevReserve_.profit; // Subtract the previous day's profit from the total profit

			// Determine whether the reserve change type should be set to PROFIT or LOSS based on the difference between
			// the total profit and total loss for the current day and the previous day
			if (_totalProfit - prevReserve_.profit > _totalLoss - prevReserve_.loss) {
				changeType_ = ReserveChangeType.PROFIT;
			} else {
				changeType_ = ReserveChangeType.LOSS;
			}
		}

		// Store the updated reserve for the current day in the periodReserves array
		periodReserves[index] = PeriodReserve(
			amount_,
			_totalProfit,
			_totalLoss,
			changeType_,
			0
		);
	}

	/**
	 *
	 * @dev Public function to get the difference in reserve amounts between two periods.
	 * @param prevIndex The index of the previous period.
	 * @param currentIndex The index of the current period.
	 * @return prevPeriod_ The reserve information for the previous period.
	 * @return diffReserve_ The difference in reserve amounts between the two periods.
	 */
	function getDifference(
		uint256 prevIndex,
		uint256 currentIndex
	)
		public
		view
		returns (PeriodReserve memory prevPeriod_, PeriodReserve memory diffReserve_)
	{
		// Get the reserve information for the previous and current periods
		prevPeriod_ = periodReserves[prevIndex];
		PeriodReserve memory currentPeriod_ = periodReserves[currentIndex];

		// Calculate the difference in reserve amounts between the two periods
		if (prevPeriod_.totalAmount >= currentPeriod_.totalAmount) {
			diffReserve_.totalAmount =
				prevPeriod_.totalAmount -
				currentPeriod_.totalAmount;
		} else {
			diffReserve_.totalAmount =
				currentPeriod_.totalAmount -
				prevPeriod_.totalAmount;
		}

		// Set the change type of the difference reserve to the change type of the current period
		diffReserve_.changeType = currentPeriod_.changeType;
	}

	/**
	 *
	 * @dev Internal function to calculate the current multiplier.
	 * @notice This function calculates the current multiplier based on the reserve amount for the current period.
	 * @return The current multiplier as a uint256 value.
	 */
	function _getMultiplier() internal returns (uint256) {
		// Get the current period index
		uint256 index  = getPeriodIndex();

		// If the current period index is the same as the last calculated index, return the current multiplier
		if (lastCalculatedIndex == index) {
			return currentMultiplier;
		}

		// Set the reserve for the current period index
		setReserve(index);

		// If the period index is less than 1, set the current multiplier to the minimum multiplier value
		if (index <= 2) {
			currentMultiplier = config.maxMultiplier;
			periodReserves[index].currentMultiplier = config.maxMultiplier;
		} else {
			// Calculate the difference in reserves between the current and previous periods
			(
				PeriodReserve memory prevPeriodReserve_,
				PeriodReserve memory diffReserve_
			) = getDifference(index - 2, index -1);
			uint256 diff = diffReserve_.totalAmount;
			uint256 periodChangeRate;

			// If the previous period reserve and the difference in reserves are not equal to zero, calculate the period change rate
			if (prevPeriodReserve_.totalAmount != 0 && diff != 0) {
				periodChangeRate =
					(diff * PRECISION) /
					prevPeriodReserve_.totalAmount;
			}

			// If the difference in reserves represents a loss, decrease the current multiplier accordingly
			if (diffReserve_.changeType == ReserveChangeType.LOSS) {
				uint256 decrease = (2 * (currentMultiplier * periodChangeRate)) /
					PRECISION;
				currentMultiplier = currentMultiplier > decrease
					? currentMultiplier - decrease
					: config.minMultiplier;
			}
			// Otherwise, increase the current multiplier according to the period change rate
			else if (periodChangeRate != 0) {
				currentMultiplier =
					(currentMultiplier * (1e18 + periodChangeRate)) /
					PRECISION;
			}

			// If the current multiplier exceeds the maximum multiplier value, set it to the maximum value
			currentMultiplier = currentMultiplier > config.maxMultiplier
				? config.maxMultiplier
				: currentMultiplier;

			// If the current multiplier is less than the minimum multiplier value, set it to the minimum value
			currentMultiplier = currentMultiplier < config.minMultiplier
				? config.minMultiplier
				: currentMultiplier;
		}

		// Update the last calculated index to the current period index
		lastCalculatedIndex = index;

		// Set the wager fee for the current period index and current multiplier
		_setWagerFee(index, currentMultiplier);

		// Return the current multiplier
		return currentMultiplier;
	}

	/**
	 * @param _token address of the input (wl) token
	 * @param _amount amount of the token
	 * @notice function to calculation with current multiplier
	 */
	function calculate(address _token, uint256 _amount) external returns (uint256 amount_) {
		uint256 _value = computeDollarValue(_token, _amount);
		amount_ = (_value * _getMultiplier()) / PRECISION;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
	/*==================== Events *====================*/
	event BuyUSDW(
		address account,
		address token,
		uint256 tokenAmount,
		uint256 usdwAmount,
		uint256 feeBasisPoints
	);
	event SellUSDW(
		address account,
		address token,
		uint256 usdwAmount,
		uint256 tokenAmount,
		uint256 feeBasisPoints
	);
	event Swap(
		address account,
		address tokenIn,
		address tokenOut,
		uint256 amountIn,
		uint256 indexed amountOut,
		uint256 indexed amountOutAfterFees,
		uint256 indexed feeBasisPoints
	);
	event DirectPoolDeposit(address token, uint256 amount);
	error TokenBufferViolation(address tokenAddress);
	error PriceZero();

	event PayinWLP(
		// address of the token sent into the vault
		address tokenInAddress,
		// amount payed in (was in escrow)
		uint256 amountPayin
	);

	event PlayerPayout(
		// address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
		address recipient,
		// address of the token paid to the player
		address tokenOut,
		// net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
		uint256 amountPayoutTotal
	);

	event AmountOutNull();

	event WithdrawAllFees(
		address tokenCollected,
		uint256 swapFeesCollected,
		uint256 wagerFeesCollected,
		uint256 referralFeesCollected
	);

	event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

	event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

	event WagerFeeChanged(uint256 newWagerFee);

	event ReferralDistributionReverted(uint256 registeredTooMuch, uint256 maxVaueAllowed);

	/*==================== Operational Functions *====================*/
	function setPayoutHalted(bool _setting) external;

	// function isInitialized() external view returns (bool);

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	// function router() external view returns (address);

	function usdw() external view returns (address);

	function feeCollector() external returns (address);

	function hasDynamicFees() external view returns (bool);

	function totalTokenWeights() external view returns (uint256);

	function getTargetUsdwAmount(address _token) external view returns (uint256);

	function inManagerMode() external view returns (bool);

	function isManager(address _account) external view returns (bool);

	function tokenBalances(address _token) external view returns (uint256);

	function setInManagerMode(bool _inManagerMode) external;

	function setManager(address _manager, bool _isManager, bool _isWLPManager) external;

	function setIsSwapEnabled(bool _isSwapEnabled) external;

	function setUsdwAmount(address _token, uint256 _amount) external;

	function setBufferAmount(address _token, uint256 _amount) external;

	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _minimumBurnMintFee,
		bool _hasDynamicFees
	) external;

	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _redemptionBps,
		uint256 _maxUsdwAmount,
		bool _isStable
	) external;

	function setPriceFeedRouter(address _priceFeed) external;

	function withdrawAllFees(address _token) external returns (uint256, uint256, uint256);

	function directPoolDeposit(address _token) external;

	function deposit(address _tokenIn, address _receiver, bool _swapLess) external returns (uint256);

	function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function tokenToUsdMin(
		address _tokenToPrice,
		uint256 _tokenAmount
	) external view returns (uint256);

	function priceOracleRouter() external view returns (address);

	function taxBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function minimumBurnMintFee() external view returns (uint256);

	function allWhitelistedTokensLength() external view returns (uint256);

	function allWhitelistedTokens(uint256) external view returns (address);

	function stableTokens(address _token) external view returns (bool);

	function swapFeeReserves(address _token) external view returns (uint256);

	function tokenDecimals(address _token) external view returns (uint256);

	function tokenWeights(address _token) external view returns (uint256);

	function poolAmounts(address _token) external view returns (uint256);

	function bufferAmounts(address _token) external view returns (uint256);

	function usdwAmounts(address _token) external view returns (uint256);

	function maxUsdwAmounts(address _token) external view returns (uint256);

	function getRedemptionAmount(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function setVaultManagerAddress(address _vaultManagerAddress, bool _setting) external;

	function wagerFeeBasisPoints() external view returns (uint256);

	function setWagerFee(uint256 _wagerFee) external;

	function wagerFeeReserves(address _token) external view returns (uint256);

	function referralReserves(address _token) external view returns (uint256);

	function getReserve() external view returns (uint256);

	function getWlpValue() external view returns (uint256);

	function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToToken(
		address _token,
		uint256 _usdAmount,
		uint256 _price
	) external view returns (uint256);

	function returnTotalOutAndIn(
		address token_
	) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

	function payout(
		address[2] calldata _tokens,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

	function setAsideReferral(address _token, uint256 _amount) external;

	function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;
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

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
	function getBuyUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSellUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdwDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);
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