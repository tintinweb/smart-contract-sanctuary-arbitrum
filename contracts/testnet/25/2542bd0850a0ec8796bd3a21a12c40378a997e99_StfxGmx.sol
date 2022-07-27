//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmxFactory } from "./interfaces/IStfxGmxFactory.sol";
import { IStfxGmx } from "./interfaces/IStfxGmx.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IGmxVault } from "./interfaces/gmx/IGmxVault.sol";
import { IGmxRouter } from "./interfaces/gmx/IGmxRouter.sol";
import { IGmxVaultUtils } from "./interfaces/gmx/IGmxVaultUtils.sol";
import { IGmxPositionRouter } from "./interfaces/gmx/IGmxPositionRouter.sol";

/// @title Stfx-Gmx
/// @author 7811
/// @notice Contract to integrate the Single Trade Fund (STF) with GMX
contract StfxGmx is IStfxGmx {
	/*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

	uint256 private constant BASE = 100 * (10**18);
	uint256 private constant MANAGER_FEE = 17 * (10**18);
	uint256 private constant PROTOCOL_FEE = 3 * (10**18);

	// bool to make sure initialize() is called only once
	bool private calledInitialize;
	// bool to make sure openPosition() is called only once
	bool private calledOpen;
	// address of the factory contract
	address public factoryAddress;
	// manager of this STF
	address public manager;
	// owner of the factory contract
	address public factoryOwner;
	// baseToken used for the trade
	// eg. vETH, vBTC (any virtual asset (vAsset))
	address public baseToken;
	// usdc address
	address public usdc;
	// true -> long, false -> short
	bool public tradeDirection;

	// perpetual protocol contract addresses
	GmxAddress public gmx;
	// status of the vault, check `IStfx`
	VaultStatus public vaultStatus;

	// total amount raised by the manager in this vault
	uint256 public totalRaised;
	// time till when the manager can raise funds
	uint256 public endTime;
	// time from the fundraisingPeriod till when the manager can deploy the fund
	// default is 72 hours (3 days)
	uint256 public fundDeadline;
	// default is 300 seconds (5 minutes)
	uint256 public tradeDeadline;
	// default leverage for the trade
	uint256 public leverage;
	// remaining usdc in this contract after withdrawing
	uint256 public remainingUsdc;
	// manager's referral code
	bytes32 public referralCode;
	// account to total amount deposited
	mapping(address => uint256) public userAmount;
	// mapping to check if the investor has claimed
	mapping(address => bool) public claimed;

	/*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

	/// @notice modifier to make sure the initalize() is called only once
	modifier initOnce() {
		require(!calledInitialize, "can only initialize once");
		calledInitialize = true;
		_;
	}

	/// @notice modifier to make sure the openPosition() is called only once
	modifier openOnce() {
		require(!calledOpen, "can only open once");
		calledOpen = true;
		_;
	}

	/// @notice modifier for the trading methods to be called only by the manager
	modifier onlyManager() {
		require(msg.sender == manager, "only manager");
		_;
	}

	/// @notice modifier to change capacity and deadline
	modifier onlyFactoryOwner() {
		require(msg.sender == factoryOwner, "only factory owner");
		_;
	}

	/// @notice modifier to execute withdraw logic and change referralCode
	modifier onlyManagerOrFactoryOwner() {
		require(msg.sender == manager || msg.sender == factoryOwner, "onlyManager or factoryOwner");
		_;
	}

	/*//////////////////////////////////////////////////////////////
                            INITIALIZE
    //////////////////////////////////////////////////////////////*/

	/// @notice initializes the STF, one per trade
	/// @dev can only be initialized once per contract
	/// @param _fund fund detials
	/// @param _gmx gmx contract addresses
	/// @param _manager address of the manager and the one controlling this contract
	function initialize(
		Fund calldata _fund,
		GmxAddress calldata _gmx,
		address _manager
	) external override initOnce {
		gmx = _gmx;
		manager = _manager;
		endTime = block.timestamp + _fund.fundraisingPeriod;
		factoryOwner = IStfxGmxFactory(msg.sender).owner();
		baseToken = _fund.baseToken;
		leverage = _fund.leverage;
		factoryAddress = msg.sender;
		fundDeadline = 72 hours;
		tradeDeadline = 900;
		tradeDirection = _fund.tradeDirection;
		usdc = IStfxGmxFactory(msg.sender).usdc();
	}

	/*//////////////////////////////////////////////////////////////
                            FUNDRAISING
    //////////////////////////////////////////////////////////////*/

	/// @notice anyone can be an investor and deposit into this vault for the manager to start trading
	/// @dev fundraisingPeriod has to end and the totalAmount raised should not be more than the capacity
	/// @dev approve has to be called before this method for the investor to transfer usdc to this contract
	/// @param amount amount the investor wants to deposit
	function depositIntoFund(uint256 amount) external override {
		require(block.timestamp <= endTime, "not in deposit period");
		require(totalRaised + amount <= IStfxGmxFactory(factoryAddress).capacityPerFund(), "vault is full");
		require(amount >= IStfxGmxFactory(factoryAddress).minInvestmentAmount(), "less than min amount");

		totalRaised += amount;
		userAmount[msg.sender] += amount;

		IERC20(usdc).transferFrom(msg.sender, address(this), amount);
		emit DepositIntoFund(msg.sender, address(this), amount, block.timestamp);
	}

	/*//////////////////////////////////////////////////////////////
                            TRADING
    //////////////////////////////////////////////////////////////*/

	/// @notice Calls the `PositionRouter` on GMX and creates a new position which is then executed
	///			by the keepers
	/// @dev `openPosition` can only be called by the manager and can only be called once
	function openPosition() external payable override onlyManager openOnce {
		require(block.timestamp > endTime, "still fundraising period");
		require(vaultStatus != VaultStatus.OPENED, "already opened a position");

		IStfxGmx.GmxAddress memory _gmx = gmx;
		require(msg.value >= IGmxPositionRouter(_gmx.positionRouter).minExecutionFee(), "fees not equal");

		address[] memory _path;
		address collateral = tradeDirection ? baseToken : usdc;

		if (collateral == usdc) {
			_path = new address[](1);
			_path[0] = usdc;
		} else {
			_path = new address[](2);
			_path[0] = usdc;
			_path[1] = collateral;
		}

		uint256 _price = tradeDirection
			? IGmxVault(_gmx.vault).getMaxPrice(baseToken)
			: IGmxVault(_gmx.vault).getMinPrice(baseToken);
		uint256 _sizeDelta = leverage * totalRaised * 1e24;
		uint256 _fee = IGmxPositionRouter(_gmx.positionRouter).minExecutionFee();

		IGmxRouter(_gmx.router).approvePlugin(_gmx.positionRouter);
		IGmxPositionRouter(_gmx.positionRouter).createIncreasePosition{ value: _fee }(
			_path,
			baseToken,
			totalRaised,
			0,
			_sizeDelta,
			tradeDirection,
			_price,
			_fee,
			referralCode
		);

		vaultStatus = VaultStatus.OPENED;

		emit VaultOpened(block.timestamp, address(this));
	}

	/// @notice Calls the `PositionRouter` on GMX and creates a close position on an already open one
	/// @dev `closePosition` can only be called by the manager and the factoryOwner and has a max
	///		  time limit of 1 month, after which our backend bot will automatically close the position
	function closePosition() external payable override onlyManagerOrFactoryOwner {
		require(vaultStatus == VaultStatus.OPENED, "no positions open");

		IStfxGmx.GmxAddress memory _gmx = gmx;
		require(msg.value >= IGmxPositionRouter(_gmx.positionRouter).minExecutionFee(), "fees not equal");

		address collateral = tradeDirection ? baseToken : usdc;
		(uint256 size, , , , , , , ) = IGmxVault(_gmx.vault).getPosition(
			address(this),
			collateral,
			baseToken,
			tradeDirection
		);

		uint256 _price = tradeDirection
			? IGmxVault(_gmx.vault).getMinPrice(baseToken)
			: IGmxVault(_gmx.vault).getMaxPrice(baseToken);

		address[] memory _path;

		if (collateral == usdc) {
			_path = new address[](1);
			_path[0] = usdc;
		} else {
			_path = new address[](2);
			_path[0] = collateral;
			_path[1] = usdc;
		}

		uint256 _fee = IGmxPositionRouter(_gmx.positionRouter).minExecutionFee();

		vaultStatus = VaultStatus.CLOSED;

		IGmxPositionRouter(_gmx.positionRouter).createDecreasePosition{ value: _fee }(
			_path,
			baseToken,
			0,
			size,
			tradeDirection,
			address(this),
			_price,
			0,
			_fee,
			false
		);

		emit VaultClosed(block.timestamp, address(this), IERC20(usdc).balanceOf(address(this)));
	}

	/// @notice Distributes the profit after closing the position
	/// @dev can be called only by the manager
	/// @dev is called by the backend bot immediately after the keepers execute the position
	function distributeProfits() external override onlyManagerOrFactoryOwner {
		uint256 profits;
		uint256 managerFee;
		uint256 protocolFee;
		uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));

		require(usdcBalance > 0, "nothing to distribute");
		require(vaultStatus == VaultStatus.CLOSED, "not yet closed");

		if (usdcBalance > totalRaised) {
			profits = usdcBalance - totalRaised;
			managerFee = (profits * MANAGER_FEE) / BASE;
			protocolFee = (profits * PROTOCOL_FEE) / BASE;

			IERC20(usdc).transfer(manager, managerFee);
			IERC20(usdc).transfer(factoryOwner, protocolFee);

			// solhint-disable-next-line
			remainingUsdc = IERC20(usdc).balanceOf(address(this));
		} else {
			// solhint-disable-next-line
			remainingUsdc = usdcBalance;
		}

		IStfxGmxFactory(factoryAddress).setIsManagingFund(manager);

		emit FeesTransferred(managerFee, protocolFee, block.timestamp, address(this));
	}

	/// @notice Method to return the amount which is claimable by the investor including the profits
	/// @dev the position has to be closed before
	/// @param investor address of the investor
	/// @return amount which can be claimed by the investor and 0 if the investor has already claimed
	function claimableAmount(address investor) public view override returns (uint256 amount) {
		if (claimed[investor] || vaultStatus == VaultStatus.OPENED) {
			amount = 0;
		} else if (vaultStatus == VaultStatus.CANCELLED || vaultStatus == VaultStatus.NOT_OPENED) {
			amount = userAmount[investor];
		} else if (vaultStatus == VaultStatus.CLOSED) {
			amount = (remainingUsdc * userAmount[investor] * 1e18) / (totalRaised * 1e18);
		} else {
			amount = 0;
		}
	}

	/// @notice Method for the investors to claim the remaining amount including profits from
	///			the fund depending on the weightage of the account calling this method
	/// @notice it also includes the refund which will be available if the position is not filled by the deadline
	/// @dev requires the vault to be closed or CANCELLED
	function claim() external override {
		require(
			vaultStatus == VaultStatus.CLOSED || vaultStatus == VaultStatus.CANCELLED,
			"not yet closed or cancelled"
		);

		uint256 amount = claimableAmount(msg.sender);
		require(amount > 0, "nothing to claim");

		claimed[msg.sender] = true;
		userAmount[msg.sender] = 0;
		IERC20(usdc).transfer(msg.sender, amount);

		emit ClaimedUSDC(msg.sender, amount, block.timestamp, address(this));
	}

	/// @notice Method to close the vault if the position gets liquidated
	/// @dev requires the TREASURY to call
	function closeLiquidatedVault() external override onlyFactoryOwner {
		vaultStatus = VaultStatus.LIQUIDATED;
		emit VaultLiquidated(block.timestamp, address(this));
	}

	/// @notice Method to close the vault if the position is not filled
	/// @dev requires the TREASURY to call
	function cancelVault() external override onlyFactoryOwner {
		require(
			block.timestamp > endTime + fundDeadline && vaultStatus == VaultStatus.NOT_OPENED,
			"already opened a position"
		);
		vaultStatus = VaultStatus.CANCELLED;
		emit NoFillVaultClosed(block.timestamp, address(this));
	}

	/*//////////////////////////////////////////////////////////////
                            SETFUNCTIONS
    //////////////////////////////////////////////////////////////*/

	/// @notice Method to set a new Deadline for the manager to open a position after fundraising
	/// @dev only the factory owner can call
	/// @param _fundDeadline the new deadline in seconds
	function setFundDeadline(uint256 _fundDeadline) external override onlyManagerOrFactoryOwner {
		fundDeadline = _fundDeadline;
		emit FundDeadlineChanged(_fundDeadline, address(this), block.timestamp);
	}

	/// @notice Method to set the new manager
	/// @dev only the current manager can call
	/// @param _manager address of the new manager
	function setManagerAddress(address _manager) external override onlyManager {
		require(_manager != address(0), "can't be zero address");
		manager = _manager;
		emit ManagerAddressChanged(_manager, address(this), block.timestamp);
	}

	/// @notice Method to set the referral code for the trade
	/// @dev can be called wither by the manager or by the factory owner
	/// @param _referralCode referralCode in bytes32 acquired from Perp
	function setReferralCode(bytes32 _referralCode) external override onlyManagerOrFactoryOwner {
		referralCode = _referralCode;
		emit ReferralCodeChanged(_referralCode, address(this), block.timestamp);
	}

	/// @notice Method to set the deadline for the trade
	/// @dev can be called wither by the manager
	/// @param _tradeDeadline the new trade deadline
	function setTradeDeadline(uint256 _tradeDeadline) external override onlyManager {
		tradeDeadline = _tradeDeadline;
		emit TradeDeadlineChanged(_tradeDeadline, address(this), block.timestamp);
	}

	/// @notice Method to check if the vault is ready to be deployed
	/// @return true if the vault is deployable and vice-versa
	function isDeployable() external view returns (bool) {
		if (block.timestamp > endTime) {
			return true;
		}
		return false;
	}

	/// @notice Method to check if the investor's amount is refundable
	/// @return true if the deposit amount is refundable and vice-versa
	function isRefundable() external view returns (bool) {
		if (block.timestamp > endTime + fundDeadline && vaultStatus == VaultStatus.CANCELLED) {
			return true;
		}
		return false;
	}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmxStorage } from "./IStfxGmxStorage.sol";

