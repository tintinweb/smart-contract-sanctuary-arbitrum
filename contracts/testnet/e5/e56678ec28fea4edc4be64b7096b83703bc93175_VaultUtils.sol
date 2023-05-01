// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/core/IVault.sol";
import "../interfaces/core/IVaultUtils.sol";
import "./AccessControlBase.sol";

contract VaultUtils is IVaultUtils, AccessControlBase {
	IVault public immutable vault;

	constructor(
		address _vault,
		address _vaultRegistry,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) {
		vault = IVault(_vault);
	}

	/*==================== View functions *====================*/

	/**
	 * @notice returns the amount of basispooints the vault will charge for a WLP deposit (so minting of WLP by depositing a whitelisted asset in the vault)
	 * @param _token address of the token to check
	 * @param _usdwAmount usdw amount/value of the mutation
	 * @return the fee basis point the vault will charge for the mutation
	 */
	function getBuyUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view override returns (uint256) {
		uint256 dynamicFee_ = getFeeBasisPoints(
			_token,
			_usdwAmount,
			vault.mintBurnFeeBasisPoints(),
			vault.taxBasisPoints(),
			true
		);
		uint256 minimumFee_ = vault.minimumBurnMintFee();
		// if the dynamic fee is lower than the minimum fee
		if (dynamicFee_ < minimumFee_) {
			// the vault will charge the minimum configured mint/burn fee
			return minimumFee_;
		} else {
			return dynamicFee_;
		}
	}

	/**
	 * @notice returns the amount of basispooints the vault will charge for a WLP withdraw (so burning of WLP for a certain whitelisted asset in the vault)
	 * @param _token address of the token to check
	 * @param _usdwAmount usdw amount/value of the mutation
	 * @return the fee basis point the vault will charge for the mutation
	 */
	function getSellUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view override returns (uint256) {
		uint256 dynamicFee_ = getFeeBasisPoints(
			_token,
			_usdwAmount,
			vault.mintBurnFeeBasisPoints(),
			vault.taxBasisPoints(),
			false
		);
		uint256 minimumFee_ = vault.minimumBurnMintFee();
		// if the dynamic fee is lower than the minimum fee
		if (dynamicFee_ < minimumFee_) {
			// the vault will charge the minimum configured mint/burn fee
			return minimumFee_;
		} else {
			return dynamicFee_;
		}
	}

	/**
	 * @notice this function determines how much swap fee needs to be paid for a certain swap
	 * @dev the size/extent of the swap fee depends on if the swap balances the WLP (cheaper) or unbalances the pool (expensive)
	 * @param _tokenIn address of the token being sold by the swapper
	 * @param _tokenOut address of the token being bought by the swapper
	 * @param _usdwAmount the amount of of USDC/WLP the swap is 'worth'
	 */
	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdwAmount
	) external view override returns (uint256 effectiveSwapFee_) {
		// check if the swap is a swap between 2 stablecoins
		bool isStableSwap_ = vault.stableTokens(_tokenIn) && vault.stableTokens(_tokenOut);
		uint256 baseBps_ = isStableSwap_
			? vault.stableSwapFeeBasisPoints()
			: vault.swapFeeBasisPoints();
		uint256 taxBps_ = isStableSwap_
			? vault.stableTaxBasisPoints()
			: vault.taxBasisPoints();
		/**
		 * How large a swap fee is depends on if the swap improves the WLP asset balance or not.
		 * If the incoming asset is relatively scarce, this means a lower swap rate
		 * If the outcoing asset is abundant, this means a lower swap rate
		 * Both the in and outcoming assets need to improve the balance for the swap fee to be low.
		 * If both the incoming as the outgoing asset are scarce, this will mean that the swap fee will be high.
		 */
		// get the swap fee for the incoming asset/change
		uint256 feesBasisPoints0_ = getFeeBasisPoints(
			_tokenIn,
			_usdwAmount,
			baseBps_,
			taxBps_,
			true
		);
		// get the swap fee for the outgoing change/asset
		uint256 feesBasisPoints1_ = getFeeBasisPoints(
			_tokenOut,
			_usdwAmount,
			baseBps_,
			taxBps_,
			false
		);
		// use the highest of the two fees as effective rate
		effectiveSwapFee_ = feesBasisPoints0_ > feesBasisPoints1_
			? feesBasisPoints0_
			: feesBasisPoints1_;
	}

	// cases to consider
	// 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
	// 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
	// 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
	// 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
	// 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
	// 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
	// 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
	// 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
	/**
	 * @param _token the asset that is entering or leaving the WLP
	 * @param _usdwDelta the amount of WLP this incoming/outgoing asset is 'worth'
	 * @param _feeBasisPoints the amount of swap fee (based on the type of swap)
	 * @param _taxBasisPoints the amount of tax (based on the type of swap)
	 * @param _increment if the asset is coming in 'incrementing the balance'
	 * @return the swapFee in basis points (including the tax)
	 */
	function getFeeBasisPoints(
		address _token,
		uint256 _usdwDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) public view override returns (uint256) {
		if (!vault.hasDynamicFees()) {
			return _feeBasisPoints;
		}
		// fetch how much debt of the _token there is before the change in the WLP
		uint256 initialAmount_ = vault.usdwAmounts(_token);
		uint256 nextAmount_;
		// if the _token is leaving the pool (so it is NOT incrementing the pool debt/balance)
		if (!_increment) {
			// if the token is leaving the usdw debt will be reduced
			unchecked {
				nextAmount_ = _usdwDelta > initialAmount_
					? 0
					: (initialAmount_ - _usdwDelta);
			}
			// IMO nextAmount cannot be 0 realistically, it is merely there to prevent underflow
		} else {
			unchecked {
				// calculate how much the debt will be
				nextAmount_ = (initialAmount_ + _usdwDelta);
			}
		}
		// fetch how much usdw debt the token should be in optimally balanced state
		uint256 targetAmount_ = vault.getTargetUsdwAmount(_token);
		// if the token weight is 0, then the fee is the standard fee
		if (targetAmount_ == 0) {
			return _feeBasisPoints;
		}
		/**
		 * calculate how much the pool balance was before the swap/depoist/mutation is processed
		 */
		uint256 initialDiff_;
		unchecked {
			initialDiff_ = initialAmount_ > targetAmount_
				? (initialAmount_ - targetAmount_)
				: (targetAmount_ - initialAmount_);
		}
		/**
		 * calculate the balance of the pool after the swap/deposit/mutation is processed
		 */
		uint256 nextDiff_;
		unchecked {
			nextDiff_ = nextAmount_ > targetAmount_
				? (nextAmount_ - targetAmount_)
				: (targetAmount_ - nextAmount_);
		}
		/**
		 * with the initial and next balance, we can determine if the swap/deposit/mutation is improving the balance of the pool
		 */
		// action improves relative asset balance
		if (nextDiff_ < initialDiff_) {
			// the _taxBasisPoints determines the extent of the discount of the fee, the higher the tax, the lower the fee in case of improvement of the pool
			// this effect also works in reverse, if the tax is low, the fee will be high in case of improvement of the pool
			uint256 rebateBps_ = (_taxBasisPoints * initialDiff_) / targetAmount_;
			// if the action improves the balance so that the rebate is so high, no swap fee is charged and no tax is charged
			// if the rebate is higher than the fee, the function returns 0
			return rebateBps_ > _feeBasisPoints ? 0 : (_feeBasisPoints - rebateBps_);
		}
		/**
		 * If we are here, it means that this leg of the swap isn't improving the balance of the pool.
		 * Now we need to establish to what extent this leg unbalances the pool in order to determine the final fee.
		 */
		uint256 averageDiff_ = (initialDiff_ + nextDiff_) / 2;
		if (averageDiff_ > targetAmount_) {
			averageDiff_ = targetAmount_;
		}
		uint256 taxBps_ = (_taxBasisPoints * averageDiff_) / targetAmount_;
		return (_feeBasisPoints + taxBps_);
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

	function isInitialized() external view returns (bool);

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	function router() external view returns (address);

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

	function deposit(address _tokenIn, address _receiver) external returns (uint256);

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

	modifier onlyManager() {
		require(registry.isCallerManager(_msgSender()), "Forbidden: Only Manager");
		_;
	}

	modifier onlyEmergency() {
		require(registry.isCallerEmergency(_msgSender()), "Forbidden: Only Emergency");
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

	function isCallerManager(address _account) external view returns (bool);

	function isCallerEmergency(address _account) external view returns (bool);

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