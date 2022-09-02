// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IERC20TokenReceiver } from "./interfaces/IERC20TokenReceiver.sol";

import { PausableAccessControl } from "./utils/PausableAccessControl.sol";
import { TokenUtils } from "./utils/TokenUtils.sol";
import "./utils/Errors.sol";

/// @title Keeper
/// @author Koala Money
contract Keeper is IERC20TokenReceiver, PausableAccessControl, ReentrancyGuard {
	/// @notice Struct describing the user info
	struct UserInfo {
		///@notice Amount of synthethic tokens deposited, decreases when tokens are converted (convertedAmount increases).
		uint256 totalStaked;
		///@notice Amount of synthethic tokens that have been converted into native tokens and ready to claim as native tokens.
		uint256 totalConverted;
		///@notice Keep track of last time the dividends were updated for each user.
		uint256 lastDividendPoints;
		///@notice Last block number user interactived with the keeper.
		uint256 lastUserAction;
	}

	/// @notice The scalar used for conversion of integral numbers to fixed point numbers.
	uint256 public constant FIXED_POINT_SCALAR = 1e18;

	/// @notice The address of the synthetic token to convert to base token.
	address public immutable synthToken;

	/// @notice The address of the native token.
	address public immutable nativeToken;

	uint8 public immutable nativeTokenDecimals;

	uint8 public immutable synthTokenDecimals;

	/// @notice The length (in blocks) of one full distribution phase.
	uint256 public distributionPeriod;

	///@notice Total reserve of synth token staked by users.
	uint256 public totalStaked;

	/// @notice Total reserve of native token to share.
	uint256 public nativeTokenReserve;

	///@notice Beginning of last distribution cycle.
	uint256 public lastDistributionBlock;

	/// @notice Gives the id of the next added user.
	uint256 public nextUserId;

	/// @notice Checks if a user is known.
	mapping(address => bool) public isKnownUser;

	/// @notice Total amount of native tokens already converted.
	uint256 private _nativeTokenConvertedReserve;

	///@notice Sum of weights.
	uint256 private _totalDividendPoints;

	/// @notice Associates a unique id with a user address.
	mapping(uint256 => address) private _userList;

	/// @notice Associates user infos with user address.
	mapping(address => UserInfo) private _userInfos;

	constructor(
		address _synthToken,
		address _nativeToken,
		uint256 _distributionPeriod
	) {
		synthToken = _synthToken;
		nativeToken = _nativeToken;
		distributionPeriod = _distributionPeriod;

		nativeTokenDecimals = TokenUtils.expectDecimals(_nativeToken);
		synthTokenDecimals = TokenUtils.expectDecimals(_synthToken);
	}

	/// @notice Sets the distribution period.
	///
	/// @notice Reverts with an {OnlyAdminAllowed} error if the caller is missing the admin role.
	/// @notice Reverts with an {ZeroValue} error if the distribution period is 0.
	///
	/// @notice Emits a {DistributionPeriodUpdated} event.
	///
	/// @param _distributionPeriod The length (in block) of one full distribution phase.
	function setDistributionPeriod(uint256 _distributionPeriod) external {
		_onlyAdmin();
		if (_distributionPeriod == 0) {
			revert ZeroValue();
		}
		distributionPeriod = _distributionPeriod;

		emit DistributionPeriodUpdated(_distributionPeriod);
	}

	/// @notice Deposits synthetic tokens into the keeper in order to get the right to convert them into native tokens over time.
	///
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	/// @notice Reverts with an {ZeroValue} error if the stake amount is 0.
	///
	/// @notice Emits a {TokensStaked} event.
	///
	/// @param _amount the amount of synthetic tokens to stake.
	function stake(uint256 _amount) external nonReentrant {
		_checkNotPaused();
		if (_amount == 0) {
			revert ZeroValue();
		}
		_distribute();
		_update(msg.sender);

		// Adds user to known list to control liquidations
		_addUserToKnownList(msg.sender);

		// Transfers synthetic tokens from user to keeper
		TokenUtils.safeTransferFrom(synthToken, msg.sender, address(this), _amount);

		// Increases user stake amount
		_increaseStakeFor(msg.sender, _amount);

		emit TokensStaked(msg.sender, _amount);
	}

	/// @notice Withdraws staked synthetic tokens from the keeper.
	/// @notice User gives up the converted tokens when calling this function.
	///
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	/// @notice Reverts with an {ZeroValue} error if the unstake amount is 0.
	///
	/// @notice Emits a {TokensUnstaked} event.
	///
	/// @param _amount The amount of synthetic tokens to unstake.
	function unstake(uint256 _amount) external nonReentrant {
		_checkNotPaused();
		_distribute();
		_update(msg.sender);

		// Claims native tokens
		_claim(msg.sender);

		// Computes effective unstake amount allowed for user
		uint256 _unstakeAmount = _getEffectiveUnstakeFor(msg.sender, _amount);

		_unstake(msg.sender, _unstakeAmount);
	}

	/// @notice Executes claim() on another account that has more converted tokens than synthethic tokens staked.
	/// @notice The caller of this function will have the surplus base tokens credited to their balance, rewarding them for performing this action.
	///
	/// @notice Reverts with an {LiquidationForbidden} if the address has nothing to liquidate.
	/// @notice Reverts with an {ContractPaused} error if the contract is in pause state.
	///
	/// @notice Emits a {TokensLiquidated} event.
	///
	/// @param _toLiquidate address of the account you will force convert.
	function liquidate(address _toLiquidate) external nonReentrant {
		_checkNotPaused();
		_distribute();
		_update(msg.sender);
		_update(_toLiquidate);

		// Calculates overflow for liquidated user
		uint256 _overflow = _getOverflowFor(_toLiquidate);

		// Checks if valid liquidation
		if (_overflow == 0) {
			revert LiquidationForbidden();
		}

		// Closes liquidated user position
		_claim(_toLiquidate);

		// Grants overflow to liquidator
		_increaseConvertedForLiquidator(msg.sender, _overflow);

		emit TokensLiquidated(msg.sender, _toLiquidate, _overflow);
	}

	/// @notice Allows user to forfeit converted tokens and withdraw all staked tokens.
	///
	/// @notice Reverts with an {NothingStaked} error if the unstake amount is 0.
	///
	/// @notice Emits a {EmergencyExitCompleted} event.
	function emergencyExit() external nonReentrant {
		_distribute();
		_update(msg.sender);
		// Computes effective debt reduction allowed for user
		uint256 _unstakeAmount = _getMaxUnstakeFor(msg.sender);
		if (_unstakeAmount == 0) {
			revert NothingStaked();
		}
		// Forfeits converted native tokens
		_resetConvertedFor(msg.sender);

		// Unstakes synthethic tokens
		_unstake(msg.sender, _unstakeAmount);

		emit EmergencyExitCompleted(msg.sender, _unstakeAmount);
	}

	/// @notice Checks the amount of vault token available and distributes it during the next phased period.
	function distribute() external nonReentrant {
		_distribute();
		_syncNativeTokenReserve();
	}

	///  IERC20TokenReceiver
	function onERC20Received(address _token, uint256 _amount) external nonReentrant {
		_distribute();
		_syncNativeTokenReserve();
	}

	/// @notice Gets the status of a user's staking position.
	///
	/// @param _user The address of the user to query.
	///
	/// @return The amount of tokens staked for user.
	/// @return The amount of synthetic tokens converted and ready to be claimed as native tokens.
	function userInfo(address _user) external view returns (uint256, uint256) {
		return _getUserInfoFor(_user);
	}

	/// @notice Gets the status of a a list of users.
	///
	/// @param _from The index of the first user to query (included).
	/// @param _to The index of the last user to query (excluded).
	///
	/// @return _addressList The addresses of the users.
	/// @return _stakedAmount The amount of tokens staked for users.
	/// @return _convertedAmount The amount of synthetic tokens converted and ready to be claimed as native tokens.
	function userInfos(uint256 _from, uint256 _to)
		external
		view
		returns (
			address[] memory, //addressList,
			uint256[] memory, //totalStakedList,
			uint256[] memory //totalConvertedList
		)
	{
		if (_to > nextUserId || _from >= _to) {
			revert OutOfBoundsArgument();
		}

		uint256 _delta = _to - _from;
		address[] memory _addressList = new address[](_delta);
		uint256[] memory _totalStakedList = new uint256[](_delta);
		uint256[] memory _totalConvertedList = new uint256[](_delta);

		for (uint256 i = 0; i < _delta; ++i) {
			address _user = _userList[_from + i];
			_addressList[i] = _user;
			(_totalStakedList[i], _totalConvertedList[i]) = _getUserInfoFor(_user);
		}
		return (_addressList, _totalStakedList, _totalConvertedList);
	}

	/// @notice Gets the total amount to distribute to users.
	///
	/// @return The total amount of native tokens to distribute during distribution period.
	function getNativeTokenToDistribute() external view returns (uint256) {
		return _getNativeTokenToDistribute();
	}

	/// @notice Allows `_owner` to claim its converted native tokens.
	///
	/// @param _owner The address of the account to claim converted native tokens for.
	function _claim(address _owner) internal {
		// Gets claimable amount
		uint256 _claimableAmount = _getClaimableFor(_owner);

		if (_claimableAmount > 0) {
			// Resets converted amount
			_resetConvertedFor(_owner);
			// Decreases user stake and burns synth tokens
			_decreaseStakeFor(_owner, _claimableAmount);
			TokenUtils.safeBurn(synthToken, _claimableAmount);
			// Transfers converted tokens to user
			nativeTokenReserve -= _claimableAmount;
			TokenUtils.safeTransfer(nativeToken, _owner, _claimableAmount);
		}

		emit TokensClaimed(_owner, _claimableAmount);
	}

	/// @notice Allows `_owner` to unstake its synthethic tokens.
	///
	/// @param _owner The address of the account to claim converted native tokens for.
	/// @param _amount The amount of tokens to unstake
	function _unstake(address _owner, uint256 _amount) internal {
		if (_amount > 0) {
			_decreaseStakeFor(_owner, _amount);

			TokenUtils.safeTransfer(synthToken, _owner, _amount);
		}

		emit TokensUnstaked(_owner, _amount);
	}

	function _normaliseSynthToNative(uint256 _amount) internal view returns (uint256) {
		return (_amount * (10**nativeTokenDecimals)) / 10**synthTokenDecimals;
	}

	function _normaliseNativeToSynth(uint256 _amount) internal view returns (uint256) {
		return (_amount * (10**synthTokenDecimals)) / 10**nativeTokenDecimals;
	}

	/// @notice Increases distributed amount for user `_owner`.
	///
	/// @param _owner The address of the account to update the totalconverted amount for.
	function _update(address _owner) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		uint256 _extraConverted = (_userInfo.totalStaked * (_totalDividendPoints - _userInfo.lastDividendPoints)) /
			FIXED_POINT_SCALAR;

		_userInfo.totalConverted += _extraConverted;
		_userInfo.lastDividendPoints = _totalDividendPoints;
	}

	/// @notice Synchronises native token known balance with effective balance.
	function _syncNativeTokenReserve() internal {
		nativeTokenReserve = TokenUtils.safeBalanceOf(nativeToken, address(this));
	}

	/// @notice Run the phased distribution of the funds
	function _distribute() internal {
		uint256 _totalStaked = totalStaked;
		if (_totalStaked > 0) {
			uint256 _toDistribute = _getNativeTokenToDistribute();
			if (_toDistribute > 0) {
				_nativeTokenConvertedReserve += _toDistribute;
				_totalDividendPoints += (_toDistribute * FIXED_POINT_SCALAR) / _totalStaked;
			}
		}
		lastDistributionBlock = block.number;
	}

	/// @notice Increases the amount of synth token staked for `_owner` by `_amount`
	///
	/// @param _owner The address of the account to increase stake for.
	/// @param _amount The additional amount of synth tokens staked.
	function _increaseStakeFor(address _owner, uint256 _amount) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_userInfo.totalStaked += _amount;
		totalStaked += _amount;
	}

	/// @notice Decreases the amount of synth token staked for `_owner` by `_amount`.
	///
	/// @param _owner The address of the account to decrease stake for.
	/// @param _amount The reduced amount of synth tokens staked.
	function _decreaseStakeFor(address _owner, uint256 _amount) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_userInfo.totalStaked -= _amount;
		totalStaked -= _amount;
	}

	/// @notice Converted tokens are forfeited by `_owner`.
	///
	/// @param _owner The address of the account to forfeit rewards for.
	function _resetConvertedFor(address _owner) internal {
		UserInfo storage _userInfo = _userInfos[_owner];
		_nativeTokenConvertedReserve -= _userInfo.totalConverted;
		_userInfo.totalConverted = 0;
	}

	/// @notice Increases converted position for the liquidator.
	/// @notice This function is called when a user is liquidated.
	///
	/// @param _liquidator The address of the account that performs the liquidation.
	/// @param _overflow The amount of native tokens to add to the converted position of the liquidator.
	function _increaseConvertedForLiquidator(address _liquidator, uint256 _overflow) internal {
		UserInfo storage _liquidatorInfo = _userInfos[_liquidator];
		_liquidatorInfo.totalConverted += _overflow;
		_nativeTokenConvertedReserve += _overflow;
	}

	/// @notice Adds `_user` to the list of known users
	///
	/// @param _user The address of the account to add to the list of known users.
	function _addUserToKnownList(address _user) internal {
		if (!isKnownUser[_user]) {
			isKnownUser[_user] = true;
			uint256 _id = nextUserId;
			_userList[_id] = _user;
			nextUserId = _id + 1;
		}
	}

	/// @notice Gets the status of a user's staking position.
	///
	/// @param _user The address of the user to query.
	///
	/// @return The amount of tokens staked for user.
	/// @return The amount of synthetic tokens converted and ready to be claimed as native tokens.
	function _getUserInfoFor(address _user) internal view returns (uint256, uint256) {
		UserInfo storage _userInfo = _userInfos[_user];

		uint256 _userTotalStaked = _userInfo.totalStaked;
		uint256 _userTotalConverted = _userInfo.totalConverted;

		// Rewards from last distribution
		_userTotalConverted +=
			(_userTotalStaked * (_totalDividendPoints - _userInfo.lastDividendPoints)) /
			FIXED_POINT_SCALAR;

		// Rewards from next distribution
		uint256 _totalStaked = totalStaked;
		if (_totalStaked != 0) {
			uint256 _toDistribute = _getNativeTokenToDistribute();
			_userTotalConverted += (_toDistribute * _userTotalStaked) / _totalStaked;
		}
		return (_userTotalStaked, _userTotalConverted);
	}

	/// @notice Gets the total amount to distribute to users.
	///
	/// @return The total amount of native tokens to distribute during distribution period.
	function _getNativeTokenToDistribute() internal view returns (uint256) {
		uint256 _distributionPeriod = distributionPeriod;
		uint256 _deltaBlocks = Math.min(block.number - lastDistributionBlock, _distributionPeriod);
		uint256 _nativeTokenAvailable = nativeTokenReserve - _nativeTokenConvertedReserve;
		uint256 _toDistribute = (_nativeTokenAvailable * _deltaBlocks) / _distributionPeriod;
		return _toDistribute;
	}

	/// @notice Gets the amount of converted tokens claimable by `_owner`.
	///
	/// @param _owner The address of the account to get the claimable amount for.
	///
	/// @return The amount of converted tokens claimable.
	function _getClaimableFor(address _owner) internal view returns (uint256) {
		UserInfo storage _userInfo = _userInfos[_owner];
		uint256 _claimableAmount = Math.min(_userInfo.totalConverted, _userInfo.totalStaked);

		return _claimableAmount;
	}

	/// @notice Gets the max stake reduction for `_owner`.
	///
	/// @param _owner The address of the account that wants to reduce its stake.
	///
	/// @return The max amount of unstaked tokens.
	function _getMaxUnstakeFor(address _owner) internal view returns (uint256) {
		UserInfo storage _userInfo = _userInfos[_owner];
		return _userInfo.totalStaked;
	}

	/// @notice Gets the effective stake reduction for `_owner`.
	///
	/// @param _owner The address of the account that wants to reduce its stake.
	/// @param _wishedUnstakedAmount The wished amount of tokens to unstake.
	///
	/// @return The effective amount of unstaked tokens.
	function _getEffectiveUnstakeFor(address _owner, uint256 _wishedUnstakedAmount) internal view returns (uint256) {
		UserInfo storage _userInfo = _userInfos[_owner];
		uint256 _effectiveUnstakedAmount = Math.min(_wishedUnstakedAmount, _userInfo.totalStaked);
		return _effectiveUnstakedAmount;
	}

	/// @notice Gets the overflow for `_owner`.
	/// @notice The overflow is the surplus between the amount of native tokens converted and the amount of synthethic tokens staked by `_owner`.
	/// @notice Returns 0 if there is no overflow.
	///
	/// @param _owner The address of the account to compute overflow for.
	///
	/// @return The overflow.
	function _getOverflowFor(address _owner) internal view returns (uint256) {
		UserInfo storage _liquidatedInfo = _userInfos[_owner];
		uint256 _liquidatedTotalStaked = _liquidatedInfo.totalStaked;
		uint256 _liquidatedTotalConverted = _liquidatedInfo.totalConverted;
		// If no overflow returns 0
		if (_liquidatedTotalStaked >= _liquidatedTotalConverted) {
			return 0;
		}
		uint256 _overflow = _liquidatedTotalConverted - _liquidatedTotalStaked;
		return _overflow;
	}

	/// @notice Emitted when `_user` stakes `amount` synthetic assets.
	///
	/// @param user The address of the user.
	/// @param amount The amount of synthetic tokens staked.
	event TokensStaked(address indexed user, uint256 amount);

	/// @notice Emitted when `_user` unstakes `amount` synthetic assets.
	///
	/// @param user The address of the user.
	/// @param amount The amount of synthetic tokens unstaked.
	event TokensUnstaked(address indexed user, uint256 amount);

	/// @notice Emitted when `user` claims `amount` of native tokens.
	///
	/// @param  user The address of the user.
	/// @param amount The amount of native tokens claimed.
	event TokensClaimed(address indexed user, uint256 amount);

	/// @notice Emitted when `user` liquidates `amount` synthetic assets from `toLiquidate`.
	///
	/// @param user The address of the user.
	/// @param toLiquidate The address of the user to liquidate.
	/// @param amount The amount of tokens liquidates.
	event TokensLiquidated(address indexed user, address toLiquidate, uint256 amount);

	/// @notice Emitted when `amount` of native tokens are received by the keeper.
	///
	/// @param amount The amount of native tokens received by the keeper.
	event NativeTokenReceived(uint256 amount);

	/// @notice Emitted when the distribution period is updated.
	///
	/// @param distributionPeriod The distribution period.
	event DistributionPeriodUpdated(uint256 distributionPeriod);

	/// @notice Emitted when the vault manager is migrated.
	///
	/// @param migrateTo The address of the new vault manager.
	/// @param totalFunds The total amount of funds migrated.
	event MigrationCompleted(address migrateTo, uint256 totalFunds);

	/// @notice Emitted when a user perform an emergency exit after a migration.
	///
	/// @param user The address of the user.
	/// @param amount The total amount of synthetic tokens unstaked.
	event EmergencyExitCompleted(address indexed user, uint256 amount);

	/// @notice Indicates that the unstake operation failed because user has nothing staked.
	error NothingStaked();

	/// @notice Indicates that the liquidation operation failed because liquidated user ready to convert balance has not overflown.
	error LiquidationForbidden();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/// @title IERC20TokenReceiver
