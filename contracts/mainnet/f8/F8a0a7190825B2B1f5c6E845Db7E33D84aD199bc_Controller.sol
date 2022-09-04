// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IOracle } from "./interfaces/IOracle.sol";
import { IWhitelist } from "./interfaces/IWhitelist.sol";
import { IZooMinimal } from "./interfaces/IZooMinimal.sol";
import { IERC20StakerMinimal } from "./interfaces/IERC20StakerMinimal.sol";

import { TokenUtils } from "./utils/TokenUtils.sol";
import { AdminAccessControl } from "./utils/AdminAccessControl.sol";
import { Sets } from "./utils/Sets.sol";
import "./utils/Errors.sol";

contract Controller is AdminAccessControl, ReentrancyGuard {
	/// @notice A structure to store the informations related to an account.
	struct UserInfo {
		/// @notice The set of staked tokens.
		Sets.AddressSet stakings;
		/// @notice Last block number a deposit was made.
		uint256 lastDeposit;
	}

	/// @notice A structure to store the informations related to a staking contract.
	/// @notice Staking contract must have a precision equals to debt token decimals.
	struct StakeTokenParam {
		// Gives the multiplier associated with staking amount to compute user staking bonus.
		uint256 multiplier;
		// Factor to express staked token amount with debt token precision.
		uint256 conversionFactor;
		// A flag to indicate if the staking is enabled.
		bool enabled;
	}

	struct PriceFeed {
		// The address of the oracle providing price for collat token.
		address oracle;
		// The conversion factor between price precision and debt token precision.
		uint256 conversionFactor;
	}

	/// @notice The scalar used for conversion of integral numbers to fixed point numbers. Fixed point numbers in this implementation have 18 decimals of resolution, meaning that 1 is represented as 1e18, 0.5 is represented as 5e17, and 2 is represented as 2e18.
	uint256 public constant FIXED_POINT_SCALAR = 1e18;

	/// @notice The minimum value that the collateralization limit can be set to by the admin. This is a safety rail to prevent the collateralization from being set to a value which breaks the system.
	/// This value is equal to 100%.
	uint256 public constant MINIMUM_COLLATERALIZATION = 1e18;

	/// @notice The minimum collateralization ratio allowed. Calculated as user deposit / user debt.
	uint256 public minimumSafeGuardCollateralization;

	/// @notice The minimum adjusted collateralization ratio. Calculates as (user deposit + user staking bonus) / user debt.
	uint256 public minimumAdjustedCollateralization;

	/// @notice The token that this contract is using as the debt asset.
	address public immutable debtToken;

	/// @notice The address of the zoo contract which will manage the deposit/withdraw/mint/burn actions.
	address public zoo;

	/// @notice The address of the contract which will manage the whitelisted contracts with access to the actions.
	address public whitelist;

	/// @notice The address of the contract which will provide price feed expressed in debt token for collateral token.
	PriceFeed private _priceFeed;

	/// @notice The list of supported tokens to stake. Staked tokens are eligible for collateral ratio boost.
	Sets.AddressSet private _supportedStakings;

	/// @notice A mapping between a stake token address and the associated stake token parameters.
	mapping(address => StakeTokenParam) private _stakings;

	/// @notice A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
	/// create a new address or set up a proxy contract that interfaces with this contract.
	mapping(address => UserInfo) private _userInfos;

	constructor(
		address _debtToken,
		uint256 _minimumSafeGuardCollateralization,
		uint256 _minimumAdjustedCollateralization
	) {
		debtToken = _debtToken;
		minimumSafeGuardCollateralization = _minimumSafeGuardCollateralization;
		minimumAdjustedCollateralization = _minimumAdjustedCollateralization;
	}

	/// @notice Sets the address of the zoo.
	/// @notice The zoo allows user to deposit native token and borrow debt token.
	///
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _zoo The address of the new zoo.
	function setZoo(address _zoo) external {
		_onlyAdmin();
		if (_zoo == address(0)) {
			revert ZeroAddress();
		}

		zoo = _zoo;

		emit ZooUpdated(_zoo);
	}

	/// @notice Sets the address of the whitelist contract.
	/// @notice The whitelist controls the smartcontracts that can call the action methods.
	///
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _whitelist The address of the new whitelist.
	function setWhitelist(address _whitelist) external {
		_onlyAdmin();
		if (_whitelist == address(0)) {
			revert ZeroAddress();
		}

		whitelist = _whitelist;

		emit WhitelistUpdated(_whitelist);
	}

	/// @notice Sets the address of the oracle contract.
	///
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _oracle The address of the new oracle.
	function setPriceFeed(address _oracle) external {
		_onlyAdmin();
		if (_oracle == address(0)) {
			revert ZeroAddress();
		}

		uint8 _debtTokenDecimals = TokenUtils.expectDecimals(debtToken);
		uint8 _priceDecimals = IOracle(_oracle).decimals();
		uint256 _conversionFactor = 10**(_debtTokenDecimals - _priceDecimals);

		_priceFeed = PriceFeed({ oracle: _oracle, conversionFactor: _conversionFactor });

		emit PriceFeedUpdated(_oracle, _conversionFactor);
	}

	/// @notice Sets the minimumSafeGuardCollateralization.
	/// @notice The minimumSafeGuardCollateralization is used to control if a user position is healthy. The deposit balance / debt balance of a user must be greater than the minimumSafeGuardCollateralization.
	///
	/// @notice Reverts if the collateralization limit is under 100%.
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _minimumSafeGuardCollateralization The new minimumSafeGuardCollateralization.
	function setMinimumSafeGuardCollateralization(uint256 _minimumSafeGuardCollateralization) external {
		_onlyAdmin();
		if (_minimumSafeGuardCollateralization < MINIMUM_COLLATERALIZATION) {
			revert MinimumCollateralizationBreached();
		}

		minimumSafeGuardCollateralization = _minimumSafeGuardCollateralization;

		emit MinimumSafeGuardCollateralizationUpdated(_minimumSafeGuardCollateralization);
	}

	/// @notice Sets the minimumAdjustedCollateralization.
	/// @notice The minimumAdjustedCollateralization is used to control if a user position is healthy. The (deposit balance + stake bonus) / debt balance of a user must be greater than the minimumSafeGuardCollateralization.
	///
	/// @notice Reverts if the collateralization limit is under 100%.
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _minimumAdjustedCollateralization The new minimumAdjustedCollateralization.
	function setMinimumAdjustedCollateralization(uint256 _minimumAdjustedCollateralization) external {
		_onlyAdmin();
		if (_minimumAdjustedCollateralization < MINIMUM_COLLATERALIZATION) {
			revert MinimumCollateralizationBreached();
		}

		minimumAdjustedCollateralization = _minimumAdjustedCollateralization;

		emit MinimumAdjustedCollateralizationUpdated(_minimumAdjustedCollateralization);
	}

	/// @notice Adds `_staker` to the set of staker contracts with a multiplier of `_multiplier`.
	///
	/// @notice Reverts if `_staker` is already in the set of staker.
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _staking The address of the staking contract.
	/// @param _multiplier the multiplier associated with the staking contract.
	function addSupportedStaking(
		address _staking,
		uint256 _decimals,
		uint256 _multiplier
	) external {
		_onlyAdmin();

		if (Sets.contains(_supportedStakings, _staking)) {
			revert DuplicatedStakingContract(_staking);
		}

		uint8 _debtTokenDecimals = TokenUtils.expectDecimals(debtToken);

		uint256 _conversionFactor = 10**(_debtTokenDecimals - _decimals);

		_stakings[_staking] = StakeTokenParam({
			multiplier: _multiplier,
			conversionFactor: _conversionFactor,
			enabled: false
		});

		Sets.add(_supportedStakings, _staking);

		emit StakingAdded(_staking, _conversionFactor);
		emit StakingMultiplierUpdated(_staking, _multiplier);
		emit StakingEnableUpdated(_staking, false);
	}

	/// @notice Sets the multiplier of `_staking` to `_multiplier`.
	///
	/// @notice Reverts if `_staking` is not a supported stake token.
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _staking The address of the token.
	/// @param _multiplier The value of the multiplier associated with the staking token.
	function setStakingMultiplier(address _staking, uint256 _multiplier) external {
		_onlyAdmin();
		_checkSupportedStaking(_staking);

		_stakings[_staking].multiplier = _multiplier;

		emit StakingMultiplierUpdated(_staking, _multiplier);
	}

	/// @notice Sets the status of `_staking` to `_enabled`.
	/// @notice Users can stake tokens into the zoo to increase the amount of debt token they can borrow.
	///
	/// @notice Reverts if `_staking` is not a supported stake token.
	/// @notice Reverts if the caller does not have the admin role.
	///
	/// @param _staking The address of the token
	/// @param _enabled True if `_staker` is added to the set of staked tokens.
	function setStakingEnabled(address _staking, bool _enabled) external {
		_onlyAdmin();
		_checkSupportedStaking(_staking);

		_stakings[_staking].enabled = _enabled;

		emit StakingEnableUpdated(_staking, _enabled);
	}

	/// @notice Allows to perform control before a deposit action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the deposit action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested deposit amount.
	function controlBeforeDeposit(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_onlyWhitelisted(_owner);
	}

	/// @notice Allows to perform control before a withdraw action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the withdraw action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested withdraw amount.
	function controlBeforeWithdraw(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_onlyWhitelisted(_owner);

		UserInfo storage _userInfo = _userInfos[_owner];
		if (block.number <= _userInfo.lastDeposit) {
			revert DepositSameBlock();
		}
	}

	/// @notice Allows to perform control before a mint action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the mint action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested mint amount.
	function controlBeforeMint(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_onlyWhitelisted(_owner);
	}

	/// @notice Allows to perform control before a burn action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the burn action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested burn amount.
	function controlBeforeBurn(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_onlyWhitelisted(_owner);
	}

	/// @notice Allows to perform control before a liquidate action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the liquidate action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested liquidate amount.
	function controlBeforeLiquidate(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_onlyWhitelisted(_owner);
	}

	/// @notice Allows to perform control after a deposit action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the deposit action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The deposited amount.
	function controlAfterDeposit(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();

		_userInfos[_owner].lastDeposit = block.number;
	}

	/// @notice Allows to perform control after a withdraw action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the withdraw action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The withdrawn amount.
	function controlAfterWithdraw(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_validate(_owner);
	}

	/// @notice Allows to perform control after a mint action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the mint action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The minted amount.
	function controlAfterMint(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
		_validate(_owner);
	}

	/// @notice Allows to perform control after a burn action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the burn action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The burned amount.
	function controlAfterBurn(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
	}

	/// @notice Allows to perform control after a liquidate action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _zoo The address of the contract where the liquidate action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The liquidated amount.
	function controlAfterLiquidate(
		address _zoo,
		address _owner,
		uint256 _amount
	) external {
		_onlyZoo();
	}

	/// @notice Allows to perform control after a stake action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _staking The address of the contract where the stake action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested stake amount.
	function controlBeforeStake(
		address _staking,
		address _owner,
		uint256 _amount
	) external {
		_onlyStakingContract();
		_onlyWhitelisted(_owner);
		_checkEnabledStaking(_staking);
	}

	/// @notice Allows to perform control after an unstake action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _staking The address of the contract where the unstake action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The requested unstake amount.
	function controlBeforeUnstake(
		address _staking,
		address _owner,
		uint256 _amount
	) external {
		_onlyStakingContract();
		_onlyWhitelisted(_owner);
	}

	/// @notice Allows to perform control after a stake action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _staking The address of the contract where the stake action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The staked amount.
	function controlAfterStake(
		address _staking,
		address _owner,
		uint256 _amount
	) external {
		_onlyStakingContract();

		Sets.add(_userInfos[_owner].stakings, _staking);
	}

	/// @notice Allows to perform control after an unstake action.
	///
	/// @notice Reverts if the action is not allowed.
	///
	/// @param _staking The address of the contract where the unstake action is performed.
	/// @param _owner The address of the user that performs the action.
	/// @param _amount The unstaked amount.
	function controlAfterUnstake(
		address _staking,
		address _owner,
		uint256 _amount
	) external {
		_onlyStakingContract();

		IZooMinimal(zoo).sync(_owner);
		_validate(_owner);

		if (IERC20StakerMinimal(_staking).balanceOf(_owner) == 0) {
			Sets.remove(_userInfos[_owner].stakings, _staking);
		}
	}

	/// @notice Gets the address of the price feed.
	function getPriceFeed() external view returns (address) {
		return _priceFeed.oracle;
	}

	/// @notice Gets the list of staked tokens by `_owner`.
	///
	/// @param _owner The address of the user to query the staked tokens for.
	function getStakingsFor(address _owner) external view returns (address[] memory) {
		return _userInfos[_owner].stakings.values;
	}

	/// @notice Gets the list of supported staked tokens.
	function getSupportedStakings() external view returns (address[] memory) {
		return _supportedStakings.values;
	}

	/// @notice Checks if a token is available for staking.
	///
	/// @return true if the token can be staked.
	function isSupportedStaking(address _staking) external view returns (bool) {
		return Sets.contains(_supportedStakings, _staking);
	}

	/// @notice Gets the parameters associated with a stake token.
	///
	/// @param _staking The address of the stake token to query.
	///
	/// @return The parameters of the stake token.
	function getStakingParam(address _staking) external view returns (StakeTokenParam memory) {
		return _stakings[_staking];
	}

	/// @notice Gets the staking bonus for user `_owner`.
	///
	/// @param _owner The address of the user to compute the staking bonus for.
	///
	/// @return The staking bonus.
	function getStakingBonusFor(address _owner) external view returns (uint256) {
		return _getStakingBonusFor(_owner);
	}

	function _validate(address _owner) internal view {
		(uint256 _deposit, int256 _debt) = IZooMinimal(zoo).userInfo(_owner);

		// If no debt the position is valid
		if (_debt <= 0) {
			return;
		}

		// Total value normalized in debt token precision
		uint256 _totalValue = _normalizeToDebt(
			IOracle(_priceFeed.oracle).getPrice(_deposit),
			_priceFeed.conversionFactor
		);

		// Checks direct debt factor
		uint256 _rawCollateralization = (_totalValue * FIXED_POINT_SCALAR) / uint256(_debt);

		if (_rawCollateralization < minimumSafeGuardCollateralization) {
			revert SafeGuardCollateralizationBreached();
		}
		// No needs to check staking bonus if deposit is enough
		uint256 _minimumAdjustedCollateralization = minimumAdjustedCollateralization;
		if (_rawCollateralization >= _minimumAdjustedCollateralization) {
			return;
		}
		// Check debt factor adjusted with staking
		uint256 _stakingBonus = _getStakingBonusFor(_owner);

		uint256 _adjustedCollateralization = ((_totalValue + _stakingBonus) * FIXED_POINT_SCALAR) / uint256(_debt);

		if (_adjustedCollateralization < _minimumAdjustedCollateralization) {
			revert AdjustedCollateralizationBreached();
		}
	}

	function _getStakingBonusFor(address _owner) internal view returns (uint256) {
		uint256 _score = 0;

		address[] memory _stakingTokenList = _userInfos[_owner].stakings.values;
		for (uint256 i = 0; i < _stakingTokenList.length; ++i) {
			StakeTokenParam storage _param = _stakings[_stakingTokenList[i]];
			if (_param.enabled) {
				// Get user lock amount
				uint256 _stakingTokenBalance = IERC20StakerMinimal(_stakingTokenList[i]).balanceOf(_owner);
				if (_stakingTokenBalance > 0) {
					uint256 _normalizedStakingTokenBalance = _normalizeToDebt(
						_stakingTokenBalance,
						_param.conversionFactor
					);

					_score += (_normalizedStakingTokenBalance * _param.multiplier) / FIXED_POINT_SCALAR;
				}
			}
		}
		return _score;
	}

	function _normalizeToDebt(uint256 _amount, uint256 _conversionFactor) internal pure returns (uint256) {
		return _amount * _conversionFactor;
	}

	function _checkSupportedStaking(address _staking) internal view {
		if (!Sets.contains(_supportedStakings, _staking)) {
			revert UnsupportedStakingContract(_staking);
		}
	}

	function _checkEnabledStaking(address _staking) internal view {
		if (!_stakings[_staking].enabled) {
			revert DisabledStakingContract(_staking);
		}
	}

	function _onlyWhitelisted(address _msgSender) internal view {
		// Checks if the message sender is an EOA. In the future, this potentially may break. It is important that functions
		// which rely on the whitelist not be explicitly vulnerable in the situation where this no longer holds true.
		if (tx.origin == _msgSender) {
			return;
		}

		// Only check the whitelist for calls from contracts.
		if (!IWhitelist(whitelist).isWhitelisted(_msgSender)) {
			revert OnlyWhitelistAllowed();
		}
	}

	function _onlyStakingContract() internal view {
		if (!Sets.contains(_supportedStakings, msg.sender)) {
			revert OnlyStakingContractAllowed();
		}
	}

	function _onlyZoo() internal view {
		if (zoo != msg.sender) {
			revert OnlyZooAllowed();
		}
	}

	event MinimumSafeGuardCollateralizationUpdated(uint256 _minimumSafeGuardCollateralization);

	event MinimumAdjustedCollateralizationUpdated(uint256 _minimumAdjustedCollateralization);

	event StakingAdded(address staker, uint256 conversionFactor);

	event StakingEnableUpdated(address staker, bool enabled);

	event StakingMultiplierUpdated(address staker, uint256 multiplier);

	event WhitelistUpdated(address whitelist);

	event ZooUpdated(address zoo);

	event PriceFeedUpdated(address oracle, uint256 conversionFactor);

	error SafeGuardCollateralizationBreached();

	error AdjustedCollateralizationBreached();

	error UnsupportedStakingContract(address stakeToken);

	error DuplicatedStakingContract(address stakeToken);

	error DisabledStakingContract(address stakeToken);

	error DepositSameBlock();

	error MinimumCollateralizationBreached();

	error OnlyWhitelistAllowed();

	error OnlyStakingContractAllowed();

	error OnlyZooAllowed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IOracle {
	function getPrice(uint256 _amount) external view returns (uint256);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  Whitelist
/// @author Alchemix Finance
interface IWhitelist {
	/// @notice Emitted when a contract is added to the whitelist.
	///
	/// @param account The account that was added to the whitelist.
	event AccountAdded(address account);

	/// @notice Emitted when a contract is removed from the whitelist.
	///
	/// @param account The account that was removed from the whitelist.
	event AccountRemoved(address account);

	/// @notice Emitted when the whitelist is deactivated.
	event WhitelistDisabled();

	/// @notice Returns the list of addresses that are whitelisted for the given contract address.
	///
	/// @return addresses The addresses that are whitelisted to interact with the given contract.
	function getAddresses() external view returns (address[] memory addresses);

	/// @notice Returns the disabled status of a given whitelist.
	///
	/// @return disabled A flag denoting if the given whitelist is disabled.
	function disabled() external view returns (bool);

	/// @notice Adds an contract to the whitelist.
	///
	/// @param caller The address to add to the whitelist.
	function add(address caller) external;

	/// @notice Adds a contract to the whitelist.
	///
	/// @param caller The address to remove from the whitelist.
	function remove(address caller) external;

	/// @notice Disables the whitelist of the target whitelisted contract.
	///
	/// This can only occur once. Once the whitelist is disabled, then it cannot be reenabled.
	function disable() external;

	/// @notice Checks that the `msg.sender` is whitelisted when it is not an EOA.
	///
	/// @param account The account to check.
	///
	/// @return whitelisted A flag denoting if the given account is whitelisted.
	function isWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IZooMinimal
/// @author Koala Money
interface IZooMinimal {
	/// @notice Allows controller to update distribution and user information.
	///
	/// @notice _owner The address of the user to update.
	function sync(address _owner) external;

	/// @notice Gets the informations about the account owner by `_owner`.
	///
	/// @param _owner The address of the account to query.
	///
	/// @return totalDeposit The amount of native token deposited
	/// @return totalDebt Total amount of debt left
	function userInfo(address _owner) external view returns (uint256 totalDeposit, int256 totalDebt);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IERC20StakerMinimal
/// @author Koala Money
interface IERC20StakerMinimal {
	function balanceOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/token/IERC20Burnable.sol";
import "../interfaces/token/IERC20Metadata.sol";
import "../interfaces/token/IERC20Minimal.sol";
import "../interfaces/token/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Alchemix Finance
library TokenUtils {
	/// @notice An error used to indicate that a call to an ERC20 contract failed.
	///
	/// @param target  The target address.
	/// @param success If the call to the token was a success.
	/// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
	///                this is malformed data when the call was a success.
	error ERC20CallFailed(address target, bool success, bytes data);

	/// @dev A safe function to get the decimals of an ERC20 token.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token The target token.
	///
	/// @return The amount of decimals of the token.
	function expectDecimals(address token) internal view returns (uint8) {
		(bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint8));
	}

	/// @dev Gets the balance of tokens held by an account.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the balance of.
	/// @param account The address of the token holder.
	///
	/// @return The balance of the tokens held by an account.
	function safeBalanceOf(address token, address account) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Gets the total supply of tokens.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
	///
	/// @param token   The token to check the total supply of.
	///
	/// @return The balance of the tokens held by an account.
	function safeTotalSupply(address token) internal view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.totalSupply.selector)
		);

		if (!success || data.length < 32) {
			revert ERC20CallFailed(token, success, data);
		}

		return abi.decode(data, (uint256));
	}

	/// @dev Transfers tokens to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransfer(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Approves tokens for the smart contract.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
	///
	/// @param token   The token to approve.
	/// @param spender The contract to spend the tokens.
	/// @param value   The amount of tokens to approve.
	function safeApprove(
		address token,
		address spender,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.approve.selector, spender, value)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Transfer tokens from one address to another address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
	///
	/// @param token     The token to transfer.
	/// @param owner     The address of the owner.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to transfer.
	function safeTransferFrom(
		address token,
		address owner,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, owner, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Mints tokens to an address.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
	///
	/// @param token     The token to mint.
	/// @param recipient The address of the recipient.
	/// @param amount    The amount of tokens to mint.
	function safeMint(
		address token,
		address recipient,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens.
	///
	/// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param amount The amount of tokens to burn.
	function safeBurn(address token, uint256 amount) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Burnable.burn.selector, amount));

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}

	/// @dev Burns tokens from its total supply.
	///
	/// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
	///
	/// @param token  The token to burn.
	/// @param owner  The owner of the tokens.
	/// @param amount The amount of tokens to burn.
	function safeBurnFrom(
		address token,
		address owner,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
		);

		if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
			revert ERC20CallFailed(token, success, data);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title  AdminAccessControl
/// @author Koala Money
///
/// @notice An access control with admin role granted to the contract deployer.
contract AdminAccessControl is AccessControl {
	/// @notice Indicates that the caller is missing the admin role.
	error OnlyAdminAllowed();

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function _onlyAdmin() internal view {
		if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
			revert OnlyAdminAllowed();
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  Sets
/// @author Alchemix Finance
library Sets {
	using Sets for AddressSet;

	/// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
	struct AddressSet {
		address[] values;
		mapping(address => uint256) indexes;
	}

	/// @notice Add a value to a Set
	///
	/// @param self  The Set.
	/// @param value The value to add.
	///
	/// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
	function add(AddressSet storage self, address value) internal returns (bool) {
		if (self.contains(value)) {
			return false;
		}
		self.values.push(value);
		self.indexes[value] = self.values.length;
		return true;
	}

	/// @notice Remove a value from a Set
	///
	/// @param self  The Set.
	/// @param value The value to remove.
	///
	/// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
	function remove(AddressSet storage self, address value) internal returns (bool) {
		uint256 index = self.indexes[value];
		if (index == 0) {
			return false;
		}

		// Normalize the index since we know that the element is in the set.
		index--;

		uint256 lastIndex = self.values.length - 1;

		if (index != lastIndex) {
			address lastValue = self.values[lastIndex];
			self.values[index] = lastValue;
			self.indexes[lastValue] = index + 1;
		}

		self.values.pop();

		delete self.indexes[value];

		return true;
	}

	/// @notice Returns true if the value exists in the Set
	///
	/// @param self  The Set.
	/// @param value The value to check.
	///
	/// @return True if the value is contained in the Set, False if it is not.
	function contains(AddressSet storage self, address value) internal view returns (bool) {
		return self.indexes[value] != 0;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

/// @notice An error used to indicate that an action could not be completed because a zero address argument was passed to the function.
error ZeroAddress();

/// @notice An error used to indicate that an action could not be completed because a zero amount argument was passed to the function.
error ZeroValue();

/// @notice An error used to indicate that an action could not be completed because a function was called with an out of bounds argument.
error OutOfBoundsArgument();

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Burnable {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
	/// @notice Gets the name of the token.
	///
	/// @return The name.
	function name() external view returns (string memory);

	/// @notice Gets the symbol of the token.
	///
	/// @return The symbol.
	function symbol() external view returns (string memory);

	/// @notice Gets the number of decimals that the token has.
	///
	/// @return The number of decimals.
	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title  IERC20Minimal
/// @author Alchemix Finance
interface IERC20Minimal {
	/// @notice An event which is emitted when tokens are transferred between two parties.
	///
	/// @param owner     The owner of the tokens from which the tokens were transferred.
	/// @param recipient The recipient of the tokens to which the tokens were transferred.
	/// @param amount    The amount of tokens which were transferred.
	event Transfer(address indexed owner, address indexed recipient, uint256 amount);

	/// @notice An event which is emitted when an approval is made.
	///
	/// @param owner   The address which made the approval.
	/// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/// @notice Gets the current total supply of tokens.
	///
	/// @return The total supply.
	function totalSupply() external view returns (uint256);

	/// @notice Gets the balance of tokens that an account holds.
	///
	/// @param account The account address.
	///
	/// @return The balance of the account.
	function balanceOf(address account) external view returns (uint256);

	/// @notice Gets the allowance that an owner has allotted for a spender.
	///
	/// @param owner   The owner address.
	/// @param spender The spender address.
	///
	/// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
	function allowance(address owner, address spender) external view returns (uint256);

	/// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
	///
	/// @notice Emits a {Transfer} event.
	///
	/// @param recipient The address which will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transfer(address recipient, uint256 amount) external returns (bool);

	/// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	///
	/// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
	/// @param amount  The amount of tokens that `spender` is allowed to transfer.
	///
	/// @return If the approval was successful.
	function approve(address spender, uint256 amount) external returns (bool);

	/// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
	///
	/// @notice Emits a {Approval} event.
	/// @notice Emits a {Transfer} event.
	///
	/// @param owner     The address to transfer tokens from.
	/// @param recipient The address that will receive the tokens.
	/// @param amount    The amount of tokens to transfer.
	///
	/// @return If the transfer was successful.
	function transferFrom(
		address owner,
		address recipient,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20Mintable {
	function mint(address _recipient, uint256 _amount) external;

	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}