interface IStfxGmxFactory is IStfxGmxStorage {
	event NewFundCreated(
		address indexed baseToken,
		uint256 fundraisingPeriod,
		uint256 entryPrice,
		uint256 targetPrice,
		uint256 liquidationPrice,
		uint256 leverage,
		bool tradeDirection,
		address indexed stfxAddress,
		address indexed manager,
		uint256 capacityPerFund,
		uint256 timeOfFundCreation
	);
	event GmxAddressUpdated(
		address indexed gmxVault,
		address indexed gmxRouter,
		address indexed gmxPositionRouter,
		uint256 timeOfChange
	);
	event CapacityPerFundChanged(uint256 capacityPerFund, uint256 timeOfChange);
	event MinInvestmentAmountChanged(uint256 minAmount, uint256 timeOfChange);
	event TraderStatusChanged(address indexed _trader, uint256 timeOfChange);
	event UsdcAddressUpdated(address indexed _usdc, uint256 timeOfChange);

	function owner() external view returns (address);

	function usdc() external view returns (address);

	function capacityPerFund() external view returns (uint256);

	function minInvestmentAmount() external view returns (uint256);

	function createNewStf(Fund calldata fund) external returns (address);

	function updateGmxAddresses(GmxAddress calldata gmx) external;

	function setCapacityPerFund(uint256 _capacityPerFund) external;

