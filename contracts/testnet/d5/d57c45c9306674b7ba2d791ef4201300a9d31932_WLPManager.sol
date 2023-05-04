// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IFeeCollector.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/tokens/wlp/IUSDW.sol";
import "../interfaces/tokens/wlp/IMintable.sol";
import "./AccessControlBase.sol";

contract WLPManager is ReentrancyGuard, AccessControlBase, IWLPManager {
	/*==================== Constants *====================*/
	uint128 private constant PRICE_PRECISION = 1e30;
	uint32 private constant USDW_DECIMALS = 18;
	uint64 private constant WLP_PRECISION = 1e18;
	uint64 private constant MAX_COOLDOWN_DURATION = 48 hours;

	/*==================== State Variabes Operations *====================*/
	IVault public immutable override vault;
	address public immutable override usdw;
	address public immutable override wlp;
	address public feeCollector;
	uint256 public override cooldownDuration;
	uint256 public aumAddition;
	uint256 public aumDeduction;
	uint256 public reserveDeduction;

	// Percentages configuration
	uint256 public override maxPercentageOfWagerFee = 2000;
	uint256 public reserveDeductionOnCB = 5000; // 50% of AUM when CB is triggered

	bool public handlersEnabled = false;
	bool public collectFeesOnLiquidityEvent = false;
	bool public inPrivateMode = false;

	// Vault circuit breaker config
	bool public pausePayoutsOnCB = false;
	bool public pauseSwapOnCB = false;
	bool private circuitBreakerActive = false;

	mapping(address => uint256) public override lastAddedAt;
	mapping(address => bool) public isHandler;

	constructor(
		address _vault,
		address _usdw,
		address _wlp,
		uint256 _cooldownDuration,
		address _vaultRegistry,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) {
		vault = IVault(_vault);
		usdw = _usdw;
		wlp = _wlp;
		cooldownDuration = _cooldownDuration;
	}

	/*==================== Configuration functions *====================*/

	/**
	 * @notice when private mode is enabled, minting and redemption of WLP is not possible (it is disabled) - only exception is that if handlersEnabled is true, whitelisted handlers are able to mint and redeem WLP on behalf of others.
	 * @param _inPrivateMode bool to set private mdoe
	 */
	function setInPrivateMode(bool _inPrivateMode) external onlyTeam {
		inPrivateMode = _inPrivateMode;
		emit PrivateModeSet(_inPrivateMode);
	}

	function setHandlerEnabled(bool _setting) external onlyTimelockGovernance {
		handlersEnabled = _setting;
		emit HandlerEnabling(_setting);
	}

	/**
	 * @dev since this function could 'steal' assets of LPs that do not agree with the action, it has a timelock on it
	 * @param _handler address of the handler that will be allowed to handle the WLPs wlp on their behalf
	 * @param _isActive bool setting (true adds a handlerAddress, false removes a handlerAddress)
	 */
	function setHandler(address _handler, bool _isActive) external onlyTimelockGovernance {
		isHandler[_handler] = _isActive;
		emit HandlerSet(_handler, _isActive);
	}

	/**
	 * @notice configuration function to set the max percentage of the wagerfees collected the referral can represent
	 * @dev this mechanism is in place as a backstop for a potential exploit of the referral mechanism
	 * @param _maxPercentageOfWagerFee configure value for the max percentage of the wagerfee
	 */
	function setMaxPercentageOfWagerFee(
		uint256 _maxPercentageOfWagerFee
	) external onlyTeam {
		maxPercentageOfWagerFee = _maxPercentageOfWagerFee;
		emit MaxPercentageOfWagerFeeSet(_maxPercentageOfWagerFee);
	}

	/**
	 * @notice the cooldown durations sets a certain amount of seconds cooldown after a lp withdraw until a neext withdraw is able to be conducted
	 * @param _cooldownDuration amount of seconds for the cooldown
	 */
	function setCooldownDuration(uint256 _cooldownDuration) external override onlyTeam {
		require(
			_cooldownDuration <= MAX_COOLDOWN_DURATION,
			"WLPManager: invalid _cooldownDuration"
		);
		cooldownDuration = _cooldownDuration;
		emit CoolDownDurationSet(_cooldownDuration);
	}

	/**
	 * @notice configuration confuction to set a AUM adjustment, this is useful for if due to some reason the calculation is wrong and needs to be corrected
	 * @param _aumAddition amount the calulated aum should be increased
	 * @param _aumDeduction amount the calculated aum should be decreased
	 */
	function setAumAdjustment(
		uint256 _aumAddition,
		uint256 _aumDeduction
	) external onlyTeam {
		aumAddition = _aumAddition;
		aumDeduction = _aumDeduction;
		emit AumAdjustmentSet(_aumAddition, _aumDeduction);
	}

	/*==================== Operational functions WINR/JB *====================*/

	/**
	 * @notice the function that can mint WLP/ add liquidity to the vault
	 * @dev this function mints WLP to the msg sender, also this will mint USDW to this contract
	 * @param _token the address of the token being deposited as LP
	 * @param _amount the amount of the token being deposited
	 * @param _minUsdw the minimum USDW the callers wants his deposit to be valued at
	 * @param _minWlp the minimum amount of WLP the callers wants to receive
	 * @return wlpAmount_ returns the amount of WLP that was minted to the _account
	 */
	function addLiquidity(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external override nonReentrant returns (uint256 wlpAmount_) {
		if (inPrivateMode) {
			revert("WLPManager: action not enabled");
		}
		wlpAmount_ = _addLiquidity(
			_msgSender(),
			_msgSender(),
			_token,
			_amount,
			_minUsdw,
			_minWlp,
			false
		);
	}

	/**
	 * @notice the function that can mint WLP/ add liquidity to the vault (for a handler)
	 * @param _fundingAccount the address that will source the tokens to de deposited
	 * @param _account the address that will receive the WLP
	 * @param _token the address of the token being deposited as LP
	 * @param _amount the amount of the token being deposited
	 * @param _minUsdw the minimum USDW the callers wants his deposit to be valued at
	 * @param _minWlp the minimum amount of WLP the callers wants to receive
	 * @return wlpAmount_ returns the amount of WLP that was minted to the _account
	 */
	function addLiquidityForAccount(
		address _fundingAccount,
		address _account,
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external override nonReentrant returns (uint256 wlpAmount_) {
		_validateHandler();
		wlpAmount_ = _addLiquidity(
			_fundingAccount,
			_account,
			_token,
			_amount,
			_minUsdw,
			_minWlp,
			false
		);
	}

	/**
	 * @param _tokenOut address of the token the redeemer wants to receive
	 * @param _wlpAmount  amount of wlp tokens to be redeemed for _tokenOut
	 * @param _minOut minimum amount of _tokenOut the redemeer wants to receive
	 * @param _receiver  address that will reive the _tokenOut assets
	 * @return tokenOutAmount_ uint256 amount of the tokenOut the caller receives (for their burned WLP)
	 */
	function removeLiquidity(
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external override nonReentrant returns (uint256 tokenOutAmount_) {
		if (inPrivateMode) {
			revert("WLPManager: action not enabled");
		}
		tokenOutAmount_ = _removeLiquidity(
			_msgSender(),
			_tokenOut,
			_wlpAmount,
			_minOut,
			_receiver
		);
	}

	/**
	 * @notice handler remove liquidity function - redeems WLP for selected asset
	 * @param _account  the address that will source the WLP  tokens
	 * @param _tokenOut address of the token the redeemer wants to receive
	 * @param _wlpAmount  amount of wlp tokens to be redeemed for _tokenOut
	 * @param _minOut minimum amount of _tokenOut the redemeer wants to receive
	 * @param _receiver  address that will reive the _tokenOut assets
	 * @return tokenOutAmount_ uint256 amount of the tokenOut the caller receives
	 */
	function removeLiquidityForAccount(
		address _account,
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external override nonReentrant returns (uint256 tokenOutAmount_) {
		_validateHandler();
		tokenOutAmount_ = _removeLiquidity(
			_account,
			_tokenOut,
			_wlpAmount,
			_minOut,
			_receiver
		);
	}

	/**
	 * @notice the circuit breaker configuration
	 * @param _pausePayoutsOnCB bool to set if the cb should pause payouts the vault in case of a circuit breaker level trigger
	 * @param _pauseSwapOnCB bool to set if the cb should pause the entire protocol in case of a circuit breaker trigger
	 * @param _reserveDeductionOnCB percentage amount deduction config for the cb to reduce max wager amount after a cb trigger
	 */
	function setCiruitBreakerPolicy(
		bool _pausePayoutsOnCB,
		bool _pauseSwapOnCB,
		uint256 _reserveDeductionOnCB
	) external onlyTeam {
		pausePayoutsOnCB = _pausePayoutsOnCB;
		pauseSwapOnCB = _pauseSwapOnCB;
		reserveDeductionOnCB = _reserveDeductionOnCB;
		emit CircuitBreakerPolicy(pausePayoutsOnCB, pauseSwapOnCB, reserveDeductionOnCB);
	}

	/**
	 * @notice function called by the vault when the circuit breaker is triggered (poolAmount under configured minimum)
	 * @param _token the address of the token that triggered the Circuit Breaker in the vault
	 */
	function circuitBreakerTrigger(address _token) external {
		if (circuitBreakerActive) {
			// circuit breaker is already active, so we return to vault
			return;
		}
		require(
			_msgSender() == address(vault),
			"WLPManager: only vault can trigger circuit break"
		);
		circuitBreakerActive = true;
		// execute the circuit breaker policy for payouts
		vault.setPayoutHalted(pausePayoutsOnCB);
		// execute the circuit breaker policy for external swaps
		vault.setIsSwapEnabled(pauseSwapOnCB);
		// if AUM deduction is set, we will lower the AUM by the configured percentage
		// a lower AUM will also mean a lower max
		if (reserveDeductionOnCB != 0) {
			// get the current AUM (without any deductions)
			uint256 aum_ = getAum(true);
			// caculate the deduction percentage, so if AUM is 2M and the deduction is 50%, we will deduct 1M
			reserveDeduction = (aum_ * reserveDeductionOnCB) / 10000;
			// with the deduction of the circuit breaker we will not lower the WLP, but we will lower the getReserves() function in the vault
			// this getReseres() function is used to calculate the max wager amount. Thus the trigger of the circuit breaker can drastically lower the max wager!
			// of course the policy of deducting the maxWager only makes sense if the payouts are not paused. If payouts are paused by the circuit breaker no wager can be made anyway.
		}
		emit CircuitBreakerTriggered(
			_token,
			pausePayoutsOnCB,
			pauseSwapOnCB,
			reserveDeductionOnCB
		);
	}

	/**
	 * @notice functuion that undoes/resets the circuitbreaker
	 */
	function resetCircuitBreaker() external onlyTeam {
		circuitBreakerActive = false;
		vault.setPayoutHalted(false);
		vault.setIsSwapEnabled(true);
		reserveDeduction = 0;
		emit CircuitBreakerReset(pausePayoutsOnCB, pauseSwapOnCB, reserveDeductionOnCB);
	}

	/*==================== View functions WINR/JB *====================*/

	/**
	 * @notice returns the value of 1 wlp token in USD (scaled 1e30)
	 * @param _maximise when true, the assets maxPrice will be used (upper bound), when false lower bound will be used
	 * @return tokenPrice_ returns price of a single WLP token
	 */
	function getPriceWlp(bool _maximise) external view returns (uint256 tokenPrice_) {
		uint256 supply_ = IERC20(wlp).totalSupply();
		if (supply_ == 0) {
			return 0;
		}
		tokenPrice_ = ((getAum(_maximise) * WLP_PRECISION) / supply_);
	}

	/**
	 * @notice returns the WLP price of 1 WLP token denominated in USDW (so in 1e18, $1 = 1e18)
	 * @param _maximise when true, the assets maxPrice will be used (upper bound), when false lower bound will be used
	 */
	function getPriceWLPInUsdw(bool _maximise) external view returns (uint256 tokenPrice_) {
		uint256 supply_ = IERC20(wlp).totalSupply();
		if (supply_ == 0) {
			return 0;
		}
		tokenPrice_ = ((getAumInUsdw(_maximise) * WLP_PRECISION) / supply_);
	}

	/**
	 * @notice function that returns the total vault AUM in USDW
	 * @param _maximise bool signifying if the maxPrices of the tokens need to be used
	 * @return aumUSDW_ the amount of aum denomnated in USDW tokens
	 * @dev the USDW tokens are 1e18 scaled, not 1e30 as the USD value is represented
	 */
	function getAumInUsdw(bool _maximise) public view override returns (uint256 aumUSDW_) {
		aumUSDW_ = (getAum(_maximise) * (10 ** USDW_DECIMALS)) / PRICE_PRECISION;
	}

	/**
	 * @notice returns the total value of all the assets in the WLP/Vault
	 * @dev the USD value is scaled in 1e30, not 1e18, so $1 = 1e30
	 * @return aumAmountsUSD_ array with minimised and maximised AU<
	 */
	function getAums() external view returns (uint256[] memory aumAmountsUSD_) {
		aumAmountsUSD_ = new uint256[](2);
		aumAmountsUSD_[0] = getAum(true /** use upper bound oracle price for assets */);
		aumAmountsUSD_[1] = getAum(false /** use lower bound oracle price for assets */);
	}

	/**
	 * @notice returns the total amount of AUM of the vault
	 * @dev take note that 1 USD is 1e30, this function returns the AUM in this format
	 * @param _maximise bool indicating if the max price need to be used for the aum calculation
	 * @return aumUSD_ the total aum (in USD) of all the whtielisted assets in the vault
	 */
	function getAum(bool _maximise) public view returns (uint256 aumUSD_) {
		IVault _vault = vault;
		uint256 length_ = _vault.allWhitelistedTokensLength();
		uint256 aum_ = aumAddition;
		for (uint256 i = 0; i < length_; ++i) {
			address token_ = _vault.allWhitelistedTokens(i);
			// if token is not whitelisted, don't count it to the AUM
			uint256 price_ = _maximise
				? _vault.getMaxPrice(token_)
				: _vault.getMinPrice(token_);
			aum_ += ((_vault.poolAmounts(token_) * price_) /
				(10 ** _vault.tokenDecimals(token_)));
		}
		uint256 aumD_ = aumDeduction;
		aumUSD_ = aumD_ > aum_ ? 0 : (aum_ - aumD_);
	}

	/*==================== Internal functions WINR/JB *====================*/

	/**
	 * @notice function used by feecollector to mint WLP tokens
	 * @dev this function is only active when
	 * @param _token address of the token the WLP will be minted for
	 * @param _amount amount of tokens to be added to the vault pool
	 * @param _minUsdw minimum amount of USDW tokens to be received
	 * @param _minWlp minimum amount of WLP tokens to be received
	 */
	function addLiquidityFeeCollector(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256 wlpAmount_) {
		require(
			_msgSender() == feeCollector,
			"WLP: only fee collector can call this function"
		);
		wlpAmount_ = _addLiquidity(
			_msgSender(),
			_msgSender(),
			_token,
			_amount,
			_minUsdw,
			_minWlp,
			true
		);
	}

	/**
	 * @param _feeCollector address of the fee collector
	 */
	function setFeeCollector(address _feeCollector) external onlyTimelockGovernance {
		feeCollector = _feeCollector;
	}

	/**
	 * @notice config function to enable or disable the collection of wlp fees on liquidity events (mint and burning)
	 * @dev this mechnism is in place to the sandwiching of the distribution of wlp fees
	 * @param _collectFeesOnLiquidityEvent bool set to true to enable the collection of fees on liquidity events
	 */
	function setCollectFeesOnLiquidityEvent(
		bool _collectFeesOnLiquidityEvent
	) external onlyTeam {
		collectFeesOnLiquidityEvent = _collectFeesOnLiquidityEvent;
	}

	/**
	 * @notice internal funciton that collects fees before a liquidity event
	 */
	function _collectFees() internal {
		// note: in the process of collecting fees and converting it into wlp the protocol 'by design' re-enters the WLPManager contract
		IFeeCollector(feeCollector).collectFeesBeforeLPEvent();
	}

	/**
	 * @notice internal function that calls the deposit function in the vault
	 * @dev calling this function requires an approval by the _funding account
	 * @param _fundingAccount address of the account sourcing the
	 * @param _account address that will receive the newly minted WLP tokens
	 * @param _tokenDeposit address of the token being deposited into the vault
	 * @param _amountDeposit amiunt of _tokenDeposit the caller is adding as liquiditty
	 * @param _minUsdw minimum amount of USDW the caller wants their deposited tokens to be worth
	 * @param _minWlp minimum amount of WLP the caller wants to receive
	 * @return mintAmountWLP_ amount of WLP tokens minted
	 */
	function _addLiquidity(
		address _fundingAccount,
		address _account,
		address _tokenDeposit,
		uint256 _amountDeposit,
		uint256 _minUsdw,
		uint256 _minWlp,
		bool _swapLess
	) private returns (uint256 mintAmountWLP_) {
		require(_amountDeposit != 0, "WLPManager: invalid _amount");
		if (collectFeesOnLiquidityEvent) {
			// prevent reentrancy looping if the wlp collection on mint/deposit is enabled
			collectFeesOnLiquidityEvent = false;
			// collect fees from vault and distribute to WLP holders (to prevent frontrunning of WLP feecollection)
			_collectFees();
			// set the configuration back to true, so that it
			collectFeesOnLiquidityEvent = true;
		}
		// cache address to save on SLOADs
		address wlp_ = wlp;
		// calculate aum before buyUSDW
		uint256 aumInUsdw_ = getAumInUsdw(true /**  get AUM using upper bound prices */);
		uint256 wlpSupply_ = IERC20(wlp_).totalSupply();

		// mechanism in place to prevent manipulation of wlp price by the first wlp minter
		bool firstMint_;
		if (wlpSupply_ == 0) {
			firstMint_ = true;
			// first mint must issue more than 10 WLP to ensure WLP pricing precision
			require((_minWlp >= 1e18), "WLPManager: too low WLP amount for first mint");
		}

		// transfer the tokens to the vault, from the user/source (_fundingAccount). note this requires an approval from the source address
		SafeERC20.safeTransferFrom(
			IERC20(_tokenDeposit),
			_fundingAccount,
			address(vault),
			_amountDeposit
		);
		// call the deposit function in the vault (external call)
		uint256 usdwAmount_ = vault.deposit(
			_tokenDeposit, // the token that is being deposited into the vault for WLP
			address(this), // the address that will receive the USDW tokens (minted by the vault)
			_swapLess
		);
		// the vault has minted USDW to this contract (WLP Manager), the amount of USDW minted is equivalent to the value of the deposited tokens (in USD, scaled 1e18) now this WLP Manager contract has received usdw, 1e18 usdw is 1 USD 'debt'. If the caller has provided tokens worth $10k, then about 1e5 * 1e18 USDW will be minted. This ratio of value deposited vs amount of USDW minted will remain the same.

		// check if the amount of usdwAmount_ fits the expectation of the caller
		require(usdwAmount_ >= _minUsdw, "WLPManager: insufficient USDW output");
		/**
		 * Initially depositing 1 USD will result in 1 WLP, however as the value of the WLP grows (so historically the WLP LPs are in profit), a 1 USD deposit will result in less WLP, this because new LPs do not have the right to 'cash in' on the WLP profits that where earned bedore the LP entered the vault. The calculation below determines how much WLP will be minted for the amount of USDW deposited.
		 */
		mintAmountWLP_ = aumInUsdw_ == 0
			? usdwAmount_
			: ((usdwAmount_ * wlpSupply_) / aumInUsdw_);
		require(mintAmountWLP_ >= _minWlp, "WLPManager: insufficient WLP output");

		// only on the first mint 1 WLP will be sent to the timelock
		if (firstMint_) {
			mintAmountWLP_ -= 1e18;
			// mint 1 WLP to the timelock address to prevent any attack possible
			IMintable(wlp_).mint(timelockAddressImmutable, 1e18);
		}

		// wlp is minted to the _account address
		IMintable(wlp_).mint(_account, mintAmountWLP_);
		lastAddedAt[_account] = block.timestamp;
		emit AddLiquidity(
			_account,
			_tokenDeposit,
			_amountDeposit,
			aumInUsdw_,
			wlpSupply_,
			usdwAmount_,
			mintAmountWLP_
		);
		return mintAmountWLP_;
	}

	/**
	 * @notice internal function that withdraws assets from the vault
	 * @dev burns WLP, burns usdw, transfers tokenOut from the vault to the caller
	 * @param _account the addresss that wants to redeem its WLP from
	 * @param _tokenOut address of the token that the redeemer wants to receive for their wlp
	 * @param _wlpAmount the amount of WLP that is being redeemed
	 * @param _minOut the minimum amount of tokenOut the redeemer/remover wants to receive
	 * @param _receiver address the redeemer wants to receive the tokenOut on
	 * @return amountOutToken_ amount of the token redeemed from the vault
	 */
	function _removeLiquidity(
		address _account,
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) private returns (uint256 amountOutToken_) {
		require(_wlpAmount != 0, "WLPManager: invalid _wlpAmount");
		// check if there is a cooldown period
		require(
			(lastAddedAt[_account] + cooldownDuration) <= block.timestamp,
			"WLPManager: cooldown duration not yet passed"
		);
		// calculate how much the lower bound priced value is of all the assets in the WLP
		uint256 aumInUsdw_ = getAumInUsdw(false);
		// cache wlp address to save on SLOAD
		address wlp_ = wlp;
		// fetch how much WLP tokens are minted/outstanding
		uint256 wlpSupply_ = IERC20(wlp_).totalSupply();
		// when liquidity is removed, usdw needs to be burned, since the usdw token is an accounting token for debt (it is the value of the token when it was deposited, or transferred to the vault via a swap)
		uint256 usdwAmountToBurn_ = (_wlpAmount * aumInUsdw_) / wlpSupply_;
		// calculate how much USDW debt there is in total
		// cache address to save on SLOAD
		address usdw_ = usdw;
		uint256 usdwBalance_ = IERC20(usdw_).balanceOf(address(this));
		// check if there are enough USDW tokens to burn
		if (usdwAmountToBurn_ > usdwBalance_) {
			// auditor note: this situation, where usdw token need to be minted without actual tokens being deposited, can only occur when there are almost no WLPs left and the vault in general. Another requirement for this to occur is that the prices of assets in the vault are (far) lower at the time of withdrawal relative ti the time they where originally added to the vault.
			IUSDW(usdw_).mint(address(this), usdwAmountToBurn_ - usdwBalance_);
		}
		// burn the WLP token in the wallet of the LP remover, will fail if the _account doesn't have the WLP tokens in their wallet
		IMintable(wlp_).burn(_account, _wlpAmount);
		// usdw is transferred to the vault (where it will be burned)
		IERC20(usdw_).transfer(address(vault), usdwAmountToBurn_);
		// call the vault for the second step of the withdraw flow
		amountOutToken_ = vault.withdraw(_tokenOut, _receiver);
		// check if the amount of tokenOut the vault has returend fits the requirements of the caller
		require(amountOutToken_ >= _minOut, "WLPManager: insufficient output");
		emit RemoveLiquidity(
			_account,
			_tokenOut,
			_wlpAmount,
			aumInUsdw_,
			wlpSupply_,
			usdwAmountToBurn_,
			amountOutToken_
		);
		return amountOutToken_;
	}

	function _validateHandler() private view {
		require(handlersEnabled, "WLPManager: handlers not enabled");
		require(isHandler[_msgSender()], "WLPManager: forbidden");
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollector {
	struct SwapDistributionRatio {
		uint64 wlpHolders;
		uint64 staking;
		uint64 buybackAndBurn;
		uint64 core;
	}

	struct WagerDistributionRatio {
		uint64 staking;
		uint64 buybackAndBurn;
		uint64 core;
	}

	struct Reserve {
		uint256 wlpHolders;
		uint256 staking;
		uint256 buybackAndBurn;
		uint256 core;
	}

	// *** Destination addresses for the farmed fees from the vault *** //
	// note: the 4 addresses below need to be able to receive ERC20 tokens
	struct DistributionAddresses {
		// the destination address for the collected fees attributed to WLP holders
		address wlpClaim;
		// the destination address for the collected fees attributed  to WINR stakers
		address winrStaking;
		// address of the contract that does the 'buyback and burn'
		address buybackAndBurn;
		// the destination address for the collected fees attributed to core development
		address core;
		// address of the contract/EOA that will distribute the referral fees
		address referral;
	}

	struct DistributionTimes {
		uint256 wlpClaim;
		uint256 winrStaking;
		uint256 buybackAndBurn;
		uint256 core;
		uint256 referral;
	}

	function getReserves() external returns (Reserve memory);

	function getSwapDistribution() external returns (SwapDistributionRatio memory);

	function getWagerDistribution() external returns (WagerDistributionRatio memory);

	function getAddresses() external returns (DistributionAddresses memory);

	function calculateDistribution(
		uint256 _amountToDistribute,
		uint64 _ratio
	) external pure returns (uint256 amount_);

	function withdrawFeesAll() external;

	function isWhitelistedDestination(address _address) external returns (bool);

	function syncWhitelistedTokens() external;

	function addToWhitelist(address _toWhitelistAddress, bool _setting) external;

	function setReferralDistributor(address _distributorAddress) external;

	function setCoreDevelopment(address _coreDevelopment) external;

	function setWinrStakingContract(address _winrStakingContract) external;

	function setBuyBackAndBurnContract(address _buybackAndBurnContract) external;

	function setWlpClaimContract(address _wlpClaimContract) external;

	function setWagerDistribution(
		uint64 _stakingRatio,
		uint64 _burnRatio,
		uint64 _coreRatio
	) external;

	function setSwapDistribution(
		uint64 _wlpHoldersRatio,
		uint64 _stakingRatio,
		uint64 _buybackRatio,
		uint64 _coreRatio
	) external;

	function addTokenToWhitelistList(address _tokenToAdd) external;

	function deleteWhitelistTokenList() external;

	function collectFeesBeforeLPEvent() external;

	/*==================== Events *====================*/
	event DistributionSync();
	event WithdrawSync();
	event WhitelistEdit(address whitelistAddress, bool setting);
	event EmergencyWithdraw(address caller, address token, uint256 amount, address destination);
	event ManualGovernanceDistro();
	event FeesDistributed();
	event WagerFeesManuallyFarmed(address tokenAddress, uint256 amountFarmed);
	event ManualDistributionManager(
		address targetToken,
		uint256 amountToken,
		address destinationAddress
	);
	event SetRewardInterval(uint256 timeInterval);
	event SetCoreDestination(address newDestination);
	event SetBuybackAndBurnDestination(address newDestination);
	event SetClaimDestination(address newDestination);
	event SetReferralDestination(address referralDestination);
	event SetStakingDestination(address newDestination);
	event SwapFeesManuallyFarmed(address tokenAddress, uint256 totalAmountCollected);
	event CollectedWagerFees(address tokenAddress, uint256 amountCollected);
	event CollectedSwapFees(address tokenAddress, uint256 amountCollected);
	event NothingToDistribute(address token);
	event DistributionComplete(
		address token,
		uint256 toWLP,
		uint256 toStakers,
		uint256 toBuyBack,
		uint256 toCore,
		uint256 toReferral
	);
	event WagerDistributionSet(uint64 stakingRatio, uint64 burnRatio, uint64 coreRatio);
	event SwapDistributionSet(
		uint64 _wlpHoldersRatio,
		uint64 _stakingRatio,
		uint64 _buybackRatio,
		uint64 _coreRatio
	);
	event SyncTokens();
	event DeleteAllWhitelistedTokens();
	event TokenAddedToWhitelist(address addedTokenAddress);
	event TokenTransferredByTimelock(address token, address recipient, uint256 amount);

	event ManualFeeWithdraw(
		address token,
		uint256 swapFeesCollected,
		uint256 wagerFeesCollected,
		uint256 referralFeesCollected
	);

	event TransferBuybackAndBurnTokens(address receiver, uint256 amount);
	event TransferCoreTokens(address receiver, uint256 amount);
	event TransferWLPRewardTokens(address receiver, uint256 amount);
	event TransferWinrStakingTokens(address receiver, uint256 amount);
	event TransferReferralTokens(address token, address receiver, uint256 amount);
	event VaultUpdated(address vault);
	event WLPManagerUpdated(address wlpManager);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

interface IWLPManager {
	function wlp() external view returns (address);

	function usdw() external view returns (address);

	function vault() external view returns (IVault);

	function cooldownDuration() external returns (uint256);

	function getAumInUsdw(bool maximise) external view returns (uint256);

	function lastAddedAt(address _account) external returns (uint256);

	function addLiquidity(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256);

	function addLiquidityForAccount(
		address _fundingAccount,
		address _account,
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256);

	function removeLiquidity(
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);

	function removeLiquidityForAccount(
		address _account,
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);

	function setCooldownDuration(uint256 _cooldownDuration) external;

	function getAum(bool _maximise) external view returns (uint256);

	function getPriceWlp(bool _maximise) external view returns (uint256);

	function getPriceWLPInUsdw(bool _maximise) external view returns (uint256);

	function circuitBreakerTrigger(address _token) external;

	function aumDeduction() external view returns (uint256);

	function reserveDeduction() external view returns (uint256);

	function maxPercentageOfWagerFee() external view returns (uint256);

	function addLiquidityFeeCollector(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256 wlpAmount_);

	/*==================== Events *====================*/
	event AddLiquidity(
		address account,
		address token,
		uint256 amount,
		uint256 aumInUsdw,
		uint256 wlpSupply,
		uint256 usdwAmount,
		uint256 mintAmount
	);

	event RemoveLiquidity(
		address account,
		address token,
		uint256 wlpAmount,
		uint256 aumInUsdw,
		uint256 wlpSupply,
		uint256 usdwAmount,
		uint256 amountOut
	);

	event PrivateModeSet(bool inPrivateMode);

	event HandlerEnabling(bool setting);

	event HandlerSet(address handlerAddress, bool isActive);

	event CoolDownDurationSet(uint256 cooldownDuration);

	event AumAdjustmentSet(uint256 aumAddition, uint256 aumDeduction);

	event MaxPercentageOfWagerFeeSet(uint256 maxPercentageOfWagerFee);

	event CircuitBreakerTriggered(
		address forToken,
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);

	event CircuitBreakerPolicy(
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);

	event CircuitBreakerReset(
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUSDW {
	event VaultAdded(address vaultAddress);

	event VaultRemoved(address vaultAddress);

	function addVault(address _vault) external;

	function removeVault(address _vault) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IMintable {
	event MinterSet(address minterAddress, bool isActive);

	function isMinter(address _account) external returns (bool);

	function setMinter(address _minter, bool _isActive) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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