/// @author Alchemix Finance
interface IERC20TokenReceiver {
	/// @notice Informs implementors of this interface that an ERC20 token has been transferred.
	///
	/// @param token The token that was transferred.
	/// @param value The amount of the token that was transferred.
	function onERC20Received(address token, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AdminAccessControl } from "./AdminAccessControl.sol";

/// @title  PausableAccessControl
/// @author Koala Money
///
/// @notice An admin access control with sentinel role and pausable state.
contract PausableAccessControl is AdminAccessControl {
	/// @notice The identifier of the role which can pause/unpause contract
	bytes32 public constant SENTINEL_ROLE = keccak256("SENTINEL");

	/// @notice Check if the token is paused.
	bool public paused;

	/// @notice Emitted when the contract enters the pause state.
	event Pause();

	/// @notice Emitted when the contract enters the unpause state.
	event Unpause();

	/// @notice Indicates that the caller is missing the sentinel role.
	error OnlySentinelAllowed();

	/// @notice Indicates that the contract is in pause state.
	error ContractPaused();

	/// @notice indicates that the contract is not in pause state.
	error ContractNotPaused();

	/// @notice Sets the contract in the pause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function pause() external {
		_onlySentinel();
		paused = true;
		emit Pause();
	}

	/// @notice Sets the contract in the unpause state.
	///
	/// @notice Reverts if the caller does not have sentinel role.
	function unpause() external {
		_onlySentinel();
		paused = false;
		emit Unpause();
	}

	/// @notice Checks that the contract is in the unpause state.
	function _checkNotPaused() internal view {
		if (paused) {
			revert ContractPaused();
		}
	}

	/// @notice Checks that the contract is in the pause state.
	function _checkPaused() internal view {
		if (!paused) {
			revert ContractNotPaused();
		}
	}

	/// @notice Checks that the caller has the sentinel role.
	function _onlySentinel() internal view {
		if (!hasRole(SENTINEL_ROLE, msg.sender)) {
			revert OnlySentinelAllowed();
		}
	}
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