	function setMinInvestmentAmount(uint256 _amount) external;

	function setIsManagingFund(address _trader) external;

	function setUsdc(address _usdc) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmxStorage } from "./IStfxGmxStorage.sol";

interface IStfxGmx is IStfxGmxStorage {
	event DepositIntoFund(address indexed investor, address indexed stfxAddress, uint256 amount, uint256 timeOfDeposit);
	event Refund(address indexed investor, address indexed stfxAddress, uint256 amount, uint256 timeOfRefund);
	event FundDeadlineChanged(uint256 newDeadline, address indexed stfxAddress, uint256 timeOfChange);
	event ManagerAddressChanged(address indexed newManager, address indexed stfxAddress, uint256 timeOfChange);
	event ReferralCodeChanged(bytes32 newReferralCode, address indexed stfxAddress, uint256 timeOfChange);
	event FeesTransferred(
		uint256 managerFee,
		uint256 protocolFee,
		uint256 timeOfWithdrawal,
		address indexed stfxAddress
	);
	event ClaimedUSDC(address indexed investor, uint256 claimAmount, uint256 timeOfClaim, address indexed stfxAddress);
	event VaultLiquidated(uint256 timeOfLiquidation, address indexed stfxAddress);
	event NoFillVaultClosed(uint256 timeOfClose, address indexed stfxAddress);
	event TradeDeadlineChanged(uint256 newTradeDeadline, address indexed stfxAddress, uint256 timeOfChange);
	event VaultOpened(uint256 timeOfOpen, address indexed stfxAddress);
	event VaultClosed(uint256 timeOfClose, address indexed stfxAddress, uint256 usdcBalanceAfterClose);

