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
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier onlySupport() {
        require(
            registry.isCallerSupport(_msgSender()),
            "Forbidden: Only Support"
        );
        _;
    }

    modifier onlyTeam() {
        require(registry.isCallerTeam(_msgSender()), "Forbidden: Only Team");
        _;
    }

    modifier onlyProtocol() {
        require(
            registry.isCallerProtocol(_msgSender()),
            "Forbidden: Only Protocol"
        );
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
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
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

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

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
		address _wagerToken,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payoutNoEscrow(
		address _wagerAsset,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payin(
		address _inputToken, 
		address _escrowAddress,
		uint256 _escrowAmount) external;

	function setAsideReferral(address _token, uint256 _amount) external;

	function payinWagerFee(
		address _tokenIn
	) external;

	function payinSwapFee(
		address _tokenIn
	) external;

	function payinPoolProfits(
		address _tokenIn
	) external;

	function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;

	function setFeeCollector(address _feeCollector) external;

	function upgradeVault(
		address _newVault,
		address _token,
		uint256 _amount,
		bool _upgrade
	) external;

	function setCircuitBreakerAmount(address _token, uint256 _amount) external;

	function clearTokenConfig(address _token) external;

	function updateTokenBalance(address _token) external;

	function setCircuitBreakerEnabled(bool _setting) external;

	function setPoolBalance(address _token, uint256 _amount) external;
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
pragma solidity 0.8.19;

import "../interfaces/core/IVault.sol";
import "../core/AccessControlBase.sol";

contract FeeStrategy is AccessControlBase {
	/*==================================================== Events =============================================================*/

	event FeeMultiplierChanged(uint256 multiplier);

	event ConfigUpdated(uint256 maxMultiplier, uint256 minMultiplier);

	event PeriodChangeRate(uint256 periodChangeRate, bool isProfit);

	/*==================================================== State Variables ====================================================*/

	struct Config {
		uint256 minMultiplier;
		uint256 maxMultiplier;
	}

	struct LastDayReserves {
		uint256 profit;
		uint256 loss;
	}

	Config public config = Config(7_500_000_000_000_000, 12_500_000_000_000_000);

	/// @notice Last calculated multipliers index id
	uint256 public lastCalculatedIndex = 0;
	/// @notice Start time of periods
	uint256 public immutable periodStartTime = block.timestamp - 1 days;
	/// @notice Last calculated multiplier
	uint256 public currentMultiplier;
	/// @notice Vault address
	IVault public vault;
	/// @notice stores the profit and loss of the last day for each token
	mapping(address => LastDayReserves) public lastDayReserves;

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
	 * @param _config max, min multipliers
	 * @notice funtion to set new max min multipliers config
	 */
	function updateConfig(Config memory _config) public onlyGovernance {
		require(_config.maxMultiplier != 0, "Max zero");
		require(_config.minMultiplier != 0, "Min zero");
		require(_config.minMultiplier < _config.maxMultiplier, "Min greater than max");

		config.maxMultiplier = _config.maxMultiplier;
		config.minMultiplier = _config.minMultiplier;

		emit ConfigUpdated(_config.maxMultiplier, _config.minMultiplier);
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
	 * @param _wagerFee wager fee percentage in 1e18
	 * @notice function to set wager fee to vault for a given day
	 */
	function _setWagerFee(uint256 _wagerFee) internal {
		currentMultiplier = _wagerFee;
		vault.setWagerFee(_wagerFee);
		emit FeeMultiplierChanged(currentMultiplier);
	}

	/**
	 * @dev Public function to calculate the dollar value of a given token amount.
	 * @param _token The address of the whitelisted token on the vault.
	 * @param _amount The amount of the given token.
	 * @return dollarValue_ The dollar value of the given token amount.
	 * @notice This function takes the address of a whitelisted token on the vault and an amount of that token,
	 *  and calculates the dollar value of that amount by multiplying the amount by the current dollar value of the token
	 *  on the vault and dividing by 10^decimals of the token. The result is then divided by 1e12 to convert to USD.
	 */
	function computeDollarValue(
		address _token,
		uint256 _amount
	) public view returns (uint256 dollarValue_) {
		uint256 decimals_ = vault.tokenDecimals(_token); // Get the decimals of the token using the Vault interface
		dollarValue_ = ((_amount * vault.getMinPrice(_token)) / 10 ** decimals_); // Calculate the dollar value by multiplying the amount by the current dollar value of the token on the vault and dividing by 10^decimals
		dollarValue_ = dollarValue_ / 1e12; // Convert the result to USD by dividing by 1e12
	}

	/**
	 * @dev Public function to get the current period index.
	 * @return periodIndex_ index of the day
	 */
	function getPeriodIndex() public view returns (uint256 periodIndex_) {
		periodIndex_ = (block.timestamp - periodStartTime) / 1 days;
	}

	function _setLastDayReserves() internal {
		// Get the length of the allWhitelistedTokens array
		uint256 allWhitelistedTokensLength_ = vault.allWhitelistedTokensLength();

		// Iterate over all whitelisted tokens in the vault
		for (uint256 i = 0; i < allWhitelistedTokensLength_; i++) {
			address token_ = vault.allWhitelistedTokens(i); // Get the address of the current token
			(uint256 loss_, uint256 profit_) = vault.returnTotalOutAndIn(token_);
			// Store the previous day's profit and loss for the current token
			lastDayReserves[token_] = LastDayReserves(profit_, loss_);
		}
	}

	/**
	 *
	 * @dev Calculates the change in dollar value of the vault's reserves and the last day's P&L.
	 * @return change_ The change in dollar value of the vault's reserves.
	 * @return lastDayPnl_ The last day's profit and loss.
	 */
	function _getChange() internal returns (int256 change_, int256 lastDayPnl_) {
		uint256 allWhitelistedTokensLength_ = vault.allWhitelistedTokensLength();

		// Create a LastDayReserves struct to store the previous day's reserve data
		LastDayReserves[] memory lastDayReserves_ = new LastDayReserves[](allWhitelistedTokensLength_);
		// Iterate over all whitelisted tokens in the vault
		for (uint256 i = 0; i < allWhitelistedTokensLength_; i++) {
			address token_ = vault.allWhitelistedTokens(i); // Get the address of the current token
			// Get the previous day's profit and loss for the current token
			lastDayReserves_[i] = lastDayReserves[token_];
			// Calculate the previous day's profit and loss in USD
			uint256 lastDayProfit = computeDollarValue(
				token_,
				lastDayReserves_[i].profit
			);
			uint256 lastDayLoss = computeDollarValue(
				token_,
				lastDayReserves_[i].loss
			);
			// Add the previous day's profit and loss to the last day's P&L
			lastDayPnl_ += int256(lastDayProfit) - int256(lastDayLoss);
		}

		_setLastDayReserves();

		for (uint256 i = 0; i < allWhitelistedTokensLength_; i++) {
			address token_ = vault.allWhitelistedTokens(i); // Get the address of the current token
			// Calculate the current day's profit and loss in USD
			uint256 profit_ = lastDayReserves[token_].profit - lastDayReserves_[i].profit;
			uint256 loss_ = lastDayReserves[token_].loss - lastDayReserves_[i].loss;

			uint256 profitInDollar_ = computeDollarValue(token_, profit_);
			uint256 lossInDollar_ = computeDollarValue(token_, loss_);

			// Add the current day's profit and loss to the change in reserves
			change_ += int256(profitInDollar_) - int256(lossInDollar_);
		}
	}

	function _getMultiplier() internal returns (uint256) {
		// Get the current period index
		uint256 index_ = getPeriodIndex();

		// If the current period index is the same as the last calculated index, return the current multiplier
		// This is to prevent the multiplier from being calculated multiple times in the same period
		if (index_ == lastCalculatedIndex) {
			return currentMultiplier;
		}

		// Get the change in reserves and the last day's P&L
		(int256 change_, int256 lastDayPnl_) = _getChange();

		// If the current period index is 0 or 1, return the max multiplier
		if (index_ <= 1) {
			// set the last calculated index to the current period index
			lastCalculatedIndex = index_;
            uint256 initialMultiplier_ = config.maxMultiplier;
			// Set the wager fee for the current period index and current multiplier
			_setWagerFee(initialMultiplier_);
            // Return the current multiplier
			return initialMultiplier_;
		}

		// If the last day's P&L is 0, return the current multiplier
		if (lastDayPnl_ == 0) {
			lastCalculatedIndex = index_;
			return currentMultiplier;
		}

		// Calculate the period change rate based on the change in reserves and the last day's P&L
		uint256 periodChangeRate_ = (absoluteValue(change_) * PRECISION) /
			absoluteValue(lastDayPnl_);

		// If the difference in reserves represents a loss, decrease the current multiplier accordingly
		if (change_ < 0) {
			uint256 decrease_ = (2 * (currentMultiplier * periodChangeRate_)) / PRECISION;
			currentMultiplier = currentMultiplier > decrease_
				? currentMultiplier - decrease_
				: config.minMultiplier;
		}
		// Otherwise, increase the current multiplier according to the period change rate
		else if (periodChangeRate_ != 0) {
			currentMultiplier =
				(currentMultiplier * (1e18 + periodChangeRate_)) /
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

		// Update the last calculated index to the current period index
		lastCalculatedIndex = index_;

		// Set the wager fee for the current period index and current multiplier
		_setWagerFee(currentMultiplier);
		// Emit the period change rate and whether the change in reserves represents a profit or loss
		bool isProfit_ = change_ > 0;

		 emit PeriodChangeRate(periodChangeRate_, isProfit_);
		// Return the current multiplier
		return currentMultiplier;
	}

	/**
	 * @param _token address of the input (wl) token
	 * @param _amount amount of the token
	 * @notice function to calculation with current multiplier
	 */
	function calculate(address _token, uint256 _amount) external onlyProtocol returns (uint256 amount_) {
		uint256 value_ = computeDollarValue(_token, _amount);
		amount_ = (value_ * _getMultiplier()) / PRECISION;
	}

	/**
	 *
	 * @param _num The number to get the absolute value of
	 * @dev Returns the absolute value of a number
	 */
	function absoluteValue(int _num) public pure returns (uint) {
		if (_num < 0) {
			return uint(-1 * _num);
		} else {
			return uint(_num);
		}
	}
}