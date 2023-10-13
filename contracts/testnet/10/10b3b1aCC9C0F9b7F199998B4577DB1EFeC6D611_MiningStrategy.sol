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

    /*==================== Managed in GEMBTimelock *====================*/

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

    event PayinGEMLP(
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

    event ReferralDistributionReverted(
        uint256 registeredTooMuch,
        uint256 maxVaueAllowed
    );

    /*==================== Operational Functions *====================*/
    function setPayoutHalted(bool _setting) external;

    function isSwapEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setError(uint256 _errorCode, string calldata _error) external;

    function usdw() external view returns (address);

    function feeCollector() external returns (address);

    function hasDynamicFees() external view returns (bool);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdwAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function tokenBalances(address _token) external view returns (uint256);

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(
        address _manager,
        bool _isManager,
        bool _isGEMLPManager
    ) external;

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

    function withdrawAllFees(
        address _token
    ) external returns (uint256, uint256, uint256);

    function directPoolDeposit(address _token) external;

    function deposit(
        address _tokenIn,
        address _receiver,
        bool _swapLess
    ) external returns (uint256);

    function withdraw(
        address _tokenOut,
        address _receiverTokenOut
    ) external returns (uint256);

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

    function setVaultManagerAddress(
        address _vaultManagerAddress,
        bool _setting
    ) external;

    function wagerFeeBasisPoints() external view returns (uint256);

    function setWagerFee(uint256 _wagerFee) external;

    function wagerFeeReserves(address _token) external view returns (uint256);

    function referralReserves(address _token) external view returns (uint256);

    function getReserve() external view returns (uint256);

    function getGemLpValue() external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

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
        uint256 _escrowAmount
    ) external;

    function setAsideReferral(address _token, uint256 _amount) external;

    function payinWagerFee(address _tokenIn) external;

    function payinSwapFee(address _tokenIn) external;

    function payinPoolProfits(address _tokenIn) external;

    function removeAsideReferral(
        address _token,
        uint256 _amountRemoveAside
    ) external;

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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGEMB is IERC20 {
    function mint(
        address account,
        uint256 amount
    ) external returns (uint256, uint256);

    function burn(uint256 amount) external;

    function MAX_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "../interfaces/tokens/IGEMB.sol";
import "../interfaces/core/IVault.sol";
import "../core/AccessControlBase.sol";
import "../interfaces/core/IVault.sol";

contract MiningStrategy is AccessControlBase {
    /*==================================================== Events =============================================================*/

    event MiningMultiplierChanged(uint256 multiplier);
    event AddressesUpdated(IGEMB token, IVault vault);
    event ConfigUpdated(uint256[] _percentages, Config[] _configs);
    event VolumeIncreased(
        uint256 _amount,
        uint256 _newVolume,
        uint256 _dayIndex
    );
    event VolumeDecreased(
        uint256 _amount,
        uint256 _newVolume,
        uint256 _dayIndex
    );
    event AccountMultiplierChanged(address _account, uint256 _newMultiplier);
    event ParityIntervalUpdated(uint64 _newInterval);
    event ParityUpdated(uint256 _newParity);
    event MaxAccountMultiplierUpdated(uint256 _newMultiplier);
    /*==================================================== State Variables ====================================================*/

    struct Config {
        uint256 minMultiplier;
        uint256 maxMultiplier;
    }

    IGEMB public GEMB;
    IVault public vault;
    /// @notice max mint amount by games
    uint256 public immutable MAX_MINT;
    /// @notice Last parity of ETH/GEMB
    uint256 public parity;
    /// @notice Interval of parity update
    uint64 public parityInterval = 1 days;
    /// @notice max multiplier of accounts
    uint256 public maxAccountMultiplier;
    /// @notice Last parity update time
    uint256 public lastParityUpdateTime;
    /// @notice Last calculated multipliers index id
    uint256 public lastCalculatedIndex;
    /// @notice The volumes of given period duration
    mapping(uint256 => uint256) public dailyVolumes;
    /// @notice The volumes of given period duration
    mapping(uint256 => uint256) public dailyVolumeCurrentMultiplier;
    /// @notice Multipliers of accounts
    mapping(address => uint256) public accountMultipliers;
    /// @notice Last calculated multiplier
    uint256 public currentMultiplier;
    /// @notice Start time of periods
    uint256 public immutable volumeRecordStartTime = block.timestamp - 2 days;

    uint256[] public percentages;
    mapping(uint256 => Config) public halvings;

    /*==================================================== Constant Variables ==================================================*/

    /// @notice used to calculate precise decimals
    uint256 private constant PRECISION = 1e18;

    /*==================================================== Configurations ===========================================================*/

    constructor(
        address _vaultRegistry,
        address _timelock,
        uint256 _maxMint
    ) AccessControlBase(_vaultRegistry, _timelock) {
        MAX_MINT = _maxMint;
        maxAccountMultiplier = 2e18;
    }

    /**
     *
     * @dev Internal function to update the halvings mapping.
     * @param _percentages An array of percentages at which the halvings will occur.
     * @param _configs An array of configurations to be associated with each halving percentage.
     * @notice The function requires that the lengths of the two input arrays must be equal.
     * @notice Each configuration must have a non-zero value for both minMultiplier and maxMultiplier.
     * @notice The minimum multiplier value must be less than the maximum multiplier value for each configuration.
     * @notice For each percentage in the _percentages array, the corresponding configuration in the _configs array will be associated with the halvings mapping.
     * @notice After the halvings are updated, the percentages and configurations arrays will be updated and a ConfigUpdated event will be emitted with the new arrays as inputs.
     */
    function _updateHalvings(
        uint256[] memory _percentages,
        Config[] memory _configs
    ) internal {
        require(
            _percentages.length == _configs.length,
            "Lengths must be equal"
        );
        require(_percentages.length <= type(uint8).max, "Too many halvings");
        for (uint256 i = 0; i < _percentages.length; i++) {
            require(_configs[i].maxMultiplier != 0, "Max zero");
            require(_configs[i].minMultiplier != 0, "Min zero");
            require(
                _configs[i].minMultiplier < _configs[i].maxMultiplier,
                "Min greater than max"
            );
            halvings[_percentages[i]] = _configs[i];
        }
        percentages = _percentages;

        if (currentMultiplier == 0) {
            currentMultiplier = _configs[0].maxMultiplier;
        }

        emit ConfigUpdated(_percentages, _configs);
    }

    /**
     *
     * @param _percentages An array of percentages at which the halvings will occur.
     * @param _configs  An array of configurations to be associated with each halving percentage.
     * @dev Allows the governance role to update the halvings mapping.
     */
    function updateHalvings(
        uint256[] memory _percentages,
        Config[] memory _configs
    ) public onlyGovernance {
        _updateHalvings(_percentages, _configs);
    }

    /**
     *
     * @dev Allows the governance role to update the contract's addresses for the GEMB token, Vault, Pool, and Pair Token.
     * @param _GEMB The new address of the GEMB token contract.
     * @param _vault The new address of the Vault contract.
     * @notice Each input address must not be equal to the zero address.
     * @notice The function updates the corresponding variables with the new addresses.
     * @notice Finally, an AddressesUpdated event is emitted with the updated GEMB and Vault addresses.
     */
    function updateAddresses(IGEMB _GEMB, IVault _vault) public onlyGovernance {
        require(address(_GEMB) != address(0), "GEMB address zero");
        require(address(_vault) != address(0), "Vault zero");

        GEMB = _GEMB;
        vault = _vault;

        emit AddressesUpdated(_GEMB, _vault);
    }

    /**
     *
     * @param _maxAccountMultiplier The new value for the maxAccountMultiplier variable.
     * @notice This function allows the governance role to update the maxAccountMultiplier variable.
     */
    function updateMaxAccountMultiplier(
        uint256 _maxAccountMultiplier
    ) external onlyGovernance {
        maxAccountMultiplier = _maxAccountMultiplier;

        emit MaxAccountMultiplierUpdated(_maxAccountMultiplier);
    }

    /**
     *
     * @param _account The account for which to set the multiplier.
     * @param _multiplier multiplier to set for the account.
     */
    function setAccountMultiplier(
        address _account,
        uint256 _multiplier
    ) external onlyProtocol {
        require(_multiplier <= maxAccountMultiplier, "Multiplier too high");
        accountMultipliers[_account] = _multiplier;

        emit AccountMultiplierChanged(_account, _multiplier);
    }

    function updateParityInterval(
        uint64 _parityInterval
    ) external onlyGovernance {
        parityInterval = _parityInterval;

        emit ParityIntervalUpdated(_parityInterval);
    }

    /*==================================================== Volume ===========================================================*/

    function getVolumeDayIndex() public view returns (uint256 day_) {
        day_ = (block.timestamp - volumeRecordStartTime) / 1 days;
    }

    /**
    @dev Public function to get the daily volume of a specific day index.
    @param _dayIndex The index of the day for which to get the volume.
    @return volume_ The  volume of the specified day index.
    @notice This function takes a day index and returns the volume of that day,
    as stored in the dailyVolumes mapping.
    */
    function getVolumeOfDay(
        uint256 _dayIndex
    ) public view returns (uint256 volume_) {
        volume_ = dailyVolumes[_dayIndex]; // Get the  volume of the specified day index from the dailyVolumes mapping
    }

    /**
    @dev Public function to calculate the dollar value of a given token amount.
    @param _token The address of the whitelisted token on the vault.
    @param _amount The amount of the given token.
    @return dollarValue_ The dollar value of the given token amount.
    @notice This function takes the address of a whitelisted token on the vault and an amount of that token,
    and calculates the dollar value of that amount by multiplying the amount by the current dollar value of the token
    on the vault and dividing by 10^decimals of the token. The result is then divided by 1e12 to convert to USD.
    */
    function computeDollarValue(
        address _token,
        uint256 _amount
    ) public view returns (uint256 dollarValue_) {
        uint256 decimals_ = vault.tokenDecimals(_token); // Get the decimals of the token using the Vault interface
        dollarValue_ = ((_amount * vault.getMinPrice(_token)) /
            10 ** decimals_); // Calculate the dollar value by multiplying the amount by the current dollar value of the token on the vault and dividing by 10^decimals
        dollarValue_ = dollarValue_ / 1e12; // Convert the result to USD by dividing by 1e12
    }

    /**
     *
     * @dev External function to increase the volume of the current day index.
     * @dev This function is called by the Token Manager to increase the volume of the current day index.
     * @param _input The address of the token to increase the volume.
     * @param _amount The amount of the token to increase the volume.
     * @notice This function is called by the Token Manager to increase the volume
     *  of the current day index. It calculates the dollar value of the token amount using
     *  the computeDollarValue function, adds it to the volume of the current day
     *  index, and emits a VolumeIncreased event with the updated volume.
     */
    function increaseVolume(
        address _input,
        uint256 _amount
    ) external onlyProtocol {
        uint256 dayIndex_ = getVolumeDayIndex(); // Get the current day index to update the volume
        uint256 dollarValue_ = computeDollarValue(_input, _amount); // Calculate the dollar value of the token amount using the computeDollarValue function
        unchecked {
            dailyVolumes[dayIndex_] += dollarValue_; // Increase the volume of the current day index by the calculated dollar value
        }
        emit VolumeIncreased(dollarValue_, dailyVolumes[dayIndex_], dayIndex_); // Emit a VolumeIncreased event with the updated volume
    }

    /**
     *
     * @dev External function to decrease the volume of the current day index.
     * @dev This function is called by the Token Manager to decrease the volume of the current day index.
     * @param _input The address of the token to decrease the volume.
     * @param _amount The amount of the token to decrease the volume.
     * @notice This function is called by the Token Manager to decrease the volume
     *  of the current day index. It calculates the dollar value of the token amount using
     *  the computeDollarValue function, subtracts it from the  volume of the current day
     *  index, and emits a VolumeDecreased event with the updated volume.
     */
    function decreaseVolume(
        address _input,
        uint256 _amount
    ) external onlyProtocol {
        uint256 dayIndex_ = getVolumeDayIndex(); // Get the current day index to update the  volume
        uint256 dollarValue_ = computeDollarValue(_input, _amount); // Calculate the dollar value of the token amount using the computeDollarValue function

        // Decrease the  volume of the current day index by the calculated dollar value
        if (dailyVolumes[dayIndex_] > dollarValue_) {
            dailyVolumes[dayIndex_] -= dollarValue_;
        } else {
            dailyVolumes[dayIndex_] = 0;
        }

        emit VolumeDecreased(dollarValue_, dailyVolumes[dayIndex_], dayIndex_); // Emit a VolumeDecreased event with the updated volume
    }

    /*================================================== Mining =================================================*/

    /**
     *
     * @param _parity The parity of the USDC/GEMB
     * @dev This function is called by the Support accounts to set the parity of the USDC/GEMB
     */
    function setParity(uint256 _parity) external onlyTeam {
        // Parity can be updated once per interval
        require(
            lastParityUpdateTime + parityInterval <= block.timestamp,
            "Parity: parity can be updated once per interval"
        );

        parity = _parity;
        lastParityUpdateTime = block.timestamp;

        emit ParityUpdated(_parity);
    }

    /**
     * @notice This function calculates the mining multiplier based on the current day's volume and the previous day's volume
     * @dev It takes in two parameters, the number of tokens minted by games and the maximum number of tokens that can be minted
     * @dev It returns the current mining multiplier as an int256
     * @dev _mintedByGames and MAX_MINT are using to halving calculation
     * @param _mintedByGames The total minted Vested GEMB amount
     */
    function _getMultiplier(uint256 _mintedByGames) internal returns (uint256) {
        uint256 index_ = getVolumeDayIndex();

        // If the current day's index is the same as the last calculated index, return the current multiplier
        if (lastCalculatedIndex == index_) {
            return currentMultiplier;
        }

        // Get the current configuration based on the number of tokens minted by games and the maximum number of tokens that can be minted
        Config memory config_ = getCurrentConfig(_mintedByGames);

        // Get the volume of the previous day and the current day
        uint256 prevDayVolume_ = getVolumeOfDay(index_ - 2);
        uint256 currentDayVolume_ = getVolumeOfDay(index_ - 1);

        // If either the current day's volume or the previous day's volume is zero, return the current multiplier
        if (currentDayVolume_ == 0 || prevDayVolume_ == 0) {
            dailyVolumeCurrentMultiplier[index_] = currentMultiplier;
            return currentMultiplier;
        }

        // Calculate the percentage change in volume between the previous day and the current day
        uint256 diff_ = (
            currentDayVolume_ > prevDayVolume_
                ? currentDayVolume_ - prevDayVolume_
                : prevDayVolume_ - currentDayVolume_
        );
        uint256 periodChangeRate_ = ((diff_ * 1e36) / prevDayVolume_) /
            PRECISION;

        // Calculate the new multiplier and ensure it's within the configured range
        uint256 newMultiplier;
        if (currentDayVolume_ < prevDayVolume_) {
            newMultiplier =
                (currentMultiplier * (1e18 + 2 * periodChangeRate_)) /
                PRECISION;
        } else {
            uint256 decrease = (currentMultiplier * periodChangeRate_) /
                PRECISION;
            newMultiplier = decrease > currentMultiplier
                ? config_.minMultiplier
                : currentMultiplier - decrease;
        }
        newMultiplier = newMultiplier > config_.maxMultiplier
            ? config_.maxMultiplier
            : newMultiplier;
        newMultiplier = newMultiplier < config_.minMultiplier
            ? config_.minMultiplier
            : newMultiplier;

        // Set the new multiplier for the current day and emit an event
        currentMultiplier = newMultiplier;
        dailyVolumeCurrentMultiplier[index_] = currentMultiplier;
        emit MiningMultiplierChanged(currentMultiplier);

        // Update the last calculated index and return the current multiplier
        lastCalculatedIndex = index_;
        return currentMultiplier;
    }

    /**
     *
     * @param _account address of the account
     * @param _amount amount of the token
     * @param _mintedByGames minted Vested GEMB amount
     * @dev This function is called by the Token Manager to calculate the mint amount
     * @notice This function calculates the mint amount based on the current day's volume and the previous day's volume
     */
    function calculate(
        address _account,
        uint256 _amount,
        uint256 _mintedByGames
    ) external onlyProtocol returns (uint256 mintAmount_) {
        // If the account has a multiplier, use it to calculate the mint amount
        if (accountMultipliers[_account] != 0) {
            mintAmount_ = _calculate(_amount, accountMultipliers[_account]);
        } else {
            // Otherwise, use the current multiplier to calculate the mint amount
            mintAmount_ = _calculate(_amount, _getMultiplier(_mintedByGames));
        }
    }

    /**
     * @notice This function calculates the mint amount based on the current day's volume and the previous day's volume
     * @param _amount The amount of tokens to calculate the mint amount for
     * @param _multiplier The multiplier to use to calculate the mint amount
     */
    function _calculate(
        uint256 _amount,
        uint256 _multiplier
    ) internal view returns (uint256) {
        return ((_amount * _multiplier * PRECISION) / parity) / PRECISION;
    }

    function getCurrentConfig(
        uint256 _mintedByGames
    ) public view returns (Config memory config) {
        uint256 ratio_ = (PRECISION * _mintedByGames) / MAX_MINT;
        uint8 index_ = findIndex(ratio_);
        return halvings[percentages[index_]];
    }

    function findIndex(uint256 ratio) internal view returns (uint8 index) {
        uint8 min_ = 0;
        uint8 max_ = uint8(percentages.length) - 1;

        while (min_ < max_) {
            uint8 mid_ = (min_ + max_) / 2;
            if (ratio < percentages[mid_]) {
                max_ = mid_;
            } else {
                min_ = mid_ + 1;
            }
        }

        return min_;
    }
}