	function initialize(
		Fund calldata,
		GmxAddress calldata,
		address _manager
	) external;

	function depositIntoFund(uint256 amount) external;

	function openPosition() external payable;

	function closePosition() external payable;

	function distributeProfits() external;

	function claimableAmount(address investor) external view returns (uint256);

	function claim() external;

	function closeLiquidatedVault() external;

	function cancelVault() external;

	function setFundDeadline(uint256 _deadline) external;

	function setManagerAddress(address _manager) external;

	function setReferralCode(bytes32 _referralCode) external;

	function setTradeDeadline(uint256 _tradeDeadline) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IGmxVaultUtils.sol";

interface IGmxVault {
	function isInitialized() external view returns (bool);

	function isSwapEnabled() external view returns (bool);

	function isLeverageEnabled() external view returns (bool);

	function setVaultUtils(IGmxVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	function router() external view returns (address);

	function usdg() external view returns (address);

	function gov() external view returns (address);

	function whitelistedTokenCount() external view returns (uint256);

	function maxLeverage() external view returns (uint256);

	function minProfitTime() external view returns (uint256);

	function hasDynamicFees() external view returns (bool);

	function fundingInterval() external view returns (uint256);

	function totalTokenWeights() external view returns (uint256);

	function getTargetUsdgAmount(address _token) external view returns (uint256);

	function inManagerMode() external view returns (bool);

	function inPrivateLiquidationMode() external view returns (bool);

	function maxGasPrice() external view returns (uint256);

	function approvedRouters(address _account, address _router) external view returns (bool);

	function isLiquidator(address _account) external view returns (bool);

	function isManager(address _account) external view returns (bool);

	function minProfitBasisPoints(address _token) external view returns (uint256);

	function tokenBalances(address _token) external view returns (uint256);

	function lastFundingTimes(address _token) external view returns (uint256);

	function setMaxLeverage(uint256 _maxLeverage) external;

	function setInManagerMode(bool _inManagerMode) external;

	function setManager(address _manager, bool _isManager) external;

	function setIsSwapEnabled(bool _isSwapEnabled) external;

	function setIsLeverageEnabled(bool _isLeverageEnabled) external;

	function setMaxGasPrice(uint256 _maxGasPrice) external;

	function setUsdgAmount(address _token, uint256 _amount) external;

	function setBufferAmount(address _token, uint256 _amount) external;

	function setMaxGlobalShortSize(address _token, uint256 _amount) external;

	function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;

	function setLiquidator(address _liquidator, bool _isActive) external;

	function setFundingRate(
		uint256 _fundingInterval,
		uint256 _fundingRateFactor,
		uint256 _stableFundingRateFactor
	) external;

	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _marginFeeBasisPoints,
		uint256 _liquidationFeeUsd,
		uint256 _minProfitTime,
		bool _hasDynamicFees
	) external;

	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _redemptionBps,
		uint256 _minProfitBps,
		uint256 _maxUsdgAmount,
		bool _isStable,
		bool _isShortable
	) external;

