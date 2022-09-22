// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import "./interfaces/IAuthority.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/AccessControl.sol";

/**
 *  @title Contract used as the source of truth for all protocol authority and access control, based off of OlympusDao Access Control
 */
contract Authority is IAuthority, AccessControl {
	/* ========== STATE VARIABLES ========== */

	address public override governor;

	mapping(address => bool) public override guardian;

	address public override manager;

	address public newGovernor;

	address public newManager;

	/* ========== Constructor ========== */

	constructor(
		address _governor,
		address _guardian,
		address _manager
	) AccessControl(IAuthority(address(this))) {
		if (_governor == address(0) || _guardian == address(0) || _manager == address(0)) {
			revert CustomErrors.InvalidAddress();
		}
		governor = _governor;
		emit GovernorPushed(address(0), _governor);
		emit GovernorPulled(address(0), _governor);
		guardian[_guardian] = true;
		emit GuardianPushed(_guardian);
		manager = _manager;
		emit ManagerPushed(address(0), _manager);
		emit ManagerPulled(address(0), _manager);
	}

	/* ========== GOV ONLY ========== */

	function pushGovernor(address _newGovernor) external {
		_onlyGovernor();
		if (_newGovernor == address(0)) {
			revert CustomErrors.InvalidAddress();
		}
		newGovernor = _newGovernor;
		emit GovernorPushed(governor, newGovernor);
	}

	function pushGuardian(address _newGuardian) external {
		_onlyGovernor();
		if (_newGuardian == address(0)) {
			revert CustomErrors.InvalidAddress();
		}
		guardian[_newGuardian] = true;
		emit GuardianPushed(_newGuardian);
	}

	function pushManager(address _newManager) external {
		_onlyGovernor();
		if (_newManager == address(0)) {
			revert CustomErrors.InvalidAddress();
		}
		newManager = _newManager;
		emit ManagerPushed(manager, newManager);
	}

	function pullGovernor() external {
		require(msg.sender == newGovernor, "!newGovernor");
		emit GovernorPulled(governor, newGovernor);
		governor = newGovernor;
		delete newGovernor;
	}

	function revokeGuardian(address _guardian) external {
		_onlyGovernor();
		emit GuardianRevoked(_guardian);
		guardian[_guardian] = false;
	}

	function pullManager() external {
		require(msg.sender == newManager, "!newManager");
		emit ManagerPulled(manager, newManager);
		manager = newManager;
		delete newManager;
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