	function setPriceFeed(address _priceFeed) external;

	function withdrawFees(address _token, address _receiver) external returns (uint256);

	function directPoolDeposit(address _token) external;

	function buyUSDG(address _token, address _receiver) external returns (uint256);

	function sellUSDG(address _token, address _receiver) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function increasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _sizeDelta,
		bool _isLong
	) external;

	function decreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver
	) external returns (uint256);

	function liquidatePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong,
		address _feeReceiver
	) external;

	function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

	function priceFeed() external view returns (address);

	function fundingRateFactor() external view returns (uint256);

	function stableFundingRateFactor() external view returns (uint256);

	function cumulativeFundingRates(address _token) external view returns (uint256);

	function getNextFundingRate(address _token) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdgDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);

	function liquidationFeeUsd() external view returns (uint256);

	function taxBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function marginFeeBasisPoints() external view returns (uint256);

	function allWhitelistedTokensLength() external view returns (uint256);

	function allWhitelistedTokens(uint256) external view returns (address);

	function whitelistedTokens(address _token) external view returns (bool);

	function stableTokens(address _token) external view returns (bool);

	function shortableTokens(address _token) external view returns (bool);

	function feeReserves(address _token) external view returns (uint256);

	function globalShortSizes(address _token) external view returns (uint256);

	function globalShortAveragePrices(address _token) external view returns (uint256);

	function maxGlobalShortSizes(address _token) external view returns (uint256);

	function tokenDecimals(address _token) external view returns (uint256);

	function tokenWeights(address _token) external view returns (uint256);

	function guaranteedUsd(address _token) external view returns (uint256);

	function poolAmounts(address _token) external view returns (uint256);

	function bufferAmounts(address _token) external view returns (uint256);

	function reservedAmounts(address _token) external view returns (uint256);

	function usdgAmounts(address _token) external view returns (uint256);

	function maxUsdgAmounts(address _token) external view returns (uint256);

	function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function getDelta(
		address _indexToken,
		uint256 _size,
		uint256 _averagePrice,
		bool _isLong,
		uint256 _lastIncreasedTime
	) external view returns (bool, uint256);

	function getPosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			bool,
			uint256
		);

	function getPositionDelta(
		address _account,
		address _collateralToken,
		address _indexToken,
		bool _isLong
	) external view returns (bool, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxRouter {
	function addPlugin(address _plugin) external;

	function pluginTransfer(
		address _token,
		address _account,
		address _receiver,
		uint256 _amount
	) external;

	function pluginIncreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _sizeDelta,
		bool _isLong
	) external;

	function pluginDecreasePosition(
		address _account,
		address _collateralToken,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver
	) external returns (uint256);

	function swap(
		address[] memory _path,
		uint256 _amountIn,
		uint256 _minOut,
		address _receiver
	) external;

	function directPoolDeposit(address _token, uint256 _amount) external;

	function approvePlugin(address) external;

	function decreasePosition(
		address _collateralToken,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver,
		uint256 _price
	) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxPositionRouter {
	struct DecreasePositionRequest {
		address account;
		address[] path;
		address indexToken;
		uint256 collateralDelta;
		uint256 sizeDelta;
		bool isLong;
		address receiver;
		uint256 acceptablePrice;
		uint256 minOut;
		uint256 executionFee;
		uint256 blockNumber;
		uint256 blockTime;
		bool withdrawETH;
	}

	function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

	function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

	function createIncreasePosition(
		address[] memory _path,
		address _indexToken,
		uint256 _amountIn,
		uint256 _minOut,
		uint256 _sizeDelta,
		bool _isLong,
		uint256 _acceptablePrice,
		uint256 _executionFee,
		bytes32 _referralCode
	) external payable;

	function createDecreasePosition(
		address[] memory _path,
		address _indexToken,
		uint256 _collateralDelta,
		uint256 _sizeDelta,
		bool _isLong,
		address _receiver,
		uint256 _acceptablePrice,
		uint256 _minOut,
		uint256 _executionFee,
		bool _withdrawETH
	) external payable;

	function minExecutionFee() external view returns (uint256);

	function setPositionKeeper(address _account, bool _isActive) external;

	function getRequestKey(address _account, uint256 _index) external pure returns (bytes32);

	function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

	function decreasePositionRequests(bytes32 _key) external view returns (DecreasePositionRequest memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStfxGmxStorage {
	/// @notice Enum to describe the trading status of the vault
	/// @dev NOT_OPENED - Not open
	/// @dev OPENED - opened position
	/// @dev CLOSED - closed position
	/// @dev LIQUIDATED - liquidated position
	/// @dev CANCELLED - did not start due to deadline reached
	enum VaultStatus {
		NOT_OPENED,
		OPENED,
		CLOSED,
		LIQUIDATED,
		CANCELLED
	}

	struct GmxAddress {
		address vault;
		address router;
		address positionRouter;
	}

	struct Fund {
		address baseToken;
		uint256 fundraisingPeriod;
		uint256 entryPrice;
		uint256 targetPrice;
		uint256 liquidationPrice;
		uint256 leverage;
		bool tradeDirection;
	}
}